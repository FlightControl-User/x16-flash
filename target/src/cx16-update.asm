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
  .const display_intro_briefing_count = $e
  .const display_intro_colors_count = $10
  .const display_no_valid_smc_bootloader_count = 9
  .const display_smc_rom_issue_count = 8
  .const display_smc_unsupported_rom_count = 7
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
  .label __errno = $f2
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
// void snputc(__zp($ed) char c)
snputc: {
    .const OFFSET_STACK_C = 0
    .label c = $ed
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
    .label conio_x16_init__5 = $e0
    // screenlayer1()
    // [20] call screenlayer1
    jsr screenlayer1
    // [21] phi from conio_x16_init to conio_x16_init::@1 [phi:conio_x16_init->conio_x16_init::@1]
    // conio_x16_init::@1
    // textcolor(CONIO_TEXTCOLOR_DEFAULT)
    // [22] call textcolor
    // [738] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [738] phi textcolor::color#18 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [23] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [24] call bgcolor
    // [743] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [743] phi bgcolor::color#14 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbuz1=vbuc1 
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
    // [756] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [756] phi gotoxy::y#30 = gotoxy::y#2 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [756] phi gotoxy::x#30 = gotoxy::x#2 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
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
    .const bank_set_brom2_bank = 4
    .const bank_set_brom3_bank = 0
    .const bank_set_brom4_bank = 0
    .const bank_set_brom5_bank = 0
    .const bank_set_brom6_bank = 4
    .const bank_push_set_bram1_bank = 1
    .const bank_set_bram2_bank = 0
    .const bank_set_brom7_bank = 0
    .label main__79 = $72
    .label main__104 = $68
    .label main__106 = $bf
    .label main__186 = $f0
    .label check_status_smc1_main__0 = $37
    .label check_status_cx16_rom1_check_status_rom1_main__0 = $e5
    .label check_status_smc3_main__0 = $2f
    .label check_status_cx16_rom2_check_status_rom1_main__0 = $e8
    .label check_status_vera1_main__0 = $c4
    .label check_status_roms1_check_status_rom1_main__0 = $73
    .label check_status_smc6_main__0 = $cf
    .label check_status_vera2_main__0 = $e6
    .label check_status_roms2_check_status_rom1_main__0 = $69
    .label check_status_roms_all1_check_status_rom1_main__0 = $ba
    .label check_status_smc8_main__0 = $67
    .label check_status_cx16_rom4_check_status_rom1_main__0 = $71
    .label check_status_smc9_main__0 = $d4
    .label check_status_cx16_rom5_check_status_rom1_main__0 = $df
    .label check_status_rom1_main__0 = $ee
    .label check_status_smc10_main__0 = $be
    .label check_status_smc11_main__0 = $b1
    .label check_status_roms3_check_status_rom1_main__0 = $53
    .label check_status_roms4_check_status_rom1_main__0 = $70
    .label check_status_smc13_main__0 = $6a
    .label check_status_smc1_return = $37
    .label check_status_cx16_rom1_check_status_rom1_return = $e5
    .label check_status_smc3_return = $2f
    .label check_status_cx16_rom2_check_status_rom1_return = $e8
    .label check_status_vera1_return = $c4
    .label check_status_roms1_check_status_rom1_return = $73
    .label check_status_smc6_return = $cf
    .label check_status_vera2_return = $e6
    .label check_status_roms2_check_status_rom1_return = $69
    .label check_status_roms_all1_check_status_rom1_return = $ba
    .label check_status_smc8_return = $67
    .label check_status_cx16_rom4_check_status_rom1_return = $71
    .label check_status_smc9_return = $d4
    .label check_status_cx16_rom5_check_status_rom1_return = $df
    .label ch1 = $e9
    .label check_status_rom1_return = $ee
    .label check_status_smc10_return = $be
    .label rom_differences = $30
    .label check_status_smc11_return = $b1
    .label check_status_roms3_check_status_rom1_return = $53
    .label check_status_roms4_check_status_rom1_return = $70
    .label check_status_smc13_return = $6a
    .label main__318 = $72
    .label main__319 = $72
    .label main__320 = $72
    .label main__322 = $68
    .label main__323 = $68
    .label main__324 = $68
    // main::SEI1
    // asm
    // asm { sei  }
    sei
    // main::bank_set_bram1
    // BRAM = bank
    // [73] BRAM = main::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // main::bank_set_brom1
    // BROM = bank
    // [74] BROM = main::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [75] phi from main::bank_set_brom1 to main::@66 [phi:main::bank_set_brom1->main::@66]
    // main::@66
    // display_frame_init_64()
    // [76] call display_frame_init_64
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
    // [777] phi from main::@66 to display_frame_init_64 [phi:main::@66->display_frame_init_64]
    jsr display_frame_init_64
    // [77] phi from main::@66 to main::@91 [phi:main::@66->main::@91]
    // main::@91
    // display_frame_draw()
    // [78] call display_frame_draw
    // [797] phi from main::@91 to display_frame_draw [phi:main::@91->display_frame_draw]
    jsr display_frame_draw
    // [79] phi from main::@91 to main::@92 [phi:main::@91->main::@92]
    // main::@92
    // display_frame_title("Commander X16 Flash Utility!")
    // [80] call display_frame_title
    // [838] phi from main::@92 to display_frame_title [phi:main::@92->display_frame_title]
    jsr display_frame_title
    // [81] phi from main::@92 to main::display_info_title1 [phi:main::@92->main::display_info_title1]
    // main::display_info_title1
    // cputsxy(INFO_X-2, INFO_Y-2, "# Chip Status    Type   Curr. Release Update Info")
    // [82] call cputsxy
    // [843] phi from main::display_info_title1 to cputsxy [phi:main::display_info_title1->cputsxy]
    // [843] phi cputsxy::s#4 = main::s [phi:main::display_info_title1->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z cputsxy.s
    lda #>s
    sta.z cputsxy.s+1
    // [843] phi cputsxy::y#4 = $11-2 [phi:main::display_info_title1->cputsxy#1] -- vbuz1=vbuc1 
    lda #$11-2
    sta.z cputsxy.y
    // [843] phi cputsxy::x#4 = 4-2 [phi:main::display_info_title1->cputsxy#2] -- vbuz1=vbuc1 
    lda #4-2
    sta.z cputsxy.x
    jsr cputsxy
    // [83] phi from main::display_info_title1 to main::@93 [phi:main::display_info_title1->main::@93]
    // main::@93
    // cputsxy(INFO_X-2, INFO_Y-1, "- ---- --------- ------ ------------- --------------------------")
    // [84] call cputsxy
    // [843] phi from main::@93 to cputsxy [phi:main::@93->cputsxy]
    // [843] phi cputsxy::s#4 = main::s1 [phi:main::@93->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s1
    sta.z cputsxy.s
    lda #>s1
    sta.z cputsxy.s+1
    // [843] phi cputsxy::y#4 = $11-1 [phi:main::@93->cputsxy#1] -- vbuz1=vbuc1 
    lda #$11-1
    sta.z cputsxy.y
    // [843] phi cputsxy::x#4 = 4-2 [phi:main::@93->cputsxy#2] -- vbuz1=vbuc1 
    lda #4-2
    sta.z cputsxy.x
    jsr cputsxy
    // [85] phi from main::@93 to main::@67 [phi:main::@93->main::@67]
    // main::@67
    // display_action_progress("Introduction ...")
    // [86] call display_action_progress
    // [850] phi from main::@67 to display_action_progress [phi:main::@67->display_action_progress]
    // [850] phi display_action_progress::info_text#18 = main::info_text [phi:main::@67->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [87] phi from main::@67 to main::@94 [phi:main::@67->main::@94]
    // main::@94
    // display_progress_clear()
    // [88] call display_progress_clear
    // [864] phi from main::@94 to display_progress_clear [phi:main::@94->display_progress_clear]
    jsr display_progress_clear
    // [89] phi from main::@94 to main::@95 [phi:main::@94->main::@95]
    // main::@95
    // display_chip_smc()
    // [90] call display_chip_smc
    // [879] phi from main::@95 to display_chip_smc [phi:main::@95->display_chip_smc]
    jsr display_chip_smc
    // [91] phi from main::@95 to main::@96 [phi:main::@95->main::@96]
    // main::@96
    // display_chip_vera()
    // [92] call display_chip_vera
    // [884] phi from main::@96 to display_chip_vera [phi:main::@96->display_chip_vera]
    jsr display_chip_vera
    // [93] phi from main::@96 to main::@97 [phi:main::@96->main::@97]
    // main::@97
    // display_chip_rom()
    // [94] call display_chip_rom
    // [889] phi from main::@97 to display_chip_rom [phi:main::@97->display_chip_rom]
    jsr display_chip_rom
    // [95] phi from main::@97 to main::@98 [phi:main::@97->main::@98]
    // main::@98
    // display_info_smc(STATUS_COLOR_NONE, NULL)
    // [96] call display_info_smc
    // [908] phi from main::@98 to display_info_smc [phi:main::@98->display_info_smc]
    // [908] phi display_info_smc::info_text#18 = 0 [phi:main::@98->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [908] phi smc_bootloader#13 = 0 [phi:main::@98->display_info_smc#1] -- vwum1=vwuc1 
    sta smc_bootloader_1
    sta smc_bootloader_1+1
    // [908] phi display_info_smc::info_status#18 = BLACK [phi:main::@98->display_info_smc#2] -- vbum1=vbuc1 
    lda #BLACK
    sta display_info_smc.info_status
    jsr display_info_smc
    // [97] phi from main::@98 to main::@99 [phi:main::@98->main::@99]
    // main::@99
    // display_info_vera(STATUS_NONE, NULL)
    // [98] call display_info_vera
    // [942] phi from main::@99 to display_info_vera [phi:main::@99->display_info_vera]
    // [942] phi display_info_vera::info_text#10 = 0 [phi:main::@99->display_info_vera#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_vera.info_text
    sta.z display_info_vera.info_text+1
    // [942] phi display_info_vera::info_status#3 = STATUS_NONE [phi:main::@99->display_info_vera#1] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta display_info_vera.info_status
    jsr display_info_vera
    // [99] phi from main::@99 to main::@13 [phi:main::@99->main::@13]
    // [99] phi main::rom_chip#2 = 0 [phi:main::@99->main::@13#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // main::@13
  __b13:
    // for(unsigned char rom_chip=0; rom_chip<8; rom_chip++)
    // [100] if(main::rom_chip#2<8) goto main::@14 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcs !__b14+
    jmp __b14
  !__b14:
    // [101] phi from main::@13 to main::@15 [phi:main::@13->main::@15]
    // main::@15
    // smc_detect()
    // [102] call smc_detect
    jsr smc_detect
    // [103] smc_detect::return#2 = smc_detect::return#0
    // main::@102
    // smc_bootloader = smc_detect()
    // [104] smc_bootloader#0 = smc_detect::return#2 -- vwum1=vwuz2 
    lda.z smc_detect.return
    sta smc_bootloader
    lda.z smc_detect.return+1
    sta smc_bootloader+1
    // strcpy(smc_version_text, "0.0.0")
    // [105] call strcpy
    // [979] phi from main::@102 to strcpy [phi:main::@102->strcpy]
    // [979] phi strcpy::dst#0 = smc_version_text [phi:main::@102->strcpy#0] -- pbuz1=pbuc1 
    lda #<smc_version_text
    sta.z strcpy.dst
    lda #>smc_version_text
    sta.z strcpy.dst+1
    // [979] phi strcpy::src#0 = main::source1 [phi:main::@102->strcpy#1] -- pbuz1=pbuc1 
    lda #<source1
    sta.z strcpy.src
    lda #>source1
    sta.z strcpy.src+1
    jsr strcpy
    // [106] phi from main::@102 to main::@103 [phi:main::@102->main::@103]
    // main::@103
    // display_chip_smc()
    // [107] call display_chip_smc
    // [879] phi from main::@103 to display_chip_smc [phi:main::@103->display_chip_smc]
    jsr display_chip_smc
    // main::@104
    // if(smc_bootloader == 0x0100)
    // [108] if(smc_bootloader#0==$100) goto main::@1 -- vwum1_eq_vwuc1_then_la1 
    lda smc_bootloader
    cmp #<$100
    bne !+
    lda smc_bootloader+1
    cmp #>$100
    bne !__b1+
    jmp __b1
  !__b1:
  !:
    // main::@16
    // if(smc_bootloader == 0x0200)
    // [109] if(smc_bootloader#0==$200) goto main::@19 -- vwum1_eq_vwuc1_then_la1 
    lda smc_bootloader
    cmp #<$200
    bne !+
    lda smc_bootloader+1
    cmp #>$200
    bne !__b19+
    jmp __b19
  !__b19:
  !:
    // main::@17
    // if(smc_bootloader > 0x2)
    // [110] if(smc_bootloader#0>=2+1) goto main::@20 -- vwum1_ge_vbuc1_then_la1 
    lda smc_bootloader+1
    beq !__b20+
    jmp __b20
  !__b20:
    lda smc_bootloader
    cmp #2+1
    bcc !__b20+
    jmp __b20
  !__b20:
  !:
    // main::@18
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_VERSION)
    // [111] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [112] cx16_k_i2c_read_byte::offset = $30 -- vbum1=vbuc1 
    lda #$30
    sta cx16_k_i2c_read_byte.offset
    // [113] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [114] cx16_k_i2c_read_byte::return#14 = cx16_k_i2c_read_byte::return#1
    // main::@111
    // smc_release = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_VERSION)
    // [115] smc_release#0 = cx16_k_i2c_read_byte::return#14 -- vbum1=vwuz2 
    lda.z cx16_k_i2c_read_byte.return
    sta smc_release
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_MAJOR)
    // [116] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [117] cx16_k_i2c_read_byte::offset = $31 -- vbum1=vbuc1 
    lda #$31
    sta cx16_k_i2c_read_byte.offset
    // [118] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [119] cx16_k_i2c_read_byte::return#15 = cx16_k_i2c_read_byte::return#1
    // main::@112
    // smc_major = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_MAJOR)
    // [120] smc_major#0 = cx16_k_i2c_read_byte::return#15 -- vbum1=vwuz2 
    lda.z cx16_k_i2c_read_byte.return
    sta smc_major
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_MINOR)
    // [121] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [122] cx16_k_i2c_read_byte::offset = $32 -- vbum1=vbuc1 
    lda #$32
    sta cx16_k_i2c_read_byte.offset
    // [123] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [124] cx16_k_i2c_read_byte::return#16 = cx16_k_i2c_read_byte::return#1
    // main::@113
    // smc_minor = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_MINOR)
    // [125] smc_minor#0 = cx16_k_i2c_read_byte::return#16 -- vbum1=vwuz2 
    lda.z cx16_k_i2c_read_byte.return
    sta smc_minor
    // smc_get_version_text(smc_version_text, smc_release, smc_major, smc_minor)
    // [126] smc_get_version_text::release#0 = smc_release#0 -- vbuz1=vbum2 
    lda smc_release
    sta.z smc_get_version_text.release
    // [127] smc_get_version_text::major#0 = smc_major#0 -- vbuz1=vbum2 
    lda smc_major
    sta.z smc_get_version_text.major
    // [128] smc_get_version_text::minor#0 = smc_minor#0 -- vbuz1=vbum2 
    lda smc_minor
    sta.z smc_get_version_text.minor
    // [129] call smc_get_version_text
    // [992] phi from main::@113 to smc_get_version_text [phi:main::@113->smc_get_version_text]
    // [992] phi smc_get_version_text::minor#2 = smc_get_version_text::minor#0 [phi:main::@113->smc_get_version_text#0] -- register_copy 
    // [992] phi smc_get_version_text::major#2 = smc_get_version_text::major#0 [phi:main::@113->smc_get_version_text#1] -- register_copy 
    // [992] phi smc_get_version_text::release#2 = smc_get_version_text::release#0 [phi:main::@113->smc_get_version_text#2] -- register_copy 
    // [992] phi smc_get_version_text::version_string#2 = smc_version_text [phi:main::@113->smc_get_version_text#3] -- pbuz1=pbuc1 
    lda #<smc_version_text
    sta.z smc_get_version_text.version_string
    lda #>smc_version_text
    sta.z smc_get_version_text.version_string+1
    jsr smc_get_version_text
    // main::@114
    // [130] smc_bootloader#467 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_DETECTED, NULL)
    // [131] call display_info_smc
    // [908] phi from main::@114 to display_info_smc [phi:main::@114->display_info_smc]
    // [908] phi display_info_smc::info_text#18 = 0 [phi:main::@114->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [908] phi smc_bootloader#13 = smc_bootloader#467 [phi:main::@114->display_info_smc#1] -- register_copy 
    // [908] phi display_info_smc::info_status#18 = STATUS_DETECTED [phi:main::@114->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_DETECTED
    sta display_info_smc.info_status
    jsr display_info_smc
    // [132] phi from main::@114 to main::@2 [phi:main::@114->main::@2]
    // [132] phi smc_minor#398 = smc_minor#0 [phi:main::@114->main::@2#0] -- register_copy 
    // [132] phi smc_major#399 = smc_major#0 [phi:main::@114->main::@2#1] -- register_copy 
    // [132] phi smc_release#400 = smc_release#0 [phi:main::@114->main::@2#2] -- register_copy 
    // main::@2
  __b2:
    // display_chip_vera()
    // [133] call display_chip_vera
  // Detecting VERA FPGA.
    // [884] phi from main::@2 to display_chip_vera [phi:main::@2->display_chip_vera]
    jsr display_chip_vera
    // [134] phi from main::@2 to main::@115 [phi:main::@2->main::@115]
    // main::@115
    // display_info_vera(STATUS_DETECTED, "VERA installed, OK")
    // [135] call display_info_vera
    // [942] phi from main::@115 to display_info_vera [phi:main::@115->display_info_vera]
    // [942] phi display_info_vera::info_text#10 = main::info_text3 [phi:main::@115->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text3
    sta.z display_info_vera.info_text
    lda #>info_text3
    sta.z display_info_vera.info_text+1
    // [942] phi display_info_vera::info_status#3 = STATUS_DETECTED [phi:main::@115->display_info_vera#1] -- vbum1=vbuc1 
    lda #STATUS_DETECTED
    sta display_info_vera.info_status
    jsr display_info_vera
    // [136] phi from main::@115 to main::@116 [phi:main::@115->main::@116]
    // main::@116
    // rom_detect()
    // [137] call rom_detect
  // Detecting ROM chips
    // [1009] phi from main::@116 to rom_detect [phi:main::@116->rom_detect]
    jsr rom_detect
    // [138] phi from main::@116 to main::@117 [phi:main::@116->main::@117]
    // main::@117
    // display_chip_rom()
    // [139] call display_chip_rom
    // [889] phi from main::@117 to display_chip_rom [phi:main::@117->display_chip_rom]
    jsr display_chip_rom
    // [140] phi from main::@117 to main::@21 [phi:main::@117->main::@21]
    // [140] phi main::rom_chip1#10 = 0 [phi:main::@117->main::@21#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip1
    // main::@21
  __b21:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [141] if(main::rom_chip1#10<8) goto main::@22 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip1
    cmp #8
    bcs !__b22+
    jmp __b22
  !__b22:
    // main::bank_set_brom2
    // BROM = bank
    // [142] BROM = main::bank_set_brom2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom2_bank
    sta.z BROM
    // main::CLI1
    // asm
    // asm { cli  }
    cli
    // [144] phi from main::CLI1 to main::@68 [phi:main::CLI1->main::@68]
    // main::@68
    // display_progress_text(display_into_briefing_text, display_intro_briefing_count)
    // [145] call display_progress_text
    // [1059] phi from main::@68 to display_progress_text [phi:main::@68->display_progress_text]
    // [1059] phi display_progress_text::text#12 = display_into_briefing_text [phi:main::@68->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_into_briefing_text
    sta.z display_progress_text.text
    lda #>display_into_briefing_text
    sta.z display_progress_text.text+1
    // [1059] phi display_progress_text::lines#11 = display_intro_briefing_count [phi:main::@68->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_intro_briefing_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [146] phi from main::@68 to main::@118 [phi:main::@68->main::@118]
    // main::@118
    // util_wait_space()
    // [147] call util_wait_space
    // [1069] phi from main::@118 to util_wait_space [phi:main::@118->util_wait_space]
    jsr util_wait_space
    // [148] phi from main::@118 to main::@119 [phi:main::@118->main::@119]
    // main::@119
    // display_progress_text(display_into_colors_text, display_intro_colors_count)
    // [149] call display_progress_text
    // [1059] phi from main::@119 to display_progress_text [phi:main::@119->display_progress_text]
    // [1059] phi display_progress_text::text#12 = display_into_colors_text [phi:main::@119->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_into_colors_text
    sta.z display_progress_text.text
    lda #>display_into_colors_text
    sta.z display_progress_text.text+1
    // [1059] phi display_progress_text::lines#11 = display_intro_colors_count [phi:main::@119->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_intro_colors_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [150] phi from main::@119 to main::@24 [phi:main::@119->main::@24]
    // [150] phi main::intro_status#2 = 0 [phi:main::@119->main::@24#0] -- vbum1=vbuc1 
    lda #0
    sta intro_status
    // main::@24
  __b24:
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [151] if(main::intro_status#2<$b) goto main::@25 -- vbum1_lt_vbuc1_then_la1 
    lda intro_status
    cmp #$b
    bcs !__b25+
    jmp __b25
  !__b25:
    // [152] phi from main::@24 to main::@26 [phi:main::@24->main::@26]
    // main::@26
    // util_wait_space()
    // [153] call util_wait_space
    // [1069] phi from main::@26 to util_wait_space [phi:main::@26->util_wait_space]
    jsr util_wait_space
    // [154] phi from main::@26 to main::@125 [phi:main::@26->main::@125]
    // main::@125
    // display_progress_clear()
    // [155] call display_progress_clear
    // [864] phi from main::@125 to display_progress_clear [phi:main::@125->display_progress_clear]
    jsr display_progress_clear
    // main::SEI2
    // asm
    // asm { sei  }
    sei
    // main::bank_set_brom4
    // BROM = bank
    // [157] BROM = main::bank_set_brom4_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom4_bank
    sta.z BROM
    // main::SEI3
    // asm
    // asm { sei  }
    sei
    // main::check_status_smc1
    // status_smc == status
    // [159] main::check_status_smc1_$0 = status_smc#0 == STATUS_DETECTED -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_DETECTED
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc1_main__0
    // return (unsigned char)(status_smc == status);
    // [160] main::check_status_smc1_return#0 = (char)main::check_status_smc1_$0
    // main::@70
    // if(check_status_smc(STATUS_DETECTED))
    // [161] if(0==main::check_status_smc1_return#0) goto main::CLI2 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_smc1_return
    bne !__b8+
    jmp __b8
  !__b8:
    // [162] phi from main::@70 to main::@27 [phi:main::@70->main::@27]
    // main::@27
    // smc_read(0)
    // [163] call smc_read
    // [1072] phi from main::@27 to smc_read [phi:main::@27->smc_read]
    // [1072] phi smc_read::display_progress#19 = 0 [phi:main::@27->smc_read#0] -- vbuz1=vbuc1 
    lda #0
    sta.z smc_read.display_progress
    // [1072] phi __errno#35 = 0 [phi:main::@27->smc_read#1] -- vwsz1=vwsc1 
    sta.z __errno
    sta.z __errno+1
    jsr smc_read
    // smc_read(0)
    // [164] smc_read::return#2 = smc_read::return#0
    // main::@126
    // smc_file_size = smc_read(0)
    // [165] smc_file_size#0 = smc_read::return#2 -- vwum1=vwum2 
    lda smc_read.return
    sta smc_file_size
    lda smc_read.return+1
    sta smc_file_size+1
    // if (!smc_file_size)
    // [166] if(0==smc_file_size#0) goto main::@30 -- 0_eq_vwum1_then_la1 
    lda smc_file_size
    ora smc_file_size+1
    bne !__b30+
    jmp __b30
  !__b30:
    // main::@28
    // if(smc_file_size > 0x1E00)
    // [167] if(smc_file_size#0>$1e00) goto main::@31 -- vwum1_gt_vwuc1_then_la1 
    lda #>$1e00
    cmp smc_file_size+1
    bcs !__b31+
    jmp __b31
  !__b31:
    bne !+
    lda #<$1e00
    cmp smc_file_size
    bcs !__b31+
    jmp __b31
  !__b31:
  !:
    // main::@29
    // rom_get_release(*((char*)RAM_BASE+0x30))
    // [168] rom_get_release::release#2 = *((char *)$7800+$30) -- vbum1=_deref_pbuc1 
    lda $7800+$30
    sta rom_get_release.release
    // [169] call rom_get_release
    // [1135] phi from main::@29 to rom_get_release [phi:main::@29->rom_get_release]
    // [1135] phi rom_get_release::release#4 = rom_get_release::release#2 [phi:main::@29->rom_get_release#0] -- register_copy 
    jsr rom_get_release
    // rom_get_release(*((char*)RAM_BASE+0x30))
    // [170] rom_get_release::return#3 = rom_get_release::return#0
    // main::@127
    // smc_file_release = rom_get_release(*((char*)RAM_BASE+0x30))
    // [171] smc_file_release#0 = rom_get_release::return#3 -- vbum1=vbum2 
    lda rom_get_release.return
    sta smc_file_release
    // rom_get_prefix(*((char*)RAM_BASE+0x31))
    // [172] rom_get_prefix::release#1 = *((char *)$7800+$31) -- vbum1=_deref_pbuc1 
    lda $7800+$31
    sta rom_get_prefix.release
    // [173] call rom_get_prefix
    // [1142] phi from main::@127 to rom_get_prefix [phi:main::@127->rom_get_prefix]
    // [1142] phi rom_get_prefix::release#4 = rom_get_prefix::release#1 [phi:main::@127->rom_get_prefix#0] -- register_copy 
    jsr rom_get_prefix
    // rom_get_prefix(*((char*)RAM_BASE+0x31))
    // [174] rom_get_prefix::return#3 = rom_get_prefix::return#0
    // main::@128
    // smc_file_major = rom_get_prefix(*((char*)RAM_BASE+0x31))
    // [175] smc_file_major#0 = rom_get_prefix::return#3 -- vbum1=vbum2 
    lda rom_get_prefix.return
    sta smc_file_major
    // rom_get_prefix(*((char*)RAM_BASE+0x32))
    // [176] rom_get_prefix::release#2 = *((char *)$7800+$32) -- vbum1=_deref_pbuc1 
    lda $7800+$32
    sta rom_get_prefix.release
    // [177] call rom_get_prefix
    // [1142] phi from main::@128 to rom_get_prefix [phi:main::@128->rom_get_prefix]
    // [1142] phi rom_get_prefix::release#4 = rom_get_prefix::release#2 [phi:main::@128->rom_get_prefix#0] -- register_copy 
    jsr rom_get_prefix
    // rom_get_prefix(*((char*)RAM_BASE+0x32))
    // [178] rom_get_prefix::return#4 = rom_get_prefix::return#0
    // main::@129
    // smc_file_minor = rom_get_prefix(*((char*)RAM_BASE+0x32))
    // [179] smc_file_minor#0 = rom_get_prefix::return#4 -- vbum1=vbum2 
    lda rom_get_prefix.return
    sta smc_file_minor
    // smc_get_version_text(smc_file_version_text, smc_file_release, smc_file_major, smc_file_minor)
    // [180] smc_get_version_text::release#1 = smc_file_release#0 -- vbuz1=vbum2 
    lda smc_file_release
    sta.z smc_get_version_text.release
    // [181] smc_get_version_text::major#1 = smc_file_major#0 -- vbuz1=vbum2 
    lda smc_file_major
    sta.z smc_get_version_text.major
    // [182] smc_get_version_text::minor#1 = smc_file_minor#0 -- vbuz1=vbum2 
    lda smc_file_minor
    sta.z smc_get_version_text.minor
    // [183] call smc_get_version_text
    // [992] phi from main::@129 to smc_get_version_text [phi:main::@129->smc_get_version_text]
    // [992] phi smc_get_version_text::minor#2 = smc_get_version_text::minor#1 [phi:main::@129->smc_get_version_text#0] -- register_copy 
    // [992] phi smc_get_version_text::major#2 = smc_get_version_text::major#1 [phi:main::@129->smc_get_version_text#1] -- register_copy 
    // [992] phi smc_get_version_text::release#2 = smc_get_version_text::release#1 [phi:main::@129->smc_get_version_text#2] -- register_copy 
    // [992] phi smc_get_version_text::version_string#2 = main::smc_file_version_text [phi:main::@129->smc_get_version_text#3] -- pbuz1=pbuc1 
    lda #<smc_file_version_text
    sta.z smc_get_version_text.version_string
    lda #>smc_file_version_text
    sta.z smc_get_version_text.version_string+1
    jsr smc_get_version_text
    // [184] phi from main::@129 to main::@130 [phi:main::@129->main::@130]
    // main::@130
    // sprintf(info_text, "SMC.BIN:%s", smc_file_version_text)
    // [185] call snprintf_init
    // [1151] phi from main::@130 to snprintf_init [phi:main::@130->snprintf_init]
    // [1151] phi snprintf_init::s#26 = info_text [phi:main::@130->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [186] phi from main::@130 to main::@131 [phi:main::@130->main::@131]
    // main::@131
    // sprintf(info_text, "SMC.BIN:%s", smc_file_version_text)
    // [187] call printf_str
    // [1156] phi from main::@131 to printf_str [phi:main::@131->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:main::@131->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = main::s4 [phi:main::@131->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // [188] phi from main::@131 to main::@132 [phi:main::@131->main::@132]
    // main::@132
    // sprintf(info_text, "SMC.BIN:%s", smc_file_version_text)
    // [189] call printf_string
    // [1165] phi from main::@132 to printf_string [phi:main::@132->printf_string]
    // [1165] phi printf_string::putc#22 = &snputc [phi:main::@132->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1165] phi printf_string::str#22 = main::smc_file_version_text [phi:main::@132->printf_string#1] -- pbuz1=pbuc1 
    lda #<smc_file_version_text
    sta.z printf_string.str
    lda #>smc_file_version_text
    sta.z printf_string.str+1
    // [1165] phi printf_string::format_justify_left#22 = 0 [phi:main::@132->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1165] phi printf_string::format_min_length#22 = 0 [phi:main::@132->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@133
    // sprintf(info_text, "SMC.BIN:%s", smc_file_version_text)
    // [190] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [191] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [193] smc_bootloader#469 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_FLASH, info_text)
    // [194] call display_info_smc
  // All ok, display file version.
    // [908] phi from main::@133 to display_info_smc [phi:main::@133->display_info_smc]
    // [908] phi display_info_smc::info_text#18 = info_text [phi:main::@133->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_smc.info_text
    lda #>@info_text
    sta.z display_info_smc.info_text+1
    // [908] phi smc_bootloader#13 = smc_bootloader#469 [phi:main::@133->display_info_smc#1] -- register_copy 
    // [908] phi display_info_smc::info_status#18 = STATUS_FLASH [phi:main::@133->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta display_info_smc.info_status
    jsr display_info_smc
    // [195] phi from main::@133 to main::CLI2 [phi:main::@133->main::CLI2]
    // [195] phi smc_file_minor#246 = smc_file_minor#0 [phi:main::@133->main::CLI2#0] -- register_copy 
    // [195] phi smc_file_major#247 = smc_file_major#0 [phi:main::@133->main::CLI2#1] -- register_copy 
    // [195] phi smc_file_release#248 = smc_file_release#0 [phi:main::@133->main::CLI2#2] -- register_copy 
    // [195] phi __errno#239 = __errno#18 [phi:main::@133->main::CLI2#3] -- register_copy 
    jmp CLI2
    // [195] phi from main::@70 to main::CLI2 [phi:main::@70->main::CLI2]
  __b8:
    // [195] phi smc_file_minor#246 = 0 [phi:main::@70->main::CLI2#0] -- vbum1=vbuc1 
    lda #0
    sta smc_file_minor
    // [195] phi smc_file_major#247 = 0 [phi:main::@70->main::CLI2#1] -- vbum1=vbuc1 
    sta smc_file_major
    // [195] phi smc_file_release#248 = 0 [phi:main::@70->main::CLI2#2] -- vbum1=vbuc1 
    sta smc_file_release
    // [195] phi __errno#239 = 0 [phi:main::@70->main::CLI2#3] -- vwsz1=vwsc1 
    sta.z __errno
    sta.z __errno+1
    // main::CLI2
  CLI2:
    // asm
    // asm { cli  }
    cli
    // main::SEI4
    // asm { sei  }
    sei
    // [198] phi from main::SEI4 to main::@32 [phi:main::SEI4->main::@32]
    // [198] phi __errno#114 = __errno#239 [phi:main::SEI4->main::@32#0] -- register_copy 
    // [198] phi main::rom_chip2#10 = 0 [phi:main::SEI4->main::@32#1] -- vbum1=vbuc1 
    lda #0
    sta rom_chip2
  // We loop all the possible ROM chip slots on the board and on the extension card,
  // and we check the file contents.
  // Any error identified gets reported and this chip will not be flashed.
  // In case of ROM0.BIN in error, no flashing will be done!
    // main::@32
  __b32:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [199] if(main::rom_chip2#10<8) goto main::bank_set_brom5 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip2
    cmp #8
    bcs !bank_set_brom5+
    jmp bank_set_brom5
  !bank_set_brom5:
    // main::bank_set_brom6
    // BROM = bank
    // [200] BROM = main::bank_set_brom6_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom6_bank
    sta.z BROM
    // main::CLI3
    // asm
    // asm { cli  }
    cli
    // main::check_status_smc2
    // status_smc == status
    // [202] main::check_status_smc2_$0 = status_smc#0 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc2_main__0
    // return (unsigned char)(status_smc == status);
    // [203] main::check_status_smc2_return#0 = (char)main::check_status_smc2_$0
    // [204] phi from main::check_status_smc2 to main::check_status_cx16_rom1 [phi:main::check_status_smc2->main::check_status_cx16_rom1]
    // main::check_status_cx16_rom1
    // main::check_status_cx16_rom1_check_status_rom1
    // status_rom[rom_chip] == status
    // [205] main::check_status_cx16_rom1_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_cx16_rom1_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [206] main::check_status_cx16_rom1_check_status_rom1_return#0 = (char)main::check_status_cx16_rom1_check_status_rom1_$0
    // main::@72
    // if(!check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH))
    // [207] if(0!=main::check_status_smc2_return#0) goto main::check_status_smc3 -- 0_neq_vbum1_then_la1 
    lda check_status_smc2_return
    bne check_status_smc3
    // main::@220
    // [208] if(0!=main::check_status_cx16_rom1_check_status_rom1_return#0) goto main::@39 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_cx16_rom1_check_status_rom1_return
    beq !__b39+
    jmp __b39
  !__b39:
    // main::check_status_smc3
  check_status_smc3:
    // status_smc == status
    // [209] main::check_status_smc3_$0 = status_smc#0 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc3_main__0
    // return (unsigned char)(status_smc == status);
    // [210] main::check_status_smc3_return#0 = (char)main::check_status_smc3_$0
    // [211] phi from main::check_status_smc3 to main::check_status_cx16_rom2 [phi:main::check_status_smc3->main::check_status_cx16_rom2]
    // main::check_status_cx16_rom2
    // main::check_status_cx16_rom2_check_status_rom1
    // status_rom[rom_chip] == status
    // [212] main::check_status_cx16_rom2_check_status_rom1_$0 = *status_rom == STATUS_NONE -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_NONE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_cx16_rom2_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [213] main::check_status_cx16_rom2_check_status_rom1_return#0 = (char)main::check_status_cx16_rom2_check_status_rom1_$0
    // main::@75
    // if(check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_NONE))
    // [214] if(0==main::check_status_smc3_return#0) goto main::check_status_smc4 -- 0_eq_vbuz1_then_la1 
    // VA-3 | SMC.BIN and CX16 ROM not Detected | Display issue and don't flash. Ask to close the J1 jumper pins on the CX16 main board. | Issue
    lda.z check_status_smc3_return
    beq check_status_smc4
    // main::@221
    // [215] if(0!=main::check_status_cx16_rom2_check_status_rom1_return#0) goto main::@3 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_cx16_rom2_check_status_rom1_return
    beq !__b3+
    jmp __b3
  !__b3:
    // main::check_status_smc4
  check_status_smc4:
    // status_smc == status
    // [216] main::check_status_smc4_$0 = status_smc#0 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc4_main__0
    // return (unsigned char)(status_smc == status);
    // [217] main::check_status_smc4_return#0 = (char)main::check_status_smc4_$0
    // [218] phi from main::check_status_smc4 to main::check_status_cx16_rom3 [phi:main::check_status_smc4->main::check_status_cx16_rom3]
    // main::check_status_cx16_rom3
    // main::check_status_cx16_rom3_check_status_rom1
    // status_rom[rom_chip] == status
    // [219] main::check_status_cx16_rom3_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vbom1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_cx16_rom3_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [220] main::check_status_cx16_rom3_check_status_rom1_return#0 = (char)main::check_status_cx16_rom3_check_status_rom1_$0
    // main::@76
    // if(check_status_smc(STATUS_FLASH) && !check_status_cx16_rom(STATUS_FLASH))
    // [221] if(0==main::check_status_smc4_return#0) goto main::@4 -- 0_eq_vbum1_then_la1 
    lda check_status_smc4_return
    beq __b4
    // main::@222
    // [222] if(0==main::check_status_cx16_rom3_check_status_rom1_return#0) goto main::@6 -- 0_eq_vbum1_then_la1 
    lda check_status_cx16_rom3_check_status_rom1_return
    bne !__b6+
    jmp __b6
  !__b6:
    // main::@4
  __b4:
    // if(smc_release == smc_file_release && smc_major == smc_file_major && smc_minor == smc_file_minor)
    // [223] if(smc_release#400!=smc_file_release#248) goto main::@5 -- vbum1_neq_vbum2_then_la1 
    lda smc_release
    cmp smc_file_release
    bne __b5
    // main::@224
    // [224] if(smc_major#399!=smc_file_major#247) goto main::@5 -- vbum1_neq_vbum2_then_la1 
    lda smc_major
    cmp smc_file_major
    bne __b5
    // main::@223
    // [225] if(smc_minor#398==smc_file_minor#246) goto main::@7 -- vbum1_eq_vbum2_then_la1 
    lda smc_minor
    cmp smc_file_minor
    bne !__b7+
    jmp __b7
  !__b7:
    // main::@5
  __b5:
    // smc_supported_rom(rom_release[0])
    // [226] smc_supported_rom::rom_release#0 = *rom_release -- vbum1=_deref_pbuc1 
    lda rom_release
    sta smc_supported_rom.rom_release
    // [227] call smc_supported_rom
    // [1190] phi from main::@5 to smc_supported_rom [phi:main::@5->smc_supported_rom]
    jsr smc_supported_rom
    // smc_supported_rom(rom_release[0])
    // [228] smc_supported_rom::return#3 = smc_supported_rom::return#2
    // main::@168
    // [229] main::$52 = smc_supported_rom::return#3
    // if(!smc_supported_rom(rom_release[0]))
    // [230] if(0!=main::$52) goto main::check_status_smc5 -- 0_neq_vbum1_then_la1 
    lda main__52
    bne check_status_smc5
    // [231] phi from main::@168 to main::@8 [phi:main::@168->main::@8]
    // main::@8
    // display_action_progress("The ROM.BIN isn't compatible with SMC.BIN, no flash allowed!")
    // [232] call display_action_progress
    // [850] phi from main::@8 to display_action_progress [phi:main::@8->display_action_progress]
    // [850] phi display_action_progress::info_text#18 = main::info_text15 [phi:main::@8->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text15
    sta.z display_action_progress.info_text
    lda #>info_text15
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [233] phi from main::@8 to main::@171 [phi:main::@8->main::@171]
    // main::@171
    // display_progress_text(display_smc_unsupported_rom_text, display_smc_unsupported_rom_count)
    // [234] call display_progress_text
    // [1059] phi from main::@171 to display_progress_text [phi:main::@171->display_progress_text]
    // [1059] phi display_progress_text::text#12 = display_smc_unsupported_rom_text [phi:main::@171->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_unsupported_rom_text
    sta.z display_progress_text.text
    lda #>display_smc_unsupported_rom_text
    sta.z display_progress_text.text+1
    // [1059] phi display_progress_text::lines#11 = display_smc_unsupported_rom_count [phi:main::@171->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_smc_unsupported_rom_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [235] phi from main::@171 to main::@172 [phi:main::@171->main::@172]
    // main::@172
    // unsigned char ch = util_wait_key("You still want to continue with flashing? [YN]", "YN")
    // [236] call util_wait_key
    // [1197] phi from main::@172 to util_wait_key [phi:main::@172->util_wait_key]
    // [1197] phi util_wait_key::filter#13 = main::filter [phi:main::@172->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter
    sta.z util_wait_key.filter
    lda #>filter
    sta.z util_wait_key.filter+1
    // [1197] phi util_wait_key::info_text#3 = main::info_text16 [phi:main::@172->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text16
    sta.z util_wait_key.info_text
    lda #>info_text16
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("You still want to continue with flashing? [YN]", "YN")
    // [237] util_wait_key::return#3 = util_wait_key::ch#4 -- vbum1=vwum2 
    lda util_wait_key.ch
    sta util_wait_key.return
    // main::@173
    // [238] main::ch#0 = util_wait_key::return#3
    // if(ch == 'N')
    // [239] if(main::ch#0!='N') goto main::check_status_smc5 -- vbum1_neq_vbuc1_then_la1 
    lda #'N'
    cmp ch
    bne check_status_smc5
    // main::@9
    // [240] smc_bootloader#465 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ISSUE, NULL)
    // [241] call display_info_smc
  // Cancel flash
    // [908] phi from main::@9 to display_info_smc [phi:main::@9->display_info_smc]
    // [908] phi display_info_smc::info_text#18 = 0 [phi:main::@9->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [908] phi smc_bootloader#13 = smc_bootloader#465 [phi:main::@9->display_info_smc#1] -- register_copy 
    // [908] phi display_info_smc::info_status#18 = STATUS_ISSUE [phi:main::@9->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_smc.info_status
    jsr display_info_smc
    // [242] phi from main::@9 to main::@174 [phi:main::@9->main::@174]
    // main::@174
    // display_info_cx16_rom(STATUS_ISSUE, NULL)
    // [243] call display_info_cx16_rom
    // [1221] phi from main::@174 to display_info_cx16_rom [phi:main::@174->display_info_cx16_rom]
    // [1221] phi display_info_cx16_rom::info_text#4 = 0 [phi:main::@174->display_info_cx16_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_cx16_rom.info_text
    sta.z display_info_cx16_rom.info_text+1
    // [1221] phi display_info_cx16_rom::info_status#4 = STATUS_ISSUE [phi:main::@174->display_info_cx16_rom#1] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    // main::check_status_smc5
  check_status_smc5:
    // status_smc == status
    // [244] main::check_status_smc5_$0 = status_smc#0 == STATUS_ISSUE -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc5_main__0
    // return (unsigned char)(status_smc == status);
    // [245] main::check_status_smc5_return#0 = (char)main::check_status_smc5_$0
    // main::check_status_vera1
    // status_vera == status
    // [246] main::check_status_vera1_$0 = status_vera#0 == STATUS_ISSUE -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_vera1_main__0
    // return (unsigned char)(status_vera == status);
    // [247] main::check_status_vera1_return#0 = (char)main::check_status_vera1_$0
    // [248] phi from main::check_status_vera1 to main::check_status_roms1 [phi:main::check_status_vera1->main::check_status_roms1]
    // main::check_status_roms1
    // [249] phi from main::check_status_roms1 to main::check_status_roms1_@1 [phi:main::check_status_roms1->main::check_status_roms1_@1]
    // [249] phi main::check_status_roms1_rom_chip#2 = 0 [phi:main::check_status_roms1->main::check_status_roms1_@1#0] -- vbum1=vbuc1 
    lda #0
    sta check_status_roms1_rom_chip
    // main::check_status_roms1_@1
  check_status_roms1___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [250] if(main::check_status_roms1_rom_chip#2<8) goto main::check_status_roms1_check_status_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda check_status_roms1_rom_chip
    cmp #8
    bcs !check_status_roms1_check_status_rom1+
    jmp check_status_roms1_check_status_rom1
  !check_status_roms1_check_status_rom1:
    // [251] phi from main::check_status_roms1_@1 to main::check_status_roms1_@return [phi:main::check_status_roms1_@1->main::check_status_roms1_@return]
    // [251] phi main::check_status_roms1_return#2 = 0 [phi:main::check_status_roms1_@1->main::check_status_roms1_@return#0] -- vbum1=vbuc1 
    lda #0
    sta check_status_roms1_return
    // main::check_status_roms1_@return
    // main::check_status_smc6
  check_status_smc6:
    // status_smc == status
    // [252] main::check_status_smc6_$0 = status_smc#0 == STATUS_ERROR -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc6_main__0
    // return (unsigned char)(status_smc == status);
    // [253] main::check_status_smc6_return#0 = (char)main::check_status_smc6_$0
    // main::check_status_vera2
    // status_vera == status
    // [254] main::check_status_vera2_$0 = status_vera#0 == STATUS_ERROR -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_vera2_main__0
    // return (unsigned char)(status_vera == status);
    // [255] main::check_status_vera2_return#0 = (char)main::check_status_vera2_$0
    // [256] phi from main::check_status_vera2 to main::check_status_roms2 [phi:main::check_status_vera2->main::check_status_roms2]
    // main::check_status_roms2
    // [257] phi from main::check_status_roms2 to main::check_status_roms2_@1 [phi:main::check_status_roms2->main::check_status_roms2_@1]
    // [257] phi main::check_status_roms2_rom_chip#2 = 0 [phi:main::check_status_roms2->main::check_status_roms2_@1#0] -- vbum1=vbuc1 
    lda #0
    sta check_status_roms2_rom_chip
    // main::check_status_roms2_@1
  check_status_roms2___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [258] if(main::check_status_roms2_rom_chip#2<8) goto main::check_status_roms2_check_status_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda check_status_roms2_rom_chip
    cmp #8
    bcs !check_status_roms2_check_status_rom1+
    jmp check_status_roms2_check_status_rom1
  !check_status_roms2_check_status_rom1:
    // [259] phi from main::check_status_roms2_@1 to main::check_status_roms2_@return [phi:main::check_status_roms2_@1->main::check_status_roms2_@return]
    // [259] phi main::check_status_roms2_return#2 = 0 [phi:main::check_status_roms2_@1->main::check_status_roms2_@return#0] -- vbum1=vbuc1 
    lda #0
    sta check_status_roms2_return
    // main::check_status_roms2_@return
    // main::@77
  __b77:
    // if(!check_status_smc(STATUS_ISSUE) && !check_status_vera(STATUS_ISSUE) && !check_status_roms(STATUS_ISSUE) &&
    //        !check_status_smc(STATUS_ERROR) && !check_status_vera(STATUS_ERROR) && !check_status_roms(STATUS_ERROR))
    // [260] if(0!=main::check_status_smc5_return#0) goto main::check_status_smc7 -- 0_neq_vbum1_then_la1 
    lda check_status_smc5_return
    bne check_status_smc7
    // main::@229
    // [261] if(0==main::check_status_vera1_return#0) goto main::@228 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_vera1_return
    bne !__b228+
    jmp __b228
  !__b228:
    // main::check_status_smc7
  check_status_smc7:
    // status_smc == status
    // [262] main::check_status_smc7_$0 = status_smc#0 == STATUS_SKIP -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc7_main__0
    // return (unsigned char)(status_smc == status);
    // [263] main::check_status_smc7_return#0 = (char)main::check_status_smc7_$0
    // main::check_status_vera3
    // status_vera == status
    // [264] main::check_status_vera3_$0 = status_vera#0 == STATUS_SKIP -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_vera3_main__0
    // return (unsigned char)(status_vera == status);
    // [265] main::check_status_vera3_return#0 = (char)main::check_status_vera3_$0
    // [266] phi from main::check_status_vera3 to main::check_status_roms_all1 [phi:main::check_status_vera3->main::check_status_roms_all1]
    // main::check_status_roms_all1
    // [267] phi from main::check_status_roms_all1 to main::check_status_roms_all1_@1 [phi:main::check_status_roms_all1->main::check_status_roms_all1_@1]
    // [267] phi main::check_status_roms_all1_rom_chip#2 = 0 [phi:main::check_status_roms_all1->main::check_status_roms_all1_@1#0] -- vbum1=vbuc1 
    lda #0
    sta check_status_roms_all1_rom_chip
    // main::check_status_roms_all1_@1
  check_status_roms_all1___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [268] if(main::check_status_roms_all1_rom_chip#2<8) goto main::check_status_roms_all1_check_status_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda check_status_roms_all1_rom_chip
    cmp #8
    bcs !check_status_roms_all1_check_status_rom1+
    jmp check_status_roms_all1_check_status_rom1
  !check_status_roms_all1_check_status_rom1:
    // [269] phi from main::check_status_roms_all1_@1 to main::check_status_roms_all1_@return [phi:main::check_status_roms_all1_@1->main::check_status_roms_all1_@return]
    // [269] phi main::check_status_roms_all1_return#2 = 1 [phi:main::check_status_roms_all1_@1->main::check_status_roms_all1_@return#0] -- vbum1=vbuc1 
    lda #1
    sta check_status_roms_all1_return
    // main::check_status_roms_all1_@return
    // main::@78
  __b78:
    // if(check_status_smc(STATUS_SKIP) && check_status_vera(STATUS_SKIP) && check_status_roms_all(STATUS_SKIP))
    // [270] if(0==main::check_status_smc7_return#0) goto main::check_status_smc11 -- 0_eq_vbum1_then_la1 
    lda check_status_smc7_return
    beq check_status_smc11
    // main::@231
    // [271] if(0==main::check_status_vera3_return#0) goto main::check_status_smc11 -- 0_eq_vbum1_then_la1 
    lda check_status_vera3_return
    beq check_status_smc11
    // main::@230
    // [272] if(0!=main::check_status_roms_all1_return#2) goto main::vera_display_set_border_color1 -- 0_neq_vbum1_then_la1 
    lda check_status_roms_all1_return
    beq !vera_display_set_border_color1+
    jmp vera_display_set_border_color1
  !vera_display_set_border_color1:
    // main::check_status_smc11
  check_status_smc11:
    // status_smc == status
    // [273] main::check_status_smc11_$0 = status_smc#0 == STATUS_ERROR -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc11_main__0
    // return (unsigned char)(status_smc == status);
    // [274] main::check_status_smc11_return#0 = (char)main::check_status_smc11_$0
    // main::check_status_vera4
    // status_vera == status
    // [275] main::check_status_vera4_$0 = status_vera#0 == STATUS_ERROR -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_vera4_main__0
    // return (unsigned char)(status_vera == status);
    // [276] main::check_status_vera4_return#0 = (char)main::check_status_vera4_$0
    // [277] phi from main::check_status_vera4 to main::check_status_roms3 [phi:main::check_status_vera4->main::check_status_roms3]
    // main::check_status_roms3
    // [278] phi from main::check_status_roms3 to main::check_status_roms3_@1 [phi:main::check_status_roms3->main::check_status_roms3_@1]
    // [278] phi main::check_status_roms3_rom_chip#2 = 0 [phi:main::check_status_roms3->main::check_status_roms3_@1#0] -- vbum1=vbuc1 
    lda #0
    sta check_status_roms3_rom_chip
    // main::check_status_roms3_@1
  check_status_roms3___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [279] if(main::check_status_roms3_rom_chip#2<8) goto main::check_status_roms3_check_status_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda check_status_roms3_rom_chip
    cmp #8
    bcs !check_status_roms3_check_status_rom1+
    jmp check_status_roms3_check_status_rom1
  !check_status_roms3_check_status_rom1:
    // [280] phi from main::check_status_roms3_@1 to main::check_status_roms3_@return [phi:main::check_status_roms3_@1->main::check_status_roms3_@return]
    // [280] phi main::check_status_roms3_return#2 = 0 [phi:main::check_status_roms3_@1->main::check_status_roms3_@return#0] -- vbum1=vbuc1 
    lda #0
    sta check_status_roms3_return
    // main::check_status_roms3_@return
    // main::@85
  __b85:
    // if(check_status_smc(STATUS_ERROR) || check_status_vera(STATUS_ERROR) || check_status_roms(STATUS_ERROR))
    // [281] if(0!=main::check_status_smc11_return#0) goto main::vera_display_set_border_color2 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc11_return
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::@238
    // [282] if(0!=main::check_status_vera4_return#0) goto main::vera_display_set_border_color2 -- 0_neq_vbum1_then_la1 
    lda check_status_vera4_return
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::@237
    // [283] if(0!=main::check_status_roms3_return#2) goto main::vera_display_set_border_color2 -- 0_neq_vbum1_then_la1 
    lda check_status_roms3_return
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::check_status_smc12
    // status_smc == status
    // [284] main::check_status_smc12_$0 = status_smc#0 == STATUS_ISSUE -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc12_main__0
    // return (unsigned char)(status_smc == status);
    // [285] main::check_status_smc12_return#0 = (char)main::check_status_smc12_$0
    // main::check_status_vera5
    // status_vera == status
    // [286] main::check_status_vera5_$0 = status_vera#0 == STATUS_ISSUE -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_vera5_main__0
    // return (unsigned char)(status_vera == status);
    // [287] main::check_status_vera5_return#0 = (char)main::check_status_vera5_$0
    // [288] phi from main::check_status_vera5 to main::check_status_roms4 [phi:main::check_status_vera5->main::check_status_roms4]
    // main::check_status_roms4
    // [289] phi from main::check_status_roms4 to main::check_status_roms4_@1 [phi:main::check_status_roms4->main::check_status_roms4_@1]
    // [289] phi main::check_status_roms4_rom_chip#2 = 0 [phi:main::check_status_roms4->main::check_status_roms4_@1#0] -- vbum1=vbuc1 
    lda #0
    sta check_status_roms4_rom_chip
    // main::check_status_roms4_@1
  check_status_roms4___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [290] if(main::check_status_roms4_rom_chip#2<8) goto main::check_status_roms4_check_status_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda check_status_roms4_rom_chip
    cmp #8
    bcs !check_status_roms4_check_status_rom1+
    jmp check_status_roms4_check_status_rom1
  !check_status_roms4_check_status_rom1:
    // [291] phi from main::check_status_roms4_@1 to main::check_status_roms4_@return [phi:main::check_status_roms4_@1->main::check_status_roms4_@return]
    // [291] phi main::check_status_roms4_return#2 = 0 [phi:main::check_status_roms4_@1->main::check_status_roms4_@return#0] -- vbum1=vbuc1 
    lda #0
    sta check_status_roms4_return
    // main::check_status_roms4_@return
    // main::@87
  __b87:
    // if(check_status_smc(STATUS_ISSUE) || check_status_vera(STATUS_ISSUE) || check_status_roms(STATUS_ISSUE))
    // [292] if(0!=main::check_status_smc12_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbum1_then_la1 
    lda check_status_smc12_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::@240
    // [293] if(0!=main::check_status_vera5_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbum1_then_la1 
    lda check_status_vera5_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::@239
    // [294] if(0!=main::check_status_roms4_return#2) goto main::vera_display_set_border_color3 -- 0_neq_vbum1_then_la1 
    lda check_status_roms4_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::vera_display_set_border_color4
    // *VERA_CTRL &= ~VERA_DCSEL
    // [295] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [296] *VERA_DC_BORDER = GREEN -- _deref_pbuc1=vbuc2 
    lda #GREEN
    sta VERA_DC_BORDER
    // [297] phi from main::vera_display_set_border_color4 to main::@89 [phi:main::vera_display_set_border_color4->main::@89]
    // main::@89
    // display_action_progress("Your CX16 update is a success!")
    // [298] call display_action_progress
    // [850] phi from main::@89 to display_action_progress [phi:main::@89->display_action_progress]
    // [850] phi display_action_progress::info_text#18 = main::info_text37 [phi:main::@89->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text37
    sta.z display_action_progress.info_text
    lda #>info_text37
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::check_status_smc13
    // status_smc == status
    // [299] main::check_status_smc13_$0 = status_smc#0 == STATUS_FLASHED -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASHED
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc13_main__0
    // return (unsigned char)(status_smc == status);
    // [300] main::check_status_smc13_return#0 = (char)main::check_status_smc13_$0
    // main::@90
    // if(check_status_smc(STATUS_FLASHED))
    // [301] if(0!=main::check_status_smc13_return#0) goto main::@58 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc13_return
    beq !__b58+
    jmp __b58
  !__b58:
    // [302] phi from main::@90 to main::@12 [phi:main::@90->main::@12]
    // main::@12
    // display_progress_text(display_debriefing_text_rom, display_debriefing_count_rom)
    // [303] call display_progress_text
    // [1059] phi from main::@12 to display_progress_text [phi:main::@12->display_progress_text]
    // [1059] phi display_progress_text::text#12 = display_debriefing_text_rom [phi:main::@12->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_debriefing_text_rom
    sta.z display_progress_text.text
    lda #>display_debriefing_text_rom
    sta.z display_progress_text.text+1
    // [1059] phi display_progress_text::lines#11 = display_debriefing_count_rom [phi:main::@12->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_debriefing_count_rom
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [304] phi from main::@12 main::@213 main::@84 main::@88 to main::@63 [phi:main::@12/main::@213/main::@84/main::@88->main::@63]
  __b9:
    // [304] phi main::w1#2 = $c8 [phi:main::@12/main::@213/main::@84/main::@88->main::@63#0] -- vbum1=vbuc1 
    lda #$c8
    sta w1
  // DE-6 | Wait until reset
    // main::@63
  __b63:
    // for (unsigned char w=200; w>0; w--)
    // [305] if(main::w1#2>0) goto main::@64 -- vbum1_gt_0_then_la1 
    lda w1
    bne __b64
    // [306] phi from main::@63 to main::@65 [phi:main::@63->main::@65]
    // main::@65
    // system_reset()
    // [307] call system_reset
    // [1226] phi from main::@65 to system_reset [phi:main::@65->system_reset]
    jsr system_reset
    // main::@return
    // }
    // [308] return 
    rts
    // [309] phi from main::@63 to main::@64 [phi:main::@63->main::@64]
    // main::@64
  __b64:
    // wait_moment()
    // [310] call wait_moment
    // [1231] phi from main::@64 to wait_moment [phi:main::@64->wait_moment]
    jsr wait_moment
    // [311] phi from main::@64 to main::@214 [phi:main::@64->main::@214]
    // main::@214
    // sprintf(info_text, "(%u) Your CX16 will reset ...", w)
    // [312] call snprintf_init
    // [1151] phi from main::@214 to snprintf_init [phi:main::@214->snprintf_init]
    // [1151] phi snprintf_init::s#26 = info_text [phi:main::@214->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [313] phi from main::@214 to main::@215 [phi:main::@214->main::@215]
    // main::@215
    // sprintf(info_text, "(%u) Your CX16 will reset ...", w)
    // [314] call printf_str
    // [1156] phi from main::@215 to printf_str [phi:main::@215->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:main::@215->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = main::s15 [phi:main::@215->printf_str#1] -- pbuz1=pbuc1 
    lda #<s15
    sta.z printf_str.s
    lda #>s15
    sta.z printf_str.s+1
    jsr printf_str
    // main::@216
    // sprintf(info_text, "(%u) Your CX16 will reset ...", w)
    // [315] printf_uchar::uvalue#13 = main::w1#2 -- vbuz1=vbum2 
    lda w1
    sta.z printf_uchar.uvalue
    // [316] call printf_uchar
    // [1236] phi from main::@216 to printf_uchar [phi:main::@216->printf_uchar]
    // [1236] phi printf_uchar::format_zero_padding#14 = 0 [phi:main::@216->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1236] phi printf_uchar::format_min_length#14 = 0 [phi:main::@216->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1236] phi printf_uchar::putc#14 = &snputc [phi:main::@216->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1236] phi printf_uchar::format_radix#14 = DECIMAL [phi:main::@216->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1236] phi printf_uchar::uvalue#14 = printf_uchar::uvalue#13 [phi:main::@216->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [317] phi from main::@216 to main::@217 [phi:main::@216->main::@217]
    // main::@217
    // sprintf(info_text, "(%u) Your CX16 will reset ...", w)
    // [318] call printf_str
    // [1156] phi from main::@217 to printf_str [phi:main::@217->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:main::@217->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = main::s19 [phi:main::@217->printf_str#1] -- pbuz1=pbuc1 
    lda #<s19
    sta.z printf_str.s
    lda #>s19
    sta.z printf_str.s+1
    jsr printf_str
    // main::@218
    // sprintf(info_text, "(%u) Your CX16 will reset ...", w)
    // [319] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [320] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [322] call display_action_text
    // [1247] phi from main::@218 to display_action_text [phi:main::@218->display_action_text]
    // [1247] phi display_action_text::info_text#19 = info_text [phi:main::@218->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@219
    // for (unsigned char w=200; w>0; w--)
    // [323] main::w1#1 = -- main::w1#2 -- vbum1=_dec_vbum1 
    dec w1
    // [304] phi from main::@219 to main::@63 [phi:main::@219->main::@63]
    // [304] phi main::w1#2 = main::w1#1 [phi:main::@219->main::@63#0] -- register_copy 
    jmp __b63
    // [324] phi from main::@90 to main::@58 [phi:main::@90->main::@58]
    // main::@58
  __b58:
    // display_progress_text(display_debriefing_text_smc, display_debriefing_count_smc)
    // [325] call display_progress_text
    // [1059] phi from main::@58 to display_progress_text [phi:main::@58->display_progress_text]
    // [1059] phi display_progress_text::text#12 = display_debriefing_text_smc [phi:main::@58->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_debriefing_text_smc
    sta.z display_progress_text.text
    lda #>display_debriefing_text_smc
    sta.z display_progress_text.text+1
    // [1059] phi display_progress_text::lines#11 = display_debriefing_count_smc [phi:main::@58->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_debriefing_count_smc
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [326] phi from main::@58 to main::@59 [phi:main::@58->main::@59]
    // [326] phi main::w#2 = $f0 [phi:main::@58->main::@59#0] -- vbum1=vbuc1 
    lda #$f0
    sta w
    // main::@59
  __b59:
    // for (unsigned char w=240; w>0; w--)
    // [327] if(main::w#2>0) goto main::@60 -- vbum1_gt_0_then_la1 
    lda w
    bne __b60
    // [328] phi from main::@59 to main::@61 [phi:main::@59->main::@61]
    // main::@61
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [329] call snprintf_init
    // [1151] phi from main::@61 to snprintf_init [phi:main::@61->snprintf_init]
    // [1151] phi snprintf_init::s#26 = info_text [phi:main::@61->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [330] phi from main::@61 to main::@211 [phi:main::@61->main::@211]
    // main::@211
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [331] call printf_str
    // [1156] phi from main::@211 to printf_str [phi:main::@211->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:main::@211->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = main::s17 [phi:main::@211->printf_str#1] -- pbuz1=pbuc1 
    lda #<s17
    sta.z printf_str.s
    lda #>s17
    sta.z printf_str.s+1
    jsr printf_str
    // main::@212
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [332] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [333] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [335] call display_action_text
    // [1247] phi from main::@212 to display_action_text [phi:main::@212->display_action_text]
    // [1247] phi display_action_text::info_text#19 = info_text [phi:main::@212->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [336] phi from main::@212 to main::@213 [phi:main::@212->main::@213]
    // main::@213
    // smc_reset()
    // [337] call smc_reset
  // DE-5 | The components correctly updated, SMC bootloader 2
  // When bootloader 1, the CX16 won't shut down automatically and will hang! The user will see the above bootloader 1 action.
  // When bootloader 2, the CX16 will shut down automatically. The user will never see the bootloader 1 action.
    // [1261] phi from main::@213 to smc_reset [phi:main::@213->smc_reset]
    jsr smc_reset
    jmp __b9
    // [338] phi from main::@59 to main::@60 [phi:main::@59->main::@60]
    // main::@60
  __b60:
    // wait_moment()
    // [339] call wait_moment
    // [1231] phi from main::@60 to wait_moment [phi:main::@60->wait_moment]
    jsr wait_moment
    // [340] phi from main::@60 to main::@205 [phi:main::@60->main::@205]
    // main::@205
    // sprintf(info_text, "(%u) Please read carefully the below ...", w)
    // [341] call snprintf_init
    // [1151] phi from main::@205 to snprintf_init [phi:main::@205->snprintf_init]
    // [1151] phi snprintf_init::s#26 = info_text [phi:main::@205->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [342] phi from main::@205 to main::@206 [phi:main::@205->main::@206]
    // main::@206
    // sprintf(info_text, "(%u) Please read carefully the below ...", w)
    // [343] call printf_str
    // [1156] phi from main::@206 to printf_str [phi:main::@206->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:main::@206->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = main::s15 [phi:main::@206->printf_str#1] -- pbuz1=pbuc1 
    lda #<s15
    sta.z printf_str.s
    lda #>s15
    sta.z printf_str.s+1
    jsr printf_str
    // main::@207
    // sprintf(info_text, "(%u) Please read carefully the below ...", w)
    // [344] printf_uchar::uvalue#12 = main::w#2 -- vbuz1=vbum2 
    lda w
    sta.z printf_uchar.uvalue
    // [345] call printf_uchar
    // [1236] phi from main::@207 to printf_uchar [phi:main::@207->printf_uchar]
    // [1236] phi printf_uchar::format_zero_padding#14 = 0 [phi:main::@207->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1236] phi printf_uchar::format_min_length#14 = 0 [phi:main::@207->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1236] phi printf_uchar::putc#14 = &snputc [phi:main::@207->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1236] phi printf_uchar::format_radix#14 = DECIMAL [phi:main::@207->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1236] phi printf_uchar::uvalue#14 = printf_uchar::uvalue#12 [phi:main::@207->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [346] phi from main::@207 to main::@208 [phi:main::@207->main::@208]
    // main::@208
    // sprintf(info_text, "(%u) Please read carefully the below ...", w)
    // [347] call printf_str
    // [1156] phi from main::@208 to printf_str [phi:main::@208->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:main::@208->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = main::s16 [phi:main::@208->printf_str#1] -- pbuz1=pbuc1 
    lda #<s16
    sta.z printf_str.s
    lda #>s16
    sta.z printf_str.s+1
    jsr printf_str
    // main::@209
    // sprintf(info_text, "(%u) Please read carefully the below ...", w)
    // [348] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [349] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [351] call display_action_text
    // [1247] phi from main::@209 to display_action_text [phi:main::@209->display_action_text]
    // [1247] phi display_action_text::info_text#19 = info_text [phi:main::@209->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@210
    // for (unsigned char w=240; w>0; w--)
    // [352] main::w#1 = -- main::w#2 -- vbum1=_dec_vbum1 
    dec w
    // [326] phi from main::@210 to main::@59 [phi:main::@210->main::@59]
    // [326] phi main::w#2 = main::w#1 [phi:main::@210->main::@59#0] -- register_copy 
    jmp __b59
    // main::vera_display_set_border_color3
  vera_display_set_border_color3:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [353] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [354] *VERA_DC_BORDER = YELLOW -- _deref_pbuc1=vbuc2 
    lda #YELLOW
    sta VERA_DC_BORDER
    // [355] phi from main::vera_display_set_border_color3 to main::@88 [phi:main::vera_display_set_border_color3->main::@88]
    // main::@88
    // display_action_progress("Update issues, your CX16 is not updated!")
    // [356] call display_action_progress
    // [850] phi from main::@88 to display_action_progress [phi:main::@88->display_action_progress]
    // [850] phi display_action_progress::info_text#18 = main::info_text36 [phi:main::@88->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text36
    sta.z display_action_progress.info_text
    lda #>info_text36
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    jmp __b9
    // main::check_status_roms4_check_status_rom1
  check_status_roms4_check_status_rom1:
    // status_rom[rom_chip] == status
    // [357] main::check_status_roms4_check_status_rom1_$0 = status_rom[main::check_status_roms4_rom_chip#2] == STATUS_ISSUE -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_ISSUE
    ldy check_status_roms4_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_roms4_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [358] main::check_status_roms4_check_status_rom1_return#0 = (char)main::check_status_roms4_check_status_rom1_$0
    // main::check_status_roms4_@11
    // if(check_status_rom(rom_chip, status))
    // [359] if(0==main::check_status_roms4_check_status_rom1_return#0) goto main::check_status_roms4_@4 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_roms4_check_status_rom1_return
    beq check_status_roms4___b4
    // [291] phi from main::check_status_roms4_@11 to main::check_status_roms4_@return [phi:main::check_status_roms4_@11->main::check_status_roms4_@return]
    // [291] phi main::check_status_roms4_return#2 = 1 [phi:main::check_status_roms4_@11->main::check_status_roms4_@return#0] -- vbum1=vbuc1 
    lda #1
    sta check_status_roms4_return
    jmp __b87
    // main::check_status_roms4_@4
  check_status_roms4___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [360] main::check_status_roms4_rom_chip#1 = ++ main::check_status_roms4_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_status_roms4_rom_chip
    // [289] phi from main::check_status_roms4_@4 to main::check_status_roms4_@1 [phi:main::check_status_roms4_@4->main::check_status_roms4_@1]
    // [289] phi main::check_status_roms4_rom_chip#2 = main::check_status_roms4_rom_chip#1 [phi:main::check_status_roms4_@4->main::check_status_roms4_@1#0] -- register_copy 
    jmp check_status_roms4___b1
    // main::vera_display_set_border_color2
  vera_display_set_border_color2:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [361] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [362] *VERA_DC_BORDER = RED -- _deref_pbuc1=vbuc2 
    lda #RED
    sta VERA_DC_BORDER
    // [363] phi from main::vera_display_set_border_color2 to main::@86 [phi:main::vera_display_set_border_color2->main::@86]
    // main::@86
    // display_action_progress("Update Failure! Your CX16 may be bricked!")
    // [364] call display_action_progress
    // [850] phi from main::@86 to display_action_progress [phi:main::@86->display_action_progress]
    // [850] phi display_action_progress::info_text#18 = main::info_text34 [phi:main::@86->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text34
    sta.z display_action_progress.info_text
    lda #>info_text34
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [365] phi from main::@86 to main::@204 [phi:main::@86->main::@204]
    // main::@204
    // display_action_text("Take a foto of this screen. And shut down power ...")
    // [366] call display_action_text
    // [1247] phi from main::@204 to display_action_text [phi:main::@204->display_action_text]
    // [1247] phi display_action_text::info_text#19 = main::info_text35 [phi:main::@204->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text35
    sta.z display_action_text.info_text
    lda #>info_text35
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [367] phi from main::@204 main::@62 to main::@62 [phi:main::@204/main::@62->main::@62]
    // main::@62
  __b62:
    jmp __b62
    // main::check_status_roms3_check_status_rom1
  check_status_roms3_check_status_rom1:
    // status_rom[rom_chip] == status
    // [368] main::check_status_roms3_check_status_rom1_$0 = status_rom[main::check_status_roms3_rom_chip#2] == STATUS_ERROR -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_ERROR
    ldy check_status_roms3_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_roms3_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [369] main::check_status_roms3_check_status_rom1_return#0 = (char)main::check_status_roms3_check_status_rom1_$0
    // main::check_status_roms3_@11
    // if(check_status_rom(rom_chip, status))
    // [370] if(0==main::check_status_roms3_check_status_rom1_return#0) goto main::check_status_roms3_@4 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_roms3_check_status_rom1_return
    beq check_status_roms3___b4
    // [280] phi from main::check_status_roms3_@11 to main::check_status_roms3_@return [phi:main::check_status_roms3_@11->main::check_status_roms3_@return]
    // [280] phi main::check_status_roms3_return#2 = 1 [phi:main::check_status_roms3_@11->main::check_status_roms3_@return#0] -- vbum1=vbuc1 
    lda #1
    sta check_status_roms3_return
    jmp __b85
    // main::check_status_roms3_@4
  check_status_roms3___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [371] main::check_status_roms3_rom_chip#1 = ++ main::check_status_roms3_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_status_roms3_rom_chip
    // [278] phi from main::check_status_roms3_@4 to main::check_status_roms3_@1 [phi:main::check_status_roms3_@4->main::check_status_roms3_@1]
    // [278] phi main::check_status_roms3_rom_chip#2 = main::check_status_roms3_rom_chip#1 [phi:main::check_status_roms3_@4->main::check_status_roms3_@1#0] -- register_copy 
    jmp check_status_roms3___b1
    // main::vera_display_set_border_color1
  vera_display_set_border_color1:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [372] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [373] *VERA_DC_BORDER = BLACK -- _deref_pbuc1=vbuc2 
    lda #BLACK
    sta VERA_DC_BORDER
    // [374] phi from main::vera_display_set_border_color1 to main::@84 [phi:main::vera_display_set_border_color1->main::@84]
    // main::@84
    // display_action_progress("The update has been cancelled!")
    // [375] call display_action_progress
    // [850] phi from main::@84 to display_action_progress [phi:main::@84->display_action_progress]
    // [850] phi display_action_progress::info_text#18 = main::info_text33 [phi:main::@84->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text33
    sta.z display_action_progress.info_text
    lda #>info_text33
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    jmp __b9
    // main::check_status_roms_all1_check_status_rom1
  check_status_roms_all1_check_status_rom1:
    // status_rom[rom_chip] == status
    // [376] main::check_status_roms_all1_check_status_rom1_$0 = status_rom[main::check_status_roms_all1_rom_chip#2] == STATUS_SKIP -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_SKIP
    ldy check_status_roms_all1_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_roms_all1_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [377] main::check_status_roms_all1_check_status_rom1_return#0 = (char)main::check_status_roms_all1_check_status_rom1_$0
    // main::check_status_roms_all1_@11
    // if(check_status_rom(rom_chip, status) != status)
    // [378] if(main::check_status_roms_all1_check_status_rom1_return#0==STATUS_SKIP) goto main::check_status_roms_all1_@4 -- vbuz1_eq_vbuc1_then_la1 
    lda #STATUS_SKIP
    cmp.z check_status_roms_all1_check_status_rom1_return
    beq check_status_roms_all1___b4
    // [269] phi from main::check_status_roms_all1_@11 to main::check_status_roms_all1_@return [phi:main::check_status_roms_all1_@11->main::check_status_roms_all1_@return]
    // [269] phi main::check_status_roms_all1_return#2 = 0 [phi:main::check_status_roms_all1_@11->main::check_status_roms_all1_@return#0] -- vbum1=vbuc1 
    lda #0
    sta check_status_roms_all1_return
    jmp __b78
    // main::check_status_roms_all1_@4
  check_status_roms_all1___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [379] main::check_status_roms_all1_rom_chip#1 = ++ main::check_status_roms_all1_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_status_roms_all1_rom_chip
    // [267] phi from main::check_status_roms_all1_@4 to main::check_status_roms_all1_@1 [phi:main::check_status_roms_all1_@4->main::check_status_roms_all1_@1]
    // [267] phi main::check_status_roms_all1_rom_chip#2 = main::check_status_roms_all1_rom_chip#1 [phi:main::check_status_roms_all1_@4->main::check_status_roms_all1_@1#0] -- register_copy 
    jmp check_status_roms_all1___b1
    // main::@228
  __b228:
    // if(!check_status_smc(STATUS_ISSUE) && !check_status_vera(STATUS_ISSUE) && !check_status_roms(STATUS_ISSUE) &&
    //        !check_status_smc(STATUS_ERROR) && !check_status_vera(STATUS_ERROR) && !check_status_roms(STATUS_ERROR))
    // [380] if(0!=main::check_status_roms1_return#2) goto main::check_status_smc7 -- 0_neq_vbum1_then_la1 
    lda check_status_roms1_return
    beq !check_status_smc7+
    jmp check_status_smc7
  !check_status_smc7:
    // main::@227
    // [381] if(0==main::check_status_smc6_return#0) goto main::@226 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_smc6_return
    beq __b226
    jmp check_status_smc7
    // main::@226
  __b226:
    // [382] if(0!=main::check_status_vera2_return#0) goto main::check_status_smc7 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_vera2_return
    beq !check_status_smc7+
    jmp check_status_smc7
  !check_status_smc7:
    // main::@225
    // [383] if(0==main::check_status_roms2_return#2) goto main::check_status_smc8 -- 0_eq_vbum1_then_la1 
    lda check_status_roms2_return
    beq check_status_smc8
    jmp check_status_smc7
    // main::check_status_smc8
  check_status_smc8:
    // status_smc == status
    // [384] main::check_status_smc8_$0 = status_smc#0 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc8_main__0
    // return (unsigned char)(status_smc == status);
    // [385] main::check_status_smc8_return#0 = (char)main::check_status_smc8_$0
    // [386] phi from main::check_status_smc8 to main::check_status_cx16_rom4 [phi:main::check_status_smc8->main::check_status_cx16_rom4]
    // main::check_status_cx16_rom4
    // main::check_status_cx16_rom4_check_status_rom1
    // status_rom[rom_chip] == status
    // [387] main::check_status_cx16_rom4_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_cx16_rom4_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [388] main::check_status_cx16_rom4_check_status_rom1_return#0 = (char)main::check_status_cx16_rom4_check_status_rom1_$0
    // [389] phi from main::check_status_cx16_rom4_check_status_rom1 to main::check_status_card_roms1 [phi:main::check_status_cx16_rom4_check_status_rom1->main::check_status_card_roms1]
    // main::check_status_card_roms1
    // [390] phi from main::check_status_card_roms1 to main::check_status_card_roms1_@1 [phi:main::check_status_card_roms1->main::check_status_card_roms1_@1]
    // [390] phi main::check_status_card_roms1_rom_chip#2 = 1 [phi:main::check_status_card_roms1->main::check_status_card_roms1_@1#0] -- vbum1=vbuc1 
    lda #1
    sta check_status_card_roms1_rom_chip
    // main::check_status_card_roms1_@1
  check_status_card_roms1___b1:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [391] if(main::check_status_card_roms1_rom_chip#2<8) goto main::check_status_card_roms1_check_status_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda check_status_card_roms1_rom_chip
    cmp #8
    bcs !check_status_card_roms1_check_status_rom1+
    jmp check_status_card_roms1_check_status_rom1
  !check_status_card_roms1_check_status_rom1:
    // [392] phi from main::check_status_card_roms1_@1 to main::check_status_card_roms1_@return [phi:main::check_status_card_roms1_@1->main::check_status_card_roms1_@return]
    // [392] phi main::check_status_card_roms1_return#2 = 0 [phi:main::check_status_card_roms1_@1->main::check_status_card_roms1_@return#0] -- vbum1=vbuc1 
    lda #0
    sta check_status_card_roms1_return
    // main::check_status_card_roms1_@return
    // main::@79
  __b79:
    // if(check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH) || check_status_card_roms(STATUS_FLASH))
    // [393] if(0==main::check_status_smc8_return#0) goto main::@232 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_smc8_return
    beq __b232
    // main::@233
    // [394] if(0!=main::check_status_cx16_rom4_check_status_rom1_return#0) goto main::@10 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_cx16_rom4_check_status_rom1_return
    beq !__b10+
    jmp __b10
  !__b10:
    // main::@232
  __b232:
    // [395] if(0!=main::check_status_card_roms1_return#2) goto main::@10 -- 0_neq_vbum1_then_la1 
    lda check_status_card_roms1_return
    beq !__b10+
    jmp __b10
  !__b10:
    // main::bank_set_bram2
  bank_set_bram2:
    // BRAM = bank
    // [396] BRAM = main::bank_set_bram2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram2_bank
    sta.z BRAM
    // main::SEI5
    // asm
    // asm { sei  }
    sei
    // main::check_status_smc9
    // status_smc == status
    // [398] main::check_status_smc9_$0 = status_smc#0 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc9_main__0
    // return (unsigned char)(status_smc == status);
    // [399] main::check_status_smc9_return#0 = (char)main::check_status_smc9_$0
    // [400] phi from main::check_status_smc9 to main::check_status_cx16_rom5 [phi:main::check_status_smc9->main::check_status_cx16_rom5]
    // main::check_status_cx16_rom5
    // main::check_status_cx16_rom5_check_status_rom1
    // status_rom[rom_chip] == status
    // [401] main::check_status_cx16_rom5_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_cx16_rom5_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [402] main::check_status_cx16_rom5_check_status_rom1_return#0 = (char)main::check_status_cx16_rom5_check_status_rom1_$0
    // main::@80
    // if (check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH))
    // [403] if(0==main::check_status_smc9_return#0) goto main::@43 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_smc9_return
    beq __b43
    // main::@234
    // [404] if(0!=main::check_status_cx16_rom5_check_status_rom1_return#0) goto main::@54 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_cx16_rom5_check_status_rom1_return
    beq !__b54+
    jmp __b54
  !__b54:
    // [405] phi from main::@234 to main::@43 [phi:main::@234->main::@43]
    // [405] phi from main::@181 main::@44 main::@45 main::@57 main::@80 to main::@43 [phi:main::@181/main::@44/main::@45/main::@57/main::@80->main::@43]
    // [405] phi __errno#387 = __errno#18 [phi:main::@181/main::@44/main::@45/main::@57/main::@80->main::@43#0] -- register_copy 
    // main::@43
  __b43:
    // [406] phi from main::@43 to main::@46 [phi:main::@43->main::@46]
    // [406] phi __errno#116 = __errno#387 [phi:main::@43->main::@46#0] -- register_copy 
    // [406] phi main::rom_chip4#10 = 7 [phi:main::@43->main::@46#1] -- vbum1=vbuc1 
    lda #7
    sta rom_chip4
  // Flash the ROM chips. 
  // We loop first all the ROM chips and read the file contents.
  // Then we verify the file contents and flash the ROM only for the differences.
  // If the file contents are the same as the ROM contents, then no flashing is required.
  // IMPORTANT! We start to flash the ROMs on the extension card.
  // The last ROM flashed is the CX16 ROM on the CX16 board!
    // main::@46
  __b46:
    // for(unsigned char rom_chip = 7; rom_chip != 255; rom_chip--)
    // [407] if(main::rom_chip4#10!=$ff) goto main::check_status_rom1 -- vbum1_neq_vbuc1_then_la1 
    lda #$ff
    cmp rom_chip4
    bne check_status_rom1
    jmp check_status_smc7
    // main::check_status_rom1
  check_status_rom1:
    // status_rom[rom_chip] == status
    // [408] main::check_status_rom1_$0 = status_rom[main::rom_chip4#10] == STATUS_FLASH -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_FLASH
    ldy rom_chip4
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [409] main::check_status_rom1_return#0 = (char)main::check_status_rom1_$0
    // main::@81
    // if(check_status_rom(rom_chip, STATUS_FLASH))
    // [410] if(0==main::check_status_rom1_return#0) goto main::@47 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_rom1_return
    beq __b47
    // main::check_status_smc10
    // status_smc == status
    // [411] main::check_status_smc10_$0 = status_smc#0 == STATUS_FLASHED -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASHED
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc10_main__0
    // return (unsigned char)(status_smc == status);
    // [412] main::check_status_smc10_return#0 = (char)main::check_status_smc10_$0
    // main::@82
    // if((rom_chip == 0 && check_status_smc(STATUS_FLASHED)) || (rom_chip != 0))
    // [413] if(main::rom_chip4#10!=0) goto main::@235 -- vbum1_neq_0_then_la1 
    // IMPORTANT! We only flash the CX16 ROM chip if the SMC got flashed succesfully!
    lda rom_chip4
    bne __b235
    // main::@236
    // [414] if(0!=main::check_status_smc10_return#0) goto main::bank_set_brom7 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc10_return
    bne bank_set_brom7
    // main::@235
  __b235:
    // [415] if(main::rom_chip4#10!=0) goto main::bank_set_brom7 -- vbum1_neq_0_then_la1 
    lda rom_chip4
    bne bank_set_brom7
    // main::@53
    // display_info_rom(rom_chip, STATUS_ISSUE, "Update SMC failed!")
    // [416] display_info_rom::rom_chip#10 = main::rom_chip4#10 -- vbuz1=vbum2 
    sta.z display_info_rom.rom_chip
    // [417] call display_info_rom
    // [1270] phi from main::@53 to display_info_rom [phi:main::@53->display_info_rom]
    // [1270] phi display_info_rom::info_text#16 = main::info_text28 [phi:main::@53->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text28
    sta.z display_info_rom.info_text
    lda #>info_text28
    sta.z display_info_rom.info_text+1
    // [1270] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#10 [phi:main::@53->display_info_rom#1] -- register_copy 
    // [1270] phi display_info_rom::info_status#16 = STATUS_ISSUE [phi:main::@53->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_rom.info_status
    jsr display_info_rom
    // [418] phi from main::@192 main::@203 main::@48 main::@52 main::@53 main::@81 to main::@47 [phi:main::@192/main::@203/main::@48/main::@52/main::@53/main::@81->main::@47]
    // [418] phi __errno#388 = __errno#18 [phi:main::@192/main::@203/main::@48/main::@52/main::@53/main::@81->main::@47#0] -- register_copy 
    // main::@47
  __b47:
    // for(unsigned char rom_chip = 7; rom_chip != 255; rom_chip--)
    // [419] main::rom_chip4#1 = -- main::rom_chip4#10 -- vbum1=_dec_vbum1 
    dec rom_chip4
    // [406] phi from main::@47 to main::@46 [phi:main::@47->main::@46]
    // [406] phi __errno#116 = __errno#388 [phi:main::@47->main::@46#0] -- register_copy 
    // [406] phi main::rom_chip4#10 = main::rom_chip4#1 [phi:main::@47->main::@46#1] -- register_copy 
    jmp __b46
    // main::bank_set_brom7
  bank_set_brom7:
    // BROM = bank
    // [420] BROM = main::bank_set_brom7_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom7_bank
    sta.z BROM
    // [421] phi from main::bank_set_brom7 to main::@83 [phi:main::bank_set_brom7->main::@83]
    // main::@83
    // display_progress_clear()
    // [422] call display_progress_clear
    // [864] phi from main::@83 to display_progress_clear [phi:main::@83->display_progress_clear]
    jsr display_progress_clear
    // main::@185
    // unsigned char rom_bank = rom_chip * 32
    // [423] main::rom_bank1#0 = main::rom_chip4#10 << 5 -- vbum1=vbum2_rol_5 
    lda rom_chip4
    asl
    asl
    asl
    asl
    asl
    sta rom_bank1
    // unsigned char* file = rom_file(rom_chip)
    // [424] rom_file::rom_chip#1 = main::rom_chip4#10 -- vbum1=vbum2 
    lda rom_chip4
    sta rom_file.rom_chip
    // [425] call rom_file
    // [1313] phi from main::@185 to rom_file [phi:main::@185->rom_file]
    // [1313] phi rom_file::rom_chip#2 = rom_file::rom_chip#1 [phi:main::@185->rom_file#0] -- register_copy 
    jsr rom_file
    // unsigned char* file = rom_file(rom_chip)
    // [426] rom_file::return#5 = rom_file::return#2
    // main::@186
    // [427] main::file1#0 = rom_file::return#5
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [428] call snprintf_init
    // [1151] phi from main::@186 to snprintf_init [phi:main::@186->snprintf_init]
    // [1151] phi snprintf_init::s#26 = info_text [phi:main::@186->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [429] phi from main::@186 to main::@187 [phi:main::@186->main::@187]
    // main::@187
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [430] call printf_str
    // [1156] phi from main::@187 to printf_str [phi:main::@187->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:main::@187->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = s11 [phi:main::@187->printf_str#1] -- pbuz1=pbuc1 
    lda #<s11
    sta.z printf_str.s
    lda #>s11
    sta.z printf_str.s+1
    jsr printf_str
    // main::@188
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [431] printf_string::str#21 = main::file1#0 -- pbuz1=pbum2 
    lda file1
    sta.z printf_string.str
    lda file1+1
    sta.z printf_string.str+1
    // [432] call printf_string
    // [1165] phi from main::@188 to printf_string [phi:main::@188->printf_string]
    // [1165] phi printf_string::putc#22 = &snputc [phi:main::@188->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1165] phi printf_string::str#22 = printf_string::str#21 [phi:main::@188->printf_string#1] -- register_copy 
    // [1165] phi printf_string::format_justify_left#22 = 0 [phi:main::@188->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1165] phi printf_string::format_min_length#22 = 0 [phi:main::@188->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [433] phi from main::@188 to main::@189 [phi:main::@188->main::@189]
    // main::@189
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [434] call printf_str
    // [1156] phi from main::@189 to printf_str [phi:main::@189->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:main::@189->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = main::s6 [phi:main::@189->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // main::@190
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [435] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [436] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_progress(info_text)
    // [438] call display_action_progress
    // [850] phi from main::@190 to display_action_progress [phi:main::@190->display_action_progress]
    // [850] phi display_action_progress::info_text#18 = info_text [phi:main::@190->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_progress.info_text
    lda #>@info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@191
    // unsigned long rom_bytes_read = rom_read(1, rom_chip, file, STATUS_READING, rom_bank, rom_sizes[rom_chip])
    // [439] main::$274 = main::rom_chip4#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip4
    asl
    asl
    sta main__274
    // [440] rom_read::file#1 = main::file1#0 -- pbum1=pbum2 
    lda file1
    sta rom_read.file
    lda file1+1
    sta rom_read.file+1
    // [441] rom_read::brom_bank_start#2 = main::rom_bank1#0 -- vbuz1=vbum2 
    lda rom_bank1
    sta.z rom_read.brom_bank_start
    // [442] rom_read::rom_size#1 = rom_sizes[main::$274] -- vduz1=pduc1_derefidx_vbum2 
    ldy main__274
    lda rom_sizes,y
    sta.z rom_read.rom_size
    lda rom_sizes+1,y
    sta.z rom_read.rom_size+1
    lda rom_sizes+2,y
    sta.z rom_read.rom_size+2
    lda rom_sizes+3,y
    sta.z rom_read.rom_size+3
    // [443] call rom_read
    // [1319] phi from main::@191 to rom_read [phi:main::@191->rom_read]
    // [1319] phi rom_read::display_progress#28 = 1 [phi:main::@191->rom_read#0] -- vbum1=vbuc1 
    lda #1
    sta rom_read.display_progress
    // [1319] phi rom_read::rom_size#12 = rom_read::rom_size#1 [phi:main::@191->rom_read#1] -- register_copy 
    // [1319] phi __errno#108 = __errno#116 [phi:main::@191->rom_read#2] -- register_copy 
    // [1319] phi rom_read::file#11 = rom_read::file#1 [phi:main::@191->rom_read#3] -- register_copy 
    // [1319] phi rom_read::brom_bank_start#22 = rom_read::brom_bank_start#2 [phi:main::@191->rom_read#4] -- register_copy 
    jsr rom_read
    // unsigned long rom_bytes_read = rom_read(1, rom_chip, file, STATUS_READING, rom_bank, rom_sizes[rom_chip])
    // [444] rom_read::return#3 = rom_read::return#0
    // main::@192
    // [445] main::rom_bytes_read1#0 = rom_read::return#3
    // if(rom_bytes_read)
    // [446] if(0==main::rom_bytes_read1#0) goto main::@47 -- 0_eq_vdum1_then_la1 
    lda rom_bytes_read1
    ora rom_bytes_read1+1
    ora rom_bytes_read1+2
    ora rom_bytes_read1+3
    bne !__b47+
    jmp __b47
  !__b47:
    // [447] phi from main::@192 to main::@50 [phi:main::@192->main::@50]
    // main::@50
    // display_action_progress("Comparing ... (.) same, (*) different.")
    // [448] call display_action_progress
  // Now we compare the RAM with the actual ROM contents.
    // [850] phi from main::@50 to display_action_progress [phi:main::@50->display_action_progress]
    // [850] phi display_action_progress::info_text#18 = main::info_text29 [phi:main::@50->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text29
    sta.z display_action_progress.info_text
    lda #>info_text29
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@193
    // display_info_rom(rom_chip, STATUS_COMPARING, "")
    // [449] display_info_rom::rom_chip#11 = main::rom_chip4#10 -- vbuz1=vbum2 
    lda rom_chip4
    sta.z display_info_rom.rom_chip
    // [450] call display_info_rom
    // [1270] phi from main::@193 to display_info_rom [phi:main::@193->display_info_rom]
    // [1270] phi display_info_rom::info_text#16 = info_text4 [phi:main::@193->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z display_info_rom.info_text
    lda #>info_text4
    sta.z display_info_rom.info_text+1
    // [1270] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#11 [phi:main::@193->display_info_rom#1] -- register_copy 
    // [1270] phi display_info_rom::info_status#16 = STATUS_COMPARING [phi:main::@193->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_COMPARING
    sta display_info_rom.info_status
    jsr display_info_rom
    // main::@194
    // unsigned long rom_differences = rom_verify(
    //                             rom_chip, rom_bank, file_sizes[rom_chip])
    // [451] rom_verify::rom_chip#0 = main::rom_chip4#10 -- vbuz1=vbum2 
    lda rom_chip4
    sta.z rom_verify.rom_chip
    // [452] rom_verify::rom_bank_start#0 = main::rom_bank1#0 -- vbum1=vbum2 
    lda rom_bank1
    sta rom_verify.rom_bank_start
    // [453] rom_verify::file_size#0 = file_sizes[main::$274] -- vdum1=pduc1_derefidx_vbum2 
    ldy main__274
    lda file_sizes,y
    sta rom_verify.file_size
    lda file_sizes+1,y
    sta rom_verify.file_size+1
    lda file_sizes+2,y
    sta rom_verify.file_size+2
    lda file_sizes+3,y
    sta rom_verify.file_size+3
    // [454] call rom_verify
    // Verify the ROM...
    jsr rom_verify
    // [455] rom_verify::return#2 = rom_verify::rom_different_bytes#11
    // main::@195
    // [456] main::rom_differences#0 = rom_verify::return#2 -- vduz1=vduz2 
    lda.z rom_verify.return
    sta.z rom_differences
    lda.z rom_verify.return+1
    sta.z rom_differences+1
    lda.z rom_verify.return+2
    sta.z rom_differences+2
    lda.z rom_verify.return+3
    sta.z rom_differences+3
    // if (!rom_differences)
    // [457] if(0==main::rom_differences#0) goto main::@48 -- 0_eq_vduz1_then_la1 
    lda.z rom_differences
    ora.z rom_differences+1
    ora.z rom_differences+2
    ora.z rom_differences+3
    bne !__b48+
    jmp __b48
  !__b48:
    // [458] phi from main::@195 to main::@51 [phi:main::@195->main::@51]
    // main::@51
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [459] call snprintf_init
    // [1151] phi from main::@51 to snprintf_init [phi:main::@51->snprintf_init]
    // [1151] phi snprintf_init::s#26 = info_text [phi:main::@51->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main::@196
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [460] printf_ulong::uvalue#7 = main::rom_differences#0
    // [461] call printf_ulong
    // [1470] phi from main::@196 to printf_ulong [phi:main::@196->printf_ulong]
    // [1470] phi printf_ulong::format_zero_padding#10 = 1 [phi:main::@196->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1470] phi printf_ulong::format_min_length#10 = 5 [phi:main::@196->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1470] phi printf_ulong::format_radix#10 = HEXADECIMAL [phi:main::@196->printf_ulong#2] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1470] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#7 [phi:main::@196->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [462] phi from main::@196 to main::@197 [phi:main::@196->main::@197]
    // main::@197
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [463] call printf_str
    // [1156] phi from main::@197 to printf_str [phi:main::@197->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:main::@197->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = main::s13 [phi:main::@197->printf_str#1] -- pbuz1=pbuc1 
    lda #<s13
    sta.z printf_str.s
    lda #>s13
    sta.z printf_str.s+1
    jsr printf_str
    // main::@198
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [464] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [465] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_FLASH, info_text)
    // [467] display_info_rom::rom_chip#13 = main::rom_chip4#10 -- vbuz1=vbum2 
    lda rom_chip4
    sta.z display_info_rom.rom_chip
    // [468] call display_info_rom
    // [1270] phi from main::@198 to display_info_rom [phi:main::@198->display_info_rom]
    // [1270] phi display_info_rom::info_text#16 = info_text [phi:main::@198->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1270] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#13 [phi:main::@198->display_info_rom#1] -- register_copy 
    // [1270] phi display_info_rom::info_status#16 = STATUS_FLASH [phi:main::@198->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta display_info_rom.info_status
    jsr display_info_rom
    // main::@199
    // unsigned long rom_flash_errors = rom_flash(
    //                                 rom_chip, rom_bank, file_sizes[rom_chip])
    // [469] rom_flash::rom_chip#0 = main::rom_chip4#10 -- vbum1=vbum2 
    lda rom_chip4
    sta rom_flash.rom_chip
    // [470] rom_flash::rom_bank_start#0 = main::rom_bank1#0 -- vbum1=vbum2 
    lda rom_bank1
    sta rom_flash.rom_bank_start
    // [471] rom_flash::file_size#0 = file_sizes[main::$274] -- vdum1=pduc1_derefidx_vbum2 
    ldy main__274
    lda file_sizes,y
    sta rom_flash.file_size
    lda file_sizes+1,y
    sta rom_flash.file_size+1
    lda file_sizes+2,y
    sta rom_flash.file_size+2
    lda file_sizes+3,y
    sta rom_flash.file_size+3
    // [472] call rom_flash
    // [1480] phi from main::@199 to rom_flash [phi:main::@199->rom_flash]
    jsr rom_flash
    // unsigned long rom_flash_errors = rom_flash(
    //                                 rom_chip, rom_bank, file_sizes[rom_chip])
    // [473] rom_flash::return#2 = rom_flash::flash_errors#10
    // main::@200
    // [474] main::rom_flash_errors#0 = rom_flash::return#2 -- vdum1=vdum2 
    lda rom_flash.return
    sta rom_flash_errors
    lda rom_flash.return+1
    sta rom_flash_errors+1
    lda rom_flash.return+2
    sta rom_flash_errors+2
    lda rom_flash.return+3
    sta rom_flash_errors+3
    // if(rom_flash_errors)
    // [475] if(0!=main::rom_flash_errors#0) goto main::@49 -- 0_neq_vdum1_then_la1 
    lda rom_flash_errors
    ora rom_flash_errors+1
    ora rom_flash_errors+2
    ora rom_flash_errors+3
    bne __b49
    // main::@52
    // display_info_rom(rom_chip, STATUS_FLASHED, "OK!")
    // [476] display_info_rom::rom_chip#15 = main::rom_chip4#10 -- vbuz1=vbum2 
    lda rom_chip4
    sta.z display_info_rom.rom_chip
    // [477] call display_info_rom
  // RF-3 | Flash ROM and all ok
    // [1270] phi from main::@52 to display_info_rom [phi:main::@52->display_info_rom]
    // [1270] phi display_info_rom::info_text#16 = main::info_text32 [phi:main::@52->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text32
    sta.z display_info_rom.info_text
    lda #>info_text32
    sta.z display_info_rom.info_text+1
    // [1270] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#15 [phi:main::@52->display_info_rom#1] -- register_copy 
    // [1270] phi display_info_rom::info_status#16 = STATUS_FLASHED [phi:main::@52->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHED
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b47
    // [478] phi from main::@200 to main::@49 [phi:main::@200->main::@49]
    // main::@49
  __b49:
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [479] call snprintf_init
    // [1151] phi from main::@49 to snprintf_init [phi:main::@49->snprintf_init]
    // [1151] phi snprintf_init::s#26 = info_text [phi:main::@49->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main::@201
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [480] printf_ulong::uvalue#8 = main::rom_flash_errors#0 -- vduz1=vdum2 
    lda rom_flash_errors
    sta.z printf_ulong.uvalue
    lda rom_flash_errors+1
    sta.z printf_ulong.uvalue+1
    lda rom_flash_errors+2
    sta.z printf_ulong.uvalue+2
    lda rom_flash_errors+3
    sta.z printf_ulong.uvalue+3
    // [481] call printf_ulong
    // [1470] phi from main::@201 to printf_ulong [phi:main::@201->printf_ulong]
    // [1470] phi printf_ulong::format_zero_padding#10 = 0 [phi:main::@201->printf_ulong#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_ulong.format_zero_padding
    // [1470] phi printf_ulong::format_min_length#10 = 0 [phi:main::@201->printf_ulong#1] -- vbuz1=vbuc1 
    sta.z printf_ulong.format_min_length
    // [1470] phi printf_ulong::format_radix#10 = DECIMAL [phi:main::@201->printf_ulong#2] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_ulong.format_radix
    // [1470] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#8 [phi:main::@201->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [482] phi from main::@201 to main::@202 [phi:main::@201->main::@202]
    // main::@202
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [483] call printf_str
    // [1156] phi from main::@202 to printf_str [phi:main::@202->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:main::@202->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = main::s14 [phi:main::@202->printf_str#1] -- pbuz1=pbuc1 
    lda #<s14
    sta.z printf_str.s
    lda #>s14
    sta.z printf_str.s+1
    jsr printf_str
    // main::@203
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [484] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [485] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_ERROR, info_text)
    // [487] display_info_rom::rom_chip#14 = main::rom_chip4#10 -- vbuz1=vbum2 
    lda rom_chip4
    sta.z display_info_rom.rom_chip
    // [488] call display_info_rom
    // [1270] phi from main::@203 to display_info_rom [phi:main::@203->display_info_rom]
    // [1270] phi display_info_rom::info_text#16 = info_text [phi:main::@203->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1270] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#14 [phi:main::@203->display_info_rom#1] -- register_copy 
    // [1270] phi display_info_rom::info_status#16 = STATUS_ERROR [phi:main::@203->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b47
    // main::@48
  __b48:
    // display_info_rom(rom_chip, STATUS_FLASHED, "No update required")
    // [489] display_info_rom::rom_chip#12 = main::rom_chip4#10 -- vbuz1=vbum2 
    lda rom_chip4
    sta.z display_info_rom.rom_chip
    // [490] call display_info_rom
  // RF-1 | ROM and ROM.BIN equal | Display that there are no differences between the ROM and ROM.BIN. Set ROM to Flashed. | None
    // [1270] phi from main::@48 to display_info_rom [phi:main::@48->display_info_rom]
    // [1270] phi display_info_rom::info_text#16 = main::info_text31 [phi:main::@48->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text31
    sta.z display_info_rom.info_text
    lda #>info_text31
    sta.z display_info_rom.info_text+1
    // [1270] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#12 [phi:main::@48->display_info_rom#1] -- register_copy 
    // [1270] phi display_info_rom::info_status#16 = STATUS_FLASHED [phi:main::@48->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHED
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b47
    // [491] phi from main::@234 to main::@54 [phi:main::@234->main::@54]
    // main::@54
  __b54:
    // display_progress_clear()
    // [492] call display_progress_clear
    // [864] phi from main::@54 to display_progress_clear [phi:main::@54->display_progress_clear]
    jsr display_progress_clear
    // [493] phi from main::@54 to main::@180 [phi:main::@54->main::@180]
    // main::@180
    // smc_read(1)
    // [494] call smc_read
    // [1072] phi from main::@180 to smc_read [phi:main::@180->smc_read]
    // [1072] phi smc_read::display_progress#19 = 1 [phi:main::@180->smc_read#0] -- vbuz1=vbuc1 
    lda #1
    sta.z smc_read.display_progress
    // [1072] phi __errno#35 = __errno#114 [phi:main::@180->smc_read#1] -- register_copy 
    jsr smc_read
    // smc_read(1)
    // [495] smc_read::return#3 = smc_read::return#0
    // main::@181
    // smc_file_size = smc_read(1)
    // [496] smc_file_size#1 = smc_read::return#3 -- vwum1=vwum2 
    lda smc_read.return
    sta smc_file_size_1
    lda smc_read.return+1
    sta smc_file_size_1+1
    // if(smc_file_size)
    // [497] if(0==smc_file_size#1) goto main::@43 -- 0_eq_vwum1_then_la1 
    lda smc_file_size_1
    ora smc_file_size_1+1
    bne !__b43+
    jmp __b43
  !__b43:
    // [498] phi from main::@181 to main::@55 [phi:main::@181->main::@55]
    // main::@55
    // display_action_text("Press both POWER/RESET buttons on the CX16 board!")
    // [499] call display_action_text
  // Flash the SMC chip.
    // [1247] phi from main::@55 to display_action_text [phi:main::@55->display_action_text]
    // [1247] phi display_action_text::info_text#19 = main::info_text23 [phi:main::@55->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text23
    sta.z display_action_text.info_text
    lda #>info_text23
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@182
    // [500] smc_bootloader#474 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_FLASHING, "Press POWER/RESET!")
    // [501] call display_info_smc
    // [908] phi from main::@182 to display_info_smc [phi:main::@182->display_info_smc]
    // [908] phi display_info_smc::info_text#18 = main::info_text24 [phi:main::@182->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text24
    sta.z display_info_smc.info_text
    lda #>info_text24
    sta.z display_info_smc.info_text+1
    // [908] phi smc_bootloader#13 = smc_bootloader#474 [phi:main::@182->display_info_smc#1] -- register_copy 
    // [908] phi display_info_smc::info_status#18 = STATUS_FLASHING [phi:main::@182->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHING
    sta display_info_smc.info_status
    jsr display_info_smc
    // main::@183
    // unsigned int flashed_bytes = smc_flash(smc_file_size)
    // [502] smc_flash::smc_bytes_total#0 = smc_file_size#1 -- vwuz1=vwum2 
    lda smc_file_size_1
    sta.z smc_flash.smc_bytes_total
    lda smc_file_size_1+1
    sta.z smc_flash.smc_bytes_total+1
    // [503] call smc_flash
    // [1595] phi from main::@183 to smc_flash [phi:main::@183->smc_flash]
    jsr smc_flash
    // unsigned int flashed_bytes = smc_flash(smc_file_size)
    // [504] smc_flash::return#5 = smc_flash::return#1
    // main::@184
    // [505] main::flashed_bytes#0 = smc_flash::return#5
    // if(flashed_bytes)
    // [506] if(0!=main::flashed_bytes#0) goto main::@44 -- 0_neq_vwum1_then_la1 
    lda flashed_bytes
    ora flashed_bytes+1
    bne __b44
    // main::@56
    // if(flashed_bytes == (unsigned int)0xFFFF)
    // [507] if(main::flashed_bytes#0==$ffff) goto main::@45 -- vwum1_eq_vwuc1_then_la1 
    lda flashed_bytes
    cmp #<$ffff
    bne !+
    lda flashed_bytes+1
    cmp #>$ffff
    beq __b45
  !:
    // main::@57
    // [508] smc_bootloader#480 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ISSUE, "POWER/RESET not pressed!")
    // [509] call display_info_smc
  // SF-2 | no action on POWER/RESET press request
    // [908] phi from main::@57 to display_info_smc [phi:main::@57->display_info_smc]
    // [908] phi display_info_smc::info_text#18 = main::info_text27 [phi:main::@57->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text27
    sta.z display_info_smc.info_text
    lda #>info_text27
    sta.z display_info_smc.info_text+1
    // [908] phi smc_bootloader#13 = smc_bootloader#480 [phi:main::@57->display_info_smc#1] -- register_copy 
    // [908] phi display_info_smc::info_status#18 = STATUS_ISSUE [phi:main::@57->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_smc.info_status
    jsr display_info_smc
    jmp __b43
    // main::@45
  __b45:
    // [510] smc_bootloader#479 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ERROR, "SMC has errors!")
    // [511] call display_info_smc
  // SF-3 | errors during flash
    // [908] phi from main::@45 to display_info_smc [phi:main::@45->display_info_smc]
    // [908] phi display_info_smc::info_text#18 = main::info_text26 [phi:main::@45->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text26
    sta.z display_info_smc.info_text
    lda #>info_text26
    sta.z display_info_smc.info_text+1
    // [908] phi smc_bootloader#13 = smc_bootloader#479 [phi:main::@45->display_info_smc#1] -- register_copy 
    // [908] phi display_info_smc::info_status#18 = STATUS_ERROR [phi:main::@45->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_smc.info_status
    jsr display_info_smc
    jmp __b43
    // main::@44
  __b44:
    // [512] smc_bootloader#478 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_FLASHED, "")
    // [513] call display_info_smc
  // SF-1 | and POWER/RESET pressed
    // [908] phi from main::@44 to display_info_smc [phi:main::@44->display_info_smc]
    // [908] phi display_info_smc::info_text#18 = info_text4 [phi:main::@44->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z display_info_smc.info_text
    lda #>info_text4
    sta.z display_info_smc.info_text+1
    // [908] phi smc_bootloader#13 = smc_bootloader#478 [phi:main::@44->display_info_smc#1] -- register_copy 
    // [908] phi display_info_smc::info_status#18 = STATUS_FLASHED [phi:main::@44->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHED
    sta display_info_smc.info_status
    jsr display_info_smc
    jmp __b43
    // [514] phi from main::@232 main::@233 to main::@10 [phi:main::@232/main::@233->main::@10]
    // main::@10
  __b10:
    // display_action_progress("Chipsets have been detected and update files validated!")
    // [515] call display_action_progress
    // [850] phi from main::@10 to display_action_progress [phi:main::@10->display_action_progress]
    // [850] phi display_action_progress::info_text#18 = main::info_text17 [phi:main::@10->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text17
    sta.z display_action_progress.info_text
    lda #>info_text17
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [516] phi from main::@10 to main::@175 [phi:main::@10->main::@175]
    // main::@175
    // unsigned char ch = util_wait_key("Continue with update of highlighted chipsets? [Y/N]", "nyNY")
    // [517] call util_wait_key
    // [1197] phi from main::@175 to util_wait_key [phi:main::@175->util_wait_key]
    // [1197] phi util_wait_key::filter#13 = main::filter1 [phi:main::@175->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter1
    sta.z util_wait_key.filter
    lda #>filter1
    sta.z util_wait_key.filter+1
    // [1197] phi util_wait_key::info_text#3 = main::info_text18 [phi:main::@175->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text18
    sta.z util_wait_key.info_text
    lda #>info_text18
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("Continue with update of highlighted chipsets? [Y/N]", "nyNY")
    // [518] util_wait_key::return#4 = util_wait_key::ch#4 -- vbuz1=vwum2 
    lda util_wait_key.ch
    sta.z util_wait_key.return_1
    // main::@176
    // [519] main::ch1#0 = util_wait_key::return#4
    // strchr("nN", ch)
    // [520] strchr::c#1 = main::ch1#0
    // [521] call strchr
    // [1757] phi from main::@176 to strchr [phi:main::@176->strchr]
    // [1757] phi strchr::c#4 = strchr::c#1 [phi:main::@176->strchr#0] -- register_copy 
    // [1757] phi strchr::str#2 = (const void *)main::$298 [phi:main::@176->strchr#1] -- pvoz1=pvoc1 
    lda #<main__298
    sta.z strchr.str
    lda #>main__298
    sta.z strchr.str+1
    jsr strchr
    // strchr("nN", ch)
    // [522] strchr::return#4 = strchr::return#2
    // main::@177
    // [523] main::$186 = strchr::return#4
    // if(strchr("nN", ch))
    // [524] if((void *)0==main::$186) goto main::bank_set_bram2 -- pvoc1_eq_pvoz1_then_la1 
    lda.z main__186
    cmp #<0
    bne !+
    lda.z main__186+1
    cmp #>0
    bne !bank_set_bram2+
    jmp bank_set_bram2
  !bank_set_bram2:
  !:
    // main::@11
    // [525] smc_bootloader#468 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_SKIP, "Cancelled")
    // [526] call display_info_smc
  // We cancel all updates, the updates are skipped.
    // [908] phi from main::@11 to display_info_smc [phi:main::@11->display_info_smc]
    // [908] phi display_info_smc::info_text#18 = main::info_text19 [phi:main::@11->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text19
    sta.z display_info_smc.info_text
    lda #>info_text19
    sta.z display_info_smc.info_text+1
    // [908] phi smc_bootloader#13 = smc_bootloader#468 [phi:main::@11->display_info_smc#1] -- register_copy 
    // [908] phi display_info_smc::info_status#18 = STATUS_SKIP [phi:main::@11->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    // [527] phi from main::@11 to main::@178 [phi:main::@11->main::@178]
    // main::@178
    // display_info_vera(STATUS_SKIP, "Cancelled")
    // [528] call display_info_vera
    // [942] phi from main::@178 to display_info_vera [phi:main::@178->display_info_vera]
    // [942] phi display_info_vera::info_text#10 = main::info_text19 [phi:main::@178->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text19
    sta.z display_info_vera.info_text
    lda #>info_text19
    sta.z display_info_vera.info_text+1
    // [942] phi display_info_vera::info_status#3 = STATUS_SKIP [phi:main::@178->display_info_vera#1] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_vera.info_status
    jsr display_info_vera
    // [529] phi from main::@178 to main::@40 [phi:main::@178->main::@40]
    // [529] phi main::rom_chip3#2 = 0 [phi:main::@178->main::@40#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip3
    // main::@40
  __b40:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [530] if(main::rom_chip3#2<8) goto main::@41 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip3
    cmp #8
    bcc __b41
    // [531] phi from main::@40 to main::@42 [phi:main::@40->main::@42]
    // main::@42
    // display_action_text("You have selected not to cancel the update ... ")
    // [532] call display_action_text
    // [1247] phi from main::@42 to display_action_text [phi:main::@42->display_action_text]
    // [1247] phi display_action_text::info_text#19 = main::info_text22 [phi:main::@42->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text22
    sta.z display_action_text.info_text
    lda #>info_text22
    sta.z display_action_text.info_text+1
    jsr display_action_text
    jmp bank_set_bram2
    // main::@41
  __b41:
    // display_info_rom(rom_chip, STATUS_SKIP, "Cancelled")
    // [533] display_info_rom::rom_chip#9 = main::rom_chip3#2 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z display_info_rom.rom_chip
    // [534] call display_info_rom
    // [1270] phi from main::@41 to display_info_rom [phi:main::@41->display_info_rom]
    // [1270] phi display_info_rom::info_text#16 = main::info_text19 [phi:main::@41->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text19
    sta.z display_info_rom.info_text
    lda #>info_text19
    sta.z display_info_rom.info_text+1
    // [1270] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#9 [phi:main::@41->display_info_rom#1] -- register_copy 
    // [1270] phi display_info_rom::info_status#16 = STATUS_SKIP [phi:main::@41->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_rom.info_status
    jsr display_info_rom
    // main::@179
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [535] main::rom_chip3#1 = ++ main::rom_chip3#2 -- vbum1=_inc_vbum1 
    inc rom_chip3
    // [529] phi from main::@179 to main::@40 [phi:main::@179->main::@40]
    // [529] phi main::rom_chip3#2 = main::rom_chip3#1 [phi:main::@179->main::@40#0] -- register_copy 
    jmp __b40
    // main::check_status_card_roms1_check_status_rom1
  check_status_card_roms1_check_status_rom1:
    // status_rom[rom_chip] == status
    // [536] main::check_status_card_roms1_check_status_rom1_$0 = status_rom[main::check_status_card_roms1_rom_chip#2] == STATUS_FLASH -- vbom1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_FLASH
    ldy check_status_card_roms1_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_card_roms1_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [537] main::check_status_card_roms1_check_status_rom1_return#0 = (char)main::check_status_card_roms1_check_status_rom1_$0
    // main::check_status_card_roms1_@11
    // if(check_status_rom(rom_chip, status))
    // [538] if(0==main::check_status_card_roms1_check_status_rom1_return#0) goto main::check_status_card_roms1_@4 -- 0_eq_vbum1_then_la1 
    lda check_status_card_roms1_check_status_rom1_return
    beq check_status_card_roms1___b4
    // [392] phi from main::check_status_card_roms1_@11 to main::check_status_card_roms1_@return [phi:main::check_status_card_roms1_@11->main::check_status_card_roms1_@return]
    // [392] phi main::check_status_card_roms1_return#2 = 1 [phi:main::check_status_card_roms1_@11->main::check_status_card_roms1_@return#0] -- vbum1=vbuc1 
    lda #1
    sta check_status_card_roms1_return
    jmp __b79
    // main::check_status_card_roms1_@4
  check_status_card_roms1___b4:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [539] main::check_status_card_roms1_rom_chip#1 = ++ main::check_status_card_roms1_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_status_card_roms1_rom_chip
    // [390] phi from main::check_status_card_roms1_@4 to main::check_status_card_roms1_@1 [phi:main::check_status_card_roms1_@4->main::check_status_card_roms1_@1]
    // [390] phi main::check_status_card_roms1_rom_chip#2 = main::check_status_card_roms1_rom_chip#1 [phi:main::check_status_card_roms1_@4->main::check_status_card_roms1_@1#0] -- register_copy 
    jmp check_status_card_roms1___b1
    // main::check_status_roms2_check_status_rom1
  check_status_roms2_check_status_rom1:
    // status_rom[rom_chip] == status
    // [540] main::check_status_roms2_check_status_rom1_$0 = status_rom[main::check_status_roms2_rom_chip#2] == STATUS_ERROR -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_ERROR
    ldy check_status_roms2_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_roms2_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [541] main::check_status_roms2_check_status_rom1_return#0 = (char)main::check_status_roms2_check_status_rom1_$0
    // main::check_status_roms2_@11
    // if(check_status_rom(rom_chip, status))
    // [542] if(0==main::check_status_roms2_check_status_rom1_return#0) goto main::check_status_roms2_@4 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_roms2_check_status_rom1_return
    beq check_status_roms2___b4
    // [259] phi from main::check_status_roms2_@11 to main::check_status_roms2_@return [phi:main::check_status_roms2_@11->main::check_status_roms2_@return]
    // [259] phi main::check_status_roms2_return#2 = 1 [phi:main::check_status_roms2_@11->main::check_status_roms2_@return#0] -- vbum1=vbuc1 
    lda #1
    sta check_status_roms2_return
    jmp __b77
    // main::check_status_roms2_@4
  check_status_roms2___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [543] main::check_status_roms2_rom_chip#1 = ++ main::check_status_roms2_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_status_roms2_rom_chip
    // [257] phi from main::check_status_roms2_@4 to main::check_status_roms2_@1 [phi:main::check_status_roms2_@4->main::check_status_roms2_@1]
    // [257] phi main::check_status_roms2_rom_chip#2 = main::check_status_roms2_rom_chip#1 [phi:main::check_status_roms2_@4->main::check_status_roms2_@1#0] -- register_copy 
    jmp check_status_roms2___b1
    // main::check_status_roms1_check_status_rom1
  check_status_roms1_check_status_rom1:
    // status_rom[rom_chip] == status
    // [544] main::check_status_roms1_check_status_rom1_$0 = status_rom[main::check_status_roms1_rom_chip#2] == STATUS_ISSUE -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_ISSUE
    ldy check_status_roms1_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_roms1_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [545] main::check_status_roms1_check_status_rom1_return#0 = (char)main::check_status_roms1_check_status_rom1_$0
    // main::check_status_roms1_@11
    // if(check_status_rom(rom_chip, status))
    // [546] if(0==main::check_status_roms1_check_status_rom1_return#0) goto main::check_status_roms1_@4 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_roms1_check_status_rom1_return
    beq check_status_roms1___b4
    // [251] phi from main::check_status_roms1_@11 to main::check_status_roms1_@return [phi:main::check_status_roms1_@11->main::check_status_roms1_@return]
    // [251] phi main::check_status_roms1_return#2 = 1 [phi:main::check_status_roms1_@11->main::check_status_roms1_@return#0] -- vbum1=vbuc1 
    lda #1
    sta check_status_roms1_return
    jmp check_status_smc6
    // main::check_status_roms1_@4
  check_status_roms1___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [547] main::check_status_roms1_rom_chip#1 = ++ main::check_status_roms1_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_status_roms1_rom_chip
    // [249] phi from main::check_status_roms1_@4 to main::check_status_roms1_@1 [phi:main::check_status_roms1_@4->main::check_status_roms1_@1]
    // [249] phi main::check_status_roms1_rom_chip#2 = main::check_status_roms1_rom_chip#1 [phi:main::check_status_roms1_@4->main::check_status_roms1_@1#0] -- register_copy 
    jmp check_status_roms1___b1
    // [548] phi from main::@223 to main::@7 [phi:main::@223->main::@7]
    // main::@7
  __b7:
    // display_action_progress("The SMC chip and SMC.BIN versions are equal, no flash required!")
    // [549] call display_action_progress
    // [850] phi from main::@7 to display_action_progress [phi:main::@7->display_action_progress]
    // [850] phi display_action_progress::info_text#18 = main::info_text14 [phi:main::@7->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text14
    sta.z display_action_progress.info_text
    lda #>info_text14
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@169
    // [550] smc_bootloader#473 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_SKIP, NULL)
    // [551] call display_info_smc
    // [908] phi from main::@169 to display_info_smc [phi:main::@169->display_info_smc]
    // [908] phi display_info_smc::info_text#18 = 0 [phi:main::@169->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [908] phi smc_bootloader#13 = smc_bootloader#473 [phi:main::@169->display_info_smc#1] -- register_copy 
    // [908] phi display_info_smc::info_status#18 = STATUS_SKIP [phi:main::@169->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    // [552] phi from main::@169 to main::@170 [phi:main::@169->main::@170]
    // main::@170
    // util_wait_space()
    // [553] call util_wait_space
    // [1069] phi from main::@170 to util_wait_space [phi:main::@170->util_wait_space]
    jsr util_wait_space
    jmp __b5
    // [554] phi from main::@222 to main::@6 [phi:main::@222->main::@6]
    // main::@6
  __b6:
    // display_action_progress("CX16 ROM update issue!")
    // [555] call display_action_progress
    // [850] phi from main::@6 to display_action_progress [phi:main::@6->display_action_progress]
    // [850] phi display_action_progress::info_text#18 = main::info_text12 [phi:main::@6->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text12
    sta.z display_action_progress.info_text
    lda #>info_text12
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [556] phi from main::@6 to main::@164 [phi:main::@6->main::@164]
    // main::@164
    // display_progress_text(display_smc_rom_issue_text, display_smc_rom_issue_count)
    // [557] call display_progress_text
    // [1059] phi from main::@164 to display_progress_text [phi:main::@164->display_progress_text]
    // [1059] phi display_progress_text::text#12 = display_smc_rom_issue_text [phi:main::@164->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_rom_issue_text
    sta.z display_progress_text.text
    lda #>display_smc_rom_issue_text
    sta.z display_progress_text.text+1
    // [1059] phi display_progress_text::lines#11 = display_smc_rom_issue_count [phi:main::@164->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_smc_rom_issue_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // main::@165
    // [558] smc_bootloader#472 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_SKIP, "Issue with main CX16 ROM!")
    // [559] call display_info_smc
    // [908] phi from main::@165 to display_info_smc [phi:main::@165->display_info_smc]
    // [908] phi display_info_smc::info_text#18 = main::info_text10 [phi:main::@165->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text10
    sta.z display_info_smc.info_text
    lda #>info_text10
    sta.z display_info_smc.info_text+1
    // [908] phi smc_bootloader#13 = smc_bootloader#472 [phi:main::@165->display_info_smc#1] -- register_copy 
    // [908] phi display_info_smc::info_status#18 = STATUS_SKIP [phi:main::@165->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    // [560] phi from main::@165 to main::@166 [phi:main::@165->main::@166]
    // main::@166
    // display_info_cx16_rom(STATUS_ISSUE, NULL)
    // [561] call display_info_cx16_rom
    // [1221] phi from main::@166 to display_info_cx16_rom [phi:main::@166->display_info_cx16_rom]
    // [1221] phi display_info_cx16_rom::info_text#4 = 0 [phi:main::@166->display_info_cx16_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_cx16_rom.info_text
    sta.z display_info_cx16_rom.info_text+1
    // [1221] phi display_info_cx16_rom::info_status#4 = STATUS_ISSUE [phi:main::@166->display_info_cx16_rom#1] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    // [562] phi from main::@166 to main::@167 [phi:main::@166->main::@167]
    // main::@167
    // util_wait_space()
    // [563] call util_wait_space
    // [1069] phi from main::@167 to util_wait_space [phi:main::@167->util_wait_space]
    jsr util_wait_space
    jmp __b4
    // [564] phi from main::@221 to main::@3 [phi:main::@221->main::@3]
    // main::@3
  __b3:
    // display_action_progress("CX16 ROM update issue, ROM not detected!")
    // [565] call display_action_progress
    // [850] phi from main::@3 to display_action_progress [phi:main::@3->display_action_progress]
    // [850] phi display_action_progress::info_text#18 = main::info_text9 [phi:main::@3->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text9
    sta.z display_action_progress.info_text
    lda #>info_text9
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [566] phi from main::@3 to main::@160 [phi:main::@3->main::@160]
    // main::@160
    // display_progress_text(display_smc_rom_issue_text, display_smc_rom_issue_count)
    // [567] call display_progress_text
    // [1059] phi from main::@160 to display_progress_text [phi:main::@160->display_progress_text]
    // [1059] phi display_progress_text::text#12 = display_smc_rom_issue_text [phi:main::@160->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_rom_issue_text
    sta.z display_progress_text.text
    lda #>display_smc_rom_issue_text
    sta.z display_progress_text.text+1
    // [1059] phi display_progress_text::lines#11 = display_smc_rom_issue_count [phi:main::@160->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_smc_rom_issue_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // main::@161
    // [568] smc_bootloader#471 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_SKIP, "Issue with main CX16 ROM!")
    // [569] call display_info_smc
    // [908] phi from main::@161 to display_info_smc [phi:main::@161->display_info_smc]
    // [908] phi display_info_smc::info_text#18 = main::info_text10 [phi:main::@161->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text10
    sta.z display_info_smc.info_text
    lda #>info_text10
    sta.z display_info_smc.info_text+1
    // [908] phi smc_bootloader#13 = smc_bootloader#471 [phi:main::@161->display_info_smc#1] -- register_copy 
    // [908] phi display_info_smc::info_status#18 = STATUS_SKIP [phi:main::@161->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    // [570] phi from main::@161 to main::@162 [phi:main::@161->main::@162]
    // main::@162
    // display_info_cx16_rom(STATUS_ISSUE, "Are J1 jumper pins closed?")
    // [571] call display_info_cx16_rom
    // [1221] phi from main::@162 to display_info_cx16_rom [phi:main::@162->display_info_cx16_rom]
    // [1221] phi display_info_cx16_rom::info_text#4 = main::info_text11 [phi:main::@162->display_info_cx16_rom#0] -- pbuz1=pbuc1 
    lda #<info_text11
    sta.z display_info_cx16_rom.info_text
    lda #>info_text11
    sta.z display_info_cx16_rom.info_text+1
    // [1221] phi display_info_cx16_rom::info_status#4 = STATUS_ISSUE [phi:main::@162->display_info_cx16_rom#1] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    // [572] phi from main::@162 to main::@163 [phi:main::@162->main::@163]
    // main::@163
    // util_wait_space()
    // [573] call util_wait_space
    // [1069] phi from main::@163 to util_wait_space [phi:main::@163->util_wait_space]
    jsr util_wait_space
    jmp __b4
    // [574] phi from main::@220 to main::@39 [phi:main::@220->main::@39]
    // main::@39
  __b39:
    // display_action_progress("SMC update issue!")
    // [575] call display_action_progress
    // [850] phi from main::@39 to display_action_progress [phi:main::@39->display_action_progress]
    // [850] phi display_action_progress::info_text#18 = main::info_text7 [phi:main::@39->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z display_action_progress.info_text
    lda #>info_text7
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [576] phi from main::@39 to main::@156 [phi:main::@39->main::@156]
    // main::@156
    // display_progress_text(display_smc_rom_issue_text, display_smc_rom_issue_count)
    // [577] call display_progress_text
    // [1059] phi from main::@156 to display_progress_text [phi:main::@156->display_progress_text]
    // [1059] phi display_progress_text::text#12 = display_smc_rom_issue_text [phi:main::@156->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_rom_issue_text
    sta.z display_progress_text.text
    lda #>display_smc_rom_issue_text
    sta.z display_progress_text.text+1
    // [1059] phi display_progress_text::lines#11 = display_smc_rom_issue_count [phi:main::@156->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_smc_rom_issue_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [578] phi from main::@156 to main::@157 [phi:main::@156->main::@157]
    // main::@157
    // display_info_cx16_rom(STATUS_SKIP, "Issue with SMC!")
    // [579] call display_info_cx16_rom
    // [1221] phi from main::@157 to display_info_cx16_rom [phi:main::@157->display_info_cx16_rom]
    // [1221] phi display_info_cx16_rom::info_text#4 = main::info_text8 [phi:main::@157->display_info_cx16_rom#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z display_info_cx16_rom.info_text
    lda #>info_text8
    sta.z display_info_cx16_rom.info_text+1
    // [1221] phi display_info_cx16_rom::info_status#4 = STATUS_SKIP [phi:main::@157->display_info_cx16_rom#1] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    // main::@158
    // [580] smc_bootloader#470 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ISSUE, NULL)
    // [581] call display_info_smc
    // [908] phi from main::@158 to display_info_smc [phi:main::@158->display_info_smc]
    // [908] phi display_info_smc::info_text#18 = 0 [phi:main::@158->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [908] phi smc_bootloader#13 = smc_bootloader#470 [phi:main::@158->display_info_smc#1] -- register_copy 
    // [908] phi display_info_smc::info_status#18 = STATUS_ISSUE [phi:main::@158->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_smc.info_status
    jsr display_info_smc
    // [582] phi from main::@158 to main::@159 [phi:main::@158->main::@159]
    // main::@159
    // util_wait_space()
    // [583] call util_wait_space
    // [1069] phi from main::@159 to util_wait_space [phi:main::@159->util_wait_space]
    jsr util_wait_space
    jmp check_status_smc3
    // main::bank_set_brom5
  bank_set_brom5:
    // BROM = bank
    // [584] BROM = main::bank_set_brom5_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom5_bank
    sta.z BROM
    // main::@71
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [585] if(rom_device_ids[main::rom_chip2#10]==$55) goto main::@33 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    ldy rom_chip2
    lda rom_device_ids,y
    cmp #$55
    bne !__b33+
    jmp __b33
  !__b33:
    // [586] phi from main::@71 to main::@36 [phi:main::@71->main::@36]
    // main::@36
    // display_progress_clear()
    // [587] call display_progress_clear
    // [864] phi from main::@36 to display_progress_clear [phi:main::@36->display_progress_clear]
    jsr display_progress_clear
    // main::@134
    // unsigned char rom_bank = rom_chip * 32
    // [588] main::rom_bank#0 = main::rom_chip2#10 << 5 -- vbum1=vbum2_rol_5 
    lda rom_chip2
    asl
    asl
    asl
    asl
    asl
    sta rom_bank
    // unsigned char* file = rom_file(rom_chip)
    // [589] rom_file::rom_chip#0 = main::rom_chip2#10 -- vbum1=vbum2 
    lda rom_chip2
    sta rom_file.rom_chip
    // [590] call rom_file
    // [1313] phi from main::@134 to rom_file [phi:main::@134->rom_file]
    // [1313] phi rom_file::rom_chip#2 = rom_file::rom_chip#0 [phi:main::@134->rom_file#0] -- register_copy 
    jsr rom_file
    // unsigned char* file = rom_file(rom_chip)
    // [591] rom_file::return#4 = rom_file::return#2
    // main::@135
    // [592] main::file#0 = rom_file::return#4 -- pbum1=pbum2 
    lda rom_file.return
    sta file
    lda rom_file.return+1
    sta file+1
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [593] call snprintf_init
    // [1151] phi from main::@135 to snprintf_init [phi:main::@135->snprintf_init]
    // [1151] phi snprintf_init::s#26 = info_text [phi:main::@135->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [594] phi from main::@135 to main::@136 [phi:main::@135->main::@136]
    // main::@136
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [595] call printf_str
    // [1156] phi from main::@136 to printf_str [phi:main::@136->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:main::@136->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = main::s5 [phi:main::@136->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // main::@137
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [596] printf_string::str#16 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [597] call printf_string
    // [1165] phi from main::@137 to printf_string [phi:main::@137->printf_string]
    // [1165] phi printf_string::putc#22 = &snputc [phi:main::@137->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1165] phi printf_string::str#22 = printf_string::str#16 [phi:main::@137->printf_string#1] -- register_copy 
    // [1165] phi printf_string::format_justify_left#22 = 0 [phi:main::@137->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1165] phi printf_string::format_min_length#22 = 0 [phi:main::@137->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [598] phi from main::@137 to main::@138 [phi:main::@137->main::@138]
    // main::@138
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [599] call printf_str
    // [1156] phi from main::@138 to printf_str [phi:main::@138->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:main::@138->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = main::s6 [phi:main::@138->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // main::@139
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [600] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [601] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_progress(info_text)
    // [603] call display_action_progress
    // [850] phi from main::@139 to display_action_progress [phi:main::@139->display_action_progress]
    // [850] phi display_action_progress::info_text#18 = info_text [phi:main::@139->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_progress.info_text
    lda #>@info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@140
    // unsigned long rom_bytes_read = rom_read(0, rom_chip, file, STATUS_CHECKING, rom_bank, rom_sizes[rom_chip])
    // [604] main::$272 = main::rom_chip2#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip2
    asl
    asl
    sta main__272
    // [605] rom_read::file#0 = main::file#0 -- pbum1=pbum2 
    lda file
    sta rom_read.file
    lda file+1
    sta rom_read.file+1
    // [606] rom_read::brom_bank_start#1 = main::rom_bank#0 -- vbuz1=vbum2 
    lda rom_bank
    sta.z rom_read.brom_bank_start
    // [607] rom_read::rom_size#0 = rom_sizes[main::$272] -- vduz1=pduc1_derefidx_vbum2 
    ldy main__272
    lda rom_sizes,y
    sta.z rom_read.rom_size
    lda rom_sizes+1,y
    sta.z rom_read.rom_size+1
    lda rom_sizes+2,y
    sta.z rom_read.rom_size+2
    lda rom_sizes+3,y
    sta.z rom_read.rom_size+3
    // [608] call rom_read
  // Read the ROM(n).BIN file.
    // [1319] phi from main::@140 to rom_read [phi:main::@140->rom_read]
    // [1319] phi rom_read::display_progress#28 = 0 [phi:main::@140->rom_read#0] -- vbum1=vbuc1 
    lda #0
    sta rom_read.display_progress
    // [1319] phi rom_read::rom_size#12 = rom_read::rom_size#0 [phi:main::@140->rom_read#1] -- register_copy 
    // [1319] phi __errno#108 = __errno#114 [phi:main::@140->rom_read#2] -- register_copy 
    // [1319] phi rom_read::file#11 = rom_read::file#0 [phi:main::@140->rom_read#3] -- register_copy 
    // [1319] phi rom_read::brom_bank_start#22 = rom_read::brom_bank_start#1 [phi:main::@140->rom_read#4] -- register_copy 
    jsr rom_read
    // unsigned long rom_bytes_read = rom_read(0, rom_chip, file, STATUS_CHECKING, rom_bank, rom_sizes[rom_chip])
    // [609] rom_read::return#2 = rom_read::return#0
    // main::@141
    // [610] main::rom_bytes_read#0 = rom_read::return#2
    // if (!rom_bytes_read)
    // [611] if(0==main::rom_bytes_read#0) goto main::@34 -- 0_eq_vdum1_then_la1 
    // In case no file was found, set the status to none and skip to the next, else, mention the amount of bytes read.
    lda rom_bytes_read
    ora rom_bytes_read+1
    ora rom_bytes_read+2
    ora rom_bytes_read+3
    bne !__b34+
    jmp __b34
  !__b34:
    // main::@37
    // unsigned long rom_file_modulo = rom_bytes_read % 0x4000
    // [612] main::rom_file_modulo#0 = main::rom_bytes_read#0 & $4000-1 -- vdum1=vdum2_band_vduc1 
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
    // [613] if(0!=main::rom_file_modulo#0) goto main::@35 -- 0_neq_vdum1_then_la1 
    lda rom_file_modulo
    ora rom_file_modulo+1
    ora rom_file_modulo+2
    ora rom_file_modulo+3
    beq !__b35+
    jmp __b35
  !__b35:
    // main::@38
    // file_sizes[rom_chip] = rom_bytes_read
    // [614] file_sizes[main::$272] = main::rom_bytes_read#0 -- pduc1_derefidx_vbum1=vdum2 
    // RF-5 | ROM.BIN all ok | Display the ROM.BIN release version and github commit id (if any) and set ROM to Flash | Flash
    // We know the file size, so we indicate it in the status panel.
    ldy main__272
    lda rom_bytes_read
    sta file_sizes,y
    lda rom_bytes_read+1
    sta file_sizes+1,y
    lda rom_bytes_read+2
    sta file_sizes+2,y
    lda rom_bytes_read+3
    sta file_sizes+3,y
    // rom_get_github_commit_id(rom_file_github, (char*)RAM_BASE)
    // [615] call rom_get_github_commit_id
    // [1766] phi from main::@38 to rom_get_github_commit_id [phi:main::@38->rom_get_github_commit_id]
    // [1766] phi rom_get_github_commit_id::commit_id#6 = main::rom_file_github [phi:main::@38->rom_get_github_commit_id#0] -- pbuz1=pbuc1 
    lda #<rom_file_github
    sta.z rom_get_github_commit_id.commit_id
    lda #>rom_file_github
    sta.z rom_get_github_commit_id.commit_id+1
    // [1766] phi rom_get_github_commit_id::from#6 = (char *)$7800 [phi:main::@38->rom_get_github_commit_id#1] -- pbuz1=pbuc1 
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
    // [617] BRAM = main::bank_push_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_push_set_bram1_bank
    sta.z BRAM
    // main::@73
    // unsigned char rom_file_release = rom_get_release(*((char*)0xBF80))
    // [618] rom_get_release::release#3 = *((char *) 49024) -- vbum1=_deref_pbuc1 
    lda $bf80
    sta rom_get_release.release
    // [619] call rom_get_release
    // [1135] phi from main::@73 to rom_get_release [phi:main::@73->rom_get_release]
    // [1135] phi rom_get_release::release#4 = rom_get_release::release#3 [phi:main::@73->rom_get_release#0] -- register_copy 
    jsr rom_get_release
    // unsigned char rom_file_release = rom_get_release(*((char*)0xBF80))
    // [620] rom_get_release::return#4 = rom_get_release::return#0
    // main::@149
    // [621] main::rom_file_release#0 = rom_get_release::return#4
    // unsigned char rom_file_prefix = rom_get_prefix(*((char*)0xBF80))
    // [622] rom_get_prefix::release#3 = *((char *) 49024) -- vbum1=_deref_pbuc1 
    lda $bf80
    sta rom_get_prefix.release
    // [623] call rom_get_prefix
    // [1142] phi from main::@149 to rom_get_prefix [phi:main::@149->rom_get_prefix]
    // [1142] phi rom_get_prefix::release#4 = rom_get_prefix::release#3 [phi:main::@149->rom_get_prefix#0] -- register_copy 
    jsr rom_get_prefix
    // unsigned char rom_file_prefix = rom_get_prefix(*((char*)0xBF80))
    // [624] rom_get_prefix::return#10 = rom_get_prefix::return#0
    // main::@150
    // [625] main::rom_file_prefix#0 = rom_get_prefix::return#10
    // main::bank_pull_bram1
    // asm
    // asm { pla sta$00  }
    pla
    sta.z 0
    // main::@74
    // rom_get_version_text(rom_file_release_text, rom_file_prefix, rom_file_release, rom_file_github)
    // [627] rom_get_version_text::prefix#1 = main::rom_file_prefix#0
    // [628] rom_get_version_text::release#1 = main::rom_file_release#0
    // [629] call rom_get_version_text
    // [1783] phi from main::@74 to rom_get_version_text [phi:main::@74->rom_get_version_text]
    // [1783] phi rom_get_version_text::github#2 = main::rom_file_github [phi:main::@74->rom_get_version_text#0] -- pbuz1=pbuc1 
    lda #<rom_file_github
    sta.z rom_get_version_text.github
    lda #>rom_file_github
    sta.z rom_get_version_text.github+1
    // [1783] phi rom_get_version_text::release#2 = rom_get_version_text::release#1 [phi:main::@74->rom_get_version_text#1] -- register_copy 
    // [1783] phi rom_get_version_text::prefix#2 = rom_get_version_text::prefix#1 [phi:main::@74->rom_get_version_text#2] -- register_copy 
    // [1783] phi rom_get_version_text::release_info#2 = main::rom_file_release_text [phi:main::@74->rom_get_version_text#3] -- pbuz1=pbuc1 
    lda #<rom_file_release_text
    sta.z rom_get_version_text.release_info
    lda #>rom_file_release_text
    sta.z rom_get_version_text.release_info+1
    jsr rom_get_version_text
    // [630] phi from main::@74 to main::@151 [phi:main::@74->main::@151]
    // main::@151
    // sprintf(info_text, "%s %s", file, rom_file_release_text)
    // [631] call snprintf_init
    // [1151] phi from main::@151 to snprintf_init [phi:main::@151->snprintf_init]
    // [1151] phi snprintf_init::s#26 = info_text [phi:main::@151->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main::@152
    // sprintf(info_text, "%s %s", file, rom_file_release_text)
    // [632] printf_string::str#19 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [633] call printf_string
    // [1165] phi from main::@152 to printf_string [phi:main::@152->printf_string]
    // [1165] phi printf_string::putc#22 = &snputc [phi:main::@152->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1165] phi printf_string::str#22 = printf_string::str#19 [phi:main::@152->printf_string#1] -- register_copy 
    // [1165] phi printf_string::format_justify_left#22 = 0 [phi:main::@152->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1165] phi printf_string::format_min_length#22 = 0 [phi:main::@152->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [634] phi from main::@152 to main::@153 [phi:main::@152->main::@153]
    // main::@153
    // sprintf(info_text, "%s %s", file, rom_file_release_text)
    // [635] call printf_str
    // [1156] phi from main::@153 to printf_str [phi:main::@153->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:main::@153->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = s [phi:main::@153->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s
    sta.z printf_str.s
    lda #>@s
    sta.z printf_str.s+1
    jsr printf_str
    // [636] phi from main::@153 to main::@154 [phi:main::@153->main::@154]
    // main::@154
    // sprintf(info_text, "%s %s", file, rom_file_release_text)
    // [637] call printf_string
    // [1165] phi from main::@154 to printf_string [phi:main::@154->printf_string]
    // [1165] phi printf_string::putc#22 = &snputc [phi:main::@154->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1165] phi printf_string::str#22 = main::rom_file_release_text [phi:main::@154->printf_string#1] -- pbuz1=pbuc1 
    lda #<rom_file_release_text
    sta.z printf_string.str
    lda #>rom_file_release_text
    sta.z printf_string.str+1
    // [1165] phi printf_string::format_justify_left#22 = 0 [phi:main::@154->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1165] phi printf_string::format_min_length#22 = 0 [phi:main::@154->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@155
    // sprintf(info_text, "%s %s", file, rom_file_release_text)
    // [638] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [639] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_FLASH, info_text)
    // [641] display_info_rom::rom_chip#8 = main::rom_chip2#10 -- vbuz1=vbum2 
    lda rom_chip2
    sta.z display_info_rom.rom_chip
    // [642] call display_info_rom
    // [1270] phi from main::@155 to display_info_rom [phi:main::@155->display_info_rom]
    // [1270] phi display_info_rom::info_text#16 = info_text [phi:main::@155->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1270] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#8 [phi:main::@155->display_info_rom#1] -- register_copy 
    // [1270] phi display_info_rom::info_status#16 = STATUS_FLASH [phi:main::@155->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta display_info_rom.info_status
    jsr display_info_rom
    // [643] phi from main::@144 main::@148 main::@155 main::@71 to main::@33 [phi:main::@144/main::@148/main::@155/main::@71->main::@33]
    // [643] phi __errno#238 = __errno#18 [phi:main::@144/main::@148/main::@155/main::@71->main::@33#0] -- register_copy 
    // main::@33
  __b33:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [644] main::rom_chip2#1 = ++ main::rom_chip2#10 -- vbum1=_inc_vbum1 
    inc rom_chip2
    // [198] phi from main::@33 to main::@32 [phi:main::@33->main::@32]
    // [198] phi __errno#114 = __errno#238 [phi:main::@33->main::@32#0] -- register_copy 
    // [198] phi main::rom_chip2#10 = main::rom_chip2#1 [phi:main::@33->main::@32#1] -- register_copy 
    jmp __b32
    // [645] phi from main::@37 to main::@35 [phi:main::@37->main::@35]
    // main::@35
  __b35:
    // sprintf(info_text, "File %s size error!", file)
    // [646] call snprintf_init
    // [1151] phi from main::@35 to snprintf_init [phi:main::@35->snprintf_init]
    // [1151] phi snprintf_init::s#26 = info_text [phi:main::@35->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [647] phi from main::@35 to main::@145 [phi:main::@35->main::@145]
    // main::@145
    // sprintf(info_text, "File %s size error!", file)
    // [648] call printf_str
    // [1156] phi from main::@145 to printf_str [phi:main::@145->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:main::@145->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = main::s8 [phi:main::@145->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // main::@146
    // sprintf(info_text, "File %s size error!", file)
    // [649] printf_string::str#18 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [650] call printf_string
    // [1165] phi from main::@146 to printf_string [phi:main::@146->printf_string]
    // [1165] phi printf_string::putc#22 = &snputc [phi:main::@146->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1165] phi printf_string::str#22 = printf_string::str#18 [phi:main::@146->printf_string#1] -- register_copy 
    // [1165] phi printf_string::format_justify_left#22 = 0 [phi:main::@146->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1165] phi printf_string::format_min_length#22 = 0 [phi:main::@146->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [651] phi from main::@146 to main::@147 [phi:main::@146->main::@147]
    // main::@147
    // sprintf(info_text, "File %s size error!", file)
    // [652] call printf_str
    // [1156] phi from main::@147 to printf_str [phi:main::@147->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:main::@147->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = main::s9 [phi:main::@147->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // main::@148
    // sprintf(info_text, "File %s size error!", file)
    // [653] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [654] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_ISSUE, info_text)
    // [656] display_info_rom::rom_chip#7 = main::rom_chip2#10 -- vbuz1=vbum2 
    lda rom_chip2
    sta.z display_info_rom.rom_chip
    // [657] call display_info_rom
    // [1270] phi from main::@148 to display_info_rom [phi:main::@148->display_info_rom]
    // [1270] phi display_info_rom::info_text#16 = info_text [phi:main::@148->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1270] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#7 [phi:main::@148->display_info_rom#1] -- register_copy 
    // [1270] phi display_info_rom::info_status#16 = STATUS_ISSUE [phi:main::@148->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b33
    // [658] phi from main::@141 to main::@34 [phi:main::@141->main::@34]
    // main::@34
  __b34:
    // sprintf(info_text, "No %s", file)
    // [659] call snprintf_init
    // [1151] phi from main::@34 to snprintf_init [phi:main::@34->snprintf_init]
    // [1151] phi snprintf_init::s#26 = info_text [phi:main::@34->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [660] phi from main::@34 to main::@142 [phi:main::@34->main::@142]
    // main::@142
    // sprintf(info_text, "No %s", file)
    // [661] call printf_str
    // [1156] phi from main::@142 to printf_str [phi:main::@142->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:main::@142->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = main::s7 [phi:main::@142->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@143
    // sprintf(info_text, "No %s", file)
    // [662] printf_string::str#17 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [663] call printf_string
    // [1165] phi from main::@143 to printf_string [phi:main::@143->printf_string]
    // [1165] phi printf_string::putc#22 = &snputc [phi:main::@143->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1165] phi printf_string::str#22 = printf_string::str#17 [phi:main::@143->printf_string#1] -- register_copy 
    // [1165] phi printf_string::format_justify_left#22 = 0 [phi:main::@143->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1165] phi printf_string::format_min_length#22 = 0 [phi:main::@143->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@144
    // sprintf(info_text, "No %s", file)
    // [664] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [665] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_SKIP, info_text)
    // [667] display_info_rom::rom_chip#6 = main::rom_chip2#10 -- vbuz1=vbum2 
    lda rom_chip2
    sta.z display_info_rom.rom_chip
    // [668] call display_info_rom
    // [1270] phi from main::@144 to display_info_rom [phi:main::@144->display_info_rom]
    // [1270] phi display_info_rom::info_text#16 = info_text [phi:main::@144->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1270] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#6 [phi:main::@144->display_info_rom#1] -- register_copy 
    // [1270] phi display_info_rom::info_status#16 = STATUS_SKIP [phi:main::@144->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b33
    // main::@31
  __b31:
    // [669] smc_bootloader#477 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ISSUE, "SMC.BIN too large!")
    // [670] call display_info_smc
  // SF-3 | size SMC.BIN is > 0x1E00 | Display SMC.BIN file size issue and don't flash. Ask the user to place a correct SMC.BIN file onto the SDcard. | Issue
    // [908] phi from main::@31 to display_info_smc [phi:main::@31->display_info_smc]
    // [908] phi display_info_smc::info_text#18 = main::info_text6 [phi:main::@31->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text6
    sta.z display_info_smc.info_text
    lda #>info_text6
    sta.z display_info_smc.info_text+1
    // [908] phi smc_bootloader#13 = smc_bootloader#477 [phi:main::@31->display_info_smc#1] -- register_copy 
    // [908] phi display_info_smc::info_status#18 = STATUS_ISSUE [phi:main::@31->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_smc.info_status
    jsr display_info_smc
    // [195] phi from main::@30 main::@31 to main::CLI2 [phi:main::@30/main::@31->main::CLI2]
  __b11:
    // [195] phi smc_file_minor#246 = 0 [phi:main::@30/main::@31->main::CLI2#0] -- vbum1=vbuc1 
    lda #0
    sta smc_file_minor
    // [195] phi smc_file_major#247 = 0 [phi:main::@30/main::@31->main::CLI2#1] -- vbum1=vbuc1 
    sta smc_file_major
    // [195] phi smc_file_release#248 = 0 [phi:main::@30/main::@31->main::CLI2#2] -- vbum1=vbuc1 
    sta smc_file_release
    // [195] phi __errno#239 = __errno#18 [phi:main::@30/main::@31->main::CLI2#3] -- register_copy 
    jmp CLI2
    // main::@30
  __b30:
    // [671] smc_bootloader#476 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_SKIP, "No SMC.BIN!")
    // [672] call display_info_smc
  // SF-1 | no SMC.BIN | Ask user to place an SMC.BIN file onto the SDcard and don't flash. | Issue
  // SF-2 | size SMC.BIN is 0 | Ask user to place an SMC.BIN file onto the SDcard and don't flash. | Issue
    // [908] phi from main::@30 to display_info_smc [phi:main::@30->display_info_smc]
    // [908] phi display_info_smc::info_text#18 = main::info_text5 [phi:main::@30->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z display_info_smc.info_text
    lda #>info_text5
    sta.z display_info_smc.info_text+1
    // [908] phi smc_bootloader#13 = smc_bootloader#476 [phi:main::@30->display_info_smc#1] -- register_copy 
    // [908] phi display_info_smc::info_status#18 = STATUS_SKIP [phi:main::@30->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    jmp __b11
    // main::@25
  __b25:
    // display_info_led(PROGRESS_X + 3, PROGRESS_Y + 3 + intro_status, status_color[intro_status], BLUE)
    // [673] display_info_led::y#3 = PROGRESS_Y+3 + main::intro_status#2 -- vbuz1=vbuc1_plus_vbum2 
    lda #PROGRESS_Y+3
    clc
    adc intro_status
    sta.z display_info_led.y
    // [674] display_info_led::tc#3 = status_color[main::intro_status#2] -- vbuz1=pbuc1_derefidx_vbum2 
    ldy intro_status
    lda status_color,y
    sta.z display_info_led.tc
    // [675] call display_info_led
    // [1799] phi from main::@25 to display_info_led [phi:main::@25->display_info_led]
    // [1799] phi display_info_led::y#4 = display_info_led::y#3 [phi:main::@25->display_info_led#0] -- register_copy 
    // [1799] phi display_info_led::x#4 = PROGRESS_X+3 [phi:main::@25->display_info_led#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X+3
    sta.z display_info_led.x
    // [1799] phi display_info_led::tc#4 = display_info_led::tc#3 [phi:main::@25->display_info_led#2] -- register_copy 
    jsr display_info_led
    // main::@124
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [676] main::intro_status#1 = ++ main::intro_status#2 -- vbum1=_inc_vbum1 
    inc intro_status
    // [150] phi from main::@124 to main::@24 [phi:main::@124->main::@24]
    // [150] phi main::intro_status#2 = main::intro_status#1 [phi:main::@124->main::@24#0] -- register_copy 
    jmp __b24
    // main::@22
  __b22:
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [677] if(rom_device_ids[main::rom_chip1#10]!=$55) goto main::bank_set_brom3 -- pbuc1_derefidx_vbum1_neq_vbuc2_then_la1 
    lda #$55
    ldy rom_chip1
    cmp rom_device_ids,y
    bne bank_set_brom3
    // main::@23
  __b23:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [678] main::rom_chip1#1 = ++ main::rom_chip1#10 -- vbum1=_inc_vbum1 
    inc rom_chip1
    // [140] phi from main::@23 to main::@21 [phi:main::@23->main::@21]
    // [140] phi main::rom_chip1#10 = main::rom_chip1#1 [phi:main::@23->main::@21#0] -- register_copy 
    jmp __b21
    // main::bank_set_brom3
  bank_set_brom3:
    // BROM = bank
    // [679] BROM = main::bank_set_brom3_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom3_bank
    sta.z BROM
    // main::@69
    // rom_chip*8
    // [680] main::$106 = main::rom_chip1#10 << 3 -- vbuz1=vbum2_rol_3 
    lda rom_chip1
    asl
    asl
    asl
    sta.z main__106
    // rom_get_github_commit_id(&rom_github[rom_chip*8], (char*)0xC000)
    // [681] rom_get_github_commit_id::commit_id#0 = rom_github + main::$106 -- pbuz1=pbuc1_plus_vbuz2 
    clc
    adc #<rom_github
    sta.z rom_get_github_commit_id.commit_id
    lda #>rom_github
    adc #0
    sta.z rom_get_github_commit_id.commit_id+1
    // [682] call rom_get_github_commit_id
    // [1766] phi from main::@69 to rom_get_github_commit_id [phi:main::@69->rom_get_github_commit_id]
    // [1766] phi rom_get_github_commit_id::commit_id#6 = rom_get_github_commit_id::commit_id#0 [phi:main::@69->rom_get_github_commit_id#0] -- register_copy 
    // [1766] phi rom_get_github_commit_id::from#6 = (char *) 49152 [phi:main::@69->rom_get_github_commit_id#1] -- pbuz1=pbuc1 
    lda #<$c000
    sta.z rom_get_github_commit_id.from
    lda #>$c000
    sta.z rom_get_github_commit_id.from+1
    jsr rom_get_github_commit_id
    // main::@120
    // rom_get_release(*((char*)0xFF80))
    // [683] rom_get_release::release#1 = *((char *) 65408) -- vbum1=_deref_pbuc1 
    lda $ff80
    sta rom_get_release.release
    // [684] call rom_get_release
    // [1135] phi from main::@120 to rom_get_release [phi:main::@120->rom_get_release]
    // [1135] phi rom_get_release::release#4 = rom_get_release::release#1 [phi:main::@120->rom_get_release#0] -- register_copy 
    jsr rom_get_release
    // rom_get_release(*((char*)0xFF80))
    // [685] rom_get_release::return#2 = rom_get_release::return#0
    // main::@121
    // [686] main::$102 = rom_get_release::return#2
    // rom_release[rom_chip] = rom_get_release(*((char*)0xFF80))
    // [687] rom_release[main::rom_chip1#10] = main::$102 -- pbuc1_derefidx_vbum1=vbum2 
    lda main__102
    ldy rom_chip1
    sta rom_release,y
    // rom_get_prefix(*((char*)0xFF80))
    // [688] rom_get_prefix::release#0 = *((char *) 65408) -- vbum1=_deref_pbuc1 
    lda $ff80
    sta rom_get_prefix.release
    // [689] call rom_get_prefix
    // [1142] phi from main::@121 to rom_get_prefix [phi:main::@121->rom_get_prefix]
    // [1142] phi rom_get_prefix::release#4 = rom_get_prefix::release#0 [phi:main::@121->rom_get_prefix#0] -- register_copy 
    jsr rom_get_prefix
    // rom_get_prefix(*((char*)0xFF80))
    // [690] rom_get_prefix::return#2 = rom_get_prefix::return#0
    // main::@122
    // [691] main::$103 = rom_get_prefix::return#2
    // rom_prefix[rom_chip] = rom_get_prefix(*((char*)0xFF80))
    // [692] rom_prefix[main::rom_chip1#10] = main::$103 -- pbuc1_derefidx_vbum1=vbum2 
    lda main__103
    ldy rom_chip1
    sta rom_prefix,y
    // rom_chip*13
    // [693] main::$322 = main::rom_chip1#10 << 1 -- vbuz1=vbum2_rol_1 
    tya
    asl
    sta.z main__322
    // [694] main::$323 = main::$322 + main::rom_chip1#10 -- vbuz1=vbuz1_plus_vbum2 
    tya
    clc
    adc.z main__323
    sta.z main__323
    // [695] main::$324 = main::$323 << 2 -- vbuz1=vbuz1_rol_2 
    lda.z main__324
    asl
    asl
    sta.z main__324
    // [696] main::$104 = main::$324 + main::rom_chip1#10 -- vbuz1=vbuz1_plus_vbum2 
    tya
    clc
    adc.z main__104
    sta.z main__104
    // rom_get_version_text(&rom_release_text[rom_chip*13], rom_prefix[rom_chip], rom_release[rom_chip], &rom_github[rom_chip*8])
    // [697] rom_get_version_text::release_info#0 = rom_release_text + main::$104 -- pbuz1=pbuc1_plus_vbuz2 
    clc
    adc #<rom_release_text
    sta.z rom_get_version_text.release_info
    lda #>rom_release_text
    adc #0
    sta.z rom_get_version_text.release_info+1
    // [698] rom_get_version_text::github#0 = rom_github + main::$106 -- pbuz1=pbuc1_plus_vbuz2 
    lda.z main__106
    clc
    adc #<rom_github
    sta.z rom_get_version_text.github
    lda #>rom_github
    adc #0
    sta.z rom_get_version_text.github+1
    // [699] rom_get_version_text::prefix#0 = rom_prefix[main::rom_chip1#10] -- vbum1=pbuc1_derefidx_vbum2 
    lda rom_prefix,y
    sta rom_get_version_text.prefix
    // [700] rom_get_version_text::release#0 = rom_release[main::rom_chip1#10] -- vbum1=pbuc1_derefidx_vbum2 
    lda rom_release,y
    sta rom_get_version_text.release
    // [701] call rom_get_version_text
    // [1783] phi from main::@122 to rom_get_version_text [phi:main::@122->rom_get_version_text]
    // [1783] phi rom_get_version_text::github#2 = rom_get_version_text::github#0 [phi:main::@122->rom_get_version_text#0] -- register_copy 
    // [1783] phi rom_get_version_text::release#2 = rom_get_version_text::release#0 [phi:main::@122->rom_get_version_text#1] -- register_copy 
    // [1783] phi rom_get_version_text::prefix#2 = rom_get_version_text::prefix#0 [phi:main::@122->rom_get_version_text#2] -- register_copy 
    // [1783] phi rom_get_version_text::release_info#2 = rom_get_version_text::release_info#0 [phi:main::@122->rom_get_version_text#3] -- register_copy 
    jsr rom_get_version_text
    // main::@123
    // display_info_rom(rom_chip, STATUS_DETECTED, "")
    // [702] display_info_rom::rom_chip#5 = main::rom_chip1#10 -- vbuz1=vbum2 
    lda rom_chip1
    sta.z display_info_rom.rom_chip
    // [703] call display_info_rom
    // [1270] phi from main::@123 to display_info_rom [phi:main::@123->display_info_rom]
    // [1270] phi display_info_rom::info_text#16 = info_text4 [phi:main::@123->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z display_info_rom.info_text
    lda #>info_text4
    sta.z display_info_rom.info_text+1
    // [1270] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#5 [phi:main::@123->display_info_rom#1] -- register_copy 
    // [1270] phi display_info_rom::info_status#16 = STATUS_DETECTED [phi:main::@123->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_DETECTED
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b23
    // [704] phi from main::@17 to main::@20 [phi:main::@17->main::@20]
    // main::@20
  __b20:
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [705] call snprintf_init
    // [1151] phi from main::@20 to snprintf_init [phi:main::@20->snprintf_init]
    // [1151] phi snprintf_init::s#26 = info_text [phi:main::@20->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [706] phi from main::@20 to main::@106 [phi:main::@20->main::@106]
    // main::@106
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [707] call printf_str
    // [1156] phi from main::@106 to printf_str [phi:main::@106->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:main::@106->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = main::s2 [phi:main::@106->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main::@107
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [708] printf_uint::uvalue#13 = smc_bootloader#0 -- vwuz1=vwum2 
    lda smc_bootloader
    sta.z printf_uint.uvalue
    lda smc_bootloader+1
    sta.z printf_uint.uvalue+1
    // [709] call printf_uint
    // [1810] phi from main::@107 to printf_uint [phi:main::@107->printf_uint]
    // [1810] phi printf_uint::format_zero_padding#14 = 1 [phi:main::@107->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [1810] phi printf_uint::format_min_length#14 = 2 [phi:main::@107->printf_uint#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uint.format_min_length
    // [1810] phi printf_uint::putc#14 = &snputc [phi:main::@107->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [1810] phi printf_uint::format_radix#14 = HEXADECIMAL [phi:main::@107->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [1810] phi printf_uint::uvalue#14 = printf_uint::uvalue#13 [phi:main::@107->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [710] phi from main::@107 to main::@108 [phi:main::@107->main::@108]
    // main::@108
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [711] call printf_str
    // [1156] phi from main::@108 to printf_str [phi:main::@108->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:main::@108->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = main::s3 [phi:main::@108->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // main::@109
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [712] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [713] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [715] smc_bootloader#466 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ISSUE, info_text)
    // [716] call display_info_smc
    // [908] phi from main::@109 to display_info_smc [phi:main::@109->display_info_smc]
    // [908] phi display_info_smc::info_text#18 = info_text [phi:main::@109->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_smc.info_text
    lda #>@info_text
    sta.z display_info_smc.info_text+1
    // [908] phi smc_bootloader#13 = smc_bootloader#466 [phi:main::@109->display_info_smc#1] -- register_copy 
    // [908] phi display_info_smc::info_status#18 = STATUS_ISSUE [phi:main::@109->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_smc.info_status
    jsr display_info_smc
    // [717] phi from main::@109 to main::@110 [phi:main::@109->main::@110]
    // main::@110
    // display_progress_text(display_no_valid_smc_bootloader_text, display_no_valid_smc_bootloader_count)
    // [718] call display_progress_text
  // Bootloader is not supported by this utility, but is not error.
    // [1059] phi from main::@110 to display_progress_text [phi:main::@110->display_progress_text]
    // [1059] phi display_progress_text::text#12 = display_no_valid_smc_bootloader_text [phi:main::@110->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_no_valid_smc_bootloader_text
    sta.z display_progress_text.text
    lda #>display_no_valid_smc_bootloader_text
    sta.z display_progress_text.text+1
    // [1059] phi display_progress_text::lines#11 = display_no_valid_smc_bootloader_count [phi:main::@110->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_no_valid_smc_bootloader_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [132] phi from main::@105 main::@110 main::@19 to main::@2 [phi:main::@105/main::@110/main::@19->main::@2]
  __b12:
    // [132] phi smc_minor#398 = 0 [phi:main::@105/main::@110/main::@19->main::@2#0] -- vbum1=vbuc1 
    lda #0
    sta smc_minor
    // [132] phi smc_major#399 = 0 [phi:main::@105/main::@110/main::@19->main::@2#1] -- vbum1=vbuc1 
    sta smc_major
    // [132] phi smc_release#400 = 0 [phi:main::@105/main::@110/main::@19->main::@2#2] -- vbum1=vbuc1 
    sta smc_release
    jmp __b2
    // main::@19
  __b19:
    // [719] smc_bootloader#475 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ERROR, "SMC Unreachable!")
    // [720] call display_info_smc
  // SD-2 | SMC chip not detected | Display that the SMC chip is not detected and set SMC to Error. | Error
    // [908] phi from main::@19 to display_info_smc [phi:main::@19->display_info_smc]
    // [908] phi display_info_smc::info_text#18 = main::info_text2 [phi:main::@19->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z display_info_smc.info_text
    lda #>info_text2
    sta.z display_info_smc.info_text+1
    // [908] phi smc_bootloader#13 = smc_bootloader#475 [phi:main::@19->display_info_smc#1] -- register_copy 
    // [908] phi display_info_smc::info_status#18 = STATUS_ERROR [phi:main::@19->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_smc.info_status
    jsr display_info_smc
    jmp __b12
    // main::@1
  __b1:
    // [721] smc_bootloader#464 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ISSUE, "No Bootloader!")
    // [722] call display_info_smc
  // SD-1 | No Bootloader | Display that there is no bootloader and set SMC to Issue. | Issue
    // [908] phi from main::@1 to display_info_smc [phi:main::@1->display_info_smc]
    // [908] phi display_info_smc::info_text#18 = main::info_text1 [phi:main::@1->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_smc.info_text
    lda #>info_text1
    sta.z display_info_smc.info_text+1
    // [908] phi smc_bootloader#13 = smc_bootloader#464 [phi:main::@1->display_info_smc#1] -- register_copy 
    // [908] phi display_info_smc::info_status#18 = STATUS_ISSUE [phi:main::@1->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_smc.info_status
    jsr display_info_smc
    // [723] phi from main::@1 to main::@105 [phi:main::@1->main::@105]
    // main::@105
    // display_progress_text(display_no_valid_smc_bootloader_text, display_no_valid_smc_bootloader_count)
    // [724] call display_progress_text
  // If the CX16 board does not have a bootloader, display info how to flash bootloader.
    // [1059] phi from main::@105 to display_progress_text [phi:main::@105->display_progress_text]
    // [1059] phi display_progress_text::text#12 = display_no_valid_smc_bootloader_text [phi:main::@105->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_no_valid_smc_bootloader_text
    sta.z display_progress_text.text
    lda #>display_no_valid_smc_bootloader_text
    sta.z display_progress_text.text+1
    // [1059] phi display_progress_text::lines#11 = display_no_valid_smc_bootloader_count [phi:main::@105->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_no_valid_smc_bootloader_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    jmp __b12
    // main::@14
  __b14:
    // rom_chip*13
    // [725] main::$318 = main::rom_chip#2 << 1 -- vbuz1=vbum2_rol_1 
    lda rom_chip
    asl
    sta.z main__318
    // [726] main::$319 = main::$318 + main::rom_chip#2 -- vbuz1=vbuz1_plus_vbum2 
    lda rom_chip
    clc
    adc.z main__319
    sta.z main__319
    // [727] main::$320 = main::$319 << 2 -- vbuz1=vbuz1_rol_2 
    lda.z main__320
    asl
    asl
    sta.z main__320
    // [728] main::$79 = main::$320 + main::rom_chip#2 -- vbuz1=vbuz1_plus_vbum2 
    lda rom_chip
    clc
    adc.z main__79
    sta.z main__79
    // strcpy(&rom_release_text[rom_chip*13], "          " )
    // [729] strcpy::destination#1 = rom_release_text + main::$79 -- pbuz1=pbuc1_plus_vbuz2 
    clc
    adc #<rom_release_text
    sta.z strcpy.destination
    lda #>rom_release_text
    adc #0
    sta.z strcpy.destination+1
    // [730] call strcpy
    // [979] phi from main::@14 to strcpy [phi:main::@14->strcpy]
    // [979] phi strcpy::dst#0 = strcpy::destination#1 [phi:main::@14->strcpy#0] -- register_copy 
    // [979] phi strcpy::src#0 = main::source [phi:main::@14->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // main::@100
    // display_info_rom(rom_chip, STATUS_NONE, NULL)
    // [731] display_info_rom::rom_chip#4 = main::rom_chip#2 -- vbuz1=vbum2 
    lda rom_chip
    sta.z display_info_rom.rom_chip
    // [732] call display_info_rom
    // [1270] phi from main::@100 to display_info_rom [phi:main::@100->display_info_rom]
    // [1270] phi display_info_rom::info_text#16 = 0 [phi:main::@100->display_info_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_rom.info_text
    sta.z display_info_rom.info_text+1
    // [1270] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#4 [phi:main::@100->display_info_rom#1] -- register_copy 
    // [1270] phi display_info_rom::info_status#16 = STATUS_NONE [phi:main::@100->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta display_info_rom.info_status
    jsr display_info_rom
    // main::@101
    // for(unsigned char rom_chip=0; rom_chip<8; rom_chip++)
    // [733] main::rom_chip#1 = ++ main::rom_chip#2 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [99] phi from main::@101 to main::@13 [phi:main::@101->main::@13]
    // [99] phi main::rom_chip#2 = main::rom_chip#1 [phi:main::@101->main::@13#0] -- register_copy 
    jmp __b13
  .segment Data
    smc_file_version_text: .fill $d, 0
    // Fill the version data ...
    rom_file_github: .fill 8, 0
    rom_file_release_text: .fill $d, 0
    title_text: .text "Commander X16 Flash Utility!"
    .byte 0
    s: .text "# Chip Status    Type   Curr. Release Update Info"
    .byte 0
    s1: .text "- ---- --------- ------ ------------- --------------------------"
    .byte 0
    info_text: .text "Introduction ..."
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
    info_text3: .text "VERA installed, OK"
    .byte 0
    info_text5: .text "No SMC.BIN!"
    .byte 0
    info_text6: .text "SMC.BIN too large!"
    .byte 0
    s4: .text "SMC.BIN:"
    .byte 0
    s5: .text "Checking "
    .byte 0
    s6: .text " ... (.) data ( ) empty"
    .byte 0
    s7: .text "No "
    .byte 0
    s8: .text "File "
    .byte 0
    s9: .text " size error!"
    .byte 0
    info_text7: .text "SMC update issue!"
    .byte 0
    info_text8: .text "Issue with SMC!"
    .byte 0
    info_text9: .text "CX16 ROM update issue, ROM not detected!"
    .byte 0
    info_text10: .text "Issue with main CX16 ROM!"
    .byte 0
    info_text11: .text "Are J1 jumper pins closed?"
    .byte 0
    info_text12: .text "CX16 ROM update issue!"
    .byte 0
    info_text14: .text "The SMC chip and SMC.BIN versions are equal, no flash required!"
    .byte 0
    info_text15: .text "The ROM.BIN isn't compatible with SMC.BIN, no flash allowed!"
    .byte 0
    info_text16: .text "You still want to continue with flashing? [YN]"
    .byte 0
    filter: .text "YN"
    .byte 0
    info_text17: .text "Chipsets have been detected and update files validated!"
    .byte 0
    info_text18: .text "Continue with update of highlighted chipsets? [Y/N]"
    .byte 0
    filter1: .text "nyNY"
    .byte 0
    main__298: .text "nN"
    .byte 0
    info_text19: .text "Cancelled"
    .byte 0
    info_text22: .text "You have selected not to cancel the update ... "
    .byte 0
    info_text23: .text "Press both POWER/RESET buttons on the CX16 board!"
    .byte 0
    info_text24: .text "Press POWER/RESET!"
    .byte 0
    info_text26: .text "SMC has errors!"
    .byte 0
    info_text27: .text "POWER/RESET not pressed!"
    .byte 0
    info_text28: .text "Update SMC failed!"
    .byte 0
    info_text29: .text "Comparing ... (.) same, (*) different."
    .byte 0
    info_text31: .text "No update required"
    .byte 0
    s13: .text " differences!"
    .byte 0
    s14: .text " flash errors!"
    .byte 0
    info_text32: .text "OK!"
    .byte 0
    info_text33: .text "The update has been cancelled!"
    .byte 0
    info_text34: .text "Update Failure! Your CX16 may be bricked!"
    .byte 0
    info_text35: .text "Take a foto of this screen. And shut down power ..."
    .byte 0
    info_text36: .text "Update issues, your CX16 is not updated!"
    .byte 0
    info_text37: .text "Your CX16 update is a success!"
    .byte 0
    s15: .text "("
    .byte 0
    s16: .text ") Please read carefully the below ..."
    .byte 0
    s17: .text "Please disconnect your CX16 from power source ..."
    .byte 0
    s19: .text ") Your CX16 will reset ..."
    .byte 0
    .label main__52 = smc_supported_rom.return
    .label main__102 = rom_get_release.return
    .label main__103 = rom_get_prefix.return
    main__272: .byte 0
    main__274: .byte 0
    check_status_smc2_main__0: .byte 0
    check_status_smc4_main__0: .byte 0
    check_status_cx16_rom3_check_status_rom1_main__0: .byte 0
    check_status_smc5_main__0: .byte 0
    check_status_smc7_main__0: .byte 0
    check_status_vera3_main__0: .byte 0
    check_status_card_roms1_check_status_rom1_main__0: .byte 0
    check_status_vera4_main__0: .byte 0
    check_status_smc12_main__0: .byte 0
    check_status_vera5_main__0: .byte 0
    rom_chip: .byte 0
    rom_chip1: .byte 0
    intro_status: .byte 0
    .label check_status_smc2_return = check_status_smc2_main__0
    rom_chip2: .byte 0
    rom_bank: .byte 0
    file: .word 0
    .label rom_bytes_read = rom_read.return
    rom_file_modulo: .dword 0
    .label rom_file_release = rom_get_release.return
    .label rom_file_prefix = rom_get_prefix.return
    .label check_status_smc4_return = check_status_smc4_main__0
    .label check_status_cx16_rom3_check_status_rom1_return = check_status_cx16_rom3_check_status_rom1_main__0
    .label check_status_smc5_return = check_status_smc5_main__0
    check_status_roms1_rom_chip: .byte 0
    check_status_roms1_return: .byte 0
    check_status_roms2_rom_chip: .byte 0
    check_status_roms2_return: .byte 0
    .label ch = util_wait_key.return
    .label check_status_smc7_return = check_status_smc7_main__0
    .label check_status_vera3_return = check_status_vera3_main__0
    check_status_roms_all1_rom_chip: .byte 0
    check_status_roms_all1_return: .byte 0
    .label check_status_card_roms1_check_status_rom1_return = check_status_card_roms1_check_status_rom1_main__0
    check_status_card_roms1_rom_chip: .byte 0
    check_status_card_roms1_return: .byte 0
    rom_chip3: .byte 0
    .label flashed_bytes = smc_flash.return
    rom_chip4: .byte 0
    rom_bank1: .byte 0
    .label file1 = rom_file.return
    .label rom_bytes_read1 = rom_read.return
    rom_flash_errors: .dword 0
    .label check_status_vera4_return = check_status_vera4_main__0
    check_status_roms3_rom_chip: .byte 0
    check_status_roms3_return: .byte 0
    .label check_status_smc12_return = check_status_smc12_main__0
    .label check_status_vera5_return = check_status_vera5_main__0
    check_status_roms4_rom_chip: .byte 0
    check_status_roms4_return: .byte 0
    w: .byte 0
    w1: .byte 0
}
.segment Code
  // screenlayer1
// Set the layer with which the conio will interact.
screenlayer1: {
    // screenlayer(1, *VERA_L1_MAPBASE, *VERA_L1_CONFIG)
    // [734] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbuz1=_deref_pbuc1 
    lda VERA_L1_MAPBASE
    sta.z screenlayer.mapbase
    // [735] screenlayer::config#0 = *VERA_L1_CONFIG -- vbuz1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta.z screenlayer.config
    // [736] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [737] return 
    rts
}
  // textcolor
// Set the front color for text output. The old front text color setting is returned.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char textcolor(__zp($e0) char color)
textcolor: {
    .label textcolor__0 = $e4
    .label textcolor__1 = $e0
    .label color = $e0
    // __conio.color & 0xF0
    // [739] textcolor::$0 = *((char *)&__conio+$d) & $f0 -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$d
    sta.z textcolor__0
    // __conio.color & 0xF0 | color
    // [740] textcolor::$1 = textcolor::$0 | textcolor::color#18 -- vbuz1=vbuz2_bor_vbuz1 
    lda.z textcolor__1
    ora.z textcolor__0
    sta.z textcolor__1
    // __conio.color = __conio.color & 0xF0 | color
    // [741] *((char *)&__conio+$d) = textcolor::$1 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // textcolor::@return
    // }
    // [742] return 
    rts
}
  // bgcolor
// Set the back color for text output.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char bgcolor(__zp($e0) char color)
bgcolor: {
    .label bgcolor__0 = $e1
    .label bgcolor__1 = $e0
    .label bgcolor__2 = $e1
    .label color = $e0
    // __conio.color & 0x0F
    // [744] bgcolor::$0 = *((char *)&__conio+$d) & $f -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$d
    sta.z bgcolor__0
    // color << 4
    // [745] bgcolor::$1 = bgcolor::color#14 << 4 -- vbuz1=vbuz1_rol_4 
    lda.z bgcolor__1
    asl
    asl
    asl
    asl
    sta.z bgcolor__1
    // __conio.color & 0x0F | color << 4
    // [746] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbuz1=vbuz1_bor_vbuz2 
    lda.z bgcolor__2
    ora.z bgcolor__1
    sta.z bgcolor__2
    // __conio.color = __conio.color & 0x0F | color << 4
    // [747] *((char *)&__conio+$d) = bgcolor::$2 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // bgcolor::@return
    // }
    // [748] return 
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
    // [749] *((char *)&__conio+$c) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$c
    // cursor::@return
    // }
    // [750] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    // __mem unsigned char x
    // [751] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [752] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [754] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwum1=vbum2_word_vbum3 
    lda x
    sta return+1
    lda y
    sta return
    // cbm_k_plot_get::@return
    // }
    // [755] return 
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
    // [757] if(gotoxy::x#30>=*((char *)&__conio+6)) goto gotoxy::@1 -- vbuz1_ge__deref_pbuc1_then_la1 
    lda.z x
    cmp __conio+6
    bcs __b1
    // [759] phi from gotoxy gotoxy::@1 to gotoxy::@2 [phi:gotoxy/gotoxy::@1->gotoxy::@2]
    // [759] phi gotoxy::$3 = gotoxy::x#30 [phi:gotoxy/gotoxy::@1->gotoxy::@2#0] -- register_copy 
    jmp __b2
    // gotoxy::@1
  __b1:
    // [758] gotoxy::$2 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z gotoxy__2
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [760] *((char *)&__conio) = gotoxy::$3 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__3
    sta __conio
    // (y>=__conio.height)?__conio.height:y
    // [761] if(gotoxy::y#30>=*((char *)&__conio+7)) goto gotoxy::@3 -- vbuz1_ge__deref_pbuc1_then_la1 
    lda.z y
    cmp __conio+7
    bcs __b3
    // gotoxy::@4
    // [762] gotoxy::$14 = gotoxy::y#30 -- vbuz1=vbuz2 
    sta.z gotoxy__14
    // [763] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [763] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [764] *((char *)&__conio+1) = gotoxy::$7 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__7
    sta __conio+1
    // __conio.cursor_x << 1
    // [765] gotoxy::$8 = *((char *)&__conio) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio
    asl
    sta.z gotoxy__8
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [766] gotoxy::$10 = gotoxy::y#30 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z gotoxy__10
    // [767] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwuz1=pwuc1_derefidx_vbuz2_plus_vbuz3 
    ldy.z gotoxy__10
    clc
    adc __conio+$15,y
    sta.z gotoxy__9
    lda __conio+$15+1,y
    adc #0
    sta.z gotoxy__9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [768] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwuz1 
    lda.z gotoxy__9
    sta __conio+$13
    lda.z gotoxy__9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [769] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [770] gotoxy::$6 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
    lda __conio+7
    sta.z gotoxy__6
    jmp __b5
}
  // cputln
// Print a newline
cputln: {
    .label cputln__2 = $6f
    // __conio.cursor_x = 0
    // [771] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y++;
    // [772] *((char *)&__conio+1) = ++ *((char *)&__conio+1) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+1
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [773] cputln::$2 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z cputln__2
    // [774] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [775] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [776] return 
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
    // [778] call textcolor
  // Set the charset to lower case.
  // screenlayer1();
    // [738] phi from display_frame_init_64 to textcolor [phi:display_frame_init_64->textcolor]
    // [738] phi textcolor::color#18 = WHITE [phi:display_frame_init_64->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [779] phi from display_frame_init_64 to display_frame_init_64::@2 [phi:display_frame_init_64->display_frame_init_64::@2]
    // display_frame_init_64::@2
    // bgcolor(BLUE)
    // [780] call bgcolor
    // [743] phi from display_frame_init_64::@2 to bgcolor [phi:display_frame_init_64::@2->bgcolor]
    // [743] phi bgcolor::color#14 = BLUE [phi:display_frame_init_64::@2->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [781] phi from display_frame_init_64::@2 to display_frame_init_64::@3 [phi:display_frame_init_64::@2->display_frame_init_64::@3]
    // display_frame_init_64::@3
    // scroll(0)
    // [782] call scroll
    jsr scroll
    // [783] phi from display_frame_init_64::@3 to display_frame_init_64::@4 [phi:display_frame_init_64::@3->display_frame_init_64::@4]
    // display_frame_init_64::@4
    // clrscr()
    // [784] call clrscr
    jsr clrscr
    // display_frame_init_64::vera_display_set_hstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [785] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTART = start
    // [786] *VERA_DC_HSTART = display_frame_init_64::vera_display_set_hstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstart1_start
    sta VERA_DC_HSTART
    // display_frame_init_64::vera_display_set_hstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [787] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTOP = stop
    // [788] *VERA_DC_HSTOP = display_frame_init_64::vera_display_set_hstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstop1_stop
    sta VERA_DC_HSTOP
    // display_frame_init_64::vera_display_set_vstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [789] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTART = start
    // [790] *VERA_DC_VSTART = display_frame_init_64::vera_display_set_vstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstart1_start
    sta VERA_DC_VSTART
    // display_frame_init_64::vera_display_set_vstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [791] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTOP = stop
    // [792] *VERA_DC_VSTOP = display_frame_init_64::vera_display_set_vstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstop1_stop
    sta VERA_DC_VSTOP
    // display_frame_init_64::@1
    // cx16_k_screen_set_charset(3, (char *)0)
    // [793] display_frame_init_64::cx16_k_screen_set_charset1_charset = 3 -- vbum1=vbuc1 
    lda #3
    sta cx16_k_screen_set_charset1_charset
    // [794] display_frame_init_64::cx16_k_screen_set_charset1_offset = (char *) 0 -- pbum1=pbuc1 
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
    // [796] return 
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
    // [798] call textcolor
    // [738] phi from display_frame_draw to textcolor [phi:display_frame_draw->textcolor]
    // [738] phi textcolor::color#18 = LIGHT_BLUE [phi:display_frame_draw->textcolor#0] -- vbuz1=vbuc1 
    lda #LIGHT_BLUE
    sta.z textcolor.color
    jsr textcolor
    // [799] phi from display_frame_draw to display_frame_draw::@1 [phi:display_frame_draw->display_frame_draw::@1]
    // display_frame_draw::@1
    // bgcolor(BLUE)
    // [800] call bgcolor
    // [743] phi from display_frame_draw::@1 to bgcolor [phi:display_frame_draw::@1->bgcolor]
    // [743] phi bgcolor::color#14 = BLUE [phi:display_frame_draw::@1->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [801] phi from display_frame_draw::@1 to display_frame_draw::@2 [phi:display_frame_draw::@1->display_frame_draw::@2]
    // display_frame_draw::@2
    // clrscr()
    // [802] call clrscr
    jsr clrscr
    // [803] phi from display_frame_draw::@2 to display_frame_draw::@3 [phi:display_frame_draw::@2->display_frame_draw::@3]
    // display_frame_draw::@3
    // display_frame(0, 0, 67, 14)
    // [804] call display_frame
    // [1892] phi from display_frame_draw::@3 to display_frame [phi:display_frame_draw::@3->display_frame]
    // [1892] phi display_frame::y#0 = 0 [phi:display_frame_draw::@3->display_frame#0] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.y
    // [1892] phi display_frame::y1#16 = $e [phi:display_frame_draw::@3->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1892] phi display_frame::x#0 = 0 [phi:display_frame_draw::@3->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1892] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@3->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [805] phi from display_frame_draw::@3 to display_frame_draw::@4 [phi:display_frame_draw::@3->display_frame_draw::@4]
    // display_frame_draw::@4
    // display_frame(0, 0, 67, 2)
    // [806] call display_frame
    // [1892] phi from display_frame_draw::@4 to display_frame [phi:display_frame_draw::@4->display_frame]
    // [1892] phi display_frame::y#0 = 0 [phi:display_frame_draw::@4->display_frame#0] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.y
    // [1892] phi display_frame::y1#16 = 2 [phi:display_frame_draw::@4->display_frame#1] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y1
    // [1892] phi display_frame::x#0 = 0 [phi:display_frame_draw::@4->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1892] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@4->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [807] phi from display_frame_draw::@4 to display_frame_draw::@5 [phi:display_frame_draw::@4->display_frame_draw::@5]
    // display_frame_draw::@5
    // display_frame(0, 2, 67, 14)
    // [808] call display_frame
    // [1892] phi from display_frame_draw::@5 to display_frame [phi:display_frame_draw::@5->display_frame]
    // [1892] phi display_frame::y#0 = 2 [phi:display_frame_draw::@5->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1892] phi display_frame::y1#16 = $e [phi:display_frame_draw::@5->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1892] phi display_frame::x#0 = 0 [phi:display_frame_draw::@5->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1892] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@5->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [809] phi from display_frame_draw::@5 to display_frame_draw::@6 [phi:display_frame_draw::@5->display_frame_draw::@6]
    // display_frame_draw::@6
    // display_frame(0, 2, 8, 14)
    // [810] call display_frame
  // Chipset areas
    // [1892] phi from display_frame_draw::@6 to display_frame [phi:display_frame_draw::@6->display_frame]
    // [1892] phi display_frame::y#0 = 2 [phi:display_frame_draw::@6->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1892] phi display_frame::y1#16 = $e [phi:display_frame_draw::@6->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1892] phi display_frame::x#0 = 0 [phi:display_frame_draw::@6->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1892] phi display_frame::x1#16 = 8 [phi:display_frame_draw::@6->display_frame#3] -- vbuz1=vbuc1 
    lda #8
    sta.z display_frame.x1
    jsr display_frame
    // [811] phi from display_frame_draw::@6 to display_frame_draw::@7 [phi:display_frame_draw::@6->display_frame_draw::@7]
    // display_frame_draw::@7
    // display_frame(8, 2, 19, 14)
    // [812] call display_frame
    // [1892] phi from display_frame_draw::@7 to display_frame [phi:display_frame_draw::@7->display_frame]
    // [1892] phi display_frame::y#0 = 2 [phi:display_frame_draw::@7->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1892] phi display_frame::y1#16 = $e [phi:display_frame_draw::@7->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1892] phi display_frame::x#0 = 8 [phi:display_frame_draw::@7->display_frame#2] -- vbuz1=vbuc1 
    lda #8
    sta.z display_frame.x
    // [1892] phi display_frame::x1#16 = $13 [phi:display_frame_draw::@7->display_frame#3] -- vbuz1=vbuc1 
    lda #$13
    sta.z display_frame.x1
    jsr display_frame
    // [813] phi from display_frame_draw::@7 to display_frame_draw::@8 [phi:display_frame_draw::@7->display_frame_draw::@8]
    // display_frame_draw::@8
    // display_frame(19, 2, 25, 14)
    // [814] call display_frame
    // [1892] phi from display_frame_draw::@8 to display_frame [phi:display_frame_draw::@8->display_frame]
    // [1892] phi display_frame::y#0 = 2 [phi:display_frame_draw::@8->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1892] phi display_frame::y1#16 = $e [phi:display_frame_draw::@8->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1892] phi display_frame::x#0 = $13 [phi:display_frame_draw::@8->display_frame#2] -- vbuz1=vbuc1 
    lda #$13
    sta.z display_frame.x
    // [1892] phi display_frame::x1#16 = $19 [phi:display_frame_draw::@8->display_frame#3] -- vbuz1=vbuc1 
    lda #$19
    sta.z display_frame.x1
    jsr display_frame
    // [815] phi from display_frame_draw::@8 to display_frame_draw::@9 [phi:display_frame_draw::@8->display_frame_draw::@9]
    // display_frame_draw::@9
    // display_frame(25, 2, 31, 14)
    // [816] call display_frame
    // [1892] phi from display_frame_draw::@9 to display_frame [phi:display_frame_draw::@9->display_frame]
    // [1892] phi display_frame::y#0 = 2 [phi:display_frame_draw::@9->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1892] phi display_frame::y1#16 = $e [phi:display_frame_draw::@9->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1892] phi display_frame::x#0 = $19 [phi:display_frame_draw::@9->display_frame#2] -- vbuz1=vbuc1 
    lda #$19
    sta.z display_frame.x
    // [1892] phi display_frame::x1#16 = $1f [phi:display_frame_draw::@9->display_frame#3] -- vbuz1=vbuc1 
    lda #$1f
    sta.z display_frame.x1
    jsr display_frame
    // [817] phi from display_frame_draw::@9 to display_frame_draw::@10 [phi:display_frame_draw::@9->display_frame_draw::@10]
    // display_frame_draw::@10
    // display_frame(31, 2, 37, 14)
    // [818] call display_frame
    // [1892] phi from display_frame_draw::@10 to display_frame [phi:display_frame_draw::@10->display_frame]
    // [1892] phi display_frame::y#0 = 2 [phi:display_frame_draw::@10->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1892] phi display_frame::y1#16 = $e [phi:display_frame_draw::@10->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1892] phi display_frame::x#0 = $1f [phi:display_frame_draw::@10->display_frame#2] -- vbuz1=vbuc1 
    lda #$1f
    sta.z display_frame.x
    // [1892] phi display_frame::x1#16 = $25 [phi:display_frame_draw::@10->display_frame#3] -- vbuz1=vbuc1 
    lda #$25
    sta.z display_frame.x1
    jsr display_frame
    // [819] phi from display_frame_draw::@10 to display_frame_draw::@11 [phi:display_frame_draw::@10->display_frame_draw::@11]
    // display_frame_draw::@11
    // display_frame(37, 2, 43, 14)
    // [820] call display_frame
    // [1892] phi from display_frame_draw::@11 to display_frame [phi:display_frame_draw::@11->display_frame]
    // [1892] phi display_frame::y#0 = 2 [phi:display_frame_draw::@11->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1892] phi display_frame::y1#16 = $e [phi:display_frame_draw::@11->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1892] phi display_frame::x#0 = $25 [phi:display_frame_draw::@11->display_frame#2] -- vbuz1=vbuc1 
    lda #$25
    sta.z display_frame.x
    // [1892] phi display_frame::x1#16 = $2b [phi:display_frame_draw::@11->display_frame#3] -- vbuz1=vbuc1 
    lda #$2b
    sta.z display_frame.x1
    jsr display_frame
    // [821] phi from display_frame_draw::@11 to display_frame_draw::@12 [phi:display_frame_draw::@11->display_frame_draw::@12]
    // display_frame_draw::@12
    // display_frame(43, 2, 49, 14)
    // [822] call display_frame
    // [1892] phi from display_frame_draw::@12 to display_frame [phi:display_frame_draw::@12->display_frame]
    // [1892] phi display_frame::y#0 = 2 [phi:display_frame_draw::@12->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1892] phi display_frame::y1#16 = $e [phi:display_frame_draw::@12->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1892] phi display_frame::x#0 = $2b [phi:display_frame_draw::@12->display_frame#2] -- vbuz1=vbuc1 
    lda #$2b
    sta.z display_frame.x
    // [1892] phi display_frame::x1#16 = $31 [phi:display_frame_draw::@12->display_frame#3] -- vbuz1=vbuc1 
    lda #$31
    sta.z display_frame.x1
    jsr display_frame
    // [823] phi from display_frame_draw::@12 to display_frame_draw::@13 [phi:display_frame_draw::@12->display_frame_draw::@13]
    // display_frame_draw::@13
    // display_frame(49, 2, 55, 14)
    // [824] call display_frame
    // [1892] phi from display_frame_draw::@13 to display_frame [phi:display_frame_draw::@13->display_frame]
    // [1892] phi display_frame::y#0 = 2 [phi:display_frame_draw::@13->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1892] phi display_frame::y1#16 = $e [phi:display_frame_draw::@13->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1892] phi display_frame::x#0 = $31 [phi:display_frame_draw::@13->display_frame#2] -- vbuz1=vbuc1 
    lda #$31
    sta.z display_frame.x
    // [1892] phi display_frame::x1#16 = $37 [phi:display_frame_draw::@13->display_frame#3] -- vbuz1=vbuc1 
    lda #$37
    sta.z display_frame.x1
    jsr display_frame
    // [825] phi from display_frame_draw::@13 to display_frame_draw::@14 [phi:display_frame_draw::@13->display_frame_draw::@14]
    // display_frame_draw::@14
    // display_frame(55, 2, 61, 14)
    // [826] call display_frame
    // [1892] phi from display_frame_draw::@14 to display_frame [phi:display_frame_draw::@14->display_frame]
    // [1892] phi display_frame::y#0 = 2 [phi:display_frame_draw::@14->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1892] phi display_frame::y1#16 = $e [phi:display_frame_draw::@14->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1892] phi display_frame::x#0 = $37 [phi:display_frame_draw::@14->display_frame#2] -- vbuz1=vbuc1 
    lda #$37
    sta.z display_frame.x
    // [1892] phi display_frame::x1#16 = $3d [phi:display_frame_draw::@14->display_frame#3] -- vbuz1=vbuc1 
    lda #$3d
    sta.z display_frame.x1
    jsr display_frame
    // [827] phi from display_frame_draw::@14 to display_frame_draw::@15 [phi:display_frame_draw::@14->display_frame_draw::@15]
    // display_frame_draw::@15
    // display_frame(61, 2, 67, 14)
    // [828] call display_frame
    // [1892] phi from display_frame_draw::@15 to display_frame [phi:display_frame_draw::@15->display_frame]
    // [1892] phi display_frame::y#0 = 2 [phi:display_frame_draw::@15->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1892] phi display_frame::y1#16 = $e [phi:display_frame_draw::@15->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1892] phi display_frame::x#0 = $3d [phi:display_frame_draw::@15->display_frame#2] -- vbuz1=vbuc1 
    lda #$3d
    sta.z display_frame.x
    // [1892] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@15->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [829] phi from display_frame_draw::@15 to display_frame_draw::@16 [phi:display_frame_draw::@15->display_frame_draw::@16]
    // display_frame_draw::@16
    // display_frame(0, 14, 67, PROGRESS_Y-5)
    // [830] call display_frame
  // Progress area
    // [1892] phi from display_frame_draw::@16 to display_frame [phi:display_frame_draw::@16->display_frame]
    // [1892] phi display_frame::y#0 = $e [phi:display_frame_draw::@16->display_frame#0] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y
    // [1892] phi display_frame::y1#16 = PROGRESS_Y-5 [phi:display_frame_draw::@16->display_frame#1] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-5
    sta.z display_frame.y1
    // [1892] phi display_frame::x#0 = 0 [phi:display_frame_draw::@16->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1892] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@16->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [831] phi from display_frame_draw::@16 to display_frame_draw::@17 [phi:display_frame_draw::@16->display_frame_draw::@17]
    // display_frame_draw::@17
    // display_frame(0, PROGRESS_Y-5, 67, PROGRESS_Y-2)
    // [832] call display_frame
    // [1892] phi from display_frame_draw::@17 to display_frame [phi:display_frame_draw::@17->display_frame]
    // [1892] phi display_frame::y#0 = PROGRESS_Y-5 [phi:display_frame_draw::@17->display_frame#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-5
    sta.z display_frame.y
    // [1892] phi display_frame::y1#16 = PROGRESS_Y-2 [phi:display_frame_draw::@17->display_frame#1] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-2
    sta.z display_frame.y1
    // [1892] phi display_frame::x#0 = 0 [phi:display_frame_draw::@17->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1892] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@17->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [833] phi from display_frame_draw::@17 to display_frame_draw::@18 [phi:display_frame_draw::@17->display_frame_draw::@18]
    // display_frame_draw::@18
    // display_frame(0, PROGRESS_Y-2, 67, 49)
    // [834] call display_frame
    // [1892] phi from display_frame_draw::@18 to display_frame [phi:display_frame_draw::@18->display_frame]
    // [1892] phi display_frame::y#0 = PROGRESS_Y-2 [phi:display_frame_draw::@18->display_frame#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-2
    sta.z display_frame.y
    // [1892] phi display_frame::y1#16 = $31 [phi:display_frame_draw::@18->display_frame#1] -- vbuz1=vbuc1 
    lda #$31
    sta.z display_frame.y1
    // [1892] phi display_frame::x#0 = 0 [phi:display_frame_draw::@18->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1892] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@18->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [835] phi from display_frame_draw::@18 to display_frame_draw::@19 [phi:display_frame_draw::@18->display_frame_draw::@19]
    // display_frame_draw::@19
    // textcolor(WHITE)
    // [836] call textcolor
    // [738] phi from display_frame_draw::@19 to textcolor [phi:display_frame_draw::@19->textcolor]
    // [738] phi textcolor::color#18 = WHITE [phi:display_frame_draw::@19->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // display_frame_draw::@return
    // }
    // [837] return 
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
    // [839] call gotoxy
    // [756] phi from display_frame_title to gotoxy [phi:display_frame_title->gotoxy]
    // [756] phi gotoxy::y#30 = 1 [phi:display_frame_title->gotoxy#0] -- vbuz1=vbuc1 
    lda #1
    sta.z gotoxy.y
    // [756] phi gotoxy::x#30 = 2 [phi:display_frame_title->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // [840] phi from display_frame_title to display_frame_title::@1 [phi:display_frame_title->display_frame_title::@1]
    // display_frame_title::@1
    // printf("%-65s", title_text)
    // [841] call printf_string
    // [1165] phi from display_frame_title::@1 to printf_string [phi:display_frame_title::@1->printf_string]
    // [1165] phi printf_string::putc#22 = &cputc [phi:display_frame_title::@1->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1165] phi printf_string::str#22 = main::title_text [phi:display_frame_title::@1->printf_string#1] -- pbuz1=pbuc1 
    lda #<main.title_text
    sta.z printf_string.str
    lda #>main.title_text
    sta.z printf_string.str+1
    // [1165] phi printf_string::format_justify_left#22 = 1 [phi:display_frame_title::@1->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1165] phi printf_string::format_min_length#22 = $41 [phi:display_frame_title::@1->printf_string#3] -- vbuz1=vbuc1 
    lda #$41
    sta.z printf_string.format_min_length
    jsr printf_string
    // display_frame_title::@return
    // }
    // [842] return 
    rts
}
  // cputsxy
// Move cursor and output a NUL-terminated string
// Same as "gotoxy (x, y); puts (s);"
// void cputsxy(__zp($e7) char x, __zp($ea) char y, __zp($2d) const char *s)
cputsxy: {
    .label y = $ea
    .label s = $2d
    .label x = $e7
    // gotoxy(x, y)
    // [844] gotoxy::x#1 = cputsxy::x#4 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [845] gotoxy::y#1 = cputsxy::y#4 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [846] call gotoxy
    // [756] phi from cputsxy to gotoxy [phi:cputsxy->gotoxy]
    // [756] phi gotoxy::y#30 = gotoxy::y#1 [phi:cputsxy->gotoxy#0] -- register_copy 
    // [756] phi gotoxy::x#30 = gotoxy::x#1 [phi:cputsxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputsxy::@1
    // cputs(s)
    // [847] cputs::s#1 = cputsxy::s#4 -- pbuz1=pbuz2 
    lda.z s
    sta.z cputs.s
    lda.z s+1
    sta.z cputs.s+1
    // [848] call cputs
    // [2026] phi from cputsxy::@1 to cputs [phi:cputsxy::@1->cputs]
    jsr cputs
    // cputsxy::@return
    // }
    // [849] return 
    rts
}
  // display_action_progress
/**
 * @brief Print the progress at the action frame, which is the first line.
 * 
 * @param info_text The progress text to be displayed.
 */
// void display_action_progress(__zp($62) char *info_text)
display_action_progress: {
    .label x = $bb
    .label y = $c3
    .label info_text = $62
    // unsigned char x = wherex()
    // [851] call wherex
    jsr wherex
    // [852] wherex::return#2 = wherex::return#0
    // display_action_progress::@1
    // [853] display_action_progress::x#0 = wherex::return#2
    // unsigned char y = wherey()
    // [854] call wherey
    jsr wherey
    // [855] wherey::return#2 = wherey::return#0
    // display_action_progress::@2
    // [856] display_action_progress::y#0 = wherey::return#2
    // gotoxy(2, PROGRESS_Y-4)
    // [857] call gotoxy
    // [756] phi from display_action_progress::@2 to gotoxy [phi:display_action_progress::@2->gotoxy]
    // [756] phi gotoxy::y#30 = PROGRESS_Y-4 [phi:display_action_progress::@2->gotoxy#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-4
    sta.z gotoxy.y
    // [756] phi gotoxy::x#30 = 2 [phi:display_action_progress::@2->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // display_action_progress::@3
    // printf("%-65s", info_text)
    // [858] printf_string::str#1 = display_action_progress::info_text#18
    // [859] call printf_string
    // [1165] phi from display_action_progress::@3 to printf_string [phi:display_action_progress::@3->printf_string]
    // [1165] phi printf_string::putc#22 = &cputc [phi:display_action_progress::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1165] phi printf_string::str#22 = printf_string::str#1 [phi:display_action_progress::@3->printf_string#1] -- register_copy 
    // [1165] phi printf_string::format_justify_left#22 = 1 [phi:display_action_progress::@3->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1165] phi printf_string::format_min_length#22 = $41 [phi:display_action_progress::@3->printf_string#3] -- vbuz1=vbuc1 
    lda #$41
    sta.z printf_string.format_min_length
    jsr printf_string
    // display_action_progress::@4
    // gotoxy(x, y)
    // [860] gotoxy::x#10 = display_action_progress::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [861] gotoxy::y#10 = display_action_progress::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [862] call gotoxy
    // [756] phi from display_action_progress::@4 to gotoxy [phi:display_action_progress::@4->gotoxy]
    // [756] phi gotoxy::y#30 = gotoxy::y#10 [phi:display_action_progress::@4->gotoxy#0] -- register_copy 
    // [756] phi gotoxy::x#30 = gotoxy::x#10 [phi:display_action_progress::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_action_progress::@return
    // }
    // [863] return 
    rts
}
  // display_progress_clear
/**
 * @brief Clean the progress area for the flashing.
 */
display_progress_clear: {
    .const h = PROGRESS_Y+PROGRESS_H
    .label x = $35
    .label i = $ea
    .label y = $e7
    // textcolor(WHITE)
    // [865] call textcolor
    // [738] phi from display_progress_clear to textcolor [phi:display_progress_clear->textcolor]
    // [738] phi textcolor::color#18 = WHITE [phi:display_progress_clear->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [866] phi from display_progress_clear to display_progress_clear::@5 [phi:display_progress_clear->display_progress_clear::@5]
    // display_progress_clear::@5
    // bgcolor(BLUE)
    // [867] call bgcolor
    // [743] phi from display_progress_clear::@5 to bgcolor [phi:display_progress_clear::@5->bgcolor]
    // [743] phi bgcolor::color#14 = BLUE [phi:display_progress_clear::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [868] phi from display_progress_clear::@5 to display_progress_clear::@1 [phi:display_progress_clear::@5->display_progress_clear::@1]
    // [868] phi display_progress_clear::y#2 = PROGRESS_Y [phi:display_progress_clear::@5->display_progress_clear::@1#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // display_progress_clear::@1
  __b1:
    // while (y < h)
    // [869] if(display_progress_clear::y#2<display_progress_clear::h) goto display_progress_clear::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y
    cmp #h
    bcc __b4
    // display_progress_clear::@return
    // }
    // [870] return 
    rts
    // [871] phi from display_progress_clear::@1 to display_progress_clear::@2 [phi:display_progress_clear::@1->display_progress_clear::@2]
  __b4:
    // [871] phi display_progress_clear::x#2 = PROGRESS_X [phi:display_progress_clear::@1->display_progress_clear::@2#0] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z x
    // [871] phi display_progress_clear::i#2 = 0 [phi:display_progress_clear::@1->display_progress_clear::@2#1] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // display_progress_clear::@2
  __b2:
    // for(unsigned char i = 0; i < w; i++)
    // [872] if(display_progress_clear::i#2<PROGRESS_W) goto display_progress_clear::@3 -- vbuz1_lt_vbuc1_then_la1 
    lda.z i
    cmp #PROGRESS_W
    bcc __b3
    // display_progress_clear::@4
    // y++;
    // [873] display_progress_clear::y#1 = ++ display_progress_clear::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [868] phi from display_progress_clear::@4 to display_progress_clear::@1 [phi:display_progress_clear::@4->display_progress_clear::@1]
    // [868] phi display_progress_clear::y#2 = display_progress_clear::y#1 [phi:display_progress_clear::@4->display_progress_clear::@1#0] -- register_copy 
    jmp __b1
    // display_progress_clear::@3
  __b3:
    // cputcxy(x, y, ' ')
    // [874] cputcxy::x#12 = display_progress_clear::x#2 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [875] cputcxy::y#12 = display_progress_clear::y#2 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [876] call cputcxy
    // [2039] phi from display_progress_clear::@3 to cputcxy [phi:display_progress_clear::@3->cputcxy]
    // [2039] phi cputcxy::c#15 = ' ' [phi:display_progress_clear::@3->cputcxy#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z cputcxy.c
    // [2039] phi cputcxy::y#15 = cputcxy::y#12 [phi:display_progress_clear::@3->cputcxy#1] -- register_copy 
    // [2039] phi cputcxy::x#15 = cputcxy::x#12 [phi:display_progress_clear::@3->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_progress_clear::@6
    // x++;
    // [877] display_progress_clear::x#1 = ++ display_progress_clear::x#2 -- vbuz1=_inc_vbuz1 
    inc.z x
    // for(unsigned char i = 0; i < w; i++)
    // [878] display_progress_clear::i#1 = ++ display_progress_clear::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [871] phi from display_progress_clear::@6 to display_progress_clear::@2 [phi:display_progress_clear::@6->display_progress_clear::@2]
    // [871] phi display_progress_clear::x#2 = display_progress_clear::x#1 [phi:display_progress_clear::@6->display_progress_clear::@2#0] -- register_copy 
    // [871] phi display_progress_clear::i#2 = display_progress_clear::i#1 [phi:display_progress_clear::@6->display_progress_clear::@2#1] -- register_copy 
    jmp __b2
}
  // display_chip_smc
display_chip_smc: {
    // display_smc_led(GREY)
    // [880] call display_smc_led
    // [2047] phi from display_chip_smc to display_smc_led [phi:display_chip_smc->display_smc_led]
    // [2047] phi display_smc_led::c#2 = GREY [phi:display_chip_smc->display_smc_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z display_smc_led.c
    jsr display_smc_led
    // [881] phi from display_chip_smc to display_chip_smc::@1 [phi:display_chip_smc->display_chip_smc::@1]
    // display_chip_smc::@1
    // display_print_chip(CHIP_SMC_X, CHIP_SMC_Y+2, CHIP_SMC_W, "SMC     ")
    // [882] call display_print_chip
    // [2053] phi from display_chip_smc::@1 to display_print_chip [phi:display_chip_smc::@1->display_print_chip]
    // [2053] phi display_print_chip::text#11 = display_chip_smc::text [phi:display_chip_smc::@1->display_print_chip#0] -- pbum1=pbuc1 
    lda #<text
    sta display_print_chip.text_2
    lda #>text
    sta display_print_chip.text_2+1
    // [2053] phi display_print_chip::w#10 = 5 [phi:display_chip_smc::@1->display_print_chip#1] -- vbuz1=vbuc1 
    lda #5
    sta.z display_print_chip.w
    // [2053] phi display_print_chip::x#10 = 1 [phi:display_chip_smc::@1->display_print_chip#2] -- vbuz1=vbuc1 
    lda #1
    sta.z display_print_chip.x
    jsr display_print_chip
    // display_chip_smc::@return
    // }
    // [883] return 
    rts
  .segment Data
    text: .text "SMC     "
    .byte 0
}
.segment Code
  // display_chip_vera
display_chip_vera: {
    // display_vera_led(GREY)
    // [885] call display_vera_led
    // [2097] phi from display_chip_vera to display_vera_led [phi:display_chip_vera->display_vera_led]
    // [2097] phi display_vera_led::c#2 = GREY [phi:display_chip_vera->display_vera_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z display_vera_led.c
    jsr display_vera_led
    // [886] phi from display_chip_vera to display_chip_vera::@1 [phi:display_chip_vera->display_chip_vera::@1]
    // display_chip_vera::@1
    // display_print_chip(CHIP_VERA_X, CHIP_VERA_Y+2, CHIP_VERA_W, "VERA     ")
    // [887] call display_print_chip
    // [2053] phi from display_chip_vera::@1 to display_print_chip [phi:display_chip_vera::@1->display_print_chip]
    // [2053] phi display_print_chip::text#11 = display_chip_vera::text [phi:display_chip_vera::@1->display_print_chip#0] -- pbum1=pbuc1 
    lda #<text
    sta display_print_chip.text_2
    lda #>text
    sta display_print_chip.text_2+1
    // [2053] phi display_print_chip::w#10 = 8 [phi:display_chip_vera::@1->display_print_chip#1] -- vbuz1=vbuc1 
    lda #8
    sta.z display_print_chip.w
    // [2053] phi display_print_chip::x#10 = 9 [phi:display_chip_vera::@1->display_print_chip#2] -- vbuz1=vbuc1 
    lda #9
    sta.z display_print_chip.x
    jsr display_print_chip
    // display_chip_vera::@return
    // }
    // [888] return 
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
    .label display_chip_rom__4 = $bb
    .label display_chip_rom__6 = $df
    .label display_chip_rom__11 = $6d
    .label display_chip_rom__12 = $6d
    // [890] phi from display_chip_rom to display_chip_rom::@1 [phi:display_chip_rom->display_chip_rom::@1]
    // [890] phi display_chip_rom::r#2 = 0 [phi:display_chip_rom->display_chip_rom::@1#0] -- vbum1=vbuc1 
    lda #0
    sta r
    // display_chip_rom::@1
  __b1:
    // for (unsigned char r = 0; r < 8; r++)
    // [891] if(display_chip_rom::r#2<8) goto display_chip_rom::@2 -- vbum1_lt_vbuc1_then_la1 
    lda r
    cmp #8
    bcc __b2
    // display_chip_rom::@return
    // }
    // [892] return 
    rts
    // [893] phi from display_chip_rom::@1 to display_chip_rom::@2 [phi:display_chip_rom::@1->display_chip_rom::@2]
    // display_chip_rom::@2
  __b2:
    // strcpy(rom, "ROM  ")
    // [894] call strcpy
    // [979] phi from display_chip_rom::@2 to strcpy [phi:display_chip_rom::@2->strcpy]
    // [979] phi strcpy::dst#0 = display_chip_rom::rom [phi:display_chip_rom::@2->strcpy#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z strcpy.dst
    lda #>rom
    sta.z strcpy.dst+1
    // [979] phi strcpy::src#0 = display_chip_rom::source [phi:display_chip_rom::@2->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // display_chip_rom::@5
    // strcat(rom, rom_size_strings[r])
    // [895] display_chip_rom::$11 = display_chip_rom::r#2 << 1 -- vbuz1=vbum2_rol_1 
    lda r
    asl
    sta.z display_chip_rom__11
    // [896] strcat::source#0 = rom_size_strings[display_chip_rom::$11] -- pbum1=qbuc1_derefidx_vbuz2 
    tay
    lda rom_size_strings,y
    sta strcat.source
    lda rom_size_strings+1,y
    sta strcat.source+1
    // [897] call strcat
    // [2103] phi from display_chip_rom::@5 to strcat [phi:display_chip_rom::@5->strcat]
    jsr strcat
    // display_chip_rom::@6
    // if(r)
    // [898] if(0==display_chip_rom::r#2) goto display_chip_rom::@3 -- 0_eq_vbum1_then_la1 
    lda r
    beq __b3
    // display_chip_rom::@4
    // r+'0'
    // [899] display_chip_rom::$4 = display_chip_rom::r#2 + '0' -- vbuz1=vbum2_plus_vbuc1 
    lda #'0'
    clc
    adc r
    sta.z display_chip_rom__4
    // *(rom+3) = r+'0'
    // [900] *(display_chip_rom::rom+3) = display_chip_rom::$4 -- _deref_pbuc1=vbuz1 
    sta rom+3
    // display_chip_rom::@3
  __b3:
    // display_rom_led(r, GREY)
    // [901] display_rom_led::chip#0 = display_chip_rom::r#2 -- vbuz1=vbum2 
    lda r
    sta.z display_rom_led.chip
    // [902] call display_rom_led
    // [2115] phi from display_chip_rom::@3 to display_rom_led [phi:display_chip_rom::@3->display_rom_led]
    // [2115] phi display_rom_led::c#2 = GREY [phi:display_chip_rom::@3->display_rom_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z display_rom_led.c
    // [2115] phi display_rom_led::chip#2 = display_rom_led::chip#0 [phi:display_chip_rom::@3->display_rom_led#1] -- register_copy 
    jsr display_rom_led
    // display_chip_rom::@7
    // r*6
    // [903] display_chip_rom::$12 = display_chip_rom::$11 + display_chip_rom::r#2 -- vbuz1=vbuz1_plus_vbum2 
    lda r
    clc
    adc.z display_chip_rom__12
    sta.z display_chip_rom__12
    // [904] display_chip_rom::$6 = display_chip_rom::$12 << 1 -- vbuz1=vbuz2_rol_1 
    asl
    sta.z display_chip_rom__6
    // display_print_chip(CHIP_ROM_X+r*6, CHIP_ROM_Y+2, CHIP_ROM_W, rom)
    // [905] display_print_chip::x#2 = $14 + display_chip_rom::$6 -- vbuz1=vbuc1_plus_vbuz1 
    lda #$14
    clc
    adc.z display_print_chip.x
    sta.z display_print_chip.x
    // [906] call display_print_chip
    // [2053] phi from display_chip_rom::@7 to display_print_chip [phi:display_chip_rom::@7->display_print_chip]
    // [2053] phi display_print_chip::text#11 = display_chip_rom::rom [phi:display_chip_rom::@7->display_print_chip#0] -- pbum1=pbuc1 
    lda #<rom
    sta display_print_chip.text_2
    lda #>rom
    sta display_print_chip.text_2+1
    // [2053] phi display_print_chip::w#10 = 3 [phi:display_chip_rom::@7->display_print_chip#1] -- vbuz1=vbuc1 
    lda #3
    sta.z display_print_chip.w
    // [2053] phi display_print_chip::x#10 = display_print_chip::x#2 [phi:display_chip_rom::@7->display_print_chip#2] -- register_copy 
    jsr display_print_chip
    // display_chip_rom::@8
    // for (unsigned char r = 0; r < 8; r++)
    // [907] display_chip_rom::r#1 = ++ display_chip_rom::r#2 -- vbum1=_inc_vbum1 
    inc r
    // [890] phi from display_chip_rom::@8 to display_chip_rom::@1 [phi:display_chip_rom::@8->display_chip_rom::@1]
    // [890] phi display_chip_rom::r#2 = display_chip_rom::r#1 [phi:display_chip_rom::@8->display_chip_rom::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    rom: .fill $10, 0
    source: .text "ROM  "
    .byte 0
    .label r = rom_get_release.return
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
// void display_info_smc(__mem() char info_status, __zp($4d) char *info_text)
display_info_smc: {
    .label x = $e2
    .label y = $66
    .label info_text = $4d
    // unsigned char x = wherex()
    // [909] call wherex
    jsr wherex
    // [910] wherex::return#10 = wherex::return#0 -- vbuz1=vbuz2 
    lda.z wherex.return
    sta.z wherex.return_2
    // display_info_smc::@3
    // [911] display_info_smc::x#0 = wherex::return#10
    // unsigned char y = wherey()
    // [912] call wherey
    jsr wherey
    // [913] wherey::return#10 = wherey::return#0 -- vbuz1=vbuz2 
    lda.z wherey.return
    sta.z wherey.return_2
    // display_info_smc::@4
    // [914] display_info_smc::y#0 = wherey::return#10
    // status_smc = info_status
    // [915] status_smc#0 = display_info_smc::info_status#18 -- vbum1=vbum2 
    lda info_status
    sta status_smc
    // display_smc_led(status_color[info_status])
    // [916] display_smc_led::c#1 = status_color[display_info_smc::info_status#18] -- vbuz1=pbuc1_derefidx_vbum2 
    ldy info_status
    lda status_color,y
    sta.z display_smc_led.c
    // [917] call display_smc_led
    // [2047] phi from display_info_smc::@4 to display_smc_led [phi:display_info_smc::@4->display_smc_led]
    // [2047] phi display_smc_led::c#2 = display_smc_led::c#1 [phi:display_info_smc::@4->display_smc_led#0] -- register_copy 
    jsr display_smc_led
    // [918] phi from display_info_smc::@4 to display_info_smc::@5 [phi:display_info_smc::@4->display_info_smc::@5]
    // display_info_smc::@5
    // gotoxy(INFO_X, INFO_Y)
    // [919] call gotoxy
    // [756] phi from display_info_smc::@5 to gotoxy [phi:display_info_smc::@5->gotoxy]
    // [756] phi gotoxy::y#30 = $11 [phi:display_info_smc::@5->gotoxy#0] -- vbuz1=vbuc1 
    lda #$11
    sta.z gotoxy.y
    // [756] phi gotoxy::x#30 = 4 [phi:display_info_smc::@5->gotoxy#1] -- vbuz1=vbuc1 
    lda #4
    sta.z gotoxy.x
    jsr gotoxy
    // [920] phi from display_info_smc::@5 to display_info_smc::@6 [phi:display_info_smc::@5->display_info_smc::@6]
    // display_info_smc::@6
    // printf("SMC  %-9s ATTiny %-9s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [921] call printf_str
    // [1156] phi from display_info_smc::@6 to printf_str [phi:display_info_smc::@6->printf_str]
    // [1156] phi printf_str::putc#71 = &cputc [phi:display_info_smc::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = display_info_smc::s [phi:display_info_smc::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@7
    // printf("SMC  %-9s ATTiny %-9s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [922] display_info_smc::$8 = display_info_smc::info_status#18 << 1 -- vbum1=vbum1_rol_1 
    asl display_info_smc__8
    // [923] printf_string::str#3 = status_text[display_info_smc::$8] -- pbuz1=qbuc1_derefidx_vbum2 
    ldy display_info_smc__8
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [924] call printf_string
    // [1165] phi from display_info_smc::@7 to printf_string [phi:display_info_smc::@7->printf_string]
    // [1165] phi printf_string::putc#22 = &cputc [phi:display_info_smc::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1165] phi printf_string::str#22 = printf_string::str#3 [phi:display_info_smc::@7->printf_string#1] -- register_copy 
    // [1165] phi printf_string::format_justify_left#22 = 1 [phi:display_info_smc::@7->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1165] phi printf_string::format_min_length#22 = 9 [phi:display_info_smc::@7->printf_string#3] -- vbuz1=vbuc1 
    lda #9
    sta.z printf_string.format_min_length
    jsr printf_string
    // [925] phi from display_info_smc::@7 to display_info_smc::@8 [phi:display_info_smc::@7->display_info_smc::@8]
    // display_info_smc::@8
    // printf("SMC  %-9s ATTiny %-9s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [926] call printf_str
    // [1156] phi from display_info_smc::@8 to printf_str [phi:display_info_smc::@8->printf_str]
    // [1156] phi printf_str::putc#71 = &cputc [phi:display_info_smc::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = display_info_smc::s1 [phi:display_info_smc::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // [927] phi from display_info_smc::@8 to display_info_smc::@9 [phi:display_info_smc::@8->display_info_smc::@9]
    // display_info_smc::@9
    // printf("SMC  %-9s ATTiny %-9s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [928] call printf_string
    // [1165] phi from display_info_smc::@9 to printf_string [phi:display_info_smc::@9->printf_string]
    // [1165] phi printf_string::putc#22 = &cputc [phi:display_info_smc::@9->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1165] phi printf_string::str#22 = smc_version_text [phi:display_info_smc::@9->printf_string#1] -- pbuz1=pbuc1 
    lda #<smc_version_text
    sta.z printf_string.str
    lda #>smc_version_text
    sta.z printf_string.str+1
    // [1165] phi printf_string::format_justify_left#22 = 1 [phi:display_info_smc::@9->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1165] phi printf_string::format_min_length#22 = 9 [phi:display_info_smc::@9->printf_string#3] -- vbuz1=vbuc1 
    lda #9
    sta.z printf_string.format_min_length
    jsr printf_string
    // [929] phi from display_info_smc::@9 to display_info_smc::@10 [phi:display_info_smc::@9->display_info_smc::@10]
    // display_info_smc::@10
    // printf("SMC  %-9s ATTiny %-9s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [930] call printf_str
    // [1156] phi from display_info_smc::@10 to printf_str [phi:display_info_smc::@10->printf_str]
    // [1156] phi printf_str::putc#71 = &cputc [phi:display_info_smc::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = display_info_smc::s2 [phi:display_info_smc::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@11
    // printf("SMC  %-9s ATTiny %-9s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [931] printf_uint::uvalue#0 = smc_bootloader#13 -- vwuz1=vwum2 
    lda smc_bootloader_1
    sta.z printf_uint.uvalue
    lda smc_bootloader_1+1
    sta.z printf_uint.uvalue+1
    // [932] call printf_uint
    // [1810] phi from display_info_smc::@11 to printf_uint [phi:display_info_smc::@11->printf_uint]
    // [1810] phi printf_uint::format_zero_padding#14 = 0 [phi:display_info_smc::@11->printf_uint#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uint.format_zero_padding
    // [1810] phi printf_uint::format_min_length#14 = 0 [phi:display_info_smc::@11->printf_uint#1] -- vbuz1=vbuc1 
    sta.z printf_uint.format_min_length
    // [1810] phi printf_uint::putc#14 = &cputc [phi:display_info_smc::@11->printf_uint#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uint.putc
    lda #>cputc
    sta.z printf_uint.putc+1
    // [1810] phi printf_uint::format_radix#14 = DECIMAL [phi:display_info_smc::@11->printf_uint#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [1810] phi printf_uint::uvalue#14 = printf_uint::uvalue#0 [phi:display_info_smc::@11->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [933] phi from display_info_smc::@11 to display_info_smc::@12 [phi:display_info_smc::@11->display_info_smc::@12]
    // display_info_smc::@12
    // printf("SMC  %-9s ATTiny %-9s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [934] call printf_str
    // [1156] phi from display_info_smc::@12 to printf_str [phi:display_info_smc::@12->printf_str]
    // [1156] phi printf_str::putc#71 = &cputc [phi:display_info_smc::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = s [phi:display_info_smc::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s
    sta.z printf_str.s
    lda #>@s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@13
    // if(info_text)
    // [935] if((char *)0==display_info_smc::info_text#18) goto display_info_smc::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // display_info_smc::@2
    // printf("%-25s", info_text)
    // [936] printf_string::str#5 = display_info_smc::info_text#18 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [937] call printf_string
    // [1165] phi from display_info_smc::@2 to printf_string [phi:display_info_smc::@2->printf_string]
    // [1165] phi printf_string::putc#22 = &cputc [phi:display_info_smc::@2->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1165] phi printf_string::str#22 = printf_string::str#5 [phi:display_info_smc::@2->printf_string#1] -- register_copy 
    // [1165] phi printf_string::format_justify_left#22 = 1 [phi:display_info_smc::@2->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1165] phi printf_string::format_min_length#22 = $19 [phi:display_info_smc::@2->printf_string#3] -- vbuz1=vbuc1 
    lda #$19
    sta.z printf_string.format_min_length
    jsr printf_string
    // display_info_smc::@1
  __b1:
    // gotoxy(x, y)
    // [938] gotoxy::x#14 = display_info_smc::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [939] gotoxy::y#14 = display_info_smc::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [940] call gotoxy
    // [756] phi from display_info_smc::@1 to gotoxy [phi:display_info_smc::@1->gotoxy]
    // [756] phi gotoxy::y#30 = gotoxy::y#14 [phi:display_info_smc::@1->gotoxy#0] -- register_copy 
    // [756] phi gotoxy::x#30 = gotoxy::x#14 [phi:display_info_smc::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_smc::@return
    // }
    // [941] return 
    rts
  .segment Data
    s: .text "SMC  "
    .byte 0
    s1: .text " ATTiny "
    .byte 0
    s2: .text " BL:"
    .byte 0
    .label display_info_smc__8 = main.check_status_smc2_main__0
    .label info_status = main.check_status_smc2_main__0
}
.segment Code
  // display_info_vera
/**
 * @brief Display the VERA status at the info frame.
 * 
 * @param info_status The STATUS_ 
 */
// void display_info_vera(__mem() char info_status, __zp($bc) char *info_text)
display_info_vera: {
    .label x = $6b
    .label y = $e3
    .label info_text = $bc
    // unsigned char x = wherex()
    // [943] call wherex
    jsr wherex
    // [944] wherex::return#11 = wherex::return#0 -- vbuz1=vbuz2 
    lda.z wherex.return
    sta.z wherex.return_3
    // display_info_vera::@3
    // [945] display_info_vera::x#0 = wherex::return#11
    // unsigned char y = wherey()
    // [946] call wherey
    jsr wherey
    // [947] wherey::return#11 = wherey::return#0 -- vbuz1=vbuz2 
    lda.z wherey.return
    sta.z wherey.return_3
    // display_info_vera::@4
    // [948] display_info_vera::y#0 = wherey::return#11
    // status_vera = info_status
    // [949] status_vera#0 = display_info_vera::info_status#3 -- vbum1=vbum2 
    lda info_status
    sta status_vera
    // display_vera_led(status_color[info_status])
    // [950] display_vera_led::c#1 = status_color[display_info_vera::info_status#3] -- vbuz1=pbuc1_derefidx_vbum2 
    ldy info_status
    lda status_color,y
    sta.z display_vera_led.c
    // [951] call display_vera_led
    // [2097] phi from display_info_vera::@4 to display_vera_led [phi:display_info_vera::@4->display_vera_led]
    // [2097] phi display_vera_led::c#2 = display_vera_led::c#1 [phi:display_info_vera::@4->display_vera_led#0] -- register_copy 
    jsr display_vera_led
    // [952] phi from display_info_vera::@4 to display_info_vera::@5 [phi:display_info_vera::@4->display_info_vera::@5]
    // display_info_vera::@5
    // gotoxy(INFO_X, INFO_Y+1)
    // [953] call gotoxy
    // [756] phi from display_info_vera::@5 to gotoxy [phi:display_info_vera::@5->gotoxy]
    // [756] phi gotoxy::y#30 = $11+1 [phi:display_info_vera::@5->gotoxy#0] -- vbuz1=vbuc1 
    lda #$11+1
    sta.z gotoxy.y
    // [756] phi gotoxy::x#30 = 4 [phi:display_info_vera::@5->gotoxy#1] -- vbuz1=vbuc1 
    lda #4
    sta.z gotoxy.x
    jsr gotoxy
    // [954] phi from display_info_vera::@5 to display_info_vera::@6 [phi:display_info_vera::@5->display_info_vera::@6]
    // display_info_vera::@6
    // printf("VERA %-9s FPGA                 ", status_text[info_status])
    // [955] call printf_str
    // [1156] phi from display_info_vera::@6 to printf_str [phi:display_info_vera::@6->printf_str]
    // [1156] phi printf_str::putc#71 = &cputc [phi:display_info_vera::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = display_info_vera::s [phi:display_info_vera::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@7
    // printf("VERA %-9s FPGA                 ", status_text[info_status])
    // [956] display_info_vera::$8 = display_info_vera::info_status#3 << 1 -- vbum1=vbum1_rol_1 
    asl display_info_vera__8
    // [957] printf_string::str#6 = status_text[display_info_vera::$8] -- pbuz1=qbuc1_derefidx_vbum2 
    ldy display_info_vera__8
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [958] call printf_string
    // [1165] phi from display_info_vera::@7 to printf_string [phi:display_info_vera::@7->printf_string]
    // [1165] phi printf_string::putc#22 = &cputc [phi:display_info_vera::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1165] phi printf_string::str#22 = printf_string::str#6 [phi:display_info_vera::@7->printf_string#1] -- register_copy 
    // [1165] phi printf_string::format_justify_left#22 = 1 [phi:display_info_vera::@7->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1165] phi printf_string::format_min_length#22 = 9 [phi:display_info_vera::@7->printf_string#3] -- vbuz1=vbuc1 
    lda #9
    sta.z printf_string.format_min_length
    jsr printf_string
    // [959] phi from display_info_vera::@7 to display_info_vera::@8 [phi:display_info_vera::@7->display_info_vera::@8]
    // display_info_vera::@8
    // printf("VERA %-9s FPGA                 ", status_text[info_status])
    // [960] call printf_str
    // [1156] phi from display_info_vera::@8 to printf_str [phi:display_info_vera::@8->printf_str]
    // [1156] phi printf_str::putc#71 = &cputc [phi:display_info_vera::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = display_info_vera::s1 [phi:display_info_vera::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@9
    // if(info_text)
    // [961] if((char *)0==display_info_vera::info_text#10) goto display_info_vera::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // display_info_vera::@2
    // printf("%-25s", info_text)
    // [962] printf_string::str#7 = display_info_vera::info_text#10 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [963] call printf_string
    // [1165] phi from display_info_vera::@2 to printf_string [phi:display_info_vera::@2->printf_string]
    // [1165] phi printf_string::putc#22 = &cputc [phi:display_info_vera::@2->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1165] phi printf_string::str#22 = printf_string::str#7 [phi:display_info_vera::@2->printf_string#1] -- register_copy 
    // [1165] phi printf_string::format_justify_left#22 = 1 [phi:display_info_vera::@2->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1165] phi printf_string::format_min_length#22 = $19 [phi:display_info_vera::@2->printf_string#3] -- vbuz1=vbuc1 
    lda #$19
    sta.z printf_string.format_min_length
    jsr printf_string
    // display_info_vera::@1
  __b1:
    // gotoxy(x, y)
    // [964] gotoxy::x#16 = display_info_vera::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [965] gotoxy::y#16 = display_info_vera::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [966] call gotoxy
    // [756] phi from display_info_vera::@1 to gotoxy [phi:display_info_vera::@1->gotoxy]
    // [756] phi gotoxy::y#30 = gotoxy::y#16 [phi:display_info_vera::@1->gotoxy#0] -- register_copy 
    // [756] phi gotoxy::x#30 = gotoxy::x#16 [phi:display_info_vera::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_vera::@return
    // }
    // [967] return 
    rts
  .segment Data
    s: .text "VERA "
    .byte 0
    s1: .text " FPGA                 "
    .byte 0
    .label display_info_vera__8 = rom_get_prefix.return
    .label info_status = rom_get_prefix.return
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
    .label smc_detect__1 = $c3
    // When the bootloader is not present, 0xFF is returned.
    .label smc_bootloader_version = $2d
    .label return = $2d
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [968] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [969] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [970] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [971] cx16_k_i2c_read_byte::return#10 = cx16_k_i2c_read_byte::return#1
    // smc_detect::@3
    // smc_bootloader_version = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [972] smc_detect::smc_bootloader_version#1 = cx16_k_i2c_read_byte::return#10
    // BYTE1(smc_bootloader_version)
    // [973] smc_detect::$1 = byte1  smc_detect::smc_bootloader_version#1 -- vbuz1=_byte1_vwuz2 
    lda.z smc_bootloader_version+1
    sta.z smc_detect__1
    // if(!BYTE1(smc_bootloader_version))
    // [974] if(0==smc_detect::$1) goto smc_detect::@1 -- 0_eq_vbuz1_then_la1 
    beq __b1
    // [977] phi from smc_detect::@3 to smc_detect::@2 [phi:smc_detect::@3->smc_detect::@2]
    // [977] phi smc_detect::return#0 = $200 [phi:smc_detect::@3->smc_detect::@2#0] -- vwuz1=vwuc1 
    lda #<$200
    sta.z return
    lda #>$200
    sta.z return+1
    rts
    // smc_detect::@1
  __b1:
    // if(smc_bootloader_version == 0xFF)
    // [975] if(smc_detect::smc_bootloader_version#1!=$ff) goto smc_detect::@4 -- vwuz1_neq_vbuc1_then_la1 
    lda.z smc_bootloader_version+1
    bne __b2
    lda.z smc_bootloader_version
    cmp #$ff
    bne __b2
    // [977] phi from smc_detect::@1 to smc_detect::@2 [phi:smc_detect::@1->smc_detect::@2]
    // [977] phi smc_detect::return#0 = $100 [phi:smc_detect::@1->smc_detect::@2#0] -- vwuz1=vwuc1 
    lda #<$100
    sta.z return
    lda #>$100
    sta.z return+1
    rts
    // [976] phi from smc_detect::@1 to smc_detect::@4 [phi:smc_detect::@1->smc_detect::@4]
    // smc_detect::@4
    // [977] phi from smc_detect::@4 to smc_detect::@2 [phi:smc_detect::@4->smc_detect::@2]
    // [977] phi smc_detect::return#0 = smc_detect::smc_bootloader_version#1 [phi:smc_detect::@4->smc_detect::@2#0] -- register_copy 
    // smc_detect::@2
  __b2:
    // smc_detect::@return
    // }
    // [978] return 
    rts
}
  // strcpy
// Copies the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcpy(__zp($4d) char *destination, char *source)
strcpy: {
    .label src = $62
    .label dst = $4d
    .label destination = $4d
    // [980] phi from strcpy strcpy::@2 to strcpy::@1 [phi:strcpy/strcpy::@2->strcpy::@1]
    // [980] phi strcpy::dst#2 = strcpy::dst#0 [phi:strcpy/strcpy::@2->strcpy::@1#0] -- register_copy 
    // [980] phi strcpy::src#2 = strcpy::src#0 [phi:strcpy/strcpy::@2->strcpy::@1#1] -- register_copy 
    // strcpy::@1
  __b1:
    // while(*src)
    // [981] if(0!=*strcpy::src#2) goto strcpy::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcpy::@3
    // *dst = 0
    // [982] *strcpy::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcpy::@return
    // }
    // [983] return 
    rts
    // strcpy::@2
  __b2:
    // *dst++ = *src++
    // [984] *strcpy::dst#2 = *strcpy::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [985] strcpy::dst#1 = ++ strcpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [986] strcpy::src#1 = ++ strcpy::src#2 -- pbuz1=_inc_pbuz1 
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
// __zp($2d) unsigned int cx16_k_i2c_read_byte(__mem() volatile char device, __mem() volatile char offset)
cx16_k_i2c_read_byte: {
    .label return = $2d
    // unsigned int result
    // [987] cx16_k_i2c_read_byte::result = 0 -- vwum1=vwuc1 
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
    // [989] cx16_k_i2c_read_byte::return#0 = cx16_k_i2c_read_byte::result -- vwuz1=vwum2 
    sta.z return
    lda result+1
    sta.z return+1
    // cx16_k_i2c_read_byte::@return
    // }
    // [990] cx16_k_i2c_read_byte::return#1 = cx16_k_i2c_read_byte::return#0
    // [991] return 
    rts
  .segment Data
    device: .byte 0
    offset: .byte 0
    result: .word 0
}
.segment Code
  // smc_get_version_text
/**
 * @brief Detect and write the SMC version number into the info_text.
 * 
 * @param version_string The string containing the SMC version filled upon return.
 */
// unsigned long smc_get_version_text(__zp($bc) char *version_string, __zp($2f) char release, __zp($35) char major, __zp($37) char minor)
smc_get_version_text: {
    .label release = $2f
    .label major = $35
    .label minor = $37
    .label version_string = $bc
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [993] snprintf_init::s#0 = smc_get_version_text::version_string#2
    // [994] call snprintf_init
    // [1151] phi from smc_get_version_text to snprintf_init [phi:smc_get_version_text->snprintf_init]
    // [1151] phi snprintf_init::s#26 = snprintf_init::s#0 [phi:smc_get_version_text->snprintf_init#0] -- register_copy 
    jsr snprintf_init
    // smc_get_version_text::@1
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [995] printf_uchar::uvalue#1 = smc_get_version_text::release#2
    // [996] call printf_uchar
    // [1236] phi from smc_get_version_text::@1 to printf_uchar [phi:smc_get_version_text::@1->printf_uchar]
    // [1236] phi printf_uchar::format_zero_padding#14 = 0 [phi:smc_get_version_text::@1->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1236] phi printf_uchar::format_min_length#14 = 0 [phi:smc_get_version_text::@1->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1236] phi printf_uchar::putc#14 = &snputc [phi:smc_get_version_text::@1->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1236] phi printf_uchar::format_radix#14 = DECIMAL [phi:smc_get_version_text::@1->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1236] phi printf_uchar::uvalue#14 = printf_uchar::uvalue#1 [phi:smc_get_version_text::@1->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [997] phi from smc_get_version_text::@1 to smc_get_version_text::@2 [phi:smc_get_version_text::@1->smc_get_version_text::@2]
    // smc_get_version_text::@2
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [998] call printf_str
    // [1156] phi from smc_get_version_text::@2 to printf_str [phi:smc_get_version_text::@2->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:smc_get_version_text::@2->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = smc_get_version_text::s [phi:smc_get_version_text::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_get_version_text::@3
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [999] printf_uchar::uvalue#2 = smc_get_version_text::major#2 -- vbuz1=vbuz2 
    lda.z major
    sta.z printf_uchar.uvalue
    // [1000] call printf_uchar
    // [1236] phi from smc_get_version_text::@3 to printf_uchar [phi:smc_get_version_text::@3->printf_uchar]
    // [1236] phi printf_uchar::format_zero_padding#14 = 0 [phi:smc_get_version_text::@3->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1236] phi printf_uchar::format_min_length#14 = 0 [phi:smc_get_version_text::@3->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1236] phi printf_uchar::putc#14 = &snputc [phi:smc_get_version_text::@3->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1236] phi printf_uchar::format_radix#14 = DECIMAL [phi:smc_get_version_text::@3->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1236] phi printf_uchar::uvalue#14 = printf_uchar::uvalue#2 [phi:smc_get_version_text::@3->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1001] phi from smc_get_version_text::@3 to smc_get_version_text::@4 [phi:smc_get_version_text::@3->smc_get_version_text::@4]
    // smc_get_version_text::@4
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [1002] call printf_str
    // [1156] phi from smc_get_version_text::@4 to printf_str [phi:smc_get_version_text::@4->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:smc_get_version_text::@4->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = smc_get_version_text::s [phi:smc_get_version_text::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_get_version_text::@5
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [1003] printf_uchar::uvalue#3 = smc_get_version_text::minor#2 -- vbuz1=vbuz2 
    lda.z minor
    sta.z printf_uchar.uvalue
    // [1004] call printf_uchar
    // [1236] phi from smc_get_version_text::@5 to printf_uchar [phi:smc_get_version_text::@5->printf_uchar]
    // [1236] phi printf_uchar::format_zero_padding#14 = 0 [phi:smc_get_version_text::@5->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1236] phi printf_uchar::format_min_length#14 = 0 [phi:smc_get_version_text::@5->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1236] phi printf_uchar::putc#14 = &snputc [phi:smc_get_version_text::@5->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1236] phi printf_uchar::format_radix#14 = DECIMAL [phi:smc_get_version_text::@5->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1236] phi printf_uchar::uvalue#14 = printf_uchar::uvalue#3 [phi:smc_get_version_text::@5->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // smc_get_version_text::@6
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [1005] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1006] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_get_version_text::@return
    // }
    // [1008] return 
    rts
  .segment Data
    s: .text "."
    .byte 0
}
.segment Code
  // rom_detect
rom_detect: {
    .const bank_set_brom1_bank = 4
    .label rom_detect__3 = $6d
    .label rom_detect__5 = $6d
    .label rom_detect__9 = $e2
    .label rom_detect__14 = $6e
    .label rom_detect__18 = $e3
    .label rom_detect__21 = $6b
    .label rom_detect__24 = $66
    .label rom_detect_address = $30
    // [1010] phi from rom_detect to rom_detect::@1 [phi:rom_detect->rom_detect::@1]
    // [1010] phi rom_detect::rom_chip#10 = 0 [phi:rom_detect->rom_detect::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // [1010] phi rom_detect::rom_detect_address#10 = 0 [phi:rom_detect->rom_detect::@1#1] -- vduz1=vduc1 
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
    // [1011] if(rom_detect::rom_detect_address#10<8*$80000) goto rom_detect::@2 -- vduz1_lt_vduc1_then_la1 
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
    // [1012] return 
    rts
    // rom_detect::@2
  __b2:
    // rom_manufacturer_ids[rom_chip] = 0
    // [1013] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = 0
    // [1014] rom_device_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta rom_device_ids,y
    // rom_unlock(rom_detect_address + 0x05555, 0x90)
    // [1015] rom_unlock::address#2 = rom_detect::rom_detect_address#10 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [1016] call rom_unlock
    // [2126] phi from rom_detect::@2 to rom_unlock [phi:rom_detect::@2->rom_unlock]
    // [2126] phi rom_unlock::unlock_code#5 = $90 [phi:rom_detect::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$90
    sta.z rom_unlock.unlock_code
    // [2126] phi rom_unlock::address#5 = rom_unlock::address#2 [phi:rom_detect::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_detect::@12
    // rom_read_byte(rom_detect_address)
    // [1017] rom_read_byte::address#0 = rom_detect::rom_detect_address#10 -- vduz1=vduz2 
    lda.z rom_detect_address
    sta.z rom_read_byte.address
    lda.z rom_detect_address+1
    sta.z rom_read_byte.address+1
    lda.z rom_detect_address+2
    sta.z rom_read_byte.address+2
    lda.z rom_detect_address+3
    sta.z rom_read_byte.address+3
    // [1018] call rom_read_byte
    // [2136] phi from rom_detect::@12 to rom_read_byte [phi:rom_detect::@12->rom_read_byte]
    // [2136] phi rom_read_byte::address#2 = rom_read_byte::address#0 [phi:rom_detect::@12->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(rom_detect_address)
    // [1019] rom_read_byte::return#2 = rom_read_byte::return#0
    // rom_detect::@13
    // [1020] rom_detect::$3 = rom_read_byte::return#2
    // rom_manufacturer_ids[rom_chip] = rom_read_byte(rom_detect_address)
    // [1021] rom_manufacturer_ids[rom_detect::rom_chip#10] = rom_detect::$3 -- pbuc1_derefidx_vbum1=vbuz2 
    lda.z rom_detect__3
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_read_byte(rom_detect_address + 1)
    // [1022] rom_read_byte::address#1 = rom_detect::rom_detect_address#10 + 1 -- vduz1=vduz2_plus_1 
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
    // [1023] call rom_read_byte
    // [2136] phi from rom_detect::@13 to rom_read_byte [phi:rom_detect::@13->rom_read_byte]
    // [2136] phi rom_read_byte::address#2 = rom_read_byte::address#1 [phi:rom_detect::@13->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(rom_detect_address + 1)
    // [1024] rom_read_byte::return#3 = rom_read_byte::return#0
    // rom_detect::@14
    // [1025] rom_detect::$5 = rom_read_byte::return#3
    // rom_device_ids[rom_chip] = rom_read_byte(rom_detect_address + 1)
    // [1026] rom_device_ids[rom_detect::rom_chip#10] = rom_detect::$5 -- pbuc1_derefidx_vbum1=vbuz2 
    lda.z rom_detect__5
    ldy rom_chip
    sta rom_device_ids,y
    // rom_unlock(rom_detect_address + 0x05555, 0xF0)
    // [1027] rom_unlock::address#3 = rom_detect::rom_detect_address#10 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [1028] call rom_unlock
    // [2126] phi from rom_detect::@14 to rom_unlock [phi:rom_detect::@14->rom_unlock]
    // [2126] phi rom_unlock::unlock_code#5 = $f0 [phi:rom_detect::@14->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$f0
    sta.z rom_unlock.unlock_code
    // [2126] phi rom_unlock::address#5 = rom_unlock::address#3 [phi:rom_detect::@14->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_detect::bank_set_brom1
    // BROM = bank
    // [1029] BROM = rom_detect::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // rom_detect::@11
    // rom_chip*3
    // [1030] rom_detect::$14 = rom_detect::rom_chip#10 << 1 -- vbuz1=vbum2_rol_1 
    lda rom_chip
    asl
    sta.z rom_detect__14
    // [1031] rom_detect::$9 = rom_detect::$14 + rom_detect::rom_chip#10 -- vbuz1=vbuz2_plus_vbum3 
    lda rom_chip
    clc
    adc.z rom_detect__14
    sta.z rom_detect__9
    // gotoxy(rom_chip*3+40, 1)
    // [1032] gotoxy::x#23 = rom_detect::$9 + $28 -- vbuz1=vbuz2_plus_vbuc1 
    lda #$28
    clc
    adc.z rom_detect__9
    sta.z gotoxy.x
    // [1033] call gotoxy
    // [756] phi from rom_detect::@11 to gotoxy [phi:rom_detect::@11->gotoxy]
    // [756] phi gotoxy::y#30 = 1 [phi:rom_detect::@11->gotoxy#0] -- vbuz1=vbuc1 
    lda #1
    sta.z gotoxy.y
    // [756] phi gotoxy::x#30 = gotoxy::x#23 [phi:rom_detect::@11->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_detect::@15
    // printf("%02x", rom_device_ids[rom_chip])
    // [1034] printf_uchar::uvalue#8 = rom_device_ids[rom_detect::rom_chip#10] -- vbuz1=pbuc1_derefidx_vbum2 
    ldy rom_chip
    lda rom_device_ids,y
    sta.z printf_uchar.uvalue
    // [1035] call printf_uchar
    // [1236] phi from rom_detect::@15 to printf_uchar [phi:rom_detect::@15->printf_uchar]
    // [1236] phi printf_uchar::format_zero_padding#14 = 1 [phi:rom_detect::@15->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1236] phi printf_uchar::format_min_length#14 = 2 [phi:rom_detect::@15->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [1236] phi printf_uchar::putc#14 = &cputc [phi:rom_detect::@15->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1236] phi printf_uchar::format_radix#14 = HEXADECIMAL [phi:rom_detect::@15->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [1236] phi printf_uchar::uvalue#14 = printf_uchar::uvalue#8 [phi:rom_detect::@15->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // rom_detect::@16
    // case SST39SF010A:
    //             rom_device_names[rom_chip] = "f010a";
    //             rom_size_strings[rom_chip] = "128";
    //             rom_sizes[rom_chip] = 128 * 1024;
    //             break;
    // [1036] if(rom_device_ids[rom_detect::rom_chip#10]==$b5) goto rom_detect::@3 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
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
    // [1037] if(rom_device_ids[rom_detect::rom_chip#10]==$b6) goto rom_detect::@4 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
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
    // [1038] if(rom_device_ids[rom_detect::rom_chip#10]==$b7) goto rom_detect::@5 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b7
    beq __b5
    // rom_detect::@6
    // rom_manufacturer_ids[rom_chip] = 0
    // [1039] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    sta rom_manufacturer_ids,y
    // rom_device_names[rom_chip] = "----"
    // [1040] rom_device_names[rom_detect::$14] = rom_detect::$31 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__14
    lda #<rom_detect__31
    sta rom_device_names,y
    lda #>rom_detect__31
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "000"
    // [1041] rom_size_strings[rom_detect::$14] = rom_detect::$32 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__32
    sta rom_size_strings,y
    lda #>rom_detect__32
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 0
    // [1042] rom_detect::$24 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__24
    // [1043] rom_sizes[rom_detect::$24] = 0 -- pduc1_derefidx_vbuz1=vbuc2 
    tay
    lda #0
    sta rom_sizes,y
    sta rom_sizes+1,y
    sta rom_sizes+2,y
    sta rom_sizes+3,y
    // rom_device_ids[rom_chip] = UNKNOWN
    // [1044] rom_device_ids[rom_detect::rom_chip#10] = $55 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$55
    ldy rom_chip
    sta rom_device_ids,y
    // rom_detect::@7
  __b7:
    // rom_chip++;
    // [1045] rom_detect::rom_chip#1 = ++ rom_detect::rom_chip#10 -- vbum1=_inc_vbum1 
    inc rom_chip
    // rom_detect::@8
    // rom_detect_address += 0x80000
    // [1046] rom_detect::rom_detect_address#1 = rom_detect::rom_detect_address#10 + $80000 -- vduz1=vduz1_plus_vduc1 
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
    // [1010] phi from rom_detect::@8 to rom_detect::@1 [phi:rom_detect::@8->rom_detect::@1]
    // [1010] phi rom_detect::rom_chip#10 = rom_detect::rom_chip#1 [phi:rom_detect::@8->rom_detect::@1#0] -- register_copy 
    // [1010] phi rom_detect::rom_detect_address#10 = rom_detect::rom_detect_address#1 [phi:rom_detect::@8->rom_detect::@1#1] -- register_copy 
    jmp __b1
    // rom_detect::@5
  __b5:
    // rom_device_names[rom_chip] = "f040"
    // [1047] rom_device_names[rom_detect::$14] = rom_detect::$29 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__14
    lda #<rom_detect__29
    sta rom_device_names,y
    lda #>rom_detect__29
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "512"
    // [1048] rom_size_strings[rom_detect::$14] = rom_detect::$30 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__30
    sta rom_size_strings,y
    lda #>rom_detect__30
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 512 * 1024
    // [1049] rom_detect::$21 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__21
    // [1050] rom_sizes[rom_detect::$21] = (unsigned long)$200*$400 -- pduc1_derefidx_vbuz1=vduc2 
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
    // [1051] rom_device_names[rom_detect::$14] = rom_detect::$27 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__14
    lda #<rom_detect__27
    sta rom_device_names,y
    lda #>rom_detect__27
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "256"
    // [1052] rom_size_strings[rom_detect::$14] = rom_detect::$28 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__28
    sta rom_size_strings,y
    lda #>rom_detect__28
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 256 * 1024
    // [1053] rom_detect::$18 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__18
    // [1054] rom_sizes[rom_detect::$18] = (unsigned long)$100*$400 -- pduc1_derefidx_vbuz1=vduc2 
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
    // [1055] rom_device_names[rom_detect::$14] = rom_detect::$25 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__14
    lda #<rom_detect__25
    sta rom_device_names,y
    lda #>rom_detect__25
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "128"
    // [1056] rom_size_strings[rom_detect::$14] = rom_detect::$26 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__26
    sta rom_size_strings,y
    lda #>rom_detect__26
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 128 * 1024
    // [1057] rom_detect::$15 = rom_detect::rom_chip#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta rom_detect__15
    // [1058] rom_sizes[rom_detect::$15] = (unsigned long)$80*$400 -- pduc1_derefidx_vbum1=vduc2 
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
    .label rom_detect__15 = rom_get_release.rom_get_release__0
    .label rom_chip = smc_supported_rom.return
}
.segment Code
  // display_progress_text
/**
 * @brief Print a block of text within the progress frame with a count of lines.
 * 
 * @param text A pointer to an array of strings to be displayed (char**).
 * @param lines The amount of lines to be displayed, starting from the top of the progress frame.
 */
// void display_progress_text(__zp($5e) char **text, __zp($37) char lines)
display_progress_text: {
    .label display_progress_text__3 = $6e
    .label l = $e5
    .label lines = $37
    .label text = $5e
    // display_progress_clear()
    // [1060] call display_progress_clear
    // [864] phi from display_progress_text to display_progress_clear [phi:display_progress_text->display_progress_clear]
    jsr display_progress_clear
    // [1061] phi from display_progress_text to display_progress_text::@1 [phi:display_progress_text->display_progress_text::@1]
    // [1061] phi display_progress_text::l#2 = 0 [phi:display_progress_text->display_progress_text::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z l
    // display_progress_text::@1
  __b1:
    // for(unsigned char l=0; l<lines; l++)
    // [1062] if(display_progress_text::l#2<display_progress_text::lines#11) goto display_progress_text::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z l
    cmp.z lines
    bcc __b2
    // display_progress_text::@return
    // }
    // [1063] return 
    rts
    // display_progress_text::@2
  __b2:
    // display_progress_line(l, text[l])
    // [1064] display_progress_text::$3 = display_progress_text::l#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z l
    asl
    sta.z display_progress_text__3
    // [1065] display_progress_line::line#0 = display_progress_text::l#2 -- vbuz1=vbuz2 
    lda.z l
    sta.z display_progress_line.line
    // [1066] display_progress_line::text#0 = display_progress_text::text#12[display_progress_text::$3] -- pbuz1=qbuz2_derefidx_vbuz3 
    ldy.z display_progress_text__3
    lda (text),y
    sta.z display_progress_line.text
    iny
    lda (text),y
    sta.z display_progress_line.text+1
    // [1067] call display_progress_line
    jsr display_progress_line
    // display_progress_text::@3
    // for(unsigned char l=0; l<lines; l++)
    // [1068] display_progress_text::l#1 = ++ display_progress_text::l#2 -- vbuz1=_inc_vbuz1 
    inc.z l
    // [1061] phi from display_progress_text::@3 to display_progress_text::@1 [phi:display_progress_text::@3->display_progress_text::@1]
    // [1061] phi display_progress_text::l#2 = display_progress_text::l#1 [phi:display_progress_text::@3->display_progress_text::@1#0] -- register_copy 
    jmp __b1
}
  // util_wait_space
util_wait_space: {
    // util_wait_key("Press [SPACE] to continue ...", " ")
    // [1070] call util_wait_key
    // [1197] phi from util_wait_space to util_wait_key [phi:util_wait_space->util_wait_key]
    // [1197] phi util_wait_key::filter#13 = s [phi:util_wait_space->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z util_wait_key.filter
    lda #>s
    sta.z util_wait_key.filter+1
    // [1197] phi util_wait_key::info_text#3 = util_wait_space::info_text [phi:util_wait_space->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z util_wait_key.info_text
    lda #>info_text
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // util_wait_space::@return
    // }
    // [1071] return 
    rts
  .segment Data
    info_text: .text "Press [SPACE] to continue ..."
    .byte 0
}
.segment Code
  // smc_read
/**
 * @brief Read the SMC.BIN file into RAM_BASE.
 * The maximum size of SMC.BIN data that should be in the file is 0x1E00.
 * 
 * @return unsigned int The amount of bytes read from SMC.BIN to be flashed.
 */
// __mem() unsigned int smc_read(__zp($e8) char display_progress)
smc_read: {
    .label fp = $b2
    .label smc_file_read = $60
    /// Holds the amount of bytes actually read in the memory to be flashed.
    .label progress_row_bytes = $f0
    .label display_progress = $e8
    // display_action_progress("Reading SMC.BIN ... (.) data, ( ) empty")
    // [1073] call display_action_progress
  // It is assume that one RAM bank is 0X2000 bytes.
    // [850] phi from smc_read to display_action_progress [phi:smc_read->display_action_progress]
    // [850] phi display_action_progress::info_text#18 = smc_read::info_text [phi:smc_read->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1074] phi from smc_read to smc_read::@10 [phi:smc_read->smc_read::@10]
    // smc_read::@10
    // textcolor(WHITE)
    // [1075] call textcolor
    // [738] phi from smc_read::@10 to textcolor [phi:smc_read::@10->textcolor]
    // [738] phi textcolor::color#18 = WHITE [phi:smc_read::@10->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [1076] phi from smc_read::@10 to smc_read::@11 [phi:smc_read::@10->smc_read::@11]
    // smc_read::@11
    // gotoxy(x, y)
    // [1077] call gotoxy
    // [756] phi from smc_read::@11 to gotoxy [phi:smc_read::@11->gotoxy]
    // [756] phi gotoxy::y#30 = PROGRESS_Y [phi:smc_read::@11->gotoxy#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z gotoxy.y
    // [756] phi gotoxy::x#30 = PROGRESS_X [phi:smc_read::@11->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [1078] phi from smc_read::@11 to smc_read::@12 [phi:smc_read::@11->smc_read::@12]
    // smc_read::@12
    // FILE *fp = fopen("SMC.BIN", "r")
    // [1079] call fopen
    // [2152] phi from smc_read::@12 to fopen [phi:smc_read::@12->fopen]
    // [2152] phi __errno#318 = __errno#35 [phi:smc_read::@12->fopen#0] -- register_copy 
    // [2152] phi fopen::pathtoken#0 = smc_read::path [phi:smc_read::@12->fopen#1] -- pbuz1=pbuc1 
    lda #<path
    sta.z fopen.pathtoken
    lda #>path
    sta.z fopen.pathtoken+1
    jsr fopen
    // FILE *fp = fopen("SMC.BIN", "r")
    // [1080] fopen::return#3 = fopen::return#2
    // smc_read::@13
    // [1081] smc_read::fp#0 = fopen::return#3 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [1082] if((struct $2 *)0==smc_read::fp#0) goto smc_read::@1 -- pssc1_eq_pssz1_then_la1 
    lda.z fp
    cmp #<0
    bne !+
    lda.z fp+1
    cmp #>0
    beq __b2
  !:
    // smc_read::@2
    // fgets(smc_rom_releases, 32, fp)
    // [1083] fgets::stream#0 = smc_read::fp#0 -- pssm1=pssz2 
    lda.z fp
    sta fgets.stream
    lda.z fp+1
    sta fgets.stream+1
    // [1084] call fgets
    // [2233] phi from smc_read::@2 to fgets [phi:smc_read::@2->fgets]
    // [2233] phi fgets::ptr#13 = smc_rom_releases [phi:smc_read::@2->fgets#0] -- pbuz1=pbuc1 
    lda #<smc_rom_releases
    sta.z fgets.ptr
    lda #>smc_rom_releases
    sta.z fgets.ptr+1
    // [2233] phi fgets::size#11 = $20 [phi:smc_read::@2->fgets#1] -- vwuz1=vbuc1 
    lda #<$20
    sta.z fgets.size
    lda #>$20
    sta.z fgets.size+1
    // [2233] phi fgets::stream#3 = fgets::stream#0 [phi:smc_read::@2->fgets#2] -- register_copy 
    jsr fgets
    // fgets(smc_rom_releases, 32, fp)
    // [1085] fgets::return#5 = fgets::return#1
    // smc_read::@14
    // smc_file_read = fgets(smc_rom_releases, 32, fp)
    // [1086] smc_read::smc_file_read#1 = fgets::return#5
    // if(smc_file_read)
    // [1087] if(0==smc_read::smc_file_read#1) goto smc_read::@1 -- 0_eq_vwuz1_then_la1 
    lda.z smc_file_read
    ora.z smc_file_read+1
    beq __b2
    // [1088] phi from smc_read::@14 to smc_read::@3 [phi:smc_read::@14->smc_read::@3]
    // [1088] phi smc_read::y#10 = PROGRESS_Y [phi:smc_read::@14->smc_read::@3#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1088] phi smc_read::progress_row_bytes#10 = 0 [phi:smc_read::@14->smc_read::@3#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z progress_row_bytes
    sta.z progress_row_bytes+1
    // [1088] phi smc_read::smc_file_size#10 = 0 [phi:smc_read::@14->smc_read::@3#2] -- vwum1=vwuc1 
    sta smc_file_size
    sta smc_file_size+1
    // [1088] phi smc_read::ram_ptr#10 = (char *)$7800 [phi:smc_read::@14->smc_read::@3#3] -- pbum1=pbuc1 
    lda #<$7800
    sta ram_ptr
    lda #>$7800
    sta ram_ptr+1
  // We read block_size bytes at a time, and each block_size bytes we plot a dot.
  // Every r bytes we move to the next line.
    // smc_read::@3
  __b3:
    // fgets(ram_ptr, SMC_PROGRESS_CELL, fp)
    // [1089] fgets::ptr#3 = smc_read::ram_ptr#10 -- pbuz1=pbum2 
    lda ram_ptr
    sta.z fgets.ptr
    lda ram_ptr+1
    sta.z fgets.ptr+1
    // [1090] fgets::stream#1 = smc_read::fp#0 -- pssm1=pssz2 
    lda.z fp
    sta fgets.stream
    lda.z fp+1
    sta fgets.stream+1
    // [1091] call fgets
    // [2233] phi from smc_read::@3 to fgets [phi:smc_read::@3->fgets]
    // [2233] phi fgets::ptr#13 = fgets::ptr#3 [phi:smc_read::@3->fgets#0] -- register_copy 
    // [2233] phi fgets::size#11 = SMC_PROGRESS_CELL [phi:smc_read::@3->fgets#1] -- vwuz1=vbuc1 
    lda #<SMC_PROGRESS_CELL
    sta.z fgets.size
    lda #>SMC_PROGRESS_CELL
    sta.z fgets.size+1
    // [2233] phi fgets::stream#3 = fgets::stream#1 [phi:smc_read::@3->fgets#2] -- register_copy 
    jsr fgets
    // fgets(ram_ptr, SMC_PROGRESS_CELL, fp)
    // [1092] fgets::return#10 = fgets::return#1
    // smc_read::@15
    // smc_file_read = fgets(ram_ptr, SMC_PROGRESS_CELL, fp)
    // [1093] smc_read::smc_file_read#10 = fgets::return#10
    // while (smc_file_read = fgets(ram_ptr, SMC_PROGRESS_CELL, fp))
    // [1094] if(0!=smc_read::smc_file_read#10) goto smc_read::@4 -- 0_neq_vwuz1_then_la1 
    lda.z smc_file_read
    ora.z smc_file_read+1
    bne __b4
    // smc_read::@5
    // fclose(fp)
    // [1095] fclose::stream#0 = smc_read::fp#0
    // [1096] call fclose
    // [2287] phi from smc_read::@5 to fclose [phi:smc_read::@5->fclose]
    // [2287] phi fclose::stream#2 = fclose::stream#0 [phi:smc_read::@5->fclose#0] -- register_copy 
    jsr fclose
    // [1097] phi from smc_read::@5 to smc_read::@1 [phi:smc_read::@5->smc_read::@1]
    // [1097] phi smc_read::return#0 = smc_read::smc_file_size#10 [phi:smc_read::@5->smc_read::@1#0] -- register_copy 
    rts
    // [1097] phi from smc_read::@13 smc_read::@14 to smc_read::@1 [phi:smc_read::@13/smc_read::@14->smc_read::@1]
  __b2:
    // [1097] phi smc_read::return#0 = 0 [phi:smc_read::@13/smc_read::@14->smc_read::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta return
    sta return+1
    // smc_read::@1
    // smc_read::@return
    // }
    // [1098] return 
    rts
    // [1099] phi from smc_read::@15 to smc_read::@4 [phi:smc_read::@15->smc_read::@4]
    // smc_read::@4
  __b4:
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1100] call snprintf_init
    // [1151] phi from smc_read::@4 to snprintf_init [phi:smc_read::@4->snprintf_init]
    // [1151] phi snprintf_init::s#26 = info_text [phi:smc_read::@4->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1101] phi from smc_read::@4 to smc_read::@16 [phi:smc_read::@4->smc_read::@16]
    // smc_read::@16
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1102] call printf_str
    // [1156] phi from smc_read::@16 to printf_str [phi:smc_read::@16->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:smc_read::@16->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = smc_read::s [phi:smc_read::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@17
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1103] printf_uint::uvalue#1 = smc_read::smc_file_read#10 -- vwuz1=vwuz2 
    lda.z smc_file_read
    sta.z printf_uint.uvalue
    lda.z smc_file_read+1
    sta.z printf_uint.uvalue+1
    // [1104] call printf_uint
    // [1810] phi from smc_read::@17 to printf_uint [phi:smc_read::@17->printf_uint]
    // [1810] phi printf_uint::format_zero_padding#14 = 1 [phi:smc_read::@17->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [1810] phi printf_uint::format_min_length#14 = 5 [phi:smc_read::@17->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [1810] phi printf_uint::putc#14 = &snputc [phi:smc_read::@17->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [1810] phi printf_uint::format_radix#14 = HEXADECIMAL [phi:smc_read::@17->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [1810] phi printf_uint::uvalue#14 = printf_uint::uvalue#1 [phi:smc_read::@17->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1105] phi from smc_read::@17 to smc_read::@18 [phi:smc_read::@17->smc_read::@18]
    // smc_read::@18
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1106] call printf_str
    // [1156] phi from smc_read::@18 to printf_str [phi:smc_read::@18->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:smc_read::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = s1 [phi:smc_read::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@19
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1107] printf_uint::uvalue#2 = smc_read::smc_file_size#10 -- vwuz1=vwum2 
    lda smc_file_size
    sta.z printf_uint.uvalue
    lda smc_file_size+1
    sta.z printf_uint.uvalue+1
    // [1108] call printf_uint
    // [1810] phi from smc_read::@19 to printf_uint [phi:smc_read::@19->printf_uint]
    // [1810] phi printf_uint::format_zero_padding#14 = 1 [phi:smc_read::@19->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [1810] phi printf_uint::format_min_length#14 = 5 [phi:smc_read::@19->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [1810] phi printf_uint::putc#14 = &snputc [phi:smc_read::@19->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [1810] phi printf_uint::format_radix#14 = HEXADECIMAL [phi:smc_read::@19->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [1810] phi printf_uint::uvalue#14 = printf_uint::uvalue#2 [phi:smc_read::@19->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1109] phi from smc_read::@19 to smc_read::@20 [phi:smc_read::@19->smc_read::@20]
    // smc_read::@20
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1110] call printf_str
    // [1156] phi from smc_read::@20 to printf_str [phi:smc_read::@20->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:smc_read::@20->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = s2 [phi:smc_read::@20->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // [1111] phi from smc_read::@20 to smc_read::@21 [phi:smc_read::@20->smc_read::@21]
    // smc_read::@21
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1112] call printf_uint
    // [1810] phi from smc_read::@21 to printf_uint [phi:smc_read::@21->printf_uint]
    // [1810] phi printf_uint::format_zero_padding#14 = 1 [phi:smc_read::@21->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [1810] phi printf_uint::format_min_length#14 = 2 [phi:smc_read::@21->printf_uint#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uint.format_min_length
    // [1810] phi printf_uint::putc#14 = &snputc [phi:smc_read::@21->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [1810] phi printf_uint::format_radix#14 = HEXADECIMAL [phi:smc_read::@21->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [1810] phi printf_uint::uvalue#14 = 0 [phi:smc_read::@21->printf_uint#4] -- vwuz1=vbuc1 
    lda #<0
    sta.z printf_uint.uvalue
    sta.z printf_uint.uvalue+1
    jsr printf_uint
    // [1113] phi from smc_read::@21 to smc_read::@22 [phi:smc_read::@21->smc_read::@22]
    // smc_read::@22
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1114] call printf_str
    // [1156] phi from smc_read::@22 to printf_str [phi:smc_read::@22->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:smc_read::@22->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = s3 [phi:smc_read::@22->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@23
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1115] printf_uint::uvalue#4 = (unsigned int)smc_read::ram_ptr#10 -- vwuz1=vwum2 
    lda ram_ptr
    sta.z printf_uint.uvalue
    lda ram_ptr+1
    sta.z printf_uint.uvalue+1
    // [1116] call printf_uint
    // [1810] phi from smc_read::@23 to printf_uint [phi:smc_read::@23->printf_uint]
    // [1810] phi printf_uint::format_zero_padding#14 = 1 [phi:smc_read::@23->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [1810] phi printf_uint::format_min_length#14 = 4 [phi:smc_read::@23->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [1810] phi printf_uint::putc#14 = &snputc [phi:smc_read::@23->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [1810] phi printf_uint::format_radix#14 = HEXADECIMAL [phi:smc_read::@23->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [1810] phi printf_uint::uvalue#14 = printf_uint::uvalue#4 [phi:smc_read::@23->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1117] phi from smc_read::@23 to smc_read::@24 [phi:smc_read::@23->smc_read::@24]
    // smc_read::@24
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1118] call printf_str
    // [1156] phi from smc_read::@24 to printf_str [phi:smc_read::@24->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:smc_read::@24->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = s4 [phi:smc_read::@24->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@25
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1119] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1120] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1122] call display_action_text
    // [1247] phi from smc_read::@25 to display_action_text [phi:smc_read::@25->display_action_text]
    // [1247] phi display_action_text::info_text#19 = info_text [phi:smc_read::@25->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_read::@26
    // if (progress_row_bytes == SMC_PROGRESS_ROW)
    // [1123] if(smc_read::progress_row_bytes#10!=SMC_PROGRESS_ROW) goto smc_read::@6 -- vwuz1_neq_vwuc1_then_la1 
    lda.z progress_row_bytes+1
    cmp #>SMC_PROGRESS_ROW
    bne __b6
    lda.z progress_row_bytes
    cmp #<SMC_PROGRESS_ROW
    bne __b6
    // smc_read::@8
    // gotoxy(x, ++y);
    // [1124] smc_read::y#1 = ++ smc_read::y#10 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [1125] gotoxy::y#20 = smc_read::y#1 -- vbuz1=vbum2 
    lda y
    sta.z gotoxy.y
    // [1126] call gotoxy
    // [756] phi from smc_read::@8 to gotoxy [phi:smc_read::@8->gotoxy]
    // [756] phi gotoxy::y#30 = gotoxy::y#20 [phi:smc_read::@8->gotoxy#0] -- register_copy 
    // [756] phi gotoxy::x#30 = PROGRESS_X [phi:smc_read::@8->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [1127] phi from smc_read::@8 to smc_read::@6 [phi:smc_read::@8->smc_read::@6]
    // [1127] phi smc_read::y#20 = smc_read::y#1 [phi:smc_read::@8->smc_read::@6#0] -- register_copy 
    // [1127] phi smc_read::progress_row_bytes#4 = 0 [phi:smc_read::@8->smc_read::@6#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z progress_row_bytes
    sta.z progress_row_bytes+1
    // [1127] phi from smc_read::@26 to smc_read::@6 [phi:smc_read::@26->smc_read::@6]
    // [1127] phi smc_read::y#20 = smc_read::y#10 [phi:smc_read::@26->smc_read::@6#0] -- register_copy 
    // [1127] phi smc_read::progress_row_bytes#4 = smc_read::progress_row_bytes#10 [phi:smc_read::@26->smc_read::@6#1] -- register_copy 
    // smc_read::@6
  __b6:
    // if(display_progress)
    // [1128] if(0==smc_read::display_progress#19) goto smc_read::@7 -- 0_eq_vbuz1_then_la1 
    lda.z display_progress
    beq __b7
    // smc_read::@9
    // cputc('.')
    // [1129] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [1130] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_read::@7
  __b7:
    // ram_ptr += smc_file_read
    // [1132] smc_read::ram_ptr#1 = smc_read::ram_ptr#10 + smc_read::smc_file_read#10 -- pbum1=pbum1_plus_vwuz2 
    clc
    lda ram_ptr
    adc.z smc_file_read
    sta ram_ptr
    lda ram_ptr+1
    adc.z smc_file_read+1
    sta ram_ptr+1
    // smc_file_size += smc_file_read
    // [1133] smc_read::smc_file_size#1 = smc_read::smc_file_size#10 + smc_read::smc_file_read#10 -- vwum1=vwum1_plus_vwuz2 
    clc
    lda smc_file_size
    adc.z smc_file_read
    sta smc_file_size
    lda smc_file_size+1
    adc.z smc_file_read+1
    sta smc_file_size+1
    // progress_row_bytes += smc_file_read
    // [1134] smc_read::progress_row_bytes#2 = smc_read::progress_row_bytes#4 + smc_read::smc_file_read#10 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z progress_row_bytes
    adc.z smc_file_read
    sta.z progress_row_bytes
    lda.z progress_row_bytes+1
    adc.z smc_file_read+1
    sta.z progress_row_bytes+1
    // [1088] phi from smc_read::@7 to smc_read::@3 [phi:smc_read::@7->smc_read::@3]
    // [1088] phi smc_read::y#10 = smc_read::y#20 [phi:smc_read::@7->smc_read::@3#0] -- register_copy 
    // [1088] phi smc_read::progress_row_bytes#10 = smc_read::progress_row_bytes#2 [phi:smc_read::@7->smc_read::@3#1] -- register_copy 
    // [1088] phi smc_read::smc_file_size#10 = smc_read::smc_file_size#1 [phi:smc_read::@7->smc_read::@3#2] -- register_copy 
    // [1088] phi smc_read::ram_ptr#10 = smc_read::ram_ptr#1 [phi:smc_read::@7->smc_read::@3#3] -- register_copy 
    jmp __b3
  .segment Data
    info_text: .text "Reading SMC.BIN ... (.) data, ( ) empty"
    .byte 0
    path: .text "SMC.BIN"
    .byte 0
    s: .text "Reading SMC.BIN:"
    .byte 0
    .label return = smc_flash.smc_package_flashed
    .label y = main.check_status_smc4_main__0
    .label ram_ptr = wait_moment.i
    .label smc_file_size = smc_flash.smc_package_flashed
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
    // release & 0x80
    // [1136] rom_get_release::$0 = rom_get_release::release#4 & $80 -- vbum1=vbum2_band_vbuc1 
    lda #$80
    and release
    sta rom_get_release__0
    // if(release & 0x80)
    // [1137] if(0==rom_get_release::$0) goto rom_get_release::@1 -- 0_eq_vbum1_then_la1 
    beq __b1
    // rom_get_release::@2
    // ~release
    // [1138] rom_get_release::$2 = ~ rom_get_release::release#4 -- vbum1=_bnot_vbum1 
    lda rom_get_release__2
    eor #$ff
    sta rom_get_release__2
    // release = ~release + 1
    // [1139] rom_get_release::release#0 = rom_get_release::$2 + 1 -- vbum1=vbum1_plus_1 
    inc release
    // [1140] phi from rom_get_release rom_get_release::@2 to rom_get_release::@1 [phi:rom_get_release/rom_get_release::@2->rom_get_release::@1]
    // [1140] phi rom_get_release::return#0 = rom_get_release::release#4 [phi:rom_get_release/rom_get_release::@2->rom_get_release::@1#0] -- register_copy 
    // rom_get_release::@1
  __b1:
    // rom_get_release::@return
    // }
    // [1141] return 
    rts
  .segment Data
    rom_get_release__0: .byte 0
    .label rom_get_release__2 = return
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
    // if(release == 0xFF)
    // [1143] if(rom_get_prefix::release#4!=$ff) goto rom_get_prefix::@1 -- vbum1_neq_vbuc1_then_la1 
    lda #$ff
    cmp release
    bne __b3
    // [1144] phi from rom_get_prefix to rom_get_prefix::@3 [phi:rom_get_prefix->rom_get_prefix::@3]
    // rom_get_prefix::@3
    // [1145] phi from rom_get_prefix::@3 to rom_get_prefix::@1 [phi:rom_get_prefix::@3->rom_get_prefix::@1]
    // [1145] phi rom_get_prefix::prefix#4 = 'p' [phi:rom_get_prefix::@3->rom_get_prefix::@1#0] -- vbum1=vbuc1 
    lda #'p'
    sta prefix
    jmp __b1
    // [1145] phi from rom_get_prefix to rom_get_prefix::@1 [phi:rom_get_prefix->rom_get_prefix::@1]
  __b3:
    // [1145] phi rom_get_prefix::prefix#4 = 'r' [phi:rom_get_prefix->rom_get_prefix::@1#0] -- vbum1=vbuc1 
    lda #'r'
    sta prefix
    // rom_get_prefix::@1
  __b1:
    // release & 0x80
    // [1146] rom_get_prefix::$2 = rom_get_prefix::release#4 & $80 -- vbum1=vbum1_band_vbuc1 
    lda #$80
    and rom_get_prefix__2
    sta rom_get_prefix__2
    // if(release & 0x80)
    // [1147] if(0==rom_get_prefix::$2) goto rom_get_prefix::@4 -- 0_eq_vbum1_then_la1 
    beq __b2
    // [1149] phi from rom_get_prefix::@1 to rom_get_prefix::@2 [phi:rom_get_prefix::@1->rom_get_prefix::@2]
    // [1149] phi rom_get_prefix::return#0 = 'p' [phi:rom_get_prefix::@1->rom_get_prefix::@2#0] -- vbum1=vbuc1 
    lda #'p'
    sta return
    rts
    // [1148] phi from rom_get_prefix::@1 to rom_get_prefix::@4 [phi:rom_get_prefix::@1->rom_get_prefix::@4]
    // rom_get_prefix::@4
    // [1149] phi from rom_get_prefix::@4 to rom_get_prefix::@2 [phi:rom_get_prefix::@4->rom_get_prefix::@2]
    // [1149] phi rom_get_prefix::return#0 = rom_get_prefix::prefix#4 [phi:rom_get_prefix::@4->rom_get_prefix::@2#0] -- register_copy 
    // rom_get_prefix::@2
  __b2:
    // rom_get_prefix::@return
    // }
    // [1150] return 
    rts
  .segment Data
    .label rom_get_prefix__2 = main.check_status_smc2_main__0
    return: .byte 0
    .label release = main.check_status_smc2_main__0
    // If the release is 0xFF, then the release is a preview.
    // If bit 7 of the release is set, then the release is a preview.
    .label prefix = return
}
.segment Code
  // snprintf_init
/// Initialize the snprintf() state
// void snprintf_init(__zp($bc) char *s, unsigned int n)
snprintf_init: {
    .label s = $bc
    // __snprintf_capacity = n
    // [1152] __snprintf_capacity = $ffff -- vwum1=vwuc1 
    lda #<$ffff
    sta __snprintf_capacity
    lda #>$ffff
    sta __snprintf_capacity+1
    // __snprintf_size = 0
    // [1153] __snprintf_size = 0 -- vwum1=vbuc1 
    lda #<0
    sta __snprintf_size
    sta __snprintf_size+1
    // __snprintf_buffer = s
    // [1154] __snprintf_buffer = snprintf_init::s#26 -- pbum1=pbuz2 
    lda.z s
    sta __snprintf_buffer
    lda.z s+1
    sta __snprintf_buffer+1
    // snprintf_init::@return
    // }
    // [1155] return 
    rts
}
  // printf_str
/// Print a NUL-terminated string
// void printf_str(__zp($5e) void (*putc)(char), __zp($62) const char *s)
printf_str: {
    .label c = $c5
    .label s = $62
    .label putc = $5e
    // [1157] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [1157] phi printf_str::s#70 = printf_str::s#71 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [1158] printf_str::c#1 = *printf_str::s#70 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta.z c
    // [1159] printf_str::s#0 = ++ printf_str::s#70 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [1160] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // printf_str::@return
    // }
    // [1161] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [1162] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [1163] callexecute *printf_str::putc#71  -- call__deref_pprz1 
    jsr icall16
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
    // Outside Flow
  icall16:
    jmp (putc)
}
  // printf_string
// Print a string value using a specific format
// Handles justification and min length 
// void printf_string(__zp($64) void (*putc)(char), __zp($62) char *str, __zp($e5) char format_min_length, __zp($e7) char format_justify_left)
printf_string: {
    .label printf_string__9 = $55
    .label len = $c5
    .label padding = $e5
    .label str = $62
    .label format_min_length = $e5
    .label format_justify_left = $e7
    .label putc = $64
    // if(format.min_length)
    // [1166] if(0==printf_string::format_min_length#22) goto printf_string::@1 -- 0_eq_vbuz1_then_la1 
    lda.z format_min_length
    beq __b3
    // printf_string::@3
    // strlen(str)
    // [1167] strlen::str#3 = printf_string::str#22 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [1168] call strlen
    // [2315] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [2315] phi strlen::str#8 = strlen::str#3 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [1169] strlen::return#10 = strlen::len#2
    // printf_string::@6
    // [1170] printf_string::$9 = strlen::return#10
    // signed char len = (signed char)strlen(str)
    // [1171] printf_string::len#0 = (signed char)printf_string::$9 -- vbsz1=_sbyte_vwuz2 
    lda.z printf_string__9
    sta.z len
    // padding = (signed char)format.min_length  - len
    // [1172] printf_string::padding#1 = (signed char)printf_string::format_min_length#22 - printf_string::len#0 -- vbsz1=vbsz1_minus_vbsz2 
    lda.z padding
    sec
    sbc.z len
    sta.z padding
    // if(padding<0)
    // [1173] if(printf_string::padding#1>=0) goto printf_string::@10 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1175] phi from printf_string printf_string::@6 to printf_string::@1 [phi:printf_string/printf_string::@6->printf_string::@1]
  __b3:
    // [1175] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@6->printf_string::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [1174] phi from printf_string::@6 to printf_string::@10 [phi:printf_string::@6->printf_string::@10]
    // printf_string::@10
    // [1175] phi from printf_string::@10 to printf_string::@1 [phi:printf_string::@10->printf_string::@1]
    // [1175] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@10->printf_string::@1#0] -- register_copy 
    // printf_string::@1
  __b1:
    // if(!format.justify_left && padding)
    // [1176] if(0!=printf_string::format_justify_left#22) goto printf_string::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_justify_left
    bne __b2
    // printf_string::@8
    // [1177] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b4
    jmp __b2
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [1178] printf_padding::putc#3 = printf_string::putc#22 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1179] printf_padding::length#3 = (char)printf_string::padding#3 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1180] call printf_padding
    // [2321] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    // [2321] phi printf_padding::putc#7 = printf_padding::putc#3 [phi:printf_string::@4->printf_padding#0] -- register_copy 
    // [2321] phi printf_padding::pad#7 = ' ' [phi:printf_string::@4->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [2321] phi printf_padding::length#6 = printf_padding::length#3 [phi:printf_string::@4->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [1181] printf_str::putc#1 = printf_string::putc#22 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_str.putc
    lda.z putc+1
    sta.z printf_str.putc+1
    // [1182] printf_str::s#2 = printf_string::str#22
    // [1183] call printf_str
    // [1156] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [1156] phi printf_str::putc#71 = printf_str::putc#1 [phi:printf_string::@2->printf_str#0] -- register_copy 
    // [1156] phi printf_str::s#71 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@7
    // if(format.justify_left && padding)
    // [1184] if(0==printf_string::format_justify_left#22) goto printf_string::@return -- 0_eq_vbuz1_then_la1 
    lda.z format_justify_left
    beq __breturn
    // printf_string::@9
    // [1185] if(0!=printf_string::padding#3) goto printf_string::@5 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b5
    rts
    // printf_string::@5
  __b5:
    // printf_padding(putc, ' ',(char)padding)
    // [1186] printf_padding::putc#4 = printf_string::putc#22 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1187] printf_padding::length#4 = (char)printf_string::padding#3 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1188] call printf_padding
    // [2321] phi from printf_string::@5 to printf_padding [phi:printf_string::@5->printf_padding]
    // [2321] phi printf_padding::putc#7 = printf_padding::putc#4 [phi:printf_string::@5->printf_padding#0] -- register_copy 
    // [2321] phi printf_padding::pad#7 = ' ' [phi:printf_string::@5->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [2321] phi printf_padding::length#6 = printf_padding::length#4 [phi:printf_string::@5->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@return
  __breturn:
    // }
    // [1189] return 
    rts
  .segment Data
    .label str_1 = rom_read.rom_package_read
}
.segment Code
  // smc_supported_rom
// __mem() char smc_supported_rom(__mem() char rom_release)
smc_supported_rom: {
    .label i = $2f
    // [1191] phi from smc_supported_rom to smc_supported_rom::@1 [phi:smc_supported_rom->smc_supported_rom::@1]
    // [1191] phi smc_supported_rom::i#2 = 0 [phi:smc_supported_rom->smc_supported_rom::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // smc_supported_rom::@1
  __b1:
    // for(unsigned char i=0; i<32; i++)
    // [1192] if(smc_supported_rom::i#2<$20) goto smc_supported_rom::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z i
    cmp #$20
    bcc __b2
    // [1194] phi from smc_supported_rom::@1 to smc_supported_rom::@return [phi:smc_supported_rom::@1->smc_supported_rom::@return]
    // [1194] phi smc_supported_rom::return#2 = 0 [phi:smc_supported_rom::@1->smc_supported_rom::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    rts
    // smc_supported_rom::@2
  __b2:
    // if(smc_rom_releases[i] == rom_release)
    // [1193] if(smc_rom_releases[smc_supported_rom::i#2]!=smc_supported_rom::rom_release#0) goto smc_supported_rom::@3 -- pbuc1_derefidx_vbuz1_neq_vbum2_then_la1 
    lda rom_release
    ldy.z i
    cmp smc_rom_releases,y
    bne __b3
    // [1194] phi from smc_supported_rom::@2 to smc_supported_rom::@return [phi:smc_supported_rom::@2->smc_supported_rom::@return]
    // [1194] phi smc_supported_rom::return#2 = 1 [phi:smc_supported_rom::@2->smc_supported_rom::@return#0] -- vbum1=vbuc1 
    lda #1
    sta return
    // smc_supported_rom::@return
    // }
    // [1195] return 
    rts
    // smc_supported_rom::@3
  __b3:
    // for(unsigned char i=0; i<32; i++)
    // [1196] smc_supported_rom::i#1 = ++ smc_supported_rom::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1191] phi from smc_supported_rom::@3 to smc_supported_rom::@1 [phi:smc_supported_rom::@3->smc_supported_rom::@1]
    // [1191] phi smc_supported_rom::i#2 = smc_supported_rom::i#1 [phi:smc_supported_rom::@3->smc_supported_rom::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    return: .byte 0
    .label rom_release = util_wait_key.return
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
// __zp($e9) char util_wait_key(__zp($64) char *info_text, __zp($3f) char *filter)
util_wait_key: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 4
    .label util_wait_key__9 = $f0
    .label bram = $5c
    .label bank_get_brom1_return = $d5
    .label return_1 = $e9
    .label info_text = $64
    .label filter = $3f
    // display_action_text(info_text)
    // [1198] display_action_text::info_text#0 = util_wait_key::info_text#3
    // [1199] call display_action_text
    // [1247] phi from util_wait_key to display_action_text [phi:util_wait_key->display_action_text]
    // [1247] phi display_action_text::info_text#19 = display_action_text::info_text#0 [phi:util_wait_key->display_action_text#0] -- register_copy 
    jsr display_action_text
    // util_wait_key::bank_get_bram1
    // return BRAM;
    // [1200] util_wait_key::bram#0 = BRAM -- vbuz1=vbuz2 
    lda.z BRAM
    sta.z bram
    // util_wait_key::bank_get_brom1
    // return BROM;
    // [1201] util_wait_key::bank_get_brom1_return#0 = BROM -- vbuz1=vbuz2 
    lda.z BROM
    sta.z bank_get_brom1_return
    // util_wait_key::bank_set_bram1
    // BRAM = bank
    // [1202] BRAM = util_wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // util_wait_key::bank_set_brom1
    // BROM = bank
    // [1203] BROM = util_wait_key::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [1204] phi from util_wait_key::@2 util_wait_key::@5 util_wait_key::bank_set_brom1 to util_wait_key::kbhit1 [phi:util_wait_key::@2/util_wait_key::@5/util_wait_key::bank_set_brom1->util_wait_key::kbhit1]
    // util_wait_key::kbhit1
  kbhit1:
    // util_wait_key::kbhit1_cbm_k_clrchn1
    // asm
    // asm { jsrCBM_CLRCHN  }
    jsr CBM_CLRCHN
    // [1206] phi from util_wait_key::kbhit1_cbm_k_clrchn1 to util_wait_key::kbhit1_@2 [phi:util_wait_key::kbhit1_cbm_k_clrchn1->util_wait_key::kbhit1_@2]
    // util_wait_key::kbhit1_@2
    // cbm_k_getin()
    // [1207] call cbm_k_getin
    jsr cbm_k_getin
    // [1208] cbm_k_getin::return#2 = cbm_k_getin::return#1
    // util_wait_key::@4
    // [1209] util_wait_key::ch#4 = cbm_k_getin::return#2 -- vwum1=vbuz2 
    lda.z cbm_k_getin.return
    sta ch
    lda #0
    sta ch+1
    // util_wait_key::@3
    // if (filter)
    // [1210] if((char *)0!=util_wait_key::filter#13) goto util_wait_key::@1 -- pbuc1_neq_pbuz1_then_la1 
    // if there is a filter, check the filter, otherwise return ch.
    lda.z filter+1
    cmp #>0
    bne __b1
    lda.z filter
    cmp #<0
    bne __b1
    // util_wait_key::@2
    // if(ch)
    // [1211] if(0!=util_wait_key::ch#4) goto util_wait_key::bank_set_bram2 -- 0_neq_vwum1_then_la1 
    lda ch
    ora ch+1
    bne bank_set_bram2
    jmp kbhit1
    // util_wait_key::bank_set_bram2
  bank_set_bram2:
    // BRAM = bank
    // [1212] BRAM = util_wait_key::bram#0 -- vbuz1=vbuz2 
    lda.z bram
    sta.z BRAM
    // util_wait_key::bank_set_brom2
    // BROM = bank
    // [1213] BROM = util_wait_key::bank_get_brom1_return#0 -- vbuz1=vbuz2 
    lda.z bank_get_brom1_return
    sta.z BROM
    // util_wait_key::@return
    // }
    // [1214] return 
    rts
    // util_wait_key::@1
  __b1:
    // strchr(filter, ch)
    // [1215] strchr::str#0 = (const void *)util_wait_key::filter#13 -- pvoz1=pvoz2 
    lda.z filter
    sta.z strchr.str
    lda.z filter+1
    sta.z strchr.str+1
    // [1216] strchr::c#0 = util_wait_key::ch#4 -- vbuz1=vwum2 
    lda ch
    sta.z strchr.c
    // [1217] call strchr
    // [1757] phi from util_wait_key::@1 to strchr [phi:util_wait_key::@1->strchr]
    // [1757] phi strchr::c#4 = strchr::c#0 [phi:util_wait_key::@1->strchr#0] -- register_copy 
    // [1757] phi strchr::str#2 = strchr::str#0 [phi:util_wait_key::@1->strchr#1] -- register_copy 
    jsr strchr
    // strchr(filter, ch)
    // [1218] strchr::return#3 = strchr::return#2
    // util_wait_key::@5
    // [1219] util_wait_key::$9 = strchr::return#3
    // if(strchr(filter, ch) != NULL)
    // [1220] if(util_wait_key::$9!=0) goto util_wait_key::bank_set_bram2 -- pvoz1_neq_0_then_la1 
    lda.z util_wait_key__9
    ora.z util_wait_key__9+1
    bne bank_set_bram2
    jmp kbhit1
  .segment Data
    return: .byte 0
    .label ch = rom_read.fp
}
.segment Code
  // display_info_cx16_rom
/**
 * @brief Display the ROM status of the main CX16 ROM chip.
 * 
 * @param info_status The status.
 * @param info_text The status text.
 */
// void display_info_cx16_rom(__mem() char info_status, __zp($4f) char *info_text)
display_info_cx16_rom: {
    .label info_text = $4f
    // display_info_rom(0, info_status, info_text)
    // [1222] display_info_rom::info_status#0 = display_info_cx16_rom::info_status#4
    // [1223] display_info_rom::info_text#0 = display_info_cx16_rom::info_text#4
    // [1224] call display_info_rom
    // [1270] phi from display_info_cx16_rom to display_info_rom [phi:display_info_cx16_rom->display_info_rom]
    // [1270] phi display_info_rom::info_text#16 = display_info_rom::info_text#0 [phi:display_info_cx16_rom->display_info_rom#0] -- register_copy 
    // [1270] phi display_info_rom::rom_chip#16 = 0 [phi:display_info_cx16_rom->display_info_rom#1] -- vbuz1=vbuc1 
    lda #0
    sta.z display_info_rom.rom_chip
    // [1270] phi display_info_rom::info_status#16 = display_info_rom::info_status#0 [phi:display_info_cx16_rom->display_info_rom#2] -- register_copy 
    jsr display_info_rom
    // display_info_cx16_rom::@return
    // }
    // [1225] return 
    rts
  .segment Data
    .label info_status = main.check_status_cx16_rom3_check_status_rom1_main__0
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
    // [1227] BRAM = system_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // system_reset::bank_set_brom1
    // BROM = bank
    // [1228] BROM = system_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // system_reset::@2
    // asm
    // asm { jmp($FFFC)  }
    jmp ($fffc)
    // [1230] phi from system_reset::@1 system_reset::@2 to system_reset::@1 [phi:system_reset::@1/system_reset::@2->system_reset::@1]
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
    // [1232] phi from wait_moment to wait_moment::@1 [phi:wait_moment->wait_moment::@1]
    // [1232] phi wait_moment::i#2 = $ffff [phi:wait_moment->wait_moment::@1#0] -- vwum1=vwuc1 
    lda #<$ffff
    sta i
    lda #>$ffff
    sta i+1
    // wait_moment::@1
  __b1:
    // for(unsigned int i=65535; i>0; i--)
    // [1233] if(wait_moment::i#2>0) goto wait_moment::@2 -- vwum1_gt_0_then_la1 
    lda i+1
    bne __b2
    lda i
    bne __b2
  !:
    // wait_moment::@return
    // }
    // [1234] return 
    rts
    // wait_moment::@2
  __b2:
    // for(unsigned int i=65535; i>0; i--)
    // [1235] wait_moment::i#1 = -- wait_moment::i#2 -- vwum1=_dec_vwum1 
    lda i
    bne !+
    dec i+1
  !:
    dec i
    // [1232] phi from wait_moment::@2 to wait_moment::@1 [phi:wait_moment::@2->wait_moment::@1]
    // [1232] phi wait_moment::i#2 = wait_moment::i#1 [phi:wait_moment::@2->wait_moment::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    i: .word 0
}
.segment Code
  // printf_uchar
// Print an unsigned char using a specific format
// void printf_uchar(__zp($5e) void (*putc)(char), __zp($2f) char uvalue, __zp($ea) char format_min_length, char format_justify_left, char format_sign_always, __zp($e9) char format_zero_padding, char format_upper_case, __zp($e8) char format_radix)
printf_uchar: {
    .label uvalue = $2f
    .label format_radix = $e8
    .label putc = $5e
    .label format_min_length = $ea
    .label format_zero_padding = $e9
    // printf_uchar::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1237] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // uctoa(uvalue, printf_buffer.digits, format.radix)
    // [1238] uctoa::value#1 = printf_uchar::uvalue#14
    // [1239] uctoa::radix#0 = printf_uchar::format_radix#14
    // [1240] call uctoa
    // Format number into buffer
    jsr uctoa
    // printf_uchar::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1241] printf_number_buffer::putc#2 = printf_uchar::putc#14
    // [1242] printf_number_buffer::buffer_sign#2 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [1243] printf_number_buffer::format_min_length#2 = printf_uchar::format_min_length#14
    // [1244] printf_number_buffer::format_zero_padding#2 = printf_uchar::format_zero_padding#14
    // [1245] call printf_number_buffer
  // Print using format
    // [2362] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [2362] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#2 [phi:printf_uchar::@2->printf_number_buffer#0] -- register_copy 
    // [2362] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#2 [phi:printf_uchar::@2->printf_number_buffer#1] -- register_copy 
    // [2362] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#2 [phi:printf_uchar::@2->printf_number_buffer#2] -- register_copy 
    // [2362] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#2 [phi:printf_uchar::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [1246] return 
    rts
}
  // display_action_text
/**
 * @brief Print an info line at the action frame, which is the second line.
 * 
 * @param info_text The info text to be displayed.
 */
// void display_action_text(__zp($64) char *info_text)
display_action_text: {
    .label info_text = $64
    .label x = $6c
    .label y = $45
    // unsigned char x = wherex()
    // [1248] call wherex
    jsr wherex
    // [1249] wherex::return#3 = wherex::return#0 -- vbuz1=vbuz2 
    lda.z wherex.return
    sta.z wherex.return_1
    // display_action_text::@1
    // [1250] display_action_text::x#0 = wherex::return#3
    // unsigned char y = wherey()
    // [1251] call wherey
    jsr wherey
    // [1252] wherey::return#3 = wherey::return#0 -- vbuz1=vbuz2 
    lda.z wherey.return
    sta.z wherey.return_1
    // display_action_text::@2
    // [1253] display_action_text::y#0 = wherey::return#3
    // gotoxy(2, PROGRESS_Y-3)
    // [1254] call gotoxy
    // [756] phi from display_action_text::@2 to gotoxy [phi:display_action_text::@2->gotoxy]
    // [756] phi gotoxy::y#30 = PROGRESS_Y-3 [phi:display_action_text::@2->gotoxy#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-3
    sta.z gotoxy.y
    // [756] phi gotoxy::x#30 = 2 [phi:display_action_text::@2->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // display_action_text::@3
    // printf("%-65s", info_text)
    // [1255] printf_string::str#2 = display_action_text::info_text#19 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1256] call printf_string
    // [1165] phi from display_action_text::@3 to printf_string [phi:display_action_text::@3->printf_string]
    // [1165] phi printf_string::putc#22 = &cputc [phi:display_action_text::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1165] phi printf_string::str#22 = printf_string::str#2 [phi:display_action_text::@3->printf_string#1] -- register_copy 
    // [1165] phi printf_string::format_justify_left#22 = 1 [phi:display_action_text::@3->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1165] phi printf_string::format_min_length#22 = $41 [phi:display_action_text::@3->printf_string#3] -- vbuz1=vbuc1 
    lda #$41
    sta.z printf_string.format_min_length
    jsr printf_string
    // display_action_text::@4
    // gotoxy(x, y)
    // [1257] gotoxy::x#12 = display_action_text::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1258] gotoxy::y#12 = display_action_text::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1259] call gotoxy
    // [756] phi from display_action_text::@4 to gotoxy [phi:display_action_text::@4->gotoxy]
    // [756] phi gotoxy::y#30 = gotoxy::y#12 [phi:display_action_text::@4->gotoxy#0] -- register_copy 
    // [756] phi gotoxy::x#30 = gotoxy::x#12 [phi:display_action_text::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_action_text::@return
    // }
    // [1260] return 
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
    // [1262] BRAM = smc_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // smc_reset::bank_set_brom1
    // BROM = bank
    // [1263] BROM = smc_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // smc_reset::@2
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [1264] smc_reset::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [1265] smc_reset::cx16_k_i2c_write_byte1_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte1_offset
    // [1266] smc_reset::cx16_k_i2c_write_byte1_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte1_value
    // smc_reset::cx16_k_i2c_write_byte1
    // unsigned char result
    // [1267] smc_reset::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
    sta cx16_k_i2c_write_byte1_result
    // asm
    // asm { ldxdevice ldyoffset ldavalue stzresult jsrCX16_I2C_WRITE_BYTE rolresult  }
    ldx cx16_k_i2c_write_byte1_device
    ldy cx16_k_i2c_write_byte1_offset
    lda cx16_k_i2c_write_byte1_value
    stz cx16_k_i2c_write_byte1_result
    jsr CX16_I2C_WRITE_BYTE
    rol cx16_k_i2c_write_byte1_result
    // [1269] phi from smc_reset::@1 smc_reset::cx16_k_i2c_write_byte1 to smc_reset::@1 [phi:smc_reset::@1/smc_reset::cx16_k_i2c_write_byte1->smc_reset::@1]
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
// void display_info_rom(__zp($2f) char rom_chip, __mem() char info_status, __zp($4f) char *info_text)
display_info_rom: {
    .label display_info_rom__6 = $d5
    .label display_info_rom__13 = $5c
    .label x = $5b
    .label y = $54
    .label info_text = $4f
    .label rom_chip = $2f
    .label display_info_rom__16 = $d5
    .label display_info_rom__17 = $d5
    // unsigned char x = wherex()
    // [1271] call wherex
    jsr wherex
    // [1272] wherex::return#12 = wherex::return#0 -- vbuz1=vbuz2 
    lda.z wherex.return
    sta.z wherex.return_4
    // display_info_rom::@3
    // [1273] display_info_rom::x#0 = wherex::return#12
    // unsigned char y = wherey()
    // [1274] call wherey
    jsr wherey
    // [1275] wherey::return#12 = wherey::return#0 -- vbuz1=vbuz2 
    lda.z wherey.return
    sta.z wherey.return_4
    // display_info_rom::@4
    // [1276] display_info_rom::y#0 = wherey::return#12
    // status_rom[rom_chip] = info_status
    // [1277] status_rom[display_info_rom::rom_chip#16] = display_info_rom::info_status#16 -- pbuc1_derefidx_vbuz1=vbum2 
    lda info_status
    ldy.z rom_chip
    sta status_rom,y
    // display_rom_led(rom_chip, status_color[info_status])
    // [1278] display_rom_led::chip#1 = display_info_rom::rom_chip#16 -- vbuz1=vbuz2 
    tya
    sta.z display_rom_led.chip
    // [1279] display_rom_led::c#1 = status_color[display_info_rom::info_status#16] -- vbuz1=pbuc1_derefidx_vbum2 
    ldy info_status
    lda status_color,y
    sta.z display_rom_led.c
    // [1280] call display_rom_led
    // [2115] phi from display_info_rom::@4 to display_rom_led [phi:display_info_rom::@4->display_rom_led]
    // [2115] phi display_rom_led::c#2 = display_rom_led::c#1 [phi:display_info_rom::@4->display_rom_led#0] -- register_copy 
    // [2115] phi display_rom_led::chip#2 = display_rom_led::chip#1 [phi:display_info_rom::@4->display_rom_led#1] -- register_copy 
    jsr display_rom_led
    // display_info_rom::@5
    // gotoxy(INFO_X, INFO_Y+rom_chip+2)
    // [1281] gotoxy::y#17 = display_info_rom::rom_chip#16 + $11+2 -- vbuz1=vbuz2_plus_vbuc1 
    lda #$11+2
    clc
    adc.z rom_chip
    sta.z gotoxy.y
    // [1282] call gotoxy
    // [756] phi from display_info_rom::@5 to gotoxy [phi:display_info_rom::@5->gotoxy]
    // [756] phi gotoxy::y#30 = gotoxy::y#17 [phi:display_info_rom::@5->gotoxy#0] -- register_copy 
    // [756] phi gotoxy::x#30 = 4 [phi:display_info_rom::@5->gotoxy#1] -- vbuz1=vbuc1 
    lda #4
    sta.z gotoxy.x
    jsr gotoxy
    // display_info_rom::@6
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1283] display_info_rom::$13 = display_info_rom::rom_chip#16 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta.z display_info_rom__13
    // rom_chip*13
    // [1284] display_info_rom::$16 = display_info_rom::$13 + display_info_rom::rom_chip#16 -- vbuz1=vbuz2_plus_vbuz3 
    clc
    adc.z rom_chip
    sta.z display_info_rom__16
    // [1285] display_info_rom::$17 = display_info_rom::$16 << 2 -- vbuz1=vbuz1_rol_2 
    lda.z display_info_rom__17
    asl
    asl
    sta.z display_info_rom__17
    // [1286] display_info_rom::$6 = display_info_rom::$17 + display_info_rom::rom_chip#16 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z display_info_rom__6
    clc
    adc.z rom_chip
    sta.z display_info_rom__6
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1287] printf_string::str#10 = rom_release_text + display_info_rom::$6 -- pbum1=pbuc1_plus_vbuz2 
    clc
    adc #<rom_release_text
    sta printf_string.str_1
    lda #>rom_release_text
    adc #0
    sta printf_string.str_1+1
    // [1288] call printf_str
    // [1156] phi from display_info_rom::@6 to printf_str [phi:display_info_rom::@6->printf_str]
    // [1156] phi printf_str::putc#71 = &cputc [phi:display_info_rom::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = display_info_rom::s [phi:display_info_rom::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@7
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1289] printf_uchar::uvalue#0 = display_info_rom::rom_chip#16
    // [1290] call printf_uchar
    // [1236] phi from display_info_rom::@7 to printf_uchar [phi:display_info_rom::@7->printf_uchar]
    // [1236] phi printf_uchar::format_zero_padding#14 = 0 [phi:display_info_rom::@7->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1236] phi printf_uchar::format_min_length#14 = 0 [phi:display_info_rom::@7->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1236] phi printf_uchar::putc#14 = &cputc [phi:display_info_rom::@7->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1236] phi printf_uchar::format_radix#14 = DECIMAL [phi:display_info_rom::@7->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1236] phi printf_uchar::uvalue#14 = printf_uchar::uvalue#0 [phi:display_info_rom::@7->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1291] phi from display_info_rom::@7 to display_info_rom::@8 [phi:display_info_rom::@7->display_info_rom::@8]
    // display_info_rom::@8
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1292] call printf_str
    // [1156] phi from display_info_rom::@8 to printf_str [phi:display_info_rom::@8->printf_str]
    // [1156] phi printf_str::putc#71 = &cputc [phi:display_info_rom::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = s [phi:display_info_rom::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s
    sta.z printf_str.s
    lda #>@s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@9
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1293] display_info_rom::$12 = display_info_rom::info_status#16 << 1 -- vbum1=vbum1_rol_1 
    asl display_info_rom__12
    // [1294] printf_string::str#8 = status_text[display_info_rom::$12] -- pbuz1=qbuc1_derefidx_vbum2 
    ldy display_info_rom__12
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [1295] call printf_string
    // [1165] phi from display_info_rom::@9 to printf_string [phi:display_info_rom::@9->printf_string]
    // [1165] phi printf_string::putc#22 = &cputc [phi:display_info_rom::@9->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1165] phi printf_string::str#22 = printf_string::str#8 [phi:display_info_rom::@9->printf_string#1] -- register_copy 
    // [1165] phi printf_string::format_justify_left#22 = 1 [phi:display_info_rom::@9->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1165] phi printf_string::format_min_length#22 = 9 [phi:display_info_rom::@9->printf_string#3] -- vbuz1=vbuc1 
    lda #9
    sta.z printf_string.format_min_length
    jsr printf_string
    // [1296] phi from display_info_rom::@9 to display_info_rom::@10 [phi:display_info_rom::@9->display_info_rom::@10]
    // display_info_rom::@10
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1297] call printf_str
    // [1156] phi from display_info_rom::@10 to printf_str [phi:display_info_rom::@10->printf_str]
    // [1156] phi printf_str::putc#71 = &cputc [phi:display_info_rom::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = s [phi:display_info_rom::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s
    sta.z printf_str.s
    lda #>@s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@11
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1298] printf_string::str#9 = rom_device_names[display_info_rom::$13] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z display_info_rom__13
    lda rom_device_names,y
    sta.z printf_string.str
    lda rom_device_names+1,y
    sta.z printf_string.str+1
    // [1299] call printf_string
    // [1165] phi from display_info_rom::@11 to printf_string [phi:display_info_rom::@11->printf_string]
    // [1165] phi printf_string::putc#22 = &cputc [phi:display_info_rom::@11->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1165] phi printf_string::str#22 = printf_string::str#9 [phi:display_info_rom::@11->printf_string#1] -- register_copy 
    // [1165] phi printf_string::format_justify_left#22 = 1 [phi:display_info_rom::@11->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1165] phi printf_string::format_min_length#22 = 6 [phi:display_info_rom::@11->printf_string#3] -- vbuz1=vbuc1 
    lda #6
    sta.z printf_string.format_min_length
    jsr printf_string
    // [1300] phi from display_info_rom::@11 to display_info_rom::@12 [phi:display_info_rom::@11->display_info_rom::@12]
    // display_info_rom::@12
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1301] call printf_str
    // [1156] phi from display_info_rom::@12 to printf_str [phi:display_info_rom::@12->printf_str]
    // [1156] phi printf_str::putc#71 = &cputc [phi:display_info_rom::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = s [phi:display_info_rom::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s
    sta.z printf_str.s
    lda #>@s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@13
    // [1302] printf_string::str#33 = printf_string::str#10 -- pbuz1=pbum2 
    lda printf_string.str_1
    sta.z printf_string.str
    lda printf_string.str_1+1
    sta.z printf_string.str+1
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1303] call printf_string
    // [1165] phi from display_info_rom::@13 to printf_string [phi:display_info_rom::@13->printf_string]
    // [1165] phi printf_string::putc#22 = &cputc [phi:display_info_rom::@13->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1165] phi printf_string::str#22 = printf_string::str#33 [phi:display_info_rom::@13->printf_string#1] -- register_copy 
    // [1165] phi printf_string::format_justify_left#22 = 1 [phi:display_info_rom::@13->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1165] phi printf_string::format_min_length#22 = $d [phi:display_info_rom::@13->printf_string#3] -- vbuz1=vbuc1 
    lda #$d
    sta.z printf_string.format_min_length
    jsr printf_string
    // [1304] phi from display_info_rom::@13 to display_info_rom::@14 [phi:display_info_rom::@13->display_info_rom::@14]
    // display_info_rom::@14
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1305] call printf_str
    // [1156] phi from display_info_rom::@14 to printf_str [phi:display_info_rom::@14->printf_str]
    // [1156] phi printf_str::putc#71 = &cputc [phi:display_info_rom::@14->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = s [phi:display_info_rom::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s
    sta.z printf_str.s
    lda #>@s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@15
    // if(info_text)
    // [1306] if((char *)0==display_info_rom::info_text#16) goto display_info_rom::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // display_info_rom::@2
    // printf("%-25s", info_text)
    // [1307] printf_string::str#11 = display_info_rom::info_text#16 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1308] call printf_string
    // [1165] phi from display_info_rom::@2 to printf_string [phi:display_info_rom::@2->printf_string]
    // [1165] phi printf_string::putc#22 = &cputc [phi:display_info_rom::@2->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1165] phi printf_string::str#22 = printf_string::str#11 [phi:display_info_rom::@2->printf_string#1] -- register_copy 
    // [1165] phi printf_string::format_justify_left#22 = 1 [phi:display_info_rom::@2->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1165] phi printf_string::format_min_length#22 = $19 [phi:display_info_rom::@2->printf_string#3] -- vbuz1=vbuc1 
    lda #$19
    sta.z printf_string.format_min_length
    jsr printf_string
    // display_info_rom::@1
  __b1:
    // gotoxy(x,y)
    // [1309] gotoxy::x#18 = display_info_rom::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1310] gotoxy::y#18 = display_info_rom::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1311] call gotoxy
    // [756] phi from display_info_rom::@1 to gotoxy [phi:display_info_rom::@1->gotoxy]
    // [756] phi gotoxy::y#30 = gotoxy::y#18 [phi:display_info_rom::@1->gotoxy#0] -- register_copy 
    // [756] phi gotoxy::x#30 = gotoxy::x#18 [phi:display_info_rom::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_rom::@return
    // }
    // [1312] return 
    rts
  .segment Data
    s: .text "ROM"
    .byte 0
    .label display_info_rom__12 = main.check_status_cx16_rom3_check_status_rom1_main__0
    .label info_status = main.check_status_cx16_rom3_check_status_rom1_main__0
}
.segment Code
  // rom_file
// __mem() char * rom_file(__mem() char rom_chip)
rom_file: {
    // if(rom_chip)
    // [1314] if(0!=rom_file::rom_chip#2) goto rom_file::@1 -- 0_neq_vbum1_then_la1 
    lda rom_chip
    bne __b1
    // [1317] phi from rom_file to rom_file::@return [phi:rom_file->rom_file::@return]
    // [1317] phi rom_file::return#2 = rom_file::file_rom_cx16 [phi:rom_file->rom_file::@return#0] -- pbum1=pbuc1 
    lda #<file_rom_cx16
    sta return
    lda #>file_rom_cx16
    sta return+1
    rts
    // rom_file::@1
  __b1:
    // '0'+rom_chip
    // [1315] rom_file::$0 = '0' + rom_file::rom_chip#2 -- vbum1=vbuc1_plus_vbum1 
    lda #'0'
    clc
    adc rom_file__0
    sta rom_file__0
    // file_rom_card[3] = '0'+rom_chip
    // [1316] *(rom_file::file_rom_card+3) = rom_file::$0 -- _deref_pbuc1=vbum1 
    sta file_rom_card+3
    // [1317] phi from rom_file::@1 to rom_file::@return [phi:rom_file::@1->rom_file::@return]
    // [1317] phi rom_file::return#2 = rom_file::file_rom_card [phi:rom_file::@1->rom_file::@return#0] -- pbum1=pbuc1 
    lda #<file_rom_card
    sta return
    lda #>file_rom_card
    sta return+1
    // rom_file::@return
    // }
    // [1318] return 
    rts
  .segment Data
    file_rom_cx16: .text "ROM.BIN"
    .byte 0
    file_rom_card: .text "ROMn.BIN"
    .byte 0
    .label rom_file__0 = main.check_status_smc4_main__0
    return: .word 0
    .label rom_chip = main.check_status_smc4_main__0
}
.segment Code
  // rom_read
// __mem() unsigned long rom_read(__mem() char display_progress, char rom_chip, __mem() char *file, char info_status, __zp($c4) char brom_bank_start, __zp($78) unsigned long rom_size)
rom_read: {
    .const bank_set_brom1_bank = 0
    .label rom_address = $57
    .label brom_bank_start = $c4
    .label y = $cf
    .label ram_address = $d1
    .label rom_row_current = $ad
    .label rom_size = $78
    // unsigned long rom_address = rom_address_from_bank(brom_bank_start)
    // [1320] rom_address_from_bank::rom_bank#0 = rom_read::brom_bank_start#22 -- vbum1=vbuz2 
    lda.z brom_bank_start
    sta rom_address_from_bank.rom_bank
    // [1321] call rom_address_from_bank
    // [2393] phi from rom_read to rom_address_from_bank [phi:rom_read->rom_address_from_bank]
    // [2393] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#0 [phi:rom_read->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(brom_bank_start)
    // [1322] rom_address_from_bank::return#2 = rom_address_from_bank::return#0
    // rom_read::@17
    // [1323] rom_read::rom_address#0 = rom_address_from_bank::return#2
    // rom_read::bank_set_bram1
    // BRAM = bank
    // [1324] BRAM = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z BRAM
    // rom_read::bank_set_brom1
    // BROM = bank
    // [1325] BROM = rom_read::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [1326] phi from rom_read::bank_set_brom1 to rom_read::@15 [phi:rom_read::bank_set_brom1->rom_read::@15]
    // rom_read::@15
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1327] call snprintf_init
    // [1151] phi from rom_read::@15 to snprintf_init [phi:rom_read::@15->snprintf_init]
    // [1151] phi snprintf_init::s#26 = info_text [phi:rom_read::@15->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1328] phi from rom_read::@15 to rom_read::@18 [phi:rom_read::@15->rom_read::@18]
    // rom_read::@18
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1329] call printf_str
    // [1156] phi from rom_read::@18 to printf_str [phi:rom_read::@18->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:rom_read::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = rom_read::s [phi:rom_read::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@19
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1330] printf_string::str#13 = rom_read::file#11 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [1331] call printf_string
    // [1165] phi from rom_read::@19 to printf_string [phi:rom_read::@19->printf_string]
    // [1165] phi printf_string::putc#22 = &snputc [phi:rom_read::@19->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1165] phi printf_string::str#22 = printf_string::str#13 [phi:rom_read::@19->printf_string#1] -- register_copy 
    // [1165] phi printf_string::format_justify_left#22 = 0 [phi:rom_read::@19->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1165] phi printf_string::format_min_length#22 = 0 [phi:rom_read::@19->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [1332] phi from rom_read::@19 to rom_read::@20 [phi:rom_read::@19->rom_read::@20]
    // rom_read::@20
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1333] call printf_str
    // [1156] phi from rom_read::@20 to printf_str [phi:rom_read::@20->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:rom_read::@20->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = rom_read::s1 [phi:rom_read::@20->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@21
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1334] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1335] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1337] call display_action_text
    // [1247] phi from rom_read::@21 to display_action_text [phi:rom_read::@21->display_action_text]
    // [1247] phi display_action_text::info_text#19 = info_text [phi:rom_read::@21->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // rom_read::@22
    // FILE *fp = fopen(file, "r")
    // [1338] fopen::path#3 = rom_read::file#11 -- pbuz1=pbum2 
    lda file
    sta.z fopen.path
    lda file+1
    sta.z fopen.path+1
    // [1339] call fopen
    // [2152] phi from rom_read::@22 to fopen [phi:rom_read::@22->fopen]
    // [2152] phi __errno#318 = __errno#108 [phi:rom_read::@22->fopen#0] -- register_copy 
    // [2152] phi fopen::pathtoken#0 = fopen::path#3 [phi:rom_read::@22->fopen#1] -- register_copy 
    jsr fopen
    // FILE *fp = fopen(file, "r")
    // [1340] fopen::return#4 = fopen::return#2
    // rom_read::@23
    // [1341] rom_read::fp#0 = fopen::return#4 -- pssm1=pssz2 
    lda.z fopen.return
    sta fp
    lda.z fopen.return+1
    sta fp+1
    // if (fp)
    // [1342] if((struct $2 *)0==rom_read::fp#0) goto rom_read::@1 -- pssc1_eq_pssm1_then_la1 
    lda fp
    cmp #<0
    bne !+
    lda fp+1
    cmp #>0
    beq __b2
  !:
    // [1343] phi from rom_read::@23 to rom_read::@2 [phi:rom_read::@23->rom_read::@2]
    // rom_read::@2
    // gotoxy(x, y)
    // [1344] call gotoxy
    // [756] phi from rom_read::@2 to gotoxy [phi:rom_read::@2->gotoxy]
    // [756] phi gotoxy::y#30 = PROGRESS_Y [phi:rom_read::@2->gotoxy#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z gotoxy.y
    // [756] phi gotoxy::x#30 = PROGRESS_X [phi:rom_read::@2->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [1345] phi from rom_read::@2 to rom_read::@3 [phi:rom_read::@2->rom_read::@3]
    // [1345] phi rom_read::y#11 = PROGRESS_Y [phi:rom_read::@2->rom_read::@3#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // [1345] phi rom_read::rom_row_current#10 = 0 [phi:rom_read::@2->rom_read::@3#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z rom_row_current
    sta.z rom_row_current+1
    // [1345] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#22 [phi:rom_read::@2->rom_read::@3#2] -- register_copy 
    // [1345] phi rom_read::rom_address#10 = rom_read::rom_address#0 [phi:rom_read::@2->rom_read::@3#3] -- register_copy 
    // [1345] phi rom_read::ram_address#10 = (char *)$7800 [phi:rom_read::@2->rom_read::@3#4] -- pbuz1=pbuc1 
    lda #<$7800
    sta.z ram_address
    lda #>$7800
    sta.z ram_address+1
    // [1345] phi rom_read::bram_bank#10 = 0 [phi:rom_read::@2->rom_read::@3#5] -- vbum1=vbuc1 
    lda #0
    sta bram_bank
    // [1345] phi rom_read::rom_file_size#11 = 0 [phi:rom_read::@2->rom_read::@3#6] -- vdum1=vduc1 
    sta rom_file_size
    sta rom_file_size+1
    lda #<0>>$10
    sta rom_file_size+2
    lda #>0>>$10
    sta rom_file_size+3
    // rom_read::@3
  __b3:
    // while (rom_file_size < rom_size)
    // [1346] if(rom_read::rom_file_size#11<rom_read::rom_size#12) goto rom_read::@4 -- vdum1_lt_vduz2_then_la1 
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
    // [1347] fclose::stream#1 = rom_read::fp#0 -- pssz1=pssm2 
    lda fp
    sta.z fclose.stream
    lda fp+1
    sta.z fclose.stream+1
    // [1348] call fclose
    // [2287] phi from rom_read::@7 to fclose [phi:rom_read::@7->fclose]
    // [2287] phi fclose::stream#2 = fclose::stream#1 [phi:rom_read::@7->fclose#0] -- register_copy 
    jsr fclose
    // [1349] phi from rom_read::@7 to rom_read::@1 [phi:rom_read::@7->rom_read::@1]
    // [1349] phi rom_read::return#0 = rom_read::rom_file_size#11 [phi:rom_read::@7->rom_read::@1#0] -- register_copy 
    rts
    // [1349] phi from rom_read::@23 to rom_read::@1 [phi:rom_read::@23->rom_read::@1]
  __b2:
    // [1349] phi rom_read::return#0 = 0 [phi:rom_read::@23->rom_read::@1#0] -- vdum1=vduc1 
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
    // [1350] return 
    rts
    // [1351] phi from rom_read::@3 to rom_read::@4 [phi:rom_read::@3->rom_read::@4]
    // rom_read::@4
  __b4:
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1352] call snprintf_init
    // [1151] phi from rom_read::@4 to snprintf_init [phi:rom_read::@4->snprintf_init]
    // [1151] phi snprintf_init::s#26 = info_text [phi:rom_read::@4->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1353] phi from rom_read::@4 to rom_read::@24 [phi:rom_read::@4->rom_read::@24]
    // rom_read::@24
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1354] call printf_str
    // [1156] phi from rom_read::@24 to printf_str [phi:rom_read::@24->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:rom_read::@24->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = s11 [phi:rom_read::@24->printf_str#1] -- pbuz1=pbuc1 
    lda #<s11
    sta.z printf_str.s
    lda #>s11
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@25
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1355] printf_string::str#14 = rom_read::file#11 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [1356] call printf_string
    // [1165] phi from rom_read::@25 to printf_string [phi:rom_read::@25->printf_string]
    // [1165] phi printf_string::putc#22 = &snputc [phi:rom_read::@25->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1165] phi printf_string::str#22 = printf_string::str#14 [phi:rom_read::@25->printf_string#1] -- register_copy 
    // [1165] phi printf_string::format_justify_left#22 = 0 [phi:rom_read::@25->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1165] phi printf_string::format_min_length#22 = 0 [phi:rom_read::@25->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [1357] phi from rom_read::@25 to rom_read::@26 [phi:rom_read::@25->rom_read::@26]
    // rom_read::@26
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1358] call printf_str
    // [1156] phi from rom_read::@26 to printf_str [phi:rom_read::@26->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:rom_read::@26->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = s3 [phi:rom_read::@26->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@27
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1359] printf_ulong::uvalue#0 = rom_read::rom_file_size#11 -- vduz1=vdum2 
    lda rom_file_size
    sta.z printf_ulong.uvalue
    lda rom_file_size+1
    sta.z printf_ulong.uvalue+1
    lda rom_file_size+2
    sta.z printf_ulong.uvalue+2
    lda rom_file_size+3
    sta.z printf_ulong.uvalue+3
    // [1360] call printf_ulong
    // [1470] phi from rom_read::@27 to printf_ulong [phi:rom_read::@27->printf_ulong]
    // [1470] phi printf_ulong::format_zero_padding#10 = 1 [phi:rom_read::@27->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1470] phi printf_ulong::format_min_length#10 = 5 [phi:rom_read::@27->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1470] phi printf_ulong::format_radix#10 = HEXADECIMAL [phi:rom_read::@27->printf_ulong#2] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1470] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#0 [phi:rom_read::@27->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1361] phi from rom_read::@27 to rom_read::@28 [phi:rom_read::@27->rom_read::@28]
    // rom_read::@28
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1362] call printf_str
    // [1156] phi from rom_read::@28 to printf_str [phi:rom_read::@28->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:rom_read::@28->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = s1 [phi:rom_read::@28->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s1
    sta.z printf_str.s
    lda #>@s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@29
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1363] printf_ulong::uvalue#1 = rom_read::rom_size#12 -- vduz1=vduz2 
    lda.z rom_size
    sta.z printf_ulong.uvalue
    lda.z rom_size+1
    sta.z printf_ulong.uvalue+1
    lda.z rom_size+2
    sta.z printf_ulong.uvalue+2
    lda.z rom_size+3
    sta.z printf_ulong.uvalue+3
    // [1364] call printf_ulong
    // [1470] phi from rom_read::@29 to printf_ulong [phi:rom_read::@29->printf_ulong]
    // [1470] phi printf_ulong::format_zero_padding#10 = 1 [phi:rom_read::@29->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1470] phi printf_ulong::format_min_length#10 = 5 [phi:rom_read::@29->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1470] phi printf_ulong::format_radix#10 = HEXADECIMAL [phi:rom_read::@29->printf_ulong#2] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1470] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#1 [phi:rom_read::@29->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1365] phi from rom_read::@29 to rom_read::@30 [phi:rom_read::@29->rom_read::@30]
    // rom_read::@30
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1366] call printf_str
    // [1156] phi from rom_read::@30 to printf_str [phi:rom_read::@30->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:rom_read::@30->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = s2 [phi:rom_read::@30->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@31
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1367] printf_uchar::uvalue#9 = rom_read::bram_bank#10 -- vbuz1=vbum2 
    lda bram_bank
    sta.z printf_uchar.uvalue
    // [1368] call printf_uchar
    // [1236] phi from rom_read::@31 to printf_uchar [phi:rom_read::@31->printf_uchar]
    // [1236] phi printf_uchar::format_zero_padding#14 = 1 [phi:rom_read::@31->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1236] phi printf_uchar::format_min_length#14 = 2 [phi:rom_read::@31->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [1236] phi printf_uchar::putc#14 = &snputc [phi:rom_read::@31->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1236] phi printf_uchar::format_radix#14 = HEXADECIMAL [phi:rom_read::@31->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [1236] phi printf_uchar::uvalue#14 = printf_uchar::uvalue#9 [phi:rom_read::@31->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1369] phi from rom_read::@31 to rom_read::@32 [phi:rom_read::@31->rom_read::@32]
    // rom_read::@32
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1370] call printf_str
    // [1156] phi from rom_read::@32 to printf_str [phi:rom_read::@32->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:rom_read::@32->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = s3 [phi:rom_read::@32->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@33
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1371] printf_uint::uvalue#10 = (unsigned int)rom_read::ram_address#10 -- vwuz1=vwuz2 
    lda.z ram_address
    sta.z printf_uint.uvalue
    lda.z ram_address+1
    sta.z printf_uint.uvalue+1
    // [1372] call printf_uint
    // [1810] phi from rom_read::@33 to printf_uint [phi:rom_read::@33->printf_uint]
    // [1810] phi printf_uint::format_zero_padding#14 = 1 [phi:rom_read::@33->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [1810] phi printf_uint::format_min_length#14 = 4 [phi:rom_read::@33->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [1810] phi printf_uint::putc#14 = &snputc [phi:rom_read::@33->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [1810] phi printf_uint::format_radix#14 = HEXADECIMAL [phi:rom_read::@33->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [1810] phi printf_uint::uvalue#14 = printf_uint::uvalue#10 [phi:rom_read::@33->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1373] phi from rom_read::@33 to rom_read::@34 [phi:rom_read::@33->rom_read::@34]
    // rom_read::@34
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1374] call printf_str
    // [1156] phi from rom_read::@34 to printf_str [phi:rom_read::@34->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:rom_read::@34->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = s4 [phi:rom_read::@34->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@35
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1375] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1376] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1378] call display_action_text
    // [1247] phi from rom_read::@35 to display_action_text [phi:rom_read::@35->display_action_text]
    // [1247] phi display_action_text::info_text#19 = info_text [phi:rom_read::@35->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // rom_read::@36
    // rom_address % 0x04000
    // [1379] rom_read::$11 = rom_read::rom_address#10 & $4000-1 -- vdum1=vduz2_band_vduc1 
    lda.z rom_address
    and #<$4000-1
    sta rom_read__11
    lda.z rom_address+1
    and #>$4000-1
    sta rom_read__11+1
    lda.z rom_address+2
    and #<$4000-1>>$10
    sta rom_read__11+2
    lda.z rom_address+3
    and #>$4000-1>>$10
    sta rom_read__11+3
    // if (!(rom_address % 0x04000))
    // [1380] if(0!=rom_read::$11) goto rom_read::@5 -- 0_neq_vdum1_then_la1 
    lda rom_read__11
    ora rom_read__11+1
    ora rom_read__11+2
    ora rom_read__11+3
    bne __b5
    // rom_read::@11
    // brom_bank_start++;
    // [1381] rom_read::brom_bank_start#0 = ++ rom_read::brom_bank_start#10 -- vbuz1=_inc_vbuz1 
    inc.z brom_bank_start
    // [1382] phi from rom_read::@11 rom_read::@36 to rom_read::@5 [phi:rom_read::@11/rom_read::@36->rom_read::@5]
    // [1382] phi rom_read::brom_bank_start#20 = rom_read::brom_bank_start#0 [phi:rom_read::@11/rom_read::@36->rom_read::@5#0] -- register_copy 
    // rom_read::@5
  __b5:
    // rom_read::bank_set_bram2
    // BRAM = bank
    // [1383] BRAM = rom_read::bram_bank#10 -- vbuz1=vbum2 
    lda bram_bank
    sta.z BRAM
    // rom_read::@16
    // unsigned int rom_package_read = fgets(ram_address, ROM_PROGRESS_CELL, fp)
    // [1384] fgets::ptr#4 = rom_read::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z fgets.ptr
    lda.z ram_address+1
    sta.z fgets.ptr+1
    // [1385] fgets::stream#2 = rom_read::fp#0 -- pssm1=pssm2 
    lda fp
    sta fgets.stream
    lda fp+1
    sta fgets.stream+1
    // [1386] call fgets
    // [2233] phi from rom_read::@16 to fgets [phi:rom_read::@16->fgets]
    // [2233] phi fgets::ptr#13 = fgets::ptr#4 [phi:rom_read::@16->fgets#0] -- register_copy 
    // [2233] phi fgets::size#11 = ROM_PROGRESS_CELL [phi:rom_read::@16->fgets#1] -- vwuz1=vwuc1 
    lda #<ROM_PROGRESS_CELL
    sta.z fgets.size
    lda #>ROM_PROGRESS_CELL
    sta.z fgets.size+1
    // [2233] phi fgets::stream#3 = fgets::stream#2 [phi:rom_read::@16->fgets#2] -- register_copy 
    jsr fgets
    // unsigned int rom_package_read = fgets(ram_address, ROM_PROGRESS_CELL, fp)
    // [1387] fgets::return#11 = fgets::return#1
    // rom_read::@37
    // [1388] rom_read::rom_package_read#0 = fgets::return#11 -- vwum1=vwuz2 
    lda.z fgets.return
    sta rom_package_read
    lda.z fgets.return+1
    sta rom_package_read+1
    // if (!rom_package_read)
    // [1389] if(0!=rom_read::rom_package_read#0) goto rom_read::@6 -- 0_neq_vwum1_then_la1 
    lda rom_package_read
    ora rom_package_read+1
    bne __b6
    jmp __b7
    // rom_read::@6
  __b6:
    // if (rom_row_current == ROM_PROGRESS_ROW)
    // [1390] if(rom_read::rom_row_current#10!=ROM_PROGRESS_ROW) goto rom_read::@8 -- vwuz1_neq_vwuc1_then_la1 
    lda.z rom_row_current+1
    cmp #>ROM_PROGRESS_ROW
    bne __b8
    lda.z rom_row_current
    cmp #<ROM_PROGRESS_ROW
    bne __b8
    // rom_read::@12
    // gotoxy(x, ++y);
    // [1391] rom_read::y#1 = ++ rom_read::y#11 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [1392] gotoxy::y#25 = rom_read::y#1 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1393] call gotoxy
    // [756] phi from rom_read::@12 to gotoxy [phi:rom_read::@12->gotoxy]
    // [756] phi gotoxy::y#30 = gotoxy::y#25 [phi:rom_read::@12->gotoxy#0] -- register_copy 
    // [756] phi gotoxy::x#30 = PROGRESS_X [phi:rom_read::@12->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [1394] phi from rom_read::@12 to rom_read::@8 [phi:rom_read::@12->rom_read::@8]
    // [1394] phi rom_read::y#36 = rom_read::y#1 [phi:rom_read::@12->rom_read::@8#0] -- register_copy 
    // [1394] phi rom_read::rom_row_current#4 = 0 [phi:rom_read::@12->rom_read::@8#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z rom_row_current
    sta.z rom_row_current+1
    // [1394] phi from rom_read::@6 to rom_read::@8 [phi:rom_read::@6->rom_read::@8]
    // [1394] phi rom_read::y#36 = rom_read::y#11 [phi:rom_read::@6->rom_read::@8#0] -- register_copy 
    // [1394] phi rom_read::rom_row_current#4 = rom_read::rom_row_current#10 [phi:rom_read::@6->rom_read::@8#1] -- register_copy 
    // rom_read::@8
  __b8:
    // if(display_progress)
    // [1395] if(0==rom_read::display_progress#28) goto rom_read::@9 -- 0_eq_vbum1_then_la1 
    lda display_progress
    beq __b9
    // rom_read::@13
    // cputc('.')
    // [1396] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [1397] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // rom_read::@9
  __b9:
    // ram_address += rom_package_read
    // [1399] rom_read::ram_address#1 = rom_read::ram_address#10 + rom_read::rom_package_read#0 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z ram_address
    adc rom_package_read
    sta.z ram_address
    lda.z ram_address+1
    adc rom_package_read+1
    sta.z ram_address+1
    // rom_address += rom_package_read
    // [1400] rom_read::rom_address#1 = rom_read::rom_address#10 + rom_read::rom_package_read#0 -- vduz1=vduz1_plus_vwum2 
    lda.z rom_address
    clc
    adc rom_package_read
    sta.z rom_address
    lda.z rom_address+1
    adc rom_package_read+1
    sta.z rom_address+1
    lda.z rom_address+2
    adc #0
    sta.z rom_address+2
    lda.z rom_address+3
    adc #0
    sta.z rom_address+3
    // rom_file_size += rom_package_read
    // [1401] rom_read::rom_file_size#1 = rom_read::rom_file_size#11 + rom_read::rom_package_read#0 -- vdum1=vdum1_plus_vwum2 
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
    // [1402] rom_read::rom_row_current#2 = rom_read::rom_row_current#4 + rom_read::rom_package_read#0 -- vwuz1=vwuz1_plus_vwum2 
    clc
    lda.z rom_row_current
    adc rom_package_read
    sta.z rom_row_current
    lda.z rom_row_current+1
    adc rom_package_read+1
    sta.z rom_row_current+1
    // if (ram_address == (ram_ptr_t)BRAM_HIGH)
    // [1403] if(rom_read::ram_address#1!=(char *)$c000) goto rom_read::@10 -- pbuz1_neq_pbuc1_then_la1 
    lda.z ram_address+1
    cmp #>$c000
    bne __b10
    lda.z ram_address
    cmp #<$c000
    bne __b10
    // rom_read::@14
    // bram_bank++;
    // [1404] rom_read::bram_bank#1 = ++ rom_read::bram_bank#10 -- vbum1=_inc_vbum1 
    inc bram_bank
    // [1405] phi from rom_read::@14 to rom_read::@10 [phi:rom_read::@14->rom_read::@10]
    // [1405] phi rom_read::bram_bank#31 = rom_read::bram_bank#1 [phi:rom_read::@14->rom_read::@10#0] -- register_copy 
    // [1405] phi rom_read::ram_address#7 = (char *)$a000 [phi:rom_read::@14->rom_read::@10#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1405] phi from rom_read::@9 to rom_read::@10 [phi:rom_read::@9->rom_read::@10]
    // [1405] phi rom_read::bram_bank#31 = rom_read::bram_bank#10 [phi:rom_read::@9->rom_read::@10#0] -- register_copy 
    // [1405] phi rom_read::ram_address#7 = rom_read::ram_address#1 [phi:rom_read::@9->rom_read::@10#1] -- register_copy 
    // rom_read::@10
  __b10:
    // if (ram_address == (ram_ptr_t)RAM_HIGH)
    // [1406] if(rom_read::ram_address#7!=(char *)$9800) goto rom_read::@38 -- pbuz1_neq_pbuc1_then_la1 
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
    // [1345] phi from rom_read::@10 to rom_read::@3 [phi:rom_read::@10->rom_read::@3]
    // [1345] phi rom_read::y#11 = rom_read::y#36 [phi:rom_read::@10->rom_read::@3#0] -- register_copy 
    // [1345] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#2 [phi:rom_read::@10->rom_read::@3#1] -- register_copy 
    // [1345] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#20 [phi:rom_read::@10->rom_read::@3#2] -- register_copy 
    // [1345] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@10->rom_read::@3#3] -- register_copy 
    // [1345] phi rom_read::ram_address#10 = (char *)$a000 [phi:rom_read::@10->rom_read::@3#4] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1345] phi rom_read::bram_bank#10 = 1 [phi:rom_read::@10->rom_read::@3#5] -- vbum1=vbuc1 
    lda #1
    sta bram_bank
    // [1345] phi rom_read::rom_file_size#11 = rom_read::rom_file_size#1 [phi:rom_read::@10->rom_read::@3#6] -- register_copy 
    jmp __b3
    // [1407] phi from rom_read::@10 to rom_read::@38 [phi:rom_read::@10->rom_read::@38]
    // rom_read::@38
    // [1345] phi from rom_read::@38 to rom_read::@3 [phi:rom_read::@38->rom_read::@3]
    // [1345] phi rom_read::y#11 = rom_read::y#36 [phi:rom_read::@38->rom_read::@3#0] -- register_copy 
    // [1345] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#2 [phi:rom_read::@38->rom_read::@3#1] -- register_copy 
    // [1345] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#20 [phi:rom_read::@38->rom_read::@3#2] -- register_copy 
    // [1345] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@38->rom_read::@3#3] -- register_copy 
    // [1345] phi rom_read::ram_address#10 = rom_read::ram_address#7 [phi:rom_read::@38->rom_read::@3#4] -- register_copy 
    // [1345] phi rom_read::bram_bank#10 = rom_read::bram_bank#31 [phi:rom_read::@38->rom_read::@3#5] -- register_copy 
    // [1345] phi rom_read::rom_file_size#11 = rom_read::rom_file_size#1 [phi:rom_read::@38->rom_read::@3#6] -- register_copy 
  .segment Data
    s: .text "Opening "
    .byte 0
    s1: .text " from SD card ..."
    .byte 0
    rom_read__11: .dword 0
    fp: .word 0
    return: .dword 0
    rom_package_read: .word 0
    .label rom_file_size = return
    .label bram_bank = main.check_status_smc5_main__0
    .label file = clrscr.ch
    .label display_progress = util_wait_key.return
}
.segment Code
  // rom_verify
// __zp($b4) unsigned long rom_verify(__zp($2f) char rom_chip, __mem() char rom_bank_start, __mem() unsigned long file_size)
rom_verify: {
    .label rom_verify__16 = $51
    .label rom_address = $a9
    .label equal_bytes = $51
    .label rom_different_bytes = $b4
    .label rom_chip = $2f
    .label return = $b4
    .label progress_row_current = $db
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [1408] rom_address_from_bank::rom_bank#1 = rom_verify::rom_bank_start#0
    // [1409] call rom_address_from_bank
    // [2393] phi from rom_verify to rom_address_from_bank [phi:rom_verify->rom_address_from_bank]
    // [2393] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#1 [phi:rom_verify->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [1410] rom_address_from_bank::return#3 = rom_address_from_bank::return#0 -- vduz1=vduz2 
    lda.z rom_address_from_bank.return
    sta.z rom_address_from_bank.return_1
    lda.z rom_address_from_bank.return+1
    sta.z rom_address_from_bank.return_1+1
    lda.z rom_address_from_bank.return+2
    sta.z rom_address_from_bank.return_1+2
    lda.z rom_address_from_bank.return+3
    sta.z rom_address_from_bank.return_1+3
    // rom_verify::@11
    // [1411] rom_verify::rom_address#0 = rom_address_from_bank::return#3
    // unsigned long rom_boundary = rom_address + file_size
    // [1412] rom_verify::rom_boundary#0 = rom_verify::rom_address#0 + rom_verify::file_size#0 -- vdum1=vduz2_plus_vdum1 
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
    // [1413] display_info_rom::rom_chip#1 = rom_verify::rom_chip#0
    // [1414] call display_info_rom
    // [1270] phi from rom_verify::@11 to display_info_rom [phi:rom_verify::@11->display_info_rom]
    // [1270] phi display_info_rom::info_text#16 = rom_verify::info_text [phi:rom_verify::@11->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_rom.info_text
    lda #>info_text
    sta.z display_info_rom.info_text+1
    // [1270] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#1 [phi:rom_verify::@11->display_info_rom#1] -- register_copy 
    // [1270] phi display_info_rom::info_status#16 = STATUS_COMPARING [phi:rom_verify::@11->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_COMPARING
    sta display_info_rom.info_status
    jsr display_info_rom
    // [1415] phi from rom_verify::@11 to rom_verify::@12 [phi:rom_verify::@11->rom_verify::@12]
    // rom_verify::@12
    // gotoxy(x, y)
    // [1416] call gotoxy
    // [756] phi from rom_verify::@12 to gotoxy [phi:rom_verify::@12->gotoxy]
    // [756] phi gotoxy::y#30 = PROGRESS_Y [phi:rom_verify::@12->gotoxy#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z gotoxy.y
    // [756] phi gotoxy::x#30 = PROGRESS_X [phi:rom_verify::@12->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [1417] phi from rom_verify::@12 to rom_verify::@1 [phi:rom_verify::@12->rom_verify::@1]
    // [1417] phi rom_verify::y#3 = PROGRESS_Y [phi:rom_verify::@12->rom_verify::@1#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1417] phi rom_verify::progress_row_current#3 = 0 [phi:rom_verify::@12->rom_verify::@1#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z progress_row_current
    sta.z progress_row_current+1
    // [1417] phi rom_verify::rom_different_bytes#11 = 0 [phi:rom_verify::@12->rom_verify::@1#2] -- vduz1=vduc1 
    sta.z rom_different_bytes
    sta.z rom_different_bytes+1
    lda #<0>>$10
    sta.z rom_different_bytes+2
    lda #>0>>$10
    sta.z rom_different_bytes+3
    // [1417] phi rom_verify::ram_address#10 = (char *)$7800 [phi:rom_verify::@12->rom_verify::@1#3] -- pbum1=pbuc1 
    lda #<$7800
    sta ram_address
    lda #>$7800
    sta ram_address+1
    // [1417] phi rom_verify::bram_bank#11 = 0 [phi:rom_verify::@12->rom_verify::@1#4] -- vbum1=vbuc1 
    lda #0
    sta bram_bank
    // [1417] phi rom_verify::rom_address#12 = rom_verify::rom_address#0 [phi:rom_verify::@12->rom_verify::@1#5] -- register_copy 
    // rom_verify::@1
  __b1:
    // while (rom_address < rom_boundary)
    // [1418] if(rom_verify::rom_address#12<rom_verify::rom_boundary#0) goto rom_verify::@2 -- vduz1_lt_vdum2_then_la1 
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
    // [1419] return 
    rts
    // rom_verify::@2
  __b2:
    // unsigned int equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1420] rom_compare::bank_ram#0 = rom_verify::bram_bank#11 -- vbuz1=vbum2 
    lda bram_bank
    sta.z rom_compare.bank_ram
    // [1421] rom_compare::ptr_ram#1 = rom_verify::ram_address#10 -- pbuz1=pbum2 
    lda ram_address
    sta.z rom_compare.ptr_ram
    lda ram_address+1
    sta.z rom_compare.ptr_ram+1
    // [1422] rom_compare::rom_compare_address#0 = rom_verify::rom_address#12 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_compare.rom_compare_address
    lda.z rom_address+1
    sta.z rom_compare.rom_compare_address+1
    lda.z rom_address+2
    sta.z rom_compare.rom_compare_address+2
    lda.z rom_address+3
    sta.z rom_compare.rom_compare_address+3
    // [1423] call rom_compare
  // {asm{.byte $db}}
    // [2397] phi from rom_verify::@2 to rom_compare [phi:rom_verify::@2->rom_compare]
    // [2397] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#1 [phi:rom_verify::@2->rom_compare#0] -- register_copy 
    // [2397] phi rom_compare::rom_compare_size#11 = ROM_PROGRESS_CELL [phi:rom_verify::@2->rom_compare#1] -- vwuz1=vwuc1 
    lda #<ROM_PROGRESS_CELL
    sta.z rom_compare.rom_compare_size
    lda #>ROM_PROGRESS_CELL
    sta.z rom_compare.rom_compare_size+1
    // [2397] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#0 [phi:rom_verify::@2->rom_compare#2] -- register_copy 
    // [2397] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#0 [phi:rom_verify::@2->rom_compare#3] -- register_copy 
    jsr rom_compare
    // unsigned int equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1424] rom_compare::return#2 = rom_compare::equal_bytes#2
    // rom_verify::@13
    // [1425] rom_verify::equal_bytes#0 = rom_compare::return#2
    // if (progress_row_current == ROM_PROGRESS_ROW)
    // [1426] if(rom_verify::progress_row_current#3!=ROM_PROGRESS_ROW) goto rom_verify::@3 -- vwuz1_neq_vwuc1_then_la1 
    lda.z progress_row_current+1
    cmp #>ROM_PROGRESS_ROW
    bne __b3
    lda.z progress_row_current
    cmp #<ROM_PROGRESS_ROW
    bne __b3
    // rom_verify::@8
    // gotoxy(x, ++y);
    // [1427] rom_verify::y#1 = ++ rom_verify::y#3 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [1428] gotoxy::y#27 = rom_verify::y#1 -- vbuz1=vbum2 
    lda y
    sta.z gotoxy.y
    // [1429] call gotoxy
    // [756] phi from rom_verify::@8 to gotoxy [phi:rom_verify::@8->gotoxy]
    // [756] phi gotoxy::y#30 = gotoxy::y#27 [phi:rom_verify::@8->gotoxy#0] -- register_copy 
    // [756] phi gotoxy::x#30 = PROGRESS_X [phi:rom_verify::@8->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [1430] phi from rom_verify::@8 to rom_verify::@3 [phi:rom_verify::@8->rom_verify::@3]
    // [1430] phi rom_verify::y#10 = rom_verify::y#1 [phi:rom_verify::@8->rom_verify::@3#0] -- register_copy 
    // [1430] phi rom_verify::progress_row_current#4 = 0 [phi:rom_verify::@8->rom_verify::@3#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z progress_row_current
    sta.z progress_row_current+1
    // [1430] phi from rom_verify::@13 to rom_verify::@3 [phi:rom_verify::@13->rom_verify::@3]
    // [1430] phi rom_verify::y#10 = rom_verify::y#3 [phi:rom_verify::@13->rom_verify::@3#0] -- register_copy 
    // [1430] phi rom_verify::progress_row_current#4 = rom_verify::progress_row_current#3 [phi:rom_verify::@13->rom_verify::@3#1] -- register_copy 
    // rom_verify::@3
  __b3:
    // if (equal_bytes != ROM_PROGRESS_CELL)
    // [1431] if(rom_verify::equal_bytes#0!=ROM_PROGRESS_CELL) goto rom_verify::@4 -- vwuz1_neq_vwuc1_then_la1 
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
    // [1432] stackpush(char) = '=' -- _stackpushbyte_=vbuc1 
    lda #'='
    pha
    // [1433] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // rom_verify::@5
  __b5:
    // ram_address += ROM_PROGRESS_CELL
    // [1435] rom_verify::ram_address#1 = rom_verify::ram_address#10 + ROM_PROGRESS_CELL -- pbum1=pbum1_plus_vwuc1 
    lda ram_address
    clc
    adc #<ROM_PROGRESS_CELL
    sta ram_address
    lda ram_address+1
    adc #>ROM_PROGRESS_CELL
    sta ram_address+1
    // rom_address += ROM_PROGRESS_CELL
    // [1436] rom_verify::rom_address#1 = rom_verify::rom_address#12 + ROM_PROGRESS_CELL -- vduz1=vduz1_plus_vwuc1 
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
    // [1437] rom_verify::progress_row_current#11 = rom_verify::progress_row_current#4 + ROM_PROGRESS_CELL -- vwuz1=vwuz1_plus_vwuc1 
    lda.z progress_row_current
    clc
    adc #<ROM_PROGRESS_CELL
    sta.z progress_row_current
    lda.z progress_row_current+1
    adc #>ROM_PROGRESS_CELL
    sta.z progress_row_current+1
    // if (ram_address == BRAM_HIGH)
    // [1438] if(rom_verify::ram_address#1!=$c000) goto rom_verify::@6 -- pbum1_neq_vwuc1_then_la1 
    lda ram_address+1
    cmp #>$c000
    bne __b6
    lda ram_address
    cmp #<$c000
    bne __b6
    // rom_verify::@10
    // bram_bank++;
    // [1439] rom_verify::bram_bank#1 = ++ rom_verify::bram_bank#11 -- vbum1=_inc_vbum1 
    inc bram_bank
    // [1440] phi from rom_verify::@10 to rom_verify::@6 [phi:rom_verify::@10->rom_verify::@6]
    // [1440] phi rom_verify::bram_bank#24 = rom_verify::bram_bank#1 [phi:rom_verify::@10->rom_verify::@6#0] -- register_copy 
    // [1440] phi rom_verify::ram_address#6 = (char *)$a000 [phi:rom_verify::@10->rom_verify::@6#1] -- pbum1=pbuc1 
    lda #<$a000
    sta ram_address
    lda #>$a000
    sta ram_address+1
    // [1440] phi from rom_verify::@5 to rom_verify::@6 [phi:rom_verify::@5->rom_verify::@6]
    // [1440] phi rom_verify::bram_bank#24 = rom_verify::bram_bank#11 [phi:rom_verify::@5->rom_verify::@6#0] -- register_copy 
    // [1440] phi rom_verify::ram_address#6 = rom_verify::ram_address#1 [phi:rom_verify::@5->rom_verify::@6#1] -- register_copy 
    // rom_verify::@6
  __b6:
    // if (ram_address == RAM_HIGH)
    // [1441] if(rom_verify::ram_address#6!=$9800) goto rom_verify::@23 -- pbum1_neq_vwuc1_then_la1 
    lda ram_address+1
    cmp #>$9800
    bne __b7
    lda ram_address
    cmp #<$9800
    bne __b7
    // [1443] phi from rom_verify::@6 to rom_verify::@7 [phi:rom_verify::@6->rom_verify::@7]
    // [1443] phi rom_verify::ram_address#11 = (char *)$a000 [phi:rom_verify::@6->rom_verify::@7#0] -- pbum1=pbuc1 
    lda #<$a000
    sta ram_address
    lda #>$a000
    sta ram_address+1
    // [1443] phi rom_verify::bram_bank#10 = 1 [phi:rom_verify::@6->rom_verify::@7#1] -- vbum1=vbuc1 
    lda #1
    sta bram_bank
    // [1442] phi from rom_verify::@6 to rom_verify::@23 [phi:rom_verify::@6->rom_verify::@23]
    // rom_verify::@23
    // [1443] phi from rom_verify::@23 to rom_verify::@7 [phi:rom_verify::@23->rom_verify::@7]
    // [1443] phi rom_verify::ram_address#11 = rom_verify::ram_address#6 [phi:rom_verify::@23->rom_verify::@7#0] -- register_copy 
    // [1443] phi rom_verify::bram_bank#10 = rom_verify::bram_bank#24 [phi:rom_verify::@23->rom_verify::@7#1] -- register_copy 
    // rom_verify::@7
  __b7:
    // ROM_PROGRESS_CELL - equal_bytes
    // [1444] rom_verify::$16 = ROM_PROGRESS_CELL - rom_verify::equal_bytes#0 -- vwuz1=vwuc1_minus_vwuz1 
    lda #<ROM_PROGRESS_CELL
    sec
    sbc.z rom_verify__16
    sta.z rom_verify__16
    lda #>ROM_PROGRESS_CELL
    sbc.z rom_verify__16+1
    sta.z rom_verify__16+1
    // rom_different_bytes += (ROM_PROGRESS_CELL - equal_bytes)
    // [1445] rom_verify::rom_different_bytes#1 = rom_verify::rom_different_bytes#11 + rom_verify::$16 -- vduz1=vduz1_plus_vwuz2 
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
    // [1446] call snprintf_init
    // [1151] phi from rom_verify::@7 to snprintf_init [phi:rom_verify::@7->snprintf_init]
    // [1151] phi snprintf_init::s#26 = info_text [phi:rom_verify::@7->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1447] phi from rom_verify::@7 to rom_verify::@14 [phi:rom_verify::@7->rom_verify::@14]
    // rom_verify::@14
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1448] call printf_str
    // [1156] phi from rom_verify::@14 to printf_str [phi:rom_verify::@14->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:rom_verify::@14->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = rom_verify::s [phi:rom_verify::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@15
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1449] printf_ulong::uvalue#2 = rom_verify::rom_different_bytes#1 -- vduz1=vduz2 
    lda.z rom_different_bytes
    sta.z printf_ulong.uvalue
    lda.z rom_different_bytes+1
    sta.z printf_ulong.uvalue+1
    lda.z rom_different_bytes+2
    sta.z printf_ulong.uvalue+2
    lda.z rom_different_bytes+3
    sta.z printf_ulong.uvalue+3
    // [1450] call printf_ulong
    // [1470] phi from rom_verify::@15 to printf_ulong [phi:rom_verify::@15->printf_ulong]
    // [1470] phi printf_ulong::format_zero_padding#10 = 1 [phi:rom_verify::@15->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1470] phi printf_ulong::format_min_length#10 = 5 [phi:rom_verify::@15->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1470] phi printf_ulong::format_radix#10 = HEXADECIMAL [phi:rom_verify::@15->printf_ulong#2] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1470] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#2 [phi:rom_verify::@15->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1451] phi from rom_verify::@15 to rom_verify::@16 [phi:rom_verify::@15->rom_verify::@16]
    // rom_verify::@16
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1452] call printf_str
    // [1156] phi from rom_verify::@16 to printf_str [phi:rom_verify::@16->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:rom_verify::@16->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = rom_verify::s1 [phi:rom_verify::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@17
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1453] printf_uchar::uvalue#10 = rom_verify::bram_bank#10 -- vbuz1=vbum2 
    lda bram_bank
    sta.z printf_uchar.uvalue
    // [1454] call printf_uchar
    // [1236] phi from rom_verify::@17 to printf_uchar [phi:rom_verify::@17->printf_uchar]
    // [1236] phi printf_uchar::format_zero_padding#14 = 1 [phi:rom_verify::@17->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1236] phi printf_uchar::format_min_length#14 = 2 [phi:rom_verify::@17->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [1236] phi printf_uchar::putc#14 = &snputc [phi:rom_verify::@17->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1236] phi printf_uchar::format_radix#14 = HEXADECIMAL [phi:rom_verify::@17->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [1236] phi printf_uchar::uvalue#14 = printf_uchar::uvalue#10 [phi:rom_verify::@17->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1455] phi from rom_verify::@17 to rom_verify::@18 [phi:rom_verify::@17->rom_verify::@18]
    // rom_verify::@18
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1456] call printf_str
    // [1156] phi from rom_verify::@18 to printf_str [phi:rom_verify::@18->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:rom_verify::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = s3 [phi:rom_verify::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s3
    sta.z printf_str.s
    lda #>@s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@19
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1457] printf_uint::uvalue#11 = (unsigned int)rom_verify::ram_address#11 -- vwuz1=vwum2 
    lda ram_address
    sta.z printf_uint.uvalue
    lda ram_address+1
    sta.z printf_uint.uvalue+1
    // [1458] call printf_uint
    // [1810] phi from rom_verify::@19 to printf_uint [phi:rom_verify::@19->printf_uint]
    // [1810] phi printf_uint::format_zero_padding#14 = 1 [phi:rom_verify::@19->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [1810] phi printf_uint::format_min_length#14 = 4 [phi:rom_verify::@19->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [1810] phi printf_uint::putc#14 = &snputc [phi:rom_verify::@19->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [1810] phi printf_uint::format_radix#14 = HEXADECIMAL [phi:rom_verify::@19->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [1810] phi printf_uint::uvalue#14 = printf_uint::uvalue#11 [phi:rom_verify::@19->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1459] phi from rom_verify::@19 to rom_verify::@20 [phi:rom_verify::@19->rom_verify::@20]
    // rom_verify::@20
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1460] call printf_str
    // [1156] phi from rom_verify::@20 to printf_str [phi:rom_verify::@20->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:rom_verify::@20->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = rom_verify::s3 [phi:rom_verify::@20->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@21
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1461] printf_ulong::uvalue#3 = rom_verify::rom_address#1 -- vduz1=vduz2 
    lda.z rom_address
    sta.z printf_ulong.uvalue
    lda.z rom_address+1
    sta.z printf_ulong.uvalue+1
    lda.z rom_address+2
    sta.z printf_ulong.uvalue+2
    lda.z rom_address+3
    sta.z printf_ulong.uvalue+3
    // [1462] call printf_ulong
    // [1470] phi from rom_verify::@21 to printf_ulong [phi:rom_verify::@21->printf_ulong]
    // [1470] phi printf_ulong::format_zero_padding#10 = 1 [phi:rom_verify::@21->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1470] phi printf_ulong::format_min_length#10 = 5 [phi:rom_verify::@21->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1470] phi printf_ulong::format_radix#10 = HEXADECIMAL [phi:rom_verify::@21->printf_ulong#2] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1470] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#3 [phi:rom_verify::@21->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // rom_verify::@22
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1463] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1464] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1466] call display_action_text
    // [1247] phi from rom_verify::@22 to display_action_text [phi:rom_verify::@22->display_action_text]
    // [1247] phi display_action_text::info_text#19 = info_text [phi:rom_verify::@22->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1417] phi from rom_verify::@22 to rom_verify::@1 [phi:rom_verify::@22->rom_verify::@1]
    // [1417] phi rom_verify::y#3 = rom_verify::y#10 [phi:rom_verify::@22->rom_verify::@1#0] -- register_copy 
    // [1417] phi rom_verify::progress_row_current#3 = rom_verify::progress_row_current#11 [phi:rom_verify::@22->rom_verify::@1#1] -- register_copy 
    // [1417] phi rom_verify::rom_different_bytes#11 = rom_verify::rom_different_bytes#1 [phi:rom_verify::@22->rom_verify::@1#2] -- register_copy 
    // [1417] phi rom_verify::ram_address#10 = rom_verify::ram_address#11 [phi:rom_verify::@22->rom_verify::@1#3] -- register_copy 
    // [1417] phi rom_verify::bram_bank#11 = rom_verify::bram_bank#10 [phi:rom_verify::@22->rom_verify::@1#4] -- register_copy 
    // [1417] phi rom_verify::rom_address#12 = rom_verify::rom_address#1 [phi:rom_verify::@22->rom_verify::@1#5] -- register_copy 
    jmp __b1
    // rom_verify::@4
  __b4:
    // cputc('*')
    // [1467] stackpush(char) = '*' -- _stackpushbyte_=vbuc1 
    lda #'*'
    pha
    // [1468] callexecute cputc  -- call_vprc1 
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
    .label y = main.check_status_smc7_main__0
    .label ram_address = fopen.pathtoken_1
    .label bram_bank = main.check_status_vera3_main__0
    .label rom_bank_start = fopen.fopen__4
    .label file_size = rom_flash.rom_flash__29
}
.segment Code
  // printf_ulong
// Print an unsigned int using a specific format
// void printf_ulong(void (*putc)(char), __zp($30) unsigned long uvalue, __zp($ea) char format_min_length, char format_justify_left, char format_sign_always, __zp($e9) char format_zero_padding, char format_upper_case, __zp($e7) char format_radix)
printf_ulong: {
    .label uvalue = $30
    .label format_radix = $e7
    .label format_min_length = $ea
    .label format_zero_padding = $e9
    // printf_ulong::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1471] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // ultoa(uvalue, printf_buffer.digits, format.radix)
    // [1472] ultoa::value#1 = printf_ulong::uvalue#10
    // [1473] ultoa::radix#0 = printf_ulong::format_radix#10
    // [1474] call ultoa
    // Format number into buffer
    jsr ultoa
    // printf_ulong::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1475] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [1476] printf_number_buffer::format_min_length#0 = printf_ulong::format_min_length#10
    // [1477] printf_number_buffer::format_zero_padding#0 = printf_ulong::format_zero_padding#10
    // [1478] call printf_number_buffer
  // Print using format
    // [2362] phi from printf_ulong::@2 to printf_number_buffer [phi:printf_ulong::@2->printf_number_buffer]
    // [2362] phi printf_number_buffer::putc#10 = &snputc [phi:printf_ulong::@2->printf_number_buffer#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_number_buffer.putc
    lda #>snputc
    sta.z printf_number_buffer.putc+1
    // [2362] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_ulong::@2->printf_number_buffer#1] -- register_copy 
    // [2362] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#0 [phi:printf_ulong::@2->printf_number_buffer#2] -- register_copy 
    // [2362] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#0 [phi:printf_ulong::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_ulong::@return
    // }
    // [1479] return 
    rts
  .segment Data
    uvalue_1: .dword 0
}
.segment Code
  // rom_flash
// __mem() unsigned long rom_flash(__mem() char rom_chip, __mem() char rom_bank_start, __mem() unsigned long file_size)
rom_flash: {
    .label equal_bytes = $51
    .label equal_bytes_1 = $d7
    .label flash_errors_sector = $d9
    .label ram_address = $c0
    .label rom_address = $f5
    .label x = $f4
    // display_action_progress("Flashing ... (-) equal, (+) flashed, (!) error.")
    // [1481] call display_action_progress
  // Now we compare the RAM with the actual ROM contents.
    // [850] phi from rom_flash to display_action_progress [phi:rom_flash->display_action_progress]
    // [850] phi display_action_progress::info_text#18 = rom_flash::info_text [phi:rom_flash->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // rom_flash::@19
    // unsigned long rom_address_sector = rom_address_from_bank(rom_bank_start)
    // [1482] rom_address_from_bank::rom_bank#2 = rom_flash::rom_bank_start#0
    // [1483] call rom_address_from_bank
    // [2393] phi from rom_flash::@19 to rom_address_from_bank [phi:rom_flash::@19->rom_address_from_bank]
    // [2393] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#2 [phi:rom_flash::@19->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address_sector = rom_address_from_bank(rom_bank_start)
    // [1484] rom_address_from_bank::return#4 = rom_address_from_bank::return#0 -- vdum1=vduz2 
    lda.z rom_address_from_bank.return
    sta rom_address_from_bank.return_2
    lda.z rom_address_from_bank.return+1
    sta rom_address_from_bank.return_2+1
    lda.z rom_address_from_bank.return+2
    sta rom_address_from_bank.return_2+2
    lda.z rom_address_from_bank.return+3
    sta rom_address_from_bank.return_2+3
    // rom_flash::@20
    // [1485] rom_flash::rom_address_sector#0 = rom_address_from_bank::return#4
    // unsigned long rom_boundary = rom_address_sector + file_size
    // [1486] rom_flash::rom_boundary#0 = rom_flash::rom_address_sector#0 + rom_flash::file_size#0 -- vdum1=vdum2_plus_vdum3 
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
    // [1487] display_info_rom::rom_chip#2 = rom_flash::rom_chip#0 -- vbuz1=vbum2 
    lda rom_chip
    sta.z display_info_rom.rom_chip
    // [1488] call display_info_rom
    // [1270] phi from rom_flash::@20 to display_info_rom [phi:rom_flash::@20->display_info_rom]
    // [1270] phi display_info_rom::info_text#16 = rom_flash::info_text1 [phi:rom_flash::@20->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_rom.info_text
    lda #>info_text1
    sta.z display_info_rom.info_text+1
    // [1270] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#2 [phi:rom_flash::@20->display_info_rom#1] -- register_copy 
    // [1270] phi display_info_rom::info_status#16 = STATUS_FLASHING [phi:rom_flash::@20->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHING
    sta display_info_rom.info_status
    jsr display_info_rom
    // [1489] phi from rom_flash::@20 to rom_flash::@1 [phi:rom_flash::@20->rom_flash::@1]
    // [1489] phi rom_flash::y_sector#13 = PROGRESS_Y [phi:rom_flash::@20->rom_flash::@1#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y_sector
    // [1489] phi rom_flash::x_sector#10 = PROGRESS_X [phi:rom_flash::@20->rom_flash::@1#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [1489] phi rom_flash::flash_errors#10 = 0 [phi:rom_flash::@20->rom_flash::@1#2] -- vdum1=vduc1 
    lda #<0
    sta flash_errors
    sta flash_errors+1
    lda #<0>>$10
    sta flash_errors+2
    lda #>0>>$10
    sta flash_errors+3
    // [1489] phi rom_flash::ram_address_sector#11 = (char *)$7800 [phi:rom_flash::@20->rom_flash::@1#3] -- pbum1=pbuc1 
    lda #<$7800
    sta ram_address_sector
    lda #>$7800
    sta ram_address_sector+1
    // [1489] phi rom_flash::bram_bank_sector#14 = 0 [phi:rom_flash::@20->rom_flash::@1#4] -- vbum1=vbuc1 
    lda #0
    sta bram_bank_sector
    // [1489] phi rom_flash::rom_address_sector#12 = rom_flash::rom_address_sector#0 [phi:rom_flash::@20->rom_flash::@1#5] -- register_copy 
    // rom_flash::@1
  __b1:
    // while (rom_address_sector < rom_boundary)
    // [1490] if(rom_flash::rom_address_sector#12<rom_flash::rom_boundary#0) goto rom_flash::@2 -- vdum1_lt_vdum2_then_la1 
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
    // [1491] phi from rom_flash::@1 to rom_flash::@3 [phi:rom_flash::@1->rom_flash::@3]
    // rom_flash::@3
    // display_action_text("Flashed ...")
    // [1492] call display_action_text
    // [1247] phi from rom_flash::@3 to display_action_text [phi:rom_flash::@3->display_action_text]
    // [1247] phi display_action_text::info_text#19 = rom_flash::info_text2 [phi:rom_flash::@3->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z display_action_text.info_text
    lda #>info_text2
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // rom_flash::@return
    // }
    // [1493] return 
    rts
    // rom_flash::@2
  __b2:
    // unsigned int equal_bytes = rom_compare(bram_bank_sector, (ram_ptr_t)ram_address_sector, rom_address_sector, ROM_SECTOR)
    // [1494] rom_compare::bank_ram#1 = rom_flash::bram_bank_sector#14 -- vbuz1=vbum2 
    lda bram_bank_sector
    sta.z rom_compare.bank_ram
    // [1495] rom_compare::ptr_ram#2 = rom_flash::ram_address_sector#11 -- pbuz1=pbum2 
    lda ram_address_sector
    sta.z rom_compare.ptr_ram
    lda ram_address_sector+1
    sta.z rom_compare.ptr_ram+1
    // [1496] rom_compare::rom_compare_address#1 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_compare.rom_compare_address
    lda rom_address_sector+1
    sta.z rom_compare.rom_compare_address+1
    lda rom_address_sector+2
    sta.z rom_compare.rom_compare_address+2
    lda rom_address_sector+3
    sta.z rom_compare.rom_compare_address+3
    // [1497] call rom_compare
  // {asm{.byte $db}}
    // [2397] phi from rom_flash::@2 to rom_compare [phi:rom_flash::@2->rom_compare]
    // [2397] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#2 [phi:rom_flash::@2->rom_compare#0] -- register_copy 
    // [2397] phi rom_compare::rom_compare_size#11 = $1000 [phi:rom_flash::@2->rom_compare#1] -- vwuz1=vwuc1 
    lda #<$1000
    sta.z rom_compare.rom_compare_size
    lda #>$1000
    sta.z rom_compare.rom_compare_size+1
    // [2397] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#1 [phi:rom_flash::@2->rom_compare#2] -- register_copy 
    // [2397] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#1 [phi:rom_flash::@2->rom_compare#3] -- register_copy 
    jsr rom_compare
    // unsigned int equal_bytes = rom_compare(bram_bank_sector, (ram_ptr_t)ram_address_sector, rom_address_sector, ROM_SECTOR)
    // [1498] rom_compare::return#3 = rom_compare::equal_bytes#2
    // rom_flash::@21
    // [1499] rom_flash::equal_bytes#0 = rom_compare::return#3
    // if (equal_bytes != ROM_SECTOR)
    // [1500] if(rom_flash::equal_bytes#0!=$1000) goto rom_flash::@5 -- vwuz1_neq_vwuc1_then_la1 
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
    // [1501] cputsxy::x#1 = rom_flash::x_sector#10 -- vbuz1=vbum2 
    lda x_sector
    sta.z cputsxy.x
    // [1502] cputsxy::y#1 = rom_flash::y_sector#13 -- vbuz1=vbum2 
    lda y_sector
    sta.z cputsxy.y
    // [1503] call cputsxy
    // [843] phi from rom_flash::@16 to cputsxy [phi:rom_flash::@16->cputsxy]
    // [843] phi cputsxy::s#4 = rom_flash::s [phi:rom_flash::@16->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z cputsxy.s
    lda #>s
    sta.z cputsxy.s+1
    // [843] phi cputsxy::y#4 = cputsxy::y#1 [phi:rom_flash::@16->cputsxy#1] -- register_copy 
    // [843] phi cputsxy::x#4 = cputsxy::x#1 [phi:rom_flash::@16->cputsxy#2] -- register_copy 
    jsr cputsxy
    // [1504] phi from rom_flash::@12 rom_flash::@16 to rom_flash::@4 [phi:rom_flash::@12/rom_flash::@16->rom_flash::@4]
    // [1504] phi rom_flash::flash_errors#13 = rom_flash::flash_errors#1 [phi:rom_flash::@12/rom_flash::@16->rom_flash::@4#0] -- register_copy 
    // rom_flash::@4
  __b4:
    // ram_address_sector += ROM_SECTOR
    // [1505] rom_flash::ram_address_sector#1 = rom_flash::ram_address_sector#11 + $1000 -- pbum1=pbum1_plus_vwuc1 
    lda ram_address_sector
    clc
    adc #<$1000
    sta ram_address_sector
    lda ram_address_sector+1
    adc #>$1000
    sta ram_address_sector+1
    // rom_address_sector += ROM_SECTOR
    // [1506] rom_flash::rom_address_sector#1 = rom_flash::rom_address_sector#12 + $1000 -- vdum1=vdum1_plus_vwuc1 
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
    // [1507] if(rom_flash::ram_address_sector#1!=$c000) goto rom_flash::@13 -- pbum1_neq_vwuc1_then_la1 
    lda ram_address_sector+1
    cmp #>$c000
    bne __b13
    lda ram_address_sector
    cmp #<$c000
    bne __b13
    // rom_flash::@17
    // bram_bank_sector++;
    // [1508] rom_flash::bram_bank_sector#1 = ++ rom_flash::bram_bank_sector#14 -- vbum1=_inc_vbum1 
    inc bram_bank_sector
    // [1509] phi from rom_flash::@17 to rom_flash::@13 [phi:rom_flash::@17->rom_flash::@13]
    // [1509] phi rom_flash::bram_bank_sector#38 = rom_flash::bram_bank_sector#1 [phi:rom_flash::@17->rom_flash::@13#0] -- register_copy 
    // [1509] phi rom_flash::ram_address_sector#8 = (char *)$a000 [phi:rom_flash::@17->rom_flash::@13#1] -- pbum1=pbuc1 
    lda #<$a000
    sta ram_address_sector
    lda #>$a000
    sta ram_address_sector+1
    // [1509] phi from rom_flash::@4 to rom_flash::@13 [phi:rom_flash::@4->rom_flash::@13]
    // [1509] phi rom_flash::bram_bank_sector#38 = rom_flash::bram_bank_sector#14 [phi:rom_flash::@4->rom_flash::@13#0] -- register_copy 
    // [1509] phi rom_flash::ram_address_sector#8 = rom_flash::ram_address_sector#1 [phi:rom_flash::@4->rom_flash::@13#1] -- register_copy 
    // rom_flash::@13
  __b13:
    // if (ram_address_sector == RAM_HIGH)
    // [1510] if(rom_flash::ram_address_sector#8!=$9800) goto rom_flash::@44 -- pbum1_neq_vwuc1_then_la1 
    lda ram_address_sector+1
    cmp #>$9800
    bne __b14
    lda ram_address_sector
    cmp #<$9800
    bne __b14
    // [1512] phi from rom_flash::@13 to rom_flash::@14 [phi:rom_flash::@13->rom_flash::@14]
    // [1512] phi rom_flash::ram_address_sector#15 = (char *)$a000 [phi:rom_flash::@13->rom_flash::@14#0] -- pbum1=pbuc1 
    lda #<$a000
    sta ram_address_sector
    lda #>$a000
    sta ram_address_sector+1
    // [1512] phi rom_flash::bram_bank_sector#12 = 1 [phi:rom_flash::@13->rom_flash::@14#1] -- vbum1=vbuc1 
    lda #1
    sta bram_bank_sector
    // [1511] phi from rom_flash::@13 to rom_flash::@44 [phi:rom_flash::@13->rom_flash::@44]
    // rom_flash::@44
    // [1512] phi from rom_flash::@44 to rom_flash::@14 [phi:rom_flash::@44->rom_flash::@14]
    // [1512] phi rom_flash::ram_address_sector#15 = rom_flash::ram_address_sector#8 [phi:rom_flash::@44->rom_flash::@14#0] -- register_copy 
    // [1512] phi rom_flash::bram_bank_sector#12 = rom_flash::bram_bank_sector#38 [phi:rom_flash::@44->rom_flash::@14#1] -- register_copy 
    // rom_flash::@14
  __b14:
    // x_sector += 8
    // [1513] rom_flash::x_sector#1 = rom_flash::x_sector#10 + 8 -- vbum1=vbum1_plus_vbuc1 
    lda #8
    clc
    adc x_sector
    sta x_sector
    // rom_address_sector % ROM_PROGRESS_ROW
    // [1514] rom_flash::$29 = rom_flash::rom_address_sector#1 & ROM_PROGRESS_ROW-1 -- vdum1=vdum2_band_vduc1 
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
    // [1515] if(0!=rom_flash::$29) goto rom_flash::@15 -- 0_neq_vdum1_then_la1 
    lda rom_flash__29
    ora rom_flash__29+1
    ora rom_flash__29+2
    ora rom_flash__29+3
    bne __b15
    // rom_flash::@18
    // y_sector++;
    // [1516] rom_flash::y_sector#1 = ++ rom_flash::y_sector#13 -- vbum1=_inc_vbum1 
    inc y_sector
    // [1517] phi from rom_flash::@18 to rom_flash::@15 [phi:rom_flash::@18->rom_flash::@15]
    // [1517] phi rom_flash::y_sector#18 = rom_flash::y_sector#1 [phi:rom_flash::@18->rom_flash::@15#0] -- register_copy 
    // [1517] phi rom_flash::x_sector#20 = PROGRESS_X [phi:rom_flash::@18->rom_flash::@15#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [1517] phi from rom_flash::@14 to rom_flash::@15 [phi:rom_flash::@14->rom_flash::@15]
    // [1517] phi rom_flash::y_sector#18 = rom_flash::y_sector#13 [phi:rom_flash::@14->rom_flash::@15#0] -- register_copy 
    // [1517] phi rom_flash::x_sector#20 = rom_flash::x_sector#1 [phi:rom_flash::@14->rom_flash::@15#1] -- register_copy 
    // rom_flash::@15
  __b15:
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1518] call snprintf_init
    // [1151] phi from rom_flash::@15 to snprintf_init [phi:rom_flash::@15->snprintf_init]
    // [1151] phi snprintf_init::s#26 = info_text [phi:rom_flash::@15->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // rom_flash::@40
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1519] printf_ulong::uvalue#6 = rom_flash::flash_errors#13 -- vduz1=vdum2 
    lda flash_errors
    sta.z printf_ulong.uvalue
    lda flash_errors+1
    sta.z printf_ulong.uvalue+1
    lda flash_errors+2
    sta.z printf_ulong.uvalue+2
    lda flash_errors+3
    sta.z printf_ulong.uvalue+3
    // [1520] call printf_ulong
    // [1470] phi from rom_flash::@40 to printf_ulong [phi:rom_flash::@40->printf_ulong]
    // [1470] phi printf_ulong::format_zero_padding#10 = 0 [phi:rom_flash::@40->printf_ulong#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_ulong.format_zero_padding
    // [1470] phi printf_ulong::format_min_length#10 = 0 [phi:rom_flash::@40->printf_ulong#1] -- vbuz1=vbuc1 
    sta.z printf_ulong.format_min_length
    // [1470] phi printf_ulong::format_radix#10 = DECIMAL [phi:rom_flash::@40->printf_ulong#2] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_ulong.format_radix
    // [1470] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#6 [phi:rom_flash::@40->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1521] phi from rom_flash::@40 to rom_flash::@41 [phi:rom_flash::@40->rom_flash::@41]
    // rom_flash::@41
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1522] call printf_str
    // [1156] phi from rom_flash::@41 to printf_str [phi:rom_flash::@41->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:rom_flash::@41->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = rom_flash::s6 [phi:rom_flash::@41->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@42
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1523] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1524] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_FLASHING, info_text)
    // [1526] display_info_rom::rom_chip#3 = rom_flash::rom_chip#0 -- vbuz1=vbum2 
    lda rom_chip
    sta.z display_info_rom.rom_chip
    // [1527] call display_info_rom
    // [1270] phi from rom_flash::@42 to display_info_rom [phi:rom_flash::@42->display_info_rom]
    // [1270] phi display_info_rom::info_text#16 = info_text [phi:rom_flash::@42->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1270] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#3 [phi:rom_flash::@42->display_info_rom#1] -- register_copy 
    // [1270] phi display_info_rom::info_status#16 = STATUS_FLASHING [phi:rom_flash::@42->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHING
    sta display_info_rom.info_status
    jsr display_info_rom
    // [1489] phi from rom_flash::@42 to rom_flash::@1 [phi:rom_flash::@42->rom_flash::@1]
    // [1489] phi rom_flash::y_sector#13 = rom_flash::y_sector#18 [phi:rom_flash::@42->rom_flash::@1#0] -- register_copy 
    // [1489] phi rom_flash::x_sector#10 = rom_flash::x_sector#20 [phi:rom_flash::@42->rom_flash::@1#1] -- register_copy 
    // [1489] phi rom_flash::flash_errors#10 = rom_flash::flash_errors#13 [phi:rom_flash::@42->rom_flash::@1#2] -- register_copy 
    // [1489] phi rom_flash::ram_address_sector#11 = rom_flash::ram_address_sector#15 [phi:rom_flash::@42->rom_flash::@1#3] -- register_copy 
    // [1489] phi rom_flash::bram_bank_sector#14 = rom_flash::bram_bank_sector#12 [phi:rom_flash::@42->rom_flash::@1#4] -- register_copy 
    // [1489] phi rom_flash::rom_address_sector#12 = rom_flash::rom_address_sector#1 [phi:rom_flash::@42->rom_flash::@1#5] -- register_copy 
    jmp __b1
    // [1528] phi from rom_flash::@21 to rom_flash::@5 [phi:rom_flash::@21->rom_flash::@5]
  __b3:
    // [1528] phi rom_flash::retries#12 = 0 [phi:rom_flash::@21->rom_flash::@5#0] -- vbum1=vbuc1 
    lda #0
    sta retries
    // [1528] phi rom_flash::flash_errors_sector#11 = 0 [phi:rom_flash::@21->rom_flash::@5#1] -- vwuz1=vwuc1 
    sta.z flash_errors_sector
    sta.z flash_errors_sector+1
    // [1528] phi from rom_flash::@43 to rom_flash::@5 [phi:rom_flash::@43->rom_flash::@5]
    // [1528] phi rom_flash::retries#12 = rom_flash::retries#1 [phi:rom_flash::@43->rom_flash::@5#0] -- register_copy 
    // [1528] phi rom_flash::flash_errors_sector#11 = rom_flash::flash_errors_sector#10 [phi:rom_flash::@43->rom_flash::@5#1] -- register_copy 
    // rom_flash::@5
  __b5:
    // rom_sector_erase(rom_address_sector)
    // [1529] rom_sector_erase::address#0 = rom_flash::rom_address_sector#12 -- vdum1=vdum2 
    lda rom_address_sector
    sta rom_sector_erase.address
    lda rom_address_sector+1
    sta rom_sector_erase.address+1
    lda rom_address_sector+2
    sta rom_sector_erase.address+2
    lda rom_address_sector+3
    sta rom_sector_erase.address+3
    // [1530] call rom_sector_erase
    // [2453] phi from rom_flash::@5 to rom_sector_erase [phi:rom_flash::@5->rom_sector_erase]
    jsr rom_sector_erase
    // rom_flash::@22
    // unsigned long rom_sector_boundary = rom_address_sector + ROM_SECTOR
    // [1531] rom_flash::rom_sector_boundary#0 = rom_flash::rom_address_sector#12 + $1000 -- vdum1=vdum2_plus_vwuc1 
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
    // [1532] gotoxy::x#28 = rom_flash::x_sector#10 -- vbuz1=vbum2 
    lda x_sector
    sta.z gotoxy.x
    // [1533] gotoxy::y#28 = rom_flash::y_sector#13 -- vbuz1=vbum2 
    lda y_sector
    sta.z gotoxy.y
    // [1534] call gotoxy
    // [756] phi from rom_flash::@22 to gotoxy [phi:rom_flash::@22->gotoxy]
    // [756] phi gotoxy::y#30 = gotoxy::y#28 [phi:rom_flash::@22->gotoxy#0] -- register_copy 
    // [756] phi gotoxy::x#30 = gotoxy::x#28 [phi:rom_flash::@22->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1535] phi from rom_flash::@22 to rom_flash::@23 [phi:rom_flash::@22->rom_flash::@23]
    // rom_flash::@23
    // printf("........")
    // [1536] call printf_str
    // [1156] phi from rom_flash::@23 to printf_str [phi:rom_flash::@23->printf_str]
    // [1156] phi printf_str::putc#71 = &cputc [phi:rom_flash::@23->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = rom_flash::s1 [phi:rom_flash::@23->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@24
    // [1537] rom_flash::rom_address#26 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_address
    lda rom_address_sector+1
    sta.z rom_address+1
    lda rom_address_sector+2
    sta.z rom_address+2
    lda rom_address_sector+3
    sta.z rom_address+3
    // [1538] rom_flash::ram_address#26 = rom_flash::ram_address_sector#11 -- pbuz1=pbum2 
    lda ram_address_sector
    sta.z ram_address
    lda ram_address_sector+1
    sta.z ram_address+1
    // [1539] rom_flash::x#26 = rom_flash::x_sector#10 -- vbuz1=vbum2 
    lda x_sector
    sta.z x
    // [1540] phi from rom_flash::@10 rom_flash::@24 to rom_flash::@6 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6]
    // [1540] phi rom_flash::x#10 = rom_flash::x#1 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#0] -- register_copy 
    // [1540] phi rom_flash::ram_address#10 = rom_flash::ram_address#1 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#1] -- register_copy 
    // [1540] phi rom_flash::flash_errors_sector#10 = rom_flash::flash_errors_sector#8 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#2] -- register_copy 
    // [1540] phi rom_flash::rom_address#11 = rom_flash::rom_address#1 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#3] -- register_copy 
    // rom_flash::@6
  __b6:
    // while (rom_address < rom_sector_boundary)
    // [1541] if(rom_flash::rom_address#11<rom_flash::rom_sector_boundary#0) goto rom_flash::@7 -- vduz1_lt_vdum2_then_la1 
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
    // [1542] rom_flash::retries#1 = ++ rom_flash::retries#12 -- vbum1=_inc_vbum1 
    inc retries
    // while (flash_errors_sector && retries <= 3)
    // [1543] if(0==rom_flash::flash_errors_sector#10) goto rom_flash::@12 -- 0_eq_vwuz1_then_la1 
    lda.z flash_errors_sector
    ora.z flash_errors_sector+1
    beq __b12
    // rom_flash::@43
    // [1544] if(rom_flash::retries#1<3+1) goto rom_flash::@5 -- vbum1_lt_vbuc1_then_la1 
    lda retries
    cmp #3+1
    bcs !__b5+
    jmp __b5
  !__b5:
    // rom_flash::@12
  __b12:
    // flash_errors += flash_errors_sector
    // [1545] rom_flash::flash_errors#1 = rom_flash::flash_errors#10 + rom_flash::flash_errors_sector#10 -- vdum1=vdum1_plus_vwuz2 
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
    // [1546] printf_ulong::uvalue#5 = rom_flash::flash_errors_sector#10 + rom_flash::flash_errors#10 -- vdum1=vwuz2_plus_vdum3 
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
    // [1547] call snprintf_init
    // [1151] phi from rom_flash::@7 to snprintf_init [phi:rom_flash::@7->snprintf_init]
    // [1151] phi snprintf_init::s#26 = info_text [phi:rom_flash::@7->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1548] phi from rom_flash::@7 to rom_flash::@25 [phi:rom_flash::@7->rom_flash::@25]
    // rom_flash::@25
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1549] call printf_str
    // [1156] phi from rom_flash::@25 to printf_str [phi:rom_flash::@25->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:rom_flash::@25->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = rom_flash::s2 [phi:rom_flash::@25->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@26
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1550] printf_uchar::uvalue#11 = rom_flash::bram_bank_sector#14 -- vbuz1=vbum2 
    lda bram_bank_sector
    sta.z printf_uchar.uvalue
    // [1551] call printf_uchar
    // [1236] phi from rom_flash::@26 to printf_uchar [phi:rom_flash::@26->printf_uchar]
    // [1236] phi printf_uchar::format_zero_padding#14 = 1 [phi:rom_flash::@26->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1236] phi printf_uchar::format_min_length#14 = 2 [phi:rom_flash::@26->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [1236] phi printf_uchar::putc#14 = &snputc [phi:rom_flash::@26->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1236] phi printf_uchar::format_radix#14 = HEXADECIMAL [phi:rom_flash::@26->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [1236] phi printf_uchar::uvalue#14 = printf_uchar::uvalue#11 [phi:rom_flash::@26->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1552] phi from rom_flash::@26 to rom_flash::@27 [phi:rom_flash::@26->rom_flash::@27]
    // rom_flash::@27
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1553] call printf_str
    // [1156] phi from rom_flash::@27 to printf_str [phi:rom_flash::@27->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:rom_flash::@27->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = s3 [phi:rom_flash::@27->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@28
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1554] printf_uint::uvalue#12 = (unsigned int)rom_flash::ram_address_sector#11 -- vwuz1=vwum2 
    lda ram_address_sector
    sta.z printf_uint.uvalue
    lda ram_address_sector+1
    sta.z printf_uint.uvalue+1
    // [1555] call printf_uint
    // [1810] phi from rom_flash::@28 to printf_uint [phi:rom_flash::@28->printf_uint]
    // [1810] phi printf_uint::format_zero_padding#14 = 1 [phi:rom_flash::@28->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [1810] phi printf_uint::format_min_length#14 = 4 [phi:rom_flash::@28->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [1810] phi printf_uint::putc#14 = &snputc [phi:rom_flash::@28->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [1810] phi printf_uint::format_radix#14 = HEXADECIMAL [phi:rom_flash::@28->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [1810] phi printf_uint::uvalue#14 = printf_uint::uvalue#12 [phi:rom_flash::@28->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1556] phi from rom_flash::@28 to rom_flash::@29 [phi:rom_flash::@28->rom_flash::@29]
    // rom_flash::@29
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1557] call printf_str
    // [1156] phi from rom_flash::@29 to printf_str [phi:rom_flash::@29->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:rom_flash::@29->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = rom_flash::s4 [phi:rom_flash::@29->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@30
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1558] printf_ulong::uvalue#4 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z printf_ulong.uvalue
    lda rom_address_sector+1
    sta.z printf_ulong.uvalue+1
    lda rom_address_sector+2
    sta.z printf_ulong.uvalue+2
    lda rom_address_sector+3
    sta.z printf_ulong.uvalue+3
    // [1559] call printf_ulong
    // [1470] phi from rom_flash::@30 to printf_ulong [phi:rom_flash::@30->printf_ulong]
    // [1470] phi printf_ulong::format_zero_padding#10 = 1 [phi:rom_flash::@30->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1470] phi printf_ulong::format_min_length#10 = 5 [phi:rom_flash::@30->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1470] phi printf_ulong::format_radix#10 = HEXADECIMAL [phi:rom_flash::@30->printf_ulong#2] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1470] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#4 [phi:rom_flash::@30->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1560] phi from rom_flash::@30 to rom_flash::@31 [phi:rom_flash::@30->rom_flash::@31]
    // rom_flash::@31
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1561] call printf_str
    // [1156] phi from rom_flash::@31 to printf_str [phi:rom_flash::@31->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:rom_flash::@31->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = rom_flash::s5 [phi:rom_flash::@31->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@32
    // [1562] printf_ulong::uvalue#16 = printf_ulong::uvalue#5 -- vduz1=vdum2 
    lda printf_ulong.uvalue_1
    sta.z printf_ulong.uvalue
    lda printf_ulong.uvalue_1+1
    sta.z printf_ulong.uvalue+1
    lda printf_ulong.uvalue_1+2
    sta.z printf_ulong.uvalue+2
    lda printf_ulong.uvalue_1+3
    sta.z printf_ulong.uvalue+3
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1563] call printf_ulong
    // [1470] phi from rom_flash::@32 to printf_ulong [phi:rom_flash::@32->printf_ulong]
    // [1470] phi printf_ulong::format_zero_padding#10 = 0 [phi:rom_flash::@32->printf_ulong#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_ulong.format_zero_padding
    // [1470] phi printf_ulong::format_min_length#10 = 0 [phi:rom_flash::@32->printf_ulong#1] -- vbuz1=vbuc1 
    sta.z printf_ulong.format_min_length
    // [1470] phi printf_ulong::format_radix#10 = DECIMAL [phi:rom_flash::@32->printf_ulong#2] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_ulong.format_radix
    // [1470] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#16 [phi:rom_flash::@32->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1564] phi from rom_flash::@32 to rom_flash::@33 [phi:rom_flash::@32->rom_flash::@33]
    // rom_flash::@33
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1565] call printf_str
    // [1156] phi from rom_flash::@33 to printf_str [phi:rom_flash::@33->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:rom_flash::@33->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = rom_flash::s6 [phi:rom_flash::@33->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@34
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1566] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1567] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1569] call display_action_text
    // [1247] phi from rom_flash::@34 to display_action_text [phi:rom_flash::@34->display_action_text]
    // [1247] phi display_action_text::info_text#19 = info_text [phi:rom_flash::@34->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // rom_flash::@35
    // unsigned long written_bytes = rom_write(bram_bank, (ram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1570] rom_write::flash_ram_bank#0 = rom_flash::bram_bank_sector#14 -- vbuz1=vbum2 
    lda bram_bank_sector
    sta.z rom_write.flash_ram_bank
    // [1571] rom_write::flash_ram_address#1 = rom_flash::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_write.flash_ram_address
    lda.z ram_address+1
    sta.z rom_write.flash_ram_address+1
    // [1572] rom_write::flash_rom_address#1 = rom_flash::rom_address#11 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_write.flash_rom_address
    lda.z rom_address+1
    sta.z rom_write.flash_rom_address+1
    lda.z rom_address+2
    sta.z rom_write.flash_rom_address+2
    lda.z rom_address+3
    sta.z rom_write.flash_rom_address+3
    // [1573] call rom_write
    jsr rom_write
    // rom_flash::@36
    // rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1574] rom_compare::bank_ram#2 = rom_flash::bram_bank_sector#14 -- vbuz1=vbum2 
    lda bram_bank_sector
    sta.z rom_compare.bank_ram
    // [1575] rom_compare::ptr_ram#3 = rom_flash::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_compare.ptr_ram
    lda.z ram_address+1
    sta.z rom_compare.ptr_ram+1
    // [1576] rom_compare::rom_compare_address#2 = rom_flash::rom_address#11 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_compare.rom_compare_address
    lda.z rom_address+1
    sta.z rom_compare.rom_compare_address+1
    lda.z rom_address+2
    sta.z rom_compare.rom_compare_address+2
    lda.z rom_address+3
    sta.z rom_compare.rom_compare_address+3
    // [1577] call rom_compare
    // [2397] phi from rom_flash::@36 to rom_compare [phi:rom_flash::@36->rom_compare]
    // [2397] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#3 [phi:rom_flash::@36->rom_compare#0] -- register_copy 
    // [2397] phi rom_compare::rom_compare_size#11 = ROM_PROGRESS_CELL [phi:rom_flash::@36->rom_compare#1] -- vwuz1=vwuc1 
    lda #<ROM_PROGRESS_CELL
    sta.z rom_compare.rom_compare_size
    lda #>ROM_PROGRESS_CELL
    sta.z rom_compare.rom_compare_size+1
    // [2397] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#2 [phi:rom_flash::@36->rom_compare#2] -- register_copy 
    // [2397] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#2 [phi:rom_flash::@36->rom_compare#3] -- register_copy 
    jsr rom_compare
    // rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1578] rom_compare::return#4 = rom_compare::equal_bytes#2
    // rom_flash::@37
    // equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1579] rom_flash::equal_bytes#1 = rom_compare::return#4 -- vwuz1=vwuz2 
    lda.z rom_compare.return
    sta.z equal_bytes_1
    lda.z rom_compare.return+1
    sta.z equal_bytes_1+1
    // gotoxy(x, y)
    // [1580] gotoxy::x#29 = rom_flash::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1581] gotoxy::y#29 = rom_flash::y_sector#13 -- vbuz1=vbum2 
    lda y_sector
    sta.z gotoxy.y
    // [1582] call gotoxy
    // [756] phi from rom_flash::@37 to gotoxy [phi:rom_flash::@37->gotoxy]
    // [756] phi gotoxy::y#30 = gotoxy::y#29 [phi:rom_flash::@37->gotoxy#0] -- register_copy 
    // [756] phi gotoxy::x#30 = gotoxy::x#29 [phi:rom_flash::@37->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_flash::@38
    // if (equal_bytes != ROM_PROGRESS_CELL)
    // [1583] if(rom_flash::equal_bytes#1!=ROM_PROGRESS_CELL) goto rom_flash::@9 -- vwuz1_neq_vwuc1_then_la1 
    lda.z equal_bytes_1+1
    cmp #>ROM_PROGRESS_CELL
    bne __b9
    lda.z equal_bytes_1
    cmp #<ROM_PROGRESS_CELL
    bne __b9
    // rom_flash::@11
    // cputcxy(x,y,'+')
    // [1584] cputcxy::x#14 = rom_flash::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1585] cputcxy::y#14 = rom_flash::y_sector#13 -- vbuz1=vbum2 
    lda y_sector
    sta.z cputcxy.y
    // [1586] call cputcxy
    // [2039] phi from rom_flash::@11 to cputcxy [phi:rom_flash::@11->cputcxy]
    // [2039] phi cputcxy::c#15 = '+' [phi:rom_flash::@11->cputcxy#0] -- vbuz1=vbuc1 
    lda #'+'
    sta.z cputcxy.c
    // [2039] phi cputcxy::y#15 = cputcxy::y#14 [phi:rom_flash::@11->cputcxy#1] -- register_copy 
    // [2039] phi cputcxy::x#15 = cputcxy::x#14 [phi:rom_flash::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [1587] phi from rom_flash::@11 rom_flash::@39 to rom_flash::@10 [phi:rom_flash::@11/rom_flash::@39->rom_flash::@10]
    // [1587] phi rom_flash::flash_errors_sector#8 = rom_flash::flash_errors_sector#10 [phi:rom_flash::@11/rom_flash::@39->rom_flash::@10#0] -- register_copy 
    // rom_flash::@10
  __b10:
    // ram_address += ROM_PROGRESS_CELL
    // [1588] rom_flash::ram_address#1 = rom_flash::ram_address#10 + ROM_PROGRESS_CELL -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address
    clc
    adc #<ROM_PROGRESS_CELL
    sta.z ram_address
    lda.z ram_address+1
    adc #>ROM_PROGRESS_CELL
    sta.z ram_address+1
    // rom_address += ROM_PROGRESS_CELL
    // [1589] rom_flash::rom_address#1 = rom_flash::rom_address#11 + ROM_PROGRESS_CELL -- vduz1=vduz1_plus_vwuc1 
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
    // [1590] rom_flash::x#1 = ++ rom_flash::x#10 -- vbuz1=_inc_vbuz1 
    inc.z x
    jmp __b6
    // rom_flash::@9
  __b9:
    // cputcxy(x,y,'!')
    // [1591] cputcxy::x#13 = rom_flash::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1592] cputcxy::y#13 = rom_flash::y_sector#13 -- vbuz1=vbum2 
    lda y_sector
    sta.z cputcxy.y
    // [1593] call cputcxy
    // [2039] phi from rom_flash::@9 to cputcxy [phi:rom_flash::@9->cputcxy]
    // [2039] phi cputcxy::c#15 = '!' [phi:rom_flash::@9->cputcxy#0] -- vbuz1=vbuc1 
    lda #'!'
    sta.z cputcxy.c
    // [2039] phi cputcxy::y#15 = cputcxy::y#13 [phi:rom_flash::@9->cputcxy#1] -- register_copy 
    // [2039] phi cputcxy::x#15 = cputcxy::x#13 [phi:rom_flash::@9->cputcxy#2] -- register_copy 
    jsr cputcxy
    // rom_flash::@39
    // flash_errors_sector++;
    // [1594] rom_flash::flash_errors_sector#1 = ++ rom_flash::flash_errors_sector#10 -- vwuz1=_inc_vwuz1 
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
    .label rom_address_sector = main.rom_file_modulo
    rom_boundary: .dword 0
    .label ram_address_sector = fgets.stream
    rom_sector_boundary: .dword 0
    .label retries = rom_get_release.rom_get_release__0
    .label flash_errors = rom_read.rom_read__11
    .label bram_bank_sector = main.check_status_vera5_main__0
    .label x_sector = main.check_status_vera4_main__0
    .label y_sector = main.check_status_smc12_main__0
    .label rom_chip = main.check_status_card_roms1_check_status_rom1_main__0
    .label rom_bank_start = fopen.fopen__4
    .label file_size = main.rom_flash_errors
    .label return = rom_read.rom_read__11
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
// __mem() unsigned int smc_flash(__zp($3d) unsigned int smc_bytes_total)
smc_flash: {
    .label smc_flash__26 = $ea
    .label smc_flash__27 = $ea
    .label cx16_k_i2c_write_byte1_return = $ef
    .label smc_bootloader_start = $ef
    .label smc_bootloader_not_activated1 = $2d
    // Waiting a bit to ensure the bootloader is activated.
    .label smc_bootloader_activation_countdown = $b1
    // Waiting a bit to ensure the bootloader is activated.
    .label smc_bootloader_activation_countdown_1 = $ee
    .label smc_bootloader_not_activated = $2d
    .label smc_byte_upload = $5b
    .label smc_ram_ptr = $cd
    .label smc_bytes_checksum = $ea
    .label smc_commit_result = $2d
    .label smc_attempts_flashed = $69
    .label smc_row_bytes = $76
    .label smc_attempts_total = $7c
    .label y = $be
    .label smc_bytes_total = $3d
    // display_action_progress("To start the SMC update, do the below action ...")
    // [1596] call display_action_progress
    // [850] phi from smc_flash to display_action_progress [phi:smc_flash->display_action_progress]
    // [850] phi display_action_progress::info_text#18 = smc_flash::info_text [phi:smc_flash->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // smc_flash::@25
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [1597] smc_flash::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [1598] smc_flash::cx16_k_i2c_write_byte1_offset = $8f -- vbum1=vbuc1 
    lda #$8f
    sta cx16_k_i2c_write_byte1_offset
    // [1599] smc_flash::cx16_k_i2c_write_byte1_value = $31 -- vbum1=vbuc1 
    lda #$31
    sta cx16_k_i2c_write_byte1_value
    // smc_flash::cx16_k_i2c_write_byte1
    // unsigned char result
    // [1600] smc_flash::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
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
    // [1602] smc_flash::cx16_k_i2c_write_byte1_return#0 = smc_flash::cx16_k_i2c_write_byte1_result -- vbuz1=vbum2 
    lda cx16_k_i2c_write_byte1_result
    sta.z cx16_k_i2c_write_byte1_return
    // smc_flash::cx16_k_i2c_write_byte1_@return
    // }
    // [1603] smc_flash::cx16_k_i2c_write_byte1_return#1 = smc_flash::cx16_k_i2c_write_byte1_return#0
    // smc_flash::@22
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [1604] smc_flash::smc_bootloader_start#0 = smc_flash::cx16_k_i2c_write_byte1_return#1
    // if(smc_bootloader_start)
    // [1605] if(0==smc_flash::smc_bootloader_start#0) goto smc_flash::@3 -- 0_eq_vbuz1_then_la1 
    lda.z smc_bootloader_start
    beq __b6
    // [1606] phi from smc_flash::@22 to smc_flash::@2 [phi:smc_flash::@22->smc_flash::@2]
    // smc_flash::@2
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1607] call snprintf_init
    // [1151] phi from smc_flash::@2 to snprintf_init [phi:smc_flash::@2->snprintf_init]
    // [1151] phi snprintf_init::s#26 = info_text [phi:smc_flash::@2->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1608] phi from smc_flash::@2 to smc_flash::@26 [phi:smc_flash::@2->smc_flash::@26]
    // smc_flash::@26
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1609] call printf_str
    // [1156] phi from smc_flash::@26 to printf_str [phi:smc_flash::@26->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:smc_flash::@26->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = smc_flash::s [phi:smc_flash::@26->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@27
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1610] printf_uchar::uvalue#4 = smc_flash::smc_bootloader_start#0 -- vbuz1=vbuz2 
    lda.z smc_bootloader_start
    sta.z printf_uchar.uvalue
    // [1611] call printf_uchar
    // [1236] phi from smc_flash::@27 to printf_uchar [phi:smc_flash::@27->printf_uchar]
    // [1236] phi printf_uchar::format_zero_padding#14 = 0 [phi:smc_flash::@27->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1236] phi printf_uchar::format_min_length#14 = 0 [phi:smc_flash::@27->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1236] phi printf_uchar::putc#14 = &snputc [phi:smc_flash::@27->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1236] phi printf_uchar::format_radix#14 = HEXADECIMAL [phi:smc_flash::@27->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [1236] phi printf_uchar::uvalue#14 = printf_uchar::uvalue#4 [phi:smc_flash::@27->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // smc_flash::@28
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1612] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1613] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1615] call display_action_text
    // [1247] phi from smc_flash::@28 to display_action_text [phi:smc_flash::@28->display_action_text]
    // [1247] phi display_action_text::info_text#19 = info_text [phi:smc_flash::@28->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_flash::@29
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [1616] smc_flash::cx16_k_i2c_write_byte2_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte2_device
    // [1617] smc_flash::cx16_k_i2c_write_byte2_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte2_offset
    // [1618] smc_flash::cx16_k_i2c_write_byte2_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte2_value
    // smc_flash::cx16_k_i2c_write_byte2
    // unsigned char result
    // [1619] smc_flash::cx16_k_i2c_write_byte2_result = 0 -- vbum1=vbuc1 
    sta cx16_k_i2c_write_byte2_result
    // asm
    // asm { ldxdevice ldyoffset ldavalue stzresult jsrCX16_I2C_WRITE_BYTE rolresult  }
    ldx cx16_k_i2c_write_byte2_device
    ldy cx16_k_i2c_write_byte2_offset
    lda cx16_k_i2c_write_byte2_value
    stz cx16_k_i2c_write_byte2_result
    jsr CX16_I2C_WRITE_BYTE
    rol cx16_k_i2c_write_byte2_result
    // [1621] phi from smc_flash::@47 smc_flash::cx16_k_i2c_write_byte2 to smc_flash::@return [phi:smc_flash::@47/smc_flash::cx16_k_i2c_write_byte2->smc_flash::@return]
  __b2:
    // [1621] phi smc_flash::return#1 = 0 [phi:smc_flash::@47/smc_flash::cx16_k_i2c_write_byte2->smc_flash::@return#0] -- vwum1=vbuc1 
    lda #<0
    sta return
    sta return+1
    // smc_flash::@return
    // }
    // [1622] return 
    rts
    // [1623] phi from smc_flash::@22 to smc_flash::@3 [phi:smc_flash::@22->smc_flash::@3]
  __b6:
    // [1623] phi smc_flash::smc_bootloader_activation_countdown#10 = $80 [phi:smc_flash::@22->smc_flash::@3#0] -- vbuz1=vbuc1 
    lda #$80
    sta.z smc_bootloader_activation_countdown
    // smc_flash::@3
  __b3:
    // while(smc_bootloader_activation_countdown)
    // [1624] if(0!=smc_flash::smc_bootloader_activation_countdown#10) goto smc_flash::@4 -- 0_neq_vbuz1_then_la1 
    lda.z smc_bootloader_activation_countdown
    beq !__b4+
    jmp __b4
  !__b4:
    // [1625] phi from smc_flash::@3 smc_flash::@30 to smc_flash::@7 [phi:smc_flash::@3/smc_flash::@30->smc_flash::@7]
  __b9:
    // [1625] phi smc_flash::smc_bootloader_activation_countdown#12 = $a [phi:smc_flash::@3/smc_flash::@30->smc_flash::@7#0] -- vbuz1=vbuc1 
    lda #$a
    sta.z smc_bootloader_activation_countdown_1
    // smc_flash::@7
  __b7:
    // while(smc_bootloader_activation_countdown)
    // [1626] if(0!=smc_flash::smc_bootloader_activation_countdown#12) goto smc_flash::@8 -- 0_neq_vbuz1_then_la1 
    lda.z smc_bootloader_activation_countdown_1
    beq !__b8+
    jmp __b8
  !__b8:
    // smc_flash::@9
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1627] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1628] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [1629] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [1630] cx16_k_i2c_read_byte::return#12 = cx16_k_i2c_read_byte::return#1
    // smc_flash::@42
    // smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1631] smc_flash::smc_bootloader_not_activated#1 = cx16_k_i2c_read_byte::return#12
    // if(smc_bootloader_not_activated)
    // [1632] if(0==smc_flash::smc_bootloader_not_activated#1) goto smc_flash::@1 -- 0_eq_vwuz1_then_la1 
    lda.z smc_bootloader_not_activated
    ora.z smc_bootloader_not_activated+1
    beq __b1
    // [1633] phi from smc_flash::@42 to smc_flash::@10 [phi:smc_flash::@42->smc_flash::@10]
    // smc_flash::@10
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1634] call snprintf_init
    // [1151] phi from smc_flash::@10 to snprintf_init [phi:smc_flash::@10->snprintf_init]
    // [1151] phi snprintf_init::s#26 = info_text [phi:smc_flash::@10->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1635] phi from smc_flash::@10 to smc_flash::@45 [phi:smc_flash::@10->smc_flash::@45]
    // smc_flash::@45
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1636] call printf_str
    // [1156] phi from smc_flash::@45 to printf_str [phi:smc_flash::@45->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:smc_flash::@45->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = smc_flash::s5 [phi:smc_flash::@45->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@46
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1637] printf_uint::uvalue#5 = smc_flash::smc_bootloader_not_activated#1
    // [1638] call printf_uint
    // [1810] phi from smc_flash::@46 to printf_uint [phi:smc_flash::@46->printf_uint]
    // [1810] phi printf_uint::format_zero_padding#14 = 0 [phi:smc_flash::@46->printf_uint#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uint.format_zero_padding
    // [1810] phi printf_uint::format_min_length#14 = 0 [phi:smc_flash::@46->printf_uint#1] -- vbuz1=vbuc1 
    sta.z printf_uint.format_min_length
    // [1810] phi printf_uint::putc#14 = &snputc [phi:smc_flash::@46->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [1810] phi printf_uint::format_radix#14 = HEXADECIMAL [phi:smc_flash::@46->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [1810] phi printf_uint::uvalue#14 = printf_uint::uvalue#5 [phi:smc_flash::@46->printf_uint#4] -- register_copy 
    jsr printf_uint
    // smc_flash::@47
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1639] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1640] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1642] call display_action_text
    // [1247] phi from smc_flash::@47 to display_action_text [phi:smc_flash::@47->display_action_text]
    // [1247] phi display_action_text::info_text#19 = info_text [phi:smc_flash::@47->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    jmp __b2
    // [1643] phi from smc_flash::@42 to smc_flash::@1 [phi:smc_flash::@42->smc_flash::@1]
    // smc_flash::@1
  __b1:
    // display_action_progress("Updating SMC firmware ... (+) Updated")
    // [1644] call display_action_progress
    // [850] phi from smc_flash::@1 to display_action_progress [phi:smc_flash::@1->display_action_progress]
    // [850] phi display_action_progress::info_text#18 = smc_flash::info_text1 [phi:smc_flash::@1->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_action_progress.info_text
    lda #>info_text1
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1645] phi from smc_flash::@1 to smc_flash::@43 [phi:smc_flash::@1->smc_flash::@43]
    // smc_flash::@43
    // textcolor(WHITE)
    // [1646] call textcolor
    // [738] phi from smc_flash::@43 to textcolor [phi:smc_flash::@43->textcolor]
    // [738] phi textcolor::color#18 = WHITE [phi:smc_flash::@43->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [1647] phi from smc_flash::@43 to smc_flash::@44 [phi:smc_flash::@43->smc_flash::@44]
    // smc_flash::@44
    // gotoxy(x, y)
    // [1648] call gotoxy
    // [756] phi from smc_flash::@44 to gotoxy [phi:smc_flash::@44->gotoxy]
    // [756] phi gotoxy::y#30 = PROGRESS_Y [phi:smc_flash::@44->gotoxy#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z gotoxy.y
    // [756] phi gotoxy::x#30 = PROGRESS_X [phi:smc_flash::@44->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [1649] phi from smc_flash::@44 to smc_flash::@11 [phi:smc_flash::@44->smc_flash::@11]
    // [1649] phi smc_flash::y#31 = PROGRESS_Y [phi:smc_flash::@44->smc_flash::@11#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // [1649] phi smc_flash::smc_attempts_total#21 = 0 [phi:smc_flash::@44->smc_flash::@11#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z smc_attempts_total
    sta.z smc_attempts_total+1
    // [1649] phi smc_flash::smc_row_bytes#14 = 0 [phi:smc_flash::@44->smc_flash::@11#2] -- vwuz1=vwuc1 
    sta.z smc_row_bytes
    sta.z smc_row_bytes+1
    // [1649] phi smc_flash::smc_ram_ptr#13 = (char *)$7800 [phi:smc_flash::@44->smc_flash::@11#3] -- pbuz1=pbuc1 
    lda #<$7800
    sta.z smc_ram_ptr
    lda #>$7800
    sta.z smc_ram_ptr+1
    // [1649] phi smc_flash::smc_bytes_flashed#16 = 0 [phi:smc_flash::@44->smc_flash::@11#4] -- vwum1=vwuc1 
    lda #<0
    sta smc_bytes_flashed
    sta smc_bytes_flashed+1
    // [1649] phi from smc_flash::@13 to smc_flash::@11 [phi:smc_flash::@13->smc_flash::@11]
    // [1649] phi smc_flash::y#31 = smc_flash::y#20 [phi:smc_flash::@13->smc_flash::@11#0] -- register_copy 
    // [1649] phi smc_flash::smc_attempts_total#21 = smc_flash::smc_attempts_total#17 [phi:smc_flash::@13->smc_flash::@11#1] -- register_copy 
    // [1649] phi smc_flash::smc_row_bytes#14 = smc_flash::smc_row_bytes#10 [phi:smc_flash::@13->smc_flash::@11#2] -- register_copy 
    // [1649] phi smc_flash::smc_ram_ptr#13 = smc_flash::smc_ram_ptr#10 [phi:smc_flash::@13->smc_flash::@11#3] -- register_copy 
    // [1649] phi smc_flash::smc_bytes_flashed#16 = smc_flash::smc_bytes_flashed#11 [phi:smc_flash::@13->smc_flash::@11#4] -- register_copy 
    // smc_flash::@11
  __b11:
    // while(smc_bytes_flashed < smc_bytes_total)
    // [1650] if(smc_flash::smc_bytes_flashed#16<smc_flash::smc_bytes_total#0) goto smc_flash::@12 -- vwum1_lt_vwuz2_then_la1 
    lda smc_bytes_flashed+1
    cmp.z smc_bytes_total+1
    bcc __b10
    bne !+
    lda smc_bytes_flashed
    cmp.z smc_bytes_total
    bcc __b10
  !:
    // [1621] phi from smc_flash::@11 to smc_flash::@return [phi:smc_flash::@11->smc_flash::@return]
    // [1621] phi smc_flash::return#1 = smc_flash::smc_bytes_flashed#16 [phi:smc_flash::@11->smc_flash::@return#0] -- register_copy 
    rts
    // [1651] phi from smc_flash::@11 to smc_flash::@12 [phi:smc_flash::@11->smc_flash::@12]
  __b10:
    // [1651] phi smc_flash::y#20 = smc_flash::y#31 [phi:smc_flash::@11->smc_flash::@12#0] -- register_copy 
    // [1651] phi smc_flash::smc_attempts_total#17 = smc_flash::smc_attempts_total#21 [phi:smc_flash::@11->smc_flash::@12#1] -- register_copy 
    // [1651] phi smc_flash::smc_row_bytes#10 = smc_flash::smc_row_bytes#14 [phi:smc_flash::@11->smc_flash::@12#2] -- register_copy 
    // [1651] phi smc_flash::smc_ram_ptr#10 = smc_flash::smc_ram_ptr#13 [phi:smc_flash::@11->smc_flash::@12#3] -- register_copy 
    // [1651] phi smc_flash::smc_bytes_flashed#11 = smc_flash::smc_bytes_flashed#16 [phi:smc_flash::@11->smc_flash::@12#4] -- register_copy 
    // [1651] phi smc_flash::smc_attempts_flashed#19 = 0 [phi:smc_flash::@11->smc_flash::@12#5] -- vbuz1=vbuc1 
    lda #0
    sta.z smc_attempts_flashed
    // [1651] phi smc_flash::smc_package_committed#2 = 0 [phi:smc_flash::@11->smc_flash::@12#6] -- vbum1=vbuc1 
    sta smc_package_committed
    // smc_flash::@12
  __b12:
    // while(!smc_package_committed && smc_attempts_flashed < 10)
    // [1652] if(0!=smc_flash::smc_package_committed#2) goto smc_flash::@13 -- 0_neq_vbum1_then_la1 
    lda smc_package_committed
    bne __b13
    // smc_flash::@60
    // [1653] if(smc_flash::smc_attempts_flashed#19<$a) goto smc_flash::@14 -- vbuz1_lt_vbuc1_then_la1 
    lda.z smc_attempts_flashed
    cmp #$a
    bcc __b16
    // smc_flash::@13
  __b13:
    // if(smc_attempts_flashed >= 10)
    // [1654] if(smc_flash::smc_attempts_flashed#19<$a) goto smc_flash::@11 -- vbuz1_lt_vbuc1_then_la1 
    lda.z smc_attempts_flashed
    cmp #$a
    bcc __b11
    // [1655] phi from smc_flash::@13 to smc_flash::@21 [phi:smc_flash::@13->smc_flash::@21]
    // smc_flash::@21
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1656] call snprintf_init
    // [1151] phi from smc_flash::@21 to snprintf_init [phi:smc_flash::@21->snprintf_init]
    // [1151] phi snprintf_init::s#26 = info_text [phi:smc_flash::@21->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1657] phi from smc_flash::@21 to smc_flash::@57 [phi:smc_flash::@21->smc_flash::@57]
    // smc_flash::@57
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1658] call printf_str
    // [1156] phi from smc_flash::@57 to printf_str [phi:smc_flash::@57->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:smc_flash::@57->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = smc_flash::s10 [phi:smc_flash::@57->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@58
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1659] printf_uint::uvalue#9 = smc_flash::smc_bytes_flashed#11 -- vwuz1=vwum2 
    lda smc_bytes_flashed
    sta.z printf_uint.uvalue
    lda smc_bytes_flashed+1
    sta.z printf_uint.uvalue+1
    // [1660] call printf_uint
    // [1810] phi from smc_flash::@58 to printf_uint [phi:smc_flash::@58->printf_uint]
    // [1810] phi printf_uint::format_zero_padding#14 = 1 [phi:smc_flash::@58->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [1810] phi printf_uint::format_min_length#14 = 4 [phi:smc_flash::@58->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [1810] phi printf_uint::putc#14 = &snputc [phi:smc_flash::@58->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [1810] phi printf_uint::format_radix#14 = HEXADECIMAL [phi:smc_flash::@58->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [1810] phi printf_uint::uvalue#14 = printf_uint::uvalue#9 [phi:smc_flash::@58->printf_uint#4] -- register_copy 
    jsr printf_uint
    // smc_flash::@59
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1661] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1662] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1664] call display_action_text
    // [1247] phi from smc_flash::@59 to display_action_text [phi:smc_flash::@59->display_action_text]
    // [1247] phi display_action_text::info_text#19 = info_text [phi:smc_flash::@59->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1621] phi from smc_flash::@59 to smc_flash::@return [phi:smc_flash::@59->smc_flash::@return]
    // [1621] phi smc_flash::return#1 = $ffff [phi:smc_flash::@59->smc_flash::@return#0] -- vwum1=vwuc1 
    lda #<$ffff
    sta return
    lda #>$ffff
    sta return+1
    rts
    // [1665] phi from smc_flash::@60 to smc_flash::@14 [phi:smc_flash::@60->smc_flash::@14]
  __b16:
    // [1665] phi smc_flash::smc_bytes_checksum#2 = 0 [phi:smc_flash::@60->smc_flash::@14#0] -- vbuz1=vbuc1 
    lda #0
    sta.z smc_bytes_checksum
    // [1665] phi smc_flash::smc_ram_ptr#12 = smc_flash::smc_ram_ptr#10 [phi:smc_flash::@60->smc_flash::@14#1] -- register_copy 
    // [1665] phi smc_flash::smc_package_flashed#2 = 0 [phi:smc_flash::@60->smc_flash::@14#2] -- vwum1=vwuc1 
    sta smc_package_flashed
    sta smc_package_flashed+1
    // smc_flash::@14
  __b14:
    // while(smc_package_flashed < SMC_PROGRESS_CELL)
    // [1666] if(smc_flash::smc_package_flashed#2<SMC_PROGRESS_CELL) goto smc_flash::@15 -- vwum1_lt_vbuc1_then_la1 
    lda smc_package_flashed+1
    bne !+
    lda smc_package_flashed
    cmp #SMC_PROGRESS_CELL
    bcs !__b15+
    jmp __b15
  !__b15:
  !:
    // smc_flash::@16
    // smc_bytes_checksum ^ 0xFF
    // [1667] smc_flash::$26 = smc_flash::smc_bytes_checksum#2 ^ $ff -- vbuz1=vbuz1_bxor_vbuc1 
    lda #$ff
    eor.z smc_flash__26
    sta.z smc_flash__26
    // (smc_bytes_checksum ^ 0xFF)+1
    // [1668] smc_flash::$27 = smc_flash::$26 + 1 -- vbuz1=vbuz1_plus_1 
    inc.z smc_flash__27
    // unsigned char smc_checksum_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, (smc_bytes_checksum ^ 0xFF)+1)
    // [1669] smc_flash::cx16_k_i2c_write_byte4_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte4_device
    // [1670] smc_flash::cx16_k_i2c_write_byte4_offset = $80 -- vbum1=vbuc1 
    lda #$80
    sta cx16_k_i2c_write_byte4_offset
    // [1671] smc_flash::cx16_k_i2c_write_byte4_value = smc_flash::$27 -- vbum1=vbuz2 
    lda.z smc_flash__27
    sta cx16_k_i2c_write_byte4_value
    // smc_flash::cx16_k_i2c_write_byte4
    // unsigned char result
    // [1672] smc_flash::cx16_k_i2c_write_byte4_result = 0 -- vbum1=vbuc1 
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
    // [1674] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1675] cx16_k_i2c_read_byte::offset = $81 -- vbum1=vbuc1 
    lda #$81
    sta cx16_k_i2c_read_byte.offset
    // [1676] call cx16_k_i2c_read_byte
    // Now send the commit command.
    jsr cx16_k_i2c_read_byte
    // [1677] cx16_k_i2c_read_byte::return#13 = cx16_k_i2c_read_byte::return#1
    // smc_flash::@48
    // [1678] smc_flash::smc_commit_result#0 = cx16_k_i2c_read_byte::return#13
    // if(smc_commit_result == 1)
    // [1679] if(smc_flash::smc_commit_result#0==1) goto smc_flash::@18 -- vwuz1_eq_vbuc1_then_la1 
    lda.z smc_commit_result+1
    bne !+
    lda.z smc_commit_result
    cmp #1
    beq __b18
  !:
    // smc_flash::@17
    // smc_ram_ptr -= SMC_PROGRESS_CELL
    // [1680] smc_flash::smc_ram_ptr#2 = smc_flash::smc_ram_ptr#12 - SMC_PROGRESS_CELL -- pbuz1=pbuz1_minus_vbuc1 
    sec
    lda.z smc_ram_ptr
    sbc #SMC_PROGRESS_CELL
    sta.z smc_ram_ptr
    lda.z smc_ram_ptr+1
    sbc #0
    sta.z smc_ram_ptr+1
    // smc_attempts_flashed++;
    // [1681] smc_flash::smc_attempts_flashed#1 = ++ smc_flash::smc_attempts_flashed#19 -- vbuz1=_inc_vbuz1 
    inc.z smc_attempts_flashed
    // [1651] phi from smc_flash::@17 to smc_flash::@12 [phi:smc_flash::@17->smc_flash::@12]
    // [1651] phi smc_flash::y#20 = smc_flash::y#20 [phi:smc_flash::@17->smc_flash::@12#0] -- register_copy 
    // [1651] phi smc_flash::smc_attempts_total#17 = smc_flash::smc_attempts_total#17 [phi:smc_flash::@17->smc_flash::@12#1] -- register_copy 
    // [1651] phi smc_flash::smc_row_bytes#10 = smc_flash::smc_row_bytes#10 [phi:smc_flash::@17->smc_flash::@12#2] -- register_copy 
    // [1651] phi smc_flash::smc_ram_ptr#10 = smc_flash::smc_ram_ptr#2 [phi:smc_flash::@17->smc_flash::@12#3] -- register_copy 
    // [1651] phi smc_flash::smc_bytes_flashed#11 = smc_flash::smc_bytes_flashed#11 [phi:smc_flash::@17->smc_flash::@12#4] -- register_copy 
    // [1651] phi smc_flash::smc_attempts_flashed#19 = smc_flash::smc_attempts_flashed#1 [phi:smc_flash::@17->smc_flash::@12#5] -- register_copy 
    // [1651] phi smc_flash::smc_package_committed#2 = smc_flash::smc_package_committed#2 [phi:smc_flash::@17->smc_flash::@12#6] -- register_copy 
    jmp __b12
    // smc_flash::@18
  __b18:
    // if (smc_row_bytes == SMC_PROGRESS_ROW)
    // [1682] if(smc_flash::smc_row_bytes#10!=SMC_PROGRESS_ROW) goto smc_flash::@19 -- vwuz1_neq_vwuc1_then_la1 
    lda.z smc_row_bytes+1
    cmp #>SMC_PROGRESS_ROW
    bne __b19
    lda.z smc_row_bytes
    cmp #<SMC_PROGRESS_ROW
    bne __b19
    // smc_flash::@20
    // gotoxy(x, ++y);
    // [1683] smc_flash::y#1 = ++ smc_flash::y#20 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [1684] gotoxy::y#22 = smc_flash::y#1 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1685] call gotoxy
    // [756] phi from smc_flash::@20 to gotoxy [phi:smc_flash::@20->gotoxy]
    // [756] phi gotoxy::y#30 = gotoxy::y#22 [phi:smc_flash::@20->gotoxy#0] -- register_copy 
    // [756] phi gotoxy::x#30 = PROGRESS_X [phi:smc_flash::@20->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [1686] phi from smc_flash::@20 to smc_flash::@19 [phi:smc_flash::@20->smc_flash::@19]
    // [1686] phi smc_flash::y#33 = smc_flash::y#1 [phi:smc_flash::@20->smc_flash::@19#0] -- register_copy 
    // [1686] phi smc_flash::smc_row_bytes#4 = 0 [phi:smc_flash::@20->smc_flash::@19#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z smc_row_bytes
    sta.z smc_row_bytes+1
    // [1686] phi from smc_flash::@18 to smc_flash::@19 [phi:smc_flash::@18->smc_flash::@19]
    // [1686] phi smc_flash::y#33 = smc_flash::y#20 [phi:smc_flash::@18->smc_flash::@19#0] -- register_copy 
    // [1686] phi smc_flash::smc_row_bytes#4 = smc_flash::smc_row_bytes#10 [phi:smc_flash::@18->smc_flash::@19#1] -- register_copy 
    // smc_flash::@19
  __b19:
    // cputc('+')
    // [1687] stackpush(char) = '+' -- _stackpushbyte_=vbuc1 
    lda #'+'
    pha
    // [1688] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_bytes_flashed += SMC_PROGRESS_CELL
    // [1690] smc_flash::smc_bytes_flashed#1 = smc_flash::smc_bytes_flashed#11 + SMC_PROGRESS_CELL -- vwum1=vwum1_plus_vbuc1 
    lda #SMC_PROGRESS_CELL
    clc
    adc smc_bytes_flashed
    sta smc_bytes_flashed
    bcc !+
    inc smc_bytes_flashed+1
  !:
    // smc_row_bytes += SMC_PROGRESS_CELL
    // [1691] smc_flash::smc_row_bytes#1 = smc_flash::smc_row_bytes#4 + SMC_PROGRESS_CELL -- vwuz1=vwuz1_plus_vbuc1 
    lda #SMC_PROGRESS_CELL
    clc
    adc.z smc_row_bytes
    sta.z smc_row_bytes
    bcc !+
    inc.z smc_row_bytes+1
  !:
    // smc_attempts_total += smc_attempts_flashed
    // [1692] smc_flash::smc_attempts_total#1 = smc_flash::smc_attempts_total#17 + smc_flash::smc_attempts_flashed#19 -- vwuz1=vwuz1_plus_vbuz2 
    lda.z smc_attempts_flashed
    clc
    adc.z smc_attempts_total
    sta.z smc_attempts_total
    bcc !+
    inc.z smc_attempts_total+1
  !:
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1693] call snprintf_init
    // [1151] phi from smc_flash::@19 to snprintf_init [phi:smc_flash::@19->snprintf_init]
    // [1151] phi snprintf_init::s#26 = info_text [phi:smc_flash::@19->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1694] phi from smc_flash::@19 to smc_flash::@49 [phi:smc_flash::@19->smc_flash::@49]
    // smc_flash::@49
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1695] call printf_str
    // [1156] phi from smc_flash::@49 to printf_str [phi:smc_flash::@49->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:smc_flash::@49->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = smc_flash::s6 [phi:smc_flash::@49->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@50
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1696] printf_uint::uvalue#6 = smc_flash::smc_bytes_flashed#1 -- vwuz1=vwum2 
    lda smc_bytes_flashed
    sta.z printf_uint.uvalue
    lda smc_bytes_flashed+1
    sta.z printf_uint.uvalue+1
    // [1697] call printf_uint
    // [1810] phi from smc_flash::@50 to printf_uint [phi:smc_flash::@50->printf_uint]
    // [1810] phi printf_uint::format_zero_padding#14 = 1 [phi:smc_flash::@50->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [1810] phi printf_uint::format_min_length#14 = 5 [phi:smc_flash::@50->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [1810] phi printf_uint::putc#14 = &snputc [phi:smc_flash::@50->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [1810] phi printf_uint::format_radix#14 = DECIMAL [phi:smc_flash::@50->printf_uint#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [1810] phi printf_uint::uvalue#14 = printf_uint::uvalue#6 [phi:smc_flash::@50->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1698] phi from smc_flash::@50 to smc_flash::@51 [phi:smc_flash::@50->smc_flash::@51]
    // smc_flash::@51
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1699] call printf_str
    // [1156] phi from smc_flash::@51 to printf_str [phi:smc_flash::@51->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:smc_flash::@51->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = smc_flash::s7 [phi:smc_flash::@51->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@52
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1700] printf_uint::uvalue#7 = smc_flash::smc_bytes_total#0 -- vwuz1=vwuz2 
    lda.z smc_bytes_total
    sta.z printf_uint.uvalue
    lda.z smc_bytes_total+1
    sta.z printf_uint.uvalue+1
    // [1701] call printf_uint
    // [1810] phi from smc_flash::@52 to printf_uint [phi:smc_flash::@52->printf_uint]
    // [1810] phi printf_uint::format_zero_padding#14 = 1 [phi:smc_flash::@52->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [1810] phi printf_uint::format_min_length#14 = 5 [phi:smc_flash::@52->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [1810] phi printf_uint::putc#14 = &snputc [phi:smc_flash::@52->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [1810] phi printf_uint::format_radix#14 = DECIMAL [phi:smc_flash::@52->printf_uint#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [1810] phi printf_uint::uvalue#14 = printf_uint::uvalue#7 [phi:smc_flash::@52->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1702] phi from smc_flash::@52 to smc_flash::@53 [phi:smc_flash::@52->smc_flash::@53]
    // smc_flash::@53
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1703] call printf_str
    // [1156] phi from smc_flash::@53 to printf_str [phi:smc_flash::@53->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:smc_flash::@53->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = smc_flash::s8 [phi:smc_flash::@53->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@54
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1704] printf_uint::uvalue#8 = smc_flash::smc_attempts_total#1 -- vwuz1=vwuz2 
    lda.z smc_attempts_total
    sta.z printf_uint.uvalue
    lda.z smc_attempts_total+1
    sta.z printf_uint.uvalue+1
    // [1705] call printf_uint
    // [1810] phi from smc_flash::@54 to printf_uint [phi:smc_flash::@54->printf_uint]
    // [1810] phi printf_uint::format_zero_padding#14 = 1 [phi:smc_flash::@54->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [1810] phi printf_uint::format_min_length#14 = 2 [phi:smc_flash::@54->printf_uint#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uint.format_min_length
    // [1810] phi printf_uint::putc#14 = &snputc [phi:smc_flash::@54->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [1810] phi printf_uint::format_radix#14 = DECIMAL [phi:smc_flash::@54->printf_uint#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [1810] phi printf_uint::uvalue#14 = printf_uint::uvalue#8 [phi:smc_flash::@54->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1706] phi from smc_flash::@54 to smc_flash::@55 [phi:smc_flash::@54->smc_flash::@55]
    // smc_flash::@55
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1707] call printf_str
    // [1156] phi from smc_flash::@55 to printf_str [phi:smc_flash::@55->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:smc_flash::@55->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = smc_flash::s9 [phi:smc_flash::@55->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@56
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1708] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1709] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1711] call display_action_text
    // [1247] phi from smc_flash::@56 to display_action_text [phi:smc_flash::@56->display_action_text]
    // [1247] phi display_action_text::info_text#19 = info_text [phi:smc_flash::@56->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1651] phi from smc_flash::@56 to smc_flash::@12 [phi:smc_flash::@56->smc_flash::@12]
    // [1651] phi smc_flash::y#20 = smc_flash::y#33 [phi:smc_flash::@56->smc_flash::@12#0] -- register_copy 
    // [1651] phi smc_flash::smc_attempts_total#17 = smc_flash::smc_attempts_total#1 [phi:smc_flash::@56->smc_flash::@12#1] -- register_copy 
    // [1651] phi smc_flash::smc_row_bytes#10 = smc_flash::smc_row_bytes#1 [phi:smc_flash::@56->smc_flash::@12#2] -- register_copy 
    // [1651] phi smc_flash::smc_ram_ptr#10 = smc_flash::smc_ram_ptr#12 [phi:smc_flash::@56->smc_flash::@12#3] -- register_copy 
    // [1651] phi smc_flash::smc_bytes_flashed#11 = smc_flash::smc_bytes_flashed#1 [phi:smc_flash::@56->smc_flash::@12#4] -- register_copy 
    // [1651] phi smc_flash::smc_attempts_flashed#19 = smc_flash::smc_attempts_flashed#19 [phi:smc_flash::@56->smc_flash::@12#5] -- register_copy 
    // [1651] phi smc_flash::smc_package_committed#2 = 1 [phi:smc_flash::@56->smc_flash::@12#6] -- vbum1=vbuc1 
    lda #1
    sta smc_package_committed
    jmp __b12
    // smc_flash::@15
  __b15:
    // unsigned char smc_byte_upload = *smc_ram_ptr
    // [1712] smc_flash::smc_byte_upload#0 = *smc_flash::smc_ram_ptr#12 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (smc_ram_ptr),y
    sta.z smc_byte_upload
    // smc_ram_ptr++;
    // [1713] smc_flash::smc_ram_ptr#1 = ++ smc_flash::smc_ram_ptr#12 -- pbuz1=_inc_pbuz1 
    inc.z smc_ram_ptr
    bne !+
    inc.z smc_ram_ptr+1
  !:
    // smc_bytes_checksum += smc_byte_upload
    // [1714] smc_flash::smc_bytes_checksum#1 = smc_flash::smc_bytes_checksum#2 + smc_flash::smc_byte_upload#0 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z smc_bytes_checksum
    clc
    adc.z smc_byte_upload
    sta.z smc_bytes_checksum
    // unsigned char smc_upload_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, smc_byte_upload)
    // [1715] smc_flash::cx16_k_i2c_write_byte3_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte3_device
    // [1716] smc_flash::cx16_k_i2c_write_byte3_offset = $80 -- vbum1=vbuc1 
    lda #$80
    sta cx16_k_i2c_write_byte3_offset
    // [1717] smc_flash::cx16_k_i2c_write_byte3_value = smc_flash::smc_byte_upload#0 -- vbum1=vbuz2 
    lda.z smc_byte_upload
    sta cx16_k_i2c_write_byte3_value
    // smc_flash::cx16_k_i2c_write_byte3
    // unsigned char result
    // [1718] smc_flash::cx16_k_i2c_write_byte3_result = 0 -- vbum1=vbuc1 
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
    // [1720] smc_flash::smc_package_flashed#1 = ++ smc_flash::smc_package_flashed#2 -- vwum1=_inc_vwum1 
    inc smc_package_flashed
    bne !+
    inc smc_package_flashed+1
  !:
    // [1665] phi from smc_flash::@23 to smc_flash::@14 [phi:smc_flash::@23->smc_flash::@14]
    // [1665] phi smc_flash::smc_bytes_checksum#2 = smc_flash::smc_bytes_checksum#1 [phi:smc_flash::@23->smc_flash::@14#0] -- register_copy 
    // [1665] phi smc_flash::smc_ram_ptr#12 = smc_flash::smc_ram_ptr#1 [phi:smc_flash::@23->smc_flash::@14#1] -- register_copy 
    // [1665] phi smc_flash::smc_package_flashed#2 = smc_flash::smc_package_flashed#1 [phi:smc_flash::@23->smc_flash::@14#2] -- register_copy 
    jmp __b14
    // [1721] phi from smc_flash::@7 to smc_flash::@8 [phi:smc_flash::@7->smc_flash::@8]
    // smc_flash::@8
  __b8:
    // wait_moment()
    // [1722] call wait_moment
    // [1231] phi from smc_flash::@8 to wait_moment [phi:smc_flash::@8->wait_moment]
    jsr wait_moment
    // [1723] phi from smc_flash::@8 to smc_flash::@36 [phi:smc_flash::@8->smc_flash::@36]
    // smc_flash::@36
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1724] call snprintf_init
    // [1151] phi from smc_flash::@36 to snprintf_init [phi:smc_flash::@36->snprintf_init]
    // [1151] phi snprintf_init::s#26 = info_text [phi:smc_flash::@36->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1725] phi from smc_flash::@36 to smc_flash::@37 [phi:smc_flash::@36->smc_flash::@37]
    // smc_flash::@37
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1726] call printf_str
    // [1156] phi from smc_flash::@37 to printf_str [phi:smc_flash::@37->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:smc_flash::@37->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = smc_flash::s3 [phi:smc_flash::@37->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@38
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1727] printf_uchar::uvalue#6 = smc_flash::smc_bootloader_activation_countdown#12 -- vbuz1=vbuz2 
    lda.z smc_bootloader_activation_countdown_1
    sta.z printf_uchar.uvalue
    // [1728] call printf_uchar
    // [1236] phi from smc_flash::@38 to printf_uchar [phi:smc_flash::@38->printf_uchar]
    // [1236] phi printf_uchar::format_zero_padding#14 = 0 [phi:smc_flash::@38->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1236] phi printf_uchar::format_min_length#14 = 0 [phi:smc_flash::@38->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1236] phi printf_uchar::putc#14 = &snputc [phi:smc_flash::@38->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1236] phi printf_uchar::format_radix#14 = DECIMAL [phi:smc_flash::@38->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1236] phi printf_uchar::uvalue#14 = printf_uchar::uvalue#6 [phi:smc_flash::@38->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1729] phi from smc_flash::@38 to smc_flash::@39 [phi:smc_flash::@38->smc_flash::@39]
    // smc_flash::@39
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1730] call printf_str
    // [1156] phi from smc_flash::@39 to printf_str [phi:smc_flash::@39->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:smc_flash::@39->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = s4 [phi:smc_flash::@39->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@40
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1731] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1732] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1734] call display_action_text
    // [1247] phi from smc_flash::@40 to display_action_text [phi:smc_flash::@40->display_action_text]
    // [1247] phi display_action_text::info_text#19 = info_text [phi:smc_flash::@40->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_flash::@41
    // smc_bootloader_activation_countdown--;
    // [1735] smc_flash::smc_bootloader_activation_countdown#3 = -- smc_flash::smc_bootloader_activation_countdown#12 -- vbuz1=_dec_vbuz1 
    dec.z smc_bootloader_activation_countdown_1
    // [1625] phi from smc_flash::@41 to smc_flash::@7 [phi:smc_flash::@41->smc_flash::@7]
    // [1625] phi smc_flash::smc_bootloader_activation_countdown#12 = smc_flash::smc_bootloader_activation_countdown#3 [phi:smc_flash::@41->smc_flash::@7#0] -- register_copy 
    jmp __b7
    // smc_flash::@4
  __b4:
    // unsigned int smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1736] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1737] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [1738] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [1739] cx16_k_i2c_read_byte::return#11 = cx16_k_i2c_read_byte::return#1
    // smc_flash::@30
    // [1740] smc_flash::smc_bootloader_not_activated1#0 = cx16_k_i2c_read_byte::return#11
    // if(smc_bootloader_not_activated)
    // [1741] if(0!=smc_flash::smc_bootloader_not_activated1#0) goto smc_flash::@5 -- 0_neq_vwuz1_then_la1 
    lda.z smc_bootloader_not_activated1
    ora.z smc_bootloader_not_activated1+1
    bne __b5
    jmp __b9
    // [1742] phi from smc_flash::@30 to smc_flash::@5 [phi:smc_flash::@30->smc_flash::@5]
    // smc_flash::@5
  __b5:
    // wait_moment()
    // [1743] call wait_moment
    // [1231] phi from smc_flash::@5 to wait_moment [phi:smc_flash::@5->wait_moment]
    jsr wait_moment
    // [1744] phi from smc_flash::@5 to smc_flash::@31 [phi:smc_flash::@5->smc_flash::@31]
    // smc_flash::@31
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1745] call snprintf_init
    // [1151] phi from smc_flash::@31 to snprintf_init [phi:smc_flash::@31->snprintf_init]
    // [1151] phi snprintf_init::s#26 = info_text [phi:smc_flash::@31->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1746] phi from smc_flash::@31 to smc_flash::@32 [phi:smc_flash::@31->smc_flash::@32]
    // smc_flash::@32
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1747] call printf_str
    // [1156] phi from smc_flash::@32 to printf_str [phi:smc_flash::@32->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:smc_flash::@32->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = smc_flash::s1 [phi:smc_flash::@32->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@33
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1748] printf_uchar::uvalue#5 = smc_flash::smc_bootloader_activation_countdown#10 -- vbuz1=vbuz2 
    lda.z smc_bootloader_activation_countdown
    sta.z printf_uchar.uvalue
    // [1749] call printf_uchar
    // [1236] phi from smc_flash::@33 to printf_uchar [phi:smc_flash::@33->printf_uchar]
    // [1236] phi printf_uchar::format_zero_padding#14 = 1 [phi:smc_flash::@33->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1236] phi printf_uchar::format_min_length#14 = 3 [phi:smc_flash::@33->printf_uchar#1] -- vbuz1=vbuc1 
    lda #3
    sta.z printf_uchar.format_min_length
    // [1236] phi printf_uchar::putc#14 = &snputc [phi:smc_flash::@33->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1236] phi printf_uchar::format_radix#14 = DECIMAL [phi:smc_flash::@33->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1236] phi printf_uchar::uvalue#14 = printf_uchar::uvalue#5 [phi:smc_flash::@33->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1750] phi from smc_flash::@33 to smc_flash::@34 [phi:smc_flash::@33->smc_flash::@34]
    // smc_flash::@34
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1751] call printf_str
    // [1156] phi from smc_flash::@34 to printf_str [phi:smc_flash::@34->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:smc_flash::@34->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = smc_flash::s2 [phi:smc_flash::@34->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@35
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1752] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1753] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1755] call display_action_text
    // [1247] phi from smc_flash::@35 to display_action_text [phi:smc_flash::@35->display_action_text]
    // [1247] phi display_action_text::info_text#19 = info_text [phi:smc_flash::@35->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_flash::@6
    // smc_bootloader_activation_countdown--;
    // [1756] smc_flash::smc_bootloader_activation_countdown#2 = -- smc_flash::smc_bootloader_activation_countdown#10 -- vbuz1=_dec_vbuz1 
    dec.z smc_bootloader_activation_countdown
    // [1623] phi from smc_flash::@6 to smc_flash::@3 [phi:smc_flash::@6->smc_flash::@3]
    // [1623] phi smc_flash::smc_bootloader_activation_countdown#10 = smc_flash::smc_bootloader_activation_countdown#2 [phi:smc_flash::@6->smc_flash::@3#0] -- register_copy 
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
    return: .word 0
    smc_package_flashed: .word 0
    .label smc_bytes_flashed = return
    .label smc_package_committed = main.check_status_cx16_rom3_check_status_rom1_main__0
}
.segment Code
  // strchr
// Searches for the first occurrence of the character c (an unsigned char) in the string pointed to, by the argument str.
// - str: The memory to search
// - c: A character to search for
// Return: A pointer to the matching byte or NULL if the character does not occur in the given memory area.
// __zp($f0) void * strchr(__zp($f0) const void *str, __zp($e9) char c)
strchr: {
    .label ptr = $f0
    .label return = $f0
    .label str = $f0
    .label c = $e9
    // [1758] strchr::ptr#6 = (char *)strchr::str#2
    // [1759] phi from strchr strchr::@3 to strchr::@1 [phi:strchr/strchr::@3->strchr::@1]
    // [1759] phi strchr::ptr#2 = strchr::ptr#6 [phi:strchr/strchr::@3->strchr::@1#0] -- register_copy 
    // strchr::@1
  __b1:
    // while(*ptr)
    // [1760] if(0!=*strchr::ptr#2) goto strchr::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (ptr),y
    cmp #0
    bne __b2
    // [1761] phi from strchr::@1 to strchr::@return [phi:strchr::@1->strchr::@return]
    // [1761] phi strchr::return#2 = (void *) 0 [phi:strchr::@1->strchr::@return#0] -- pvoz1=pvoc1 
    tya
    sta.z return
    sta.z return+1
    // strchr::@return
    // }
    // [1762] return 
    rts
    // strchr::@2
  __b2:
    // if(*ptr==c)
    // [1763] if(*strchr::ptr#2!=strchr::c#4) goto strchr::@3 -- _deref_pbuz1_neq_vbuz2_then_la1 
    ldy #0
    lda (ptr),y
    cmp.z c
    bne __b3
    // strchr::@4
    // [1764] strchr::return#8 = (void *)strchr::ptr#2
    // [1761] phi from strchr::@4 to strchr::@return [phi:strchr::@4->strchr::@return]
    // [1761] phi strchr::return#2 = strchr::return#8 [phi:strchr::@4->strchr::@return#0] -- register_copy 
    rts
    // strchr::@3
  __b3:
    // ptr++;
    // [1765] strchr::ptr#1 = ++ strchr::ptr#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr
    bne !+
    inc.z ptr+1
  !:
    jmp __b1
}
  // rom_get_github_commit_id
/**
 * @brief Copy the github commit_id only if the commit_id contains hexadecimal characters. 
 * 
 * @param commit_id The target commit_id.
 * @param from The source ptr in ROM or RAM.
 */
// void rom_get_github_commit_id(__zp($4f) char *commit_id, __zp($3f) char *from)
rom_get_github_commit_id: {
    .label ch = $54
    .label commit_id = $4f
    .label from = $3f
    // [1767] phi from rom_get_github_commit_id to rom_get_github_commit_id::@2 [phi:rom_get_github_commit_id->rom_get_github_commit_id::@2]
    // [1767] phi rom_get_github_commit_id::commit_id_ok#2 = true [phi:rom_get_github_commit_id->rom_get_github_commit_id::@2#0] -- vbom1=vboc1 
    lda #1
    sta commit_id_ok
    // [1767] phi rom_get_github_commit_id::c#2 = 0 [phi:rom_get_github_commit_id->rom_get_github_commit_id::@2#1] -- vbum1=vbuc1 
    lda #0
    sta c
    // rom_get_github_commit_id::@2
  __b2:
    // for(unsigned char c=0; c<7; c++)
    // [1768] if(rom_get_github_commit_id::c#2<7) goto rom_get_github_commit_id::@3 -- vbum1_lt_vbuc1_then_la1 
    lda c
    cmp #7
    bcc __b3
    // rom_get_github_commit_id::@4
    // if(commit_id_ok)
    // [1769] if(rom_get_github_commit_id::commit_id_ok#2) goto rom_get_github_commit_id::@1 -- vbom1_then_la1 
    lda commit_id_ok
    cmp #0
    bne __b1
    // rom_get_github_commit_id::@6
    // *commit_id = '\0'
    // [1770] *rom_get_github_commit_id::commit_id#6 = '@' -- _deref_pbuz1=vbuc1 
    lda #'@'
    ldy #0
    sta (commit_id),y
    // rom_get_github_commit_id::@return
    // }
    // [1771] return 
    rts
    // rom_get_github_commit_id::@1
  __b1:
    // strncpy(commit_id, from, 7)
    // [1772] strncpy::dst#2 = rom_get_github_commit_id::commit_id#6
    // [1773] strncpy::src#2 = rom_get_github_commit_id::from#6
    // [1774] call strncpy
    // [2478] phi from rom_get_github_commit_id::@1 to strncpy [phi:rom_get_github_commit_id::@1->strncpy]
    // [2478] phi strncpy::dst#8 = strncpy::dst#2 [phi:rom_get_github_commit_id::@1->strncpy#0] -- register_copy 
    // [2478] phi strncpy::src#6 = strncpy::src#2 [phi:rom_get_github_commit_id::@1->strncpy#1] -- register_copy 
    // [2478] phi strncpy::n#3 = 7 [phi:rom_get_github_commit_id::@1->strncpy#2] -- vwuz1=vbuc1 
    lda #<7
    sta.z strncpy.n
    lda #>7
    sta.z strncpy.n+1
    jsr strncpy
    rts
    // rom_get_github_commit_id::@3
  __b3:
    // unsigned char ch = from[c]
    // [1775] rom_get_github_commit_id::ch#0 = rom_get_github_commit_id::from#6[rom_get_github_commit_id::c#2] -- vbuz1=pbuz2_derefidx_vbum3 
    ldy c
    lda (from),y
    sta.z ch
    // if(!(ch >= 48 && ch <= 48+9 || ch >= 65 && ch <= 65+26))
    // [1776] if(rom_get_github_commit_id::ch#0<$30) goto rom_get_github_commit_id::@7 -- vbuz1_lt_vbuc1_then_la1 
    cmp #$30
    bcc __b7
    // rom_get_github_commit_id::@8
    // [1777] if(rom_get_github_commit_id::ch#0<$30+9+1) goto rom_get_github_commit_id::@5 -- vbuz1_lt_vbuc1_then_la1 
    cmp #$30+9+1
    bcc __b5
    // rom_get_github_commit_id::@7
  __b7:
    // [1778] if(rom_get_github_commit_id::ch#0<$41) goto rom_get_github_commit_id::@5 -- vbuz1_lt_vbuc1_then_la1 
    lda.z ch
    cmp #$41
    bcc __b4
    // rom_get_github_commit_id::@9
    // [1779] if(rom_get_github_commit_id::ch#0<$41+$1a+1) goto rom_get_github_commit_id::@10 -- vbuz1_lt_vbuc1_then_la1 
    cmp #$41+$1a+1
    bcc __b5
    // [1781] phi from rom_get_github_commit_id::@7 rom_get_github_commit_id::@9 to rom_get_github_commit_id::@5 [phi:rom_get_github_commit_id::@7/rom_get_github_commit_id::@9->rom_get_github_commit_id::@5]
  __b4:
    // [1781] phi rom_get_github_commit_id::commit_id_ok#4 = false [phi:rom_get_github_commit_id::@7/rom_get_github_commit_id::@9->rom_get_github_commit_id::@5#0] -- vbom1=vboc1 
    lda #0
    sta commit_id_ok
    // [1780] phi from rom_get_github_commit_id::@9 to rom_get_github_commit_id::@10 [phi:rom_get_github_commit_id::@9->rom_get_github_commit_id::@10]
    // rom_get_github_commit_id::@10
    // [1781] phi from rom_get_github_commit_id::@10 rom_get_github_commit_id::@8 to rom_get_github_commit_id::@5 [phi:rom_get_github_commit_id::@10/rom_get_github_commit_id::@8->rom_get_github_commit_id::@5]
    // [1781] phi rom_get_github_commit_id::commit_id_ok#4 = rom_get_github_commit_id::commit_id_ok#2 [phi:rom_get_github_commit_id::@10/rom_get_github_commit_id::@8->rom_get_github_commit_id::@5#0] -- register_copy 
    // rom_get_github_commit_id::@5
  __b5:
    // for(unsigned char c=0; c<7; c++)
    // [1782] rom_get_github_commit_id::c#1 = ++ rom_get_github_commit_id::c#2 -- vbum1=_inc_vbum1 
    inc c
    // [1767] phi from rom_get_github_commit_id::@5 to rom_get_github_commit_id::@2 [phi:rom_get_github_commit_id::@5->rom_get_github_commit_id::@2]
    // [1767] phi rom_get_github_commit_id::commit_id_ok#2 = rom_get_github_commit_id::commit_id_ok#4 [phi:rom_get_github_commit_id::@5->rom_get_github_commit_id::@2#0] -- register_copy 
    // [1767] phi rom_get_github_commit_id::c#2 = rom_get_github_commit_id::c#1 [phi:rom_get_github_commit_id::@5->rom_get_github_commit_id::@2#1] -- register_copy 
    jmp __b2
  .segment Data
    .label c = util_wait_key.return
    .label commit_id_ok = main.check_status_smc5_main__0
}
.segment Code
  // rom_get_version_text
// void rom_get_version_text(__zp($bc) char *release_info, __mem() char prefix, __mem() char release, __zp($dd) char *github)
rom_get_version_text: {
    .label release_info = $bc
    .label github = $dd
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [1784] snprintf_init::s#8 = rom_get_version_text::release_info#2
    // [1785] call snprintf_init
    // [1151] phi from rom_get_version_text to snprintf_init [phi:rom_get_version_text->snprintf_init]
    // [1151] phi snprintf_init::s#26 = snprintf_init::s#8 [phi:rom_get_version_text->snprintf_init#0] -- register_copy 
    jsr snprintf_init
    // rom_get_version_text::@1
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [1786] stackpush(char) = rom_get_version_text::prefix#2 -- _stackpushbyte_=vbum1 
    lda prefix
    pha
    // [1787] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [1789] printf_uchar::uvalue#7 = rom_get_version_text::release#2 -- vbuz1=vbum2 
    lda release
    sta.z printf_uchar.uvalue
    // [1790] call printf_uchar
    // [1236] phi from rom_get_version_text::@1 to printf_uchar [phi:rom_get_version_text::@1->printf_uchar]
    // [1236] phi printf_uchar::format_zero_padding#14 = 0 [phi:rom_get_version_text::@1->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1236] phi printf_uchar::format_min_length#14 = 0 [phi:rom_get_version_text::@1->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1236] phi printf_uchar::putc#14 = &snputc [phi:rom_get_version_text::@1->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1236] phi printf_uchar::format_radix#14 = DECIMAL [phi:rom_get_version_text::@1->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1236] phi printf_uchar::uvalue#14 = printf_uchar::uvalue#7 [phi:rom_get_version_text::@1->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1791] phi from rom_get_version_text::@1 to rom_get_version_text::@2 [phi:rom_get_version_text::@1->rom_get_version_text::@2]
    // rom_get_version_text::@2
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [1792] call printf_str
    // [1156] phi from rom_get_version_text::@2 to printf_str [phi:rom_get_version_text::@2->printf_str]
    // [1156] phi printf_str::putc#71 = &snputc [phi:rom_get_version_text::@2->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1156] phi printf_str::s#71 = s [phi:rom_get_version_text::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_get_version_text::@3
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [1793] printf_string::str#12 = rom_get_version_text::github#2 -- pbuz1=pbuz2 
    lda.z github
    sta.z printf_string.str
    lda.z github+1
    sta.z printf_string.str+1
    // [1794] call printf_string
    // [1165] phi from rom_get_version_text::@3 to printf_string [phi:rom_get_version_text::@3->printf_string]
    // [1165] phi printf_string::putc#22 = &snputc [phi:rom_get_version_text::@3->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1165] phi printf_string::str#22 = printf_string::str#12 [phi:rom_get_version_text::@3->printf_string#1] -- register_copy 
    // [1165] phi printf_string::format_justify_left#22 = 0 [phi:rom_get_version_text::@3->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1165] phi printf_string::format_min_length#22 = 0 [phi:rom_get_version_text::@3->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // rom_get_version_text::@4
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [1795] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1796] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // rom_get_version_text::@return
    // }
    // [1798] return 
    rts
  .segment Data
    .label prefix = rom_get_prefix.return
    .label release = rom_get_release.return
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
// void display_info_led(__zp($c4) char x, __zp($cf) char y, __zp($e6) char tc, char bc)
display_info_led: {
    .label tc = $e6
    .label y = $cf
    .label x = $c4
    // textcolor(tc)
    // [1800] textcolor::color#13 = display_info_led::tc#4 -- vbuz1=vbuz2 
    lda.z tc
    sta.z textcolor.color
    // [1801] call textcolor
    // [738] phi from display_info_led to textcolor [phi:display_info_led->textcolor]
    // [738] phi textcolor::color#18 = textcolor::color#13 [phi:display_info_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [1802] phi from display_info_led to display_info_led::@1 [phi:display_info_led->display_info_led::@1]
    // display_info_led::@1
    // bgcolor(bc)
    // [1803] call bgcolor
    // [743] phi from display_info_led::@1 to bgcolor [phi:display_info_led::@1->bgcolor]
    // [743] phi bgcolor::color#14 = BLUE [phi:display_info_led::@1->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // display_info_led::@2
    // cputcxy(x, y, VERA_CHR_UR)
    // [1804] cputcxy::x#11 = display_info_led::x#4
    // [1805] cputcxy::y#11 = display_info_led::y#4
    // [1806] call cputcxy
    // [2039] phi from display_info_led::@2 to cputcxy [phi:display_info_led::@2->cputcxy]
    // [2039] phi cputcxy::c#15 = $7c [phi:display_info_led::@2->cputcxy#0] -- vbuz1=vbuc1 
    lda #$7c
    sta.z cputcxy.c
    // [2039] phi cputcxy::y#15 = cputcxy::y#11 [phi:display_info_led::@2->cputcxy#1] -- register_copy 
    // [2039] phi cputcxy::x#15 = cputcxy::x#11 [phi:display_info_led::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [1807] phi from display_info_led::@2 to display_info_led::@3 [phi:display_info_led::@2->display_info_led::@3]
    // display_info_led::@3
    // textcolor(WHITE)
    // [1808] call textcolor
    // [738] phi from display_info_led::@3 to textcolor [phi:display_info_led::@3->textcolor]
    // [738] phi textcolor::color#18 = WHITE [phi:display_info_led::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // display_info_led::@return
    // }
    // [1809] return 
    rts
}
  // printf_uint
// Print an unsigned int using a specific format
// void printf_uint(__zp($5e) void (*putc)(char), __zp($2d) unsigned int uvalue, __zp($ea) char format_min_length, char format_justify_left, char format_sign_always, __zp($e9) char format_zero_padding, char format_upper_case, __zp($e6) char format_radix)
printf_uint: {
    .label uvalue = $2d
    .label format_radix = $e6
    .label putc = $5e
    .label format_min_length = $ea
    .label format_zero_padding = $e9
    // printf_uint::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1811] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [1812] utoa::value#1 = printf_uint::uvalue#14
    // [1813] utoa::radix#0 = printf_uint::format_radix#14
    // [1814] call utoa
    // Format number into buffer
    jsr utoa
    // printf_uint::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1815] printf_number_buffer::putc#1 = printf_uint::putc#14
    // [1816] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [1817] printf_number_buffer::format_min_length#1 = printf_uint::format_min_length#14
    // [1818] printf_number_buffer::format_zero_padding#1 = printf_uint::format_zero_padding#14
    // [1819] call printf_number_buffer
  // Print using format
    // [2362] phi from printf_uint::@2 to printf_number_buffer [phi:printf_uint::@2->printf_number_buffer]
    // [2362] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#1 [phi:printf_uint::@2->printf_number_buffer#0] -- register_copy 
    // [2362] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_uint::@2->printf_number_buffer#1] -- register_copy 
    // [2362] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#1 [phi:printf_uint::@2->printf_number_buffer#2] -- register_copy 
    // [2362] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#1 [phi:printf_uint::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uint::@return
    // }
    // [1820] return 
    rts
}
  // screenlayer
// --- layer management in VERA ---
// void screenlayer(char layer, __zp($e4) char mapbase, __zp($e1) char config)
screenlayer: {
    .label screenlayer__1 = $e4
    .label screenlayer__5 = $e1
    .label screenlayer__6 = $e1
    .label mapbase = $e4
    .label config = $e1
    .label y = $e0
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [1821] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [1822] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [1823] *((char *)&__conio+2) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+2
    // mapbase >> 7
    // [1824] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbum1=vbuz2_ror_7 
    lda.z mapbase
    rol
    rol
    and #1
    sta screenlayer__0
    // __conio.mapbase_bank = mapbase >> 7
    // [1825] *((char *)&__conio+5) = screenlayer::$0 -- _deref_pbuc1=vbum1 
    sta __conio+5
    // (mapbase)<<1
    // [1826] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z screenlayer__1
    // MAKEWORD((mapbase)<<1,0)
    // [1827] screenlayer::$2 = screenlayer::$1 w= 0 -- vwum1=vbuz2_word_vbuc1 
    lda #0
    ldy.z screenlayer__1
    sty screenlayer__2+1
    sta screenlayer__2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [1828] *((unsigned int *)&__conio+3) = screenlayer::$2 -- _deref_pwuc1=vwum1 
    sta __conio+3
    tya
    sta __conio+3+1
    // config & VERA_LAYER_WIDTH_MASK
    // [1829] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbum1=vbuz2_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and.z config
    sta screenlayer__7
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [1830] screenlayer::$8 = screenlayer::$7 >> 4 -- vbum1=vbum1_ror_4 
    lda screenlayer__8
    lsr
    lsr
    lsr
    lsr
    sta screenlayer__8
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [1831] *((char *)&__conio+8) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbum1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+8
    // config & VERA_LAYER_HEIGHT_MASK
    // [1832] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbuz1=vbuz1_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and.z screenlayer__5
    sta.z screenlayer__5
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [1833] screenlayer::$6 = screenlayer::$5 >> 6 -- vbuz1=vbuz1_ror_6 
    lda.z screenlayer__6
    rol
    rol
    rol
    and #3
    sta.z screenlayer__6
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [1834] *((char *)&__conio+9) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+9
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [1835] screenlayer::$16 = screenlayer::$8 << 1 -- vbum1=vbum1_rol_1 
    asl screenlayer__16
    // [1836] *((unsigned int *)&__conio+$a) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbum1 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    ldy screenlayer__16
    lda VERA_LAYER_SKIP,y
    sta __conio+$a
    lda VERA_LAYER_SKIP+1,y
    sta __conio+$a+1
    // vera_dc_hscale_temp == 0x80
    // [1837] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vbom1=vbum2_eq_vbuc1 
    lda vera_dc_hscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta screenlayer__9
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [1838] screenlayer::$18 = (char)screenlayer::$9
    // [1839] screenlayer::$10 = $28 << screenlayer::$18 -- vbum1=vbuc1_rol_vbum1 
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
    // [1840] screenlayer::$11 = screenlayer::$10 - 1 -- vbum1=vbum1_minus_1 
    dec screenlayer__11
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [1841] *((char *)&__conio+6) = screenlayer::$11 -- _deref_pbuc1=vbum1 
    lda screenlayer__11
    sta __conio+6
    // vera_dc_vscale_temp == 0x80
    // [1842] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vbom1=vbum2_eq_vbuc1 
    lda vera_dc_vscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta screenlayer__12
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [1843] screenlayer::$19 = (char)screenlayer::$12
    // [1844] screenlayer::$13 = $1e << screenlayer::$19 -- vbum1=vbuc1_rol_vbum1 
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
    // [1845] screenlayer::$14 = screenlayer::$13 - 1 -- vbum1=vbum1_minus_1 
    dec screenlayer__14
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [1846] *((char *)&__conio+7) = screenlayer::$14 -- _deref_pbuc1=vbum1 
    lda screenlayer__14
    sta __conio+7
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [1847] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta mapbase_offset
    lda __conio+3+1
    sta mapbase_offset+1
    // [1848] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [1848] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [1848] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [1849] if(screenlayer::y#2<=*((char *)&__conio+7)) goto screenlayer::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+7
    cmp.z y
    bcs __b2
    // screenlayer::@return
    // }
    // [1850] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [1851] screenlayer::$17 = screenlayer::y#2 << 1 -- vbum1=vbuz2_rol_1 
    lda.z y
    asl
    sta screenlayer__17
    // [1852] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbum1=vwum2 
    tay
    lda mapbase_offset
    sta __conio+$15,y
    lda mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [1853] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda mapbase_offset
    adc __conio+$a
    sta mapbase_offset
    lda mapbase_offset+1
    adc __conio+$a+1
    sta mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [1854] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [1848] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [1848] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [1848] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
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
    // [1855] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [1856] if(0!=((char *)&__conio+$f)[*((char *)&__conio+2)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [1857] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // [1858] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [1859] call gotoxy
    // [756] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [756] phi gotoxy::y#30 = 0 [phi:cscroll::@3->gotoxy#0] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.y
    // [756] phi gotoxy::x#30 = 0 [phi:cscroll::@3->gotoxy#1] -- vbuz1=vbuc1 
    sta.z gotoxy.x
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [1860] return 
    rts
    // [1861] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [1862] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [1863] gotoxy::y#3 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
    lda __conio+7
    sta.z gotoxy.y
    // [1864] call gotoxy
    // [756] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [756] phi gotoxy::y#30 = gotoxy::y#3 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [756] phi gotoxy::x#30 = 0 [phi:cscroll::@5->gotoxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.x
    jsr gotoxy
    // [1865] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [1866] call clearline
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
    // [1867] ((char *)&__conio+$f)[*((char *)&__conio+2)] = scroll::onoff#0 -- pbuc1_derefidx_(_deref_pbuc2)=vbuc3 
    lda #onoff
    ldy __conio+2
    sta __conio+$f,y
    // scroll::@return
    // }
    // [1868] return 
    rts
}
  // clrscr
// clears the screen and moves the cursor to the upper left-hand corner of the screen.
clrscr: {
    .label clrscr__0 = $ef
    .label clrscr__1 = $5d
    .label clrscr__2 = $38
    // unsigned int line_text = __conio.mapbase_offset
    // [1869] clrscr::line_text#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta line_text
    lda __conio+3+1
    sta line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1870] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [1871] clrscr::$0 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clrscr__0
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1872] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [1873] clrscr::l#0 = *((char *)&__conio+9) -- vbum1=_deref_pbuc1 
    lda __conio+9
    sta l
    // [1874] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [1874] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [1874] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [1875] clrscr::$1 = byte0  clrscr::ch#0 -- vbuz1=_byte0_vwum2 
    lda ch
    sta.z clrscr__1
    // *VERA_ADDRX_L = BYTE0(ch)
    // [1876] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbuz1 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [1877] clrscr::$2 = byte1  clrscr::ch#0 -- vbuz1=_byte1_vwum2 
    lda ch+1
    sta.z clrscr__2
    // *VERA_ADDRX_M = BYTE1(ch)
    // [1878] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth+1
    // [1879] clrscr::c#0 = *((char *)&__conio+8) + 1 -- vbum1=_deref_pbuc1_plus_1 
    lda __conio+8
    inc
    sta c
    // [1880] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [1880] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [1881] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1882] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [1883] clrscr::c#1 = -- clrscr::c#2 -- vbum1=_dec_vbum1 
    dec c
    // while(c)
    // [1884] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [1885] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda line_text
    adc __conio+$a
    sta line_text
    lda line_text+1
    adc __conio+$a+1
    sta line_text+1
    // l--;
    // [1886] clrscr::l#1 = -- clrscr::l#4 -- vbum1=_dec_vbum1 
    dec l
    // while(l)
    // [1887] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbum1_then_la1 
    lda l
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [1888] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y = 0
    // [1889] *((char *)&__conio+1) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+1
    // __conio.offset = __conio.mapbase_offset
    // [1890] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+3) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+3
    sta __conio+$13
    lda __conio+3+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [1891] return 
    rts
  .segment Data
    .label line_text = ch
    .label l = main.check_status_smc7_main__0
    ch: .word 0
    .label c = main.check_status_vera3_main__0
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
// void display_frame(char x0, char y0, __zp($6a) char x1, __zp($70) char y1)
display_frame: {
    .label w = $5d
    .label h = $38
    .label x = $71
    .label y = $53
    .label c = $d4
    .label x_1 = $ba
    .label y_1 = $67
    .label x1 = $6a
    .label y1 = $70
    // unsigned char w = x1 - x0
    // [1893] display_frame::w#0 = display_frame::x1#16 - display_frame::x#0 -- vbuz1=vbuz2_minus_vbuz3 
    lda.z x1
    sec
    sbc.z x
    sta.z w
    // unsigned char h = y1 - y0
    // [1894] display_frame::h#0 = display_frame::y1#16 - display_frame::y#0 -- vbuz1=vbuz2_minus_vbuz3 
    lda.z y1
    sec
    sbc.z y
    sta.z h
    // unsigned char mask = display_frame_maskxy(x, y)
    // [1895] display_frame_maskxy::x#0 = display_frame::x#0 -- vbum1=vbuz2 
    lda.z x
    sta display_frame_maskxy.x
    // [1896] display_frame_maskxy::y#0 = display_frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z display_frame_maskxy.y
    // [1897] call display_frame_maskxy
    // [2552] phi from display_frame to display_frame_maskxy [phi:display_frame->display_frame_maskxy]
    // [2552] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#0 [phi:display_frame->display_frame_maskxy#0] -- register_copy 
    // [2552] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#0 [phi:display_frame->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // unsigned char mask = display_frame_maskxy(x, y)
    // [1898] display_frame_maskxy::return#13 = display_frame_maskxy::return#12
    // display_frame::@13
    // [1899] display_frame::mask#0 = display_frame_maskxy::return#13
    // mask |= 0b0110
    // [1900] display_frame::mask#1 = display_frame::mask#0 | 6 -- vbum1=vbum1_bor_vbuc1 
    lda #6
    ora mask
    sta mask
    // unsigned char c = display_frame_char(mask)
    // [1901] display_frame_char::mask#0 = display_frame::mask#1
    // [1902] call display_frame_char
  // Add a corner.
    // [2578] phi from display_frame::@13 to display_frame_char [phi:display_frame::@13->display_frame_char]
    // [2578] phi display_frame_char::mask#10 = display_frame_char::mask#0 [phi:display_frame::@13->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // unsigned char c = display_frame_char(mask)
    // [1903] display_frame_char::return#13 = display_frame_char::return#12
    // display_frame::@14
    // [1904] display_frame::c#0 = display_frame_char::return#13
    // cputcxy(x, y, c)
    // [1905] cputcxy::x#0 = display_frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1906] cputcxy::y#0 = display_frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [1907] cputcxy::c#0 = display_frame::c#0
    // [1908] call cputcxy
    // [2039] phi from display_frame::@14 to cputcxy [phi:display_frame::@14->cputcxy]
    // [2039] phi cputcxy::c#15 = cputcxy::c#0 [phi:display_frame::@14->cputcxy#0] -- register_copy 
    // [2039] phi cputcxy::y#15 = cputcxy::y#0 [phi:display_frame::@14->cputcxy#1] -- register_copy 
    // [2039] phi cputcxy::x#15 = cputcxy::x#0 [phi:display_frame::@14->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@15
    // if(w>=2)
    // [1909] if(display_frame::w#0<2) goto display_frame::@36 -- vbuz1_lt_vbuc1_then_la1 
    lda.z w
    cmp #2
    bcs !__b36+
    jmp __b36
  !__b36:
    // display_frame::@2
    // x++;
    // [1910] display_frame::x#1 = ++ display_frame::x#0 -- vbuz1=_inc_vbuz2 
    lda.z x
    inc
    sta.z x_1
    // [1911] phi from display_frame::@2 display_frame::@21 to display_frame::@4 [phi:display_frame::@2/display_frame::@21->display_frame::@4]
    // [1911] phi display_frame::x#10 = display_frame::x#1 [phi:display_frame::@2/display_frame::@21->display_frame::@4#0] -- register_copy 
    // display_frame::@4
  __b4:
    // while(x < x1)
    // [1912] if(display_frame::x#10<display_frame::x1#16) goto display_frame::@5 -- vbuz1_lt_vbuz2_then_la1 
    lda.z x_1
    cmp.z x1
    bcs !__b5+
    jmp __b5
  !__b5:
    // [1913] phi from display_frame::@36 display_frame::@4 to display_frame::@1 [phi:display_frame::@36/display_frame::@4->display_frame::@1]
    // [1913] phi display_frame::x#24 = display_frame::x#30 [phi:display_frame::@36/display_frame::@4->display_frame::@1#0] -- register_copy 
    // display_frame::@1
  __b1:
    // display_frame_maskxy(x, y)
    // [1914] display_frame_maskxy::x#1 = display_frame::x#24 -- vbum1=vbuz2 
    lda.z x_1
    sta display_frame_maskxy.x
    // [1915] display_frame_maskxy::y#1 = display_frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z display_frame_maskxy.y
    // [1916] call display_frame_maskxy
    // [2552] phi from display_frame::@1 to display_frame_maskxy [phi:display_frame::@1->display_frame_maskxy]
    // [2552] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#1 [phi:display_frame::@1->display_frame_maskxy#0] -- register_copy 
    // [2552] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#1 [phi:display_frame::@1->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1917] display_frame_maskxy::return#14 = display_frame_maskxy::return#12
    // display_frame::@16
    // mask = display_frame_maskxy(x, y)
    // [1918] display_frame::mask#2 = display_frame_maskxy::return#14
    // mask |= 0b0011
    // [1919] display_frame::mask#3 = display_frame::mask#2 | 3 -- vbum1=vbum1_bor_vbuc1 
    lda #3
    ora mask
    sta mask
    // display_frame_char(mask)
    // [1920] display_frame_char::mask#1 = display_frame::mask#3
    // [1921] call display_frame_char
    // [2578] phi from display_frame::@16 to display_frame_char [phi:display_frame::@16->display_frame_char]
    // [2578] phi display_frame_char::mask#10 = display_frame_char::mask#1 [phi:display_frame::@16->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1922] display_frame_char::return#14 = display_frame_char::return#12
    // display_frame::@17
    // c = display_frame_char(mask)
    // [1923] display_frame::c#1 = display_frame_char::return#14
    // cputcxy(x, y, c)
    // [1924] cputcxy::x#1 = display_frame::x#24 -- vbuz1=vbuz2 
    lda.z x_1
    sta.z cputcxy.x
    // [1925] cputcxy::y#1 = display_frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [1926] cputcxy::c#1 = display_frame::c#1
    // [1927] call cputcxy
    // [2039] phi from display_frame::@17 to cputcxy [phi:display_frame::@17->cputcxy]
    // [2039] phi cputcxy::c#15 = cputcxy::c#1 [phi:display_frame::@17->cputcxy#0] -- register_copy 
    // [2039] phi cputcxy::y#15 = cputcxy::y#1 [phi:display_frame::@17->cputcxy#1] -- register_copy 
    // [2039] phi cputcxy::x#15 = cputcxy::x#1 [phi:display_frame::@17->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@18
    // if(h>=2)
    // [1928] if(display_frame::h#0<2) goto display_frame::@return -- vbuz1_lt_vbuc1_then_la1 
    lda.z h
    cmp #2
    bcc __breturn
    // display_frame::@3
    // y++;
    // [1929] display_frame::y#1 = ++ display_frame::y#0 -- vbuz1=_inc_vbuz2 
    lda.z y
    inc
    sta.z y_1
    // [1930] phi from display_frame::@27 display_frame::@3 to display_frame::@6 [phi:display_frame::@27/display_frame::@3->display_frame::@6]
    // [1930] phi display_frame::y#10 = display_frame::y#2 [phi:display_frame::@27/display_frame::@3->display_frame::@6#0] -- register_copy 
    // display_frame::@6
  __b6:
    // while(y < y1)
    // [1931] if(display_frame::y#10<display_frame::y1#16) goto display_frame::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z y_1
    cmp.z y1
    bcc __b7
    // display_frame::@8
    // display_frame_maskxy(x, y)
    // [1932] display_frame_maskxy::x#5 = display_frame::x#0 -- vbum1=vbuz2 
    lda.z x
    sta display_frame_maskxy.x
    // [1933] display_frame_maskxy::y#5 = display_frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z display_frame_maskxy.y
    // [1934] call display_frame_maskxy
    // [2552] phi from display_frame::@8 to display_frame_maskxy [phi:display_frame::@8->display_frame_maskxy]
    // [2552] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#5 [phi:display_frame::@8->display_frame_maskxy#0] -- register_copy 
    // [2552] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#5 [phi:display_frame::@8->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1935] display_frame_maskxy::return#18 = display_frame_maskxy::return#12
    // display_frame::@28
    // mask = display_frame_maskxy(x, y)
    // [1936] display_frame::mask#10 = display_frame_maskxy::return#18
    // mask |= 0b1100
    // [1937] display_frame::mask#11 = display_frame::mask#10 | $c -- vbum1=vbum1_bor_vbuc1 
    lda #$c
    ora mask
    sta mask
    // display_frame_char(mask)
    // [1938] display_frame_char::mask#5 = display_frame::mask#11
    // [1939] call display_frame_char
    // [2578] phi from display_frame::@28 to display_frame_char [phi:display_frame::@28->display_frame_char]
    // [2578] phi display_frame_char::mask#10 = display_frame_char::mask#5 [phi:display_frame::@28->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1940] display_frame_char::return#18 = display_frame_char::return#12
    // display_frame::@29
    // c = display_frame_char(mask)
    // [1941] display_frame::c#5 = display_frame_char::return#18
    // cputcxy(x, y, c)
    // [1942] cputcxy::x#5 = display_frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1943] cputcxy::y#5 = display_frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1944] cputcxy::c#5 = display_frame::c#5
    // [1945] call cputcxy
    // [2039] phi from display_frame::@29 to cputcxy [phi:display_frame::@29->cputcxy]
    // [2039] phi cputcxy::c#15 = cputcxy::c#5 [phi:display_frame::@29->cputcxy#0] -- register_copy 
    // [2039] phi cputcxy::y#15 = cputcxy::y#5 [phi:display_frame::@29->cputcxy#1] -- register_copy 
    // [2039] phi cputcxy::x#15 = cputcxy::x#5 [phi:display_frame::@29->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@30
    // if(w>=2)
    // [1946] if(display_frame::w#0<2) goto display_frame::@10 -- vbuz1_lt_vbuc1_then_la1 
    lda.z w
    cmp #2
    bcc __b10
    // display_frame::@9
    // x++;
    // [1947] display_frame::x#4 = ++ display_frame::x#0 -- vbuz1=_inc_vbuz1 
    inc.z x
    // [1948] phi from display_frame::@35 display_frame::@9 to display_frame::@11 [phi:display_frame::@35/display_frame::@9->display_frame::@11]
    // [1948] phi display_frame::x#18 = display_frame::x#5 [phi:display_frame::@35/display_frame::@9->display_frame::@11#0] -- register_copy 
    // display_frame::@11
  __b11:
    // while(x < x1)
    // [1949] if(display_frame::x#18<display_frame::x1#16) goto display_frame::@12 -- vbuz1_lt_vbuz2_then_la1 
    lda.z x
    cmp.z x1
    bcc __b12
    // [1950] phi from display_frame::@11 display_frame::@30 to display_frame::@10 [phi:display_frame::@11/display_frame::@30->display_frame::@10]
    // [1950] phi display_frame::x#15 = display_frame::x#18 [phi:display_frame::@11/display_frame::@30->display_frame::@10#0] -- register_copy 
    // display_frame::@10
  __b10:
    // display_frame_maskxy(x, y)
    // [1951] display_frame_maskxy::x#6 = display_frame::x#15 -- vbum1=vbuz2 
    lda.z x
    sta display_frame_maskxy.x
    // [1952] display_frame_maskxy::y#6 = display_frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z display_frame_maskxy.y
    // [1953] call display_frame_maskxy
    // [2552] phi from display_frame::@10 to display_frame_maskxy [phi:display_frame::@10->display_frame_maskxy]
    // [2552] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#6 [phi:display_frame::@10->display_frame_maskxy#0] -- register_copy 
    // [2552] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#6 [phi:display_frame::@10->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1954] display_frame_maskxy::return#19 = display_frame_maskxy::return#12
    // display_frame::@31
    // mask = display_frame_maskxy(x, y)
    // [1955] display_frame::mask#12 = display_frame_maskxy::return#19
    // mask |= 0b1001
    // [1956] display_frame::mask#13 = display_frame::mask#12 | 9 -- vbum1=vbum1_bor_vbuc1 
    lda #9
    ora mask
    sta mask
    // display_frame_char(mask)
    // [1957] display_frame_char::mask#6 = display_frame::mask#13
    // [1958] call display_frame_char
    // [2578] phi from display_frame::@31 to display_frame_char [phi:display_frame::@31->display_frame_char]
    // [2578] phi display_frame_char::mask#10 = display_frame_char::mask#6 [phi:display_frame::@31->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1959] display_frame_char::return#19 = display_frame_char::return#12
    // display_frame::@32
    // c = display_frame_char(mask)
    // [1960] display_frame::c#6 = display_frame_char::return#19
    // cputcxy(x, y, c)
    // [1961] cputcxy::x#6 = display_frame::x#15 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1962] cputcxy::y#6 = display_frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1963] cputcxy::c#6 = display_frame::c#6
    // [1964] call cputcxy
    // [2039] phi from display_frame::@32 to cputcxy [phi:display_frame::@32->cputcxy]
    // [2039] phi cputcxy::c#15 = cputcxy::c#6 [phi:display_frame::@32->cputcxy#0] -- register_copy 
    // [2039] phi cputcxy::y#15 = cputcxy::y#6 [phi:display_frame::@32->cputcxy#1] -- register_copy 
    // [2039] phi cputcxy::x#15 = cputcxy::x#6 [phi:display_frame::@32->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@return
  __breturn:
    // }
    // [1965] return 
    rts
    // display_frame::@12
  __b12:
    // display_frame_maskxy(x, y)
    // [1966] display_frame_maskxy::x#7 = display_frame::x#18 -- vbum1=vbuz2 
    lda.z x
    sta display_frame_maskxy.x
    // [1967] display_frame_maskxy::y#7 = display_frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z display_frame_maskxy.y
    // [1968] call display_frame_maskxy
    // [2552] phi from display_frame::@12 to display_frame_maskxy [phi:display_frame::@12->display_frame_maskxy]
    // [2552] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#7 [phi:display_frame::@12->display_frame_maskxy#0] -- register_copy 
    // [2552] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#7 [phi:display_frame::@12->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1969] display_frame_maskxy::return#20 = display_frame_maskxy::return#12
    // display_frame::@33
    // mask = display_frame_maskxy(x, y)
    // [1970] display_frame::mask#14 = display_frame_maskxy::return#20
    // mask |= 0b0101
    // [1971] display_frame::mask#15 = display_frame::mask#14 | 5 -- vbum1=vbum1_bor_vbuc1 
    lda #5
    ora mask
    sta mask
    // display_frame_char(mask)
    // [1972] display_frame_char::mask#7 = display_frame::mask#15
    // [1973] call display_frame_char
    // [2578] phi from display_frame::@33 to display_frame_char [phi:display_frame::@33->display_frame_char]
    // [2578] phi display_frame_char::mask#10 = display_frame_char::mask#7 [phi:display_frame::@33->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1974] display_frame_char::return#20 = display_frame_char::return#12
    // display_frame::@34
    // c = display_frame_char(mask)
    // [1975] display_frame::c#7 = display_frame_char::return#20
    // cputcxy(x, y, c)
    // [1976] cputcxy::x#7 = display_frame::x#18 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1977] cputcxy::y#7 = display_frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1978] cputcxy::c#7 = display_frame::c#7
    // [1979] call cputcxy
    // [2039] phi from display_frame::@34 to cputcxy [phi:display_frame::@34->cputcxy]
    // [2039] phi cputcxy::c#15 = cputcxy::c#7 [phi:display_frame::@34->cputcxy#0] -- register_copy 
    // [2039] phi cputcxy::y#15 = cputcxy::y#7 [phi:display_frame::@34->cputcxy#1] -- register_copy 
    // [2039] phi cputcxy::x#15 = cputcxy::x#7 [phi:display_frame::@34->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@35
    // x++;
    // [1980] display_frame::x#5 = ++ display_frame::x#18 -- vbuz1=_inc_vbuz1 
    inc.z x
    jmp __b11
    // display_frame::@7
  __b7:
    // display_frame_maskxy(x0, y)
    // [1981] display_frame_maskxy::x#3 = display_frame::x#0 -- vbum1=vbuz2 
    lda.z x
    sta display_frame_maskxy.x
    // [1982] display_frame_maskxy::y#3 = display_frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z display_frame_maskxy.y
    // [1983] call display_frame_maskxy
    // [2552] phi from display_frame::@7 to display_frame_maskxy [phi:display_frame::@7->display_frame_maskxy]
    // [2552] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#3 [phi:display_frame::@7->display_frame_maskxy#0] -- register_copy 
    // [2552] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#3 [phi:display_frame::@7->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x0, y)
    // [1984] display_frame_maskxy::return#16 = display_frame_maskxy::return#12
    // display_frame::@22
    // mask = display_frame_maskxy(x0, y)
    // [1985] display_frame::mask#6 = display_frame_maskxy::return#16
    // mask |= 0b1010
    // [1986] display_frame::mask#7 = display_frame::mask#6 | $a -- vbum1=vbum1_bor_vbuc1 
    lda #$a
    ora mask
    sta mask
    // display_frame_char(mask)
    // [1987] display_frame_char::mask#3 = display_frame::mask#7
    // [1988] call display_frame_char
    // [2578] phi from display_frame::@22 to display_frame_char [phi:display_frame::@22->display_frame_char]
    // [2578] phi display_frame_char::mask#10 = display_frame_char::mask#3 [phi:display_frame::@22->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1989] display_frame_char::return#16 = display_frame_char::return#12
    // display_frame::@23
    // c = display_frame_char(mask)
    // [1990] display_frame::c#3 = display_frame_char::return#16
    // cputcxy(x0, y, c)
    // [1991] cputcxy::x#3 = display_frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1992] cputcxy::y#3 = display_frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1993] cputcxy::c#3 = display_frame::c#3
    // [1994] call cputcxy
    // [2039] phi from display_frame::@23 to cputcxy [phi:display_frame::@23->cputcxy]
    // [2039] phi cputcxy::c#15 = cputcxy::c#3 [phi:display_frame::@23->cputcxy#0] -- register_copy 
    // [2039] phi cputcxy::y#15 = cputcxy::y#3 [phi:display_frame::@23->cputcxy#1] -- register_copy 
    // [2039] phi cputcxy::x#15 = cputcxy::x#3 [phi:display_frame::@23->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@24
    // display_frame_maskxy(x1, y)
    // [1995] display_frame_maskxy::x#4 = display_frame::x1#16 -- vbum1=vbuz2 
    lda.z x1
    sta display_frame_maskxy.x
    // [1996] display_frame_maskxy::y#4 = display_frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z display_frame_maskxy.y
    // [1997] call display_frame_maskxy
    // [2552] phi from display_frame::@24 to display_frame_maskxy [phi:display_frame::@24->display_frame_maskxy]
    // [2552] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#4 [phi:display_frame::@24->display_frame_maskxy#0] -- register_copy 
    // [2552] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#4 [phi:display_frame::@24->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x1, y)
    // [1998] display_frame_maskxy::return#17 = display_frame_maskxy::return#12
    // display_frame::@25
    // mask = display_frame_maskxy(x1, y)
    // [1999] display_frame::mask#8 = display_frame_maskxy::return#17
    // mask |= 0b1010
    // [2000] display_frame::mask#9 = display_frame::mask#8 | $a -- vbum1=vbum1_bor_vbuc1 
    lda #$a
    ora mask
    sta mask
    // display_frame_char(mask)
    // [2001] display_frame_char::mask#4 = display_frame::mask#9
    // [2002] call display_frame_char
    // [2578] phi from display_frame::@25 to display_frame_char [phi:display_frame::@25->display_frame_char]
    // [2578] phi display_frame_char::mask#10 = display_frame_char::mask#4 [phi:display_frame::@25->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [2003] display_frame_char::return#17 = display_frame_char::return#12
    // display_frame::@26
    // c = display_frame_char(mask)
    // [2004] display_frame::c#4 = display_frame_char::return#17
    // cputcxy(x1, y, c)
    // [2005] cputcxy::x#4 = display_frame::x1#16 -- vbuz1=vbuz2 
    lda.z x1
    sta.z cputcxy.x
    // [2006] cputcxy::y#4 = display_frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [2007] cputcxy::c#4 = display_frame::c#4
    // [2008] call cputcxy
    // [2039] phi from display_frame::@26 to cputcxy [phi:display_frame::@26->cputcxy]
    // [2039] phi cputcxy::c#15 = cputcxy::c#4 [phi:display_frame::@26->cputcxy#0] -- register_copy 
    // [2039] phi cputcxy::y#15 = cputcxy::y#4 [phi:display_frame::@26->cputcxy#1] -- register_copy 
    // [2039] phi cputcxy::x#15 = cputcxy::x#4 [phi:display_frame::@26->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@27
    // y++;
    // [2009] display_frame::y#2 = ++ display_frame::y#10 -- vbuz1=_inc_vbuz1 
    inc.z y_1
    jmp __b6
    // display_frame::@5
  __b5:
    // display_frame_maskxy(x, y)
    // [2010] display_frame_maskxy::x#2 = display_frame::x#10 -- vbum1=vbuz2 
    lda.z x_1
    sta display_frame_maskxy.x
    // [2011] display_frame_maskxy::y#2 = display_frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z display_frame_maskxy.y
    // [2012] call display_frame_maskxy
    // [2552] phi from display_frame::@5 to display_frame_maskxy [phi:display_frame::@5->display_frame_maskxy]
    // [2552] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#2 [phi:display_frame::@5->display_frame_maskxy#0] -- register_copy 
    // [2552] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#2 [phi:display_frame::@5->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [2013] display_frame_maskxy::return#15 = display_frame_maskxy::return#12
    // display_frame::@19
    // mask = display_frame_maskxy(x, y)
    // [2014] display_frame::mask#4 = display_frame_maskxy::return#15
    // mask |= 0b0101
    // [2015] display_frame::mask#5 = display_frame::mask#4 | 5 -- vbum1=vbum1_bor_vbuc1 
    lda #5
    ora mask
    sta mask
    // display_frame_char(mask)
    // [2016] display_frame_char::mask#2 = display_frame::mask#5
    // [2017] call display_frame_char
    // [2578] phi from display_frame::@19 to display_frame_char [phi:display_frame::@19->display_frame_char]
    // [2578] phi display_frame_char::mask#10 = display_frame_char::mask#2 [phi:display_frame::@19->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [2018] display_frame_char::return#15 = display_frame_char::return#12
    // display_frame::@20
    // c = display_frame_char(mask)
    // [2019] display_frame::c#2 = display_frame_char::return#15
    // cputcxy(x, y, c)
    // [2020] cputcxy::x#2 = display_frame::x#10 -- vbuz1=vbuz2 
    lda.z x_1
    sta.z cputcxy.x
    // [2021] cputcxy::y#2 = display_frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [2022] cputcxy::c#2 = display_frame::c#2
    // [2023] call cputcxy
    // [2039] phi from display_frame::@20 to cputcxy [phi:display_frame::@20->cputcxy]
    // [2039] phi cputcxy::c#15 = cputcxy::c#2 [phi:display_frame::@20->cputcxy#0] -- register_copy 
    // [2039] phi cputcxy::y#15 = cputcxy::y#2 [phi:display_frame::@20->cputcxy#1] -- register_copy 
    // [2039] phi cputcxy::x#15 = cputcxy::x#2 [phi:display_frame::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@21
    // x++;
    // [2024] display_frame::x#2 = ++ display_frame::x#10 -- vbuz1=_inc_vbuz1 
    inc.z x_1
    jmp __b4
    // display_frame::@36
  __b36:
    // [2025] display_frame::x#30 = display_frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z x_1
    jmp __b1
  .segment Data
    .label mask = fopen.fopen__4
}
.segment Code
  // cputs
// Output a NUL-terminated string at the current cursor position
// void cputs(__zp($dd) const char *s)
cputs: {
    .label c = $2c
    .label s = $dd
    // [2027] phi from cputs cputs::@2 to cputs::@1 [phi:cputs/cputs::@2->cputs::@1]
    // [2027] phi cputs::s#2 = cputs::s#1 [phi:cputs/cputs::@2->cputs::@1#0] -- register_copy 
    // cputs::@1
  __b1:
    // while(c=*s++)
    // [2028] cputs::c#1 = *cputs::s#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta.z c
    // [2029] cputs::s#0 = ++ cputs::s#2 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [2030] if(0!=cputs::c#1) goto cputs::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // cputs::@return
    // }
    // [2031] return 
    rts
    // cputs::@2
  __b2:
    // cputc(c)
    // [2032] stackpush(char) = cputs::c#1 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [2033] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
}
  // wherex
// Return the x position of the cursor
wherex: {
    .label return = $bb
    .label return_1 = $6c
    .label return_2 = $e2
    .label return_3 = $6b
    .label return_4 = $5b
    // return __conio.cursor_x;
    // [2035] wherex::return#0 = *((char *)&__conio) -- vbuz1=_deref_pbuc1 
    lda __conio
    sta.z return
    // wherex::@return
    // }
    // [2036] return 
    rts
}
  // wherey
// Return the y position of the cursor
wherey: {
    .label return = $c3
    .label return_1 = $45
    .label return_2 = $66
    .label return_3 = $e3
    .label return_4 = $54
    // return __conio.cursor_y;
    // [2037] wherey::return#0 = *((char *)&__conio+1) -- vbuz1=_deref_pbuc1 
    lda __conio+1
    sta.z return
    // wherey::@return
    // }
    // [2038] return 
    rts
}
  // cputcxy
// Move cursor and output one character
// Same as "gotoxy (x, y); cputc (c);"
// void cputcxy(__zp($c4) char x, __zp($cf) char y, __zp($d4) char c)
cputcxy: {
    .label x = $c4
    .label y = $cf
    .label c = $d4
    // gotoxy(x, y)
    // [2040] gotoxy::x#0 = cputcxy::x#15 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [2041] gotoxy::y#0 = cputcxy::y#15 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [2042] call gotoxy
    // [756] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [756] phi gotoxy::y#30 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [756] phi gotoxy::x#30 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [2043] stackpush(char) = cputcxy::c#15 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [2044] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [2046] return 
    rts
}
  // display_smc_led
/**
 * @brief Print SMC led above the SMC chip.
 * 
 * @param c Led color
 */
// void display_smc_led(__zp($e6) char c)
display_smc_led: {
    .label c = $e6
    // display_chip_led(CHIP_SMC_X+1, CHIP_SMC_Y, CHIP_SMC_W, c, BLUE)
    // [2048] display_chip_led::tc#0 = display_smc_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_chip_led.tc
    // [2049] call display_chip_led
    // [2593] phi from display_smc_led to display_chip_led [phi:display_smc_led->display_chip_led]
    // [2593] phi display_chip_led::w#7 = 5 [phi:display_smc_led->display_chip_led#0] -- vbuz1=vbuc1 
    lda #5
    sta.z display_chip_led.w
    // [2593] phi display_chip_led::x#7 = 1+1 [phi:display_smc_led->display_chip_led#1] -- vbuz1=vbuc1 
    lda #1+1
    sta.z display_chip_led.x
    // [2593] phi display_chip_led::tc#3 = display_chip_led::tc#0 [phi:display_smc_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_smc_led::@1
    // display_info_led(INFO_X-2, INFO_Y, c, BLUE)
    // [2050] display_info_led::tc#0 = display_smc_led::c#2
    // [2051] call display_info_led
    // [1799] phi from display_smc_led::@1 to display_info_led [phi:display_smc_led::@1->display_info_led]
    // [1799] phi display_info_led::y#4 = $11 [phi:display_smc_led::@1->display_info_led#0] -- vbuz1=vbuc1 
    lda #$11
    sta.z display_info_led.y
    // [1799] phi display_info_led::x#4 = 4-2 [phi:display_smc_led::@1->display_info_led#1] -- vbuz1=vbuc1 
    lda #4-2
    sta.z display_info_led.x
    // [1799] phi display_info_led::tc#4 = display_info_led::tc#0 [phi:display_smc_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_smc_led::@return
    // }
    // [2052] return 
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
// void display_print_chip(__zp($df) char x, char y, __zp($73) char w, __zp($55) char *text)
display_print_chip: {
    .label y = 3+2+1+1+1+1+1+1+1+1
    .label text = $55
    .label x = $df
    .label text_5 = $74
    .label text_6 = $eb
    .label w = $73
    // display_chip_line(x, y++, w, *text++)
    // [2054] display_chip_line::x#0 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [2055] display_chip_line::w#0 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [2056] display_chip_line::c#0 = *display_print_chip::text#11 -- vbuz1=_deref_pbum2 
    ldy text_2
    sty.z $fe
    ldy text_2+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta.z display_chip_line.c
    // [2057] call display_chip_line
    // [2611] phi from display_print_chip to display_chip_line [phi:display_print_chip->display_chip_line]
    // [2611] phi display_chip_line::c#15 = display_chip_line::c#0 [phi:display_print_chip->display_chip_line#0] -- register_copy 
    // [2611] phi display_chip_line::w#10 = display_chip_line::w#0 [phi:display_print_chip->display_chip_line#1] -- register_copy 
    // [2611] phi display_chip_line::y#16 = 3+2 [phi:display_print_chip->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2
    sta.z display_chip_line.y
    // [2611] phi display_chip_line::x#16 = display_chip_line::x#0 [phi:display_print_chip->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@1
    // display_chip_line(x, y++, w, *text++);
    // [2058] display_print_chip::text#0 = ++ display_print_chip::text#11 -- pbuz1=_inc_pbum2 
    clc
    lda text_2
    adc #1
    sta.z text
    lda text_2+1
    adc #0
    sta.z text+1
    // display_chip_line(x, y++, w, *text++)
    // [2059] display_chip_line::x#1 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [2060] display_chip_line::w#1 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [2061] display_chip_line::c#1 = *display_print_chip::text#0 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text),y
    sta.z display_chip_line.c
    // [2062] call display_chip_line
    // [2611] phi from display_print_chip::@1 to display_chip_line [phi:display_print_chip::@1->display_chip_line]
    // [2611] phi display_chip_line::c#15 = display_chip_line::c#1 [phi:display_print_chip::@1->display_chip_line#0] -- register_copy 
    // [2611] phi display_chip_line::w#10 = display_chip_line::w#1 [phi:display_print_chip::@1->display_chip_line#1] -- register_copy 
    // [2611] phi display_chip_line::y#16 = ++3+2 [phi:display_print_chip::@1->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1
    sta.z display_chip_line.y
    // [2611] phi display_chip_line::x#16 = display_chip_line::x#1 [phi:display_print_chip::@1->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@2
    // display_chip_line(x, y++, w, *text++);
    // [2063] display_print_chip::text#1 = ++ display_print_chip::text#0 -- pbum1=_inc_pbuz2 
    clc
    lda.z text
    adc #1
    sta text_1
    lda.z text+1
    adc #0
    sta text_1+1
    // display_chip_line(x, y++, w, *text++)
    // [2064] display_chip_line::x#2 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [2065] display_chip_line::w#2 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [2066] display_chip_line::c#2 = *display_print_chip::text#1 -- vbuz1=_deref_pbum2 
    ldy text_1
    sty.z $fe
    ldy text_1+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta.z display_chip_line.c
    // [2067] call display_chip_line
    // [2611] phi from display_print_chip::@2 to display_chip_line [phi:display_print_chip::@2->display_chip_line]
    // [2611] phi display_chip_line::c#15 = display_chip_line::c#2 [phi:display_print_chip::@2->display_chip_line#0] -- register_copy 
    // [2611] phi display_chip_line::w#10 = display_chip_line::w#2 [phi:display_print_chip::@2->display_chip_line#1] -- register_copy 
    // [2611] phi display_chip_line::y#16 = ++++3+2 [phi:display_print_chip::@2->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1
    sta.z display_chip_line.y
    // [2611] phi display_chip_line::x#16 = display_chip_line::x#2 [phi:display_print_chip::@2->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@3
    // display_chip_line(x, y++, w, *text++);
    // [2068] display_print_chip::text#15 = ++ display_print_chip::text#1 -- pbum1=_inc_pbum2 
    clc
    lda text_1
    adc #1
    sta text_3
    lda text_1+1
    adc #0
    sta text_3+1
    // display_chip_line(x, y++, w, *text++)
    // [2069] display_chip_line::x#3 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [2070] display_chip_line::w#3 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [2071] display_chip_line::c#3 = *display_print_chip::text#15 -- vbuz1=_deref_pbum2 
    ldy text_3
    sty.z $fe
    ldy text_3+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta.z display_chip_line.c
    // [2072] call display_chip_line
    // [2611] phi from display_print_chip::@3 to display_chip_line [phi:display_print_chip::@3->display_chip_line]
    // [2611] phi display_chip_line::c#15 = display_chip_line::c#3 [phi:display_print_chip::@3->display_chip_line#0] -- register_copy 
    // [2611] phi display_chip_line::w#10 = display_chip_line::w#3 [phi:display_print_chip::@3->display_chip_line#1] -- register_copy 
    // [2611] phi display_chip_line::y#16 = ++++++3+2 [phi:display_print_chip::@3->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1
    sta.z display_chip_line.y
    // [2611] phi display_chip_line::x#16 = display_chip_line::x#3 [phi:display_print_chip::@3->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@4
    // display_chip_line(x, y++, w, *text++);
    // [2073] display_print_chip::text#16 = ++ display_print_chip::text#15 -- pbum1=_inc_pbum2 
    clc
    lda text_3
    adc #1
    sta text_4
    lda text_3+1
    adc #0
    sta text_4+1
    // display_chip_line(x, y++, w, *text++)
    // [2074] display_chip_line::x#4 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [2075] display_chip_line::w#4 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [2076] display_chip_line::c#4 = *display_print_chip::text#16 -- vbuz1=_deref_pbum2 
    ldy text_4
    sty.z $fe
    ldy text_4+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta.z display_chip_line.c
    // [2077] call display_chip_line
    // [2611] phi from display_print_chip::@4 to display_chip_line [phi:display_print_chip::@4->display_chip_line]
    // [2611] phi display_chip_line::c#15 = display_chip_line::c#4 [phi:display_print_chip::@4->display_chip_line#0] -- register_copy 
    // [2611] phi display_chip_line::w#10 = display_chip_line::w#4 [phi:display_print_chip::@4->display_chip_line#1] -- register_copy 
    // [2611] phi display_chip_line::y#16 = ++++++++3+2 [phi:display_print_chip::@4->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1
    sta.z display_chip_line.y
    // [2611] phi display_chip_line::x#16 = display_chip_line::x#4 [phi:display_print_chip::@4->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@5
    // display_chip_line(x, y++, w, *text++);
    // [2078] display_print_chip::text#17 = ++ display_print_chip::text#16 -- pbuz1=_inc_pbum2 
    clc
    lda text_4
    adc #1
    sta.z text_5
    lda text_4+1
    adc #0
    sta.z text_5+1
    // display_chip_line(x, y++, w, *text++)
    // [2079] display_chip_line::x#5 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [2080] display_chip_line::w#5 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [2081] display_chip_line::c#5 = *display_print_chip::text#17 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_5),y
    sta.z display_chip_line.c
    // [2082] call display_chip_line
    // [2611] phi from display_print_chip::@5 to display_chip_line [phi:display_print_chip::@5->display_chip_line]
    // [2611] phi display_chip_line::c#15 = display_chip_line::c#5 [phi:display_print_chip::@5->display_chip_line#0] -- register_copy 
    // [2611] phi display_chip_line::w#10 = display_chip_line::w#5 [phi:display_print_chip::@5->display_chip_line#1] -- register_copy 
    // [2611] phi display_chip_line::y#16 = ++++++++++3+2 [phi:display_print_chip::@5->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1+1
    sta.z display_chip_line.y
    // [2611] phi display_chip_line::x#16 = display_chip_line::x#5 [phi:display_print_chip::@5->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@6
    // display_chip_line(x, y++, w, *text++);
    // [2083] display_print_chip::text#18 = ++ display_print_chip::text#17 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_5
    adc #1
    sta.z text_6
    lda.z text_5+1
    adc #0
    sta.z text_6+1
    // display_chip_line(x, y++, w, *text++)
    // [2084] display_chip_line::x#6 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [2085] display_chip_line::w#6 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [2086] display_chip_line::c#6 = *display_print_chip::text#18 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta.z display_chip_line.c
    // [2087] call display_chip_line
    // [2611] phi from display_print_chip::@6 to display_chip_line [phi:display_print_chip::@6->display_chip_line]
    // [2611] phi display_chip_line::c#15 = display_chip_line::c#6 [phi:display_print_chip::@6->display_chip_line#0] -- register_copy 
    // [2611] phi display_chip_line::w#10 = display_chip_line::w#6 [phi:display_print_chip::@6->display_chip_line#1] -- register_copy 
    // [2611] phi display_chip_line::y#16 = ++++++++++++3+2 [phi:display_print_chip::@6->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1+1+1
    sta.z display_chip_line.y
    // [2611] phi display_chip_line::x#16 = display_chip_line::x#6 [phi:display_print_chip::@6->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@7
    // display_chip_line(x, y++, w, *text++);
    // [2088] display_print_chip::text#19 = ++ display_print_chip::text#18 -- pbuz1=_inc_pbuz1 
    inc.z text_6
    bne !+
    inc.z text_6+1
  !:
    // display_chip_line(x, y++, w, *text++)
    // [2089] display_chip_line::x#7 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [2090] display_chip_line::w#7 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [2091] display_chip_line::c#7 = *display_print_chip::text#19 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta.z display_chip_line.c
    // [2092] call display_chip_line
    // [2611] phi from display_print_chip::@7 to display_chip_line [phi:display_print_chip::@7->display_chip_line]
    // [2611] phi display_chip_line::c#15 = display_chip_line::c#7 [phi:display_print_chip::@7->display_chip_line#0] -- register_copy 
    // [2611] phi display_chip_line::w#10 = display_chip_line::w#7 [phi:display_print_chip::@7->display_chip_line#1] -- register_copy 
    // [2611] phi display_chip_line::y#16 = ++++++++++++++3+2 [phi:display_print_chip::@7->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1+1+1+1
    sta.z display_chip_line.y
    // [2611] phi display_chip_line::x#16 = display_chip_line::x#7 [phi:display_print_chip::@7->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@8
    // display_chip_end(x, y++, w)
    // [2093] display_chip_end::x#0 = display_print_chip::x#10
    // [2094] display_chip_end::w#0 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_end.w
    // [2095] call display_chip_end
    jsr display_chip_end
    // display_print_chip::@return
    // }
    // [2096] return 
    rts
  .segment Data
    .label text_1 = fopen.fopen__28
    .label text_2 = strcat.src
    .label text_3 = fopen.fopen__11
    .label text_4 = ferror.return
}
.segment Code
  // display_vera_led
/**
 * @brief Print VERA led above the VERA chip.
 * 
 * @param c Led color
 */
// void display_vera_led(__zp($bf) char c)
display_vera_led: {
    .label c = $bf
    // display_chip_led(CHIP_VERA_X+1, CHIP_VERA_Y, CHIP_VERA_W, c, BLUE)
    // [2098] display_chip_led::tc#1 = display_vera_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_chip_led.tc
    // [2099] call display_chip_led
    // [2593] phi from display_vera_led to display_chip_led [phi:display_vera_led->display_chip_led]
    // [2593] phi display_chip_led::w#7 = 8 [phi:display_vera_led->display_chip_led#0] -- vbuz1=vbuc1 
    lda #8
    sta.z display_chip_led.w
    // [2593] phi display_chip_led::x#7 = 9+1 [phi:display_vera_led->display_chip_led#1] -- vbuz1=vbuc1 
    lda #9+1
    sta.z display_chip_led.x
    // [2593] phi display_chip_led::tc#3 = display_chip_led::tc#1 [phi:display_vera_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_vera_led::@1
    // display_info_led(INFO_X-2, INFO_Y+1, c, BLUE)
    // [2100] display_info_led::tc#1 = display_vera_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_info_led.tc
    // [2101] call display_info_led
    // [1799] phi from display_vera_led::@1 to display_info_led [phi:display_vera_led::@1->display_info_led]
    // [1799] phi display_info_led::y#4 = $11+1 [phi:display_vera_led::@1->display_info_led#0] -- vbuz1=vbuc1 
    lda #$11+1
    sta.z display_info_led.y
    // [1799] phi display_info_led::x#4 = 4-2 [phi:display_vera_led::@1->display_info_led#1] -- vbuz1=vbuc1 
    lda #4-2
    sta.z display_info_led.x
    // [1799] phi display_info_led::tc#4 = display_info_led::tc#1 [phi:display_vera_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_vera_led::@return
    // }
    // [2102] return 
    rts
}
  // strcat
// Concatenates the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcat(char *destination, __mem() char *source)
strcat: {
    .label strcat__0 = $55
    .label dst = $55
    // strlen(destination)
    // [2104] call strlen
    // [2315] phi from strcat to strlen [phi:strcat->strlen]
    // [2315] phi strlen::str#8 = display_chip_rom::rom [phi:strcat->strlen#0] -- pbuz1=pbuc1 
    lda #<display_chip_rom.rom
    sta.z strlen.str
    lda #>display_chip_rom.rom
    sta.z strlen.str+1
    jsr strlen
    // strlen(destination)
    // [2105] strlen::return#0 = strlen::len#2
    // strcat::@4
    // [2106] strcat::$0 = strlen::return#0
    // char* dst = destination + strlen(destination)
    // [2107] strcat::dst#0 = display_chip_rom::rom + strcat::$0 -- pbuz1=pbuc1_plus_vwuz1 
    lda.z dst
    clc
    adc #<display_chip_rom.rom
    sta.z dst
    lda.z dst+1
    adc #>display_chip_rom.rom
    sta.z dst+1
    // [2108] phi from strcat::@2 strcat::@4 to strcat::@1 [phi:strcat::@2/strcat::@4->strcat::@1]
    // [2108] phi strcat::dst#2 = strcat::dst#1 [phi:strcat::@2/strcat::@4->strcat::@1#0] -- register_copy 
    // [2108] phi strcat::src#2 = strcat::src#1 [phi:strcat::@2/strcat::@4->strcat::@1#1] -- register_copy 
    // strcat::@1
  __b1:
    // while(*src)
    // [2109] if(0!=*strcat::src#2) goto strcat::@2 -- 0_neq__deref_pbum1_then_la1 
    ldy src
    sty.z $fe
    ldy src+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    cmp #0
    bne __b2
    // strcat::@3
    // *dst = 0
    // [2110] *strcat::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcat::@return
    // }
    // [2111] return 
    rts
    // strcat::@2
  __b2:
    // *dst++ = *src++
    // [2112] *strcat::dst#2 = *strcat::src#2 -- _deref_pbuz1=_deref_pbum2 
    ldy src
    sty.z $fe
    ldy src+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta (dst),y
    // *dst++ = *src++;
    // [2113] strcat::dst#1 = ++ strcat::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [2114] strcat::src#1 = ++ strcat::src#2 -- pbum1=_inc_pbum1 
    inc src
    bne !+
    inc src+1
  !:
    jmp __b1
  .segment Data
    src: .word 0
    .label source = src
}
.segment Code
  // display_rom_led
/**
 * @brief Print ROM led above the ROM chip.
 * 
 * @param chip ROM chip number (0 is main rom chip of CX16)
 * @param c Led color
 */
// void display_rom_led(__zp($68) char chip, __zp($72) char c)
display_rom_led: {
    .label display_rom_led__0 = $5c
    .label chip = $68
    .label c = $72
    .label display_rom_led__7 = $5c
    .label display_rom_led__8 = $5c
    // chip*6
    // [2116] display_rom_led::$7 = display_rom_led::chip#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z chip
    asl
    sta.z display_rom_led__7
    // [2117] display_rom_led::$8 = display_rom_led::$7 + display_rom_led::chip#2 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z display_rom_led__8
    clc
    adc.z chip
    sta.z display_rom_led__8
    // CHIP_ROM_X+chip*6
    // [2118] display_rom_led::$0 = display_rom_led::$8 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_rom_led__0
    // display_chip_led(CHIP_ROM_X+chip*6+1, CHIP_ROM_Y, CHIP_ROM_W, c, BLUE)
    // [2119] display_chip_led::x#3 = display_rom_led::$0 + $14+1 -- vbuz1=vbuz1_plus_vbuc1 
    lda #$14+1
    clc
    adc.z display_chip_led.x
    sta.z display_chip_led.x
    // [2120] display_chip_led::tc#2 = display_rom_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_chip_led.tc
    // [2121] call display_chip_led
    // [2593] phi from display_rom_led to display_chip_led [phi:display_rom_led->display_chip_led]
    // [2593] phi display_chip_led::w#7 = 3 [phi:display_rom_led->display_chip_led#0] -- vbuz1=vbuc1 
    lda #3
    sta.z display_chip_led.w
    // [2593] phi display_chip_led::x#7 = display_chip_led::x#3 [phi:display_rom_led->display_chip_led#1] -- register_copy 
    // [2593] phi display_chip_led::tc#3 = display_chip_led::tc#2 [phi:display_rom_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_rom_led::@1
    // display_info_led(INFO_X-2, INFO_Y+chip+2, c, BLUE)
    // [2122] display_info_led::y#2 = display_rom_led::chip#2 + $11+2 -- vbuz1=vbuz2_plus_vbuc1 
    lda #$11+2
    clc
    adc.z chip
    sta.z display_info_led.y
    // [2123] display_info_led::tc#2 = display_rom_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_info_led.tc
    // [2124] call display_info_led
    // [1799] phi from display_rom_led::@1 to display_info_led [phi:display_rom_led::@1->display_info_led]
    // [1799] phi display_info_led::y#4 = display_info_led::y#2 [phi:display_rom_led::@1->display_info_led#0] -- register_copy 
    // [1799] phi display_info_led::x#4 = 4-2 [phi:display_rom_led::@1->display_info_led#1] -- vbuz1=vbuc1 
    lda #4-2
    sta.z display_info_led.x
    // [1799] phi display_info_led::tc#4 = display_info_led::tc#2 [phi:display_rom_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_rom_led::@return
    // }
    // [2125] return 
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
// void rom_unlock(__zp($78) unsigned long address, __zp($b1) char unlock_code)
rom_unlock: {
    .label chip_address = $41
    .label address = $78
    .label unlock_code = $b1
    // unsigned long chip_address = address & ROM_CHIP_MASK
    // [2127] rom_unlock::chip_address#0 = rom_unlock::address#5 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [2128] rom_write_byte::address#0 = rom_unlock::chip_address#0 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [2129] call rom_write_byte
  // This is a very important operation...
    // [2672] phi from rom_unlock to rom_write_byte [phi:rom_unlock->rom_write_byte]
    // [2672] phi rom_write_byte::value#10 = $aa [phi:rom_unlock->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$aa
    sta.z rom_write_byte.value
    // [2672] phi rom_write_byte::address#4 = rom_write_byte::address#0 [phi:rom_unlock->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@1
    // rom_write_byte(chip_address + 0x02AAA, 0x55)
    // [2130] rom_write_byte::address#1 = rom_unlock::chip_address#0 + $2aaa -- vduz1=vduz2_plus_vwuc1 
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
    // [2131] call rom_write_byte
    // [2672] phi from rom_unlock::@1 to rom_write_byte [phi:rom_unlock::@1->rom_write_byte]
    // [2672] phi rom_write_byte::value#10 = $55 [phi:rom_unlock::@1->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$55
    sta.z rom_write_byte.value
    // [2672] phi rom_write_byte::address#4 = rom_write_byte::address#1 [phi:rom_unlock::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@2
    // rom_write_byte(address, unlock_code)
    // [2132] rom_write_byte::address#2 = rom_unlock::address#5 -- vduz1=vduz2 
    lda.z address
    sta.z rom_write_byte.address
    lda.z address+1
    sta.z rom_write_byte.address+1
    lda.z address+2
    sta.z rom_write_byte.address+2
    lda.z address+3
    sta.z rom_write_byte.address+3
    // [2133] rom_write_byte::value#2 = rom_unlock::unlock_code#5 -- vbuz1=vbuz2 
    lda.z unlock_code
    sta.z rom_write_byte.value
    // [2134] call rom_write_byte
    // [2672] phi from rom_unlock::@2 to rom_write_byte [phi:rom_unlock::@2->rom_write_byte]
    // [2672] phi rom_write_byte::value#10 = rom_write_byte::value#2 [phi:rom_unlock::@2->rom_write_byte#0] -- register_copy 
    // [2672] phi rom_write_byte::address#4 = rom_write_byte::address#2 [phi:rom_unlock::@2->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@return
    // }
    // [2135] return 
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
// __zp($6d) char rom_read_byte(__zp($57) unsigned long address)
rom_read_byte: {
    .label rom_bank1_rom_read_byte__0 = $36
    .label rom_bank1_rom_read_byte__1 = $f4
    .label rom_bank1_rom_read_byte__2 = $d7
    .label rom_ptr1_rom_read_byte__0 = $55
    .label rom_ptr1_rom_read_byte__2 = $55
    .label rom_bank1_bank_unshifted = $d7
    .label rom_ptr1_return = $55
    .label return = $6d
    .label address = $57
    // rom_read_byte::rom_bank1
    // BYTE2(address)
    // [2137] rom_read_byte::rom_bank1_$0 = byte2  rom_read_byte::address#2 -- vbuz1=_byte2_vduz2 
    lda.z address+2
    sta.z rom_bank1_rom_read_byte__0
    // BYTE1(address)
    // [2138] rom_read_byte::rom_bank1_$1 = byte1  rom_read_byte::address#2 -- vbuz1=_byte1_vduz2 
    lda.z address+1
    sta.z rom_bank1_rom_read_byte__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2139] rom_read_byte::rom_bank1_$2 = rom_read_byte::rom_bank1_$0 w= rom_read_byte::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_read_byte__0
    sta.z rom_bank1_rom_read_byte__2+1
    lda.z rom_bank1_rom_read_byte__1
    sta.z rom_bank1_rom_read_byte__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2140] rom_read_byte::rom_bank1_bank_unshifted#0 = rom_read_byte::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2141] rom_read_byte::rom_bank1_return#0 = byte1  rom_read_byte::rom_bank1_bank_unshifted#0 -- vbum1=_byte1_vwuz2 
    lda.z rom_bank1_bank_unshifted+1
    sta rom_bank1_return
    // rom_read_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2142] rom_read_byte::rom_ptr1_$2 = (unsigned int)rom_read_byte::address#2 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_read_byte__2
    lda.z address+1
    sta.z rom_ptr1_rom_read_byte__2+1
    // [2143] rom_read_byte::rom_ptr1_$0 = rom_read_byte::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_read_byte__0
    and #<$3fff
    sta.z rom_ptr1_rom_read_byte__0
    lda.z rom_ptr1_rom_read_byte__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_read_byte__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2144] rom_read_byte::rom_ptr1_return#0 = rom_read_byte::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_read_byte::bank_set_brom1
    // BROM = bank
    // [2145] BROM = rom_read_byte::rom_bank1_return#0 -- vbuz1=vbum2 
    lda rom_bank1_return
    sta.z BROM
    // rom_read_byte::@1
    // return *ptr_rom;
    // [2146] rom_read_byte::return#0 = *((char *)rom_read_byte::rom_ptr1_return#0) -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (rom_ptr1_return),y
    sta.z return
    // rom_read_byte::@return
    // }
    // [2147] return 
    rts
  .segment Data
    .label rom_bank1_return = fopen.fopen__4
}
.segment Code
  // display_progress_line
/**
 * @brief Print one line of text in the progress frame at a line position.
 * 
 * @param line The start line, counting from 0.
 * @param text The text to be displayed.
 */
// void display_progress_line(__zp($ea) char line, __zp($2d) char *text)
display_progress_line: {
    .label line = $ea
    .label text = $2d
    // cputsxy(PROGRESS_X, PROGRESS_Y+line, text)
    // [2148] cputsxy::y#0 = PROGRESS_Y + display_progress_line::line#0 -- vbuz1=vbuc1_plus_vbuz1 
    lda #PROGRESS_Y
    clc
    adc.z cputsxy.y
    sta.z cputsxy.y
    // [2149] cputsxy::s#0 = display_progress_line::text#0
    // [2150] call cputsxy
    // [843] phi from display_progress_line to cputsxy [phi:display_progress_line->cputsxy]
    // [843] phi cputsxy::s#4 = cputsxy::s#0 [phi:display_progress_line->cputsxy#0] -- register_copy 
    // [843] phi cputsxy::y#4 = cputsxy::y#0 [phi:display_progress_line->cputsxy#1] -- register_copy 
    // [843] phi cputsxy::x#4 = PROGRESS_X [phi:display_progress_line->cputsxy#2] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z cputsxy.x
    jsr cputsxy
    // display_progress_line::@return
    // }
    // [2151] return 
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
// __zp($d7) struct $2 * fopen(__zp($db) const char *path, const char *mode)
fopen: {
    .label fopen__9 = $d6
    .label fopen__15 = $d3
    .label fopen__26 = $64
    .label fopen__30 = $d7
    .label cbm_k_setnam1_fopen__0 = $55
    .label sp = $36
    .label stream = $d7
    .label pathtoken = $db
    .label pathpos = $f4
    .label pathcmp = $bb
    .label path = $db
    .label cbm_k_readst1_return = $d3
    .label return = $d7
    // unsigned char sp = __stdio_filecount
    // [2153] fopen::sp#0 = __stdio_filecount -- vbuz1=vbum2 
    lda __stdio_filecount
    sta.z sp
    // (unsigned int)sp | 0x8000
    // [2154] fopen::$30 = (unsigned int)fopen::sp#0 -- vwuz1=_word_vbuz2 
    sta.z fopen__30
    lda #0
    sta.z fopen__30+1
    // [2155] fopen::stream#0 = fopen::$30 | $8000 -- vwuz1=vwuz1_bor_vwuc1 
    lda.z stream
    ora #<$8000
    sta.z stream
    lda.z stream+1
    ora #>$8000
    sta.z stream+1
    // char pathpos = sp * __STDIO_FILECOUNT
    // [2156] fopen::pathpos#0 = fopen::sp#0 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z sp
    asl
    sta.z pathpos
    // __logical = 0
    // [2157] ((char *)&__stdio_file+$40)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    ldy.z sp
    sta __stdio_file+$40,y
    // __device = 0
    // [2158] ((char *)&__stdio_file+$42)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [2159] ((char *)&__stdio_file+$44)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$44,y
    // [2160] fopen::pathtoken#22 = fopen::pathtoken#0 -- pbum1=pbuz2 
    lda.z pathtoken
    sta pathtoken_1
    lda.z pathtoken+1
    sta pathtoken_1+1
    // [2161] fopen::pathpos#21 = fopen::pathpos#0 -- vbum1=vbuz2 
    lda.z pathpos
    sta pathpos_1
    // [2162] phi from fopen to fopen::@8 [phi:fopen->fopen::@8]
    // [2162] phi fopen::num#10 = 0 [phi:fopen->fopen::@8#0] -- vbum1=vbuc1 
    lda #0
    sta num
    // [2162] phi fopen::pathpos#10 = fopen::pathpos#21 [phi:fopen->fopen::@8#1] -- register_copy 
    // [2162] phi fopen::path#10 = fopen::pathtoken#0 [phi:fopen->fopen::@8#2] -- register_copy 
    // [2162] phi fopen::pathstep#10 = 0 [phi:fopen->fopen::@8#3] -- vbum1=vbuc1 
    sta pathstep
    // [2162] phi fopen::pathtoken#10 = fopen::pathtoken#22 [phi:fopen->fopen::@8#4] -- register_copy 
  // Iterate while path is not \0.
    // [2162] phi from fopen::@22 to fopen::@8 [phi:fopen::@22->fopen::@8]
    // [2162] phi fopen::num#10 = fopen::num#13 [phi:fopen::@22->fopen::@8#0] -- register_copy 
    // [2162] phi fopen::pathpos#10 = fopen::pathpos#7 [phi:fopen::@22->fopen::@8#1] -- register_copy 
    // [2162] phi fopen::path#10 = fopen::path#11 [phi:fopen::@22->fopen::@8#2] -- register_copy 
    // [2162] phi fopen::pathstep#10 = fopen::pathstep#11 [phi:fopen::@22->fopen::@8#3] -- register_copy 
    // [2162] phi fopen::pathtoken#10 = fopen::pathtoken#1 [phi:fopen::@22->fopen::@8#4] -- register_copy 
    // fopen::@8
  __b8:
    // if (*pathtoken == ',' || *pathtoken == '\0')
    // [2163] if(*fopen::pathtoken#10==',') goto fopen::@9 -- _deref_pbum1_eq_vbuc1_then_la1 
    ldy pathtoken_1
    sty.z $fe
    ldy pathtoken_1+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    cmp #','
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@33
    // [2164] if(*fopen::pathtoken#10=='@') goto fopen::@9 -- _deref_pbum1_eq_vbuc1_then_la1 
    ldy pathtoken_1
    sty.z $fe
    ldy pathtoken_1+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    cmp #'@'
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@23
    // if (pathstep == 0)
    // [2165] if(fopen::pathstep#10!=0) goto fopen::@10 -- vbum1_neq_0_then_la1 
    lda pathstep
    bne __b10
    // fopen::@24
    // __stdio_file.filename[pathpos] = *pathtoken
    // [2166] ((char *)&__stdio_file)[fopen::pathpos#10] = *fopen::pathtoken#10 -- pbuc1_derefidx_vbum1=_deref_pbum2 
    ldy pathtoken_1
    sty.z $fe
    ldy pathtoken_1+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    ldy pathpos_1
    sta __stdio_file,y
    // pathpos++;
    // [2167] fopen::pathpos#1 = ++ fopen::pathpos#10 -- vbum1=_inc_vbum1 
    inc pathpos_1
    // [2168] phi from fopen::@12 fopen::@23 fopen::@24 to fopen::@10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10]
    // [2168] phi fopen::num#13 = fopen::num#15 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#0] -- register_copy 
    // [2168] phi fopen::pathpos#7 = fopen::pathpos#10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#1] -- register_copy 
    // [2168] phi fopen::path#11 = fopen::path#13 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#2] -- register_copy 
    // [2168] phi fopen::pathstep#11 = fopen::pathstep#1 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#3] -- register_copy 
    // fopen::@10
  __b10:
    // pathtoken++;
    // [2169] fopen::pathtoken#1 = ++ fopen::pathtoken#10 -- pbum1=_inc_pbum1 
    inc pathtoken_1
    bne !+
    inc pathtoken_1+1
  !:
    // fopen::@22
    // pathtoken - 1
    // [2170] fopen::$28 = fopen::pathtoken#1 - 1 -- pbum1=pbum2_minus_1 
    lda pathtoken_1
    sec
    sbc #1
    sta fopen__28
    lda pathtoken_1+1
    sbc #0
    sta fopen__28+1
    // while (*(pathtoken - 1))
    // [2171] if(0!=*fopen::$28) goto fopen::@8 -- 0_neq__deref_pbum1_then_la1 
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
    // [2172] ((char *)&__stdio_file+$46)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    tya
    ldy.z sp
    sta __stdio_file+$46,y
    // if(!__logical)
    // [2173] if(0!=((char *)&__stdio_file+$40)[fopen::sp#0]) goto fopen::@1 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$40,y
    cmp #0
    bne __b1
    // fopen::@27
    // __stdio_filecount+1
    // [2174] fopen::$4 = __stdio_filecount + 1 -- vbum1=vbum2_plus_1 
    lda __stdio_filecount
    inc
    sta fopen__4
    // __logical = __stdio_filecount+1
    // [2175] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::$4 -- pbuc1_derefidx_vbuz1=vbum2 
    sta __stdio_file+$40,y
    // fopen::@1
  __b1:
    // if(!__device)
    // [2176] if(0!=((char *)&__stdio_file+$42)[fopen::sp#0]) goto fopen::@2 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    ldy.z sp
    lda __stdio_file+$42,y
    cmp #0
    bne __b2
    // fopen::@5
    // __device = 8
    // [2177] ((char *)&__stdio_file+$42)[fopen::sp#0] = 8 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #8
    sta __stdio_file+$42,y
    // fopen::@2
  __b2:
    // if(!__channel)
    // [2178] if(0!=((char *)&__stdio_file+$44)[fopen::sp#0]) goto fopen::@3 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    ldy.z sp
    lda __stdio_file+$44,y
    cmp #0
    bne __b3
    // fopen::@6
    // __stdio_filecount+2
    // [2179] fopen::$9 = __stdio_filecount + 2 -- vbuz1=vbum2_plus_2 
    lda __stdio_filecount
    clc
    adc #2
    sta.z fopen__9
    // __channel = __stdio_filecount+2
    // [2180] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::$9 -- pbuc1_derefidx_vbuz1=vbuz2 
    sta __stdio_file+$44,y
    // fopen::@3
  __b3:
    // __filename
    // [2181] fopen::$11 = (char *)&__stdio_file + fopen::pathpos#0 -- pbum1=pbuc1_plus_vbuz2 
    lda.z pathpos
    clc
    adc #<__stdio_file
    sta fopen__11
    lda #>__stdio_file
    adc #0
    sta fopen__11+1
    // cbm_k_setnam(__filename)
    // [2182] fopen::cbm_k_setnam1_filename = fopen::$11 -- pbum1=pbum2 
    lda fopen__11
    sta cbm_k_setnam1_filename
    lda fopen__11+1
    sta cbm_k_setnam1_filename+1
    // fopen::cbm_k_setnam1
    // strlen(filename)
    // [2183] strlen::str#4 = fopen::cbm_k_setnam1_filename -- pbuz1=pbum2 
    lda cbm_k_setnam1_filename
    sta.z strlen.str
    lda cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [2184] call strlen
    // [2315] phi from fopen::cbm_k_setnam1 to strlen [phi:fopen::cbm_k_setnam1->strlen]
    // [2315] phi strlen::str#8 = strlen::str#4 [phi:fopen::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [2185] strlen::return#11 = strlen::len#2
    // fopen::@31
    // [2186] fopen::cbm_k_setnam1_$0 = strlen::return#11
    // char filename_len = (char)strlen(filename)
    // [2187] fopen::cbm_k_setnam1_filename_len = (char)fopen::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
    lda.z cbm_k_setnam1_fopen__0
    sta cbm_k_setnam1_filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx cbm_k_setnam1_filename
    ldy cbm_k_setnam1_filename+1
    jsr CBM_SETNAM
    // fopen::@28
    // cbm_k_setlfs(__logical, __device, __channel)
    // [2189] cbm_k_setlfs::channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$40,y
    sta cbm_k_setlfs.channel
    // [2190] cbm_k_setlfs::device = ((char *)&__stdio_file+$42)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    lda __stdio_file+$42,y
    sta cbm_k_setlfs.device
    // [2191] cbm_k_setlfs::command = ((char *)&__stdio_file+$44)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    lda __stdio_file+$44,y
    sta cbm_k_setlfs.command
    // [2192] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // fopen::cbm_k_open1
    // asm
    // asm { jsrCBM_OPEN  }
    jsr CBM_OPEN
    // fopen::cbm_k_readst1
    // char status
    // [2194] fopen::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2196] fopen::cbm_k_readst1_return#0 = fopen::cbm_k_readst1_status -- vbuz1=vbum2 
    sta.z cbm_k_readst1_return
    // fopen::cbm_k_readst1_@return
    // }
    // [2197] fopen::cbm_k_readst1_return#1 = fopen::cbm_k_readst1_return#0
    // fopen::@29
    // cbm_k_readst()
    // [2198] fopen::$15 = fopen::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [2199] ((char *)&__stdio_file+$46)[fopen::sp#0] = fopen::$15 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fopen__15
    ldy.z sp
    sta __stdio_file+$46,y
    // ferror(stream)
    // [2200] ferror::stream#0 = (struct $2 *)fopen::stream#0
    // [2201] call ferror
    jsr ferror
    // [2202] ferror::return#0 = ferror::return#1
    // fopen::@32
    // [2203] fopen::$16 = ferror::return#0
    // if (ferror(stream))
    // [2204] if(0==fopen::$16) goto fopen::@4 -- 0_eq_vwsm1_then_la1 
    lda fopen__16
    ora fopen__16+1
    beq __b4
    // fopen::@7
    // cbm_k_close(__logical)
    // [2205] fopen::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$40,y
    sta cbm_k_close1_channel
    // fopen::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // [2207] phi from fopen::cbm_k_close1 to fopen::@return [phi:fopen::cbm_k_close1->fopen::@return]
    // [2207] phi fopen::return#2 = 0 [phi:fopen::cbm_k_close1->fopen::@return#0] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fopen::@return
    // }
    // [2208] return 
    rts
    // fopen::@4
  __b4:
    // __stdio_filecount++;
    // [2209] __stdio_filecount = ++ __stdio_filecount -- vbum1=_inc_vbum1 
    inc __stdio_filecount
    // [2210] fopen::return#8 = (struct $2 *)fopen::stream#0
    // [2207] phi from fopen::@4 to fopen::@return [phi:fopen::@4->fopen::@return]
    // [2207] phi fopen::return#2 = fopen::return#8 [phi:fopen::@4->fopen::@return#0] -- register_copy 
    rts
    // fopen::@9
  __b9:
    // if (pathstep > 0)
    // [2211] if(fopen::pathstep#10>0) goto fopen::@11 -- vbum1_gt_0_then_la1 
    lda pathstep
    bne __b11
    // fopen::@25
    // __stdio_file.filename[pathpos] = '\0'
    // [2212] ((char *)&__stdio_file)[fopen::pathpos#10] = '@' -- pbuc1_derefidx_vbum1=vbuc2 
    lda #'@'
    ldy pathpos_1
    sta __stdio_file,y
    // path = pathtoken + 1
    // [2213] fopen::path#0 = fopen::pathtoken#10 + 1 -- pbuz1=pbum2_plus_1 
    clc
    lda pathtoken_1
    adc #1
    sta.z path
    lda pathtoken_1+1
    adc #0
    sta.z path+1
    // [2214] phi from fopen::@16 fopen::@17 fopen::@18 fopen::@19 fopen::@25 to fopen::@12 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12]
    // [2214] phi fopen::num#15 = fopen::num#2 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#0] -- register_copy 
    // [2214] phi fopen::path#13 = fopen::path#16 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#1] -- register_copy 
    // fopen::@12
  __b12:
    // pathstep++;
    // [2215] fopen::pathstep#1 = ++ fopen::pathstep#10 -- vbum1=_inc_vbum1 
    inc pathstep
    jmp __b10
    // fopen::@11
  __b11:
    // char pathcmp = *path
    // [2216] fopen::pathcmp#0 = *fopen::path#10 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (path),y
    sta.z pathcmp
    // case 'D':
    // [2217] if(fopen::pathcmp#0=='D') goto fopen::@13 -- vbuz1_eq_vbuc1_then_la1 
    lda #'D'
    cmp.z pathcmp
    beq __b13
    // fopen::@20
    // case 'L':
    // [2218] if(fopen::pathcmp#0=='L') goto fopen::@13 -- vbuz1_eq_vbuc1_then_la1 
    lda #'L'
    cmp.z pathcmp
    beq __b13
    // fopen::@21
    // case 'C':
    //                     num = (char)atoi(path + 1);
    //                     path = pathtoken + 1;
    // [2219] if(fopen::pathcmp#0=='C') goto fopen::@13 -- vbuz1_eq_vbuc1_then_la1 
    lda #'C'
    cmp.z pathcmp
    beq __b13
    // [2220] phi from fopen::@21 fopen::@30 to fopen::@14 [phi:fopen::@21/fopen::@30->fopen::@14]
    // [2220] phi fopen::path#16 = fopen::path#10 [phi:fopen::@21/fopen::@30->fopen::@14#0] -- register_copy 
    // [2220] phi fopen::num#2 = fopen::num#10 [phi:fopen::@21/fopen::@30->fopen::@14#1] -- register_copy 
    // fopen::@14
  __b14:
    // case 'L':
    //                     __logical = num;
    //                     break;
    // [2221] if(fopen::pathcmp#0=='L') goto fopen::@17 -- vbuz1_eq_vbuc1_then_la1 
    lda #'L'
    cmp.z pathcmp
    beq __b17
    // fopen::@15
    // case 'D':
    //                     __device = num;
    //                     break;
    // [2222] if(fopen::pathcmp#0=='D') goto fopen::@18 -- vbuz1_eq_vbuc1_then_la1 
    lda #'D'
    cmp.z pathcmp
    beq __b18
    // fopen::@16
    // case 'C':
    //                     __channel = num;
    //                     break;
    // [2223] if(fopen::pathcmp#0!='C') goto fopen::@12 -- vbuz1_neq_vbuc1_then_la1 
    lda #'C'
    cmp.z pathcmp
    bne __b12
    // fopen::@19
    // __channel = num
    // [2224] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbum2 
    lda num
    ldy.z sp
    sta __stdio_file+$44,y
    jmp __b12
    // fopen::@18
  __b18:
    // __device = num
    // [2225] ((char *)&__stdio_file+$42)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbum2 
    lda num
    ldy.z sp
    sta __stdio_file+$42,y
    jmp __b12
    // fopen::@17
  __b17:
    // __logical = num
    // [2226] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbum2 
    lda num
    ldy.z sp
    sta __stdio_file+$40,y
    jmp __b12
    // fopen::@13
  __b13:
    // atoi(path + 1)
    // [2227] atoi::str#0 = fopen::path#10 + 1 -- pbuz1=pbuz1_plus_1 
    inc.z atoi.str
    bne !+
    inc.z atoi.str+1
  !:
    // [2228] call atoi
    // [2738] phi from fopen::@13 to atoi [phi:fopen::@13->atoi]
    // [2738] phi atoi::str#2 = atoi::str#0 [phi:fopen::@13->atoi#0] -- register_copy 
    jsr atoi
    // atoi(path + 1)
    // [2229] atoi::return#3 = atoi::return#2
    // fopen::@30
    // [2230] fopen::$26 = atoi::return#3
    // num = (char)atoi(path + 1)
    // [2231] fopen::num#1 = (char)fopen::$26 -- vbum1=_byte_vwsz2 
    lda.z fopen__26
    sta num
    // path = pathtoken + 1
    // [2232] fopen::path#1 = fopen::pathtoken#10 + 1 -- pbuz1=pbum2_plus_1 
    clc
    lda pathtoken_1
    adc #1
    sta.z path
    lda pathtoken_1+1
    adc #0
    sta.z path+1
    jmp __b14
  .segment Data
    fopen__4: .byte 0
    fopen__11: .word 0
    .label fopen__16 = ferror.return
    fopen__28: .word 0
    cbm_k_setnam1_filename: .word 0
    cbm_k_setnam1_filename_len: .byte 0
    cbm_k_readst1_status: .byte 0
    cbm_k_close1_channel: .byte 0
    .label pathpos_1 = main.check_status_smc12_main__0
    pathtoken_1: .word 0
    // Parse path
    .label pathstep = main.check_status_vera4_main__0
    .label num = main.check_status_vera5_main__0
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
// __zp($60) unsigned int fgets(__zp($c0) char *ptr, __zp($d9) unsigned int size, __mem() struct $2 *stream)
fgets: {
    .label fgets__1 = $d3
    .label fgets__8 = $bb
    .label fgets__9 = $c2
    .label fgets__13 = $c3
    .label cbm_k_chkin1_status = $f9
    .label cbm_k_readst1_status = $fa
    .label cbm_k_readst2_status = $c6
    .label sp = $d6
    .label cbm_k_readst1_return = $d3
    .label return = $60
    .label bytes = $7c
    .label cbm_k_readst2_return = $bb
    .label read = $60
    .label ptr = $c0
    .label remaining = $cd
    .label size = $d9
    // unsigned char sp = (unsigned char)stream
    // [2234] fgets::sp#0 = (char)fgets::stream#3 -- vbuz1=_byte_pssm2 
    lda stream
    sta.z sp
    // cbm_k_chkin(__logical)
    // [2235] fgets::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fgets::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    tay
    lda __stdio_file+$40,y
    sta cbm_k_chkin1_channel
    // fgets::cbm_k_chkin1
    // char status
    // [2236] fgets::cbm_k_chkin1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fgets::cbm_k_readst1
    // char status
    // [2238] fgets::cbm_k_readst1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2240] fgets::cbm_k_readst1_return#0 = fgets::cbm_k_readst1_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst1_return
    // fgets::cbm_k_readst1_@return
    // }
    // [2241] fgets::cbm_k_readst1_return#1 = fgets::cbm_k_readst1_return#0
    // fgets::@11
    // cbm_k_readst()
    // [2242] fgets::$1 = fgets::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [2243] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$1 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fgets__1
    ldy.z sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2244] if(0==((char *)&__stdio_file+$46)[fgets::sp#0]) goto fgets::@1 -- 0_eq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b1
    // [2245] phi from fgets::@11 fgets::@12 fgets::@5 to fgets::@return [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return]
  __b8:
    // [2245] phi fgets::return#1 = 0 [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return#0] -- vwuz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fgets::@return
    // }
    // [2246] return 
    rts
    // fgets::@1
  __b1:
    // [2247] fgets::remaining#22 = fgets::size#11 -- vwuz1=vwuz2 
    lda.z size
    sta.z remaining
    lda.z size+1
    sta.z remaining+1
    // [2248] phi from fgets::@1 to fgets::@2 [phi:fgets::@1->fgets::@2]
    // [2248] phi fgets::read#10 = 0 [phi:fgets::@1->fgets::@2#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z read
    sta.z read+1
    // [2248] phi fgets::remaining#11 = fgets::remaining#22 [phi:fgets::@1->fgets::@2#1] -- register_copy 
    // [2248] phi fgets::ptr#10 = fgets::ptr#13 [phi:fgets::@1->fgets::@2#2] -- register_copy 
    // [2248] phi from fgets::@17 fgets::@18 to fgets::@2 [phi:fgets::@17/fgets::@18->fgets::@2]
    // [2248] phi fgets::read#10 = fgets::read#1 [phi:fgets::@17/fgets::@18->fgets::@2#0] -- register_copy 
    // [2248] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@17/fgets::@18->fgets::@2#1] -- register_copy 
    // [2248] phi fgets::ptr#10 = fgets::ptr#14 [phi:fgets::@17/fgets::@18->fgets::@2#2] -- register_copy 
    // fgets::@2
  __b2:
    // if (!size)
    // [2249] if(0==fgets::size#11) goto fgets::@3 -- 0_eq_vwuz1_then_la1 
    lda.z size
    ora.z size+1
    bne !__b3+
    jmp __b3
  !__b3:
    // fgets::@8
    // if (remaining >= 512)
    // [2250] if(fgets::remaining#11>=$200) goto fgets::@4 -- vwuz1_ge_vwuc1_then_la1 
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
    // [2251] cx16_k_macptr::bytes = fgets::remaining#11 -- vbuz1=vwuz2 
    lda.z remaining
    sta.z cx16_k_macptr.bytes
    // [2252] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2253] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2254] cx16_k_macptr::return#4 = cx16_k_macptr::return#1
    // fgets::@15
  __b15:
    // bytes = cx16_k_macptr(remaining, ptr)
    // [2255] fgets::bytes#3 = cx16_k_macptr::return#4
    // [2256] phi from fgets::@13 fgets::@14 fgets::@15 to fgets::cbm_k_readst2 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2]
    // [2256] phi fgets::bytes#10 = fgets::bytes#1 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2#0] -- register_copy 
    // fgets::cbm_k_readst2
    // char status
    // [2257] fgets::cbm_k_readst2_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [2259] fgets::cbm_k_readst2_return#0 = fgets::cbm_k_readst2_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst2_return
    // fgets::cbm_k_readst2_@return
    // }
    // [2260] fgets::cbm_k_readst2_return#1 = fgets::cbm_k_readst2_return#0
    // fgets::@12
    // cbm_k_readst()
    // [2261] fgets::$8 = fgets::cbm_k_readst2_return#1
    // __status = cbm_k_readst()
    // [2262] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$8 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fgets__8
    ldy.z sp
    sta __stdio_file+$46,y
    // __status & 0xBF
    // [2263] fgets::$9 = ((char *)&__stdio_file+$46)[fgets::sp#0] & $bf -- vbuz1=pbuc1_derefidx_vbuz2_band_vbuc2 
    lda #$bf
    and __stdio_file+$46,y
    sta.z fgets__9
    // if (__status & 0xBF)
    // [2264] if(0==fgets::$9) goto fgets::@5 -- 0_eq_vbuz1_then_la1 
    beq __b5
    jmp __b8
    // fgets::@5
  __b5:
    // if (bytes == 0xFFFF)
    // [2265] if(fgets::bytes#10!=$ffff) goto fgets::@6 -- vwuz1_neq_vwuc1_then_la1 
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
    // [2266] fgets::read#1 = fgets::read#10 + fgets::bytes#10 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z read
    adc.z bytes
    sta.z read
    lda.z read+1
    adc.z bytes+1
    sta.z read+1
    // ptr += bytes
    // [2267] fgets::ptr#0 = fgets::ptr#10 + fgets::bytes#10 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z ptr
    adc.z bytes
    sta.z ptr
    lda.z ptr+1
    adc.z bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [2268] fgets::$13 = byte1  fgets::ptr#0 -- vbuz1=_byte1_pbuz2 
    sta.z fgets__13
    // if (BYTE1(ptr) == 0xC0)
    // [2269] if(fgets::$13!=$c0) goto fgets::@7 -- vbuz1_neq_vbuc1_then_la1 
    lda #$c0
    cmp.z fgets__13
    bne __b7
    // fgets::@10
    // ptr -= 0x2000
    // [2270] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [2271] phi from fgets::@10 fgets::@6 to fgets::@7 [phi:fgets::@10/fgets::@6->fgets::@7]
    // [2271] phi fgets::ptr#14 = fgets::ptr#1 [phi:fgets::@10/fgets::@6->fgets::@7#0] -- register_copy 
    // fgets::@7
  __b7:
    // remaining -= bytes
    // [2272] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#10 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z remaining
    sec
    sbc.z bytes
    sta.z remaining
    lda.z remaining+1
    sbc.z bytes+1
    sta.z remaining+1
    // while ((__status == 0) && ((size && remaining) || !size))
    // [2273] if(((char *)&__stdio_file+$46)[fgets::sp#0]==0) goto fgets::@16 -- pbuc1_derefidx_vbuz1_eq_0_then_la1 
    ldy.z sp
    lda __stdio_file+$46,y
    cmp #0
    beq __b16
    // [2245] phi from fgets::@17 fgets::@7 to fgets::@return [phi:fgets::@17/fgets::@7->fgets::@return]
    // [2245] phi fgets::return#1 = fgets::read#1 [phi:fgets::@17/fgets::@7->fgets::@return#0] -- register_copy 
    rts
    // fgets::@16
  __b16:
    // while ((__status == 0) && ((size && remaining) || !size))
    // [2274] if(0==fgets::size#11) goto fgets::@17 -- 0_eq_vwuz1_then_la1 
    lda.z size
    ora.z size+1
    beq __b17
    // fgets::@18
    // [2275] if(0!=fgets::remaining#1) goto fgets::@2 -- 0_neq_vwuz1_then_la1 
    lda.z remaining
    ora.z remaining+1
    beq !__b2+
    jmp __b2
  !__b2:
    // fgets::@17
  __b17:
    // [2276] if(0==fgets::size#11) goto fgets::@2 -- 0_eq_vwuz1_then_la1 
    lda.z size
    ora.z size+1
    bne !__b2+
    jmp __b2
  !__b2:
    rts
    // fgets::@4
  __b4:
    // cx16_k_macptr(512, ptr)
    // [2277] cx16_k_macptr::bytes = $200 -- vbuz1=vwuc1 
    lda #<$200
    sta.z cx16_k_macptr.bytes
    // [2278] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2279] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2280] cx16_k_macptr::return#3 = cx16_k_macptr::return#1
    // fgets::@14
    // bytes = cx16_k_macptr(512, ptr)
    // [2281] fgets::bytes#2 = cx16_k_macptr::return#3
    jmp __b15
    // fgets::@3
  __b3:
    // cx16_k_macptr(0, ptr)
    // [2282] cx16_k_macptr::bytes = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cx16_k_macptr.bytes
    // [2283] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2284] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2285] cx16_k_macptr::return#2 = cx16_k_macptr::return#1
    // fgets::@13
    // bytes = cx16_k_macptr(0, ptr)
    // [2286] fgets::bytes#1 = cx16_k_macptr::return#2
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
// int fclose(__zp($b2) struct $2 *stream)
fclose: {
    .label fclose__1 = $c3
    .label fclose__4 = $6c
    .label fclose__6 = $c2
    .label sp = $c2
    .label cbm_k_readst1_return = $c3
    .label cbm_k_readst2_return = $6c
    .label stream = $b2
    // unsigned char sp = (unsigned char)stream
    // [2288] fclose::sp#0 = (char)fclose::stream#2 -- vbuz1=_byte_pssz2 
    lda.z stream
    sta.z sp
    // cbm_k_chkin(__logical)
    // [2289] fclose::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    tay
    lda __stdio_file+$40,y
    sta cbm_k_chkin1_channel
    // fclose::cbm_k_chkin1
    // char status
    // [2290] fclose::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fclose::cbm_k_readst1
    // char status
    // [2292] fclose::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2294] fclose::cbm_k_readst1_return#0 = fclose::cbm_k_readst1_status -- vbuz1=vbum2 
    sta.z cbm_k_readst1_return
    // fclose::cbm_k_readst1_@return
    // }
    // [2295] fclose::cbm_k_readst1_return#1 = fclose::cbm_k_readst1_return#0
    // fclose::@3
    // cbm_k_readst()
    // [2296] fclose::$1 = fclose::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [2297] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$1 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fclose__1
    ldy.z sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2298] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@1 -- 0_eq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b1
    // fclose::@return
    // }
    // [2299] return 
    rts
    // fclose::@1
  __b1:
    // cbm_k_close(__logical)
    // [2300] fclose::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$40,y
    sta cbm_k_close1_channel
    // fclose::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // fclose::cbm_k_readst2
    // char status
    // [2302] fclose::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [2304] fclose::cbm_k_readst2_return#0 = fclose::cbm_k_readst2_status -- vbuz1=vbum2 
    sta.z cbm_k_readst2_return
    // fclose::cbm_k_readst2_@return
    // }
    // [2305] fclose::cbm_k_readst2_return#1 = fclose::cbm_k_readst2_return#0
    // fclose::@4
    // cbm_k_readst()
    // [2306] fclose::$4 = fclose::cbm_k_readst2_return#1
    // __status = cbm_k_readst()
    // [2307] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$4 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fclose__4
    ldy.z sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2308] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@2 -- 0_eq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b2
    rts
    // fclose::@2
  __b2:
    // __logical = 0
    // [2309] ((char *)&__stdio_file+$40)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    ldy.z sp
    sta __stdio_file+$40,y
    // __device = 0
    // [2310] ((char *)&__stdio_file+$42)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [2311] ((char *)&__stdio_file+$44)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$44,y
    // __filename
    // [2312] fclose::$6 = fclose::sp#0 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z fclose__6
    // *__filename = '\0'
    // [2313] ((char *)&__stdio_file)[fclose::$6] = '@' -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #'@'
    ldy.z fclose__6
    sta __stdio_file,y
    // __stdio_filecount--;
    // [2314] __stdio_filecount = -- __stdio_filecount -- vbum1=_dec_vbum1 
    dec __stdio_filecount
    rts
  .segment Data
    cbm_k_chkin1_channel: .byte 0
    cbm_k_chkin1_status: .byte 0
    cbm_k_readst1_status: .byte 0
    cbm_k_close1_channel: .byte 0
    cbm_k_readst2_status: .byte 0
}
.segment Code
  // strlen
// Computes the length of the string str up to but not including the terminating null character.
// __zp($55) unsigned int strlen(__zp($51) char *str)
strlen: {
    .label return = $55
    .label len = $55
    .label str = $51
    // [2316] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [2316] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z len
    sta.z len+1
    // [2316] phi strlen::str#6 = strlen::str#8 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [2317] if(0!=*strlen::str#6) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [2318] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [2319] strlen::len#1 = ++ strlen::len#2 -- vwuz1=_inc_vwuz1 
    inc.z len
    bne !+
    inc.z len+1
  !:
    // str++;
    // [2320] strlen::str#1 = ++ strlen::str#6 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [2316] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [2316] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [2316] phi strlen::str#6 = strlen::str#1 [phi:strlen::@2->strlen::@1#1] -- register_copy 
    jmp __b1
}
  // printf_padding
// Print a padding char a number of times
// void printf_padding(__zp($d7) void (*putc)(char), __zp($70) char pad, __zp($6a) char length)
printf_padding: {
    .label i = $53
    .label putc = $d7
    .label length = $6a
    .label pad = $70
    // [2322] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [2322] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [2323] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z length
    bcc __b2
    // printf_padding::@return
    // }
    // [2324] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [2325] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbuz1 
    lda.z pad
    pha
    // [2326] callexecute *printf_padding::putc#7  -- call__deref_pprz1 
    jsr icall36
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [2328] printf_padding::i#1 = ++ printf_padding::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [2322] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [2322] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
    jmp __b1
    // Outside Flow
  icall36:
    jmp (putc)
}
  // cbm_k_getin
/**
 * @brief Scan a character from keyboard without pressing enter.
 * 
 * @return char The character read.
 */
cbm_k_getin: {
    .label return = $6c
    // __mem unsigned char ch
    // [2329] cbm_k_getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // asm
    // asm { jsrCBM_GETIN stach  }
    jsr CBM_GETIN
    sta ch
    // return ch;
    // [2331] cbm_k_getin::return#0 = cbm_k_getin::ch -- vbuz1=vbum2 
    sta.z return
    // cbm_k_getin::@return
    // }
    // [2332] cbm_k_getin::return#1 = cbm_k_getin::return#0
    // [2333] return 
    rts
  .segment Data
    ch: .byte 0
}
.segment Code
  // uctoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void uctoa(__zp($2f) char value, __zp($60) char *buffer, __zp($e8) char radix)
uctoa: {
    .label uctoa__4 = $6c
    .label digit_value = $45
    .label buffer = $60
    .label digit = $67
    .label value = $2f
    .label radix = $e8
    .label started = $71
    .label max_digits = $ba
    .label digit_values = $55
    // if(radix==DECIMAL)
    // [2334] if(uctoa::radix#0==DECIMAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp.z radix
    beq __b2
    // uctoa::@2
    // if(radix==HEXADECIMAL)
    // [2335] if(uctoa::radix#0==HEXADECIMAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp.z radix
    beq __b3
    // uctoa::@3
    // if(radix==OCTAL)
    // [2336] if(uctoa::radix#0==OCTAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp.z radix
    beq __b4
    // uctoa::@4
    // if(radix==BINARY)
    // [2337] if(uctoa::radix#0==BINARY) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp.z radix
    beq __b5
    // uctoa::@5
    // *buffer++ = 'e'
    // [2338] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2339] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2340] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2341] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // uctoa::@return
    // }
    // [2342] return 
    rts
    // [2343] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
  __b2:
    // [2343] phi uctoa::digit_values#8 = RADIX_DECIMAL_VALUES_CHAR [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [2343] phi uctoa::max_digits#7 = 3 [phi:uctoa->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [2343] phi from uctoa::@2 to uctoa::@1 [phi:uctoa::@2->uctoa::@1]
  __b3:
    // [2343] phi uctoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_CHAR [phi:uctoa::@2->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [2343] phi uctoa::max_digits#7 = 2 [phi:uctoa::@2->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #2
    sta.z max_digits
    jmp __b1
    // [2343] phi from uctoa::@3 to uctoa::@1 [phi:uctoa::@3->uctoa::@1]
  __b4:
    // [2343] phi uctoa::digit_values#8 = RADIX_OCTAL_VALUES_CHAR [phi:uctoa::@3->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values+1
    // [2343] phi uctoa::max_digits#7 = 3 [phi:uctoa::@3->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [2343] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
  __b5:
    // [2343] phi uctoa::digit_values#8 = RADIX_BINARY_VALUES_CHAR [phi:uctoa::@4->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_BINARY_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_CHAR
    sta.z digit_values+1
    // [2343] phi uctoa::max_digits#7 = 8 [phi:uctoa::@4->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #8
    sta.z max_digits
    // uctoa::@1
  __b1:
    // [2344] phi from uctoa::@1 to uctoa::@6 [phi:uctoa::@1->uctoa::@6]
    // [2344] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa::@1->uctoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2344] phi uctoa::started#2 = 0 [phi:uctoa::@1->uctoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [2344] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa::@1->uctoa::@6#2] -- register_copy 
    // [2344] phi uctoa::digit#2 = 0 [phi:uctoa::@1->uctoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // uctoa::@6
  __b6:
    // max_digits-1
    // [2345] uctoa::$4 = uctoa::max_digits#7 - 1 -- vbuz1=vbuz2_minus_1 
    ldx.z max_digits
    dex
    stx.z uctoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2346] if(uctoa::digit#2<uctoa::$4) goto uctoa::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z digit
    cmp.z uctoa__4
    bcc __b7
    // uctoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2347] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z value
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2348] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2349] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // uctoa::@7
  __b7:
    // unsigned char digit_value = digit_values[digit]
    // [2350] uctoa::digit_value#0 = uctoa::digit_values#8[uctoa::digit#2] -- vbuz1=pbuz2_derefidx_vbuz3 
    ldy.z digit
    lda (digit_values),y
    sta.z digit_value
    // if (started || value >= digit_value)
    // [2351] if(0!=uctoa::started#2) goto uctoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // uctoa::@12
    // [2352] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@10 -- vbuz1_ge_vbuz2_then_la1 
    lda.z value
    cmp.z digit_value
    bcs __b10
    // [2353] phi from uctoa::@12 to uctoa::@9 [phi:uctoa::@12->uctoa::@9]
    // [2353] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@12->uctoa::@9#0] -- register_copy 
    // [2353] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@12->uctoa::@9#1] -- register_copy 
    // [2353] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@12->uctoa::@9#2] -- register_copy 
    // uctoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2354] uctoa::digit#1 = ++ uctoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [2344] phi from uctoa::@9 to uctoa::@6 [phi:uctoa::@9->uctoa::@6]
    // [2344] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@9->uctoa::@6#0] -- register_copy 
    // [2344] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@9->uctoa::@6#1] -- register_copy 
    // [2344] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@9->uctoa::@6#2] -- register_copy 
    // [2344] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@9->uctoa::@6#3] -- register_copy 
    jmp __b6
    // uctoa::@10
  __b10:
    // uctoa_append(buffer++, value, digit_value)
    // [2355] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [2356] uctoa_append::value#0 = uctoa::value#2
    // [2357] uctoa_append::sub#0 = uctoa::digit_value#0
    // [2358] call uctoa_append
    // [2759] phi from uctoa::@10 to uctoa_append [phi:uctoa::@10->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [2359] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@11
    // value = uctoa_append(buffer++, value, digit_value)
    // [2360] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [2361] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2353] phi from uctoa::@11 to uctoa::@9 [phi:uctoa::@11->uctoa::@9]
    // [2353] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@11->uctoa::@9#0] -- register_copy 
    // [2353] phi uctoa::started#4 = 1 [phi:uctoa::@11->uctoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [2353] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@11->uctoa::@9#2] -- register_copy 
    jmp __b9
}
  // printf_number_buffer
// Print the contents of the number buffer using a specific format.
// This handles minimum length, zero-filling, and left/right justification from the format
// void printf_number_buffer(__zp($5e) void (*putc)(char), __zp($d4) char buffer_sign, char *buffer_digits, __zp($ea) char format_min_length, char format_justify_left, char format_sign_always, __zp($e9) char format_zero_padding, char format_upper_case, char format_radix)
printf_number_buffer: {
    .label printf_number_buffer__19 = $55
    .label buffer_sign = $d4
    .label format_min_length = $ea
    .label format_zero_padding = $e9
    .label putc = $5e
    .label len = $df
    .label padding = $df
    // if(format.min_length)
    // [2363] if(0==printf_number_buffer::format_min_length#3) goto printf_number_buffer::@1 -- 0_eq_vbuz1_then_la1 
    lda.z format_min_length
    beq __b5
    // [2364] phi from printf_number_buffer to printf_number_buffer::@5 [phi:printf_number_buffer->printf_number_buffer::@5]
    // printf_number_buffer::@5
    // strlen(buffer.digits)
    // [2365] call strlen
    // [2315] phi from printf_number_buffer::@5 to strlen [phi:printf_number_buffer::@5->strlen]
    // [2315] phi strlen::str#8 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@5->strlen#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str+1
    jsr strlen
    // strlen(buffer.digits)
    // [2366] strlen::return#3 = strlen::len#2
    // printf_number_buffer::@11
    // [2367] printf_number_buffer::$19 = strlen::return#3
    // signed char len = (signed char)strlen(buffer.digits)
    // [2368] printf_number_buffer::len#0 = (signed char)printf_number_buffer::$19 -- vbsz1=_sbyte_vwuz2 
    // There is a minimum length - work out the padding
    lda.z printf_number_buffer__19
    sta.z len
    // if(buffer.sign)
    // [2369] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@10 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b10
    // printf_number_buffer::@6
    // len++;
    // [2370] printf_number_buffer::len#1 = ++ printf_number_buffer::len#0 -- vbsz1=_inc_vbsz1 
    inc.z len
    // [2371] phi from printf_number_buffer::@11 printf_number_buffer::@6 to printf_number_buffer::@10 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10]
    // [2371] phi printf_number_buffer::len#2 = printf_number_buffer::len#0 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10#0] -- register_copy 
    // printf_number_buffer::@10
  __b10:
    // padding = (signed char)format.min_length - len
    // [2372] printf_number_buffer::padding#1 = (signed char)printf_number_buffer::format_min_length#3 - printf_number_buffer::len#2 -- vbsz1=vbsz2_minus_vbsz1 
    lda.z format_min_length
    sec
    sbc.z padding
    sta.z padding
    // if(padding<0)
    // [2373] if(printf_number_buffer::padding#1>=0) goto printf_number_buffer::@15 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [2375] phi from printf_number_buffer printf_number_buffer::@10 to printf_number_buffer::@1 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1]
  __b5:
    // [2375] phi printf_number_buffer::padding#10 = 0 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [2374] phi from printf_number_buffer::@10 to printf_number_buffer::@15 [phi:printf_number_buffer::@10->printf_number_buffer::@15]
    // printf_number_buffer::@15
    // [2375] phi from printf_number_buffer::@15 to printf_number_buffer::@1 [phi:printf_number_buffer::@15->printf_number_buffer::@1]
    // [2375] phi printf_number_buffer::padding#10 = printf_number_buffer::padding#1 [phi:printf_number_buffer::@15->printf_number_buffer::@1#0] -- register_copy 
    // printf_number_buffer::@1
  __b1:
    // printf_number_buffer::@13
    // if(!format.justify_left && !format.zero_padding && padding)
    // [2376] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_zero_padding
    bne __b2
    // printf_number_buffer::@12
    // [2377] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@7 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b7
    jmp __b2
    // printf_number_buffer::@7
  __b7:
    // printf_padding(putc, ' ',(char)padding)
    // [2378] printf_padding::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [2379] printf_padding::length#0 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [2380] call printf_padding
    // [2321] phi from printf_number_buffer::@7 to printf_padding [phi:printf_number_buffer::@7->printf_padding]
    // [2321] phi printf_padding::putc#7 = printf_padding::putc#0 [phi:printf_number_buffer::@7->printf_padding#0] -- register_copy 
    // [2321] phi printf_padding::pad#7 = ' ' [phi:printf_number_buffer::@7->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [2321] phi printf_padding::length#6 = printf_padding::length#0 [phi:printf_number_buffer::@7->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@2
  __b2:
    // if(buffer.sign)
    // [2381] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@3 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b3
    // printf_number_buffer::@8
    // putc(buffer.sign)
    // [2382] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbuz1 
    pha
    // [2383] callexecute *printf_number_buffer::putc#10  -- call__deref_pprz1 
    jsr icall37
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@3
  __b3:
    // if(format.zero_padding && padding)
    // [2385] if(0==printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@4 -- 0_eq_vbuz1_then_la1 
    lda.z format_zero_padding
    beq __b4
    // printf_number_buffer::@14
    // [2386] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@9 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b9
    jmp __b4
    // printf_number_buffer::@9
  __b9:
    // printf_padding(putc, '0',(char)padding)
    // [2387] printf_padding::putc#1 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [2388] printf_padding::length#1 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [2389] call printf_padding
    // [2321] phi from printf_number_buffer::@9 to printf_padding [phi:printf_number_buffer::@9->printf_padding]
    // [2321] phi printf_padding::putc#7 = printf_padding::putc#1 [phi:printf_number_buffer::@9->printf_padding#0] -- register_copy 
    // [2321] phi printf_padding::pad#7 = '0' [phi:printf_number_buffer::@9->printf_padding#1] -- vbuz1=vbuc1 
    lda #'0'
    sta.z printf_padding.pad
    // [2321] phi printf_padding::length#6 = printf_padding::length#1 [phi:printf_number_buffer::@9->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@4
  __b4:
    // printf_str(putc, buffer.digits)
    // [2390] printf_str::putc#0 = printf_number_buffer::putc#10
    // [2391] call printf_str
    // [1156] phi from printf_number_buffer::@4 to printf_str [phi:printf_number_buffer::@4->printf_str]
    // [1156] phi printf_str::putc#71 = printf_str::putc#0 [phi:printf_number_buffer::@4->printf_str#0] -- register_copy 
    // [1156] phi printf_str::s#71 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@return
    // }
    // [2392] return 
    rts
    // Outside Flow
  icall37:
    jmp (putc)
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
// __mem() unsigned long rom_address_from_bank(__mem() char rom_bank)
rom_address_from_bank: {
    .label rom_address_from_bank__1 = $57
    .label return = $57
    .label return_1 = $a9
    // ((unsigned long)(rom_bank)) << 14
    // [2394] rom_address_from_bank::$1 = (unsigned long)rom_address_from_bank::rom_bank#3 -- vduz1=_dword_vbum2 
    lda rom_bank
    sta.z rom_address_from_bank__1
    lda #0
    sta.z rom_address_from_bank__1+1
    sta.z rom_address_from_bank__1+2
    sta.z rom_address_from_bank__1+3
    // [2395] rom_address_from_bank::return#0 = rom_address_from_bank::$1 << $e -- vduz1=vduz1_rol_vbuc1 
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
    // [2396] return 
    rts
  .segment Data
    .label rom_bank = fopen.fopen__4
    .label return_2 = main.rom_file_modulo
}
.segment Code
  // rom_compare
// __zp($51) unsigned int rom_compare(__zp($ee) char bank_ram, __zp($b2) char *ptr_ram, __zp($57) unsigned long rom_compare_address, __zp($d1) unsigned int rom_compare_size)
rom_compare: {
    .label rom_compare__5 = $35
    .label rom_bank1_rom_compare__0 = $45
    .label rom_bank1_rom_compare__1 = $6d
    .label rom_bank1_rom_compare__2 = $eb
    .label rom_ptr1_rom_compare__0 = $76
    .label rom_ptr1_rom_compare__2 = $76
    .label bank_set_bram1_bank = $ee
    .label rom_bank1_bank_unshifted = $eb
    .label rom_bank1_return = $e2
    .label rom_ptr1_return = $76
    .label ptr_rom = $76
    .label ptr_ram = $b2
    .label compared_bytes = $ad
    /// Holds the amount of bytes actually verified between the ROM and the RAM.
    .label equal_bytes = $51
    .label bank_ram = $ee
    .label rom_compare_address = $57
    .label return = $51
    .label rom_compare_size = $d1
    // rom_compare::bank_set_bram1
    // BRAM = bank
    // [2398] BRAM = rom_compare::bank_set_bram1_bank#0 -- vbuz1=vbuz2 
    lda.z bank_set_bram1_bank
    sta.z BRAM
    // rom_compare::rom_bank1
    // BYTE2(address)
    // [2399] rom_compare::rom_bank1_$0 = byte2  rom_compare::rom_compare_address#3 -- vbuz1=_byte2_vduz2 
    lda.z rom_compare_address+2
    sta.z rom_bank1_rom_compare__0
    // BYTE1(address)
    // [2400] rom_compare::rom_bank1_$1 = byte1  rom_compare::rom_compare_address#3 -- vbuz1=_byte1_vduz2 
    lda.z rom_compare_address+1
    sta.z rom_bank1_rom_compare__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2401] rom_compare::rom_bank1_$2 = rom_compare::rom_bank1_$0 w= rom_compare::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_compare__0
    sta.z rom_bank1_rom_compare__2+1
    lda.z rom_bank1_rom_compare__1
    sta.z rom_bank1_rom_compare__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2402] rom_compare::rom_bank1_bank_unshifted#0 = rom_compare::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2403] rom_compare::rom_bank1_return#0 = byte1  rom_compare::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwuz2 
    lda.z rom_bank1_bank_unshifted+1
    sta.z rom_bank1_return
    // rom_compare::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2404] rom_compare::rom_ptr1_$2 = (unsigned int)rom_compare::rom_compare_address#3 -- vwuz1=_word_vduz2 
    lda.z rom_compare_address
    sta.z rom_ptr1_rom_compare__2
    lda.z rom_compare_address+1
    sta.z rom_ptr1_rom_compare__2+1
    // [2405] rom_compare::rom_ptr1_$0 = rom_compare::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_compare__0
    and #<$3fff
    sta.z rom_ptr1_rom_compare__0
    lda.z rom_ptr1_rom_compare__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_compare__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2406] rom_compare::rom_ptr1_return#0 = rom_compare::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_compare::bank_set_brom1
    // BROM = bank
    // [2407] BROM = rom_compare::rom_bank1_return#0 -- vbuz1=vbuz2 
    lda.z rom_bank1_return
    sta.z BROM
    // [2408] rom_compare::ptr_rom#9 = (char *)rom_compare::rom_ptr1_return#0
    // [2409] phi from rom_compare::bank_set_brom1 to rom_compare::@1 [phi:rom_compare::bank_set_brom1->rom_compare::@1]
    // [2409] phi rom_compare::equal_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z equal_bytes
    sta.z equal_bytes+1
    // [2409] phi rom_compare::ptr_ram#4 = rom_compare::ptr_ram#10 [phi:rom_compare::bank_set_brom1->rom_compare::@1#1] -- register_copy 
    // [2409] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#9 [phi:rom_compare::bank_set_brom1->rom_compare::@1#2] -- register_copy 
    // [2409] phi rom_compare::compared_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#3] -- vwuz1=vwuc1 
    sta.z compared_bytes
    sta.z compared_bytes+1
    // rom_compare::@1
  __b1:
    // while (compared_bytes < rom_compare_size)
    // [2410] if(rom_compare::compared_bytes#2<rom_compare::rom_compare_size#11) goto rom_compare::@2 -- vwuz1_lt_vwuz2_then_la1 
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
    // [2411] return 
    rts
    // rom_compare::@2
  __b2:
    // rom_byte_compare(ptr_rom, *ptr_ram)
    // [2412] rom_byte_compare::ptr_rom#0 = rom_compare::ptr_rom#2
    // [2413] rom_byte_compare::value#0 = *rom_compare::ptr_ram#4 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (ptr_ram),y
    sta.z rom_byte_compare.value
    // [2414] call rom_byte_compare
    jsr rom_byte_compare
    // [2415] rom_byte_compare::return#2 = rom_byte_compare::return#0
    // rom_compare::@5
    // [2416] rom_compare::$5 = rom_byte_compare::return#2
    // if (rom_byte_compare(ptr_rom, *ptr_ram))
    // [2417] if(0==rom_compare::$5) goto rom_compare::@3 -- 0_eq_vbuz1_then_la1 
    lda.z rom_compare__5
    beq __b3
    // rom_compare::@4
    // equal_bytes++;
    // [2418] rom_compare::equal_bytes#1 = ++ rom_compare::equal_bytes#2 -- vwuz1=_inc_vwuz1 
    inc.z equal_bytes
    bne !+
    inc.z equal_bytes+1
  !:
    // [2419] phi from rom_compare::@4 rom_compare::@5 to rom_compare::@3 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3]
    // [2419] phi rom_compare::equal_bytes#6 = rom_compare::equal_bytes#1 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3#0] -- register_copy 
    // rom_compare::@3
  __b3:
    // ptr_rom++;
    // [2420] rom_compare::ptr_rom#1 = ++ rom_compare::ptr_rom#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr_rom
    bne !+
    inc.z ptr_rom+1
  !:
    // ptr_ram++;
    // [2421] rom_compare::ptr_ram#0 = ++ rom_compare::ptr_ram#4 -- pbuz1=_inc_pbuz1 
    inc.z ptr_ram
    bne !+
    inc.z ptr_ram+1
  !:
    // compared_bytes++;
    // [2422] rom_compare::compared_bytes#1 = ++ rom_compare::compared_bytes#2 -- vwuz1=_inc_vwuz1 
    inc.z compared_bytes
    bne !+
    inc.z compared_bytes+1
  !:
    // [2409] phi from rom_compare::@3 to rom_compare::@1 [phi:rom_compare::@3->rom_compare::@1]
    // [2409] phi rom_compare::equal_bytes#2 = rom_compare::equal_bytes#6 [phi:rom_compare::@3->rom_compare::@1#0] -- register_copy 
    // [2409] phi rom_compare::ptr_ram#4 = rom_compare::ptr_ram#0 [phi:rom_compare::@3->rom_compare::@1#1] -- register_copy 
    // [2409] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#1 [phi:rom_compare::@3->rom_compare::@1#2] -- register_copy 
    // [2409] phi rom_compare::compared_bytes#2 = rom_compare::compared_bytes#1 [phi:rom_compare::@3->rom_compare::@1#3] -- register_copy 
    jmp __b1
}
  // ultoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void ultoa(__zp($30) unsigned long value, __zp($62) char *buffer, __zp($e7) char radix)
ultoa: {
    .label ultoa__4 = $6d
    .label ultoa__10 = $66
    .label ultoa__11 = $e2
    .label digit_value = $41
    .label buffer = $62
    .label digit = $69
    .label value = $30
    .label radix = $e7
    .label started = $73
    .label max_digits = $be
    .label digit_values = $2d
    // if(radix==DECIMAL)
    // [2423] if(ultoa::radix#0==DECIMAL) goto ultoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp.z radix
    beq __b2
    // ultoa::@2
    // if(radix==HEXADECIMAL)
    // [2424] if(ultoa::radix#0==HEXADECIMAL) goto ultoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp.z radix
    beq __b3
    // ultoa::@3
    // if(radix==OCTAL)
    // [2425] if(ultoa::radix#0==OCTAL) goto ultoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp.z radix
    beq __b4
    // ultoa::@4
    // if(radix==BINARY)
    // [2426] if(ultoa::radix#0==BINARY) goto ultoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp.z radix
    beq __b5
    // ultoa::@5
    // *buffer++ = 'e'
    // [2427] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2428] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2429] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2430] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // ultoa::@return
    // }
    // [2431] return 
    rts
    // [2432] phi from ultoa to ultoa::@1 [phi:ultoa->ultoa::@1]
  __b2:
    // [2432] phi ultoa::digit_values#8 = RADIX_DECIMAL_VALUES_LONG [phi:ultoa->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2432] phi ultoa::max_digits#7 = $a [phi:ultoa->ultoa::@1#1] -- vbuz1=vbuc1 
    lda #$a
    sta.z max_digits
    jmp __b1
    // [2432] phi from ultoa::@2 to ultoa::@1 [phi:ultoa::@2->ultoa::@1]
  __b3:
    // [2432] phi ultoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_LONG [phi:ultoa::@2->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2432] phi ultoa::max_digits#7 = 8 [phi:ultoa::@2->ultoa::@1#1] -- vbuz1=vbuc1 
    lda #8
    sta.z max_digits
    jmp __b1
    // [2432] phi from ultoa::@3 to ultoa::@1 [phi:ultoa::@3->ultoa::@1]
  __b4:
    // [2432] phi ultoa::digit_values#8 = RADIX_OCTAL_VALUES_LONG [phi:ultoa::@3->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_OCTAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_LONG
    sta.z digit_values+1
    // [2432] phi ultoa::max_digits#7 = $b [phi:ultoa::@3->ultoa::@1#1] -- vbuz1=vbuc1 
    lda #$b
    sta.z max_digits
    jmp __b1
    // [2432] phi from ultoa::@4 to ultoa::@1 [phi:ultoa::@4->ultoa::@1]
  __b5:
    // [2432] phi ultoa::digit_values#8 = RADIX_BINARY_VALUES_LONG [phi:ultoa::@4->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_BINARY_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_LONG
    sta.z digit_values+1
    // [2432] phi ultoa::max_digits#7 = $20 [phi:ultoa::@4->ultoa::@1#1] -- vbuz1=vbuc1 
    lda #$20
    sta.z max_digits
    // ultoa::@1
  __b1:
    // [2433] phi from ultoa::@1 to ultoa::@6 [phi:ultoa::@1->ultoa::@6]
    // [2433] phi ultoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:ultoa::@1->ultoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2433] phi ultoa::started#2 = 0 [phi:ultoa::@1->ultoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [2433] phi ultoa::value#2 = ultoa::value#1 [phi:ultoa::@1->ultoa::@6#2] -- register_copy 
    // [2433] phi ultoa::digit#2 = 0 [phi:ultoa::@1->ultoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // ultoa::@6
  __b6:
    // max_digits-1
    // [2434] ultoa::$4 = ultoa::max_digits#7 - 1 -- vbuz1=vbuz2_minus_1 
    ldx.z max_digits
    dex
    stx.z ultoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2435] if(ultoa::digit#2<ultoa::$4) goto ultoa::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z digit
    cmp.z ultoa__4
    bcc __b7
    // ultoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2436] ultoa::$11 = (char)ultoa::value#2 -- vbuz1=_byte_vduz2 
    lda.z value
    sta.z ultoa__11
    // [2437] *ultoa::buffer#11 = DIGITS[ultoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2438] ultoa::buffer#3 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2439] *ultoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // ultoa::@7
  __b7:
    // unsigned long digit_value = digit_values[digit]
    // [2440] ultoa::$10 = ultoa::digit#2 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z digit
    asl
    asl
    sta.z ultoa__10
    // [2441] ultoa::digit_value#0 = ultoa::digit_values#8[ultoa::$10] -- vduz1=pduz2_derefidx_vbuz3 
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
    // [2442] if(0!=ultoa::started#2) goto ultoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // ultoa::@12
    // [2443] if(ultoa::value#2>=ultoa::digit_value#0) goto ultoa::@10 -- vduz1_ge_vduz2_then_la1 
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
    // [2444] phi from ultoa::@12 to ultoa::@9 [phi:ultoa::@12->ultoa::@9]
    // [2444] phi ultoa::buffer#14 = ultoa::buffer#11 [phi:ultoa::@12->ultoa::@9#0] -- register_copy 
    // [2444] phi ultoa::started#4 = ultoa::started#2 [phi:ultoa::@12->ultoa::@9#1] -- register_copy 
    // [2444] phi ultoa::value#6 = ultoa::value#2 [phi:ultoa::@12->ultoa::@9#2] -- register_copy 
    // ultoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2445] ultoa::digit#1 = ++ ultoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [2433] phi from ultoa::@9 to ultoa::@6 [phi:ultoa::@9->ultoa::@6]
    // [2433] phi ultoa::buffer#11 = ultoa::buffer#14 [phi:ultoa::@9->ultoa::@6#0] -- register_copy 
    // [2433] phi ultoa::started#2 = ultoa::started#4 [phi:ultoa::@9->ultoa::@6#1] -- register_copy 
    // [2433] phi ultoa::value#2 = ultoa::value#6 [phi:ultoa::@9->ultoa::@6#2] -- register_copy 
    // [2433] phi ultoa::digit#2 = ultoa::digit#1 [phi:ultoa::@9->ultoa::@6#3] -- register_copy 
    jmp __b6
    // ultoa::@10
  __b10:
    // ultoa_append(buffer++, value, digit_value)
    // [2446] ultoa_append::buffer#0 = ultoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z ultoa_append.buffer
    lda.z buffer+1
    sta.z ultoa_append.buffer+1
    // [2447] ultoa_append::value#0 = ultoa::value#2
    // [2448] ultoa_append::sub#0 = ultoa::digit_value#0
    // [2449] call ultoa_append
    // [2770] phi from ultoa::@10 to ultoa_append [phi:ultoa::@10->ultoa_append]
    jsr ultoa_append
    // ultoa_append(buffer++, value, digit_value)
    // [2450] ultoa_append::return#0 = ultoa_append::value#2
    // ultoa::@11
    // value = ultoa_append(buffer++, value, digit_value)
    // [2451] ultoa::value#0 = ultoa_append::return#0
    // value = ultoa_append(buffer++, value, digit_value);
    // [2452] ultoa::buffer#4 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2444] phi from ultoa::@11 to ultoa::@9 [phi:ultoa::@11->ultoa::@9]
    // [2444] phi ultoa::buffer#14 = ultoa::buffer#4 [phi:ultoa::@11->ultoa::@9#0] -- register_copy 
    // [2444] phi ultoa::started#4 = 1 [phi:ultoa::@11->ultoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [2444] phi ultoa::value#6 = ultoa::value#0 [phi:ultoa::@11->ultoa::@9#2] -- register_copy 
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
    .label rom_chip_address = $78
    // rom_sector_erase::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2454] rom_sector_erase::rom_ptr1_$2 = (unsigned int)rom_sector_erase::address#0 -- vwuz1=_word_vdum2 
    lda address
    sta.z rom_ptr1_rom_sector_erase__2
    lda address+1
    sta.z rom_ptr1_rom_sector_erase__2+1
    // [2455] rom_sector_erase::rom_ptr1_$0 = rom_sector_erase::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_sector_erase__0
    and #<$3fff
    sta.z rom_ptr1_rom_sector_erase__0
    lda.z rom_ptr1_rom_sector_erase__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_sector_erase__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2456] rom_sector_erase::rom_ptr1_return#0 = rom_sector_erase::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_sector_erase::@1
    // unsigned long rom_chip_address = address & ROM_CHIP_MASK
    // [2457] rom_sector_erase::rom_chip_address#0 = rom_sector_erase::address#0 & $380000 -- vduz1=vdum2_band_vduc1 
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
    // [2458] rom_unlock::address#0 = rom_sector_erase::rom_chip_address#0 + $5555 -- vduz1=vduz1_plus_vwuc1 
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
    // [2459] call rom_unlock
    // [2126] phi from rom_sector_erase::@1 to rom_unlock [phi:rom_sector_erase::@1->rom_unlock]
    // [2126] phi rom_unlock::unlock_code#5 = $80 [phi:rom_sector_erase::@1->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$80
    sta.z rom_unlock.unlock_code
    // [2126] phi rom_unlock::address#5 = rom_unlock::address#0 [phi:rom_sector_erase::@1->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@2
    // rom_unlock(address, 0x30)
    // [2460] rom_unlock::address#1 = rom_sector_erase::address#0 -- vduz1=vdum2 
    lda address
    sta.z rom_unlock.address
    lda address+1
    sta.z rom_unlock.address+1
    lda address+2
    sta.z rom_unlock.address+2
    lda address+3
    sta.z rom_unlock.address+3
    // [2461] call rom_unlock
    // [2126] phi from rom_sector_erase::@2 to rom_unlock [phi:rom_sector_erase::@2->rom_unlock]
    // [2126] phi rom_unlock::unlock_code#5 = $30 [phi:rom_sector_erase::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$30
    sta.z rom_unlock.unlock_code
    // [2126] phi rom_unlock::address#5 = rom_unlock::address#1 [phi:rom_sector_erase::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@3
    // rom_wait(ptr_rom)
    // [2462] rom_wait::ptr_rom#0 = (char *)rom_sector_erase::rom_ptr1_return#0
    // [2463] call rom_wait
    // [2777] phi from rom_sector_erase::@3 to rom_wait [phi:rom_sector_erase::@3->rom_wait]
    // [2777] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#0 [phi:rom_sector_erase::@3->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_sector_erase::@return
    // }
    // [2464] return 
    rts
  .segment Data
    .label address = printf_ulong.uvalue_1
}
.segment Code
  // rom_write
/* inline */
// unsigned long rom_write(__zp($45) char flash_ram_bank, __zp($2d) char *flash_ram_address, __zp($b4) unsigned long flash_rom_address, unsigned int flash_rom_size)
rom_write: {
    .label rom_chip_address = $c7
    .label flash_rom_address = $b4
    .label flash_ram_address = $2d
    .label flashed_bytes = $a9
    .label flash_ram_bank = $45
    // unsigned long rom_chip_address = flash_rom_address & ROM_CHIP_MASK
    // [2465] rom_write::rom_chip_address#0 = rom_write::flash_rom_address#1 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [2466] BRAM = rom_write::flash_ram_bank#0 -- vbuz1=vbuz2 
    lda.z flash_ram_bank
    sta.z BRAM
    // [2467] phi from rom_write::bank_set_bram1 to rom_write::@1 [phi:rom_write::bank_set_bram1->rom_write::@1]
    // [2467] phi rom_write::flash_ram_address#2 = rom_write::flash_ram_address#1 [phi:rom_write::bank_set_bram1->rom_write::@1#0] -- register_copy 
    // [2467] phi rom_write::flash_rom_address#3 = rom_write::flash_rom_address#1 [phi:rom_write::bank_set_bram1->rom_write::@1#1] -- register_copy 
    // [2467] phi rom_write::flashed_bytes#2 = 0 [phi:rom_write::bank_set_bram1->rom_write::@1#2] -- vduz1=vduc1 
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
    // [2468] if(rom_write::flashed_bytes#2<ROM_PROGRESS_CELL) goto rom_write::@2 -- vduz1_lt_vduc1_then_la1 
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
    // [2469] return 
    rts
    // rom_write::@2
  __b2:
    // rom_unlock(rom_chip_address + 0x05555, 0xA0)
    // [2470] rom_unlock::address#4 = rom_write::rom_chip_address#0 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [2471] call rom_unlock
    // [2126] phi from rom_write::@2 to rom_unlock [phi:rom_write::@2->rom_unlock]
    // [2126] phi rom_unlock::unlock_code#5 = $a0 [phi:rom_write::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$a0
    sta.z rom_unlock.unlock_code
    // [2126] phi rom_unlock::address#5 = rom_unlock::address#4 [phi:rom_write::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_write::@3
    // rom_byte_program(flash_rom_address, *flash_ram_address)
    // [2472] rom_byte_program::address#0 = rom_write::flash_rom_address#3 -- vduz1=vduz2 
    lda.z flash_rom_address
    sta.z rom_byte_program.address
    lda.z flash_rom_address+1
    sta.z rom_byte_program.address+1
    lda.z flash_rom_address+2
    sta.z rom_byte_program.address+2
    lda.z flash_rom_address+3
    sta.z rom_byte_program.address+3
    // [2473] rom_byte_program::value#0 = *rom_write::flash_ram_address#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (flash_ram_address),y
    sta.z rom_byte_program.value
    // [2474] call rom_byte_program
    // [2784] phi from rom_write::@3 to rom_byte_program [phi:rom_write::@3->rom_byte_program]
    jsr rom_byte_program
    // rom_write::@4
    // flash_rom_address++;
    // [2475] rom_write::flash_rom_address#0 = ++ rom_write::flash_rom_address#3 -- vduz1=_inc_vduz1 
    inc.z flash_rom_address
    bne !+
    inc.z flash_rom_address+1
    bne !+
    inc.z flash_rom_address+2
    bne !+
    inc.z flash_rom_address+3
  !:
    // flash_ram_address++;
    // [2476] rom_write::flash_ram_address#0 = ++ rom_write::flash_ram_address#2 -- pbuz1=_inc_pbuz1 
    inc.z flash_ram_address
    bne !+
    inc.z flash_ram_address+1
  !:
    // flashed_bytes++;
    // [2477] rom_write::flashed_bytes#1 = ++ rom_write::flashed_bytes#2 -- vduz1=_inc_vduz1 
    inc.z flashed_bytes
    bne !+
    inc.z flashed_bytes+1
    bne !+
    inc.z flashed_bytes+2
    bne !+
    inc.z flashed_bytes+3
  !:
    // [2467] phi from rom_write::@4 to rom_write::@1 [phi:rom_write::@4->rom_write::@1]
    // [2467] phi rom_write::flash_ram_address#2 = rom_write::flash_ram_address#0 [phi:rom_write::@4->rom_write::@1#0] -- register_copy 
    // [2467] phi rom_write::flash_rom_address#3 = rom_write::flash_rom_address#0 [phi:rom_write::@4->rom_write::@1#1] -- register_copy 
    // [2467] phi rom_write::flashed_bytes#2 = rom_write::flashed_bytes#1 [phi:rom_write::@4->rom_write::@1#2] -- register_copy 
    jmp __b1
}
  // strncpy
/// Copies up to n characters from the string pointed to, by src to dst.
/// In a case where the length of src is less than that of n, the remainder of dst will be padded with null bytes.
/// @param dst ? This is the pointer to the destination array where the content is to be copied.
/// @param src ? This is the string to be copied.
/// @param n ? The number of characters to be copied from source.
/// @return The destination
// char * strncpy(__zp($4f) char *dst, __zp($3f) const char *src, __zp($62) unsigned int n)
strncpy: {
    .label c = $6b
    .label dst = $4f
    .label i = $bc
    .label src = $3f
    .label n = $62
    // [2479] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [2479] phi strncpy::dst#3 = strncpy::dst#8 [phi:strncpy->strncpy::@1#0] -- register_copy 
    // [2479] phi strncpy::src#3 = strncpy::src#6 [phi:strncpy->strncpy::@1#1] -- register_copy 
    // [2479] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwuz1=vwuc1 
    lda #<0
    sta.z i
    sta.z i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [2480] if(strncpy::i#2<strncpy::n#3) goto strncpy::@2 -- vwuz1_lt_vwuz2_then_la1 
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
    // [2481] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [2482] strncpy::c#0 = *strncpy::src#3 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta.z c
    // if(c)
    // [2483] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbuz1_then_la1 
    beq __b3
    // strncpy::@4
    // src++;
    // [2484] strncpy::src#0 = ++ strncpy::src#3 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [2485] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [2485] phi strncpy::src#7 = strncpy::src#3 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [2486] *strncpy::dst#3 = strncpy::c#0 -- _deref_pbuz1=vbuz2 
    lda.z c
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [2487] strncpy::dst#0 = ++ strncpy::dst#3 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [2488] strncpy::i#1 = ++ strncpy::i#2 -- vwuz1=_inc_vwuz1 
    inc.z i
    bne !+
    inc.z i+1
  !:
    // [2479] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [2479] phi strncpy::dst#3 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [2479] phi strncpy::src#3 = strncpy::src#7 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [2479] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
    jmp __b1
}
  // utoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void utoa(__zp($2d) unsigned int value, __zp($64) char *buffer, __zp($e6) char radix)
utoa: {
    .label utoa__4 = $6b
    .label utoa__10 = $6e
    .label utoa__11 = $e3
    .label digit_value = $3f
    .label buffer = $64
    .label digit = $68
    .label value = $2d
    .label radix = $e6
    .label started = $72
    .label max_digits = $bf
    .label digit_values = $bc
    // if(radix==DECIMAL)
    // [2489] if(utoa::radix#0==DECIMAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp.z radix
    beq __b2
    // utoa::@2
    // if(radix==HEXADECIMAL)
    // [2490] if(utoa::radix#0==HEXADECIMAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp.z radix
    beq __b3
    // utoa::@3
    // if(radix==OCTAL)
    // [2491] if(utoa::radix#0==OCTAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp.z radix
    beq __b4
    // utoa::@4
    // if(radix==BINARY)
    // [2492] if(utoa::radix#0==BINARY) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp.z radix
    beq __b5
    // utoa::@5
    // *buffer++ = 'e'
    // [2493] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2494] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2495] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2496] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // utoa::@return
    // }
    // [2497] return 
    rts
    // [2498] phi from utoa to utoa::@1 [phi:utoa->utoa::@1]
  __b2:
    // [2498] phi utoa::digit_values#8 = RADIX_DECIMAL_VALUES [phi:utoa->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_DECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES
    sta.z digit_values+1
    // [2498] phi utoa::max_digits#7 = 5 [phi:utoa->utoa::@1#1] -- vbuz1=vbuc1 
    lda #5
    sta.z max_digits
    jmp __b1
    // [2498] phi from utoa::@2 to utoa::@1 [phi:utoa::@2->utoa::@1]
  __b3:
    // [2498] phi utoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES [phi:utoa::@2->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_HEXADECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES
    sta.z digit_values+1
    // [2498] phi utoa::max_digits#7 = 4 [phi:utoa::@2->utoa::@1#1] -- vbuz1=vbuc1 
    lda #4
    sta.z max_digits
    jmp __b1
    // [2498] phi from utoa::@3 to utoa::@1 [phi:utoa::@3->utoa::@1]
  __b4:
    // [2498] phi utoa::digit_values#8 = RADIX_OCTAL_VALUES [phi:utoa::@3->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_OCTAL_VALUES
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES
    sta.z digit_values+1
    // [2498] phi utoa::max_digits#7 = 6 [phi:utoa::@3->utoa::@1#1] -- vbuz1=vbuc1 
    lda #6
    sta.z max_digits
    jmp __b1
    // [2498] phi from utoa::@4 to utoa::@1 [phi:utoa::@4->utoa::@1]
  __b5:
    // [2498] phi utoa::digit_values#8 = RADIX_BINARY_VALUES [phi:utoa::@4->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_BINARY_VALUES
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES
    sta.z digit_values+1
    // [2498] phi utoa::max_digits#7 = $10 [phi:utoa::@4->utoa::@1#1] -- vbuz1=vbuc1 
    lda #$10
    sta.z max_digits
    // utoa::@1
  __b1:
    // [2499] phi from utoa::@1 to utoa::@6 [phi:utoa::@1->utoa::@6]
    // [2499] phi utoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:utoa::@1->utoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2499] phi utoa::started#2 = 0 [phi:utoa::@1->utoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [2499] phi utoa::value#2 = utoa::value#1 [phi:utoa::@1->utoa::@6#2] -- register_copy 
    // [2499] phi utoa::digit#2 = 0 [phi:utoa::@1->utoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // utoa::@6
  __b6:
    // max_digits-1
    // [2500] utoa::$4 = utoa::max_digits#7 - 1 -- vbuz1=vbuz2_minus_1 
    ldx.z max_digits
    dex
    stx.z utoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2501] if(utoa::digit#2<utoa::$4) goto utoa::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z digit
    cmp.z utoa__4
    bcc __b7
    // utoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2502] utoa::$11 = (char)utoa::value#2 -- vbuz1=_byte_vwuz2 
    lda.z value
    sta.z utoa__11
    // [2503] *utoa::buffer#11 = DIGITS[utoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2504] utoa::buffer#3 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2505] *utoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // utoa::@7
  __b7:
    // unsigned int digit_value = digit_values[digit]
    // [2506] utoa::$10 = utoa::digit#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z digit
    asl
    sta.z utoa__10
    // [2507] utoa::digit_value#0 = utoa::digit_values#8[utoa::$10] -- vwuz1=pwuz2_derefidx_vbuz3 
    tay
    lda (digit_values),y
    sta.z digit_value
    iny
    lda (digit_values),y
    sta.z digit_value+1
    // if (started || value >= digit_value)
    // [2508] if(0!=utoa::started#2) goto utoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // utoa::@12
    // [2509] if(utoa::value#2>=utoa::digit_value#0) goto utoa::@10 -- vwuz1_ge_vwuz2_then_la1 
    lda.z digit_value+1
    cmp.z value+1
    bne !+
    lda.z digit_value
    cmp.z value
    beq __b10
  !:
    bcc __b10
    // [2510] phi from utoa::@12 to utoa::@9 [phi:utoa::@12->utoa::@9]
    // [2510] phi utoa::buffer#14 = utoa::buffer#11 [phi:utoa::@12->utoa::@9#0] -- register_copy 
    // [2510] phi utoa::started#4 = utoa::started#2 [phi:utoa::@12->utoa::@9#1] -- register_copy 
    // [2510] phi utoa::value#6 = utoa::value#2 [phi:utoa::@12->utoa::@9#2] -- register_copy 
    // utoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2511] utoa::digit#1 = ++ utoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [2499] phi from utoa::@9 to utoa::@6 [phi:utoa::@9->utoa::@6]
    // [2499] phi utoa::buffer#11 = utoa::buffer#14 [phi:utoa::@9->utoa::@6#0] -- register_copy 
    // [2499] phi utoa::started#2 = utoa::started#4 [phi:utoa::@9->utoa::@6#1] -- register_copy 
    // [2499] phi utoa::value#2 = utoa::value#6 [phi:utoa::@9->utoa::@6#2] -- register_copy 
    // [2499] phi utoa::digit#2 = utoa::digit#1 [phi:utoa::@9->utoa::@6#3] -- register_copy 
    jmp __b6
    // utoa::@10
  __b10:
    // utoa_append(buffer++, value, digit_value)
    // [2512] utoa_append::buffer#0 = utoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z utoa_append.buffer
    lda.z buffer+1
    sta.z utoa_append.buffer+1
    // [2513] utoa_append::value#0 = utoa::value#2
    // [2514] utoa_append::sub#0 = utoa::digit_value#0
    // [2515] call utoa_append
    // [2794] phi from utoa::@10 to utoa_append [phi:utoa::@10->utoa_append]
    jsr utoa_append
    // utoa_append(buffer++, value, digit_value)
    // [2516] utoa_append::return#0 = utoa_append::value#2
    // utoa::@11
    // value = utoa_append(buffer++, value, digit_value)
    // [2517] utoa::value#0 = utoa_append::return#0
    // value = utoa_append(buffer++, value, digit_value);
    // [2518] utoa::buffer#4 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2510] phi from utoa::@11 to utoa::@9 [phi:utoa::@11->utoa::@9]
    // [2510] phi utoa::buffer#14 = utoa::buffer#4 [phi:utoa::@11->utoa::@9#0] -- register_copy 
    // [2510] phi utoa::started#4 = 1 [phi:utoa::@11->utoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [2510] phi utoa::value#6 = utoa::value#0 [phi:utoa::@11->utoa::@9#2] -- register_copy 
    jmp __b9
}
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
    // [2519] insertup::$0 = *((char *)&__conio+6) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+6
    inc
    sta.z insertup__0
    // unsigned char width = (__conio.width+1) * 2
    // [2520] insertup::width#0 = insertup::$0 << 1 -- vbuz1=vbuz1_rol_1 
    // {asm{.byte $db}}
    asl.z width
    // [2521] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [2521] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [2522] if(insertup::y#2<*((char *)&__conio+1)) goto insertup::@2 -- vbuz1_lt__deref_pbuc1_then_la1 
    lda.z y
    cmp __conio+1
    bcc __b2
    // [2523] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [2524] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [2525] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [2526] insertup::$4 = insertup::y#2 + 1 -- vbuz1=vbuz2_plus_1 
    lda.z y
    inc
    sta.z insertup__4
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [2527] insertup::$6 = insertup::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z insertup__6
    // [2528] insertup::$7 = insertup::$4 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z insertup__7
    // [2529] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z memcpy8_vram_vram.dbank_vram
    // [2530] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__6
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.doffset_vram+1
    // [2531] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z memcpy8_vram_vram.sbank_vram
    // [2532] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__7
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.soffset_vram+1
    // [2533] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbuz1=vbuz2 
    lda.z width
    sta.z memcpy8_vram_vram.num8_1
    // [2534] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [2535] insertup::y#1 = ++ insertup::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [2521] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [2521] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
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
    // [2536] clearline::$3 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z clearline__3
    // [2537] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwuz1=pwuc1_derefidx_vbuz2 
    tay
    lda __conio+$15,y
    sta.z addr
    lda __conio+$15+1,y
    sta.z addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2538] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [2539] clearline::$0 = byte0  clearline::addr#0 -- vbuz1=_byte0_vwuz2 
    lda.z addr
    sta.z clearline__0
    // *VERA_ADDRX_L = BYTE0(addr)
    // [2540] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [2541] clearline::$1 = byte1  clearline::addr#0 -- vbuz1=_byte1_vwuz2 
    lda.z addr+1
    sta.z clearline__1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [2542] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [2543] clearline::$2 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clearline__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [2544] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [2545] clearline::c#0 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z c
    // [2546] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [2546] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [2547] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [2548] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [2549] clearline::c#1 = -- clearline::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [2550] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b1
    // clearline::@return
    // }
    // [2551] return 
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
// __mem() char display_frame_maskxy(__mem() char x, __zp($f4) char y)
display_frame_maskxy: {
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__0 = $e3
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__1 = $6e
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__2 = $5b
    .label cpeekcxy1_y = $f4
    .label c = $54
    .label y = $f4
    // display_frame_maskxy::cpeekcxy1
    // gotoxy(x,y)
    // [2553] gotoxy::x#5 = display_frame_maskxy::cpeekcxy1_x#0 -- vbuz1=vbum2 
    lda cpeekcxy1_x
    sta.z gotoxy.x
    // [2554] gotoxy::y#5 = display_frame_maskxy::cpeekcxy1_y#0 -- vbuz1=vbuz2 
    lda.z cpeekcxy1_y
    sta.z gotoxy.y
    // [2555] call gotoxy
    // [756] phi from display_frame_maskxy::cpeekcxy1 to gotoxy [phi:display_frame_maskxy::cpeekcxy1->gotoxy]
    // [756] phi gotoxy::y#30 = gotoxy::y#5 [phi:display_frame_maskxy::cpeekcxy1->gotoxy#0] -- register_copy 
    // [756] phi gotoxy::x#30 = gotoxy::x#5 [phi:display_frame_maskxy::cpeekcxy1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_frame_maskxy::cpeekcxy1_cpeekc1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2556] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(__conio.offset)
    // [2557] display_frame_maskxy::cpeekcxy1_cpeekc1_$0 = byte0  *((unsigned int *)&__conio+$13) -- vbuz1=_byte0__deref_pwuc1 
    lda __conio+$13
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__0
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [2558] *VERA_ADDRX_L = display_frame_maskxy::cpeekcxy1_cpeekc1_$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [2559] display_frame_maskxy::cpeekcxy1_cpeekc1_$1 = byte1  *((unsigned int *)&__conio+$13) -- vbuz1=_byte1__deref_pwuc1 
    lda __conio+$13+1
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__1
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [2560] *VERA_ADDRX_M = display_frame_maskxy::cpeekcxy1_cpeekc1_$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_0
    // [2561] display_frame_maskxy::cpeekcxy1_cpeekc1_$2 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_0
    // [2562] *VERA_ADDRX_H = display_frame_maskxy::cpeekcxy1_cpeekc1_$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // return *VERA_DATA0;
    // [2563] display_frame_maskxy::c#0 = *VERA_DATA0 -- vbuz1=_deref_pbuc1 
    lda VERA_DATA0
    sta.z c
    // display_frame_maskxy::@12
    // case 0x70: // DR corner.
    //             return 0b0110;
    // [2564] if(display_frame_maskxy::c#0==$70) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$70
    cmp.z c
    beq __b2
    // display_frame_maskxy::@1
    // case 0x6E: // DL corner.
    //             return 0b0011;
    // [2565] if(display_frame_maskxy::c#0==$6e) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6e
    cmp.z c
    beq __b1
    // display_frame_maskxy::@2
    // case 0x6D: // UR corner.
    //             return 0b1100;
    // [2566] if(display_frame_maskxy::c#0==$6d) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6d
    cmp.z c
    beq __b3
    // display_frame_maskxy::@3
    // case 0x7D: // UL corner.
    //             return 0b1001;
    // [2567] if(display_frame_maskxy::c#0==$7d) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$7d
    cmp.z c
    beq __b4
    // display_frame_maskxy::@4
    // case 0x40: // HL line.
    //             return 0b0101;
    // [2568] if(display_frame_maskxy::c#0==$40) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$40
    cmp.z c
    beq __b5
    // display_frame_maskxy::@5
    // case 0x5D: // VL line.
    //             return 0b1010;
    // [2569] if(display_frame_maskxy::c#0==$5d) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$5d
    cmp.z c
    beq __b6
    // display_frame_maskxy::@6
    // case 0x6B: // VR junction.
    //             return 0b1110;
    // [2570] if(display_frame_maskxy::c#0==$6b) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6b
    cmp.z c
    beq __b7
    // display_frame_maskxy::@7
    // case 0x73: // VL junction.
    //             return 0b1011;
    // [2571] if(display_frame_maskxy::c#0==$73) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$73
    cmp.z c
    beq __b8
    // display_frame_maskxy::@8
    // case 0x72: // HD junction.
    //             return 0b0111;
    // [2572] if(display_frame_maskxy::c#0==$72) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$72
    cmp.z c
    beq __b9
    // display_frame_maskxy::@9
    // case 0x71: // HU junction.
    //             return 0b1101;
    // [2573] if(display_frame_maskxy::c#0==$71) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$71
    cmp.z c
    beq __b10
    // display_frame_maskxy::@10
    // case 0x5B: // HV junction.
    //             return 0b1111;
    // [2574] if(display_frame_maskxy::c#0==$5b) goto display_frame_maskxy::@11 -- vbuz1_eq_vbuc1_then_la1 
    lda #$5b
    cmp.z c
    beq __b11
    // [2576] phi from display_frame_maskxy::@10 to display_frame_maskxy::@return [phi:display_frame_maskxy::@10->display_frame_maskxy::@return]
    // [2576] phi display_frame_maskxy::return#12 = 0 [phi:display_frame_maskxy::@10->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    rts
    // [2575] phi from display_frame_maskxy::@10 to display_frame_maskxy::@11 [phi:display_frame_maskxy::@10->display_frame_maskxy::@11]
    // display_frame_maskxy::@11
  __b11:
    // [2576] phi from display_frame_maskxy::@11 to display_frame_maskxy::@return [phi:display_frame_maskxy::@11->display_frame_maskxy::@return]
    // [2576] phi display_frame_maskxy::return#12 = $f [phi:display_frame_maskxy::@11->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$f
    sta return
    rts
    // [2576] phi from display_frame_maskxy::@1 to display_frame_maskxy::@return [phi:display_frame_maskxy::@1->display_frame_maskxy::@return]
  __b1:
    // [2576] phi display_frame_maskxy::return#12 = 3 [phi:display_frame_maskxy::@1->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #3
    sta return
    rts
    // [2576] phi from display_frame_maskxy::@12 to display_frame_maskxy::@return [phi:display_frame_maskxy::@12->display_frame_maskxy::@return]
  __b2:
    // [2576] phi display_frame_maskxy::return#12 = 6 [phi:display_frame_maskxy::@12->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #6
    sta return
    rts
    // [2576] phi from display_frame_maskxy::@2 to display_frame_maskxy::@return [phi:display_frame_maskxy::@2->display_frame_maskxy::@return]
  __b3:
    // [2576] phi display_frame_maskxy::return#12 = $c [phi:display_frame_maskxy::@2->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$c
    sta return
    rts
    // [2576] phi from display_frame_maskxy::@3 to display_frame_maskxy::@return [phi:display_frame_maskxy::@3->display_frame_maskxy::@return]
  __b4:
    // [2576] phi display_frame_maskxy::return#12 = 9 [phi:display_frame_maskxy::@3->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #9
    sta return
    rts
    // [2576] phi from display_frame_maskxy::@4 to display_frame_maskxy::@return [phi:display_frame_maskxy::@4->display_frame_maskxy::@return]
  __b5:
    // [2576] phi display_frame_maskxy::return#12 = 5 [phi:display_frame_maskxy::@4->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #5
    sta return
    rts
    // [2576] phi from display_frame_maskxy::@5 to display_frame_maskxy::@return [phi:display_frame_maskxy::@5->display_frame_maskxy::@return]
  __b6:
    // [2576] phi display_frame_maskxy::return#12 = $a [phi:display_frame_maskxy::@5->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$a
    sta return
    rts
    // [2576] phi from display_frame_maskxy::@6 to display_frame_maskxy::@return [phi:display_frame_maskxy::@6->display_frame_maskxy::@return]
  __b7:
    // [2576] phi display_frame_maskxy::return#12 = $e [phi:display_frame_maskxy::@6->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$e
    sta return
    rts
    // [2576] phi from display_frame_maskxy::@7 to display_frame_maskxy::@return [phi:display_frame_maskxy::@7->display_frame_maskxy::@return]
  __b8:
    // [2576] phi display_frame_maskxy::return#12 = $b [phi:display_frame_maskxy::@7->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$b
    sta return
    rts
    // [2576] phi from display_frame_maskxy::@8 to display_frame_maskxy::@return [phi:display_frame_maskxy::@8->display_frame_maskxy::@return]
  __b9:
    // [2576] phi display_frame_maskxy::return#12 = 7 [phi:display_frame_maskxy::@8->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #7
    sta return
    rts
    // [2576] phi from display_frame_maskxy::@9 to display_frame_maskxy::@return [phi:display_frame_maskxy::@9->display_frame_maskxy::@return]
  __b10:
    // [2576] phi display_frame_maskxy::return#12 = $d [phi:display_frame_maskxy::@9->display_frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$d
    sta return
    // display_frame_maskxy::@return
    // }
    // [2577] return 
    rts
  .segment Data
    .label cpeekcxy1_x = rom_get_release.rom_get_release__0
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
    .label return = fopen.fopen__4
    .label x = rom_get_release.rom_get_release__0
}
.segment Code
  // display_frame_char
/**
 * @brief 
 * 
 * @param mask 
 * @return unsigned char 
 */
// __zp($d4) char display_frame_char(__mem() char mask)
display_frame_char: {
    .label return = $d4
    // case 0b0110:
    //             return 0x70;
    // [2579] if(display_frame_char::mask#10==6) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    lda #6
    cmp mask
    beq __b1
    // display_frame_char::@1
    // case 0b0011:
    //             return 0x6E;
    // [2580] if(display_frame_char::mask#10==3) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // DR corner.
    lda #3
    cmp mask
    beq __b2
    // display_frame_char::@2
    // case 0b1100:
    //             return 0x6D;
    // [2581] if(display_frame_char::mask#10==$c) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // DL corner.
    lda #$c
    cmp mask
    beq __b3
    // display_frame_char::@3
    // case 0b1001:
    //             return 0x7D;
    // [2582] if(display_frame_char::mask#10==9) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // UR corner.
    lda #9
    cmp mask
    beq __b4
    // display_frame_char::@4
    // case 0b0101:
    //             return 0x40;
    // [2583] if(display_frame_char::mask#10==5) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // UL corner.
    lda #5
    cmp mask
    beq __b5
    // display_frame_char::@5
    // case 0b1010:
    //             return 0x5D;
    // [2584] if(display_frame_char::mask#10==$a) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // HL line.
    lda #$a
    cmp mask
    beq __b6
    // display_frame_char::@6
    // case 0b1110:
    //             return 0x6B;
    // [2585] if(display_frame_char::mask#10==$e) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // VL line.
    lda #$e
    cmp mask
    beq __b7
    // display_frame_char::@7
    // case 0b1011:
    //             return 0x73;
    // [2586] if(display_frame_char::mask#10==$b) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // VR junction.
    lda #$b
    cmp mask
    beq __b8
    // display_frame_char::@8
    // case 0b0111:
    //             return 0x72;
    // [2587] if(display_frame_char::mask#10==7) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // VL junction.
    lda #7
    cmp mask
    beq __b9
    // display_frame_char::@9
    // case 0b1101:
    //             return 0x71;
    // [2588] if(display_frame_char::mask#10==$d) goto display_frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // HD junction.
    lda #$d
    cmp mask
    beq __b10
    // display_frame_char::@10
    // case 0b1111:
    //             return 0x5B;
    // [2589] if(display_frame_char::mask#10==$f) goto display_frame_char::@11 -- vbum1_eq_vbuc1_then_la1 
    // HU junction.
    lda #$f
    cmp mask
    beq __b11
    // [2591] phi from display_frame_char::@10 to display_frame_char::@return [phi:display_frame_char::@10->display_frame_char::@return]
    // [2591] phi display_frame_char::return#12 = $20 [phi:display_frame_char::@10->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$20
    sta.z return
    rts
    // [2590] phi from display_frame_char::@10 to display_frame_char::@11 [phi:display_frame_char::@10->display_frame_char::@11]
    // display_frame_char::@11
  __b11:
    // [2591] phi from display_frame_char::@11 to display_frame_char::@return [phi:display_frame_char::@11->display_frame_char::@return]
    // [2591] phi display_frame_char::return#12 = $5b [phi:display_frame_char::@11->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z return
    rts
    // [2591] phi from display_frame_char to display_frame_char::@return [phi:display_frame_char->display_frame_char::@return]
  __b1:
    // [2591] phi display_frame_char::return#12 = $70 [phi:display_frame_char->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$70
    sta.z return
    rts
    // [2591] phi from display_frame_char::@1 to display_frame_char::@return [phi:display_frame_char::@1->display_frame_char::@return]
  __b2:
    // [2591] phi display_frame_char::return#12 = $6e [phi:display_frame_char::@1->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6e
    sta.z return
    rts
    // [2591] phi from display_frame_char::@2 to display_frame_char::@return [phi:display_frame_char::@2->display_frame_char::@return]
  __b3:
    // [2591] phi display_frame_char::return#12 = $6d [phi:display_frame_char::@2->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6d
    sta.z return
    rts
    // [2591] phi from display_frame_char::@3 to display_frame_char::@return [phi:display_frame_char::@3->display_frame_char::@return]
  __b4:
    // [2591] phi display_frame_char::return#12 = $7d [phi:display_frame_char::@3->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$7d
    sta.z return
    rts
    // [2591] phi from display_frame_char::@4 to display_frame_char::@return [phi:display_frame_char::@4->display_frame_char::@return]
  __b5:
    // [2591] phi display_frame_char::return#12 = $40 [phi:display_frame_char::@4->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z return
    rts
    // [2591] phi from display_frame_char::@5 to display_frame_char::@return [phi:display_frame_char::@5->display_frame_char::@return]
  __b6:
    // [2591] phi display_frame_char::return#12 = $5d [phi:display_frame_char::@5->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z return
    rts
    // [2591] phi from display_frame_char::@6 to display_frame_char::@return [phi:display_frame_char::@6->display_frame_char::@return]
  __b7:
    // [2591] phi display_frame_char::return#12 = $6b [phi:display_frame_char::@6->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z return
    rts
    // [2591] phi from display_frame_char::@7 to display_frame_char::@return [phi:display_frame_char::@7->display_frame_char::@return]
  __b8:
    // [2591] phi display_frame_char::return#12 = $73 [phi:display_frame_char::@7->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z return
    rts
    // [2591] phi from display_frame_char::@8 to display_frame_char::@return [phi:display_frame_char::@8->display_frame_char::@return]
  __b9:
    // [2591] phi display_frame_char::return#12 = $72 [phi:display_frame_char::@8->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z return
    rts
    // [2591] phi from display_frame_char::@9 to display_frame_char::@return [phi:display_frame_char::@9->display_frame_char::@return]
  __b10:
    // [2591] phi display_frame_char::return#12 = $71 [phi:display_frame_char::@9->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z return
    // display_frame_char::@return
    // }
    // [2592] return 
    rts
  .segment Data
    .label mask = fopen.fopen__4
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
// void display_chip_led(__zp($5c) char x, char y, __zp($d5) char w, __zp($c5) char tc, char bc)
display_chip_led: {
    .label x = $5c
    .label w = $d5
    .label tc = $c5
    // textcolor(tc)
    // [2594] textcolor::color#11 = display_chip_led::tc#3 -- vbuz1=vbuz2 
    lda.z tc
    sta.z textcolor.color
    // [2595] call textcolor
    // [738] phi from display_chip_led to textcolor [phi:display_chip_led->textcolor]
    // [738] phi textcolor::color#18 = textcolor::color#11 [phi:display_chip_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [2596] phi from display_chip_led to display_chip_led::@3 [phi:display_chip_led->display_chip_led::@3]
    // display_chip_led::@3
    // bgcolor(bc)
    // [2597] call bgcolor
    // [743] phi from display_chip_led::@3 to bgcolor [phi:display_chip_led::@3->bgcolor]
    // [743] phi bgcolor::color#14 = BLUE [phi:display_chip_led::@3->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [2598] phi from display_chip_led::@3 display_chip_led::@5 to display_chip_led::@1 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1]
    // [2598] phi display_chip_led::w#4 = display_chip_led::w#7 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1#0] -- register_copy 
    // [2598] phi display_chip_led::x#4 = display_chip_led::x#7 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1#1] -- register_copy 
    // display_chip_led::@1
  __b1:
    // cputcxy(x, y, 0x6F)
    // [2599] cputcxy::x#9 = display_chip_led::x#4 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [2600] call cputcxy
    // [2039] phi from display_chip_led::@1 to cputcxy [phi:display_chip_led::@1->cputcxy]
    // [2039] phi cputcxy::c#15 = $6f [phi:display_chip_led::@1->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6f
    sta.z cputcxy.c
    // [2039] phi cputcxy::y#15 = 3 [phi:display_chip_led::@1->cputcxy#1] -- vbuz1=vbuc1 
    lda #3
    sta.z cputcxy.y
    // [2039] phi cputcxy::x#15 = cputcxy::x#9 [phi:display_chip_led::@1->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_led::@4
    // cputcxy(x, y+1, 0x77)
    // [2601] cputcxy::x#10 = display_chip_led::x#4 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [2602] call cputcxy
    // [2039] phi from display_chip_led::@4 to cputcxy [phi:display_chip_led::@4->cputcxy]
    // [2039] phi cputcxy::c#15 = $77 [phi:display_chip_led::@4->cputcxy#0] -- vbuz1=vbuc1 
    lda #$77
    sta.z cputcxy.c
    // [2039] phi cputcxy::y#15 = 3+1 [phi:display_chip_led::@4->cputcxy#1] -- vbuz1=vbuc1 
    lda #3+1
    sta.z cputcxy.y
    // [2039] phi cputcxy::x#15 = cputcxy::x#10 [phi:display_chip_led::@4->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_led::@5
    // x++;
    // [2603] display_chip_led::x#0 = ++ display_chip_led::x#4 -- vbuz1=_inc_vbuz1 
    inc.z x
    // while(--w)
    // [2604] display_chip_led::w#0 = -- display_chip_led::w#4 -- vbuz1=_dec_vbuz1 
    dec.z w
    // [2605] if(0!=display_chip_led::w#0) goto display_chip_led::@1 -- 0_neq_vbuz1_then_la1 
    lda.z w
    bne __b1
    // [2606] phi from display_chip_led::@5 to display_chip_led::@2 [phi:display_chip_led::@5->display_chip_led::@2]
    // display_chip_led::@2
    // textcolor(WHITE)
    // [2607] call textcolor
    // [738] phi from display_chip_led::@2 to textcolor [phi:display_chip_led::@2->textcolor]
    // [738] phi textcolor::color#18 = WHITE [phi:display_chip_led::@2->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [2608] phi from display_chip_led::@2 to display_chip_led::@6 [phi:display_chip_led::@2->display_chip_led::@6]
    // display_chip_led::@6
    // bgcolor(BLUE)
    // [2609] call bgcolor
    // [743] phi from display_chip_led::@6 to bgcolor [phi:display_chip_led::@6->bgcolor]
    // [743] phi bgcolor::color#14 = BLUE [phi:display_chip_led::@6->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // display_chip_led::@return
    // }
    // [2610] return 
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
// void display_chip_line(__zp($c5) char x, __zp($ef) char y, __zp($d6) char w, __zp($d3) char c)
display_chip_line: {
    .label i = $c2
    .label x = $c5
    .label w = $d6
    .label c = $d3
    .label y = $ef
    // gotoxy(x, y)
    // [2612] gotoxy::x#7 = display_chip_line::x#16 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [2613] gotoxy::y#7 = display_chip_line::y#16 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [2614] call gotoxy
    // [756] phi from display_chip_line to gotoxy [phi:display_chip_line->gotoxy]
    // [756] phi gotoxy::y#30 = gotoxy::y#7 [phi:display_chip_line->gotoxy#0] -- register_copy 
    // [756] phi gotoxy::x#30 = gotoxy::x#7 [phi:display_chip_line->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [2615] phi from display_chip_line to display_chip_line::@4 [phi:display_chip_line->display_chip_line::@4]
    // display_chip_line::@4
    // textcolor(GREY)
    // [2616] call textcolor
    // [738] phi from display_chip_line::@4 to textcolor [phi:display_chip_line::@4->textcolor]
    // [738] phi textcolor::color#18 = GREY [phi:display_chip_line::@4->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [2617] phi from display_chip_line::@4 to display_chip_line::@5 [phi:display_chip_line::@4->display_chip_line::@5]
    // display_chip_line::@5
    // bgcolor(BLUE)
    // [2618] call bgcolor
    // [743] phi from display_chip_line::@5 to bgcolor [phi:display_chip_line::@5->bgcolor]
    // [743] phi bgcolor::color#14 = BLUE [phi:display_chip_line::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // display_chip_line::@6
    // cputc(VERA_CHR_UR)
    // [2619] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [2620] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [2622] call textcolor
    // [738] phi from display_chip_line::@6 to textcolor [phi:display_chip_line::@6->textcolor]
    // [738] phi textcolor::color#18 = WHITE [phi:display_chip_line::@6->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [2623] phi from display_chip_line::@6 to display_chip_line::@7 [phi:display_chip_line::@6->display_chip_line::@7]
    // display_chip_line::@7
    // bgcolor(BLACK)
    // [2624] call bgcolor
    // [743] phi from display_chip_line::@7 to bgcolor [phi:display_chip_line::@7->bgcolor]
    // [743] phi bgcolor::color#14 = BLACK [phi:display_chip_line::@7->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // [2625] phi from display_chip_line::@7 to display_chip_line::@1 [phi:display_chip_line::@7->display_chip_line::@1]
    // [2625] phi display_chip_line::i#2 = 0 [phi:display_chip_line::@7->display_chip_line::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // display_chip_line::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [2626] if(display_chip_line::i#2<display_chip_line::w#10) goto display_chip_line::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [2627] phi from display_chip_line::@1 to display_chip_line::@3 [phi:display_chip_line::@1->display_chip_line::@3]
    // display_chip_line::@3
    // textcolor(GREY)
    // [2628] call textcolor
    // [738] phi from display_chip_line::@3 to textcolor [phi:display_chip_line::@3->textcolor]
    // [738] phi textcolor::color#18 = GREY [phi:display_chip_line::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [2629] phi from display_chip_line::@3 to display_chip_line::@8 [phi:display_chip_line::@3->display_chip_line::@8]
    // display_chip_line::@8
    // bgcolor(BLUE)
    // [2630] call bgcolor
    // [743] phi from display_chip_line::@8 to bgcolor [phi:display_chip_line::@8->bgcolor]
    // [743] phi bgcolor::color#14 = BLUE [phi:display_chip_line::@8->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // display_chip_line::@9
    // cputc(VERA_CHR_UL)
    // [2631] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [2632] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [2634] call textcolor
    // [738] phi from display_chip_line::@9 to textcolor [phi:display_chip_line::@9->textcolor]
    // [738] phi textcolor::color#18 = WHITE [phi:display_chip_line::@9->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [2635] phi from display_chip_line::@9 to display_chip_line::@10 [phi:display_chip_line::@9->display_chip_line::@10]
    // display_chip_line::@10
    // bgcolor(BLACK)
    // [2636] call bgcolor
    // [743] phi from display_chip_line::@10 to bgcolor [phi:display_chip_line::@10->bgcolor]
    // [743] phi bgcolor::color#14 = BLACK [phi:display_chip_line::@10->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // display_chip_line::@11
    // cputcxy(x+2, y, c)
    // [2637] cputcxy::x#8 = display_chip_line::x#16 + 2 -- vbuz1=vbuz2_plus_2 
    lda.z x
    clc
    adc #2
    sta.z cputcxy.x
    // [2638] cputcxy::y#8 = display_chip_line::y#16 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [2639] cputcxy::c#8 = display_chip_line::c#15 -- vbuz1=vbuz2 
    lda.z c
    sta.z cputcxy.c
    // [2640] call cputcxy
    // [2039] phi from display_chip_line::@11 to cputcxy [phi:display_chip_line::@11->cputcxy]
    // [2039] phi cputcxy::c#15 = cputcxy::c#8 [phi:display_chip_line::@11->cputcxy#0] -- register_copy 
    // [2039] phi cputcxy::y#15 = cputcxy::y#8 [phi:display_chip_line::@11->cputcxy#1] -- register_copy 
    // [2039] phi cputcxy::x#15 = cputcxy::x#8 [phi:display_chip_line::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_line::@return
    // }
    // [2641] return 
    rts
    // display_chip_line::@2
  __b2:
    // cputc(VERA_CHR_SPACE)
    // [2642] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [2643] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [2645] display_chip_line::i#1 = ++ display_chip_line::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [2625] phi from display_chip_line::@2 to display_chip_line::@1 [phi:display_chip_line::@2->display_chip_line::@1]
    // [2625] phi display_chip_line::i#2 = display_chip_line::i#1 [phi:display_chip_line::@2->display_chip_line::@1#0] -- register_copy 
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
// void display_chip_end(__zp($df) char x, char y, __zp($2c) char w)
display_chip_end: {
    .label i = $36
    .label x = $df
    .label w = $2c
    // gotoxy(x, y)
    // [2646] gotoxy::x#8 = display_chip_end::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [2647] call gotoxy
    // [756] phi from display_chip_end to gotoxy [phi:display_chip_end->gotoxy]
    // [756] phi gotoxy::y#30 = display_print_chip::y#21 [phi:display_chip_end->gotoxy#0] -- vbuz1=vbuc1 
    lda #display_print_chip.y
    sta.z gotoxy.y
    // [756] phi gotoxy::x#30 = gotoxy::x#8 [phi:display_chip_end->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [2648] phi from display_chip_end to display_chip_end::@4 [phi:display_chip_end->display_chip_end::@4]
    // display_chip_end::@4
    // textcolor(GREY)
    // [2649] call textcolor
    // [738] phi from display_chip_end::@4 to textcolor [phi:display_chip_end::@4->textcolor]
    // [738] phi textcolor::color#18 = GREY [phi:display_chip_end::@4->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [2650] phi from display_chip_end::@4 to display_chip_end::@5 [phi:display_chip_end::@4->display_chip_end::@5]
    // display_chip_end::@5
    // bgcolor(BLUE)
    // [2651] call bgcolor
    // [743] phi from display_chip_end::@5 to bgcolor [phi:display_chip_end::@5->bgcolor]
    // [743] phi bgcolor::color#14 = BLUE [phi:display_chip_end::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // display_chip_end::@6
    // cputc(VERA_CHR_UR)
    // [2652] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [2653] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [2655] call textcolor
    // [738] phi from display_chip_end::@6 to textcolor [phi:display_chip_end::@6->textcolor]
    // [738] phi textcolor::color#18 = BLUE [phi:display_chip_end::@6->textcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z textcolor.color
    jsr textcolor
    // [2656] phi from display_chip_end::@6 to display_chip_end::@7 [phi:display_chip_end::@6->display_chip_end::@7]
    // display_chip_end::@7
    // bgcolor(BLACK)
    // [2657] call bgcolor
    // [743] phi from display_chip_end::@7 to bgcolor [phi:display_chip_end::@7->bgcolor]
    // [743] phi bgcolor::color#14 = BLACK [phi:display_chip_end::@7->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // [2658] phi from display_chip_end::@7 to display_chip_end::@1 [phi:display_chip_end::@7->display_chip_end::@1]
    // [2658] phi display_chip_end::i#2 = 0 [phi:display_chip_end::@7->display_chip_end::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // display_chip_end::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [2659] if(display_chip_end::i#2<display_chip_end::w#0) goto display_chip_end::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [2660] phi from display_chip_end::@1 to display_chip_end::@3 [phi:display_chip_end::@1->display_chip_end::@3]
    // display_chip_end::@3
    // textcolor(GREY)
    // [2661] call textcolor
    // [738] phi from display_chip_end::@3 to textcolor [phi:display_chip_end::@3->textcolor]
    // [738] phi textcolor::color#18 = GREY [phi:display_chip_end::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [2662] phi from display_chip_end::@3 to display_chip_end::@8 [phi:display_chip_end::@3->display_chip_end::@8]
    // display_chip_end::@8
    // bgcolor(BLUE)
    // [2663] call bgcolor
    // [743] phi from display_chip_end::@8 to bgcolor [phi:display_chip_end::@8->bgcolor]
    // [743] phi bgcolor::color#14 = BLUE [phi:display_chip_end::@8->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // display_chip_end::@9
    // cputc(VERA_CHR_UL)
    // [2664] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [2665] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_chip_end::@return
    // }
    // [2667] return 
    rts
    // display_chip_end::@2
  __b2:
    // cputc(VERA_CHR_HL)
    // [2668] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [2669] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [2671] display_chip_end::i#1 = ++ display_chip_end::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [2658] phi from display_chip_end::@2 to display_chip_end::@1 [phi:display_chip_end::@2->display_chip_end::@1]
    // [2658] phi display_chip_end::i#2 = display_chip_end::i#1 [phi:display_chip_end::@2->display_chip_end::@1#0] -- register_copy 
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
    // [2673] rom_write_byte::rom_bank1_$0 = byte2  rom_write_byte::address#4 -- vbuz1=_byte2_vduz2 
    lda.z address+2
    sta.z rom_bank1_rom_write_byte__0
    // BYTE1(address)
    // [2674] rom_write_byte::rom_bank1_$1 = byte1  rom_write_byte::address#4 -- vbuz1=_byte1_vduz2 
    lda.z address+1
    sta.z rom_bank1_rom_write_byte__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2675] rom_write_byte::rom_bank1_$2 = rom_write_byte::rom_bank1_$0 w= rom_write_byte::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_write_byte__0
    sta.z rom_bank1_rom_write_byte__2+1
    lda.z rom_bank1_rom_write_byte__1
    sta.z rom_bank1_rom_write_byte__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2676] rom_write_byte::rom_bank1_bank_unshifted#0 = rom_write_byte::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2677] rom_write_byte::rom_bank1_return#0 = byte1  rom_write_byte::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwuz2 
    lda.z rom_bank1_bank_unshifted+1
    sta.z rom_bank1_return
    // rom_write_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2678] rom_write_byte::rom_ptr1_$2 = (unsigned int)rom_write_byte::address#4 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_write_byte__2
    lda.z address+1
    sta.z rom_ptr1_rom_write_byte__2+1
    // [2679] rom_write_byte::rom_ptr1_$0 = rom_write_byte::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_write_byte__0
    and #<$3fff
    sta.z rom_ptr1_rom_write_byte__0
    lda.z rom_ptr1_rom_write_byte__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_write_byte__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2680] rom_write_byte::rom_ptr1_return#0 = rom_write_byte::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_write_byte::bank_set_brom1
    // BROM = bank
    // [2681] BROM = rom_write_byte::rom_bank1_return#0 -- vbuz1=vbuz2 
    lda.z rom_bank1_return
    sta.z BROM
    // rom_write_byte::@1
    // *ptr_rom = value
    // [2682] *((char *)rom_write_byte::rom_ptr1_return#0) = rom_write_byte::value#10 -- _deref_pbuz1=vbuz2 
    lda.z value
    ldy #0
    sta (rom_ptr1_return),y
    // rom_write_byte::@return
    // }
    // [2683] return 
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
    // [2685] return 
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
// __mem() int ferror(__zp($d7) struct $2 *stream)
ferror: {
    .label ferror__6 = $38
    .label ferror__15 = $ef
    .label cbm_k_setnam1_ferror__0 = $55
    .label cbm_k_readst1_status = $fb
    .label stream = $d7
    .label sp = $5d
    .label cbm_k_chrin1_return = $ef
    .label ch = $ef
    .label cbm_k_readst1_return = $38
    .label st = $38
    .label errno_len = $d6
    .label cbm_k_chrin2_return = $ef
    .label errno_parsed = $d5
    // unsigned char sp = (unsigned char)stream
    // [2686] ferror::sp#0 = (char)ferror::stream#0 -- vbuz1=_byte_pssz2 
    lda.z stream
    sta.z sp
    // cbm_k_setlfs(15, 8, 15)
    // [2687] cbm_k_setlfs::channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.channel
    // [2688] cbm_k_setlfs::device = 8 -- vbum1=vbuc1 
    lda #8
    sta cbm_k_setlfs.device
    // [2689] cbm_k_setlfs::command = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.command
    // [2690] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // ferror::@11
    // cbm_k_setnam("")
    // [2691] ferror::cbm_k_setnam1_filename = info_text4 -- pbum1=pbuc1 
    lda #<info_text4
    sta cbm_k_setnam1_filename
    lda #>info_text4
    sta cbm_k_setnam1_filename+1
    // ferror::cbm_k_setnam1
    // strlen(filename)
    // [2692] strlen::str#5 = ferror::cbm_k_setnam1_filename -- pbuz1=pbum2 
    lda cbm_k_setnam1_filename
    sta.z strlen.str
    lda cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [2693] call strlen
    // [2315] phi from ferror::cbm_k_setnam1 to strlen [phi:ferror::cbm_k_setnam1->strlen]
    // [2315] phi strlen::str#8 = strlen::str#5 [phi:ferror::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [2694] strlen::return#12 = strlen::len#2
    // ferror::@12
    // [2695] ferror::cbm_k_setnam1_$0 = strlen::return#12
    // char filename_len = (char)strlen(filename)
    // [2696] ferror::cbm_k_setnam1_filename_len = (char)ferror::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
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
    // [2699] ferror::cbm_k_chkin1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_chkin1_channel
    // ferror::cbm_k_chkin1
    // char status
    // [2700] ferror::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // ferror::cbm_k_chrin1
    // char ch
    // [2702] ferror::cbm_k_chrin1_ch = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chrin1_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin1_ch
    // return ch;
    // [2704] ferror::cbm_k_chrin1_return#0 = ferror::cbm_k_chrin1_ch -- vbuz1=vbum2 
    sta.z cbm_k_chrin1_return
    // ferror::cbm_k_chrin1_@return
    // }
    // [2705] ferror::cbm_k_chrin1_return#1 = ferror::cbm_k_chrin1_return#0
    // ferror::@7
    // char ch = cbm_k_chrin()
    // [2706] ferror::ch#0 = ferror::cbm_k_chrin1_return#1
    // [2707] phi from ferror::@7 to ferror::cbm_k_readst1 [phi:ferror::@7->ferror::cbm_k_readst1]
    // [2707] phi __errno#18 = __errno#318 [phi:ferror::@7->ferror::cbm_k_readst1#0] -- register_copy 
    // [2707] phi ferror::errno_len#10 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z errno_len
    // [2707] phi ferror::ch#10 = ferror::ch#0 [phi:ferror::@7->ferror::cbm_k_readst1#2] -- register_copy 
    // [2707] phi ferror::errno_parsed#2 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#3] -- vbuz1=vbuc1 
    sta.z errno_parsed
    // ferror::cbm_k_readst1
  cbm_k_readst1:
    // char status
    // [2708] ferror::cbm_k_readst1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2710] ferror::cbm_k_readst1_return#0 = ferror::cbm_k_readst1_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst1_return
    // ferror::cbm_k_readst1_@return
    // }
    // [2711] ferror::cbm_k_readst1_return#1 = ferror::cbm_k_readst1_return#0
    // ferror::@8
    // cbm_k_readst()
    // [2712] ferror::$6 = ferror::cbm_k_readst1_return#1
    // st = cbm_k_readst()
    // [2713] ferror::st#1 = ferror::$6
    // while (!(st = cbm_k_readst()))
    // [2714] if(0==ferror::st#1) goto ferror::@1 -- 0_eq_vbuz1_then_la1 
    lda.z st
    beq __b1
    // ferror::@2
    // __status = st
    // [2715] ((char *)&__stdio_file+$46)[ferror::sp#0] = ferror::st#1 -- pbuc1_derefidx_vbuz1=vbuz2 
    ldy.z sp
    sta __stdio_file+$46,y
    // cbm_k_close(15)
    // [2716] ferror::cbm_k_close1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_close1_channel
    // ferror::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // ferror::@9
    // return __errno;
    // [2718] ferror::return#1 = __errno#18 -- vwsm1=vwsz2 
    lda.z __errno
    sta return
    lda.z __errno+1
    sta return+1
    // ferror::@return
    // }
    // [2719] return 
    rts
    // ferror::@1
  __b1:
    // if (!errno_parsed)
    // [2720] if(0!=ferror::errno_parsed#2) goto ferror::@3 -- 0_neq_vbuz1_then_la1 
    lda.z errno_parsed
    bne __b3
    // ferror::@4
    // if (ch == ',')
    // [2721] if(ferror::ch#10!=',') goto ferror::@3 -- vbuz1_neq_vbuc1_then_la1 
    lda #','
    cmp.z ch
    bne __b3
    // ferror::@5
    // errno_parsed++;
    // [2722] ferror::errno_parsed#1 = ++ ferror::errno_parsed#2 -- vbuz1=_inc_vbuz1 
    inc.z errno_parsed
    // strncpy(temp, __errno_error, errno_len+1)
    // [2723] strncpy::n#0 = ferror::errno_len#10 + 1 -- vwuz1=vbuz2_plus_1 
    lda.z errno_len
    clc
    adc #1
    sta.z strncpy.n
    lda #0
    adc #0
    sta.z strncpy.n+1
    // [2724] call strncpy
    // [2478] phi from ferror::@5 to strncpy [phi:ferror::@5->strncpy]
    // [2478] phi strncpy::dst#8 = ferror::temp [phi:ferror::@5->strncpy#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z strncpy.dst
    lda #>temp
    sta.z strncpy.dst+1
    // [2478] phi strncpy::src#6 = __errno_error [phi:ferror::@5->strncpy#1] -- pbuz1=pbuc1 
    lda #<__errno_error
    sta.z strncpy.src
    lda #>__errno_error
    sta.z strncpy.src+1
    // [2478] phi strncpy::n#3 = strncpy::n#0 [phi:ferror::@5->strncpy#2] -- register_copy 
    jsr strncpy
    // [2725] phi from ferror::@5 to ferror::@13 [phi:ferror::@5->ferror::@13]
    // ferror::@13
    // atoi(temp)
    // [2726] call atoi
    // [2738] phi from ferror::@13 to atoi [phi:ferror::@13->atoi]
    // [2738] phi atoi::str#2 = ferror::temp [phi:ferror::@13->atoi#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z atoi.str
    lda #>temp
    sta.z atoi.str+1
    jsr atoi
    // atoi(temp)
    // [2727] atoi::return#4 = atoi::return#2
    // ferror::@14
    // __errno = atoi(temp)
    // [2728] __errno#2 = atoi::return#4 -- vwsz1=vwsz2 
    lda.z atoi.return
    sta.z __errno
    lda.z atoi.return+1
    sta.z __errno+1
    // [2729] phi from ferror::@1 ferror::@14 ferror::@4 to ferror::@3 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3]
    // [2729] phi __errno#105 = __errno#18 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#0] -- register_copy 
    // [2729] phi ferror::errno_parsed#11 = ferror::errno_parsed#2 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#1] -- register_copy 
    // ferror::@3
  __b3:
    // __errno_error[errno_len] = ch
    // [2730] __errno_error[ferror::errno_len#10] = ferror::ch#10 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z ch
    ldy.z errno_len
    sta __errno_error,y
    // errno_len++;
    // [2731] ferror::errno_len#1 = ++ ferror::errno_len#10 -- vbuz1=_inc_vbuz1 
    inc.z errno_len
    // ferror::cbm_k_chrin2
    // char ch
    // [2732] ferror::cbm_k_chrin2_ch = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chrin2_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin2_ch
    // return ch;
    // [2734] ferror::cbm_k_chrin2_return#0 = ferror::cbm_k_chrin2_ch -- vbuz1=vbum2 
    sta.z cbm_k_chrin2_return
    // ferror::cbm_k_chrin2_@return
    // }
    // [2735] ferror::cbm_k_chrin2_return#1 = ferror::cbm_k_chrin2_return#0
    // ferror::@10
    // cbm_k_chrin()
    // [2736] ferror::$15 = ferror::cbm_k_chrin2_return#1
    // ch = cbm_k_chrin()
    // [2737] ferror::ch#1 = ferror::$15
    // [2707] phi from ferror::@10 to ferror::cbm_k_readst1 [phi:ferror::@10->ferror::cbm_k_readst1]
    // [2707] phi __errno#18 = __errno#105 [phi:ferror::@10->ferror::cbm_k_readst1#0] -- register_copy 
    // [2707] phi ferror::errno_len#10 = ferror::errno_len#1 [phi:ferror::@10->ferror::cbm_k_readst1#1] -- register_copy 
    // [2707] phi ferror::ch#10 = ferror::ch#1 [phi:ferror::@10->ferror::cbm_k_readst1#2] -- register_copy 
    // [2707] phi ferror::errno_parsed#2 = ferror::errno_parsed#11 [phi:ferror::@10->ferror::cbm_k_readst1#3] -- register_copy 
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
    return: .word 0
}
.segment Code
  // atoi
// Converts the string argument str to an integer.
// __zp($64) int atoi(__zp($db) const char *str)
atoi: {
    .label atoi__6 = $64
    .label atoi__7 = $64
    .label res = $64
    // Initialize sign as positive
    .label i = $d3
    .label return = $64
    .label str = $db
    // Initialize result
    .label negative = $c2
    .label atoi__10 = $4d
    .label atoi__11 = $64
    // if (str[i] == '-')
    // [2739] if(*atoi::str#2!='-') goto atoi::@3 -- _deref_pbuz1_neq_vbuc1_then_la1 
    ldy #0
    lda (str),y
    cmp #'-'
    bne __b2
    // [2740] phi from atoi to atoi::@2 [phi:atoi->atoi::@2]
    // atoi::@2
    // [2741] phi from atoi::@2 to atoi::@3 [phi:atoi::@2->atoi::@3]
    // [2741] phi atoi::negative#2 = 1 [phi:atoi::@2->atoi::@3#0] -- vbuz1=vbuc1 
    lda #1
    sta.z negative
    // [2741] phi atoi::res#2 = 0 [phi:atoi::@2->atoi::@3#1] -- vwsz1=vwsc1 
    tya
    sta.z res
    sta.z res+1
    // [2741] phi atoi::i#4 = 1 [phi:atoi::@2->atoi::@3#2] -- vbuz1=vbuc1 
    lda #1
    sta.z i
    jmp __b3
  // Iterate through all digits and update the result
    // [2741] phi from atoi to atoi::@3 [phi:atoi->atoi::@3]
  __b2:
    // [2741] phi atoi::negative#2 = 0 [phi:atoi->atoi::@3#0] -- vbuz1=vbuc1 
    lda #0
    sta.z negative
    // [2741] phi atoi::res#2 = 0 [phi:atoi->atoi::@3#1] -- vwsz1=vwsc1 
    sta.z res
    sta.z res+1
    // [2741] phi atoi::i#4 = 0 [phi:atoi->atoi::@3#2] -- vbuz1=vbuc1 
    sta.z i
    // atoi::@3
  __b3:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [2742] if(atoi::str#2[atoi::i#4]<'0') goto atoi::@5 -- pbuz1_derefidx_vbuz2_lt_vbuc1_then_la1 
    ldy.z i
    lda (str),y
    cmp #'0'
    bcc __b5
    // atoi::@6
    // [2743] if(atoi::str#2[atoi::i#4]<='9') goto atoi::@4 -- pbuz1_derefidx_vbuz2_le_vbuc1_then_la1 
    lda (str),y
    cmp #'9'
    bcc __b4
    beq __b4
    // atoi::@5
  __b5:
    // if(negative)
    // [2744] if(0!=atoi::negative#2) goto atoi::@1 -- 0_neq_vbuz1_then_la1 
    // Return result with sign
    lda.z negative
    bne __b1
    // [2746] phi from atoi::@1 atoi::@5 to atoi::@return [phi:atoi::@1/atoi::@5->atoi::@return]
    // [2746] phi atoi::return#2 = atoi::return#0 [phi:atoi::@1/atoi::@5->atoi::@return#0] -- register_copy 
    rts
    // atoi::@1
  __b1:
    // return -res;
    // [2745] atoi::return#0 = - atoi::res#2 -- vwsz1=_neg_vwsz1 
    lda #0
    sec
    sbc.z return
    sta.z return
    lda #0
    sbc.z return+1
    sta.z return+1
    // atoi::@return
    // }
    // [2747] return 
    rts
    // atoi::@4
  __b4:
    // res * 10
    // [2748] atoi::$10 = atoi::res#2 << 2 -- vwsz1=vwsz2_rol_2 
    lda.z res
    asl
    sta.z atoi__10
    lda.z res+1
    rol
    sta.z atoi__10+1
    asl.z atoi__10
    rol.z atoi__10+1
    // [2749] atoi::$11 = atoi::$10 + atoi::res#2 -- vwsz1=vwsz2_plus_vwsz1 
    clc
    lda.z atoi__11
    adc.z atoi__10
    sta.z atoi__11
    lda.z atoi__11+1
    adc.z atoi__10+1
    sta.z atoi__11+1
    // [2750] atoi::$6 = atoi::$11 << 1 -- vwsz1=vwsz1_rol_1 
    asl.z atoi__6
    rol.z atoi__6+1
    // res * 10 + str[i]
    // [2751] atoi::$7 = atoi::$6 + atoi::str#2[atoi::i#4] -- vwsz1=vwsz1_plus_pbuz2_derefidx_vbuz3 
    ldy.z i
    lda.z atoi__7
    clc
    adc (str),y
    sta.z atoi__7
    bcc !+
    inc.z atoi__7+1
  !:
    // res = res * 10 + str[i] - '0'
    // [2752] atoi::res#1 = atoi::$7 - '0' -- vwsz1=vwsz1_minus_vbuc1 
    lda.z res
    sec
    sbc #'0'
    sta.z res
    bcs !+
    dec.z res+1
  !:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [2753] atoi::i#2 = ++ atoi::i#4 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [2741] phi from atoi::@4 to atoi::@3 [phi:atoi::@4->atoi::@3]
    // [2741] phi atoi::negative#2 = atoi::negative#2 [phi:atoi::@4->atoi::@3#0] -- register_copy 
    // [2741] phi atoi::res#2 = atoi::res#1 [phi:atoi::@4->atoi::@3#1] -- register_copy 
    // [2741] phi atoi::i#4 = atoi::i#2 [phi:atoi::@4->atoi::@3#2] -- register_copy 
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
// __zp($7c) unsigned int cx16_k_macptr(__zp($d0) volatile char bytes, __zp($cb) void * volatile buffer)
cx16_k_macptr: {
    .label bytes = $d0
    .label buffer = $cb
    .label bytes_read = $b8
    .label return = $7c
    // unsigned int bytes_read
    // [2754] cx16_k_macptr::bytes_read = 0 -- vwuz1=vwuc1 
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
    // [2756] cx16_k_macptr::return#0 = cx16_k_macptr::bytes_read -- vwuz1=vwuz2 
    lda.z bytes_read
    sta.z return
    lda.z bytes_read+1
    sta.z return+1
    // cx16_k_macptr::@return
    // }
    // [2757] cx16_k_macptr::return#1 = cx16_k_macptr::return#0
    // [2758] return 
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
// __zp($2f) char uctoa_append(__zp($74) char *buffer, __zp($2f) char value, __zp($45) char sub)
uctoa_append: {
    .label buffer = $74
    .label value = $2f
    .label sub = $45
    .label return = $2f
    .label digit = $36
    // [2760] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [2760] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [2760] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [2761] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbuz1_ge_vbuz2_then_la1 
    lda.z value
    cmp.z sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [2762] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // uctoa_append::@return
    // }
    // [2763] return 
    rts
    // uctoa_append::@2
  __b2:
    // digit++;
    // [2764] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [2765] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbuz1=vbuz1_minus_vbuz2 
    lda.z value
    sec
    sbc.z sub
    sta.z value
    // [2760] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [2760] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [2760] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
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
// __zp($35) char rom_byte_compare(__zp($76) char *ptr_rom, __zp($66) char value)
rom_byte_compare: {
    .label return = $35
    .label ptr_rom = $76
    .label value = $66
    // if (*ptr_rom != value)
    // [2766] if(*rom_byte_compare::ptr_rom#0==rom_byte_compare::value#0) goto rom_byte_compare::@1 -- _deref_pbuz1_eq_vbuz2_then_la1 
    lda.z value
    ldy #0
    cmp (ptr_rom),y
    beq __b2
    // [2767] phi from rom_byte_compare to rom_byte_compare::@2 [phi:rom_byte_compare->rom_byte_compare::@2]
    // rom_byte_compare::@2
    // [2768] phi from rom_byte_compare::@2 to rom_byte_compare::@1 [phi:rom_byte_compare::@2->rom_byte_compare::@1]
    // [2768] phi rom_byte_compare::return#0 = 0 [phi:rom_byte_compare::@2->rom_byte_compare::@1#0] -- vbuz1=vbuc1 
    tya
    sta.z return
    rts
    // [2768] phi from rom_byte_compare to rom_byte_compare::@1 [phi:rom_byte_compare->rom_byte_compare::@1]
  __b2:
    // [2768] phi rom_byte_compare::return#0 = 1 [phi:rom_byte_compare->rom_byte_compare::@1#0] -- vbuz1=vbuc1 
    lda #1
    sta.z return
    // rom_byte_compare::@1
    // rom_byte_compare::@return
    // }
    // [2769] return 
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
// __zp($30) unsigned long ultoa_append(__zp($3f) char *buffer, __zp($30) unsigned long value, __zp($41) unsigned long sub)
ultoa_append: {
    .label buffer = $3f
    .label value = $30
    .label sub = $41
    .label return = $30
    .label digit = $35
    // [2771] phi from ultoa_append to ultoa_append::@1 [phi:ultoa_append->ultoa_append::@1]
    // [2771] phi ultoa_append::digit#2 = 0 [phi:ultoa_append->ultoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [2771] phi ultoa_append::value#2 = ultoa_append::value#0 [phi:ultoa_append->ultoa_append::@1#1] -- register_copy 
    // ultoa_append::@1
  __b1:
    // while (value >= sub)
    // [2772] if(ultoa_append::value#2>=ultoa_append::sub#0) goto ultoa_append::@2 -- vduz1_ge_vduz2_then_la1 
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
    // [2773] *ultoa_append::buffer#0 = DIGITS[ultoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // ultoa_append::@return
    // }
    // [2774] return 
    rts
    // ultoa_append::@2
  __b2:
    // digit++;
    // [2775] ultoa_append::digit#1 = ++ ultoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [2776] ultoa_append::value#1 = ultoa_append::value#2 - ultoa_append::sub#0 -- vduz1=vduz1_minus_vduz2 
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
    // [2771] phi from ultoa_append::@2 to ultoa_append::@1 [phi:ultoa_append::@2->ultoa_append::@1]
    // [2771] phi ultoa_append::digit#2 = ultoa_append::digit#1 [phi:ultoa_append::@2->ultoa_append::@1#0] -- register_copy 
    // [2771] phi ultoa_append::value#2 = ultoa_append::value#1 [phi:ultoa_append::@2->ultoa_append::@1#1] -- register_copy 
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
    // [2778] rom_wait::test1#1 = *rom_wait::ptr_rom#3 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (ptr_rom),y
    sta.z test1
    // test2 = *((brom_ptr_t)ptr_rom)
    // [2779] rom_wait::test2#1 = *rom_wait::ptr_rom#3 -- vbuz1=_deref_pbuz2 
    lda (ptr_rom),y
    sta.z test2
    // test1 & 0x40
    // [2780] rom_wait::$0 = rom_wait::test1#1 & $40 -- vbuz1=vbuz1_band_vbuc1 
    lda #$40
    and.z rom_wait__0
    sta.z rom_wait__0
    // test2 & 0x40
    // [2781] rom_wait::$1 = rom_wait::test2#1 & $40 -- vbuz1=vbuz1_band_vbuc1 
    lda #$40
    and.z rom_wait__1
    sta.z rom_wait__1
    // while ((test1 & 0x40) != (test2 & 0x40))
    // [2782] if(rom_wait::$0!=rom_wait::$1) goto rom_wait::@1 -- vbuz1_neq_vbuz2_then_la1 
    lda.z rom_wait__0
    cmp.z rom_wait__1
    bne __b1
    // rom_wait::@return
    // }
    // [2783] return 
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
    // [2785] rom_byte_program::rom_ptr1_$2 = (unsigned int)rom_byte_program::address#0 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_byte_program__2
    lda.z address+1
    sta.z rom_ptr1_rom_byte_program__2+1
    // [2786] rom_byte_program::rom_ptr1_$0 = rom_byte_program::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_byte_program__0
    and #<$3fff
    sta.z rom_ptr1_rom_byte_program__0
    lda.z rom_ptr1_rom_byte_program__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_byte_program__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2787] rom_byte_program::rom_ptr1_return#0 = rom_byte_program::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_byte_program::@1
    // rom_write_byte(address, value)
    // [2788] rom_write_byte::address#3 = rom_byte_program::address#0
    // [2789] rom_write_byte::value#3 = rom_byte_program::value#0
    // [2790] call rom_write_byte
    // [2672] phi from rom_byte_program::@1 to rom_write_byte [phi:rom_byte_program::@1->rom_write_byte]
    // [2672] phi rom_write_byte::value#10 = rom_write_byte::value#3 [phi:rom_byte_program::@1->rom_write_byte#0] -- register_copy 
    // [2672] phi rom_write_byte::address#4 = rom_write_byte::address#3 [phi:rom_byte_program::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_byte_program::@2
    // rom_wait(ptr_rom)
    // [2791] rom_wait::ptr_rom#1 = (char *)rom_byte_program::rom_ptr1_return#0 -- pbuz1=pbuz2 
    lda.z rom_ptr1_return
    sta.z rom_wait.ptr_rom
    lda.z rom_ptr1_return+1
    sta.z rom_wait.ptr_rom+1
    // [2792] call rom_wait
    // [2777] phi from rom_byte_program::@2 to rom_wait [phi:rom_byte_program::@2->rom_wait]
    // [2777] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#1 [phi:rom_byte_program::@2->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_byte_program::@return
    // }
    // [2793] return 
    rts
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
// __zp($2d) unsigned int utoa_append(__zp($4f) char *buffer, __zp($2d) unsigned int value, __zp($3f) unsigned int sub)
utoa_append: {
    .label buffer = $4f
    .label value = $2d
    .label sub = $3f
    .label return = $2d
    .label digit = $37
    // [2795] phi from utoa_append to utoa_append::@1 [phi:utoa_append->utoa_append::@1]
    // [2795] phi utoa_append::digit#2 = 0 [phi:utoa_append->utoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [2795] phi utoa_append::value#2 = utoa_append::value#0 [phi:utoa_append->utoa_append::@1#1] -- register_copy 
    // utoa_append::@1
  __b1:
    // while (value >= sub)
    // [2796] if(utoa_append::value#2>=utoa_append::sub#0) goto utoa_append::@2 -- vwuz1_ge_vwuz2_then_la1 
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
    // [2797] *utoa_append::buffer#0 = DIGITS[utoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // utoa_append::@return
    // }
    // [2798] return 
    rts
    // utoa_append::@2
  __b2:
    // digit++;
    // [2799] utoa_append::digit#1 = ++ utoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [2800] utoa_append::value#1 = utoa_append::value#2 - utoa_append::sub#0 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z value
    sec
    sbc.z sub
    sta.z value
    lda.z value+1
    sbc.z sub+1
    sta.z value+1
    // [2795] phi from utoa_append::@2 to utoa_append::@1 [phi:utoa_append::@2->utoa_append::@1]
    // [2795] phi utoa_append::digit#2 = utoa_append::digit#1 [phi:utoa_append::@2->utoa_append::@1#0] -- register_copy 
    // [2795] phi utoa_append::value#2 = utoa_append::value#1 [phi:utoa_append::@2->utoa_append::@1#1] -- register_copy 
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
    // [2801] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [2802] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte0_vwuz2 
    lda.z soffset_vram
    sta.z memcpy8_vram_vram__0
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [2803] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [2804] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte1_vwuz2 
    lda.z soffset_vram+1
    sta.z memcpy8_vram_vram__1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [2805] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [2806] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbuz1=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z memcpy8_vram_vram__2
    sta.z memcpy8_vram_vram__2
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [2807] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [2808] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [2809] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte0_vwuz2 
    lda.z doffset_vram
    sta.z memcpy8_vram_vram__3
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [2810] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [2811] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte1_vwuz2 
    lda.z doffset_vram+1
    sta.z memcpy8_vram_vram__4
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [2812] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [2813] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbuz1=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z memcpy8_vram_vram__5
    sta.z memcpy8_vram_vram__5
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [2814] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // [2815] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [2815] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [2816] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbuz1=_dec_vbuz2 
    ldy.z num8_1
    dey
    sty.z num8
    // [2817] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbuz1_then_la1 
    lda.z num8_1
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [2818] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [2819] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [2820] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbuz1=vbuz2 
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
  status_text: .word __3, __4, __5, __6, __7, __8, __9, __10, __11, __12, __13
  status_color: .byte BLACK, GREY, WHITE, CYAN, PURPLE, CYAN, PURPLE, PURPLE, GREEN, YELLOW, RED
  status_rom: .byte 0
  .fill 7, 0
  display_into_briefing_text: .word __14, __15, info_text4, __17, __18, __19, __20, __21, __22, __23, __24, info_text4, __26, __27
  display_into_colors_text: .word __28, __29, info_text4, __31, __32, __33, __34, __35, __36, __37, __38, __39, __40, __41, info_text4, __43
  display_no_valid_smc_bootloader_text: .word __44, info_text4, __46, __47, info_text4, __49, __50, __51, __52
  display_smc_rom_issue_text: .word __53, info_text4, __63, __64, info_text4, __58, __59, __60
  display_smc_unsupported_rom_text: .word __61, info_text4, __63, __64, info_text4, __66, __67
  display_debriefing_text_smc: .word __80, info_text4, __70, __71, __72, info_text4, __74, info_text4, __76, __77, __78, __79
  display_debriefing_text_rom: .word __80, info_text4, __82, __83
  smc_rom_releases: .fill $20, 0
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
  __53: .text "There is an issue with the CX16 SMC or ROM flash readiness."
  .byte 0
  __58: .text "Therefore, ensure you have the correct SMC.BIN and ROM.BIN"
  .byte 0
  __59: .text "files placed on your SDcard. Also ensure that the"
  .byte 0
  __60: .text "J1 jumper pins on the CX16 board are closed."
  .byte 0
  __61: .text "There is an issue with the CX16 SMC or ROM flash versions."
  .byte 0
  __63: .text "Both the SMC and the main ROM must be updated together,"
  .byte 0
  __64: .text "to avoid possible conflicts of firmware, bricking your CX16."
  .byte 0
  __66: .text "The SMC.BIN does not support the current ROM.BIN file"
  .byte 0
  __67: .text "placed on your SDcard. Upgrade the CX16 upon your own risk!"
  .byte 0
  __70: .text "Because your SMC chipset has been updated,"
  .byte 0
  __71: .text "the restart process differs, depending on the"
  .byte 0
  __72: .text "SMC boootloader version installed on your CX16 board:"
  .byte 0
  __74: .text "- SMC bootloader v2.0: your CX16 will automatically shut down."
  .byte 0
  __76: .text "- SMC bootloader v1.0: you need to "
  .byte 0
  __77: .text "  COMPLETELY DISCONNECT your CX16 from the power source!"
  .byte 0
  __78: .text "  The power-off button won't work!"
  .byte 0
  __79: .text "  Then, reconnect and start the CX16 normally."
  .byte 0
  __80: .text "Your CX16 system has been successfully updated!"
  .byte 0
  __82: .text "Since your CX16 system SMC and main ROM chipset"
  .byte 0
  __83: .text "have not been updated, your CX16 will just reset."
  .byte 0
  s: .text " "
  .byte 0
  s1: .text "/"
  .byte 0
  s2: .text " -> RAM:"
  .byte 0
  s3: .text ":"
  .byte 0
  s4: .text " ..."
  .byte 0
  s11: .text "Reading "
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
