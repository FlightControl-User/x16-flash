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
  .const display_intro_briefing_count = $10
  .const display_intro_colors_count = $10
  .const display_debriefing_count_smc = $c
  .const display_debriefing_count_rom = 4
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
  .label __snprintf_buffer = $ad
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
    .label conio_x16_init__4 = $d6
    .label conio_x16_init__5 = $be
    .label conio_x16_init__6 = $d8
    .label conio_x16_init__7 = $da
    // screenlayer1()
    // [19] call screenlayer1
    jsr screenlayer1
    // [20] phi from conio_x16_init to conio_x16_init::@1 [phi:conio_x16_init->conio_x16_init::@1]
    // conio_x16_init::@1
    // textcolor(CONIO_TEXTCOLOR_DEFAULT)
    // [21] call textcolor
    // [564] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [564] phi textcolor::color#18 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [22] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [23] call bgcolor
    // [569] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [569] phi bgcolor::color#14 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbum1=vbuc1 
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
    // [582] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [582] phi gotoxy::y#30 = gotoxy::y#2 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [582] phi gotoxy::x#30 = gotoxy::x#2 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
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
    .label cputc__2 = $54
    .label cputc__3 = $55
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
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 0
    .const bank_set_brom2_bank = 0
    .const bank_set_brom3_bank = 0
    .const bank_push_set_bram1_bank = 1
    .const bank_set_brom4_bank = 4
    .const bank_set_brom5_bank = 0
    .label main__106 = $5f
    .label main__182 = $d5
    .label main__184 = $b3
    .label main__186 = $dd
    .label cx16_k_screen_set_charset1_offset = $de
    .label check_smc1_main__0 = $74
    .label check_smc2_main__0 = $58
    .label check_cx16_rom1_check_rom1_main__0 = $7f
    .label check_smc3_main__0 = $78
    .label check_cx16_rom2_check_rom1_main__0 = $72
    .label check_card_roms1_check_rom1_main__0 = $d0
    .label check_smc4_main__0 = $b2
    .label check_rom1_main__0 = $bf
    .label check_smc5_main__0 = $b5
    .label check_vera1_main__0 = $cd
    .label check_roms_all1_check_rom1_main__0 = $b4
    .label check_smc6_main__0 = $b1
    .label check_smc7_main__0 = $c5
    .label check_vera2_main__0 = $79
    .label check_roms1_check_rom1_main__0 = $68
    .label check_smc8_main__0 = $7a
    .label check_vera3_main__0 = $c6
    .label check_roms2_check_rom1_main__0 = $69
    .label check_smc9_main__0 = $73
    .label file = $db
    .label file1 = $d1
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
    // main::@55
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
    // [76] phi from main::cx16_k_screen_set_charset1 to main::@56 [phi:main::cx16_k_screen_set_charset1->main::@56]
    // main::@56
    // display_frame_init_64()
    // [77] call display_frame_init_64
    // [603] phi from main::@56 to display_frame_init_64 [phi:main::@56->display_frame_init_64]
    jsr display_frame_init_64
    // [78] phi from main::@56 to main::@80 [phi:main::@56->main::@80]
    // main::@80
    // display_frame_draw()
    // [79] call display_frame_draw
    // [623] phi from main::@80 to display_frame_draw [phi:main::@80->display_frame_draw]
    jsr display_frame_draw
    // [80] phi from main::@80 to main::@81 [phi:main::@80->main::@81]
    // main::@81
    // display_frame_title("Commander X16 Flash Utility!")
    // [81] call display_frame_title
    // [664] phi from main::@81 to display_frame_title [phi:main::@81->display_frame_title]
    jsr display_frame_title
    // [82] phi from main::@81 to main::display_print_info_title1 [phi:main::@81->main::display_print_info_title1]
    // main::display_print_info_title1
    // cputsxy(INFO_X-2, INFO_Y-2, "# Chip Status    Type   File  / Total Information")
    // [83] call cputsxy
    // [669] phi from main::display_print_info_title1 to cputsxy [phi:main::display_print_info_title1->cputsxy]
    // [669] phi cputsxy::s#4 = main::s [phi:main::display_print_info_title1->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z cputsxy.s
    lda #>s
    sta.z cputsxy.s+1
    // [669] phi cputsxy::y#4 = $11-2 [phi:main::display_print_info_title1->cputsxy#1] -- vbum1=vbuc1 
    lda #$11-2
    sta cputsxy.y
    // [669] phi cputsxy::x#4 = 4-2 [phi:main::display_print_info_title1->cputsxy#2] -- vbum1=vbuc1 
    lda #4-2
    sta cputsxy.x
    jsr cputsxy
    // [84] phi from main::display_print_info_title1 to main::@82 [phi:main::display_print_info_title1->main::@82]
    // main::@82
    // cputsxy(INFO_X-2, INFO_Y-1, "- ---- --------- ------ ----- / ----- --------------------")
    // [85] call cputsxy
    // [669] phi from main::@82 to cputsxy [phi:main::@82->cputsxy]
    // [669] phi cputsxy::s#4 = main::s1 [phi:main::@82->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s1
    sta.z cputsxy.s
    lda #>s1
    sta.z cputsxy.s+1
    // [669] phi cputsxy::y#4 = $11-1 [phi:main::@82->cputsxy#1] -- vbum1=vbuc1 
    lda #$11-1
    sta cputsxy.y
    // [669] phi cputsxy::x#4 = 4-2 [phi:main::@82->cputsxy#2] -- vbum1=vbuc1 
    lda #4-2
    sta cputsxy.x
    jsr cputsxy
    // [86] phi from main::@82 to main::@57 [phi:main::@82->main::@57]
    // main::@57
    // display_progress_clear()
    // [87] call display_progress_clear
    // [676] phi from main::@57 to display_progress_clear [phi:main::@57->display_progress_clear]
    jsr display_progress_clear
    // [88] phi from main::@57 to main::@83 [phi:main::@57->main::@83]
    // main::@83
    // display_info_progress("Detecting SMC, VERA and ROM chipsets ...")
    // [89] call display_info_progress
  // info_print(0, "The SMC chip on the X16 board controls the power on/off, keyboard and mouse pheripherals.");
  // info_print(1, "It is essential that the SMC chip gets updated together with the latest ROM on the X16 board.");
  // info_print(2, "On the X16 board, near the SMC chip are two jumpers");
    // [691] phi from main::@83 to display_info_progress [phi:main::@83->display_info_progress]
    // [691] phi display_info_progress::info_text#14 = main::info_text [phi:main::@83->display_info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_progress.info_text
    lda #>info_text
    sta.z display_info_progress.info_text+1
    jsr display_info_progress
    // main::SEI1
    // asm
    // asm { sei  }
    sei
    // [91] phi from main::SEI1 to main::@58 [phi:main::SEI1->main::@58]
    // main::@58
    // smc_detect()
    // [92] call smc_detect
    jsr smc_detect
    // [93] smc_detect::return#2 = smc_detect::return#0
    // main::@84
    // smc_bootloader = smc_detect()
    // [94] smc_bootloader#0 = smc_detect::return#2 -- vwum1=vwum2 
    lda smc_detect.return
    sta smc_bootloader
    lda smc_detect.return+1
    sta smc_bootloader+1
    // display_chip_smc()
    // [95] call display_chip_smc
    // [716] phi from main::@84 to display_chip_smc [phi:main::@84->display_chip_smc]
    jsr display_chip_smc
    // main::@85
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
    // [101] phi from main::@5 to main::@90 [phi:main::@5->main::@90]
    // main::@90
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [102] call printf_str
    // [725] phi from main::@90 to printf_str [phi:main::@90->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:main::@90->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = main::s2 [phi:main::@90->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main::@91
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [103] printf_uint::uvalue#14 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta printf_uint.uvalue
    lda smc_bootloader+1
    sta printf_uint.uvalue+1
    // [104] call printf_uint
    // [734] phi from main::@91 to printf_uint [phi:main::@91->printf_uint]
    // [734] phi printf_uint::format_zero_padding#16 = 1 [phi:main::@91->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [734] phi printf_uint::format_min_length#16 = 2 [phi:main::@91->printf_uint#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uint.format_min_length
    // [734] phi printf_uint::putc#16 = &snputc [phi:main::@91->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [734] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:main::@91->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [734] phi printf_uint::uvalue#16 = printf_uint::uvalue#14 [phi:main::@91->printf_uint#4] -- register_copy 
    jsr printf_uint
    // main::@92
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
    // [745] phi from main::@92 to display_info_smc [phi:main::@92->display_info_smc]
    // [745] phi display_info_smc::info_text#12 = info_text [phi:main::@92->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_smc.info_text
    lda #>@info_text
    sta.z display_info_smc.info_text+1
    // [745] phi smc_file_size#12 = 0 [phi:main::@92->display_info_smc#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size_2
    sta smc_file_size_2+1
    // [745] phi display_info_smc::info_status#12 = STATUS_DETECTED [phi:main::@92->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_DETECTED
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // main::CLI1
  CLI1:
    // asm
    // asm { cli  }
    cli
    // [110] phi from main::CLI1 to main::@59 [phi:main::CLI1->main::@59]
    // main::@59
    // display_chip_vera()
    // [111] call display_chip_vera
  // Detecting VERA FPGA.
    // [775] phi from main::@59 to display_chip_vera [phi:main::@59->display_chip_vera]
    jsr display_chip_vera
    // [112] phi from main::@59 to main::@93 [phi:main::@59->main::@93]
    // main::@93
    // display_info_vera(STATUS_DETECTED, "VERA installed, OK")
    // [113] call display_info_vera
    // [780] phi from main::@93 to display_info_vera [phi:main::@93->display_info_vera]
    // [780] phi display_info_vera::info_text#10 = main::info_text3 [phi:main::@93->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text3
    sta.z display_info_vera.info_text
    lda #>info_text3
    sta.z display_info_vera.info_text+1
    // [780] phi display_info_vera::info_status#2 = STATUS_DETECTED [phi:main::@93->display_info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_DETECTED
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // main::SEI2
    // asm
    // asm { sei  }
    sei
    // [115] phi from main::SEI2 to main::@60 [phi:main::SEI2->main::@60]
    // main::@60
    // rom_detect()
    // [116] call rom_detect
  // Detecting ROM chips
    // [806] phi from main::@60 to rom_detect [phi:main::@60->rom_detect]
    jsr rom_detect
    // [117] phi from main::@60 to main::@94 [phi:main::@60->main::@94]
    // main::@94
    // display_chip_rom()
    // [118] call display_chip_rom
    // [856] phi from main::@94 to display_chip_rom [phi:main::@94->display_chip_rom]
    jsr display_chip_rom
    // [119] phi from main::@94 to main::@13 [phi:main::@94->main::@13]
    // [119] phi main::rom_chip#2 = 0 [phi:main::@94->main::@13#0] -- vbum1=vbuc1 
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
    // [122] phi from main::CLI2 to main::@61 [phi:main::CLI2->main::@61]
    // main::@61
    // display_progress_text(display_into_briefing_text, display_intro_briefing_count)
    // [123] call display_progress_text
    // [875] phi from main::@61 to display_progress_text [phi:main::@61->display_progress_text]
    // [875] phi display_progress_text::text#6 = display_into_briefing_text [phi:main::@61->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_into_briefing_text
    sta.z display_progress_text.text
    lda #>display_into_briefing_text
    sta.z display_progress_text.text+1
    // [875] phi display_progress_text::lines#5 = display_intro_briefing_count [phi:main::@61->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_intro_briefing_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [124] phi from main::@61 to main::@95 [phi:main::@61->main::@95]
    // main::@95
    // util_wait_key("Please read carefully the below, and press [SPACE] ...", " ")
    // [125] call util_wait_key
    // [884] phi from main::@95 to util_wait_key [phi:main::@95->util_wait_key]
    // [884] phi util_wait_key::filter#14 = s1 [phi:main::@95->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<@s1
    sta.z util_wait_key.filter
    lda #>@s1
    sta.z util_wait_key.filter+1
    // [884] phi util_wait_key::info_text#4 = main::info_text4 [phi:main::@95->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z util_wait_key.info_text
    lda #>info_text4
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // [126] phi from main::@95 to main::@96 [phi:main::@95->main::@96]
    // main::@96
    // display_progress_clear()
    // [127] call display_progress_clear
    // [676] phi from main::@96 to display_progress_clear [phi:main::@96->display_progress_clear]
    jsr display_progress_clear
    // [128] phi from main::@96 to main::@97 [phi:main::@96->main::@97]
    // main::@97
    // display_progress_text(display_into_colors_text, display_intro_colors_count)
    // [129] call display_progress_text
    // [875] phi from main::@97 to display_progress_text [phi:main::@97->display_progress_text]
    // [875] phi display_progress_text::text#6 = display_into_colors_text [phi:main::@97->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_into_colors_text
    sta.z display_progress_text.text
    lda #>display_into_colors_text
    sta.z display_progress_text.text+1
    // [875] phi display_progress_text::lines#5 = display_intro_colors_count [phi:main::@97->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_intro_colors_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [130] phi from main::@97 to main::@18 [phi:main::@97->main::@18]
    // [130] phi main::intro_status#2 = 0 [phi:main::@97->main::@18#0] -- vbum1=vbuc1 
    lda #0
    sta intro_status
    // main::@18
  __b18:
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [131] if(main::intro_status#2<$b) goto main::@19 -- vbum1_lt_vbuc1_then_la1 
    lda intro_status
    cmp #$b
    bcs !__b19+
    jmp __b19
  !__b19:
    // [132] phi from main::@18 to main::@20 [phi:main::@18->main::@20]
    // main::@20
    // util_wait_key("If understood, press [SPACE] to start the update ...", " ")
    // [133] call util_wait_key
    // [884] phi from main::@20 to util_wait_key [phi:main::@20->util_wait_key]
    // [884] phi util_wait_key::filter#14 = s1 [phi:main::@20->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<@s1
    sta.z util_wait_key.filter
    lda #>@s1
    sta.z util_wait_key.filter+1
    // [884] phi util_wait_key::info_text#4 = main::info_text7 [phi:main::@20->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z util_wait_key.info_text
    lda #>info_text7
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // [134] phi from main::@20 to main::@99 [phi:main::@20->main::@99]
    // main::@99
    // display_progress_clear()
    // [135] call display_progress_clear
    // [676] phi from main::@99 to display_progress_clear [phi:main::@99->display_progress_clear]
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
    // main::@62
    // if(check_smc(STATUS_DETECTED))
    // [139] if(0==main::check_smc1_return#0) goto main::CLI3 -- 0_eq_vbum1_then_la1 
    bne !__b4+
    jmp __b4
  !__b4:
    // [140] phi from main::@62 to main::@21 [phi:main::@62->main::@21]
    // main::@21
    // smc_read(8, 512)
    // [141] call smc_read
    // [908] phi from main::@21 to smc_read [phi:main::@21->smc_read]
    // [908] phi __errno#35 = 0 [phi:main::@21->smc_read#0] -- vwsm1=vwsc1 
    lda #<0
    sta __errno
    sta __errno+1
    jsr smc_read
    // smc_read(8, 512)
    // [142] smc_read::return#2 = smc_read::return#0
    // main::@100
    // smc_file_size = smc_read(8, 512)
    // [143] smc_file_size#0 = smc_read::return#2 -- vwum1=vwum2 
    lda smc_read.return
    sta smc_file_size
    lda smc_read.return+1
    sta smc_file_size+1
    // if (!smc_file_size)
    // [144] if(0==smc_file_size#0) goto main::@24 -- 0_eq_vwum1_then_la1 
    // In case no file was found, set the status to error and skip to the next, else, mention the amount of bytes read.
    lda smc_file_size
    ora smc_file_size+1
    bne !__b24+
    jmp __b24
  !__b24:
    // main::@22
    // if(smc_file_size > 0x1E00)
    // [145] if(smc_file_size#0>$1e00) goto main::@25 -- vwum1_gt_vwuc1_then_la1 
    // If the smc.bin file size is larger than 0x1E00 then there is an error!
    lda #>$1e00
    cmp smc_file_size+1
    bcs !__b25+
    jmp __b25
  !__b25:
    bne !+
    lda #<$1e00
    cmp smc_file_size
    bcs !__b25+
    jmp __b25
  !__b25:
  !:
    // [146] phi from main::@22 to main::@23 [phi:main::@22->main::@23]
    // main::@23
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [147] call snprintf_init
    jsr snprintf_init
    // [148] phi from main::@23 to main::@101 [phi:main::@23->main::@101]
    // main::@101
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [149] call printf_str
    // [725] phi from main::@101 to printf_str [phi:main::@101->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:main::@101->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = main::s2 [phi:main::@101->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main::@102
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [150] printf_uint::uvalue#15 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta printf_uint.uvalue
    lda smc_bootloader+1
    sta printf_uint.uvalue+1
    // [151] call printf_uint
    // [734] phi from main::@102 to printf_uint [phi:main::@102->printf_uint]
    // [734] phi printf_uint::format_zero_padding#16 = 1 [phi:main::@102->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [734] phi printf_uint::format_min_length#16 = 2 [phi:main::@102->printf_uint#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uint.format_min_length
    // [734] phi printf_uint::putc#16 = &snputc [phi:main::@102->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [734] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:main::@102->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [734] phi printf_uint::uvalue#16 = printf_uint::uvalue#15 [phi:main::@102->printf_uint#4] -- register_copy 
    jsr printf_uint
    // main::@103
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [152] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [153] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [155] smc_file_size#358 = smc_file_size#0 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_FLASH, info_text)
    // [156] call display_info_smc
    // [745] phi from main::@103 to display_info_smc [phi:main::@103->display_info_smc]
    // [745] phi display_info_smc::info_text#12 = info_text [phi:main::@103->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_smc.info_text
    lda #>@info_text
    sta.z display_info_smc.info_text+1
    // [745] phi smc_file_size#12 = smc_file_size#358 [phi:main::@103->display_info_smc#1] -- register_copy 
    // [745] phi display_info_smc::info_status#12 = STATUS_FLASH [phi:main::@103->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASH
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [157] phi from main::@103 main::@24 main::@25 to main::CLI3 [phi:main::@103/main::@24/main::@25->main::CLI3]
    // [157] phi smc_file_size#202 = smc_file_size#0 [phi:main::@103/main::@24/main::@25->main::CLI3#0] -- register_copy 
    // [157] phi __errno#253 = __errno#18 [phi:main::@103/main::@24/main::@25->main::CLI3#1] -- register_copy 
    jmp CLI3
    // [157] phi from main::@62 to main::CLI3 [phi:main::@62->main::CLI3]
  __b4:
    // [157] phi smc_file_size#202 = 0 [phi:main::@62->main::CLI3#0] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size
    sta smc_file_size+1
    // [157] phi __errno#253 = 0 [phi:main::@62->main::CLI3#1] -- vwsm1=vwsc1 
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
    // [160] phi from main::SEI4 to main::@26 [phi:main::SEI4->main::@26]
    // [160] phi __errno#112 = __errno#253 [phi:main::SEI4->main::@26#0] -- register_copy 
    // [160] phi main::rom_chip1#10 = 0 [phi:main::SEI4->main::@26#1] -- vbum1=vbuc1 
    lda #0
    sta rom_chip1
  // We loop all the possible ROM chip slots on the board and on the extension card,
  // and we check the file contents.
  // Any error identified gets reported and this chip will not be flashed.
  // In case of ROM0.BIN in error, no flashing will be done!
    // main::@26
  __b26:
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
    // main::@64
    // if(!check_smc(STATUS_FLASH) || !check_cx16_rom(STATUS_FLASH))
    // [169] if(0==main::check_smc2_return#0) goto main::@33 -- 0_eq_vbum1_then_la1 
    lda check_smc2_return
    bne !__b33+
    jmp __b33
  !__b33:
    // main::@174
    // [170] if(0==main::check_cx16_rom1_check_rom1_return#0) goto main::@33 -- 0_eq_vbum1_then_la1 
    lda check_cx16_rom1_check_rom1_return
    bne !__b33+
    jmp __b33
  !__b33:
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
    // main::@67
  __b67:
    // if(check_smc(STATUS_FLASH) && check_cx16_rom(STATUS_FLASH) || check_card_roms(STATUS_FLASH))
    // [180] if(0==main::check_smc3_return#0) goto main::@175 -- 0_eq_vbum1_then_la1 
    lda check_smc3_return
    beq __b175
    // main::@176
    // [181] if(0!=main::check_cx16_rom2_check_rom1_return#0) goto main::@6 -- 0_neq_vbum1_then_la1 
    lda check_cx16_rom2_check_rom1_return
    beq !__b6+
    jmp __b6
  !__b6:
    // main::@175
  __b175:
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
    // main::@68
    // if (check_smc(STATUS_FLASH))
    // [186] if(0==main::check_smc4_return#0) goto main::@2 -- 0_eq_vbum1_then_la1 
    bne !__b2+
    jmp __b2
  !__b2:
    // [187] phi from main::@68 to main::@8 [phi:main::@68->main::@8]
    // main::@8
    // smc_read(8, 512)
    // [188] call smc_read
    // [908] phi from main::@8 to smc_read [phi:main::@8->smc_read]
    // [908] phi __errno#35 = __errno#112 [phi:main::@8->smc_read#0] -- register_copy 
    jsr smc_read
    // smc_read(8, 512)
    // [189] smc_read::return#3 = smc_read::return#0
    // main::@134
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
    // [192] phi from main::@134 to main::@9 [phi:main::@134->main::@9]
    // main::@9
    // display_info_line("Press both POWER/RESET buttons on the CX16 board!")
    // [193] call display_info_line
  // Flash the SMC chip.
    // [965] phi from main::@9 to display_info_line [phi:main::@9->display_info_line]
    // [965] phi display_info_line::info_text#19 = main::info_text18 [phi:main::@9->display_info_line#0] -- pbuz1=pbuc1 
    lda #<info_text18
    sta.z display_info_line.info_text
    lda #>info_text18
    sta.z display_info_line.info_text+1
    jsr display_info_line
    // main::@135
    // [194] smc_file_size#359 = smc_file_size#1 -- vwum1=vwum2 
    lda smc_file_size_1
    sta smc_file_size_2
    lda smc_file_size_1+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_FLASHING, "Press POWER/RESET!")
    // [195] call display_info_smc
    // [745] phi from main::@135 to display_info_smc [phi:main::@135->display_info_smc]
    // [745] phi display_info_smc::info_text#12 = main::info_text19 [phi:main::@135->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text19
    sta.z display_info_smc.info_text
    lda #>info_text19
    sta.z display_info_smc.info_text+1
    // [745] phi smc_file_size#12 = smc_file_size#359 [phi:main::@135->display_info_smc#1] -- register_copy 
    // [745] phi display_info_smc::info_status#12 = STATUS_FLASHING [phi:main::@135->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHING
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // main::@136
    // unsigned long flashed_bytes = flash_smc(PROGRESS_X, PROGRESS_Y, PROGRESS_W, smc_file_size, 8, 512, (ram_ptr_t)RAM_BASE)
    // [196] flash_smc::smc_bytes_total#0 = smc_file_size#1 -- vwuz1=vwum2 
    lda smc_file_size_1
    sta.z flash_smc.smc_bytes_total
    lda smc_file_size_1+1
    sta.z flash_smc.smc_bytes_total+1
    // [197] call flash_smc
    // [979] phi from main::@136 to flash_smc [phi:main::@136->flash_smc]
    jsr flash_smc
    // unsigned long flashed_bytes = flash_smc(PROGRESS_X, PROGRESS_Y, PROGRESS_W, smc_file_size, 8, 512, (ram_ptr_t)RAM_BASE)
    // [198] flash_smc::return#5 = flash_smc::return#1
    // main::@137
    // [199] main::flashed_bytes#0 = flash_smc::return#5 -- vdum1=vwum2 
    lda flash_smc.return
    sta flashed_bytes
    lda flash_smc.return+1
    sta flashed_bytes+1
    lda #0
    sta flashed_bytes+2
    sta flashed_bytes+3
    // if(flashed_bytes)
    // [200] if(0!=main::flashed_bytes#0) goto main::@37 -- 0_neq_vdum1_then_la1 
    lda flashed_bytes
    ora flashed_bytes+1
    ora flashed_bytes+2
    ora flashed_bytes+3
    beq !__b37+
    jmp __b37
  !__b37:
    // main::@10
    // [201] smc_file_size#357 = smc_file_size#1 -- vwum1=vwum2 
    lda smc_file_size_1
    sta smc_file_size_2
    lda smc_file_size_1+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_ERROR, "SMC not updated!")
    // [202] call display_info_smc
    // [745] phi from main::@10 to display_info_smc [phi:main::@10->display_info_smc]
    // [745] phi display_info_smc::info_text#12 = main::info_text21 [phi:main::@10->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text21
    sta.z display_info_smc.info_text
    lda #>info_text21
    sta.z display_info_smc.info_text+1
    // [745] phi smc_file_size#12 = smc_file_size#357 [phi:main::@10->display_info_smc#1] -- register_copy 
    // [745] phi display_info_smc::info_status#12 = STATUS_ERROR [phi:main::@10->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [203] phi from main::@10 main::@134 main::@37 main::@68 to main::@2 [phi:main::@10/main::@134/main::@37/main::@68->main::@2]
    // [203] phi __errno#388 = __errno#18 [phi:main::@10/main::@134/main::@37/main::@68->main::@2#0] -- register_copy 
    // main::@2
  __b2:
    // [204] phi from main::@2 to main::@38 [phi:main::@2->main::@38]
    // [204] phi __errno#114 = __errno#388 [phi:main::@2->main::@38#0] -- register_copy 
    // [204] phi main::rom_chip3#10 = 7 [phi:main::@2->main::@38#1] -- vbum1=vbuc1 
    lda #7
    sta rom_chip3
  // Flash the ROM chips. 
  // We loop first all the ROM chips and read the file contents.
  // Then we verify the file contents and flash the ROM only for the differences.
  // If the file contents are the same as the ROM contents, then no flashing is required.
  // IMPORTANT! We start to flash the ROMs on the extension card.
  // The last ROM flashed is the CX16 ROM on the CX16 board!
    // main::@38
  __b38:
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
    // [208] phi from main::CLI5 to main::@70 [phi:main::CLI5->main::@70]
    // main::@70
    // display_progress_clear()
    // [209] call display_progress_clear
    // [676] phi from main::@70 to display_progress_clear [phi:main::@70->display_progress_clear]
    jsr display_progress_clear
    // [210] phi from main::@70 to main::@138 [phi:main::@70->main::@138]
    // main::@138
    // display_info_progress("Update finished ...")
    // [211] call display_info_progress
    // [691] phi from main::@138 to display_info_progress [phi:main::@138->display_info_progress]
    // [691] phi display_info_progress::info_text#14 = main::info_text22 [phi:main::@138->display_info_progress#0] -- pbuz1=pbuc1 
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
    // main::@71
  __b71:
    // if(check_smc(STATUS_SKIP) && check_vera(STATUS_SKIP) && check_roms_all(STATUS_SKIP))
    // [220] if(0==main::check_smc5_return#0) goto main::check_smc7 -- 0_eq_vbum1_then_la1 
    lda check_smc5_return
    beq check_smc7
    // main::@178
    // [221] if(0==main::check_vera1_return#0) goto main::check_smc7 -- 0_eq_vbum1_then_la1 
    lda check_vera1_return
    beq check_smc7
    // main::@177
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
    // main::@75
  __b75:
    // if(check_smc(STATUS_ERROR) || check_vera(STATUS_ERROR) || check_roms(STATUS_ERROR))
    // [231] if(0!=main::check_smc7_return#0) goto main::vera_display_set_border_color2 -- 0_neq_vbum1_then_la1 
    lda check_smc7_return
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::@182
    // [232] if(0!=main::check_vera2_return#0) goto main::vera_display_set_border_color2 -- 0_neq_vbum1_then_la1 
    lda check_vera2_return
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::@181
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
    // main::@77
  __b77:
    // if(check_smc(STATUS_ISSUE) || check_vera(STATUS_ISSUE) || check_roms(STATUS_ISSUE))
    // [242] if(0!=main::check_smc8_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbum1_then_la1 
    lda check_smc8_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::@184
    // [243] if(0!=main::check_vera3_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbum1_then_la1 
    lda check_vera3_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::@183
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
    // main::@79
    // if(check_smc(STATUS_FLASHED))
    // [249] if(0!=main::check_smc9_return#0) goto main::@47 -- 0_neq_vbum1_then_la1 
    beq !__b47+
    jmp __b47
  !__b47:
    // [250] phi from main::@79 to main::@46 [phi:main::@79->main::@46]
    // main::@46
    // display_progress_text(display_debriefing_text_rom, display_debriefing_count_rom)
    // [251] call display_progress_text
    // [875] phi from main::@46 to display_progress_text [phi:main::@46->display_progress_text]
    // [875] phi display_progress_text::text#6 = display_debriefing_text_rom [phi:main::@46->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_debriefing_text_rom
    sta.z display_progress_text.text
    lda #>display_debriefing_text_rom
    sta.z display_progress_text.text+1
    // [875] phi display_progress_text::lines#5 = display_debriefing_count_rom [phi:main::@46->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_debriefing_count_rom
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [252] phi from main::@167 main::@46 main::@74 main::@78 to main::@52 [phi:main::@167/main::@46/main::@74/main::@78->main::@52]
  __b5:
    // [252] phi main::w1#2 = $c8 [phi:main::@167/main::@46/main::@74/main::@78->main::@52#0] -- vbum1=vbuc1 
    lda #$c8
    sta w1
    // main::@52
  __b52:
    // for (unsigned char w=200; w>0; w--)
    // [253] if(main::w1#2>0) goto main::@53 -- vbum1_gt_0_then_la1 
    lda w1
    bne __b53
    // [254] phi from main::@52 to main::@54 [phi:main::@52->main::@54]
    // main::@54
    // system_reset()
    // [255] call system_reset
    // [1141] phi from main::@54 to system_reset [phi:main::@54->system_reset]
    jsr system_reset
    // main::@return
    // }
    // [256] return 
    rts
    // [257] phi from main::@52 to main::@53 [phi:main::@52->main::@53]
    // main::@53
  __b53:
    // wait_moment()
    // [258] call wait_moment
    // [1146] phi from main::@53 to wait_moment [phi:main::@53->wait_moment]
    jsr wait_moment
    // [259] phi from main::@53 to main::@168 [phi:main::@53->main::@168]
    // main::@168
    // sprintf(info_text, "Your CX16 will reset (%03u) ...", w)
    // [260] call snprintf_init
    jsr snprintf_init
    // [261] phi from main::@168 to main::@169 [phi:main::@168->main::@169]
    // main::@169
    // sprintf(info_text, "Your CX16 will reset (%03u) ...", w)
    // [262] call printf_str
    // [725] phi from main::@169 to printf_str [phi:main::@169->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:main::@169->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = main::s21 [phi:main::@169->printf_str#1] -- pbuz1=pbuc1 
    lda #<s21
    sta.z printf_str.s
    lda #>s21
    sta.z printf_str.s+1
    jsr printf_str
    // main::@170
    // sprintf(info_text, "Your CX16 will reset (%03u) ...", w)
    // [263] printf_uchar::uvalue#10 = main::w1#2 -- vbum1=vbum2 
    lda w1
    sta printf_uchar.uvalue
    // [264] call printf_uchar
    // [1151] phi from main::@170 to printf_uchar [phi:main::@170->printf_uchar]
    // [1151] phi printf_uchar::format_zero_padding#11 = 1 [phi:main::@170->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1151] phi printf_uchar::format_min_length#11 = 3 [phi:main::@170->printf_uchar#1] -- vbum1=vbuc1 
    lda #3
    sta printf_uchar.format_min_length
    // [1151] phi printf_uchar::putc#11 = &snputc [phi:main::@170->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1151] phi printf_uchar::format_radix#11 = DECIMAL [phi:main::@170->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1151] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#10 [phi:main::@170->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [265] phi from main::@170 to main::@171 [phi:main::@170->main::@171]
    // main::@171
    // sprintf(info_text, "Your CX16 will reset (%03u) ...", w)
    // [266] call printf_str
    // [725] phi from main::@171 to printf_str [phi:main::@171->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:main::@171->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = main::s19 [phi:main::@171->printf_str#1] -- pbuz1=pbuc1 
    lda #<s19
    sta.z printf_str.s
    lda #>s19
    sta.z printf_str.s+1
    jsr printf_str
    // main::@172
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
    // [965] phi from main::@172 to display_info_line [phi:main::@172->display_info_line]
    // [965] phi display_info_line::info_text#19 = info_text [phi:main::@172->display_info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_line.info_text
    lda #>@info_text
    sta.z display_info_line.info_text+1
    jsr display_info_line
    // main::@173
    // for (unsigned char w=200; w>0; w--)
    // [271] main::w1#1 = -- main::w1#2 -- vbum1=_dec_vbum1 
    dec w1
    // [252] phi from main::@173 to main::@52 [phi:main::@173->main::@52]
    // [252] phi main::w1#2 = main::w1#1 [phi:main::@173->main::@52#0] -- register_copy 
    jmp __b52
    // [272] phi from main::@79 to main::@47 [phi:main::@79->main::@47]
    // main::@47
  __b47:
    // display_progress_text(display_debriefing_text_smc, display_debriefing_count_smc)
    // [273] call display_progress_text
    // [875] phi from main::@47 to display_progress_text [phi:main::@47->display_progress_text]
    // [875] phi display_progress_text::text#6 = display_debriefing_text_smc [phi:main::@47->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_debriefing_text_smc
    sta.z display_progress_text.text
    lda #>display_debriefing_text_smc
    sta.z display_progress_text.text+1
    // [875] phi display_progress_text::lines#5 = display_debriefing_count_smc [phi:main::@47->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_debriefing_count_smc
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [274] phi from main::@47 to main::@48 [phi:main::@47->main::@48]
    // [274] phi main::w#2 = $80 [phi:main::@47->main::@48#0] -- vbum1=vbuc1 
    lda #$80
    sta w
    // main::@48
  __b48:
    // for (unsigned char w=128; w>0; w--)
    // [275] if(main::w#2>0) goto main::@49 -- vbum1_gt_0_then_la1 
    lda w
    bne __b49
    // [276] phi from main::@48 to main::@50 [phi:main::@48->main::@50]
    // main::@50
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [277] call snprintf_init
    jsr snprintf_init
    // [278] phi from main::@50 to main::@165 [phi:main::@50->main::@165]
    // main::@165
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [279] call printf_str
    // [725] phi from main::@165 to printf_str [phi:main::@165->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:main::@165->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = main::s20 [phi:main::@165->printf_str#1] -- pbuz1=pbuc1 
    lda #<s20
    sta.z printf_str.s
    lda #>s20
    sta.z printf_str.s+1
    jsr printf_str
    // main::@166
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [280] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [281] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_line(info_text)
    // [283] call display_info_line
    // [965] phi from main::@166 to display_info_line [phi:main::@166->display_info_line]
    // [965] phi display_info_line::info_text#19 = info_text [phi:main::@166->display_info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_line.info_text
    lda #>@info_text
    sta.z display_info_line.info_text+1
    jsr display_info_line
    // [284] phi from main::@166 to main::@167 [phi:main::@166->main::@167]
    // main::@167
    // smc_reset()
    // [285] call smc_reset
    // [1162] phi from main::@167 to smc_reset [phi:main::@167->smc_reset]
    jsr smc_reset
    jmp __b5
    // [286] phi from main::@48 to main::@49 [phi:main::@48->main::@49]
    // main::@49
  __b49:
    // wait_moment()
    // [287] call wait_moment
    // [1146] phi from main::@49 to wait_moment [phi:main::@49->wait_moment]
    jsr wait_moment
    // [288] phi from main::@49 to main::@159 [phi:main::@49->main::@159]
    // main::@159
    // sprintf(info_text, "Please read carefully the below (%u) ...", w)
    // [289] call snprintf_init
    jsr snprintf_init
    // [290] phi from main::@159 to main::@160 [phi:main::@159->main::@160]
    // main::@160
    // sprintf(info_text, "Please read carefully the below (%u) ...", w)
    // [291] call printf_str
    // [725] phi from main::@160 to printf_str [phi:main::@160->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:main::@160->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = main::s18 [phi:main::@160->printf_str#1] -- pbuz1=pbuc1 
    lda #<s18
    sta.z printf_str.s
    lda #>s18
    sta.z printf_str.s+1
    jsr printf_str
    // main::@161
    // sprintf(info_text, "Please read carefully the below (%u) ...", w)
    // [292] printf_uchar::uvalue#9 = main::w#2 -- vbum1=vbum2 
    lda w
    sta printf_uchar.uvalue
    // [293] call printf_uchar
    // [1151] phi from main::@161 to printf_uchar [phi:main::@161->printf_uchar]
    // [1151] phi printf_uchar::format_zero_padding#11 = 0 [phi:main::@161->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1151] phi printf_uchar::format_min_length#11 = 0 [phi:main::@161->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1151] phi printf_uchar::putc#11 = &snputc [phi:main::@161->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1151] phi printf_uchar::format_radix#11 = DECIMAL [phi:main::@161->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1151] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#9 [phi:main::@161->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [294] phi from main::@161 to main::@162 [phi:main::@161->main::@162]
    // main::@162
    // sprintf(info_text, "Please read carefully the below (%u) ...", w)
    // [295] call printf_str
    // [725] phi from main::@162 to printf_str [phi:main::@162->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:main::@162->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = main::s19 [phi:main::@162->printf_str#1] -- pbuz1=pbuc1 
    lda #<s19
    sta.z printf_str.s
    lda #>s19
    sta.z printf_str.s+1
    jsr printf_str
    // main::@163
    // sprintf(info_text, "Please read carefully the below (%u) ...", w)
    // [296] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [297] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_line(info_text)
    // [299] call display_info_line
    // [965] phi from main::@163 to display_info_line [phi:main::@163->display_info_line]
    // [965] phi display_info_line::info_text#19 = info_text [phi:main::@163->display_info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_line.info_text
    lda #>@info_text
    sta.z display_info_line.info_text+1
    jsr display_info_line
    // main::@164
    // for (unsigned char w=128; w>0; w--)
    // [300] main::w#1 = -- main::w#2 -- vbum1=_dec_vbum1 
    dec w
    // [274] phi from main::@164 to main::@48 [phi:main::@164->main::@48]
    // [274] phi main::w#2 = main::w#1 [phi:main::@164->main::@48#0] -- register_copy 
    jmp __b48
    // main::vera_display_set_border_color3
  vera_display_set_border_color3:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [301] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [302] *VERA_DC_BORDER = YELLOW -- _deref_pbuc1=vbuc2 
    lda #YELLOW
    sta VERA_DC_BORDER
    // [303] phi from main::vera_display_set_border_color3 to main::@78 [phi:main::vera_display_set_border_color3->main::@78]
    // main::@78
    // display_info_progress("Update issues, your CX16 is not updated!")
    // [304] call display_info_progress
    // [691] phi from main::@78 to display_info_progress [phi:main::@78->display_info_progress]
    // [691] phi display_info_progress::info_text#14 = main::info_text31 [phi:main::@78->display_info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text31
    sta.z display_info_progress.info_text
    lda #>info_text31
    sta.z display_info_progress.info_text+1
    jsr display_info_progress
    jmp __b5
    // main::check_roms2_check_rom1
  check_roms2_check_rom1:
    // status_rom[rom_chip] == status
    // [305] main::check_roms2_check_rom1_$0 = status_rom[main::check_roms2_rom_chip#2] == STATUS_ISSUE -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_ISSUE
    ldy check_roms2_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_roms2_check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [306] main::check_roms2_check_rom1_return#0 = (char)main::check_roms2_check_rom1_$0 -- vbum1=vbuz2 
    sta check_roms2_check_rom1_return
    // main::check_roms2_@11
    // if(check_rom(rom_chip, status) == status)
    // [307] if(main::check_roms2_check_rom1_return#0!=STATUS_ISSUE) goto main::check_roms2_@4 -- vbum1_neq_vbuc1_then_la1 
    lda #STATUS_ISSUE
    cmp check_roms2_check_rom1_return
    bne check_roms2___b4
    // [241] phi from main::check_roms2_@11 to main::check_roms2_@return [phi:main::check_roms2_@11->main::check_roms2_@return]
    // [241] phi main::check_roms2_return#2 = STATUS_ISSUE [phi:main::check_roms2_@11->main::check_roms2_@return#0] -- vbum1=vbuc1 
    sta check_roms2_return
    jmp __b77
    // main::check_roms2_@4
  check_roms2___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [308] main::check_roms2_rom_chip#1 = ++ main::check_roms2_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_roms2_rom_chip
    // [239] phi from main::check_roms2_@4 to main::check_roms2_@1 [phi:main::check_roms2_@4->main::check_roms2_@1]
    // [239] phi main::check_roms2_rom_chip#2 = main::check_roms2_rom_chip#1 [phi:main::check_roms2_@4->main::check_roms2_@1#0] -- register_copy 
    jmp check_roms2___b1
    // main::vera_display_set_border_color2
  vera_display_set_border_color2:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [309] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [310] *VERA_DC_BORDER = RED -- _deref_pbuc1=vbuc2 
    lda #RED
    sta VERA_DC_BORDER
    // [311] phi from main::vera_display_set_border_color2 to main::@76 [phi:main::vera_display_set_border_color2->main::@76]
    // main::@76
    // display_info_progress("Update Failure! Your CX16 may be bricked!")
    // [312] call display_info_progress
    // [691] phi from main::@76 to display_info_progress [phi:main::@76->display_info_progress]
    // [691] phi display_info_progress::info_text#14 = main::info_text29 [phi:main::@76->display_info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text29
    sta.z display_info_progress.info_text
    lda #>info_text29
    sta.z display_info_progress.info_text+1
    jsr display_info_progress
    // [313] phi from main::@76 to main::@158 [phi:main::@76->main::@158]
    // main::@158
    // display_info_line("Take a foto of this screen. And shut down power ...")
    // [314] call display_info_line
    // [965] phi from main::@158 to display_info_line [phi:main::@158->display_info_line]
    // [965] phi display_info_line::info_text#19 = main::info_text30 [phi:main::@158->display_info_line#0] -- pbuz1=pbuc1 
    lda #<info_text30
    sta.z display_info_line.info_text
    lda #>info_text30
    sta.z display_info_line.info_text+1
    jsr display_info_line
    // [315] phi from main::@158 main::@51 to main::@51 [phi:main::@158/main::@51->main::@51]
    // main::@51
  __b51:
    jmp __b51
    // main::check_roms1_check_rom1
  check_roms1_check_rom1:
    // status_rom[rom_chip] == status
    // [316] main::check_roms1_check_rom1_$0 = status_rom[main::check_roms1_rom_chip#2] == STATUS_ERROR -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_ERROR
    ldy check_roms1_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_roms1_check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [317] main::check_roms1_check_rom1_return#0 = (char)main::check_roms1_check_rom1_$0 -- vbum1=vbuz2 
    sta check_roms1_check_rom1_return
    // main::check_roms1_@11
    // if(check_rom(rom_chip, status) == status)
    // [318] if(main::check_roms1_check_rom1_return#0!=STATUS_ERROR) goto main::check_roms1_@4 -- vbum1_neq_vbuc1_then_la1 
    lda #STATUS_ERROR
    cmp check_roms1_check_rom1_return
    bne check_roms1___b4
    // [230] phi from main::check_roms1_@11 to main::check_roms1_@return [phi:main::check_roms1_@11->main::check_roms1_@return]
    // [230] phi main::check_roms1_return#2 = STATUS_ERROR [phi:main::check_roms1_@11->main::check_roms1_@return#0] -- vbum1=vbuc1 
    sta check_roms1_return
    jmp __b75
    // main::check_roms1_@4
  check_roms1___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [319] main::check_roms1_rom_chip#1 = ++ main::check_roms1_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_roms1_rom_chip
    // [228] phi from main::check_roms1_@4 to main::check_roms1_@1 [phi:main::check_roms1_@4->main::check_roms1_@1]
    // [228] phi main::check_roms1_rom_chip#2 = main::check_roms1_rom_chip#1 [phi:main::check_roms1_@4->main::check_roms1_@1#0] -- register_copy 
    jmp check_roms1___b1
    // main::vera_display_set_border_color1
  vera_display_set_border_color1:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [320] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [321] *VERA_DC_BORDER = BLACK -- _deref_pbuc1=vbuc2 
    lda #BLACK
    sta VERA_DC_BORDER
    // [322] phi from main::vera_display_set_border_color1 to main::@74 [phi:main::vera_display_set_border_color1->main::@74]
    // main::@74
    // display_info_progress("The update has been cancelled!")
    // [323] call display_info_progress
    // [691] phi from main::@74 to display_info_progress [phi:main::@74->display_info_progress]
    // [691] phi display_info_progress::info_text#14 = main::info_text28 [phi:main::@74->display_info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text28
    sta.z display_info_progress.info_text
    lda #>info_text28
    sta.z display_info_progress.info_text+1
    jsr display_info_progress
    jmp __b5
    // main::check_roms_all1_check_rom1
  check_roms_all1_check_rom1:
    // status_rom[rom_chip] == status
    // [324] main::check_roms_all1_check_rom1_$0 = status_rom[main::check_roms_all1_rom_chip#2] == STATUS_SKIP -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_SKIP
    ldy check_roms_all1_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_roms_all1_check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [325] main::check_roms_all1_check_rom1_return#0 = (char)main::check_roms_all1_check_rom1_$0 -- vbum1=vbuz2 
    sta check_roms_all1_check_rom1_return
    // main::check_roms_all1_@11
    // if(check_rom(rom_chip, status) != status)
    // [326] if(main::check_roms_all1_check_rom1_return#0==STATUS_SKIP) goto main::check_roms_all1_@4 -- vbum1_eq_vbuc1_then_la1 
    lda #STATUS_SKIP
    cmp check_roms_all1_check_rom1_return
    beq check_roms_all1___b4
    // [219] phi from main::check_roms_all1_@11 to main::check_roms_all1_@return [phi:main::check_roms_all1_@11->main::check_roms_all1_@return]
    // [219] phi main::check_roms_all1_return#2 = 0 [phi:main::check_roms_all1_@11->main::check_roms_all1_@return#0] -- vbum1=vbuc1 
    lda #0
    sta check_roms_all1_return
    jmp __b71
    // main::check_roms_all1_@4
  check_roms_all1___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [327] main::check_roms_all1_rom_chip#1 = ++ main::check_roms_all1_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_roms_all1_rom_chip
    // [217] phi from main::check_roms_all1_@4 to main::check_roms_all1_@1 [phi:main::check_roms_all1_@4->main::check_roms_all1_@1]
    // [217] phi main::check_roms_all1_rom_chip#2 = main::check_roms_all1_rom_chip#1 [phi:main::check_roms_all1_@4->main::check_roms_all1_@1#0] -- register_copy 
    jmp check_roms_all1___b1
    // main::check_rom1
  check_rom1:
    // status_rom[rom_chip] == status
    // [328] main::check_rom1_$0 = status_rom[main::rom_chip3#10] == STATUS_FLASH -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_FLASH
    ldy rom_chip3
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [329] main::check_rom1_return#0 = (char)main::check_rom1_$0 -- vbum1=vbuz2 
    sta check_rom1_return
    // main::@69
    // if(check_rom(rom_chip, STATUS_FLASH))
    // [330] if(0==main::check_rom1_return#0) goto main::@39 -- 0_eq_vbum1_then_la1 
    beq __b39
    // main::check_smc6
    // status_smc == status
    // [331] main::check_smc6_$0 = status_smc#0 == STATUS_FLASHED -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASHED
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_smc6_main__0
    // return (unsigned char)(status_smc == status);
    // [332] main::check_smc6_return#0 = (char)main::check_smc6_$0 -- vbum1=vbuz2 
    sta check_smc6_return
    // main::@72
    // if((rom_chip == 0 && check_smc(STATUS_FLASHED)) || (rom_chip != 0))
    // [333] if(main::rom_chip3#10!=0) goto main::@179 -- vbum1_neq_0_then_la1 
    // IMPORTANT! We only flash the CX16 ROM chip if the SMC got flashed succesfully!
    lda rom_chip3
    bne __b179
    // main::@180
    // [334] if(0!=main::check_smc6_return#0) goto main::bank_set_brom5 -- 0_neq_vbum1_then_la1 
    lda check_smc6_return
    bne bank_set_brom5
    // main::@179
  __b179:
    // [335] if(main::rom_chip3#10!=0) goto main::bank_set_brom5 -- vbum1_neq_0_then_la1 
    lda rom_chip3
    bne bank_set_brom5
    // main::@45
    // display_info_rom(rom_chip, STATUS_ISSUE, "Update SMC failed!")
    // [336] display_info_rom::rom_chip#10 = main::rom_chip3#10 -- vbuz1=vbum2 
    sta.z display_info_rom.rom_chip
    // [337] call display_info_rom
    // [1171] phi from main::@45 to display_info_rom [phi:main::@45->display_info_rom]
    // [1171] phi display_info_rom::info_text#16 = main::info_text23 [phi:main::@45->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text23
    sta.z display_info_rom.info_text
    lda #>info_text23
    sta.z display_info_rom.info_text+1
    // [1171] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#10 [phi:main::@45->display_info_rom#1] -- register_copy 
    // [1171] phi display_info_rom::info_status#16 = STATUS_ISSUE [phi:main::@45->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // [338] phi from main::@146 main::@157 main::@40 main::@44 main::@45 main::@69 to main::@39 [phi:main::@146/main::@157/main::@40/main::@44/main::@45/main::@69->main::@39]
    // [338] phi __errno#389 = __errno#18 [phi:main::@146/main::@157/main::@40/main::@44/main::@45/main::@69->main::@39#0] -- register_copy 
    // main::@39
  __b39:
    // for(unsigned char rom_chip = 7; rom_chip != 255; rom_chip--)
    // [339] main::rom_chip3#1 = -- main::rom_chip3#10 -- vbum1=_dec_vbum1 
    dec rom_chip3
    // [204] phi from main::@39 to main::@38 [phi:main::@39->main::@38]
    // [204] phi __errno#114 = __errno#389 [phi:main::@39->main::@38#0] -- register_copy 
    // [204] phi main::rom_chip3#10 = main::rom_chip3#1 [phi:main::@39->main::@38#1] -- register_copy 
    jmp __b38
    // main::bank_set_brom5
  bank_set_brom5:
    // BROM = bank
    // [340] BROM = main::bank_set_brom5_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom5_bank
    sta.z BROM
    // [341] phi from main::bank_set_brom5 to main::@73 [phi:main::bank_set_brom5->main::@73]
    // main::@73
    // display_progress_clear()
    // [342] call display_progress_clear
    // [676] phi from main::@73 to display_progress_clear [phi:main::@73->display_progress_clear]
    jsr display_progress_clear
    // main::@139
    // unsigned char rom_bank = rom_chip * 32
    // [343] main::rom_bank1#0 = main::rom_chip3#10 << 5 -- vbum1=vbum2_rol_5 
    lda rom_chip3
    asl
    asl
    asl
    asl
    asl
    sta rom_bank1
    // unsigned char* file = rom_file(rom_chip)
    // [344] rom_file::rom_chip#1 = main::rom_chip3#10 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z rom_file.rom_chip
    // [345] call rom_file
    // [1216] phi from main::@139 to rom_file [phi:main::@139->rom_file]
    // [1216] phi rom_file::rom_chip#2 = rom_file::rom_chip#1 [phi:main::@139->rom_file#0] -- register_copy 
    jsr rom_file
    // unsigned char* file = rom_file(rom_chip)
    // [346] rom_file::return#5 = rom_file::return#2
    // main::@140
    // [347] main::file1#0 = rom_file::return#5
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [348] call snprintf_init
    jsr snprintf_init
    // [349] phi from main::@140 to main::@141 [phi:main::@140->main::@141]
    // main::@141
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [350] call printf_str
    // [725] phi from main::@141 to printf_str [phi:main::@141->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:main::@141->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = s14 [phi:main::@141->printf_str#1] -- pbuz1=pbuc1 
    lda #<s14
    sta.z printf_str.s
    lda #>s14
    sta.z printf_str.s+1
    jsr printf_str
    // main::@142
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [351] printf_string::str#17 = main::file1#0 -- pbuz1=pbuz2 
    lda.z file1
    sta.z printf_string.str
    lda.z file1+1
    sta.z printf_string.str+1
    // [352] call printf_string
    // [1222] phi from main::@142 to printf_string [phi:main::@142->printf_string]
    // [1222] phi printf_string::putc#18 = &snputc [phi:main::@142->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1222] phi printf_string::str#18 = printf_string::str#17 [phi:main::@142->printf_string#1] -- register_copy 
    // [1222] phi printf_string::format_justify_left#18 = 0 [phi:main::@142->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1222] phi printf_string::format_min_length#18 = 0 [phi:main::@142->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [353] phi from main::@142 to main::@143 [phi:main::@142->main::@143]
    // main::@143
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [354] call printf_str
    // [725] phi from main::@143 to printf_str [phi:main::@143->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:main::@143->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = main::s7 [phi:main::@143->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@144
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [355] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [356] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_progress(info_text)
    // [358] call display_info_progress
    // [691] phi from main::@144 to display_info_progress [phi:main::@144->display_info_progress]
    // [691] phi display_info_progress::info_text#14 = info_text [phi:main::@144->display_info_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_progress.info_text
    lda #>@info_text
    sta.z display_info_progress.info_text+1
    jsr display_info_progress
    // main::@145
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_READING, rom_bank, rom_sizes[rom_chip])
    // [359] main::$186 = main::rom_chip3#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip3
    asl
    asl
    sta.z main__186
    // [360] rom_read::file#1 = main::file1#0 -- pbuz1=pbuz2 
    lda.z file1
    sta.z rom_read.file
    lda.z file1+1
    sta.z rom_read.file+1
    // [361] rom_read::brom_bank_start#2 = main::rom_bank1#0 -- vbuz1=vbum2 
    lda rom_bank1
    sta.z rom_read.brom_bank_start
    // [362] rom_read::rom_size#1 = rom_sizes[main::$186] -- vduz1=pduc1_derefidx_vbuz2 
    ldy.z main__186
    lda rom_sizes,y
    sta.z rom_read.rom_size
    lda rom_sizes+1,y
    sta.z rom_read.rom_size+1
    lda rom_sizes+2,y
    sta.z rom_read.rom_size+2
    lda rom_sizes+3,y
    sta.z rom_read.rom_size+3
    // [363] call rom_read
    // [1247] phi from main::@145 to rom_read [phi:main::@145->rom_read]
    // [1247] phi rom_read::rom_size#12 = rom_read::rom_size#1 [phi:main::@145->rom_read#0] -- register_copy 
    // [1247] phi __errno#106 = __errno#114 [phi:main::@145->rom_read#1] -- register_copy 
    // [1247] phi rom_read::file#11 = rom_read::file#1 [phi:main::@145->rom_read#2] -- register_copy 
    // [1247] phi rom_read::brom_bank_start#21 = rom_read::brom_bank_start#2 [phi:main::@145->rom_read#3] -- register_copy 
    jsr rom_read
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_READING, rom_bank, rom_sizes[rom_chip])
    // [364] rom_read::return#3 = rom_read::return#0
    // main::@146
    // [365] main::rom_bytes_read1#0 = rom_read::return#3
    // if(rom_bytes_read)
    // [366] if(0==main::rom_bytes_read1#0) goto main::@39 -- 0_eq_vdum1_then_la1 
    lda rom_bytes_read1
    ora rom_bytes_read1+1
    ora rom_bytes_read1+2
    ora rom_bytes_read1+3
    bne !__b39+
    jmp __b39
  !__b39:
    // [367] phi from main::@146 to main::@42 [phi:main::@146->main::@42]
    // main::@42
    // display_info_progress("Comparing ... (.) same, (*) different.")
    // [368] call display_info_progress
  // Now we compare the RAM with the actual ROM contents.
    // [691] phi from main::@42 to display_info_progress [phi:main::@42->display_info_progress]
    // [691] phi display_info_progress::info_text#14 = main::info_text24 [phi:main::@42->display_info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text24
    sta.z display_info_progress.info_text
    lda #>info_text24
    sta.z display_info_progress.info_text+1
    jsr display_info_progress
    // main::@147
    // display_info_rom(rom_chip, STATUS_COMPARING, "")
    // [369] display_info_rom::rom_chip#11 = main::rom_chip3#10 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z display_info_rom.rom_chip
    // [370] call display_info_rom
    // [1171] phi from main::@147 to display_info_rom [phi:main::@147->display_info_rom]
    // [1171] phi display_info_rom::info_text#16 = info_text5 [phi:main::@147->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z display_info_rom.info_text
    lda #>info_text5
    sta.z display_info_rom.info_text+1
    // [1171] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#11 [phi:main::@147->display_info_rom#1] -- register_copy 
    // [1171] phi display_info_rom::info_status#16 = STATUS_COMPARING [phi:main::@147->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_COMPARING
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // main::@148
    // unsigned long rom_differences = rom_verify(
    //                         rom_chip, rom_bank, file_sizes[rom_chip])
    // [371] rom_verify::rom_chip#0 = main::rom_chip3#10 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z rom_verify.rom_chip
    // [372] rom_verify::rom_bank_start#0 = main::rom_bank1#0 -- vbuz1=vbum2 
    lda rom_bank1
    sta.z rom_verify.rom_bank_start
    // [373] rom_verify::file_size#0 = file_sizes[main::$186] -- vduz1=pduc1_derefidx_vbuz2 
    ldy.z main__186
    lda file_sizes,y
    sta.z rom_verify.file_size
    lda file_sizes+1,y
    sta.z rom_verify.file_size+1
    lda file_sizes+2,y
    sta.z rom_verify.file_size+2
    lda file_sizes+3,y
    sta.z rom_verify.file_size+3
    // [374] call rom_verify
    // Verify the ROM...
    jsr rom_verify
    // [375] rom_verify::return#2 = rom_verify::rom_different_bytes#11
    // main::@149
    // [376] main::rom_differences#0 = rom_verify::return#2 -- vdum1=vdum2 
    lda rom_verify.return
    sta rom_differences
    lda rom_verify.return+1
    sta rom_differences+1
    lda rom_verify.return+2
    sta rom_differences+2
    lda rom_verify.return+3
    sta rom_differences+3
    // if (!rom_differences)
    // [377] if(0==main::rom_differences#0) goto main::@40 -- 0_eq_vdum1_then_la1 
    lda rom_differences
    ora rom_differences+1
    ora rom_differences+2
    ora rom_differences+3
    bne !__b40+
    jmp __b40
  !__b40:
    // [378] phi from main::@149 to main::@43 [phi:main::@149->main::@43]
    // main::@43
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [379] call snprintf_init
    jsr snprintf_init
    // main::@150
    // [380] printf_ulong::uvalue#9 = main::rom_differences#0
    // [381] call printf_ulong
    // [1397] phi from main::@150 to printf_ulong [phi:main::@150->printf_ulong]
    // [1397] phi printf_ulong::format_zero_padding#11 = 1 [phi:main::@150->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1397] phi printf_ulong::format_min_length#11 = 5 [phi:main::@150->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1397] phi printf_ulong::putc#11 = &snputc [phi:main::@150->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1397] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:main::@150->printf_ulong#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1397] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#9 [phi:main::@150->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [382] phi from main::@150 to main::@151 [phi:main::@150->main::@151]
    // main::@151
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [383] call printf_str
    // [725] phi from main::@151 to printf_str [phi:main::@151->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:main::@151->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = main::s16 [phi:main::@151->printf_str#1] -- pbuz1=pbuc1 
    lda #<s16
    sta.z printf_str.s
    lda #>s16
    sta.z printf_str.s+1
    jsr printf_str
    // main::@152
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [384] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [385] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_FLASH, info_text)
    // [387] display_info_rom::rom_chip#13 = main::rom_chip3#10 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z display_info_rom.rom_chip
    // [388] call display_info_rom
    // [1171] phi from main::@152 to display_info_rom [phi:main::@152->display_info_rom]
    // [1171] phi display_info_rom::info_text#16 = info_text [phi:main::@152->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1171] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#13 [phi:main::@152->display_info_rom#1] -- register_copy 
    // [1171] phi display_info_rom::info_status#16 = STATUS_FLASH [phi:main::@152->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASH
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // main::@153
    // unsigned long rom_flash_errors = rom_flash(
    //                             rom_chip, rom_bank, file_sizes[rom_chip])
    // [389] rom_flash::rom_chip#0 = main::rom_chip3#10 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z rom_flash.rom_chip
    // [390] rom_flash::rom_bank_start#0 = main::rom_bank1#0 -- vbuz1=vbum2 
    lda rom_bank1
    sta.z rom_flash.rom_bank_start
    // [391] rom_flash::file_size#0 = file_sizes[main::$186] -- vduz1=pduc1_derefidx_vbuz2 
    ldy.z main__186
    lda file_sizes,y
    sta.z rom_flash.file_size
    lda file_sizes+1,y
    sta.z rom_flash.file_size+1
    lda file_sizes+2,y
    sta.z rom_flash.file_size+2
    lda file_sizes+3,y
    sta.z rom_flash.file_size+3
    // [392] call rom_flash
    // [1408] phi from main::@153 to rom_flash [phi:main::@153->rom_flash]
    jsr rom_flash
    // unsigned long rom_flash_errors = rom_flash(
    //                             rom_chip, rom_bank, file_sizes[rom_chip])
    // [393] rom_flash::return#2 = rom_flash::flash_errors#10
    // main::@154
    // [394] main::rom_flash_errors#0 = rom_flash::return#2 -- vdum1=vdum2 
    lda rom_flash.return
    sta rom_flash_errors
    lda rom_flash.return+1
    sta rom_flash_errors+1
    lda rom_flash.return+2
    sta rom_flash_errors+2
    lda rom_flash.return+3
    sta rom_flash_errors+3
    // if(rom_flash_errors)
    // [395] if(0!=main::rom_flash_errors#0) goto main::@41 -- 0_neq_vdum1_then_la1 
    lda rom_flash_errors
    ora rom_flash_errors+1
    ora rom_flash_errors+2
    ora rom_flash_errors+3
    bne __b41
    // main::@44
    // display_info_rom(rom_chip, STATUS_FLASHED, "OK!")
    // [396] display_info_rom::rom_chip#15 = main::rom_chip3#10 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z display_info_rom.rom_chip
    // [397] call display_info_rom
    // [1171] phi from main::@44 to display_info_rom [phi:main::@44->display_info_rom]
    // [1171] phi display_info_rom::info_text#16 = main::info_text27 [phi:main::@44->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text27
    sta.z display_info_rom.info_text
    lda #>info_text27
    sta.z display_info_rom.info_text+1
    // [1171] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#15 [phi:main::@44->display_info_rom#1] -- register_copy 
    // [1171] phi display_info_rom::info_status#16 = STATUS_FLASHED [phi:main::@44->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHED
    sta.z display_info_rom.info_status
    jsr display_info_rom
    jmp __b39
    // [398] phi from main::@154 to main::@41 [phi:main::@154->main::@41]
    // main::@41
  __b41:
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [399] call snprintf_init
    jsr snprintf_init
    // main::@155
    // [400] printf_ulong::uvalue#10 = main::rom_flash_errors#0 -- vdum1=vdum2 
    lda rom_flash_errors
    sta printf_ulong.uvalue
    lda rom_flash_errors+1
    sta printf_ulong.uvalue+1
    lda rom_flash_errors+2
    sta printf_ulong.uvalue+2
    lda rom_flash_errors+3
    sta printf_ulong.uvalue+3
    // [401] call printf_ulong
    // [1397] phi from main::@155 to printf_ulong [phi:main::@155->printf_ulong]
    // [1397] phi printf_ulong::format_zero_padding#11 = 0 [phi:main::@155->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1397] phi printf_ulong::format_min_length#11 = 0 [phi:main::@155->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1397] phi printf_ulong::putc#11 = &snputc [phi:main::@155->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1397] phi printf_ulong::format_radix#11 = DECIMAL [phi:main::@155->printf_ulong#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1397] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#10 [phi:main::@155->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [402] phi from main::@155 to main::@156 [phi:main::@155->main::@156]
    // main::@156
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [403] call printf_str
    // [725] phi from main::@156 to printf_str [phi:main::@156->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:main::@156->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = main::s17 [phi:main::@156->printf_str#1] -- pbuz1=pbuc1 
    lda #<s17
    sta.z printf_str.s
    lda #>s17
    sta.z printf_str.s+1
    jsr printf_str
    // main::@157
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [404] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [405] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_ERROR, info_text)
    // [407] display_info_rom::rom_chip#14 = main::rom_chip3#10 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z display_info_rom.rom_chip
    // [408] call display_info_rom
    // [1171] phi from main::@157 to display_info_rom [phi:main::@157->display_info_rom]
    // [1171] phi display_info_rom::info_text#16 = info_text [phi:main::@157->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1171] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#14 [phi:main::@157->display_info_rom#1] -- register_copy 
    // [1171] phi display_info_rom::info_status#16 = STATUS_ERROR [phi:main::@157->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_rom.info_status
    jsr display_info_rom
    jmp __b39
    // main::@40
  __b40:
    // display_info_rom(rom_chip, STATUS_FLASHED, "No update required")
    // [409] display_info_rom::rom_chip#12 = main::rom_chip3#10 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z display_info_rom.rom_chip
    // [410] call display_info_rom
    // [1171] phi from main::@40 to display_info_rom [phi:main::@40->display_info_rom]
    // [1171] phi display_info_rom::info_text#16 = main::info_text26 [phi:main::@40->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text26
    sta.z display_info_rom.info_text
    lda #>info_text26
    sta.z display_info_rom.info_text+1
    // [1171] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#12 [phi:main::@40->display_info_rom#1] -- register_copy 
    // [1171] phi display_info_rom::info_status#16 = STATUS_FLASHED [phi:main::@40->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHED
    sta.z display_info_rom.info_status
    jsr display_info_rom
    jmp __b39
    // main::@37
  __b37:
    // [411] smc_file_size#363 = smc_file_size#1 -- vwum1=vwum2 
    lda smc_file_size_1
    sta smc_file_size_2
    lda smc_file_size_1+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_FLASHED, "")
    // [412] call display_info_smc
    // [745] phi from main::@37 to display_info_smc [phi:main::@37->display_info_smc]
    // [745] phi display_info_smc::info_text#12 = info_text5 [phi:main::@37->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z display_info_smc.info_text
    lda #>info_text5
    sta.z display_info_smc.info_text+1
    // [745] phi smc_file_size#12 = smc_file_size#363 [phi:main::@37->display_info_smc#1] -- register_copy 
    // [745] phi display_info_smc::info_status#12 = STATUS_FLASHED [phi:main::@37->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHED
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp __b2
    // [413] phi from main::@175 main::@176 to main::@6 [phi:main::@175/main::@176->main::@6]
    // main::@6
  __b6:
    // display_info_progress("Chipsets have been detected and update files validated!")
    // [414] call display_info_progress
    // [691] phi from main::@6 to display_info_progress [phi:main::@6->display_info_progress]
    // [691] phi display_info_progress::info_text#14 = main::info_text12 [phi:main::@6->display_info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text12
    sta.z display_info_progress.info_text
    lda #>info_text12
    sta.z display_info_progress.info_text+1
    jsr display_info_progress
    // [415] phi from main::@6 to main::@129 [phi:main::@6->main::@129]
    // main::@129
    // unsigned char ch = util_wait_key("Continue with update? [Y/N]", "nyNY")
    // [416] call util_wait_key
    // [884] phi from main::@129 to util_wait_key [phi:main::@129->util_wait_key]
    // [884] phi util_wait_key::filter#14 = main::filter3 [phi:main::@129->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter3
    sta.z util_wait_key.filter
    lda #>filter3
    sta.z util_wait_key.filter+1
    // [884] phi util_wait_key::info_text#4 = main::info_text13 [phi:main::@129->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text13
    sta.z util_wait_key.info_text
    lda #>info_text13
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("Continue with update? [Y/N]", "nyNY")
    // [417] util_wait_key::return#5 = util_wait_key::ch#4 -- vbum1=vwum2 
    lda util_wait_key.ch
    sta util_wait_key.return
    // main::@130
    // [418] main::ch#0 = util_wait_key::return#5
    // strchr("nN", ch)
    // [419] strchr::c#1 = main::ch#0
    // [420] call strchr
    // [1523] phi from main::@130 to strchr [phi:main::@130->strchr]
    // [1523] phi strchr::c#4 = strchr::c#1 [phi:main::@130->strchr#0] -- register_copy 
    // [1523] phi strchr::str#2 = (const void *)main::$204 [phi:main::@130->strchr#1] -- pvoz1=pvoc1 
    lda #<main__204
    sta.z strchr.str
    lda #>main__204
    sta.z strchr.str+1
    jsr strchr
    // strchr("nN", ch)
    // [421] strchr::return#4 = strchr::return#2
    // main::@131
    // [422] main::$106 = strchr::return#4
    // if(strchr("nN", ch))
    // [423] if((void *)0==main::$106) goto main::SEI5 -- pvoc1_eq_pvoz1_then_la1 
    lda.z main__106
    cmp #<0
    bne !+
    lda.z main__106+1
    cmp #>0
    bne !SEI5+
    jmp SEI5
  !SEI5:
  !:
    // main::@7
    // [424] smc_file_size#356 = smc_file_size#202 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_SKIP, "Cancelled")
    // [425] call display_info_smc
  // We cancel all updates, the updates are skipped.
    // [745] phi from main::@7 to display_info_smc [phi:main::@7->display_info_smc]
    // [745] phi display_info_smc::info_text#12 = main::info_text14 [phi:main::@7->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text14
    sta.z display_info_smc.info_text
    lda #>info_text14
    sta.z display_info_smc.info_text+1
    // [745] phi smc_file_size#12 = smc_file_size#356 [phi:main::@7->display_info_smc#1] -- register_copy 
    // [745] phi display_info_smc::info_status#12 = STATUS_SKIP [phi:main::@7->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [426] phi from main::@7 to main::@132 [phi:main::@7->main::@132]
    // main::@132
    // display_info_vera(STATUS_SKIP, "Cancelled")
    // [427] call display_info_vera
    // [780] phi from main::@132 to display_info_vera [phi:main::@132->display_info_vera]
    // [780] phi display_info_vera::info_text#10 = main::info_text14 [phi:main::@132->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text14
    sta.z display_info_vera.info_text
    lda #>info_text14
    sta.z display_info_vera.info_text+1
    // [780] phi display_info_vera::info_status#2 = STATUS_SKIP [phi:main::@132->display_info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // [428] phi from main::@132 to main::@34 [phi:main::@132->main::@34]
    // [428] phi main::rom_chip2#2 = 0 [phi:main::@132->main::@34#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip2
    // main::@34
  __b34:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [429] if(main::rom_chip2#2<8) goto main::@35 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip2
    cmp #8
    bcc __b35
    // [430] phi from main::@34 to main::@36 [phi:main::@34->main::@36]
    // main::@36
    // display_info_line("You have selected not to cancel the update ... ")
    // [431] call display_info_line
    // [965] phi from main::@36 to display_info_line [phi:main::@36->display_info_line]
    // [965] phi display_info_line::info_text#19 = main::info_text17 [phi:main::@36->display_info_line#0] -- pbuz1=pbuc1 
    lda #<info_text17
    sta.z display_info_line.info_text
    lda #>info_text17
    sta.z display_info_line.info_text+1
    jsr display_info_line
    jmp SEI5
    // main::@35
  __b35:
    // display_info_rom(rom_chip, STATUS_SKIP, "Cancelled")
    // [432] display_info_rom::rom_chip#9 = main::rom_chip2#2 -- vbuz1=vbum2 
    lda rom_chip2
    sta.z display_info_rom.rom_chip
    // [433] call display_info_rom
    // [1171] phi from main::@35 to display_info_rom [phi:main::@35->display_info_rom]
    // [1171] phi display_info_rom::info_text#16 = main::info_text14 [phi:main::@35->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text14
    sta.z display_info_rom.info_text
    lda #>info_text14
    sta.z display_info_rom.info_text+1
    // [1171] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#9 [phi:main::@35->display_info_rom#1] -- register_copy 
    // [1171] phi display_info_rom::info_status#16 = STATUS_SKIP [phi:main::@35->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // main::@133
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [434] main::rom_chip2#1 = ++ main::rom_chip2#2 -- vbum1=_inc_vbum1 
    inc rom_chip2
    // [428] phi from main::@133 to main::@34 [phi:main::@133->main::@34]
    // [428] phi main::rom_chip2#2 = main::rom_chip2#1 [phi:main::@133->main::@34#0] -- register_copy 
    jmp __b34
    // main::check_card_roms1_check_rom1
  check_card_roms1_check_rom1:
    // status_rom[rom_chip] == status
    // [435] main::check_card_roms1_check_rom1_$0 = status_rom[main::check_card_roms1_rom_chip#2] == STATUS_FLASH -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_FLASH
    ldy check_card_roms1_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_card_roms1_check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [436] main::check_card_roms1_check_rom1_return#0 = (char)main::check_card_roms1_check_rom1_$0 -- vbum1=vbuz2 
    sta check_card_roms1_check_rom1_return
    // main::check_card_roms1_@11
    // if(check_rom(rom_chip, status))
    // [437] if(0==main::check_card_roms1_check_rom1_return#0) goto main::check_card_roms1_@4 -- 0_eq_vbum1_then_la1 
    beq check_card_roms1___b4
    // [179] phi from main::check_card_roms1_@11 to main::check_card_roms1_@return [phi:main::check_card_roms1_@11->main::check_card_roms1_@return]
    // [179] phi main::check_card_roms1_return#2 = STATUS_FLASH [phi:main::check_card_roms1_@11->main::check_card_roms1_@return#0] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta check_card_roms1_return
    jmp __b67
    // main::check_card_roms1_@4
  check_card_roms1___b4:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [438] main::check_card_roms1_rom_chip#1 = ++ main::check_card_roms1_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_card_roms1_rom_chip
    // [177] phi from main::check_card_roms1_@4 to main::check_card_roms1_@1 [phi:main::check_card_roms1_@4->main::check_card_roms1_@1]
    // [177] phi main::check_card_roms1_rom_chip#2 = main::check_card_roms1_rom_chip#1 [phi:main::check_card_roms1_@4->main::check_card_roms1_@1#0] -- register_copy 
    jmp check_card_roms1___b1
    // main::@33
  __b33:
    // [439] smc_file_size#362 = smc_file_size#202 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_ISSUE, NULL)
    // [440] call display_info_smc
    // [745] phi from main::@33 to display_info_smc [phi:main::@33->display_info_smc]
    // [745] phi display_info_smc::info_text#12 = 0 [phi:main::@33->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [745] phi smc_file_size#12 = smc_file_size#362 [phi:main::@33->display_info_smc#1] -- register_copy 
    // [745] phi display_info_smc::info_status#12 = STATUS_ISSUE [phi:main::@33->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [441] phi from main::@33 to main::@126 [phi:main::@33->main::@126]
    // main::@126
    // display_info_cx16_rom(STATUS_ISSUE, NULL)
    // [442] call display_info_cx16_rom
    // [1532] phi from main::@126 to display_info_cx16_rom [phi:main::@126->display_info_cx16_rom]
    jsr display_info_cx16_rom
    // [443] phi from main::@126 to main::@127 [phi:main::@126->main::@127]
    // main::@127
    // display_info_progress("There is an issue with either the SMC or the CX16 main ROM!")
    // [444] call display_info_progress
    // [691] phi from main::@127 to display_info_progress [phi:main::@127->display_info_progress]
    // [691] phi display_info_progress::info_text#14 = main::info_text10 [phi:main::@127->display_info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text10
    sta.z display_info_progress.info_text
    lda #>info_text10
    sta.z display_info_progress.info_text+1
    jsr display_info_progress
    // [445] phi from main::@127 to main::@128 [phi:main::@127->main::@128]
    // main::@128
    // util_wait_key("Press [SPACE] to continue [ ]", " ")
    // [446] call util_wait_key
    // [884] phi from main::@128 to util_wait_key [phi:main::@128->util_wait_key]
    // [884] phi util_wait_key::filter#14 = s1 [phi:main::@128->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<@s1
    sta.z util_wait_key.filter
    lda #>@s1
    sta.z util_wait_key.filter+1
    // [884] phi util_wait_key::info_text#4 = main::info_text11 [phi:main::@128->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text11
    sta.z util_wait_key.info_text
    lda #>info_text11
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    jmp check_smc3
    // main::bank_set_brom2
  bank_set_brom2:
    // BROM = bank
    // [447] BROM = main::bank_set_brom2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom2_bank
    sta.z BROM
    // main::@63
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [448] if(rom_device_ids[main::rom_chip1#10]==$55) goto main::@27 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    ldy rom_chip1
    lda rom_device_ids,y
    cmp #$55
    bne !__b27+
    jmp __b27
  !__b27:
    // [449] phi from main::@63 to main::@30 [phi:main::@63->main::@30]
    // main::@30
    // display_progress_clear()
    // [450] call display_progress_clear
    // [676] phi from main::@30 to display_progress_clear [phi:main::@30->display_progress_clear]
    jsr display_progress_clear
    // main::@104
    // unsigned char rom_bank = rom_chip * 32
    // [451] main::rom_bank#0 = main::rom_chip1#10 << 5 -- vbum1=vbum2_rol_5 
    lda rom_chip1
    asl
    asl
    asl
    asl
    asl
    sta rom_bank
    // unsigned char* file = rom_file(rom_chip)
    // [452] rom_file::rom_chip#0 = main::rom_chip1#10 -- vbuz1=vbum2 
    lda rom_chip1
    sta.z rom_file.rom_chip
    // [453] call rom_file
    // [1216] phi from main::@104 to rom_file [phi:main::@104->rom_file]
    // [1216] phi rom_file::rom_chip#2 = rom_file::rom_chip#0 [phi:main::@104->rom_file#0] -- register_copy 
    jsr rom_file
    // unsigned char* file = rom_file(rom_chip)
    // [454] rom_file::return#4 = rom_file::return#2
    // main::@105
    // [455] main::file#0 = rom_file::return#4 -- pbuz1=pbuz2 
    lda.z rom_file.return
    sta.z file
    lda.z rom_file.return+1
    sta.z file+1
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [456] call snprintf_init
    jsr snprintf_init
    // [457] phi from main::@105 to main::@106 [phi:main::@105->main::@106]
    // main::@106
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [458] call printf_str
    // [725] phi from main::@106 to printf_str [phi:main::@106->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:main::@106->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = main::s6 [phi:main::@106->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // main::@107
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [459] printf_string::str#12 = main::file#0 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [460] call printf_string
    // [1222] phi from main::@107 to printf_string [phi:main::@107->printf_string]
    // [1222] phi printf_string::putc#18 = &snputc [phi:main::@107->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1222] phi printf_string::str#18 = printf_string::str#12 [phi:main::@107->printf_string#1] -- register_copy 
    // [1222] phi printf_string::format_justify_left#18 = 0 [phi:main::@107->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1222] phi printf_string::format_min_length#18 = 0 [phi:main::@107->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [461] phi from main::@107 to main::@108 [phi:main::@107->main::@108]
    // main::@108
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [462] call printf_str
    // [725] phi from main::@108 to printf_str [phi:main::@108->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:main::@108->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = main::s7 [phi:main::@108->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@109
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [463] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [464] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_progress(info_text)
    // [466] call display_info_progress
    // [691] phi from main::@109 to display_info_progress [phi:main::@109->display_info_progress]
    // [691] phi display_info_progress::info_text#14 = info_text [phi:main::@109->display_info_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_progress.info_text
    lda #>@info_text
    sta.z display_info_progress.info_text+1
    jsr display_info_progress
    // main::@110
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_CHECKING, rom_bank, rom_sizes[rom_chip])
    // [467] main::$182 = main::rom_chip1#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip1
    asl
    asl
    sta.z main__182
    // [468] rom_read::file#0 = main::file#0 -- pbuz1=pbuz2 
    lda.z file
    sta.z rom_read.file
    lda.z file+1
    sta.z rom_read.file+1
    // [469] rom_read::brom_bank_start#1 = main::rom_bank#0 -- vbuz1=vbum2 
    lda rom_bank
    sta.z rom_read.brom_bank_start
    // [470] rom_read::rom_size#0 = rom_sizes[main::$182] -- vduz1=pduc1_derefidx_vbuz2 
    ldy.z main__182
    lda rom_sizes,y
    sta.z rom_read.rom_size
    lda rom_sizes+1,y
    sta.z rom_read.rom_size+1
    lda rom_sizes+2,y
    sta.z rom_read.rom_size+2
    lda rom_sizes+3,y
    sta.z rom_read.rom_size+3
    // [471] call rom_read
    // [1247] phi from main::@110 to rom_read [phi:main::@110->rom_read]
    // [1247] phi rom_read::rom_size#12 = rom_read::rom_size#0 [phi:main::@110->rom_read#0] -- register_copy 
    // [1247] phi __errno#106 = __errno#112 [phi:main::@110->rom_read#1] -- register_copy 
    // [1247] phi rom_read::file#11 = rom_read::file#0 [phi:main::@110->rom_read#2] -- register_copy 
    // [1247] phi rom_read::brom_bank_start#21 = rom_read::brom_bank_start#1 [phi:main::@110->rom_read#3] -- register_copy 
    jsr rom_read
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_CHECKING, rom_bank, rom_sizes[rom_chip])
    // [472] rom_read::return#2 = rom_read::return#0
    // main::@111
    // [473] main::rom_bytes_read#0 = rom_read::return#2
    // if (!rom_bytes_read)
    // [474] if(0==main::rom_bytes_read#0) goto main::@28 -- 0_eq_vdum1_then_la1 
    // In case no file was found, set the status to none and skip to the next, else, mention the amount of bytes read.
    lda rom_bytes_read
    ora rom_bytes_read+1
    ora rom_bytes_read+2
    ora rom_bytes_read+3
    bne !__b28+
    jmp __b28
  !__b28:
    // main::@31
    // unsigned long rom_file_modulo = rom_bytes_read % 0x4000
    // [475] main::rom_file_modulo#0 = main::rom_bytes_read#0 & $4000-1 -- vdum1=vdum2_band_vduc1 
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
    // [476] if(0!=main::rom_file_modulo#0) goto main::@29 -- 0_neq_vdum1_then_la1 
    lda rom_file_modulo
    ora rom_file_modulo+1
    ora rom_file_modulo+2
    ora rom_file_modulo+3
    beq !__b29+
    jmp __b29
  !__b29:
    // main::@32
    // file_sizes[rom_chip] = rom_bytes_read
    // [477] file_sizes[main::$182] = main::rom_bytes_read#0 -- pduc1_derefidx_vbuz1=vdum2 
    // We know the file size, so we indicate it in the status panel.
    ldy.z main__182
    lda rom_bytes_read
    sta file_sizes,y
    lda rom_bytes_read+1
    sta file_sizes+1,y
    lda rom_bytes_read+2
    sta file_sizes+2,y
    lda rom_bytes_read+3
    sta file_sizes+3,y
    // strncpy(rom_github[rom_chip], (char*)RAM_BASE, 6)
    // [478] main::$184 = main::rom_chip1#10 << 1 -- vbuz1=vbum2_rol_1 
    lda rom_chip1
    asl
    sta.z main__184
    // [479] strncpy::dst#2 = rom_github[main::$184] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda rom_github,y
    sta.z strncpy.dst
    lda rom_github+1,y
    sta.z strncpy.dst+1
    // [480] call strncpy
  // Fill the version data ...
    // [1535] phi from main::@32 to strncpy [phi:main::@32->strncpy]
    // [1535] phi strncpy::dst#8 = strncpy::dst#2 [phi:main::@32->strncpy#0] -- register_copy 
    // [1535] phi strncpy::src#6 = (char *)$6000 [phi:main::@32->strncpy#1] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z strncpy.src
    lda #>$6000
    sta.z strncpy.src+1
    // [1535] phi strncpy::n#3 = 6 [phi:main::@32->strncpy#2] -- vwum1=vbuc1 
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
    // [482] BRAM = main::bank_push_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_push_set_bram1_bank
    sta.z BRAM
    // main::@65
    // rom_release[rom_chip] = *((char*)0xBF80)
    // [483] rom_release[main::rom_chip1#10] = *((char *) 49024) -- pbuc1_derefidx_vbum1=_deref_pbuc2 
    lda $bf80
    ldy rom_chip1
    sta rom_release,y
    // main::bank_pull_bram1
    // asm
    // asm { pla sta$00  }
    pla
    sta.z 0
    // [485] phi from main::bank_pull_bram1 to main::@66 [phi:main::bank_pull_bram1->main::@66]
    // main::@66
    // sprintf(info_text, "%s:R%u/%s", file, rom_release[rom_chip], rom_github[rom_chip])
    // [486] call snprintf_init
    jsr snprintf_init
    // main::@120
    // [487] printf_string::str#15 = main::file#0 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [488] call printf_string
    // [1222] phi from main::@120 to printf_string [phi:main::@120->printf_string]
    // [1222] phi printf_string::putc#18 = &snputc [phi:main::@120->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1222] phi printf_string::str#18 = printf_string::str#15 [phi:main::@120->printf_string#1] -- register_copy 
    // [1222] phi printf_string::format_justify_left#18 = 0 [phi:main::@120->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1222] phi printf_string::format_min_length#18 = 0 [phi:main::@120->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [489] phi from main::@120 to main::@121 [phi:main::@120->main::@121]
    // main::@121
    // sprintf(info_text, "%s:R%u/%s", file, rom_release[rom_chip], rom_github[rom_chip])
    // [490] call printf_str
    // [725] phi from main::@121 to printf_str [phi:main::@121->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:main::@121->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = main::s12 [phi:main::@121->printf_str#1] -- pbuz1=pbuc1 
    lda #<s12
    sta.z printf_str.s
    lda #>s12
    sta.z printf_str.s+1
    jsr printf_str
    // main::@122
    // sprintf(info_text, "%s:R%u/%s", file, rom_release[rom_chip], rom_github[rom_chip])
    // [491] printf_uchar::uvalue#8 = rom_release[main::rom_chip1#10] -- vbum1=pbuc1_derefidx_vbum2 
    ldy rom_chip1
    lda rom_release,y
    sta printf_uchar.uvalue
    // [492] call printf_uchar
    // [1151] phi from main::@122 to printf_uchar [phi:main::@122->printf_uchar]
    // [1151] phi printf_uchar::format_zero_padding#11 = 0 [phi:main::@122->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1151] phi printf_uchar::format_min_length#11 = 0 [phi:main::@122->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1151] phi printf_uchar::putc#11 = &snputc [phi:main::@122->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1151] phi printf_uchar::format_radix#11 = DECIMAL [phi:main::@122->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1151] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#8 [phi:main::@122->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [493] phi from main::@122 to main::@123 [phi:main::@122->main::@123]
    // main::@123
    // sprintf(info_text, "%s:R%u/%s", file, rom_release[rom_chip], rom_github[rom_chip])
    // [494] call printf_str
    // [725] phi from main::@123 to printf_str [phi:main::@123->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:main::@123->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = s4 [phi:main::@123->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // main::@124
    // sprintf(info_text, "%s:R%u/%s", file, rom_release[rom_chip], rom_github[rom_chip])
    // [495] printf_string::str#16 = rom_github[main::$184] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z main__184
    lda rom_github,y
    sta.z printf_string.str
    lda rom_github+1,y
    sta.z printf_string.str+1
    // [496] call printf_string
    // [1222] phi from main::@124 to printf_string [phi:main::@124->printf_string]
    // [1222] phi printf_string::putc#18 = &snputc [phi:main::@124->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1222] phi printf_string::str#18 = printf_string::str#16 [phi:main::@124->printf_string#1] -- register_copy 
    // [1222] phi printf_string::format_justify_left#18 = 0 [phi:main::@124->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1222] phi printf_string::format_min_length#18 = 0 [phi:main::@124->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // main::@125
    // sprintf(info_text, "%s:R%u/%s", file, rom_release[rom_chip], rom_github[rom_chip])
    // [497] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [498] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_FLASH, info_text)
    // [500] display_info_rom::rom_chip#8 = main::rom_chip1#10 -- vbuz1=vbum2 
    lda rom_chip1
    sta.z display_info_rom.rom_chip
    // [501] call display_info_rom
    // [1171] phi from main::@125 to display_info_rom [phi:main::@125->display_info_rom]
    // [1171] phi display_info_rom::info_text#16 = info_text [phi:main::@125->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1171] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#8 [phi:main::@125->display_info_rom#1] -- register_copy 
    // [1171] phi display_info_rom::info_status#16 = STATUS_FLASH [phi:main::@125->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASH
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // [502] phi from main::@115 main::@119 main::@125 main::@63 to main::@27 [phi:main::@115/main::@119/main::@125/main::@63->main::@27]
    // [502] phi __errno#252 = __errno#18 [phi:main::@115/main::@119/main::@125/main::@63->main::@27#0] -- register_copy 
    // main::@27
  __b27:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [503] main::rom_chip1#1 = ++ main::rom_chip1#10 -- vbum1=_inc_vbum1 
    inc rom_chip1
    // [160] phi from main::@27 to main::@26 [phi:main::@27->main::@26]
    // [160] phi __errno#112 = __errno#252 [phi:main::@27->main::@26#0] -- register_copy 
    // [160] phi main::rom_chip1#10 = main::rom_chip1#1 [phi:main::@27->main::@26#1] -- register_copy 
    jmp __b26
    // [504] phi from main::@31 to main::@29 [phi:main::@31->main::@29]
    // main::@29
  __b29:
    // sprintf(info_text, "File %s size error!", file)
    // [505] call snprintf_init
    jsr snprintf_init
    // [506] phi from main::@29 to main::@116 [phi:main::@29->main::@116]
    // main::@116
    // sprintf(info_text, "File %s size error!", file)
    // [507] call printf_str
    // [725] phi from main::@116 to printf_str [phi:main::@116->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:main::@116->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = main::s10 [phi:main::@116->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // main::@117
    // sprintf(info_text, "File %s size error!", file)
    // [508] printf_string::str#14 = main::file#0 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [509] call printf_string
    // [1222] phi from main::@117 to printf_string [phi:main::@117->printf_string]
    // [1222] phi printf_string::putc#18 = &snputc [phi:main::@117->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1222] phi printf_string::str#18 = printf_string::str#14 [phi:main::@117->printf_string#1] -- register_copy 
    // [1222] phi printf_string::format_justify_left#18 = 0 [phi:main::@117->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1222] phi printf_string::format_min_length#18 = 0 [phi:main::@117->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [510] phi from main::@117 to main::@118 [phi:main::@117->main::@118]
    // main::@118
    // sprintf(info_text, "File %s size error!", file)
    // [511] call printf_str
    // [725] phi from main::@118 to printf_str [phi:main::@118->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:main::@118->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = main::s11 [phi:main::@118->printf_str#1] -- pbuz1=pbuc1 
    lda #<s11
    sta.z printf_str.s
    lda #>s11
    sta.z printf_str.s+1
    jsr printf_str
    // main::@119
    // sprintf(info_text, "File %s size error!", file)
    // [512] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [513] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_ERROR, info_text)
    // [515] display_info_rom::rom_chip#7 = main::rom_chip1#10 -- vbuz1=vbum2 
    lda rom_chip1
    sta.z display_info_rom.rom_chip
    // [516] call display_info_rom
    // [1171] phi from main::@119 to display_info_rom [phi:main::@119->display_info_rom]
    // [1171] phi display_info_rom::info_text#16 = info_text [phi:main::@119->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1171] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#7 [phi:main::@119->display_info_rom#1] -- register_copy 
    // [1171] phi display_info_rom::info_status#16 = STATUS_ERROR [phi:main::@119->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_rom.info_status
    jsr display_info_rom
    jmp __b27
    // [517] phi from main::@111 to main::@28 [phi:main::@111->main::@28]
    // main::@28
  __b28:
    // sprintf(info_text, "No %s, skipped", file)
    // [518] call snprintf_init
    jsr snprintf_init
    // [519] phi from main::@28 to main::@112 [phi:main::@28->main::@112]
    // main::@112
    // sprintf(info_text, "No %s, skipped", file)
    // [520] call printf_str
    // [725] phi from main::@112 to printf_str [phi:main::@112->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:main::@112->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = main::s8 [phi:main::@112->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // main::@113
    // sprintf(info_text, "No %s, skipped", file)
    // [521] printf_string::str#13 = main::file#0 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [522] call printf_string
    // [1222] phi from main::@113 to printf_string [phi:main::@113->printf_string]
    // [1222] phi printf_string::putc#18 = &snputc [phi:main::@113->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1222] phi printf_string::str#18 = printf_string::str#13 [phi:main::@113->printf_string#1] -- register_copy 
    // [1222] phi printf_string::format_justify_left#18 = 0 [phi:main::@113->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1222] phi printf_string::format_min_length#18 = 0 [phi:main::@113->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [523] phi from main::@113 to main::@114 [phi:main::@113->main::@114]
    // main::@114
    // sprintf(info_text, "No %s, skipped", file)
    // [524] call printf_str
    // [725] phi from main::@114 to printf_str [phi:main::@114->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:main::@114->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = main::s9 [phi:main::@114->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // main::@115
    // sprintf(info_text, "No %s, skipped", file)
    // [525] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [526] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_NONE, info_text)
    // [528] display_info_rom::rom_chip#6 = main::rom_chip1#10 -- vbuz1=vbum2 
    lda rom_chip1
    sta.z display_info_rom.rom_chip
    // [529] call display_info_rom
    // [1171] phi from main::@115 to display_info_rom [phi:main::@115->display_info_rom]
    // [1171] phi display_info_rom::info_text#16 = info_text [phi:main::@115->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1171] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#6 [phi:main::@115->display_info_rom#1] -- register_copy 
    // [1171] phi display_info_rom::info_status#16 = STATUS_NONE [phi:main::@115->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_NONE
    sta.z display_info_rom.info_status
    jsr display_info_rom
    jmp __b27
    // main::@25
  __b25:
    // [530] smc_file_size#361 = smc_file_size#0 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_ERROR, "SMC.BIN too large!")
    // [531] call display_info_smc
    // [745] phi from main::@25 to display_info_smc [phi:main::@25->display_info_smc]
    // [745] phi display_info_smc::info_text#12 = main::info_text9 [phi:main::@25->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text9
    sta.z display_info_smc.info_text
    lda #>info_text9
    sta.z display_info_smc.info_text+1
    // [745] phi smc_file_size#12 = smc_file_size#361 [phi:main::@25->display_info_smc#1] -- register_copy 
    // [745] phi display_info_smc::info_status#12 = STATUS_ERROR [phi:main::@25->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp CLI3
    // main::@24
  __b24:
    // [532] smc_file_size#360 = smc_file_size#0 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_ERROR, "No SMC.BIN!")
    // [533] call display_info_smc
    // [745] phi from main::@24 to display_info_smc [phi:main::@24->display_info_smc]
    // [745] phi display_info_smc::info_text#12 = main::info_text8 [phi:main::@24->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z display_info_smc.info_text
    lda #>info_text8
    sta.z display_info_smc.info_text+1
    // [745] phi smc_file_size#12 = smc_file_size#360 [phi:main::@24->display_info_smc#1] -- register_copy 
    // [745] phi display_info_smc::info_status#12 = STATUS_ERROR [phi:main::@24->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp CLI3
    // main::@19
  __b19:
    // display_info_led(PROGRESS_X + 3, PROGRESS_Y + 3 + intro_status, status_color[intro_status], BLUE)
    // [534] display_info_led::y#3 = PROGRESS_Y+3 + main::intro_status#2 -- vbuz1=vbuc1_plus_vbum2 
    lda #PROGRESS_Y+3
    clc
    adc intro_status
    sta.z display_info_led.y
    // [535] display_info_led::tc#3 = status_color[main::intro_status#2] -- vbuz1=pbuc1_derefidx_vbum2 
    ldy intro_status
    lda status_color,y
    sta.z display_info_led.tc
    // [536] call display_info_led
    // [1546] phi from main::@19 to display_info_led [phi:main::@19->display_info_led]
    // [1546] phi display_info_led::y#4 = display_info_led::y#3 [phi:main::@19->display_info_led#0] -- register_copy 
    // [1546] phi display_info_led::x#4 = PROGRESS_X+3 [phi:main::@19->display_info_led#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X+3
    sta.z display_info_led.x
    // [1546] phi display_info_led::tc#4 = display_info_led::tc#3 [phi:main::@19->display_info_led#2] -- register_copy 
    jsr display_info_led
    // main::@98
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [537] main::intro_status#1 = ++ main::intro_status#2 -- vbum1=_inc_vbum1 
    inc intro_status
    // [130] phi from main::@98 to main::@18 [phi:main::@98->main::@18]
    // [130] phi main::intro_status#2 = main::intro_status#1 [phi:main::@98->main::@18#0] -- register_copy 
    jmp __b18
    // main::@14
  __b14:
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [538] if(rom_device_ids[main::rom_chip#2]!=$55) goto main::@15 -- pbuc1_derefidx_vbum1_neq_vbuc2_then_la1 
    lda #$55
    ldy rom_chip
    cmp rom_device_ids,y
    bne __b15
    // main::@17
    // display_info_rom(rom_chip, STATUS_NONE, "")
    // [539] display_info_rom::rom_chip#5 = main::rom_chip#2 -- vbuz1=vbum2 
    tya
    sta.z display_info_rom.rom_chip
    // [540] call display_info_rom
    // [1171] phi from main::@17 to display_info_rom [phi:main::@17->display_info_rom]
    // [1171] phi display_info_rom::info_text#16 = info_text5 [phi:main::@17->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z display_info_rom.info_text
    lda #>info_text5
    sta.z display_info_rom.info_text+1
    // [1171] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#5 [phi:main::@17->display_info_rom#1] -- register_copy 
    // [1171] phi display_info_rom::info_status#16 = STATUS_NONE [phi:main::@17->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_NONE
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // main::@16
  __b16:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [541] main::rom_chip#1 = ++ main::rom_chip#2 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [119] phi from main::@16 to main::@13 [phi:main::@16->main::@13]
    // [119] phi main::rom_chip#2 = main::rom_chip#1 [phi:main::@16->main::@13#0] -- register_copy 
    jmp __b13
    // main::@15
  __b15:
    // display_info_rom(rom_chip, STATUS_DETECTED, "")
    // [542] display_info_rom::rom_chip#4 = main::rom_chip#2 -- vbuz1=vbum2 
    lda rom_chip
    sta.z display_info_rom.rom_chip
    // [543] call display_info_rom
    // [1171] phi from main::@15 to display_info_rom [phi:main::@15->display_info_rom]
    // [1171] phi display_info_rom::info_text#16 = info_text5 [phi:main::@15->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z display_info_rom.info_text
    lda #>info_text5
    sta.z display_info_rom.info_text+1
    // [1171] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#4 [phi:main::@15->display_info_rom#1] -- register_copy 
    // [1171] phi display_info_rom::info_status#16 = STATUS_DETECTED [phi:main::@15->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_DETECTED
    sta.z display_info_rom.info_status
    jsr display_info_rom
    jmp __b16
    // [544] phi from main::@4 to main::@12 [phi:main::@4->main::@12]
    // main::@12
  __b12:
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [545] call snprintf_init
    jsr snprintf_init
    // [546] phi from main::@12 to main::@86 [phi:main::@12->main::@86]
    // main::@86
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [547] call printf_str
    // [725] phi from main::@86 to printf_str [phi:main::@86->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:main::@86->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = main::s2 [phi:main::@86->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main::@87
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [548] printf_uint::uvalue#13 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta printf_uint.uvalue
    lda smc_bootloader+1
    sta printf_uint.uvalue+1
    // [549] call printf_uint
    // [734] phi from main::@87 to printf_uint [phi:main::@87->printf_uint]
    // [734] phi printf_uint::format_zero_padding#16 = 1 [phi:main::@87->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [734] phi printf_uint::format_min_length#16 = 2 [phi:main::@87->printf_uint#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uint.format_min_length
    // [734] phi printf_uint::putc#16 = &snputc [phi:main::@87->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [734] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:main::@87->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [734] phi printf_uint::uvalue#16 = printf_uint::uvalue#13 [phi:main::@87->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [550] phi from main::@87 to main::@88 [phi:main::@87->main::@88]
    // main::@88
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [551] call printf_str
    // [725] phi from main::@88 to printf_str [phi:main::@88->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:main::@88->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = main::s3 [phi:main::@88->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // main::@89
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [552] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [553] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_smc(STATUS_ERROR, info_text)
    // [555] call display_info_smc
    // [745] phi from main::@89 to display_info_smc [phi:main::@89->display_info_smc]
    // [745] phi display_info_smc::info_text#12 = info_text [phi:main::@89->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_smc.info_text
    lda #>@info_text
    sta.z display_info_smc.info_text+1
    // [745] phi smc_file_size#12 = 0 [phi:main::@89->display_info_smc#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size_2
    sta smc_file_size_2+1
    // [745] phi display_info_smc::info_status#12 = STATUS_ERROR [phi:main::@89->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp CLI1
    // [556] phi from main::@3 to main::@11 [phi:main::@3->main::@11]
    // main::@11
  __b11:
    // display_info_smc(STATUS_ERROR, "Unreachable!")
    // [557] call display_info_smc
  // TODO: explain next steps ...
    // [745] phi from main::@11 to display_info_smc [phi:main::@11->display_info_smc]
    // [745] phi display_info_smc::info_text#12 = main::info_text2 [phi:main::@11->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z display_info_smc.info_text
    lda #>info_text2
    sta.z display_info_smc.info_text+1
    // [745] phi smc_file_size#12 = 0 [phi:main::@11->display_info_smc#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size_2
    sta smc_file_size_2+1
    // [745] phi display_info_smc::info_status#12 = STATUS_ERROR [phi:main::@11->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp CLI1
    // [558] phi from main::@85 to main::@1 [phi:main::@85->main::@1]
    // main::@1
  __b1:
    // display_info_smc(STATUS_ERROR, "No Bootloader!")
    // [559] call display_info_smc
  // TODO: explain next steps ...
    // [745] phi from main::@1 to display_info_smc [phi:main::@1->display_info_smc]
    // [745] phi display_info_smc::info_text#12 = main::info_text1 [phi:main::@1->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_smc.info_text
    lda #>info_text1
    sta.z display_info_smc.info_text+1
    // [745] phi smc_file_size#12 = 0 [phi:main::@1->display_info_smc#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size_2
    sta smc_file_size_2+1
    // [745] phi display_info_smc::info_status#12 = STATUS_ERROR [phi:main::@1->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp CLI1
  .segment Data
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
    info_text4: .text "Please read carefully the below, and press [SPACE] ..."
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
    main__204: .text "nN"
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
    w: .byte 0
    w1: .byte 0
}
.segment Code
  // screenlayer1
// Set the layer with which the conio will interact.
screenlayer1: {
    // screenlayer(1, *VERA_L1_MAPBASE, *VERA_L1_CONFIG)
    // [560] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbum1=_deref_pbuc1 
    lda VERA_L1_MAPBASE
    sta screenlayer.mapbase
    // [561] screenlayer::config#0 = *VERA_L1_CONFIG -- vbum1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta screenlayer.config
    // [562] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [563] return 
    rts
}
  // textcolor
// Set the front color for text output. The old front text color setting is returned.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char textcolor(__mem() char color)
textcolor: {
    .label textcolor__0 = $6e
    .label textcolor__1 = $6e
    // __conio.color & 0xF0
    // [565] textcolor::$0 = *((char *)&__conio+$d) & $f0 -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$d
    sta.z textcolor__0
    // __conio.color & 0xF0 | color
    // [566] textcolor::$1 = textcolor::$0 | textcolor::color#18 -- vbuz1=vbuz1_bor_vbum2 
    lda color
    ora.z textcolor__1
    sta.z textcolor__1
    // __conio.color = __conio.color & 0xF0 | color
    // [567] *((char *)&__conio+$d) = textcolor::$1 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // textcolor::@return
    // }
    // [568] return 
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
    .label bgcolor__0 = $6e
    .label bgcolor__1 = $6f
    .label bgcolor__2 = $6e
    // __conio.color & 0x0F
    // [570] bgcolor::$0 = *((char *)&__conio+$d) & $f -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$d
    sta.z bgcolor__0
    // color << 4
    // [571] bgcolor::$1 = bgcolor::color#14 << 4 -- vbuz1=vbum2_rol_4 
    lda color
    asl
    asl
    asl
    asl
    sta.z bgcolor__1
    // __conio.color & 0x0F | color << 4
    // [572] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbuz1=vbuz1_bor_vbuz2 
    lda.z bgcolor__2
    ora.z bgcolor__1
    sta.z bgcolor__2
    // __conio.color = __conio.color & 0x0F | color << 4
    // [573] *((char *)&__conio+$d) = bgcolor::$2 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // bgcolor::@return
    // }
    // [574] return 
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
    // [575] *((char *)&__conio+$c) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$c
    // cursor::@return
    // }
    // [576] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    // __mem unsigned char x
    // [577] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [578] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [580] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwum1=vbum2_word_vbum3 
    lda x
    sta return+1
    lda y
    sta return
    // cbm_k_plot_get::@return
    // }
    // [581] return 
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
    // [583] if(gotoxy::x#30>=*((char *)&__conio+6)) goto gotoxy::@1 -- vbum1_ge__deref_pbuc1_then_la1 
    lda x
    cmp __conio+6
    bcs __b1
    // [585] phi from gotoxy to gotoxy::@2 [phi:gotoxy->gotoxy::@2]
    // [585] phi gotoxy::$3 = gotoxy::x#30 [phi:gotoxy->gotoxy::@2#0] -- vbuz1=vbum2 
    sta.z gotoxy__3
    jmp __b2
    // gotoxy::@1
  __b1:
    // [584] gotoxy::$2 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z gotoxy__2
    // [585] phi from gotoxy::@1 to gotoxy::@2 [phi:gotoxy::@1->gotoxy::@2]
    // [585] phi gotoxy::$3 = gotoxy::$2 [phi:gotoxy::@1->gotoxy::@2#0] -- register_copy 
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [586] *((char *)&__conio) = gotoxy::$3 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__3
    sta __conio
    // (y>=__conio.height)?__conio.height:y
    // [587] if(gotoxy::y#30>=*((char *)&__conio+7)) goto gotoxy::@3 -- vbum1_ge__deref_pbuc1_then_la1 
    lda y
    cmp __conio+7
    bcs __b3
    // gotoxy::@4
    // [588] gotoxy::$14 = gotoxy::y#30 -- vbuz1=vbum2 
    sta.z gotoxy__14
    // [589] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [589] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [590] *((char *)&__conio+1) = gotoxy::$7 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__7
    sta __conio+1
    // __conio.cursor_x << 1
    // [591] gotoxy::$8 = *((char *)&__conio) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio
    asl
    sta.z gotoxy__8
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [592] gotoxy::$10 = gotoxy::y#30 << 1 -- vbuz1=vbum2_rol_1 
    lda y
    asl
    sta.z gotoxy__10
    // [593] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwuz1=pwuc1_derefidx_vbuz2_plus_vbuz3 
    lda.z gotoxy__8
    ldy.z gotoxy__10
    clc
    adc __conio+$15,y
    sta.z gotoxy__9
    lda __conio+$15+1,y
    adc #0
    sta.z gotoxy__9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [594] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwuz1 
    lda.z gotoxy__9
    sta __conio+$13
    lda.z gotoxy__9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [595] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [596] gotoxy::$6 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
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
    .label cputln__2 = $4a
    // __conio.cursor_x = 0
    // [597] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y++;
    // [598] *((char *)&__conio+1) = ++ *((char *)&__conio+1) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+1
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [599] cputln::$2 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z cputln__2
    // [600] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [601] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [602] return 
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
    .label cx16_k_screen_set_charset1_offset = $d3
    // textcolor(WHITE)
    // [604] call textcolor
  // Set the charset to lower case.
  // screenlayer1();
    // [564] phi from display_frame_init_64 to textcolor [phi:display_frame_init_64->textcolor]
    // [564] phi textcolor::color#18 = WHITE [phi:display_frame_init_64->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [605] phi from display_frame_init_64 to display_frame_init_64::@2 [phi:display_frame_init_64->display_frame_init_64::@2]
    // display_frame_init_64::@2
    // bgcolor(BLUE)
    // [606] call bgcolor
    // [569] phi from display_frame_init_64::@2 to bgcolor [phi:display_frame_init_64::@2->bgcolor]
    // [569] phi bgcolor::color#14 = BLUE [phi:display_frame_init_64::@2->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [607] phi from display_frame_init_64::@2 to display_frame_init_64::@3 [phi:display_frame_init_64::@2->display_frame_init_64::@3]
    // display_frame_init_64::@3
    // scroll(0)
    // [608] call scroll
    jsr scroll
    // [609] phi from display_frame_init_64::@3 to display_frame_init_64::@4 [phi:display_frame_init_64::@3->display_frame_init_64::@4]
    // display_frame_init_64::@4
    // clrscr()
    // [610] call clrscr
    jsr clrscr
    // display_frame_init_64::vera_display_set_hstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [611] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTART = start
    // [612] *VERA_DC_HSTART = display_frame_init_64::vera_display_set_hstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstart1_start
    sta VERA_DC_HSTART
    // display_frame_init_64::vera_display_set_hstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [613] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTOP = stop
    // [614] *VERA_DC_HSTOP = display_frame_init_64::vera_display_set_hstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstop1_stop
    sta VERA_DC_HSTOP
    // display_frame_init_64::vera_display_set_vstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [615] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTART = start
    // [616] *VERA_DC_VSTART = display_frame_init_64::vera_display_set_vstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstart1_start
    sta VERA_DC_VSTART
    // display_frame_init_64::vera_display_set_vstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [617] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTOP = stop
    // [618] *VERA_DC_VSTOP = display_frame_init_64::vera_display_set_vstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstop1_stop
    sta VERA_DC_VSTOP
    // display_frame_init_64::@1
    // cx16_k_screen_set_charset(3, (char *)0)
    // [619] display_frame_init_64::cx16_k_screen_set_charset1_charset = 3 -- vbum1=vbuc1 
    lda #3
    sta cx16_k_screen_set_charset1_charset
    // [620] display_frame_init_64::cx16_k_screen_set_charset1_offset = (char *) 0 -- pbuz1=pbuc1 
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
    // display_frame_init_64::@return
    // }
    // [622] return 
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
    // [624] call textcolor
    // [564] phi from display_frame_draw to textcolor [phi:display_frame_draw->textcolor]
    // [564] phi textcolor::color#18 = LIGHT_BLUE [phi:display_frame_draw->textcolor#0] -- vbum1=vbuc1 
    lda #LIGHT_BLUE
    sta textcolor.color
    jsr textcolor
    // [625] phi from display_frame_draw to display_frame_draw::@1 [phi:display_frame_draw->display_frame_draw::@1]
    // display_frame_draw::@1
    // bgcolor(BLUE)
    // [626] call bgcolor
    // [569] phi from display_frame_draw::@1 to bgcolor [phi:display_frame_draw::@1->bgcolor]
    // [569] phi bgcolor::color#14 = BLUE [phi:display_frame_draw::@1->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [627] phi from display_frame_draw::@1 to display_frame_draw::@2 [phi:display_frame_draw::@1->display_frame_draw::@2]
    // display_frame_draw::@2
    // clrscr()
    // [628] call clrscr
    jsr clrscr
    // [629] phi from display_frame_draw::@2 to display_frame_draw::@3 [phi:display_frame_draw::@2->display_frame_draw::@3]
    // display_frame_draw::@3
    // display_frame(0, 0, 67, 14)
    // [630] call display_frame
    // [1628] phi from display_frame_draw::@3 to display_frame [phi:display_frame_draw::@3->display_frame]
    // [1628] phi display_frame::y#0 = 0 [phi:display_frame_draw::@3->display_frame#0] -- vbum1=vbuc1 
    lda #0
    sta display_frame.y
    // [1628] phi display_frame::y1#16 = $e [phi:display_frame_draw::@3->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1628] phi display_frame::x#0 = 0 [phi:display_frame_draw::@3->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1628] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@3->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [631] phi from display_frame_draw::@3 to display_frame_draw::@4 [phi:display_frame_draw::@3->display_frame_draw::@4]
    // display_frame_draw::@4
    // display_frame(0, 0, 67, 2)
    // [632] call display_frame
    // [1628] phi from display_frame_draw::@4 to display_frame [phi:display_frame_draw::@4->display_frame]
    // [1628] phi display_frame::y#0 = 0 [phi:display_frame_draw::@4->display_frame#0] -- vbum1=vbuc1 
    lda #0
    sta display_frame.y
    // [1628] phi display_frame::y1#16 = 2 [phi:display_frame_draw::@4->display_frame#1] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y1
    // [1628] phi display_frame::x#0 = 0 [phi:display_frame_draw::@4->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1628] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@4->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [633] phi from display_frame_draw::@4 to display_frame_draw::@5 [phi:display_frame_draw::@4->display_frame_draw::@5]
    // display_frame_draw::@5
    // display_frame(0, 2, 67, 14)
    // [634] call display_frame
    // [1628] phi from display_frame_draw::@5 to display_frame [phi:display_frame_draw::@5->display_frame]
    // [1628] phi display_frame::y#0 = 2 [phi:display_frame_draw::@5->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1628] phi display_frame::y1#16 = $e [phi:display_frame_draw::@5->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1628] phi display_frame::x#0 = 0 [phi:display_frame_draw::@5->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1628] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@5->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [635] phi from display_frame_draw::@5 to display_frame_draw::@6 [phi:display_frame_draw::@5->display_frame_draw::@6]
    // display_frame_draw::@6
    // display_frame(0, 2, 8, 14)
    // [636] call display_frame
  // Chipset areas
    // [1628] phi from display_frame_draw::@6 to display_frame [phi:display_frame_draw::@6->display_frame]
    // [1628] phi display_frame::y#0 = 2 [phi:display_frame_draw::@6->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1628] phi display_frame::y1#16 = $e [phi:display_frame_draw::@6->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1628] phi display_frame::x#0 = 0 [phi:display_frame_draw::@6->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1628] phi display_frame::x1#16 = 8 [phi:display_frame_draw::@6->display_frame#3] -- vbuz1=vbuc1 
    lda #8
    sta.z display_frame.x1
    jsr display_frame
    // [637] phi from display_frame_draw::@6 to display_frame_draw::@7 [phi:display_frame_draw::@6->display_frame_draw::@7]
    // display_frame_draw::@7
    // display_frame(8, 2, 19, 14)
    // [638] call display_frame
    // [1628] phi from display_frame_draw::@7 to display_frame [phi:display_frame_draw::@7->display_frame]
    // [1628] phi display_frame::y#0 = 2 [phi:display_frame_draw::@7->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1628] phi display_frame::y1#16 = $e [phi:display_frame_draw::@7->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1628] phi display_frame::x#0 = 8 [phi:display_frame_draw::@7->display_frame#2] -- vbum1=vbuc1 
    lda #8
    sta display_frame.x
    // [1628] phi display_frame::x1#16 = $13 [phi:display_frame_draw::@7->display_frame#3] -- vbuz1=vbuc1 
    lda #$13
    sta.z display_frame.x1
    jsr display_frame
    // [639] phi from display_frame_draw::@7 to display_frame_draw::@8 [phi:display_frame_draw::@7->display_frame_draw::@8]
    // display_frame_draw::@8
    // display_frame(19, 2, 25, 14)
    // [640] call display_frame
    // [1628] phi from display_frame_draw::@8 to display_frame [phi:display_frame_draw::@8->display_frame]
    // [1628] phi display_frame::y#0 = 2 [phi:display_frame_draw::@8->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1628] phi display_frame::y1#16 = $e [phi:display_frame_draw::@8->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1628] phi display_frame::x#0 = $13 [phi:display_frame_draw::@8->display_frame#2] -- vbum1=vbuc1 
    lda #$13
    sta display_frame.x
    // [1628] phi display_frame::x1#16 = $19 [phi:display_frame_draw::@8->display_frame#3] -- vbuz1=vbuc1 
    lda #$19
    sta.z display_frame.x1
    jsr display_frame
    // [641] phi from display_frame_draw::@8 to display_frame_draw::@9 [phi:display_frame_draw::@8->display_frame_draw::@9]
    // display_frame_draw::@9
    // display_frame(25, 2, 31, 14)
    // [642] call display_frame
    // [1628] phi from display_frame_draw::@9 to display_frame [phi:display_frame_draw::@9->display_frame]
    // [1628] phi display_frame::y#0 = 2 [phi:display_frame_draw::@9->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1628] phi display_frame::y1#16 = $e [phi:display_frame_draw::@9->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1628] phi display_frame::x#0 = $19 [phi:display_frame_draw::@9->display_frame#2] -- vbum1=vbuc1 
    lda #$19
    sta display_frame.x
    // [1628] phi display_frame::x1#16 = $1f [phi:display_frame_draw::@9->display_frame#3] -- vbuz1=vbuc1 
    lda #$1f
    sta.z display_frame.x1
    jsr display_frame
    // [643] phi from display_frame_draw::@9 to display_frame_draw::@10 [phi:display_frame_draw::@9->display_frame_draw::@10]
    // display_frame_draw::@10
    // display_frame(31, 2, 37, 14)
    // [644] call display_frame
    // [1628] phi from display_frame_draw::@10 to display_frame [phi:display_frame_draw::@10->display_frame]
    // [1628] phi display_frame::y#0 = 2 [phi:display_frame_draw::@10->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1628] phi display_frame::y1#16 = $e [phi:display_frame_draw::@10->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1628] phi display_frame::x#0 = $1f [phi:display_frame_draw::@10->display_frame#2] -- vbum1=vbuc1 
    lda #$1f
    sta display_frame.x
    // [1628] phi display_frame::x1#16 = $25 [phi:display_frame_draw::@10->display_frame#3] -- vbuz1=vbuc1 
    lda #$25
    sta.z display_frame.x1
    jsr display_frame
    // [645] phi from display_frame_draw::@10 to display_frame_draw::@11 [phi:display_frame_draw::@10->display_frame_draw::@11]
    // display_frame_draw::@11
    // display_frame(37, 2, 43, 14)
    // [646] call display_frame
    // [1628] phi from display_frame_draw::@11 to display_frame [phi:display_frame_draw::@11->display_frame]
    // [1628] phi display_frame::y#0 = 2 [phi:display_frame_draw::@11->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1628] phi display_frame::y1#16 = $e [phi:display_frame_draw::@11->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1628] phi display_frame::x#0 = $25 [phi:display_frame_draw::@11->display_frame#2] -- vbum1=vbuc1 
    lda #$25
    sta display_frame.x
    // [1628] phi display_frame::x1#16 = $2b [phi:display_frame_draw::@11->display_frame#3] -- vbuz1=vbuc1 
    lda #$2b
    sta.z display_frame.x1
    jsr display_frame
    // [647] phi from display_frame_draw::@11 to display_frame_draw::@12 [phi:display_frame_draw::@11->display_frame_draw::@12]
    // display_frame_draw::@12
    // display_frame(43, 2, 49, 14)
    // [648] call display_frame
    // [1628] phi from display_frame_draw::@12 to display_frame [phi:display_frame_draw::@12->display_frame]
    // [1628] phi display_frame::y#0 = 2 [phi:display_frame_draw::@12->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1628] phi display_frame::y1#16 = $e [phi:display_frame_draw::@12->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1628] phi display_frame::x#0 = $2b [phi:display_frame_draw::@12->display_frame#2] -- vbum1=vbuc1 
    lda #$2b
    sta display_frame.x
    // [1628] phi display_frame::x1#16 = $31 [phi:display_frame_draw::@12->display_frame#3] -- vbuz1=vbuc1 
    lda #$31
    sta.z display_frame.x1
    jsr display_frame
    // [649] phi from display_frame_draw::@12 to display_frame_draw::@13 [phi:display_frame_draw::@12->display_frame_draw::@13]
    // display_frame_draw::@13
    // display_frame(49, 2, 55, 14)
    // [650] call display_frame
    // [1628] phi from display_frame_draw::@13 to display_frame [phi:display_frame_draw::@13->display_frame]
    // [1628] phi display_frame::y#0 = 2 [phi:display_frame_draw::@13->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1628] phi display_frame::y1#16 = $e [phi:display_frame_draw::@13->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1628] phi display_frame::x#0 = $31 [phi:display_frame_draw::@13->display_frame#2] -- vbum1=vbuc1 
    lda #$31
    sta display_frame.x
    // [1628] phi display_frame::x1#16 = $37 [phi:display_frame_draw::@13->display_frame#3] -- vbuz1=vbuc1 
    lda #$37
    sta.z display_frame.x1
    jsr display_frame
    // [651] phi from display_frame_draw::@13 to display_frame_draw::@14 [phi:display_frame_draw::@13->display_frame_draw::@14]
    // display_frame_draw::@14
    // display_frame(55, 2, 61, 14)
    // [652] call display_frame
    // [1628] phi from display_frame_draw::@14 to display_frame [phi:display_frame_draw::@14->display_frame]
    // [1628] phi display_frame::y#0 = 2 [phi:display_frame_draw::@14->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1628] phi display_frame::y1#16 = $e [phi:display_frame_draw::@14->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1628] phi display_frame::x#0 = $37 [phi:display_frame_draw::@14->display_frame#2] -- vbum1=vbuc1 
    lda #$37
    sta display_frame.x
    // [1628] phi display_frame::x1#16 = $3d [phi:display_frame_draw::@14->display_frame#3] -- vbuz1=vbuc1 
    lda #$3d
    sta.z display_frame.x1
    jsr display_frame
    // [653] phi from display_frame_draw::@14 to display_frame_draw::@15 [phi:display_frame_draw::@14->display_frame_draw::@15]
    // display_frame_draw::@15
    // display_frame(61, 2, 67, 14)
    // [654] call display_frame
    // [1628] phi from display_frame_draw::@15 to display_frame [phi:display_frame_draw::@15->display_frame]
    // [1628] phi display_frame::y#0 = 2 [phi:display_frame_draw::@15->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1628] phi display_frame::y1#16 = $e [phi:display_frame_draw::@15->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1628] phi display_frame::x#0 = $3d [phi:display_frame_draw::@15->display_frame#2] -- vbum1=vbuc1 
    lda #$3d
    sta display_frame.x
    // [1628] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@15->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [655] phi from display_frame_draw::@15 to display_frame_draw::@16 [phi:display_frame_draw::@15->display_frame_draw::@16]
    // display_frame_draw::@16
    // display_frame(0, 14, 67, PROGRESS_Y-5)
    // [656] call display_frame
  // Progress area
    // [1628] phi from display_frame_draw::@16 to display_frame [phi:display_frame_draw::@16->display_frame]
    // [1628] phi display_frame::y#0 = $e [phi:display_frame_draw::@16->display_frame#0] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y
    // [1628] phi display_frame::y1#16 = PROGRESS_Y-5 [phi:display_frame_draw::@16->display_frame#1] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-5
    sta.z display_frame.y1
    // [1628] phi display_frame::x#0 = 0 [phi:display_frame_draw::@16->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1628] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@16->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [657] phi from display_frame_draw::@16 to display_frame_draw::@17 [phi:display_frame_draw::@16->display_frame_draw::@17]
    // display_frame_draw::@17
    // display_frame(0, PROGRESS_Y-5, 67, PROGRESS_Y-2)
    // [658] call display_frame
    // [1628] phi from display_frame_draw::@17 to display_frame [phi:display_frame_draw::@17->display_frame]
    // [1628] phi display_frame::y#0 = PROGRESS_Y-5 [phi:display_frame_draw::@17->display_frame#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-5
    sta display_frame.y
    // [1628] phi display_frame::y1#16 = PROGRESS_Y-2 [phi:display_frame_draw::@17->display_frame#1] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-2
    sta.z display_frame.y1
    // [1628] phi display_frame::x#0 = 0 [phi:display_frame_draw::@17->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1628] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@17->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [659] phi from display_frame_draw::@17 to display_frame_draw::@18 [phi:display_frame_draw::@17->display_frame_draw::@18]
    // display_frame_draw::@18
    // display_frame(0, PROGRESS_Y-2, 67, 49)
    // [660] call display_frame
    // [1628] phi from display_frame_draw::@18 to display_frame [phi:display_frame_draw::@18->display_frame]
    // [1628] phi display_frame::y#0 = PROGRESS_Y-2 [phi:display_frame_draw::@18->display_frame#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-2
    sta display_frame.y
    // [1628] phi display_frame::y1#16 = $31 [phi:display_frame_draw::@18->display_frame#1] -- vbuz1=vbuc1 
    lda #$31
    sta.z display_frame.y1
    // [1628] phi display_frame::x#0 = 0 [phi:display_frame_draw::@18->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1628] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@18->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [661] phi from display_frame_draw::@18 to display_frame_draw::@19 [phi:display_frame_draw::@18->display_frame_draw::@19]
    // display_frame_draw::@19
    // textcolor(WHITE)
    // [662] call textcolor
    // [564] phi from display_frame_draw::@19 to textcolor [phi:display_frame_draw::@19->textcolor]
    // [564] phi textcolor::color#18 = WHITE [phi:display_frame_draw::@19->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // display_frame_draw::@return
    // }
    // [663] return 
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
    // [665] call gotoxy
    // [582] phi from display_frame_title to gotoxy [phi:display_frame_title->gotoxy]
    // [582] phi gotoxy::y#30 = 1 [phi:display_frame_title->gotoxy#0] -- vbum1=vbuc1 
    lda #1
    sta gotoxy.y
    // [582] phi gotoxy::x#30 = 2 [phi:display_frame_title->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // [666] phi from display_frame_title to display_frame_title::@1 [phi:display_frame_title->display_frame_title::@1]
    // display_frame_title::@1
    // printf("%-65s", title_text)
    // [667] call printf_string
    // [1222] phi from display_frame_title::@1 to printf_string [phi:display_frame_title::@1->printf_string]
    // [1222] phi printf_string::putc#18 = &cputc [phi:display_frame_title::@1->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1222] phi printf_string::str#18 = main::title_text [phi:display_frame_title::@1->printf_string#1] -- pbuz1=pbuc1 
    lda #<main.title_text
    sta.z printf_string.str
    lda #>main.title_text
    sta.z printf_string.str+1
    // [1222] phi printf_string::format_justify_left#18 = 1 [phi:display_frame_title::@1->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1222] phi printf_string::format_min_length#18 = $41 [phi:display_frame_title::@1->printf_string#3] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_frame_title::@return
    // }
    // [668] return 
    rts
}
  // cputsxy
// Move cursor and output a NUL-terminated string
// Same as "gotoxy (x, y); puts (s);"
// void cputsxy(__mem() char x, __mem() char y, __zp($6c) const char *s)
cputsxy: {
    .label s = $6c
    // gotoxy(x, y)
    // [670] gotoxy::x#1 = cputsxy::x#4 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [671] gotoxy::y#1 = cputsxy::y#4 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [672] call gotoxy
    // [582] phi from cputsxy to gotoxy [phi:cputsxy->gotoxy]
    // [582] phi gotoxy::y#30 = gotoxy::y#1 [phi:cputsxy->gotoxy#0] -- register_copy 
    // [582] phi gotoxy::x#30 = gotoxy::x#1 [phi:cputsxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputsxy::@1
    // cputs(s)
    // [673] cputs::s#1 = cputsxy::s#4 -- pbuz1=pbuz2 
    lda.z s
    sta.z cputs.s
    lda.z s+1
    sta.z cputs.s+1
    // [674] call cputs
    // [1762] phi from cputsxy::@1 to cputs [phi:cputsxy::@1->cputs]
    jsr cputs
    // cputsxy::@return
    // }
    // [675] return 
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
    // [677] call textcolor
    // [564] phi from display_progress_clear to textcolor [phi:display_progress_clear->textcolor]
    // [564] phi textcolor::color#18 = WHITE [phi:display_progress_clear->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [678] phi from display_progress_clear to display_progress_clear::@5 [phi:display_progress_clear->display_progress_clear::@5]
    // display_progress_clear::@5
    // bgcolor(BLUE)
    // [679] call bgcolor
    // [569] phi from display_progress_clear::@5 to bgcolor [phi:display_progress_clear::@5->bgcolor]
    // [569] phi bgcolor::color#14 = BLUE [phi:display_progress_clear::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [680] phi from display_progress_clear::@5 to display_progress_clear::@1 [phi:display_progress_clear::@5->display_progress_clear::@1]
    // [680] phi display_progress_clear::y#2 = PROGRESS_Y [phi:display_progress_clear::@5->display_progress_clear::@1#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // display_progress_clear::@1
  __b1:
    // while (y < h)
    // [681] if(display_progress_clear::y#2<display_progress_clear::h) goto display_progress_clear::@2 -- vbum1_lt_vbuc1_then_la1 
    lda y
    cmp #h
    bcc __b4
    // display_progress_clear::@return
    // }
    // [682] return 
    rts
    // [683] phi from display_progress_clear::@1 to display_progress_clear::@2 [phi:display_progress_clear::@1->display_progress_clear::@2]
  __b4:
    // [683] phi display_progress_clear::x#2 = PROGRESS_X [phi:display_progress_clear::@1->display_progress_clear::@2#0] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x
    // [683] phi display_progress_clear::i#2 = 0 [phi:display_progress_clear::@1->display_progress_clear::@2#1] -- vbum1=vbuc1 
    lda #0
    sta i
    // display_progress_clear::@2
  __b2:
    // for(unsigned char i = 0; i < w; i++)
    // [684] if(display_progress_clear::i#2<PROGRESS_W) goto display_progress_clear::@3 -- vbum1_lt_vbuc1_then_la1 
    lda i
    cmp #PROGRESS_W
    bcc __b3
    // display_progress_clear::@4
    // y++;
    // [685] display_progress_clear::y#1 = ++ display_progress_clear::y#2 -- vbum1=_inc_vbum1 
    inc y
    // [680] phi from display_progress_clear::@4 to display_progress_clear::@1 [phi:display_progress_clear::@4->display_progress_clear::@1]
    // [680] phi display_progress_clear::y#2 = display_progress_clear::y#1 [phi:display_progress_clear::@4->display_progress_clear::@1#0] -- register_copy 
    jmp __b1
    // display_progress_clear::@3
  __b3:
    // cputcxy(x, y, ' ')
    // [686] cputcxy::x#12 = display_progress_clear::x#2 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [687] cputcxy::y#12 = display_progress_clear::y#2 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [688] call cputcxy
    // [1771] phi from display_progress_clear::@3 to cputcxy [phi:display_progress_clear::@3->cputcxy]
    // [1771] phi cputcxy::c#15 = ' ' [phi:display_progress_clear::@3->cputcxy#0] -- vbum1=vbuc1 
    lda #' '
    sta cputcxy.c
    // [1771] phi cputcxy::y#15 = cputcxy::y#12 [phi:display_progress_clear::@3->cputcxy#1] -- register_copy 
    // [1771] phi cputcxy::x#15 = cputcxy::x#12 [phi:display_progress_clear::@3->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_progress_clear::@6
    // x++;
    // [689] display_progress_clear::x#1 = ++ display_progress_clear::x#2 -- vbum1=_inc_vbum1 
    inc x
    // for(unsigned char i = 0; i < w; i++)
    // [690] display_progress_clear::i#1 = ++ display_progress_clear::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [683] phi from display_progress_clear::@6 to display_progress_clear::@2 [phi:display_progress_clear::@6->display_progress_clear::@2]
    // [683] phi display_progress_clear::x#2 = display_progress_clear::x#1 [phi:display_progress_clear::@6->display_progress_clear::@2#0] -- register_copy 
    // [683] phi display_progress_clear::i#2 = display_progress_clear::i#1 [phi:display_progress_clear::@6->display_progress_clear::@2#1] -- register_copy 
    jmp __b2
  .segment Data
    x: .byte 0
    i: .byte 0
    y: .byte 0
}
.segment Code
  // display_info_progress
// void display_info_progress(__zp($5f) char *info_text)
display_info_progress: {
    .label info_text = $5f
    // unsigned char x = wherex()
    // [692] call wherex
    jsr wherex
    // [693] wherex::return#2 = wherex::return#0
    // display_info_progress::@1
    // [694] display_info_progress::x#0 = wherex::return#2
    // unsigned char y = wherey()
    // [695] call wherey
    jsr wherey
    // [696] wherey::return#2 = wherey::return#0
    // display_info_progress::@2
    // [697] display_info_progress::y#0 = wherey::return#2
    // gotoxy(2, PROGRESS_Y-4)
    // [698] call gotoxy
    // [582] phi from display_info_progress::@2 to gotoxy [phi:display_info_progress::@2->gotoxy]
    // [582] phi gotoxy::y#30 = PROGRESS_Y-4 [phi:display_info_progress::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-4
    sta gotoxy.y
    // [582] phi gotoxy::x#30 = 2 [phi:display_info_progress::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // display_info_progress::@3
    // printf("%-65s", info_text)
    // [699] printf_string::str#1 = display_info_progress::info_text#14
    // [700] call printf_string
    // [1222] phi from display_info_progress::@3 to printf_string [phi:display_info_progress::@3->printf_string]
    // [1222] phi printf_string::putc#18 = &cputc [phi:display_info_progress::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1222] phi printf_string::str#18 = printf_string::str#1 [phi:display_info_progress::@3->printf_string#1] -- register_copy 
    // [1222] phi printf_string::format_justify_left#18 = 1 [phi:display_info_progress::@3->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1222] phi printf_string::format_min_length#18 = $41 [phi:display_info_progress::@3->printf_string#3] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_progress::@4
    // gotoxy(x, y)
    // [701] gotoxy::x#10 = display_info_progress::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [702] gotoxy::y#10 = display_info_progress::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [703] call gotoxy
    // [582] phi from display_info_progress::@4 to gotoxy [phi:display_info_progress::@4->gotoxy]
    // [582] phi gotoxy::y#30 = gotoxy::y#10 [phi:display_info_progress::@4->gotoxy#0] -- register_copy 
    // [582] phi gotoxy::x#30 = gotoxy::x#10 [phi:display_info_progress::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_progress::@return
    // }
    // [704] return 
    rts
  .segment Data
    .label x = wherex.return
    .label y = wherey.return
}
.segment Code
  // smc_detect
smc_detect: {
    .label smc_detect__1 = $41
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [705] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [706] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [707] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [708] cx16_k_i2c_read_byte::return#10 = cx16_k_i2c_read_byte::return#1
    // smc_detect::@3
    // smc_bootloader_version = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [709] smc_detect::smc_bootloader_version#1 = cx16_k_i2c_read_byte::return#10
    // BYTE1(smc_bootloader_version)
    // [710] smc_detect::$1 = byte1  smc_detect::smc_bootloader_version#1 -- vbuz1=_byte1_vwum2 
    lda smc_bootloader_version+1
    sta.z smc_detect__1
    // if(!BYTE1(smc_bootloader_version))
    // [711] if(0==smc_detect::$1) goto smc_detect::@1 -- 0_eq_vbuz1_then_la1 
    beq __b1
    // [714] phi from smc_detect::@3 to smc_detect::@2 [phi:smc_detect::@3->smc_detect::@2]
    // [714] phi smc_detect::return#0 = $200 [phi:smc_detect::@3->smc_detect::@2#0] -- vwum1=vwuc1 
    lda #<$200
    sta return
    lda #>$200
    sta return+1
    rts
    // smc_detect::@1
  __b1:
    // if(smc_bootloader_version == 0xFF)
    // [712] if(smc_detect::smc_bootloader_version#1!=$ff) goto smc_detect::@4 -- vwum1_neq_vbuc1_then_la1 
    lda smc_bootloader_version+1
    bne __b2
    lda smc_bootloader_version
    cmp #$ff
    bne __b2
    // [714] phi from smc_detect::@1 to smc_detect::@2 [phi:smc_detect::@1->smc_detect::@2]
    // [714] phi smc_detect::return#0 = $100 [phi:smc_detect::@1->smc_detect::@2#0] -- vwum1=vwuc1 
    lda #<$100
    sta return
    lda #>$100
    sta return+1
    rts
    // [713] phi from smc_detect::@1 to smc_detect::@4 [phi:smc_detect::@1->smc_detect::@4]
    // smc_detect::@4
    // [714] phi from smc_detect::@4 to smc_detect::@2 [phi:smc_detect::@4->smc_detect::@2]
    // [714] phi smc_detect::return#0 = smc_detect::smc_bootloader_version#1 [phi:smc_detect::@4->smc_detect::@2#0] -- register_copy 
    // smc_detect::@2
  __b2:
    // smc_detect::@return
    // }
    // [715] return 
    rts
  .segment Data
    // When the bootloader is not present, 0xFF is returned.
    .label smc_bootloader_version = return
    return: .word 0
}
.segment Code
  // display_chip_smc
display_chip_smc: {
    // display_smc_led(GREY)
    // [717] call display_smc_led
    // [1788] phi from display_chip_smc to display_smc_led [phi:display_chip_smc->display_smc_led]
    // [1788] phi display_smc_led::c#2 = GREY [phi:display_chip_smc->display_smc_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z display_smc_led.c
    jsr display_smc_led
    // [718] phi from display_chip_smc to display_chip_smc::@1 [phi:display_chip_smc->display_chip_smc::@1]
    // display_chip_smc::@1
    // display_print_chip(CHIP_SMC_X, CHIP_SMC_Y+2, CHIP_SMC_W, "SMC     ")
    // [719] call display_print_chip
    // [1794] phi from display_chip_smc::@1 to display_print_chip [phi:display_chip_smc::@1->display_print_chip]
    // [1794] phi display_print_chip::text#11 = display_chip_smc::text [phi:display_chip_smc::@1->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_print_chip.text_2
    lda #>text
    sta.z display_print_chip.text_2+1
    // [1794] phi display_print_chip::w#10 = 5 [phi:display_chip_smc::@1->display_print_chip#1] -- vbuz1=vbuc1 
    lda #5
    sta.z display_print_chip.w
    // [1794] phi display_print_chip::x#10 = 1 [phi:display_chip_smc::@1->display_print_chip#2] -- vbuz1=vbuc1 
    lda #1
    sta.z display_print_chip.x
    jsr display_print_chip
    // display_chip_smc::@return
    // }
    // [720] return 
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
    // [721] __snprintf_capacity = $ffff -- vwum1=vwuc1 
    lda #<$ffff
    sta __snprintf_capacity
    lda #>$ffff
    sta __snprintf_capacity+1
    // __snprintf_size = 0
    // [722] __snprintf_size = 0 -- vwum1=vbuc1 
    lda #<0
    sta __snprintf_size
    sta __snprintf_size+1
    // __snprintf_buffer = s
    // [723] __snprintf_buffer = info_text -- pbuz1=pbuc1 
    lda #<info_text
    sta.z __snprintf_buffer
    lda #>info_text
    sta.z __snprintf_buffer+1
    // snprintf_init::@return
    // }
    // [724] return 
    rts
}
  // printf_str
/// Print a NUL-terminated string
// void printf_str(__zp($6c) void (*putc)(char), __zp($5f) const char *s)
printf_str: {
    .label s = $5f
    .label putc = $6c
    // [726] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [726] phi printf_str::s#70 = printf_str::s#71 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [727] printf_str::c#1 = *printf_str::s#70 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta c
    // [728] printf_str::s#0 = ++ printf_str::s#70 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [729] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // printf_str::@return
    // }
    // [730] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [731] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [732] callexecute *printf_str::putc#71  -- call__deref_pprz1 
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
// void printf_uint(__zp($6c) void (*putc)(char), __mem() unsigned int uvalue, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, __mem() char format_radix)
printf_uint: {
    .label putc = $6c
    // printf_uint::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [735] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [736] utoa::value#1 = printf_uint::uvalue#16
    // [737] utoa::radix#0 = printf_uint::format_radix#16
    // [738] call utoa
    // Format number into buffer
    jsr utoa
    // printf_uint::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [739] printf_number_buffer::putc#1 = printf_uint::putc#16
    // [740] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [741] printf_number_buffer::format_min_length#1 = printf_uint::format_min_length#16
    // [742] printf_number_buffer::format_zero_padding#1 = printf_uint::format_zero_padding#16
    // [743] call printf_number_buffer
  // Print using format
    // [1868] phi from printf_uint::@2 to printf_number_buffer [phi:printf_uint::@2->printf_number_buffer]
    // [1868] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#1 [phi:printf_uint::@2->printf_number_buffer#0] -- register_copy 
    // [1868] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_uint::@2->printf_number_buffer#1] -- register_copy 
    // [1868] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#1 [phi:printf_uint::@2->printf_number_buffer#2] -- register_copy 
    // [1868] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#1 [phi:printf_uint::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uint::@return
    // }
    // [744] return 
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
// void display_info_smc(__zp($75) char info_status, __zp($56) char *info_text)
display_info_smc: {
    .label display_info_smc__8 = $75
    .label info_status = $75
    .label info_text = $56
    // unsigned char x = wherex()
    // [746] call wherex
    jsr wherex
    // [747] wherex::return#10 = wherex::return#0 -- vbum1=vbum2 
    lda wherex.return
    sta wherex.return_2
    // display_info_smc::@3
    // [748] display_info_smc::x#0 = wherex::return#10
    // unsigned char y = wherey()
    // [749] call wherey
    jsr wherey
    // [750] wherey::return#10 = wherey::return#0 -- vbum1=vbum2 
    lda wherey.return
    sta wherey.return_2
    // display_info_smc::@4
    // [751] display_info_smc::y#0 = wherey::return#10
    // status_smc = info_status
    // [752] status_smc#0 = display_info_smc::info_status#12 -- vbum1=vbuz2 
    lda.z info_status
    sta status_smc
    // display_smc_led(status_color[info_status])
    // [753] display_smc_led::c#1 = status_color[display_info_smc::info_status#12] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z display_smc_led.c
    // [754] call display_smc_led
    // [1788] phi from display_info_smc::@4 to display_smc_led [phi:display_info_smc::@4->display_smc_led]
    // [1788] phi display_smc_led::c#2 = display_smc_led::c#1 [phi:display_info_smc::@4->display_smc_led#0] -- register_copy 
    jsr display_smc_led
    // [755] phi from display_info_smc::@4 to display_info_smc::@5 [phi:display_info_smc::@4->display_info_smc::@5]
    // display_info_smc::@5
    // gotoxy(INFO_X, INFO_Y)
    // [756] call gotoxy
    // [582] phi from display_info_smc::@5 to gotoxy [phi:display_info_smc::@5->gotoxy]
    // [582] phi gotoxy::y#30 = $11 [phi:display_info_smc::@5->gotoxy#0] -- vbum1=vbuc1 
    lda #$11
    sta gotoxy.y
    // [582] phi gotoxy::x#30 = 4 [phi:display_info_smc::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.x
    jsr gotoxy
    // [757] phi from display_info_smc::@5 to display_info_smc::@6 [phi:display_info_smc::@5->display_info_smc::@6]
    // display_info_smc::@6
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [758] call printf_str
    // [725] phi from display_info_smc::@6 to printf_str [phi:display_info_smc::@6->printf_str]
    // [725] phi printf_str::putc#71 = &cputc [phi:display_info_smc::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = display_info_smc::s [phi:display_info_smc::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@7
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [759] display_info_smc::$8 = display_info_smc::info_status#12 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_info_smc__8
    // [760] printf_string::str#3 = status_text[display_info_smc::$8] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z display_info_smc__8
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [761] call printf_string
    // [1222] phi from display_info_smc::@7 to printf_string [phi:display_info_smc::@7->printf_string]
    // [1222] phi printf_string::putc#18 = &cputc [phi:display_info_smc::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1222] phi printf_string::str#18 = printf_string::str#3 [phi:display_info_smc::@7->printf_string#1] -- register_copy 
    // [1222] phi printf_string::format_justify_left#18 = 1 [phi:display_info_smc::@7->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1222] phi printf_string::format_min_length#18 = 9 [phi:display_info_smc::@7->printf_string#3] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [762] phi from display_info_smc::@7 to display_info_smc::@8 [phi:display_info_smc::@7->display_info_smc::@8]
    // display_info_smc::@8
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [763] call printf_str
    // [725] phi from display_info_smc::@8 to printf_str [phi:display_info_smc::@8->printf_str]
    // [725] phi printf_str::putc#71 = &cputc [phi:display_info_smc::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = display_info_smc::s1 [phi:display_info_smc::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@9
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [764] printf_uint::uvalue#0 = smc_file_size#12 -- vwum1=vwum2 
    lda smc_file_size_2
    sta printf_uint.uvalue
    lda smc_file_size_2+1
    sta printf_uint.uvalue+1
    // [765] call printf_uint
    // [734] phi from display_info_smc::@9 to printf_uint [phi:display_info_smc::@9->printf_uint]
    // [734] phi printf_uint::format_zero_padding#16 = 1 [phi:display_info_smc::@9->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [734] phi printf_uint::format_min_length#16 = 5 [phi:display_info_smc::@9->printf_uint#1] -- vbum1=vbuc1 
    lda #5
    sta printf_uint.format_min_length
    // [734] phi printf_uint::putc#16 = &cputc [phi:display_info_smc::@9->printf_uint#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uint.putc
    lda #>cputc
    sta.z printf_uint.putc+1
    // [734] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:display_info_smc::@9->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [734] phi printf_uint::uvalue#16 = printf_uint::uvalue#0 [phi:display_info_smc::@9->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [766] phi from display_info_smc::@9 to display_info_smc::@10 [phi:display_info_smc::@9->display_info_smc::@10]
    // display_info_smc::@10
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [767] call printf_str
    // [725] phi from display_info_smc::@10 to printf_str [phi:display_info_smc::@10->printf_str]
    // [725] phi printf_str::putc#71 = &cputc [phi:display_info_smc::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = display_info_smc::s2 [phi:display_info_smc::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@11
    // if(info_text)
    // [768] if((char *)0==display_info_smc::info_text#12) goto display_info_smc::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // display_info_smc::@2
    // printf("%-20s", info_text)
    // [769] printf_string::str#4 = display_info_smc::info_text#12 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [770] call printf_string
    // [1222] phi from display_info_smc::@2 to printf_string [phi:display_info_smc::@2->printf_string]
    // [1222] phi printf_string::putc#18 = &cputc [phi:display_info_smc::@2->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1222] phi printf_string::str#18 = printf_string::str#4 [phi:display_info_smc::@2->printf_string#1] -- register_copy 
    // [1222] phi printf_string::format_justify_left#18 = 1 [phi:display_info_smc::@2->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1222] phi printf_string::format_min_length#18 = $14 [phi:display_info_smc::@2->printf_string#3] -- vbum1=vbuc1 
    lda #$14
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_smc::@1
  __b1:
    // gotoxy(x, y)
    // [771] gotoxy::x#14 = display_info_smc::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [772] gotoxy::y#14 = display_info_smc::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [773] call gotoxy
    // [582] phi from display_info_smc::@1 to gotoxy [phi:display_info_smc::@1->gotoxy]
    // [582] phi gotoxy::y#30 = gotoxy::y#14 [phi:display_info_smc::@1->gotoxy#0] -- register_copy 
    // [582] phi gotoxy::x#30 = gotoxy::x#14 [phi:display_info_smc::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_smc::@return
    // }
    // [774] return 
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
    // display_vera_led(GREY)
    // [776] call display_vera_led
    // [1899] phi from display_chip_vera to display_vera_led [phi:display_chip_vera->display_vera_led]
    // [1899] phi display_vera_led::c#2 = GREY [phi:display_chip_vera->display_vera_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z display_vera_led.c
    jsr display_vera_led
    // [777] phi from display_chip_vera to display_chip_vera::@1 [phi:display_chip_vera->display_chip_vera::@1]
    // display_chip_vera::@1
    // display_print_chip(CHIP_VERA_X, CHIP_VERA_Y+2, CHIP_VERA_W, "VERA     ")
    // [778] call display_print_chip
    // [1794] phi from display_chip_vera::@1 to display_print_chip [phi:display_chip_vera::@1->display_print_chip]
    // [1794] phi display_print_chip::text#11 = display_chip_vera::text [phi:display_chip_vera::@1->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_print_chip.text_2
    lda #>text
    sta.z display_print_chip.text_2+1
    // [1794] phi display_print_chip::w#10 = 8 [phi:display_chip_vera::@1->display_print_chip#1] -- vbuz1=vbuc1 
    lda #8
    sta.z display_print_chip.w
    // [1794] phi display_print_chip::x#10 = 9 [phi:display_chip_vera::@1->display_print_chip#2] -- vbuz1=vbuc1 
    lda #9
    sta.z display_print_chip.x
    jsr display_print_chip
    // display_chip_vera::@return
    // }
    // [779] return 
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
// void display_info_vera(__zp($58) char info_status, __zp($44) char *info_text)
display_info_vera: {
    .label display_info_vera__8 = $58
    .label info_status = $58
    .label info_text = $44
    // unsigned char x = wherex()
    // [781] call wherex
    jsr wherex
    // [782] wherex::return#11 = wherex::return#0 -- vbum1=vbum2 
    lda wherex.return
    sta wherex.return_3
    // display_info_vera::@3
    // [783] display_info_vera::x#0 = wherex::return#11
    // unsigned char y = wherey()
    // [784] call wherey
    jsr wherey
    // [785] wherey::return#11 = wherey::return#0 -- vbum1=vbum2 
    lda wherey.return
    sta wherey.return_3
    // display_info_vera::@4
    // [786] display_info_vera::y#0 = wherey::return#11
    // status_vera = info_status
    // [787] status_vera#0 = display_info_vera::info_status#2 -- vbum1=vbuz2 
    lda.z info_status
    sta status_vera
    // display_vera_led(status_color[info_status])
    // [788] display_vera_led::c#1 = status_color[display_info_vera::info_status#2] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z display_vera_led.c
    // [789] call display_vera_led
    // [1899] phi from display_info_vera::@4 to display_vera_led [phi:display_info_vera::@4->display_vera_led]
    // [1899] phi display_vera_led::c#2 = display_vera_led::c#1 [phi:display_info_vera::@4->display_vera_led#0] -- register_copy 
    jsr display_vera_led
    // [790] phi from display_info_vera::@4 to display_info_vera::@5 [phi:display_info_vera::@4->display_info_vera::@5]
    // display_info_vera::@5
    // gotoxy(INFO_X, INFO_Y+1)
    // [791] call gotoxy
    // [582] phi from display_info_vera::@5 to gotoxy [phi:display_info_vera::@5->gotoxy]
    // [582] phi gotoxy::y#30 = $11+1 [phi:display_info_vera::@5->gotoxy#0] -- vbum1=vbuc1 
    lda #$11+1
    sta gotoxy.y
    // [582] phi gotoxy::x#30 = 4 [phi:display_info_vera::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.x
    jsr gotoxy
    // [792] phi from display_info_vera::@5 to display_info_vera::@6 [phi:display_info_vera::@5->display_info_vera::@6]
    // display_info_vera::@6
    // printf("VERA %-9s FPGA   1a000 / 1a000 ", status_text[info_status])
    // [793] call printf_str
    // [725] phi from display_info_vera::@6 to printf_str [phi:display_info_vera::@6->printf_str]
    // [725] phi printf_str::putc#71 = &cputc [phi:display_info_vera::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = display_info_vera::s [phi:display_info_vera::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@7
    // printf("VERA %-9s FPGA   1a000 / 1a000 ", status_text[info_status])
    // [794] display_info_vera::$8 = display_info_vera::info_status#2 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_info_vera__8
    // [795] printf_string::str#5 = status_text[display_info_vera::$8] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z display_info_vera__8
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [796] call printf_string
    // [1222] phi from display_info_vera::@7 to printf_string [phi:display_info_vera::@7->printf_string]
    // [1222] phi printf_string::putc#18 = &cputc [phi:display_info_vera::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1222] phi printf_string::str#18 = printf_string::str#5 [phi:display_info_vera::@7->printf_string#1] -- register_copy 
    // [1222] phi printf_string::format_justify_left#18 = 1 [phi:display_info_vera::@7->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1222] phi printf_string::format_min_length#18 = 9 [phi:display_info_vera::@7->printf_string#3] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [797] phi from display_info_vera::@7 to display_info_vera::@8 [phi:display_info_vera::@7->display_info_vera::@8]
    // display_info_vera::@8
    // printf("VERA %-9s FPGA   1a000 / 1a000 ", status_text[info_status])
    // [798] call printf_str
    // [725] phi from display_info_vera::@8 to printf_str [phi:display_info_vera::@8->printf_str]
    // [725] phi printf_str::putc#71 = &cputc [phi:display_info_vera::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = display_info_vera::s1 [phi:display_info_vera::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@9
    // if(info_text)
    // [799] if((char *)0==display_info_vera::info_text#10) goto display_info_vera::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // display_info_vera::@2
    // printf("%-20s", info_text)
    // [800] printf_string::str#6 = display_info_vera::info_text#10 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [801] call printf_string
    // [1222] phi from display_info_vera::@2 to printf_string [phi:display_info_vera::@2->printf_string]
    // [1222] phi printf_string::putc#18 = &cputc [phi:display_info_vera::@2->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1222] phi printf_string::str#18 = printf_string::str#6 [phi:display_info_vera::@2->printf_string#1] -- register_copy 
    // [1222] phi printf_string::format_justify_left#18 = 1 [phi:display_info_vera::@2->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1222] phi printf_string::format_min_length#18 = $14 [phi:display_info_vera::@2->printf_string#3] -- vbum1=vbuc1 
    lda #$14
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_vera::@1
  __b1:
    // gotoxy(x, y)
    // [802] gotoxy::x#16 = display_info_vera::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [803] gotoxy::y#16 = display_info_vera::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [804] call gotoxy
    // [582] phi from display_info_vera::@1 to gotoxy [phi:display_info_vera::@1->gotoxy]
    // [582] phi gotoxy::y#30 = gotoxy::y#16 [phi:display_info_vera::@1->gotoxy#0] -- register_copy 
    // [582] phi gotoxy::x#30 = gotoxy::x#16 [phi:display_info_vera::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_vera::@return
    // }
    // [805] return 
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
    .label rom_detect__3 = $41
    .label rom_detect__5 = $4d
    .label rom_detect__9 = $2b
    .label rom_detect__14 = $29
    .label rom_detect__15 = $63
    .label rom_detect__18 = $62
    .label rom_detect__21 = $61
    .label rom_detect__24 = $75
    // [807] phi from rom_detect to rom_detect::@1 [phi:rom_detect->rom_detect::@1]
    // [807] phi rom_detect::rom_chip#10 = 0 [phi:rom_detect->rom_detect::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // [807] phi rom_detect::rom_detect_address#10 = 0 [phi:rom_detect->rom_detect::@1#1] -- vdum1=vduc1 
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
    // [808] if(rom_detect::rom_detect_address#10<8*$80000) goto rom_detect::@2 -- vdum1_lt_vduc1_then_la1 
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
    // [809] return 
    rts
    // rom_detect::@2
  __b2:
    // rom_manufacturer_ids[rom_chip] = 0
    // [810] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = 0
    // [811] rom_device_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta rom_device_ids,y
    // rom_unlock(rom_detect_address + 0x05555, 0x90)
    // [812] rom_unlock::address#2 = rom_detect::rom_detect_address#10 + $5555 -- vduz1=vdum2_plus_vwuc1 
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
    // [813] call rom_unlock
    // [1905] phi from rom_detect::@2 to rom_unlock [phi:rom_detect::@2->rom_unlock]
    // [1905] phi rom_unlock::unlock_code#5 = $90 [phi:rom_detect::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$90
    sta.z rom_unlock.unlock_code
    // [1905] phi rom_unlock::address#5 = rom_unlock::address#2 [phi:rom_detect::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_detect::@12
    // rom_read_byte(rom_detect_address)
    // [814] rom_read_byte::address#0 = rom_detect::rom_detect_address#10 -- vduz1=vdum2 
    lda rom_detect_address
    sta.z rom_read_byte.address
    lda rom_detect_address+1
    sta.z rom_read_byte.address+1
    lda rom_detect_address+2
    sta.z rom_read_byte.address+2
    lda rom_detect_address+3
    sta.z rom_read_byte.address+3
    // [815] call rom_read_byte
    // [1915] phi from rom_detect::@12 to rom_read_byte [phi:rom_detect::@12->rom_read_byte]
    // [1915] phi rom_read_byte::address#2 = rom_read_byte::address#0 [phi:rom_detect::@12->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(rom_detect_address)
    // [816] rom_read_byte::return#2 = rom_read_byte::return#0
    // rom_detect::@13
    // [817] rom_detect::$3 = rom_read_byte::return#2 -- vbuz1=vbum2 
    lda rom_read_byte.return
    sta.z rom_detect__3
    // rom_manufacturer_ids[rom_chip] = rom_read_byte(rom_detect_address)
    // [818] rom_manufacturer_ids[rom_detect::rom_chip#10] = rom_detect::$3 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_read_byte(rom_detect_address + 1)
    // [819] rom_read_byte::address#1 = rom_detect::rom_detect_address#10 + 1 -- vduz1=vdum2_plus_1 
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
    // [820] call rom_read_byte
    // [1915] phi from rom_detect::@13 to rom_read_byte [phi:rom_detect::@13->rom_read_byte]
    // [1915] phi rom_read_byte::address#2 = rom_read_byte::address#1 [phi:rom_detect::@13->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(rom_detect_address + 1)
    // [821] rom_read_byte::return#3 = rom_read_byte::return#0
    // rom_detect::@14
    // [822] rom_detect::$5 = rom_read_byte::return#3 -- vbuz1=vbum2 
    lda rom_read_byte.return
    sta.z rom_detect__5
    // rom_device_ids[rom_chip] = rom_read_byte(rom_detect_address + 1)
    // [823] rom_device_ids[rom_detect::rom_chip#10] = rom_detect::$5 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy rom_chip
    sta rom_device_ids,y
    // rom_unlock(rom_detect_address + 0x05555, 0xF0)
    // [824] rom_unlock::address#3 = rom_detect::rom_detect_address#10 + $5555 -- vduz1=vdum2_plus_vwuc1 
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
    // [825] call rom_unlock
    // [1905] phi from rom_detect::@14 to rom_unlock [phi:rom_detect::@14->rom_unlock]
    // [1905] phi rom_unlock::unlock_code#5 = $f0 [phi:rom_detect::@14->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$f0
    sta.z rom_unlock.unlock_code
    // [1905] phi rom_unlock::address#5 = rom_unlock::address#3 [phi:rom_detect::@14->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_detect::bank_set_brom1
    // BROM = bank
    // [826] BROM = rom_detect::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // rom_detect::@11
    // rom_chip*3
    // [827] rom_detect::$14 = rom_detect::rom_chip#10 << 1 -- vbuz1=vbum2_rol_1 
    lda rom_chip
    asl
    sta.z rom_detect__14
    // [828] rom_detect::$9 = rom_detect::$14 + rom_detect::rom_chip#10 -- vbuz1=vbuz2_plus_vbum3 
    lda rom_chip
    clc
    adc.z rom_detect__14
    sta.z rom_detect__9
    // gotoxy(rom_chip*3+40, 1)
    // [829] gotoxy::x#23 = rom_detect::$9 + $28 -- vbum1=vbuz2_plus_vbuc1 
    lda #$28
    clc
    adc.z rom_detect__9
    sta gotoxy.x
    // [830] call gotoxy
    // [582] phi from rom_detect::@11 to gotoxy [phi:rom_detect::@11->gotoxy]
    // [582] phi gotoxy::y#30 = 1 [phi:rom_detect::@11->gotoxy#0] -- vbum1=vbuc1 
    lda #1
    sta gotoxy.y
    // [582] phi gotoxy::x#30 = gotoxy::x#23 [phi:rom_detect::@11->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_detect::@15
    // printf("%02x", rom_device_ids[rom_chip])
    // [831] printf_uchar::uvalue#4 = rom_device_ids[rom_detect::rom_chip#10] -- vbum1=pbuc1_derefidx_vbum2 
    ldy rom_chip
    lda rom_device_ids,y
    sta printf_uchar.uvalue
    // [832] call printf_uchar
    // [1151] phi from rom_detect::@15 to printf_uchar [phi:rom_detect::@15->printf_uchar]
    // [1151] phi printf_uchar::format_zero_padding#11 = 1 [phi:rom_detect::@15->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1151] phi printf_uchar::format_min_length#11 = 2 [phi:rom_detect::@15->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1151] phi printf_uchar::putc#11 = &cputc [phi:rom_detect::@15->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1151] phi printf_uchar::format_radix#11 = HEXADECIMAL [phi:rom_detect::@15->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1151] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#4 [phi:rom_detect::@15->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // rom_detect::@16
    // case SST39SF010A:
    //             rom_device_names[rom_chip] = "f010a";
    //             rom_size_strings[rom_chip] = "128";
    //             rom_sizes[rom_chip] = 128 * 1024;
    //             break;
    // [833] if(rom_device_ids[rom_detect::rom_chip#10]==$b5) goto rom_detect::@3 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
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
    // [834] if(rom_device_ids[rom_detect::rom_chip#10]==$b6) goto rom_detect::@4 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
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
    // [835] if(rom_device_ids[rom_detect::rom_chip#10]==$b7) goto rom_detect::@5 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b7
    beq __b5
    // rom_detect::@6
    // rom_manufacturer_ids[rom_chip] = 0
    // [836] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    sta rom_manufacturer_ids,y
    // rom_device_names[rom_chip] = "----"
    // [837] rom_device_names[rom_detect::$14] = rom_detect::$31 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__14
    lda #<rom_detect__31
    sta rom_device_names,y
    lda #>rom_detect__31
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "000"
    // [838] rom_size_strings[rom_detect::$14] = rom_detect::$32 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__32
    sta rom_size_strings,y
    lda #>rom_detect__32
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 0
    // [839] rom_detect::$24 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__24
    // [840] rom_sizes[rom_detect::$24] = 0 -- pduc1_derefidx_vbuz1=vbuc2 
    tay
    lda #0
    sta rom_sizes,y
    sta rom_sizes+1,y
    sta rom_sizes+2,y
    sta rom_sizes+3,y
    // rom_device_ids[rom_chip] = UNKNOWN
    // [841] rom_device_ids[rom_detect::rom_chip#10] = $55 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$55
    ldy rom_chip
    sta rom_device_ids,y
    // rom_detect::@7
  __b7:
    // rom_chip++;
    // [842] rom_detect::rom_chip#1 = ++ rom_detect::rom_chip#10 -- vbum1=_inc_vbum1 
    inc rom_chip
    // rom_detect::@8
    // rom_detect_address += 0x80000
    // [843] rom_detect::rom_detect_address#1 = rom_detect::rom_detect_address#10 + $80000 -- vdum1=vdum1_plus_vduc1 
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
    // [807] phi from rom_detect::@8 to rom_detect::@1 [phi:rom_detect::@8->rom_detect::@1]
    // [807] phi rom_detect::rom_chip#10 = rom_detect::rom_chip#1 [phi:rom_detect::@8->rom_detect::@1#0] -- register_copy 
    // [807] phi rom_detect::rom_detect_address#10 = rom_detect::rom_detect_address#1 [phi:rom_detect::@8->rom_detect::@1#1] -- register_copy 
    jmp __b1
    // rom_detect::@5
  __b5:
    // rom_device_names[rom_chip] = "f040"
    // [844] rom_device_names[rom_detect::$14] = rom_detect::$29 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__14
    lda #<rom_detect__29
    sta rom_device_names,y
    lda #>rom_detect__29
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "512"
    // [845] rom_size_strings[rom_detect::$14] = rom_detect::$30 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__30
    sta rom_size_strings,y
    lda #>rom_detect__30
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 512 * 1024
    // [846] rom_detect::$21 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__21
    // [847] rom_sizes[rom_detect::$21] = (unsigned long)$200*$400 -- pduc1_derefidx_vbuz1=vduc2 
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
    // [848] rom_device_names[rom_detect::$14] = rom_detect::$27 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__14
    lda #<rom_detect__27
    sta rom_device_names,y
    lda #>rom_detect__27
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "256"
    // [849] rom_size_strings[rom_detect::$14] = rom_detect::$28 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__28
    sta rom_size_strings,y
    lda #>rom_detect__28
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 256 * 1024
    // [850] rom_detect::$18 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__18
    // [851] rom_sizes[rom_detect::$18] = (unsigned long)$100*$400 -- pduc1_derefidx_vbuz1=vduc2 
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
    // [852] rom_device_names[rom_detect::$14] = rom_detect::$25 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__14
    lda #<rom_detect__25
    sta rom_device_names,y
    lda #>rom_detect__25
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "128"
    // [853] rom_size_strings[rom_detect::$14] = rom_detect::$26 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__26
    sta rom_size_strings,y
    lda #>rom_detect__26
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 128 * 1024
    // [854] rom_detect::$15 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__15
    // [855] rom_sizes[rom_detect::$15] = (unsigned long)$80*$400 -- pduc1_derefidx_vbuz1=vduc2 
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
/**
 * @brief Print all ROM chips.
 * 
 */
display_chip_rom: {
    .label display_chip_rom__4 = $29
    .label display_chip_rom__6 = $b5
    .label display_chip_rom__11 = $4d
    .label display_chip_rom__12 = $4d
    // [857] phi from display_chip_rom to display_chip_rom::@1 [phi:display_chip_rom->display_chip_rom::@1]
    // [857] phi display_chip_rom::r#2 = 0 [phi:display_chip_rom->display_chip_rom::@1#0] -- vbum1=vbuc1 
    lda #0
    sta r
    // display_chip_rom::@1
  __b1:
    // for (unsigned char r = 0; r < 8; r++)
    // [858] if(display_chip_rom::r#2<8) goto display_chip_rom::@2 -- vbum1_lt_vbuc1_then_la1 
    lda r
    cmp #8
    bcc __b2
    // display_chip_rom::@return
    // }
    // [859] return 
    rts
    // [860] phi from display_chip_rom::@1 to display_chip_rom::@2 [phi:display_chip_rom::@1->display_chip_rom::@2]
    // display_chip_rom::@2
  __b2:
    // strcpy(rom, "ROM  ")
    // [861] call strcpy
    // [1927] phi from display_chip_rom::@2 to strcpy [phi:display_chip_rom::@2->strcpy]
    jsr strcpy
    // display_chip_rom::@5
    // strcat(rom, rom_size_strings[r])
    // [862] display_chip_rom::$11 = display_chip_rom::r#2 << 1 -- vbuz1=vbum2_rol_1 
    lda r
    asl
    sta.z display_chip_rom__11
    // [863] strcat::source#0 = rom_size_strings[display_chip_rom::$11] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda rom_size_strings,y
    sta.z strcat.source
    lda rom_size_strings+1,y
    sta.z strcat.source+1
    // [864] call strcat
    // [1935] phi from display_chip_rom::@5 to strcat [phi:display_chip_rom::@5->strcat]
    jsr strcat
    // display_chip_rom::@6
    // if(r)
    // [865] if(0==display_chip_rom::r#2) goto display_chip_rom::@3 -- 0_eq_vbum1_then_la1 
    lda r
    beq __b3
    // display_chip_rom::@4
    // r+'0'
    // [866] display_chip_rom::$4 = display_chip_rom::r#2 + '0' -- vbuz1=vbum2_plus_vbuc1 
    lda #'0'
    clc
    adc r
    sta.z display_chip_rom__4
    // *(rom+3) = r+'0'
    // [867] *(display_chip_rom::rom+3) = display_chip_rom::$4 -- _deref_pbuc1=vbuz1 
    sta rom+3
    // display_chip_rom::@3
  __b3:
    // display_rom_led(r, GREY)
    // [868] display_rom_led::chip#0 = display_chip_rom::r#2 -- vbuz1=vbum2 
    lda r
    sta.z display_rom_led.chip
    // [869] call display_rom_led
    // [1947] phi from display_chip_rom::@3 to display_rom_led [phi:display_chip_rom::@3->display_rom_led]
    // [1947] phi display_rom_led::c#2 = GREY [phi:display_chip_rom::@3->display_rom_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z display_rom_led.c
    // [1947] phi display_rom_led::chip#2 = display_rom_led::chip#0 [phi:display_chip_rom::@3->display_rom_led#1] -- register_copy 
    jsr display_rom_led
    // display_chip_rom::@7
    // r*6
    // [870] display_chip_rom::$12 = display_chip_rom::$11 + display_chip_rom::r#2 -- vbuz1=vbuz1_plus_vbum2 
    lda r
    clc
    adc.z display_chip_rom__12
    sta.z display_chip_rom__12
    // [871] display_chip_rom::$6 = display_chip_rom::$12 << 1 -- vbuz1=vbuz2_rol_1 
    asl
    sta.z display_chip_rom__6
    // display_print_chip(CHIP_ROM_X+r*6, CHIP_ROM_Y+2, CHIP_ROM_W, rom)
    // [872] display_print_chip::x#2 = $14 + display_chip_rom::$6 -- vbuz1=vbuc1_plus_vbuz1 
    lda #$14
    clc
    adc.z display_print_chip.x
    sta.z display_print_chip.x
    // [873] call display_print_chip
    // [1794] phi from display_chip_rom::@7 to display_print_chip [phi:display_chip_rom::@7->display_print_chip]
    // [1794] phi display_print_chip::text#11 = display_chip_rom::rom [phi:display_chip_rom::@7->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z display_print_chip.text_2
    lda #>rom
    sta.z display_print_chip.text_2+1
    // [1794] phi display_print_chip::w#10 = 3 [phi:display_chip_rom::@7->display_print_chip#1] -- vbuz1=vbuc1 
    lda #3
    sta.z display_print_chip.w
    // [1794] phi display_print_chip::x#10 = display_print_chip::x#2 [phi:display_chip_rom::@7->display_print_chip#2] -- register_copy 
    jsr display_print_chip
    // display_chip_rom::@8
    // for (unsigned char r = 0; r < 8; r++)
    // [874] display_chip_rom::r#1 = ++ display_chip_rom::r#2 -- vbum1=_inc_vbum1 
    inc r
    // [857] phi from display_chip_rom::@8 to display_chip_rom::@1 [phi:display_chip_rom::@8->display_chip_rom::@1]
    // [857] phi display_chip_rom::r#2 = display_chip_rom::r#1 [phi:display_chip_rom::@8->display_chip_rom::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    rom: .fill $10, 0
    source: .text "ROM  "
    .byte 0
    r: .byte 0
}
.segment Code
  // display_progress_text
// void display_progress_text(__zp($5d) char **text, __zp($61) char lines)
display_progress_text: {
    .label display_progress_text__2 = $2b
    .label lines = $61
    .label text = $5d
    // [876] phi from display_progress_text to display_progress_text::@1 [phi:display_progress_text->display_progress_text::@1]
    // [876] phi display_progress_text::l#2 = 0 [phi:display_progress_text->display_progress_text::@1#0] -- vbum1=vbuc1 
    lda #0
    sta l
    // display_progress_text::@1
  __b1:
    // for(unsigned char l=0; l<lines; l++)
    // [877] if(display_progress_text::l#2<display_progress_text::lines#5) goto display_progress_text::@2 -- vbum1_lt_vbuz2_then_la1 
    lda l
    cmp.z lines
    bcc __b2
    // display_progress_text::@return
    // }
    // [878] return 
    rts
    // display_progress_text::@2
  __b2:
    // display_progress_line(l, text[l])
    // [879] display_progress_text::$2 = display_progress_text::l#2 << 1 -- vbuz1=vbum2_rol_1 
    lda l
    asl
    sta.z display_progress_text__2
    // [880] display_progress_line::line#0 = display_progress_text::l#2 -- vbuz1=vbum2 
    lda l
    sta.z display_progress_line.line
    // [881] display_progress_line::text#0 = display_progress_text::text#6[display_progress_text::$2] -- pbuz1=qbuz2_derefidx_vbuz3 
    ldy.z display_progress_text__2
    lda (text),y
    sta.z display_progress_line.text
    iny
    lda (text),y
    sta.z display_progress_line.text+1
    // [882] call display_progress_line
    jsr display_progress_line
    // display_progress_text::@3
    // for(unsigned char l=0; l<lines; l++)
    // [883] display_progress_text::l#1 = ++ display_progress_text::l#2 -- vbum1=_inc_vbum1 
    inc l
    // [876] phi from display_progress_text::@3 to display_progress_text::@1 [phi:display_progress_text::@3->display_progress_text::@1]
    // [876] phi display_progress_text::l#2 = display_progress_text::l#1 [phi:display_progress_text::@3->display_progress_text::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    l: .byte 0
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
// __mem() char util_wait_key(__zp($4b) char *info_text, __zp($48) char *filter)
util_wait_key: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 0
    .label util_wait_key__9 = $5f
    .label info_text = $4b
    .label filter = $48
    // display_info_line(info_text)
    // [885] display_info_line::info_text#0 = util_wait_key::info_text#4
    // [886] call display_info_line
    // [965] phi from util_wait_key to display_info_line [phi:util_wait_key->display_info_line]
    // [965] phi display_info_line::info_text#19 = display_info_line::info_text#0 [phi:util_wait_key->display_info_line#0] -- register_copy 
    jsr display_info_line
    // util_wait_key::bank_get_bram1
    // return BRAM;
    // [887] util_wait_key::bram#0 = BRAM -- vbum1=vbuz2 
    lda.z BRAM
    sta bram
    // util_wait_key::bank_get_brom1
    // return BROM;
    // [888] util_wait_key::bank_get_brom1_return#0 = BROM -- vbum1=vbuz2 
    lda.z BROM
    sta bank_get_brom1_return
    // util_wait_key::bank_set_bram1
    // BRAM = bank
    // [889] BRAM = util_wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // util_wait_key::bank_set_brom1
    // BROM = bank
    // [890] BROM = util_wait_key::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [891] phi from util_wait_key::@2 util_wait_key::@5 util_wait_key::bank_set_brom1 to util_wait_key::kbhit1 [phi:util_wait_key::@2/util_wait_key::@5/util_wait_key::bank_set_brom1->util_wait_key::kbhit1]
    // util_wait_key::kbhit1
  kbhit1:
    // util_wait_key::kbhit1_cbm_k_clrchn1
    // asm
    // asm { jsrCBM_CLRCHN  }
    jsr CBM_CLRCHN
    // [893] phi from util_wait_key::kbhit1_cbm_k_clrchn1 to util_wait_key::kbhit1_@2 [phi:util_wait_key::kbhit1_cbm_k_clrchn1->util_wait_key::kbhit1_@2]
    // util_wait_key::kbhit1_@2
    // cbm_k_getin()
    // [894] call cbm_k_getin
    jsr cbm_k_getin
    // [895] cbm_k_getin::return#2 = cbm_k_getin::return#1
    // util_wait_key::@4
    // [896] util_wait_key::ch#4 = cbm_k_getin::return#2 -- vwum1=vbum2 
    lda cbm_k_getin.return
    sta ch
    lda #0
    sta ch+1
    // util_wait_key::@3
    // if (filter)
    // [897] if((char *)0!=util_wait_key::filter#14) goto util_wait_key::@1 -- pbuc1_neq_pbuz1_then_la1 
    // if there is a filter, check the filter, otherwise return ch.
    lda.z filter+1
    cmp #>0
    bne __b1
    lda.z filter
    cmp #<0
    bne __b1
    // util_wait_key::@2
    // if(ch)
    // [898] if(0!=util_wait_key::ch#4) goto util_wait_key::bank_set_bram2 -- 0_neq_vwum1_then_la1 
    lda ch
    ora ch+1
    bne bank_set_bram2
    jmp kbhit1
    // util_wait_key::bank_set_bram2
  bank_set_bram2:
    // BRAM = bank
    // [899] BRAM = util_wait_key::bram#0 -- vbuz1=vbum2 
    lda bram
    sta.z BRAM
    // util_wait_key::bank_set_brom2
    // BROM = bank
    // [900] BROM = util_wait_key::bank_get_brom1_return#0 -- vbuz1=vbum2 
    lda bank_get_brom1_return
    sta.z BROM
    // util_wait_key::@return
    // }
    // [901] return 
    rts
    // util_wait_key::@1
  __b1:
    // strchr(filter, ch)
    // [902] strchr::str#0 = (const void *)util_wait_key::filter#14 -- pvoz1=pvoz2 
    lda.z filter
    sta.z strchr.str
    lda.z filter+1
    sta.z strchr.str+1
    // [903] strchr::c#0 = util_wait_key::ch#4 -- vbum1=vwum2 
    lda ch
    sta strchr.c
    // [904] call strchr
    // [1523] phi from util_wait_key::@1 to strchr [phi:util_wait_key::@1->strchr]
    // [1523] phi strchr::c#4 = strchr::c#0 [phi:util_wait_key::@1->strchr#0] -- register_copy 
    // [1523] phi strchr::str#2 = strchr::str#0 [phi:util_wait_key::@1->strchr#1] -- register_copy 
    jsr strchr
    // strchr(filter, ch)
    // [905] strchr::return#3 = strchr::return#2
    // util_wait_key::@5
    // [906] util_wait_key::$9 = strchr::return#3
    // if(strchr(filter, ch) != NULL)
    // [907] if(util_wait_key::$9!=0) goto util_wait_key::bank_set_bram2 -- pvoz1_neq_0_then_la1 
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
    .label fp = $46
    .label ram_address = $3b
    // display_info_progress("Reading SMC.BIN ... (.) data, ( ) empty")
    // [909] call display_info_progress
  // It is assume that one RAM bank is 0X2000 bytes.
    // [691] phi from smc_read to display_info_progress [phi:smc_read->display_info_progress]
    // [691] phi display_info_progress::info_text#14 = smc_read::info_text [phi:smc_read->display_info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_progress.info_text
    lda #>info_text
    sta.z display_info_progress.info_text+1
    jsr display_info_progress
    // [910] phi from smc_read to smc_read::@7 [phi:smc_read->smc_read::@7]
    // smc_read::@7
    // textcolor(WHITE)
    // [911] call textcolor
    // [564] phi from smc_read::@7 to textcolor [phi:smc_read::@7->textcolor]
    // [564] phi textcolor::color#18 = WHITE [phi:smc_read::@7->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [912] phi from smc_read::@7 to smc_read::@8 [phi:smc_read::@7->smc_read::@8]
    // smc_read::@8
    // gotoxy(x, y)
    // [913] call gotoxy
    // [582] phi from smc_read::@8 to gotoxy [phi:smc_read::@8->gotoxy]
    // [582] phi gotoxy::y#30 = PROGRESS_Y [phi:smc_read::@8->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [582] phi gotoxy::x#30 = PROGRESS_X [phi:smc_read::@8->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [914] phi from smc_read::@8 to smc_read::@9 [phi:smc_read::@8->smc_read::@9]
    // smc_read::@9
    // FILE *fp = fopen("SMC.BIN", "r")
    // [915] call fopen
    // [1967] phi from smc_read::@9 to fopen [phi:smc_read::@9->fopen]
    // [1967] phi __errno#328 = __errno#35 [phi:smc_read::@9->fopen#0] -- register_copy 
    // [1967] phi fopen::pathtoken#0 = smc_read::path [phi:smc_read::@9->fopen#1] -- pbuz1=pbuc1 
    lda #<path
    sta.z fopen.pathtoken
    lda #>path
    sta.z fopen.pathtoken+1
    jsr fopen
    // FILE *fp = fopen("SMC.BIN", "r")
    // [916] fopen::return#3 = fopen::return#2
    // smc_read::@10
    // [917] smc_read::fp#0 = fopen::return#3 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [918] if((struct $2 *)0==smc_read::fp#0) goto smc_read::@1 -- pssc1_eq_pssz1_then_la1 
    lda.z fp
    cmp #<0
    bne !+
    lda.z fp+1
    cmp #>0
    beq __b4
  !:
    // [919] phi from smc_read::@10 to smc_read::@2 [phi:smc_read::@10->smc_read::@2]
    // [919] phi smc_read::y#10 = PROGRESS_Y [phi:smc_read::@10->smc_read::@2#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [919] phi smc_read::progress_row_bytes#10 = 0 [phi:smc_read::@10->smc_read::@2#1] -- vwum1=vwuc1 
    lda #<0
    sta progress_row_bytes
    sta progress_row_bytes+1
    // [919] phi smc_read::smc_file_size#11 = 0 [phi:smc_read::@10->smc_read::@2#2] -- vwum1=vwuc1 
    sta smc_file_size
    sta smc_file_size+1
    // [919] phi smc_read::ram_address#10 = (char *)$6000 [phi:smc_read::@10->smc_read::@2#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z ram_address
    lda #>$6000
    sta.z ram_address+1
  // We read b bytes at a time, and each b bytes we plot a dot.
  // Every r bytes we move to the next line.
    // smc_read::@2
  __b2:
    // fgets(ram_address, b, fp)
    // [920] fgets::ptr#2 = smc_read::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z fgets.ptr
    lda.z ram_address+1
    sta.z fgets.ptr+1
    // [921] fgets::stream#0 = smc_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.stream
    lda.z fp+1
    sta.z fgets.stream+1
    // [922] call fgets
    // [2048] phi from smc_read::@2 to fgets [phi:smc_read::@2->fgets]
    // [2048] phi fgets::ptr#12 = fgets::ptr#2 [phi:smc_read::@2->fgets#0] -- register_copy 
    // [2048] phi fgets::size#10 = 8 [phi:smc_read::@2->fgets#1] -- vwum1=vbuc1 
    lda #<8
    sta fgets.size
    lda #>8
    sta fgets.size+1
    // [2048] phi fgets::stream#2 = fgets::stream#0 [phi:smc_read::@2->fgets#2] -- register_copy 
    jsr fgets
    // fgets(ram_address, b, fp)
    // [923] fgets::return#5 = fgets::return#1
    // smc_read::@11
    // smc_file_read = fgets(ram_address, b, fp)
    // [924] smc_read::smc_file_read#1 = fgets::return#5
    // while (smc_file_read = fgets(ram_address, b, fp))
    // [925] if(0!=smc_read::smc_file_read#1) goto smc_read::@3 -- 0_neq_vwum1_then_la1 
    lda smc_file_read
    ora smc_file_read+1
    bne __b3
    // smc_read::@4
    // fclose(fp)
    // [926] fclose::stream#0 = smc_read::fp#0
    // [927] call fclose
    // [2102] phi from smc_read::@4 to fclose [phi:smc_read::@4->fclose]
    // [2102] phi fclose::stream#2 = fclose::stream#0 [phi:smc_read::@4->fclose#0] -- register_copy 
    jsr fclose
    // [928] phi from smc_read::@4 to smc_read::@1 [phi:smc_read::@4->smc_read::@1]
    // [928] phi smc_read::return#0 = smc_read::smc_file_size#11 [phi:smc_read::@4->smc_read::@1#0] -- register_copy 
    rts
    // [928] phi from smc_read::@10 to smc_read::@1 [phi:smc_read::@10->smc_read::@1]
  __b4:
    // [928] phi smc_read::return#0 = 0 [phi:smc_read::@10->smc_read::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta return
    sta return+1
    // smc_read::@1
    // smc_read::@return
    // }
    // [929] return 
    rts
    // [930] phi from smc_read::@11 to smc_read::@3 [phi:smc_read::@11->smc_read::@3]
    // smc_read::@3
  __b3:
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [931] call snprintf_init
    jsr snprintf_init
    // [932] phi from smc_read::@3 to smc_read::@12 [phi:smc_read::@3->smc_read::@12]
    // smc_read::@12
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [933] call printf_str
    // [725] phi from smc_read::@12 to printf_str [phi:smc_read::@12->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:smc_read::@12->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = smc_read::s [phi:smc_read::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@13
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [934] printf_uint::uvalue#1 = smc_read::smc_file_read#1 -- vwum1=vwum2 
    lda smc_file_read
    sta printf_uint.uvalue
    lda smc_file_read+1
    sta printf_uint.uvalue+1
    // [935] call printf_uint
    // [734] phi from smc_read::@13 to printf_uint [phi:smc_read::@13->printf_uint]
    // [734] phi printf_uint::format_zero_padding#16 = 1 [phi:smc_read::@13->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [734] phi printf_uint::format_min_length#16 = 5 [phi:smc_read::@13->printf_uint#1] -- vbum1=vbuc1 
    lda #5
    sta printf_uint.format_min_length
    // [734] phi printf_uint::putc#16 = &snputc [phi:smc_read::@13->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [734] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:smc_read::@13->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [734] phi printf_uint::uvalue#16 = printf_uint::uvalue#1 [phi:smc_read::@13->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [936] phi from smc_read::@13 to smc_read::@14 [phi:smc_read::@13->smc_read::@14]
    // smc_read::@14
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [937] call printf_str
    // [725] phi from smc_read::@14 to printf_str [phi:smc_read::@14->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:smc_read::@14->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = s4 [phi:smc_read::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@15
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [938] printf_uint::uvalue#2 = smc_read::smc_file_size#11 -- vwum1=vwum2 
    lda smc_file_size
    sta printf_uint.uvalue
    lda smc_file_size+1
    sta printf_uint.uvalue+1
    // [939] call printf_uint
    // [734] phi from smc_read::@15 to printf_uint [phi:smc_read::@15->printf_uint]
    // [734] phi printf_uint::format_zero_padding#16 = 1 [phi:smc_read::@15->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [734] phi printf_uint::format_min_length#16 = 5 [phi:smc_read::@15->printf_uint#1] -- vbum1=vbuc1 
    lda #5
    sta printf_uint.format_min_length
    // [734] phi printf_uint::putc#16 = &snputc [phi:smc_read::@15->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [734] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:smc_read::@15->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [734] phi printf_uint::uvalue#16 = printf_uint::uvalue#2 [phi:smc_read::@15->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [940] phi from smc_read::@15 to smc_read::@16 [phi:smc_read::@15->smc_read::@16]
    // smc_read::@16
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [941] call printf_str
    // [725] phi from smc_read::@16 to printf_str [phi:smc_read::@16->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:smc_read::@16->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = s2 [phi:smc_read::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // [942] phi from smc_read::@16 to smc_read::@17 [phi:smc_read::@16->smc_read::@17]
    // smc_read::@17
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [943] call printf_uint
    // [734] phi from smc_read::@17 to printf_uint [phi:smc_read::@17->printf_uint]
    // [734] phi printf_uint::format_zero_padding#16 = 1 [phi:smc_read::@17->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [734] phi printf_uint::format_min_length#16 = 2 [phi:smc_read::@17->printf_uint#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uint.format_min_length
    // [734] phi printf_uint::putc#16 = &snputc [phi:smc_read::@17->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [734] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:smc_read::@17->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [734] phi printf_uint::uvalue#16 = 0 [phi:smc_read::@17->printf_uint#4] -- vwum1=vbuc1 
    lda #<0
    sta printf_uint.uvalue
    sta printf_uint.uvalue+1
    jsr printf_uint
    // [944] phi from smc_read::@17 to smc_read::@18 [phi:smc_read::@17->smc_read::@18]
    // smc_read::@18
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [945] call printf_str
    // [725] phi from smc_read::@18 to printf_str [phi:smc_read::@18->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:smc_read::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = s3 [phi:smc_read::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@19
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [946] printf_uint::uvalue#4 = (unsigned int)smc_read::ram_address#10 -- vwum1=vwuz2 
    lda.z ram_address
    sta printf_uint.uvalue
    lda.z ram_address+1
    sta printf_uint.uvalue+1
    // [947] call printf_uint
    // [734] phi from smc_read::@19 to printf_uint [phi:smc_read::@19->printf_uint]
    // [734] phi printf_uint::format_zero_padding#16 = 1 [phi:smc_read::@19->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [734] phi printf_uint::format_min_length#16 = 4 [phi:smc_read::@19->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [734] phi printf_uint::putc#16 = &snputc [phi:smc_read::@19->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [734] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:smc_read::@19->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [734] phi printf_uint::uvalue#16 = printf_uint::uvalue#4 [phi:smc_read::@19->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [948] phi from smc_read::@19 to smc_read::@20 [phi:smc_read::@19->smc_read::@20]
    // smc_read::@20
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [949] call printf_str
    // [725] phi from smc_read::@20 to printf_str [phi:smc_read::@20->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:smc_read::@20->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = s7 [phi:smc_read::@20->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@21
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [950] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [951] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_line(info_text)
    // [953] call display_info_line
    // [965] phi from smc_read::@21 to display_info_line [phi:smc_read::@21->display_info_line]
    // [965] phi display_info_line::info_text#19 = info_text [phi:smc_read::@21->display_info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_line.info_text
    lda #>@info_text
    sta.z display_info_line.info_text+1
    jsr display_info_line
    // smc_read::@22
    // if (progress_row_bytes == progress_row_size)
    // [954] if(smc_read::progress_row_bytes#10!=$200) goto smc_read::@5 -- vwum1_neq_vwuc1_then_la1 
    lda progress_row_bytes+1
    cmp #>$200
    bne __b5
    lda progress_row_bytes
    cmp #<$200
    bne __b5
    // smc_read::@6
    // gotoxy(x, ++y);
    // [955] smc_read::y#1 = ++ smc_read::y#10 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [956] gotoxy::y#20 = smc_read::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [957] call gotoxy
    // [582] phi from smc_read::@6 to gotoxy [phi:smc_read::@6->gotoxy]
    // [582] phi gotoxy::y#30 = gotoxy::y#20 [phi:smc_read::@6->gotoxy#0] -- register_copy 
    // [582] phi gotoxy::x#30 = PROGRESS_X [phi:smc_read::@6->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [958] phi from smc_read::@6 to smc_read::@5 [phi:smc_read::@6->smc_read::@5]
    // [958] phi smc_read::y#20 = smc_read::y#1 [phi:smc_read::@6->smc_read::@5#0] -- register_copy 
    // [958] phi smc_read::progress_row_bytes#4 = 0 [phi:smc_read::@6->smc_read::@5#1] -- vwum1=vbuc1 
    lda #<0
    sta progress_row_bytes
    sta progress_row_bytes+1
    // [958] phi from smc_read::@22 to smc_read::@5 [phi:smc_read::@22->smc_read::@5]
    // [958] phi smc_read::y#20 = smc_read::y#10 [phi:smc_read::@22->smc_read::@5#0] -- register_copy 
    // [958] phi smc_read::progress_row_bytes#4 = smc_read::progress_row_bytes#10 [phi:smc_read::@22->smc_read::@5#1] -- register_copy 
    // smc_read::@5
  __b5:
    // cputc('.')
    // [959] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [960] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // ram_address += smc_file_read
    // [962] smc_read::ram_address#1 = smc_read::ram_address#10 + smc_read::smc_file_read#1 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z ram_address
    adc smc_file_read
    sta.z ram_address
    lda.z ram_address+1
    adc smc_file_read+1
    sta.z ram_address+1
    // smc_file_size += smc_file_read
    // [963] smc_read::smc_file_size#1 = smc_read::smc_file_size#11 + smc_read::smc_file_read#1 -- vwum1=vwum1_plus_vwum2 
    clc
    lda smc_file_size
    adc smc_file_read
    sta smc_file_size
    lda smc_file_size+1
    adc smc_file_read+1
    sta smc_file_size+1
    // progress_row_bytes += smc_file_read
    // [964] smc_read::progress_row_bytes#1 = smc_read::progress_row_bytes#4 + smc_read::smc_file_read#1 -- vwum1=vwum1_plus_vwum2 
    clc
    lda progress_row_bytes
    adc smc_file_read
    sta progress_row_bytes
    lda progress_row_bytes+1
    adc smc_file_read+1
    sta progress_row_bytes+1
    // [919] phi from smc_read::@5 to smc_read::@2 [phi:smc_read::@5->smc_read::@2]
    // [919] phi smc_read::y#10 = smc_read::y#20 [phi:smc_read::@5->smc_read::@2#0] -- register_copy 
    // [919] phi smc_read::progress_row_bytes#10 = smc_read::progress_row_bytes#1 [phi:smc_read::@5->smc_read::@2#1] -- register_copy 
    // [919] phi smc_read::smc_file_size#11 = smc_read::smc_file_size#1 [phi:smc_read::@5->smc_read::@2#2] -- register_copy 
    // [919] phi smc_read::ram_address#10 = smc_read::ram_address#1 [phi:smc_read::@5->smc_read::@2#3] -- register_copy 
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
// void display_info_line(__zp($4b) char *info_text)
display_info_line: {
    .label info_text = $4b
    // unsigned char x = wherex()
    // [966] call wherex
    jsr wherex
    // [967] wherex::return#3 = wherex::return#0 -- vbum1=vbum2 
    lda wherex.return
    sta wherex.return_1
    // display_info_line::@1
    // [968] display_info_line::x#0 = wherex::return#3
    // unsigned char y = wherey()
    // [969] call wherey
    jsr wherey
    // [970] wherey::return#3 = wherey::return#0 -- vbum1=vbum2 
    lda wherey.return
    sta wherey.return_1
    // display_info_line::@2
    // [971] display_info_line::y#0 = wherey::return#3
    // gotoxy(2, PROGRESS_Y-3)
    // [972] call gotoxy
    // [582] phi from display_info_line::@2 to gotoxy [phi:display_info_line::@2->gotoxy]
    // [582] phi gotoxy::y#30 = PROGRESS_Y-3 [phi:display_info_line::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-3
    sta gotoxy.y
    // [582] phi gotoxy::x#30 = 2 [phi:display_info_line::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // display_info_line::@3
    // printf("%-65s", info_text)
    // [973] printf_string::str#2 = display_info_line::info_text#19 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [974] call printf_string
    // [1222] phi from display_info_line::@3 to printf_string [phi:display_info_line::@3->printf_string]
    // [1222] phi printf_string::putc#18 = &cputc [phi:display_info_line::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1222] phi printf_string::str#18 = printf_string::str#2 [phi:display_info_line::@3->printf_string#1] -- register_copy 
    // [1222] phi printf_string::format_justify_left#18 = 1 [phi:display_info_line::@3->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1222] phi printf_string::format_min_length#18 = $41 [phi:display_info_line::@3->printf_string#3] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_line::@4
    // gotoxy(x, y)
    // [975] gotoxy::x#12 = display_info_line::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [976] gotoxy::y#12 = display_info_line::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [977] call gotoxy
    // [582] phi from display_info_line::@4 to gotoxy [phi:display_info_line::@4->gotoxy]
    // [582] phi gotoxy::y#30 = gotoxy::y#12 [phi:display_info_line::@4->gotoxy#0] -- register_copy 
    // [582] phi gotoxy::x#30 = gotoxy::x#12 [phi:display_info_line::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_line::@return
    // }
    // [978] return 
    rts
  .segment Data
    .label x = wherex.return_1
    .label y = wherey.return_1
}
.segment Code
  // flash_smc
// __mem() unsigned int flash_smc(char x, __zp($74) char y, char w, __zp($2d) unsigned int smc_bytes_total, char b, unsigned int smc_row_total, __zp($36) char *smc_ram_ptr)
flash_smc: {
    .const smc_row_total = $200
    .label flash_smc__26 = $61
    .label flash_smc__27 = $61
    .label smc_ram_ptr = $36
    .label y = $74
    .label smc_bytes_total = $2d
    // display_info_progress("To start the SMC update, do the below action ...")
    // [980] call display_info_progress
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
    // [691] phi from flash_smc to display_info_progress [phi:flash_smc->display_info_progress]
    // [691] phi display_info_progress::info_text#14 = flash_smc::info_text [phi:flash_smc->display_info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_progress.info_text
    lda #>info_text
    sta.z display_info_progress.info_text+1
    jsr display_info_progress
    // flash_smc::@25
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [981] flash_smc::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [982] flash_smc::cx16_k_i2c_write_byte1_offset = $8f -- vbum1=vbuc1 
    lda #$8f
    sta cx16_k_i2c_write_byte1_offset
    // [983] flash_smc::cx16_k_i2c_write_byte1_value = $31 -- vbum1=vbuc1 
    lda #$31
    sta cx16_k_i2c_write_byte1_value
    // flash_smc::cx16_k_i2c_write_byte1
    // unsigned char result
    // [984] flash_smc::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
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
    // [986] flash_smc::cx16_k_i2c_write_byte1_return#0 = flash_smc::cx16_k_i2c_write_byte1_result -- vbum1=vbum2 
    lda cx16_k_i2c_write_byte1_result
    sta cx16_k_i2c_write_byte1_return
    // flash_smc::cx16_k_i2c_write_byte1_@return
    // }
    // [987] flash_smc::cx16_k_i2c_write_byte1_return#1 = flash_smc::cx16_k_i2c_write_byte1_return#0
    // flash_smc::@22
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [988] flash_smc::smc_bootloader_start#0 = flash_smc::cx16_k_i2c_write_byte1_return#1
    // if(smc_bootloader_start)
    // [989] if(0==flash_smc::smc_bootloader_start#0) goto flash_smc::@3 -- 0_eq_vbum1_then_la1 
    lda smc_bootloader_start
    beq __b6
    // [990] phi from flash_smc::@22 to flash_smc::@2 [phi:flash_smc::@22->flash_smc::@2]
    // flash_smc::@2
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [991] call snprintf_init
    jsr snprintf_init
    // [992] phi from flash_smc::@2 to flash_smc::@26 [phi:flash_smc::@2->flash_smc::@26]
    // flash_smc::@26
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [993] call printf_str
    // [725] phi from flash_smc::@26 to printf_str [phi:flash_smc::@26->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:flash_smc::@26->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = flash_smc::s [phi:flash_smc::@26->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@27
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [994] printf_uchar::uvalue#1 = flash_smc::smc_bootloader_start#0
    // [995] call printf_uchar
    // [1151] phi from flash_smc::@27 to printf_uchar [phi:flash_smc::@27->printf_uchar]
    // [1151] phi printf_uchar::format_zero_padding#11 = 0 [phi:flash_smc::@27->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1151] phi printf_uchar::format_min_length#11 = 0 [phi:flash_smc::@27->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1151] phi printf_uchar::putc#11 = &snputc [phi:flash_smc::@27->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1151] phi printf_uchar::format_radix#11 = HEXADECIMAL [phi:flash_smc::@27->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1151] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#1 [phi:flash_smc::@27->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // flash_smc::@28
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [996] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [997] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_line(info_text)
    // [999] call display_info_line
    // [965] phi from flash_smc::@28 to display_info_line [phi:flash_smc::@28->display_info_line]
    // [965] phi display_info_line::info_text#19 = info_text [phi:flash_smc::@28->display_info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_line.info_text
    lda #>@info_text
    sta.z display_info_line.info_text+1
    jsr display_info_line
    // flash_smc::@29
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [1000] flash_smc::cx16_k_i2c_write_byte2_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte2_device
    // [1001] flash_smc::cx16_k_i2c_write_byte2_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte2_offset
    // [1002] flash_smc::cx16_k_i2c_write_byte2_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte2_value
    // flash_smc::cx16_k_i2c_write_byte2
    // unsigned char result
    // [1003] flash_smc::cx16_k_i2c_write_byte2_result = 0 -- vbum1=vbuc1 
    sta cx16_k_i2c_write_byte2_result
    // asm
    // asm { ldxdevice ldyoffset ldavalue stzresult jsrCX16_I2C_WRITE_BYTE rolresult  }
    ldx cx16_k_i2c_write_byte2_device
    ldy cx16_k_i2c_write_byte2_offset
    lda cx16_k_i2c_write_byte2_value
    stz cx16_k_i2c_write_byte2_result
    jsr CX16_I2C_WRITE_BYTE
    rol cx16_k_i2c_write_byte2_result
    // [1005] phi from flash_smc::@47 flash_smc::@59 flash_smc::cx16_k_i2c_write_byte2 to flash_smc::@return [phi:flash_smc::@47/flash_smc::@59/flash_smc::cx16_k_i2c_write_byte2->flash_smc::@return]
  __b2:
    // [1005] phi flash_smc::return#1 = 0 [phi:flash_smc::@47/flash_smc::@59/flash_smc::cx16_k_i2c_write_byte2->flash_smc::@return#0] -- vwum1=vbuc1 
    lda #<0
    sta return
    sta return+1
    // flash_smc::@return
    // }
    // [1006] return 
    rts
    // [1007] phi from flash_smc::@22 to flash_smc::@3 [phi:flash_smc::@22->flash_smc::@3]
  __b6:
    // [1007] phi flash_smc::smc_bootloader_activation_countdown#10 = $3c [phi:flash_smc::@22->flash_smc::@3#0] -- vbum1=vbuc1 
    lda #$3c
    sta smc_bootloader_activation_countdown
    // flash_smc::@3
  __b3:
    // while(smc_bootloader_activation_countdown)
    // [1008] if(0!=flash_smc::smc_bootloader_activation_countdown#10) goto flash_smc::@4 -- 0_neq_vbum1_then_la1 
    lda smc_bootloader_activation_countdown
    beq !__b4+
    jmp __b4
  !__b4:
    // [1009] phi from flash_smc::@3 flash_smc::@30 to flash_smc::@7 [phi:flash_smc::@3/flash_smc::@30->flash_smc::@7]
  __b9:
    // [1009] phi flash_smc::smc_bootloader_activation_countdown#12 = $a [phi:flash_smc::@3/flash_smc::@30->flash_smc::@7#0] -- vbum1=vbuc1 
    lda #$a
    sta smc_bootloader_activation_countdown_1
    // flash_smc::@7
  __b7:
    // while(smc_bootloader_activation_countdown)
    // [1010] if(0!=flash_smc::smc_bootloader_activation_countdown#12) goto flash_smc::@8 -- 0_neq_vbum1_then_la1 
    lda smc_bootloader_activation_countdown_1
    beq !__b8+
    jmp __b8
  !__b8:
    // flash_smc::@9
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1011] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1012] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [1013] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [1014] cx16_k_i2c_read_byte::return#3 = cx16_k_i2c_read_byte::return#1
    // flash_smc::@42
    // smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1015] flash_smc::smc_bootloader_not_activated#1 = cx16_k_i2c_read_byte::return#3
    // if(smc_bootloader_not_activated)
    // [1016] if(0==flash_smc::smc_bootloader_not_activated#1) goto flash_smc::@1 -- 0_eq_vwum1_then_la1 
    lda smc_bootloader_not_activated
    ora smc_bootloader_not_activated+1
    beq __b1
    // [1017] phi from flash_smc::@42 to flash_smc::@10 [phi:flash_smc::@42->flash_smc::@10]
    // flash_smc::@10
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1018] call snprintf_init
    jsr snprintf_init
    // [1019] phi from flash_smc::@10 to flash_smc::@45 [phi:flash_smc::@10->flash_smc::@45]
    // flash_smc::@45
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1020] call printf_str
    // [725] phi from flash_smc::@45 to printf_str [phi:flash_smc::@45->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:flash_smc::@45->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = flash_smc::s5 [phi:flash_smc::@45->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@46
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1021] printf_uint::uvalue#5 = flash_smc::smc_bootloader_not_activated#1
    // [1022] call printf_uint
    // [734] phi from flash_smc::@46 to printf_uint [phi:flash_smc::@46->printf_uint]
    // [734] phi printf_uint::format_zero_padding#16 = 0 [phi:flash_smc::@46->printf_uint#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uint.format_zero_padding
    // [734] phi printf_uint::format_min_length#16 = 0 [phi:flash_smc::@46->printf_uint#1] -- vbum1=vbuc1 
    sta printf_uint.format_min_length
    // [734] phi printf_uint::putc#16 = &snputc [phi:flash_smc::@46->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [734] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:flash_smc::@46->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [734] phi printf_uint::uvalue#16 = printf_uint::uvalue#5 [phi:flash_smc::@46->printf_uint#4] -- register_copy 
    jsr printf_uint
    // flash_smc::@47
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1023] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1024] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_line(info_text)
    // [1026] call display_info_line
    // [965] phi from flash_smc::@47 to display_info_line [phi:flash_smc::@47->display_info_line]
    // [965] phi display_info_line::info_text#19 = info_text [phi:flash_smc::@47->display_info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_line.info_text
    lda #>@info_text
    sta.z display_info_line.info_text+1
    jsr display_info_line
    jmp __b2
    // [1027] phi from flash_smc::@42 to flash_smc::@1 [phi:flash_smc::@42->flash_smc::@1]
    // flash_smc::@1
  __b1:
    // display_info_progress("Updating SMC firmware ... (+) Updated")
    // [1028] call display_info_progress
    // [691] phi from flash_smc::@1 to display_info_progress [phi:flash_smc::@1->display_info_progress]
    // [691] phi display_info_progress::info_text#14 = flash_smc::info_text1 [phi:flash_smc::@1->display_info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_progress.info_text
    lda #>info_text1
    sta.z display_info_progress.info_text+1
    jsr display_info_progress
    // [1029] phi from flash_smc::@1 to flash_smc::@43 [phi:flash_smc::@1->flash_smc::@43]
    // flash_smc::@43
    // textcolor(WHITE)
    // [1030] call textcolor
    // [564] phi from flash_smc::@43 to textcolor [phi:flash_smc::@43->textcolor]
    // [564] phi textcolor::color#18 = WHITE [phi:flash_smc::@43->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [1031] phi from flash_smc::@43 to flash_smc::@44 [phi:flash_smc::@43->flash_smc::@44]
    // flash_smc::@44
    // gotoxy(x, y)
    // [1032] call gotoxy
    // [582] phi from flash_smc::@44 to gotoxy [phi:flash_smc::@44->gotoxy]
    // [582] phi gotoxy::y#30 = PROGRESS_Y [phi:flash_smc::@44->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [582] phi gotoxy::x#30 = PROGRESS_X [phi:flash_smc::@44->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1033] phi from flash_smc::@44 to flash_smc::@11 [phi:flash_smc::@44->flash_smc::@11]
    // [1033] phi flash_smc::y#31 = PROGRESS_Y [phi:flash_smc::@44->flash_smc::@11#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // [1033] phi flash_smc::smc_attempts_total#21 = 0 [phi:flash_smc::@44->flash_smc::@11#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_attempts_total
    sta smc_attempts_total+1
    // [1033] phi flash_smc::smc_row_bytes#14 = 0 [phi:flash_smc::@44->flash_smc::@11#2] -- vwum1=vwuc1 
    sta smc_row_bytes
    sta smc_row_bytes+1
    // [1033] phi flash_smc::smc_ram_ptr#13 = (char *)$6000 [phi:flash_smc::@44->flash_smc::@11#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z smc_ram_ptr
    lda #>$6000
    sta.z smc_ram_ptr+1
    // [1033] phi flash_smc::smc_bytes_flashed#16 = 0 [phi:flash_smc::@44->flash_smc::@11#4] -- vwum1=vwuc1 
    lda #<0
    sta smc_bytes_flashed
    sta smc_bytes_flashed+1
    // [1033] phi from flash_smc::@13 to flash_smc::@11 [phi:flash_smc::@13->flash_smc::@11]
    // [1033] phi flash_smc::y#31 = flash_smc::y#20 [phi:flash_smc::@13->flash_smc::@11#0] -- register_copy 
    // [1033] phi flash_smc::smc_attempts_total#21 = flash_smc::smc_attempts_total#17 [phi:flash_smc::@13->flash_smc::@11#1] -- register_copy 
    // [1033] phi flash_smc::smc_row_bytes#14 = flash_smc::smc_row_bytes#10 [phi:flash_smc::@13->flash_smc::@11#2] -- register_copy 
    // [1033] phi flash_smc::smc_ram_ptr#13 = flash_smc::smc_ram_ptr#10 [phi:flash_smc::@13->flash_smc::@11#3] -- register_copy 
    // [1033] phi flash_smc::smc_bytes_flashed#16 = flash_smc::smc_bytes_flashed#11 [phi:flash_smc::@13->flash_smc::@11#4] -- register_copy 
    // flash_smc::@11
  __b11:
    // while(smc_bytes_flashed < smc_bytes_total)
    // [1034] if(flash_smc::smc_bytes_flashed#16<flash_smc::smc_bytes_total#0) goto flash_smc::@12 -- vwum1_lt_vwuz2_then_la1 
    lda smc_bytes_flashed+1
    cmp.z smc_bytes_total+1
    bcc __b10
    bne !+
    lda smc_bytes_flashed
    cmp.z smc_bytes_total
    bcc __b10
  !:
    // [1005] phi from flash_smc::@11 to flash_smc::@return [phi:flash_smc::@11->flash_smc::@return]
    // [1005] phi flash_smc::return#1 = flash_smc::smc_bytes_flashed#16 [phi:flash_smc::@11->flash_smc::@return#0] -- register_copy 
    rts
    // [1035] phi from flash_smc::@11 to flash_smc::@12 [phi:flash_smc::@11->flash_smc::@12]
  __b10:
    // [1035] phi flash_smc::y#20 = flash_smc::y#31 [phi:flash_smc::@11->flash_smc::@12#0] -- register_copy 
    // [1035] phi flash_smc::smc_attempts_total#17 = flash_smc::smc_attempts_total#21 [phi:flash_smc::@11->flash_smc::@12#1] -- register_copy 
    // [1035] phi flash_smc::smc_row_bytes#10 = flash_smc::smc_row_bytes#14 [phi:flash_smc::@11->flash_smc::@12#2] -- register_copy 
    // [1035] phi flash_smc::smc_ram_ptr#10 = flash_smc::smc_ram_ptr#13 [phi:flash_smc::@11->flash_smc::@12#3] -- register_copy 
    // [1035] phi flash_smc::smc_bytes_flashed#11 = flash_smc::smc_bytes_flashed#16 [phi:flash_smc::@11->flash_smc::@12#4] -- register_copy 
    // [1035] phi flash_smc::smc_attempts_flashed#19 = 0 [phi:flash_smc::@11->flash_smc::@12#5] -- vbum1=vbuc1 
    lda #0
    sta smc_attempts_flashed
    // [1035] phi flash_smc::smc_package_committed#2 = 0 [phi:flash_smc::@11->flash_smc::@12#6] -- vbum1=vbuc1 
    sta smc_package_committed
    // flash_smc::@12
  __b12:
    // while(!smc_package_committed && smc_attempts_flashed < 10)
    // [1036] if(0!=flash_smc::smc_package_committed#2) goto flash_smc::@13 -- 0_neq_vbum1_then_la1 
    lda smc_package_committed
    bne __b13
    // flash_smc::@60
    // [1037] if(flash_smc::smc_attempts_flashed#19<$a) goto flash_smc::@14 -- vbum1_lt_vbuc1_then_la1 
    lda smc_attempts_flashed
    cmp #$a
    bcc __b16
    // flash_smc::@13
  __b13:
    // if(smc_attempts_flashed >= 10)
    // [1038] if(flash_smc::smc_attempts_flashed#19<$a) goto flash_smc::@11 -- vbum1_lt_vbuc1_then_la1 
    lda smc_attempts_flashed
    cmp #$a
    bcc __b11
    // [1039] phi from flash_smc::@13 to flash_smc::@21 [phi:flash_smc::@13->flash_smc::@21]
    // flash_smc::@21
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1040] call snprintf_init
    jsr snprintf_init
    // [1041] phi from flash_smc::@21 to flash_smc::@57 [phi:flash_smc::@21->flash_smc::@57]
    // flash_smc::@57
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1042] call printf_str
    // [725] phi from flash_smc::@57 to printf_str [phi:flash_smc::@57->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:flash_smc::@57->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = flash_smc::s10 [phi:flash_smc::@57->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@58
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1043] printf_uint::uvalue#9 = flash_smc::smc_bytes_flashed#11 -- vwum1=vwum2 
    lda smc_bytes_flashed
    sta printf_uint.uvalue
    lda smc_bytes_flashed+1
    sta printf_uint.uvalue+1
    // [1044] call printf_uint
    // [734] phi from flash_smc::@58 to printf_uint [phi:flash_smc::@58->printf_uint]
    // [734] phi printf_uint::format_zero_padding#16 = 1 [phi:flash_smc::@58->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [734] phi printf_uint::format_min_length#16 = 4 [phi:flash_smc::@58->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [734] phi printf_uint::putc#16 = &snputc [phi:flash_smc::@58->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [734] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:flash_smc::@58->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [734] phi printf_uint::uvalue#16 = printf_uint::uvalue#9 [phi:flash_smc::@58->printf_uint#4] -- register_copy 
    jsr printf_uint
    // flash_smc::@59
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1045] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1046] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_line(info_text)
    // [1048] call display_info_line
    // [965] phi from flash_smc::@59 to display_info_line [phi:flash_smc::@59->display_info_line]
    // [965] phi display_info_line::info_text#19 = info_text [phi:flash_smc::@59->display_info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_line.info_text
    lda #>@info_text
    sta.z display_info_line.info_text+1
    jsr display_info_line
    jmp __b2
    // [1049] phi from flash_smc::@60 to flash_smc::@14 [phi:flash_smc::@60->flash_smc::@14]
  __b16:
    // [1049] phi flash_smc::smc_bytes_checksum#2 = 0 [phi:flash_smc::@60->flash_smc::@14#0] -- vbum1=vbuc1 
    lda #0
    sta smc_bytes_checksum
    // [1049] phi flash_smc::smc_ram_ptr#12 = flash_smc::smc_ram_ptr#10 [phi:flash_smc::@60->flash_smc::@14#1] -- register_copy 
    // [1049] phi flash_smc::smc_package_flashed#2 = 0 [phi:flash_smc::@60->flash_smc::@14#2] -- vwum1=vwuc1 
    sta smc_package_flashed
    sta smc_package_flashed+1
    // flash_smc::@14
  __b14:
    // while(smc_package_flashed < 8)
    // [1050] if(flash_smc::smc_package_flashed#2<8) goto flash_smc::@15 -- vwum1_lt_vbuc1_then_la1 
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
    // [1051] flash_smc::$26 = flash_smc::smc_bytes_checksum#2 ^ $ff -- vbuz1=vbum2_bxor_vbuc1 
    lda #$ff
    eor smc_bytes_checksum
    sta.z flash_smc__26
    // (smc_bytes_checksum ^ 0xFF)+1
    // [1052] flash_smc::$27 = flash_smc::$26 + 1 -- vbuz1=vbuz1_plus_1 
    inc.z flash_smc__27
    // unsigned char smc_checksum_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, (smc_bytes_checksum ^ 0xFF)+1)
    // [1053] flash_smc::cx16_k_i2c_write_byte4_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte4_device
    // [1054] flash_smc::cx16_k_i2c_write_byte4_offset = $80 -- vbum1=vbuc1 
    lda #$80
    sta cx16_k_i2c_write_byte4_offset
    // [1055] flash_smc::cx16_k_i2c_write_byte4_value = flash_smc::$27 -- vbum1=vbuz2 
    lda.z flash_smc__27
    sta cx16_k_i2c_write_byte4_value
    // flash_smc::cx16_k_i2c_write_byte4
    // unsigned char result
    // [1056] flash_smc::cx16_k_i2c_write_byte4_result = 0 -- vbum1=vbuc1 
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
    // [1058] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1059] cx16_k_i2c_read_byte::offset = $81 -- vbum1=vbuc1 
    lda #$81
    sta cx16_k_i2c_read_byte.offset
    // [1060] call cx16_k_i2c_read_byte
    // Now send the commit command.
    jsr cx16_k_i2c_read_byte
    // [1061] cx16_k_i2c_read_byte::return#4 = cx16_k_i2c_read_byte::return#1
    // flash_smc::@48
    // [1062] flash_smc::smc_commit_result#0 = cx16_k_i2c_read_byte::return#4
    // if(smc_commit_result == 1)
    // [1063] if(flash_smc::smc_commit_result#0==1) goto flash_smc::@18 -- vwum1_eq_vbuc1_then_la1 
    lda smc_commit_result+1
    bne !+
    lda smc_commit_result
    cmp #1
    beq __b18
  !:
    // flash_smc::@17
    // smc_ram_ptr -= 8
    // [1064] flash_smc::smc_ram_ptr#1 = flash_smc::smc_ram_ptr#12 - 8 -- pbuz1=pbuz1_minus_vbuc1 
    sec
    lda.z smc_ram_ptr
    sbc #8
    sta.z smc_ram_ptr
    lda.z smc_ram_ptr+1
    sbc #0
    sta.z smc_ram_ptr+1
    // smc_attempts_flashed++;
    // [1065] flash_smc::smc_attempts_flashed#1 = ++ flash_smc::smc_attempts_flashed#19 -- vbum1=_inc_vbum1 
    inc smc_attempts_flashed
    // [1035] phi from flash_smc::@17 to flash_smc::@12 [phi:flash_smc::@17->flash_smc::@12]
    // [1035] phi flash_smc::y#20 = flash_smc::y#20 [phi:flash_smc::@17->flash_smc::@12#0] -- register_copy 
    // [1035] phi flash_smc::smc_attempts_total#17 = flash_smc::smc_attempts_total#17 [phi:flash_smc::@17->flash_smc::@12#1] -- register_copy 
    // [1035] phi flash_smc::smc_row_bytes#10 = flash_smc::smc_row_bytes#10 [phi:flash_smc::@17->flash_smc::@12#2] -- register_copy 
    // [1035] phi flash_smc::smc_ram_ptr#10 = flash_smc::smc_ram_ptr#1 [phi:flash_smc::@17->flash_smc::@12#3] -- register_copy 
    // [1035] phi flash_smc::smc_bytes_flashed#11 = flash_smc::smc_bytes_flashed#11 [phi:flash_smc::@17->flash_smc::@12#4] -- register_copy 
    // [1035] phi flash_smc::smc_attempts_flashed#19 = flash_smc::smc_attempts_flashed#1 [phi:flash_smc::@17->flash_smc::@12#5] -- register_copy 
    // [1035] phi flash_smc::smc_package_committed#2 = flash_smc::smc_package_committed#2 [phi:flash_smc::@17->flash_smc::@12#6] -- register_copy 
    jmp __b12
    // flash_smc::@18
  __b18:
    // if (smc_row_bytes == smc_row_total)
    // [1066] if(flash_smc::smc_row_bytes#10!=flash_smc::smc_row_total#0) goto flash_smc::@19 -- vwum1_neq_vwuc1_then_la1 
    lda smc_row_bytes+1
    cmp #>smc_row_total
    bne __b19
    lda smc_row_bytes
    cmp #<smc_row_total
    bne __b19
    // flash_smc::@20
    // gotoxy(x, ++y);
    // [1067] flash_smc::y#0 = ++ flash_smc::y#20 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [1068] gotoxy::y#22 = flash_smc::y#0 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [1069] call gotoxy
    // [582] phi from flash_smc::@20 to gotoxy [phi:flash_smc::@20->gotoxy]
    // [582] phi gotoxy::y#30 = gotoxy::y#22 [phi:flash_smc::@20->gotoxy#0] -- register_copy 
    // [582] phi gotoxy::x#30 = PROGRESS_X [phi:flash_smc::@20->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1070] phi from flash_smc::@20 to flash_smc::@19 [phi:flash_smc::@20->flash_smc::@19]
    // [1070] phi flash_smc::y#33 = flash_smc::y#0 [phi:flash_smc::@20->flash_smc::@19#0] -- register_copy 
    // [1070] phi flash_smc::smc_row_bytes#4 = 0 [phi:flash_smc::@20->flash_smc::@19#1] -- vwum1=vbuc1 
    lda #<0
    sta smc_row_bytes
    sta smc_row_bytes+1
    // [1070] phi from flash_smc::@18 to flash_smc::@19 [phi:flash_smc::@18->flash_smc::@19]
    // [1070] phi flash_smc::y#33 = flash_smc::y#20 [phi:flash_smc::@18->flash_smc::@19#0] -- register_copy 
    // [1070] phi flash_smc::smc_row_bytes#4 = flash_smc::smc_row_bytes#10 [phi:flash_smc::@18->flash_smc::@19#1] -- register_copy 
    // flash_smc::@19
  __b19:
    // cputc('+')
    // [1071] stackpush(char) = '+' -- _stackpushbyte_=vbuc1 
    lda #'+'
    pha
    // [1072] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_bytes_flashed += 8
    // [1074] flash_smc::smc_bytes_flashed#1 = flash_smc::smc_bytes_flashed#11 + 8 -- vwum1=vwum1_plus_vbuc1 
    lda #8
    clc
    adc smc_bytes_flashed
    sta smc_bytes_flashed
    bcc !+
    inc smc_bytes_flashed+1
  !:
    // smc_row_bytes += 8
    // [1075] flash_smc::smc_row_bytes#1 = flash_smc::smc_row_bytes#4 + 8 -- vwum1=vwum1_plus_vbuc1 
    lda #8
    clc
    adc smc_row_bytes
    sta smc_row_bytes
    bcc !+
    inc smc_row_bytes+1
  !:
    // smc_attempts_total += smc_attempts_flashed
    // [1076] flash_smc::smc_attempts_total#1 = flash_smc::smc_attempts_total#17 + flash_smc::smc_attempts_flashed#19 -- vwum1=vwum1_plus_vbum2 
    lda smc_attempts_flashed
    clc
    adc smc_attempts_total
    sta smc_attempts_total
    bcc !+
    inc smc_attempts_total+1
  !:
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1077] call snprintf_init
    jsr snprintf_init
    // [1078] phi from flash_smc::@19 to flash_smc::@49 [phi:flash_smc::@19->flash_smc::@49]
    // flash_smc::@49
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1079] call printf_str
    // [725] phi from flash_smc::@49 to printf_str [phi:flash_smc::@49->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:flash_smc::@49->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = flash_smc::s6 [phi:flash_smc::@49->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@50
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1080] printf_uint::uvalue#6 = flash_smc::smc_bytes_flashed#1 -- vwum1=vwum2 
    lda smc_bytes_flashed
    sta printf_uint.uvalue
    lda smc_bytes_flashed+1
    sta printf_uint.uvalue+1
    // [1081] call printf_uint
    // [734] phi from flash_smc::@50 to printf_uint [phi:flash_smc::@50->printf_uint]
    // [734] phi printf_uint::format_zero_padding#16 = 1 [phi:flash_smc::@50->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [734] phi printf_uint::format_min_length#16 = 5 [phi:flash_smc::@50->printf_uint#1] -- vbum1=vbuc1 
    lda #5
    sta printf_uint.format_min_length
    // [734] phi printf_uint::putc#16 = &snputc [phi:flash_smc::@50->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [734] phi printf_uint::format_radix#16 = DECIMAL [phi:flash_smc::@50->printf_uint#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uint.format_radix
    // [734] phi printf_uint::uvalue#16 = printf_uint::uvalue#6 [phi:flash_smc::@50->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1082] phi from flash_smc::@50 to flash_smc::@51 [phi:flash_smc::@50->flash_smc::@51]
    // flash_smc::@51
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1083] call printf_str
    // [725] phi from flash_smc::@51 to printf_str [phi:flash_smc::@51->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:flash_smc::@51->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = flash_smc::s7 [phi:flash_smc::@51->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@52
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1084] printf_uint::uvalue#7 = flash_smc::smc_bytes_total#0 -- vwum1=vwuz2 
    lda.z smc_bytes_total
    sta printf_uint.uvalue
    lda.z smc_bytes_total+1
    sta printf_uint.uvalue+1
    // [1085] call printf_uint
    // [734] phi from flash_smc::@52 to printf_uint [phi:flash_smc::@52->printf_uint]
    // [734] phi printf_uint::format_zero_padding#16 = 1 [phi:flash_smc::@52->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [734] phi printf_uint::format_min_length#16 = 5 [phi:flash_smc::@52->printf_uint#1] -- vbum1=vbuc1 
    lda #5
    sta printf_uint.format_min_length
    // [734] phi printf_uint::putc#16 = &snputc [phi:flash_smc::@52->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [734] phi printf_uint::format_radix#16 = DECIMAL [phi:flash_smc::@52->printf_uint#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uint.format_radix
    // [734] phi printf_uint::uvalue#16 = printf_uint::uvalue#7 [phi:flash_smc::@52->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1086] phi from flash_smc::@52 to flash_smc::@53 [phi:flash_smc::@52->flash_smc::@53]
    // flash_smc::@53
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1087] call printf_str
    // [725] phi from flash_smc::@53 to printf_str [phi:flash_smc::@53->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:flash_smc::@53->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = flash_smc::s8 [phi:flash_smc::@53->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@54
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1088] printf_uint::uvalue#8 = flash_smc::smc_attempts_total#1 -- vwum1=vwum2 
    lda smc_attempts_total
    sta printf_uint.uvalue
    lda smc_attempts_total+1
    sta printf_uint.uvalue+1
    // [1089] call printf_uint
    // [734] phi from flash_smc::@54 to printf_uint [phi:flash_smc::@54->printf_uint]
    // [734] phi printf_uint::format_zero_padding#16 = 1 [phi:flash_smc::@54->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [734] phi printf_uint::format_min_length#16 = 2 [phi:flash_smc::@54->printf_uint#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uint.format_min_length
    // [734] phi printf_uint::putc#16 = &snputc [phi:flash_smc::@54->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [734] phi printf_uint::format_radix#16 = DECIMAL [phi:flash_smc::@54->printf_uint#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uint.format_radix
    // [734] phi printf_uint::uvalue#16 = printf_uint::uvalue#8 [phi:flash_smc::@54->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1090] phi from flash_smc::@54 to flash_smc::@55 [phi:flash_smc::@54->flash_smc::@55]
    // flash_smc::@55
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1091] call printf_str
    // [725] phi from flash_smc::@55 to printf_str [phi:flash_smc::@55->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:flash_smc::@55->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = flash_smc::s9 [phi:flash_smc::@55->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@56
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1092] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1093] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_line(info_text)
    // [1095] call display_info_line
    // [965] phi from flash_smc::@56 to display_info_line [phi:flash_smc::@56->display_info_line]
    // [965] phi display_info_line::info_text#19 = info_text [phi:flash_smc::@56->display_info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_line.info_text
    lda #>@info_text
    sta.z display_info_line.info_text+1
    jsr display_info_line
    // [1035] phi from flash_smc::@56 to flash_smc::@12 [phi:flash_smc::@56->flash_smc::@12]
    // [1035] phi flash_smc::y#20 = flash_smc::y#33 [phi:flash_smc::@56->flash_smc::@12#0] -- register_copy 
    // [1035] phi flash_smc::smc_attempts_total#17 = flash_smc::smc_attempts_total#1 [phi:flash_smc::@56->flash_smc::@12#1] -- register_copy 
    // [1035] phi flash_smc::smc_row_bytes#10 = flash_smc::smc_row_bytes#1 [phi:flash_smc::@56->flash_smc::@12#2] -- register_copy 
    // [1035] phi flash_smc::smc_ram_ptr#10 = flash_smc::smc_ram_ptr#12 [phi:flash_smc::@56->flash_smc::@12#3] -- register_copy 
    // [1035] phi flash_smc::smc_bytes_flashed#11 = flash_smc::smc_bytes_flashed#1 [phi:flash_smc::@56->flash_smc::@12#4] -- register_copy 
    // [1035] phi flash_smc::smc_attempts_flashed#19 = flash_smc::smc_attempts_flashed#19 [phi:flash_smc::@56->flash_smc::@12#5] -- register_copy 
    // [1035] phi flash_smc::smc_package_committed#2 = 1 [phi:flash_smc::@56->flash_smc::@12#6] -- vbum1=vbuc1 
    lda #1
    sta smc_package_committed
    jmp __b12
    // flash_smc::@15
  __b15:
    // unsigned char smc_byte_upload = *smc_ram_ptr
    // [1096] flash_smc::smc_byte_upload#0 = *flash_smc::smc_ram_ptr#12 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (smc_ram_ptr),y
    sta smc_byte_upload
    // smc_ram_ptr++;
    // [1097] flash_smc::smc_ram_ptr#0 = ++ flash_smc::smc_ram_ptr#12 -- pbuz1=_inc_pbuz1 
    inc.z smc_ram_ptr
    bne !+
    inc.z smc_ram_ptr+1
  !:
    // smc_bytes_checksum += smc_byte_upload
    // [1098] flash_smc::smc_bytes_checksum#1 = flash_smc::smc_bytes_checksum#2 + flash_smc::smc_byte_upload#0 -- vbum1=vbum1_plus_vbum2 
    lda smc_bytes_checksum
    clc
    adc smc_byte_upload
    sta smc_bytes_checksum
    // unsigned char smc_upload_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, smc_byte_upload)
    // [1099] flash_smc::cx16_k_i2c_write_byte3_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte3_device
    // [1100] flash_smc::cx16_k_i2c_write_byte3_offset = $80 -- vbum1=vbuc1 
    lda #$80
    sta cx16_k_i2c_write_byte3_offset
    // [1101] flash_smc::cx16_k_i2c_write_byte3_value = flash_smc::smc_byte_upload#0 -- vbum1=vbum2 
    lda smc_byte_upload
    sta cx16_k_i2c_write_byte3_value
    // flash_smc::cx16_k_i2c_write_byte3
    // unsigned char result
    // [1102] flash_smc::cx16_k_i2c_write_byte3_result = 0 -- vbum1=vbuc1 
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
    // [1104] flash_smc::smc_package_flashed#1 = ++ flash_smc::smc_package_flashed#2 -- vwum1=_inc_vwum1 
    inc smc_package_flashed
    bne !+
    inc smc_package_flashed+1
  !:
    // [1049] phi from flash_smc::@23 to flash_smc::@14 [phi:flash_smc::@23->flash_smc::@14]
    // [1049] phi flash_smc::smc_bytes_checksum#2 = flash_smc::smc_bytes_checksum#1 [phi:flash_smc::@23->flash_smc::@14#0] -- register_copy 
    // [1049] phi flash_smc::smc_ram_ptr#12 = flash_smc::smc_ram_ptr#0 [phi:flash_smc::@23->flash_smc::@14#1] -- register_copy 
    // [1049] phi flash_smc::smc_package_flashed#2 = flash_smc::smc_package_flashed#1 [phi:flash_smc::@23->flash_smc::@14#2] -- register_copy 
    jmp __b14
    // [1105] phi from flash_smc::@7 to flash_smc::@8 [phi:flash_smc::@7->flash_smc::@8]
    // flash_smc::@8
  __b8:
    // wait_moment()
    // [1106] call wait_moment
    // [1146] phi from flash_smc::@8 to wait_moment [phi:flash_smc::@8->wait_moment]
    jsr wait_moment
    // [1107] phi from flash_smc::@8 to flash_smc::@36 [phi:flash_smc::@8->flash_smc::@36]
    // flash_smc::@36
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1108] call snprintf_init
    jsr snprintf_init
    // [1109] phi from flash_smc::@36 to flash_smc::@37 [phi:flash_smc::@36->flash_smc::@37]
    // flash_smc::@37
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1110] call printf_str
    // [725] phi from flash_smc::@37 to printf_str [phi:flash_smc::@37->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:flash_smc::@37->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = flash_smc::s3 [phi:flash_smc::@37->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@38
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1111] printf_uchar::uvalue#3 = flash_smc::smc_bootloader_activation_countdown#12 -- vbum1=vbum2 
    lda smc_bootloader_activation_countdown_1
    sta printf_uchar.uvalue
    // [1112] call printf_uchar
    // [1151] phi from flash_smc::@38 to printf_uchar [phi:flash_smc::@38->printf_uchar]
    // [1151] phi printf_uchar::format_zero_padding#11 = 0 [phi:flash_smc::@38->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1151] phi printf_uchar::format_min_length#11 = 0 [phi:flash_smc::@38->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1151] phi printf_uchar::putc#11 = &snputc [phi:flash_smc::@38->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1151] phi printf_uchar::format_radix#11 = DECIMAL [phi:flash_smc::@38->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1151] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#3 [phi:flash_smc::@38->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1113] phi from flash_smc::@38 to flash_smc::@39 [phi:flash_smc::@38->flash_smc::@39]
    // flash_smc::@39
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1114] call printf_str
    // [725] phi from flash_smc::@39 to printf_str [phi:flash_smc::@39->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:flash_smc::@39->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = s7 [phi:flash_smc::@39->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s7
    sta.z printf_str.s
    lda #>@s7
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@40
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1115] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1116] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_line(info_text)
    // [1118] call display_info_line
    // [965] phi from flash_smc::@40 to display_info_line [phi:flash_smc::@40->display_info_line]
    // [965] phi display_info_line::info_text#19 = info_text [phi:flash_smc::@40->display_info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_line.info_text
    lda #>@info_text
    sta.z display_info_line.info_text+1
    jsr display_info_line
    // flash_smc::@41
    // smc_bootloader_activation_countdown--;
    // [1119] flash_smc::smc_bootloader_activation_countdown#3 = -- flash_smc::smc_bootloader_activation_countdown#12 -- vbum1=_dec_vbum1 
    dec smc_bootloader_activation_countdown_1
    // [1009] phi from flash_smc::@41 to flash_smc::@7 [phi:flash_smc::@41->flash_smc::@7]
    // [1009] phi flash_smc::smc_bootloader_activation_countdown#12 = flash_smc::smc_bootloader_activation_countdown#3 [phi:flash_smc::@41->flash_smc::@7#0] -- register_copy 
    jmp __b7
    // flash_smc::@4
  __b4:
    // unsigned int smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1120] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1121] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [1122] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [1123] cx16_k_i2c_read_byte::return#2 = cx16_k_i2c_read_byte::return#1
    // flash_smc::@30
    // [1124] flash_smc::smc_bootloader_not_activated1#0 = cx16_k_i2c_read_byte::return#2
    // if(smc_bootloader_not_activated)
    // [1125] if(0!=flash_smc::smc_bootloader_not_activated1#0) goto flash_smc::@5 -- 0_neq_vwum1_then_la1 
    lda smc_bootloader_not_activated1
    ora smc_bootloader_not_activated1+1
    bne __b5
    jmp __b9
    // [1126] phi from flash_smc::@30 to flash_smc::@5 [phi:flash_smc::@30->flash_smc::@5]
    // flash_smc::@5
  __b5:
    // wait_moment()
    // [1127] call wait_moment
    // [1146] phi from flash_smc::@5 to wait_moment [phi:flash_smc::@5->wait_moment]
    jsr wait_moment
    // [1128] phi from flash_smc::@5 to flash_smc::@31 [phi:flash_smc::@5->flash_smc::@31]
    // flash_smc::@31
    // sprintf(info_text, "Press POWER and RESET on the CX16 to start the SMC update (%u)!", smc_bootloader_activation_countdown)
    // [1129] call snprintf_init
    jsr snprintf_init
    // [1130] phi from flash_smc::@31 to flash_smc::@32 [phi:flash_smc::@31->flash_smc::@32]
    // flash_smc::@32
    // sprintf(info_text, "Press POWER and RESET on the CX16 to start the SMC update (%u)!", smc_bootloader_activation_countdown)
    // [1131] call printf_str
    // [725] phi from flash_smc::@32 to printf_str [phi:flash_smc::@32->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:flash_smc::@32->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = flash_smc::s1 [phi:flash_smc::@32->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@33
    // sprintf(info_text, "Press POWER and RESET on the CX16 to start the SMC update (%u)!", smc_bootloader_activation_countdown)
    // [1132] printf_uchar::uvalue#2 = flash_smc::smc_bootloader_activation_countdown#10 -- vbum1=vbum2 
    lda smc_bootloader_activation_countdown
    sta printf_uchar.uvalue
    // [1133] call printf_uchar
    // [1151] phi from flash_smc::@33 to printf_uchar [phi:flash_smc::@33->printf_uchar]
    // [1151] phi printf_uchar::format_zero_padding#11 = 0 [phi:flash_smc::@33->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1151] phi printf_uchar::format_min_length#11 = 0 [phi:flash_smc::@33->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1151] phi printf_uchar::putc#11 = &snputc [phi:flash_smc::@33->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1151] phi printf_uchar::format_radix#11 = DECIMAL [phi:flash_smc::@33->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1151] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#2 [phi:flash_smc::@33->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1134] phi from flash_smc::@33 to flash_smc::@34 [phi:flash_smc::@33->flash_smc::@34]
    // flash_smc::@34
    // sprintf(info_text, "Press POWER and RESET on the CX16 to start the SMC update (%u)!", smc_bootloader_activation_countdown)
    // [1135] call printf_str
    // [725] phi from flash_smc::@34 to printf_str [phi:flash_smc::@34->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:flash_smc::@34->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = flash_smc::s2 [phi:flash_smc::@34->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@35
    // sprintf(info_text, "Press POWER and RESET on the CX16 to start the SMC update (%u)!", smc_bootloader_activation_countdown)
    // [1136] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1137] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_line(info_text)
    // [1139] call display_info_line
    // [965] phi from flash_smc::@35 to display_info_line [phi:flash_smc::@35->display_info_line]
    // [965] phi display_info_line::info_text#19 = info_text [phi:flash_smc::@35->display_info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_line.info_text
    lda #>@info_text
    sta.z display_info_line.info_text+1
    jsr display_info_line
    // flash_smc::@6
    // smc_bootloader_activation_countdown--;
    // [1140] flash_smc::smc_bootloader_activation_countdown#2 = -- flash_smc::smc_bootloader_activation_countdown#10 -- vbum1=_dec_vbum1 
    dec smc_bootloader_activation_countdown
    // [1007] phi from flash_smc::@6 to flash_smc::@3 [phi:flash_smc::@6->flash_smc::@3]
    // [1007] phi flash_smc::smc_bootloader_activation_countdown#10 = flash_smc::smc_bootloader_activation_countdown#2 [phi:flash_smc::@6->flash_smc::@3#0] -- register_copy 
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
    // [1142] BRAM = system_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // system_reset::bank_set_brom1
    // BROM = bank
    // [1143] BROM = system_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // system_reset::@2
    // asm
    // asm { jmp($FFFC)  }
    jmp ($fffc)
    // [1145] phi from system_reset::@1 system_reset::@2 to system_reset::@1 [phi:system_reset::@1/system_reset::@2->system_reset::@1]
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
    // [1147] phi from wait_moment to wait_moment::@1 [phi:wait_moment->wait_moment::@1]
    // [1147] phi wait_moment::i#2 = $ffff [phi:wait_moment->wait_moment::@1#0] -- vwum1=vwuc1 
    lda #<$ffff
    sta i
    lda #>$ffff
    sta i+1
    // wait_moment::@1
  __b1:
    // for(unsigned int i=65535; i>0; i--)
    // [1148] if(wait_moment::i#2>0) goto wait_moment::@2 -- vwum1_gt_0_then_la1 
    lda i+1
    bne __b2
    lda i
    bne __b2
  !:
    // wait_moment::@return
    // }
    // [1149] return 
    rts
    // wait_moment::@2
  __b2:
    // for(unsigned int i=65535; i>0; i--)
    // [1150] wait_moment::i#1 = -- wait_moment::i#2 -- vwum1=_dec_vwum1 
    lda i
    bne !+
    dec i+1
  !:
    dec i
    // [1147] phi from wait_moment::@2 to wait_moment::@1 [phi:wait_moment::@2->wait_moment::@1]
    // [1147] phi wait_moment::i#2 = wait_moment::i#1 [phi:wait_moment::@2->wait_moment::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    i: .word 0
}
.segment Code
  // printf_uchar
// Print an unsigned char using a specific format
// void printf_uchar(__zp($6c) void (*putc)(char), __mem() char uvalue, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, __mem() char format_radix)
printf_uchar: {
    .label putc = $6c
    // printf_uchar::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1152] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // uctoa(uvalue, printf_buffer.digits, format.radix)
    // [1153] uctoa::value#1 = printf_uchar::uvalue#11
    // [1154] uctoa::radix#0 = printf_uchar::format_radix#11
    // [1155] call uctoa
    // Format number into buffer
    jsr uctoa
    // printf_uchar::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1156] printf_number_buffer::putc#2 = printf_uchar::putc#11
    // [1157] printf_number_buffer::buffer_sign#2 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [1158] printf_number_buffer::format_min_length#2 = printf_uchar::format_min_length#11
    // [1159] printf_number_buffer::format_zero_padding#2 = printf_uchar::format_zero_padding#11
    // [1160] call printf_number_buffer
  // Print using format
    // [1868] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [1868] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#2 [phi:printf_uchar::@2->printf_number_buffer#0] -- register_copy 
    // [1868] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#2 [phi:printf_uchar::@2->printf_number_buffer#1] -- register_copy 
    // [1868] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#2 [phi:printf_uchar::@2->printf_number_buffer#2] -- register_copy 
    // [1868] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#2 [phi:printf_uchar::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [1161] return 
    rts
  .segment Data
    uvalue: .byte 0
    format_radix: .byte 0
    .label format_min_length = printf_uint.format_min_length
    .label format_zero_padding = printf_uint.format_zero_padding
}
.segment Code
  // smc_reset
smc_reset: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 0
    // smc_reset::bank_set_bram1
    // BRAM = bank
    // [1163] BRAM = smc_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // smc_reset::bank_set_brom1
    // BROM = bank
    // [1164] BROM = smc_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // smc_reset::@2
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [1165] smc_reset::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [1166] smc_reset::cx16_k_i2c_write_byte1_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte1_offset
    // [1167] smc_reset::cx16_k_i2c_write_byte1_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte1_value
    // smc_reset::cx16_k_i2c_write_byte1
    // unsigned char result
    // [1168] smc_reset::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
    sta cx16_k_i2c_write_byte1_result
    // asm
    // asm { ldxdevice ldyoffset ldavalue stzresult jsrCX16_I2C_WRITE_BYTE rolresult  }
    ldx cx16_k_i2c_write_byte1_device
    ldy cx16_k_i2c_write_byte1_offset
    lda cx16_k_i2c_write_byte1_value
    stz cx16_k_i2c_write_byte1_result
    jsr CX16_I2C_WRITE_BYTE
    rol cx16_k_i2c_write_byte1_result
    // [1170] phi from smc_reset::@1 smc_reset::cx16_k_i2c_write_byte1 to smc_reset::@1 [phi:smc_reset::@1/smc_reset::cx16_k_i2c_write_byte1->smc_reset::@1]
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
  // display_info_rom
/**
 * @brief 
 * 
 * @param rom_chip 
 * @param info_status 
 * @param info_text 
 */
// void display_info_rom(__zp($b2) char rom_chip, __zp($7f) char info_status, __zp($a9) char *info_text)
display_info_rom: {
    .label display_info_rom__10 = $7f
    .label display_info_rom__11 = $62
    .label display_info_rom__13 = $63
    .label rom_chip = $b2
    .label info_status = $7f
    .label info_text = $a9
    // unsigned char x = wherex()
    // [1172] call wherex
    jsr wherex
    // [1173] wherex::return#12 = wherex::return#0 -- vbum1=vbum2 
    lda wherex.return
    sta wherex.return_4
    // display_info_rom::@3
    // [1174] display_info_rom::x#0 = wherex::return#12
    // unsigned char y = wherey()
    // [1175] call wherey
    jsr wherey
    // [1176] wherey::return#12 = wherey::return#0 -- vbum1=vbum2 
    lda wherey.return
    sta wherey.return_4
    // display_info_rom::@4
    // [1177] display_info_rom::y#0 = wherey::return#12
    // status_rom[rom_chip] = info_status
    // [1178] status_rom[display_info_rom::rom_chip#16] = display_info_rom::info_status#16 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z info_status
    ldy.z rom_chip
    sta status_rom,y
    // display_rom_led(rom_chip, status_color[info_status])
    // [1179] display_rom_led::chip#1 = display_info_rom::rom_chip#16 -- vbuz1=vbuz2 
    tya
    sta.z display_rom_led.chip
    // [1180] display_rom_led::c#1 = status_color[display_info_rom::info_status#16] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z display_rom_led.c
    // [1181] call display_rom_led
    // [1947] phi from display_info_rom::@4 to display_rom_led [phi:display_info_rom::@4->display_rom_led]
    // [1947] phi display_rom_led::c#2 = display_rom_led::c#1 [phi:display_info_rom::@4->display_rom_led#0] -- register_copy 
    // [1947] phi display_rom_led::chip#2 = display_rom_led::chip#1 [phi:display_info_rom::@4->display_rom_led#1] -- register_copy 
    jsr display_rom_led
    // display_info_rom::@5
    // gotoxy(INFO_X, INFO_Y+rom_chip+2)
    // [1182] gotoxy::y#17 = display_info_rom::rom_chip#16 + $11+2 -- vbum1=vbuz2_plus_vbuc1 
    lda #$11+2
    clc
    adc.z rom_chip
    sta gotoxy.y
    // [1183] call gotoxy
    // [582] phi from display_info_rom::@5 to gotoxy [phi:display_info_rom::@5->gotoxy]
    // [582] phi gotoxy::y#30 = gotoxy::y#17 [phi:display_info_rom::@5->gotoxy#0] -- register_copy 
    // [582] phi gotoxy::x#30 = 4 [phi:display_info_rom::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.x
    jsr gotoxy
    // [1184] phi from display_info_rom::@5 to display_info_rom::@6 [phi:display_info_rom::@5->display_info_rom::@6]
    // display_info_rom::@6
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1185] call printf_str
    // [725] phi from display_info_rom::@6 to printf_str [phi:display_info_rom::@6->printf_str]
    // [725] phi printf_str::putc#71 = &cputc [phi:display_info_rom::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = display_info_rom::s [phi:display_info_rom::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@7
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1186] printf_uchar::uvalue#0 = display_info_rom::rom_chip#16 -- vbum1=vbuz2 
    lda.z rom_chip
    sta printf_uchar.uvalue
    // [1187] call printf_uchar
    // [1151] phi from display_info_rom::@7 to printf_uchar [phi:display_info_rom::@7->printf_uchar]
    // [1151] phi printf_uchar::format_zero_padding#11 = 0 [phi:display_info_rom::@7->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1151] phi printf_uchar::format_min_length#11 = 0 [phi:display_info_rom::@7->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1151] phi printf_uchar::putc#11 = &cputc [phi:display_info_rom::@7->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1151] phi printf_uchar::format_radix#11 = DECIMAL [phi:display_info_rom::@7->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1151] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#0 [phi:display_info_rom::@7->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1188] phi from display_info_rom::@7 to display_info_rom::@8 [phi:display_info_rom::@7->display_info_rom::@8]
    // display_info_rom::@8
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1189] call printf_str
    // [725] phi from display_info_rom::@8 to printf_str [phi:display_info_rom::@8->printf_str]
    // [725] phi printf_str::putc#71 = &cputc [phi:display_info_rom::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = s1 [phi:display_info_rom::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@9
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1190] display_info_rom::$10 = display_info_rom::info_status#16 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_info_rom__10
    // [1191] printf_string::str#7 = status_text[display_info_rom::$10] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z display_info_rom__10
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [1192] call printf_string
    // [1222] phi from display_info_rom::@9 to printf_string [phi:display_info_rom::@9->printf_string]
    // [1222] phi printf_string::putc#18 = &cputc [phi:display_info_rom::@9->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1222] phi printf_string::str#18 = printf_string::str#7 [phi:display_info_rom::@9->printf_string#1] -- register_copy 
    // [1222] phi printf_string::format_justify_left#18 = 1 [phi:display_info_rom::@9->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1222] phi printf_string::format_min_length#18 = 9 [phi:display_info_rom::@9->printf_string#3] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [1193] phi from display_info_rom::@9 to display_info_rom::@10 [phi:display_info_rom::@9->display_info_rom::@10]
    // display_info_rom::@10
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1194] call printf_str
    // [725] phi from display_info_rom::@10 to printf_str [phi:display_info_rom::@10->printf_str]
    // [725] phi printf_str::putc#71 = &cputc [phi:display_info_rom::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = s1 [phi:display_info_rom::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@11
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1195] display_info_rom::$11 = display_info_rom::rom_chip#16 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta.z display_info_rom__11
    // [1196] printf_string::str#8 = rom_device_names[display_info_rom::$11] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda rom_device_names,y
    sta.z printf_string.str
    lda rom_device_names+1,y
    sta.z printf_string.str+1
    // [1197] call printf_string
    // [1222] phi from display_info_rom::@11 to printf_string [phi:display_info_rom::@11->printf_string]
    // [1222] phi printf_string::putc#18 = &cputc [phi:display_info_rom::@11->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1222] phi printf_string::str#18 = printf_string::str#8 [phi:display_info_rom::@11->printf_string#1] -- register_copy 
    // [1222] phi printf_string::format_justify_left#18 = 1 [phi:display_info_rom::@11->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1222] phi printf_string::format_min_length#18 = 6 [phi:display_info_rom::@11->printf_string#3] -- vbum1=vbuc1 
    lda #6
    sta printf_string.format_min_length
    jsr printf_string
    // [1198] phi from display_info_rom::@11 to display_info_rom::@12 [phi:display_info_rom::@11->display_info_rom::@12]
    // display_info_rom::@12
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1199] call printf_str
    // [725] phi from display_info_rom::@12 to printf_str [phi:display_info_rom::@12->printf_str]
    // [725] phi printf_str::putc#71 = &cputc [phi:display_info_rom::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = s1 [phi:display_info_rom::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@13
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1200] display_info_rom::$13 = display_info_rom::rom_chip#16 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta.z display_info_rom__13
    // [1201] printf_ulong::uvalue#0 = file_sizes[display_info_rom::$13] -- vdum1=pduc1_derefidx_vbuz2 
    tay
    lda file_sizes,y
    sta printf_ulong.uvalue
    lda file_sizes+1,y
    sta printf_ulong.uvalue+1
    lda file_sizes+2,y
    sta printf_ulong.uvalue+2
    lda file_sizes+3,y
    sta printf_ulong.uvalue+3
    // [1202] call printf_ulong
    // [1397] phi from display_info_rom::@13 to printf_ulong [phi:display_info_rom::@13->printf_ulong]
    // [1397] phi printf_ulong::format_zero_padding#11 = 1 [phi:display_info_rom::@13->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1397] phi printf_ulong::format_min_length#11 = 5 [phi:display_info_rom::@13->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1397] phi printf_ulong::putc#11 = &cputc [phi:display_info_rom::@13->printf_ulong#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_ulong.putc
    lda #>cputc
    sta.z printf_ulong.putc+1
    // [1397] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:display_info_rom::@13->printf_ulong#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1397] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#0 [phi:display_info_rom::@13->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1203] phi from display_info_rom::@13 to display_info_rom::@14 [phi:display_info_rom::@13->display_info_rom::@14]
    // display_info_rom::@14
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1204] call printf_str
    // [725] phi from display_info_rom::@14 to printf_str [phi:display_info_rom::@14->printf_str]
    // [725] phi printf_str::putc#71 = &cputc [phi:display_info_rom::@14->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = display_info_rom::s4 [phi:display_info_rom::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@15
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1205] printf_ulong::uvalue#1 = rom_sizes[display_info_rom::$13] -- vdum1=pduc1_derefidx_vbuz2 
    ldy.z display_info_rom__13
    lda rom_sizes,y
    sta printf_ulong.uvalue
    lda rom_sizes+1,y
    sta printf_ulong.uvalue+1
    lda rom_sizes+2,y
    sta printf_ulong.uvalue+2
    lda rom_sizes+3,y
    sta printf_ulong.uvalue+3
    // [1206] call printf_ulong
    // [1397] phi from display_info_rom::@15 to printf_ulong [phi:display_info_rom::@15->printf_ulong]
    // [1397] phi printf_ulong::format_zero_padding#11 = 1 [phi:display_info_rom::@15->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1397] phi printf_ulong::format_min_length#11 = 5 [phi:display_info_rom::@15->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1397] phi printf_ulong::putc#11 = &cputc [phi:display_info_rom::@15->printf_ulong#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_ulong.putc
    lda #>cputc
    sta.z printf_ulong.putc+1
    // [1397] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:display_info_rom::@15->printf_ulong#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1397] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#1 [phi:display_info_rom::@15->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1207] phi from display_info_rom::@15 to display_info_rom::@16 [phi:display_info_rom::@15->display_info_rom::@16]
    // display_info_rom::@16
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1208] call printf_str
    // [725] phi from display_info_rom::@16 to printf_str [phi:display_info_rom::@16->printf_str]
    // [725] phi printf_str::putc#71 = &cputc [phi:display_info_rom::@16->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = s1 [phi:display_info_rom::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@17
    // if(info_text)
    // [1209] if((char *)0==display_info_rom::info_text#16) goto display_info_rom::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // display_info_rom::@2
    // printf("%-20s", info_text)
    // [1210] printf_string::str#9 = display_info_rom::info_text#16 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1211] call printf_string
    // [1222] phi from display_info_rom::@2 to printf_string [phi:display_info_rom::@2->printf_string]
    // [1222] phi printf_string::putc#18 = &cputc [phi:display_info_rom::@2->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1222] phi printf_string::str#18 = printf_string::str#9 [phi:display_info_rom::@2->printf_string#1] -- register_copy 
    // [1222] phi printf_string::format_justify_left#18 = 1 [phi:display_info_rom::@2->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1222] phi printf_string::format_min_length#18 = $14 [phi:display_info_rom::@2->printf_string#3] -- vbum1=vbuc1 
    lda #$14
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_rom::@1
  __b1:
    // gotoxy(x,y)
    // [1212] gotoxy::x#18 = display_info_rom::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1213] gotoxy::y#18 = display_info_rom::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1214] call gotoxy
    // [582] phi from display_info_rom::@1 to gotoxy [phi:display_info_rom::@1->gotoxy]
    // [582] phi gotoxy::y#30 = gotoxy::y#18 [phi:display_info_rom::@1->gotoxy#0] -- register_copy 
    // [582] phi gotoxy::x#30 = gotoxy::x#18 [phi:display_info_rom::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_rom::@return
    // }
    // [1215] return 
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
// __zp($d1) char * rom_file(__zp($75) char rom_chip)
rom_file: {
    .label rom_file__0 = $75
    .label return = $d1
    .label rom_chip = $75
    // if(rom_chip)
    // [1217] if(0!=rom_file::rom_chip#2) goto rom_file::@1 -- 0_neq_vbuz1_then_la1 
    lda.z rom_chip
    bne __b1
    // [1220] phi from rom_file to rom_file::@return [phi:rom_file->rom_file::@return]
    // [1220] phi rom_file::return#2 = rom_file::file_rom_cx16 [phi:rom_file->rom_file::@return#0] -- pbuz1=pbuc1 
    lda #<file_rom_cx16
    sta.z return
    lda #>file_rom_cx16
    sta.z return+1
    rts
    // rom_file::@1
  __b1:
    // '0'+rom_chip
    // [1218] rom_file::$0 = '0' + rom_file::rom_chip#2 -- vbuz1=vbuc1_plus_vbuz1 
    lda #'0'
    clc
    adc.z rom_file__0
    sta.z rom_file__0
    // file_rom_card[3] = '0'+rom_chip
    // [1219] *(rom_file::file_rom_card+3) = rom_file::$0 -- _deref_pbuc1=vbuz1 
    sta file_rom_card+3
    // [1220] phi from rom_file::@1 to rom_file::@return [phi:rom_file::@1->rom_file::@return]
    // [1220] phi rom_file::return#2 = rom_file::file_rom_card [phi:rom_file::@1->rom_file::@return#0] -- pbuz1=pbuc1 
    lda #<file_rom_card
    sta.z return
    lda #>file_rom_card
    sta.z return+1
    // rom_file::@return
    // }
    // [1221] return 
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
// void printf_string(__zp($5d) void (*putc)(char), __zp($5f) char *str, __mem() char format_min_length, __mem() char format_justify_left)
printf_string: {
    .label printf_string__9 = $6c
    .label str = $5f
    .label putc = $5d
    // if(format.min_length)
    // [1223] if(0==printf_string::format_min_length#18) goto printf_string::@1 -- 0_eq_vbum1_then_la1 
    lda format_min_length
    beq __b3
    // printf_string::@3
    // strlen(str)
    // [1224] strlen::str#3 = printf_string::str#18 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [1225] call strlen
    // [2158] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [2158] phi strlen::str#8 = strlen::str#3 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [1226] strlen::return#10 = strlen::len#2
    // printf_string::@6
    // [1227] printf_string::$9 = strlen::return#10 -- vwuz1=vwum2 
    lda strlen.return
    sta.z printf_string__9
    lda strlen.return+1
    sta.z printf_string__9+1
    // signed char len = (signed char)strlen(str)
    // [1228] printf_string::len#0 = (signed char)printf_string::$9 -- vbsm1=_sbyte_vwuz2 
    lda.z printf_string__9
    sta len
    // padding = (signed char)format.min_length  - len
    // [1229] printf_string::padding#1 = (signed char)printf_string::format_min_length#18 - printf_string::len#0 -- vbsm1=vbsm1_minus_vbsm2 
    lda padding
    sec
    sbc len
    sta padding
    // if(padding<0)
    // [1230] if(printf_string::padding#1>=0) goto printf_string::@10 -- vbsm1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1232] phi from printf_string printf_string::@6 to printf_string::@1 [phi:printf_string/printf_string::@6->printf_string::@1]
  __b3:
    // [1232] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@6->printf_string::@1#0] -- vbsm1=vbsc1 
    lda #0
    sta padding
    // [1231] phi from printf_string::@6 to printf_string::@10 [phi:printf_string::@6->printf_string::@10]
    // printf_string::@10
    // [1232] phi from printf_string::@10 to printf_string::@1 [phi:printf_string::@10->printf_string::@1]
    // [1232] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@10->printf_string::@1#0] -- register_copy 
    // printf_string::@1
  __b1:
    // if(!format.justify_left && padding)
    // [1233] if(0!=printf_string::format_justify_left#18) goto printf_string::@2 -- 0_neq_vbum1_then_la1 
    lda format_justify_left
    bne __b2
    // printf_string::@8
    // [1234] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b4
    jmp __b2
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [1235] printf_padding::putc#3 = printf_string::putc#18 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1236] printf_padding::length#3 = (char)printf_string::padding#3 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1237] call printf_padding
    // [2164] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    // [2164] phi printf_padding::putc#7 = printf_padding::putc#3 [phi:printf_string::@4->printf_padding#0] -- register_copy 
    // [2164] phi printf_padding::pad#7 = ' ' [phi:printf_string::@4->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [2164] phi printf_padding::length#6 = printf_padding::length#3 [phi:printf_string::@4->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [1238] printf_str::putc#1 = printf_string::putc#18 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_str.putc
    lda.z putc+1
    sta.z printf_str.putc+1
    // [1239] printf_str::s#2 = printf_string::str#18
    // [1240] call printf_str
    // [725] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [725] phi printf_str::putc#71 = printf_str::putc#1 [phi:printf_string::@2->printf_str#0] -- register_copy 
    // [725] phi printf_str::s#71 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@7
    // if(format.justify_left && padding)
    // [1241] if(0==printf_string::format_justify_left#18) goto printf_string::@return -- 0_eq_vbum1_then_la1 
    lda format_justify_left
    beq __breturn
    // printf_string::@9
    // [1242] if(0!=printf_string::padding#3) goto printf_string::@5 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b5
    rts
    // printf_string::@5
  __b5:
    // printf_padding(putc, ' ',(char)padding)
    // [1243] printf_padding::putc#4 = printf_string::putc#18 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1244] printf_padding::length#4 = (char)printf_string::padding#3 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1245] call printf_padding
    // [2164] phi from printf_string::@5 to printf_padding [phi:printf_string::@5->printf_padding]
    // [2164] phi printf_padding::putc#7 = printf_padding::putc#4 [phi:printf_string::@5->printf_padding#0] -- register_copy 
    // [2164] phi printf_padding::pad#7 = ' ' [phi:printf_string::@5->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [2164] phi printf_padding::length#6 = printf_padding::length#4 [phi:printf_string::@5->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@return
  __breturn:
    // }
    // [1246] return 
    rts
  .segment Data
    len: .byte 0
    .label padding = format_min_length
    format_min_length: .byte 0
    format_justify_left: .byte 0
}
.segment Code
  // rom_read
// __mem() unsigned long rom_read(char rom_chip, __zp($66) char *file, char info_status, __zp($78) char brom_bank_start, __zp($50) unsigned long rom_size)
rom_read: {
    .const bank_set_brom1_bank = 0
    .label rom_read__11 = $59
    .label fp = $ba
    .label brom_bank_start = $78
    .label ram_address = $4e
    .label file = $66
    .label rom_size = $50
    // unsigned long rom_address = rom_address_from_bank(brom_bank_start)
    // [1248] rom_address_from_bank::rom_bank#0 = rom_read::brom_bank_start#21 -- vbuz1=vbuz2 
    lda.z brom_bank_start
    sta.z rom_address_from_bank.rom_bank
    // [1249] call rom_address_from_bank
    // [2172] phi from rom_read to rom_address_from_bank [phi:rom_read->rom_address_from_bank]
    // [2172] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#0 [phi:rom_read->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(brom_bank_start)
    // [1250] rom_address_from_bank::return#2 = rom_address_from_bank::return#0
    // rom_read::@15
    // [1251] rom_read::rom_address#0 = rom_address_from_bank::return#2
    // rom_read::bank_set_bram1
    // BRAM = bank
    // [1252] BRAM = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z BRAM
    // rom_read::bank_set_brom1
    // BROM = bank
    // [1253] BROM = rom_read::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [1254] phi from rom_read::bank_set_brom1 to rom_read::@13 [phi:rom_read::bank_set_brom1->rom_read::@13]
    // rom_read::@13
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1255] call snprintf_init
    jsr snprintf_init
    // [1256] phi from rom_read::@13 to rom_read::@16 [phi:rom_read::@13->rom_read::@16]
    // rom_read::@16
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1257] call printf_str
    // [725] phi from rom_read::@16 to printf_str [phi:rom_read::@16->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:rom_read::@16->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = rom_read::s [phi:rom_read::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@17
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1258] printf_string::str#10 = rom_read::file#11 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [1259] call printf_string
    // [1222] phi from rom_read::@17 to printf_string [phi:rom_read::@17->printf_string]
    // [1222] phi printf_string::putc#18 = &snputc [phi:rom_read::@17->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1222] phi printf_string::str#18 = printf_string::str#10 [phi:rom_read::@17->printf_string#1] -- register_copy 
    // [1222] phi printf_string::format_justify_left#18 = 0 [phi:rom_read::@17->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1222] phi printf_string::format_min_length#18 = 0 [phi:rom_read::@17->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [1260] phi from rom_read::@17 to rom_read::@18 [phi:rom_read::@17->rom_read::@18]
    // rom_read::@18
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1261] call printf_str
    // [725] phi from rom_read::@18 to printf_str [phi:rom_read::@18->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:rom_read::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = rom_read::s1 [phi:rom_read::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@19
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1262] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1263] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_line(info_text)
    // [1265] call display_info_line
    // [965] phi from rom_read::@19 to display_info_line [phi:rom_read::@19->display_info_line]
    // [965] phi display_info_line::info_text#19 = info_text [phi:rom_read::@19->display_info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_line.info_text
    lda #>info_text
    sta.z display_info_line.info_text+1
    jsr display_info_line
    // rom_read::@20
    // FILE *fp = fopen(file, "r")
    // [1266] fopen::path#3 = rom_read::file#11 -- pbuz1=pbuz2 
    lda.z file
    sta.z fopen.path
    lda.z file+1
    sta.z fopen.path+1
    // [1267] call fopen
    // [1967] phi from rom_read::@20 to fopen [phi:rom_read::@20->fopen]
    // [1967] phi __errno#328 = __errno#106 [phi:rom_read::@20->fopen#0] -- register_copy 
    // [1967] phi fopen::pathtoken#0 = fopen::path#3 [phi:rom_read::@20->fopen#1] -- register_copy 
    jsr fopen
    // FILE *fp = fopen(file, "r")
    // [1268] fopen::return#4 = fopen::return#2
    // rom_read::@21
    // [1269] rom_read::fp#0 = fopen::return#4 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [1270] if((struct $2 *)0==rom_read::fp#0) goto rom_read::@1 -- pssc1_eq_pssz1_then_la1 
    lda.z fp
    cmp #<0
    bne !+
    lda.z fp+1
    cmp #>0
    beq __b2
  !:
    // [1271] phi from rom_read::@21 to rom_read::@2 [phi:rom_read::@21->rom_read::@2]
    // rom_read::@2
    // gotoxy(x, y)
    // [1272] call gotoxy
    // [582] phi from rom_read::@2 to gotoxy [phi:rom_read::@2->gotoxy]
    // [582] phi gotoxy::y#30 = PROGRESS_Y [phi:rom_read::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [582] phi gotoxy::x#30 = PROGRESS_X [phi:rom_read::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1273] phi from rom_read::@2 to rom_read::@3 [phi:rom_read::@2->rom_read::@3]
    // [1273] phi rom_read::y#11 = PROGRESS_Y [phi:rom_read::@2->rom_read::@3#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1273] phi rom_read::rom_row_current#10 = 0 [phi:rom_read::@2->rom_read::@3#1] -- vwum1=vwuc1 
    lda #<0
    sta rom_row_current
    sta rom_row_current+1
    // [1273] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#21 [phi:rom_read::@2->rom_read::@3#2] -- register_copy 
    // [1273] phi rom_read::rom_address#10 = rom_read::rom_address#0 [phi:rom_read::@2->rom_read::@3#3] -- register_copy 
    // [1273] phi rom_read::ram_address#10 = (char *)$6000 [phi:rom_read::@2->rom_read::@3#4] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z ram_address
    lda #>$6000
    sta.z ram_address+1
    // [1273] phi rom_read::bram_bank#10 = 0 [phi:rom_read::@2->rom_read::@3#5] -- vbum1=vbuc1 
    lda #0
    sta bram_bank
    // [1273] phi rom_read::rom_file_size#11 = 0 [phi:rom_read::@2->rom_read::@3#6] -- vdum1=vduc1 
    sta rom_file_size
    sta rom_file_size+1
    lda #<0>>$10
    sta rom_file_size+2
    lda #>0>>$10
    sta rom_file_size+3
    // rom_read::@3
  __b3:
    // while (rom_file_size < rom_size)
    // [1274] if(rom_read::rom_file_size#11<rom_read::rom_size#12) goto rom_read::@4 -- vdum1_lt_vduz2_then_la1 
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
    // [1275] fclose::stream#1 = rom_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fclose.stream
    lda.z fp+1
    sta.z fclose.stream+1
    // [1276] call fclose
    // [2102] phi from rom_read::@7 to fclose [phi:rom_read::@7->fclose]
    // [2102] phi fclose::stream#2 = fclose::stream#1 [phi:rom_read::@7->fclose#0] -- register_copy 
    jsr fclose
    // [1277] phi from rom_read::@7 to rom_read::@1 [phi:rom_read::@7->rom_read::@1]
    // [1277] phi rom_read::return#0 = rom_read::rom_file_size#11 [phi:rom_read::@7->rom_read::@1#0] -- register_copy 
    rts
    // [1277] phi from rom_read::@21 to rom_read::@1 [phi:rom_read::@21->rom_read::@1]
  __b2:
    // [1277] phi rom_read::return#0 = 0 [phi:rom_read::@21->rom_read::@1#0] -- vdum1=vduc1 
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
    // [1278] return 
    rts
    // [1279] phi from rom_read::@3 to rom_read::@4 [phi:rom_read::@3->rom_read::@4]
    // rom_read::@4
  __b4:
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1280] call snprintf_init
    jsr snprintf_init
    // [1281] phi from rom_read::@4 to rom_read::@22 [phi:rom_read::@4->rom_read::@22]
    // rom_read::@22
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1282] call printf_str
    // [725] phi from rom_read::@22 to printf_str [phi:rom_read::@22->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:rom_read::@22->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = s14 [phi:rom_read::@22->printf_str#1] -- pbuz1=pbuc1 
    lda #<s14
    sta.z printf_str.s
    lda #>s14
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@23
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1283] printf_string::str#11 = rom_read::file#11 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [1284] call printf_string
    // [1222] phi from rom_read::@23 to printf_string [phi:rom_read::@23->printf_string]
    // [1222] phi printf_string::putc#18 = &snputc [phi:rom_read::@23->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1222] phi printf_string::str#18 = printf_string::str#11 [phi:rom_read::@23->printf_string#1] -- register_copy 
    // [1222] phi printf_string::format_justify_left#18 = 0 [phi:rom_read::@23->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1222] phi printf_string::format_min_length#18 = 0 [phi:rom_read::@23->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [1285] phi from rom_read::@23 to rom_read::@24 [phi:rom_read::@23->rom_read::@24]
    // rom_read::@24
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1286] call printf_str
    // [725] phi from rom_read::@24 to printf_str [phi:rom_read::@24->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:rom_read::@24->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = s3 [phi:rom_read::@24->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@25
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1287] printf_ulong::uvalue#2 = rom_read::rom_file_size#11 -- vdum1=vdum2 
    lda rom_file_size
    sta printf_ulong.uvalue
    lda rom_file_size+1
    sta printf_ulong.uvalue+1
    lda rom_file_size+2
    sta printf_ulong.uvalue+2
    lda rom_file_size+3
    sta printf_ulong.uvalue+3
    // [1288] call printf_ulong
    // [1397] phi from rom_read::@25 to printf_ulong [phi:rom_read::@25->printf_ulong]
    // [1397] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_read::@25->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1397] phi printf_ulong::format_min_length#11 = 5 [phi:rom_read::@25->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1397] phi printf_ulong::putc#11 = &snputc [phi:rom_read::@25->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1397] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_read::@25->printf_ulong#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1397] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#2 [phi:rom_read::@25->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1289] phi from rom_read::@25 to rom_read::@26 [phi:rom_read::@25->rom_read::@26]
    // rom_read::@26
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1290] call printf_str
    // [725] phi from rom_read::@26 to printf_str [phi:rom_read::@26->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:rom_read::@26->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = s4 [phi:rom_read::@26->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@27
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1291] printf_ulong::uvalue#3 = rom_read::rom_size#12 -- vdum1=vduz2 
    lda.z rom_size
    sta printf_ulong.uvalue
    lda.z rom_size+1
    sta printf_ulong.uvalue+1
    lda.z rom_size+2
    sta printf_ulong.uvalue+2
    lda.z rom_size+3
    sta printf_ulong.uvalue+3
    // [1292] call printf_ulong
    // [1397] phi from rom_read::@27 to printf_ulong [phi:rom_read::@27->printf_ulong]
    // [1397] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_read::@27->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1397] phi printf_ulong::format_min_length#11 = 5 [phi:rom_read::@27->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1397] phi printf_ulong::putc#11 = &snputc [phi:rom_read::@27->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1397] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_read::@27->printf_ulong#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1397] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#3 [phi:rom_read::@27->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1293] phi from rom_read::@27 to rom_read::@28 [phi:rom_read::@27->rom_read::@28]
    // rom_read::@28
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1294] call printf_str
    // [725] phi from rom_read::@28 to printf_str [phi:rom_read::@28->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:rom_read::@28->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = s2 [phi:rom_read::@28->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@29
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1295] printf_uchar::uvalue#5 = rom_read::bram_bank#10 -- vbum1=vbum2 
    lda bram_bank
    sta printf_uchar.uvalue
    // [1296] call printf_uchar
    // [1151] phi from rom_read::@29 to printf_uchar [phi:rom_read::@29->printf_uchar]
    // [1151] phi printf_uchar::format_zero_padding#11 = 1 [phi:rom_read::@29->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1151] phi printf_uchar::format_min_length#11 = 2 [phi:rom_read::@29->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1151] phi printf_uchar::putc#11 = &snputc [phi:rom_read::@29->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1151] phi printf_uchar::format_radix#11 = HEXADECIMAL [phi:rom_read::@29->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1151] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#5 [phi:rom_read::@29->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1297] phi from rom_read::@29 to rom_read::@30 [phi:rom_read::@29->rom_read::@30]
    // rom_read::@30
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1298] call printf_str
    // [725] phi from rom_read::@30 to printf_str [phi:rom_read::@30->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:rom_read::@30->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = s3 [phi:rom_read::@30->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@31
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1299] printf_uint::uvalue#10 = (unsigned int)rom_read::ram_address#10 -- vwum1=vwuz2 
    lda.z ram_address
    sta printf_uint.uvalue
    lda.z ram_address+1
    sta printf_uint.uvalue+1
    // [1300] call printf_uint
    // [734] phi from rom_read::@31 to printf_uint [phi:rom_read::@31->printf_uint]
    // [734] phi printf_uint::format_zero_padding#16 = 1 [phi:rom_read::@31->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [734] phi printf_uint::format_min_length#16 = 4 [phi:rom_read::@31->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [734] phi printf_uint::putc#16 = &snputc [phi:rom_read::@31->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [734] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:rom_read::@31->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [734] phi printf_uint::uvalue#16 = printf_uint::uvalue#10 [phi:rom_read::@31->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1301] phi from rom_read::@31 to rom_read::@32 [phi:rom_read::@31->rom_read::@32]
    // rom_read::@32
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1302] call printf_str
    // [725] phi from rom_read::@32 to printf_str [phi:rom_read::@32->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:rom_read::@32->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = s7 [phi:rom_read::@32->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@33
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1303] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1304] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_line(info_text)
    // [1306] call display_info_line
    // [965] phi from rom_read::@33 to display_info_line [phi:rom_read::@33->display_info_line]
    // [965] phi display_info_line::info_text#19 = info_text [phi:rom_read::@33->display_info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_line.info_text
    lda #>info_text
    sta.z display_info_line.info_text+1
    jsr display_info_line
    // rom_read::@34
    // rom_address % 0x04000
    // [1307] rom_read::$11 = rom_read::rom_address#10 & $4000-1 -- vduz1=vdum2_band_vduc1 
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
    // [1308] if(0!=rom_read::$11) goto rom_read::@5 -- 0_neq_vduz1_then_la1 
    lda.z rom_read__11
    ora.z rom_read__11+1
    ora.z rom_read__11+2
    ora.z rom_read__11+3
    bne __b5
    // rom_read::@10
    // brom_bank_start++;
    // [1309] rom_read::brom_bank_start#0 = ++ rom_read::brom_bank_start#10 -- vbuz1=_inc_vbuz1 
    inc.z brom_bank_start
    // [1310] phi from rom_read::@10 rom_read::@34 to rom_read::@5 [phi:rom_read::@10/rom_read::@34->rom_read::@5]
    // [1310] phi rom_read::brom_bank_start#20 = rom_read::brom_bank_start#0 [phi:rom_read::@10/rom_read::@34->rom_read::@5#0] -- register_copy 
    // rom_read::@5
  __b5:
    // rom_read::bank_set_bram2
    // BRAM = bank
    // [1311] BRAM = rom_read::bram_bank#10 -- vbuz1=vbum2 
    lda bram_bank
    sta.z BRAM
    // rom_read::@14
    // unsigned int rom_package_read = fgets(ram_address, PROGRESS_CELL, fp)
    // [1312] fgets::ptr#3 = rom_read::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z fgets.ptr
    lda.z ram_address+1
    sta.z fgets.ptr+1
    // [1313] fgets::stream#1 = rom_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.stream
    lda.z fp+1
    sta.z fgets.stream+1
    // [1314] call fgets
    // [2048] phi from rom_read::@14 to fgets [phi:rom_read::@14->fgets]
    // [2048] phi fgets::ptr#12 = fgets::ptr#3 [phi:rom_read::@14->fgets#0] -- register_copy 
    // [2048] phi fgets::size#10 = PROGRESS_CELL [phi:rom_read::@14->fgets#1] -- vwum1=vwuc1 
    lda #<PROGRESS_CELL
    sta fgets.size
    lda #>PROGRESS_CELL
    sta fgets.size+1
    // [2048] phi fgets::stream#2 = fgets::stream#1 [phi:rom_read::@14->fgets#2] -- register_copy 
    jsr fgets
    // unsigned int rom_package_read = fgets(ram_address, PROGRESS_CELL, fp)
    // [1315] fgets::return#6 = fgets::return#1
    // rom_read::@35
    // [1316] rom_read::rom_package_read#0 = fgets::return#6 -- vwum1=vwum2 
    lda fgets.return
    sta rom_package_read
    lda fgets.return+1
    sta rom_package_read+1
    // if (!rom_package_read)
    // [1317] if(0!=rom_read::rom_package_read#0) goto rom_read::@6 -- 0_neq_vwum1_then_la1 
    lda rom_package_read
    ora rom_package_read+1
    bne __b6
    jmp __b7
    // rom_read::@6
  __b6:
    // if (rom_row_current == PROGRESS_ROW)
    // [1318] if(rom_read::rom_row_current#10!=PROGRESS_ROW) goto rom_read::@8 -- vwum1_neq_vwuc1_then_la1 
    lda rom_row_current+1
    cmp #>PROGRESS_ROW
    bne __b8
    lda rom_row_current
    cmp #<PROGRESS_ROW
    bne __b8
    // rom_read::@11
    // gotoxy(x, ++y);
    // [1319] rom_read::y#1 = ++ rom_read::y#11 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [1320] gotoxy::y#25 = rom_read::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1321] call gotoxy
    // [582] phi from rom_read::@11 to gotoxy [phi:rom_read::@11->gotoxy]
    // [582] phi gotoxy::y#30 = gotoxy::y#25 [phi:rom_read::@11->gotoxy#0] -- register_copy 
    // [582] phi gotoxy::x#30 = PROGRESS_X [phi:rom_read::@11->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1322] phi from rom_read::@11 to rom_read::@8 [phi:rom_read::@11->rom_read::@8]
    // [1322] phi rom_read::y#36 = rom_read::y#1 [phi:rom_read::@11->rom_read::@8#0] -- register_copy 
    // [1322] phi rom_read::rom_row_current#4 = 0 [phi:rom_read::@11->rom_read::@8#1] -- vwum1=vbuc1 
    lda #<0
    sta rom_row_current
    sta rom_row_current+1
    // [1322] phi from rom_read::@6 to rom_read::@8 [phi:rom_read::@6->rom_read::@8]
    // [1322] phi rom_read::y#36 = rom_read::y#11 [phi:rom_read::@6->rom_read::@8#0] -- register_copy 
    // [1322] phi rom_read::rom_row_current#4 = rom_read::rom_row_current#10 [phi:rom_read::@6->rom_read::@8#1] -- register_copy 
    // rom_read::@8
  __b8:
    // cputc('.')
    // [1323] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [1324] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // ram_address += rom_package_read
    // [1326] rom_read::ram_address#1 = rom_read::ram_address#10 + rom_read::rom_package_read#0 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z ram_address
    adc rom_package_read
    sta.z ram_address
    lda.z ram_address+1
    adc rom_package_read+1
    sta.z ram_address+1
    // rom_address += rom_package_read
    // [1327] rom_read::rom_address#1 = rom_read::rom_address#10 + rom_read::rom_package_read#0 -- vdum1=vdum1_plus_vwum2 
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
    // [1328] rom_read::rom_file_size#1 = rom_read::rom_file_size#11 + rom_read::rom_package_read#0 -- vdum1=vdum1_plus_vwum2 
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
    // [1329] rom_read::rom_row_current#1 = rom_read::rom_row_current#4 + rom_read::rom_package_read#0 -- vwum1=vwum1_plus_vwum2 
    clc
    lda rom_row_current
    adc rom_package_read
    sta rom_row_current
    lda rom_row_current+1
    adc rom_package_read+1
    sta rom_row_current+1
    // if (ram_address == (ram_ptr_t)BRAM_HIGH)
    // [1330] if(rom_read::ram_address#1!=(char *)$c000) goto rom_read::@9 -- pbuz1_neq_pbuc1_then_la1 
    lda.z ram_address+1
    cmp #>$c000
    bne __b9
    lda.z ram_address
    cmp #<$c000
    bne __b9
    // rom_read::@12
    // bram_bank++;
    // [1331] rom_read::bram_bank#1 = ++ rom_read::bram_bank#10 -- vbum1=_inc_vbum1 
    inc bram_bank
    // [1332] phi from rom_read::@12 to rom_read::@9 [phi:rom_read::@12->rom_read::@9]
    // [1332] phi rom_read::bram_bank#30 = rom_read::bram_bank#1 [phi:rom_read::@12->rom_read::@9#0] -- register_copy 
    // [1332] phi rom_read::ram_address#7 = (char *)$a000 [phi:rom_read::@12->rom_read::@9#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1332] phi from rom_read::@8 to rom_read::@9 [phi:rom_read::@8->rom_read::@9]
    // [1332] phi rom_read::bram_bank#30 = rom_read::bram_bank#10 [phi:rom_read::@8->rom_read::@9#0] -- register_copy 
    // [1332] phi rom_read::ram_address#7 = rom_read::ram_address#1 [phi:rom_read::@8->rom_read::@9#1] -- register_copy 
    // rom_read::@9
  __b9:
    // if (ram_address == (ram_ptr_t)RAM_HIGH)
    // [1333] if(rom_read::ram_address#7!=(char *)$8000) goto rom_read::@36 -- pbuz1_neq_pbuc1_then_la1 
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
    // [1273] phi from rom_read::@9 to rom_read::@3 [phi:rom_read::@9->rom_read::@3]
    // [1273] phi rom_read::y#11 = rom_read::y#36 [phi:rom_read::@9->rom_read::@3#0] -- register_copy 
    // [1273] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#1 [phi:rom_read::@9->rom_read::@3#1] -- register_copy 
    // [1273] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#20 [phi:rom_read::@9->rom_read::@3#2] -- register_copy 
    // [1273] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@9->rom_read::@3#3] -- register_copy 
    // [1273] phi rom_read::ram_address#10 = (char *)$a000 [phi:rom_read::@9->rom_read::@3#4] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1273] phi rom_read::bram_bank#10 = 1 [phi:rom_read::@9->rom_read::@3#5] -- vbum1=vbuc1 
    lda #1
    sta bram_bank
    // [1273] phi rom_read::rom_file_size#11 = rom_read::rom_file_size#1 [phi:rom_read::@9->rom_read::@3#6] -- register_copy 
    jmp __b3
    // [1334] phi from rom_read::@9 to rom_read::@36 [phi:rom_read::@9->rom_read::@36]
    // rom_read::@36
    // [1273] phi from rom_read::@36 to rom_read::@3 [phi:rom_read::@36->rom_read::@3]
    // [1273] phi rom_read::y#11 = rom_read::y#36 [phi:rom_read::@36->rom_read::@3#0] -- register_copy 
    // [1273] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#1 [phi:rom_read::@36->rom_read::@3#1] -- register_copy 
    // [1273] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#20 [phi:rom_read::@36->rom_read::@3#2] -- register_copy 
    // [1273] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@36->rom_read::@3#3] -- register_copy 
    // [1273] phi rom_read::ram_address#10 = rom_read::ram_address#7 [phi:rom_read::@36->rom_read::@3#4] -- register_copy 
    // [1273] phi rom_read::bram_bank#10 = rom_read::bram_bank#30 [phi:rom_read::@36->rom_read::@3#5] -- register_copy 
    // [1273] phi rom_read::rom_file_size#11 = rom_read::rom_file_size#1 [phi:rom_read::@36->rom_read::@3#6] -- register_copy 
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
// __mem() unsigned long rom_verify(__zp($b2) char rom_chip, __zp($c6) char rom_bank_start, __zp($59) unsigned long file_size)
rom_verify: {
    .label rom_verify__16 = $6c
    .label ram_address = $af
    .label rom_chip = $b2
    .label rom_bank_start = $c6
    .label file_size = $59
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [1335] rom_address_from_bank::rom_bank#1 = rom_verify::rom_bank_start#0
    // [1336] call rom_address_from_bank
    // [2172] phi from rom_verify to rom_address_from_bank [phi:rom_verify->rom_address_from_bank]
    // [2172] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#1 [phi:rom_verify->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [1337] rom_address_from_bank::return#3 = rom_address_from_bank::return#0 -- vdum1=vdum2 
    lda rom_address_from_bank.return
    sta rom_address_from_bank.return_1
    lda rom_address_from_bank.return+1
    sta rom_address_from_bank.return_1+1
    lda rom_address_from_bank.return+2
    sta rom_address_from_bank.return_1+2
    lda rom_address_from_bank.return+3
    sta rom_address_from_bank.return_1+3
    // rom_verify::@11
    // [1338] rom_verify::rom_address#0 = rom_address_from_bank::return#3
    // unsigned long rom_boundary = rom_address + file_size
    // [1339] rom_verify::rom_boundary#0 = rom_verify::rom_address#0 + rom_verify::file_size#0 -- vdum1=vdum2_plus_vduz3 
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
    // display_info_rom(rom_chip, STATUS_COMPARING, "Comparing ...")
    // [1340] display_info_rom::rom_chip#1 = rom_verify::rom_chip#0
    // [1341] call display_info_rom
    // [1171] phi from rom_verify::@11 to display_info_rom [phi:rom_verify::@11->display_info_rom]
    // [1171] phi display_info_rom::info_text#16 = rom_verify::info_text [phi:rom_verify::@11->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_rom.info_text
    lda #>info_text
    sta.z display_info_rom.info_text+1
    // [1171] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#1 [phi:rom_verify::@11->display_info_rom#1] -- register_copy 
    // [1171] phi display_info_rom::info_status#16 = STATUS_COMPARING [phi:rom_verify::@11->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_COMPARING
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // [1342] phi from rom_verify::@11 to rom_verify::@12 [phi:rom_verify::@11->rom_verify::@12]
    // rom_verify::@12
    // gotoxy(x, y)
    // [1343] call gotoxy
    // [582] phi from rom_verify::@12 to gotoxy [phi:rom_verify::@12->gotoxy]
    // [582] phi gotoxy::y#30 = PROGRESS_Y [phi:rom_verify::@12->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [582] phi gotoxy::x#30 = PROGRESS_X [phi:rom_verify::@12->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1344] phi from rom_verify::@12 to rom_verify::@1 [phi:rom_verify::@12->rom_verify::@1]
    // [1344] phi rom_verify::y#3 = PROGRESS_Y [phi:rom_verify::@12->rom_verify::@1#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1344] phi rom_verify::progress_row_current#3 = 0 [phi:rom_verify::@12->rom_verify::@1#1] -- vwum1=vwuc1 
    lda #<0
    sta progress_row_current
    sta progress_row_current+1
    // [1344] phi rom_verify::rom_different_bytes#11 = 0 [phi:rom_verify::@12->rom_verify::@1#2] -- vdum1=vduc1 
    sta rom_different_bytes
    sta rom_different_bytes+1
    lda #<0>>$10
    sta rom_different_bytes+2
    lda #>0>>$10
    sta rom_different_bytes+3
    // [1344] phi rom_verify::ram_address#10 = (char *)$6000 [phi:rom_verify::@12->rom_verify::@1#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z ram_address
    lda #>$6000
    sta.z ram_address+1
    // [1344] phi rom_verify::bram_bank#11 = 0 [phi:rom_verify::@12->rom_verify::@1#4] -- vbum1=vbuc1 
    lda #0
    sta bram_bank
    // [1344] phi rom_verify::rom_address#12 = rom_verify::rom_address#0 [phi:rom_verify::@12->rom_verify::@1#5] -- register_copy 
    // rom_verify::@1
  __b1:
    // while (rom_address < rom_boundary)
    // [1345] if(rom_verify::rom_address#12<rom_verify::rom_boundary#0) goto rom_verify::@2 -- vdum1_lt_vdum2_then_la1 
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
    // [1346] return 
    rts
    // rom_verify::@2
  __b2:
    // unsigned int equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1347] rom_compare::bank_ram#0 = rom_verify::bram_bank#11 -- vbuz1=vbum2 
    lda bram_bank
    sta.z rom_compare.bank_ram
    // [1348] rom_compare::ptr_ram#1 = rom_verify::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_compare.ptr_ram
    lda.z ram_address+1
    sta.z rom_compare.ptr_ram+1
    // [1349] rom_compare::rom_compare_address#0 = rom_verify::rom_address#12 -- vduz1=vdum2 
    lda rom_address
    sta.z rom_compare.rom_compare_address
    lda rom_address+1
    sta.z rom_compare.rom_compare_address+1
    lda rom_address+2
    sta.z rom_compare.rom_compare_address+2
    lda rom_address+3
    sta.z rom_compare.rom_compare_address+3
    // [1350] call rom_compare
  // {asm{.byte $db}}
    // [2176] phi from rom_verify::@2 to rom_compare [phi:rom_verify::@2->rom_compare]
    // [2176] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#1 [phi:rom_verify::@2->rom_compare#0] -- register_copy 
    // [2176] phi rom_compare::rom_compare_size#11 = PROGRESS_CELL [phi:rom_verify::@2->rom_compare#1] -- vwuz1=vwuc1 
    lda #<PROGRESS_CELL
    sta.z rom_compare.rom_compare_size
    lda #>PROGRESS_CELL
    sta.z rom_compare.rom_compare_size+1
    // [2176] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#0 [phi:rom_verify::@2->rom_compare#2] -- register_copy 
    // [2176] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#0 [phi:rom_verify::@2->rom_compare#3] -- vbum1=vbuz2 
    lda.z rom_compare.bank_ram
    sta rom_compare.bank_set_bram1_bank
    jsr rom_compare
    // unsigned int equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1351] rom_compare::return#2 = rom_compare::equal_bytes#2
    // rom_verify::@13
    // [1352] rom_verify::equal_bytes#0 = rom_compare::return#2
    // if (progress_row_current == PROGRESS_ROW)
    // [1353] if(rom_verify::progress_row_current#3!=PROGRESS_ROW) goto rom_verify::@3 -- vwum1_neq_vwuc1_then_la1 
    lda progress_row_current+1
    cmp #>PROGRESS_ROW
    bne __b3
    lda progress_row_current
    cmp #<PROGRESS_ROW
    bne __b3
    // rom_verify::@8
    // gotoxy(x, ++y);
    // [1354] rom_verify::y#1 = ++ rom_verify::y#3 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [1355] gotoxy::y#27 = rom_verify::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1356] call gotoxy
    // [582] phi from rom_verify::@8 to gotoxy [phi:rom_verify::@8->gotoxy]
    // [582] phi gotoxy::y#30 = gotoxy::y#27 [phi:rom_verify::@8->gotoxy#0] -- register_copy 
    // [582] phi gotoxy::x#30 = PROGRESS_X [phi:rom_verify::@8->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1357] phi from rom_verify::@8 to rom_verify::@3 [phi:rom_verify::@8->rom_verify::@3]
    // [1357] phi rom_verify::y#10 = rom_verify::y#1 [phi:rom_verify::@8->rom_verify::@3#0] -- register_copy 
    // [1357] phi rom_verify::progress_row_current#4 = 0 [phi:rom_verify::@8->rom_verify::@3#1] -- vwum1=vbuc1 
    lda #<0
    sta progress_row_current
    sta progress_row_current+1
    // [1357] phi from rom_verify::@13 to rom_verify::@3 [phi:rom_verify::@13->rom_verify::@3]
    // [1357] phi rom_verify::y#10 = rom_verify::y#3 [phi:rom_verify::@13->rom_verify::@3#0] -- register_copy 
    // [1357] phi rom_verify::progress_row_current#4 = rom_verify::progress_row_current#3 [phi:rom_verify::@13->rom_verify::@3#1] -- register_copy 
    // rom_verify::@3
  __b3:
    // if (equal_bytes != PROGRESS_CELL)
    // [1358] if(rom_verify::equal_bytes#0!=PROGRESS_CELL) goto rom_verify::@4 -- vwum1_neq_vwuc1_then_la1 
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
    // [1359] stackpush(char) = '=' -- _stackpushbyte_=vbuc1 
    lda #'='
    pha
    // [1360] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // rom_verify::@5
  __b5:
    // ram_address += PROGRESS_CELL
    // [1362] rom_verify::ram_address#1 = rom_verify::ram_address#10 + PROGRESS_CELL -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address
    clc
    adc #<PROGRESS_CELL
    sta.z ram_address
    lda.z ram_address+1
    adc #>PROGRESS_CELL
    sta.z ram_address+1
    // rom_address += PROGRESS_CELL
    // [1363] rom_verify::rom_address#1 = rom_verify::rom_address#12 + PROGRESS_CELL -- vdum1=vdum1_plus_vwuc1 
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
    // [1364] rom_verify::progress_row_current#11 = rom_verify::progress_row_current#4 + PROGRESS_CELL -- vwum1=vwum1_plus_vwuc1 
    lda progress_row_current
    clc
    adc #<PROGRESS_CELL
    sta progress_row_current
    lda progress_row_current+1
    adc #>PROGRESS_CELL
    sta progress_row_current+1
    // if (ram_address == BRAM_HIGH)
    // [1365] if(rom_verify::ram_address#1!=$c000) goto rom_verify::@6 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address+1
    cmp #>$c000
    bne __b6
    lda.z ram_address
    cmp #<$c000
    bne __b6
    // rom_verify::@10
    // bram_bank++;
    // [1366] rom_verify::bram_bank#1 = ++ rom_verify::bram_bank#11 -- vbum1=_inc_vbum1 
    inc bram_bank
    // [1367] phi from rom_verify::@10 to rom_verify::@6 [phi:rom_verify::@10->rom_verify::@6]
    // [1367] phi rom_verify::bram_bank#24 = rom_verify::bram_bank#1 [phi:rom_verify::@10->rom_verify::@6#0] -- register_copy 
    // [1367] phi rom_verify::ram_address#6 = (char *)$a000 [phi:rom_verify::@10->rom_verify::@6#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1367] phi from rom_verify::@5 to rom_verify::@6 [phi:rom_verify::@5->rom_verify::@6]
    // [1367] phi rom_verify::bram_bank#24 = rom_verify::bram_bank#11 [phi:rom_verify::@5->rom_verify::@6#0] -- register_copy 
    // [1367] phi rom_verify::ram_address#6 = rom_verify::ram_address#1 [phi:rom_verify::@5->rom_verify::@6#1] -- register_copy 
    // rom_verify::@6
  __b6:
    // if (ram_address == RAM_HIGH)
    // [1368] if(rom_verify::ram_address#6!=$8000) goto rom_verify::@23 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address+1
    cmp #>$8000
    bne __b7
    lda.z ram_address
    cmp #<$8000
    bne __b7
    // [1370] phi from rom_verify::@6 to rom_verify::@7 [phi:rom_verify::@6->rom_verify::@7]
    // [1370] phi rom_verify::ram_address#11 = (char *)$a000 [phi:rom_verify::@6->rom_verify::@7#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1370] phi rom_verify::bram_bank#10 = 1 [phi:rom_verify::@6->rom_verify::@7#1] -- vbum1=vbuc1 
    lda #1
    sta bram_bank
    // [1369] phi from rom_verify::@6 to rom_verify::@23 [phi:rom_verify::@6->rom_verify::@23]
    // rom_verify::@23
    // [1370] phi from rom_verify::@23 to rom_verify::@7 [phi:rom_verify::@23->rom_verify::@7]
    // [1370] phi rom_verify::ram_address#11 = rom_verify::ram_address#6 [phi:rom_verify::@23->rom_verify::@7#0] -- register_copy 
    // [1370] phi rom_verify::bram_bank#10 = rom_verify::bram_bank#24 [phi:rom_verify::@23->rom_verify::@7#1] -- register_copy 
    // rom_verify::@7
  __b7:
    // PROGRESS_CELL - equal_bytes
    // [1371] rom_verify::$16 = PROGRESS_CELL - rom_verify::equal_bytes#0 -- vwuz1=vwuc1_minus_vwum2 
    sec
    lda #<PROGRESS_CELL
    sbc equal_bytes
    sta.z rom_verify__16
    lda #>PROGRESS_CELL
    sbc equal_bytes+1
    sta.z rom_verify__16+1
    // rom_different_bytes += (PROGRESS_CELL - equal_bytes)
    // [1372] rom_verify::rom_different_bytes#1 = rom_verify::rom_different_bytes#11 + rom_verify::$16 -- vdum1=vdum1_plus_vwuz2 
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
    // [1373] call snprintf_init
    jsr snprintf_init
    // [1374] phi from rom_verify::@7 to rom_verify::@14 [phi:rom_verify::@7->rom_verify::@14]
    // rom_verify::@14
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1375] call printf_str
    // [725] phi from rom_verify::@14 to printf_str [phi:rom_verify::@14->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:rom_verify::@14->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = rom_verify::s [phi:rom_verify::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@15
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1376] printf_ulong::uvalue#4 = rom_verify::rom_different_bytes#1 -- vdum1=vdum2 
    lda rom_different_bytes
    sta printf_ulong.uvalue
    lda rom_different_bytes+1
    sta printf_ulong.uvalue+1
    lda rom_different_bytes+2
    sta printf_ulong.uvalue+2
    lda rom_different_bytes+3
    sta printf_ulong.uvalue+3
    // [1377] call printf_ulong
    // [1397] phi from rom_verify::@15 to printf_ulong [phi:rom_verify::@15->printf_ulong]
    // [1397] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_verify::@15->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1397] phi printf_ulong::format_min_length#11 = 5 [phi:rom_verify::@15->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1397] phi printf_ulong::putc#11 = &snputc [phi:rom_verify::@15->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1397] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_verify::@15->printf_ulong#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1397] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#4 [phi:rom_verify::@15->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1378] phi from rom_verify::@15 to rom_verify::@16 [phi:rom_verify::@15->rom_verify::@16]
    // rom_verify::@16
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1379] call printf_str
    // [725] phi from rom_verify::@16 to printf_str [phi:rom_verify::@16->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:rom_verify::@16->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = rom_verify::s1 [phi:rom_verify::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@17
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1380] printf_uchar::uvalue#6 = rom_verify::bram_bank#10 -- vbum1=vbum2 
    lda bram_bank
    sta printf_uchar.uvalue
    // [1381] call printf_uchar
    // [1151] phi from rom_verify::@17 to printf_uchar [phi:rom_verify::@17->printf_uchar]
    // [1151] phi printf_uchar::format_zero_padding#11 = 1 [phi:rom_verify::@17->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1151] phi printf_uchar::format_min_length#11 = 2 [phi:rom_verify::@17->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1151] phi printf_uchar::putc#11 = &snputc [phi:rom_verify::@17->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1151] phi printf_uchar::format_radix#11 = HEXADECIMAL [phi:rom_verify::@17->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1151] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#6 [phi:rom_verify::@17->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1382] phi from rom_verify::@17 to rom_verify::@18 [phi:rom_verify::@17->rom_verify::@18]
    // rom_verify::@18
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1383] call printf_str
    // [725] phi from rom_verify::@18 to printf_str [phi:rom_verify::@18->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:rom_verify::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = s3 [phi:rom_verify::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s3
    sta.z printf_str.s
    lda #>@s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@19
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1384] printf_uint::uvalue#11 = (unsigned int)rom_verify::ram_address#11 -- vwum1=vwuz2 
    lda.z ram_address
    sta printf_uint.uvalue
    lda.z ram_address+1
    sta printf_uint.uvalue+1
    // [1385] call printf_uint
    // [734] phi from rom_verify::@19 to printf_uint [phi:rom_verify::@19->printf_uint]
    // [734] phi printf_uint::format_zero_padding#16 = 1 [phi:rom_verify::@19->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [734] phi printf_uint::format_min_length#16 = 4 [phi:rom_verify::@19->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [734] phi printf_uint::putc#16 = &snputc [phi:rom_verify::@19->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [734] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:rom_verify::@19->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [734] phi printf_uint::uvalue#16 = printf_uint::uvalue#11 [phi:rom_verify::@19->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1386] phi from rom_verify::@19 to rom_verify::@20 [phi:rom_verify::@19->rom_verify::@20]
    // rom_verify::@20
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1387] call printf_str
    // [725] phi from rom_verify::@20 to printf_str [phi:rom_verify::@20->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:rom_verify::@20->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = rom_verify::s3 [phi:rom_verify::@20->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@21
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1388] printf_ulong::uvalue#5 = rom_verify::rom_address#1 -- vdum1=vdum2 
    lda rom_address
    sta printf_ulong.uvalue
    lda rom_address+1
    sta printf_ulong.uvalue+1
    lda rom_address+2
    sta printf_ulong.uvalue+2
    lda rom_address+3
    sta printf_ulong.uvalue+3
    // [1389] call printf_ulong
    // [1397] phi from rom_verify::@21 to printf_ulong [phi:rom_verify::@21->printf_ulong]
    // [1397] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_verify::@21->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1397] phi printf_ulong::format_min_length#11 = 5 [phi:rom_verify::@21->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1397] phi printf_ulong::putc#11 = &snputc [phi:rom_verify::@21->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1397] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_verify::@21->printf_ulong#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1397] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#5 [phi:rom_verify::@21->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // rom_verify::@22
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1390] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1391] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_line(info_text)
    // [1393] call display_info_line
    // [965] phi from rom_verify::@22 to display_info_line [phi:rom_verify::@22->display_info_line]
    // [965] phi display_info_line::info_text#19 = info_text [phi:rom_verify::@22->display_info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_line.info_text
    lda #>@info_text
    sta.z display_info_line.info_text+1
    jsr display_info_line
    // [1344] phi from rom_verify::@22 to rom_verify::@1 [phi:rom_verify::@22->rom_verify::@1]
    // [1344] phi rom_verify::y#3 = rom_verify::y#10 [phi:rom_verify::@22->rom_verify::@1#0] -- register_copy 
    // [1344] phi rom_verify::progress_row_current#3 = rom_verify::progress_row_current#11 [phi:rom_verify::@22->rom_verify::@1#1] -- register_copy 
    // [1344] phi rom_verify::rom_different_bytes#11 = rom_verify::rom_different_bytes#1 [phi:rom_verify::@22->rom_verify::@1#2] -- register_copy 
    // [1344] phi rom_verify::ram_address#10 = rom_verify::ram_address#11 [phi:rom_verify::@22->rom_verify::@1#3] -- register_copy 
    // [1344] phi rom_verify::bram_bank#11 = rom_verify::bram_bank#10 [phi:rom_verify::@22->rom_verify::@1#4] -- register_copy 
    // [1344] phi rom_verify::rom_address#12 = rom_verify::rom_address#1 [phi:rom_verify::@22->rom_verify::@1#5] -- register_copy 
    jmp __b1
    // rom_verify::@4
  __b4:
    // cputc('*')
    // [1394] stackpush(char) = '*' -- _stackpushbyte_=vbuc1 
    lda #'*'
    pha
    // [1395] callexecute cputc  -- call_vprc1 
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
// void printf_ulong(__zp($6c) void (*putc)(char), __mem() unsigned long uvalue, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, __mem() char format_radix)
printf_ulong: {
    .label putc = $6c
    // printf_ulong::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1398] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // ultoa(uvalue, printf_buffer.digits, format.radix)
    // [1399] ultoa::value#1 = printf_ulong::uvalue#11
    // [1400] ultoa::radix#0 = printf_ulong::format_radix#11
    // [1401] call ultoa
    // Format number into buffer
    jsr ultoa
    // printf_ulong::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1402] printf_number_buffer::putc#0 = printf_ulong::putc#11
    // [1403] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [1404] printf_number_buffer::format_min_length#0 = printf_ulong::format_min_length#11
    // [1405] printf_number_buffer::format_zero_padding#0 = printf_ulong::format_zero_padding#11
    // [1406] call printf_number_buffer
  // Print using format
    // [1868] phi from printf_ulong::@2 to printf_number_buffer [phi:printf_ulong::@2->printf_number_buffer]
    // [1868] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#0 [phi:printf_ulong::@2->printf_number_buffer#0] -- register_copy 
    // [1868] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_ulong::@2->printf_number_buffer#1] -- register_copy 
    // [1868] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#0 [phi:printf_ulong::@2->printf_number_buffer#2] -- register_copy 
    // [1868] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#0 [phi:printf_ulong::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_ulong::@return
    // }
    // [1407] return 
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
// __mem() unsigned long rom_flash(__zp($d0) char rom_chip, __zp($c6) char rom_bank_start, __zp($3d) unsigned long file_size)
rom_flash: {
    .label rom_flash__29 = $59
    .label ram_address_sector = $6a
    .label ram_address = $76
    .label rom_chip = $d0
    .label rom_bank_start = $c6
    .label file_size = $3d
    // display_info_progress("Flashing ... (-) equal, (+) flashed, (!) error.")
    // [1409] call display_info_progress
  // Now we compare the RAM with the actual ROM contents.
    // [691] phi from rom_flash to display_info_progress [phi:rom_flash->display_info_progress]
    // [691] phi display_info_progress::info_text#14 = rom_flash::info_text [phi:rom_flash->display_info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_progress.info_text
    lda #>info_text
    sta.z display_info_progress.info_text+1
    jsr display_info_progress
    // rom_flash::@19
    // unsigned long rom_address_sector = rom_address_from_bank(rom_bank_start)
    // [1410] rom_address_from_bank::rom_bank#2 = rom_flash::rom_bank_start#0
    // [1411] call rom_address_from_bank
    // [2172] phi from rom_flash::@19 to rom_address_from_bank [phi:rom_flash::@19->rom_address_from_bank]
    // [2172] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#2 [phi:rom_flash::@19->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address_sector = rom_address_from_bank(rom_bank_start)
    // [1412] rom_address_from_bank::return#4 = rom_address_from_bank::return#0 -- vdum1=vdum2 
    lda rom_address_from_bank.return
    sta rom_address_from_bank.return_2
    lda rom_address_from_bank.return+1
    sta rom_address_from_bank.return_2+1
    lda rom_address_from_bank.return+2
    sta rom_address_from_bank.return_2+2
    lda rom_address_from_bank.return+3
    sta rom_address_from_bank.return_2+3
    // rom_flash::@20
    // [1413] rom_flash::rom_address_sector#0 = rom_address_from_bank::return#4
    // unsigned long rom_boundary = rom_address_sector + file_size
    // [1414] rom_flash::rom_boundary#0 = rom_flash::rom_address_sector#0 + rom_flash::file_size#0 -- vdum1=vdum2_plus_vduz3 
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
    // display_info_rom(rom_chip, STATUS_FLASHING, "Flashing ...")
    // [1415] display_info_rom::rom_chip#2 = rom_flash::rom_chip#0 -- vbuz1=vbuz2 
    lda.z rom_chip
    sta.z display_info_rom.rom_chip
    // [1416] call display_info_rom
    // [1171] phi from rom_flash::@20 to display_info_rom [phi:rom_flash::@20->display_info_rom]
    // [1171] phi display_info_rom::info_text#16 = rom_flash::info_text1 [phi:rom_flash::@20->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_rom.info_text
    lda #>info_text1
    sta.z display_info_rom.info_text+1
    // [1171] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#2 [phi:rom_flash::@20->display_info_rom#1] -- register_copy 
    // [1171] phi display_info_rom::info_status#16 = STATUS_FLASHING [phi:rom_flash::@20->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHING
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // [1417] phi from rom_flash::@20 to rom_flash::@1 [phi:rom_flash::@20->rom_flash::@1]
    // [1417] phi rom_flash::y_sector#13 = PROGRESS_Y [phi:rom_flash::@20->rom_flash::@1#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y_sector
    // [1417] phi rom_flash::x_sector#10 = PROGRESS_X [phi:rom_flash::@20->rom_flash::@1#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [1417] phi rom_flash::flash_errors#10 = 0 [phi:rom_flash::@20->rom_flash::@1#2] -- vdum1=vduc1 
    lda #<0
    sta flash_errors
    sta flash_errors+1
    lda #<0>>$10
    sta flash_errors+2
    lda #>0>>$10
    sta flash_errors+3
    // [1417] phi rom_flash::ram_address_sector#11 = (char *)$6000 [phi:rom_flash::@20->rom_flash::@1#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z ram_address_sector
    lda #>$6000
    sta.z ram_address_sector+1
    // [1417] phi rom_flash::bram_bank_sector#14 = 0 [phi:rom_flash::@20->rom_flash::@1#4] -- vbum1=vbuc1 
    lda #0
    sta bram_bank_sector
    // [1417] phi rom_flash::rom_address_sector#12 = rom_flash::rom_address_sector#0 [phi:rom_flash::@20->rom_flash::@1#5] -- register_copy 
    // rom_flash::@1
  __b1:
    // while (rom_address_sector < rom_boundary)
    // [1418] if(rom_flash::rom_address_sector#12<rom_flash::rom_boundary#0) goto rom_flash::@2 -- vdum1_lt_vdum2_then_la1 
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
    // [1419] phi from rom_flash::@1 to rom_flash::@3 [phi:rom_flash::@1->rom_flash::@3]
    // rom_flash::@3
    // display_info_line("Flashed ...")
    // [1420] call display_info_line
    // [965] phi from rom_flash::@3 to display_info_line [phi:rom_flash::@3->display_info_line]
    // [965] phi display_info_line::info_text#19 = rom_flash::info_text2 [phi:rom_flash::@3->display_info_line#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z display_info_line.info_text
    lda #>info_text2
    sta.z display_info_line.info_text+1
    jsr display_info_line
    // rom_flash::@return
    // }
    // [1421] return 
    rts
    // rom_flash::@2
  __b2:
    // unsigned int equal_bytes = rom_compare(bram_bank_sector, (ram_ptr_t)ram_address_sector, rom_address_sector, ROM_SECTOR)
    // [1422] rom_compare::bank_ram#1 = rom_flash::bram_bank_sector#14 -- vbuz1=vbum2 
    lda bram_bank_sector
    sta.z rom_compare.bank_ram_1
    // [1423] rom_compare::ptr_ram#2 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z rom_compare.ptr_ram
    lda.z ram_address_sector+1
    sta.z rom_compare.ptr_ram+1
    // [1424] rom_compare::rom_compare_address#1 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_compare.rom_compare_address
    lda rom_address_sector+1
    sta.z rom_compare.rom_compare_address+1
    lda rom_address_sector+2
    sta.z rom_compare.rom_compare_address+2
    lda rom_address_sector+3
    sta.z rom_compare.rom_compare_address+3
    // [1425] call rom_compare
  // {asm{.byte $db}}
    // [2176] phi from rom_flash::@2 to rom_compare [phi:rom_flash::@2->rom_compare]
    // [2176] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#2 [phi:rom_flash::@2->rom_compare#0] -- register_copy 
    // [2176] phi rom_compare::rom_compare_size#11 = $1000 [phi:rom_flash::@2->rom_compare#1] -- vwuz1=vwuc1 
    lda #<$1000
    sta.z rom_compare.rom_compare_size
    lda #>$1000
    sta.z rom_compare.rom_compare_size+1
    // [2176] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#1 [phi:rom_flash::@2->rom_compare#2] -- register_copy 
    // [2176] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#1 [phi:rom_flash::@2->rom_compare#3] -- vbum1=vbuz2 
    lda.z rom_compare.bank_ram_1
    sta rom_compare.bank_set_bram1_bank
    jsr rom_compare
    // unsigned int equal_bytes = rom_compare(bram_bank_sector, (ram_ptr_t)ram_address_sector, rom_address_sector, ROM_SECTOR)
    // [1426] rom_compare::return#3 = rom_compare::equal_bytes#2
    // rom_flash::@21
    // [1427] rom_flash::equal_bytes#0 = rom_compare::return#3
    // if (equal_bytes != ROM_SECTOR)
    // [1428] if(rom_flash::equal_bytes#0!=$1000) goto rom_flash::@5 -- vwum1_neq_vwuc1_then_la1 
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
    // [1429] cputsxy::x#1 = rom_flash::x_sector#10 -- vbum1=vbum2 
    lda x_sector
    sta cputsxy.x
    // [1430] cputsxy::y#1 = rom_flash::y_sector#13 -- vbum1=vbum2 
    lda y_sector
    sta cputsxy.y
    // [1431] call cputsxy
    // [669] phi from rom_flash::@16 to cputsxy [phi:rom_flash::@16->cputsxy]
    // [669] phi cputsxy::s#4 = rom_flash::s [phi:rom_flash::@16->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z cputsxy.s
    lda #>s
    sta.z cputsxy.s+1
    // [669] phi cputsxy::y#4 = cputsxy::y#1 [phi:rom_flash::@16->cputsxy#1] -- register_copy 
    // [669] phi cputsxy::x#4 = cputsxy::x#1 [phi:rom_flash::@16->cputsxy#2] -- register_copy 
    jsr cputsxy
    // [1432] phi from rom_flash::@12 rom_flash::@16 to rom_flash::@4 [phi:rom_flash::@12/rom_flash::@16->rom_flash::@4]
    // [1432] phi rom_flash::flash_errors#13 = rom_flash::flash_errors#1 [phi:rom_flash::@12/rom_flash::@16->rom_flash::@4#0] -- register_copy 
    // rom_flash::@4
  __b4:
    // ram_address_sector += ROM_SECTOR
    // [1433] rom_flash::ram_address_sector#1 = rom_flash::ram_address_sector#11 + $1000 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address_sector
    clc
    adc #<$1000
    sta.z ram_address_sector
    lda.z ram_address_sector+1
    adc #>$1000
    sta.z ram_address_sector+1
    // rom_address_sector += ROM_SECTOR
    // [1434] rom_flash::rom_address_sector#1 = rom_flash::rom_address_sector#12 + $1000 -- vdum1=vdum1_plus_vwuc1 
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
    // [1435] if(rom_flash::ram_address_sector#1!=$c000) goto rom_flash::@13 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address_sector+1
    cmp #>$c000
    bne __b13
    lda.z ram_address_sector
    cmp #<$c000
    bne __b13
    // rom_flash::@17
    // bram_bank_sector++;
    // [1436] rom_flash::bram_bank_sector#1 = ++ rom_flash::bram_bank_sector#14 -- vbum1=_inc_vbum1 
    inc bram_bank_sector
    // [1437] phi from rom_flash::@17 to rom_flash::@13 [phi:rom_flash::@17->rom_flash::@13]
    // [1437] phi rom_flash::bram_bank_sector#38 = rom_flash::bram_bank_sector#1 [phi:rom_flash::@17->rom_flash::@13#0] -- register_copy 
    // [1437] phi rom_flash::ram_address_sector#8 = (char *)$a000 [phi:rom_flash::@17->rom_flash::@13#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address_sector
    lda #>$a000
    sta.z ram_address_sector+1
    // [1437] phi from rom_flash::@4 to rom_flash::@13 [phi:rom_flash::@4->rom_flash::@13]
    // [1437] phi rom_flash::bram_bank_sector#38 = rom_flash::bram_bank_sector#14 [phi:rom_flash::@4->rom_flash::@13#0] -- register_copy 
    // [1437] phi rom_flash::ram_address_sector#8 = rom_flash::ram_address_sector#1 [phi:rom_flash::@4->rom_flash::@13#1] -- register_copy 
    // rom_flash::@13
  __b13:
    // if (ram_address_sector == RAM_HIGH)
    // [1438] if(rom_flash::ram_address_sector#8!=$8000) goto rom_flash::@44 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address_sector+1
    cmp #>$8000
    bne __b14
    lda.z ram_address_sector
    cmp #<$8000
    bne __b14
    // [1440] phi from rom_flash::@13 to rom_flash::@14 [phi:rom_flash::@13->rom_flash::@14]
    // [1440] phi rom_flash::ram_address_sector#15 = (char *)$a000 [phi:rom_flash::@13->rom_flash::@14#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address_sector
    lda #>$a000
    sta.z ram_address_sector+1
    // [1440] phi rom_flash::bram_bank_sector#12 = 1 [phi:rom_flash::@13->rom_flash::@14#1] -- vbum1=vbuc1 
    lda #1
    sta bram_bank_sector
    // [1439] phi from rom_flash::@13 to rom_flash::@44 [phi:rom_flash::@13->rom_flash::@44]
    // rom_flash::@44
    // [1440] phi from rom_flash::@44 to rom_flash::@14 [phi:rom_flash::@44->rom_flash::@14]
    // [1440] phi rom_flash::ram_address_sector#15 = rom_flash::ram_address_sector#8 [phi:rom_flash::@44->rom_flash::@14#0] -- register_copy 
    // [1440] phi rom_flash::bram_bank_sector#12 = rom_flash::bram_bank_sector#38 [phi:rom_flash::@44->rom_flash::@14#1] -- register_copy 
    // rom_flash::@14
  __b14:
    // x_sector += 8
    // [1441] rom_flash::x_sector#1 = rom_flash::x_sector#10 + 8 -- vbum1=vbum1_plus_vbuc1 
    lda #8
    clc
    adc x_sector
    sta x_sector
    // rom_address_sector % PROGRESS_ROW
    // [1442] rom_flash::$29 = rom_flash::rom_address_sector#1 & PROGRESS_ROW-1 -- vduz1=vdum2_band_vduc1 
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
    // [1443] if(0!=rom_flash::$29) goto rom_flash::@15 -- 0_neq_vduz1_then_la1 
    lda.z rom_flash__29
    ora.z rom_flash__29+1
    ora.z rom_flash__29+2
    ora.z rom_flash__29+3
    bne __b15
    // rom_flash::@18
    // y_sector++;
    // [1444] rom_flash::y_sector#1 = ++ rom_flash::y_sector#13 -- vbum1=_inc_vbum1 
    inc y_sector
    // [1445] phi from rom_flash::@18 to rom_flash::@15 [phi:rom_flash::@18->rom_flash::@15]
    // [1445] phi rom_flash::y_sector#18 = rom_flash::y_sector#1 [phi:rom_flash::@18->rom_flash::@15#0] -- register_copy 
    // [1445] phi rom_flash::x_sector#20 = PROGRESS_X [phi:rom_flash::@18->rom_flash::@15#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [1445] phi from rom_flash::@14 to rom_flash::@15 [phi:rom_flash::@14->rom_flash::@15]
    // [1445] phi rom_flash::y_sector#18 = rom_flash::y_sector#13 [phi:rom_flash::@14->rom_flash::@15#0] -- register_copy 
    // [1445] phi rom_flash::x_sector#20 = rom_flash::x_sector#1 [phi:rom_flash::@14->rom_flash::@15#1] -- register_copy 
    // rom_flash::@15
  __b15:
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1446] call snprintf_init
    jsr snprintf_init
    // rom_flash::@40
    // [1447] printf_ulong::uvalue#8 = rom_flash::flash_errors#13 -- vdum1=vdum2 
    lda flash_errors
    sta printf_ulong.uvalue
    lda flash_errors+1
    sta printf_ulong.uvalue+1
    lda flash_errors+2
    sta printf_ulong.uvalue+2
    lda flash_errors+3
    sta printf_ulong.uvalue+3
    // [1448] call printf_ulong
    // [1397] phi from rom_flash::@40 to printf_ulong [phi:rom_flash::@40->printf_ulong]
    // [1397] phi printf_ulong::format_zero_padding#11 = 0 [phi:rom_flash::@40->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1397] phi printf_ulong::format_min_length#11 = 0 [phi:rom_flash::@40->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1397] phi printf_ulong::putc#11 = &snputc [phi:rom_flash::@40->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1397] phi printf_ulong::format_radix#11 = DECIMAL [phi:rom_flash::@40->printf_ulong#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1397] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#8 [phi:rom_flash::@40->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1449] phi from rom_flash::@40 to rom_flash::@41 [phi:rom_flash::@40->rom_flash::@41]
    // rom_flash::@41
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1450] call printf_str
    // [725] phi from rom_flash::@41 to printf_str [phi:rom_flash::@41->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:rom_flash::@41->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = rom_flash::s6 [phi:rom_flash::@41->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@42
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1451] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1452] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_FLASHING, info_text)
    // [1454] display_info_rom::rom_chip#3 = rom_flash::rom_chip#0 -- vbuz1=vbuz2 
    lda.z rom_chip
    sta.z display_info_rom.rom_chip
    // [1455] call display_info_rom
    // [1171] phi from rom_flash::@42 to display_info_rom [phi:rom_flash::@42->display_info_rom]
    // [1171] phi display_info_rom::info_text#16 = info_text [phi:rom_flash::@42->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1171] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#3 [phi:rom_flash::@42->display_info_rom#1] -- register_copy 
    // [1171] phi display_info_rom::info_status#16 = STATUS_FLASHING [phi:rom_flash::@42->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHING
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // [1417] phi from rom_flash::@42 to rom_flash::@1 [phi:rom_flash::@42->rom_flash::@1]
    // [1417] phi rom_flash::y_sector#13 = rom_flash::y_sector#18 [phi:rom_flash::@42->rom_flash::@1#0] -- register_copy 
    // [1417] phi rom_flash::x_sector#10 = rom_flash::x_sector#20 [phi:rom_flash::@42->rom_flash::@1#1] -- register_copy 
    // [1417] phi rom_flash::flash_errors#10 = rom_flash::flash_errors#13 [phi:rom_flash::@42->rom_flash::@1#2] -- register_copy 
    // [1417] phi rom_flash::ram_address_sector#11 = rom_flash::ram_address_sector#15 [phi:rom_flash::@42->rom_flash::@1#3] -- register_copy 
    // [1417] phi rom_flash::bram_bank_sector#14 = rom_flash::bram_bank_sector#12 [phi:rom_flash::@42->rom_flash::@1#4] -- register_copy 
    // [1417] phi rom_flash::rom_address_sector#12 = rom_flash::rom_address_sector#1 [phi:rom_flash::@42->rom_flash::@1#5] -- register_copy 
    jmp __b1
    // [1456] phi from rom_flash::@21 to rom_flash::@5 [phi:rom_flash::@21->rom_flash::@5]
  __b3:
    // [1456] phi rom_flash::retries#12 = 0 [phi:rom_flash::@21->rom_flash::@5#0] -- vbum1=vbuc1 
    lda #0
    sta retries
    // [1456] phi rom_flash::flash_errors_sector#11 = 0 [phi:rom_flash::@21->rom_flash::@5#1] -- vwum1=vwuc1 
    sta flash_errors_sector
    sta flash_errors_sector+1
    // [1456] phi from rom_flash::@43 to rom_flash::@5 [phi:rom_flash::@43->rom_flash::@5]
    // [1456] phi rom_flash::retries#12 = rom_flash::retries#1 [phi:rom_flash::@43->rom_flash::@5#0] -- register_copy 
    // [1456] phi rom_flash::flash_errors_sector#11 = rom_flash::flash_errors_sector#10 [phi:rom_flash::@43->rom_flash::@5#1] -- register_copy 
    // rom_flash::@5
  __b5:
    // rom_sector_erase(rom_address_sector)
    // [1457] rom_sector_erase::address#0 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_sector_erase.address
    lda rom_address_sector+1
    sta.z rom_sector_erase.address+1
    lda rom_address_sector+2
    sta.z rom_sector_erase.address+2
    lda rom_address_sector+3
    sta.z rom_sector_erase.address+3
    // [1458] call rom_sector_erase
    // [2232] phi from rom_flash::@5 to rom_sector_erase [phi:rom_flash::@5->rom_sector_erase]
    jsr rom_sector_erase
    // rom_flash::@22
    // unsigned long rom_sector_boundary = rom_address_sector + ROM_SECTOR
    // [1459] rom_flash::rom_sector_boundary#0 = rom_flash::rom_address_sector#12 + $1000 -- vdum1=vdum2_plus_vwuc1 
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
    // [1460] gotoxy::x#28 = rom_flash::x_sector#10 -- vbum1=vbum2 
    lda x_sector
    sta gotoxy.x
    // [1461] gotoxy::y#28 = rom_flash::y_sector#13 -- vbum1=vbum2 
    lda y_sector
    sta gotoxy.y
    // [1462] call gotoxy
    // [582] phi from rom_flash::@22 to gotoxy [phi:rom_flash::@22->gotoxy]
    // [582] phi gotoxy::y#30 = gotoxy::y#28 [phi:rom_flash::@22->gotoxy#0] -- register_copy 
    // [582] phi gotoxy::x#30 = gotoxy::x#28 [phi:rom_flash::@22->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1463] phi from rom_flash::@22 to rom_flash::@23 [phi:rom_flash::@22->rom_flash::@23]
    // rom_flash::@23
    // printf("........")
    // [1464] call printf_str
    // [725] phi from rom_flash::@23 to printf_str [phi:rom_flash::@23->printf_str]
    // [725] phi printf_str::putc#71 = &cputc [phi:rom_flash::@23->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = rom_flash::s1 [phi:rom_flash::@23->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@24
    // [1465] rom_flash::rom_address#26 = rom_flash::rom_address_sector#12 -- vdum1=vdum2 
    lda rom_address_sector
    sta rom_address
    lda rom_address_sector+1
    sta rom_address+1
    lda rom_address_sector+2
    sta rom_address+2
    lda rom_address_sector+3
    sta rom_address+3
    // [1466] rom_flash::ram_address#26 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z ram_address
    lda.z ram_address_sector+1
    sta.z ram_address+1
    // [1467] rom_flash::x#26 = rom_flash::x_sector#10 -- vbum1=vbum2 
    lda x_sector
    sta x
    // [1468] phi from rom_flash::@10 rom_flash::@24 to rom_flash::@6 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6]
    // [1468] phi rom_flash::x#10 = rom_flash::x#1 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#0] -- register_copy 
    // [1468] phi rom_flash::ram_address#10 = rom_flash::ram_address#1 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#1] -- register_copy 
    // [1468] phi rom_flash::flash_errors_sector#10 = rom_flash::flash_errors_sector#8 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#2] -- register_copy 
    // [1468] phi rom_flash::rom_address#11 = rom_flash::rom_address#1 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#3] -- register_copy 
    // rom_flash::@6
  __b6:
    // while (rom_address < rom_sector_boundary)
    // [1469] if(rom_flash::rom_address#11<rom_flash::rom_sector_boundary#0) goto rom_flash::@7 -- vdum1_lt_vdum2_then_la1 
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
    // [1470] rom_flash::retries#1 = ++ rom_flash::retries#12 -- vbum1=_inc_vbum1 
    inc retries
    // while (flash_errors_sector && retries <= 3)
    // [1471] if(0==rom_flash::flash_errors_sector#10) goto rom_flash::@12 -- 0_eq_vwum1_then_la1 
    lda flash_errors_sector
    ora flash_errors_sector+1
    beq __b12
    // rom_flash::@43
    // [1472] if(rom_flash::retries#1<3+1) goto rom_flash::@5 -- vbum1_lt_vbuc1_then_la1 
    lda retries
    cmp #3+1
    bcs !__b5+
    jmp __b5
  !__b5:
    // rom_flash::@12
  __b12:
    // flash_errors += flash_errors_sector
    // [1473] rom_flash::flash_errors#1 = rom_flash::flash_errors#10 + rom_flash::flash_errors_sector#10 -- vdum1=vdum1_plus_vwum2 
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
    // [1474] printf_ulong::uvalue#7 = rom_flash::flash_errors_sector#10 + rom_flash::flash_errors#10 -- vdum1=vwum2_plus_vdum3 
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
    // [1475] call snprintf_init
    jsr snprintf_init
    // [1476] phi from rom_flash::@7 to rom_flash::@25 [phi:rom_flash::@7->rom_flash::@25]
    // rom_flash::@25
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1477] call printf_str
    // [725] phi from rom_flash::@25 to printf_str [phi:rom_flash::@25->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:rom_flash::@25->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = rom_flash::s2 [phi:rom_flash::@25->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@26
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1478] printf_uchar::uvalue#7 = rom_flash::bram_bank_sector#14 -- vbum1=vbum2 
    lda bram_bank_sector
    sta printf_uchar.uvalue
    // [1479] call printf_uchar
    // [1151] phi from rom_flash::@26 to printf_uchar [phi:rom_flash::@26->printf_uchar]
    // [1151] phi printf_uchar::format_zero_padding#11 = 1 [phi:rom_flash::@26->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1151] phi printf_uchar::format_min_length#11 = 2 [phi:rom_flash::@26->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1151] phi printf_uchar::putc#11 = &snputc [phi:rom_flash::@26->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1151] phi printf_uchar::format_radix#11 = HEXADECIMAL [phi:rom_flash::@26->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1151] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#7 [phi:rom_flash::@26->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1480] phi from rom_flash::@26 to rom_flash::@27 [phi:rom_flash::@26->rom_flash::@27]
    // rom_flash::@27
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1481] call printf_str
    // [725] phi from rom_flash::@27 to printf_str [phi:rom_flash::@27->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:rom_flash::@27->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = s3 [phi:rom_flash::@27->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@28
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1482] printf_uint::uvalue#12 = (unsigned int)rom_flash::ram_address_sector#11 -- vwum1=vwuz2 
    lda.z ram_address_sector
    sta printf_uint.uvalue
    lda.z ram_address_sector+1
    sta printf_uint.uvalue+1
    // [1483] call printf_uint
    // [734] phi from rom_flash::@28 to printf_uint [phi:rom_flash::@28->printf_uint]
    // [734] phi printf_uint::format_zero_padding#16 = 1 [phi:rom_flash::@28->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [734] phi printf_uint::format_min_length#16 = 4 [phi:rom_flash::@28->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [734] phi printf_uint::putc#16 = &snputc [phi:rom_flash::@28->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [734] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:rom_flash::@28->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [734] phi printf_uint::uvalue#16 = printf_uint::uvalue#12 [phi:rom_flash::@28->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1484] phi from rom_flash::@28 to rom_flash::@29 [phi:rom_flash::@28->rom_flash::@29]
    // rom_flash::@29
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1485] call printf_str
    // [725] phi from rom_flash::@29 to printf_str [phi:rom_flash::@29->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:rom_flash::@29->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = rom_flash::s4 [phi:rom_flash::@29->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@30
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1486] printf_ulong::uvalue#6 = rom_flash::rom_address_sector#12 -- vdum1=vdum2 
    lda rom_address_sector
    sta printf_ulong.uvalue
    lda rom_address_sector+1
    sta printf_ulong.uvalue+1
    lda rom_address_sector+2
    sta printf_ulong.uvalue+2
    lda rom_address_sector+3
    sta printf_ulong.uvalue+3
    // [1487] call printf_ulong
    // [1397] phi from rom_flash::@30 to printf_ulong [phi:rom_flash::@30->printf_ulong]
    // [1397] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_flash::@30->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1397] phi printf_ulong::format_min_length#11 = 5 [phi:rom_flash::@30->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1397] phi printf_ulong::putc#11 = &snputc [phi:rom_flash::@30->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1397] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_flash::@30->printf_ulong#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1397] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#6 [phi:rom_flash::@30->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1488] phi from rom_flash::@30 to rom_flash::@31 [phi:rom_flash::@30->rom_flash::@31]
    // rom_flash::@31
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1489] call printf_str
    // [725] phi from rom_flash::@31 to printf_str [phi:rom_flash::@31->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:rom_flash::@31->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = rom_flash::s5 [phi:rom_flash::@31->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@32
    // [1490] printf_ulong::uvalue#20 = printf_ulong::uvalue#7 -- vdum1=vdum2 
    lda printf_ulong.uvalue_1
    sta printf_ulong.uvalue
    lda printf_ulong.uvalue_1+1
    sta printf_ulong.uvalue+1
    lda printf_ulong.uvalue_1+2
    sta printf_ulong.uvalue+2
    lda printf_ulong.uvalue_1+3
    sta printf_ulong.uvalue+3
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1491] call printf_ulong
    // [1397] phi from rom_flash::@32 to printf_ulong [phi:rom_flash::@32->printf_ulong]
    // [1397] phi printf_ulong::format_zero_padding#11 = 0 [phi:rom_flash::@32->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1397] phi printf_ulong::format_min_length#11 = 0 [phi:rom_flash::@32->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1397] phi printf_ulong::putc#11 = &snputc [phi:rom_flash::@32->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1397] phi printf_ulong::format_radix#11 = DECIMAL [phi:rom_flash::@32->printf_ulong#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1397] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#20 [phi:rom_flash::@32->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1492] phi from rom_flash::@32 to rom_flash::@33 [phi:rom_flash::@32->rom_flash::@33]
    // rom_flash::@33
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1493] call printf_str
    // [725] phi from rom_flash::@33 to printf_str [phi:rom_flash::@33->printf_str]
    // [725] phi printf_str::putc#71 = &snputc [phi:rom_flash::@33->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [725] phi printf_str::s#71 = rom_flash::s6 [phi:rom_flash::@33->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@34
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1494] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1495] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_line(info_text)
    // [1497] call display_info_line
    // [965] phi from rom_flash::@34 to display_info_line [phi:rom_flash::@34->display_info_line]
    // [965] phi display_info_line::info_text#19 = info_text [phi:rom_flash::@34->display_info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_line.info_text
    lda #>@info_text
    sta.z display_info_line.info_text+1
    jsr display_info_line
    // rom_flash::@35
    // unsigned long written_bytes = rom_write(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1498] rom_write::flash_ram_bank#0 = rom_flash::bram_bank_sector#14 -- vbuz1=vbum2 
    lda bram_bank_sector
    sta.z rom_write.flash_ram_bank
    // [1499] rom_write::flash_ram_address#1 = rom_flash::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_write.flash_ram_address
    lda.z ram_address+1
    sta.z rom_write.flash_ram_address+1
    // [1500] rom_write::flash_rom_address#1 = rom_flash::rom_address#11 -- vduz1=vdum2 
    lda rom_address
    sta.z rom_write.flash_rom_address
    lda rom_address+1
    sta.z rom_write.flash_rom_address+1
    lda rom_address+2
    sta.z rom_write.flash_rom_address+2
    lda rom_address+3
    sta.z rom_write.flash_rom_address+3
    // [1501] call rom_write
    jsr rom_write
    // rom_flash::@36
    // rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1502] rom_compare::bank_ram#2 = rom_flash::bram_bank_sector#14 -- vbuz1=vbum2 
    lda bram_bank_sector
    sta.z rom_compare.bank_ram_2
    // [1503] rom_compare::ptr_ram#3 = rom_flash::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_compare.ptr_ram
    lda.z ram_address+1
    sta.z rom_compare.ptr_ram+1
    // [1504] rom_compare::rom_compare_address#2 = rom_flash::rom_address#11 -- vduz1=vdum2 
    lda rom_address
    sta.z rom_compare.rom_compare_address
    lda rom_address+1
    sta.z rom_compare.rom_compare_address+1
    lda rom_address+2
    sta.z rom_compare.rom_compare_address+2
    lda rom_address+3
    sta.z rom_compare.rom_compare_address+3
    // [1505] call rom_compare
    // [2176] phi from rom_flash::@36 to rom_compare [phi:rom_flash::@36->rom_compare]
    // [2176] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#3 [phi:rom_flash::@36->rom_compare#0] -- register_copy 
    // [2176] phi rom_compare::rom_compare_size#11 = PROGRESS_CELL [phi:rom_flash::@36->rom_compare#1] -- vwuz1=vwuc1 
    lda #<PROGRESS_CELL
    sta.z rom_compare.rom_compare_size
    lda #>PROGRESS_CELL
    sta.z rom_compare.rom_compare_size+1
    // [2176] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#2 [phi:rom_flash::@36->rom_compare#2] -- register_copy 
    // [2176] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#2 [phi:rom_flash::@36->rom_compare#3] -- vbum1=vbuz2 
    lda.z rom_compare.bank_ram_2
    sta rom_compare.bank_set_bram1_bank
    jsr rom_compare
    // rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1506] rom_compare::return#4 = rom_compare::equal_bytes#2
    // rom_flash::@37
    // equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1507] rom_flash::equal_bytes#1 = rom_compare::return#4 -- vwum1=vwum2 
    lda rom_compare.return
    sta equal_bytes_1
    lda rom_compare.return+1
    sta equal_bytes_1+1
    // gotoxy(x, y)
    // [1508] gotoxy::x#29 = rom_flash::x#10 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1509] gotoxy::y#29 = rom_flash::y_sector#13 -- vbum1=vbum2 
    lda y_sector
    sta gotoxy.y
    // [1510] call gotoxy
    // [582] phi from rom_flash::@37 to gotoxy [phi:rom_flash::@37->gotoxy]
    // [582] phi gotoxy::y#30 = gotoxy::y#29 [phi:rom_flash::@37->gotoxy#0] -- register_copy 
    // [582] phi gotoxy::x#30 = gotoxy::x#29 [phi:rom_flash::@37->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_flash::@38
    // if (equal_bytes != PROGRESS_CELL)
    // [1511] if(rom_flash::equal_bytes#1!=PROGRESS_CELL) goto rom_flash::@9 -- vwum1_neq_vwuc1_then_la1 
    lda equal_bytes_1+1
    cmp #>PROGRESS_CELL
    bne __b9
    lda equal_bytes_1
    cmp #<PROGRESS_CELL
    bne __b9
    // rom_flash::@11
    // cputcxy(x,y,'+')
    // [1512] cputcxy::x#14 = rom_flash::x#10 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1513] cputcxy::y#14 = rom_flash::y_sector#13 -- vbum1=vbum2 
    lda y_sector
    sta cputcxy.y
    // [1514] call cputcxy
    // [1771] phi from rom_flash::@11 to cputcxy [phi:rom_flash::@11->cputcxy]
    // [1771] phi cputcxy::c#15 = '+' [phi:rom_flash::@11->cputcxy#0] -- vbum1=vbuc1 
    lda #'+'
    sta cputcxy.c
    // [1771] phi cputcxy::y#15 = cputcxy::y#14 [phi:rom_flash::@11->cputcxy#1] -- register_copy 
    // [1771] phi cputcxy::x#15 = cputcxy::x#14 [phi:rom_flash::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [1515] phi from rom_flash::@11 rom_flash::@39 to rom_flash::@10 [phi:rom_flash::@11/rom_flash::@39->rom_flash::@10]
    // [1515] phi rom_flash::flash_errors_sector#8 = rom_flash::flash_errors_sector#10 [phi:rom_flash::@11/rom_flash::@39->rom_flash::@10#0] -- register_copy 
    // rom_flash::@10
  __b10:
    // ram_address += PROGRESS_CELL
    // [1516] rom_flash::ram_address#1 = rom_flash::ram_address#10 + PROGRESS_CELL -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address
    clc
    adc #<PROGRESS_CELL
    sta.z ram_address
    lda.z ram_address+1
    adc #>PROGRESS_CELL
    sta.z ram_address+1
    // rom_address += PROGRESS_CELL
    // [1517] rom_flash::rom_address#1 = rom_flash::rom_address#11 + PROGRESS_CELL -- vdum1=vdum1_plus_vwuc1 
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
    // [1518] rom_flash::x#1 = ++ rom_flash::x#10 -- vbum1=_inc_vbum1 
    inc x
    jmp __b6
    // rom_flash::@9
  __b9:
    // cputcxy(x,y,'!')
    // [1519] cputcxy::x#13 = rom_flash::x#10 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1520] cputcxy::y#13 = rom_flash::y_sector#13 -- vbum1=vbum2 
    lda y_sector
    sta cputcxy.y
    // [1521] call cputcxy
    // [1771] phi from rom_flash::@9 to cputcxy [phi:rom_flash::@9->cputcxy]
    // [1771] phi cputcxy::c#15 = '!' [phi:rom_flash::@9->cputcxy#0] -- vbum1=vbuc1 
    lda #'!'
    sta cputcxy.c
    // [1771] phi cputcxy::y#15 = cputcxy::y#13 [phi:rom_flash::@9->cputcxy#1] -- register_copy 
    // [1771] phi cputcxy::x#15 = cputcxy::x#13 [phi:rom_flash::@9->cputcxy#2] -- register_copy 
    jsr cputcxy
    // rom_flash::@39
    // flash_errors_sector++;
    // [1522] rom_flash::flash_errors_sector#1 = ++ rom_flash::flash_errors_sector#10 -- vwum1=_inc_vwum1 
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
// __zp($5f) void * strchr(__zp($5f) const void *str, __mem() char c)
strchr: {
    .label ptr = $5f
    .label return = $5f
    .label str = $5f
    // [1524] strchr::ptr#6 = (char *)strchr::str#2
    // [1525] phi from strchr strchr::@3 to strchr::@1 [phi:strchr/strchr::@3->strchr::@1]
    // [1525] phi strchr::ptr#2 = strchr::ptr#6 [phi:strchr/strchr::@3->strchr::@1#0] -- register_copy 
    // strchr::@1
  __b1:
    // while(*ptr)
    // [1526] if(0!=*strchr::ptr#2) goto strchr::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (ptr),y
    cmp #0
    bne __b2
    // [1527] phi from strchr::@1 to strchr::@return [phi:strchr::@1->strchr::@return]
    // [1527] phi strchr::return#2 = (void *) 0 [phi:strchr::@1->strchr::@return#0] -- pvoz1=pvoc1 
    tya
    sta.z return
    sta.z return+1
    // strchr::@return
    // }
    // [1528] return 
    rts
    // strchr::@2
  __b2:
    // if(*ptr==c)
    // [1529] if(*strchr::ptr#2!=strchr::c#4) goto strchr::@3 -- _deref_pbuz1_neq_vbum2_then_la1 
    ldy #0
    lda (ptr),y
    cmp c
    bne __b3
    // strchr::@4
    // [1530] strchr::return#8 = (void *)strchr::ptr#2
    // [1527] phi from strchr::@4 to strchr::@return [phi:strchr::@4->strchr::@return]
    // [1527] phi strchr::return#2 = strchr::return#8 [phi:strchr::@4->strchr::@return#0] -- register_copy 
    rts
    // strchr::@3
  __b3:
    // ptr++;
    // [1531] strchr::ptr#1 = ++ strchr::ptr#2 -- pbuz1=_inc_pbuz1 
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
 * @brief 
 * 
 * @param info_status 
 * @param info_text 
 */
// void display_info_cx16_rom(char info_status, char *info_text)
display_info_cx16_rom: {
    .label info_text = 0
    // display_info_rom(0, info_status, info_text)
    // [1533] call display_info_rom
    // [1171] phi from display_info_cx16_rom to display_info_rom [phi:display_info_cx16_rom->display_info_rom]
    // [1171] phi display_info_rom::info_text#16 = display_info_cx16_rom::info_text#0 [phi:display_info_cx16_rom->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_rom.info_text
    lda #>info_text
    sta.z display_info_rom.info_text+1
    // [1171] phi display_info_rom::rom_chip#16 = 0 [phi:display_info_cx16_rom->display_info_rom#1] -- vbuz1=vbuc1 
    lda #0
    sta.z display_info_rom.rom_chip
    // [1171] phi display_info_rom::info_status#16 = STATUS_ISSUE [phi:display_info_cx16_rom->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // display_info_cx16_rom::@return
    // }
    // [1534] return 
    rts
}
  // strncpy
/// Copies up to n characters from the string pointed to, by src to dst.
/// In a case where the length of src is less than that of n, the remainder of dst will be padded with null bytes.
/// @param dst ? This is the pointer to the destination array where the content is to be copied.
/// @param src ? This is the string to be copied.
/// @param n ? The number of characters to be copied from source.
/// @return The destination
// char * strncpy(__zp($44) char *dst, __zp($56) const char *src, __mem() unsigned int n)
strncpy: {
    .label dst = $44
    .label src = $56
    // [1536] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [1536] phi strncpy::dst#3 = strncpy::dst#8 [phi:strncpy->strncpy::@1#0] -- register_copy 
    // [1536] phi strncpy::src#3 = strncpy::src#6 [phi:strncpy->strncpy::@1#1] -- register_copy 
    // [1536] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwum1=vwuc1 
    lda #<0
    sta i
    sta i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [1537] if(strncpy::i#2<strncpy::n#3) goto strncpy::@2 -- vwum1_lt_vwum2_then_la1 
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
    // [1538] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [1539] strncpy::c#0 = *strncpy::src#3 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta c
    // if(c)
    // [1540] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbum1_then_la1 
    beq __b3
    // strncpy::@4
    // src++;
    // [1541] strncpy::src#0 = ++ strncpy::src#3 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [1542] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [1542] phi strncpy::src#7 = strncpy::src#3 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [1543] *strncpy::dst#3 = strncpy::c#0 -- _deref_pbuz1=vbum2 
    lda c
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [1544] strncpy::dst#0 = ++ strncpy::dst#3 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [1545] strncpy::i#1 = ++ strncpy::i#2 -- vwum1=_inc_vwum1 
    inc i
    bne !+
    inc i+1
  !:
    // [1536] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [1536] phi strncpy::dst#3 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [1536] phi strncpy::src#3 = strncpy::src#7 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [1536] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
    jmp __b1
  .segment Data
    c: .byte 0
    i: .word 0
    n: .word 0
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
// void display_info_led(__zp($61) char x, __zp($74) char y, __zp($72) char tc, char bc)
display_info_led: {
    .label tc = $72
    .label y = $74
    .label x = $61
    // textcolor(tc)
    // [1547] textcolor::color#13 = display_info_led::tc#4 -- vbum1=vbuz2 
    lda.z tc
    sta textcolor.color
    // [1548] call textcolor
    // [564] phi from display_info_led to textcolor [phi:display_info_led->textcolor]
    // [564] phi textcolor::color#18 = textcolor::color#13 [phi:display_info_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [1549] phi from display_info_led to display_info_led::@1 [phi:display_info_led->display_info_led::@1]
    // display_info_led::@1
    // bgcolor(bc)
    // [1550] call bgcolor
    // [569] phi from display_info_led::@1 to bgcolor [phi:display_info_led::@1->bgcolor]
    // [569] phi bgcolor::color#14 = BLUE [phi:display_info_led::@1->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_info_led::@2
    // cputcxy(x, y, VERA_CHR_UR)
    // [1551] cputcxy::x#11 = display_info_led::x#4 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [1552] cputcxy::y#11 = display_info_led::y#4 -- vbum1=vbuz2 
    lda.z y
    sta cputcxy.y
    // [1553] call cputcxy
    // [1771] phi from display_info_led::@2 to cputcxy [phi:display_info_led::@2->cputcxy]
    // [1771] phi cputcxy::c#15 = $7c [phi:display_info_led::@2->cputcxy#0] -- vbum1=vbuc1 
    lda #$7c
    sta cputcxy.c
    // [1771] phi cputcxy::y#15 = cputcxy::y#11 [phi:display_info_led::@2->cputcxy#1] -- register_copy 
    // [1771] phi cputcxy::x#15 = cputcxy::x#11 [phi:display_info_led::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [1554] phi from display_info_led::@2 to display_info_led::@3 [phi:display_info_led::@2->display_info_led::@3]
    // display_info_led::@3
    // textcolor(WHITE)
    // [1555] call textcolor
    // [564] phi from display_info_led::@3 to textcolor [phi:display_info_led::@3->textcolor]
    // [564] phi textcolor::color#18 = WHITE [phi:display_info_led::@3->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // display_info_led::@return
    // }
    // [1556] return 
    rts
}
  // screenlayer
// --- layer management in VERA ---
// void screenlayer(char layer, __mem() char mapbase, __mem() char config)
screenlayer: {
    .label screenlayer__0 = $6f
    .label screenlayer__1 = $6e
    .label screenlayer__2 = $ce
    .label screenlayer__5 = $ca
    .label screenlayer__6 = $ca
    .label screenlayer__7 = $c9
    .label screenlayer__8 = $c9
    .label screenlayer__9 = $c7
    .label screenlayer__10 = $c7
    .label screenlayer__11 = $c7
    .label screenlayer__12 = $c8
    .label screenlayer__13 = $c8
    .label screenlayer__14 = $c8
    .label screenlayer__16 = $c9
    .label screenlayer__17 = $c4
    .label screenlayer__18 = $c7
    .label screenlayer__19 = $c8
    .label y = $be
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [1557] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [1558] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [1559] *((char *)&__conio+2) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+2
    // mapbase >> 7
    // [1560] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbuz1=vbum2_ror_7 
    lda mapbase
    rol
    rol
    and #1
    sta.z screenlayer__0
    // __conio.mapbase_bank = mapbase >> 7
    // [1561] *((char *)&__conio+5) = screenlayer::$0 -- _deref_pbuc1=vbuz1 
    sta __conio+5
    // (mapbase)<<1
    // [1562] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbuz1=vbum2_rol_1 
    lda mapbase
    asl
    sta.z screenlayer__1
    // MAKEWORD((mapbase)<<1,0)
    // [1563] screenlayer::$2 = screenlayer::$1 w= 0 -- vwuz1=vbuz2_word_vbuc1 
    lda #0
    ldy.z screenlayer__1
    sty.z screenlayer__2+1
    sta.z screenlayer__2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [1564] *((unsigned int *)&__conio+3) = screenlayer::$2 -- _deref_pwuc1=vwuz1 
    sta __conio+3
    tya
    sta __conio+3+1
    // config & VERA_LAYER_WIDTH_MASK
    // [1565] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbuz1=vbum2_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and config
    sta.z screenlayer__7
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [1566] screenlayer::$8 = screenlayer::$7 >> 4 -- vbuz1=vbuz1_ror_4 
    lda.z screenlayer__8
    lsr
    lsr
    lsr
    lsr
    sta.z screenlayer__8
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [1567] *((char *)&__conio+8) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+8
    // config & VERA_LAYER_HEIGHT_MASK
    // [1568] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbuz1=vbum2_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and config
    sta.z screenlayer__5
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [1569] screenlayer::$6 = screenlayer::$5 >> 6 -- vbuz1=vbuz1_ror_6 
    lda.z screenlayer__6
    rol
    rol
    rol
    and #3
    sta.z screenlayer__6
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [1570] *((char *)&__conio+9) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+9
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [1571] screenlayer::$16 = screenlayer::$8 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z screenlayer__16
    // [1572] *((unsigned int *)&__conio+$a) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    ldy.z screenlayer__16
    lda VERA_LAYER_SKIP,y
    sta __conio+$a
    lda VERA_LAYER_SKIP+1,y
    sta __conio+$a+1
    // vera_dc_hscale_temp == 0x80
    // [1573] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_hscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z screenlayer__9
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [1574] screenlayer::$18 = (char)screenlayer::$9
    // [1575] screenlayer::$10 = $28 << screenlayer::$18 -- vbuz1=vbuc1_rol_vbuz1 
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
    // [1576] screenlayer::$11 = screenlayer::$10 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z screenlayer__11
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [1577] *((char *)&__conio+6) = screenlayer::$11 -- _deref_pbuc1=vbuz1 
    lda.z screenlayer__11
    sta __conio+6
    // vera_dc_vscale_temp == 0x80
    // [1578] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_vscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z screenlayer__12
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [1579] screenlayer::$19 = (char)screenlayer::$12
    // [1580] screenlayer::$13 = $1e << screenlayer::$19 -- vbuz1=vbuc1_rol_vbuz1 
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
    // [1581] screenlayer::$14 = screenlayer::$13 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z screenlayer__14
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [1582] *((char *)&__conio+7) = screenlayer::$14 -- _deref_pbuc1=vbuz1 
    lda.z screenlayer__14
    sta __conio+7
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [1583] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta mapbase_offset
    lda __conio+3+1
    sta mapbase_offset+1
    // [1584] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [1584] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [1584] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [1585] if(screenlayer::y#2<=*((char *)&__conio+7)) goto screenlayer::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+7
    cmp.z y
    bcs __b2
    // screenlayer::@return
    // }
    // [1586] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [1587] screenlayer::$17 = screenlayer::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z screenlayer__17
    // [1588] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbuz1=vwum2 
    tay
    lda mapbase_offset
    sta __conio+$15,y
    lda mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [1589] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda mapbase_offset
    adc __conio+$a
    sta mapbase_offset
    lda mapbase_offset+1
    adc __conio+$a+1
    sta mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [1590] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [1584] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [1584] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [1584] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
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
    // [1591] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [1592] if(0!=((char *)&__conio+$f)[*((char *)&__conio+2)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [1593] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // [1594] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [1595] call gotoxy
    // [582] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [582] phi gotoxy::y#30 = 0 [phi:cscroll::@3->gotoxy#0] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.y
    // [582] phi gotoxy::x#30 = 0 [phi:cscroll::@3->gotoxy#1] -- vbum1=vbuc1 
    sta gotoxy.x
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [1596] return 
    rts
    // [1597] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [1598] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [1599] gotoxy::y#3 = *((char *)&__conio+7) -- vbum1=_deref_pbuc1 
    lda __conio+7
    sta gotoxy.y
    // [1600] call gotoxy
    // [582] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [582] phi gotoxy::y#30 = gotoxy::y#3 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [582] phi gotoxy::x#30 = 0 [phi:cscroll::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.x
    jsr gotoxy
    // [1601] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [1602] call clearline
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
    // [1603] ((char *)&__conio+$f)[*((char *)&__conio+2)] = scroll::onoff#0 -- pbuc1_derefidx_(_deref_pbuc2)=vbuc3 
    lda #onoff
    ldy __conio+2
    sta __conio+$f,y
    // scroll::@return
    // }
    // [1604] return 
    rts
}
  // clrscr
// clears the screen and moves the cursor to the upper left-hand corner of the screen.
clrscr: {
    .label clrscr__0 = $4d
    .label clrscr__1 = $2b
    .label clrscr__2 = $29
    // unsigned int line_text = __conio.mapbase_offset
    // [1605] clrscr::line_text#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta line_text
    lda __conio+3+1
    sta line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1606] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [1607] clrscr::$0 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clrscr__0
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1608] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [1609] clrscr::l#0 = *((char *)&__conio+9) -- vbum1=_deref_pbuc1 
    lda __conio+9
    sta l
    // [1610] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [1610] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [1610] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [1611] clrscr::$1 = byte0  clrscr::ch#0 -- vbuz1=_byte0_vwum2 
    lda ch
    sta.z clrscr__1
    // *VERA_ADDRX_L = BYTE0(ch)
    // [1612] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbuz1 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [1613] clrscr::$2 = byte1  clrscr::ch#0 -- vbuz1=_byte1_vwum2 
    lda ch+1
    sta.z clrscr__2
    // *VERA_ADDRX_M = BYTE1(ch)
    // [1614] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth+1
    // [1615] clrscr::c#0 = *((char *)&__conio+8) + 1 -- vbum1=_deref_pbuc1_plus_1 
    lda __conio+8
    inc
    sta c
    // [1616] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [1616] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [1617] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1618] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [1619] clrscr::c#1 = -- clrscr::c#2 -- vbum1=_dec_vbum1 
    dec c
    // while(c)
    // [1620] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [1621] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda line_text
    adc __conio+$a
    sta line_text
    lda line_text+1
    adc __conio+$a+1
    sta line_text+1
    // l--;
    // [1622] clrscr::l#1 = -- clrscr::l#4 -- vbum1=_dec_vbum1 
    dec l
    // while(l)
    // [1623] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbum1_then_la1 
    lda l
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [1624] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y = 0
    // [1625] *((char *)&__conio+1) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+1
    // __conio.offset = __conio.mapbase_offset
    // [1626] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+3) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+3
    sta __conio+$13
    lda __conio+3+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [1627] return 
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
// void display_frame(char x0, char y0, __zp($73) char x1, __zp($41) char y1)
display_frame: {
    .label x1 = $73
    .label y1 = $41
    // unsigned char w = x1 - x0
    // [1629] display_frame::w#0 = display_frame::x1#16 - display_frame::x#0 -- vbum1=vbuz2_minus_vbum3 
    lda.z x1
    sec
    sbc x
    sta w
    // unsigned char h = y1 - y0
    // [1630] display_frame::h#0 = display_frame::y1#16 - display_frame::y#0 -- vbum1=vbuz2_minus_vbum3 
    lda.z y1
    sec
    sbc y
    sta h
    // unsigned char mask = display_frame_maskxy(x, y)
    // [1631] display_frame_maskxy::x#0 = display_frame::x#0 -- vbuz1=vbum2 
    lda x
    sta.z display_frame_maskxy.x
    // [1632] display_frame_maskxy::y#0 = display_frame::y#0 -- vbuz1=vbum2 
    lda y
    sta.z display_frame_maskxy.y
    // [1633] call display_frame_maskxy
    // [2290] phi from display_frame to display_frame_maskxy [phi:display_frame->display_frame_maskxy]
    // [2290] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#0 [phi:display_frame->display_frame_maskxy#0] -- vbum1=vbuz2 
    sta display_frame_maskxy.cpeekcxy1_y
    // [2290] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#0 [phi:display_frame->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // unsigned char mask = display_frame_maskxy(x, y)
    // [1634] display_frame_maskxy::return#13 = display_frame_maskxy::return#12
    // display_frame::@13
    // [1635] display_frame::mask#0 = display_frame_maskxy::return#13
    // mask |= 0b0110
    // [1636] display_frame::mask#1 = display_frame::mask#0 | 6 -- vbum1=vbum1_bor_vbuc1 
    lda #6
    ora mask
    sta mask
    // unsigned char c = display_frame_char(mask)
    // [1637] display_frame_char::mask#0 = display_frame::mask#1 -- vbuz1=vbum2 
    sta.z display_frame_char.mask
    // [1638] call display_frame_char
  // Add a corner.
    // [2316] phi from display_frame::@13 to display_frame_char [phi:display_frame::@13->display_frame_char]
    // [2316] phi display_frame_char::mask#10 = display_frame_char::mask#0 [phi:display_frame::@13->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // unsigned char c = display_frame_char(mask)
    // [1639] display_frame_char::return#13 = display_frame_char::return#12
    // display_frame::@14
    // [1640] display_frame::c#0 = display_frame_char::return#13
    // cputcxy(x, y, c)
    // [1641] cputcxy::x#0 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1642] cputcxy::y#0 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [1643] cputcxy::c#0 = display_frame::c#0
    // [1644] call cputcxy
    // [1771] phi from display_frame::@14 to cputcxy [phi:display_frame::@14->cputcxy]
    // [1771] phi cputcxy::c#15 = cputcxy::c#0 [phi:display_frame::@14->cputcxy#0] -- register_copy 
    // [1771] phi cputcxy::y#15 = cputcxy::y#0 [phi:display_frame::@14->cputcxy#1] -- register_copy 
    // [1771] phi cputcxy::x#15 = cputcxy::x#0 [phi:display_frame::@14->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@15
    // if(w>=2)
    // [1645] if(display_frame::w#0<2) goto display_frame::@36 -- vbum1_lt_vbuc1_then_la1 
    lda w
    cmp #2
    bcs !__b36+
    jmp __b36
  !__b36:
    // display_frame::@2
    // x++;
    // [1646] display_frame::x#1 = ++ display_frame::x#0 -- vbum1=_inc_vbum2 
    lda x
    inc
    sta x_1
    // [1647] phi from display_frame::@2 display_frame::@21 to display_frame::@4 [phi:display_frame::@2/display_frame::@21->display_frame::@4]
    // [1647] phi display_frame::x#10 = display_frame::x#1 [phi:display_frame::@2/display_frame::@21->display_frame::@4#0] -- register_copy 
    // display_frame::@4
  __b4:
    // while(x < x1)
    // [1648] if(display_frame::x#10<display_frame::x1#16) goto display_frame::@5 -- vbum1_lt_vbuz2_then_la1 
    lda x_1
    cmp.z x1
    bcs !__b5+
    jmp __b5
  !__b5:
    // [1649] phi from display_frame::@36 display_frame::@4 to display_frame::@1 [phi:display_frame::@36/display_frame::@4->display_frame::@1]
    // [1649] phi display_frame::x#24 = display_frame::x#30 [phi:display_frame::@36/display_frame::@4->display_frame::@1#0] -- register_copy 
    // display_frame::@1
  __b1:
    // display_frame_maskxy(x, y)
    // [1650] display_frame_maskxy::x#1 = display_frame::x#24 -- vbuz1=vbum2 
    lda x_1
    sta.z display_frame_maskxy.x_1
    // [1651] display_frame_maskxy::y#1 = display_frame::y#0 -- vbuz1=vbum2 
    lda y
    sta.z display_frame_maskxy.y_1
    // [1652] call display_frame_maskxy
    // [2290] phi from display_frame::@1 to display_frame_maskxy [phi:display_frame::@1->display_frame_maskxy]
    // [2290] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#1 [phi:display_frame::@1->display_frame_maskxy#0] -- vbum1=vbuz2 
    sta display_frame_maskxy.cpeekcxy1_y
    // [2290] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#1 [phi:display_frame::@1->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x_1
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1653] display_frame_maskxy::return#14 = display_frame_maskxy::return#12
    // display_frame::@16
    // mask = display_frame_maskxy(x, y)
    // [1654] display_frame::mask#2 = display_frame_maskxy::return#14
    // mask |= 0b0011
    // [1655] display_frame::mask#3 = display_frame::mask#2 | 3 -- vbum1=vbum1_bor_vbuc1 
    lda #3
    ora mask
    sta mask
    // display_frame_char(mask)
    // [1656] display_frame_char::mask#1 = display_frame::mask#3 -- vbuz1=vbum2 
    sta.z display_frame_char.mask
    // [1657] call display_frame_char
    // [2316] phi from display_frame::@16 to display_frame_char [phi:display_frame::@16->display_frame_char]
    // [2316] phi display_frame_char::mask#10 = display_frame_char::mask#1 [phi:display_frame::@16->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1658] display_frame_char::return#14 = display_frame_char::return#12
    // display_frame::@17
    // c = display_frame_char(mask)
    // [1659] display_frame::c#1 = display_frame_char::return#14
    // cputcxy(x, y, c)
    // [1660] cputcxy::x#1 = display_frame::x#24 -- vbum1=vbum2 
    lda x_1
    sta cputcxy.x
    // [1661] cputcxy::y#1 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [1662] cputcxy::c#1 = display_frame::c#1
    // [1663] call cputcxy
    // [1771] phi from display_frame::@17 to cputcxy [phi:display_frame::@17->cputcxy]
    // [1771] phi cputcxy::c#15 = cputcxy::c#1 [phi:display_frame::@17->cputcxy#0] -- register_copy 
    // [1771] phi cputcxy::y#15 = cputcxy::y#1 [phi:display_frame::@17->cputcxy#1] -- register_copy 
    // [1771] phi cputcxy::x#15 = cputcxy::x#1 [phi:display_frame::@17->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@18
    // if(h>=2)
    // [1664] if(display_frame::h#0<2) goto display_frame::@return -- vbum1_lt_vbuc1_then_la1 
    lda h
    cmp #2
    bcs !__breturn+
    jmp __breturn
  !__breturn:
    // display_frame::@3
    // y++;
    // [1665] display_frame::y#1 = ++ display_frame::y#0 -- vbum1=_inc_vbum2 
    lda y
    inc
    sta y_1
    // [1666] phi from display_frame::@27 display_frame::@3 to display_frame::@6 [phi:display_frame::@27/display_frame::@3->display_frame::@6]
    // [1666] phi display_frame::y#10 = display_frame::y#2 [phi:display_frame::@27/display_frame::@3->display_frame::@6#0] -- register_copy 
    // display_frame::@6
  __b6:
    // while(y < y1)
    // [1667] if(display_frame::y#10<display_frame::y1#16) goto display_frame::@7 -- vbum1_lt_vbuz2_then_la1 
    lda y_1
    cmp.z y1
    bcs !__b7+
    jmp __b7
  !__b7:
    // display_frame::@8
    // display_frame_maskxy(x, y)
    // [1668] display_frame_maskxy::x#5 = display_frame::x#0 -- vbuz1=vbum2 
    lda x
    sta.z display_frame_maskxy.x_5
    // [1669] display_frame_maskxy::y#5 = display_frame::y#10 -- vbuz1=vbum2 
    lda y_1
    sta.z display_frame_maskxy.y_5
    // [1670] call display_frame_maskxy
    // [2290] phi from display_frame::@8 to display_frame_maskxy [phi:display_frame::@8->display_frame_maskxy]
    // [2290] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#5 [phi:display_frame::@8->display_frame_maskxy#0] -- vbum1=vbuz2 
    sta display_frame_maskxy.cpeekcxy1_y
    // [2290] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#5 [phi:display_frame::@8->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x_5
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1671] display_frame_maskxy::return#18 = display_frame_maskxy::return#12
    // display_frame::@28
    // mask = display_frame_maskxy(x, y)
    // [1672] display_frame::mask#10 = display_frame_maskxy::return#18
    // mask |= 0b1100
    // [1673] display_frame::mask#11 = display_frame::mask#10 | $c -- vbum1=vbum1_bor_vbuc1 
    lda #$c
    ora mask
    sta mask
    // display_frame_char(mask)
    // [1674] display_frame_char::mask#5 = display_frame::mask#11 -- vbuz1=vbum2 
    sta.z display_frame_char.mask
    // [1675] call display_frame_char
    // [2316] phi from display_frame::@28 to display_frame_char [phi:display_frame::@28->display_frame_char]
    // [2316] phi display_frame_char::mask#10 = display_frame_char::mask#5 [phi:display_frame::@28->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1676] display_frame_char::return#18 = display_frame_char::return#12
    // display_frame::@29
    // c = display_frame_char(mask)
    // [1677] display_frame::c#5 = display_frame_char::return#18
    // cputcxy(x, y, c)
    // [1678] cputcxy::x#5 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1679] cputcxy::y#5 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [1680] cputcxy::c#5 = display_frame::c#5
    // [1681] call cputcxy
    // [1771] phi from display_frame::@29 to cputcxy [phi:display_frame::@29->cputcxy]
    // [1771] phi cputcxy::c#15 = cputcxy::c#5 [phi:display_frame::@29->cputcxy#0] -- register_copy 
    // [1771] phi cputcxy::y#15 = cputcxy::y#5 [phi:display_frame::@29->cputcxy#1] -- register_copy 
    // [1771] phi cputcxy::x#15 = cputcxy::x#5 [phi:display_frame::@29->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@30
    // if(w>=2)
    // [1682] if(display_frame::w#0<2) goto display_frame::@10 -- vbum1_lt_vbuc1_then_la1 
    lda w
    cmp #2
    bcc __b10
    // display_frame::@9
    // x++;
    // [1683] display_frame::x#4 = ++ display_frame::x#0 -- vbum1=_inc_vbum1 
    inc x
    // [1684] phi from display_frame::@35 display_frame::@9 to display_frame::@11 [phi:display_frame::@35/display_frame::@9->display_frame::@11]
    // [1684] phi display_frame::x#18 = display_frame::x#5 [phi:display_frame::@35/display_frame::@9->display_frame::@11#0] -- register_copy 
    // display_frame::@11
  __b11:
    // while(x < x1)
    // [1685] if(display_frame::x#18<display_frame::x1#16) goto display_frame::@12 -- vbum1_lt_vbuz2_then_la1 
    lda x
    cmp.z x1
    bcc __b12
    // [1686] phi from display_frame::@11 display_frame::@30 to display_frame::@10 [phi:display_frame::@11/display_frame::@30->display_frame::@10]
    // [1686] phi display_frame::x#15 = display_frame::x#18 [phi:display_frame::@11/display_frame::@30->display_frame::@10#0] -- register_copy 
    // display_frame::@10
  __b10:
    // display_frame_maskxy(x, y)
    // [1687] display_frame_maskxy::x#6 = display_frame::x#15 -- vbuz1=vbum2 
    lda x
    sta.z display_frame_maskxy.x_6
    // [1688] display_frame_maskxy::y#6 = display_frame::y#10 -- vbuz1=vbum2 
    lda y_1
    sta.z display_frame_maskxy.y_6
    // [1689] call display_frame_maskxy
    // [2290] phi from display_frame::@10 to display_frame_maskxy [phi:display_frame::@10->display_frame_maskxy]
    // [2290] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#6 [phi:display_frame::@10->display_frame_maskxy#0] -- vbum1=vbuz2 
    sta display_frame_maskxy.cpeekcxy1_y
    // [2290] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#6 [phi:display_frame::@10->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x_6
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1690] display_frame_maskxy::return#19 = display_frame_maskxy::return#12
    // display_frame::@31
    // mask = display_frame_maskxy(x, y)
    // [1691] display_frame::mask#12 = display_frame_maskxy::return#19
    // mask |= 0b1001
    // [1692] display_frame::mask#13 = display_frame::mask#12 | 9 -- vbum1=vbum1_bor_vbuc1 
    lda #9
    ora mask
    sta mask
    // display_frame_char(mask)
    // [1693] display_frame_char::mask#6 = display_frame::mask#13 -- vbuz1=vbum2 
    sta.z display_frame_char.mask
    // [1694] call display_frame_char
    // [2316] phi from display_frame::@31 to display_frame_char [phi:display_frame::@31->display_frame_char]
    // [2316] phi display_frame_char::mask#10 = display_frame_char::mask#6 [phi:display_frame::@31->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1695] display_frame_char::return#19 = display_frame_char::return#12
    // display_frame::@32
    // c = display_frame_char(mask)
    // [1696] display_frame::c#6 = display_frame_char::return#19
    // cputcxy(x, y, c)
    // [1697] cputcxy::x#6 = display_frame::x#15 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1698] cputcxy::y#6 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [1699] cputcxy::c#6 = display_frame::c#6
    // [1700] call cputcxy
    // [1771] phi from display_frame::@32 to cputcxy [phi:display_frame::@32->cputcxy]
    // [1771] phi cputcxy::c#15 = cputcxy::c#6 [phi:display_frame::@32->cputcxy#0] -- register_copy 
    // [1771] phi cputcxy::y#15 = cputcxy::y#6 [phi:display_frame::@32->cputcxy#1] -- register_copy 
    // [1771] phi cputcxy::x#15 = cputcxy::x#6 [phi:display_frame::@32->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@return
  __breturn:
    // }
    // [1701] return 
    rts
    // display_frame::@12
  __b12:
    // display_frame_maskxy(x, y)
    // [1702] display_frame_maskxy::x#7 = display_frame::x#18 -- vbuz1=vbum2 
    lda x
    sta.z display_frame_maskxy.x_7
    // [1703] display_frame_maskxy::y#7 = display_frame::y#10 -- vbuz1=vbum2 
    lda y_1
    sta.z display_frame_maskxy.y_7
    // [1704] call display_frame_maskxy
    // [2290] phi from display_frame::@12 to display_frame_maskxy [phi:display_frame::@12->display_frame_maskxy]
    // [2290] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#7 [phi:display_frame::@12->display_frame_maskxy#0] -- vbum1=vbuz2 
    sta display_frame_maskxy.cpeekcxy1_y
    // [2290] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#7 [phi:display_frame::@12->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x_7
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1705] display_frame_maskxy::return#20 = display_frame_maskxy::return#12
    // display_frame::@33
    // mask = display_frame_maskxy(x, y)
    // [1706] display_frame::mask#14 = display_frame_maskxy::return#20
    // mask |= 0b0101
    // [1707] display_frame::mask#15 = display_frame::mask#14 | 5 -- vbum1=vbum1_bor_vbuc1 
    lda #5
    ora mask
    sta mask
    // display_frame_char(mask)
    // [1708] display_frame_char::mask#7 = display_frame::mask#15 -- vbuz1=vbum2 
    sta.z display_frame_char.mask
    // [1709] call display_frame_char
    // [2316] phi from display_frame::@33 to display_frame_char [phi:display_frame::@33->display_frame_char]
    // [2316] phi display_frame_char::mask#10 = display_frame_char::mask#7 [phi:display_frame::@33->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1710] display_frame_char::return#20 = display_frame_char::return#12
    // display_frame::@34
    // c = display_frame_char(mask)
    // [1711] display_frame::c#7 = display_frame_char::return#20
    // cputcxy(x, y, c)
    // [1712] cputcxy::x#7 = display_frame::x#18 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1713] cputcxy::y#7 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [1714] cputcxy::c#7 = display_frame::c#7
    // [1715] call cputcxy
    // [1771] phi from display_frame::@34 to cputcxy [phi:display_frame::@34->cputcxy]
    // [1771] phi cputcxy::c#15 = cputcxy::c#7 [phi:display_frame::@34->cputcxy#0] -- register_copy 
    // [1771] phi cputcxy::y#15 = cputcxy::y#7 [phi:display_frame::@34->cputcxy#1] -- register_copy 
    // [1771] phi cputcxy::x#15 = cputcxy::x#7 [phi:display_frame::@34->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@35
    // x++;
    // [1716] display_frame::x#5 = ++ display_frame::x#18 -- vbum1=_inc_vbum1 
    inc x
    jmp __b11
    // display_frame::@7
  __b7:
    // display_frame_maskxy(x0, y)
    // [1717] display_frame_maskxy::x#3 = display_frame::x#0 -- vbuz1=vbum2 
    lda x
    sta.z display_frame_maskxy.x_3
    // [1718] display_frame_maskxy::y#3 = display_frame::y#10 -- vbuz1=vbum2 
    lda y_1
    sta.z display_frame_maskxy.y_3
    // [1719] call display_frame_maskxy
    // [2290] phi from display_frame::@7 to display_frame_maskxy [phi:display_frame::@7->display_frame_maskxy]
    // [2290] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#3 [phi:display_frame::@7->display_frame_maskxy#0] -- vbum1=vbuz2 
    sta display_frame_maskxy.cpeekcxy1_y
    // [2290] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#3 [phi:display_frame::@7->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x_3
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x0, y)
    // [1720] display_frame_maskxy::return#16 = display_frame_maskxy::return#12
    // display_frame::@22
    // mask = display_frame_maskxy(x0, y)
    // [1721] display_frame::mask#6 = display_frame_maskxy::return#16
    // mask |= 0b1010
    // [1722] display_frame::mask#7 = display_frame::mask#6 | $a -- vbum1=vbum1_bor_vbuc1 
    lda #$a
    ora mask
    sta mask
    // display_frame_char(mask)
    // [1723] display_frame_char::mask#3 = display_frame::mask#7 -- vbuz1=vbum2 
    sta.z display_frame_char.mask
    // [1724] call display_frame_char
    // [2316] phi from display_frame::@22 to display_frame_char [phi:display_frame::@22->display_frame_char]
    // [2316] phi display_frame_char::mask#10 = display_frame_char::mask#3 [phi:display_frame::@22->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1725] display_frame_char::return#16 = display_frame_char::return#12
    // display_frame::@23
    // c = display_frame_char(mask)
    // [1726] display_frame::c#3 = display_frame_char::return#16
    // cputcxy(x0, y, c)
    // [1727] cputcxy::x#3 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1728] cputcxy::y#3 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [1729] cputcxy::c#3 = display_frame::c#3
    // [1730] call cputcxy
    // [1771] phi from display_frame::@23 to cputcxy [phi:display_frame::@23->cputcxy]
    // [1771] phi cputcxy::c#15 = cputcxy::c#3 [phi:display_frame::@23->cputcxy#0] -- register_copy 
    // [1771] phi cputcxy::y#15 = cputcxy::y#3 [phi:display_frame::@23->cputcxy#1] -- register_copy 
    // [1771] phi cputcxy::x#15 = cputcxy::x#3 [phi:display_frame::@23->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@24
    // display_frame_maskxy(x1, y)
    // [1731] display_frame_maskxy::x#4 = display_frame::x1#16
    // [1732] display_frame_maskxy::y#4 = display_frame::y#10 -- vbuz1=vbum2 
    lda y_1
    sta.z display_frame_maskxy.y_4
    // [1733] call display_frame_maskxy
    // [2290] phi from display_frame::@24 to display_frame_maskxy [phi:display_frame::@24->display_frame_maskxy]
    // [2290] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#4 [phi:display_frame::@24->display_frame_maskxy#0] -- vbum1=vbuz2 
    sta display_frame_maskxy.cpeekcxy1_y
    // [2290] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#4 [phi:display_frame::@24->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x_4
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x1, y)
    // [1734] display_frame_maskxy::return#17 = display_frame_maskxy::return#12
    // display_frame::@25
    // mask = display_frame_maskxy(x1, y)
    // [1735] display_frame::mask#8 = display_frame_maskxy::return#17
    // mask |= 0b1010
    // [1736] display_frame::mask#9 = display_frame::mask#8 | $a -- vbum1=vbum1_bor_vbuc1 
    lda #$a
    ora mask
    sta mask
    // display_frame_char(mask)
    // [1737] display_frame_char::mask#4 = display_frame::mask#9 -- vbuz1=vbum2 
    sta.z display_frame_char.mask
    // [1738] call display_frame_char
    // [2316] phi from display_frame::@25 to display_frame_char [phi:display_frame::@25->display_frame_char]
    // [2316] phi display_frame_char::mask#10 = display_frame_char::mask#4 [phi:display_frame::@25->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1739] display_frame_char::return#17 = display_frame_char::return#12
    // display_frame::@26
    // c = display_frame_char(mask)
    // [1740] display_frame::c#4 = display_frame_char::return#17
    // cputcxy(x1, y, c)
    // [1741] cputcxy::x#4 = display_frame::x1#16 -- vbum1=vbuz2 
    lda.z x1
    sta cputcxy.x
    // [1742] cputcxy::y#4 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [1743] cputcxy::c#4 = display_frame::c#4
    // [1744] call cputcxy
    // [1771] phi from display_frame::@26 to cputcxy [phi:display_frame::@26->cputcxy]
    // [1771] phi cputcxy::c#15 = cputcxy::c#4 [phi:display_frame::@26->cputcxy#0] -- register_copy 
    // [1771] phi cputcxy::y#15 = cputcxy::y#4 [phi:display_frame::@26->cputcxy#1] -- register_copy 
    // [1771] phi cputcxy::x#15 = cputcxy::x#4 [phi:display_frame::@26->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@27
    // y++;
    // [1745] display_frame::y#2 = ++ display_frame::y#10 -- vbum1=_inc_vbum1 
    inc y_1
    jmp __b6
    // display_frame::@5
  __b5:
    // display_frame_maskxy(x, y)
    // [1746] display_frame_maskxy::x#2 = display_frame::x#10 -- vbuz1=vbum2 
    lda x_1
    sta.z display_frame_maskxy.x_2
    // [1747] display_frame_maskxy::y#2 = display_frame::y#0 -- vbuz1=vbum2 
    lda y
    sta.z display_frame_maskxy.y_2
    // [1748] call display_frame_maskxy
    // [2290] phi from display_frame::@5 to display_frame_maskxy [phi:display_frame::@5->display_frame_maskxy]
    // [2290] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#2 [phi:display_frame::@5->display_frame_maskxy#0] -- vbum1=vbuz2 
    sta display_frame_maskxy.cpeekcxy1_y
    // [2290] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#2 [phi:display_frame::@5->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x_2
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1749] display_frame_maskxy::return#15 = display_frame_maskxy::return#12
    // display_frame::@19
    // mask = display_frame_maskxy(x, y)
    // [1750] display_frame::mask#4 = display_frame_maskxy::return#15
    // mask |= 0b0101
    // [1751] display_frame::mask#5 = display_frame::mask#4 | 5 -- vbum1=vbum1_bor_vbuc1 
    lda #5
    ora mask
    sta mask
    // display_frame_char(mask)
    // [1752] display_frame_char::mask#2 = display_frame::mask#5 -- vbuz1=vbum2 
    sta.z display_frame_char.mask
    // [1753] call display_frame_char
    // [2316] phi from display_frame::@19 to display_frame_char [phi:display_frame::@19->display_frame_char]
    // [2316] phi display_frame_char::mask#10 = display_frame_char::mask#2 [phi:display_frame::@19->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1754] display_frame_char::return#15 = display_frame_char::return#12
    // display_frame::@20
    // c = display_frame_char(mask)
    // [1755] display_frame::c#2 = display_frame_char::return#15
    // cputcxy(x, y, c)
    // [1756] cputcxy::x#2 = display_frame::x#10 -- vbum1=vbum2 
    lda x_1
    sta cputcxy.x
    // [1757] cputcxy::y#2 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [1758] cputcxy::c#2 = display_frame::c#2
    // [1759] call cputcxy
    // [1771] phi from display_frame::@20 to cputcxy [phi:display_frame::@20->cputcxy]
    // [1771] phi cputcxy::c#15 = cputcxy::c#2 [phi:display_frame::@20->cputcxy#0] -- register_copy 
    // [1771] phi cputcxy::y#15 = cputcxy::y#2 [phi:display_frame::@20->cputcxy#1] -- register_copy 
    // [1771] phi cputcxy::x#15 = cputcxy::x#2 [phi:display_frame::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@21
    // x++;
    // [1760] display_frame::x#2 = ++ display_frame::x#10 -- vbum1=_inc_vbum1 
    inc x_1
    jmp __b4
    // display_frame::@36
  __b36:
    // [1761] display_frame::x#30 = display_frame::x#0 -- vbum1=vbum2 
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
// void cputs(__zp($42) const char *s)
cputs: {
    .label s = $42
    // [1763] phi from cputs cputs::@2 to cputs::@1 [phi:cputs/cputs::@2->cputs::@1]
    // [1763] phi cputs::s#2 = cputs::s#1 [phi:cputs/cputs::@2->cputs::@1#0] -- register_copy 
    // cputs::@1
  __b1:
    // while(c=*s++)
    // [1764] cputs::c#1 = *cputs::s#2 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta c
    // [1765] cputs::s#0 = ++ cputs::s#2 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [1766] if(0!=cputs::c#1) goto cputs::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // cputs::@return
    // }
    // [1767] return 
    rts
    // cputs::@2
  __b2:
    // cputc(c)
    // [1768] stackpush(char) = cputs::c#1 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [1769] callexecute cputc  -- call_vprc1 
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
    // [1772] gotoxy::x#0 = cputcxy::x#15 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1773] gotoxy::y#0 = cputcxy::y#15 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1774] call gotoxy
    // [582] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [582] phi gotoxy::y#30 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [582] phi gotoxy::x#30 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [1775] stackpush(char) = cputcxy::c#15 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [1776] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [1778] return 
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
    // [1779] wherex::return#0 = *((char *)&__conio) -- vbum1=_deref_pbuc1 
    lda __conio
    sta return
    // wherex::@return
    // }
    // [1780] return 
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
    // [1781] wherey::return#0 = *((char *)&__conio+1) -- vbum1=_deref_pbuc1 
    lda __conio+1
    sta return
    // wherey::@return
    // }
    // [1782] return 
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
    // [1783] cx16_k_i2c_read_byte::result = 0 -- vwum1=vwuc1 
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
    // [1785] cx16_k_i2c_read_byte::return#0 = cx16_k_i2c_read_byte::result -- vwum1=vwum2 
    sta return
    lda result+1
    sta return+1
    // cx16_k_i2c_read_byte::@return
    // }
    // [1786] cx16_k_i2c_read_byte::return#1 = cx16_k_i2c_read_byte::return#0
    // [1787] return 
    rts
  .segment Data
    device: .byte 0
    offset: .byte 0
    result: .word 0
    .label return = smc_detect.return
}
.segment Code
  // display_smc_led
/**
 * @brief Print SMC led above the SMC chip.
 * 
 * @param c Led color
 */
// void display_smc_led(__zp($72) char c)
display_smc_led: {
    .label c = $72
    // display_chip_led(CHIP_SMC_X+1, CHIP_SMC_Y, CHIP_SMC_W, c, BLUE)
    // [1789] display_chip_led::tc#0 = display_smc_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_chip_led.tc
    // [1790] call display_chip_led
    // [2331] phi from display_smc_led to display_chip_led [phi:display_smc_led->display_chip_led]
    // [2331] phi display_chip_led::w#7 = 5 [phi:display_smc_led->display_chip_led#0] -- vbuz1=vbuc1 
    lda #5
    sta.z display_chip_led.w
    // [2331] phi display_chip_led::x#7 = 1+1 [phi:display_smc_led->display_chip_led#1] -- vbuz1=vbuc1 
    lda #1+1
    sta.z display_chip_led.x
    // [2331] phi display_chip_led::tc#3 = display_chip_led::tc#0 [phi:display_smc_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_smc_led::@1
    // display_info_led(INFO_X-2, INFO_Y, c, BLUE)
    // [1791] display_info_led::tc#0 = display_smc_led::c#2
    // [1792] call display_info_led
    // [1546] phi from display_smc_led::@1 to display_info_led [phi:display_smc_led::@1->display_info_led]
    // [1546] phi display_info_led::y#4 = $11 [phi:display_smc_led::@1->display_info_led#0] -- vbuz1=vbuc1 
    lda #$11
    sta.z display_info_led.y
    // [1546] phi display_info_led::x#4 = 4-2 [phi:display_smc_led::@1->display_info_led#1] -- vbuz1=vbuc1 
    lda #4-2
    sta.z display_info_led.x
    // [1546] phi display_info_led::tc#4 = display_info_led::tc#0 [phi:display_smc_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_smc_led::@return
    // }
    // [1793] return 
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
// void display_print_chip(__zp($b5) char x, char y, __zp($cd) char w, __zp($38) char *text)
display_print_chip: {
    .label y = 3+2+1+1+1+1+1+1+1+1
    .label text = $38
    .label text_1 = $70
    .label x = $b5
    .label text_2 = $b6
    .label text_3 = $b8
    .label text_4 = $ab
    .label text_5 = $c0
    .label text_6 = $c2
    .label w = $cd
    // display_chip_line(x, y++, w, *text++)
    // [1795] display_chip_line::x#0 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1796] display_chip_line::w#0 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1797] display_chip_line::c#0 = *display_print_chip::text#11 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_2),y
    sta.z display_chip_line.c
    // [1798] call display_chip_line
    // [2349] phi from display_print_chip to display_chip_line [phi:display_print_chip->display_chip_line]
    // [2349] phi display_chip_line::c#15 = display_chip_line::c#0 [phi:display_print_chip->display_chip_line#0] -- register_copy 
    // [2349] phi display_chip_line::w#10 = display_chip_line::w#0 [phi:display_print_chip->display_chip_line#1] -- register_copy 
    // [2349] phi display_chip_line::y#16 = 3+2 [phi:display_print_chip->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2
    sta.z display_chip_line.y
    // [2349] phi display_chip_line::x#16 = display_chip_line::x#0 [phi:display_print_chip->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@1
    // display_chip_line(x, y++, w, *text++);
    // [1799] display_print_chip::text#0 = ++ display_print_chip::text#11 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_2
    adc #1
    sta.z text
    lda.z text_2+1
    adc #0
    sta.z text+1
    // display_chip_line(x, y++, w, *text++)
    // [1800] display_chip_line::x#1 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1801] display_chip_line::w#1 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1802] display_chip_line::c#1 = *display_print_chip::text#0 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text),y
    sta.z display_chip_line.c
    // [1803] call display_chip_line
    // [2349] phi from display_print_chip::@1 to display_chip_line [phi:display_print_chip::@1->display_chip_line]
    // [2349] phi display_chip_line::c#15 = display_chip_line::c#1 [phi:display_print_chip::@1->display_chip_line#0] -- register_copy 
    // [2349] phi display_chip_line::w#10 = display_chip_line::w#1 [phi:display_print_chip::@1->display_chip_line#1] -- register_copy 
    // [2349] phi display_chip_line::y#16 = ++3+2 [phi:display_print_chip::@1->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1
    sta.z display_chip_line.y
    // [2349] phi display_chip_line::x#16 = display_chip_line::x#1 [phi:display_print_chip::@1->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@2
    // display_chip_line(x, y++, w, *text++);
    // [1804] display_print_chip::text#1 = ++ display_print_chip::text#0 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text
    adc #1
    sta.z text_1
    lda.z text+1
    adc #0
    sta.z text_1+1
    // display_chip_line(x, y++, w, *text++)
    // [1805] display_chip_line::x#2 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1806] display_chip_line::w#2 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1807] display_chip_line::c#2 = *display_print_chip::text#1 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_1),y
    sta.z display_chip_line.c
    // [1808] call display_chip_line
    // [2349] phi from display_print_chip::@2 to display_chip_line [phi:display_print_chip::@2->display_chip_line]
    // [2349] phi display_chip_line::c#15 = display_chip_line::c#2 [phi:display_print_chip::@2->display_chip_line#0] -- register_copy 
    // [2349] phi display_chip_line::w#10 = display_chip_line::w#2 [phi:display_print_chip::@2->display_chip_line#1] -- register_copy 
    // [2349] phi display_chip_line::y#16 = ++++3+2 [phi:display_print_chip::@2->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1
    sta.z display_chip_line.y
    // [2349] phi display_chip_line::x#16 = display_chip_line::x#2 [phi:display_print_chip::@2->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@3
    // display_chip_line(x, y++, w, *text++);
    // [1809] display_print_chip::text#15 = ++ display_print_chip::text#1 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_1
    adc #1
    sta.z text_3
    lda.z text_1+1
    adc #0
    sta.z text_3+1
    // display_chip_line(x, y++, w, *text++)
    // [1810] display_chip_line::x#3 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1811] display_chip_line::w#3 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1812] display_chip_line::c#3 = *display_print_chip::text#15 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_3),y
    sta.z display_chip_line.c
    // [1813] call display_chip_line
    // [2349] phi from display_print_chip::@3 to display_chip_line [phi:display_print_chip::@3->display_chip_line]
    // [2349] phi display_chip_line::c#15 = display_chip_line::c#3 [phi:display_print_chip::@3->display_chip_line#0] -- register_copy 
    // [2349] phi display_chip_line::w#10 = display_chip_line::w#3 [phi:display_print_chip::@3->display_chip_line#1] -- register_copy 
    // [2349] phi display_chip_line::y#16 = ++++++3+2 [phi:display_print_chip::@3->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1
    sta.z display_chip_line.y
    // [2349] phi display_chip_line::x#16 = display_chip_line::x#3 [phi:display_print_chip::@3->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@4
    // display_chip_line(x, y++, w, *text++);
    // [1814] display_print_chip::text#16 = ++ display_print_chip::text#15 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_3
    adc #1
    sta.z text_4
    lda.z text_3+1
    adc #0
    sta.z text_4+1
    // display_chip_line(x, y++, w, *text++)
    // [1815] display_chip_line::x#4 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1816] display_chip_line::w#4 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1817] display_chip_line::c#4 = *display_print_chip::text#16 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_4),y
    sta.z display_chip_line.c
    // [1818] call display_chip_line
    // [2349] phi from display_print_chip::@4 to display_chip_line [phi:display_print_chip::@4->display_chip_line]
    // [2349] phi display_chip_line::c#15 = display_chip_line::c#4 [phi:display_print_chip::@4->display_chip_line#0] -- register_copy 
    // [2349] phi display_chip_line::w#10 = display_chip_line::w#4 [phi:display_print_chip::@4->display_chip_line#1] -- register_copy 
    // [2349] phi display_chip_line::y#16 = ++++++++3+2 [phi:display_print_chip::@4->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1
    sta.z display_chip_line.y
    // [2349] phi display_chip_line::x#16 = display_chip_line::x#4 [phi:display_print_chip::@4->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@5
    // display_chip_line(x, y++, w, *text++);
    // [1819] display_print_chip::text#17 = ++ display_print_chip::text#16 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_4
    adc #1
    sta.z text_5
    lda.z text_4+1
    adc #0
    sta.z text_5+1
    // display_chip_line(x, y++, w, *text++)
    // [1820] display_chip_line::x#5 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1821] display_chip_line::w#5 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1822] display_chip_line::c#5 = *display_print_chip::text#17 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_5),y
    sta.z display_chip_line.c
    // [1823] call display_chip_line
    // [2349] phi from display_print_chip::@5 to display_chip_line [phi:display_print_chip::@5->display_chip_line]
    // [2349] phi display_chip_line::c#15 = display_chip_line::c#5 [phi:display_print_chip::@5->display_chip_line#0] -- register_copy 
    // [2349] phi display_chip_line::w#10 = display_chip_line::w#5 [phi:display_print_chip::@5->display_chip_line#1] -- register_copy 
    // [2349] phi display_chip_line::y#16 = ++++++++++3+2 [phi:display_print_chip::@5->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1+1
    sta.z display_chip_line.y
    // [2349] phi display_chip_line::x#16 = display_chip_line::x#5 [phi:display_print_chip::@5->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@6
    // display_chip_line(x, y++, w, *text++);
    // [1824] display_print_chip::text#18 = ++ display_print_chip::text#17 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_5
    adc #1
    sta.z text_6
    lda.z text_5+1
    adc #0
    sta.z text_6+1
    // display_chip_line(x, y++, w, *text++)
    // [1825] display_chip_line::x#6 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1826] display_chip_line::w#6 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1827] display_chip_line::c#6 = *display_print_chip::text#18 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta.z display_chip_line.c
    // [1828] call display_chip_line
    // [2349] phi from display_print_chip::@6 to display_chip_line [phi:display_print_chip::@6->display_chip_line]
    // [2349] phi display_chip_line::c#15 = display_chip_line::c#6 [phi:display_print_chip::@6->display_chip_line#0] -- register_copy 
    // [2349] phi display_chip_line::w#10 = display_chip_line::w#6 [phi:display_print_chip::@6->display_chip_line#1] -- register_copy 
    // [2349] phi display_chip_line::y#16 = ++++++++++++3+2 [phi:display_print_chip::@6->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1+1+1
    sta.z display_chip_line.y
    // [2349] phi display_chip_line::x#16 = display_chip_line::x#6 [phi:display_print_chip::@6->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@7
    // display_chip_line(x, y++, w, *text++);
    // [1829] display_print_chip::text#19 = ++ display_print_chip::text#18 -- pbuz1=_inc_pbuz1 
    inc.z text_6
    bne !+
    inc.z text_6+1
  !:
    // display_chip_line(x, y++, w, *text++)
    // [1830] display_chip_line::x#7 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1831] display_chip_line::w#7 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1832] display_chip_line::c#7 = *display_print_chip::text#19 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta.z display_chip_line.c
    // [1833] call display_chip_line
    // [2349] phi from display_print_chip::@7 to display_chip_line [phi:display_print_chip::@7->display_chip_line]
    // [2349] phi display_chip_line::c#15 = display_chip_line::c#7 [phi:display_print_chip::@7->display_chip_line#0] -- register_copy 
    // [2349] phi display_chip_line::w#10 = display_chip_line::w#7 [phi:display_print_chip::@7->display_chip_line#1] -- register_copy 
    // [2349] phi display_chip_line::y#16 = ++++++++++++++3+2 [phi:display_print_chip::@7->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1+1+1+1
    sta.z display_chip_line.y
    // [2349] phi display_chip_line::x#16 = display_chip_line::x#7 [phi:display_print_chip::@7->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@8
    // display_chip_end(x, y++, w)
    // [1834] display_chip_end::x#0 = display_print_chip::x#10
    // [1835] display_chip_end::w#0 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_end.w
    // [1836] call display_chip_end
    jsr display_chip_end
    // display_print_chip::@return
    // }
    // [1837] return 
    rts
}
  // utoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void utoa(__mem() unsigned int value, __zp($48) char *buffer, __mem() char radix)
utoa: {
    .label utoa__4 = $29
    .label utoa__10 = $3a
    .label utoa__11 = $2b
    .label buffer = $48
    .label digit_values = $4b
    // if(radix==DECIMAL)
    // [1838] if(utoa::radix#0==DECIMAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // utoa::@2
    // if(radix==HEXADECIMAL)
    // [1839] if(utoa::radix#0==HEXADECIMAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // utoa::@3
    // if(radix==OCTAL)
    // [1840] if(utoa::radix#0==OCTAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // utoa::@4
    // if(radix==BINARY)
    // [1841] if(utoa::radix#0==BINARY) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // utoa::@5
    // *buffer++ = 'e'
    // [1842] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1843] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1844] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1845] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // utoa::@return
    // }
    // [1846] return 
    rts
    // [1847] phi from utoa to utoa::@1 [phi:utoa->utoa::@1]
  __b2:
    // [1847] phi utoa::digit_values#8 = RADIX_DECIMAL_VALUES [phi:utoa->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_DECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES
    sta.z digit_values+1
    // [1847] phi utoa::max_digits#7 = 5 [phi:utoa->utoa::@1#1] -- vbum1=vbuc1 
    lda #5
    sta max_digits
    jmp __b1
    // [1847] phi from utoa::@2 to utoa::@1 [phi:utoa::@2->utoa::@1]
  __b3:
    // [1847] phi utoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES [phi:utoa::@2->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_HEXADECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES
    sta.z digit_values+1
    // [1847] phi utoa::max_digits#7 = 4 [phi:utoa::@2->utoa::@1#1] -- vbum1=vbuc1 
    lda #4
    sta max_digits
    jmp __b1
    // [1847] phi from utoa::@3 to utoa::@1 [phi:utoa::@3->utoa::@1]
  __b4:
    // [1847] phi utoa::digit_values#8 = RADIX_OCTAL_VALUES [phi:utoa::@3->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_OCTAL_VALUES
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES
    sta.z digit_values+1
    // [1847] phi utoa::max_digits#7 = 6 [phi:utoa::@3->utoa::@1#1] -- vbum1=vbuc1 
    lda #6
    sta max_digits
    jmp __b1
    // [1847] phi from utoa::@4 to utoa::@1 [phi:utoa::@4->utoa::@1]
  __b5:
    // [1847] phi utoa::digit_values#8 = RADIX_BINARY_VALUES [phi:utoa::@4->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_BINARY_VALUES
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES
    sta.z digit_values+1
    // [1847] phi utoa::max_digits#7 = $10 [phi:utoa::@4->utoa::@1#1] -- vbum1=vbuc1 
    lda #$10
    sta max_digits
    // utoa::@1
  __b1:
    // [1848] phi from utoa::@1 to utoa::@6 [phi:utoa::@1->utoa::@6]
    // [1848] phi utoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:utoa::@1->utoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1848] phi utoa::started#2 = 0 [phi:utoa::@1->utoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [1848] phi utoa::value#2 = utoa::value#1 [phi:utoa::@1->utoa::@6#2] -- register_copy 
    // [1848] phi utoa::digit#2 = 0 [phi:utoa::@1->utoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // utoa::@6
  __b6:
    // max_digits-1
    // [1849] utoa::$4 = utoa::max_digits#7 - 1 -- vbuz1=vbum2_minus_1 
    ldx max_digits
    dex
    stx.z utoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1850] if(utoa::digit#2<utoa::$4) goto utoa::@7 -- vbum1_lt_vbuz2_then_la1 
    lda digit
    cmp.z utoa__4
    bcc __b7
    // utoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1851] utoa::$11 = (char)utoa::value#2 -- vbuz1=_byte_vwum2 
    lda value
    sta.z utoa__11
    // [1852] *utoa::buffer#11 = DIGITS[utoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1853] utoa::buffer#3 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1854] *utoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // utoa::@7
  __b7:
    // unsigned int digit_value = digit_values[digit]
    // [1855] utoa::$10 = utoa::digit#2 << 1 -- vbuz1=vbum2_rol_1 
    lda digit
    asl
    sta.z utoa__10
    // [1856] utoa::digit_value#0 = utoa::digit_values#8[utoa::$10] -- vwum1=pwuz2_derefidx_vbuz3 
    tay
    lda (digit_values),y
    sta digit_value
    iny
    lda (digit_values),y
    sta digit_value+1
    // if (started || value >= digit_value)
    // [1857] if(0!=utoa::started#2) goto utoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // utoa::@12
    // [1858] if(utoa::value#2>=utoa::digit_value#0) goto utoa::@10 -- vwum1_ge_vwum2_then_la1 
    lda digit_value+1
    cmp value+1
    bne !+
    lda digit_value
    cmp value
    beq __b10
  !:
    bcc __b10
    // [1859] phi from utoa::@12 to utoa::@9 [phi:utoa::@12->utoa::@9]
    // [1859] phi utoa::buffer#14 = utoa::buffer#11 [phi:utoa::@12->utoa::@9#0] -- register_copy 
    // [1859] phi utoa::started#4 = utoa::started#2 [phi:utoa::@12->utoa::@9#1] -- register_copy 
    // [1859] phi utoa::value#6 = utoa::value#2 [phi:utoa::@12->utoa::@9#2] -- register_copy 
    // utoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1860] utoa::digit#1 = ++ utoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [1848] phi from utoa::@9 to utoa::@6 [phi:utoa::@9->utoa::@6]
    // [1848] phi utoa::buffer#11 = utoa::buffer#14 [phi:utoa::@9->utoa::@6#0] -- register_copy 
    // [1848] phi utoa::started#2 = utoa::started#4 [phi:utoa::@9->utoa::@6#1] -- register_copy 
    // [1848] phi utoa::value#2 = utoa::value#6 [phi:utoa::@9->utoa::@6#2] -- register_copy 
    // [1848] phi utoa::digit#2 = utoa::digit#1 [phi:utoa::@9->utoa::@6#3] -- register_copy 
    jmp __b6
    // utoa::@10
  __b10:
    // utoa_append(buffer++, value, digit_value)
    // [1861] utoa_append::buffer#0 = utoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z utoa_append.buffer
    lda.z buffer+1
    sta.z utoa_append.buffer+1
    // [1862] utoa_append::value#0 = utoa::value#2
    // [1863] utoa_append::sub#0 = utoa::digit_value#0
    // [1864] call utoa_append
    // [2410] phi from utoa::@10 to utoa_append [phi:utoa::@10->utoa_append]
    jsr utoa_append
    // utoa_append(buffer++, value, digit_value)
    // [1865] utoa_append::return#0 = utoa_append::value#2
    // utoa::@11
    // value = utoa_append(buffer++, value, digit_value)
    // [1866] utoa::value#0 = utoa_append::return#0
    // value = utoa_append(buffer++, value, digit_value);
    // [1867] utoa::buffer#4 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1859] phi from utoa::@11 to utoa::@9 [phi:utoa::@11->utoa::@9]
    // [1859] phi utoa::buffer#14 = utoa::buffer#4 [phi:utoa::@11->utoa::@9#0] -- register_copy 
    // [1859] phi utoa::started#4 = 1 [phi:utoa::@11->utoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [1859] phi utoa::value#6 = utoa::value#0 [phi:utoa::@11->utoa::@9#2] -- register_copy 
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
// void printf_number_buffer(__zp($6c) void (*putc)(char), __mem() char buffer_sign, char *buffer_digits, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, char format_radix)
printf_number_buffer: {
    .label printf_number_buffer__19 = $70
    .label putc = $6c
    // if(format.min_length)
    // [1869] if(0==printf_number_buffer::format_min_length#3) goto printf_number_buffer::@1 -- 0_eq_vbum1_then_la1 
    lda format_min_length
    beq __b5
    // [1870] phi from printf_number_buffer to printf_number_buffer::@5 [phi:printf_number_buffer->printf_number_buffer::@5]
    // printf_number_buffer::@5
    // strlen(buffer.digits)
    // [1871] call strlen
    // [2158] phi from printf_number_buffer::@5 to strlen [phi:printf_number_buffer::@5->strlen]
    // [2158] phi strlen::str#8 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@5->strlen#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str+1
    jsr strlen
    // strlen(buffer.digits)
    // [1872] strlen::return#3 = strlen::len#2
    // printf_number_buffer::@11
    // [1873] printf_number_buffer::$19 = strlen::return#3 -- vwuz1=vwum2 
    lda strlen.return
    sta.z printf_number_buffer__19
    lda strlen.return+1
    sta.z printf_number_buffer__19+1
    // signed char len = (signed char)strlen(buffer.digits)
    // [1874] printf_number_buffer::len#0 = (signed char)printf_number_buffer::$19 -- vbsm1=_sbyte_vwuz2 
    // There is a minimum length - work out the padding
    lda.z printf_number_buffer__19
    sta len
    // if(buffer.sign)
    // [1875] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@10 -- 0_eq_vbum1_then_la1 
    lda buffer_sign
    beq __b10
    // printf_number_buffer::@6
    // len++;
    // [1876] printf_number_buffer::len#1 = ++ printf_number_buffer::len#0 -- vbsm1=_inc_vbsm1 
    inc len
    // [1877] phi from printf_number_buffer::@11 printf_number_buffer::@6 to printf_number_buffer::@10 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10]
    // [1877] phi printf_number_buffer::len#2 = printf_number_buffer::len#0 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10#0] -- register_copy 
    // printf_number_buffer::@10
  __b10:
    // padding = (signed char)format.min_length - len
    // [1878] printf_number_buffer::padding#1 = (signed char)printf_number_buffer::format_min_length#3 - printf_number_buffer::len#2 -- vbsm1=vbsm2_minus_vbsm1 
    lda format_min_length
    sec
    sbc padding
    sta padding
    // if(padding<0)
    // [1879] if(printf_number_buffer::padding#1>=0) goto printf_number_buffer::@15 -- vbsm1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1881] phi from printf_number_buffer printf_number_buffer::@10 to printf_number_buffer::@1 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1]
  __b5:
    // [1881] phi printf_number_buffer::padding#10 = 0 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1#0] -- vbsm1=vbsc1 
    lda #0
    sta padding
    // [1880] phi from printf_number_buffer::@10 to printf_number_buffer::@15 [phi:printf_number_buffer::@10->printf_number_buffer::@15]
    // printf_number_buffer::@15
    // [1881] phi from printf_number_buffer::@15 to printf_number_buffer::@1 [phi:printf_number_buffer::@15->printf_number_buffer::@1]
    // [1881] phi printf_number_buffer::padding#10 = printf_number_buffer::padding#1 [phi:printf_number_buffer::@15->printf_number_buffer::@1#0] -- register_copy 
    // printf_number_buffer::@1
  __b1:
    // printf_number_buffer::@13
    // if(!format.justify_left && !format.zero_padding && padding)
    // [1882] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@2 -- 0_neq_vbum1_then_la1 
    lda format_zero_padding
    bne __b2
    // printf_number_buffer::@12
    // [1883] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@7 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b7
    jmp __b2
    // printf_number_buffer::@7
  __b7:
    // printf_padding(putc, ' ',(char)padding)
    // [1884] printf_padding::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1885] printf_padding::length#0 = (char)printf_number_buffer::padding#10 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1886] call printf_padding
    // [2164] phi from printf_number_buffer::@7 to printf_padding [phi:printf_number_buffer::@7->printf_padding]
    // [2164] phi printf_padding::putc#7 = printf_padding::putc#0 [phi:printf_number_buffer::@7->printf_padding#0] -- register_copy 
    // [2164] phi printf_padding::pad#7 = ' ' [phi:printf_number_buffer::@7->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [2164] phi printf_padding::length#6 = printf_padding::length#0 [phi:printf_number_buffer::@7->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@2
  __b2:
    // if(buffer.sign)
    // [1887] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@3 -- 0_eq_vbum1_then_la1 
    lda buffer_sign
    beq __b3
    // printf_number_buffer::@8
    // putc(buffer.sign)
    // [1888] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbum1 
    pha
    // [1889] callexecute *printf_number_buffer::putc#10  -- call__deref_pprz1 
    jsr icall34
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@3
  __b3:
    // if(format.zero_padding && padding)
    // [1891] if(0==printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@4 -- 0_eq_vbum1_then_la1 
    lda format_zero_padding
    beq __b4
    // printf_number_buffer::@14
    // [1892] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@9 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b9
    jmp __b4
    // printf_number_buffer::@9
  __b9:
    // printf_padding(putc, '0',(char)padding)
    // [1893] printf_padding::putc#1 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1894] printf_padding::length#1 = (char)printf_number_buffer::padding#10 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1895] call printf_padding
    // [2164] phi from printf_number_buffer::@9 to printf_padding [phi:printf_number_buffer::@9->printf_padding]
    // [2164] phi printf_padding::putc#7 = printf_padding::putc#1 [phi:printf_number_buffer::@9->printf_padding#0] -- register_copy 
    // [2164] phi printf_padding::pad#7 = '0' [phi:printf_number_buffer::@9->printf_padding#1] -- vbum1=vbuc1 
    lda #'0'
    sta printf_padding.pad
    // [2164] phi printf_padding::length#6 = printf_padding::length#1 [phi:printf_number_buffer::@9->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@4
  __b4:
    // printf_str(putc, buffer.digits)
    // [1896] printf_str::putc#0 = printf_number_buffer::putc#10
    // [1897] call printf_str
    // [725] phi from printf_number_buffer::@4 to printf_str [phi:printf_number_buffer::@4->printf_str]
    // [725] phi printf_str::putc#71 = printf_str::putc#0 [phi:printf_number_buffer::@4->printf_str#0] -- register_copy 
    // [725] phi printf_str::s#71 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@return
    // }
    // [1898] return 
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
  // display_vera_led
/**
 * @brief Print VERA led above the VERA chip.
 * 
 * @param c Led color
 */
// void display_vera_led(__zp($c5) char c)
display_vera_led: {
    .label c = $c5
    // display_chip_led(CHIP_VERA_X+1, CHIP_VERA_Y, CHIP_VERA_W, c, BLUE)
    // [1900] display_chip_led::tc#1 = display_vera_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_chip_led.tc
    // [1901] call display_chip_led
    // [2331] phi from display_vera_led to display_chip_led [phi:display_vera_led->display_chip_led]
    // [2331] phi display_chip_led::w#7 = 8 [phi:display_vera_led->display_chip_led#0] -- vbuz1=vbuc1 
    lda #8
    sta.z display_chip_led.w
    // [2331] phi display_chip_led::x#7 = 9+1 [phi:display_vera_led->display_chip_led#1] -- vbuz1=vbuc1 
    lda #9+1
    sta.z display_chip_led.x
    // [2331] phi display_chip_led::tc#3 = display_chip_led::tc#1 [phi:display_vera_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_vera_led::@1
    // display_info_led(INFO_X-2, INFO_Y+1, c, BLUE)
    // [1902] display_info_led::tc#1 = display_vera_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_info_led.tc
    // [1903] call display_info_led
    // [1546] phi from display_vera_led::@1 to display_info_led [phi:display_vera_led::@1->display_info_led]
    // [1546] phi display_info_led::y#4 = $11+1 [phi:display_vera_led::@1->display_info_led#0] -- vbuz1=vbuc1 
    lda #$11+1
    sta.z display_info_led.y
    // [1546] phi display_info_led::x#4 = 4-2 [phi:display_vera_led::@1->display_info_led#1] -- vbuz1=vbuc1 
    lda #4-2
    sta.z display_info_led.x
    // [1546] phi display_info_led::tc#4 = display_info_led::tc#1 [phi:display_vera_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_vera_led::@return
    // }
    // [1904] return 
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
// void rom_unlock(__zp($50) unsigned long address, __zp($58) char unlock_code)
rom_unlock: {
    .label address = $50
    .label unlock_code = $58
    // unsigned long chip_address = address & ROM_CHIP_MASK
    // [1906] rom_unlock::chip_address#0 = rom_unlock::address#5 & $380000 -- vdum1=vduz2_band_vduc1 
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
    // [1907] rom_write_byte::address#0 = rom_unlock::chip_address#0 + $5555 -- vduz1=vdum2_plus_vwuc1 
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
    // [1908] call rom_write_byte
  // This is a very important operation...
    // [2417] phi from rom_unlock to rom_write_byte [phi:rom_unlock->rom_write_byte]
    // [2417] phi rom_write_byte::value#10 = $aa [phi:rom_unlock->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$aa
    sta.z rom_write_byte.value
    // [2417] phi rom_write_byte::address#4 = rom_write_byte::address#0 [phi:rom_unlock->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@1
    // rom_write_byte(chip_address + 0x02AAA, 0x55)
    // [1909] rom_write_byte::address#1 = rom_unlock::chip_address#0 + $2aaa -- vduz1=vdum2_plus_vwuc1 
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
    // [1910] call rom_write_byte
    // [2417] phi from rom_unlock::@1 to rom_write_byte [phi:rom_unlock::@1->rom_write_byte]
    // [2417] phi rom_write_byte::value#10 = $55 [phi:rom_unlock::@1->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$55
    sta.z rom_write_byte.value
    // [2417] phi rom_write_byte::address#4 = rom_write_byte::address#1 [phi:rom_unlock::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@2
    // rom_write_byte(address, unlock_code)
    // [1911] rom_write_byte::address#2 = rom_unlock::address#5 -- vduz1=vduz2 
    lda.z address
    sta.z rom_write_byte.address
    lda.z address+1
    sta.z rom_write_byte.address+1
    lda.z address+2
    sta.z rom_write_byte.address+2
    lda.z address+3
    sta.z rom_write_byte.address+3
    // [1912] rom_write_byte::value#2 = rom_unlock::unlock_code#5 -- vbuz1=vbuz2 
    lda.z unlock_code
    sta.z rom_write_byte.value
    // [1913] call rom_write_byte
    // [2417] phi from rom_unlock::@2 to rom_write_byte [phi:rom_unlock::@2->rom_write_byte]
    // [2417] phi rom_write_byte::value#10 = rom_write_byte::value#2 [phi:rom_unlock::@2->rom_write_byte#0] -- register_copy 
    // [2417] phi rom_write_byte::address#4 = rom_write_byte::address#2 [phi:rom_unlock::@2->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@return
    // }
    // [1914] return 
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
// __mem() char rom_read_byte(__zp($50) unsigned long address)
rom_read_byte: {
    .label rom_bank1_rom_read_byte__0 = $2b
    .label rom_bank1_rom_read_byte__1 = $3a
    .label rom_bank1_rom_read_byte__2 = $ba
    .label rom_ptr1_rom_read_byte__0 = $b8
    .label rom_ptr1_rom_read_byte__2 = $b8
    .label rom_ptr1_return = $b8
    .label address = $50
    // rom_read_byte::rom_bank1
    // BYTE2(address)
    // [1916] rom_read_byte::rom_bank1_$0 = byte2  rom_read_byte::address#2 -- vbuz1=_byte2_vduz2 
    lda.z address+2
    sta.z rom_bank1_rom_read_byte__0
    // BYTE1(address)
    // [1917] rom_read_byte::rom_bank1_$1 = byte1  rom_read_byte::address#2 -- vbuz1=_byte1_vduz2 
    lda.z address+1
    sta.z rom_bank1_rom_read_byte__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [1918] rom_read_byte::rom_bank1_$2 = rom_read_byte::rom_bank1_$0 w= rom_read_byte::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_read_byte__0
    sta.z rom_bank1_rom_read_byte__2+1
    lda.z rom_bank1_rom_read_byte__1
    sta.z rom_bank1_rom_read_byte__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [1919] rom_read_byte::rom_bank1_bank_unshifted#0 = rom_read_byte::rom_bank1_$2 << 2 -- vwum1=vwuz2_rol_2 
    asl
    sta rom_bank1_bank_unshifted
    lda.z rom_bank1_rom_read_byte__2+1
    rol
    sta rom_bank1_bank_unshifted+1
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [1920] rom_read_byte::rom_bank1_return#0 = byte1  rom_read_byte::rom_bank1_bank_unshifted#0 -- vbum1=_byte1_vwum2 
    lda rom_bank1_bank_unshifted+1
    sta rom_bank1_return
    // rom_read_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [1921] rom_read_byte::rom_ptr1_$2 = (unsigned int)rom_read_byte::address#2 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_read_byte__2
    lda.z address+1
    sta.z rom_ptr1_rom_read_byte__2+1
    // [1922] rom_read_byte::rom_ptr1_$0 = rom_read_byte::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_read_byte__0
    and #<$3fff
    sta.z rom_ptr1_rom_read_byte__0
    lda.z rom_ptr1_rom_read_byte__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_read_byte__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [1923] rom_read_byte::rom_ptr1_return#0 = rom_read_byte::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_read_byte::bank_set_brom1
    // BROM = bank
    // [1924] BROM = rom_read_byte::rom_bank1_return#0 -- vbuz1=vbum2 
    lda rom_bank1_return
    sta.z BROM
    // rom_read_byte::@1
    // return *ptr_rom;
    // [1925] rom_read_byte::return#0 = *((char *)rom_read_byte::rom_ptr1_return#0) -- vbum1=_deref_pbuz2 
    ldy #0
    lda (rom_ptr1_return),y
    sta return
    // rom_read_byte::@return
    // }
    // [1926] return 
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
    .label dst = $36
    .label src = $3b
    // [1928] phi from strcpy to strcpy::@1 [phi:strcpy->strcpy::@1]
    // [1928] phi strcpy::dst#2 = display_chip_rom::rom [phi:strcpy->strcpy::@1#0] -- pbuz1=pbuc1 
    lda #<display_chip_rom.rom
    sta.z dst
    lda #>display_chip_rom.rom
    sta.z dst+1
    // [1928] phi strcpy::src#2 = display_chip_rom::source [phi:strcpy->strcpy::@1#1] -- pbuz1=pbuc1 
    lda #<display_chip_rom.source
    sta.z src
    lda #>display_chip_rom.source
    sta.z src+1
    // strcpy::@1
  __b1:
    // while(*src)
    // [1929] if(0!=*strcpy::src#2) goto strcpy::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcpy::@3
    // *dst = 0
    // [1930] *strcpy::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcpy::@return
    // }
    // [1931] return 
    rts
    // strcpy::@2
  __b2:
    // *dst++ = *src++
    // [1932] *strcpy::dst#2 = *strcpy::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [1933] strcpy::dst#1 = ++ strcpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [1934] strcpy::src#1 = ++ strcpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [1928] phi from strcpy::@2 to strcpy::@1 [phi:strcpy::@2->strcpy::@1]
    // [1928] phi strcpy::dst#2 = strcpy::dst#1 [phi:strcpy::@2->strcpy::@1#0] -- register_copy 
    // [1928] phi strcpy::src#2 = strcpy::src#1 [phi:strcpy::@2->strcpy::@1#1] -- register_copy 
    jmp __b1
}
  // strcat
// Concatenates the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcat(char *destination, __zp($42) char *source)
strcat: {
    .label strcat__0 = $a9
    .label dst = $a9
    .label src = $42
    .label source = $42
    // strlen(destination)
    // [1936] call strlen
    // [2158] phi from strcat to strlen [phi:strcat->strlen]
    // [2158] phi strlen::str#8 = display_chip_rom::rom [phi:strcat->strlen#0] -- pbuz1=pbuc1 
    lda #<display_chip_rom.rom
    sta.z strlen.str
    lda #>display_chip_rom.rom
    sta.z strlen.str+1
    jsr strlen
    // strlen(destination)
    // [1937] strlen::return#0 = strlen::len#2
    // strcat::@4
    // [1938] strcat::$0 = strlen::return#0 -- vwuz1=vwum2 
    lda strlen.return
    sta.z strcat__0
    lda strlen.return+1
    sta.z strcat__0+1
    // char* dst = destination + strlen(destination)
    // [1939] strcat::dst#0 = display_chip_rom::rom + strcat::$0 -- pbuz1=pbuc1_plus_vwuz1 
    lda.z dst
    clc
    adc #<display_chip_rom.rom
    sta.z dst
    lda.z dst+1
    adc #>display_chip_rom.rom
    sta.z dst+1
    // [1940] phi from strcat::@2 strcat::@4 to strcat::@1 [phi:strcat::@2/strcat::@4->strcat::@1]
    // [1940] phi strcat::dst#2 = strcat::dst#1 [phi:strcat::@2/strcat::@4->strcat::@1#0] -- register_copy 
    // [1940] phi strcat::src#2 = strcat::src#1 [phi:strcat::@2/strcat::@4->strcat::@1#1] -- register_copy 
    // strcat::@1
  __b1:
    // while(*src)
    // [1941] if(0!=*strcat::src#2) goto strcat::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcat::@3
    // *dst = 0
    // [1942] *strcat::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcat::@return
    // }
    // [1943] return 
    rts
    // strcat::@2
  __b2:
    // *dst++ = *src++
    // [1944] *strcat::dst#2 = *strcat::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [1945] strcat::dst#1 = ++ strcat::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [1946] strcat::src#1 = ++ strcat::src#2 -- pbuz1=_inc_pbuz1 
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
// void display_rom_led(__zp($79) char chip, __zp($7a) char c)
display_rom_led: {
    .label display_rom_led__0 = $69
    .label chip = $79
    .label c = $7a
    .label display_rom_led__7 = $69
    .label display_rom_led__8 = $69
    // chip*6
    // [1948] display_rom_led::$7 = display_rom_led::chip#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z chip
    asl
    sta.z display_rom_led__7
    // [1949] display_rom_led::$8 = display_rom_led::$7 + display_rom_led::chip#2 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z display_rom_led__8
    clc
    adc.z chip
    sta.z display_rom_led__8
    // CHIP_ROM_X+chip*6
    // [1950] display_rom_led::$0 = display_rom_led::$8 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_rom_led__0
    // display_chip_led(CHIP_ROM_X+chip*6+1, CHIP_ROM_Y, CHIP_ROM_W, c, BLUE)
    // [1951] display_chip_led::x#3 = display_rom_led::$0 + $14+1 -- vbuz1=vbuz1_plus_vbuc1 
    lda #$14+1
    clc
    adc.z display_chip_led.x
    sta.z display_chip_led.x
    // [1952] display_chip_led::tc#2 = display_rom_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_chip_led.tc
    // [1953] call display_chip_led
    // [2331] phi from display_rom_led to display_chip_led [phi:display_rom_led->display_chip_led]
    // [2331] phi display_chip_led::w#7 = 3 [phi:display_rom_led->display_chip_led#0] -- vbuz1=vbuc1 
    lda #3
    sta.z display_chip_led.w
    // [2331] phi display_chip_led::x#7 = display_chip_led::x#3 [phi:display_rom_led->display_chip_led#1] -- register_copy 
    // [2331] phi display_chip_led::tc#3 = display_chip_led::tc#2 [phi:display_rom_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_rom_led::@1
    // display_info_led(INFO_X-2, INFO_Y+chip+2, c, BLUE)
    // [1954] display_info_led::y#2 = display_rom_led::chip#2 + $11+2 -- vbuz1=vbuz2_plus_vbuc1 
    lda #$11+2
    clc
    adc.z chip
    sta.z display_info_led.y
    // [1955] display_info_led::tc#2 = display_rom_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_info_led.tc
    // [1956] call display_info_led
    // [1546] phi from display_rom_led::@1 to display_info_led [phi:display_rom_led::@1->display_info_led]
    // [1546] phi display_info_led::y#4 = display_info_led::y#2 [phi:display_rom_led::@1->display_info_led#0] -- register_copy 
    // [1546] phi display_info_led::x#4 = 4-2 [phi:display_rom_led::@1->display_info_led#1] -- vbuz1=vbuc1 
    lda #4-2
    sta.z display_info_led.x
    // [1546] phi display_info_led::tc#4 = display_info_led::tc#2 [phi:display_rom_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_rom_led::@return
    // }
    // [1957] return 
    rts
}
  // display_progress_line
// void display_progress_line(__zp($75) char line, __zp($6c) char *text)
display_progress_line: {
    .label line = $75
    .label text = $6c
    // cputsxy(PROGRESS_X, PROGRESS_Y+line, text)
    // [1958] cputsxy::y#0 = PROGRESS_Y + display_progress_line::line#0 -- vbum1=vbuc1_plus_vbuz2 
    lda #PROGRESS_Y
    clc
    adc.z line
    sta cputsxy.y
    // [1959] cputsxy::s#0 = display_progress_line::text#0
    // [1960] call cputsxy
    // [669] phi from display_progress_line to cputsxy [phi:display_progress_line->cputsxy]
    // [669] phi cputsxy::s#4 = cputsxy::s#0 [phi:display_progress_line->cputsxy#0] -- register_copy 
    // [669] phi cputsxy::y#4 = cputsxy::y#0 [phi:display_progress_line->cputsxy#1] -- register_copy 
    // [669] phi cputsxy::x#4 = PROGRESS_X [phi:display_progress_line->cputsxy#2] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta cputsxy.x
    jsr cputsxy
    // display_progress_line::@return
    // }
    // [1961] return 
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
    // [1962] cbm_k_getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // asm
    // asm { jsrCBM_GETIN stach  }
    jsr CBM_GETIN
    sta ch
    // return ch;
    // [1964] cbm_k_getin::return#0 = cbm_k_getin::ch -- vbum1=vbum2 
    sta return
    // cbm_k_getin::@return
    // }
    // [1965] cbm_k_getin::return#1 = cbm_k_getin::return#0
    // [1966] return 
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
// __zp($b6) struct $2 * fopen(__zp($6a) const char *path, const char *mode)
fopen: {
    .label fopen__4 = $75
    .label fopen__9 = $61
    .label fopen__11 = $c0
    .label fopen__15 = $62
    .label fopen__16 = $4b
    .label fopen__26 = $48
    .label fopen__28 = $ab
    .label fopen__30 = $b6
    .label cbm_k_setnam1_filename = $cb
    .label cbm_k_setnam1_fopen__0 = $c2
    .label stream = $b6
    .label pathtoken = $6a
    .label pathtoken_1 = $af
    .label path = $6a
    .label return = $b6
    // unsigned char sp = __stdio_filecount
    // [1968] fopen::sp#0 = __stdio_filecount -- vbum1=vbum2 
    lda __stdio_filecount
    sta sp
    // (unsigned int)sp | 0x8000
    // [1969] fopen::$30 = (unsigned int)fopen::sp#0 -- vwuz1=_word_vbum2 
    sta.z fopen__30
    lda #0
    sta.z fopen__30+1
    // [1970] fopen::stream#0 = fopen::$30 | $8000 -- vwuz1=vwuz1_bor_vwuc1 
    lda.z stream
    ora #<$8000
    sta.z stream
    lda.z stream+1
    ora #>$8000
    sta.z stream+1
    // char pathpos = sp * __STDIO_FILECOUNT
    // [1971] fopen::pathpos#0 = fopen::sp#0 << 2 -- vbum1=vbum2_rol_2 
    lda sp
    asl
    asl
    sta pathpos
    // __logical = 0
    // [1972] ((char *)&__stdio_file+$80)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy sp
    sta __stdio_file+$80,y
    // __device = 0
    // [1973] ((char *)&__stdio_file+$84)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$84,y
    // __channel = 0
    // [1974] ((char *)&__stdio_file+$88)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$88,y
    // [1975] fopen::pathtoken#22 = fopen::pathtoken#0 -- pbuz1=pbuz2 
    lda.z pathtoken
    sta.z pathtoken_1
    lda.z pathtoken+1
    sta.z pathtoken_1+1
    // [1976] fopen::pathpos#21 = fopen::pathpos#0 -- vbum1=vbum2 
    lda pathpos
    sta pathpos_1
    // [1977] phi from fopen to fopen::@8 [phi:fopen->fopen::@8]
    // [1977] phi fopen::num#10 = 0 [phi:fopen->fopen::@8#0] -- vbum1=vbuc1 
    lda #0
    sta num
    // [1977] phi fopen::pathpos#10 = fopen::pathpos#21 [phi:fopen->fopen::@8#1] -- register_copy 
    // [1977] phi fopen::path#10 = fopen::pathtoken#0 [phi:fopen->fopen::@8#2] -- register_copy 
    // [1977] phi fopen::pathstep#10 = 0 [phi:fopen->fopen::@8#3] -- vbum1=vbuc1 
    sta pathstep
    // [1977] phi fopen::pathtoken#10 = fopen::pathtoken#22 [phi:fopen->fopen::@8#4] -- register_copy 
  // Iterate while path is not \0.
    // [1977] phi from fopen::@22 to fopen::@8 [phi:fopen::@22->fopen::@8]
    // [1977] phi fopen::num#10 = fopen::num#13 [phi:fopen::@22->fopen::@8#0] -- register_copy 
    // [1977] phi fopen::pathpos#10 = fopen::pathpos#7 [phi:fopen::@22->fopen::@8#1] -- register_copy 
    // [1977] phi fopen::path#10 = fopen::path#11 [phi:fopen::@22->fopen::@8#2] -- register_copy 
    // [1977] phi fopen::pathstep#10 = fopen::pathstep#11 [phi:fopen::@22->fopen::@8#3] -- register_copy 
    // [1977] phi fopen::pathtoken#10 = fopen::pathtoken#1 [phi:fopen::@22->fopen::@8#4] -- register_copy 
    // fopen::@8
  __b8:
    // if (*pathtoken == ',' || *pathtoken == '\0')
    // [1978] if(*fopen::pathtoken#10==',') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #','
    ldy #0
    cmp (pathtoken_1),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@33
    // [1979] if(*fopen::pathtoken#10=='@') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #'@'
    cmp (pathtoken_1),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@23
    // if (pathstep == 0)
    // [1980] if(fopen::pathstep#10!=0) goto fopen::@10 -- vbum1_neq_0_then_la1 
    lda pathstep
    bne __b10
    // fopen::@24
    // __stdio_file.filename[pathpos] = *pathtoken
    // [1981] ((char *)&__stdio_file)[fopen::pathpos#10] = *fopen::pathtoken#10 -- pbuc1_derefidx_vbum1=_deref_pbuz2 
    lda (pathtoken_1),y
    ldy pathpos_1
    sta __stdio_file,y
    // pathpos++;
    // [1982] fopen::pathpos#1 = ++ fopen::pathpos#10 -- vbum1=_inc_vbum1 
    inc pathpos_1
    // [1983] phi from fopen::@12 fopen::@23 fopen::@24 to fopen::@10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10]
    // [1983] phi fopen::num#13 = fopen::num#15 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#0] -- register_copy 
    // [1983] phi fopen::pathpos#7 = fopen::pathpos#10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#1] -- register_copy 
    // [1983] phi fopen::path#11 = fopen::path#13 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#2] -- register_copy 
    // [1983] phi fopen::pathstep#11 = fopen::pathstep#1 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#3] -- register_copy 
    // fopen::@10
  __b10:
    // pathtoken++;
    // [1984] fopen::pathtoken#1 = ++ fopen::pathtoken#10 -- pbuz1=_inc_pbuz1 
    inc.z pathtoken_1
    bne !+
    inc.z pathtoken_1+1
  !:
    // fopen::@22
    // pathtoken - 1
    // [1985] fopen::$28 = fopen::pathtoken#1 - 1 -- pbuz1=pbuz2_minus_1 
    lda.z pathtoken_1
    sec
    sbc #1
    sta.z fopen__28
    lda.z pathtoken_1+1
    sbc #0
    sta.z fopen__28+1
    // while (*(pathtoken - 1))
    // [1986] if(0!=*fopen::$28) goto fopen::@8 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (fopen__28),y
    cmp #0
    bne __b8
    // fopen::@26
    // __status = 0
    // [1987] ((char *)&__stdio_file+$8c)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    tya
    ldy sp
    sta __stdio_file+$8c,y
    // if(!__logical)
    // [1988] if(0!=((char *)&__stdio_file+$80)[fopen::sp#0]) goto fopen::@1 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$80,y
    cmp #0
    bne __b1
    // fopen::@27
    // __stdio_filecount+1
    // [1989] fopen::$4 = __stdio_filecount + 1 -- vbuz1=vbum2_plus_1 
    lda __stdio_filecount
    inc
    sta.z fopen__4
    // __logical = __stdio_filecount+1
    // [1990] ((char *)&__stdio_file+$80)[fopen::sp#0] = fopen::$4 -- pbuc1_derefidx_vbum1=vbuz2 
    sta __stdio_file+$80,y
    // fopen::@1
  __b1:
    // if(!__device)
    // [1991] if(0!=((char *)&__stdio_file+$84)[fopen::sp#0]) goto fopen::@2 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    ldy sp
    lda __stdio_file+$84,y
    cmp #0
    bne __b2
    // fopen::@5
    // __device = 8
    // [1992] ((char *)&__stdio_file+$84)[fopen::sp#0] = 8 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #8
    sta __stdio_file+$84,y
    // fopen::@2
  __b2:
    // if(!__channel)
    // [1993] if(0!=((char *)&__stdio_file+$88)[fopen::sp#0]) goto fopen::@3 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    ldy sp
    lda __stdio_file+$88,y
    cmp #0
    bne __b3
    // fopen::@6
    // __stdio_filecount+2
    // [1994] fopen::$9 = __stdio_filecount + 2 -- vbuz1=vbum2_plus_2 
    lda __stdio_filecount
    clc
    adc #2
    sta.z fopen__9
    // __channel = __stdio_filecount+2
    // [1995] ((char *)&__stdio_file+$88)[fopen::sp#0] = fopen::$9 -- pbuc1_derefidx_vbum1=vbuz2 
    sta __stdio_file+$88,y
    // fopen::@3
  __b3:
    // __filename
    // [1996] fopen::$11 = (char *)&__stdio_file + fopen::pathpos#0 -- pbuz1=pbuc1_plus_vbum2 
    lda pathpos
    clc
    adc #<__stdio_file
    sta.z fopen__11
    lda #>__stdio_file
    adc #0
    sta.z fopen__11+1
    // cbm_k_setnam(__filename)
    // [1997] fopen::cbm_k_setnam1_filename = fopen::$11 -- pbuz1=pbuz2 
    lda.z fopen__11
    sta.z cbm_k_setnam1_filename
    lda.z fopen__11+1
    sta.z cbm_k_setnam1_filename+1
    // fopen::cbm_k_setnam1
    // strlen(filename)
    // [1998] strlen::str#4 = fopen::cbm_k_setnam1_filename -- pbuz1=pbuz2 
    lda.z cbm_k_setnam1_filename
    sta.z strlen.str
    lda.z cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [1999] call strlen
    // [2158] phi from fopen::cbm_k_setnam1 to strlen [phi:fopen::cbm_k_setnam1->strlen]
    // [2158] phi strlen::str#8 = strlen::str#4 [phi:fopen::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [2000] strlen::return#11 = strlen::len#2
    // fopen::@31
    // [2001] fopen::cbm_k_setnam1_$0 = strlen::return#11 -- vwuz1=vwum2 
    lda strlen.return
    sta.z cbm_k_setnam1_fopen__0
    lda strlen.return+1
    sta.z cbm_k_setnam1_fopen__0+1
    // char filename_len = (char)strlen(filename)
    // [2002] fopen::cbm_k_setnam1_filename_len = (char)fopen::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
    lda.z cbm_k_setnam1_fopen__0
    sta cbm_k_setnam1_filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx cbm_k_setnam1_filename
    ldy cbm_k_setnam1_filename+1
    jsr CBM_SETNAM
    // fopen::@28
    // cbm_k_setlfs(__logical, __device, __channel)
    // [2004] cbm_k_setlfs::channel = ((char *)&__stdio_file+$80)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$80,y
    sta cbm_k_setlfs.channel
    // [2005] cbm_k_setlfs::device = ((char *)&__stdio_file+$84)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    lda __stdio_file+$84,y
    sta cbm_k_setlfs.device
    // [2006] cbm_k_setlfs::command = ((char *)&__stdio_file+$88)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    lda __stdio_file+$88,y
    sta cbm_k_setlfs.command
    // [2007] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // fopen::cbm_k_open1
    // asm
    // asm { jsrCBM_OPEN  }
    jsr CBM_OPEN
    // fopen::cbm_k_readst1
    // char status
    // [2009] fopen::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2011] fopen::cbm_k_readst1_return#0 = fopen::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // fopen::cbm_k_readst1_@return
    // }
    // [2012] fopen::cbm_k_readst1_return#1 = fopen::cbm_k_readst1_return#0
    // fopen::@29
    // cbm_k_readst()
    // [2013] fopen::$15 = fopen::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z fopen__15
    // __status = cbm_k_readst()
    // [2014] ((char *)&__stdio_file+$8c)[fopen::sp#0] = fopen::$15 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$8c,y
    // ferror(stream)
    // [2015] ferror::stream#0 = (struct $2 *)fopen::stream#0
    // [2016] call ferror
    jsr ferror
    // [2017] ferror::return#0 = ferror::return#1
    // fopen::@32
    // [2018] fopen::$16 = ferror::return#0 -- vwsz1=vwsm2 
    lda ferror.return
    sta.z fopen__16
    lda ferror.return+1
    sta.z fopen__16+1
    // if (ferror(stream))
    // [2019] if(0==fopen::$16) goto fopen::@4 -- 0_eq_vwsz1_then_la1 
    lda.z fopen__16
    ora.z fopen__16+1
    beq __b4
    // fopen::@7
    // cbm_k_close(__logical)
    // [2020] fopen::cbm_k_close1_channel = ((char *)&__stdio_file+$80)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$80,y
    sta cbm_k_close1_channel
    // fopen::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // [2022] phi from fopen::cbm_k_close1 to fopen::@return [phi:fopen::cbm_k_close1->fopen::@return]
    // [2022] phi fopen::return#2 = 0 [phi:fopen::cbm_k_close1->fopen::@return#0] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fopen::@return
    // }
    // [2023] return 
    rts
    // fopen::@4
  __b4:
    // __stdio_filecount++;
    // [2024] __stdio_filecount = ++ __stdio_filecount -- vbum1=_inc_vbum1 
    inc __stdio_filecount
    // [2025] fopen::return#8 = (struct $2 *)fopen::stream#0
    // [2022] phi from fopen::@4 to fopen::@return [phi:fopen::@4->fopen::@return]
    // [2022] phi fopen::return#2 = fopen::return#8 [phi:fopen::@4->fopen::@return#0] -- register_copy 
    rts
    // fopen::@9
  __b9:
    // if (pathstep > 0)
    // [2026] if(fopen::pathstep#10>0) goto fopen::@11 -- vbum1_gt_0_then_la1 
    lda pathstep
    bne __b11
    // fopen::@25
    // __stdio_file.filename[pathpos] = '\0'
    // [2027] ((char *)&__stdio_file)[fopen::pathpos#10] = '@' -- pbuc1_derefidx_vbum1=vbuc2 
    lda #'@'
    ldy pathpos_1
    sta __stdio_file,y
    // path = pathtoken + 1
    // [2028] fopen::path#0 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
    clc
    lda.z pathtoken_1
    adc #1
    sta.z path
    lda.z pathtoken_1+1
    adc #0
    sta.z path+1
    // [2029] phi from fopen::@16 fopen::@17 fopen::@18 fopen::@19 fopen::@25 to fopen::@12 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12]
    // [2029] phi fopen::num#15 = fopen::num#2 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#0] -- register_copy 
    // [2029] phi fopen::path#13 = fopen::path#16 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#1] -- register_copy 
    // fopen::@12
  __b12:
    // pathstep++;
    // [2030] fopen::pathstep#1 = ++ fopen::pathstep#10 -- vbum1=_inc_vbum1 
    inc pathstep
    jmp __b10
    // fopen::@11
  __b11:
    // char pathcmp = *path
    // [2031] fopen::pathcmp#0 = *fopen::path#10 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (path),y
    sta pathcmp
    // case 'D':
    // [2032] if(fopen::pathcmp#0=='D') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'D'
    cmp pathcmp
    beq __b13
    // fopen::@20
    // case 'L':
    // [2033] if(fopen::pathcmp#0=='L') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'L'
    cmp pathcmp
    beq __b13
    // fopen::@21
    // case 'C':
    //                     num = (char)atoi(path + 1);
    //                     path = pathtoken + 1;
    // [2034] if(fopen::pathcmp#0=='C') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'C'
    cmp pathcmp
    beq __b13
    // [2035] phi from fopen::@21 fopen::@30 to fopen::@14 [phi:fopen::@21/fopen::@30->fopen::@14]
    // [2035] phi fopen::path#16 = fopen::path#10 [phi:fopen::@21/fopen::@30->fopen::@14#0] -- register_copy 
    // [2035] phi fopen::num#2 = fopen::num#10 [phi:fopen::@21/fopen::@30->fopen::@14#1] -- register_copy 
    // fopen::@14
  __b14:
    // case 'L':
    //                     __logical = num;
    //                     break;
    // [2036] if(fopen::pathcmp#0=='L') goto fopen::@17 -- vbum1_eq_vbuc1_then_la1 
    lda #'L'
    cmp pathcmp
    beq __b17
    // fopen::@15
    // case 'D':
    //                     __device = num;
    //                     break;
    // [2037] if(fopen::pathcmp#0=='D') goto fopen::@18 -- vbum1_eq_vbuc1_then_la1 
    lda #'D'
    cmp pathcmp
    beq __b18
    // fopen::@16
    // case 'C':
    //                     __channel = num;
    //                     break;
    // [2038] if(fopen::pathcmp#0!='C') goto fopen::@12 -- vbum1_neq_vbuc1_then_la1 
    lda #'C'
    cmp pathcmp
    bne __b12
    // fopen::@19
    // __channel = num
    // [2039] ((char *)&__stdio_file+$88)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbum2 
    lda num
    ldy sp
    sta __stdio_file+$88,y
    jmp __b12
    // fopen::@18
  __b18:
    // __device = num
    // [2040] ((char *)&__stdio_file+$84)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbum2 
    lda num
    ldy sp
    sta __stdio_file+$84,y
    jmp __b12
    // fopen::@17
  __b17:
    // __logical = num
    // [2041] ((char *)&__stdio_file+$80)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbum2 
    lda num
    ldy sp
    sta __stdio_file+$80,y
    jmp __b12
    // fopen::@13
  __b13:
    // atoi(path + 1)
    // [2042] atoi::str#0 = fopen::path#10 + 1 -- pbuz1=pbuz1_plus_1 
    inc.z atoi.str
    bne !+
    inc.z atoi.str+1
  !:
    // [2043] call atoi
    // [2483] phi from fopen::@13 to atoi [phi:fopen::@13->atoi]
    // [2483] phi atoi::str#2 = atoi::str#0 [phi:fopen::@13->atoi#0] -- register_copy 
    jsr atoi
    // atoi(path + 1)
    // [2044] atoi::return#3 = atoi::return#2
    // fopen::@30
    // [2045] fopen::$26 = atoi::return#3 -- vwsz1=vwsm2 
    lda atoi.return
    sta.z fopen__26
    lda atoi.return+1
    sta.z fopen__26+1
    // num = (char)atoi(path + 1)
    // [2046] fopen::num#1 = (char)fopen::$26 -- vbum1=_byte_vwsz2 
    lda.z fopen__26
    sta num
    // path = pathtoken + 1
    // [2047] fopen::path#1 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
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
// __mem() unsigned int fgets(__zp($5d) char *ptr, __mem() unsigned int size, __zp($76) struct $2 *stream)
fgets: {
    .label fgets__1 = $75
    .label fgets__8 = $61
    .label fgets__9 = $62
    .label fgets__13 = $63
    .label ptr = $5d
    .label stream = $76
    // unsigned char sp = (unsigned char)stream
    // [2049] fgets::sp#0 = (char)fgets::stream#2 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_chkin(__logical)
    // [2050] fgets::cbm_k_chkin1_channel = ((char *)&__stdio_file+$80)[fgets::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    tay
    lda __stdio_file+$80,y
    sta cbm_k_chkin1_channel
    // fgets::cbm_k_chkin1
    // char status
    // [2051] fgets::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fgets::cbm_k_readst1
    // char status
    // [2053] fgets::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2055] fgets::cbm_k_readst1_return#0 = fgets::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // fgets::cbm_k_readst1_@return
    // }
    // [2056] fgets::cbm_k_readst1_return#1 = fgets::cbm_k_readst1_return#0
    // fgets::@11
    // cbm_k_readst()
    // [2057] fgets::$1 = fgets::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z fgets__1
    // __status = cbm_k_readst()
    // [2058] ((char *)&__stdio_file+$8c)[fgets::sp#0] = fgets::$1 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$8c,y
    // if (__status)
    // [2059] if(0==((char *)&__stdio_file+$8c)[fgets::sp#0]) goto fgets::@1 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$8c,y
    cmp #0
    beq __b1
    // [2060] phi from fgets::@11 fgets::@12 fgets::@5 to fgets::@return [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return]
  __b8:
    // [2060] phi fgets::return#1 = 0 [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return#0] -- vwum1=vbuc1 
    lda #<0
    sta return
    sta return+1
    // fgets::@return
    // }
    // [2061] return 
    rts
    // fgets::@1
  __b1:
    // [2062] fgets::remaining#22 = fgets::size#10 -- vwum1=vwum2 
    lda size
    sta remaining
    lda size+1
    sta remaining+1
    // [2063] phi from fgets::@1 to fgets::@2 [phi:fgets::@1->fgets::@2]
    // [2063] phi fgets::read#10 = 0 [phi:fgets::@1->fgets::@2#0] -- vwum1=vwuc1 
    lda #<0
    sta read
    sta read+1
    // [2063] phi fgets::remaining#11 = fgets::remaining#22 [phi:fgets::@1->fgets::@2#1] -- register_copy 
    // [2063] phi fgets::ptr#10 = fgets::ptr#12 [phi:fgets::@1->fgets::@2#2] -- register_copy 
    // [2063] phi from fgets::@17 fgets::@18 to fgets::@2 [phi:fgets::@17/fgets::@18->fgets::@2]
    // [2063] phi fgets::read#10 = fgets::read#1 [phi:fgets::@17/fgets::@18->fgets::@2#0] -- register_copy 
    // [2063] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@17/fgets::@18->fgets::@2#1] -- register_copy 
    // [2063] phi fgets::ptr#10 = fgets::ptr#13 [phi:fgets::@17/fgets::@18->fgets::@2#2] -- register_copy 
    // fgets::@2
  __b2:
    // if (!size)
    // [2064] if(0==fgets::size#10) goto fgets::@3 -- 0_eq_vwum1_then_la1 
    lda size
    ora size+1
    bne !__b3+
    jmp __b3
  !__b3:
    // fgets::@8
    // if (remaining >= 512)
    // [2065] if(fgets::remaining#11>=$200) goto fgets::@4 -- vwum1_ge_vwuc1_then_la1 
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
    // [2066] cx16_k_macptr::bytes = fgets::remaining#11 -- vbum1=vwum2 
    lda remaining
    sta cx16_k_macptr.bytes
    // [2067] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2068] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2069] cx16_k_macptr::return#4 = cx16_k_macptr::return#1
    // fgets::@15
  __b15:
    // bytes = cx16_k_macptr(remaining, ptr)
    // [2070] fgets::bytes#3 = cx16_k_macptr::return#4
    // [2071] phi from fgets::@13 fgets::@14 fgets::@15 to fgets::cbm_k_readst2 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2]
    // [2071] phi fgets::bytes#10 = fgets::bytes#1 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2#0] -- register_copy 
    // fgets::cbm_k_readst2
    // char status
    // [2072] fgets::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [2074] fgets::cbm_k_readst2_return#0 = fgets::cbm_k_readst2_status -- vbum1=vbum2 
    sta cbm_k_readst2_return
    // fgets::cbm_k_readst2_@return
    // }
    // [2075] fgets::cbm_k_readst2_return#1 = fgets::cbm_k_readst2_return#0
    // fgets::@12
    // cbm_k_readst()
    // [2076] fgets::$8 = fgets::cbm_k_readst2_return#1 -- vbuz1=vbum2 
    sta.z fgets__8
    // __status = cbm_k_readst()
    // [2077] ((char *)&__stdio_file+$8c)[fgets::sp#0] = fgets::$8 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$8c,y
    // __status & 0xBF
    // [2078] fgets::$9 = ((char *)&__stdio_file+$8c)[fgets::sp#0] & $bf -- vbuz1=pbuc1_derefidx_vbum2_band_vbuc2 
    lda #$bf
    and __stdio_file+$8c,y
    sta.z fgets__9
    // if (__status & 0xBF)
    // [2079] if(0==fgets::$9) goto fgets::@5 -- 0_eq_vbuz1_then_la1 
    beq __b5
    jmp __b8
    // fgets::@5
  __b5:
    // if (bytes == 0xFFFF)
    // [2080] if(fgets::bytes#10!=$ffff) goto fgets::@6 -- vwum1_neq_vwuc1_then_la1 
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
    // [2081] fgets::read#1 = fgets::read#10 + fgets::bytes#10 -- vwum1=vwum1_plus_vwum2 
    clc
    lda read
    adc bytes
    sta read
    lda read+1
    adc bytes+1
    sta read+1
    // ptr += bytes
    // [2082] fgets::ptr#0 = fgets::ptr#10 + fgets::bytes#10 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z ptr
    adc bytes
    sta.z ptr
    lda.z ptr+1
    adc bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [2083] fgets::$13 = byte1  fgets::ptr#0 -- vbuz1=_byte1_pbuz2 
    sta.z fgets__13
    // if (BYTE1(ptr) == 0xC0)
    // [2084] if(fgets::$13!=$c0) goto fgets::@7 -- vbuz1_neq_vbuc1_then_la1 
    lda #$c0
    cmp.z fgets__13
    bne __b7
    // fgets::@10
    // ptr -= 0x2000
    // [2085] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [2086] phi from fgets::@10 fgets::@6 to fgets::@7 [phi:fgets::@10/fgets::@6->fgets::@7]
    // [2086] phi fgets::ptr#13 = fgets::ptr#1 [phi:fgets::@10/fgets::@6->fgets::@7#0] -- register_copy 
    // fgets::@7
  __b7:
    // remaining -= bytes
    // [2087] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#10 -- vwum1=vwum1_minus_vwum2 
    lda remaining
    sec
    sbc bytes
    sta remaining
    lda remaining+1
    sbc bytes+1
    sta remaining+1
    // while ((__status == 0) && ((size && remaining) || !size))
    // [2088] if(((char *)&__stdio_file+$8c)[fgets::sp#0]==0) goto fgets::@16 -- pbuc1_derefidx_vbum1_eq_0_then_la1 
    ldy sp
    lda __stdio_file+$8c,y
    cmp #0
    beq __b16
    // [2060] phi from fgets::@17 fgets::@7 to fgets::@return [phi:fgets::@17/fgets::@7->fgets::@return]
    // [2060] phi fgets::return#1 = fgets::read#1 [phi:fgets::@17/fgets::@7->fgets::@return#0] -- register_copy 
    rts
    // fgets::@16
  __b16:
    // while ((__status == 0) && ((size && remaining) || !size))
    // [2089] if(0==fgets::size#10) goto fgets::@17 -- 0_eq_vwum1_then_la1 
    lda size
    ora size+1
    beq __b17
    // fgets::@18
    // [2090] if(0!=fgets::remaining#1) goto fgets::@2 -- 0_neq_vwum1_then_la1 
    lda remaining
    ora remaining+1
    beq !__b2+
    jmp __b2
  !__b2:
    // fgets::@17
  __b17:
    // [2091] if(0==fgets::size#10) goto fgets::@2 -- 0_eq_vwum1_then_la1 
    lda size
    ora size+1
    bne !__b2+
    jmp __b2
  !__b2:
    rts
    // fgets::@4
  __b4:
    // cx16_k_macptr(512, ptr)
    // [2092] cx16_k_macptr::bytes = $200 -- vbum1=vwuc1 
    lda #<$200
    sta cx16_k_macptr.bytes
    // [2093] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2094] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2095] cx16_k_macptr::return#3 = cx16_k_macptr::return#1
    // fgets::@14
    // bytes = cx16_k_macptr(512, ptr)
    // [2096] fgets::bytes#2 = cx16_k_macptr::return#3
    jmp __b15
    // fgets::@3
  __b3:
    // cx16_k_macptr(0, ptr)
    // [2097] cx16_k_macptr::bytes = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_macptr.bytes
    // [2098] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2099] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2100] cx16_k_macptr::return#2 = cx16_k_macptr::return#1
    // fgets::@13
    // bytes = cx16_k_macptr(0, ptr)
    // [2101] fgets::bytes#1 = cx16_k_macptr::return#2
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
// int fclose(__zp($46) struct $2 *stream)
fclose: {
    .label fclose__1 = $63
    .label fclose__4 = $2b
    .label fclose__6 = $3a
    .label stream = $46
    // unsigned char sp = (unsigned char)stream
    // [2103] fclose::sp#0 = (char)fclose::stream#2 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_chkin(__logical)
    // [2104] fclose::cbm_k_chkin1_channel = ((char *)&__stdio_file+$80)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    tay
    lda __stdio_file+$80,y
    sta cbm_k_chkin1_channel
    // fclose::cbm_k_chkin1
    // char status
    // [2105] fclose::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fclose::cbm_k_readst1
    // char status
    // [2107] fclose::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2109] fclose::cbm_k_readst1_return#0 = fclose::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // fclose::cbm_k_readst1_@return
    // }
    // [2110] fclose::cbm_k_readst1_return#1 = fclose::cbm_k_readst1_return#0
    // fclose::@3
    // cbm_k_readst()
    // [2111] fclose::$1 = fclose::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z fclose__1
    // __status = cbm_k_readst()
    // [2112] ((char *)&__stdio_file+$8c)[fclose::sp#0] = fclose::$1 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$8c,y
    // if (__status)
    // [2113] if(0==((char *)&__stdio_file+$8c)[fclose::sp#0]) goto fclose::@1 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$8c,y
    cmp #0
    beq __b1
    // fclose::@return
    // }
    // [2114] return 
    rts
    // fclose::@1
  __b1:
    // cbm_k_close(__logical)
    // [2115] fclose::cbm_k_close1_channel = ((char *)&__stdio_file+$80)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$80,y
    sta cbm_k_close1_channel
    // fclose::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // fclose::cbm_k_readst2
    // char status
    // [2117] fclose::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [2119] fclose::cbm_k_readst2_return#0 = fclose::cbm_k_readst2_status -- vbum1=vbum2 
    sta cbm_k_readst2_return
    // fclose::cbm_k_readst2_@return
    // }
    // [2120] fclose::cbm_k_readst2_return#1 = fclose::cbm_k_readst2_return#0
    // fclose::@4
    // cbm_k_readst()
    // [2121] fclose::$4 = fclose::cbm_k_readst2_return#1 -- vbuz1=vbum2 
    sta.z fclose__4
    // __status = cbm_k_readst()
    // [2122] ((char *)&__stdio_file+$8c)[fclose::sp#0] = fclose::$4 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$8c,y
    // if (__status)
    // [2123] if(0==((char *)&__stdio_file+$8c)[fclose::sp#0]) goto fclose::@2 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$8c,y
    cmp #0
    beq __b2
    rts
    // fclose::@2
  __b2:
    // __logical = 0
    // [2124] ((char *)&__stdio_file+$80)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy sp
    sta __stdio_file+$80,y
    // __device = 0
    // [2125] ((char *)&__stdio_file+$84)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$84,y
    // __channel = 0
    // [2126] ((char *)&__stdio_file+$88)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$88,y
    // __filename
    // [2127] fclose::$6 = fclose::sp#0 << 2 -- vbuz1=vbum2_rol_2 
    tya
    asl
    asl
    sta.z fclose__6
    // *__filename = '\0'
    // [2128] ((char *)&__stdio_file)[fclose::$6] = '@' -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #'@'
    ldy.z fclose__6
    sta __stdio_file,y
    // __stdio_filecount--;
    // [2129] __stdio_filecount = -- __stdio_filecount -- vbum1=_dec_vbum1 
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
// void uctoa(__mem() char value, __zp($46) char *buffer, __mem() char radix)
uctoa: {
    .label uctoa__4 = $2b
    .label buffer = $46
    .label digit_values = $5d
    // if(radix==DECIMAL)
    // [2130] if(uctoa::radix#0==DECIMAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // uctoa::@2
    // if(radix==HEXADECIMAL)
    // [2131] if(uctoa::radix#0==HEXADECIMAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // uctoa::@3
    // if(radix==OCTAL)
    // [2132] if(uctoa::radix#0==OCTAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // uctoa::@4
    // if(radix==BINARY)
    // [2133] if(uctoa::radix#0==BINARY) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // uctoa::@5
    // *buffer++ = 'e'
    // [2134] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2135] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2136] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2137] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // uctoa::@return
    // }
    // [2138] return 
    rts
    // [2139] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
  __b2:
    // [2139] phi uctoa::digit_values#8 = RADIX_DECIMAL_VALUES_CHAR [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [2139] phi uctoa::max_digits#7 = 3 [phi:uctoa->uctoa::@1#1] -- vbum1=vbuc1 
    lda #3
    sta max_digits
    jmp __b1
    // [2139] phi from uctoa::@2 to uctoa::@1 [phi:uctoa::@2->uctoa::@1]
  __b3:
    // [2139] phi uctoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_CHAR [phi:uctoa::@2->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [2139] phi uctoa::max_digits#7 = 2 [phi:uctoa::@2->uctoa::@1#1] -- vbum1=vbuc1 
    lda #2
    sta max_digits
    jmp __b1
    // [2139] phi from uctoa::@3 to uctoa::@1 [phi:uctoa::@3->uctoa::@1]
  __b4:
    // [2139] phi uctoa::digit_values#8 = RADIX_OCTAL_VALUES_CHAR [phi:uctoa::@3->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values+1
    // [2139] phi uctoa::max_digits#7 = 3 [phi:uctoa::@3->uctoa::@1#1] -- vbum1=vbuc1 
    lda #3
    sta max_digits
    jmp __b1
    // [2139] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
  __b5:
    // [2139] phi uctoa::digit_values#8 = RADIX_BINARY_VALUES_CHAR [phi:uctoa::@4->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_BINARY_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_CHAR
    sta.z digit_values+1
    // [2139] phi uctoa::max_digits#7 = 8 [phi:uctoa::@4->uctoa::@1#1] -- vbum1=vbuc1 
    lda #8
    sta max_digits
    // uctoa::@1
  __b1:
    // [2140] phi from uctoa::@1 to uctoa::@6 [phi:uctoa::@1->uctoa::@6]
    // [2140] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa::@1->uctoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2140] phi uctoa::started#2 = 0 [phi:uctoa::@1->uctoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [2140] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa::@1->uctoa::@6#2] -- register_copy 
    // [2140] phi uctoa::digit#2 = 0 [phi:uctoa::@1->uctoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // uctoa::@6
  __b6:
    // max_digits-1
    // [2141] uctoa::$4 = uctoa::max_digits#7 - 1 -- vbuz1=vbum2_minus_1 
    ldx max_digits
    dex
    stx.z uctoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2142] if(uctoa::digit#2<uctoa::$4) goto uctoa::@7 -- vbum1_lt_vbuz2_then_la1 
    lda digit
    cmp.z uctoa__4
    bcc __b7
    // uctoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2143] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy value
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2144] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2145] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // uctoa::@7
  __b7:
    // unsigned char digit_value = digit_values[digit]
    // [2146] uctoa::digit_value#0 = uctoa::digit_values#8[uctoa::digit#2] -- vbum1=pbuz2_derefidx_vbum3 
    ldy digit
    lda (digit_values),y
    sta digit_value
    // if (started || value >= digit_value)
    // [2147] if(0!=uctoa::started#2) goto uctoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // uctoa::@12
    // [2148] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@10 -- vbum1_ge_vbum2_then_la1 
    lda value
    cmp digit_value
    bcs __b10
    // [2149] phi from uctoa::@12 to uctoa::@9 [phi:uctoa::@12->uctoa::@9]
    // [2149] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@12->uctoa::@9#0] -- register_copy 
    // [2149] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@12->uctoa::@9#1] -- register_copy 
    // [2149] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@12->uctoa::@9#2] -- register_copy 
    // uctoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2150] uctoa::digit#1 = ++ uctoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [2140] phi from uctoa::@9 to uctoa::@6 [phi:uctoa::@9->uctoa::@6]
    // [2140] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@9->uctoa::@6#0] -- register_copy 
    // [2140] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@9->uctoa::@6#1] -- register_copy 
    // [2140] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@9->uctoa::@6#2] -- register_copy 
    // [2140] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@9->uctoa::@6#3] -- register_copy 
    jmp __b6
    // uctoa::@10
  __b10:
    // uctoa_append(buffer++, value, digit_value)
    // [2151] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [2152] uctoa_append::value#0 = uctoa::value#2
    // [2153] uctoa_append::sub#0 = uctoa::digit_value#0
    // [2154] call uctoa_append
    // [2504] phi from uctoa::@10 to uctoa_append [phi:uctoa::@10->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [2155] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@11
    // value = uctoa_append(buffer++, value, digit_value)
    // [2156] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [2157] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2149] phi from uctoa::@11 to uctoa::@9 [phi:uctoa::@11->uctoa::@9]
    // [2149] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@11->uctoa::@9#0] -- register_copy 
    // [2149] phi uctoa::started#4 = 1 [phi:uctoa::@11->uctoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [2149] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@11->uctoa::@9#2] -- register_copy 
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
    // [2159] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [2159] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta len
    sta len+1
    // [2159] phi strlen::str#6 = strlen::str#8 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [2160] if(0!=*strlen::str#6) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [2161] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [2162] strlen::len#1 = ++ strlen::len#2 -- vwum1=_inc_vwum1 
    inc len
    bne !+
    inc len+1
  !:
    // str++;
    // [2163] strlen::str#1 = ++ strlen::str#6 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [2159] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [2159] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [2159] phi strlen::str#6 = strlen::str#1 [phi:strlen::@2->strlen::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label return = len
    len: .word 0
}
.segment Code
  // printf_padding
// Print a padding char a number of times
// void printf_padding(__zp($38) void (*putc)(char), __mem() char pad, __mem() char length)
printf_padding: {
    .label putc = $38
    // [2165] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [2165] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbum1=vbuc1 
    lda #0
    sta i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [2166] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbum1_lt_vbum2_then_la1 
    lda i
    cmp length
    bcc __b2
    // printf_padding::@return
    // }
    // [2167] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [2168] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbum1 
    lda pad
    pha
    // [2169] callexecute *printf_padding::putc#7  -- call__deref_pprz1 
    jsr icall35
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [2171] printf_padding::i#1 = ++ printf_padding::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [2165] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [2165] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
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
// __mem() unsigned long rom_address_from_bank(__zp($c6) char rom_bank)
rom_address_from_bank: {
    .label rom_address_from_bank__1 = $7b
    .label rom_bank = $c6
    // ((unsigned long)(rom_bank)) << 14
    // [2173] rom_address_from_bank::$1 = (unsigned long)rom_address_from_bank::rom_bank#3 -- vduz1=_dword_vbuz2 
    lda.z rom_bank
    sta.z rom_address_from_bank__1
    lda #0
    sta.z rom_address_from_bank__1+1
    sta.z rom_address_from_bank__1+2
    sta.z rom_address_from_bank__1+3
    // [2174] rom_address_from_bank::return#0 = rom_address_from_bank::$1 << $e -- vdum1=vduz2_rol_vbuc1 
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
    // [2175] return 
    rts
  .segment Data
    .label return = rom_read.rom_address
    .label return_1 = rom_verify.rom_address
    .label return_2 = rom_flash.rom_address_sector
}
.segment Code
  // rom_compare
// __mem() unsigned int rom_compare(__zp($72) char bank_ram, __zp($56) char *ptr_ram, __zp($50) unsigned long rom_compare_address, __zp($66) unsigned int rom_compare_size)
rom_compare: {
    .label rom_compare__5 = $4d
    .label rom_bank1_rom_compare__0 = $3a
    .label rom_bank1_rom_compare__1 = $2b
    .label rom_bank1_rom_compare__2 = $48
    .label rom_ptr1_rom_compare__0 = $4e
    .label rom_ptr1_rom_compare__2 = $4e
    .label rom_ptr1_return = $4e
    .label ptr_rom = $4e
    .label ptr_ram = $56
    .label bank_ram = $72
    .label rom_compare_address = $50
    .label bank_ram_1 = $7f
    .label bank_ram_2 = $78
    .label rom_compare_size = $66
    // rom_compare::bank_set_bram1
    // BRAM = bank
    // [2177] BRAM = rom_compare::bank_set_bram1_bank#0 -- vbuz1=vbum2 
    lda bank_set_bram1_bank
    sta.z BRAM
    // rom_compare::rom_bank1
    // BYTE2(address)
    // [2178] rom_compare::rom_bank1_$0 = byte2  rom_compare::rom_compare_address#3 -- vbuz1=_byte2_vduz2 
    lda.z rom_compare_address+2
    sta.z rom_bank1_rom_compare__0
    // BYTE1(address)
    // [2179] rom_compare::rom_bank1_$1 = byte1  rom_compare::rom_compare_address#3 -- vbuz1=_byte1_vduz2 
    lda.z rom_compare_address+1
    sta.z rom_bank1_rom_compare__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2180] rom_compare::rom_bank1_$2 = rom_compare::rom_bank1_$0 w= rom_compare::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_compare__0
    sta.z rom_bank1_rom_compare__2+1
    lda.z rom_bank1_rom_compare__1
    sta.z rom_bank1_rom_compare__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2181] rom_compare::rom_bank1_bank_unshifted#0 = rom_compare::rom_bank1_$2 << 2 -- vwum1=vwuz2_rol_2 
    asl
    sta rom_bank1_bank_unshifted
    lda.z rom_bank1_rom_compare__2+1
    rol
    sta rom_bank1_bank_unshifted+1
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2182] rom_compare::rom_bank1_return#0 = byte1  rom_compare::rom_bank1_bank_unshifted#0 -- vbum1=_byte1_vwum2 
    lda rom_bank1_bank_unshifted+1
    sta rom_bank1_return
    // rom_compare::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2183] rom_compare::rom_ptr1_$2 = (unsigned int)rom_compare::rom_compare_address#3 -- vwuz1=_word_vduz2 
    lda.z rom_compare_address
    sta.z rom_ptr1_rom_compare__2
    lda.z rom_compare_address+1
    sta.z rom_ptr1_rom_compare__2+1
    // [2184] rom_compare::rom_ptr1_$0 = rom_compare::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_compare__0
    and #<$3fff
    sta.z rom_ptr1_rom_compare__0
    lda.z rom_ptr1_rom_compare__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_compare__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2185] rom_compare::rom_ptr1_return#0 = rom_compare::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_compare::bank_set_brom1
    // BROM = bank
    // [2186] BROM = rom_compare::rom_bank1_return#0 -- vbuz1=vbum2 
    lda rom_bank1_return
    sta.z BROM
    // [2187] rom_compare::ptr_rom#9 = (char *)rom_compare::rom_ptr1_return#0
    // [2188] phi from rom_compare::bank_set_brom1 to rom_compare::@1 [phi:rom_compare::bank_set_brom1->rom_compare::@1]
    // [2188] phi rom_compare::equal_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta equal_bytes
    sta equal_bytes+1
    // [2188] phi rom_compare::ptr_ram#4 = rom_compare::ptr_ram#10 [phi:rom_compare::bank_set_brom1->rom_compare::@1#1] -- register_copy 
    // [2188] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#9 [phi:rom_compare::bank_set_brom1->rom_compare::@1#2] -- register_copy 
    // [2188] phi rom_compare::compared_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#3] -- vwum1=vwuc1 
    sta compared_bytes
    sta compared_bytes+1
    // rom_compare::@1
  __b1:
    // while (compared_bytes < rom_compare_size)
    // [2189] if(rom_compare::compared_bytes#2<rom_compare::rom_compare_size#11) goto rom_compare::@2 -- vwum1_lt_vwuz2_then_la1 
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
    // [2190] return 
    rts
    // rom_compare::@2
  __b2:
    // rom_byte_compare(ptr_rom, *ptr_ram)
    // [2191] rom_byte_compare::ptr_rom#0 = rom_compare::ptr_rom#2
    // [2192] rom_byte_compare::value#0 = *rom_compare::ptr_ram#4 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (ptr_ram),y
    sta.z rom_byte_compare.value
    // [2193] call rom_byte_compare
    jsr rom_byte_compare
    // [2194] rom_byte_compare::return#2 = rom_byte_compare::return#0
    // rom_compare::@5
    // [2195] rom_compare::$5 = rom_byte_compare::return#2 -- vbuz1=vbum2 
    lda rom_byte_compare.return
    sta.z rom_compare__5
    // if (rom_byte_compare(ptr_rom, *ptr_ram))
    // [2196] if(0==rom_compare::$5) goto rom_compare::@3 -- 0_eq_vbuz1_then_la1 
    beq __b3
    // rom_compare::@4
    // equal_bytes++;
    // [2197] rom_compare::equal_bytes#1 = ++ rom_compare::equal_bytes#2 -- vwum1=_inc_vwum1 
    inc equal_bytes
    bne !+
    inc equal_bytes+1
  !:
    // [2198] phi from rom_compare::@4 rom_compare::@5 to rom_compare::@3 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3]
    // [2198] phi rom_compare::equal_bytes#6 = rom_compare::equal_bytes#1 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3#0] -- register_copy 
    // rom_compare::@3
  __b3:
    // ptr_rom++;
    // [2199] rom_compare::ptr_rom#1 = ++ rom_compare::ptr_rom#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr_rom
    bne !+
    inc.z ptr_rom+1
  !:
    // ptr_ram++;
    // [2200] rom_compare::ptr_ram#0 = ++ rom_compare::ptr_ram#4 -- pbuz1=_inc_pbuz1 
    inc.z ptr_ram
    bne !+
    inc.z ptr_ram+1
  !:
    // compared_bytes++;
    // [2201] rom_compare::compared_bytes#1 = ++ rom_compare::compared_bytes#2 -- vwum1=_inc_vwum1 
    inc compared_bytes
    bne !+
    inc compared_bytes+1
  !:
    // [2188] phi from rom_compare::@3 to rom_compare::@1 [phi:rom_compare::@3->rom_compare::@1]
    // [2188] phi rom_compare::equal_bytes#2 = rom_compare::equal_bytes#6 [phi:rom_compare::@3->rom_compare::@1#0] -- register_copy 
    // [2188] phi rom_compare::ptr_ram#4 = rom_compare::ptr_ram#0 [phi:rom_compare::@3->rom_compare::@1#1] -- register_copy 
    // [2188] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#1 [phi:rom_compare::@3->rom_compare::@1#2] -- register_copy 
    // [2188] phi rom_compare::compared_bytes#2 = rom_compare::compared_bytes#1 [phi:rom_compare::@3->rom_compare::@1#3] -- register_copy 
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
// void ultoa(__mem() unsigned long value, __zp($44) char *buffer, __mem() char radix)
ultoa: {
    .label ultoa__4 = $2b
    .label ultoa__10 = $3a
    .label ultoa__11 = $4d
    .label buffer = $44
    .label digit_values = $56
    // if(radix==DECIMAL)
    // [2202] if(ultoa::radix#0==DECIMAL) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // ultoa::@2
    // if(radix==HEXADECIMAL)
    // [2203] if(ultoa::radix#0==HEXADECIMAL) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // ultoa::@3
    // if(radix==OCTAL)
    // [2204] if(ultoa::radix#0==OCTAL) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // ultoa::@4
    // if(radix==BINARY)
    // [2205] if(ultoa::radix#0==BINARY) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // ultoa::@5
    // *buffer++ = 'e'
    // [2206] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2207] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2208] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2209] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // ultoa::@return
    // }
    // [2210] return 
    rts
    // [2211] phi from ultoa to ultoa::@1 [phi:ultoa->ultoa::@1]
  __b2:
    // [2211] phi ultoa::digit_values#8 = RADIX_DECIMAL_VALUES_LONG [phi:ultoa->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2211] phi ultoa::max_digits#7 = $a [phi:ultoa->ultoa::@1#1] -- vbum1=vbuc1 
    lda #$a
    sta max_digits
    jmp __b1
    // [2211] phi from ultoa::@2 to ultoa::@1 [phi:ultoa::@2->ultoa::@1]
  __b3:
    // [2211] phi ultoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_LONG [phi:ultoa::@2->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2211] phi ultoa::max_digits#7 = 8 [phi:ultoa::@2->ultoa::@1#1] -- vbum1=vbuc1 
    lda #8
    sta max_digits
    jmp __b1
    // [2211] phi from ultoa::@3 to ultoa::@1 [phi:ultoa::@3->ultoa::@1]
  __b4:
    // [2211] phi ultoa::digit_values#8 = RADIX_OCTAL_VALUES_LONG [phi:ultoa::@3->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_OCTAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_LONG
    sta.z digit_values+1
    // [2211] phi ultoa::max_digits#7 = $b [phi:ultoa::@3->ultoa::@1#1] -- vbum1=vbuc1 
    lda #$b
    sta max_digits
    jmp __b1
    // [2211] phi from ultoa::@4 to ultoa::@1 [phi:ultoa::@4->ultoa::@1]
  __b5:
    // [2211] phi ultoa::digit_values#8 = RADIX_BINARY_VALUES_LONG [phi:ultoa::@4->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_BINARY_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_LONG
    sta.z digit_values+1
    // [2211] phi ultoa::max_digits#7 = $20 [phi:ultoa::@4->ultoa::@1#1] -- vbum1=vbuc1 
    lda #$20
    sta max_digits
    // ultoa::@1
  __b1:
    // [2212] phi from ultoa::@1 to ultoa::@6 [phi:ultoa::@1->ultoa::@6]
    // [2212] phi ultoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:ultoa::@1->ultoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2212] phi ultoa::started#2 = 0 [phi:ultoa::@1->ultoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [2212] phi ultoa::value#2 = ultoa::value#1 [phi:ultoa::@1->ultoa::@6#2] -- register_copy 
    // [2212] phi ultoa::digit#2 = 0 [phi:ultoa::@1->ultoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // ultoa::@6
  __b6:
    // max_digits-1
    // [2213] ultoa::$4 = ultoa::max_digits#7 - 1 -- vbuz1=vbum2_minus_1 
    ldx max_digits
    dex
    stx.z ultoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2214] if(ultoa::digit#2<ultoa::$4) goto ultoa::@7 -- vbum1_lt_vbuz2_then_la1 
    lda digit
    cmp.z ultoa__4
    bcc __b7
    // ultoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2215] ultoa::$11 = (char)ultoa::value#2 -- vbuz1=_byte_vdum2 
    lda value
    sta.z ultoa__11
    // [2216] *ultoa::buffer#11 = DIGITS[ultoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2217] ultoa::buffer#3 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2218] *ultoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // ultoa::@7
  __b7:
    // unsigned long digit_value = digit_values[digit]
    // [2219] ultoa::$10 = ultoa::digit#2 << 2 -- vbuz1=vbum2_rol_2 
    lda digit
    asl
    asl
    sta.z ultoa__10
    // [2220] ultoa::digit_value#0 = ultoa::digit_values#8[ultoa::$10] -- vdum1=pduz2_derefidx_vbuz3 
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
    // [2221] if(0!=ultoa::started#2) goto ultoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // ultoa::@12
    // [2222] if(ultoa::value#2>=ultoa::digit_value#0) goto ultoa::@10 -- vdum1_ge_vdum2_then_la1 
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
    // [2223] phi from ultoa::@12 to ultoa::@9 [phi:ultoa::@12->ultoa::@9]
    // [2223] phi ultoa::buffer#14 = ultoa::buffer#11 [phi:ultoa::@12->ultoa::@9#0] -- register_copy 
    // [2223] phi ultoa::started#4 = ultoa::started#2 [phi:ultoa::@12->ultoa::@9#1] -- register_copy 
    // [2223] phi ultoa::value#6 = ultoa::value#2 [phi:ultoa::@12->ultoa::@9#2] -- register_copy 
    // ultoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2224] ultoa::digit#1 = ++ ultoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [2212] phi from ultoa::@9 to ultoa::@6 [phi:ultoa::@9->ultoa::@6]
    // [2212] phi ultoa::buffer#11 = ultoa::buffer#14 [phi:ultoa::@9->ultoa::@6#0] -- register_copy 
    // [2212] phi ultoa::started#2 = ultoa::started#4 [phi:ultoa::@9->ultoa::@6#1] -- register_copy 
    // [2212] phi ultoa::value#2 = ultoa::value#6 [phi:ultoa::@9->ultoa::@6#2] -- register_copy 
    // [2212] phi ultoa::digit#2 = ultoa::digit#1 [phi:ultoa::@9->ultoa::@6#3] -- register_copy 
    jmp __b6
    // ultoa::@10
  __b10:
    // ultoa_append(buffer++, value, digit_value)
    // [2225] ultoa_append::buffer#0 = ultoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z ultoa_append.buffer
    lda.z buffer+1
    sta.z ultoa_append.buffer+1
    // [2226] ultoa_append::value#0 = ultoa::value#2
    // [2227] ultoa_append::sub#0 = ultoa::digit_value#0
    // [2228] call ultoa_append
    // [2515] phi from ultoa::@10 to ultoa_append [phi:ultoa::@10->ultoa_append]
    jsr ultoa_append
    // ultoa_append(buffer++, value, digit_value)
    // [2229] ultoa_append::return#0 = ultoa_append::value#2
    // ultoa::@11
    // value = ultoa_append(buffer++, value, digit_value)
    // [2230] ultoa::value#0 = ultoa_append::return#0
    // value = ultoa_append(buffer++, value, digit_value);
    // [2231] ultoa::buffer#4 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2223] phi from ultoa::@11 to ultoa::@9 [phi:ultoa::@11->ultoa::@9]
    // [2223] phi ultoa::buffer#14 = ultoa::buffer#4 [phi:ultoa::@11->ultoa::@9#0] -- register_copy 
    // [2223] phi ultoa::started#4 = 1 [phi:ultoa::@11->ultoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [2223] phi ultoa::value#6 = ultoa::value#0 [phi:ultoa::@11->ultoa::@9#2] -- register_copy 
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
// void rom_sector_erase(__zp($7b) unsigned long address)
rom_sector_erase: {
    .label rom_ptr1_rom_sector_erase__0 = $2d
    .label rom_ptr1_rom_sector_erase__2 = $2d
    .label rom_ptr1_return = $2d
    .label address = $7b
    // rom_sector_erase::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2233] rom_sector_erase::rom_ptr1_$2 = (unsigned int)rom_sector_erase::address#0 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_sector_erase__2
    lda.z address+1
    sta.z rom_ptr1_rom_sector_erase__2+1
    // [2234] rom_sector_erase::rom_ptr1_$0 = rom_sector_erase::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_sector_erase__0
    and #<$3fff
    sta.z rom_ptr1_rom_sector_erase__0
    lda.z rom_ptr1_rom_sector_erase__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_sector_erase__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2235] rom_sector_erase::rom_ptr1_return#0 = rom_sector_erase::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_sector_erase::@1
    // unsigned long rom_chip_address = address & ROM_CHIP_MASK
    // [2236] rom_sector_erase::rom_chip_address#0 = rom_sector_erase::address#0 & $380000 -- vdum1=vduz2_band_vduc1 
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
    // [2237] rom_unlock::address#0 = rom_sector_erase::rom_chip_address#0 + $5555 -- vduz1=vdum2_plus_vwuc1 
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
    // [2238] call rom_unlock
    // [1905] phi from rom_sector_erase::@1 to rom_unlock [phi:rom_sector_erase::@1->rom_unlock]
    // [1905] phi rom_unlock::unlock_code#5 = $80 [phi:rom_sector_erase::@1->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$80
    sta.z rom_unlock.unlock_code
    // [1905] phi rom_unlock::address#5 = rom_unlock::address#0 [phi:rom_sector_erase::@1->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@2
    // rom_unlock(address, 0x30)
    // [2239] rom_unlock::address#1 = rom_sector_erase::address#0 -- vduz1=vduz2 
    lda.z address
    sta.z rom_unlock.address
    lda.z address+1
    sta.z rom_unlock.address+1
    lda.z address+2
    sta.z rom_unlock.address+2
    lda.z address+3
    sta.z rom_unlock.address+3
    // [2240] call rom_unlock
    // [1905] phi from rom_sector_erase::@2 to rom_unlock [phi:rom_sector_erase::@2->rom_unlock]
    // [1905] phi rom_unlock::unlock_code#5 = $30 [phi:rom_sector_erase::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$30
    sta.z rom_unlock.unlock_code
    // [1905] phi rom_unlock::address#5 = rom_unlock::address#1 [phi:rom_sector_erase::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@3
    // rom_wait(ptr_rom)
    // [2241] rom_wait::ptr_rom#0 = (char *)rom_sector_erase::rom_ptr1_return#0
    // [2242] call rom_wait
    // [2522] phi from rom_sector_erase::@3 to rom_wait [phi:rom_sector_erase::@3->rom_wait]
    // [2522] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#0 [phi:rom_sector_erase::@3->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_sector_erase::@return
    // }
    // [2243] return 
    rts
  .segment Data
    rom_chip_address: .dword 0
}
.segment Code
  // rom_write
/* inline */
// unsigned long rom_write(__zp($4d) char flash_ram_bank, __zp($44) char *flash_ram_address, __zp($59) unsigned long flash_rom_address, unsigned int flash_rom_size)
rom_write: {
    .label flash_rom_address = $59
    .label flash_ram_address = $44
    .label flash_ram_bank = $4d
    // unsigned long rom_chip_address = flash_rom_address & ROM_CHIP_MASK
    // [2244] rom_write::rom_chip_address#0 = rom_write::flash_rom_address#1 & $380000 -- vdum1=vduz2_band_vduc1 
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
    // [2245] BRAM = rom_write::flash_ram_bank#0 -- vbuz1=vbuz2 
    lda.z flash_ram_bank
    sta.z BRAM
    // [2246] phi from rom_write::bank_set_bram1 to rom_write::@1 [phi:rom_write::bank_set_bram1->rom_write::@1]
    // [2246] phi rom_write::flash_ram_address#2 = rom_write::flash_ram_address#1 [phi:rom_write::bank_set_bram1->rom_write::@1#0] -- register_copy 
    // [2246] phi rom_write::flash_rom_address#3 = rom_write::flash_rom_address#1 [phi:rom_write::bank_set_bram1->rom_write::@1#1] -- register_copy 
    // [2246] phi rom_write::flashed_bytes#2 = 0 [phi:rom_write::bank_set_bram1->rom_write::@1#2] -- vdum1=vduc1 
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
    // [2247] if(rom_write::flashed_bytes#2<PROGRESS_CELL) goto rom_write::@2 -- vdum1_lt_vduc1_then_la1 
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
    // [2248] return 
    rts
    // rom_write::@2
  __b2:
    // rom_unlock(rom_chip_address + 0x05555, 0xA0)
    // [2249] rom_unlock::address#4 = rom_write::rom_chip_address#0 + $5555 -- vduz1=vdum2_plus_vwuc1 
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
    // [1905] phi from rom_write::@2 to rom_unlock [phi:rom_write::@2->rom_unlock]
    // [1905] phi rom_unlock::unlock_code#5 = $a0 [phi:rom_write::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$a0
    sta.z rom_unlock.unlock_code
    // [1905] phi rom_unlock::address#5 = rom_unlock::address#4 [phi:rom_write::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_write::@3
    // rom_byte_program(flash_rom_address, *flash_ram_address)
    // [2251] rom_byte_program::address#0 = rom_write::flash_rom_address#3 -- vduz1=vduz2 
    lda.z flash_rom_address
    sta.z rom_byte_program.address
    lda.z flash_rom_address+1
    sta.z rom_byte_program.address+1
    lda.z flash_rom_address+2
    sta.z rom_byte_program.address+2
    lda.z flash_rom_address+3
    sta.z rom_byte_program.address+3
    // [2252] rom_byte_program::value#0 = *rom_write::flash_ram_address#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (flash_ram_address),y
    sta.z rom_byte_program.value
    // [2253] call rom_byte_program
    // [2529] phi from rom_write::@3 to rom_byte_program [phi:rom_write::@3->rom_byte_program]
    jsr rom_byte_program
    // rom_write::@4
    // flash_rom_address++;
    // [2254] rom_write::flash_rom_address#0 = ++ rom_write::flash_rom_address#3 -- vduz1=_inc_vduz1 
    inc.z flash_rom_address
    bne !+
    inc.z flash_rom_address+1
    bne !+
    inc.z flash_rom_address+2
    bne !+
    inc.z flash_rom_address+3
  !:
    // flash_ram_address++;
    // [2255] rom_write::flash_ram_address#0 = ++ rom_write::flash_ram_address#2 -- pbuz1=_inc_pbuz1 
    inc.z flash_ram_address
    bne !+
    inc.z flash_ram_address+1
  !:
    // flashed_bytes++;
    // [2256] rom_write::flashed_bytes#1 = ++ rom_write::flashed_bytes#2 -- vdum1=_inc_vdum1 
    inc flashed_bytes
    bne !+
    inc flashed_bytes+1
    bne !+
    inc flashed_bytes+2
    bne !+
    inc flashed_bytes+3
  !:
    // [2246] phi from rom_write::@4 to rom_write::@1 [phi:rom_write::@4->rom_write::@1]
    // [2246] phi rom_write::flash_ram_address#2 = rom_write::flash_ram_address#0 [phi:rom_write::@4->rom_write::@1#0] -- register_copy 
    // [2246] phi rom_write::flash_rom_address#3 = rom_write::flash_rom_address#0 [phi:rom_write::@4->rom_write::@1#1] -- register_copy 
    // [2246] phi rom_write::flashed_bytes#2 = rom_write::flashed_bytes#1 [phi:rom_write::@4->rom_write::@1#2] -- register_copy 
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
    // [2257] insertup::$0 = *((char *)&__conio+6) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+6
    inc
    sta.z insertup__0
    // unsigned char width = (__conio.width+1) * 2
    // [2258] insertup::width#0 = insertup::$0 << 1 -- vbum1=vbuz2_rol_1 
    // {asm{.byte $db}}
    asl
    sta width
    // [2259] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [2259] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbum1=vbuc1 
    lda #0
    sta y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [2260] if(insertup::y#2<*((char *)&__conio+1)) goto insertup::@2 -- vbum1_lt__deref_pbuc1_then_la1 
    lda y
    cmp __conio+1
    bcc __b2
    // [2261] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [2262] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [2263] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [2264] insertup::$4 = insertup::y#2 + 1 -- vbuz1=vbum2_plus_1 
    lda y
    inc
    sta.z insertup__4
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [2265] insertup::$6 = insertup::y#2 << 1 -- vbuz1=vbum2_rol_1 
    lda y
    asl
    sta.z insertup__6
    // [2266] insertup::$7 = insertup::$4 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z insertup__7
    // [2267] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+5) -- vbum1=_deref_pbuc1 
    lda __conio+5
    sta memcpy8_vram_vram.dbank_vram
    // [2268] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwum1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__6
    lda __conio+$15,y
    sta memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta memcpy8_vram_vram.doffset_vram+1
    // [2269] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+5) -- vbum1=_deref_pbuc1 
    lda __conio+5
    sta memcpy8_vram_vram.sbank_vram
    // [2270] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwum1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__7
    lda __conio+$15,y
    sta memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,y
    sta memcpy8_vram_vram.soffset_vram+1
    // [2271] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbum1=vbum2 
    lda width
    sta memcpy8_vram_vram.num8_1
    // [2272] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [2273] insertup::y#1 = ++ insertup::y#2 -- vbum1=_inc_vbum1 
    inc y
    // [2259] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [2259] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
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
    // [2274] clearline::$3 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z clearline__3
    // [2275] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwum1=pwuc1_derefidx_vbuz2 
    tay
    lda __conio+$15,y
    sta addr
    lda __conio+$15+1,y
    sta addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2276] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [2277] clearline::$0 = byte0  clearline::addr#0 -- vbuz1=_byte0_vwum2 
    lda addr
    sta.z clearline__0
    // *VERA_ADDRX_L = BYTE0(addr)
    // [2278] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [2279] clearline::$1 = byte1  clearline::addr#0 -- vbuz1=_byte1_vwum2 
    lda addr+1
    sta.z clearline__1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [2280] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [2281] clearline::$2 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clearline__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [2282] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [2283] clearline::c#0 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z c
    // [2284] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [2284] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [2285] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [2286] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [2287] clearline::c#1 = -- clearline::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [2288] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b1
    // clearline::@return
    // }
    // [2289] return 
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
// __mem() char display_frame_maskxy(__zp($b2) char x, __zp($75) char y)
display_frame_maskxy: {
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__0 = $4d
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__1 = $3a
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__2 = $2b
    .label x = $b2
    .label y = $75
    .label x_1 = $b5
    .label y_1 = $69
    .label x_2 = $79
    .label y_2 = $b1
    .label x_3 = $7a
    .label y_3 = $b3
    .label x_4 = $73
    .label y_4 = $bf
    .label x_5 = $c6
    .label y_5 = $61
    .label x_6 = $cd
    .label y_6 = $68
    .label x_7 = $c5
    .label y_7 = $b4
    // display_frame_maskxy::cpeekcxy1
    // gotoxy(x,y)
    // [2291] gotoxy::x#5 = display_frame_maskxy::cpeekcxy1_x#0 -- vbum1=vbum2 
    lda cpeekcxy1_x
    sta gotoxy.x
    // [2292] gotoxy::y#5 = display_frame_maskxy::cpeekcxy1_y#0 -- vbum1=vbum2 
    lda cpeekcxy1_y
    sta gotoxy.y
    // [2293] call gotoxy
    // [582] phi from display_frame_maskxy::cpeekcxy1 to gotoxy [phi:display_frame_maskxy::cpeekcxy1->gotoxy]
    // [582] phi gotoxy::y#30 = gotoxy::y#5 [phi:display_frame_maskxy::cpeekcxy1->gotoxy#0] -- register_copy 
    // [582] phi gotoxy::x#30 = gotoxy::x#5 [phi:display_frame_maskxy::cpeekcxy1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_frame_maskxy::cpeekcxy1_cpeekc1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2294] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(__conio.offset)
    // [2295] display_frame_maskxy::cpeekcxy1_cpeekc1_$0 = byte0  *((unsigned int *)&__conio+$13) -- vbuz1=_byte0__deref_pwuc1 
    lda __conio+$13
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__0
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [2296] *VERA_ADDRX_L = display_frame_maskxy::cpeekcxy1_cpeekc1_$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [2297] display_frame_maskxy::cpeekcxy1_cpeekc1_$1 = byte1  *((unsigned int *)&__conio+$13) -- vbuz1=_byte1__deref_pwuc1 
    lda __conio+$13+1
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__1
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [2298] *VERA_ADDRX_M = display_frame_maskxy::cpeekcxy1_cpeekc1_$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_0
    // [2299] display_frame_maskxy::cpeekcxy1_cpeekc1_$2 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_0
    // [2300] *VERA_ADDRX_H = display_frame_maskxy::cpeekcxy1_cpeekc1_$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // return *VERA_DATA0;
    // [2301] display_frame_maskxy::c#0 = *VERA_DATA0 -- vbum1=_deref_pbuc1 
    lda VERA_DATA0
    sta c
    // display_frame_maskxy::@12
    // case 0x70: // DR corner.
    //             return 0b0110;
    // [2302] if(display_frame_maskxy::c#0==$70) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$70
    cmp c
    beq __b2
    // display_frame_maskxy::@1
    // case 0x6E: // DL corner.
    //             return 0b0011;
    // [2303] if(display_frame_maskxy::c#0==$6e) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$6e
    cmp c
    beq __b1
    // display_frame_maskxy::@2
    // case 0x6D: // UR corner.
    //             return 0b1100;
    // [2304] if(display_frame_maskxy::c#0==$6d) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$6d
    cmp c
    beq __b3
    // display_frame_maskxy::@3
    // case 0x7D: // UL corner.
    //             return 0b1001;
    // [2305] if(display_frame_maskxy::c#0==$7d) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$7d
    cmp c
    beq __b4
    // display_frame_maskxy::@4
    // case 0x40: // HL line.
    //             return 0b0101;
    // [2306] if(display_frame_maskxy::c#0==$40) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$40
    cmp c
    beq __b5
    // display_frame_maskxy::@5
    // case 0x5D: // VL line.
    //             return 0b1010;
    // [2307] if(display_frame_maskxy::c#0==$5d) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$5d
    cmp c
    beq __b6
    // display_frame_maskxy::@6
    // case 0x6B: // VR junction.
    //             return 0b1110;
    // [2308] if(display_frame_maskxy::c#0==$6b) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$6b
    cmp c
    beq __b7
    // display_frame_maskxy::@7
    // case 0x73: // VL junction.
    //             return 0b1011;
    // [2309] if(display_frame_maskxy::c#0==$73) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$73
    cmp c
    beq __b8
    // display_frame_maskxy::@8
    // case 0x72: // HD junction.
    //             return 0b0111;
    // [2310] if(display_frame_maskxy::c#0==$72) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$72
    cmp c
    beq __b9
    // display_frame_maskxy::@9
    // case 0x71: // HU junction.
    //             return 0b1101;
    // [2311] if(display_frame_maskxy::c#0==$71) goto display_frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$71
    cmp c
    beq __b10
    // display_frame_maskxy::@10
    // case 0x5B: // HV junction.
    //             return 0b1111;
    // [2312] if(display_frame_maskxy::c#0==$5b) goto display_frame_maskxy::@11 -- vbum1_eq_vbuc1_then_la1 
    lda #$5b
    cmp c
    beq __b11
    // [2314] phi from display_frame_maskxy::@10 to display_frame_maskxy::@return [phi:display_frame_maskxy::@10->display_frame_maskxy::@return]
    // [2314] phi display_frame_maskxy::return#12 = 0 [phi:display_frame_maskxy::@10->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    rts
    // [2313] phi from display_frame_maskxy::@10 to display_frame_maskxy::@11 [phi:display_frame_maskxy::@10->display_frame_maskxy::@11]
    // display_frame_maskxy::@11
  __b11:
    // [2314] phi from display_frame_maskxy::@11 to display_frame_maskxy::@return [phi:display_frame_maskxy::@11->display_frame_maskxy::@return]
    // [2314] phi display_frame_maskxy::return#12 = $f [phi:display_frame_maskxy::@11->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$f
    sta return
    rts
    // [2314] phi from display_frame_maskxy::@1 to display_frame_maskxy::@return [phi:display_frame_maskxy::@1->display_frame_maskxy::@return]
  __b1:
    // [2314] phi display_frame_maskxy::return#12 = 3 [phi:display_frame_maskxy::@1->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #3
    sta return
    rts
    // [2314] phi from display_frame_maskxy::@12 to display_frame_maskxy::@return [phi:display_frame_maskxy::@12->display_frame_maskxy::@return]
  __b2:
    // [2314] phi display_frame_maskxy::return#12 = 6 [phi:display_frame_maskxy::@12->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #6
    sta return
    rts
    // [2314] phi from display_frame_maskxy::@2 to display_frame_maskxy::@return [phi:display_frame_maskxy::@2->display_frame_maskxy::@return]
  __b3:
    // [2314] phi display_frame_maskxy::return#12 = $c [phi:display_frame_maskxy::@2->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$c
    sta return
    rts
    // [2314] phi from display_frame_maskxy::@3 to display_frame_maskxy::@return [phi:display_frame_maskxy::@3->display_frame_maskxy::@return]
  __b4:
    // [2314] phi display_frame_maskxy::return#12 = 9 [phi:display_frame_maskxy::@3->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #9
    sta return
    rts
    // [2314] phi from display_frame_maskxy::@4 to display_frame_maskxy::@return [phi:display_frame_maskxy::@4->display_frame_maskxy::@return]
  __b5:
    // [2314] phi display_frame_maskxy::return#12 = 5 [phi:display_frame_maskxy::@4->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #5
    sta return
    rts
    // [2314] phi from display_frame_maskxy::@5 to display_frame_maskxy::@return [phi:display_frame_maskxy::@5->display_frame_maskxy::@return]
  __b6:
    // [2314] phi display_frame_maskxy::return#12 = $a [phi:display_frame_maskxy::@5->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$a
    sta return
    rts
    // [2314] phi from display_frame_maskxy::@6 to display_frame_maskxy::@return [phi:display_frame_maskxy::@6->display_frame_maskxy::@return]
  __b7:
    // [2314] phi display_frame_maskxy::return#12 = $e [phi:display_frame_maskxy::@6->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$e
    sta return
    rts
    // [2314] phi from display_frame_maskxy::@7 to display_frame_maskxy::@return [phi:display_frame_maskxy::@7->display_frame_maskxy::@return]
  __b8:
    // [2314] phi display_frame_maskxy::return#12 = $b [phi:display_frame_maskxy::@7->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$b
    sta return
    rts
    // [2314] phi from display_frame_maskxy::@8 to display_frame_maskxy::@return [phi:display_frame_maskxy::@8->display_frame_maskxy::@return]
  __b9:
    // [2314] phi display_frame_maskxy::return#12 = 7 [phi:display_frame_maskxy::@8->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #7
    sta return
    rts
    // [2314] phi from display_frame_maskxy::@9 to display_frame_maskxy::@return [phi:display_frame_maskxy::@9->display_frame_maskxy::@return]
  __b10:
    // [2314] phi display_frame_maskxy::return#12 = $d [phi:display_frame_maskxy::@9->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$d
    sta return
    // display_frame_maskxy::@return
    // }
    // [2315] return 
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
// __mem() char display_frame_char(__zp($75) char mask)
display_frame_char: {
    .label mask = $75
    // case 0b0110:
    //             return 0x70;
    // [2317] if(display_frame_char::mask#10==6) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #6
    cmp.z mask
    beq __b1
    // display_frame_char::@1
    // case 0b0011:
    //             return 0x6E;
    // [2318] if(display_frame_char::mask#10==3) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // DR corner.
    lda #3
    cmp.z mask
    beq __b2
    // display_frame_char::@2
    // case 0b1100:
    //             return 0x6D;
    // [2319] if(display_frame_char::mask#10==$c) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // DL corner.
    lda #$c
    cmp.z mask
    beq __b3
    // display_frame_char::@3
    // case 0b1001:
    //             return 0x7D;
    // [2320] if(display_frame_char::mask#10==9) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // UR corner.
    lda #9
    cmp.z mask
    beq __b4
    // display_frame_char::@4
    // case 0b0101:
    //             return 0x40;
    // [2321] if(display_frame_char::mask#10==5) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // UL corner.
    lda #5
    cmp.z mask
    beq __b5
    // display_frame_char::@5
    // case 0b1010:
    //             return 0x5D;
    // [2322] if(display_frame_char::mask#10==$a) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // HL line.
    lda #$a
    cmp.z mask
    beq __b6
    // display_frame_char::@6
    // case 0b1110:
    //             return 0x6B;
    // [2323] if(display_frame_char::mask#10==$e) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VL line.
    lda #$e
    cmp.z mask
    beq __b7
    // display_frame_char::@7
    // case 0b1011:
    //             return 0x73;
    // [2324] if(display_frame_char::mask#10==$b) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VR junction.
    lda #$b
    cmp.z mask
    beq __b8
    // display_frame_char::@8
    // case 0b0111:
    //             return 0x72;
    // [2325] if(display_frame_char::mask#10==7) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VL junction.
    lda #7
    cmp.z mask
    beq __b9
    // display_frame_char::@9
    // case 0b1101:
    //             return 0x71;
    // [2326] if(display_frame_char::mask#10==$d) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // HD junction.
    lda #$d
    cmp.z mask
    beq __b10
    // display_frame_char::@10
    // case 0b1111:
    //             return 0x5B;
    // [2327] if(display_frame_char::mask#10==$f) goto display_frame_char::@11 -- vbuz1_eq_vbuc1_then_la1 
    // HU junction.
    lda #$f
    cmp.z mask
    beq __b11
    // [2329] phi from display_frame_char::@10 to display_frame_char::@return [phi:display_frame_char::@10->display_frame_char::@return]
    // [2329] phi display_frame_char::return#12 = $20 [phi:display_frame_char::@10->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$20
    sta return
    rts
    // [2328] phi from display_frame_char::@10 to display_frame_char::@11 [phi:display_frame_char::@10->display_frame_char::@11]
    // display_frame_char::@11
  __b11:
    // [2329] phi from display_frame_char::@11 to display_frame_char::@return [phi:display_frame_char::@11->display_frame_char::@return]
    // [2329] phi display_frame_char::return#12 = $5b [phi:display_frame_char::@11->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$5b
    sta return
    rts
    // [2329] phi from display_frame_char to display_frame_char::@return [phi:display_frame_char->display_frame_char::@return]
  __b1:
    // [2329] phi display_frame_char::return#12 = $70 [phi:display_frame_char->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$70
    sta return
    rts
    // [2329] phi from display_frame_char::@1 to display_frame_char::@return [phi:display_frame_char::@1->display_frame_char::@return]
  __b2:
    // [2329] phi display_frame_char::return#12 = $6e [phi:display_frame_char::@1->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$6e
    sta return
    rts
    // [2329] phi from display_frame_char::@2 to display_frame_char::@return [phi:display_frame_char::@2->display_frame_char::@return]
  __b3:
    // [2329] phi display_frame_char::return#12 = $6d [phi:display_frame_char::@2->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$6d
    sta return
    rts
    // [2329] phi from display_frame_char::@3 to display_frame_char::@return [phi:display_frame_char::@3->display_frame_char::@return]
  __b4:
    // [2329] phi display_frame_char::return#12 = $7d [phi:display_frame_char::@3->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$7d
    sta return
    rts
    // [2329] phi from display_frame_char::@4 to display_frame_char::@return [phi:display_frame_char::@4->display_frame_char::@return]
  __b5:
    // [2329] phi display_frame_char::return#12 = $40 [phi:display_frame_char::@4->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$40
    sta return
    rts
    // [2329] phi from display_frame_char::@5 to display_frame_char::@return [phi:display_frame_char::@5->display_frame_char::@return]
  __b6:
    // [2329] phi display_frame_char::return#12 = $5d [phi:display_frame_char::@5->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$5d
    sta return
    rts
    // [2329] phi from display_frame_char::@6 to display_frame_char::@return [phi:display_frame_char::@6->display_frame_char::@return]
  __b7:
    // [2329] phi display_frame_char::return#12 = $6b [phi:display_frame_char::@6->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$6b
    sta return
    rts
    // [2329] phi from display_frame_char::@7 to display_frame_char::@return [phi:display_frame_char::@7->display_frame_char::@return]
  __b8:
    // [2329] phi display_frame_char::return#12 = $73 [phi:display_frame_char::@7->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$73
    sta return
    rts
    // [2329] phi from display_frame_char::@8 to display_frame_char::@return [phi:display_frame_char::@8->display_frame_char::@return]
  __b9:
    // [2329] phi display_frame_char::return#12 = $72 [phi:display_frame_char::@8->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$72
    sta return
    rts
    // [2329] phi from display_frame_char::@9 to display_frame_char::@return [phi:display_frame_char::@9->display_frame_char::@return]
  __b10:
    // [2329] phi display_frame_char::return#12 = $71 [phi:display_frame_char::@9->display_frame_char::@return#0] -- vbum1=vbuc1 
    lda #$71
    sta return
    // display_frame_char::@return
    // }
    // [2330] return 
    rts
  .segment Data
    .label return = cputcxy.c
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
// void display_chip_led(__zp($69) char x, char y, __zp($68) char w, __zp($73) char tc, char bc)
display_chip_led: {
    .label x = $69
    .label w = $68
    .label tc = $73
    // textcolor(tc)
    // [2332] textcolor::color#11 = display_chip_led::tc#3 -- vbum1=vbuz2 
    lda.z tc
    sta textcolor.color
    // [2333] call textcolor
    // [564] phi from display_chip_led to textcolor [phi:display_chip_led->textcolor]
    // [564] phi textcolor::color#18 = textcolor::color#11 [phi:display_chip_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [2334] phi from display_chip_led to display_chip_led::@3 [phi:display_chip_led->display_chip_led::@3]
    // display_chip_led::@3
    // bgcolor(bc)
    // [2335] call bgcolor
    // [569] phi from display_chip_led::@3 to bgcolor [phi:display_chip_led::@3->bgcolor]
    // [569] phi bgcolor::color#14 = BLUE [phi:display_chip_led::@3->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [2336] phi from display_chip_led::@3 display_chip_led::@5 to display_chip_led::@1 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1]
    // [2336] phi display_chip_led::w#4 = display_chip_led::w#7 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1#0] -- register_copy 
    // [2336] phi display_chip_led::x#4 = display_chip_led::x#7 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1#1] -- register_copy 
    // display_chip_led::@1
  __b1:
    // cputcxy(x, y, 0x6F)
    // [2337] cputcxy::x#9 = display_chip_led::x#4 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [2338] call cputcxy
    // [1771] phi from display_chip_led::@1 to cputcxy [phi:display_chip_led::@1->cputcxy]
    // [1771] phi cputcxy::c#15 = $6f [phi:display_chip_led::@1->cputcxy#0] -- vbum1=vbuc1 
    lda #$6f
    sta cputcxy.c
    // [1771] phi cputcxy::y#15 = 3 [phi:display_chip_led::@1->cputcxy#1] -- vbum1=vbuc1 
    lda #3
    sta cputcxy.y
    // [1771] phi cputcxy::x#15 = cputcxy::x#9 [phi:display_chip_led::@1->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_led::@4
    // cputcxy(x, y+1, 0x77)
    // [2339] cputcxy::x#10 = display_chip_led::x#4 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [2340] call cputcxy
    // [1771] phi from display_chip_led::@4 to cputcxy [phi:display_chip_led::@4->cputcxy]
    // [1771] phi cputcxy::c#15 = $77 [phi:display_chip_led::@4->cputcxy#0] -- vbum1=vbuc1 
    lda #$77
    sta cputcxy.c
    // [1771] phi cputcxy::y#15 = 3+1 [phi:display_chip_led::@4->cputcxy#1] -- vbum1=vbuc1 
    lda #3+1
    sta cputcxy.y
    // [1771] phi cputcxy::x#15 = cputcxy::x#10 [phi:display_chip_led::@4->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_led::@5
    // x++;
    // [2341] display_chip_led::x#0 = ++ display_chip_led::x#4 -- vbuz1=_inc_vbuz1 
    inc.z x
    // while(--w)
    // [2342] display_chip_led::w#0 = -- display_chip_led::w#4 -- vbuz1=_dec_vbuz1 
    dec.z w
    // [2343] if(0!=display_chip_led::w#0) goto display_chip_led::@1 -- 0_neq_vbuz1_then_la1 
    lda.z w
    bne __b1
    // [2344] phi from display_chip_led::@5 to display_chip_led::@2 [phi:display_chip_led::@5->display_chip_led::@2]
    // display_chip_led::@2
    // textcolor(WHITE)
    // [2345] call textcolor
    // [564] phi from display_chip_led::@2 to textcolor [phi:display_chip_led::@2->textcolor]
    // [564] phi textcolor::color#18 = WHITE [phi:display_chip_led::@2->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [2346] phi from display_chip_led::@2 to display_chip_led::@6 [phi:display_chip_led::@2->display_chip_led::@6]
    // display_chip_led::@6
    // bgcolor(BLUE)
    // [2347] call bgcolor
    // [569] phi from display_chip_led::@6 to bgcolor [phi:display_chip_led::@6->bgcolor]
    // [569] phi bgcolor::color#14 = BLUE [phi:display_chip_led::@6->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_led::@return
    // }
    // [2348] return 
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
// void display_chip_line(__zp($b4) char x, __zp($bf) char y, __zp($b1) char w, __zp($b3) char c)
display_chip_line: {
    .label x = $b4
    .label w = $b1
    .label c = $b3
    .label y = $bf
    // gotoxy(x, y)
    // [2350] gotoxy::x#7 = display_chip_line::x#16 -- vbum1=vbuz2 
    lda.z x
    sta gotoxy.x
    // [2351] gotoxy::y#7 = display_chip_line::y#16 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [2352] call gotoxy
    // [582] phi from display_chip_line to gotoxy [phi:display_chip_line->gotoxy]
    // [582] phi gotoxy::y#30 = gotoxy::y#7 [phi:display_chip_line->gotoxy#0] -- register_copy 
    // [582] phi gotoxy::x#30 = gotoxy::x#7 [phi:display_chip_line->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [2353] phi from display_chip_line to display_chip_line::@4 [phi:display_chip_line->display_chip_line::@4]
    // display_chip_line::@4
    // textcolor(GREY)
    // [2354] call textcolor
    // [564] phi from display_chip_line::@4 to textcolor [phi:display_chip_line::@4->textcolor]
    // [564] phi textcolor::color#18 = GREY [phi:display_chip_line::@4->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [2355] phi from display_chip_line::@4 to display_chip_line::@5 [phi:display_chip_line::@4->display_chip_line::@5]
    // display_chip_line::@5
    // bgcolor(BLUE)
    // [2356] call bgcolor
    // [569] phi from display_chip_line::@5 to bgcolor [phi:display_chip_line::@5->bgcolor]
    // [569] phi bgcolor::color#14 = BLUE [phi:display_chip_line::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_line::@6
    // cputc(VERA_CHR_UR)
    // [2357] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [2358] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [2360] call textcolor
    // [564] phi from display_chip_line::@6 to textcolor [phi:display_chip_line::@6->textcolor]
    // [564] phi textcolor::color#18 = WHITE [phi:display_chip_line::@6->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [2361] phi from display_chip_line::@6 to display_chip_line::@7 [phi:display_chip_line::@6->display_chip_line::@7]
    // display_chip_line::@7
    // bgcolor(BLACK)
    // [2362] call bgcolor
    // [569] phi from display_chip_line::@7 to bgcolor [phi:display_chip_line::@7->bgcolor]
    // [569] phi bgcolor::color#14 = BLACK [phi:display_chip_line::@7->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // [2363] phi from display_chip_line::@7 to display_chip_line::@1 [phi:display_chip_line::@7->display_chip_line::@1]
    // [2363] phi display_chip_line::i#2 = 0 [phi:display_chip_line::@7->display_chip_line::@1#0] -- vbum1=vbuc1 
    lda #0
    sta i
    // display_chip_line::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [2364] if(display_chip_line::i#2<display_chip_line::w#10) goto display_chip_line::@2 -- vbum1_lt_vbuz2_then_la1 
    lda i
    cmp.z w
    bcc __b2
    // [2365] phi from display_chip_line::@1 to display_chip_line::@3 [phi:display_chip_line::@1->display_chip_line::@3]
    // display_chip_line::@3
    // textcolor(GREY)
    // [2366] call textcolor
    // [564] phi from display_chip_line::@3 to textcolor [phi:display_chip_line::@3->textcolor]
    // [564] phi textcolor::color#18 = GREY [phi:display_chip_line::@3->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [2367] phi from display_chip_line::@3 to display_chip_line::@8 [phi:display_chip_line::@3->display_chip_line::@8]
    // display_chip_line::@8
    // bgcolor(BLUE)
    // [2368] call bgcolor
    // [569] phi from display_chip_line::@8 to bgcolor [phi:display_chip_line::@8->bgcolor]
    // [569] phi bgcolor::color#14 = BLUE [phi:display_chip_line::@8->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_line::@9
    // cputc(VERA_CHR_UL)
    // [2369] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [2370] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [2372] call textcolor
    // [564] phi from display_chip_line::@9 to textcolor [phi:display_chip_line::@9->textcolor]
    // [564] phi textcolor::color#18 = WHITE [phi:display_chip_line::@9->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [2373] phi from display_chip_line::@9 to display_chip_line::@10 [phi:display_chip_line::@9->display_chip_line::@10]
    // display_chip_line::@10
    // bgcolor(BLACK)
    // [2374] call bgcolor
    // [569] phi from display_chip_line::@10 to bgcolor [phi:display_chip_line::@10->bgcolor]
    // [569] phi bgcolor::color#14 = BLACK [phi:display_chip_line::@10->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // display_chip_line::@11
    // cputcxy(x+2, y, c)
    // [2375] cputcxy::x#8 = display_chip_line::x#16 + 2 -- vbum1=vbuz2_plus_2 
    lda.z x
    clc
    adc #2
    sta cputcxy.x
    // [2376] cputcxy::y#8 = display_chip_line::y#16 -- vbum1=vbuz2 
    lda.z y
    sta cputcxy.y
    // [2377] cputcxy::c#8 = display_chip_line::c#15 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [2378] call cputcxy
    // [1771] phi from display_chip_line::@11 to cputcxy [phi:display_chip_line::@11->cputcxy]
    // [1771] phi cputcxy::c#15 = cputcxy::c#8 [phi:display_chip_line::@11->cputcxy#0] -- register_copy 
    // [1771] phi cputcxy::y#15 = cputcxy::y#8 [phi:display_chip_line::@11->cputcxy#1] -- register_copy 
    // [1771] phi cputcxy::x#15 = cputcxy::x#8 [phi:display_chip_line::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_line::@return
    // }
    // [2379] return 
    rts
    // display_chip_line::@2
  __b2:
    // cputc(VERA_CHR_SPACE)
    // [2380] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [2381] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [2383] display_chip_line::i#1 = ++ display_chip_line::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [2363] phi from display_chip_line::@2 to display_chip_line::@1 [phi:display_chip_line::@2->display_chip_line::@1]
    // [2363] phi display_chip_line::i#2 = display_chip_line::i#1 [phi:display_chip_line::@2->display_chip_line::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    i: .byte 0
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
// void display_chip_end(__zp($b5) char x, char y, __zp($2b) char w)
display_chip_end: {
    .label x = $b5
    .label w = $2b
    // gotoxy(x, y)
    // [2384] gotoxy::x#8 = display_chip_end::x#0 -- vbum1=vbuz2 
    lda.z x
    sta gotoxy.x
    // [2385] call gotoxy
    // [582] phi from display_chip_end to gotoxy [phi:display_chip_end->gotoxy]
    // [582] phi gotoxy::y#30 = display_print_chip::y#21 [phi:display_chip_end->gotoxy#0] -- vbum1=vbuc1 
    lda #display_print_chip.y
    sta gotoxy.y
    // [582] phi gotoxy::x#30 = gotoxy::x#8 [phi:display_chip_end->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [2386] phi from display_chip_end to display_chip_end::@4 [phi:display_chip_end->display_chip_end::@4]
    // display_chip_end::@4
    // textcolor(GREY)
    // [2387] call textcolor
    // [564] phi from display_chip_end::@4 to textcolor [phi:display_chip_end::@4->textcolor]
    // [564] phi textcolor::color#18 = GREY [phi:display_chip_end::@4->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [2388] phi from display_chip_end::@4 to display_chip_end::@5 [phi:display_chip_end::@4->display_chip_end::@5]
    // display_chip_end::@5
    // bgcolor(BLUE)
    // [2389] call bgcolor
    // [569] phi from display_chip_end::@5 to bgcolor [phi:display_chip_end::@5->bgcolor]
    // [569] phi bgcolor::color#14 = BLUE [phi:display_chip_end::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_end::@6
    // cputc(VERA_CHR_UR)
    // [2390] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [2391] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [2393] call textcolor
    // [564] phi from display_chip_end::@6 to textcolor [phi:display_chip_end::@6->textcolor]
    // [564] phi textcolor::color#18 = BLUE [phi:display_chip_end::@6->textcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta textcolor.color
    jsr textcolor
    // [2394] phi from display_chip_end::@6 to display_chip_end::@7 [phi:display_chip_end::@6->display_chip_end::@7]
    // display_chip_end::@7
    // bgcolor(BLACK)
    // [2395] call bgcolor
    // [569] phi from display_chip_end::@7 to bgcolor [phi:display_chip_end::@7->bgcolor]
    // [569] phi bgcolor::color#14 = BLACK [phi:display_chip_end::@7->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // [2396] phi from display_chip_end::@7 to display_chip_end::@1 [phi:display_chip_end::@7->display_chip_end::@1]
    // [2396] phi display_chip_end::i#2 = 0 [phi:display_chip_end::@7->display_chip_end::@1#0] -- vbum1=vbuc1 
    lda #0
    sta i
    // display_chip_end::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [2397] if(display_chip_end::i#2<display_chip_end::w#0) goto display_chip_end::@2 -- vbum1_lt_vbuz2_then_la1 
    lda i
    cmp.z w
    bcc __b2
    // [2398] phi from display_chip_end::@1 to display_chip_end::@3 [phi:display_chip_end::@1->display_chip_end::@3]
    // display_chip_end::@3
    // textcolor(GREY)
    // [2399] call textcolor
    // [564] phi from display_chip_end::@3 to textcolor [phi:display_chip_end::@3->textcolor]
    // [564] phi textcolor::color#18 = GREY [phi:display_chip_end::@3->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [2400] phi from display_chip_end::@3 to display_chip_end::@8 [phi:display_chip_end::@3->display_chip_end::@8]
    // display_chip_end::@8
    // bgcolor(BLUE)
    // [2401] call bgcolor
    // [569] phi from display_chip_end::@8 to bgcolor [phi:display_chip_end::@8->bgcolor]
    // [569] phi bgcolor::color#14 = BLUE [phi:display_chip_end::@8->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_end::@9
    // cputc(VERA_CHR_UL)
    // [2402] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [2403] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_chip_end::@return
    // }
    // [2405] return 
    rts
    // display_chip_end::@2
  __b2:
    // cputc(VERA_CHR_HL)
    // [2406] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [2407] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [2409] display_chip_end::i#1 = ++ display_chip_end::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [2396] phi from display_chip_end::@2 to display_chip_end::@1 [phi:display_chip_end::@2->display_chip_end::@1]
    // [2396] phi display_chip_end::i#2 = display_chip_end::i#1 [phi:display_chip_end::@2->display_chip_end::@1#0] -- register_copy 
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
// __mem() unsigned int utoa_append(__zp($38) char *buffer, __mem() unsigned int value, __mem() unsigned int sub)
utoa_append: {
    .label buffer = $38
    // [2411] phi from utoa_append to utoa_append::@1 [phi:utoa_append->utoa_append::@1]
    // [2411] phi utoa_append::digit#2 = 0 [phi:utoa_append->utoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [2411] phi utoa_append::value#2 = utoa_append::value#0 [phi:utoa_append->utoa_append::@1#1] -- register_copy 
    // utoa_append::@1
  __b1:
    // while (value >= sub)
    // [2412] if(utoa_append::value#2>=utoa_append::sub#0) goto utoa_append::@2 -- vwum1_ge_vwum2_then_la1 
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
    // [2413] *utoa_append::buffer#0 = DIGITS[utoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // utoa_append::@return
    // }
    // [2414] return 
    rts
    // utoa_append::@2
  __b2:
    // digit++;
    // [2415] utoa_append::digit#1 = ++ utoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [2416] utoa_append::value#1 = utoa_append::value#2 - utoa_append::sub#0 -- vwum1=vwum1_minus_vwum2 
    lda value
    sec
    sbc sub
    sta value
    lda value+1
    sbc sub+1
    sta value+1
    // [2411] phi from utoa_append::@2 to utoa_append::@1 [phi:utoa_append::@2->utoa_append::@1]
    // [2411] phi utoa_append::digit#2 = utoa_append::digit#1 [phi:utoa_append::@2->utoa_append::@1#0] -- register_copy 
    // [2411] phi utoa_append::value#2 = utoa_append::value#1 [phi:utoa_append::@2->utoa_append::@1#1] -- register_copy 
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
    .label rom_bank1_rom_write_byte__0 = $2b
    .label rom_bank1_rom_write_byte__1 = $3a
    .label rom_bank1_rom_write_byte__2 = $3b
    .label rom_ptr1_rom_write_byte__0 = $36
    .label rom_ptr1_rom_write_byte__2 = $36
    .label rom_ptr1_return = $36
    .label address = $3d
    .label value = $41
    // rom_write_byte::rom_bank1
    // BYTE2(address)
    // [2418] rom_write_byte::rom_bank1_$0 = byte2  rom_write_byte::address#4 -- vbuz1=_byte2_vduz2 
    lda.z address+2
    sta.z rom_bank1_rom_write_byte__0
    // BYTE1(address)
    // [2419] rom_write_byte::rom_bank1_$1 = byte1  rom_write_byte::address#4 -- vbuz1=_byte1_vduz2 
    lda.z address+1
    sta.z rom_bank1_rom_write_byte__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2420] rom_write_byte::rom_bank1_$2 = rom_write_byte::rom_bank1_$0 w= rom_write_byte::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_write_byte__0
    sta.z rom_bank1_rom_write_byte__2+1
    lda.z rom_bank1_rom_write_byte__1
    sta.z rom_bank1_rom_write_byte__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2421] rom_write_byte::rom_bank1_bank_unshifted#0 = rom_write_byte::rom_bank1_$2 << 2 -- vwum1=vwuz2_rol_2 
    asl
    sta rom_bank1_bank_unshifted
    lda.z rom_bank1_rom_write_byte__2+1
    rol
    sta rom_bank1_bank_unshifted+1
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2422] rom_write_byte::rom_bank1_return#0 = byte1  rom_write_byte::rom_bank1_bank_unshifted#0 -- vbum1=_byte1_vwum2 
    lda rom_bank1_bank_unshifted+1
    sta rom_bank1_return
    // rom_write_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2423] rom_write_byte::rom_ptr1_$2 = (unsigned int)rom_write_byte::address#4 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_write_byte__2
    lda.z address+1
    sta.z rom_ptr1_rom_write_byte__2+1
    // [2424] rom_write_byte::rom_ptr1_$0 = rom_write_byte::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_write_byte__0
    and #<$3fff
    sta.z rom_ptr1_rom_write_byte__0
    lda.z rom_ptr1_rom_write_byte__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_write_byte__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2425] rom_write_byte::rom_ptr1_return#0 = rom_write_byte::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_write_byte::bank_set_brom1
    // BROM = bank
    // [2426] BROM = rom_write_byte::rom_bank1_return#0 -- vbuz1=vbum2 
    lda rom_bank1_return
    sta.z BROM
    // rom_write_byte::@1
    // *ptr_rom = value
    // [2427] *((char *)rom_write_byte::rom_ptr1_return#0) = rom_write_byte::value#10 -- _deref_pbuz1=vbuz2 
    lda.z value
    ldy #0
    sta (rom_ptr1_return),y
    // rom_write_byte::@return
    // }
    // [2428] return 
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
    // [2430] return 
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
// __mem() int ferror(__zp($b6) struct $2 *stream)
ferror: {
    .label ferror__6 = $3a
    .label ferror__15 = $2b
    .label cbm_k_setnam1_filename = $bc
    .label cbm_k_setnam1_ferror__0 = $36
    .label stream = $b6
    .label errno_len = $61
    // unsigned char sp = (unsigned char)stream
    // [2431] ferror::sp#0 = (char)ferror::stream#0 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_setlfs(15, 8, 15)
    // [2432] cbm_k_setlfs::channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.channel
    // [2433] cbm_k_setlfs::device = 8 -- vbum1=vbuc1 
    lda #8
    sta cbm_k_setlfs.device
    // [2434] cbm_k_setlfs::command = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.command
    // [2435] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // ferror::@11
    // cbm_k_setnam("")
    // [2436] ferror::cbm_k_setnam1_filename = info_text5 -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z cbm_k_setnam1_filename
    lda #>info_text5
    sta.z cbm_k_setnam1_filename+1
    // ferror::cbm_k_setnam1
    // strlen(filename)
    // [2437] strlen::str#5 = ferror::cbm_k_setnam1_filename -- pbuz1=pbuz2 
    lda.z cbm_k_setnam1_filename
    sta.z strlen.str
    lda.z cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [2438] call strlen
    // [2158] phi from ferror::cbm_k_setnam1 to strlen [phi:ferror::cbm_k_setnam1->strlen]
    // [2158] phi strlen::str#8 = strlen::str#5 [phi:ferror::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [2439] strlen::return#12 = strlen::len#2
    // ferror::@12
    // [2440] ferror::cbm_k_setnam1_$0 = strlen::return#12 -- vwuz1=vwum2 
    lda strlen.return
    sta.z cbm_k_setnam1_ferror__0
    lda strlen.return+1
    sta.z cbm_k_setnam1_ferror__0+1
    // char filename_len = (char)strlen(filename)
    // [2441] ferror::cbm_k_setnam1_filename_len = (char)ferror::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
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
    // [2444] ferror::cbm_k_chkin1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_chkin1_channel
    // ferror::cbm_k_chkin1
    // char status
    // [2445] ferror::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // ferror::cbm_k_chrin1
    // char ch
    // [2447] ferror::cbm_k_chrin1_ch = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chrin1_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin1_ch
    // return ch;
    // [2449] ferror::cbm_k_chrin1_return#0 = ferror::cbm_k_chrin1_ch -- vbum1=vbum2 
    sta cbm_k_chrin1_return
    // ferror::cbm_k_chrin1_@return
    // }
    // [2450] ferror::cbm_k_chrin1_return#1 = ferror::cbm_k_chrin1_return#0
    // ferror::@7
    // char ch = cbm_k_chrin()
    // [2451] ferror::ch#0 = ferror::cbm_k_chrin1_return#1
    // [2452] phi from ferror::@7 to ferror::cbm_k_readst1 [phi:ferror::@7->ferror::cbm_k_readst1]
    // [2452] phi __errno#18 = __errno#328 [phi:ferror::@7->ferror::cbm_k_readst1#0] -- register_copy 
    // [2452] phi ferror::errno_len#10 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z errno_len
    // [2452] phi ferror::ch#10 = ferror::ch#0 [phi:ferror::@7->ferror::cbm_k_readst1#2] -- register_copy 
    // [2452] phi ferror::errno_parsed#2 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#3] -- vbum1=vbuc1 
    sta errno_parsed
    // ferror::cbm_k_readst1
  cbm_k_readst1:
    // char status
    // [2453] ferror::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2455] ferror::cbm_k_readst1_return#0 = ferror::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // ferror::cbm_k_readst1_@return
    // }
    // [2456] ferror::cbm_k_readst1_return#1 = ferror::cbm_k_readst1_return#0
    // ferror::@8
    // cbm_k_readst()
    // [2457] ferror::$6 = ferror::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z ferror__6
    // st = cbm_k_readst()
    // [2458] ferror::st#1 = ferror::$6 -- vbum1=vbuz2 
    sta st
    // while (!(st = cbm_k_readst()))
    // [2459] if(0==ferror::st#1) goto ferror::@1 -- 0_eq_vbum1_then_la1 
    beq __b1
    // ferror::@2
    // __status = st
    // [2460] ((char *)&__stdio_file+$8c)[ferror::sp#0] = ferror::st#1 -- pbuc1_derefidx_vbum1=vbum2 
    ldy sp
    sta __stdio_file+$8c,y
    // cbm_k_close(15)
    // [2461] ferror::cbm_k_close1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_close1_channel
    // ferror::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // ferror::@9
    // return __errno;
    // [2463] ferror::return#1 = __errno#18 -- vwsm1=vwsm2 
    lda __errno
    sta return
    lda __errno+1
    sta return+1
    // ferror::@return
    // }
    // [2464] return 
    rts
    // ferror::@1
  __b1:
    // if (!errno_parsed)
    // [2465] if(0!=ferror::errno_parsed#2) goto ferror::@3 -- 0_neq_vbum1_then_la1 
    lda errno_parsed
    bne __b3
    // ferror::@4
    // if (ch == ',')
    // [2466] if(ferror::ch#10!=',') goto ferror::@3 -- vbum1_neq_vbuc1_then_la1 
    lda #','
    cmp ch
    bne __b3
    // ferror::@5
    // errno_parsed++;
    // [2467] ferror::errno_parsed#1 = ++ ferror::errno_parsed#2 -- vbum1=_inc_vbum1 
    inc errno_parsed
    // strncpy(temp, __errno_error, errno_len+1)
    // [2468] strncpy::n#0 = ferror::errno_len#10 + 1 -- vwum1=vbuz2_plus_1 
    lda.z errno_len
    clc
    adc #1
    sta strncpy.n
    lda #0
    adc #0
    sta strncpy.n+1
    // [2469] call strncpy
    // [1535] phi from ferror::@5 to strncpy [phi:ferror::@5->strncpy]
    // [1535] phi strncpy::dst#8 = ferror::temp [phi:ferror::@5->strncpy#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z strncpy.dst
    lda #>temp
    sta.z strncpy.dst+1
    // [1535] phi strncpy::src#6 = __errno_error [phi:ferror::@5->strncpy#1] -- pbuz1=pbuc1 
    lda #<__errno_error
    sta.z strncpy.src
    lda #>__errno_error
    sta.z strncpy.src+1
    // [1535] phi strncpy::n#3 = strncpy::n#0 [phi:ferror::@5->strncpy#2] -- register_copy 
    jsr strncpy
    // [2470] phi from ferror::@5 to ferror::@13 [phi:ferror::@5->ferror::@13]
    // ferror::@13
    // atoi(temp)
    // [2471] call atoi
    // [2483] phi from ferror::@13 to atoi [phi:ferror::@13->atoi]
    // [2483] phi atoi::str#2 = ferror::temp [phi:ferror::@13->atoi#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z atoi.str
    lda #>temp
    sta.z atoi.str+1
    jsr atoi
    // atoi(temp)
    // [2472] atoi::return#4 = atoi::return#2
    // ferror::@14
    // __errno = atoi(temp)
    // [2473] __errno#2 = atoi::return#4 -- vwsm1=vwsm2 
    lda atoi.return
    sta __errno
    lda atoi.return+1
    sta __errno+1
    // [2474] phi from ferror::@1 ferror::@14 ferror::@4 to ferror::@3 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3]
    // [2474] phi __errno#103 = __errno#18 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#0] -- register_copy 
    // [2474] phi ferror::errno_parsed#11 = ferror::errno_parsed#2 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#1] -- register_copy 
    // ferror::@3
  __b3:
    // __errno_error[errno_len] = ch
    // [2475] __errno_error[ferror::errno_len#10] = ferror::ch#10 -- pbuc1_derefidx_vbuz1=vbum2 
    lda ch
    ldy.z errno_len
    sta __errno_error,y
    // errno_len++;
    // [2476] ferror::errno_len#1 = ++ ferror::errno_len#10 -- vbuz1=_inc_vbuz1 
    inc.z errno_len
    // ferror::cbm_k_chrin2
    // char ch
    // [2477] ferror::cbm_k_chrin2_ch = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chrin2_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin2_ch
    // return ch;
    // [2479] ferror::cbm_k_chrin2_return#0 = ferror::cbm_k_chrin2_ch -- vbum1=vbum2 
    sta cbm_k_chrin2_return
    // ferror::cbm_k_chrin2_@return
    // }
    // [2480] ferror::cbm_k_chrin2_return#1 = ferror::cbm_k_chrin2_return#0
    // ferror::@10
    // cbm_k_chrin()
    // [2481] ferror::$15 = ferror::cbm_k_chrin2_return#1 -- vbuz1=vbum2 
    sta.z ferror__15
    // ch = cbm_k_chrin()
    // [2482] ferror::ch#1 = ferror::$15 -- vbum1=vbuz2 
    sta ch
    // [2452] phi from ferror::@10 to ferror::cbm_k_readst1 [phi:ferror::@10->ferror::cbm_k_readst1]
    // [2452] phi __errno#18 = __errno#103 [phi:ferror::@10->ferror::cbm_k_readst1#0] -- register_copy 
    // [2452] phi ferror::errno_len#10 = ferror::errno_len#1 [phi:ferror::@10->ferror::cbm_k_readst1#1] -- register_copy 
    // [2452] phi ferror::ch#10 = ferror::ch#1 [phi:ferror::@10->ferror::cbm_k_readst1#2] -- register_copy 
    // [2452] phi ferror::errno_parsed#2 = ferror::errno_parsed#11 [phi:ferror::@10->ferror::cbm_k_readst1#3] -- register_copy 
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
// __mem() int atoi(__zp($6a) const char *str)
atoi: {
    .label atoi__6 = $42
    .label atoi__7 = $42
    .label str = $6a
    .label atoi__10 = $42
    .label atoi__11 = $42
    // if (str[i] == '-')
    // [2484] if(*atoi::str#2!='-') goto atoi::@3 -- _deref_pbuz1_neq_vbuc1_then_la1 
    ldy #0
    lda (str),y
    cmp #'-'
    bne __b2
    // [2485] phi from atoi to atoi::@2 [phi:atoi->atoi::@2]
    // atoi::@2
    // [2486] phi from atoi::@2 to atoi::@3 [phi:atoi::@2->atoi::@3]
    // [2486] phi atoi::negative#2 = 1 [phi:atoi::@2->atoi::@3#0] -- vbum1=vbuc1 
    lda #1
    sta negative
    // [2486] phi atoi::res#2 = 0 [phi:atoi::@2->atoi::@3#1] -- vwsm1=vwsc1 
    tya
    sta res
    sta res+1
    // [2486] phi atoi::i#4 = 1 [phi:atoi::@2->atoi::@3#2] -- vbum1=vbuc1 
    lda #1
    sta i
    jmp __b3
  // Iterate through all digits and update the result
    // [2486] phi from atoi to atoi::@3 [phi:atoi->atoi::@3]
  __b2:
    // [2486] phi atoi::negative#2 = 0 [phi:atoi->atoi::@3#0] -- vbum1=vbuc1 
    lda #0
    sta negative
    // [2486] phi atoi::res#2 = 0 [phi:atoi->atoi::@3#1] -- vwsm1=vwsc1 
    sta res
    sta res+1
    // [2486] phi atoi::i#4 = 0 [phi:atoi->atoi::@3#2] -- vbum1=vbuc1 
    sta i
    // atoi::@3
  __b3:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [2487] if(atoi::str#2[atoi::i#4]<'0') goto atoi::@5 -- pbuz1_derefidx_vbum2_lt_vbuc1_then_la1 
    ldy i
    lda (str),y
    cmp #'0'
    bcc __b5
    // atoi::@6
    // [2488] if(atoi::str#2[atoi::i#4]<='9') goto atoi::@4 -- pbuz1_derefidx_vbum2_le_vbuc1_then_la1 
    lda (str),y
    cmp #'9'
    bcc __b4
    beq __b4
    // atoi::@5
  __b5:
    // if(negative)
    // [2489] if(0!=atoi::negative#2) goto atoi::@1 -- 0_neq_vbum1_then_la1 
    // Return result with sign
    lda negative
    bne __b1
    // [2491] phi from atoi::@1 atoi::@5 to atoi::@return [phi:atoi::@1/atoi::@5->atoi::@return]
    // [2491] phi atoi::return#2 = atoi::return#0 [phi:atoi::@1/atoi::@5->atoi::@return#0] -- register_copy 
    rts
    // atoi::@1
  __b1:
    // return -res;
    // [2490] atoi::return#0 = - atoi::res#2 -- vwsm1=_neg_vwsm1 
    lda #0
    sec
    sbc return
    sta return
    lda #0
    sbc return+1
    sta return+1
    // atoi::@return
    // }
    // [2492] return 
    rts
    // atoi::@4
  __b4:
    // res * 10
    // [2493] atoi::$10 = atoi::res#2 << 2 -- vwsz1=vwsm2_rol_2 
    lda res
    asl
    sta.z atoi__10
    lda res+1
    rol
    sta.z atoi__10+1
    asl.z atoi__10
    rol.z atoi__10+1
    // [2494] atoi::$11 = atoi::$10 + atoi::res#2 -- vwsz1=vwsz1_plus_vwsm2 
    clc
    lda.z atoi__11
    adc res
    sta.z atoi__11
    lda.z atoi__11+1
    adc res+1
    sta.z atoi__11+1
    // [2495] atoi::$6 = atoi::$11 << 1 -- vwsz1=vwsz1_rol_1 
    asl.z atoi__6
    rol.z atoi__6+1
    // res * 10 + str[i]
    // [2496] atoi::$7 = atoi::$6 + atoi::str#2[atoi::i#4] -- vwsz1=vwsz1_plus_pbuz2_derefidx_vbum3 
    ldy i
    lda.z atoi__7
    clc
    adc (str),y
    sta.z atoi__7
    bcc !+
    inc.z atoi__7+1
  !:
    // res = res * 10 + str[i] - '0'
    // [2497] atoi::res#1 = atoi::$7 - '0' -- vwsm1=vwsz2_minus_vbuc1 
    lda.z atoi__7
    sec
    sbc #'0'
    sta res
    lda.z atoi__7+1
    sbc #0
    sta res+1
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [2498] atoi::i#2 = ++ atoi::i#4 -- vbum1=_inc_vbum1 
    inc i
    // [2486] phi from atoi::@4 to atoi::@3 [phi:atoi::@4->atoi::@3]
    // [2486] phi atoi::negative#2 = atoi::negative#2 [phi:atoi::@4->atoi::@3#0] -- register_copy 
    // [2486] phi atoi::res#2 = atoi::res#1 [phi:atoi::@4->atoi::@3#1] -- register_copy 
    // [2486] phi atoi::i#4 = atoi::i#2 [phi:atoi::@4->atoi::@3#2] -- register_copy 
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
// __mem() unsigned int cx16_k_macptr(__mem() volatile char bytes, __zp($64) void * volatile buffer)
cx16_k_macptr: {
    .label buffer = $64
    // unsigned int bytes_read
    // [2499] cx16_k_macptr::bytes_read = 0 -- vwum1=vwuc1 
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
    // [2501] cx16_k_macptr::return#0 = cx16_k_macptr::bytes_read -- vwum1=vwum2 
    lda bytes_read
    sta return
    lda bytes_read+1
    sta return+1
    // cx16_k_macptr::@return
    // }
    // [2502] cx16_k_macptr::return#1 = cx16_k_macptr::return#0
    // [2503] return 
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
// __mem() char uctoa_append(__zp($4b) char *buffer, __mem() char value, __mem() char sub)
uctoa_append: {
    .label buffer = $4b
    // [2505] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [2505] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [2505] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [2506] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbum1_ge_vbum2_then_la1 
    lda value
    cmp sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [2507] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // uctoa_append::@return
    // }
    // [2508] return 
    rts
    // uctoa_append::@2
  __b2:
    // digit++;
    // [2509] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [2510] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbum1=vbum1_minus_vbum2 
    lda value
    sec
    sbc sub
    sta value
    // [2505] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [2505] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [2505] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
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
// __mem() char rom_byte_compare(__zp($4e) char *ptr_rom, __zp($4d) char value)
rom_byte_compare: {
    .label ptr_rom = $4e
    .label value = $4d
    // if (*ptr_rom != value)
    // [2511] if(*rom_byte_compare::ptr_rom#0==rom_byte_compare::value#0) goto rom_byte_compare::@1 -- _deref_pbuz1_eq_vbuz2_then_la1 
    lda.z value
    ldy #0
    cmp (ptr_rom),y
    beq __b2
    // [2512] phi from rom_byte_compare to rom_byte_compare::@2 [phi:rom_byte_compare->rom_byte_compare::@2]
    // rom_byte_compare::@2
    // [2513] phi from rom_byte_compare::@2 to rom_byte_compare::@1 [phi:rom_byte_compare::@2->rom_byte_compare::@1]
    // [2513] phi rom_byte_compare::return#0 = 0 [phi:rom_byte_compare::@2->rom_byte_compare::@1#0] -- vbum1=vbuc1 
    tya
    sta return
    rts
    // [2513] phi from rom_byte_compare to rom_byte_compare::@1 [phi:rom_byte_compare->rom_byte_compare::@1]
  __b2:
    // [2513] phi rom_byte_compare::return#0 = 1 [phi:rom_byte_compare->rom_byte_compare::@1#0] -- vbum1=vbuc1 
    lda #1
    sta return
    // rom_byte_compare::@1
    // rom_byte_compare::@return
    // }
    // [2514] return 
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
// __mem() unsigned long ultoa_append(__zp($3b) char *buffer, __mem() unsigned long value, __mem() unsigned long sub)
ultoa_append: {
    .label buffer = $3b
    // [2516] phi from ultoa_append to ultoa_append::@1 [phi:ultoa_append->ultoa_append::@1]
    // [2516] phi ultoa_append::digit#2 = 0 [phi:ultoa_append->ultoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [2516] phi ultoa_append::value#2 = ultoa_append::value#0 [phi:ultoa_append->ultoa_append::@1#1] -- register_copy 
    // ultoa_append::@1
  __b1:
    // while (value >= sub)
    // [2517] if(ultoa_append::value#2>=ultoa_append::sub#0) goto ultoa_append::@2 -- vdum1_ge_vdum2_then_la1 
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
    // [2518] *ultoa_append::buffer#0 = DIGITS[ultoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // ultoa_append::@return
    // }
    // [2519] return 
    rts
    // ultoa_append::@2
  __b2:
    // digit++;
    // [2520] ultoa_append::digit#1 = ++ ultoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [2521] ultoa_append::value#1 = ultoa_append::value#2 - ultoa_append::sub#0 -- vdum1=vdum1_minus_vdum2 
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
    // [2516] phi from ultoa_append::@2 to ultoa_append::@1 [phi:ultoa_append::@2->ultoa_append::@1]
    // [2516] phi ultoa_append::digit#2 = ultoa_append::digit#1 [phi:ultoa_append::@2->ultoa_append::@1#0] -- register_copy 
    // [2516] phi ultoa_append::value#2 = ultoa_append::value#1 [phi:ultoa_append::@2->ultoa_append::@1#1] -- register_copy 
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
    // [2523] rom_wait::test1#1 = *rom_wait::ptr_rom#3 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (ptr_rom),y
    sta test1
    // test2 = *((brom_ptr_t)ptr_rom)
    // [2524] rom_wait::test2#1 = *rom_wait::ptr_rom#3 -- vbum1=_deref_pbuz2 
    lda (ptr_rom),y
    sta test2
    // test1 & 0x40
    // [2525] rom_wait::$0 = rom_wait::test1#1 & $40 -- vbuz1=vbum2_band_vbuc1 
    lda #$40
    and test1
    sta.z rom_wait__0
    // test2 & 0x40
    // [2526] rom_wait::$1 = rom_wait::test2#1 & $40 -- vbuz1=vbum2_band_vbuc1 
    lda #$40
    and test2
    sta.z rom_wait__1
    // while ((test1 & 0x40) != (test2 & 0x40))
    // [2527] if(rom_wait::$0!=rom_wait::$1) goto rom_wait::@1 -- vbuz1_neq_vbuz2_then_la1 
    lda.z rom_wait__0
    cmp.z rom_wait__1
    bne __b1
    // rom_wait::@return
    // }
    // [2528] return 
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
    .label rom_ptr1_rom_byte_program__0 = $42
    .label rom_ptr1_rom_byte_program__2 = $42
    .label rom_ptr1_return = $42
    .label address = $3d
    .label value = $41
    // rom_byte_program::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2530] rom_byte_program::rom_ptr1_$2 = (unsigned int)rom_byte_program::address#0 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_byte_program__2
    lda.z address+1
    sta.z rom_ptr1_rom_byte_program__2+1
    // [2531] rom_byte_program::rom_ptr1_$0 = rom_byte_program::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_byte_program__0
    and #<$3fff
    sta.z rom_ptr1_rom_byte_program__0
    lda.z rom_ptr1_rom_byte_program__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_byte_program__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2532] rom_byte_program::rom_ptr1_return#0 = rom_byte_program::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_byte_program::@1
    // rom_write_byte(address, value)
    // [2533] rom_write_byte::address#3 = rom_byte_program::address#0
    // [2534] rom_write_byte::value#3 = rom_byte_program::value#0
    // [2535] call rom_write_byte
    // [2417] phi from rom_byte_program::@1 to rom_write_byte [phi:rom_byte_program::@1->rom_write_byte]
    // [2417] phi rom_write_byte::value#10 = rom_write_byte::value#3 [phi:rom_byte_program::@1->rom_write_byte#0] -- register_copy 
    // [2417] phi rom_write_byte::address#4 = rom_write_byte::address#3 [phi:rom_byte_program::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_byte_program::@2
    // rom_wait(ptr_rom)
    // [2536] rom_wait::ptr_rom#1 = (char *)rom_byte_program::rom_ptr1_return#0 -- pbuz1=pbuz2 
    lda.z rom_ptr1_return
    sta.z rom_wait.ptr_rom
    lda.z rom_ptr1_return+1
    sta.z rom_wait.ptr_rom+1
    // [2537] call rom_wait
    // [2522] phi from rom_byte_program::@2 to rom_wait [phi:rom_byte_program::@2->rom_wait]
    // [2522] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#1 [phi:rom_byte_program::@2->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_byte_program::@return
    // }
    // [2538] return 
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
    // [2539] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [2540] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte0_vwum2 
    lda soffset_vram
    sta.z memcpy8_vram_vram__0
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [2541] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [2542] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte1_vwum2 
    lda soffset_vram+1
    sta.z memcpy8_vram_vram__1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [2543] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [2544] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbuz1=vbum2_bor_vbuc1 
    lda #VERA_INC_1
    ora sbank_vram
    sta.z memcpy8_vram_vram__2
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [2545] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [2546] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [2547] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte0_vwum2 
    lda doffset_vram
    sta.z memcpy8_vram_vram__3
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [2548] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [2549] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte1_vwum2 
    lda doffset_vram+1
    sta.z memcpy8_vram_vram__4
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [2550] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [2551] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbuz1=vbum2_bor_vbuc1 
    lda #VERA_INC_1
    ora dbank_vram
    sta.z memcpy8_vram_vram__5
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [2552] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // [2553] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [2553] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [2554] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbum1=_dec_vbum2 
    ldy num8_1
    dey
    sty num8
    // [2555] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbum1_then_la1 
    lda num8_1
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [2556] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [2557] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [2558] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbum1=vbum2 
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
  display_into_briefing_text: .word __14, __15, info_text5, __17, __18, __19, __20, __21, __22, __23, __24, info_text5, __26, __27
  .fill 2*2, 0
  display_into_colors_text: .word __28, __29, info_text5, __31, __32, __33, __34, __35, __36, __37, __38, __39, __40, __41, info_text5, __43
  display_debriefing_text_smc: .word __56, info_text5, __46, __47, __48, info_text5, __50, info_text5, __52, __53, __54, __55
  display_debriefing_text_rom: .word __56, info_text5, __58, __59
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
  __46: .text "Because your SMC chipset has been updated,"
  .byte 0
  __47: .text "the restart process differs, depending on the"
  .byte 0
  __48: .text "SMC boootloader version installed on your CX16 board:"
  .byte 0
  __50: .text "- SMC bootloader v2.0: your CX16 will automatically shut down."
  .byte 0
  __52: .text "- SMC bootloader v1.0: you need to "
  .byte 0
  __53: .text "  COMPLETELY DISCONNECT your CX16 from the power source!"
  .byte 0
  __54: .text "  The power-off button won't work!"
  .byte 0
  __55: .text "  Then, reconnect and start the CX16 normally."
  .byte 0
  __56: .text "Your CX16 system has been successfully updated!"
  .byte 0
  __58: .text "Since your CX16 system SMC and main ROM chipset"
  .byte 0
  __59: .text "have not been updated, your CX16 will just reset."
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
  info_text5: .text ""
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
