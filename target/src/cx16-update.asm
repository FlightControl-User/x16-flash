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
  .const STATUS_NONE = 0
  .const STATUS_SKIP = 1
  .const STATUS_DETECTED = 2
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
  .const display_no_valid_smc_bootloader_count = 9
  .const display_debriefing_count_smc = $c
  .const display_debriefing_count_rom = 4
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
  .label __errno = $f3
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
    // [3] __snprintf_buffer = (char *) 0 -- pbum1=pbuc1 
    lda #<0
    sta __snprintf_buffer
    sta __snprintf_buffer+1
    // volatile unsigned char __stdio_filecount = 0
    // [4] __stdio_filecount = 0 -- vbum1=vbuc1 
    sta __stdio_filecount
    // [5] phi from __start::__init1 to __start::@2 [phi:__start::__init1->__start::@2]
    // __start::@2
    // #pragma constructor_for(conio_x16_init, cputc, clrscr, cscroll)
    // [6] call conio_x16_init
    // [19] phi from __start::@2 to conio_x16_init [phi:__start::@2->conio_x16_init]
    jsr conio_x16_init
    // [7] phi from __start::@2 to __start::@1 [phi:__start::@2->__start::@1]
    // __start::@1
    // [8] call main
    // [71] phi from __start::@1 to main [phi:__start::@1->main]
    jsr main
    // __start::@return
    // [9] return 
    rts
}
  // snputc
/// Print a character into snprintf buffer
/// Used by snprintf()
/// @param c The character to print
// void snputc(__zp($e9) char c)
snputc: {
    .const OFFSET_STACK_C = 0
    .label c = $e9
    // [10] snputc::c#0 = stackidx(char,snputc::OFFSET_STACK_C) -- vbuz1=_stackidxbyte_vbuc1 
    tsx
    lda STACK_BASE+OFFSET_STACK_C,x
    sta.z c
    // ++__snprintf_size;
    // [11] __snprintf_size = ++ __snprintf_size -- vwum1=_inc_vwum1 
    inc __snprintf_size
    bne !+
    inc __snprintf_size+1
  !:
    // if(__snprintf_size > __snprintf_capacity)
    // [12] if(__snprintf_size<=__snprintf_capacity) goto snputc::@1 -- vwum1_le_vwum2_then_la1 
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
    // [13] return 
    rts
    // snputc::@1
  __b1:
    // if(__snprintf_size==__snprintf_capacity)
    // [14] if(__snprintf_size!=__snprintf_capacity) goto snputc::@3 -- vwum1_neq_vwum2_then_la1 
    lda __snprintf_size+1
    cmp __snprintf_capacity+1
    bne __b2
    lda __snprintf_size
    cmp __snprintf_capacity
    bne __b2
    // [16] phi from snputc::@1 to snputc::@2 [phi:snputc::@1->snputc::@2]
    // [16] phi snputc::c#2 = 0 [phi:snputc::@1->snputc::@2#0] -- vbuz1=vbuc1 
    lda #0
    sta.z c
    // [15] phi from snputc::@1 to snputc::@3 [phi:snputc::@1->snputc::@3]
    // snputc::@3
    // [16] phi from snputc::@3 to snputc::@2 [phi:snputc::@3->snputc::@2]
    // [16] phi snputc::c#2 = snputc::c#0 [phi:snputc::@3->snputc::@2#0] -- register_copy 
    // snputc::@2
  __b2:
    // *(__snprintf_buffer++) = c
    // [17] *__snprintf_buffer = snputc::c#2 -- _deref_pbum1=vbuz2 
    // Append char
    lda.z c
    ldy __snprintf_buffer
    sty.z $fe
    ldy __snprintf_buffer+1
    sty.z $ff
    ldy #0
    sta ($fe),y
    // *(__snprintf_buffer++) = c;
    // [18] __snprintf_buffer = ++ __snprintf_buffer -- pbum1=_inc_pbum1 
    inc __snprintf_buffer
    bne !+
    inc __snprintf_buffer+1
  !:
    rts
}
  // conio_x16_init
/// Set initial screen values.
conio_x16_init: {
    .label conio_x16_init__5 = $df
    // screenlayer1()
    // [20] call screenlayer1
    jsr screenlayer1
    // [21] phi from conio_x16_init to conio_x16_init::@1 [phi:conio_x16_init->conio_x16_init::@1]
    // conio_x16_init::@1
    // textcolor(CONIO_TEXTCOLOR_DEFAULT)
    // [22] call textcolor
    // [592] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [592] phi textcolor::color#18 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [23] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [24] call bgcolor
    // [597] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [597] phi bgcolor::color#14 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [25] phi from conio_x16_init::@2 to conio_x16_init::@3 [phi:conio_x16_init::@2->conio_x16_init::@3]
    // conio_x16_init::@3
    // cursor(0)
    // [26] call cursor
    jsr cursor
    // [27] phi from conio_x16_init::@3 to conio_x16_init::@4 [phi:conio_x16_init::@3->conio_x16_init::@4]
    // conio_x16_init::@4
    // cbm_k_plot_get()
    // [28] call cbm_k_plot_get
    jsr cbm_k_plot_get
    // [29] cbm_k_plot_get::return#2 = cbm_k_plot_get::return#0
    // conio_x16_init::@5
    // [30] conio_x16_init::$4 = cbm_k_plot_get::return#2
    // BYTE1(cbm_k_plot_get())
    // [31] conio_x16_init::$5 = byte1  conio_x16_init::$4 -- vbuz1=_byte1_vwum2 
    lda conio_x16_init__4+1
    sta.z conio_x16_init__5
    // __conio.cursor_x = BYTE1(cbm_k_plot_get())
    // [32] *((char *)&__conio) = conio_x16_init::$5 -- _deref_pbuc1=vbuz1 
    sta __conio
    // cbm_k_plot_get()
    // [33] call cbm_k_plot_get
    jsr cbm_k_plot_get
    // [34] cbm_k_plot_get::return#3 = cbm_k_plot_get::return#0
    // conio_x16_init::@6
    // [35] conio_x16_init::$6 = cbm_k_plot_get::return#3
    // BYTE0(cbm_k_plot_get())
    // [36] conio_x16_init::$7 = byte0  conio_x16_init::$6 -- vbum1=_byte0_vwum2 
    lda conio_x16_init__6
    sta conio_x16_init__7
    // __conio.cursor_y = BYTE0(cbm_k_plot_get())
    // [37] *((char *)&__conio+1) = conio_x16_init::$7 -- _deref_pbuc1=vbum1 
    sta __conio+1
    // gotoxy(__conio.cursor_x, __conio.cursor_y)
    // [38] gotoxy::x#2 = *((char *)&__conio) -- vbuz1=_deref_pbuc1 
    lda __conio
    sta.z gotoxy.x
    // [39] gotoxy::y#2 = *((char *)&__conio+1) -- vbuz1=_deref_pbuc1 
    lda __conio+1
    sta.z gotoxy.y
    // [40] call gotoxy
    // [610] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [610] phi gotoxy::y#30 = gotoxy::y#2 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [610] phi gotoxy::x#30 = gotoxy::x#2 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
    jsr gotoxy
    // conio_x16_init::@7
    // __conio.scroll[0] = 1
    // [41] *((char *)&__conio+$f) = 1 -- _deref_pbuc1=vbuc2 
    lda #1
    sta __conio+$f
    // __conio.scroll[1] = 1
    // [42] *((char *)&__conio+$f+1) = 1 -- _deref_pbuc1=vbuc2 
    sta __conio+$f+1
    // conio_x16_init::@return
    // }
    // [43] return 
    rts
  .segment Data
    .label conio_x16_init__4 = cbm_k_plot_get.return
    .label conio_x16_init__6 = cbm_k_plot_get.return
    conio_x16_init__7: .byte 0
}
.segment Code
  // cputc
// Output one character at the current cursor position
// Moves the cursor forward. Scrolls the entire screen if needed
// void cputc(__zp($34) char c)
cputc: {
    .const OFFSET_STACK_C = 0
    .label cputc__1 = $22
    .label cputc__2 = $af
    .label cputc__3 = $b0
    .label c = $34
    // [44] cputc::c#0 = stackidx(char,cputc::OFFSET_STACK_C) -- vbuz1=_stackidxbyte_vbuc1 
    tsx
    lda STACK_BASE+OFFSET_STACK_C,x
    sta.z c
    // if(c=='\n')
    // [45] if(cputc::c#0==' ') goto cputc::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #'\n'
    cmp.z c
    beq __b1
    // cputc::@2
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [46] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(__conio.offset)
    // [47] cputc::$1 = byte0  *((unsigned int *)&__conio+$13) -- vbuz1=_byte0__deref_pwuc1 
    lda __conio+$13
    sta.z cputc__1
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [48] *VERA_ADDRX_L = cputc::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [49] cputc::$2 = byte1  *((unsigned int *)&__conio+$13) -- vbuz1=_byte1__deref_pwuc1 
    lda __conio+$13+1
    sta.z cputc__2
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [50] *VERA_ADDRX_M = cputc::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [51] cputc::$3 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z cputc__3
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [52] *VERA_ADDRX_H = cputc::$3 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // *VERA_DATA0 = c
    // [53] *VERA_DATA0 = cputc::c#0 -- _deref_pbuc1=vbuz1 
    lda.z c
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [54] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // if(!__conio.hscroll[__conio.layer])
    // [55] if(0==((char *)&__conio+$11)[*((char *)&__conio+2)]) goto cputc::@5 -- 0_eq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$11,y
    cmp #0
    beq __b5
    // cputc::@3
    // if(__conio.cursor_x >= __conio.mapwidth)
    // [56] if(*((char *)&__conio)>=*((char *)&__conio+8)) goto cputc::@6 -- _deref_pbuc1_ge__deref_pbuc2_then_la1 
    lda __conio
    cmp __conio+8
    bcs __b6
    // cputc::@4
    // __conio.cursor_x++;
    // [57] *((char *)&__conio) = ++ *((char *)&__conio) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio
    // cputc::@7
  __b7:
    // __conio.offset++;
    // [58] *((unsigned int *)&__conio+$13) = ++ *((unsigned int *)&__conio+$13) -- _deref_pwuc1=_inc__deref_pwuc1 
    inc __conio+$13
    bne !+
    inc __conio+$13+1
  !:
    // [59] *((unsigned int *)&__conio+$13) = ++ *((unsigned int *)&__conio+$13) -- _deref_pwuc1=_inc__deref_pwuc1 
    inc __conio+$13
    bne !+
    inc __conio+$13+1
  !:
    // cputc::@return
    // }
    // [60] return 
    rts
    // [61] phi from cputc::@3 to cputc::@6 [phi:cputc::@3->cputc::@6]
    // cputc::@6
  __b6:
    // cputln()
    // [62] call cputln
    jsr cputln
    jmp __b7
    // cputc::@5
  __b5:
    // if(__conio.cursor_x >= __conio.width)
    // [63] if(*((char *)&__conio)>=*((char *)&__conio+6)) goto cputc::@8 -- _deref_pbuc1_ge__deref_pbuc2_then_la1 
    lda __conio
    cmp __conio+6
    bcs __b8
    // cputc::@9
    // __conio.cursor_x++;
    // [64] *((char *)&__conio) = ++ *((char *)&__conio) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio
    // __conio.offset++;
    // [65] *((unsigned int *)&__conio+$13) = ++ *((unsigned int *)&__conio+$13) -- _deref_pwuc1=_inc__deref_pwuc1 
    inc __conio+$13
    bne !+
    inc __conio+$13+1
  !:
    // [66] *((unsigned int *)&__conio+$13) = ++ *((unsigned int *)&__conio+$13) -- _deref_pwuc1=_inc__deref_pwuc1 
    inc __conio+$13
    bne !+
    inc __conio+$13+1
  !:
    rts
    // [67] phi from cputc::@5 to cputc::@8 [phi:cputc::@5->cputc::@8]
    // cputc::@8
  __b8:
    // cputln()
    // [68] call cputln
    jsr cputln
    rts
    // [69] phi from cputc to cputc::@1 [phi:cputc->cputc::@1]
    // cputc::@1
  __b1:
    // cputln()
    // [70] call cputln
    jsr cputln
    rts
}
  // main
main: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 0
    .const bank_set_brom2_bank = 0
    .const bank_set_brom3_bank = 0
    .const bank_push_set_bram1_bank = 1
    .const bank_set_brom4_bank = 4
    .const bank_set_brom5_bank = 0
    .label main__105 = $70
    .label main__121 = $2e
    .label main__201 = $be
    .label check_status_smc1_main__0 = $f2
    .label check_status_cx16_rom1_check_status_rom1_main__0 = $e2
    .label check_status_smc3_main__0 = $ec
    .label check_status_cx16_rom2_check_status_rom1_main__0 = $e3
    .label check_status_smc4_main__0 = $e7
    .label check_status_cx16_rom3_check_status_rom1_main__0 = $e6
    .label check_status_smc5_main__0 = $e4
    .label check_status_rom1_main__0 = $bf
    .label check_status_smc6_main__0 = $e5
    .label check_status_roms_all1_check_status_rom1_main__0 = $53
    .label check_status_smc7_main__0 = $66
    .label check_status_vera2_main__0 = $c4
    .label check_status_roms1_check_status_rom1_main__0 = $6d
    .label check_status_smc9_main__0 = $ce
    .label check_status_roms2_check_status_rom1_main__0 = $69
    .label check_status_smc1_return = $f2
    .label check_status_cx16_rom1_check_status_rom1_return = $e2
    .label check_status_smc3_return = $ec
    .label check_status_cx16_rom2_check_status_rom1_return = $e3
    .label check_status_smc4_return = $e7
    .label check_status_cx16_rom3_check_status_rom1_return = $e6
    .label check_status_smc5_return = $e4
    .label ch = $2d
    .label check_status_rom1_return = $bf
    .label check_status_smc6_return = $e5
    .label check_status_roms_all1_check_status_rom1_return = $53
    .label check_status_smc7_return = $66
    .label rom_differences = $30
    .label check_status_vera2_return = $c4
    .label check_status_roms1_check_status_rom1_return = $6d
    .label check_status_smc9_return = $ce
    .label check_status_roms2_check_status_rom1_return = $69
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
    // [74] phi from main::bank_set_brom1 to main::@59 [phi:main::bank_set_brom1->main::@59]
    // main::@59
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
    // [631] phi from main::@59 to display_frame_init_64 [phi:main::@59->display_frame_init_64]
    jsr display_frame_init_64
    // [76] phi from main::@59 to main::@83 [phi:main::@59->main::@83]
    // main::@83
    // display_frame_draw()
    // [77] call display_frame_draw
    // [651] phi from main::@83 to display_frame_draw [phi:main::@83->display_frame_draw]
    jsr display_frame_draw
    // [78] phi from main::@83 to main::@84 [phi:main::@83->main::@84]
    // main::@84
    // display_frame_title("Commander X16 Flash Utility!")
    // [79] call display_frame_title
    // [692] phi from main::@84 to display_frame_title [phi:main::@84->display_frame_title]
    jsr display_frame_title
    // [80] phi from main::@84 to main::display_info_title1 [phi:main::@84->main::display_info_title1]
    // main::display_info_title1
    // cputsxy(INFO_X-2, INFO_Y-2, "# Chip Status    Type   File  / Total Information")
    // [81] call cputsxy
    // [697] phi from main::display_info_title1 to cputsxy [phi:main::display_info_title1->cputsxy]
    // [697] phi cputsxy::s#4 = main::s [phi:main::display_info_title1->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z cputsxy.s
    lda #>s
    sta.z cputsxy.s+1
    // [697] phi cputsxy::y#4 = $11-2 [phi:main::display_info_title1->cputsxy#1] -- vbum1=vbuc1 
    lda #$11-2
    sta cputsxy.y
    // [697] phi cputsxy::x#4 = 4-2 [phi:main::display_info_title1->cputsxy#2] -- vbuz1=vbuc1 
    lda #4-2
    sta.z cputsxy.x
    jsr cputsxy
    // [82] phi from main::display_info_title1 to main::@85 [phi:main::display_info_title1->main::@85]
    // main::@85
    // cputsxy(INFO_X-2, INFO_Y-1, "- ---- --------- ------ ----- / ----- --------------------")
    // [83] call cputsxy
    // [697] phi from main::@85 to cputsxy [phi:main::@85->cputsxy]
    // [697] phi cputsxy::s#4 = main::s1 [phi:main::@85->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s1
    sta.z cputsxy.s
    lda #>s1
    sta.z cputsxy.s+1
    // [697] phi cputsxy::y#4 = $11-1 [phi:main::@85->cputsxy#1] -- vbum1=vbuc1 
    lda #$11-1
    sta cputsxy.y
    // [697] phi cputsxy::x#4 = 4-2 [phi:main::@85->cputsxy#2] -- vbuz1=vbuc1 
    lda #4-2
    sta.z cputsxy.x
    jsr cputsxy
    // [84] phi from main::@85 to main::@60 [phi:main::@85->main::@60]
    // main::@60
    // display_action_progress("Introduction ...")
    // [85] call display_action_progress
    // [704] phi from main::@60 to display_action_progress [phi:main::@60->display_action_progress]
    // [704] phi display_action_progress::info_text#15 = main::info_text [phi:main::@60->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [86] phi from main::@60 to main::@86 [phi:main::@60->main::@86]
    // main::@86
    // display_progress_clear()
    // [87] call display_progress_clear
    // [718] phi from main::@86 to display_progress_clear [phi:main::@86->display_progress_clear]
    jsr display_progress_clear
    // [88] phi from main::@86 to main::@87 [phi:main::@86->main::@87]
    // main::@87
    // display_chip_smc()
    // [89] call display_chip_smc
    // [733] phi from main::@87 to display_chip_smc [phi:main::@87->display_chip_smc]
    jsr display_chip_smc
    // [90] phi from main::@87 to main::@88 [phi:main::@87->main::@88]
    // main::@88
    // display_chip_vera()
    // [91] call display_chip_vera
    // [738] phi from main::@88 to display_chip_vera [phi:main::@88->display_chip_vera]
    jsr display_chip_vera
    // [92] phi from main::@88 to main::@89 [phi:main::@88->main::@89]
    // main::@89
    // display_chip_rom()
    // [93] call display_chip_rom
    // [743] phi from main::@89 to display_chip_rom [phi:main::@89->display_chip_rom]
    jsr display_chip_rom
    // [94] phi from main::@89 to main::@90 [phi:main::@89->main::@90]
    // main::@90
    // display_info_smc(STATUS_COLOR_NONE, NULL)
    // [95] call display_info_smc
    // [762] phi from main::@90 to display_info_smc [phi:main::@90->display_info_smc]
    // [762] phi display_info_smc::info_text#13 = 0 [phi:main::@90->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [762] phi smc_file_size#12 = 0 [phi:main::@90->display_info_smc#1] -- vwum1=vwuc1 
    sta smc_file_size_2
    sta smc_file_size_2+1
    // [762] phi display_info_smc::info_status#13 = BLACK [phi:main::@90->display_info_smc#2] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [96] phi from main::@90 to main::@91 [phi:main::@90->main::@91]
    // main::@91
    // display_info_vera(STATUS_NONE, NULL)
    // [97] call display_info_vera
    // [792] phi from main::@91 to display_info_vera [phi:main::@91->display_info_vera]
    // [792] phi display_info_vera::info_text#10 = 0 [phi:main::@91->display_info_vera#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_vera.info_text
    sta.z display_info_vera.info_text+1
    // [792] phi display_info_vera::info_status#3 = STATUS_NONE [phi:main::@91->display_info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_NONE
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // [98] phi from main::@91 to main::@9 [phi:main::@91->main::@9]
    // [98] phi main::rom_chip#2 = 0 [phi:main::@91->main::@9#0] -- vwum1=vwuc1 
    lda #<0
    sta rom_chip
    sta rom_chip+1
    // main::@9
  __b9:
    // for(unsigned rom_chip=0; rom_chip<8; rom_chip++)
    // [99] if(main::rom_chip#2<8) goto main::@10 -- vwum1_lt_vbuc1_then_la1 
    lda rom_chip+1
    bne !+
    lda rom_chip
    cmp #8
    bcs !__b10+
    jmp __b10
  !__b10:
  !:
    // [100] phi from main::@9 to main::@11 [phi:main::@9->main::@11]
    // main::@11
    // display_progress_text(display_into_briefing_text, display_intro_briefing_count)
    // [101] call display_progress_text
    // [818] phi from main::@11 to display_progress_text [phi:main::@11->display_progress_text]
    // [818] phi display_progress_text::text#10 = display_into_briefing_text [phi:main::@11->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_into_briefing_text
    sta.z display_progress_text.text
    lda #>display_into_briefing_text
    sta.z display_progress_text.text+1
    // [818] phi display_progress_text::lines#7 = display_intro_briefing_count [phi:main::@11->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_intro_briefing_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [102] phi from main::@11 to main::@93 [phi:main::@11->main::@93]
    // main::@93
    // util_wait_space()
    // [103] call util_wait_space
    // [828] phi from main::@93 to util_wait_space [phi:main::@93->util_wait_space]
    jsr util_wait_space
    // [104] phi from main::@93 to main::@94 [phi:main::@93->main::@94]
    // main::@94
    // display_progress_text(display_into_colors_text, display_intro_colors_count)
    // [105] call display_progress_text
    // [818] phi from main::@94 to display_progress_text [phi:main::@94->display_progress_text]
    // [818] phi display_progress_text::text#10 = display_into_colors_text [phi:main::@94->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_into_colors_text
    sta.z display_progress_text.text
    lda #>display_into_colors_text
    sta.z display_progress_text.text+1
    // [818] phi display_progress_text::lines#7 = display_intro_colors_count [phi:main::@94->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_intro_colors_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [106] phi from main::@94 to main::@12 [phi:main::@94->main::@12]
    // [106] phi main::intro_status#2 = 0 [phi:main::@94->main::@12#0] -- vbum1=vbuc1 
    lda #0
    sta intro_status
    // main::@12
  __b12:
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [107] if(main::intro_status#2<$b) goto main::@13 -- vbum1_lt_vbuc1_then_la1 
    lda intro_status
    cmp #$b
    bcs !__b13+
    jmp __b13
  !__b13:
    // [108] phi from main::@12 to main::@14 [phi:main::@12->main::@14]
    // main::@14
    // util_wait_space()
    // [109] call util_wait_space
    // [828] phi from main::@14 to util_wait_space [phi:main::@14->util_wait_space]
    jsr util_wait_space
    // [110] phi from main::@14 to main::@96 [phi:main::@14->main::@96]
    // main::@96
    // display_progress_clear()
    // [111] call display_progress_clear
    // [718] phi from main::@96 to display_progress_clear [phi:main::@96->display_progress_clear]
    jsr display_progress_clear
    // main::SEI1
    // asm
    // asm { sei  }
    sei
    // [113] phi from main::SEI1 to main::@61 [phi:main::SEI1->main::@61]
    // main::@61
    // smc_detect()
    // [114] call smc_detect
    jsr smc_detect
    // [115] smc_detect::return#2 = smc_detect::return#0
    // main::@97
    // smc_bootloader = smc_detect()
    // [116] smc_bootloader#0 = smc_detect::return#2 -- vwum1=vwuz2 
    lda.z smc_detect.return
    sta smc_bootloader
    lda.z smc_detect.return+1
    sta smc_bootloader+1
    // display_chip_smc()
    // [117] call display_chip_smc
    // [733] phi from main::@97 to display_chip_smc [phi:main::@97->display_chip_smc]
    jsr display_chip_smc
    // main::@98
    // if(smc_bootloader == 0x0100)
    // [118] if(smc_bootloader#0==$100) goto main::@1 -- vwum1_eq_vwuc1_then_la1 
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
    // [119] if(smc_bootloader#0==$200) goto main::@18 -- vwum1_eq_vwuc1_then_la1 
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
    // [120] if(smc_bootloader#0>=2+1) goto main::@19 -- vwum1_ge_vbuc1_then_la1 
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
    // [121] phi from main::@16 to main::@17 [phi:main::@16->main::@17]
    // main::@17
    // smc_version(smc_version_string)
    // [122] call smc_version
    jsr smc_version
    // [123] phi from main::@17 to main::@105 [phi:main::@17->main::@105]
    // main::@105
    // sprintf(info_text, "SMC %s, BL v%02x", smc_version_string, smc_bootloader)
    // [124] call snprintf_init
    // [872] phi from main::@105 to snprintf_init [phi:main::@105->snprintf_init]
    // [872] phi snprintf_init::s#25 = info_text [phi:main::@105->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [125] phi from main::@105 to main::@106 [phi:main::@105->main::@106]
    // main::@106
    // sprintf(info_text, "SMC %s, BL v%02x", smc_version_string, smc_bootloader)
    // [126] call printf_str
    // [877] phi from main::@106 to printf_str [phi:main::@106->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:main::@106->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = main::s4 [phi:main::@106->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // [127] phi from main::@106 to main::@107 [phi:main::@106->main::@107]
    // main::@107
    // sprintf(info_text, "SMC %s, BL v%02x", smc_version_string, smc_bootloader)
    // [128] call printf_string
    // [886] phi from main::@107 to printf_string [phi:main::@107->printf_string]
    // [886] phi printf_string::putc#19 = &snputc [phi:main::@107->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [886] phi printf_string::str#19 = smc_version_string [phi:main::@107->printf_string#1] -- pbuz1=pbuc1 
    lda #<smc_version_string
    sta.z printf_string.str
    lda #>smc_version_string
    sta.z printf_string.str+1
    // [886] phi printf_string::format_justify_left#19 = 0 [phi:main::@107->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [886] phi printf_string::format_min_length#19 = 0 [phi:main::@107->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [129] phi from main::@107 to main::@108 [phi:main::@107->main::@108]
    // main::@108
    // sprintf(info_text, "SMC %s, BL v%02x", smc_version_string, smc_bootloader)
    // [130] call printf_str
    // [877] phi from main::@108 to printf_str [phi:main::@108->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:main::@108->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = main::s5 [phi:main::@108->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // main::@109
    // sprintf(info_text, "SMC %s, BL v%02x", smc_version_string, smc_bootloader)
    // [131] printf_uint::uvalue#17 = smc_bootloader#0 -- vwuz1=vwum2 
    lda smc_bootloader
    sta.z printf_uint.uvalue
    lda smc_bootloader+1
    sta.z printf_uint.uvalue+1
    // [132] call printf_uint
    // [911] phi from main::@109 to printf_uint [phi:main::@109->printf_uint]
    // [911] phi printf_uint::format_zero_padding#19 = 1 [phi:main::@109->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [911] phi printf_uint::format_min_length#19 = 2 [phi:main::@109->printf_uint#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uint.format_min_length
    // [911] phi printf_uint::putc#19 = &snputc [phi:main::@109->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [911] phi printf_uint::format_radix#19 = HEXADECIMAL [phi:main::@109->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [911] phi printf_uint::uvalue#19 = printf_uint::uvalue#17 [phi:main::@109->printf_uint#4] -- register_copy 
    jsr printf_uint
    // main::@110
    // sprintf(info_text, "SMC %s, BL v%02x", smc_version_string, smc_bootloader)
    // [133] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [134] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_smc(STATUS_DETECTED, info_text)
    // [136] call display_info_smc
  // All ok, display bootloader version.
    // [762] phi from main::@110 to display_info_smc [phi:main::@110->display_info_smc]
    // [762] phi display_info_smc::info_text#13 = info_text [phi:main::@110->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_smc.info_text
    lda #>@info_text
    sta.z display_info_smc.info_text+1
    // [762] phi smc_file_size#12 = 0 [phi:main::@110->display_info_smc#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size_2
    sta smc_file_size_2+1
    // [762] phi display_info_smc::info_status#13 = STATUS_DETECTED [phi:main::@110->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_DETECTED
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // main::CLI1
  CLI1:
    // asm
    // asm { cli  }
    cli
    // [138] phi from main::CLI1 to main::@62 [phi:main::CLI1->main::@62]
    // main::@62
    // display_chip_vera()
    // [139] call display_chip_vera
  // Detecting VERA FPGA.
    // [738] phi from main::@62 to display_chip_vera [phi:main::@62->display_chip_vera]
    jsr display_chip_vera
    // [140] phi from main::@62 to main::@111 [phi:main::@62->main::@111]
    // main::@111
    // display_info_vera(STATUS_DETECTED, "VERA installed, OK")
    // [141] call display_info_vera
    // [792] phi from main::@111 to display_info_vera [phi:main::@111->display_info_vera]
    // [792] phi display_info_vera::info_text#10 = main::info_text3 [phi:main::@111->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text3
    sta.z display_info_vera.info_text
    lda #>info_text3
    sta.z display_info_vera.info_text+1
    // [792] phi display_info_vera::info_status#3 = STATUS_DETECTED [phi:main::@111->display_info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_DETECTED
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // main::SEI2
    // asm
    // asm { sei  }
    sei
    // [143] phi from main::SEI2 to main::@63 [phi:main::SEI2->main::@63]
    // main::@63
    // rom_detect()
    // [144] call rom_detect
  // Detecting ROM chips
    // [922] phi from main::@63 to rom_detect [phi:main::@63->rom_detect]
    jsr rom_detect
    // [145] phi from main::@63 to main::@112 [phi:main::@63->main::@112]
    // main::@112
    // display_chip_rom()
    // [146] call display_chip_rom
    // [743] phi from main::@112 to display_chip_rom [phi:main::@112->display_chip_rom]
    jsr display_chip_rom
    // [147] phi from main::@112 to main::@20 [phi:main::@112->main::@20]
    // [147] phi main::rom_chip1#2 = 0 [phi:main::@112->main::@20#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip1
    // main::@20
  __b20:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [148] if(main::rom_chip1#2<8) goto main::@21 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip1
    cmp #8
    bcs !__b21+
    jmp __b21
  !__b21:
    // main::CLI2
    // asm
    // asm { cli  }
    cli
    // main::SEI3
    // asm { sei  }
    sei
    // main::check_status_smc1
    // status_smc == status
    // [151] main::check_status_smc1_$0 = status_smc#0 == STATUS_DETECTED -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_DETECTED
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc1_main__0
    // return (unsigned char)(status_smc == status);
    // [152] main::check_status_smc1_return#0 = (char)main::check_status_smc1_$0
    // main::@64
    // if(check_status_smc(STATUS_DETECTED))
    // [153] if(0==main::check_status_smc1_return#0) goto main::CLI3 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_smc1_return
    beq __b7
    // [154] phi from main::@64 to main::@25 [phi:main::@64->main::@25]
    // main::@25
    // smc_read(0)
    // [155] call smc_read
    // [972] phi from main::@25 to smc_read [phi:main::@25->smc_read]
    // [972] phi smc_read::display_progress#19 = 0 [phi:main::@25->smc_read#0] -- vbuz1=vbuc1 
    lda #0
    sta.z smc_read.display_progress
    // [972] phi __errno#35 = 0 [phi:main::@25->smc_read#1] -- vwsz1=vwsc1 
    sta.z __errno
    sta.z __errno+1
    jsr smc_read
    // smc_read(0)
    // [156] smc_read::return#2 = smc_read::return#0
    // main::@113
    // smc_file_size = smc_read(0)
    // [157] smc_file_size#0 = smc_read::return#2 -- vwum1=vwum2 
    lda smc_read.return
    sta smc_file_size
    lda smc_read.return+1
    sta smc_file_size+1
    // if (!smc_file_size)
    // [158] if(0==smc_file_size#0) goto main::@28 -- 0_eq_vwum1_then_la1 
    // In case no file was found, set the status to error and skip to the next, else, mention the amount of bytes read.
    lda smc_file_size
    ora smc_file_size+1
    bne !__b28+
    jmp __b28
  !__b28:
    // main::@26
    // if(smc_file_size > 0x1E00)
    // [159] if(smc_file_size#0>$1e00) goto main::@29 -- vwum1_gt_vwuc1_then_la1 
    // If the smc.bin file size is larger than 0x1E00 then there is an error!
    lda #>$1e00
    cmp smc_file_size+1
    bcs !__b29+
    jmp __b29
  !__b29:
    bne !+
    lda #<$1e00
    cmp smc_file_size
    bcs !__b29+
    jmp __b29
  !__b29:
  !:
    // main::@27
    // [160] smc_file_size#384 = smc_file_size#0 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_FLASH, NULL)
    // [161] call display_info_smc
  // All ok, display the SMC version and bootloader.
    // [762] phi from main::@27 to display_info_smc [phi:main::@27->display_info_smc]
    // [762] phi display_info_smc::info_text#13 = 0 [phi:main::@27->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [762] phi smc_file_size#12 = smc_file_size#384 [phi:main::@27->display_info_smc#1] -- register_copy 
    // [762] phi display_info_smc::info_status#13 = STATUS_FLASH [phi:main::@27->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASH
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [162] phi from main::@27 main::@28 main::@29 to main::CLI3 [phi:main::@27/main::@28/main::@29->main::CLI3]
    // [162] phi smc_file_size#227 = smc_file_size#0 [phi:main::@27/main::@28/main::@29->main::CLI3#0] -- register_copy 
    // [162] phi __errno#243 = __errno#18 [phi:main::@27/main::@28/main::@29->main::CLI3#1] -- register_copy 
    jmp CLI3
    // [162] phi from main::@64 to main::CLI3 [phi:main::@64->main::CLI3]
  __b7:
    // [162] phi smc_file_size#227 = 0 [phi:main::@64->main::CLI3#0] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size
    sta smc_file_size+1
    // [162] phi __errno#243 = 0 [phi:main::@64->main::CLI3#1] -- vwsz1=vwsc1 
    sta.z __errno
    sta.z __errno+1
    // main::CLI3
  CLI3:
    // asm
    // asm { cli  }
    cli
    // main::SEI4
    // asm { sei  }
    sei
    // [165] phi from main::SEI4 to main::@30 [phi:main::SEI4->main::@30]
    // [165] phi __errno#112 = __errno#243 [phi:main::SEI4->main::@30#0] -- register_copy 
    // [165] phi main::rom_chip2#10 = 0 [phi:main::SEI4->main::@30#1] -- vbum1=vbuc1 
    lda #0
    sta rom_chip2
  // We loop all the possible ROM chip slots on the board and on the extension card,
  // and we check the file contents.
  // Any error identified gets reported and this chip will not be flashed.
  // In case of ROM0.BIN in error, no flashing will be done!
    // main::@30
  __b30:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [166] if(main::rom_chip2#10<8) goto main::bank_set_brom2 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip2
    cmp #8
    bcs !bank_set_brom2+
    jmp bank_set_brom2
  !bank_set_brom2:
    // main::bank_set_brom3
    // BROM = bank
    // [167] BROM = main::bank_set_brom3_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom3_bank
    sta.z BROM
    // main::CLI4
    // asm
    // asm { cli  }
    cli
    // main::check_status_smc2
    // status_smc == status
    // [169] main::check_status_smc2_$0 = status_smc#0 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc2_main__0
    // return (unsigned char)(status_smc == status);
    // [170] main::check_status_smc2_return#0 = (char)main::check_status_smc2_$0
    // [171] phi from main::check_status_smc2 to main::check_status_cx16_rom1 [phi:main::check_status_smc2->main::check_status_cx16_rom1]
    // main::check_status_cx16_rom1
    // main::check_status_cx16_rom1_check_status_rom1
    // status_rom[rom_chip] == status
    // [172] main::check_status_cx16_rom1_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_cx16_rom1_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [173] main::check_status_cx16_rom1_check_status_rom1_return#0 = (char)main::check_status_cx16_rom1_check_status_rom1_$0
    // main::@66
    // if(!check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH))
    // [174] if(0!=main::check_status_smc2_return#0) goto main::check_status_smc3 -- 0_neq_vbum1_then_la1 
    lda check_status_smc2_return
    bne check_status_smc3
    // main::@185
    // [175] if(0!=main::check_status_cx16_rom1_check_status_rom1_return#0) goto main::@37 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_cx16_rom1_check_status_rom1_return
    beq !__b37+
    jmp __b37
  !__b37:
    // main::check_status_smc3
  check_status_smc3:
    // status_smc == status
    // [176] main::check_status_smc3_$0 = status_smc#0 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc3_main__0
    // return (unsigned char)(status_smc == status);
    // [177] main::check_status_smc3_return#0 = (char)main::check_status_smc3_$0
    // [178] phi from main::check_status_smc3 to main::check_status_cx16_rom2 [phi:main::check_status_smc3->main::check_status_cx16_rom2]
    // main::check_status_cx16_rom2
    // main::check_status_cx16_rom2_check_status_rom1
    // status_rom[rom_chip] == status
    // [179] main::check_status_cx16_rom2_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_cx16_rom2_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [180] main::check_status_cx16_rom2_check_status_rom1_return#0 = (char)main::check_status_cx16_rom2_check_status_rom1_$0
    // main::@69
    // if(check_status_smc(STATUS_FLASH) && !check_status_cx16_rom(STATUS_FLASH))
    // [181] if(0==main::check_status_smc3_return#0) goto main::check_status_smc4 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_smc3_return
    beq check_status_smc4
    // main::@186
    // [182] if(0==main::check_status_cx16_rom2_check_status_rom1_return#0) goto main::@3 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_cx16_rom2_check_status_rom1_return
    bne !__b3+
    jmp __b3
  !__b3:
    // main::check_status_smc4
  check_status_smc4:
    // status_smc == status
    // [183] main::check_status_smc4_$0 = status_smc#0 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc4_main__0
    // return (unsigned char)(status_smc == status);
    // [184] main::check_status_smc4_return#0 = (char)main::check_status_smc4_$0
    // [185] phi from main::check_status_smc4 to main::check_status_cx16_rom3 [phi:main::check_status_smc4->main::check_status_cx16_rom3]
    // main::check_status_cx16_rom3
    // main::check_status_cx16_rom3_check_status_rom1
    // status_rom[rom_chip] == status
    // [186] main::check_status_cx16_rom3_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_cx16_rom3_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [187] main::check_status_cx16_rom3_check_status_rom1_return#0 = (char)main::check_status_cx16_rom3_check_status_rom1_$0
    // [188] phi from main::check_status_cx16_rom3_check_status_rom1 to main::check_status_card_roms1 [phi:main::check_status_cx16_rom3_check_status_rom1->main::check_status_card_roms1]
    // main::check_status_card_roms1
    // [189] phi from main::check_status_card_roms1 to main::check_status_card_roms1_@1 [phi:main::check_status_card_roms1->main::check_status_card_roms1_@1]
    // [189] phi main::check_status_card_roms1_rom_chip#2 = 1 [phi:main::check_status_card_roms1->main::check_status_card_roms1_@1#0] -- vbum1=vbuc1 
    lda #1
    sta check_status_card_roms1_rom_chip
    // main::check_status_card_roms1_@1
  check_status_card_roms1___b1:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [190] if(main::check_status_card_roms1_rom_chip#2<8) goto main::check_status_card_roms1_check_status_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda check_status_card_roms1_rom_chip
    cmp #8
    bcs !check_status_card_roms1_check_status_rom1+
    jmp check_status_card_roms1_check_status_rom1
  !check_status_card_roms1_check_status_rom1:
    // [191] phi from main::check_status_card_roms1_@1 to main::check_status_card_roms1_@return [phi:main::check_status_card_roms1_@1->main::check_status_card_roms1_@return]
    // [191] phi main::check_status_card_roms1_return#2 = STATUS_NONE [phi:main::check_status_card_roms1_@1->main::check_status_card_roms1_@return#0] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta check_status_card_roms1_return
    // main::check_status_card_roms1_@return
    // main::@70
  __b70:
    // if(check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH) || check_status_card_roms(STATUS_FLASH))
    // [192] if(0==main::check_status_smc4_return#0) goto main::@187 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_smc4_return
    beq __b187
    // main::@188
    // [193] if(0!=main::check_status_cx16_rom3_check_status_rom1_return#0) goto main::@4 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_cx16_rom3_check_status_rom1_return
    beq !__b4+
    jmp __b4
  !__b4:
    // main::@187
  __b187:
    // [194] if(0!=main::check_status_card_roms1_return#2) goto main::@4 -- 0_neq_vbum1_then_la1 
    lda check_status_card_roms1_return
    beq !__b4+
    jmp __b4
  !__b4:
    // main::SEI5
  SEI5:
    // asm
    // asm { sei  }
    sei
    // main::check_status_smc5
    // status_smc == status
    // [196] main::check_status_smc5_$0 = status_smc#0 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc5_main__0
    // return (unsigned char)(status_smc == status);
    // [197] main::check_status_smc5_return#0 = (char)main::check_status_smc5_$0
    // [198] phi from main::check_status_smc5 to main::check_status_cx16_rom4 [phi:main::check_status_smc5->main::check_status_cx16_rom4]
    // main::check_status_cx16_rom4
    // main::check_status_cx16_rom4_check_status_rom1
    // status_rom[rom_chip] == status
    // [199] main::check_status_cx16_rom4_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vbom1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_cx16_rom4_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [200] main::check_status_cx16_rom4_check_status_rom1_return#0 = (char)main::check_status_cx16_rom4_check_status_rom1_$0
    // main::@71
    // if (check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH))
    // [201] if(0==main::check_status_smc5_return#0) goto main::@2 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_smc5_return
    beq __b2
    // main::@189
    // [202] if(0!=main::check_status_cx16_rom4_check_status_rom1_return#0) goto main::@6 -- 0_neq_vbum1_then_la1 
    lda check_status_cx16_rom4_check_status_rom1_return
    beq !__b6+
    jmp __b6
  !__b6:
    // [203] phi from main::@189 to main::@2 [phi:main::@189->main::@2]
    // [203] phi from main::@146 main::@41 main::@71 main::@8 to main::@2 [phi:main::@146/main::@41/main::@71/main::@8->main::@2]
    // [203] phi __errno#400 = __errno#18 [phi:main::@146/main::@41/main::@71/main::@8->main::@2#0] -- register_copy 
    // main::@2
  __b2:
    // [204] phi from main::@2 to main::@42 [phi:main::@2->main::@42]
    // [204] phi __errno#114 = __errno#400 [phi:main::@2->main::@42#0] -- register_copy 
    // [204] phi main::rom_chip4#10 = 7 [phi:main::@2->main::@42#1] -- vbum1=vbuc1 
    lda #7
    sta rom_chip4
  // Flash the ROM chips. 
  // We loop first all the ROM chips and read the file contents.
  // Then we verify the file contents and flash the ROM only for the differences.
  // If the file contents are the same as the ROM contents, then no flashing is required.
  // IMPORTANT! We start to flash the ROMs on the extension card.
  // The last ROM flashed is the CX16 ROM on the CX16 board!
    // main::@42
  __b42:
    // for(unsigned char rom_chip = 7; rom_chip != 255; rom_chip--)
    // [205] if(main::rom_chip4#10!=$ff) goto main::check_status_rom1 -- vbum1_neq_vbuc1_then_la1 
    lda #$ff
    cmp rom_chip4
    beq !check_status_rom1+
    jmp check_status_rom1
  !check_status_rom1:
    // main::bank_set_brom4
    // BROM = bank
    // [206] BROM = main::bank_set_brom4_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom4_bank
    sta.z BROM
    // main::CLI5
    // asm
    // asm { cli  }
    cli
    // main::check_status_smc6
    // status_smc == status
    // [208] main::check_status_smc6_$0 = status_smc#0 == STATUS_SKIP -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc6_main__0
    // return (unsigned char)(status_smc == status);
    // [209] main::check_status_smc6_return#0 = (char)main::check_status_smc6_$0
    // main::check_status_vera1
    // status_vera == status
    // [210] main::check_status_vera1_$0 = status_vera#0 == STATUS_SKIP -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_vera1_main__0
    // return (unsigned char)(status_vera == status);
    // [211] main::check_status_vera1_return#0 = (char)main::check_status_vera1_$0
    // [212] phi from main::check_status_vera1 to main::check_status_roms_all1 [phi:main::check_status_vera1->main::check_status_roms_all1]
    // main::check_status_roms_all1
    // [213] phi from main::check_status_roms_all1 to main::check_status_roms_all1_@1 [phi:main::check_status_roms_all1->main::check_status_roms_all1_@1]
    // [213] phi main::check_status_roms_all1_rom_chip#2 = 0 [phi:main::check_status_roms_all1->main::check_status_roms_all1_@1#0] -- vbum1=vbuc1 
    lda #0
    sta check_status_roms_all1_rom_chip
    // main::check_status_roms_all1_@1
  check_status_roms_all1___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [214] if(main::check_status_roms_all1_rom_chip#2<8) goto main::check_status_roms_all1_check_status_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda check_status_roms_all1_rom_chip
    cmp #8
    bcs !check_status_roms_all1_check_status_rom1+
    jmp check_status_roms_all1_check_status_rom1
  !check_status_roms_all1_check_status_rom1:
    // [215] phi from main::check_status_roms_all1_@1 to main::check_status_roms_all1_@return [phi:main::check_status_roms_all1_@1->main::check_status_roms_all1_@return]
    // [215] phi main::check_status_roms_all1_return#2 = 1 [phi:main::check_status_roms_all1_@1->main::check_status_roms_all1_@return#0] -- vbum1=vbuc1 
    lda #1
    sta check_status_roms_all1_return
    // main::check_status_roms_all1_@return
    // main::@73
  __b73:
    // if(check_status_smc(STATUS_SKIP) && check_status_vera(STATUS_SKIP) && check_status_roms_all(STATUS_SKIP))
    // [216] if(0==main::check_status_smc6_return#0) goto main::check_status_smc8 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_smc6_return
    beq check_status_smc8
    // main::@191
    // [217] if(0==main::check_status_vera1_return#0) goto main::check_status_smc8 -- 0_eq_vbum1_then_la1 
    lda check_status_vera1_return
    beq check_status_smc8
    // main::@190
    // [218] if(0!=main::check_status_roms_all1_return#2) goto main::vera_display_set_border_color1 -- 0_neq_vbum1_then_la1 
    lda check_status_roms_all1_return
    beq !vera_display_set_border_color1+
    jmp vera_display_set_border_color1
  !vera_display_set_border_color1:
    // main::check_status_smc8
  check_status_smc8:
    // status_smc == status
    // [219] main::check_status_smc8_$0 = status_smc#0 == STATUS_ERROR -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc8_main__0
    // return (unsigned char)(status_smc == status);
    // [220] main::check_status_smc8_return#0 = (char)main::check_status_smc8_$0
    // main::check_status_vera2
    // status_vera == status
    // [221] main::check_status_vera2_$0 = status_vera#0 == STATUS_ERROR -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_vera2_main__0
    // return (unsigned char)(status_vera == status);
    // [222] main::check_status_vera2_return#0 = (char)main::check_status_vera2_$0
    // [223] phi from main::check_status_vera2 to main::check_status_roms1 [phi:main::check_status_vera2->main::check_status_roms1]
    // main::check_status_roms1
    // [224] phi from main::check_status_roms1 to main::check_status_roms1_@1 [phi:main::check_status_roms1->main::check_status_roms1_@1]
    // [224] phi main::check_status_roms1_rom_chip#2 = 0 [phi:main::check_status_roms1->main::check_status_roms1_@1#0] -- vbum1=vbuc1 
    lda #0
    sta check_status_roms1_rom_chip
    // main::check_status_roms1_@1
  check_status_roms1___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [225] if(main::check_status_roms1_rom_chip#2<8) goto main::check_status_roms1_check_status_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda check_status_roms1_rom_chip
    cmp #8
    bcs !check_status_roms1_check_status_rom1+
    jmp check_status_roms1_check_status_rom1
  !check_status_roms1_check_status_rom1:
    // [226] phi from main::check_status_roms1_@1 to main::check_status_roms1_@return [phi:main::check_status_roms1_@1->main::check_status_roms1_@return]
    // [226] phi main::check_status_roms1_return#2 = STATUS_NONE [phi:main::check_status_roms1_@1->main::check_status_roms1_@return#0] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta check_status_roms1_return
    // main::check_status_roms1_@return
    // main::@77
  __b77:
    // if(check_status_smc(STATUS_ERROR) || check_status_vera(STATUS_ERROR) || check_status_roms(STATUS_ERROR))
    // [227] if(0!=main::check_status_smc8_return#0) goto main::vera_display_set_border_color2 -- 0_neq_vbum1_then_la1 
    lda check_status_smc8_return
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::@195
    // [228] if(0!=main::check_status_vera2_return#0) goto main::vera_display_set_border_color2 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_vera2_return
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::@194
    // [229] if(0!=main::check_status_roms1_return#2) goto main::vera_display_set_border_color2 -- 0_neq_vbum1_then_la1 
    lda check_status_roms1_return
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::check_status_smc9
    // status_smc == status
    // [230] main::check_status_smc9_$0 = status_smc#0 == STATUS_ISSUE -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc9_main__0
    // return (unsigned char)(status_smc == status);
    // [231] main::check_status_smc9_return#0 = (char)main::check_status_smc9_$0
    // main::check_status_vera3
    // status_vera == status
    // [232] main::check_status_vera3_$0 = status_vera#0 == STATUS_ISSUE -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_vera3_main__0
    // return (unsigned char)(status_vera == status);
    // [233] main::check_status_vera3_return#0 = (char)main::check_status_vera3_$0
    // [234] phi from main::check_status_vera3 to main::check_status_roms2 [phi:main::check_status_vera3->main::check_status_roms2]
    // main::check_status_roms2
    // [235] phi from main::check_status_roms2 to main::check_status_roms2_@1 [phi:main::check_status_roms2->main::check_status_roms2_@1]
    // [235] phi main::check_status_roms2_rom_chip#2 = 0 [phi:main::check_status_roms2->main::check_status_roms2_@1#0] -- vbum1=vbuc1 
    lda #0
    sta check_status_roms2_rom_chip
    // main::check_status_roms2_@1
  check_status_roms2___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [236] if(main::check_status_roms2_rom_chip#2<8) goto main::check_status_roms2_check_status_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda check_status_roms2_rom_chip
    cmp #8
    bcs !check_status_roms2_check_status_rom1+
    jmp check_status_roms2_check_status_rom1
  !check_status_roms2_check_status_rom1:
    // [237] phi from main::check_status_roms2_@1 to main::check_status_roms2_@return [phi:main::check_status_roms2_@1->main::check_status_roms2_@return]
    // [237] phi main::check_status_roms2_return#2 = STATUS_NONE [phi:main::check_status_roms2_@1->main::check_status_roms2_@return#0] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta check_status_roms2_return
    // main::check_status_roms2_@return
    // main::@79
  __b79:
    // if(check_status_smc(STATUS_ISSUE) || check_status_vera(STATUS_ISSUE) || check_status_roms(STATUS_ISSUE))
    // [238] if(0!=main::check_status_smc9_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc9_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::@197
    // [239] if(0!=main::check_status_vera3_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbum1_then_la1 
    lda check_status_vera3_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::@196
    // [240] if(0!=main::check_status_roms2_return#2) goto main::vera_display_set_border_color3 -- 0_neq_vbum1_then_la1 
    lda check_status_roms2_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::vera_display_set_border_color4
    // *VERA_CTRL &= ~VERA_DCSEL
    // [241] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [242] *VERA_DC_BORDER = GREEN -- _deref_pbuc1=vbuc2 
    lda #GREEN
    sta VERA_DC_BORDER
    // [243] phi from main::vera_display_set_border_color4 to main::@81 [phi:main::vera_display_set_border_color4->main::@81]
    // main::@81
    // display_action_progress("Your CX16 update is a success!")
    // [244] call display_action_progress
    // [704] phi from main::@81 to display_action_progress [phi:main::@81->display_action_progress]
    // [704] phi display_action_progress::info_text#15 = main::info_text29 [phi:main::@81->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text29
    sta.z display_action_progress.info_text
    lda #>info_text29
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::check_status_smc10
    // status_smc == status
    // [245] main::check_status_smc10_$0 = status_smc#0 == STATUS_FLASHED -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASHED
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc10_main__0
    // return (unsigned char)(status_smc == status);
    // [246] main::check_status_smc10_return#0 = (char)main::check_status_smc10_$0
    // main::@82
    // if(check_status_smc(STATUS_FLASHED))
    // [247] if(0!=main::check_status_smc10_return#0) goto main::@51 -- 0_neq_vbum1_then_la1 
    lda check_status_smc10_return
    beq !__b51+
    jmp __b51
  !__b51:
    // [248] phi from main::@82 to main::@50 [phi:main::@82->main::@50]
    // main::@50
    // display_progress_text(display_debriefing_text_rom, display_debriefing_count_rom)
    // [249] call display_progress_text
    // [818] phi from main::@50 to display_progress_text [phi:main::@50->display_progress_text]
    // [818] phi display_progress_text::text#10 = display_debriefing_text_rom [phi:main::@50->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_debriefing_text_rom
    sta.z display_progress_text.text
    lda #>display_debriefing_text_rom
    sta.z display_progress_text.text+1
    // [818] phi display_progress_text::lines#7 = display_debriefing_count_rom [phi:main::@50->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_debriefing_count_rom
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [250] phi from main::@178 main::@50 main::@76 main::@80 to main::@56 [phi:main::@178/main::@50/main::@76/main::@80->main::@56]
  __b8:
    // [250] phi main::w1#2 = $c8 [phi:main::@178/main::@50/main::@76/main::@80->main::@56#0] -- vbum1=vbuc1 
    lda #$c8
    sta w1
    // main::@56
  __b56:
    // for (unsigned char w=200; w>0; w--)
    // [251] if(main::w1#2>0) goto main::@57 -- vbum1_gt_0_then_la1 
    lda w1
    bne __b57
    // [252] phi from main::@56 to main::@58 [phi:main::@56->main::@58]
    // main::@58
    // system_reset()
    // [253] call system_reset
    // [1030] phi from main::@58 to system_reset [phi:main::@58->system_reset]
    jsr system_reset
    // main::@return
    // }
    // [254] return 
    rts
    // [255] phi from main::@56 to main::@57 [phi:main::@56->main::@57]
    // main::@57
  __b57:
    // wait_moment()
    // [256] call wait_moment
    // [1035] phi from main::@57 to wait_moment [phi:main::@57->wait_moment]
    jsr wait_moment
    // [257] phi from main::@57 to main::@179 [phi:main::@57->main::@179]
    // main::@179
    // sprintf(info_text, "(%u) Your CX16 will reset ...", w)
    // [258] call snprintf_init
    // [872] phi from main::@179 to snprintf_init [phi:main::@179->snprintf_init]
    // [872] phi snprintf_init::s#25 = info_text [phi:main::@179->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [259] phi from main::@179 to main::@180 [phi:main::@179->main::@180]
    // main::@180
    // sprintf(info_text, "(%u) Your CX16 will reset ...", w)
    // [260] call printf_str
    // [877] phi from main::@180 to printf_str [phi:main::@180->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:main::@180->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = main::s18 [phi:main::@180->printf_str#1] -- pbuz1=pbuc1 
    lda #<s18
    sta.z printf_str.s
    lda #>s18
    sta.z printf_str.s+1
    jsr printf_str
    // main::@181
    // sprintf(info_text, "(%u) Your CX16 will reset ...", w)
    // [261] printf_uchar::uvalue#9 = main::w1#2 -- vbuz1=vbum2 
    lda w1
    sta.z printf_uchar.uvalue
    // [262] call printf_uchar
    // [1040] phi from main::@181 to printf_uchar [phi:main::@181->printf_uchar]
    // [1040] phi printf_uchar::format_zero_padding#10 = 0 [phi:main::@181->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1040] phi printf_uchar::format_min_length#10 = 0 [phi:main::@181->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1040] phi printf_uchar::putc#10 = &snputc [phi:main::@181->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1040] phi printf_uchar::format_radix#10 = DECIMAL [phi:main::@181->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1040] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#9 [phi:main::@181->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [263] phi from main::@181 to main::@182 [phi:main::@181->main::@182]
    // main::@182
    // sprintf(info_text, "(%u) Your CX16 will reset ...", w)
    // [264] call printf_str
    // [877] phi from main::@182 to printf_str [phi:main::@182->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:main::@182->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = main::s22 [phi:main::@182->printf_str#1] -- pbuz1=pbuc1 
    lda #<s22
    sta.z printf_str.s
    lda #>s22
    sta.z printf_str.s+1
    jsr printf_str
    // main::@183
    // sprintf(info_text, "(%u) Your CX16 will reset ...", w)
    // [265] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [266] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [268] call display_action_text
    // [1051] phi from main::@183 to display_action_text [phi:main::@183->display_action_text]
    // [1051] phi display_action_text::info_text#19 = info_text [phi:main::@183->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@184
    // for (unsigned char w=200; w>0; w--)
    // [269] main::w1#1 = -- main::w1#2 -- vbum1=_dec_vbum1 
    dec w1
    // [250] phi from main::@184 to main::@56 [phi:main::@184->main::@56]
    // [250] phi main::w1#2 = main::w1#1 [phi:main::@184->main::@56#0] -- register_copy 
    jmp __b56
    // [270] phi from main::@82 to main::@51 [phi:main::@82->main::@51]
    // main::@51
  __b51:
    // display_progress_text(display_debriefing_text_smc, display_debriefing_count_smc)
    // [271] call display_progress_text
    // [818] phi from main::@51 to display_progress_text [phi:main::@51->display_progress_text]
    // [818] phi display_progress_text::text#10 = display_debriefing_text_smc [phi:main::@51->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_debriefing_text_smc
    sta.z display_progress_text.text
    lda #>display_debriefing_text_smc
    sta.z display_progress_text.text+1
    // [818] phi display_progress_text::lines#7 = display_debriefing_count_smc [phi:main::@51->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_debriefing_count_smc
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [272] phi from main::@51 to main::@52 [phi:main::@51->main::@52]
    // [272] phi main::w#2 = $f0 [phi:main::@51->main::@52#0] -- vbum1=vbuc1 
    lda #$f0
    sta w
    // main::@52
  __b52:
    // for (unsigned char w=240; w>0; w--)
    // [273] if(main::w#2>0) goto main::@53 -- vbum1_gt_0_then_la1 
    lda w
    bne __b53
    // [274] phi from main::@52 to main::@54 [phi:main::@52->main::@54]
    // main::@54
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [275] call snprintf_init
    // [872] phi from main::@54 to snprintf_init [phi:main::@54->snprintf_init]
    // [872] phi snprintf_init::s#25 = info_text [phi:main::@54->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [276] phi from main::@54 to main::@176 [phi:main::@54->main::@176]
    // main::@176
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [277] call printf_str
    // [877] phi from main::@176 to printf_str [phi:main::@176->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:main::@176->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = main::s20 [phi:main::@176->printf_str#1] -- pbuz1=pbuc1 
    lda #<s20
    sta.z printf_str.s
    lda #>s20
    sta.z printf_str.s+1
    jsr printf_str
    // main::@177
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [278] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [279] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [281] call display_action_text
    // [1051] phi from main::@177 to display_action_text [phi:main::@177->display_action_text]
    // [1051] phi display_action_text::info_text#19 = info_text [phi:main::@177->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [282] phi from main::@177 to main::@178 [phi:main::@177->main::@178]
    // main::@178
    // smc_reset()
    // [283] call smc_reset
    // [1065] phi from main::@178 to smc_reset [phi:main::@178->smc_reset]
    jsr smc_reset
    jmp __b8
    // [284] phi from main::@52 to main::@53 [phi:main::@52->main::@53]
    // main::@53
  __b53:
    // wait_moment()
    // [285] call wait_moment
    // [1035] phi from main::@53 to wait_moment [phi:main::@53->wait_moment]
    jsr wait_moment
    // [286] phi from main::@53 to main::@170 [phi:main::@53->main::@170]
    // main::@170
    // sprintf(info_text, "(%u) Please read carefully the below ...", w)
    // [287] call snprintf_init
    // [872] phi from main::@170 to snprintf_init [phi:main::@170->snprintf_init]
    // [872] phi snprintf_init::s#25 = info_text [phi:main::@170->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [288] phi from main::@170 to main::@171 [phi:main::@170->main::@171]
    // main::@171
    // sprintf(info_text, "(%u) Please read carefully the below ...", w)
    // [289] call printf_str
    // [877] phi from main::@171 to printf_str [phi:main::@171->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:main::@171->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = main::s18 [phi:main::@171->printf_str#1] -- pbuz1=pbuc1 
    lda #<s18
    sta.z printf_str.s
    lda #>s18
    sta.z printf_str.s+1
    jsr printf_str
    // main::@172
    // sprintf(info_text, "(%u) Please read carefully the below ...", w)
    // [290] printf_uchar::uvalue#8 = main::w#2 -- vbuz1=vbum2 
    lda w
    sta.z printf_uchar.uvalue
    // [291] call printf_uchar
    // [1040] phi from main::@172 to printf_uchar [phi:main::@172->printf_uchar]
    // [1040] phi printf_uchar::format_zero_padding#10 = 0 [phi:main::@172->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1040] phi printf_uchar::format_min_length#10 = 0 [phi:main::@172->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1040] phi printf_uchar::putc#10 = &snputc [phi:main::@172->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1040] phi printf_uchar::format_radix#10 = DECIMAL [phi:main::@172->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1040] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#8 [phi:main::@172->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [292] phi from main::@172 to main::@173 [phi:main::@172->main::@173]
    // main::@173
    // sprintf(info_text, "(%u) Please read carefully the below ...", w)
    // [293] call printf_str
    // [877] phi from main::@173 to printf_str [phi:main::@173->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:main::@173->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = main::s19 [phi:main::@173->printf_str#1] -- pbuz1=pbuc1 
    lda #<s19
    sta.z printf_str.s
    lda #>s19
    sta.z printf_str.s+1
    jsr printf_str
    // main::@174
    // sprintf(info_text, "(%u) Please read carefully the below ...", w)
    // [294] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [295] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [297] call display_action_text
    // [1051] phi from main::@174 to display_action_text [phi:main::@174->display_action_text]
    // [1051] phi display_action_text::info_text#19 = info_text [phi:main::@174->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@175
    // for (unsigned char w=240; w>0; w--)
    // [298] main::w#1 = -- main::w#2 -- vbum1=_dec_vbum1 
    dec w
    // [272] phi from main::@175 to main::@52 [phi:main::@175->main::@52]
    // [272] phi main::w#2 = main::w#1 [phi:main::@175->main::@52#0] -- register_copy 
    jmp __b52
    // main::vera_display_set_border_color3
  vera_display_set_border_color3:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [299] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [300] *VERA_DC_BORDER = YELLOW -- _deref_pbuc1=vbuc2 
    lda #YELLOW
    sta VERA_DC_BORDER
    // [301] phi from main::vera_display_set_border_color3 to main::@80 [phi:main::vera_display_set_border_color3->main::@80]
    // main::@80
    // display_action_progress("Update issues, your CX16 is not updated!")
    // [302] call display_action_progress
    // [704] phi from main::@80 to display_action_progress [phi:main::@80->display_action_progress]
    // [704] phi display_action_progress::info_text#15 = main::info_text28 [phi:main::@80->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text28
    sta.z display_action_progress.info_text
    lda #>info_text28
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    jmp __b8
    // main::check_status_roms2_check_status_rom1
  check_status_roms2_check_status_rom1:
    // status_rom[rom_chip] == status
    // [303] main::check_status_roms2_check_status_rom1_$0 = status_rom[main::check_status_roms2_rom_chip#2] == STATUS_ISSUE -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_ISSUE
    ldy check_status_roms2_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_roms2_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [304] main::check_status_roms2_check_status_rom1_return#0 = (char)main::check_status_roms2_check_status_rom1_$0
    // main::check_status_roms2_@11
    // if(check_status_rom(rom_chip, status))
    // [305] if(0==main::check_status_roms2_check_status_rom1_return#0) goto main::check_status_roms2_@4 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_roms2_check_status_rom1_return
    beq check_status_roms2___b4
    // [237] phi from main::check_status_roms2_@11 to main::check_status_roms2_@return [phi:main::check_status_roms2_@11->main::check_status_roms2_@return]
    // [237] phi main::check_status_roms2_return#2 = STATUS_ISSUE [phi:main::check_status_roms2_@11->main::check_status_roms2_@return#0] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta check_status_roms2_return
    jmp __b79
    // main::check_status_roms2_@4
  check_status_roms2___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [306] main::check_status_roms2_rom_chip#1 = ++ main::check_status_roms2_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_status_roms2_rom_chip
    // [235] phi from main::check_status_roms2_@4 to main::check_status_roms2_@1 [phi:main::check_status_roms2_@4->main::check_status_roms2_@1]
    // [235] phi main::check_status_roms2_rom_chip#2 = main::check_status_roms2_rom_chip#1 [phi:main::check_status_roms2_@4->main::check_status_roms2_@1#0] -- register_copy 
    jmp check_status_roms2___b1
    // main::vera_display_set_border_color2
  vera_display_set_border_color2:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [307] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [308] *VERA_DC_BORDER = RED -- _deref_pbuc1=vbuc2 
    lda #RED
    sta VERA_DC_BORDER
    // [309] phi from main::vera_display_set_border_color2 to main::@78 [phi:main::vera_display_set_border_color2->main::@78]
    // main::@78
    // display_action_progress("Update Failure! Your CX16 may be bricked!")
    // [310] call display_action_progress
    // [704] phi from main::@78 to display_action_progress [phi:main::@78->display_action_progress]
    // [704] phi display_action_progress::info_text#15 = main::info_text26 [phi:main::@78->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text26
    sta.z display_action_progress.info_text
    lda #>info_text26
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [311] phi from main::@78 to main::@169 [phi:main::@78->main::@169]
    // main::@169
    // display_action_text("Take a foto of this screen. And shut down power ...")
    // [312] call display_action_text
    // [1051] phi from main::@169 to display_action_text [phi:main::@169->display_action_text]
    // [1051] phi display_action_text::info_text#19 = main::info_text27 [phi:main::@169->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text27
    sta.z display_action_text.info_text
    lda #>info_text27
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [313] phi from main::@169 main::@55 to main::@55 [phi:main::@169/main::@55->main::@55]
    // main::@55
  __b55:
    jmp __b55
    // main::check_status_roms1_check_status_rom1
  check_status_roms1_check_status_rom1:
    // status_rom[rom_chip] == status
    // [314] main::check_status_roms1_check_status_rom1_$0 = status_rom[main::check_status_roms1_rom_chip#2] == STATUS_ERROR -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_ERROR
    ldy check_status_roms1_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_roms1_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [315] main::check_status_roms1_check_status_rom1_return#0 = (char)main::check_status_roms1_check_status_rom1_$0
    // main::check_status_roms1_@11
    // if(check_status_rom(rom_chip, status))
    // [316] if(0==main::check_status_roms1_check_status_rom1_return#0) goto main::check_status_roms1_@4 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_roms1_check_status_rom1_return
    beq check_status_roms1___b4
    // [226] phi from main::check_status_roms1_@11 to main::check_status_roms1_@return [phi:main::check_status_roms1_@11->main::check_status_roms1_@return]
    // [226] phi main::check_status_roms1_return#2 = STATUS_ERROR [phi:main::check_status_roms1_@11->main::check_status_roms1_@return#0] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta check_status_roms1_return
    jmp __b77
    // main::check_status_roms1_@4
  check_status_roms1___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [317] main::check_status_roms1_rom_chip#1 = ++ main::check_status_roms1_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_status_roms1_rom_chip
    // [224] phi from main::check_status_roms1_@4 to main::check_status_roms1_@1 [phi:main::check_status_roms1_@4->main::check_status_roms1_@1]
    // [224] phi main::check_status_roms1_rom_chip#2 = main::check_status_roms1_rom_chip#1 [phi:main::check_status_roms1_@4->main::check_status_roms1_@1#0] -- register_copy 
    jmp check_status_roms1___b1
    // main::vera_display_set_border_color1
  vera_display_set_border_color1:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [318] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [319] *VERA_DC_BORDER = BLACK -- _deref_pbuc1=vbuc2 
    lda #BLACK
    sta VERA_DC_BORDER
    // [320] phi from main::vera_display_set_border_color1 to main::@76 [phi:main::vera_display_set_border_color1->main::@76]
    // main::@76
    // display_action_progress("The update has been cancelled!")
    // [321] call display_action_progress
    // [704] phi from main::@76 to display_action_progress [phi:main::@76->display_action_progress]
    // [704] phi display_action_progress::info_text#15 = main::info_text25 [phi:main::@76->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text25
    sta.z display_action_progress.info_text
    lda #>info_text25
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    jmp __b8
    // main::check_status_roms_all1_check_status_rom1
  check_status_roms_all1_check_status_rom1:
    // status_rom[rom_chip] == status
    // [322] main::check_status_roms_all1_check_status_rom1_$0 = status_rom[main::check_status_roms_all1_rom_chip#2] == STATUS_SKIP -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_SKIP
    ldy check_status_roms_all1_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_roms_all1_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [323] main::check_status_roms_all1_check_status_rom1_return#0 = (char)main::check_status_roms_all1_check_status_rom1_$0
    // main::check_status_roms_all1_@11
    // if(check_status_rom(rom_chip, status) != status)
    // [324] if(main::check_status_roms_all1_check_status_rom1_return#0==STATUS_SKIP) goto main::check_status_roms_all1_@4 -- vbuz1_eq_vbuc1_then_la1 
    lda #STATUS_SKIP
    cmp.z check_status_roms_all1_check_status_rom1_return
    beq check_status_roms_all1___b4
    // [215] phi from main::check_status_roms_all1_@11 to main::check_status_roms_all1_@return [phi:main::check_status_roms_all1_@11->main::check_status_roms_all1_@return]
    // [215] phi main::check_status_roms_all1_return#2 = 0 [phi:main::check_status_roms_all1_@11->main::check_status_roms_all1_@return#0] -- vbum1=vbuc1 
    lda #0
    sta check_status_roms_all1_return
    jmp __b73
    // main::check_status_roms_all1_@4
  check_status_roms_all1___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [325] main::check_status_roms_all1_rom_chip#1 = ++ main::check_status_roms_all1_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_status_roms_all1_rom_chip
    // [213] phi from main::check_status_roms_all1_@4 to main::check_status_roms_all1_@1 [phi:main::check_status_roms_all1_@4->main::check_status_roms_all1_@1]
    // [213] phi main::check_status_roms_all1_rom_chip#2 = main::check_status_roms_all1_rom_chip#1 [phi:main::check_status_roms_all1_@4->main::check_status_roms_all1_@1#0] -- register_copy 
    jmp check_status_roms_all1___b1
    // main::check_status_rom1
  check_status_rom1:
    // status_rom[rom_chip] == status
    // [326] main::check_status_rom1_$0 = status_rom[main::rom_chip4#10] == STATUS_FLASH -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_FLASH
    ldy rom_chip4
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [327] main::check_status_rom1_return#0 = (char)main::check_status_rom1_$0
    // main::@72
    // if(check_status_rom(rom_chip, STATUS_FLASH))
    // [328] if(0==main::check_status_rom1_return#0) goto main::@43 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_rom1_return
    beq __b43
    // main::check_status_smc7
    // status_smc == status
    // [329] main::check_status_smc7_$0 = status_smc#0 == STATUS_FLASHED -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASHED
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc7_main__0
    // return (unsigned char)(status_smc == status);
    // [330] main::check_status_smc7_return#0 = (char)main::check_status_smc7_$0
    // main::@74
    // if((rom_chip == 0 && check_status_smc(STATUS_FLASHED)) || (rom_chip != 0))
    // [331] if(main::rom_chip4#10!=0) goto main::@192 -- vbum1_neq_0_then_la1 
    // IMPORTANT! We only flash the CX16 ROM chip if the SMC got flashed succesfully!
    lda rom_chip4
    bne __b192
    // main::@193
    // [332] if(0!=main::check_status_smc7_return#0) goto main::bank_set_brom5 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc7_return
    bne bank_set_brom5
    // main::@192
  __b192:
    // [333] if(main::rom_chip4#10!=0) goto main::bank_set_brom5 -- vbum1_neq_0_then_la1 
    lda rom_chip4
    bne bank_set_brom5
    // main::@49
    // display_info_rom(rom_chip, STATUS_ISSUE, "Update SMC failed!")
    // [334] display_info_rom::rom_chip#11 = main::rom_chip4#10 -- vbum1=vbum2 
    sta display_info_rom.rom_chip
    // [335] call display_info_rom
    // [1074] phi from main::@49 to display_info_rom [phi:main::@49->display_info_rom]
    // [1074] phi display_info_rom::info_text#17 = main::info_text20 [phi:main::@49->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text20
    sta.z display_info_rom.info_text
    lda #>info_text20
    sta.z display_info_rom.info_text+1
    // [1074] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#11 [phi:main::@49->display_info_rom#1] -- register_copy 
    // [1074] phi display_info_rom::info_status#17 = STATUS_ISSUE [phi:main::@49->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_rom.info_status
    jsr display_info_rom
    // [336] phi from main::@157 main::@168 main::@44 main::@48 main::@49 main::@72 to main::@43 [phi:main::@157/main::@168/main::@44/main::@48/main::@49/main::@72->main::@43]
    // [336] phi __errno#401 = __errno#18 [phi:main::@157/main::@168/main::@44/main::@48/main::@49/main::@72->main::@43#0] -- register_copy 
    // main::@43
  __b43:
    // for(unsigned char rom_chip = 7; rom_chip != 255; rom_chip--)
    // [337] main::rom_chip4#1 = -- main::rom_chip4#10 -- vbum1=_dec_vbum1 
    dec rom_chip4
    // [204] phi from main::@43 to main::@42 [phi:main::@43->main::@42]
    // [204] phi __errno#114 = __errno#401 [phi:main::@43->main::@42#0] -- register_copy 
    // [204] phi main::rom_chip4#10 = main::rom_chip4#1 [phi:main::@43->main::@42#1] -- register_copy 
    jmp __b42
    // main::bank_set_brom5
  bank_set_brom5:
    // BROM = bank
    // [338] BROM = main::bank_set_brom5_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom5_bank
    sta.z BROM
    // [339] phi from main::bank_set_brom5 to main::@75 [phi:main::bank_set_brom5->main::@75]
    // main::@75
    // display_progress_clear()
    // [340] call display_progress_clear
    // [718] phi from main::@75 to display_progress_clear [phi:main::@75->display_progress_clear]
    jsr display_progress_clear
    // main::@150
    // unsigned char rom_bank = rom_chip * 32
    // [341] main::rom_bank1#0 = main::rom_chip4#10 << 5 -- vbum1=vbum2_rol_5 
    lda rom_chip4
    asl
    asl
    asl
    asl
    asl
    sta rom_bank1
    // unsigned char* file = rom_file(rom_chip)
    // [342] rom_file::rom_chip#1 = main::rom_chip4#10 -- vbum1=vbum2 
    lda rom_chip4
    sta rom_file.rom_chip
    // [343] call rom_file
    // [1119] phi from main::@150 to rom_file [phi:main::@150->rom_file]
    // [1119] phi rom_file::rom_chip#2 = rom_file::rom_chip#1 [phi:main::@150->rom_file#0] -- register_copy 
    jsr rom_file
    // unsigned char* file = rom_file(rom_chip)
    // [344] rom_file::return#5 = rom_file::return#2
    // main::@151
    // [345] main::file1#0 = rom_file::return#5
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [346] call snprintf_init
    // [872] phi from main::@151 to snprintf_init [phi:main::@151->snprintf_init]
    // [872] phi snprintf_init::s#25 = info_text [phi:main::@151->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [347] phi from main::@151 to main::@152 [phi:main::@151->main::@152]
    // main::@152
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [348] call printf_str
    // [877] phi from main::@152 to printf_str [phi:main::@152->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:main::@152->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = s14 [phi:main::@152->printf_str#1] -- pbuz1=pbuc1 
    lda #<s14
    sta.z printf_str.s
    lda #>s14
    sta.z printf_str.s+1
    jsr printf_str
    // main::@153
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [349] printf_string::str#18 = main::file1#0 -- pbuz1=pbum2 
    lda file1
    sta.z printf_string.str
    lda file1+1
    sta.z printf_string.str+1
    // [350] call printf_string
    // [886] phi from main::@153 to printf_string [phi:main::@153->printf_string]
    // [886] phi printf_string::putc#19 = &snputc [phi:main::@153->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [886] phi printf_string::str#19 = printf_string::str#18 [phi:main::@153->printf_string#1] -- register_copy 
    // [886] phi printf_string::format_justify_left#19 = 0 [phi:main::@153->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [886] phi printf_string::format_min_length#19 = 0 [phi:main::@153->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [351] phi from main::@153 to main::@154 [phi:main::@153->main::@154]
    // main::@154
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [352] call printf_str
    // [877] phi from main::@154 to printf_str [phi:main::@154->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:main::@154->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = main::s7 [phi:main::@154->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@155
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [353] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [354] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_progress(info_text)
    // [356] call display_action_progress
    // [704] phi from main::@155 to display_action_progress [phi:main::@155->display_action_progress]
    // [704] phi display_action_progress::info_text#15 = info_text [phi:main::@155->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_progress.info_text
    lda #>@info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@156
    // unsigned long rom_bytes_read = rom_read(1, rom_chip, file, STATUS_READING, rom_bank, rom_sizes[rom_chip])
    // [357] main::$203 = main::rom_chip4#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip4
    asl
    asl
    sta main__203
    // [358] rom_read::file#1 = main::file1#0 -- pbuz1=pbum2 
    lda file1
    sta.z rom_read.file
    lda file1+1
    sta.z rom_read.file+1
    // [359] rom_read::brom_bank_start#2 = main::rom_bank1#0 -- vbum1=vbum2 
    lda rom_bank1
    sta rom_read.brom_bank_start
    // [360] rom_read::rom_size#1 = rom_sizes[main::$203] -- vduz1=pduc1_derefidx_vbum2 
    ldy main__203
    lda rom_sizes,y
    sta.z rom_read.rom_size
    lda rom_sizes+1,y
    sta.z rom_read.rom_size+1
    lda rom_sizes+2,y
    sta.z rom_read.rom_size+2
    lda rom_sizes+3,y
    sta.z rom_read.rom_size+3
    // [361] call rom_read
    // [1125] phi from main::@156 to rom_read [phi:main::@156->rom_read]
    // [1125] phi rom_read::display_progress#28 = 1 [phi:main::@156->rom_read#0] -- vbuz1=vbuc1 
    lda #1
    sta.z rom_read.display_progress
    // [1125] phi rom_read::rom_size#12 = rom_read::rom_size#1 [phi:main::@156->rom_read#1] -- register_copy 
    // [1125] phi __errno#106 = __errno#114 [phi:main::@156->rom_read#2] -- register_copy 
    // [1125] phi rom_read::file#11 = rom_read::file#1 [phi:main::@156->rom_read#3] -- register_copy 
    // [1125] phi rom_read::brom_bank_start#22 = rom_read::brom_bank_start#2 [phi:main::@156->rom_read#4] -- register_copy 
    jsr rom_read
    // unsigned long rom_bytes_read = rom_read(1, rom_chip, file, STATUS_READING, rom_bank, rom_sizes[rom_chip])
    // [362] rom_read::return#3 = rom_read::return#0
    // main::@157
    // [363] main::rom_bytes_read1#0 = rom_read::return#3
    // if(rom_bytes_read)
    // [364] if(0==main::rom_bytes_read1#0) goto main::@43 -- 0_eq_vdum1_then_la1 
    lda rom_bytes_read1
    ora rom_bytes_read1+1
    ora rom_bytes_read1+2
    ora rom_bytes_read1+3
    bne !__b43+
    jmp __b43
  !__b43:
    // [365] phi from main::@157 to main::@46 [phi:main::@157->main::@46]
    // main::@46
    // display_action_progress("Comparing ... (.) same, (*) different.")
    // [366] call display_action_progress
  // Now we compare the RAM with the actual ROM contents.
    // [704] phi from main::@46 to display_action_progress [phi:main::@46->display_action_progress]
    // [704] phi display_action_progress::info_text#15 = main::info_text21 [phi:main::@46->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text21
    sta.z display_action_progress.info_text
    lda #>info_text21
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@158
    // display_info_rom(rom_chip, STATUS_COMPARING, "")
    // [367] display_info_rom::rom_chip#12 = main::rom_chip4#10 -- vbum1=vbum2 
    lda rom_chip4
    sta display_info_rom.rom_chip
    // [368] call display_info_rom
    // [1074] phi from main::@158 to display_info_rom [phi:main::@158->display_info_rom]
    // [1074] phi display_info_rom::info_text#17 = info_text4 [phi:main::@158->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z display_info_rom.info_text
    lda #>info_text4
    sta.z display_info_rom.info_text+1
    // [1074] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#12 [phi:main::@158->display_info_rom#1] -- register_copy 
    // [1074] phi display_info_rom::info_status#17 = STATUS_COMPARING [phi:main::@158->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_COMPARING
    sta display_info_rom.info_status
    jsr display_info_rom
    // main::@159
    // unsigned long rom_differences = rom_verify(
    //                         rom_chip, rom_bank, file_sizes[rom_chip])
    // [369] rom_verify::rom_chip#0 = main::rom_chip4#10 -- vbum1=vbum2 
    lda rom_chip4
    sta rom_verify.rom_chip
    // [370] rom_verify::rom_bank_start#0 = main::rom_bank1#0 -- vbuz1=vbum2 
    lda rom_bank1
    sta.z rom_verify.rom_bank_start
    // [371] rom_verify::file_size#0 = file_sizes[main::$203] -- vdum1=pduc1_derefidx_vbum2 
    ldy main__203
    lda file_sizes,y
    sta rom_verify.file_size
    lda file_sizes+1,y
    sta rom_verify.file_size+1
    lda file_sizes+2,y
    sta rom_verify.file_size+2
    lda file_sizes+3,y
    sta rom_verify.file_size+3
    // [372] call rom_verify
    // Verify the ROM...
    jsr rom_verify
    // [373] rom_verify::return#2 = rom_verify::rom_different_bytes#11
    // main::@160
    // [374] main::rom_differences#0 = rom_verify::return#2 -- vduz1=vduz2 
    lda.z rom_verify.return
    sta.z rom_differences
    lda.z rom_verify.return+1
    sta.z rom_differences+1
    lda.z rom_verify.return+2
    sta.z rom_differences+2
    lda.z rom_verify.return+3
    sta.z rom_differences+3
    // if (!rom_differences)
    // [375] if(0==main::rom_differences#0) goto main::@44 -- 0_eq_vduz1_then_la1 
    lda.z rom_differences
    ora.z rom_differences+1
    ora.z rom_differences+2
    ora.z rom_differences+3
    bne !__b44+
    jmp __b44
  !__b44:
    // [376] phi from main::@160 to main::@47 [phi:main::@160->main::@47]
    // main::@47
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [377] call snprintf_init
    // [872] phi from main::@47 to snprintf_init [phi:main::@47->snprintf_init]
    // [872] phi snprintf_init::s#25 = info_text [phi:main::@47->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main::@161
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [378] printf_ulong::uvalue#9 = main::rom_differences#0
    // [379] call printf_ulong
    // [1276] phi from main::@161 to printf_ulong [phi:main::@161->printf_ulong]
    // [1276] phi printf_ulong::format_zero_padding#11 = 1 [phi:main::@161->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1276] phi printf_ulong::format_min_length#11 = 5 [phi:main::@161->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1276] phi printf_ulong::putc#11 = &snputc [phi:main::@161->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1276] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:main::@161->printf_ulong#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1276] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#9 [phi:main::@161->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [380] phi from main::@161 to main::@162 [phi:main::@161->main::@162]
    // main::@162
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [381] call printf_str
    // [877] phi from main::@162 to printf_str [phi:main::@162->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:main::@162->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = main::s16 [phi:main::@162->printf_str#1] -- pbuz1=pbuc1 
    lda #<s16
    sta.z printf_str.s
    lda #>s16
    sta.z printf_str.s+1
    jsr printf_str
    // main::@163
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [382] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [383] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_FLASH, info_text)
    // [385] display_info_rom::rom_chip#14 = main::rom_chip4#10 -- vbum1=vbum2 
    lda rom_chip4
    sta display_info_rom.rom_chip
    // [386] call display_info_rom
    // [1074] phi from main::@163 to display_info_rom [phi:main::@163->display_info_rom]
    // [1074] phi display_info_rom::info_text#17 = info_text [phi:main::@163->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1074] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#14 [phi:main::@163->display_info_rom#1] -- register_copy 
    // [1074] phi display_info_rom::info_status#17 = STATUS_FLASH [phi:main::@163->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta display_info_rom.info_status
    jsr display_info_rom
    // main::@164
    // unsigned long rom_flash_errors = rom_flash(
    //                             rom_chip, rom_bank, file_sizes[rom_chip])
    // [387] rom_flash::rom_chip#0 = main::rom_chip4#10 -- vbum1=vbum2 
    lda rom_chip4
    sta rom_flash.rom_chip
    // [388] rom_flash::rom_bank_start#0 = main::rom_bank1#0 -- vbuz1=vbum2 
    lda rom_bank1
    sta.z rom_flash.rom_bank_start
    // [389] rom_flash::file_size#0 = file_sizes[main::$203] -- vdum1=pduc1_derefidx_vbum2 
    ldy main__203
    lda file_sizes,y
    sta rom_flash.file_size
    lda file_sizes+1,y
    sta rom_flash.file_size+1
    lda file_sizes+2,y
    sta rom_flash.file_size+2
    lda file_sizes+3,y
    sta rom_flash.file_size+3
    // [390] call rom_flash
    // [1287] phi from main::@164 to rom_flash [phi:main::@164->rom_flash]
    jsr rom_flash
    // unsigned long rom_flash_errors = rom_flash(
    //                             rom_chip, rom_bank, file_sizes[rom_chip])
    // [391] rom_flash::return#2 = rom_flash::flash_errors#10
    // main::@165
    // [392] main::rom_flash_errors#0 = rom_flash::return#2 -- vdum1=vdum2 
    lda rom_flash.return
    sta rom_flash_errors
    lda rom_flash.return+1
    sta rom_flash_errors+1
    lda rom_flash.return+2
    sta rom_flash_errors+2
    lda rom_flash.return+3
    sta rom_flash_errors+3
    // if(rom_flash_errors)
    // [393] if(0!=main::rom_flash_errors#0) goto main::@45 -- 0_neq_vdum1_then_la1 
    lda rom_flash_errors
    ora rom_flash_errors+1
    ora rom_flash_errors+2
    ora rom_flash_errors+3
    bne __b45
    // main::@48
    // display_info_rom(rom_chip, STATUS_FLASHED, "OK!")
    // [394] display_info_rom::rom_chip#16 = main::rom_chip4#10 -- vbum1=vbum2 
    lda rom_chip4
    sta display_info_rom.rom_chip
    // [395] call display_info_rom
    // [1074] phi from main::@48 to display_info_rom [phi:main::@48->display_info_rom]
    // [1074] phi display_info_rom::info_text#17 = main::info_text24 [phi:main::@48->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text24
    sta.z display_info_rom.info_text
    lda #>info_text24
    sta.z display_info_rom.info_text+1
    // [1074] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#16 [phi:main::@48->display_info_rom#1] -- register_copy 
    // [1074] phi display_info_rom::info_status#17 = STATUS_FLASHED [phi:main::@48->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHED
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b43
    // [396] phi from main::@165 to main::@45 [phi:main::@165->main::@45]
    // main::@45
  __b45:
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [397] call snprintf_init
    // [872] phi from main::@45 to snprintf_init [phi:main::@45->snprintf_init]
    // [872] phi snprintf_init::s#25 = info_text [phi:main::@45->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main::@166
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [398] printf_ulong::uvalue#10 = main::rom_flash_errors#0 -- vduz1=vdum2 
    lda rom_flash_errors
    sta.z printf_ulong.uvalue
    lda rom_flash_errors+1
    sta.z printf_ulong.uvalue+1
    lda rom_flash_errors+2
    sta.z printf_ulong.uvalue+2
    lda rom_flash_errors+3
    sta.z printf_ulong.uvalue+3
    // [399] call printf_ulong
    // [1276] phi from main::@166 to printf_ulong [phi:main::@166->printf_ulong]
    // [1276] phi printf_ulong::format_zero_padding#11 = 0 [phi:main::@166->printf_ulong#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_ulong.format_zero_padding
    // [1276] phi printf_ulong::format_min_length#11 = 0 [phi:main::@166->printf_ulong#1] -- vbuz1=vbuc1 
    sta.z printf_ulong.format_min_length
    // [1276] phi printf_ulong::putc#11 = &snputc [phi:main::@166->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1276] phi printf_ulong::format_radix#11 = DECIMAL [phi:main::@166->printf_ulong#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_ulong.format_radix
    // [1276] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#10 [phi:main::@166->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [400] phi from main::@166 to main::@167 [phi:main::@166->main::@167]
    // main::@167
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [401] call printf_str
    // [877] phi from main::@167 to printf_str [phi:main::@167->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:main::@167->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = main::s17 [phi:main::@167->printf_str#1] -- pbuz1=pbuc1 
    lda #<s17
    sta.z printf_str.s
    lda #>s17
    sta.z printf_str.s+1
    jsr printf_str
    // main::@168
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [402] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [403] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_ERROR, info_text)
    // [405] display_info_rom::rom_chip#15 = main::rom_chip4#10 -- vbum1=vbum2 
    lda rom_chip4
    sta display_info_rom.rom_chip
    // [406] call display_info_rom
    // [1074] phi from main::@168 to display_info_rom [phi:main::@168->display_info_rom]
    // [1074] phi display_info_rom::info_text#17 = info_text [phi:main::@168->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1074] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#15 [phi:main::@168->display_info_rom#1] -- register_copy 
    // [1074] phi display_info_rom::info_status#17 = STATUS_ERROR [phi:main::@168->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b43
    // main::@44
  __b44:
    // display_info_rom(rom_chip, STATUS_FLASHED, "No update required")
    // [407] display_info_rom::rom_chip#13 = main::rom_chip4#10 -- vbum1=vbum2 
    lda rom_chip4
    sta display_info_rom.rom_chip
    // [408] call display_info_rom
    // [1074] phi from main::@44 to display_info_rom [phi:main::@44->display_info_rom]
    // [1074] phi display_info_rom::info_text#17 = main::info_text23 [phi:main::@44->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text23
    sta.z display_info_rom.info_text
    lda #>info_text23
    sta.z display_info_rom.info_text+1
    // [1074] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#13 [phi:main::@44->display_info_rom#1] -- register_copy 
    // [1074] phi display_info_rom::info_status#17 = STATUS_FLASHED [phi:main::@44->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHED
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b43
    // [409] phi from main::@189 to main::@6 [phi:main::@189->main::@6]
    // main::@6
  __b6:
    // display_progress_clear()
    // [410] call display_progress_clear
    // [718] phi from main::@6 to display_progress_clear [phi:main::@6->display_progress_clear]
    jsr display_progress_clear
    // [411] phi from main::@6 to main::@145 [phi:main::@6->main::@145]
    // main::@145
    // smc_read(1)
    // [412] call smc_read
    // [972] phi from main::@145 to smc_read [phi:main::@145->smc_read]
    // [972] phi smc_read::display_progress#19 = 1 [phi:main::@145->smc_read#0] -- vbuz1=vbuc1 
    lda #1
    sta.z smc_read.display_progress
    // [972] phi __errno#35 = __errno#112 [phi:main::@145->smc_read#1] -- register_copy 
    jsr smc_read
    // smc_read(1)
    // [413] smc_read::return#3 = smc_read::return#0
    // main::@146
    // smc_file_size = smc_read(1)
    // [414] smc_file_size#1 = smc_read::return#3 -- vwum1=vwum2 
    lda smc_read.return
    sta smc_file_size_1
    lda smc_read.return+1
    sta smc_file_size_1+1
    // if(smc_file_size)
    // [415] if(0==smc_file_size#1) goto main::@2 -- 0_eq_vwum1_then_la1 
    lda smc_file_size_1
    ora smc_file_size_1+1
    bne !__b2+
    jmp __b2
  !__b2:
    // [416] phi from main::@146 to main::@7 [phi:main::@146->main::@7]
    // main::@7
    // display_action_text("Press both POWER/RESET buttons on the CX16 board!")
    // [417] call display_action_text
  // Flash the SMC chip.
    // [1051] phi from main::@7 to display_action_text [phi:main::@7->display_action_text]
    // [1051] phi display_action_text::info_text#19 = main::info_text16 [phi:main::@7->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text16
    sta.z display_action_text.info_text
    lda #>info_text16
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@147
    // [418] smc_file_size#383 = smc_file_size#1 -- vwum1=vwum2 
    lda smc_file_size_1
    sta smc_file_size_2
    lda smc_file_size_1+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_FLASHING, "Press POWER/RESET!")
    // [419] call display_info_smc
    // [762] phi from main::@147 to display_info_smc [phi:main::@147->display_info_smc]
    // [762] phi display_info_smc::info_text#13 = main::info_text17 [phi:main::@147->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text17
    sta.z display_info_smc.info_text
    lda #>info_text17
    sta.z display_info_smc.info_text+1
    // [762] phi smc_file_size#12 = smc_file_size#383 [phi:main::@147->display_info_smc#1] -- register_copy 
    // [762] phi display_info_smc::info_status#13 = STATUS_FLASHING [phi:main::@147->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHING
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // main::@148
    // unsigned long flashed_bytes = smc_flash(smc_file_size)
    // [420] smc_flash::smc_bytes_total#0 = smc_file_size#1 -- vwum1=vwum2 
    lda smc_file_size_1
    sta smc_flash.smc_bytes_total
    lda smc_file_size_1+1
    sta smc_flash.smc_bytes_total+1
    // [421] call smc_flash
    // [1402] phi from main::@148 to smc_flash [phi:main::@148->smc_flash]
    jsr smc_flash
    // unsigned long flashed_bytes = smc_flash(smc_file_size)
    // [422] smc_flash::return#5 = smc_flash::return#1
    // main::@149
    // [423] main::flashed_bytes#0 = smc_flash::return#5 -- vdum1=vwum2 
    lda smc_flash.return
    sta flashed_bytes
    lda smc_flash.return+1
    sta flashed_bytes+1
    lda #0
    sta flashed_bytes+2
    sta flashed_bytes+3
    // if(flashed_bytes)
    // [424] if(0!=main::flashed_bytes#0) goto main::@41 -- 0_neq_vdum1_then_la1 
    lda flashed_bytes
    ora flashed_bytes+1
    ora flashed_bytes+2
    ora flashed_bytes+3
    bne __b41
    // main::@8
    // [425] smc_file_size#381 = smc_file_size#1 -- vwum1=vwum2 
    lda smc_file_size_1
    sta smc_file_size_2
    lda smc_file_size_1+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_ERROR, "SMC not updated!")
    // [426] call display_info_smc
    // [762] phi from main::@8 to display_info_smc [phi:main::@8->display_info_smc]
    // [762] phi display_info_smc::info_text#13 = main::info_text19 [phi:main::@8->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text19
    sta.z display_info_smc.info_text
    lda #>info_text19
    sta.z display_info_smc.info_text+1
    // [762] phi smc_file_size#12 = smc_file_size#381 [phi:main::@8->display_info_smc#1] -- register_copy 
    // [762] phi display_info_smc::info_status#13 = STATUS_ERROR [phi:main::@8->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp __b2
    // main::@41
  __b41:
    // [427] smc_file_size#387 = smc_file_size#1 -- vwum1=vwum2 
    lda smc_file_size_1
    sta smc_file_size_2
    lda smc_file_size_1+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_FLASHED, "")
    // [428] call display_info_smc
    // [762] phi from main::@41 to display_info_smc [phi:main::@41->display_info_smc]
    // [762] phi display_info_smc::info_text#13 = info_text4 [phi:main::@41->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z display_info_smc.info_text
    lda #>info_text4
    sta.z display_info_smc.info_text+1
    // [762] phi smc_file_size#12 = smc_file_size#387 [phi:main::@41->display_info_smc#1] -- register_copy 
    // [762] phi display_info_smc::info_status#13 = STATUS_FLASHED [phi:main::@41->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHED
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp __b2
    // [429] phi from main::@187 main::@188 to main::@4 [phi:main::@187/main::@188->main::@4]
    // main::@4
  __b4:
    // display_action_progress("Chipsets have been detected and update files validated!")
    // [430] call display_action_progress
    // [704] phi from main::@4 to display_action_progress [phi:main::@4->display_action_progress]
    // [704] phi display_action_progress::info_text#15 = main::info_text10 [phi:main::@4->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text10
    sta.z display_action_progress.info_text
    lda #>info_text10
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [431] phi from main::@4 to main::@140 [phi:main::@4->main::@140]
    // main::@140
    // unsigned char ch = util_wait_key("Continue with update of highlighted chipsets? [Y/N]", "nyNY")
    // [432] call util_wait_key
    // [1564] phi from main::@140 to util_wait_key [phi:main::@140->util_wait_key]
    // [1564] phi util_wait_key::filter#12 = main::filter [phi:main::@140->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter
    sta.z util_wait_key.filter
    lda #>filter
    sta.z util_wait_key.filter+1
    // [1564] phi util_wait_key::info_text#2 = main::info_text11 [phi:main::@140->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text11
    sta.z util_wait_key.info_text
    lda #>info_text11
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("Continue with update of highlighted chipsets? [Y/N]", "nyNY")
    // [433] util_wait_key::return#3 = util_wait_key::ch#4 -- vbuz1=vwum2 
    lda util_wait_key.ch
    sta.z util_wait_key.return
    // main::@141
    // [434] main::ch#0 = util_wait_key::return#3
    // strchr("nN", ch)
    // [435] strchr::c#1 = main::ch#0
    // [436] call strchr
    // [1588] phi from main::@141 to strchr [phi:main::@141->strchr]
    // [1588] phi strchr::c#4 = strchr::c#1 [phi:main::@141->strchr#0] -- register_copy 
    // [1588] phi strchr::str#2 = (const void *)main::$220 [phi:main::@141->strchr#1] -- pvoz1=pvoc1 
    lda #<main__220
    sta.z strchr.str
    lda #>main__220
    sta.z strchr.str+1
    jsr strchr
    // strchr("nN", ch)
    // [437] strchr::return#4 = strchr::return#2
    // main::@142
    // [438] main::$121 = strchr::return#4
    // if(strchr("nN", ch))
    // [439] if((void *)0==main::$121) goto main::SEI5 -- pvoc1_eq_pvoz1_then_la1 
    lda.z main__121
    cmp #<0
    bne !+
    lda.z main__121+1
    cmp #>0
    bne !SEI5+
    jmp SEI5
  !SEI5:
  !:
    // main::@5
    // [440] smc_file_size#388 = smc_file_size#227 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_SKIP, "Cancelled")
    // [441] call display_info_smc
  // We cancel all updates, the updates are skipped.
    // [762] phi from main::@5 to display_info_smc [phi:main::@5->display_info_smc]
    // [762] phi display_info_smc::info_text#13 = main::info_text12 [phi:main::@5->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text12
    sta.z display_info_smc.info_text
    lda #>info_text12
    sta.z display_info_smc.info_text+1
    // [762] phi smc_file_size#12 = smc_file_size#388 [phi:main::@5->display_info_smc#1] -- register_copy 
    // [762] phi display_info_smc::info_status#13 = STATUS_SKIP [phi:main::@5->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [442] phi from main::@5 to main::@143 [phi:main::@5->main::@143]
    // main::@143
    // display_info_vera(STATUS_SKIP, "Cancelled")
    // [443] call display_info_vera
    // [792] phi from main::@143 to display_info_vera [phi:main::@143->display_info_vera]
    // [792] phi display_info_vera::info_text#10 = main::info_text12 [phi:main::@143->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text12
    sta.z display_info_vera.info_text
    lda #>info_text12
    sta.z display_info_vera.info_text+1
    // [792] phi display_info_vera::info_status#3 = STATUS_SKIP [phi:main::@143->display_info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // [444] phi from main::@143 to main::@38 [phi:main::@143->main::@38]
    // [444] phi main::rom_chip3#2 = 0 [phi:main::@143->main::@38#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip3
    // main::@38
  __b38:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [445] if(main::rom_chip3#2<8) goto main::@39 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip3
    cmp #8
    bcc __b39
    // [446] phi from main::@38 to main::@40 [phi:main::@38->main::@40]
    // main::@40
    // display_action_text("You have selected not to cancel the update ... ")
    // [447] call display_action_text
    // [1051] phi from main::@40 to display_action_text [phi:main::@40->display_action_text]
    // [1051] phi display_action_text::info_text#19 = main::info_text15 [phi:main::@40->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text15
    sta.z display_action_text.info_text
    lda #>info_text15
    sta.z display_action_text.info_text+1
    jsr display_action_text
    jmp SEI5
    // main::@39
  __b39:
    // display_info_rom(rom_chip, STATUS_SKIP, "Cancelled")
    // [448] display_info_rom::rom_chip#10 = main::rom_chip3#2 -- vbum1=vbum2 
    lda rom_chip3
    sta display_info_rom.rom_chip
    // [449] call display_info_rom
    // [1074] phi from main::@39 to display_info_rom [phi:main::@39->display_info_rom]
    // [1074] phi display_info_rom::info_text#17 = main::info_text12 [phi:main::@39->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text12
    sta.z display_info_rom.info_text
    lda #>info_text12
    sta.z display_info_rom.info_text+1
    // [1074] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#10 [phi:main::@39->display_info_rom#1] -- register_copy 
    // [1074] phi display_info_rom::info_status#17 = STATUS_SKIP [phi:main::@39->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_rom.info_status
    jsr display_info_rom
    // main::@144
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [450] main::rom_chip3#1 = ++ main::rom_chip3#2 -- vbum1=_inc_vbum1 
    inc rom_chip3
    // [444] phi from main::@144 to main::@38 [phi:main::@144->main::@38]
    // [444] phi main::rom_chip3#2 = main::rom_chip3#1 [phi:main::@144->main::@38#0] -- register_copy 
    jmp __b38
    // main::check_status_card_roms1_check_status_rom1
  check_status_card_roms1_check_status_rom1:
    // status_rom[rom_chip] == status
    // [451] main::check_status_card_roms1_check_status_rom1_$0 = status_rom[main::check_status_card_roms1_rom_chip#2] == STATUS_FLASH -- vbom1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_FLASH
    ldy check_status_card_roms1_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_card_roms1_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [452] main::check_status_card_roms1_check_status_rom1_return#0 = (char)main::check_status_card_roms1_check_status_rom1_$0
    // main::check_status_card_roms1_@11
    // if(check_status_rom(rom_chip, status))
    // [453] if(0==main::check_status_card_roms1_check_status_rom1_return#0) goto main::check_status_card_roms1_@4 -- 0_eq_vbum1_then_la1 
    lda check_status_card_roms1_check_status_rom1_return
    beq check_status_card_roms1___b4
    // [191] phi from main::check_status_card_roms1_@11 to main::check_status_card_roms1_@return [phi:main::check_status_card_roms1_@11->main::check_status_card_roms1_@return]
    // [191] phi main::check_status_card_roms1_return#2 = STATUS_FLASH [phi:main::check_status_card_roms1_@11->main::check_status_card_roms1_@return#0] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta check_status_card_roms1_return
    jmp __b70
    // main::check_status_card_roms1_@4
  check_status_card_roms1___b4:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [454] main::check_status_card_roms1_rom_chip#1 = ++ main::check_status_card_roms1_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_status_card_roms1_rom_chip
    // [189] phi from main::check_status_card_roms1_@4 to main::check_status_card_roms1_@1 [phi:main::check_status_card_roms1_@4->main::check_status_card_roms1_@1]
    // [189] phi main::check_status_card_roms1_rom_chip#2 = main::check_status_card_roms1_rom_chip#1 [phi:main::check_status_card_roms1_@4->main::check_status_card_roms1_@1#0] -- register_copy 
    jmp check_status_card_roms1___b1
    // [455] phi from main::@186 to main::@3 [phi:main::@186->main::@3]
    // main::@3
  __b3:
    // display_action_progress("The ROM must also be flashable, check the ROM issue.")
    // [456] call display_action_progress
    // [704] phi from main::@3 to display_action_progress [phi:main::@3->display_action_progress]
    // [704] phi display_action_progress::info_text#15 = main::info_text9 [phi:main::@3->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text9
    sta.z display_action_progress.info_text
    lda #>info_text9
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [457] phi from main::@3 to main::@138 [phi:main::@3->main::@138]
    // main::@138
    // display_info_cx16_rom(STATUS_ISSUE, NULL)
    // [458] call display_info_cx16_rom
    // [1597] phi from main::@138 to display_info_cx16_rom [phi:main::@138->display_info_cx16_rom]
    jsr display_info_cx16_rom
    // [459] phi from main::@138 to main::@139 [phi:main::@138->main::@139]
    // main::@139
    // util_wait_space()
    // [460] call util_wait_space
    // [828] phi from main::@139 to util_wait_space [phi:main::@139->util_wait_space]
    jsr util_wait_space
    jmp check_status_smc4
    // [461] phi from main::@185 to main::@37 [phi:main::@185->main::@37]
    // main::@37
  __b37:
    // display_action_progress("The SMC must also be flashable, check the SMC issue!")
    // [462] call display_action_progress
    // [704] phi from main::@37 to display_action_progress [phi:main::@37->display_action_progress]
    // [704] phi display_action_progress::info_text#15 = main::info_text8 [phi:main::@37->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z display_action_progress.info_text
    lda #>info_text8
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@136
    // [463] smc_file_size#382 = smc_file_size#227 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_ISSUE, NULL)
    // [464] call display_info_smc
    // [762] phi from main::@136 to display_info_smc [phi:main::@136->display_info_smc]
    // [762] phi display_info_smc::info_text#13 = 0 [phi:main::@136->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [762] phi smc_file_size#12 = smc_file_size#382 [phi:main::@136->display_info_smc#1] -- register_copy 
    // [762] phi display_info_smc::info_status#13 = STATUS_ISSUE [phi:main::@136->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [465] phi from main::@136 to main::@137 [phi:main::@136->main::@137]
    // main::@137
    // util_wait_space()
    // [466] call util_wait_space
    // [828] phi from main::@137 to util_wait_space [phi:main::@137->util_wait_space]
    jsr util_wait_space
    jmp check_status_smc3
    // main::bank_set_brom2
  bank_set_brom2:
    // BROM = bank
    // [467] BROM = main::bank_set_brom2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom2_bank
    sta.z BROM
    // main::@65
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [468] if(rom_device_ids[main::rom_chip2#10]==$55) goto main::@31 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    ldy rom_chip2
    lda rom_device_ids,y
    cmp #$55
    bne !__b31+
    jmp __b31
  !__b31:
    // [469] phi from main::@65 to main::@34 [phi:main::@65->main::@34]
    // main::@34
    // display_progress_clear()
    // [470] call display_progress_clear
    // [718] phi from main::@34 to display_progress_clear [phi:main::@34->display_progress_clear]
    jsr display_progress_clear
    // main::@114
    // unsigned char rom_bank = rom_chip * 32
    // [471] main::rom_bank#0 = main::rom_chip2#10 << 5 -- vbum1=vbum2_rol_5 
    lda rom_chip2
    asl
    asl
    asl
    asl
    asl
    sta rom_bank
    // unsigned char* file = rom_file(rom_chip)
    // [472] rom_file::rom_chip#0 = main::rom_chip2#10 -- vbum1=vbum2 
    lda rom_chip2
    sta rom_file.rom_chip
    // [473] call rom_file
    // [1119] phi from main::@114 to rom_file [phi:main::@114->rom_file]
    // [1119] phi rom_file::rom_chip#2 = rom_file::rom_chip#0 [phi:main::@114->rom_file#0] -- register_copy 
    jsr rom_file
    // unsigned char* file = rom_file(rom_chip)
    // [474] rom_file::return#4 = rom_file::return#2
    // main::@115
    // [475] main::file#0 = rom_file::return#4 -- pbum1=pbum2 
    lda rom_file.return
    sta file
    lda rom_file.return+1
    sta file+1
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [476] call snprintf_init
    // [872] phi from main::@115 to snprintf_init [phi:main::@115->snprintf_init]
    // [872] phi snprintf_init::s#25 = info_text [phi:main::@115->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [477] phi from main::@115 to main::@116 [phi:main::@115->main::@116]
    // main::@116
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [478] call printf_str
    // [877] phi from main::@116 to printf_str [phi:main::@116->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:main::@116->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = main::s6 [phi:main::@116->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // main::@117
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [479] printf_string::str#13 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [480] call printf_string
    // [886] phi from main::@117 to printf_string [phi:main::@117->printf_string]
    // [886] phi printf_string::putc#19 = &snputc [phi:main::@117->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [886] phi printf_string::str#19 = printf_string::str#13 [phi:main::@117->printf_string#1] -- register_copy 
    // [886] phi printf_string::format_justify_left#19 = 0 [phi:main::@117->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [886] phi printf_string::format_min_length#19 = 0 [phi:main::@117->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [481] phi from main::@117 to main::@118 [phi:main::@117->main::@118]
    // main::@118
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [482] call printf_str
    // [877] phi from main::@118 to printf_str [phi:main::@118->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:main::@118->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = main::s7 [phi:main::@118->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@119
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [483] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [484] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_progress(info_text)
    // [486] call display_action_progress
    // [704] phi from main::@119 to display_action_progress [phi:main::@119->display_action_progress]
    // [704] phi display_action_progress::info_text#15 = info_text [phi:main::@119->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_progress.info_text
    lda #>@info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@120
    // unsigned long rom_bytes_read = rom_read(0, rom_chip, file, STATUS_CHECKING, rom_bank, rom_sizes[rom_chip])
    // [487] main::$199 = main::rom_chip2#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip2
    asl
    asl
    sta main__199
    // [488] rom_read::file#0 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z rom_read.file
    lda file+1
    sta.z rom_read.file+1
    // [489] rom_read::brom_bank_start#1 = main::rom_bank#0 -- vbum1=vbum2 
    lda rom_bank
    sta rom_read.brom_bank_start
    // [490] rom_read::rom_size#0 = rom_sizes[main::$199] -- vduz1=pduc1_derefidx_vbum2 
    ldy main__199
    lda rom_sizes,y
    sta.z rom_read.rom_size
    lda rom_sizes+1,y
    sta.z rom_read.rom_size+1
    lda rom_sizes+2,y
    sta.z rom_read.rom_size+2
    lda rom_sizes+3,y
    sta.z rom_read.rom_size+3
    // [491] call rom_read
  // Read the ROM(n).BIN file.
    // [1125] phi from main::@120 to rom_read [phi:main::@120->rom_read]
    // [1125] phi rom_read::display_progress#28 = 0 [phi:main::@120->rom_read#0] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_read.display_progress
    // [1125] phi rom_read::rom_size#12 = rom_read::rom_size#0 [phi:main::@120->rom_read#1] -- register_copy 
    // [1125] phi __errno#106 = __errno#112 [phi:main::@120->rom_read#2] -- register_copy 
    // [1125] phi rom_read::file#11 = rom_read::file#0 [phi:main::@120->rom_read#3] -- register_copy 
    // [1125] phi rom_read::brom_bank_start#22 = rom_read::brom_bank_start#1 [phi:main::@120->rom_read#4] -- register_copy 
    jsr rom_read
    // unsigned long rom_bytes_read = rom_read(0, rom_chip, file, STATUS_CHECKING, rom_bank, rom_sizes[rom_chip])
    // [492] rom_read::return#2 = rom_read::return#0
    // main::@121
    // [493] main::rom_bytes_read#0 = rom_read::return#2
    // if (!rom_bytes_read)
    // [494] if(0==main::rom_bytes_read#0) goto main::@32 -- 0_eq_vdum1_then_la1 
    // In case no file was found, set the status to none and skip to the next, else, mention the amount of bytes read.
    lda rom_bytes_read
    ora rom_bytes_read+1
    ora rom_bytes_read+2
    ora rom_bytes_read+3
    bne !__b32+
    jmp __b32
  !__b32:
    // main::@35
    // unsigned long rom_file_modulo = rom_bytes_read % 0x4000
    // [495] main::rom_file_modulo#0 = main::rom_bytes_read#0 & $4000-1 -- vdum1=vdum2_band_vduc1 
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
    // [496] if(0!=main::rom_file_modulo#0) goto main::@33 -- 0_neq_vdum1_then_la1 
    lda rom_file_modulo
    ora rom_file_modulo+1
    ora rom_file_modulo+2
    ora rom_file_modulo+3
    beq !__b33+
    jmp __b33
  !__b33:
    // main::@36
    // file_sizes[rom_chip] = rom_bytes_read
    // [497] file_sizes[main::$199] = main::rom_bytes_read#0 -- pduc1_derefidx_vbum1=vdum2 
    // We know the file size, so we indicate it in the status panel.
    ldy main__199
    lda rom_bytes_read
    sta file_sizes,y
    lda rom_bytes_read+1
    sta file_sizes+1,y
    lda rom_bytes_read+2
    sta file_sizes+2,y
    lda rom_bytes_read+3
    sta file_sizes+3,y
    // strncpy(rom_github[rom_chip], (char*)RAM_BASE, 6)
    // [498] main::$201 = main::rom_chip2#10 << 1 -- vbuz1=vbum2_rol_1 
    lda rom_chip2
    asl
    sta.z main__201
    // [499] strncpy::dst#2 = rom_github[main::$201] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda rom_github,y
    sta.z strncpy.dst
    lda rom_github+1,y
    sta.z strncpy.dst+1
    // [500] call strncpy
  // Fill the version data ...
  // TODO: I need to make a function for this, and calculate it properly! 
  // TODO: It seems currently not to work like I would expect.
    // [1600] phi from main::@36 to strncpy [phi:main::@36->strncpy]
    // [1600] phi strncpy::dst#8 = strncpy::dst#2 [phi:main::@36->strncpy#0] -- register_copy 
    // [1600] phi strncpy::src#6 = (char *)$7800 [phi:main::@36->strncpy#1] -- pbuz1=pbuc1 
    lda #<$7800
    sta.z strncpy.src
    lda #>$7800
    sta.z strncpy.src+1
    // [1600] phi strncpy::n#3 = 6 [phi:main::@36->strncpy#2] -- vwuz1=vbuc1 
    lda #<6
    sta.z strncpy.n
    lda #>6
    sta.z strncpy.n+1
    jsr strncpy
    // main::bank_push_set_bram1
    // asm
    // asm { lda$00 pha  }
    lda.z 0
    pha
    // BRAM = bank
    // [502] BRAM = main::bank_push_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_push_set_bram1_bank
    sta.z BRAM
    // main::@67
    // rom_release[rom_chip] = *((char*)0xBF80)
    // [503] rom_release[main::rom_chip2#10] = *((char *) 49024) -- pbuc1_derefidx_vbum1=_deref_pbuc2 
    lda $bf80
    ldy rom_chip2
    sta rom_release,y
    // main::bank_pull_bram1
    // asm
    // asm { pla sta$00  }
    pla
    sta.z 0
    // main::@68
    // ~(rom_release[rom_chip])
    // [505] main::$105 = ~ rom_release[main::rom_chip2#10] -- vbuz1=_bnot_pbuc1_derefidx_vbum2 
    lda rom_release,y
    eor #$ff
    sta.z main__105
    // sprintf(info_text, "%s:R%u/%s", file, (~(rom_release[rom_chip]))+1, rom_github[rom_chip])
    // [506] printf_uint::uvalue#18 = main::$105 + 1 -- vwuz1=vbuz2_plus_1 
    clc
    adc #1
    sta.z printf_uint.uvalue
    lda #0
    adc #0
    sta.z printf_uint.uvalue+1
    // [507] call snprintf_init
    // [872] phi from main::@68 to snprintf_init [phi:main::@68->snprintf_init]
    // [872] phi snprintf_init::s#25 = info_text [phi:main::@68->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main::@130
    // sprintf(info_text, "%s:R%u/%s", file, (~(rom_release[rom_chip]))+1, rom_github[rom_chip])
    // [508] printf_string::str#16 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [509] call printf_string
    // [886] phi from main::@130 to printf_string [phi:main::@130->printf_string]
    // [886] phi printf_string::putc#19 = &snputc [phi:main::@130->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [886] phi printf_string::str#19 = printf_string::str#16 [phi:main::@130->printf_string#1] -- register_copy 
    // [886] phi printf_string::format_justify_left#19 = 0 [phi:main::@130->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [886] phi printf_string::format_min_length#19 = 0 [phi:main::@130->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [510] phi from main::@130 to main::@131 [phi:main::@130->main::@131]
    // main::@131
    // sprintf(info_text, "%s:R%u/%s", file, (~(rom_release[rom_chip]))+1, rom_github[rom_chip])
    // [511] call printf_str
    // [877] phi from main::@131 to printf_str [phi:main::@131->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:main::@131->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = main::s12 [phi:main::@131->printf_str#1] -- pbuz1=pbuc1 
    lda #<s12
    sta.z printf_str.s
    lda #>s12
    sta.z printf_str.s+1
    jsr printf_str
    // [512] phi from main::@131 to main::@132 [phi:main::@131->main::@132]
    // main::@132
    // sprintf(info_text, "%s:R%u/%s", file, (~(rom_release[rom_chip]))+1, rom_github[rom_chip])
    // [513] call printf_uint
    // [911] phi from main::@132 to printf_uint [phi:main::@132->printf_uint]
    // [911] phi printf_uint::format_zero_padding#19 = 0 [phi:main::@132->printf_uint#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uint.format_zero_padding
    // [911] phi printf_uint::format_min_length#19 = 0 [phi:main::@132->printf_uint#1] -- vbuz1=vbuc1 
    sta.z printf_uint.format_min_length
    // [911] phi printf_uint::putc#19 = &snputc [phi:main::@132->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [911] phi printf_uint::format_radix#19 = DECIMAL [phi:main::@132->printf_uint#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [911] phi printf_uint::uvalue#19 = printf_uint::uvalue#18 [phi:main::@132->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [514] phi from main::@132 to main::@133 [phi:main::@132->main::@133]
    // main::@133
    // sprintf(info_text, "%s:R%u/%s", file, (~(rom_release[rom_chip]))+1, rom_github[rom_chip])
    // [515] call printf_str
    // [877] phi from main::@133 to printf_str [phi:main::@133->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:main::@133->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = s4 [phi:main::@133->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s4
    sta.z printf_str.s
    lda #>@s4
    sta.z printf_str.s+1
    jsr printf_str
    // main::@134
    // sprintf(info_text, "%s:R%u/%s", file, (~(rom_release[rom_chip]))+1, rom_github[rom_chip])
    // [516] printf_string::str#17 = rom_github[main::$201] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z main__201
    lda rom_github,y
    sta.z printf_string.str
    lda rom_github+1,y
    sta.z printf_string.str+1
    // [517] call printf_string
    // [886] phi from main::@134 to printf_string [phi:main::@134->printf_string]
    // [886] phi printf_string::putc#19 = &snputc [phi:main::@134->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [886] phi printf_string::str#19 = printf_string::str#17 [phi:main::@134->printf_string#1] -- register_copy 
    // [886] phi printf_string::format_justify_left#19 = 0 [phi:main::@134->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [886] phi printf_string::format_min_length#19 = 0 [phi:main::@134->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@135
    // sprintf(info_text, "%s:R%u/%s", file, (~(rom_release[rom_chip]))+1, rom_github[rom_chip])
    // [518] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [519] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_FLASH, info_text)
    // [521] display_info_rom::rom_chip#9 = main::rom_chip2#10 -- vbum1=vbum2 
    lda rom_chip2
    sta display_info_rom.rom_chip
    // [522] call display_info_rom
    // [1074] phi from main::@135 to display_info_rom [phi:main::@135->display_info_rom]
    // [1074] phi display_info_rom::info_text#17 = info_text [phi:main::@135->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1074] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#9 [phi:main::@135->display_info_rom#1] -- register_copy 
    // [1074] phi display_info_rom::info_status#17 = STATUS_FLASH [phi:main::@135->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta display_info_rom.info_status
    jsr display_info_rom
    // [523] phi from main::@125 main::@129 main::@135 main::@65 to main::@31 [phi:main::@125/main::@129/main::@135/main::@65->main::@31]
    // [523] phi __errno#242 = __errno#18 [phi:main::@125/main::@129/main::@135/main::@65->main::@31#0] -- register_copy 
    // main::@31
  __b31:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [524] main::rom_chip2#1 = ++ main::rom_chip2#10 -- vbum1=_inc_vbum1 
    inc rom_chip2
    // [165] phi from main::@31 to main::@30 [phi:main::@31->main::@30]
    // [165] phi __errno#112 = __errno#242 [phi:main::@31->main::@30#0] -- register_copy 
    // [165] phi main::rom_chip2#10 = main::rom_chip2#1 [phi:main::@31->main::@30#1] -- register_copy 
    jmp __b30
    // [525] phi from main::@35 to main::@33 [phi:main::@35->main::@33]
    // main::@33
  __b33:
    // sprintf(info_text, "File %s size error!", file)
    // [526] call snprintf_init
    // [872] phi from main::@33 to snprintf_init [phi:main::@33->snprintf_init]
    // [872] phi snprintf_init::s#25 = info_text [phi:main::@33->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [527] phi from main::@33 to main::@126 [phi:main::@33->main::@126]
    // main::@126
    // sprintf(info_text, "File %s size error!", file)
    // [528] call printf_str
    // [877] phi from main::@126 to printf_str [phi:main::@126->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:main::@126->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = main::s10 [phi:main::@126->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // main::@127
    // sprintf(info_text, "File %s size error!", file)
    // [529] printf_string::str#15 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [530] call printf_string
    // [886] phi from main::@127 to printf_string [phi:main::@127->printf_string]
    // [886] phi printf_string::putc#19 = &snputc [phi:main::@127->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [886] phi printf_string::str#19 = printf_string::str#15 [phi:main::@127->printf_string#1] -- register_copy 
    // [886] phi printf_string::format_justify_left#19 = 0 [phi:main::@127->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [886] phi printf_string::format_min_length#19 = 0 [phi:main::@127->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [531] phi from main::@127 to main::@128 [phi:main::@127->main::@128]
    // main::@128
    // sprintf(info_text, "File %s size error!", file)
    // [532] call printf_str
    // [877] phi from main::@128 to printf_str [phi:main::@128->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:main::@128->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = main::s11 [phi:main::@128->printf_str#1] -- pbuz1=pbuc1 
    lda #<s11
    sta.z printf_str.s
    lda #>s11
    sta.z printf_str.s+1
    jsr printf_str
    // main::@129
    // sprintf(info_text, "File %s size error!", file)
    // [533] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [534] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_ERROR, info_text)
    // [536] display_info_rom::rom_chip#8 = main::rom_chip2#10 -- vbum1=vbum2 
    lda rom_chip2
    sta display_info_rom.rom_chip
    // [537] call display_info_rom
    // [1074] phi from main::@129 to display_info_rom [phi:main::@129->display_info_rom]
    // [1074] phi display_info_rom::info_text#17 = info_text [phi:main::@129->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1074] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#8 [phi:main::@129->display_info_rom#1] -- register_copy 
    // [1074] phi display_info_rom::info_status#17 = STATUS_ERROR [phi:main::@129->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b31
    // [538] phi from main::@121 to main::@32 [phi:main::@121->main::@32]
    // main::@32
  __b32:
    // sprintf(info_text, "No %s, skipped", file)
    // [539] call snprintf_init
    // [872] phi from main::@32 to snprintf_init [phi:main::@32->snprintf_init]
    // [872] phi snprintf_init::s#25 = info_text [phi:main::@32->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [540] phi from main::@32 to main::@122 [phi:main::@32->main::@122]
    // main::@122
    // sprintf(info_text, "No %s, skipped", file)
    // [541] call printf_str
    // [877] phi from main::@122 to printf_str [phi:main::@122->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:main::@122->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = main::s8 [phi:main::@122->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // main::@123
    // sprintf(info_text, "No %s, skipped", file)
    // [542] printf_string::str#14 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [543] call printf_string
    // [886] phi from main::@123 to printf_string [phi:main::@123->printf_string]
    // [886] phi printf_string::putc#19 = &snputc [phi:main::@123->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [886] phi printf_string::str#19 = printf_string::str#14 [phi:main::@123->printf_string#1] -- register_copy 
    // [886] phi printf_string::format_justify_left#19 = 0 [phi:main::@123->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [886] phi printf_string::format_min_length#19 = 0 [phi:main::@123->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [544] phi from main::@123 to main::@124 [phi:main::@123->main::@124]
    // main::@124
    // sprintf(info_text, "No %s, skipped", file)
    // [545] call printf_str
    // [877] phi from main::@124 to printf_str [phi:main::@124->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:main::@124->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = main::s9 [phi:main::@124->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // main::@125
    // sprintf(info_text, "No %s, skipped", file)
    // [546] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [547] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_NONE, info_text)
    // [549] display_info_rom::rom_chip#7 = main::rom_chip2#10 -- vbum1=vbum2 
    lda rom_chip2
    sta display_info_rom.rom_chip
    // [550] call display_info_rom
    // [1074] phi from main::@125 to display_info_rom [phi:main::@125->display_info_rom]
    // [1074] phi display_info_rom::info_text#17 = info_text [phi:main::@125->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1074] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#7 [phi:main::@125->display_info_rom#1] -- register_copy 
    // [1074] phi display_info_rom::info_status#17 = STATUS_NONE [phi:main::@125->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b31
    // main::@29
  __b29:
    // [551] smc_file_size#386 = smc_file_size#0 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_ISSUE, "SMC.BIN too large!")
    // [552] call display_info_smc
    // [762] phi from main::@29 to display_info_smc [phi:main::@29->display_info_smc]
    // [762] phi display_info_smc::info_text#13 = main::info_text7 [phi:main::@29->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z display_info_smc.info_text
    lda #>info_text7
    sta.z display_info_smc.info_text+1
    // [762] phi smc_file_size#12 = smc_file_size#386 [phi:main::@29->display_info_smc#1] -- register_copy 
    // [762] phi display_info_smc::info_status#13 = STATUS_ISSUE [phi:main::@29->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp CLI3
    // main::@28
  __b28:
    // [553] smc_file_size#385 = smc_file_size#0 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_ISSUE, "No SMC.BIN!")
    // [554] call display_info_smc
    // [762] phi from main::@28 to display_info_smc [phi:main::@28->display_info_smc]
    // [762] phi display_info_smc::info_text#13 = main::info_text6 [phi:main::@28->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text6
    sta.z display_info_smc.info_text
    lda #>info_text6
    sta.z display_info_smc.info_text+1
    // [762] phi smc_file_size#12 = smc_file_size#385 [phi:main::@28->display_info_smc#1] -- register_copy 
    // [762] phi display_info_smc::info_status#13 = STATUS_ISSUE [phi:main::@28->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp CLI3
    // main::@21
  __b21:
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [555] if(rom_device_ids[main::rom_chip1#2]!=$55) goto main::@22 -- pbuc1_derefidx_vbum1_neq_vbuc2_then_la1 
    lda #$55
    ldy rom_chip1
    cmp rom_device_ids,y
    bne __b22
    // main::@24
    // display_info_rom(rom_chip, STATUS_NONE, "")
    // [556] display_info_rom::rom_chip#6 = main::rom_chip1#2 -- vbum1=vbum2 
    tya
    sta display_info_rom.rom_chip
    // [557] call display_info_rom
    // [1074] phi from main::@24 to display_info_rom [phi:main::@24->display_info_rom]
    // [1074] phi display_info_rom::info_text#17 = info_text4 [phi:main::@24->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z display_info_rom.info_text
    lda #>info_text4
    sta.z display_info_rom.info_text+1
    // [1074] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#6 [phi:main::@24->display_info_rom#1] -- register_copy 
    // [1074] phi display_info_rom::info_status#17 = STATUS_NONE [phi:main::@24->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta display_info_rom.info_status
    jsr display_info_rom
    // main::@23
  __b23:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [558] main::rom_chip1#1 = ++ main::rom_chip1#2 -- vbum1=_inc_vbum1 
    inc rom_chip1
    // [147] phi from main::@23 to main::@20 [phi:main::@23->main::@20]
    // [147] phi main::rom_chip1#2 = main::rom_chip1#1 [phi:main::@23->main::@20#0] -- register_copy 
    jmp __b20
    // main::@22
  __b22:
    // display_info_rom(rom_chip, STATUS_DETECTED, "")
    // [559] display_info_rom::rom_chip#5 = main::rom_chip1#2 -- vbum1=vbum2 
    lda rom_chip1
    sta display_info_rom.rom_chip
    // [560] call display_info_rom
    // [1074] phi from main::@22 to display_info_rom [phi:main::@22->display_info_rom]
    // [1074] phi display_info_rom::info_text#17 = info_text4 [phi:main::@22->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z display_info_rom.info_text
    lda #>info_text4
    sta.z display_info_rom.info_text+1
    // [1074] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#5 [phi:main::@22->display_info_rom#1] -- register_copy 
    // [1074] phi display_info_rom::info_status#17 = STATUS_DETECTED [phi:main::@22->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_DETECTED
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b23
    // [561] phi from main::@16 to main::@19 [phi:main::@16->main::@19]
    // main::@19
  __b19:
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [562] call snprintf_init
    // [872] phi from main::@19 to snprintf_init [phi:main::@19->snprintf_init]
    // [872] phi snprintf_init::s#25 = info_text [phi:main::@19->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [563] phi from main::@19 to main::@100 [phi:main::@19->main::@100]
    // main::@100
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [564] call printf_str
    // [877] phi from main::@100 to printf_str [phi:main::@100->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:main::@100->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = main::s2 [phi:main::@100->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main::@101
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [565] printf_uint::uvalue#16 = smc_bootloader#0 -- vwuz1=vwum2 
    lda smc_bootloader
    sta.z printf_uint.uvalue
    lda smc_bootloader+1
    sta.z printf_uint.uvalue+1
    // [566] call printf_uint
    // [911] phi from main::@101 to printf_uint [phi:main::@101->printf_uint]
    // [911] phi printf_uint::format_zero_padding#19 = 1 [phi:main::@101->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [911] phi printf_uint::format_min_length#19 = 2 [phi:main::@101->printf_uint#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uint.format_min_length
    // [911] phi printf_uint::putc#19 = &snputc [phi:main::@101->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [911] phi printf_uint::format_radix#19 = HEXADECIMAL [phi:main::@101->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [911] phi printf_uint::uvalue#19 = printf_uint::uvalue#16 [phi:main::@101->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [567] phi from main::@101 to main::@102 [phi:main::@101->main::@102]
    // main::@102
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [568] call printf_str
    // [877] phi from main::@102 to printf_str [phi:main::@102->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:main::@102->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = main::s3 [phi:main::@102->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // main::@103
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [569] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [570] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_smc(STATUS_ISSUE, info_text)
    // [572] call display_info_smc
    // [762] phi from main::@103 to display_info_smc [phi:main::@103->display_info_smc]
    // [762] phi display_info_smc::info_text#13 = info_text [phi:main::@103->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_smc.info_text
    lda #>@info_text
    sta.z display_info_smc.info_text+1
    // [762] phi smc_file_size#12 = 0 [phi:main::@103->display_info_smc#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size_2
    sta smc_file_size_2+1
    // [762] phi display_info_smc::info_status#13 = STATUS_ISSUE [phi:main::@103->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [573] phi from main::@103 to main::@104 [phi:main::@103->main::@104]
    // main::@104
    // display_progress_text(display_no_valid_smc_bootloader_text, display_no_valid_smc_bootloader_count)
    // [574] call display_progress_text
  // Bootloader is not supported by this utility, but is not error.
    // [818] phi from main::@104 to display_progress_text [phi:main::@104->display_progress_text]
    // [818] phi display_progress_text::text#10 = display_no_valid_smc_bootloader_text [phi:main::@104->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_no_valid_smc_bootloader_text
    sta.z display_progress_text.text
    lda #>display_no_valid_smc_bootloader_text
    sta.z display_progress_text.text+1
    // [818] phi display_progress_text::lines#7 = display_no_valid_smc_bootloader_count [phi:main::@104->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_no_valid_smc_bootloader_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    jmp CLI1
    // [575] phi from main::@15 to main::@18 [phi:main::@15->main::@18]
    // main::@18
  __b18:
    // display_info_smc(STATUS_ERROR, "SMC Unreachable!")
    // [576] call display_info_smc
    // [762] phi from main::@18 to display_info_smc [phi:main::@18->display_info_smc]
    // [762] phi display_info_smc::info_text#13 = main::info_text2 [phi:main::@18->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z display_info_smc.info_text
    lda #>info_text2
    sta.z display_info_smc.info_text+1
    // [762] phi smc_file_size#12 = 0 [phi:main::@18->display_info_smc#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size_2
    sta smc_file_size_2+1
    // [762] phi display_info_smc::info_status#13 = STATUS_ERROR [phi:main::@18->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp CLI1
    // [577] phi from main::@98 to main::@1 [phi:main::@98->main::@1]
    // main::@1
  __b1:
    // display_info_smc(STATUS_ISSUE, "No Bootloader!")
    // [578] call display_info_smc
    // [762] phi from main::@1 to display_info_smc [phi:main::@1->display_info_smc]
    // [762] phi display_info_smc::info_text#13 = main::info_text1 [phi:main::@1->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_smc.info_text
    lda #>info_text1
    sta.z display_info_smc.info_text+1
    // [762] phi smc_file_size#12 = 0 [phi:main::@1->display_info_smc#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size_2
    sta smc_file_size_2+1
    // [762] phi display_info_smc::info_status#13 = STATUS_ISSUE [phi:main::@1->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [579] phi from main::@1 to main::@99 [phi:main::@1->main::@99]
    // main::@99
    // display_progress_text(display_no_valid_smc_bootloader_text, display_no_valid_smc_bootloader_count)
    // [580] call display_progress_text
  // If the CX16 board does not have a bootloader, display info how to flash bootloader.
    // [818] phi from main::@99 to display_progress_text [phi:main::@99->display_progress_text]
    // [818] phi display_progress_text::text#10 = display_no_valid_smc_bootloader_text [phi:main::@99->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_no_valid_smc_bootloader_text
    sta.z display_progress_text.text
    lda #>display_no_valid_smc_bootloader_text
    sta.z display_progress_text.text+1
    // [818] phi display_progress_text::lines#7 = display_no_valid_smc_bootloader_count [phi:main::@99->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_no_valid_smc_bootloader_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    jmp CLI1
    // main::@13
  __b13:
    // display_info_led(PROGRESS_X + 3, PROGRESS_Y + 3 + intro_status, status_color[intro_status], BLUE)
    // [581] display_info_led::y#3 = PROGRESS_Y+3 + main::intro_status#2 -- vbuz1=vbuc1_plus_vbum2 
    lda #PROGRESS_Y+3
    clc
    adc intro_status
    sta.z display_info_led.y
    // [582] display_info_led::tc#3 = status_color[main::intro_status#2] -- vbuz1=pbuc1_derefidx_vbum2 
    ldy intro_status
    lda status_color,y
    sta.z display_info_led.tc
    // [583] call display_info_led
    // [1611] phi from main::@13 to display_info_led [phi:main::@13->display_info_led]
    // [1611] phi display_info_led::y#4 = display_info_led::y#3 [phi:main::@13->display_info_led#0] -- register_copy 
    // [1611] phi display_info_led::x#4 = PROGRESS_X+3 [phi:main::@13->display_info_led#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X+3
    sta.z display_info_led.x
    // [1611] phi display_info_led::tc#4 = display_info_led::tc#3 [phi:main::@13->display_info_led#2] -- register_copy 
    jsr display_info_led
    // main::@95
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [584] main::intro_status#1 = ++ main::intro_status#2 -- vbum1=_inc_vbum1 
    inc intro_status
    // [106] phi from main::@95 to main::@12 [phi:main::@95->main::@12]
    // [106] phi main::intro_status#2 = main::intro_status#1 [phi:main::@95->main::@12#0] -- register_copy 
    jmp __b12
    // main::@10
  __b10:
    // display_info_rom(rom_chip, STATUS_NONE, NULL)
    // [585] display_info_rom::rom_chip#4 = main::rom_chip#2 -- vbum1=vwum2 
    lda rom_chip
    sta display_info_rom.rom_chip
    // [586] call display_info_rom
    // [1074] phi from main::@10 to display_info_rom [phi:main::@10->display_info_rom]
    // [1074] phi display_info_rom::info_text#17 = 0 [phi:main::@10->display_info_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_rom.info_text
    sta.z display_info_rom.info_text+1
    // [1074] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#4 [phi:main::@10->display_info_rom#1] -- register_copy 
    // [1074] phi display_info_rom::info_status#17 = STATUS_NONE [phi:main::@10->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta display_info_rom.info_status
    jsr display_info_rom
    // main::@92
    // for(unsigned rom_chip=0; rom_chip<8; rom_chip++)
    // [587] main::rom_chip#1 = ++ main::rom_chip#2 -- vwum1=_inc_vwum1 
    inc rom_chip
    bne !+
    inc rom_chip+1
  !:
    // [98] phi from main::@92 to main::@9 [phi:main::@92->main::@9]
    // [98] phi main::rom_chip#2 = main::rom_chip#1 [phi:main::@92->main::@9#0] -- register_copy 
    jmp __b9
  .segment Data
    title_text: .text "Commander X16 Flash Utility!"
    .byte 0
    s: .text "# Chip Status    Type   File  / Total Information"
    .byte 0
    s1: .text "- ---- --------- ------ ----- / ----- --------------------"
    .byte 0
    info_text: .text "Introduction ..."
    .byte 0
    info_text1: .text "No Bootloader!"
    .byte 0
    info_text2: .text "SMC Unreachable!"
    .byte 0
    s2: .text "Bootloader v"
    .byte 0
    s3: .text " invalid! !"
    .byte 0
    s4: .text "SMC "
    .byte 0
    s5: .text ", BL v"
    .byte 0
    info_text3: .text "VERA installed, OK"
    .byte 0
    info_text6: .text "No SMC.BIN!"
    .byte 0
    info_text7: .text "SMC.BIN too large!"
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
    info_text8: .text "The SMC must also be flashable, check the SMC issue!"
    .byte 0
    info_text9: .text "The ROM must also be flashable, check the ROM issue."
    .byte 0
    info_text10: .text "Chipsets have been detected and update files validated!"
    .byte 0
    info_text11: .text "Continue with update of highlighted chipsets? [Y/N]"
    .byte 0
    filter: .text "nyNY"
    .byte 0
    main__220: .text "nN"
    .byte 0
    info_text12: .text "Cancelled"
    .byte 0
    info_text15: .text "You have selected not to cancel the update ... "
    .byte 0
    info_text16: .text "Press both POWER/RESET buttons on the CX16 board!"
    .byte 0
    info_text17: .text "Press POWER/RESET!"
    .byte 0
    info_text19: .text "SMC not updated!"
    .byte 0
    info_text20: .text "Update SMC failed!"
    .byte 0
    info_text21: .text "Comparing ... (.) same, (*) different."
    .byte 0
    info_text23: .text "No update required"
    .byte 0
    s16: .text " differences!"
    .byte 0
    s17: .text " flash errors!"
    .byte 0
    info_text24: .text "OK!"
    .byte 0
    info_text25: .text "The update has been cancelled!"
    .byte 0
    info_text26: .text "Update Failure! Your CX16 may be bricked!"
    .byte 0
    info_text27: .text "Take a foto of this screen. And shut down power ..."
    .byte 0
    info_text28: .text "Update issues, your CX16 is not updated!"
    .byte 0
    info_text29: .text "Your CX16 update is a success!"
    .byte 0
    s18: .text "("
    .byte 0
    s19: .text ") Please read carefully the below ..."
    .byte 0
    s20: .text "Please disconnect your CX16 from power source ..."
    .byte 0
    s22: .text ") Your CX16 will reset ..."
    .byte 0
    main__199: .byte 0
    main__203: .byte 0
    check_status_smc2_main__0: .byte 0
    check_status_card_roms1_check_status_rom1_main__0: .byte 0
    check_status_cx16_rom4_check_status_rom1_main__0: .byte 0
    check_status_vera1_main__0: .byte 0
    check_status_smc8_main__0: .byte 0
    check_status_vera3_main__0: .byte 0
    check_status_smc10_main__0: .byte 0
    rom_chip: .word 0
    intro_status: .byte 0
    rom_chip1: .byte 0
    .label check_status_smc2_return = check_status_smc2_main__0
    rom_chip2: .byte 0
    rom_bank: .byte 0
    file: .word 0
    .label rom_bytes_read = rom_read.return
    rom_file_modulo: .dword 0
    .label check_status_card_roms1_check_status_rom1_return = check_status_card_roms1_check_status_rom1_main__0
    check_status_card_roms1_rom_chip: .byte 0
    check_status_card_roms1_return: .byte 0
    .label check_status_cx16_rom4_check_status_rom1_return = check_status_cx16_rom4_check_status_rom1_main__0
    rom_chip3: .byte 0
    flashed_bytes: .dword 0
    .label check_status_vera1_return = check_status_vera1_main__0
    check_status_roms_all1_rom_chip: .byte 0
    check_status_roms_all1_return: .byte 0
    rom_chip4: .byte 0
    rom_bank1: .byte 0
    .label file1 = rom_file.return
    .label rom_bytes_read1 = rom_read.return
    rom_flash_errors: .dword 0
    .label check_status_smc8_return = check_status_smc8_main__0
    check_status_roms1_rom_chip: .byte 0
    check_status_roms1_return: .byte 0
    .label check_status_vera3_return = check_status_vera3_main__0
    check_status_roms2_rom_chip: .byte 0
    check_status_roms2_return: .byte 0
    .label check_status_smc10_return = check_status_smc10_main__0
    w: .byte 0
    w1: .byte 0
}
.segment Code
  // screenlayer1
// Set the layer with which the conio will interact.
screenlayer1: {
    // screenlayer(1, *VERA_L1_MAPBASE, *VERA_L1_CONFIG)
    // [588] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbuz1=_deref_pbuc1 
    lda VERA_L1_MAPBASE
    sta.z screenlayer.mapbase
    // [589] screenlayer::config#0 = *VERA_L1_CONFIG -- vbuz1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta.z screenlayer.config
    // [590] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [591] return 
    rts
}
  // textcolor
// Set the front color for text output. The old front text color setting is returned.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char textcolor(__zp($df) char color)
textcolor: {
    .label textcolor__0 = $e1
    .label textcolor__1 = $df
    .label color = $df
    // __conio.color & 0xF0
    // [593] textcolor::$0 = *((char *)&__conio+$d) & $f0 -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$d
    sta.z textcolor__0
    // __conio.color & 0xF0 | color
    // [594] textcolor::$1 = textcolor::$0 | textcolor::color#18 -- vbuz1=vbuz2_bor_vbuz1 
    lda.z textcolor__1
    ora.z textcolor__0
    sta.z textcolor__1
    // __conio.color = __conio.color & 0xF0 | color
    // [595] *((char *)&__conio+$d) = textcolor::$1 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // textcolor::@return
    // }
    // [596] return 
    rts
}
  // bgcolor
// Set the back color for text output.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char bgcolor(__zp($df) char color)
bgcolor: {
    .label bgcolor__0 = $e0
    .label bgcolor__1 = $df
    .label bgcolor__2 = $e0
    .label color = $df
    // __conio.color & 0x0F
    // [598] bgcolor::$0 = *((char *)&__conio+$d) & $f -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$d
    sta.z bgcolor__0
    // color << 4
    // [599] bgcolor::$1 = bgcolor::color#14 << 4 -- vbuz1=vbuz1_rol_4 
    lda.z bgcolor__1
    asl
    asl
    asl
    asl
    sta.z bgcolor__1
    // __conio.color & 0x0F | color << 4
    // [600] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbuz1=vbuz1_bor_vbuz2 
    lda.z bgcolor__2
    ora.z bgcolor__1
    sta.z bgcolor__2
    // __conio.color = __conio.color & 0x0F | color << 4
    // [601] *((char *)&__conio+$d) = bgcolor::$2 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // bgcolor::@return
    // }
    // [602] return 
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
    // [603] *((char *)&__conio+$c) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$c
    // cursor::@return
    // }
    // [604] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    // __mem unsigned char x
    // [605] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [606] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [608] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwum1=vbum2_word_vbum3 
    lda x
    sta return+1
    lda y
    sta return
    // cbm_k_plot_get::@return
    // }
    // [609] return 
    rts
  .segment Data
    x: .byte 0
    y: .byte 0
    return: .word 0
}
.segment Code
  // gotoxy
// Set the cursor to the specified position
// void gotoxy(__zp($48) char x, __zp($49) char y)
gotoxy: {
    .label gotoxy__2 = $48
    .label gotoxy__3 = $48
    .label gotoxy__6 = $47
    .label gotoxy__7 = $47
    .label gotoxy__8 = $4c
    .label gotoxy__9 = $4a
    .label gotoxy__10 = $49
    .label x = $48
    .label y = $49
    .label gotoxy__14 = $47
    // (x>=__conio.width)?__conio.width:x
    // [611] if(gotoxy::x#30>=*((char *)&__conio+6)) goto gotoxy::@1 -- vbuz1_ge__deref_pbuc1_then_la1 
    lda.z x
    cmp __conio+6
    bcs __b1
    // [613] phi from gotoxy gotoxy::@1 to gotoxy::@2 [phi:gotoxy/gotoxy::@1->gotoxy::@2]
    // [613] phi gotoxy::$3 = gotoxy::x#30 [phi:gotoxy/gotoxy::@1->gotoxy::@2#0] -- register_copy 
    jmp __b2
    // gotoxy::@1
  __b1:
    // [612] gotoxy::$2 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z gotoxy__2
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [614] *((char *)&__conio) = gotoxy::$3 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__3
    sta __conio
    // (y>=__conio.height)?__conio.height:y
    // [615] if(gotoxy::y#30>=*((char *)&__conio+7)) goto gotoxy::@3 -- vbuz1_ge__deref_pbuc1_then_la1 
    lda.z y
    cmp __conio+7
    bcs __b3
    // gotoxy::@4
    // [616] gotoxy::$14 = gotoxy::y#30 -- vbuz1=vbuz2 
    sta.z gotoxy__14
    // [617] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [617] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [618] *((char *)&__conio+1) = gotoxy::$7 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__7
    sta __conio+1
    // __conio.cursor_x << 1
    // [619] gotoxy::$8 = *((char *)&__conio) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio
    asl
    sta.z gotoxy__8
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [620] gotoxy::$10 = gotoxy::y#30 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z gotoxy__10
    // [621] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwuz1=pwuc1_derefidx_vbuz2_plus_vbuz3 
    ldy.z gotoxy__10
    clc
    adc __conio+$15,y
    sta.z gotoxy__9
    lda __conio+$15+1,y
    adc #0
    sta.z gotoxy__9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [622] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwuz1 
    lda.z gotoxy__9
    sta __conio+$13
    lda.z gotoxy__9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [623] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [624] gotoxy::$6 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
    lda __conio+7
    sta.z gotoxy__6
    jmp __b5
}
  // cputln
// Print a newline
cputln: {
    .label cputln__2 = $6c
    // __conio.cursor_x = 0
    // [625] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y++;
    // [626] *((char *)&__conio+1) = ++ *((char *)&__conio+1) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+1
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [627] cputln::$2 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z cputln__2
    // [628] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [629] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [630] return 
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
    // textcolor(WHITE)
    // [632] call textcolor
  // Set the charset to lower case.
  // screenlayer1();
    // [592] phi from display_frame_init_64 to textcolor [phi:display_frame_init_64->textcolor]
    // [592] phi textcolor::color#18 = WHITE [phi:display_frame_init_64->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [633] phi from display_frame_init_64 to display_frame_init_64::@2 [phi:display_frame_init_64->display_frame_init_64::@2]
    // display_frame_init_64::@2
    // bgcolor(BLUE)
    // [634] call bgcolor
    // [597] phi from display_frame_init_64::@2 to bgcolor [phi:display_frame_init_64::@2->bgcolor]
    // [597] phi bgcolor::color#14 = BLUE [phi:display_frame_init_64::@2->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [635] phi from display_frame_init_64::@2 to display_frame_init_64::@3 [phi:display_frame_init_64::@2->display_frame_init_64::@3]
    // display_frame_init_64::@3
    // scroll(0)
    // [636] call scroll
    jsr scroll
    // [637] phi from display_frame_init_64::@3 to display_frame_init_64::@4 [phi:display_frame_init_64::@3->display_frame_init_64::@4]
    // display_frame_init_64::@4
    // clrscr()
    // [638] call clrscr
    jsr clrscr
    // display_frame_init_64::vera_display_set_hstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [639] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTART = start
    // [640] *VERA_DC_HSTART = display_frame_init_64::vera_display_set_hstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstart1_start
    sta VERA_DC_HSTART
    // display_frame_init_64::vera_display_set_hstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [641] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTOP = stop
    // [642] *VERA_DC_HSTOP = display_frame_init_64::vera_display_set_hstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstop1_stop
    sta VERA_DC_HSTOP
    // display_frame_init_64::vera_display_set_vstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [643] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTART = start
    // [644] *VERA_DC_VSTART = display_frame_init_64::vera_display_set_vstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstart1_start
    sta VERA_DC_VSTART
    // display_frame_init_64::vera_display_set_vstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [645] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTOP = stop
    // [646] *VERA_DC_VSTOP = display_frame_init_64::vera_display_set_vstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstop1_stop
    sta VERA_DC_VSTOP
    // display_frame_init_64::@1
    // cx16_k_screen_set_charset(3, (char *)0)
    // [647] display_frame_init_64::cx16_k_screen_set_charset1_charset = 3 -- vbum1=vbuc1 
    lda #3
    sta cx16_k_screen_set_charset1_charset
    // [648] display_frame_init_64::cx16_k_screen_set_charset1_offset = (char *) 0 -- pbum1=pbuc1 
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
    // display_frame_init_64::@return
    // }
    // [650] return 
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
    // [652] call textcolor
    // [592] phi from display_frame_draw to textcolor [phi:display_frame_draw->textcolor]
    // [592] phi textcolor::color#18 = LIGHT_BLUE [phi:display_frame_draw->textcolor#0] -- vbuz1=vbuc1 
    lda #LIGHT_BLUE
    sta.z textcolor.color
    jsr textcolor
    // [653] phi from display_frame_draw to display_frame_draw::@1 [phi:display_frame_draw->display_frame_draw::@1]
    // display_frame_draw::@1
    // bgcolor(BLUE)
    // [654] call bgcolor
    // [597] phi from display_frame_draw::@1 to bgcolor [phi:display_frame_draw::@1->bgcolor]
    // [597] phi bgcolor::color#14 = BLUE [phi:display_frame_draw::@1->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [655] phi from display_frame_draw::@1 to display_frame_draw::@2 [phi:display_frame_draw::@1->display_frame_draw::@2]
    // display_frame_draw::@2
    // clrscr()
    // [656] call clrscr
    jsr clrscr
    // [657] phi from display_frame_draw::@2 to display_frame_draw::@3 [phi:display_frame_draw::@2->display_frame_draw::@3]
    // display_frame_draw::@3
    // display_frame(0, 0, 67, 14)
    // [658] call display_frame
    // [1693] phi from display_frame_draw::@3 to display_frame [phi:display_frame_draw::@3->display_frame]
    // [1693] phi display_frame::y#0 = 0 [phi:display_frame_draw::@3->display_frame#0] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.y
    // [1693] phi display_frame::y1#16 = $e [phi:display_frame_draw::@3->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1693] phi display_frame::x#0 = 0 [phi:display_frame_draw::@3->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1693] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@3->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [659] phi from display_frame_draw::@3 to display_frame_draw::@4 [phi:display_frame_draw::@3->display_frame_draw::@4]
    // display_frame_draw::@4
    // display_frame(0, 0, 67, 2)
    // [660] call display_frame
    // [1693] phi from display_frame_draw::@4 to display_frame [phi:display_frame_draw::@4->display_frame]
    // [1693] phi display_frame::y#0 = 0 [phi:display_frame_draw::@4->display_frame#0] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.y
    // [1693] phi display_frame::y1#16 = 2 [phi:display_frame_draw::@4->display_frame#1] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y1
    // [1693] phi display_frame::x#0 = 0 [phi:display_frame_draw::@4->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1693] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@4->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [661] phi from display_frame_draw::@4 to display_frame_draw::@5 [phi:display_frame_draw::@4->display_frame_draw::@5]
    // display_frame_draw::@5
    // display_frame(0, 2, 67, 14)
    // [662] call display_frame
    // [1693] phi from display_frame_draw::@5 to display_frame [phi:display_frame_draw::@5->display_frame]
    // [1693] phi display_frame::y#0 = 2 [phi:display_frame_draw::@5->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1693] phi display_frame::y1#16 = $e [phi:display_frame_draw::@5->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1693] phi display_frame::x#0 = 0 [phi:display_frame_draw::@5->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1693] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@5->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [663] phi from display_frame_draw::@5 to display_frame_draw::@6 [phi:display_frame_draw::@5->display_frame_draw::@6]
    // display_frame_draw::@6
    // display_frame(0, 2, 8, 14)
    // [664] call display_frame
  // Chipset areas
    // [1693] phi from display_frame_draw::@6 to display_frame [phi:display_frame_draw::@6->display_frame]
    // [1693] phi display_frame::y#0 = 2 [phi:display_frame_draw::@6->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1693] phi display_frame::y1#16 = $e [phi:display_frame_draw::@6->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1693] phi display_frame::x#0 = 0 [phi:display_frame_draw::@6->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1693] phi display_frame::x1#16 = 8 [phi:display_frame_draw::@6->display_frame#3] -- vbuz1=vbuc1 
    lda #8
    sta.z display_frame.x1
    jsr display_frame
    // [665] phi from display_frame_draw::@6 to display_frame_draw::@7 [phi:display_frame_draw::@6->display_frame_draw::@7]
    // display_frame_draw::@7
    // display_frame(8, 2, 19, 14)
    // [666] call display_frame
    // [1693] phi from display_frame_draw::@7 to display_frame [phi:display_frame_draw::@7->display_frame]
    // [1693] phi display_frame::y#0 = 2 [phi:display_frame_draw::@7->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1693] phi display_frame::y1#16 = $e [phi:display_frame_draw::@7->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1693] phi display_frame::x#0 = 8 [phi:display_frame_draw::@7->display_frame#2] -- vbuz1=vbuc1 
    lda #8
    sta.z display_frame.x
    // [1693] phi display_frame::x1#16 = $13 [phi:display_frame_draw::@7->display_frame#3] -- vbuz1=vbuc1 
    lda #$13
    sta.z display_frame.x1
    jsr display_frame
    // [667] phi from display_frame_draw::@7 to display_frame_draw::@8 [phi:display_frame_draw::@7->display_frame_draw::@8]
    // display_frame_draw::@8
    // display_frame(19, 2, 25, 14)
    // [668] call display_frame
    // [1693] phi from display_frame_draw::@8 to display_frame [phi:display_frame_draw::@8->display_frame]
    // [1693] phi display_frame::y#0 = 2 [phi:display_frame_draw::@8->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1693] phi display_frame::y1#16 = $e [phi:display_frame_draw::@8->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1693] phi display_frame::x#0 = $13 [phi:display_frame_draw::@8->display_frame#2] -- vbuz1=vbuc1 
    lda #$13
    sta.z display_frame.x
    // [1693] phi display_frame::x1#16 = $19 [phi:display_frame_draw::@8->display_frame#3] -- vbuz1=vbuc1 
    lda #$19
    sta.z display_frame.x1
    jsr display_frame
    // [669] phi from display_frame_draw::@8 to display_frame_draw::@9 [phi:display_frame_draw::@8->display_frame_draw::@9]
    // display_frame_draw::@9
    // display_frame(25, 2, 31, 14)
    // [670] call display_frame
    // [1693] phi from display_frame_draw::@9 to display_frame [phi:display_frame_draw::@9->display_frame]
    // [1693] phi display_frame::y#0 = 2 [phi:display_frame_draw::@9->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1693] phi display_frame::y1#16 = $e [phi:display_frame_draw::@9->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1693] phi display_frame::x#0 = $19 [phi:display_frame_draw::@9->display_frame#2] -- vbuz1=vbuc1 
    lda #$19
    sta.z display_frame.x
    // [1693] phi display_frame::x1#16 = $1f [phi:display_frame_draw::@9->display_frame#3] -- vbuz1=vbuc1 
    lda #$1f
    sta.z display_frame.x1
    jsr display_frame
    // [671] phi from display_frame_draw::@9 to display_frame_draw::@10 [phi:display_frame_draw::@9->display_frame_draw::@10]
    // display_frame_draw::@10
    // display_frame(31, 2, 37, 14)
    // [672] call display_frame
    // [1693] phi from display_frame_draw::@10 to display_frame [phi:display_frame_draw::@10->display_frame]
    // [1693] phi display_frame::y#0 = 2 [phi:display_frame_draw::@10->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1693] phi display_frame::y1#16 = $e [phi:display_frame_draw::@10->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1693] phi display_frame::x#0 = $1f [phi:display_frame_draw::@10->display_frame#2] -- vbuz1=vbuc1 
    lda #$1f
    sta.z display_frame.x
    // [1693] phi display_frame::x1#16 = $25 [phi:display_frame_draw::@10->display_frame#3] -- vbuz1=vbuc1 
    lda #$25
    sta.z display_frame.x1
    jsr display_frame
    // [673] phi from display_frame_draw::@10 to display_frame_draw::@11 [phi:display_frame_draw::@10->display_frame_draw::@11]
    // display_frame_draw::@11
    // display_frame(37, 2, 43, 14)
    // [674] call display_frame
    // [1693] phi from display_frame_draw::@11 to display_frame [phi:display_frame_draw::@11->display_frame]
    // [1693] phi display_frame::y#0 = 2 [phi:display_frame_draw::@11->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1693] phi display_frame::y1#16 = $e [phi:display_frame_draw::@11->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1693] phi display_frame::x#0 = $25 [phi:display_frame_draw::@11->display_frame#2] -- vbuz1=vbuc1 
    lda #$25
    sta.z display_frame.x
    // [1693] phi display_frame::x1#16 = $2b [phi:display_frame_draw::@11->display_frame#3] -- vbuz1=vbuc1 
    lda #$2b
    sta.z display_frame.x1
    jsr display_frame
    // [675] phi from display_frame_draw::@11 to display_frame_draw::@12 [phi:display_frame_draw::@11->display_frame_draw::@12]
    // display_frame_draw::@12
    // display_frame(43, 2, 49, 14)
    // [676] call display_frame
    // [1693] phi from display_frame_draw::@12 to display_frame [phi:display_frame_draw::@12->display_frame]
    // [1693] phi display_frame::y#0 = 2 [phi:display_frame_draw::@12->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1693] phi display_frame::y1#16 = $e [phi:display_frame_draw::@12->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1693] phi display_frame::x#0 = $2b [phi:display_frame_draw::@12->display_frame#2] -- vbuz1=vbuc1 
    lda #$2b
    sta.z display_frame.x
    // [1693] phi display_frame::x1#16 = $31 [phi:display_frame_draw::@12->display_frame#3] -- vbuz1=vbuc1 
    lda #$31
    sta.z display_frame.x1
    jsr display_frame
    // [677] phi from display_frame_draw::@12 to display_frame_draw::@13 [phi:display_frame_draw::@12->display_frame_draw::@13]
    // display_frame_draw::@13
    // display_frame(49, 2, 55, 14)
    // [678] call display_frame
    // [1693] phi from display_frame_draw::@13 to display_frame [phi:display_frame_draw::@13->display_frame]
    // [1693] phi display_frame::y#0 = 2 [phi:display_frame_draw::@13->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1693] phi display_frame::y1#16 = $e [phi:display_frame_draw::@13->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1693] phi display_frame::x#0 = $31 [phi:display_frame_draw::@13->display_frame#2] -- vbuz1=vbuc1 
    lda #$31
    sta.z display_frame.x
    // [1693] phi display_frame::x1#16 = $37 [phi:display_frame_draw::@13->display_frame#3] -- vbuz1=vbuc1 
    lda #$37
    sta.z display_frame.x1
    jsr display_frame
    // [679] phi from display_frame_draw::@13 to display_frame_draw::@14 [phi:display_frame_draw::@13->display_frame_draw::@14]
    // display_frame_draw::@14
    // display_frame(55, 2, 61, 14)
    // [680] call display_frame
    // [1693] phi from display_frame_draw::@14 to display_frame [phi:display_frame_draw::@14->display_frame]
    // [1693] phi display_frame::y#0 = 2 [phi:display_frame_draw::@14->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1693] phi display_frame::y1#16 = $e [phi:display_frame_draw::@14->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1693] phi display_frame::x#0 = $37 [phi:display_frame_draw::@14->display_frame#2] -- vbuz1=vbuc1 
    lda #$37
    sta.z display_frame.x
    // [1693] phi display_frame::x1#16 = $3d [phi:display_frame_draw::@14->display_frame#3] -- vbuz1=vbuc1 
    lda #$3d
    sta.z display_frame.x1
    jsr display_frame
    // [681] phi from display_frame_draw::@14 to display_frame_draw::@15 [phi:display_frame_draw::@14->display_frame_draw::@15]
    // display_frame_draw::@15
    // display_frame(61, 2, 67, 14)
    // [682] call display_frame
    // [1693] phi from display_frame_draw::@15 to display_frame [phi:display_frame_draw::@15->display_frame]
    // [1693] phi display_frame::y#0 = 2 [phi:display_frame_draw::@15->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1693] phi display_frame::y1#16 = $e [phi:display_frame_draw::@15->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1693] phi display_frame::x#0 = $3d [phi:display_frame_draw::@15->display_frame#2] -- vbuz1=vbuc1 
    lda #$3d
    sta.z display_frame.x
    // [1693] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@15->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [683] phi from display_frame_draw::@15 to display_frame_draw::@16 [phi:display_frame_draw::@15->display_frame_draw::@16]
    // display_frame_draw::@16
    // display_frame(0, 14, 67, PROGRESS_Y-5)
    // [684] call display_frame
  // Progress area
    // [1693] phi from display_frame_draw::@16 to display_frame [phi:display_frame_draw::@16->display_frame]
    // [1693] phi display_frame::y#0 = $e [phi:display_frame_draw::@16->display_frame#0] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y
    // [1693] phi display_frame::y1#16 = PROGRESS_Y-5 [phi:display_frame_draw::@16->display_frame#1] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-5
    sta.z display_frame.y1
    // [1693] phi display_frame::x#0 = 0 [phi:display_frame_draw::@16->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1693] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@16->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [685] phi from display_frame_draw::@16 to display_frame_draw::@17 [phi:display_frame_draw::@16->display_frame_draw::@17]
    // display_frame_draw::@17
    // display_frame(0, PROGRESS_Y-5, 67, PROGRESS_Y-2)
    // [686] call display_frame
    // [1693] phi from display_frame_draw::@17 to display_frame [phi:display_frame_draw::@17->display_frame]
    // [1693] phi display_frame::y#0 = PROGRESS_Y-5 [phi:display_frame_draw::@17->display_frame#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-5
    sta.z display_frame.y
    // [1693] phi display_frame::y1#16 = PROGRESS_Y-2 [phi:display_frame_draw::@17->display_frame#1] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-2
    sta.z display_frame.y1
    // [1693] phi display_frame::x#0 = 0 [phi:display_frame_draw::@17->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1693] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@17->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [687] phi from display_frame_draw::@17 to display_frame_draw::@18 [phi:display_frame_draw::@17->display_frame_draw::@18]
    // display_frame_draw::@18
    // display_frame(0, PROGRESS_Y-2, 67, 49)
    // [688] call display_frame
    // [1693] phi from display_frame_draw::@18 to display_frame [phi:display_frame_draw::@18->display_frame]
    // [1693] phi display_frame::y#0 = PROGRESS_Y-2 [phi:display_frame_draw::@18->display_frame#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-2
    sta.z display_frame.y
    // [1693] phi display_frame::y1#16 = $31 [phi:display_frame_draw::@18->display_frame#1] -- vbuz1=vbuc1 
    lda #$31
    sta.z display_frame.y1
    // [1693] phi display_frame::x#0 = 0 [phi:display_frame_draw::@18->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1693] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@18->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [689] phi from display_frame_draw::@18 to display_frame_draw::@19 [phi:display_frame_draw::@18->display_frame_draw::@19]
    // display_frame_draw::@19
    // textcolor(WHITE)
    // [690] call textcolor
    // [592] phi from display_frame_draw::@19 to textcolor [phi:display_frame_draw::@19->textcolor]
    // [592] phi textcolor::color#18 = WHITE [phi:display_frame_draw::@19->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // display_frame_draw::@return
    // }
    // [691] return 
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
    // [693] call gotoxy
    // [610] phi from display_frame_title to gotoxy [phi:display_frame_title->gotoxy]
    // [610] phi gotoxy::y#30 = 1 [phi:display_frame_title->gotoxy#0] -- vbuz1=vbuc1 
    lda #1
    sta.z gotoxy.y
    // [610] phi gotoxy::x#30 = 2 [phi:display_frame_title->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // [694] phi from display_frame_title to display_frame_title::@1 [phi:display_frame_title->display_frame_title::@1]
    // display_frame_title::@1
    // printf("%-65s", title_text)
    // [695] call printf_string
    // [886] phi from display_frame_title::@1 to printf_string [phi:display_frame_title::@1->printf_string]
    // [886] phi printf_string::putc#19 = &cputc [phi:display_frame_title::@1->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [886] phi printf_string::str#19 = main::title_text [phi:display_frame_title::@1->printf_string#1] -- pbuz1=pbuc1 
    lda #<main.title_text
    sta.z printf_string.str
    lda #>main.title_text
    sta.z printf_string.str+1
    // [886] phi printf_string::format_justify_left#19 = 1 [phi:display_frame_title::@1->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [886] phi printf_string::format_min_length#19 = $41 [phi:display_frame_title::@1->printf_string#3] -- vbuz1=vbuc1 
    lda #$41
    sta.z printf_string.format_min_length
    jsr printf_string
    // display_frame_title::@return
    // }
    // [696] return 
    rts
}
  // cputsxy
// Move cursor and output a NUL-terminated string
// Same as "gotoxy (x, y); puts (s);"
// void cputsxy(__zp($2d) char x, __mem() char y, __zp($b1) const char *s)
cputsxy: {
    .label s = $b1
    .label x = $2d
    // gotoxy(x, y)
    // [698] gotoxy::x#1 = cputsxy::x#4 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [699] gotoxy::y#1 = cputsxy::y#4 -- vbuz1=vbum2 
    lda y
    sta.z gotoxy.y
    // [700] call gotoxy
    // [610] phi from cputsxy to gotoxy [phi:cputsxy->gotoxy]
    // [610] phi gotoxy::y#30 = gotoxy::y#1 [phi:cputsxy->gotoxy#0] -- register_copy 
    // [610] phi gotoxy::x#30 = gotoxy::x#1 [phi:cputsxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputsxy::@1
    // cputs(s)
    // [701] cputs::s#1 = cputsxy::s#4 -- pbuz1=pbuz2 
    lda.z s
    sta.z cputs.s
    lda.z s+1
    sta.z cputs.s+1
    // [702] call cputs
    // [1827] phi from cputsxy::@1 to cputs [phi:cputsxy::@1->cputs]
    jsr cputs
    // cputsxy::@return
    // }
    // [703] return 
    rts
  .segment Data
    .label y = main.check_status_smc2_main__0
}
.segment Code
  // display_action_progress
/**
 * @brief Print the progress at the action frame, which is the first line.
 * 
 * @param info_text The progress text to be displayed.
 */
// void display_action_progress(__zp($60) char *info_text)
display_action_progress: {
    .label x = $6a
    .label y = $2c
    .label info_text = $60
    // unsigned char x = wherex()
    // [705] call wherex
    jsr wherex
    // [706] wherex::return#2 = wherex::return#0
    // display_action_progress::@1
    // [707] display_action_progress::x#0 = wherex::return#2
    // unsigned char y = wherey()
    // [708] call wherey
    jsr wherey
    // [709] wherey::return#2 = wherey::return#0
    // display_action_progress::@2
    // [710] display_action_progress::y#0 = wherey::return#2
    // gotoxy(2, PROGRESS_Y-4)
    // [711] call gotoxy
    // [610] phi from display_action_progress::@2 to gotoxy [phi:display_action_progress::@2->gotoxy]
    // [610] phi gotoxy::y#30 = PROGRESS_Y-4 [phi:display_action_progress::@2->gotoxy#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-4
    sta.z gotoxy.y
    // [610] phi gotoxy::x#30 = 2 [phi:display_action_progress::@2->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // display_action_progress::@3
    // printf("%-65s", info_text)
    // [712] printf_string::str#1 = display_action_progress::info_text#15
    // [713] call printf_string
    // [886] phi from display_action_progress::@3 to printf_string [phi:display_action_progress::@3->printf_string]
    // [886] phi printf_string::putc#19 = &cputc [phi:display_action_progress::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [886] phi printf_string::str#19 = printf_string::str#1 [phi:display_action_progress::@3->printf_string#1] -- register_copy 
    // [886] phi printf_string::format_justify_left#19 = 1 [phi:display_action_progress::@3->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [886] phi printf_string::format_min_length#19 = $41 [phi:display_action_progress::@3->printf_string#3] -- vbuz1=vbuc1 
    lda #$41
    sta.z printf_string.format_min_length
    jsr printf_string
    // display_action_progress::@4
    // gotoxy(x, y)
    // [714] gotoxy::x#10 = display_action_progress::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [715] gotoxy::y#10 = display_action_progress::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [716] call gotoxy
    // [610] phi from display_action_progress::@4 to gotoxy [phi:display_action_progress::@4->gotoxy]
    // [610] phi gotoxy::y#30 = gotoxy::y#10 [phi:display_action_progress::@4->gotoxy#0] -- register_copy 
    // [610] phi gotoxy::x#30 = gotoxy::x#10 [phi:display_action_progress::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_action_progress::@return
    // }
    // [717] return 
    rts
}
  // display_progress_clear
/**
 * @brief Clean the progress area for the flashing.
 */
display_progress_clear: {
    .const h = PROGRESS_Y+PROGRESS_H
    .label x = $e2
    .label y = $2d
    // textcolor(WHITE)
    // [719] call textcolor
    // [592] phi from display_progress_clear to textcolor [phi:display_progress_clear->textcolor]
    // [592] phi textcolor::color#18 = WHITE [phi:display_progress_clear->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [720] phi from display_progress_clear to display_progress_clear::@5 [phi:display_progress_clear->display_progress_clear::@5]
    // display_progress_clear::@5
    // bgcolor(BLUE)
    // [721] call bgcolor
    // [597] phi from display_progress_clear::@5 to bgcolor [phi:display_progress_clear::@5->bgcolor]
    // [597] phi bgcolor::color#14 = BLUE [phi:display_progress_clear::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [722] phi from display_progress_clear::@5 to display_progress_clear::@1 [phi:display_progress_clear::@5->display_progress_clear::@1]
    // [722] phi display_progress_clear::y#2 = PROGRESS_Y [phi:display_progress_clear::@5->display_progress_clear::@1#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // display_progress_clear::@1
  __b1:
    // while (y < h)
    // [723] if(display_progress_clear::y#2<display_progress_clear::h) goto display_progress_clear::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y
    cmp #h
    bcc __b4
    // display_progress_clear::@return
    // }
    // [724] return 
    rts
    // [725] phi from display_progress_clear::@1 to display_progress_clear::@2 [phi:display_progress_clear::@1->display_progress_clear::@2]
  __b4:
    // [725] phi display_progress_clear::x#2 = PROGRESS_X [phi:display_progress_clear::@1->display_progress_clear::@2#0] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z x
    // [725] phi display_progress_clear::i#2 = 0 [phi:display_progress_clear::@1->display_progress_clear::@2#1] -- vbum1=vbuc1 
    lda #0
    sta i
    // display_progress_clear::@2
  __b2:
    // for(unsigned char i = 0; i < w; i++)
    // [726] if(display_progress_clear::i#2<PROGRESS_W) goto display_progress_clear::@3 -- vbum1_lt_vbuc1_then_la1 
    lda i
    cmp #PROGRESS_W
    bcc __b3
    // display_progress_clear::@4
    // y++;
    // [727] display_progress_clear::y#1 = ++ display_progress_clear::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [722] phi from display_progress_clear::@4 to display_progress_clear::@1 [phi:display_progress_clear::@4->display_progress_clear::@1]
    // [722] phi display_progress_clear::y#2 = display_progress_clear::y#1 [phi:display_progress_clear::@4->display_progress_clear::@1#0] -- register_copy 
    jmp __b1
    // display_progress_clear::@3
  __b3:
    // cputcxy(x, y, ' ')
    // [728] cputcxy::x#12 = display_progress_clear::x#2 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [729] cputcxy::y#12 = display_progress_clear::y#2 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [730] call cputcxy
    // [1840] phi from display_progress_clear::@3 to cputcxy [phi:display_progress_clear::@3->cputcxy]
    // [1840] phi cputcxy::c#15 = ' ' [phi:display_progress_clear::@3->cputcxy#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z cputcxy.c
    // [1840] phi cputcxy::y#15 = cputcxy::y#12 [phi:display_progress_clear::@3->cputcxy#1] -- register_copy 
    // [1840] phi cputcxy::x#15 = cputcxy::x#12 [phi:display_progress_clear::@3->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_progress_clear::@6
    // x++;
    // [731] display_progress_clear::x#1 = ++ display_progress_clear::x#2 -- vbuz1=_inc_vbuz1 
    inc.z x
    // for(unsigned char i = 0; i < w; i++)
    // [732] display_progress_clear::i#1 = ++ display_progress_clear::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [725] phi from display_progress_clear::@6 to display_progress_clear::@2 [phi:display_progress_clear::@6->display_progress_clear::@2]
    // [725] phi display_progress_clear::x#2 = display_progress_clear::x#1 [phi:display_progress_clear::@6->display_progress_clear::@2#0] -- register_copy 
    // [725] phi display_progress_clear::i#2 = display_progress_clear::i#1 [phi:display_progress_clear::@6->display_progress_clear::@2#1] -- register_copy 
    jmp __b2
  .segment Data
    .label i = main.check_status_smc2_main__0
}
.segment Code
  // display_chip_smc
display_chip_smc: {
    // display_smc_led(GREY)
    // [734] call display_smc_led
    // [1848] phi from display_chip_smc to display_smc_led [phi:display_chip_smc->display_smc_led]
    // [1848] phi display_smc_led::c#2 = GREY [phi:display_chip_smc->display_smc_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z display_smc_led.c
    jsr display_smc_led
    // [735] phi from display_chip_smc to display_chip_smc::@1 [phi:display_chip_smc->display_chip_smc::@1]
    // display_chip_smc::@1
    // display_print_chip(CHIP_SMC_X, CHIP_SMC_Y+2, CHIP_SMC_W, "SMC     ")
    // [736] call display_print_chip
    // [1854] phi from display_chip_smc::@1 to display_print_chip [phi:display_chip_smc::@1->display_print_chip]
    // [1854] phi display_print_chip::text#11 = display_chip_smc::text [phi:display_chip_smc::@1->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_print_chip.text_2
    lda #>text
    sta.z display_print_chip.text_2+1
    // [1854] phi display_print_chip::w#10 = 5 [phi:display_chip_smc::@1->display_print_chip#1] -- vbuz1=vbuc1 
    lda #5
    sta.z display_print_chip.w
    // [1854] phi display_print_chip::x#10 = 1 [phi:display_chip_smc::@1->display_print_chip#2] -- vbuz1=vbuc1 
    lda #1
    sta.z display_print_chip.x
    jsr display_print_chip
    // display_chip_smc::@return
    // }
    // [737] return 
    rts
  .segment Data
    text: .text "SMC     "
    .byte 0
}
.segment Code
  // display_chip_vera
display_chip_vera: {
    // display_vera_led(GREY)
    // [739] call display_vera_led
    // [1898] phi from display_chip_vera to display_vera_led [phi:display_chip_vera->display_vera_led]
    // [1898] phi display_vera_led::c#2 = GREY [phi:display_chip_vera->display_vera_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z display_vera_led.c
    jsr display_vera_led
    // [740] phi from display_chip_vera to display_chip_vera::@1 [phi:display_chip_vera->display_chip_vera::@1]
    // display_chip_vera::@1
    // display_print_chip(CHIP_VERA_X, CHIP_VERA_Y+2, CHIP_VERA_W, "VERA     ")
    // [741] call display_print_chip
    // [1854] phi from display_chip_vera::@1 to display_print_chip [phi:display_chip_vera::@1->display_print_chip]
    // [1854] phi display_print_chip::text#11 = display_chip_vera::text [phi:display_chip_vera::@1->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_print_chip.text_2
    lda #>text
    sta.z display_print_chip.text_2+1
    // [1854] phi display_print_chip::w#10 = 8 [phi:display_chip_vera::@1->display_print_chip#1] -- vbuz1=vbuc1 
    lda #8
    sta.z display_print_chip.w
    // [1854] phi display_print_chip::x#10 = 9 [phi:display_chip_vera::@1->display_print_chip#2] -- vbuz1=vbuc1 
    lda #9
    sta.z display_print_chip.x
    jsr display_print_chip
    // display_chip_vera::@return
    // }
    // [742] return 
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
    .label display_chip_rom__4 = $6a
    .label display_chip_rom__6 = $be
    .label r = $e3
    // [744] phi from display_chip_rom to display_chip_rom::@1 [phi:display_chip_rom->display_chip_rom::@1]
    // [744] phi display_chip_rom::r#2 = 0 [phi:display_chip_rom->display_chip_rom::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z r
    // display_chip_rom::@1
  __b1:
    // for (unsigned char r = 0; r < 8; r++)
    // [745] if(display_chip_rom::r#2<8) goto display_chip_rom::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z r
    cmp #8
    bcc __b2
    // display_chip_rom::@return
    // }
    // [746] return 
    rts
    // [747] phi from display_chip_rom::@1 to display_chip_rom::@2 [phi:display_chip_rom::@1->display_chip_rom::@2]
    // display_chip_rom::@2
  __b2:
    // strcpy(rom, "ROM  ")
    // [748] call strcpy
    // [1904] phi from display_chip_rom::@2 to strcpy [phi:display_chip_rom::@2->strcpy]
    jsr strcpy
    // display_chip_rom::@5
    // strcat(rom, rom_size_strings[r])
    // [749] display_chip_rom::$11 = display_chip_rom::r#2 << 1 -- vbum1=vbuz2_rol_1 
    lda.z r
    asl
    sta display_chip_rom__11
    // [750] strcat::source#0 = rom_size_strings[display_chip_rom::$11] -- pbuz1=qbuc1_derefidx_vbum2 
    tay
    lda rom_size_strings,y
    sta.z strcat.source
    lda rom_size_strings+1,y
    sta.z strcat.source+1
    // [751] call strcat
    // [1912] phi from display_chip_rom::@5 to strcat [phi:display_chip_rom::@5->strcat]
    jsr strcat
    // display_chip_rom::@6
    // if(r)
    // [752] if(0==display_chip_rom::r#2) goto display_chip_rom::@3 -- 0_eq_vbuz1_then_la1 
    lda.z r
    beq __b3
    // display_chip_rom::@4
    // r+'0'
    // [753] display_chip_rom::$4 = display_chip_rom::r#2 + '0' -- vbuz1=vbuz2_plus_vbuc1 
    lda #'0'
    clc
    adc.z r
    sta.z display_chip_rom__4
    // *(rom+3) = r+'0'
    // [754] *(display_chip_rom::rom+3) = display_chip_rom::$4 -- _deref_pbuc1=vbuz1 
    sta rom+3
    // display_chip_rom::@3
  __b3:
    // display_rom_led(r, GREY)
    // [755] display_rom_led::chip#0 = display_chip_rom::r#2 -- vbuz1=vbuz2 
    lda.z r
    sta.z display_rom_led.chip
    // [756] call display_rom_led
    // [1924] phi from display_chip_rom::@3 to display_rom_led [phi:display_chip_rom::@3->display_rom_led]
    // [1924] phi display_rom_led::c#2 = GREY [phi:display_chip_rom::@3->display_rom_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z display_rom_led.c
    // [1924] phi display_rom_led::chip#2 = display_rom_led::chip#0 [phi:display_chip_rom::@3->display_rom_led#1] -- register_copy 
    jsr display_rom_led
    // display_chip_rom::@7
    // r*6
    // [757] display_chip_rom::$12 = display_chip_rom::$11 + display_chip_rom::r#2 -- vbum1=vbum1_plus_vbuz2 
    lda display_chip_rom__12
    clc
    adc.z r
    sta display_chip_rom__12
    // [758] display_chip_rom::$6 = display_chip_rom::$12 << 1 -- vbuz1=vbum2_rol_1 
    asl
    sta.z display_chip_rom__6
    // display_print_chip(CHIP_ROM_X+r*6, CHIP_ROM_Y+2, CHIP_ROM_W, rom)
    // [759] display_print_chip::x#2 = $14 + display_chip_rom::$6 -- vbuz1=vbuc1_plus_vbuz1 
    lda #$14
    clc
    adc.z display_print_chip.x
    sta.z display_print_chip.x
    // [760] call display_print_chip
    // [1854] phi from display_chip_rom::@7 to display_print_chip [phi:display_chip_rom::@7->display_print_chip]
    // [1854] phi display_print_chip::text#11 = display_chip_rom::rom [phi:display_chip_rom::@7->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z display_print_chip.text_2
    lda #>rom
    sta.z display_print_chip.text_2+1
    // [1854] phi display_print_chip::w#10 = 3 [phi:display_chip_rom::@7->display_print_chip#1] -- vbuz1=vbuc1 
    lda #3
    sta.z display_print_chip.w
    // [1854] phi display_print_chip::x#10 = display_print_chip::x#2 [phi:display_chip_rom::@7->display_print_chip#2] -- register_copy 
    jsr display_print_chip
    // display_chip_rom::@8
    // for (unsigned char r = 0; r < 8; r++)
    // [761] display_chip_rom::r#1 = ++ display_chip_rom::r#2 -- vbuz1=_inc_vbuz1 
    inc.z r
    // [744] phi from display_chip_rom::@8 to display_chip_rom::@1 [phi:display_chip_rom::@8->display_chip_rom::@1]
    // [744] phi display_chip_rom::r#2 = display_chip_rom::r#1 [phi:display_chip_rom::@8->display_chip_rom::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    rom: .fill $10, 0
    source: .text "ROM  "
    .byte 0
    .label display_chip_rom__11 = smc_detect.smc_detect__1
    .label display_chip_rom__12 = smc_detect.smc_detect__1
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
// void display_info_smc(__zp($e4) char info_status, __zp($3d) char *info_text)
display_info_smc: {
    .label display_info_smc__8 = $e4
    .label info_status = $e4
    .label info_text = $3d
    // unsigned char x = wherex()
    // [763] call wherex
    jsr wherex
    // [764] wherex::return#10 = wherex::return#0 -- vbum1=vbuz2 
    lda.z wherex.return
    sta wherex.return_2
    // display_info_smc::@3
    // [765] display_info_smc::x#0 = wherex::return#10
    // unsigned char y = wherey()
    // [766] call wherey
    jsr wherey
    // [767] wherey::return#10 = wherey::return#0 -- vbum1=vbuz2 
    lda.z wherey.return
    sta wherey.return_2
    // display_info_smc::@4
    // [768] display_info_smc::y#0 = wherey::return#10
    // status_smc = info_status
    // [769] status_smc#0 = display_info_smc::info_status#13 -- vbum1=vbuz2 
    lda.z info_status
    sta status_smc
    // display_smc_led(status_color[info_status])
    // [770] display_smc_led::c#1 = status_color[display_info_smc::info_status#13] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z display_smc_led.c
    // [771] call display_smc_led
    // [1848] phi from display_info_smc::@4 to display_smc_led [phi:display_info_smc::@4->display_smc_led]
    // [1848] phi display_smc_led::c#2 = display_smc_led::c#1 [phi:display_info_smc::@4->display_smc_led#0] -- register_copy 
    jsr display_smc_led
    // [772] phi from display_info_smc::@4 to display_info_smc::@5 [phi:display_info_smc::@4->display_info_smc::@5]
    // display_info_smc::@5
    // gotoxy(INFO_X, INFO_Y)
    // [773] call gotoxy
    // [610] phi from display_info_smc::@5 to gotoxy [phi:display_info_smc::@5->gotoxy]
    // [610] phi gotoxy::y#30 = $11 [phi:display_info_smc::@5->gotoxy#0] -- vbuz1=vbuc1 
    lda #$11
    sta.z gotoxy.y
    // [610] phi gotoxy::x#30 = 4 [phi:display_info_smc::@5->gotoxy#1] -- vbuz1=vbuc1 
    lda #4
    sta.z gotoxy.x
    jsr gotoxy
    // [774] phi from display_info_smc::@5 to display_info_smc::@6 [phi:display_info_smc::@5->display_info_smc::@6]
    // display_info_smc::@6
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [775] call printf_str
    // [877] phi from display_info_smc::@6 to printf_str [phi:display_info_smc::@6->printf_str]
    // [877] phi printf_str::putc#73 = &cputc [phi:display_info_smc::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = display_info_smc::s [phi:display_info_smc::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@7
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [776] display_info_smc::$8 = display_info_smc::info_status#13 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_info_smc__8
    // [777] printf_string::str#3 = status_text[display_info_smc::$8] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z display_info_smc__8
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [778] call printf_string
    // [886] phi from display_info_smc::@7 to printf_string [phi:display_info_smc::@7->printf_string]
    // [886] phi printf_string::putc#19 = &cputc [phi:display_info_smc::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [886] phi printf_string::str#19 = printf_string::str#3 [phi:display_info_smc::@7->printf_string#1] -- register_copy 
    // [886] phi printf_string::format_justify_left#19 = 1 [phi:display_info_smc::@7->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [886] phi printf_string::format_min_length#19 = 9 [phi:display_info_smc::@7->printf_string#3] -- vbuz1=vbuc1 
    lda #9
    sta.z printf_string.format_min_length
    jsr printf_string
    // [779] phi from display_info_smc::@7 to display_info_smc::@8 [phi:display_info_smc::@7->display_info_smc::@8]
    // display_info_smc::@8
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [780] call printf_str
    // [877] phi from display_info_smc::@8 to printf_str [phi:display_info_smc::@8->printf_str]
    // [877] phi printf_str::putc#73 = &cputc [phi:display_info_smc::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = display_info_smc::s1 [phi:display_info_smc::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@9
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [781] printf_uint::uvalue#0 = smc_file_size#12 -- vwuz1=vwum2 
    lda smc_file_size_2
    sta.z printf_uint.uvalue
    lda smc_file_size_2+1
    sta.z printf_uint.uvalue+1
    // [782] call printf_uint
    // [911] phi from display_info_smc::@9 to printf_uint [phi:display_info_smc::@9->printf_uint]
    // [911] phi printf_uint::format_zero_padding#19 = 1 [phi:display_info_smc::@9->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [911] phi printf_uint::format_min_length#19 = 5 [phi:display_info_smc::@9->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [911] phi printf_uint::putc#19 = &cputc [phi:display_info_smc::@9->printf_uint#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uint.putc
    lda #>cputc
    sta.z printf_uint.putc+1
    // [911] phi printf_uint::format_radix#19 = HEXADECIMAL [phi:display_info_smc::@9->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [911] phi printf_uint::uvalue#19 = printf_uint::uvalue#0 [phi:display_info_smc::@9->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [783] phi from display_info_smc::@9 to display_info_smc::@10 [phi:display_info_smc::@9->display_info_smc::@10]
    // display_info_smc::@10
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [784] call printf_str
    // [877] phi from display_info_smc::@10 to printf_str [phi:display_info_smc::@10->printf_str]
    // [877] phi printf_str::putc#73 = &cputc [phi:display_info_smc::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = display_info_smc::s2 [phi:display_info_smc::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@11
    // if(info_text)
    // [785] if((char *)0==display_info_smc::info_text#13) goto display_info_smc::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // display_info_smc::@2
    // printf("%-25s", info_text)
    // [786] printf_string::str#4 = display_info_smc::info_text#13 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [787] call printf_string
    // [886] phi from display_info_smc::@2 to printf_string [phi:display_info_smc::@2->printf_string]
    // [886] phi printf_string::putc#19 = &cputc [phi:display_info_smc::@2->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [886] phi printf_string::str#19 = printf_string::str#4 [phi:display_info_smc::@2->printf_string#1] -- register_copy 
    // [886] phi printf_string::format_justify_left#19 = 1 [phi:display_info_smc::@2->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [886] phi printf_string::format_min_length#19 = $19 [phi:display_info_smc::@2->printf_string#3] -- vbuz1=vbuc1 
    lda #$19
    sta.z printf_string.format_min_length
    jsr printf_string
    // display_info_smc::@1
  __b1:
    // gotoxy(x, y)
    // [788] gotoxy::x#14 = display_info_smc::x#0 -- vbuz1=vbum2 
    lda x
    sta.z gotoxy.x
    // [789] gotoxy::y#14 = display_info_smc::y#0 -- vbuz1=vbum2 
    lda y
    sta.z gotoxy.y
    // [790] call gotoxy
    // [610] phi from display_info_smc::@1 to gotoxy [phi:display_info_smc::@1->gotoxy]
    // [610] phi gotoxy::y#30 = gotoxy::y#14 [phi:display_info_smc::@1->gotoxy#0] -- register_copy 
    // [610] phi gotoxy::x#30 = gotoxy::x#14 [phi:display_info_smc::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_smc::@return
    // }
    // [791] return 
    rts
  .segment Data
    s: .text "SMC  "
    .byte 0
    s1: .text " ATTiny "
    .byte 0
    s2: .text " / 01E00 "
    .byte 0
    .label x = rom_read_byte.return
    .label y = rom_detect.rom_detect__9
}
.segment Code
  // display_info_vera
/**
 * @brief Display the VERA status at the info frame.
 * 
 * @param info_status The STATUS_ 
 */
// void display_info_vera(__zp($e7) char info_status, __zp($71) char *info_text)
display_info_vera: {
    .label display_info_vera__8 = $e7
    .label info_status = $e7
    .label info_text = $71
    // unsigned char x = wherex()
    // [793] call wherex
    jsr wherex
    // [794] wherex::return#11 = wherex::return#0 -- vbum1=vbuz2 
    lda.z wherex.return
    sta wherex.return_3
    // display_info_vera::@3
    // [795] display_info_vera::x#0 = wherex::return#11
    // unsigned char y = wherey()
    // [796] call wherey
    jsr wherey
    // [797] wherey::return#11 = wherey::return#0 -- vbum1=vbuz2 
    lda.z wherey.return
    sta wherey.return_3
    // display_info_vera::@4
    // [798] display_info_vera::y#0 = wherey::return#11
    // status_vera = info_status
    // [799] status_vera#0 = display_info_vera::info_status#3 -- vbum1=vbuz2 
    lda.z info_status
    sta status_vera
    // display_vera_led(status_color[info_status])
    // [800] display_vera_led::c#1 = status_color[display_info_vera::info_status#3] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z display_vera_led.c
    // [801] call display_vera_led
    // [1898] phi from display_info_vera::@4 to display_vera_led [phi:display_info_vera::@4->display_vera_led]
    // [1898] phi display_vera_led::c#2 = display_vera_led::c#1 [phi:display_info_vera::@4->display_vera_led#0] -- register_copy 
    jsr display_vera_led
    // [802] phi from display_info_vera::@4 to display_info_vera::@5 [phi:display_info_vera::@4->display_info_vera::@5]
    // display_info_vera::@5
    // gotoxy(INFO_X, INFO_Y+1)
    // [803] call gotoxy
    // [610] phi from display_info_vera::@5 to gotoxy [phi:display_info_vera::@5->gotoxy]
    // [610] phi gotoxy::y#30 = $11+1 [phi:display_info_vera::@5->gotoxy#0] -- vbuz1=vbuc1 
    lda #$11+1
    sta.z gotoxy.y
    // [610] phi gotoxy::x#30 = 4 [phi:display_info_vera::@5->gotoxy#1] -- vbuz1=vbuc1 
    lda #4
    sta.z gotoxy.x
    jsr gotoxy
    // [804] phi from display_info_vera::@5 to display_info_vera::@6 [phi:display_info_vera::@5->display_info_vera::@6]
    // display_info_vera::@6
    // printf("VERA %-9s FPGA   1a000 / 1a000 ", status_text[info_status])
    // [805] call printf_str
    // [877] phi from display_info_vera::@6 to printf_str [phi:display_info_vera::@6->printf_str]
    // [877] phi printf_str::putc#73 = &cputc [phi:display_info_vera::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = display_info_vera::s [phi:display_info_vera::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@7
    // printf("VERA %-9s FPGA   1a000 / 1a000 ", status_text[info_status])
    // [806] display_info_vera::$8 = display_info_vera::info_status#3 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_info_vera__8
    // [807] printf_string::str#5 = status_text[display_info_vera::$8] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z display_info_vera__8
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [808] call printf_string
    // [886] phi from display_info_vera::@7 to printf_string [phi:display_info_vera::@7->printf_string]
    // [886] phi printf_string::putc#19 = &cputc [phi:display_info_vera::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [886] phi printf_string::str#19 = printf_string::str#5 [phi:display_info_vera::@7->printf_string#1] -- register_copy 
    // [886] phi printf_string::format_justify_left#19 = 1 [phi:display_info_vera::@7->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [886] phi printf_string::format_min_length#19 = 9 [phi:display_info_vera::@7->printf_string#3] -- vbuz1=vbuc1 
    lda #9
    sta.z printf_string.format_min_length
    jsr printf_string
    // [809] phi from display_info_vera::@7 to display_info_vera::@8 [phi:display_info_vera::@7->display_info_vera::@8]
    // display_info_vera::@8
    // printf("VERA %-9s FPGA   1a000 / 1a000 ", status_text[info_status])
    // [810] call printf_str
    // [877] phi from display_info_vera::@8 to printf_str [phi:display_info_vera::@8->printf_str]
    // [877] phi printf_str::putc#73 = &cputc [phi:display_info_vera::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = display_info_vera::s1 [phi:display_info_vera::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@9
    // if(info_text)
    // [811] if((char *)0==display_info_vera::info_text#10) goto display_info_vera::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // display_info_vera::@2
    // printf("%-25s", info_text)
    // [812] printf_string::str#6 = display_info_vera::info_text#10 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [813] call printf_string
    // [886] phi from display_info_vera::@2 to printf_string [phi:display_info_vera::@2->printf_string]
    // [886] phi printf_string::putc#19 = &cputc [phi:display_info_vera::@2->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [886] phi printf_string::str#19 = printf_string::str#6 [phi:display_info_vera::@2->printf_string#1] -- register_copy 
    // [886] phi printf_string::format_justify_left#19 = 1 [phi:display_info_vera::@2->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [886] phi printf_string::format_min_length#19 = $19 [phi:display_info_vera::@2->printf_string#3] -- vbuz1=vbuc1 
    lda #$19
    sta.z printf_string.format_min_length
    jsr printf_string
    // display_info_vera::@1
  __b1:
    // gotoxy(x, y)
    // [814] gotoxy::x#16 = display_info_vera::x#0 -- vbuz1=vbum2 
    lda x
    sta.z gotoxy.x
    // [815] gotoxy::y#16 = display_info_vera::y#0 -- vbuz1=vbum2 
    lda y
    sta.z gotoxy.y
    // [816] call gotoxy
    // [610] phi from display_info_vera::@1 to gotoxy [phi:display_info_vera::@1->gotoxy]
    // [610] phi gotoxy::y#30 = gotoxy::y#16 [phi:display_info_vera::@1->gotoxy#0] -- register_copy 
    // [610] phi gotoxy::x#30 = gotoxy::x#16 [phi:display_info_vera::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_vera::@return
    // }
    // [817] return 
    rts
  .segment Data
    s: .text "VERA "
    .byte 0
    s1: .text " FPGA   1a000 / 1a000 "
    .byte 0
    .label x = rom_detect.rom_detect__24
    .label y = rom_detect.rom_detect__21
}
.segment Code
  // display_progress_text
/**
 * @brief Print a block of text within the progress frame with a count of lines.
 * 
 * @param text A pointer to an array of strings to be displayed (char**).
 * @param lines The amount of lines to be displayed, starting from the top of the progress frame.
 */
// void display_progress_text(__zp($4d) char **text, __zp($ec) char lines)
display_progress_text: {
    .label display_progress_text__3 = $2c
    .label l = $e6
    .label lines = $ec
    .label text = $4d
    // display_progress_clear()
    // [819] call display_progress_clear
    // [718] phi from display_progress_text to display_progress_clear [phi:display_progress_text->display_progress_clear]
    jsr display_progress_clear
    // [820] phi from display_progress_text to display_progress_text::@1 [phi:display_progress_text->display_progress_text::@1]
    // [820] phi display_progress_text::l#2 = 0 [phi:display_progress_text->display_progress_text::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z l
    // display_progress_text::@1
  __b1:
    // for(unsigned char l=0; l<lines; l++)
    // [821] if(display_progress_text::l#2<display_progress_text::lines#7) goto display_progress_text::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z l
    cmp.z lines
    bcc __b2
    // display_progress_text::@return
    // }
    // [822] return 
    rts
    // display_progress_text::@2
  __b2:
    // display_progress_line(l, text[l])
    // [823] display_progress_text::$3 = display_progress_text::l#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z l
    asl
    sta.z display_progress_text__3
    // [824] display_progress_line::line#0 = display_progress_text::l#2 -- vbum1=vbuz2 
    lda.z l
    sta display_progress_line.line
    // [825] display_progress_line::text#0 = display_progress_text::text#10[display_progress_text::$3] -- pbuz1=qbuz2_derefidx_vbuz3 
    ldy.z display_progress_text__3
    lda (text),y
    sta.z display_progress_line.text
    iny
    lda (text),y
    sta.z display_progress_line.text+1
    // [826] call display_progress_line
    jsr display_progress_line
    // display_progress_text::@3
    // for(unsigned char l=0; l<lines; l++)
    // [827] display_progress_text::l#1 = ++ display_progress_text::l#2 -- vbuz1=_inc_vbuz1 
    inc.z l
    // [820] phi from display_progress_text::@3 to display_progress_text::@1 [phi:display_progress_text::@3->display_progress_text::@1]
    // [820] phi display_progress_text::l#2 = display_progress_text::l#1 [phi:display_progress_text::@3->display_progress_text::@1#0] -- register_copy 
    jmp __b1
}
  // util_wait_space
util_wait_space: {
    // util_wait_key("Press [SPACE] to continue ...", " ")
    // [829] call util_wait_key
    // [1564] phi from util_wait_space to util_wait_key [phi:util_wait_space->util_wait_key]
    // [1564] phi util_wait_key::filter#12 = s1 [phi:util_wait_space->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<s1
    sta.z util_wait_key.filter
    lda #>s1
    sta.z util_wait_key.filter+1
    // [1564] phi util_wait_key::info_text#2 = util_wait_space::info_text [phi:util_wait_space->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z util_wait_key.info_text
    lda #>info_text
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // util_wait_space::@return
    // }
    // [830] return 
    rts
  .segment Data
    info_text: .text "Press [SPACE] to continue ..."
    .byte 0
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
    // When the bootloader is not present, 0xFF is returned.
    .label smc_bootloader_version = $b1
    .label return = $b1
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [831] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [832] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [833] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [834] cx16_k_i2c_read_byte::return#10 = cx16_k_i2c_read_byte::return#1
    // smc_detect::@3
    // smc_bootloader_version = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [835] smc_detect::smc_bootloader_version#1 = cx16_k_i2c_read_byte::return#10
    // BYTE1(smc_bootloader_version)
    // [836] smc_detect::$1 = byte1  smc_detect::smc_bootloader_version#1 -- vbum1=_byte1_vwuz2 
    lda.z smc_bootloader_version+1
    sta smc_detect__1
    // if(!BYTE1(smc_bootloader_version))
    // [837] if(0==smc_detect::$1) goto smc_detect::@1 -- 0_eq_vbum1_then_la1 
    beq __b1
    // [840] phi from smc_detect::@3 to smc_detect::@2 [phi:smc_detect::@3->smc_detect::@2]
    // [840] phi smc_detect::return#0 = $200 [phi:smc_detect::@3->smc_detect::@2#0] -- vwuz1=vwuc1 
    lda #<$200
    sta.z return
    lda #>$200
    sta.z return+1
    rts
    // smc_detect::@1
  __b1:
    // if(smc_bootloader_version == 0xFF)
    // [838] if(smc_detect::smc_bootloader_version#1!=$ff) goto smc_detect::@4 -- vwuz1_neq_vbuc1_then_la1 
    lda.z smc_bootloader_version+1
    bne __b2
    lda.z smc_bootloader_version
    cmp #$ff
    bne __b2
    // [840] phi from smc_detect::@1 to smc_detect::@2 [phi:smc_detect::@1->smc_detect::@2]
    // [840] phi smc_detect::return#0 = $100 [phi:smc_detect::@1->smc_detect::@2#0] -- vwuz1=vwuc1 
    lda #<$100
    sta.z return
    lda #>$100
    sta.z return+1
    rts
    // [839] phi from smc_detect::@1 to smc_detect::@4 [phi:smc_detect::@1->smc_detect::@4]
    // smc_detect::@4
    // [840] phi from smc_detect::@4 to smc_detect::@2 [phi:smc_detect::@4->smc_detect::@2]
    // [840] phi smc_detect::return#0 = smc_detect::smc_bootloader_version#1 [phi:smc_detect::@4->smc_detect::@2#0] -- register_copy 
    // smc_detect::@2
  __b2:
    // smc_detect::@return
    // }
    // [841] return 
    rts
  .segment Data
    smc_detect__1: .byte 0
}
.segment Code
  // smc_version
/**
 * @brief Detect and write the SMC version number into the info_text.
 * 
 * @param version_string The string containing the SMC version filled upon return.
 */
// unsigned long smc_version(char *version_string)
smc_version: {
    .label version = $62
    .label minor = $b1
    // unsigned int version = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_VERSION)
    // [842] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [843] cx16_k_i2c_read_byte::offset = $30 -- vbum1=vbuc1 
    lda #$30
    sta cx16_k_i2c_read_byte.offset
    // [844] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [845] cx16_k_i2c_read_byte::return#11 = cx16_k_i2c_read_byte::return#1 -- vwuz1=vwuz2 
    lda.z cx16_k_i2c_read_byte.return
    sta.z cx16_k_i2c_read_byte.return_1
    lda.z cx16_k_i2c_read_byte.return+1
    sta.z cx16_k_i2c_read_byte.return_1+1
    // smc_version::@1
    // [846] smc_version::version#0 = cx16_k_i2c_read_byte::return#11
    // unsigned int major = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_MAJOR)
    // [847] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [848] cx16_k_i2c_read_byte::offset = $31 -- vbum1=vbuc1 
    lda #$31
    sta cx16_k_i2c_read_byte.offset
    // [849] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [850] cx16_k_i2c_read_byte::return#12 = cx16_k_i2c_read_byte::return#1 -- vwum1=vwuz2 
    lda.z cx16_k_i2c_read_byte.return
    sta cx16_k_i2c_read_byte.return_2
    lda.z cx16_k_i2c_read_byte.return+1
    sta cx16_k_i2c_read_byte.return_2+1
    // smc_version::@2
    // [851] smc_version::major#0 = cx16_k_i2c_read_byte::return#12
    // unsigned int minor = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_MINOR)
    // [852] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [853] cx16_k_i2c_read_byte::offset = $32 -- vbum1=vbuc1 
    lda #$32
    sta cx16_k_i2c_read_byte.offset
    // [854] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [855] cx16_k_i2c_read_byte::return#13 = cx16_k_i2c_read_byte::return#1
    // smc_version::@3
    // [856] smc_version::minor#0 = cx16_k_i2c_read_byte::return#13
    // sprintf(version_string, "%u.%u.%u", version, major, minor)
    // [857] call snprintf_init
    // [872] phi from smc_version::@3 to snprintf_init [phi:smc_version::@3->snprintf_init]
    // [872] phi snprintf_init::s#25 = smc_version_string [phi:smc_version::@3->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<smc_version_string
    sta.z snprintf_init.s
    lda #>smc_version_string
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // smc_version::@4
    // sprintf(version_string, "%u.%u.%u", version, major, minor)
    // [858] printf_uint::uvalue#1 = smc_version::version#0 -- vwuz1=vwuz2 
    lda.z version
    sta.z printf_uint.uvalue
    lda.z version+1
    sta.z printf_uint.uvalue+1
    // [859] call printf_uint
    // [911] phi from smc_version::@4 to printf_uint [phi:smc_version::@4->printf_uint]
    // [911] phi printf_uint::format_zero_padding#19 = 0 [phi:smc_version::@4->printf_uint#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uint.format_zero_padding
    // [911] phi printf_uint::format_min_length#19 = 0 [phi:smc_version::@4->printf_uint#1] -- vbuz1=vbuc1 
    sta.z printf_uint.format_min_length
    // [911] phi printf_uint::putc#19 = &snputc [phi:smc_version::@4->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [911] phi printf_uint::format_radix#19 = DECIMAL [phi:smc_version::@4->printf_uint#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [911] phi printf_uint::uvalue#19 = printf_uint::uvalue#1 [phi:smc_version::@4->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [860] phi from smc_version::@4 to smc_version::@5 [phi:smc_version::@4->smc_version::@5]
    // smc_version::@5
    // sprintf(version_string, "%u.%u.%u", version, major, minor)
    // [861] call printf_str
    // [877] phi from smc_version::@5 to printf_str [phi:smc_version::@5->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:smc_version::@5->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = smc_version::s [phi:smc_version::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_version::@6
    // sprintf(version_string, "%u.%u.%u", version, major, minor)
    // [862] printf_uint::uvalue#2 = smc_version::major#0 -- vwuz1=vwum2 
    lda major
    sta.z printf_uint.uvalue
    lda major+1
    sta.z printf_uint.uvalue+1
    // [863] call printf_uint
    // [911] phi from smc_version::@6 to printf_uint [phi:smc_version::@6->printf_uint]
    // [911] phi printf_uint::format_zero_padding#19 = 0 [phi:smc_version::@6->printf_uint#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uint.format_zero_padding
    // [911] phi printf_uint::format_min_length#19 = 0 [phi:smc_version::@6->printf_uint#1] -- vbuz1=vbuc1 
    sta.z printf_uint.format_min_length
    // [911] phi printf_uint::putc#19 = &snputc [phi:smc_version::@6->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [911] phi printf_uint::format_radix#19 = DECIMAL [phi:smc_version::@6->printf_uint#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [911] phi printf_uint::uvalue#19 = printf_uint::uvalue#2 [phi:smc_version::@6->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [864] phi from smc_version::@6 to smc_version::@7 [phi:smc_version::@6->smc_version::@7]
    // smc_version::@7
    // sprintf(version_string, "%u.%u.%u", version, major, minor)
    // [865] call printf_str
    // [877] phi from smc_version::@7 to printf_str [phi:smc_version::@7->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:smc_version::@7->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = smc_version::s [phi:smc_version::@7->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_version::@8
    // sprintf(version_string, "%u.%u.%u", version, major, minor)
    // [866] printf_uint::uvalue#3 = smc_version::minor#0 -- vwuz1=vwuz2 
    lda.z minor
    sta.z printf_uint.uvalue
    lda.z minor+1
    sta.z printf_uint.uvalue+1
    // [867] call printf_uint
    // [911] phi from smc_version::@8 to printf_uint [phi:smc_version::@8->printf_uint]
    // [911] phi printf_uint::format_zero_padding#19 = 0 [phi:smc_version::@8->printf_uint#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uint.format_zero_padding
    // [911] phi printf_uint::format_min_length#19 = 0 [phi:smc_version::@8->printf_uint#1] -- vbuz1=vbuc1 
    sta.z printf_uint.format_min_length
    // [911] phi printf_uint::putc#19 = &snputc [phi:smc_version::@8->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [911] phi printf_uint::format_radix#19 = DECIMAL [phi:smc_version::@8->printf_uint#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [911] phi printf_uint::uvalue#19 = printf_uint::uvalue#3 [phi:smc_version::@8->printf_uint#4] -- register_copy 
    jsr printf_uint
    // smc_version::@9
    // sprintf(version_string, "%u.%u.%u", version, major, minor)
    // [868] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [869] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_version::@return
    // }
    // [871] return 
    rts
  .segment Data
    s: .text "."
    .byte 0
    .label major = rom_flash.equal_bytes_1
}
.segment Code
  // snprintf_init
/// Initialize the snprintf() state
// void snprintf_init(__zp($60) char *s, unsigned int n)
snprintf_init: {
    .label s = $60
    // __snprintf_capacity = n
    // [873] __snprintf_capacity = $ffff -- vwum1=vwuc1 
    lda #<$ffff
    sta __snprintf_capacity
    lda #>$ffff
    sta __snprintf_capacity+1
    // __snprintf_size = 0
    // [874] __snprintf_size = 0 -- vwum1=vbuc1 
    lda #<0
    sta __snprintf_size
    sta __snprintf_size+1
    // __snprintf_buffer = s
    // [875] __snprintf_buffer = snprintf_init::s#25 -- pbum1=pbuz2 
    lda.z s
    sta __snprintf_buffer
    lda.z s+1
    sta __snprintf_buffer+1
    // snprintf_init::@return
    // }
    // [876] return 
    rts
}
  // printf_str
/// Print a NUL-terminated string
// void printf_str(__zp($4d) void (*putc)(char), __zp($60) const char *s)
printf_str: {
    .label c = $64
    .label s = $60
    .label putc = $4d
    // [878] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [878] phi printf_str::s#72 = printf_str::s#73 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [879] printf_str::c#1 = *printf_str::s#72 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta.z c
    // [880] printf_str::s#0 = ++ printf_str::s#72 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [881] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // printf_str::@return
    // }
    // [882] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [883] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [884] callexecute *printf_str::putc#73  -- call__deref_pprz1 
    jsr icall14
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
    // Outside Flow
  icall14:
    jmp (putc)
}
  // printf_string
// Print a string value using a specific format
// Handles justification and min length 
// void printf_string(__zp($73) void (*putc)(char), __zp($60) char *str, __zp($e2) char format_min_length, __zp($ec) char format_justify_left)
printf_string: {
    .label printf_string__9 = $55
    .label len = $64
    .label padding = $e2
    .label str = $60
    .label format_min_length = $e2
    .label format_justify_left = $ec
    .label putc = $73
    // if(format.min_length)
    // [887] if(0==printf_string::format_min_length#19) goto printf_string::@1 -- 0_eq_vbuz1_then_la1 
    lda.z format_min_length
    beq __b3
    // printf_string::@3
    // strlen(str)
    // [888] strlen::str#3 = printf_string::str#19 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [889] call strlen
    // [1944] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [1944] phi strlen::str#8 = strlen::str#3 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [890] strlen::return#10 = strlen::len#2
    // printf_string::@6
    // [891] printf_string::$9 = strlen::return#10
    // signed char len = (signed char)strlen(str)
    // [892] printf_string::len#0 = (signed char)printf_string::$9 -- vbsz1=_sbyte_vwuz2 
    lda.z printf_string__9
    sta.z len
    // padding = (signed char)format.min_length  - len
    // [893] printf_string::padding#1 = (signed char)printf_string::format_min_length#19 - printf_string::len#0 -- vbsz1=vbsz1_minus_vbsz2 
    lda.z padding
    sec
    sbc.z len
    sta.z padding
    // if(padding<0)
    // [894] if(printf_string::padding#1>=0) goto printf_string::@10 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [896] phi from printf_string printf_string::@6 to printf_string::@1 [phi:printf_string/printf_string::@6->printf_string::@1]
  __b3:
    // [896] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@6->printf_string::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [895] phi from printf_string::@6 to printf_string::@10 [phi:printf_string::@6->printf_string::@10]
    // printf_string::@10
    // [896] phi from printf_string::@10 to printf_string::@1 [phi:printf_string::@10->printf_string::@1]
    // [896] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@10->printf_string::@1#0] -- register_copy 
    // printf_string::@1
  __b1:
    // if(!format.justify_left && padding)
    // [897] if(0!=printf_string::format_justify_left#19) goto printf_string::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_justify_left
    bne __b2
    // printf_string::@8
    // [898] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b4
    jmp __b2
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [899] printf_padding::putc#3 = printf_string::putc#19 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [900] printf_padding::length#3 = (char)printf_string::padding#3 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [901] call printf_padding
    // [1950] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    // [1950] phi printf_padding::putc#7 = printf_padding::putc#3 [phi:printf_string::@4->printf_padding#0] -- register_copy 
    // [1950] phi printf_padding::pad#7 = ' ' [phi:printf_string::@4->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1950] phi printf_padding::length#6 = printf_padding::length#3 [phi:printf_string::@4->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [902] printf_str::putc#1 = printf_string::putc#19 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_str.putc
    lda.z putc+1
    sta.z printf_str.putc+1
    // [903] printf_str::s#2 = printf_string::str#19
    // [904] call printf_str
    // [877] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [877] phi printf_str::putc#73 = printf_str::putc#1 [phi:printf_string::@2->printf_str#0] -- register_copy 
    // [877] phi printf_str::s#73 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@7
    // if(format.justify_left && padding)
    // [905] if(0==printf_string::format_justify_left#19) goto printf_string::@return -- 0_eq_vbuz1_then_la1 
    lda.z format_justify_left
    beq __breturn
    // printf_string::@9
    // [906] if(0!=printf_string::padding#3) goto printf_string::@5 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b5
    rts
    // printf_string::@5
  __b5:
    // printf_padding(putc, ' ',(char)padding)
    // [907] printf_padding::putc#4 = printf_string::putc#19 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [908] printf_padding::length#4 = (char)printf_string::padding#3 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [909] call printf_padding
    // [1950] phi from printf_string::@5 to printf_padding [phi:printf_string::@5->printf_padding]
    // [1950] phi printf_padding::putc#7 = printf_padding::putc#4 [phi:printf_string::@5->printf_padding#0] -- register_copy 
    // [1950] phi printf_padding::pad#7 = ' ' [phi:printf_string::@5->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1950] phi printf_padding::length#6 = printf_padding::length#4 [phi:printf_string::@5->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@return
  __breturn:
    // }
    // [910] return 
    rts
}
  // printf_uint
// Print an unsigned int using a specific format
// void printf_uint(__zp($4d) void (*putc)(char), __zp($2e) unsigned int uvalue, __zp($e7) char format_min_length, char format_justify_left, char format_sign_always, __zp($e6) char format_zero_padding, char format_upper_case, __zp($e3) char format_radix)
printf_uint: {
    .label uvalue = $2e
    .label format_radix = $e3
    .label putc = $4d
    .label format_min_length = $e7
    .label format_zero_padding = $e6
    // printf_uint::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [912] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [913] utoa::value#1 = printf_uint::uvalue#19
    // [914] utoa::radix#0 = printf_uint::format_radix#19
    // [915] call utoa
    // Format number into buffer
    jsr utoa
    // printf_uint::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [916] printf_number_buffer::putc#1 = printf_uint::putc#19
    // [917] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [918] printf_number_buffer::format_min_length#1 = printf_uint::format_min_length#19
    // [919] printf_number_buffer::format_zero_padding#1 = printf_uint::format_zero_padding#19
    // [920] call printf_number_buffer
  // Print using format
    // [1988] phi from printf_uint::@2 to printf_number_buffer [phi:printf_uint::@2->printf_number_buffer]
    // [1988] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#1 [phi:printf_uint::@2->printf_number_buffer#0] -- register_copy 
    // [1988] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_uint::@2->printf_number_buffer#1] -- register_copy 
    // [1988] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#1 [phi:printf_uint::@2->printf_number_buffer#2] -- register_copy 
    // [1988] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#1 [phi:printf_uint::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uint::@return
    // }
    // [921] return 
    rts
}
  // rom_detect
rom_detect: {
    .const bank_set_brom1_bank = 4
    .label rom_detect__15 = $e8
    .label rom_detect__18 = $ea
    .label rom_detect_address = $30
    // [923] phi from rom_detect to rom_detect::@1 [phi:rom_detect->rom_detect::@1]
    // [923] phi rom_detect::rom_chip#10 = 0 [phi:rom_detect->rom_detect::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // [923] phi rom_detect::rom_detect_address#10 = 0 [phi:rom_detect->rom_detect::@1#1] -- vduz1=vduc1 
    sta.z rom_detect_address
    sta.z rom_detect_address+1
    lda #<0>>$10
    sta.z rom_detect_address+2
    lda #>0>>$10
    sta.z rom_detect_address+3
  // Ensure the ROM is set to BASIC.
  // bank_set_brom(4);
    // rom_detect::@1
  __b1:
    // for (unsigned long rom_detect_address = 0; rom_detect_address < 8 * 0x80000; rom_detect_address += 0x80000)
    // [924] if(rom_detect::rom_detect_address#10<8*$80000) goto rom_detect::@2 -- vduz1_lt_vduc1_then_la1 
    lda.z rom_detect_address+3
    cmp #>8*$80000>>$10
    bcc __b2
    bne !+
    lda.z rom_detect_address+2
    cmp #<8*$80000>>$10
    bcc __b2
    bne !+
    lda.z rom_detect_address+1
    cmp #>8*$80000
    bcc __b2
    bne !+
    lda.z rom_detect_address
    cmp #<8*$80000
    bcc __b2
  !:
    // rom_detect::@return
    // }
    // [925] return 
    rts
    // rom_detect::@2
  __b2:
    // rom_manufacturer_ids[rom_chip] = 0
    // [926] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = 0
    // [927] rom_device_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta rom_device_ids,y
    // rom_unlock(rom_detect_address + 0x05555, 0x90)
    // [928] rom_unlock::address#2 = rom_detect::rom_detect_address#10 + $5555 -- vduz1=vduz2_plus_vwuc1 
    clc
    lda.z rom_detect_address
    adc #<$5555
    sta.z rom_unlock.address
    lda.z rom_detect_address+1
    adc #>$5555
    sta.z rom_unlock.address+1
    lda.z rom_detect_address+2
    adc #0
    sta.z rom_unlock.address+2
    lda.z rom_detect_address+3
    adc #0
    sta.z rom_unlock.address+3
    // [929] call rom_unlock
    // [2019] phi from rom_detect::@2 to rom_unlock [phi:rom_detect::@2->rom_unlock]
    // [2019] phi rom_unlock::unlock_code#5 = $90 [phi:rom_detect::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$90
    sta.z rom_unlock.unlock_code
    // [2019] phi rom_unlock::address#5 = rom_unlock::address#2 [phi:rom_detect::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_detect::@12
    // rom_read_byte(rom_detect_address)
    // [930] rom_read_byte::address#0 = rom_detect::rom_detect_address#10 -- vduz1=vduz2 
    lda.z rom_detect_address
    sta.z rom_read_byte.address
    lda.z rom_detect_address+1
    sta.z rom_read_byte.address+1
    lda.z rom_detect_address+2
    sta.z rom_read_byte.address+2
    lda.z rom_detect_address+3
    sta.z rom_read_byte.address+3
    // [931] call rom_read_byte
    // [2029] phi from rom_detect::@12 to rom_read_byte [phi:rom_detect::@12->rom_read_byte]
    // [2029] phi rom_read_byte::address#2 = rom_read_byte::address#0 [phi:rom_detect::@12->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(rom_detect_address)
    // [932] rom_read_byte::return#2 = rom_read_byte::return#0
    // rom_detect::@13
    // [933] rom_detect::$3 = rom_read_byte::return#2
    // rom_manufacturer_ids[rom_chip] = rom_read_byte(rom_detect_address)
    // [934] rom_manufacturer_ids[rom_detect::rom_chip#10] = rom_detect::$3 -- pbuc1_derefidx_vbum1=vbum2 
    lda rom_detect__3
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_read_byte(rom_detect_address + 1)
    // [935] rom_read_byte::address#1 = rom_detect::rom_detect_address#10 + 1 -- vduz1=vduz2_plus_1 
    lda.z rom_detect_address
    clc
    adc #1
    sta.z rom_read_byte.address
    lda.z rom_detect_address+1
    adc #0
    sta.z rom_read_byte.address+1
    lda.z rom_detect_address+2
    adc #0
    sta.z rom_read_byte.address+2
    lda.z rom_detect_address+3
    adc #0
    sta.z rom_read_byte.address+3
    // [936] call rom_read_byte
    // [2029] phi from rom_detect::@13 to rom_read_byte [phi:rom_detect::@13->rom_read_byte]
    // [2029] phi rom_read_byte::address#2 = rom_read_byte::address#1 [phi:rom_detect::@13->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(rom_detect_address + 1)
    // [937] rom_read_byte::return#3 = rom_read_byte::return#0
    // rom_detect::@14
    // [938] rom_detect::$5 = rom_read_byte::return#3
    // rom_device_ids[rom_chip] = rom_read_byte(rom_detect_address + 1)
    // [939] rom_device_ids[rom_detect::rom_chip#10] = rom_detect::$5 -- pbuc1_derefidx_vbum1=vbum2 
    lda rom_detect__5
    ldy rom_chip
    sta rom_device_ids,y
    // rom_unlock(rom_detect_address + 0x05555, 0xF0)
    // [940] rom_unlock::address#3 = rom_detect::rom_detect_address#10 + $5555 -- vduz1=vduz2_plus_vwuc1 
    clc
    lda.z rom_detect_address
    adc #<$5555
    sta.z rom_unlock.address
    lda.z rom_detect_address+1
    adc #>$5555
    sta.z rom_unlock.address+1
    lda.z rom_detect_address+2
    adc #0
    sta.z rom_unlock.address+2
    lda.z rom_detect_address+3
    adc #0
    sta.z rom_unlock.address+3
    // [941] call rom_unlock
    // [2019] phi from rom_detect::@14 to rom_unlock [phi:rom_detect::@14->rom_unlock]
    // [2019] phi rom_unlock::unlock_code#5 = $f0 [phi:rom_detect::@14->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$f0
    sta.z rom_unlock.unlock_code
    // [2019] phi rom_unlock::address#5 = rom_unlock::address#3 [phi:rom_detect::@14->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_detect::bank_set_brom1
    // BROM = bank
    // [942] BROM = rom_detect::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // rom_detect::@11
    // rom_chip*3
    // [943] rom_detect::$14 = rom_detect::rom_chip#10 << 1 -- vbum1=vbum2_rol_1 
    lda rom_chip
    asl
    sta rom_detect__14
    // [944] rom_detect::$9 = rom_detect::$14 + rom_detect::rom_chip#10 -- vbum1=vbum2_plus_vbum3 
    clc
    adc rom_chip
    sta rom_detect__9
    // gotoxy(rom_chip*3+40, 1)
    // [945] gotoxy::x#23 = rom_detect::$9 + $28 -- vbuz1=vbum2_plus_vbuc1 
    lda #$28
    clc
    adc rom_detect__9
    sta.z gotoxy.x
    // [946] call gotoxy
    // [610] phi from rom_detect::@11 to gotoxy [phi:rom_detect::@11->gotoxy]
    // [610] phi gotoxy::y#30 = 1 [phi:rom_detect::@11->gotoxy#0] -- vbuz1=vbuc1 
    lda #1
    sta.z gotoxy.y
    // [610] phi gotoxy::x#30 = gotoxy::x#23 [phi:rom_detect::@11->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_detect::@15
    // printf("%02x", rom_device_ids[rom_chip])
    // [947] printf_uchar::uvalue#4 = rom_device_ids[rom_detect::rom_chip#10] -- vbuz1=pbuc1_derefidx_vbum2 
    ldy rom_chip
    lda rom_device_ids,y
    sta.z printf_uchar.uvalue
    // [948] call printf_uchar
    // [1040] phi from rom_detect::@15 to printf_uchar [phi:rom_detect::@15->printf_uchar]
    // [1040] phi printf_uchar::format_zero_padding#10 = 1 [phi:rom_detect::@15->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1040] phi printf_uchar::format_min_length#10 = 2 [phi:rom_detect::@15->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [1040] phi printf_uchar::putc#10 = &cputc [phi:rom_detect::@15->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1040] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:rom_detect::@15->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [1040] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#4 [phi:rom_detect::@15->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // rom_detect::@16
    // case SST39SF010A:
    //             rom_device_names[rom_chip] = "f010a";
    //             rom_size_strings[rom_chip] = "128";
    //             rom_sizes[rom_chip] = 128 * 1024;
    //             break;
    // [949] if(rom_device_ids[rom_detect::rom_chip#10]==$b5) goto rom_detect::@3 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
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
    // [950] if(rom_device_ids[rom_detect::rom_chip#10]==$b6) goto rom_detect::@4 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
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
    // [951] if(rom_device_ids[rom_detect::rom_chip#10]==$b7) goto rom_detect::@5 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b7
    beq __b5
    // rom_detect::@6
    // rom_manufacturer_ids[rom_chip] = 0
    // [952] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    sta rom_manufacturer_ids,y
    // rom_device_names[rom_chip] = "----"
    // [953] rom_device_names[rom_detect::$14] = rom_detect::$31 -- qbuc1_derefidx_vbum1=pbuc2 
    ldy rom_detect__14
    lda #<rom_detect__31
    sta rom_device_names,y
    lda #>rom_detect__31
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "000"
    // [954] rom_size_strings[rom_detect::$14] = rom_detect::$32 -- qbuc1_derefidx_vbum1=pbuc2 
    lda #<rom_detect__32
    sta rom_size_strings,y
    lda #>rom_detect__32
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 0
    // [955] rom_detect::$24 = rom_detect::rom_chip#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta rom_detect__24
    // [956] rom_sizes[rom_detect::$24] = 0 -- pduc1_derefidx_vbum1=vbuc2 
    tay
    lda #0
    sta rom_sizes,y
    sta rom_sizes+1,y
    sta rom_sizes+2,y
    sta rom_sizes+3,y
    // rom_device_ids[rom_chip] = UNKNOWN
    // [957] rom_device_ids[rom_detect::rom_chip#10] = $55 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$55
    ldy rom_chip
    sta rom_device_ids,y
    // rom_detect::@7
  __b7:
    // rom_chip++;
    // [958] rom_detect::rom_chip#1 = ++ rom_detect::rom_chip#10 -- vbum1=_inc_vbum1 
    inc rom_chip
    // rom_detect::@8
    // rom_detect_address += 0x80000
    // [959] rom_detect::rom_detect_address#1 = rom_detect::rom_detect_address#10 + $80000 -- vduz1=vduz1_plus_vduc1 
    clc
    lda.z rom_detect_address
    adc #<$80000
    sta.z rom_detect_address
    lda.z rom_detect_address+1
    adc #>$80000
    sta.z rom_detect_address+1
    lda.z rom_detect_address+2
    adc #<$80000>>$10
    sta.z rom_detect_address+2
    lda.z rom_detect_address+3
    adc #>$80000>>$10
    sta.z rom_detect_address+3
    // [923] phi from rom_detect::@8 to rom_detect::@1 [phi:rom_detect::@8->rom_detect::@1]
    // [923] phi rom_detect::rom_chip#10 = rom_detect::rom_chip#1 [phi:rom_detect::@8->rom_detect::@1#0] -- register_copy 
    // [923] phi rom_detect::rom_detect_address#10 = rom_detect::rom_detect_address#1 [phi:rom_detect::@8->rom_detect::@1#1] -- register_copy 
    jmp __b1
    // rom_detect::@5
  __b5:
    // rom_device_names[rom_chip] = "f040"
    // [960] rom_device_names[rom_detect::$14] = rom_detect::$29 -- qbuc1_derefidx_vbum1=pbuc2 
    ldy rom_detect__14
    lda #<rom_detect__29
    sta rom_device_names,y
    lda #>rom_detect__29
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "512"
    // [961] rom_size_strings[rom_detect::$14] = rom_detect::$30 -- qbuc1_derefidx_vbum1=pbuc2 
    lda #<rom_detect__30
    sta rom_size_strings,y
    lda #>rom_detect__30
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 512 * 1024
    // [962] rom_detect::$21 = rom_detect::rom_chip#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta rom_detect__21
    // [963] rom_sizes[rom_detect::$21] = (unsigned long)$200*$400 -- pduc1_derefidx_vbum1=vduc2 
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
    // [964] rom_device_names[rom_detect::$14] = rom_detect::$27 -- qbuc1_derefidx_vbum1=pbuc2 
    ldy rom_detect__14
    lda #<rom_detect__27
    sta rom_device_names,y
    lda #>rom_detect__27
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "256"
    // [965] rom_size_strings[rom_detect::$14] = rom_detect::$28 -- qbuc1_derefidx_vbum1=pbuc2 
    lda #<rom_detect__28
    sta rom_size_strings,y
    lda #>rom_detect__28
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 256 * 1024
    // [966] rom_detect::$18 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__18
    // [967] rom_sizes[rom_detect::$18] = (unsigned long)$100*$400 -- pduc1_derefidx_vbuz1=vduc2 
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
    // [968] rom_device_names[rom_detect::$14] = rom_detect::$25 -- qbuc1_derefidx_vbum1=pbuc2 
    ldy rom_detect__14
    lda #<rom_detect__25
    sta rom_device_names,y
    lda #>rom_detect__25
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "128"
    // [969] rom_size_strings[rom_detect::$14] = rom_detect::$26 -- qbuc1_derefidx_vbum1=pbuc2 
    lda #<rom_detect__26
    sta rom_size_strings,y
    lda #>rom_detect__26
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 128 * 1024
    // [970] rom_detect::$15 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__15
    // [971] rom_sizes[rom_detect::$15] = (unsigned long)$80*$400 -- pduc1_derefidx_vbuz1=vduc2 
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
    .label rom_detect__3 = rom_read_byte.return
    .label rom_detect__5 = rom_read_byte.return
    rom_detect__9: .byte 0
    .label rom_detect__14 = display_info_rom.display_info_rom__11
    rom_detect__21: .byte 0
    rom_detect__24: .byte 0
    .label rom_chip = main.check_status_cx16_rom4_check_status_rom1_main__0
}
.segment Code
  // smc_read
/**
 * @brief Read the SMC.BIN file into RAM_BASE.
 * The maximum size of SMC.BIN data that should be in the file is 0x1E00.
 * 
 * @return unsigned int The amount of bytes read from SMC.BIN to be flashed.
 */
// __mem() unsigned int smc_read(__zp($e5) char display_progress)
smc_read: {
    .label fp = $b3
    .label smc_file_read = $bc
    .label display_progress = $e5
    // display_action_progress("Reading SMC.BIN ... (.) data, ( ) empty")
    // [973] call display_action_progress
  // It is assume that one RAM bank is 0X2000 bytes.
    // [704] phi from smc_read to display_action_progress [phi:smc_read->display_action_progress]
    // [704] phi display_action_progress::info_text#15 = smc_read::info_text [phi:smc_read->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [974] phi from smc_read to smc_read::@9 [phi:smc_read->smc_read::@9]
    // smc_read::@9
    // textcolor(WHITE)
    // [975] call textcolor
    // [592] phi from smc_read::@9 to textcolor [phi:smc_read::@9->textcolor]
    // [592] phi textcolor::color#18 = WHITE [phi:smc_read::@9->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [976] phi from smc_read::@9 to smc_read::@10 [phi:smc_read::@9->smc_read::@10]
    // smc_read::@10
    // gotoxy(x, y)
    // [977] call gotoxy
    // [610] phi from smc_read::@10 to gotoxy [phi:smc_read::@10->gotoxy]
    // [610] phi gotoxy::y#30 = PROGRESS_Y [phi:smc_read::@10->gotoxy#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z gotoxy.y
    // [610] phi gotoxy::x#30 = PROGRESS_X [phi:smc_read::@10->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [978] phi from smc_read::@10 to smc_read::@11 [phi:smc_read::@10->smc_read::@11]
    // smc_read::@11
    // FILE *fp = fopen("SMC.BIN", "r")
    // [979] call fopen
    // [2041] phi from smc_read::@11 to fopen [phi:smc_read::@11->fopen]
    // [2041] phi __errno#325 = __errno#35 [phi:smc_read::@11->fopen#0] -- register_copy 
    // [2041] phi fopen::pathtoken#0 = smc_read::path [phi:smc_read::@11->fopen#1] -- pbuz1=pbuc1 
    lda #<path
    sta.z fopen.pathtoken
    lda #>path
    sta.z fopen.pathtoken+1
    jsr fopen
    // FILE *fp = fopen("SMC.BIN", "r")
    // [980] fopen::return#3 = fopen::return#2
    // smc_read::@12
    // [981] smc_read::fp#0 = fopen::return#3 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [982] if((struct $2 *)0==smc_read::fp#0) goto smc_read::@1 -- pssc1_eq_pssz1_then_la1 
    lda.z fp
    cmp #<0
    bne !+
    lda.z fp+1
    cmp #>0
    beq __b4
  !:
    // [983] phi from smc_read::@12 to smc_read::@2 [phi:smc_read::@12->smc_read::@2]
    // [983] phi smc_read::y#10 = PROGRESS_Y [phi:smc_read::@12->smc_read::@2#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [983] phi smc_read::progress_row_bytes#10 = 0 [phi:smc_read::@12->smc_read::@2#1] -- vwum1=vwuc1 
    lda #<0
    sta progress_row_bytes
    sta progress_row_bytes+1
    // [983] phi smc_read::smc_file_size#11 = 0 [phi:smc_read::@12->smc_read::@2#2] -- vwum1=vwuc1 
    sta smc_file_size
    sta smc_file_size+1
    // [983] phi smc_read::ram_ptr#10 = (char *)$7800 [phi:smc_read::@12->smc_read::@2#3] -- pbum1=pbuc1 
    lda #<$7800
    sta ram_ptr
    lda #>$7800
    sta ram_ptr+1
  // We read block_size bytes at a time, and each block_size bytes we plot a dot.
  // Every r bytes we move to the next line.
    // smc_read::@2
  __b2:
    // fgets(ram_ptr, SMC_PROGRESS_CELL, fp)
    // [984] fgets::ptr#2 = smc_read::ram_ptr#10 -- pbuz1=pbum2 
    lda ram_ptr
    sta.z fgets.ptr
    lda ram_ptr+1
    sta.z fgets.ptr+1
    // [985] fgets::stream#0 = smc_read::fp#0 -- pssm1=pssz2 
    lda.z fp
    sta fgets.stream
    lda.z fp+1
    sta fgets.stream+1
    // [986] call fgets
    // [2122] phi from smc_read::@2 to fgets [phi:smc_read::@2->fgets]
    // [2122] phi fgets::ptr#12 = fgets::ptr#2 [phi:smc_read::@2->fgets#0] -- register_copy 
    // [2122] phi fgets::size#10 = SMC_PROGRESS_CELL [phi:smc_read::@2->fgets#1] -- vwuz1=vbuc1 
    lda #<SMC_PROGRESS_CELL
    sta.z fgets.size
    lda #>SMC_PROGRESS_CELL
    sta.z fgets.size+1
    // [2122] phi fgets::stream#2 = fgets::stream#0 [phi:smc_read::@2->fgets#2] -- register_copy 
    jsr fgets
    // fgets(ram_ptr, SMC_PROGRESS_CELL, fp)
    // [987] fgets::return#5 = fgets::return#1
    // smc_read::@13
    // smc_file_read = fgets(ram_ptr, SMC_PROGRESS_CELL, fp)
    // [988] smc_read::smc_file_read#1 = fgets::return#5
    // while (smc_file_read = fgets(ram_ptr, SMC_PROGRESS_CELL, fp))
    // [989] if(0!=smc_read::smc_file_read#1) goto smc_read::@3 -- 0_neq_vwuz1_then_la1 
    lda.z smc_file_read
    ora.z smc_file_read+1
    bne __b3
    // smc_read::@4
    // fclose(fp)
    // [990] fclose::stream#0 = smc_read::fp#0
    // [991] call fclose
    // [2176] phi from smc_read::@4 to fclose [phi:smc_read::@4->fclose]
    // [2176] phi fclose::stream#2 = fclose::stream#0 [phi:smc_read::@4->fclose#0] -- register_copy 
    jsr fclose
    // [992] phi from smc_read::@4 to smc_read::@1 [phi:smc_read::@4->smc_read::@1]
    // [992] phi smc_read::return#0 = smc_read::smc_file_size#11 [phi:smc_read::@4->smc_read::@1#0] -- register_copy 
    rts
    // [992] phi from smc_read::@12 to smc_read::@1 [phi:smc_read::@12->smc_read::@1]
  __b4:
    // [992] phi smc_read::return#0 = 0 [phi:smc_read::@12->smc_read::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta return
    sta return+1
    // smc_read::@1
    // smc_read::@return
    // }
    // [993] return 
    rts
    // [994] phi from smc_read::@13 to smc_read::@3 [phi:smc_read::@13->smc_read::@3]
    // smc_read::@3
  __b3:
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [995] call snprintf_init
    // [872] phi from smc_read::@3 to snprintf_init [phi:smc_read::@3->snprintf_init]
    // [872] phi snprintf_init::s#25 = info_text [phi:smc_read::@3->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [996] phi from smc_read::@3 to smc_read::@14 [phi:smc_read::@3->smc_read::@14]
    // smc_read::@14
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [997] call printf_str
    // [877] phi from smc_read::@14 to printf_str [phi:smc_read::@14->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:smc_read::@14->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = smc_read::s [phi:smc_read::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@15
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [998] printf_uint::uvalue#4 = smc_read::smc_file_read#1 -- vwuz1=vwuz2 
    lda.z smc_file_read
    sta.z printf_uint.uvalue
    lda.z smc_file_read+1
    sta.z printf_uint.uvalue+1
    // [999] call printf_uint
    // [911] phi from smc_read::@15 to printf_uint [phi:smc_read::@15->printf_uint]
    // [911] phi printf_uint::format_zero_padding#19 = 1 [phi:smc_read::@15->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [911] phi printf_uint::format_min_length#19 = 5 [phi:smc_read::@15->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [911] phi printf_uint::putc#19 = &snputc [phi:smc_read::@15->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [911] phi printf_uint::format_radix#19 = HEXADECIMAL [phi:smc_read::@15->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [911] phi printf_uint::uvalue#19 = printf_uint::uvalue#4 [phi:smc_read::@15->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1000] phi from smc_read::@15 to smc_read::@16 [phi:smc_read::@15->smc_read::@16]
    // smc_read::@16
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1001] call printf_str
    // [877] phi from smc_read::@16 to printf_str [phi:smc_read::@16->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:smc_read::@16->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = s4 [phi:smc_read::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@17
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1002] printf_uint::uvalue#5 = smc_read::smc_file_size#11 -- vwuz1=vwum2 
    lda smc_file_size
    sta.z printf_uint.uvalue
    lda smc_file_size+1
    sta.z printf_uint.uvalue+1
    // [1003] call printf_uint
    // [911] phi from smc_read::@17 to printf_uint [phi:smc_read::@17->printf_uint]
    // [911] phi printf_uint::format_zero_padding#19 = 1 [phi:smc_read::@17->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [911] phi printf_uint::format_min_length#19 = 5 [phi:smc_read::@17->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [911] phi printf_uint::putc#19 = &snputc [phi:smc_read::@17->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [911] phi printf_uint::format_radix#19 = HEXADECIMAL [phi:smc_read::@17->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [911] phi printf_uint::uvalue#19 = printf_uint::uvalue#5 [phi:smc_read::@17->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1004] phi from smc_read::@17 to smc_read::@18 [phi:smc_read::@17->smc_read::@18]
    // smc_read::@18
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1005] call printf_str
    // [877] phi from smc_read::@18 to printf_str [phi:smc_read::@18->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:smc_read::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = s2 [phi:smc_read::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // [1006] phi from smc_read::@18 to smc_read::@19 [phi:smc_read::@18->smc_read::@19]
    // smc_read::@19
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1007] call printf_uint
    // [911] phi from smc_read::@19 to printf_uint [phi:smc_read::@19->printf_uint]
    // [911] phi printf_uint::format_zero_padding#19 = 1 [phi:smc_read::@19->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [911] phi printf_uint::format_min_length#19 = 2 [phi:smc_read::@19->printf_uint#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uint.format_min_length
    // [911] phi printf_uint::putc#19 = &snputc [phi:smc_read::@19->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [911] phi printf_uint::format_radix#19 = HEXADECIMAL [phi:smc_read::@19->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [911] phi printf_uint::uvalue#19 = 0 [phi:smc_read::@19->printf_uint#4] -- vwuz1=vbuc1 
    lda #<0
    sta.z printf_uint.uvalue
    sta.z printf_uint.uvalue+1
    jsr printf_uint
    // [1008] phi from smc_read::@19 to smc_read::@20 [phi:smc_read::@19->smc_read::@20]
    // smc_read::@20
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1009] call printf_str
    // [877] phi from smc_read::@20 to printf_str [phi:smc_read::@20->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:smc_read::@20->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = s3 [phi:smc_read::@20->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@21
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1010] printf_uint::uvalue#7 = (unsigned int)smc_read::ram_ptr#10 -- vwuz1=vwum2 
    lda ram_ptr
    sta.z printf_uint.uvalue
    lda ram_ptr+1
    sta.z printf_uint.uvalue+1
    // [1011] call printf_uint
    // [911] phi from smc_read::@21 to printf_uint [phi:smc_read::@21->printf_uint]
    // [911] phi printf_uint::format_zero_padding#19 = 1 [phi:smc_read::@21->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [911] phi printf_uint::format_min_length#19 = 4 [phi:smc_read::@21->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [911] phi printf_uint::putc#19 = &snputc [phi:smc_read::@21->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [911] phi printf_uint::format_radix#19 = HEXADECIMAL [phi:smc_read::@21->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [911] phi printf_uint::uvalue#19 = printf_uint::uvalue#7 [phi:smc_read::@21->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1012] phi from smc_read::@21 to smc_read::@22 [phi:smc_read::@21->smc_read::@22]
    // smc_read::@22
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1013] call printf_str
    // [877] phi from smc_read::@22 to printf_str [phi:smc_read::@22->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:smc_read::@22->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = s7 [phi:smc_read::@22->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@23
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1014] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1015] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1017] call display_action_text
    // [1051] phi from smc_read::@23 to display_action_text [phi:smc_read::@23->display_action_text]
    // [1051] phi display_action_text::info_text#19 = info_text [phi:smc_read::@23->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_read::@24
    // if (progress_row_bytes == SMC_PROGRESS_ROW)
    // [1018] if(smc_read::progress_row_bytes#10!=SMC_PROGRESS_ROW) goto smc_read::@5 -- vwum1_neq_vwuc1_then_la1 
    lda progress_row_bytes+1
    cmp #>SMC_PROGRESS_ROW
    bne __b5
    lda progress_row_bytes
    cmp #<SMC_PROGRESS_ROW
    bne __b5
    // smc_read::@7
    // gotoxy(x, ++y);
    // [1019] smc_read::y#1 = ++ smc_read::y#10 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [1020] gotoxy::y#20 = smc_read::y#1 -- vbuz1=vbum2 
    lda y
    sta.z gotoxy.y
    // [1021] call gotoxy
    // [610] phi from smc_read::@7 to gotoxy [phi:smc_read::@7->gotoxy]
    // [610] phi gotoxy::y#30 = gotoxy::y#20 [phi:smc_read::@7->gotoxy#0] -- register_copy 
    // [610] phi gotoxy::x#30 = PROGRESS_X [phi:smc_read::@7->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [1022] phi from smc_read::@7 to smc_read::@5 [phi:smc_read::@7->smc_read::@5]
    // [1022] phi smc_read::y#20 = smc_read::y#1 [phi:smc_read::@7->smc_read::@5#0] -- register_copy 
    // [1022] phi smc_read::progress_row_bytes#4 = 0 [phi:smc_read::@7->smc_read::@5#1] -- vwum1=vbuc1 
    lda #<0
    sta progress_row_bytes
    sta progress_row_bytes+1
    // [1022] phi from smc_read::@24 to smc_read::@5 [phi:smc_read::@24->smc_read::@5]
    // [1022] phi smc_read::y#20 = smc_read::y#10 [phi:smc_read::@24->smc_read::@5#0] -- register_copy 
    // [1022] phi smc_read::progress_row_bytes#4 = smc_read::progress_row_bytes#10 [phi:smc_read::@24->smc_read::@5#1] -- register_copy 
    // smc_read::@5
  __b5:
    // if(display_progress)
    // [1023] if(0==smc_read::display_progress#19) goto smc_read::@6 -- 0_eq_vbuz1_then_la1 
    lda.z display_progress
    beq __b6
    // smc_read::@8
    // cputc('.')
    // [1024] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [1025] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_read::@6
  __b6:
    // ram_ptr += smc_file_read
    // [1027] smc_read::ram_ptr#1 = smc_read::ram_ptr#10 + smc_read::smc_file_read#1 -- pbum1=pbum1_plus_vwuz2 
    clc
    lda ram_ptr
    adc.z smc_file_read
    sta ram_ptr
    lda ram_ptr+1
    adc.z smc_file_read+1
    sta ram_ptr+1
    // smc_file_size += smc_file_read
    // [1028] smc_read::smc_file_size#1 = smc_read::smc_file_size#11 + smc_read::smc_file_read#1 -- vwum1=vwum1_plus_vwuz2 
    clc
    lda smc_file_size
    adc.z smc_file_read
    sta smc_file_size
    lda smc_file_size+1
    adc.z smc_file_read+1
    sta smc_file_size+1
    // progress_row_bytes += smc_file_read
    // [1029] smc_read::progress_row_bytes#2 = smc_read::progress_row_bytes#4 + smc_read::smc_file_read#1 -- vwum1=vwum1_plus_vwuz2 
    clc
    lda progress_row_bytes
    adc.z smc_file_read
    sta progress_row_bytes
    lda progress_row_bytes+1
    adc.z smc_file_read+1
    sta progress_row_bytes+1
    // [983] phi from smc_read::@6 to smc_read::@2 [phi:smc_read::@6->smc_read::@2]
    // [983] phi smc_read::y#10 = smc_read::y#20 [phi:smc_read::@6->smc_read::@2#0] -- register_copy 
    // [983] phi smc_read::progress_row_bytes#10 = smc_read::progress_row_bytes#2 [phi:smc_read::@6->smc_read::@2#1] -- register_copy 
    // [983] phi smc_read::smc_file_size#11 = smc_read::smc_file_size#1 [phi:smc_read::@6->smc_read::@2#2] -- register_copy 
    // [983] phi smc_read::ram_ptr#10 = smc_read::ram_ptr#1 [phi:smc_read::@6->smc_read::@2#3] -- register_copy 
    jmp __b2
  .segment Data
    info_text: .text "Reading SMC.BIN ... (.) data, ( ) empty"
    .byte 0
    path: .text "SMC.BIN"
    .byte 0
    s: .text "Reading SMC.BIN:"
    .byte 0
    .label return = strcpy.src
    .label y = main.check_status_vera1_main__0
    .label ram_ptr = clrscr.ch
    .label smc_file_size = strcpy.src
    /// Holds the amount of bytes actually read in the memory to be flashed.
    .label progress_row_bytes = strcpy.dst
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
    // [1031] BRAM = system_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // system_reset::bank_set_brom1
    // BROM = bank
    // [1032] BROM = system_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // system_reset::@2
    // asm
    // asm { jmp($FFFC)  }
    jmp ($fffc)
    // [1034] phi from system_reset::@1 system_reset::@2 to system_reset::@1 [phi:system_reset::@1/system_reset::@2->system_reset::@1]
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
    .label i = $3d
    // [1036] phi from wait_moment to wait_moment::@1 [phi:wait_moment->wait_moment::@1]
    // [1036] phi wait_moment::i#2 = $ffff [phi:wait_moment->wait_moment::@1#0] -- vwuz1=vwuc1 
    lda #<$ffff
    sta.z i
    lda #>$ffff
    sta.z i+1
    // wait_moment::@1
  __b1:
    // for(unsigned int i=65535; i>0; i--)
    // [1037] if(wait_moment::i#2>0) goto wait_moment::@2 -- vwuz1_gt_0_then_la1 
    lda.z i+1
    bne __b2
    lda.z i
    bne __b2
  !:
    // wait_moment::@return
    // }
    // [1038] return 
    rts
    // wait_moment::@2
  __b2:
    // for(unsigned int i=65535; i>0; i--)
    // [1039] wait_moment::i#1 = -- wait_moment::i#2 -- vwuz1=_dec_vwuz1 
    lda.z i
    bne !+
    dec.z i+1
  !:
    dec.z i
    // [1036] phi from wait_moment::@2 to wait_moment::@1 [phi:wait_moment::@2->wait_moment::@1]
    // [1036] phi wait_moment::i#2 = wait_moment::i#1 [phi:wait_moment::@2->wait_moment::@1#0] -- register_copy 
    jmp __b1
}
  // printf_uchar
// Print an unsigned char using a specific format
// void printf_uchar(__zp($4d) void (*putc)(char), __zp($2d) char uvalue, __zp($e7) char format_min_length, char format_justify_left, char format_sign_always, __zp($e6) char format_zero_padding, char format_upper_case, __zp($e4) char format_radix)
printf_uchar: {
    .label uvalue = $2d
    .label format_radix = $e4
    .label putc = $4d
    .label format_min_length = $e7
    .label format_zero_padding = $e6
    // printf_uchar::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1041] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // uctoa(uvalue, printf_buffer.digits, format.radix)
    // [1042] uctoa::value#1 = printf_uchar::uvalue#10
    // [1043] uctoa::radix#0 = printf_uchar::format_radix#10
    // [1044] call uctoa
    // Format number into buffer
    jsr uctoa
    // printf_uchar::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1045] printf_number_buffer::putc#2 = printf_uchar::putc#10
    // [1046] printf_number_buffer::buffer_sign#2 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [1047] printf_number_buffer::format_min_length#2 = printf_uchar::format_min_length#10
    // [1048] printf_number_buffer::format_zero_padding#2 = printf_uchar::format_zero_padding#10
    // [1049] call printf_number_buffer
  // Print using format
    // [1988] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [1988] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#2 [phi:printf_uchar::@2->printf_number_buffer#0] -- register_copy 
    // [1988] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#2 [phi:printf_uchar::@2->printf_number_buffer#1] -- register_copy 
    // [1988] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#2 [phi:printf_uchar::@2->printf_number_buffer#2] -- register_copy 
    // [1988] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#2 [phi:printf_uchar::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [1050] return 
    rts
}
  // display_action_text
/**
 * @brief Print an info line at the action frame, which is the second line.
 * 
 * @param info_text The info text to be displayed.
 */
// void display_action_text(__zp($73) char *info_text)
display_action_text: {
    .label x = $ea
    .label y = $e8
    .label info_text = $73
    // unsigned char x = wherex()
    // [1052] call wherex
    jsr wherex
    // [1053] wherex::return#3 = wherex::return#0 -- vbuz1=vbuz2 
    lda.z wherex.return
    sta.z wherex.return_1
    // display_action_text::@1
    // [1054] display_action_text::x#0 = wherex::return#3
    // unsigned char y = wherey()
    // [1055] call wherey
    jsr wherey
    // [1056] wherey::return#3 = wherey::return#0 -- vbuz1=vbuz2 
    lda.z wherey.return
    sta.z wherey.return_1
    // display_action_text::@2
    // [1057] display_action_text::y#0 = wherey::return#3
    // gotoxy(2, PROGRESS_Y-3)
    // [1058] call gotoxy
    // [610] phi from display_action_text::@2 to gotoxy [phi:display_action_text::@2->gotoxy]
    // [610] phi gotoxy::y#30 = PROGRESS_Y-3 [phi:display_action_text::@2->gotoxy#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-3
    sta.z gotoxy.y
    // [610] phi gotoxy::x#30 = 2 [phi:display_action_text::@2->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // display_action_text::@3
    // printf("%-65s", info_text)
    // [1059] printf_string::str#2 = display_action_text::info_text#19 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1060] call printf_string
    // [886] phi from display_action_text::@3 to printf_string [phi:display_action_text::@3->printf_string]
    // [886] phi printf_string::putc#19 = &cputc [phi:display_action_text::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [886] phi printf_string::str#19 = printf_string::str#2 [phi:display_action_text::@3->printf_string#1] -- register_copy 
    // [886] phi printf_string::format_justify_left#19 = 1 [phi:display_action_text::@3->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [886] phi printf_string::format_min_length#19 = $41 [phi:display_action_text::@3->printf_string#3] -- vbuz1=vbuc1 
    lda #$41
    sta.z printf_string.format_min_length
    jsr printf_string
    // display_action_text::@4
    // gotoxy(x, y)
    // [1061] gotoxy::x#12 = display_action_text::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1062] gotoxy::y#12 = display_action_text::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1063] call gotoxy
    // [610] phi from display_action_text::@4 to gotoxy [phi:display_action_text::@4->gotoxy]
    // [610] phi gotoxy::y#30 = gotoxy::y#12 [phi:display_action_text::@4->gotoxy#0] -- register_copy 
    // [610] phi gotoxy::x#30 = gotoxy::x#12 [phi:display_action_text::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_action_text::@return
    // }
    // [1064] return 
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
    // [1066] BRAM = smc_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // smc_reset::bank_set_brom1
    // BROM = bank
    // [1067] BROM = smc_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // smc_reset::@2
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [1068] smc_reset::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [1069] smc_reset::cx16_k_i2c_write_byte1_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte1_offset
    // [1070] smc_reset::cx16_k_i2c_write_byte1_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte1_value
    // smc_reset::cx16_k_i2c_write_byte1
    // unsigned char result
    // [1071] smc_reset::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
    sta cx16_k_i2c_write_byte1_result
    // asm
    // asm { ldxdevice ldyoffset ldavalue stzresult jsrCX16_I2C_WRITE_BYTE rolresult  }
    ldx cx16_k_i2c_write_byte1_device
    ldy cx16_k_i2c_write_byte1_offset
    lda cx16_k_i2c_write_byte1_value
    stz cx16_k_i2c_write_byte1_result
    jsr CX16_I2C_WRITE_BYTE
    rol cx16_k_i2c_write_byte1_result
    // [1073] phi from smc_reset::@1 smc_reset::cx16_k_i2c_write_byte1 to smc_reset::@1 [phi:smc_reset::@1/smc_reset::cx16_k_i2c_write_byte1->smc_reset::@1]
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
 * @brief Display the ROM status of a specific rom chip. 
 * 
 * @param rom_chip The ROM chip, 0 is the main CX16 ROM chip, maximum 7 ROMs.
 * @param info_status The status.
 * @param info_text The status text.
 */
// void display_info_rom(__mem() char rom_chip, __mem() char info_status, __zp($4f) char *info_text)
display_info_rom: {
    .label display_info_rom__13 = $6e
    .label x = $f1
    .label info_text = $4f
    // unsigned char x = wherex()
    // [1075] call wherex
    jsr wherex
    // [1076] wherex::return#12 = wherex::return#0 -- vbuz1=vbuz2 
    lda.z wherex.return
    sta.z wherex.return_4
    // display_info_rom::@3
    // [1077] display_info_rom::x#0 = wherex::return#12
    // unsigned char y = wherey()
    // [1078] call wherey
    jsr wherey
    // [1079] wherey::return#12 = wherey::return#0 -- vbum1=vbuz2 
    lda.z wherey.return
    sta wherey.return_4
    // display_info_rom::@4
    // [1080] display_info_rom::y#0 = wherey::return#12
    // status_rom[rom_chip] = info_status
    // [1081] status_rom[display_info_rom::rom_chip#17] = display_info_rom::info_status#17 -- pbuc1_derefidx_vbum1=vbum2 
    lda info_status
    ldy rom_chip
    sta status_rom,y
    // display_rom_led(rom_chip, status_color[info_status])
    // [1082] display_rom_led::chip#1 = display_info_rom::rom_chip#17 -- vbuz1=vbum2 
    tya
    sta.z display_rom_led.chip
    // [1083] display_rom_led::c#1 = status_color[display_info_rom::info_status#17] -- vbuz1=pbuc1_derefidx_vbum2 
    ldy info_status
    lda status_color,y
    sta.z display_rom_led.c
    // [1084] call display_rom_led
    // [1924] phi from display_info_rom::@4 to display_rom_led [phi:display_info_rom::@4->display_rom_led]
    // [1924] phi display_rom_led::c#2 = display_rom_led::c#1 [phi:display_info_rom::@4->display_rom_led#0] -- register_copy 
    // [1924] phi display_rom_led::chip#2 = display_rom_led::chip#1 [phi:display_info_rom::@4->display_rom_led#1] -- register_copy 
    jsr display_rom_led
    // display_info_rom::@5
    // gotoxy(INFO_X, INFO_Y+rom_chip+2)
    // [1085] gotoxy::y#17 = display_info_rom::rom_chip#17 + $11+2 -- vbuz1=vbum2_plus_vbuc1 
    lda #$11+2
    clc
    adc rom_chip
    sta.z gotoxy.y
    // [1086] call gotoxy
    // [610] phi from display_info_rom::@5 to gotoxy [phi:display_info_rom::@5->gotoxy]
    // [610] phi gotoxy::y#30 = gotoxy::y#17 [phi:display_info_rom::@5->gotoxy#0] -- register_copy 
    // [610] phi gotoxy::x#30 = 4 [phi:display_info_rom::@5->gotoxy#1] -- vbuz1=vbuc1 
    lda #4
    sta.z gotoxy.x
    jsr gotoxy
    // [1087] phi from display_info_rom::@5 to display_info_rom::@6 [phi:display_info_rom::@5->display_info_rom::@6]
    // display_info_rom::@6
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1088] call printf_str
    // [877] phi from display_info_rom::@6 to printf_str [phi:display_info_rom::@6->printf_str]
    // [877] phi printf_str::putc#73 = &cputc [phi:display_info_rom::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = display_info_rom::s [phi:display_info_rom::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@7
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1089] printf_uchar::uvalue#0 = display_info_rom::rom_chip#17 -- vbuz1=vbum2 
    lda rom_chip
    sta.z printf_uchar.uvalue
    // [1090] call printf_uchar
    // [1040] phi from display_info_rom::@7 to printf_uchar [phi:display_info_rom::@7->printf_uchar]
    // [1040] phi printf_uchar::format_zero_padding#10 = 0 [phi:display_info_rom::@7->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1040] phi printf_uchar::format_min_length#10 = 0 [phi:display_info_rom::@7->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1040] phi printf_uchar::putc#10 = &cputc [phi:display_info_rom::@7->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1040] phi printf_uchar::format_radix#10 = DECIMAL [phi:display_info_rom::@7->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1040] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#0 [phi:display_info_rom::@7->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1091] phi from display_info_rom::@7 to display_info_rom::@8 [phi:display_info_rom::@7->display_info_rom::@8]
    // display_info_rom::@8
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1092] call printf_str
    // [877] phi from display_info_rom::@8 to printf_str [phi:display_info_rom::@8->printf_str]
    // [877] phi printf_str::putc#73 = &cputc [phi:display_info_rom::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = s1 [phi:display_info_rom::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@9
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1093] display_info_rom::$10 = display_info_rom::info_status#17 << 1 -- vbum1=vbum1_rol_1 
    asl display_info_rom__10
    // [1094] printf_string::str#7 = status_text[display_info_rom::$10] -- pbuz1=qbuc1_derefidx_vbum2 
    ldy display_info_rom__10
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [1095] call printf_string
    // [886] phi from display_info_rom::@9 to printf_string [phi:display_info_rom::@9->printf_string]
    // [886] phi printf_string::putc#19 = &cputc [phi:display_info_rom::@9->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [886] phi printf_string::str#19 = printf_string::str#7 [phi:display_info_rom::@9->printf_string#1] -- register_copy 
    // [886] phi printf_string::format_justify_left#19 = 1 [phi:display_info_rom::@9->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [886] phi printf_string::format_min_length#19 = 9 [phi:display_info_rom::@9->printf_string#3] -- vbuz1=vbuc1 
    lda #9
    sta.z printf_string.format_min_length
    jsr printf_string
    // [1096] phi from display_info_rom::@9 to display_info_rom::@10 [phi:display_info_rom::@9->display_info_rom::@10]
    // display_info_rom::@10
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1097] call printf_str
    // [877] phi from display_info_rom::@10 to printf_str [phi:display_info_rom::@10->printf_str]
    // [877] phi printf_str::putc#73 = &cputc [phi:display_info_rom::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = s1 [phi:display_info_rom::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@11
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1098] display_info_rom::$11 = display_info_rom::rom_chip#17 << 1 -- vbum1=vbum2_rol_1 
    lda rom_chip
    asl
    sta display_info_rom__11
    // [1099] printf_string::str#8 = rom_device_names[display_info_rom::$11] -- pbuz1=qbuc1_derefidx_vbum2 
    tay
    lda rom_device_names,y
    sta.z printf_string.str
    lda rom_device_names+1,y
    sta.z printf_string.str+1
    // [1100] call printf_string
    // [886] phi from display_info_rom::@11 to printf_string [phi:display_info_rom::@11->printf_string]
    // [886] phi printf_string::putc#19 = &cputc [phi:display_info_rom::@11->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [886] phi printf_string::str#19 = printf_string::str#8 [phi:display_info_rom::@11->printf_string#1] -- register_copy 
    // [886] phi printf_string::format_justify_left#19 = 1 [phi:display_info_rom::@11->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [886] phi printf_string::format_min_length#19 = 6 [phi:display_info_rom::@11->printf_string#3] -- vbuz1=vbuc1 
    lda #6
    sta.z printf_string.format_min_length
    jsr printf_string
    // [1101] phi from display_info_rom::@11 to display_info_rom::@12 [phi:display_info_rom::@11->display_info_rom::@12]
    // display_info_rom::@12
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1102] call printf_str
    // [877] phi from display_info_rom::@12 to printf_str [phi:display_info_rom::@12->printf_str]
    // [877] phi printf_str::putc#73 = &cputc [phi:display_info_rom::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = s1 [phi:display_info_rom::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@13
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1103] display_info_rom::$13 = display_info_rom::rom_chip#17 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z display_info_rom__13
    // [1104] printf_ulong::uvalue#0 = file_sizes[display_info_rom::$13] -- vduz1=pduc1_derefidx_vbuz2 
    tay
    lda file_sizes,y
    sta.z printf_ulong.uvalue
    lda file_sizes+1,y
    sta.z printf_ulong.uvalue+1
    lda file_sizes+2,y
    sta.z printf_ulong.uvalue+2
    lda file_sizes+3,y
    sta.z printf_ulong.uvalue+3
    // [1105] call printf_ulong
    // [1276] phi from display_info_rom::@13 to printf_ulong [phi:display_info_rom::@13->printf_ulong]
    // [1276] phi printf_ulong::format_zero_padding#11 = 1 [phi:display_info_rom::@13->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1276] phi printf_ulong::format_min_length#11 = 5 [phi:display_info_rom::@13->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1276] phi printf_ulong::putc#11 = &cputc [phi:display_info_rom::@13->printf_ulong#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_ulong.putc
    lda #>cputc
    sta.z printf_ulong.putc+1
    // [1276] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:display_info_rom::@13->printf_ulong#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1276] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#0 [phi:display_info_rom::@13->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1106] phi from display_info_rom::@13 to display_info_rom::@14 [phi:display_info_rom::@13->display_info_rom::@14]
    // display_info_rom::@14
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1107] call printf_str
    // [877] phi from display_info_rom::@14 to printf_str [phi:display_info_rom::@14->printf_str]
    // [877] phi printf_str::putc#73 = &cputc [phi:display_info_rom::@14->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = display_info_rom::s4 [phi:display_info_rom::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@15
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1108] printf_ulong::uvalue#1 = rom_sizes[display_info_rom::$13] -- vduz1=pduc1_derefidx_vbuz2 
    ldy.z display_info_rom__13
    lda rom_sizes,y
    sta.z printf_ulong.uvalue
    lda rom_sizes+1,y
    sta.z printf_ulong.uvalue+1
    lda rom_sizes+2,y
    sta.z printf_ulong.uvalue+2
    lda rom_sizes+3,y
    sta.z printf_ulong.uvalue+3
    // [1109] call printf_ulong
    // [1276] phi from display_info_rom::@15 to printf_ulong [phi:display_info_rom::@15->printf_ulong]
    // [1276] phi printf_ulong::format_zero_padding#11 = 1 [phi:display_info_rom::@15->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1276] phi printf_ulong::format_min_length#11 = 5 [phi:display_info_rom::@15->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1276] phi printf_ulong::putc#11 = &cputc [phi:display_info_rom::@15->printf_ulong#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_ulong.putc
    lda #>cputc
    sta.z printf_ulong.putc+1
    // [1276] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:display_info_rom::@15->printf_ulong#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1276] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#1 [phi:display_info_rom::@15->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1110] phi from display_info_rom::@15 to display_info_rom::@16 [phi:display_info_rom::@15->display_info_rom::@16]
    // display_info_rom::@16
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1111] call printf_str
    // [877] phi from display_info_rom::@16 to printf_str [phi:display_info_rom::@16->printf_str]
    // [877] phi printf_str::putc#73 = &cputc [phi:display_info_rom::@16->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = s1 [phi:display_info_rom::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@17
    // if(info_text)
    // [1112] if((char *)0==display_info_rom::info_text#17) goto display_info_rom::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // display_info_rom::@2
    // printf("%-25s", info_text)
    // [1113] printf_string::str#9 = display_info_rom::info_text#17 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1114] call printf_string
    // [886] phi from display_info_rom::@2 to printf_string [phi:display_info_rom::@2->printf_string]
    // [886] phi printf_string::putc#19 = &cputc [phi:display_info_rom::@2->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [886] phi printf_string::str#19 = printf_string::str#9 [phi:display_info_rom::@2->printf_string#1] -- register_copy 
    // [886] phi printf_string::format_justify_left#19 = 1 [phi:display_info_rom::@2->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [886] phi printf_string::format_min_length#19 = $19 [phi:display_info_rom::@2->printf_string#3] -- vbuz1=vbuc1 
    lda #$19
    sta.z printf_string.format_min_length
    jsr printf_string
    // display_info_rom::@1
  __b1:
    // gotoxy(x,y)
    // [1115] gotoxy::x#18 = display_info_rom::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1116] gotoxy::y#18 = display_info_rom::y#0 -- vbuz1=vbum2 
    lda y
    sta.z gotoxy.y
    // [1117] call gotoxy
    // [610] phi from display_info_rom::@1 to gotoxy [phi:display_info_rom::@1->gotoxy]
    // [610] phi gotoxy::y#30 = gotoxy::y#18 [phi:display_info_rom::@1->gotoxy#0] -- register_copy 
    // [610] phi gotoxy::x#30 = gotoxy::x#18 [phi:display_info_rom::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_rom::@return
    // }
    // [1118] return 
    rts
  .segment Data
    s: .text "ROM"
    .byte 0
    s4: .text " / "
    .byte 0
    .label display_info_rom__10 = main.check_status_smc8_main__0
    display_info_rom__11: .byte 0
    .label y = smc_flash.smc_byte_upload
    .label rom_chip = main.check_status_vera3_main__0
    .label info_status = main.check_status_smc8_main__0
}
.segment Code
  // rom_file
// __mem() char * rom_file(__mem() char rom_chip)
rom_file: {
    // if(rom_chip)
    // [1120] if(0!=rom_file::rom_chip#2) goto rom_file::@1 -- 0_neq_vbum1_then_la1 
    lda rom_chip
    bne __b1
    // [1123] phi from rom_file to rom_file::@return [phi:rom_file->rom_file::@return]
    // [1123] phi rom_file::return#2 = rom_file::file_rom_cx16 [phi:rom_file->rom_file::@return#0] -- pbum1=pbuc1 
    lda #<file_rom_cx16
    sta return
    lda #>file_rom_cx16
    sta return+1
    rts
    // rom_file::@1
  __b1:
    // '0'+rom_chip
    // [1121] rom_file::$0 = '0' + rom_file::rom_chip#2 -- vbum1=vbuc1_plus_vbum1 
    lda #'0'
    clc
    adc rom_file__0
    sta rom_file__0
    // file_rom_card[3] = '0'+rom_chip
    // [1122] *(rom_file::file_rom_card+3) = rom_file::$0 -- _deref_pbuc1=vbum1 
    sta file_rom_card+3
    // [1123] phi from rom_file::@1 to rom_file::@return [phi:rom_file::@1->rom_file::@return]
    // [1123] phi rom_file::return#2 = rom_file::file_rom_card [phi:rom_file::@1->rom_file::@return#0] -- pbum1=pbuc1 
    lda #<file_rom_card
    sta return
    lda #>file_rom_card
    sta return+1
    // rom_file::@return
    // }
    // [1124] return 
    rts
  .segment Data
    file_rom_cx16: .text "ROM.BIN"
    .byte 0
    file_rom_card: .text "ROMn.BIN"
    .byte 0
    .label rom_file__0 = main.check_status_cx16_rom4_check_status_rom1_main__0
    return: .word 0
    .label rom_chip = main.check_status_cx16_rom4_check_status_rom1_main__0
}
.segment Code
  // rom_read
// __mem() unsigned long rom_read(__zp($c4) char display_progress, char rom_chip, __zp($d0) char *file, char info_status, __mem() char brom_bank_start, __zp($7a) unsigned long rom_size)
rom_read: {
    .const bank_set_brom1_bank = 0
    .label rom_read__11 = $f5
    .label rom_address = $57
    .label rom_package_read = $62
    .label y = $77
    .label ram_address = $ad
    .label rom_row_current = $78
    .label bram_bank = $ce
    .label file = $d0
    .label rom_size = $7a
    .label display_progress = $c4
    // unsigned long rom_address = rom_address_from_bank(brom_bank_start)
    // [1126] rom_address_from_bank::rom_bank#0 = rom_read::brom_bank_start#22 -- vbuz1=vbum2 
    lda brom_bank_start
    sta.z rom_address_from_bank.rom_bank
    // [1127] call rom_address_from_bank
    // [2232] phi from rom_read to rom_address_from_bank [phi:rom_read->rom_address_from_bank]
    // [2232] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#0 [phi:rom_read->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(brom_bank_start)
    // [1128] rom_address_from_bank::return#2 = rom_address_from_bank::return#0
    // rom_read::@17
    // [1129] rom_read::rom_address#0 = rom_address_from_bank::return#2
    // rom_read::bank_set_bram1
    // BRAM = bank
    // [1130] BRAM = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z BRAM
    // rom_read::bank_set_brom1
    // BROM = bank
    // [1131] BROM = rom_read::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [1132] phi from rom_read::bank_set_brom1 to rom_read::@15 [phi:rom_read::bank_set_brom1->rom_read::@15]
    // rom_read::@15
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1133] call snprintf_init
    // [872] phi from rom_read::@15 to snprintf_init [phi:rom_read::@15->snprintf_init]
    // [872] phi snprintf_init::s#25 = info_text [phi:rom_read::@15->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1134] phi from rom_read::@15 to rom_read::@18 [phi:rom_read::@15->rom_read::@18]
    // rom_read::@18
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1135] call printf_str
    // [877] phi from rom_read::@18 to printf_str [phi:rom_read::@18->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:rom_read::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = rom_read::s [phi:rom_read::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@19
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1136] printf_string::str#10 = rom_read::file#11 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [1137] call printf_string
    // [886] phi from rom_read::@19 to printf_string [phi:rom_read::@19->printf_string]
    // [886] phi printf_string::putc#19 = &snputc [phi:rom_read::@19->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [886] phi printf_string::str#19 = printf_string::str#10 [phi:rom_read::@19->printf_string#1] -- register_copy 
    // [886] phi printf_string::format_justify_left#19 = 0 [phi:rom_read::@19->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [886] phi printf_string::format_min_length#19 = 0 [phi:rom_read::@19->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [1138] phi from rom_read::@19 to rom_read::@20 [phi:rom_read::@19->rom_read::@20]
    // rom_read::@20
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1139] call printf_str
    // [877] phi from rom_read::@20 to printf_str [phi:rom_read::@20->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:rom_read::@20->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = rom_read::s1 [phi:rom_read::@20->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@21
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1140] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1141] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1143] call display_action_text
    // [1051] phi from rom_read::@21 to display_action_text [phi:rom_read::@21->display_action_text]
    // [1051] phi display_action_text::info_text#19 = info_text [phi:rom_read::@21->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // rom_read::@22
    // FILE *fp = fopen(file, "r")
    // [1144] fopen::path#3 = rom_read::file#11 -- pbuz1=pbuz2 
    lda.z file
    sta.z fopen.path
    lda.z file+1
    sta.z fopen.path+1
    // [1145] call fopen
    // [2041] phi from rom_read::@22 to fopen [phi:rom_read::@22->fopen]
    // [2041] phi __errno#325 = __errno#106 [phi:rom_read::@22->fopen#0] -- register_copy 
    // [2041] phi fopen::pathtoken#0 = fopen::path#3 [phi:rom_read::@22->fopen#1] -- register_copy 
    jsr fopen
    // FILE *fp = fopen(file, "r")
    // [1146] fopen::return#4 = fopen::return#2
    // rom_read::@23
    // [1147] rom_read::fp#0 = fopen::return#4 -- pssm1=pssz2 
    lda.z fopen.return
    sta fp
    lda.z fopen.return+1
    sta fp+1
    // if (fp)
    // [1148] if((struct $2 *)0==rom_read::fp#0) goto rom_read::@1 -- pssc1_eq_pssm1_then_la1 
    lda fp
    cmp #<0
    bne !+
    lda fp+1
    cmp #>0
    beq __b2
  !:
    // [1149] phi from rom_read::@23 to rom_read::@2 [phi:rom_read::@23->rom_read::@2]
    // rom_read::@2
    // gotoxy(x, y)
    // [1150] call gotoxy
    // [610] phi from rom_read::@2 to gotoxy [phi:rom_read::@2->gotoxy]
    // [610] phi gotoxy::y#30 = PROGRESS_Y [phi:rom_read::@2->gotoxy#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z gotoxy.y
    // [610] phi gotoxy::x#30 = PROGRESS_X [phi:rom_read::@2->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [1151] phi from rom_read::@2 to rom_read::@3 [phi:rom_read::@2->rom_read::@3]
    // [1151] phi rom_read::y#11 = PROGRESS_Y [phi:rom_read::@2->rom_read::@3#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // [1151] phi rom_read::rom_row_current#10 = 0 [phi:rom_read::@2->rom_read::@3#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z rom_row_current
    sta.z rom_row_current+1
    // [1151] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#22 [phi:rom_read::@2->rom_read::@3#2] -- register_copy 
    // [1151] phi rom_read::rom_address#10 = rom_read::rom_address#0 [phi:rom_read::@2->rom_read::@3#3] -- register_copy 
    // [1151] phi rom_read::ram_address#10 = (char *)$7800 [phi:rom_read::@2->rom_read::@3#4] -- pbuz1=pbuc1 
    lda #<$7800
    sta.z ram_address
    lda #>$7800
    sta.z ram_address+1
    // [1151] phi rom_read::bram_bank#10 = 0 [phi:rom_read::@2->rom_read::@3#5] -- vbuz1=vbuc1 
    lda #0
    sta.z bram_bank
    // [1151] phi rom_read::rom_file_size#11 = 0 [phi:rom_read::@2->rom_read::@3#6] -- vdum1=vduc1 
    sta rom_file_size
    sta rom_file_size+1
    lda #<0>>$10
    sta rom_file_size+2
    lda #>0>>$10
    sta rom_file_size+3
    // rom_read::@3
  __b3:
    // while (rom_file_size < rom_size)
    // [1152] if(rom_read::rom_file_size#11<rom_read::rom_size#12) goto rom_read::@4 -- vdum1_lt_vduz2_then_la1 
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
    // [1153] fclose::stream#1 = rom_read::fp#0 -- pssz1=pssm2 
    lda fp
    sta.z fclose.stream
    lda fp+1
    sta.z fclose.stream+1
    // [1154] call fclose
    // [2176] phi from rom_read::@7 to fclose [phi:rom_read::@7->fclose]
    // [2176] phi fclose::stream#2 = fclose::stream#1 [phi:rom_read::@7->fclose#0] -- register_copy 
    jsr fclose
    // [1155] phi from rom_read::@7 to rom_read::@1 [phi:rom_read::@7->rom_read::@1]
    // [1155] phi rom_read::return#0 = rom_read::rom_file_size#11 [phi:rom_read::@7->rom_read::@1#0] -- register_copy 
    rts
    // [1155] phi from rom_read::@23 to rom_read::@1 [phi:rom_read::@23->rom_read::@1]
  __b2:
    // [1155] phi rom_read::return#0 = 0 [phi:rom_read::@23->rom_read::@1#0] -- vdum1=vduc1 
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
    // [1156] return 
    rts
    // [1157] phi from rom_read::@3 to rom_read::@4 [phi:rom_read::@3->rom_read::@4]
    // rom_read::@4
  __b4:
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1158] call snprintf_init
    // [872] phi from rom_read::@4 to snprintf_init [phi:rom_read::@4->snprintf_init]
    // [872] phi snprintf_init::s#25 = info_text [phi:rom_read::@4->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1159] phi from rom_read::@4 to rom_read::@24 [phi:rom_read::@4->rom_read::@24]
    // rom_read::@24
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1160] call printf_str
    // [877] phi from rom_read::@24 to printf_str [phi:rom_read::@24->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:rom_read::@24->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = s14 [phi:rom_read::@24->printf_str#1] -- pbuz1=pbuc1 
    lda #<s14
    sta.z printf_str.s
    lda #>s14
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@25
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1161] printf_string::str#11 = rom_read::file#11 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [1162] call printf_string
    // [886] phi from rom_read::@25 to printf_string [phi:rom_read::@25->printf_string]
    // [886] phi printf_string::putc#19 = &snputc [phi:rom_read::@25->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [886] phi printf_string::str#19 = printf_string::str#11 [phi:rom_read::@25->printf_string#1] -- register_copy 
    // [886] phi printf_string::format_justify_left#19 = 0 [phi:rom_read::@25->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [886] phi printf_string::format_min_length#19 = 0 [phi:rom_read::@25->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [1163] phi from rom_read::@25 to rom_read::@26 [phi:rom_read::@25->rom_read::@26]
    // rom_read::@26
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1164] call printf_str
    // [877] phi from rom_read::@26 to printf_str [phi:rom_read::@26->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:rom_read::@26->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = s3 [phi:rom_read::@26->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@27
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1165] printf_ulong::uvalue#2 = rom_read::rom_file_size#11 -- vduz1=vdum2 
    lda rom_file_size
    sta.z printf_ulong.uvalue
    lda rom_file_size+1
    sta.z printf_ulong.uvalue+1
    lda rom_file_size+2
    sta.z printf_ulong.uvalue+2
    lda rom_file_size+3
    sta.z printf_ulong.uvalue+3
    // [1166] call printf_ulong
    // [1276] phi from rom_read::@27 to printf_ulong [phi:rom_read::@27->printf_ulong]
    // [1276] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_read::@27->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1276] phi printf_ulong::format_min_length#11 = 5 [phi:rom_read::@27->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1276] phi printf_ulong::putc#11 = &snputc [phi:rom_read::@27->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1276] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_read::@27->printf_ulong#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1276] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#2 [phi:rom_read::@27->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1167] phi from rom_read::@27 to rom_read::@28 [phi:rom_read::@27->rom_read::@28]
    // rom_read::@28
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1168] call printf_str
    // [877] phi from rom_read::@28 to printf_str [phi:rom_read::@28->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:rom_read::@28->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = s4 [phi:rom_read::@28->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@29
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1169] printf_ulong::uvalue#3 = rom_read::rom_size#12 -- vduz1=vduz2 
    lda.z rom_size
    sta.z printf_ulong.uvalue
    lda.z rom_size+1
    sta.z printf_ulong.uvalue+1
    lda.z rom_size+2
    sta.z printf_ulong.uvalue+2
    lda.z rom_size+3
    sta.z printf_ulong.uvalue+3
    // [1170] call printf_ulong
    // [1276] phi from rom_read::@29 to printf_ulong [phi:rom_read::@29->printf_ulong]
    // [1276] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_read::@29->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1276] phi printf_ulong::format_min_length#11 = 5 [phi:rom_read::@29->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1276] phi printf_ulong::putc#11 = &snputc [phi:rom_read::@29->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1276] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_read::@29->printf_ulong#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1276] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#3 [phi:rom_read::@29->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1171] phi from rom_read::@29 to rom_read::@30 [phi:rom_read::@29->rom_read::@30]
    // rom_read::@30
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1172] call printf_str
    // [877] phi from rom_read::@30 to printf_str [phi:rom_read::@30->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:rom_read::@30->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = s2 [phi:rom_read::@30->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@31
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1173] printf_uchar::uvalue#5 = rom_read::bram_bank#10 -- vbuz1=vbuz2 
    lda.z bram_bank
    sta.z printf_uchar.uvalue
    // [1174] call printf_uchar
    // [1040] phi from rom_read::@31 to printf_uchar [phi:rom_read::@31->printf_uchar]
    // [1040] phi printf_uchar::format_zero_padding#10 = 1 [phi:rom_read::@31->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1040] phi printf_uchar::format_min_length#10 = 2 [phi:rom_read::@31->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [1040] phi printf_uchar::putc#10 = &snputc [phi:rom_read::@31->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1040] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:rom_read::@31->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [1040] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#5 [phi:rom_read::@31->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1175] phi from rom_read::@31 to rom_read::@32 [phi:rom_read::@31->rom_read::@32]
    // rom_read::@32
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1176] call printf_str
    // [877] phi from rom_read::@32 to printf_str [phi:rom_read::@32->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:rom_read::@32->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = s3 [phi:rom_read::@32->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@33
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1177] printf_uint::uvalue#13 = (unsigned int)rom_read::ram_address#10 -- vwuz1=vwuz2 
    lda.z ram_address
    sta.z printf_uint.uvalue
    lda.z ram_address+1
    sta.z printf_uint.uvalue+1
    // [1178] call printf_uint
    // [911] phi from rom_read::@33 to printf_uint [phi:rom_read::@33->printf_uint]
    // [911] phi printf_uint::format_zero_padding#19 = 1 [phi:rom_read::@33->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [911] phi printf_uint::format_min_length#19 = 4 [phi:rom_read::@33->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [911] phi printf_uint::putc#19 = &snputc [phi:rom_read::@33->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [911] phi printf_uint::format_radix#19 = HEXADECIMAL [phi:rom_read::@33->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [911] phi printf_uint::uvalue#19 = printf_uint::uvalue#13 [phi:rom_read::@33->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1179] phi from rom_read::@33 to rom_read::@34 [phi:rom_read::@33->rom_read::@34]
    // rom_read::@34
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1180] call printf_str
    // [877] phi from rom_read::@34 to printf_str [phi:rom_read::@34->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:rom_read::@34->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = s7 [phi:rom_read::@34->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@35
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1181] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1182] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1184] call display_action_text
    // [1051] phi from rom_read::@35 to display_action_text [phi:rom_read::@35->display_action_text]
    // [1051] phi display_action_text::info_text#19 = info_text [phi:rom_read::@35->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // rom_read::@36
    // rom_address % 0x04000
    // [1185] rom_read::$11 = rom_read::rom_address#10 & $4000-1 -- vduz1=vduz2_band_vduc1 
    lda.z rom_address
    and #<$4000-1
    sta.z rom_read__11
    lda.z rom_address+1
    and #>$4000-1
    sta.z rom_read__11+1
    lda.z rom_address+2
    and #<$4000-1>>$10
    sta.z rom_read__11+2
    lda.z rom_address+3
    and #>$4000-1>>$10
    sta.z rom_read__11+3
    // if (!(rom_address % 0x04000))
    // [1186] if(0!=rom_read::$11) goto rom_read::@5 -- 0_neq_vduz1_then_la1 
    lda.z rom_read__11
    ora.z rom_read__11+1
    ora.z rom_read__11+2
    ora.z rom_read__11+3
    bne __b5
    // rom_read::@11
    // brom_bank_start++;
    // [1187] rom_read::brom_bank_start#0 = ++ rom_read::brom_bank_start#10 -- vbum1=_inc_vbum1 
    inc brom_bank_start
    // [1188] phi from rom_read::@11 rom_read::@36 to rom_read::@5 [phi:rom_read::@11/rom_read::@36->rom_read::@5]
    // [1188] phi rom_read::brom_bank_start#20 = rom_read::brom_bank_start#0 [phi:rom_read::@11/rom_read::@36->rom_read::@5#0] -- register_copy 
    // rom_read::@5
  __b5:
    // rom_read::bank_set_bram2
    // BRAM = bank
    // [1189] BRAM = rom_read::bram_bank#10 -- vbuz1=vbuz2 
    lda.z bram_bank
    sta.z BRAM
    // rom_read::@16
    // unsigned int rom_package_read = fgets(ram_address, ROM_PROGRESS_CELL, fp)
    // [1190] fgets::ptr#3 = rom_read::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z fgets.ptr
    lda.z ram_address+1
    sta.z fgets.ptr+1
    // [1191] fgets::stream#1 = rom_read::fp#0 -- pssm1=pssm2 
    lda fp
    sta fgets.stream
    lda fp+1
    sta fgets.stream+1
    // [1192] call fgets
    // [2122] phi from rom_read::@16 to fgets [phi:rom_read::@16->fgets]
    // [2122] phi fgets::ptr#12 = fgets::ptr#3 [phi:rom_read::@16->fgets#0] -- register_copy 
    // [2122] phi fgets::size#10 = ROM_PROGRESS_CELL [phi:rom_read::@16->fgets#1] -- vwuz1=vwuc1 
    lda #<ROM_PROGRESS_CELL
    sta.z fgets.size
    lda #>ROM_PROGRESS_CELL
    sta.z fgets.size+1
    // [2122] phi fgets::stream#2 = fgets::stream#1 [phi:rom_read::@16->fgets#2] -- register_copy 
    jsr fgets
    // unsigned int rom_package_read = fgets(ram_address, ROM_PROGRESS_CELL, fp)
    // [1193] fgets::return#6 = fgets::return#1
    // rom_read::@37
    // [1194] rom_read::rom_package_read#0 = fgets::return#6 -- vwuz1=vwuz2 
    lda.z fgets.return
    sta.z rom_package_read
    lda.z fgets.return+1
    sta.z rom_package_read+1
    // if (!rom_package_read)
    // [1195] if(0!=rom_read::rom_package_read#0) goto rom_read::@6 -- 0_neq_vwuz1_then_la1 
    lda.z rom_package_read
    ora.z rom_package_read+1
    bne __b6
    jmp __b7
    // rom_read::@6
  __b6:
    // if (rom_row_current == ROM_PROGRESS_ROW)
    // [1196] if(rom_read::rom_row_current#10!=ROM_PROGRESS_ROW) goto rom_read::@8 -- vwuz1_neq_vwuc1_then_la1 
    lda.z rom_row_current+1
    cmp #>ROM_PROGRESS_ROW
    bne __b8
    lda.z rom_row_current
    cmp #<ROM_PROGRESS_ROW
    bne __b8
    // rom_read::@12
    // gotoxy(x, ++y);
    // [1197] rom_read::y#1 = ++ rom_read::y#11 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [1198] gotoxy::y#25 = rom_read::y#1 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1199] call gotoxy
    // [610] phi from rom_read::@12 to gotoxy [phi:rom_read::@12->gotoxy]
    // [610] phi gotoxy::y#30 = gotoxy::y#25 [phi:rom_read::@12->gotoxy#0] -- register_copy 
    // [610] phi gotoxy::x#30 = PROGRESS_X [phi:rom_read::@12->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [1200] phi from rom_read::@12 to rom_read::@8 [phi:rom_read::@12->rom_read::@8]
    // [1200] phi rom_read::y#36 = rom_read::y#1 [phi:rom_read::@12->rom_read::@8#0] -- register_copy 
    // [1200] phi rom_read::rom_row_current#4 = 0 [phi:rom_read::@12->rom_read::@8#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z rom_row_current
    sta.z rom_row_current+1
    // [1200] phi from rom_read::@6 to rom_read::@8 [phi:rom_read::@6->rom_read::@8]
    // [1200] phi rom_read::y#36 = rom_read::y#11 [phi:rom_read::@6->rom_read::@8#0] -- register_copy 
    // [1200] phi rom_read::rom_row_current#4 = rom_read::rom_row_current#10 [phi:rom_read::@6->rom_read::@8#1] -- register_copy 
    // rom_read::@8
  __b8:
    // if(display_progress)
    // [1201] if(0==rom_read::display_progress#28) goto rom_read::@9 -- 0_eq_vbuz1_then_la1 
    lda.z display_progress
    beq __b9
    // rom_read::@13
    // cputc('.')
    // [1202] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [1203] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // rom_read::@9
  __b9:
    // ram_address += rom_package_read
    // [1205] rom_read::ram_address#1 = rom_read::ram_address#10 + rom_read::rom_package_read#0 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z ram_address
    adc.z rom_package_read
    sta.z ram_address
    lda.z ram_address+1
    adc.z rom_package_read+1
    sta.z ram_address+1
    // rom_address += rom_package_read
    // [1206] rom_read::rom_address#1 = rom_read::rom_address#10 + rom_read::rom_package_read#0 -- vduz1=vduz1_plus_vwuz2 
    lda.z rom_address
    clc
    adc.z rom_package_read
    sta.z rom_address
    lda.z rom_address+1
    adc.z rom_package_read+1
    sta.z rom_address+1
    lda.z rom_address+2
    adc #0
    sta.z rom_address+2
    lda.z rom_address+3
    adc #0
    sta.z rom_address+3
    // rom_file_size += rom_package_read
    // [1207] rom_read::rom_file_size#1 = rom_read::rom_file_size#11 + rom_read::rom_package_read#0 -- vdum1=vdum1_plus_vwuz2 
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
    // rom_row_current += rom_package_read
    // [1208] rom_read::rom_row_current#2 = rom_read::rom_row_current#4 + rom_read::rom_package_read#0 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z rom_row_current
    adc.z rom_package_read
    sta.z rom_row_current
    lda.z rom_row_current+1
    adc.z rom_package_read+1
    sta.z rom_row_current+1
    // if (ram_address == (ram_ptr_t)BRAM_HIGH)
    // [1209] if(rom_read::ram_address#1!=(char *)$c000) goto rom_read::@10 -- pbuz1_neq_pbuc1_then_la1 
    lda.z ram_address+1
    cmp #>$c000
    bne __b10
    lda.z ram_address
    cmp #<$c000
    bne __b10
    // rom_read::@14
    // bram_bank++;
    // [1210] rom_read::bram_bank#1 = ++ rom_read::bram_bank#10 -- vbuz1=_inc_vbuz1 
    inc.z bram_bank
    // [1211] phi from rom_read::@14 to rom_read::@10 [phi:rom_read::@14->rom_read::@10]
    // [1211] phi rom_read::bram_bank#31 = rom_read::bram_bank#1 [phi:rom_read::@14->rom_read::@10#0] -- register_copy 
    // [1211] phi rom_read::ram_address#7 = (char *)$a000 [phi:rom_read::@14->rom_read::@10#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1211] phi from rom_read::@9 to rom_read::@10 [phi:rom_read::@9->rom_read::@10]
    // [1211] phi rom_read::bram_bank#31 = rom_read::bram_bank#10 [phi:rom_read::@9->rom_read::@10#0] -- register_copy 
    // [1211] phi rom_read::ram_address#7 = rom_read::ram_address#1 [phi:rom_read::@9->rom_read::@10#1] -- register_copy 
    // rom_read::@10
  __b10:
    // if (ram_address == (ram_ptr_t)RAM_HIGH)
    // [1212] if(rom_read::ram_address#7!=(char *)$9800) goto rom_read::@38 -- pbuz1_neq_pbuc1_then_la1 
    lda.z ram_address+1
    cmp #>$9800
    beq !__b3+
    jmp __b3
  !__b3:
    lda.z ram_address
    cmp #<$9800
    beq !__b3+
    jmp __b3
  !__b3:
    // [1151] phi from rom_read::@10 to rom_read::@3 [phi:rom_read::@10->rom_read::@3]
    // [1151] phi rom_read::y#11 = rom_read::y#36 [phi:rom_read::@10->rom_read::@3#0] -- register_copy 
    // [1151] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#2 [phi:rom_read::@10->rom_read::@3#1] -- register_copy 
    // [1151] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#20 [phi:rom_read::@10->rom_read::@3#2] -- register_copy 
    // [1151] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@10->rom_read::@3#3] -- register_copy 
    // [1151] phi rom_read::ram_address#10 = (char *)$a000 [phi:rom_read::@10->rom_read::@3#4] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1151] phi rom_read::bram_bank#10 = 1 [phi:rom_read::@10->rom_read::@3#5] -- vbuz1=vbuc1 
    lda #1
    sta.z bram_bank
    // [1151] phi rom_read::rom_file_size#11 = rom_read::rom_file_size#1 [phi:rom_read::@10->rom_read::@3#6] -- register_copy 
    jmp __b3
    // [1213] phi from rom_read::@10 to rom_read::@38 [phi:rom_read::@10->rom_read::@38]
    // rom_read::@38
    // [1151] phi from rom_read::@38 to rom_read::@3 [phi:rom_read::@38->rom_read::@3]
    // [1151] phi rom_read::y#11 = rom_read::y#36 [phi:rom_read::@38->rom_read::@3#0] -- register_copy 
    // [1151] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#2 [phi:rom_read::@38->rom_read::@3#1] -- register_copy 
    // [1151] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#20 [phi:rom_read::@38->rom_read::@3#2] -- register_copy 
    // [1151] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@38->rom_read::@3#3] -- register_copy 
    // [1151] phi rom_read::ram_address#10 = rom_read::ram_address#7 [phi:rom_read::@38->rom_read::@3#4] -- register_copy 
    // [1151] phi rom_read::bram_bank#10 = rom_read::bram_bank#31 [phi:rom_read::@38->rom_read::@3#5] -- register_copy 
    // [1151] phi rom_read::rom_file_size#11 = rom_read::rom_file_size#1 [phi:rom_read::@38->rom_read::@3#6] -- register_copy 
  .segment Data
    s: .text "Opening "
    .byte 0
    s1: .text " from SD card ..."
    .byte 0
    .label fp = rom_read_byte.rom_bank1_rom_read_byte__2
    return: .dword 0
    .label brom_bank_start = main.check_status_smc10_main__0
    .label rom_file_size = return
}
.segment Code
  // rom_verify
// __zp($b6) unsigned long rom_verify(__mem() char rom_chip, __zp($ed) char rom_bank_start, __mem() unsigned long file_size)
rom_verify: {
    .label rom_verify__16 = $51
    .label rom_address = $a9
    .label equal_bytes = $51
    .label y = $5b
    .label ram_address = $5e
    .label bram_bank = $54
    .label rom_different_bytes = $b6
    .label rom_bank_start = $ed
    .label return = $b6
    .label progress_row_current = $d5
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [1214] rom_address_from_bank::rom_bank#1 = rom_verify::rom_bank_start#0
    // [1215] call rom_address_from_bank
    // [2232] phi from rom_verify to rom_address_from_bank [phi:rom_verify->rom_address_from_bank]
    // [2232] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#1 [phi:rom_verify->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [1216] rom_address_from_bank::return#3 = rom_address_from_bank::return#0 -- vduz1=vduz2 
    lda.z rom_address_from_bank.return
    sta.z rom_address_from_bank.return_1
    lda.z rom_address_from_bank.return+1
    sta.z rom_address_from_bank.return_1+1
    lda.z rom_address_from_bank.return+2
    sta.z rom_address_from_bank.return_1+2
    lda.z rom_address_from_bank.return+3
    sta.z rom_address_from_bank.return_1+3
    // rom_verify::@11
    // [1217] rom_verify::rom_address#0 = rom_address_from_bank::return#3
    // unsigned long rom_boundary = rom_address + file_size
    // [1218] rom_verify::rom_boundary#0 = rom_verify::rom_address#0 + rom_verify::file_size#0 -- vdum1=vduz2_plus_vdum1 
    clc
    lda rom_boundary
    adc.z rom_address
    sta rom_boundary
    lda rom_boundary+1
    adc.z rom_address+1
    sta rom_boundary+1
    lda rom_boundary+2
    adc.z rom_address+2
    sta rom_boundary+2
    lda rom_boundary+3
    adc.z rom_address+3
    sta rom_boundary+3
    // display_info_rom(rom_chip, STATUS_COMPARING, "Comparing ...")
    // [1219] display_info_rom::rom_chip#1 = rom_verify::rom_chip#0
    // [1220] call display_info_rom
    // [1074] phi from rom_verify::@11 to display_info_rom [phi:rom_verify::@11->display_info_rom]
    // [1074] phi display_info_rom::info_text#17 = rom_verify::info_text [phi:rom_verify::@11->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_rom.info_text
    lda #>info_text
    sta.z display_info_rom.info_text+1
    // [1074] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#1 [phi:rom_verify::@11->display_info_rom#1] -- register_copy 
    // [1074] phi display_info_rom::info_status#17 = STATUS_COMPARING [phi:rom_verify::@11->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_COMPARING
    sta display_info_rom.info_status
    jsr display_info_rom
    // [1221] phi from rom_verify::@11 to rom_verify::@12 [phi:rom_verify::@11->rom_verify::@12]
    // rom_verify::@12
    // gotoxy(x, y)
    // [1222] call gotoxy
    // [610] phi from rom_verify::@12 to gotoxy [phi:rom_verify::@12->gotoxy]
    // [610] phi gotoxy::y#30 = PROGRESS_Y [phi:rom_verify::@12->gotoxy#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z gotoxy.y
    // [610] phi gotoxy::x#30 = PROGRESS_X [phi:rom_verify::@12->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [1223] phi from rom_verify::@12 to rom_verify::@1 [phi:rom_verify::@12->rom_verify::@1]
    // [1223] phi rom_verify::y#3 = PROGRESS_Y [phi:rom_verify::@12->rom_verify::@1#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // [1223] phi rom_verify::progress_row_current#3 = 0 [phi:rom_verify::@12->rom_verify::@1#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z progress_row_current
    sta.z progress_row_current+1
    // [1223] phi rom_verify::rom_different_bytes#11 = 0 [phi:rom_verify::@12->rom_verify::@1#2] -- vduz1=vduc1 
    sta.z rom_different_bytes
    sta.z rom_different_bytes+1
    lda #<0>>$10
    sta.z rom_different_bytes+2
    lda #>0>>$10
    sta.z rom_different_bytes+3
    // [1223] phi rom_verify::ram_address#10 = (char *)$7800 [phi:rom_verify::@12->rom_verify::@1#3] -- pbuz1=pbuc1 
    lda #<$7800
    sta.z ram_address
    lda #>$7800
    sta.z ram_address+1
    // [1223] phi rom_verify::bram_bank#11 = 0 [phi:rom_verify::@12->rom_verify::@1#4] -- vbuz1=vbuc1 
    lda #0
    sta.z bram_bank
    // [1223] phi rom_verify::rom_address#12 = rom_verify::rom_address#0 [phi:rom_verify::@12->rom_verify::@1#5] -- register_copy 
    // rom_verify::@1
  __b1:
    // while (rom_address < rom_boundary)
    // [1224] if(rom_verify::rom_address#12<rom_verify::rom_boundary#0) goto rom_verify::@2 -- vduz1_lt_vdum2_then_la1 
    lda.z rom_address+3
    cmp rom_boundary+3
    bcc __b2
    bne !+
    lda.z rom_address+2
    cmp rom_boundary+2
    bcc __b2
    bne !+
    lda.z rom_address+1
    cmp rom_boundary+1
    bcc __b2
    bne !+
    lda.z rom_address
    cmp rom_boundary
    bcc __b2
  !:
    // rom_verify::@return
    // }
    // [1225] return 
    rts
    // rom_verify::@2
  __b2:
    // unsigned int equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1226] rom_compare::bank_ram#0 = rom_verify::bram_bank#11 -- vbuz1=vbuz2 
    lda.z bram_bank
    sta.z rom_compare.bank_ram
    // [1227] rom_compare::ptr_ram#1 = rom_verify::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_compare.ptr_ram
    lda.z ram_address+1
    sta.z rom_compare.ptr_ram+1
    // [1228] rom_compare::rom_compare_address#0 = rom_verify::rom_address#12 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_compare.rom_compare_address
    lda.z rom_address+1
    sta.z rom_compare.rom_compare_address+1
    lda.z rom_address+2
    sta.z rom_compare.rom_compare_address+2
    lda.z rom_address+3
    sta.z rom_compare.rom_compare_address+3
    // [1229] call rom_compare
  // {asm{.byte $db}}
    // [2236] phi from rom_verify::@2 to rom_compare [phi:rom_verify::@2->rom_compare]
    // [2236] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#1 [phi:rom_verify::@2->rom_compare#0] -- register_copy 
    // [2236] phi rom_compare::rom_compare_size#11 = ROM_PROGRESS_CELL [phi:rom_verify::@2->rom_compare#1] -- vwuz1=vwuc1 
    lda #<ROM_PROGRESS_CELL
    sta.z rom_compare.rom_compare_size
    lda #>ROM_PROGRESS_CELL
    sta.z rom_compare.rom_compare_size+1
    // [2236] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#0 [phi:rom_verify::@2->rom_compare#2] -- register_copy 
    // [2236] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#0 [phi:rom_verify::@2->rom_compare#3] -- register_copy 
    jsr rom_compare
    // unsigned int equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1230] rom_compare::return#2 = rom_compare::equal_bytes#2
    // rom_verify::@13
    // [1231] rom_verify::equal_bytes#0 = rom_compare::return#2
    // if (progress_row_current == ROM_PROGRESS_ROW)
    // [1232] if(rom_verify::progress_row_current#3!=ROM_PROGRESS_ROW) goto rom_verify::@3 -- vwuz1_neq_vwuc1_then_la1 
    lda.z progress_row_current+1
    cmp #>ROM_PROGRESS_ROW
    bne __b3
    lda.z progress_row_current
    cmp #<ROM_PROGRESS_ROW
    bne __b3
    // rom_verify::@8
    // gotoxy(x, ++y);
    // [1233] rom_verify::y#1 = ++ rom_verify::y#3 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [1234] gotoxy::y#27 = rom_verify::y#1 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1235] call gotoxy
    // [610] phi from rom_verify::@8 to gotoxy [phi:rom_verify::@8->gotoxy]
    // [610] phi gotoxy::y#30 = gotoxy::y#27 [phi:rom_verify::@8->gotoxy#0] -- register_copy 
    // [610] phi gotoxy::x#30 = PROGRESS_X [phi:rom_verify::@8->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [1236] phi from rom_verify::@8 to rom_verify::@3 [phi:rom_verify::@8->rom_verify::@3]
    // [1236] phi rom_verify::y#10 = rom_verify::y#1 [phi:rom_verify::@8->rom_verify::@3#0] -- register_copy 
    // [1236] phi rom_verify::progress_row_current#4 = 0 [phi:rom_verify::@8->rom_verify::@3#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z progress_row_current
    sta.z progress_row_current+1
    // [1236] phi from rom_verify::@13 to rom_verify::@3 [phi:rom_verify::@13->rom_verify::@3]
    // [1236] phi rom_verify::y#10 = rom_verify::y#3 [phi:rom_verify::@13->rom_verify::@3#0] -- register_copy 
    // [1236] phi rom_verify::progress_row_current#4 = rom_verify::progress_row_current#3 [phi:rom_verify::@13->rom_verify::@3#1] -- register_copy 
    // rom_verify::@3
  __b3:
    // if (equal_bytes != ROM_PROGRESS_CELL)
    // [1237] if(rom_verify::equal_bytes#0!=ROM_PROGRESS_CELL) goto rom_verify::@4 -- vwuz1_neq_vwuc1_then_la1 
    lda.z equal_bytes+1
    cmp #>ROM_PROGRESS_CELL
    beq !__b4+
    jmp __b4
  !__b4:
    lda.z equal_bytes
    cmp #<ROM_PROGRESS_CELL
    beq !__b4+
    jmp __b4
  !__b4:
    // rom_verify::@9
    // cputc('=')
    // [1238] stackpush(char) = '=' -- _stackpushbyte_=vbuc1 
    lda #'='
    pha
    // [1239] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // rom_verify::@5
  __b5:
    // ram_address += ROM_PROGRESS_CELL
    // [1241] rom_verify::ram_address#1 = rom_verify::ram_address#10 + ROM_PROGRESS_CELL -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address
    clc
    adc #<ROM_PROGRESS_CELL
    sta.z ram_address
    lda.z ram_address+1
    adc #>ROM_PROGRESS_CELL
    sta.z ram_address+1
    // rom_address += ROM_PROGRESS_CELL
    // [1242] rom_verify::rom_address#1 = rom_verify::rom_address#12 + ROM_PROGRESS_CELL -- vduz1=vduz1_plus_vwuc1 
    clc
    lda.z rom_address
    adc #<ROM_PROGRESS_CELL
    sta.z rom_address
    lda.z rom_address+1
    adc #>ROM_PROGRESS_CELL
    sta.z rom_address+1
    lda.z rom_address+2
    adc #0
    sta.z rom_address+2
    lda.z rom_address+3
    adc #0
    sta.z rom_address+3
    // progress_row_current += ROM_PROGRESS_CELL
    // [1243] rom_verify::progress_row_current#11 = rom_verify::progress_row_current#4 + ROM_PROGRESS_CELL -- vwuz1=vwuz1_plus_vwuc1 
    lda.z progress_row_current
    clc
    adc #<ROM_PROGRESS_CELL
    sta.z progress_row_current
    lda.z progress_row_current+1
    adc #>ROM_PROGRESS_CELL
    sta.z progress_row_current+1
    // if (ram_address == BRAM_HIGH)
    // [1244] if(rom_verify::ram_address#1!=$c000) goto rom_verify::@6 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address+1
    cmp #>$c000
    bne __b6
    lda.z ram_address
    cmp #<$c000
    bne __b6
    // rom_verify::@10
    // bram_bank++;
    // [1245] rom_verify::bram_bank#1 = ++ rom_verify::bram_bank#11 -- vbuz1=_inc_vbuz1 
    inc.z bram_bank
    // [1246] phi from rom_verify::@10 to rom_verify::@6 [phi:rom_verify::@10->rom_verify::@6]
    // [1246] phi rom_verify::bram_bank#24 = rom_verify::bram_bank#1 [phi:rom_verify::@10->rom_verify::@6#0] -- register_copy 
    // [1246] phi rom_verify::ram_address#6 = (char *)$a000 [phi:rom_verify::@10->rom_verify::@6#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1246] phi from rom_verify::@5 to rom_verify::@6 [phi:rom_verify::@5->rom_verify::@6]
    // [1246] phi rom_verify::bram_bank#24 = rom_verify::bram_bank#11 [phi:rom_verify::@5->rom_verify::@6#0] -- register_copy 
    // [1246] phi rom_verify::ram_address#6 = rom_verify::ram_address#1 [phi:rom_verify::@5->rom_verify::@6#1] -- register_copy 
    // rom_verify::@6
  __b6:
    // if (ram_address == RAM_HIGH)
    // [1247] if(rom_verify::ram_address#6!=$9800) goto rom_verify::@23 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address+1
    cmp #>$9800
    bne __b7
    lda.z ram_address
    cmp #<$9800
    bne __b7
    // [1249] phi from rom_verify::@6 to rom_verify::@7 [phi:rom_verify::@6->rom_verify::@7]
    // [1249] phi rom_verify::ram_address#11 = (char *)$a000 [phi:rom_verify::@6->rom_verify::@7#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1249] phi rom_verify::bram_bank#10 = 1 [phi:rom_verify::@6->rom_verify::@7#1] -- vbuz1=vbuc1 
    lda #1
    sta.z bram_bank
    // [1248] phi from rom_verify::@6 to rom_verify::@23 [phi:rom_verify::@6->rom_verify::@23]
    // rom_verify::@23
    // [1249] phi from rom_verify::@23 to rom_verify::@7 [phi:rom_verify::@23->rom_verify::@7]
    // [1249] phi rom_verify::ram_address#11 = rom_verify::ram_address#6 [phi:rom_verify::@23->rom_verify::@7#0] -- register_copy 
    // [1249] phi rom_verify::bram_bank#10 = rom_verify::bram_bank#24 [phi:rom_verify::@23->rom_verify::@7#1] -- register_copy 
    // rom_verify::@7
  __b7:
    // ROM_PROGRESS_CELL - equal_bytes
    // [1250] rom_verify::$16 = ROM_PROGRESS_CELL - rom_verify::equal_bytes#0 -- vwuz1=vwuc1_minus_vwuz1 
    lda #<ROM_PROGRESS_CELL
    sec
    sbc.z rom_verify__16
    sta.z rom_verify__16
    lda #>ROM_PROGRESS_CELL
    sbc.z rom_verify__16+1
    sta.z rom_verify__16+1
    // rom_different_bytes += (ROM_PROGRESS_CELL - equal_bytes)
    // [1251] rom_verify::rom_different_bytes#1 = rom_verify::rom_different_bytes#11 + rom_verify::$16 -- vduz1=vduz1_plus_vwuz2 
    lda.z rom_different_bytes
    clc
    adc.z rom_verify__16
    sta.z rom_different_bytes
    lda.z rom_different_bytes+1
    adc.z rom_verify__16+1
    sta.z rom_different_bytes+1
    lda.z rom_different_bytes+2
    adc #0
    sta.z rom_different_bytes+2
    lda.z rom_different_bytes+3
    adc #0
    sta.z rom_different_bytes+3
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1252] call snprintf_init
    // [872] phi from rom_verify::@7 to snprintf_init [phi:rom_verify::@7->snprintf_init]
    // [872] phi snprintf_init::s#25 = info_text [phi:rom_verify::@7->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1253] phi from rom_verify::@7 to rom_verify::@14 [phi:rom_verify::@7->rom_verify::@14]
    // rom_verify::@14
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1254] call printf_str
    // [877] phi from rom_verify::@14 to printf_str [phi:rom_verify::@14->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:rom_verify::@14->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = rom_verify::s [phi:rom_verify::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@15
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1255] printf_ulong::uvalue#4 = rom_verify::rom_different_bytes#1 -- vduz1=vduz2 
    lda.z rom_different_bytes
    sta.z printf_ulong.uvalue
    lda.z rom_different_bytes+1
    sta.z printf_ulong.uvalue+1
    lda.z rom_different_bytes+2
    sta.z printf_ulong.uvalue+2
    lda.z rom_different_bytes+3
    sta.z printf_ulong.uvalue+3
    // [1256] call printf_ulong
    // [1276] phi from rom_verify::@15 to printf_ulong [phi:rom_verify::@15->printf_ulong]
    // [1276] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_verify::@15->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1276] phi printf_ulong::format_min_length#11 = 5 [phi:rom_verify::@15->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1276] phi printf_ulong::putc#11 = &snputc [phi:rom_verify::@15->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1276] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_verify::@15->printf_ulong#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1276] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#4 [phi:rom_verify::@15->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1257] phi from rom_verify::@15 to rom_verify::@16 [phi:rom_verify::@15->rom_verify::@16]
    // rom_verify::@16
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1258] call printf_str
    // [877] phi from rom_verify::@16 to printf_str [phi:rom_verify::@16->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:rom_verify::@16->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = rom_verify::s1 [phi:rom_verify::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@17
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1259] printf_uchar::uvalue#6 = rom_verify::bram_bank#10 -- vbuz1=vbuz2 
    lda.z bram_bank
    sta.z printf_uchar.uvalue
    // [1260] call printf_uchar
    // [1040] phi from rom_verify::@17 to printf_uchar [phi:rom_verify::@17->printf_uchar]
    // [1040] phi printf_uchar::format_zero_padding#10 = 1 [phi:rom_verify::@17->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1040] phi printf_uchar::format_min_length#10 = 2 [phi:rom_verify::@17->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [1040] phi printf_uchar::putc#10 = &snputc [phi:rom_verify::@17->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1040] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:rom_verify::@17->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [1040] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#6 [phi:rom_verify::@17->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1261] phi from rom_verify::@17 to rom_verify::@18 [phi:rom_verify::@17->rom_verify::@18]
    // rom_verify::@18
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1262] call printf_str
    // [877] phi from rom_verify::@18 to printf_str [phi:rom_verify::@18->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:rom_verify::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = s3 [phi:rom_verify::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s3
    sta.z printf_str.s
    lda #>@s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@19
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1263] printf_uint::uvalue#14 = (unsigned int)rom_verify::ram_address#11 -- vwuz1=vwuz2 
    lda.z ram_address
    sta.z printf_uint.uvalue
    lda.z ram_address+1
    sta.z printf_uint.uvalue+1
    // [1264] call printf_uint
    // [911] phi from rom_verify::@19 to printf_uint [phi:rom_verify::@19->printf_uint]
    // [911] phi printf_uint::format_zero_padding#19 = 1 [phi:rom_verify::@19->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [911] phi printf_uint::format_min_length#19 = 4 [phi:rom_verify::@19->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [911] phi printf_uint::putc#19 = &snputc [phi:rom_verify::@19->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [911] phi printf_uint::format_radix#19 = HEXADECIMAL [phi:rom_verify::@19->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [911] phi printf_uint::uvalue#19 = printf_uint::uvalue#14 [phi:rom_verify::@19->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1265] phi from rom_verify::@19 to rom_verify::@20 [phi:rom_verify::@19->rom_verify::@20]
    // rom_verify::@20
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1266] call printf_str
    // [877] phi from rom_verify::@20 to printf_str [phi:rom_verify::@20->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:rom_verify::@20->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = rom_verify::s3 [phi:rom_verify::@20->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@21
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1267] printf_ulong::uvalue#5 = rom_verify::rom_address#1 -- vduz1=vduz2 
    lda.z rom_address
    sta.z printf_ulong.uvalue
    lda.z rom_address+1
    sta.z printf_ulong.uvalue+1
    lda.z rom_address+2
    sta.z printf_ulong.uvalue+2
    lda.z rom_address+3
    sta.z printf_ulong.uvalue+3
    // [1268] call printf_ulong
    // [1276] phi from rom_verify::@21 to printf_ulong [phi:rom_verify::@21->printf_ulong]
    // [1276] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_verify::@21->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1276] phi printf_ulong::format_min_length#11 = 5 [phi:rom_verify::@21->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1276] phi printf_ulong::putc#11 = &snputc [phi:rom_verify::@21->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1276] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_verify::@21->printf_ulong#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1276] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#5 [phi:rom_verify::@21->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // rom_verify::@22
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1269] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1270] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1272] call display_action_text
    // [1051] phi from rom_verify::@22 to display_action_text [phi:rom_verify::@22->display_action_text]
    // [1051] phi display_action_text::info_text#19 = info_text [phi:rom_verify::@22->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1223] phi from rom_verify::@22 to rom_verify::@1 [phi:rom_verify::@22->rom_verify::@1]
    // [1223] phi rom_verify::y#3 = rom_verify::y#10 [phi:rom_verify::@22->rom_verify::@1#0] -- register_copy 
    // [1223] phi rom_verify::progress_row_current#3 = rom_verify::progress_row_current#11 [phi:rom_verify::@22->rom_verify::@1#1] -- register_copy 
    // [1223] phi rom_verify::rom_different_bytes#11 = rom_verify::rom_different_bytes#1 [phi:rom_verify::@22->rom_verify::@1#2] -- register_copy 
    // [1223] phi rom_verify::ram_address#10 = rom_verify::ram_address#11 [phi:rom_verify::@22->rom_verify::@1#3] -- register_copy 
    // [1223] phi rom_verify::bram_bank#11 = rom_verify::bram_bank#10 [phi:rom_verify::@22->rom_verify::@1#4] -- register_copy 
    // [1223] phi rom_verify::rom_address#12 = rom_verify::rom_address#1 [phi:rom_verify::@22->rom_verify::@1#5] -- register_copy 
    jmp __b1
    // rom_verify::@4
  __b4:
    // cputc('*')
    // [1273] stackpush(char) = '*' -- _stackpushbyte_=vbuc1 
    lda #'*'
    pha
    // [1274] callexecute cputc  -- call_vprc1 
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
    .label rom_boundary = rom_flash.rom_flash__29
    .label rom_chip = main.check_status_vera3_main__0
    .label file_size = rom_flash.rom_flash__29
}
.segment Code
  // printf_ulong
// Print an unsigned int using a specific format
// void printf_ulong(__zp($4d) void (*putc)(char), __zp($30) unsigned long uvalue, __zp($e7) char format_min_length, char format_justify_left, char format_sign_always, __zp($e6) char format_zero_padding, char format_upper_case, __zp($e5) char format_radix)
printf_ulong: {
    .label uvalue = $30
    .label format_radix = $e5
    .label putc = $4d
    .label format_min_length = $e7
    .label format_zero_padding = $e6
    // printf_ulong::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1277] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // ultoa(uvalue, printf_buffer.digits, format.radix)
    // [1278] ultoa::value#1 = printf_ulong::uvalue#11
    // [1279] ultoa::radix#0 = printf_ulong::format_radix#11
    // [1280] call ultoa
    // Format number into buffer
    jsr ultoa
    // printf_ulong::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1281] printf_number_buffer::putc#0 = printf_ulong::putc#11
    // [1282] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [1283] printf_number_buffer::format_min_length#0 = printf_ulong::format_min_length#11
    // [1284] printf_number_buffer::format_zero_padding#0 = printf_ulong::format_zero_padding#11
    // [1285] call printf_number_buffer
  // Print using format
    // [1988] phi from printf_ulong::@2 to printf_number_buffer [phi:printf_ulong::@2->printf_number_buffer]
    // [1988] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#0 [phi:printf_ulong::@2->printf_number_buffer#0] -- register_copy 
    // [1988] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_ulong::@2->printf_number_buffer#1] -- register_copy 
    // [1988] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#0 [phi:printf_ulong::@2->printf_number_buffer#2] -- register_copy 
    // [1988] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#0 [phi:printf_ulong::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_ulong::@return
    // }
    // [1286] return 
    rts
  .segment Data
    uvalue_1: .dword 0
}
.segment Code
  // rom_flash
// __mem() unsigned long rom_flash(__mem() char rom_chip, __zp($ed) char rom_bank_start, __mem() unsigned long file_size)
rom_flash: {
    .label equal_bytes = $51
    .label ram_address_sector = $db
    .label flash_errors_sector = $ef
    .label ram_address = $d7
    .label rom_address = $f5
    .label x = $ee
    .label rom_bank_start = $ed
    // display_action_progress("Flashing ... (-) equal, (+) flashed, (!) error.")
    // [1288] call display_action_progress
  // Now we compare the RAM with the actual ROM contents.
    // [704] phi from rom_flash to display_action_progress [phi:rom_flash->display_action_progress]
    // [704] phi display_action_progress::info_text#15 = rom_flash::info_text [phi:rom_flash->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // rom_flash::@19
    // unsigned long rom_address_sector = rom_address_from_bank(rom_bank_start)
    // [1289] rom_address_from_bank::rom_bank#2 = rom_flash::rom_bank_start#0
    // [1290] call rom_address_from_bank
    // [2232] phi from rom_flash::@19 to rom_address_from_bank [phi:rom_flash::@19->rom_address_from_bank]
    // [2232] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#2 [phi:rom_flash::@19->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address_sector = rom_address_from_bank(rom_bank_start)
    // [1291] rom_address_from_bank::return#4 = rom_address_from_bank::return#0 -- vdum1=vduz2 
    lda.z rom_address_from_bank.return
    sta rom_address_from_bank.return_2
    lda.z rom_address_from_bank.return+1
    sta rom_address_from_bank.return_2+1
    lda.z rom_address_from_bank.return+2
    sta rom_address_from_bank.return_2+2
    lda.z rom_address_from_bank.return+3
    sta rom_address_from_bank.return_2+3
    // rom_flash::@20
    // [1292] rom_flash::rom_address_sector#0 = rom_address_from_bank::return#4
    // unsigned long rom_boundary = rom_address_sector + file_size
    // [1293] rom_flash::rom_boundary#0 = rom_flash::rom_address_sector#0 + rom_flash::file_size#0 -- vdum1=vdum2_plus_vdum3 
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
    // [1294] display_info_rom::rom_chip#2 = rom_flash::rom_chip#0 -- vbum1=vbum2 
    lda rom_chip
    sta display_info_rom.rom_chip
    // [1295] call display_info_rom
    // [1074] phi from rom_flash::@20 to display_info_rom [phi:rom_flash::@20->display_info_rom]
    // [1074] phi display_info_rom::info_text#17 = rom_flash::info_text1 [phi:rom_flash::@20->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_rom.info_text
    lda #>info_text1
    sta.z display_info_rom.info_text+1
    // [1074] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#2 [phi:rom_flash::@20->display_info_rom#1] -- register_copy 
    // [1074] phi display_info_rom::info_status#17 = STATUS_FLASHING [phi:rom_flash::@20->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHING
    sta display_info_rom.info_status
    jsr display_info_rom
    // [1296] phi from rom_flash::@20 to rom_flash::@1 [phi:rom_flash::@20->rom_flash::@1]
    // [1296] phi rom_flash::y_sector#13 = PROGRESS_Y [phi:rom_flash::@20->rom_flash::@1#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y_sector
    // [1296] phi rom_flash::x_sector#10 = PROGRESS_X [phi:rom_flash::@20->rom_flash::@1#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [1296] phi rom_flash::flash_errors#10 = 0 [phi:rom_flash::@20->rom_flash::@1#2] -- vdum1=vduc1 
    lda #<0
    sta flash_errors
    sta flash_errors+1
    lda #<0>>$10
    sta flash_errors+2
    lda #>0>>$10
    sta flash_errors+3
    // [1296] phi rom_flash::ram_address_sector#11 = (char *)$7800 [phi:rom_flash::@20->rom_flash::@1#3] -- pbuz1=pbuc1 
    lda #<$7800
    sta.z ram_address_sector
    lda #>$7800
    sta.z ram_address_sector+1
    // [1296] phi rom_flash::bram_bank_sector#14 = 0 [phi:rom_flash::@20->rom_flash::@1#4] -- vbum1=vbuc1 
    lda #0
    sta bram_bank_sector
    // [1296] phi rom_flash::rom_address_sector#12 = rom_flash::rom_address_sector#0 [phi:rom_flash::@20->rom_flash::@1#5] -- register_copy 
    // rom_flash::@1
  __b1:
    // while (rom_address_sector < rom_boundary)
    // [1297] if(rom_flash::rom_address_sector#12<rom_flash::rom_boundary#0) goto rom_flash::@2 -- vdum1_lt_vdum2_then_la1 
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
    // [1298] phi from rom_flash::@1 to rom_flash::@3 [phi:rom_flash::@1->rom_flash::@3]
    // rom_flash::@3
    // display_action_text("Flashed ...")
    // [1299] call display_action_text
    // [1051] phi from rom_flash::@3 to display_action_text [phi:rom_flash::@3->display_action_text]
    // [1051] phi display_action_text::info_text#19 = rom_flash::info_text2 [phi:rom_flash::@3->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z display_action_text.info_text
    lda #>info_text2
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // rom_flash::@return
    // }
    // [1300] return 
    rts
    // rom_flash::@2
  __b2:
    // unsigned int equal_bytes = rom_compare(bram_bank_sector, (ram_ptr_t)ram_address_sector, rom_address_sector, ROM_SECTOR)
    // [1301] rom_compare::bank_ram#1 = rom_flash::bram_bank_sector#14 -- vbuz1=vbum2 
    lda bram_bank_sector
    sta.z rom_compare.bank_ram
    // [1302] rom_compare::ptr_ram#2 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z rom_compare.ptr_ram
    lda.z ram_address_sector+1
    sta.z rom_compare.ptr_ram+1
    // [1303] rom_compare::rom_compare_address#1 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_compare.rom_compare_address
    lda rom_address_sector+1
    sta.z rom_compare.rom_compare_address+1
    lda rom_address_sector+2
    sta.z rom_compare.rom_compare_address+2
    lda rom_address_sector+3
    sta.z rom_compare.rom_compare_address+3
    // [1304] call rom_compare
  // {asm{.byte $db}}
    // [2236] phi from rom_flash::@2 to rom_compare [phi:rom_flash::@2->rom_compare]
    // [2236] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#2 [phi:rom_flash::@2->rom_compare#0] -- register_copy 
    // [2236] phi rom_compare::rom_compare_size#11 = $1000 [phi:rom_flash::@2->rom_compare#1] -- vwuz1=vwuc1 
    lda #<$1000
    sta.z rom_compare.rom_compare_size
    lda #>$1000
    sta.z rom_compare.rom_compare_size+1
    // [2236] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#1 [phi:rom_flash::@2->rom_compare#2] -- register_copy 
    // [2236] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#1 [phi:rom_flash::@2->rom_compare#3] -- register_copy 
    jsr rom_compare
    // unsigned int equal_bytes = rom_compare(bram_bank_sector, (ram_ptr_t)ram_address_sector, rom_address_sector, ROM_SECTOR)
    // [1305] rom_compare::return#3 = rom_compare::equal_bytes#2
    // rom_flash::@21
    // [1306] rom_flash::equal_bytes#0 = rom_compare::return#3
    // if (equal_bytes != ROM_SECTOR)
    // [1307] if(rom_flash::equal_bytes#0!=$1000) goto rom_flash::@5 -- vwuz1_neq_vwuc1_then_la1 
    lda.z equal_bytes+1
    cmp #>$1000
    beq !__b3+
    jmp __b3
  !__b3:
    lda.z equal_bytes
    cmp #<$1000
    beq !__b3+
    jmp __b3
  !__b3:
    // rom_flash::@16
    // cputsxy(x_sector, y_sector, "--------")
    // [1308] cputsxy::x#1 = rom_flash::x_sector#10 -- vbuz1=vbum2 
    lda x_sector
    sta.z cputsxy.x
    // [1309] cputsxy::y#1 = rom_flash::y_sector#13 -- vbum1=vbum2 
    lda y_sector
    sta cputsxy.y
    // [1310] call cputsxy
    // [697] phi from rom_flash::@16 to cputsxy [phi:rom_flash::@16->cputsxy]
    // [697] phi cputsxy::s#4 = rom_flash::s [phi:rom_flash::@16->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z cputsxy.s
    lda #>s
    sta.z cputsxy.s+1
    // [697] phi cputsxy::y#4 = cputsxy::y#1 [phi:rom_flash::@16->cputsxy#1] -- register_copy 
    // [697] phi cputsxy::x#4 = cputsxy::x#1 [phi:rom_flash::@16->cputsxy#2] -- register_copy 
    jsr cputsxy
    // [1311] phi from rom_flash::@12 rom_flash::@16 to rom_flash::@4 [phi:rom_flash::@12/rom_flash::@16->rom_flash::@4]
    // [1311] phi rom_flash::flash_errors#13 = rom_flash::flash_errors#1 [phi:rom_flash::@12/rom_flash::@16->rom_flash::@4#0] -- register_copy 
    // rom_flash::@4
  __b4:
    // ram_address_sector += ROM_SECTOR
    // [1312] rom_flash::ram_address_sector#1 = rom_flash::ram_address_sector#11 + $1000 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address_sector
    clc
    adc #<$1000
    sta.z ram_address_sector
    lda.z ram_address_sector+1
    adc #>$1000
    sta.z ram_address_sector+1
    // rom_address_sector += ROM_SECTOR
    // [1313] rom_flash::rom_address_sector#1 = rom_flash::rom_address_sector#12 + $1000 -- vdum1=vdum1_plus_vwuc1 
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
    // [1314] if(rom_flash::ram_address_sector#1!=$c000) goto rom_flash::@13 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address_sector+1
    cmp #>$c000
    bne __b13
    lda.z ram_address_sector
    cmp #<$c000
    bne __b13
    // rom_flash::@17
    // bram_bank_sector++;
    // [1315] rom_flash::bram_bank_sector#1 = ++ rom_flash::bram_bank_sector#14 -- vbum1=_inc_vbum1 
    inc bram_bank_sector
    // [1316] phi from rom_flash::@17 to rom_flash::@13 [phi:rom_flash::@17->rom_flash::@13]
    // [1316] phi rom_flash::bram_bank_sector#38 = rom_flash::bram_bank_sector#1 [phi:rom_flash::@17->rom_flash::@13#0] -- register_copy 
    // [1316] phi rom_flash::ram_address_sector#8 = (char *)$a000 [phi:rom_flash::@17->rom_flash::@13#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address_sector
    lda #>$a000
    sta.z ram_address_sector+1
    // [1316] phi from rom_flash::@4 to rom_flash::@13 [phi:rom_flash::@4->rom_flash::@13]
    // [1316] phi rom_flash::bram_bank_sector#38 = rom_flash::bram_bank_sector#14 [phi:rom_flash::@4->rom_flash::@13#0] -- register_copy 
    // [1316] phi rom_flash::ram_address_sector#8 = rom_flash::ram_address_sector#1 [phi:rom_flash::@4->rom_flash::@13#1] -- register_copy 
    // rom_flash::@13
  __b13:
    // if (ram_address_sector == RAM_HIGH)
    // [1317] if(rom_flash::ram_address_sector#8!=$9800) goto rom_flash::@44 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address_sector+1
    cmp #>$9800
    bne __b14
    lda.z ram_address_sector
    cmp #<$9800
    bne __b14
    // [1319] phi from rom_flash::@13 to rom_flash::@14 [phi:rom_flash::@13->rom_flash::@14]
    // [1319] phi rom_flash::ram_address_sector#15 = (char *)$a000 [phi:rom_flash::@13->rom_flash::@14#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address_sector
    lda #>$a000
    sta.z ram_address_sector+1
    // [1319] phi rom_flash::bram_bank_sector#12 = 1 [phi:rom_flash::@13->rom_flash::@14#1] -- vbum1=vbuc1 
    lda #1
    sta bram_bank_sector
    // [1318] phi from rom_flash::@13 to rom_flash::@44 [phi:rom_flash::@13->rom_flash::@44]
    // rom_flash::@44
    // [1319] phi from rom_flash::@44 to rom_flash::@14 [phi:rom_flash::@44->rom_flash::@14]
    // [1319] phi rom_flash::ram_address_sector#15 = rom_flash::ram_address_sector#8 [phi:rom_flash::@44->rom_flash::@14#0] -- register_copy 
    // [1319] phi rom_flash::bram_bank_sector#12 = rom_flash::bram_bank_sector#38 [phi:rom_flash::@44->rom_flash::@14#1] -- register_copy 
    // rom_flash::@14
  __b14:
    // x_sector += 8
    // [1320] rom_flash::x_sector#1 = rom_flash::x_sector#10 + 8 -- vbum1=vbum1_plus_vbuc1 
    lda #8
    clc
    adc x_sector
    sta x_sector
    // rom_address_sector % ROM_PROGRESS_ROW
    // [1321] rom_flash::$29 = rom_flash::rom_address_sector#1 & ROM_PROGRESS_ROW-1 -- vdum1=vdum2_band_vduc1 
    lda rom_address_sector
    and #<ROM_PROGRESS_ROW-1
    sta rom_flash__29
    lda rom_address_sector+1
    and #>ROM_PROGRESS_ROW-1
    sta rom_flash__29+1
    lda rom_address_sector+2
    and #<ROM_PROGRESS_ROW-1>>$10
    sta rom_flash__29+2
    lda rom_address_sector+3
    and #>ROM_PROGRESS_ROW-1>>$10
    sta rom_flash__29+3
    // if (!(rom_address_sector % ROM_PROGRESS_ROW))
    // [1322] if(0!=rom_flash::$29) goto rom_flash::@15 -- 0_neq_vdum1_then_la1 
    lda rom_flash__29
    ora rom_flash__29+1
    ora rom_flash__29+2
    ora rom_flash__29+3
    bne __b15
    // rom_flash::@18
    // y_sector++;
    // [1323] rom_flash::y_sector#1 = ++ rom_flash::y_sector#13 -- vbum1=_inc_vbum1 
    inc y_sector
    // [1324] phi from rom_flash::@18 to rom_flash::@15 [phi:rom_flash::@18->rom_flash::@15]
    // [1324] phi rom_flash::y_sector#18 = rom_flash::y_sector#1 [phi:rom_flash::@18->rom_flash::@15#0] -- register_copy 
    // [1324] phi rom_flash::x_sector#20 = PROGRESS_X [phi:rom_flash::@18->rom_flash::@15#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [1324] phi from rom_flash::@14 to rom_flash::@15 [phi:rom_flash::@14->rom_flash::@15]
    // [1324] phi rom_flash::y_sector#18 = rom_flash::y_sector#13 [phi:rom_flash::@14->rom_flash::@15#0] -- register_copy 
    // [1324] phi rom_flash::x_sector#20 = rom_flash::x_sector#1 [phi:rom_flash::@14->rom_flash::@15#1] -- register_copy 
    // rom_flash::@15
  __b15:
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1325] call snprintf_init
    // [872] phi from rom_flash::@15 to snprintf_init [phi:rom_flash::@15->snprintf_init]
    // [872] phi snprintf_init::s#25 = info_text [phi:rom_flash::@15->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // rom_flash::@40
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1326] printf_ulong::uvalue#8 = rom_flash::flash_errors#13 -- vduz1=vdum2 
    lda flash_errors
    sta.z printf_ulong.uvalue
    lda flash_errors+1
    sta.z printf_ulong.uvalue+1
    lda flash_errors+2
    sta.z printf_ulong.uvalue+2
    lda flash_errors+3
    sta.z printf_ulong.uvalue+3
    // [1327] call printf_ulong
    // [1276] phi from rom_flash::@40 to printf_ulong [phi:rom_flash::@40->printf_ulong]
    // [1276] phi printf_ulong::format_zero_padding#11 = 0 [phi:rom_flash::@40->printf_ulong#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_ulong.format_zero_padding
    // [1276] phi printf_ulong::format_min_length#11 = 0 [phi:rom_flash::@40->printf_ulong#1] -- vbuz1=vbuc1 
    sta.z printf_ulong.format_min_length
    // [1276] phi printf_ulong::putc#11 = &snputc [phi:rom_flash::@40->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1276] phi printf_ulong::format_radix#11 = DECIMAL [phi:rom_flash::@40->printf_ulong#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_ulong.format_radix
    // [1276] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#8 [phi:rom_flash::@40->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1328] phi from rom_flash::@40 to rom_flash::@41 [phi:rom_flash::@40->rom_flash::@41]
    // rom_flash::@41
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1329] call printf_str
    // [877] phi from rom_flash::@41 to printf_str [phi:rom_flash::@41->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:rom_flash::@41->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = rom_flash::s6 [phi:rom_flash::@41->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@42
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1330] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1331] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_FLASHING, info_text)
    // [1333] display_info_rom::rom_chip#3 = rom_flash::rom_chip#0 -- vbum1=vbum2 
    lda rom_chip
    sta display_info_rom.rom_chip
    // [1334] call display_info_rom
    // [1074] phi from rom_flash::@42 to display_info_rom [phi:rom_flash::@42->display_info_rom]
    // [1074] phi display_info_rom::info_text#17 = info_text [phi:rom_flash::@42->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1074] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#3 [phi:rom_flash::@42->display_info_rom#1] -- register_copy 
    // [1074] phi display_info_rom::info_status#17 = STATUS_FLASHING [phi:rom_flash::@42->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHING
    sta display_info_rom.info_status
    jsr display_info_rom
    // [1296] phi from rom_flash::@42 to rom_flash::@1 [phi:rom_flash::@42->rom_flash::@1]
    // [1296] phi rom_flash::y_sector#13 = rom_flash::y_sector#18 [phi:rom_flash::@42->rom_flash::@1#0] -- register_copy 
    // [1296] phi rom_flash::x_sector#10 = rom_flash::x_sector#20 [phi:rom_flash::@42->rom_flash::@1#1] -- register_copy 
    // [1296] phi rom_flash::flash_errors#10 = rom_flash::flash_errors#13 [phi:rom_flash::@42->rom_flash::@1#2] -- register_copy 
    // [1296] phi rom_flash::ram_address_sector#11 = rom_flash::ram_address_sector#15 [phi:rom_flash::@42->rom_flash::@1#3] -- register_copy 
    // [1296] phi rom_flash::bram_bank_sector#14 = rom_flash::bram_bank_sector#12 [phi:rom_flash::@42->rom_flash::@1#4] -- register_copy 
    // [1296] phi rom_flash::rom_address_sector#12 = rom_flash::rom_address_sector#1 [phi:rom_flash::@42->rom_flash::@1#5] -- register_copy 
    jmp __b1
    // [1335] phi from rom_flash::@21 to rom_flash::@5 [phi:rom_flash::@21->rom_flash::@5]
  __b3:
    // [1335] phi rom_flash::retries#12 = 0 [phi:rom_flash::@21->rom_flash::@5#0] -- vbum1=vbuc1 
    lda #0
    sta retries
    // [1335] phi rom_flash::flash_errors_sector#11 = 0 [phi:rom_flash::@21->rom_flash::@5#1] -- vwuz1=vwuc1 
    sta.z flash_errors_sector
    sta.z flash_errors_sector+1
    // [1335] phi from rom_flash::@43 to rom_flash::@5 [phi:rom_flash::@43->rom_flash::@5]
    // [1335] phi rom_flash::retries#12 = rom_flash::retries#1 [phi:rom_flash::@43->rom_flash::@5#0] -- register_copy 
    // [1335] phi rom_flash::flash_errors_sector#11 = rom_flash::flash_errors_sector#10 [phi:rom_flash::@43->rom_flash::@5#1] -- register_copy 
    // rom_flash::@5
  __b5:
    // rom_sector_erase(rom_address_sector)
    // [1336] rom_sector_erase::address#0 = rom_flash::rom_address_sector#12 -- vdum1=vdum2 
    lda rom_address_sector
    sta rom_sector_erase.address
    lda rom_address_sector+1
    sta rom_sector_erase.address+1
    lda rom_address_sector+2
    sta rom_sector_erase.address+2
    lda rom_address_sector+3
    sta rom_sector_erase.address+3
    // [1337] call rom_sector_erase
    // [2292] phi from rom_flash::@5 to rom_sector_erase [phi:rom_flash::@5->rom_sector_erase]
    jsr rom_sector_erase
    // rom_flash::@22
    // unsigned long rom_sector_boundary = rom_address_sector + ROM_SECTOR
    // [1338] rom_flash::rom_sector_boundary#0 = rom_flash::rom_address_sector#12 + $1000 -- vdum1=vdum2_plus_vwuc1 
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
    // [1339] gotoxy::x#28 = rom_flash::x_sector#10 -- vbuz1=vbum2 
    lda x_sector
    sta.z gotoxy.x
    // [1340] gotoxy::y#28 = rom_flash::y_sector#13 -- vbuz1=vbum2 
    lda y_sector
    sta.z gotoxy.y
    // [1341] call gotoxy
    // [610] phi from rom_flash::@22 to gotoxy [phi:rom_flash::@22->gotoxy]
    // [610] phi gotoxy::y#30 = gotoxy::y#28 [phi:rom_flash::@22->gotoxy#0] -- register_copy 
    // [610] phi gotoxy::x#30 = gotoxy::x#28 [phi:rom_flash::@22->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1342] phi from rom_flash::@22 to rom_flash::@23 [phi:rom_flash::@22->rom_flash::@23]
    // rom_flash::@23
    // printf("........")
    // [1343] call printf_str
    // [877] phi from rom_flash::@23 to printf_str [phi:rom_flash::@23->printf_str]
    // [877] phi printf_str::putc#73 = &cputc [phi:rom_flash::@23->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = rom_flash::s1 [phi:rom_flash::@23->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@24
    // [1344] rom_flash::rom_address#26 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_address
    lda rom_address_sector+1
    sta.z rom_address+1
    lda rom_address_sector+2
    sta.z rom_address+2
    lda rom_address_sector+3
    sta.z rom_address+3
    // [1345] rom_flash::ram_address#26 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z ram_address
    lda.z ram_address_sector+1
    sta.z ram_address+1
    // [1346] rom_flash::x#26 = rom_flash::x_sector#10 -- vbuz1=vbum2 
    lda x_sector
    sta.z x
    // [1347] phi from rom_flash::@10 rom_flash::@24 to rom_flash::@6 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6]
    // [1347] phi rom_flash::x#10 = rom_flash::x#1 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#0] -- register_copy 
    // [1347] phi rom_flash::ram_address#10 = rom_flash::ram_address#1 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#1] -- register_copy 
    // [1347] phi rom_flash::flash_errors_sector#10 = rom_flash::flash_errors_sector#8 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#2] -- register_copy 
    // [1347] phi rom_flash::rom_address#11 = rom_flash::rom_address#1 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#3] -- register_copy 
    // rom_flash::@6
  __b6:
    // while (rom_address < rom_sector_boundary)
    // [1348] if(rom_flash::rom_address#11<rom_flash::rom_sector_boundary#0) goto rom_flash::@7 -- vduz1_lt_vdum2_then_la1 
    lda.z rom_address+3
    cmp rom_sector_boundary+3
    bcc __b7
    bne !+
    lda.z rom_address+2
    cmp rom_sector_boundary+2
    bcc __b7
    bne !+
    lda.z rom_address+1
    cmp rom_sector_boundary+1
    bcc __b7
    bne !+
    lda.z rom_address
    cmp rom_sector_boundary
    bcc __b7
  !:
    // rom_flash::@8
    // retries++;
    // [1349] rom_flash::retries#1 = ++ rom_flash::retries#12 -- vbum1=_inc_vbum1 
    inc retries
    // while (flash_errors_sector && retries <= 3)
    // [1350] if(0==rom_flash::flash_errors_sector#10) goto rom_flash::@12 -- 0_eq_vwuz1_then_la1 
    lda.z flash_errors_sector
    ora.z flash_errors_sector+1
    beq __b12
    // rom_flash::@43
    // [1351] if(rom_flash::retries#1<3+1) goto rom_flash::@5 -- vbum1_lt_vbuc1_then_la1 
    lda retries
    cmp #3+1
    bcs !__b5+
    jmp __b5
  !__b5:
    // rom_flash::@12
  __b12:
    // flash_errors += flash_errors_sector
    // [1352] rom_flash::flash_errors#1 = rom_flash::flash_errors#10 + rom_flash::flash_errors_sector#10 -- vdum1=vdum1_plus_vwuz2 
    lda flash_errors
    clc
    adc.z flash_errors_sector
    sta flash_errors
    lda flash_errors+1
    adc.z flash_errors_sector+1
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
    // [1353] printf_ulong::uvalue#7 = rom_flash::flash_errors_sector#10 + rom_flash::flash_errors#10 -- vdum1=vwuz2_plus_vdum3 
    lda flash_errors
    clc
    adc.z flash_errors_sector
    sta printf_ulong.uvalue_1
    lda flash_errors+1
    adc.z flash_errors_sector+1
    sta printf_ulong.uvalue_1+1
    lda flash_errors+2
    adc #0
    sta printf_ulong.uvalue_1+2
    lda flash_errors+3
    adc #0
    sta printf_ulong.uvalue_1+3
    // [1354] call snprintf_init
    // [872] phi from rom_flash::@7 to snprintf_init [phi:rom_flash::@7->snprintf_init]
    // [872] phi snprintf_init::s#25 = info_text [phi:rom_flash::@7->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1355] phi from rom_flash::@7 to rom_flash::@25 [phi:rom_flash::@7->rom_flash::@25]
    // rom_flash::@25
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1356] call printf_str
    // [877] phi from rom_flash::@25 to printf_str [phi:rom_flash::@25->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:rom_flash::@25->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = rom_flash::s2 [phi:rom_flash::@25->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@26
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1357] printf_uchar::uvalue#7 = rom_flash::bram_bank_sector#14 -- vbuz1=vbum2 
    lda bram_bank_sector
    sta.z printf_uchar.uvalue
    // [1358] call printf_uchar
    // [1040] phi from rom_flash::@26 to printf_uchar [phi:rom_flash::@26->printf_uchar]
    // [1040] phi printf_uchar::format_zero_padding#10 = 1 [phi:rom_flash::@26->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1040] phi printf_uchar::format_min_length#10 = 2 [phi:rom_flash::@26->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [1040] phi printf_uchar::putc#10 = &snputc [phi:rom_flash::@26->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1040] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:rom_flash::@26->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [1040] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#7 [phi:rom_flash::@26->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1359] phi from rom_flash::@26 to rom_flash::@27 [phi:rom_flash::@26->rom_flash::@27]
    // rom_flash::@27
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1360] call printf_str
    // [877] phi from rom_flash::@27 to printf_str [phi:rom_flash::@27->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:rom_flash::@27->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = s3 [phi:rom_flash::@27->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@28
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1361] printf_uint::uvalue#15 = (unsigned int)rom_flash::ram_address_sector#11 -- vwuz1=vwuz2 
    lda.z ram_address_sector
    sta.z printf_uint.uvalue
    lda.z ram_address_sector+1
    sta.z printf_uint.uvalue+1
    // [1362] call printf_uint
    // [911] phi from rom_flash::@28 to printf_uint [phi:rom_flash::@28->printf_uint]
    // [911] phi printf_uint::format_zero_padding#19 = 1 [phi:rom_flash::@28->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [911] phi printf_uint::format_min_length#19 = 4 [phi:rom_flash::@28->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [911] phi printf_uint::putc#19 = &snputc [phi:rom_flash::@28->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [911] phi printf_uint::format_radix#19 = HEXADECIMAL [phi:rom_flash::@28->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [911] phi printf_uint::uvalue#19 = printf_uint::uvalue#15 [phi:rom_flash::@28->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1363] phi from rom_flash::@28 to rom_flash::@29 [phi:rom_flash::@28->rom_flash::@29]
    // rom_flash::@29
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1364] call printf_str
    // [877] phi from rom_flash::@29 to printf_str [phi:rom_flash::@29->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:rom_flash::@29->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = rom_flash::s4 [phi:rom_flash::@29->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@30
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1365] printf_ulong::uvalue#6 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z printf_ulong.uvalue
    lda rom_address_sector+1
    sta.z printf_ulong.uvalue+1
    lda rom_address_sector+2
    sta.z printf_ulong.uvalue+2
    lda rom_address_sector+3
    sta.z printf_ulong.uvalue+3
    // [1366] call printf_ulong
    // [1276] phi from rom_flash::@30 to printf_ulong [phi:rom_flash::@30->printf_ulong]
    // [1276] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_flash::@30->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1276] phi printf_ulong::format_min_length#11 = 5 [phi:rom_flash::@30->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1276] phi printf_ulong::putc#11 = &snputc [phi:rom_flash::@30->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1276] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_flash::@30->printf_ulong#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1276] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#6 [phi:rom_flash::@30->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1367] phi from rom_flash::@30 to rom_flash::@31 [phi:rom_flash::@30->rom_flash::@31]
    // rom_flash::@31
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1368] call printf_str
    // [877] phi from rom_flash::@31 to printf_str [phi:rom_flash::@31->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:rom_flash::@31->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = rom_flash::s5 [phi:rom_flash::@31->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@32
    // [1369] printf_ulong::uvalue#20 = printf_ulong::uvalue#7 -- vduz1=vdum2 
    lda printf_ulong.uvalue_1
    sta.z printf_ulong.uvalue
    lda printf_ulong.uvalue_1+1
    sta.z printf_ulong.uvalue+1
    lda printf_ulong.uvalue_1+2
    sta.z printf_ulong.uvalue+2
    lda printf_ulong.uvalue_1+3
    sta.z printf_ulong.uvalue+3
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1370] call printf_ulong
    // [1276] phi from rom_flash::@32 to printf_ulong [phi:rom_flash::@32->printf_ulong]
    // [1276] phi printf_ulong::format_zero_padding#11 = 0 [phi:rom_flash::@32->printf_ulong#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_ulong.format_zero_padding
    // [1276] phi printf_ulong::format_min_length#11 = 0 [phi:rom_flash::@32->printf_ulong#1] -- vbuz1=vbuc1 
    sta.z printf_ulong.format_min_length
    // [1276] phi printf_ulong::putc#11 = &snputc [phi:rom_flash::@32->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1276] phi printf_ulong::format_radix#11 = DECIMAL [phi:rom_flash::@32->printf_ulong#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_ulong.format_radix
    // [1276] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#20 [phi:rom_flash::@32->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1371] phi from rom_flash::@32 to rom_flash::@33 [phi:rom_flash::@32->rom_flash::@33]
    // rom_flash::@33
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1372] call printf_str
    // [877] phi from rom_flash::@33 to printf_str [phi:rom_flash::@33->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:rom_flash::@33->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = rom_flash::s6 [phi:rom_flash::@33->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@34
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1373] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1374] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1376] call display_action_text
    // [1051] phi from rom_flash::@34 to display_action_text [phi:rom_flash::@34->display_action_text]
    // [1051] phi display_action_text::info_text#19 = info_text [phi:rom_flash::@34->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // rom_flash::@35
    // unsigned long written_bytes = rom_write(bram_bank, (ram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1377] rom_write::flash_ram_bank#0 = rom_flash::bram_bank_sector#14 -- vbuz1=vbum2 
    lda bram_bank_sector
    sta.z rom_write.flash_ram_bank
    // [1378] rom_write::flash_ram_address#1 = rom_flash::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_write.flash_ram_address
    lda.z ram_address+1
    sta.z rom_write.flash_ram_address+1
    // [1379] rom_write::flash_rom_address#1 = rom_flash::rom_address#11 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_write.flash_rom_address
    lda.z rom_address+1
    sta.z rom_write.flash_rom_address+1
    lda.z rom_address+2
    sta.z rom_write.flash_rom_address+2
    lda.z rom_address+3
    sta.z rom_write.flash_rom_address+3
    // [1380] call rom_write
    jsr rom_write
    // rom_flash::@36
    // rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1381] rom_compare::bank_ram#2 = rom_flash::bram_bank_sector#14 -- vbuz1=vbum2 
    lda bram_bank_sector
    sta.z rom_compare.bank_ram
    // [1382] rom_compare::ptr_ram#3 = rom_flash::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_compare.ptr_ram
    lda.z ram_address+1
    sta.z rom_compare.ptr_ram+1
    // [1383] rom_compare::rom_compare_address#2 = rom_flash::rom_address#11 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_compare.rom_compare_address
    lda.z rom_address+1
    sta.z rom_compare.rom_compare_address+1
    lda.z rom_address+2
    sta.z rom_compare.rom_compare_address+2
    lda.z rom_address+3
    sta.z rom_compare.rom_compare_address+3
    // [1384] call rom_compare
    // [2236] phi from rom_flash::@36 to rom_compare [phi:rom_flash::@36->rom_compare]
    // [2236] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#3 [phi:rom_flash::@36->rom_compare#0] -- register_copy 
    // [2236] phi rom_compare::rom_compare_size#11 = ROM_PROGRESS_CELL [phi:rom_flash::@36->rom_compare#1] -- vwuz1=vwuc1 
    lda #<ROM_PROGRESS_CELL
    sta.z rom_compare.rom_compare_size
    lda #>ROM_PROGRESS_CELL
    sta.z rom_compare.rom_compare_size+1
    // [2236] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#2 [phi:rom_flash::@36->rom_compare#2] -- register_copy 
    // [2236] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#2 [phi:rom_flash::@36->rom_compare#3] -- register_copy 
    jsr rom_compare
    // rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1385] rom_compare::return#4 = rom_compare::equal_bytes#2
    // rom_flash::@37
    // equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1386] rom_flash::equal_bytes#1 = rom_compare::return#4 -- vwum1=vwuz2 
    lda.z rom_compare.return
    sta equal_bytes_1
    lda.z rom_compare.return+1
    sta equal_bytes_1+1
    // gotoxy(x, y)
    // [1387] gotoxy::x#29 = rom_flash::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1388] gotoxy::y#29 = rom_flash::y_sector#13 -- vbuz1=vbum2 
    lda y_sector
    sta.z gotoxy.y
    // [1389] call gotoxy
    // [610] phi from rom_flash::@37 to gotoxy [phi:rom_flash::@37->gotoxy]
    // [610] phi gotoxy::y#30 = gotoxy::y#29 [phi:rom_flash::@37->gotoxy#0] -- register_copy 
    // [610] phi gotoxy::x#30 = gotoxy::x#29 [phi:rom_flash::@37->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_flash::@38
    // if (equal_bytes != ROM_PROGRESS_CELL)
    // [1390] if(rom_flash::equal_bytes#1!=ROM_PROGRESS_CELL) goto rom_flash::@9 -- vwum1_neq_vwuc1_then_la1 
    lda equal_bytes_1+1
    cmp #>ROM_PROGRESS_CELL
    bne __b9
    lda equal_bytes_1
    cmp #<ROM_PROGRESS_CELL
    bne __b9
    // rom_flash::@11
    // cputcxy(x,y,'+')
    // [1391] cputcxy::x#14 = rom_flash::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1392] cputcxy::y#14 = rom_flash::y_sector#13 -- vbuz1=vbum2 
    lda y_sector
    sta.z cputcxy.y
    // [1393] call cputcxy
    // [1840] phi from rom_flash::@11 to cputcxy [phi:rom_flash::@11->cputcxy]
    // [1840] phi cputcxy::c#15 = '+' [phi:rom_flash::@11->cputcxy#0] -- vbuz1=vbuc1 
    lda #'+'
    sta.z cputcxy.c
    // [1840] phi cputcxy::y#15 = cputcxy::y#14 [phi:rom_flash::@11->cputcxy#1] -- register_copy 
    // [1840] phi cputcxy::x#15 = cputcxy::x#14 [phi:rom_flash::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [1394] phi from rom_flash::@11 rom_flash::@39 to rom_flash::@10 [phi:rom_flash::@11/rom_flash::@39->rom_flash::@10]
    // [1394] phi rom_flash::flash_errors_sector#8 = rom_flash::flash_errors_sector#10 [phi:rom_flash::@11/rom_flash::@39->rom_flash::@10#0] -- register_copy 
    // rom_flash::@10
  __b10:
    // ram_address += ROM_PROGRESS_CELL
    // [1395] rom_flash::ram_address#1 = rom_flash::ram_address#10 + ROM_PROGRESS_CELL -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address
    clc
    adc #<ROM_PROGRESS_CELL
    sta.z ram_address
    lda.z ram_address+1
    adc #>ROM_PROGRESS_CELL
    sta.z ram_address+1
    // rom_address += ROM_PROGRESS_CELL
    // [1396] rom_flash::rom_address#1 = rom_flash::rom_address#11 + ROM_PROGRESS_CELL -- vduz1=vduz1_plus_vwuc1 
    clc
    lda.z rom_address
    adc #<ROM_PROGRESS_CELL
    sta.z rom_address
    lda.z rom_address+1
    adc #>ROM_PROGRESS_CELL
    sta.z rom_address+1
    lda.z rom_address+2
    adc #0
    sta.z rom_address+2
    lda.z rom_address+3
    adc #0
    sta.z rom_address+3
    // x++;
    // [1397] rom_flash::x#1 = ++ rom_flash::x#10 -- vbuz1=_inc_vbuz1 
    inc.z x
    jmp __b6
    // rom_flash::@9
  __b9:
    // cputcxy(x,y,'!')
    // [1398] cputcxy::x#13 = rom_flash::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1399] cputcxy::y#13 = rom_flash::y_sector#13 -- vbuz1=vbum2 
    lda y_sector
    sta.z cputcxy.y
    // [1400] call cputcxy
    // [1840] phi from rom_flash::@9 to cputcxy [phi:rom_flash::@9->cputcxy]
    // [1840] phi cputcxy::c#15 = '!' [phi:rom_flash::@9->cputcxy#0] -- vbuz1=vbuc1 
    lda #'!'
    sta.z cputcxy.c
    // [1840] phi cputcxy::y#15 = cputcxy::y#13 [phi:rom_flash::@9->cputcxy#1] -- register_copy 
    // [1840] phi cputcxy::x#15 = cputcxy::x#13 [phi:rom_flash::@9->cputcxy#2] -- register_copy 
    jsr cputcxy
    // rom_flash::@39
    // flash_errors_sector++;
    // [1401] rom_flash::flash_errors_sector#1 = ++ rom_flash::flash_errors_sector#10 -- vwuz1=_inc_vwuz1 
    inc.z flash_errors_sector
    bne !+
    inc.z flash_errors_sector+1
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
    rom_flash__29: .dword 0
    .label rom_address_sector = main.flashed_bytes
    rom_boundary: .dword 0
    rom_sector_boundary: .dword 0
    equal_bytes_1: .word 0
    .label retries = display_frame_maskxy.return
    .label flash_errors = main.rom_file_modulo
    .label bram_bank_sector = display_frame_maskxy.cpeekcxy1_y
    .label x_sector = fopen.num
    .label y_sector = fclose.sp
    .label rom_chip = main.check_status_card_roms1_check_status_rom1_main__0
    .label file_size = main.rom_flash_errors
    .label return = main.rom_file_modulo
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
    .label cx16_k_i2c_write_byte1_return = $2d
    .label smc_bootloader_start = $2d
    .label smc_bootloader_not_activated1 = $b1
    // Waiting a bit to ensure the bootloader is activated.
    .label smc_bootloader_activation_countdown = $eb
    // Waiting a bit to ensure the bootloader is activated.
    .label smc_bootloader_activation_countdown_1 = $b5
    .label smc_ram_ptr = $d3
    .label smc_package_flashed = $71
    .label smc_commit_result = $b1
    .label smc_attempts_flashed = $6f
    .label smc_row_bytes = $cc
    .label smc_attempts_total = $c2
    .label y = $65
    // display_action_progress("To start the SMC update, do the below action ...")
    // [1403] call display_action_progress
    // [704] phi from smc_flash to display_action_progress [phi:smc_flash->display_action_progress]
    // [704] phi display_action_progress::info_text#15 = smc_flash::info_text [phi:smc_flash->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // smc_flash::@25
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [1404] smc_flash::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [1405] smc_flash::cx16_k_i2c_write_byte1_offset = $8f -- vbum1=vbuc1 
    lda #$8f
    sta cx16_k_i2c_write_byte1_offset
    // [1406] smc_flash::cx16_k_i2c_write_byte1_value = $31 -- vbum1=vbuc1 
    lda #$31
    sta cx16_k_i2c_write_byte1_value
    // smc_flash::cx16_k_i2c_write_byte1
    // unsigned char result
    // [1407] smc_flash::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
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
    // [1409] smc_flash::cx16_k_i2c_write_byte1_return#0 = smc_flash::cx16_k_i2c_write_byte1_result -- vbuz1=vbum2 
    lda cx16_k_i2c_write_byte1_result
    sta.z cx16_k_i2c_write_byte1_return
    // smc_flash::cx16_k_i2c_write_byte1_@return
    // }
    // [1410] smc_flash::cx16_k_i2c_write_byte1_return#1 = smc_flash::cx16_k_i2c_write_byte1_return#0
    // smc_flash::@22
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [1411] smc_flash::smc_bootloader_start#0 = smc_flash::cx16_k_i2c_write_byte1_return#1
    // if(smc_bootloader_start)
    // [1412] if(0==smc_flash::smc_bootloader_start#0) goto smc_flash::@3 -- 0_eq_vbuz1_then_la1 
    lda.z smc_bootloader_start
    beq __b6
    // [1413] phi from smc_flash::@22 to smc_flash::@2 [phi:smc_flash::@22->smc_flash::@2]
    // smc_flash::@2
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1414] call snprintf_init
    // [872] phi from smc_flash::@2 to snprintf_init [phi:smc_flash::@2->snprintf_init]
    // [872] phi snprintf_init::s#25 = info_text [phi:smc_flash::@2->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1415] phi from smc_flash::@2 to smc_flash::@26 [phi:smc_flash::@2->smc_flash::@26]
    // smc_flash::@26
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1416] call printf_str
    // [877] phi from smc_flash::@26 to printf_str [phi:smc_flash::@26->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:smc_flash::@26->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = smc_flash::s [phi:smc_flash::@26->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@27
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1417] printf_uchar::uvalue#1 = smc_flash::smc_bootloader_start#0
    // [1418] call printf_uchar
    // [1040] phi from smc_flash::@27 to printf_uchar [phi:smc_flash::@27->printf_uchar]
    // [1040] phi printf_uchar::format_zero_padding#10 = 0 [phi:smc_flash::@27->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1040] phi printf_uchar::format_min_length#10 = 0 [phi:smc_flash::@27->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1040] phi printf_uchar::putc#10 = &snputc [phi:smc_flash::@27->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1040] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:smc_flash::@27->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [1040] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#1 [phi:smc_flash::@27->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // smc_flash::@28
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1419] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1420] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1422] call display_action_text
    // [1051] phi from smc_flash::@28 to display_action_text [phi:smc_flash::@28->display_action_text]
    // [1051] phi display_action_text::info_text#19 = info_text [phi:smc_flash::@28->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_flash::@29
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [1423] smc_flash::cx16_k_i2c_write_byte2_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte2_device
    // [1424] smc_flash::cx16_k_i2c_write_byte2_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte2_offset
    // [1425] smc_flash::cx16_k_i2c_write_byte2_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte2_value
    // smc_flash::cx16_k_i2c_write_byte2
    // unsigned char result
    // [1426] smc_flash::cx16_k_i2c_write_byte2_result = 0 -- vbum1=vbuc1 
    sta cx16_k_i2c_write_byte2_result
    // asm
    // asm { ldxdevice ldyoffset ldavalue stzresult jsrCX16_I2C_WRITE_BYTE rolresult  }
    ldx cx16_k_i2c_write_byte2_device
    ldy cx16_k_i2c_write_byte2_offset
    lda cx16_k_i2c_write_byte2_value
    stz cx16_k_i2c_write_byte2_result
    jsr CX16_I2C_WRITE_BYTE
    rol cx16_k_i2c_write_byte2_result
    // [1428] phi from smc_flash::@47 smc_flash::@59 smc_flash::cx16_k_i2c_write_byte2 to smc_flash::@return [phi:smc_flash::@47/smc_flash::@59/smc_flash::cx16_k_i2c_write_byte2->smc_flash::@return]
  __b2:
    // [1428] phi smc_flash::return#1 = 0 [phi:smc_flash::@47/smc_flash::@59/smc_flash::cx16_k_i2c_write_byte2->smc_flash::@return#0] -- vwum1=vbuc1 
    lda #<0
    sta return
    sta return+1
    // smc_flash::@return
    // }
    // [1429] return 
    rts
    // [1430] phi from smc_flash::@22 to smc_flash::@3 [phi:smc_flash::@22->smc_flash::@3]
  __b6:
    // [1430] phi smc_flash::smc_bootloader_activation_countdown#10 = $80 [phi:smc_flash::@22->smc_flash::@3#0] -- vbuz1=vbuc1 
    lda #$80
    sta.z smc_bootloader_activation_countdown
    // smc_flash::@3
  __b3:
    // while(smc_bootloader_activation_countdown)
    // [1431] if(0!=smc_flash::smc_bootloader_activation_countdown#10) goto smc_flash::@4 -- 0_neq_vbuz1_then_la1 
    lda.z smc_bootloader_activation_countdown
    beq !__b4+
    jmp __b4
  !__b4:
    // [1432] phi from smc_flash::@3 smc_flash::@30 to smc_flash::@7 [phi:smc_flash::@3/smc_flash::@30->smc_flash::@7]
  __b9:
    // [1432] phi smc_flash::smc_bootloader_activation_countdown#12 = $a [phi:smc_flash::@3/smc_flash::@30->smc_flash::@7#0] -- vbuz1=vbuc1 
    lda #$a
    sta.z smc_bootloader_activation_countdown_1
    // smc_flash::@7
  __b7:
    // while(smc_bootloader_activation_countdown)
    // [1433] if(0!=smc_flash::smc_bootloader_activation_countdown#12) goto smc_flash::@8 -- 0_neq_vbuz1_then_la1 
    lda.z smc_bootloader_activation_countdown_1
    beq !__b8+
    jmp __b8
  !__b8:
    // smc_flash::@9
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1434] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1435] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [1436] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [1437] cx16_k_i2c_read_byte::return#15 = cx16_k_i2c_read_byte::return#1 -- vwum1=vwuz2 
    lda.z cx16_k_i2c_read_byte.return
    sta cx16_k_i2c_read_byte.return_3
    lda.z cx16_k_i2c_read_byte.return+1
    sta cx16_k_i2c_read_byte.return_3+1
    // smc_flash::@42
    // smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1438] smc_flash::smc_bootloader_not_activated#1 = cx16_k_i2c_read_byte::return#15
    // if(smc_bootloader_not_activated)
    // [1439] if(0==smc_flash::smc_bootloader_not_activated#1) goto smc_flash::@1 -- 0_eq_vwum1_then_la1 
    lda smc_bootloader_not_activated
    ora smc_bootloader_not_activated+1
    beq __b1
    // [1440] phi from smc_flash::@42 to smc_flash::@10 [phi:smc_flash::@42->smc_flash::@10]
    // smc_flash::@10
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1441] call snprintf_init
    // [872] phi from smc_flash::@10 to snprintf_init [phi:smc_flash::@10->snprintf_init]
    // [872] phi snprintf_init::s#25 = info_text [phi:smc_flash::@10->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1442] phi from smc_flash::@10 to smc_flash::@45 [phi:smc_flash::@10->smc_flash::@45]
    // smc_flash::@45
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1443] call printf_str
    // [877] phi from smc_flash::@45 to printf_str [phi:smc_flash::@45->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:smc_flash::@45->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = smc_flash::s5 [phi:smc_flash::@45->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@46
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1444] printf_uint::uvalue#8 = smc_flash::smc_bootloader_not_activated#1 -- vwuz1=vwum2 
    lda smc_bootloader_not_activated
    sta.z printf_uint.uvalue
    lda smc_bootloader_not_activated+1
    sta.z printf_uint.uvalue+1
    // [1445] call printf_uint
    // [911] phi from smc_flash::@46 to printf_uint [phi:smc_flash::@46->printf_uint]
    // [911] phi printf_uint::format_zero_padding#19 = 0 [phi:smc_flash::@46->printf_uint#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uint.format_zero_padding
    // [911] phi printf_uint::format_min_length#19 = 0 [phi:smc_flash::@46->printf_uint#1] -- vbuz1=vbuc1 
    sta.z printf_uint.format_min_length
    // [911] phi printf_uint::putc#19 = &snputc [phi:smc_flash::@46->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [911] phi printf_uint::format_radix#19 = HEXADECIMAL [phi:smc_flash::@46->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [911] phi printf_uint::uvalue#19 = printf_uint::uvalue#8 [phi:smc_flash::@46->printf_uint#4] -- register_copy 
    jsr printf_uint
    // smc_flash::@47
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1446] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1447] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1449] call display_action_text
    // [1051] phi from smc_flash::@47 to display_action_text [phi:smc_flash::@47->display_action_text]
    // [1051] phi display_action_text::info_text#19 = info_text [phi:smc_flash::@47->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    jmp __b2
    // [1450] phi from smc_flash::@42 to smc_flash::@1 [phi:smc_flash::@42->smc_flash::@1]
    // smc_flash::@1
  __b1:
    // display_action_progress("Updating SMC firmware ... (+) Updated")
    // [1451] call display_action_progress
    // [704] phi from smc_flash::@1 to display_action_progress [phi:smc_flash::@1->display_action_progress]
    // [704] phi display_action_progress::info_text#15 = smc_flash::info_text1 [phi:smc_flash::@1->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_action_progress.info_text
    lda #>info_text1
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1452] phi from smc_flash::@1 to smc_flash::@43 [phi:smc_flash::@1->smc_flash::@43]
    // smc_flash::@43
    // textcolor(WHITE)
    // [1453] call textcolor
    // [592] phi from smc_flash::@43 to textcolor [phi:smc_flash::@43->textcolor]
    // [592] phi textcolor::color#18 = WHITE [phi:smc_flash::@43->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [1454] phi from smc_flash::@43 to smc_flash::@44 [phi:smc_flash::@43->smc_flash::@44]
    // smc_flash::@44
    // gotoxy(x, y)
    // [1455] call gotoxy
    // [610] phi from smc_flash::@44 to gotoxy [phi:smc_flash::@44->gotoxy]
    // [610] phi gotoxy::y#30 = PROGRESS_Y [phi:smc_flash::@44->gotoxy#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z gotoxy.y
    // [610] phi gotoxy::x#30 = PROGRESS_X [phi:smc_flash::@44->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [1456] phi from smc_flash::@44 to smc_flash::@11 [phi:smc_flash::@44->smc_flash::@11]
    // [1456] phi smc_flash::y#31 = PROGRESS_Y [phi:smc_flash::@44->smc_flash::@11#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // [1456] phi smc_flash::smc_attempts_total#21 = 0 [phi:smc_flash::@44->smc_flash::@11#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z smc_attempts_total
    sta.z smc_attempts_total+1
    // [1456] phi smc_flash::smc_row_bytes#14 = 0 [phi:smc_flash::@44->smc_flash::@11#2] -- vwuz1=vwuc1 
    sta.z smc_row_bytes
    sta.z smc_row_bytes+1
    // [1456] phi smc_flash::smc_ram_ptr#13 = (char *)$7800 [phi:smc_flash::@44->smc_flash::@11#3] -- pbuz1=pbuc1 
    lda #<$7800
    sta.z smc_ram_ptr
    lda #>$7800
    sta.z smc_ram_ptr+1
    // [1456] phi smc_flash::smc_bytes_flashed#16 = 0 [phi:smc_flash::@44->smc_flash::@11#4] -- vwum1=vwuc1 
    lda #<0
    sta smc_bytes_flashed
    sta smc_bytes_flashed+1
    // [1456] phi from smc_flash::@13 to smc_flash::@11 [phi:smc_flash::@13->smc_flash::@11]
    // [1456] phi smc_flash::y#31 = smc_flash::y#20 [phi:smc_flash::@13->smc_flash::@11#0] -- register_copy 
    // [1456] phi smc_flash::smc_attempts_total#21 = smc_flash::smc_attempts_total#17 [phi:smc_flash::@13->smc_flash::@11#1] -- register_copy 
    // [1456] phi smc_flash::smc_row_bytes#14 = smc_flash::smc_row_bytes#10 [phi:smc_flash::@13->smc_flash::@11#2] -- register_copy 
    // [1456] phi smc_flash::smc_ram_ptr#13 = smc_flash::smc_ram_ptr#10 [phi:smc_flash::@13->smc_flash::@11#3] -- register_copy 
    // [1456] phi smc_flash::smc_bytes_flashed#16 = smc_flash::smc_bytes_flashed#11 [phi:smc_flash::@13->smc_flash::@11#4] -- register_copy 
    // smc_flash::@11
  __b11:
    // while(smc_bytes_flashed < smc_bytes_total)
    // [1457] if(smc_flash::smc_bytes_flashed#16<smc_flash::smc_bytes_total#0) goto smc_flash::@12 -- vwum1_lt_vwum2_then_la1 
    lda smc_bytes_flashed+1
    cmp smc_bytes_total+1
    bcc __b10
    bne !+
    lda smc_bytes_flashed
    cmp smc_bytes_total
    bcc __b10
  !:
    // [1428] phi from smc_flash::@11 to smc_flash::@return [phi:smc_flash::@11->smc_flash::@return]
    // [1428] phi smc_flash::return#1 = smc_flash::smc_bytes_flashed#16 [phi:smc_flash::@11->smc_flash::@return#0] -- register_copy 
    rts
    // [1458] phi from smc_flash::@11 to smc_flash::@12 [phi:smc_flash::@11->smc_flash::@12]
  __b10:
    // [1458] phi smc_flash::y#20 = smc_flash::y#31 [phi:smc_flash::@11->smc_flash::@12#0] -- register_copy 
    // [1458] phi smc_flash::smc_attempts_total#17 = smc_flash::smc_attempts_total#21 [phi:smc_flash::@11->smc_flash::@12#1] -- register_copy 
    // [1458] phi smc_flash::smc_row_bytes#10 = smc_flash::smc_row_bytes#14 [phi:smc_flash::@11->smc_flash::@12#2] -- register_copy 
    // [1458] phi smc_flash::smc_ram_ptr#10 = smc_flash::smc_ram_ptr#13 [phi:smc_flash::@11->smc_flash::@12#3] -- register_copy 
    // [1458] phi smc_flash::smc_bytes_flashed#11 = smc_flash::smc_bytes_flashed#16 [phi:smc_flash::@11->smc_flash::@12#4] -- register_copy 
    // [1458] phi smc_flash::smc_attempts_flashed#19 = 0 [phi:smc_flash::@11->smc_flash::@12#5] -- vbuz1=vbuc1 
    lda #0
    sta.z smc_attempts_flashed
    // [1458] phi smc_flash::smc_package_committed#2 = 0 [phi:smc_flash::@11->smc_flash::@12#6] -- vbum1=vbuc1 
    sta smc_package_committed
    // smc_flash::@12
  __b12:
    // while(!smc_package_committed && smc_attempts_flashed < 10)
    // [1459] if(0!=smc_flash::smc_package_committed#2) goto smc_flash::@13 -- 0_neq_vbum1_then_la1 
    lda smc_package_committed
    bne __b13
    // smc_flash::@60
    // [1460] if(smc_flash::smc_attempts_flashed#19<$a) goto smc_flash::@14 -- vbuz1_lt_vbuc1_then_la1 
    lda.z smc_attempts_flashed
    cmp #$a
    bcc __b16
    // smc_flash::@13
  __b13:
    // if(smc_attempts_flashed >= 10)
    // [1461] if(smc_flash::smc_attempts_flashed#19<$a) goto smc_flash::@11 -- vbuz1_lt_vbuc1_then_la1 
    lda.z smc_attempts_flashed
    cmp #$a
    bcc __b11
    // [1462] phi from smc_flash::@13 to smc_flash::@21 [phi:smc_flash::@13->smc_flash::@21]
    // smc_flash::@21
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1463] call snprintf_init
    // [872] phi from smc_flash::@21 to snprintf_init [phi:smc_flash::@21->snprintf_init]
    // [872] phi snprintf_init::s#25 = info_text [phi:smc_flash::@21->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1464] phi from smc_flash::@21 to smc_flash::@57 [phi:smc_flash::@21->smc_flash::@57]
    // smc_flash::@57
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1465] call printf_str
    // [877] phi from smc_flash::@57 to printf_str [phi:smc_flash::@57->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:smc_flash::@57->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = smc_flash::s10 [phi:smc_flash::@57->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@58
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1466] printf_uint::uvalue#12 = smc_flash::smc_bytes_flashed#11 -- vwuz1=vwum2 
    lda smc_bytes_flashed
    sta.z printf_uint.uvalue
    lda smc_bytes_flashed+1
    sta.z printf_uint.uvalue+1
    // [1467] call printf_uint
    // [911] phi from smc_flash::@58 to printf_uint [phi:smc_flash::@58->printf_uint]
    // [911] phi printf_uint::format_zero_padding#19 = 1 [phi:smc_flash::@58->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [911] phi printf_uint::format_min_length#19 = 4 [phi:smc_flash::@58->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [911] phi printf_uint::putc#19 = &snputc [phi:smc_flash::@58->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [911] phi printf_uint::format_radix#19 = HEXADECIMAL [phi:smc_flash::@58->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [911] phi printf_uint::uvalue#19 = printf_uint::uvalue#12 [phi:smc_flash::@58->printf_uint#4] -- register_copy 
    jsr printf_uint
    // smc_flash::@59
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1468] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1469] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1471] call display_action_text
    // [1051] phi from smc_flash::@59 to display_action_text [phi:smc_flash::@59->display_action_text]
    // [1051] phi display_action_text::info_text#19 = info_text [phi:smc_flash::@59->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    jmp __b2
    // [1472] phi from smc_flash::@60 to smc_flash::@14 [phi:smc_flash::@60->smc_flash::@14]
  __b16:
    // [1472] phi smc_flash::smc_bytes_checksum#2 = 0 [phi:smc_flash::@60->smc_flash::@14#0] -- vbum1=vbuc1 
    lda #0
    sta smc_bytes_checksum
    // [1472] phi smc_flash::smc_ram_ptr#12 = smc_flash::smc_ram_ptr#10 [phi:smc_flash::@60->smc_flash::@14#1] -- register_copy 
    // [1472] phi smc_flash::smc_package_flashed#2 = 0 [phi:smc_flash::@60->smc_flash::@14#2] -- vwuz1=vwuc1 
    sta.z smc_package_flashed
    sta.z smc_package_flashed+1
    // smc_flash::@14
  __b14:
    // while(smc_package_flashed < SMC_PROGRESS_CELL)
    // [1473] if(smc_flash::smc_package_flashed#2<SMC_PROGRESS_CELL) goto smc_flash::@15 -- vwuz1_lt_vbuc1_then_la1 
    lda.z smc_package_flashed+1
    bne !+
    lda.z smc_package_flashed
    cmp #SMC_PROGRESS_CELL
    bcs !__b15+
    jmp __b15
  !__b15:
  !:
    // smc_flash::@16
    // smc_bytes_checksum ^ 0xFF
    // [1474] smc_flash::$26 = smc_flash::smc_bytes_checksum#2 ^ $ff -- vbum1=vbum1_bxor_vbuc1 
    lda #$ff
    eor smc_flash__26
    sta smc_flash__26
    // (smc_bytes_checksum ^ 0xFF)+1
    // [1475] smc_flash::$27 = smc_flash::$26 + 1 -- vbum1=vbum1_plus_1 
    inc smc_flash__27
    // unsigned char smc_checksum_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, (smc_bytes_checksum ^ 0xFF)+1)
    // [1476] smc_flash::cx16_k_i2c_write_byte4_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte4_device
    // [1477] smc_flash::cx16_k_i2c_write_byte4_offset = $80 -- vbum1=vbuc1 
    lda #$80
    sta cx16_k_i2c_write_byte4_offset
    // [1478] smc_flash::cx16_k_i2c_write_byte4_value = smc_flash::$27 -- vbum1=vbum2 
    lda smc_flash__27
    sta cx16_k_i2c_write_byte4_value
    // smc_flash::cx16_k_i2c_write_byte4
    // unsigned char result
    // [1479] smc_flash::cx16_k_i2c_write_byte4_result = 0 -- vbum1=vbuc1 
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
    // smc_flash::@24
    // unsigned int smc_commit_result = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_COMMIT)
    // [1481] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1482] cx16_k_i2c_read_byte::offset = $81 -- vbum1=vbuc1 
    lda #$81
    sta cx16_k_i2c_read_byte.offset
    // [1483] call cx16_k_i2c_read_byte
    // Now send the commit command.
    jsr cx16_k_i2c_read_byte
    // [1484] cx16_k_i2c_read_byte::return#16 = cx16_k_i2c_read_byte::return#1
    // smc_flash::@48
    // [1485] smc_flash::smc_commit_result#0 = cx16_k_i2c_read_byte::return#16
    // if(smc_commit_result == 1)
    // [1486] if(smc_flash::smc_commit_result#0==1) goto smc_flash::@18 -- vwuz1_eq_vbuc1_then_la1 
    lda.z smc_commit_result+1
    bne !+
    lda.z smc_commit_result
    cmp #1
    beq __b18
  !:
    // smc_flash::@17
    // smc_ram_ptr -= SMC_PROGRESS_CELL
    // [1487] smc_flash::smc_ram_ptr#2 = smc_flash::smc_ram_ptr#12 - SMC_PROGRESS_CELL -- pbuz1=pbuz1_minus_vbuc1 
    sec
    lda.z smc_ram_ptr
    sbc #SMC_PROGRESS_CELL
    sta.z smc_ram_ptr
    lda.z smc_ram_ptr+1
    sbc #0
    sta.z smc_ram_ptr+1
    // smc_attempts_flashed++;
    // [1488] smc_flash::smc_attempts_flashed#1 = ++ smc_flash::smc_attempts_flashed#19 -- vbuz1=_inc_vbuz1 
    inc.z smc_attempts_flashed
    // [1458] phi from smc_flash::@17 to smc_flash::@12 [phi:smc_flash::@17->smc_flash::@12]
    // [1458] phi smc_flash::y#20 = smc_flash::y#20 [phi:smc_flash::@17->smc_flash::@12#0] -- register_copy 
    // [1458] phi smc_flash::smc_attempts_total#17 = smc_flash::smc_attempts_total#17 [phi:smc_flash::@17->smc_flash::@12#1] -- register_copy 
    // [1458] phi smc_flash::smc_row_bytes#10 = smc_flash::smc_row_bytes#10 [phi:smc_flash::@17->smc_flash::@12#2] -- register_copy 
    // [1458] phi smc_flash::smc_ram_ptr#10 = smc_flash::smc_ram_ptr#2 [phi:smc_flash::@17->smc_flash::@12#3] -- register_copy 
    // [1458] phi smc_flash::smc_bytes_flashed#11 = smc_flash::smc_bytes_flashed#11 [phi:smc_flash::@17->smc_flash::@12#4] -- register_copy 
    // [1458] phi smc_flash::smc_attempts_flashed#19 = smc_flash::smc_attempts_flashed#1 [phi:smc_flash::@17->smc_flash::@12#5] -- register_copy 
    // [1458] phi smc_flash::smc_package_committed#2 = smc_flash::smc_package_committed#2 [phi:smc_flash::@17->smc_flash::@12#6] -- register_copy 
    jmp __b12
    // smc_flash::@18
  __b18:
    // if (smc_row_bytes == SMC_PROGRESS_ROW)
    // [1489] if(smc_flash::smc_row_bytes#10!=SMC_PROGRESS_ROW) goto smc_flash::@19 -- vwuz1_neq_vwuc1_then_la1 
    lda.z smc_row_bytes+1
    cmp #>SMC_PROGRESS_ROW
    bne __b19
    lda.z smc_row_bytes
    cmp #<SMC_PROGRESS_ROW
    bne __b19
    // smc_flash::@20
    // gotoxy(x, ++y);
    // [1490] smc_flash::y#1 = ++ smc_flash::y#20 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [1491] gotoxy::y#22 = smc_flash::y#1 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1492] call gotoxy
    // [610] phi from smc_flash::@20 to gotoxy [phi:smc_flash::@20->gotoxy]
    // [610] phi gotoxy::y#30 = gotoxy::y#22 [phi:smc_flash::@20->gotoxy#0] -- register_copy 
    // [610] phi gotoxy::x#30 = PROGRESS_X [phi:smc_flash::@20->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [1493] phi from smc_flash::@20 to smc_flash::@19 [phi:smc_flash::@20->smc_flash::@19]
    // [1493] phi smc_flash::y#33 = smc_flash::y#1 [phi:smc_flash::@20->smc_flash::@19#0] -- register_copy 
    // [1493] phi smc_flash::smc_row_bytes#4 = 0 [phi:smc_flash::@20->smc_flash::@19#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z smc_row_bytes
    sta.z smc_row_bytes+1
    // [1493] phi from smc_flash::@18 to smc_flash::@19 [phi:smc_flash::@18->smc_flash::@19]
    // [1493] phi smc_flash::y#33 = smc_flash::y#20 [phi:smc_flash::@18->smc_flash::@19#0] -- register_copy 
    // [1493] phi smc_flash::smc_row_bytes#4 = smc_flash::smc_row_bytes#10 [phi:smc_flash::@18->smc_flash::@19#1] -- register_copy 
    // smc_flash::@19
  __b19:
    // cputc('+')
    // [1494] stackpush(char) = '+' -- _stackpushbyte_=vbuc1 
    lda #'+'
    pha
    // [1495] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_bytes_flashed += SMC_PROGRESS_CELL
    // [1497] smc_flash::smc_bytes_flashed#1 = smc_flash::smc_bytes_flashed#11 + SMC_PROGRESS_CELL -- vwum1=vwum1_plus_vbuc1 
    lda #SMC_PROGRESS_CELL
    clc
    adc smc_bytes_flashed
    sta smc_bytes_flashed
    bcc !+
    inc smc_bytes_flashed+1
  !:
    // smc_row_bytes += SMC_PROGRESS_CELL
    // [1498] smc_flash::smc_row_bytes#1 = smc_flash::smc_row_bytes#4 + SMC_PROGRESS_CELL -- vwuz1=vwuz1_plus_vbuc1 
    lda #SMC_PROGRESS_CELL
    clc
    adc.z smc_row_bytes
    sta.z smc_row_bytes
    bcc !+
    inc.z smc_row_bytes+1
  !:
    // smc_attempts_total += smc_attempts_flashed
    // [1499] smc_flash::smc_attempts_total#1 = smc_flash::smc_attempts_total#17 + smc_flash::smc_attempts_flashed#19 -- vwuz1=vwuz1_plus_vbuz2 
    lda.z smc_attempts_flashed
    clc
    adc.z smc_attempts_total
    sta.z smc_attempts_total
    bcc !+
    inc.z smc_attempts_total+1
  !:
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1500] call snprintf_init
    // [872] phi from smc_flash::@19 to snprintf_init [phi:smc_flash::@19->snprintf_init]
    // [872] phi snprintf_init::s#25 = info_text [phi:smc_flash::@19->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1501] phi from smc_flash::@19 to smc_flash::@49 [phi:smc_flash::@19->smc_flash::@49]
    // smc_flash::@49
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1502] call printf_str
    // [877] phi from smc_flash::@49 to printf_str [phi:smc_flash::@49->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:smc_flash::@49->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = smc_flash::s6 [phi:smc_flash::@49->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@50
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1503] printf_uint::uvalue#9 = smc_flash::smc_bytes_flashed#1 -- vwuz1=vwum2 
    lda smc_bytes_flashed
    sta.z printf_uint.uvalue
    lda smc_bytes_flashed+1
    sta.z printf_uint.uvalue+1
    // [1504] call printf_uint
    // [911] phi from smc_flash::@50 to printf_uint [phi:smc_flash::@50->printf_uint]
    // [911] phi printf_uint::format_zero_padding#19 = 1 [phi:smc_flash::@50->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [911] phi printf_uint::format_min_length#19 = 5 [phi:smc_flash::@50->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [911] phi printf_uint::putc#19 = &snputc [phi:smc_flash::@50->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [911] phi printf_uint::format_radix#19 = DECIMAL [phi:smc_flash::@50->printf_uint#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [911] phi printf_uint::uvalue#19 = printf_uint::uvalue#9 [phi:smc_flash::@50->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1505] phi from smc_flash::@50 to smc_flash::@51 [phi:smc_flash::@50->smc_flash::@51]
    // smc_flash::@51
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1506] call printf_str
    // [877] phi from smc_flash::@51 to printf_str [phi:smc_flash::@51->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:smc_flash::@51->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = smc_flash::s7 [phi:smc_flash::@51->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@52
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1507] printf_uint::uvalue#10 = smc_flash::smc_bytes_total#0 -- vwuz1=vwum2 
    lda smc_bytes_total
    sta.z printf_uint.uvalue
    lda smc_bytes_total+1
    sta.z printf_uint.uvalue+1
    // [1508] call printf_uint
    // [911] phi from smc_flash::@52 to printf_uint [phi:smc_flash::@52->printf_uint]
    // [911] phi printf_uint::format_zero_padding#19 = 1 [phi:smc_flash::@52->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [911] phi printf_uint::format_min_length#19 = 5 [phi:smc_flash::@52->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [911] phi printf_uint::putc#19 = &snputc [phi:smc_flash::@52->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [911] phi printf_uint::format_radix#19 = DECIMAL [phi:smc_flash::@52->printf_uint#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [911] phi printf_uint::uvalue#19 = printf_uint::uvalue#10 [phi:smc_flash::@52->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1509] phi from smc_flash::@52 to smc_flash::@53 [phi:smc_flash::@52->smc_flash::@53]
    // smc_flash::@53
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1510] call printf_str
    // [877] phi from smc_flash::@53 to printf_str [phi:smc_flash::@53->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:smc_flash::@53->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = smc_flash::s8 [phi:smc_flash::@53->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@54
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1511] printf_uint::uvalue#11 = smc_flash::smc_attempts_total#1 -- vwuz1=vwuz2 
    lda.z smc_attempts_total
    sta.z printf_uint.uvalue
    lda.z smc_attempts_total+1
    sta.z printf_uint.uvalue+1
    // [1512] call printf_uint
    // [911] phi from smc_flash::@54 to printf_uint [phi:smc_flash::@54->printf_uint]
    // [911] phi printf_uint::format_zero_padding#19 = 1 [phi:smc_flash::@54->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [911] phi printf_uint::format_min_length#19 = 2 [phi:smc_flash::@54->printf_uint#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uint.format_min_length
    // [911] phi printf_uint::putc#19 = &snputc [phi:smc_flash::@54->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [911] phi printf_uint::format_radix#19 = DECIMAL [phi:smc_flash::@54->printf_uint#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [911] phi printf_uint::uvalue#19 = printf_uint::uvalue#11 [phi:smc_flash::@54->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1513] phi from smc_flash::@54 to smc_flash::@55 [phi:smc_flash::@54->smc_flash::@55]
    // smc_flash::@55
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1514] call printf_str
    // [877] phi from smc_flash::@55 to printf_str [phi:smc_flash::@55->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:smc_flash::@55->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = smc_flash::s9 [phi:smc_flash::@55->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@56
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1515] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1516] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1518] call display_action_text
    // [1051] phi from smc_flash::@56 to display_action_text [phi:smc_flash::@56->display_action_text]
    // [1051] phi display_action_text::info_text#19 = info_text [phi:smc_flash::@56->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1458] phi from smc_flash::@56 to smc_flash::@12 [phi:smc_flash::@56->smc_flash::@12]
    // [1458] phi smc_flash::y#20 = smc_flash::y#33 [phi:smc_flash::@56->smc_flash::@12#0] -- register_copy 
    // [1458] phi smc_flash::smc_attempts_total#17 = smc_flash::smc_attempts_total#1 [phi:smc_flash::@56->smc_flash::@12#1] -- register_copy 
    // [1458] phi smc_flash::smc_row_bytes#10 = smc_flash::smc_row_bytes#1 [phi:smc_flash::@56->smc_flash::@12#2] -- register_copy 
    // [1458] phi smc_flash::smc_ram_ptr#10 = smc_flash::smc_ram_ptr#12 [phi:smc_flash::@56->smc_flash::@12#3] -- register_copy 
    // [1458] phi smc_flash::smc_bytes_flashed#11 = smc_flash::smc_bytes_flashed#1 [phi:smc_flash::@56->smc_flash::@12#4] -- register_copy 
    // [1458] phi smc_flash::smc_attempts_flashed#19 = smc_flash::smc_attempts_flashed#19 [phi:smc_flash::@56->smc_flash::@12#5] -- register_copy 
    // [1458] phi smc_flash::smc_package_committed#2 = 1 [phi:smc_flash::@56->smc_flash::@12#6] -- vbum1=vbuc1 
    lda #1
    sta smc_package_committed
    jmp __b12
    // smc_flash::@15
  __b15:
    // unsigned char smc_byte_upload = *smc_ram_ptr
    // [1519] smc_flash::smc_byte_upload#0 = *smc_flash::smc_ram_ptr#12 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (smc_ram_ptr),y
    sta smc_byte_upload
    // smc_ram_ptr++;
    // [1520] smc_flash::smc_ram_ptr#1 = ++ smc_flash::smc_ram_ptr#12 -- pbuz1=_inc_pbuz1 
    inc.z smc_ram_ptr
    bne !+
    inc.z smc_ram_ptr+1
  !:
    // smc_bytes_checksum += smc_byte_upload
    // [1521] smc_flash::smc_bytes_checksum#1 = smc_flash::smc_bytes_checksum#2 + smc_flash::smc_byte_upload#0 -- vbum1=vbum1_plus_vbum2 
    lda smc_bytes_checksum
    clc
    adc smc_byte_upload
    sta smc_bytes_checksum
    // unsigned char smc_upload_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, smc_byte_upload)
    // [1522] smc_flash::cx16_k_i2c_write_byte3_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte3_device
    // [1523] smc_flash::cx16_k_i2c_write_byte3_offset = $80 -- vbum1=vbuc1 
    lda #$80
    sta cx16_k_i2c_write_byte3_offset
    // [1524] smc_flash::cx16_k_i2c_write_byte3_value = smc_flash::smc_byte_upload#0 -- vbum1=vbum2 
    lda smc_byte_upload
    sta cx16_k_i2c_write_byte3_value
    // smc_flash::cx16_k_i2c_write_byte3
    // unsigned char result
    // [1525] smc_flash::cx16_k_i2c_write_byte3_result = 0 -- vbum1=vbuc1 
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
    // smc_flash::@23
    // smc_package_flashed++;
    // [1527] smc_flash::smc_package_flashed#1 = ++ smc_flash::smc_package_flashed#2 -- vwuz1=_inc_vwuz1 
    inc.z smc_package_flashed
    bne !+
    inc.z smc_package_flashed+1
  !:
    // [1472] phi from smc_flash::@23 to smc_flash::@14 [phi:smc_flash::@23->smc_flash::@14]
    // [1472] phi smc_flash::smc_bytes_checksum#2 = smc_flash::smc_bytes_checksum#1 [phi:smc_flash::@23->smc_flash::@14#0] -- register_copy 
    // [1472] phi smc_flash::smc_ram_ptr#12 = smc_flash::smc_ram_ptr#1 [phi:smc_flash::@23->smc_flash::@14#1] -- register_copy 
    // [1472] phi smc_flash::smc_package_flashed#2 = smc_flash::smc_package_flashed#1 [phi:smc_flash::@23->smc_flash::@14#2] -- register_copy 
    jmp __b14
    // [1528] phi from smc_flash::@7 to smc_flash::@8 [phi:smc_flash::@7->smc_flash::@8]
    // smc_flash::@8
  __b8:
    // wait_moment()
    // [1529] call wait_moment
    // [1035] phi from smc_flash::@8 to wait_moment [phi:smc_flash::@8->wait_moment]
    jsr wait_moment
    // [1530] phi from smc_flash::@8 to smc_flash::@36 [phi:smc_flash::@8->smc_flash::@36]
    // smc_flash::@36
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1531] call snprintf_init
    // [872] phi from smc_flash::@36 to snprintf_init [phi:smc_flash::@36->snprintf_init]
    // [872] phi snprintf_init::s#25 = info_text [phi:smc_flash::@36->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1532] phi from smc_flash::@36 to smc_flash::@37 [phi:smc_flash::@36->smc_flash::@37]
    // smc_flash::@37
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1533] call printf_str
    // [877] phi from smc_flash::@37 to printf_str [phi:smc_flash::@37->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:smc_flash::@37->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = smc_flash::s3 [phi:smc_flash::@37->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@38
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1534] printf_uchar::uvalue#3 = smc_flash::smc_bootloader_activation_countdown#12 -- vbuz1=vbuz2 
    lda.z smc_bootloader_activation_countdown_1
    sta.z printf_uchar.uvalue
    // [1535] call printf_uchar
    // [1040] phi from smc_flash::@38 to printf_uchar [phi:smc_flash::@38->printf_uchar]
    // [1040] phi printf_uchar::format_zero_padding#10 = 0 [phi:smc_flash::@38->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1040] phi printf_uchar::format_min_length#10 = 0 [phi:smc_flash::@38->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1040] phi printf_uchar::putc#10 = &snputc [phi:smc_flash::@38->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1040] phi printf_uchar::format_radix#10 = DECIMAL [phi:smc_flash::@38->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1040] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#3 [phi:smc_flash::@38->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1536] phi from smc_flash::@38 to smc_flash::@39 [phi:smc_flash::@38->smc_flash::@39]
    // smc_flash::@39
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1537] call printf_str
    // [877] phi from smc_flash::@39 to printf_str [phi:smc_flash::@39->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:smc_flash::@39->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = s7 [phi:smc_flash::@39->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s7
    sta.z printf_str.s
    lda #>@s7
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@40
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1538] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1539] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1541] call display_action_text
    // [1051] phi from smc_flash::@40 to display_action_text [phi:smc_flash::@40->display_action_text]
    // [1051] phi display_action_text::info_text#19 = info_text [phi:smc_flash::@40->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_flash::@41
    // smc_bootloader_activation_countdown--;
    // [1542] smc_flash::smc_bootloader_activation_countdown#3 = -- smc_flash::smc_bootloader_activation_countdown#12 -- vbuz1=_dec_vbuz1 
    dec.z smc_bootloader_activation_countdown_1
    // [1432] phi from smc_flash::@41 to smc_flash::@7 [phi:smc_flash::@41->smc_flash::@7]
    // [1432] phi smc_flash::smc_bootloader_activation_countdown#12 = smc_flash::smc_bootloader_activation_countdown#3 [phi:smc_flash::@41->smc_flash::@7#0] -- register_copy 
    jmp __b7
    // smc_flash::@4
  __b4:
    // unsigned int smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1543] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1544] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [1545] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [1546] cx16_k_i2c_read_byte::return#14 = cx16_k_i2c_read_byte::return#1
    // smc_flash::@30
    // [1547] smc_flash::smc_bootloader_not_activated1#0 = cx16_k_i2c_read_byte::return#14
    // if(smc_bootloader_not_activated)
    // [1548] if(0!=smc_flash::smc_bootloader_not_activated1#0) goto smc_flash::@5 -- 0_neq_vwuz1_then_la1 
    lda.z smc_bootloader_not_activated1
    ora.z smc_bootloader_not_activated1+1
    bne __b5
    jmp __b9
    // [1549] phi from smc_flash::@30 to smc_flash::@5 [phi:smc_flash::@30->smc_flash::@5]
    // smc_flash::@5
  __b5:
    // wait_moment()
    // [1550] call wait_moment
    // [1035] phi from smc_flash::@5 to wait_moment [phi:smc_flash::@5->wait_moment]
    jsr wait_moment
    // [1551] phi from smc_flash::@5 to smc_flash::@31 [phi:smc_flash::@5->smc_flash::@31]
    // smc_flash::@31
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1552] call snprintf_init
    // [872] phi from smc_flash::@31 to snprintf_init [phi:smc_flash::@31->snprintf_init]
    // [872] phi snprintf_init::s#25 = info_text [phi:smc_flash::@31->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1553] phi from smc_flash::@31 to smc_flash::@32 [phi:smc_flash::@31->smc_flash::@32]
    // smc_flash::@32
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1554] call printf_str
    // [877] phi from smc_flash::@32 to printf_str [phi:smc_flash::@32->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:smc_flash::@32->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = smc_flash::s1 [phi:smc_flash::@32->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@33
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1555] printf_uchar::uvalue#2 = smc_flash::smc_bootloader_activation_countdown#10 -- vbuz1=vbuz2 
    lda.z smc_bootloader_activation_countdown
    sta.z printf_uchar.uvalue
    // [1556] call printf_uchar
    // [1040] phi from smc_flash::@33 to printf_uchar [phi:smc_flash::@33->printf_uchar]
    // [1040] phi printf_uchar::format_zero_padding#10 = 1 [phi:smc_flash::@33->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1040] phi printf_uchar::format_min_length#10 = 3 [phi:smc_flash::@33->printf_uchar#1] -- vbuz1=vbuc1 
    lda #3
    sta.z printf_uchar.format_min_length
    // [1040] phi printf_uchar::putc#10 = &snputc [phi:smc_flash::@33->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1040] phi printf_uchar::format_radix#10 = DECIMAL [phi:smc_flash::@33->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1040] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#2 [phi:smc_flash::@33->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1557] phi from smc_flash::@33 to smc_flash::@34 [phi:smc_flash::@33->smc_flash::@34]
    // smc_flash::@34
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1558] call printf_str
    // [877] phi from smc_flash::@34 to printf_str [phi:smc_flash::@34->printf_str]
    // [877] phi printf_str::putc#73 = &snputc [phi:smc_flash::@34->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [877] phi printf_str::s#73 = smc_flash::s2 [phi:smc_flash::@34->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@35
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1559] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1560] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1562] call display_action_text
    // [1051] phi from smc_flash::@35 to display_action_text [phi:smc_flash::@35->display_action_text]
    // [1051] phi display_action_text::info_text#19 = info_text [phi:smc_flash::@35->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_flash::@6
    // smc_bootloader_activation_countdown--;
    // [1563] smc_flash::smc_bootloader_activation_countdown#2 = -- smc_flash::smc_bootloader_activation_countdown#10 -- vbuz1=_dec_vbuz1 
    dec.z smc_bootloader_activation_countdown
    // [1430] phi from smc_flash::@6 to smc_flash::@3 [phi:smc_flash::@6->smc_flash::@3]
    // [1430] phi smc_flash::smc_bootloader_activation_countdown#10 = smc_flash::smc_bootloader_activation_countdown#2 [phi:smc_flash::@6->smc_flash::@3#0] -- register_copy 
    jmp __b3
  .segment Data
    info_text: .text "To start the SMC update, do the below action ..."
    .byte 0
    s: .text "There was a problem starting the SMC bootloader: "
    .byte 0
    s1: .text "["
    .byte 0
    s2: .text "] Press POWER and RESET on the CX16 to start the SMC update!"
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
    .label smc_flash__26 = main.check_status_smc8_main__0
    .label smc_flash__27 = main.check_status_smc8_main__0
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
    .label return = fgets.stream
    .label smc_bootloader_not_activated = display_print_chip.text
    smc_byte_upload: .byte 0
    .label smc_bytes_checksum = main.check_status_smc8_main__0
    .label smc_bytes_flashed = fgets.stream
    .label smc_bytes_total = util_wait_key.ch
    .label smc_package_committed = main.check_status_vera1_main__0
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
// __zp($2d) char util_wait_key(__zp($73) char *info_text, __zp($c0) char *filter)
util_wait_key: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 0
    .label util_wait_key__9 = $2e
    .label bram = $6e
    .label bank_get_brom1_return = $de
    .label return = $2d
    .label info_text = $73
    .label filter = $c0
    // display_action_text(info_text)
    // [1565] display_action_text::info_text#7 = util_wait_key::info_text#2
    // [1566] call display_action_text
    // [1051] phi from util_wait_key to display_action_text [phi:util_wait_key->display_action_text]
    // [1051] phi display_action_text::info_text#19 = display_action_text::info_text#7 [phi:util_wait_key->display_action_text#0] -- register_copy 
    jsr display_action_text
    // util_wait_key::bank_get_bram1
    // return BRAM;
    // [1567] util_wait_key::bram#0 = BRAM -- vbuz1=vbuz2 
    lda.z BRAM
    sta.z bram
    // util_wait_key::bank_get_brom1
    // return BROM;
    // [1568] util_wait_key::bank_get_brom1_return#0 = BROM -- vbuz1=vbuz2 
    lda.z BROM
    sta.z bank_get_brom1_return
    // util_wait_key::bank_set_bram1
    // BRAM = bank
    // [1569] BRAM = util_wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // util_wait_key::bank_set_brom1
    // BROM = bank
    // [1570] BROM = util_wait_key::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [1571] phi from util_wait_key::@2 util_wait_key::@5 util_wait_key::bank_set_brom1 to util_wait_key::kbhit1 [phi:util_wait_key::@2/util_wait_key::@5/util_wait_key::bank_set_brom1->util_wait_key::kbhit1]
    // util_wait_key::kbhit1
  kbhit1:
    // util_wait_key::kbhit1_cbm_k_clrchn1
    // asm
    // asm { jsrCBM_CLRCHN  }
    jsr CBM_CLRCHN
    // [1573] phi from util_wait_key::kbhit1_cbm_k_clrchn1 to util_wait_key::kbhit1_@2 [phi:util_wait_key::kbhit1_cbm_k_clrchn1->util_wait_key::kbhit1_@2]
    // util_wait_key::kbhit1_@2
    // cbm_k_getin()
    // [1574] call cbm_k_getin
    jsr cbm_k_getin
    // [1575] cbm_k_getin::return#2 = cbm_k_getin::return#1
    // util_wait_key::@4
    // [1576] util_wait_key::ch#4 = cbm_k_getin::return#2 -- vwum1=vbuz2 
    lda.z cbm_k_getin.return
    sta ch
    lda #0
    sta ch+1
    // util_wait_key::@3
    // if (filter)
    // [1577] if((char *)0!=util_wait_key::filter#12) goto util_wait_key::@1 -- pbuc1_neq_pbuz1_then_la1 
    // if there is a filter, check the filter, otherwise return ch.
    lda.z filter+1
    cmp #>0
    bne __b1
    lda.z filter
    cmp #<0
    bne __b1
    // util_wait_key::@2
    // if(ch)
    // [1578] if(0!=util_wait_key::ch#4) goto util_wait_key::bank_set_bram2 -- 0_neq_vwum1_then_la1 
    lda ch
    ora ch+1
    bne bank_set_bram2
    jmp kbhit1
    // util_wait_key::bank_set_bram2
  bank_set_bram2:
    // BRAM = bank
    // [1579] BRAM = util_wait_key::bram#0 -- vbuz1=vbuz2 
    lda.z bram
    sta.z BRAM
    // util_wait_key::bank_set_brom2
    // BROM = bank
    // [1580] BROM = util_wait_key::bank_get_brom1_return#0 -- vbuz1=vbuz2 
    lda.z bank_get_brom1_return
    sta.z BROM
    // util_wait_key::@return
    // }
    // [1581] return 
    rts
    // util_wait_key::@1
  __b1:
    // strchr(filter, ch)
    // [1582] strchr::str#0 = (const void *)util_wait_key::filter#12 -- pvoz1=pvoz2 
    lda.z filter
    sta.z strchr.str
    lda.z filter+1
    sta.z strchr.str+1
    // [1583] strchr::c#0 = util_wait_key::ch#4 -- vbuz1=vwum2 
    lda ch
    sta.z strchr.c
    // [1584] call strchr
    // [1588] phi from util_wait_key::@1 to strchr [phi:util_wait_key::@1->strchr]
    // [1588] phi strchr::c#4 = strchr::c#0 [phi:util_wait_key::@1->strchr#0] -- register_copy 
    // [1588] phi strchr::str#2 = strchr::str#0 [phi:util_wait_key::@1->strchr#1] -- register_copy 
    jsr strchr
    // strchr(filter, ch)
    // [1585] strchr::return#3 = strchr::return#2
    // util_wait_key::@5
    // [1586] util_wait_key::$9 = strchr::return#3
    // if(strchr(filter, ch) != NULL)
    // [1587] if(util_wait_key::$9!=0) goto util_wait_key::bank_set_bram2 -- pvoz1_neq_0_then_la1 
    lda.z util_wait_key__9
    ora.z util_wait_key__9+1
    bne bank_set_bram2
    jmp kbhit1
  .segment Data
    ch: .word 0
}
.segment Code
  // strchr
// Searches for the first occurrence of the character c (an unsigned char) in the string pointed to, by the argument str.
// - str: The memory to search
// - c: A character to search for
// Return: A pointer to the matching byte or NULL if the character does not occur in the given memory area.
// __zp($2e) void * strchr(__zp($2e) const void *str, __zp($2d) char c)
strchr: {
    .label ptr = $2e
    .label return = $2e
    .label str = $2e
    .label c = $2d
    // [1589] strchr::ptr#6 = (char *)strchr::str#2
    // [1590] phi from strchr strchr::@3 to strchr::@1 [phi:strchr/strchr::@3->strchr::@1]
    // [1590] phi strchr::ptr#2 = strchr::ptr#6 [phi:strchr/strchr::@3->strchr::@1#0] -- register_copy 
    // strchr::@1
  __b1:
    // while(*ptr)
    // [1591] if(0!=*strchr::ptr#2) goto strchr::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (ptr),y
    cmp #0
    bne __b2
    // [1592] phi from strchr::@1 to strchr::@return [phi:strchr::@1->strchr::@return]
    // [1592] phi strchr::return#2 = (void *) 0 [phi:strchr::@1->strchr::@return#0] -- pvoz1=pvoc1 
    tya
    sta.z return
    sta.z return+1
    // strchr::@return
    // }
    // [1593] return 
    rts
    // strchr::@2
  __b2:
    // if(*ptr==c)
    // [1594] if(*strchr::ptr#2!=strchr::c#4) goto strchr::@3 -- _deref_pbuz1_neq_vbuz2_then_la1 
    ldy #0
    lda (ptr),y
    cmp.z c
    bne __b3
    // strchr::@4
    // [1595] strchr::return#8 = (void *)strchr::ptr#2
    // [1592] phi from strchr::@4 to strchr::@return [phi:strchr::@4->strchr::@return]
    // [1592] phi strchr::return#2 = strchr::return#8 [phi:strchr::@4->strchr::@return#0] -- register_copy 
    rts
    // strchr::@3
  __b3:
    // ptr++;
    // [1596] strchr::ptr#1 = ++ strchr::ptr#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr
    bne !+
    inc.z ptr+1
  !:
    jmp __b1
}
  // display_info_cx16_rom
/**
 * @brief Display the ROM status of the main CX16 ROM chip.
 * 
 * @param info_status The status.
 * @param info_text The status text.
 */
// void display_info_cx16_rom(char info_status, char *info_text)
display_info_cx16_rom: {
    .label info_text = 0
    // display_info_rom(0, info_status, info_text)
    // [1598] call display_info_rom
    // [1074] phi from display_info_cx16_rom to display_info_rom [phi:display_info_cx16_rom->display_info_rom]
    // [1074] phi display_info_rom::info_text#17 = display_info_cx16_rom::info_text#0 [phi:display_info_cx16_rom->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_rom.info_text
    lda #>info_text
    sta.z display_info_rom.info_text+1
    // [1074] phi display_info_rom::rom_chip#17 = 0 [phi:display_info_cx16_rom->display_info_rom#1] -- vbum1=vbuc1 
    lda #0
    sta display_info_rom.rom_chip
    // [1074] phi display_info_rom::info_status#17 = STATUS_ISSUE [phi:display_info_cx16_rom->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_rom.info_status
    jsr display_info_rom
    // display_info_cx16_rom::@return
    // }
    // [1599] return 
    rts
}
  // strncpy
/// Copies up to n characters from the string pointed to, by src to dst.
/// In a case where the length of src is less than that of n, the remainder of dst will be padded with null bytes.
/// @param dst ? This is the pointer to the destination array where the content is to be copied.
/// @param src ? This is the string to be copied.
/// @param n ? The number of characters to be copied from source.
/// @return The destination
// char * strncpy(__zp($db) char *dst, __zp($d5) const char *src, __zp($4f) unsigned int n)
strncpy: {
    .label c = $de
    .label dst = $db
    .label i = $5e
    .label src = $d5
    .label n = $4f
    // [1601] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [1601] phi strncpy::dst#3 = strncpy::dst#8 [phi:strncpy->strncpy::@1#0] -- register_copy 
    // [1601] phi strncpy::src#3 = strncpy::src#6 [phi:strncpy->strncpy::@1#1] -- register_copy 
    // [1601] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwuz1=vwuc1 
    lda #<0
    sta.z i
    sta.z i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [1602] if(strncpy::i#2<strncpy::n#3) goto strncpy::@2 -- vwuz1_lt_vwuz2_then_la1 
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
    // [1603] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [1604] strncpy::c#0 = *strncpy::src#3 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta.z c
    // if(c)
    // [1605] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbuz1_then_la1 
    beq __b3
    // strncpy::@4
    // src++;
    // [1606] strncpy::src#0 = ++ strncpy::src#3 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [1607] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [1607] phi strncpy::src#7 = strncpy::src#3 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [1608] *strncpy::dst#3 = strncpy::c#0 -- _deref_pbuz1=vbuz2 
    lda.z c
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [1609] strncpy::dst#0 = ++ strncpy::dst#3 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [1610] strncpy::i#1 = ++ strncpy::i#2 -- vwuz1=_inc_vwuz1 
    inc.z i
    bne !+
    inc.z i+1
  !:
    // [1601] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [1601] phi strncpy::dst#3 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [1601] phi strncpy::src#3 = strncpy::src#7 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [1601] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
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
// void display_info_led(__zp($c4) char x, __zp($ce) char y, __zp($69) char tc, char bc)
display_info_led: {
    .label tc = $69
    .label y = $ce
    .label x = $c4
    // textcolor(tc)
    // [1612] textcolor::color#13 = display_info_led::tc#4 -- vbuz1=vbuz2 
    lda.z tc
    sta.z textcolor.color
    // [1613] call textcolor
    // [592] phi from display_info_led to textcolor [phi:display_info_led->textcolor]
    // [592] phi textcolor::color#18 = textcolor::color#13 [phi:display_info_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [1614] phi from display_info_led to display_info_led::@1 [phi:display_info_led->display_info_led::@1]
    // display_info_led::@1
    // bgcolor(bc)
    // [1615] call bgcolor
    // [597] phi from display_info_led::@1 to bgcolor [phi:display_info_led::@1->bgcolor]
    // [597] phi bgcolor::color#14 = BLUE [phi:display_info_led::@1->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // display_info_led::@2
    // cputcxy(x, y, VERA_CHR_UR)
    // [1616] cputcxy::x#11 = display_info_led::x#4
    // [1617] cputcxy::y#11 = display_info_led::y#4
    // [1618] call cputcxy
    // [1840] phi from display_info_led::@2 to cputcxy [phi:display_info_led::@2->cputcxy]
    // [1840] phi cputcxy::c#15 = $7c [phi:display_info_led::@2->cputcxy#0] -- vbuz1=vbuc1 
    lda #$7c
    sta.z cputcxy.c
    // [1840] phi cputcxy::y#15 = cputcxy::y#11 [phi:display_info_led::@2->cputcxy#1] -- register_copy 
    // [1840] phi cputcxy::x#15 = cputcxy::x#11 [phi:display_info_led::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [1619] phi from display_info_led::@2 to display_info_led::@3 [phi:display_info_led::@2->display_info_led::@3]
    // display_info_led::@3
    // textcolor(WHITE)
    // [1620] call textcolor
    // [592] phi from display_info_led::@3 to textcolor [phi:display_info_led::@3->textcolor]
    // [592] phi textcolor::color#18 = WHITE [phi:display_info_led::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // display_info_led::@return
    // }
    // [1621] return 
    rts
}
  // screenlayer
// --- layer management in VERA ---
// void screenlayer(char layer, __zp($e1) char mapbase, __zp($e0) char config)
screenlayer: {
    .label screenlayer__1 = $e1
    .label screenlayer__5 = $e0
    .label screenlayer__6 = $e0
    .label mapbase = $e1
    .label config = $e0
    .label y = $df
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [1622] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [1623] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [1624] *((char *)&__conio+2) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+2
    // mapbase >> 7
    // [1625] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbum1=vbuz2_ror_7 
    lda.z mapbase
    rol
    rol
    and #1
    sta screenlayer__0
    // __conio.mapbase_bank = mapbase >> 7
    // [1626] *((char *)&__conio+5) = screenlayer::$0 -- _deref_pbuc1=vbum1 
    sta __conio+5
    // (mapbase)<<1
    // [1627] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z screenlayer__1
    // MAKEWORD((mapbase)<<1,0)
    // [1628] screenlayer::$2 = screenlayer::$1 w= 0 -- vwum1=vbuz2_word_vbuc1 
    lda #0
    ldy.z screenlayer__1
    sty screenlayer__2+1
    sta screenlayer__2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [1629] *((unsigned int *)&__conio+3) = screenlayer::$2 -- _deref_pwuc1=vwum1 
    sta __conio+3
    tya
    sta __conio+3+1
    // config & VERA_LAYER_WIDTH_MASK
    // [1630] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbum1=vbuz2_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and.z config
    sta screenlayer__7
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [1631] screenlayer::$8 = screenlayer::$7 >> 4 -- vbum1=vbum1_ror_4 
    lda screenlayer__8
    lsr
    lsr
    lsr
    lsr
    sta screenlayer__8
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [1632] *((char *)&__conio+8) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbum1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+8
    // config & VERA_LAYER_HEIGHT_MASK
    // [1633] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbuz1=vbuz1_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and.z screenlayer__5
    sta.z screenlayer__5
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [1634] screenlayer::$6 = screenlayer::$5 >> 6 -- vbuz1=vbuz1_ror_6 
    lda.z screenlayer__6
    rol
    rol
    rol
    and #3
    sta.z screenlayer__6
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [1635] *((char *)&__conio+9) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+9
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [1636] screenlayer::$16 = screenlayer::$8 << 1 -- vbum1=vbum1_rol_1 
    asl screenlayer__16
    // [1637] *((unsigned int *)&__conio+$a) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbum1 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    ldy screenlayer__16
    lda VERA_LAYER_SKIP,y
    sta __conio+$a
    lda VERA_LAYER_SKIP+1,y
    sta __conio+$a+1
    // vera_dc_hscale_temp == 0x80
    // [1638] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vbom1=vbum2_eq_vbuc1 
    lda vera_dc_hscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta screenlayer__9
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [1639] screenlayer::$18 = (char)screenlayer::$9
    // [1640] screenlayer::$10 = $28 << screenlayer::$18 -- vbum1=vbuc1_rol_vbum1 
    lda #$28
    ldy screenlayer__10
    cpy #0
    beq !e+
  !:
    asl
    dey
    bne !-
  !e:
    sta screenlayer__10
    // (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [1641] screenlayer::$11 = screenlayer::$10 - 1 -- vbum1=vbum1_minus_1 
    dec screenlayer__11
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [1642] *((char *)&__conio+6) = screenlayer::$11 -- _deref_pbuc1=vbum1 
    lda screenlayer__11
    sta __conio+6
    // vera_dc_vscale_temp == 0x80
    // [1643] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vbom1=vbum2_eq_vbuc1 
    lda vera_dc_vscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta screenlayer__12
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [1644] screenlayer::$19 = (char)screenlayer::$12
    // [1645] screenlayer::$13 = $1e << screenlayer::$19 -- vbum1=vbuc1_rol_vbum1 
    lda #$1e
    ldy screenlayer__13
    cpy #0
    beq !e+
  !:
    asl
    dey
    bne !-
  !e:
    sta screenlayer__13
    // (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [1646] screenlayer::$14 = screenlayer::$13 - 1 -- vbum1=vbum1_minus_1 
    dec screenlayer__14
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [1647] *((char *)&__conio+7) = screenlayer::$14 -- _deref_pbuc1=vbum1 
    lda screenlayer__14
    sta __conio+7
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [1648] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta mapbase_offset
    lda __conio+3+1
    sta mapbase_offset+1
    // [1649] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [1649] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [1649] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [1650] if(screenlayer::y#2<=*((char *)&__conio+7)) goto screenlayer::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+7
    cmp.z y
    bcs __b2
    // screenlayer::@return
    // }
    // [1651] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [1652] screenlayer::$17 = screenlayer::y#2 << 1 -- vbum1=vbuz2_rol_1 
    lda.z y
    asl
    sta screenlayer__17
    // [1653] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbum1=vwum2 
    tay
    lda mapbase_offset
    sta __conio+$15,y
    lda mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [1654] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda mapbase_offset
    adc __conio+$a
    sta mapbase_offset
    lda mapbase_offset+1
    adc __conio+$a+1
    sta mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [1655] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [1649] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [1649] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [1649] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    VERA_LAYER_DIM: .byte $1f, $3f, $7f, $ff
    VERA_LAYER_SKIP: .word $40, $80, $100, $200
    screenlayer__0: .byte 0
    screenlayer__2: .word 0
    screenlayer__7: .byte 0
    .label screenlayer__8 = screenlayer__7
    screenlayer__9: .byte 0
    .label screenlayer__10 = screenlayer__9
    .label screenlayer__11 = screenlayer__9
    screenlayer__12: .byte 0
    .label screenlayer__13 = screenlayer__12
    .label screenlayer__14 = screenlayer__12
    .label screenlayer__16 = screenlayer__7
    screenlayer__17: .byte 0
    .label screenlayer__18 = screenlayer__9
    .label screenlayer__19 = screenlayer__12
    vera_dc_hscale_temp: .byte 0
    vera_dc_vscale_temp: .byte 0
    .label mapbase_offset = cbm_k_plot_get.return
}
.segment Code
  // cscroll
// Scroll the entire screen if the cursor is beyond the last line
cscroll: {
    // if(__conio.cursor_y>__conio.height)
    // [1656] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [1657] if(0!=((char *)&__conio+$f)[*((char *)&__conio+2)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [1658] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // [1659] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [1660] call gotoxy
    // [610] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [610] phi gotoxy::y#30 = 0 [phi:cscroll::@3->gotoxy#0] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.y
    // [610] phi gotoxy::x#30 = 0 [phi:cscroll::@3->gotoxy#1] -- vbuz1=vbuc1 
    sta.z gotoxy.x
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [1661] return 
    rts
    // [1662] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [1663] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [1664] gotoxy::y#3 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
    lda __conio+7
    sta.z gotoxy.y
    // [1665] call gotoxy
    // [610] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [610] phi gotoxy::y#30 = gotoxy::y#3 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [610] phi gotoxy::x#30 = 0 [phi:cscroll::@5->gotoxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.x
    jsr gotoxy
    // [1666] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [1667] call clearline
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
    // [1668] ((char *)&__conio+$f)[*((char *)&__conio+2)] = scroll::onoff#0 -- pbuc1_derefidx_(_deref_pbuc2)=vbuc3 
    lda #onoff
    ldy __conio+2
    sta __conio+$f,y
    // scroll::@return
    // }
    // [1669] return 
    rts
}
  // clrscr
// clears the screen and moves the cursor to the upper left-hand corner of the screen.
clrscr: {
    .label clrscr__0 = $d2
    .label clrscr__1 = $38
    // unsigned int line_text = __conio.mapbase_offset
    // [1670] clrscr::line_text#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta line_text
    lda __conio+3+1
    sta line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1671] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [1672] clrscr::$0 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clrscr__0
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1673] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [1674] clrscr::l#0 = *((char *)&__conio+9) -- vbum1=_deref_pbuc1 
    lda __conio+9
    sta l
    // [1675] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [1675] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [1675] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [1676] clrscr::$1 = byte0  clrscr::ch#0 -- vbuz1=_byte0_vwum2 
    lda ch
    sta.z clrscr__1
    // *VERA_ADDRX_L = BYTE0(ch)
    // [1677] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbuz1 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [1678] clrscr::$2 = byte1  clrscr::ch#0 -- vbum1=_byte1_vwum2 
    lda ch+1
    sta clrscr__2
    // *VERA_ADDRX_M = BYTE1(ch)
    // [1679] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth+1
    // [1680] clrscr::c#0 = *((char *)&__conio+8) + 1 -- vbum1=_deref_pbuc1_plus_1 
    lda __conio+8
    inc
    sta c
    // [1681] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [1681] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [1682] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1683] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [1684] clrscr::c#1 = -- clrscr::c#2 -- vbum1=_dec_vbum1 
    dec c
    // while(c)
    // [1685] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [1686] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda line_text
    adc __conio+$a
    sta line_text
    lda line_text+1
    adc __conio+$a+1
    sta line_text+1
    // l--;
    // [1687] clrscr::l#1 = -- clrscr::l#4 -- vbum1=_dec_vbum1 
    dec l
    // while(l)
    // [1688] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbum1_then_la1 
    lda l
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [1689] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y = 0
    // [1690] *((char *)&__conio+1) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+1
    // __conio.offset = __conio.mapbase_offset
    // [1691] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+3) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+3
    sta __conio+$13
    lda __conio+3+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [1692] return 
    rts
  .segment Data
    .label clrscr__2 = display_frame.h
    .label line_text = ch
    .label l = main.check_status_vera3_main__0
    ch: .word 0
    .label c = main.check_status_smc10_main__0
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
// void display_frame(char x0, char y0, __zp($6d) char x1, __zp($53) char y1)
display_frame: {
    .label w = $38
    .label x = $de
    .label y = $bf
    .label c = $d2
    .label x_1 = $66
    .label y_1 = $70
    .label x1 = $6d
    .label y1 = $53
    // unsigned char w = x1 - x0
    // [1694] display_frame::w#0 = display_frame::x1#16 - display_frame::x#0 -- vbuz1=vbuz2_minus_vbuz3 
    lda.z x1
    sec
    sbc.z x
    sta.z w
    // unsigned char h = y1 - y0
    // [1695] display_frame::h#0 = display_frame::y1#16 - display_frame::y#0 -- vbum1=vbuz2_minus_vbuz3 
    lda.z y1
    sec
    sbc.z y
    sta h
    // unsigned char mask = display_frame_maskxy(x, y)
    // [1696] display_frame_maskxy::x#0 = display_frame::x#0 -- vbum1=vbuz2 
    lda.z x
    sta display_frame_maskxy.x
    // [1697] display_frame_maskxy::y#0 = display_frame::y#0 -- vbum1=vbuz2 
    lda.z y
    sta display_frame_maskxy.y
    // [1698] call display_frame_maskxy
    // [2355] phi from display_frame to display_frame_maskxy [phi:display_frame->display_frame_maskxy]
    // [2355] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#0 [phi:display_frame->display_frame_maskxy#0] -- register_copy 
    // [2355] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#0 [phi:display_frame->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // unsigned char mask = display_frame_maskxy(x, y)
    // [1699] display_frame_maskxy::return#13 = display_frame_maskxy::return#12
    // display_frame::@13
    // [1700] display_frame::mask#0 = display_frame_maskxy::return#13
    // mask |= 0b0110
    // [1701] display_frame::mask#1 = display_frame::mask#0 | 6 -- vbum1=vbum1_bor_vbuc1 
    lda #6
    ora mask
    sta mask
    // unsigned char c = display_frame_char(mask)
    // [1702] display_frame_char::mask#0 = display_frame::mask#1
    // [1703] call display_frame_char
  // Add a corner.
    // [2381] phi from display_frame::@13 to display_frame_char [phi:display_frame::@13->display_frame_char]
    // [2381] phi display_frame_char::mask#10 = display_frame_char::mask#0 [phi:display_frame::@13->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // unsigned char c = display_frame_char(mask)
    // [1704] display_frame_char::return#13 = display_frame_char::return#12
    // display_frame::@14
    // [1705] display_frame::c#0 = display_frame_char::return#13
    // cputcxy(x, y, c)
    // [1706] cputcxy::x#0 = display_frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1707] cputcxy::y#0 = display_frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [1708] cputcxy::c#0 = display_frame::c#0
    // [1709] call cputcxy
    // [1840] phi from display_frame::@14 to cputcxy [phi:display_frame::@14->cputcxy]
    // [1840] phi cputcxy::c#15 = cputcxy::c#0 [phi:display_frame::@14->cputcxy#0] -- register_copy 
    // [1840] phi cputcxy::y#15 = cputcxy::y#0 [phi:display_frame::@14->cputcxy#1] -- register_copy 
    // [1840] phi cputcxy::x#15 = cputcxy::x#0 [phi:display_frame::@14->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@15
    // if(w>=2)
    // [1710] if(display_frame::w#0<2) goto display_frame::@36 -- vbuz1_lt_vbuc1_then_la1 
    lda.z w
    cmp #2
    bcs !__b36+
    jmp __b36
  !__b36:
    // display_frame::@2
    // x++;
    // [1711] display_frame::x#1 = ++ display_frame::x#0 -- vbuz1=_inc_vbuz2 
    lda.z x
    inc
    sta.z x_1
    // [1712] phi from display_frame::@2 display_frame::@21 to display_frame::@4 [phi:display_frame::@2/display_frame::@21->display_frame::@4]
    // [1712] phi display_frame::x#10 = display_frame::x#1 [phi:display_frame::@2/display_frame::@21->display_frame::@4#0] -- register_copy 
    // display_frame::@4
  __b4:
    // while(x < x1)
    // [1713] if(display_frame::x#10<display_frame::x1#16) goto display_frame::@5 -- vbuz1_lt_vbuz2_then_la1 
    lda.z x_1
    cmp.z x1
    bcs !__b5+
    jmp __b5
  !__b5:
    // [1714] phi from display_frame::@36 display_frame::@4 to display_frame::@1 [phi:display_frame::@36/display_frame::@4->display_frame::@1]
    // [1714] phi display_frame::x#24 = display_frame::x#30 [phi:display_frame::@36/display_frame::@4->display_frame::@1#0] -- register_copy 
    // display_frame::@1
  __b1:
    // display_frame_maskxy(x, y)
    // [1715] display_frame_maskxy::x#1 = display_frame::x#24 -- vbum1=vbuz2 
    lda.z x_1
    sta display_frame_maskxy.x
    // [1716] display_frame_maskxy::y#1 = display_frame::y#0 -- vbum1=vbuz2 
    lda.z y
    sta display_frame_maskxy.y
    // [1717] call display_frame_maskxy
    // [2355] phi from display_frame::@1 to display_frame_maskxy [phi:display_frame::@1->display_frame_maskxy]
    // [2355] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#1 [phi:display_frame::@1->display_frame_maskxy#0] -- register_copy 
    // [2355] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#1 [phi:display_frame::@1->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1718] display_frame_maskxy::return#14 = display_frame_maskxy::return#12
    // display_frame::@16
    // mask = display_frame_maskxy(x, y)
    // [1719] display_frame::mask#2 = display_frame_maskxy::return#14
    // mask |= 0b0011
    // [1720] display_frame::mask#3 = display_frame::mask#2 | 3 -- vbum1=vbum1_bor_vbuc1 
    lda #3
    ora mask
    sta mask
    // display_frame_char(mask)
    // [1721] display_frame_char::mask#1 = display_frame::mask#3
    // [1722] call display_frame_char
    // [2381] phi from display_frame::@16 to display_frame_char [phi:display_frame::@16->display_frame_char]
    // [2381] phi display_frame_char::mask#10 = display_frame_char::mask#1 [phi:display_frame::@16->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1723] display_frame_char::return#14 = display_frame_char::return#12
    // display_frame::@17
    // c = display_frame_char(mask)
    // [1724] display_frame::c#1 = display_frame_char::return#14
    // cputcxy(x, y, c)
    // [1725] cputcxy::x#1 = display_frame::x#24 -- vbuz1=vbuz2 
    lda.z x_1
    sta.z cputcxy.x
    // [1726] cputcxy::y#1 = display_frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [1727] cputcxy::c#1 = display_frame::c#1
    // [1728] call cputcxy
    // [1840] phi from display_frame::@17 to cputcxy [phi:display_frame::@17->cputcxy]
    // [1840] phi cputcxy::c#15 = cputcxy::c#1 [phi:display_frame::@17->cputcxy#0] -- register_copy 
    // [1840] phi cputcxy::y#15 = cputcxy::y#1 [phi:display_frame::@17->cputcxy#1] -- register_copy 
    // [1840] phi cputcxy::x#15 = cputcxy::x#1 [phi:display_frame::@17->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@18
    // if(h>=2)
    // [1729] if(display_frame::h#0<2) goto display_frame::@return -- vbum1_lt_vbuc1_then_la1 
    lda h
    cmp #2
    bcc __breturn
    // display_frame::@3
    // y++;
    // [1730] display_frame::y#1 = ++ display_frame::y#0 -- vbuz1=_inc_vbuz2 
    lda.z y
    inc
    sta.z y_1
    // [1731] phi from display_frame::@27 display_frame::@3 to display_frame::@6 [phi:display_frame::@27/display_frame::@3->display_frame::@6]
    // [1731] phi display_frame::y#10 = display_frame::y#2 [phi:display_frame::@27/display_frame::@3->display_frame::@6#0] -- register_copy 
    // display_frame::@6
  __b6:
    // while(y < y1)
    // [1732] if(display_frame::y#10<display_frame::y1#16) goto display_frame::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z y_1
    cmp.z y1
    bcc __b7
    // display_frame::@8
    // display_frame_maskxy(x, y)
    // [1733] display_frame_maskxy::x#5 = display_frame::x#0 -- vbum1=vbuz2 
    lda.z x
    sta display_frame_maskxy.x
    // [1734] display_frame_maskxy::y#5 = display_frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta display_frame_maskxy.y
    // [1735] call display_frame_maskxy
    // [2355] phi from display_frame::@8 to display_frame_maskxy [phi:display_frame::@8->display_frame_maskxy]
    // [2355] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#5 [phi:display_frame::@8->display_frame_maskxy#0] -- register_copy 
    // [2355] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#5 [phi:display_frame::@8->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1736] display_frame_maskxy::return#18 = display_frame_maskxy::return#12
    // display_frame::@28
    // mask = display_frame_maskxy(x, y)
    // [1737] display_frame::mask#10 = display_frame_maskxy::return#18
    // mask |= 0b1100
    // [1738] display_frame::mask#11 = display_frame::mask#10 | $c -- vbum1=vbum1_bor_vbuc1 
    lda #$c
    ora mask
    sta mask
    // display_frame_char(mask)
    // [1739] display_frame_char::mask#5 = display_frame::mask#11
    // [1740] call display_frame_char
    // [2381] phi from display_frame::@28 to display_frame_char [phi:display_frame::@28->display_frame_char]
    // [2381] phi display_frame_char::mask#10 = display_frame_char::mask#5 [phi:display_frame::@28->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1741] display_frame_char::return#18 = display_frame_char::return#12
    // display_frame::@29
    // c = display_frame_char(mask)
    // [1742] display_frame::c#5 = display_frame_char::return#18
    // cputcxy(x, y, c)
    // [1743] cputcxy::x#5 = display_frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1744] cputcxy::y#5 = display_frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1745] cputcxy::c#5 = display_frame::c#5
    // [1746] call cputcxy
    // [1840] phi from display_frame::@29 to cputcxy [phi:display_frame::@29->cputcxy]
    // [1840] phi cputcxy::c#15 = cputcxy::c#5 [phi:display_frame::@29->cputcxy#0] -- register_copy 
    // [1840] phi cputcxy::y#15 = cputcxy::y#5 [phi:display_frame::@29->cputcxy#1] -- register_copy 
    // [1840] phi cputcxy::x#15 = cputcxy::x#5 [phi:display_frame::@29->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@30
    // if(w>=2)
    // [1747] if(display_frame::w#0<2) goto display_frame::@10 -- vbuz1_lt_vbuc1_then_la1 
    lda.z w
    cmp #2
    bcc __b10
    // display_frame::@9
    // x++;
    // [1748] display_frame::x#4 = ++ display_frame::x#0 -- vbuz1=_inc_vbuz1 
    inc.z x
    // [1749] phi from display_frame::@35 display_frame::@9 to display_frame::@11 [phi:display_frame::@35/display_frame::@9->display_frame::@11]
    // [1749] phi display_frame::x#18 = display_frame::x#5 [phi:display_frame::@35/display_frame::@9->display_frame::@11#0] -- register_copy 
    // display_frame::@11
  __b11:
    // while(x < x1)
    // [1750] if(display_frame::x#18<display_frame::x1#16) goto display_frame::@12 -- vbuz1_lt_vbuz2_then_la1 
    lda.z x
    cmp.z x1
    bcc __b12
    // [1751] phi from display_frame::@11 display_frame::@30 to display_frame::@10 [phi:display_frame::@11/display_frame::@30->display_frame::@10]
    // [1751] phi display_frame::x#15 = display_frame::x#18 [phi:display_frame::@11/display_frame::@30->display_frame::@10#0] -- register_copy 
    // display_frame::@10
  __b10:
    // display_frame_maskxy(x, y)
    // [1752] display_frame_maskxy::x#6 = display_frame::x#15 -- vbum1=vbuz2 
    lda.z x
    sta display_frame_maskxy.x
    // [1753] display_frame_maskxy::y#6 = display_frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta display_frame_maskxy.y
    // [1754] call display_frame_maskxy
    // [2355] phi from display_frame::@10 to display_frame_maskxy [phi:display_frame::@10->display_frame_maskxy]
    // [2355] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#6 [phi:display_frame::@10->display_frame_maskxy#0] -- register_copy 
    // [2355] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#6 [phi:display_frame::@10->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1755] display_frame_maskxy::return#19 = display_frame_maskxy::return#12
    // display_frame::@31
    // mask = display_frame_maskxy(x, y)
    // [1756] display_frame::mask#12 = display_frame_maskxy::return#19
    // mask |= 0b1001
    // [1757] display_frame::mask#13 = display_frame::mask#12 | 9 -- vbum1=vbum1_bor_vbuc1 
    lda #9
    ora mask
    sta mask
    // display_frame_char(mask)
    // [1758] display_frame_char::mask#6 = display_frame::mask#13
    // [1759] call display_frame_char
    // [2381] phi from display_frame::@31 to display_frame_char [phi:display_frame::@31->display_frame_char]
    // [2381] phi display_frame_char::mask#10 = display_frame_char::mask#6 [phi:display_frame::@31->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1760] display_frame_char::return#19 = display_frame_char::return#12
    // display_frame::@32
    // c = display_frame_char(mask)
    // [1761] display_frame::c#6 = display_frame_char::return#19
    // cputcxy(x, y, c)
    // [1762] cputcxy::x#6 = display_frame::x#15 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1763] cputcxy::y#6 = display_frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1764] cputcxy::c#6 = display_frame::c#6
    // [1765] call cputcxy
    // [1840] phi from display_frame::@32 to cputcxy [phi:display_frame::@32->cputcxy]
    // [1840] phi cputcxy::c#15 = cputcxy::c#6 [phi:display_frame::@32->cputcxy#0] -- register_copy 
    // [1840] phi cputcxy::y#15 = cputcxy::y#6 [phi:display_frame::@32->cputcxy#1] -- register_copy 
    // [1840] phi cputcxy::x#15 = cputcxy::x#6 [phi:display_frame::@32->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@return
  __breturn:
    // }
    // [1766] return 
    rts
    // display_frame::@12
  __b12:
    // display_frame_maskxy(x, y)
    // [1767] display_frame_maskxy::x#7 = display_frame::x#18 -- vbum1=vbuz2 
    lda.z x
    sta display_frame_maskxy.x
    // [1768] display_frame_maskxy::y#7 = display_frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta display_frame_maskxy.y
    // [1769] call display_frame_maskxy
    // [2355] phi from display_frame::@12 to display_frame_maskxy [phi:display_frame::@12->display_frame_maskxy]
    // [2355] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#7 [phi:display_frame::@12->display_frame_maskxy#0] -- register_copy 
    // [2355] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#7 [phi:display_frame::@12->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1770] display_frame_maskxy::return#20 = display_frame_maskxy::return#12
    // display_frame::@33
    // mask = display_frame_maskxy(x, y)
    // [1771] display_frame::mask#14 = display_frame_maskxy::return#20
    // mask |= 0b0101
    // [1772] display_frame::mask#15 = display_frame::mask#14 | 5 -- vbum1=vbum1_bor_vbuc1 
    lda #5
    ora mask
    sta mask
    // display_frame_char(mask)
    // [1773] display_frame_char::mask#7 = display_frame::mask#15
    // [1774] call display_frame_char
    // [2381] phi from display_frame::@33 to display_frame_char [phi:display_frame::@33->display_frame_char]
    // [2381] phi display_frame_char::mask#10 = display_frame_char::mask#7 [phi:display_frame::@33->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1775] display_frame_char::return#20 = display_frame_char::return#12
    // display_frame::@34
    // c = display_frame_char(mask)
    // [1776] display_frame::c#7 = display_frame_char::return#20
    // cputcxy(x, y, c)
    // [1777] cputcxy::x#7 = display_frame::x#18 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1778] cputcxy::y#7 = display_frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1779] cputcxy::c#7 = display_frame::c#7
    // [1780] call cputcxy
    // [1840] phi from display_frame::@34 to cputcxy [phi:display_frame::@34->cputcxy]
    // [1840] phi cputcxy::c#15 = cputcxy::c#7 [phi:display_frame::@34->cputcxy#0] -- register_copy 
    // [1840] phi cputcxy::y#15 = cputcxy::y#7 [phi:display_frame::@34->cputcxy#1] -- register_copy 
    // [1840] phi cputcxy::x#15 = cputcxy::x#7 [phi:display_frame::@34->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@35
    // x++;
    // [1781] display_frame::x#5 = ++ display_frame::x#18 -- vbuz1=_inc_vbuz1 
    inc.z x
    jmp __b11
    // display_frame::@7
  __b7:
    // display_frame_maskxy(x0, y)
    // [1782] display_frame_maskxy::x#3 = display_frame::x#0 -- vbum1=vbuz2 
    lda.z x
    sta display_frame_maskxy.x
    // [1783] display_frame_maskxy::y#3 = display_frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta display_frame_maskxy.y
    // [1784] call display_frame_maskxy
    // [2355] phi from display_frame::@7 to display_frame_maskxy [phi:display_frame::@7->display_frame_maskxy]
    // [2355] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#3 [phi:display_frame::@7->display_frame_maskxy#0] -- register_copy 
    // [2355] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#3 [phi:display_frame::@7->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x0, y)
    // [1785] display_frame_maskxy::return#16 = display_frame_maskxy::return#12
    // display_frame::@22
    // mask = display_frame_maskxy(x0, y)
    // [1786] display_frame::mask#6 = display_frame_maskxy::return#16
    // mask |= 0b1010
    // [1787] display_frame::mask#7 = display_frame::mask#6 | $a -- vbum1=vbum1_bor_vbuc1 
    lda #$a
    ora mask
    sta mask
    // display_frame_char(mask)
    // [1788] display_frame_char::mask#3 = display_frame::mask#7
    // [1789] call display_frame_char
    // [2381] phi from display_frame::@22 to display_frame_char [phi:display_frame::@22->display_frame_char]
    // [2381] phi display_frame_char::mask#10 = display_frame_char::mask#3 [phi:display_frame::@22->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1790] display_frame_char::return#16 = display_frame_char::return#12
    // display_frame::@23
    // c = display_frame_char(mask)
    // [1791] display_frame::c#3 = display_frame_char::return#16
    // cputcxy(x0, y, c)
    // [1792] cputcxy::x#3 = display_frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1793] cputcxy::y#3 = display_frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1794] cputcxy::c#3 = display_frame::c#3
    // [1795] call cputcxy
    // [1840] phi from display_frame::@23 to cputcxy [phi:display_frame::@23->cputcxy]
    // [1840] phi cputcxy::c#15 = cputcxy::c#3 [phi:display_frame::@23->cputcxy#0] -- register_copy 
    // [1840] phi cputcxy::y#15 = cputcxy::y#3 [phi:display_frame::@23->cputcxy#1] -- register_copy 
    // [1840] phi cputcxy::x#15 = cputcxy::x#3 [phi:display_frame::@23->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@24
    // display_frame_maskxy(x1, y)
    // [1796] display_frame_maskxy::x#4 = display_frame::x1#16 -- vbum1=vbuz2 
    lda.z x1
    sta display_frame_maskxy.x
    // [1797] display_frame_maskxy::y#4 = display_frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta display_frame_maskxy.y
    // [1798] call display_frame_maskxy
    // [2355] phi from display_frame::@24 to display_frame_maskxy [phi:display_frame::@24->display_frame_maskxy]
    // [2355] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#4 [phi:display_frame::@24->display_frame_maskxy#0] -- register_copy 
    // [2355] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#4 [phi:display_frame::@24->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x1, y)
    // [1799] display_frame_maskxy::return#17 = display_frame_maskxy::return#12
    // display_frame::@25
    // mask = display_frame_maskxy(x1, y)
    // [1800] display_frame::mask#8 = display_frame_maskxy::return#17
    // mask |= 0b1010
    // [1801] display_frame::mask#9 = display_frame::mask#8 | $a -- vbum1=vbum1_bor_vbuc1 
    lda #$a
    ora mask
    sta mask
    // display_frame_char(mask)
    // [1802] display_frame_char::mask#4 = display_frame::mask#9
    // [1803] call display_frame_char
    // [2381] phi from display_frame::@25 to display_frame_char [phi:display_frame::@25->display_frame_char]
    // [2381] phi display_frame_char::mask#10 = display_frame_char::mask#4 [phi:display_frame::@25->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1804] display_frame_char::return#17 = display_frame_char::return#12
    // display_frame::@26
    // c = display_frame_char(mask)
    // [1805] display_frame::c#4 = display_frame_char::return#17
    // cputcxy(x1, y, c)
    // [1806] cputcxy::x#4 = display_frame::x1#16 -- vbuz1=vbuz2 
    lda.z x1
    sta.z cputcxy.x
    // [1807] cputcxy::y#4 = display_frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1808] cputcxy::c#4 = display_frame::c#4
    // [1809] call cputcxy
    // [1840] phi from display_frame::@26 to cputcxy [phi:display_frame::@26->cputcxy]
    // [1840] phi cputcxy::c#15 = cputcxy::c#4 [phi:display_frame::@26->cputcxy#0] -- register_copy 
    // [1840] phi cputcxy::y#15 = cputcxy::y#4 [phi:display_frame::@26->cputcxy#1] -- register_copy 
    // [1840] phi cputcxy::x#15 = cputcxy::x#4 [phi:display_frame::@26->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@27
    // y++;
    // [1810] display_frame::y#2 = ++ display_frame::y#10 -- vbuz1=_inc_vbuz1 
    inc.z y_1
    jmp __b6
    // display_frame::@5
  __b5:
    // display_frame_maskxy(x, y)
    // [1811] display_frame_maskxy::x#2 = display_frame::x#10 -- vbum1=vbuz2 
    lda.z x_1
    sta display_frame_maskxy.x
    // [1812] display_frame_maskxy::y#2 = display_frame::y#0 -- vbum1=vbuz2 
    lda.z y
    sta display_frame_maskxy.y
    // [1813] call display_frame_maskxy
    // [2355] phi from display_frame::@5 to display_frame_maskxy [phi:display_frame::@5->display_frame_maskxy]
    // [2355] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#2 [phi:display_frame::@5->display_frame_maskxy#0] -- register_copy 
    // [2355] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#2 [phi:display_frame::@5->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1814] display_frame_maskxy::return#15 = display_frame_maskxy::return#12
    // display_frame::@19
    // mask = display_frame_maskxy(x, y)
    // [1815] display_frame::mask#4 = display_frame_maskxy::return#15
    // mask |= 0b0101
    // [1816] display_frame::mask#5 = display_frame::mask#4 | 5 -- vbum1=vbum1_bor_vbuc1 
    lda #5
    ora mask
    sta mask
    // display_frame_char(mask)
    // [1817] display_frame_char::mask#2 = display_frame::mask#5
    // [1818] call display_frame_char
    // [2381] phi from display_frame::@19 to display_frame_char [phi:display_frame::@19->display_frame_char]
    // [2381] phi display_frame_char::mask#10 = display_frame_char::mask#2 [phi:display_frame::@19->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1819] display_frame_char::return#15 = display_frame_char::return#12
    // display_frame::@20
    // c = display_frame_char(mask)
    // [1820] display_frame::c#2 = display_frame_char::return#15
    // cputcxy(x, y, c)
    // [1821] cputcxy::x#2 = display_frame::x#10 -- vbuz1=vbuz2 
    lda.z x_1
    sta.z cputcxy.x
    // [1822] cputcxy::y#2 = display_frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [1823] cputcxy::c#2 = display_frame::c#2
    // [1824] call cputcxy
    // [1840] phi from display_frame::@20 to cputcxy [phi:display_frame::@20->cputcxy]
    // [1840] phi cputcxy::c#15 = cputcxy::c#2 [phi:display_frame::@20->cputcxy#0] -- register_copy 
    // [1840] phi cputcxy::y#15 = cputcxy::y#2 [phi:display_frame::@20->cputcxy#1] -- register_copy 
    // [1840] phi cputcxy::x#15 = cputcxy::x#2 [phi:display_frame::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@21
    // x++;
    // [1825] display_frame::x#2 = ++ display_frame::x#10 -- vbuz1=_inc_vbuz1 
    inc.z x_1
    jmp __b4
    // display_frame::@36
  __b36:
    // [1826] display_frame::x#30 = display_frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z x_1
    jmp __b1
  .segment Data
    h: .byte 0
    .label mask = display_frame_maskxy.return
}
.segment Code
  // cputs
// Output a NUL-terminated string at the current cursor position
// void cputs(__zp($d9) const char *s)
cputs: {
    .label c = $dd
    .label s = $d9
    // [1828] phi from cputs cputs::@2 to cputs::@1 [phi:cputs/cputs::@2->cputs::@1]
    // [1828] phi cputs::s#2 = cputs::s#1 [phi:cputs/cputs::@2->cputs::@1#0] -- register_copy 
    // cputs::@1
  __b1:
    // while(c=*s++)
    // [1829] cputs::c#1 = *cputs::s#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta.z c
    // [1830] cputs::s#0 = ++ cputs::s#2 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [1831] if(0!=cputs::c#1) goto cputs::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // cputs::@return
    // }
    // [1832] return 
    rts
    // cputs::@2
  __b2:
    // cputc(c)
    // [1833] stackpush(char) = cputs::c#1 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [1834] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
}
  // wherex
// Return the x position of the cursor
wherex: {
    .label return = $6a
    .label return_1 = $ea
    .label return_4 = $f1
    // return __conio.cursor_x;
    // [1836] wherex::return#0 = *((char *)&__conio) -- vbuz1=_deref_pbuc1 
    lda __conio
    sta.z return
    // wherex::@return
    // }
    // [1837] return 
    rts
  .segment Data
    .label return_2 = rom_read_byte.return
    .label return_3 = rom_detect.rom_detect__24
}
.segment Code
  // wherey
// Return the y position of the cursor
wherey: {
    .label return = $2c
    .label return_1 = $e8
    // return __conio.cursor_y;
    // [1838] wherey::return#0 = *((char *)&__conio+1) -- vbuz1=_deref_pbuc1 
    lda __conio+1
    sta.z return
    // wherey::@return
    // }
    // [1839] return 
    rts
  .segment Data
    .label return_2 = rom_detect.rom_detect__9
    .label return_3 = rom_detect.rom_detect__21
    .label return_4 = smc_flash.smc_byte_upload
}
.segment Code
  // cputcxy
// Move cursor and output one character
// Same as "gotoxy (x, y); cputc (c);"
// void cputcxy(__zp($c4) char x, __zp($ce) char y, __zp($d2) char c)
cputcxy: {
    .label x = $c4
    .label y = $ce
    .label c = $d2
    // gotoxy(x, y)
    // [1841] gotoxy::x#0 = cputcxy::x#15 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1842] gotoxy::y#0 = cputcxy::y#15 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1843] call gotoxy
    // [610] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [610] phi gotoxy::y#30 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [610] phi gotoxy::x#30 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [1844] stackpush(char) = cputcxy::c#15 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [1845] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [1847] return 
    rts
}
  // display_smc_led
/**
 * @brief Print SMC led above the SMC chip.
 * 
 * @param c Led color
 */
// void display_smc_led(__zp($69) char c)
display_smc_led: {
    .label c = $69
    // display_chip_led(CHIP_SMC_X+1, CHIP_SMC_Y, CHIP_SMC_W, c, BLUE)
    // [1849] display_chip_led::tc#0 = display_smc_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_chip_led.tc
    // [1850] call display_chip_led
    // [2396] phi from display_smc_led to display_chip_led [phi:display_smc_led->display_chip_led]
    // [2396] phi display_chip_led::w#7 = 5 [phi:display_smc_led->display_chip_led#0] -- vbuz1=vbuc1 
    lda #5
    sta.z display_chip_led.w
    // [2396] phi display_chip_led::x#7 = 1+1 [phi:display_smc_led->display_chip_led#1] -- vbuz1=vbuc1 
    lda #1+1
    sta.z display_chip_led.x
    // [2396] phi display_chip_led::tc#3 = display_chip_led::tc#0 [phi:display_smc_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_smc_led::@1
    // display_info_led(INFO_X-2, INFO_Y, c, BLUE)
    // [1851] display_info_led::tc#0 = display_smc_led::c#2
    // [1852] call display_info_led
    // [1611] phi from display_smc_led::@1 to display_info_led [phi:display_smc_led::@1->display_info_led]
    // [1611] phi display_info_led::y#4 = $11 [phi:display_smc_led::@1->display_info_led#0] -- vbuz1=vbuc1 
    lda #$11
    sta.z display_info_led.y
    // [1611] phi display_info_led::x#4 = 4-2 [phi:display_smc_led::@1->display_info_led#1] -- vbuz1=vbuc1 
    lda #4-2
    sta.z display_info_led.x
    // [1611] phi display_info_led::tc#4 = display_info_led::tc#0 [phi:display_smc_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_smc_led::@return
    // }
    // [1853] return 
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
// void display_print_chip(__zp($be) char x, char y, __zp($64) char w, __mem() char *text)
display_print_chip: {
    .label y = 3+2+1+1+1+1+1+1+1+1
    .label text_1 = $44
    .label x = $be
    .label text_2 = $55
    .label text_3 = $75
    .label w = $64
    // display_chip_line(x, y++, w, *text++)
    // [1855] display_chip_line::x#0 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1856] display_chip_line::w#0 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1857] display_chip_line::c#0 = *display_print_chip::text#11 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_2),y
    sta.z display_chip_line.c
    // [1858] call display_chip_line
    // [2414] phi from display_print_chip to display_chip_line [phi:display_print_chip->display_chip_line]
    // [2414] phi display_chip_line::c#15 = display_chip_line::c#0 [phi:display_print_chip->display_chip_line#0] -- register_copy 
    // [2414] phi display_chip_line::w#10 = display_chip_line::w#0 [phi:display_print_chip->display_chip_line#1] -- register_copy 
    // [2414] phi display_chip_line::y#16 = 3+2 [phi:display_print_chip->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2
    sta.z display_chip_line.y
    // [2414] phi display_chip_line::x#16 = display_chip_line::x#0 [phi:display_print_chip->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@1
    // display_chip_line(x, y++, w, *text++);
    // [1859] display_print_chip::text#0 = ++ display_print_chip::text#11 -- pbum1=_inc_pbuz2 
    clc
    lda.z text_2
    adc #1
    sta text
    lda.z text_2+1
    adc #0
    sta text+1
    // display_chip_line(x, y++, w, *text++)
    // [1860] display_chip_line::x#1 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1861] display_chip_line::w#1 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1862] display_chip_line::c#1 = *display_print_chip::text#0 -- vbuz1=_deref_pbum2 
    ldy text
    sty.z $fe
    ldy text+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta.z display_chip_line.c
    // [1863] call display_chip_line
    // [2414] phi from display_print_chip::@1 to display_chip_line [phi:display_print_chip::@1->display_chip_line]
    // [2414] phi display_chip_line::c#15 = display_chip_line::c#1 [phi:display_print_chip::@1->display_chip_line#0] -- register_copy 
    // [2414] phi display_chip_line::w#10 = display_chip_line::w#1 [phi:display_print_chip::@1->display_chip_line#1] -- register_copy 
    // [2414] phi display_chip_line::y#16 = ++3+2 [phi:display_print_chip::@1->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1
    sta.z display_chip_line.y
    // [2414] phi display_chip_line::x#16 = display_chip_line::x#1 [phi:display_print_chip::@1->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@2
    // display_chip_line(x, y++, w, *text++);
    // [1864] display_print_chip::text#1 = ++ display_print_chip::text#0 -- pbuz1=_inc_pbum2 
    clc
    lda text
    adc #1
    sta.z text_1
    lda text+1
    adc #0
    sta.z text_1+1
    // display_chip_line(x, y++, w, *text++)
    // [1865] display_chip_line::x#2 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1866] display_chip_line::w#2 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1867] display_chip_line::c#2 = *display_print_chip::text#1 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_1),y
    sta.z display_chip_line.c
    // [1868] call display_chip_line
    // [2414] phi from display_print_chip::@2 to display_chip_line [phi:display_print_chip::@2->display_chip_line]
    // [2414] phi display_chip_line::c#15 = display_chip_line::c#2 [phi:display_print_chip::@2->display_chip_line#0] -- register_copy 
    // [2414] phi display_chip_line::w#10 = display_chip_line::w#2 [phi:display_print_chip::@2->display_chip_line#1] -- register_copy 
    // [2414] phi display_chip_line::y#16 = ++++3+2 [phi:display_print_chip::@2->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1
    sta.z display_chip_line.y
    // [2414] phi display_chip_line::x#16 = display_chip_line::x#2 [phi:display_print_chip::@2->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@3
    // display_chip_line(x, y++, w, *text++);
    // [1869] display_print_chip::text#15 = ++ display_print_chip::text#1 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_1
    adc #1
    sta.z text_3
    lda.z text_1+1
    adc #0
    sta.z text_3+1
    // display_chip_line(x, y++, w, *text++)
    // [1870] display_chip_line::x#3 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1871] display_chip_line::w#3 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1872] display_chip_line::c#3 = *display_print_chip::text#15 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_3),y
    sta.z display_chip_line.c
    // [1873] call display_chip_line
    // [2414] phi from display_print_chip::@3 to display_chip_line [phi:display_print_chip::@3->display_chip_line]
    // [2414] phi display_chip_line::c#15 = display_chip_line::c#3 [phi:display_print_chip::@3->display_chip_line#0] -- register_copy 
    // [2414] phi display_chip_line::w#10 = display_chip_line::w#3 [phi:display_print_chip::@3->display_chip_line#1] -- register_copy 
    // [2414] phi display_chip_line::y#16 = ++++++3+2 [phi:display_print_chip::@3->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1
    sta.z display_chip_line.y
    // [2414] phi display_chip_line::x#16 = display_chip_line::x#3 [phi:display_print_chip::@3->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@4
    // display_chip_line(x, y++, w, *text++);
    // [1874] display_print_chip::text#16 = ++ display_print_chip::text#15 -- pbum1=_inc_pbuz2 
    clc
    lda.z text_3
    adc #1
    sta text_4
    lda.z text_3+1
    adc #0
    sta text_4+1
    // display_chip_line(x, y++, w, *text++)
    // [1875] display_chip_line::x#4 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1876] display_chip_line::w#4 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1877] display_chip_line::c#4 = *display_print_chip::text#16 -- vbuz1=_deref_pbum2 
    ldy text_4
    sty.z $fe
    ldy text_4+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta.z display_chip_line.c
    // [1878] call display_chip_line
    // [2414] phi from display_print_chip::@4 to display_chip_line [phi:display_print_chip::@4->display_chip_line]
    // [2414] phi display_chip_line::c#15 = display_chip_line::c#4 [phi:display_print_chip::@4->display_chip_line#0] -- register_copy 
    // [2414] phi display_chip_line::w#10 = display_chip_line::w#4 [phi:display_print_chip::@4->display_chip_line#1] -- register_copy 
    // [2414] phi display_chip_line::y#16 = ++++++++3+2 [phi:display_print_chip::@4->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1
    sta.z display_chip_line.y
    // [2414] phi display_chip_line::x#16 = display_chip_line::x#4 [phi:display_print_chip::@4->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@5
    // display_chip_line(x, y++, w, *text++);
    // [1879] display_print_chip::text#17 = ++ display_print_chip::text#16 -- pbum1=_inc_pbum2 
    clc
    lda text_4
    adc #1
    sta text_5
    lda text_4+1
    adc #0
    sta text_5+1
    // display_chip_line(x, y++, w, *text++)
    // [1880] display_chip_line::x#5 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1881] display_chip_line::w#5 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1882] display_chip_line::c#5 = *display_print_chip::text#17 -- vbuz1=_deref_pbum2 
    ldy text_5
    sty.z $fe
    ldy text_5+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta.z display_chip_line.c
    // [1883] call display_chip_line
    // [2414] phi from display_print_chip::@5 to display_chip_line [phi:display_print_chip::@5->display_chip_line]
    // [2414] phi display_chip_line::c#15 = display_chip_line::c#5 [phi:display_print_chip::@5->display_chip_line#0] -- register_copy 
    // [2414] phi display_chip_line::w#10 = display_chip_line::w#5 [phi:display_print_chip::@5->display_chip_line#1] -- register_copy 
    // [2414] phi display_chip_line::y#16 = ++++++++++3+2 [phi:display_print_chip::@5->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1+1
    sta.z display_chip_line.y
    // [2414] phi display_chip_line::x#16 = display_chip_line::x#5 [phi:display_print_chip::@5->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@6
    // display_chip_line(x, y++, w, *text++);
    // [1884] display_print_chip::text#18 = ++ display_print_chip::text#17 -- pbum1=_inc_pbum2 
    clc
    lda text_5
    adc #1
    sta text_6
    lda text_5+1
    adc #0
    sta text_6+1
    // display_chip_line(x, y++, w, *text++)
    // [1885] display_chip_line::x#6 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1886] display_chip_line::w#6 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1887] display_chip_line::c#6 = *display_print_chip::text#18 -- vbuz1=_deref_pbum2 
    ldy text_6
    sty.z $fe
    ldy text_6+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta.z display_chip_line.c
    // [1888] call display_chip_line
    // [2414] phi from display_print_chip::@6 to display_chip_line [phi:display_print_chip::@6->display_chip_line]
    // [2414] phi display_chip_line::c#15 = display_chip_line::c#6 [phi:display_print_chip::@6->display_chip_line#0] -- register_copy 
    // [2414] phi display_chip_line::w#10 = display_chip_line::w#6 [phi:display_print_chip::@6->display_chip_line#1] -- register_copy 
    // [2414] phi display_chip_line::y#16 = ++++++++++++3+2 [phi:display_print_chip::@6->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1+1+1
    sta.z display_chip_line.y
    // [2414] phi display_chip_line::x#16 = display_chip_line::x#6 [phi:display_print_chip::@6->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@7
    // display_chip_line(x, y++, w, *text++);
    // [1889] display_print_chip::text#19 = ++ display_print_chip::text#18 -- pbum1=_inc_pbum1 
    inc text_6
    bne !+
    inc text_6+1
  !:
    // display_chip_line(x, y++, w, *text++)
    // [1890] display_chip_line::x#7 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1891] display_chip_line::w#7 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1892] display_chip_line::c#7 = *display_print_chip::text#19 -- vbuz1=_deref_pbum2 
    ldy text_6
    sty.z $fe
    ldy text_6+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta.z display_chip_line.c
    // [1893] call display_chip_line
    // [2414] phi from display_print_chip::@7 to display_chip_line [phi:display_print_chip::@7->display_chip_line]
    // [2414] phi display_chip_line::c#15 = display_chip_line::c#7 [phi:display_print_chip::@7->display_chip_line#0] -- register_copy 
    // [2414] phi display_chip_line::w#10 = display_chip_line::w#7 [phi:display_print_chip::@7->display_chip_line#1] -- register_copy 
    // [2414] phi display_chip_line::y#16 = ++++++++++++++3+2 [phi:display_print_chip::@7->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1+1+1+1
    sta.z display_chip_line.y
    // [2414] phi display_chip_line::x#16 = display_chip_line::x#7 [phi:display_print_chip::@7->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@8
    // display_chip_end(x, y++, w)
    // [1894] display_chip_end::x#0 = display_print_chip::x#10
    // [1895] display_chip_end::w#0 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_end.w
    // [1896] call display_chip_end
    jsr display_chip_end
    // display_print_chip::@return
    // }
    // [1897] return 
    rts
  .segment Data
    text: .word 0
    .label text_4 = rom_read_byte.rom_ptr1_rom_read_byte__2
    .label text_5 = fopen.fopen__28
    .label text_6 = fopen.fopen__11
}
.segment Code
  // display_vera_led
/**
 * @brief Print VERA led above the VERA chip.
 * 
 * @param c Led color
 */
// void display_vera_led(__zp($6e) char c)
display_vera_led: {
    .label c = $6e
    // display_chip_led(CHIP_VERA_X+1, CHIP_VERA_Y, CHIP_VERA_W, c, BLUE)
    // [1899] display_chip_led::tc#1 = display_vera_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_chip_led.tc
    // [1900] call display_chip_led
    // [2396] phi from display_vera_led to display_chip_led [phi:display_vera_led->display_chip_led]
    // [2396] phi display_chip_led::w#7 = 8 [phi:display_vera_led->display_chip_led#0] -- vbuz1=vbuc1 
    lda #8
    sta.z display_chip_led.w
    // [2396] phi display_chip_led::x#7 = 9+1 [phi:display_vera_led->display_chip_led#1] -- vbuz1=vbuc1 
    lda #9+1
    sta.z display_chip_led.x
    // [2396] phi display_chip_led::tc#3 = display_chip_led::tc#1 [phi:display_vera_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_vera_led::@1
    // display_info_led(INFO_X-2, INFO_Y+1, c, BLUE)
    // [1901] display_info_led::tc#1 = display_vera_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_info_led.tc
    // [1902] call display_info_led
    // [1611] phi from display_vera_led::@1 to display_info_led [phi:display_vera_led::@1->display_info_led]
    // [1611] phi display_info_led::y#4 = $11+1 [phi:display_vera_led::@1->display_info_led#0] -- vbuz1=vbuc1 
    lda #$11+1
    sta.z display_info_led.y
    // [1611] phi display_info_led::x#4 = 4-2 [phi:display_vera_led::@1->display_info_led#1] -- vbuz1=vbuc1 
    lda #4-2
    sta.z display_info_led.x
    // [1611] phi display_info_led::tc#4 = display_info_led::tc#1 [phi:display_vera_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_vera_led::@return
    // }
    // [1903] return 
    rts
}
  // strcpy
// Copies the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcpy(char *destination, char *source)
strcpy: {
    // [1905] phi from strcpy to strcpy::@1 [phi:strcpy->strcpy::@1]
    // [1905] phi strcpy::dst#2 = display_chip_rom::rom [phi:strcpy->strcpy::@1#0] -- pbum1=pbuc1 
    lda #<display_chip_rom.rom
    sta dst
    lda #>display_chip_rom.rom
    sta dst+1
    // [1905] phi strcpy::src#2 = display_chip_rom::source [phi:strcpy->strcpy::@1#1] -- pbum1=pbuc1 
    lda #<display_chip_rom.source
    sta src
    lda #>display_chip_rom.source
    sta src+1
    // strcpy::@1
  __b1:
    // while(*src)
    // [1906] if(0!=*strcpy::src#2) goto strcpy::@2 -- 0_neq__deref_pbum1_then_la1 
    ldy src
    sty.z $fe
    ldy src+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    cmp #0
    bne __b2
    // strcpy::@3
    // *dst = 0
    // [1907] *strcpy::dst#2 = 0 -- _deref_pbum1=vbuc1 
    tya
    ldy dst
    sty.z $fe
    ldy dst+1
    sty.z $ff
    tay
    sta ($fe),y
    // strcpy::@return
    // }
    // [1908] return 
    rts
    // strcpy::@2
  __b2:
    // *dst++ = *src++
    // [1909] *strcpy::dst#2 = *strcpy::src#2 -- _deref_pbum1=_deref_pbum2 
    ldy src
    sty.z $fe
    ldy src+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    ldy dst
    sty.z $fe
    ldy dst+1
    sty.z $ff
    ldy #0
    sta ($fe),y
    // *dst++ = *src++;
    // [1910] strcpy::dst#1 = ++ strcpy::dst#2 -- pbum1=_inc_pbum1 
    inc dst
    bne !+
    inc dst+1
  !:
    // [1911] strcpy::src#1 = ++ strcpy::src#2 -- pbum1=_inc_pbum1 
    inc src
    bne !+
    inc src+1
  !:
    // [1905] phi from strcpy::@2 to strcpy::@1 [phi:strcpy::@2->strcpy::@1]
    // [1905] phi strcpy::dst#2 = strcpy::dst#1 [phi:strcpy::@2->strcpy::@1#0] -- register_copy 
    // [1905] phi strcpy::src#2 = strcpy::src#1 [phi:strcpy::@2->strcpy::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    dst: .word 0
    src: .word 0
}
.segment Code
  // strcat
// Concatenates the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcat(char *destination, __zp($d9) char *source)
strcat: {
    .label strcat__0 = $55
    .label dst = $55
    .label src = $d9
    .label source = $d9
    // strlen(destination)
    // [1913] call strlen
    // [1944] phi from strcat to strlen [phi:strcat->strlen]
    // [1944] phi strlen::str#8 = display_chip_rom::rom [phi:strcat->strlen#0] -- pbuz1=pbuc1 
    lda #<display_chip_rom.rom
    sta.z strlen.str
    lda #>display_chip_rom.rom
    sta.z strlen.str+1
    jsr strlen
    // strlen(destination)
    // [1914] strlen::return#0 = strlen::len#2
    // strcat::@4
    // [1915] strcat::$0 = strlen::return#0
    // char* dst = destination + strlen(destination)
    // [1916] strcat::dst#0 = display_chip_rom::rom + strcat::$0 -- pbuz1=pbuc1_plus_vwuz1 
    lda.z dst
    clc
    adc #<display_chip_rom.rom
    sta.z dst
    lda.z dst+1
    adc #>display_chip_rom.rom
    sta.z dst+1
    // [1917] phi from strcat::@2 strcat::@4 to strcat::@1 [phi:strcat::@2/strcat::@4->strcat::@1]
    // [1917] phi strcat::dst#2 = strcat::dst#1 [phi:strcat::@2/strcat::@4->strcat::@1#0] -- register_copy 
    // [1917] phi strcat::src#2 = strcat::src#1 [phi:strcat::@2/strcat::@4->strcat::@1#1] -- register_copy 
    // strcat::@1
  __b1:
    // while(*src)
    // [1918] if(0!=*strcat::src#2) goto strcat::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcat::@3
    // *dst = 0
    // [1919] *strcat::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcat::@return
    // }
    // [1920] return 
    rts
    // strcat::@2
  __b2:
    // *dst++ = *src++
    // [1921] *strcat::dst#2 = *strcat::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [1922] strcat::dst#1 = ++ strcat::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [1923] strcat::src#1 = ++ strcat::src#2 -- pbuz1=_inc_pbuz1 
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
// void display_rom_led(__zp($37) char chip, __zp($5c) char c)
display_rom_led: {
    .label display_rom_led__0 = $67
    .label chip = $37
    .label c = $5c
    .label display_rom_led__7 = $67
    .label display_rom_led__8 = $67
    // chip*6
    // [1925] display_rom_led::$7 = display_rom_led::chip#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z chip
    asl
    sta.z display_rom_led__7
    // [1926] display_rom_led::$8 = display_rom_led::$7 + display_rom_led::chip#2 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z display_rom_led__8
    clc
    adc.z chip
    sta.z display_rom_led__8
    // CHIP_ROM_X+chip*6
    // [1927] display_rom_led::$0 = display_rom_led::$8 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_rom_led__0
    // display_chip_led(CHIP_ROM_X+chip*6+1, CHIP_ROM_Y, CHIP_ROM_W, c, BLUE)
    // [1928] display_chip_led::x#3 = display_rom_led::$0 + $14+1 -- vbuz1=vbuz1_plus_vbuc1 
    lda #$14+1
    clc
    adc.z display_chip_led.x
    sta.z display_chip_led.x
    // [1929] display_chip_led::tc#2 = display_rom_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_chip_led.tc
    // [1930] call display_chip_led
    // [2396] phi from display_rom_led to display_chip_led [phi:display_rom_led->display_chip_led]
    // [2396] phi display_chip_led::w#7 = 3 [phi:display_rom_led->display_chip_led#0] -- vbuz1=vbuc1 
    lda #3
    sta.z display_chip_led.w
    // [2396] phi display_chip_led::x#7 = display_chip_led::x#3 [phi:display_rom_led->display_chip_led#1] -- register_copy 
    // [2396] phi display_chip_led::tc#3 = display_chip_led::tc#2 [phi:display_rom_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_rom_led::@1
    // display_info_led(INFO_X-2, INFO_Y+chip+2, c, BLUE)
    // [1931] display_info_led::y#2 = display_rom_led::chip#2 + $11+2 -- vbuz1=vbuz2_plus_vbuc1 
    lda #$11+2
    clc
    adc.z chip
    sta.z display_info_led.y
    // [1932] display_info_led::tc#2 = display_rom_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_info_led.tc
    // [1933] call display_info_led
    // [1611] phi from display_rom_led::@1 to display_info_led [phi:display_rom_led::@1->display_info_led]
    // [1611] phi display_info_led::y#4 = display_info_led::y#2 [phi:display_rom_led::@1->display_info_led#0] -- register_copy 
    // [1611] phi display_info_led::x#4 = 4-2 [phi:display_rom_led::@1->display_info_led#1] -- vbuz1=vbuc1 
    lda #4-2
    sta.z display_info_led.x
    // [1611] phi display_info_led::tc#4 = display_info_led::tc#2 [phi:display_rom_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_rom_led::@return
    // }
    // [1934] return 
    rts
}
  // display_progress_line
/**
 * @brief Print one line of text in the progress frame at a line position.
 * 
 * @param line The start line, counting from 0.
 * @param text The text to be displayed.
 */
// void display_progress_line(__mem() char line, __zp($b1) char *text)
display_progress_line: {
    .label text = $b1
    // cputsxy(PROGRESS_X, PROGRESS_Y+line, text)
    // [1935] cputsxy::y#0 = PROGRESS_Y + display_progress_line::line#0 -- vbum1=vbuc1_plus_vbum1 
    lda #PROGRESS_Y
    clc
    adc cputsxy.y
    sta cputsxy.y
    // [1936] cputsxy::s#0 = display_progress_line::text#0
    // [1937] call cputsxy
    // [697] phi from display_progress_line to cputsxy [phi:display_progress_line->cputsxy]
    // [697] phi cputsxy::s#4 = cputsxy::s#0 [phi:display_progress_line->cputsxy#0] -- register_copy 
    // [697] phi cputsxy::y#4 = cputsxy::y#0 [phi:display_progress_line->cputsxy#1] -- register_copy 
    // [697] phi cputsxy::x#4 = PROGRESS_X [phi:display_progress_line->cputsxy#2] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z cputsxy.x
    jsr cputsxy
    // display_progress_line::@return
    // }
    // [1938] return 
    rts
  .segment Data
    .label line = main.check_status_smc2_main__0
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
// __zp($b1) unsigned int cx16_k_i2c_read_byte(__mem() volatile char device, __mem() volatile char offset)
cx16_k_i2c_read_byte: {
    .label return = $b1
    .label return_1 = $62
    // unsigned int result
    // [1939] cx16_k_i2c_read_byte::result = 0 -- vwum1=vwuc1 
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
    // [1941] cx16_k_i2c_read_byte::return#0 = cx16_k_i2c_read_byte::result -- vwuz1=vwum2 
    sta.z return
    lda result+1
    sta.z return+1
    // cx16_k_i2c_read_byte::@return
    // }
    // [1942] cx16_k_i2c_read_byte::return#1 = cx16_k_i2c_read_byte::return#0
    // [1943] return 
    rts
  .segment Data
    device: .byte 0
    offset: .byte 0
    result: .word 0
    .label return_2 = rom_flash.equal_bytes_1
    .label return_3 = display_print_chip.text
}
.segment Code
  // strlen
// Computes the length of the string str up to but not including the terminating null character.
// __zp($55) unsigned int strlen(__zp($51) char *str)
strlen: {
    .label return = $55
    .label len = $55
    .label str = $51
    // [1945] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [1945] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z len
    sta.z len+1
    // [1945] phi strlen::str#6 = strlen::str#8 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [1946] if(0!=*strlen::str#6) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [1947] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [1948] strlen::len#1 = ++ strlen::len#2 -- vwuz1=_inc_vwuz1 
    inc.z len
    bne !+
    inc.z len+1
  !:
    // str++;
    // [1949] strlen::str#1 = ++ strlen::str#6 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [1945] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [1945] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [1945] phi strlen::str#6 = strlen::str#1 [phi:strlen::@2->strlen::@1#1] -- register_copy 
    jmp __b1
}
  // printf_padding
// Print a padding char a number of times
// void printf_padding(__zp($51) void (*putc)(char), __zp($6d) char pad, __zp($69) char length)
printf_padding: {
    .label i = $53
    .label putc = $51
    .label length = $69
    .label pad = $6d
    // [1951] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [1951] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [1952] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z length
    bcc __b2
    // printf_padding::@return
    // }
    // [1953] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [1954] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbuz1 
    lda.z pad
    pha
    // [1955] callexecute *printf_padding::putc#7  -- call__deref_pprz1 
    jsr icall34
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [1957] printf_padding::i#1 = ++ printf_padding::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1951] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [1951] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
    jmp __b1
    // Outside Flow
  icall34:
    jmp (putc)
}
  // utoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void utoa(__zp($2e) unsigned int value, __zp($62) char *buffer, __zp($e3) char radix)
utoa: {
    .label utoa__4 = $6b
    .label utoa__10 = $5c
    .label utoa__11 = $37
    .label digit_value = $44
    .label buffer = $62
    .label digit = $66
    .label value = $2e
    .label radix = $e3
    .label started = $70
    .label max_digits = $bf
    .label digit_values = $c0
    // if(radix==DECIMAL)
    // [1958] if(utoa::radix#0==DECIMAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp.z radix
    beq __b2
    // utoa::@2
    // if(radix==HEXADECIMAL)
    // [1959] if(utoa::radix#0==HEXADECIMAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp.z radix
    beq __b3
    // utoa::@3
    // if(radix==OCTAL)
    // [1960] if(utoa::radix#0==OCTAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp.z radix
    beq __b4
    // utoa::@4
    // if(radix==BINARY)
    // [1961] if(utoa::radix#0==BINARY) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp.z radix
    beq __b5
    // utoa::@5
    // *buffer++ = 'e'
    // [1962] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1963] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1964] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1965] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // utoa::@return
    // }
    // [1966] return 
    rts
    // [1967] phi from utoa to utoa::@1 [phi:utoa->utoa::@1]
  __b2:
    // [1967] phi utoa::digit_values#8 = RADIX_DECIMAL_VALUES [phi:utoa->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_DECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES
    sta.z digit_values+1
    // [1967] phi utoa::max_digits#7 = 5 [phi:utoa->utoa::@1#1] -- vbuz1=vbuc1 
    lda #5
    sta.z max_digits
    jmp __b1
    // [1967] phi from utoa::@2 to utoa::@1 [phi:utoa::@2->utoa::@1]
  __b3:
    // [1967] phi utoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES [phi:utoa::@2->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_HEXADECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES
    sta.z digit_values+1
    // [1967] phi utoa::max_digits#7 = 4 [phi:utoa::@2->utoa::@1#1] -- vbuz1=vbuc1 
    lda #4
    sta.z max_digits
    jmp __b1
    // [1967] phi from utoa::@3 to utoa::@1 [phi:utoa::@3->utoa::@1]
  __b4:
    // [1967] phi utoa::digit_values#8 = RADIX_OCTAL_VALUES [phi:utoa::@3->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_OCTAL_VALUES
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES
    sta.z digit_values+1
    // [1967] phi utoa::max_digits#7 = 6 [phi:utoa::@3->utoa::@1#1] -- vbuz1=vbuc1 
    lda #6
    sta.z max_digits
    jmp __b1
    // [1967] phi from utoa::@4 to utoa::@1 [phi:utoa::@4->utoa::@1]
  __b5:
    // [1967] phi utoa::digit_values#8 = RADIX_BINARY_VALUES [phi:utoa::@4->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_BINARY_VALUES
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES
    sta.z digit_values+1
    // [1967] phi utoa::max_digits#7 = $10 [phi:utoa::@4->utoa::@1#1] -- vbuz1=vbuc1 
    lda #$10
    sta.z max_digits
    // utoa::@1
  __b1:
    // [1968] phi from utoa::@1 to utoa::@6 [phi:utoa::@1->utoa::@6]
    // [1968] phi utoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:utoa::@1->utoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1968] phi utoa::started#2 = 0 [phi:utoa::@1->utoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [1968] phi utoa::value#2 = utoa::value#1 [phi:utoa::@1->utoa::@6#2] -- register_copy 
    // [1968] phi utoa::digit#2 = 0 [phi:utoa::@1->utoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // utoa::@6
  __b6:
    // max_digits-1
    // [1969] utoa::$4 = utoa::max_digits#7 - 1 -- vbuz1=vbuz2_minus_1 
    ldx.z max_digits
    dex
    stx.z utoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1970] if(utoa::digit#2<utoa::$4) goto utoa::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z digit
    cmp.z utoa__4
    bcc __b7
    // utoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1971] utoa::$11 = (char)utoa::value#2 -- vbuz1=_byte_vwuz2 
    lda.z value
    sta.z utoa__11
    // [1972] *utoa::buffer#11 = DIGITS[utoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1973] utoa::buffer#3 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1974] *utoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // utoa::@7
  __b7:
    // unsigned int digit_value = digit_values[digit]
    // [1975] utoa::$10 = utoa::digit#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z digit
    asl
    sta.z utoa__10
    // [1976] utoa::digit_value#0 = utoa::digit_values#8[utoa::$10] -- vwuz1=pwuz2_derefidx_vbuz3 
    tay
    lda (digit_values),y
    sta.z digit_value
    iny
    lda (digit_values),y
    sta.z digit_value+1
    // if (started || value >= digit_value)
    // [1977] if(0!=utoa::started#2) goto utoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // utoa::@12
    // [1978] if(utoa::value#2>=utoa::digit_value#0) goto utoa::@10 -- vwuz1_ge_vwuz2_then_la1 
    lda.z digit_value+1
    cmp.z value+1
    bne !+
    lda.z digit_value
    cmp.z value
    beq __b10
  !:
    bcc __b10
    // [1979] phi from utoa::@12 to utoa::@9 [phi:utoa::@12->utoa::@9]
    // [1979] phi utoa::buffer#14 = utoa::buffer#11 [phi:utoa::@12->utoa::@9#0] -- register_copy 
    // [1979] phi utoa::started#4 = utoa::started#2 [phi:utoa::@12->utoa::@9#1] -- register_copy 
    // [1979] phi utoa::value#6 = utoa::value#2 [phi:utoa::@12->utoa::@9#2] -- register_copy 
    // utoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1980] utoa::digit#1 = ++ utoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1968] phi from utoa::@9 to utoa::@6 [phi:utoa::@9->utoa::@6]
    // [1968] phi utoa::buffer#11 = utoa::buffer#14 [phi:utoa::@9->utoa::@6#0] -- register_copy 
    // [1968] phi utoa::started#2 = utoa::started#4 [phi:utoa::@9->utoa::@6#1] -- register_copy 
    // [1968] phi utoa::value#2 = utoa::value#6 [phi:utoa::@9->utoa::@6#2] -- register_copy 
    // [1968] phi utoa::digit#2 = utoa::digit#1 [phi:utoa::@9->utoa::@6#3] -- register_copy 
    jmp __b6
    // utoa::@10
  __b10:
    // utoa_append(buffer++, value, digit_value)
    // [1981] utoa_append::buffer#0 = utoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z utoa_append.buffer
    lda.z buffer+1
    sta.z utoa_append.buffer+1
    // [1982] utoa_append::value#0 = utoa::value#2
    // [1983] utoa_append::sub#0 = utoa::digit_value#0
    // [1984] call utoa_append
    // [2475] phi from utoa::@10 to utoa_append [phi:utoa::@10->utoa_append]
    jsr utoa_append
    // utoa_append(buffer++, value, digit_value)
    // [1985] utoa_append::return#0 = utoa_append::value#2
    // utoa::@11
    // value = utoa_append(buffer++, value, digit_value)
    // [1986] utoa::value#0 = utoa_append::return#0
    // value = utoa_append(buffer++, value, digit_value);
    // [1987] utoa::buffer#4 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1979] phi from utoa::@11 to utoa::@9 [phi:utoa::@11->utoa::@9]
    // [1979] phi utoa::buffer#14 = utoa::buffer#4 [phi:utoa::@11->utoa::@9#0] -- register_copy 
    // [1979] phi utoa::started#4 = 1 [phi:utoa::@11->utoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [1979] phi utoa::value#6 = utoa::value#0 [phi:utoa::@11->utoa::@9#2] -- register_copy 
    jmp __b9
}
  // printf_number_buffer
// Print the contents of the number buffer using a specific format.
// This handles minimum length, zero-filling, and left/right justification from the format
// void printf_number_buffer(__zp($4d) void (*putc)(char), __zp($de) char buffer_sign, char *buffer_digits, __zp($e7) char format_min_length, char format_justify_left, char format_sign_always, __zp($e6) char format_zero_padding, char format_upper_case, char format_radix)
printf_number_buffer: {
    .label printf_number_buffer__19 = $55
    .label putc = $4d
    .label buffer_sign = $de
    .label format_min_length = $e7
    .label format_zero_padding = $e6
    .label len = $d2
    .label padding = $d2
    // if(format.min_length)
    // [1989] if(0==printf_number_buffer::format_min_length#3) goto printf_number_buffer::@1 -- 0_eq_vbuz1_then_la1 
    lda.z format_min_length
    beq __b5
    // [1990] phi from printf_number_buffer to printf_number_buffer::@5 [phi:printf_number_buffer->printf_number_buffer::@5]
    // printf_number_buffer::@5
    // strlen(buffer.digits)
    // [1991] call strlen
    // [1944] phi from printf_number_buffer::@5 to strlen [phi:printf_number_buffer::@5->strlen]
    // [1944] phi strlen::str#8 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@5->strlen#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str+1
    jsr strlen
    // strlen(buffer.digits)
    // [1992] strlen::return#3 = strlen::len#2
    // printf_number_buffer::@11
    // [1993] printf_number_buffer::$19 = strlen::return#3
    // signed char len = (signed char)strlen(buffer.digits)
    // [1994] printf_number_buffer::len#0 = (signed char)printf_number_buffer::$19 -- vbsz1=_sbyte_vwuz2 
    // There is a minimum length - work out the padding
    lda.z printf_number_buffer__19
    sta.z len
    // if(buffer.sign)
    // [1995] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@10 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b10
    // printf_number_buffer::@6
    // len++;
    // [1996] printf_number_buffer::len#1 = ++ printf_number_buffer::len#0 -- vbsz1=_inc_vbsz1 
    inc.z len
    // [1997] phi from printf_number_buffer::@11 printf_number_buffer::@6 to printf_number_buffer::@10 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10]
    // [1997] phi printf_number_buffer::len#2 = printf_number_buffer::len#0 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10#0] -- register_copy 
    // printf_number_buffer::@10
  __b10:
    // padding = (signed char)format.min_length - len
    // [1998] printf_number_buffer::padding#1 = (signed char)printf_number_buffer::format_min_length#3 - printf_number_buffer::len#2 -- vbsz1=vbsz2_minus_vbsz1 
    lda.z format_min_length
    sec
    sbc.z padding
    sta.z padding
    // if(padding<0)
    // [1999] if(printf_number_buffer::padding#1>=0) goto printf_number_buffer::@15 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [2001] phi from printf_number_buffer printf_number_buffer::@10 to printf_number_buffer::@1 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1]
  __b5:
    // [2001] phi printf_number_buffer::padding#10 = 0 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [2000] phi from printf_number_buffer::@10 to printf_number_buffer::@15 [phi:printf_number_buffer::@10->printf_number_buffer::@15]
    // printf_number_buffer::@15
    // [2001] phi from printf_number_buffer::@15 to printf_number_buffer::@1 [phi:printf_number_buffer::@15->printf_number_buffer::@1]
    // [2001] phi printf_number_buffer::padding#10 = printf_number_buffer::padding#1 [phi:printf_number_buffer::@15->printf_number_buffer::@1#0] -- register_copy 
    // printf_number_buffer::@1
  __b1:
    // printf_number_buffer::@13
    // if(!format.justify_left && !format.zero_padding && padding)
    // [2002] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_zero_padding
    bne __b2
    // printf_number_buffer::@12
    // [2003] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@7 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b7
    jmp __b2
    // printf_number_buffer::@7
  __b7:
    // printf_padding(putc, ' ',(char)padding)
    // [2004] printf_padding::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [2005] printf_padding::length#0 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [2006] call printf_padding
    // [1950] phi from printf_number_buffer::@7 to printf_padding [phi:printf_number_buffer::@7->printf_padding]
    // [1950] phi printf_padding::putc#7 = printf_padding::putc#0 [phi:printf_number_buffer::@7->printf_padding#0] -- register_copy 
    // [1950] phi printf_padding::pad#7 = ' ' [phi:printf_number_buffer::@7->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1950] phi printf_padding::length#6 = printf_padding::length#0 [phi:printf_number_buffer::@7->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@2
  __b2:
    // if(buffer.sign)
    // [2007] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@3 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b3
    // printf_number_buffer::@8
    // putc(buffer.sign)
    // [2008] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbuz1 
    pha
    // [2009] callexecute *printf_number_buffer::putc#10  -- call__deref_pprz1 
    jsr icall35
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@3
  __b3:
    // if(format.zero_padding && padding)
    // [2011] if(0==printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@4 -- 0_eq_vbuz1_then_la1 
    lda.z format_zero_padding
    beq __b4
    // printf_number_buffer::@14
    // [2012] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@9 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b9
    jmp __b4
    // printf_number_buffer::@9
  __b9:
    // printf_padding(putc, '0',(char)padding)
    // [2013] printf_padding::putc#1 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [2014] printf_padding::length#1 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [2015] call printf_padding
    // [1950] phi from printf_number_buffer::@9 to printf_padding [phi:printf_number_buffer::@9->printf_padding]
    // [1950] phi printf_padding::putc#7 = printf_padding::putc#1 [phi:printf_number_buffer::@9->printf_padding#0] -- register_copy 
    // [1950] phi printf_padding::pad#7 = '0' [phi:printf_number_buffer::@9->printf_padding#1] -- vbuz1=vbuc1 
    lda #'0'
    sta.z printf_padding.pad
    // [1950] phi printf_padding::length#6 = printf_padding::length#1 [phi:printf_number_buffer::@9->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@4
  __b4:
    // printf_str(putc, buffer.digits)
    // [2016] printf_str::putc#0 = printf_number_buffer::putc#10
    // [2017] call printf_str
    // [877] phi from printf_number_buffer::@4 to printf_str [phi:printf_number_buffer::@4->printf_str]
    // [877] phi printf_str::putc#73 = printf_str::putc#0 [phi:printf_number_buffer::@4->printf_str#0] -- register_copy 
    // [877] phi printf_str::s#73 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@return
    // }
    // [2018] return 
    rts
    // Outside Flow
  icall35:
    jmp (putc)
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
// void rom_unlock(__zp($7a) unsigned long address, __zp($77) char unlock_code)
rom_unlock: {
    .label chip_address = $3f
    .label address = $7a
    .label unlock_code = $77
    // unsigned long chip_address = address & ROM_CHIP_MASK
    // [2020] rom_unlock::chip_address#0 = rom_unlock::address#5 & $380000 -- vduz1=vduz2_band_vduc1 
    lda.z address
    and #<$380000
    sta.z chip_address
    lda.z address+1
    and #>$380000
    sta.z chip_address+1
    lda.z address+2
    and #<$380000>>$10
    sta.z chip_address+2
    lda.z address+3
    and #>$380000>>$10
    sta.z chip_address+3
    // rom_write_byte(chip_address + 0x05555, 0xAA)
    // [2021] rom_write_byte::address#0 = rom_unlock::chip_address#0 + $5555 -- vduz1=vduz2_plus_vwuc1 
    clc
    lda.z chip_address
    adc #<$5555
    sta.z rom_write_byte.address
    lda.z chip_address+1
    adc #>$5555
    sta.z rom_write_byte.address+1
    lda.z chip_address+2
    adc #0
    sta.z rom_write_byte.address+2
    lda.z chip_address+3
    adc #0
    sta.z rom_write_byte.address+3
    // [2022] call rom_write_byte
  // This is a very important operation...
    // [2482] phi from rom_unlock to rom_write_byte [phi:rom_unlock->rom_write_byte]
    // [2482] phi rom_write_byte::value#10 = $aa [phi:rom_unlock->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$aa
    sta.z rom_write_byte.value
    // [2482] phi rom_write_byte::address#4 = rom_write_byte::address#0 [phi:rom_unlock->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@1
    // rom_write_byte(chip_address + 0x02AAA, 0x55)
    // [2023] rom_write_byte::address#1 = rom_unlock::chip_address#0 + $2aaa -- vduz1=vduz2_plus_vwuc1 
    clc
    lda.z chip_address
    adc #<$2aaa
    sta.z rom_write_byte.address
    lda.z chip_address+1
    adc #>$2aaa
    sta.z rom_write_byte.address+1
    lda.z chip_address+2
    adc #0
    sta.z rom_write_byte.address+2
    lda.z chip_address+3
    adc #0
    sta.z rom_write_byte.address+3
    // [2024] call rom_write_byte
    // [2482] phi from rom_unlock::@1 to rom_write_byte [phi:rom_unlock::@1->rom_write_byte]
    // [2482] phi rom_write_byte::value#10 = $55 [phi:rom_unlock::@1->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$55
    sta.z rom_write_byte.value
    // [2482] phi rom_write_byte::address#4 = rom_write_byte::address#1 [phi:rom_unlock::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@2
    // rom_write_byte(address, unlock_code)
    // [2025] rom_write_byte::address#2 = rom_unlock::address#5 -- vduz1=vduz2 
    lda.z address
    sta.z rom_write_byte.address
    lda.z address+1
    sta.z rom_write_byte.address+1
    lda.z address+2
    sta.z rom_write_byte.address+2
    lda.z address+3
    sta.z rom_write_byte.address+3
    // [2026] rom_write_byte::value#2 = rom_unlock::unlock_code#5 -- vbuz1=vbuz2 
    lda.z unlock_code
    sta.z rom_write_byte.value
    // [2027] call rom_write_byte
    // [2482] phi from rom_unlock::@2 to rom_write_byte [phi:rom_unlock::@2->rom_write_byte]
    // [2482] phi rom_write_byte::value#10 = rom_write_byte::value#2 [phi:rom_unlock::@2->rom_write_byte#0] -- register_copy 
    // [2482] phi rom_write_byte::address#4 = rom_write_byte::address#2 [phi:rom_unlock::@2->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@return
    // }
    // [2028] return 
    rts
}
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
// __mem() char rom_read_byte(__zp($57) unsigned long address)
rom_read_byte: {
    .label rom_bank1_rom_read_byte__0 = $6b
    .label rom_bank1_rom_read_byte__1 = $37
    .label rom_bank1_return = $5c
    .label address = $57
    // rom_read_byte::rom_bank1
    // BYTE2(address)
    // [2030] rom_read_byte::rom_bank1_$0 = byte2  rom_read_byte::address#2 -- vbuz1=_byte2_vduz2 
    lda.z address+2
    sta.z rom_bank1_rom_read_byte__0
    // BYTE1(address)
    // [2031] rom_read_byte::rom_bank1_$1 = byte1  rom_read_byte::address#2 -- vbuz1=_byte1_vduz2 
    lda.z address+1
    sta.z rom_bank1_rom_read_byte__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2032] rom_read_byte::rom_bank1_$2 = rom_read_byte::rom_bank1_$0 w= rom_read_byte::rom_bank1_$1 -- vwum1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_read_byte__0
    sta rom_bank1_rom_read_byte__2+1
    lda.z rom_bank1_rom_read_byte__1
    sta rom_bank1_rom_read_byte__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2033] rom_read_byte::rom_bank1_bank_unshifted#0 = rom_read_byte::rom_bank1_$2 << 2 -- vwum1=vwum1_rol_2 
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2034] rom_read_byte::rom_bank1_return#0 = byte1  rom_read_byte::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwum2 
    lda rom_bank1_bank_unshifted+1
    sta.z rom_bank1_return
    // rom_read_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2035] rom_read_byte::rom_ptr1_$2 = (unsigned int)rom_read_byte::address#2 -- vwum1=_word_vduz2 
    lda.z address
    sta rom_ptr1_rom_read_byte__2
    lda.z address+1
    sta rom_ptr1_rom_read_byte__2+1
    // [2036] rom_read_byte::rom_ptr1_$0 = rom_read_byte::rom_ptr1_$2 & $3fff -- vwum1=vwum1_band_vwuc1 
    lda rom_ptr1_rom_read_byte__0
    and #<$3fff
    sta rom_ptr1_rom_read_byte__0
    lda rom_ptr1_rom_read_byte__0+1
    and #>$3fff
    sta rom_ptr1_rom_read_byte__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2037] rom_read_byte::rom_ptr1_return#0 = rom_read_byte::rom_ptr1_$0 + $c000 -- vwum1=vwum1_plus_vwuc1 
    lda rom_ptr1_return
    clc
    adc #<$c000
    sta rom_ptr1_return
    lda rom_ptr1_return+1
    adc #>$c000
    sta rom_ptr1_return+1
    // rom_read_byte::bank_set_brom1
    // BROM = bank
    // [2038] BROM = rom_read_byte::rom_bank1_return#0 -- vbuz1=vbuz2 
    lda.z rom_bank1_return
    sta.z BROM
    // rom_read_byte::@1
    // return *ptr_rom;
    // [2039] rom_read_byte::return#0 = *((char *)rom_read_byte::rom_ptr1_return#0) -- vbum1=_deref_pbum2 
    ldy rom_ptr1_return
    sty.z $fe
    ldy rom_ptr1_return+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta return
    // rom_read_byte::@return
    // }
    // [2040] return 
    rts
  .segment Data
    rom_bank1_rom_read_byte__2: .word 0
    .label rom_ptr1_rom_read_byte__0 = rom_ptr1_rom_read_byte__2
    rom_ptr1_rom_read_byte__2: .word 0
    .label rom_bank1_bank_unshifted = rom_bank1_rom_read_byte__2
    .label rom_ptr1_return = rom_ptr1_rom_read_byte__2
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
// __zp($62) struct $2 * fopen(__zp($d7) const char *path, const char *mode)
fopen: {
    .label fopen__4 = $b5
    .label fopen__9 = $65
    .label fopen__15 = $6f
    .label fopen__16 = $73
    .label fopen__26 = $51
    .label fopen__30 = $62
    .label cbm_k_setnam1_fopen__0 = $55
    .label sp = $35
    .label stream = $62
    .label pathtoken = $d7
    .label pathpos = $eb
    .label pathpos_1 = $54
    .label pathtoken_1 = $ef
    .label path = $d7
    // Parse path
    .label pathstep = $5b
    .label cbm_k_readst1_return = $6f
    .label return = $62
    // unsigned char sp = __stdio_filecount
    // [2042] fopen::sp#0 = __stdio_filecount -- vbuz1=vbum2 
    lda __stdio_filecount
    sta.z sp
    // (unsigned int)sp | 0x8000
    // [2043] fopen::$30 = (unsigned int)fopen::sp#0 -- vwuz1=_word_vbuz2 
    sta.z fopen__30
    lda #0
    sta.z fopen__30+1
    // [2044] fopen::stream#0 = fopen::$30 | $8000 -- vwuz1=vwuz1_bor_vwuc1 
    lda.z stream
    ora #<$8000
    sta.z stream
    lda.z stream+1
    ora #>$8000
    sta.z stream+1
    // char pathpos = sp * __STDIO_FILECOUNT
    // [2045] fopen::pathpos#0 = fopen::sp#0 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z sp
    asl
    sta.z pathpos
    // __logical = 0
    // [2046] ((char *)&__stdio_file+$40)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    ldy.z sp
    sta __stdio_file+$40,y
    // __device = 0
    // [2047] ((char *)&__stdio_file+$42)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [2048] ((char *)&__stdio_file+$44)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$44,y
    // [2049] fopen::pathtoken#22 = fopen::pathtoken#0 -- pbuz1=pbuz2 
    lda.z pathtoken
    sta.z pathtoken_1
    lda.z pathtoken+1
    sta.z pathtoken_1+1
    // [2050] fopen::pathpos#21 = fopen::pathpos#0 -- vbuz1=vbuz2 
    lda.z pathpos
    sta.z pathpos_1
    // [2051] phi from fopen to fopen::@8 [phi:fopen->fopen::@8]
    // [2051] phi fopen::num#10 = 0 [phi:fopen->fopen::@8#0] -- vbum1=vbuc1 
    lda #0
    sta num
    // [2051] phi fopen::pathpos#10 = fopen::pathpos#21 [phi:fopen->fopen::@8#1] -- register_copy 
    // [2051] phi fopen::path#10 = fopen::pathtoken#0 [phi:fopen->fopen::@8#2] -- register_copy 
    // [2051] phi fopen::pathstep#10 = 0 [phi:fopen->fopen::@8#3] -- vbuz1=vbuc1 
    sta.z pathstep
    // [2051] phi fopen::pathtoken#10 = fopen::pathtoken#22 [phi:fopen->fopen::@8#4] -- register_copy 
  // Iterate while path is not \0.
    // [2051] phi from fopen::@22 to fopen::@8 [phi:fopen::@22->fopen::@8]
    // [2051] phi fopen::num#10 = fopen::num#13 [phi:fopen::@22->fopen::@8#0] -- register_copy 
    // [2051] phi fopen::pathpos#10 = fopen::pathpos#7 [phi:fopen::@22->fopen::@8#1] -- register_copy 
    // [2051] phi fopen::path#10 = fopen::path#11 [phi:fopen::@22->fopen::@8#2] -- register_copy 
    // [2051] phi fopen::pathstep#10 = fopen::pathstep#11 [phi:fopen::@22->fopen::@8#3] -- register_copy 
    // [2051] phi fopen::pathtoken#10 = fopen::pathtoken#1 [phi:fopen::@22->fopen::@8#4] -- register_copy 
    // fopen::@8
  __b8:
    // if (*pathtoken == ',' || *pathtoken == '\0')
    // [2052] if(*fopen::pathtoken#10==',') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #','
    ldy #0
    cmp (pathtoken_1),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@33
    // [2053] if(*fopen::pathtoken#10=='@') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #'@'
    cmp (pathtoken_1),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@23
    // if (pathstep == 0)
    // [2054] if(fopen::pathstep#10!=0) goto fopen::@10 -- vbuz1_neq_0_then_la1 
    lda.z pathstep
    bne __b10
    // fopen::@24
    // __stdio_file.filename[pathpos] = *pathtoken
    // [2055] ((char *)&__stdio_file)[fopen::pathpos#10] = *fopen::pathtoken#10 -- pbuc1_derefidx_vbuz1=_deref_pbuz2 
    lda (pathtoken_1),y
    ldy.z pathpos_1
    sta __stdio_file,y
    // pathpos++;
    // [2056] fopen::pathpos#1 = ++ fopen::pathpos#10 -- vbuz1=_inc_vbuz1 
    inc.z pathpos_1
    // [2057] phi from fopen::@12 fopen::@23 fopen::@24 to fopen::@10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10]
    // [2057] phi fopen::num#13 = fopen::num#15 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#0] -- register_copy 
    // [2057] phi fopen::pathpos#7 = fopen::pathpos#10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#1] -- register_copy 
    // [2057] phi fopen::path#11 = fopen::path#13 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#2] -- register_copy 
    // [2057] phi fopen::pathstep#11 = fopen::pathstep#1 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#3] -- register_copy 
    // fopen::@10
  __b10:
    // pathtoken++;
    // [2058] fopen::pathtoken#1 = ++ fopen::pathtoken#10 -- pbuz1=_inc_pbuz1 
    inc.z pathtoken_1
    bne !+
    inc.z pathtoken_1+1
  !:
    // fopen::@22
    // pathtoken - 1
    // [2059] fopen::$28 = fopen::pathtoken#1 - 1 -- pbum1=pbuz2_minus_1 
    lda.z pathtoken_1
    sec
    sbc #1
    sta fopen__28
    lda.z pathtoken_1+1
    sbc #0
    sta fopen__28+1
    // while (*(pathtoken - 1))
    // [2060] if(0!=*fopen::$28) goto fopen::@8 -- 0_neq__deref_pbum1_then_la1 
    ldy fopen__28
    sty.z $fe
    tay
    sty.z $ff
    ldy #0
    lda ($fe),y
    cmp #0
    bne __b8
    // fopen::@26
    // __status = 0
    // [2061] ((char *)&__stdio_file+$46)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    tya
    ldy.z sp
    sta __stdio_file+$46,y
    // if(!__logical)
    // [2062] if(0!=((char *)&__stdio_file+$40)[fopen::sp#0]) goto fopen::@1 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$40,y
    cmp #0
    bne __b1
    // fopen::@27
    // __stdio_filecount+1
    // [2063] fopen::$4 = __stdio_filecount + 1 -- vbuz1=vbum2_plus_1 
    lda __stdio_filecount
    inc
    sta.z fopen__4
    // __logical = __stdio_filecount+1
    // [2064] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::$4 -- pbuc1_derefidx_vbuz1=vbuz2 
    sta __stdio_file+$40,y
    // fopen::@1
  __b1:
    // if(!__device)
    // [2065] if(0!=((char *)&__stdio_file+$42)[fopen::sp#0]) goto fopen::@2 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    ldy.z sp
    lda __stdio_file+$42,y
    cmp #0
    bne __b2
    // fopen::@5
    // __device = 8
    // [2066] ((char *)&__stdio_file+$42)[fopen::sp#0] = 8 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #8
    sta __stdio_file+$42,y
    // fopen::@2
  __b2:
    // if(!__channel)
    // [2067] if(0!=((char *)&__stdio_file+$44)[fopen::sp#0]) goto fopen::@3 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    ldy.z sp
    lda __stdio_file+$44,y
    cmp #0
    bne __b3
    // fopen::@6
    // __stdio_filecount+2
    // [2068] fopen::$9 = __stdio_filecount + 2 -- vbuz1=vbum2_plus_2 
    lda __stdio_filecount
    clc
    adc #2
    sta.z fopen__9
    // __channel = __stdio_filecount+2
    // [2069] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::$9 -- pbuc1_derefidx_vbuz1=vbuz2 
    sta __stdio_file+$44,y
    // fopen::@3
  __b3:
    // __filename
    // [2070] fopen::$11 = (char *)&__stdio_file + fopen::pathpos#0 -- pbum1=pbuc1_plus_vbuz2 
    lda.z pathpos
    clc
    adc #<__stdio_file
    sta fopen__11
    lda #>__stdio_file
    adc #0
    sta fopen__11+1
    // cbm_k_setnam(__filename)
    // [2071] fopen::cbm_k_setnam1_filename = fopen::$11 -- pbum1=pbum2 
    lda fopen__11
    sta cbm_k_setnam1_filename
    lda fopen__11+1
    sta cbm_k_setnam1_filename+1
    // fopen::cbm_k_setnam1
    // strlen(filename)
    // [2072] strlen::str#4 = fopen::cbm_k_setnam1_filename -- pbuz1=pbum2 
    lda cbm_k_setnam1_filename
    sta.z strlen.str
    lda cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [2073] call strlen
    // [1944] phi from fopen::cbm_k_setnam1 to strlen [phi:fopen::cbm_k_setnam1->strlen]
    // [1944] phi strlen::str#8 = strlen::str#4 [phi:fopen::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [2074] strlen::return#11 = strlen::len#2
    // fopen::@31
    // [2075] fopen::cbm_k_setnam1_$0 = strlen::return#11
    // char filename_len = (char)strlen(filename)
    // [2076] fopen::cbm_k_setnam1_filename_len = (char)fopen::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
    lda.z cbm_k_setnam1_fopen__0
    sta cbm_k_setnam1_filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx cbm_k_setnam1_filename
    ldy cbm_k_setnam1_filename+1
    jsr CBM_SETNAM
    // fopen::@28
    // cbm_k_setlfs(__logical, __device, __channel)
    // [2078] cbm_k_setlfs::channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$40,y
    sta cbm_k_setlfs.channel
    // [2079] cbm_k_setlfs::device = ((char *)&__stdio_file+$42)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    lda __stdio_file+$42,y
    sta cbm_k_setlfs.device
    // [2080] cbm_k_setlfs::command = ((char *)&__stdio_file+$44)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    lda __stdio_file+$44,y
    sta cbm_k_setlfs.command
    // [2081] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // fopen::cbm_k_open1
    // asm
    // asm { jsrCBM_OPEN  }
    jsr CBM_OPEN
    // fopen::cbm_k_readst1
    // char status
    // [2083] fopen::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2085] fopen::cbm_k_readst1_return#0 = fopen::cbm_k_readst1_status -- vbuz1=vbum2 
    sta.z cbm_k_readst1_return
    // fopen::cbm_k_readst1_@return
    // }
    // [2086] fopen::cbm_k_readst1_return#1 = fopen::cbm_k_readst1_return#0
    // fopen::@29
    // cbm_k_readst()
    // [2087] fopen::$15 = fopen::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [2088] ((char *)&__stdio_file+$46)[fopen::sp#0] = fopen::$15 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fopen__15
    ldy.z sp
    sta __stdio_file+$46,y
    // ferror(stream)
    // [2089] ferror::stream#0 = (struct $2 *)fopen::stream#0
    // [2090] call ferror
    jsr ferror
    // [2091] ferror::return#0 = ferror::return#1
    // fopen::@32
    // [2092] fopen::$16 = ferror::return#0
    // if (ferror(stream))
    // [2093] if(0==fopen::$16) goto fopen::@4 -- 0_eq_vwsz1_then_la1 
    lda.z fopen__16
    ora.z fopen__16+1
    beq __b4
    // fopen::@7
    // cbm_k_close(__logical)
    // [2094] fopen::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$40,y
    sta cbm_k_close1_channel
    // fopen::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // [2096] phi from fopen::cbm_k_close1 to fopen::@return [phi:fopen::cbm_k_close1->fopen::@return]
    // [2096] phi fopen::return#2 = 0 [phi:fopen::cbm_k_close1->fopen::@return#0] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fopen::@return
    // }
    // [2097] return 
    rts
    // fopen::@4
  __b4:
    // __stdio_filecount++;
    // [2098] __stdio_filecount = ++ __stdio_filecount -- vbum1=_inc_vbum1 
    inc __stdio_filecount
    // [2099] fopen::return#8 = (struct $2 *)fopen::stream#0
    // [2096] phi from fopen::@4 to fopen::@return [phi:fopen::@4->fopen::@return]
    // [2096] phi fopen::return#2 = fopen::return#8 [phi:fopen::@4->fopen::@return#0] -- register_copy 
    rts
    // fopen::@9
  __b9:
    // if (pathstep > 0)
    // [2100] if(fopen::pathstep#10>0) goto fopen::@11 -- vbuz1_gt_0_then_la1 
    lda.z pathstep
    bne __b11
    // fopen::@25
    // __stdio_file.filename[pathpos] = '\0'
    // [2101] ((char *)&__stdio_file)[fopen::pathpos#10] = '@' -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #'@'
    ldy.z pathpos_1
    sta __stdio_file,y
    // path = pathtoken + 1
    // [2102] fopen::path#0 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
    clc
    lda.z pathtoken_1
    adc #1
    sta.z path
    lda.z pathtoken_1+1
    adc #0
    sta.z path+1
    // [2103] phi from fopen::@16 fopen::@17 fopen::@18 fopen::@19 fopen::@25 to fopen::@12 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12]
    // [2103] phi fopen::num#15 = fopen::num#2 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#0] -- register_copy 
    // [2103] phi fopen::path#13 = fopen::path#16 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#1] -- register_copy 
    // fopen::@12
  __b12:
    // pathstep++;
    // [2104] fopen::pathstep#1 = ++ fopen::pathstep#10 -- vbuz1=_inc_vbuz1 
    inc.z pathstep
    jmp __b10
    // fopen::@11
  __b11:
    // char pathcmp = *path
    // [2105] fopen::pathcmp#0 = *fopen::path#10 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (path),y
    sta pathcmp
    // case 'D':
    // [2106] if(fopen::pathcmp#0=='D') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'D'
    cmp pathcmp
    beq __b13
    // fopen::@20
    // case 'L':
    // [2107] if(fopen::pathcmp#0=='L') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'L'
    cmp pathcmp
    beq __b13
    // fopen::@21
    // case 'C':
    //                     num = (char)atoi(path + 1);
    //                     path = pathtoken + 1;
    // [2108] if(fopen::pathcmp#0=='C') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'C'
    cmp pathcmp
    beq __b13
    // [2109] phi from fopen::@21 fopen::@30 to fopen::@14 [phi:fopen::@21/fopen::@30->fopen::@14]
    // [2109] phi fopen::path#16 = fopen::path#10 [phi:fopen::@21/fopen::@30->fopen::@14#0] -- register_copy 
    // [2109] phi fopen::num#2 = fopen::num#10 [phi:fopen::@21/fopen::@30->fopen::@14#1] -- register_copy 
    // fopen::@14
  __b14:
    // case 'L':
    //                     __logical = num;
    //                     break;
    // [2110] if(fopen::pathcmp#0=='L') goto fopen::@17 -- vbum1_eq_vbuc1_then_la1 
    lda #'L'
    cmp pathcmp
    beq __b17
    // fopen::@15
    // case 'D':
    //                     __device = num;
    //                     break;
    // [2111] if(fopen::pathcmp#0=='D') goto fopen::@18 -- vbum1_eq_vbuc1_then_la1 
    lda #'D'
    cmp pathcmp
    beq __b18
    // fopen::@16
    // case 'C':
    //                     __channel = num;
    //                     break;
    // [2112] if(fopen::pathcmp#0!='C') goto fopen::@12 -- vbum1_neq_vbuc1_then_la1 
    lda #'C'
    cmp pathcmp
    bne __b12
    // fopen::@19
    // __channel = num
    // [2113] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbum2 
    lda num
    ldy.z sp
    sta __stdio_file+$44,y
    jmp __b12
    // fopen::@18
  __b18:
    // __device = num
    // [2114] ((char *)&__stdio_file+$42)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbum2 
    lda num
    ldy.z sp
    sta __stdio_file+$42,y
    jmp __b12
    // fopen::@17
  __b17:
    // __logical = num
    // [2115] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbum2 
    lda num
    ldy.z sp
    sta __stdio_file+$40,y
    jmp __b12
    // fopen::@13
  __b13:
    // atoi(path + 1)
    // [2116] atoi::str#0 = fopen::path#10 + 1 -- pbuz1=pbuz1_plus_1 
    inc.z atoi.str
    bne !+
    inc.z atoi.str+1
  !:
    // [2117] call atoi
    // [2548] phi from fopen::@13 to atoi [phi:fopen::@13->atoi]
    // [2548] phi atoi::str#2 = atoi::str#0 [phi:fopen::@13->atoi#0] -- register_copy 
    jsr atoi
    // atoi(path + 1)
    // [2118] atoi::return#3 = atoi::return#2
    // fopen::@30
    // [2119] fopen::$26 = atoi::return#3
    // num = (char)atoi(path + 1)
    // [2120] fopen::num#1 = (char)fopen::$26 -- vbum1=_byte_vwsz2 
    lda.z fopen__26
    sta num
    // path = pathtoken + 1
    // [2121] fopen::path#1 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
    clc
    lda.z pathtoken_1
    adc #1
    sta.z path
    lda.z pathtoken_1+1
    adc #0
    sta.z path+1
    jmp __b14
  .segment Data
    fopen__11: .word 0
    fopen__28: .word 0
    cbm_k_setnam1_filename: .word 0
    cbm_k_setnam1_filename_len: .byte 0
    cbm_k_readst1_status: .byte 0
    cbm_k_close1_channel: .byte 0
    .label pathcmp = fclose.sp
    num: .byte 0
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
// __zp($bc) unsigned int fgets(__zp($c2) char *ptr, __zp($d3) unsigned int size, __mem() struct $2 *stream)
fgets: {
    .label fgets__1 = $eb
    .label fgets__8 = $b5
    .label fgets__9 = $65
    .label fgets__13 = $6f
    .label cbm_k_chkin1_status = $f9
    .label cbm_k_readst1_status = $fa
    .label cbm_k_readst2_status = $c5
    .label sp = $35
    .label cbm_k_readst1_return = $eb
    .label return = $bc
    .label bytes = $60
    .label cbm_k_readst2_return = $b5
    .label read = $bc
    .label ptr = $c2
    .label remaining = $cc
    .label size = $d3
    // unsigned char sp = (unsigned char)stream
    // [2123] fgets::sp#0 = (char)fgets::stream#2 -- vbuz1=_byte_pssm2 
    lda stream
    sta.z sp
    // cbm_k_chkin(__logical)
    // [2124] fgets::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fgets::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    tay
    lda __stdio_file+$40,y
    sta cbm_k_chkin1_channel
    // fgets::cbm_k_chkin1
    // char status
    // [2125] fgets::cbm_k_chkin1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fgets::cbm_k_readst1
    // char status
    // [2127] fgets::cbm_k_readst1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2129] fgets::cbm_k_readst1_return#0 = fgets::cbm_k_readst1_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst1_return
    // fgets::cbm_k_readst1_@return
    // }
    // [2130] fgets::cbm_k_readst1_return#1 = fgets::cbm_k_readst1_return#0
    // fgets::@11
    // cbm_k_readst()
    // [2131] fgets::$1 = fgets::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [2132] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$1 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fgets__1
    ldy.z sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2133] if(0==((char *)&__stdio_file+$46)[fgets::sp#0]) goto fgets::@1 -- 0_eq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b1
    // [2134] phi from fgets::@11 fgets::@12 fgets::@5 to fgets::@return [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return]
  __b8:
    // [2134] phi fgets::return#1 = 0 [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return#0] -- vwuz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fgets::@return
    // }
    // [2135] return 
    rts
    // fgets::@1
  __b1:
    // [2136] fgets::remaining#22 = fgets::size#10 -- vwuz1=vwuz2 
    lda.z size
    sta.z remaining
    lda.z size+1
    sta.z remaining+1
    // [2137] phi from fgets::@1 to fgets::@2 [phi:fgets::@1->fgets::@2]
    // [2137] phi fgets::read#10 = 0 [phi:fgets::@1->fgets::@2#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z read
    sta.z read+1
    // [2137] phi fgets::remaining#11 = fgets::remaining#22 [phi:fgets::@1->fgets::@2#1] -- register_copy 
    // [2137] phi fgets::ptr#10 = fgets::ptr#12 [phi:fgets::@1->fgets::@2#2] -- register_copy 
    // [2137] phi from fgets::@17 fgets::@18 to fgets::@2 [phi:fgets::@17/fgets::@18->fgets::@2]
    // [2137] phi fgets::read#10 = fgets::read#1 [phi:fgets::@17/fgets::@18->fgets::@2#0] -- register_copy 
    // [2137] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@17/fgets::@18->fgets::@2#1] -- register_copy 
    // [2137] phi fgets::ptr#10 = fgets::ptr#13 [phi:fgets::@17/fgets::@18->fgets::@2#2] -- register_copy 
    // fgets::@2
  __b2:
    // if (!size)
    // [2138] if(0==fgets::size#10) goto fgets::@3 -- 0_eq_vwuz1_then_la1 
    lda.z size
    ora.z size+1
    bne !__b3+
    jmp __b3
  !__b3:
    // fgets::@8
    // if (remaining >= 512)
    // [2139] if(fgets::remaining#11>=$200) goto fgets::@4 -- vwuz1_ge_vwuc1_then_la1 
    lda.z remaining+1
    cmp #>$200
    bcc !+
    beq !__b4+
    jmp __b4
  !__b4:
    lda.z remaining
    cmp #<$200
    bcc !__b4+
    jmp __b4
  !__b4:
  !:
    // fgets::@9
    // cx16_k_macptr(remaining, ptr)
    // [2140] cx16_k_macptr::bytes = fgets::remaining#11 -- vbuz1=vwuz2 
    lda.z remaining
    sta.z cx16_k_macptr.bytes
    // [2141] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2142] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2143] cx16_k_macptr::return#4 = cx16_k_macptr::return#1
    // fgets::@15
  __b15:
    // bytes = cx16_k_macptr(remaining, ptr)
    // [2144] fgets::bytes#3 = cx16_k_macptr::return#4
    // [2145] phi from fgets::@13 fgets::@14 fgets::@15 to fgets::cbm_k_readst2 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2]
    // [2145] phi fgets::bytes#10 = fgets::bytes#1 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2#0] -- register_copy 
    // fgets::cbm_k_readst2
    // char status
    // [2146] fgets::cbm_k_readst2_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [2148] fgets::cbm_k_readst2_return#0 = fgets::cbm_k_readst2_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst2_return
    // fgets::cbm_k_readst2_@return
    // }
    // [2149] fgets::cbm_k_readst2_return#1 = fgets::cbm_k_readst2_return#0
    // fgets::@12
    // cbm_k_readst()
    // [2150] fgets::$8 = fgets::cbm_k_readst2_return#1
    // __status = cbm_k_readst()
    // [2151] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$8 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fgets__8
    ldy.z sp
    sta __stdio_file+$46,y
    // __status & 0xBF
    // [2152] fgets::$9 = ((char *)&__stdio_file+$46)[fgets::sp#0] & $bf -- vbuz1=pbuc1_derefidx_vbuz2_band_vbuc2 
    lda #$bf
    and __stdio_file+$46,y
    sta.z fgets__9
    // if (__status & 0xBF)
    // [2153] if(0==fgets::$9) goto fgets::@5 -- 0_eq_vbuz1_then_la1 
    beq __b5
    jmp __b8
    // fgets::@5
  __b5:
    // if (bytes == 0xFFFF)
    // [2154] if(fgets::bytes#10!=$ffff) goto fgets::@6 -- vwuz1_neq_vwuc1_then_la1 
    lda.z bytes+1
    cmp #>$ffff
    bne __b6
    lda.z bytes
    cmp #<$ffff
    bne __b6
    jmp __b8
    // fgets::@6
  __b6:
    // read += bytes
    // [2155] fgets::read#1 = fgets::read#10 + fgets::bytes#10 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z read
    adc.z bytes
    sta.z read
    lda.z read+1
    adc.z bytes+1
    sta.z read+1
    // ptr += bytes
    // [2156] fgets::ptr#0 = fgets::ptr#10 + fgets::bytes#10 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z ptr
    adc.z bytes
    sta.z ptr
    lda.z ptr+1
    adc.z bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [2157] fgets::$13 = byte1  fgets::ptr#0 -- vbuz1=_byte1_pbuz2 
    sta.z fgets__13
    // if (BYTE1(ptr) == 0xC0)
    // [2158] if(fgets::$13!=$c0) goto fgets::@7 -- vbuz1_neq_vbuc1_then_la1 
    lda #$c0
    cmp.z fgets__13
    bne __b7
    // fgets::@10
    // ptr -= 0x2000
    // [2159] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [2160] phi from fgets::@10 fgets::@6 to fgets::@7 [phi:fgets::@10/fgets::@6->fgets::@7]
    // [2160] phi fgets::ptr#13 = fgets::ptr#1 [phi:fgets::@10/fgets::@6->fgets::@7#0] -- register_copy 
    // fgets::@7
  __b7:
    // remaining -= bytes
    // [2161] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#10 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z remaining
    sec
    sbc.z bytes
    sta.z remaining
    lda.z remaining+1
    sbc.z bytes+1
    sta.z remaining+1
    // while ((__status == 0) && ((size && remaining) || !size))
    // [2162] if(((char *)&__stdio_file+$46)[fgets::sp#0]==0) goto fgets::@16 -- pbuc1_derefidx_vbuz1_eq_0_then_la1 
    ldy.z sp
    lda __stdio_file+$46,y
    cmp #0
    beq __b16
    // [2134] phi from fgets::@17 fgets::@7 to fgets::@return [phi:fgets::@17/fgets::@7->fgets::@return]
    // [2134] phi fgets::return#1 = fgets::read#1 [phi:fgets::@17/fgets::@7->fgets::@return#0] -- register_copy 
    rts
    // fgets::@16
  __b16:
    // while ((__status == 0) && ((size && remaining) || !size))
    // [2163] if(0==fgets::size#10) goto fgets::@17 -- 0_eq_vwuz1_then_la1 
    lda.z size
    ora.z size+1
    beq __b17
    // fgets::@18
    // [2164] if(0!=fgets::remaining#1) goto fgets::@2 -- 0_neq_vwuz1_then_la1 
    lda.z remaining
    ora.z remaining+1
    beq !__b2+
    jmp __b2
  !__b2:
    // fgets::@17
  __b17:
    // [2165] if(0==fgets::size#10) goto fgets::@2 -- 0_eq_vwuz1_then_la1 
    lda.z size
    ora.z size+1
    bne !__b2+
    jmp __b2
  !__b2:
    rts
    // fgets::@4
  __b4:
    // cx16_k_macptr(512, ptr)
    // [2166] cx16_k_macptr::bytes = $200 -- vbuz1=vwuc1 
    lda #<$200
    sta.z cx16_k_macptr.bytes
    // [2167] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2168] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2169] cx16_k_macptr::return#3 = cx16_k_macptr::return#1
    // fgets::@14
    // bytes = cx16_k_macptr(512, ptr)
    // [2170] fgets::bytes#2 = cx16_k_macptr::return#3
    jmp __b15
    // fgets::@3
  __b3:
    // cx16_k_macptr(0, ptr)
    // [2171] cx16_k_macptr::bytes = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cx16_k_macptr.bytes
    // [2172] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2173] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2174] cx16_k_macptr::return#2 = cx16_k_macptr::return#1
    // fgets::@13
    // bytes = cx16_k_macptr(0, ptr)
    // [2175] fgets::bytes#1 = cx16_k_macptr::return#2
    jmp __b15
  .segment Data
    cbm_k_chkin1_channel: .byte 0
    stream: .word 0
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
// int fclose(__zp($b3) struct $2 *stream)
fclose: {
    .label fclose__1 = $67
    .label fclose__4 = $43
    .label cbm_k_readst1_return = $67
    .label cbm_k_readst2_return = $43
    .label stream = $b3
    // unsigned char sp = (unsigned char)stream
    // [2177] fclose::sp#0 = (char)fclose::stream#2 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_chkin(__logical)
    // [2178] fclose::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    tay
    lda __stdio_file+$40,y
    sta cbm_k_chkin1_channel
    // fclose::cbm_k_chkin1
    // char status
    // [2179] fclose::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fclose::cbm_k_readst1
    // char status
    // [2181] fclose::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2183] fclose::cbm_k_readst1_return#0 = fclose::cbm_k_readst1_status -- vbuz1=vbum2 
    sta.z cbm_k_readst1_return
    // fclose::cbm_k_readst1_@return
    // }
    // [2184] fclose::cbm_k_readst1_return#1 = fclose::cbm_k_readst1_return#0
    // fclose::@3
    // cbm_k_readst()
    // [2185] fclose::$1 = fclose::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [2186] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$1 -- pbuc1_derefidx_vbum1=vbuz2 
    lda.z fclose__1
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2187] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@1 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b1
    // fclose::@return
    // }
    // [2188] return 
    rts
    // fclose::@1
  __b1:
    // cbm_k_close(__logical)
    // [2189] fclose::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$40,y
    sta cbm_k_close1_channel
    // fclose::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // fclose::cbm_k_readst2
    // char status
    // [2191] fclose::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [2193] fclose::cbm_k_readst2_return#0 = fclose::cbm_k_readst2_status -- vbuz1=vbum2 
    sta.z cbm_k_readst2_return
    // fclose::cbm_k_readst2_@return
    // }
    // [2194] fclose::cbm_k_readst2_return#1 = fclose::cbm_k_readst2_return#0
    // fclose::@4
    // cbm_k_readst()
    // [2195] fclose::$4 = fclose::cbm_k_readst2_return#1
    // __status = cbm_k_readst()
    // [2196] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$4 -- pbuc1_derefidx_vbum1=vbuz2 
    lda.z fclose__4
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2197] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@2 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b2
    rts
    // fclose::@2
  __b2:
    // __logical = 0
    // [2198] ((char *)&__stdio_file+$40)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy sp
    sta __stdio_file+$40,y
    // __device = 0
    // [2199] ((char *)&__stdio_file+$42)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [2200] ((char *)&__stdio_file+$44)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$44,y
    // __filename
    // [2201] fclose::$6 = fclose::sp#0 << 1 -- vbum1=vbum1_rol_1 
    asl fclose__6
    // *__filename = '\0'
    // [2202] ((char *)&__stdio_file)[fclose::$6] = '@' -- pbuc1_derefidx_vbum1=vbuc2 
    lda #'@'
    ldy fclose__6
    sta __stdio_file,y
    // __stdio_filecount--;
    // [2203] __stdio_filecount = -- __stdio_filecount -- vbum1=_dec_vbum1 
    dec __stdio_filecount
    rts
  .segment Data
    .label fclose__6 = sp
    cbm_k_chkin1_channel: .byte 0
    cbm_k_chkin1_status: .byte 0
    cbm_k_readst1_status: .byte 0
    cbm_k_close1_channel: .byte 0
    cbm_k_readst2_status: .byte 0
    sp: .byte 0
}
.segment Code
  // uctoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void uctoa(__zp($2d) char value, __zp($60) char *buffer, __zp($e4) char radix)
uctoa: {
    .label uctoa__4 = $67
    .label digit_value = $43
    .label buffer = $60
    .label digit = $64
    .label value = $2d
    .label radix = $e4
    .label started = $6e
    .label max_digits = $be
    .label digit_values = $bc
    // if(radix==DECIMAL)
    // [2204] if(uctoa::radix#0==DECIMAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp.z radix
    beq __b2
    // uctoa::@2
    // if(radix==HEXADECIMAL)
    // [2205] if(uctoa::radix#0==HEXADECIMAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp.z radix
    beq __b3
    // uctoa::@3
    // if(radix==OCTAL)
    // [2206] if(uctoa::radix#0==OCTAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp.z radix
    beq __b4
    // uctoa::@4
    // if(radix==BINARY)
    // [2207] if(uctoa::radix#0==BINARY) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp.z radix
    beq __b5
    // uctoa::@5
    // *buffer++ = 'e'
    // [2208] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2209] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2210] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2211] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // uctoa::@return
    // }
    // [2212] return 
    rts
    // [2213] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
  __b2:
    // [2213] phi uctoa::digit_values#8 = RADIX_DECIMAL_VALUES_CHAR [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [2213] phi uctoa::max_digits#7 = 3 [phi:uctoa->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [2213] phi from uctoa::@2 to uctoa::@1 [phi:uctoa::@2->uctoa::@1]
  __b3:
    // [2213] phi uctoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_CHAR [phi:uctoa::@2->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [2213] phi uctoa::max_digits#7 = 2 [phi:uctoa::@2->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #2
    sta.z max_digits
    jmp __b1
    // [2213] phi from uctoa::@3 to uctoa::@1 [phi:uctoa::@3->uctoa::@1]
  __b4:
    // [2213] phi uctoa::digit_values#8 = RADIX_OCTAL_VALUES_CHAR [phi:uctoa::@3->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values+1
    // [2213] phi uctoa::max_digits#7 = 3 [phi:uctoa::@3->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [2213] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
  __b5:
    // [2213] phi uctoa::digit_values#8 = RADIX_BINARY_VALUES_CHAR [phi:uctoa::@4->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_BINARY_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_CHAR
    sta.z digit_values+1
    // [2213] phi uctoa::max_digits#7 = 8 [phi:uctoa::@4->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #8
    sta.z max_digits
    // uctoa::@1
  __b1:
    // [2214] phi from uctoa::@1 to uctoa::@6 [phi:uctoa::@1->uctoa::@6]
    // [2214] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa::@1->uctoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2214] phi uctoa::started#2 = 0 [phi:uctoa::@1->uctoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [2214] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa::@1->uctoa::@6#2] -- register_copy 
    // [2214] phi uctoa::digit#2 = 0 [phi:uctoa::@1->uctoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // uctoa::@6
  __b6:
    // max_digits-1
    // [2215] uctoa::$4 = uctoa::max_digits#7 - 1 -- vbuz1=vbuz2_minus_1 
    ldx.z max_digits
    dex
    stx.z uctoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2216] if(uctoa::digit#2<uctoa::$4) goto uctoa::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z digit
    cmp.z uctoa__4
    bcc __b7
    // uctoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2217] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z value
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2218] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2219] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // uctoa::@7
  __b7:
    // unsigned char digit_value = digit_values[digit]
    // [2220] uctoa::digit_value#0 = uctoa::digit_values#8[uctoa::digit#2] -- vbuz1=pbuz2_derefidx_vbuz3 
    ldy.z digit
    lda (digit_values),y
    sta.z digit_value
    // if (started || value >= digit_value)
    // [2221] if(0!=uctoa::started#2) goto uctoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // uctoa::@12
    // [2222] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@10 -- vbuz1_ge_vbuz2_then_la1 
    lda.z value
    cmp.z digit_value
    bcs __b10
    // [2223] phi from uctoa::@12 to uctoa::@9 [phi:uctoa::@12->uctoa::@9]
    // [2223] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@12->uctoa::@9#0] -- register_copy 
    // [2223] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@12->uctoa::@9#1] -- register_copy 
    // [2223] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@12->uctoa::@9#2] -- register_copy 
    // uctoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2224] uctoa::digit#1 = ++ uctoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [2214] phi from uctoa::@9 to uctoa::@6 [phi:uctoa::@9->uctoa::@6]
    // [2214] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@9->uctoa::@6#0] -- register_copy 
    // [2214] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@9->uctoa::@6#1] -- register_copy 
    // [2214] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@9->uctoa::@6#2] -- register_copy 
    // [2214] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@9->uctoa::@6#3] -- register_copy 
    jmp __b6
    // uctoa::@10
  __b10:
    // uctoa_append(buffer++, value, digit_value)
    // [2225] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [2226] uctoa_append::value#0 = uctoa::value#2
    // [2227] uctoa_append::sub#0 = uctoa::digit_value#0
    // [2228] call uctoa_append
    // [2569] phi from uctoa::@10 to uctoa_append [phi:uctoa::@10->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [2229] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@11
    // value = uctoa_append(buffer++, value, digit_value)
    // [2230] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [2231] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2223] phi from uctoa::@11 to uctoa::@9 [phi:uctoa::@11->uctoa::@9]
    // [2223] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@11->uctoa::@9#0] -- register_copy 
    // [2223] phi uctoa::started#4 = 1 [phi:uctoa::@11->uctoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [2223] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@11->uctoa::@9#2] -- register_copy 
    jmp __b9
}
  // rom_address_from_bank
/**
 * @brief Calculates the 22 bit ROM address from the 8 bit ROM bank.
 * The ROM bank number is calcuated by taking the 8 bits and shifing those 14 bits to the left (bit 21-14).
 *
 * @param rom_bank The 8 bit ROM address.
 * @return unsigned long The 22 bit ROM address.
 */
/* inline */
// __mem() unsigned long rom_address_from_bank(__zp($ed) char rom_bank)
rom_address_from_bank: {
    .label rom_address_from_bank__1 = $57
    .label return = $57
    .label rom_bank = $ed
    .label return_1 = $a9
    // ((unsigned long)(rom_bank)) << 14
    // [2233] rom_address_from_bank::$1 = (unsigned long)rom_address_from_bank::rom_bank#3 -- vduz1=_dword_vbuz2 
    lda.z rom_bank
    sta.z rom_address_from_bank__1
    lda #0
    sta.z rom_address_from_bank__1+1
    sta.z rom_address_from_bank__1+2
    sta.z rom_address_from_bank__1+3
    // [2234] rom_address_from_bank::return#0 = rom_address_from_bank::$1 << $e -- vduz1=vduz1_rol_vbuc1 
    ldx #$e
    cpx #0
    beq !e+
  !:
    asl.z return
    rol.z return+1
    rol.z return+2
    rol.z return+3
    dex
    bne !-
  !e:
    // rom_address_from_bank::@return
    // }
    // [2235] return 
    rts
  .segment Data
    .label return_2 = main.flashed_bytes
}
.segment Code
  // rom_compare
// __zp($51) unsigned int rom_compare(__zp($eb) char bank_ram, __zp($b3) char *ptr_ram, __zp($57) unsigned long rom_compare_address, __zp($d0) unsigned int rom_compare_size)
rom_compare: {
    .label rom_compare__5 = $5d
    .label rom_bank1_rom_compare__0 = $68
    .label rom_bank1_rom_compare__1 = $36
    .label rom_bank1_rom_compare__2 = $71
    .label rom_ptr1_rom_compare__0 = $78
    .label rom_ptr1_rom_compare__2 = $78
    .label bank_set_bram1_bank = $eb
    .label rom_bank1_bank_unshifted = $71
    .label rom_bank1_return = $6a
    .label rom_ptr1_return = $78
    .label ptr_rom = $78
    .label ptr_ram = $b3
    .label compared_bytes = $ad
    /// Holds the amount of bytes actually verified between the ROM and the RAM.
    .label equal_bytes = $51
    .label bank_ram = $eb
    .label rom_compare_address = $57
    .label return = $51
    .label rom_compare_size = $d0
    // rom_compare::bank_set_bram1
    // BRAM = bank
    // [2237] BRAM = rom_compare::bank_set_bram1_bank#0 -- vbuz1=vbuz2 
    lda.z bank_set_bram1_bank
    sta.z BRAM
    // rom_compare::rom_bank1
    // BYTE2(address)
    // [2238] rom_compare::rom_bank1_$0 = byte2  rom_compare::rom_compare_address#3 -- vbuz1=_byte2_vduz2 
    lda.z rom_compare_address+2
    sta.z rom_bank1_rom_compare__0
    // BYTE1(address)
    // [2239] rom_compare::rom_bank1_$1 = byte1  rom_compare::rom_compare_address#3 -- vbuz1=_byte1_vduz2 
    lda.z rom_compare_address+1
    sta.z rom_bank1_rom_compare__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2240] rom_compare::rom_bank1_$2 = rom_compare::rom_bank1_$0 w= rom_compare::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_compare__0
    sta.z rom_bank1_rom_compare__2+1
    lda.z rom_bank1_rom_compare__1
    sta.z rom_bank1_rom_compare__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2241] rom_compare::rom_bank1_bank_unshifted#0 = rom_compare::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2242] rom_compare::rom_bank1_return#0 = byte1  rom_compare::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwuz2 
    lda.z rom_bank1_bank_unshifted+1
    sta.z rom_bank1_return
    // rom_compare::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2243] rom_compare::rom_ptr1_$2 = (unsigned int)rom_compare::rom_compare_address#3 -- vwuz1=_word_vduz2 
    lda.z rom_compare_address
    sta.z rom_ptr1_rom_compare__2
    lda.z rom_compare_address+1
    sta.z rom_ptr1_rom_compare__2+1
    // [2244] rom_compare::rom_ptr1_$0 = rom_compare::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_compare__0
    and #<$3fff
    sta.z rom_ptr1_rom_compare__0
    lda.z rom_ptr1_rom_compare__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_compare__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2245] rom_compare::rom_ptr1_return#0 = rom_compare::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_compare::bank_set_brom1
    // BROM = bank
    // [2246] BROM = rom_compare::rom_bank1_return#0 -- vbuz1=vbuz2 
    lda.z rom_bank1_return
    sta.z BROM
    // [2247] rom_compare::ptr_rom#9 = (char *)rom_compare::rom_ptr1_return#0
    // [2248] phi from rom_compare::bank_set_brom1 to rom_compare::@1 [phi:rom_compare::bank_set_brom1->rom_compare::@1]
    // [2248] phi rom_compare::equal_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z equal_bytes
    sta.z equal_bytes+1
    // [2248] phi rom_compare::ptr_ram#4 = rom_compare::ptr_ram#10 [phi:rom_compare::bank_set_brom1->rom_compare::@1#1] -- register_copy 
    // [2248] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#9 [phi:rom_compare::bank_set_brom1->rom_compare::@1#2] -- register_copy 
    // [2248] phi rom_compare::compared_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#3] -- vwuz1=vwuc1 
    sta.z compared_bytes
    sta.z compared_bytes+1
    // rom_compare::@1
  __b1:
    // while (compared_bytes < rom_compare_size)
    // [2249] if(rom_compare::compared_bytes#2<rom_compare::rom_compare_size#11) goto rom_compare::@2 -- vwuz1_lt_vwuz2_then_la1 
    lda.z compared_bytes+1
    cmp.z rom_compare_size+1
    bcc __b2
    bne !+
    lda.z compared_bytes
    cmp.z rom_compare_size
    bcc __b2
  !:
    // rom_compare::@return
    // }
    // [2250] return 
    rts
    // rom_compare::@2
  __b2:
    // rom_byte_compare(ptr_rom, *ptr_ram)
    // [2251] rom_byte_compare::ptr_rom#0 = rom_compare::ptr_rom#2
    // [2252] rom_byte_compare::value#0 = *rom_compare::ptr_ram#4 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (ptr_ram),y
    sta.z rom_byte_compare.value
    // [2253] call rom_byte_compare
    jsr rom_byte_compare
    // [2254] rom_byte_compare::return#2 = rom_byte_compare::return#0
    // rom_compare::@5
    // [2255] rom_compare::$5 = rom_byte_compare::return#2
    // if (rom_byte_compare(ptr_rom, *ptr_ram))
    // [2256] if(0==rom_compare::$5) goto rom_compare::@3 -- 0_eq_vbuz1_then_la1 
    lda.z rom_compare__5
    beq __b3
    // rom_compare::@4
    // equal_bytes++;
    // [2257] rom_compare::equal_bytes#1 = ++ rom_compare::equal_bytes#2 -- vwuz1=_inc_vwuz1 
    inc.z equal_bytes
    bne !+
    inc.z equal_bytes+1
  !:
    // [2258] phi from rom_compare::@4 rom_compare::@5 to rom_compare::@3 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3]
    // [2258] phi rom_compare::equal_bytes#6 = rom_compare::equal_bytes#1 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3#0] -- register_copy 
    // rom_compare::@3
  __b3:
    // ptr_rom++;
    // [2259] rom_compare::ptr_rom#1 = ++ rom_compare::ptr_rom#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr_rom
    bne !+
    inc.z ptr_rom+1
  !:
    // ptr_ram++;
    // [2260] rom_compare::ptr_ram#0 = ++ rom_compare::ptr_ram#4 -- pbuz1=_inc_pbuz1 
    inc.z ptr_ram
    bne !+
    inc.z ptr_ram+1
  !:
    // compared_bytes++;
    // [2261] rom_compare::compared_bytes#1 = ++ rom_compare::compared_bytes#2 -- vwuz1=_inc_vwuz1 
    inc.z compared_bytes
    bne !+
    inc.z compared_bytes+1
  !:
    // [2248] phi from rom_compare::@3 to rom_compare::@1 [phi:rom_compare::@3->rom_compare::@1]
    // [2248] phi rom_compare::equal_bytes#2 = rom_compare::equal_bytes#6 [phi:rom_compare::@3->rom_compare::@1#0] -- register_copy 
    // [2248] phi rom_compare::ptr_ram#4 = rom_compare::ptr_ram#0 [phi:rom_compare::@3->rom_compare::@1#1] -- register_copy 
    // [2248] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#1 [phi:rom_compare::@3->rom_compare::@1#2] -- register_copy 
    // [2248] phi rom_compare::compared_bytes#2 = rom_compare::compared_bytes#1 [phi:rom_compare::@3->rom_compare::@1#3] -- register_copy 
    jmp __b1
}
  // ultoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void ultoa(__zp($30) unsigned long value, __zp($3d) char *buffer, __zp($e5) char radix)
ultoa: {
    .label ultoa__4 = $68
    .label ultoa__10 = $6a
    .label ultoa__11 = $36
    .label digit_value = $3f
    .label buffer = $3d
    .label digit = $65
    .label value = $30
    .label radix = $e5
    .label started = $6f
    .label max_digits = $b5
    .label digit_values = $b1
    // if(radix==DECIMAL)
    // [2262] if(ultoa::radix#0==DECIMAL) goto ultoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp.z radix
    beq __b2
    // ultoa::@2
    // if(radix==HEXADECIMAL)
    // [2263] if(ultoa::radix#0==HEXADECIMAL) goto ultoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp.z radix
    beq __b3
    // ultoa::@3
    // if(radix==OCTAL)
    // [2264] if(ultoa::radix#0==OCTAL) goto ultoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp.z radix
    beq __b4
    // ultoa::@4
    // if(radix==BINARY)
    // [2265] if(ultoa::radix#0==BINARY) goto ultoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp.z radix
    beq __b5
    // ultoa::@5
    // *buffer++ = 'e'
    // [2266] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2267] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2268] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2269] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // ultoa::@return
    // }
    // [2270] return 
    rts
    // [2271] phi from ultoa to ultoa::@1 [phi:ultoa->ultoa::@1]
  __b2:
    // [2271] phi ultoa::digit_values#8 = RADIX_DECIMAL_VALUES_LONG [phi:ultoa->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2271] phi ultoa::max_digits#7 = $a [phi:ultoa->ultoa::@1#1] -- vbuz1=vbuc1 
    lda #$a
    sta.z max_digits
    jmp __b1
    // [2271] phi from ultoa::@2 to ultoa::@1 [phi:ultoa::@2->ultoa::@1]
  __b3:
    // [2271] phi ultoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_LONG [phi:ultoa::@2->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2271] phi ultoa::max_digits#7 = 8 [phi:ultoa::@2->ultoa::@1#1] -- vbuz1=vbuc1 
    lda #8
    sta.z max_digits
    jmp __b1
    // [2271] phi from ultoa::@3 to ultoa::@1 [phi:ultoa::@3->ultoa::@1]
  __b4:
    // [2271] phi ultoa::digit_values#8 = RADIX_OCTAL_VALUES_LONG [phi:ultoa::@3->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_OCTAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_LONG
    sta.z digit_values+1
    // [2271] phi ultoa::max_digits#7 = $b [phi:ultoa::@3->ultoa::@1#1] -- vbuz1=vbuc1 
    lda #$b
    sta.z max_digits
    jmp __b1
    // [2271] phi from ultoa::@4 to ultoa::@1 [phi:ultoa::@4->ultoa::@1]
  __b5:
    // [2271] phi ultoa::digit_values#8 = RADIX_BINARY_VALUES_LONG [phi:ultoa::@4->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_BINARY_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_LONG
    sta.z digit_values+1
    // [2271] phi ultoa::max_digits#7 = $20 [phi:ultoa::@4->ultoa::@1#1] -- vbuz1=vbuc1 
    lda #$20
    sta.z max_digits
    // ultoa::@1
  __b1:
    // [2272] phi from ultoa::@1 to ultoa::@6 [phi:ultoa::@1->ultoa::@6]
    // [2272] phi ultoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:ultoa::@1->ultoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2272] phi ultoa::started#2 = 0 [phi:ultoa::@1->ultoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [2272] phi ultoa::value#2 = ultoa::value#1 [phi:ultoa::@1->ultoa::@6#2] -- register_copy 
    // [2272] phi ultoa::digit#2 = 0 [phi:ultoa::@1->ultoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // ultoa::@6
  __b6:
    // max_digits-1
    // [2273] ultoa::$4 = ultoa::max_digits#7 - 1 -- vbuz1=vbuz2_minus_1 
    ldx.z max_digits
    dex
    stx.z ultoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2274] if(ultoa::digit#2<ultoa::$4) goto ultoa::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z digit
    cmp.z ultoa__4
    bcc __b7
    // ultoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2275] ultoa::$11 = (char)ultoa::value#2 -- vbuz1=_byte_vduz2 
    lda.z value
    sta.z ultoa__11
    // [2276] *ultoa::buffer#11 = DIGITS[ultoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2277] ultoa::buffer#3 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2278] *ultoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // ultoa::@7
  __b7:
    // unsigned long digit_value = digit_values[digit]
    // [2279] ultoa::$10 = ultoa::digit#2 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z digit
    asl
    asl
    sta.z ultoa__10
    // [2280] ultoa::digit_value#0 = ultoa::digit_values#8[ultoa::$10] -- vduz1=pduz2_derefidx_vbuz3 
    tay
    lda (digit_values),y
    sta.z digit_value
    iny
    lda (digit_values),y
    sta.z digit_value+1
    iny
    lda (digit_values),y
    sta.z digit_value+2
    iny
    lda (digit_values),y
    sta.z digit_value+3
    // if (started || value >= digit_value)
    // [2281] if(0!=ultoa::started#2) goto ultoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // ultoa::@12
    // [2282] if(ultoa::value#2>=ultoa::digit_value#0) goto ultoa::@10 -- vduz1_ge_vduz2_then_la1 
    lda.z value+3
    cmp.z digit_value+3
    bcc !+
    bne __b10
    lda.z value+2
    cmp.z digit_value+2
    bcc !+
    bne __b10
    lda.z value+1
    cmp.z digit_value+1
    bcc !+
    bne __b10
    lda.z value
    cmp.z digit_value
    bcs __b10
  !:
    // [2283] phi from ultoa::@12 to ultoa::@9 [phi:ultoa::@12->ultoa::@9]
    // [2283] phi ultoa::buffer#14 = ultoa::buffer#11 [phi:ultoa::@12->ultoa::@9#0] -- register_copy 
    // [2283] phi ultoa::started#4 = ultoa::started#2 [phi:ultoa::@12->ultoa::@9#1] -- register_copy 
    // [2283] phi ultoa::value#6 = ultoa::value#2 [phi:ultoa::@12->ultoa::@9#2] -- register_copy 
    // ultoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2284] ultoa::digit#1 = ++ ultoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [2272] phi from ultoa::@9 to ultoa::@6 [phi:ultoa::@9->ultoa::@6]
    // [2272] phi ultoa::buffer#11 = ultoa::buffer#14 [phi:ultoa::@9->ultoa::@6#0] -- register_copy 
    // [2272] phi ultoa::started#2 = ultoa::started#4 [phi:ultoa::@9->ultoa::@6#1] -- register_copy 
    // [2272] phi ultoa::value#2 = ultoa::value#6 [phi:ultoa::@9->ultoa::@6#2] -- register_copy 
    // [2272] phi ultoa::digit#2 = ultoa::digit#1 [phi:ultoa::@9->ultoa::@6#3] -- register_copy 
    jmp __b6
    // ultoa::@10
  __b10:
    // ultoa_append(buffer++, value, digit_value)
    // [2285] ultoa_append::buffer#0 = ultoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z ultoa_append.buffer
    lda.z buffer+1
    sta.z ultoa_append.buffer+1
    // [2286] ultoa_append::value#0 = ultoa::value#2
    // [2287] ultoa_append::sub#0 = ultoa::digit_value#0
    // [2288] call ultoa_append
    // [2580] phi from ultoa::@10 to ultoa_append [phi:ultoa::@10->ultoa_append]
    jsr ultoa_append
    // ultoa_append(buffer++, value, digit_value)
    // [2289] ultoa_append::return#0 = ultoa_append::value#2
    // ultoa::@11
    // value = ultoa_append(buffer++, value, digit_value)
    // [2290] ultoa::value#0 = ultoa_append::return#0
    // value = ultoa_append(buffer++, value, digit_value);
    // [2291] ultoa::buffer#4 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2283] phi from ultoa::@11 to ultoa::@9 [phi:ultoa::@11->ultoa::@9]
    // [2283] phi ultoa::buffer#14 = ultoa::buffer#4 [phi:ultoa::@11->ultoa::@9#0] -- register_copy 
    // [2283] phi ultoa::started#4 = 1 [phi:ultoa::@11->ultoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [2283] phi ultoa::value#6 = ultoa::value#0 [phi:ultoa::@11->ultoa::@9#2] -- register_copy 
    jmp __b9
}
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
    .label rom_ptr1_rom_sector_erase__0 = $3d
    .label rom_ptr1_rom_sector_erase__2 = $3d
    .label rom_ptr1_return = $3d
    .label rom_chip_address = $7a
    // rom_sector_erase::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2293] rom_sector_erase::rom_ptr1_$2 = (unsigned int)rom_sector_erase::address#0 -- vwuz1=_word_vdum2 
    lda address
    sta.z rom_ptr1_rom_sector_erase__2
    lda address+1
    sta.z rom_ptr1_rom_sector_erase__2+1
    // [2294] rom_sector_erase::rom_ptr1_$0 = rom_sector_erase::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_sector_erase__0
    and #<$3fff
    sta.z rom_ptr1_rom_sector_erase__0
    lda.z rom_ptr1_rom_sector_erase__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_sector_erase__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2295] rom_sector_erase::rom_ptr1_return#0 = rom_sector_erase::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_sector_erase::@1
    // unsigned long rom_chip_address = address & ROM_CHIP_MASK
    // [2296] rom_sector_erase::rom_chip_address#0 = rom_sector_erase::address#0 & $380000 -- vduz1=vdum2_band_vduc1 
    lda address
    and #<$380000
    sta.z rom_chip_address
    lda address+1
    and #>$380000
    sta.z rom_chip_address+1
    lda address+2
    and #<$380000>>$10
    sta.z rom_chip_address+2
    lda address+3
    and #>$380000>>$10
    sta.z rom_chip_address+3
    // rom_unlock(rom_chip_address + 0x05555, 0x80)
    // [2297] rom_unlock::address#0 = rom_sector_erase::rom_chip_address#0 + $5555 -- vduz1=vduz1_plus_vwuc1 
    clc
    lda.z rom_unlock.address
    adc #<$5555
    sta.z rom_unlock.address
    lda.z rom_unlock.address+1
    adc #>$5555
    sta.z rom_unlock.address+1
    lda.z rom_unlock.address+2
    adc #0
    sta.z rom_unlock.address+2
    lda.z rom_unlock.address+3
    adc #0
    sta.z rom_unlock.address+3
    // [2298] call rom_unlock
    // [2019] phi from rom_sector_erase::@1 to rom_unlock [phi:rom_sector_erase::@1->rom_unlock]
    // [2019] phi rom_unlock::unlock_code#5 = $80 [phi:rom_sector_erase::@1->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$80
    sta.z rom_unlock.unlock_code
    // [2019] phi rom_unlock::address#5 = rom_unlock::address#0 [phi:rom_sector_erase::@1->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@2
    // rom_unlock(address, 0x30)
    // [2299] rom_unlock::address#1 = rom_sector_erase::address#0 -- vduz1=vdum2 
    lda address
    sta.z rom_unlock.address
    lda address+1
    sta.z rom_unlock.address+1
    lda address+2
    sta.z rom_unlock.address+2
    lda address+3
    sta.z rom_unlock.address+3
    // [2300] call rom_unlock
    // [2019] phi from rom_sector_erase::@2 to rom_unlock [phi:rom_sector_erase::@2->rom_unlock]
    // [2019] phi rom_unlock::unlock_code#5 = $30 [phi:rom_sector_erase::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$30
    sta.z rom_unlock.unlock_code
    // [2019] phi rom_unlock::address#5 = rom_unlock::address#1 [phi:rom_sector_erase::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@3
    // rom_wait(ptr_rom)
    // [2301] rom_wait::ptr_rom#0 = (char *)rom_sector_erase::rom_ptr1_return#0
    // [2302] call rom_wait
    // [2587] phi from rom_sector_erase::@3 to rom_wait [phi:rom_sector_erase::@3->rom_wait]
    // [2587] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#0 [phi:rom_sector_erase::@3->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_sector_erase::@return
    // }
    // [2303] return 
    rts
  .segment Data
    .label address = printf_ulong.uvalue_1
}
.segment Code
  // rom_write
/* inline */
// unsigned long rom_write(__zp($f1) char flash_ram_bank, __zp($b1) char *flash_ram_address, __zp($b6) unsigned long flash_rom_address, unsigned int flash_rom_size)
rom_write: {
    .label rom_chip_address = $c6
    .label flash_rom_address = $b6
    .label flash_ram_address = $b1
    .label flashed_bytes = $a9
    .label flash_ram_bank = $f1
    // unsigned long rom_chip_address = flash_rom_address & ROM_CHIP_MASK
    // [2304] rom_write::rom_chip_address#0 = rom_write::flash_rom_address#1 & $380000 -- vduz1=vduz2_band_vduc1 
    /// Holds the amount of bytes actually flashed in the ROM.
    lda.z flash_rom_address
    and #<$380000
    sta.z rom_chip_address
    lda.z flash_rom_address+1
    and #>$380000
    sta.z rom_chip_address+1
    lda.z flash_rom_address+2
    and #<$380000>>$10
    sta.z rom_chip_address+2
    lda.z flash_rom_address+3
    and #>$380000>>$10
    sta.z rom_chip_address+3
    // rom_write::bank_set_bram1
    // BRAM = bank
    // [2305] BRAM = rom_write::flash_ram_bank#0 -- vbuz1=vbuz2 
    lda.z flash_ram_bank
    sta.z BRAM
    // [2306] phi from rom_write::bank_set_bram1 to rom_write::@1 [phi:rom_write::bank_set_bram1->rom_write::@1]
    // [2306] phi rom_write::flash_ram_address#2 = rom_write::flash_ram_address#1 [phi:rom_write::bank_set_bram1->rom_write::@1#0] -- register_copy 
    // [2306] phi rom_write::flash_rom_address#3 = rom_write::flash_rom_address#1 [phi:rom_write::bank_set_bram1->rom_write::@1#1] -- register_copy 
    // [2306] phi rom_write::flashed_bytes#2 = 0 [phi:rom_write::bank_set_bram1->rom_write::@1#2] -- vduz1=vduc1 
    lda #<0
    sta.z flashed_bytes
    sta.z flashed_bytes+1
    lda #<0>>$10
    sta.z flashed_bytes+2
    lda #>0>>$10
    sta.z flashed_bytes+3
    // rom_write::@1
  __b1:
    // while (flashed_bytes < flash_rom_size)
    // [2307] if(rom_write::flashed_bytes#2<ROM_PROGRESS_CELL) goto rom_write::@2 -- vduz1_lt_vduc1_then_la1 
    lda.z flashed_bytes+3
    cmp #>ROM_PROGRESS_CELL>>$10
    bcc __b2
    bne !+
    lda.z flashed_bytes+2
    cmp #<ROM_PROGRESS_CELL>>$10
    bcc __b2
    bne !+
    lda.z flashed_bytes+1
    cmp #>ROM_PROGRESS_CELL
    bcc __b2
    bne !+
    lda.z flashed_bytes
    cmp #<ROM_PROGRESS_CELL
    bcc __b2
  !:
    // rom_write::@return
    // }
    // [2308] return 
    rts
    // rom_write::@2
  __b2:
    // rom_unlock(rom_chip_address + 0x05555, 0xA0)
    // [2309] rom_unlock::address#4 = rom_write::rom_chip_address#0 + $5555 -- vduz1=vduz2_plus_vwuc1 
    clc
    lda.z rom_chip_address
    adc #<$5555
    sta.z rom_unlock.address
    lda.z rom_chip_address+1
    adc #>$5555
    sta.z rom_unlock.address+1
    lda.z rom_chip_address+2
    adc #0
    sta.z rom_unlock.address+2
    lda.z rom_chip_address+3
    adc #0
    sta.z rom_unlock.address+3
    // [2310] call rom_unlock
    // [2019] phi from rom_write::@2 to rom_unlock [phi:rom_write::@2->rom_unlock]
    // [2019] phi rom_unlock::unlock_code#5 = $a0 [phi:rom_write::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$a0
    sta.z rom_unlock.unlock_code
    // [2019] phi rom_unlock::address#5 = rom_unlock::address#4 [phi:rom_write::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_write::@3
    // rom_byte_program(flash_rom_address, *flash_ram_address)
    // [2311] rom_byte_program::address#0 = rom_write::flash_rom_address#3 -- vduz1=vduz2 
    lda.z flash_rom_address
    sta.z rom_byte_program.address
    lda.z flash_rom_address+1
    sta.z rom_byte_program.address+1
    lda.z flash_rom_address+2
    sta.z rom_byte_program.address+2
    lda.z flash_rom_address+3
    sta.z rom_byte_program.address+3
    // [2312] rom_byte_program::value#0 = *rom_write::flash_ram_address#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (flash_ram_address),y
    sta.z rom_byte_program.value
    // [2313] call rom_byte_program
    // [2594] phi from rom_write::@3 to rom_byte_program [phi:rom_write::@3->rom_byte_program]
    jsr rom_byte_program
    // rom_write::@4
    // flash_rom_address++;
    // [2314] rom_write::flash_rom_address#0 = ++ rom_write::flash_rom_address#3 -- vduz1=_inc_vduz1 
    inc.z flash_rom_address
    bne !+
    inc.z flash_rom_address+1
    bne !+
    inc.z flash_rom_address+2
    bne !+
    inc.z flash_rom_address+3
  !:
    // flash_ram_address++;
    // [2315] rom_write::flash_ram_address#0 = ++ rom_write::flash_ram_address#2 -- pbuz1=_inc_pbuz1 
    inc.z flash_ram_address
    bne !+
    inc.z flash_ram_address+1
  !:
    // flashed_bytes++;
    // [2316] rom_write::flashed_bytes#1 = ++ rom_write::flashed_bytes#2 -- vduz1=_inc_vduz1 
    inc.z flashed_bytes
    bne !+
    inc.z flashed_bytes+1
    bne !+
    inc.z flashed_bytes+2
    bne !+
    inc.z flashed_bytes+3
  !:
    // [2306] phi from rom_write::@4 to rom_write::@1 [phi:rom_write::@4->rom_write::@1]
    // [2306] phi rom_write::flash_ram_address#2 = rom_write::flash_ram_address#0 [phi:rom_write::@4->rom_write::@1#0] -- register_copy 
    // [2306] phi rom_write::flash_rom_address#3 = rom_write::flash_rom_address#0 [phi:rom_write::@4->rom_write::@1#1] -- register_copy 
    // [2306] phi rom_write::flashed_bytes#2 = rom_write::flashed_bytes#1 [phi:rom_write::@4->rom_write::@1#2] -- register_copy 
    jmp __b1
}
  // cbm_k_getin
/**
 * @brief Scan a character from keyboard without pressing enter.
 * 
 * @return char The character read.
 */
cbm_k_getin: {
    .label return = $d2
    // __mem unsigned char ch
    // [2317] cbm_k_getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // asm
    // asm { jsrCBM_GETIN stach  }
    jsr CBM_GETIN
    sta ch
    // return ch;
    // [2319] cbm_k_getin::return#0 = cbm_k_getin::ch -- vbuz1=vbum2 
    sta.z return
    // cbm_k_getin::@return
    // }
    // [2320] cbm_k_getin::return#1 = cbm_k_getin::return#0
    // [2321] return 
    rts
  .segment Data
    ch: .byte 0
}
.segment Code
  // insertup
// Insert a new line, and scroll the upper part of the screen up.
// void insertup(char rows)
insertup: {
    .label insertup__0 = $46
    .label insertup__4 = $3b
    .label insertup__6 = $3c
    .label insertup__7 = $3b
    .label width = $46
    .label y = $34
    // __conio.width+1
    // [2322] insertup::$0 = *((char *)&__conio+6) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+6
    inc
    sta.z insertup__0
    // unsigned char width = (__conio.width+1) * 2
    // [2323] insertup::width#0 = insertup::$0 << 1 -- vbuz1=vbuz1_rol_1 
    // {asm{.byte $db}}
    asl.z width
    // [2324] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [2324] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [2325] if(insertup::y#2<*((char *)&__conio+1)) goto insertup::@2 -- vbuz1_lt__deref_pbuc1_then_la1 
    lda.z y
    cmp __conio+1
    bcc __b2
    // [2326] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [2327] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [2328] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [2329] insertup::$4 = insertup::y#2 + 1 -- vbuz1=vbuz2_plus_1 
    lda.z y
    inc
    sta.z insertup__4
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [2330] insertup::$6 = insertup::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z insertup__6
    // [2331] insertup::$7 = insertup::$4 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z insertup__7
    // [2332] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z memcpy8_vram_vram.dbank_vram
    // [2333] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__6
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.doffset_vram+1
    // [2334] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z memcpy8_vram_vram.sbank_vram
    // [2335] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__7
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.soffset_vram+1
    // [2336] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbuz1=vbuz2 
    lda.z width
    sta.z memcpy8_vram_vram.num8_1
    // [2337] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [2338] insertup::y#1 = ++ insertup::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [2324] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [2324] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
    jmp __b1
}
  // clearline
clearline: {
    .label clearline__0 = $24
    .label clearline__1 = $26
    .label clearline__2 = $27
    .label clearline__3 = $25
    .label addr = $39
    .label c = $22
    // unsigned int addr = __conio.offsets[__conio.cursor_y]
    // [2339] clearline::$3 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z clearline__3
    // [2340] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwuz1=pwuc1_derefidx_vbuz2 
    tay
    lda __conio+$15,y
    sta.z addr
    lda __conio+$15+1,y
    sta.z addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2341] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [2342] clearline::$0 = byte0  clearline::addr#0 -- vbuz1=_byte0_vwuz2 
    lda.z addr
    sta.z clearline__0
    // *VERA_ADDRX_L = BYTE0(addr)
    // [2343] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [2344] clearline::$1 = byte1  clearline::addr#0 -- vbuz1=_byte1_vwuz2 
    lda.z addr+1
    sta.z clearline__1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [2345] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [2346] clearline::$2 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clearline__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [2347] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [2348] clearline::c#0 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z c
    // [2349] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [2349] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [2350] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [2351] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [2352] clearline::c#1 = -- clearline::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [2353] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b1
    // clearline::@return
    // }
    // [2354] return 
    rts
}
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
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__0 = $77
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__1 = $5b
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__2 = $54
    .label c = $5d
    // display_frame_maskxy::cpeekcxy1
    // gotoxy(x,y)
    // [2356] gotoxy::x#5 = display_frame_maskxy::cpeekcxy1_x#0 -- vbuz1=vbum2 
    lda cpeekcxy1_x
    sta.z gotoxy.x
    // [2357] gotoxy::y#5 = display_frame_maskxy::cpeekcxy1_y#0 -- vbuz1=vbum2 
    lda cpeekcxy1_y
    sta.z gotoxy.y
    // [2358] call gotoxy
    // [610] phi from display_frame_maskxy::cpeekcxy1 to gotoxy [phi:display_frame_maskxy::cpeekcxy1->gotoxy]
    // [610] phi gotoxy::y#30 = gotoxy::y#5 [phi:display_frame_maskxy::cpeekcxy1->gotoxy#0] -- register_copy 
    // [610] phi gotoxy::x#30 = gotoxy::x#5 [phi:display_frame_maskxy::cpeekcxy1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_frame_maskxy::cpeekcxy1_cpeekc1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2359] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(__conio.offset)
    // [2360] display_frame_maskxy::cpeekcxy1_cpeekc1_$0 = byte0  *((unsigned int *)&__conio+$13) -- vbuz1=_byte0__deref_pwuc1 
    lda __conio+$13
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__0
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [2361] *VERA_ADDRX_L = display_frame_maskxy::cpeekcxy1_cpeekc1_$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [2362] display_frame_maskxy::cpeekcxy1_cpeekc1_$1 = byte1  *((unsigned int *)&__conio+$13) -- vbuz1=_byte1__deref_pwuc1 
    lda __conio+$13+1
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__1
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [2363] *VERA_ADDRX_M = display_frame_maskxy::cpeekcxy1_cpeekc1_$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_0
    // [2364] display_frame_maskxy::cpeekcxy1_cpeekc1_$2 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_0
    // [2365] *VERA_ADDRX_H = display_frame_maskxy::cpeekcxy1_cpeekc1_$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // return *VERA_DATA0;
    // [2366] display_frame_maskxy::c#0 = *VERA_DATA0 -- vbuz1=_deref_pbuc1 
    lda VERA_DATA0
    sta.z c
    // display_frame_maskxy::@12
    // case 0x70: // DR corner.
    //             return 0b0110;
    // [2367] if(display_frame_maskxy::c#0==$70) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$70
    cmp.z c
    beq __b2
    // display_frame_maskxy::@1
    // case 0x6E: // DL corner.
    //             return 0b0011;
    // [2368] if(display_frame_maskxy::c#0==$6e) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6e
    cmp.z c
    beq __b1
    // display_frame_maskxy::@2
    // case 0x6D: // UR corner.
    //             return 0b1100;
    // [2369] if(display_frame_maskxy::c#0==$6d) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6d
    cmp.z c
    beq __b3
    // display_frame_maskxy::@3
    // case 0x7D: // UL corner.
    //             return 0b1001;
    // [2370] if(display_frame_maskxy::c#0==$7d) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$7d
    cmp.z c
    beq __b4
    // display_frame_maskxy::@4
    // case 0x40: // HL line.
    //             return 0b0101;
    // [2371] if(display_frame_maskxy::c#0==$40) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$40
    cmp.z c
    beq __b5
    // display_frame_maskxy::@5
    // case 0x5D: // VL line.
    //             return 0b1010;
    // [2372] if(display_frame_maskxy::c#0==$5d) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$5d
    cmp.z c
    beq __b6
    // display_frame_maskxy::@6
    // case 0x6B: // VR junction.
    //             return 0b1110;
    // [2373] if(display_frame_maskxy::c#0==$6b) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6b
    cmp.z c
    beq __b7
    // display_frame_maskxy::@7
    // case 0x73: // VL junction.
    //             return 0b1011;
    // [2374] if(display_frame_maskxy::c#0==$73) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$73
    cmp.z c
    beq __b8
    // display_frame_maskxy::@8
    // case 0x72: // HD junction.
    //             return 0b0111;
    // [2375] if(display_frame_maskxy::c#0==$72) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$72
    cmp.z c
    beq __b9
    // display_frame_maskxy::@9
    // case 0x71: // HU junction.
    //             return 0b1101;
    // [2376] if(display_frame_maskxy::c#0==$71) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$71
    cmp.z c
    beq __b10
    // display_frame_maskxy::@10
    // case 0x5B: // HV junction.
    //             return 0b1111;
    // [2377] if(display_frame_maskxy::c#0==$5b) goto display_frame_maskxy::@11 -- vbuz1_eq_vbuc1_then_la1 
    lda #$5b
    cmp.z c
    beq __b11
    // [2379] phi from display_frame_maskxy::@10 to display_frame_maskxy::@return [phi:display_frame_maskxy::@10->display_frame_maskxy::@return]
    // [2379] phi display_frame_maskxy::return#12 = 0 [phi:display_frame_maskxy::@10->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    rts
    // [2378] phi from display_frame_maskxy::@10 to display_frame_maskxy::@11 [phi:display_frame_maskxy::@10->display_frame_maskxy::@11]
    // display_frame_maskxy::@11
  __b11:
    // [2379] phi from display_frame_maskxy::@11 to display_frame_maskxy::@return [phi:display_frame_maskxy::@11->display_frame_maskxy::@return]
    // [2379] phi display_frame_maskxy::return#12 = $f [phi:display_frame_maskxy::@11->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$f
    sta return
    rts
    // [2379] phi from display_frame_maskxy::@1 to display_frame_maskxy::@return [phi:display_frame_maskxy::@1->display_frame_maskxy::@return]
  __b1:
    // [2379] phi display_frame_maskxy::return#12 = 3 [phi:display_frame_maskxy::@1->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #3
    sta return
    rts
    // [2379] phi from display_frame_maskxy::@12 to display_frame_maskxy::@return [phi:display_frame_maskxy::@12->display_frame_maskxy::@return]
  __b2:
    // [2379] phi display_frame_maskxy::return#12 = 6 [phi:display_frame_maskxy::@12->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #6
    sta return
    rts
    // [2379] phi from display_frame_maskxy::@2 to display_frame_maskxy::@return [phi:display_frame_maskxy::@2->display_frame_maskxy::@return]
  __b3:
    // [2379] phi display_frame_maskxy::return#12 = $c [phi:display_frame_maskxy::@2->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$c
    sta return
    rts
    // [2379] phi from display_frame_maskxy::@3 to display_frame_maskxy::@return [phi:display_frame_maskxy::@3->display_frame_maskxy::@return]
  __b4:
    // [2379] phi display_frame_maskxy::return#12 = 9 [phi:display_frame_maskxy::@3->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #9
    sta return
    rts
    // [2379] phi from display_frame_maskxy::@4 to display_frame_maskxy::@return [phi:display_frame_maskxy::@4->display_frame_maskxy::@return]
  __b5:
    // [2379] phi display_frame_maskxy::return#12 = 5 [phi:display_frame_maskxy::@4->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #5
    sta return
    rts
    // [2379] phi from display_frame_maskxy::@5 to display_frame_maskxy::@return [phi:display_frame_maskxy::@5->display_frame_maskxy::@return]
  __b6:
    // [2379] phi display_frame_maskxy::return#12 = $a [phi:display_frame_maskxy::@5->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$a
    sta return
    rts
    // [2379] phi from display_frame_maskxy::@6 to display_frame_maskxy::@return [phi:display_frame_maskxy::@6->display_frame_maskxy::@return]
  __b7:
    // [2379] phi display_frame_maskxy::return#12 = $e [phi:display_frame_maskxy::@6->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$e
    sta return
    rts
    // [2379] phi from display_frame_maskxy::@7 to display_frame_maskxy::@return [phi:display_frame_maskxy::@7->display_frame_maskxy::@return]
  __b8:
    // [2379] phi display_frame_maskxy::return#12 = $b [phi:display_frame_maskxy::@7->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$b
    sta return
    rts
    // [2379] phi from display_frame_maskxy::@8 to display_frame_maskxy::@return [phi:display_frame_maskxy::@8->display_frame_maskxy::@return]
  __b9:
    // [2379] phi display_frame_maskxy::return#12 = 7 [phi:display_frame_maskxy::@8->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #7
    sta return
    rts
    // [2379] phi from display_frame_maskxy::@9 to display_frame_maskxy::@return [phi:display_frame_maskxy::@9->display_frame_maskxy::@return]
  __b10:
    // [2379] phi display_frame_maskxy::return#12 = $d [phi:display_frame_maskxy::@9->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$d
    sta return
    // display_frame_maskxy::@return
    // }
    // [2380] return 
    rts
  .segment Data
    .label cpeekcxy1_x = fclose.sp
    cpeekcxy1_y: .byte 0
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
    .label x = fclose.sp
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
// __zp($d2) char display_frame_char(__mem() char mask)
display_frame_char: {
    .label return = $d2
    // case 0b0110:
    //             return 0x70;
    // [2382] if(display_frame_char::mask#10==6) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    lda #6
    cmp mask
    beq __b1
    // display_frame_char::@1
    // case 0b0011:
    //             return 0x6E;
    // [2383] if(display_frame_char::mask#10==3) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // DR corner.
    lda #3
    cmp mask
    beq __b2
    // display_frame_char::@2
    // case 0b1100:
    //             return 0x6D;
    // [2384] if(display_frame_char::mask#10==$c) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // DL corner.
    lda #$c
    cmp mask
    beq __b3
    // display_frame_char::@3
    // case 0b1001:
    //             return 0x7D;
    // [2385] if(display_frame_char::mask#10==9) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // UR corner.
    lda #9
    cmp mask
    beq __b4
    // display_frame_char::@4
    // case 0b0101:
    //             return 0x40;
    // [2386] if(display_frame_char::mask#10==5) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // UL corner.
    lda #5
    cmp mask
    beq __b5
    // display_frame_char::@5
    // case 0b1010:
    //             return 0x5D;
    // [2387] if(display_frame_char::mask#10==$a) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // HL line.
    lda #$a
    cmp mask
    beq __b6
    // display_frame_char::@6
    // case 0b1110:
    //             return 0x6B;
    // [2388] if(display_frame_char::mask#10==$e) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // VL line.
    lda #$e
    cmp mask
    beq __b7
    // display_frame_char::@7
    // case 0b1011:
    //             return 0x73;
    // [2389] if(display_frame_char::mask#10==$b) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // VR junction.
    lda #$b
    cmp mask
    beq __b8
    // display_frame_char::@8
    // case 0b0111:
    //             return 0x72;
    // [2390] if(display_frame_char::mask#10==7) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // VL junction.
    lda #7
    cmp mask
    beq __b9
    // display_frame_char::@9
    // case 0b1101:
    //             return 0x71;
    // [2391] if(display_frame_char::mask#10==$d) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // HD junction.
    lda #$d
    cmp mask
    beq __b10
    // display_frame_char::@10
    // case 0b1111:
    //             return 0x5B;
    // [2392] if(display_frame_char::mask#10==$f) goto display_frame_char::@11 -- vbum1_eq_vbuc1_then_la1 
    // HU junction.
    lda #$f
    cmp mask
    beq __b11
    // [2394] phi from display_frame_char::@10 to display_frame_char::@return [phi:display_frame_char::@10->display_frame_char::@return]
    // [2394] phi display_frame_char::return#12 = $20 [phi:display_frame_char::@10->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$20
    sta.z return
    rts
    // [2393] phi from display_frame_char::@10 to display_frame_char::@11 [phi:display_frame_char::@10->display_frame_char::@11]
    // display_frame_char::@11
  __b11:
    // [2394] phi from display_frame_char::@11 to display_frame_char::@return [phi:display_frame_char::@11->display_frame_char::@return]
    // [2394] phi display_frame_char::return#12 = $5b [phi:display_frame_char::@11->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z return
    rts
    // [2394] phi from display_frame_char to display_frame_char::@return [phi:display_frame_char->display_frame_char::@return]
  __b1:
    // [2394] phi display_frame_char::return#12 = $70 [phi:display_frame_char->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$70
    sta.z return
    rts
    // [2394] phi from display_frame_char::@1 to display_frame_char::@return [phi:display_frame_char::@1->display_frame_char::@return]
  __b2:
    // [2394] phi display_frame_char::return#12 = $6e [phi:display_frame_char::@1->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6e
    sta.z return
    rts
    // [2394] phi from display_frame_char::@2 to display_frame_char::@return [phi:display_frame_char::@2->display_frame_char::@return]
  __b3:
    // [2394] phi display_frame_char::return#12 = $6d [phi:display_frame_char::@2->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6d
    sta.z return
    rts
    // [2394] phi from display_frame_char::@3 to display_frame_char::@return [phi:display_frame_char::@3->display_frame_char::@return]
  __b4:
    // [2394] phi display_frame_char::return#12 = $7d [phi:display_frame_char::@3->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$7d
    sta.z return
    rts
    // [2394] phi from display_frame_char::@4 to display_frame_char::@return [phi:display_frame_char::@4->display_frame_char::@return]
  __b5:
    // [2394] phi display_frame_char::return#12 = $40 [phi:display_frame_char::@4->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z return
    rts
    // [2394] phi from display_frame_char::@5 to display_frame_char::@return [phi:display_frame_char::@5->display_frame_char::@return]
  __b6:
    // [2394] phi display_frame_char::return#12 = $5d [phi:display_frame_char::@5->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z return
    rts
    // [2394] phi from display_frame_char::@6 to display_frame_char::@return [phi:display_frame_char::@6->display_frame_char::@return]
  __b7:
    // [2394] phi display_frame_char::return#12 = $6b [phi:display_frame_char::@6->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z return
    rts
    // [2394] phi from display_frame_char::@7 to display_frame_char::@return [phi:display_frame_char::@7->display_frame_char::@return]
  __b8:
    // [2394] phi display_frame_char::return#12 = $73 [phi:display_frame_char::@7->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z return
    rts
    // [2394] phi from display_frame_char::@8 to display_frame_char::@return [phi:display_frame_char::@8->display_frame_char::@return]
  __b9:
    // [2394] phi display_frame_char::return#12 = $72 [phi:display_frame_char::@8->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z return
    rts
    // [2394] phi from display_frame_char::@9 to display_frame_char::@return [phi:display_frame_char::@9->display_frame_char::@return]
  __b10:
    // [2394] phi display_frame_char::return#12 = $71 [phi:display_frame_char::@9->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z return
    // display_frame_char::@return
    // }
    // [2395] return 
    rts
  .segment Data
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
// void display_chip_led(__zp($67) char x, char y, __zp($43) char w, __zp($6b) char tc, char bc)
display_chip_led: {
    .label x = $67
    .label w = $43
    .label tc = $6b
    // textcolor(tc)
    // [2397] textcolor::color#11 = display_chip_led::tc#3 -- vbuz1=vbuz2 
    lda.z tc
    sta.z textcolor.color
    // [2398] call textcolor
    // [592] phi from display_chip_led to textcolor [phi:display_chip_led->textcolor]
    // [592] phi textcolor::color#18 = textcolor::color#11 [phi:display_chip_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [2399] phi from display_chip_led to display_chip_led::@3 [phi:display_chip_led->display_chip_led::@3]
    // display_chip_led::@3
    // bgcolor(bc)
    // [2400] call bgcolor
    // [597] phi from display_chip_led::@3 to bgcolor [phi:display_chip_led::@3->bgcolor]
    // [597] phi bgcolor::color#14 = BLUE [phi:display_chip_led::@3->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [2401] phi from display_chip_led::@3 display_chip_led::@5 to display_chip_led::@1 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1]
    // [2401] phi display_chip_led::w#4 = display_chip_led::w#7 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1#0] -- register_copy 
    // [2401] phi display_chip_led::x#4 = display_chip_led::x#7 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1#1] -- register_copy 
    // display_chip_led::@1
  __b1:
    // cputcxy(x, y, 0x6F)
    // [2402] cputcxy::x#9 = display_chip_led::x#4 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [2403] call cputcxy
    // [1840] phi from display_chip_led::@1 to cputcxy [phi:display_chip_led::@1->cputcxy]
    // [1840] phi cputcxy::c#15 = $6f [phi:display_chip_led::@1->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6f
    sta.z cputcxy.c
    // [1840] phi cputcxy::y#15 = 3 [phi:display_chip_led::@1->cputcxy#1] -- vbuz1=vbuc1 
    lda #3
    sta.z cputcxy.y
    // [1840] phi cputcxy::x#15 = cputcxy::x#9 [phi:display_chip_led::@1->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_led::@4
    // cputcxy(x, y+1, 0x77)
    // [2404] cputcxy::x#10 = display_chip_led::x#4 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [2405] call cputcxy
    // [1840] phi from display_chip_led::@4 to cputcxy [phi:display_chip_led::@4->cputcxy]
    // [1840] phi cputcxy::c#15 = $77 [phi:display_chip_led::@4->cputcxy#0] -- vbuz1=vbuc1 
    lda #$77
    sta.z cputcxy.c
    // [1840] phi cputcxy::y#15 = 3+1 [phi:display_chip_led::@4->cputcxy#1] -- vbuz1=vbuc1 
    lda #3+1
    sta.z cputcxy.y
    // [1840] phi cputcxy::x#15 = cputcxy::x#10 [phi:display_chip_led::@4->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_led::@5
    // x++;
    // [2406] display_chip_led::x#0 = ++ display_chip_led::x#4 -- vbuz1=_inc_vbuz1 
    inc.z x
    // while(--w)
    // [2407] display_chip_led::w#0 = -- display_chip_led::w#4 -- vbuz1=_dec_vbuz1 
    dec.z w
    // [2408] if(0!=display_chip_led::w#0) goto display_chip_led::@1 -- 0_neq_vbuz1_then_la1 
    lda.z w
    bne __b1
    // [2409] phi from display_chip_led::@5 to display_chip_led::@2 [phi:display_chip_led::@5->display_chip_led::@2]
    // display_chip_led::@2
    // textcolor(WHITE)
    // [2410] call textcolor
    // [592] phi from display_chip_led::@2 to textcolor [phi:display_chip_led::@2->textcolor]
    // [592] phi textcolor::color#18 = WHITE [phi:display_chip_led::@2->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [2411] phi from display_chip_led::@2 to display_chip_led::@6 [phi:display_chip_led::@2->display_chip_led::@6]
    // display_chip_led::@6
    // bgcolor(BLUE)
    // [2412] call bgcolor
    // [597] phi from display_chip_led::@6 to bgcolor [phi:display_chip_led::@6->bgcolor]
    // [597] phi bgcolor::color#14 = BLUE [phi:display_chip_led::@6->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // display_chip_led::@return
    // }
    // [2413] return 
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
// void display_chip_line(__zp($6b) char x, __zp($68) char y, __zp($35) char w, __zp($5d) char c)
display_chip_line: {
    .label i = $36
    .label x = $6b
    .label w = $35
    .label c = $5d
    .label y = $68
    // gotoxy(x, y)
    // [2415] gotoxy::x#7 = display_chip_line::x#16 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [2416] gotoxy::y#7 = display_chip_line::y#16 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [2417] call gotoxy
    // [610] phi from display_chip_line to gotoxy [phi:display_chip_line->gotoxy]
    // [610] phi gotoxy::y#30 = gotoxy::y#7 [phi:display_chip_line->gotoxy#0] -- register_copy 
    // [610] phi gotoxy::x#30 = gotoxy::x#7 [phi:display_chip_line->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [2418] phi from display_chip_line to display_chip_line::@4 [phi:display_chip_line->display_chip_line::@4]
    // display_chip_line::@4
    // textcolor(GREY)
    // [2419] call textcolor
    // [592] phi from display_chip_line::@4 to textcolor [phi:display_chip_line::@4->textcolor]
    // [592] phi textcolor::color#18 = GREY [phi:display_chip_line::@4->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [2420] phi from display_chip_line::@4 to display_chip_line::@5 [phi:display_chip_line::@4->display_chip_line::@5]
    // display_chip_line::@5
    // bgcolor(BLUE)
    // [2421] call bgcolor
    // [597] phi from display_chip_line::@5 to bgcolor [phi:display_chip_line::@5->bgcolor]
    // [597] phi bgcolor::color#14 = BLUE [phi:display_chip_line::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // display_chip_line::@6
    // cputc(VERA_CHR_UR)
    // [2422] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [2423] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [2425] call textcolor
    // [592] phi from display_chip_line::@6 to textcolor [phi:display_chip_line::@6->textcolor]
    // [592] phi textcolor::color#18 = WHITE [phi:display_chip_line::@6->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [2426] phi from display_chip_line::@6 to display_chip_line::@7 [phi:display_chip_line::@6->display_chip_line::@7]
    // display_chip_line::@7
    // bgcolor(BLACK)
    // [2427] call bgcolor
    // [597] phi from display_chip_line::@7 to bgcolor [phi:display_chip_line::@7->bgcolor]
    // [597] phi bgcolor::color#14 = BLACK [phi:display_chip_line::@7->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // [2428] phi from display_chip_line::@7 to display_chip_line::@1 [phi:display_chip_line::@7->display_chip_line::@1]
    // [2428] phi display_chip_line::i#2 = 0 [phi:display_chip_line::@7->display_chip_line::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // display_chip_line::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [2429] if(display_chip_line::i#2<display_chip_line::w#10) goto display_chip_line::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [2430] phi from display_chip_line::@1 to display_chip_line::@3 [phi:display_chip_line::@1->display_chip_line::@3]
    // display_chip_line::@3
    // textcolor(GREY)
    // [2431] call textcolor
    // [592] phi from display_chip_line::@3 to textcolor [phi:display_chip_line::@3->textcolor]
    // [592] phi textcolor::color#18 = GREY [phi:display_chip_line::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [2432] phi from display_chip_line::@3 to display_chip_line::@8 [phi:display_chip_line::@3->display_chip_line::@8]
    // display_chip_line::@8
    // bgcolor(BLUE)
    // [2433] call bgcolor
    // [597] phi from display_chip_line::@8 to bgcolor [phi:display_chip_line::@8->bgcolor]
    // [597] phi bgcolor::color#14 = BLUE [phi:display_chip_line::@8->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // display_chip_line::@9
    // cputc(VERA_CHR_UL)
    // [2434] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [2435] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [2437] call textcolor
    // [592] phi from display_chip_line::@9 to textcolor [phi:display_chip_line::@9->textcolor]
    // [592] phi textcolor::color#18 = WHITE [phi:display_chip_line::@9->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [2438] phi from display_chip_line::@9 to display_chip_line::@10 [phi:display_chip_line::@9->display_chip_line::@10]
    // display_chip_line::@10
    // bgcolor(BLACK)
    // [2439] call bgcolor
    // [597] phi from display_chip_line::@10 to bgcolor [phi:display_chip_line::@10->bgcolor]
    // [597] phi bgcolor::color#14 = BLACK [phi:display_chip_line::@10->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // display_chip_line::@11
    // cputcxy(x+2, y, c)
    // [2440] cputcxy::x#8 = display_chip_line::x#16 + 2 -- vbuz1=vbuz2_plus_2 
    lda.z x
    clc
    adc #2
    sta.z cputcxy.x
    // [2441] cputcxy::y#8 = display_chip_line::y#16 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [2442] cputcxy::c#8 = display_chip_line::c#15 -- vbuz1=vbuz2 
    lda.z c
    sta.z cputcxy.c
    // [2443] call cputcxy
    // [1840] phi from display_chip_line::@11 to cputcxy [phi:display_chip_line::@11->cputcxy]
    // [1840] phi cputcxy::c#15 = cputcxy::c#8 [phi:display_chip_line::@11->cputcxy#0] -- register_copy 
    // [1840] phi cputcxy::y#15 = cputcxy::y#8 [phi:display_chip_line::@11->cputcxy#1] -- register_copy 
    // [1840] phi cputcxy::x#15 = cputcxy::x#8 [phi:display_chip_line::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_line::@return
    // }
    // [2444] return 
    rts
    // display_chip_line::@2
  __b2:
    // cputc(VERA_CHR_SPACE)
    // [2445] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [2446] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [2448] display_chip_line::i#1 = ++ display_chip_line::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [2428] phi from display_chip_line::@2 to display_chip_line::@1 [phi:display_chip_line::@2->display_chip_line::@1]
    // [2428] phi display_chip_line::i#2 = display_chip_line::i#1 [phi:display_chip_line::@2->display_chip_line::@1#0] -- register_copy 
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
// void display_chip_end(__zp($be) char x, char y, __zp($dd) char w)
display_chip_end: {
    .label i = $f2
    .label x = $be
    .label w = $dd
    // gotoxy(x, y)
    // [2449] gotoxy::x#8 = display_chip_end::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [2450] call gotoxy
    // [610] phi from display_chip_end to gotoxy [phi:display_chip_end->gotoxy]
    // [610] phi gotoxy::y#30 = display_print_chip::y#21 [phi:display_chip_end->gotoxy#0] -- vbuz1=vbuc1 
    lda #display_print_chip.y
    sta.z gotoxy.y
    // [610] phi gotoxy::x#30 = gotoxy::x#8 [phi:display_chip_end->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [2451] phi from display_chip_end to display_chip_end::@4 [phi:display_chip_end->display_chip_end::@4]
    // display_chip_end::@4
    // textcolor(GREY)
    // [2452] call textcolor
    // [592] phi from display_chip_end::@4 to textcolor [phi:display_chip_end::@4->textcolor]
    // [592] phi textcolor::color#18 = GREY [phi:display_chip_end::@4->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [2453] phi from display_chip_end::@4 to display_chip_end::@5 [phi:display_chip_end::@4->display_chip_end::@5]
    // display_chip_end::@5
    // bgcolor(BLUE)
    // [2454] call bgcolor
    // [597] phi from display_chip_end::@5 to bgcolor [phi:display_chip_end::@5->bgcolor]
    // [597] phi bgcolor::color#14 = BLUE [phi:display_chip_end::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // display_chip_end::@6
    // cputc(VERA_CHR_UR)
    // [2455] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [2456] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [2458] call textcolor
    // [592] phi from display_chip_end::@6 to textcolor [phi:display_chip_end::@6->textcolor]
    // [592] phi textcolor::color#18 = BLUE [phi:display_chip_end::@6->textcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z textcolor.color
    jsr textcolor
    // [2459] phi from display_chip_end::@6 to display_chip_end::@7 [phi:display_chip_end::@6->display_chip_end::@7]
    // display_chip_end::@7
    // bgcolor(BLACK)
    // [2460] call bgcolor
    // [597] phi from display_chip_end::@7 to bgcolor [phi:display_chip_end::@7->bgcolor]
    // [597] phi bgcolor::color#14 = BLACK [phi:display_chip_end::@7->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // [2461] phi from display_chip_end::@7 to display_chip_end::@1 [phi:display_chip_end::@7->display_chip_end::@1]
    // [2461] phi display_chip_end::i#2 = 0 [phi:display_chip_end::@7->display_chip_end::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // display_chip_end::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [2462] if(display_chip_end::i#2<display_chip_end::w#0) goto display_chip_end::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [2463] phi from display_chip_end::@1 to display_chip_end::@3 [phi:display_chip_end::@1->display_chip_end::@3]
    // display_chip_end::@3
    // textcolor(GREY)
    // [2464] call textcolor
    // [592] phi from display_chip_end::@3 to textcolor [phi:display_chip_end::@3->textcolor]
    // [592] phi textcolor::color#18 = GREY [phi:display_chip_end::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [2465] phi from display_chip_end::@3 to display_chip_end::@8 [phi:display_chip_end::@3->display_chip_end::@8]
    // display_chip_end::@8
    // bgcolor(BLUE)
    // [2466] call bgcolor
    // [597] phi from display_chip_end::@8 to bgcolor [phi:display_chip_end::@8->bgcolor]
    // [597] phi bgcolor::color#14 = BLUE [phi:display_chip_end::@8->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // display_chip_end::@9
    // cputc(VERA_CHR_UL)
    // [2467] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [2468] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_chip_end::@return
    // }
    // [2470] return 
    rts
    // display_chip_end::@2
  __b2:
    // cputc(VERA_CHR_HL)
    // [2471] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [2472] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [2474] display_chip_end::i#1 = ++ display_chip_end::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [2461] phi from display_chip_end::@2 to display_chip_end::@1 [phi:display_chip_end::@2->display_chip_end::@1]
    // [2461] phi display_chip_end::i#2 = display_chip_end::i#1 [phi:display_chip_end::@2->display_chip_end::@1#0] -- register_copy 
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
// __zp($2e) unsigned int utoa_append(__zp($75) char *buffer, __zp($2e) unsigned int value, __zp($44) unsigned int sub)
utoa_append: {
    .label buffer = $75
    .label value = $2e
    .label sub = $44
    .label return = $2e
    .label digit = $37
    // [2476] phi from utoa_append to utoa_append::@1 [phi:utoa_append->utoa_append::@1]
    // [2476] phi utoa_append::digit#2 = 0 [phi:utoa_append->utoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [2476] phi utoa_append::value#2 = utoa_append::value#0 [phi:utoa_append->utoa_append::@1#1] -- register_copy 
    // utoa_append::@1
  __b1:
    // while (value >= sub)
    // [2477] if(utoa_append::value#2>=utoa_append::sub#0) goto utoa_append::@2 -- vwuz1_ge_vwuz2_then_la1 
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
    // [2478] *utoa_append::buffer#0 = DIGITS[utoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // utoa_append::@return
    // }
    // [2479] return 
    rts
    // utoa_append::@2
  __b2:
    // digit++;
    // [2480] utoa_append::digit#1 = ++ utoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [2481] utoa_append::value#1 = utoa_append::value#2 - utoa_append::sub#0 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z value
    sec
    sbc.z sub
    sta.z value
    lda.z value+1
    sbc.z sub+1
    sta.z value+1
    // [2476] phi from utoa_append::@2 to utoa_append::@1 [phi:utoa_append::@2->utoa_append::@1]
    // [2476] phi utoa_append::digit#2 = utoa_append::digit#1 [phi:utoa_append::@2->utoa_append::@1#0] -- register_copy 
    // [2476] phi utoa_append::value#2 = utoa_append::value#1 [phi:utoa_append::@2->utoa_append::@1#1] -- register_copy 
    jmp __b1
}
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
// void rom_write_byte(__zp($57) unsigned long address, __zp($5c) char value)
rom_write_byte: {
    .label rom_bank1_rom_write_byte__0 = $5b
    .label rom_bank1_rom_write_byte__1 = $54
    .label rom_bank1_rom_write_byte__2 = $4f
    .label rom_ptr1_rom_write_byte__0 = $4d
    .label rom_ptr1_rom_write_byte__2 = $4d
    .label rom_bank1_bank_unshifted = $4f
    .label rom_bank1_return = $5d
    .label rom_ptr1_return = $4d
    .label address = $57
    .label value = $5c
    // rom_write_byte::rom_bank1
    // BYTE2(address)
    // [2483] rom_write_byte::rom_bank1_$0 = byte2  rom_write_byte::address#4 -- vbuz1=_byte2_vduz2 
    lda.z address+2
    sta.z rom_bank1_rom_write_byte__0
    // BYTE1(address)
    // [2484] rom_write_byte::rom_bank1_$1 = byte1  rom_write_byte::address#4 -- vbuz1=_byte1_vduz2 
    lda.z address+1
    sta.z rom_bank1_rom_write_byte__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2485] rom_write_byte::rom_bank1_$2 = rom_write_byte::rom_bank1_$0 w= rom_write_byte::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_write_byte__0
    sta.z rom_bank1_rom_write_byte__2+1
    lda.z rom_bank1_rom_write_byte__1
    sta.z rom_bank1_rom_write_byte__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2486] rom_write_byte::rom_bank1_bank_unshifted#0 = rom_write_byte::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2487] rom_write_byte::rom_bank1_return#0 = byte1  rom_write_byte::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwuz2 
    lda.z rom_bank1_bank_unshifted+1
    sta.z rom_bank1_return
    // rom_write_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2488] rom_write_byte::rom_ptr1_$2 = (unsigned int)rom_write_byte::address#4 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_write_byte__2
    lda.z address+1
    sta.z rom_ptr1_rom_write_byte__2+1
    // [2489] rom_write_byte::rom_ptr1_$0 = rom_write_byte::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_write_byte__0
    and #<$3fff
    sta.z rom_ptr1_rom_write_byte__0
    lda.z rom_ptr1_rom_write_byte__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_write_byte__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2490] rom_write_byte::rom_ptr1_return#0 = rom_write_byte::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_write_byte::bank_set_brom1
    // BROM = bank
    // [2491] BROM = rom_write_byte::rom_bank1_return#0 -- vbuz1=vbuz2 
    lda.z rom_bank1_return
    sta.z BROM
    // rom_write_byte::@1
    // *ptr_rom = value
    // [2492] *((char *)rom_write_byte::rom_ptr1_return#0) = rom_write_byte::value#10 -- _deref_pbuz1=vbuz2 
    lda.z value
    ldy #0
    sta (rom_ptr1_return),y
    // rom_write_byte::@return
    // }
    // [2493] return 
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
    // [2495] return 
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
// __zp($73) int ferror(__zp($62) struct $2 *stream)
ferror: {
    .label ferror__6 = $2c
    .label ferror__15 = $ed
    .label cbm_k_setnam1_ferror__0 = $55
    .label cbm_k_readst1_status = $fb
    .label stream = $62
    .label return = $73
    .label sp = $38
    .label cbm_k_chrin1_return = $ed
    .label ch = $ed
    .label cbm_k_readst1_return = $2c
    .label st = $2c
    .label errno_len = $67
    .label cbm_k_chrin2_return = $ed
    .label errno_parsed = $ee
    // unsigned char sp = (unsigned char)stream
    // [2496] ferror::sp#0 = (char)ferror::stream#0 -- vbuz1=_byte_pssz2 
    lda.z stream
    sta.z sp
    // cbm_k_setlfs(15, 8, 15)
    // [2497] cbm_k_setlfs::channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.channel
    // [2498] cbm_k_setlfs::device = 8 -- vbum1=vbuc1 
    lda #8
    sta cbm_k_setlfs.device
    // [2499] cbm_k_setlfs::command = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.command
    // [2500] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // ferror::@11
    // cbm_k_setnam("")
    // [2501] ferror::cbm_k_setnam1_filename = info_text4 -- pbum1=pbuc1 
    lda #<info_text4
    sta cbm_k_setnam1_filename
    lda #>info_text4
    sta cbm_k_setnam1_filename+1
    // ferror::cbm_k_setnam1
    // strlen(filename)
    // [2502] strlen::str#5 = ferror::cbm_k_setnam1_filename -- pbuz1=pbum2 
    lda cbm_k_setnam1_filename
    sta.z strlen.str
    lda cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [2503] call strlen
    // [1944] phi from ferror::cbm_k_setnam1 to strlen [phi:ferror::cbm_k_setnam1->strlen]
    // [1944] phi strlen::str#8 = strlen::str#5 [phi:ferror::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [2504] strlen::return#12 = strlen::len#2
    // ferror::@12
    // [2505] ferror::cbm_k_setnam1_$0 = strlen::return#12
    // char filename_len = (char)strlen(filename)
    // [2506] ferror::cbm_k_setnam1_filename_len = (char)ferror::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
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
    // [2509] ferror::cbm_k_chkin1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_chkin1_channel
    // ferror::cbm_k_chkin1
    // char status
    // [2510] ferror::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // ferror::cbm_k_chrin1
    // char ch
    // [2512] ferror::cbm_k_chrin1_ch = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chrin1_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin1_ch
    // return ch;
    // [2514] ferror::cbm_k_chrin1_return#0 = ferror::cbm_k_chrin1_ch -- vbuz1=vbum2 
    sta.z cbm_k_chrin1_return
    // ferror::cbm_k_chrin1_@return
    // }
    // [2515] ferror::cbm_k_chrin1_return#1 = ferror::cbm_k_chrin1_return#0
    // ferror::@7
    // char ch = cbm_k_chrin()
    // [2516] ferror::ch#0 = ferror::cbm_k_chrin1_return#1
    // [2517] phi from ferror::@7 to ferror::cbm_k_readst1 [phi:ferror::@7->ferror::cbm_k_readst1]
    // [2517] phi __errno#18 = __errno#325 [phi:ferror::@7->ferror::cbm_k_readst1#0] -- register_copy 
    // [2517] phi ferror::errno_len#10 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z errno_len
    // [2517] phi ferror::ch#10 = ferror::ch#0 [phi:ferror::@7->ferror::cbm_k_readst1#2] -- register_copy 
    // [2517] phi ferror::errno_parsed#2 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#3] -- vbuz1=vbuc1 
    sta.z errno_parsed
    // ferror::cbm_k_readst1
  cbm_k_readst1:
    // char status
    // [2518] ferror::cbm_k_readst1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2520] ferror::cbm_k_readst1_return#0 = ferror::cbm_k_readst1_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst1_return
    // ferror::cbm_k_readst1_@return
    // }
    // [2521] ferror::cbm_k_readst1_return#1 = ferror::cbm_k_readst1_return#0
    // ferror::@8
    // cbm_k_readst()
    // [2522] ferror::$6 = ferror::cbm_k_readst1_return#1
    // st = cbm_k_readst()
    // [2523] ferror::st#1 = ferror::$6
    // while (!(st = cbm_k_readst()))
    // [2524] if(0==ferror::st#1) goto ferror::@1 -- 0_eq_vbuz1_then_la1 
    lda.z st
    beq __b1
    // ferror::@2
    // __status = st
    // [2525] ((char *)&__stdio_file+$46)[ferror::sp#0] = ferror::st#1 -- pbuc1_derefidx_vbuz1=vbuz2 
    ldy.z sp
    sta __stdio_file+$46,y
    // cbm_k_close(15)
    // [2526] ferror::cbm_k_close1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_close1_channel
    // ferror::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // ferror::@9
    // return __errno;
    // [2528] ferror::return#1 = __errno#18 -- vwsz1=vwsz2 
    lda.z __errno
    sta.z return
    lda.z __errno+1
    sta.z return+1
    // ferror::@return
    // }
    // [2529] return 
    rts
    // ferror::@1
  __b1:
    // if (!errno_parsed)
    // [2530] if(0!=ferror::errno_parsed#2) goto ferror::@3 -- 0_neq_vbuz1_then_la1 
    lda.z errno_parsed
    bne __b3
    // ferror::@4
    // if (ch == ',')
    // [2531] if(ferror::ch#10!=',') goto ferror::@3 -- vbuz1_neq_vbuc1_then_la1 
    lda #','
    cmp.z ch
    bne __b3
    // ferror::@5
    // errno_parsed++;
    // [2532] ferror::errno_parsed#1 = ++ ferror::errno_parsed#2 -- vbuz1=_inc_vbuz1 
    inc.z errno_parsed
    // strncpy(temp, __errno_error, errno_len+1)
    // [2533] strncpy::n#0 = ferror::errno_len#10 + 1 -- vwuz1=vbuz2_plus_1 
    lda.z errno_len
    clc
    adc #1
    sta.z strncpy.n
    lda #0
    adc #0
    sta.z strncpy.n+1
    // [2534] call strncpy
    // [1600] phi from ferror::@5 to strncpy [phi:ferror::@5->strncpy]
    // [1600] phi strncpy::dst#8 = ferror::temp [phi:ferror::@5->strncpy#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z strncpy.dst
    lda #>temp
    sta.z strncpy.dst+1
    // [1600] phi strncpy::src#6 = __errno_error [phi:ferror::@5->strncpy#1] -- pbuz1=pbuc1 
    lda #<__errno_error
    sta.z strncpy.src
    lda #>__errno_error
    sta.z strncpy.src+1
    // [1600] phi strncpy::n#3 = strncpy::n#0 [phi:ferror::@5->strncpy#2] -- register_copy 
    jsr strncpy
    // [2535] phi from ferror::@5 to ferror::@13 [phi:ferror::@5->ferror::@13]
    // ferror::@13
    // atoi(temp)
    // [2536] call atoi
    // [2548] phi from ferror::@13 to atoi [phi:ferror::@13->atoi]
    // [2548] phi atoi::str#2 = ferror::temp [phi:ferror::@13->atoi#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z atoi.str
    lda #>temp
    sta.z atoi.str+1
    jsr atoi
    // atoi(temp)
    // [2537] atoi::return#4 = atoi::return#2
    // ferror::@14
    // __errno = atoi(temp)
    // [2538] __errno#2 = atoi::return#4 -- vwsz1=vwsz2 
    lda.z atoi.return
    sta.z __errno
    lda.z atoi.return+1
    sta.z __errno+1
    // [2539] phi from ferror::@1 ferror::@14 ferror::@4 to ferror::@3 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3]
    // [2539] phi __errno#103 = __errno#18 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#0] -- register_copy 
    // [2539] phi ferror::errno_parsed#11 = ferror::errno_parsed#2 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#1] -- register_copy 
    // ferror::@3
  __b3:
    // __errno_error[errno_len] = ch
    // [2540] __errno_error[ferror::errno_len#10] = ferror::ch#10 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z ch
    ldy.z errno_len
    sta __errno_error,y
    // errno_len++;
    // [2541] ferror::errno_len#1 = ++ ferror::errno_len#10 -- vbuz1=_inc_vbuz1 
    inc.z errno_len
    // ferror::cbm_k_chrin2
    // char ch
    // [2542] ferror::cbm_k_chrin2_ch = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chrin2_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin2_ch
    // return ch;
    // [2544] ferror::cbm_k_chrin2_return#0 = ferror::cbm_k_chrin2_ch -- vbuz1=vbum2 
    sta.z cbm_k_chrin2_return
    // ferror::cbm_k_chrin2_@return
    // }
    // [2545] ferror::cbm_k_chrin2_return#1 = ferror::cbm_k_chrin2_return#0
    // ferror::@10
    // cbm_k_chrin()
    // [2546] ferror::$15 = ferror::cbm_k_chrin2_return#1
    // ch = cbm_k_chrin()
    // [2547] ferror::ch#1 = ferror::$15
    // [2517] phi from ferror::@10 to ferror::cbm_k_readst1 [phi:ferror::@10->ferror::cbm_k_readst1]
    // [2517] phi __errno#18 = __errno#103 [phi:ferror::@10->ferror::cbm_k_readst1#0] -- register_copy 
    // [2517] phi ferror::errno_len#10 = ferror::errno_len#1 [phi:ferror::@10->ferror::cbm_k_readst1#1] -- register_copy 
    // [2517] phi ferror::ch#10 = ferror::ch#1 [phi:ferror::@10->ferror::cbm_k_readst1#2] -- register_copy 
    // [2517] phi ferror::errno_parsed#2 = ferror::errno_parsed#11 [phi:ferror::@10->ferror::cbm_k_readst1#3] -- register_copy 
    jmp cbm_k_readst1
  .segment Data
    temp: .fill 4, 0
    cbm_k_setnam1_filename: .word 0
    cbm_k_setnam1_filename_len: .byte 0
    cbm_k_chkin1_channel: .byte 0
    cbm_k_chkin1_status: .byte 0
    cbm_k_chrin1_ch: .byte 0
    cbm_k_close1_channel: .byte 0
    cbm_k_chrin2_ch: .byte 0
}
.segment Code
  // atoi
// Converts the string argument str to an integer.
// __zp($51) int atoi(__zp($d7) const char *str)
atoi: {
    .label atoi__6 = $51
    .label atoi__7 = $51
    .label res = $51
    // Initialize sign as positive
    .label i = $43
    .label return = $51
    .label str = $d7
    // Initialize result
    .label negative = $68
    .label atoi__10 = $4f
    .label atoi__11 = $51
    // if (str[i] == '-')
    // [2549] if(*atoi::str#2!='-') goto atoi::@3 -- _deref_pbuz1_neq_vbuc1_then_la1 
    ldy #0
    lda (str),y
    cmp #'-'
    bne __b2
    // [2550] phi from atoi to atoi::@2 [phi:atoi->atoi::@2]
    // atoi::@2
    // [2551] phi from atoi::@2 to atoi::@3 [phi:atoi::@2->atoi::@3]
    // [2551] phi atoi::negative#2 = 1 [phi:atoi::@2->atoi::@3#0] -- vbuz1=vbuc1 
    lda #1
    sta.z negative
    // [2551] phi atoi::res#2 = 0 [phi:atoi::@2->atoi::@3#1] -- vwsz1=vwsc1 
    tya
    sta.z res
    sta.z res+1
    // [2551] phi atoi::i#4 = 1 [phi:atoi::@2->atoi::@3#2] -- vbuz1=vbuc1 
    lda #1
    sta.z i
    jmp __b3
  // Iterate through all digits and update the result
    // [2551] phi from atoi to atoi::@3 [phi:atoi->atoi::@3]
  __b2:
    // [2551] phi atoi::negative#2 = 0 [phi:atoi->atoi::@3#0] -- vbuz1=vbuc1 
    lda #0
    sta.z negative
    // [2551] phi atoi::res#2 = 0 [phi:atoi->atoi::@3#1] -- vwsz1=vwsc1 
    sta.z res
    sta.z res+1
    // [2551] phi atoi::i#4 = 0 [phi:atoi->atoi::@3#2] -- vbuz1=vbuc1 
    sta.z i
    // atoi::@3
  __b3:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [2552] if(atoi::str#2[atoi::i#4]<'0') goto atoi::@5 -- pbuz1_derefidx_vbuz2_lt_vbuc1_then_la1 
    ldy.z i
    lda (str),y
    cmp #'0'
    bcc __b5
    // atoi::@6
    // [2553] if(atoi::str#2[atoi::i#4]<='9') goto atoi::@4 -- pbuz1_derefidx_vbuz2_le_vbuc1_then_la1 
    lda (str),y
    cmp #'9'
    bcc __b4
    beq __b4
    // atoi::@5
  __b5:
    // if(negative)
    // [2554] if(0!=atoi::negative#2) goto atoi::@1 -- 0_neq_vbuz1_then_la1 
    // Return result with sign
    lda.z negative
    bne __b1
    // [2556] phi from atoi::@1 atoi::@5 to atoi::@return [phi:atoi::@1/atoi::@5->atoi::@return]
    // [2556] phi atoi::return#2 = atoi::return#0 [phi:atoi::@1/atoi::@5->atoi::@return#0] -- register_copy 
    rts
    // atoi::@1
  __b1:
    // return -res;
    // [2555] atoi::return#0 = - atoi::res#2 -- vwsz1=_neg_vwsz1 
    lda #0
    sec
    sbc.z return
    sta.z return
    lda #0
    sbc.z return+1
    sta.z return+1
    // atoi::@return
    // }
    // [2557] return 
    rts
    // atoi::@4
  __b4:
    // res * 10
    // [2558] atoi::$10 = atoi::res#2 << 2 -- vwsz1=vwsz2_rol_2 
    lda.z res
    asl
    sta.z atoi__10
    lda.z res+1
    rol
    sta.z atoi__10+1
    asl.z atoi__10
    rol.z atoi__10+1
    // [2559] atoi::$11 = atoi::$10 + atoi::res#2 -- vwsz1=vwsz2_plus_vwsz1 
    clc
    lda.z atoi__11
    adc.z atoi__10
    sta.z atoi__11
    lda.z atoi__11+1
    adc.z atoi__10+1
    sta.z atoi__11+1
    // [2560] atoi::$6 = atoi::$11 << 1 -- vwsz1=vwsz1_rol_1 
    asl.z atoi__6
    rol.z atoi__6+1
    // res * 10 + str[i]
    // [2561] atoi::$7 = atoi::$6 + atoi::str#2[atoi::i#4] -- vwsz1=vwsz1_plus_pbuz2_derefidx_vbuz3 
    ldy.z i
    lda.z atoi__7
    clc
    adc (str),y
    sta.z atoi__7
    bcc !+
    inc.z atoi__7+1
  !:
    // res = res * 10 + str[i] - '0'
    // [2562] atoi::res#1 = atoi::$7 - '0' -- vwsz1=vwsz1_minus_vbuc1 
    lda.z res
    sec
    sbc #'0'
    sta.z res
    bcs !+
    dec.z res+1
  !:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [2563] atoi::i#2 = ++ atoi::i#4 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [2551] phi from atoi::@4 to atoi::@3 [phi:atoi::@4->atoi::@3]
    // [2551] phi atoi::negative#2 = atoi::negative#2 [phi:atoi::@4->atoi::@3#0] -- register_copy 
    // [2551] phi atoi::res#2 = atoi::res#1 [phi:atoi::@4->atoi::@3#1] -- register_copy 
    // [2551] phi atoi::i#4 = atoi::i#2 [phi:atoi::@4->atoi::@3#2] -- register_copy 
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
// __zp($60) unsigned int cx16_k_macptr(__zp($cf) volatile char bytes, __zp($ca) void * volatile buffer)
cx16_k_macptr: {
    .label bytes = $cf
    .label buffer = $ca
    .label bytes_read = $ba
    .label return = $60
    // unsigned int bytes_read
    // [2564] cx16_k_macptr::bytes_read = 0 -- vwuz1=vwuc1 
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
    // [2566] cx16_k_macptr::return#0 = cx16_k_macptr::bytes_read -- vwuz1=vwuz2 
    lda.z bytes_read
    sta.z return
    lda.z bytes_read+1
    sta.z return+1
    // cx16_k_macptr::@return
    // }
    // [2567] cx16_k_macptr::return#1 = cx16_k_macptr::return#0
    // [2568] return 
    rts
}
  // uctoa_append
// Used to convert a single digit of an unsigned number value to a string representation
// Counts a single digit up from '0' as long as the value is larger than sub.
// Each time the digit is increased sub is subtracted from value.
// - buffer : pointer to the char that receives the digit
// - value : The value where the digit will be derived from
// - sub : the value of a '1' in the digit. Subtracted continually while the digit is increased.
//        (For decimal the subs used are 10000, 1000, 100, 10, 1)
// returns : the value reduced by sub * digit so that it is less than sub.
// __zp($2d) char uctoa_append(__zp($73) char *buffer, __zp($2d) char value, __zp($43) char sub)
uctoa_append: {
    .label buffer = $73
    .label value = $2d
    .label sub = $43
    .label return = $2d
    .label digit = $35
    // [2570] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [2570] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [2570] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [2571] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbuz1_ge_vbuz2_then_la1 
    lda.z value
    cmp.z sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [2572] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // uctoa_append::@return
    // }
    // [2573] return 
    rts
    // uctoa_append::@2
  __b2:
    // digit++;
    // [2574] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [2575] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbuz1=vbuz1_minus_vbuz2 
    lda.z value
    sec
    sbc.z sub
    sta.z value
    // [2570] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [2570] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [2570] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
    jmp __b1
}
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
// __zp($5d) char rom_byte_compare(__zp($78) char *ptr_rom, __zp($77) char value)
rom_byte_compare: {
    .label return = $5d
    .label ptr_rom = $78
    .label value = $77
    // if (*ptr_rom != value)
    // [2576] if(*rom_byte_compare::ptr_rom#0==rom_byte_compare::value#0) goto rom_byte_compare::@1 -- _deref_pbuz1_eq_vbuz2_then_la1 
    lda.z value
    ldy #0
    cmp (ptr_rom),y
    beq __b2
    // [2577] phi from rom_byte_compare to rom_byte_compare::@2 [phi:rom_byte_compare->rom_byte_compare::@2]
    // rom_byte_compare::@2
    // [2578] phi from rom_byte_compare::@2 to rom_byte_compare::@1 [phi:rom_byte_compare::@2->rom_byte_compare::@1]
    // [2578] phi rom_byte_compare::return#0 = 0 [phi:rom_byte_compare::@2->rom_byte_compare::@1#0] -- vbuz1=vbuc1 
    tya
    sta.z return
    rts
    // [2578] phi from rom_byte_compare to rom_byte_compare::@1 [phi:rom_byte_compare->rom_byte_compare::@1]
  __b2:
    // [2578] phi rom_byte_compare::return#0 = 1 [phi:rom_byte_compare->rom_byte_compare::@1#0] -- vbuz1=vbuc1 
    lda #1
    sta.z return
    // rom_byte_compare::@1
    // rom_byte_compare::@return
    // }
    // [2579] return 
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
// __zp($30) unsigned long ultoa_append(__zp($71) char *buffer, __zp($30) unsigned long value, __zp($3f) unsigned long sub)
ultoa_append: {
    .label buffer = $71
    .label value = $30
    .label sub = $3f
    .label return = $30
    .label digit = $36
    // [2581] phi from ultoa_append to ultoa_append::@1 [phi:ultoa_append->ultoa_append::@1]
    // [2581] phi ultoa_append::digit#2 = 0 [phi:ultoa_append->ultoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [2581] phi ultoa_append::value#2 = ultoa_append::value#0 [phi:ultoa_append->ultoa_append::@1#1] -- register_copy 
    // ultoa_append::@1
  __b1:
    // while (value >= sub)
    // [2582] if(ultoa_append::value#2>=ultoa_append::sub#0) goto ultoa_append::@2 -- vduz1_ge_vduz2_then_la1 
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
    // [2583] *ultoa_append::buffer#0 = DIGITS[ultoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // ultoa_append::@return
    // }
    // [2584] return 
    rts
    // ultoa_append::@2
  __b2:
    // digit++;
    // [2585] ultoa_append::digit#1 = ++ ultoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [2586] ultoa_append::value#1 = ultoa_append::value#2 - ultoa_append::sub#0 -- vduz1=vduz1_minus_vduz2 
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
    // [2581] phi from ultoa_append::@2 to ultoa_append::@1 [phi:ultoa_append::@2->ultoa_append::@1]
    // [2581] phi ultoa_append::digit#2 = ultoa_append::digit#1 [phi:ultoa_append::@2->ultoa_append::@1#0] -- register_copy 
    // [2581] phi ultoa_append::value#2 = ultoa_append::value#1 [phi:ultoa_append::@2->ultoa_append::@1#1] -- register_copy 
    jmp __b1
}
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
// void rom_wait(__zp($3d) char *ptr_rom)
rom_wait: {
    .label rom_wait__0 = $38
    .label rom_wait__1 = $2c
    .label test1 = $38
    .label test2 = $2c
    .label ptr_rom = $3d
    // rom_wait::@1
  __b1:
    // test1 = *((brom_ptr_t)ptr_rom)
    // [2588] rom_wait::test1#1 = *rom_wait::ptr_rom#3 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (ptr_rom),y
    sta.z test1
    // test2 = *((brom_ptr_t)ptr_rom)
    // [2589] rom_wait::test2#1 = *rom_wait::ptr_rom#3 -- vbuz1=_deref_pbuz2 
    lda (ptr_rom),y
    sta.z test2
    // test1 & 0x40
    // [2590] rom_wait::$0 = rom_wait::test1#1 & $40 -- vbuz1=vbuz1_band_vbuc1 
    lda #$40
    and.z rom_wait__0
    sta.z rom_wait__0
    // test2 & 0x40
    // [2591] rom_wait::$1 = rom_wait::test2#1 & $40 -- vbuz1=vbuz1_band_vbuc1 
    lda #$40
    and.z rom_wait__1
    sta.z rom_wait__1
    // while ((test1 & 0x40) != (test2 & 0x40))
    // [2592] if(rom_wait::$0!=rom_wait::$1) goto rom_wait::@1 -- vbuz1_neq_vbuz2_then_la1 
    lda.z rom_wait__0
    cmp.z rom_wait__1
    bne __b1
    // rom_wait::@return
    // }
    // [2593] return 
    rts
}
  // rom_byte_program
/**
 * @brief Write a byte and wait until the byte has been successfully flashed into the ROM.
 *
 * @param address The 22 bit ROM address.
 * @param value The byte value to be written.
 */
/* inline */
// void rom_byte_program(__zp($57) unsigned long address, __zp($5c) char value)
rom_byte_program: {
    .label rom_ptr1_rom_byte_program__0 = $5e
    .label rom_ptr1_rom_byte_program__2 = $5e
    .label rom_ptr1_return = $5e
    .label address = $57
    .label value = $5c
    // rom_byte_program::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2595] rom_byte_program::rom_ptr1_$2 = (unsigned int)rom_byte_program::address#0 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_byte_program__2
    lda.z address+1
    sta.z rom_ptr1_rom_byte_program__2+1
    // [2596] rom_byte_program::rom_ptr1_$0 = rom_byte_program::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_byte_program__0
    and #<$3fff
    sta.z rom_ptr1_rom_byte_program__0
    lda.z rom_ptr1_rom_byte_program__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_byte_program__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2597] rom_byte_program::rom_ptr1_return#0 = rom_byte_program::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_byte_program::@1
    // rom_write_byte(address, value)
    // [2598] rom_write_byte::address#3 = rom_byte_program::address#0
    // [2599] rom_write_byte::value#3 = rom_byte_program::value#0
    // [2600] call rom_write_byte
    // [2482] phi from rom_byte_program::@1 to rom_write_byte [phi:rom_byte_program::@1->rom_write_byte]
    // [2482] phi rom_write_byte::value#10 = rom_write_byte::value#3 [phi:rom_byte_program::@1->rom_write_byte#0] -- register_copy 
    // [2482] phi rom_write_byte::address#4 = rom_write_byte::address#3 [phi:rom_byte_program::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_byte_program::@2
    // rom_wait(ptr_rom)
    // [2601] rom_wait::ptr_rom#1 = (char *)rom_byte_program::rom_ptr1_return#0 -- pbuz1=pbuz2 
    lda.z rom_ptr1_return
    sta.z rom_wait.ptr_rom
    lda.z rom_ptr1_return+1
    sta.z rom_wait.ptr_rom+1
    // [2602] call rom_wait
    // [2587] phi from rom_byte_program::@2 to rom_wait [phi:rom_byte_program::@2->rom_wait]
    // [2587] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#1 [phi:rom_byte_program::@2->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_byte_program::@return
    // }
    // [2603] return 
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
// void memcpy8_vram_vram(__zp($25) char dbank_vram, __zp($39) unsigned int doffset_vram, __zp($24) char sbank_vram, __zp($2a) unsigned int soffset_vram, __zp($23) char num8)
memcpy8_vram_vram: {
    .label memcpy8_vram_vram__0 = $26
    .label memcpy8_vram_vram__1 = $27
    .label memcpy8_vram_vram__2 = $24
    .label memcpy8_vram_vram__3 = $28
    .label memcpy8_vram_vram__4 = $29
    .label memcpy8_vram_vram__5 = $25
    .label num8 = $23
    .label dbank_vram = $25
    .label doffset_vram = $39
    .label sbank_vram = $24
    .label soffset_vram = $2a
    .label num8_1 = $22
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2604] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [2605] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte0_vwuz2 
    lda.z soffset_vram
    sta.z memcpy8_vram_vram__0
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [2606] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [2607] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte1_vwuz2 
    lda.z soffset_vram+1
    sta.z memcpy8_vram_vram__1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [2608] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [2609] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbuz1=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z memcpy8_vram_vram__2
    sta.z memcpy8_vram_vram__2
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [2610] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [2611] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [2612] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte0_vwuz2 
    lda.z doffset_vram
    sta.z memcpy8_vram_vram__3
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [2613] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [2614] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte1_vwuz2 
    lda.z doffset_vram+1
    sta.z memcpy8_vram_vram__4
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [2615] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [2616] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbuz1=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z memcpy8_vram_vram__5
    sta.z memcpy8_vram_vram__5
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [2617] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // [2618] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [2618] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [2619] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbuz1=_dec_vbuz2 
    ldy.z num8_1
    dey
    sty.z num8
    // [2620] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbuz1_then_la1 
    lda.z num8_1
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [2621] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [2622] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [2623] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbuz1=vbuz2 
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
  display_into_briefing_text: .word __14, __15, info_text4, __17, __18, __19, __20, __21, __22, __23, __24, info_text4, __26, __27
  .fill 2*2, 0
  display_into_colors_text: .word __28, __29, info_text4, __31, __32, __33, __34, __35, __36, __37, __38, __39, __40, __41, info_text4, __43
  display_no_valid_smc_bootloader_text: .word __44, info_text4, __46, __47, info_text4, __49, __50, __51, __52
  display_debriefing_text_smc: .word __65, info_text4, __55, __56, __57, info_text4, __59, info_text4, __61, __62, __63, __64
  display_debriefing_text_rom: .word __65, info_text4, __67, __68
  smc_version_string: .fill $10, 0
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
  __44: .text "The SMC chip in your CX16 system does not contain a valid bootloader."
  .byte 0
  __46: .text "A valid bootloader is needed to update the SMC chip."
  .byte 0
  __47: .text "Unfortunately, your SMC chip cannot be updated using this tool!"
  .byte 0
  __49: .text "You will either need to install or downgrade the bootloader onto"
  .byte 0
  __50: .text "the SMC chip on your CX16 using an arduino device,"
  .byte 0
  __51: .text "or alternatively to order a new SMC chip from TexElec or"
  .byte 0
  __52: .text "a CX16 community friend containing a valid bootloader!"
  .byte 0
  __55: .text "Because your SMC chipset has been updated,"
  .byte 0
  __56: .text "the restart process differs, depending on the"
  .byte 0
  __57: .text "SMC boootloader version installed on your CX16 board:"
  .byte 0
  __59: .text "- SMC bootloader v2.0: your CX16 will automatically shut down."
  .byte 0
  __61: .text "- SMC bootloader v1.0: you need to "
  .byte 0
  __62: .text "  COMPLETELY DISCONNECT your CX16 from the power source!"
  .byte 0
  __63: .text "  The power-off button won't work!"
  .byte 0
  __64: .text "  Then, reconnect and start the CX16 normally."
  .byte 0
  __65: .text "Your CX16 system has been successfully updated!"
  .byte 0
  __67: .text "Since your CX16 system SMC and main ROM chipset"
  .byte 0
  __68: .text "have not been updated, your CX16 will just reset."
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
  /// Current position in the buffer being filled ( initially *s passed to snprintf()
  /// Used to hold state while printing
  __snprintf_buffer: .word 0
  __stdio_file: .fill SIZEOF_STRUCT___2, 0
  __stdio_filecount: .byte 0
  // Globals
  status_smc: .byte 0
  status_vera: .byte 0
  // Globals (to save zeropage and code overhead with parameter passing.)
  smc_bootloader: .word 0
  smc_file_size: .word 0
  smc_file_size_1: .word 0
  smc_file_size_2: .word 0
