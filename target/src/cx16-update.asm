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
  /// The colors of the C64
  .const BLACK = 0
  .const WHITE = 1
  .const RED = 2
  .const CYAN = 3
  .const PURPLE = 4
  .const GREEN = 5
  .const BLUE = 6
  .const YELLOW = 7
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
  .const VERA_LAYER_WIDTH_MASK = $30
  .const VERA_LAYER_HEIGHT_MASK = $c0
  // Some addressing constants.
  // These pre-processor directives allow to disable specific ROM flashing functions (for emulator development purposes).
  // Normally they should be all activated.
  // To print the graphics on the vera.
  .const PROGRESS_X = 2
  .const PROGRESS_Y = $20
  .const PROGRESS_W = $40
  .const PROGRESS_H = $10
  .const STATUS_NONE = 0
  .const STATUS_SKIP = 1
  .const STATUS_DETECTED = 2
  .const STATUS_COMPARING = 5
  .const STATUS_FLASH = 6
  .const STATUS_FLASHING = 7
  .const STATUS_FLASHED = 8
  .const STATUS_ISSUE = 9
  .const STATUS_ERROR = $a
  .const PROGRESS_CELL = $200
  .const PROGRESS_ROW = $8000
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
  .label BRAM = 0
  .label BROM = 1
  /// Current position in the buffer being filled ( initially *s passed to snprintf()
  /// Used to hold state while printing
  .label __snprintf_buffer = $af
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
    .label conio_x16_init__4 = $d9
    .label conio_x16_init__5 = $c4
    .label conio_x16_init__6 = $db
    .label conio_x16_init__7 = $dd
    // screenlayer1()
    // [19] call screenlayer1
    jsr screenlayer1
    // [20] phi from conio_x16_init to conio_x16_init::@1 [phi:conio_x16_init->conio_x16_init::@1]
    // conio_x16_init::@1
    // textcolor(CONIO_TEXTCOLOR_DEFAULT)
    // [21] call textcolor
    // [584] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [584] phi textcolor::color#18 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [22] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [23] call bgcolor
    // [589] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [589] phi bgcolor::color#14 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbum1=vbuc1 
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
    // [602] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [602] phi gotoxy::y#30 = gotoxy::y#2 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [602] phi gotoxy::x#30 = gotoxy::x#2 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
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
    .label cputc__2 = $53
    .label cputc__3 = $54
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
    // cputc::@7
  __b7:
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
    jmp __b7
    // cputc::@5
  __b5:
    // if(__conio.cursor_x >= __conio.width)
    // [62] if(*((char *)&__conio)>=*((char *)&__conio+6)) goto cputc::@8 -- _deref_pbuc1_ge__deref_pbuc2_then_la1 
    lda __conio
    cmp __conio+6
    bcs __b8
    // cputc::@9
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
    // [66] phi from cputc::@5 to cputc::@8 [phi:cputc::@5->cputc::@8]
    // cputc::@8
  __b8:
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
    .const intro_briefing_count = $10
    .const intro_colors_count = $10
    .const debriefing_count = 4
    .const debriefing_count1 = $c
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 0
    .const bank_set_brom2_bank = 0
    .const bank_set_brom3_bank = 0
    .const bank_push_set_bram1_bank = 1
    .const bank_set_brom4_bank = 4
    .const bank_set_brom5_bank = 0
    .label main__108 = $62
    .label main__185 = $d5
    .label main__186 = $41
    .label main__188 = $d8
    .label main__190 = $de
    .label main__192 = $e1
    .label main__194 = $6b
    .label main__195 = $b9
    .label cx16_k_screen_set_charset1_offset = $e2
    .label check_smc1_main__0 = $78
    .label check_smc2_main__0 = $57
    .label check_cx16_rom1_check_rom1_main__0 = $76
    .label check_smc3_main__0 = $7c
    .label check_cx16_rom2_check_rom1_main__0 = $ba
    .label check_card_roms1_check_rom1_main__0 = $d2
    .label check_smc4_main__0 = $b4
    .label check_rom1_main__0 = $b7
    .label check_smc5_main__0 = $bb
    .label check_vera1_main__0 = $cf
    .label check_roms_all1_check_rom1_main__0 = $b8
    .label check_smc6_main__0 = $75
    .label check_smc7_main__0 = $c7
    .label check_vera2_main__0 = $7d
    .label check_roms1_check_rom1_main__0 = $b3
    .label check_smc8_main__0 = $7e
    .label check_vera3_main__0 = $c8
    .label check_roms2_check_rom1_main__0 = $c5
    .label check_smc9_main__0 = $6c
    .label file = $df
    .label file1 = $d3
    // main::bank_set_bram1
    // BRAM = bank
    // [71] BRAM = main::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // main::bank_set_brom1
    // BROM = bank
    // [72] BROM = main::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // main::@62
    // cx16_k_screen_set_charset(3, (char *)0)
    // [73] main::cx16_k_screen_set_charset1_charset = 3 -- vbum1=vbuc1 
    lda #3
    sta cx16_k_screen_set_charset1_charset
    // [74] main::cx16_k_screen_set_charset1_offset = (char *) 0 -- pbuz1=pbuc1 
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
    // [76] phi from main::cx16_k_screen_set_charset1 to main::@63 [phi:main::cx16_k_screen_set_charset1->main::@63]
    // main::@63
    // display_frame_init()
    // [77] call display_frame_init
    // [623] phi from main::@63 to display_frame_init [phi:main::@63->display_frame_init]
    jsr display_frame_init
    // [78] phi from main::@63 to main::@86 [phi:main::@63->main::@86]
    // main::@86
    // display_frame_draw()
    // [79] call display_frame_draw
    // [643] phi from main::@86 to display_frame_draw [phi:main::@86->display_frame_draw]
    jsr display_frame_draw
    // [80] phi from main::@86 to main::@87 [phi:main::@86->main::@87]
    // main::@87
    // display_print_title("Commander X16 Flash Utility!")
    // [81] call display_print_title
    // [684] phi from main::@87 to display_print_title [phi:main::@87->display_print_title]
    jsr display_print_title
    // [82] phi from main::@87 to main::display_print_info_title1 [phi:main::@87->main::display_print_info_title1]
    // main::display_print_info_title1
    // cputsxy(INFO_X-2, INFO_Y-2, "# Chip Status    Type   File  / Total Information")
    // [83] call cputsxy
    // [689] phi from main::display_print_info_title1 to cputsxy [phi:main::display_print_info_title1->cputsxy]
    // [689] phi cputsxy::s#4 = main::s [phi:main::display_print_info_title1->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z cputsxy.s
    lda #>s
    sta.z cputsxy.s+1
    // [689] phi cputsxy::y#4 = $11-2 [phi:main::display_print_info_title1->cputsxy#1] -- vbum1=vbuc1 
    lda #$11-2
    sta cputsxy.y
    // [689] phi cputsxy::x#4 = 4-2 [phi:main::display_print_info_title1->cputsxy#2] -- vbum1=vbuc1 
    lda #4-2
    sta cputsxy.x
    jsr cputsxy
    // [84] phi from main::display_print_info_title1 to main::@88 [phi:main::display_print_info_title1->main::@88]
    // main::@88
    // cputsxy(INFO_X-2, INFO_Y-1, "- ---- --------- ------ ----- / ----- --------------------")
    // [85] call cputsxy
    // [689] phi from main::@88 to cputsxy [phi:main::@88->cputsxy]
    // [689] phi cputsxy::s#4 = main::s1 [phi:main::@88->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s1
    sta.z cputsxy.s
    lda #>s1
    sta.z cputsxy.s+1
    // [689] phi cputsxy::y#4 = $11-1 [phi:main::@88->cputsxy#1] -- vbum1=vbuc1 
    lda #$11-1
    sta cputsxy.y
    // [689] phi cputsxy::x#4 = 4-2 [phi:main::@88->cputsxy#2] -- vbum1=vbuc1 
    lda #4-2
    sta cputsxy.x
    jsr cputsxy
    // [86] phi from main::@88 to main::@64 [phi:main::@88->main::@64]
    // main::@64
    // display_progress_clear()
    // [87] call display_progress_clear
    // [696] phi from main::@64 to display_progress_clear [phi:main::@64->display_progress_clear]
    jsr display_progress_clear
    // [88] phi from main::@64 to main::@89 [phi:main::@64->main::@89]
    // main::@89
    // display_info_progress("Detecting SMC, VERA and ROM chipsets ...")
    // [89] call display_info_progress
  // info_print(0, "The SMC chip on the X16 board controls the power on/off, keyboard and mouse pheripherals.");
  // info_print(1, "It is essential that the SMC chip gets updated together with the latest ROM on the X16 board.");
  // info_print(2, "On the X16 board, near the SMC chip are two jumpers");
    // [711] phi from main::@89 to display_info_progress [phi:main::@89->display_info_progress]
    // [711] phi display_info_progress::info_text#14 = main::info_text [phi:main::@89->display_info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_progress.info_text
    lda #>info_text
    sta.z display_info_progress.info_text+1
    jsr display_info_progress
    // main::SEI1
    // asm
    // asm { sei  }
    sei
    // [91] phi from main::SEI1 to main::@65 [phi:main::SEI1->main::@65]
    // main::@65
    // smc_detect()
    // [92] call smc_detect
    jsr smc_detect
    // [93] smc_detect::return#2 = smc_detect::return#0
    // main::@90
    // smc_bootloader = smc_detect()
    // [94] smc_bootloader#0 = smc_detect::return#2 -- vwum1=vwum2 
    lda smc_detect.return
    sta smc_bootloader
    lda smc_detect.return+1
    sta smc_bootloader+1
    // display_chip_smc()
    // [95] call display_chip_smc
    // [736] phi from main::@90 to display_chip_smc [phi:main::@90->display_chip_smc]
    jsr display_chip_smc
    // main::@91
    // if(smc_bootloader == 0x0100)
    // [96] if(smc_bootloader#0==$100) goto main::@1 -- vwum1_eq_vwuc1_then_la1 
    lda smc_bootloader
    cmp #<$100
    bne !+
    lda smc_bootloader+1
    cmp #>$100
    bne !__b1+
    jmp __b1
  !__b1:
  !:
    // main::@3
    // if(smc_bootloader == 0x0200)
    // [97] if(smc_bootloader#0==$200) goto main::@11 -- vwum1_eq_vwuc1_then_la1 
    lda smc_bootloader
    cmp #<$200
    bne !+
    lda smc_bootloader+1
    cmp #>$200
    bne !__b11+
    jmp __b11
  !__b11:
  !:
    // main::@4
    // if(smc_bootloader > 0x2)
    // [98] if(smc_bootloader#0>=2+1) goto main::@12 -- vwum1_ge_vbuc1_then_la1 
    lda smc_bootloader+1
    beq !__b12+
    jmp __b12
  !__b12:
    lda smc_bootloader
    cmp #2+1
    bcc !__b12+
    jmp __b12
  !__b12:
  !:
    // [99] phi from main::@4 to main::@5 [phi:main::@4->main::@5]
    // main::@5
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [100] call snprintf_init
    jsr snprintf_init
    // [101] phi from main::@5 to main::@96 [phi:main::@5->main::@96]
    // main::@96
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [102] call printf_str
    // [745] phi from main::@96 to printf_str [phi:main::@96->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:main::@96->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = main::s2 [phi:main::@96->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main::@97
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [103] printf_uint::uvalue#14 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta printf_uint.uvalue
    lda smc_bootloader+1
    sta printf_uint.uvalue+1
    // [104] call printf_uint
    // [754] phi from main::@97 to printf_uint [phi:main::@97->printf_uint]
    // [754] phi printf_uint::format_zero_padding#16 = 1 [phi:main::@97->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [754] phi printf_uint::format_min_length#16 = 2 [phi:main::@97->printf_uint#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uint.format_min_length
    // [754] phi printf_uint::putc#16 = &snputc [phi:main::@97->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [754] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:main::@97->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [754] phi printf_uint::uvalue#16 = printf_uint::uvalue#14 [phi:main::@97->printf_uint#4] -- register_copy 
    jsr printf_uint
    // main::@98
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [105] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [106] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_smc(STATUS_DETECTED, info_text)
    // [108] call display_info_smc
    // [765] phi from main::@98 to display_info_smc [phi:main::@98->display_info_smc]
    // [765] phi display_info_smc::info_text#12 = info_text [phi:main::@98->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_smc.info_text
    lda #>@info_text
    sta.z display_info_smc.info_text+1
    // [765] phi smc_file_size#12 = 0 [phi:main::@98->display_info_smc#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size_2
    sta smc_file_size_2+1
    // [765] phi display_info_smc::info_status#12 = STATUS_DETECTED [phi:main::@98->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_DETECTED
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // main::CLI1
  CLI1:
    // asm
    // asm { cli  }
    cli
    // [110] phi from main::CLI1 to main::@66 [phi:main::CLI1->main::@66]
    // main::@66
    // display_chip_vera()
    // [111] call display_chip_vera
  // Detecting VERA FPGA.
    // [795] phi from main::@66 to display_chip_vera [phi:main::@66->display_chip_vera]
    jsr display_chip_vera
    // [112] phi from main::@66 to main::@99 [phi:main::@66->main::@99]
    // main::@99
    // display_info_vera(STATUS_DETECTED, "VERA installed, OK")
    // [113] call display_info_vera
    // [800] phi from main::@99 to display_info_vera [phi:main::@99->display_info_vera]
    // [800] phi display_info_vera::info_text#10 = main::info_text3 [phi:main::@99->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text3
    sta.z display_info_vera.info_text
    lda #>info_text3
    sta.z display_info_vera.info_text+1
    // [800] phi display_info_vera::info_status#2 = STATUS_DETECTED [phi:main::@99->display_info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_DETECTED
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // main::SEI2
    // asm
    // asm { sei  }
    sei
    // [115] phi from main::SEI2 to main::@67 [phi:main::SEI2->main::@67]
    // main::@67
    // rom_detect()
    // [116] call rom_detect
  // Detecting ROM chips
    // [826] phi from main::@67 to rom_detect [phi:main::@67->rom_detect]
    jsr rom_detect
    // [117] phi from main::@67 to main::@100 [phi:main::@67->main::@100]
    // main::@100
    // display_chip_rom()
    // [118] call display_chip_rom
    // [876] phi from main::@100 to display_chip_rom [phi:main::@100->display_chip_rom]
    jsr display_chip_rom
    // [119] phi from main::@100 to main::@13 [phi:main::@100->main::@13]
    // [119] phi main::rom_chip#2 = 0 [phi:main::@100->main::@13#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // main::@13
  __b13:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [120] if(main::rom_chip#2<8) goto main::@14 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcs !__b14+
    jmp __b14
  !__b14:
    // main::CLI2
    // asm
    // asm { cli  }
    cli
    // [122] phi from main::CLI2 to main::@18 [phi:main::CLI2->main::@18]
    // [122] phi main::intro_line#2 = 0 [phi:main::CLI2->main::@18#0] -- vbum1=vbuc1 
    lda #0
    sta intro_line
    // main::@18
  __b18:
    // for(unsigned char intro_line=0; intro_line<intro_briefing_count; intro_line++)
    // [123] if(main::intro_line#2<main::intro_briefing_count) goto main::@19 -- vbum1_lt_vbuc1_then_la1 
    lda intro_line
    cmp #intro_briefing_count
    bcs !__b19+
    jmp __b19
  !__b19:
    // [124] phi from main::@18 to main::@20 [phi:main::@18->main::@20]
    // main::@20
    // util_wait_key("Please read carefully the below, and press [SPACE] ...", " ")
    // [125] call util_wait_key
    // [895] phi from main::@20 to util_wait_key [phi:main::@20->util_wait_key]
    // [895] phi util_wait_key::filter#14 = s1 [phi:main::@20->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<@s1
    sta.z util_wait_key.filter
    lda #>@s1
    sta.z util_wait_key.filter+1
    // [895] phi util_wait_key::info_text#4 = main::info_text6 [phi:main::@20->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text6
    sta.z util_wait_key.info_text
    lda #>info_text6
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // [126] phi from main::@20 to main::@102 [phi:main::@20->main::@102]
    // main::@102
    // display_progress_clear()
    // [127] call display_progress_clear
    // [696] phi from main::@102 to display_progress_clear [phi:main::@102->display_progress_clear]
    jsr display_progress_clear
    // [128] phi from main::@102 to main::@21 [phi:main::@102->main::@21]
    // [128] phi main::intro_line1#2 = 0 [phi:main::@102->main::@21#0] -- vbum1=vbuc1 
    lda #0
    sta intro_line1
    // main::@21
  __b21:
    // for(unsigned char intro_line=0; intro_line<intro_colors_count; intro_line++)
    // [129] if(main::intro_line1#2<main::intro_colors_count) goto main::@22 -- vbum1_lt_vbuc1_then_la1 
    lda intro_line1
    cmp #intro_colors_count
    bcs !__b22+
    jmp __b22
  !__b22:
    // [130] phi from main::@21 to main::@23 [phi:main::@21->main::@23]
    // [130] phi main::intro_status#2 = 0 [phi:main::@21->main::@23#0] -- vbum1=vbuc1 
    lda #0
    sta intro_status
    // main::@23
  __b23:
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [131] if(main::intro_status#2<$b) goto main::@24 -- vbum1_lt_vbuc1_then_la1 
    lda intro_status
    cmp #$b
    bcs !__b24+
    jmp __b24
  !__b24:
    // [132] phi from main::@23 to main::@25 [phi:main::@23->main::@25]
    // main::@25
    // util_wait_key("If understood, press [SPACE] to start the update ...", " ")
    // [133] call util_wait_key
    // [895] phi from main::@25 to util_wait_key [phi:main::@25->util_wait_key]
    // [895] phi util_wait_key::filter#14 = s1 [phi:main::@25->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<@s1
    sta.z util_wait_key.filter
    lda #>@s1
    sta.z util_wait_key.filter+1
    // [895] phi util_wait_key::info_text#4 = main::info_text7 [phi:main::@25->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z util_wait_key.info_text
    lda #>info_text7
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // [134] phi from main::@25 to main::@105 [phi:main::@25->main::@105]
    // main::@105
    // display_progress_clear()
    // [135] call display_progress_clear
    // [696] phi from main::@105 to display_progress_clear [phi:main::@105->display_progress_clear]
    jsr display_progress_clear
    // main::SEI3
    // asm
    // asm { sei  }
    sei
    // main::check_smc1
    // status_smc == status
    // [137] main::check_smc1_$0 = status_smc#0 == STATUS_DETECTED -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_DETECTED
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_smc1_main__0
    // return (unsigned char)(status_smc == status);
    // [138] main::check_smc1_return#0 = (char)main::check_smc1_$0 -- vbum1=vbuz2 
    sta check_smc1_return
    // main::@68
    // if(check_smc(STATUS_DETECTED))
    // [139] if(0==main::check_smc1_return#0) goto main::CLI3 -- 0_eq_vbum1_then_la1 
    bne !__b4+
    jmp __b4
  !__b4:
    // [140] phi from main::@68 to main::@26 [phi:main::@68->main::@26]
    // main::@26
    // smc_read(8, 512)
    // [141] call smc_read
    // [919] phi from main::@26 to smc_read [phi:main::@26->smc_read]
    // [919] phi __errno#35 = 0 [phi:main::@26->smc_read#0] -- vwsm1=vwsc1 
    lda #<0
    sta __errno
    sta __errno+1
    jsr smc_read
    // smc_read(8, 512)
    // [142] smc_read::return#2 = smc_read::return#0
    // main::@106
    // smc_file_size = smc_read(8, 512)
    // [143] smc_file_size#0 = smc_read::return#2 -- vwum1=vwum2 
    lda smc_read.return
    sta smc_file_size
    lda smc_read.return+1
    sta smc_file_size+1
    // if (!smc_file_size)
    // [144] if(0==smc_file_size#0) goto main::@29 -- 0_eq_vwum1_then_la1 
    // In case no file was found, set the status to error and skip to the next, else, mention the amount of bytes read.
    lda smc_file_size
    ora smc_file_size+1
    bne !__b29+
    jmp __b29
  !__b29:
    // main::@27
    // if(smc_file_size > 0x1E00)
    // [145] if(smc_file_size#0>$1e00) goto main::@30 -- vwum1_gt_vwuc1_then_la1 
    // If the smc.bin file size is larger than 0x1E00 then there is an error!
    lda #>$1e00
    cmp smc_file_size+1
    bcs !__b30+
    jmp __b30
  !__b30:
    bne !+
    lda #<$1e00
    cmp smc_file_size
    bcs !__b30+
    jmp __b30
  !__b30:
  !:
    // [146] phi from main::@27 to main::@28 [phi:main::@27->main::@28]
    // main::@28
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [147] call snprintf_init
    jsr snprintf_init
    // [148] phi from main::@28 to main::@107 [phi:main::@28->main::@107]
    // main::@107
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [149] call printf_str
    // [745] phi from main::@107 to printf_str [phi:main::@107->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:main::@107->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = main::s2 [phi:main::@107->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main::@108
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [150] printf_uint::uvalue#15 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta printf_uint.uvalue
    lda smc_bootloader+1
    sta printf_uint.uvalue+1
    // [151] call printf_uint
    // [754] phi from main::@108 to printf_uint [phi:main::@108->printf_uint]
    // [754] phi printf_uint::format_zero_padding#16 = 1 [phi:main::@108->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [754] phi printf_uint::format_min_length#16 = 2 [phi:main::@108->printf_uint#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uint.format_min_length
    // [754] phi printf_uint::putc#16 = &snputc [phi:main::@108->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [754] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:main::@108->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [754] phi printf_uint::uvalue#16 = printf_uint::uvalue#15 [phi:main::@108->printf_uint#4] -- register_copy 
    jsr printf_uint
    // main::@109
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [152] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [153] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [155] smc_file_size#369 = smc_file_size#0 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_FLASH, info_text)
    // [156] call display_info_smc
    // [765] phi from main::@109 to display_info_smc [phi:main::@109->display_info_smc]
    // [765] phi display_info_smc::info_text#12 = info_text [phi:main::@109->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_smc.info_text
    lda #>@info_text
    sta.z display_info_smc.info_text+1
    // [765] phi smc_file_size#12 = smc_file_size#369 [phi:main::@109->display_info_smc#1] -- register_copy 
    // [765] phi display_info_smc::info_status#12 = STATUS_FLASH [phi:main::@109->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASH
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [157] phi from main::@109 main::@29 main::@30 to main::CLI3 [phi:main::@109/main::@29/main::@30->main::CLI3]
    // [157] phi smc_file_size#207 = smc_file_size#0 [phi:main::@109/main::@29/main::@30->main::CLI3#0] -- register_copy 
    // [157] phi __errno#256 = __errno#18 [phi:main::@109/main::@29/main::@30->main::CLI3#1] -- register_copy 
    jmp CLI3
    // [157] phi from main::@68 to main::CLI3 [phi:main::@68->main::CLI3]
  __b4:
    // [157] phi smc_file_size#207 = 0 [phi:main::@68->main::CLI3#0] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size
    sta smc_file_size+1
    // [157] phi __errno#256 = 0 [phi:main::@68->main::CLI3#1] -- vwsm1=vwsc1 
    sta __errno
    sta __errno+1
    // main::CLI3
  CLI3:
    // asm
    // asm { cli  }
    cli
    // main::SEI4
    // asm { sei  }
    sei
    // [160] phi from main::SEI4 to main::@31 [phi:main::SEI4->main::@31]
    // [160] phi __errno#112 = __errno#256 [phi:main::SEI4->main::@31#0] -- register_copy 
    // [160] phi main::rom_chip1#10 = 0 [phi:main::SEI4->main::@31#1] -- vbum1=vbuc1 
    lda #0
    sta rom_chip1
  // We loop all the possible ROM chip slots on the board and on the extension card,
  // and we check the file contents.
  // Any error identified gets reported and this chip will not be flashed.
  // In case of ROM0.BIN in error, no flashing will be done!
    // main::@31
  __b31:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [161] if(main::rom_chip1#10<8) goto main::bank_set_brom2 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip1
    cmp #8
    bcs !bank_set_brom2+
    jmp bank_set_brom2
  !bank_set_brom2:
    // main::bank_set_brom3
    // BROM = bank
    // [162] BROM = main::bank_set_brom3_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom3_bank
    sta.z BROM
    // main::CLI4
    // asm
    // asm { cli  }
    cli
    // main::check_smc2
    // status_smc == status
    // [164] main::check_smc2_$0 = status_smc#0 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_smc2_main__0
    // return (unsigned char)(status_smc == status);
    // [165] main::check_smc2_return#0 = (char)main::check_smc2_$0 -- vbum1=vbuz2 
    sta check_smc2_return
    // [166] phi from main::check_smc2 to main::check_cx16_rom1 [phi:main::check_smc2->main::check_cx16_rom1]
    // main::check_cx16_rom1
    // main::check_cx16_rom1_check_rom1
    // status_rom[rom_chip] == status
    // [167] main::check_cx16_rom1_check_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_cx16_rom1_check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [168] main::check_cx16_rom1_check_rom1_return#0 = (char)main::check_cx16_rom1_check_rom1_$0 -- vbum1=vbuz2 
    sta check_cx16_rom1_check_rom1_return
    // main::@70
    // if(!check_smc(STATUS_FLASH) || !check_cx16_rom(STATUS_FLASH))
    // [169] if(0==main::check_smc2_return#0) goto main::@38 -- 0_eq_vbum1_then_la1 
    lda check_smc2_return
    bne !__b38+
    jmp __b38
  !__b38:
    // main::@182
    // [170] if(0==main::check_cx16_rom1_check_rom1_return#0) goto main::@38 -- 0_eq_vbum1_then_la1 
    lda check_cx16_rom1_check_rom1_return
    bne !__b38+
    jmp __b38
  !__b38:
    // main::check_smc3
  check_smc3:
    // status_smc == status
    // [171] main::check_smc3_$0 = status_smc#0 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_smc3_main__0
    // return (unsigned char)(status_smc == status);
    // [172] main::check_smc3_return#0 = (char)main::check_smc3_$0 -- vbum1=vbuz2 
    sta check_smc3_return
    // [173] phi from main::check_smc3 to main::check_cx16_rom2 [phi:main::check_smc3->main::check_cx16_rom2]
    // main::check_cx16_rom2
    // main::check_cx16_rom2_check_rom1
    // status_rom[rom_chip] == status
    // [174] main::check_cx16_rom2_check_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_cx16_rom2_check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [175] main::check_cx16_rom2_check_rom1_return#0 = (char)main::check_cx16_rom2_check_rom1_$0 -- vbum1=vbuz2 
    sta check_cx16_rom2_check_rom1_return
    // [176] phi from main::check_cx16_rom2_check_rom1 to main::check_card_roms1 [phi:main::check_cx16_rom2_check_rom1->main::check_card_roms1]
    // main::check_card_roms1
    // [177] phi from main::check_card_roms1 to main::check_card_roms1_@1 [phi:main::check_card_roms1->main::check_card_roms1_@1]
    // [177] phi main::check_card_roms1_rom_chip#2 = 1 [phi:main::check_card_roms1->main::check_card_roms1_@1#0] -- vbum1=vbuc1 
    lda #1
    sta check_card_roms1_rom_chip
    // main::check_card_roms1_@1
  check_card_roms1___b1:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [178] if(main::check_card_roms1_rom_chip#2<8) goto main::check_card_roms1_check_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda check_card_roms1_rom_chip
    cmp #8
    bcs !check_card_roms1_check_rom1+
    jmp check_card_roms1_check_rom1
  !check_card_roms1_check_rom1:
    // [179] phi from main::check_card_roms1_@1 to main::check_card_roms1_@return [phi:main::check_card_roms1_@1->main::check_card_roms1_@return]
    // [179] phi main::check_card_roms1_return#2 = STATUS_NONE [phi:main::check_card_roms1_@1->main::check_card_roms1_@return#0] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta check_card_roms1_return
    // main::check_card_roms1_@return
    // main::@73
  __b73:
    // if(check_smc(STATUS_FLASH) && check_cx16_rom(STATUS_FLASH) || check_card_roms(STATUS_FLASH))
    // [180] if(0==main::check_smc3_return#0) goto main::@183 -- 0_eq_vbum1_then_la1 
    lda check_smc3_return
    beq __b183
    // main::@184
    // [181] if(0!=main::check_cx16_rom2_check_rom1_return#0) goto main::@6 -- 0_neq_vbum1_then_la1 
    lda check_cx16_rom2_check_rom1_return
    beq !__b6+
    jmp __b6
  !__b6:
    // main::@183
  __b183:
    // [182] if(0!=main::check_card_roms1_return#2) goto main::@6 -- 0_neq_vbum1_then_la1 
    lda check_card_roms1_return
    beq !__b6+
    jmp __b6
  !__b6:
    // main::SEI5
  SEI5:
    // asm
    // asm { sei  }
    sei
    // main::check_smc4
    // status_smc == status
    // [184] main::check_smc4_$0 = status_smc#0 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_smc4_main__0
    // return (unsigned char)(status_smc == status);
    // [185] main::check_smc4_return#0 = (char)main::check_smc4_$0 -- vbum1=vbuz2 
    sta check_smc4_return
    // main::@74
    // if (check_smc(STATUS_FLASH))
    // [186] if(0==main::check_smc4_return#0) goto main::@2 -- 0_eq_vbum1_then_la1 
    bne !__b2+
    jmp __b2
  !__b2:
    // [187] phi from main::@74 to main::@8 [phi:main::@74->main::@8]
    // main::@8
    // smc_read(8, 512)
    // [188] call smc_read
    // [919] phi from main::@8 to smc_read [phi:main::@8->smc_read]
    // [919] phi __errno#35 = __errno#112 [phi:main::@8->smc_read#0] -- register_copy 
    jsr smc_read
    // smc_read(8, 512)
    // [189] smc_read::return#3 = smc_read::return#0
    // main::@140
    // smc_file_size = smc_read(8, 512)
    // [190] smc_file_size#1 = smc_read::return#3 -- vwum1=vwum2 
    lda smc_read.return
    sta smc_file_size_1
    lda smc_read.return+1
    sta smc_file_size_1+1
    // if(smc_file_size)
    // [191] if(0==smc_file_size#1) goto main::@2 -- 0_eq_vwum1_then_la1 
    lda smc_file_size_1
    ora smc_file_size_1+1
    beq __b2
    // [192] phi from main::@140 to main::@9 [phi:main::@140->main::@9]
    // main::@9
    // display_info_line("Press both POWER/RESET buttons on the CX16 board!")
    // [193] call display_info_line
  // Flash the SMC chip.
    // [976] phi from main::@9 to display_info_line [phi:main::@9->display_info_line]
    // [976] phi display_info_line::info_text#19 = main::info_text18 [phi:main::@9->display_info_line#0] -- pbuz1=pbuc1 
    lda #<info_text18
    sta.z display_info_line.info_text
    lda #>info_text18
    sta.z display_info_line.info_text+1
    jsr display_info_line
    // main::@141
    // [194] smc_file_size#370 = smc_file_size#1 -- vwum1=vwum2 
    lda smc_file_size_1
    sta smc_file_size_2
    lda smc_file_size_1+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_FLASHING, "Press POWER/RESET!")
    // [195] call display_info_smc
    // [765] phi from main::@141 to display_info_smc [phi:main::@141->display_info_smc]
    // [765] phi display_info_smc::info_text#12 = main::info_text19 [phi:main::@141->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text19
    sta.z display_info_smc.info_text
    lda #>info_text19
    sta.z display_info_smc.info_text+1
    // [765] phi smc_file_size#12 = smc_file_size#370 [phi:main::@141->display_info_smc#1] -- register_copy 
    // [765] phi display_info_smc::info_status#12 = STATUS_FLASHING [phi:main::@141->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHING
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // main::@142
    // unsigned long flashed_bytes = flash_smc(PROGRESS_X, PROGRESS_Y, PROGRESS_W, smc_file_size, 8, 512, (ram_ptr_t)RAM_BASE)
    // [196] flash_smc::smc_bytes_total#0 = smc_file_size#1 -- vwuz1=vwum2 
    lda smc_file_size_1
    sta.z flash_smc.smc_bytes_total
    lda smc_file_size_1+1
    sta.z flash_smc.smc_bytes_total+1
    // [197] call flash_smc
    // [990] phi from main::@142 to flash_smc [phi:main::@142->flash_smc]
    jsr flash_smc
    // unsigned long flashed_bytes = flash_smc(PROGRESS_X, PROGRESS_Y, PROGRESS_W, smc_file_size, 8, 512, (ram_ptr_t)RAM_BASE)
    // [198] flash_smc::return#5 = flash_smc::return#1
    // main::@143
    // [199] main::flashed_bytes#0 = flash_smc::return#5 -- vdum1=vwum2 
    lda flash_smc.return
    sta flashed_bytes
    lda flash_smc.return+1
    sta flashed_bytes+1
    lda #0
    sta flashed_bytes+2
    sta flashed_bytes+3
    // if(flashed_bytes)
    // [200] if(0!=main::flashed_bytes#0) goto main::@42 -- 0_neq_vdum1_then_la1 
    lda flashed_bytes
    ora flashed_bytes+1
    ora flashed_bytes+2
    ora flashed_bytes+3
    beq !__b42+
    jmp __b42
  !__b42:
    // main::@10
    // [201] smc_file_size#368 = smc_file_size#1 -- vwum1=vwum2 
    lda smc_file_size_1
    sta smc_file_size_2
    lda smc_file_size_1+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_ERROR, "SMC not updated!")
    // [202] call display_info_smc
    // [765] phi from main::@10 to display_info_smc [phi:main::@10->display_info_smc]
    // [765] phi display_info_smc::info_text#12 = main::info_text21 [phi:main::@10->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text21
    sta.z display_info_smc.info_text
    lda #>info_text21
    sta.z display_info_smc.info_text+1
    // [765] phi smc_file_size#12 = smc_file_size#368 [phi:main::@10->display_info_smc#1] -- register_copy 
    // [765] phi display_info_smc::info_status#12 = STATUS_ERROR [phi:main::@10->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [203] phi from main::@10 main::@140 main::@42 main::@74 to main::@2 [phi:main::@10/main::@140/main::@42/main::@74->main::@2]
    // [203] phi __errno#393 = __errno#18 [phi:main::@10/main::@140/main::@42/main::@74->main::@2#0] -- register_copy 
    // main::@2
  __b2:
    // [204] phi from main::@2 to main::@43 [phi:main::@2->main::@43]
    // [204] phi __errno#114 = __errno#393 [phi:main::@2->main::@43#0] -- register_copy 
    // [204] phi main::rom_chip3#10 = 7 [phi:main::@2->main::@43#1] -- vbum1=vbuc1 
    lda #7
    sta rom_chip3
  // Flash the ROM chips. 
  // We loop first all the ROM chips and read the file contents.
  // Then we verify the file contents and flash the ROM only for the differences.
  // If the file contents are the same as the ROM contents, then no flashing is required.
  // IMPORTANT! We start to flash the ROMs on the extension card.
  // The last ROM flashed is the CX16 ROM on the CX16 board!
    // main::@43
  __b43:
    // for(unsigned char rom_chip = 7; rom_chip != 255; rom_chip--)
    // [205] if(main::rom_chip3#10!=$ff) goto main::check_rom1 -- vbum1_neq_vbuc1_then_la1 
    lda #$ff
    cmp rom_chip3
    beq !check_rom1+
    jmp check_rom1
  !check_rom1:
    // main::bank_set_brom4
    // BROM = bank
    // [206] BROM = main::bank_set_brom4_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom4_bank
    sta.z BROM
    // main::CLI5
    // asm
    // asm { cli  }
    cli
    // [208] phi from main::CLI5 to main::@76 [phi:main::CLI5->main::@76]
    // main::@76
    // display_progress_clear()
    // [209] call display_progress_clear
    // [696] phi from main::@76 to display_progress_clear [phi:main::@76->display_progress_clear]
    jsr display_progress_clear
    // [210] phi from main::@76 to main::@144 [phi:main::@76->main::@144]
    // main::@144
    // display_info_progress("Update finished ...")
    // [211] call display_info_progress
    // [711] phi from main::@144 to display_info_progress [phi:main::@144->display_info_progress]
    // [711] phi display_info_progress::info_text#14 = main::info_text22 [phi:main::@144->display_info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text22
    sta.z display_info_progress.info_text
    lda #>info_text22
    sta.z display_info_progress.info_text+1
    jsr display_info_progress
    // main::check_smc5
    // status_smc == status
    // [212] main::check_smc5_$0 = status_smc#0 == STATUS_SKIP -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_smc5_main__0
    // return (unsigned char)(status_smc == status);
    // [213] main::check_smc5_return#0 = (char)main::check_smc5_$0 -- vbum1=vbuz2 
    sta check_smc5_return
    // main::check_vera1
    // status_vera == status
    // [214] main::check_vera1_$0 = status_vera#0 == STATUS_SKIP -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_vera1_main__0
    // return (unsigned char)(status_vera == status);
    // [215] main::check_vera1_return#0 = (char)main::check_vera1_$0 -- vbum1=vbuz2 
    sta check_vera1_return
    // [216] phi from main::check_vera1 to main::check_roms_all1 [phi:main::check_vera1->main::check_roms_all1]
    // main::check_roms_all1
    // [217] phi from main::check_roms_all1 to main::check_roms_all1_@1 [phi:main::check_roms_all1->main::check_roms_all1_@1]
    // [217] phi main::check_roms_all1_rom_chip#2 = 0 [phi:main::check_roms_all1->main::check_roms_all1_@1#0] -- vbum1=vbuc1 
    lda #0
    sta check_roms_all1_rom_chip
    // main::check_roms_all1_@1
  check_roms_all1___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [218] if(main::check_roms_all1_rom_chip#2<8) goto main::check_roms_all1_check_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda check_roms_all1_rom_chip
    cmp #8
    bcs !check_roms_all1_check_rom1+
    jmp check_roms_all1_check_rom1
  !check_roms_all1_check_rom1:
    // [219] phi from main::check_roms_all1_@1 to main::check_roms_all1_@return [phi:main::check_roms_all1_@1->main::check_roms_all1_@return]
    // [219] phi main::check_roms_all1_return#2 = 1 [phi:main::check_roms_all1_@1->main::check_roms_all1_@return#0] -- vbum1=vbuc1 
    lda #1
    sta check_roms_all1_return
    // main::check_roms_all1_@return
    // main::@77
  __b77:
    // if(check_smc(STATUS_SKIP) && check_vera(STATUS_SKIP) && check_roms_all(STATUS_SKIP))
    // [220] if(0==main::check_smc5_return#0) goto main::check_smc7 -- 0_eq_vbum1_then_la1 
    lda check_smc5_return
    beq check_smc7
    // main::@186
    // [221] if(0==main::check_vera1_return#0) goto main::check_smc7 -- 0_eq_vbum1_then_la1 
    lda check_vera1_return
    beq check_smc7
    // main::@185
    // [222] if(0!=main::check_roms_all1_return#2) goto main::vera_display_set_border_color1 -- 0_neq_vbum1_then_la1 
    lda check_roms_all1_return
    beq !vera_display_set_border_color1+
    jmp vera_display_set_border_color1
  !vera_display_set_border_color1:
    // main::check_smc7
  check_smc7:
    // status_smc == status
    // [223] main::check_smc7_$0 = status_smc#0 == STATUS_ERROR -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_smc7_main__0
    // return (unsigned char)(status_smc == status);
    // [224] main::check_smc7_return#0 = (char)main::check_smc7_$0 -- vbum1=vbuz2 
    sta check_smc7_return
    // main::check_vera2
    // status_vera == status
    // [225] main::check_vera2_$0 = status_vera#0 == STATUS_ERROR -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_vera2_main__0
    // return (unsigned char)(status_vera == status);
    // [226] main::check_vera2_return#0 = (char)main::check_vera2_$0 -- vbum1=vbuz2 
    sta check_vera2_return
    // [227] phi from main::check_vera2 to main::check_roms1 [phi:main::check_vera2->main::check_roms1]
    // main::check_roms1
    // [228] phi from main::check_roms1 to main::check_roms1_@1 [phi:main::check_roms1->main::check_roms1_@1]
    // [228] phi main::check_roms1_rom_chip#2 = 0 [phi:main::check_roms1->main::check_roms1_@1#0] -- vbum1=vbuc1 
    lda #0
    sta check_roms1_rom_chip
    // main::check_roms1_@1
  check_roms1___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [229] if(main::check_roms1_rom_chip#2<8) goto main::check_roms1_check_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda check_roms1_rom_chip
    cmp #8
    bcs !check_roms1_check_rom1+
    jmp check_roms1_check_rom1
  !check_roms1_check_rom1:
    // [230] phi from main::check_roms1_@1 to main::check_roms1_@return [phi:main::check_roms1_@1->main::check_roms1_@return]
    // [230] phi main::check_roms1_return#2 = STATUS_NONE [phi:main::check_roms1_@1->main::check_roms1_@return#0] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta check_roms1_return
    // main::check_roms1_@return
    // main::@81
  __b81:
    // if(check_smc(STATUS_ERROR) || check_vera(STATUS_ERROR) || check_roms(STATUS_ERROR))
    // [231] if(0!=main::check_smc7_return#0) goto main::vera_display_set_border_color2 -- 0_neq_vbum1_then_la1 
    lda check_smc7_return
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::@190
    // [232] if(0!=main::check_vera2_return#0) goto main::vera_display_set_border_color2 -- 0_neq_vbum1_then_la1 
    lda check_vera2_return
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::@189
    // [233] if(0!=main::check_roms1_return#2) goto main::vera_display_set_border_color2 -- 0_neq_vbum1_then_la1 
    lda check_roms1_return
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::check_smc8
    // status_smc == status
    // [234] main::check_smc8_$0 = status_smc#0 == STATUS_ISSUE -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_smc8_main__0
    // return (unsigned char)(status_smc == status);
    // [235] main::check_smc8_return#0 = (char)main::check_smc8_$0 -- vbum1=vbuz2 
    sta check_smc8_return
    // main::check_vera3
    // status_vera == status
    // [236] main::check_vera3_$0 = status_vera#0 == STATUS_ISSUE -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_vera3_main__0
    // return (unsigned char)(status_vera == status);
    // [237] main::check_vera3_return#0 = (char)main::check_vera3_$0 -- vbum1=vbuz2 
    sta check_vera3_return
    // [238] phi from main::check_vera3 to main::check_roms2 [phi:main::check_vera3->main::check_roms2]
    // main::check_roms2
    // [239] phi from main::check_roms2 to main::check_roms2_@1 [phi:main::check_roms2->main::check_roms2_@1]
    // [239] phi main::check_roms2_rom_chip#2 = 0 [phi:main::check_roms2->main::check_roms2_@1#0] -- vbum1=vbuc1 
    lda #0
    sta check_roms2_rom_chip
    // main::check_roms2_@1
  check_roms2___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [240] if(main::check_roms2_rom_chip#2<8) goto main::check_roms2_check_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda check_roms2_rom_chip
    cmp #8
    bcs !check_roms2_check_rom1+
    jmp check_roms2_check_rom1
  !check_roms2_check_rom1:
    // [241] phi from main::check_roms2_@1 to main::check_roms2_@return [phi:main::check_roms2_@1->main::check_roms2_@return]
    // [241] phi main::check_roms2_return#2 = STATUS_NONE [phi:main::check_roms2_@1->main::check_roms2_@return#0] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta check_roms2_return
    // main::check_roms2_@return
    // main::@83
  __b83:
    // if(check_smc(STATUS_ISSUE) || check_vera(STATUS_ISSUE) || check_roms(STATUS_ISSUE))
    // [242] if(0!=main::check_smc8_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbum1_then_la1 
    lda check_smc8_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::@192
    // [243] if(0!=main::check_vera3_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbum1_then_la1 
    lda check_vera3_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::@191
    // [244] if(0!=main::check_roms2_return#2) goto main::vera_display_set_border_color3 -- 0_neq_vbum1_then_la1 
    lda check_roms2_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::vera_display_set_border_color4
    // *VERA_CTRL &= ~VERA_DCSEL
    // [245] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [246] *VERA_DC_BORDER = GREEN -- _deref_pbuc1=vbuc2 
    lda #GREEN
    sta VERA_DC_BORDER
    // main::check_smc9
    // status_smc == status
    // [247] main::check_smc9_$0 = status_smc#0 == STATUS_FLASHED -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASHED
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_smc9_main__0
    // return (unsigned char)(status_smc == status);
    // [248] main::check_smc9_return#0 = (char)main::check_smc9_$0 -- vbum1=vbuz2 
    sta check_smc9_return
    // main::@85
    // if(check_smc(STATUS_FLASHED))
    // [249] if(0!=main::check_smc9_return#0) goto main::@53 -- 0_neq_vbum1_then_la1 
    beq !__b7+
    jmp __b7
  !__b7:
    // [250] phi from main::@85 to main::@51 [phi:main::@85->main::@51]
    // [250] phi main::l#2 = 0 [phi:main::@85->main::@51#0] -- vbum1=vbuc1 
    lda #0
    sta l
    // main::@51
  __b51:
    // for(unsigned char l=0; l<debriefing_count; l++)
    // [251] if(main::l#2<main::debriefing_count) goto main::@52 -- vbum1_lt_vbuc1_then_la1 
    lda l
    cmp #debriefing_count
    bcc __b52
    // [252] phi from main::@175 main::@51 main::@80 main::@84 to main::@59 [phi:main::@175/main::@51/main::@80/main::@84->main::@59]
  __b5:
    // [252] phi main::w1#2 = $c8 [phi:main::@175/main::@51/main::@80/main::@84->main::@59#0] -- vbum1=vbuc1 
    lda #$c8
    sta w1
    // main::@59
  __b59:
    // for (unsigned char w=200; w>0; w--)
    // [253] if(main::w1#2>0) goto main::@60 -- vbum1_gt_0_then_la1 
    lda w1
    bne __b60
    // [254] phi from main::@59 to main::@61 [phi:main::@59->main::@61]
    // main::@61
    // system_reset()
    // [255] call system_reset
    // [1152] phi from main::@61 to system_reset [phi:main::@61->system_reset]
    jsr system_reset
    // main::@return
    // }
    // [256] return 
    rts
    // [257] phi from main::@59 to main::@60 [phi:main::@59->main::@60]
    // main::@60
  __b60:
    // wait_moment()
    // [258] call wait_moment
    // [1157] phi from main::@60 to wait_moment [phi:main::@60->wait_moment]
    jsr wait_moment
    // [259] phi from main::@60 to main::@176 [phi:main::@60->main::@176]
    // main::@176
    // sprintf(info_text, "Your CX16 will reset (%03u) ...", w)
    // [260] call snprintf_init
    jsr snprintf_init
    // [261] phi from main::@176 to main::@177 [phi:main::@176->main::@177]
    // main::@177
    // sprintf(info_text, "Your CX16 will reset (%03u) ...", w)
    // [262] call printf_str
    // [745] phi from main::@177 to printf_str [phi:main::@177->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:main::@177->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = main::s21 [phi:main::@177->printf_str#1] -- pbuz1=pbuc1 
    lda #<s21
    sta.z printf_str.s
    lda #>s21
    sta.z printf_str.s+1
    jsr printf_str
    // main::@178
    // sprintf(info_text, "Your CX16 will reset (%03u) ...", w)
    // [263] printf_uchar::uvalue#10 = main::w1#2 -- vbum1=vbum2 
    lda w1
    sta printf_uchar.uvalue
    // [264] call printf_uchar
    // [1162] phi from main::@178 to printf_uchar [phi:main::@178->printf_uchar]
    // [1162] phi printf_uchar::format_zero_padding#11 = 1 [phi:main::@178->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1162] phi printf_uchar::format_min_length#11 = 3 [phi:main::@178->printf_uchar#1] -- vbum1=vbuc1 
    lda #3
    sta printf_uchar.format_min_length
    // [1162] phi printf_uchar::putc#11 = &snputc [phi:main::@178->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1162] phi printf_uchar::format_radix#11 = DECIMAL [phi:main::@178->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1162] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#10 [phi:main::@178->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [265] phi from main::@178 to main::@179 [phi:main::@178->main::@179]
    // main::@179
    // sprintf(info_text, "Your CX16 will reset (%03u) ...", w)
    // [266] call printf_str
    // [745] phi from main::@179 to printf_str [phi:main::@179->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:main::@179->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = main::s19 [phi:main::@179->printf_str#1] -- pbuz1=pbuc1 
    lda #<s19
    sta.z printf_str.s
    lda #>s19
    sta.z printf_str.s+1
    jsr printf_str
    // main::@180
    // sprintf(info_text, "Your CX16 will reset (%03u) ...", w)
    // [267] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [268] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_line(info_text)
    // [270] call display_info_line
    // [976] phi from main::@180 to display_info_line [phi:main::@180->display_info_line]
    // [976] phi display_info_line::info_text#19 = info_text [phi:main::@180->display_info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_line.info_text
    lda #>@info_text
    sta.z display_info_line.info_text+1
    jsr display_info_line
    // main::@181
    // for (unsigned char w=200; w>0; w--)
    // [271] main::w1#1 = -- main::w1#2 -- vbum1=_dec_vbum1 
    dec w1
    // [252] phi from main::@181 to main::@59 [phi:main::@181->main::@59]
    // [252] phi main::w1#2 = main::w1#1 [phi:main::@181->main::@59#0] -- register_copy 
    jmp __b59
    // main::@52
  __b52:
    // progress_text(l, debriefing_text[l])
    // [272] main::$194 = main::l#2 << 1 -- vbuz1=vbum2_rol_1 
    lda l
    asl
    sta.z main__194
    // [273] progress_text::line#2 = main::l#2 -- vbuz1=vbum2 
    lda l
    sta.z progress_text.line
    // [274] progress_text::text#2 = main::debriefing_text[main::$194] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z main__194
    lda debriefing_text,y
    sta.z progress_text.text
    lda debriefing_text+1,y
    sta.z progress_text.text+1
    // [275] call progress_text
    // [1173] phi from main::@52 to progress_text [phi:main::@52->progress_text]
    // [1173] phi progress_text::text#4 = progress_text::text#2 [phi:main::@52->progress_text#0] -- register_copy 
    // [1173] phi progress_text::line#4 = progress_text::line#2 [phi:main::@52->progress_text#1] -- register_copy 
    jsr progress_text
    // main::@165
    // for(unsigned char l=0; l<debriefing_count; l++)
    // [276] main::l#1 = ++ main::l#2 -- vbum1=_inc_vbum1 
    inc l
    // [250] phi from main::@165 to main::@51 [phi:main::@165->main::@51]
    // [250] phi main::l#2 = main::l#1 [phi:main::@165->main::@51#0] -- register_copy 
    jmp __b51
    // [277] phi from main::@85 to main::@53 [phi:main::@85->main::@53]
  __b7:
    // [277] phi main::l1#2 = 0 [phi:main::@85->main::@53#0] -- vbum1=vbuc1 
    lda #0
    sta l1
    // main::@53
  __b53:
    // for(unsigned char l=0; l<debriefing_count; l++)
    // [278] if(main::l1#2<main::debriefing_count1) goto main::@54 -- vbum1_lt_vbuc1_then_la1 
    lda l1
    cmp #debriefing_count1
    bcs !__b54+
    jmp __b54
  !__b54:
    // [279] phi from main::@53 to main::@55 [phi:main::@53->main::@55]
    // [279] phi main::w#2 = $80 [phi:main::@53->main::@55#0] -- vbum1=vbuc1 
    lda #$80
    sta w
    // main::@55
  __b55:
    // for (unsigned char w=128; w>0; w--)
    // [280] if(main::w#2>0) goto main::@56 -- vbum1_gt_0_then_la1 
    lda w
    bne __b56
    // [281] phi from main::@55 to main::@57 [phi:main::@55->main::@57]
    // main::@57
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [282] call snprintf_init
    jsr snprintf_init
    // [283] phi from main::@57 to main::@173 [phi:main::@57->main::@173]
    // main::@173
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [284] call printf_str
    // [745] phi from main::@173 to printf_str [phi:main::@173->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:main::@173->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = main::s20 [phi:main::@173->printf_str#1] -- pbuz1=pbuc1 
    lda #<s20
    sta.z printf_str.s
    lda #>s20
    sta.z printf_str.s+1
    jsr printf_str
    // main::@174
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [285] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [286] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_line(info_text)
    // [288] call display_info_line
    // [976] phi from main::@174 to display_info_line [phi:main::@174->display_info_line]
    // [976] phi display_info_line::info_text#19 = info_text [phi:main::@174->display_info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_line.info_text
    lda #>@info_text
    sta.z display_info_line.info_text+1
    jsr display_info_line
    // [289] phi from main::@174 to main::@175 [phi:main::@174->main::@175]
    // main::@175
    // smc_reset()
    // [290] call smc_reset
    // [1178] phi from main::@175 to smc_reset [phi:main::@175->smc_reset]
    jsr smc_reset
    jmp __b5
    // [291] phi from main::@55 to main::@56 [phi:main::@55->main::@56]
    // main::@56
  __b56:
    // wait_moment()
    // [292] call wait_moment
    // [1157] phi from main::@56 to wait_moment [phi:main::@56->wait_moment]
    jsr wait_moment
    // [293] phi from main::@56 to main::@167 [phi:main::@56->main::@167]
    // main::@167
    // sprintf(info_text, "Please read carefully the below (%u) ...", w)
    // [294] call snprintf_init
    jsr snprintf_init
    // [295] phi from main::@167 to main::@168 [phi:main::@167->main::@168]
    // main::@168
    // sprintf(info_text, "Please read carefully the below (%u) ...", w)
    // [296] call printf_str
    // [745] phi from main::@168 to printf_str [phi:main::@168->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:main::@168->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = main::s18 [phi:main::@168->printf_str#1] -- pbuz1=pbuc1 
    lda #<s18
    sta.z printf_str.s
    lda #>s18
    sta.z printf_str.s+1
    jsr printf_str
    // main::@169
    // sprintf(info_text, "Please read carefully the below (%u) ...", w)
    // [297] printf_uchar::uvalue#9 = main::w#2 -- vbum1=vbum2 
    lda w
    sta printf_uchar.uvalue
    // [298] call printf_uchar
    // [1162] phi from main::@169 to printf_uchar [phi:main::@169->printf_uchar]
    // [1162] phi printf_uchar::format_zero_padding#11 = 0 [phi:main::@169->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1162] phi printf_uchar::format_min_length#11 = 0 [phi:main::@169->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1162] phi printf_uchar::putc#11 = &snputc [phi:main::@169->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1162] phi printf_uchar::format_radix#11 = DECIMAL [phi:main::@169->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1162] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#9 [phi:main::@169->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [299] phi from main::@169 to main::@170 [phi:main::@169->main::@170]
    // main::@170
    // sprintf(info_text, "Please read carefully the below (%u) ...", w)
    // [300] call printf_str
    // [745] phi from main::@170 to printf_str [phi:main::@170->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:main::@170->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = main::s19 [phi:main::@170->printf_str#1] -- pbuz1=pbuc1 
    lda #<s19
    sta.z printf_str.s
    lda #>s19
    sta.z printf_str.s+1
    jsr printf_str
    // main::@171
    // sprintf(info_text, "Please read carefully the below (%u) ...", w)
    // [301] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [302] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_line(info_text)
    // [304] call display_info_line
    // [976] phi from main::@171 to display_info_line [phi:main::@171->display_info_line]
    // [976] phi display_info_line::info_text#19 = info_text [phi:main::@171->display_info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_line.info_text
    lda #>@info_text
    sta.z display_info_line.info_text+1
    jsr display_info_line
    // main::@172
    // for (unsigned char w=128; w>0; w--)
    // [305] main::w#1 = -- main::w#2 -- vbum1=_dec_vbum1 
    dec w
    // [279] phi from main::@172 to main::@55 [phi:main::@172->main::@55]
    // [279] phi main::w#2 = main::w#1 [phi:main::@172->main::@55#0] -- register_copy 
    jmp __b55
    // main::@54
  __b54:
    // progress_text(l, debriefing_text[l])
    // [306] main::$195 = main::l1#2 << 1 -- vbuz1=vbum2_rol_1 
    lda l1
    asl
    sta.z main__195
    // [307] progress_text::line#3 = main::l1#2 -- vbuz1=vbum2 
    lda l1
    sta.z progress_text.line
    // [308] progress_text::text#3 = main::debriefing_text1[main::$195] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z main__195
    lda debriefing_text1,y
    sta.z progress_text.text
    lda debriefing_text1+1,y
    sta.z progress_text.text+1
    // [309] call progress_text
    // [1173] phi from main::@54 to progress_text [phi:main::@54->progress_text]
    // [1173] phi progress_text::text#4 = progress_text::text#3 [phi:main::@54->progress_text#0] -- register_copy 
    // [1173] phi progress_text::line#4 = progress_text::line#3 [phi:main::@54->progress_text#1] -- register_copy 
    jsr progress_text
    // main::@166
    // for(unsigned char l=0; l<debriefing_count; l++)
    // [310] main::l1#1 = ++ main::l1#2 -- vbum1=_inc_vbum1 
    inc l1
    // [277] phi from main::@166 to main::@53 [phi:main::@166->main::@53]
    // [277] phi main::l1#2 = main::l1#1 [phi:main::@166->main::@53#0] -- register_copy 
    jmp __b53
    // main::vera_display_set_border_color3
  vera_display_set_border_color3:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [311] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [312] *VERA_DC_BORDER = YELLOW -- _deref_pbuc1=vbuc2 
    lda #YELLOW
    sta VERA_DC_BORDER
    // [313] phi from main::vera_display_set_border_color3 to main::@84 [phi:main::vera_display_set_border_color3->main::@84]
    // main::@84
    // display_info_progress("Update issues, your CX16 is not updated!")
    // [314] call display_info_progress
    // [711] phi from main::@84 to display_info_progress [phi:main::@84->display_info_progress]
    // [711] phi display_info_progress::info_text#14 = main::info_text31 [phi:main::@84->display_info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text31
    sta.z display_info_progress.info_text
    lda #>info_text31
    sta.z display_info_progress.info_text+1
    jsr display_info_progress
    jmp __b5
    // main::check_roms2_check_rom1
  check_roms2_check_rom1:
    // status_rom[rom_chip] == status
    // [315] main::check_roms2_check_rom1_$0 = status_rom[main::check_roms2_rom_chip#2] == STATUS_ISSUE -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_ISSUE
    ldy check_roms2_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_roms2_check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [316] main::check_roms2_check_rom1_return#0 = (char)main::check_roms2_check_rom1_$0 -- vbum1=vbuz2 
    sta check_roms2_check_rom1_return
    // main::check_roms2_@11
    // if(check_rom(rom_chip, status) == status)
    // [317] if(main::check_roms2_check_rom1_return#0!=STATUS_ISSUE) goto main::check_roms2_@4 -- vbum1_neq_vbuc1_then_la1 
    lda #STATUS_ISSUE
    cmp check_roms2_check_rom1_return
    bne check_roms2___b4
    // [241] phi from main::check_roms2_@11 to main::check_roms2_@return [phi:main::check_roms2_@11->main::check_roms2_@return]
    // [241] phi main::check_roms2_return#2 = STATUS_ISSUE [phi:main::check_roms2_@11->main::check_roms2_@return#0] -- vbum1=vbuc1 
    sta check_roms2_return
    jmp __b83
    // main::check_roms2_@4
  check_roms2___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [318] main::check_roms2_rom_chip#1 = ++ main::check_roms2_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_roms2_rom_chip
    // [239] phi from main::check_roms2_@4 to main::check_roms2_@1 [phi:main::check_roms2_@4->main::check_roms2_@1]
    // [239] phi main::check_roms2_rom_chip#2 = main::check_roms2_rom_chip#1 [phi:main::check_roms2_@4->main::check_roms2_@1#0] -- register_copy 
    jmp check_roms2___b1
    // main::vera_display_set_border_color2
  vera_display_set_border_color2:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [319] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [320] *VERA_DC_BORDER = RED -- _deref_pbuc1=vbuc2 
    lda #RED
    sta VERA_DC_BORDER
    // [321] phi from main::vera_display_set_border_color2 to main::@82 [phi:main::vera_display_set_border_color2->main::@82]
    // main::@82
    // display_info_progress("Update Failure! Your CX16 may be bricked!")
    // [322] call display_info_progress
    // [711] phi from main::@82 to display_info_progress [phi:main::@82->display_info_progress]
    // [711] phi display_info_progress::info_text#14 = main::info_text29 [phi:main::@82->display_info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text29
    sta.z display_info_progress.info_text
    lda #>info_text29
    sta.z display_info_progress.info_text+1
    jsr display_info_progress
    // [323] phi from main::@82 to main::@164 [phi:main::@82->main::@164]
    // main::@164
    // display_info_line("Take a foto of this screen. And shut down power ...")
    // [324] call display_info_line
    // [976] phi from main::@164 to display_info_line [phi:main::@164->display_info_line]
    // [976] phi display_info_line::info_text#19 = main::info_text30 [phi:main::@164->display_info_line#0] -- pbuz1=pbuc1 
    lda #<info_text30
    sta.z display_info_line.info_text
    lda #>info_text30
    sta.z display_info_line.info_text+1
    jsr display_info_line
    // [325] phi from main::@164 main::@58 to main::@58 [phi:main::@164/main::@58->main::@58]
    // main::@58
  __b58:
    jmp __b58
    // main::check_roms1_check_rom1
  check_roms1_check_rom1:
    // status_rom[rom_chip] == status
    // [326] main::check_roms1_check_rom1_$0 = status_rom[main::check_roms1_rom_chip#2] == STATUS_ERROR -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_ERROR
    ldy check_roms1_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_roms1_check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [327] main::check_roms1_check_rom1_return#0 = (char)main::check_roms1_check_rom1_$0 -- vbum1=vbuz2 
    sta check_roms1_check_rom1_return
    // main::check_roms1_@11
    // if(check_rom(rom_chip, status) == status)
    // [328] if(main::check_roms1_check_rom1_return#0!=STATUS_ERROR) goto main::check_roms1_@4 -- vbum1_neq_vbuc1_then_la1 
    lda #STATUS_ERROR
    cmp check_roms1_check_rom1_return
    bne check_roms1___b4
    // [230] phi from main::check_roms1_@11 to main::check_roms1_@return [phi:main::check_roms1_@11->main::check_roms1_@return]
    // [230] phi main::check_roms1_return#2 = STATUS_ERROR [phi:main::check_roms1_@11->main::check_roms1_@return#0] -- vbum1=vbuc1 
    sta check_roms1_return
    jmp __b81
    // main::check_roms1_@4
  check_roms1___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [329] main::check_roms1_rom_chip#1 = ++ main::check_roms1_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_roms1_rom_chip
    // [228] phi from main::check_roms1_@4 to main::check_roms1_@1 [phi:main::check_roms1_@4->main::check_roms1_@1]
    // [228] phi main::check_roms1_rom_chip#2 = main::check_roms1_rom_chip#1 [phi:main::check_roms1_@4->main::check_roms1_@1#0] -- register_copy 
    jmp check_roms1___b1
    // main::vera_display_set_border_color1
  vera_display_set_border_color1:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [330] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [331] *VERA_DC_BORDER = BLACK -- _deref_pbuc1=vbuc2 
    lda #BLACK
    sta VERA_DC_BORDER
    // [332] phi from main::vera_display_set_border_color1 to main::@80 [phi:main::vera_display_set_border_color1->main::@80]
    // main::@80
    // display_info_progress("The update has been cancelled!")
    // [333] call display_info_progress
    // [711] phi from main::@80 to display_info_progress [phi:main::@80->display_info_progress]
    // [711] phi display_info_progress::info_text#14 = main::info_text28 [phi:main::@80->display_info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text28
    sta.z display_info_progress.info_text
    lda #>info_text28
    sta.z display_info_progress.info_text+1
    jsr display_info_progress
    jmp __b5
    // main::check_roms_all1_check_rom1
  check_roms_all1_check_rom1:
    // status_rom[rom_chip] == status
    // [334] main::check_roms_all1_check_rom1_$0 = status_rom[main::check_roms_all1_rom_chip#2] == STATUS_SKIP -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_SKIP
    ldy check_roms_all1_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_roms_all1_check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [335] main::check_roms_all1_check_rom1_return#0 = (char)main::check_roms_all1_check_rom1_$0 -- vbum1=vbuz2 
    sta check_roms_all1_check_rom1_return
    // main::check_roms_all1_@11
    // if(check_rom(rom_chip, status) != status)
    // [336] if(main::check_roms_all1_check_rom1_return#0==STATUS_SKIP) goto main::check_roms_all1_@4 -- vbum1_eq_vbuc1_then_la1 
    lda #STATUS_SKIP
    cmp check_roms_all1_check_rom1_return
    beq check_roms_all1___b4
    // [219] phi from main::check_roms_all1_@11 to main::check_roms_all1_@return [phi:main::check_roms_all1_@11->main::check_roms_all1_@return]
    // [219] phi main::check_roms_all1_return#2 = 0 [phi:main::check_roms_all1_@11->main::check_roms_all1_@return#0] -- vbum1=vbuc1 
    lda #0
    sta check_roms_all1_return
    jmp __b77
    // main::check_roms_all1_@4
  check_roms_all1___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [337] main::check_roms_all1_rom_chip#1 = ++ main::check_roms_all1_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_roms_all1_rom_chip
    // [217] phi from main::check_roms_all1_@4 to main::check_roms_all1_@1 [phi:main::check_roms_all1_@4->main::check_roms_all1_@1]
    // [217] phi main::check_roms_all1_rom_chip#2 = main::check_roms_all1_rom_chip#1 [phi:main::check_roms_all1_@4->main::check_roms_all1_@1#0] -- register_copy 
    jmp check_roms_all1___b1
    // main::check_rom1
  check_rom1:
    // status_rom[rom_chip] == status
    // [338] main::check_rom1_$0 = status_rom[main::rom_chip3#10] == STATUS_FLASH -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_FLASH
    ldy rom_chip3
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [339] main::check_rom1_return#0 = (char)main::check_rom1_$0 -- vbum1=vbuz2 
    sta check_rom1_return
    // main::@75
    // if(check_rom(rom_chip, STATUS_FLASH))
    // [340] if(0==main::check_rom1_return#0) goto main::@44 -- 0_eq_vbum1_then_la1 
    beq __b44
    // main::check_smc6
    // status_smc == status
    // [341] main::check_smc6_$0 = status_smc#0 == STATUS_FLASHED -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASHED
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_smc6_main__0
    // return (unsigned char)(status_smc == status);
    // [342] main::check_smc6_return#0 = (char)main::check_smc6_$0 -- vbum1=vbuz2 
    sta check_smc6_return
    // main::@78
    // if((rom_chip == 0 && check_smc(STATUS_FLASHED)) || (rom_chip != 0))
    // [343] if(main::rom_chip3#10!=0) goto main::@187 -- vbum1_neq_0_then_la1 
    // IMPORTANT! We only flash the CX16 ROM chip if the SMC got flashed succesfully!
    lda rom_chip3
    bne __b187
    // main::@188
    // [344] if(0!=main::check_smc6_return#0) goto main::bank_set_brom5 -- 0_neq_vbum1_then_la1 
    lda check_smc6_return
    bne bank_set_brom5
    // main::@187
  __b187:
    // [345] if(main::rom_chip3#10!=0) goto main::bank_set_brom5 -- vbum1_neq_0_then_la1 
    lda rom_chip3
    bne bank_set_brom5
    // main::@50
    // info_rom(rom_chip, STATUS_ISSUE, "Update SMC failed!")
    // [346] info_rom::rom_chip#10 = main::rom_chip3#10 -- vbuz1=vbum2 
    sta.z info_rom.rom_chip
    // [347] call info_rom
    // [1187] phi from main::@50 to info_rom [phi:main::@50->info_rom]
    // [1187] phi info_rom::info_text#16 = main::info_text23 [phi:main::@50->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text23
    sta.z info_rom.info_text
    lda #>info_text23
    sta.z info_rom.info_text+1
    // [1187] phi info_rom::rom_chip#16 = info_rom::rom_chip#10 [phi:main::@50->info_rom#1] -- register_copy 
    // [1187] phi info_rom::info_status#16 = STATUS_ISSUE [phi:main::@50->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z info_rom.info_status
    jsr info_rom
    // [348] phi from main::@152 main::@163 main::@45 main::@49 main::@50 main::@75 to main::@44 [phi:main::@152/main::@163/main::@45/main::@49/main::@50/main::@75->main::@44]
    // [348] phi __errno#394 = __errno#18 [phi:main::@152/main::@163/main::@45/main::@49/main::@50/main::@75->main::@44#0] -- register_copy 
    // main::@44
  __b44:
    // for(unsigned char rom_chip = 7; rom_chip != 255; rom_chip--)
    // [349] main::rom_chip3#1 = -- main::rom_chip3#10 -- vbum1=_dec_vbum1 
    dec rom_chip3
    // [204] phi from main::@44 to main::@43 [phi:main::@44->main::@43]
    // [204] phi __errno#114 = __errno#394 [phi:main::@44->main::@43#0] -- register_copy 
    // [204] phi main::rom_chip3#10 = main::rom_chip3#1 [phi:main::@44->main::@43#1] -- register_copy 
    jmp __b43
    // main::bank_set_brom5
  bank_set_brom5:
    // BROM = bank
    // [350] BROM = main::bank_set_brom5_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom5_bank
    sta.z BROM
    // [351] phi from main::bank_set_brom5 to main::@79 [phi:main::bank_set_brom5->main::@79]
    // main::@79
    // display_progress_clear()
    // [352] call display_progress_clear
    // [696] phi from main::@79 to display_progress_clear [phi:main::@79->display_progress_clear]
    jsr display_progress_clear
    // main::@145
    // unsigned char rom_bank = rom_chip * 32
    // [353] main::rom_bank1#0 = main::rom_chip3#10 << 5 -- vbum1=vbum2_rol_5 
    lda rom_chip3
    asl
    asl
    asl
    asl
    asl
    sta rom_bank1
    // unsigned char* file = rom_file(rom_chip)
    // [354] rom_file::rom_chip#1 = main::rom_chip3#10 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z rom_file.rom_chip
    // [355] call rom_file
    // [1232] phi from main::@145 to rom_file [phi:main::@145->rom_file]
    // [1232] phi rom_file::rom_chip#2 = rom_file::rom_chip#1 [phi:main::@145->rom_file#0] -- register_copy 
    jsr rom_file
    // unsigned char* file = rom_file(rom_chip)
    // [356] rom_file::return#5 = rom_file::return#2
    // main::@146
    // [357] main::file1#0 = rom_file::return#5
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [358] call snprintf_init
    jsr snprintf_init
    // [359] phi from main::@146 to main::@147 [phi:main::@146->main::@147]
    // main::@147
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [360] call printf_str
    // [745] phi from main::@147 to printf_str [phi:main::@147->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:main::@147->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = s14 [phi:main::@147->printf_str#1] -- pbuz1=pbuc1 
    lda #<s14
    sta.z printf_str.s
    lda #>s14
    sta.z printf_str.s+1
    jsr printf_str
    // main::@148
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [361] printf_string::str#17 = main::file1#0 -- pbuz1=pbuz2 
    lda.z file1
    sta.z printf_string.str
    lda.z file1+1
    sta.z printf_string.str+1
    // [362] call printf_string
    // [1238] phi from main::@148 to printf_string [phi:main::@148->printf_string]
    // [1238] phi printf_string::putc#18 = &snputc [phi:main::@148->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1238] phi printf_string::str#18 = printf_string::str#17 [phi:main::@148->printf_string#1] -- register_copy 
    // [1238] phi printf_string::format_justify_left#18 = 0 [phi:main::@148->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1238] phi printf_string::format_min_length#18 = 0 [phi:main::@148->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [363] phi from main::@148 to main::@149 [phi:main::@148->main::@149]
    // main::@149
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [364] call printf_str
    // [745] phi from main::@149 to printf_str [phi:main::@149->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:main::@149->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = main::s7 [phi:main::@149->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@150
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [365] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [366] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_progress(info_text)
    // [368] call display_info_progress
    // [711] phi from main::@150 to display_info_progress [phi:main::@150->display_info_progress]
    // [711] phi display_info_progress::info_text#14 = info_text [phi:main::@150->display_info_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_progress.info_text
    lda #>@info_text
    sta.z display_info_progress.info_text+1
    jsr display_info_progress
    // main::@151
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_READING, rom_bank, rom_sizes[rom_chip])
    // [369] main::$192 = main::rom_chip3#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip3
    asl
    asl
    sta.z main__192
    // [370] rom_read::file#1 = main::file1#0 -- pbuz1=pbuz2 
    lda.z file1
    sta.z rom_read.file
    lda.z file1+1
    sta.z rom_read.file+1
    // [371] rom_read::brom_bank_start#2 = main::rom_bank1#0 -- vbuz1=vbum2 
    lda rom_bank1
    sta.z rom_read.brom_bank_start
    // [372] rom_read::rom_size#1 = rom_sizes[main::$192] -- vduz1=pduc1_derefidx_vbuz2 
    ldy.z main__192
    lda rom_sizes,y
    sta.z rom_read.rom_size
    lda rom_sizes+1,y
    sta.z rom_read.rom_size+1
    lda rom_sizes+2,y
    sta.z rom_read.rom_size+2
    lda rom_sizes+3,y
    sta.z rom_read.rom_size+3
    // [373] call rom_read
    // [1263] phi from main::@151 to rom_read [phi:main::@151->rom_read]
    // [1263] phi rom_read::rom_size#12 = rom_read::rom_size#1 [phi:main::@151->rom_read#0] -- register_copy 
    // [1263] phi __errno#106 = __errno#114 [phi:main::@151->rom_read#1] -- register_copy 
    // [1263] phi rom_read::file#11 = rom_read::file#1 [phi:main::@151->rom_read#2] -- register_copy 
    // [1263] phi rom_read::brom_bank_start#21 = rom_read::brom_bank_start#2 [phi:main::@151->rom_read#3] -- register_copy 
    jsr rom_read
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_READING, rom_bank, rom_sizes[rom_chip])
    // [374] rom_read::return#3 = rom_read::return#0
    // main::@152
    // [375] main::rom_bytes_read1#0 = rom_read::return#3
    // if(rom_bytes_read)
    // [376] if(0==main::rom_bytes_read1#0) goto main::@44 -- 0_eq_vdum1_then_la1 
    lda rom_bytes_read1
    ora rom_bytes_read1+1
    ora rom_bytes_read1+2
    ora rom_bytes_read1+3
    bne !__b44+
    jmp __b44
  !__b44:
    // [377] phi from main::@152 to main::@47 [phi:main::@152->main::@47]
    // main::@47
    // display_info_progress("Comparing ... (.) same, (*) different.")
    // [378] call display_info_progress
  // Now we compare the RAM with the actual ROM contents.
    // [711] phi from main::@47 to display_info_progress [phi:main::@47->display_info_progress]
    // [711] phi display_info_progress::info_text#14 = main::info_text24 [phi:main::@47->display_info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text24
    sta.z display_info_progress.info_text
    lda #>info_text24
    sta.z display_info_progress.info_text+1
    jsr display_info_progress
    // main::@153
    // info_rom(rom_chip, STATUS_COMPARING, "")
    // [379] info_rom::rom_chip#11 = main::rom_chip3#10 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z info_rom.rom_chip
    // [380] call info_rom
    // [1187] phi from main::@153 to info_rom [phi:main::@153->info_rom]
    // [1187] phi info_rom::info_text#16 = info_text4 [phi:main::@153->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z info_rom.info_text
    lda #>info_text4
    sta.z info_rom.info_text+1
    // [1187] phi info_rom::rom_chip#16 = info_rom::rom_chip#11 [phi:main::@153->info_rom#1] -- register_copy 
    // [1187] phi info_rom::info_status#16 = STATUS_COMPARING [phi:main::@153->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_COMPARING
    sta.z info_rom.info_status
    jsr info_rom
    // main::@154
    // unsigned long rom_differences = rom_verify(
    //                         rom_chip, rom_bank, file_sizes[rom_chip])
    // [381] rom_verify::rom_chip#0 = main::rom_chip3#10 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z rom_verify.rom_chip
    // [382] rom_verify::rom_bank_start#0 = main::rom_bank1#0 -- vbuz1=vbum2 
    lda rom_bank1
    sta.z rom_verify.rom_bank_start
    // [383] rom_verify::file_size#0 = file_sizes[main::$192] -- vduz1=pduc1_derefidx_vbuz2 
    ldy.z main__192
    lda file_sizes,y
    sta.z rom_verify.file_size
    lda file_sizes+1,y
    sta.z rom_verify.file_size+1
    lda file_sizes+2,y
    sta.z rom_verify.file_size+2
    lda file_sizes+3,y
    sta.z rom_verify.file_size+3
    // [384] call rom_verify
    // Verify the ROM...
    jsr rom_verify
    // [385] rom_verify::return#2 = rom_verify::rom_different_bytes#11
    // main::@155
    // [386] main::rom_differences#0 = rom_verify::return#2 -- vdum1=vdum2 
    lda rom_verify.return
    sta rom_differences
    lda rom_verify.return+1
    sta rom_differences+1
    lda rom_verify.return+2
    sta rom_differences+2
    lda rom_verify.return+3
    sta rom_differences+3
    // if (!rom_differences)
    // [387] if(0==main::rom_differences#0) goto main::@45 -- 0_eq_vdum1_then_la1 
    lda rom_differences
    ora rom_differences+1
    ora rom_differences+2
    ora rom_differences+3
    bne !__b45+
    jmp __b45
  !__b45:
    // [388] phi from main::@155 to main::@48 [phi:main::@155->main::@48]
    // main::@48
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [389] call snprintf_init
    jsr snprintf_init
    // main::@156
    // [390] printf_ulong::uvalue#9 = main::rom_differences#0
    // [391] call printf_ulong
    // [1413] phi from main::@156 to printf_ulong [phi:main::@156->printf_ulong]
    // [1413] phi printf_ulong::format_zero_padding#11 = 1 [phi:main::@156->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1413] phi printf_ulong::format_min_length#11 = 5 [phi:main::@156->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1413] phi printf_ulong::putc#11 = &snputc [phi:main::@156->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1413] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:main::@156->printf_ulong#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1413] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#9 [phi:main::@156->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [392] phi from main::@156 to main::@157 [phi:main::@156->main::@157]
    // main::@157
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [393] call printf_str
    // [745] phi from main::@157 to printf_str [phi:main::@157->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:main::@157->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = main::s16 [phi:main::@157->printf_str#1] -- pbuz1=pbuc1 
    lda #<s16
    sta.z printf_str.s
    lda #>s16
    sta.z printf_str.s+1
    jsr printf_str
    // main::@158
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [394] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [395] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom(rom_chip, STATUS_FLASH, info_text)
    // [397] info_rom::rom_chip#13 = main::rom_chip3#10 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z info_rom.rom_chip
    // [398] call info_rom
    // [1187] phi from main::@158 to info_rom [phi:main::@158->info_rom]
    // [1187] phi info_rom::info_text#16 = info_text [phi:main::@158->info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_rom.info_text
    lda #>@info_text
    sta.z info_rom.info_text+1
    // [1187] phi info_rom::rom_chip#16 = info_rom::rom_chip#13 [phi:main::@158->info_rom#1] -- register_copy 
    // [1187] phi info_rom::info_status#16 = STATUS_FLASH [phi:main::@158->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASH
    sta.z info_rom.info_status
    jsr info_rom
    // main::@159
    // unsigned long rom_flash_errors = rom_flash(
    //                             rom_chip, rom_bank, file_sizes[rom_chip])
    // [399] rom_flash::rom_chip#0 = main::rom_chip3#10 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z rom_flash.rom_chip
    // [400] rom_flash::rom_bank_start#0 = main::rom_bank1#0 -- vbuz1=vbum2 
    lda rom_bank1
    sta.z rom_flash.rom_bank_start
    // [401] rom_flash::file_size#0 = file_sizes[main::$192] -- vduz1=pduc1_derefidx_vbuz2 
    ldy.z main__192
    lda file_sizes,y
    sta.z rom_flash.file_size
    lda file_sizes+1,y
    sta.z rom_flash.file_size+1
    lda file_sizes+2,y
    sta.z rom_flash.file_size+2
    lda file_sizes+3,y
    sta.z rom_flash.file_size+3
    // [402] call rom_flash
    // [1424] phi from main::@159 to rom_flash [phi:main::@159->rom_flash]
    jsr rom_flash
    // unsigned long rom_flash_errors = rom_flash(
    //                             rom_chip, rom_bank, file_sizes[rom_chip])
    // [403] rom_flash::return#2 = rom_flash::flash_errors#10
    // main::@160
    // [404] main::rom_flash_errors#0 = rom_flash::return#2 -- vdum1=vdum2 
    lda rom_flash.return
    sta rom_flash_errors
    lda rom_flash.return+1
    sta rom_flash_errors+1
    lda rom_flash.return+2
    sta rom_flash_errors+2
    lda rom_flash.return+3
    sta rom_flash_errors+3
    // if(rom_flash_errors)
    // [405] if(0!=main::rom_flash_errors#0) goto main::@46 -- 0_neq_vdum1_then_la1 
    lda rom_flash_errors
    ora rom_flash_errors+1
    ora rom_flash_errors+2
    ora rom_flash_errors+3
    bne __b46
    // main::@49
    // info_rom(rom_chip, STATUS_FLASHED, "OK!")
    // [406] info_rom::rom_chip#15 = main::rom_chip3#10 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z info_rom.rom_chip
    // [407] call info_rom
    // [1187] phi from main::@49 to info_rom [phi:main::@49->info_rom]
    // [1187] phi info_rom::info_text#16 = main::info_text27 [phi:main::@49->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text27
    sta.z info_rom.info_text
    lda #>info_text27
    sta.z info_rom.info_text+1
    // [1187] phi info_rom::rom_chip#16 = info_rom::rom_chip#15 [phi:main::@49->info_rom#1] -- register_copy 
    // [1187] phi info_rom::info_status#16 = STATUS_FLASHED [phi:main::@49->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHED
    sta.z info_rom.info_status
    jsr info_rom
    jmp __b44
    // [408] phi from main::@160 to main::@46 [phi:main::@160->main::@46]
    // main::@46
  __b46:
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [409] call snprintf_init
    jsr snprintf_init
    // main::@161
    // [410] printf_ulong::uvalue#10 = main::rom_flash_errors#0 -- vdum1=vdum2 
    lda rom_flash_errors
    sta printf_ulong.uvalue
    lda rom_flash_errors+1
    sta printf_ulong.uvalue+1
    lda rom_flash_errors+2
    sta printf_ulong.uvalue+2
    lda rom_flash_errors+3
    sta printf_ulong.uvalue+3
    // [411] call printf_ulong
    // [1413] phi from main::@161 to printf_ulong [phi:main::@161->printf_ulong]
    // [1413] phi printf_ulong::format_zero_padding#11 = 0 [phi:main::@161->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1413] phi printf_ulong::format_min_length#11 = 0 [phi:main::@161->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1413] phi printf_ulong::putc#11 = &snputc [phi:main::@161->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1413] phi printf_ulong::format_radix#11 = DECIMAL [phi:main::@161->printf_ulong#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1413] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#10 [phi:main::@161->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [412] phi from main::@161 to main::@162 [phi:main::@161->main::@162]
    // main::@162
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [413] call printf_str
    // [745] phi from main::@162 to printf_str [phi:main::@162->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:main::@162->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = main::s17 [phi:main::@162->printf_str#1] -- pbuz1=pbuc1 
    lda #<s17
    sta.z printf_str.s
    lda #>s17
    sta.z printf_str.s+1
    jsr printf_str
    // main::@163
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [414] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [415] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom(rom_chip, STATUS_ERROR, info_text)
    // [417] info_rom::rom_chip#14 = main::rom_chip3#10 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z info_rom.rom_chip
    // [418] call info_rom
    // [1187] phi from main::@163 to info_rom [phi:main::@163->info_rom]
    // [1187] phi info_rom::info_text#16 = info_text [phi:main::@163->info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_rom.info_text
    lda #>@info_text
    sta.z info_rom.info_text+1
    // [1187] phi info_rom::rom_chip#16 = info_rom::rom_chip#14 [phi:main::@163->info_rom#1] -- register_copy 
    // [1187] phi info_rom::info_status#16 = STATUS_ERROR [phi:main::@163->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z info_rom.info_status
    jsr info_rom
    jmp __b44
    // main::@45
  __b45:
    // info_rom(rom_chip, STATUS_FLASHED, "No update required")
    // [419] info_rom::rom_chip#12 = main::rom_chip3#10 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z info_rom.rom_chip
    // [420] call info_rom
    // [1187] phi from main::@45 to info_rom [phi:main::@45->info_rom]
    // [1187] phi info_rom::info_text#16 = main::info_text26 [phi:main::@45->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text26
    sta.z info_rom.info_text
    lda #>info_text26
    sta.z info_rom.info_text+1
    // [1187] phi info_rom::rom_chip#16 = info_rom::rom_chip#12 [phi:main::@45->info_rom#1] -- register_copy 
    // [1187] phi info_rom::info_status#16 = STATUS_FLASHED [phi:main::@45->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHED
    sta.z info_rom.info_status
    jsr info_rom
    jmp __b44
    // main::@42
  __b42:
    // [421] smc_file_size#374 = smc_file_size#1 -- vwum1=vwum2 
    lda smc_file_size_1
    sta smc_file_size_2
    lda smc_file_size_1+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_FLASHED, "")
    // [422] call display_info_smc
    // [765] phi from main::@42 to display_info_smc [phi:main::@42->display_info_smc]
    // [765] phi display_info_smc::info_text#12 = info_text4 [phi:main::@42->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z display_info_smc.info_text
    lda #>info_text4
    sta.z display_info_smc.info_text+1
    // [765] phi smc_file_size#12 = smc_file_size#374 [phi:main::@42->display_info_smc#1] -- register_copy 
    // [765] phi display_info_smc::info_status#12 = STATUS_FLASHED [phi:main::@42->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHED
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp __b2
    // [423] phi from main::@183 main::@184 to main::@6 [phi:main::@183/main::@184->main::@6]
    // main::@6
  __b6:
    // display_info_progress("Chipsets have been detected and update files validated!")
    // [424] call display_info_progress
    // [711] phi from main::@6 to display_info_progress [phi:main::@6->display_info_progress]
    // [711] phi display_info_progress::info_text#14 = main::info_text12 [phi:main::@6->display_info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text12
    sta.z display_info_progress.info_text
    lda #>info_text12
    sta.z display_info_progress.info_text+1
    jsr display_info_progress
    // [425] phi from main::@6 to main::@135 [phi:main::@6->main::@135]
    // main::@135
    // unsigned char ch = util_wait_key("Continue with update? [Y/N]", "nyNY")
    // [426] call util_wait_key
    // [895] phi from main::@135 to util_wait_key [phi:main::@135->util_wait_key]
    // [895] phi util_wait_key::filter#14 = main::filter3 [phi:main::@135->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter3
    sta.z util_wait_key.filter
    lda #>filter3
    sta.z util_wait_key.filter+1
    // [895] phi util_wait_key::info_text#4 = main::info_text13 [phi:main::@135->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text13
    sta.z util_wait_key.info_text
    lda #>info_text13
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("Continue with update? [Y/N]", "nyNY")
    // [427] util_wait_key::return#5 = util_wait_key::ch#4 -- vbum1=vwum2 
    lda util_wait_key.ch
    sta util_wait_key.return
    // main::@136
    // [428] main::ch#0 = util_wait_key::return#5
    // strchr("nN", ch)
    // [429] strchr::c#1 = main::ch#0
    // [430] call strchr
    // [1539] phi from main::@136 to strchr [phi:main::@136->strchr]
    // [1539] phi strchr::c#4 = strchr::c#1 [phi:main::@136->strchr#0] -- register_copy 
    // [1539] phi strchr::str#2 = (const void *)main::$212 [phi:main::@136->strchr#1] -- pvoz1=pvoc1 
    lda #<main__212
    sta.z strchr.str
    lda #>main__212
    sta.z strchr.str+1
    jsr strchr
    // strchr("nN", ch)
    // [431] strchr::return#4 = strchr::return#2
    // main::@137
    // [432] main::$108 = strchr::return#4
    // if(strchr("nN", ch))
    // [433] if((void *)0==main::$108) goto main::SEI5 -- pvoc1_eq_pvoz1_then_la1 
    lda.z main__108
    cmp #<0
    bne !+
    lda.z main__108+1
    cmp #>0
    bne !SEI5+
    jmp SEI5
  !SEI5:
  !:
    // main::@7
    // [434] smc_file_size#367 = smc_file_size#207 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_SKIP, "Cancelled")
    // [435] call display_info_smc
  // We cancel all updates, the updates are skipped.
    // [765] phi from main::@7 to display_info_smc [phi:main::@7->display_info_smc]
    // [765] phi display_info_smc::info_text#12 = main::info_text14 [phi:main::@7->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text14
    sta.z display_info_smc.info_text
    lda #>info_text14
    sta.z display_info_smc.info_text+1
    // [765] phi smc_file_size#12 = smc_file_size#367 [phi:main::@7->display_info_smc#1] -- register_copy 
    // [765] phi display_info_smc::info_status#12 = STATUS_SKIP [phi:main::@7->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [436] phi from main::@7 to main::@138 [phi:main::@7->main::@138]
    // main::@138
    // display_info_vera(STATUS_SKIP, "Cancelled")
    // [437] call display_info_vera
    // [800] phi from main::@138 to display_info_vera [phi:main::@138->display_info_vera]
    // [800] phi display_info_vera::info_text#10 = main::info_text14 [phi:main::@138->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text14
    sta.z display_info_vera.info_text
    lda #>info_text14
    sta.z display_info_vera.info_text+1
    // [800] phi display_info_vera::info_status#2 = STATUS_SKIP [phi:main::@138->display_info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // [438] phi from main::@138 to main::@39 [phi:main::@138->main::@39]
    // [438] phi main::rom_chip2#2 = 0 [phi:main::@138->main::@39#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip2
    // main::@39
  __b39:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [439] if(main::rom_chip2#2<8) goto main::@40 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip2
    cmp #8
    bcc __b40
    // [440] phi from main::@39 to main::@41 [phi:main::@39->main::@41]
    // main::@41
    // display_info_line("You have selected not to cancel the update ... ")
    // [441] call display_info_line
    // [976] phi from main::@41 to display_info_line [phi:main::@41->display_info_line]
    // [976] phi display_info_line::info_text#19 = main::info_text17 [phi:main::@41->display_info_line#0] -- pbuz1=pbuc1 
    lda #<info_text17
    sta.z display_info_line.info_text
    lda #>info_text17
    sta.z display_info_line.info_text+1
    jsr display_info_line
    jmp SEI5
    // main::@40
  __b40:
    // info_rom(rom_chip, STATUS_SKIP, "Cancelled")
    // [442] info_rom::rom_chip#9 = main::rom_chip2#2 -- vbuz1=vbum2 
    lda rom_chip2
    sta.z info_rom.rom_chip
    // [443] call info_rom
    // [1187] phi from main::@40 to info_rom [phi:main::@40->info_rom]
    // [1187] phi info_rom::info_text#16 = main::info_text14 [phi:main::@40->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text14
    sta.z info_rom.info_text
    lda #>info_text14
    sta.z info_rom.info_text+1
    // [1187] phi info_rom::rom_chip#16 = info_rom::rom_chip#9 [phi:main::@40->info_rom#1] -- register_copy 
    // [1187] phi info_rom::info_status#16 = STATUS_SKIP [phi:main::@40->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z info_rom.info_status
    jsr info_rom
    // main::@139
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [444] main::rom_chip2#1 = ++ main::rom_chip2#2 -- vbum1=_inc_vbum1 
    inc rom_chip2
    // [438] phi from main::@139 to main::@39 [phi:main::@139->main::@39]
    // [438] phi main::rom_chip2#2 = main::rom_chip2#1 [phi:main::@139->main::@39#0] -- register_copy 
    jmp __b39
    // main::check_card_roms1_check_rom1
  check_card_roms1_check_rom1:
    // status_rom[rom_chip] == status
    // [445] main::check_card_roms1_check_rom1_$0 = status_rom[main::check_card_roms1_rom_chip#2] == STATUS_FLASH -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_FLASH
    ldy check_card_roms1_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_card_roms1_check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [446] main::check_card_roms1_check_rom1_return#0 = (char)main::check_card_roms1_check_rom1_$0 -- vbum1=vbuz2 
    sta check_card_roms1_check_rom1_return
    // main::check_card_roms1_@11
    // if(check_rom(rom_chip, status))
    // [447] if(0==main::check_card_roms1_check_rom1_return#0) goto main::check_card_roms1_@4 -- 0_eq_vbum1_then_la1 
    beq check_card_roms1___b4
    // [179] phi from main::check_card_roms1_@11 to main::check_card_roms1_@return [phi:main::check_card_roms1_@11->main::check_card_roms1_@return]
    // [179] phi main::check_card_roms1_return#2 = STATUS_FLASH [phi:main::check_card_roms1_@11->main::check_card_roms1_@return#0] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta check_card_roms1_return
    jmp __b73
    // main::check_card_roms1_@4
  check_card_roms1___b4:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [448] main::check_card_roms1_rom_chip#1 = ++ main::check_card_roms1_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_card_roms1_rom_chip
    // [177] phi from main::check_card_roms1_@4 to main::check_card_roms1_@1 [phi:main::check_card_roms1_@4->main::check_card_roms1_@1]
    // [177] phi main::check_card_roms1_rom_chip#2 = main::check_card_roms1_rom_chip#1 [phi:main::check_card_roms1_@4->main::check_card_roms1_@1#0] -- register_copy 
    jmp check_card_roms1___b1
    // main::@38
  __b38:
    // [449] smc_file_size#373 = smc_file_size#207 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_ISSUE, NULL)
    // [450] call display_info_smc
    // [765] phi from main::@38 to display_info_smc [phi:main::@38->display_info_smc]
    // [765] phi display_info_smc::info_text#12 = 0 [phi:main::@38->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [765] phi smc_file_size#12 = smc_file_size#373 [phi:main::@38->display_info_smc#1] -- register_copy 
    // [765] phi display_info_smc::info_status#12 = STATUS_ISSUE [phi:main::@38->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [451] phi from main::@38 to main::@132 [phi:main::@38->main::@132]
    // main::@132
    // info_cx16_rom(STATUS_ISSUE, NULL)
    // [452] call info_cx16_rom
    // [1548] phi from main::@132 to info_cx16_rom [phi:main::@132->info_cx16_rom]
    jsr info_cx16_rom
    // [453] phi from main::@132 to main::@133 [phi:main::@132->main::@133]
    // main::@133
    // display_info_progress("There is an issue with either the SMC or the CX16 main ROM!")
    // [454] call display_info_progress
    // [711] phi from main::@133 to display_info_progress [phi:main::@133->display_info_progress]
    // [711] phi display_info_progress::info_text#14 = main::info_text10 [phi:main::@133->display_info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text10
    sta.z display_info_progress.info_text
    lda #>info_text10
    sta.z display_info_progress.info_text+1
    jsr display_info_progress
    // [455] phi from main::@133 to main::@134 [phi:main::@133->main::@134]
    // main::@134
    // util_wait_key("Press [SPACE] to continue [ ]", " ")
    // [456] call util_wait_key
    // [895] phi from main::@134 to util_wait_key [phi:main::@134->util_wait_key]
    // [895] phi util_wait_key::filter#14 = s1 [phi:main::@134->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<@s1
    sta.z util_wait_key.filter
    lda #>@s1
    sta.z util_wait_key.filter+1
    // [895] phi util_wait_key::info_text#4 = main::info_text11 [phi:main::@134->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text11
    sta.z util_wait_key.info_text
    lda #>info_text11
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    jmp check_smc3
    // main::bank_set_brom2
  bank_set_brom2:
    // BROM = bank
    // [457] BROM = main::bank_set_brom2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom2_bank
    sta.z BROM
    // main::@69
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [458] if(rom_device_ids[main::rom_chip1#10]==$55) goto main::@32 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    ldy rom_chip1
    lda rom_device_ids,y
    cmp #$55
    bne !__b32+
    jmp __b32
  !__b32:
    // [459] phi from main::@69 to main::@35 [phi:main::@69->main::@35]
    // main::@35
    // display_progress_clear()
    // [460] call display_progress_clear
    // [696] phi from main::@35 to display_progress_clear [phi:main::@35->display_progress_clear]
    jsr display_progress_clear
    // main::@110
    // unsigned char rom_bank = rom_chip * 32
    // [461] main::rom_bank#0 = main::rom_chip1#10 << 5 -- vbum1=vbum2_rol_5 
    lda rom_chip1
    asl
    asl
    asl
    asl
    asl
    sta rom_bank
    // unsigned char* file = rom_file(rom_chip)
    // [462] rom_file::rom_chip#0 = main::rom_chip1#10 -- vbuz1=vbum2 
    lda rom_chip1
    sta.z rom_file.rom_chip
    // [463] call rom_file
    // [1232] phi from main::@110 to rom_file [phi:main::@110->rom_file]
    // [1232] phi rom_file::rom_chip#2 = rom_file::rom_chip#0 [phi:main::@110->rom_file#0] -- register_copy 
    jsr rom_file
    // unsigned char* file = rom_file(rom_chip)
    // [464] rom_file::return#4 = rom_file::return#2
    // main::@111
    // [465] main::file#0 = rom_file::return#4 -- pbuz1=pbuz2 
    lda.z rom_file.return
    sta.z file
    lda.z rom_file.return+1
    sta.z file+1
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [466] call snprintf_init
    jsr snprintf_init
    // [467] phi from main::@111 to main::@112 [phi:main::@111->main::@112]
    // main::@112
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [468] call printf_str
    // [745] phi from main::@112 to printf_str [phi:main::@112->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:main::@112->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = main::s6 [phi:main::@112->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // main::@113
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [469] printf_string::str#12 = main::file#0 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [470] call printf_string
    // [1238] phi from main::@113 to printf_string [phi:main::@113->printf_string]
    // [1238] phi printf_string::putc#18 = &snputc [phi:main::@113->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1238] phi printf_string::str#18 = printf_string::str#12 [phi:main::@113->printf_string#1] -- register_copy 
    // [1238] phi printf_string::format_justify_left#18 = 0 [phi:main::@113->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1238] phi printf_string::format_min_length#18 = 0 [phi:main::@113->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [471] phi from main::@113 to main::@114 [phi:main::@113->main::@114]
    // main::@114
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [472] call printf_str
    // [745] phi from main::@114 to printf_str [phi:main::@114->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:main::@114->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = main::s7 [phi:main::@114->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@115
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [473] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [474] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_progress(info_text)
    // [476] call display_info_progress
    // [711] phi from main::@115 to display_info_progress [phi:main::@115->display_info_progress]
    // [711] phi display_info_progress::info_text#14 = info_text [phi:main::@115->display_info_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_progress.info_text
    lda #>@info_text
    sta.z display_info_progress.info_text+1
    jsr display_info_progress
    // main::@116
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_CHECKING, rom_bank, rom_sizes[rom_chip])
    // [477] main::$188 = main::rom_chip1#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip1
    asl
    asl
    sta.z main__188
    // [478] rom_read::file#0 = main::file#0 -- pbuz1=pbuz2 
    lda.z file
    sta.z rom_read.file
    lda.z file+1
    sta.z rom_read.file+1
    // [479] rom_read::brom_bank_start#1 = main::rom_bank#0 -- vbuz1=vbum2 
    lda rom_bank
    sta.z rom_read.brom_bank_start
    // [480] rom_read::rom_size#0 = rom_sizes[main::$188] -- vduz1=pduc1_derefidx_vbuz2 
    ldy.z main__188
    lda rom_sizes,y
    sta.z rom_read.rom_size
    lda rom_sizes+1,y
    sta.z rom_read.rom_size+1
    lda rom_sizes+2,y
    sta.z rom_read.rom_size+2
    lda rom_sizes+3,y
    sta.z rom_read.rom_size+3
    // [481] call rom_read
    // [1263] phi from main::@116 to rom_read [phi:main::@116->rom_read]
    // [1263] phi rom_read::rom_size#12 = rom_read::rom_size#0 [phi:main::@116->rom_read#0] -- register_copy 
    // [1263] phi __errno#106 = __errno#112 [phi:main::@116->rom_read#1] -- register_copy 
    // [1263] phi rom_read::file#11 = rom_read::file#0 [phi:main::@116->rom_read#2] -- register_copy 
    // [1263] phi rom_read::brom_bank_start#21 = rom_read::brom_bank_start#1 [phi:main::@116->rom_read#3] -- register_copy 
    jsr rom_read
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_CHECKING, rom_bank, rom_sizes[rom_chip])
    // [482] rom_read::return#2 = rom_read::return#0
    // main::@117
    // [483] main::rom_bytes_read#0 = rom_read::return#2
    // if (!rom_bytes_read)
    // [484] if(0==main::rom_bytes_read#0) goto main::@33 -- 0_eq_vdum1_then_la1 
    // In case no file was found, set the status to none and skip to the next, else, mention the amount of bytes read.
    lda rom_bytes_read
    ora rom_bytes_read+1
    ora rom_bytes_read+2
    ora rom_bytes_read+3
    bne !__b33+
    jmp __b33
  !__b33:
    // main::@36
    // unsigned long rom_file_modulo = rom_bytes_read % 0x4000
    // [485] main::rom_file_modulo#0 = main::rom_bytes_read#0 & $4000-1 -- vdum1=vdum2_band_vduc1 
    // If the rom size is not a factor or 0x4000 bytes, then there is an error.
    lda rom_bytes_read
    and #<$4000-1
    sta rom_file_modulo
    lda rom_bytes_read+1
    and #>$4000-1
    sta rom_file_modulo+1
    lda rom_bytes_read+2
    and #<$4000-1>>$10
    sta rom_file_modulo+2
    lda rom_bytes_read+3
    and #>$4000-1>>$10
    sta rom_file_modulo+3
    // if(rom_file_modulo)
    // [486] if(0!=main::rom_file_modulo#0) goto main::@34 -- 0_neq_vdum1_then_la1 
    lda rom_file_modulo
    ora rom_file_modulo+1
    ora rom_file_modulo+2
    ora rom_file_modulo+3
    beq !__b34+
    jmp __b34
  !__b34:
    // main::@37
    // file_sizes[rom_chip] = rom_bytes_read
    // [487] file_sizes[main::$188] = main::rom_bytes_read#0 -- pduc1_derefidx_vbuz1=vdum2 
    // We know the file size, so we indicate it in the status panel.
    ldy.z main__188
    lda rom_bytes_read
    sta file_sizes,y
    lda rom_bytes_read+1
    sta file_sizes+1,y
    lda rom_bytes_read+2
    sta file_sizes+2,y
    lda rom_bytes_read+3
    sta file_sizes+3,y
    // strncpy(rom_github[rom_chip], (char*)RAM_BASE, 6)
    // [488] main::$190 = main::rom_chip1#10 << 1 -- vbuz1=vbum2_rol_1 
    lda rom_chip1
    asl
    sta.z main__190
    // [489] strncpy::dst#2 = rom_github[main::$190] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda rom_github,y
    sta.z strncpy.dst
    lda rom_github+1,y
    sta.z strncpy.dst+1
    // [490] call strncpy
  // Fill the version data ...
    // [1551] phi from main::@37 to strncpy [phi:main::@37->strncpy]
    // [1551] phi strncpy::dst#8 = strncpy::dst#2 [phi:main::@37->strncpy#0] -- register_copy 
    // [1551] phi strncpy::src#6 = (char *)$6000 [phi:main::@37->strncpy#1] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z strncpy.src
    lda #>$6000
    sta.z strncpy.src+1
    // [1551] phi strncpy::n#3 = 6 [phi:main::@37->strncpy#2] -- vwum1=vbuc1 
    lda #<6
    sta strncpy.n
    lda #>6
    sta strncpy.n+1
    jsr strncpy
    // main::bank_push_set_bram1
    // asm
    // asm { lda$00 pha  }
    lda.z 0
    pha
    // BRAM = bank
    // [492] BRAM = main::bank_push_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_push_set_bram1_bank
    sta.z BRAM
    // main::@71
    // rom_release[rom_chip] = *((char*)0xBF80)
    // [493] rom_release[main::rom_chip1#10] = *((char *) 49024) -- pbuc1_derefidx_vbum1=_deref_pbuc2 
    lda $bf80
    ldy rom_chip1
    sta rom_release,y
    // main::bank_pull_bram1
    // asm
    // asm { pla sta$00  }
    pla
    sta.z 0
    // [495] phi from main::bank_pull_bram1 to main::@72 [phi:main::bank_pull_bram1->main::@72]
    // main::@72
    // sprintf(info_text, "%s:R%u/%s", file, rom_release[rom_chip], rom_github[rom_chip])
    // [496] call snprintf_init
    jsr snprintf_init
    // main::@126
    // [497] printf_string::str#15 = main::file#0 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [498] call printf_string
    // [1238] phi from main::@126 to printf_string [phi:main::@126->printf_string]
    // [1238] phi printf_string::putc#18 = &snputc [phi:main::@126->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1238] phi printf_string::str#18 = printf_string::str#15 [phi:main::@126->printf_string#1] -- register_copy 
    // [1238] phi printf_string::format_justify_left#18 = 0 [phi:main::@126->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1238] phi printf_string::format_min_length#18 = 0 [phi:main::@126->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [499] phi from main::@126 to main::@127 [phi:main::@126->main::@127]
    // main::@127
    // sprintf(info_text, "%s:R%u/%s", file, rom_release[rom_chip], rom_github[rom_chip])
    // [500] call printf_str
    // [745] phi from main::@127 to printf_str [phi:main::@127->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:main::@127->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = main::s12 [phi:main::@127->printf_str#1] -- pbuz1=pbuc1 
    lda #<s12
    sta.z printf_str.s
    lda #>s12
    sta.z printf_str.s+1
    jsr printf_str
    // main::@128
    // sprintf(info_text, "%s:R%u/%s", file, rom_release[rom_chip], rom_github[rom_chip])
    // [501] printf_uchar::uvalue#8 = rom_release[main::rom_chip1#10] -- vbum1=pbuc1_derefidx_vbum2 
    ldy rom_chip1
    lda rom_release,y
    sta printf_uchar.uvalue
    // [502] call printf_uchar
    // [1162] phi from main::@128 to printf_uchar [phi:main::@128->printf_uchar]
    // [1162] phi printf_uchar::format_zero_padding#11 = 0 [phi:main::@128->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1162] phi printf_uchar::format_min_length#11 = 0 [phi:main::@128->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1162] phi printf_uchar::putc#11 = &snputc [phi:main::@128->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1162] phi printf_uchar::format_radix#11 = DECIMAL [phi:main::@128->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1162] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#8 [phi:main::@128->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [503] phi from main::@128 to main::@129 [phi:main::@128->main::@129]
    // main::@129
    // sprintf(info_text, "%s:R%u/%s", file, rom_release[rom_chip], rom_github[rom_chip])
    // [504] call printf_str
    // [745] phi from main::@129 to printf_str [phi:main::@129->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:main::@129->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = s4 [phi:main::@129->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // main::@130
    // sprintf(info_text, "%s:R%u/%s", file, rom_release[rom_chip], rom_github[rom_chip])
    // [505] printf_string::str#16 = rom_github[main::$190] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z main__190
    lda rom_github,y
    sta.z printf_string.str
    lda rom_github+1,y
    sta.z printf_string.str+1
    // [506] call printf_string
    // [1238] phi from main::@130 to printf_string [phi:main::@130->printf_string]
    // [1238] phi printf_string::putc#18 = &snputc [phi:main::@130->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1238] phi printf_string::str#18 = printf_string::str#16 [phi:main::@130->printf_string#1] -- register_copy 
    // [1238] phi printf_string::format_justify_left#18 = 0 [phi:main::@130->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1238] phi printf_string::format_min_length#18 = 0 [phi:main::@130->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // main::@131
    // sprintf(info_text, "%s:R%u/%s", file, rom_release[rom_chip], rom_github[rom_chip])
    // [507] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [508] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom(rom_chip, STATUS_FLASH, info_text)
    // [510] info_rom::rom_chip#8 = main::rom_chip1#10 -- vbuz1=vbum2 
    lda rom_chip1
    sta.z info_rom.rom_chip
    // [511] call info_rom
    // [1187] phi from main::@131 to info_rom [phi:main::@131->info_rom]
    // [1187] phi info_rom::info_text#16 = info_text [phi:main::@131->info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_rom.info_text
    lda #>@info_text
    sta.z info_rom.info_text+1
    // [1187] phi info_rom::rom_chip#16 = info_rom::rom_chip#8 [phi:main::@131->info_rom#1] -- register_copy 
    // [1187] phi info_rom::info_status#16 = STATUS_FLASH [phi:main::@131->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASH
    sta.z info_rom.info_status
    jsr info_rom
    // [512] phi from main::@121 main::@125 main::@131 main::@69 to main::@32 [phi:main::@121/main::@125/main::@131/main::@69->main::@32]
    // [512] phi __errno#255 = __errno#18 [phi:main::@121/main::@125/main::@131/main::@69->main::@32#0] -- register_copy 
    // main::@32
  __b32:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [513] main::rom_chip1#1 = ++ main::rom_chip1#10 -- vbum1=_inc_vbum1 
    inc rom_chip1
    // [160] phi from main::@32 to main::@31 [phi:main::@32->main::@31]
    // [160] phi __errno#112 = __errno#255 [phi:main::@32->main::@31#0] -- register_copy 
    // [160] phi main::rom_chip1#10 = main::rom_chip1#1 [phi:main::@32->main::@31#1] -- register_copy 
    jmp __b31
    // [514] phi from main::@36 to main::@34 [phi:main::@36->main::@34]
    // main::@34
  __b34:
    // sprintf(info_text, "File %s size error!", file)
    // [515] call snprintf_init
    jsr snprintf_init
    // [516] phi from main::@34 to main::@122 [phi:main::@34->main::@122]
    // main::@122
    // sprintf(info_text, "File %s size error!", file)
    // [517] call printf_str
    // [745] phi from main::@122 to printf_str [phi:main::@122->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:main::@122->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = main::s10 [phi:main::@122->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // main::@123
    // sprintf(info_text, "File %s size error!", file)
    // [518] printf_string::str#14 = main::file#0 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [519] call printf_string
    // [1238] phi from main::@123 to printf_string [phi:main::@123->printf_string]
    // [1238] phi printf_string::putc#18 = &snputc [phi:main::@123->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1238] phi printf_string::str#18 = printf_string::str#14 [phi:main::@123->printf_string#1] -- register_copy 
    // [1238] phi printf_string::format_justify_left#18 = 0 [phi:main::@123->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1238] phi printf_string::format_min_length#18 = 0 [phi:main::@123->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [520] phi from main::@123 to main::@124 [phi:main::@123->main::@124]
    // main::@124
    // sprintf(info_text, "File %s size error!", file)
    // [521] call printf_str
    // [745] phi from main::@124 to printf_str [phi:main::@124->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:main::@124->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = main::s11 [phi:main::@124->printf_str#1] -- pbuz1=pbuc1 
    lda #<s11
    sta.z printf_str.s
    lda #>s11
    sta.z printf_str.s+1
    jsr printf_str
    // main::@125
    // sprintf(info_text, "File %s size error!", file)
    // [522] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [523] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom(rom_chip, STATUS_ERROR, info_text)
    // [525] info_rom::rom_chip#7 = main::rom_chip1#10 -- vbuz1=vbum2 
    lda rom_chip1
    sta.z info_rom.rom_chip
    // [526] call info_rom
    // [1187] phi from main::@125 to info_rom [phi:main::@125->info_rom]
    // [1187] phi info_rom::info_text#16 = info_text [phi:main::@125->info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_rom.info_text
    lda #>@info_text
    sta.z info_rom.info_text+1
    // [1187] phi info_rom::rom_chip#16 = info_rom::rom_chip#7 [phi:main::@125->info_rom#1] -- register_copy 
    // [1187] phi info_rom::info_status#16 = STATUS_ERROR [phi:main::@125->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z info_rom.info_status
    jsr info_rom
    jmp __b32
    // [527] phi from main::@117 to main::@33 [phi:main::@117->main::@33]
    // main::@33
  __b33:
    // sprintf(info_text, "No %s, skipped", file)
    // [528] call snprintf_init
    jsr snprintf_init
    // [529] phi from main::@33 to main::@118 [phi:main::@33->main::@118]
    // main::@118
    // sprintf(info_text, "No %s, skipped", file)
    // [530] call printf_str
    // [745] phi from main::@118 to printf_str [phi:main::@118->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:main::@118->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = main::s8 [phi:main::@118->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // main::@119
    // sprintf(info_text, "No %s, skipped", file)
    // [531] printf_string::str#13 = main::file#0 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [532] call printf_string
    // [1238] phi from main::@119 to printf_string [phi:main::@119->printf_string]
    // [1238] phi printf_string::putc#18 = &snputc [phi:main::@119->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1238] phi printf_string::str#18 = printf_string::str#13 [phi:main::@119->printf_string#1] -- register_copy 
    // [1238] phi printf_string::format_justify_left#18 = 0 [phi:main::@119->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1238] phi printf_string::format_min_length#18 = 0 [phi:main::@119->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [533] phi from main::@119 to main::@120 [phi:main::@119->main::@120]
    // main::@120
    // sprintf(info_text, "No %s, skipped", file)
    // [534] call printf_str
    // [745] phi from main::@120 to printf_str [phi:main::@120->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:main::@120->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = main::s9 [phi:main::@120->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // main::@121
    // sprintf(info_text, "No %s, skipped", file)
    // [535] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [536] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom(rom_chip, STATUS_NONE, info_text)
    // [538] info_rom::rom_chip#6 = main::rom_chip1#10 -- vbuz1=vbum2 
    lda rom_chip1
    sta.z info_rom.rom_chip
    // [539] call info_rom
    // [1187] phi from main::@121 to info_rom [phi:main::@121->info_rom]
    // [1187] phi info_rom::info_text#16 = info_text [phi:main::@121->info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_rom.info_text
    lda #>@info_text
    sta.z info_rom.info_text+1
    // [1187] phi info_rom::rom_chip#16 = info_rom::rom_chip#6 [phi:main::@121->info_rom#1] -- register_copy 
    // [1187] phi info_rom::info_status#16 = STATUS_NONE [phi:main::@121->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_NONE
    sta.z info_rom.info_status
    jsr info_rom
    jmp __b32
    // main::@30
  __b30:
    // [540] smc_file_size#372 = smc_file_size#0 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_ERROR, "SMC.BIN too large!")
    // [541] call display_info_smc
    // [765] phi from main::@30 to display_info_smc [phi:main::@30->display_info_smc]
    // [765] phi display_info_smc::info_text#12 = main::info_text9 [phi:main::@30->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text9
    sta.z display_info_smc.info_text
    lda #>info_text9
    sta.z display_info_smc.info_text+1
    // [765] phi smc_file_size#12 = smc_file_size#372 [phi:main::@30->display_info_smc#1] -- register_copy 
    // [765] phi display_info_smc::info_status#12 = STATUS_ERROR [phi:main::@30->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp CLI3
    // main::@29
  __b29:
    // [542] smc_file_size#371 = smc_file_size#0 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_ERROR, "No SMC.BIN!")
    // [543] call display_info_smc
    // [765] phi from main::@29 to display_info_smc [phi:main::@29->display_info_smc]
    // [765] phi display_info_smc::info_text#12 = main::info_text8 [phi:main::@29->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z display_info_smc.info_text
    lda #>info_text8
    sta.z display_info_smc.info_text+1
    // [765] phi smc_file_size#12 = smc_file_size#371 [phi:main::@29->display_info_smc#1] -- register_copy 
    // [765] phi display_info_smc::info_status#12 = STATUS_ERROR [phi:main::@29->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp CLI3
    // main::@24
  __b24:
    // print_info_led(PROGRESS_X + 3, PROGRESS_Y + 3 + intro_status, status_color[intro_status], BLUE)
    // [544] print_info_led::y#3 = PROGRESS_Y+3 + main::intro_status#2 -- vbuz1=vbuc1_plus_vbum2 
    lda #PROGRESS_Y+3
    clc
    adc intro_status
    sta.z print_info_led.y
    // [545] print_info_led::tc#3 = status_color[main::intro_status#2] -- vbuz1=pbuc1_derefidx_vbum2 
    ldy intro_status
    lda status_color,y
    sta.z print_info_led.tc
    // [546] call print_info_led
    // [1562] phi from main::@24 to print_info_led [phi:main::@24->print_info_led]
    // [1562] phi print_info_led::y#4 = print_info_led::y#3 [phi:main::@24->print_info_led#0] -- register_copy 
    // [1562] phi print_info_led::x#4 = PROGRESS_X+3 [phi:main::@24->print_info_led#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X+3
    sta.z print_info_led.x
    // [1562] phi print_info_led::tc#4 = print_info_led::tc#3 [phi:main::@24->print_info_led#2] -- register_copy 
    jsr print_info_led
    // main::@104
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [547] main::intro_status#1 = ++ main::intro_status#2 -- vbum1=_inc_vbum1 
    inc intro_status
    // [130] phi from main::@104 to main::@23 [phi:main::@104->main::@23]
    // [130] phi main::intro_status#2 = main::intro_status#1 [phi:main::@104->main::@23#0] -- register_copy 
    jmp __b23
    // main::@22
  __b22:
    // progress_text(intro_line, into_colors_text[intro_line])
    // [548] main::$186 = main::intro_line1#2 << 1 -- vbuz1=vbum2_rol_1 
    lda intro_line1
    asl
    sta.z main__186
    // [549] progress_text::line#1 = main::intro_line1#2 -- vbuz1=vbum2 
    lda intro_line1
    sta.z progress_text.line
    // [550] progress_text::text#1 = main::into_colors_text[main::$186] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z main__186
    lda into_colors_text,y
    sta.z progress_text.text
    lda into_colors_text+1,y
    sta.z progress_text.text+1
    // [551] call progress_text
    // [1173] phi from main::@22 to progress_text [phi:main::@22->progress_text]
    // [1173] phi progress_text::text#4 = progress_text::text#1 [phi:main::@22->progress_text#0] -- register_copy 
    // [1173] phi progress_text::line#4 = progress_text::line#1 [phi:main::@22->progress_text#1] -- register_copy 
    jsr progress_text
    // main::@103
    // for(unsigned char intro_line=0; intro_line<intro_colors_count; intro_line++)
    // [552] main::intro_line1#1 = ++ main::intro_line1#2 -- vbum1=_inc_vbum1 
    inc intro_line1
    // [128] phi from main::@103 to main::@21 [phi:main::@103->main::@21]
    // [128] phi main::intro_line1#2 = main::intro_line1#1 [phi:main::@103->main::@21#0] -- register_copy 
    jmp __b21
    // main::@19
  __b19:
    // progress_text(intro_line, into_briefing_text[intro_line])
    // [553] main::$185 = main::intro_line#2 << 1 -- vbuz1=vbum2_rol_1 
    lda intro_line
    asl
    sta.z main__185
    // [554] progress_text::line#0 = main::intro_line#2 -- vbuz1=vbum2 
    lda intro_line
    sta.z progress_text.line
    // [555] progress_text::text#0 = main::into_briefing_text[main::$185] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z main__185
    lda into_briefing_text,y
    sta.z progress_text.text
    lda into_briefing_text+1,y
    sta.z progress_text.text+1
    // [556] call progress_text
    // [1173] phi from main::@19 to progress_text [phi:main::@19->progress_text]
    // [1173] phi progress_text::text#4 = progress_text::text#0 [phi:main::@19->progress_text#0] -- register_copy 
    // [1173] phi progress_text::line#4 = progress_text::line#0 [phi:main::@19->progress_text#1] -- register_copy 
    jsr progress_text
    // main::@101
    // for(unsigned char intro_line=0; intro_line<intro_briefing_count; intro_line++)
    // [557] main::intro_line#1 = ++ main::intro_line#2 -- vbum1=_inc_vbum1 
    inc intro_line
    // [122] phi from main::@101 to main::@18 [phi:main::@101->main::@18]
    // [122] phi main::intro_line#2 = main::intro_line#1 [phi:main::@101->main::@18#0] -- register_copy 
    jmp __b18
    // main::@14
  __b14:
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [558] if(rom_device_ids[main::rom_chip#2]!=$55) goto main::@15 -- pbuc1_derefidx_vbum1_neq_vbuc2_then_la1 
    lda #$55
    ldy rom_chip
    cmp rom_device_ids,y
    bne __b15
    // main::@17
    // info_rom(rom_chip, STATUS_NONE, "")
    // [559] info_rom::rom_chip#5 = main::rom_chip#2 -- vbuz1=vbum2 
    tya
    sta.z info_rom.rom_chip
    // [560] call info_rom
    // [1187] phi from main::@17 to info_rom [phi:main::@17->info_rom]
    // [1187] phi info_rom::info_text#16 = info_text4 [phi:main::@17->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z info_rom.info_text
    lda #>info_text4
    sta.z info_rom.info_text+1
    // [1187] phi info_rom::rom_chip#16 = info_rom::rom_chip#5 [phi:main::@17->info_rom#1] -- register_copy 
    // [1187] phi info_rom::info_status#16 = STATUS_NONE [phi:main::@17->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_NONE
    sta.z info_rom.info_status
    jsr info_rom
    // main::@16
  __b16:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [561] main::rom_chip#1 = ++ main::rom_chip#2 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [119] phi from main::@16 to main::@13 [phi:main::@16->main::@13]
    // [119] phi main::rom_chip#2 = main::rom_chip#1 [phi:main::@16->main::@13#0] -- register_copy 
    jmp __b13
    // main::@15
  __b15:
    // info_rom(rom_chip, STATUS_DETECTED, "")
    // [562] info_rom::rom_chip#4 = main::rom_chip#2 -- vbuz1=vbum2 
    lda rom_chip
    sta.z info_rom.rom_chip
    // [563] call info_rom
    // [1187] phi from main::@15 to info_rom [phi:main::@15->info_rom]
    // [1187] phi info_rom::info_text#16 = info_text4 [phi:main::@15->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z info_rom.info_text
    lda #>info_text4
    sta.z info_rom.info_text+1
    // [1187] phi info_rom::rom_chip#16 = info_rom::rom_chip#4 [phi:main::@15->info_rom#1] -- register_copy 
    // [1187] phi info_rom::info_status#16 = STATUS_DETECTED [phi:main::@15->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_DETECTED
    sta.z info_rom.info_status
    jsr info_rom
    jmp __b16
    // [564] phi from main::@4 to main::@12 [phi:main::@4->main::@12]
    // main::@12
  __b12:
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [565] call snprintf_init
    jsr snprintf_init
    // [566] phi from main::@12 to main::@92 [phi:main::@12->main::@92]
    // main::@92
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [567] call printf_str
    // [745] phi from main::@92 to printf_str [phi:main::@92->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:main::@92->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = main::s2 [phi:main::@92->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main::@93
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [568] printf_uint::uvalue#13 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta printf_uint.uvalue
    lda smc_bootloader+1
    sta printf_uint.uvalue+1
    // [569] call printf_uint
    // [754] phi from main::@93 to printf_uint [phi:main::@93->printf_uint]
    // [754] phi printf_uint::format_zero_padding#16 = 1 [phi:main::@93->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [754] phi printf_uint::format_min_length#16 = 2 [phi:main::@93->printf_uint#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uint.format_min_length
    // [754] phi printf_uint::putc#16 = &snputc [phi:main::@93->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [754] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:main::@93->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [754] phi printf_uint::uvalue#16 = printf_uint::uvalue#13 [phi:main::@93->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [570] phi from main::@93 to main::@94 [phi:main::@93->main::@94]
    // main::@94
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [571] call printf_str
    // [745] phi from main::@94 to printf_str [phi:main::@94->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:main::@94->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = main::s3 [phi:main::@94->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // main::@95
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [572] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [573] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_smc(STATUS_ERROR, info_text)
    // [575] call display_info_smc
    // [765] phi from main::@95 to display_info_smc [phi:main::@95->display_info_smc]
    // [765] phi display_info_smc::info_text#12 = info_text [phi:main::@95->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_smc.info_text
    lda #>@info_text
    sta.z display_info_smc.info_text+1
    // [765] phi smc_file_size#12 = 0 [phi:main::@95->display_info_smc#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size_2
    sta smc_file_size_2+1
    // [765] phi display_info_smc::info_status#12 = STATUS_ERROR [phi:main::@95->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp CLI1
    // [576] phi from main::@3 to main::@11 [phi:main::@3->main::@11]
    // main::@11
  __b11:
    // display_info_smc(STATUS_ERROR, "Unreachable!")
    // [577] call display_info_smc
  // TODO: explain next steps ...
    // [765] phi from main::@11 to display_info_smc [phi:main::@11->display_info_smc]
    // [765] phi display_info_smc::info_text#12 = main::info_text2 [phi:main::@11->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z display_info_smc.info_text
    lda #>info_text2
    sta.z display_info_smc.info_text+1
    // [765] phi smc_file_size#12 = 0 [phi:main::@11->display_info_smc#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size_2
    sta smc_file_size_2+1
    // [765] phi display_info_smc::info_status#12 = STATUS_ERROR [phi:main::@11->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp CLI1
    // [578] phi from main::@91 to main::@1 [phi:main::@91->main::@1]
    // main::@1
  __b1:
    // display_info_smc(STATUS_ERROR, "No Bootloader!")
    // [579] call display_info_smc
  // TODO: explain next steps ...
    // [765] phi from main::@1 to display_info_smc [phi:main::@1->display_info_smc]
    // [765] phi display_info_smc::info_text#12 = main::info_text1 [phi:main::@1->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_smc.info_text
    lda #>info_text1
    sta.z display_info_smc.info_text+1
    // [765] phi smc_file_size#12 = 0 [phi:main::@1->display_info_smc#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size_2
    sta smc_file_size_2+1
    // [765] phi display_info_smc::info_status#12 = STATUS_ERROR [phi:main::@1->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp CLI1
  .segment Data
    into_briefing_text: .word __14, __15, info_text4, __17, __18, __19, __20, __21, __22, __23, __24, info_text4, __26, __27
    .fill 2*2, 0
    into_colors_text: .word __28, __29, info_text4, __31, __32, __33, __34, __35, __36, __37, __38, __39, __40, __41, info_text4, __43
    debriefing_text: .word __48, info_text4, __46, __47
    debriefing_text1: .word __48, info_text4, __50, __51, __52, info_text4, __54, info_text4, __56, __57, __58, __59
    title_text: .text "Commander X16 Flash Utility!"
    .byte 0
    s: .text "# Chip Status    Type   File  / Total Information"
    .byte 0
    s1: .text "- ---- --------- ------ ----- / ----- --------------------"
    .byte 0
    info_text: .text "Detecting SMC, VERA and ROM chipsets ..."
    .byte 0
    info_text1: .text "No Bootloader!"
    .byte 0
    info_text2: .text "Unreachable!"
    .byte 0
    s2: .text "Bootloader v"
    .byte 0
    s3: .text " invalid! !"
    .byte 0
    info_text3: .text "VERA installed, OK"
    .byte 0
    info_text6: .text "Please read carefully the below, and press [SPACE] ..."
    .byte 0
    info_text7: .text "If understood, press [SPACE] to start the update ..."
    .byte 0
    info_text8: .text "No SMC.BIN!"
    .byte 0
    info_text9: .text "SMC.BIN too large!"
    .byte 0
    s6: .text "Checking "
    .byte 0
    s7: .text " ... (.) data ( ) empty"
    .byte 0
    s8: .text "No "
    .byte 0
    s9: .text ", skipped"
    .byte 0
    s10: .text "File "
    .byte 0
    s11: .text " size error!"
    .byte 0
    s12: .text ":R"
    .byte 0
    info_text10: .text "There is an issue with either the SMC or the CX16 main ROM!"
    .byte 0
    info_text11: .text "Press [SPACE] to continue [ ]"
    .byte 0
    info_text12: .text "Chipsets have been detected and update files validated!"
    .byte 0
    info_text13: .text "Continue with update? [Y/N]"
    .byte 0
    filter3: .text "nyNY"
    .byte 0
    main__212: .text "nN"
    .byte 0
    info_text14: .text "Cancelled"
    .byte 0
    info_text17: .text "You have selected not to cancel the update ... "
    .byte 0
    info_text18: .text "Press both POWER/RESET buttons on the CX16 board!"
    .byte 0
    info_text19: .text "Press POWER/RESET!"
    .byte 0
    info_text21: .text "SMC not updated!"
    .byte 0
    info_text22: .text "Update finished ..."
    .byte 0
    info_text23: .text "Update SMC failed!"
    .byte 0
    info_text24: .text "Comparing ... (.) same, (*) different."
    .byte 0
    info_text26: .text "No update required"
    .byte 0
    s16: .text " differences!"
    .byte 0
    s17: .text " flash errors!"
    .byte 0
    info_text27: .text "OK!"
    .byte 0
    info_text28: .text "The update has been cancelled!"
    .byte 0
    info_text29: .text "Update Failure! Your CX16 may be bricked!"
    .byte 0
    info_text30: .text "Take a foto of this screen. And shut down power ..."
    .byte 0
    info_text31: .text "Update issues, your CX16 is not updated!"
    .byte 0
    s18: .text "Please read carefully the below ("
    .byte 0
    s19: .text ") ..."
    .byte 0
    s20: .text "Please disconnect your CX16 from power source ..."
    .byte 0
    s21: .text "Your CX16 will reset ("
    .byte 0
    cx16_k_screen_set_charset1_charset: .byte 0
    rom_chip: .byte 0
    intro_line: .byte 0
    intro_line1: .byte 0
    intro_status: .byte 0
    check_smc1_return: .byte 0
    check_smc2_return: .byte 0
    check_cx16_rom1_check_rom1_return: .byte 0
    rom_chip1: .byte 0
    rom_bank: .byte 0
    .label rom_bytes_read = rom_read.return
    rom_file_modulo: .dword 0
    check_smc3_return: .byte 0
    check_cx16_rom2_check_rom1_return: .byte 0
    check_card_roms1_check_rom1_return: .byte 0
    check_card_roms1_rom_chip: .byte 0
    check_card_roms1_return: .byte 0
    check_smc4_return: .byte 0
    .label ch = strchr.c
    rom_chip2: .byte 0
    flashed_bytes: .dword 0
    check_rom1_return: .byte 0
    check_smc5_return: .byte 0
    check_vera1_return: .byte 0
    check_roms_all1_check_rom1_return: .byte 0
    check_roms_all1_rom_chip: .byte 0
    check_roms_all1_return: .byte 0
    rom_chip3: .byte 0
    check_smc6_return: .byte 0
    rom_bank1: .byte 0
    .label rom_bytes_read1 = rom_read.return
    .label rom_differences = printf_ulong.uvalue
    rom_flash_errors: .dword 0
    check_smc7_return: .byte 0
    check_vera2_return: .byte 0
    check_roms1_check_rom1_return: .byte 0
    check_roms1_rom_chip: .byte 0
    check_roms1_return: .byte 0
    check_smc8_return: .byte 0
    check_vera3_return: .byte 0
    check_roms2_check_rom1_return: .byte 0
    check_roms2_rom_chip: .byte 0
    check_roms2_return: .byte 0
    check_smc9_return: .byte 0
    l: .byte 0
    l1: .byte 0
    w: .byte 0
    w1: .byte 0
}
.segment Code
  // screenlayer1
// Set the layer with which the conio will interact.
screenlayer1: {
    // screenlayer(1, *VERA_L1_MAPBASE, *VERA_L1_CONFIG)
    // [580] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbum1=_deref_pbuc1 
    lda VERA_L1_MAPBASE
    sta screenlayer.mapbase
    // [581] screenlayer::config#0 = *VERA_L1_CONFIG -- vbum1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta screenlayer.config
    // [582] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [583] return 
    rts
}
  // textcolor
// Set the front color for text output. The old front text color setting is returned.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char textcolor(__mem() char color)
textcolor: {
    .label textcolor__0 = $71
    .label textcolor__1 = $71
    // __conio.color & 0xF0
    // [585] textcolor::$0 = *((char *)&__conio+$d) & $f0 -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$d
    sta.z textcolor__0
    // __conio.color & 0xF0 | color
    // [586] textcolor::$1 = textcolor::$0 | textcolor::color#18 -- vbuz1=vbuz1_bor_vbum2 
    lda color
    ora.z textcolor__1
    sta.z textcolor__1
    // __conio.color = __conio.color & 0xF0 | color
    // [587] *((char *)&__conio+$d) = textcolor::$1 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // textcolor::@return
    // }
    // [588] return 
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
    .label bgcolor__0 = $71
    .label bgcolor__1 = $72
    .label bgcolor__2 = $71
    // __conio.color & 0x0F
    // [590] bgcolor::$0 = *((char *)&__conio+$d) & $f -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$d
    sta.z bgcolor__0
    // color << 4
    // [591] bgcolor::$1 = bgcolor::color#14 << 4 -- vbuz1=vbum2_rol_4 
    lda color
    asl
    asl
    asl
    asl
    sta.z bgcolor__1
    // __conio.color & 0x0F | color << 4
    // [592] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbuz1=vbuz1_bor_vbuz2 
    lda.z bgcolor__2
    ora.z bgcolor__1
    sta.z bgcolor__2
    // __conio.color = __conio.color & 0x0F | color << 4
    // [593] *((char *)&__conio+$d) = bgcolor::$2 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // bgcolor::@return
    // }
    // [594] return 
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
    // [595] *((char *)&__conio+$c) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$c
    // cursor::@return
    // }
    // [596] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    // __mem unsigned char x
    // [597] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [598] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [600] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwum1=vbum2_word_vbum3 
    lda x
    sta return+1
    lda y
    sta return
    // cbm_k_plot_get::@return
    // }
    // [601] return 
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
    .label gotoxy__8 = $35
    .label gotoxy__9 = $32
    .label gotoxy__10 = $31
    .label gotoxy__14 = $2f
    // (x>=__conio.width)?__conio.width:x
    // [603] if(gotoxy::x#30>=*((char *)&__conio+6)) goto gotoxy::@1 -- vbum1_ge__deref_pbuc1_then_la1 
    lda x
    cmp __conio+6
    bcs __b1
    // [605] phi from gotoxy to gotoxy::@2 [phi:gotoxy->gotoxy::@2]
    // [605] phi gotoxy::$3 = gotoxy::x#30 [phi:gotoxy->gotoxy::@2#0] -- vbuz1=vbum2 
    sta.z gotoxy__3
    jmp __b2
    // gotoxy::@1
  __b1:
    // [604] gotoxy::$2 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z gotoxy__2
    // [605] phi from gotoxy::@1 to gotoxy::@2 [phi:gotoxy::@1->gotoxy::@2]
    // [605] phi gotoxy::$3 = gotoxy::$2 [phi:gotoxy::@1->gotoxy::@2#0] -- register_copy 
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [606] *((char *)&__conio) = gotoxy::$3 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__3
    sta __conio
    // (y>=__conio.height)?__conio.height:y
    // [607] if(gotoxy::y#30>=*((char *)&__conio+7)) goto gotoxy::@3 -- vbum1_ge__deref_pbuc1_then_la1 
    lda y
    cmp __conio+7
    bcs __b3
    // gotoxy::@4
    // [608] gotoxy::$14 = gotoxy::y#30 -- vbuz1=vbum2 
    sta.z gotoxy__14
    // [609] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [609] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [610] *((char *)&__conio+1) = gotoxy::$7 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__7
    sta __conio+1
    // __conio.cursor_x << 1
    // [611] gotoxy::$8 = *((char *)&__conio) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio
    asl
    sta.z gotoxy__8
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [612] gotoxy::$10 = gotoxy::y#30 << 1 -- vbuz1=vbum2_rol_1 
    lda y
    asl
    sta.z gotoxy__10
    // [613] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwuz1=pwuc1_derefidx_vbuz2_plus_vbuz3 
    lda.z gotoxy__8
    ldy.z gotoxy__10
    clc
    adc __conio+$15,y
    sta.z gotoxy__9
    lda __conio+$15+1,y
    adc #0
    sta.z gotoxy__9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [614] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwuz1 
    lda.z gotoxy__9
    sta __conio+$13
    lda.z gotoxy__9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [615] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [616] gotoxy::$6 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
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
    .label cputln__2 = $48
    // __conio.cursor_x = 0
    // [617] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y++;
    // [618] *((char *)&__conio+1) = ++ *((char *)&__conio+1) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+1
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [619] cputln::$2 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z cputln__2
    // [620] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [621] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [622] return 
    rts
}
  // display_frame_init
/**
 * @brief 
 * 
 */
display_frame_init: {
    .const vera_display_set_hstart1_start = $b
    .const vera_display_set_hstop1_stop = $93
    .const vera_display_set_vstart1_start = $13
    .const vera_display_set_vstop1_stop = $db
    .label cx16_k_screen_set_charset1_offset = $d6
    // textcolor(WHITE)
    // [624] call textcolor
  // Set the charset to lower case.
  // screenlayer1();
    // [584] phi from display_frame_init to textcolor [phi:display_frame_init->textcolor]
    // [584] phi textcolor::color#18 = WHITE [phi:display_frame_init->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [625] phi from display_frame_init to display_frame_init::@2 [phi:display_frame_init->display_frame_init::@2]
    // display_frame_init::@2
    // bgcolor(BLUE)
    // [626] call bgcolor
    // [589] phi from display_frame_init::@2 to bgcolor [phi:display_frame_init::@2->bgcolor]
    // [589] phi bgcolor::color#14 = BLUE [phi:display_frame_init::@2->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [627] phi from display_frame_init::@2 to display_frame_init::@3 [phi:display_frame_init::@2->display_frame_init::@3]
    // display_frame_init::@3
    // scroll(0)
    // [628] call scroll
    jsr scroll
    // [629] phi from display_frame_init::@3 to display_frame_init::@4 [phi:display_frame_init::@3->display_frame_init::@4]
    // display_frame_init::@4
    // clrscr()
    // [630] call clrscr
    jsr clrscr
    // display_frame_init::vera_display_set_hstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [631] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTART = start
    // [632] *VERA_DC_HSTART = display_frame_init::vera_display_set_hstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstart1_start
    sta VERA_DC_HSTART
    // display_frame_init::vera_display_set_hstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [633] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTOP = stop
    // [634] *VERA_DC_HSTOP = display_frame_init::vera_display_set_hstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstop1_stop
    sta VERA_DC_HSTOP
    // display_frame_init::vera_display_set_vstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [635] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTART = start
    // [636] *VERA_DC_VSTART = display_frame_init::vera_display_set_vstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstart1_start
    sta VERA_DC_VSTART
    // display_frame_init::vera_display_set_vstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [637] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTOP = stop
    // [638] *VERA_DC_VSTOP = display_frame_init::vera_display_set_vstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstop1_stop
    sta VERA_DC_VSTOP
    // display_frame_init::@1
    // cx16_k_screen_set_charset(3, (char *)0)
    // [639] display_frame_init::cx16_k_screen_set_charset1_charset = 3 -- vbum1=vbuc1 
    lda #3
    sta cx16_k_screen_set_charset1_charset
    // [640] display_frame_init::cx16_k_screen_set_charset1_offset = (char *) 0 -- pbuz1=pbuc1 
    lda #<0
    sta.z cx16_k_screen_set_charset1_offset
    sta.z cx16_k_screen_set_charset1_offset+1
    // display_frame_init::cx16_k_screen_set_charset1
    // asm
    // asm { ldacharset ldx<offset ldy>offset jsrCX16_SCREEN_SET_CHARSET  }
    lda cx16_k_screen_set_charset1_charset
    ldx.z <cx16_k_screen_set_charset1_offset
    ldy.z >cx16_k_screen_set_charset1_offset
    jsr CX16_SCREEN_SET_CHARSET
    // display_frame_init::@return
    // }
    // [642] return 
    rts
  .segment Data
    cx16_k_screen_set_charset1_charset: .byte 0
}
.segment Code
  // display_frame_draw
/**
 * @brief 
 * 
 */
display_frame_draw: {
    // textcolor(LIGHT_BLUE)
    // [644] call textcolor
    // [584] phi from display_frame_draw to textcolor [phi:display_frame_draw->textcolor]
    // [584] phi textcolor::color#18 = LIGHT_BLUE [phi:display_frame_draw->textcolor#0] -- vbum1=vbuc1 
    lda #LIGHT_BLUE
    sta textcolor.color
    jsr textcolor
    // [645] phi from display_frame_draw to display_frame_draw::@1 [phi:display_frame_draw->display_frame_draw::@1]
    // display_frame_draw::@1
    // bgcolor(BLUE)
    // [646] call bgcolor
    // [589] phi from display_frame_draw::@1 to bgcolor [phi:display_frame_draw::@1->bgcolor]
    // [589] phi bgcolor::color#14 = BLUE [phi:display_frame_draw::@1->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [647] phi from display_frame_draw::@1 to display_frame_draw::@2 [phi:display_frame_draw::@1->display_frame_draw::@2]
    // display_frame_draw::@2
    // clrscr()
    // [648] call clrscr
    jsr clrscr
    // [649] phi from display_frame_draw::@2 to display_frame_draw::@3 [phi:display_frame_draw::@2->display_frame_draw::@3]
    // display_frame_draw::@3
    // display_frame(0, 0, 67, 14)
    // [650] call display_frame
    // [1644] phi from display_frame_draw::@3 to display_frame [phi:display_frame_draw::@3->display_frame]
    // [1644] phi display_frame::y#0 = 0 [phi:display_frame_draw::@3->display_frame#0] -- vbum1=vbuc1 
    lda #0
    sta display_frame.y
    // [1644] phi display_frame::y1#16 = $e [phi:display_frame_draw::@3->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1644] phi display_frame::x#0 = 0 [phi:display_frame_draw::@3->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1644] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@3->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [651] phi from display_frame_draw::@3 to display_frame_draw::@4 [phi:display_frame_draw::@3->display_frame_draw::@4]
    // display_frame_draw::@4
    // display_frame(0, 0, 67, 2)
    // [652] call display_frame
    // [1644] phi from display_frame_draw::@4 to display_frame [phi:display_frame_draw::@4->display_frame]
    // [1644] phi display_frame::y#0 = 0 [phi:display_frame_draw::@4->display_frame#0] -- vbum1=vbuc1 
    lda #0
    sta display_frame.y
    // [1644] phi display_frame::y1#16 = 2 [phi:display_frame_draw::@4->display_frame#1] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y1
    // [1644] phi display_frame::x#0 = 0 [phi:display_frame_draw::@4->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1644] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@4->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [653] phi from display_frame_draw::@4 to display_frame_draw::@5 [phi:display_frame_draw::@4->display_frame_draw::@5]
    // display_frame_draw::@5
    // display_frame(0, 2, 67, 14)
    // [654] call display_frame
    // [1644] phi from display_frame_draw::@5 to display_frame [phi:display_frame_draw::@5->display_frame]
    // [1644] phi display_frame::y#0 = 2 [phi:display_frame_draw::@5->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1644] phi display_frame::y1#16 = $e [phi:display_frame_draw::@5->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1644] phi display_frame::x#0 = 0 [phi:display_frame_draw::@5->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1644] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@5->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [655] phi from display_frame_draw::@5 to display_frame_draw::@6 [phi:display_frame_draw::@5->display_frame_draw::@6]
    // display_frame_draw::@6
    // display_frame(0, 2, 8, 14)
    // [656] call display_frame
  // Chipset areas
    // [1644] phi from display_frame_draw::@6 to display_frame [phi:display_frame_draw::@6->display_frame]
    // [1644] phi display_frame::y#0 = 2 [phi:display_frame_draw::@6->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1644] phi display_frame::y1#16 = $e [phi:display_frame_draw::@6->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1644] phi display_frame::x#0 = 0 [phi:display_frame_draw::@6->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1644] phi display_frame::x1#16 = 8 [phi:display_frame_draw::@6->display_frame#3] -- vbuz1=vbuc1 
    lda #8
    sta.z display_frame.x1
    jsr display_frame
    // [657] phi from display_frame_draw::@6 to display_frame_draw::@7 [phi:display_frame_draw::@6->display_frame_draw::@7]
    // display_frame_draw::@7
    // display_frame(8, 2, 19, 14)
    // [658] call display_frame
    // [1644] phi from display_frame_draw::@7 to display_frame [phi:display_frame_draw::@7->display_frame]
    // [1644] phi display_frame::y#0 = 2 [phi:display_frame_draw::@7->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1644] phi display_frame::y1#16 = $e [phi:display_frame_draw::@7->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1644] phi display_frame::x#0 = 8 [phi:display_frame_draw::@7->display_frame#2] -- vbum1=vbuc1 
    lda #8
    sta display_frame.x
    // [1644] phi display_frame::x1#16 = $13 [phi:display_frame_draw::@7->display_frame#3] -- vbuz1=vbuc1 
    lda #$13
    sta.z display_frame.x1
    jsr display_frame
    // [659] phi from display_frame_draw::@7 to display_frame_draw::@8 [phi:display_frame_draw::@7->display_frame_draw::@8]
    // display_frame_draw::@8
    // display_frame(19, 2, 25, 14)
    // [660] call display_frame
    // [1644] phi from display_frame_draw::@8 to display_frame [phi:display_frame_draw::@8->display_frame]
    // [1644] phi display_frame::y#0 = 2 [phi:display_frame_draw::@8->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1644] phi display_frame::y1#16 = $e [phi:display_frame_draw::@8->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1644] phi display_frame::x#0 = $13 [phi:display_frame_draw::@8->display_frame#2] -- vbum1=vbuc1 
    lda #$13
    sta display_frame.x
    // [1644] phi display_frame::x1#16 = $19 [phi:display_frame_draw::@8->display_frame#3] -- vbuz1=vbuc1 
    lda #$19
    sta.z display_frame.x1
    jsr display_frame
    // [661] phi from display_frame_draw::@8 to display_frame_draw::@9 [phi:display_frame_draw::@8->display_frame_draw::@9]
    // display_frame_draw::@9
    // display_frame(25, 2, 31, 14)
    // [662] call display_frame
    // [1644] phi from display_frame_draw::@9 to display_frame [phi:display_frame_draw::@9->display_frame]
    // [1644] phi display_frame::y#0 = 2 [phi:display_frame_draw::@9->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1644] phi display_frame::y1#16 = $e [phi:display_frame_draw::@9->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1644] phi display_frame::x#0 = $19 [phi:display_frame_draw::@9->display_frame#2] -- vbum1=vbuc1 
    lda #$19
    sta display_frame.x
    // [1644] phi display_frame::x1#16 = $1f [phi:display_frame_draw::@9->display_frame#3] -- vbuz1=vbuc1 
    lda #$1f
    sta.z display_frame.x1
    jsr display_frame
    // [663] phi from display_frame_draw::@9 to display_frame_draw::@10 [phi:display_frame_draw::@9->display_frame_draw::@10]
    // display_frame_draw::@10
    // display_frame(31, 2, 37, 14)
    // [664] call display_frame
    // [1644] phi from display_frame_draw::@10 to display_frame [phi:display_frame_draw::@10->display_frame]
    // [1644] phi display_frame::y#0 = 2 [phi:display_frame_draw::@10->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1644] phi display_frame::y1#16 = $e [phi:display_frame_draw::@10->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1644] phi display_frame::x#0 = $1f [phi:display_frame_draw::@10->display_frame#2] -- vbum1=vbuc1 
    lda #$1f
    sta display_frame.x
    // [1644] phi display_frame::x1#16 = $25 [phi:display_frame_draw::@10->display_frame#3] -- vbuz1=vbuc1 
    lda #$25
    sta.z display_frame.x1
    jsr display_frame
    // [665] phi from display_frame_draw::@10 to display_frame_draw::@11 [phi:display_frame_draw::@10->display_frame_draw::@11]
    // display_frame_draw::@11
    // display_frame(37, 2, 43, 14)
    // [666] call display_frame
    // [1644] phi from display_frame_draw::@11 to display_frame [phi:display_frame_draw::@11->display_frame]
    // [1644] phi display_frame::y#0 = 2 [phi:display_frame_draw::@11->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1644] phi display_frame::y1#16 = $e [phi:display_frame_draw::@11->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1644] phi display_frame::x#0 = $25 [phi:display_frame_draw::@11->display_frame#2] -- vbum1=vbuc1 
    lda #$25
    sta display_frame.x
    // [1644] phi display_frame::x1#16 = $2b [phi:display_frame_draw::@11->display_frame#3] -- vbuz1=vbuc1 
    lda #$2b
    sta.z display_frame.x1
    jsr display_frame
    // [667] phi from display_frame_draw::@11 to display_frame_draw::@12 [phi:display_frame_draw::@11->display_frame_draw::@12]
    // display_frame_draw::@12
    // display_frame(43, 2, 49, 14)
    // [668] call display_frame
    // [1644] phi from display_frame_draw::@12 to display_frame [phi:display_frame_draw::@12->display_frame]
    // [1644] phi display_frame::y#0 = 2 [phi:display_frame_draw::@12->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1644] phi display_frame::y1#16 = $e [phi:display_frame_draw::@12->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1644] phi display_frame::x#0 = $2b [phi:display_frame_draw::@12->display_frame#2] -- vbum1=vbuc1 
    lda #$2b
    sta display_frame.x
    // [1644] phi display_frame::x1#16 = $31 [phi:display_frame_draw::@12->display_frame#3] -- vbuz1=vbuc1 
    lda #$31
    sta.z display_frame.x1
    jsr display_frame
    // [669] phi from display_frame_draw::@12 to display_frame_draw::@13 [phi:display_frame_draw::@12->display_frame_draw::@13]
    // display_frame_draw::@13
    // display_frame(49, 2, 55, 14)
    // [670] call display_frame
    // [1644] phi from display_frame_draw::@13 to display_frame [phi:display_frame_draw::@13->display_frame]
    // [1644] phi display_frame::y#0 = 2 [phi:display_frame_draw::@13->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1644] phi display_frame::y1#16 = $e [phi:display_frame_draw::@13->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1644] phi display_frame::x#0 = $31 [phi:display_frame_draw::@13->display_frame#2] -- vbum1=vbuc1 
    lda #$31
    sta display_frame.x
    // [1644] phi display_frame::x1#16 = $37 [phi:display_frame_draw::@13->display_frame#3] -- vbuz1=vbuc1 
    lda #$37
    sta.z display_frame.x1
    jsr display_frame
    // [671] phi from display_frame_draw::@13 to display_frame_draw::@14 [phi:display_frame_draw::@13->display_frame_draw::@14]
    // display_frame_draw::@14
    // display_frame(55, 2, 61, 14)
    // [672] call display_frame
    // [1644] phi from display_frame_draw::@14 to display_frame [phi:display_frame_draw::@14->display_frame]
    // [1644] phi display_frame::y#0 = 2 [phi:display_frame_draw::@14->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1644] phi display_frame::y1#16 = $e [phi:display_frame_draw::@14->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1644] phi display_frame::x#0 = $37 [phi:display_frame_draw::@14->display_frame#2] -- vbum1=vbuc1 
    lda #$37
    sta display_frame.x
    // [1644] phi display_frame::x1#16 = $3d [phi:display_frame_draw::@14->display_frame#3] -- vbuz1=vbuc1 
    lda #$3d
    sta.z display_frame.x1
    jsr display_frame
    // [673] phi from display_frame_draw::@14 to display_frame_draw::@15 [phi:display_frame_draw::@14->display_frame_draw::@15]
    // display_frame_draw::@15
    // display_frame(61, 2, 67, 14)
    // [674] call display_frame
    // [1644] phi from display_frame_draw::@15 to display_frame [phi:display_frame_draw::@15->display_frame]
    // [1644] phi display_frame::y#0 = 2 [phi:display_frame_draw::@15->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1644] phi display_frame::y1#16 = $e [phi:display_frame_draw::@15->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1644] phi display_frame::x#0 = $3d [phi:display_frame_draw::@15->display_frame#2] -- vbum1=vbuc1 
    lda #$3d
    sta display_frame.x
    // [1644] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@15->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [675] phi from display_frame_draw::@15 to display_frame_draw::@16 [phi:display_frame_draw::@15->display_frame_draw::@16]
    // display_frame_draw::@16
    // display_frame(0, 14, 67, PROGRESS_Y-5)
    // [676] call display_frame
  // Progress area
    // [1644] phi from display_frame_draw::@16 to display_frame [phi:display_frame_draw::@16->display_frame]
    // [1644] phi display_frame::y#0 = $e [phi:display_frame_draw::@16->display_frame#0] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y
    // [1644] phi display_frame::y1#16 = PROGRESS_Y-5 [phi:display_frame_draw::@16->display_frame#1] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-5
    sta.z display_frame.y1
    // [1644] phi display_frame::x#0 = 0 [phi:display_frame_draw::@16->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1644] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@16->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [677] phi from display_frame_draw::@16 to display_frame_draw::@17 [phi:display_frame_draw::@16->display_frame_draw::@17]
    // display_frame_draw::@17
    // display_frame(0, PROGRESS_Y-5, 67, PROGRESS_Y-2)
    // [678] call display_frame
    // [1644] phi from display_frame_draw::@17 to display_frame [phi:display_frame_draw::@17->display_frame]
    // [1644] phi display_frame::y#0 = PROGRESS_Y-5 [phi:display_frame_draw::@17->display_frame#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-5
    sta display_frame.y
    // [1644] phi display_frame::y1#16 = PROGRESS_Y-2 [phi:display_frame_draw::@17->display_frame#1] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-2
    sta.z display_frame.y1
    // [1644] phi display_frame::x#0 = 0 [phi:display_frame_draw::@17->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1644] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@17->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [679] phi from display_frame_draw::@17 to display_frame_draw::@18 [phi:display_frame_draw::@17->display_frame_draw::@18]
    // display_frame_draw::@18
    // display_frame(0, PROGRESS_Y-2, 67, 49)
    // [680] call display_frame
    // [1644] phi from display_frame_draw::@18 to display_frame [phi:display_frame_draw::@18->display_frame]
    // [1644] phi display_frame::y#0 = PROGRESS_Y-2 [phi:display_frame_draw::@18->display_frame#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-2
    sta display_frame.y
    // [1644] phi display_frame::y1#16 = $31 [phi:display_frame_draw::@18->display_frame#1] -- vbuz1=vbuc1 
    lda #$31
    sta.z display_frame.y1
    // [1644] phi display_frame::x#0 = 0 [phi:display_frame_draw::@18->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1644] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@18->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [681] phi from display_frame_draw::@18 to display_frame_draw::@19 [phi:display_frame_draw::@18->display_frame_draw::@19]
    // display_frame_draw::@19
    // textcolor(WHITE)
    // [682] call textcolor
    // [584] phi from display_frame_draw::@19 to textcolor [phi:display_frame_draw::@19->textcolor]
    // [584] phi textcolor::color#18 = WHITE [phi:display_frame_draw::@19->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // display_frame_draw::@return
    // }
    // [683] return 
    rts
}
  // display_print_title
// void display_print_title(char *title_text)
display_print_title: {
    // gotoxy(2, 1)
    // [685] call gotoxy
    // [602] phi from display_print_title to gotoxy [phi:display_print_title->gotoxy]
    // [602] phi gotoxy::y#30 = 1 [phi:display_print_title->gotoxy#0] -- vbum1=vbuc1 
    lda #1
    sta gotoxy.y
    // [602] phi gotoxy::x#30 = 2 [phi:display_print_title->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // [686] phi from display_print_title to display_print_title::@1 [phi:display_print_title->display_print_title::@1]
    // display_print_title::@1
    // printf("%-65s", title_text)
    // [687] call printf_string
    // [1238] phi from display_print_title::@1 to printf_string [phi:display_print_title::@1->printf_string]
    // [1238] phi printf_string::putc#18 = &cputc [phi:display_print_title::@1->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1238] phi printf_string::str#18 = main::title_text [phi:display_print_title::@1->printf_string#1] -- pbuz1=pbuc1 
    lda #<main.title_text
    sta.z printf_string.str
    lda #>main.title_text
    sta.z printf_string.str+1
    // [1238] phi printf_string::format_justify_left#18 = 1 [phi:display_print_title::@1->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1238] phi printf_string::format_min_length#18 = $41 [phi:display_print_title::@1->printf_string#3] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_print_title::@return
    // }
    // [688] return 
    rts
}
  // cputsxy
// Move cursor and output a NUL-terminated string
// Same as "gotoxy (x, y); puts (s);"
// void cputsxy(__mem() char x, __mem() char y, __zp($6f) const char *s)
cputsxy: {
    .label s = $6f
    // gotoxy(x, y)
    // [690] gotoxy::x#1 = cputsxy::x#4 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [691] gotoxy::y#1 = cputsxy::y#4 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [692] call gotoxy
    // [602] phi from cputsxy to gotoxy [phi:cputsxy->gotoxy]
    // [602] phi gotoxy::y#30 = gotoxy::y#1 [phi:cputsxy->gotoxy#0] -- register_copy 
    // [602] phi gotoxy::x#30 = gotoxy::x#1 [phi:cputsxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputsxy::@1
    // cputs(s)
    // [693] cputs::s#1 = cputsxy::s#4 -- pbuz1=pbuz2 
    lda.z s
    sta.z cputs.s
    lda.z s+1
    sta.z cputs.s+1
    // [694] call cputs
    // [1778] phi from cputsxy::@1 to cputs [phi:cputsxy::@1->cputs]
    jsr cputs
    // cputsxy::@return
    // }
    // [695] return 
    rts
  .segment Data
    y: .byte 0
    x: .byte 0
}
.segment Code
  // display_progress_clear
/**
 * @brief Clean the progress area for the flashing.
 */
display_progress_clear: {
    .const h = PROGRESS_Y+PROGRESS_H
    // textcolor(WHITE)
    // [697] call textcolor
    // [584] phi from display_progress_clear to textcolor [phi:display_progress_clear->textcolor]
    // [584] phi textcolor::color#18 = WHITE [phi:display_progress_clear->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [698] phi from display_progress_clear to display_progress_clear::@5 [phi:display_progress_clear->display_progress_clear::@5]
    // display_progress_clear::@5
    // bgcolor(BLUE)
    // [699] call bgcolor
    // [589] phi from display_progress_clear::@5 to bgcolor [phi:display_progress_clear::@5->bgcolor]
    // [589] phi bgcolor::color#14 = BLUE [phi:display_progress_clear::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [700] phi from display_progress_clear::@5 to display_progress_clear::@1 [phi:display_progress_clear::@5->display_progress_clear::@1]
    // [700] phi display_progress_clear::y#2 = PROGRESS_Y [phi:display_progress_clear::@5->display_progress_clear::@1#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // display_progress_clear::@1
  __b1:
    // while (y < h)
    // [701] if(display_progress_clear::y#2<display_progress_clear::h) goto display_progress_clear::@2 -- vbum1_lt_vbuc1_then_la1 
    lda y
    cmp #h
    bcc __b4
    // display_progress_clear::@return
    // }
    // [702] return 
    rts
    // [703] phi from display_progress_clear::@1 to display_progress_clear::@2 [phi:display_progress_clear::@1->display_progress_clear::@2]
  __b4:
    // [703] phi display_progress_clear::x#2 = PROGRESS_X [phi:display_progress_clear::@1->display_progress_clear::@2#0] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x
    // [703] phi display_progress_clear::i#2 = 0 [phi:display_progress_clear::@1->display_progress_clear::@2#1] -- vbum1=vbuc1 
    lda #0
    sta i
    // display_progress_clear::@2
  __b2:
    // for(unsigned char i = 0; i < w; i++)
    // [704] if(display_progress_clear::i#2<PROGRESS_W) goto display_progress_clear::@3 -- vbum1_lt_vbuc1_then_la1 
    lda i
    cmp #PROGRESS_W
    bcc __b3
    // display_progress_clear::@4
    // y++;
    // [705] display_progress_clear::y#1 = ++ display_progress_clear::y#2 -- vbum1=_inc_vbum1 
    inc y
    // [700] phi from display_progress_clear::@4 to display_progress_clear::@1 [phi:display_progress_clear::@4->display_progress_clear::@1]
    // [700] phi display_progress_clear::y#2 = display_progress_clear::y#1 [phi:display_progress_clear::@4->display_progress_clear::@1#0] -- register_copy 
    jmp __b1
    // display_progress_clear::@3
  __b3:
    // cputcxy(x, y, ' ')
    // [706] cputcxy::x#12 = display_progress_clear::x#2 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [707] cputcxy::y#12 = display_progress_clear::y#2 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [708] call cputcxy
    // [1787] phi from display_progress_clear::@3 to cputcxy [phi:display_progress_clear::@3->cputcxy]
    // [1787] phi cputcxy::c#15 = ' ' [phi:display_progress_clear::@3->cputcxy#0] -- vbum1=vbuc1 
    lda #' '
    sta cputcxy.c
    // [1787] phi cputcxy::y#15 = cputcxy::y#12 [phi:display_progress_clear::@3->cputcxy#1] -- register_copy 
    // [1787] phi cputcxy::x#15 = cputcxy::x#12 [phi:display_progress_clear::@3->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_progress_clear::@6
    // x++;
    // [709] display_progress_clear::x#1 = ++ display_progress_clear::x#2 -- vbum1=_inc_vbum1 
    inc x
    // for(unsigned char i = 0; i < w; i++)
    // [710] display_progress_clear::i#1 = ++ display_progress_clear::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [703] phi from display_progress_clear::@6 to display_progress_clear::@2 [phi:display_progress_clear::@6->display_progress_clear::@2]
    // [703] phi display_progress_clear::x#2 = display_progress_clear::x#1 [phi:display_progress_clear::@6->display_progress_clear::@2#0] -- register_copy 
    // [703] phi display_progress_clear::i#2 = display_progress_clear::i#1 [phi:display_progress_clear::@6->display_progress_clear::@2#1] -- register_copy 
    jmp __b2
  .segment Data
    x: .byte 0
    i: .byte 0
    y: .byte 0
}
.segment Code
  // display_info_progress
// void display_info_progress(__zp($62) char *info_text)
display_info_progress: {
    .label info_text = $62
    // unsigned char x = wherex()
    // [712] call wherex
    jsr wherex
    // [713] wherex::return#2 = wherex::return#0
    // display_info_progress::@1
    // [714] display_info_progress::x#0 = wherex::return#2
    // unsigned char y = wherey()
    // [715] call wherey
    jsr wherey
    // [716] wherey::return#2 = wherey::return#0
    // display_info_progress::@2
    // [717] display_info_progress::y#0 = wherey::return#2
    // gotoxy(2, PROGRESS_Y-4)
    // [718] call gotoxy
    // [602] phi from display_info_progress::@2 to gotoxy [phi:display_info_progress::@2->gotoxy]
    // [602] phi gotoxy::y#30 = PROGRESS_Y-4 [phi:display_info_progress::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-4
    sta gotoxy.y
    // [602] phi gotoxy::x#30 = 2 [phi:display_info_progress::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // display_info_progress::@3
    // printf("%-65s", info_text)
    // [719] printf_string::str#1 = display_info_progress::info_text#14
    // [720] call printf_string
    // [1238] phi from display_info_progress::@3 to printf_string [phi:display_info_progress::@3->printf_string]
    // [1238] phi printf_string::putc#18 = &cputc [phi:display_info_progress::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1238] phi printf_string::str#18 = printf_string::str#1 [phi:display_info_progress::@3->printf_string#1] -- register_copy 
    // [1238] phi printf_string::format_justify_left#18 = 1 [phi:display_info_progress::@3->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1238] phi printf_string::format_min_length#18 = $41 [phi:display_info_progress::@3->printf_string#3] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_progress::@4
    // gotoxy(x, y)
    // [721] gotoxy::x#10 = display_info_progress::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [722] gotoxy::y#10 = display_info_progress::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [723] call gotoxy
    // [602] phi from display_info_progress::@4 to gotoxy [phi:display_info_progress::@4->gotoxy]
    // [602] phi gotoxy::y#30 = gotoxy::y#10 [phi:display_info_progress::@4->gotoxy#0] -- register_copy 
    // [602] phi gotoxy::x#30 = gotoxy::x#10 [phi:display_info_progress::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_progress::@return
    // }
    // [724] return 
    rts
  .segment Data
    .label x = wherex.return
    .label y = wherey.return
}
.segment Code
  // smc_detect
smc_detect: {
    .label smc_detect__1 = $2b
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [725] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [726] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [727] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [728] cx16_k_i2c_read_byte::return#10 = cx16_k_i2c_read_byte::return#1
    // smc_detect::@3
    // smc_bootloader_version = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [729] smc_detect::smc_bootloader_version#1 = cx16_k_i2c_read_byte::return#10
    // BYTE1(smc_bootloader_version)
    // [730] smc_detect::$1 = byte1  smc_detect::smc_bootloader_version#1 -- vbuz1=_byte1_vwum2 
    lda smc_bootloader_version+1
    sta.z smc_detect__1
    // if(!BYTE1(smc_bootloader_version))
    // [731] if(0==smc_detect::$1) goto smc_detect::@1 -- 0_eq_vbuz1_then_la1 
    beq __b1
    // [734] phi from smc_detect::@3 to smc_detect::@2 [phi:smc_detect::@3->smc_detect::@2]
    // [734] phi smc_detect::return#0 = $200 [phi:smc_detect::@3->smc_detect::@2#0] -- vwum1=vwuc1 
    lda #<$200
    sta return
    lda #>$200
    sta return+1
    rts
    // smc_detect::@1
  __b1:
    // if(smc_bootloader_version == 0xFF)
    // [732] if(smc_detect::smc_bootloader_version#1!=$ff) goto smc_detect::@4 -- vwum1_neq_vbuc1_then_la1 
    lda smc_bootloader_version+1
    bne __b2
    lda smc_bootloader_version
    cmp #$ff
    bne __b2
    // [734] phi from smc_detect::@1 to smc_detect::@2 [phi:smc_detect::@1->smc_detect::@2]
    // [734] phi smc_detect::return#0 = $100 [phi:smc_detect::@1->smc_detect::@2#0] -- vwum1=vwuc1 
    lda #<$100
    sta return
    lda #>$100
    sta return+1
    rts
    // [733] phi from smc_detect::@1 to smc_detect::@4 [phi:smc_detect::@1->smc_detect::@4]
    // smc_detect::@4
    // [734] phi from smc_detect::@4 to smc_detect::@2 [phi:smc_detect::@4->smc_detect::@2]
    // [734] phi smc_detect::return#0 = smc_detect::smc_bootloader_version#1 [phi:smc_detect::@4->smc_detect::@2#0] -- register_copy 
    // smc_detect::@2
  __b2:
    // smc_detect::@return
    // }
    // [735] return 
    rts
  .segment Data
    // When the bootloader is not present, 0xFF is returned.
    .label smc_bootloader_version = return
    return: .word 0
}
.segment Code
  // display_chip_smc
display_chip_smc: {
    // print_smc_led(GREY)
    // [737] call print_smc_led
    // [1804] phi from display_chip_smc to print_smc_led [phi:display_chip_smc->print_smc_led]
    // [1804] phi print_smc_led::c#2 = GREY [phi:display_chip_smc->print_smc_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z print_smc_led.c
    jsr print_smc_led
    // [738] phi from display_chip_smc to display_chip_smc::@1 [phi:display_chip_smc->display_chip_smc::@1]
    // display_chip_smc::@1
    // print_chip(CHIP_SMC_X, CHIP_SMC_Y+2, CHIP_SMC_W, "SMC     ")
    // [739] call print_chip
    // [1810] phi from display_chip_smc::@1 to print_chip [phi:display_chip_smc::@1->print_chip]
    // [1810] phi print_chip::text#11 = display_chip_smc::text [phi:display_chip_smc::@1->print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z print_chip.text_2
    lda #>text
    sta.z print_chip.text_2+1
    // [1810] phi print_chip::w#10 = 5 [phi:display_chip_smc::@1->print_chip#1] -- vbuz1=vbuc1 
    lda #5
    sta.z print_chip.w
    // [1810] phi print_chip::x#10 = 1 [phi:display_chip_smc::@1->print_chip#2] -- vbuz1=vbuc1 
    lda #1
    sta.z print_chip.x
    jsr print_chip
    // display_chip_smc::@return
    // }
    // [740] return 
    rts
  .segment Data
    text: .text "SMC     "
    .byte 0
}
.segment Code
  // snprintf_init
/// Initialize the snprintf() state
// void snprintf_init(char *s, unsigned int n)
snprintf_init: {
    // __snprintf_capacity = n
    // [741] __snprintf_capacity = $ffff -- vwum1=vwuc1 
    lda #<$ffff
    sta __snprintf_capacity
    lda #>$ffff
    sta __snprintf_capacity+1
    // __snprintf_size = 0
    // [742] __snprintf_size = 0 -- vwum1=vbuc1 
    lda #<0
    sta __snprintf_size
    sta __snprintf_size+1
    // __snprintf_buffer = s
    // [743] __snprintf_buffer = info_text -- pbuz1=pbuc1 
    lda #<info_text
    sta.z __snprintf_buffer
    lda #>info_text
    sta.z __snprintf_buffer+1
    // snprintf_init::@return
    // }
    // [744] return 
    rts
}
  // printf_str
/// Print a NUL-terminated string
// void printf_str(__zp($6f) void (*putc)(char), __zp($62) const char *s)
printf_str: {
    .label s = $62
    .label putc = $6f
    // [746] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [746] phi printf_str::s#70 = printf_str::s#71 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [747] printf_str::c#1 = *printf_str::s#70 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta c
    // [748] printf_str::s#0 = ++ printf_str::s#70 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [749] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // printf_str::@return
    // }
    // [750] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [751] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [752] callexecute *printf_str::putc#71  -- call__deref_pprz1 
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
  // printf_uint
// Print an unsigned int using a specific format
// void printf_uint(__zp($6f) void (*putc)(char), __mem() unsigned int uvalue, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, __mem() char format_radix)
printf_uint: {
    .label putc = $6f
    // printf_uint::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [755] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [756] utoa::value#1 = printf_uint::uvalue#16
    // [757] utoa::radix#0 = printf_uint::format_radix#16
    // [758] call utoa
    // Format number into buffer
    jsr utoa
    // printf_uint::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [759] printf_number_buffer::putc#1 = printf_uint::putc#16
    // [760] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [761] printf_number_buffer::format_min_length#1 = printf_uint::format_min_length#16
    // [762] printf_number_buffer::format_zero_padding#1 = printf_uint::format_zero_padding#16
    // [763] call printf_number_buffer
  // Print using format
    // [1884] phi from printf_uint::@2 to printf_number_buffer [phi:printf_uint::@2->printf_number_buffer]
    // [1884] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#1 [phi:printf_uint::@2->printf_number_buffer#0] -- register_copy 
    // [1884] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_uint::@2->printf_number_buffer#1] -- register_copy 
    // [1884] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#1 [phi:printf_uint::@2->printf_number_buffer#2] -- register_copy 
    // [1884] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#1 [phi:printf_uint::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uint::@return
    // }
    // [764] return 
    rts
  .segment Data
    .label uvalue = smc_detect.return
    format_radix: .byte 0
    format_min_length: .byte 0
    format_zero_padding: .byte 0
}
.segment Code
  // display_info_smc
/**
 * @brief Print the SMC status.
 * 
 * @param status The STATUS_ 
 * 
 * @remark The smc_booloader is a global variable. 
 */
// void display_info_smc(__zp($b7) char info_status, __zp($55) char *info_text)
display_info_smc: {
    .label display_info_smc__8 = $b7
    .label info_status = $b7
    .label info_text = $55
    // unsigned char x = wherex()
    // [766] call wherex
    jsr wherex
    // [767] wherex::return#10 = wherex::return#0 -- vbum1=vbum2 
    lda wherex.return
    sta wherex.return_2
    // display_info_smc::@3
    // [768] display_info_smc::x#0 = wherex::return#10
    // unsigned char y = wherey()
    // [769] call wherey
    jsr wherey
    // [770] wherey::return#10 = wherey::return#0 -- vbum1=vbum2 
    lda wherey.return
    sta wherey.return_2
    // display_info_smc::@4
    // [771] display_info_smc::y#0 = wherey::return#10
    // status_smc = info_status
    // [772] status_smc#0 = display_info_smc::info_status#12 -- vbum1=vbuz2 
    lda.z info_status
    sta status_smc
    // print_smc_led(status_color[info_status])
    // [773] print_smc_led::c#1 = status_color[display_info_smc::info_status#12] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z print_smc_led.c
    // [774] call print_smc_led
    // [1804] phi from display_info_smc::@4 to print_smc_led [phi:display_info_smc::@4->print_smc_led]
    // [1804] phi print_smc_led::c#2 = print_smc_led::c#1 [phi:display_info_smc::@4->print_smc_led#0] -- register_copy 
    jsr print_smc_led
    // [775] phi from display_info_smc::@4 to display_info_smc::@5 [phi:display_info_smc::@4->display_info_smc::@5]
    // display_info_smc::@5
    // gotoxy(INFO_X, INFO_Y)
    // [776] call gotoxy
    // [602] phi from display_info_smc::@5 to gotoxy [phi:display_info_smc::@5->gotoxy]
    // [602] phi gotoxy::y#30 = $11 [phi:display_info_smc::@5->gotoxy#0] -- vbum1=vbuc1 
    lda #$11
    sta gotoxy.y
    // [602] phi gotoxy::x#30 = 4 [phi:display_info_smc::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.x
    jsr gotoxy
    // [777] phi from display_info_smc::@5 to display_info_smc::@6 [phi:display_info_smc::@5->display_info_smc::@6]
    // display_info_smc::@6
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [778] call printf_str
    // [745] phi from display_info_smc::@6 to printf_str [phi:display_info_smc::@6->printf_str]
    // [745] phi printf_str::putc#71 = &cputc [phi:display_info_smc::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = display_info_smc::s [phi:display_info_smc::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@7
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [779] display_info_smc::$8 = display_info_smc::info_status#12 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_info_smc__8
    // [780] printf_string::str#3 = status_text[display_info_smc::$8] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z display_info_smc__8
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [781] call printf_string
    // [1238] phi from display_info_smc::@7 to printf_string [phi:display_info_smc::@7->printf_string]
    // [1238] phi printf_string::putc#18 = &cputc [phi:display_info_smc::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1238] phi printf_string::str#18 = printf_string::str#3 [phi:display_info_smc::@7->printf_string#1] -- register_copy 
    // [1238] phi printf_string::format_justify_left#18 = 1 [phi:display_info_smc::@7->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1238] phi printf_string::format_min_length#18 = 9 [phi:display_info_smc::@7->printf_string#3] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [782] phi from display_info_smc::@7 to display_info_smc::@8 [phi:display_info_smc::@7->display_info_smc::@8]
    // display_info_smc::@8
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [783] call printf_str
    // [745] phi from display_info_smc::@8 to printf_str [phi:display_info_smc::@8->printf_str]
    // [745] phi printf_str::putc#71 = &cputc [phi:display_info_smc::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = display_info_smc::s1 [phi:display_info_smc::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@9
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [784] printf_uint::uvalue#0 = smc_file_size#12 -- vwum1=vwum2 
    lda smc_file_size_2
    sta printf_uint.uvalue
    lda smc_file_size_2+1
    sta printf_uint.uvalue+1
    // [785] call printf_uint
    // [754] phi from display_info_smc::@9 to printf_uint [phi:display_info_smc::@9->printf_uint]
    // [754] phi printf_uint::format_zero_padding#16 = 1 [phi:display_info_smc::@9->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [754] phi printf_uint::format_min_length#16 = 5 [phi:display_info_smc::@9->printf_uint#1] -- vbum1=vbuc1 
    lda #5
    sta printf_uint.format_min_length
    // [754] phi printf_uint::putc#16 = &cputc [phi:display_info_smc::@9->printf_uint#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uint.putc
    lda #>cputc
    sta.z printf_uint.putc+1
    // [754] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:display_info_smc::@9->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [754] phi printf_uint::uvalue#16 = printf_uint::uvalue#0 [phi:display_info_smc::@9->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [786] phi from display_info_smc::@9 to display_info_smc::@10 [phi:display_info_smc::@9->display_info_smc::@10]
    // display_info_smc::@10
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [787] call printf_str
    // [745] phi from display_info_smc::@10 to printf_str [phi:display_info_smc::@10->printf_str]
    // [745] phi printf_str::putc#71 = &cputc [phi:display_info_smc::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = display_info_smc::s2 [phi:display_info_smc::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@11
    // if(info_text)
    // [788] if((char *)0==display_info_smc::info_text#12) goto display_info_smc::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // display_info_smc::@2
    // printf("%-20s", info_text)
    // [789] printf_string::str#4 = display_info_smc::info_text#12 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [790] call printf_string
    // [1238] phi from display_info_smc::@2 to printf_string [phi:display_info_smc::@2->printf_string]
    // [1238] phi printf_string::putc#18 = &cputc [phi:display_info_smc::@2->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1238] phi printf_string::str#18 = printf_string::str#4 [phi:display_info_smc::@2->printf_string#1] -- register_copy 
    // [1238] phi printf_string::format_justify_left#18 = 1 [phi:display_info_smc::@2->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1238] phi printf_string::format_min_length#18 = $14 [phi:display_info_smc::@2->printf_string#3] -- vbum1=vbuc1 
    lda #$14
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_smc::@1
  __b1:
    // gotoxy(x, y)
    // [791] gotoxy::x#14 = display_info_smc::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [792] gotoxy::y#14 = display_info_smc::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [793] call gotoxy
    // [602] phi from display_info_smc::@1 to gotoxy [phi:display_info_smc::@1->gotoxy]
    // [602] phi gotoxy::y#30 = gotoxy::y#14 [phi:display_info_smc::@1->gotoxy#0] -- register_copy 
    // [602] phi gotoxy::x#30 = gotoxy::x#14 [phi:display_info_smc::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_smc::@return
    // }
    // [794] return 
    rts
  .segment Data
    s: .text "SMC  "
    .byte 0
    s1: .text " ATTiny "
    .byte 0
    s2: .text " / 01E00 "
    .byte 0
    .label x = wherex.return_2
    .label y = wherey.return_2
}
.segment Code
  // display_chip_vera
display_chip_vera: {
    // print_vera_led(GREY)
    // [796] call print_vera_led
    // [1915] phi from display_chip_vera to print_vera_led [phi:display_chip_vera->print_vera_led]
    // [1915] phi print_vera_led::c#2 = GREY [phi:display_chip_vera->print_vera_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z print_vera_led.c
    jsr print_vera_led
    // [797] phi from display_chip_vera to display_chip_vera::@1 [phi:display_chip_vera->display_chip_vera::@1]
    // display_chip_vera::@1
    // print_chip(CHIP_VERA_X, CHIP_VERA_Y+2, CHIP_VERA_W, "VERA     ")
    // [798] call print_chip
    // [1810] phi from display_chip_vera::@1 to print_chip [phi:display_chip_vera::@1->print_chip]
    // [1810] phi print_chip::text#11 = display_chip_vera::text [phi:display_chip_vera::@1->print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z print_chip.text_2
    lda #>text
    sta.z print_chip.text_2+1
    // [1810] phi print_chip::w#10 = 8 [phi:display_chip_vera::@1->print_chip#1] -- vbuz1=vbuc1 
    lda #8
    sta.z print_chip.w
    // [1810] phi print_chip::x#10 = 9 [phi:display_chip_vera::@1->print_chip#2] -- vbuz1=vbuc1 
    lda #9
    sta.z print_chip.x
    jsr print_chip
    // display_chip_vera::@return
    // }
    // [799] return 
    rts
  .segment Data
    text: .text "VERA     "
    .byte 0
}
.segment Code
  // display_info_vera
/**
 * @brief Print the VERA status.
 * 
 * @param info_status The STATUS_ 
 */
// void display_info_vera(__zp($41) char info_status, __zp($2d) char *info_text)
display_info_vera: {
    .label display_info_vera__8 = $41
    .label info_status = $41
    .label info_text = $2d
    // unsigned char x = wherex()
    // [801] call wherex
    jsr wherex
    // [802] wherex::return#11 = wherex::return#0 -- vbum1=vbum2 
    lda wherex.return
    sta wherex.return_3
    // display_info_vera::@3
    // [803] display_info_vera::x#0 = wherex::return#11
    // unsigned char y = wherey()
    // [804] call wherey
    jsr wherey
    // [805] wherey::return#11 = wherey::return#0 -- vbum1=vbum2 
    lda wherey.return
    sta wherey.return_3
    // display_info_vera::@4
    // [806] display_info_vera::y#0 = wherey::return#11
    // status_vera = info_status
    // [807] status_vera#0 = display_info_vera::info_status#2 -- vbum1=vbuz2 
    lda.z info_status
    sta status_vera
    // print_vera_led(status_color[info_status])
    // [808] print_vera_led::c#1 = status_color[display_info_vera::info_status#2] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z print_vera_led.c
    // [809] call print_vera_led
    // [1915] phi from display_info_vera::@4 to print_vera_led [phi:display_info_vera::@4->print_vera_led]
    // [1915] phi print_vera_led::c#2 = print_vera_led::c#1 [phi:display_info_vera::@4->print_vera_led#0] -- register_copy 
    jsr print_vera_led
    // [810] phi from display_info_vera::@4 to display_info_vera::@5 [phi:display_info_vera::@4->display_info_vera::@5]
    // display_info_vera::@5
    // gotoxy(INFO_X, INFO_Y+1)
    // [811] call gotoxy
    // [602] phi from display_info_vera::@5 to gotoxy [phi:display_info_vera::@5->gotoxy]
    // [602] phi gotoxy::y#30 = $11+1 [phi:display_info_vera::@5->gotoxy#0] -- vbum1=vbuc1 
    lda #$11+1
    sta gotoxy.y
    // [602] phi gotoxy::x#30 = 4 [phi:display_info_vera::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.x
    jsr gotoxy
    // [812] phi from display_info_vera::@5 to display_info_vera::@6 [phi:display_info_vera::@5->display_info_vera::@6]
    // display_info_vera::@6
    // printf("VERA %-9s FPGA   1a000 / 1a000 ", status_text[info_status])
    // [813] call printf_str
    // [745] phi from display_info_vera::@6 to printf_str [phi:display_info_vera::@6->printf_str]
    // [745] phi printf_str::putc#71 = &cputc [phi:display_info_vera::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = display_info_vera::s [phi:display_info_vera::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@7
    // printf("VERA %-9s FPGA   1a000 / 1a000 ", status_text[info_status])
    // [814] display_info_vera::$8 = display_info_vera::info_status#2 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_info_vera__8
    // [815] printf_string::str#5 = status_text[display_info_vera::$8] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z display_info_vera__8
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [816] call printf_string
    // [1238] phi from display_info_vera::@7 to printf_string [phi:display_info_vera::@7->printf_string]
    // [1238] phi printf_string::putc#18 = &cputc [phi:display_info_vera::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1238] phi printf_string::str#18 = printf_string::str#5 [phi:display_info_vera::@7->printf_string#1] -- register_copy 
    // [1238] phi printf_string::format_justify_left#18 = 1 [phi:display_info_vera::@7->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1238] phi printf_string::format_min_length#18 = 9 [phi:display_info_vera::@7->printf_string#3] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [817] phi from display_info_vera::@7 to display_info_vera::@8 [phi:display_info_vera::@7->display_info_vera::@8]
    // display_info_vera::@8
    // printf("VERA %-9s FPGA   1a000 / 1a000 ", status_text[info_status])
    // [818] call printf_str
    // [745] phi from display_info_vera::@8 to printf_str [phi:display_info_vera::@8->printf_str]
    // [745] phi printf_str::putc#71 = &cputc [phi:display_info_vera::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = display_info_vera::s1 [phi:display_info_vera::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@9
    // if(info_text)
    // [819] if((char *)0==display_info_vera::info_text#10) goto display_info_vera::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // display_info_vera::@2
    // printf("%-20s", info_text)
    // [820] printf_string::str#6 = display_info_vera::info_text#10 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [821] call printf_string
    // [1238] phi from display_info_vera::@2 to printf_string [phi:display_info_vera::@2->printf_string]
    // [1238] phi printf_string::putc#18 = &cputc [phi:display_info_vera::@2->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1238] phi printf_string::str#18 = printf_string::str#6 [phi:display_info_vera::@2->printf_string#1] -- register_copy 
    // [1238] phi printf_string::format_justify_left#18 = 1 [phi:display_info_vera::@2->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1238] phi printf_string::format_min_length#18 = $14 [phi:display_info_vera::@2->printf_string#3] -- vbum1=vbuc1 
    lda #$14
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_vera::@1
  __b1:
    // gotoxy(x, y)
    // [822] gotoxy::x#16 = display_info_vera::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [823] gotoxy::y#16 = display_info_vera::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [824] call gotoxy
    // [602] phi from display_info_vera::@1 to gotoxy [phi:display_info_vera::@1->gotoxy]
    // [602] phi gotoxy::y#30 = gotoxy::y#16 [phi:display_info_vera::@1->gotoxy#0] -- register_copy 
    // [602] phi gotoxy::x#30 = gotoxy::x#16 [phi:display_info_vera::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_vera::@return
    // }
    // [825] return 
    rts
  .segment Data
    s: .text "VERA "
    .byte 0
    s1: .text " FPGA   1a000 / 1a000 "
    .byte 0
    .label x = wherex.return_3
    .label y = wherey.return_3
}
.segment Code
  // rom_detect
rom_detect: {
    .const bank_set_brom1_bank = 4
    .label rom_detect__3 = $2b
    .label rom_detect__5 = $47
    .label rom_detect__9 = $66
    .label rom_detect__14 = $79
    .label rom_detect__15 = $46
    .label rom_detect__18 = $77
    .label rom_detect__21 = $65
    .label rom_detect__24 = $64
    // [827] phi from rom_detect to rom_detect::@1 [phi:rom_detect->rom_detect::@1]
    // [827] phi rom_detect::rom_chip#10 = 0 [phi:rom_detect->rom_detect::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // [827] phi rom_detect::rom_detect_address#10 = 0 [phi:rom_detect->rom_detect::@1#1] -- vdum1=vduc1 
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
    // [828] if(rom_detect::rom_detect_address#10<8*$80000) goto rom_detect::@2 -- vdum1_lt_vduc1_then_la1 
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
    // [829] return 
    rts
    // rom_detect::@2
  __b2:
    // rom_manufacturer_ids[rom_chip] = 0
    // [830] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = 0
    // [831] rom_device_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta rom_device_ids,y
    // rom_unlock(rom_detect_address + 0x05555, 0x90)
    // [832] rom_unlock::address#2 = rom_detect::rom_detect_address#10 + $5555 -- vduz1=vdum2_plus_vwuc1 
    clc
    lda rom_detect_address
    adc #<$5555
    sta.z rom_unlock.address
    lda rom_detect_address+1
    adc #>$5555
    sta.z rom_unlock.address+1
    lda rom_detect_address+2
    adc #0
    sta.z rom_unlock.address+2
    lda rom_detect_address+3
    adc #0
    sta.z rom_unlock.address+3
    // [833] call rom_unlock
    // [1921] phi from rom_detect::@2 to rom_unlock [phi:rom_detect::@2->rom_unlock]
    // [1921] phi rom_unlock::unlock_code#5 = $90 [phi:rom_detect::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$90
    sta.z rom_unlock.unlock_code
    // [1921] phi rom_unlock::address#5 = rom_unlock::address#2 [phi:rom_detect::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_detect::@12
    // rom_read_byte(rom_detect_address)
    // [834] rom_read_byte::address#0 = rom_detect::rom_detect_address#10 -- vduz1=vdum2 
    lda rom_detect_address
    sta.z rom_read_byte.address
    lda rom_detect_address+1
    sta.z rom_read_byte.address+1
    lda rom_detect_address+2
    sta.z rom_read_byte.address+2
    lda rom_detect_address+3
    sta.z rom_read_byte.address+3
    // [835] call rom_read_byte
    // [1931] phi from rom_detect::@12 to rom_read_byte [phi:rom_detect::@12->rom_read_byte]
    // [1931] phi rom_read_byte::address#2 = rom_read_byte::address#0 [phi:rom_detect::@12->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(rom_detect_address)
    // [836] rom_read_byte::return#2 = rom_read_byte::return#0
    // rom_detect::@13
    // [837] rom_detect::$3 = rom_read_byte::return#2 -- vbuz1=vbum2 
    lda rom_read_byte.return
    sta.z rom_detect__3
    // rom_manufacturer_ids[rom_chip] = rom_read_byte(rom_detect_address)
    // [838] rom_manufacturer_ids[rom_detect::rom_chip#10] = rom_detect::$3 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_read_byte(rom_detect_address + 1)
    // [839] rom_read_byte::address#1 = rom_detect::rom_detect_address#10 + 1 -- vduz1=vdum2_plus_1 
    lda rom_detect_address
    clc
    adc #1
    sta.z rom_read_byte.address
    lda rom_detect_address+1
    adc #0
    sta.z rom_read_byte.address+1
    lda rom_detect_address+2
    adc #0
    sta.z rom_read_byte.address+2
    lda rom_detect_address+3
    adc #0
    sta.z rom_read_byte.address+3
    // [840] call rom_read_byte
    // [1931] phi from rom_detect::@13 to rom_read_byte [phi:rom_detect::@13->rom_read_byte]
    // [1931] phi rom_read_byte::address#2 = rom_read_byte::address#1 [phi:rom_detect::@13->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(rom_detect_address + 1)
    // [841] rom_read_byte::return#3 = rom_read_byte::return#0
    // rom_detect::@14
    // [842] rom_detect::$5 = rom_read_byte::return#3 -- vbuz1=vbum2 
    lda rom_read_byte.return
    sta.z rom_detect__5
    // rom_device_ids[rom_chip] = rom_read_byte(rom_detect_address + 1)
    // [843] rom_device_ids[rom_detect::rom_chip#10] = rom_detect::$5 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy rom_chip
    sta rom_device_ids,y
    // rom_unlock(rom_detect_address + 0x05555, 0xF0)
    // [844] rom_unlock::address#3 = rom_detect::rom_detect_address#10 + $5555 -- vduz1=vdum2_plus_vwuc1 
    clc
    lda rom_detect_address
    adc #<$5555
    sta.z rom_unlock.address
    lda rom_detect_address+1
    adc #>$5555
    sta.z rom_unlock.address+1
    lda rom_detect_address+2
    adc #0
    sta.z rom_unlock.address+2
    lda rom_detect_address+3
    adc #0
    sta.z rom_unlock.address+3
    // [845] call rom_unlock
    // [1921] phi from rom_detect::@14 to rom_unlock [phi:rom_detect::@14->rom_unlock]
    // [1921] phi rom_unlock::unlock_code#5 = $f0 [phi:rom_detect::@14->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$f0
    sta.z rom_unlock.unlock_code
    // [1921] phi rom_unlock::address#5 = rom_unlock::address#3 [phi:rom_detect::@14->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_detect::bank_set_brom1
    // BROM = bank
    // [846] BROM = rom_detect::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // rom_detect::@11
    // rom_chip*3
    // [847] rom_detect::$14 = rom_detect::rom_chip#10 << 1 -- vbuz1=vbum2_rol_1 
    lda rom_chip
    asl
    sta.z rom_detect__14
    // [848] rom_detect::$9 = rom_detect::$14 + rom_detect::rom_chip#10 -- vbuz1=vbuz2_plus_vbum3 
    lda rom_chip
    clc
    adc.z rom_detect__14
    sta.z rom_detect__9
    // gotoxy(rom_chip*3+40, 1)
    // [849] gotoxy::x#23 = rom_detect::$9 + $28 -- vbum1=vbuz2_plus_vbuc1 
    lda #$28
    clc
    adc.z rom_detect__9
    sta gotoxy.x
    // [850] call gotoxy
    // [602] phi from rom_detect::@11 to gotoxy [phi:rom_detect::@11->gotoxy]
    // [602] phi gotoxy::y#30 = 1 [phi:rom_detect::@11->gotoxy#0] -- vbum1=vbuc1 
    lda #1
    sta gotoxy.y
    // [602] phi gotoxy::x#30 = gotoxy::x#23 [phi:rom_detect::@11->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_detect::@15
    // printf("%02x", rom_device_ids[rom_chip])
    // [851] printf_uchar::uvalue#4 = rom_device_ids[rom_detect::rom_chip#10] -- vbum1=pbuc1_derefidx_vbum2 
    ldy rom_chip
    lda rom_device_ids,y
    sta printf_uchar.uvalue
    // [852] call printf_uchar
    // [1162] phi from rom_detect::@15 to printf_uchar [phi:rom_detect::@15->printf_uchar]
    // [1162] phi printf_uchar::format_zero_padding#11 = 1 [phi:rom_detect::@15->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1162] phi printf_uchar::format_min_length#11 = 2 [phi:rom_detect::@15->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1162] phi printf_uchar::putc#11 = &cputc [phi:rom_detect::@15->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1162] phi printf_uchar::format_radix#11 = HEXADECIMAL [phi:rom_detect::@15->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1162] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#4 [phi:rom_detect::@15->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // rom_detect::@16
    // case SST39SF010A:
    //             rom_device_names[rom_chip] = "f010a";
    //             rom_size_strings[rom_chip] = "128";
    //             rom_sizes[rom_chip] = 128 * 1024;
    //             break;
    // [853] if(rom_device_ids[rom_detect::rom_chip#10]==$b5) goto rom_detect::@3 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
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
    // [854] if(rom_device_ids[rom_detect::rom_chip#10]==$b6) goto rom_detect::@4 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
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
    // [855] if(rom_device_ids[rom_detect::rom_chip#10]==$b7) goto rom_detect::@5 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b7
    beq __b5
    // rom_detect::@6
    // rom_manufacturer_ids[rom_chip] = 0
    // [856] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    sta rom_manufacturer_ids,y
    // rom_device_names[rom_chip] = "----"
    // [857] rom_device_names[rom_detect::$14] = rom_detect::$31 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__14
    lda #<rom_detect__31
    sta rom_device_names,y
    lda #>rom_detect__31
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "000"
    // [858] rom_size_strings[rom_detect::$14] = rom_detect::$32 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__32
    sta rom_size_strings,y
    lda #>rom_detect__32
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 0
    // [859] rom_detect::$24 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__24
    // [860] rom_sizes[rom_detect::$24] = 0 -- pduc1_derefidx_vbuz1=vbuc2 
    tay
    lda #0
    sta rom_sizes,y
    sta rom_sizes+1,y
    sta rom_sizes+2,y
    sta rom_sizes+3,y
    // rom_device_ids[rom_chip] = UNKNOWN
    // [861] rom_device_ids[rom_detect::rom_chip#10] = $55 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$55
    ldy rom_chip
    sta rom_device_ids,y
    // rom_detect::@7
  __b7:
    // rom_chip++;
    // [862] rom_detect::rom_chip#1 = ++ rom_detect::rom_chip#10 -- vbum1=_inc_vbum1 
    inc rom_chip
    // rom_detect::@8
    // rom_detect_address += 0x80000
    // [863] rom_detect::rom_detect_address#1 = rom_detect::rom_detect_address#10 + $80000 -- vdum1=vdum1_plus_vduc1 
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
    // [827] phi from rom_detect::@8 to rom_detect::@1 [phi:rom_detect::@8->rom_detect::@1]
    // [827] phi rom_detect::rom_chip#10 = rom_detect::rom_chip#1 [phi:rom_detect::@8->rom_detect::@1#0] -- register_copy 
    // [827] phi rom_detect::rom_detect_address#10 = rom_detect::rom_detect_address#1 [phi:rom_detect::@8->rom_detect::@1#1] -- register_copy 
    jmp __b1
    // rom_detect::@5
  __b5:
    // rom_device_names[rom_chip] = "f040"
    // [864] rom_device_names[rom_detect::$14] = rom_detect::$29 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__14
    lda #<rom_detect__29
    sta rom_device_names,y
    lda #>rom_detect__29
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "512"
    // [865] rom_size_strings[rom_detect::$14] = rom_detect::$30 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__30
    sta rom_size_strings,y
    lda #>rom_detect__30
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 512 * 1024
    // [866] rom_detect::$21 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__21
    // [867] rom_sizes[rom_detect::$21] = (unsigned long)$200*$400 -- pduc1_derefidx_vbuz1=vduc2 
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
    // [868] rom_device_names[rom_detect::$14] = rom_detect::$27 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__14
    lda #<rom_detect__27
    sta rom_device_names,y
    lda #>rom_detect__27
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "256"
    // [869] rom_size_strings[rom_detect::$14] = rom_detect::$28 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__28
    sta rom_size_strings,y
    lda #>rom_detect__28
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 256 * 1024
    // [870] rom_detect::$18 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__18
    // [871] rom_sizes[rom_detect::$18] = (unsigned long)$100*$400 -- pduc1_derefidx_vbuz1=vduc2 
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
    // [872] rom_device_names[rom_detect::$14] = rom_detect::$25 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__14
    lda #<rom_detect__25
    sta rom_device_names,y
    lda #>rom_detect__25
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "128"
    // [873] rom_size_strings[rom_detect::$14] = rom_detect::$26 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__26
    sta rom_size_strings,y
    lda #>rom_detect__26
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 128 * 1024
    // [874] rom_detect::$15 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__15
    // [875] rom_sizes[rom_detect::$15] = (unsigned long)$80*$400 -- pduc1_derefidx_vbuz1=vduc2 
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
  // display_chip_rom
display_chip_rom: {
    .label display_chip_rom__4 = $79
    .label display_chip_rom__6 = $bb
    .label display_chip_rom__11 = $47
    .label display_chip_rom__12 = $47
    // [877] phi from display_chip_rom to display_chip_rom::@1 [phi:display_chip_rom->display_chip_rom::@1]
    // [877] phi display_chip_rom::r#2 = 0 [phi:display_chip_rom->display_chip_rom::@1#0] -- vbum1=vbuc1 
    lda #0
    sta r
    // display_chip_rom::@1
  __b1:
    // for (unsigned char r = 0; r < 8; r++)
    // [878] if(display_chip_rom::r#2<8) goto display_chip_rom::@2 -- vbum1_lt_vbuc1_then_la1 
    lda r
    cmp #8
    bcc __b2
    // display_chip_rom::@return
    // }
    // [879] return 
    rts
    // [880] phi from display_chip_rom::@1 to display_chip_rom::@2 [phi:display_chip_rom::@1->display_chip_rom::@2]
    // display_chip_rom::@2
  __b2:
    // strcpy(rom, "ROM  ")
    // [881] call strcpy
    // [1943] phi from display_chip_rom::@2 to strcpy [phi:display_chip_rom::@2->strcpy]
    jsr strcpy
    // display_chip_rom::@5
    // strcat(rom, rom_size_strings[r])
    // [882] display_chip_rom::$11 = display_chip_rom::r#2 << 1 -- vbuz1=vbum2_rol_1 
    lda r
    asl
    sta.z display_chip_rom__11
    // [883] strcat::source#0 = rom_size_strings[display_chip_rom::$11] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda rom_size_strings,y
    sta.z strcat.source
    lda rom_size_strings+1,y
    sta.z strcat.source+1
    // [884] call strcat
    // [1951] phi from display_chip_rom::@5 to strcat [phi:display_chip_rom::@5->strcat]
    jsr strcat
    // display_chip_rom::@6
    // if(r)
    // [885] if(0==display_chip_rom::r#2) goto display_chip_rom::@3 -- 0_eq_vbum1_then_la1 
    lda r
    beq __b3
    // display_chip_rom::@4
    // r+'0'
    // [886] display_chip_rom::$4 = display_chip_rom::r#2 + '0' -- vbuz1=vbum2_plus_vbuc1 
    lda #'0'
    clc
    adc r
    sta.z display_chip_rom__4
    // *(rom+3) = r+'0'
    // [887] *(display_chip_rom::rom+3) = display_chip_rom::$4 -- _deref_pbuc1=vbuz1 
    sta rom+3
    // display_chip_rom::@3
  __b3:
    // print_rom_led(r, GREY)
    // [888] print_rom_led::chip#0 = display_chip_rom::r#2 -- vbuz1=vbum2 
    lda r
    sta.z print_rom_led.chip
    // [889] call print_rom_led
    // [1963] phi from display_chip_rom::@3 to print_rom_led [phi:display_chip_rom::@3->print_rom_led]
    // [1963] phi print_rom_led::c#2 = GREY [phi:display_chip_rom::@3->print_rom_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z print_rom_led.c
    // [1963] phi print_rom_led::chip#2 = print_rom_led::chip#0 [phi:display_chip_rom::@3->print_rom_led#1] -- register_copy 
    jsr print_rom_led
    // display_chip_rom::@7
    // r*6
    // [890] display_chip_rom::$12 = display_chip_rom::$11 + display_chip_rom::r#2 -- vbuz1=vbuz1_plus_vbum2 
    lda r
    clc
    adc.z display_chip_rom__12
    sta.z display_chip_rom__12
    // [891] display_chip_rom::$6 = display_chip_rom::$12 << 1 -- vbuz1=vbuz2_rol_1 
    asl
    sta.z display_chip_rom__6
    // print_chip(CHIP_ROM_X+r*6, CHIP_ROM_Y+2, CHIP_ROM_W, rom)
    // [892] print_chip::x#2 = $14 + display_chip_rom::$6 -- vbuz1=vbuc1_plus_vbuz1 
    lda #$14
    clc
    adc.z print_chip.x
    sta.z print_chip.x
    // [893] call print_chip
    // [1810] phi from display_chip_rom::@7 to print_chip [phi:display_chip_rom::@7->print_chip]
    // [1810] phi print_chip::text#11 = display_chip_rom::rom [phi:display_chip_rom::@7->print_chip#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z print_chip.text_2
    lda #>rom
    sta.z print_chip.text_2+1
    // [1810] phi print_chip::w#10 = 3 [phi:display_chip_rom::@7->print_chip#1] -- vbuz1=vbuc1 
    lda #3
    sta.z print_chip.w
    // [1810] phi print_chip::x#10 = print_chip::x#2 [phi:display_chip_rom::@7->print_chip#2] -- register_copy 
    jsr print_chip
    // display_chip_rom::@8
    // for (unsigned char r = 0; r < 8; r++)
    // [894] display_chip_rom::r#1 = ++ display_chip_rom::r#2 -- vbum1=_inc_vbum1 
    inc r
    // [877] phi from display_chip_rom::@8 to display_chip_rom::@1 [phi:display_chip_rom::@8->display_chip_rom::@1]
    // [877] phi display_chip_rom::r#2 = display_chip_rom::r#1 [phi:display_chip_rom::@8->display_chip_rom::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    rom: .fill $10, 0
    source: .text "ROM  "
    .byte 0
    r: .byte 0
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
// __mem() char util_wait_key(__zp($5e) char *info_text, __zp($42) char *filter)
util_wait_key: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 0
    .label util_wait_key__9 = $62
    .label info_text = $5e
    .label filter = $42
    // display_info_line(info_text)
    // [896] display_info_line::info_text#0 = util_wait_key::info_text#4
    // [897] call display_info_line
    // [976] phi from util_wait_key to display_info_line [phi:util_wait_key->display_info_line]
    // [976] phi display_info_line::info_text#19 = display_info_line::info_text#0 [phi:util_wait_key->display_info_line#0] -- register_copy 
    jsr display_info_line
    // util_wait_key::bank_get_bram1
    // return BRAM;
    // [898] util_wait_key::bram#0 = BRAM -- vbum1=vbuz2 
    lda.z BRAM
    sta bram
    // util_wait_key::bank_get_brom1
    // return BROM;
    // [899] util_wait_key::bank_get_brom1_return#0 = BROM -- vbum1=vbuz2 
    lda.z BROM
    sta bank_get_brom1_return
    // util_wait_key::bank_set_bram1
    // BRAM = bank
    // [900] BRAM = util_wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // util_wait_key::bank_set_brom1
    // BROM = bank
    // [901] BROM = util_wait_key::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [902] phi from util_wait_key::@2 util_wait_key::@5 util_wait_key::bank_set_brom1 to util_wait_key::kbhit1 [phi:util_wait_key::@2/util_wait_key::@5/util_wait_key::bank_set_brom1->util_wait_key::kbhit1]
    // util_wait_key::kbhit1
  kbhit1:
    // util_wait_key::kbhit1_cbm_k_clrchn1
    // asm
    // asm { jsrCBM_CLRCHN  }
    jsr CBM_CLRCHN
    // [904] phi from util_wait_key::kbhit1_cbm_k_clrchn1 to util_wait_key::kbhit1_@2 [phi:util_wait_key::kbhit1_cbm_k_clrchn1->util_wait_key::kbhit1_@2]
    // util_wait_key::kbhit1_@2
    // cbm_k_getin()
    // [905] call cbm_k_getin
    jsr cbm_k_getin
    // [906] cbm_k_getin::return#2 = cbm_k_getin::return#1
    // util_wait_key::@4
    // [907] util_wait_key::ch#4 = cbm_k_getin::return#2 -- vwum1=vbum2 
    lda cbm_k_getin.return
    sta ch
    lda #0
    sta ch+1
    // util_wait_key::@3
    // if (filter)
    // [908] if((char *)0!=util_wait_key::filter#14) goto util_wait_key::@1 -- pbuc1_neq_pbuz1_then_la1 
    // if there is a filter, check the filter, otherwise return ch.
    lda.z filter+1
    cmp #>0
    bne __b1
    lda.z filter
    cmp #<0
    bne __b1
    // util_wait_key::@2
    // if(ch)
    // [909] if(0!=util_wait_key::ch#4) goto util_wait_key::bank_set_bram2 -- 0_neq_vwum1_then_la1 
    lda ch
    ora ch+1
    bne bank_set_bram2
    jmp kbhit1
    // util_wait_key::bank_set_bram2
  bank_set_bram2:
    // BRAM = bank
    // [910] BRAM = util_wait_key::bram#0 -- vbuz1=vbum2 
    lda bram
    sta.z BRAM
    // util_wait_key::bank_set_brom2
    // BROM = bank
    // [911] BROM = util_wait_key::bank_get_brom1_return#0 -- vbuz1=vbum2 
    lda bank_get_brom1_return
    sta.z BROM
    // util_wait_key::@return
    // }
    // [912] return 
    rts
    // util_wait_key::@1
  __b1:
    // strchr(filter, ch)
    // [913] strchr::str#0 = (const void *)util_wait_key::filter#14 -- pvoz1=pvoz2 
    lda.z filter
    sta.z strchr.str
    lda.z filter+1
    sta.z strchr.str+1
    // [914] strchr::c#0 = util_wait_key::ch#4 -- vbum1=vwum2 
    lda ch
    sta strchr.c
    // [915] call strchr
    // [1539] phi from util_wait_key::@1 to strchr [phi:util_wait_key::@1->strchr]
    // [1539] phi strchr::c#4 = strchr::c#0 [phi:util_wait_key::@1->strchr#0] -- register_copy 
    // [1539] phi strchr::str#2 = strchr::str#0 [phi:util_wait_key::@1->strchr#1] -- register_copy 
    jsr strchr
    // strchr(filter, ch)
    // [916] strchr::return#3 = strchr::return#2
    // util_wait_key::@5
    // [917] util_wait_key::$9 = strchr::return#3
    // if(strchr(filter, ch) != NULL)
    // [918] if(util_wait_key::$9!=0) goto util_wait_key::bank_set_bram2 -- pvoz1_neq_0_then_la1 
    lda.z util_wait_key__9
    ora.z util_wait_key__9+1
    bne bank_set_bram2
    jmp kbhit1
  .segment Data
    bram: .byte 0
    bank_get_brom1_return: .byte 0
    .label return = strchr.c
    ch: .word 0
}
.segment Code
  // smc_read
// __mem() unsigned int smc_read(char b, unsigned int progress_row_size)
smc_read: {
    .label fp = $60
    .label ram_address = $44
    // display_info_progress("Reading SMC.BIN ... (.) data, ( ) empty")
    // [920] call display_info_progress
  // It is assume that one RAM bank is 0X2000 bytes.
    // [711] phi from smc_read to display_info_progress [phi:smc_read->display_info_progress]
    // [711] phi display_info_progress::info_text#14 = smc_read::info_text [phi:smc_read->display_info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_progress.info_text
    lda #>info_text
    sta.z display_info_progress.info_text+1
    jsr display_info_progress
    // [921] phi from smc_read to smc_read::@7 [phi:smc_read->smc_read::@7]
    // smc_read::@7
    // textcolor(WHITE)
    // [922] call textcolor
    // [584] phi from smc_read::@7 to textcolor [phi:smc_read::@7->textcolor]
    // [584] phi textcolor::color#18 = WHITE [phi:smc_read::@7->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [923] phi from smc_read::@7 to smc_read::@8 [phi:smc_read::@7->smc_read::@8]
    // smc_read::@8
    // gotoxy(x, y)
    // [924] call gotoxy
    // [602] phi from smc_read::@8 to gotoxy [phi:smc_read::@8->gotoxy]
    // [602] phi gotoxy::y#30 = PROGRESS_Y [phi:smc_read::@8->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [602] phi gotoxy::x#30 = PROGRESS_X [phi:smc_read::@8->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [925] phi from smc_read::@8 to smc_read::@9 [phi:smc_read::@8->smc_read::@9]
    // smc_read::@9
    // FILE *fp = fopen("SMC.BIN", "r")
    // [926] call fopen
    // [1979] phi from smc_read::@9 to fopen [phi:smc_read::@9->fopen]
    // [1979] phi __errno#335 = __errno#35 [phi:smc_read::@9->fopen#0] -- register_copy 
    // [1979] phi fopen::pathtoken#0 = smc_read::path [phi:smc_read::@9->fopen#1] -- pbuz1=pbuc1 
    lda #<path
    sta.z fopen.pathtoken
    lda #>path
    sta.z fopen.pathtoken+1
    jsr fopen
    // FILE *fp = fopen("SMC.BIN", "r")
    // [927] fopen::return#3 = fopen::return#2
    // smc_read::@10
    // [928] smc_read::fp#0 = fopen::return#3 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [929] if((struct $2 *)0==smc_read::fp#0) goto smc_read::@1 -- pssc1_eq_pssz1_then_la1 
    lda.z fp
    cmp #<0
    bne !+
    lda.z fp+1
    cmp #>0
    beq __b4
  !:
    // [930] phi from smc_read::@10 to smc_read::@2 [phi:smc_read::@10->smc_read::@2]
    // [930] phi smc_read::y#10 = PROGRESS_Y [phi:smc_read::@10->smc_read::@2#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [930] phi smc_read::progress_row_bytes#10 = 0 [phi:smc_read::@10->smc_read::@2#1] -- vwum1=vwuc1 
    lda #<0
    sta progress_row_bytes
    sta progress_row_bytes+1
    // [930] phi smc_read::smc_file_size#11 = 0 [phi:smc_read::@10->smc_read::@2#2] -- vwum1=vwuc1 
    sta smc_file_size
    sta smc_file_size+1
    // [930] phi smc_read::ram_address#10 = (char *)$6000 [phi:smc_read::@10->smc_read::@2#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z ram_address
    lda #>$6000
    sta.z ram_address+1
  // We read b bytes at a time, and each b bytes we plot a dot.
  // Every r bytes we move to the next line.
    // smc_read::@2
  __b2:
    // fgets(ram_address, b, fp)
    // [931] fgets::ptr#2 = smc_read::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z fgets.ptr
    lda.z ram_address+1
    sta.z fgets.ptr+1
    // [932] fgets::stream#0 = smc_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.stream
    lda.z fp+1
    sta.z fgets.stream+1
    // [933] call fgets
    // [2060] phi from smc_read::@2 to fgets [phi:smc_read::@2->fgets]
    // [2060] phi fgets::ptr#12 = fgets::ptr#2 [phi:smc_read::@2->fgets#0] -- register_copy 
    // [2060] phi fgets::size#10 = 8 [phi:smc_read::@2->fgets#1] -- vwum1=vbuc1 
    lda #<8
    sta fgets.size
    lda #>8
    sta fgets.size+1
    // [2060] phi fgets::stream#2 = fgets::stream#0 [phi:smc_read::@2->fgets#2] -- register_copy 
    jsr fgets
    // fgets(ram_address, b, fp)
    // [934] fgets::return#5 = fgets::return#1
    // smc_read::@11
    // smc_file_read = fgets(ram_address, b, fp)
    // [935] smc_read::smc_file_read#1 = fgets::return#5
    // while (smc_file_read = fgets(ram_address, b, fp))
    // [936] if(0!=smc_read::smc_file_read#1) goto smc_read::@3 -- 0_neq_vwum1_then_la1 
    lda smc_file_read
    ora smc_file_read+1
    bne __b3
    // smc_read::@4
    // fclose(fp)
    // [937] fclose::stream#0 = smc_read::fp#0
    // [938] call fclose
    // [2114] phi from smc_read::@4 to fclose [phi:smc_read::@4->fclose]
    // [2114] phi fclose::stream#2 = fclose::stream#0 [phi:smc_read::@4->fclose#0] -- register_copy 
    jsr fclose
    // [939] phi from smc_read::@4 to smc_read::@1 [phi:smc_read::@4->smc_read::@1]
    // [939] phi smc_read::return#0 = smc_read::smc_file_size#11 [phi:smc_read::@4->smc_read::@1#0] -- register_copy 
    rts
    // [939] phi from smc_read::@10 to smc_read::@1 [phi:smc_read::@10->smc_read::@1]
  __b4:
    // [939] phi smc_read::return#0 = 0 [phi:smc_read::@10->smc_read::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta return
    sta return+1
    // smc_read::@1
    // smc_read::@return
    // }
    // [940] return 
    rts
    // [941] phi from smc_read::@11 to smc_read::@3 [phi:smc_read::@11->smc_read::@3]
    // smc_read::@3
  __b3:
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [942] call snprintf_init
    jsr snprintf_init
    // [943] phi from smc_read::@3 to smc_read::@12 [phi:smc_read::@3->smc_read::@12]
    // smc_read::@12
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [944] call printf_str
    // [745] phi from smc_read::@12 to printf_str [phi:smc_read::@12->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:smc_read::@12->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = smc_read::s [phi:smc_read::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@13
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [945] printf_uint::uvalue#1 = smc_read::smc_file_read#1 -- vwum1=vwum2 
    lda smc_file_read
    sta printf_uint.uvalue
    lda smc_file_read+1
    sta printf_uint.uvalue+1
    // [946] call printf_uint
    // [754] phi from smc_read::@13 to printf_uint [phi:smc_read::@13->printf_uint]
    // [754] phi printf_uint::format_zero_padding#16 = 1 [phi:smc_read::@13->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [754] phi printf_uint::format_min_length#16 = 5 [phi:smc_read::@13->printf_uint#1] -- vbum1=vbuc1 
    lda #5
    sta printf_uint.format_min_length
    // [754] phi printf_uint::putc#16 = &snputc [phi:smc_read::@13->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [754] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:smc_read::@13->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [754] phi printf_uint::uvalue#16 = printf_uint::uvalue#1 [phi:smc_read::@13->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [947] phi from smc_read::@13 to smc_read::@14 [phi:smc_read::@13->smc_read::@14]
    // smc_read::@14
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [948] call printf_str
    // [745] phi from smc_read::@14 to printf_str [phi:smc_read::@14->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:smc_read::@14->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = s4 [phi:smc_read::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@15
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [949] printf_uint::uvalue#2 = smc_read::smc_file_size#11 -- vwum1=vwum2 
    lda smc_file_size
    sta printf_uint.uvalue
    lda smc_file_size+1
    sta printf_uint.uvalue+1
    // [950] call printf_uint
    // [754] phi from smc_read::@15 to printf_uint [phi:smc_read::@15->printf_uint]
    // [754] phi printf_uint::format_zero_padding#16 = 1 [phi:smc_read::@15->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [754] phi printf_uint::format_min_length#16 = 5 [phi:smc_read::@15->printf_uint#1] -- vbum1=vbuc1 
    lda #5
    sta printf_uint.format_min_length
    // [754] phi printf_uint::putc#16 = &snputc [phi:smc_read::@15->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [754] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:smc_read::@15->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [754] phi printf_uint::uvalue#16 = printf_uint::uvalue#2 [phi:smc_read::@15->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [951] phi from smc_read::@15 to smc_read::@16 [phi:smc_read::@15->smc_read::@16]
    // smc_read::@16
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [952] call printf_str
    // [745] phi from smc_read::@16 to printf_str [phi:smc_read::@16->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:smc_read::@16->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = s2 [phi:smc_read::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // [953] phi from smc_read::@16 to smc_read::@17 [phi:smc_read::@16->smc_read::@17]
    // smc_read::@17
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [954] call printf_uint
    // [754] phi from smc_read::@17 to printf_uint [phi:smc_read::@17->printf_uint]
    // [754] phi printf_uint::format_zero_padding#16 = 1 [phi:smc_read::@17->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [754] phi printf_uint::format_min_length#16 = 2 [phi:smc_read::@17->printf_uint#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uint.format_min_length
    // [754] phi printf_uint::putc#16 = &snputc [phi:smc_read::@17->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [754] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:smc_read::@17->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [754] phi printf_uint::uvalue#16 = 0 [phi:smc_read::@17->printf_uint#4] -- vwum1=vbuc1 
    lda #<0
    sta printf_uint.uvalue
    sta printf_uint.uvalue+1
    jsr printf_uint
    // [955] phi from smc_read::@17 to smc_read::@18 [phi:smc_read::@17->smc_read::@18]
    // smc_read::@18
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [956] call printf_str
    // [745] phi from smc_read::@18 to printf_str [phi:smc_read::@18->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:smc_read::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = s3 [phi:smc_read::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@19
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [957] printf_uint::uvalue#4 = (unsigned int)smc_read::ram_address#10 -- vwum1=vwuz2 
    lda.z ram_address
    sta printf_uint.uvalue
    lda.z ram_address+1
    sta printf_uint.uvalue+1
    // [958] call printf_uint
    // [754] phi from smc_read::@19 to printf_uint [phi:smc_read::@19->printf_uint]
    // [754] phi printf_uint::format_zero_padding#16 = 1 [phi:smc_read::@19->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [754] phi printf_uint::format_min_length#16 = 4 [phi:smc_read::@19->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [754] phi printf_uint::putc#16 = &snputc [phi:smc_read::@19->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [754] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:smc_read::@19->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [754] phi printf_uint::uvalue#16 = printf_uint::uvalue#4 [phi:smc_read::@19->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [959] phi from smc_read::@19 to smc_read::@20 [phi:smc_read::@19->smc_read::@20]
    // smc_read::@20
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [960] call printf_str
    // [745] phi from smc_read::@20 to printf_str [phi:smc_read::@20->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:smc_read::@20->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = s7 [phi:smc_read::@20->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@21
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [961] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [962] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_line(info_text)
    // [964] call display_info_line
    // [976] phi from smc_read::@21 to display_info_line [phi:smc_read::@21->display_info_line]
    // [976] phi display_info_line::info_text#19 = info_text [phi:smc_read::@21->display_info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_line.info_text
    lda #>@info_text
    sta.z display_info_line.info_text+1
    jsr display_info_line
    // smc_read::@22
    // if (progress_row_bytes == progress_row_size)
    // [965] if(smc_read::progress_row_bytes#10!=$200) goto smc_read::@5 -- vwum1_neq_vwuc1_then_la1 
    lda progress_row_bytes+1
    cmp #>$200
    bne __b5
    lda progress_row_bytes
    cmp #<$200
    bne __b5
    // smc_read::@6
    // gotoxy(x, ++y);
    // [966] smc_read::y#1 = ++ smc_read::y#10 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [967] gotoxy::y#20 = smc_read::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [968] call gotoxy
    // [602] phi from smc_read::@6 to gotoxy [phi:smc_read::@6->gotoxy]
    // [602] phi gotoxy::y#30 = gotoxy::y#20 [phi:smc_read::@6->gotoxy#0] -- register_copy 
    // [602] phi gotoxy::x#30 = PROGRESS_X [phi:smc_read::@6->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [969] phi from smc_read::@6 to smc_read::@5 [phi:smc_read::@6->smc_read::@5]
    // [969] phi smc_read::y#20 = smc_read::y#1 [phi:smc_read::@6->smc_read::@5#0] -- register_copy 
    // [969] phi smc_read::progress_row_bytes#4 = 0 [phi:smc_read::@6->smc_read::@5#1] -- vwum1=vbuc1 
    lda #<0
    sta progress_row_bytes
    sta progress_row_bytes+1
    // [969] phi from smc_read::@22 to smc_read::@5 [phi:smc_read::@22->smc_read::@5]
    // [969] phi smc_read::y#20 = smc_read::y#10 [phi:smc_read::@22->smc_read::@5#0] -- register_copy 
    // [969] phi smc_read::progress_row_bytes#4 = smc_read::progress_row_bytes#10 [phi:smc_read::@22->smc_read::@5#1] -- register_copy 
    // smc_read::@5
  __b5:
    // cputc('.')
    // [970] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [971] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // ram_address += smc_file_read
    // [973] smc_read::ram_address#1 = smc_read::ram_address#10 + smc_read::smc_file_read#1 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z ram_address
    adc smc_file_read
    sta.z ram_address
    lda.z ram_address+1
    adc smc_file_read+1
    sta.z ram_address+1
    // smc_file_size += smc_file_read
    // [974] smc_read::smc_file_size#1 = smc_read::smc_file_size#11 + smc_read::smc_file_read#1 -- vwum1=vwum1_plus_vwum2 
    clc
    lda smc_file_size
    adc smc_file_read
    sta smc_file_size
    lda smc_file_size+1
    adc smc_file_read+1
    sta smc_file_size+1
    // progress_row_bytes += smc_file_read
    // [975] smc_read::progress_row_bytes#1 = smc_read::progress_row_bytes#4 + smc_read::smc_file_read#1 -- vwum1=vwum1_plus_vwum2 
    clc
    lda progress_row_bytes
    adc smc_file_read
    sta progress_row_bytes
    lda progress_row_bytes+1
    adc smc_file_read+1
    sta progress_row_bytes+1
    // [930] phi from smc_read::@5 to smc_read::@2 [phi:smc_read::@5->smc_read::@2]
    // [930] phi smc_read::y#10 = smc_read::y#20 [phi:smc_read::@5->smc_read::@2#0] -- register_copy 
    // [930] phi smc_read::progress_row_bytes#10 = smc_read::progress_row_bytes#1 [phi:smc_read::@5->smc_read::@2#1] -- register_copy 
    // [930] phi smc_read::smc_file_size#11 = smc_read::smc_file_size#1 [phi:smc_read::@5->smc_read::@2#2] -- register_copy 
    // [930] phi smc_read::ram_address#10 = smc_read::ram_address#1 [phi:smc_read::@5->smc_read::@2#3] -- register_copy 
    jmp __b2
  .segment Data
    info_text: .text "Reading SMC.BIN ... (.) data, ( ) empty"
    .byte 0
    path: .text "SMC.BIN"
    .byte 0
    s: .text "Reading SMC.BIN:"
    .byte 0
    return: .word 0
    .label smc_file_read = fgets.read
    .label smc_file_size = return
    /// Holds the amount of bytes actually read in the memory to be flashed.
    progress_row_bytes: .word 0
    y: .byte 0
}
.segment Code
  // display_info_line
// void display_info_line(__zp($5e) char *info_text)
display_info_line: {
    .label info_text = $5e
    // unsigned char x = wherex()
    // [977] call wherex
    jsr wherex
    // [978] wherex::return#3 = wherex::return#0 -- vbum1=vbum2 
    lda wherex.return
    sta wherex.return_1
    // display_info_line::@1
    // [979] display_info_line::x#0 = wherex::return#3
    // unsigned char y = wherey()
    // [980] call wherey
    jsr wherey
    // [981] wherey::return#3 = wherey::return#0 -- vbum1=vbum2 
    lda wherey.return
    sta wherey.return_1
    // display_info_line::@2
    // [982] display_info_line::y#0 = wherey::return#3
    // gotoxy(2, PROGRESS_Y-3)
    // [983] call gotoxy
    // [602] phi from display_info_line::@2 to gotoxy [phi:display_info_line::@2->gotoxy]
    // [602] phi gotoxy::y#30 = PROGRESS_Y-3 [phi:display_info_line::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-3
    sta gotoxy.y
    // [602] phi gotoxy::x#30 = 2 [phi:display_info_line::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // display_info_line::@3
    // printf("%-65s", info_text)
    // [984] printf_string::str#2 = display_info_line::info_text#19 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [985] call printf_string
    // [1238] phi from display_info_line::@3 to printf_string [phi:display_info_line::@3->printf_string]
    // [1238] phi printf_string::putc#18 = &cputc [phi:display_info_line::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1238] phi printf_string::str#18 = printf_string::str#2 [phi:display_info_line::@3->printf_string#1] -- register_copy 
    // [1238] phi printf_string::format_justify_left#18 = 1 [phi:display_info_line::@3->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1238] phi printf_string::format_min_length#18 = $41 [phi:display_info_line::@3->printf_string#3] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_line::@4
    // gotoxy(x, y)
    // [986] gotoxy::x#12 = display_info_line::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [987] gotoxy::y#12 = display_info_line::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [988] call gotoxy
    // [602] phi from display_info_line::@4 to gotoxy [phi:display_info_line::@4->gotoxy]
    // [602] phi gotoxy::y#30 = gotoxy::y#12 [phi:display_info_line::@4->gotoxy#0] -- register_copy 
    // [602] phi gotoxy::x#30 = gotoxy::x#12 [phi:display_info_line::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_line::@return
    // }
    // [989] return 
    rts
  .segment Data
    .label x = wherex.return_1
    .label y = wherey.return_1
}
.segment Code
  // flash_smc
// __mem() unsigned int flash_smc(char x, __zp($75) char y, char w, __zp($b5) unsigned int smc_bytes_total, char b, unsigned int smc_row_total, __zp($3b) char *smc_ram_ptr)
flash_smc: {
    .const smc_row_total = $200
    .label flash_smc__26 = $66
    .label flash_smc__27 = $66
    .label smc_ram_ptr = $3b
    .label y = $75
    .label smc_bytes_total = $b5
    // display_info_progress("To start the SMC update, do the below action ...")
    // [991] call display_info_progress
  /*
   ; Send start bootloader command
    ldx #I2C_ADDR
    ldy #$8f
    lda #$31
    jsr I2C_WRITE

    ; Prompt the user to activate bootloader within 20 seconds, and check if activated
    print str_activate_countdown
    ldx #20
:   jsr util_stepdown
    cpx #0
    beq :+
    
    ldx #I2C_ADDR
    ldy #$8e
    jsr I2C_READ
    cmp #0
    beq :+
    jsr util_delay
    ldx #0
    bra :-

    ; Wait another 5 seconds to ensure bootloader is ready
:   print str_activate_wait
    ldx #5
    jsr util_countdown

    ; Check if bootloader activated
    ldx #I2C_ADDR
    ldy #$8e
    jsr I2C_READ
    cmp #0
    beq :+

    print str_bootloader_not_activated
    cli
    rts
*/
    // [711] phi from flash_smc to display_info_progress [phi:flash_smc->display_info_progress]
    // [711] phi display_info_progress::info_text#14 = flash_smc::info_text [phi:flash_smc->display_info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_progress.info_text
    lda #>info_text
    sta.z display_info_progress.info_text+1
    jsr display_info_progress
    // flash_smc::@25
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [992] flash_smc::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [993] flash_smc::cx16_k_i2c_write_byte1_offset = $8f -- vbum1=vbuc1 
    lda #$8f
    sta cx16_k_i2c_write_byte1_offset
    // [994] flash_smc::cx16_k_i2c_write_byte1_value = $31 -- vbum1=vbuc1 
    lda #$31
    sta cx16_k_i2c_write_byte1_value
    // flash_smc::cx16_k_i2c_write_byte1
    // unsigned char result
    // [995] flash_smc::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
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
    // [997] flash_smc::cx16_k_i2c_write_byte1_return#0 = flash_smc::cx16_k_i2c_write_byte1_result -- vbum1=vbum2 
    lda cx16_k_i2c_write_byte1_result
    sta cx16_k_i2c_write_byte1_return
    // flash_smc::cx16_k_i2c_write_byte1_@return
    // }
    // [998] flash_smc::cx16_k_i2c_write_byte1_return#1 = flash_smc::cx16_k_i2c_write_byte1_return#0
    // flash_smc::@22
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [999] flash_smc::smc_bootloader_start#0 = flash_smc::cx16_k_i2c_write_byte1_return#1
    // if(smc_bootloader_start)
    // [1000] if(0==flash_smc::smc_bootloader_start#0) goto flash_smc::@3 -- 0_eq_vbum1_then_la1 
    lda smc_bootloader_start
    beq __b6
    // [1001] phi from flash_smc::@22 to flash_smc::@2 [phi:flash_smc::@22->flash_smc::@2]
    // flash_smc::@2
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1002] call snprintf_init
    jsr snprintf_init
    // [1003] phi from flash_smc::@2 to flash_smc::@26 [phi:flash_smc::@2->flash_smc::@26]
    // flash_smc::@26
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1004] call printf_str
    // [745] phi from flash_smc::@26 to printf_str [phi:flash_smc::@26->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:flash_smc::@26->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = flash_smc::s [phi:flash_smc::@26->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@27
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1005] printf_uchar::uvalue#1 = flash_smc::smc_bootloader_start#0
    // [1006] call printf_uchar
    // [1162] phi from flash_smc::@27 to printf_uchar [phi:flash_smc::@27->printf_uchar]
    // [1162] phi printf_uchar::format_zero_padding#11 = 0 [phi:flash_smc::@27->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1162] phi printf_uchar::format_min_length#11 = 0 [phi:flash_smc::@27->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1162] phi printf_uchar::putc#11 = &snputc [phi:flash_smc::@27->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1162] phi printf_uchar::format_radix#11 = HEXADECIMAL [phi:flash_smc::@27->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1162] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#1 [phi:flash_smc::@27->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // flash_smc::@28
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1007] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1008] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_line(info_text)
    // [1010] call display_info_line
    // [976] phi from flash_smc::@28 to display_info_line [phi:flash_smc::@28->display_info_line]
    // [976] phi display_info_line::info_text#19 = info_text [phi:flash_smc::@28->display_info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_line.info_text
    lda #>@info_text
    sta.z display_info_line.info_text+1
    jsr display_info_line
    // flash_smc::@29
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [1011] flash_smc::cx16_k_i2c_write_byte2_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte2_device
    // [1012] flash_smc::cx16_k_i2c_write_byte2_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte2_offset
    // [1013] flash_smc::cx16_k_i2c_write_byte2_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte2_value
    // flash_smc::cx16_k_i2c_write_byte2
    // unsigned char result
    // [1014] flash_smc::cx16_k_i2c_write_byte2_result = 0 -- vbum1=vbuc1 
    sta cx16_k_i2c_write_byte2_result
    // asm
    // asm { ldxdevice ldyoffset ldavalue stzresult jsrCX16_I2C_WRITE_BYTE rolresult  }
    ldx cx16_k_i2c_write_byte2_device
    ldy cx16_k_i2c_write_byte2_offset
    lda cx16_k_i2c_write_byte2_value
    stz cx16_k_i2c_write_byte2_result
    jsr CX16_I2C_WRITE_BYTE
    rol cx16_k_i2c_write_byte2_result
    // [1016] phi from flash_smc::@47 flash_smc::@59 flash_smc::cx16_k_i2c_write_byte2 to flash_smc::@return [phi:flash_smc::@47/flash_smc::@59/flash_smc::cx16_k_i2c_write_byte2->flash_smc::@return]
  __b2:
    // [1016] phi flash_smc::return#1 = 0 [phi:flash_smc::@47/flash_smc::@59/flash_smc::cx16_k_i2c_write_byte2->flash_smc::@return#0] -- vwum1=vbuc1 
    lda #<0
    sta return
    sta return+1
    // flash_smc::@return
    // }
    // [1017] return 
    rts
    // [1018] phi from flash_smc::@22 to flash_smc::@3 [phi:flash_smc::@22->flash_smc::@3]
  __b6:
    // [1018] phi flash_smc::smc_bootloader_activation_countdown#10 = $3c [phi:flash_smc::@22->flash_smc::@3#0] -- vbum1=vbuc1 
    lda #$3c
    sta smc_bootloader_activation_countdown
    // flash_smc::@3
  __b3:
    // while(smc_bootloader_activation_countdown)
    // [1019] if(0!=flash_smc::smc_bootloader_activation_countdown#10) goto flash_smc::@4 -- 0_neq_vbum1_then_la1 
    lda smc_bootloader_activation_countdown
    beq !__b4+
    jmp __b4
  !__b4:
    // [1020] phi from flash_smc::@3 flash_smc::@30 to flash_smc::@7 [phi:flash_smc::@3/flash_smc::@30->flash_smc::@7]
  __b9:
    // [1020] phi flash_smc::smc_bootloader_activation_countdown#12 = $a [phi:flash_smc::@3/flash_smc::@30->flash_smc::@7#0] -- vbum1=vbuc1 
    lda #$a
    sta smc_bootloader_activation_countdown_1
    // flash_smc::@7
  __b7:
    // while(smc_bootloader_activation_countdown)
    // [1021] if(0!=flash_smc::smc_bootloader_activation_countdown#12) goto flash_smc::@8 -- 0_neq_vbum1_then_la1 
    lda smc_bootloader_activation_countdown_1
    beq !__b8+
    jmp __b8
  !__b8:
    // flash_smc::@9
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1022] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1023] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [1024] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [1025] cx16_k_i2c_read_byte::return#3 = cx16_k_i2c_read_byte::return#1
    // flash_smc::@42
    // smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1026] flash_smc::smc_bootloader_not_activated#1 = cx16_k_i2c_read_byte::return#3
    // if(smc_bootloader_not_activated)
    // [1027] if(0==flash_smc::smc_bootloader_not_activated#1) goto flash_smc::@1 -- 0_eq_vwum1_then_la1 
    lda smc_bootloader_not_activated
    ora smc_bootloader_not_activated+1
    beq __b1
    // [1028] phi from flash_smc::@42 to flash_smc::@10 [phi:flash_smc::@42->flash_smc::@10]
    // flash_smc::@10
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1029] call snprintf_init
    jsr snprintf_init
    // [1030] phi from flash_smc::@10 to flash_smc::@45 [phi:flash_smc::@10->flash_smc::@45]
    // flash_smc::@45
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1031] call printf_str
    // [745] phi from flash_smc::@45 to printf_str [phi:flash_smc::@45->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:flash_smc::@45->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = flash_smc::s5 [phi:flash_smc::@45->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@46
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1032] printf_uint::uvalue#5 = flash_smc::smc_bootloader_not_activated#1
    // [1033] call printf_uint
    // [754] phi from flash_smc::@46 to printf_uint [phi:flash_smc::@46->printf_uint]
    // [754] phi printf_uint::format_zero_padding#16 = 0 [phi:flash_smc::@46->printf_uint#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uint.format_zero_padding
    // [754] phi printf_uint::format_min_length#16 = 0 [phi:flash_smc::@46->printf_uint#1] -- vbum1=vbuc1 
    sta printf_uint.format_min_length
    // [754] phi printf_uint::putc#16 = &snputc [phi:flash_smc::@46->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [754] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:flash_smc::@46->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [754] phi printf_uint::uvalue#16 = printf_uint::uvalue#5 [phi:flash_smc::@46->printf_uint#4] -- register_copy 
    jsr printf_uint
    // flash_smc::@47
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1034] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1035] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_line(info_text)
    // [1037] call display_info_line
    // [976] phi from flash_smc::@47 to display_info_line [phi:flash_smc::@47->display_info_line]
    // [976] phi display_info_line::info_text#19 = info_text [phi:flash_smc::@47->display_info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_line.info_text
    lda #>@info_text
    sta.z display_info_line.info_text+1
    jsr display_info_line
    jmp __b2
    // [1038] phi from flash_smc::@42 to flash_smc::@1 [phi:flash_smc::@42->flash_smc::@1]
    // flash_smc::@1
  __b1:
    // display_info_progress("Updating SMC firmware ... (+) Updated")
    // [1039] call display_info_progress
    // [711] phi from flash_smc::@1 to display_info_progress [phi:flash_smc::@1->display_info_progress]
    // [711] phi display_info_progress::info_text#14 = flash_smc::info_text1 [phi:flash_smc::@1->display_info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_progress.info_text
    lda #>info_text1
    sta.z display_info_progress.info_text+1
    jsr display_info_progress
    // [1040] phi from flash_smc::@1 to flash_smc::@43 [phi:flash_smc::@1->flash_smc::@43]
    // flash_smc::@43
    // textcolor(WHITE)
    // [1041] call textcolor
    // [584] phi from flash_smc::@43 to textcolor [phi:flash_smc::@43->textcolor]
    // [584] phi textcolor::color#18 = WHITE [phi:flash_smc::@43->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [1042] phi from flash_smc::@43 to flash_smc::@44 [phi:flash_smc::@43->flash_smc::@44]
    // flash_smc::@44
    // gotoxy(x, y)
    // [1043] call gotoxy
    // [602] phi from flash_smc::@44 to gotoxy [phi:flash_smc::@44->gotoxy]
    // [602] phi gotoxy::y#30 = PROGRESS_Y [phi:flash_smc::@44->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [602] phi gotoxy::x#30 = PROGRESS_X [phi:flash_smc::@44->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1044] phi from flash_smc::@44 to flash_smc::@11 [phi:flash_smc::@44->flash_smc::@11]
    // [1044] phi flash_smc::y#31 = PROGRESS_Y [phi:flash_smc::@44->flash_smc::@11#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // [1044] phi flash_smc::smc_attempts_total#21 = 0 [phi:flash_smc::@44->flash_smc::@11#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_attempts_total
    sta smc_attempts_total+1
    // [1044] phi flash_smc::smc_row_bytes#14 = 0 [phi:flash_smc::@44->flash_smc::@11#2] -- vwum1=vwuc1 
    sta smc_row_bytes
    sta smc_row_bytes+1
    // [1044] phi flash_smc::smc_ram_ptr#13 = (char *)$6000 [phi:flash_smc::@44->flash_smc::@11#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z smc_ram_ptr
    lda #>$6000
    sta.z smc_ram_ptr+1
    // [1044] phi flash_smc::smc_bytes_flashed#16 = 0 [phi:flash_smc::@44->flash_smc::@11#4] -- vwum1=vwuc1 
    lda #<0
    sta smc_bytes_flashed
    sta smc_bytes_flashed+1
    // [1044] phi from flash_smc::@13 to flash_smc::@11 [phi:flash_smc::@13->flash_smc::@11]
    // [1044] phi flash_smc::y#31 = flash_smc::y#20 [phi:flash_smc::@13->flash_smc::@11#0] -- register_copy 
    // [1044] phi flash_smc::smc_attempts_total#21 = flash_smc::smc_attempts_total#17 [phi:flash_smc::@13->flash_smc::@11#1] -- register_copy 
    // [1044] phi flash_smc::smc_row_bytes#14 = flash_smc::smc_row_bytes#10 [phi:flash_smc::@13->flash_smc::@11#2] -- register_copy 
    // [1044] phi flash_smc::smc_ram_ptr#13 = flash_smc::smc_ram_ptr#10 [phi:flash_smc::@13->flash_smc::@11#3] -- register_copy 
    // [1044] phi flash_smc::smc_bytes_flashed#16 = flash_smc::smc_bytes_flashed#11 [phi:flash_smc::@13->flash_smc::@11#4] -- register_copy 
    // flash_smc::@11
  __b11:
    // while(smc_bytes_flashed < smc_bytes_total)
    // [1045] if(flash_smc::smc_bytes_flashed#16<flash_smc::smc_bytes_total#0) goto flash_smc::@12 -- vwum1_lt_vwuz2_then_la1 
    lda smc_bytes_flashed+1
    cmp.z smc_bytes_total+1
    bcc __b10
    bne !+
    lda smc_bytes_flashed
    cmp.z smc_bytes_total
    bcc __b10
  !:
    // [1016] phi from flash_smc::@11 to flash_smc::@return [phi:flash_smc::@11->flash_smc::@return]
    // [1016] phi flash_smc::return#1 = flash_smc::smc_bytes_flashed#16 [phi:flash_smc::@11->flash_smc::@return#0] -- register_copy 
    rts
    // [1046] phi from flash_smc::@11 to flash_smc::@12 [phi:flash_smc::@11->flash_smc::@12]
  __b10:
    // [1046] phi flash_smc::y#20 = flash_smc::y#31 [phi:flash_smc::@11->flash_smc::@12#0] -- register_copy 
    // [1046] phi flash_smc::smc_attempts_total#17 = flash_smc::smc_attempts_total#21 [phi:flash_smc::@11->flash_smc::@12#1] -- register_copy 
    // [1046] phi flash_smc::smc_row_bytes#10 = flash_smc::smc_row_bytes#14 [phi:flash_smc::@11->flash_smc::@12#2] -- register_copy 
    // [1046] phi flash_smc::smc_ram_ptr#10 = flash_smc::smc_ram_ptr#13 [phi:flash_smc::@11->flash_smc::@12#3] -- register_copy 
    // [1046] phi flash_smc::smc_bytes_flashed#11 = flash_smc::smc_bytes_flashed#16 [phi:flash_smc::@11->flash_smc::@12#4] -- register_copy 
    // [1046] phi flash_smc::smc_attempts_flashed#19 = 0 [phi:flash_smc::@11->flash_smc::@12#5] -- vbum1=vbuc1 
    lda #0
    sta smc_attempts_flashed
    // [1046] phi flash_smc::smc_package_committed#2 = 0 [phi:flash_smc::@11->flash_smc::@12#6] -- vbum1=vbuc1 
    sta smc_package_committed
    // flash_smc::@12
  __b12:
    // while(!smc_package_committed && smc_attempts_flashed < 10)
    // [1047] if(0!=flash_smc::smc_package_committed#2) goto flash_smc::@13 -- 0_neq_vbum1_then_la1 
    lda smc_package_committed
    bne __b13
    // flash_smc::@60
    // [1048] if(flash_smc::smc_attempts_flashed#19<$a) goto flash_smc::@14 -- vbum1_lt_vbuc1_then_la1 
    lda smc_attempts_flashed
    cmp #$a
    bcc __b16
    // flash_smc::@13
  __b13:
    // if(smc_attempts_flashed >= 10)
    // [1049] if(flash_smc::smc_attempts_flashed#19<$a) goto flash_smc::@11 -- vbum1_lt_vbuc1_then_la1 
    lda smc_attempts_flashed
    cmp #$a
    bcc __b11
    // [1050] phi from flash_smc::@13 to flash_smc::@21 [phi:flash_smc::@13->flash_smc::@21]
    // flash_smc::@21
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1051] call snprintf_init
    jsr snprintf_init
    // [1052] phi from flash_smc::@21 to flash_smc::@57 [phi:flash_smc::@21->flash_smc::@57]
    // flash_smc::@57
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1053] call printf_str
    // [745] phi from flash_smc::@57 to printf_str [phi:flash_smc::@57->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:flash_smc::@57->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = flash_smc::s10 [phi:flash_smc::@57->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@58
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1054] printf_uint::uvalue#9 = flash_smc::smc_bytes_flashed#11 -- vwum1=vwum2 
    lda smc_bytes_flashed
    sta printf_uint.uvalue
    lda smc_bytes_flashed+1
    sta printf_uint.uvalue+1
    // [1055] call printf_uint
    // [754] phi from flash_smc::@58 to printf_uint [phi:flash_smc::@58->printf_uint]
    // [754] phi printf_uint::format_zero_padding#16 = 1 [phi:flash_smc::@58->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [754] phi printf_uint::format_min_length#16 = 4 [phi:flash_smc::@58->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [754] phi printf_uint::putc#16 = &snputc [phi:flash_smc::@58->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [754] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:flash_smc::@58->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [754] phi printf_uint::uvalue#16 = printf_uint::uvalue#9 [phi:flash_smc::@58->printf_uint#4] -- register_copy 
    jsr printf_uint
    // flash_smc::@59
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1056] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1057] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_line(info_text)
    // [1059] call display_info_line
    // [976] phi from flash_smc::@59 to display_info_line [phi:flash_smc::@59->display_info_line]
    // [976] phi display_info_line::info_text#19 = info_text [phi:flash_smc::@59->display_info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_line.info_text
    lda #>@info_text
    sta.z display_info_line.info_text+1
    jsr display_info_line
    jmp __b2
    // [1060] phi from flash_smc::@60 to flash_smc::@14 [phi:flash_smc::@60->flash_smc::@14]
  __b16:
    // [1060] phi flash_smc::smc_bytes_checksum#2 = 0 [phi:flash_smc::@60->flash_smc::@14#0] -- vbum1=vbuc1 
    lda #0
    sta smc_bytes_checksum
    // [1060] phi flash_smc::smc_ram_ptr#12 = flash_smc::smc_ram_ptr#10 [phi:flash_smc::@60->flash_smc::@14#1] -- register_copy 
    // [1060] phi flash_smc::smc_package_flashed#2 = 0 [phi:flash_smc::@60->flash_smc::@14#2] -- vwum1=vwuc1 
    sta smc_package_flashed
    sta smc_package_flashed+1
    // flash_smc::@14
  __b14:
    // while(smc_package_flashed < 8)
    // [1061] if(flash_smc::smc_package_flashed#2<8) goto flash_smc::@15 -- vwum1_lt_vbuc1_then_la1 
    lda smc_package_flashed+1
    bne !+
    lda smc_package_flashed
    cmp #8
    bcs !__b15+
    jmp __b15
  !__b15:
  !:
    // flash_smc::@16
    // smc_bytes_checksum ^ 0xFF
    // [1062] flash_smc::$26 = flash_smc::smc_bytes_checksum#2 ^ $ff -- vbuz1=vbum2_bxor_vbuc1 
    lda #$ff
    eor smc_bytes_checksum
    sta.z flash_smc__26
    // (smc_bytes_checksum ^ 0xFF)+1
    // [1063] flash_smc::$27 = flash_smc::$26 + 1 -- vbuz1=vbuz1_plus_1 
    inc.z flash_smc__27
    // unsigned char smc_checksum_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, (smc_bytes_checksum ^ 0xFF)+1)
    // [1064] flash_smc::cx16_k_i2c_write_byte4_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte4_device
    // [1065] flash_smc::cx16_k_i2c_write_byte4_offset = $80 -- vbum1=vbuc1 
    lda #$80
    sta cx16_k_i2c_write_byte4_offset
    // [1066] flash_smc::cx16_k_i2c_write_byte4_value = flash_smc::$27 -- vbum1=vbuz2 
    lda.z flash_smc__27
    sta cx16_k_i2c_write_byte4_value
    // flash_smc::cx16_k_i2c_write_byte4
    // unsigned char result
    // [1067] flash_smc::cx16_k_i2c_write_byte4_result = 0 -- vbum1=vbuc1 
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
    // flash_smc::@24
    // unsigned int smc_commit_result = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_COMMIT)
    // [1069] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1070] cx16_k_i2c_read_byte::offset = $81 -- vbum1=vbuc1 
    lda #$81
    sta cx16_k_i2c_read_byte.offset
    // [1071] call cx16_k_i2c_read_byte
    // Now send the commit command.
    jsr cx16_k_i2c_read_byte
    // [1072] cx16_k_i2c_read_byte::return#4 = cx16_k_i2c_read_byte::return#1
    // flash_smc::@48
    // [1073] flash_smc::smc_commit_result#0 = cx16_k_i2c_read_byte::return#4
    // if(smc_commit_result == 1)
    // [1074] if(flash_smc::smc_commit_result#0==1) goto flash_smc::@18 -- vwum1_eq_vbuc1_then_la1 
    lda smc_commit_result+1
    bne !+
    lda smc_commit_result
    cmp #1
    beq __b18
  !:
    // flash_smc::@17
    // smc_ram_ptr -= 8
    // [1075] flash_smc::smc_ram_ptr#1 = flash_smc::smc_ram_ptr#12 - 8 -- pbuz1=pbuz1_minus_vbuc1 
    sec
    lda.z smc_ram_ptr
    sbc #8
    sta.z smc_ram_ptr
    lda.z smc_ram_ptr+1
    sbc #0
    sta.z smc_ram_ptr+1
    // smc_attempts_flashed++;
    // [1076] flash_smc::smc_attempts_flashed#1 = ++ flash_smc::smc_attempts_flashed#19 -- vbum1=_inc_vbum1 
    inc smc_attempts_flashed
    // [1046] phi from flash_smc::@17 to flash_smc::@12 [phi:flash_smc::@17->flash_smc::@12]
    // [1046] phi flash_smc::y#20 = flash_smc::y#20 [phi:flash_smc::@17->flash_smc::@12#0] -- register_copy 
    // [1046] phi flash_smc::smc_attempts_total#17 = flash_smc::smc_attempts_total#17 [phi:flash_smc::@17->flash_smc::@12#1] -- register_copy 
    // [1046] phi flash_smc::smc_row_bytes#10 = flash_smc::smc_row_bytes#10 [phi:flash_smc::@17->flash_smc::@12#2] -- register_copy 
    // [1046] phi flash_smc::smc_ram_ptr#10 = flash_smc::smc_ram_ptr#1 [phi:flash_smc::@17->flash_smc::@12#3] -- register_copy 
    // [1046] phi flash_smc::smc_bytes_flashed#11 = flash_smc::smc_bytes_flashed#11 [phi:flash_smc::@17->flash_smc::@12#4] -- register_copy 
    // [1046] phi flash_smc::smc_attempts_flashed#19 = flash_smc::smc_attempts_flashed#1 [phi:flash_smc::@17->flash_smc::@12#5] -- register_copy 
    // [1046] phi flash_smc::smc_package_committed#2 = flash_smc::smc_package_committed#2 [phi:flash_smc::@17->flash_smc::@12#6] -- register_copy 
    jmp __b12
    // flash_smc::@18
  __b18:
    // if (smc_row_bytes == smc_row_total)
    // [1077] if(flash_smc::smc_row_bytes#10!=flash_smc::smc_row_total#0) goto flash_smc::@19 -- vwum1_neq_vwuc1_then_la1 
    lda smc_row_bytes+1
    cmp #>smc_row_total
    bne __b19
    lda smc_row_bytes
    cmp #<smc_row_total
    bne __b19
    // flash_smc::@20
    // gotoxy(x, ++y);
    // [1078] flash_smc::y#0 = ++ flash_smc::y#20 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [1079] gotoxy::y#22 = flash_smc::y#0 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [1080] call gotoxy
    // [602] phi from flash_smc::@20 to gotoxy [phi:flash_smc::@20->gotoxy]
    // [602] phi gotoxy::y#30 = gotoxy::y#22 [phi:flash_smc::@20->gotoxy#0] -- register_copy 
    // [602] phi gotoxy::x#30 = PROGRESS_X [phi:flash_smc::@20->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1081] phi from flash_smc::@20 to flash_smc::@19 [phi:flash_smc::@20->flash_smc::@19]
    // [1081] phi flash_smc::y#33 = flash_smc::y#0 [phi:flash_smc::@20->flash_smc::@19#0] -- register_copy 
    // [1081] phi flash_smc::smc_row_bytes#4 = 0 [phi:flash_smc::@20->flash_smc::@19#1] -- vwum1=vbuc1 
    lda #<0
    sta smc_row_bytes
    sta smc_row_bytes+1
    // [1081] phi from flash_smc::@18 to flash_smc::@19 [phi:flash_smc::@18->flash_smc::@19]
    // [1081] phi flash_smc::y#33 = flash_smc::y#20 [phi:flash_smc::@18->flash_smc::@19#0] -- register_copy 
    // [1081] phi flash_smc::smc_row_bytes#4 = flash_smc::smc_row_bytes#10 [phi:flash_smc::@18->flash_smc::@19#1] -- register_copy 
    // flash_smc::@19
  __b19:
    // cputc('+')
    // [1082] stackpush(char) = '+' -- _stackpushbyte_=vbuc1 
    lda #'+'
    pha
    // [1083] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_bytes_flashed += 8
    // [1085] flash_smc::smc_bytes_flashed#1 = flash_smc::smc_bytes_flashed#11 + 8 -- vwum1=vwum1_plus_vbuc1 
    lda #8
    clc
    adc smc_bytes_flashed
    sta smc_bytes_flashed
    bcc !+
    inc smc_bytes_flashed+1
  !:
    // smc_row_bytes += 8
    // [1086] flash_smc::smc_row_bytes#1 = flash_smc::smc_row_bytes#4 + 8 -- vwum1=vwum1_plus_vbuc1 
    lda #8
    clc
    adc smc_row_bytes
    sta smc_row_bytes
    bcc !+
    inc smc_row_bytes+1
  !:
    // smc_attempts_total += smc_attempts_flashed
    // [1087] flash_smc::smc_attempts_total#1 = flash_smc::smc_attempts_total#17 + flash_smc::smc_attempts_flashed#19 -- vwum1=vwum1_plus_vbum2 
    lda smc_attempts_flashed
    clc
    adc smc_attempts_total
    sta smc_attempts_total
    bcc !+
    inc smc_attempts_total+1
  !:
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1088] call snprintf_init
    jsr snprintf_init
    // [1089] phi from flash_smc::@19 to flash_smc::@49 [phi:flash_smc::@19->flash_smc::@49]
    // flash_smc::@49
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1090] call printf_str
    // [745] phi from flash_smc::@49 to printf_str [phi:flash_smc::@49->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:flash_smc::@49->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = flash_smc::s6 [phi:flash_smc::@49->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@50
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1091] printf_uint::uvalue#6 = flash_smc::smc_bytes_flashed#1 -- vwum1=vwum2 
    lda smc_bytes_flashed
    sta printf_uint.uvalue
    lda smc_bytes_flashed+1
    sta printf_uint.uvalue+1
    // [1092] call printf_uint
    // [754] phi from flash_smc::@50 to printf_uint [phi:flash_smc::@50->printf_uint]
    // [754] phi printf_uint::format_zero_padding#16 = 1 [phi:flash_smc::@50->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [754] phi printf_uint::format_min_length#16 = 5 [phi:flash_smc::@50->printf_uint#1] -- vbum1=vbuc1 
    lda #5
    sta printf_uint.format_min_length
    // [754] phi printf_uint::putc#16 = &snputc [phi:flash_smc::@50->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [754] phi printf_uint::format_radix#16 = DECIMAL [phi:flash_smc::@50->printf_uint#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uint.format_radix
    // [754] phi printf_uint::uvalue#16 = printf_uint::uvalue#6 [phi:flash_smc::@50->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1093] phi from flash_smc::@50 to flash_smc::@51 [phi:flash_smc::@50->flash_smc::@51]
    // flash_smc::@51
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1094] call printf_str
    // [745] phi from flash_smc::@51 to printf_str [phi:flash_smc::@51->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:flash_smc::@51->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = flash_smc::s7 [phi:flash_smc::@51->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@52
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1095] printf_uint::uvalue#7 = flash_smc::smc_bytes_total#0 -- vwum1=vwuz2 
    lda.z smc_bytes_total
    sta printf_uint.uvalue
    lda.z smc_bytes_total+1
    sta printf_uint.uvalue+1
    // [1096] call printf_uint
    // [754] phi from flash_smc::@52 to printf_uint [phi:flash_smc::@52->printf_uint]
    // [754] phi printf_uint::format_zero_padding#16 = 1 [phi:flash_smc::@52->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [754] phi printf_uint::format_min_length#16 = 5 [phi:flash_smc::@52->printf_uint#1] -- vbum1=vbuc1 
    lda #5
    sta printf_uint.format_min_length
    // [754] phi printf_uint::putc#16 = &snputc [phi:flash_smc::@52->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [754] phi printf_uint::format_radix#16 = DECIMAL [phi:flash_smc::@52->printf_uint#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uint.format_radix
    // [754] phi printf_uint::uvalue#16 = printf_uint::uvalue#7 [phi:flash_smc::@52->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1097] phi from flash_smc::@52 to flash_smc::@53 [phi:flash_smc::@52->flash_smc::@53]
    // flash_smc::@53
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1098] call printf_str
    // [745] phi from flash_smc::@53 to printf_str [phi:flash_smc::@53->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:flash_smc::@53->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = flash_smc::s8 [phi:flash_smc::@53->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@54
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1099] printf_uint::uvalue#8 = flash_smc::smc_attempts_total#1 -- vwum1=vwum2 
    lda smc_attempts_total
    sta printf_uint.uvalue
    lda smc_attempts_total+1
    sta printf_uint.uvalue+1
    // [1100] call printf_uint
    // [754] phi from flash_smc::@54 to printf_uint [phi:flash_smc::@54->printf_uint]
    // [754] phi printf_uint::format_zero_padding#16 = 1 [phi:flash_smc::@54->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [754] phi printf_uint::format_min_length#16 = 2 [phi:flash_smc::@54->printf_uint#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uint.format_min_length
    // [754] phi printf_uint::putc#16 = &snputc [phi:flash_smc::@54->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [754] phi printf_uint::format_radix#16 = DECIMAL [phi:flash_smc::@54->printf_uint#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uint.format_radix
    // [754] phi printf_uint::uvalue#16 = printf_uint::uvalue#8 [phi:flash_smc::@54->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1101] phi from flash_smc::@54 to flash_smc::@55 [phi:flash_smc::@54->flash_smc::@55]
    // flash_smc::@55
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1102] call printf_str
    // [745] phi from flash_smc::@55 to printf_str [phi:flash_smc::@55->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:flash_smc::@55->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = flash_smc::s9 [phi:flash_smc::@55->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@56
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1103] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1104] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_line(info_text)
    // [1106] call display_info_line
    // [976] phi from flash_smc::@56 to display_info_line [phi:flash_smc::@56->display_info_line]
    // [976] phi display_info_line::info_text#19 = info_text [phi:flash_smc::@56->display_info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_line.info_text
    lda #>@info_text
    sta.z display_info_line.info_text+1
    jsr display_info_line
    // [1046] phi from flash_smc::@56 to flash_smc::@12 [phi:flash_smc::@56->flash_smc::@12]
    // [1046] phi flash_smc::y#20 = flash_smc::y#33 [phi:flash_smc::@56->flash_smc::@12#0] -- register_copy 
    // [1046] phi flash_smc::smc_attempts_total#17 = flash_smc::smc_attempts_total#1 [phi:flash_smc::@56->flash_smc::@12#1] -- register_copy 
    // [1046] phi flash_smc::smc_row_bytes#10 = flash_smc::smc_row_bytes#1 [phi:flash_smc::@56->flash_smc::@12#2] -- register_copy 
    // [1046] phi flash_smc::smc_ram_ptr#10 = flash_smc::smc_ram_ptr#12 [phi:flash_smc::@56->flash_smc::@12#3] -- register_copy 
    // [1046] phi flash_smc::smc_bytes_flashed#11 = flash_smc::smc_bytes_flashed#1 [phi:flash_smc::@56->flash_smc::@12#4] -- register_copy 
    // [1046] phi flash_smc::smc_attempts_flashed#19 = flash_smc::smc_attempts_flashed#19 [phi:flash_smc::@56->flash_smc::@12#5] -- register_copy 
    // [1046] phi flash_smc::smc_package_committed#2 = 1 [phi:flash_smc::@56->flash_smc::@12#6] -- vbum1=vbuc1 
    lda #1
    sta smc_package_committed
    jmp __b12
    // flash_smc::@15
  __b15:
    // unsigned char smc_byte_upload = *smc_ram_ptr
    // [1107] flash_smc::smc_byte_upload#0 = *flash_smc::smc_ram_ptr#12 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (smc_ram_ptr),y
    sta smc_byte_upload
    // smc_ram_ptr++;
    // [1108] flash_smc::smc_ram_ptr#0 = ++ flash_smc::smc_ram_ptr#12 -- pbuz1=_inc_pbuz1 
    inc.z smc_ram_ptr
    bne !+
    inc.z smc_ram_ptr+1
  !:
    // smc_bytes_checksum += smc_byte_upload
    // [1109] flash_smc::smc_bytes_checksum#1 = flash_smc::smc_bytes_checksum#2 + flash_smc::smc_byte_upload#0 -- vbum1=vbum1_plus_vbum2 
    lda smc_bytes_checksum
    clc
    adc smc_byte_upload
    sta smc_bytes_checksum
    // unsigned char smc_upload_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, smc_byte_upload)
    // [1110] flash_smc::cx16_k_i2c_write_byte3_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte3_device
    // [1111] flash_smc::cx16_k_i2c_write_byte3_offset = $80 -- vbum1=vbuc1 
    lda #$80
    sta cx16_k_i2c_write_byte3_offset
    // [1112] flash_smc::cx16_k_i2c_write_byte3_value = flash_smc::smc_byte_upload#0 -- vbum1=vbum2 
    lda smc_byte_upload
    sta cx16_k_i2c_write_byte3_value
    // flash_smc::cx16_k_i2c_write_byte3
    // unsigned char result
    // [1113] flash_smc::cx16_k_i2c_write_byte3_result = 0 -- vbum1=vbuc1 
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
    // flash_smc::@23
    // smc_package_flashed++;
    // [1115] flash_smc::smc_package_flashed#1 = ++ flash_smc::smc_package_flashed#2 -- vwum1=_inc_vwum1 
    inc smc_package_flashed
    bne !+
    inc smc_package_flashed+1
  !:
    // [1060] phi from flash_smc::@23 to flash_smc::@14 [phi:flash_smc::@23->flash_smc::@14]
    // [1060] phi flash_smc::smc_bytes_checksum#2 = flash_smc::smc_bytes_checksum#1 [phi:flash_smc::@23->flash_smc::@14#0] -- register_copy 
    // [1060] phi flash_smc::smc_ram_ptr#12 = flash_smc::smc_ram_ptr#0 [phi:flash_smc::@23->flash_smc::@14#1] -- register_copy 
    // [1060] phi flash_smc::smc_package_flashed#2 = flash_smc::smc_package_flashed#1 [phi:flash_smc::@23->flash_smc::@14#2] -- register_copy 
    jmp __b14
    // [1116] phi from flash_smc::@7 to flash_smc::@8 [phi:flash_smc::@7->flash_smc::@8]
    // flash_smc::@8
  __b8:
    // wait_moment()
    // [1117] call wait_moment
    // [1157] phi from flash_smc::@8 to wait_moment [phi:flash_smc::@8->wait_moment]
    jsr wait_moment
    // [1118] phi from flash_smc::@8 to flash_smc::@36 [phi:flash_smc::@8->flash_smc::@36]
    // flash_smc::@36
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1119] call snprintf_init
    jsr snprintf_init
    // [1120] phi from flash_smc::@36 to flash_smc::@37 [phi:flash_smc::@36->flash_smc::@37]
    // flash_smc::@37
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1121] call printf_str
    // [745] phi from flash_smc::@37 to printf_str [phi:flash_smc::@37->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:flash_smc::@37->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = flash_smc::s3 [phi:flash_smc::@37->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@38
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1122] printf_uchar::uvalue#3 = flash_smc::smc_bootloader_activation_countdown#12 -- vbum1=vbum2 
    lda smc_bootloader_activation_countdown_1
    sta printf_uchar.uvalue
    // [1123] call printf_uchar
    // [1162] phi from flash_smc::@38 to printf_uchar [phi:flash_smc::@38->printf_uchar]
    // [1162] phi printf_uchar::format_zero_padding#11 = 0 [phi:flash_smc::@38->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1162] phi printf_uchar::format_min_length#11 = 0 [phi:flash_smc::@38->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1162] phi printf_uchar::putc#11 = &snputc [phi:flash_smc::@38->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1162] phi printf_uchar::format_radix#11 = DECIMAL [phi:flash_smc::@38->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1162] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#3 [phi:flash_smc::@38->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1124] phi from flash_smc::@38 to flash_smc::@39 [phi:flash_smc::@38->flash_smc::@39]
    // flash_smc::@39
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1125] call printf_str
    // [745] phi from flash_smc::@39 to printf_str [phi:flash_smc::@39->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:flash_smc::@39->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = s7 [phi:flash_smc::@39->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s7
    sta.z printf_str.s
    lda #>@s7
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@40
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1126] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1127] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_line(info_text)
    // [1129] call display_info_line
    // [976] phi from flash_smc::@40 to display_info_line [phi:flash_smc::@40->display_info_line]
    // [976] phi display_info_line::info_text#19 = info_text [phi:flash_smc::@40->display_info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_line.info_text
    lda #>@info_text
    sta.z display_info_line.info_text+1
    jsr display_info_line
    // flash_smc::@41
    // smc_bootloader_activation_countdown--;
    // [1130] flash_smc::smc_bootloader_activation_countdown#3 = -- flash_smc::smc_bootloader_activation_countdown#12 -- vbum1=_dec_vbum1 
    dec smc_bootloader_activation_countdown_1
    // [1020] phi from flash_smc::@41 to flash_smc::@7 [phi:flash_smc::@41->flash_smc::@7]
    // [1020] phi flash_smc::smc_bootloader_activation_countdown#12 = flash_smc::smc_bootloader_activation_countdown#3 [phi:flash_smc::@41->flash_smc::@7#0] -- register_copy 
    jmp __b7
    // flash_smc::@4
  __b4:
    // unsigned int smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1131] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1132] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [1133] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [1134] cx16_k_i2c_read_byte::return#2 = cx16_k_i2c_read_byte::return#1
    // flash_smc::@30
    // [1135] flash_smc::smc_bootloader_not_activated1#0 = cx16_k_i2c_read_byte::return#2
    // if(smc_bootloader_not_activated)
    // [1136] if(0!=flash_smc::smc_bootloader_not_activated1#0) goto flash_smc::@5 -- 0_neq_vwum1_then_la1 
    lda smc_bootloader_not_activated1
    ora smc_bootloader_not_activated1+1
    bne __b5
    jmp __b9
    // [1137] phi from flash_smc::@30 to flash_smc::@5 [phi:flash_smc::@30->flash_smc::@5]
    // flash_smc::@5
  __b5:
    // wait_moment()
    // [1138] call wait_moment
    // [1157] phi from flash_smc::@5 to wait_moment [phi:flash_smc::@5->wait_moment]
    jsr wait_moment
    // [1139] phi from flash_smc::@5 to flash_smc::@31 [phi:flash_smc::@5->flash_smc::@31]
    // flash_smc::@31
    // sprintf(info_text, "Press POWER and RESET on the CX16 to start the SMC update (%u)!", smc_bootloader_activation_countdown)
    // [1140] call snprintf_init
    jsr snprintf_init
    // [1141] phi from flash_smc::@31 to flash_smc::@32 [phi:flash_smc::@31->flash_smc::@32]
    // flash_smc::@32
    // sprintf(info_text, "Press POWER and RESET on the CX16 to start the SMC update (%u)!", smc_bootloader_activation_countdown)
    // [1142] call printf_str
    // [745] phi from flash_smc::@32 to printf_str [phi:flash_smc::@32->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:flash_smc::@32->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = flash_smc::s1 [phi:flash_smc::@32->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@33
    // sprintf(info_text, "Press POWER and RESET on the CX16 to start the SMC update (%u)!", smc_bootloader_activation_countdown)
    // [1143] printf_uchar::uvalue#2 = flash_smc::smc_bootloader_activation_countdown#10 -- vbum1=vbum2 
    lda smc_bootloader_activation_countdown
    sta printf_uchar.uvalue
    // [1144] call printf_uchar
    // [1162] phi from flash_smc::@33 to printf_uchar [phi:flash_smc::@33->printf_uchar]
    // [1162] phi printf_uchar::format_zero_padding#11 = 0 [phi:flash_smc::@33->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1162] phi printf_uchar::format_min_length#11 = 0 [phi:flash_smc::@33->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1162] phi printf_uchar::putc#11 = &snputc [phi:flash_smc::@33->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1162] phi printf_uchar::format_radix#11 = DECIMAL [phi:flash_smc::@33->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1162] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#2 [phi:flash_smc::@33->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1145] phi from flash_smc::@33 to flash_smc::@34 [phi:flash_smc::@33->flash_smc::@34]
    // flash_smc::@34
    // sprintf(info_text, "Press POWER and RESET on the CX16 to start the SMC update (%u)!", smc_bootloader_activation_countdown)
    // [1146] call printf_str
    // [745] phi from flash_smc::@34 to printf_str [phi:flash_smc::@34->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:flash_smc::@34->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = flash_smc::s2 [phi:flash_smc::@34->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@35
    // sprintf(info_text, "Press POWER and RESET on the CX16 to start the SMC update (%u)!", smc_bootloader_activation_countdown)
    // [1147] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1148] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_line(info_text)
    // [1150] call display_info_line
    // [976] phi from flash_smc::@35 to display_info_line [phi:flash_smc::@35->display_info_line]
    // [976] phi display_info_line::info_text#19 = info_text [phi:flash_smc::@35->display_info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_line.info_text
    lda #>@info_text
    sta.z display_info_line.info_text+1
    jsr display_info_line
    // flash_smc::@6
    // smc_bootloader_activation_countdown--;
    // [1151] flash_smc::smc_bootloader_activation_countdown#2 = -- flash_smc::smc_bootloader_activation_countdown#10 -- vbum1=_dec_vbum1 
    dec smc_bootloader_activation_countdown
    // [1018] phi from flash_smc::@6 to flash_smc::@3 [phi:flash_smc::@6->flash_smc::@3]
    // [1018] phi flash_smc::smc_bootloader_activation_countdown#10 = flash_smc::smc_bootloader_activation_countdown#2 [phi:flash_smc::@6->flash_smc::@3#0] -- register_copy 
    jmp __b3
  .segment Data
    info_text: .text "To start the SMC update, do the below action ..."
    .byte 0
    s: .text "There was a problem starting the SMC bootloader: "
    .byte 0
    s1: .text "Press POWER and RESET on the CX16 to start the SMC update ("
    .byte 0
    s2: .text ")!"
    .byte 0
    s3: .text "Updating SMC in "
    .byte 0
    info_text1: .text "Updating SMC firmware ... (+) Updated"
    .byte 0
    s5: .text "There was a problem activating the SMC bootloader: "
    .byte 0
    s6: .text "Flashed "
    .byte 0
    s7: .text " of "
    .byte 0
    s8: .text " bytes in the SMC, with "
    .byte 0
    s9: .text " retries ..."
    .byte 0
    s10: .text "There were too many attempts trying to flash the SMC at location "
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
    .label cx16_k_i2c_write_byte1_return = printf_uchar.uvalue
    .label smc_bootloader_start = printf_uchar.uvalue
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
    smc_attempts_total: .word 0
    smc_package_committed: .byte 0
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
    // [1153] BRAM = system_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // system_reset::bank_set_brom1
    // BROM = bank
    // [1154] BROM = system_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // system_reset::@2
    // asm
    // asm { jmp($FFFC)  }
    jmp ($fffc)
    // [1156] phi from system_reset::@1 system_reset::@2 to system_reset::@1 [phi:system_reset::@1/system_reset::@2->system_reset::@1]
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
    // [1158] phi from wait_moment to wait_moment::@1 [phi:wait_moment->wait_moment::@1]
    // [1158] phi wait_moment::i#2 = $ffff [phi:wait_moment->wait_moment::@1#0] -- vwum1=vwuc1 
    lda #<$ffff
    sta i
    lda #>$ffff
    sta i+1
    // wait_moment::@1
  __b1:
    // for(unsigned int i=65535; i>0; i--)
    // [1159] if(wait_moment::i#2>0) goto wait_moment::@2 -- vwum1_gt_0_then_la1 
    lda i+1
    bne __b2
    lda i
    bne __b2
  !:
    // wait_moment::@return
    // }
    // [1160] return 
    rts
    // wait_moment::@2
  __b2:
    // for(unsigned int i=65535; i>0; i--)
    // [1161] wait_moment::i#1 = -- wait_moment::i#2 -- vwum1=_dec_vwum1 
    lda i
    bne !+
    dec i+1
  !:
    dec i
    // [1158] phi from wait_moment::@2 to wait_moment::@1 [phi:wait_moment::@2->wait_moment::@1]
    // [1158] phi wait_moment::i#2 = wait_moment::i#1 [phi:wait_moment::@2->wait_moment::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    i: .word 0
}
.segment Code
  // printf_uchar
// Print an unsigned char using a specific format
// void printf_uchar(__zp($6f) void (*putc)(char), __mem() char uvalue, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, __mem() char format_radix)
printf_uchar: {
    .label putc = $6f
    // printf_uchar::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1163] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // uctoa(uvalue, printf_buffer.digits, format.radix)
    // [1164] uctoa::value#1 = printf_uchar::uvalue#11
    // [1165] uctoa::radix#0 = printf_uchar::format_radix#11
    // [1166] call uctoa
    // Format number into buffer
    jsr uctoa
    // printf_uchar::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1167] printf_number_buffer::putc#2 = printf_uchar::putc#11
    // [1168] printf_number_buffer::buffer_sign#2 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [1169] printf_number_buffer::format_min_length#2 = printf_uchar::format_min_length#11
    // [1170] printf_number_buffer::format_zero_padding#2 = printf_uchar::format_zero_padding#11
    // [1171] call printf_number_buffer
  // Print using format
    // [1884] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [1884] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#2 [phi:printf_uchar::@2->printf_number_buffer#0] -- register_copy 
    // [1884] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#2 [phi:printf_uchar::@2->printf_number_buffer#1] -- register_copy 
    // [1884] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#2 [phi:printf_uchar::@2->printf_number_buffer#2] -- register_copy 
    // [1884] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#2 [phi:printf_uchar::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [1172] return 
    rts
  .segment Data
    uvalue: .byte 0
    format_radix: .byte 0
    .label format_min_length = printf_uint.format_min_length
    .label format_zero_padding = printf_uint.format_zero_padding
}
.segment Code
  // progress_text
// void progress_text(__zp($b7) char line, __zp($6f) char *text)
progress_text: {
    .label line = $b7
    .label text = $6f
    // cputsxy(PROGRESS_X, PROGRESS_Y+line, text)
    // [1174] cputsxy::y#0 = PROGRESS_Y + progress_text::line#4 -- vbum1=vbuc1_plus_vbuz2 
    lda #PROGRESS_Y
    clc
    adc.z line
    sta cputsxy.y
    // [1175] cputsxy::s#0 = progress_text::text#4
    // [1176] call cputsxy
    // [689] phi from progress_text to cputsxy [phi:progress_text->cputsxy]
    // [689] phi cputsxy::s#4 = cputsxy::s#0 [phi:progress_text->cputsxy#0] -- register_copy 
    // [689] phi cputsxy::y#4 = cputsxy::y#0 [phi:progress_text->cputsxy#1] -- register_copy 
    // [689] phi cputsxy::x#4 = PROGRESS_X [phi:progress_text->cputsxy#2] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta cputsxy.x
    jsr cputsxy
    // progress_text::@return
    // }
    // [1177] return 
    rts
}
  // smc_reset
smc_reset: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 0
    // smc_reset::bank_set_bram1
    // BRAM = bank
    // [1179] BRAM = smc_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // smc_reset::bank_set_brom1
    // BROM = bank
    // [1180] BROM = smc_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // smc_reset::@2
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [1181] smc_reset::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [1182] smc_reset::cx16_k_i2c_write_byte1_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte1_offset
    // [1183] smc_reset::cx16_k_i2c_write_byte1_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte1_value
    // smc_reset::cx16_k_i2c_write_byte1
    // unsigned char result
    // [1184] smc_reset::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
    sta cx16_k_i2c_write_byte1_result
    // asm
    // asm { ldxdevice ldyoffset ldavalue stzresult jsrCX16_I2C_WRITE_BYTE rolresult  }
    ldx cx16_k_i2c_write_byte1_device
    ldy cx16_k_i2c_write_byte1_offset
    lda cx16_k_i2c_write_byte1_value
    stz cx16_k_i2c_write_byte1_result
    jsr CX16_I2C_WRITE_BYTE
    rol cx16_k_i2c_write_byte1_result
    // [1186] phi from smc_reset::@1 smc_reset::cx16_k_i2c_write_byte1 to smc_reset::@1 [phi:smc_reset::@1/smc_reset::cx16_k_i2c_write_byte1->smc_reset::@1]
    // smc_reset::@1
  __b1:
    jmp __b1
  .segment Data
    cx16_k_i2c_write_byte1_device: .byte 0
    cx16_k_i2c_write_byte1_offset: .byte 0
    cx16_k_i2c_write_byte1_value: .byte 0
    cx16_k_i2c_write_byte1_result: .byte 0
}
.segment Code
  // info_rom
/**
 * @brief 
 * 
 * @param rom_chip 
 * @param info_status 
 * @param info_text 
 */
// void info_rom(__zp($b4) char rom_chip, __zp($57) char info_status, __zp($36) char *info_text)
info_rom: {
    .label info_rom__10 = $57
    .label info_rom__11 = $64
    .label info_rom__13 = $65
    .label rom_chip = $b4
    .label info_status = $57
    .label info_text = $36
    // unsigned char x = wherex()
    // [1188] call wherex
    jsr wherex
    // [1189] wherex::return#12 = wherex::return#0 -- vbum1=vbum2 
    lda wherex.return
    sta wherex.return_4
    // info_rom::@3
    // [1190] info_rom::x#0 = wherex::return#12
    // unsigned char y = wherey()
    // [1191] call wherey
    jsr wherey
    // [1192] wherey::return#12 = wherey::return#0 -- vbum1=vbum2 
    lda wherey.return
    sta wherey.return_4
    // info_rom::@4
    // [1193] info_rom::y#0 = wherey::return#12
    // status_rom[rom_chip] = info_status
    // [1194] status_rom[info_rom::rom_chip#16] = info_rom::info_status#16 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z info_status
    ldy.z rom_chip
    sta status_rom,y
    // print_rom_led(rom_chip, status_color[info_status])
    // [1195] print_rom_led::chip#1 = info_rom::rom_chip#16 -- vbuz1=vbuz2 
    tya
    sta.z print_rom_led.chip
    // [1196] print_rom_led::c#1 = status_color[info_rom::info_status#16] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z print_rom_led.c
    // [1197] call print_rom_led
    // [1963] phi from info_rom::@4 to print_rom_led [phi:info_rom::@4->print_rom_led]
    // [1963] phi print_rom_led::c#2 = print_rom_led::c#1 [phi:info_rom::@4->print_rom_led#0] -- register_copy 
    // [1963] phi print_rom_led::chip#2 = print_rom_led::chip#1 [phi:info_rom::@4->print_rom_led#1] -- register_copy 
    jsr print_rom_led
    // info_rom::@5
    // gotoxy(INFO_X, INFO_Y+rom_chip+2)
    // [1198] gotoxy::y#17 = info_rom::rom_chip#16 + $11+2 -- vbum1=vbuz2_plus_vbuc1 
    lda #$11+2
    clc
    adc.z rom_chip
    sta gotoxy.y
    // [1199] call gotoxy
    // [602] phi from info_rom::@5 to gotoxy [phi:info_rom::@5->gotoxy]
    // [602] phi gotoxy::y#30 = gotoxy::y#17 [phi:info_rom::@5->gotoxy#0] -- register_copy 
    // [602] phi gotoxy::x#30 = 4 [phi:info_rom::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.x
    jsr gotoxy
    // [1200] phi from info_rom::@5 to info_rom::@6 [phi:info_rom::@5->info_rom::@6]
    // info_rom::@6
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1201] call printf_str
    // [745] phi from info_rom::@6 to printf_str [phi:info_rom::@6->printf_str]
    // [745] phi printf_str::putc#71 = &cputc [phi:info_rom::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = info_rom::s [phi:info_rom::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@7
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1202] printf_uchar::uvalue#0 = info_rom::rom_chip#16 -- vbum1=vbuz2 
    lda.z rom_chip
    sta printf_uchar.uvalue
    // [1203] call printf_uchar
    // [1162] phi from info_rom::@7 to printf_uchar [phi:info_rom::@7->printf_uchar]
    // [1162] phi printf_uchar::format_zero_padding#11 = 0 [phi:info_rom::@7->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1162] phi printf_uchar::format_min_length#11 = 0 [phi:info_rom::@7->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1162] phi printf_uchar::putc#11 = &cputc [phi:info_rom::@7->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1162] phi printf_uchar::format_radix#11 = DECIMAL [phi:info_rom::@7->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1162] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#0 [phi:info_rom::@7->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1204] phi from info_rom::@7 to info_rom::@8 [phi:info_rom::@7->info_rom::@8]
    // info_rom::@8
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1205] call printf_str
    // [745] phi from info_rom::@8 to printf_str [phi:info_rom::@8->printf_str]
    // [745] phi printf_str::putc#71 = &cputc [phi:info_rom::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = s1 [phi:info_rom::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@9
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1206] info_rom::$10 = info_rom::info_status#16 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z info_rom__10
    // [1207] printf_string::str#7 = status_text[info_rom::$10] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z info_rom__10
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [1208] call printf_string
    // [1238] phi from info_rom::@9 to printf_string [phi:info_rom::@9->printf_string]
    // [1238] phi printf_string::putc#18 = &cputc [phi:info_rom::@9->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1238] phi printf_string::str#18 = printf_string::str#7 [phi:info_rom::@9->printf_string#1] -- register_copy 
    // [1238] phi printf_string::format_justify_left#18 = 1 [phi:info_rom::@9->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1238] phi printf_string::format_min_length#18 = 9 [phi:info_rom::@9->printf_string#3] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [1209] phi from info_rom::@9 to info_rom::@10 [phi:info_rom::@9->info_rom::@10]
    // info_rom::@10
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1210] call printf_str
    // [745] phi from info_rom::@10 to printf_str [phi:info_rom::@10->printf_str]
    // [745] phi printf_str::putc#71 = &cputc [phi:info_rom::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = s1 [phi:info_rom::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@11
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1211] info_rom::$11 = info_rom::rom_chip#16 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta.z info_rom__11
    // [1212] printf_string::str#8 = rom_device_names[info_rom::$11] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda rom_device_names,y
    sta.z printf_string.str
    lda rom_device_names+1,y
    sta.z printf_string.str+1
    // [1213] call printf_string
    // [1238] phi from info_rom::@11 to printf_string [phi:info_rom::@11->printf_string]
    // [1238] phi printf_string::putc#18 = &cputc [phi:info_rom::@11->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1238] phi printf_string::str#18 = printf_string::str#8 [phi:info_rom::@11->printf_string#1] -- register_copy 
    // [1238] phi printf_string::format_justify_left#18 = 1 [phi:info_rom::@11->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1238] phi printf_string::format_min_length#18 = 6 [phi:info_rom::@11->printf_string#3] -- vbum1=vbuc1 
    lda #6
    sta printf_string.format_min_length
    jsr printf_string
    // [1214] phi from info_rom::@11 to info_rom::@12 [phi:info_rom::@11->info_rom::@12]
    // info_rom::@12
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1215] call printf_str
    // [745] phi from info_rom::@12 to printf_str [phi:info_rom::@12->printf_str]
    // [745] phi printf_str::putc#71 = &cputc [phi:info_rom::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = s1 [phi:info_rom::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@13
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1216] info_rom::$13 = info_rom::rom_chip#16 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta.z info_rom__13
    // [1217] printf_ulong::uvalue#0 = file_sizes[info_rom::$13] -- vdum1=pduc1_derefidx_vbuz2 
    tay
    lda file_sizes,y
    sta printf_ulong.uvalue
    lda file_sizes+1,y
    sta printf_ulong.uvalue+1
    lda file_sizes+2,y
    sta printf_ulong.uvalue+2
    lda file_sizes+3,y
    sta printf_ulong.uvalue+3
    // [1218] call printf_ulong
    // [1413] phi from info_rom::@13 to printf_ulong [phi:info_rom::@13->printf_ulong]
    // [1413] phi printf_ulong::format_zero_padding#11 = 1 [phi:info_rom::@13->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1413] phi printf_ulong::format_min_length#11 = 5 [phi:info_rom::@13->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1413] phi printf_ulong::putc#11 = &cputc [phi:info_rom::@13->printf_ulong#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_ulong.putc
    lda #>cputc
    sta.z printf_ulong.putc+1
    // [1413] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:info_rom::@13->printf_ulong#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1413] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#0 [phi:info_rom::@13->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1219] phi from info_rom::@13 to info_rom::@14 [phi:info_rom::@13->info_rom::@14]
    // info_rom::@14
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1220] call printf_str
    // [745] phi from info_rom::@14 to printf_str [phi:info_rom::@14->printf_str]
    // [745] phi printf_str::putc#71 = &cputc [phi:info_rom::@14->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = info_rom::s4 [phi:info_rom::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@15
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1221] printf_ulong::uvalue#1 = rom_sizes[info_rom::$13] -- vdum1=pduc1_derefidx_vbuz2 
    ldy.z info_rom__13
    lda rom_sizes,y
    sta printf_ulong.uvalue
    lda rom_sizes+1,y
    sta printf_ulong.uvalue+1
    lda rom_sizes+2,y
    sta printf_ulong.uvalue+2
    lda rom_sizes+3,y
    sta printf_ulong.uvalue+3
    // [1222] call printf_ulong
    // [1413] phi from info_rom::@15 to printf_ulong [phi:info_rom::@15->printf_ulong]
    // [1413] phi printf_ulong::format_zero_padding#11 = 1 [phi:info_rom::@15->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1413] phi printf_ulong::format_min_length#11 = 5 [phi:info_rom::@15->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1413] phi printf_ulong::putc#11 = &cputc [phi:info_rom::@15->printf_ulong#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_ulong.putc
    lda #>cputc
    sta.z printf_ulong.putc+1
    // [1413] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:info_rom::@15->printf_ulong#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1413] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#1 [phi:info_rom::@15->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1223] phi from info_rom::@15 to info_rom::@16 [phi:info_rom::@15->info_rom::@16]
    // info_rom::@16
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1224] call printf_str
    // [745] phi from info_rom::@16 to printf_str [phi:info_rom::@16->printf_str]
    // [745] phi printf_str::putc#71 = &cputc [phi:info_rom::@16->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = s1 [phi:info_rom::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@17
    // if(info_text)
    // [1225] if((char *)0==info_rom::info_text#16) goto info_rom::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // info_rom::@2
    // printf("%-20s", info_text)
    // [1226] printf_string::str#9 = info_rom::info_text#16 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1227] call printf_string
    // [1238] phi from info_rom::@2 to printf_string [phi:info_rom::@2->printf_string]
    // [1238] phi printf_string::putc#18 = &cputc [phi:info_rom::@2->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1238] phi printf_string::str#18 = printf_string::str#9 [phi:info_rom::@2->printf_string#1] -- register_copy 
    // [1238] phi printf_string::format_justify_left#18 = 1 [phi:info_rom::@2->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1238] phi printf_string::format_min_length#18 = $14 [phi:info_rom::@2->printf_string#3] -- vbum1=vbuc1 
    lda #$14
    sta printf_string.format_min_length
    jsr printf_string
    // info_rom::@1
  __b1:
    // gotoxy(x,y)
    // [1228] gotoxy::x#18 = info_rom::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1229] gotoxy::y#18 = info_rom::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1230] call gotoxy
    // [602] phi from info_rom::@1 to gotoxy [phi:info_rom::@1->gotoxy]
    // [602] phi gotoxy::y#30 = gotoxy::y#18 [phi:info_rom::@1->gotoxy#0] -- register_copy 
    // [602] phi gotoxy::x#30 = gotoxy::x#18 [phi:info_rom::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // info_rom::@return
    // }
    // [1231] return 
    rts
  .segment Data
    s: .text "ROM"
    .byte 0
    s4: .text " / "
    .byte 0
    .label x = wherex.return_4
    .label y = wherey.return_4
}
.segment Code
  // rom_file
// __zp($d3) char * rom_file(__zp($41) char rom_chip)
rom_file: {
    .label rom_file__0 = $41
    .label return = $d3
    .label rom_chip = $41
    // if(rom_chip)
    // [1233] if(0!=rom_file::rom_chip#2) goto rom_file::@1 -- 0_neq_vbuz1_then_la1 
    lda.z rom_chip
    bne __b1
    // [1236] phi from rom_file to rom_file::@return [phi:rom_file->rom_file::@return]
    // [1236] phi rom_file::return#2 = rom_file::file_rom_cx16 [phi:rom_file->rom_file::@return#0] -- pbuz1=pbuc1 
    lda #<file_rom_cx16
    sta.z return
    lda #>file_rom_cx16
    sta.z return+1
    rts
    // rom_file::@1
  __b1:
    // '0'+rom_chip
    // [1234] rom_file::$0 = '0' + rom_file::rom_chip#2 -- vbuz1=vbuc1_plus_vbuz1 
    lda #'0'
    clc
    adc.z rom_file__0
    sta.z rom_file__0
    // file_rom_card[3] = '0'+rom_chip
    // [1235] *(rom_file::file_rom_card+3) = rom_file::$0 -- _deref_pbuc1=vbuz1 
    sta file_rom_card+3
    // [1236] phi from rom_file::@1 to rom_file::@return [phi:rom_file::@1->rom_file::@return]
    // [1236] phi rom_file::return#2 = rom_file::file_rom_card [phi:rom_file::@1->rom_file::@return#0] -- pbuz1=pbuc1 
    lda #<file_rom_card
    sta.z return
    lda #>file_rom_card
    sta.z return+1
    // rom_file::@return
    // }
    // [1237] return 
    rts
  .segment Data
    file_rom_cx16: .text "ROM.BIN"
    .byte 0
    file_rom_card: .text "ROMn.BIN"
    .byte 0
}
.segment Code
  // printf_string
// Print a string value using a specific format
// Handles justification and min length 
// void printf_string(__zp($49) void (*putc)(char), __zp($62) char *str, __mem() char format_min_length, __mem() char format_justify_left)
printf_string: {
    .label printf_string__9 = $38
    .label str = $62
    .label putc = $49
    // if(format.min_length)
    // [1239] if(0==printf_string::format_min_length#18) goto printf_string::@1 -- 0_eq_vbum1_then_la1 
    lda format_min_length
    beq __b3
    // printf_string::@3
    // strlen(str)
    // [1240] strlen::str#3 = printf_string::str#18 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [1241] call strlen
    // [2170] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [2170] phi strlen::str#8 = strlen::str#3 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [1242] strlen::return#10 = strlen::len#2
    // printf_string::@6
    // [1243] printf_string::$9 = strlen::return#10 -- vwuz1=vwum2 
    lda strlen.return
    sta.z printf_string__9
    lda strlen.return+1
    sta.z printf_string__9+1
    // signed char len = (signed char)strlen(str)
    // [1244] printf_string::len#0 = (signed char)printf_string::$9 -- vbsm1=_sbyte_vwuz2 
    lda.z printf_string__9
    sta len
    // padding = (signed char)format.min_length  - len
    // [1245] printf_string::padding#1 = (signed char)printf_string::format_min_length#18 - printf_string::len#0 -- vbsm1=vbsm1_minus_vbsm2 
    lda padding
    sec
    sbc len
    sta padding
    // if(padding<0)
    // [1246] if(printf_string::padding#1>=0) goto printf_string::@10 -- vbsm1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1248] phi from printf_string printf_string::@6 to printf_string::@1 [phi:printf_string/printf_string::@6->printf_string::@1]
  __b3:
    // [1248] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@6->printf_string::@1#0] -- vbsm1=vbsc1 
    lda #0
    sta padding
    // [1247] phi from printf_string::@6 to printf_string::@10 [phi:printf_string::@6->printf_string::@10]
    // printf_string::@10
    // [1248] phi from printf_string::@10 to printf_string::@1 [phi:printf_string::@10->printf_string::@1]
    // [1248] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@10->printf_string::@1#0] -- register_copy 
    // printf_string::@1
  __b1:
    // if(!format.justify_left && padding)
    // [1249] if(0!=printf_string::format_justify_left#18) goto printf_string::@2 -- 0_neq_vbum1_then_la1 
    lda format_justify_left
    bne __b2
    // printf_string::@8
    // [1250] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b4
    jmp __b2
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [1251] printf_padding::putc#3 = printf_string::putc#18 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1252] printf_padding::length#3 = (char)printf_string::padding#3 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1253] call printf_padding
    // [2176] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    // [2176] phi printf_padding::putc#7 = printf_padding::putc#3 [phi:printf_string::@4->printf_padding#0] -- register_copy 
    // [2176] phi printf_padding::pad#7 = ' ' [phi:printf_string::@4->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [2176] phi printf_padding::length#6 = printf_padding::length#3 [phi:printf_string::@4->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [1254] printf_str::putc#1 = printf_string::putc#18 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_str.putc
    lda.z putc+1
    sta.z printf_str.putc+1
    // [1255] printf_str::s#2 = printf_string::str#18
    // [1256] call printf_str
    // [745] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [745] phi printf_str::putc#71 = printf_str::putc#1 [phi:printf_string::@2->printf_str#0] -- register_copy 
    // [745] phi printf_str::s#71 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@7
    // if(format.justify_left && padding)
    // [1257] if(0==printf_string::format_justify_left#18) goto printf_string::@return -- 0_eq_vbum1_then_la1 
    lda format_justify_left
    beq __breturn
    // printf_string::@9
    // [1258] if(0!=printf_string::padding#3) goto printf_string::@5 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b5
    rts
    // printf_string::@5
  __b5:
    // printf_padding(putc, ' ',(char)padding)
    // [1259] printf_padding::putc#4 = printf_string::putc#18 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1260] printf_padding::length#4 = (char)printf_string::padding#3 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1261] call printf_padding
    // [2176] phi from printf_string::@5 to printf_padding [phi:printf_string::@5->printf_padding]
    // [2176] phi printf_padding::putc#7 = printf_padding::putc#4 [phi:printf_string::@5->printf_padding#0] -- register_copy 
    // [2176] phi printf_padding::pad#7 = ' ' [phi:printf_string::@5->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [2176] phi printf_padding::length#6 = printf_padding::length#4 [phi:printf_string::@5->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@return
  __breturn:
    // }
    // [1262] return 
    rts
  .segment Data
    len: .byte 0
    .label padding = format_min_length
    format_min_length: .byte 0
    format_justify_left: .byte 0
}
.segment Code
  // rom_read
// __mem() unsigned long rom_read(char rom_chip, __zp($69) char *file, char info_status, __zp($78) char brom_bank_start, __zp($4f) unsigned long rom_size)
rom_read: {
    .const bank_set_brom1_bank = 0
    .label rom_read__11 = $5a
    .label fp = $be
    .label brom_bank_start = $78
    .label ram_address = $4d
    .label file = $69
    .label rom_size = $4f
    // unsigned long rom_address = rom_address_from_bank(brom_bank_start)
    // [1264] rom_address_from_bank::rom_bank#0 = rom_read::brom_bank_start#21 -- vbuz1=vbuz2 
    lda.z brom_bank_start
    sta.z rom_address_from_bank.rom_bank
    // [1265] call rom_address_from_bank
    // [2184] phi from rom_read to rom_address_from_bank [phi:rom_read->rom_address_from_bank]
    // [2184] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#0 [phi:rom_read->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(brom_bank_start)
    // [1266] rom_address_from_bank::return#2 = rom_address_from_bank::return#0
    // rom_read::@15
    // [1267] rom_read::rom_address#0 = rom_address_from_bank::return#2
    // rom_read::bank_set_bram1
    // BRAM = bank
    // [1268] BRAM = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z BRAM
    // rom_read::bank_set_brom1
    // BROM = bank
    // [1269] BROM = rom_read::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [1270] phi from rom_read::bank_set_brom1 to rom_read::@13 [phi:rom_read::bank_set_brom1->rom_read::@13]
    // rom_read::@13
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1271] call snprintf_init
    jsr snprintf_init
    // [1272] phi from rom_read::@13 to rom_read::@16 [phi:rom_read::@13->rom_read::@16]
    // rom_read::@16
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1273] call printf_str
    // [745] phi from rom_read::@16 to printf_str [phi:rom_read::@16->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:rom_read::@16->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = rom_read::s [phi:rom_read::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@17
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1274] printf_string::str#10 = rom_read::file#11 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [1275] call printf_string
    // [1238] phi from rom_read::@17 to printf_string [phi:rom_read::@17->printf_string]
    // [1238] phi printf_string::putc#18 = &snputc [phi:rom_read::@17->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1238] phi printf_string::str#18 = printf_string::str#10 [phi:rom_read::@17->printf_string#1] -- register_copy 
    // [1238] phi printf_string::format_justify_left#18 = 0 [phi:rom_read::@17->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1238] phi printf_string::format_min_length#18 = 0 [phi:rom_read::@17->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [1276] phi from rom_read::@17 to rom_read::@18 [phi:rom_read::@17->rom_read::@18]
    // rom_read::@18
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1277] call printf_str
    // [745] phi from rom_read::@18 to printf_str [phi:rom_read::@18->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:rom_read::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = rom_read::s1 [phi:rom_read::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@19
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1278] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1279] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_line(info_text)
    // [1281] call display_info_line
    // [976] phi from rom_read::@19 to display_info_line [phi:rom_read::@19->display_info_line]
    // [976] phi display_info_line::info_text#19 = info_text [phi:rom_read::@19->display_info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_line.info_text
    lda #>info_text
    sta.z display_info_line.info_text+1
    jsr display_info_line
    // rom_read::@20
    // FILE *fp = fopen(file, "r")
    // [1282] fopen::path#3 = rom_read::file#11 -- pbuz1=pbuz2 
    lda.z file
    sta.z fopen.path
    lda.z file+1
    sta.z fopen.path+1
    // [1283] call fopen
    // [1979] phi from rom_read::@20 to fopen [phi:rom_read::@20->fopen]
    // [1979] phi __errno#335 = __errno#106 [phi:rom_read::@20->fopen#0] -- register_copy 
    // [1979] phi fopen::pathtoken#0 = fopen::path#3 [phi:rom_read::@20->fopen#1] -- register_copy 
    jsr fopen
    // FILE *fp = fopen(file, "r")
    // [1284] fopen::return#4 = fopen::return#2
    // rom_read::@21
    // [1285] rom_read::fp#0 = fopen::return#4 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [1286] if((struct $2 *)0==rom_read::fp#0) goto rom_read::@1 -- pssc1_eq_pssz1_then_la1 
    lda.z fp
    cmp #<0
    bne !+
    lda.z fp+1
    cmp #>0
    beq __b2
  !:
    // [1287] phi from rom_read::@21 to rom_read::@2 [phi:rom_read::@21->rom_read::@2]
    // rom_read::@2
    // gotoxy(x, y)
    // [1288] call gotoxy
    // [602] phi from rom_read::@2 to gotoxy [phi:rom_read::@2->gotoxy]
    // [602] phi gotoxy::y#30 = PROGRESS_Y [phi:rom_read::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [602] phi gotoxy::x#30 = PROGRESS_X [phi:rom_read::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1289] phi from rom_read::@2 to rom_read::@3 [phi:rom_read::@2->rom_read::@3]
    // [1289] phi rom_read::y#11 = PROGRESS_Y [phi:rom_read::@2->rom_read::@3#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1289] phi rom_read::rom_row_current#10 = 0 [phi:rom_read::@2->rom_read::@3#1] -- vwum1=vwuc1 
    lda #<0
    sta rom_row_current
    sta rom_row_current+1
    // [1289] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#21 [phi:rom_read::@2->rom_read::@3#2] -- register_copy 
    // [1289] phi rom_read::rom_address#10 = rom_read::rom_address#0 [phi:rom_read::@2->rom_read::@3#3] -- register_copy 
    // [1289] phi rom_read::ram_address#10 = (char *)$6000 [phi:rom_read::@2->rom_read::@3#4] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z ram_address
    lda #>$6000
    sta.z ram_address+1
    // [1289] phi rom_read::bram_bank#10 = 0 [phi:rom_read::@2->rom_read::@3#5] -- vbum1=vbuc1 
    lda #0
    sta bram_bank
    // [1289] phi rom_read::rom_file_size#11 = 0 [phi:rom_read::@2->rom_read::@3#6] -- vdum1=vduc1 
    sta rom_file_size
    sta rom_file_size+1
    lda #<0>>$10
    sta rom_file_size+2
    lda #>0>>$10
    sta rom_file_size+3
    // rom_read::@3
  __b3:
    // while (rom_file_size < rom_size)
    // [1290] if(rom_read::rom_file_size#11<rom_read::rom_size#12) goto rom_read::@4 -- vdum1_lt_vduz2_then_la1 
    lda rom_file_size+3
    cmp.z rom_size+3
    bcc __b4
    bne !+
    lda rom_file_size+2
    cmp.z rom_size+2
    bcc __b4
    bne !+
    lda rom_file_size+1
    cmp.z rom_size+1
    bcc __b4
    bne !+
    lda rom_file_size
    cmp.z rom_size
    bcc __b4
  !:
    // rom_read::@7
  __b7:
    // fclose(fp)
    // [1291] fclose::stream#1 = rom_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fclose.stream
    lda.z fp+1
    sta.z fclose.stream+1
    // [1292] call fclose
    // [2114] phi from rom_read::@7 to fclose [phi:rom_read::@7->fclose]
    // [2114] phi fclose::stream#2 = fclose::stream#1 [phi:rom_read::@7->fclose#0] -- register_copy 
    jsr fclose
    // [1293] phi from rom_read::@7 to rom_read::@1 [phi:rom_read::@7->rom_read::@1]
    // [1293] phi rom_read::return#0 = rom_read::rom_file_size#11 [phi:rom_read::@7->rom_read::@1#0] -- register_copy 
    rts
    // [1293] phi from rom_read::@21 to rom_read::@1 [phi:rom_read::@21->rom_read::@1]
  __b2:
    // [1293] phi rom_read::return#0 = 0 [phi:rom_read::@21->rom_read::@1#0] -- vdum1=vduc1 
    lda #<0
    sta return
    sta return+1
    lda #<0>>$10
    sta return+2
    lda #>0>>$10
    sta return+3
    // rom_read::@1
    // rom_read::@return
    // }
    // [1294] return 
    rts
    // [1295] phi from rom_read::@3 to rom_read::@4 [phi:rom_read::@3->rom_read::@4]
    // rom_read::@4
  __b4:
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1296] call snprintf_init
    jsr snprintf_init
    // [1297] phi from rom_read::@4 to rom_read::@22 [phi:rom_read::@4->rom_read::@22]
    // rom_read::@22
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1298] call printf_str
    // [745] phi from rom_read::@22 to printf_str [phi:rom_read::@22->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:rom_read::@22->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = s14 [phi:rom_read::@22->printf_str#1] -- pbuz1=pbuc1 
    lda #<s14
    sta.z printf_str.s
    lda #>s14
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@23
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1299] printf_string::str#11 = rom_read::file#11 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [1300] call printf_string
    // [1238] phi from rom_read::@23 to printf_string [phi:rom_read::@23->printf_string]
    // [1238] phi printf_string::putc#18 = &snputc [phi:rom_read::@23->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1238] phi printf_string::str#18 = printf_string::str#11 [phi:rom_read::@23->printf_string#1] -- register_copy 
    // [1238] phi printf_string::format_justify_left#18 = 0 [phi:rom_read::@23->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1238] phi printf_string::format_min_length#18 = 0 [phi:rom_read::@23->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [1301] phi from rom_read::@23 to rom_read::@24 [phi:rom_read::@23->rom_read::@24]
    // rom_read::@24
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1302] call printf_str
    // [745] phi from rom_read::@24 to printf_str [phi:rom_read::@24->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:rom_read::@24->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = s3 [phi:rom_read::@24->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@25
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1303] printf_ulong::uvalue#2 = rom_read::rom_file_size#11 -- vdum1=vdum2 
    lda rom_file_size
    sta printf_ulong.uvalue
    lda rom_file_size+1
    sta printf_ulong.uvalue+1
    lda rom_file_size+2
    sta printf_ulong.uvalue+2
    lda rom_file_size+3
    sta printf_ulong.uvalue+3
    // [1304] call printf_ulong
    // [1413] phi from rom_read::@25 to printf_ulong [phi:rom_read::@25->printf_ulong]
    // [1413] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_read::@25->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1413] phi printf_ulong::format_min_length#11 = 5 [phi:rom_read::@25->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1413] phi printf_ulong::putc#11 = &snputc [phi:rom_read::@25->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1413] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_read::@25->printf_ulong#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1413] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#2 [phi:rom_read::@25->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1305] phi from rom_read::@25 to rom_read::@26 [phi:rom_read::@25->rom_read::@26]
    // rom_read::@26
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1306] call printf_str
    // [745] phi from rom_read::@26 to printf_str [phi:rom_read::@26->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:rom_read::@26->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = s4 [phi:rom_read::@26->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@27
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1307] printf_ulong::uvalue#3 = rom_read::rom_size#12 -- vdum1=vduz2 
    lda.z rom_size
    sta printf_ulong.uvalue
    lda.z rom_size+1
    sta printf_ulong.uvalue+1
    lda.z rom_size+2
    sta printf_ulong.uvalue+2
    lda.z rom_size+3
    sta printf_ulong.uvalue+3
    // [1308] call printf_ulong
    // [1413] phi from rom_read::@27 to printf_ulong [phi:rom_read::@27->printf_ulong]
    // [1413] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_read::@27->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1413] phi printf_ulong::format_min_length#11 = 5 [phi:rom_read::@27->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1413] phi printf_ulong::putc#11 = &snputc [phi:rom_read::@27->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1413] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_read::@27->printf_ulong#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1413] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#3 [phi:rom_read::@27->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1309] phi from rom_read::@27 to rom_read::@28 [phi:rom_read::@27->rom_read::@28]
    // rom_read::@28
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1310] call printf_str
    // [745] phi from rom_read::@28 to printf_str [phi:rom_read::@28->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:rom_read::@28->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = s2 [phi:rom_read::@28->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@29
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1311] printf_uchar::uvalue#5 = rom_read::bram_bank#10 -- vbum1=vbum2 
    lda bram_bank
    sta printf_uchar.uvalue
    // [1312] call printf_uchar
    // [1162] phi from rom_read::@29 to printf_uchar [phi:rom_read::@29->printf_uchar]
    // [1162] phi printf_uchar::format_zero_padding#11 = 1 [phi:rom_read::@29->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1162] phi printf_uchar::format_min_length#11 = 2 [phi:rom_read::@29->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1162] phi printf_uchar::putc#11 = &snputc [phi:rom_read::@29->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1162] phi printf_uchar::format_radix#11 = HEXADECIMAL [phi:rom_read::@29->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1162] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#5 [phi:rom_read::@29->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1313] phi from rom_read::@29 to rom_read::@30 [phi:rom_read::@29->rom_read::@30]
    // rom_read::@30
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1314] call printf_str
    // [745] phi from rom_read::@30 to printf_str [phi:rom_read::@30->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:rom_read::@30->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = s3 [phi:rom_read::@30->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@31
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1315] printf_uint::uvalue#10 = (unsigned int)rom_read::ram_address#10 -- vwum1=vwuz2 
    lda.z ram_address
    sta printf_uint.uvalue
    lda.z ram_address+1
    sta printf_uint.uvalue+1
    // [1316] call printf_uint
    // [754] phi from rom_read::@31 to printf_uint [phi:rom_read::@31->printf_uint]
    // [754] phi printf_uint::format_zero_padding#16 = 1 [phi:rom_read::@31->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [754] phi printf_uint::format_min_length#16 = 4 [phi:rom_read::@31->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [754] phi printf_uint::putc#16 = &snputc [phi:rom_read::@31->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [754] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:rom_read::@31->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [754] phi printf_uint::uvalue#16 = printf_uint::uvalue#10 [phi:rom_read::@31->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1317] phi from rom_read::@31 to rom_read::@32 [phi:rom_read::@31->rom_read::@32]
    // rom_read::@32
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1318] call printf_str
    // [745] phi from rom_read::@32 to printf_str [phi:rom_read::@32->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:rom_read::@32->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = s7 [phi:rom_read::@32->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@33
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1319] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1320] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_line(info_text)
    // [1322] call display_info_line
    // [976] phi from rom_read::@33 to display_info_line [phi:rom_read::@33->display_info_line]
    // [976] phi display_info_line::info_text#19 = info_text [phi:rom_read::@33->display_info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_line.info_text
    lda #>info_text
    sta.z display_info_line.info_text+1
    jsr display_info_line
    // rom_read::@34
    // rom_address % 0x04000
    // [1323] rom_read::$11 = rom_read::rom_address#10 & $4000-1 -- vduz1=vdum2_band_vduc1 
    lda rom_address
    and #<$4000-1
    sta.z rom_read__11
    lda rom_address+1
    and #>$4000-1
    sta.z rom_read__11+1
    lda rom_address+2
    and #<$4000-1>>$10
    sta.z rom_read__11+2
    lda rom_address+3
    and #>$4000-1>>$10
    sta.z rom_read__11+3
    // if (!(rom_address % 0x04000))
    // [1324] if(0!=rom_read::$11) goto rom_read::@5 -- 0_neq_vduz1_then_la1 
    lda.z rom_read__11
    ora.z rom_read__11+1
    ora.z rom_read__11+2
    ora.z rom_read__11+3
    bne __b5
    // rom_read::@10
    // brom_bank_start++;
    // [1325] rom_read::brom_bank_start#0 = ++ rom_read::brom_bank_start#10 -- vbuz1=_inc_vbuz1 
    inc.z brom_bank_start
    // [1326] phi from rom_read::@10 rom_read::@34 to rom_read::@5 [phi:rom_read::@10/rom_read::@34->rom_read::@5]
    // [1326] phi rom_read::brom_bank_start#20 = rom_read::brom_bank_start#0 [phi:rom_read::@10/rom_read::@34->rom_read::@5#0] -- register_copy 
    // rom_read::@5
  __b5:
    // rom_read::bank_set_bram2
    // BRAM = bank
    // [1327] BRAM = rom_read::bram_bank#10 -- vbuz1=vbum2 
    lda bram_bank
    sta.z BRAM
    // rom_read::@14
    // unsigned int rom_package_read = fgets(ram_address, PROGRESS_CELL, fp)
    // [1328] fgets::ptr#3 = rom_read::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z fgets.ptr
    lda.z ram_address+1
    sta.z fgets.ptr+1
    // [1329] fgets::stream#1 = rom_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.stream
    lda.z fp+1
    sta.z fgets.stream+1
    // [1330] call fgets
    // [2060] phi from rom_read::@14 to fgets [phi:rom_read::@14->fgets]
    // [2060] phi fgets::ptr#12 = fgets::ptr#3 [phi:rom_read::@14->fgets#0] -- register_copy 
    // [2060] phi fgets::size#10 = PROGRESS_CELL [phi:rom_read::@14->fgets#1] -- vwum1=vwuc1 
    lda #<PROGRESS_CELL
    sta fgets.size
    lda #>PROGRESS_CELL
    sta fgets.size+1
    // [2060] phi fgets::stream#2 = fgets::stream#1 [phi:rom_read::@14->fgets#2] -- register_copy 
    jsr fgets
    // unsigned int rom_package_read = fgets(ram_address, PROGRESS_CELL, fp)
    // [1331] fgets::return#6 = fgets::return#1
    // rom_read::@35
    // [1332] rom_read::rom_package_read#0 = fgets::return#6 -- vwum1=vwum2 
    lda fgets.return
    sta rom_package_read
    lda fgets.return+1
    sta rom_package_read+1
    // if (!rom_package_read)
    // [1333] if(0!=rom_read::rom_package_read#0) goto rom_read::@6 -- 0_neq_vwum1_then_la1 
    lda rom_package_read
    ora rom_package_read+1
    bne __b6
    jmp __b7
    // rom_read::@6
  __b6:
    // if (rom_row_current == PROGRESS_ROW)
    // [1334] if(rom_read::rom_row_current#10!=PROGRESS_ROW) goto rom_read::@8 -- vwum1_neq_vwuc1_then_la1 
    lda rom_row_current+1
    cmp #>PROGRESS_ROW
    bne __b8
    lda rom_row_current
    cmp #<PROGRESS_ROW
    bne __b8
    // rom_read::@11
    // gotoxy(x, ++y);
    // [1335] rom_read::y#1 = ++ rom_read::y#11 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [1336] gotoxy::y#25 = rom_read::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1337] call gotoxy
    // [602] phi from rom_read::@11 to gotoxy [phi:rom_read::@11->gotoxy]
    // [602] phi gotoxy::y#30 = gotoxy::y#25 [phi:rom_read::@11->gotoxy#0] -- register_copy 
    // [602] phi gotoxy::x#30 = PROGRESS_X [phi:rom_read::@11->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1338] phi from rom_read::@11 to rom_read::@8 [phi:rom_read::@11->rom_read::@8]
    // [1338] phi rom_read::y#36 = rom_read::y#1 [phi:rom_read::@11->rom_read::@8#0] -- register_copy 
    // [1338] phi rom_read::rom_row_current#4 = 0 [phi:rom_read::@11->rom_read::@8#1] -- vwum1=vbuc1 
    lda #<0
    sta rom_row_current
    sta rom_row_current+1
    // [1338] phi from rom_read::@6 to rom_read::@8 [phi:rom_read::@6->rom_read::@8]
    // [1338] phi rom_read::y#36 = rom_read::y#11 [phi:rom_read::@6->rom_read::@8#0] -- register_copy 
    // [1338] phi rom_read::rom_row_current#4 = rom_read::rom_row_current#10 [phi:rom_read::@6->rom_read::@8#1] -- register_copy 
    // rom_read::@8
  __b8:
    // cputc('.')
    // [1339] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [1340] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // ram_address += rom_package_read
    // [1342] rom_read::ram_address#1 = rom_read::ram_address#10 + rom_read::rom_package_read#0 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z ram_address
    adc rom_package_read
    sta.z ram_address
    lda.z ram_address+1
    adc rom_package_read+1
    sta.z ram_address+1
    // rom_address += rom_package_read
    // [1343] rom_read::rom_address#1 = rom_read::rom_address#10 + rom_read::rom_package_read#0 -- vdum1=vdum1_plus_vwum2 
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
    // [1344] rom_read::rom_file_size#1 = rom_read::rom_file_size#11 + rom_read::rom_package_read#0 -- vdum1=vdum1_plus_vwum2 
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
    // [1345] rom_read::rom_row_current#1 = rom_read::rom_row_current#4 + rom_read::rom_package_read#0 -- vwum1=vwum1_plus_vwum2 
    clc
    lda rom_row_current
    adc rom_package_read
    sta rom_row_current
    lda rom_row_current+1
    adc rom_package_read+1
    sta rom_row_current+1
    // if (ram_address == (ram_ptr_t)BRAM_HIGH)
    // [1346] if(rom_read::ram_address#1!=(char *)$c000) goto rom_read::@9 -- pbuz1_neq_pbuc1_then_la1 
    lda.z ram_address+1
    cmp #>$c000
    bne __b9
    lda.z ram_address
    cmp #<$c000
    bne __b9
    // rom_read::@12
    // bram_bank++;
    // [1347] rom_read::bram_bank#1 = ++ rom_read::bram_bank#10 -- vbum1=_inc_vbum1 
    inc bram_bank
    // [1348] phi from rom_read::@12 to rom_read::@9 [phi:rom_read::@12->rom_read::@9]
    // [1348] phi rom_read::bram_bank#30 = rom_read::bram_bank#1 [phi:rom_read::@12->rom_read::@9#0] -- register_copy 
    // [1348] phi rom_read::ram_address#7 = (char *)$a000 [phi:rom_read::@12->rom_read::@9#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1348] phi from rom_read::@8 to rom_read::@9 [phi:rom_read::@8->rom_read::@9]
    // [1348] phi rom_read::bram_bank#30 = rom_read::bram_bank#10 [phi:rom_read::@8->rom_read::@9#0] -- register_copy 
    // [1348] phi rom_read::ram_address#7 = rom_read::ram_address#1 [phi:rom_read::@8->rom_read::@9#1] -- register_copy 
    // rom_read::@9
  __b9:
    // if (ram_address == (ram_ptr_t)RAM_HIGH)
    // [1349] if(rom_read::ram_address#7!=(char *)$8000) goto rom_read::@36 -- pbuz1_neq_pbuc1_then_la1 
    lda.z ram_address+1
    cmp #>$8000
    beq !__b3+
    jmp __b3
  !__b3:
    lda.z ram_address
    cmp #<$8000
    beq !__b3+
    jmp __b3
  !__b3:
    // [1289] phi from rom_read::@9 to rom_read::@3 [phi:rom_read::@9->rom_read::@3]
    // [1289] phi rom_read::y#11 = rom_read::y#36 [phi:rom_read::@9->rom_read::@3#0] -- register_copy 
    // [1289] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#1 [phi:rom_read::@9->rom_read::@3#1] -- register_copy 
    // [1289] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#20 [phi:rom_read::@9->rom_read::@3#2] -- register_copy 
    // [1289] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@9->rom_read::@3#3] -- register_copy 
    // [1289] phi rom_read::ram_address#10 = (char *)$a000 [phi:rom_read::@9->rom_read::@3#4] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1289] phi rom_read::bram_bank#10 = 1 [phi:rom_read::@9->rom_read::@3#5] -- vbum1=vbuc1 
    lda #1
    sta bram_bank
    // [1289] phi rom_read::rom_file_size#11 = rom_read::rom_file_size#1 [phi:rom_read::@9->rom_read::@3#6] -- register_copy 
    jmp __b3
    // [1350] phi from rom_read::@9 to rom_read::@36 [phi:rom_read::@9->rom_read::@36]
    // rom_read::@36
    // [1289] phi from rom_read::@36 to rom_read::@3 [phi:rom_read::@36->rom_read::@3]
    // [1289] phi rom_read::y#11 = rom_read::y#36 [phi:rom_read::@36->rom_read::@3#0] -- register_copy 
    // [1289] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#1 [phi:rom_read::@36->rom_read::@3#1] -- register_copy 
    // [1289] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#20 [phi:rom_read::@36->rom_read::@3#2] -- register_copy 
    // [1289] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@36->rom_read::@3#3] -- register_copy 
    // [1289] phi rom_read::ram_address#10 = rom_read::ram_address#7 [phi:rom_read::@36->rom_read::@3#4] -- register_copy 
    // [1289] phi rom_read::bram_bank#10 = rom_read::bram_bank#30 [phi:rom_read::@36->rom_read::@3#5] -- register_copy 
    // [1289] phi rom_read::rom_file_size#11 = rom_read::rom_file_size#1 [phi:rom_read::@36->rom_read::@3#6] -- register_copy 
  .segment Data
    s: .text "Opening "
    .byte 0
    s1: .text " from SD card ..."
    .byte 0
    rom_address: .dword 0
    return: .dword 0
    rom_package_read: .word 0
    .label rom_file_size = return
    rom_row_current: .word 0
    y: .byte 0
    bram_bank: .byte 0
}
.segment Code
  // rom_verify
// __mem() unsigned long rom_verify(__zp($b4) char rom_chip, __zp($c8) char rom_bank_start, __zp($5a) unsigned long file_size)
rom_verify: {
    .label rom_verify__16 = $b5
    .label ram_address = $b1
    .label rom_chip = $b4
    .label rom_bank_start = $c8
    .label file_size = $5a
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [1351] rom_address_from_bank::rom_bank#1 = rom_verify::rom_bank_start#0
    // [1352] call rom_address_from_bank
    // [2184] phi from rom_verify to rom_address_from_bank [phi:rom_verify->rom_address_from_bank]
    // [2184] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#1 [phi:rom_verify->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [1353] rom_address_from_bank::return#3 = rom_address_from_bank::return#0 -- vdum1=vdum2 
    lda rom_address_from_bank.return
    sta rom_address_from_bank.return_1
    lda rom_address_from_bank.return+1
    sta rom_address_from_bank.return_1+1
    lda rom_address_from_bank.return+2
    sta rom_address_from_bank.return_1+2
    lda rom_address_from_bank.return+3
    sta rom_address_from_bank.return_1+3
    // rom_verify::@11
    // [1354] rom_verify::rom_address#0 = rom_address_from_bank::return#3
    // unsigned long rom_boundary = rom_address + file_size
    // [1355] rom_verify::rom_boundary#0 = rom_verify::rom_address#0 + rom_verify::file_size#0 -- vdum1=vdum2_plus_vduz3 
    lda rom_address
    clc
    adc.z file_size
    sta rom_boundary
    lda rom_address+1
    adc.z file_size+1
    sta rom_boundary+1
    lda rom_address+2
    adc.z file_size+2
    sta rom_boundary+2
    lda rom_address+3
    adc.z file_size+3
    sta rom_boundary+3
    // info_rom(rom_chip, STATUS_COMPARING, "Comparing ...")
    // [1356] info_rom::rom_chip#1 = rom_verify::rom_chip#0
    // [1357] call info_rom
    // [1187] phi from rom_verify::@11 to info_rom [phi:rom_verify::@11->info_rom]
    // [1187] phi info_rom::info_text#16 = rom_verify::info_text [phi:rom_verify::@11->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_rom.info_text
    lda #>info_text
    sta.z info_rom.info_text+1
    // [1187] phi info_rom::rom_chip#16 = info_rom::rom_chip#1 [phi:rom_verify::@11->info_rom#1] -- register_copy 
    // [1187] phi info_rom::info_status#16 = STATUS_COMPARING [phi:rom_verify::@11->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_COMPARING
    sta.z info_rom.info_status
    jsr info_rom
    // [1358] phi from rom_verify::@11 to rom_verify::@12 [phi:rom_verify::@11->rom_verify::@12]
    // rom_verify::@12
    // gotoxy(x, y)
    // [1359] call gotoxy
    // [602] phi from rom_verify::@12 to gotoxy [phi:rom_verify::@12->gotoxy]
    // [602] phi gotoxy::y#30 = PROGRESS_Y [phi:rom_verify::@12->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [602] phi gotoxy::x#30 = PROGRESS_X [phi:rom_verify::@12->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1360] phi from rom_verify::@12 to rom_verify::@1 [phi:rom_verify::@12->rom_verify::@1]
    // [1360] phi rom_verify::y#3 = PROGRESS_Y [phi:rom_verify::@12->rom_verify::@1#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1360] phi rom_verify::progress_row_current#3 = 0 [phi:rom_verify::@12->rom_verify::@1#1] -- vwum1=vwuc1 
    lda #<0
    sta progress_row_current
    sta progress_row_current+1
    // [1360] phi rom_verify::rom_different_bytes#11 = 0 [phi:rom_verify::@12->rom_verify::@1#2] -- vdum1=vduc1 
    sta rom_different_bytes
    sta rom_different_bytes+1
    lda #<0>>$10
    sta rom_different_bytes+2
    lda #>0>>$10
    sta rom_different_bytes+3
    // [1360] phi rom_verify::ram_address#10 = (char *)$6000 [phi:rom_verify::@12->rom_verify::@1#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z ram_address
    lda #>$6000
    sta.z ram_address+1
    // [1360] phi rom_verify::bram_bank#11 = 0 [phi:rom_verify::@12->rom_verify::@1#4] -- vbum1=vbuc1 
    lda #0
    sta bram_bank
    // [1360] phi rom_verify::rom_address#12 = rom_verify::rom_address#0 [phi:rom_verify::@12->rom_verify::@1#5] -- register_copy 
    // rom_verify::@1
  __b1:
    // while (rom_address < rom_boundary)
    // [1361] if(rom_verify::rom_address#12<rom_verify::rom_boundary#0) goto rom_verify::@2 -- vdum1_lt_vdum2_then_la1 
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
    // [1362] return 
    rts
    // rom_verify::@2
  __b2:
    // unsigned int equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1363] rom_compare::bank_ram#0 = rom_verify::bram_bank#11 -- vbuz1=vbum2 
    lda bram_bank
    sta.z rom_compare.bank_ram
    // [1364] rom_compare::ptr_ram#1 = rom_verify::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_compare.ptr_ram
    lda.z ram_address+1
    sta.z rom_compare.ptr_ram+1
    // [1365] rom_compare::rom_compare_address#0 = rom_verify::rom_address#12 -- vduz1=vdum2 
    lda rom_address
    sta.z rom_compare.rom_compare_address
    lda rom_address+1
    sta.z rom_compare.rom_compare_address+1
    lda rom_address+2
    sta.z rom_compare.rom_compare_address+2
    lda rom_address+3
    sta.z rom_compare.rom_compare_address+3
    // [1366] call rom_compare
  // {asm{.byte $db}}
    // [2188] phi from rom_verify::@2 to rom_compare [phi:rom_verify::@2->rom_compare]
    // [2188] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#1 [phi:rom_verify::@2->rom_compare#0] -- register_copy 
    // [2188] phi rom_compare::rom_compare_size#11 = PROGRESS_CELL [phi:rom_verify::@2->rom_compare#1] -- vwuz1=vwuc1 
    lda #<PROGRESS_CELL
    sta.z rom_compare.rom_compare_size
    lda #>PROGRESS_CELL
    sta.z rom_compare.rom_compare_size+1
    // [2188] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#0 [phi:rom_verify::@2->rom_compare#2] -- register_copy 
    // [2188] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#0 [phi:rom_verify::@2->rom_compare#3] -- vbum1=vbuz2 
    lda.z rom_compare.bank_ram
    sta rom_compare.bank_set_bram1_bank
    jsr rom_compare
    // unsigned int equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1367] rom_compare::return#2 = rom_compare::equal_bytes#2
    // rom_verify::@13
    // [1368] rom_verify::equal_bytes#0 = rom_compare::return#2
    // if (progress_row_current == PROGRESS_ROW)
    // [1369] if(rom_verify::progress_row_current#3!=PROGRESS_ROW) goto rom_verify::@3 -- vwum1_neq_vwuc1_then_la1 
    lda progress_row_current+1
    cmp #>PROGRESS_ROW
    bne __b3
    lda progress_row_current
    cmp #<PROGRESS_ROW
    bne __b3
    // rom_verify::@8
    // gotoxy(x, ++y);
    // [1370] rom_verify::y#1 = ++ rom_verify::y#3 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [1371] gotoxy::y#27 = rom_verify::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1372] call gotoxy
    // [602] phi from rom_verify::@8 to gotoxy [phi:rom_verify::@8->gotoxy]
    // [602] phi gotoxy::y#30 = gotoxy::y#27 [phi:rom_verify::@8->gotoxy#0] -- register_copy 
    // [602] phi gotoxy::x#30 = PROGRESS_X [phi:rom_verify::@8->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1373] phi from rom_verify::@8 to rom_verify::@3 [phi:rom_verify::@8->rom_verify::@3]
    // [1373] phi rom_verify::y#10 = rom_verify::y#1 [phi:rom_verify::@8->rom_verify::@3#0] -- register_copy 
    // [1373] phi rom_verify::progress_row_current#4 = 0 [phi:rom_verify::@8->rom_verify::@3#1] -- vwum1=vbuc1 
    lda #<0
    sta progress_row_current
    sta progress_row_current+1
    // [1373] phi from rom_verify::@13 to rom_verify::@3 [phi:rom_verify::@13->rom_verify::@3]
    // [1373] phi rom_verify::y#10 = rom_verify::y#3 [phi:rom_verify::@13->rom_verify::@3#0] -- register_copy 
    // [1373] phi rom_verify::progress_row_current#4 = rom_verify::progress_row_current#3 [phi:rom_verify::@13->rom_verify::@3#1] -- register_copy 
    // rom_verify::@3
  __b3:
    // if (equal_bytes != PROGRESS_CELL)
    // [1374] if(rom_verify::equal_bytes#0!=PROGRESS_CELL) goto rom_verify::@4 -- vwum1_neq_vwuc1_then_la1 
    lda equal_bytes+1
    cmp #>PROGRESS_CELL
    beq !__b4+
    jmp __b4
  !__b4:
    lda equal_bytes
    cmp #<PROGRESS_CELL
    beq !__b4+
    jmp __b4
  !__b4:
    // rom_verify::@9
    // cputc('=')
    // [1375] stackpush(char) = '=' -- _stackpushbyte_=vbuc1 
    lda #'='
    pha
    // [1376] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // rom_verify::@5
  __b5:
    // ram_address += PROGRESS_CELL
    // [1378] rom_verify::ram_address#1 = rom_verify::ram_address#10 + PROGRESS_CELL -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address
    clc
    adc #<PROGRESS_CELL
    sta.z ram_address
    lda.z ram_address+1
    adc #>PROGRESS_CELL
    sta.z ram_address+1
    // rom_address += PROGRESS_CELL
    // [1379] rom_verify::rom_address#1 = rom_verify::rom_address#12 + PROGRESS_CELL -- vdum1=vdum1_plus_vwuc1 
    clc
    lda rom_address
    adc #<PROGRESS_CELL
    sta rom_address
    lda rom_address+1
    adc #>PROGRESS_CELL
    sta rom_address+1
    lda rom_address+2
    adc #0
    sta rom_address+2
    lda rom_address+3
    adc #0
    sta rom_address+3
    // progress_row_current += PROGRESS_CELL
    // [1380] rom_verify::progress_row_current#11 = rom_verify::progress_row_current#4 + PROGRESS_CELL -- vwum1=vwum1_plus_vwuc1 
    lda progress_row_current
    clc
    adc #<PROGRESS_CELL
    sta progress_row_current
    lda progress_row_current+1
    adc #>PROGRESS_CELL
    sta progress_row_current+1
    // if (ram_address == BRAM_HIGH)
    // [1381] if(rom_verify::ram_address#1!=$c000) goto rom_verify::@6 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address+1
    cmp #>$c000
    bne __b6
    lda.z ram_address
    cmp #<$c000
    bne __b6
    // rom_verify::@10
    // bram_bank++;
    // [1382] rom_verify::bram_bank#1 = ++ rom_verify::bram_bank#11 -- vbum1=_inc_vbum1 
    inc bram_bank
    // [1383] phi from rom_verify::@10 to rom_verify::@6 [phi:rom_verify::@10->rom_verify::@6]
    // [1383] phi rom_verify::bram_bank#24 = rom_verify::bram_bank#1 [phi:rom_verify::@10->rom_verify::@6#0] -- register_copy 
    // [1383] phi rom_verify::ram_address#6 = (char *)$a000 [phi:rom_verify::@10->rom_verify::@6#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1383] phi from rom_verify::@5 to rom_verify::@6 [phi:rom_verify::@5->rom_verify::@6]
    // [1383] phi rom_verify::bram_bank#24 = rom_verify::bram_bank#11 [phi:rom_verify::@5->rom_verify::@6#0] -- register_copy 
    // [1383] phi rom_verify::ram_address#6 = rom_verify::ram_address#1 [phi:rom_verify::@5->rom_verify::@6#1] -- register_copy 
    // rom_verify::@6
  __b6:
    // if (ram_address == RAM_HIGH)
    // [1384] if(rom_verify::ram_address#6!=$8000) goto rom_verify::@23 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address+1
    cmp #>$8000
    bne __b7
    lda.z ram_address
    cmp #<$8000
    bne __b7
    // [1386] phi from rom_verify::@6 to rom_verify::@7 [phi:rom_verify::@6->rom_verify::@7]
    // [1386] phi rom_verify::ram_address#11 = (char *)$a000 [phi:rom_verify::@6->rom_verify::@7#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1386] phi rom_verify::bram_bank#10 = 1 [phi:rom_verify::@6->rom_verify::@7#1] -- vbum1=vbuc1 
    lda #1
    sta bram_bank
    // [1385] phi from rom_verify::@6 to rom_verify::@23 [phi:rom_verify::@6->rom_verify::@23]
    // rom_verify::@23
    // [1386] phi from rom_verify::@23 to rom_verify::@7 [phi:rom_verify::@23->rom_verify::@7]
    // [1386] phi rom_verify::ram_address#11 = rom_verify::ram_address#6 [phi:rom_verify::@23->rom_verify::@7#0] -- register_copy 
    // [1386] phi rom_verify::bram_bank#10 = rom_verify::bram_bank#24 [phi:rom_verify::@23->rom_verify::@7#1] -- register_copy 
    // rom_verify::@7
  __b7:
    // PROGRESS_CELL - equal_bytes
    // [1387] rom_verify::$16 = PROGRESS_CELL - rom_verify::equal_bytes#0 -- vwuz1=vwuc1_minus_vwum2 
    sec
    lda #<PROGRESS_CELL
    sbc equal_bytes
    sta.z rom_verify__16
    lda #>PROGRESS_CELL
    sbc equal_bytes+1
    sta.z rom_verify__16+1
    // rom_different_bytes += (PROGRESS_CELL - equal_bytes)
    // [1388] rom_verify::rom_different_bytes#1 = rom_verify::rom_different_bytes#11 + rom_verify::$16 -- vdum1=vdum1_plus_vwuz2 
    lda rom_different_bytes
    clc
    adc.z rom_verify__16
    sta rom_different_bytes
    lda rom_different_bytes+1
    adc.z rom_verify__16+1
    sta rom_different_bytes+1
    lda rom_different_bytes+2
    adc #0
    sta rom_different_bytes+2
    lda rom_different_bytes+3
    adc #0
    sta rom_different_bytes+3
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1389] call snprintf_init
    jsr snprintf_init
    // [1390] phi from rom_verify::@7 to rom_verify::@14 [phi:rom_verify::@7->rom_verify::@14]
    // rom_verify::@14
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1391] call printf_str
    // [745] phi from rom_verify::@14 to printf_str [phi:rom_verify::@14->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:rom_verify::@14->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = rom_verify::s [phi:rom_verify::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@15
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1392] printf_ulong::uvalue#4 = rom_verify::rom_different_bytes#1 -- vdum1=vdum2 
    lda rom_different_bytes
    sta printf_ulong.uvalue
    lda rom_different_bytes+1
    sta printf_ulong.uvalue+1
    lda rom_different_bytes+2
    sta printf_ulong.uvalue+2
    lda rom_different_bytes+3
    sta printf_ulong.uvalue+3
    // [1393] call printf_ulong
    // [1413] phi from rom_verify::@15 to printf_ulong [phi:rom_verify::@15->printf_ulong]
    // [1413] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_verify::@15->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1413] phi printf_ulong::format_min_length#11 = 5 [phi:rom_verify::@15->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1413] phi printf_ulong::putc#11 = &snputc [phi:rom_verify::@15->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1413] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_verify::@15->printf_ulong#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1413] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#4 [phi:rom_verify::@15->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1394] phi from rom_verify::@15 to rom_verify::@16 [phi:rom_verify::@15->rom_verify::@16]
    // rom_verify::@16
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1395] call printf_str
    // [745] phi from rom_verify::@16 to printf_str [phi:rom_verify::@16->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:rom_verify::@16->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = rom_verify::s1 [phi:rom_verify::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@17
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1396] printf_uchar::uvalue#6 = rom_verify::bram_bank#10 -- vbum1=vbum2 
    lda bram_bank
    sta printf_uchar.uvalue
    // [1397] call printf_uchar
    // [1162] phi from rom_verify::@17 to printf_uchar [phi:rom_verify::@17->printf_uchar]
    // [1162] phi printf_uchar::format_zero_padding#11 = 1 [phi:rom_verify::@17->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1162] phi printf_uchar::format_min_length#11 = 2 [phi:rom_verify::@17->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1162] phi printf_uchar::putc#11 = &snputc [phi:rom_verify::@17->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1162] phi printf_uchar::format_radix#11 = HEXADECIMAL [phi:rom_verify::@17->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1162] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#6 [phi:rom_verify::@17->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1398] phi from rom_verify::@17 to rom_verify::@18 [phi:rom_verify::@17->rom_verify::@18]
    // rom_verify::@18
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1399] call printf_str
    // [745] phi from rom_verify::@18 to printf_str [phi:rom_verify::@18->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:rom_verify::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = s3 [phi:rom_verify::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s3
    sta.z printf_str.s
    lda #>@s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@19
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1400] printf_uint::uvalue#11 = (unsigned int)rom_verify::ram_address#11 -- vwum1=vwuz2 
    lda.z ram_address
    sta printf_uint.uvalue
    lda.z ram_address+1
    sta printf_uint.uvalue+1
    // [1401] call printf_uint
    // [754] phi from rom_verify::@19 to printf_uint [phi:rom_verify::@19->printf_uint]
    // [754] phi printf_uint::format_zero_padding#16 = 1 [phi:rom_verify::@19->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [754] phi printf_uint::format_min_length#16 = 4 [phi:rom_verify::@19->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [754] phi printf_uint::putc#16 = &snputc [phi:rom_verify::@19->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [754] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:rom_verify::@19->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [754] phi printf_uint::uvalue#16 = printf_uint::uvalue#11 [phi:rom_verify::@19->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1402] phi from rom_verify::@19 to rom_verify::@20 [phi:rom_verify::@19->rom_verify::@20]
    // rom_verify::@20
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1403] call printf_str
    // [745] phi from rom_verify::@20 to printf_str [phi:rom_verify::@20->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:rom_verify::@20->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = rom_verify::s3 [phi:rom_verify::@20->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@21
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1404] printf_ulong::uvalue#5 = rom_verify::rom_address#1 -- vdum1=vdum2 
    lda rom_address
    sta printf_ulong.uvalue
    lda rom_address+1
    sta printf_ulong.uvalue+1
    lda rom_address+2
    sta printf_ulong.uvalue+2
    lda rom_address+3
    sta printf_ulong.uvalue+3
    // [1405] call printf_ulong
    // [1413] phi from rom_verify::@21 to printf_ulong [phi:rom_verify::@21->printf_ulong]
    // [1413] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_verify::@21->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1413] phi printf_ulong::format_min_length#11 = 5 [phi:rom_verify::@21->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1413] phi printf_ulong::putc#11 = &snputc [phi:rom_verify::@21->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1413] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_verify::@21->printf_ulong#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1413] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#5 [phi:rom_verify::@21->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // rom_verify::@22
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1406] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1407] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_line(info_text)
    // [1409] call display_info_line
    // [976] phi from rom_verify::@22 to display_info_line [phi:rom_verify::@22->display_info_line]
    // [976] phi display_info_line::info_text#19 = info_text [phi:rom_verify::@22->display_info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_line.info_text
    lda #>@info_text
    sta.z display_info_line.info_text+1
    jsr display_info_line
    // [1360] phi from rom_verify::@22 to rom_verify::@1 [phi:rom_verify::@22->rom_verify::@1]
    // [1360] phi rom_verify::y#3 = rom_verify::y#10 [phi:rom_verify::@22->rom_verify::@1#0] -- register_copy 
    // [1360] phi rom_verify::progress_row_current#3 = rom_verify::progress_row_current#11 [phi:rom_verify::@22->rom_verify::@1#1] -- register_copy 
    // [1360] phi rom_verify::rom_different_bytes#11 = rom_verify::rom_different_bytes#1 [phi:rom_verify::@22->rom_verify::@1#2] -- register_copy 
    // [1360] phi rom_verify::ram_address#10 = rom_verify::ram_address#11 [phi:rom_verify::@22->rom_verify::@1#3] -- register_copy 
    // [1360] phi rom_verify::bram_bank#11 = rom_verify::bram_bank#10 [phi:rom_verify::@22->rom_verify::@1#4] -- register_copy 
    // [1360] phi rom_verify::rom_address#12 = rom_verify::rom_address#1 [phi:rom_verify::@22->rom_verify::@1#5] -- register_copy 
    jmp __b1
    // rom_verify::@4
  __b4:
    // cputc('*')
    // [1410] stackpush(char) = '*' -- _stackpushbyte_=vbuc1 
    lda #'*'
    pha
    // [1411] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b5
  .segment Data
    info_text: .text "Comparing ..."
    .byte 0
    s: .text "Comparing: "
    .byte 0
    s1: .text " differences between RAM:"
    .byte 0
    s3: .text " <-> ROM:"
    .byte 0
    rom_address: .dword 0
    rom_boundary: .dword 0
    .label equal_bytes = rom_compare.equal_bytes
    y: .byte 0
    bram_bank: .byte 0
    rom_different_bytes: .dword 0
    .label return = rom_different_bytes
    progress_row_current: .word 0
}
.segment Code
  // printf_ulong
// Print an unsigned int using a specific format
// void printf_ulong(__zp($6f) void (*putc)(char), __mem() unsigned long uvalue, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, __mem() char format_radix)
printf_ulong: {
    .label putc = $6f
    // printf_ulong::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1414] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // ultoa(uvalue, printf_buffer.digits, format.radix)
    // [1415] ultoa::value#1 = printf_ulong::uvalue#11
    // [1416] ultoa::radix#0 = printf_ulong::format_radix#11
    // [1417] call ultoa
    // Format number into buffer
    jsr ultoa
    // printf_ulong::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1418] printf_number_buffer::putc#0 = printf_ulong::putc#11
    // [1419] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [1420] printf_number_buffer::format_min_length#0 = printf_ulong::format_min_length#11
    // [1421] printf_number_buffer::format_zero_padding#0 = printf_ulong::format_zero_padding#11
    // [1422] call printf_number_buffer
  // Print using format
    // [1884] phi from printf_ulong::@2 to printf_number_buffer [phi:printf_ulong::@2->printf_number_buffer]
    // [1884] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#0 [phi:printf_ulong::@2->printf_number_buffer#0] -- register_copy 
    // [1884] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_ulong::@2->printf_number_buffer#1] -- register_copy 
    // [1884] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#0 [phi:printf_ulong::@2->printf_number_buffer#2] -- register_copy 
    // [1884] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#0 [phi:printf_ulong::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_ulong::@return
    // }
    // [1423] return 
    rts
  .segment Data
    uvalue: .dword 0
    uvalue_1: .dword 0
    format_radix: .byte 0
    .label format_min_length = printf_uint.format_min_length
    .label format_zero_padding = printf_uint.format_zero_padding
}
.segment Code
  // rom_flash
// __mem() unsigned long rom_flash(__zp($d2) char rom_chip, __zp($c8) char rom_bank_start, __zp($3d) unsigned long file_size)
rom_flash: {
    .label rom_flash__29 = $5a
    .label ram_address_sector = $6d
    .label ram_address = $7a
    .label rom_chip = $d2
    .label rom_bank_start = $c8
    .label file_size = $3d
    // display_info_progress("Flashing ... (-) equal, (+) flashed, (!) error.")
    // [1425] call display_info_progress
  // Now we compare the RAM with the actual ROM contents.
    // [711] phi from rom_flash to display_info_progress [phi:rom_flash->display_info_progress]
    // [711] phi display_info_progress::info_text#14 = rom_flash::info_text [phi:rom_flash->display_info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_progress.info_text
    lda #>info_text
    sta.z display_info_progress.info_text+1
    jsr display_info_progress
    // rom_flash::@19
    // unsigned long rom_address_sector = rom_address_from_bank(rom_bank_start)
    // [1426] rom_address_from_bank::rom_bank#2 = rom_flash::rom_bank_start#0
    // [1427] call rom_address_from_bank
    // [2184] phi from rom_flash::@19 to rom_address_from_bank [phi:rom_flash::@19->rom_address_from_bank]
    // [2184] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#2 [phi:rom_flash::@19->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address_sector = rom_address_from_bank(rom_bank_start)
    // [1428] rom_address_from_bank::return#4 = rom_address_from_bank::return#0 -- vdum1=vdum2 
    lda rom_address_from_bank.return
    sta rom_address_from_bank.return_2
    lda rom_address_from_bank.return+1
    sta rom_address_from_bank.return_2+1
    lda rom_address_from_bank.return+2
    sta rom_address_from_bank.return_2+2
    lda rom_address_from_bank.return+3
    sta rom_address_from_bank.return_2+3
    // rom_flash::@20
    // [1429] rom_flash::rom_address_sector#0 = rom_address_from_bank::return#4
    // unsigned long rom_boundary = rom_address_sector + file_size
    // [1430] rom_flash::rom_boundary#0 = rom_flash::rom_address_sector#0 + rom_flash::file_size#0 -- vdum1=vdum2_plus_vduz3 
    lda rom_address_sector
    clc
    adc.z file_size
    sta rom_boundary
    lda rom_address_sector+1
    adc.z file_size+1
    sta rom_boundary+1
    lda rom_address_sector+2
    adc.z file_size+2
    sta rom_boundary+2
    lda rom_address_sector+3
    adc.z file_size+3
    sta rom_boundary+3
    // info_rom(rom_chip, STATUS_FLASHING, "Flashing ...")
    // [1431] info_rom::rom_chip#2 = rom_flash::rom_chip#0 -- vbuz1=vbuz2 
    lda.z rom_chip
    sta.z info_rom.rom_chip
    // [1432] call info_rom
    // [1187] phi from rom_flash::@20 to info_rom [phi:rom_flash::@20->info_rom]
    // [1187] phi info_rom::info_text#16 = rom_flash::info_text1 [phi:rom_flash::@20->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z info_rom.info_text
    lda #>info_text1
    sta.z info_rom.info_text+1
    // [1187] phi info_rom::rom_chip#16 = info_rom::rom_chip#2 [phi:rom_flash::@20->info_rom#1] -- register_copy 
    // [1187] phi info_rom::info_status#16 = STATUS_FLASHING [phi:rom_flash::@20->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHING
    sta.z info_rom.info_status
    jsr info_rom
    // [1433] phi from rom_flash::@20 to rom_flash::@1 [phi:rom_flash::@20->rom_flash::@1]
    // [1433] phi rom_flash::y_sector#13 = PROGRESS_Y [phi:rom_flash::@20->rom_flash::@1#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y_sector
    // [1433] phi rom_flash::x_sector#10 = PROGRESS_X [phi:rom_flash::@20->rom_flash::@1#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [1433] phi rom_flash::flash_errors#10 = 0 [phi:rom_flash::@20->rom_flash::@1#2] -- vdum1=vduc1 
    lda #<0
    sta flash_errors
    sta flash_errors+1
    lda #<0>>$10
    sta flash_errors+2
    lda #>0>>$10
    sta flash_errors+3
    // [1433] phi rom_flash::ram_address_sector#11 = (char *)$6000 [phi:rom_flash::@20->rom_flash::@1#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z ram_address_sector
    lda #>$6000
    sta.z ram_address_sector+1
    // [1433] phi rom_flash::bram_bank_sector#14 = 0 [phi:rom_flash::@20->rom_flash::@1#4] -- vbum1=vbuc1 
    lda #0
    sta bram_bank_sector
    // [1433] phi rom_flash::rom_address_sector#12 = rom_flash::rom_address_sector#0 [phi:rom_flash::@20->rom_flash::@1#5] -- register_copy 
    // rom_flash::@1
  __b1:
    // while (rom_address_sector < rom_boundary)
    // [1434] if(rom_flash::rom_address_sector#12<rom_flash::rom_boundary#0) goto rom_flash::@2 -- vdum1_lt_vdum2_then_la1 
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
    // [1435] phi from rom_flash::@1 to rom_flash::@3 [phi:rom_flash::@1->rom_flash::@3]
    // rom_flash::@3
    // display_info_line("Flashed ...")
    // [1436] call display_info_line
    // [976] phi from rom_flash::@3 to display_info_line [phi:rom_flash::@3->display_info_line]
    // [976] phi display_info_line::info_text#19 = rom_flash::info_text2 [phi:rom_flash::@3->display_info_line#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z display_info_line.info_text
    lda #>info_text2
    sta.z display_info_line.info_text+1
    jsr display_info_line
    // rom_flash::@return
    // }
    // [1437] return 
    rts
    // rom_flash::@2
  __b2:
    // unsigned int equal_bytes = rom_compare(bram_bank_sector, (ram_ptr_t)ram_address_sector, rom_address_sector, ROM_SECTOR)
    // [1438] rom_compare::bank_ram#1 = rom_flash::bram_bank_sector#14 -- vbuz1=vbum2 
    lda bram_bank_sector
    sta.z rom_compare.bank_ram_1
    // [1439] rom_compare::ptr_ram#2 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z rom_compare.ptr_ram
    lda.z ram_address_sector+1
    sta.z rom_compare.ptr_ram+1
    // [1440] rom_compare::rom_compare_address#1 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_compare.rom_compare_address
    lda rom_address_sector+1
    sta.z rom_compare.rom_compare_address+1
    lda rom_address_sector+2
    sta.z rom_compare.rom_compare_address+2
    lda rom_address_sector+3
    sta.z rom_compare.rom_compare_address+3
    // [1441] call rom_compare
  // {asm{.byte $db}}
    // [2188] phi from rom_flash::@2 to rom_compare [phi:rom_flash::@2->rom_compare]
    // [2188] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#2 [phi:rom_flash::@2->rom_compare#0] -- register_copy 
    // [2188] phi rom_compare::rom_compare_size#11 = $1000 [phi:rom_flash::@2->rom_compare#1] -- vwuz1=vwuc1 
    lda #<$1000
    sta.z rom_compare.rom_compare_size
    lda #>$1000
    sta.z rom_compare.rom_compare_size+1
    // [2188] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#1 [phi:rom_flash::@2->rom_compare#2] -- register_copy 
    // [2188] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#1 [phi:rom_flash::@2->rom_compare#3] -- vbum1=vbuz2 
    lda.z rom_compare.bank_ram_1
    sta rom_compare.bank_set_bram1_bank
    jsr rom_compare
    // unsigned int equal_bytes = rom_compare(bram_bank_sector, (ram_ptr_t)ram_address_sector, rom_address_sector, ROM_SECTOR)
    // [1442] rom_compare::return#3 = rom_compare::equal_bytes#2
    // rom_flash::@21
    // [1443] rom_flash::equal_bytes#0 = rom_compare::return#3
    // if (equal_bytes != ROM_SECTOR)
    // [1444] if(rom_flash::equal_bytes#0!=$1000) goto rom_flash::@5 -- vwum1_neq_vwuc1_then_la1 
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
    // [1445] cputsxy::x#1 = rom_flash::x_sector#10 -- vbum1=vbum2 
    lda x_sector
    sta cputsxy.x
    // [1446] cputsxy::y#1 = rom_flash::y_sector#13 -- vbum1=vbum2 
    lda y_sector
    sta cputsxy.y
    // [1447] call cputsxy
    // [689] phi from rom_flash::@16 to cputsxy [phi:rom_flash::@16->cputsxy]
    // [689] phi cputsxy::s#4 = rom_flash::s [phi:rom_flash::@16->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z cputsxy.s
    lda #>s
    sta.z cputsxy.s+1
    // [689] phi cputsxy::y#4 = cputsxy::y#1 [phi:rom_flash::@16->cputsxy#1] -- register_copy 
    // [689] phi cputsxy::x#4 = cputsxy::x#1 [phi:rom_flash::@16->cputsxy#2] -- register_copy 
    jsr cputsxy
    // [1448] phi from rom_flash::@12 rom_flash::@16 to rom_flash::@4 [phi:rom_flash::@12/rom_flash::@16->rom_flash::@4]
    // [1448] phi rom_flash::flash_errors#13 = rom_flash::flash_errors#1 [phi:rom_flash::@12/rom_flash::@16->rom_flash::@4#0] -- register_copy 
    // rom_flash::@4
  __b4:
    // ram_address_sector += ROM_SECTOR
    // [1449] rom_flash::ram_address_sector#1 = rom_flash::ram_address_sector#11 + $1000 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address_sector
    clc
    adc #<$1000
    sta.z ram_address_sector
    lda.z ram_address_sector+1
    adc #>$1000
    sta.z ram_address_sector+1
    // rom_address_sector += ROM_SECTOR
    // [1450] rom_flash::rom_address_sector#1 = rom_flash::rom_address_sector#12 + $1000 -- vdum1=vdum1_plus_vwuc1 
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
    // [1451] if(rom_flash::ram_address_sector#1!=$c000) goto rom_flash::@13 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address_sector+1
    cmp #>$c000
    bne __b13
    lda.z ram_address_sector
    cmp #<$c000
    bne __b13
    // rom_flash::@17
    // bram_bank_sector++;
    // [1452] rom_flash::bram_bank_sector#1 = ++ rom_flash::bram_bank_sector#14 -- vbum1=_inc_vbum1 
    inc bram_bank_sector
    // [1453] phi from rom_flash::@17 to rom_flash::@13 [phi:rom_flash::@17->rom_flash::@13]
    // [1453] phi rom_flash::bram_bank_sector#38 = rom_flash::bram_bank_sector#1 [phi:rom_flash::@17->rom_flash::@13#0] -- register_copy 
    // [1453] phi rom_flash::ram_address_sector#8 = (char *)$a000 [phi:rom_flash::@17->rom_flash::@13#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address_sector
    lda #>$a000
    sta.z ram_address_sector+1
    // [1453] phi from rom_flash::@4 to rom_flash::@13 [phi:rom_flash::@4->rom_flash::@13]
    // [1453] phi rom_flash::bram_bank_sector#38 = rom_flash::bram_bank_sector#14 [phi:rom_flash::@4->rom_flash::@13#0] -- register_copy 
    // [1453] phi rom_flash::ram_address_sector#8 = rom_flash::ram_address_sector#1 [phi:rom_flash::@4->rom_flash::@13#1] -- register_copy 
    // rom_flash::@13
  __b13:
    // if (ram_address_sector == RAM_HIGH)
    // [1454] if(rom_flash::ram_address_sector#8!=$8000) goto rom_flash::@44 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address_sector+1
    cmp #>$8000
    bne __b14
    lda.z ram_address_sector
    cmp #<$8000
    bne __b14
    // [1456] phi from rom_flash::@13 to rom_flash::@14 [phi:rom_flash::@13->rom_flash::@14]
    // [1456] phi rom_flash::ram_address_sector#15 = (char *)$a000 [phi:rom_flash::@13->rom_flash::@14#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address_sector
    lda #>$a000
    sta.z ram_address_sector+1
    // [1456] phi rom_flash::bram_bank_sector#12 = 1 [phi:rom_flash::@13->rom_flash::@14#1] -- vbum1=vbuc1 
    lda #1
    sta bram_bank_sector
    // [1455] phi from rom_flash::@13 to rom_flash::@44 [phi:rom_flash::@13->rom_flash::@44]
    // rom_flash::@44
    // [1456] phi from rom_flash::@44 to rom_flash::@14 [phi:rom_flash::@44->rom_flash::@14]
    // [1456] phi rom_flash::ram_address_sector#15 = rom_flash::ram_address_sector#8 [phi:rom_flash::@44->rom_flash::@14#0] -- register_copy 
    // [1456] phi rom_flash::bram_bank_sector#12 = rom_flash::bram_bank_sector#38 [phi:rom_flash::@44->rom_flash::@14#1] -- register_copy 
    // rom_flash::@14
  __b14:
    // x_sector += 8
    // [1457] rom_flash::x_sector#1 = rom_flash::x_sector#10 + 8 -- vbum1=vbum1_plus_vbuc1 
    lda #8
    clc
    adc x_sector
    sta x_sector
    // rom_address_sector % PROGRESS_ROW
    // [1458] rom_flash::$29 = rom_flash::rom_address_sector#1 & PROGRESS_ROW-1 -- vduz1=vdum2_band_vduc1 
    lda rom_address_sector
    and #<PROGRESS_ROW-1
    sta.z rom_flash__29
    lda rom_address_sector+1
    and #>PROGRESS_ROW-1
    sta.z rom_flash__29+1
    lda rom_address_sector+2
    and #<PROGRESS_ROW-1>>$10
    sta.z rom_flash__29+2
    lda rom_address_sector+3
    and #>PROGRESS_ROW-1>>$10
    sta.z rom_flash__29+3
    // if (!(rom_address_sector % PROGRESS_ROW))
    // [1459] if(0!=rom_flash::$29) goto rom_flash::@15 -- 0_neq_vduz1_then_la1 
    lda.z rom_flash__29
    ora.z rom_flash__29+1
    ora.z rom_flash__29+2
    ora.z rom_flash__29+3
    bne __b15
    // rom_flash::@18
    // y_sector++;
    // [1460] rom_flash::y_sector#1 = ++ rom_flash::y_sector#13 -- vbum1=_inc_vbum1 
    inc y_sector
    // [1461] phi from rom_flash::@18 to rom_flash::@15 [phi:rom_flash::@18->rom_flash::@15]
    // [1461] phi rom_flash::y_sector#18 = rom_flash::y_sector#1 [phi:rom_flash::@18->rom_flash::@15#0] -- register_copy 
    // [1461] phi rom_flash::x_sector#20 = PROGRESS_X [phi:rom_flash::@18->rom_flash::@15#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [1461] phi from rom_flash::@14 to rom_flash::@15 [phi:rom_flash::@14->rom_flash::@15]
    // [1461] phi rom_flash::y_sector#18 = rom_flash::y_sector#13 [phi:rom_flash::@14->rom_flash::@15#0] -- register_copy 
    // [1461] phi rom_flash::x_sector#20 = rom_flash::x_sector#1 [phi:rom_flash::@14->rom_flash::@15#1] -- register_copy 
    // rom_flash::@15
  __b15:
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1462] call snprintf_init
    jsr snprintf_init
    // rom_flash::@40
    // [1463] printf_ulong::uvalue#8 = rom_flash::flash_errors#13 -- vdum1=vdum2 
    lda flash_errors
    sta printf_ulong.uvalue
    lda flash_errors+1
    sta printf_ulong.uvalue+1
    lda flash_errors+2
    sta printf_ulong.uvalue+2
    lda flash_errors+3
    sta printf_ulong.uvalue+3
    // [1464] call printf_ulong
    // [1413] phi from rom_flash::@40 to printf_ulong [phi:rom_flash::@40->printf_ulong]
    // [1413] phi printf_ulong::format_zero_padding#11 = 0 [phi:rom_flash::@40->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1413] phi printf_ulong::format_min_length#11 = 0 [phi:rom_flash::@40->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1413] phi printf_ulong::putc#11 = &snputc [phi:rom_flash::@40->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1413] phi printf_ulong::format_radix#11 = DECIMAL [phi:rom_flash::@40->printf_ulong#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1413] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#8 [phi:rom_flash::@40->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1465] phi from rom_flash::@40 to rom_flash::@41 [phi:rom_flash::@40->rom_flash::@41]
    // rom_flash::@41
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1466] call printf_str
    // [745] phi from rom_flash::@41 to printf_str [phi:rom_flash::@41->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:rom_flash::@41->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = rom_flash::s6 [phi:rom_flash::@41->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@42
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1467] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1468] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom(rom_chip, STATUS_FLASHING, info_text)
    // [1470] info_rom::rom_chip#3 = rom_flash::rom_chip#0 -- vbuz1=vbuz2 
    lda.z rom_chip
    sta.z info_rom.rom_chip
    // [1471] call info_rom
    // [1187] phi from rom_flash::@42 to info_rom [phi:rom_flash::@42->info_rom]
    // [1187] phi info_rom::info_text#16 = info_text [phi:rom_flash::@42->info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_rom.info_text
    lda #>@info_text
    sta.z info_rom.info_text+1
    // [1187] phi info_rom::rom_chip#16 = info_rom::rom_chip#3 [phi:rom_flash::@42->info_rom#1] -- register_copy 
    // [1187] phi info_rom::info_status#16 = STATUS_FLASHING [phi:rom_flash::@42->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHING
    sta.z info_rom.info_status
    jsr info_rom
    // [1433] phi from rom_flash::@42 to rom_flash::@1 [phi:rom_flash::@42->rom_flash::@1]
    // [1433] phi rom_flash::y_sector#13 = rom_flash::y_sector#18 [phi:rom_flash::@42->rom_flash::@1#0] -- register_copy 
    // [1433] phi rom_flash::x_sector#10 = rom_flash::x_sector#20 [phi:rom_flash::@42->rom_flash::@1#1] -- register_copy 
    // [1433] phi rom_flash::flash_errors#10 = rom_flash::flash_errors#13 [phi:rom_flash::@42->rom_flash::@1#2] -- register_copy 
    // [1433] phi rom_flash::ram_address_sector#11 = rom_flash::ram_address_sector#15 [phi:rom_flash::@42->rom_flash::@1#3] -- register_copy 
    // [1433] phi rom_flash::bram_bank_sector#14 = rom_flash::bram_bank_sector#12 [phi:rom_flash::@42->rom_flash::@1#4] -- register_copy 
    // [1433] phi rom_flash::rom_address_sector#12 = rom_flash::rom_address_sector#1 [phi:rom_flash::@42->rom_flash::@1#5] -- register_copy 
    jmp __b1
    // [1472] phi from rom_flash::@21 to rom_flash::@5 [phi:rom_flash::@21->rom_flash::@5]
  __b3:
    // [1472] phi rom_flash::retries#12 = 0 [phi:rom_flash::@21->rom_flash::@5#0] -- vbum1=vbuc1 
    lda #0
    sta retries
    // [1472] phi rom_flash::flash_errors_sector#11 = 0 [phi:rom_flash::@21->rom_flash::@5#1] -- vwum1=vwuc1 
    sta flash_errors_sector
    sta flash_errors_sector+1
    // [1472] phi from rom_flash::@43 to rom_flash::@5 [phi:rom_flash::@43->rom_flash::@5]
    // [1472] phi rom_flash::retries#12 = rom_flash::retries#1 [phi:rom_flash::@43->rom_flash::@5#0] -- register_copy 
    // [1472] phi rom_flash::flash_errors_sector#11 = rom_flash::flash_errors_sector#10 [phi:rom_flash::@43->rom_flash::@5#1] -- register_copy 
    // rom_flash::@5
  __b5:
    // rom_sector_erase(rom_address_sector)
    // [1473] rom_sector_erase::address#0 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_sector_erase.address
    lda rom_address_sector+1
    sta.z rom_sector_erase.address+1
    lda rom_address_sector+2
    sta.z rom_sector_erase.address+2
    lda rom_address_sector+3
    sta.z rom_sector_erase.address+3
    // [1474] call rom_sector_erase
    // [2244] phi from rom_flash::@5 to rom_sector_erase [phi:rom_flash::@5->rom_sector_erase]
    jsr rom_sector_erase
    // rom_flash::@22
    // unsigned long rom_sector_boundary = rom_address_sector + ROM_SECTOR
    // [1475] rom_flash::rom_sector_boundary#0 = rom_flash::rom_address_sector#12 + $1000 -- vdum1=vdum2_plus_vwuc1 
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
    // [1476] gotoxy::x#28 = rom_flash::x_sector#10 -- vbum1=vbum2 
    lda x_sector
    sta gotoxy.x
    // [1477] gotoxy::y#28 = rom_flash::y_sector#13 -- vbum1=vbum2 
    lda y_sector
    sta gotoxy.y
    // [1478] call gotoxy
    // [602] phi from rom_flash::@22 to gotoxy [phi:rom_flash::@22->gotoxy]
    // [602] phi gotoxy::y#30 = gotoxy::y#28 [phi:rom_flash::@22->gotoxy#0] -- register_copy 
    // [602] phi gotoxy::x#30 = gotoxy::x#28 [phi:rom_flash::@22->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1479] phi from rom_flash::@22 to rom_flash::@23 [phi:rom_flash::@22->rom_flash::@23]
    // rom_flash::@23
    // printf("........")
    // [1480] call printf_str
    // [745] phi from rom_flash::@23 to printf_str [phi:rom_flash::@23->printf_str]
    // [745] phi printf_str::putc#71 = &cputc [phi:rom_flash::@23->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = rom_flash::s1 [phi:rom_flash::@23->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@24
    // [1481] rom_flash::rom_address#26 = rom_flash::rom_address_sector#12 -- vdum1=vdum2 
    lda rom_address_sector
    sta rom_address
    lda rom_address_sector+1
    sta rom_address+1
    lda rom_address_sector+2
    sta rom_address+2
    lda rom_address_sector+3
    sta rom_address+3
    // [1482] rom_flash::ram_address#26 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z ram_address
    lda.z ram_address_sector+1
    sta.z ram_address+1
    // [1483] rom_flash::x#26 = rom_flash::x_sector#10 -- vbum1=vbum2 
    lda x_sector
    sta x
    // [1484] phi from rom_flash::@10 rom_flash::@24 to rom_flash::@6 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6]
    // [1484] phi rom_flash::x#10 = rom_flash::x#1 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#0] -- register_copy 
    // [1484] phi rom_flash::ram_address#10 = rom_flash::ram_address#1 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#1] -- register_copy 
    // [1484] phi rom_flash::flash_errors_sector#10 = rom_flash::flash_errors_sector#8 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#2] -- register_copy 
    // [1484] phi rom_flash::rom_address#11 = rom_flash::rom_address#1 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#3] -- register_copy 
    // rom_flash::@6
  __b6:
    // while (rom_address < rom_sector_boundary)
    // [1485] if(rom_flash::rom_address#11<rom_flash::rom_sector_boundary#0) goto rom_flash::@7 -- vdum1_lt_vdum2_then_la1 
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
    // [1486] rom_flash::retries#1 = ++ rom_flash::retries#12 -- vbum1=_inc_vbum1 
    inc retries
    // while (flash_errors_sector && retries <= 3)
    // [1487] if(0==rom_flash::flash_errors_sector#10) goto rom_flash::@12 -- 0_eq_vwum1_then_la1 
    lda flash_errors_sector
    ora flash_errors_sector+1
    beq __b12
    // rom_flash::@43
    // [1488] if(rom_flash::retries#1<3+1) goto rom_flash::@5 -- vbum1_lt_vbuc1_then_la1 
    lda retries
    cmp #3+1
    bcs !__b5+
    jmp __b5
  !__b5:
    // rom_flash::@12
  __b12:
    // flash_errors += flash_errors_sector
    // [1489] rom_flash::flash_errors#1 = rom_flash::flash_errors#10 + rom_flash::flash_errors_sector#10 -- vdum1=vdum1_plus_vwum2 
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
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1490] printf_ulong::uvalue#7 = rom_flash::flash_errors_sector#10 + rom_flash::flash_errors#10 -- vdum1=vwum2_plus_vdum3 
    lda flash_errors
    clc
    adc flash_errors_sector
    sta printf_ulong.uvalue_1
    lda flash_errors+1
    adc flash_errors_sector+1
    sta printf_ulong.uvalue_1+1
    lda flash_errors+2
    adc #0
    sta printf_ulong.uvalue_1+2
    lda flash_errors+3
    adc #0
    sta printf_ulong.uvalue_1+3
    // [1491] call snprintf_init
    jsr snprintf_init
    // [1492] phi from rom_flash::@7 to rom_flash::@25 [phi:rom_flash::@7->rom_flash::@25]
    // rom_flash::@25
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1493] call printf_str
    // [745] phi from rom_flash::@25 to printf_str [phi:rom_flash::@25->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:rom_flash::@25->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = rom_flash::s2 [phi:rom_flash::@25->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@26
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1494] printf_uchar::uvalue#7 = rom_flash::bram_bank_sector#14 -- vbum1=vbum2 
    lda bram_bank_sector
    sta printf_uchar.uvalue
    // [1495] call printf_uchar
    // [1162] phi from rom_flash::@26 to printf_uchar [phi:rom_flash::@26->printf_uchar]
    // [1162] phi printf_uchar::format_zero_padding#11 = 1 [phi:rom_flash::@26->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1162] phi printf_uchar::format_min_length#11 = 2 [phi:rom_flash::@26->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1162] phi printf_uchar::putc#11 = &snputc [phi:rom_flash::@26->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1162] phi printf_uchar::format_radix#11 = HEXADECIMAL [phi:rom_flash::@26->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1162] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#7 [phi:rom_flash::@26->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1496] phi from rom_flash::@26 to rom_flash::@27 [phi:rom_flash::@26->rom_flash::@27]
    // rom_flash::@27
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1497] call printf_str
    // [745] phi from rom_flash::@27 to printf_str [phi:rom_flash::@27->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:rom_flash::@27->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = s3 [phi:rom_flash::@27->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@28
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1498] printf_uint::uvalue#12 = (unsigned int)rom_flash::ram_address_sector#11 -- vwum1=vwuz2 
    lda.z ram_address_sector
    sta printf_uint.uvalue
    lda.z ram_address_sector+1
    sta printf_uint.uvalue+1
    // [1499] call printf_uint
    // [754] phi from rom_flash::@28 to printf_uint [phi:rom_flash::@28->printf_uint]
    // [754] phi printf_uint::format_zero_padding#16 = 1 [phi:rom_flash::@28->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [754] phi printf_uint::format_min_length#16 = 4 [phi:rom_flash::@28->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [754] phi printf_uint::putc#16 = &snputc [phi:rom_flash::@28->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [754] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:rom_flash::@28->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [754] phi printf_uint::uvalue#16 = printf_uint::uvalue#12 [phi:rom_flash::@28->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1500] phi from rom_flash::@28 to rom_flash::@29 [phi:rom_flash::@28->rom_flash::@29]
    // rom_flash::@29
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1501] call printf_str
    // [745] phi from rom_flash::@29 to printf_str [phi:rom_flash::@29->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:rom_flash::@29->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = rom_flash::s4 [phi:rom_flash::@29->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@30
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1502] printf_ulong::uvalue#6 = rom_flash::rom_address_sector#12 -- vdum1=vdum2 
    lda rom_address_sector
    sta printf_ulong.uvalue
    lda rom_address_sector+1
    sta printf_ulong.uvalue+1
    lda rom_address_sector+2
    sta printf_ulong.uvalue+2
    lda rom_address_sector+3
    sta printf_ulong.uvalue+3
    // [1503] call printf_ulong
    // [1413] phi from rom_flash::@30 to printf_ulong [phi:rom_flash::@30->printf_ulong]
    // [1413] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_flash::@30->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1413] phi printf_ulong::format_min_length#11 = 5 [phi:rom_flash::@30->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1413] phi printf_ulong::putc#11 = &snputc [phi:rom_flash::@30->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1413] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_flash::@30->printf_ulong#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1413] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#6 [phi:rom_flash::@30->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1504] phi from rom_flash::@30 to rom_flash::@31 [phi:rom_flash::@30->rom_flash::@31]
    // rom_flash::@31
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1505] call printf_str
    // [745] phi from rom_flash::@31 to printf_str [phi:rom_flash::@31->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:rom_flash::@31->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = rom_flash::s5 [phi:rom_flash::@31->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@32
    // [1506] printf_ulong::uvalue#20 = printf_ulong::uvalue#7 -- vdum1=vdum2 
    lda printf_ulong.uvalue_1
    sta printf_ulong.uvalue
    lda printf_ulong.uvalue_1+1
    sta printf_ulong.uvalue+1
    lda printf_ulong.uvalue_1+2
    sta printf_ulong.uvalue+2
    lda printf_ulong.uvalue_1+3
    sta printf_ulong.uvalue+3
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1507] call printf_ulong
    // [1413] phi from rom_flash::@32 to printf_ulong [phi:rom_flash::@32->printf_ulong]
    // [1413] phi printf_ulong::format_zero_padding#11 = 0 [phi:rom_flash::@32->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1413] phi printf_ulong::format_min_length#11 = 0 [phi:rom_flash::@32->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1413] phi printf_ulong::putc#11 = &snputc [phi:rom_flash::@32->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1413] phi printf_ulong::format_radix#11 = DECIMAL [phi:rom_flash::@32->printf_ulong#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1413] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#20 [phi:rom_flash::@32->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1508] phi from rom_flash::@32 to rom_flash::@33 [phi:rom_flash::@32->rom_flash::@33]
    // rom_flash::@33
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1509] call printf_str
    // [745] phi from rom_flash::@33 to printf_str [phi:rom_flash::@33->printf_str]
    // [745] phi printf_str::putc#71 = &snputc [phi:rom_flash::@33->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [745] phi printf_str::s#71 = rom_flash::s6 [phi:rom_flash::@33->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@34
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1510] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1511] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_line(info_text)
    // [1513] call display_info_line
    // [976] phi from rom_flash::@34 to display_info_line [phi:rom_flash::@34->display_info_line]
    // [976] phi display_info_line::info_text#19 = info_text [phi:rom_flash::@34->display_info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_line.info_text
    lda #>@info_text
    sta.z display_info_line.info_text+1
    jsr display_info_line
    // rom_flash::@35
    // unsigned long written_bytes = rom_write(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1514] rom_write::flash_ram_bank#0 = rom_flash::bram_bank_sector#14 -- vbuz1=vbum2 
    lda bram_bank_sector
    sta.z rom_write.flash_ram_bank
    // [1515] rom_write::flash_ram_address#1 = rom_flash::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_write.flash_ram_address
    lda.z ram_address+1
    sta.z rom_write.flash_ram_address+1
    // [1516] rom_write::flash_rom_address#1 = rom_flash::rom_address#11 -- vduz1=vdum2 
    lda rom_address
    sta.z rom_write.flash_rom_address
    lda rom_address+1
    sta.z rom_write.flash_rom_address+1
    lda rom_address+2
    sta.z rom_write.flash_rom_address+2
    lda rom_address+3
    sta.z rom_write.flash_rom_address+3
    // [1517] call rom_write
    jsr rom_write
    // rom_flash::@36
    // rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1518] rom_compare::bank_ram#2 = rom_flash::bram_bank_sector#14 -- vbuz1=vbum2 
    lda bram_bank_sector
    sta.z rom_compare.bank_ram_2
    // [1519] rom_compare::ptr_ram#3 = rom_flash::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_compare.ptr_ram
    lda.z ram_address+1
    sta.z rom_compare.ptr_ram+1
    // [1520] rom_compare::rom_compare_address#2 = rom_flash::rom_address#11 -- vduz1=vdum2 
    lda rom_address
    sta.z rom_compare.rom_compare_address
    lda rom_address+1
    sta.z rom_compare.rom_compare_address+1
    lda rom_address+2
    sta.z rom_compare.rom_compare_address+2
    lda rom_address+3
    sta.z rom_compare.rom_compare_address+3
    // [1521] call rom_compare
    // [2188] phi from rom_flash::@36 to rom_compare [phi:rom_flash::@36->rom_compare]
    // [2188] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#3 [phi:rom_flash::@36->rom_compare#0] -- register_copy 
    // [2188] phi rom_compare::rom_compare_size#11 = PROGRESS_CELL [phi:rom_flash::@36->rom_compare#1] -- vwuz1=vwuc1 
    lda #<PROGRESS_CELL
    sta.z rom_compare.rom_compare_size
    lda #>PROGRESS_CELL
    sta.z rom_compare.rom_compare_size+1
    // [2188] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#2 [phi:rom_flash::@36->rom_compare#2] -- register_copy 
    // [2188] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#2 [phi:rom_flash::@36->rom_compare#3] -- vbum1=vbuz2 
    lda.z rom_compare.bank_ram_2
    sta rom_compare.bank_set_bram1_bank
    jsr rom_compare
    // rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1522] rom_compare::return#4 = rom_compare::equal_bytes#2
    // rom_flash::@37
    // equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1523] rom_flash::equal_bytes#1 = rom_compare::return#4 -- vwum1=vwum2 
    lda rom_compare.return
    sta equal_bytes_1
    lda rom_compare.return+1
    sta equal_bytes_1+1
    // gotoxy(x, y)
    // [1524] gotoxy::x#29 = rom_flash::x#10 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1525] gotoxy::y#29 = rom_flash::y_sector#13 -- vbum1=vbum2 
    lda y_sector
    sta gotoxy.y
    // [1526] call gotoxy
    // [602] phi from rom_flash::@37 to gotoxy [phi:rom_flash::@37->gotoxy]
    // [602] phi gotoxy::y#30 = gotoxy::y#29 [phi:rom_flash::@37->gotoxy#0] -- register_copy 
    // [602] phi gotoxy::x#30 = gotoxy::x#29 [phi:rom_flash::@37->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_flash::@38
    // if (equal_bytes != PROGRESS_CELL)
    // [1527] if(rom_flash::equal_bytes#1!=PROGRESS_CELL) goto rom_flash::@9 -- vwum1_neq_vwuc1_then_la1 
    lda equal_bytes_1+1
    cmp #>PROGRESS_CELL
    bne __b9
    lda equal_bytes_1
    cmp #<PROGRESS_CELL
    bne __b9
    // rom_flash::@11
    // cputcxy(x,y,'+')
    // [1528] cputcxy::x#14 = rom_flash::x#10 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1529] cputcxy::y#14 = rom_flash::y_sector#13 -- vbum1=vbum2 
    lda y_sector
    sta cputcxy.y
    // [1530] call cputcxy
    // [1787] phi from rom_flash::@11 to cputcxy [phi:rom_flash::@11->cputcxy]
    // [1787] phi cputcxy::c#15 = '+' [phi:rom_flash::@11->cputcxy#0] -- vbum1=vbuc1 
    lda #'+'
    sta cputcxy.c
    // [1787] phi cputcxy::y#15 = cputcxy::y#14 [phi:rom_flash::@11->cputcxy#1] -- register_copy 
    // [1787] phi cputcxy::x#15 = cputcxy::x#14 [phi:rom_flash::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [1531] phi from rom_flash::@11 rom_flash::@39 to rom_flash::@10 [phi:rom_flash::@11/rom_flash::@39->rom_flash::@10]
    // [1531] phi rom_flash::flash_errors_sector#8 = rom_flash::flash_errors_sector#10 [phi:rom_flash::@11/rom_flash::@39->rom_flash::@10#0] -- register_copy 
    // rom_flash::@10
  __b10:
    // ram_address += PROGRESS_CELL
    // [1532] rom_flash::ram_address#1 = rom_flash::ram_address#10 + PROGRESS_CELL -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address
    clc
    adc #<PROGRESS_CELL
    sta.z ram_address
    lda.z ram_address+1
    adc #>PROGRESS_CELL
    sta.z ram_address+1
    // rom_address += PROGRESS_CELL
    // [1533] rom_flash::rom_address#1 = rom_flash::rom_address#11 + PROGRESS_CELL -- vdum1=vdum1_plus_vwuc1 
    clc
    lda rom_address
    adc #<PROGRESS_CELL
    sta rom_address
    lda rom_address+1
    adc #>PROGRESS_CELL
    sta rom_address+1
    lda rom_address+2
    adc #0
    sta rom_address+2
    lda rom_address+3
    adc #0
    sta rom_address+3
    // x++;
    // [1534] rom_flash::x#1 = ++ rom_flash::x#10 -- vbum1=_inc_vbum1 
    inc x
    jmp __b6
    // rom_flash::@9
  __b9:
    // cputcxy(x,y,'!')
    // [1535] cputcxy::x#13 = rom_flash::x#10 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1536] cputcxy::y#13 = rom_flash::y_sector#13 -- vbum1=vbum2 
    lda y_sector
    sta cputcxy.y
    // [1537] call cputcxy
    // [1787] phi from rom_flash::@9 to cputcxy [phi:rom_flash::@9->cputcxy]
    // [1787] phi cputcxy::c#15 = '!' [phi:rom_flash::@9->cputcxy#0] -- vbum1=vbuc1 
    lda #'!'
    sta cputcxy.c
    // [1787] phi cputcxy::y#15 = cputcxy::y#13 [phi:rom_flash::@9->cputcxy#1] -- register_copy 
    // [1787] phi cputcxy::x#15 = cputcxy::x#13 [phi:rom_flash::@9->cputcxy#2] -- register_copy 
    jsr cputcxy
    // rom_flash::@39
    // flash_errors_sector++;
    // [1538] rom_flash::flash_errors_sector#1 = ++ rom_flash::flash_errors_sector#10 -- vwum1=_inc_vwum1 
    inc flash_errors_sector
    bne !+
    inc flash_errors_sector+1
  !:
    jmp __b10
  .segment Data
    info_text: .text "Flashing ... (-) equal, (+) flashed, (!) error."
    .byte 0
    info_text1: .text "Flashing ..."
    .byte 0
    info_text2: .text "Flashed ..."
    .byte 0
    s: .text "--------"
    .byte 0
    s1: .text "........"
    .byte 0
    s2: .text "Flashing ... RAM:"
    .byte 0
    s4: .text " -> ROM:"
    .byte 0
    s5: .text " ... "
    .byte 0
    s6: .text " flash errors ..."
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
    bram_bank_sector: .byte 0
    x_sector: .byte 0
    y_sector: .byte 0
    .label return = flash_errors
}
.segment Code
  // strchr
// Searches for the first occurrence of the character c (an unsigned char) in the string pointed to, by the argument str.
// - str: The memory to search
// - c: A character to search for
// Return: A pointer to the matching byte or NULL if the character does not occur in the given memory area.
// __zp($62) void * strchr(__zp($62) const void *str, __mem() char c)
strchr: {
    .label ptr = $62
    .label return = $62
    .label str = $62
    // [1540] strchr::ptr#6 = (char *)strchr::str#2
    // [1541] phi from strchr strchr::@3 to strchr::@1 [phi:strchr/strchr::@3->strchr::@1]
    // [1541] phi strchr::ptr#2 = strchr::ptr#6 [phi:strchr/strchr::@3->strchr::@1#0] -- register_copy 
    // strchr::@1
  __b1:
    // while(*ptr)
    // [1542] if(0!=*strchr::ptr#2) goto strchr::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (ptr),y
    cmp #0
    bne __b2
    // [1543] phi from strchr::@1 to strchr::@return [phi:strchr::@1->strchr::@return]
    // [1543] phi strchr::return#2 = (void *) 0 [phi:strchr::@1->strchr::@return#0] -- pvoz1=pvoc1 
    tya
    sta.z return
    sta.z return+1
    // strchr::@return
    // }
    // [1544] return 
    rts
    // strchr::@2
  __b2:
    // if(*ptr==c)
    // [1545] if(*strchr::ptr#2!=strchr::c#4) goto strchr::@3 -- _deref_pbuz1_neq_vbum2_then_la1 
    ldy #0
    lda (ptr),y
    cmp c
    bne __b3
    // strchr::@4
    // [1546] strchr::return#8 = (void *)strchr::ptr#2
    // [1543] phi from strchr::@4 to strchr::@return [phi:strchr::@4->strchr::@return]
    // [1543] phi strchr::return#2 = strchr::return#8 [phi:strchr::@4->strchr::@return#0] -- register_copy 
    rts
    // strchr::@3
  __b3:
    // ptr++;
    // [1547] strchr::ptr#1 = ++ strchr::ptr#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr
    bne !+
    inc.z ptr+1
  !:
    jmp __b1
  .segment Data
    c: .byte 0
}
.segment Code
  // info_cx16_rom
/**
 * @brief 
 * 
 * @param info_status 
 * @param info_text 
 */
// void info_cx16_rom(char info_status, char *info_text)
info_cx16_rom: {
    .label info_text = 0
    // info_rom(0, info_status, info_text)
    // [1549] call info_rom
    // [1187] phi from info_cx16_rom to info_rom [phi:info_cx16_rom->info_rom]
    // [1187] phi info_rom::info_text#16 = info_cx16_rom::info_text#0 [phi:info_cx16_rom->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_rom.info_text
    lda #>info_text
    sta.z info_rom.info_text+1
    // [1187] phi info_rom::rom_chip#16 = 0 [phi:info_cx16_rom->info_rom#1] -- vbuz1=vbuc1 
    lda #0
    sta.z info_rom.rom_chip
    // [1187] phi info_rom::info_status#16 = STATUS_ISSUE [phi:info_cx16_rom->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z info_rom.info_status
    jsr info_rom
    // info_cx16_rom::@return
    // }
    // [1550] return 
    rts
}
  // strncpy
/// Copies up to n characters from the string pointed to, by src to dst.
/// In a case where the length of src is less than that of n, the remainder of dst will be padded with null bytes.
/// @param dst ? This is the pointer to the destination array where the content is to be copied.
/// @param src ? This is the string to be copied.
/// @param n ? The number of characters to be copied from source.
/// @return The destination
// char * strncpy(__zp($2d) char *dst, __zp($55) const char *src, __mem() unsigned int n)
strncpy: {
    .label dst = $2d
    .label src = $55
    // [1552] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [1552] phi strncpy::dst#3 = strncpy::dst#8 [phi:strncpy->strncpy::@1#0] -- register_copy 
    // [1552] phi strncpy::src#3 = strncpy::src#6 [phi:strncpy->strncpy::@1#1] -- register_copy 
    // [1552] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwum1=vwuc1 
    lda #<0
    sta i
    sta i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [1553] if(strncpy::i#2<strncpy::n#3) goto strncpy::@2 -- vwum1_lt_vwum2_then_la1 
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
    // [1554] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [1555] strncpy::c#0 = *strncpy::src#3 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta c
    // if(c)
    // [1556] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbum1_then_la1 
    beq __b3
    // strncpy::@4
    // src++;
    // [1557] strncpy::src#0 = ++ strncpy::src#3 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [1558] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [1558] phi strncpy::src#7 = strncpy::src#3 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [1559] *strncpy::dst#3 = strncpy::c#0 -- _deref_pbuz1=vbum2 
    lda c
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [1560] strncpy::dst#0 = ++ strncpy::dst#3 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [1561] strncpy::i#1 = ++ strncpy::i#2 -- vwum1=_inc_vwum1 
    inc i
    bne !+
    inc i+1
  !:
    // [1552] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [1552] phi strncpy::dst#3 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [1552] phi strncpy::src#3 = strncpy::src#7 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [1552] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
    jmp __b1
  .segment Data
    c: .byte 0
    i: .word 0
    n: .word 0
}
.segment Code
  // print_info_led
// void print_info_led(__zp($75) char x, __zp($78) char y, __zp($76) char tc, char bc)
print_info_led: {
    .label tc = $76
    .label y = $78
    .label x = $75
    // textcolor(tc)
    // [1563] textcolor::color#13 = print_info_led::tc#4 -- vbum1=vbuz2 
    lda.z tc
    sta textcolor.color
    // [1564] call textcolor
    // [584] phi from print_info_led to textcolor [phi:print_info_led->textcolor]
    // [584] phi textcolor::color#18 = textcolor::color#13 [phi:print_info_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [1565] phi from print_info_led to print_info_led::@1 [phi:print_info_led->print_info_led::@1]
    // print_info_led::@1
    // bgcolor(bc)
    // [1566] call bgcolor
    // [589] phi from print_info_led::@1 to bgcolor [phi:print_info_led::@1->bgcolor]
    // [589] phi bgcolor::color#14 = BLUE [phi:print_info_led::@1->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // print_info_led::@2
    // cputcxy(x, y, VERA_CHR_UR)
    // [1567] cputcxy::x#11 = print_info_led::x#4 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [1568] cputcxy::y#11 = print_info_led::y#4 -- vbum1=vbuz2 
    lda.z y
    sta cputcxy.y
    // [1569] call cputcxy
    // [1787] phi from print_info_led::@2 to cputcxy [phi:print_info_led::@2->cputcxy]
    // [1787] phi cputcxy::c#15 = $7c [phi:print_info_led::@2->cputcxy#0] -- vbum1=vbuc1 
    lda #$7c
    sta cputcxy.c
    // [1787] phi cputcxy::y#15 = cputcxy::y#11 [phi:print_info_led::@2->cputcxy#1] -- register_copy 
    // [1787] phi cputcxy::x#15 = cputcxy::x#11 [phi:print_info_led::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [1570] phi from print_info_led::@2 to print_info_led::@3 [phi:print_info_led::@2->print_info_led::@3]
    // print_info_led::@3
    // textcolor(WHITE)
    // [1571] call textcolor
    // [584] phi from print_info_led::@3 to textcolor [phi:print_info_led::@3->textcolor]
    // [584] phi textcolor::color#18 = WHITE [phi:print_info_led::@3->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // print_info_led::@return
    // }
    // [1572] return 
    rts
}
  // screenlayer
// --- layer management in VERA ---
// void screenlayer(char layer, __mem() char mapbase, __mem() char config)
screenlayer: {
    .label screenlayer__0 = $72
    .label screenlayer__1 = $71
    .label screenlayer__2 = $d0
    .label screenlayer__5 = $cc
    .label screenlayer__6 = $cc
    .label screenlayer__7 = $cb
    .label screenlayer__8 = $cb
    .label screenlayer__9 = $c9
    .label screenlayer__10 = $c9
    .label screenlayer__11 = $c9
    .label screenlayer__12 = $ca
    .label screenlayer__13 = $ca
    .label screenlayer__14 = $ca
    .label screenlayer__16 = $cb
    .label screenlayer__17 = $c6
    .label screenlayer__18 = $c9
    .label screenlayer__19 = $ca
    .label y = $c4
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [1573] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [1574] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [1575] *((char *)&__conio+2) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+2
    // mapbase >> 7
    // [1576] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbuz1=vbum2_ror_7 
    lda mapbase
    rol
    rol
    and #1
    sta.z screenlayer__0
    // __conio.mapbase_bank = mapbase >> 7
    // [1577] *((char *)&__conio+5) = screenlayer::$0 -- _deref_pbuc1=vbuz1 
    sta __conio+5
    // (mapbase)<<1
    // [1578] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbuz1=vbum2_rol_1 
    lda mapbase
    asl
    sta.z screenlayer__1
    // MAKEWORD((mapbase)<<1,0)
    // [1579] screenlayer::$2 = screenlayer::$1 w= 0 -- vwuz1=vbuz2_word_vbuc1 
    lda #0
    ldy.z screenlayer__1
    sty.z screenlayer__2+1
    sta.z screenlayer__2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [1580] *((unsigned int *)&__conio+3) = screenlayer::$2 -- _deref_pwuc1=vwuz1 
    sta __conio+3
    tya
    sta __conio+3+1
    // config & VERA_LAYER_WIDTH_MASK
    // [1581] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbuz1=vbum2_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and config
    sta.z screenlayer__7
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [1582] screenlayer::$8 = screenlayer::$7 >> 4 -- vbuz1=vbuz1_ror_4 
    lda.z screenlayer__8
    lsr
    lsr
    lsr
    lsr
    sta.z screenlayer__8
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [1583] *((char *)&__conio+8) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+8
    // config & VERA_LAYER_HEIGHT_MASK
    // [1584] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbuz1=vbum2_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and config
    sta.z screenlayer__5
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [1585] screenlayer::$6 = screenlayer::$5 >> 6 -- vbuz1=vbuz1_ror_6 
    lda.z screenlayer__6
    rol
    rol
    rol
    and #3
    sta.z screenlayer__6
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [1586] *((char *)&__conio+9) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+9
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [1587] screenlayer::$16 = screenlayer::$8 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z screenlayer__16
    // [1588] *((unsigned int *)&__conio+$a) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    ldy.z screenlayer__16
    lda VERA_LAYER_SKIP,y
    sta __conio+$a
    lda VERA_LAYER_SKIP+1,y
    sta __conio+$a+1
    // vera_dc_hscale_temp == 0x80
    // [1589] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_hscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z screenlayer__9
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [1590] screenlayer::$18 = (char)screenlayer::$9
    // [1591] screenlayer::$10 = $28 << screenlayer::$18 -- vbuz1=vbuc1_rol_vbuz1 
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
    // [1592] screenlayer::$11 = screenlayer::$10 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z screenlayer__11
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [1593] *((char *)&__conio+6) = screenlayer::$11 -- _deref_pbuc1=vbuz1 
    lda.z screenlayer__11
    sta __conio+6
    // vera_dc_vscale_temp == 0x80
    // [1594] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_vscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z screenlayer__12
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [1595] screenlayer::$19 = (char)screenlayer::$12
    // [1596] screenlayer::$13 = $1e << screenlayer::$19 -- vbuz1=vbuc1_rol_vbuz1 
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
    // [1597] screenlayer::$14 = screenlayer::$13 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z screenlayer__14
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [1598] *((char *)&__conio+7) = screenlayer::$14 -- _deref_pbuc1=vbuz1 
    lda.z screenlayer__14
    sta __conio+7
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [1599] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta mapbase_offset
    lda __conio+3+1
    sta mapbase_offset+1
    // [1600] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [1600] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [1600] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [1601] if(screenlayer::y#2<=*((char *)&__conio+7)) goto screenlayer::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+7
    cmp.z y
    bcs __b2
    // screenlayer::@return
    // }
    // [1602] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [1603] screenlayer::$17 = screenlayer::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z screenlayer__17
    // [1604] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbuz1=vwum2 
    tay
    lda mapbase_offset
    sta __conio+$15,y
    lda mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [1605] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda mapbase_offset
    adc __conio+$a
    sta mapbase_offset
    lda mapbase_offset+1
    adc __conio+$a+1
    sta mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [1606] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [1600] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [1600] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [1600] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
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
    // [1607] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [1608] if(0!=((char *)&__conio+$f)[*((char *)&__conio+2)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [1609] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // [1610] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [1611] call gotoxy
    // [602] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [602] phi gotoxy::y#30 = 0 [phi:cscroll::@3->gotoxy#0] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.y
    // [602] phi gotoxy::x#30 = 0 [phi:cscroll::@3->gotoxy#1] -- vbum1=vbuc1 
    sta gotoxy.x
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [1612] return 
    rts
    // [1613] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [1614] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [1615] gotoxy::y#3 = *((char *)&__conio+7) -- vbum1=_deref_pbuc1 
    lda __conio+7
    sta gotoxy.y
    // [1616] call gotoxy
    // [602] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [602] phi gotoxy::y#30 = gotoxy::y#3 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [602] phi gotoxy::x#30 = 0 [phi:cscroll::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.x
    jsr gotoxy
    // [1617] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [1618] call clearline
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
    // [1619] ((char *)&__conio+$f)[*((char *)&__conio+2)] = scroll::onoff#0 -- pbuc1_derefidx_(_deref_pbuc2)=vbuc3 
    lda #onoff
    ldy __conio+2
    sta __conio+$f,y
    // scroll::@return
    // }
    // [1620] return 
    rts
}
  // clrscr
// clears the screen and moves the cursor to the upper left-hand corner of the screen.
clrscr: {
    .label clrscr__0 = $46
    .label clrscr__1 = $2b
    .label clrscr__2 = $47
    // unsigned int line_text = __conio.mapbase_offset
    // [1621] clrscr::line_text#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta line_text
    lda __conio+3+1
    sta line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1622] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [1623] clrscr::$0 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clrscr__0
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1624] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [1625] clrscr::l#0 = *((char *)&__conio+9) -- vbum1=_deref_pbuc1 
    lda __conio+9
    sta l
    // [1626] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [1626] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [1626] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [1627] clrscr::$1 = byte0  clrscr::ch#0 -- vbuz1=_byte0_vwum2 
    lda ch
    sta.z clrscr__1
    // *VERA_ADDRX_L = BYTE0(ch)
    // [1628] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbuz1 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [1629] clrscr::$2 = byte1  clrscr::ch#0 -- vbuz1=_byte1_vwum2 
    lda ch+1
    sta.z clrscr__2
    // *VERA_ADDRX_M = BYTE1(ch)
    // [1630] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth+1
    // [1631] clrscr::c#0 = *((char *)&__conio+8) + 1 -- vbum1=_deref_pbuc1_plus_1 
    lda __conio+8
    inc
    sta c
    // [1632] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [1632] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [1633] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1634] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [1635] clrscr::c#1 = -- clrscr::c#2 -- vbum1=_dec_vbum1 
    dec c
    // while(c)
    // [1636] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [1637] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda line_text
    adc __conio+$a
    sta line_text
    lda line_text+1
    adc __conio+$a+1
    sta line_text+1
    // l--;
    // [1638] clrscr::l#1 = -- clrscr::l#4 -- vbum1=_dec_vbum1 
    dec l
    // while(l)
    // [1639] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbum1_then_la1 
    lda l
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [1640] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y = 0
    // [1641] *((char *)&__conio+1) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+1
    // __conio.offset = __conio.mapbase_offset
    // [1642] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+3) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+3
    sta __conio+$13
    lda __conio+3+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [1643] return 
    rts
  .segment Data
    .label line_text = ch
    l: .byte 0
    ch: .word 0
    c: .byte 0
}
.segment Code
  // display_frame
// Draw a line horizontal from a given xy position and a given length.
// The line should calculate the matching characters to draw and glue them.
// So it first needs to peek the characters at the given position.
// And then calculate the resulting characters to draw.
/**
 * @brief 
 * 
 * @param x0 
 * @param y0 
 * @param x1 
 * @param y1 
 */
// void display_frame(char x0, char y0, __zp($7c) char x1, __zp($ba) char y1)
display_frame: {
    .label x1 = $7c
    .label y1 = $ba
    // unsigned char w = x1 - x0
    // [1645] display_frame::w#0 = display_frame::x1#16 - display_frame::x#0 -- vbum1=vbuz2_minus_vbum3 
    lda.z x1
    sec
    sbc x
    sta w
    // unsigned char h = y1 - y0
    // [1646] display_frame::h#0 = display_frame::y1#16 - display_frame::y#0 -- vbum1=vbuz2_minus_vbum3 
    lda.z y1
    sec
    sbc y
    sta h
    // unsigned char mask = display_frame_maskxy(x, y)
    // [1647] display_frame_maskxy::x#0 = display_frame::x#0 -- vbuz1=vbum2 
    lda x
    sta.z display_frame_maskxy.x
    // [1648] display_frame_maskxy::y#0 = display_frame::y#0 -- vbuz1=vbum2 
    lda y
    sta.z display_frame_maskxy.y
    // [1649] call display_frame_maskxy
    // [2302] phi from display_frame to display_frame_maskxy [phi:display_frame->display_frame_maskxy]
    // [2302] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#0 [phi:display_frame->display_frame_maskxy#0] -- vbum1=vbuz2 
    sta display_frame_maskxy.cpeekcxy1_y
    // [2302] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#0 [phi:display_frame->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // unsigned char mask = display_frame_maskxy(x, y)
    // [1650] display_frame_maskxy::return#13 = display_frame_maskxy::return#12
    // display_frame::@13
    // [1651] display_frame::mask#0 = display_frame_maskxy::return#13
    // mask |= 0b0110
    // [1652] display_frame::mask#1 = display_frame::mask#0 | 6 -- vbum1=vbum1_bor_vbuc1 
    lda #6
    ora mask
    sta mask
    // unsigned char c = display_frame_char(mask)
    // [1653] display_frame_char::mask#0 = display_frame::mask#1 -- vbuz1=vbum2 
    sta.z display_frame_char.mask
    // [1654] call display_frame_char
  // Add a corner.
    // [2328] phi from display_frame::@13 to display_frame_char [phi:display_frame::@13->display_frame_char]
    // [2328] phi display_frame_char::mask#10 = display_frame_char::mask#0 [phi:display_frame::@13->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // unsigned char c = display_frame_char(mask)
    // [1655] display_frame_char::return#13 = display_frame_char::return#12
    // display_frame::@14
    // [1656] display_frame::c#0 = display_frame_char::return#13
    // cputcxy(x, y, c)
    // [1657] cputcxy::x#0 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1658] cputcxy::y#0 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [1659] cputcxy::c#0 = display_frame::c#0
    // [1660] call cputcxy
    // [1787] phi from display_frame::@14 to cputcxy [phi:display_frame::@14->cputcxy]
    // [1787] phi cputcxy::c#15 = cputcxy::c#0 [phi:display_frame::@14->cputcxy#0] -- register_copy 
    // [1787] phi cputcxy::y#15 = cputcxy::y#0 [phi:display_frame::@14->cputcxy#1] -- register_copy 
    // [1787] phi cputcxy::x#15 = cputcxy::x#0 [phi:display_frame::@14->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@15
    // if(w>=2)
    // [1661] if(display_frame::w#0<2) goto display_frame::@36 -- vbum1_lt_vbuc1_then_la1 
    lda w
    cmp #2
    bcs !__b36+
    jmp __b36
  !__b36:
    // display_frame::@2
    // x++;
    // [1662] display_frame::x#1 = ++ display_frame::x#0 -- vbum1=_inc_vbum2 
    lda x
    inc
    sta x_1
    // [1663] phi from display_frame::@2 display_frame::@21 to display_frame::@4 [phi:display_frame::@2/display_frame::@21->display_frame::@4]
    // [1663] phi display_frame::x#10 = display_frame::x#1 [phi:display_frame::@2/display_frame::@21->display_frame::@4#0] -- register_copy 
    // display_frame::@4
  __b4:
    // while(x < x1)
    // [1664] if(display_frame::x#10<display_frame::x1#16) goto display_frame::@5 -- vbum1_lt_vbuz2_then_la1 
    lda x_1
    cmp.z x1
    bcs !__b5+
    jmp __b5
  !__b5:
    // [1665] phi from display_frame::@36 display_frame::@4 to display_frame::@1 [phi:display_frame::@36/display_frame::@4->display_frame::@1]
    // [1665] phi display_frame::x#24 = display_frame::x#30 [phi:display_frame::@36/display_frame::@4->display_frame::@1#0] -- register_copy 
    // display_frame::@1
  __b1:
    // display_frame_maskxy(x, y)
    // [1666] display_frame_maskxy::x#1 = display_frame::x#24 -- vbuz1=vbum2 
    lda x_1
    sta.z display_frame_maskxy.x_1
    // [1667] display_frame_maskxy::y#1 = display_frame::y#0 -- vbuz1=vbum2 
    lda y
    sta.z display_frame_maskxy.y_1
    // [1668] call display_frame_maskxy
    // [2302] phi from display_frame::@1 to display_frame_maskxy [phi:display_frame::@1->display_frame_maskxy]
    // [2302] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#1 [phi:display_frame::@1->display_frame_maskxy#0] -- vbum1=vbuz2 
    sta display_frame_maskxy.cpeekcxy1_y
    // [2302] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#1 [phi:display_frame::@1->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x_1
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1669] display_frame_maskxy::return#14 = display_frame_maskxy::return#12
    // display_frame::@16
    // mask = display_frame_maskxy(x, y)
    // [1670] display_frame::mask#2 = display_frame_maskxy::return#14
    // mask |= 0b0011
    // [1671] display_frame::mask#3 = display_frame::mask#2 | 3 -- vbum1=vbum1_bor_vbuc1 
    lda #3
    ora mask
    sta mask
    // display_frame_char(mask)
    // [1672] display_frame_char::mask#1 = display_frame::mask#3 -- vbuz1=vbum2 
    sta.z display_frame_char.mask
    // [1673] call display_frame_char
    // [2328] phi from display_frame::@16 to display_frame_char [phi:display_frame::@16->display_frame_char]
    // [2328] phi display_frame_char::mask#10 = display_frame_char::mask#1 [phi:display_frame::@16->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1674] display_frame_char::return#14 = display_frame_char::return#12
    // display_frame::@17
    // c = display_frame_char(mask)
    // [1675] display_frame::c#1 = display_frame_char::return#14
    // cputcxy(x, y, c)
    // [1676] cputcxy::x#1 = display_frame::x#24 -- vbum1=vbum2 
    lda x_1
    sta cputcxy.x
    // [1677] cputcxy::y#1 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [1678] cputcxy::c#1 = display_frame::c#1
    // [1679] call cputcxy
    // [1787] phi from display_frame::@17 to cputcxy [phi:display_frame::@17->cputcxy]
    // [1787] phi cputcxy::c#15 = cputcxy::c#1 [phi:display_frame::@17->cputcxy#0] -- register_copy 
    // [1787] phi cputcxy::y#15 = cputcxy::y#1 [phi:display_frame::@17->cputcxy#1] -- register_copy 
    // [1787] phi cputcxy::x#15 = cputcxy::x#1 [phi:display_frame::@17->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@18
    // if(h>=2)
    // [1680] if(display_frame::h#0<2) goto display_frame::@return -- vbum1_lt_vbuc1_then_la1 
    lda h
    cmp #2
    bcs !__breturn+
    jmp __breturn
  !__breturn:
    // display_frame::@3
    // y++;
    // [1681] display_frame::y#1 = ++ display_frame::y#0 -- vbum1=_inc_vbum2 
    lda y
    inc
    sta y_1
    // [1682] phi from display_frame::@27 display_frame::@3 to display_frame::@6 [phi:display_frame::@27/display_frame::@3->display_frame::@6]
    // [1682] phi display_frame::y#10 = display_frame::y#2 [phi:display_frame::@27/display_frame::@3->display_frame::@6#0] -- register_copy 
    // display_frame::@6
  __b6:
    // while(y < y1)
    // [1683] if(display_frame::y#10<display_frame::y1#16) goto display_frame::@7 -- vbum1_lt_vbuz2_then_la1 
    lda y_1
    cmp.z y1
    bcs !__b7+
    jmp __b7
  !__b7:
    // display_frame::@8
    // display_frame_maskxy(x, y)
    // [1684] display_frame_maskxy::x#5 = display_frame::x#0 -- vbuz1=vbum2 
    lda x
    sta.z display_frame_maskxy.x_5
    // [1685] display_frame_maskxy::y#5 = display_frame::y#10 -- vbuz1=vbum2 
    lda y_1
    sta.z display_frame_maskxy.y_5
    // [1686] call display_frame_maskxy
    // [2302] phi from display_frame::@8 to display_frame_maskxy [phi:display_frame::@8->display_frame_maskxy]
    // [2302] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#5 [phi:display_frame::@8->display_frame_maskxy#0] -- vbum1=vbuz2 
    sta display_frame_maskxy.cpeekcxy1_y
    // [2302] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#5 [phi:display_frame::@8->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x_5
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1687] display_frame_maskxy::return#18 = display_frame_maskxy::return#12
    // display_frame::@28
    // mask = display_frame_maskxy(x, y)
    // [1688] display_frame::mask#10 = display_frame_maskxy::return#18
    // mask |= 0b1100
    // [1689] display_frame::mask#11 = display_frame::mask#10 | $c -- vbum1=vbum1_bor_vbuc1 
    lda #$c
    ora mask
    sta mask
    // display_frame_char(mask)
    // [1690] display_frame_char::mask#5 = display_frame::mask#11 -- vbuz1=vbum2 
    sta.z display_frame_char.mask
    // [1691] call display_frame_char
    // [2328] phi from display_frame::@28 to display_frame_char [phi:display_frame::@28->display_frame_char]
    // [2328] phi display_frame_char::mask#10 = display_frame_char::mask#5 [phi:display_frame::@28->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1692] display_frame_char::return#18 = display_frame_char::return#12
    // display_frame::@29
    // c = display_frame_char(mask)
    // [1693] display_frame::c#5 = display_frame_char::return#18
    // cputcxy(x, y, c)
    // [1694] cputcxy::x#5 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1695] cputcxy::y#5 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [1696] cputcxy::c#5 = display_frame::c#5
    // [1697] call cputcxy
    // [1787] phi from display_frame::@29 to cputcxy [phi:display_frame::@29->cputcxy]
    // [1787] phi cputcxy::c#15 = cputcxy::c#5 [phi:display_frame::@29->cputcxy#0] -- register_copy 
    // [1787] phi cputcxy::y#15 = cputcxy::y#5 [phi:display_frame::@29->cputcxy#1] -- register_copy 
    // [1787] phi cputcxy::x#15 = cputcxy::x#5 [phi:display_frame::@29->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@30
    // if(w>=2)
    // [1698] if(display_frame::w#0<2) goto display_frame::@10 -- vbum1_lt_vbuc1_then_la1 
    lda w
    cmp #2
    bcc __b10
    // display_frame::@9
    // x++;
    // [1699] display_frame::x#4 = ++ display_frame::x#0 -- vbum1=_inc_vbum1 
    inc x
    // [1700] phi from display_frame::@35 display_frame::@9 to display_frame::@11 [phi:display_frame::@35/display_frame::@9->display_frame::@11]
    // [1700] phi display_frame::x#18 = display_frame::x#5 [phi:display_frame::@35/display_frame::@9->display_frame::@11#0] -- register_copy 
    // display_frame::@11
  __b11:
    // while(x < x1)
    // [1701] if(display_frame::x#18<display_frame::x1#16) goto display_frame::@12 -- vbum1_lt_vbuz2_then_la1 
    lda x
    cmp.z x1
    bcc __b12
    // [1702] phi from display_frame::@11 display_frame::@30 to display_frame::@10 [phi:display_frame::@11/display_frame::@30->display_frame::@10]
    // [1702] phi display_frame::x#15 = display_frame::x#18 [phi:display_frame::@11/display_frame::@30->display_frame::@10#0] -- register_copy 
    // display_frame::@10
  __b10:
    // display_frame_maskxy(x, y)
    // [1703] display_frame_maskxy::x#6 = display_frame::x#15 -- vbuz1=vbum2 
    lda x
    sta.z display_frame_maskxy.x_6
    // [1704] display_frame_maskxy::y#6 = display_frame::y#10 -- vbuz1=vbum2 
    lda y_1
    sta.z display_frame_maskxy.y_6
    // [1705] call display_frame_maskxy
    // [2302] phi from display_frame::@10 to display_frame_maskxy [phi:display_frame::@10->display_frame_maskxy]
    // [2302] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#6 [phi:display_frame::@10->display_frame_maskxy#0] -- vbum1=vbuz2 
    sta display_frame_maskxy.cpeekcxy1_y
    // [2302] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#6 [phi:display_frame::@10->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x_6
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1706] display_frame_maskxy::return#19 = display_frame_maskxy::return#12
    // display_frame::@31
    // mask = display_frame_maskxy(x, y)
    // [1707] display_frame::mask#12 = display_frame_maskxy::return#19
    // mask |= 0b1001
    // [1708] display_frame::mask#13 = display_frame::mask#12 | 9 -- vbum1=vbum1_bor_vbuc1 
    lda #9
    ora mask
    sta mask
    // display_frame_char(mask)
    // [1709] display_frame_char::mask#6 = display_frame::mask#13 -- vbuz1=vbum2 
    sta.z display_frame_char.mask
    // [1710] call display_frame_char
    // [2328] phi from display_frame::@31 to display_frame_char [phi:display_frame::@31->display_frame_char]
    // [2328] phi display_frame_char::mask#10 = display_frame_char::mask#6 [phi:display_frame::@31->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1711] display_frame_char::return#19 = display_frame_char::return#12
    // display_frame::@32
    // c = display_frame_char(mask)
    // [1712] display_frame::c#6 = display_frame_char::return#19
    // cputcxy(x, y, c)
    // [1713] cputcxy::x#6 = display_frame::x#15 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1714] cputcxy::y#6 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [1715] cputcxy::c#6 = display_frame::c#6
    // [1716] call cputcxy
    // [1787] phi from display_frame::@32 to cputcxy [phi:display_frame::@32->cputcxy]
    // [1787] phi cputcxy::c#15 = cputcxy::c#6 [phi:display_frame::@32->cputcxy#0] -- register_copy 
    // [1787] phi cputcxy::y#15 = cputcxy::y#6 [phi:display_frame::@32->cputcxy#1] -- register_copy 
    // [1787] phi cputcxy::x#15 = cputcxy::x#6 [phi:display_frame::@32->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@return
  __breturn:
    // }
    // [1717] return 
    rts
    // display_frame::@12
  __b12:
    // display_frame_maskxy(x, y)
    // [1718] display_frame_maskxy::x#7 = display_frame::x#18 -- vbuz1=vbum2 
    lda x
    sta.z display_frame_maskxy.x_7
    // [1719] display_frame_maskxy::y#7 = display_frame::y#10 -- vbuz1=vbum2 
    lda y_1
    sta.z display_frame_maskxy.y_7
    // [1720] call display_frame_maskxy
    // [2302] phi from display_frame::@12 to display_frame_maskxy [phi:display_frame::@12->display_frame_maskxy]
    // [2302] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#7 [phi:display_frame::@12->display_frame_maskxy#0] -- vbum1=vbuz2 
    sta display_frame_maskxy.cpeekcxy1_y
    // [2302] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#7 [phi:display_frame::@12->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x_7
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1721] display_frame_maskxy::return#20 = display_frame_maskxy::return#12
    // display_frame::@33
    // mask = display_frame_maskxy(x, y)
    // [1722] display_frame::mask#14 = display_frame_maskxy::return#20
    // mask |= 0b0101
    // [1723] display_frame::mask#15 = display_frame::mask#14 | 5 -- vbum1=vbum1_bor_vbuc1 
    lda #5
    ora mask
    sta mask
    // display_frame_char(mask)
    // [1724] display_frame_char::mask#7 = display_frame::mask#15 -- vbuz1=vbum2 
    sta.z display_frame_char.mask
    // [1725] call display_frame_char
    // [2328] phi from display_frame::@33 to display_frame_char [phi:display_frame::@33->display_frame_char]
    // [2328] phi display_frame_char::mask#10 = display_frame_char::mask#7 [phi:display_frame::@33->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1726] display_frame_char::return#20 = display_frame_char::return#12
    // display_frame::@34
    // c = display_frame_char(mask)
    // [1727] display_frame::c#7 = display_frame_char::return#20
    // cputcxy(x, y, c)
    // [1728] cputcxy::x#7 = display_frame::x#18 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1729] cputcxy::y#7 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [1730] cputcxy::c#7 = display_frame::c#7
    // [1731] call cputcxy
    // [1787] phi from display_frame::@34 to cputcxy [phi:display_frame::@34->cputcxy]
    // [1787] phi cputcxy::c#15 = cputcxy::c#7 [phi:display_frame::@34->cputcxy#0] -- register_copy 
    // [1787] phi cputcxy::y#15 = cputcxy::y#7 [phi:display_frame::@34->cputcxy#1] -- register_copy 
    // [1787] phi cputcxy::x#15 = cputcxy::x#7 [phi:display_frame::@34->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@35
    // x++;
    // [1732] display_frame::x#5 = ++ display_frame::x#18 -- vbum1=_inc_vbum1 
    inc x
    jmp __b11
    // display_frame::@7
  __b7:
    // display_frame_maskxy(x0, y)
    // [1733] display_frame_maskxy::x#3 = display_frame::x#0 -- vbuz1=vbum2 
    lda x
    sta.z display_frame_maskxy.x_3
    // [1734] display_frame_maskxy::y#3 = display_frame::y#10 -- vbuz1=vbum2 
    lda y_1
    sta.z display_frame_maskxy.y_3
    // [1735] call display_frame_maskxy
    // [2302] phi from display_frame::@7 to display_frame_maskxy [phi:display_frame::@7->display_frame_maskxy]
    // [2302] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#3 [phi:display_frame::@7->display_frame_maskxy#0] -- vbum1=vbuz2 
    sta display_frame_maskxy.cpeekcxy1_y
    // [2302] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#3 [phi:display_frame::@7->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x_3
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x0, y)
    // [1736] display_frame_maskxy::return#16 = display_frame_maskxy::return#12
    // display_frame::@22
    // mask = display_frame_maskxy(x0, y)
    // [1737] display_frame::mask#6 = display_frame_maskxy::return#16
    // mask |= 0b1010
    // [1738] display_frame::mask#7 = display_frame::mask#6 | $a -- vbum1=vbum1_bor_vbuc1 
    lda #$a
    ora mask
    sta mask
    // display_frame_char(mask)
    // [1739] display_frame_char::mask#3 = display_frame::mask#7 -- vbuz1=vbum2 
    sta.z display_frame_char.mask
    // [1740] call display_frame_char
    // [2328] phi from display_frame::@22 to display_frame_char [phi:display_frame::@22->display_frame_char]
    // [2328] phi display_frame_char::mask#10 = display_frame_char::mask#3 [phi:display_frame::@22->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1741] display_frame_char::return#16 = display_frame_char::return#12
    // display_frame::@23
    // c = display_frame_char(mask)
    // [1742] display_frame::c#3 = display_frame_char::return#16
    // cputcxy(x0, y, c)
    // [1743] cputcxy::x#3 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1744] cputcxy::y#3 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [1745] cputcxy::c#3 = display_frame::c#3
    // [1746] call cputcxy
    // [1787] phi from display_frame::@23 to cputcxy [phi:display_frame::@23->cputcxy]
    // [1787] phi cputcxy::c#15 = cputcxy::c#3 [phi:display_frame::@23->cputcxy#0] -- register_copy 
    // [1787] phi cputcxy::y#15 = cputcxy::y#3 [phi:display_frame::@23->cputcxy#1] -- register_copy 
    // [1787] phi cputcxy::x#15 = cputcxy::x#3 [phi:display_frame::@23->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@24
    // display_frame_maskxy(x1, y)
    // [1747] display_frame_maskxy::x#4 = display_frame::x1#16
    // [1748] display_frame_maskxy::y#4 = display_frame::y#10 -- vbuz1=vbum2 
    lda y_1
    sta.z display_frame_maskxy.y_4
    // [1749] call display_frame_maskxy
    // [2302] phi from display_frame::@24 to display_frame_maskxy [phi:display_frame::@24->display_frame_maskxy]
    // [2302] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#4 [phi:display_frame::@24->display_frame_maskxy#0] -- vbum1=vbuz2 
    sta display_frame_maskxy.cpeekcxy1_y
    // [2302] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#4 [phi:display_frame::@24->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x_4
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x1, y)
    // [1750] display_frame_maskxy::return#17 = display_frame_maskxy::return#12
    // display_frame::@25
    // mask = display_frame_maskxy(x1, y)
    // [1751] display_frame::mask#8 = display_frame_maskxy::return#17
    // mask |= 0b1010
    // [1752] display_frame::mask#9 = display_frame::mask#8 | $a -- vbum1=vbum1_bor_vbuc1 
    lda #$a
    ora mask
    sta mask
    // display_frame_char(mask)
    // [1753] display_frame_char::mask#4 = display_frame::mask#9 -- vbuz1=vbum2 
    sta.z display_frame_char.mask
    // [1754] call display_frame_char
    // [2328] phi from display_frame::@25 to display_frame_char [phi:display_frame::@25->display_frame_char]
    // [2328] phi display_frame_char::mask#10 = display_frame_char::mask#4 [phi:display_frame::@25->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1755] display_frame_char::return#17 = display_frame_char::return#12
    // display_frame::@26
    // c = display_frame_char(mask)
    // [1756] display_frame::c#4 = display_frame_char::return#17
    // cputcxy(x1, y, c)
    // [1757] cputcxy::x#4 = display_frame::x1#16 -- vbum1=vbuz2 
    lda.z x1
    sta cputcxy.x
    // [1758] cputcxy::y#4 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [1759] cputcxy::c#4 = display_frame::c#4
    // [1760] call cputcxy
    // [1787] phi from display_frame::@26 to cputcxy [phi:display_frame::@26->cputcxy]
    // [1787] phi cputcxy::c#15 = cputcxy::c#4 [phi:display_frame::@26->cputcxy#0] -- register_copy 
    // [1787] phi cputcxy::y#15 = cputcxy::y#4 [phi:display_frame::@26->cputcxy#1] -- register_copy 
    // [1787] phi cputcxy::x#15 = cputcxy::x#4 [phi:display_frame::@26->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@27
    // y++;
    // [1761] display_frame::y#2 = ++ display_frame::y#10 -- vbum1=_inc_vbum1 
    inc y_1
    jmp __b6
    // display_frame::@5
  __b5:
    // display_frame_maskxy(x, y)
    // [1762] display_frame_maskxy::x#2 = display_frame::x#10 -- vbuz1=vbum2 
    lda x_1
    sta.z display_frame_maskxy.x_2
    // [1763] display_frame_maskxy::y#2 = display_frame::y#0 -- vbuz1=vbum2 
    lda y
    sta.z display_frame_maskxy.y_2
    // [1764] call display_frame_maskxy
    // [2302] phi from display_frame::@5 to display_frame_maskxy [phi:display_frame::@5->display_frame_maskxy]
    // [2302] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#2 [phi:display_frame::@5->display_frame_maskxy#0] -- vbum1=vbuz2 
    sta display_frame_maskxy.cpeekcxy1_y
    // [2302] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#2 [phi:display_frame::@5->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x_2
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1765] display_frame_maskxy::return#15 = display_frame_maskxy::return#12
    // display_frame::@19
    // mask = display_frame_maskxy(x, y)
    // [1766] display_frame::mask#4 = display_frame_maskxy::return#15
    // mask |= 0b0101
    // [1767] display_frame::mask#5 = display_frame::mask#4 | 5 -- vbum1=vbum1_bor_vbuc1 
    lda #5
    ora mask
    sta mask
    // display_frame_char(mask)
    // [1768] display_frame_char::mask#2 = display_frame::mask#5 -- vbuz1=vbum2 
    sta.z display_frame_char.mask
    // [1769] call display_frame_char
    // [2328] phi from display_frame::@19 to display_frame_char [phi:display_frame::@19->display_frame_char]
    // [2328] phi display_frame_char::mask#10 = display_frame_char::mask#2 [phi:display_frame::@19->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1770] display_frame_char::return#15 = display_frame_char::return#12
    // display_frame::@20
    // c = display_frame_char(mask)
    // [1771] display_frame::c#2 = display_frame_char::return#15
    // cputcxy(x, y, c)
    // [1772] cputcxy::x#2 = display_frame::x#10 -- vbum1=vbum2 
    lda x_1
    sta cputcxy.x
    // [1773] cputcxy::y#2 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [1774] cputcxy::c#2 = display_frame::c#2
    // [1775] call cputcxy
    // [1787] phi from display_frame::@20 to cputcxy [phi:display_frame::@20->cputcxy]
    // [1787] phi cputcxy::c#15 = cputcxy::c#2 [phi:display_frame::@20->cputcxy#0] -- register_copy 
    // [1787] phi cputcxy::y#15 = cputcxy::y#2 [phi:display_frame::@20->cputcxy#1] -- register_copy 
    // [1787] phi cputcxy::x#15 = cputcxy::x#2 [phi:display_frame::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@21
    // x++;
    // [1776] display_frame::x#2 = ++ display_frame::x#10 -- vbum1=_inc_vbum1 
    inc x_1
    jmp __b4
    // display_frame::@36
  __b36:
    // [1777] display_frame::x#30 = display_frame::x#0 -- vbum1=vbum2 
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
}
.segment Code
  // cputs
// Output a NUL-terminated string at the current cursor position
// void cputs(__zp($49) const char *s)
cputs: {
    .label s = $49
    // [1779] phi from cputs cputs::@2 to cputs::@1 [phi:cputs/cputs::@2->cputs::@1]
    // [1779] phi cputs::s#2 = cputs::s#1 [phi:cputs/cputs::@2->cputs::@1#0] -- register_copy 
    // cputs::@1
  __b1:
    // while(c=*s++)
    // [1780] cputs::c#1 = *cputs::s#2 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta c
    // [1781] cputs::s#0 = ++ cputs::s#2 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [1782] if(0!=cputs::c#1) goto cputs::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // cputs::@return
    // }
    // [1783] return 
    rts
    // cputs::@2
  __b2:
    // cputc(c)
    // [1784] stackpush(char) = cputs::c#1 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [1785] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
  .segment Data
    c: .byte 0
}
.segment Code
  // cputcxy
// Move cursor and output one character
// Same as "gotoxy (x, y); cputc (c);"
// void cputcxy(__mem() char x, __mem() char y, __mem() char c)
cputcxy: {
    // gotoxy(x, y)
    // [1788] gotoxy::x#0 = cputcxy::x#15 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1789] gotoxy::y#0 = cputcxy::y#15 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1790] call gotoxy
    // [602] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [602] phi gotoxy::y#30 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [602] phi gotoxy::x#30 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [1791] stackpush(char) = cputcxy::c#15 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [1792] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [1794] return 
    rts
  .segment Data
    x: .byte 0
    y: .byte 0
    c: .byte 0
}
.segment Code
  // wherex
// Return the x position of the cursor
wherex: {
    // return __conio.cursor_x;
    // [1795] wherex::return#0 = *((char *)&__conio) -- vbum1=_deref_pbuc1 
    lda __conio
    sta return
    // wherex::@return
    // }
    // [1796] return 
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
    // [1797] wherey::return#0 = *((char *)&__conio+1) -- vbum1=_deref_pbuc1 
    lda __conio+1
    sta return
    // wherey::@return
    // }
    // [1798] return 
    rts
  .segment Data
    return: .byte 0
    return_1: .byte 0
    return_2: .byte 0
    return_3: .byte 0
    return_4: .byte 0
}
.segment Code
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
    // [1799] cx16_k_i2c_read_byte::result = 0 -- vwum1=vwuc1 
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
    // [1801] cx16_k_i2c_read_byte::return#0 = cx16_k_i2c_read_byte::result -- vwum1=vwum2 
    sta return
    lda result+1
    sta return+1
    // cx16_k_i2c_read_byte::@return
    // }
    // [1802] cx16_k_i2c_read_byte::return#1 = cx16_k_i2c_read_byte::return#0
    // [1803] return 
    rts
  .segment Data
    device: .byte 0
    offset: .byte 0
    result: .word 0
    .label return = smc_detect.return
}
.segment Code
  // print_smc_led
// void print_smc_led(__zp($76) char c)
print_smc_led: {
    .label c = $76
    // display_print_chip_led(CHIP_SMC_X+1, CHIP_SMC_Y, CHIP_SMC_W, c, BLUE)
    // [1805] display_print_chip_led::tc#0 = print_smc_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_print_chip_led.tc
    // [1806] call display_print_chip_led
    // [2343] phi from print_smc_led to display_print_chip_led [phi:print_smc_led->display_print_chip_led]
    // [2343] phi display_print_chip_led::w#7 = 5 [phi:print_smc_led->display_print_chip_led#0] -- vbuz1=vbuc1 
    lda #5
    sta.z display_print_chip_led.w
    // [2343] phi display_print_chip_led::x#7 = 1+1 [phi:print_smc_led->display_print_chip_led#1] -- vbuz1=vbuc1 
    lda #1+1
    sta.z display_print_chip_led.x
    // [2343] phi display_print_chip_led::tc#3 = display_print_chip_led::tc#0 [phi:print_smc_led->display_print_chip_led#2] -- register_copy 
    jsr display_print_chip_led
    // print_smc_led::@1
    // print_info_led(INFO_X-2, INFO_Y, c, BLUE)
    // [1807] print_info_led::tc#0 = print_smc_led::c#2
    // [1808] call print_info_led
    // [1562] phi from print_smc_led::@1 to print_info_led [phi:print_smc_led::@1->print_info_led]
    // [1562] phi print_info_led::y#4 = $11 [phi:print_smc_led::@1->print_info_led#0] -- vbuz1=vbuc1 
    lda #$11
    sta.z print_info_led.y
    // [1562] phi print_info_led::x#4 = 4-2 [phi:print_smc_led::@1->print_info_led#1] -- vbuz1=vbuc1 
    lda #4-2
    sta.z print_info_led.x
    // [1562] phi print_info_led::tc#4 = print_info_led::tc#0 [phi:print_smc_led::@1->print_info_led#2] -- register_copy 
    jsr print_info_led
    // print_smc_led::@return
    // }
    // [1809] return 
    rts
}
  // print_chip
// void print_chip(__zp($bb) char x, char y, __zp($cf) char w, __zp($38) char *text)
print_chip: {
    .label y = 3+2+1+1+1+1+1+1+1+1
    .label text = $38
    .label text_1 = $4b
    .label x = $bb
    .label text_2 = $58
    .label text_3 = $73
    .label text_4 = $bc
    .label text_5 = $ad
    .label text_6 = $c2
    .label w = $cf
    // display_print_chip_line(x, y++, w, *text++)
    // [1811] display_print_chip_line::x#0 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_print_chip_line.x
    // [1812] display_print_chip_line::w#0 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_print_chip_line.w
    // [1813] display_print_chip_line::c#0 = *print_chip::text#11 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_2),y
    sta.z display_print_chip_line.c
    // [1814] call display_print_chip_line
    // [2361] phi from print_chip to display_print_chip_line [phi:print_chip->display_print_chip_line]
    // [2361] phi display_print_chip_line::c#15 = display_print_chip_line::c#0 [phi:print_chip->display_print_chip_line#0] -- register_copy 
    // [2361] phi display_print_chip_line::w#10 = display_print_chip_line::w#0 [phi:print_chip->display_print_chip_line#1] -- register_copy 
    // [2361] phi display_print_chip_line::y#16 = 3+2 [phi:print_chip->display_print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2
    sta.z display_print_chip_line.y
    // [2361] phi display_print_chip_line::x#16 = display_print_chip_line::x#0 [phi:print_chip->display_print_chip_line#3] -- register_copy 
    jsr display_print_chip_line
    // print_chip::@1
    // display_print_chip_line(x, y++, w, *text++);
    // [1815] print_chip::text#0 = ++ print_chip::text#11 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_2
    adc #1
    sta.z text
    lda.z text_2+1
    adc #0
    sta.z text+1
    // display_print_chip_line(x, y++, w, *text++)
    // [1816] display_print_chip_line::x#1 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_print_chip_line.x
    // [1817] display_print_chip_line::w#1 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_print_chip_line.w
    // [1818] display_print_chip_line::c#1 = *print_chip::text#0 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text),y
    sta.z display_print_chip_line.c
    // [1819] call display_print_chip_line
    // [2361] phi from print_chip::@1 to display_print_chip_line [phi:print_chip::@1->display_print_chip_line]
    // [2361] phi display_print_chip_line::c#15 = display_print_chip_line::c#1 [phi:print_chip::@1->display_print_chip_line#0] -- register_copy 
    // [2361] phi display_print_chip_line::w#10 = display_print_chip_line::w#1 [phi:print_chip::@1->display_print_chip_line#1] -- register_copy 
    // [2361] phi display_print_chip_line::y#16 = ++3+2 [phi:print_chip::@1->display_print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1
    sta.z display_print_chip_line.y
    // [2361] phi display_print_chip_line::x#16 = display_print_chip_line::x#1 [phi:print_chip::@1->display_print_chip_line#3] -- register_copy 
    jsr display_print_chip_line
    // print_chip::@2
    // display_print_chip_line(x, y++, w, *text++);
    // [1820] print_chip::text#1 = ++ print_chip::text#0 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text
    adc #1
    sta.z text_1
    lda.z text+1
    adc #0
    sta.z text_1+1
    // display_print_chip_line(x, y++, w, *text++)
    // [1821] display_print_chip_line::x#2 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_print_chip_line.x
    // [1822] display_print_chip_line::w#2 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_print_chip_line.w
    // [1823] display_print_chip_line::c#2 = *print_chip::text#1 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_1),y
    sta.z display_print_chip_line.c
    // [1824] call display_print_chip_line
    // [2361] phi from print_chip::@2 to display_print_chip_line [phi:print_chip::@2->display_print_chip_line]
    // [2361] phi display_print_chip_line::c#15 = display_print_chip_line::c#2 [phi:print_chip::@2->display_print_chip_line#0] -- register_copy 
    // [2361] phi display_print_chip_line::w#10 = display_print_chip_line::w#2 [phi:print_chip::@2->display_print_chip_line#1] -- register_copy 
    // [2361] phi display_print_chip_line::y#16 = ++++3+2 [phi:print_chip::@2->display_print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1
    sta.z display_print_chip_line.y
    // [2361] phi display_print_chip_line::x#16 = display_print_chip_line::x#2 [phi:print_chip::@2->display_print_chip_line#3] -- register_copy 
    jsr display_print_chip_line
    // print_chip::@3
    // display_print_chip_line(x, y++, w, *text++);
    // [1825] print_chip::text#15 = ++ print_chip::text#1 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_1
    adc #1
    sta.z text_3
    lda.z text_1+1
    adc #0
    sta.z text_3+1
    // display_print_chip_line(x, y++, w, *text++)
    // [1826] display_print_chip_line::x#3 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_print_chip_line.x
    // [1827] display_print_chip_line::w#3 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_print_chip_line.w
    // [1828] display_print_chip_line::c#3 = *print_chip::text#15 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_3),y
    sta.z display_print_chip_line.c
    // [1829] call display_print_chip_line
    // [2361] phi from print_chip::@3 to display_print_chip_line [phi:print_chip::@3->display_print_chip_line]
    // [2361] phi display_print_chip_line::c#15 = display_print_chip_line::c#3 [phi:print_chip::@3->display_print_chip_line#0] -- register_copy 
    // [2361] phi display_print_chip_line::w#10 = display_print_chip_line::w#3 [phi:print_chip::@3->display_print_chip_line#1] -- register_copy 
    // [2361] phi display_print_chip_line::y#16 = ++++++3+2 [phi:print_chip::@3->display_print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1
    sta.z display_print_chip_line.y
    // [2361] phi display_print_chip_line::x#16 = display_print_chip_line::x#3 [phi:print_chip::@3->display_print_chip_line#3] -- register_copy 
    jsr display_print_chip_line
    // print_chip::@4
    // display_print_chip_line(x, y++, w, *text++);
    // [1830] print_chip::text#16 = ++ print_chip::text#15 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_3
    adc #1
    sta.z text_4
    lda.z text_3+1
    adc #0
    sta.z text_4+1
    // display_print_chip_line(x, y++, w, *text++)
    // [1831] display_print_chip_line::x#4 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_print_chip_line.x
    // [1832] display_print_chip_line::w#4 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_print_chip_line.w
    // [1833] display_print_chip_line::c#4 = *print_chip::text#16 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_4),y
    sta.z display_print_chip_line.c
    // [1834] call display_print_chip_line
    // [2361] phi from print_chip::@4 to display_print_chip_line [phi:print_chip::@4->display_print_chip_line]
    // [2361] phi display_print_chip_line::c#15 = display_print_chip_line::c#4 [phi:print_chip::@4->display_print_chip_line#0] -- register_copy 
    // [2361] phi display_print_chip_line::w#10 = display_print_chip_line::w#4 [phi:print_chip::@4->display_print_chip_line#1] -- register_copy 
    // [2361] phi display_print_chip_line::y#16 = ++++++++3+2 [phi:print_chip::@4->display_print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1
    sta.z display_print_chip_line.y
    // [2361] phi display_print_chip_line::x#16 = display_print_chip_line::x#4 [phi:print_chip::@4->display_print_chip_line#3] -- register_copy 
    jsr display_print_chip_line
    // print_chip::@5
    // display_print_chip_line(x, y++, w, *text++);
    // [1835] print_chip::text#17 = ++ print_chip::text#16 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_4
    adc #1
    sta.z text_5
    lda.z text_4+1
    adc #0
    sta.z text_5+1
    // display_print_chip_line(x, y++, w, *text++)
    // [1836] display_print_chip_line::x#5 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_print_chip_line.x
    // [1837] display_print_chip_line::w#5 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_print_chip_line.w
    // [1838] display_print_chip_line::c#5 = *print_chip::text#17 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_5),y
    sta.z display_print_chip_line.c
    // [1839] call display_print_chip_line
    // [2361] phi from print_chip::@5 to display_print_chip_line [phi:print_chip::@5->display_print_chip_line]
    // [2361] phi display_print_chip_line::c#15 = display_print_chip_line::c#5 [phi:print_chip::@5->display_print_chip_line#0] -- register_copy 
    // [2361] phi display_print_chip_line::w#10 = display_print_chip_line::w#5 [phi:print_chip::@5->display_print_chip_line#1] -- register_copy 
    // [2361] phi display_print_chip_line::y#16 = ++++++++++3+2 [phi:print_chip::@5->display_print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1+1
    sta.z display_print_chip_line.y
    // [2361] phi display_print_chip_line::x#16 = display_print_chip_line::x#5 [phi:print_chip::@5->display_print_chip_line#3] -- register_copy 
    jsr display_print_chip_line
    // print_chip::@6
    // display_print_chip_line(x, y++, w, *text++);
    // [1840] print_chip::text#18 = ++ print_chip::text#17 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_5
    adc #1
    sta.z text_6
    lda.z text_5+1
    adc #0
    sta.z text_6+1
    // display_print_chip_line(x, y++, w, *text++)
    // [1841] display_print_chip_line::x#6 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_print_chip_line.x
    // [1842] display_print_chip_line::w#6 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_print_chip_line.w
    // [1843] display_print_chip_line::c#6 = *print_chip::text#18 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta.z display_print_chip_line.c
    // [1844] call display_print_chip_line
    // [2361] phi from print_chip::@6 to display_print_chip_line [phi:print_chip::@6->display_print_chip_line]
    // [2361] phi display_print_chip_line::c#15 = display_print_chip_line::c#6 [phi:print_chip::@6->display_print_chip_line#0] -- register_copy 
    // [2361] phi display_print_chip_line::w#10 = display_print_chip_line::w#6 [phi:print_chip::@6->display_print_chip_line#1] -- register_copy 
    // [2361] phi display_print_chip_line::y#16 = ++++++++++++3+2 [phi:print_chip::@6->display_print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1+1+1
    sta.z display_print_chip_line.y
    // [2361] phi display_print_chip_line::x#16 = display_print_chip_line::x#6 [phi:print_chip::@6->display_print_chip_line#3] -- register_copy 
    jsr display_print_chip_line
    // print_chip::@7
    // display_print_chip_line(x, y++, w, *text++);
    // [1845] print_chip::text#19 = ++ print_chip::text#18 -- pbuz1=_inc_pbuz1 
    inc.z text_6
    bne !+
    inc.z text_6+1
  !:
    // display_print_chip_line(x, y++, w, *text++)
    // [1846] display_print_chip_line::x#7 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_print_chip_line.x
    // [1847] display_print_chip_line::w#7 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_print_chip_line.w
    // [1848] display_print_chip_line::c#7 = *print_chip::text#19 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta.z display_print_chip_line.c
    // [1849] call display_print_chip_line
    // [2361] phi from print_chip::@7 to display_print_chip_line [phi:print_chip::@7->display_print_chip_line]
    // [2361] phi display_print_chip_line::c#15 = display_print_chip_line::c#7 [phi:print_chip::@7->display_print_chip_line#0] -- register_copy 
    // [2361] phi display_print_chip_line::w#10 = display_print_chip_line::w#7 [phi:print_chip::@7->display_print_chip_line#1] -- register_copy 
    // [2361] phi display_print_chip_line::y#16 = ++++++++++++++3+2 [phi:print_chip::@7->display_print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1+1+1+1
    sta.z display_print_chip_line.y
    // [2361] phi display_print_chip_line::x#16 = display_print_chip_line::x#7 [phi:print_chip::@7->display_print_chip_line#3] -- register_copy 
    jsr display_print_chip_line
    // print_chip::@8
    // display_print_chip_end(x, y++, w)
    // [1850] display_print_chip_end::x#0 = print_chip::x#10
    // [1851] display_print_chip_end::w#0 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_print_chip_end.w
    // [1852] call display_print_chip_end
    jsr display_print_chip_end
    // print_chip::@return
    // }
    // [1853] return 
    rts
}
  // utoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void utoa(__mem() unsigned int value, __zp($42) char *buffer, __mem() char radix)
utoa: {
    .label utoa__4 = $47
    .label utoa__10 = $29
    .label utoa__11 = $46
    .label buffer = $42
    .label digit_values = $5e
    // if(radix==DECIMAL)
    // [1854] if(utoa::radix#0==DECIMAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // utoa::@2
    // if(radix==HEXADECIMAL)
    // [1855] if(utoa::radix#0==HEXADECIMAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // utoa::@3
    // if(radix==OCTAL)
    // [1856] if(utoa::radix#0==OCTAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // utoa::@4
    // if(radix==BINARY)
    // [1857] if(utoa::radix#0==BINARY) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // utoa::@5
    // *buffer++ = 'e'
    // [1858] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1859] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1860] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1861] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // utoa::@return
    // }
    // [1862] return 
    rts
    // [1863] phi from utoa to utoa::@1 [phi:utoa->utoa::@1]
  __b2:
    // [1863] phi utoa::digit_values#8 = RADIX_DECIMAL_VALUES [phi:utoa->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_DECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES
    sta.z digit_values+1
    // [1863] phi utoa::max_digits#7 = 5 [phi:utoa->utoa::@1#1] -- vbum1=vbuc1 
    lda #5
    sta max_digits
    jmp __b1
    // [1863] phi from utoa::@2 to utoa::@1 [phi:utoa::@2->utoa::@1]
  __b3:
    // [1863] phi utoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES [phi:utoa::@2->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_HEXADECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES
    sta.z digit_values+1
    // [1863] phi utoa::max_digits#7 = 4 [phi:utoa::@2->utoa::@1#1] -- vbum1=vbuc1 
    lda #4
    sta max_digits
    jmp __b1
    // [1863] phi from utoa::@3 to utoa::@1 [phi:utoa::@3->utoa::@1]
  __b4:
    // [1863] phi utoa::digit_values#8 = RADIX_OCTAL_VALUES [phi:utoa::@3->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_OCTAL_VALUES
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES
    sta.z digit_values+1
    // [1863] phi utoa::max_digits#7 = 6 [phi:utoa::@3->utoa::@1#1] -- vbum1=vbuc1 
    lda #6
    sta max_digits
    jmp __b1
    // [1863] phi from utoa::@4 to utoa::@1 [phi:utoa::@4->utoa::@1]
  __b5:
    // [1863] phi utoa::digit_values#8 = RADIX_BINARY_VALUES [phi:utoa::@4->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_BINARY_VALUES
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES
    sta.z digit_values+1
    // [1863] phi utoa::max_digits#7 = $10 [phi:utoa::@4->utoa::@1#1] -- vbum1=vbuc1 
    lda #$10
    sta max_digits
    // utoa::@1
  __b1:
    // [1864] phi from utoa::@1 to utoa::@6 [phi:utoa::@1->utoa::@6]
    // [1864] phi utoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:utoa::@1->utoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1864] phi utoa::started#2 = 0 [phi:utoa::@1->utoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [1864] phi utoa::value#2 = utoa::value#1 [phi:utoa::@1->utoa::@6#2] -- register_copy 
    // [1864] phi utoa::digit#2 = 0 [phi:utoa::@1->utoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // utoa::@6
  __b6:
    // max_digits-1
    // [1865] utoa::$4 = utoa::max_digits#7 - 1 -- vbuz1=vbum2_minus_1 
    ldx max_digits
    dex
    stx.z utoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1866] if(utoa::digit#2<utoa::$4) goto utoa::@7 -- vbum1_lt_vbuz2_then_la1 
    lda digit
    cmp.z utoa__4
    bcc __b7
    // utoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1867] utoa::$11 = (char)utoa::value#2 -- vbuz1=_byte_vwum2 
    lda value
    sta.z utoa__11
    // [1868] *utoa::buffer#11 = DIGITS[utoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1869] utoa::buffer#3 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1870] *utoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // utoa::@7
  __b7:
    // unsigned int digit_value = digit_values[digit]
    // [1871] utoa::$10 = utoa::digit#2 << 1 -- vbuz1=vbum2_rol_1 
    lda digit
    asl
    sta.z utoa__10
    // [1872] utoa::digit_value#0 = utoa::digit_values#8[utoa::$10] -- vwum1=pwuz2_derefidx_vbuz3 
    tay
    lda (digit_values),y
    sta digit_value
    iny
    lda (digit_values),y
    sta digit_value+1
    // if (started || value >= digit_value)
    // [1873] if(0!=utoa::started#2) goto utoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // utoa::@12
    // [1874] if(utoa::value#2>=utoa::digit_value#0) goto utoa::@10 -- vwum1_ge_vwum2_then_la1 
    lda digit_value+1
    cmp value+1
    bne !+
    lda digit_value
    cmp value
    beq __b10
  !:
    bcc __b10
    // [1875] phi from utoa::@12 to utoa::@9 [phi:utoa::@12->utoa::@9]
    // [1875] phi utoa::buffer#14 = utoa::buffer#11 [phi:utoa::@12->utoa::@9#0] -- register_copy 
    // [1875] phi utoa::started#4 = utoa::started#2 [phi:utoa::@12->utoa::@9#1] -- register_copy 
    // [1875] phi utoa::value#6 = utoa::value#2 [phi:utoa::@12->utoa::@9#2] -- register_copy 
    // utoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1876] utoa::digit#1 = ++ utoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [1864] phi from utoa::@9 to utoa::@6 [phi:utoa::@9->utoa::@6]
    // [1864] phi utoa::buffer#11 = utoa::buffer#14 [phi:utoa::@9->utoa::@6#0] -- register_copy 
    // [1864] phi utoa::started#2 = utoa::started#4 [phi:utoa::@9->utoa::@6#1] -- register_copy 
    // [1864] phi utoa::value#2 = utoa::value#6 [phi:utoa::@9->utoa::@6#2] -- register_copy 
    // [1864] phi utoa::digit#2 = utoa::digit#1 [phi:utoa::@9->utoa::@6#3] -- register_copy 
    jmp __b6
    // utoa::@10
  __b10:
    // utoa_append(buffer++, value, digit_value)
    // [1877] utoa_append::buffer#0 = utoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z utoa_append.buffer
    lda.z buffer+1
    sta.z utoa_append.buffer+1
    // [1878] utoa_append::value#0 = utoa::value#2
    // [1879] utoa_append::sub#0 = utoa::digit_value#0
    // [1880] call utoa_append
    // [2422] phi from utoa::@10 to utoa_append [phi:utoa::@10->utoa_append]
    jsr utoa_append
    // utoa_append(buffer++, value, digit_value)
    // [1881] utoa_append::return#0 = utoa_append::value#2
    // utoa::@11
    // value = utoa_append(buffer++, value, digit_value)
    // [1882] utoa::value#0 = utoa_append::return#0
    // value = utoa_append(buffer++, value, digit_value);
    // [1883] utoa::buffer#4 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1875] phi from utoa::@11 to utoa::@9 [phi:utoa::@11->utoa::@9]
    // [1875] phi utoa::buffer#14 = utoa::buffer#4 [phi:utoa::@11->utoa::@9#0] -- register_copy 
    // [1875] phi utoa::started#4 = 1 [phi:utoa::@11->utoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [1875] phi utoa::value#6 = utoa::value#0 [phi:utoa::@11->utoa::@9#2] -- register_copy 
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
  // printf_number_buffer
// Print the contents of the number buffer using a specific format.
// This handles minimum length, zero-filling, and left/right justification from the format
// void printf_number_buffer(__zp($6f) void (*putc)(char), __mem() char buffer_sign, char *buffer_digits, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, char format_radix)
printf_number_buffer: {
    .label printf_number_buffer__19 = $73
    .label putc = $6f
    // if(format.min_length)
    // [1885] if(0==printf_number_buffer::format_min_length#3) goto printf_number_buffer::@1 -- 0_eq_vbum1_then_la1 
    lda format_min_length
    beq __b5
    // [1886] phi from printf_number_buffer to printf_number_buffer::@5 [phi:printf_number_buffer->printf_number_buffer::@5]
    // printf_number_buffer::@5
    // strlen(buffer.digits)
    // [1887] call strlen
    // [2170] phi from printf_number_buffer::@5 to strlen [phi:printf_number_buffer::@5->strlen]
    // [2170] phi strlen::str#8 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@5->strlen#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str+1
    jsr strlen
    // strlen(buffer.digits)
    // [1888] strlen::return#3 = strlen::len#2
    // printf_number_buffer::@11
    // [1889] printf_number_buffer::$19 = strlen::return#3 -- vwuz1=vwum2 
    lda strlen.return
    sta.z printf_number_buffer__19
    lda strlen.return+1
    sta.z printf_number_buffer__19+1
    // signed char len = (signed char)strlen(buffer.digits)
    // [1890] printf_number_buffer::len#0 = (signed char)printf_number_buffer::$19 -- vbsm1=_sbyte_vwuz2 
    // There is a minimum length - work out the padding
    lda.z printf_number_buffer__19
    sta len
    // if(buffer.sign)
    // [1891] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@10 -- 0_eq_vbum1_then_la1 
    lda buffer_sign
    beq __b10
    // printf_number_buffer::@6
    // len++;
    // [1892] printf_number_buffer::len#1 = ++ printf_number_buffer::len#0 -- vbsm1=_inc_vbsm1 
    inc len
    // [1893] phi from printf_number_buffer::@11 printf_number_buffer::@6 to printf_number_buffer::@10 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10]
    // [1893] phi printf_number_buffer::len#2 = printf_number_buffer::len#0 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10#0] -- register_copy 
    // printf_number_buffer::@10
  __b10:
    // padding = (signed char)format.min_length - len
    // [1894] printf_number_buffer::padding#1 = (signed char)printf_number_buffer::format_min_length#3 - printf_number_buffer::len#2 -- vbsm1=vbsm2_minus_vbsm1 
    lda format_min_length
    sec
    sbc padding
    sta padding
    // if(padding<0)
    // [1895] if(printf_number_buffer::padding#1>=0) goto printf_number_buffer::@15 -- vbsm1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1897] phi from printf_number_buffer printf_number_buffer::@10 to printf_number_buffer::@1 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1]
  __b5:
    // [1897] phi printf_number_buffer::padding#10 = 0 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1#0] -- vbsm1=vbsc1 
    lda #0
    sta padding
    // [1896] phi from printf_number_buffer::@10 to printf_number_buffer::@15 [phi:printf_number_buffer::@10->printf_number_buffer::@15]
    // printf_number_buffer::@15
    // [1897] phi from printf_number_buffer::@15 to printf_number_buffer::@1 [phi:printf_number_buffer::@15->printf_number_buffer::@1]
    // [1897] phi printf_number_buffer::padding#10 = printf_number_buffer::padding#1 [phi:printf_number_buffer::@15->printf_number_buffer::@1#0] -- register_copy 
    // printf_number_buffer::@1
  __b1:
    // printf_number_buffer::@13
    // if(!format.justify_left && !format.zero_padding && padding)
    // [1898] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@2 -- 0_neq_vbum1_then_la1 
    lda format_zero_padding
    bne __b2
    // printf_number_buffer::@12
    // [1899] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@7 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b7
    jmp __b2
    // printf_number_buffer::@7
  __b7:
    // printf_padding(putc, ' ',(char)padding)
    // [1900] printf_padding::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1901] printf_padding::length#0 = (char)printf_number_buffer::padding#10 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1902] call printf_padding
    // [2176] phi from printf_number_buffer::@7 to printf_padding [phi:printf_number_buffer::@7->printf_padding]
    // [2176] phi printf_padding::putc#7 = printf_padding::putc#0 [phi:printf_number_buffer::@7->printf_padding#0] -- register_copy 
    // [2176] phi printf_padding::pad#7 = ' ' [phi:printf_number_buffer::@7->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [2176] phi printf_padding::length#6 = printf_padding::length#0 [phi:printf_number_buffer::@7->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@2
  __b2:
    // if(buffer.sign)
    // [1903] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@3 -- 0_eq_vbum1_then_la1 
    lda buffer_sign
    beq __b3
    // printf_number_buffer::@8
    // putc(buffer.sign)
    // [1904] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbum1 
    pha
    // [1905] callexecute *printf_number_buffer::putc#10  -- call__deref_pprz1 
    jsr icall34
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@3
  __b3:
    // if(format.zero_padding && padding)
    // [1907] if(0==printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@4 -- 0_eq_vbum1_then_la1 
    lda format_zero_padding
    beq __b4
    // printf_number_buffer::@14
    // [1908] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@9 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b9
    jmp __b4
    // printf_number_buffer::@9
  __b9:
    // printf_padding(putc, '0',(char)padding)
    // [1909] printf_padding::putc#1 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1910] printf_padding::length#1 = (char)printf_number_buffer::padding#10 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1911] call printf_padding
    // [2176] phi from printf_number_buffer::@9 to printf_padding [phi:printf_number_buffer::@9->printf_padding]
    // [2176] phi printf_padding::putc#7 = printf_padding::putc#1 [phi:printf_number_buffer::@9->printf_padding#0] -- register_copy 
    // [2176] phi printf_padding::pad#7 = '0' [phi:printf_number_buffer::@9->printf_padding#1] -- vbum1=vbuc1 
    lda #'0'
    sta printf_padding.pad
    // [2176] phi printf_padding::length#6 = printf_padding::length#1 [phi:printf_number_buffer::@9->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@4
  __b4:
    // printf_str(putc, buffer.digits)
    // [1912] printf_str::putc#0 = printf_number_buffer::putc#10
    // [1913] call printf_str
    // [745] phi from printf_number_buffer::@4 to printf_str [phi:printf_number_buffer::@4->printf_str]
    // [745] phi printf_str::putc#71 = printf_str::putc#0 [phi:printf_number_buffer::@4->printf_str#0] -- register_copy 
    // [745] phi printf_str::s#71 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@return
    // }
    // [1914] return 
    rts
    // Outside Flow
  icall34:
    jmp (putc)
  .segment Data
    buffer_sign: .byte 0
    .label format_min_length = printf_uint.format_min_length
    .label format_zero_padding = printf_uint.format_zero_padding
    len: .byte 0
    .label padding = len
}
.segment Code
  // print_vera_led
// void print_vera_led(__zp($c7) char c)
print_vera_led: {
    .label c = $c7
    // display_print_chip_led(CHIP_VERA_X+1, CHIP_VERA_Y, CHIP_VERA_W, c, BLUE)
    // [1916] display_print_chip_led::tc#1 = print_vera_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_print_chip_led.tc
    // [1917] call display_print_chip_led
    // [2343] phi from print_vera_led to display_print_chip_led [phi:print_vera_led->display_print_chip_led]
    // [2343] phi display_print_chip_led::w#7 = 8 [phi:print_vera_led->display_print_chip_led#0] -- vbuz1=vbuc1 
    lda #8
    sta.z display_print_chip_led.w
    // [2343] phi display_print_chip_led::x#7 = 9+1 [phi:print_vera_led->display_print_chip_led#1] -- vbuz1=vbuc1 
    lda #9+1
    sta.z display_print_chip_led.x
    // [2343] phi display_print_chip_led::tc#3 = display_print_chip_led::tc#1 [phi:print_vera_led->display_print_chip_led#2] -- register_copy 
    jsr display_print_chip_led
    // print_vera_led::@1
    // print_info_led(INFO_X-2, INFO_Y+1, c, BLUE)
    // [1918] print_info_led::tc#1 = print_vera_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z print_info_led.tc
    // [1919] call print_info_led
    // [1562] phi from print_vera_led::@1 to print_info_led [phi:print_vera_led::@1->print_info_led]
    // [1562] phi print_info_led::y#4 = $11+1 [phi:print_vera_led::@1->print_info_led#0] -- vbuz1=vbuc1 
    lda #$11+1
    sta.z print_info_led.y
    // [1562] phi print_info_led::x#4 = 4-2 [phi:print_vera_led::@1->print_info_led#1] -- vbuz1=vbuc1 
    lda #4-2
    sta.z print_info_led.x
    // [1562] phi print_info_led::tc#4 = print_info_led::tc#1 [phi:print_vera_led::@1->print_info_led#2] -- register_copy 
    jsr print_info_led
    // print_vera_led::@return
    // }
    // [1920] return 
    rts
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
// void rom_unlock(__zp($4f) unsigned long address, __zp($57) char unlock_code)
rom_unlock: {
    .label address = $4f
    .label unlock_code = $57
    // unsigned long chip_address = address & ROM_CHIP_MASK
    // [1922] rom_unlock::chip_address#0 = rom_unlock::address#5 & $380000 -- vdum1=vduz2_band_vduc1 
    lda.z address
    and #<$380000
    sta chip_address
    lda.z address+1
    and #>$380000
    sta chip_address+1
    lda.z address+2
    and #<$380000>>$10
    sta chip_address+2
    lda.z address+3
    and #>$380000>>$10
    sta chip_address+3
    // rom_write_byte(chip_address + 0x05555, 0xAA)
    // [1923] rom_write_byte::address#0 = rom_unlock::chip_address#0 + $5555 -- vduz1=vdum2_plus_vwuc1 
    clc
    lda chip_address
    adc #<$5555
    sta.z rom_write_byte.address
    lda chip_address+1
    adc #>$5555
    sta.z rom_write_byte.address+1
    lda chip_address+2
    adc #0
    sta.z rom_write_byte.address+2
    lda chip_address+3
    adc #0
    sta.z rom_write_byte.address+3
    // [1924] call rom_write_byte
  // This is a very important operation...
    // [2429] phi from rom_unlock to rom_write_byte [phi:rom_unlock->rom_write_byte]
    // [2429] phi rom_write_byte::value#10 = $aa [phi:rom_unlock->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$aa
    sta.z rom_write_byte.value
    // [2429] phi rom_write_byte::address#4 = rom_write_byte::address#0 [phi:rom_unlock->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@1
    // rom_write_byte(chip_address + 0x02AAA, 0x55)
    // [1925] rom_write_byte::address#1 = rom_unlock::chip_address#0 + $2aaa -- vduz1=vdum2_plus_vwuc1 
    clc
    lda chip_address
    adc #<$2aaa
    sta.z rom_write_byte.address
    lda chip_address+1
    adc #>$2aaa
    sta.z rom_write_byte.address+1
    lda chip_address+2
    adc #0
    sta.z rom_write_byte.address+2
    lda chip_address+3
    adc #0
    sta.z rom_write_byte.address+3
    // [1926] call rom_write_byte
    // [2429] phi from rom_unlock::@1 to rom_write_byte [phi:rom_unlock::@1->rom_write_byte]
    // [2429] phi rom_write_byte::value#10 = $55 [phi:rom_unlock::@1->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$55
    sta.z rom_write_byte.value
    // [2429] phi rom_write_byte::address#4 = rom_write_byte::address#1 [phi:rom_unlock::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@2
    // rom_write_byte(address, unlock_code)
    // [1927] rom_write_byte::address#2 = rom_unlock::address#5 -- vduz1=vduz2 
    lda.z address
    sta.z rom_write_byte.address
    lda.z address+1
    sta.z rom_write_byte.address+1
    lda.z address+2
    sta.z rom_write_byte.address+2
    lda.z address+3
    sta.z rom_write_byte.address+3
    // [1928] rom_write_byte::value#2 = rom_unlock::unlock_code#5 -- vbuz1=vbuz2 
    lda.z unlock_code
    sta.z rom_write_byte.value
    // [1929] call rom_write_byte
    // [2429] phi from rom_unlock::@2 to rom_write_byte [phi:rom_unlock::@2->rom_write_byte]
    // [2429] phi rom_write_byte::value#10 = rom_write_byte::value#2 [phi:rom_unlock::@2->rom_write_byte#0] -- register_copy 
    // [2429] phi rom_write_byte::address#4 = rom_write_byte::address#2 [phi:rom_unlock::@2->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@return
    // }
    // [1930] return 
    rts
  .segment Data
    chip_address: .dword 0
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
// __mem() char rom_read_byte(__zp($4f) unsigned long address)
rom_read_byte: {
    .label rom_bank1_rom_read_byte__0 = $46
    .label rom_bank1_rom_read_byte__1 = $29
    .label rom_bank1_rom_read_byte__2 = $be
    .label rom_ptr1_rom_read_byte__0 = $bc
    .label rom_ptr1_rom_read_byte__2 = $bc
    .label rom_ptr1_return = $bc
    .label address = $4f
    // rom_read_byte::rom_bank1
    // BYTE2(address)
    // [1932] rom_read_byte::rom_bank1_$0 = byte2  rom_read_byte::address#2 -- vbuz1=_byte2_vduz2 
    lda.z address+2
    sta.z rom_bank1_rom_read_byte__0
    // BYTE1(address)
    // [1933] rom_read_byte::rom_bank1_$1 = byte1  rom_read_byte::address#2 -- vbuz1=_byte1_vduz2 
    lda.z address+1
    sta.z rom_bank1_rom_read_byte__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [1934] rom_read_byte::rom_bank1_$2 = rom_read_byte::rom_bank1_$0 w= rom_read_byte::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_read_byte__0
    sta.z rom_bank1_rom_read_byte__2+1
    lda.z rom_bank1_rom_read_byte__1
    sta.z rom_bank1_rom_read_byte__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [1935] rom_read_byte::rom_bank1_bank_unshifted#0 = rom_read_byte::rom_bank1_$2 << 2 -- vwum1=vwuz2_rol_2 
    asl
    sta rom_bank1_bank_unshifted
    lda.z rom_bank1_rom_read_byte__2+1
    rol
    sta rom_bank1_bank_unshifted+1
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [1936] rom_read_byte::rom_bank1_return#0 = byte1  rom_read_byte::rom_bank1_bank_unshifted#0 -- vbum1=_byte1_vwum2 
    lda rom_bank1_bank_unshifted+1
    sta rom_bank1_return
    // rom_read_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [1937] rom_read_byte::rom_ptr1_$2 = (unsigned int)rom_read_byte::address#2 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_read_byte__2
    lda.z address+1
    sta.z rom_ptr1_rom_read_byte__2+1
    // [1938] rom_read_byte::rom_ptr1_$0 = rom_read_byte::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_read_byte__0
    and #<$3fff
    sta.z rom_ptr1_rom_read_byte__0
    lda.z rom_ptr1_rom_read_byte__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_read_byte__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [1939] rom_read_byte::rom_ptr1_return#0 = rom_read_byte::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_read_byte::bank_set_brom1
    // BROM = bank
    // [1940] BROM = rom_read_byte::rom_bank1_return#0 -- vbuz1=vbum2 
    lda rom_bank1_return
    sta.z BROM
    // rom_read_byte::@1
    // return *ptr_rom;
    // [1941] rom_read_byte::return#0 = *((char *)rom_read_byte::rom_ptr1_return#0) -- vbum1=_deref_pbuz2 
    ldy #0
    lda (rom_ptr1_return),y
    sta return
    // rom_read_byte::@return
    // }
    // [1942] return 
    rts
  .segment Data
    rom_bank1_bank_unshifted: .word 0
    rom_bank1_return: .byte 0
    return: .byte 0
}
.segment Code
  // strcpy
// Copies the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcpy(char *destination, char *source)
strcpy: {
    .label dst = $3b
    .label src = $44
    // [1944] phi from strcpy to strcpy::@1 [phi:strcpy->strcpy::@1]
    // [1944] phi strcpy::dst#2 = display_chip_rom::rom [phi:strcpy->strcpy::@1#0] -- pbuz1=pbuc1 
    lda #<display_chip_rom.rom
    sta.z dst
    lda #>display_chip_rom.rom
    sta.z dst+1
    // [1944] phi strcpy::src#2 = display_chip_rom::source [phi:strcpy->strcpy::@1#1] -- pbuz1=pbuc1 
    lda #<display_chip_rom.source
    sta.z src
    lda #>display_chip_rom.source
    sta.z src+1
    // strcpy::@1
  __b1:
    // while(*src)
    // [1945] if(0!=*strcpy::src#2) goto strcpy::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcpy::@3
    // *dst = 0
    // [1946] *strcpy::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcpy::@return
    // }
    // [1947] return 
    rts
    // strcpy::@2
  __b2:
    // *dst++ = *src++
    // [1948] *strcpy::dst#2 = *strcpy::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [1949] strcpy::dst#1 = ++ strcpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [1950] strcpy::src#1 = ++ strcpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [1944] phi from strcpy::@2 to strcpy::@1 [phi:strcpy::@2->strcpy::@1]
    // [1944] phi strcpy::dst#2 = strcpy::dst#1 [phi:strcpy::@2->strcpy::@1#0] -- register_copy 
    // [1944] phi strcpy::src#2 = strcpy::src#1 [phi:strcpy::@2->strcpy::@1#1] -- register_copy 
    jmp __b1
}
  // strcat
// Concatenates the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcat(char *destination, __zp($58) char *source)
strcat: {
    .label strcat__0 = $36
    .label dst = $36
    .label src = $58
    .label source = $58
    // strlen(destination)
    // [1952] call strlen
    // [2170] phi from strcat to strlen [phi:strcat->strlen]
    // [2170] phi strlen::str#8 = display_chip_rom::rom [phi:strcat->strlen#0] -- pbuz1=pbuc1 
    lda #<display_chip_rom.rom
    sta.z strlen.str
    lda #>display_chip_rom.rom
    sta.z strlen.str+1
    jsr strlen
    // strlen(destination)
    // [1953] strlen::return#0 = strlen::len#2
    // strcat::@4
    // [1954] strcat::$0 = strlen::return#0 -- vwuz1=vwum2 
    lda strlen.return
    sta.z strcat__0
    lda strlen.return+1
    sta.z strcat__0+1
    // char* dst = destination + strlen(destination)
    // [1955] strcat::dst#0 = display_chip_rom::rom + strcat::$0 -- pbuz1=pbuc1_plus_vwuz1 
    lda.z dst
    clc
    adc #<display_chip_rom.rom
    sta.z dst
    lda.z dst+1
    adc #>display_chip_rom.rom
    sta.z dst+1
    // [1956] phi from strcat::@2 strcat::@4 to strcat::@1 [phi:strcat::@2/strcat::@4->strcat::@1]
    // [1956] phi strcat::dst#2 = strcat::dst#1 [phi:strcat::@2/strcat::@4->strcat::@1#0] -- register_copy 
    // [1956] phi strcat::src#2 = strcat::src#1 [phi:strcat::@2/strcat::@4->strcat::@1#1] -- register_copy 
    // strcat::@1
  __b1:
    // while(*src)
    // [1957] if(0!=*strcat::src#2) goto strcat::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcat::@3
    // *dst = 0
    // [1958] *strcat::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcat::@return
    // }
    // [1959] return 
    rts
    // strcat::@2
  __b2:
    // *dst++ = *src++
    // [1960] *strcat::dst#2 = *strcat::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [1961] strcat::dst#1 = ++ strcat::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [1962] strcat::src#1 = ++ strcat::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    jmp __b1
}
  // print_rom_led
// void print_rom_led(__zp($7d) char chip, __zp($7e) char c)
print_rom_led: {
    .label print_rom_led__0 = $6c
    .label chip = $7d
    .label c = $7e
    .label print_rom_led__7 = $6c
    .label print_rom_led__8 = $6c
    // chip*6
    // [1964] print_rom_led::$7 = print_rom_led::chip#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z chip
    asl
    sta.z print_rom_led__7
    // [1965] print_rom_led::$8 = print_rom_led::$7 + print_rom_led::chip#2 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z print_rom_led__8
    clc
    adc.z chip
    sta.z print_rom_led__8
    // CHIP_ROM_X+chip*6
    // [1966] print_rom_led::$0 = print_rom_led::$8 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z print_rom_led__0
    // display_print_chip_led(CHIP_ROM_X+chip*6+1, CHIP_ROM_Y, CHIP_ROM_W, c, BLUE)
    // [1967] display_print_chip_led::x#3 = print_rom_led::$0 + $14+1 -- vbuz1=vbuz1_plus_vbuc1 
    lda #$14+1
    clc
    adc.z display_print_chip_led.x
    sta.z display_print_chip_led.x
    // [1968] display_print_chip_led::tc#2 = print_rom_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_print_chip_led.tc
    // [1969] call display_print_chip_led
    // [2343] phi from print_rom_led to display_print_chip_led [phi:print_rom_led->display_print_chip_led]
    // [2343] phi display_print_chip_led::w#7 = 3 [phi:print_rom_led->display_print_chip_led#0] -- vbuz1=vbuc1 
    lda #3
    sta.z display_print_chip_led.w
    // [2343] phi display_print_chip_led::x#7 = display_print_chip_led::x#3 [phi:print_rom_led->display_print_chip_led#1] -- register_copy 
    // [2343] phi display_print_chip_led::tc#3 = display_print_chip_led::tc#2 [phi:print_rom_led->display_print_chip_led#2] -- register_copy 
    jsr display_print_chip_led
    // print_rom_led::@1
    // print_info_led(INFO_X-2, INFO_Y+chip+2, c, BLUE)
    // [1970] print_info_led::y#2 = print_rom_led::chip#2 + $11+2 -- vbuz1=vbuz2_plus_vbuc1 
    lda #$11+2
    clc
    adc.z chip
    sta.z print_info_led.y
    // [1971] print_info_led::tc#2 = print_rom_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z print_info_led.tc
    // [1972] call print_info_led
    // [1562] phi from print_rom_led::@1 to print_info_led [phi:print_rom_led::@1->print_info_led]
    // [1562] phi print_info_led::y#4 = print_info_led::y#2 [phi:print_rom_led::@1->print_info_led#0] -- register_copy 
    // [1562] phi print_info_led::x#4 = 4-2 [phi:print_rom_led::@1->print_info_led#1] -- vbuz1=vbuc1 
    lda #4-2
    sta.z print_info_led.x
    // [1562] phi print_info_led::tc#4 = print_info_led::tc#2 [phi:print_rom_led::@1->print_info_led#2] -- register_copy 
    jsr print_info_led
    // print_rom_led::@return
    // }
    // [1973] return 
    rts
}
  // cbm_k_getin
/**
 * @brief Scan a character from keyboard without pressing enter.
 * 
 * @return char The character read.
 */
cbm_k_getin: {
    // __mem unsigned char ch
    // [1974] cbm_k_getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // asm
    // asm { jsrCBM_GETIN stach  }
    jsr CBM_GETIN
    sta ch
    // return ch;
    // [1976] cbm_k_getin::return#0 = cbm_k_getin::ch -- vbum1=vbum2 
    sta return
    // cbm_k_getin::@return
    // }
    // [1977] cbm_k_getin::return#1 = cbm_k_getin::return#0
    // [1978] return 
    rts
  .segment Data
    ch: .byte 0
    return: .byte 0
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
// __zp($5e) struct $2 * fopen(__zp($6d) const char *path, const char *mode)
fopen: {
    .label fopen__4 = $79
    .label fopen__9 = $66
    .label fopen__11 = $c2
    .label fopen__15 = $64
    .label fopen__16 = $6f
    .label fopen__26 = $42
    .label fopen__28 = $ad
    .label fopen__30 = $5e
    .label cbm_k_setnam1_filename = $cd
    .label cbm_k_setnam1_fopen__0 = $49
    .label stream = $5e
    .label pathtoken = $6d
    .label pathtoken_1 = $b1
    .label path = $6d
    .label return = $5e
    // unsigned char sp = __stdio_filecount
    // [1980] fopen::sp#0 = __stdio_filecount -- vbum1=vbum2 
    lda __stdio_filecount
    sta sp
    // (unsigned int)sp | 0x8000
    // [1981] fopen::$30 = (unsigned int)fopen::sp#0 -- vwuz1=_word_vbum2 
    sta.z fopen__30
    lda #0
    sta.z fopen__30+1
    // [1982] fopen::stream#0 = fopen::$30 | $8000 -- vwuz1=vwuz1_bor_vwuc1 
    lda.z stream
    ora #<$8000
    sta.z stream
    lda.z stream+1
    ora #>$8000
    sta.z stream+1
    // char pathpos = sp * __STDIO_FILECOUNT
    // [1983] fopen::pathpos#0 = fopen::sp#0 << 2 -- vbum1=vbum2_rol_2 
    lda sp
    asl
    asl
    sta pathpos
    // __logical = 0
    // [1984] ((char *)&__stdio_file+$80)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy sp
    sta __stdio_file+$80,y
    // __device = 0
    // [1985] ((char *)&__stdio_file+$84)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$84,y
    // __channel = 0
    // [1986] ((char *)&__stdio_file+$88)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$88,y
    // [1987] fopen::pathtoken#22 = fopen::pathtoken#0 -- pbuz1=pbuz2 
    lda.z pathtoken
    sta.z pathtoken_1
    lda.z pathtoken+1
    sta.z pathtoken_1+1
    // [1988] fopen::pathpos#21 = fopen::pathpos#0 -- vbum1=vbum2 
    lda pathpos
    sta pathpos_1
    // [1989] phi from fopen to fopen::@8 [phi:fopen->fopen::@8]
    // [1989] phi fopen::num#10 = 0 [phi:fopen->fopen::@8#0] -- vbum1=vbuc1 
    lda #0
    sta num
    // [1989] phi fopen::pathpos#10 = fopen::pathpos#21 [phi:fopen->fopen::@8#1] -- register_copy 
    // [1989] phi fopen::path#10 = fopen::pathtoken#0 [phi:fopen->fopen::@8#2] -- register_copy 
    // [1989] phi fopen::pathstep#10 = 0 [phi:fopen->fopen::@8#3] -- vbum1=vbuc1 
    sta pathstep
    // [1989] phi fopen::pathtoken#10 = fopen::pathtoken#22 [phi:fopen->fopen::@8#4] -- register_copy 
  // Iterate while path is not \0.
    // [1989] phi from fopen::@22 to fopen::@8 [phi:fopen::@22->fopen::@8]
    // [1989] phi fopen::num#10 = fopen::num#13 [phi:fopen::@22->fopen::@8#0] -- register_copy 
    // [1989] phi fopen::pathpos#10 = fopen::pathpos#7 [phi:fopen::@22->fopen::@8#1] -- register_copy 
    // [1989] phi fopen::path#10 = fopen::path#11 [phi:fopen::@22->fopen::@8#2] -- register_copy 
    // [1989] phi fopen::pathstep#10 = fopen::pathstep#11 [phi:fopen::@22->fopen::@8#3] -- register_copy 
    // [1989] phi fopen::pathtoken#10 = fopen::pathtoken#1 [phi:fopen::@22->fopen::@8#4] -- register_copy 
    // fopen::@8
  __b8:
    // if (*pathtoken == ',' || *pathtoken == '\0')
    // [1990] if(*fopen::pathtoken#10==',') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #','
    ldy #0
    cmp (pathtoken_1),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@33
    // [1991] if(*fopen::pathtoken#10=='@') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #'@'
    cmp (pathtoken_1),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@23
    // if (pathstep == 0)
    // [1992] if(fopen::pathstep#10!=0) goto fopen::@10 -- vbum1_neq_0_then_la1 
    lda pathstep
    bne __b10
    // fopen::@24
    // __stdio_file.filename[pathpos] = *pathtoken
    // [1993] ((char *)&__stdio_file)[fopen::pathpos#10] = *fopen::pathtoken#10 -- pbuc1_derefidx_vbum1=_deref_pbuz2 
    lda (pathtoken_1),y
    ldy pathpos_1
    sta __stdio_file,y
    // pathpos++;
    // [1994] fopen::pathpos#1 = ++ fopen::pathpos#10 -- vbum1=_inc_vbum1 
    inc pathpos_1
    // [1995] phi from fopen::@12 fopen::@23 fopen::@24 to fopen::@10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10]
    // [1995] phi fopen::num#13 = fopen::num#15 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#0] -- register_copy 
    // [1995] phi fopen::pathpos#7 = fopen::pathpos#10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#1] -- register_copy 
    // [1995] phi fopen::path#11 = fopen::path#13 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#2] -- register_copy 
    // [1995] phi fopen::pathstep#11 = fopen::pathstep#1 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#3] -- register_copy 
    // fopen::@10
  __b10:
    // pathtoken++;
    // [1996] fopen::pathtoken#1 = ++ fopen::pathtoken#10 -- pbuz1=_inc_pbuz1 
    inc.z pathtoken_1
    bne !+
    inc.z pathtoken_1+1
  !:
    // fopen::@22
    // pathtoken - 1
    // [1997] fopen::$28 = fopen::pathtoken#1 - 1 -- pbuz1=pbuz2_minus_1 
    lda.z pathtoken_1
    sec
    sbc #1
    sta.z fopen__28
    lda.z pathtoken_1+1
    sbc #0
    sta.z fopen__28+1
    // while (*(pathtoken - 1))
    // [1998] if(0!=*fopen::$28) goto fopen::@8 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (fopen__28),y
    cmp #0
    bne __b8
    // fopen::@26
    // __status = 0
    // [1999] ((char *)&__stdio_file+$8c)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    tya
    ldy sp
    sta __stdio_file+$8c,y
    // if(!__logical)
    // [2000] if(0!=((char *)&__stdio_file+$80)[fopen::sp#0]) goto fopen::@1 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$80,y
    cmp #0
    bne __b1
    // fopen::@27
    // __stdio_filecount+1
    // [2001] fopen::$4 = __stdio_filecount + 1 -- vbuz1=vbum2_plus_1 
    lda __stdio_filecount
    inc
    sta.z fopen__4
    // __logical = __stdio_filecount+1
    // [2002] ((char *)&__stdio_file+$80)[fopen::sp#0] = fopen::$4 -- pbuc1_derefidx_vbum1=vbuz2 
    sta __stdio_file+$80,y
    // fopen::@1
  __b1:
    // if(!__device)
    // [2003] if(0!=((char *)&__stdio_file+$84)[fopen::sp#0]) goto fopen::@2 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    ldy sp
    lda __stdio_file+$84,y
    cmp #0
    bne __b2
    // fopen::@5
    // __device = 8
    // [2004] ((char *)&__stdio_file+$84)[fopen::sp#0] = 8 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #8
    sta __stdio_file+$84,y
    // fopen::@2
  __b2:
    // if(!__channel)
    // [2005] if(0!=((char *)&__stdio_file+$88)[fopen::sp#0]) goto fopen::@3 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    ldy sp
    lda __stdio_file+$88,y
    cmp #0
    bne __b3
    // fopen::@6
    // __stdio_filecount+2
    // [2006] fopen::$9 = __stdio_filecount + 2 -- vbuz1=vbum2_plus_2 
    lda __stdio_filecount
    clc
    adc #2
    sta.z fopen__9
    // __channel = __stdio_filecount+2
    // [2007] ((char *)&__stdio_file+$88)[fopen::sp#0] = fopen::$9 -- pbuc1_derefidx_vbum1=vbuz2 
    sta __stdio_file+$88,y
    // fopen::@3
  __b3:
    // __filename
    // [2008] fopen::$11 = (char *)&__stdio_file + fopen::pathpos#0 -- pbuz1=pbuc1_plus_vbum2 
    lda pathpos
    clc
    adc #<__stdio_file
    sta.z fopen__11
    lda #>__stdio_file
    adc #0
    sta.z fopen__11+1
    // cbm_k_setnam(__filename)
    // [2009] fopen::cbm_k_setnam1_filename = fopen::$11 -- pbuz1=pbuz2 
    lda.z fopen__11
    sta.z cbm_k_setnam1_filename
    lda.z fopen__11+1
    sta.z cbm_k_setnam1_filename+1
    // fopen::cbm_k_setnam1
    // strlen(filename)
    // [2010] strlen::str#4 = fopen::cbm_k_setnam1_filename -- pbuz1=pbuz2 
    lda.z cbm_k_setnam1_filename
    sta.z strlen.str
    lda.z cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [2011] call strlen
    // [2170] phi from fopen::cbm_k_setnam1 to strlen [phi:fopen::cbm_k_setnam1->strlen]
    // [2170] phi strlen::str#8 = strlen::str#4 [phi:fopen::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [2012] strlen::return#11 = strlen::len#2
    // fopen::@31
    // [2013] fopen::cbm_k_setnam1_$0 = strlen::return#11 -- vwuz1=vwum2 
    lda strlen.return
    sta.z cbm_k_setnam1_fopen__0
    lda strlen.return+1
    sta.z cbm_k_setnam1_fopen__0+1
    // char filename_len = (char)strlen(filename)
    // [2014] fopen::cbm_k_setnam1_filename_len = (char)fopen::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
    lda.z cbm_k_setnam1_fopen__0
    sta cbm_k_setnam1_filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx cbm_k_setnam1_filename
    ldy cbm_k_setnam1_filename+1
    jsr CBM_SETNAM
    // fopen::@28
    // cbm_k_setlfs(__logical, __device, __channel)
    // [2016] cbm_k_setlfs::channel = ((char *)&__stdio_file+$80)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$80,y
    sta cbm_k_setlfs.channel
    // [2017] cbm_k_setlfs::device = ((char *)&__stdio_file+$84)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    lda __stdio_file+$84,y
    sta cbm_k_setlfs.device
    // [2018] cbm_k_setlfs::command = ((char *)&__stdio_file+$88)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    lda __stdio_file+$88,y
    sta cbm_k_setlfs.command
    // [2019] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // fopen::cbm_k_open1
    // asm
    // asm { jsrCBM_OPEN  }
    jsr CBM_OPEN
    // fopen::cbm_k_readst1
    // char status
    // [2021] fopen::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2023] fopen::cbm_k_readst1_return#0 = fopen::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // fopen::cbm_k_readst1_@return
    // }
    // [2024] fopen::cbm_k_readst1_return#1 = fopen::cbm_k_readst1_return#0
    // fopen::@29
    // cbm_k_readst()
    // [2025] fopen::$15 = fopen::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z fopen__15
    // __status = cbm_k_readst()
    // [2026] ((char *)&__stdio_file+$8c)[fopen::sp#0] = fopen::$15 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$8c,y
    // ferror(stream)
    // [2027] ferror::stream#0 = (struct $2 *)fopen::stream#0
    // [2028] call ferror
    jsr ferror
    // [2029] ferror::return#0 = ferror::return#1
    // fopen::@32
    // [2030] fopen::$16 = ferror::return#0 -- vwsz1=vwsm2 
    lda ferror.return
    sta.z fopen__16
    lda ferror.return+1
    sta.z fopen__16+1
    // if (ferror(stream))
    // [2031] if(0==fopen::$16) goto fopen::@4 -- 0_eq_vwsz1_then_la1 
    lda.z fopen__16
    ora.z fopen__16+1
    beq __b4
    // fopen::@7
    // cbm_k_close(__logical)
    // [2032] fopen::cbm_k_close1_channel = ((char *)&__stdio_file+$80)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$80,y
    sta cbm_k_close1_channel
    // fopen::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // [2034] phi from fopen::cbm_k_close1 to fopen::@return [phi:fopen::cbm_k_close1->fopen::@return]
    // [2034] phi fopen::return#2 = 0 [phi:fopen::cbm_k_close1->fopen::@return#0] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fopen::@return
    // }
    // [2035] return 
    rts
    // fopen::@4
  __b4:
    // __stdio_filecount++;
    // [2036] __stdio_filecount = ++ __stdio_filecount -- vbum1=_inc_vbum1 
    inc __stdio_filecount
    // [2037] fopen::return#8 = (struct $2 *)fopen::stream#0
    // [2034] phi from fopen::@4 to fopen::@return [phi:fopen::@4->fopen::@return]
    // [2034] phi fopen::return#2 = fopen::return#8 [phi:fopen::@4->fopen::@return#0] -- register_copy 
    rts
    // fopen::@9
  __b9:
    // if (pathstep > 0)
    // [2038] if(fopen::pathstep#10>0) goto fopen::@11 -- vbum1_gt_0_then_la1 
    lda pathstep
    bne __b11
    // fopen::@25
    // __stdio_file.filename[pathpos] = '\0'
    // [2039] ((char *)&__stdio_file)[fopen::pathpos#10] = '@' -- pbuc1_derefidx_vbum1=vbuc2 
    lda #'@'
    ldy pathpos_1
    sta __stdio_file,y
    // path = pathtoken + 1
    // [2040] fopen::path#0 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
    clc
    lda.z pathtoken_1
    adc #1
    sta.z path
    lda.z pathtoken_1+1
    adc #0
    sta.z path+1
    // [2041] phi from fopen::@16 fopen::@17 fopen::@18 fopen::@19 fopen::@25 to fopen::@12 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12]
    // [2041] phi fopen::num#15 = fopen::num#2 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#0] -- register_copy 
    // [2041] phi fopen::path#13 = fopen::path#16 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#1] -- register_copy 
    // fopen::@12
  __b12:
    // pathstep++;
    // [2042] fopen::pathstep#1 = ++ fopen::pathstep#10 -- vbum1=_inc_vbum1 
    inc pathstep
    jmp __b10
    // fopen::@11
  __b11:
    // char pathcmp = *path
    // [2043] fopen::pathcmp#0 = *fopen::path#10 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (path),y
    sta pathcmp
    // case 'D':
    // [2044] if(fopen::pathcmp#0=='D') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'D'
    cmp pathcmp
    beq __b13
    // fopen::@20
    // case 'L':
    // [2045] if(fopen::pathcmp#0=='L') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'L'
    cmp pathcmp
    beq __b13
    // fopen::@21
    // case 'C':
    //                     num = (char)atoi(path + 1);
    //                     path = pathtoken + 1;
    // [2046] if(fopen::pathcmp#0=='C') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'C'
    cmp pathcmp
    beq __b13
    // [2047] phi from fopen::@21 fopen::@30 to fopen::@14 [phi:fopen::@21/fopen::@30->fopen::@14]
    // [2047] phi fopen::path#16 = fopen::path#10 [phi:fopen::@21/fopen::@30->fopen::@14#0] -- register_copy 
    // [2047] phi fopen::num#2 = fopen::num#10 [phi:fopen::@21/fopen::@30->fopen::@14#1] -- register_copy 
    // fopen::@14
  __b14:
    // case 'L':
    //                     __logical = num;
    //                     break;
    // [2048] if(fopen::pathcmp#0=='L') goto fopen::@17 -- vbum1_eq_vbuc1_then_la1 
    lda #'L'
    cmp pathcmp
    beq __b17
    // fopen::@15
    // case 'D':
    //                     __device = num;
    //                     break;
    // [2049] if(fopen::pathcmp#0=='D') goto fopen::@18 -- vbum1_eq_vbuc1_then_la1 
    lda #'D'
    cmp pathcmp
    beq __b18
    // fopen::@16
    // case 'C':
    //                     __channel = num;
    //                     break;
    // [2050] if(fopen::pathcmp#0!='C') goto fopen::@12 -- vbum1_neq_vbuc1_then_la1 
    lda #'C'
    cmp pathcmp
    bne __b12
    // fopen::@19
    // __channel = num
    // [2051] ((char *)&__stdio_file+$88)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbum2 
    lda num
    ldy sp
    sta __stdio_file+$88,y
    jmp __b12
    // fopen::@18
  __b18:
    // __device = num
    // [2052] ((char *)&__stdio_file+$84)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbum2 
    lda num
    ldy sp
    sta __stdio_file+$84,y
    jmp __b12
    // fopen::@17
  __b17:
    // __logical = num
    // [2053] ((char *)&__stdio_file+$80)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbum2 
    lda num
    ldy sp
    sta __stdio_file+$80,y
    jmp __b12
    // fopen::@13
  __b13:
    // atoi(path + 1)
    // [2054] atoi::str#0 = fopen::path#10 + 1 -- pbuz1=pbuz1_plus_1 
    inc.z atoi.str
    bne !+
    inc.z atoi.str+1
  !:
    // [2055] call atoi
    // [2495] phi from fopen::@13 to atoi [phi:fopen::@13->atoi]
    // [2495] phi atoi::str#2 = atoi::str#0 [phi:fopen::@13->atoi#0] -- register_copy 
    jsr atoi
    // atoi(path + 1)
    // [2056] atoi::return#3 = atoi::return#2
    // fopen::@30
    // [2057] fopen::$26 = atoi::return#3 -- vwsz1=vwsm2 
    lda atoi.return
    sta.z fopen__26
    lda atoi.return+1
    sta.z fopen__26+1
    // num = (char)atoi(path + 1)
    // [2058] fopen::num#1 = (char)fopen::$26 -- vbum1=_byte_vwsz2 
    lda.z fopen__26
    sta num
    // path = pathtoken + 1
    // [2059] fopen::path#1 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
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
// __mem() unsigned int fgets(__zp($5e) char *ptr, __mem() unsigned int size, __zp($7a) struct $2 *stream)
fgets: {
    .label fgets__1 = $79
    .label fgets__8 = $66
    .label fgets__9 = $64
    .label fgets__13 = $65
    .label ptr = $5e
    .label stream = $7a
    // unsigned char sp = (unsigned char)stream
    // [2061] fgets::sp#0 = (char)fgets::stream#2 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_chkin(__logical)
    // [2062] fgets::cbm_k_chkin1_channel = ((char *)&__stdio_file+$80)[fgets::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    tay
    lda __stdio_file+$80,y
    sta cbm_k_chkin1_channel
    // fgets::cbm_k_chkin1
    // char status
    // [2063] fgets::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fgets::cbm_k_readst1
    // char status
    // [2065] fgets::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2067] fgets::cbm_k_readst1_return#0 = fgets::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // fgets::cbm_k_readst1_@return
    // }
    // [2068] fgets::cbm_k_readst1_return#1 = fgets::cbm_k_readst1_return#0
    // fgets::@11
    // cbm_k_readst()
    // [2069] fgets::$1 = fgets::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z fgets__1
    // __status = cbm_k_readst()
    // [2070] ((char *)&__stdio_file+$8c)[fgets::sp#0] = fgets::$1 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$8c,y
    // if (__status)
    // [2071] if(0==((char *)&__stdio_file+$8c)[fgets::sp#0]) goto fgets::@1 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$8c,y
    cmp #0
    beq __b1
    // [2072] phi from fgets::@11 fgets::@12 fgets::@5 to fgets::@return [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return]
  __b8:
    // [2072] phi fgets::return#1 = 0 [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return#0] -- vwum1=vbuc1 
    lda #<0
    sta return
    sta return+1
    // fgets::@return
    // }
    // [2073] return 
    rts
    // fgets::@1
  __b1:
    // [2074] fgets::remaining#22 = fgets::size#10 -- vwum1=vwum2 
    lda size
    sta remaining
    lda size+1
    sta remaining+1
    // [2075] phi from fgets::@1 to fgets::@2 [phi:fgets::@1->fgets::@2]
    // [2075] phi fgets::read#10 = 0 [phi:fgets::@1->fgets::@2#0] -- vwum1=vwuc1 
    lda #<0
    sta read
    sta read+1
    // [2075] phi fgets::remaining#11 = fgets::remaining#22 [phi:fgets::@1->fgets::@2#1] -- register_copy 
    // [2075] phi fgets::ptr#10 = fgets::ptr#12 [phi:fgets::@1->fgets::@2#2] -- register_copy 
    // [2075] phi from fgets::@17 fgets::@18 to fgets::@2 [phi:fgets::@17/fgets::@18->fgets::@2]
    // [2075] phi fgets::read#10 = fgets::read#1 [phi:fgets::@17/fgets::@18->fgets::@2#0] -- register_copy 
    // [2075] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@17/fgets::@18->fgets::@2#1] -- register_copy 
    // [2075] phi fgets::ptr#10 = fgets::ptr#13 [phi:fgets::@17/fgets::@18->fgets::@2#2] -- register_copy 
    // fgets::@2
  __b2:
    // if (!size)
    // [2076] if(0==fgets::size#10) goto fgets::@3 -- 0_eq_vwum1_then_la1 
    lda size
    ora size+1
    bne !__b3+
    jmp __b3
  !__b3:
    // fgets::@8
    // if (remaining >= 512)
    // [2077] if(fgets::remaining#11>=$200) goto fgets::@4 -- vwum1_ge_vwuc1_then_la1 
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
    // [2078] cx16_k_macptr::bytes = fgets::remaining#11 -- vbum1=vwum2 
    lda remaining
    sta cx16_k_macptr.bytes
    // [2079] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2080] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2081] cx16_k_macptr::return#4 = cx16_k_macptr::return#1
    // fgets::@15
  __b15:
    // bytes = cx16_k_macptr(remaining, ptr)
    // [2082] fgets::bytes#3 = cx16_k_macptr::return#4
    // [2083] phi from fgets::@13 fgets::@14 fgets::@15 to fgets::cbm_k_readst2 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2]
    // [2083] phi fgets::bytes#10 = fgets::bytes#1 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2#0] -- register_copy 
    // fgets::cbm_k_readst2
    // char status
    // [2084] fgets::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [2086] fgets::cbm_k_readst2_return#0 = fgets::cbm_k_readst2_status -- vbum1=vbum2 
    sta cbm_k_readst2_return
    // fgets::cbm_k_readst2_@return
    // }
    // [2087] fgets::cbm_k_readst2_return#1 = fgets::cbm_k_readst2_return#0
    // fgets::@12
    // cbm_k_readst()
    // [2088] fgets::$8 = fgets::cbm_k_readst2_return#1 -- vbuz1=vbum2 
    sta.z fgets__8
    // __status = cbm_k_readst()
    // [2089] ((char *)&__stdio_file+$8c)[fgets::sp#0] = fgets::$8 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$8c,y
    // __status & 0xBF
    // [2090] fgets::$9 = ((char *)&__stdio_file+$8c)[fgets::sp#0] & $bf -- vbuz1=pbuc1_derefidx_vbum2_band_vbuc2 
    lda #$bf
    and __stdio_file+$8c,y
    sta.z fgets__9
    // if (__status & 0xBF)
    // [2091] if(0==fgets::$9) goto fgets::@5 -- 0_eq_vbuz1_then_la1 
    beq __b5
    jmp __b8
    // fgets::@5
  __b5:
    // if (bytes == 0xFFFF)
    // [2092] if(fgets::bytes#10!=$ffff) goto fgets::@6 -- vwum1_neq_vwuc1_then_la1 
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
    // [2093] fgets::read#1 = fgets::read#10 + fgets::bytes#10 -- vwum1=vwum1_plus_vwum2 
    clc
    lda read
    adc bytes
    sta read
    lda read+1
    adc bytes+1
    sta read+1
    // ptr += bytes
    // [2094] fgets::ptr#0 = fgets::ptr#10 + fgets::bytes#10 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z ptr
    adc bytes
    sta.z ptr
    lda.z ptr+1
    adc bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [2095] fgets::$13 = byte1  fgets::ptr#0 -- vbuz1=_byte1_pbuz2 
    sta.z fgets__13
    // if (BYTE1(ptr) == 0xC0)
    // [2096] if(fgets::$13!=$c0) goto fgets::@7 -- vbuz1_neq_vbuc1_then_la1 
    lda #$c0
    cmp.z fgets__13
    bne __b7
    // fgets::@10
    // ptr -= 0x2000
    // [2097] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [2098] phi from fgets::@10 fgets::@6 to fgets::@7 [phi:fgets::@10/fgets::@6->fgets::@7]
    // [2098] phi fgets::ptr#13 = fgets::ptr#1 [phi:fgets::@10/fgets::@6->fgets::@7#0] -- register_copy 
    // fgets::@7
  __b7:
    // remaining -= bytes
    // [2099] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#10 -- vwum1=vwum1_minus_vwum2 
    lda remaining
    sec
    sbc bytes
    sta remaining
    lda remaining+1
    sbc bytes+1
    sta remaining+1
    // while ((__status == 0) && ((size && remaining) || !size))
    // [2100] if(((char *)&__stdio_file+$8c)[fgets::sp#0]==0) goto fgets::@16 -- pbuc1_derefidx_vbum1_eq_0_then_la1 
    ldy sp
    lda __stdio_file+$8c,y
    cmp #0
    beq __b16
    // [2072] phi from fgets::@17 fgets::@7 to fgets::@return [phi:fgets::@17/fgets::@7->fgets::@return]
    // [2072] phi fgets::return#1 = fgets::read#1 [phi:fgets::@17/fgets::@7->fgets::@return#0] -- register_copy 
    rts
    // fgets::@16
  __b16:
    // while ((__status == 0) && ((size && remaining) || !size))
    // [2101] if(0==fgets::size#10) goto fgets::@17 -- 0_eq_vwum1_then_la1 
    lda size
    ora size+1
    beq __b17
    // fgets::@18
    // [2102] if(0!=fgets::remaining#1) goto fgets::@2 -- 0_neq_vwum1_then_la1 
    lda remaining
    ora remaining+1
    beq !__b2+
    jmp __b2
  !__b2:
    // fgets::@17
  __b17:
    // [2103] if(0==fgets::size#10) goto fgets::@2 -- 0_eq_vwum1_then_la1 
    lda size
    ora size+1
    bne !__b2+
    jmp __b2
  !__b2:
    rts
    // fgets::@4
  __b4:
    // cx16_k_macptr(512, ptr)
    // [2104] cx16_k_macptr::bytes = $200 -- vbum1=vwuc1 
    lda #<$200
    sta cx16_k_macptr.bytes
    // [2105] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2106] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2107] cx16_k_macptr::return#3 = cx16_k_macptr::return#1
    // fgets::@14
    // bytes = cx16_k_macptr(512, ptr)
    // [2108] fgets::bytes#2 = cx16_k_macptr::return#3
    jmp __b15
    // fgets::@3
  __b3:
    // cx16_k_macptr(0, ptr)
    // [2109] cx16_k_macptr::bytes = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_macptr.bytes
    // [2110] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2111] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2112] cx16_k_macptr::return#2 = cx16_k_macptr::return#1
    // fgets::@13
    // bytes = cx16_k_macptr(0, ptr)
    // [2113] fgets::bytes#1 = cx16_k_macptr::return#2
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
// int fclose(__zp($60) struct $2 *stream)
fclose: {
    .label fclose__1 = $65
    .label fclose__4 = $46
    .label fclose__6 = $77
    .label stream = $60
    // unsigned char sp = (unsigned char)stream
    // [2115] fclose::sp#0 = (char)fclose::stream#2 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_chkin(__logical)
    // [2116] fclose::cbm_k_chkin1_channel = ((char *)&__stdio_file+$80)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    tay
    lda __stdio_file+$80,y
    sta cbm_k_chkin1_channel
    // fclose::cbm_k_chkin1
    // char status
    // [2117] fclose::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fclose::cbm_k_readst1
    // char status
    // [2119] fclose::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2121] fclose::cbm_k_readst1_return#0 = fclose::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // fclose::cbm_k_readst1_@return
    // }
    // [2122] fclose::cbm_k_readst1_return#1 = fclose::cbm_k_readst1_return#0
    // fclose::@3
    // cbm_k_readst()
    // [2123] fclose::$1 = fclose::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z fclose__1
    // __status = cbm_k_readst()
    // [2124] ((char *)&__stdio_file+$8c)[fclose::sp#0] = fclose::$1 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$8c,y
    // if (__status)
    // [2125] if(0==((char *)&__stdio_file+$8c)[fclose::sp#0]) goto fclose::@1 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$8c,y
    cmp #0
    beq __b1
    // fclose::@return
    // }
    // [2126] return 
    rts
    // fclose::@1
  __b1:
    // cbm_k_close(__logical)
    // [2127] fclose::cbm_k_close1_channel = ((char *)&__stdio_file+$80)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$80,y
    sta cbm_k_close1_channel
    // fclose::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // fclose::cbm_k_readst2
    // char status
    // [2129] fclose::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [2131] fclose::cbm_k_readst2_return#0 = fclose::cbm_k_readst2_status -- vbum1=vbum2 
    sta cbm_k_readst2_return
    // fclose::cbm_k_readst2_@return
    // }
    // [2132] fclose::cbm_k_readst2_return#1 = fclose::cbm_k_readst2_return#0
    // fclose::@4
    // cbm_k_readst()
    // [2133] fclose::$4 = fclose::cbm_k_readst2_return#1 -- vbuz1=vbum2 
    sta.z fclose__4
    // __status = cbm_k_readst()
    // [2134] ((char *)&__stdio_file+$8c)[fclose::sp#0] = fclose::$4 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$8c,y
    // if (__status)
    // [2135] if(0==((char *)&__stdio_file+$8c)[fclose::sp#0]) goto fclose::@2 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$8c,y
    cmp #0
    beq __b2
    rts
    // fclose::@2
  __b2:
    // __logical = 0
    // [2136] ((char *)&__stdio_file+$80)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy sp
    sta __stdio_file+$80,y
    // __device = 0
    // [2137] ((char *)&__stdio_file+$84)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$84,y
    // __channel = 0
    // [2138] ((char *)&__stdio_file+$88)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$88,y
    // __filename
    // [2139] fclose::$6 = fclose::sp#0 << 2 -- vbuz1=vbum2_rol_2 
    tya
    asl
    asl
    sta.z fclose__6
    // *__filename = '\0'
    // [2140] ((char *)&__stdio_file)[fclose::$6] = '@' -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #'@'
    ldy.z fclose__6
    sta __stdio_file,y
    // __stdio_filecount--;
    // [2141] __stdio_filecount = -- __stdio_filecount -- vbum1=_dec_vbum1 
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
  // uctoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void uctoa(__mem() char value, __zp($38) char *buffer, __mem() char radix)
uctoa: {
    .label uctoa__4 = $46
    .label buffer = $38
    .label digit_values = $60
    // if(radix==DECIMAL)
    // [2142] if(uctoa::radix#0==DECIMAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // uctoa::@2
    // if(radix==HEXADECIMAL)
    // [2143] if(uctoa::radix#0==HEXADECIMAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // uctoa::@3
    // if(radix==OCTAL)
    // [2144] if(uctoa::radix#0==OCTAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // uctoa::@4
    // if(radix==BINARY)
    // [2145] if(uctoa::radix#0==BINARY) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // uctoa::@5
    // *buffer++ = 'e'
    // [2146] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2147] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2148] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2149] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // uctoa::@return
    // }
    // [2150] return 
    rts
    // [2151] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
  __b2:
    // [2151] phi uctoa::digit_values#8 = RADIX_DECIMAL_VALUES_CHAR [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [2151] phi uctoa::max_digits#7 = 3 [phi:uctoa->uctoa::@1#1] -- vbum1=vbuc1 
    lda #3
    sta max_digits
    jmp __b1
    // [2151] phi from uctoa::@2 to uctoa::@1 [phi:uctoa::@2->uctoa::@1]
  __b3:
    // [2151] phi uctoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_CHAR [phi:uctoa::@2->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [2151] phi uctoa::max_digits#7 = 2 [phi:uctoa::@2->uctoa::@1#1] -- vbum1=vbuc1 
    lda #2
    sta max_digits
    jmp __b1
    // [2151] phi from uctoa::@3 to uctoa::@1 [phi:uctoa::@3->uctoa::@1]
  __b4:
    // [2151] phi uctoa::digit_values#8 = RADIX_OCTAL_VALUES_CHAR [phi:uctoa::@3->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values+1
    // [2151] phi uctoa::max_digits#7 = 3 [phi:uctoa::@3->uctoa::@1#1] -- vbum1=vbuc1 
    lda #3
    sta max_digits
    jmp __b1
    // [2151] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
  __b5:
    // [2151] phi uctoa::digit_values#8 = RADIX_BINARY_VALUES_CHAR [phi:uctoa::@4->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_BINARY_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_CHAR
    sta.z digit_values+1
    // [2151] phi uctoa::max_digits#7 = 8 [phi:uctoa::@4->uctoa::@1#1] -- vbum1=vbuc1 
    lda #8
    sta max_digits
    // uctoa::@1
  __b1:
    // [2152] phi from uctoa::@1 to uctoa::@6 [phi:uctoa::@1->uctoa::@6]
    // [2152] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa::@1->uctoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2152] phi uctoa::started#2 = 0 [phi:uctoa::@1->uctoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [2152] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa::@1->uctoa::@6#2] -- register_copy 
    // [2152] phi uctoa::digit#2 = 0 [phi:uctoa::@1->uctoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // uctoa::@6
  __b6:
    // max_digits-1
    // [2153] uctoa::$4 = uctoa::max_digits#7 - 1 -- vbuz1=vbum2_minus_1 
    ldx max_digits
    dex
    stx.z uctoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2154] if(uctoa::digit#2<uctoa::$4) goto uctoa::@7 -- vbum1_lt_vbuz2_then_la1 
    lda digit
    cmp.z uctoa__4
    bcc __b7
    // uctoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2155] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy value
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2156] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2157] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // uctoa::@7
  __b7:
    // unsigned char digit_value = digit_values[digit]
    // [2158] uctoa::digit_value#0 = uctoa::digit_values#8[uctoa::digit#2] -- vbum1=pbuz2_derefidx_vbum3 
    ldy digit
    lda (digit_values),y
    sta digit_value
    // if (started || value >= digit_value)
    // [2159] if(0!=uctoa::started#2) goto uctoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // uctoa::@12
    // [2160] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@10 -- vbum1_ge_vbum2_then_la1 
    lda value
    cmp digit_value
    bcs __b10
    // [2161] phi from uctoa::@12 to uctoa::@9 [phi:uctoa::@12->uctoa::@9]
    // [2161] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@12->uctoa::@9#0] -- register_copy 
    // [2161] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@12->uctoa::@9#1] -- register_copy 
    // [2161] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@12->uctoa::@9#2] -- register_copy 
    // uctoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2162] uctoa::digit#1 = ++ uctoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [2152] phi from uctoa::@9 to uctoa::@6 [phi:uctoa::@9->uctoa::@6]
    // [2152] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@9->uctoa::@6#0] -- register_copy 
    // [2152] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@9->uctoa::@6#1] -- register_copy 
    // [2152] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@9->uctoa::@6#2] -- register_copy 
    // [2152] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@9->uctoa::@6#3] -- register_copy 
    jmp __b6
    // uctoa::@10
  __b10:
    // uctoa_append(buffer++, value, digit_value)
    // [2163] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [2164] uctoa_append::value#0 = uctoa::value#2
    // [2165] uctoa_append::sub#0 = uctoa::digit_value#0
    // [2166] call uctoa_append
    // [2516] phi from uctoa::@10 to uctoa_append [phi:uctoa::@10->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [2167] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@11
    // value = uctoa_append(buffer++, value, digit_value)
    // [2168] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [2169] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2161] phi from uctoa::@11 to uctoa::@9 [phi:uctoa::@11->uctoa::@9]
    // [2161] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@11->uctoa::@9#0] -- register_copy 
    // [2161] phi uctoa::started#4 = 1 [phi:uctoa::@11->uctoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [2161] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@11->uctoa::@9#2] -- register_copy 
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
  // strlen
// Computes the length of the string str up to but not including the terminating null character.
// __mem() unsigned int strlen(__zp($38) char *str)
strlen: {
    .label str = $38
    // [2171] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [2171] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta len
    sta len+1
    // [2171] phi strlen::str#6 = strlen::str#8 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [2172] if(0!=*strlen::str#6) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [2173] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [2174] strlen::len#1 = ++ strlen::len#2 -- vwum1=_inc_vwum1 
    inc len
    bne !+
    inc len+1
  !:
    // str++;
    // [2175] strlen::str#1 = ++ strlen::str#6 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [2171] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [2171] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [2171] phi strlen::str#6 = strlen::str#1 [phi:strlen::@2->strlen::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label return = len
    len: .word 0
}
.segment Code
  // printf_padding
// Print a padding char a number of times
// void printf_padding(__zp($58) void (*putc)(char), __mem() char pad, __mem() char length)
printf_padding: {
    .label putc = $58
    // [2177] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [2177] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbum1=vbuc1 
    lda #0
    sta i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [2178] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbum1_lt_vbum2_then_la1 
    lda i
    cmp length
    bcc __b2
    // printf_padding::@return
    // }
    // [2179] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [2180] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbum1 
    lda pad
    pha
    // [2181] callexecute *printf_padding::putc#7  -- call__deref_pprz1 
    jsr icall35
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [2183] printf_padding::i#1 = ++ printf_padding::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [2177] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [2177] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
    jmp __b1
    // Outside Flow
  icall35:
    jmp (putc)
  .segment Data
    i: .byte 0
    length: .byte 0
    pad: .byte 0
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
// __mem() unsigned long rom_address_from_bank(__zp($c8) char rom_bank)
rom_address_from_bank: {
    .label rom_address_from_bank__1 = $a9
    .label rom_bank = $c8
    // ((unsigned long)(rom_bank)) << 14
    // [2185] rom_address_from_bank::$1 = (unsigned long)rom_address_from_bank::rom_bank#3 -- vduz1=_dword_vbuz2 
    lda.z rom_bank
    sta.z rom_address_from_bank__1
    lda #0
    sta.z rom_address_from_bank__1+1
    sta.z rom_address_from_bank__1+2
    sta.z rom_address_from_bank__1+3
    // [2186] rom_address_from_bank::return#0 = rom_address_from_bank::$1 << $e -- vdum1=vduz2_rol_vbuc1 
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
    // [2187] return 
    rts
  .segment Data
    .label return = rom_read.rom_address
    .label return_1 = rom_verify.rom_address
    .label return_2 = rom_flash.rom_address_sector
}
.segment Code
  // rom_compare
// __mem() unsigned int rom_compare(__zp($ba) char bank_ram, __zp($58) char *ptr_ram, __zp($4f) unsigned long rom_compare_address, __zp($69) unsigned int rom_compare_size)
rom_compare: {
    .label rom_compare__5 = $46
    .label rom_bank1_rom_compare__0 = $77
    .label rom_bank1_rom_compare__1 = $29
    .label rom_bank1_rom_compare__2 = $6f
    .label rom_ptr1_rom_compare__0 = $4d
    .label rom_ptr1_rom_compare__2 = $4d
    .label rom_ptr1_return = $4d
    .label ptr_rom = $4d
    .label ptr_ram = $58
    .label bank_ram = $ba
    .label rom_compare_address = $4f
    .label bank_ram_1 = $76
    .label bank_ram_2 = $7c
    .label rom_compare_size = $69
    // rom_compare::bank_set_bram1
    // BRAM = bank
    // [2189] BRAM = rom_compare::bank_set_bram1_bank#0 -- vbuz1=vbum2 
    lda bank_set_bram1_bank
    sta.z BRAM
    // rom_compare::rom_bank1
    // BYTE2(address)
    // [2190] rom_compare::rom_bank1_$0 = byte2  rom_compare::rom_compare_address#3 -- vbuz1=_byte2_vduz2 
    lda.z rom_compare_address+2
    sta.z rom_bank1_rom_compare__0
    // BYTE1(address)
    // [2191] rom_compare::rom_bank1_$1 = byte1  rom_compare::rom_compare_address#3 -- vbuz1=_byte1_vduz2 
    lda.z rom_compare_address+1
    sta.z rom_bank1_rom_compare__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2192] rom_compare::rom_bank1_$2 = rom_compare::rom_bank1_$0 w= rom_compare::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_compare__0
    sta.z rom_bank1_rom_compare__2+1
    lda.z rom_bank1_rom_compare__1
    sta.z rom_bank1_rom_compare__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2193] rom_compare::rom_bank1_bank_unshifted#0 = rom_compare::rom_bank1_$2 << 2 -- vwum1=vwuz2_rol_2 
    asl
    sta rom_bank1_bank_unshifted
    lda.z rom_bank1_rom_compare__2+1
    rol
    sta rom_bank1_bank_unshifted+1
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2194] rom_compare::rom_bank1_return#0 = byte1  rom_compare::rom_bank1_bank_unshifted#0 -- vbum1=_byte1_vwum2 
    lda rom_bank1_bank_unshifted+1
    sta rom_bank1_return
    // rom_compare::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2195] rom_compare::rom_ptr1_$2 = (unsigned int)rom_compare::rom_compare_address#3 -- vwuz1=_word_vduz2 
    lda.z rom_compare_address
    sta.z rom_ptr1_rom_compare__2
    lda.z rom_compare_address+1
    sta.z rom_ptr1_rom_compare__2+1
    // [2196] rom_compare::rom_ptr1_$0 = rom_compare::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_compare__0
    and #<$3fff
    sta.z rom_ptr1_rom_compare__0
    lda.z rom_ptr1_rom_compare__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_compare__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2197] rom_compare::rom_ptr1_return#0 = rom_compare::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_compare::bank_set_brom1
    // BROM = bank
    // [2198] BROM = rom_compare::rom_bank1_return#0 -- vbuz1=vbum2 
    lda rom_bank1_return
    sta.z BROM
    // [2199] rom_compare::ptr_rom#9 = (char *)rom_compare::rom_ptr1_return#0
    // [2200] phi from rom_compare::bank_set_brom1 to rom_compare::@1 [phi:rom_compare::bank_set_brom1->rom_compare::@1]
    // [2200] phi rom_compare::equal_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta equal_bytes
    sta equal_bytes+1
    // [2200] phi rom_compare::ptr_ram#4 = rom_compare::ptr_ram#10 [phi:rom_compare::bank_set_brom1->rom_compare::@1#1] -- register_copy 
    // [2200] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#9 [phi:rom_compare::bank_set_brom1->rom_compare::@1#2] -- register_copy 
    // [2200] phi rom_compare::compared_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#3] -- vwum1=vwuc1 
    sta compared_bytes
    sta compared_bytes+1
    // rom_compare::@1
  __b1:
    // while (compared_bytes < rom_compare_size)
    // [2201] if(rom_compare::compared_bytes#2<rom_compare::rom_compare_size#11) goto rom_compare::@2 -- vwum1_lt_vwuz2_then_la1 
    lda compared_bytes+1
    cmp.z rom_compare_size+1
    bcc __b2
    bne !+
    lda compared_bytes
    cmp.z rom_compare_size
    bcc __b2
  !:
    // rom_compare::@return
    // }
    // [2202] return 
    rts
    // rom_compare::@2
  __b2:
    // rom_byte_compare(ptr_rom, *ptr_ram)
    // [2203] rom_byte_compare::ptr_rom#0 = rom_compare::ptr_rom#2
    // [2204] rom_byte_compare::value#0 = *rom_compare::ptr_ram#4 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (ptr_ram),y
    sta.z rom_byte_compare.value
    // [2205] call rom_byte_compare
    jsr rom_byte_compare
    // [2206] rom_byte_compare::return#2 = rom_byte_compare::return#0
    // rom_compare::@5
    // [2207] rom_compare::$5 = rom_byte_compare::return#2 -- vbuz1=vbum2 
    lda rom_byte_compare.return
    sta.z rom_compare__5
    // if (rom_byte_compare(ptr_rom, *ptr_ram))
    // [2208] if(0==rom_compare::$5) goto rom_compare::@3 -- 0_eq_vbuz1_then_la1 
    beq __b3
    // rom_compare::@4
    // equal_bytes++;
    // [2209] rom_compare::equal_bytes#1 = ++ rom_compare::equal_bytes#2 -- vwum1=_inc_vwum1 
    inc equal_bytes
    bne !+
    inc equal_bytes+1
  !:
    // [2210] phi from rom_compare::@4 rom_compare::@5 to rom_compare::@3 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3]
    // [2210] phi rom_compare::equal_bytes#6 = rom_compare::equal_bytes#1 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3#0] -- register_copy 
    // rom_compare::@3
  __b3:
    // ptr_rom++;
    // [2211] rom_compare::ptr_rom#1 = ++ rom_compare::ptr_rom#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr_rom
    bne !+
    inc.z ptr_rom+1
  !:
    // ptr_ram++;
    // [2212] rom_compare::ptr_ram#0 = ++ rom_compare::ptr_ram#4 -- pbuz1=_inc_pbuz1 
    inc.z ptr_ram
    bne !+
    inc.z ptr_ram+1
  !:
    // compared_bytes++;
    // [2213] rom_compare::compared_bytes#1 = ++ rom_compare::compared_bytes#2 -- vwum1=_inc_vwum1 
    inc compared_bytes
    bne !+
    inc compared_bytes+1
  !:
    // [2200] phi from rom_compare::@3 to rom_compare::@1 [phi:rom_compare::@3->rom_compare::@1]
    // [2200] phi rom_compare::equal_bytes#2 = rom_compare::equal_bytes#6 [phi:rom_compare::@3->rom_compare::@1#0] -- register_copy 
    // [2200] phi rom_compare::ptr_ram#4 = rom_compare::ptr_ram#0 [phi:rom_compare::@3->rom_compare::@1#1] -- register_copy 
    // [2200] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#1 [phi:rom_compare::@3->rom_compare::@1#2] -- register_copy 
    // [2200] phi rom_compare::compared_bytes#2 = rom_compare::compared_bytes#1 [phi:rom_compare::@3->rom_compare::@1#3] -- register_copy 
    jmp __b1
  .segment Data
    bank_set_bram1_bank: .byte 0
    rom_bank1_bank_unshifted: .word 0
    rom_bank1_return: .byte 0
    compared_bytes: .word 0
    /// Holds the amount of bytes actually verified between the ROM and the RAM.
    equal_bytes: .word 0
    .label return = equal_bytes
}
.segment Code
  // ultoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void ultoa(__mem() unsigned long value, __zp($2d) char *buffer, __mem() char radix)
ultoa: {
    .label ultoa__4 = $29
    .label ultoa__10 = $2b
    .label ultoa__11 = $3a
    .label buffer = $2d
    .label digit_values = $55
    // if(radix==DECIMAL)
    // [2214] if(ultoa::radix#0==DECIMAL) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // ultoa::@2
    // if(radix==HEXADECIMAL)
    // [2215] if(ultoa::radix#0==HEXADECIMAL) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // ultoa::@3
    // if(radix==OCTAL)
    // [2216] if(ultoa::radix#0==OCTAL) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // ultoa::@4
    // if(radix==BINARY)
    // [2217] if(ultoa::radix#0==BINARY) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // ultoa::@5
    // *buffer++ = 'e'
    // [2218] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2219] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2220] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2221] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // ultoa::@return
    // }
    // [2222] return 
    rts
    // [2223] phi from ultoa to ultoa::@1 [phi:ultoa->ultoa::@1]
  __b2:
    // [2223] phi ultoa::digit_values#8 = RADIX_DECIMAL_VALUES_LONG [phi:ultoa->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2223] phi ultoa::max_digits#7 = $a [phi:ultoa->ultoa::@1#1] -- vbum1=vbuc1 
    lda #$a
    sta max_digits
    jmp __b1
    // [2223] phi from ultoa::@2 to ultoa::@1 [phi:ultoa::@2->ultoa::@1]
  __b3:
    // [2223] phi ultoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_LONG [phi:ultoa::@2->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2223] phi ultoa::max_digits#7 = 8 [phi:ultoa::@2->ultoa::@1#1] -- vbum1=vbuc1 
    lda #8
    sta max_digits
    jmp __b1
    // [2223] phi from ultoa::@3 to ultoa::@1 [phi:ultoa::@3->ultoa::@1]
  __b4:
    // [2223] phi ultoa::digit_values#8 = RADIX_OCTAL_VALUES_LONG [phi:ultoa::@3->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_OCTAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_LONG
    sta.z digit_values+1
    // [2223] phi ultoa::max_digits#7 = $b [phi:ultoa::@3->ultoa::@1#1] -- vbum1=vbuc1 
    lda #$b
    sta max_digits
    jmp __b1
    // [2223] phi from ultoa::@4 to ultoa::@1 [phi:ultoa::@4->ultoa::@1]
  __b5:
    // [2223] phi ultoa::digit_values#8 = RADIX_BINARY_VALUES_LONG [phi:ultoa::@4->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_BINARY_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_LONG
    sta.z digit_values+1
    // [2223] phi ultoa::max_digits#7 = $20 [phi:ultoa::@4->ultoa::@1#1] -- vbum1=vbuc1 
    lda #$20
    sta max_digits
    // ultoa::@1
  __b1:
    // [2224] phi from ultoa::@1 to ultoa::@6 [phi:ultoa::@1->ultoa::@6]
    // [2224] phi ultoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:ultoa::@1->ultoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2224] phi ultoa::started#2 = 0 [phi:ultoa::@1->ultoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [2224] phi ultoa::value#2 = ultoa::value#1 [phi:ultoa::@1->ultoa::@6#2] -- register_copy 
    // [2224] phi ultoa::digit#2 = 0 [phi:ultoa::@1->ultoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // ultoa::@6
  __b6:
    // max_digits-1
    // [2225] ultoa::$4 = ultoa::max_digits#7 - 1 -- vbuz1=vbum2_minus_1 
    ldx max_digits
    dex
    stx.z ultoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2226] if(ultoa::digit#2<ultoa::$4) goto ultoa::@7 -- vbum1_lt_vbuz2_then_la1 
    lda digit
    cmp.z ultoa__4
    bcc __b7
    // ultoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2227] ultoa::$11 = (char)ultoa::value#2 -- vbuz1=_byte_vdum2 
    lda value
    sta.z ultoa__11
    // [2228] *ultoa::buffer#11 = DIGITS[ultoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2229] ultoa::buffer#3 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2230] *ultoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // ultoa::@7
  __b7:
    // unsigned long digit_value = digit_values[digit]
    // [2231] ultoa::$10 = ultoa::digit#2 << 2 -- vbuz1=vbum2_rol_2 
    lda digit
    asl
    asl
    sta.z ultoa__10
    // [2232] ultoa::digit_value#0 = ultoa::digit_values#8[ultoa::$10] -- vdum1=pduz2_derefidx_vbuz3 
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
    // [2233] if(0!=ultoa::started#2) goto ultoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // ultoa::@12
    // [2234] if(ultoa::value#2>=ultoa::digit_value#0) goto ultoa::@10 -- vdum1_ge_vdum2_then_la1 
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
    // [2235] phi from ultoa::@12 to ultoa::@9 [phi:ultoa::@12->ultoa::@9]
    // [2235] phi ultoa::buffer#14 = ultoa::buffer#11 [phi:ultoa::@12->ultoa::@9#0] -- register_copy 
    // [2235] phi ultoa::started#4 = ultoa::started#2 [phi:ultoa::@12->ultoa::@9#1] -- register_copy 
    // [2235] phi ultoa::value#6 = ultoa::value#2 [phi:ultoa::@12->ultoa::@9#2] -- register_copy 
    // ultoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2236] ultoa::digit#1 = ++ ultoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [2224] phi from ultoa::@9 to ultoa::@6 [phi:ultoa::@9->ultoa::@6]
    // [2224] phi ultoa::buffer#11 = ultoa::buffer#14 [phi:ultoa::@9->ultoa::@6#0] -- register_copy 
    // [2224] phi ultoa::started#2 = ultoa::started#4 [phi:ultoa::@9->ultoa::@6#1] -- register_copy 
    // [2224] phi ultoa::value#2 = ultoa::value#6 [phi:ultoa::@9->ultoa::@6#2] -- register_copy 
    // [2224] phi ultoa::digit#2 = ultoa::digit#1 [phi:ultoa::@9->ultoa::@6#3] -- register_copy 
    jmp __b6
    // ultoa::@10
  __b10:
    // ultoa_append(buffer++, value, digit_value)
    // [2237] ultoa_append::buffer#0 = ultoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z ultoa_append.buffer
    lda.z buffer+1
    sta.z ultoa_append.buffer+1
    // [2238] ultoa_append::value#0 = ultoa::value#2
    // [2239] ultoa_append::sub#0 = ultoa::digit_value#0
    // [2240] call ultoa_append
    // [2527] phi from ultoa::@10 to ultoa_append [phi:ultoa::@10->ultoa_append]
    jsr ultoa_append
    // ultoa_append(buffer++, value, digit_value)
    // [2241] ultoa_append::return#0 = ultoa_append::value#2
    // ultoa::@11
    // value = ultoa_append(buffer++, value, digit_value)
    // [2242] ultoa::value#0 = ultoa_append::return#0
    // value = ultoa_append(buffer++, value, digit_value);
    // [2243] ultoa::buffer#4 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2235] phi from ultoa::@11 to ultoa::@9 [phi:ultoa::@11->ultoa::@9]
    // [2235] phi ultoa::buffer#14 = ultoa::buffer#4 [phi:ultoa::@11->ultoa::@9#0] -- register_copy 
    // [2235] phi ultoa::started#4 = 1 [phi:ultoa::@11->ultoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [2235] phi ultoa::value#6 = ultoa::value#0 [phi:ultoa::@11->ultoa::@9#2] -- register_copy 
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
// void rom_sector_erase(__zp($a9) unsigned long address)
rom_sector_erase: {
    .label rom_ptr1_rom_sector_erase__0 = $2d
    .label rom_ptr1_rom_sector_erase__2 = $2d
    .label rom_ptr1_return = $2d
    .label address = $a9
    // rom_sector_erase::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2245] rom_sector_erase::rom_ptr1_$2 = (unsigned int)rom_sector_erase::address#0 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_sector_erase__2
    lda.z address+1
    sta.z rom_ptr1_rom_sector_erase__2+1
    // [2246] rom_sector_erase::rom_ptr1_$0 = rom_sector_erase::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_sector_erase__0
    and #<$3fff
    sta.z rom_ptr1_rom_sector_erase__0
    lda.z rom_ptr1_rom_sector_erase__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_sector_erase__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2247] rom_sector_erase::rom_ptr1_return#0 = rom_sector_erase::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_sector_erase::@1
    // unsigned long rom_chip_address = address & ROM_CHIP_MASK
    // [2248] rom_sector_erase::rom_chip_address#0 = rom_sector_erase::address#0 & $380000 -- vdum1=vduz2_band_vduc1 
    lda.z address
    and #<$380000
    sta rom_chip_address
    lda.z address+1
    and #>$380000
    sta rom_chip_address+1
    lda.z address+2
    and #<$380000>>$10
    sta rom_chip_address+2
    lda.z address+3
    and #>$380000>>$10
    sta rom_chip_address+3
    // rom_unlock(rom_chip_address + 0x05555, 0x80)
    // [2249] rom_unlock::address#0 = rom_sector_erase::rom_chip_address#0 + $5555 -- vduz1=vdum2_plus_vwuc1 
    clc
    lda rom_chip_address
    adc #<$5555
    sta.z rom_unlock.address
    lda rom_chip_address+1
    adc #>$5555
    sta.z rom_unlock.address+1
    lda rom_chip_address+2
    adc #0
    sta.z rom_unlock.address+2
    lda rom_chip_address+3
    adc #0
    sta.z rom_unlock.address+3
    // [2250] call rom_unlock
    // [1921] phi from rom_sector_erase::@1 to rom_unlock [phi:rom_sector_erase::@1->rom_unlock]
    // [1921] phi rom_unlock::unlock_code#5 = $80 [phi:rom_sector_erase::@1->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$80
    sta.z rom_unlock.unlock_code
    // [1921] phi rom_unlock::address#5 = rom_unlock::address#0 [phi:rom_sector_erase::@1->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@2
    // rom_unlock(address, 0x30)
    // [2251] rom_unlock::address#1 = rom_sector_erase::address#0 -- vduz1=vduz2 
    lda.z address
    sta.z rom_unlock.address
    lda.z address+1
    sta.z rom_unlock.address+1
    lda.z address+2
    sta.z rom_unlock.address+2
    lda.z address+3
    sta.z rom_unlock.address+3
    // [2252] call rom_unlock
    // [1921] phi from rom_sector_erase::@2 to rom_unlock [phi:rom_sector_erase::@2->rom_unlock]
    // [1921] phi rom_unlock::unlock_code#5 = $30 [phi:rom_sector_erase::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$30
    sta.z rom_unlock.unlock_code
    // [1921] phi rom_unlock::address#5 = rom_unlock::address#1 [phi:rom_sector_erase::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@3
    // rom_wait(ptr_rom)
    // [2253] rom_wait::ptr_rom#0 = (char *)rom_sector_erase::rom_ptr1_return#0
    // [2254] call rom_wait
    // [2534] phi from rom_sector_erase::@3 to rom_wait [phi:rom_sector_erase::@3->rom_wait]
    // [2534] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#0 [phi:rom_sector_erase::@3->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_sector_erase::@return
    // }
    // [2255] return 
    rts
  .segment Data
    rom_chip_address: .dword 0
}
.segment Code
  // rom_write
/* inline */
// unsigned long rom_write(__zp($77) char flash_ram_bank, __zp($55) char *flash_ram_address, __zp($5a) unsigned long flash_rom_address, unsigned int flash_rom_size)
rom_write: {
    .label flash_rom_address = $5a
    .label flash_ram_address = $55
    .label flash_ram_bank = $77
    // unsigned long rom_chip_address = flash_rom_address & ROM_CHIP_MASK
    // [2256] rom_write::rom_chip_address#0 = rom_write::flash_rom_address#1 & $380000 -- vdum1=vduz2_band_vduc1 
    /// Holds the amount of bytes actually flashed in the ROM.
    lda.z flash_rom_address
    and #<$380000
    sta rom_chip_address
    lda.z flash_rom_address+1
    and #>$380000
    sta rom_chip_address+1
    lda.z flash_rom_address+2
    and #<$380000>>$10
    sta rom_chip_address+2
    lda.z flash_rom_address+3
    and #>$380000>>$10
    sta rom_chip_address+3
    // rom_write::bank_set_bram1
    // BRAM = bank
    // [2257] BRAM = rom_write::flash_ram_bank#0 -- vbuz1=vbuz2 
    lda.z flash_ram_bank
    sta.z BRAM
    // [2258] phi from rom_write::bank_set_bram1 to rom_write::@1 [phi:rom_write::bank_set_bram1->rom_write::@1]
    // [2258] phi rom_write::flash_ram_address#2 = rom_write::flash_ram_address#1 [phi:rom_write::bank_set_bram1->rom_write::@1#0] -- register_copy 
    // [2258] phi rom_write::flash_rom_address#3 = rom_write::flash_rom_address#1 [phi:rom_write::bank_set_bram1->rom_write::@1#1] -- register_copy 
    // [2258] phi rom_write::flashed_bytes#2 = 0 [phi:rom_write::bank_set_bram1->rom_write::@1#2] -- vdum1=vduc1 
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
    // [2259] if(rom_write::flashed_bytes#2<PROGRESS_CELL) goto rom_write::@2 -- vdum1_lt_vduc1_then_la1 
    lda flashed_bytes+3
    cmp #>PROGRESS_CELL>>$10
    bcc __b2
    bne !+
    lda flashed_bytes+2
    cmp #<PROGRESS_CELL>>$10
    bcc __b2
    bne !+
    lda flashed_bytes+1
    cmp #>PROGRESS_CELL
    bcc __b2
    bne !+
    lda flashed_bytes
    cmp #<PROGRESS_CELL
    bcc __b2
  !:
    // rom_write::@return
    // }
    // [2260] return 
    rts
    // rom_write::@2
  __b2:
    // rom_unlock(rom_chip_address + 0x05555, 0xA0)
    // [2261] rom_unlock::address#4 = rom_write::rom_chip_address#0 + $5555 -- vduz1=vdum2_plus_vwuc1 
    clc
    lda rom_chip_address
    adc #<$5555
    sta.z rom_unlock.address
    lda rom_chip_address+1
    adc #>$5555
    sta.z rom_unlock.address+1
    lda rom_chip_address+2
    adc #0
    sta.z rom_unlock.address+2
    lda rom_chip_address+3
    adc #0
    sta.z rom_unlock.address+3
    // [2262] call rom_unlock
    // [1921] phi from rom_write::@2 to rom_unlock [phi:rom_write::@2->rom_unlock]
    // [1921] phi rom_unlock::unlock_code#5 = $a0 [phi:rom_write::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$a0
    sta.z rom_unlock.unlock_code
    // [1921] phi rom_unlock::address#5 = rom_unlock::address#4 [phi:rom_write::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_write::@3
    // rom_byte_program(flash_rom_address, *flash_ram_address)
    // [2263] rom_byte_program::address#0 = rom_write::flash_rom_address#3 -- vduz1=vduz2 
    lda.z flash_rom_address
    sta.z rom_byte_program.address
    lda.z flash_rom_address+1
    sta.z rom_byte_program.address+1
    lda.z flash_rom_address+2
    sta.z rom_byte_program.address+2
    lda.z flash_rom_address+3
    sta.z rom_byte_program.address+3
    // [2264] rom_byte_program::value#0 = *rom_write::flash_ram_address#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (flash_ram_address),y
    sta.z rom_byte_program.value
    // [2265] call rom_byte_program
    // [2541] phi from rom_write::@3 to rom_byte_program [phi:rom_write::@3->rom_byte_program]
    jsr rom_byte_program
    // rom_write::@4
    // flash_rom_address++;
    // [2266] rom_write::flash_rom_address#0 = ++ rom_write::flash_rom_address#3 -- vduz1=_inc_vduz1 
    inc.z flash_rom_address
    bne !+
    inc.z flash_rom_address+1
    bne !+
    inc.z flash_rom_address+2
    bne !+
    inc.z flash_rom_address+3
  !:
    // flash_ram_address++;
    // [2267] rom_write::flash_ram_address#0 = ++ rom_write::flash_ram_address#2 -- pbuz1=_inc_pbuz1 
    inc.z flash_ram_address
    bne !+
    inc.z flash_ram_address+1
  !:
    // flashed_bytes++;
    // [2268] rom_write::flashed_bytes#1 = ++ rom_write::flashed_bytes#2 -- vdum1=_inc_vdum1 
    inc flashed_bytes
    bne !+
    inc flashed_bytes+1
    bne !+
    inc flashed_bytes+2
    bne !+
    inc flashed_bytes+3
  !:
    // [2258] phi from rom_write::@4 to rom_write::@1 [phi:rom_write::@4->rom_write::@1]
    // [2258] phi rom_write::flash_ram_address#2 = rom_write::flash_ram_address#0 [phi:rom_write::@4->rom_write::@1#0] -- register_copy 
    // [2258] phi rom_write::flash_rom_address#3 = rom_write::flash_rom_address#0 [phi:rom_write::@4->rom_write::@1#1] -- register_copy 
    // [2258] phi rom_write::flashed_bytes#2 = rom_write::flashed_bytes#1 [phi:rom_write::@4->rom_write::@1#2] -- register_copy 
    jmp __b1
  .segment Data
    rom_chip_address: .dword 0
    flashed_bytes: .dword 0
}
.segment Code
  // insertup
// Insert a new line, and scroll the upper part of the screen up.
// void insertup(char rows)
insertup: {
    .label insertup__0 = $34
    .label insertup__4 = $2a
    .label insertup__6 = $2c
    .label insertup__7 = $2a
    // __conio.width+1
    // [2269] insertup::$0 = *((char *)&__conio+6) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+6
    inc
    sta.z insertup__0
    // unsigned char width = (__conio.width+1) * 2
    // [2270] insertup::width#0 = insertup::$0 << 1 -- vbum1=vbuz2_rol_1 
    // {asm{.byte $db}}
    asl
    sta width
    // [2271] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [2271] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbum1=vbuc1 
    lda #0
    sta y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [2272] if(insertup::y#2<*((char *)&__conio+1)) goto insertup::@2 -- vbum1_lt__deref_pbuc1_then_la1 
    lda y
    cmp __conio+1
    bcc __b2
    // [2273] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [2274] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [2275] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [2276] insertup::$4 = insertup::y#2 + 1 -- vbuz1=vbum2_plus_1 
    lda y
    inc
    sta.z insertup__4
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [2277] insertup::$6 = insertup::y#2 << 1 -- vbuz1=vbum2_rol_1 
    lda y
    asl
    sta.z insertup__6
    // [2278] insertup::$7 = insertup::$4 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z insertup__7
    // [2279] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+5) -- vbum1=_deref_pbuc1 
    lda __conio+5
    sta memcpy8_vram_vram.dbank_vram
    // [2280] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwum1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__6
    lda __conio+$15,y
    sta memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta memcpy8_vram_vram.doffset_vram+1
    // [2281] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+5) -- vbum1=_deref_pbuc1 
    lda __conio+5
    sta memcpy8_vram_vram.sbank_vram
    // [2282] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwum1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__7
    lda __conio+$15,y
    sta memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,y
    sta memcpy8_vram_vram.soffset_vram+1
    // [2283] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbum1=vbum2 
    lda width
    sta memcpy8_vram_vram.num8_1
    // [2284] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [2285] insertup::y#1 = ++ insertup::y#2 -- vbum1=_inc_vbum1 
    inc y
    // [2271] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [2271] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
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
    // [2286] clearline::$3 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z clearline__3
    // [2287] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwum1=pwuc1_derefidx_vbuz2 
    tay
    lda __conio+$15,y
    sta addr
    lda __conio+$15+1,y
    sta addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2288] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [2289] clearline::$0 = byte0  clearline::addr#0 -- vbuz1=_byte0_vwum2 
    lda addr
    sta.z clearline__0
    // *VERA_ADDRX_L = BYTE0(addr)
    // [2290] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [2291] clearline::$1 = byte1  clearline::addr#0 -- vbuz1=_byte1_vwum2 
    lda addr+1
    sta.z clearline__1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [2292] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [2293] clearline::$2 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clearline__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [2294] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [2295] clearline::c#0 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z c
    // [2296] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [2296] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [2297] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [2298] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [2299] clearline::c#1 = -- clearline::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [2300] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b1
    // clearline::@return
    // }
    // [2301] return 
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
// __mem() char display_frame_maskxy(__zp($b4) char x, __zp($b7) char y)
display_frame_maskxy: {
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__0 = $3a
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__1 = $2b
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__2 = $29
    .label x = $b4
    .label y = $b7
    .label x_1 = $bb
    .label y_1 = $75
    .label x_2 = $7d
    .label y_2 = $c5
    .label x_3 = $7e
    .label y_3 = $b3
    .label x_4 = $7c
    .label y_4 = $b9
    .label x_5 = $c8
    .label y_5 = $b8
    .label x_6 = $cf
    .label y_6 = $6c
    .label x_7 = $c7
    .label y_7 = $6b
    // display_frame_maskxy::cpeekcxy1
    // gotoxy(x,y)
    // [2303] gotoxy::x#5 = display_frame_maskxy::cpeekcxy1_x#0 -- vbum1=vbum2 
    lda cpeekcxy1_x
    sta gotoxy.x
    // [2304] gotoxy::y#5 = display_frame_maskxy::cpeekcxy1_y#0 -- vbum1=vbum2 
    lda cpeekcxy1_y
    sta gotoxy.y
    // [2305] call gotoxy
    // [602] phi from display_frame_maskxy::cpeekcxy1 to gotoxy [phi:display_frame_maskxy::cpeekcxy1->gotoxy]
    // [602] phi gotoxy::y#30 = gotoxy::y#5 [phi:display_frame_maskxy::cpeekcxy1->gotoxy#0] -- register_copy 
    // [602] phi gotoxy::x#30 = gotoxy::x#5 [phi:display_frame_maskxy::cpeekcxy1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_frame_maskxy::cpeekcxy1_cpeekc1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2306] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(__conio.offset)
    // [2307] display_frame_maskxy::cpeekcxy1_cpeekc1_$0 = byte0  *((unsigned int *)&__conio+$13) -- vbuz1=_byte0__deref_pwuc1 
    lda __conio+$13
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__0
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [2308] *VERA_ADDRX_L = display_frame_maskxy::cpeekcxy1_cpeekc1_$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [2309] display_frame_maskxy::cpeekcxy1_cpeekc1_$1 = byte1  *((unsigned int *)&__conio+$13) -- vbuz1=_byte1__deref_pwuc1 
    lda __conio+$13+1
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__1
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [2310] *VERA_ADDRX_M = display_frame_maskxy::cpeekcxy1_cpeekc1_$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_0
    // [2311] display_frame_maskxy::cpeekcxy1_cpeekc1_$2 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_0
    // [2312] *VERA_ADDRX_H = display_frame_maskxy::cpeekcxy1_cpeekc1_$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // return *VERA_DATA0;
    // [2313] display_frame_maskxy::c#0 = *VERA_DATA0 -- vbum1=_deref_pbuc1 
    lda VERA_DATA0
    sta c
    // display_frame_maskxy::@12
    // case 0x70: // DR corner.
    //             return 0b0110;
    // [2314] if(display_frame_maskxy::c#0==$70) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$70
    cmp c
    beq __b2
    // display_frame_maskxy::@1
    // case 0x6E: // DL corner.
    //             return 0b0011;
    // [2315] if(display_frame_maskxy::c#0==$6e) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$6e
    cmp c
    beq __b1
    // display_frame_maskxy::@2
    // case 0x6D: // UR corner.
    //             return 0b1100;
    // [2316] if(display_frame_maskxy::c#0==$6d) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$6d
    cmp c
    beq __b3
    // display_frame_maskxy::@3
    // case 0x7D: // UL corner.
    //             return 0b1001;
    // [2317] if(display_frame_maskxy::c#0==$7d) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$7d
    cmp c
    beq __b4
    // display_frame_maskxy::@4
    // case 0x40: // HL line.
    //             return 0b0101;
    // [2318] if(display_frame_maskxy::c#0==$40) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$40
    cmp c
    beq __b5
    // display_frame_maskxy::@5
    // case 0x5D: // VL line.
    //             return 0b1010;
    // [2319] if(display_frame_maskxy::c#0==$5d) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$5d
    cmp c
    beq __b6
    // display_frame_maskxy::@6
    // case 0x6B: // VR junction.
    //             return 0b1110;
    // [2320] if(display_frame_maskxy::c#0==$6b) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$6b
    cmp c
    beq __b7
    // display_frame_maskxy::@7
    // case 0x73: // VL junction.
    //             return 0b1011;
    // [2321] if(display_frame_maskxy::c#0==$73) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$73
    cmp c
    beq __b8
    // display_frame_maskxy::@8
    // case 0x72: // HD junction.
    //             return 0b0111;
    // [2322] if(display_frame_maskxy::c#0==$72) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$72
    cmp c
    beq __b9
    // display_frame_maskxy::@9
    // case 0x71: // HU junction.
    //             return 0b1101;
    // [2323] if(display_frame_maskxy::c#0==$71) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$71
    cmp c
    beq __b10
    // display_frame_maskxy::@10
    // case 0x5B: // HV junction.
    //             return 0b1111;
    // [2324] if(display_frame_maskxy::c#0==$5b) goto display_frame_maskxy::@11 -- vbum1_eq_vbuc1_then_la1 
    lda #$5b
    cmp c
    beq __b11
    // [2326] phi from display_frame_maskxy::@10 to display_frame_maskxy::@return [phi:display_frame_maskxy::@10->display_frame_maskxy::@return]
    // [2326] phi display_frame_maskxy::return#12 = 0 [phi:display_frame_maskxy::@10->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    rts
    // [2325] phi from display_frame_maskxy::@10 to display_frame_maskxy::@11 [phi:display_frame_maskxy::@10->display_frame_maskxy::@11]
    // display_frame_maskxy::@11
  __b11:
    // [2326] phi from display_frame_maskxy::@11 to display_frame_maskxy::@return [phi:display_frame_maskxy::@11->display_frame_maskxy::@return]
    // [2326] phi display_frame_maskxy::return#12 = $f [phi:display_frame_maskxy::@11->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$f
    sta return
    rts
    // [2326] phi from display_frame_maskxy::@1 to display_frame_maskxy::@return [phi:display_frame_maskxy::@1->display_frame_maskxy::@return]
  __b1:
    // [2326] phi display_frame_maskxy::return#12 = 3 [phi:display_frame_maskxy::@1->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #3
    sta return
    rts
    // [2326] phi from display_frame_maskxy::@12 to display_frame_maskxy::@return [phi:display_frame_maskxy::@12->display_frame_maskxy::@return]
  __b2:
    // [2326] phi display_frame_maskxy::return#12 = 6 [phi:display_frame_maskxy::@12->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #6
    sta return
    rts
    // [2326] phi from display_frame_maskxy::@2 to display_frame_maskxy::@return [phi:display_frame_maskxy::@2->display_frame_maskxy::@return]
  __b3:
    // [2326] phi display_frame_maskxy::return#12 = $c [phi:display_frame_maskxy::@2->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$c
    sta return
    rts
    // [2326] phi from display_frame_maskxy::@3 to display_frame_maskxy::@return [phi:display_frame_maskxy::@3->display_frame_maskxy::@return]
  __b4:
    // [2326] phi display_frame_maskxy::return#12 = 9 [phi:display_frame_maskxy::@3->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #9
    sta return
    rts
    // [2326] phi from display_frame_maskxy::@4 to display_frame_maskxy::@return [phi:display_frame_maskxy::@4->display_frame_maskxy::@return]
  __b5:
    // [2326] phi display_frame_maskxy::return#12 = 5 [phi:display_frame_maskxy::@4->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #5
    sta return
    rts
    // [2326] phi from display_frame_maskxy::@5 to display_frame_maskxy::@return [phi:display_frame_maskxy::@5->display_frame_maskxy::@return]
  __b6:
    // [2326] phi display_frame_maskxy::return#12 = $a [phi:display_frame_maskxy::@5->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$a
    sta return
    rts
    // [2326] phi from display_frame_maskxy::@6 to display_frame_maskxy::@return [phi:display_frame_maskxy::@6->display_frame_maskxy::@return]
  __b7:
    // [2326] phi display_frame_maskxy::return#12 = $e [phi:display_frame_maskxy::@6->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$e
    sta return
    rts
    // [2326] phi from display_frame_maskxy::@7 to display_frame_maskxy::@return [phi:display_frame_maskxy::@7->display_frame_maskxy::@return]
  __b8:
    // [2326] phi display_frame_maskxy::return#12 = $b [phi:display_frame_maskxy::@7->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$b
    sta return
    rts
    // [2326] phi from display_frame_maskxy::@8 to display_frame_maskxy::@return [phi:display_frame_maskxy::@8->display_frame_maskxy::@return]
  __b9:
    // [2326] phi display_frame_maskxy::return#12 = 7 [phi:display_frame_maskxy::@8->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #7
    sta return
    rts
    // [2326] phi from display_frame_maskxy::@9 to display_frame_maskxy::@return [phi:display_frame_maskxy::@9->display_frame_maskxy::@return]
  __b10:
    // [2326] phi display_frame_maskxy::return#12 = $d [phi:display_frame_maskxy::@9->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$d
    sta return
    // display_frame_maskxy::@return
    // }
    // [2327] return 
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
}
.segment Code
  // display_frame_char
/**
 * @brief 
 * 
 * @param mask 
 * @return unsigned char 
 */
// __mem() char display_frame_char(__zp($b7) char mask)
display_frame_char: {
    .label mask = $b7
    // case 0b0110:
    //             return 0x70;
    // [2329] if(display_frame_char::mask#10==6) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #6
    cmp.z mask
    beq __b1
    // display_frame_char::@1
    // case 0b0011:
    //             return 0x6E;
    // [2330] if(display_frame_char::mask#10==3) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // DR corner.
    lda #3
    cmp.z mask
    beq __b2
    // display_frame_char::@2
    // case 0b1100:
    //             return 0x6D;
    // [2331] if(display_frame_char::mask#10==$c) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // DL corner.
    lda #$c
    cmp.z mask
    beq __b3
    // display_frame_char::@3
    // case 0b1001:
    //             return 0x7D;
    // [2332] if(display_frame_char::mask#10==9) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // UR corner.
    lda #9
    cmp.z mask
    beq __b4
    // display_frame_char::@4
    // case 0b0101:
    //             return 0x40;
    // [2333] if(display_frame_char::mask#10==5) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // UL corner.
    lda #5
    cmp.z mask
    beq __b5
    // display_frame_char::@5
    // case 0b1010:
    //             return 0x5D;
    // [2334] if(display_frame_char::mask#10==$a) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // HL line.
    lda #$a
    cmp.z mask
    beq __b6
    // display_frame_char::@6
    // case 0b1110:
    //             return 0x6B;
    // [2335] if(display_frame_char::mask#10==$e) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VL line.
    lda #$e
    cmp.z mask
    beq __b7
    // display_frame_char::@7
    // case 0b1011:
    //             return 0x73;
    // [2336] if(display_frame_char::mask#10==$b) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VR junction.
    lda #$b
    cmp.z mask
    beq __b8
    // display_frame_char::@8
    // case 0b0111:
    //             return 0x72;
    // [2337] if(display_frame_char::mask#10==7) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VL junction.
    lda #7
    cmp.z mask
    beq __b9
    // display_frame_char::@9
    // case 0b1101:
    //             return 0x71;
    // [2338] if(display_frame_char::mask#10==$d) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // HD junction.
    lda #$d
    cmp.z mask
    beq __b10
    // display_frame_char::@10
    // case 0b1111:
    //             return 0x5B;
    // [2339] if(display_frame_char::mask#10==$f) goto display_frame_char::@11 -- vbuz1_eq_vbuc1_then_la1 
    // HU junction.
    lda #$f
    cmp.z mask
    beq __b11
    // [2341] phi from display_frame_char::@10 to display_frame_char::@return [phi:display_frame_char::@10->display_frame_char::@return]
    // [2341] phi display_frame_char::return#12 = $20 [phi:display_frame_char::@10->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$20
    sta return
    rts
    // [2340] phi from display_frame_char::@10 to display_frame_char::@11 [phi:display_frame_char::@10->display_frame_char::@11]
    // display_frame_char::@11
  __b11:
    // [2341] phi from display_frame_char::@11 to display_frame_char::@return [phi:display_frame_char::@11->display_frame_char::@return]
    // [2341] phi display_frame_char::return#12 = $5b [phi:display_frame_char::@11->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$5b
    sta return
    rts
    // [2341] phi from display_frame_char to display_frame_char::@return [phi:display_frame_char->display_frame_char::@return]
  __b1:
    // [2341] phi display_frame_char::return#12 = $70 [phi:display_frame_char->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$70
    sta return
    rts
    // [2341] phi from display_frame_char::@1 to display_frame_char::@return [phi:display_frame_char::@1->display_frame_char::@return]
  __b2:
    // [2341] phi display_frame_char::return#12 = $6e [phi:display_frame_char::@1->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$6e
    sta return
    rts
    // [2341] phi from display_frame_char::@2 to display_frame_char::@return [phi:display_frame_char::@2->display_frame_char::@return]
  __b3:
    // [2341] phi display_frame_char::return#12 = $6d [phi:display_frame_char::@2->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$6d
    sta return
    rts
    // [2341] phi from display_frame_char::@3 to display_frame_char::@return [phi:display_frame_char::@3->display_frame_char::@return]
  __b4:
    // [2341] phi display_frame_char::return#12 = $7d [phi:display_frame_char::@3->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$7d
    sta return
    rts
    // [2341] phi from display_frame_char::@4 to display_frame_char::@return [phi:display_frame_char::@4->display_frame_char::@return]
  __b5:
    // [2341] phi display_frame_char::return#12 = $40 [phi:display_frame_char::@4->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$40
    sta return
    rts
    // [2341] phi from display_frame_char::@5 to display_frame_char::@return [phi:display_frame_char::@5->display_frame_char::@return]
  __b6:
    // [2341] phi display_frame_char::return#12 = $5d [phi:display_frame_char::@5->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$5d
    sta return
    rts
    // [2341] phi from display_frame_char::@6 to display_frame_char::@return [phi:display_frame_char::@6->display_frame_char::@return]
  __b7:
    // [2341] phi display_frame_char::return#12 = $6b [phi:display_frame_char::@6->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$6b
    sta return
    rts
    // [2341] phi from display_frame_char::@7 to display_frame_char::@return [phi:display_frame_char::@7->display_frame_char::@return]
  __b8:
    // [2341] phi display_frame_char::return#12 = $73 [phi:display_frame_char::@7->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$73
    sta return
    rts
    // [2341] phi from display_frame_char::@8 to display_frame_char::@return [phi:display_frame_char::@8->display_frame_char::@return]
  __b9:
    // [2341] phi display_frame_char::return#12 = $72 [phi:display_frame_char::@8->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$72
    sta return
    rts
    // [2341] phi from display_frame_char::@9 to display_frame_char::@return [phi:display_frame_char::@9->display_frame_char::@return]
  __b10:
    // [2341] phi display_frame_char::return#12 = $71 [phi:display_frame_char::@9->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$71
    sta return
    // display_frame_char::@return
    // }
    // [2342] return 
    rts
  .segment Data
    .label return = cputcxy.c
}
.segment Code
  // display_print_chip_led
// void display_print_chip_led(__zp($6c) char x, char y, __zp($6b) char w, __zp($75) char tc, char bc)
display_print_chip_led: {
    .label x = $6c
    .label w = $6b
    .label tc = $75
    // textcolor(tc)
    // [2344] textcolor::color#11 = display_print_chip_led::tc#3 -- vbum1=vbuz2 
    lda.z tc
    sta textcolor.color
    // [2345] call textcolor
    // [584] phi from display_print_chip_led to textcolor [phi:display_print_chip_led->textcolor]
    // [584] phi textcolor::color#18 = textcolor::color#11 [phi:display_print_chip_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [2346] phi from display_print_chip_led to display_print_chip_led::@3 [phi:display_print_chip_led->display_print_chip_led::@3]
    // display_print_chip_led::@3
    // bgcolor(bc)
    // [2347] call bgcolor
    // [589] phi from display_print_chip_led::@3 to bgcolor [phi:display_print_chip_led::@3->bgcolor]
    // [589] phi bgcolor::color#14 = BLUE [phi:display_print_chip_led::@3->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [2348] phi from display_print_chip_led::@3 display_print_chip_led::@5 to display_print_chip_led::@1 [phi:display_print_chip_led::@3/display_print_chip_led::@5->display_print_chip_led::@1]
    // [2348] phi display_print_chip_led::w#4 = display_print_chip_led::w#7 [phi:display_print_chip_led::@3/display_print_chip_led::@5->display_print_chip_led::@1#0] -- register_copy 
    // [2348] phi display_print_chip_led::x#4 = display_print_chip_led::x#7 [phi:display_print_chip_led::@3/display_print_chip_led::@5->display_print_chip_led::@1#1] -- register_copy 
    // display_print_chip_led::@1
  __b1:
    // cputcxy(x, y, 0x6F)
    // [2349] cputcxy::x#9 = display_print_chip_led::x#4 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [2350] call cputcxy
    // [1787] phi from display_print_chip_led::@1 to cputcxy [phi:display_print_chip_led::@1->cputcxy]
    // [1787] phi cputcxy::c#15 = $6f [phi:display_print_chip_led::@1->cputcxy#0] -- vbum1=vbuc1 
    lda #$6f
    sta cputcxy.c
    // [1787] phi cputcxy::y#15 = 3 [phi:display_print_chip_led::@1->cputcxy#1] -- vbum1=vbuc1 
    lda #3
    sta cputcxy.y
    // [1787] phi cputcxy::x#15 = cputcxy::x#9 [phi:display_print_chip_led::@1->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_print_chip_led::@4
    // cputcxy(x, y+1, 0x77)
    // [2351] cputcxy::x#10 = display_print_chip_led::x#4 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [2352] call cputcxy
    // [1787] phi from display_print_chip_led::@4 to cputcxy [phi:display_print_chip_led::@4->cputcxy]
    // [1787] phi cputcxy::c#15 = $77 [phi:display_print_chip_led::@4->cputcxy#0] -- vbum1=vbuc1 
    lda #$77
    sta cputcxy.c
    // [1787] phi cputcxy::y#15 = 3+1 [phi:display_print_chip_led::@4->cputcxy#1] -- vbum1=vbuc1 
    lda #3+1
    sta cputcxy.y
    // [1787] phi cputcxy::x#15 = cputcxy::x#10 [phi:display_print_chip_led::@4->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_print_chip_led::@5
    // x++;
    // [2353] display_print_chip_led::x#0 = ++ display_print_chip_led::x#4 -- vbuz1=_inc_vbuz1 
    inc.z x
    // while(--w)
    // [2354] display_print_chip_led::w#0 = -- display_print_chip_led::w#4 -- vbuz1=_dec_vbuz1 
    dec.z w
    // [2355] if(0!=display_print_chip_led::w#0) goto display_print_chip_led::@1 -- 0_neq_vbuz1_then_la1 
    lda.z w
    bne __b1
    // [2356] phi from display_print_chip_led::@5 to display_print_chip_led::@2 [phi:display_print_chip_led::@5->display_print_chip_led::@2]
    // display_print_chip_led::@2
    // textcolor(WHITE)
    // [2357] call textcolor
    // [584] phi from display_print_chip_led::@2 to textcolor [phi:display_print_chip_led::@2->textcolor]
    // [584] phi textcolor::color#18 = WHITE [phi:display_print_chip_led::@2->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [2358] phi from display_print_chip_led::@2 to display_print_chip_led::@6 [phi:display_print_chip_led::@2->display_print_chip_led::@6]
    // display_print_chip_led::@6
    // bgcolor(BLUE)
    // [2359] call bgcolor
    // [589] phi from display_print_chip_led::@6 to bgcolor [phi:display_print_chip_led::@6->bgcolor]
    // [589] phi bgcolor::color#14 = BLUE [phi:display_print_chip_led::@6->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_print_chip_led::@return
    // }
    // [2360] return 
    rts
}
  // display_print_chip_line
// void display_print_chip_line(__zp($b9) char x, __zp($c5) char y, __zp($b3) char w, __zp($b8) char c)
display_print_chip_line: {
    .label x = $b9
    .label w = $b3
    .label c = $b8
    .label y = $c5
    // gotoxy(x, y)
    // [2362] gotoxy::x#7 = display_print_chip_line::x#16 -- vbum1=vbuz2 
    lda.z x
    sta gotoxy.x
    // [2363] gotoxy::y#7 = display_print_chip_line::y#16 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [2364] call gotoxy
    // [602] phi from display_print_chip_line to gotoxy [phi:display_print_chip_line->gotoxy]
    // [602] phi gotoxy::y#30 = gotoxy::y#7 [phi:display_print_chip_line->gotoxy#0] -- register_copy 
    // [602] phi gotoxy::x#30 = gotoxy::x#7 [phi:display_print_chip_line->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [2365] phi from display_print_chip_line to display_print_chip_line::@4 [phi:display_print_chip_line->display_print_chip_line::@4]
    // display_print_chip_line::@4
    // textcolor(GREY)
    // [2366] call textcolor
    // [584] phi from display_print_chip_line::@4 to textcolor [phi:display_print_chip_line::@4->textcolor]
    // [584] phi textcolor::color#18 = GREY [phi:display_print_chip_line::@4->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [2367] phi from display_print_chip_line::@4 to display_print_chip_line::@5 [phi:display_print_chip_line::@4->display_print_chip_line::@5]
    // display_print_chip_line::@5
    // bgcolor(BLUE)
    // [2368] call bgcolor
    // [589] phi from display_print_chip_line::@5 to bgcolor [phi:display_print_chip_line::@5->bgcolor]
    // [589] phi bgcolor::color#14 = BLUE [phi:display_print_chip_line::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_print_chip_line::@6
    // cputc(VERA_CHR_UR)
    // [2369] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [2370] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [2372] call textcolor
    // [584] phi from display_print_chip_line::@6 to textcolor [phi:display_print_chip_line::@6->textcolor]
    // [584] phi textcolor::color#18 = WHITE [phi:display_print_chip_line::@6->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [2373] phi from display_print_chip_line::@6 to display_print_chip_line::@7 [phi:display_print_chip_line::@6->display_print_chip_line::@7]
    // display_print_chip_line::@7
    // bgcolor(BLACK)
    // [2374] call bgcolor
    // [589] phi from display_print_chip_line::@7 to bgcolor [phi:display_print_chip_line::@7->bgcolor]
    // [589] phi bgcolor::color#14 = BLACK [phi:display_print_chip_line::@7->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // [2375] phi from display_print_chip_line::@7 to display_print_chip_line::@1 [phi:display_print_chip_line::@7->display_print_chip_line::@1]
    // [2375] phi display_print_chip_line::i#2 = 0 [phi:display_print_chip_line::@7->display_print_chip_line::@1#0] -- vbum1=vbuc1 
    lda #0
    sta i
    // display_print_chip_line::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [2376] if(display_print_chip_line::i#2<display_print_chip_line::w#10) goto display_print_chip_line::@2 -- vbum1_lt_vbuz2_then_la1 
    lda i
    cmp.z w
    bcc __b2
    // [2377] phi from display_print_chip_line::@1 to display_print_chip_line::@3 [phi:display_print_chip_line::@1->display_print_chip_line::@3]
    // display_print_chip_line::@3
    // textcolor(GREY)
    // [2378] call textcolor
    // [584] phi from display_print_chip_line::@3 to textcolor [phi:display_print_chip_line::@3->textcolor]
    // [584] phi textcolor::color#18 = GREY [phi:display_print_chip_line::@3->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [2379] phi from display_print_chip_line::@3 to display_print_chip_line::@8 [phi:display_print_chip_line::@3->display_print_chip_line::@8]
    // display_print_chip_line::@8
    // bgcolor(BLUE)
    // [2380] call bgcolor
    // [589] phi from display_print_chip_line::@8 to bgcolor [phi:display_print_chip_line::@8->bgcolor]
    // [589] phi bgcolor::color#14 = BLUE [phi:display_print_chip_line::@8->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_print_chip_line::@9
    // cputc(VERA_CHR_UL)
    // [2381] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [2382] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [2384] call textcolor
    // [584] phi from display_print_chip_line::@9 to textcolor [phi:display_print_chip_line::@9->textcolor]
    // [584] phi textcolor::color#18 = WHITE [phi:display_print_chip_line::@9->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [2385] phi from display_print_chip_line::@9 to display_print_chip_line::@10 [phi:display_print_chip_line::@9->display_print_chip_line::@10]
    // display_print_chip_line::@10
    // bgcolor(BLACK)
    // [2386] call bgcolor
    // [589] phi from display_print_chip_line::@10 to bgcolor [phi:display_print_chip_line::@10->bgcolor]
    // [589] phi bgcolor::color#14 = BLACK [phi:display_print_chip_line::@10->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // display_print_chip_line::@11
    // cputcxy(x+2, y, c)
    // [2387] cputcxy::x#8 = display_print_chip_line::x#16 + 2 -- vbum1=vbuz2_plus_2 
    lda.z x
    clc
    adc #2
    sta cputcxy.x
    // [2388] cputcxy::y#8 = display_print_chip_line::y#16 -- vbum1=vbuz2 
    lda.z y
    sta cputcxy.y
    // [2389] cputcxy::c#8 = display_print_chip_line::c#15 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [2390] call cputcxy
    // [1787] phi from display_print_chip_line::@11 to cputcxy [phi:display_print_chip_line::@11->cputcxy]
    // [1787] phi cputcxy::c#15 = cputcxy::c#8 [phi:display_print_chip_line::@11->cputcxy#0] -- register_copy 
    // [1787] phi cputcxy::y#15 = cputcxy::y#8 [phi:display_print_chip_line::@11->cputcxy#1] -- register_copy 
    // [1787] phi cputcxy::x#15 = cputcxy::x#8 [phi:display_print_chip_line::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_print_chip_line::@return
    // }
    // [2391] return 
    rts
    // display_print_chip_line::@2
  __b2:
    // cputc(VERA_CHR_SPACE)
    // [2392] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [2393] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [2395] display_print_chip_line::i#1 = ++ display_print_chip_line::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [2375] phi from display_print_chip_line::@2 to display_print_chip_line::@1 [phi:display_print_chip_line::@2->display_print_chip_line::@1]
    // [2375] phi display_print_chip_line::i#2 = display_print_chip_line::i#1 [phi:display_print_chip_line::@2->display_print_chip_line::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    i: .byte 0
}
.segment Code
  // display_print_chip_end
// void display_print_chip_end(__zp($bb) char x, char y, __zp($2b) char w)
display_print_chip_end: {
    .label x = $bb
    .label w = $2b
    // gotoxy(x, y)
    // [2396] gotoxy::x#8 = display_print_chip_end::x#0 -- vbum1=vbuz2 
    lda.z x
    sta gotoxy.x
    // [2397] call gotoxy
    // [602] phi from display_print_chip_end to gotoxy [phi:display_print_chip_end->gotoxy]
    // [602] phi gotoxy::y#30 = print_chip::y#21 [phi:display_print_chip_end->gotoxy#0] -- vbum1=vbuc1 
    lda #print_chip.y
    sta gotoxy.y
    // [602] phi gotoxy::x#30 = gotoxy::x#8 [phi:display_print_chip_end->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [2398] phi from display_print_chip_end to display_print_chip_end::@4 [phi:display_print_chip_end->display_print_chip_end::@4]
    // display_print_chip_end::@4
    // textcolor(GREY)
    // [2399] call textcolor
    // [584] phi from display_print_chip_end::@4 to textcolor [phi:display_print_chip_end::@4->textcolor]
    // [584] phi textcolor::color#18 = GREY [phi:display_print_chip_end::@4->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [2400] phi from display_print_chip_end::@4 to display_print_chip_end::@5 [phi:display_print_chip_end::@4->display_print_chip_end::@5]
    // display_print_chip_end::@5
    // bgcolor(BLUE)
    // [2401] call bgcolor
    // [589] phi from display_print_chip_end::@5 to bgcolor [phi:display_print_chip_end::@5->bgcolor]
    // [589] phi bgcolor::color#14 = BLUE [phi:display_print_chip_end::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_print_chip_end::@6
    // cputc(VERA_CHR_UR)
    // [2402] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [2403] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [2405] call textcolor
    // [584] phi from display_print_chip_end::@6 to textcolor [phi:display_print_chip_end::@6->textcolor]
    // [584] phi textcolor::color#18 = BLUE [phi:display_print_chip_end::@6->textcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta textcolor.color
    jsr textcolor
    // [2406] phi from display_print_chip_end::@6 to display_print_chip_end::@7 [phi:display_print_chip_end::@6->display_print_chip_end::@7]
    // display_print_chip_end::@7
    // bgcolor(BLACK)
    // [2407] call bgcolor
    // [589] phi from display_print_chip_end::@7 to bgcolor [phi:display_print_chip_end::@7->bgcolor]
    // [589] phi bgcolor::color#14 = BLACK [phi:display_print_chip_end::@7->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // [2408] phi from display_print_chip_end::@7 to display_print_chip_end::@1 [phi:display_print_chip_end::@7->display_print_chip_end::@1]
    // [2408] phi display_print_chip_end::i#2 = 0 [phi:display_print_chip_end::@7->display_print_chip_end::@1#0] -- vbum1=vbuc1 
    lda #0
    sta i
    // display_print_chip_end::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [2409] if(display_print_chip_end::i#2<display_print_chip_end::w#0) goto display_print_chip_end::@2 -- vbum1_lt_vbuz2_then_la1 
    lda i
    cmp.z w
    bcc __b2
    // [2410] phi from display_print_chip_end::@1 to display_print_chip_end::@3 [phi:display_print_chip_end::@1->display_print_chip_end::@3]
    // display_print_chip_end::@3
    // textcolor(GREY)
    // [2411] call textcolor
    // [584] phi from display_print_chip_end::@3 to textcolor [phi:display_print_chip_end::@3->textcolor]
    // [584] phi textcolor::color#18 = GREY [phi:display_print_chip_end::@3->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [2412] phi from display_print_chip_end::@3 to display_print_chip_end::@8 [phi:display_print_chip_end::@3->display_print_chip_end::@8]
    // display_print_chip_end::@8
    // bgcolor(BLUE)
    // [2413] call bgcolor
    // [589] phi from display_print_chip_end::@8 to bgcolor [phi:display_print_chip_end::@8->bgcolor]
    // [589] phi bgcolor::color#14 = BLUE [phi:display_print_chip_end::@8->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_print_chip_end::@9
    // cputc(VERA_CHR_UL)
    // [2414] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [2415] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_print_chip_end::@return
    // }
    // [2417] return 
    rts
    // display_print_chip_end::@2
  __b2:
    // cputc(VERA_CHR_HL)
    // [2418] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [2419] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [2421] display_print_chip_end::i#1 = ++ display_print_chip_end::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [2408] phi from display_print_chip_end::@2 to display_print_chip_end::@1 [phi:display_print_chip_end::@2->display_print_chip_end::@1]
    // [2408] phi display_print_chip_end::i#2 = display_print_chip_end::i#1 [phi:display_print_chip_end::@2->display_print_chip_end::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    i: .byte 0
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
// __mem() unsigned int utoa_append(__zp($4b) char *buffer, __mem() unsigned int value, __mem() unsigned int sub)
utoa_append: {
    .label buffer = $4b
    // [2423] phi from utoa_append to utoa_append::@1 [phi:utoa_append->utoa_append::@1]
    // [2423] phi utoa_append::digit#2 = 0 [phi:utoa_append->utoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [2423] phi utoa_append::value#2 = utoa_append::value#0 [phi:utoa_append->utoa_append::@1#1] -- register_copy 
    // utoa_append::@1
  __b1:
    // while (value >= sub)
    // [2424] if(utoa_append::value#2>=utoa_append::sub#0) goto utoa_append::@2 -- vwum1_ge_vwum2_then_la1 
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
    // [2425] *utoa_append::buffer#0 = DIGITS[utoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // utoa_append::@return
    // }
    // [2426] return 
    rts
    // utoa_append::@2
  __b2:
    // digit++;
    // [2427] utoa_append::digit#1 = ++ utoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [2428] utoa_append::value#1 = utoa_append::value#2 - utoa_append::sub#0 -- vwum1=vwum1_minus_vwum2 
    lda value
    sec
    sbc sub
    sta value
    lda value+1
    sbc sub+1
    sta value+1
    // [2423] phi from utoa_append::@2 to utoa_append::@1 [phi:utoa_append::@2->utoa_append::@1]
    // [2423] phi utoa_append::digit#2 = utoa_append::digit#1 [phi:utoa_append::@2->utoa_append::@1#0] -- register_copy 
    // [2423] phi utoa_append::value#2 = utoa_append::value#1 [phi:utoa_append::@2->utoa_append::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label value = smc_detect.return
    .label sub = utoa.digit_value
    .label return = smc_detect.return
    digit: .byte 0
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
// void rom_write_byte(__zp($3d) unsigned long address, __zp($41) char value)
rom_write_byte: {
    .label rom_bank1_rom_write_byte__0 = $29
    .label rom_bank1_rom_write_byte__1 = $3a
    .label rom_bank1_rom_write_byte__2 = $3b
    .label rom_ptr1_rom_write_byte__0 = $36
    .label rom_ptr1_rom_write_byte__2 = $36
    .label rom_ptr1_return = $36
    .label address = $3d
    .label value = $41
    // rom_write_byte::rom_bank1
    // BYTE2(address)
    // [2430] rom_write_byte::rom_bank1_$0 = byte2  rom_write_byte::address#4 -- vbuz1=_byte2_vduz2 
    lda.z address+2
    sta.z rom_bank1_rom_write_byte__0
    // BYTE1(address)
    // [2431] rom_write_byte::rom_bank1_$1 = byte1  rom_write_byte::address#4 -- vbuz1=_byte1_vduz2 
    lda.z address+1
    sta.z rom_bank1_rom_write_byte__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2432] rom_write_byte::rom_bank1_$2 = rom_write_byte::rom_bank1_$0 w= rom_write_byte::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_write_byte__0
    sta.z rom_bank1_rom_write_byte__2+1
    lda.z rom_bank1_rom_write_byte__1
    sta.z rom_bank1_rom_write_byte__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2433] rom_write_byte::rom_bank1_bank_unshifted#0 = rom_write_byte::rom_bank1_$2 << 2 -- vwum1=vwuz2_rol_2 
    asl
    sta rom_bank1_bank_unshifted
    lda.z rom_bank1_rom_write_byte__2+1
    rol
    sta rom_bank1_bank_unshifted+1
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2434] rom_write_byte::rom_bank1_return#0 = byte1  rom_write_byte::rom_bank1_bank_unshifted#0 -- vbum1=_byte1_vwum2 
    lda rom_bank1_bank_unshifted+1
    sta rom_bank1_return
    // rom_write_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2435] rom_write_byte::rom_ptr1_$2 = (unsigned int)rom_write_byte::address#4 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_write_byte__2
    lda.z address+1
    sta.z rom_ptr1_rom_write_byte__2+1
    // [2436] rom_write_byte::rom_ptr1_$0 = rom_write_byte::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_write_byte__0
    and #<$3fff
    sta.z rom_ptr1_rom_write_byte__0
    lda.z rom_ptr1_rom_write_byte__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_write_byte__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2437] rom_write_byte::rom_ptr1_return#0 = rom_write_byte::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_write_byte::bank_set_brom1
    // BROM = bank
    // [2438] BROM = rom_write_byte::rom_bank1_return#0 -- vbuz1=vbum2 
    lda rom_bank1_return
    sta.z BROM
    // rom_write_byte::@1
    // *ptr_rom = value
    // [2439] *((char *)rom_write_byte::rom_ptr1_return#0) = rom_write_byte::value#10 -- _deref_pbuz1=vbuz2 
    lda.z value
    ldy #0
    sta (rom_ptr1_return),y
    // rom_write_byte::@return
    // }
    // [2440] return 
    rts
  .segment Data
    rom_bank1_bank_unshifted: .word 0
    rom_bank1_return: .byte 0
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
    // [2442] return 
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
// __mem() int ferror(__zp($5e) struct $2 *stream)
ferror: {
    .label ferror__6 = $3a
    .label ferror__15 = $2b
    .label cbm_k_setnam1_filename = $c0
    .label cbm_k_setnam1_ferror__0 = $3b
    .label stream = $5e
    .label errno_len = $41
    // unsigned char sp = (unsigned char)stream
    // [2443] ferror::sp#0 = (char)ferror::stream#0 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_setlfs(15, 8, 15)
    // [2444] cbm_k_setlfs::channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.channel
    // [2445] cbm_k_setlfs::device = 8 -- vbum1=vbuc1 
    lda #8
    sta cbm_k_setlfs.device
    // [2446] cbm_k_setlfs::command = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.command
    // [2447] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // ferror::@11
    // cbm_k_setnam("")
    // [2448] ferror::cbm_k_setnam1_filename = info_text4 -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z cbm_k_setnam1_filename
    lda #>info_text4
    sta.z cbm_k_setnam1_filename+1
    // ferror::cbm_k_setnam1
    // strlen(filename)
    // [2449] strlen::str#5 = ferror::cbm_k_setnam1_filename -- pbuz1=pbuz2 
    lda.z cbm_k_setnam1_filename
    sta.z strlen.str
    lda.z cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [2450] call strlen
    // [2170] phi from ferror::cbm_k_setnam1 to strlen [phi:ferror::cbm_k_setnam1->strlen]
    // [2170] phi strlen::str#8 = strlen::str#5 [phi:ferror::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [2451] strlen::return#12 = strlen::len#2
    // ferror::@12
    // [2452] ferror::cbm_k_setnam1_$0 = strlen::return#12 -- vwuz1=vwum2 
    lda strlen.return
    sta.z cbm_k_setnam1_ferror__0
    lda strlen.return+1
    sta.z cbm_k_setnam1_ferror__0+1
    // char filename_len = (char)strlen(filename)
    // [2453] ferror::cbm_k_setnam1_filename_len = (char)ferror::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
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
    // [2456] ferror::cbm_k_chkin1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_chkin1_channel
    // ferror::cbm_k_chkin1
    // char status
    // [2457] ferror::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // ferror::cbm_k_chrin1
    // char ch
    // [2459] ferror::cbm_k_chrin1_ch = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chrin1_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin1_ch
    // return ch;
    // [2461] ferror::cbm_k_chrin1_return#0 = ferror::cbm_k_chrin1_ch -- vbum1=vbum2 
    sta cbm_k_chrin1_return
    // ferror::cbm_k_chrin1_@return
    // }
    // [2462] ferror::cbm_k_chrin1_return#1 = ferror::cbm_k_chrin1_return#0
    // ferror::@7
    // char ch = cbm_k_chrin()
    // [2463] ferror::ch#0 = ferror::cbm_k_chrin1_return#1
    // [2464] phi from ferror::@7 to ferror::cbm_k_readst1 [phi:ferror::@7->ferror::cbm_k_readst1]
    // [2464] phi __errno#18 = __errno#335 [phi:ferror::@7->ferror::cbm_k_readst1#0] -- register_copy 
    // [2464] phi ferror::errno_len#10 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z errno_len
    // [2464] phi ferror::ch#10 = ferror::ch#0 [phi:ferror::@7->ferror::cbm_k_readst1#2] -- register_copy 
    // [2464] phi ferror::errno_parsed#2 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#3] -- vbum1=vbuc1 
    sta errno_parsed
    // ferror::cbm_k_readst1
  cbm_k_readst1:
    // char status
    // [2465] ferror::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2467] ferror::cbm_k_readst1_return#0 = ferror::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // ferror::cbm_k_readst1_@return
    // }
    // [2468] ferror::cbm_k_readst1_return#1 = ferror::cbm_k_readst1_return#0
    // ferror::@8
    // cbm_k_readst()
    // [2469] ferror::$6 = ferror::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z ferror__6
    // st = cbm_k_readst()
    // [2470] ferror::st#1 = ferror::$6 -- vbum1=vbuz2 
    sta st
    // while (!(st = cbm_k_readst()))
    // [2471] if(0==ferror::st#1) goto ferror::@1 -- 0_eq_vbum1_then_la1 
    beq __b1
    // ferror::@2
    // __status = st
    // [2472] ((char *)&__stdio_file+$8c)[ferror::sp#0] = ferror::st#1 -- pbuc1_derefidx_vbum1=vbum2 
    ldy sp
    sta __stdio_file+$8c,y
    // cbm_k_close(15)
    // [2473] ferror::cbm_k_close1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_close1_channel
    // ferror::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // ferror::@9
    // return __errno;
    // [2475] ferror::return#1 = __errno#18 -- vwsm1=vwsm2 
    lda __errno
    sta return
    lda __errno+1
    sta return+1
    // ferror::@return
    // }
    // [2476] return 
    rts
    // ferror::@1
  __b1:
    // if (!errno_parsed)
    // [2477] if(0!=ferror::errno_parsed#2) goto ferror::@3 -- 0_neq_vbum1_then_la1 
    lda errno_parsed
    bne __b3
    // ferror::@4
    // if (ch == ',')
    // [2478] if(ferror::ch#10!=',') goto ferror::@3 -- vbum1_neq_vbuc1_then_la1 
    lda #','
    cmp ch
    bne __b3
    // ferror::@5
    // errno_parsed++;
    // [2479] ferror::errno_parsed#1 = ++ ferror::errno_parsed#2 -- vbum1=_inc_vbum1 
    inc errno_parsed
    // strncpy(temp, __errno_error, errno_len+1)
    // [2480] strncpy::n#0 = ferror::errno_len#10 + 1 -- vwum1=vbuz2_plus_1 
    lda.z errno_len
    clc
    adc #1
    sta strncpy.n
    lda #0
    adc #0
    sta strncpy.n+1
    // [2481] call strncpy
    // [1551] phi from ferror::@5 to strncpy [phi:ferror::@5->strncpy]
    // [1551] phi strncpy::dst#8 = ferror::temp [phi:ferror::@5->strncpy#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z strncpy.dst
    lda #>temp
    sta.z strncpy.dst+1
    // [1551] phi strncpy::src#6 = __errno_error [phi:ferror::@5->strncpy#1] -- pbuz1=pbuc1 
    lda #<__errno_error
    sta.z strncpy.src
    lda #>__errno_error
    sta.z strncpy.src+1
    // [1551] phi strncpy::n#3 = strncpy::n#0 [phi:ferror::@5->strncpy#2] -- register_copy 
    jsr strncpy
    // [2482] phi from ferror::@5 to ferror::@13 [phi:ferror::@5->ferror::@13]
    // ferror::@13
    // atoi(temp)
    // [2483] call atoi
    // [2495] phi from ferror::@13 to atoi [phi:ferror::@13->atoi]
    // [2495] phi atoi::str#2 = ferror::temp [phi:ferror::@13->atoi#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z atoi.str
    lda #>temp
    sta.z atoi.str+1
    jsr atoi
    // atoi(temp)
    // [2484] atoi::return#4 = atoi::return#2
    // ferror::@14
    // __errno = atoi(temp)
    // [2485] __errno#2 = atoi::return#4 -- vwsm1=vwsm2 
    lda atoi.return
    sta __errno
    lda atoi.return+1
    sta __errno+1
    // [2486] phi from ferror::@1 ferror::@14 ferror::@4 to ferror::@3 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3]
    // [2486] phi __errno#103 = __errno#18 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#0] -- register_copy 
    // [2486] phi ferror::errno_parsed#11 = ferror::errno_parsed#2 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#1] -- register_copy 
    // ferror::@3
  __b3:
    // __errno_error[errno_len] = ch
    // [2487] __errno_error[ferror::errno_len#10] = ferror::ch#10 -- pbuc1_derefidx_vbuz1=vbum2 
    lda ch
    ldy.z errno_len
    sta __errno_error,y
    // errno_len++;
    // [2488] ferror::errno_len#1 = ++ ferror::errno_len#10 -- vbuz1=_inc_vbuz1 
    inc.z errno_len
    // ferror::cbm_k_chrin2
    // char ch
    // [2489] ferror::cbm_k_chrin2_ch = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chrin2_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin2_ch
    // return ch;
    // [2491] ferror::cbm_k_chrin2_return#0 = ferror::cbm_k_chrin2_ch -- vbum1=vbum2 
    sta cbm_k_chrin2_return
    // ferror::cbm_k_chrin2_@return
    // }
    // [2492] ferror::cbm_k_chrin2_return#1 = ferror::cbm_k_chrin2_return#0
    // ferror::@10
    // cbm_k_chrin()
    // [2493] ferror::$15 = ferror::cbm_k_chrin2_return#1 -- vbuz1=vbum2 
    sta.z ferror__15
    // ch = cbm_k_chrin()
    // [2494] ferror::ch#1 = ferror::$15 -- vbum1=vbuz2 
    sta ch
    // [2464] phi from ferror::@10 to ferror::cbm_k_readst1 [phi:ferror::@10->ferror::cbm_k_readst1]
    // [2464] phi __errno#18 = __errno#103 [phi:ferror::@10->ferror::cbm_k_readst1#0] -- register_copy 
    // [2464] phi ferror::errno_len#10 = ferror::errno_len#1 [phi:ferror::@10->ferror::cbm_k_readst1#1] -- register_copy 
    // [2464] phi ferror::ch#10 = ferror::ch#1 [phi:ferror::@10->ferror::cbm_k_readst1#2] -- register_copy 
    // [2464] phi ferror::errno_parsed#2 = ferror::errno_parsed#11 [phi:ferror::@10->ferror::cbm_k_readst1#3] -- register_copy 
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
// __mem() int atoi(__zp($6d) const char *str)
atoi: {
    .label atoi__6 = $36
    .label atoi__7 = $36
    .label str = $6d
    .label atoi__10 = $36
    .label atoi__11 = $36
    // if (str[i] == '-')
    // [2496] if(*atoi::str#2!='-') goto atoi::@3 -- _deref_pbuz1_neq_vbuc1_then_la1 
    ldy #0
    lda (str),y
    cmp #'-'
    bne __b2
    // [2497] phi from atoi to atoi::@2 [phi:atoi->atoi::@2]
    // atoi::@2
    // [2498] phi from atoi::@2 to atoi::@3 [phi:atoi::@2->atoi::@3]
    // [2498] phi atoi::negative#2 = 1 [phi:atoi::@2->atoi::@3#0] -- vbum1=vbuc1 
    lda #1
    sta negative
    // [2498] phi atoi::res#2 = 0 [phi:atoi::@2->atoi::@3#1] -- vwsm1=vwsc1 
    tya
    sta res
    sta res+1
    // [2498] phi atoi::i#4 = 1 [phi:atoi::@2->atoi::@3#2] -- vbum1=vbuc1 
    lda #1
    sta i
    jmp __b3
  // Iterate through all digits and update the result
    // [2498] phi from atoi to atoi::@3 [phi:atoi->atoi::@3]
  __b2:
    // [2498] phi atoi::negative#2 = 0 [phi:atoi->atoi::@3#0] -- vbum1=vbuc1 
    lda #0
    sta negative
    // [2498] phi atoi::res#2 = 0 [phi:atoi->atoi::@3#1] -- vwsm1=vwsc1 
    sta res
    sta res+1
    // [2498] phi atoi::i#4 = 0 [phi:atoi->atoi::@3#2] -- vbum1=vbuc1 
    sta i
    // atoi::@3
  __b3:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [2499] if(atoi::str#2[atoi::i#4]<'0') goto atoi::@5 -- pbuz1_derefidx_vbum2_lt_vbuc1_then_la1 
    ldy i
    lda (str),y
    cmp #'0'
    bcc __b5
    // atoi::@6
    // [2500] if(atoi::str#2[atoi::i#4]<='9') goto atoi::@4 -- pbuz1_derefidx_vbum2_le_vbuc1_then_la1 
    lda (str),y
    cmp #'9'
    bcc __b4
    beq __b4
    // atoi::@5
  __b5:
    // if(negative)
    // [2501] if(0!=atoi::negative#2) goto atoi::@1 -- 0_neq_vbum1_then_la1 
    // Return result with sign
    lda negative
    bne __b1
    // [2503] phi from atoi::@1 atoi::@5 to atoi::@return [phi:atoi::@1/atoi::@5->atoi::@return]
    // [2503] phi atoi::return#2 = atoi::return#0 [phi:atoi::@1/atoi::@5->atoi::@return#0] -- register_copy 
    rts
    // atoi::@1
  __b1:
    // return -res;
    // [2502] atoi::return#0 = - atoi::res#2 -- vwsm1=_neg_vwsm1 
    lda #0
    sec
    sbc return
    sta return
    lda #0
    sbc return+1
    sta return+1
    // atoi::@return
    // }
    // [2504] return 
    rts
    // atoi::@4
  __b4:
    // res * 10
    // [2505] atoi::$10 = atoi::res#2 << 2 -- vwsz1=vwsm2_rol_2 
    lda res
    asl
    sta.z atoi__10
    lda res+1
    rol
    sta.z atoi__10+1
    asl.z atoi__10
    rol.z atoi__10+1
    // [2506] atoi::$11 = atoi::$10 + atoi::res#2 -- vwsz1=vwsz1_plus_vwsm2 
    clc
    lda.z atoi__11
    adc res
    sta.z atoi__11
    lda.z atoi__11+1
    adc res+1
    sta.z atoi__11+1
    // [2507] atoi::$6 = atoi::$11 << 1 -- vwsz1=vwsz1_rol_1 
    asl.z atoi__6
    rol.z atoi__6+1
    // res * 10 + str[i]
    // [2508] atoi::$7 = atoi::$6 + atoi::str#2[atoi::i#4] -- vwsz1=vwsz1_plus_pbuz2_derefidx_vbum3 
    ldy i
    lda.z atoi__7
    clc
    adc (str),y
    sta.z atoi__7
    bcc !+
    inc.z atoi__7+1
  !:
    // res = res * 10 + str[i] - '0'
    // [2509] atoi::res#1 = atoi::$7 - '0' -- vwsm1=vwsz2_minus_vbuc1 
    lda.z atoi__7
    sec
    sbc #'0'
    sta res
    lda.z atoi__7+1
    sbc #0
    sta res+1
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [2510] atoi::i#2 = ++ atoi::i#4 -- vbum1=_inc_vbum1 
    inc i
    // [2498] phi from atoi::@4 to atoi::@3 [phi:atoi::@4->atoi::@3]
    // [2498] phi atoi::negative#2 = atoi::negative#2 [phi:atoi::@4->atoi::@3#0] -- register_copy 
    // [2498] phi atoi::res#2 = atoi::res#1 [phi:atoi::@4->atoi::@3#1] -- register_copy 
    // [2498] phi atoi::i#4 = atoi::i#2 [phi:atoi::@4->atoi::@3#2] -- register_copy 
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
// __mem() unsigned int cx16_k_macptr(__mem() volatile char bytes, __zp($67) void * volatile buffer)
cx16_k_macptr: {
    .label buffer = $67
    // unsigned int bytes_read
    // [2511] cx16_k_macptr::bytes_read = 0 -- vwum1=vwuc1 
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
    // [2513] cx16_k_macptr::return#0 = cx16_k_macptr::bytes_read -- vwum1=vwum2 
    lda bytes_read
    sta return
    lda bytes_read+1
    sta return+1
    // cx16_k_macptr::@return
    // }
    // [2514] cx16_k_macptr::return#1 = cx16_k_macptr::return#0
    // [2515] return 
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
    // [2517] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [2517] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [2517] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [2518] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbum1_ge_vbum2_then_la1 
    lda value
    cmp sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [2519] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // uctoa_append::@return
    // }
    // [2520] return 
    rts
    // uctoa_append::@2
  __b2:
    // digit++;
    // [2521] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [2522] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbum1=vbum1_minus_vbum2 
    lda value
    sec
    sbc sub
    sta value
    // [2517] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [2517] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [2517] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label value = printf_uchar.uvalue
    .label sub = uctoa.digit_value
    .label return = printf_uchar.uvalue
    digit: .byte 0
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
// __mem() char rom_byte_compare(__zp($4d) char *ptr_rom, __zp($46) char value)
rom_byte_compare: {
    .label ptr_rom = $4d
    .label value = $46
    // if (*ptr_rom != value)
    // [2523] if(*rom_byte_compare::ptr_rom#0==rom_byte_compare::value#0) goto rom_byte_compare::@1 -- _deref_pbuz1_eq_vbuz2_then_la1 
    lda.z value
    ldy #0
    cmp (ptr_rom),y
    beq __b2
    // [2524] phi from rom_byte_compare to rom_byte_compare::@2 [phi:rom_byte_compare->rom_byte_compare::@2]
    // rom_byte_compare::@2
    // [2525] phi from rom_byte_compare::@2 to rom_byte_compare::@1 [phi:rom_byte_compare::@2->rom_byte_compare::@1]
    // [2525] phi rom_byte_compare::return#0 = 0 [phi:rom_byte_compare::@2->rom_byte_compare::@1#0] -- vbum1=vbuc1 
    tya
    sta return
    rts
    // [2525] phi from rom_byte_compare to rom_byte_compare::@1 [phi:rom_byte_compare->rom_byte_compare::@1]
  __b2:
    // [2525] phi rom_byte_compare::return#0 = 1 [phi:rom_byte_compare->rom_byte_compare::@1#0] -- vbum1=vbuc1 
    lda #1
    sta return
    // rom_byte_compare::@1
    // rom_byte_compare::@return
    // }
    // [2526] return 
    rts
  .segment Data
    return: .byte 0
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
// __mem() unsigned long ultoa_append(__zp($42) char *buffer, __mem() unsigned long value, __mem() unsigned long sub)
ultoa_append: {
    .label buffer = $42
    // [2528] phi from ultoa_append to ultoa_append::@1 [phi:ultoa_append->ultoa_append::@1]
    // [2528] phi ultoa_append::digit#2 = 0 [phi:ultoa_append->ultoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [2528] phi ultoa_append::value#2 = ultoa_append::value#0 [phi:ultoa_append->ultoa_append::@1#1] -- register_copy 
    // ultoa_append::@1
  __b1:
    // while (value >= sub)
    // [2529] if(ultoa_append::value#2>=ultoa_append::sub#0) goto ultoa_append::@2 -- vdum1_ge_vdum2_then_la1 
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
    // [2530] *ultoa_append::buffer#0 = DIGITS[ultoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // ultoa_append::@return
    // }
    // [2531] return 
    rts
    // ultoa_append::@2
  __b2:
    // digit++;
    // [2532] ultoa_append::digit#1 = ++ ultoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [2533] ultoa_append::value#1 = ultoa_append::value#2 - ultoa_append::sub#0 -- vdum1=vdum1_minus_vdum2 
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
    // [2528] phi from ultoa_append::@2 to ultoa_append::@1 [phi:ultoa_append::@2->ultoa_append::@1]
    // [2528] phi ultoa_append::digit#2 = ultoa_append::digit#1 [phi:ultoa_append::@2->ultoa_append::@1#0] -- register_copy 
    // [2528] phi ultoa_append::value#2 = ultoa_append::value#1 [phi:ultoa_append::@2->ultoa_append::@1#1] -- register_copy 
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
    // [2535] rom_wait::test1#1 = *rom_wait::ptr_rom#3 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (ptr_rom),y
    sta test1
    // test2 = *((brom_ptr_t)ptr_rom)
    // [2536] rom_wait::test2#1 = *rom_wait::ptr_rom#3 -- vbum1=_deref_pbuz2 
    lda (ptr_rom),y
    sta test2
    // test1 & 0x40
    // [2537] rom_wait::$0 = rom_wait::test1#1 & $40 -- vbuz1=vbum2_band_vbuc1 
    lda #$40
    and test1
    sta.z rom_wait__0
    // test2 & 0x40
    // [2538] rom_wait::$1 = rom_wait::test2#1 & $40 -- vbuz1=vbum2_band_vbuc1 
    lda #$40
    and test2
    sta.z rom_wait__1
    // while ((test1 & 0x40) != (test2 & 0x40))
    // [2539] if(rom_wait::$0!=rom_wait::$1) goto rom_wait::@1 -- vbuz1_neq_vbuz2_then_la1 
    lda.z rom_wait__0
    cmp.z rom_wait__1
    bne __b1
    // rom_wait::@return
    // }
    // [2540] return 
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
// void rom_byte_program(__zp($3d) unsigned long address, __zp($41) char value)
rom_byte_program: {
    .label rom_ptr1_rom_byte_program__0 = $44
    .label rom_ptr1_rom_byte_program__2 = $44
    .label rom_ptr1_return = $44
    .label address = $3d
    .label value = $41
    // rom_byte_program::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2542] rom_byte_program::rom_ptr1_$2 = (unsigned int)rom_byte_program::address#0 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_byte_program__2
    lda.z address+1
    sta.z rom_ptr1_rom_byte_program__2+1
    // [2543] rom_byte_program::rom_ptr1_$0 = rom_byte_program::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_byte_program__0
    and #<$3fff
    sta.z rom_ptr1_rom_byte_program__0
    lda.z rom_ptr1_rom_byte_program__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_byte_program__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2544] rom_byte_program::rom_ptr1_return#0 = rom_byte_program::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_byte_program::@1
    // rom_write_byte(address, value)
    // [2545] rom_write_byte::address#3 = rom_byte_program::address#0
    // [2546] rom_write_byte::value#3 = rom_byte_program::value#0
    // [2547] call rom_write_byte
    // [2429] phi from rom_byte_program::@1 to rom_write_byte [phi:rom_byte_program::@1->rom_write_byte]
    // [2429] phi rom_write_byte::value#10 = rom_write_byte::value#3 [phi:rom_byte_program::@1->rom_write_byte#0] -- register_copy 
    // [2429] phi rom_write_byte::address#4 = rom_write_byte::address#3 [phi:rom_byte_program::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_byte_program::@2
    // rom_wait(ptr_rom)
    // [2548] rom_wait::ptr_rom#1 = (char *)rom_byte_program::rom_ptr1_return#0 -- pbuz1=pbuz2 
    lda.z rom_ptr1_return
    sta.z rom_wait.ptr_rom
    lda.z rom_ptr1_return+1
    sta.z rom_wait.ptr_rom+1
    // [2549] call rom_wait
    // [2534] phi from rom_byte_program::@2 to rom_wait [phi:rom_byte_program::@2->rom_wait]
    // [2534] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#1 [phi:rom_byte_program::@2->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_byte_program::@return
    // }
    // [2550] return 
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
// void memcpy8_vram_vram(__mem() char dbank_vram, __mem() unsigned int doffset_vram, __mem() char sbank_vram, __mem() unsigned int soffset_vram, __mem() char num8)
memcpy8_vram_vram: {
    .label memcpy8_vram_vram__0 = $23
    .label memcpy8_vram_vram__1 = $24
    .label memcpy8_vram_vram__2 = $25
    .label memcpy8_vram_vram__3 = $26
    .label memcpy8_vram_vram__4 = $27
    .label memcpy8_vram_vram__5 = $28
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2551] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [2552] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte0_vwum2 
    lda soffset_vram
    sta.z memcpy8_vram_vram__0
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [2553] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [2554] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte1_vwum2 
    lda soffset_vram+1
    sta.z memcpy8_vram_vram__1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [2555] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [2556] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbuz1=vbum2_bor_vbuc1 
    lda #VERA_INC_1
    ora sbank_vram
    sta.z memcpy8_vram_vram__2
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [2557] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [2558] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [2559] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte0_vwum2 
    lda doffset_vram
    sta.z memcpy8_vram_vram__3
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [2560] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [2561] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte1_vwum2 
    lda doffset_vram+1
    sta.z memcpy8_vram_vram__4
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [2562] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [2563] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbuz1=vbum2_bor_vbuc1 
    lda #VERA_INC_1
    ora dbank_vram
    sta.z memcpy8_vram_vram__5
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [2564] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // [2565] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [2565] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [2566] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbum1=_dec_vbum2 
    ldy num8_1
    dey
    sty num8
    // [2567] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbum1_then_la1 
    lda num8_1
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [2568] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [2569] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [2570] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbum1=vbum2 
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
  rom_device_ids: .byte 0
  .fill 7, 0
  rom_device_names: .word 0
  .fill 2*7, 0
  rom_size_strings: .word 0
  .fill 2*7, 0
  rom_github: .fill 2*8, 0
  rom_release: .fill 8, 0
  rom_manufacturer_ids: .byte 0
  .fill 7, 0
  rom_sizes: .dword 0
  .fill 4*7, 0
  file_sizes: .dword 0
  .fill 4*7, 0
  status_text: .word __3, __4, __5, __6, __7, __8, __9, __10, __11, __12, __13
  status_color: .byte BLACK, GREY, WHITE, CYAN, PURPLE, CYAN, PURPLE, PURPLE, GREEN, YELLOW, RED
  status_rom: .byte 0
  .fill 7, 0
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
  __14: .text "Welcome to the CX16 update tool! This program will update the"
  .byte 0
  __15: .text "chipsets on your CX16 board and on your ROM expansion cardridge."
  .byte 0
  __17: .text "Depending on the type of files placed on your SDCard,"
  .byte 0
  __18: .text "different chipsets will be updated of the CX16:"
  .byte 0
  __19: .text "- The mandatory SMC.BIN file updates the SMC firmware."
  .byte 0
  __20: .text "- The mandatory ROM.BIN file updates the main ROM."
  .byte 0
  __21: .text "- An optional VERA.BIN file updates your VERA firmware."
  .byte 0
  __22: .text "- Any optional ROMn.BIN file found on your SDCard "
  .byte 0
  __23: .text "  updates the relevant ROMs on your ROM expansion cardridge."
  .byte 0
  __24: .text "  Ensure your J1 jumpers are properly enabled on the CX16!"
  .byte 0
  __26: .text "Please read carefully the step by step instructions at "
  .byte 0
  __27: .text "https://flightcontrol-user.github.io/x16-flash"
  .byte 0
  __28: .text "The panels above indicate the update progress of your chipsets,"
  .byte 0
  __29: .text "using status indicators and colors as specified below:"
  .byte 0
  __31: .text " -   None       Not detected, no action."
  .byte 0
  __32: .text " -   Skipped    Detected, but no action, eg. no file."
  .byte 0
  __33: .text " -   Detected   Detected, verification pending."
  .byte 0
  __34: .text " -   Checking   Verifying size of the update file."
  .byte 0
  __35: .text " -   Reading    Reading the update file into RAM."
  .byte 0
  __36: .text " -   Comparing  Comparing the RAM with the ROM."
  .byte 0
  __37: .text " -   Update     Ready to update the firmware."
  .byte 0
  __38: .text " -   Updating   Updating the firmware."
  .byte 0
  __39: .text " -   Updated    Updated the firmware succesfully."
  .byte 0
  __40: .text " -   Issue      Problem identified during update."
  .byte 0
  __41: .text " -   Error      Error found during update."
  .byte 0
  __43: .text "Errors indicate your J1 jumpers are not properly set!"
  .byte 0
  __46: .text "Since your CX16 system SMC and main ROM chipset"
  .byte 0
  __47: .text "have not been updated, your CX16 will just reset."
  .byte 0
  __48: .text "Your CX16 system has been successfully updated!"
  .byte 0
  __50: .text "Because your SMC chipset has been updated,"
  .byte 0
  __51: .text "the restart process differs, depending on the"
  .byte 0
  __52: .text "SMC boootloader version installed on your CX16 board:"
  .byte 0
  __54: .text "- SMC bootloader v2.0: your CX16 will automatically shut down."
  .byte 0
  __56: .text "- SMC bootloader v1.0: you need to "
  .byte 0
  __57: .text "  COMPLETELY DISCONNECT your CX16 from the power source!"
  .byte 0
  __58: .text "  The power-off button won't work!"
  .byte 0
  __59: .text "  Then, reconnect and start the CX16 normally."
  .byte 0
  s1: .text " "
  .byte 0
  s4: .text "/"
  .byte 0
  s2: .text " -> RAM:"
  .byte 0
  s3: .text ":"
  .byte 0
  s7: .text " ..."
  .byte 0
  s14: .text "Reading "
  .byte 0
  info_text4: .text ""
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
  status_smc: .byte 0
  status_vera: .byte 0
  smc_bootloader: .word 0
  smc_file_size: .word 0
  smc_file_size_1: .word 0
  smc_file_size_2: .word 0
