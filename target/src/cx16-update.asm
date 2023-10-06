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
  /// Current position in the buffer being filled ( initially *s passed to snprintf()
  /// Used to hold state while printing
  .label __snprintf_buffer = $e5
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
    // screenlayer1()
    // [19] call screenlayer1
    jsr screenlayer1
    // [20] phi from conio_x16_init to conio_x16_init::@1 [phi:conio_x16_init->conio_x16_init::@1]
    // conio_x16_init::@1
    // textcolor(CONIO_TEXTCOLOR_DEFAULT)
    // [21] call textcolor
    // [588] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [588] phi textcolor::color#18 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [22] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [23] call bgcolor
    // [593] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [593] phi bgcolor::color#14 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbum1=vbuc1 
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
    // [30] conio_x16_init::$5 = byte1  conio_x16_init::$4 -- vbum1=_byte1_vwum2 
    sta conio_x16_init__5
    // __conio.cursor_x = BYTE1(cbm_k_plot_get())
    // [31] *((char *)&__conio) = conio_x16_init::$5 -- _deref_pbuc1=vbum1 
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
    // [606] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [606] phi gotoxy::y#30 = gotoxy::y#2 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [606] phi gotoxy::x#30 = gotoxy::x#2 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
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
    conio_x16_init__5: .byte 0
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
    .label cputc__2 = $6b
    .label cputc__3 = $6c
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
    .label main__119 = $c8
    .label check_status_smc1_main__0 = $f0
    .label check_status_smc2_main__0 = $de
    .label check_status_cx16_rom1_check_status_rom1_main__0 = $e7
    .label check_status_cx16_rom2_check_status_rom1_main__0 = $f1
    .label check_status_cx16_rom3_check_status_rom1_main__0 = $ec
    .label check_status_smc5_main__0 = $d5
    .label check_status_cx16_rom4_check_status_rom1_main__0 = $ea
    .label check_status_smc6_main__0 = $cf
    .label check_status_vera3_main__0 = $c2
    .label check_status_smc1_return = $f0
    .label check_status_smc2_return = $de
    .label check_status_cx16_rom1_check_status_rom1_return = $e7
    .label file = $2d
    .label rom_bytes_read = $f2
    .label rom_file_modulo = $f6
    .label check_status_cx16_rom2_check_status_rom1_return = $f1
    .label check_status_cx16_rom3_check_status_rom1_return = $ec
    .label check_status_smc5_return = $d5
    .label check_status_cx16_rom4_check_status_rom1_return = $ea
    .label check_status_smc6_return = $cf
    .label rom_bytes_read1 = $f2
    .label rom_differences = $c3
    .label check_status_vera3_return = $c2
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
    // [73] phi from main::bank_set_brom1 to main::@59 [phi:main::bank_set_brom1->main::@59]
    // main::@59
    // display_frame_init_64()
    // [74] call display_frame_init_64
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
    // [627] phi from main::@59 to display_frame_init_64 [phi:main::@59->display_frame_init_64]
    jsr display_frame_init_64
    // [75] phi from main::@59 to main::@82 [phi:main::@59->main::@82]
    // main::@82
    // display_frame_draw()
    // [76] call display_frame_draw
    // [647] phi from main::@82 to display_frame_draw [phi:main::@82->display_frame_draw]
    jsr display_frame_draw
    // [77] phi from main::@82 to main::@83 [phi:main::@82->main::@83]
    // main::@83
    // display_frame_title("Commander X16 Flash Utility!")
    // [78] call display_frame_title
    // [688] phi from main::@83 to display_frame_title [phi:main::@83->display_frame_title]
    jsr display_frame_title
    // [79] phi from main::@83 to main::display_info_title1 [phi:main::@83->main::display_info_title1]
    // main::display_info_title1
    // cputsxy(INFO_X-2, INFO_Y-2, "# Chip Status    Type   File  / Total Information")
    // [80] call cputsxy
    // [693] phi from main::display_info_title1 to cputsxy [phi:main::display_info_title1->cputsxy]
    // [693] phi cputsxy::s#4 = main::s [phi:main::display_info_title1->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z cputsxy.s
    lda #>s
    sta.z cputsxy.s+1
    // [693] phi cputsxy::y#4 = $11-2 [phi:main::display_info_title1->cputsxy#1] -- vbum1=vbuc1 
    lda #$11-2
    sta cputsxy.y
    // [693] phi cputsxy::x#4 = 4-2 [phi:main::display_info_title1->cputsxy#2] -- vbum1=vbuc1 
    lda #4-2
    sta cputsxy.x
    jsr cputsxy
    // [81] phi from main::display_info_title1 to main::@84 [phi:main::display_info_title1->main::@84]
    // main::@84
    // cputsxy(INFO_X-2, INFO_Y-1, "- ---- --------- ------ ----- / ----- --------------------")
    // [82] call cputsxy
    // [693] phi from main::@84 to cputsxy [phi:main::@84->cputsxy]
    // [693] phi cputsxy::s#4 = main::s1 [phi:main::@84->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s1
    sta.z cputsxy.s
    lda #>s1
    sta.z cputsxy.s+1
    // [693] phi cputsxy::y#4 = $11-1 [phi:main::@84->cputsxy#1] -- vbum1=vbuc1 
    lda #$11-1
    sta cputsxy.y
    // [693] phi cputsxy::x#4 = 4-2 [phi:main::@84->cputsxy#2] -- vbum1=vbuc1 
    lda #4-2
    sta cputsxy.x
    jsr cputsxy
    // [83] phi from main::@84 to main::@60 [phi:main::@84->main::@60]
    // main::@60
    // display_action_progress("Introduction ...")
    // [84] call display_action_progress
    // [700] phi from main::@60 to display_action_progress [phi:main::@60->display_action_progress]
    // [700] phi display_action_progress::info_text#14 = main::info_text [phi:main::@60->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [85] phi from main::@60 to main::@85 [phi:main::@60->main::@85]
    // main::@85
    // display_progress_clear()
    // [86] call display_progress_clear
    // [714] phi from main::@85 to display_progress_clear [phi:main::@85->display_progress_clear]
    jsr display_progress_clear
    // [87] phi from main::@85 to main::@86 [phi:main::@85->main::@86]
    // main::@86
    // display_chip_smc()
    // [88] call display_chip_smc
    // [729] phi from main::@86 to display_chip_smc [phi:main::@86->display_chip_smc]
    jsr display_chip_smc
    // [89] phi from main::@86 to main::@87 [phi:main::@86->main::@87]
    // main::@87
    // display_chip_vera()
    // [90] call display_chip_vera
    // [734] phi from main::@87 to display_chip_vera [phi:main::@87->display_chip_vera]
    jsr display_chip_vera
    // [91] phi from main::@87 to main::@88 [phi:main::@87->main::@88]
    // main::@88
    // display_chip_rom()
    // [92] call display_chip_rom
    // [739] phi from main::@88 to display_chip_rom [phi:main::@88->display_chip_rom]
    jsr display_chip_rom
    // [93] phi from main::@88 to main::@89 [phi:main::@88->main::@89]
    // main::@89
    // display_info_smc(STATUS_COLOR_NONE, NULL)
    // [94] call display_info_smc
    // [758] phi from main::@89 to display_info_smc [phi:main::@89->display_info_smc]
    // [758] phi display_info_smc::info_text#13 = 0 [phi:main::@89->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [758] phi smc_file_size#12 = 0 [phi:main::@89->display_info_smc#1] -- vwum1=vwuc1 
    sta smc_file_size_2
    sta smc_file_size_2+1
    // [758] phi display_info_smc::info_status#13 = BLACK [phi:main::@89->display_info_smc#2] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [95] phi from main::@89 to main::@90 [phi:main::@89->main::@90]
    // main::@90
    // display_info_vera(STATUS_NONE, NULL)
    // [96] call display_info_vera
    // [788] phi from main::@90 to display_info_vera [phi:main::@90->display_info_vera]
    // [788] phi display_info_vera::info_text#10 = 0 [phi:main::@90->display_info_vera#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_vera.info_text
    sta.z display_info_vera.info_text+1
    // [788] phi display_info_vera::info_status#3 = STATUS_NONE [phi:main::@90->display_info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_NONE
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // [97] phi from main::@90 to main::@9 [phi:main::@90->main::@9]
    // [97] phi main::rom_chip#2 = 0 [phi:main::@90->main::@9#0] -- vwum1=vwuc1 
    lda #<0
    sta rom_chip
    sta rom_chip+1
    // main::@9
  __b9:
    // for(unsigned rom_chip=0; rom_chip<8; rom_chip++)
    // [98] if(main::rom_chip#2<8) goto main::@10 -- vwum1_lt_vbuc1_then_la1 
    lda rom_chip+1
    bne !+
    lda rom_chip
    cmp #8
    bcs !__b10+
    jmp __b10
  !__b10:
  !:
    // [99] phi from main::@9 to main::@11 [phi:main::@9->main::@11]
    // main::@11
    // display_progress_text(display_into_briefing_text, display_intro_briefing_count)
    // [100] call display_progress_text
    // [814] phi from main::@11 to display_progress_text [phi:main::@11->display_progress_text]
    // [814] phi display_progress_text::text#10 = display_into_briefing_text [phi:main::@11->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_into_briefing_text
    sta.z display_progress_text.text
    lda #>display_into_briefing_text
    sta.z display_progress_text.text+1
    // [814] phi display_progress_text::lines#7 = display_intro_briefing_count [phi:main::@11->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_intro_briefing_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [101] phi from main::@11 to main::@92 [phi:main::@11->main::@92]
    // main::@92
    // util_wait_space()
    // [102] call util_wait_space
    // [824] phi from main::@92 to util_wait_space [phi:main::@92->util_wait_space]
    jsr util_wait_space
    // [103] phi from main::@92 to main::@93 [phi:main::@92->main::@93]
    // main::@93
    // display_progress_text(display_into_colors_text, display_intro_colors_count)
    // [104] call display_progress_text
    // [814] phi from main::@93 to display_progress_text [phi:main::@93->display_progress_text]
    // [814] phi display_progress_text::text#10 = display_into_colors_text [phi:main::@93->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_into_colors_text
    sta.z display_progress_text.text
    lda #>display_into_colors_text
    sta.z display_progress_text.text+1
    // [814] phi display_progress_text::lines#7 = display_intro_colors_count [phi:main::@93->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_intro_colors_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [105] phi from main::@93 to main::@12 [phi:main::@93->main::@12]
    // [105] phi main::intro_status#2 = 0 [phi:main::@93->main::@12#0] -- vbum1=vbuc1 
    lda #0
    sta intro_status
    // main::@12
  __b12:
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [106] if(main::intro_status#2<$b) goto main::@13 -- vbum1_lt_vbuc1_then_la1 
    lda intro_status
    cmp #$b
    bcs !__b13+
    jmp __b13
  !__b13:
    // [107] phi from main::@12 to main::@14 [phi:main::@12->main::@14]
    // main::@14
    // util_wait_space()
    // [108] call util_wait_space
    // [824] phi from main::@14 to util_wait_space [phi:main::@14->util_wait_space]
    jsr util_wait_space
    // [109] phi from main::@14 to main::@95 [phi:main::@14->main::@95]
    // main::@95
    // display_progress_clear()
    // [110] call display_progress_clear
    // [714] phi from main::@95 to display_progress_clear [phi:main::@95->display_progress_clear]
    jsr display_progress_clear
    // main::SEI1
    // asm
    // asm { sei  }
    sei
    // [112] phi from main::SEI1 to main::@61 [phi:main::SEI1->main::@61]
    // main::@61
    // smc_detect()
    // [113] call smc_detect
    jsr smc_detect
    // [114] smc_detect::return#2 = smc_detect::return#0
    // main::@96
    // smc_bootloader = smc_detect()
    // [115] smc_bootloader#0 = smc_detect::return#2 -- vwum1=vwuz2 
    lda.z smc_detect.return
    sta smc_bootloader
    lda.z smc_detect.return+1
    sta smc_bootloader+1
    // display_chip_smc()
    // [116] call display_chip_smc
    // [729] phi from main::@96 to display_chip_smc [phi:main::@96->display_chip_smc]
    jsr display_chip_smc
    // main::@97
    // if(smc_bootloader == 0x0100)
    // [117] if(smc_bootloader#0==$100) goto main::@1 -- vwum1_eq_vwuc1_then_la1 
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
    // [118] if(smc_bootloader#0==$200) goto main::@18 -- vwum1_eq_vwuc1_then_la1 
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
    // [119] if(smc_bootloader#0>=2+1) goto main::@19 -- vwum1_ge_vbuc1_then_la1 
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
    // [120] phi from main::@16 to main::@17 [phi:main::@16->main::@17]
    // main::@17
    // smc_version(smc_version_string)
    // [121] call smc_version
    jsr smc_version
    // [122] phi from main::@17 to main::@104 [phi:main::@17->main::@104]
    // main::@104
    // sprintf(info_text, "SMC %s, BL v%02x", smc_version_string, smc_bootloader)
    // [123] call snprintf_init
    // [868] phi from main::@104 to snprintf_init [phi:main::@104->snprintf_init]
    // [868] phi snprintf_init::s#25 = info_text [phi:main::@104->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [124] phi from main::@104 to main::@105 [phi:main::@104->main::@105]
    // main::@105
    // sprintf(info_text, "SMC %s, BL v%02x", smc_version_string, smc_bootloader)
    // [125] call printf_str
    // [873] phi from main::@105 to printf_str [phi:main::@105->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:main::@105->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = main::s4 [phi:main::@105->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // [126] phi from main::@105 to main::@106 [phi:main::@105->main::@106]
    // main::@106
    // sprintf(info_text, "SMC %s, BL v%02x", smc_version_string, smc_bootloader)
    // [127] call printf_string
    // [882] phi from main::@106 to printf_string [phi:main::@106->printf_string]
    // [882] phi printf_string::putc#19 = &snputc [phi:main::@106->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [882] phi printf_string::str#19 = smc_version_string [phi:main::@106->printf_string#1] -- pbuz1=pbuc1 
    lda #<smc_version_string
    sta.z printf_string.str
    lda #>smc_version_string
    sta.z printf_string.str+1
    // [882] phi printf_string::format_justify_left#19 = 0 [phi:main::@106->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [882] phi printf_string::format_min_length#19 = 0 [phi:main::@106->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [128] phi from main::@106 to main::@107 [phi:main::@106->main::@107]
    // main::@107
    // sprintf(info_text, "SMC %s, BL v%02x", smc_version_string, smc_bootloader)
    // [129] call printf_str
    // [873] phi from main::@107 to printf_str [phi:main::@107->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:main::@107->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = main::s5 [phi:main::@107->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // main::@108
    // sprintf(info_text, "SMC %s, BL v%02x", smc_version_string, smc_bootloader)
    // [130] printf_uint::uvalue#17 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta printf_uint.uvalue
    lda smc_bootloader+1
    sta printf_uint.uvalue+1
    // [131] call printf_uint
    // [907] phi from main::@108 to printf_uint [phi:main::@108->printf_uint]
    // [907] phi printf_uint::format_zero_padding#18 = 1 [phi:main::@108->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [907] phi printf_uint::format_min_length#18 = 2 [phi:main::@108->printf_uint#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uint.format_min_length
    // [907] phi printf_uint::putc#18 = &snputc [phi:main::@108->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [907] phi printf_uint::format_radix#18 = HEXADECIMAL [phi:main::@108->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [907] phi printf_uint::uvalue#18 = printf_uint::uvalue#17 [phi:main::@108->printf_uint#4] -- register_copy 
    jsr printf_uint
    // main::@109
    // sprintf(info_text, "SMC %s, BL v%02x", smc_version_string, smc_bootloader)
    // [132] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [133] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_smc(STATUS_DETECTED, info_text)
    // [135] call display_info_smc
  // All ok, display bootloader version.
    // [758] phi from main::@109 to display_info_smc [phi:main::@109->display_info_smc]
    // [758] phi display_info_smc::info_text#13 = info_text [phi:main::@109->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_smc.info_text
    lda #>@info_text
    sta.z display_info_smc.info_text+1
    // [758] phi smc_file_size#12 = 0 [phi:main::@109->display_info_smc#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size_2
    sta smc_file_size_2+1
    // [758] phi display_info_smc::info_status#13 = STATUS_DETECTED [phi:main::@109->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_DETECTED
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // main::CLI1
  CLI1:
    // asm
    // asm { cli  }
    cli
    // [137] phi from main::CLI1 to main::@62 [phi:main::CLI1->main::@62]
    // main::@62
    // display_chip_vera()
    // [138] call display_chip_vera
  // Detecting VERA FPGA.
    // [734] phi from main::@62 to display_chip_vera [phi:main::@62->display_chip_vera]
    jsr display_chip_vera
    // [139] phi from main::@62 to main::@110 [phi:main::@62->main::@110]
    // main::@110
    // display_info_vera(STATUS_DETECTED, "VERA installed, OK")
    // [140] call display_info_vera
    // [788] phi from main::@110 to display_info_vera [phi:main::@110->display_info_vera]
    // [788] phi display_info_vera::info_text#10 = main::info_text3 [phi:main::@110->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text3
    sta.z display_info_vera.info_text
    lda #>info_text3
    sta.z display_info_vera.info_text+1
    // [788] phi display_info_vera::info_status#3 = STATUS_DETECTED [phi:main::@110->display_info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_DETECTED
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // main::SEI2
    // asm
    // asm { sei  }
    sei
    // [142] phi from main::SEI2 to main::@63 [phi:main::SEI2->main::@63]
    // main::@63
    // rom_detect()
    // [143] call rom_detect
  // Detecting ROM chips
    // [918] phi from main::@63 to rom_detect [phi:main::@63->rom_detect]
    jsr rom_detect
    // [144] phi from main::@63 to main::@111 [phi:main::@63->main::@111]
    // main::@111
    // display_chip_rom()
    // [145] call display_chip_rom
    // [739] phi from main::@111 to display_chip_rom [phi:main::@111->display_chip_rom]
    jsr display_chip_rom
    // [146] phi from main::@111 to main::@20 [phi:main::@111->main::@20]
    // [146] phi main::rom_chip1#2 = 0 [phi:main::@111->main::@20#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip1
    // main::@20
  __b20:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [147] if(main::rom_chip1#2<8) goto main::@21 -- vbum1_lt_vbuc1_then_la1 
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
    // [150] main::check_status_smc1_$0 = status_smc#0 == STATUS_DETECTED -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_DETECTED
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc1_main__0
    // return (unsigned char)(status_smc == status);
    // [151] main::check_status_smc1_return#0 = (char)main::check_status_smc1_$0
    // main::@64
    // if(check_status_smc(STATUS_DETECTED))
    // [152] if(0==main::check_status_smc1_return#0) goto main::CLI3 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_smc1_return
    beq __b7
    // [153] phi from main::@64 to main::@25 [phi:main::@64->main::@25]
    // main::@25
    // smc_read()
    // [154] call smc_read
    // [968] phi from main::@25 to smc_read [phi:main::@25->smc_read]
    // [968] phi __errno#35 = 0 [phi:main::@25->smc_read#0] -- vwsm1=vwsc1 
    lda #<0
    sta __errno
    sta __errno+1
    jsr smc_read
    // smc_read()
    // [155] smc_read::return#2 = smc_read::return#0
    // main::@112
    // smc_file_size = smc_read()
    // [156] smc_file_size#0 = smc_read::return#2 -- vwum1=vwuz2 
    lda.z smc_read.return
    sta smc_file_size
    lda.z smc_read.return+1
    sta smc_file_size+1
    // if (!smc_file_size)
    // [157] if(0==smc_file_size#0) goto main::@28 -- 0_eq_vwum1_then_la1 
    // In case no file was found, set the status to error and skip to the next, else, mention the amount of bytes read.
    lda smc_file_size
    ora smc_file_size+1
    bne !__b28+
    jmp __b28
  !__b28:
    // main::@26
    // if(smc_file_size > 0x1E00)
    // [158] if(smc_file_size#0>$1e00) goto main::@29 -- vwum1_gt_vwuc1_then_la1 
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
    // [159] smc_file_size#383 = smc_file_size#0 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_FLASH, NULL)
    // [160] call display_info_smc
  // All ok, display the SMC version and bootloader.
    // [758] phi from main::@27 to display_info_smc [phi:main::@27->display_info_smc]
    // [758] phi display_info_smc::info_text#13 = 0 [phi:main::@27->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [758] phi smc_file_size#12 = smc_file_size#383 [phi:main::@27->display_info_smc#1] -- register_copy 
    // [758] phi display_info_smc::info_status#13 = STATUS_FLASH [phi:main::@27->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASH
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [161] phi from main::@27 main::@28 main::@29 to main::CLI3 [phi:main::@27/main::@28/main::@29->main::CLI3]
    // [161] phi smc_file_size#226 = smc_file_size#0 [phi:main::@27/main::@28/main::@29->main::CLI3#0] -- register_copy 
    // [161] phi __errno#240 = __errno#179 [phi:main::@27/main::@28/main::@29->main::CLI3#1] -- register_copy 
    jmp CLI3
    // [161] phi from main::@64 to main::CLI3 [phi:main::@64->main::CLI3]
  __b7:
    // [161] phi smc_file_size#226 = 0 [phi:main::@64->main::CLI3#0] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size
    sta smc_file_size+1
    // [161] phi __errno#240 = 0 [phi:main::@64->main::CLI3#1] -- vwsm1=vwsc1 
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
    // [164] phi from main::SEI4 to main::@30 [phi:main::SEI4->main::@30]
    // [164] phi __errno#112 = __errno#240 [phi:main::SEI4->main::@30#0] -- register_copy 
    // [164] phi main::rom_chip2#10 = 0 [phi:main::SEI4->main::@30#1] -- vbum1=vbuc1 
    lda #0
    sta rom_chip2
  // We loop all the possible ROM chip slots on the board and on the extension card,
  // and we check the file contents.
  // Any error identified gets reported and this chip will not be flashed.
  // In case of ROM0.BIN in error, no flashing will be done!
    // main::@30
  __b30:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [165] if(main::rom_chip2#10<8) goto main::bank_set_brom2 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip2
    cmp #8
    bcs !bank_set_brom2+
    jmp bank_set_brom2
  !bank_set_brom2:
    // main::bank_set_brom3
    // BROM = bank
    // [166] BROM = main::bank_set_brom3_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom3_bank
    sta.z BROM
    // main::CLI4
    // asm
    // asm { cli  }
    cli
    // main::check_status_smc2
    // status_smc == status
    // [168] main::check_status_smc2_$0 = status_smc#0 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc2_main__0
    // return (unsigned char)(status_smc == status);
    // [169] main::check_status_smc2_return#0 = (char)main::check_status_smc2_$0
    // [170] phi from main::check_status_smc2 to main::check_status_cx16_rom1 [phi:main::check_status_smc2->main::check_status_cx16_rom1]
    // main::check_status_cx16_rom1
    // main::check_status_cx16_rom1_check_status_rom1
    // status_rom[rom_chip] == status
    // [171] main::check_status_cx16_rom1_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_cx16_rom1_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [172] main::check_status_cx16_rom1_check_status_rom1_return#0 = (char)main::check_status_cx16_rom1_check_status_rom1_$0
    // main::@66
    // if(!check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH))
    // [173] if(0!=main::check_status_smc2_return#0) goto main::check_status_smc3 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc2_return
    bne check_status_smc3
    // main::@184
    // [174] if(0!=main::check_status_cx16_rom1_check_status_rom1_return#0) goto main::@37 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_cx16_rom1_check_status_rom1_return
    beq !__b37+
    jmp __b37
  !__b37:
    // main::check_status_smc3
  check_status_smc3:
    // status_smc == status
    // [175] main::check_status_smc3_$0 = status_smc#0 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc3_main__0
    // return (unsigned char)(status_smc == status);
    // [176] main::check_status_smc3_return#0 = (char)main::check_status_smc3_$0
    // [177] phi from main::check_status_smc3 to main::check_status_cx16_rom2 [phi:main::check_status_smc3->main::check_status_cx16_rom2]
    // main::check_status_cx16_rom2
    // main::check_status_cx16_rom2_check_status_rom1
    // status_rom[rom_chip] == status
    // [178] main::check_status_cx16_rom2_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_cx16_rom2_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [179] main::check_status_cx16_rom2_check_status_rom1_return#0 = (char)main::check_status_cx16_rom2_check_status_rom1_$0
    // main::@69
    // if(check_status_smc(STATUS_FLASH) && !check_status_cx16_rom(STATUS_FLASH))
    // [180] if(0==main::check_status_smc3_return#0) goto main::check_status_smc4 -- 0_eq_vbum1_then_la1 
    lda check_status_smc3_return
    beq check_status_smc4
    // main::@185
    // [181] if(0==main::check_status_cx16_rom2_check_status_rom1_return#0) goto main::@3 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_cx16_rom2_check_status_rom1_return
    bne !__b3+
    jmp __b3
  !__b3:
    // main::check_status_smc4
  check_status_smc4:
    // status_smc == status
    // [182] main::check_status_smc4_$0 = status_smc#0 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc4_main__0
    // return (unsigned char)(status_smc == status);
    // [183] main::check_status_smc4_return#0 = (char)main::check_status_smc4_$0
    // [184] phi from main::check_status_smc4 to main::check_status_cx16_rom3 [phi:main::check_status_smc4->main::check_status_cx16_rom3]
    // main::check_status_cx16_rom3
    // main::check_status_cx16_rom3_check_status_rom1
    // status_rom[rom_chip] == status
    // [185] main::check_status_cx16_rom3_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_cx16_rom3_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [186] main::check_status_cx16_rom3_check_status_rom1_return#0 = (char)main::check_status_cx16_rom3_check_status_rom1_$0
    // [187] phi from main::check_status_cx16_rom3_check_status_rom1 to main::check_status_card_roms1 [phi:main::check_status_cx16_rom3_check_status_rom1->main::check_status_card_roms1]
    // main::check_status_card_roms1
    // [188] phi from main::check_status_card_roms1 to main::check_status_card_roms1_@1 [phi:main::check_status_card_roms1->main::check_status_card_roms1_@1]
    // [188] phi main::check_status_card_roms1_rom_chip#2 = 1 [phi:main::check_status_card_roms1->main::check_status_card_roms1_@1#0] -- vbum1=vbuc1 
    lda #1
    sta check_status_card_roms1_rom_chip
    // main::check_status_card_roms1_@1
  check_status_card_roms1___b1:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [189] if(main::check_status_card_roms1_rom_chip#2<8) goto main::check_status_card_roms1_check_status_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda check_status_card_roms1_rom_chip
    cmp #8
    bcs !check_status_card_roms1_check_status_rom1+
    jmp check_status_card_roms1_check_status_rom1
  !check_status_card_roms1_check_status_rom1:
    // [190] phi from main::check_status_card_roms1_@1 to main::check_status_card_roms1_@return [phi:main::check_status_card_roms1_@1->main::check_status_card_roms1_@return]
    // [190] phi main::check_status_card_roms1_return#2 = STATUS_NONE [phi:main::check_status_card_roms1_@1->main::check_status_card_roms1_@return#0] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta check_status_card_roms1_return
    // main::check_status_card_roms1_@return
    // main::@70
  __b70:
    // if(check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH) || check_status_card_roms(STATUS_FLASH))
    // [191] if(0==main::check_status_smc4_return#0) goto main::@186 -- 0_eq_vbum1_then_la1 
    lda check_status_smc4_return
    beq __b186
    // main::@187
    // [192] if(0!=main::check_status_cx16_rom3_check_status_rom1_return#0) goto main::@4 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_cx16_rom3_check_status_rom1_return
    beq !__b4+
    jmp __b4
  !__b4:
    // main::@186
  __b186:
    // [193] if(0!=main::check_status_card_roms1_return#2) goto main::@4 -- 0_neq_vbum1_then_la1 
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
    // [195] main::check_status_smc5_$0 = status_smc#0 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc5_main__0
    // return (unsigned char)(status_smc == status);
    // [196] main::check_status_smc5_return#0 = (char)main::check_status_smc5_$0
    // [197] phi from main::check_status_smc5 to main::check_status_cx16_rom4 [phi:main::check_status_smc5->main::check_status_cx16_rom4]
    // main::check_status_cx16_rom4
    // main::check_status_cx16_rom4_check_status_rom1
    // status_rom[rom_chip] == status
    // [198] main::check_status_cx16_rom4_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_cx16_rom4_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [199] main::check_status_cx16_rom4_check_status_rom1_return#0 = (char)main::check_status_cx16_rom4_check_status_rom1_$0
    // main::@71
    // if (check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH))
    // [200] if(0==main::check_status_smc5_return#0) goto main::@2 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_smc5_return
    beq __b2
    // main::@188
    // [201] if(0!=main::check_status_cx16_rom4_check_status_rom1_return#0) goto main::@6 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_cx16_rom4_check_status_rom1_return
    beq !__b6+
    jmp __b6
  !__b6:
    // [202] phi from main::@188 to main::@2 [phi:main::@188->main::@2]
    // [202] phi from main::@145 main::@41 main::@71 main::@8 to main::@2 [phi:main::@145/main::@41/main::@71/main::@8->main::@2]
    // [202] phi __errno#395 = __errno#179 [phi:main::@145/main::@41/main::@71/main::@8->main::@2#0] -- register_copy 
    // main::@2
  __b2:
    // [203] phi from main::@2 to main::@42 [phi:main::@2->main::@42]
    // [203] phi __errno#114 = __errno#395 [phi:main::@2->main::@42#0] -- register_copy 
    // [203] phi main::rom_chip4#10 = 7 [phi:main::@2->main::@42#1] -- vbum1=vbuc1 
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
    // [204] if(main::rom_chip4#10!=$ff) goto main::check_status_rom1 -- vbum1_neq_vbuc1_then_la1 
    lda #$ff
    cmp rom_chip4
    beq !check_status_rom1+
    jmp check_status_rom1
  !check_status_rom1:
    // main::bank_set_brom4
    // BROM = bank
    // [205] BROM = main::bank_set_brom4_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom4_bank
    sta.z BROM
    // main::CLI5
    // asm
    // asm { cli  }
    cli
    // main::check_status_smc6
    // status_smc == status
    // [207] main::check_status_smc6_$0 = status_smc#0 == STATUS_SKIP -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc6_main__0
    // return (unsigned char)(status_smc == status);
    // [208] main::check_status_smc6_return#0 = (char)main::check_status_smc6_$0
    // main::check_status_vera1
    // status_vera == status
    // [209] main::check_status_vera1_$0 = status_vera#0 == STATUS_SKIP -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_vera1_main__0
    // return (unsigned char)(status_vera == status);
    // [210] main::check_status_vera1_return#0 = (char)main::check_status_vera1_$0
    // [211] phi from main::check_status_vera1 to main::check_status_roms_all1 [phi:main::check_status_vera1->main::check_status_roms_all1]
    // main::check_status_roms_all1
    // [212] phi from main::check_status_roms_all1 to main::check_status_roms_all1_@1 [phi:main::check_status_roms_all1->main::check_status_roms_all1_@1]
    // [212] phi main::check_status_roms_all1_rom_chip#2 = 0 [phi:main::check_status_roms_all1->main::check_status_roms_all1_@1#0] -- vbum1=vbuc1 
    lda #0
    sta check_status_roms_all1_rom_chip
    // main::check_status_roms_all1_@1
  check_status_roms_all1___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [213] if(main::check_status_roms_all1_rom_chip#2<8) goto main::check_status_roms_all1_check_status_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda check_status_roms_all1_rom_chip
    cmp #8
    bcs !check_status_roms_all1_check_status_rom1+
    jmp check_status_roms_all1_check_status_rom1
  !check_status_roms_all1_check_status_rom1:
    // [214] phi from main::check_status_roms_all1_@1 to main::check_status_roms_all1_@return [phi:main::check_status_roms_all1_@1->main::check_status_roms_all1_@return]
    // [214] phi main::check_status_roms_all1_return#2 = 1 [phi:main::check_status_roms_all1_@1->main::check_status_roms_all1_@return#0] -- vbum1=vbuc1 
    lda #1
    sta check_status_roms_all1_return
    // main::check_status_roms_all1_@return
    // main::@73
  __b73:
    // if(check_status_smc(STATUS_SKIP) && check_status_vera(STATUS_SKIP) && check_status_roms_all(STATUS_SKIP))
    // [215] if(0==main::check_status_smc6_return#0) goto main::check_status_smc8 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_smc6_return
    beq check_status_smc8
    // main::@190
    // [216] if(0==main::check_status_vera1_return#0) goto main::check_status_smc8 -- 0_eq_vbum1_then_la1 
    lda check_status_vera1_return
    beq check_status_smc8
    // main::@189
    // [217] if(0!=main::check_status_roms_all1_return#2) goto main::vera_display_set_border_color1 -- 0_neq_vbum1_then_la1 
    lda check_status_roms_all1_return
    beq !vera_display_set_border_color1+
    jmp vera_display_set_border_color1
  !vera_display_set_border_color1:
    // main::check_status_smc8
  check_status_smc8:
    // status_smc == status
    // [218] main::check_status_smc8_$0 = status_smc#0 == STATUS_ERROR -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc8_main__0
    // return (unsigned char)(status_smc == status);
    // [219] main::check_status_smc8_return#0 = (char)main::check_status_smc8_$0
    // main::check_status_vera2
    // status_vera == status
    // [220] main::check_status_vera2_$0 = status_vera#0 == STATUS_ERROR -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_vera2_main__0
    // return (unsigned char)(status_vera == status);
    // [221] main::check_status_vera2_return#0 = (char)main::check_status_vera2_$0
    // [222] phi from main::check_status_vera2 to main::check_status_roms1 [phi:main::check_status_vera2->main::check_status_roms1]
    // main::check_status_roms1
    // [223] phi from main::check_status_roms1 to main::check_status_roms1_@1 [phi:main::check_status_roms1->main::check_status_roms1_@1]
    // [223] phi main::check_status_roms1_rom_chip#2 = 0 [phi:main::check_status_roms1->main::check_status_roms1_@1#0] -- vbum1=vbuc1 
    lda #0
    sta check_status_roms1_rom_chip
    // main::check_status_roms1_@1
  check_status_roms1___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [224] if(main::check_status_roms1_rom_chip#2<8) goto main::check_status_roms1_check_status_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda check_status_roms1_rom_chip
    cmp #8
    bcs !check_status_roms1_check_status_rom1+
    jmp check_status_roms1_check_status_rom1
  !check_status_roms1_check_status_rom1:
    // [225] phi from main::check_status_roms1_@1 to main::check_status_roms1_@return [phi:main::check_status_roms1_@1->main::check_status_roms1_@return]
    // [225] phi main::check_status_roms1_return#2 = STATUS_NONE [phi:main::check_status_roms1_@1->main::check_status_roms1_@return#0] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta check_status_roms1_return
    // main::check_status_roms1_@return
    // main::@77
  __b77:
    // if(check_status_smc(STATUS_ERROR) || check_status_vera(STATUS_ERROR) || check_status_roms(STATUS_ERROR))
    // [226] if(0!=main::check_status_smc8_return#0) goto main::vera_display_set_border_color2 -- 0_neq_vbum1_then_la1 
    lda check_status_smc8_return
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::@194
    // [227] if(0!=main::check_status_vera2_return#0) goto main::vera_display_set_border_color2 -- 0_neq_vbum1_then_la1 
    lda check_status_vera2_return
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::@193
    // [228] if(0!=main::check_status_roms1_return#2) goto main::vera_display_set_border_color2 -- 0_neq_vbum1_then_la1 
    lda check_status_roms1_return
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::check_status_smc9
    // status_smc == status
    // [229] main::check_status_smc9_$0 = status_smc#0 == STATUS_ISSUE -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc9_main__0
    // return (unsigned char)(status_smc == status);
    // [230] main::check_status_smc9_return#0 = (char)main::check_status_smc9_$0
    // main::check_status_vera3
    // status_vera == status
    // [231] main::check_status_vera3_$0 = status_vera#0 == STATUS_ISSUE -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_vera3_main__0
    // return (unsigned char)(status_vera == status);
    // [232] main::check_status_vera3_return#0 = (char)main::check_status_vera3_$0
    // [233] phi from main::check_status_vera3 to main::check_status_roms2 [phi:main::check_status_vera3->main::check_status_roms2]
    // main::check_status_roms2
    // [234] phi from main::check_status_roms2 to main::check_status_roms2_@1 [phi:main::check_status_roms2->main::check_status_roms2_@1]
    // [234] phi main::check_status_roms2_rom_chip#2 = 0 [phi:main::check_status_roms2->main::check_status_roms2_@1#0] -- vbum1=vbuc1 
    lda #0
    sta check_status_roms2_rom_chip
    // main::check_status_roms2_@1
  check_status_roms2___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [235] if(main::check_status_roms2_rom_chip#2<8) goto main::check_status_roms2_check_status_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda check_status_roms2_rom_chip
    cmp #8
    bcs !check_status_roms2_check_status_rom1+
    jmp check_status_roms2_check_status_rom1
  !check_status_roms2_check_status_rom1:
    // [236] phi from main::check_status_roms2_@1 to main::check_status_roms2_@return [phi:main::check_status_roms2_@1->main::check_status_roms2_@return]
    // [236] phi main::check_status_roms2_return#2 = STATUS_NONE [phi:main::check_status_roms2_@1->main::check_status_roms2_@return#0] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta check_status_roms2_return
    // main::check_status_roms2_@return
    // main::@79
  __b79:
    // if(check_status_smc(STATUS_ISSUE) || check_status_vera(STATUS_ISSUE) || check_status_roms(STATUS_ISSUE))
    // [237] if(0!=main::check_status_smc9_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbum1_then_la1 
    lda check_status_smc9_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::@196
    // [238] if(0!=main::check_status_vera3_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_vera3_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::@195
    // [239] if(0!=main::check_status_roms2_return#2) goto main::vera_display_set_border_color3 -- 0_neq_vbum1_then_la1 
    lda check_status_roms2_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::vera_display_set_border_color4
    // *VERA_CTRL &= ~VERA_DCSEL
    // [240] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [241] *VERA_DC_BORDER = GREEN -- _deref_pbuc1=vbuc2 
    lda #GREEN
    sta VERA_DC_BORDER
    // main::check_status_smc10
    // status_smc == status
    // [242] main::check_status_smc10_$0 = status_smc#0 == STATUS_FLASHED -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASHED
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc10_main__0
    // return (unsigned char)(status_smc == status);
    // [243] main::check_status_smc10_return#0 = (char)main::check_status_smc10_$0
    // main::@81
    // if(check_status_smc(STATUS_FLASHED))
    // [244] if(0!=main::check_status_smc10_return#0) goto main::@51 -- 0_neq_vbum1_then_la1 
    lda check_status_smc10_return
    beq !__b51+
    jmp __b51
  !__b51:
    // [245] phi from main::@81 to main::@50 [phi:main::@81->main::@50]
    // main::@50
    // display_progress_text(display_debriefing_text_rom, display_debriefing_count_rom)
    // [246] call display_progress_text
    // [814] phi from main::@50 to display_progress_text [phi:main::@50->display_progress_text]
    // [814] phi display_progress_text::text#10 = display_debriefing_text_rom [phi:main::@50->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_debriefing_text_rom
    sta.z display_progress_text.text
    lda #>display_debriefing_text_rom
    sta.z display_progress_text.text+1
    // [814] phi display_progress_text::lines#7 = display_debriefing_count_rom [phi:main::@50->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_debriefing_count_rom
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [247] phi from main::@177 main::@50 main::@76 main::@80 to main::@56 [phi:main::@177/main::@50/main::@76/main::@80->main::@56]
  __b8:
    // [247] phi main::w1#2 = $c8 [phi:main::@177/main::@50/main::@76/main::@80->main::@56#0] -- vbum1=vbuc1 
    lda #$c8
    sta w1
    // main::@56
  __b56:
    // for (unsigned char w=200; w>0; w--)
    // [248] if(main::w1#2>0) goto main::@57 -- vbum1_gt_0_then_la1 
    lda w1
    bne __b57
    // [249] phi from main::@56 to main::@58 [phi:main::@56->main::@58]
    // main::@58
    // system_reset()
    // [250] call system_reset
    // [1025] phi from main::@58 to system_reset [phi:main::@58->system_reset]
    jsr system_reset
    // main::@return
    // }
    // [251] return 
    rts
    // [252] phi from main::@56 to main::@57 [phi:main::@56->main::@57]
    // main::@57
  __b57:
    // wait_moment()
    // [253] call wait_moment
    // [1030] phi from main::@57 to wait_moment [phi:main::@57->wait_moment]
    jsr wait_moment
    // [254] phi from main::@57 to main::@178 [phi:main::@57->main::@178]
    // main::@178
    // sprintf(info_text, "(%03u) Your CX16 will reset ...", w)
    // [255] call snprintf_init
    // [868] phi from main::@178 to snprintf_init [phi:main::@178->snprintf_init]
    // [868] phi snprintf_init::s#25 = info_text [phi:main::@178->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [256] phi from main::@178 to main::@179 [phi:main::@178->main::@179]
    // main::@179
    // sprintf(info_text, "(%03u) Your CX16 will reset ...", w)
    // [257] call printf_str
    // [873] phi from main::@179 to printf_str [phi:main::@179->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:main::@179->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = main::s21 [phi:main::@179->printf_str#1] -- pbuz1=pbuc1 
    lda #<s21
    sta.z printf_str.s
    lda #>s21
    sta.z printf_str.s+1
    jsr printf_str
    // main::@180
    // sprintf(info_text, "(%03u) Your CX16 will reset ...", w)
    // [258] printf_uchar::uvalue#10 = main::w1#2 -- vbum1=vbum2 
    lda w1
    sta printf_uchar.uvalue
    // [259] call printf_uchar
    // [1035] phi from main::@180 to printf_uchar [phi:main::@180->printf_uchar]
    // [1035] phi printf_uchar::format_zero_padding#11 = 1 [phi:main::@180->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1035] phi printf_uchar::format_min_length#11 = 3 [phi:main::@180->printf_uchar#1] -- vbum1=vbuc1 
    lda #3
    sta printf_uchar.format_min_length
    // [1035] phi printf_uchar::putc#11 = &snputc [phi:main::@180->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1035] phi printf_uchar::format_radix#11 = DECIMAL [phi:main::@180->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1035] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#10 [phi:main::@180->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [260] phi from main::@180 to main::@181 [phi:main::@180->main::@181]
    // main::@181
    // sprintf(info_text, "(%03u) Your CX16 will reset ...", w)
    // [261] call printf_str
    // [873] phi from main::@181 to printf_str [phi:main::@181->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:main::@181->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = main::s22 [phi:main::@181->printf_str#1] -- pbuz1=pbuc1 
    lda #<s22
    sta.z printf_str.s
    lda #>s22
    sta.z printf_str.s+1
    jsr printf_str
    // main::@182
    // sprintf(info_text, "(%03u) Your CX16 will reset ...", w)
    // [262] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [263] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [265] call display_action_text
    // [1046] phi from main::@182 to display_action_text [phi:main::@182->display_action_text]
    // [1046] phi display_action_text::info_text#19 = info_text [phi:main::@182->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@183
    // for (unsigned char w=200; w>0; w--)
    // [266] main::w1#1 = -- main::w1#2 -- vbum1=_dec_vbum1 
    dec w1
    // [247] phi from main::@183 to main::@56 [phi:main::@183->main::@56]
    // [247] phi main::w1#2 = main::w1#1 [phi:main::@183->main::@56#0] -- register_copy 
    jmp __b56
    // [267] phi from main::@81 to main::@51 [phi:main::@81->main::@51]
    // main::@51
  __b51:
    // display_progress_text(display_debriefing_text_smc, display_debriefing_count_smc)
    // [268] call display_progress_text
    // [814] phi from main::@51 to display_progress_text [phi:main::@51->display_progress_text]
    // [814] phi display_progress_text::text#10 = display_debriefing_text_smc [phi:main::@51->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_debriefing_text_smc
    sta.z display_progress_text.text
    lda #>display_debriefing_text_smc
    sta.z display_progress_text.text+1
    // [814] phi display_progress_text::lines#7 = display_debriefing_count_smc [phi:main::@51->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_debriefing_count_smc
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [269] phi from main::@51 to main::@52 [phi:main::@51->main::@52]
    // [269] phi main::w#2 = $80 [phi:main::@51->main::@52#0] -- vbum1=vbuc1 
    lda #$80
    sta w
    // main::@52
  __b52:
    // for (unsigned char w=128; w>0; w--)
    // [270] if(main::w#2>0) goto main::@53 -- vbum1_gt_0_then_la1 
    lda w
    bne __b53
    // [271] phi from main::@52 to main::@54 [phi:main::@52->main::@54]
    // main::@54
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [272] call snprintf_init
    // [868] phi from main::@54 to snprintf_init [phi:main::@54->snprintf_init]
    // [868] phi snprintf_init::s#25 = info_text [phi:main::@54->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [273] phi from main::@54 to main::@175 [phi:main::@54->main::@175]
    // main::@175
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [274] call printf_str
    // [873] phi from main::@175 to printf_str [phi:main::@175->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:main::@175->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = main::s20 [phi:main::@175->printf_str#1] -- pbuz1=pbuc1 
    lda #<s20
    sta.z printf_str.s
    lda #>s20
    sta.z printf_str.s+1
    jsr printf_str
    // main::@176
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [275] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [276] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [278] call display_action_text
    // [1046] phi from main::@176 to display_action_text [phi:main::@176->display_action_text]
    // [1046] phi display_action_text::info_text#19 = info_text [phi:main::@176->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [279] phi from main::@176 to main::@177 [phi:main::@176->main::@177]
    // main::@177
    // smc_reset()
    // [280] call smc_reset
    // [1060] phi from main::@177 to smc_reset [phi:main::@177->smc_reset]
    jsr smc_reset
    jmp __b8
    // [281] phi from main::@52 to main::@53 [phi:main::@52->main::@53]
    // main::@53
  __b53:
    // wait_moment()
    // [282] call wait_moment
    // [1030] phi from main::@53 to wait_moment [phi:main::@53->wait_moment]
    jsr wait_moment
    // [283] phi from main::@53 to main::@169 [phi:main::@53->main::@169]
    // main::@169
    // sprintf(info_text, "Please read carefully the below (%u) ...", w)
    // [284] call snprintf_init
    // [868] phi from main::@169 to snprintf_init [phi:main::@169->snprintf_init]
    // [868] phi snprintf_init::s#25 = info_text [phi:main::@169->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [285] phi from main::@169 to main::@170 [phi:main::@169->main::@170]
    // main::@170
    // sprintf(info_text, "Please read carefully the below (%u) ...", w)
    // [286] call printf_str
    // [873] phi from main::@170 to printf_str [phi:main::@170->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:main::@170->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = main::s18 [phi:main::@170->printf_str#1] -- pbuz1=pbuc1 
    lda #<s18
    sta.z printf_str.s
    lda #>s18
    sta.z printf_str.s+1
    jsr printf_str
    // main::@171
    // sprintf(info_text, "Please read carefully the below (%u) ...", w)
    // [287] printf_uchar::uvalue#9 = main::w#2 -- vbum1=vbum2 
    lda w
    sta printf_uchar.uvalue
    // [288] call printf_uchar
    // [1035] phi from main::@171 to printf_uchar [phi:main::@171->printf_uchar]
    // [1035] phi printf_uchar::format_zero_padding#11 = 0 [phi:main::@171->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1035] phi printf_uchar::format_min_length#11 = 0 [phi:main::@171->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1035] phi printf_uchar::putc#11 = &snputc [phi:main::@171->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1035] phi printf_uchar::format_radix#11 = DECIMAL [phi:main::@171->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1035] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#9 [phi:main::@171->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [289] phi from main::@171 to main::@172 [phi:main::@171->main::@172]
    // main::@172
    // sprintf(info_text, "Please read carefully the below (%u) ...", w)
    // [290] call printf_str
    // [873] phi from main::@172 to printf_str [phi:main::@172->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:main::@172->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = main::s19 [phi:main::@172->printf_str#1] -- pbuz1=pbuc1 
    lda #<s19
    sta.z printf_str.s
    lda #>s19
    sta.z printf_str.s+1
    jsr printf_str
    // main::@173
    // sprintf(info_text, "Please read carefully the below (%u) ...", w)
    // [291] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [292] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [294] call display_action_text
    // [1046] phi from main::@173 to display_action_text [phi:main::@173->display_action_text]
    // [1046] phi display_action_text::info_text#19 = info_text [phi:main::@173->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@174
    // for (unsigned char w=128; w>0; w--)
    // [295] main::w#1 = -- main::w#2 -- vbum1=_dec_vbum1 
    dec w
    // [269] phi from main::@174 to main::@52 [phi:main::@174->main::@52]
    // [269] phi main::w#2 = main::w#1 [phi:main::@174->main::@52#0] -- register_copy 
    jmp __b52
    // main::vera_display_set_border_color3
  vera_display_set_border_color3:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [296] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [297] *VERA_DC_BORDER = YELLOW -- _deref_pbuc1=vbuc2 
    lda #YELLOW
    sta VERA_DC_BORDER
    // [298] phi from main::vera_display_set_border_color3 to main::@80 [phi:main::vera_display_set_border_color3->main::@80]
    // main::@80
    // display_action_progress("Update issues, your CX16 is not updated!")
    // [299] call display_action_progress
    // [700] phi from main::@80 to display_action_progress [phi:main::@80->display_action_progress]
    // [700] phi display_action_progress::info_text#14 = main::info_text28 [phi:main::@80->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text28
    sta.z display_action_progress.info_text
    lda #>info_text28
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    jmp __b8
    // main::check_status_roms2_check_status_rom1
  check_status_roms2_check_status_rom1:
    // status_rom[rom_chip] == status
    // [300] main::check_status_roms2_check_status_rom1_$0 = status_rom[main::check_status_roms2_rom_chip#2] == STATUS_ISSUE -- vbom1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_ISSUE
    ldy check_status_roms2_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_roms2_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [301] main::check_status_roms2_check_status_rom1_return#0 = (char)main::check_status_roms2_check_status_rom1_$0
    // main::check_status_roms2_@11
    // if(check_status_rom(rom_chip, status))
    // [302] if(0==main::check_status_roms2_check_status_rom1_return#0) goto main::check_status_roms2_@4 -- 0_eq_vbum1_then_la1 
    lda check_status_roms2_check_status_rom1_return
    beq check_status_roms2___b4
    // [236] phi from main::check_status_roms2_@11 to main::check_status_roms2_@return [phi:main::check_status_roms2_@11->main::check_status_roms2_@return]
    // [236] phi main::check_status_roms2_return#2 = STATUS_ISSUE [phi:main::check_status_roms2_@11->main::check_status_roms2_@return#0] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta check_status_roms2_return
    jmp __b79
    // main::check_status_roms2_@4
  check_status_roms2___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [303] main::check_status_roms2_rom_chip#1 = ++ main::check_status_roms2_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_status_roms2_rom_chip
    // [234] phi from main::check_status_roms2_@4 to main::check_status_roms2_@1 [phi:main::check_status_roms2_@4->main::check_status_roms2_@1]
    // [234] phi main::check_status_roms2_rom_chip#2 = main::check_status_roms2_rom_chip#1 [phi:main::check_status_roms2_@4->main::check_status_roms2_@1#0] -- register_copy 
    jmp check_status_roms2___b1
    // main::vera_display_set_border_color2
  vera_display_set_border_color2:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [304] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [305] *VERA_DC_BORDER = RED -- _deref_pbuc1=vbuc2 
    lda #RED
    sta VERA_DC_BORDER
    // [306] phi from main::vera_display_set_border_color2 to main::@78 [phi:main::vera_display_set_border_color2->main::@78]
    // main::@78
    // display_action_progress("Update Failure! Your CX16 may be bricked!")
    // [307] call display_action_progress
    // [700] phi from main::@78 to display_action_progress [phi:main::@78->display_action_progress]
    // [700] phi display_action_progress::info_text#14 = main::info_text26 [phi:main::@78->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text26
    sta.z display_action_progress.info_text
    lda #>info_text26
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [308] phi from main::@78 to main::@168 [phi:main::@78->main::@168]
    // main::@168
    // display_action_text("Take a foto of this screen. And shut down power ...")
    // [309] call display_action_text
    // [1046] phi from main::@168 to display_action_text [phi:main::@168->display_action_text]
    // [1046] phi display_action_text::info_text#19 = main::info_text27 [phi:main::@168->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text27
    sta.z display_action_text.info_text
    lda #>info_text27
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [310] phi from main::@168 main::@55 to main::@55 [phi:main::@168/main::@55->main::@55]
    // main::@55
  __b55:
    jmp __b55
    // main::check_status_roms1_check_status_rom1
  check_status_roms1_check_status_rom1:
    // status_rom[rom_chip] == status
    // [311] main::check_status_roms1_check_status_rom1_$0 = status_rom[main::check_status_roms1_rom_chip#2] == STATUS_ERROR -- vbom1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_ERROR
    ldy check_status_roms1_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_roms1_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [312] main::check_status_roms1_check_status_rom1_return#0 = (char)main::check_status_roms1_check_status_rom1_$0
    // main::check_status_roms1_@11
    // if(check_status_rom(rom_chip, status))
    // [313] if(0==main::check_status_roms1_check_status_rom1_return#0) goto main::check_status_roms1_@4 -- 0_eq_vbum1_then_la1 
    lda check_status_roms1_check_status_rom1_return
    beq check_status_roms1___b4
    // [225] phi from main::check_status_roms1_@11 to main::check_status_roms1_@return [phi:main::check_status_roms1_@11->main::check_status_roms1_@return]
    // [225] phi main::check_status_roms1_return#2 = STATUS_ERROR [phi:main::check_status_roms1_@11->main::check_status_roms1_@return#0] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta check_status_roms1_return
    jmp __b77
    // main::check_status_roms1_@4
  check_status_roms1___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [314] main::check_status_roms1_rom_chip#1 = ++ main::check_status_roms1_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_status_roms1_rom_chip
    // [223] phi from main::check_status_roms1_@4 to main::check_status_roms1_@1 [phi:main::check_status_roms1_@4->main::check_status_roms1_@1]
    // [223] phi main::check_status_roms1_rom_chip#2 = main::check_status_roms1_rom_chip#1 [phi:main::check_status_roms1_@4->main::check_status_roms1_@1#0] -- register_copy 
    jmp check_status_roms1___b1
    // main::vera_display_set_border_color1
  vera_display_set_border_color1:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [315] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [316] *VERA_DC_BORDER = BLACK -- _deref_pbuc1=vbuc2 
    lda #BLACK
    sta VERA_DC_BORDER
    // [317] phi from main::vera_display_set_border_color1 to main::@76 [phi:main::vera_display_set_border_color1->main::@76]
    // main::@76
    // display_action_progress("The update has been cancelled!")
    // [318] call display_action_progress
    // [700] phi from main::@76 to display_action_progress [phi:main::@76->display_action_progress]
    // [700] phi display_action_progress::info_text#14 = main::info_text25 [phi:main::@76->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text25
    sta.z display_action_progress.info_text
    lda #>info_text25
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    jmp __b8
    // main::check_status_roms_all1_check_status_rom1
  check_status_roms_all1_check_status_rom1:
    // status_rom[rom_chip] == status
    // [319] main::check_status_roms_all1_check_status_rom1_$0 = status_rom[main::check_status_roms_all1_rom_chip#2] == STATUS_SKIP -- vbom1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_SKIP
    ldy check_status_roms_all1_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_roms_all1_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [320] main::check_status_roms_all1_check_status_rom1_return#0 = (char)main::check_status_roms_all1_check_status_rom1_$0
    // main::check_status_roms_all1_@11
    // if(check_status_rom(rom_chip, status) != status)
    // [321] if(main::check_status_roms_all1_check_status_rom1_return#0==STATUS_SKIP) goto main::check_status_roms_all1_@4 -- vbum1_eq_vbuc1_then_la1 
    lda #STATUS_SKIP
    cmp check_status_roms_all1_check_status_rom1_return
    beq check_status_roms_all1___b4
    // [214] phi from main::check_status_roms_all1_@11 to main::check_status_roms_all1_@return [phi:main::check_status_roms_all1_@11->main::check_status_roms_all1_@return]
    // [214] phi main::check_status_roms_all1_return#2 = 0 [phi:main::check_status_roms_all1_@11->main::check_status_roms_all1_@return#0] -- vbum1=vbuc1 
    lda #0
    sta check_status_roms_all1_return
    jmp __b73
    // main::check_status_roms_all1_@4
  check_status_roms_all1___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [322] main::check_status_roms_all1_rom_chip#1 = ++ main::check_status_roms_all1_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_status_roms_all1_rom_chip
    // [212] phi from main::check_status_roms_all1_@4 to main::check_status_roms_all1_@1 [phi:main::check_status_roms_all1_@4->main::check_status_roms_all1_@1]
    // [212] phi main::check_status_roms_all1_rom_chip#2 = main::check_status_roms_all1_rom_chip#1 [phi:main::check_status_roms_all1_@4->main::check_status_roms_all1_@1#0] -- register_copy 
    jmp check_status_roms_all1___b1
    // main::check_status_rom1
  check_status_rom1:
    // status_rom[rom_chip] == status
    // [323] main::check_status_rom1_$0 = status_rom[main::rom_chip4#10] == STATUS_FLASH -- vbom1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_FLASH
    ldy rom_chip4
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [324] main::check_status_rom1_return#0 = (char)main::check_status_rom1_$0
    // main::@72
    // if(check_status_rom(rom_chip, STATUS_FLASH))
    // [325] if(0==main::check_status_rom1_return#0) goto main::@43 -- 0_eq_vbum1_then_la1 
    lda check_status_rom1_return
    beq __b43
    // main::check_status_smc7
    // status_smc == status
    // [326] main::check_status_smc7_$0 = status_smc#0 == STATUS_FLASHED -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASHED
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc7_main__0
    // return (unsigned char)(status_smc == status);
    // [327] main::check_status_smc7_return#0 = (char)main::check_status_smc7_$0
    // main::@74
    // if((rom_chip == 0 && check_status_smc(STATUS_FLASHED)) || (rom_chip != 0))
    // [328] if(main::rom_chip4#10!=0) goto main::@191 -- vbum1_neq_0_then_la1 
    // IMPORTANT! We only flash the CX16 ROM chip if the SMC got flashed succesfully!
    lda rom_chip4
    bne __b191
    // main::@192
    // [329] if(0!=main::check_status_smc7_return#0) goto main::bank_set_brom5 -- 0_neq_vbum1_then_la1 
    lda check_status_smc7_return
    bne bank_set_brom5
    // main::@191
  __b191:
    // [330] if(main::rom_chip4#10!=0) goto main::bank_set_brom5 -- vbum1_neq_0_then_la1 
    lda rom_chip4
    bne bank_set_brom5
    // main::@49
    // display_info_rom(rom_chip, STATUS_ISSUE, "Update SMC failed!")
    // [331] display_info_rom::rom_chip#11 = main::rom_chip4#10 -- vbuz1=vbum2 
    sta.z display_info_rom.rom_chip
    // [332] call display_info_rom
    // [1069] phi from main::@49 to display_info_rom [phi:main::@49->display_info_rom]
    // [1069] phi display_info_rom::info_text#17 = main::info_text20 [phi:main::@49->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text20
    sta.z display_info_rom.info_text
    lda #>info_text20
    sta.z display_info_rom.info_text+1
    // [1069] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#11 [phi:main::@49->display_info_rom#1] -- register_copy 
    // [1069] phi display_info_rom::info_status#17 = STATUS_ISSUE [phi:main::@49->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // [333] phi from main::@156 main::@167 main::@44 main::@48 main::@49 main::@72 to main::@43 [phi:main::@156/main::@167/main::@44/main::@48/main::@49/main::@72->main::@43]
    // [333] phi __errno#396 = __errno#179 [phi:main::@156/main::@167/main::@44/main::@48/main::@49/main::@72->main::@43#0] -- register_copy 
    // main::@43
  __b43:
    // for(unsigned char rom_chip = 7; rom_chip != 255; rom_chip--)
    // [334] main::rom_chip4#1 = -- main::rom_chip4#10 -- vbum1=_dec_vbum1 
    dec rom_chip4
    // [203] phi from main::@43 to main::@42 [phi:main::@43->main::@42]
    // [203] phi __errno#114 = __errno#396 [phi:main::@43->main::@42#0] -- register_copy 
    // [203] phi main::rom_chip4#10 = main::rom_chip4#1 [phi:main::@43->main::@42#1] -- register_copy 
    jmp __b42
    // main::bank_set_brom5
  bank_set_brom5:
    // BROM = bank
    // [335] BROM = main::bank_set_brom5_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom5_bank
    sta.z BROM
    // [336] phi from main::bank_set_brom5 to main::@75 [phi:main::bank_set_brom5->main::@75]
    // main::@75
    // display_progress_clear()
    // [337] call display_progress_clear
    // [714] phi from main::@75 to display_progress_clear [phi:main::@75->display_progress_clear]
    jsr display_progress_clear
    // main::@149
    // unsigned char rom_bank = rom_chip * 32
    // [338] main::rom_bank1#0 = main::rom_chip4#10 << 5 -- vbum1=vbum2_rol_5 
    lda rom_chip4
    asl
    asl
    asl
    asl
    asl
    sta rom_bank1
    // unsigned char* file = rom_file(rom_chip)
    // [339] rom_file::rom_chip#1 = main::rom_chip4#10 -- vbuz1=vbum2 
    lda rom_chip4
    sta.z rom_file.rom_chip
    // [340] call rom_file
    // [1114] phi from main::@149 to rom_file [phi:main::@149->rom_file]
    // [1114] phi rom_file::rom_chip#2 = rom_file::rom_chip#1 [phi:main::@149->rom_file#0] -- register_copy 
    jsr rom_file
    // unsigned char* file = rom_file(rom_chip)
    // [341] rom_file::return#5 = rom_file::return#2
    // main::@150
    // [342] main::file1#0 = rom_file::return#5
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [343] call snprintf_init
    // [868] phi from main::@150 to snprintf_init [phi:main::@150->snprintf_init]
    // [868] phi snprintf_init::s#25 = info_text [phi:main::@150->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [344] phi from main::@150 to main::@151 [phi:main::@150->main::@151]
    // main::@151
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [345] call printf_str
    // [873] phi from main::@151 to printf_str [phi:main::@151->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:main::@151->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = s14 [phi:main::@151->printf_str#1] -- pbuz1=pbuc1 
    lda #<s14
    sta.z printf_str.s
    lda #>s14
    sta.z printf_str.s+1
    jsr printf_str
    // main::@152
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [346] printf_string::str#18 = main::file1#0 -- pbuz1=pbum2 
    lda file1
    sta.z printf_string.str
    lda file1+1
    sta.z printf_string.str+1
    // [347] call printf_string
    // [882] phi from main::@152 to printf_string [phi:main::@152->printf_string]
    // [882] phi printf_string::putc#19 = &snputc [phi:main::@152->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [882] phi printf_string::str#19 = printf_string::str#18 [phi:main::@152->printf_string#1] -- register_copy 
    // [882] phi printf_string::format_justify_left#19 = 0 [phi:main::@152->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [882] phi printf_string::format_min_length#19 = 0 [phi:main::@152->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [348] phi from main::@152 to main::@153 [phi:main::@152->main::@153]
    // main::@153
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [349] call printf_str
    // [873] phi from main::@153 to printf_str [phi:main::@153->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:main::@153->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = main::s7 [phi:main::@153->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@154
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [350] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [351] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_progress(info_text)
    // [353] call display_action_progress
    // [700] phi from main::@154 to display_action_progress [phi:main::@154->display_action_progress]
    // [700] phi display_action_progress::info_text#14 = info_text [phi:main::@154->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_progress.info_text
    lda #>@info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@155
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_READING, rom_bank, rom_sizes[rom_chip])
    // [354] main::$200 = main::rom_chip4#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip4
    asl
    asl
    sta main__200
    // [355] rom_read::file#1 = main::file1#0 -- pbuz1=pbum2 
    lda file1
    sta.z rom_read.file
    lda file1+1
    sta.z rom_read.file+1
    // [356] rom_read::brom_bank_start#2 = main::rom_bank1#0 -- vbuz1=vbum2 
    lda rom_bank1
    sta.z rom_read.brom_bank_start
    // [357] rom_read::rom_size#1 = rom_sizes[main::$200] -- vduz1=pduc1_derefidx_vbum2 
    ldy main__200
    lda rom_sizes,y
    sta.z rom_read.rom_size
    lda rom_sizes+1,y
    sta.z rom_read.rom_size+1
    lda rom_sizes+2,y
    sta.z rom_read.rom_size+2
    lda rom_sizes+3,y
    sta.z rom_read.rom_size+3
    // [358] call rom_read
    // [1120] phi from main::@155 to rom_read [phi:main::@155->rom_read]
    // [1120] phi rom_read::rom_size#12 = rom_read::rom_size#1 [phi:main::@155->rom_read#0] -- register_copy 
    // [1120] phi __errno#106 = __errno#114 [phi:main::@155->rom_read#1] -- register_copy 
    // [1120] phi rom_read::file#11 = rom_read::file#1 [phi:main::@155->rom_read#2] -- register_copy 
    // [1120] phi rom_read::brom_bank_start#21 = rom_read::brom_bank_start#2 [phi:main::@155->rom_read#3] -- register_copy 
    jsr rom_read
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_READING, rom_bank, rom_sizes[rom_chip])
    // [359] rom_read::return#3 = rom_read::return#0
    // main::@156
    // [360] main::rom_bytes_read1#0 = rom_read::return#3
    // if(rom_bytes_read)
    // [361] if(0==main::rom_bytes_read1#0) goto main::@43 -- 0_eq_vduz1_then_la1 
    lda.z rom_bytes_read1
    ora.z rom_bytes_read1+1
    ora.z rom_bytes_read1+2
    ora.z rom_bytes_read1+3
    bne !__b43+
    jmp __b43
  !__b43:
    // [362] phi from main::@156 to main::@46 [phi:main::@156->main::@46]
    // main::@46
    // display_action_progress("Comparing ... (.) same, (*) different.")
    // [363] call display_action_progress
  // Now we compare the RAM with the actual ROM contents.
    // [700] phi from main::@46 to display_action_progress [phi:main::@46->display_action_progress]
    // [700] phi display_action_progress::info_text#14 = main::info_text21 [phi:main::@46->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text21
    sta.z display_action_progress.info_text
    lda #>info_text21
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@157
    // display_info_rom(rom_chip, STATUS_COMPARING, "")
    // [364] display_info_rom::rom_chip#12 = main::rom_chip4#10 -- vbuz1=vbum2 
    lda rom_chip4
    sta.z display_info_rom.rom_chip
    // [365] call display_info_rom
    // [1069] phi from main::@157 to display_info_rom [phi:main::@157->display_info_rom]
    // [1069] phi display_info_rom::info_text#17 = info_text4 [phi:main::@157->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z display_info_rom.info_text
    lda #>info_text4
    sta.z display_info_rom.info_text+1
    // [1069] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#12 [phi:main::@157->display_info_rom#1] -- register_copy 
    // [1069] phi display_info_rom::info_status#17 = STATUS_COMPARING [phi:main::@157->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_COMPARING
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // main::@158
    // unsigned long rom_differences = rom_verify(
    //                         rom_chip, rom_bank, file_sizes[rom_chip])
    // [366] rom_verify::rom_chip#0 = main::rom_chip4#10 -- vbuz1=vbum2 
    lda rom_chip4
    sta.z rom_verify.rom_chip
    // [367] rom_verify::rom_bank_start#0 = main::rom_bank1#0 -- vbum1=vbum2 
    lda rom_bank1
    sta rom_verify.rom_bank_start
    // [368] rom_verify::file_size#0 = file_sizes[main::$200] -- vduz1=pduc1_derefidx_vbum2 
    ldy main__200
    lda file_sizes,y
    sta.z rom_verify.file_size
    lda file_sizes+1,y
    sta.z rom_verify.file_size+1
    lda file_sizes+2,y
    sta.z rom_verify.file_size+2
    lda file_sizes+3,y
    sta.z rom_verify.file_size+3
    // [369] call rom_verify
    // Verify the ROM...
    jsr rom_verify
    // [370] rom_verify::return#2 = rom_verify::rom_different_bytes#11
    // main::@159
    // [371] main::rom_differences#0 = rom_verify::return#2 -- vduz1=vduz2 
    lda.z rom_verify.return
    sta.z rom_differences
    lda.z rom_verify.return+1
    sta.z rom_differences+1
    lda.z rom_verify.return+2
    sta.z rom_differences+2
    lda.z rom_verify.return+3
    sta.z rom_differences+3
    // if (!rom_differences)
    // [372] if(0==main::rom_differences#0) goto main::@44 -- 0_eq_vduz1_then_la1 
    lda.z rom_differences
    ora.z rom_differences+1
    ora.z rom_differences+2
    ora.z rom_differences+3
    bne !__b44+
    jmp __b44
  !__b44:
    // [373] phi from main::@159 to main::@47 [phi:main::@159->main::@47]
    // main::@47
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [374] call snprintf_init
    // [868] phi from main::@47 to snprintf_init [phi:main::@47->snprintf_init]
    // [868] phi snprintf_init::s#25 = info_text [phi:main::@47->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main::@160
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [375] printf_ulong::uvalue#9 = main::rom_differences#0 -- vdum1=vduz2 
    lda.z rom_differences
    sta printf_ulong.uvalue
    lda.z rom_differences+1
    sta printf_ulong.uvalue+1
    lda.z rom_differences+2
    sta printf_ulong.uvalue+2
    lda.z rom_differences+3
    sta printf_ulong.uvalue+3
    // [376] call printf_ulong
    // [1270] phi from main::@160 to printf_ulong [phi:main::@160->printf_ulong]
    // [1270] phi printf_ulong::format_zero_padding#11 = 1 [phi:main::@160->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1270] phi printf_ulong::format_min_length#11 = 5 [phi:main::@160->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1270] phi printf_ulong::putc#11 = &snputc [phi:main::@160->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1270] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:main::@160->printf_ulong#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1270] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#9 [phi:main::@160->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [377] phi from main::@160 to main::@161 [phi:main::@160->main::@161]
    // main::@161
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [378] call printf_str
    // [873] phi from main::@161 to printf_str [phi:main::@161->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:main::@161->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = main::s16 [phi:main::@161->printf_str#1] -- pbuz1=pbuc1 
    lda #<s16
    sta.z printf_str.s
    lda #>s16
    sta.z printf_str.s+1
    jsr printf_str
    // main::@162
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [379] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [380] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_FLASH, info_text)
    // [382] display_info_rom::rom_chip#14 = main::rom_chip4#10 -- vbuz1=vbum2 
    lda rom_chip4
    sta.z display_info_rom.rom_chip
    // [383] call display_info_rom
    // [1069] phi from main::@162 to display_info_rom [phi:main::@162->display_info_rom]
    // [1069] phi display_info_rom::info_text#17 = info_text [phi:main::@162->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1069] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#14 [phi:main::@162->display_info_rom#1] -- register_copy 
    // [1069] phi display_info_rom::info_status#17 = STATUS_FLASH [phi:main::@162->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASH
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // main::@163
    // unsigned long rom_flash_errors = rom_flash(
    //                             rom_chip, rom_bank, file_sizes[rom_chip])
    // [384] rom_flash::rom_chip#0 = main::rom_chip4#10 -- vbum1=vbum2 
    lda rom_chip4
    sta rom_flash.rom_chip
    // [385] rom_flash::rom_bank_start#0 = main::rom_bank1#0 -- vbum1=vbum2 
    lda rom_bank1
    sta rom_flash.rom_bank_start
    // [386] rom_flash::file_size#0 = file_sizes[main::$200] -- vdum1=pduc1_derefidx_vbum2 
    ldy main__200
    lda file_sizes,y
    sta rom_flash.file_size
    lda file_sizes+1,y
    sta rom_flash.file_size+1
    lda file_sizes+2,y
    sta rom_flash.file_size+2
    lda file_sizes+3,y
    sta rom_flash.file_size+3
    // [387] call rom_flash
    // [1281] phi from main::@163 to rom_flash [phi:main::@163->rom_flash]
    jsr rom_flash
    // unsigned long rom_flash_errors = rom_flash(
    //                             rom_chip, rom_bank, file_sizes[rom_chip])
    // [388] rom_flash::return#2 = rom_flash::flash_errors#10
    // main::@164
    // [389] main::rom_flash_errors#0 = rom_flash::return#2 -- vdum1=vduz2 
    lda.z rom_flash.return
    sta rom_flash_errors
    lda.z rom_flash.return+1
    sta rom_flash_errors+1
    lda.z rom_flash.return+2
    sta rom_flash_errors+2
    lda.z rom_flash.return+3
    sta rom_flash_errors+3
    // if(rom_flash_errors)
    // [390] if(0!=main::rom_flash_errors#0) goto main::@45 -- 0_neq_vdum1_then_la1 
    lda rom_flash_errors
    ora rom_flash_errors+1
    ora rom_flash_errors+2
    ora rom_flash_errors+3
    bne __b45
    // main::@48
    // display_info_rom(rom_chip, STATUS_FLASHED, "OK!")
    // [391] display_info_rom::rom_chip#16 = main::rom_chip4#10 -- vbuz1=vbum2 
    lda rom_chip4
    sta.z display_info_rom.rom_chip
    // [392] call display_info_rom
    // [1069] phi from main::@48 to display_info_rom [phi:main::@48->display_info_rom]
    // [1069] phi display_info_rom::info_text#17 = main::info_text24 [phi:main::@48->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text24
    sta.z display_info_rom.info_text
    lda #>info_text24
    sta.z display_info_rom.info_text+1
    // [1069] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#16 [phi:main::@48->display_info_rom#1] -- register_copy 
    // [1069] phi display_info_rom::info_status#17 = STATUS_FLASHED [phi:main::@48->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHED
    sta.z display_info_rom.info_status
    jsr display_info_rom
    jmp __b43
    // [393] phi from main::@164 to main::@45 [phi:main::@164->main::@45]
    // main::@45
  __b45:
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [394] call snprintf_init
    // [868] phi from main::@45 to snprintf_init [phi:main::@45->snprintf_init]
    // [868] phi snprintf_init::s#25 = info_text [phi:main::@45->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main::@165
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [395] printf_ulong::uvalue#10 = main::rom_flash_errors#0 -- vdum1=vdum2 
    lda rom_flash_errors
    sta printf_ulong.uvalue
    lda rom_flash_errors+1
    sta printf_ulong.uvalue+1
    lda rom_flash_errors+2
    sta printf_ulong.uvalue+2
    lda rom_flash_errors+3
    sta printf_ulong.uvalue+3
    // [396] call printf_ulong
    // [1270] phi from main::@165 to printf_ulong [phi:main::@165->printf_ulong]
    // [1270] phi printf_ulong::format_zero_padding#11 = 0 [phi:main::@165->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1270] phi printf_ulong::format_min_length#11 = 0 [phi:main::@165->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1270] phi printf_ulong::putc#11 = &snputc [phi:main::@165->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1270] phi printf_ulong::format_radix#11 = DECIMAL [phi:main::@165->printf_ulong#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1270] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#10 [phi:main::@165->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [397] phi from main::@165 to main::@166 [phi:main::@165->main::@166]
    // main::@166
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [398] call printf_str
    // [873] phi from main::@166 to printf_str [phi:main::@166->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:main::@166->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = main::s17 [phi:main::@166->printf_str#1] -- pbuz1=pbuc1 
    lda #<s17
    sta.z printf_str.s
    lda #>s17
    sta.z printf_str.s+1
    jsr printf_str
    // main::@167
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [399] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [400] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_ERROR, info_text)
    // [402] display_info_rom::rom_chip#15 = main::rom_chip4#10 -- vbuz1=vbum2 
    lda rom_chip4
    sta.z display_info_rom.rom_chip
    // [403] call display_info_rom
    // [1069] phi from main::@167 to display_info_rom [phi:main::@167->display_info_rom]
    // [1069] phi display_info_rom::info_text#17 = info_text [phi:main::@167->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1069] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#15 [phi:main::@167->display_info_rom#1] -- register_copy 
    // [1069] phi display_info_rom::info_status#17 = STATUS_ERROR [phi:main::@167->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_rom.info_status
    jsr display_info_rom
    jmp __b43
    // main::@44
  __b44:
    // display_info_rom(rom_chip, STATUS_FLASHED, "No update required")
    // [404] display_info_rom::rom_chip#13 = main::rom_chip4#10 -- vbuz1=vbum2 
    lda rom_chip4
    sta.z display_info_rom.rom_chip
    // [405] call display_info_rom
    // [1069] phi from main::@44 to display_info_rom [phi:main::@44->display_info_rom]
    // [1069] phi display_info_rom::info_text#17 = main::info_text23 [phi:main::@44->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text23
    sta.z display_info_rom.info_text
    lda #>info_text23
    sta.z display_info_rom.info_text+1
    // [1069] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#13 [phi:main::@44->display_info_rom#1] -- register_copy 
    // [1069] phi display_info_rom::info_status#17 = STATUS_FLASHED [phi:main::@44->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHED
    sta.z display_info_rom.info_status
    jsr display_info_rom
    jmp __b43
    // [406] phi from main::@188 to main::@6 [phi:main::@188->main::@6]
    // main::@6
  __b6:
    // display_progress_clear()
    // [407] call display_progress_clear
    // [714] phi from main::@6 to display_progress_clear [phi:main::@6->display_progress_clear]
    jsr display_progress_clear
    // [408] phi from main::@6 to main::@144 [phi:main::@6->main::@144]
    // main::@144
    // smc_read()
    // [409] call smc_read
    // [968] phi from main::@144 to smc_read [phi:main::@144->smc_read]
    // [968] phi __errno#35 = __errno#112 [phi:main::@144->smc_read#0] -- register_copy 
    jsr smc_read
    // smc_read()
    // [410] smc_read::return#3 = smc_read::return#0
    // main::@145
    // smc_file_size = smc_read()
    // [411] smc_file_size#1 = smc_read::return#3 -- vwum1=vwuz2 
    lda.z smc_read.return
    sta smc_file_size_1
    lda.z smc_read.return+1
    sta smc_file_size_1+1
    // if(smc_file_size)
    // [412] if(0==smc_file_size#1) goto main::@2 -- 0_eq_vwum1_then_la1 
    lda smc_file_size_1
    ora smc_file_size_1+1
    bne !__b2+
    jmp __b2
  !__b2:
    // [413] phi from main::@145 to main::@7 [phi:main::@145->main::@7]
    // main::@7
    // display_action_text("Press both POWER/RESET buttons on the CX16 board!")
    // [414] call display_action_text
  // Flash the SMC chip.
    // [1046] phi from main::@7 to display_action_text [phi:main::@7->display_action_text]
    // [1046] phi display_action_text::info_text#19 = main::info_text16 [phi:main::@7->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text16
    sta.z display_action_text.info_text
    lda #>info_text16
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@146
    // [415] smc_file_size#382 = smc_file_size#1 -- vwum1=vwum2 
    lda smc_file_size_1
    sta smc_file_size_2
    lda smc_file_size_1+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_FLASHING, "Press POWER/RESET!")
    // [416] call display_info_smc
    // [758] phi from main::@146 to display_info_smc [phi:main::@146->display_info_smc]
    // [758] phi display_info_smc::info_text#13 = main::info_text17 [phi:main::@146->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text17
    sta.z display_info_smc.info_text
    lda #>info_text17
    sta.z display_info_smc.info_text+1
    // [758] phi smc_file_size#12 = smc_file_size#382 [phi:main::@146->display_info_smc#1] -- register_copy 
    // [758] phi display_info_smc::info_status#13 = STATUS_FLASHING [phi:main::@146->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHING
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // main::@147
    // unsigned long flashed_bytes = smc_flash(smc_file_size)
    // [417] smc_flash::smc_bytes_total#0 = smc_file_size#1 -- vwuz1=vwum2 
    lda smc_file_size_1
    sta.z smc_flash.smc_bytes_total
    lda smc_file_size_1+1
    sta.z smc_flash.smc_bytes_total+1
    // [418] call smc_flash
    // [1396] phi from main::@147 to smc_flash [phi:main::@147->smc_flash]
    jsr smc_flash
    // unsigned long flashed_bytes = smc_flash(smc_file_size)
    // [419] smc_flash::return#5 = smc_flash::return#1
    // main::@148
    // [420] main::flashed_bytes#0 = smc_flash::return#5 -- vdum1=vwuz2 
    lda.z smc_flash.return
    sta flashed_bytes
    lda.z smc_flash.return+1
    sta flashed_bytes+1
    lda #0
    sta flashed_bytes+2
    sta flashed_bytes+3
    // if(flashed_bytes)
    // [421] if(0!=main::flashed_bytes#0) goto main::@41 -- 0_neq_vdum1_then_la1 
    lda flashed_bytes
    ora flashed_bytes+1
    ora flashed_bytes+2
    ora flashed_bytes+3
    bne __b41
    // main::@8
    // [422] smc_file_size#380 = smc_file_size#1 -- vwum1=vwum2 
    lda smc_file_size_1
    sta smc_file_size_2
    lda smc_file_size_1+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_ERROR, "SMC not updated!")
    // [423] call display_info_smc
    // [758] phi from main::@8 to display_info_smc [phi:main::@8->display_info_smc]
    // [758] phi display_info_smc::info_text#13 = main::info_text19 [phi:main::@8->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text19
    sta.z display_info_smc.info_text
    lda #>info_text19
    sta.z display_info_smc.info_text+1
    // [758] phi smc_file_size#12 = smc_file_size#380 [phi:main::@8->display_info_smc#1] -- register_copy 
    // [758] phi display_info_smc::info_status#13 = STATUS_ERROR [phi:main::@8->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp __b2
    // main::@41
  __b41:
    // [424] smc_file_size#386 = smc_file_size#1 -- vwum1=vwum2 
    lda smc_file_size_1
    sta smc_file_size_2
    lda smc_file_size_1+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_FLASHED, "")
    // [425] call display_info_smc
    // [758] phi from main::@41 to display_info_smc [phi:main::@41->display_info_smc]
    // [758] phi display_info_smc::info_text#13 = info_text4 [phi:main::@41->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z display_info_smc.info_text
    lda #>info_text4
    sta.z display_info_smc.info_text+1
    // [758] phi smc_file_size#12 = smc_file_size#386 [phi:main::@41->display_info_smc#1] -- register_copy 
    // [758] phi display_info_smc::info_status#13 = STATUS_FLASHED [phi:main::@41->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHED
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp __b2
    // [426] phi from main::@186 main::@187 to main::@4 [phi:main::@186/main::@187->main::@4]
    // main::@4
  __b4:
    // display_action_progress("Chipsets have been detected and update files validated!")
    // [427] call display_action_progress
    // [700] phi from main::@4 to display_action_progress [phi:main::@4->display_action_progress]
    // [700] phi display_action_progress::info_text#14 = main::info_text10 [phi:main::@4->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text10
    sta.z display_action_progress.info_text
    lda #>info_text10
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [428] phi from main::@4 to main::@139 [phi:main::@4->main::@139]
    // main::@139
    // unsigned char ch = util_wait_key("Continue with update of highlighted chipsets? [Y/N]", "nyNY")
    // [429] call util_wait_key
    // [1558] phi from main::@139 to util_wait_key [phi:main::@139->util_wait_key]
    // [1558] phi util_wait_key::filter#12 = main::filter [phi:main::@139->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter
    sta.z util_wait_key.filter
    lda #>filter
    sta.z util_wait_key.filter+1
    // [1558] phi util_wait_key::info_text#2 = main::info_text11 [phi:main::@139->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text11
    sta.z util_wait_key.info_text
    lda #>info_text11
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("Continue with update of highlighted chipsets? [Y/N]", "nyNY")
    // [430] util_wait_key::return#3 = util_wait_key::ch#4 -- vbum1=vwuz2 
    lda.z util_wait_key.ch
    sta util_wait_key.return
    // main::@140
    // [431] main::ch#0 = util_wait_key::return#3
    // strchr("nN", ch)
    // [432] strchr::c#1 = main::ch#0 -- vbum1=vbum2 
    lda ch
    sta strchr.c
    // [433] call strchr
    // [1582] phi from main::@140 to strchr [phi:main::@140->strchr]
    // [1582] phi strchr::c#4 = strchr::c#1 [phi:main::@140->strchr#0] -- register_copy 
    // [1582] phi strchr::str#2 = (const void *)main::$217 [phi:main::@140->strchr#1] -- pvoz1=pvoc1 
    lda #<main__217
    sta.z strchr.str
    lda #>main__217
    sta.z strchr.str+1
    jsr strchr
    // strchr("nN", ch)
    // [434] strchr::return#4 = strchr::return#2
    // main::@141
    // [435] main::$119 = strchr::return#4
    // if(strchr("nN", ch))
    // [436] if((void *)0==main::$119) goto main::SEI5 -- pvoc1_eq_pvoz1_then_la1 
    lda.z main__119
    cmp #<0
    bne !+
    lda.z main__119+1
    cmp #>0
    bne !SEI5+
    jmp SEI5
  !SEI5:
  !:
    // main::@5
    // [437] smc_file_size#387 = smc_file_size#226 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_SKIP, "Cancelled")
    // [438] call display_info_smc
  // We cancel all updates, the updates are skipped.
    // [758] phi from main::@5 to display_info_smc [phi:main::@5->display_info_smc]
    // [758] phi display_info_smc::info_text#13 = main::info_text12 [phi:main::@5->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text12
    sta.z display_info_smc.info_text
    lda #>info_text12
    sta.z display_info_smc.info_text+1
    // [758] phi smc_file_size#12 = smc_file_size#387 [phi:main::@5->display_info_smc#1] -- register_copy 
    // [758] phi display_info_smc::info_status#13 = STATUS_SKIP [phi:main::@5->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [439] phi from main::@5 to main::@142 [phi:main::@5->main::@142]
    // main::@142
    // display_info_vera(STATUS_SKIP, "Cancelled")
    // [440] call display_info_vera
    // [788] phi from main::@142 to display_info_vera [phi:main::@142->display_info_vera]
    // [788] phi display_info_vera::info_text#10 = main::info_text12 [phi:main::@142->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text12
    sta.z display_info_vera.info_text
    lda #>info_text12
    sta.z display_info_vera.info_text+1
    // [788] phi display_info_vera::info_status#3 = STATUS_SKIP [phi:main::@142->display_info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // [441] phi from main::@142 to main::@38 [phi:main::@142->main::@38]
    // [441] phi main::rom_chip3#2 = 0 [phi:main::@142->main::@38#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip3
    // main::@38
  __b38:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [442] if(main::rom_chip3#2<8) goto main::@39 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip3
    cmp #8
    bcc __b39
    // [443] phi from main::@38 to main::@40 [phi:main::@38->main::@40]
    // main::@40
    // display_action_text("You have selected not to cancel the update ... ")
    // [444] call display_action_text
    // [1046] phi from main::@40 to display_action_text [phi:main::@40->display_action_text]
    // [1046] phi display_action_text::info_text#19 = main::info_text15 [phi:main::@40->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text15
    sta.z display_action_text.info_text
    lda #>info_text15
    sta.z display_action_text.info_text+1
    jsr display_action_text
    jmp SEI5
    // main::@39
  __b39:
    // display_info_rom(rom_chip, STATUS_SKIP, "Cancelled")
    // [445] display_info_rom::rom_chip#10 = main::rom_chip3#2 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z display_info_rom.rom_chip
    // [446] call display_info_rom
    // [1069] phi from main::@39 to display_info_rom [phi:main::@39->display_info_rom]
    // [1069] phi display_info_rom::info_text#17 = main::info_text12 [phi:main::@39->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text12
    sta.z display_info_rom.info_text
    lda #>info_text12
    sta.z display_info_rom.info_text+1
    // [1069] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#10 [phi:main::@39->display_info_rom#1] -- register_copy 
    // [1069] phi display_info_rom::info_status#17 = STATUS_SKIP [phi:main::@39->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // main::@143
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [447] main::rom_chip3#1 = ++ main::rom_chip3#2 -- vbum1=_inc_vbum1 
    inc rom_chip3
    // [441] phi from main::@143 to main::@38 [phi:main::@143->main::@38]
    // [441] phi main::rom_chip3#2 = main::rom_chip3#1 [phi:main::@143->main::@38#0] -- register_copy 
    jmp __b38
    // main::check_status_card_roms1_check_status_rom1
  check_status_card_roms1_check_status_rom1:
    // status_rom[rom_chip] == status
    // [448] main::check_status_card_roms1_check_status_rom1_$0 = status_rom[main::check_status_card_roms1_rom_chip#2] == STATUS_FLASH -- vbom1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_FLASH
    ldy check_status_card_roms1_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_card_roms1_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [449] main::check_status_card_roms1_check_status_rom1_return#0 = (char)main::check_status_card_roms1_check_status_rom1_$0
    // main::check_status_card_roms1_@11
    // if(check_status_rom(rom_chip, status))
    // [450] if(0==main::check_status_card_roms1_check_status_rom1_return#0) goto main::check_status_card_roms1_@4 -- 0_eq_vbum1_then_la1 
    lda check_status_card_roms1_check_status_rom1_return
    beq check_status_card_roms1___b4
    // [190] phi from main::check_status_card_roms1_@11 to main::check_status_card_roms1_@return [phi:main::check_status_card_roms1_@11->main::check_status_card_roms1_@return]
    // [190] phi main::check_status_card_roms1_return#2 = STATUS_FLASH [phi:main::check_status_card_roms1_@11->main::check_status_card_roms1_@return#0] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta check_status_card_roms1_return
    jmp __b70
    // main::check_status_card_roms1_@4
  check_status_card_roms1___b4:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [451] main::check_status_card_roms1_rom_chip#1 = ++ main::check_status_card_roms1_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_status_card_roms1_rom_chip
    // [188] phi from main::check_status_card_roms1_@4 to main::check_status_card_roms1_@1 [phi:main::check_status_card_roms1_@4->main::check_status_card_roms1_@1]
    // [188] phi main::check_status_card_roms1_rom_chip#2 = main::check_status_card_roms1_rom_chip#1 [phi:main::check_status_card_roms1_@4->main::check_status_card_roms1_@1#0] -- register_copy 
    jmp check_status_card_roms1___b1
    // [452] phi from main::@185 to main::@3 [phi:main::@185->main::@3]
    // main::@3
  __b3:
    // display_action_progress("The ROM must also be flashable, check the ROM issue.")
    // [453] call display_action_progress
    // [700] phi from main::@3 to display_action_progress [phi:main::@3->display_action_progress]
    // [700] phi display_action_progress::info_text#14 = main::info_text9 [phi:main::@3->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text9
    sta.z display_action_progress.info_text
    lda #>info_text9
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [454] phi from main::@3 to main::@137 [phi:main::@3->main::@137]
    // main::@137
    // display_info_cx16_rom(STATUS_ISSUE, NULL)
    // [455] call display_info_cx16_rom
    // [1591] phi from main::@137 to display_info_cx16_rom [phi:main::@137->display_info_cx16_rom]
    jsr display_info_cx16_rom
    // [456] phi from main::@137 to main::@138 [phi:main::@137->main::@138]
    // main::@138
    // util_wait_space()
    // [457] call util_wait_space
    // [824] phi from main::@138 to util_wait_space [phi:main::@138->util_wait_space]
    jsr util_wait_space
    jmp check_status_smc4
    // [458] phi from main::@184 to main::@37 [phi:main::@184->main::@37]
    // main::@37
  __b37:
    // display_action_progress("The SMC must also be flashable, check the SMC issue!")
    // [459] call display_action_progress
    // [700] phi from main::@37 to display_action_progress [phi:main::@37->display_action_progress]
    // [700] phi display_action_progress::info_text#14 = main::info_text8 [phi:main::@37->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z display_action_progress.info_text
    lda #>info_text8
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@135
    // [460] smc_file_size#381 = smc_file_size#226 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_ISSUE, NULL)
    // [461] call display_info_smc
    // [758] phi from main::@135 to display_info_smc [phi:main::@135->display_info_smc]
    // [758] phi display_info_smc::info_text#13 = 0 [phi:main::@135->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [758] phi smc_file_size#12 = smc_file_size#381 [phi:main::@135->display_info_smc#1] -- register_copy 
    // [758] phi display_info_smc::info_status#13 = STATUS_ISSUE [phi:main::@135->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [462] phi from main::@135 to main::@136 [phi:main::@135->main::@136]
    // main::@136
    // util_wait_space()
    // [463] call util_wait_space
    // [824] phi from main::@136 to util_wait_space [phi:main::@136->util_wait_space]
    jsr util_wait_space
    jmp check_status_smc3
    // main::bank_set_brom2
  bank_set_brom2:
    // BROM = bank
    // [464] BROM = main::bank_set_brom2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom2_bank
    sta.z BROM
    // main::@65
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [465] if(rom_device_ids[main::rom_chip2#10]==$55) goto main::@31 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    ldy rom_chip2
    lda rom_device_ids,y
    cmp #$55
    bne !__b31+
    jmp __b31
  !__b31:
    // [466] phi from main::@65 to main::@34 [phi:main::@65->main::@34]
    // main::@34
    // display_progress_clear()
    // [467] call display_progress_clear
    // [714] phi from main::@34 to display_progress_clear [phi:main::@34->display_progress_clear]
    jsr display_progress_clear
    // main::@113
    // unsigned char rom_bank = rom_chip * 32
    // [468] main::rom_bank#0 = main::rom_chip2#10 << 5 -- vbum1=vbum2_rol_5 
    lda rom_chip2
    asl
    asl
    asl
    asl
    asl
    sta rom_bank
    // unsigned char* file = rom_file(rom_chip)
    // [469] rom_file::rom_chip#0 = main::rom_chip2#10 -- vbuz1=vbum2 
    lda rom_chip2
    sta.z rom_file.rom_chip
    // [470] call rom_file
    // [1114] phi from main::@113 to rom_file [phi:main::@113->rom_file]
    // [1114] phi rom_file::rom_chip#2 = rom_file::rom_chip#0 [phi:main::@113->rom_file#0] -- register_copy 
    jsr rom_file
    // unsigned char* file = rom_file(rom_chip)
    // [471] rom_file::return#4 = rom_file::return#2
    // main::@114
    // [472] main::file#0 = rom_file::return#4 -- pbuz1=pbum2 
    lda rom_file.return
    sta.z file
    lda rom_file.return+1
    sta.z file+1
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [473] call snprintf_init
    // [868] phi from main::@114 to snprintf_init [phi:main::@114->snprintf_init]
    // [868] phi snprintf_init::s#25 = info_text [phi:main::@114->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [474] phi from main::@114 to main::@115 [phi:main::@114->main::@115]
    // main::@115
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [475] call printf_str
    // [873] phi from main::@115 to printf_str [phi:main::@115->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:main::@115->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = main::s6 [phi:main::@115->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // main::@116
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [476] printf_string::str#13 = main::file#0 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [477] call printf_string
    // [882] phi from main::@116 to printf_string [phi:main::@116->printf_string]
    // [882] phi printf_string::putc#19 = &snputc [phi:main::@116->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [882] phi printf_string::str#19 = printf_string::str#13 [phi:main::@116->printf_string#1] -- register_copy 
    // [882] phi printf_string::format_justify_left#19 = 0 [phi:main::@116->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [882] phi printf_string::format_min_length#19 = 0 [phi:main::@116->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [478] phi from main::@116 to main::@117 [phi:main::@116->main::@117]
    // main::@117
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [479] call printf_str
    // [873] phi from main::@117 to printf_str [phi:main::@117->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:main::@117->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = main::s7 [phi:main::@117->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@118
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [480] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [481] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_progress(info_text)
    // [483] call display_action_progress
    // [700] phi from main::@118 to display_action_progress [phi:main::@118->display_action_progress]
    // [700] phi display_action_progress::info_text#14 = info_text [phi:main::@118->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_progress.info_text
    lda #>@info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@119
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_CHECKING, rom_bank, rom_sizes[rom_chip])
    // [484] main::$196 = main::rom_chip2#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip2
    asl
    asl
    sta main__196
    // [485] rom_read::file#0 = main::file#0 -- pbuz1=pbuz2 
    lda.z file
    sta.z rom_read.file
    lda.z file+1
    sta.z rom_read.file+1
    // [486] rom_read::brom_bank_start#1 = main::rom_bank#0 -- vbuz1=vbum2 
    lda rom_bank
    sta.z rom_read.brom_bank_start
    // [487] rom_read::rom_size#0 = rom_sizes[main::$196] -- vduz1=pduc1_derefidx_vbum2 
    ldy main__196
    lda rom_sizes,y
    sta.z rom_read.rom_size
    lda rom_sizes+1,y
    sta.z rom_read.rom_size+1
    lda rom_sizes+2,y
    sta.z rom_read.rom_size+2
    lda rom_sizes+3,y
    sta.z rom_read.rom_size+3
    // [488] call rom_read
  // Read the ROM(n).BIN file.
    // [1120] phi from main::@119 to rom_read [phi:main::@119->rom_read]
    // [1120] phi rom_read::rom_size#12 = rom_read::rom_size#0 [phi:main::@119->rom_read#0] -- register_copy 
    // [1120] phi __errno#106 = __errno#112 [phi:main::@119->rom_read#1] -- register_copy 
    // [1120] phi rom_read::file#11 = rom_read::file#0 [phi:main::@119->rom_read#2] -- register_copy 
    // [1120] phi rom_read::brom_bank_start#21 = rom_read::brom_bank_start#1 [phi:main::@119->rom_read#3] -- register_copy 
    jsr rom_read
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_CHECKING, rom_bank, rom_sizes[rom_chip])
    // [489] rom_read::return#2 = rom_read::return#0
    // main::@120
    // [490] main::rom_bytes_read#0 = rom_read::return#2
    // if (!rom_bytes_read)
    // [491] if(0==main::rom_bytes_read#0) goto main::@32 -- 0_eq_vduz1_then_la1 
    // In case no file was found, set the status to none and skip to the next, else, mention the amount of bytes read.
    lda.z rom_bytes_read
    ora.z rom_bytes_read+1
    ora.z rom_bytes_read+2
    ora.z rom_bytes_read+3
    bne !__b32+
    jmp __b32
  !__b32:
    // main::@35
    // unsigned long rom_file_modulo = rom_bytes_read % 0x4000
    // [492] main::rom_file_modulo#0 = main::rom_bytes_read#0 & $4000-1 -- vduz1=vduz2_band_vduc1 
    // If the rom size is not a factor or 0x4000 bytes, then there is an error.
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
    // [493] if(0!=main::rom_file_modulo#0) goto main::@33 -- 0_neq_vduz1_then_la1 
    lda.z rom_file_modulo
    ora.z rom_file_modulo+1
    ora.z rom_file_modulo+2
    ora.z rom_file_modulo+3
    beq !__b33+
    jmp __b33
  !__b33:
    // main::@36
    // file_sizes[rom_chip] = rom_bytes_read
    // [494] file_sizes[main::$196] = main::rom_bytes_read#0 -- pduc1_derefidx_vbum1=vduz2 
    // We know the file size, so we indicate it in the status panel.
    ldy main__196
    lda.z rom_bytes_read
    sta file_sizes,y
    lda.z rom_bytes_read+1
    sta file_sizes+1,y
    lda.z rom_bytes_read+2
    sta file_sizes+2,y
    lda.z rom_bytes_read+3
    sta file_sizes+3,y
    // strncpy(rom_github[rom_chip], (char*)RAM_BASE, 6)
    // [495] main::$198 = main::rom_chip2#10 << 1 -- vbum1=vbum2_rol_1 
    lda rom_chip2
    asl
    sta main__198
    // [496] strncpy::dst#2 = rom_github[main::$198] -- pbuz1=qbuc1_derefidx_vbum2 
    tay
    lda rom_github,y
    sta.z strncpy.dst
    lda rom_github+1,y
    sta.z strncpy.dst+1
    // [497] call strncpy
  // Fill the version data ...
  // TODO: I need to make a function for this, and calculate it properly! 
  // TODO: It seems currently not to work like I would expect.
    // [1594] phi from main::@36 to strncpy [phi:main::@36->strncpy]
    // [1594] phi strncpy::dst#8 = strncpy::dst#2 [phi:main::@36->strncpy#0] -- register_copy 
    // [1594] phi strncpy::src#6 = (char *)$6000 [phi:main::@36->strncpy#1] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z strncpy.src
    lda #>$6000
    sta.z strncpy.src+1
    // [1594] phi strncpy::n#3 = 6 [phi:main::@36->strncpy#2] -- vwum1=vbuc1 
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
    // [499] BRAM = main::bank_push_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_push_set_bram1_bank
    sta.z BRAM
    // main::@67
    // rom_release[rom_chip] = *((char*)0xBF80)
    // [500] rom_release[main::rom_chip2#10] = *((char *) 49024) -- pbuc1_derefidx_vbum1=_deref_pbuc2 
    lda $bf80
    ldy rom_chip2
    sta rom_release,y
    // main::bank_pull_bram1
    // asm
    // asm { pla sta$00  }
    pla
    sta.z 0
    // [502] phi from main::bank_pull_bram1 to main::@68 [phi:main::bank_pull_bram1->main::@68]
    // main::@68
    // sprintf(info_text, "%s:R%u/%s", file, rom_release[rom_chip], rom_github[rom_chip])
    // [503] call snprintf_init
    // [868] phi from main::@68 to snprintf_init [phi:main::@68->snprintf_init]
    // [868] phi snprintf_init::s#25 = info_text [phi:main::@68->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main::@129
    // sprintf(info_text, "%s:R%u/%s", file, rom_release[rom_chip], rom_github[rom_chip])
    // [504] printf_string::str#16 = main::file#0 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [505] call printf_string
    // [882] phi from main::@129 to printf_string [phi:main::@129->printf_string]
    // [882] phi printf_string::putc#19 = &snputc [phi:main::@129->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [882] phi printf_string::str#19 = printf_string::str#16 [phi:main::@129->printf_string#1] -- register_copy 
    // [882] phi printf_string::format_justify_left#19 = 0 [phi:main::@129->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [882] phi printf_string::format_min_length#19 = 0 [phi:main::@129->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [506] phi from main::@129 to main::@130 [phi:main::@129->main::@130]
    // main::@130
    // sprintf(info_text, "%s:R%u/%s", file, rom_release[rom_chip], rom_github[rom_chip])
    // [507] call printf_str
    // [873] phi from main::@130 to printf_str [phi:main::@130->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:main::@130->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = main::s12 [phi:main::@130->printf_str#1] -- pbuz1=pbuc1 
    lda #<s12
    sta.z printf_str.s
    lda #>s12
    sta.z printf_str.s+1
    jsr printf_str
    // main::@131
    // sprintf(info_text, "%s:R%u/%s", file, rom_release[rom_chip], rom_github[rom_chip])
    // [508] printf_uchar::uvalue#8 = rom_release[main::rom_chip2#10] -- vbum1=pbuc1_derefidx_vbum2 
    ldy rom_chip2
    lda rom_release,y
    sta printf_uchar.uvalue
    // [509] call printf_uchar
    // [1035] phi from main::@131 to printf_uchar [phi:main::@131->printf_uchar]
    // [1035] phi printf_uchar::format_zero_padding#11 = 0 [phi:main::@131->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1035] phi printf_uchar::format_min_length#11 = 0 [phi:main::@131->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1035] phi printf_uchar::putc#11 = &snputc [phi:main::@131->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1035] phi printf_uchar::format_radix#11 = DECIMAL [phi:main::@131->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1035] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#8 [phi:main::@131->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [510] phi from main::@131 to main::@132 [phi:main::@131->main::@132]
    // main::@132
    // sprintf(info_text, "%s:R%u/%s", file, rom_release[rom_chip], rom_github[rom_chip])
    // [511] call printf_str
    // [873] phi from main::@132 to printf_str [phi:main::@132->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:main::@132->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = s4 [phi:main::@132->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s4
    sta.z printf_str.s
    lda #>@s4
    sta.z printf_str.s+1
    jsr printf_str
    // main::@133
    // sprintf(info_text, "%s:R%u/%s", file, rom_release[rom_chip], rom_github[rom_chip])
    // [512] printf_string::str#17 = rom_github[main::$198] -- pbuz1=qbuc1_derefidx_vbum2 
    ldy main__198
    lda rom_github,y
    sta.z printf_string.str
    lda rom_github+1,y
    sta.z printf_string.str+1
    // [513] call printf_string
    // [882] phi from main::@133 to printf_string [phi:main::@133->printf_string]
    // [882] phi printf_string::putc#19 = &snputc [phi:main::@133->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [882] phi printf_string::str#19 = printf_string::str#17 [phi:main::@133->printf_string#1] -- register_copy 
    // [882] phi printf_string::format_justify_left#19 = 0 [phi:main::@133->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [882] phi printf_string::format_min_length#19 = 0 [phi:main::@133->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // main::@134
    // sprintf(info_text, "%s:R%u/%s", file, rom_release[rom_chip], rom_github[rom_chip])
    // [514] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [515] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_FLASH, info_text)
    // [517] display_info_rom::rom_chip#9 = main::rom_chip2#10 -- vbuz1=vbum2 
    lda rom_chip2
    sta.z display_info_rom.rom_chip
    // [518] call display_info_rom
    // [1069] phi from main::@134 to display_info_rom [phi:main::@134->display_info_rom]
    // [1069] phi display_info_rom::info_text#17 = info_text [phi:main::@134->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1069] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#9 [phi:main::@134->display_info_rom#1] -- register_copy 
    // [1069] phi display_info_rom::info_status#17 = STATUS_FLASH [phi:main::@134->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASH
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // [519] phi from main::@124 main::@128 main::@134 main::@65 to main::@31 [phi:main::@124/main::@128/main::@134/main::@65->main::@31]
    // [519] phi __errno#239 = __errno#179 [phi:main::@124/main::@128/main::@134/main::@65->main::@31#0] -- register_copy 
    // main::@31
  __b31:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [520] main::rom_chip2#1 = ++ main::rom_chip2#10 -- vbum1=_inc_vbum1 
    inc rom_chip2
    // [164] phi from main::@31 to main::@30 [phi:main::@31->main::@30]
    // [164] phi __errno#112 = __errno#239 [phi:main::@31->main::@30#0] -- register_copy 
    // [164] phi main::rom_chip2#10 = main::rom_chip2#1 [phi:main::@31->main::@30#1] -- register_copy 
    jmp __b30
    // [521] phi from main::@35 to main::@33 [phi:main::@35->main::@33]
    // main::@33
  __b33:
    // sprintf(info_text, "File %s size error!", file)
    // [522] call snprintf_init
    // [868] phi from main::@33 to snprintf_init [phi:main::@33->snprintf_init]
    // [868] phi snprintf_init::s#25 = info_text [phi:main::@33->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [523] phi from main::@33 to main::@125 [phi:main::@33->main::@125]
    // main::@125
    // sprintf(info_text, "File %s size error!", file)
    // [524] call printf_str
    // [873] phi from main::@125 to printf_str [phi:main::@125->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:main::@125->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = main::s10 [phi:main::@125->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // main::@126
    // sprintf(info_text, "File %s size error!", file)
    // [525] printf_string::str#15 = main::file#0 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [526] call printf_string
    // [882] phi from main::@126 to printf_string [phi:main::@126->printf_string]
    // [882] phi printf_string::putc#19 = &snputc [phi:main::@126->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [882] phi printf_string::str#19 = printf_string::str#15 [phi:main::@126->printf_string#1] -- register_copy 
    // [882] phi printf_string::format_justify_left#19 = 0 [phi:main::@126->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [882] phi printf_string::format_min_length#19 = 0 [phi:main::@126->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [527] phi from main::@126 to main::@127 [phi:main::@126->main::@127]
    // main::@127
    // sprintf(info_text, "File %s size error!", file)
    // [528] call printf_str
    // [873] phi from main::@127 to printf_str [phi:main::@127->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:main::@127->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = main::s11 [phi:main::@127->printf_str#1] -- pbuz1=pbuc1 
    lda #<s11
    sta.z printf_str.s
    lda #>s11
    sta.z printf_str.s+1
    jsr printf_str
    // main::@128
    // sprintf(info_text, "File %s size error!", file)
    // [529] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [530] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_ERROR, info_text)
    // [532] display_info_rom::rom_chip#8 = main::rom_chip2#10 -- vbuz1=vbum2 
    lda rom_chip2
    sta.z display_info_rom.rom_chip
    // [533] call display_info_rom
    // [1069] phi from main::@128 to display_info_rom [phi:main::@128->display_info_rom]
    // [1069] phi display_info_rom::info_text#17 = info_text [phi:main::@128->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1069] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#8 [phi:main::@128->display_info_rom#1] -- register_copy 
    // [1069] phi display_info_rom::info_status#17 = STATUS_ERROR [phi:main::@128->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_rom.info_status
    jsr display_info_rom
    jmp __b31
    // [534] phi from main::@120 to main::@32 [phi:main::@120->main::@32]
    // main::@32
  __b32:
    // sprintf(info_text, "No %s, skipped", file)
    // [535] call snprintf_init
    // [868] phi from main::@32 to snprintf_init [phi:main::@32->snprintf_init]
    // [868] phi snprintf_init::s#25 = info_text [phi:main::@32->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [536] phi from main::@32 to main::@121 [phi:main::@32->main::@121]
    // main::@121
    // sprintf(info_text, "No %s, skipped", file)
    // [537] call printf_str
    // [873] phi from main::@121 to printf_str [phi:main::@121->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:main::@121->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = main::s8 [phi:main::@121->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // main::@122
    // sprintf(info_text, "No %s, skipped", file)
    // [538] printf_string::str#14 = main::file#0 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [539] call printf_string
    // [882] phi from main::@122 to printf_string [phi:main::@122->printf_string]
    // [882] phi printf_string::putc#19 = &snputc [phi:main::@122->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [882] phi printf_string::str#19 = printf_string::str#14 [phi:main::@122->printf_string#1] -- register_copy 
    // [882] phi printf_string::format_justify_left#19 = 0 [phi:main::@122->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [882] phi printf_string::format_min_length#19 = 0 [phi:main::@122->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [540] phi from main::@122 to main::@123 [phi:main::@122->main::@123]
    // main::@123
    // sprintf(info_text, "No %s, skipped", file)
    // [541] call printf_str
    // [873] phi from main::@123 to printf_str [phi:main::@123->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:main::@123->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = main::s9 [phi:main::@123->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // main::@124
    // sprintf(info_text, "No %s, skipped", file)
    // [542] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [543] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_NONE, info_text)
    // [545] display_info_rom::rom_chip#7 = main::rom_chip2#10 -- vbuz1=vbum2 
    lda rom_chip2
    sta.z display_info_rom.rom_chip
    // [546] call display_info_rom
    // [1069] phi from main::@124 to display_info_rom [phi:main::@124->display_info_rom]
    // [1069] phi display_info_rom::info_text#17 = info_text [phi:main::@124->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1069] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#7 [phi:main::@124->display_info_rom#1] -- register_copy 
    // [1069] phi display_info_rom::info_status#17 = STATUS_NONE [phi:main::@124->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_NONE
    sta.z display_info_rom.info_status
    jsr display_info_rom
    jmp __b31
    // main::@29
  __b29:
    // [547] smc_file_size#385 = smc_file_size#0 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_ISSUE, "SMC.BIN too large!")
    // [548] call display_info_smc
    // [758] phi from main::@29 to display_info_smc [phi:main::@29->display_info_smc]
    // [758] phi display_info_smc::info_text#13 = main::info_text7 [phi:main::@29->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z display_info_smc.info_text
    lda #>info_text7
    sta.z display_info_smc.info_text+1
    // [758] phi smc_file_size#12 = smc_file_size#385 [phi:main::@29->display_info_smc#1] -- register_copy 
    // [758] phi display_info_smc::info_status#13 = STATUS_ISSUE [phi:main::@29->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp CLI3
    // main::@28
  __b28:
    // [549] smc_file_size#384 = smc_file_size#0 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_ISSUE, "No SMC.BIN!")
    // [550] call display_info_smc
    // [758] phi from main::@28 to display_info_smc [phi:main::@28->display_info_smc]
    // [758] phi display_info_smc::info_text#13 = main::info_text6 [phi:main::@28->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text6
    sta.z display_info_smc.info_text
    lda #>info_text6
    sta.z display_info_smc.info_text+1
    // [758] phi smc_file_size#12 = smc_file_size#384 [phi:main::@28->display_info_smc#1] -- register_copy 
    // [758] phi display_info_smc::info_status#13 = STATUS_ISSUE [phi:main::@28->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp CLI3
    // main::@21
  __b21:
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [551] if(rom_device_ids[main::rom_chip1#2]!=$55) goto main::@22 -- pbuc1_derefidx_vbum1_neq_vbuc2_then_la1 
    lda #$55
    ldy rom_chip1
    cmp rom_device_ids,y
    bne __b22
    // main::@24
    // display_info_rom(rom_chip, STATUS_NONE, "")
    // [552] display_info_rom::rom_chip#6 = main::rom_chip1#2 -- vbuz1=vbum2 
    tya
    sta.z display_info_rom.rom_chip
    // [553] call display_info_rom
    // [1069] phi from main::@24 to display_info_rom [phi:main::@24->display_info_rom]
    // [1069] phi display_info_rom::info_text#17 = info_text4 [phi:main::@24->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z display_info_rom.info_text
    lda #>info_text4
    sta.z display_info_rom.info_text+1
    // [1069] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#6 [phi:main::@24->display_info_rom#1] -- register_copy 
    // [1069] phi display_info_rom::info_status#17 = STATUS_NONE [phi:main::@24->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_NONE
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // main::@23
  __b23:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [554] main::rom_chip1#1 = ++ main::rom_chip1#2 -- vbum1=_inc_vbum1 
    inc rom_chip1
    // [146] phi from main::@23 to main::@20 [phi:main::@23->main::@20]
    // [146] phi main::rom_chip1#2 = main::rom_chip1#1 [phi:main::@23->main::@20#0] -- register_copy 
    jmp __b20
    // main::@22
  __b22:
    // display_info_rom(rom_chip, STATUS_DETECTED, "")
    // [555] display_info_rom::rom_chip#5 = main::rom_chip1#2 -- vbuz1=vbum2 
    lda rom_chip1
    sta.z display_info_rom.rom_chip
    // [556] call display_info_rom
    // [1069] phi from main::@22 to display_info_rom [phi:main::@22->display_info_rom]
    // [1069] phi display_info_rom::info_text#17 = info_text4 [phi:main::@22->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z display_info_rom.info_text
    lda #>info_text4
    sta.z display_info_rom.info_text+1
    // [1069] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#5 [phi:main::@22->display_info_rom#1] -- register_copy 
    // [1069] phi display_info_rom::info_status#17 = STATUS_DETECTED [phi:main::@22->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_DETECTED
    sta.z display_info_rom.info_status
    jsr display_info_rom
    jmp __b23
    // [557] phi from main::@16 to main::@19 [phi:main::@16->main::@19]
    // main::@19
  __b19:
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [558] call snprintf_init
    // [868] phi from main::@19 to snprintf_init [phi:main::@19->snprintf_init]
    // [868] phi snprintf_init::s#25 = info_text [phi:main::@19->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [559] phi from main::@19 to main::@99 [phi:main::@19->main::@99]
    // main::@99
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [560] call printf_str
    // [873] phi from main::@99 to printf_str [phi:main::@99->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:main::@99->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = main::s2 [phi:main::@99->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main::@100
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [561] printf_uint::uvalue#16 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta printf_uint.uvalue
    lda smc_bootloader+1
    sta printf_uint.uvalue+1
    // [562] call printf_uint
    // [907] phi from main::@100 to printf_uint [phi:main::@100->printf_uint]
    // [907] phi printf_uint::format_zero_padding#18 = 1 [phi:main::@100->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [907] phi printf_uint::format_min_length#18 = 2 [phi:main::@100->printf_uint#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uint.format_min_length
    // [907] phi printf_uint::putc#18 = &snputc [phi:main::@100->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [907] phi printf_uint::format_radix#18 = HEXADECIMAL [phi:main::@100->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [907] phi printf_uint::uvalue#18 = printf_uint::uvalue#16 [phi:main::@100->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [563] phi from main::@100 to main::@101 [phi:main::@100->main::@101]
    // main::@101
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [564] call printf_str
    // [873] phi from main::@101 to printf_str [phi:main::@101->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:main::@101->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = main::s3 [phi:main::@101->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // main::@102
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [565] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [566] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_smc(STATUS_ISSUE, info_text)
    // [568] call display_info_smc
    // [758] phi from main::@102 to display_info_smc [phi:main::@102->display_info_smc]
    // [758] phi display_info_smc::info_text#13 = info_text [phi:main::@102->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_smc.info_text
    lda #>@info_text
    sta.z display_info_smc.info_text+1
    // [758] phi smc_file_size#12 = 0 [phi:main::@102->display_info_smc#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size_2
    sta smc_file_size_2+1
    // [758] phi display_info_smc::info_status#13 = STATUS_ISSUE [phi:main::@102->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [569] phi from main::@102 to main::@103 [phi:main::@102->main::@103]
    // main::@103
    // display_progress_text(display_no_valid_smc_bootloader_text, display_no_valid_smc_bootloader_count)
    // [570] call display_progress_text
  // Bootloader is not supported by this utility, but is not error.
    // [814] phi from main::@103 to display_progress_text [phi:main::@103->display_progress_text]
    // [814] phi display_progress_text::text#10 = display_no_valid_smc_bootloader_text [phi:main::@103->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_no_valid_smc_bootloader_text
    sta.z display_progress_text.text
    lda #>display_no_valid_smc_bootloader_text
    sta.z display_progress_text.text+1
    // [814] phi display_progress_text::lines#7 = display_no_valid_smc_bootloader_count [phi:main::@103->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_no_valid_smc_bootloader_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    jmp CLI1
    // [571] phi from main::@15 to main::@18 [phi:main::@15->main::@18]
    // main::@18
  __b18:
    // display_info_smc(STATUS_ERROR, "SMC Unreachable!")
    // [572] call display_info_smc
    // [758] phi from main::@18 to display_info_smc [phi:main::@18->display_info_smc]
    // [758] phi display_info_smc::info_text#13 = main::info_text2 [phi:main::@18->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z display_info_smc.info_text
    lda #>info_text2
    sta.z display_info_smc.info_text+1
    // [758] phi smc_file_size#12 = 0 [phi:main::@18->display_info_smc#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size_2
    sta smc_file_size_2+1
    // [758] phi display_info_smc::info_status#13 = STATUS_ERROR [phi:main::@18->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp CLI1
    // [573] phi from main::@97 to main::@1 [phi:main::@97->main::@1]
    // main::@1
  __b1:
    // display_info_smc(STATUS_ISSUE, "No Bootloader!")
    // [574] call display_info_smc
    // [758] phi from main::@1 to display_info_smc [phi:main::@1->display_info_smc]
    // [758] phi display_info_smc::info_text#13 = main::info_text1 [phi:main::@1->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_smc.info_text
    lda #>info_text1
    sta.z display_info_smc.info_text+1
    // [758] phi smc_file_size#12 = 0 [phi:main::@1->display_info_smc#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size_2
    sta smc_file_size_2+1
    // [758] phi display_info_smc::info_status#13 = STATUS_ISSUE [phi:main::@1->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [575] phi from main::@1 to main::@98 [phi:main::@1->main::@98]
    // main::@98
    // display_progress_text(display_no_valid_smc_bootloader_text, display_no_valid_smc_bootloader_count)
    // [576] call display_progress_text
  // If the CX16 board does not have a bootloader, display info how to flash bootloader.
    // [814] phi from main::@98 to display_progress_text [phi:main::@98->display_progress_text]
    // [814] phi display_progress_text::text#10 = display_no_valid_smc_bootloader_text [phi:main::@98->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_no_valid_smc_bootloader_text
    sta.z display_progress_text.text
    lda #>display_no_valid_smc_bootloader_text
    sta.z display_progress_text.text+1
    // [814] phi display_progress_text::lines#7 = display_no_valid_smc_bootloader_count [phi:main::@98->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_no_valid_smc_bootloader_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    jmp CLI1
    // main::@13
  __b13:
    // display_info_led(PROGRESS_X + 3, PROGRESS_Y + 3 + intro_status, status_color[intro_status], BLUE)
    // [577] display_info_led::y#3 = PROGRESS_Y+3 + main::intro_status#2 -- vbuz1=vbuc1_plus_vbum2 
    lda #PROGRESS_Y+3
    clc
    adc intro_status
    sta.z display_info_led.y
    // [578] display_info_led::tc#3 = status_color[main::intro_status#2] -- vbuz1=pbuc1_derefidx_vbum2 
    ldy intro_status
    lda status_color,y
    sta.z display_info_led.tc
    // [579] call display_info_led
    // [1605] phi from main::@13 to display_info_led [phi:main::@13->display_info_led]
    // [1605] phi display_info_led::y#4 = display_info_led::y#3 [phi:main::@13->display_info_led#0] -- register_copy 
    // [1605] phi display_info_led::x#4 = PROGRESS_X+3 [phi:main::@13->display_info_led#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X+3
    sta.z display_info_led.x
    // [1605] phi display_info_led::tc#4 = display_info_led::tc#3 [phi:main::@13->display_info_led#2] -- register_copy 
    jsr display_info_led
    // main::@94
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [580] main::intro_status#1 = ++ main::intro_status#2 -- vbum1=_inc_vbum1 
    inc intro_status
    // [105] phi from main::@94 to main::@12 [phi:main::@94->main::@12]
    // [105] phi main::intro_status#2 = main::intro_status#1 [phi:main::@94->main::@12#0] -- register_copy 
    jmp __b12
    // main::@10
  __b10:
    // display_info_rom(rom_chip, STATUS_NONE, NULL)
    // [581] display_info_rom::rom_chip#4 = main::rom_chip#2 -- vbuz1=vwum2 
    lda rom_chip
    sta.z display_info_rom.rom_chip
    // [582] call display_info_rom
    // [1069] phi from main::@10 to display_info_rom [phi:main::@10->display_info_rom]
    // [1069] phi display_info_rom::info_text#17 = 0 [phi:main::@10->display_info_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_rom.info_text
    sta.z display_info_rom.info_text+1
    // [1069] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#4 [phi:main::@10->display_info_rom#1] -- register_copy 
    // [1069] phi display_info_rom::info_status#17 = STATUS_NONE [phi:main::@10->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_NONE
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // main::@91
    // for(unsigned rom_chip=0; rom_chip<8; rom_chip++)
    // [583] main::rom_chip#1 = ++ main::rom_chip#2 -- vwum1=_inc_vwum1 
    inc rom_chip
    bne !+
    inc rom_chip+1
  !:
    // [97] phi from main::@91 to main::@9 [phi:main::@91->main::@9]
    // [97] phi main::rom_chip#2 = main::rom_chip#1 [phi:main::@91->main::@9#0] -- register_copy 
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
    main__217: .text "nN"
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
    s18: .text "Please read carefully the below ("
    .byte 0
    s19: .text ") ..."
    .byte 0
    s20: .text "Please disconnect your CX16 from power source ..."
    .byte 0
    s21: .text "("
    .byte 0
    s22: .text ") Your CX16 will reset ..."
    .byte 0
    main__196: .byte 0
    main__198: .byte 0
    main__200: .byte 0
    check_status_smc3_main__0: .byte 0
    check_status_smc4_main__0: .byte 0
    check_status_card_roms1_check_status_rom1_main__0: .byte 0
    check_status_rom1_main__0: .byte 0
    check_status_vera1_main__0: .byte 0
    check_status_roms_all1_check_status_rom1_main__0: .byte 0
    check_status_smc7_main__0: .byte 0
    check_status_smc8_main__0: .byte 0
    check_status_vera2_main__0: .byte 0
    check_status_roms1_check_status_rom1_main__0: .byte 0
    check_status_smc9_main__0: .byte 0
    check_status_roms2_check_status_rom1_main__0: .byte 0
    check_status_smc10_main__0: .byte 0
    rom_chip: .word 0
    intro_status: .byte 0
    rom_chip1: .byte 0
    rom_chip2: .byte 0
    rom_bank: .byte 0
    .label check_status_smc3_return = check_status_smc3_main__0
    .label check_status_smc4_return = check_status_smc4_main__0
    .label check_status_card_roms1_check_status_rom1_return = check_status_card_roms1_check_status_rom1_main__0
    check_status_card_roms1_rom_chip: .byte 0
    check_status_card_roms1_return: .byte 0
    .label ch = util_wait_key.return
    rom_chip3: .byte 0
    flashed_bytes: .dword 0
    .label check_status_rom1_return = check_status_rom1_main__0
    .label check_status_vera1_return = check_status_vera1_main__0
    .label check_status_roms_all1_check_status_rom1_return = check_status_roms_all1_check_status_rom1_main__0
    check_status_roms_all1_rom_chip: .byte 0
    check_status_roms_all1_return: .byte 0
    rom_chip4: .byte 0
    .label check_status_smc7_return = check_status_smc7_main__0
    rom_bank1: .byte 0
    .label file1 = rom_file.return
    rom_flash_errors: .dword 0
    .label check_status_smc8_return = check_status_smc8_main__0
    .label check_status_vera2_return = check_status_vera2_main__0
    .label check_status_roms1_check_status_rom1_return = check_status_roms1_check_status_rom1_main__0
    check_status_roms1_rom_chip: .byte 0
    check_status_roms1_return: .byte 0
    .label check_status_smc9_return = check_status_smc9_main__0
    .label check_status_roms2_check_status_rom1_return = check_status_roms2_check_status_rom1_main__0
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
    // [584] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbum1=_deref_pbuc1 
    lda VERA_L1_MAPBASE
    sta screenlayer.mapbase
    // [585] screenlayer::config#0 = *VERA_L1_CONFIG -- vbum1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta screenlayer.config
    // [586] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [587] return 
    rts
}
  // textcolor
// Set the front color for text output. The old front text color setting is returned.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char textcolor(__mem() char color)
textcolor: {
    .label textcolor__0 = $bb
    .label textcolor__1 = $bb
    // __conio.color & 0xF0
    // [589] textcolor::$0 = *((char *)&__conio+$d) & $f0 -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$d
    sta.z textcolor__0
    // __conio.color & 0xF0 | color
    // [590] textcolor::$1 = textcolor::$0 | textcolor::color#18 -- vbuz1=vbuz1_bor_vbum2 
    lda color
    ora.z textcolor__1
    sta.z textcolor__1
    // __conio.color = __conio.color & 0xF0 | color
    // [591] *((char *)&__conio+$d) = textcolor::$1 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // textcolor::@return
    // }
    // [592] return 
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
    .label bgcolor__0 = $bb
    .label bgcolor__1 = $bc
    .label bgcolor__2 = $bb
    // __conio.color & 0x0F
    // [594] bgcolor::$0 = *((char *)&__conio+$d) & $f -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$d
    sta.z bgcolor__0
    // color << 4
    // [595] bgcolor::$1 = bgcolor::color#14 << 4 -- vbuz1=vbum2_rol_4 
    lda color
    asl
    asl
    asl
    asl
    sta.z bgcolor__1
    // __conio.color & 0x0F | color << 4
    // [596] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbuz1=vbuz1_bor_vbuz2 
    lda.z bgcolor__2
    ora.z bgcolor__1
    sta.z bgcolor__2
    // __conio.color = __conio.color & 0x0F | color << 4
    // [597] *((char *)&__conio+$d) = bgcolor::$2 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // bgcolor::@return
    // }
    // [598] return 
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
    // [599] *((char *)&__conio+$c) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$c
    // cursor::@return
    // }
    // [600] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    // __mem unsigned char x
    // [601] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [602] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [604] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwum1=vbum2_word_vbum3 
    lda x
    sta return+1
    lda y
    sta return
    // cbm_k_plot_get::@return
    // }
    // [605] return 
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
    // [607] if(gotoxy::x#30>=*((char *)&__conio+6)) goto gotoxy::@1 -- vbum1_ge__deref_pbuc1_then_la1 
    lda x
    cmp __conio+6
    bcs __b1
    // [609] phi from gotoxy to gotoxy::@2 [phi:gotoxy->gotoxy::@2]
    // [609] phi gotoxy::$3 = gotoxy::x#30 [phi:gotoxy->gotoxy::@2#0] -- vbuz1=vbum2 
    sta.z gotoxy__3
    jmp __b2
    // gotoxy::@1
  __b1:
    // [608] gotoxy::$2 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z gotoxy__2
    // [609] phi from gotoxy::@1 to gotoxy::@2 [phi:gotoxy::@1->gotoxy::@2]
    // [609] phi gotoxy::$3 = gotoxy::$2 [phi:gotoxy::@1->gotoxy::@2#0] -- register_copy 
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [610] *((char *)&__conio) = gotoxy::$3 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__3
    sta __conio
    // (y>=__conio.height)?__conio.height:y
    // [611] if(gotoxy::y#30>=*((char *)&__conio+7)) goto gotoxy::@3 -- vbum1_ge__deref_pbuc1_then_la1 
    lda y
    cmp __conio+7
    bcs __b3
    // gotoxy::@4
    // [612] gotoxy::$14 = gotoxy::y#30 -- vbuz1=vbum2 
    sta.z gotoxy__14
    // [613] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [613] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [614] *((char *)&__conio+1) = gotoxy::$7 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__7
    sta __conio+1
    // __conio.cursor_x << 1
    // [615] gotoxy::$8 = *((char *)&__conio) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio
    asl
    sta.z gotoxy__8
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [616] gotoxy::$10 = gotoxy::y#30 << 1 -- vbuz1=vbum2_rol_1 
    lda y
    asl
    sta.z gotoxy__10
    // [617] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwuz1=pwuc1_derefidx_vbuz2_plus_vbuz3 
    lda.z gotoxy__8
    ldy.z gotoxy__10
    clc
    adc __conio+$15,y
    sta.z gotoxy__9
    lda __conio+$15+1,y
    adc #0
    sta.z gotoxy__9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [618] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwuz1 
    lda.z gotoxy__9
    sta __conio+$13
    lda.z gotoxy__9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [619] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [620] gotoxy::$6 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
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
    .label cputln__2 = $51
    // __conio.cursor_x = 0
    // [621] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y++;
    // [622] *((char *)&__conio+1) = ++ *((char *)&__conio+1) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+1
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [623] cputln::$2 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z cputln__2
    // [624] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [625] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [626] return 
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
    // [628] call textcolor
  // Set the charset to lower case.
  // screenlayer1();
    // [588] phi from display_frame_init_64 to textcolor [phi:display_frame_init_64->textcolor]
    // [588] phi textcolor::color#18 = WHITE [phi:display_frame_init_64->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [629] phi from display_frame_init_64 to display_frame_init_64::@2 [phi:display_frame_init_64->display_frame_init_64::@2]
    // display_frame_init_64::@2
    // bgcolor(BLUE)
    // [630] call bgcolor
    // [593] phi from display_frame_init_64::@2 to bgcolor [phi:display_frame_init_64::@2->bgcolor]
    // [593] phi bgcolor::color#14 = BLUE [phi:display_frame_init_64::@2->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [631] phi from display_frame_init_64::@2 to display_frame_init_64::@3 [phi:display_frame_init_64::@2->display_frame_init_64::@3]
    // display_frame_init_64::@3
    // scroll(0)
    // [632] call scroll
    jsr scroll
    // [633] phi from display_frame_init_64::@3 to display_frame_init_64::@4 [phi:display_frame_init_64::@3->display_frame_init_64::@4]
    // display_frame_init_64::@4
    // clrscr()
    // [634] call clrscr
    jsr clrscr
    // display_frame_init_64::vera_display_set_hstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [635] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTART = start
    // [636] *VERA_DC_HSTART = display_frame_init_64::vera_display_set_hstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstart1_start
    sta VERA_DC_HSTART
    // display_frame_init_64::vera_display_set_hstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [637] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTOP = stop
    // [638] *VERA_DC_HSTOP = display_frame_init_64::vera_display_set_hstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstop1_stop
    sta VERA_DC_HSTOP
    // display_frame_init_64::vera_display_set_vstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [639] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTART = start
    // [640] *VERA_DC_VSTART = display_frame_init_64::vera_display_set_vstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstart1_start
    sta VERA_DC_VSTART
    // display_frame_init_64::vera_display_set_vstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [641] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTOP = stop
    // [642] *VERA_DC_VSTOP = display_frame_init_64::vera_display_set_vstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstop1_stop
    sta VERA_DC_VSTOP
    // display_frame_init_64::@1
    // cx16_k_screen_set_charset(3, (char *)0)
    // [643] display_frame_init_64::cx16_k_screen_set_charset1_charset = 3 -- vbum1=vbuc1 
    lda #3
    sta cx16_k_screen_set_charset1_charset
    // [644] display_frame_init_64::cx16_k_screen_set_charset1_offset = (char *) 0 -- pbum1=pbuc1 
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
    // [646] return 
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
    // [648] call textcolor
    // [588] phi from display_frame_draw to textcolor [phi:display_frame_draw->textcolor]
    // [588] phi textcolor::color#18 = LIGHT_BLUE [phi:display_frame_draw->textcolor#0] -- vbum1=vbuc1 
    lda #LIGHT_BLUE
    sta textcolor.color
    jsr textcolor
    // [649] phi from display_frame_draw to display_frame_draw::@1 [phi:display_frame_draw->display_frame_draw::@1]
    // display_frame_draw::@1
    // bgcolor(BLUE)
    // [650] call bgcolor
    // [593] phi from display_frame_draw::@1 to bgcolor [phi:display_frame_draw::@1->bgcolor]
    // [593] phi bgcolor::color#14 = BLUE [phi:display_frame_draw::@1->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [651] phi from display_frame_draw::@1 to display_frame_draw::@2 [phi:display_frame_draw::@1->display_frame_draw::@2]
    // display_frame_draw::@2
    // clrscr()
    // [652] call clrscr
    jsr clrscr
    // [653] phi from display_frame_draw::@2 to display_frame_draw::@3 [phi:display_frame_draw::@2->display_frame_draw::@3]
    // display_frame_draw::@3
    // display_frame(0, 0, 67, 14)
    // [654] call display_frame
    // [1687] phi from display_frame_draw::@3 to display_frame [phi:display_frame_draw::@3->display_frame]
    // [1687] phi display_frame::y#0 = 0 [phi:display_frame_draw::@3->display_frame#0] -- vbum1=vbuc1 
    lda #0
    sta display_frame.y
    // [1687] phi display_frame::y1#16 = $e [phi:display_frame_draw::@3->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1687] phi display_frame::x#0 = 0 [phi:display_frame_draw::@3->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1687] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@3->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [655] phi from display_frame_draw::@3 to display_frame_draw::@4 [phi:display_frame_draw::@3->display_frame_draw::@4]
    // display_frame_draw::@4
    // display_frame(0, 0, 67, 2)
    // [656] call display_frame
    // [1687] phi from display_frame_draw::@4 to display_frame [phi:display_frame_draw::@4->display_frame]
    // [1687] phi display_frame::y#0 = 0 [phi:display_frame_draw::@4->display_frame#0] -- vbum1=vbuc1 
    lda #0
    sta display_frame.y
    // [1687] phi display_frame::y1#16 = 2 [phi:display_frame_draw::@4->display_frame#1] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y1
    // [1687] phi display_frame::x#0 = 0 [phi:display_frame_draw::@4->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1687] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@4->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [657] phi from display_frame_draw::@4 to display_frame_draw::@5 [phi:display_frame_draw::@4->display_frame_draw::@5]
    // display_frame_draw::@5
    // display_frame(0, 2, 67, 14)
    // [658] call display_frame
    // [1687] phi from display_frame_draw::@5 to display_frame [phi:display_frame_draw::@5->display_frame]
    // [1687] phi display_frame::y#0 = 2 [phi:display_frame_draw::@5->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1687] phi display_frame::y1#16 = $e [phi:display_frame_draw::@5->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1687] phi display_frame::x#0 = 0 [phi:display_frame_draw::@5->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1687] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@5->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [659] phi from display_frame_draw::@5 to display_frame_draw::@6 [phi:display_frame_draw::@5->display_frame_draw::@6]
    // display_frame_draw::@6
    // display_frame(0, 2, 8, 14)
    // [660] call display_frame
  // Chipset areas
    // [1687] phi from display_frame_draw::@6 to display_frame [phi:display_frame_draw::@6->display_frame]
    // [1687] phi display_frame::y#0 = 2 [phi:display_frame_draw::@6->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1687] phi display_frame::y1#16 = $e [phi:display_frame_draw::@6->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1687] phi display_frame::x#0 = 0 [phi:display_frame_draw::@6->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1687] phi display_frame::x1#16 = 8 [phi:display_frame_draw::@6->display_frame#3] -- vbum1=vbuc1 
    lda #8
    sta display_frame.x1
    jsr display_frame
    // [661] phi from display_frame_draw::@6 to display_frame_draw::@7 [phi:display_frame_draw::@6->display_frame_draw::@7]
    // display_frame_draw::@7
    // display_frame(8, 2, 19, 14)
    // [662] call display_frame
    // [1687] phi from display_frame_draw::@7 to display_frame [phi:display_frame_draw::@7->display_frame]
    // [1687] phi display_frame::y#0 = 2 [phi:display_frame_draw::@7->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1687] phi display_frame::y1#16 = $e [phi:display_frame_draw::@7->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1687] phi display_frame::x#0 = 8 [phi:display_frame_draw::@7->display_frame#2] -- vbum1=vbuc1 
    lda #8
    sta display_frame.x
    // [1687] phi display_frame::x1#16 = $13 [phi:display_frame_draw::@7->display_frame#3] -- vbum1=vbuc1 
    lda #$13
    sta display_frame.x1
    jsr display_frame
    // [663] phi from display_frame_draw::@7 to display_frame_draw::@8 [phi:display_frame_draw::@7->display_frame_draw::@8]
    // display_frame_draw::@8
    // display_frame(19, 2, 25, 14)
    // [664] call display_frame
    // [1687] phi from display_frame_draw::@8 to display_frame [phi:display_frame_draw::@8->display_frame]
    // [1687] phi display_frame::y#0 = 2 [phi:display_frame_draw::@8->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1687] phi display_frame::y1#16 = $e [phi:display_frame_draw::@8->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1687] phi display_frame::x#0 = $13 [phi:display_frame_draw::@8->display_frame#2] -- vbum1=vbuc1 
    lda #$13
    sta display_frame.x
    // [1687] phi display_frame::x1#16 = $19 [phi:display_frame_draw::@8->display_frame#3] -- vbum1=vbuc1 
    lda #$19
    sta display_frame.x1
    jsr display_frame
    // [665] phi from display_frame_draw::@8 to display_frame_draw::@9 [phi:display_frame_draw::@8->display_frame_draw::@9]
    // display_frame_draw::@9
    // display_frame(25, 2, 31, 14)
    // [666] call display_frame
    // [1687] phi from display_frame_draw::@9 to display_frame [phi:display_frame_draw::@9->display_frame]
    // [1687] phi display_frame::y#0 = 2 [phi:display_frame_draw::@9->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1687] phi display_frame::y1#16 = $e [phi:display_frame_draw::@9->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1687] phi display_frame::x#0 = $19 [phi:display_frame_draw::@9->display_frame#2] -- vbum1=vbuc1 
    lda #$19
    sta display_frame.x
    // [1687] phi display_frame::x1#16 = $1f [phi:display_frame_draw::@9->display_frame#3] -- vbum1=vbuc1 
    lda #$1f
    sta display_frame.x1
    jsr display_frame
    // [667] phi from display_frame_draw::@9 to display_frame_draw::@10 [phi:display_frame_draw::@9->display_frame_draw::@10]
    // display_frame_draw::@10
    // display_frame(31, 2, 37, 14)
    // [668] call display_frame
    // [1687] phi from display_frame_draw::@10 to display_frame [phi:display_frame_draw::@10->display_frame]
    // [1687] phi display_frame::y#0 = 2 [phi:display_frame_draw::@10->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1687] phi display_frame::y1#16 = $e [phi:display_frame_draw::@10->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1687] phi display_frame::x#0 = $1f [phi:display_frame_draw::@10->display_frame#2] -- vbum1=vbuc1 
    lda #$1f
    sta display_frame.x
    // [1687] phi display_frame::x1#16 = $25 [phi:display_frame_draw::@10->display_frame#3] -- vbum1=vbuc1 
    lda #$25
    sta display_frame.x1
    jsr display_frame
    // [669] phi from display_frame_draw::@10 to display_frame_draw::@11 [phi:display_frame_draw::@10->display_frame_draw::@11]
    // display_frame_draw::@11
    // display_frame(37, 2, 43, 14)
    // [670] call display_frame
    // [1687] phi from display_frame_draw::@11 to display_frame [phi:display_frame_draw::@11->display_frame]
    // [1687] phi display_frame::y#0 = 2 [phi:display_frame_draw::@11->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1687] phi display_frame::y1#16 = $e [phi:display_frame_draw::@11->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1687] phi display_frame::x#0 = $25 [phi:display_frame_draw::@11->display_frame#2] -- vbum1=vbuc1 
    lda #$25
    sta display_frame.x
    // [1687] phi display_frame::x1#16 = $2b [phi:display_frame_draw::@11->display_frame#3] -- vbum1=vbuc1 
    lda #$2b
    sta display_frame.x1
    jsr display_frame
    // [671] phi from display_frame_draw::@11 to display_frame_draw::@12 [phi:display_frame_draw::@11->display_frame_draw::@12]
    // display_frame_draw::@12
    // display_frame(43, 2, 49, 14)
    // [672] call display_frame
    // [1687] phi from display_frame_draw::@12 to display_frame [phi:display_frame_draw::@12->display_frame]
    // [1687] phi display_frame::y#0 = 2 [phi:display_frame_draw::@12->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1687] phi display_frame::y1#16 = $e [phi:display_frame_draw::@12->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1687] phi display_frame::x#0 = $2b [phi:display_frame_draw::@12->display_frame#2] -- vbum1=vbuc1 
    lda #$2b
    sta display_frame.x
    // [1687] phi display_frame::x1#16 = $31 [phi:display_frame_draw::@12->display_frame#3] -- vbum1=vbuc1 
    lda #$31
    sta display_frame.x1
    jsr display_frame
    // [673] phi from display_frame_draw::@12 to display_frame_draw::@13 [phi:display_frame_draw::@12->display_frame_draw::@13]
    // display_frame_draw::@13
    // display_frame(49, 2, 55, 14)
    // [674] call display_frame
    // [1687] phi from display_frame_draw::@13 to display_frame [phi:display_frame_draw::@13->display_frame]
    // [1687] phi display_frame::y#0 = 2 [phi:display_frame_draw::@13->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1687] phi display_frame::y1#16 = $e [phi:display_frame_draw::@13->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1687] phi display_frame::x#0 = $31 [phi:display_frame_draw::@13->display_frame#2] -- vbum1=vbuc1 
    lda #$31
    sta display_frame.x
    // [1687] phi display_frame::x1#16 = $37 [phi:display_frame_draw::@13->display_frame#3] -- vbum1=vbuc1 
    lda #$37
    sta display_frame.x1
    jsr display_frame
    // [675] phi from display_frame_draw::@13 to display_frame_draw::@14 [phi:display_frame_draw::@13->display_frame_draw::@14]
    // display_frame_draw::@14
    // display_frame(55, 2, 61, 14)
    // [676] call display_frame
    // [1687] phi from display_frame_draw::@14 to display_frame [phi:display_frame_draw::@14->display_frame]
    // [1687] phi display_frame::y#0 = 2 [phi:display_frame_draw::@14->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1687] phi display_frame::y1#16 = $e [phi:display_frame_draw::@14->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1687] phi display_frame::x#0 = $37 [phi:display_frame_draw::@14->display_frame#2] -- vbum1=vbuc1 
    lda #$37
    sta display_frame.x
    // [1687] phi display_frame::x1#16 = $3d [phi:display_frame_draw::@14->display_frame#3] -- vbum1=vbuc1 
    lda #$3d
    sta display_frame.x1
    jsr display_frame
    // [677] phi from display_frame_draw::@14 to display_frame_draw::@15 [phi:display_frame_draw::@14->display_frame_draw::@15]
    // display_frame_draw::@15
    // display_frame(61, 2, 67, 14)
    // [678] call display_frame
    // [1687] phi from display_frame_draw::@15 to display_frame [phi:display_frame_draw::@15->display_frame]
    // [1687] phi display_frame::y#0 = 2 [phi:display_frame_draw::@15->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1687] phi display_frame::y1#16 = $e [phi:display_frame_draw::@15->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1687] phi display_frame::x#0 = $3d [phi:display_frame_draw::@15->display_frame#2] -- vbum1=vbuc1 
    lda #$3d
    sta display_frame.x
    // [1687] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@15->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [679] phi from display_frame_draw::@15 to display_frame_draw::@16 [phi:display_frame_draw::@15->display_frame_draw::@16]
    // display_frame_draw::@16
    // display_frame(0, 14, 67, PROGRESS_Y-5)
    // [680] call display_frame
  // Progress area
    // [1687] phi from display_frame_draw::@16 to display_frame [phi:display_frame_draw::@16->display_frame]
    // [1687] phi display_frame::y#0 = $e [phi:display_frame_draw::@16->display_frame#0] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y
    // [1687] phi display_frame::y1#16 = PROGRESS_Y-5 [phi:display_frame_draw::@16->display_frame#1] -- vbum1=vbuc1 
    lda #PROGRESS_Y-5
    sta display_frame.y1
    // [1687] phi display_frame::x#0 = 0 [phi:display_frame_draw::@16->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1687] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@16->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [681] phi from display_frame_draw::@16 to display_frame_draw::@17 [phi:display_frame_draw::@16->display_frame_draw::@17]
    // display_frame_draw::@17
    // display_frame(0, PROGRESS_Y-5, 67, PROGRESS_Y-2)
    // [682] call display_frame
    // [1687] phi from display_frame_draw::@17 to display_frame [phi:display_frame_draw::@17->display_frame]
    // [1687] phi display_frame::y#0 = PROGRESS_Y-5 [phi:display_frame_draw::@17->display_frame#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-5
    sta display_frame.y
    // [1687] phi display_frame::y1#16 = PROGRESS_Y-2 [phi:display_frame_draw::@17->display_frame#1] -- vbum1=vbuc1 
    lda #PROGRESS_Y-2
    sta display_frame.y1
    // [1687] phi display_frame::x#0 = 0 [phi:display_frame_draw::@17->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1687] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@17->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [683] phi from display_frame_draw::@17 to display_frame_draw::@18 [phi:display_frame_draw::@17->display_frame_draw::@18]
    // display_frame_draw::@18
    // display_frame(0, PROGRESS_Y-2, 67, 49)
    // [684] call display_frame
    // [1687] phi from display_frame_draw::@18 to display_frame [phi:display_frame_draw::@18->display_frame]
    // [1687] phi display_frame::y#0 = PROGRESS_Y-2 [phi:display_frame_draw::@18->display_frame#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-2
    sta display_frame.y
    // [1687] phi display_frame::y1#16 = $31 [phi:display_frame_draw::@18->display_frame#1] -- vbum1=vbuc1 
    lda #$31
    sta display_frame.y1
    // [1687] phi display_frame::x#0 = 0 [phi:display_frame_draw::@18->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1687] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@18->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [685] phi from display_frame_draw::@18 to display_frame_draw::@19 [phi:display_frame_draw::@18->display_frame_draw::@19]
    // display_frame_draw::@19
    // textcolor(WHITE)
    // [686] call textcolor
    // [588] phi from display_frame_draw::@19 to textcolor [phi:display_frame_draw::@19->textcolor]
    // [588] phi textcolor::color#18 = WHITE [phi:display_frame_draw::@19->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // display_frame_draw::@return
    // }
    // [687] return 
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
    // [689] call gotoxy
    // [606] phi from display_frame_title to gotoxy [phi:display_frame_title->gotoxy]
    // [606] phi gotoxy::y#30 = 1 [phi:display_frame_title->gotoxy#0] -- vbum1=vbuc1 
    lda #1
    sta gotoxy.y
    // [606] phi gotoxy::x#30 = 2 [phi:display_frame_title->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // [690] phi from display_frame_title to display_frame_title::@1 [phi:display_frame_title->display_frame_title::@1]
    // display_frame_title::@1
    // printf("%-65s", title_text)
    // [691] call printf_string
    // [882] phi from display_frame_title::@1 to printf_string [phi:display_frame_title::@1->printf_string]
    // [882] phi printf_string::putc#19 = &cputc [phi:display_frame_title::@1->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [882] phi printf_string::str#19 = main::title_text [phi:display_frame_title::@1->printf_string#1] -- pbuz1=pbuc1 
    lda #<main.title_text
    sta.z printf_string.str
    lda #>main.title_text
    sta.z printf_string.str+1
    // [882] phi printf_string::format_justify_left#19 = 1 [phi:display_frame_title::@1->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [882] phi printf_string::format_min_length#19 = $41 [phi:display_frame_title::@1->printf_string#3] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_frame_title::@return
    // }
    // [692] return 
    rts
}
  // cputsxy
// Move cursor and output a NUL-terminated string
// Same as "gotoxy (x, y); puts (s);"
// void cputsxy(__mem() char x, __mem() char y, __zp($48) const char *s)
cputsxy: {
    .label s = $48
    // gotoxy(x, y)
    // [694] gotoxy::x#1 = cputsxy::x#4 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [695] gotoxy::y#1 = cputsxy::y#4 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [696] call gotoxy
    // [606] phi from cputsxy to gotoxy [phi:cputsxy->gotoxy]
    // [606] phi gotoxy::y#30 = gotoxy::y#1 [phi:cputsxy->gotoxy#0] -- register_copy 
    // [606] phi gotoxy::x#30 = gotoxy::x#1 [phi:cputsxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputsxy::@1
    // cputs(s)
    // [697] cputs::s#1 = cputsxy::s#4 -- pbuz1=pbuz2 
    lda.z s
    sta.z cputs.s
    lda.z s+1
    sta.z cputs.s+1
    // [698] call cputs
    // [1821] phi from cputsxy::@1 to cputs [phi:cputsxy::@1->cputs]
    jsr cputs
    // cputsxy::@return
    // }
    // [699] return 
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
// void display_action_progress(__zp($52) char *info_text)
display_action_progress: {
    .label x = $cd
    .label info_text = $52
    // unsigned char x = wherex()
    // [701] call wherex
    jsr wherex
    // [702] wherex::return#2 = wherex::return#0
    // display_action_progress::@1
    // [703] display_action_progress::x#0 = wherex::return#2 -- vbuz1=vbum2 
    lda wherex.return
    sta.z x
    // unsigned char y = wherey()
    // [704] call wherey
    jsr wherey
    // [705] wherey::return#2 = wherey::return#0
    // display_action_progress::@2
    // [706] display_action_progress::y#0 = wherey::return#2 -- vbum1=vbum2 
    lda wherey.return
    sta y
    // gotoxy(2, PROGRESS_Y-4)
    // [707] call gotoxy
    // [606] phi from display_action_progress::@2 to gotoxy [phi:display_action_progress::@2->gotoxy]
    // [606] phi gotoxy::y#30 = PROGRESS_Y-4 [phi:display_action_progress::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-4
    sta gotoxy.y
    // [606] phi gotoxy::x#30 = 2 [phi:display_action_progress::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // display_action_progress::@3
    // printf("%-65s", info_text)
    // [708] printf_string::str#1 = display_action_progress::info_text#14
    // [709] call printf_string
    // [882] phi from display_action_progress::@3 to printf_string [phi:display_action_progress::@3->printf_string]
    // [882] phi printf_string::putc#19 = &cputc [phi:display_action_progress::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [882] phi printf_string::str#19 = printf_string::str#1 [phi:display_action_progress::@3->printf_string#1] -- register_copy 
    // [882] phi printf_string::format_justify_left#19 = 1 [phi:display_action_progress::@3->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [882] phi printf_string::format_min_length#19 = $41 [phi:display_action_progress::@3->printf_string#3] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_action_progress::@4
    // gotoxy(x, y)
    // [710] gotoxy::x#10 = display_action_progress::x#0 -- vbum1=vbuz2 
    lda.z x
    sta gotoxy.x
    // [711] gotoxy::y#10 = display_action_progress::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [712] call gotoxy
    // [606] phi from display_action_progress::@4 to gotoxy [phi:display_action_progress::@4->gotoxy]
    // [606] phi gotoxy::y#30 = gotoxy::y#10 [phi:display_action_progress::@4->gotoxy#0] -- register_copy 
    // [606] phi gotoxy::x#30 = gotoxy::x#10 [phi:display_action_progress::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_action_progress::@return
    // }
    // [713] return 
    rts
  .segment Data
    .label y = util_wait_key.bram
}
.segment Code
  // display_progress_clear
/**
 * @brief Clean the progress area for the flashing.
 */
display_progress_clear: {
    .const h = PROGRESS_Y+PROGRESS_H
    .label x = $7d
    .label i = $7c
    .label y = $d0
    // textcolor(WHITE)
    // [715] call textcolor
    // [588] phi from display_progress_clear to textcolor [phi:display_progress_clear->textcolor]
    // [588] phi textcolor::color#18 = WHITE [phi:display_progress_clear->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [716] phi from display_progress_clear to display_progress_clear::@5 [phi:display_progress_clear->display_progress_clear::@5]
    // display_progress_clear::@5
    // bgcolor(BLUE)
    // [717] call bgcolor
    // [593] phi from display_progress_clear::@5 to bgcolor [phi:display_progress_clear::@5->bgcolor]
    // [593] phi bgcolor::color#14 = BLUE [phi:display_progress_clear::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [718] phi from display_progress_clear::@5 to display_progress_clear::@1 [phi:display_progress_clear::@5->display_progress_clear::@1]
    // [718] phi display_progress_clear::y#2 = PROGRESS_Y [phi:display_progress_clear::@5->display_progress_clear::@1#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // display_progress_clear::@1
  __b1:
    // while (y < h)
    // [719] if(display_progress_clear::y#2<display_progress_clear::h) goto display_progress_clear::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y
    cmp #h
    bcc __b4
    // display_progress_clear::@return
    // }
    // [720] return 
    rts
    // [721] phi from display_progress_clear::@1 to display_progress_clear::@2 [phi:display_progress_clear::@1->display_progress_clear::@2]
  __b4:
    // [721] phi display_progress_clear::x#2 = PROGRESS_X [phi:display_progress_clear::@1->display_progress_clear::@2#0] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z x
    // [721] phi display_progress_clear::i#2 = 0 [phi:display_progress_clear::@1->display_progress_clear::@2#1] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // display_progress_clear::@2
  __b2:
    // for(unsigned char i = 0; i < w; i++)
    // [722] if(display_progress_clear::i#2<PROGRESS_W) goto display_progress_clear::@3 -- vbuz1_lt_vbuc1_then_la1 
    lda.z i
    cmp #PROGRESS_W
    bcc __b3
    // display_progress_clear::@4
    // y++;
    // [723] display_progress_clear::y#1 = ++ display_progress_clear::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [718] phi from display_progress_clear::@4 to display_progress_clear::@1 [phi:display_progress_clear::@4->display_progress_clear::@1]
    // [718] phi display_progress_clear::y#2 = display_progress_clear::y#1 [phi:display_progress_clear::@4->display_progress_clear::@1#0] -- register_copy 
    jmp __b1
    // display_progress_clear::@3
  __b3:
    // cputcxy(x, y, ' ')
    // [724] cputcxy::x#12 = display_progress_clear::x#2 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [725] cputcxy::y#12 = display_progress_clear::y#2 -- vbum1=vbuz2 
    lda.z y
    sta cputcxy.y
    // [726] call cputcxy
    // [1834] phi from display_progress_clear::@3 to cputcxy [phi:display_progress_clear::@3->cputcxy]
    // [1834] phi cputcxy::c#15 = ' ' [phi:display_progress_clear::@3->cputcxy#0] -- vbum1=vbuc1 
    lda #' '
    sta cputcxy.c
    // [1834] phi cputcxy::y#15 = cputcxy::y#12 [phi:display_progress_clear::@3->cputcxy#1] -- register_copy 
    // [1834] phi cputcxy::x#15 = cputcxy::x#12 [phi:display_progress_clear::@3->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_progress_clear::@6
    // x++;
    // [727] display_progress_clear::x#1 = ++ display_progress_clear::x#2 -- vbuz1=_inc_vbuz1 
    inc.z x
    // for(unsigned char i = 0; i < w; i++)
    // [728] display_progress_clear::i#1 = ++ display_progress_clear::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [721] phi from display_progress_clear::@6 to display_progress_clear::@2 [phi:display_progress_clear::@6->display_progress_clear::@2]
    // [721] phi display_progress_clear::x#2 = display_progress_clear::x#1 [phi:display_progress_clear::@6->display_progress_clear::@2#0] -- register_copy 
    // [721] phi display_progress_clear::i#2 = display_progress_clear::i#1 [phi:display_progress_clear::@6->display_progress_clear::@2#1] -- register_copy 
    jmp __b2
}
  // display_chip_smc
display_chip_smc: {
    // display_smc_led(GREY)
    // [730] call display_smc_led
    // [1842] phi from display_chip_smc to display_smc_led [phi:display_chip_smc->display_smc_led]
    // [1842] phi display_smc_led::c#2 = GREY [phi:display_chip_smc->display_smc_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z display_smc_led.c
    jsr display_smc_led
    // [731] phi from display_chip_smc to display_chip_smc::@1 [phi:display_chip_smc->display_chip_smc::@1]
    // display_chip_smc::@1
    // display_print_chip(CHIP_SMC_X, CHIP_SMC_Y+2, CHIP_SMC_W, "SMC     ")
    // [732] call display_print_chip
    // [1848] phi from display_chip_smc::@1 to display_print_chip [phi:display_chip_smc::@1->display_print_chip]
    // [1848] phi display_print_chip::text#11 = display_chip_smc::text [phi:display_chip_smc::@1->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_print_chip.text_2
    lda #>text
    sta.z display_print_chip.text_2+1
    // [1848] phi display_print_chip::w#10 = 5 [phi:display_chip_smc::@1->display_print_chip#1] -- vbum1=vbuc1 
    lda #5
    sta display_print_chip.w
    // [1848] phi display_print_chip::x#10 = 1 [phi:display_chip_smc::@1->display_print_chip#2] -- vbum1=vbuc1 
    lda #1
    sta display_print_chip.x
    jsr display_print_chip
    // display_chip_smc::@return
    // }
    // [733] return 
    rts
  .segment Data
    text: .text "SMC     "
    .byte 0
}
.segment Code
  // display_chip_vera
display_chip_vera: {
    // display_vera_led(GREY)
    // [735] call display_vera_led
    // [1892] phi from display_chip_vera to display_vera_led [phi:display_chip_vera->display_vera_led]
    // [1892] phi display_vera_led::c#2 = GREY [phi:display_chip_vera->display_vera_led#0] -- vbum1=vbuc1 
    lda #GREY
    sta display_vera_led.c
    jsr display_vera_led
    // [736] phi from display_chip_vera to display_chip_vera::@1 [phi:display_chip_vera->display_chip_vera::@1]
    // display_chip_vera::@1
    // display_print_chip(CHIP_VERA_X, CHIP_VERA_Y+2, CHIP_VERA_W, "VERA     ")
    // [737] call display_print_chip
    // [1848] phi from display_chip_vera::@1 to display_print_chip [phi:display_chip_vera::@1->display_print_chip]
    // [1848] phi display_print_chip::text#11 = display_chip_vera::text [phi:display_chip_vera::@1->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_print_chip.text_2
    lda #>text
    sta.z display_print_chip.text_2+1
    // [1848] phi display_print_chip::w#10 = 8 [phi:display_chip_vera::@1->display_print_chip#1] -- vbum1=vbuc1 
    lda #8
    sta display_print_chip.w
    // [1848] phi display_print_chip::x#10 = 9 [phi:display_chip_vera::@1->display_print_chip#2] -- vbum1=vbuc1 
    lda #9
    sta display_print_chip.x
    jsr display_print_chip
    // display_chip_vera::@return
    // }
    // [738] return 
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
    .label display_chip_rom__4 = $43
    .label r = $6d
    // [740] phi from display_chip_rom to display_chip_rom::@1 [phi:display_chip_rom->display_chip_rom::@1]
    // [740] phi display_chip_rom::r#2 = 0 [phi:display_chip_rom->display_chip_rom::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z r
    // display_chip_rom::@1
  __b1:
    // for (unsigned char r = 0; r < 8; r++)
    // [741] if(display_chip_rom::r#2<8) goto display_chip_rom::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z r
    cmp #8
    bcc __b2
    // display_chip_rom::@return
    // }
    // [742] return 
    rts
    // [743] phi from display_chip_rom::@1 to display_chip_rom::@2 [phi:display_chip_rom::@1->display_chip_rom::@2]
    // display_chip_rom::@2
  __b2:
    // strcpy(rom, "ROM  ")
    // [744] call strcpy
    // [1898] phi from display_chip_rom::@2 to strcpy [phi:display_chip_rom::@2->strcpy]
    jsr strcpy
    // display_chip_rom::@5
    // strcat(rom, rom_size_strings[r])
    // [745] display_chip_rom::$11 = display_chip_rom::r#2 << 1 -- vbum1=vbuz2_rol_1 
    lda.z r
    asl
    sta display_chip_rom__11
    // [746] strcat::source#0 = rom_size_strings[display_chip_rom::$11] -- pbuz1=qbuc1_derefidx_vbum2 
    tay
    lda rom_size_strings,y
    sta.z strcat.source
    lda rom_size_strings+1,y
    sta.z strcat.source+1
    // [747] call strcat
    // [1906] phi from display_chip_rom::@5 to strcat [phi:display_chip_rom::@5->strcat]
    jsr strcat
    // display_chip_rom::@6
    // if(r)
    // [748] if(0==display_chip_rom::r#2) goto display_chip_rom::@3 -- 0_eq_vbuz1_then_la1 
    lda.z r
    beq __b3
    // display_chip_rom::@4
    // r+'0'
    // [749] display_chip_rom::$4 = display_chip_rom::r#2 + '0' -- vbuz1=vbuz2_plus_vbuc1 
    lda #'0'
    clc
    adc.z r
    sta.z display_chip_rom__4
    // *(rom+3) = r+'0'
    // [750] *(display_chip_rom::rom+3) = display_chip_rom::$4 -- _deref_pbuc1=vbuz1 
    sta rom+3
    // display_chip_rom::@3
  __b3:
    // display_rom_led(r, GREY)
    // [751] display_rom_led::chip#0 = display_chip_rom::r#2 -- vbuz1=vbuz2 
    lda.z r
    sta.z display_rom_led.chip
    // [752] call display_rom_led
    // [1918] phi from display_chip_rom::@3 to display_rom_led [phi:display_chip_rom::@3->display_rom_led]
    // [1918] phi display_rom_led::c#2 = GREY [phi:display_chip_rom::@3->display_rom_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z display_rom_led.c
    // [1918] phi display_rom_led::chip#2 = display_rom_led::chip#0 [phi:display_chip_rom::@3->display_rom_led#1] -- register_copy 
    jsr display_rom_led
    // display_chip_rom::@7
    // r*6
    // [753] display_chip_rom::$12 = display_chip_rom::$11 + display_chip_rom::r#2 -- vbum1=vbum1_plus_vbuz2 
    lda display_chip_rom__12
    clc
    adc.z r
    sta display_chip_rom__12
    // [754] display_chip_rom::$6 = display_chip_rom::$12 << 1 -- vbum1=vbum2_rol_1 
    asl
    sta display_chip_rom__6
    // display_print_chip(CHIP_ROM_X+r*6, CHIP_ROM_Y+2, CHIP_ROM_W, rom)
    // [755] display_print_chip::x#2 = $14 + display_chip_rom::$6 -- vbum1=vbuc1_plus_vbum1 
    lda #$14
    clc
    adc display_print_chip.x
    sta display_print_chip.x
    // [756] call display_print_chip
    // [1848] phi from display_chip_rom::@7 to display_print_chip [phi:display_chip_rom::@7->display_print_chip]
    // [1848] phi display_print_chip::text#11 = display_chip_rom::rom [phi:display_chip_rom::@7->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z display_print_chip.text_2
    lda #>rom
    sta.z display_print_chip.text_2+1
    // [1848] phi display_print_chip::w#10 = 3 [phi:display_chip_rom::@7->display_print_chip#1] -- vbum1=vbuc1 
    lda #3
    sta display_print_chip.w
    // [1848] phi display_print_chip::x#10 = display_print_chip::x#2 [phi:display_chip_rom::@7->display_print_chip#2] -- register_copy 
    jsr display_print_chip
    // display_chip_rom::@8
    // for (unsigned char r = 0; r < 8; r++)
    // [757] display_chip_rom::r#1 = ++ display_chip_rom::r#2 -- vbuz1=_inc_vbuz1 
    inc.z r
    // [740] phi from display_chip_rom::@8 to display_chip_rom::@1 [phi:display_chip_rom::@8->display_chip_rom::@1]
    // [740] phi display_chip_rom::r#2 = display_chip_rom::r#1 [phi:display_chip_rom::@8->display_chip_rom::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    rom: .fill $10, 0
    source: .text "ROM  "
    .byte 0
    .label display_chip_rom__6 = util_wait_key.return
    .label display_chip_rom__11 = smc_flash.smc_bootloader_start
    .label display_chip_rom__12 = smc_flash.smc_bootloader_start
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
// void display_info_smc(__zp($4e) char info_status, __zp($54) char *info_text)
display_info_smc: {
    .label display_info_smc__8 = $4e
    .label info_status = $4e
    .label info_text = $54
    // unsigned char x = wherex()
    // [759] call wherex
    jsr wherex
    // [760] wherex::return#10 = wherex::return#0
    // display_info_smc::@3
    // [761] display_info_smc::x#0 = wherex::return#10 -- vbum1=vbum2 
    lda wherex.return
    sta x
    // unsigned char y = wherey()
    // [762] call wherey
    jsr wherey
    // [763] wherey::return#10 = wherey::return#0
    // display_info_smc::@4
    // [764] display_info_smc::y#0 = wherey::return#10 -- vbum1=vbum2 
    lda wherey.return
    sta y
    // status_smc = info_status
    // [765] status_smc#0 = display_info_smc::info_status#13 -- vbum1=vbuz2 
    lda.z info_status
    sta status_smc
    // display_smc_led(status_color[info_status])
    // [766] display_smc_led::c#1 = status_color[display_info_smc::info_status#13] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z display_smc_led.c
    // [767] call display_smc_led
    // [1842] phi from display_info_smc::@4 to display_smc_led [phi:display_info_smc::@4->display_smc_led]
    // [1842] phi display_smc_led::c#2 = display_smc_led::c#1 [phi:display_info_smc::@4->display_smc_led#0] -- register_copy 
    jsr display_smc_led
    // [768] phi from display_info_smc::@4 to display_info_smc::@5 [phi:display_info_smc::@4->display_info_smc::@5]
    // display_info_smc::@5
    // gotoxy(INFO_X, INFO_Y)
    // [769] call gotoxy
    // [606] phi from display_info_smc::@5 to gotoxy [phi:display_info_smc::@5->gotoxy]
    // [606] phi gotoxy::y#30 = $11 [phi:display_info_smc::@5->gotoxy#0] -- vbum1=vbuc1 
    lda #$11
    sta gotoxy.y
    // [606] phi gotoxy::x#30 = 4 [phi:display_info_smc::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.x
    jsr gotoxy
    // [770] phi from display_info_smc::@5 to display_info_smc::@6 [phi:display_info_smc::@5->display_info_smc::@6]
    // display_info_smc::@6
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [771] call printf_str
    // [873] phi from display_info_smc::@6 to printf_str [phi:display_info_smc::@6->printf_str]
    // [873] phi printf_str::putc#73 = &cputc [phi:display_info_smc::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = display_info_smc::s [phi:display_info_smc::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@7
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [772] display_info_smc::$8 = display_info_smc::info_status#13 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_info_smc__8
    // [773] printf_string::str#3 = status_text[display_info_smc::$8] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z display_info_smc__8
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [774] call printf_string
    // [882] phi from display_info_smc::@7 to printf_string [phi:display_info_smc::@7->printf_string]
    // [882] phi printf_string::putc#19 = &cputc [phi:display_info_smc::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [882] phi printf_string::str#19 = printf_string::str#3 [phi:display_info_smc::@7->printf_string#1] -- register_copy 
    // [882] phi printf_string::format_justify_left#19 = 1 [phi:display_info_smc::@7->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [882] phi printf_string::format_min_length#19 = 9 [phi:display_info_smc::@7->printf_string#3] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [775] phi from display_info_smc::@7 to display_info_smc::@8 [phi:display_info_smc::@7->display_info_smc::@8]
    // display_info_smc::@8
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [776] call printf_str
    // [873] phi from display_info_smc::@8 to printf_str [phi:display_info_smc::@8->printf_str]
    // [873] phi printf_str::putc#73 = &cputc [phi:display_info_smc::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = display_info_smc::s1 [phi:display_info_smc::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@9
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [777] printf_uint::uvalue#0 = smc_file_size#12 -- vwum1=vwum2 
    lda smc_file_size_2
    sta printf_uint.uvalue
    lda smc_file_size_2+1
    sta printf_uint.uvalue+1
    // [778] call printf_uint
    // [907] phi from display_info_smc::@9 to printf_uint [phi:display_info_smc::@9->printf_uint]
    // [907] phi printf_uint::format_zero_padding#18 = 1 [phi:display_info_smc::@9->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [907] phi printf_uint::format_min_length#18 = 5 [phi:display_info_smc::@9->printf_uint#1] -- vbum1=vbuc1 
    lda #5
    sta printf_uint.format_min_length
    // [907] phi printf_uint::putc#18 = &cputc [phi:display_info_smc::@9->printf_uint#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uint.putc
    lda #>cputc
    sta.z printf_uint.putc+1
    // [907] phi printf_uint::format_radix#18 = HEXADECIMAL [phi:display_info_smc::@9->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [907] phi printf_uint::uvalue#18 = printf_uint::uvalue#0 [phi:display_info_smc::@9->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [779] phi from display_info_smc::@9 to display_info_smc::@10 [phi:display_info_smc::@9->display_info_smc::@10]
    // display_info_smc::@10
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [780] call printf_str
    // [873] phi from display_info_smc::@10 to printf_str [phi:display_info_smc::@10->printf_str]
    // [873] phi printf_str::putc#73 = &cputc [phi:display_info_smc::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = display_info_smc::s2 [phi:display_info_smc::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@11
    // if(info_text)
    // [781] if((char *)0==display_info_smc::info_text#13) goto display_info_smc::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // display_info_smc::@2
    // printf("%-25s", info_text)
    // [782] printf_string::str#4 = display_info_smc::info_text#13 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [783] call printf_string
    // [882] phi from display_info_smc::@2 to printf_string [phi:display_info_smc::@2->printf_string]
    // [882] phi printf_string::putc#19 = &cputc [phi:display_info_smc::@2->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [882] phi printf_string::str#19 = printf_string::str#4 [phi:display_info_smc::@2->printf_string#1] -- register_copy 
    // [882] phi printf_string::format_justify_left#19 = 1 [phi:display_info_smc::@2->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [882] phi printf_string::format_min_length#19 = $19 [phi:display_info_smc::@2->printf_string#3] -- vbum1=vbuc1 
    lda #$19
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_smc::@1
  __b1:
    // gotoxy(x, y)
    // [784] gotoxy::x#14 = display_info_smc::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [785] gotoxy::y#14 = display_info_smc::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [786] call gotoxy
    // [606] phi from display_info_smc::@1 to gotoxy [phi:display_info_smc::@1->gotoxy]
    // [606] phi gotoxy::y#30 = gotoxy::y#14 [phi:display_info_smc::@1->gotoxy#0] -- register_copy 
    // [606] phi gotoxy::x#30 = gotoxy::x#14 [phi:display_info_smc::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_smc::@return
    // }
    // [787] return 
    rts
  .segment Data
    s: .text "SMC  "
    .byte 0
    s1: .text " ATTiny "
    .byte 0
    s2: .text " / 01E00 "
    .byte 0
    .label x = clrscr.clrscr__0
    .label y = clrscr.clrscr__1
}
.segment Code
  // display_info_vera
/**
 * @brief Display the VERA status at the info frame.
 * 
 * @param info_status The STATUS_ 
 */
// void display_info_vera(__zp($2a) char info_status, __zp($36) char *info_text)
display_info_vera: {
    .label display_info_vera__8 = $2a
    .label y = $50
    .label info_status = $2a
    .label info_text = $36
    // unsigned char x = wherex()
    // [789] call wherex
    jsr wherex
    // [790] wherex::return#11 = wherex::return#0
    // display_info_vera::@3
    // [791] display_info_vera::x#0 = wherex::return#11 -- vbum1=vbum2 
    lda wherex.return
    sta x
    // unsigned char y = wherey()
    // [792] call wherey
    jsr wherey
    // [793] wherey::return#11 = wherey::return#0
    // display_info_vera::@4
    // [794] display_info_vera::y#0 = wherey::return#11 -- vbuz1=vbum2 
    lda wherey.return
    sta.z y
    // status_vera = info_status
    // [795] status_vera#0 = display_info_vera::info_status#3 -- vbum1=vbuz2 
    lda.z info_status
    sta status_vera
    // display_vera_led(status_color[info_status])
    // [796] display_vera_led::c#1 = status_color[display_info_vera::info_status#3] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta display_vera_led.c
    // [797] call display_vera_led
    // [1892] phi from display_info_vera::@4 to display_vera_led [phi:display_info_vera::@4->display_vera_led]
    // [1892] phi display_vera_led::c#2 = display_vera_led::c#1 [phi:display_info_vera::@4->display_vera_led#0] -- register_copy 
    jsr display_vera_led
    // [798] phi from display_info_vera::@4 to display_info_vera::@5 [phi:display_info_vera::@4->display_info_vera::@5]
    // display_info_vera::@5
    // gotoxy(INFO_X, INFO_Y+1)
    // [799] call gotoxy
    // [606] phi from display_info_vera::@5 to gotoxy [phi:display_info_vera::@5->gotoxy]
    // [606] phi gotoxy::y#30 = $11+1 [phi:display_info_vera::@5->gotoxy#0] -- vbum1=vbuc1 
    lda #$11+1
    sta gotoxy.y
    // [606] phi gotoxy::x#30 = 4 [phi:display_info_vera::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.x
    jsr gotoxy
    // [800] phi from display_info_vera::@5 to display_info_vera::@6 [phi:display_info_vera::@5->display_info_vera::@6]
    // display_info_vera::@6
    // printf("VERA %-9s FPGA   1a000 / 1a000 ", status_text[info_status])
    // [801] call printf_str
    // [873] phi from display_info_vera::@6 to printf_str [phi:display_info_vera::@6->printf_str]
    // [873] phi printf_str::putc#73 = &cputc [phi:display_info_vera::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = display_info_vera::s [phi:display_info_vera::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@7
    // printf("VERA %-9s FPGA   1a000 / 1a000 ", status_text[info_status])
    // [802] display_info_vera::$8 = display_info_vera::info_status#3 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_info_vera__8
    // [803] printf_string::str#5 = status_text[display_info_vera::$8] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z display_info_vera__8
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [804] call printf_string
    // [882] phi from display_info_vera::@7 to printf_string [phi:display_info_vera::@7->printf_string]
    // [882] phi printf_string::putc#19 = &cputc [phi:display_info_vera::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [882] phi printf_string::str#19 = printf_string::str#5 [phi:display_info_vera::@7->printf_string#1] -- register_copy 
    // [882] phi printf_string::format_justify_left#19 = 1 [phi:display_info_vera::@7->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [882] phi printf_string::format_min_length#19 = 9 [phi:display_info_vera::@7->printf_string#3] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [805] phi from display_info_vera::@7 to display_info_vera::@8 [phi:display_info_vera::@7->display_info_vera::@8]
    // display_info_vera::@8
    // printf("VERA %-9s FPGA   1a000 / 1a000 ", status_text[info_status])
    // [806] call printf_str
    // [873] phi from display_info_vera::@8 to printf_str [phi:display_info_vera::@8->printf_str]
    // [873] phi printf_str::putc#73 = &cputc [phi:display_info_vera::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = display_info_vera::s1 [phi:display_info_vera::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@9
    // if(info_text)
    // [807] if((char *)0==display_info_vera::info_text#10) goto display_info_vera::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // display_info_vera::@2
    // printf("%-25s", info_text)
    // [808] printf_string::str#6 = display_info_vera::info_text#10 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [809] call printf_string
    // [882] phi from display_info_vera::@2 to printf_string [phi:display_info_vera::@2->printf_string]
    // [882] phi printf_string::putc#19 = &cputc [phi:display_info_vera::@2->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [882] phi printf_string::str#19 = printf_string::str#6 [phi:display_info_vera::@2->printf_string#1] -- register_copy 
    // [882] phi printf_string::format_justify_left#19 = 1 [phi:display_info_vera::@2->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [882] phi printf_string::format_min_length#19 = $19 [phi:display_info_vera::@2->printf_string#3] -- vbum1=vbuc1 
    lda #$19
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_vera::@1
  __b1:
    // gotoxy(x, y)
    // [810] gotoxy::x#16 = display_info_vera::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [811] gotoxy::y#16 = display_info_vera::y#0 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [812] call gotoxy
    // [606] phi from display_info_vera::@1 to gotoxy [phi:display_info_vera::@1->gotoxy]
    // [606] phi gotoxy::y#30 = gotoxy::y#16 [phi:display_info_vera::@1->gotoxy#0] -- register_copy 
    // [606] phi gotoxy::x#30 = gotoxy::x#16 [phi:display_info_vera::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_vera::@return
    // }
    // [813] return 
    rts
  .segment Data
    s: .text "VERA "
    .byte 0
    s1: .text " FPGA   1a000 / 1a000 "
    .byte 0
    .label x = clrscr.clrscr__2
}
.segment Code
  // display_progress_text
/**
 * @brief Print a block of text within the progress frame with a count of lines.
 * 
 * @param text A pointer to an array of strings to be displayed (char**).
 * @param lines The amount of lines to be displayed, starting from the top of the progress frame.
 */
// void display_progress_text(__zp($b5) char **text, __zp($58) char lines)
display_progress_text: {
    .label display_progress_text__3 = $29
    .label l = $4c
    .label lines = $58
    .label text = $b5
    // display_progress_clear()
    // [815] call display_progress_clear
    // [714] phi from display_progress_text to display_progress_clear [phi:display_progress_text->display_progress_clear]
    jsr display_progress_clear
    // [816] phi from display_progress_text to display_progress_text::@1 [phi:display_progress_text->display_progress_text::@1]
    // [816] phi display_progress_text::l#2 = 0 [phi:display_progress_text->display_progress_text::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z l
    // display_progress_text::@1
  __b1:
    // for(unsigned char l=0; l<lines; l++)
    // [817] if(display_progress_text::l#2<display_progress_text::lines#7) goto display_progress_text::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z l
    cmp.z lines
    bcc __b2
    // display_progress_text::@return
    // }
    // [818] return 
    rts
    // display_progress_text::@2
  __b2:
    // display_progress_line(l, text[l])
    // [819] display_progress_text::$3 = display_progress_text::l#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z l
    asl
    sta.z display_progress_text__3
    // [820] display_progress_line::line#0 = display_progress_text::l#2
    // [821] display_progress_line::text#0 = display_progress_text::text#10[display_progress_text::$3] -- pbuz1=qbuz2_derefidx_vbuz3 
    tay
    lda (text),y
    sta.z display_progress_line.text
    iny
    lda (text),y
    sta.z display_progress_line.text+1
    // [822] call display_progress_line
    jsr display_progress_line
    // display_progress_text::@3
    // for(unsigned char l=0; l<lines; l++)
    // [823] display_progress_text::l#1 = ++ display_progress_text::l#2 -- vbuz1=_inc_vbuz1 
    inc.z l
    // [816] phi from display_progress_text::@3 to display_progress_text::@1 [phi:display_progress_text::@3->display_progress_text::@1]
    // [816] phi display_progress_text::l#2 = display_progress_text::l#1 [phi:display_progress_text::@3->display_progress_text::@1#0] -- register_copy 
    jmp __b1
}
  // util_wait_space
util_wait_space: {
    // util_wait_key("Press [SPACE] to continue ...", " ")
    // [825] call util_wait_key
    // [1558] phi from util_wait_space to util_wait_key [phi:util_wait_space->util_wait_key]
    // [1558] phi util_wait_key::filter#12 = s1 [phi:util_wait_space->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<s1
    sta.z util_wait_key.filter
    lda #>s1
    sta.z util_wait_key.filter+1
    // [1558] phi util_wait_key::info_text#2 = util_wait_space::info_text [phi:util_wait_space->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z util_wait_key.info_text
    lda #>info_text
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // util_wait_space::@return
    // }
    // [826] return 
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
    .label smc_bootloader_version = $48
    .label return = $48
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [827] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [828] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [829] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [830] cx16_k_i2c_read_byte::return#10 = cx16_k_i2c_read_byte::return#1
    // smc_detect::@3
    // smc_bootloader_version = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [831] smc_detect::smc_bootloader_version#1 = cx16_k_i2c_read_byte::return#10 -- vwuz1=vwum2 
    lda cx16_k_i2c_read_byte.return
    sta.z smc_bootloader_version
    lda cx16_k_i2c_read_byte.return+1
    sta.z smc_bootloader_version+1
    // BYTE1(smc_bootloader_version)
    // [832] smc_detect::$1 = byte1  smc_detect::smc_bootloader_version#1 -- vbum1=_byte1_vwuz2 
    sta smc_detect__1
    // if(!BYTE1(smc_bootloader_version))
    // [833] if(0==smc_detect::$1) goto smc_detect::@1 -- 0_eq_vbum1_then_la1 
    beq __b1
    // [836] phi from smc_detect::@3 to smc_detect::@2 [phi:smc_detect::@3->smc_detect::@2]
    // [836] phi smc_detect::return#0 = $200 [phi:smc_detect::@3->smc_detect::@2#0] -- vwuz1=vwuc1 
    lda #<$200
    sta.z return
    lda #>$200
    sta.z return+1
    rts
    // smc_detect::@1
  __b1:
    // if(smc_bootloader_version == 0xFF)
    // [834] if(smc_detect::smc_bootloader_version#1!=$ff) goto smc_detect::@4 -- vwuz1_neq_vbuc1_then_la1 
    lda.z smc_bootloader_version+1
    bne __b2
    lda.z smc_bootloader_version
    cmp #$ff
    bne __b2
    // [836] phi from smc_detect::@1 to smc_detect::@2 [phi:smc_detect::@1->smc_detect::@2]
    // [836] phi smc_detect::return#0 = $100 [phi:smc_detect::@1->smc_detect::@2#0] -- vwuz1=vwuc1 
    lda #<$100
    sta.z return
    lda #>$100
    sta.z return+1
    rts
    // [835] phi from smc_detect::@1 to smc_detect::@4 [phi:smc_detect::@1->smc_detect::@4]
    // smc_detect::@4
    // [836] phi from smc_detect::@4 to smc_detect::@2 [phi:smc_detect::@4->smc_detect::@2]
    // [836] phi smc_detect::return#0 = smc_detect::smc_bootloader_version#1 [phi:smc_detect::@4->smc_detect::@2#0] -- register_copy 
    // smc_detect::@2
  __b2:
    // smc_detect::@return
    // }
    // [837] return 
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
    .label version = $63
    .label major = $be
    .label minor = $ee
    // unsigned int version = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_VERSION)
    // [838] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [839] cx16_k_i2c_read_byte::offset = $30 -- vbum1=vbuc1 
    lda #$30
    sta cx16_k_i2c_read_byte.offset
    // [840] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [841] cx16_k_i2c_read_byte::return#11 = cx16_k_i2c_read_byte::return#1
    // smc_version::@1
    // [842] smc_version::version#0 = cx16_k_i2c_read_byte::return#11 -- vwuz1=vwum2 
    lda cx16_k_i2c_read_byte.return
    sta.z version
    lda cx16_k_i2c_read_byte.return+1
    sta.z version+1
    // unsigned int major = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_MAJOR)
    // [843] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [844] cx16_k_i2c_read_byte::offset = $31 -- vbum1=vbuc1 
    lda #$31
    sta cx16_k_i2c_read_byte.offset
    // [845] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [846] cx16_k_i2c_read_byte::return#12 = cx16_k_i2c_read_byte::return#1
    // smc_version::@2
    // [847] smc_version::major#0 = cx16_k_i2c_read_byte::return#12 -- vwuz1=vwum2 
    lda cx16_k_i2c_read_byte.return
    sta.z major
    lda cx16_k_i2c_read_byte.return+1
    sta.z major+1
    // unsigned int minor = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_MINOR)
    // [848] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [849] cx16_k_i2c_read_byte::offset = $32 -- vbum1=vbuc1 
    lda #$32
    sta cx16_k_i2c_read_byte.offset
    // [850] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [851] cx16_k_i2c_read_byte::return#13 = cx16_k_i2c_read_byte::return#1
    // smc_version::@3
    // [852] smc_version::minor#0 = cx16_k_i2c_read_byte::return#13 -- vwuz1=vwum2 
    lda cx16_k_i2c_read_byte.return
    sta.z minor
    lda cx16_k_i2c_read_byte.return+1
    sta.z minor+1
    // sprintf(version_string, "%u.%u.%u", version, major, minor)
    // [853] call snprintf_init
    // [868] phi from smc_version::@3 to snprintf_init [phi:smc_version::@3->snprintf_init]
    // [868] phi snprintf_init::s#25 = smc_version_string [phi:smc_version::@3->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<smc_version_string
    sta.z snprintf_init.s
    lda #>smc_version_string
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // smc_version::@4
    // sprintf(version_string, "%u.%u.%u", version, major, minor)
    // [854] printf_uint::uvalue#1 = smc_version::version#0 -- vwum1=vwuz2 
    lda.z version
    sta printf_uint.uvalue
    lda.z version+1
    sta printf_uint.uvalue+1
    // [855] call printf_uint
    // [907] phi from smc_version::@4 to printf_uint [phi:smc_version::@4->printf_uint]
    // [907] phi printf_uint::format_zero_padding#18 = 0 [phi:smc_version::@4->printf_uint#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uint.format_zero_padding
    // [907] phi printf_uint::format_min_length#18 = 0 [phi:smc_version::@4->printf_uint#1] -- vbum1=vbuc1 
    sta printf_uint.format_min_length
    // [907] phi printf_uint::putc#18 = &snputc [phi:smc_version::@4->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [907] phi printf_uint::format_radix#18 = DECIMAL [phi:smc_version::@4->printf_uint#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uint.format_radix
    // [907] phi printf_uint::uvalue#18 = printf_uint::uvalue#1 [phi:smc_version::@4->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [856] phi from smc_version::@4 to smc_version::@5 [phi:smc_version::@4->smc_version::@5]
    // smc_version::@5
    // sprintf(version_string, "%u.%u.%u", version, major, minor)
    // [857] call printf_str
    // [873] phi from smc_version::@5 to printf_str [phi:smc_version::@5->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:smc_version::@5->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = smc_version::s [phi:smc_version::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_version::@6
    // sprintf(version_string, "%u.%u.%u", version, major, minor)
    // [858] printf_uint::uvalue#2 = smc_version::major#0 -- vwum1=vwuz2 
    lda.z major
    sta printf_uint.uvalue
    lda.z major+1
    sta printf_uint.uvalue+1
    // [859] call printf_uint
    // [907] phi from smc_version::@6 to printf_uint [phi:smc_version::@6->printf_uint]
    // [907] phi printf_uint::format_zero_padding#18 = 0 [phi:smc_version::@6->printf_uint#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uint.format_zero_padding
    // [907] phi printf_uint::format_min_length#18 = 0 [phi:smc_version::@6->printf_uint#1] -- vbum1=vbuc1 
    sta printf_uint.format_min_length
    // [907] phi printf_uint::putc#18 = &snputc [phi:smc_version::@6->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [907] phi printf_uint::format_radix#18 = DECIMAL [phi:smc_version::@6->printf_uint#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uint.format_radix
    // [907] phi printf_uint::uvalue#18 = printf_uint::uvalue#2 [phi:smc_version::@6->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [860] phi from smc_version::@6 to smc_version::@7 [phi:smc_version::@6->smc_version::@7]
    // smc_version::@7
    // sprintf(version_string, "%u.%u.%u", version, major, minor)
    // [861] call printf_str
    // [873] phi from smc_version::@7 to printf_str [phi:smc_version::@7->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:smc_version::@7->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = smc_version::s [phi:smc_version::@7->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_version::@8
    // sprintf(version_string, "%u.%u.%u", version, major, minor)
    // [862] printf_uint::uvalue#3 = smc_version::minor#0 -- vwum1=vwuz2 
    lda.z minor
    sta printf_uint.uvalue
    lda.z minor+1
    sta printf_uint.uvalue+1
    // [863] call printf_uint
    // [907] phi from smc_version::@8 to printf_uint [phi:smc_version::@8->printf_uint]
    // [907] phi printf_uint::format_zero_padding#18 = 0 [phi:smc_version::@8->printf_uint#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uint.format_zero_padding
    // [907] phi printf_uint::format_min_length#18 = 0 [phi:smc_version::@8->printf_uint#1] -- vbum1=vbuc1 
    sta printf_uint.format_min_length
    // [907] phi printf_uint::putc#18 = &snputc [phi:smc_version::@8->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [907] phi printf_uint::format_radix#18 = DECIMAL [phi:smc_version::@8->printf_uint#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uint.format_radix
    // [907] phi printf_uint::uvalue#18 = printf_uint::uvalue#3 [phi:smc_version::@8->printf_uint#4] -- register_copy 
    jsr printf_uint
    // smc_version::@9
    // sprintf(version_string, "%u.%u.%u", version, major, minor)
    // [864] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [865] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_version::@return
    // }
    // [867] return 
    rts
  .segment Data
    s: .text "."
    .byte 0
}
.segment Code
  // snprintf_init
/// Initialize the snprintf() state
// void snprintf_init(__zp($52) char *s, unsigned int n)
snprintf_init: {
    .label s = $52
    // __snprintf_capacity = n
    // [869] __snprintf_capacity = $ffff -- vwum1=vwuc1 
    lda #<$ffff
    sta __snprintf_capacity
    lda #>$ffff
    sta __snprintf_capacity+1
    // __snprintf_size = 0
    // [870] __snprintf_size = 0 -- vwum1=vbuc1 
    lda #<0
    sta __snprintf_size
    sta __snprintf_size+1
    // __snprintf_buffer = s
    // [871] __snprintf_buffer = snprintf_init::s#25 -- pbuz1=pbuz2 
    lda.z s
    sta.z __snprintf_buffer
    lda.z s+1
    sta.z __snprintf_buffer+1
    // snprintf_init::@return
    // }
    // [872] return 
    rts
}
  // printf_str
/// Print a NUL-terminated string
// void printf_str(__zp($b5) void (*putc)(char), __zp($52) const char *s)
printf_str: {
    .label s = $52
    .label putc = $b5
    // [874] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [874] phi printf_str::s#72 = printf_str::s#73 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [875] printf_str::c#1 = *printf_str::s#72 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta c
    // [876] printf_str::s#0 = ++ printf_str::s#72 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [877] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // printf_str::@return
    // }
    // [878] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [879] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [880] callexecute *printf_str::putc#73  -- call__deref_pprz1 
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
  // printf_string
// Print a string value using a specific format
// Handles justification and min length 
// void printf_string(__zp($38) void (*putc)(char), __zp($52) char *str, __mem() char format_min_length, __mem() char format_justify_left)
printf_string: {
    .label printf_string__9 = $be
    .label str = $52
    .label putc = $38
    // if(format.min_length)
    // [883] if(0==printf_string::format_min_length#19) goto printf_string::@1 -- 0_eq_vbum1_then_la1 
    lda format_min_length
    beq __b3
    // printf_string::@3
    // strlen(str)
    // [884] strlen::str#3 = printf_string::str#19 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [885] call strlen
    // [1938] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [1938] phi strlen::str#8 = strlen::str#3 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [886] strlen::return#10 = strlen::len#2
    // printf_string::@6
    // [887] printf_string::$9 = strlen::return#10 -- vwuz1=vwum2 
    lda strlen.return
    sta.z printf_string__9
    lda strlen.return+1
    sta.z printf_string__9+1
    // signed char len = (signed char)strlen(str)
    // [888] printf_string::len#0 = (signed char)printf_string::$9 -- vbsm1=_sbyte_vwuz2 
    lda.z printf_string__9
    sta len
    // padding = (signed char)format.min_length  - len
    // [889] printf_string::padding#1 = (signed char)printf_string::format_min_length#19 - printf_string::len#0 -- vbsm1=vbsm1_minus_vbsm2 
    lda padding
    sec
    sbc len
    sta padding
    // if(padding<0)
    // [890] if(printf_string::padding#1>=0) goto printf_string::@10 -- vbsm1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [892] phi from printf_string printf_string::@6 to printf_string::@1 [phi:printf_string/printf_string::@6->printf_string::@1]
  __b3:
    // [892] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@6->printf_string::@1#0] -- vbsm1=vbsc1 
    lda #0
    sta padding
    // [891] phi from printf_string::@6 to printf_string::@10 [phi:printf_string::@6->printf_string::@10]
    // printf_string::@10
    // [892] phi from printf_string::@10 to printf_string::@1 [phi:printf_string::@10->printf_string::@1]
    // [892] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@10->printf_string::@1#0] -- register_copy 
    // printf_string::@1
  __b1:
    // if(!format.justify_left && padding)
    // [893] if(0!=printf_string::format_justify_left#19) goto printf_string::@2 -- 0_neq_vbum1_then_la1 
    lda format_justify_left
    bne __b2
    // printf_string::@8
    // [894] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b4
    jmp __b2
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [895] printf_padding::putc#3 = printf_string::putc#19 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [896] printf_padding::length#3 = (char)printf_string::padding#3 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [897] call printf_padding
    // [1944] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    // [1944] phi printf_padding::putc#7 = printf_padding::putc#3 [phi:printf_string::@4->printf_padding#0] -- register_copy 
    // [1944] phi printf_padding::pad#7 = ' ' [phi:printf_string::@4->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [1944] phi printf_padding::length#6 = printf_padding::length#3 [phi:printf_string::@4->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [898] printf_str::putc#1 = printf_string::putc#19 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_str.putc
    lda.z putc+1
    sta.z printf_str.putc+1
    // [899] printf_str::s#2 = printf_string::str#19
    // [900] call printf_str
    // [873] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [873] phi printf_str::putc#73 = printf_str::putc#1 [phi:printf_string::@2->printf_str#0] -- register_copy 
    // [873] phi printf_str::s#73 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@7
    // if(format.justify_left && padding)
    // [901] if(0==printf_string::format_justify_left#19) goto printf_string::@return -- 0_eq_vbum1_then_la1 
    lda format_justify_left
    beq __breturn
    // printf_string::@9
    // [902] if(0!=printf_string::padding#3) goto printf_string::@5 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b5
    rts
    // printf_string::@5
  __b5:
    // printf_padding(putc, ' ',(char)padding)
    // [903] printf_padding::putc#4 = printf_string::putc#19 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [904] printf_padding::length#4 = (char)printf_string::padding#3 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [905] call printf_padding
    // [1944] phi from printf_string::@5 to printf_padding [phi:printf_string::@5->printf_padding]
    // [1944] phi printf_padding::putc#7 = printf_padding::putc#4 [phi:printf_string::@5->printf_padding#0] -- register_copy 
    // [1944] phi printf_padding::pad#7 = ' ' [phi:printf_string::@5->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [1944] phi printf_padding::length#6 = printf_padding::length#4 [phi:printf_string::@5->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@return
  __breturn:
    // }
    // [906] return 
    rts
  .segment Data
    len: .byte 0
    .label padding = format_min_length
    format_min_length: .byte 0
    format_justify_left: .byte 0
}
.segment Code
  // printf_uint
// Print an unsigned int using a specific format
// void printf_uint(__zp($b5) void (*putc)(char), __mem() unsigned int uvalue, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, __mem() char format_radix)
printf_uint: {
    .label putc = $b5
    // printf_uint::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [908] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [909] utoa::value#1 = printf_uint::uvalue#18
    // [910] utoa::radix#0 = printf_uint::format_radix#18
    // [911] call utoa
    // Format number into buffer
    jsr utoa
    // printf_uint::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [912] printf_number_buffer::putc#1 = printf_uint::putc#18
    // [913] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [914] printf_number_buffer::format_min_length#1 = printf_uint::format_min_length#18
    // [915] printf_number_buffer::format_zero_padding#1 = printf_uint::format_zero_padding#18
    // [916] call printf_number_buffer
  // Print using format
    // [1982] phi from printf_uint::@2 to printf_number_buffer [phi:printf_uint::@2->printf_number_buffer]
    // [1982] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#1 [phi:printf_uint::@2->printf_number_buffer#0] -- register_copy 
    // [1982] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_uint::@2->printf_number_buffer#1] -- register_copy 
    // [1982] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#1 [phi:printf_uint::@2->printf_number_buffer#2] -- register_copy 
    // [1982] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#1 [phi:printf_uint::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uint::@return
    // }
    // [917] return 
    rts
  .segment Data
    uvalue: .word 0
    format_radix: .byte 0
    format_min_length: .byte 0
    format_zero_padding: .byte 0
}
.segment Code
  // rom_detect
rom_detect: {
    .const bank_set_brom1_bank = 4
    .label rom_detect__3 = $b2
    .label rom_detect__5 = $b2
    .label rom_detect__9 = $b1
    .label rom_detect__14 = $bd
    .label rom_detect__18 = $eb
    .label rom_chip = $4d
    .label rom_detect_address = $c3
    // [919] phi from rom_detect to rom_detect::@1 [phi:rom_detect->rom_detect::@1]
    // [919] phi rom_detect::rom_chip#10 = 0 [phi:rom_detect->rom_detect::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_chip
    // [919] phi rom_detect::rom_detect_address#10 = 0 [phi:rom_detect->rom_detect::@1#1] -- vduz1=vduc1 
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
    // [920] if(rom_detect::rom_detect_address#10<8*$80000) goto rom_detect::@2 -- vduz1_lt_vduc1_then_la1 
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
    // [921] return 
    rts
    // rom_detect::@2
  __b2:
    // rom_manufacturer_ids[rom_chip] = 0
    // [922] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    ldy.z rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = 0
    // [923] rom_device_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta rom_device_ids,y
    // rom_unlock(rom_detect_address + 0x05555, 0x90)
    // [924] rom_unlock::address#2 = rom_detect::rom_detect_address#10 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [925] call rom_unlock
    // [2013] phi from rom_detect::@2 to rom_unlock [phi:rom_detect::@2->rom_unlock]
    // [2013] phi rom_unlock::unlock_code#5 = $90 [phi:rom_detect::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$90
    sta.z rom_unlock.unlock_code
    // [2013] phi rom_unlock::address#5 = rom_unlock::address#2 [phi:rom_detect::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_detect::@12
    // rom_read_byte(rom_detect_address)
    // [926] rom_read_byte::address#0 = rom_detect::rom_detect_address#10 -- vduz1=vduz2 
    lda.z rom_detect_address
    sta.z rom_read_byte.address
    lda.z rom_detect_address+1
    sta.z rom_read_byte.address+1
    lda.z rom_detect_address+2
    sta.z rom_read_byte.address+2
    lda.z rom_detect_address+3
    sta.z rom_read_byte.address+3
    // [927] call rom_read_byte
    // [2023] phi from rom_detect::@12 to rom_read_byte [phi:rom_detect::@12->rom_read_byte]
    // [2023] phi rom_read_byte::address#2 = rom_read_byte::address#0 [phi:rom_detect::@12->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(rom_detect_address)
    // [928] rom_read_byte::return#2 = rom_read_byte::return#0
    // rom_detect::@13
    // [929] rom_detect::$3 = rom_read_byte::return#2
    // rom_manufacturer_ids[rom_chip] = rom_read_byte(rom_detect_address)
    // [930] rom_manufacturer_ids[rom_detect::rom_chip#10] = rom_detect::$3 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z rom_detect__3
    ldy.z rom_chip
    sta rom_manufacturer_ids,y
    // rom_read_byte(rom_detect_address + 1)
    // [931] rom_read_byte::address#1 = rom_detect::rom_detect_address#10 + 1 -- vduz1=vduz2_plus_1 
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
    // [932] call rom_read_byte
    // [2023] phi from rom_detect::@13 to rom_read_byte [phi:rom_detect::@13->rom_read_byte]
    // [2023] phi rom_read_byte::address#2 = rom_read_byte::address#1 [phi:rom_detect::@13->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(rom_detect_address + 1)
    // [933] rom_read_byte::return#3 = rom_read_byte::return#0
    // rom_detect::@14
    // [934] rom_detect::$5 = rom_read_byte::return#3
    // rom_device_ids[rom_chip] = rom_read_byte(rom_detect_address + 1)
    // [935] rom_device_ids[rom_detect::rom_chip#10] = rom_detect::$5 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z rom_detect__5
    ldy.z rom_chip
    sta rom_device_ids,y
    // rom_unlock(rom_detect_address + 0x05555, 0xF0)
    // [936] rom_unlock::address#3 = rom_detect::rom_detect_address#10 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [937] call rom_unlock
    // [2013] phi from rom_detect::@14 to rom_unlock [phi:rom_detect::@14->rom_unlock]
    // [2013] phi rom_unlock::unlock_code#5 = $f0 [phi:rom_detect::@14->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$f0
    sta.z rom_unlock.unlock_code
    // [2013] phi rom_unlock::address#5 = rom_unlock::address#3 [phi:rom_detect::@14->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_detect::bank_set_brom1
    // BROM = bank
    // [938] BROM = rom_detect::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // rom_detect::@11
    // rom_chip*3
    // [939] rom_detect::$14 = rom_detect::rom_chip#10 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta.z rom_detect__14
    // [940] rom_detect::$9 = rom_detect::$14 + rom_detect::rom_chip#10 -- vbuz1=vbuz2_plus_vbuz3 
    clc
    adc.z rom_chip
    sta.z rom_detect__9
    // gotoxy(rom_chip*3+40, 1)
    // [941] gotoxy::x#23 = rom_detect::$9 + $28 -- vbum1=vbuz2_plus_vbuc1 
    lda #$28
    clc
    adc.z rom_detect__9
    sta gotoxy.x
    // [942] call gotoxy
    // [606] phi from rom_detect::@11 to gotoxy [phi:rom_detect::@11->gotoxy]
    // [606] phi gotoxy::y#30 = 1 [phi:rom_detect::@11->gotoxy#0] -- vbum1=vbuc1 
    lda #1
    sta gotoxy.y
    // [606] phi gotoxy::x#30 = gotoxy::x#23 [phi:rom_detect::@11->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_detect::@15
    // printf("%02x", rom_device_ids[rom_chip])
    // [943] printf_uchar::uvalue#4 = rom_device_ids[rom_detect::rom_chip#10] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z rom_chip
    lda rom_device_ids,y
    sta printf_uchar.uvalue
    // [944] call printf_uchar
    // [1035] phi from rom_detect::@15 to printf_uchar [phi:rom_detect::@15->printf_uchar]
    // [1035] phi printf_uchar::format_zero_padding#11 = 1 [phi:rom_detect::@15->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1035] phi printf_uchar::format_min_length#11 = 2 [phi:rom_detect::@15->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1035] phi printf_uchar::putc#11 = &cputc [phi:rom_detect::@15->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1035] phi printf_uchar::format_radix#11 = HEXADECIMAL [phi:rom_detect::@15->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1035] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#4 [phi:rom_detect::@15->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // rom_detect::@16
    // case SST39SF010A:
    //             rom_device_names[rom_chip] = "f010a";
    //             rom_size_strings[rom_chip] = "128";
    //             rom_sizes[rom_chip] = 128 * 1024;
    //             break;
    // [945] if(rom_device_ids[rom_detect::rom_chip#10]==$b5) goto rom_detect::@3 -- pbuc1_derefidx_vbuz1_eq_vbuc2_then_la1 
    ldy.z rom_chip
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
    // [946] if(rom_device_ids[rom_detect::rom_chip#10]==$b6) goto rom_detect::@4 -- pbuc1_derefidx_vbuz1_eq_vbuc2_then_la1 
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
    // [947] if(rom_device_ids[rom_detect::rom_chip#10]==$b7) goto rom_detect::@5 -- pbuc1_derefidx_vbuz1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b7
    beq __b5
    // rom_detect::@6
    // rom_manufacturer_ids[rom_chip] = 0
    // [948] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    sta rom_manufacturer_ids,y
    // rom_device_names[rom_chip] = "----"
    // [949] rom_device_names[rom_detect::$14] = rom_detect::$31 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__14
    lda #<rom_detect__31
    sta rom_device_names,y
    lda #>rom_detect__31
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "000"
    // [950] rom_size_strings[rom_detect::$14] = rom_detect::$32 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__32
    sta rom_size_strings,y
    lda #>rom_detect__32
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 0
    // [951] rom_detect::$24 = rom_detect::rom_chip#10 << 2 -- vbum1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta rom_detect__24
    // [952] rom_sizes[rom_detect::$24] = 0 -- pduc1_derefidx_vbum1=vbuc2 
    tay
    lda #0
    sta rom_sizes,y
    sta rom_sizes+1,y
    sta rom_sizes+2,y
    sta rom_sizes+3,y
    // rom_device_ids[rom_chip] = UNKNOWN
    // [953] rom_device_ids[rom_detect::rom_chip#10] = $55 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$55
    ldy.z rom_chip
    sta rom_device_ids,y
    // rom_detect::@7
  __b7:
    // rom_chip++;
    // [954] rom_detect::rom_chip#1 = ++ rom_detect::rom_chip#10 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip
    // rom_detect::@8
    // rom_detect_address += 0x80000
    // [955] rom_detect::rom_detect_address#1 = rom_detect::rom_detect_address#10 + $80000 -- vduz1=vduz1_plus_vduc1 
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
    // [919] phi from rom_detect::@8 to rom_detect::@1 [phi:rom_detect::@8->rom_detect::@1]
    // [919] phi rom_detect::rom_chip#10 = rom_detect::rom_chip#1 [phi:rom_detect::@8->rom_detect::@1#0] -- register_copy 
    // [919] phi rom_detect::rom_detect_address#10 = rom_detect::rom_detect_address#1 [phi:rom_detect::@8->rom_detect::@1#1] -- register_copy 
    jmp __b1
    // rom_detect::@5
  __b5:
    // rom_device_names[rom_chip] = "f040"
    // [956] rom_device_names[rom_detect::$14] = rom_detect::$29 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__14
    lda #<rom_detect__29
    sta rom_device_names,y
    lda #>rom_detect__29
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "512"
    // [957] rom_size_strings[rom_detect::$14] = rom_detect::$30 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__30
    sta rom_size_strings,y
    lda #>rom_detect__30
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 512 * 1024
    // [958] rom_detect::$21 = rom_detect::rom_chip#10 << 2 -- vbum1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta rom_detect__21
    // [959] rom_sizes[rom_detect::$21] = (unsigned long)$200*$400 -- pduc1_derefidx_vbum1=vduc2 
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
    // [960] rom_device_names[rom_detect::$14] = rom_detect::$27 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__14
    lda #<rom_detect__27
    sta rom_device_names,y
    lda #>rom_detect__27
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "256"
    // [961] rom_size_strings[rom_detect::$14] = rom_detect::$28 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__28
    sta rom_size_strings,y
    lda #>rom_detect__28
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 256 * 1024
    // [962] rom_detect::$18 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta.z rom_detect__18
    // [963] rom_sizes[rom_detect::$18] = (unsigned long)$100*$400 -- pduc1_derefidx_vbuz1=vduc2 
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
    // [964] rom_device_names[rom_detect::$14] = rom_detect::$25 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__14
    lda #<rom_detect__25
    sta rom_device_names,y
    lda #>rom_detect__25
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "128"
    // [965] rom_size_strings[rom_detect::$14] = rom_detect::$26 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__26
    sta rom_size_strings,y
    lda #>rom_detect__26
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 128 * 1024
    // [966] rom_detect::$15 = rom_detect::rom_chip#10 << 2 -- vbum1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta rom_detect__15
    // [967] rom_sizes[rom_detect::$15] = (unsigned long)$80*$400 -- pduc1_derefidx_vbum1=vduc2 
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
    rom_detect__15: .byte 0
    rom_detect__21: .byte 0
    rom_detect__24: .byte 0
}
.segment Code
  // smc_read
/**
 * @brief Read the SMC.BIN file into RAM_BASE.
 * The maximum size of SMC.BIN data that should be in the file is 0x1E00.
 * 
 * @return unsigned int The amount of bytes read from SMC.BIN to be flashed.
 */
smc_read: {
    .label fp = $46
    .label return = $d8
    .label ram_ptr = $c8
    .label smc_file_size = $d8
    /// Holds the amount of bytes actually read in the memory to be flashed.
    .label progress_row_bytes = $e3
    .label y = $42
    // display_action_progress("Reading SMC.BIN ... (.) data, ( ) empty")
    // [969] call display_action_progress
  // It is assume that one RAM bank is 0X2000 bytes.
    // [700] phi from smc_read to display_action_progress [phi:smc_read->display_action_progress]
    // [700] phi display_action_progress::info_text#14 = smc_read::info_text [phi:smc_read->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [970] phi from smc_read to smc_read::@7 [phi:smc_read->smc_read::@7]
    // smc_read::@7
    // textcolor(WHITE)
    // [971] call textcolor
    // [588] phi from smc_read::@7 to textcolor [phi:smc_read::@7->textcolor]
    // [588] phi textcolor::color#18 = WHITE [phi:smc_read::@7->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [972] phi from smc_read::@7 to smc_read::@8 [phi:smc_read::@7->smc_read::@8]
    // smc_read::@8
    // gotoxy(x, y)
    // [973] call gotoxy
    // [606] phi from smc_read::@8 to gotoxy [phi:smc_read::@8->gotoxy]
    // [606] phi gotoxy::y#30 = PROGRESS_Y [phi:smc_read::@8->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [606] phi gotoxy::x#30 = PROGRESS_X [phi:smc_read::@8->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [974] phi from smc_read::@8 to smc_read::@9 [phi:smc_read::@8->smc_read::@9]
    // smc_read::@9
    // FILE *fp = fopen("SMC.BIN", "r")
    // [975] call fopen
    // [2035] phi from smc_read::@9 to fopen [phi:smc_read::@9->fopen]
    // [2035] phi __errno#321 = __errno#35 [phi:smc_read::@9->fopen#0] -- register_copy 
    // [2035] phi fopen::pathtoken#0 = smc_read::path [phi:smc_read::@9->fopen#1] -- pbuz1=pbuc1 
    lda #<path
    sta.z fopen.pathtoken
    lda #>path
    sta.z fopen.pathtoken+1
    jsr fopen
    // FILE *fp = fopen("SMC.BIN", "r")
    // [976] fopen::return#3 = fopen::return#2
    // smc_read::@10
    // [977] smc_read::fp#0 = fopen::return#3 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [978] if((struct $2 *)0==smc_read::fp#0) goto smc_read::@1 -- pssc1_eq_pssz1_then_la1 
    lda.z fp
    cmp #<0
    bne !+
    lda.z fp+1
    cmp #>0
    beq __b4
  !:
    // [979] phi from smc_read::@10 to smc_read::@2 [phi:smc_read::@10->smc_read::@2]
    // [979] phi smc_read::y#10 = PROGRESS_Y [phi:smc_read::@10->smc_read::@2#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // [979] phi smc_read::progress_row_bytes#10 = 0 [phi:smc_read::@10->smc_read::@2#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z progress_row_bytes
    sta.z progress_row_bytes+1
    // [979] phi smc_read::smc_file_size#11 = 0 [phi:smc_read::@10->smc_read::@2#2] -- vwuz1=vwuc1 
    sta.z smc_file_size
    sta.z smc_file_size+1
    // [979] phi smc_read::ram_ptr#10 = (char *)$6000 [phi:smc_read::@10->smc_read::@2#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z ram_ptr
    lda #>$6000
    sta.z ram_ptr+1
  // We read block_size bytes at a time, and each block_size bytes we plot a dot.
  // Every r bytes we move to the next line.
    // smc_read::@2
  __b2:
    // fgets(ram_ptr, SMC_PROGRESS_CELL, fp)
    // [980] fgets::ptr#2 = smc_read::ram_ptr#10 -- pbuz1=pbuz2 
    lda.z ram_ptr
    sta.z fgets.ptr
    lda.z ram_ptr+1
    sta.z fgets.ptr+1
    // [981] fgets::stream#0 = smc_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.stream
    lda.z fp+1
    sta.z fgets.stream+1
    // [982] call fgets
    // [2116] phi from smc_read::@2 to fgets [phi:smc_read::@2->fgets]
    // [2116] phi fgets::ptr#12 = fgets::ptr#2 [phi:smc_read::@2->fgets#0] -- register_copy 
    // [2116] phi fgets::size#10 = SMC_PROGRESS_CELL [phi:smc_read::@2->fgets#1] -- vwum1=vbuc1 
    lda #<SMC_PROGRESS_CELL
    sta fgets.size
    lda #>SMC_PROGRESS_CELL
    sta fgets.size+1
    // [2116] phi fgets::stream#2 = fgets::stream#0 [phi:smc_read::@2->fgets#2] -- register_copy 
    jsr fgets
    // fgets(ram_ptr, SMC_PROGRESS_CELL, fp)
    // [983] fgets::return#5 = fgets::return#1
    // smc_read::@11
    // smc_file_read = fgets(ram_ptr, SMC_PROGRESS_CELL, fp)
    // [984] smc_read::smc_file_read#1 = fgets::return#5 -- vwum1=vwum2 
    lda fgets.return
    sta smc_file_read
    lda fgets.return+1
    sta smc_file_read+1
    // while (smc_file_read = fgets(ram_ptr, SMC_PROGRESS_CELL, fp))
    // [985] if(0!=smc_read::smc_file_read#1) goto smc_read::@3 -- 0_neq_vwum1_then_la1 
    lda smc_file_read
    ora smc_file_read+1
    bne __b3
    // smc_read::@4
    // fclose(fp)
    // [986] fclose::stream#0 = smc_read::fp#0
    // [987] call fclose
    // [2170] phi from smc_read::@4 to fclose [phi:smc_read::@4->fclose]
    // [2170] phi fclose::stream#2 = fclose::stream#0 [phi:smc_read::@4->fclose#0] -- register_copy 
    jsr fclose
    // [988] phi from smc_read::@4 to smc_read::@1 [phi:smc_read::@4->smc_read::@1]
    // [988] phi smc_read::return#0 = smc_read::smc_file_size#11 [phi:smc_read::@4->smc_read::@1#0] -- register_copy 
    rts
    // [988] phi from smc_read::@10 to smc_read::@1 [phi:smc_read::@10->smc_read::@1]
  __b4:
    // [988] phi smc_read::return#0 = 0 [phi:smc_read::@10->smc_read::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // smc_read::@1
    // smc_read::@return
    // }
    // [989] return 
    rts
    // [990] phi from smc_read::@11 to smc_read::@3 [phi:smc_read::@11->smc_read::@3]
    // smc_read::@3
  __b3:
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [991] call snprintf_init
    // [868] phi from smc_read::@3 to snprintf_init [phi:smc_read::@3->snprintf_init]
    // [868] phi snprintf_init::s#25 = info_text [phi:smc_read::@3->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [992] phi from smc_read::@3 to smc_read::@12 [phi:smc_read::@3->smc_read::@12]
    // smc_read::@12
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [993] call printf_str
    // [873] phi from smc_read::@12 to printf_str [phi:smc_read::@12->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:smc_read::@12->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = smc_read::s [phi:smc_read::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@13
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [994] printf_uint::uvalue#4 = smc_read::smc_file_read#1 -- vwum1=vwum2 
    lda smc_file_read
    sta printf_uint.uvalue
    lda smc_file_read+1
    sta printf_uint.uvalue+1
    // [995] call printf_uint
    // [907] phi from smc_read::@13 to printf_uint [phi:smc_read::@13->printf_uint]
    // [907] phi printf_uint::format_zero_padding#18 = 1 [phi:smc_read::@13->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [907] phi printf_uint::format_min_length#18 = 5 [phi:smc_read::@13->printf_uint#1] -- vbum1=vbuc1 
    lda #5
    sta printf_uint.format_min_length
    // [907] phi printf_uint::putc#18 = &snputc [phi:smc_read::@13->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [907] phi printf_uint::format_radix#18 = HEXADECIMAL [phi:smc_read::@13->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [907] phi printf_uint::uvalue#18 = printf_uint::uvalue#4 [phi:smc_read::@13->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [996] phi from smc_read::@13 to smc_read::@14 [phi:smc_read::@13->smc_read::@14]
    // smc_read::@14
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [997] call printf_str
    // [873] phi from smc_read::@14 to printf_str [phi:smc_read::@14->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:smc_read::@14->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = s4 [phi:smc_read::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@15
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [998] printf_uint::uvalue#5 = smc_read::smc_file_size#11 -- vwum1=vwuz2 
    lda.z smc_file_size
    sta printf_uint.uvalue
    lda.z smc_file_size+1
    sta printf_uint.uvalue+1
    // [999] call printf_uint
    // [907] phi from smc_read::@15 to printf_uint [phi:smc_read::@15->printf_uint]
    // [907] phi printf_uint::format_zero_padding#18 = 1 [phi:smc_read::@15->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [907] phi printf_uint::format_min_length#18 = 5 [phi:smc_read::@15->printf_uint#1] -- vbum1=vbuc1 
    lda #5
    sta printf_uint.format_min_length
    // [907] phi printf_uint::putc#18 = &snputc [phi:smc_read::@15->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [907] phi printf_uint::format_radix#18 = HEXADECIMAL [phi:smc_read::@15->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [907] phi printf_uint::uvalue#18 = printf_uint::uvalue#5 [phi:smc_read::@15->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1000] phi from smc_read::@15 to smc_read::@16 [phi:smc_read::@15->smc_read::@16]
    // smc_read::@16
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1001] call printf_str
    // [873] phi from smc_read::@16 to printf_str [phi:smc_read::@16->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:smc_read::@16->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = s2 [phi:smc_read::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // [1002] phi from smc_read::@16 to smc_read::@17 [phi:smc_read::@16->smc_read::@17]
    // smc_read::@17
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1003] call printf_uint
    // [907] phi from smc_read::@17 to printf_uint [phi:smc_read::@17->printf_uint]
    // [907] phi printf_uint::format_zero_padding#18 = 1 [phi:smc_read::@17->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [907] phi printf_uint::format_min_length#18 = 2 [phi:smc_read::@17->printf_uint#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uint.format_min_length
    // [907] phi printf_uint::putc#18 = &snputc [phi:smc_read::@17->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [907] phi printf_uint::format_radix#18 = HEXADECIMAL [phi:smc_read::@17->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [907] phi printf_uint::uvalue#18 = 0 [phi:smc_read::@17->printf_uint#4] -- vwum1=vbuc1 
    lda #<0
    sta printf_uint.uvalue
    sta printf_uint.uvalue+1
    jsr printf_uint
    // [1004] phi from smc_read::@17 to smc_read::@18 [phi:smc_read::@17->smc_read::@18]
    // smc_read::@18
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1005] call printf_str
    // [873] phi from smc_read::@18 to printf_str [phi:smc_read::@18->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:smc_read::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = s3 [phi:smc_read::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@19
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1006] printf_uint::uvalue#7 = (unsigned int)smc_read::ram_ptr#10 -- vwum1=vwuz2 
    lda.z ram_ptr
    sta printf_uint.uvalue
    lda.z ram_ptr+1
    sta printf_uint.uvalue+1
    // [1007] call printf_uint
    // [907] phi from smc_read::@19 to printf_uint [phi:smc_read::@19->printf_uint]
    // [907] phi printf_uint::format_zero_padding#18 = 1 [phi:smc_read::@19->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [907] phi printf_uint::format_min_length#18 = 4 [phi:smc_read::@19->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [907] phi printf_uint::putc#18 = &snputc [phi:smc_read::@19->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [907] phi printf_uint::format_radix#18 = HEXADECIMAL [phi:smc_read::@19->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [907] phi printf_uint::uvalue#18 = printf_uint::uvalue#7 [phi:smc_read::@19->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1008] phi from smc_read::@19 to smc_read::@20 [phi:smc_read::@19->smc_read::@20]
    // smc_read::@20
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1009] call printf_str
    // [873] phi from smc_read::@20 to printf_str [phi:smc_read::@20->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:smc_read::@20->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = s7 [phi:smc_read::@20->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@21
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1010] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1011] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1013] call display_action_text
    // [1046] phi from smc_read::@21 to display_action_text [phi:smc_read::@21->display_action_text]
    // [1046] phi display_action_text::info_text#19 = info_text [phi:smc_read::@21->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_read::@22
    // if (progress_row_bytes == SMC_PROGRESS_ROW)
    // [1014] if(smc_read::progress_row_bytes#10!=SMC_PROGRESS_ROW) goto smc_read::@5 -- vwuz1_neq_vwuc1_then_la1 
    lda.z progress_row_bytes+1
    cmp #>SMC_PROGRESS_ROW
    bne __b5
    lda.z progress_row_bytes
    cmp #<SMC_PROGRESS_ROW
    bne __b5
    // smc_read::@6
    // gotoxy(x, ++y);
    // [1015] smc_read::y#1 = ++ smc_read::y#10 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [1016] gotoxy::y#20 = smc_read::y#1 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [1017] call gotoxy
    // [606] phi from smc_read::@6 to gotoxy [phi:smc_read::@6->gotoxy]
    // [606] phi gotoxy::y#30 = gotoxy::y#20 [phi:smc_read::@6->gotoxy#0] -- register_copy 
    // [606] phi gotoxy::x#30 = PROGRESS_X [phi:smc_read::@6->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1018] phi from smc_read::@6 to smc_read::@5 [phi:smc_read::@6->smc_read::@5]
    // [1018] phi smc_read::y#20 = smc_read::y#1 [phi:smc_read::@6->smc_read::@5#0] -- register_copy 
    // [1018] phi smc_read::progress_row_bytes#4 = 0 [phi:smc_read::@6->smc_read::@5#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z progress_row_bytes
    sta.z progress_row_bytes+1
    // [1018] phi from smc_read::@22 to smc_read::@5 [phi:smc_read::@22->smc_read::@5]
    // [1018] phi smc_read::y#20 = smc_read::y#10 [phi:smc_read::@22->smc_read::@5#0] -- register_copy 
    // [1018] phi smc_read::progress_row_bytes#4 = smc_read::progress_row_bytes#10 [phi:smc_read::@22->smc_read::@5#1] -- register_copy 
    // smc_read::@5
  __b5:
    // cputc('.')
    // [1019] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [1020] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // ram_ptr += smc_file_read
    // [1022] smc_read::ram_ptr#1 = smc_read::ram_ptr#10 + smc_read::smc_file_read#1 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z ram_ptr
    adc smc_file_read
    sta.z ram_ptr
    lda.z ram_ptr+1
    adc smc_file_read+1
    sta.z ram_ptr+1
    // smc_file_size += smc_file_read
    // [1023] smc_read::smc_file_size#1 = smc_read::smc_file_size#11 + smc_read::smc_file_read#1 -- vwuz1=vwuz1_plus_vwum2 
    clc
    lda.z smc_file_size
    adc smc_file_read
    sta.z smc_file_size
    lda.z smc_file_size+1
    adc smc_file_read+1
    sta.z smc_file_size+1
    // progress_row_bytes += smc_file_read
    // [1024] smc_read::progress_row_bytes#1 = smc_read::progress_row_bytes#4 + smc_read::smc_file_read#1 -- vwuz1=vwuz1_plus_vwum2 
    clc
    lda.z progress_row_bytes
    adc smc_file_read
    sta.z progress_row_bytes
    lda.z progress_row_bytes+1
    adc smc_file_read+1
    sta.z progress_row_bytes+1
    // [979] phi from smc_read::@5 to smc_read::@2 [phi:smc_read::@5->smc_read::@2]
    // [979] phi smc_read::y#10 = smc_read::y#20 [phi:smc_read::@5->smc_read::@2#0] -- register_copy 
    // [979] phi smc_read::progress_row_bytes#10 = smc_read::progress_row_bytes#1 [phi:smc_read::@5->smc_read::@2#1] -- register_copy 
    // [979] phi smc_read::smc_file_size#11 = smc_read::smc_file_size#1 [phi:smc_read::@5->smc_read::@2#2] -- register_copy 
    // [979] phi smc_read::ram_ptr#10 = smc_read::ram_ptr#1 [phi:smc_read::@5->smc_read::@2#3] -- register_copy 
    jmp __b2
  .segment Data
    info_text: .text "Reading SMC.BIN ... (.) data, ( ) empty"
    .byte 0
    path: .text "SMC.BIN"
    .byte 0
    s: .text "Reading SMC.BIN:"
    .byte 0
    .label smc_file_read = smc_flash.smc_commit_result
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
    // [1026] BRAM = system_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // system_reset::bank_set_brom1
    // BROM = bank
    // [1027] BROM = system_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // system_reset::@2
    // asm
    // asm { jmp($FFFC)  }
    jmp ($fffc)
    // [1029] phi from system_reset::@1 system_reset::@2 to system_reset::@1 [phi:system_reset::@1/system_reset::@2->system_reset::@1]
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
    .label i = $54
    // [1031] phi from wait_moment to wait_moment::@1 [phi:wait_moment->wait_moment::@1]
    // [1031] phi wait_moment::i#2 = $ffff [phi:wait_moment->wait_moment::@1#0] -- vwuz1=vwuc1 
    lda #<$ffff
    sta.z i
    lda #>$ffff
    sta.z i+1
    // wait_moment::@1
  __b1:
    // for(unsigned int i=65535; i>0; i--)
    // [1032] if(wait_moment::i#2>0) goto wait_moment::@2 -- vwuz1_gt_0_then_la1 
    lda.z i+1
    bne __b2
    lda.z i
    bne __b2
  !:
    // wait_moment::@return
    // }
    // [1033] return 
    rts
    // wait_moment::@2
  __b2:
    // for(unsigned int i=65535; i>0; i--)
    // [1034] wait_moment::i#1 = -- wait_moment::i#2 -- vwuz1=_dec_vwuz1 
    lda.z i
    bne !+
    dec.z i+1
  !:
    dec.z i
    // [1031] phi from wait_moment::@2 to wait_moment::@1 [phi:wait_moment::@2->wait_moment::@1]
    // [1031] phi wait_moment::i#2 = wait_moment::i#1 [phi:wait_moment::@2->wait_moment::@1#0] -- register_copy 
    jmp __b1
}
  // printf_uchar
// Print an unsigned char using a specific format
// void printf_uchar(__zp($b5) void (*putc)(char), __mem() char uvalue, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, __mem() char format_radix)
printf_uchar: {
    .label putc = $b5
    // printf_uchar::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1036] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // uctoa(uvalue, printf_buffer.digits, format.radix)
    // [1037] uctoa::value#1 = printf_uchar::uvalue#11
    // [1038] uctoa::radix#0 = printf_uchar::format_radix#11
    // [1039] call uctoa
    // Format number into buffer
    jsr uctoa
    // printf_uchar::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1040] printf_number_buffer::putc#2 = printf_uchar::putc#11
    // [1041] printf_number_buffer::buffer_sign#2 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [1042] printf_number_buffer::format_min_length#2 = printf_uchar::format_min_length#11
    // [1043] printf_number_buffer::format_zero_padding#2 = printf_uchar::format_zero_padding#11
    // [1044] call printf_number_buffer
  // Print using format
    // [1982] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [1982] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#2 [phi:printf_uchar::@2->printf_number_buffer#0] -- register_copy 
    // [1982] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#2 [phi:printf_uchar::@2->printf_number_buffer#1] -- register_copy 
    // [1982] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#2 [phi:printf_uchar::@2->printf_number_buffer#2] -- register_copy 
    // [1982] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#2 [phi:printf_uchar::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [1045] return 
    rts
  .segment Data
    uvalue: .byte 0
    format_radix: .byte 0
    .label format_min_length = printf_uint.format_min_length
    .label format_zero_padding = printf_uint.format_zero_padding
}
.segment Code
  // display_action_text
/**
 * @brief Print an info line at the action frame, which is the second line.
 * 
 * @param info_text The info text to be displayed.
 */
// void display_action_text(__zp($38) char *info_text)
display_action_text: {
    .label x = $4f
    .label y = $c7
    .label info_text = $38
    // unsigned char x = wherex()
    // [1047] call wherex
    jsr wherex
    // [1048] wherex::return#3 = wherex::return#0
    // display_action_text::@1
    // [1049] display_action_text::x#0 = wherex::return#3 -- vbuz1=vbum2 
    lda wherex.return
    sta.z x
    // unsigned char y = wherey()
    // [1050] call wherey
    jsr wherey
    // [1051] wherey::return#3 = wherey::return#0
    // display_action_text::@2
    // [1052] display_action_text::y#0 = wherey::return#3 -- vbuz1=vbum2 
    lda wherey.return
    sta.z y
    // gotoxy(2, PROGRESS_Y-3)
    // [1053] call gotoxy
    // [606] phi from display_action_text::@2 to gotoxy [phi:display_action_text::@2->gotoxy]
    // [606] phi gotoxy::y#30 = PROGRESS_Y-3 [phi:display_action_text::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-3
    sta gotoxy.y
    // [606] phi gotoxy::x#30 = 2 [phi:display_action_text::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // display_action_text::@3
    // printf("%-65s", info_text)
    // [1054] printf_string::str#2 = display_action_text::info_text#19 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1055] call printf_string
    // [882] phi from display_action_text::@3 to printf_string [phi:display_action_text::@3->printf_string]
    // [882] phi printf_string::putc#19 = &cputc [phi:display_action_text::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [882] phi printf_string::str#19 = printf_string::str#2 [phi:display_action_text::@3->printf_string#1] -- register_copy 
    // [882] phi printf_string::format_justify_left#19 = 1 [phi:display_action_text::@3->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [882] phi printf_string::format_min_length#19 = $41 [phi:display_action_text::@3->printf_string#3] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_action_text::@4
    // gotoxy(x, y)
    // [1056] gotoxy::x#12 = display_action_text::x#0 -- vbum1=vbuz2 
    lda.z x
    sta gotoxy.x
    // [1057] gotoxy::y#12 = display_action_text::y#0 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [1058] call gotoxy
    // [606] phi from display_action_text::@4 to gotoxy [phi:display_action_text::@4->gotoxy]
    // [606] phi gotoxy::y#30 = gotoxy::y#12 [phi:display_action_text::@4->gotoxy#0] -- register_copy 
    // [606] phi gotoxy::x#30 = gotoxy::x#12 [phi:display_action_text::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_action_text::@return
    // }
    // [1059] return 
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
    // [1061] BRAM = smc_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // smc_reset::bank_set_brom1
    // BROM = bank
    // [1062] BROM = smc_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // smc_reset::@2
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [1063] smc_reset::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [1064] smc_reset::cx16_k_i2c_write_byte1_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte1_offset
    // [1065] smc_reset::cx16_k_i2c_write_byte1_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte1_value
    // smc_reset::cx16_k_i2c_write_byte1
    // unsigned char result
    // [1066] smc_reset::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
    sta cx16_k_i2c_write_byte1_result
    // asm
    // asm { ldxdevice ldyoffset ldavalue stzresult jsrCX16_I2C_WRITE_BYTE rolresult  }
    ldx cx16_k_i2c_write_byte1_device
    ldy cx16_k_i2c_write_byte1_offset
    lda cx16_k_i2c_write_byte1_value
    stz cx16_k_i2c_write_byte1_result
    jsr CX16_I2C_WRITE_BYTE
    rol cx16_k_i2c_write_byte1_result
    // [1068] phi from smc_reset::@1 smc_reset::cx16_k_i2c_write_byte1 to smc_reset::@1 [phi:smc_reset::@1/smc_reset::cx16_k_i2c_write_byte1->smc_reset::@1]
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
// void display_info_rom(__zp($f0) char rom_chip, __zp($41) char info_status, __zp($44) char *info_text)
display_info_rom: {
    .label display_info_rom__10 = $41
    .label display_info_rom__11 = $cc
    .label display_info_rom__13 = $ce
    .label rom_chip = $f0
    .label info_status = $41
    .label info_text = $44
    // unsigned char x = wherex()
    // [1070] call wherex
    jsr wherex
    // [1071] wherex::return#12 = wherex::return#0
    // display_info_rom::@3
    // [1072] display_info_rom::x#0 = wherex::return#12 -- vbum1=vbum2 
    lda wherex.return
    sta x
    // unsigned char y = wherey()
    // [1073] call wherey
    jsr wherey
    // [1074] wherey::return#12 = wherey::return#0
    // display_info_rom::@4
    // [1075] display_info_rom::y#0 = wherey::return#12 -- vbum1=vbum2 
    lda wherey.return
    sta y
    // status_rom[rom_chip] = info_status
    // [1076] status_rom[display_info_rom::rom_chip#17] = display_info_rom::info_status#17 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z info_status
    ldy.z rom_chip
    sta status_rom,y
    // display_rom_led(rom_chip, status_color[info_status])
    // [1077] display_rom_led::chip#1 = display_info_rom::rom_chip#17 -- vbuz1=vbuz2 
    tya
    sta.z display_rom_led.chip
    // [1078] display_rom_led::c#1 = status_color[display_info_rom::info_status#17] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z display_rom_led.c
    // [1079] call display_rom_led
    // [1918] phi from display_info_rom::@4 to display_rom_led [phi:display_info_rom::@4->display_rom_led]
    // [1918] phi display_rom_led::c#2 = display_rom_led::c#1 [phi:display_info_rom::@4->display_rom_led#0] -- register_copy 
    // [1918] phi display_rom_led::chip#2 = display_rom_led::chip#1 [phi:display_info_rom::@4->display_rom_led#1] -- register_copy 
    jsr display_rom_led
    // display_info_rom::@5
    // gotoxy(INFO_X, INFO_Y+rom_chip+2)
    // [1080] gotoxy::y#17 = display_info_rom::rom_chip#17 + $11+2 -- vbum1=vbuz2_plus_vbuc1 
    lda #$11+2
    clc
    adc.z rom_chip
    sta gotoxy.y
    // [1081] call gotoxy
    // [606] phi from display_info_rom::@5 to gotoxy [phi:display_info_rom::@5->gotoxy]
    // [606] phi gotoxy::y#30 = gotoxy::y#17 [phi:display_info_rom::@5->gotoxy#0] -- register_copy 
    // [606] phi gotoxy::x#30 = 4 [phi:display_info_rom::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.x
    jsr gotoxy
    // [1082] phi from display_info_rom::@5 to display_info_rom::@6 [phi:display_info_rom::@5->display_info_rom::@6]
    // display_info_rom::@6
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1083] call printf_str
    // [873] phi from display_info_rom::@6 to printf_str [phi:display_info_rom::@6->printf_str]
    // [873] phi printf_str::putc#73 = &cputc [phi:display_info_rom::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = display_info_rom::s [phi:display_info_rom::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@7
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1084] printf_uchar::uvalue#0 = display_info_rom::rom_chip#17 -- vbum1=vbuz2 
    lda.z rom_chip
    sta printf_uchar.uvalue
    // [1085] call printf_uchar
    // [1035] phi from display_info_rom::@7 to printf_uchar [phi:display_info_rom::@7->printf_uchar]
    // [1035] phi printf_uchar::format_zero_padding#11 = 0 [phi:display_info_rom::@7->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1035] phi printf_uchar::format_min_length#11 = 0 [phi:display_info_rom::@7->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1035] phi printf_uchar::putc#11 = &cputc [phi:display_info_rom::@7->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1035] phi printf_uchar::format_radix#11 = DECIMAL [phi:display_info_rom::@7->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1035] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#0 [phi:display_info_rom::@7->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1086] phi from display_info_rom::@7 to display_info_rom::@8 [phi:display_info_rom::@7->display_info_rom::@8]
    // display_info_rom::@8
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1087] call printf_str
    // [873] phi from display_info_rom::@8 to printf_str [phi:display_info_rom::@8->printf_str]
    // [873] phi printf_str::putc#73 = &cputc [phi:display_info_rom::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = s1 [phi:display_info_rom::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@9
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1088] display_info_rom::$10 = display_info_rom::info_status#17 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_info_rom__10
    // [1089] printf_string::str#7 = status_text[display_info_rom::$10] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z display_info_rom__10
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [1090] call printf_string
    // [882] phi from display_info_rom::@9 to printf_string [phi:display_info_rom::@9->printf_string]
    // [882] phi printf_string::putc#19 = &cputc [phi:display_info_rom::@9->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [882] phi printf_string::str#19 = printf_string::str#7 [phi:display_info_rom::@9->printf_string#1] -- register_copy 
    // [882] phi printf_string::format_justify_left#19 = 1 [phi:display_info_rom::@9->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [882] phi printf_string::format_min_length#19 = 9 [phi:display_info_rom::@9->printf_string#3] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [1091] phi from display_info_rom::@9 to display_info_rom::@10 [phi:display_info_rom::@9->display_info_rom::@10]
    // display_info_rom::@10
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1092] call printf_str
    // [873] phi from display_info_rom::@10 to printf_str [phi:display_info_rom::@10->printf_str]
    // [873] phi printf_str::putc#73 = &cputc [phi:display_info_rom::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = s1 [phi:display_info_rom::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@11
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1093] display_info_rom::$11 = display_info_rom::rom_chip#17 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta.z display_info_rom__11
    // [1094] printf_string::str#8 = rom_device_names[display_info_rom::$11] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda rom_device_names,y
    sta.z printf_string.str
    lda rom_device_names+1,y
    sta.z printf_string.str+1
    // [1095] call printf_string
    // [882] phi from display_info_rom::@11 to printf_string [phi:display_info_rom::@11->printf_string]
    // [882] phi printf_string::putc#19 = &cputc [phi:display_info_rom::@11->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [882] phi printf_string::str#19 = printf_string::str#8 [phi:display_info_rom::@11->printf_string#1] -- register_copy 
    // [882] phi printf_string::format_justify_left#19 = 1 [phi:display_info_rom::@11->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [882] phi printf_string::format_min_length#19 = 6 [phi:display_info_rom::@11->printf_string#3] -- vbum1=vbuc1 
    lda #6
    sta printf_string.format_min_length
    jsr printf_string
    // [1096] phi from display_info_rom::@11 to display_info_rom::@12 [phi:display_info_rom::@11->display_info_rom::@12]
    // display_info_rom::@12
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1097] call printf_str
    // [873] phi from display_info_rom::@12 to printf_str [phi:display_info_rom::@12->printf_str]
    // [873] phi printf_str::putc#73 = &cputc [phi:display_info_rom::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = s1 [phi:display_info_rom::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@13
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1098] display_info_rom::$13 = display_info_rom::rom_chip#17 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta.z display_info_rom__13
    // [1099] printf_ulong::uvalue#0 = file_sizes[display_info_rom::$13] -- vdum1=pduc1_derefidx_vbuz2 
    tay
    lda file_sizes,y
    sta printf_ulong.uvalue
    lda file_sizes+1,y
    sta printf_ulong.uvalue+1
    lda file_sizes+2,y
    sta printf_ulong.uvalue+2
    lda file_sizes+3,y
    sta printf_ulong.uvalue+3
    // [1100] call printf_ulong
    // [1270] phi from display_info_rom::@13 to printf_ulong [phi:display_info_rom::@13->printf_ulong]
    // [1270] phi printf_ulong::format_zero_padding#11 = 1 [phi:display_info_rom::@13->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1270] phi printf_ulong::format_min_length#11 = 5 [phi:display_info_rom::@13->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1270] phi printf_ulong::putc#11 = &cputc [phi:display_info_rom::@13->printf_ulong#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_ulong.putc
    lda #>cputc
    sta.z printf_ulong.putc+1
    // [1270] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:display_info_rom::@13->printf_ulong#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1270] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#0 [phi:display_info_rom::@13->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1101] phi from display_info_rom::@13 to display_info_rom::@14 [phi:display_info_rom::@13->display_info_rom::@14]
    // display_info_rom::@14
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1102] call printf_str
    // [873] phi from display_info_rom::@14 to printf_str [phi:display_info_rom::@14->printf_str]
    // [873] phi printf_str::putc#73 = &cputc [phi:display_info_rom::@14->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = display_info_rom::s4 [phi:display_info_rom::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@15
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1103] printf_ulong::uvalue#1 = rom_sizes[display_info_rom::$13] -- vdum1=pduc1_derefidx_vbuz2 
    ldy.z display_info_rom__13
    lda rom_sizes,y
    sta printf_ulong.uvalue
    lda rom_sizes+1,y
    sta printf_ulong.uvalue+1
    lda rom_sizes+2,y
    sta printf_ulong.uvalue+2
    lda rom_sizes+3,y
    sta printf_ulong.uvalue+3
    // [1104] call printf_ulong
    // [1270] phi from display_info_rom::@15 to printf_ulong [phi:display_info_rom::@15->printf_ulong]
    // [1270] phi printf_ulong::format_zero_padding#11 = 1 [phi:display_info_rom::@15->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1270] phi printf_ulong::format_min_length#11 = 5 [phi:display_info_rom::@15->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1270] phi printf_ulong::putc#11 = &cputc [phi:display_info_rom::@15->printf_ulong#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_ulong.putc
    lda #>cputc
    sta.z printf_ulong.putc+1
    // [1270] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:display_info_rom::@15->printf_ulong#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1270] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#1 [phi:display_info_rom::@15->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1105] phi from display_info_rom::@15 to display_info_rom::@16 [phi:display_info_rom::@15->display_info_rom::@16]
    // display_info_rom::@16
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1106] call printf_str
    // [873] phi from display_info_rom::@16 to printf_str [phi:display_info_rom::@16->printf_str]
    // [873] phi printf_str::putc#73 = &cputc [phi:display_info_rom::@16->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = s1 [phi:display_info_rom::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@17
    // if(info_text)
    // [1107] if((char *)0==display_info_rom::info_text#17) goto display_info_rom::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // display_info_rom::@2
    // printf("%-25s", info_text)
    // [1108] printf_string::str#9 = display_info_rom::info_text#17 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1109] call printf_string
    // [882] phi from display_info_rom::@2 to printf_string [phi:display_info_rom::@2->printf_string]
    // [882] phi printf_string::putc#19 = &cputc [phi:display_info_rom::@2->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [882] phi printf_string::str#19 = printf_string::str#9 [phi:display_info_rom::@2->printf_string#1] -- register_copy 
    // [882] phi printf_string::format_justify_left#19 = 1 [phi:display_info_rom::@2->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [882] phi printf_string::format_min_length#19 = $19 [phi:display_info_rom::@2->printf_string#3] -- vbum1=vbuc1 
    lda #$19
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_rom::@1
  __b1:
    // gotoxy(x,y)
    // [1110] gotoxy::x#18 = display_info_rom::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1111] gotoxy::y#18 = display_info_rom::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1112] call gotoxy
    // [606] phi from display_info_rom::@1 to gotoxy [phi:display_info_rom::@1->gotoxy]
    // [606] phi gotoxy::y#30 = gotoxy::y#18 [phi:display_info_rom::@1->gotoxy#0] -- register_copy 
    // [606] phi gotoxy::x#30 = gotoxy::x#18 [phi:display_info_rom::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_rom::@return
    // }
    // [1113] return 
    rts
  .segment Data
    s: .text "ROM"
    .byte 0
    s4: .text " / "
    .byte 0
    .label x = rom_read_byte.rom_bank1_rom_read_byte__1
    .label y = rom_read_byte.rom_bank1_return
}
.segment Code
  // rom_file
// __mem() char * rom_file(__zp($d0) char rom_chip)
rom_file: {
    .label rom_file__0 = $d0
    .label rom_chip = $d0
    // if(rom_chip)
    // [1115] if(0!=rom_file::rom_chip#2) goto rom_file::@1 -- 0_neq_vbuz1_then_la1 
    lda.z rom_chip
    bne __b1
    // [1118] phi from rom_file to rom_file::@return [phi:rom_file->rom_file::@return]
    // [1118] phi rom_file::return#2 = rom_file::file_rom_cx16 [phi:rom_file->rom_file::@return#0] -- pbum1=pbuc1 
    lda #<file_rom_cx16
    sta return
    lda #>file_rom_cx16
    sta return+1
    rts
    // rom_file::@1
  __b1:
    // '0'+rom_chip
    // [1116] rom_file::$0 = '0' + rom_file::rom_chip#2 -- vbuz1=vbuc1_plus_vbuz1 
    lda #'0'
    clc
    adc.z rom_file__0
    sta.z rom_file__0
    // file_rom_card[3] = '0'+rom_chip
    // [1117] *(rom_file::file_rom_card+3) = rom_file::$0 -- _deref_pbuc1=vbuz1 
    sta file_rom_card+3
    // [1118] phi from rom_file::@1 to rom_file::@return [phi:rom_file::@1->rom_file::@return]
    // [1118] phi rom_file::return#2 = rom_file::file_rom_card [phi:rom_file::@1->rom_file::@return#0] -- pbum1=pbuc1 
    lda #<file_rom_card
    sta return
    lda #>file_rom_card
    sta return+1
    // rom_file::@return
    // }
    // [1119] return 
    rts
  .segment Data
    file_rom_cx16: .text "ROM.BIN"
    .byte 0
    file_rom_card: .text "ROMn.BIN"
    .byte 0
    return: .word 0
}
.segment Code
  // rom_read
// __zp($f2) unsigned long rom_read(char rom_chip, __zp($df) char *file, char info_status, __zp($de) char brom_bank_start, __zp($5f) unsigned long rom_size)
rom_read: {
    .const bank_set_brom1_bank = 0
    .label rom_read__11 = $d1
    .label rom_address = $da
    .label return = $f2
    .label rom_package_read = $ee
    .label brom_bank_start = $de
    .label ram_address = $af
    .label rom_file_size = $f2
    .label rom_row_current = $69
    .label y = $e7
    .label bram_bank = $3c
    .label file = $df
    .label rom_size = $5f
    // unsigned long rom_address = rom_address_from_bank(brom_bank_start)
    // [1121] rom_address_from_bank::rom_bank#0 = rom_read::brom_bank_start#21 -- vbum1=vbuz2 
    lda.z brom_bank_start
    sta rom_address_from_bank.rom_bank
    // [1122] call rom_address_from_bank
    // [2226] phi from rom_read to rom_address_from_bank [phi:rom_read->rom_address_from_bank]
    // [2226] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#0 [phi:rom_read->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(brom_bank_start)
    // [1123] rom_address_from_bank::return#2 = rom_address_from_bank::return#0
    // rom_read::@15
    // [1124] rom_read::rom_address#0 = rom_address_from_bank::return#2
    // rom_read::bank_set_bram1
    // BRAM = bank
    // [1125] BRAM = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z BRAM
    // rom_read::bank_set_brom1
    // BROM = bank
    // [1126] BROM = rom_read::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [1127] phi from rom_read::bank_set_brom1 to rom_read::@13 [phi:rom_read::bank_set_brom1->rom_read::@13]
    // rom_read::@13
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1128] call snprintf_init
    // [868] phi from rom_read::@13 to snprintf_init [phi:rom_read::@13->snprintf_init]
    // [868] phi snprintf_init::s#25 = info_text [phi:rom_read::@13->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1129] phi from rom_read::@13 to rom_read::@16 [phi:rom_read::@13->rom_read::@16]
    // rom_read::@16
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1130] call printf_str
    // [873] phi from rom_read::@16 to printf_str [phi:rom_read::@16->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:rom_read::@16->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = rom_read::s [phi:rom_read::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@17
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1131] printf_string::str#10 = rom_read::file#11 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [1132] call printf_string
    // [882] phi from rom_read::@17 to printf_string [phi:rom_read::@17->printf_string]
    // [882] phi printf_string::putc#19 = &snputc [phi:rom_read::@17->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [882] phi printf_string::str#19 = printf_string::str#10 [phi:rom_read::@17->printf_string#1] -- register_copy 
    // [882] phi printf_string::format_justify_left#19 = 0 [phi:rom_read::@17->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [882] phi printf_string::format_min_length#19 = 0 [phi:rom_read::@17->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [1133] phi from rom_read::@17 to rom_read::@18 [phi:rom_read::@17->rom_read::@18]
    // rom_read::@18
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1134] call printf_str
    // [873] phi from rom_read::@18 to printf_str [phi:rom_read::@18->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:rom_read::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = rom_read::s1 [phi:rom_read::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@19
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1135] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1136] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1138] call display_action_text
    // [1046] phi from rom_read::@19 to display_action_text [phi:rom_read::@19->display_action_text]
    // [1046] phi display_action_text::info_text#19 = info_text [phi:rom_read::@19->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // rom_read::@20
    // FILE *fp = fopen(file, "r")
    // [1139] fopen::path#3 = rom_read::file#11 -- pbuz1=pbuz2 
    lda.z file
    sta.z fopen.path
    lda.z file+1
    sta.z fopen.path+1
    // [1140] call fopen
    // [2035] phi from rom_read::@20 to fopen [phi:rom_read::@20->fopen]
    // [2035] phi __errno#321 = __errno#106 [phi:rom_read::@20->fopen#0] -- register_copy 
    // [2035] phi fopen::pathtoken#0 = fopen::path#3 [phi:rom_read::@20->fopen#1] -- register_copy 
    jsr fopen
    // FILE *fp = fopen(file, "r")
    // [1141] fopen::return#4 = fopen::return#2
    // rom_read::@21
    // [1142] rom_read::fp#0 = fopen::return#4 -- pssm1=pssz2 
    lda.z fopen.return
    sta fp
    lda.z fopen.return+1
    sta fp+1
    // if (fp)
    // [1143] if((struct $2 *)0==rom_read::fp#0) goto rom_read::@1 -- pssc1_eq_pssm1_then_la1 
    lda fp
    cmp #<0
    bne !+
    lda fp+1
    cmp #>0
    beq __b2
  !:
    // [1144] phi from rom_read::@21 to rom_read::@2 [phi:rom_read::@21->rom_read::@2]
    // rom_read::@2
    // gotoxy(x, y)
    // [1145] call gotoxy
    // [606] phi from rom_read::@2 to gotoxy [phi:rom_read::@2->gotoxy]
    // [606] phi gotoxy::y#30 = PROGRESS_Y [phi:rom_read::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [606] phi gotoxy::x#30 = PROGRESS_X [phi:rom_read::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1146] phi from rom_read::@2 to rom_read::@3 [phi:rom_read::@2->rom_read::@3]
    // [1146] phi rom_read::y#11 = PROGRESS_Y [phi:rom_read::@2->rom_read::@3#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // [1146] phi rom_read::rom_row_current#10 = 0 [phi:rom_read::@2->rom_read::@3#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z rom_row_current
    sta.z rom_row_current+1
    // [1146] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#21 [phi:rom_read::@2->rom_read::@3#2] -- register_copy 
    // [1146] phi rom_read::rom_address#10 = rom_read::rom_address#0 [phi:rom_read::@2->rom_read::@3#3] -- register_copy 
    // [1146] phi rom_read::ram_address#10 = (char *)$6000 [phi:rom_read::@2->rom_read::@3#4] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z ram_address
    lda #>$6000
    sta.z ram_address+1
    // [1146] phi rom_read::bram_bank#10 = 0 [phi:rom_read::@2->rom_read::@3#5] -- vbuz1=vbuc1 
    lda #0
    sta.z bram_bank
    // [1146] phi rom_read::rom_file_size#11 = 0 [phi:rom_read::@2->rom_read::@3#6] -- vduz1=vduc1 
    sta.z rom_file_size
    sta.z rom_file_size+1
    lda #<0>>$10
    sta.z rom_file_size+2
    lda #>0>>$10
    sta.z rom_file_size+3
    // rom_read::@3
  __b3:
    // while (rom_file_size < rom_size)
    // [1147] if(rom_read::rom_file_size#11<rom_read::rom_size#12) goto rom_read::@4 -- vduz1_lt_vduz2_then_la1 
    lda.z rom_file_size+3
    cmp.z rom_size+3
    bcc __b4
    bne !+
    lda.z rom_file_size+2
    cmp.z rom_size+2
    bcc __b4
    bne !+
    lda.z rom_file_size+1
    cmp.z rom_size+1
    bcc __b4
    bne !+
    lda.z rom_file_size
    cmp.z rom_size
    bcc __b4
  !:
    // rom_read::@7
  __b7:
    // fclose(fp)
    // [1148] fclose::stream#1 = rom_read::fp#0 -- pssz1=pssm2 
    lda fp
    sta.z fclose.stream
    lda fp+1
    sta.z fclose.stream+1
    // [1149] call fclose
    // [2170] phi from rom_read::@7 to fclose [phi:rom_read::@7->fclose]
    // [2170] phi fclose::stream#2 = fclose::stream#1 [phi:rom_read::@7->fclose#0] -- register_copy 
    jsr fclose
    // [1150] phi from rom_read::@7 to rom_read::@1 [phi:rom_read::@7->rom_read::@1]
    // [1150] phi rom_read::return#0 = rom_read::rom_file_size#11 [phi:rom_read::@7->rom_read::@1#0] -- register_copy 
    rts
    // [1150] phi from rom_read::@21 to rom_read::@1 [phi:rom_read::@21->rom_read::@1]
  __b2:
    // [1150] phi rom_read::return#0 = 0 [phi:rom_read::@21->rom_read::@1#0] -- vduz1=vduc1 
    lda #<0
    sta.z return
    sta.z return+1
    lda #<0>>$10
    sta.z return+2
    lda #>0>>$10
    sta.z return+3
    // rom_read::@1
    // rom_read::@return
    // }
    // [1151] return 
    rts
    // [1152] phi from rom_read::@3 to rom_read::@4 [phi:rom_read::@3->rom_read::@4]
    // rom_read::@4
  __b4:
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1153] call snprintf_init
    // [868] phi from rom_read::@4 to snprintf_init [phi:rom_read::@4->snprintf_init]
    // [868] phi snprintf_init::s#25 = info_text [phi:rom_read::@4->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1154] phi from rom_read::@4 to rom_read::@22 [phi:rom_read::@4->rom_read::@22]
    // rom_read::@22
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1155] call printf_str
    // [873] phi from rom_read::@22 to printf_str [phi:rom_read::@22->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:rom_read::@22->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = s14 [phi:rom_read::@22->printf_str#1] -- pbuz1=pbuc1 
    lda #<s14
    sta.z printf_str.s
    lda #>s14
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@23
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1156] printf_string::str#11 = rom_read::file#11 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [1157] call printf_string
    // [882] phi from rom_read::@23 to printf_string [phi:rom_read::@23->printf_string]
    // [882] phi printf_string::putc#19 = &snputc [phi:rom_read::@23->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [882] phi printf_string::str#19 = printf_string::str#11 [phi:rom_read::@23->printf_string#1] -- register_copy 
    // [882] phi printf_string::format_justify_left#19 = 0 [phi:rom_read::@23->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [882] phi printf_string::format_min_length#19 = 0 [phi:rom_read::@23->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [1158] phi from rom_read::@23 to rom_read::@24 [phi:rom_read::@23->rom_read::@24]
    // rom_read::@24
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1159] call printf_str
    // [873] phi from rom_read::@24 to printf_str [phi:rom_read::@24->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:rom_read::@24->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = s3 [phi:rom_read::@24->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@25
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1160] printf_ulong::uvalue#2 = rom_read::rom_file_size#11 -- vdum1=vduz2 
    lda.z rom_file_size
    sta printf_ulong.uvalue
    lda.z rom_file_size+1
    sta printf_ulong.uvalue+1
    lda.z rom_file_size+2
    sta printf_ulong.uvalue+2
    lda.z rom_file_size+3
    sta printf_ulong.uvalue+3
    // [1161] call printf_ulong
    // [1270] phi from rom_read::@25 to printf_ulong [phi:rom_read::@25->printf_ulong]
    // [1270] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_read::@25->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1270] phi printf_ulong::format_min_length#11 = 5 [phi:rom_read::@25->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1270] phi printf_ulong::putc#11 = &snputc [phi:rom_read::@25->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1270] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_read::@25->printf_ulong#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1270] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#2 [phi:rom_read::@25->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1162] phi from rom_read::@25 to rom_read::@26 [phi:rom_read::@25->rom_read::@26]
    // rom_read::@26
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1163] call printf_str
    // [873] phi from rom_read::@26 to printf_str [phi:rom_read::@26->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:rom_read::@26->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = s4 [phi:rom_read::@26->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@27
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1164] printf_ulong::uvalue#3 = rom_read::rom_size#12 -- vdum1=vduz2 
    lda.z rom_size
    sta printf_ulong.uvalue
    lda.z rom_size+1
    sta printf_ulong.uvalue+1
    lda.z rom_size+2
    sta printf_ulong.uvalue+2
    lda.z rom_size+3
    sta printf_ulong.uvalue+3
    // [1165] call printf_ulong
    // [1270] phi from rom_read::@27 to printf_ulong [phi:rom_read::@27->printf_ulong]
    // [1270] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_read::@27->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1270] phi printf_ulong::format_min_length#11 = 5 [phi:rom_read::@27->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1270] phi printf_ulong::putc#11 = &snputc [phi:rom_read::@27->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1270] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_read::@27->printf_ulong#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1270] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#3 [phi:rom_read::@27->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1166] phi from rom_read::@27 to rom_read::@28 [phi:rom_read::@27->rom_read::@28]
    // rom_read::@28
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1167] call printf_str
    // [873] phi from rom_read::@28 to printf_str [phi:rom_read::@28->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:rom_read::@28->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = s2 [phi:rom_read::@28->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@29
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1168] printf_uchar::uvalue#5 = rom_read::bram_bank#10 -- vbum1=vbuz2 
    lda.z bram_bank
    sta printf_uchar.uvalue
    // [1169] call printf_uchar
    // [1035] phi from rom_read::@29 to printf_uchar [phi:rom_read::@29->printf_uchar]
    // [1035] phi printf_uchar::format_zero_padding#11 = 1 [phi:rom_read::@29->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1035] phi printf_uchar::format_min_length#11 = 2 [phi:rom_read::@29->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1035] phi printf_uchar::putc#11 = &snputc [phi:rom_read::@29->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1035] phi printf_uchar::format_radix#11 = HEXADECIMAL [phi:rom_read::@29->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1035] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#5 [phi:rom_read::@29->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1170] phi from rom_read::@29 to rom_read::@30 [phi:rom_read::@29->rom_read::@30]
    // rom_read::@30
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1171] call printf_str
    // [873] phi from rom_read::@30 to printf_str [phi:rom_read::@30->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:rom_read::@30->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = s3 [phi:rom_read::@30->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@31
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1172] printf_uint::uvalue#13 = (unsigned int)rom_read::ram_address#10 -- vwum1=vwuz2 
    lda.z ram_address
    sta printf_uint.uvalue
    lda.z ram_address+1
    sta printf_uint.uvalue+1
    // [1173] call printf_uint
    // [907] phi from rom_read::@31 to printf_uint [phi:rom_read::@31->printf_uint]
    // [907] phi printf_uint::format_zero_padding#18 = 1 [phi:rom_read::@31->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [907] phi printf_uint::format_min_length#18 = 4 [phi:rom_read::@31->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [907] phi printf_uint::putc#18 = &snputc [phi:rom_read::@31->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [907] phi printf_uint::format_radix#18 = HEXADECIMAL [phi:rom_read::@31->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [907] phi printf_uint::uvalue#18 = printf_uint::uvalue#13 [phi:rom_read::@31->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1174] phi from rom_read::@31 to rom_read::@32 [phi:rom_read::@31->rom_read::@32]
    // rom_read::@32
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1175] call printf_str
    // [873] phi from rom_read::@32 to printf_str [phi:rom_read::@32->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:rom_read::@32->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = s7 [phi:rom_read::@32->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@33
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1176] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1177] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1179] call display_action_text
    // [1046] phi from rom_read::@33 to display_action_text [phi:rom_read::@33->display_action_text]
    // [1046] phi display_action_text::info_text#19 = info_text [phi:rom_read::@33->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // rom_read::@34
    // rom_address % 0x04000
    // [1180] rom_read::$11 = rom_read::rom_address#10 & $4000-1 -- vduz1=vduz2_band_vduc1 
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
    // [1181] if(0!=rom_read::$11) goto rom_read::@5 -- 0_neq_vduz1_then_la1 
    lda.z rom_read__11
    ora.z rom_read__11+1
    ora.z rom_read__11+2
    ora.z rom_read__11+3
    bne __b5
    // rom_read::@10
    // brom_bank_start++;
    // [1182] rom_read::brom_bank_start#0 = ++ rom_read::brom_bank_start#10 -- vbuz1=_inc_vbuz1 
    inc.z brom_bank_start
    // [1183] phi from rom_read::@10 rom_read::@34 to rom_read::@5 [phi:rom_read::@10/rom_read::@34->rom_read::@5]
    // [1183] phi rom_read::brom_bank_start#20 = rom_read::brom_bank_start#0 [phi:rom_read::@10/rom_read::@34->rom_read::@5#0] -- register_copy 
    // rom_read::@5
  __b5:
    // rom_read::bank_set_bram2
    // BRAM = bank
    // [1184] BRAM = rom_read::bram_bank#10 -- vbuz1=vbuz2 
    lda.z bram_bank
    sta.z BRAM
    // rom_read::@14
    // unsigned int rom_package_read = fgets(ram_address, ROM_PROGRESS_CELL, fp)
    // [1185] fgets::ptr#3 = rom_read::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z fgets.ptr
    lda.z ram_address+1
    sta.z fgets.ptr+1
    // [1186] fgets::stream#1 = rom_read::fp#0 -- pssz1=pssm2 
    lda fp
    sta.z fgets.stream
    lda fp+1
    sta.z fgets.stream+1
    // [1187] call fgets
    // [2116] phi from rom_read::@14 to fgets [phi:rom_read::@14->fgets]
    // [2116] phi fgets::ptr#12 = fgets::ptr#3 [phi:rom_read::@14->fgets#0] -- register_copy 
    // [2116] phi fgets::size#10 = ROM_PROGRESS_CELL [phi:rom_read::@14->fgets#1] -- vwum1=vwuc1 
    lda #<ROM_PROGRESS_CELL
    sta fgets.size
    lda #>ROM_PROGRESS_CELL
    sta fgets.size+1
    // [2116] phi fgets::stream#2 = fgets::stream#1 [phi:rom_read::@14->fgets#2] -- register_copy 
    jsr fgets
    // unsigned int rom_package_read = fgets(ram_address, ROM_PROGRESS_CELL, fp)
    // [1188] fgets::return#6 = fgets::return#1
    // rom_read::@35
    // [1189] rom_read::rom_package_read#0 = fgets::return#6 -- vwuz1=vwum2 
    lda fgets.return
    sta.z rom_package_read
    lda fgets.return+1
    sta.z rom_package_read+1
    // if (!rom_package_read)
    // [1190] if(0!=rom_read::rom_package_read#0) goto rom_read::@6 -- 0_neq_vwuz1_then_la1 
    lda.z rom_package_read
    ora.z rom_package_read+1
    bne __b6
    jmp __b7
    // rom_read::@6
  __b6:
    // if (rom_row_current == ROM_PROGRESS_ROW)
    // [1191] if(rom_read::rom_row_current#10!=ROM_PROGRESS_ROW) goto rom_read::@8 -- vwuz1_neq_vwuc1_then_la1 
    lda.z rom_row_current+1
    cmp #>ROM_PROGRESS_ROW
    bne __b8
    lda.z rom_row_current
    cmp #<ROM_PROGRESS_ROW
    bne __b8
    // rom_read::@11
    // gotoxy(x, ++y);
    // [1192] rom_read::y#1 = ++ rom_read::y#11 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [1193] gotoxy::y#25 = rom_read::y#1 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [1194] call gotoxy
    // [606] phi from rom_read::@11 to gotoxy [phi:rom_read::@11->gotoxy]
    // [606] phi gotoxy::y#30 = gotoxy::y#25 [phi:rom_read::@11->gotoxy#0] -- register_copy 
    // [606] phi gotoxy::x#30 = PROGRESS_X [phi:rom_read::@11->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1195] phi from rom_read::@11 to rom_read::@8 [phi:rom_read::@11->rom_read::@8]
    // [1195] phi rom_read::y#36 = rom_read::y#1 [phi:rom_read::@11->rom_read::@8#0] -- register_copy 
    // [1195] phi rom_read::rom_row_current#4 = 0 [phi:rom_read::@11->rom_read::@8#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z rom_row_current
    sta.z rom_row_current+1
    // [1195] phi from rom_read::@6 to rom_read::@8 [phi:rom_read::@6->rom_read::@8]
    // [1195] phi rom_read::y#36 = rom_read::y#11 [phi:rom_read::@6->rom_read::@8#0] -- register_copy 
    // [1195] phi rom_read::rom_row_current#4 = rom_read::rom_row_current#10 [phi:rom_read::@6->rom_read::@8#1] -- register_copy 
    // rom_read::@8
  __b8:
    // cputc('.')
    // [1196] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [1197] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // ram_address += rom_package_read
    // [1199] rom_read::ram_address#1 = rom_read::ram_address#10 + rom_read::rom_package_read#0 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z ram_address
    adc.z rom_package_read
    sta.z ram_address
    lda.z ram_address+1
    adc.z rom_package_read+1
    sta.z ram_address+1
    // rom_address += rom_package_read
    // [1200] rom_read::rom_address#1 = rom_read::rom_address#10 + rom_read::rom_package_read#0 -- vduz1=vduz1_plus_vwuz2 
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
    // [1201] rom_read::rom_file_size#1 = rom_read::rom_file_size#11 + rom_read::rom_package_read#0 -- vduz1=vduz1_plus_vwuz2 
    lda.z rom_file_size
    clc
    adc.z rom_package_read
    sta.z rom_file_size
    lda.z rom_file_size+1
    adc.z rom_package_read+1
    sta.z rom_file_size+1
    lda.z rom_file_size+2
    adc #0
    sta.z rom_file_size+2
    lda.z rom_file_size+3
    adc #0
    sta.z rom_file_size+3
    // rom_row_current += rom_package_read
    // [1202] rom_read::rom_row_current#1 = rom_read::rom_row_current#4 + rom_read::rom_package_read#0 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z rom_row_current
    adc.z rom_package_read
    sta.z rom_row_current
    lda.z rom_row_current+1
    adc.z rom_package_read+1
    sta.z rom_row_current+1
    // if (ram_address == (ram_ptr_t)BRAM_HIGH)
    // [1203] if(rom_read::ram_address#1!=(char *)$c000) goto rom_read::@9 -- pbuz1_neq_pbuc1_then_la1 
    lda.z ram_address+1
    cmp #>$c000
    bne __b9
    lda.z ram_address
    cmp #<$c000
    bne __b9
    // rom_read::@12
    // bram_bank++;
    // [1204] rom_read::bram_bank#1 = ++ rom_read::bram_bank#10 -- vbuz1=_inc_vbuz1 
    inc.z bram_bank
    // [1205] phi from rom_read::@12 to rom_read::@9 [phi:rom_read::@12->rom_read::@9]
    // [1205] phi rom_read::bram_bank#30 = rom_read::bram_bank#1 [phi:rom_read::@12->rom_read::@9#0] -- register_copy 
    // [1205] phi rom_read::ram_address#7 = (char *)$a000 [phi:rom_read::@12->rom_read::@9#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1205] phi from rom_read::@8 to rom_read::@9 [phi:rom_read::@8->rom_read::@9]
    // [1205] phi rom_read::bram_bank#30 = rom_read::bram_bank#10 [phi:rom_read::@8->rom_read::@9#0] -- register_copy 
    // [1205] phi rom_read::ram_address#7 = rom_read::ram_address#1 [phi:rom_read::@8->rom_read::@9#1] -- register_copy 
    // rom_read::@9
  __b9:
    // if (ram_address == (ram_ptr_t)RAM_HIGH)
    // [1206] if(rom_read::ram_address#7!=(char *)$8000) goto rom_read::@36 -- pbuz1_neq_pbuc1_then_la1 
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
    // [1146] phi from rom_read::@9 to rom_read::@3 [phi:rom_read::@9->rom_read::@3]
    // [1146] phi rom_read::y#11 = rom_read::y#36 [phi:rom_read::@9->rom_read::@3#0] -- register_copy 
    // [1146] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#1 [phi:rom_read::@9->rom_read::@3#1] -- register_copy 
    // [1146] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#20 [phi:rom_read::@9->rom_read::@3#2] -- register_copy 
    // [1146] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@9->rom_read::@3#3] -- register_copy 
    // [1146] phi rom_read::ram_address#10 = (char *)$a000 [phi:rom_read::@9->rom_read::@3#4] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1146] phi rom_read::bram_bank#10 = 1 [phi:rom_read::@9->rom_read::@3#5] -- vbuz1=vbuc1 
    lda #1
    sta.z bram_bank
    // [1146] phi rom_read::rom_file_size#11 = rom_read::rom_file_size#1 [phi:rom_read::@9->rom_read::@3#6] -- register_copy 
    jmp __b3
    // [1207] phi from rom_read::@9 to rom_read::@36 [phi:rom_read::@9->rom_read::@36]
    // rom_read::@36
    // [1146] phi from rom_read::@36 to rom_read::@3 [phi:rom_read::@36->rom_read::@3]
    // [1146] phi rom_read::y#11 = rom_read::y#36 [phi:rom_read::@36->rom_read::@3#0] -- register_copy 
    // [1146] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#1 [phi:rom_read::@36->rom_read::@3#1] -- register_copy 
    // [1146] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#20 [phi:rom_read::@36->rom_read::@3#2] -- register_copy 
    // [1146] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@36->rom_read::@3#3] -- register_copy 
    // [1146] phi rom_read::ram_address#10 = rom_read::ram_address#7 [phi:rom_read::@36->rom_read::@3#4] -- register_copy 
    // [1146] phi rom_read::bram_bank#10 = rom_read::bram_bank#30 [phi:rom_read::@36->rom_read::@3#5] -- register_copy 
    // [1146] phi rom_read::rom_file_size#11 = rom_read::rom_file_size#1 [phi:rom_read::@36->rom_read::@3#6] -- register_copy 
  .segment Data
    s: .text "Opening "
    .byte 0
    s1: .text " from SD card ..."
    .byte 0
    .label fp = smc_flash.smc_bootloader_not_activated1
}
.segment Code
  // rom_verify
// __zp($72) unsigned long rom_verify(__zp($f0) char rom_chip, __mem() char rom_bank_start, __zp($3d) unsigned long file_size)
rom_verify: {
    .label rom_verify__16 = $63
    .label rom_address = $65
    .label rom_boundary = $3d
    .label equal_bytes = $63
    .label ram_address = $b9
    .label bram_bank = $f1
    .label rom_different_bytes = $72
    .label rom_chip = $f0
    .label file_size = $3d
    .label return = $72
    .label progress_row_current = $e8
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [1208] rom_address_from_bank::rom_bank#1 = rom_verify::rom_bank_start#0
    // [1209] call rom_address_from_bank
    // [2226] phi from rom_verify to rom_address_from_bank [phi:rom_verify->rom_address_from_bank]
    // [2226] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#1 [phi:rom_verify->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [1210] rom_address_from_bank::return#3 = rom_address_from_bank::return#0 -- vduz1=vduz2 
    lda.z rom_address_from_bank.return
    sta.z rom_address_from_bank.return_1
    lda.z rom_address_from_bank.return+1
    sta.z rom_address_from_bank.return_1+1
    lda.z rom_address_from_bank.return+2
    sta.z rom_address_from_bank.return_1+2
    lda.z rom_address_from_bank.return+3
    sta.z rom_address_from_bank.return_1+3
    // rom_verify::@11
    // [1211] rom_verify::rom_address#0 = rom_address_from_bank::return#3
    // unsigned long rom_boundary = rom_address + file_size
    // [1212] rom_verify::rom_boundary#0 = rom_verify::rom_address#0 + rom_verify::file_size#0 -- vduz1=vduz2_plus_vduz1 
    clc
    lda.z rom_boundary
    adc.z rom_address
    sta.z rom_boundary
    lda.z rom_boundary+1
    adc.z rom_address+1
    sta.z rom_boundary+1
    lda.z rom_boundary+2
    adc.z rom_address+2
    sta.z rom_boundary+2
    lda.z rom_boundary+3
    adc.z rom_address+3
    sta.z rom_boundary+3
    // display_info_rom(rom_chip, STATUS_COMPARING, "Comparing ...")
    // [1213] display_info_rom::rom_chip#1 = rom_verify::rom_chip#0
    // [1214] call display_info_rom
    // [1069] phi from rom_verify::@11 to display_info_rom [phi:rom_verify::@11->display_info_rom]
    // [1069] phi display_info_rom::info_text#17 = rom_verify::info_text [phi:rom_verify::@11->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_rom.info_text
    lda #>info_text
    sta.z display_info_rom.info_text+1
    // [1069] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#1 [phi:rom_verify::@11->display_info_rom#1] -- register_copy 
    // [1069] phi display_info_rom::info_status#17 = STATUS_COMPARING [phi:rom_verify::@11->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_COMPARING
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // [1215] phi from rom_verify::@11 to rom_verify::@12 [phi:rom_verify::@11->rom_verify::@12]
    // rom_verify::@12
    // gotoxy(x, y)
    // [1216] call gotoxy
    // [606] phi from rom_verify::@12 to gotoxy [phi:rom_verify::@12->gotoxy]
    // [606] phi gotoxy::y#30 = PROGRESS_Y [phi:rom_verify::@12->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [606] phi gotoxy::x#30 = PROGRESS_X [phi:rom_verify::@12->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1217] phi from rom_verify::@12 to rom_verify::@1 [phi:rom_verify::@12->rom_verify::@1]
    // [1217] phi rom_verify::y#3 = PROGRESS_Y [phi:rom_verify::@12->rom_verify::@1#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1217] phi rom_verify::progress_row_current#3 = 0 [phi:rom_verify::@12->rom_verify::@1#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z progress_row_current
    sta.z progress_row_current+1
    // [1217] phi rom_verify::rom_different_bytes#11 = 0 [phi:rom_verify::@12->rom_verify::@1#2] -- vduz1=vduc1 
    sta.z rom_different_bytes
    sta.z rom_different_bytes+1
    lda #<0>>$10
    sta.z rom_different_bytes+2
    lda #>0>>$10
    sta.z rom_different_bytes+3
    // [1217] phi rom_verify::ram_address#10 = (char *)$6000 [phi:rom_verify::@12->rom_verify::@1#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z ram_address
    lda #>$6000
    sta.z ram_address+1
    // [1217] phi rom_verify::bram_bank#11 = 0 [phi:rom_verify::@12->rom_verify::@1#4] -- vbuz1=vbuc1 
    lda #0
    sta.z bram_bank
    // [1217] phi rom_verify::rom_address#12 = rom_verify::rom_address#0 [phi:rom_verify::@12->rom_verify::@1#5] -- register_copy 
    // rom_verify::@1
  __b1:
    // while (rom_address < rom_boundary)
    // [1218] if(rom_verify::rom_address#12<rom_verify::rom_boundary#0) goto rom_verify::@2 -- vduz1_lt_vduz2_then_la1 
    lda.z rom_address+3
    cmp.z rom_boundary+3
    bcc __b2
    bne !+
    lda.z rom_address+2
    cmp.z rom_boundary+2
    bcc __b2
    bne !+
    lda.z rom_address+1
    cmp.z rom_boundary+1
    bcc __b2
    bne !+
    lda.z rom_address
    cmp.z rom_boundary
    bcc __b2
  !:
    // rom_verify::@return
    // }
    // [1219] return 
    rts
    // rom_verify::@2
  __b2:
    // unsigned int equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1220] rom_compare::bank_ram#0 = rom_verify::bram_bank#11
    // [1221] rom_compare::ptr_ram#1 = rom_verify::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_compare.ptr_ram
    lda.z ram_address+1
    sta.z rom_compare.ptr_ram+1
    // [1222] rom_compare::rom_compare_address#0 = rom_verify::rom_address#12 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_compare.rom_compare_address
    lda.z rom_address+1
    sta.z rom_compare.rom_compare_address+1
    lda.z rom_address+2
    sta.z rom_compare.rom_compare_address+2
    lda.z rom_address+3
    sta.z rom_compare.rom_compare_address+3
    // [1223] call rom_compare
  // {asm{.byte $db}}
    // [2230] phi from rom_verify::@2 to rom_compare [phi:rom_verify::@2->rom_compare]
    // [2230] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#1 [phi:rom_verify::@2->rom_compare#0] -- register_copy 
    // [2230] phi rom_compare::rom_compare_size#11 = ROM_PROGRESS_CELL [phi:rom_verify::@2->rom_compare#1] -- vwuz1=vwuc1 
    lda #<ROM_PROGRESS_CELL
    sta.z rom_compare.rom_compare_size
    lda #>ROM_PROGRESS_CELL
    sta.z rom_compare.rom_compare_size+1
    // [2230] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#0 [phi:rom_verify::@2->rom_compare#2] -- register_copy 
    // [2230] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#0 [phi:rom_verify::@2->rom_compare#3] -- vbum1=vbuz2 
    lda.z rom_compare.bank_ram
    sta rom_compare.bank_set_bram1_bank
    jsr rom_compare
    // unsigned int equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1224] rom_compare::return#2 = rom_compare::equal_bytes#2
    // rom_verify::@13
    // [1225] rom_verify::equal_bytes#0 = rom_compare::return#2
    // if (progress_row_current == ROM_PROGRESS_ROW)
    // [1226] if(rom_verify::progress_row_current#3!=ROM_PROGRESS_ROW) goto rom_verify::@3 -- vwuz1_neq_vwuc1_then_la1 
    lda.z progress_row_current+1
    cmp #>ROM_PROGRESS_ROW
    bne __b3
    lda.z progress_row_current
    cmp #<ROM_PROGRESS_ROW
    bne __b3
    // rom_verify::@8
    // gotoxy(x, ++y);
    // [1227] rom_verify::y#1 = ++ rom_verify::y#3 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [1228] gotoxy::y#27 = rom_verify::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1229] call gotoxy
    // [606] phi from rom_verify::@8 to gotoxy [phi:rom_verify::@8->gotoxy]
    // [606] phi gotoxy::y#30 = gotoxy::y#27 [phi:rom_verify::@8->gotoxy#0] -- register_copy 
    // [606] phi gotoxy::x#30 = PROGRESS_X [phi:rom_verify::@8->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1230] phi from rom_verify::@8 to rom_verify::@3 [phi:rom_verify::@8->rom_verify::@3]
    // [1230] phi rom_verify::y#10 = rom_verify::y#1 [phi:rom_verify::@8->rom_verify::@3#0] -- register_copy 
    // [1230] phi rom_verify::progress_row_current#4 = 0 [phi:rom_verify::@8->rom_verify::@3#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z progress_row_current
    sta.z progress_row_current+1
    // [1230] phi from rom_verify::@13 to rom_verify::@3 [phi:rom_verify::@13->rom_verify::@3]
    // [1230] phi rom_verify::y#10 = rom_verify::y#3 [phi:rom_verify::@13->rom_verify::@3#0] -- register_copy 
    // [1230] phi rom_verify::progress_row_current#4 = rom_verify::progress_row_current#3 [phi:rom_verify::@13->rom_verify::@3#1] -- register_copy 
    // rom_verify::@3
  __b3:
    // if (equal_bytes != ROM_PROGRESS_CELL)
    // [1231] if(rom_verify::equal_bytes#0!=ROM_PROGRESS_CELL) goto rom_verify::@4 -- vwuz1_neq_vwuc1_then_la1 
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
    // [1232] stackpush(char) = '=' -- _stackpushbyte_=vbuc1 
    lda #'='
    pha
    // [1233] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // rom_verify::@5
  __b5:
    // ram_address += ROM_PROGRESS_CELL
    // [1235] rom_verify::ram_address#1 = rom_verify::ram_address#10 + ROM_PROGRESS_CELL -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address
    clc
    adc #<ROM_PROGRESS_CELL
    sta.z ram_address
    lda.z ram_address+1
    adc #>ROM_PROGRESS_CELL
    sta.z ram_address+1
    // rom_address += ROM_PROGRESS_CELL
    // [1236] rom_verify::rom_address#1 = rom_verify::rom_address#12 + ROM_PROGRESS_CELL -- vduz1=vduz1_plus_vwuc1 
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
    // [1237] rom_verify::progress_row_current#11 = rom_verify::progress_row_current#4 + ROM_PROGRESS_CELL -- vwuz1=vwuz1_plus_vwuc1 
    lda.z progress_row_current
    clc
    adc #<ROM_PROGRESS_CELL
    sta.z progress_row_current
    lda.z progress_row_current+1
    adc #>ROM_PROGRESS_CELL
    sta.z progress_row_current+1
    // if (ram_address == BRAM_HIGH)
    // [1238] if(rom_verify::ram_address#1!=$c000) goto rom_verify::@6 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address+1
    cmp #>$c000
    bne __b6
    lda.z ram_address
    cmp #<$c000
    bne __b6
    // rom_verify::@10
    // bram_bank++;
    // [1239] rom_verify::bram_bank#1 = ++ rom_verify::bram_bank#11 -- vbuz1=_inc_vbuz1 
    inc.z bram_bank
    // [1240] phi from rom_verify::@10 to rom_verify::@6 [phi:rom_verify::@10->rom_verify::@6]
    // [1240] phi rom_verify::bram_bank#24 = rom_verify::bram_bank#1 [phi:rom_verify::@10->rom_verify::@6#0] -- register_copy 
    // [1240] phi rom_verify::ram_address#6 = (char *)$a000 [phi:rom_verify::@10->rom_verify::@6#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1240] phi from rom_verify::@5 to rom_verify::@6 [phi:rom_verify::@5->rom_verify::@6]
    // [1240] phi rom_verify::bram_bank#24 = rom_verify::bram_bank#11 [phi:rom_verify::@5->rom_verify::@6#0] -- register_copy 
    // [1240] phi rom_verify::ram_address#6 = rom_verify::ram_address#1 [phi:rom_verify::@5->rom_verify::@6#1] -- register_copy 
    // rom_verify::@6
  __b6:
    // if (ram_address == RAM_HIGH)
    // [1241] if(rom_verify::ram_address#6!=$8000) goto rom_verify::@23 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address+1
    cmp #>$8000
    bne __b7
    lda.z ram_address
    cmp #<$8000
    bne __b7
    // [1243] phi from rom_verify::@6 to rom_verify::@7 [phi:rom_verify::@6->rom_verify::@7]
    // [1243] phi rom_verify::ram_address#11 = (char *)$a000 [phi:rom_verify::@6->rom_verify::@7#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1243] phi rom_verify::bram_bank#10 = 1 [phi:rom_verify::@6->rom_verify::@7#1] -- vbuz1=vbuc1 
    lda #1
    sta.z bram_bank
    // [1242] phi from rom_verify::@6 to rom_verify::@23 [phi:rom_verify::@6->rom_verify::@23]
    // rom_verify::@23
    // [1243] phi from rom_verify::@23 to rom_verify::@7 [phi:rom_verify::@23->rom_verify::@7]
    // [1243] phi rom_verify::ram_address#11 = rom_verify::ram_address#6 [phi:rom_verify::@23->rom_verify::@7#0] -- register_copy 
    // [1243] phi rom_verify::bram_bank#10 = rom_verify::bram_bank#24 [phi:rom_verify::@23->rom_verify::@7#1] -- register_copy 
    // rom_verify::@7
  __b7:
    // ROM_PROGRESS_CELL - equal_bytes
    // [1244] rom_verify::$16 = ROM_PROGRESS_CELL - rom_verify::equal_bytes#0 -- vwuz1=vwuc1_minus_vwuz1 
    lda #<ROM_PROGRESS_CELL
    sec
    sbc.z rom_verify__16
    sta.z rom_verify__16
    lda #>ROM_PROGRESS_CELL
    sbc.z rom_verify__16+1
    sta.z rom_verify__16+1
    // rom_different_bytes += (ROM_PROGRESS_CELL - equal_bytes)
    // [1245] rom_verify::rom_different_bytes#1 = rom_verify::rom_different_bytes#11 + rom_verify::$16 -- vduz1=vduz1_plus_vwuz2 
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
    // [1246] call snprintf_init
    // [868] phi from rom_verify::@7 to snprintf_init [phi:rom_verify::@7->snprintf_init]
    // [868] phi snprintf_init::s#25 = info_text [phi:rom_verify::@7->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1247] phi from rom_verify::@7 to rom_verify::@14 [phi:rom_verify::@7->rom_verify::@14]
    // rom_verify::@14
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1248] call printf_str
    // [873] phi from rom_verify::@14 to printf_str [phi:rom_verify::@14->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:rom_verify::@14->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = rom_verify::s [phi:rom_verify::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@15
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1249] printf_ulong::uvalue#4 = rom_verify::rom_different_bytes#1 -- vdum1=vduz2 
    lda.z rom_different_bytes
    sta printf_ulong.uvalue
    lda.z rom_different_bytes+1
    sta printf_ulong.uvalue+1
    lda.z rom_different_bytes+2
    sta printf_ulong.uvalue+2
    lda.z rom_different_bytes+3
    sta printf_ulong.uvalue+3
    // [1250] call printf_ulong
    // [1270] phi from rom_verify::@15 to printf_ulong [phi:rom_verify::@15->printf_ulong]
    // [1270] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_verify::@15->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1270] phi printf_ulong::format_min_length#11 = 5 [phi:rom_verify::@15->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1270] phi printf_ulong::putc#11 = &snputc [phi:rom_verify::@15->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1270] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_verify::@15->printf_ulong#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1270] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#4 [phi:rom_verify::@15->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1251] phi from rom_verify::@15 to rom_verify::@16 [phi:rom_verify::@15->rom_verify::@16]
    // rom_verify::@16
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1252] call printf_str
    // [873] phi from rom_verify::@16 to printf_str [phi:rom_verify::@16->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:rom_verify::@16->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = rom_verify::s1 [phi:rom_verify::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@17
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1253] printf_uchar::uvalue#6 = rom_verify::bram_bank#10 -- vbum1=vbuz2 
    lda.z bram_bank
    sta printf_uchar.uvalue
    // [1254] call printf_uchar
    // [1035] phi from rom_verify::@17 to printf_uchar [phi:rom_verify::@17->printf_uchar]
    // [1035] phi printf_uchar::format_zero_padding#11 = 1 [phi:rom_verify::@17->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1035] phi printf_uchar::format_min_length#11 = 2 [phi:rom_verify::@17->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1035] phi printf_uchar::putc#11 = &snputc [phi:rom_verify::@17->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1035] phi printf_uchar::format_radix#11 = HEXADECIMAL [phi:rom_verify::@17->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1035] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#6 [phi:rom_verify::@17->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1255] phi from rom_verify::@17 to rom_verify::@18 [phi:rom_verify::@17->rom_verify::@18]
    // rom_verify::@18
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1256] call printf_str
    // [873] phi from rom_verify::@18 to printf_str [phi:rom_verify::@18->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:rom_verify::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = s3 [phi:rom_verify::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s3
    sta.z printf_str.s
    lda #>@s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@19
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1257] printf_uint::uvalue#14 = (unsigned int)rom_verify::ram_address#11 -- vwum1=vwuz2 
    lda.z ram_address
    sta printf_uint.uvalue
    lda.z ram_address+1
    sta printf_uint.uvalue+1
    // [1258] call printf_uint
    // [907] phi from rom_verify::@19 to printf_uint [phi:rom_verify::@19->printf_uint]
    // [907] phi printf_uint::format_zero_padding#18 = 1 [phi:rom_verify::@19->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [907] phi printf_uint::format_min_length#18 = 4 [phi:rom_verify::@19->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [907] phi printf_uint::putc#18 = &snputc [phi:rom_verify::@19->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [907] phi printf_uint::format_radix#18 = HEXADECIMAL [phi:rom_verify::@19->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [907] phi printf_uint::uvalue#18 = printf_uint::uvalue#14 [phi:rom_verify::@19->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1259] phi from rom_verify::@19 to rom_verify::@20 [phi:rom_verify::@19->rom_verify::@20]
    // rom_verify::@20
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1260] call printf_str
    // [873] phi from rom_verify::@20 to printf_str [phi:rom_verify::@20->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:rom_verify::@20->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = rom_verify::s3 [phi:rom_verify::@20->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@21
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1261] printf_ulong::uvalue#5 = rom_verify::rom_address#1 -- vdum1=vduz2 
    lda.z rom_address
    sta printf_ulong.uvalue
    lda.z rom_address+1
    sta printf_ulong.uvalue+1
    lda.z rom_address+2
    sta printf_ulong.uvalue+2
    lda.z rom_address+3
    sta printf_ulong.uvalue+3
    // [1262] call printf_ulong
    // [1270] phi from rom_verify::@21 to printf_ulong [phi:rom_verify::@21->printf_ulong]
    // [1270] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_verify::@21->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1270] phi printf_ulong::format_min_length#11 = 5 [phi:rom_verify::@21->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1270] phi printf_ulong::putc#11 = &snputc [phi:rom_verify::@21->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1270] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_verify::@21->printf_ulong#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1270] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#5 [phi:rom_verify::@21->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // rom_verify::@22
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1263] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1264] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1266] call display_action_text
    // [1046] phi from rom_verify::@22 to display_action_text [phi:rom_verify::@22->display_action_text]
    // [1046] phi display_action_text::info_text#19 = info_text [phi:rom_verify::@22->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1217] phi from rom_verify::@22 to rom_verify::@1 [phi:rom_verify::@22->rom_verify::@1]
    // [1217] phi rom_verify::y#3 = rom_verify::y#10 [phi:rom_verify::@22->rom_verify::@1#0] -- register_copy 
    // [1217] phi rom_verify::progress_row_current#3 = rom_verify::progress_row_current#11 [phi:rom_verify::@22->rom_verify::@1#1] -- register_copy 
    // [1217] phi rom_verify::rom_different_bytes#11 = rom_verify::rom_different_bytes#1 [phi:rom_verify::@22->rom_verify::@1#2] -- register_copy 
    // [1217] phi rom_verify::ram_address#10 = rom_verify::ram_address#11 [phi:rom_verify::@22->rom_verify::@1#3] -- register_copy 
    // [1217] phi rom_verify::bram_bank#11 = rom_verify::bram_bank#10 [phi:rom_verify::@22->rom_verify::@1#4] -- register_copy 
    // [1217] phi rom_verify::rom_address#12 = rom_verify::rom_address#1 [phi:rom_verify::@22->rom_verify::@1#5] -- register_copy 
    jmp __b1
    // rom_verify::@4
  __b4:
    // cputc('*')
    // [1267] stackpush(char) = '*' -- _stackpushbyte_=vbuc1 
    lda #'*'
    pha
    // [1268] callexecute cputc  -- call_vprc1 
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
    .label y = main.check_status_smc3_main__0
    .label rom_bank_start = smc_detect.smc_detect__1
}
.segment Code
  // printf_ulong
// Print an unsigned int using a specific format
// void printf_ulong(__zp($b5) void (*putc)(char), __mem() unsigned long uvalue, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, __mem() char format_radix)
printf_ulong: {
    .label putc = $b5
    // printf_ulong::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1271] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // ultoa(uvalue, printf_buffer.digits, format.radix)
    // [1272] ultoa::value#1 = printf_ulong::uvalue#11
    // [1273] ultoa::radix#0 = printf_ulong::format_radix#11
    // [1274] call ultoa
    // Format number into buffer
    jsr ultoa
    // printf_ulong::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1275] printf_number_buffer::putc#0 = printf_ulong::putc#11
    // [1276] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [1277] printf_number_buffer::format_min_length#0 = printf_ulong::format_min_length#11
    // [1278] printf_number_buffer::format_zero_padding#0 = printf_ulong::format_zero_padding#11
    // [1279] call printf_number_buffer
  // Print using format
    // [1982] phi from printf_ulong::@2 to printf_number_buffer [phi:printf_ulong::@2->printf_number_buffer]
    // [1982] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#0 [phi:printf_ulong::@2->printf_number_buffer#0] -- register_copy 
    // [1982] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_ulong::@2->printf_number_buffer#1] -- register_copy 
    // [1982] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#0 [phi:printf_ulong::@2->printf_number_buffer#2] -- register_copy 
    // [1982] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#0 [phi:printf_ulong::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_ulong::@return
    // }
    // [1280] return 
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
// __zp($f6) unsigned long rom_flash(__mem() char rom_chip, __mem() char rom_bank_start, __mem() unsigned long file_size)
rom_flash: {
    .label rom_flash__29 = $5f
    .label equal_bytes = $63
    .label ram_address_sector = $b3
    .label equal_bytes_1 = $d6
    .label retries = $ea
    .label flash_errors_sector = $ca
    .label ram_address = $7a
    .label rom_address = $d1
    .label x = $cf
    .label flash_errors = $f6
    .label bram_bank_sector = $d5
    .label y_sector = $ec
    .label return = $f6
    // display_action_progress("Flashing ... (-) equal, (+) flashed, (!) error.")
    // [1282] call display_action_progress
  // Now we compare the RAM with the actual ROM contents.
    // [700] phi from rom_flash to display_action_progress [phi:rom_flash->display_action_progress]
    // [700] phi display_action_progress::info_text#14 = rom_flash::info_text [phi:rom_flash->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // rom_flash::@19
    // unsigned long rom_address_sector = rom_address_from_bank(rom_bank_start)
    // [1283] rom_address_from_bank::rom_bank#2 = rom_flash::rom_bank_start#0
    // [1284] call rom_address_from_bank
    // [2226] phi from rom_flash::@19 to rom_address_from_bank [phi:rom_flash::@19->rom_address_from_bank]
    // [2226] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#2 [phi:rom_flash::@19->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address_sector = rom_address_from_bank(rom_bank_start)
    // [1285] rom_address_from_bank::return#4 = rom_address_from_bank::return#0 -- vdum1=vduz2 
    lda.z rom_address_from_bank.return
    sta rom_address_from_bank.return_2
    lda.z rom_address_from_bank.return+1
    sta rom_address_from_bank.return_2+1
    lda.z rom_address_from_bank.return+2
    sta rom_address_from_bank.return_2+2
    lda.z rom_address_from_bank.return+3
    sta rom_address_from_bank.return_2+3
    // rom_flash::@20
    // [1286] rom_flash::rom_address_sector#0 = rom_address_from_bank::return#4
    // unsigned long rom_boundary = rom_address_sector + file_size
    // [1287] rom_flash::rom_boundary#0 = rom_flash::rom_address_sector#0 + rom_flash::file_size#0 -- vdum1=vdum2_plus_vdum3 
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
    // [1288] display_info_rom::rom_chip#2 = rom_flash::rom_chip#0 -- vbuz1=vbum2 
    lda rom_chip
    sta.z display_info_rom.rom_chip
    // [1289] call display_info_rom
    // [1069] phi from rom_flash::@20 to display_info_rom [phi:rom_flash::@20->display_info_rom]
    // [1069] phi display_info_rom::info_text#17 = rom_flash::info_text1 [phi:rom_flash::@20->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_rom.info_text
    lda #>info_text1
    sta.z display_info_rom.info_text+1
    // [1069] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#2 [phi:rom_flash::@20->display_info_rom#1] -- register_copy 
    // [1069] phi display_info_rom::info_status#17 = STATUS_FLASHING [phi:rom_flash::@20->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHING
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // [1290] phi from rom_flash::@20 to rom_flash::@1 [phi:rom_flash::@20->rom_flash::@1]
    // [1290] phi rom_flash::y_sector#13 = PROGRESS_Y [phi:rom_flash::@20->rom_flash::@1#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y_sector
    // [1290] phi rom_flash::x_sector#10 = PROGRESS_X [phi:rom_flash::@20->rom_flash::@1#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [1290] phi rom_flash::flash_errors#10 = 0 [phi:rom_flash::@20->rom_flash::@1#2] -- vduz1=vduc1 
    lda #<0
    sta.z flash_errors
    sta.z flash_errors+1
    lda #<0>>$10
    sta.z flash_errors+2
    lda #>0>>$10
    sta.z flash_errors+3
    // [1290] phi rom_flash::ram_address_sector#11 = (char *)$6000 [phi:rom_flash::@20->rom_flash::@1#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z ram_address_sector
    lda #>$6000
    sta.z ram_address_sector+1
    // [1290] phi rom_flash::bram_bank_sector#14 = 0 [phi:rom_flash::@20->rom_flash::@1#4] -- vbuz1=vbuc1 
    lda #0
    sta.z bram_bank_sector
    // [1290] phi rom_flash::rom_address_sector#12 = rom_flash::rom_address_sector#0 [phi:rom_flash::@20->rom_flash::@1#5] -- register_copy 
    // rom_flash::@1
  __b1:
    // while (rom_address_sector < rom_boundary)
    // [1291] if(rom_flash::rom_address_sector#12<rom_flash::rom_boundary#0) goto rom_flash::@2 -- vdum1_lt_vdum2_then_la1 
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
    // [1292] phi from rom_flash::@1 to rom_flash::@3 [phi:rom_flash::@1->rom_flash::@3]
    // rom_flash::@3
    // display_action_text("Flashed ...")
    // [1293] call display_action_text
    // [1046] phi from rom_flash::@3 to display_action_text [phi:rom_flash::@3->display_action_text]
    // [1046] phi display_action_text::info_text#19 = rom_flash::info_text2 [phi:rom_flash::@3->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z display_action_text.info_text
    lda #>info_text2
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // rom_flash::@return
    // }
    // [1294] return 
    rts
    // rom_flash::@2
  __b2:
    // unsigned int equal_bytes = rom_compare(bram_bank_sector, (ram_ptr_t)ram_address_sector, rom_address_sector, ROM_SECTOR)
    // [1295] rom_compare::bank_ram#1 = rom_flash::bram_bank_sector#14
    // [1296] rom_compare::ptr_ram#2 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z rom_compare.ptr_ram
    lda.z ram_address_sector+1
    sta.z rom_compare.ptr_ram+1
    // [1297] rom_compare::rom_compare_address#1 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_compare.rom_compare_address
    lda rom_address_sector+1
    sta.z rom_compare.rom_compare_address+1
    lda rom_address_sector+2
    sta.z rom_compare.rom_compare_address+2
    lda rom_address_sector+3
    sta.z rom_compare.rom_compare_address+3
    // [1298] call rom_compare
  // {asm{.byte $db}}
    // [2230] phi from rom_flash::@2 to rom_compare [phi:rom_flash::@2->rom_compare]
    // [2230] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#2 [phi:rom_flash::@2->rom_compare#0] -- register_copy 
    // [2230] phi rom_compare::rom_compare_size#11 = $1000 [phi:rom_flash::@2->rom_compare#1] -- vwuz1=vwuc1 
    lda #<$1000
    sta.z rom_compare.rom_compare_size
    lda #>$1000
    sta.z rom_compare.rom_compare_size+1
    // [2230] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#1 [phi:rom_flash::@2->rom_compare#2] -- register_copy 
    // [2230] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#1 [phi:rom_flash::@2->rom_compare#3] -- vbum1=vbuz2 
    lda.z rom_compare.bank_ram_1
    sta rom_compare.bank_set_bram1_bank
    jsr rom_compare
    // unsigned int equal_bytes = rom_compare(bram_bank_sector, (ram_ptr_t)ram_address_sector, rom_address_sector, ROM_SECTOR)
    // [1299] rom_compare::return#3 = rom_compare::equal_bytes#2
    // rom_flash::@21
    // [1300] rom_flash::equal_bytes#0 = rom_compare::return#3
    // if (equal_bytes != ROM_SECTOR)
    // [1301] if(rom_flash::equal_bytes#0!=$1000) goto rom_flash::@5 -- vwuz1_neq_vwuc1_then_la1 
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
    // [1302] cputsxy::x#1 = rom_flash::x_sector#10 -- vbum1=vbum2 
    lda x_sector
    sta cputsxy.x
    // [1303] cputsxy::y#1 = rom_flash::y_sector#13 -- vbum1=vbuz2 
    lda.z y_sector
    sta cputsxy.y
    // [1304] call cputsxy
    // [693] phi from rom_flash::@16 to cputsxy [phi:rom_flash::@16->cputsxy]
    // [693] phi cputsxy::s#4 = rom_flash::s [phi:rom_flash::@16->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z cputsxy.s
    lda #>s
    sta.z cputsxy.s+1
    // [693] phi cputsxy::y#4 = cputsxy::y#1 [phi:rom_flash::@16->cputsxy#1] -- register_copy 
    // [693] phi cputsxy::x#4 = cputsxy::x#1 [phi:rom_flash::@16->cputsxy#2] -- register_copy 
    jsr cputsxy
    // [1305] phi from rom_flash::@12 rom_flash::@16 to rom_flash::@4 [phi:rom_flash::@12/rom_flash::@16->rom_flash::@4]
    // [1305] phi rom_flash::flash_errors#13 = rom_flash::flash_errors#1 [phi:rom_flash::@12/rom_flash::@16->rom_flash::@4#0] -- register_copy 
    // rom_flash::@4
  __b4:
    // ram_address_sector += ROM_SECTOR
    // [1306] rom_flash::ram_address_sector#1 = rom_flash::ram_address_sector#11 + $1000 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address_sector
    clc
    adc #<$1000
    sta.z ram_address_sector
    lda.z ram_address_sector+1
    adc #>$1000
    sta.z ram_address_sector+1
    // rom_address_sector += ROM_SECTOR
    // [1307] rom_flash::rom_address_sector#1 = rom_flash::rom_address_sector#12 + $1000 -- vdum1=vdum1_plus_vwuc1 
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
    // [1308] if(rom_flash::ram_address_sector#1!=$c000) goto rom_flash::@13 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address_sector+1
    cmp #>$c000
    bne __b13
    lda.z ram_address_sector
    cmp #<$c000
    bne __b13
    // rom_flash::@17
    // bram_bank_sector++;
    // [1309] rom_flash::bram_bank_sector#1 = ++ rom_flash::bram_bank_sector#14 -- vbuz1=_inc_vbuz1 
    inc.z bram_bank_sector
    // [1310] phi from rom_flash::@17 to rom_flash::@13 [phi:rom_flash::@17->rom_flash::@13]
    // [1310] phi rom_flash::bram_bank_sector#38 = rom_flash::bram_bank_sector#1 [phi:rom_flash::@17->rom_flash::@13#0] -- register_copy 
    // [1310] phi rom_flash::ram_address_sector#8 = (char *)$a000 [phi:rom_flash::@17->rom_flash::@13#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address_sector
    lda #>$a000
    sta.z ram_address_sector+1
    // [1310] phi from rom_flash::@4 to rom_flash::@13 [phi:rom_flash::@4->rom_flash::@13]
    // [1310] phi rom_flash::bram_bank_sector#38 = rom_flash::bram_bank_sector#14 [phi:rom_flash::@4->rom_flash::@13#0] -- register_copy 
    // [1310] phi rom_flash::ram_address_sector#8 = rom_flash::ram_address_sector#1 [phi:rom_flash::@4->rom_flash::@13#1] -- register_copy 
    // rom_flash::@13
  __b13:
    // if (ram_address_sector == RAM_HIGH)
    // [1311] if(rom_flash::ram_address_sector#8!=$8000) goto rom_flash::@44 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address_sector+1
    cmp #>$8000
    bne __b14
    lda.z ram_address_sector
    cmp #<$8000
    bne __b14
    // [1313] phi from rom_flash::@13 to rom_flash::@14 [phi:rom_flash::@13->rom_flash::@14]
    // [1313] phi rom_flash::ram_address_sector#15 = (char *)$a000 [phi:rom_flash::@13->rom_flash::@14#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address_sector
    lda #>$a000
    sta.z ram_address_sector+1
    // [1313] phi rom_flash::bram_bank_sector#12 = 1 [phi:rom_flash::@13->rom_flash::@14#1] -- vbuz1=vbuc1 
    lda #1
    sta.z bram_bank_sector
    // [1312] phi from rom_flash::@13 to rom_flash::@44 [phi:rom_flash::@13->rom_flash::@44]
    // rom_flash::@44
    // [1313] phi from rom_flash::@44 to rom_flash::@14 [phi:rom_flash::@44->rom_flash::@14]
    // [1313] phi rom_flash::ram_address_sector#15 = rom_flash::ram_address_sector#8 [phi:rom_flash::@44->rom_flash::@14#0] -- register_copy 
    // [1313] phi rom_flash::bram_bank_sector#12 = rom_flash::bram_bank_sector#38 [phi:rom_flash::@44->rom_flash::@14#1] -- register_copy 
    // rom_flash::@14
  __b14:
    // x_sector += 8
    // [1314] rom_flash::x_sector#1 = rom_flash::x_sector#10 + 8 -- vbum1=vbum1_plus_vbuc1 
    lda #8
    clc
    adc x_sector
    sta x_sector
    // rom_address_sector % ROM_PROGRESS_ROW
    // [1315] rom_flash::$29 = rom_flash::rom_address_sector#1 & ROM_PROGRESS_ROW-1 -- vduz1=vdum2_band_vduc1 
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
    // [1316] if(0!=rom_flash::$29) goto rom_flash::@15 -- 0_neq_vduz1_then_la1 
    lda.z rom_flash__29
    ora.z rom_flash__29+1
    ora.z rom_flash__29+2
    ora.z rom_flash__29+3
    bne __b15
    // rom_flash::@18
    // y_sector++;
    // [1317] rom_flash::y_sector#1 = ++ rom_flash::y_sector#13 -- vbuz1=_inc_vbuz1 
    inc.z y_sector
    // [1318] phi from rom_flash::@18 to rom_flash::@15 [phi:rom_flash::@18->rom_flash::@15]
    // [1318] phi rom_flash::y_sector#18 = rom_flash::y_sector#1 [phi:rom_flash::@18->rom_flash::@15#0] -- register_copy 
    // [1318] phi rom_flash::x_sector#20 = PROGRESS_X [phi:rom_flash::@18->rom_flash::@15#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [1318] phi from rom_flash::@14 to rom_flash::@15 [phi:rom_flash::@14->rom_flash::@15]
    // [1318] phi rom_flash::y_sector#18 = rom_flash::y_sector#13 [phi:rom_flash::@14->rom_flash::@15#0] -- register_copy 
    // [1318] phi rom_flash::x_sector#20 = rom_flash::x_sector#1 [phi:rom_flash::@14->rom_flash::@15#1] -- register_copy 
    // rom_flash::@15
  __b15:
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1319] call snprintf_init
    // [868] phi from rom_flash::@15 to snprintf_init [phi:rom_flash::@15->snprintf_init]
    // [868] phi snprintf_init::s#25 = info_text [phi:rom_flash::@15->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // rom_flash::@40
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1320] printf_ulong::uvalue#8 = rom_flash::flash_errors#13 -- vdum1=vduz2 
    lda.z flash_errors
    sta printf_ulong.uvalue
    lda.z flash_errors+1
    sta printf_ulong.uvalue+1
    lda.z flash_errors+2
    sta printf_ulong.uvalue+2
    lda.z flash_errors+3
    sta printf_ulong.uvalue+3
    // [1321] call printf_ulong
    // [1270] phi from rom_flash::@40 to printf_ulong [phi:rom_flash::@40->printf_ulong]
    // [1270] phi printf_ulong::format_zero_padding#11 = 0 [phi:rom_flash::@40->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1270] phi printf_ulong::format_min_length#11 = 0 [phi:rom_flash::@40->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1270] phi printf_ulong::putc#11 = &snputc [phi:rom_flash::@40->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1270] phi printf_ulong::format_radix#11 = DECIMAL [phi:rom_flash::@40->printf_ulong#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1270] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#8 [phi:rom_flash::@40->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1322] phi from rom_flash::@40 to rom_flash::@41 [phi:rom_flash::@40->rom_flash::@41]
    // rom_flash::@41
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1323] call printf_str
    // [873] phi from rom_flash::@41 to printf_str [phi:rom_flash::@41->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:rom_flash::@41->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = rom_flash::s6 [phi:rom_flash::@41->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@42
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1324] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1325] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_FLASHING, info_text)
    // [1327] display_info_rom::rom_chip#3 = rom_flash::rom_chip#0 -- vbuz1=vbum2 
    lda rom_chip
    sta.z display_info_rom.rom_chip
    // [1328] call display_info_rom
    // [1069] phi from rom_flash::@42 to display_info_rom [phi:rom_flash::@42->display_info_rom]
    // [1069] phi display_info_rom::info_text#17 = info_text [phi:rom_flash::@42->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1069] phi display_info_rom::rom_chip#17 = display_info_rom::rom_chip#3 [phi:rom_flash::@42->display_info_rom#1] -- register_copy 
    // [1069] phi display_info_rom::info_status#17 = STATUS_FLASHING [phi:rom_flash::@42->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHING
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // [1290] phi from rom_flash::@42 to rom_flash::@1 [phi:rom_flash::@42->rom_flash::@1]
    // [1290] phi rom_flash::y_sector#13 = rom_flash::y_sector#18 [phi:rom_flash::@42->rom_flash::@1#0] -- register_copy 
    // [1290] phi rom_flash::x_sector#10 = rom_flash::x_sector#20 [phi:rom_flash::@42->rom_flash::@1#1] -- register_copy 
    // [1290] phi rom_flash::flash_errors#10 = rom_flash::flash_errors#13 [phi:rom_flash::@42->rom_flash::@1#2] -- register_copy 
    // [1290] phi rom_flash::ram_address_sector#11 = rom_flash::ram_address_sector#15 [phi:rom_flash::@42->rom_flash::@1#3] -- register_copy 
    // [1290] phi rom_flash::bram_bank_sector#14 = rom_flash::bram_bank_sector#12 [phi:rom_flash::@42->rom_flash::@1#4] -- register_copy 
    // [1290] phi rom_flash::rom_address_sector#12 = rom_flash::rom_address_sector#1 [phi:rom_flash::@42->rom_flash::@1#5] -- register_copy 
    jmp __b1
    // [1329] phi from rom_flash::@21 to rom_flash::@5 [phi:rom_flash::@21->rom_flash::@5]
  __b3:
    // [1329] phi rom_flash::retries#12 = 0 [phi:rom_flash::@21->rom_flash::@5#0] -- vbuz1=vbuc1 
    lda #0
    sta.z retries
    // [1329] phi rom_flash::flash_errors_sector#11 = 0 [phi:rom_flash::@21->rom_flash::@5#1] -- vwuz1=vwuc1 
    sta.z flash_errors_sector
    sta.z flash_errors_sector+1
    // [1329] phi from rom_flash::@43 to rom_flash::@5 [phi:rom_flash::@43->rom_flash::@5]
    // [1329] phi rom_flash::retries#12 = rom_flash::retries#1 [phi:rom_flash::@43->rom_flash::@5#0] -- register_copy 
    // [1329] phi rom_flash::flash_errors_sector#11 = rom_flash::flash_errors_sector#10 [phi:rom_flash::@43->rom_flash::@5#1] -- register_copy 
    // rom_flash::@5
  __b5:
    // rom_sector_erase(rom_address_sector)
    // [1330] rom_sector_erase::address#0 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_sector_erase.address
    lda rom_address_sector+1
    sta.z rom_sector_erase.address+1
    lda rom_address_sector+2
    sta.z rom_sector_erase.address+2
    lda rom_address_sector+3
    sta.z rom_sector_erase.address+3
    // [1331] call rom_sector_erase
    // [2286] phi from rom_flash::@5 to rom_sector_erase [phi:rom_flash::@5->rom_sector_erase]
    jsr rom_sector_erase
    // rom_flash::@22
    // unsigned long rom_sector_boundary = rom_address_sector + ROM_SECTOR
    // [1332] rom_flash::rom_sector_boundary#0 = rom_flash::rom_address_sector#12 + $1000 -- vdum1=vdum2_plus_vwuc1 
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
    // [1333] gotoxy::x#28 = rom_flash::x_sector#10 -- vbum1=vbum2 
    lda x_sector
    sta gotoxy.x
    // [1334] gotoxy::y#28 = rom_flash::y_sector#13 -- vbum1=vbuz2 
    lda.z y_sector
    sta gotoxy.y
    // [1335] call gotoxy
    // [606] phi from rom_flash::@22 to gotoxy [phi:rom_flash::@22->gotoxy]
    // [606] phi gotoxy::y#30 = gotoxy::y#28 [phi:rom_flash::@22->gotoxy#0] -- register_copy 
    // [606] phi gotoxy::x#30 = gotoxy::x#28 [phi:rom_flash::@22->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1336] phi from rom_flash::@22 to rom_flash::@23 [phi:rom_flash::@22->rom_flash::@23]
    // rom_flash::@23
    // printf("........")
    // [1337] call printf_str
    // [873] phi from rom_flash::@23 to printf_str [phi:rom_flash::@23->printf_str]
    // [873] phi printf_str::putc#73 = &cputc [phi:rom_flash::@23->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = rom_flash::s1 [phi:rom_flash::@23->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@24
    // [1338] rom_flash::rom_address#26 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_address
    lda rom_address_sector+1
    sta.z rom_address+1
    lda rom_address_sector+2
    sta.z rom_address+2
    lda rom_address_sector+3
    sta.z rom_address+3
    // [1339] rom_flash::ram_address#26 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z ram_address
    lda.z ram_address_sector+1
    sta.z ram_address+1
    // [1340] rom_flash::x#26 = rom_flash::x_sector#10 -- vbuz1=vbum2 
    lda x_sector
    sta.z x
    // [1341] phi from rom_flash::@10 rom_flash::@24 to rom_flash::@6 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6]
    // [1341] phi rom_flash::x#10 = rom_flash::x#1 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#0] -- register_copy 
    // [1341] phi rom_flash::ram_address#10 = rom_flash::ram_address#1 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#1] -- register_copy 
    // [1341] phi rom_flash::flash_errors_sector#10 = rom_flash::flash_errors_sector#8 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#2] -- register_copy 
    // [1341] phi rom_flash::rom_address#11 = rom_flash::rom_address#1 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#3] -- register_copy 
    // rom_flash::@6
  __b6:
    // while (rom_address < rom_sector_boundary)
    // [1342] if(rom_flash::rom_address#11<rom_flash::rom_sector_boundary#0) goto rom_flash::@7 -- vduz1_lt_vdum2_then_la1 
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
    // [1343] rom_flash::retries#1 = ++ rom_flash::retries#12 -- vbuz1=_inc_vbuz1 
    inc.z retries
    // while (flash_errors_sector && retries <= 3)
    // [1344] if(0==rom_flash::flash_errors_sector#10) goto rom_flash::@12 -- 0_eq_vwuz1_then_la1 
    lda.z flash_errors_sector
    ora.z flash_errors_sector+1
    beq __b12
    // rom_flash::@43
    // [1345] if(rom_flash::retries#1<3+1) goto rom_flash::@5 -- vbuz1_lt_vbuc1_then_la1 
    lda.z retries
    cmp #3+1
    bcs !__b5+
    jmp __b5
  !__b5:
    // rom_flash::@12
  __b12:
    // flash_errors += flash_errors_sector
    // [1346] rom_flash::flash_errors#1 = rom_flash::flash_errors#10 + rom_flash::flash_errors_sector#10 -- vduz1=vduz1_plus_vwuz2 
    lda.z flash_errors
    clc
    adc.z flash_errors_sector
    sta.z flash_errors
    lda.z flash_errors+1
    adc.z flash_errors_sector+1
    sta.z flash_errors+1
    lda.z flash_errors+2
    adc #0
    sta.z flash_errors+2
    lda.z flash_errors+3
    adc #0
    sta.z flash_errors+3
    jmp __b4
    // rom_flash::@7
  __b7:
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1347] printf_ulong::uvalue#7 = rom_flash::flash_errors_sector#10 + rom_flash::flash_errors#10 -- vdum1=vwuz2_plus_vduz3 
    lda.z flash_errors
    clc
    adc.z flash_errors_sector
    sta printf_ulong.uvalue_1
    lda.z flash_errors+1
    adc.z flash_errors_sector+1
    sta printf_ulong.uvalue_1+1
    lda.z flash_errors+2
    adc #0
    sta printf_ulong.uvalue_1+2
    lda.z flash_errors+3
    adc #0
    sta printf_ulong.uvalue_1+3
    // [1348] call snprintf_init
    // [868] phi from rom_flash::@7 to snprintf_init [phi:rom_flash::@7->snprintf_init]
    // [868] phi snprintf_init::s#25 = info_text [phi:rom_flash::@7->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1349] phi from rom_flash::@7 to rom_flash::@25 [phi:rom_flash::@7->rom_flash::@25]
    // rom_flash::@25
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1350] call printf_str
    // [873] phi from rom_flash::@25 to printf_str [phi:rom_flash::@25->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:rom_flash::@25->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = rom_flash::s2 [phi:rom_flash::@25->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@26
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1351] printf_uchar::uvalue#7 = rom_flash::bram_bank_sector#14 -- vbum1=vbuz2 
    lda.z bram_bank_sector
    sta printf_uchar.uvalue
    // [1352] call printf_uchar
    // [1035] phi from rom_flash::@26 to printf_uchar [phi:rom_flash::@26->printf_uchar]
    // [1035] phi printf_uchar::format_zero_padding#11 = 1 [phi:rom_flash::@26->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1035] phi printf_uchar::format_min_length#11 = 2 [phi:rom_flash::@26->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1035] phi printf_uchar::putc#11 = &snputc [phi:rom_flash::@26->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1035] phi printf_uchar::format_radix#11 = HEXADECIMAL [phi:rom_flash::@26->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1035] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#7 [phi:rom_flash::@26->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1353] phi from rom_flash::@26 to rom_flash::@27 [phi:rom_flash::@26->rom_flash::@27]
    // rom_flash::@27
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1354] call printf_str
    // [873] phi from rom_flash::@27 to printf_str [phi:rom_flash::@27->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:rom_flash::@27->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = s3 [phi:rom_flash::@27->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@28
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1355] printf_uint::uvalue#15 = (unsigned int)rom_flash::ram_address_sector#11 -- vwum1=vwuz2 
    lda.z ram_address_sector
    sta printf_uint.uvalue
    lda.z ram_address_sector+1
    sta printf_uint.uvalue+1
    // [1356] call printf_uint
    // [907] phi from rom_flash::@28 to printf_uint [phi:rom_flash::@28->printf_uint]
    // [907] phi printf_uint::format_zero_padding#18 = 1 [phi:rom_flash::@28->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [907] phi printf_uint::format_min_length#18 = 4 [phi:rom_flash::@28->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [907] phi printf_uint::putc#18 = &snputc [phi:rom_flash::@28->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [907] phi printf_uint::format_radix#18 = HEXADECIMAL [phi:rom_flash::@28->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [907] phi printf_uint::uvalue#18 = printf_uint::uvalue#15 [phi:rom_flash::@28->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1357] phi from rom_flash::@28 to rom_flash::@29 [phi:rom_flash::@28->rom_flash::@29]
    // rom_flash::@29
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1358] call printf_str
    // [873] phi from rom_flash::@29 to printf_str [phi:rom_flash::@29->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:rom_flash::@29->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = rom_flash::s4 [phi:rom_flash::@29->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@30
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1359] printf_ulong::uvalue#6 = rom_flash::rom_address_sector#12 -- vdum1=vdum2 
    lda rom_address_sector
    sta printf_ulong.uvalue
    lda rom_address_sector+1
    sta printf_ulong.uvalue+1
    lda rom_address_sector+2
    sta printf_ulong.uvalue+2
    lda rom_address_sector+3
    sta printf_ulong.uvalue+3
    // [1360] call printf_ulong
    // [1270] phi from rom_flash::@30 to printf_ulong [phi:rom_flash::@30->printf_ulong]
    // [1270] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_flash::@30->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1270] phi printf_ulong::format_min_length#11 = 5 [phi:rom_flash::@30->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1270] phi printf_ulong::putc#11 = &snputc [phi:rom_flash::@30->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1270] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_flash::@30->printf_ulong#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1270] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#6 [phi:rom_flash::@30->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1361] phi from rom_flash::@30 to rom_flash::@31 [phi:rom_flash::@30->rom_flash::@31]
    // rom_flash::@31
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1362] call printf_str
    // [873] phi from rom_flash::@31 to printf_str [phi:rom_flash::@31->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:rom_flash::@31->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = rom_flash::s5 [phi:rom_flash::@31->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@32
    // [1363] printf_ulong::uvalue#20 = printf_ulong::uvalue#7 -- vdum1=vdum2 
    lda printf_ulong.uvalue_1
    sta printf_ulong.uvalue
    lda printf_ulong.uvalue_1+1
    sta printf_ulong.uvalue+1
    lda printf_ulong.uvalue_1+2
    sta printf_ulong.uvalue+2
    lda printf_ulong.uvalue_1+3
    sta printf_ulong.uvalue+3
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1364] call printf_ulong
    // [1270] phi from rom_flash::@32 to printf_ulong [phi:rom_flash::@32->printf_ulong]
    // [1270] phi printf_ulong::format_zero_padding#11 = 0 [phi:rom_flash::@32->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1270] phi printf_ulong::format_min_length#11 = 0 [phi:rom_flash::@32->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1270] phi printf_ulong::putc#11 = &snputc [phi:rom_flash::@32->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1270] phi printf_ulong::format_radix#11 = DECIMAL [phi:rom_flash::@32->printf_ulong#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1270] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#20 [phi:rom_flash::@32->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1365] phi from rom_flash::@32 to rom_flash::@33 [phi:rom_flash::@32->rom_flash::@33]
    // rom_flash::@33
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1366] call printf_str
    // [873] phi from rom_flash::@33 to printf_str [phi:rom_flash::@33->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:rom_flash::@33->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = rom_flash::s6 [phi:rom_flash::@33->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@34
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1367] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1368] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1370] call display_action_text
    // [1046] phi from rom_flash::@34 to display_action_text [phi:rom_flash::@34->display_action_text]
    // [1046] phi display_action_text::info_text#19 = info_text [phi:rom_flash::@34->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // rom_flash::@35
    // unsigned long written_bytes = rom_write(bram_bank, (ram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1371] rom_write::flash_ram_bank#0 = rom_flash::bram_bank_sector#14 -- vbuz1=vbuz2 
    lda.z bram_bank_sector
    sta.z rom_write.flash_ram_bank
    // [1372] rom_write::flash_ram_address#1 = rom_flash::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_write.flash_ram_address
    lda.z ram_address+1
    sta.z rom_write.flash_ram_address+1
    // [1373] rom_write::flash_rom_address#1 = rom_flash::rom_address#11 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_write.flash_rom_address
    lda.z rom_address+1
    sta.z rom_write.flash_rom_address+1
    lda.z rom_address+2
    sta.z rom_write.flash_rom_address+2
    lda.z rom_address+3
    sta.z rom_write.flash_rom_address+3
    // [1374] call rom_write
    jsr rom_write
    // rom_flash::@36
    // rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1375] rom_compare::bank_ram#2 = rom_flash::bram_bank_sector#14
    // [1376] rom_compare::ptr_ram#3 = rom_flash::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_compare.ptr_ram
    lda.z ram_address+1
    sta.z rom_compare.ptr_ram+1
    // [1377] rom_compare::rom_compare_address#2 = rom_flash::rom_address#11 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_compare.rom_compare_address
    lda.z rom_address+1
    sta.z rom_compare.rom_compare_address+1
    lda.z rom_address+2
    sta.z rom_compare.rom_compare_address+2
    lda.z rom_address+3
    sta.z rom_compare.rom_compare_address+3
    // [1378] call rom_compare
    // [2230] phi from rom_flash::@36 to rom_compare [phi:rom_flash::@36->rom_compare]
    // [2230] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#3 [phi:rom_flash::@36->rom_compare#0] -- register_copy 
    // [2230] phi rom_compare::rom_compare_size#11 = ROM_PROGRESS_CELL [phi:rom_flash::@36->rom_compare#1] -- vwuz1=vwuc1 
    lda #<ROM_PROGRESS_CELL
    sta.z rom_compare.rom_compare_size
    lda #>ROM_PROGRESS_CELL
    sta.z rom_compare.rom_compare_size+1
    // [2230] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#2 [phi:rom_flash::@36->rom_compare#2] -- register_copy 
    // [2230] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#2 [phi:rom_flash::@36->rom_compare#3] -- vbum1=vbuz2 
    lda.z rom_compare.bank_ram_1
    sta rom_compare.bank_set_bram1_bank
    jsr rom_compare
    // rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1379] rom_compare::return#4 = rom_compare::equal_bytes#2
    // rom_flash::@37
    // equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1380] rom_flash::equal_bytes#1 = rom_compare::return#4 -- vwuz1=vwuz2 
    lda.z rom_compare.return
    sta.z equal_bytes_1
    lda.z rom_compare.return+1
    sta.z equal_bytes_1+1
    // gotoxy(x, y)
    // [1381] gotoxy::x#29 = rom_flash::x#10 -- vbum1=vbuz2 
    lda.z x
    sta gotoxy.x
    // [1382] gotoxy::y#29 = rom_flash::y_sector#13 -- vbum1=vbuz2 
    lda.z y_sector
    sta gotoxy.y
    // [1383] call gotoxy
    // [606] phi from rom_flash::@37 to gotoxy [phi:rom_flash::@37->gotoxy]
    // [606] phi gotoxy::y#30 = gotoxy::y#29 [phi:rom_flash::@37->gotoxy#0] -- register_copy 
    // [606] phi gotoxy::x#30 = gotoxy::x#29 [phi:rom_flash::@37->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_flash::@38
    // if (equal_bytes != ROM_PROGRESS_CELL)
    // [1384] if(rom_flash::equal_bytes#1!=ROM_PROGRESS_CELL) goto rom_flash::@9 -- vwuz1_neq_vwuc1_then_la1 
    lda.z equal_bytes_1+1
    cmp #>ROM_PROGRESS_CELL
    bne __b9
    lda.z equal_bytes_1
    cmp #<ROM_PROGRESS_CELL
    bne __b9
    // rom_flash::@11
    // cputcxy(x,y,'+')
    // [1385] cputcxy::x#14 = rom_flash::x#10 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [1386] cputcxy::y#14 = rom_flash::y_sector#13 -- vbum1=vbuz2 
    lda.z y_sector
    sta cputcxy.y
    // [1387] call cputcxy
    // [1834] phi from rom_flash::@11 to cputcxy [phi:rom_flash::@11->cputcxy]
    // [1834] phi cputcxy::c#15 = '+' [phi:rom_flash::@11->cputcxy#0] -- vbum1=vbuc1 
    lda #'+'
    sta cputcxy.c
    // [1834] phi cputcxy::y#15 = cputcxy::y#14 [phi:rom_flash::@11->cputcxy#1] -- register_copy 
    // [1834] phi cputcxy::x#15 = cputcxy::x#14 [phi:rom_flash::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [1388] phi from rom_flash::@11 rom_flash::@39 to rom_flash::@10 [phi:rom_flash::@11/rom_flash::@39->rom_flash::@10]
    // [1388] phi rom_flash::flash_errors_sector#8 = rom_flash::flash_errors_sector#10 [phi:rom_flash::@11/rom_flash::@39->rom_flash::@10#0] -- register_copy 
    // rom_flash::@10
  __b10:
    // ram_address += ROM_PROGRESS_CELL
    // [1389] rom_flash::ram_address#1 = rom_flash::ram_address#10 + ROM_PROGRESS_CELL -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address
    clc
    adc #<ROM_PROGRESS_CELL
    sta.z ram_address
    lda.z ram_address+1
    adc #>ROM_PROGRESS_CELL
    sta.z ram_address+1
    // rom_address += ROM_PROGRESS_CELL
    // [1390] rom_flash::rom_address#1 = rom_flash::rom_address#11 + ROM_PROGRESS_CELL -- vduz1=vduz1_plus_vwuc1 
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
    // [1391] rom_flash::x#1 = ++ rom_flash::x#10 -- vbuz1=_inc_vbuz1 
    inc.z x
    jmp __b6
    // rom_flash::@9
  __b9:
    // cputcxy(x,y,'!')
    // [1392] cputcxy::x#13 = rom_flash::x#10 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [1393] cputcxy::y#13 = rom_flash::y_sector#13 -- vbum1=vbuz2 
    lda.z y_sector
    sta cputcxy.y
    // [1394] call cputcxy
    // [1834] phi from rom_flash::@9 to cputcxy [phi:rom_flash::@9->cputcxy]
    // [1834] phi cputcxy::c#15 = '!' [phi:rom_flash::@9->cputcxy#0] -- vbum1=vbuc1 
    lda #'!'
    sta cputcxy.c
    // [1834] phi cputcxy::y#15 = cputcxy::y#13 [phi:rom_flash::@9->cputcxy#1] -- register_copy 
    // [1834] phi cputcxy::x#15 = cputcxy::x#13 [phi:rom_flash::@9->cputcxy#2] -- register_copy 
    jsr cputcxy
    // rom_flash::@39
    // flash_errors_sector++;
    // [1395] rom_flash::flash_errors_sector#1 = ++ rom_flash::flash_errors_sector#10 -- vwuz1=_inc_vwuz1 
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
    .label rom_address_sector = main.flashed_bytes
    rom_boundary: .dword 0
    rom_sector_boundary: .dword 0
    .label x_sector = main.check_status_smc4_main__0
    .label rom_chip = smc_flash.smc_byte_upload
    .label rom_bank_start = smc_detect.smc_detect__1
    .label file_size = main.rom_flash_errors
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
// __zp($5d) unsigned int smc_flash(__zp($6e) unsigned int smc_bytes_total)
smc_flash: {
    .label smc_flash__26 = $7d
    .label smc_flash__27 = $7d
    .label return = $5d
    .label smc_bootloader_not_activated = $d6
    .label smc_ram_ptr = $70
    .label smc_bytes_checksum = $7d
    .label smc_package_flashed = $36
    .label smc_bytes_flashed = $5d
    .label smc_row_bytes = $4a
    .label smc_attempts_total = $76
    .label smc_bytes_total = $6e
    .label smc_package_committed = $7c
    // display_action_progress("To start the SMC update, do the below action ...")
    // [1397] call display_action_progress
    // [700] phi from smc_flash to display_action_progress [phi:smc_flash->display_action_progress]
    // [700] phi display_action_progress::info_text#14 = smc_flash::info_text [phi:smc_flash->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // smc_flash::@25
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [1398] smc_flash::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [1399] smc_flash::cx16_k_i2c_write_byte1_offset = $8f -- vbum1=vbuc1 
    lda #$8f
    sta cx16_k_i2c_write_byte1_offset
    // [1400] smc_flash::cx16_k_i2c_write_byte1_value = $31 -- vbum1=vbuc1 
    lda #$31
    sta cx16_k_i2c_write_byte1_value
    // smc_flash::cx16_k_i2c_write_byte1
    // unsigned char result
    // [1401] smc_flash::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
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
    // [1403] smc_flash::cx16_k_i2c_write_byte1_return#0 = smc_flash::cx16_k_i2c_write_byte1_result -- vbum1=vbum2 
    lda cx16_k_i2c_write_byte1_result
    sta cx16_k_i2c_write_byte1_return
    // smc_flash::cx16_k_i2c_write_byte1_@return
    // }
    // [1404] smc_flash::cx16_k_i2c_write_byte1_return#1 = smc_flash::cx16_k_i2c_write_byte1_return#0
    // smc_flash::@22
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [1405] smc_flash::smc_bootloader_start#0 = smc_flash::cx16_k_i2c_write_byte1_return#1 -- vbum1=vbum2 
    sta smc_bootloader_start
    // if(smc_bootloader_start)
    // [1406] if(0==smc_flash::smc_bootloader_start#0) goto smc_flash::@3 -- 0_eq_vbum1_then_la1 
    beq __b6
    // [1407] phi from smc_flash::@22 to smc_flash::@2 [phi:smc_flash::@22->smc_flash::@2]
    // smc_flash::@2
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1408] call snprintf_init
    // [868] phi from smc_flash::@2 to snprintf_init [phi:smc_flash::@2->snprintf_init]
    // [868] phi snprintf_init::s#25 = info_text [phi:smc_flash::@2->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1409] phi from smc_flash::@2 to smc_flash::@26 [phi:smc_flash::@2->smc_flash::@26]
    // smc_flash::@26
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1410] call printf_str
    // [873] phi from smc_flash::@26 to printf_str [phi:smc_flash::@26->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:smc_flash::@26->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = smc_flash::s [phi:smc_flash::@26->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@27
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1411] printf_uchar::uvalue#1 = smc_flash::smc_bootloader_start#0 -- vbum1=vbum2 
    lda smc_bootloader_start
    sta printf_uchar.uvalue
    // [1412] call printf_uchar
    // [1035] phi from smc_flash::@27 to printf_uchar [phi:smc_flash::@27->printf_uchar]
    // [1035] phi printf_uchar::format_zero_padding#11 = 0 [phi:smc_flash::@27->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1035] phi printf_uchar::format_min_length#11 = 0 [phi:smc_flash::@27->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1035] phi printf_uchar::putc#11 = &snputc [phi:smc_flash::@27->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1035] phi printf_uchar::format_radix#11 = HEXADECIMAL [phi:smc_flash::@27->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1035] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#1 [phi:smc_flash::@27->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // smc_flash::@28
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1413] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1414] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1416] call display_action_text
    // [1046] phi from smc_flash::@28 to display_action_text [phi:smc_flash::@28->display_action_text]
    // [1046] phi display_action_text::info_text#19 = info_text [phi:smc_flash::@28->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_flash::@29
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [1417] smc_flash::cx16_k_i2c_write_byte2_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte2_device
    // [1418] smc_flash::cx16_k_i2c_write_byte2_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte2_offset
    // [1419] smc_flash::cx16_k_i2c_write_byte2_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte2_value
    // smc_flash::cx16_k_i2c_write_byte2
    // unsigned char result
    // [1420] smc_flash::cx16_k_i2c_write_byte2_result = 0 -- vbum1=vbuc1 
    sta cx16_k_i2c_write_byte2_result
    // asm
    // asm { ldxdevice ldyoffset ldavalue stzresult jsrCX16_I2C_WRITE_BYTE rolresult  }
    ldx cx16_k_i2c_write_byte2_device
    ldy cx16_k_i2c_write_byte2_offset
    lda cx16_k_i2c_write_byte2_value
    stz cx16_k_i2c_write_byte2_result
    jsr CX16_I2C_WRITE_BYTE
    rol cx16_k_i2c_write_byte2_result
    // [1422] phi from smc_flash::@47 smc_flash::@59 smc_flash::cx16_k_i2c_write_byte2 to smc_flash::@return [phi:smc_flash::@47/smc_flash::@59/smc_flash::cx16_k_i2c_write_byte2->smc_flash::@return]
  __b2:
    // [1422] phi smc_flash::return#1 = 0 [phi:smc_flash::@47/smc_flash::@59/smc_flash::cx16_k_i2c_write_byte2->smc_flash::@return#0] -- vwuz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // smc_flash::@return
    // }
    // [1423] return 
    rts
    // [1424] phi from smc_flash::@22 to smc_flash::@3 [phi:smc_flash::@22->smc_flash::@3]
  __b6:
    // [1424] phi smc_flash::smc_bootloader_activation_countdown#10 = $80 [phi:smc_flash::@22->smc_flash::@3#0] -- vbum1=vbuc1 
    lda #$80
    sta smc_bootloader_activation_countdown
    // smc_flash::@3
  __b3:
    // while(smc_bootloader_activation_countdown)
    // [1425] if(0!=smc_flash::smc_bootloader_activation_countdown#10) goto smc_flash::@4 -- 0_neq_vbum1_then_la1 
    lda smc_bootloader_activation_countdown
    beq !__b4+
    jmp __b4
  !__b4:
    // [1426] phi from smc_flash::@3 smc_flash::@30 to smc_flash::@7 [phi:smc_flash::@3/smc_flash::@30->smc_flash::@7]
  __b9:
    // [1426] phi smc_flash::smc_bootloader_activation_countdown#12 = $a [phi:smc_flash::@3/smc_flash::@30->smc_flash::@7#0] -- vbum1=vbuc1 
    lda #$a
    sta smc_bootloader_activation_countdown_1
    // smc_flash::@7
  __b7:
    // while(smc_bootloader_activation_countdown)
    // [1427] if(0!=smc_flash::smc_bootloader_activation_countdown#12) goto smc_flash::@8 -- 0_neq_vbum1_then_la1 
    lda smc_bootloader_activation_countdown_1
    beq !__b8+
    jmp __b8
  !__b8:
    // smc_flash::@9
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1428] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1429] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [1430] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [1431] cx16_k_i2c_read_byte::return#15 = cx16_k_i2c_read_byte::return#1
    // smc_flash::@42
    // smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1432] smc_flash::smc_bootloader_not_activated#1 = cx16_k_i2c_read_byte::return#15 -- vwuz1=vwum2 
    lda cx16_k_i2c_read_byte.return
    sta.z smc_bootloader_not_activated
    lda cx16_k_i2c_read_byte.return+1
    sta.z smc_bootloader_not_activated+1
    // if(smc_bootloader_not_activated)
    // [1433] if(0==smc_flash::smc_bootloader_not_activated#1) goto smc_flash::@1 -- 0_eq_vwuz1_then_la1 
    lda.z smc_bootloader_not_activated
    ora.z smc_bootloader_not_activated+1
    beq __b1
    // [1434] phi from smc_flash::@42 to smc_flash::@10 [phi:smc_flash::@42->smc_flash::@10]
    // smc_flash::@10
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1435] call snprintf_init
    // [868] phi from smc_flash::@10 to snprintf_init [phi:smc_flash::@10->snprintf_init]
    // [868] phi snprintf_init::s#25 = info_text [phi:smc_flash::@10->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1436] phi from smc_flash::@10 to smc_flash::@45 [phi:smc_flash::@10->smc_flash::@45]
    // smc_flash::@45
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1437] call printf_str
    // [873] phi from smc_flash::@45 to printf_str [phi:smc_flash::@45->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:smc_flash::@45->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = smc_flash::s5 [phi:smc_flash::@45->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@46
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1438] printf_uint::uvalue#8 = smc_flash::smc_bootloader_not_activated#1 -- vwum1=vwuz2 
    lda.z smc_bootloader_not_activated
    sta printf_uint.uvalue
    lda.z smc_bootloader_not_activated+1
    sta printf_uint.uvalue+1
    // [1439] call printf_uint
    // [907] phi from smc_flash::@46 to printf_uint [phi:smc_flash::@46->printf_uint]
    // [907] phi printf_uint::format_zero_padding#18 = 0 [phi:smc_flash::@46->printf_uint#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uint.format_zero_padding
    // [907] phi printf_uint::format_min_length#18 = 0 [phi:smc_flash::@46->printf_uint#1] -- vbum1=vbuc1 
    sta printf_uint.format_min_length
    // [907] phi printf_uint::putc#18 = &snputc [phi:smc_flash::@46->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [907] phi printf_uint::format_radix#18 = HEXADECIMAL [phi:smc_flash::@46->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [907] phi printf_uint::uvalue#18 = printf_uint::uvalue#8 [phi:smc_flash::@46->printf_uint#4] -- register_copy 
    jsr printf_uint
    // smc_flash::@47
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1440] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1441] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1443] call display_action_text
    // [1046] phi from smc_flash::@47 to display_action_text [phi:smc_flash::@47->display_action_text]
    // [1046] phi display_action_text::info_text#19 = info_text [phi:smc_flash::@47->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    jmp __b2
    // [1444] phi from smc_flash::@42 to smc_flash::@1 [phi:smc_flash::@42->smc_flash::@1]
    // smc_flash::@1
  __b1:
    // display_action_progress("Updating SMC firmware ... (+) Updated")
    // [1445] call display_action_progress
    // [700] phi from smc_flash::@1 to display_action_progress [phi:smc_flash::@1->display_action_progress]
    // [700] phi display_action_progress::info_text#14 = smc_flash::info_text1 [phi:smc_flash::@1->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_action_progress.info_text
    lda #>info_text1
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1446] phi from smc_flash::@1 to smc_flash::@43 [phi:smc_flash::@1->smc_flash::@43]
    // smc_flash::@43
    // textcolor(WHITE)
    // [1447] call textcolor
    // [588] phi from smc_flash::@43 to textcolor [phi:smc_flash::@43->textcolor]
    // [588] phi textcolor::color#18 = WHITE [phi:smc_flash::@43->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [1448] phi from smc_flash::@43 to smc_flash::@44 [phi:smc_flash::@43->smc_flash::@44]
    // smc_flash::@44
    // gotoxy(x, y)
    // [1449] call gotoxy
    // [606] phi from smc_flash::@44 to gotoxy [phi:smc_flash::@44->gotoxy]
    // [606] phi gotoxy::y#30 = PROGRESS_Y [phi:smc_flash::@44->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [606] phi gotoxy::x#30 = PROGRESS_X [phi:smc_flash::@44->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1450] phi from smc_flash::@44 to smc_flash::@11 [phi:smc_flash::@44->smc_flash::@11]
    // [1450] phi smc_flash::y#31 = PROGRESS_Y [phi:smc_flash::@44->smc_flash::@11#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1450] phi smc_flash::smc_attempts_total#21 = 0 [phi:smc_flash::@44->smc_flash::@11#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z smc_attempts_total
    sta.z smc_attempts_total+1
    // [1450] phi smc_flash::smc_row_bytes#14 = 0 [phi:smc_flash::@44->smc_flash::@11#2] -- vwuz1=vwuc1 
    sta.z smc_row_bytes
    sta.z smc_row_bytes+1
    // [1450] phi smc_flash::smc_ram_ptr#13 = (char *)$6000 [phi:smc_flash::@44->smc_flash::@11#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z smc_ram_ptr
    lda #>$6000
    sta.z smc_ram_ptr+1
    // [1450] phi smc_flash::smc_bytes_flashed#16 = 0 [phi:smc_flash::@44->smc_flash::@11#4] -- vwuz1=vwuc1 
    lda #<0
    sta.z smc_bytes_flashed
    sta.z smc_bytes_flashed+1
    // [1450] phi from smc_flash::@13 to smc_flash::@11 [phi:smc_flash::@13->smc_flash::@11]
    // [1450] phi smc_flash::y#31 = smc_flash::y#20 [phi:smc_flash::@13->smc_flash::@11#0] -- register_copy 
    // [1450] phi smc_flash::smc_attempts_total#21 = smc_flash::smc_attempts_total#17 [phi:smc_flash::@13->smc_flash::@11#1] -- register_copy 
    // [1450] phi smc_flash::smc_row_bytes#14 = smc_flash::smc_row_bytes#10 [phi:smc_flash::@13->smc_flash::@11#2] -- register_copy 
    // [1450] phi smc_flash::smc_ram_ptr#13 = smc_flash::smc_ram_ptr#10 [phi:smc_flash::@13->smc_flash::@11#3] -- register_copy 
    // [1450] phi smc_flash::smc_bytes_flashed#16 = smc_flash::smc_bytes_flashed#11 [phi:smc_flash::@13->smc_flash::@11#4] -- register_copy 
    // smc_flash::@11
  __b11:
    // while(smc_bytes_flashed < smc_bytes_total)
    // [1451] if(smc_flash::smc_bytes_flashed#16<smc_flash::smc_bytes_total#0) goto smc_flash::@12 -- vwuz1_lt_vwuz2_then_la1 
    lda.z smc_bytes_flashed+1
    cmp.z smc_bytes_total+1
    bcc __b10
    bne !+
    lda.z smc_bytes_flashed
    cmp.z smc_bytes_total
    bcc __b10
  !:
    // [1422] phi from smc_flash::@11 to smc_flash::@return [phi:smc_flash::@11->smc_flash::@return]
    // [1422] phi smc_flash::return#1 = smc_flash::smc_bytes_flashed#16 [phi:smc_flash::@11->smc_flash::@return#0] -- register_copy 
    rts
    // [1452] phi from smc_flash::@11 to smc_flash::@12 [phi:smc_flash::@11->smc_flash::@12]
  __b10:
    // [1452] phi smc_flash::y#20 = smc_flash::y#31 [phi:smc_flash::@11->smc_flash::@12#0] -- register_copy 
    // [1452] phi smc_flash::smc_attempts_total#17 = smc_flash::smc_attempts_total#21 [phi:smc_flash::@11->smc_flash::@12#1] -- register_copy 
    // [1452] phi smc_flash::smc_row_bytes#10 = smc_flash::smc_row_bytes#14 [phi:smc_flash::@11->smc_flash::@12#2] -- register_copy 
    // [1452] phi smc_flash::smc_ram_ptr#10 = smc_flash::smc_ram_ptr#13 [phi:smc_flash::@11->smc_flash::@12#3] -- register_copy 
    // [1452] phi smc_flash::smc_bytes_flashed#11 = smc_flash::smc_bytes_flashed#16 [phi:smc_flash::@11->smc_flash::@12#4] -- register_copy 
    // [1452] phi smc_flash::smc_attempts_flashed#19 = 0 [phi:smc_flash::@11->smc_flash::@12#5] -- vbum1=vbuc1 
    lda #0
    sta smc_attempts_flashed
    // [1452] phi smc_flash::smc_package_committed#2 = 0 [phi:smc_flash::@11->smc_flash::@12#6] -- vbuz1=vbuc1 
    sta.z smc_package_committed
    // smc_flash::@12
  __b12:
    // while(!smc_package_committed && smc_attempts_flashed < 10)
    // [1453] if(0!=smc_flash::smc_package_committed#2) goto smc_flash::@13 -- 0_neq_vbuz1_then_la1 
    lda.z smc_package_committed
    bne __b13
    // smc_flash::@60
    // [1454] if(smc_flash::smc_attempts_flashed#19<$a) goto smc_flash::@14 -- vbum1_lt_vbuc1_then_la1 
    lda smc_attempts_flashed
    cmp #$a
    bcc __b16
    // smc_flash::@13
  __b13:
    // if(smc_attempts_flashed >= 10)
    // [1455] if(smc_flash::smc_attempts_flashed#19<$a) goto smc_flash::@11 -- vbum1_lt_vbuc1_then_la1 
    lda smc_attempts_flashed
    cmp #$a
    bcc __b11
    // [1456] phi from smc_flash::@13 to smc_flash::@21 [phi:smc_flash::@13->smc_flash::@21]
    // smc_flash::@21
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1457] call snprintf_init
    // [868] phi from smc_flash::@21 to snprintf_init [phi:smc_flash::@21->snprintf_init]
    // [868] phi snprintf_init::s#25 = info_text [phi:smc_flash::@21->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1458] phi from smc_flash::@21 to smc_flash::@57 [phi:smc_flash::@21->smc_flash::@57]
    // smc_flash::@57
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1459] call printf_str
    // [873] phi from smc_flash::@57 to printf_str [phi:smc_flash::@57->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:smc_flash::@57->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = smc_flash::s10 [phi:smc_flash::@57->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@58
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1460] printf_uint::uvalue#12 = smc_flash::smc_bytes_flashed#11 -- vwum1=vwuz2 
    lda.z smc_bytes_flashed
    sta printf_uint.uvalue
    lda.z smc_bytes_flashed+1
    sta printf_uint.uvalue+1
    // [1461] call printf_uint
    // [907] phi from smc_flash::@58 to printf_uint [phi:smc_flash::@58->printf_uint]
    // [907] phi printf_uint::format_zero_padding#18 = 1 [phi:smc_flash::@58->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [907] phi printf_uint::format_min_length#18 = 4 [phi:smc_flash::@58->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [907] phi printf_uint::putc#18 = &snputc [phi:smc_flash::@58->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [907] phi printf_uint::format_radix#18 = HEXADECIMAL [phi:smc_flash::@58->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [907] phi printf_uint::uvalue#18 = printf_uint::uvalue#12 [phi:smc_flash::@58->printf_uint#4] -- register_copy 
    jsr printf_uint
    // smc_flash::@59
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1462] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1463] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1465] call display_action_text
    // [1046] phi from smc_flash::@59 to display_action_text [phi:smc_flash::@59->display_action_text]
    // [1046] phi display_action_text::info_text#19 = info_text [phi:smc_flash::@59->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    jmp __b2
    // [1466] phi from smc_flash::@60 to smc_flash::@14 [phi:smc_flash::@60->smc_flash::@14]
  __b16:
    // [1466] phi smc_flash::smc_bytes_checksum#2 = 0 [phi:smc_flash::@60->smc_flash::@14#0] -- vbuz1=vbuc1 
    lda #0
    sta.z smc_bytes_checksum
    // [1466] phi smc_flash::smc_ram_ptr#12 = smc_flash::smc_ram_ptr#10 [phi:smc_flash::@60->smc_flash::@14#1] -- register_copy 
    // [1466] phi smc_flash::smc_package_flashed#2 = 0 [phi:smc_flash::@60->smc_flash::@14#2] -- vwuz1=vwuc1 
    sta.z smc_package_flashed
    sta.z smc_package_flashed+1
    // smc_flash::@14
  __b14:
    // while(smc_package_flashed < SMC_PROGRESS_CELL)
    // [1467] if(smc_flash::smc_package_flashed#2<SMC_PROGRESS_CELL) goto smc_flash::@15 -- vwuz1_lt_vbuc1_then_la1 
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
    // [1468] smc_flash::$26 = smc_flash::smc_bytes_checksum#2 ^ $ff -- vbuz1=vbuz1_bxor_vbuc1 
    lda #$ff
    eor.z smc_flash__26
    sta.z smc_flash__26
    // (smc_bytes_checksum ^ 0xFF)+1
    // [1469] smc_flash::$27 = smc_flash::$26 + 1 -- vbuz1=vbuz1_plus_1 
    inc.z smc_flash__27
    // unsigned char smc_checksum_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, (smc_bytes_checksum ^ 0xFF)+1)
    // [1470] smc_flash::cx16_k_i2c_write_byte4_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte4_device
    // [1471] smc_flash::cx16_k_i2c_write_byte4_offset = $80 -- vbum1=vbuc1 
    lda #$80
    sta cx16_k_i2c_write_byte4_offset
    // [1472] smc_flash::cx16_k_i2c_write_byte4_value = smc_flash::$27 -- vbum1=vbuz2 
    lda.z smc_flash__27
    sta cx16_k_i2c_write_byte4_value
    // smc_flash::cx16_k_i2c_write_byte4
    // unsigned char result
    // [1473] smc_flash::cx16_k_i2c_write_byte4_result = 0 -- vbum1=vbuc1 
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
    // [1475] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1476] cx16_k_i2c_read_byte::offset = $81 -- vbum1=vbuc1 
    lda #$81
    sta cx16_k_i2c_read_byte.offset
    // [1477] call cx16_k_i2c_read_byte
    // Now send the commit command.
    jsr cx16_k_i2c_read_byte
    // [1478] cx16_k_i2c_read_byte::return#16 = cx16_k_i2c_read_byte::return#1
    // smc_flash::@48
    // [1479] smc_flash::smc_commit_result#0 = cx16_k_i2c_read_byte::return#16 -- vwum1=vwum2 
    lda cx16_k_i2c_read_byte.return
    sta smc_commit_result
    lda cx16_k_i2c_read_byte.return+1
    sta smc_commit_result+1
    // if(smc_commit_result == 1)
    // [1480] if(smc_flash::smc_commit_result#0==1) goto smc_flash::@18 -- vwum1_eq_vbuc1_then_la1 
    bne !+
    lda smc_commit_result
    cmp #1
    beq __b18
  !:
    // smc_flash::@17
    // smc_ram_ptr -= SMC_PROGRESS_CELL
    // [1481] smc_flash::smc_ram_ptr#2 = smc_flash::smc_ram_ptr#12 - SMC_PROGRESS_CELL -- pbuz1=pbuz1_minus_vbuc1 
    sec
    lda.z smc_ram_ptr
    sbc #SMC_PROGRESS_CELL
    sta.z smc_ram_ptr
    lda.z smc_ram_ptr+1
    sbc #0
    sta.z smc_ram_ptr+1
    // smc_attempts_flashed++;
    // [1482] smc_flash::smc_attempts_flashed#1 = ++ smc_flash::smc_attempts_flashed#19 -- vbum1=_inc_vbum1 
    inc smc_attempts_flashed
    // [1452] phi from smc_flash::@17 to smc_flash::@12 [phi:smc_flash::@17->smc_flash::@12]
    // [1452] phi smc_flash::y#20 = smc_flash::y#20 [phi:smc_flash::@17->smc_flash::@12#0] -- register_copy 
    // [1452] phi smc_flash::smc_attempts_total#17 = smc_flash::smc_attempts_total#17 [phi:smc_flash::@17->smc_flash::@12#1] -- register_copy 
    // [1452] phi smc_flash::smc_row_bytes#10 = smc_flash::smc_row_bytes#10 [phi:smc_flash::@17->smc_flash::@12#2] -- register_copy 
    // [1452] phi smc_flash::smc_ram_ptr#10 = smc_flash::smc_ram_ptr#2 [phi:smc_flash::@17->smc_flash::@12#3] -- register_copy 
    // [1452] phi smc_flash::smc_bytes_flashed#11 = smc_flash::smc_bytes_flashed#11 [phi:smc_flash::@17->smc_flash::@12#4] -- register_copy 
    // [1452] phi smc_flash::smc_attempts_flashed#19 = smc_flash::smc_attempts_flashed#1 [phi:smc_flash::@17->smc_flash::@12#5] -- register_copy 
    // [1452] phi smc_flash::smc_package_committed#2 = smc_flash::smc_package_committed#2 [phi:smc_flash::@17->smc_flash::@12#6] -- register_copy 
    jmp __b12
    // smc_flash::@18
  __b18:
    // if (smc_row_bytes == SMC_PROGRESS_ROW)
    // [1483] if(smc_flash::smc_row_bytes#10!=SMC_PROGRESS_ROW) goto smc_flash::@19 -- vwuz1_neq_vwuc1_then_la1 
    lda.z smc_row_bytes+1
    cmp #>SMC_PROGRESS_ROW
    bne __b19
    lda.z smc_row_bytes
    cmp #<SMC_PROGRESS_ROW
    bne __b19
    // smc_flash::@20
    // gotoxy(x, ++y);
    // [1484] smc_flash::y#1 = ++ smc_flash::y#20 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [1485] gotoxy::y#22 = smc_flash::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1486] call gotoxy
    // [606] phi from smc_flash::@20 to gotoxy [phi:smc_flash::@20->gotoxy]
    // [606] phi gotoxy::y#30 = gotoxy::y#22 [phi:smc_flash::@20->gotoxy#0] -- register_copy 
    // [606] phi gotoxy::x#30 = PROGRESS_X [phi:smc_flash::@20->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1487] phi from smc_flash::@20 to smc_flash::@19 [phi:smc_flash::@20->smc_flash::@19]
    // [1487] phi smc_flash::y#33 = smc_flash::y#1 [phi:smc_flash::@20->smc_flash::@19#0] -- register_copy 
    // [1487] phi smc_flash::smc_row_bytes#4 = 0 [phi:smc_flash::@20->smc_flash::@19#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z smc_row_bytes
    sta.z smc_row_bytes+1
    // [1487] phi from smc_flash::@18 to smc_flash::@19 [phi:smc_flash::@18->smc_flash::@19]
    // [1487] phi smc_flash::y#33 = smc_flash::y#20 [phi:smc_flash::@18->smc_flash::@19#0] -- register_copy 
    // [1487] phi smc_flash::smc_row_bytes#4 = smc_flash::smc_row_bytes#10 [phi:smc_flash::@18->smc_flash::@19#1] -- register_copy 
    // smc_flash::@19
  __b19:
    // cputc('+')
    // [1488] stackpush(char) = '+' -- _stackpushbyte_=vbuc1 
    lda #'+'
    pha
    // [1489] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_bytes_flashed += SMC_PROGRESS_CELL
    // [1491] smc_flash::smc_bytes_flashed#1 = smc_flash::smc_bytes_flashed#11 + SMC_PROGRESS_CELL -- vwuz1=vwuz1_plus_vbuc1 
    lda #SMC_PROGRESS_CELL
    clc
    adc.z smc_bytes_flashed
    sta.z smc_bytes_flashed
    bcc !+
    inc.z smc_bytes_flashed+1
  !:
    // smc_row_bytes += SMC_PROGRESS_CELL
    // [1492] smc_flash::smc_row_bytes#1 = smc_flash::smc_row_bytes#4 + SMC_PROGRESS_CELL -- vwuz1=vwuz1_plus_vbuc1 
    lda #SMC_PROGRESS_CELL
    clc
    adc.z smc_row_bytes
    sta.z smc_row_bytes
    bcc !+
    inc.z smc_row_bytes+1
  !:
    // smc_attempts_total += smc_attempts_flashed
    // [1493] smc_flash::smc_attempts_total#1 = smc_flash::smc_attempts_total#17 + smc_flash::smc_attempts_flashed#19 -- vwuz1=vwuz1_plus_vbum2 
    lda smc_attempts_flashed
    clc
    adc.z smc_attempts_total
    sta.z smc_attempts_total
    bcc !+
    inc.z smc_attempts_total+1
  !:
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1494] call snprintf_init
    // [868] phi from smc_flash::@19 to snprintf_init [phi:smc_flash::@19->snprintf_init]
    // [868] phi snprintf_init::s#25 = info_text [phi:smc_flash::@19->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1495] phi from smc_flash::@19 to smc_flash::@49 [phi:smc_flash::@19->smc_flash::@49]
    // smc_flash::@49
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1496] call printf_str
    // [873] phi from smc_flash::@49 to printf_str [phi:smc_flash::@49->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:smc_flash::@49->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = smc_flash::s6 [phi:smc_flash::@49->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@50
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1497] printf_uint::uvalue#9 = smc_flash::smc_bytes_flashed#1 -- vwum1=vwuz2 
    lda.z smc_bytes_flashed
    sta printf_uint.uvalue
    lda.z smc_bytes_flashed+1
    sta printf_uint.uvalue+1
    // [1498] call printf_uint
    // [907] phi from smc_flash::@50 to printf_uint [phi:smc_flash::@50->printf_uint]
    // [907] phi printf_uint::format_zero_padding#18 = 1 [phi:smc_flash::@50->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [907] phi printf_uint::format_min_length#18 = 5 [phi:smc_flash::@50->printf_uint#1] -- vbum1=vbuc1 
    lda #5
    sta printf_uint.format_min_length
    // [907] phi printf_uint::putc#18 = &snputc [phi:smc_flash::@50->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [907] phi printf_uint::format_radix#18 = DECIMAL [phi:smc_flash::@50->printf_uint#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uint.format_radix
    // [907] phi printf_uint::uvalue#18 = printf_uint::uvalue#9 [phi:smc_flash::@50->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1499] phi from smc_flash::@50 to smc_flash::@51 [phi:smc_flash::@50->smc_flash::@51]
    // smc_flash::@51
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1500] call printf_str
    // [873] phi from smc_flash::@51 to printf_str [phi:smc_flash::@51->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:smc_flash::@51->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = smc_flash::s7 [phi:smc_flash::@51->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@52
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1501] printf_uint::uvalue#10 = smc_flash::smc_bytes_total#0 -- vwum1=vwuz2 
    lda.z smc_bytes_total
    sta printf_uint.uvalue
    lda.z smc_bytes_total+1
    sta printf_uint.uvalue+1
    // [1502] call printf_uint
    // [907] phi from smc_flash::@52 to printf_uint [phi:smc_flash::@52->printf_uint]
    // [907] phi printf_uint::format_zero_padding#18 = 1 [phi:smc_flash::@52->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [907] phi printf_uint::format_min_length#18 = 5 [phi:smc_flash::@52->printf_uint#1] -- vbum1=vbuc1 
    lda #5
    sta printf_uint.format_min_length
    // [907] phi printf_uint::putc#18 = &snputc [phi:smc_flash::@52->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [907] phi printf_uint::format_radix#18 = DECIMAL [phi:smc_flash::@52->printf_uint#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uint.format_radix
    // [907] phi printf_uint::uvalue#18 = printf_uint::uvalue#10 [phi:smc_flash::@52->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1503] phi from smc_flash::@52 to smc_flash::@53 [phi:smc_flash::@52->smc_flash::@53]
    // smc_flash::@53
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1504] call printf_str
    // [873] phi from smc_flash::@53 to printf_str [phi:smc_flash::@53->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:smc_flash::@53->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = smc_flash::s8 [phi:smc_flash::@53->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@54
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1505] printf_uint::uvalue#11 = smc_flash::smc_attempts_total#1 -- vwum1=vwuz2 
    lda.z smc_attempts_total
    sta printf_uint.uvalue
    lda.z smc_attempts_total+1
    sta printf_uint.uvalue+1
    // [1506] call printf_uint
    // [907] phi from smc_flash::@54 to printf_uint [phi:smc_flash::@54->printf_uint]
    // [907] phi printf_uint::format_zero_padding#18 = 1 [phi:smc_flash::@54->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [907] phi printf_uint::format_min_length#18 = 2 [phi:smc_flash::@54->printf_uint#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uint.format_min_length
    // [907] phi printf_uint::putc#18 = &snputc [phi:smc_flash::@54->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [907] phi printf_uint::format_radix#18 = DECIMAL [phi:smc_flash::@54->printf_uint#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uint.format_radix
    // [907] phi printf_uint::uvalue#18 = printf_uint::uvalue#11 [phi:smc_flash::@54->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1507] phi from smc_flash::@54 to smc_flash::@55 [phi:smc_flash::@54->smc_flash::@55]
    // smc_flash::@55
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1508] call printf_str
    // [873] phi from smc_flash::@55 to printf_str [phi:smc_flash::@55->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:smc_flash::@55->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = smc_flash::s9 [phi:smc_flash::@55->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@56
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1509] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1510] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1512] call display_action_text
    // [1046] phi from smc_flash::@56 to display_action_text [phi:smc_flash::@56->display_action_text]
    // [1046] phi display_action_text::info_text#19 = info_text [phi:smc_flash::@56->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1452] phi from smc_flash::@56 to smc_flash::@12 [phi:smc_flash::@56->smc_flash::@12]
    // [1452] phi smc_flash::y#20 = smc_flash::y#33 [phi:smc_flash::@56->smc_flash::@12#0] -- register_copy 
    // [1452] phi smc_flash::smc_attempts_total#17 = smc_flash::smc_attempts_total#1 [phi:smc_flash::@56->smc_flash::@12#1] -- register_copy 
    // [1452] phi smc_flash::smc_row_bytes#10 = smc_flash::smc_row_bytes#1 [phi:smc_flash::@56->smc_flash::@12#2] -- register_copy 
    // [1452] phi smc_flash::smc_ram_ptr#10 = smc_flash::smc_ram_ptr#12 [phi:smc_flash::@56->smc_flash::@12#3] -- register_copy 
    // [1452] phi smc_flash::smc_bytes_flashed#11 = smc_flash::smc_bytes_flashed#1 [phi:smc_flash::@56->smc_flash::@12#4] -- register_copy 
    // [1452] phi smc_flash::smc_attempts_flashed#19 = smc_flash::smc_attempts_flashed#19 [phi:smc_flash::@56->smc_flash::@12#5] -- register_copy 
    // [1452] phi smc_flash::smc_package_committed#2 = 1 [phi:smc_flash::@56->smc_flash::@12#6] -- vbuz1=vbuc1 
    lda #1
    sta.z smc_package_committed
    jmp __b12
    // smc_flash::@15
  __b15:
    // unsigned char smc_byte_upload = *smc_ram_ptr
    // [1513] smc_flash::smc_byte_upload#0 = *smc_flash::smc_ram_ptr#12 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (smc_ram_ptr),y
    sta smc_byte_upload
    // smc_ram_ptr++;
    // [1514] smc_flash::smc_ram_ptr#1 = ++ smc_flash::smc_ram_ptr#12 -- pbuz1=_inc_pbuz1 
    inc.z smc_ram_ptr
    bne !+
    inc.z smc_ram_ptr+1
  !:
    // smc_bytes_checksum += smc_byte_upload
    // [1515] smc_flash::smc_bytes_checksum#1 = smc_flash::smc_bytes_checksum#2 + smc_flash::smc_byte_upload#0 -- vbuz1=vbuz1_plus_vbum2 
    lda smc_byte_upload
    clc
    adc.z smc_bytes_checksum
    sta.z smc_bytes_checksum
    // unsigned char smc_upload_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, smc_byte_upload)
    // [1516] smc_flash::cx16_k_i2c_write_byte3_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte3_device
    // [1517] smc_flash::cx16_k_i2c_write_byte3_offset = $80 -- vbum1=vbuc1 
    lda #$80
    sta cx16_k_i2c_write_byte3_offset
    // [1518] smc_flash::cx16_k_i2c_write_byte3_value = smc_flash::smc_byte_upload#0 -- vbum1=vbum2 
    lda smc_byte_upload
    sta cx16_k_i2c_write_byte3_value
    // smc_flash::cx16_k_i2c_write_byte3
    // unsigned char result
    // [1519] smc_flash::cx16_k_i2c_write_byte3_result = 0 -- vbum1=vbuc1 
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
    // [1521] smc_flash::smc_package_flashed#1 = ++ smc_flash::smc_package_flashed#2 -- vwuz1=_inc_vwuz1 
    inc.z smc_package_flashed
    bne !+
    inc.z smc_package_flashed+1
  !:
    // [1466] phi from smc_flash::@23 to smc_flash::@14 [phi:smc_flash::@23->smc_flash::@14]
    // [1466] phi smc_flash::smc_bytes_checksum#2 = smc_flash::smc_bytes_checksum#1 [phi:smc_flash::@23->smc_flash::@14#0] -- register_copy 
    // [1466] phi smc_flash::smc_ram_ptr#12 = smc_flash::smc_ram_ptr#1 [phi:smc_flash::@23->smc_flash::@14#1] -- register_copy 
    // [1466] phi smc_flash::smc_package_flashed#2 = smc_flash::smc_package_flashed#1 [phi:smc_flash::@23->smc_flash::@14#2] -- register_copy 
    jmp __b14
    // [1522] phi from smc_flash::@7 to smc_flash::@8 [phi:smc_flash::@7->smc_flash::@8]
    // smc_flash::@8
  __b8:
    // wait_moment()
    // [1523] call wait_moment
    // [1030] phi from smc_flash::@8 to wait_moment [phi:smc_flash::@8->wait_moment]
    jsr wait_moment
    // [1524] phi from smc_flash::@8 to smc_flash::@36 [phi:smc_flash::@8->smc_flash::@36]
    // smc_flash::@36
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1525] call snprintf_init
    // [868] phi from smc_flash::@36 to snprintf_init [phi:smc_flash::@36->snprintf_init]
    // [868] phi snprintf_init::s#25 = info_text [phi:smc_flash::@36->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1526] phi from smc_flash::@36 to smc_flash::@37 [phi:smc_flash::@36->smc_flash::@37]
    // smc_flash::@37
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1527] call printf_str
    // [873] phi from smc_flash::@37 to printf_str [phi:smc_flash::@37->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:smc_flash::@37->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = smc_flash::s3 [phi:smc_flash::@37->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@38
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1528] printf_uchar::uvalue#3 = smc_flash::smc_bootloader_activation_countdown#12 -- vbum1=vbum2 
    lda smc_bootloader_activation_countdown_1
    sta printf_uchar.uvalue
    // [1529] call printf_uchar
    // [1035] phi from smc_flash::@38 to printf_uchar [phi:smc_flash::@38->printf_uchar]
    // [1035] phi printf_uchar::format_zero_padding#11 = 0 [phi:smc_flash::@38->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1035] phi printf_uchar::format_min_length#11 = 0 [phi:smc_flash::@38->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1035] phi printf_uchar::putc#11 = &snputc [phi:smc_flash::@38->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1035] phi printf_uchar::format_radix#11 = DECIMAL [phi:smc_flash::@38->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1035] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#3 [phi:smc_flash::@38->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1530] phi from smc_flash::@38 to smc_flash::@39 [phi:smc_flash::@38->smc_flash::@39]
    // smc_flash::@39
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1531] call printf_str
    // [873] phi from smc_flash::@39 to printf_str [phi:smc_flash::@39->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:smc_flash::@39->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = s7 [phi:smc_flash::@39->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s7
    sta.z printf_str.s
    lda #>@s7
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@40
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1532] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1533] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1535] call display_action_text
    // [1046] phi from smc_flash::@40 to display_action_text [phi:smc_flash::@40->display_action_text]
    // [1046] phi display_action_text::info_text#19 = info_text [phi:smc_flash::@40->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_flash::@41
    // smc_bootloader_activation_countdown--;
    // [1536] smc_flash::smc_bootloader_activation_countdown#3 = -- smc_flash::smc_bootloader_activation_countdown#12 -- vbum1=_dec_vbum1 
    dec smc_bootloader_activation_countdown_1
    // [1426] phi from smc_flash::@41 to smc_flash::@7 [phi:smc_flash::@41->smc_flash::@7]
    // [1426] phi smc_flash::smc_bootloader_activation_countdown#12 = smc_flash::smc_bootloader_activation_countdown#3 [phi:smc_flash::@41->smc_flash::@7#0] -- register_copy 
    jmp __b7
    // smc_flash::@4
  __b4:
    // unsigned int smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1537] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1538] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [1539] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [1540] cx16_k_i2c_read_byte::return#14 = cx16_k_i2c_read_byte::return#1
    // smc_flash::@30
    // [1541] smc_flash::smc_bootloader_not_activated1#0 = cx16_k_i2c_read_byte::return#14 -- vwum1=vwum2 
    lda cx16_k_i2c_read_byte.return
    sta smc_bootloader_not_activated1
    lda cx16_k_i2c_read_byte.return+1
    sta smc_bootloader_not_activated1+1
    // if(smc_bootloader_not_activated)
    // [1542] if(0!=smc_flash::smc_bootloader_not_activated1#0) goto smc_flash::@5 -- 0_neq_vwum1_then_la1 
    lda smc_bootloader_not_activated1
    ora smc_bootloader_not_activated1+1
    bne __b5
    jmp __b9
    // [1543] phi from smc_flash::@30 to smc_flash::@5 [phi:smc_flash::@30->smc_flash::@5]
    // smc_flash::@5
  __b5:
    // wait_moment()
    // [1544] call wait_moment
    // [1030] phi from smc_flash::@5 to wait_moment [phi:smc_flash::@5->wait_moment]
    jsr wait_moment
    // [1545] phi from smc_flash::@5 to smc_flash::@31 [phi:smc_flash::@5->smc_flash::@31]
    // smc_flash::@31
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1546] call snprintf_init
    // [868] phi from smc_flash::@31 to snprintf_init [phi:smc_flash::@31->snprintf_init]
    // [868] phi snprintf_init::s#25 = info_text [phi:smc_flash::@31->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1547] phi from smc_flash::@31 to smc_flash::@32 [phi:smc_flash::@31->smc_flash::@32]
    // smc_flash::@32
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1548] call printf_str
    // [873] phi from smc_flash::@32 to printf_str [phi:smc_flash::@32->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:smc_flash::@32->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = smc_flash::s1 [phi:smc_flash::@32->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@33
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1549] printf_uchar::uvalue#2 = smc_flash::smc_bootloader_activation_countdown#10 -- vbum1=vbum2 
    lda smc_bootloader_activation_countdown
    sta printf_uchar.uvalue
    // [1550] call printf_uchar
    // [1035] phi from smc_flash::@33 to printf_uchar [phi:smc_flash::@33->printf_uchar]
    // [1035] phi printf_uchar::format_zero_padding#11 = 1 [phi:smc_flash::@33->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1035] phi printf_uchar::format_min_length#11 = 3 [phi:smc_flash::@33->printf_uchar#1] -- vbum1=vbuc1 
    lda #3
    sta printf_uchar.format_min_length
    // [1035] phi printf_uchar::putc#11 = &snputc [phi:smc_flash::@33->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1035] phi printf_uchar::format_radix#11 = DECIMAL [phi:smc_flash::@33->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1035] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#2 [phi:smc_flash::@33->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1551] phi from smc_flash::@33 to smc_flash::@34 [phi:smc_flash::@33->smc_flash::@34]
    // smc_flash::@34
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1552] call printf_str
    // [873] phi from smc_flash::@34 to printf_str [phi:smc_flash::@34->printf_str]
    // [873] phi printf_str::putc#73 = &snputc [phi:smc_flash::@34->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [873] phi printf_str::s#73 = smc_flash::s2 [phi:smc_flash::@34->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@35
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1553] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1554] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1556] call display_action_text
    // [1046] phi from smc_flash::@35 to display_action_text [phi:smc_flash::@35->display_action_text]
    // [1046] phi display_action_text::info_text#19 = info_text [phi:smc_flash::@35->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_flash::@6
    // smc_bootloader_activation_countdown--;
    // [1557] smc_flash::smc_bootloader_activation_countdown#2 = -- smc_flash::smc_bootloader_activation_countdown#10 -- vbum1=_dec_vbum1 
    dec smc_bootloader_activation_countdown
    // [1424] phi from smc_flash::@6 to smc_flash::@3 [phi:smc_flash::@6->smc_flash::@3]
    // [1424] phi smc_flash::smc_bootloader_activation_countdown#10 = smc_flash::smc_bootloader_activation_countdown#2 [phi:smc_flash::@6->smc_flash::@3#0] -- register_copy 
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
    cx16_k_i2c_write_byte1_return: .byte 0
    smc_bootloader_start: .byte 0
    smc_bootloader_not_activated1: .word 0
    // Waiting a bit to ensure the bootloader is activated.
    .label smc_bootloader_activation_countdown = main.check_status_vera1_main__0
    // Waiting a bit to ensure the bootloader is activated.
    .label smc_bootloader_activation_countdown_1 = main.check_status_smc8_main__0
    smc_byte_upload: .byte 0
    smc_commit_result: .word 0
    .label smc_attempts_flashed = main.check_status_smc9_main__0
    .label y = main.check_status_vera2_main__0
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
// __mem() char util_wait_key(__zp($38) char *info_text, __zp($78) char *filter)
util_wait_key: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 0
    .label util_wait_key__9 = $c8
    .label info_text = $38
    .label ch = $be
    .label filter = $78
    // display_action_text(info_text)
    // [1559] display_action_text::info_text#7 = util_wait_key::info_text#2
    // [1560] call display_action_text
    // [1046] phi from util_wait_key to display_action_text [phi:util_wait_key->display_action_text]
    // [1046] phi display_action_text::info_text#19 = display_action_text::info_text#7 [phi:util_wait_key->display_action_text#0] -- register_copy 
    jsr display_action_text
    // util_wait_key::bank_get_bram1
    // return BRAM;
    // [1561] util_wait_key::bram#0 = BRAM -- vbum1=vbuz2 
    lda.z BRAM
    sta bram
    // util_wait_key::bank_get_brom1
    // return BROM;
    // [1562] util_wait_key::bank_get_brom1_return#0 = BROM -- vbum1=vbuz2 
    lda.z BROM
    sta bank_get_brom1_return
    // util_wait_key::bank_set_bram1
    // BRAM = bank
    // [1563] BRAM = util_wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // util_wait_key::bank_set_brom1
    // BROM = bank
    // [1564] BROM = util_wait_key::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [1565] phi from util_wait_key::@2 util_wait_key::@5 util_wait_key::bank_set_brom1 to util_wait_key::kbhit1 [phi:util_wait_key::@2/util_wait_key::@5/util_wait_key::bank_set_brom1->util_wait_key::kbhit1]
    // util_wait_key::kbhit1
  kbhit1:
    // util_wait_key::kbhit1_cbm_k_clrchn1
    // asm
    // asm { jsrCBM_CLRCHN  }
    jsr CBM_CLRCHN
    // [1567] phi from util_wait_key::kbhit1_cbm_k_clrchn1 to util_wait_key::kbhit1_@2 [phi:util_wait_key::kbhit1_cbm_k_clrchn1->util_wait_key::kbhit1_@2]
    // util_wait_key::kbhit1_@2
    // cbm_k_getin()
    // [1568] call cbm_k_getin
    jsr cbm_k_getin
    // [1569] cbm_k_getin::return#2 = cbm_k_getin::return#1
    // util_wait_key::@4
    // [1570] util_wait_key::ch#4 = cbm_k_getin::return#2 -- vwuz1=vbum2 
    lda cbm_k_getin.return
    sta.z ch
    lda #0
    sta.z ch+1
    // util_wait_key::@3
    // if (filter)
    // [1571] if((char *)0!=util_wait_key::filter#12) goto util_wait_key::@1 -- pbuc1_neq_pbuz1_then_la1 
    // if there is a filter, check the filter, otherwise return ch.
    lda.z filter+1
    cmp #>0
    bne __b1
    lda.z filter
    cmp #<0
    bne __b1
    // util_wait_key::@2
    // if(ch)
    // [1572] if(0!=util_wait_key::ch#4) goto util_wait_key::bank_set_bram2 -- 0_neq_vwuz1_then_la1 
    lda.z ch
    ora.z ch+1
    bne bank_set_bram2
    jmp kbhit1
    // util_wait_key::bank_set_bram2
  bank_set_bram2:
    // BRAM = bank
    // [1573] BRAM = util_wait_key::bram#0 -- vbuz1=vbum2 
    lda bram
    sta.z BRAM
    // util_wait_key::bank_set_brom2
    // BROM = bank
    // [1574] BROM = util_wait_key::bank_get_brom1_return#0 -- vbuz1=vbum2 
    lda bank_get_brom1_return
    sta.z BROM
    // util_wait_key::@return
    // }
    // [1575] return 
    rts
    // util_wait_key::@1
  __b1:
    // strchr(filter, ch)
    // [1576] strchr::str#0 = (const void *)util_wait_key::filter#12 -- pvoz1=pvoz2 
    lda.z filter
    sta.z strchr.str
    lda.z filter+1
    sta.z strchr.str+1
    // [1577] strchr::c#0 = util_wait_key::ch#4 -- vbum1=vwuz2 
    lda.z ch
    sta strchr.c
    // [1578] call strchr
    // [1582] phi from util_wait_key::@1 to strchr [phi:util_wait_key::@1->strchr]
    // [1582] phi strchr::c#4 = strchr::c#0 [phi:util_wait_key::@1->strchr#0] -- register_copy 
    // [1582] phi strchr::str#2 = strchr::str#0 [phi:util_wait_key::@1->strchr#1] -- register_copy 
    jsr strchr
    // strchr(filter, ch)
    // [1579] strchr::return#3 = strchr::return#2
    // util_wait_key::@5
    // [1580] util_wait_key::$9 = strchr::return#3
    // if(strchr(filter, ch) != NULL)
    // [1581] if(util_wait_key::$9!=0) goto util_wait_key::bank_set_bram2 -- pvoz1_neq_0_then_la1 
    lda.z util_wait_key__9
    ora.z util_wait_key__9+1
    bne bank_set_bram2
    jmp kbhit1
  .segment Data
    bram: .byte 0
    bank_get_brom1_return: .byte 0
    return: .byte 0
}
.segment Code
  // strchr
// Searches for the first occurrence of the character c (an unsigned char) in the string pointed to, by the argument str.
// - str: The memory to search
// - c: A character to search for
// Return: A pointer to the matching byte or NULL if the character does not occur in the given memory area.
// __zp($c8) void * strchr(__zp($c8) const void *str, __mem() char c)
strchr: {
    .label ptr = $c8
    .label return = $c8
    .label str = $c8
    // [1583] strchr::ptr#6 = (char *)strchr::str#2
    // [1584] phi from strchr strchr::@3 to strchr::@1 [phi:strchr/strchr::@3->strchr::@1]
    // [1584] phi strchr::ptr#2 = strchr::ptr#6 [phi:strchr/strchr::@3->strchr::@1#0] -- register_copy 
    // strchr::@1
  __b1:
    // while(*ptr)
    // [1585] if(0!=*strchr::ptr#2) goto strchr::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (ptr),y
    cmp #0
    bne __b2
    // [1586] phi from strchr::@1 to strchr::@return [phi:strchr::@1->strchr::@return]
    // [1586] phi strchr::return#2 = (void *) 0 [phi:strchr::@1->strchr::@return#0] -- pvoz1=pvoc1 
    tya
    sta.z return
    sta.z return+1
    // strchr::@return
    // }
    // [1587] return 
    rts
    // strchr::@2
  __b2:
    // if(*ptr==c)
    // [1588] if(*strchr::ptr#2!=strchr::c#4) goto strchr::@3 -- _deref_pbuz1_neq_vbum2_then_la1 
    ldy #0
    lda (ptr),y
    cmp c
    bne __b3
    // strchr::@4
    // [1589] strchr::return#8 = (void *)strchr::ptr#2
    // [1586] phi from strchr::@4 to strchr::@return [phi:strchr::@4->strchr::@return]
    // [1586] phi strchr::return#2 = strchr::return#8 [phi:strchr::@4->strchr::@return#0] -- register_copy 
    rts
    // strchr::@3
  __b3:
    // ptr++;
    // [1590] strchr::ptr#1 = ++ strchr::ptr#2 -- pbuz1=_inc_pbuz1 
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
// void display_info_cx16_rom(char info_status, char *info_text)
display_info_cx16_rom: {
    .label info_text = 0
    // display_info_rom(0, info_status, info_text)
    // [1592] call display_info_rom
    // [1069] phi from display_info_cx16_rom to display_info_rom [phi:display_info_cx16_rom->display_info_rom]
    // [1069] phi display_info_rom::info_text#17 = display_info_cx16_rom::info_text#0 [phi:display_info_cx16_rom->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_rom.info_text
    lda #>info_text
    sta.z display_info_rom.info_text+1
    // [1069] phi display_info_rom::rom_chip#17 = 0 [phi:display_info_cx16_rom->display_info_rom#1] -- vbuz1=vbuc1 
    lda #0
    sta.z display_info_rom.rom_chip
    // [1069] phi display_info_rom::info_status#17 = STATUS_ISSUE [phi:display_info_cx16_rom->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // display_info_cx16_rom::@return
    // }
    // [1593] return 
    rts
}
  // strncpy
/// Copies up to n characters from the string pointed to, by src to dst.
/// In a case where the length of src is less than that of n, the remainder of dst will be padded with null bytes.
/// @param dst ? This is the pointer to the destination array where the content is to be copied.
/// @param src ? This is the string to be copied.
/// @param n ? The number of characters to be copied from source.
/// @return The destination
// char * strncpy(__zp($b9) char *dst, __zp($44) const char *src, __mem() unsigned int n)
strncpy: {
    .label dst = $b9
    .label src = $44
    // [1595] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [1595] phi strncpy::dst#3 = strncpy::dst#8 [phi:strncpy->strncpy::@1#0] -- register_copy 
    // [1595] phi strncpy::src#3 = strncpy::src#6 [phi:strncpy->strncpy::@1#1] -- register_copy 
    // [1595] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwum1=vwuc1 
    lda #<0
    sta i
    sta i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [1596] if(strncpy::i#2<strncpy::n#3) goto strncpy::@2 -- vwum1_lt_vwum2_then_la1 
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
    // [1597] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [1598] strncpy::c#0 = *strncpy::src#3 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta c
    // if(c)
    // [1599] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbum1_then_la1 
    beq __b3
    // strncpy::@4
    // src++;
    // [1600] strncpy::src#0 = ++ strncpy::src#3 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [1601] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [1601] phi strncpy::src#7 = strncpy::src#3 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [1602] *strncpy::dst#3 = strncpy::c#0 -- _deref_pbuz1=vbum2 
    lda c
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [1603] strncpy::dst#0 = ++ strncpy::dst#3 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [1604] strncpy::i#1 = ++ strncpy::i#2 -- vwum1=_inc_vwum1 
    inc i
    bne !+
    inc i+1
  !:
    // [1595] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [1595] phi strncpy::dst#3 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [1595] phi strncpy::src#3 = strncpy::src#7 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [1595] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
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
// void display_info_led(__zp($4c) char x, __zp($4d) char y, __zp($c2) char tc, char bc)
display_info_led: {
    .label tc = $c2
    .label y = $4d
    .label x = $4c
    // textcolor(tc)
    // [1606] textcolor::color#13 = display_info_led::tc#4 -- vbum1=vbuz2 
    lda.z tc
    sta textcolor.color
    // [1607] call textcolor
    // [588] phi from display_info_led to textcolor [phi:display_info_led->textcolor]
    // [588] phi textcolor::color#18 = textcolor::color#13 [phi:display_info_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [1608] phi from display_info_led to display_info_led::@1 [phi:display_info_led->display_info_led::@1]
    // display_info_led::@1
    // bgcolor(bc)
    // [1609] call bgcolor
    // [593] phi from display_info_led::@1 to bgcolor [phi:display_info_led::@1->bgcolor]
    // [593] phi bgcolor::color#14 = BLUE [phi:display_info_led::@1->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_info_led::@2
    // cputcxy(x, y, VERA_CHR_UR)
    // [1610] cputcxy::x#11 = display_info_led::x#4 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [1611] cputcxy::y#11 = display_info_led::y#4 -- vbum1=vbuz2 
    lda.z y
    sta cputcxy.y
    // [1612] call cputcxy
    // [1834] phi from display_info_led::@2 to cputcxy [phi:display_info_led::@2->cputcxy]
    // [1834] phi cputcxy::c#15 = $7c [phi:display_info_led::@2->cputcxy#0] -- vbum1=vbuc1 
    lda #$7c
    sta cputcxy.c
    // [1834] phi cputcxy::y#15 = cputcxy::y#11 [phi:display_info_led::@2->cputcxy#1] -- register_copy 
    // [1834] phi cputcxy::x#15 = cputcxy::x#11 [phi:display_info_led::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [1613] phi from display_info_led::@2 to display_info_led::@3 [phi:display_info_led::@2->display_info_led::@3]
    // display_info_led::@3
    // textcolor(WHITE)
    // [1614] call textcolor
    // [588] phi from display_info_led::@3 to textcolor [phi:display_info_led::@3->textcolor]
    // [588] phi textcolor::color#18 = WHITE [phi:display_info_led::@3->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // display_info_led::@return
    // }
    // [1615] return 
    rts
}
  // screenlayer
// --- layer management in VERA ---
// void screenlayer(char layer, __mem() char mapbase, __mem() char config)
screenlayer: {
    .label screenlayer__0 = $bc
    .label screenlayer__1 = $bb
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [1616] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [1617] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [1618] *((char *)&__conio+2) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+2
    // mapbase >> 7
    // [1619] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbuz1=vbum2_ror_7 
    lda mapbase
    rol
    rol
    and #1
    sta.z screenlayer__0
    // __conio.mapbase_bank = mapbase >> 7
    // [1620] *((char *)&__conio+5) = screenlayer::$0 -- _deref_pbuc1=vbuz1 
    sta __conio+5
    // (mapbase)<<1
    // [1621] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbuz1=vbum2_rol_1 
    lda mapbase
    asl
    sta.z screenlayer__1
    // MAKEWORD((mapbase)<<1,0)
    // [1622] screenlayer::$2 = screenlayer::$1 w= 0 -- vwum1=vbuz2_word_vbuc1 
    lda #0
    ldy.z screenlayer__1
    sty screenlayer__2+1
    sta screenlayer__2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [1623] *((unsigned int *)&__conio+3) = screenlayer::$2 -- _deref_pwuc1=vwum1 
    sta __conio+3
    tya
    sta __conio+3+1
    // config & VERA_LAYER_WIDTH_MASK
    // [1624] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbum1=vbum2_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and config
    sta screenlayer__7
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [1625] screenlayer::$8 = screenlayer::$7 >> 4 -- vbum1=vbum1_ror_4 
    lda screenlayer__8
    lsr
    lsr
    lsr
    lsr
    sta screenlayer__8
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [1626] *((char *)&__conio+8) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbum1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+8
    // config & VERA_LAYER_HEIGHT_MASK
    // [1627] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbum1=vbum2_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and config
    sta screenlayer__5
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [1628] screenlayer::$6 = screenlayer::$5 >> 6 -- vbum1=vbum1_ror_6 
    lda screenlayer__6
    rol
    rol
    rol
    and #3
    sta screenlayer__6
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [1629] *((char *)&__conio+9) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbum1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+9
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [1630] screenlayer::$16 = screenlayer::$8 << 1 -- vbum1=vbum1_rol_1 
    asl screenlayer__16
    // [1631] *((unsigned int *)&__conio+$a) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbum1 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    ldy screenlayer__16
    lda VERA_LAYER_SKIP,y
    sta __conio+$a
    lda VERA_LAYER_SKIP+1,y
    sta __conio+$a+1
    // vera_dc_hscale_temp == 0x80
    // [1632] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vbom1=vbum2_eq_vbuc1 
    lda vera_dc_hscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta screenlayer__9
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [1633] screenlayer::$18 = (char)screenlayer::$9
    // [1634] screenlayer::$10 = $28 << screenlayer::$18 -- vbum1=vbuc1_rol_vbum1 
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
    // [1635] screenlayer::$11 = screenlayer::$10 - 1 -- vbum1=vbum1_minus_1 
    dec screenlayer__11
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [1636] *((char *)&__conio+6) = screenlayer::$11 -- _deref_pbuc1=vbum1 
    lda screenlayer__11
    sta __conio+6
    // vera_dc_vscale_temp == 0x80
    // [1637] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vbom1=vbum2_eq_vbuc1 
    lda vera_dc_vscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta screenlayer__12
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [1638] screenlayer::$19 = (char)screenlayer::$12
    // [1639] screenlayer::$13 = $1e << screenlayer::$19 -- vbum1=vbuc1_rol_vbum1 
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
    // [1640] screenlayer::$14 = screenlayer::$13 - 1 -- vbum1=vbum1_minus_1 
    dec screenlayer__14
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [1641] *((char *)&__conio+7) = screenlayer::$14 -- _deref_pbuc1=vbum1 
    lda screenlayer__14
    sta __conio+7
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [1642] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta mapbase_offset
    lda __conio+3+1
    sta mapbase_offset+1
    // [1643] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [1643] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [1643] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbum1=vbuc1 
    lda #0
    sta y
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [1644] if(screenlayer::y#2<=*((char *)&__conio+7)) goto screenlayer::@2 -- vbum1_le__deref_pbuc1_then_la1 
    lda __conio+7
    cmp y
    bcs __b2
    // screenlayer::@return
    // }
    // [1645] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [1646] screenlayer::$17 = screenlayer::y#2 << 1 -- vbum1=vbum2_rol_1 
    lda y
    asl
    sta screenlayer__17
    // [1647] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbum1=vwum2 
    tay
    lda mapbase_offset
    sta __conio+$15,y
    lda mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [1648] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda mapbase_offset
    adc __conio+$a
    sta mapbase_offset
    lda mapbase_offset+1
    adc __conio+$a+1
    sta mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [1649] screenlayer::y#1 = ++ screenlayer::y#2 -- vbum1=_inc_vbum1 
    inc y
    // [1643] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [1643] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [1643] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    VERA_LAYER_DIM: .byte $1f, $3f, $7f, $ff
    VERA_LAYER_SKIP: .word $40, $80, $100, $200
    screenlayer__2: .word 0
    screenlayer__5: .byte 0
    .label screenlayer__6 = screenlayer__5
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
    mapbase: .byte 0
    config: .byte 0
    vera_dc_hscale_temp: .byte 0
    vera_dc_vscale_temp: .byte 0
    mapbase_offset: .word 0
    .label y = conio_x16_init.conio_x16_init__5
}
.segment Code
  // cscroll
// Scroll the entire screen if the cursor is beyond the last line
cscroll: {
    // if(__conio.cursor_y>__conio.height)
    // [1650] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [1651] if(0!=((char *)&__conio+$f)[*((char *)&__conio+2)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [1652] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // [1653] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [1654] call gotoxy
    // [606] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [606] phi gotoxy::y#30 = 0 [phi:cscroll::@3->gotoxy#0] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.y
    // [606] phi gotoxy::x#30 = 0 [phi:cscroll::@3->gotoxy#1] -- vbum1=vbuc1 
    sta gotoxy.x
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [1655] return 
    rts
    // [1656] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [1657] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [1658] gotoxy::y#3 = *((char *)&__conio+7) -- vbum1=_deref_pbuc1 
    lda __conio+7
    sta gotoxy.y
    // [1659] call gotoxy
    // [606] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [606] phi gotoxy::y#30 = gotoxy::y#3 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [606] phi gotoxy::x#30 = 0 [phi:cscroll::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.x
    jsr gotoxy
    // [1660] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [1661] call clearline
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
    // [1662] ((char *)&__conio+$f)[*((char *)&__conio+2)] = scroll::onoff#0 -- pbuc1_derefidx_(_deref_pbuc2)=vbuc3 
    lda #onoff
    ldy __conio+2
    sta __conio+$f,y
    // scroll::@return
    // }
    // [1663] return 
    rts
}
  // clrscr
// clears the screen and moves the cursor to the upper left-hand corner of the screen.
clrscr: {
    // unsigned int line_text = __conio.mapbase_offset
    // [1664] clrscr::line_text#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta line_text
    lda __conio+3+1
    sta line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1665] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [1666] clrscr::$0 = *((char *)&__conio+5) | VERA_INC_1 -- vbum1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta clrscr__0
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1667] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [1668] clrscr::l#0 = *((char *)&__conio+9) -- vbum1=_deref_pbuc1 
    lda __conio+9
    sta l
    // [1669] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [1669] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [1669] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [1670] clrscr::$1 = byte0  clrscr::ch#0 -- vbum1=_byte0_vwum2 
    lda ch
    sta clrscr__1
    // *VERA_ADDRX_L = BYTE0(ch)
    // [1671] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbum1 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [1672] clrscr::$2 = byte1  clrscr::ch#0 -- vbum1=_byte1_vwum2 
    lda ch+1
    sta clrscr__2
    // *VERA_ADDRX_M = BYTE1(ch)
    // [1673] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth+1
    // [1674] clrscr::c#0 = *((char *)&__conio+8) + 1 -- vbum1=_deref_pbuc1_plus_1 
    lda __conio+8
    inc
    sta c
    // [1675] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [1675] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [1676] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1677] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [1678] clrscr::c#1 = -- clrscr::c#2 -- vbum1=_dec_vbum1 
    dec c
    // while(c)
    // [1679] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [1680] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda line_text
    adc __conio+$a
    sta line_text
    lda line_text+1
    adc __conio+$a+1
    sta line_text+1
    // l--;
    // [1681] clrscr::l#1 = -- clrscr::l#4 -- vbum1=_dec_vbum1 
    dec l
    // while(l)
    // [1682] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbum1_then_la1 
    lda l
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [1683] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y = 0
    // [1684] *((char *)&__conio+1) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+1
    // __conio.offset = __conio.mapbase_offset
    // [1685] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+3) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+3
    sta __conio+$13
    lda __conio+3+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [1686] return 
    rts
  .segment Data
    clrscr__0: .byte 0
    clrscr__1: .byte 0
    clrscr__2: .byte 0
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
// void display_frame(char x0, char y0, __mem() char x1, __mem() char y1)
display_frame: {
    .label mask = $4e
    .label c = $2a
    // unsigned char w = x1 - x0
    // [1688] display_frame::w#0 = display_frame::x1#16 - display_frame::x#0 -- vbum1=vbum2_minus_vbum3 
    lda x1
    sec
    sbc x
    sta w
    // unsigned char h = y1 - y0
    // [1689] display_frame::h#0 = display_frame::y1#16 - display_frame::y#0 -- vbum1=vbum2_minus_vbum3 
    lda y1
    sec
    sbc y
    sta h
    // unsigned char mask = display_frame_maskxy(x, y)
    // [1690] display_frame_maskxy::x#0 = display_frame::x#0
    // [1691] display_frame_maskxy::y#0 = display_frame::y#0
    // [1692] call display_frame_maskxy
    // [2349] phi from display_frame to display_frame_maskxy [phi:display_frame->display_frame_maskxy]
    // [2349] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#0 [phi:display_frame->display_frame_maskxy#0] -- vbum1=vbum2 
    lda display_frame_maskxy.y
    sta display_frame_maskxy.cpeekcxy1_y
    // [2349] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#0 [phi:display_frame->display_frame_maskxy#1] -- vbum1=vbum2 
    lda display_frame_maskxy.x
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // unsigned char mask = display_frame_maskxy(x, y)
    // [1693] display_frame_maskxy::return#13 = display_frame_maskxy::return#12
    // display_frame::@13
    // [1694] display_frame::mask#0 = display_frame_maskxy::return#13
    // mask |= 0b0110
    // [1695] display_frame::mask#1 = display_frame::mask#0 | 6 -- vbuz1=vbuz1_bor_vbuc1 
    lda #6
    ora.z mask
    sta.z mask
    // unsigned char c = display_frame_char(mask)
    // [1696] display_frame_char::mask#0 = display_frame::mask#1
    // [1697] call display_frame_char
  // Add a corner.
    // [2375] phi from display_frame::@13 to display_frame_char [phi:display_frame::@13->display_frame_char]
    // [2375] phi display_frame_char::mask#10 = display_frame_char::mask#0 [phi:display_frame::@13->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // unsigned char c = display_frame_char(mask)
    // [1698] display_frame_char::return#13 = display_frame_char::return#12
    // display_frame::@14
    // [1699] display_frame::c#0 = display_frame_char::return#13
    // cputcxy(x, y, c)
    // [1700] cputcxy::x#0 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1701] cputcxy::y#0 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [1702] cputcxy::c#0 = display_frame::c#0 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [1703] call cputcxy
    // [1834] phi from display_frame::@14 to cputcxy [phi:display_frame::@14->cputcxy]
    // [1834] phi cputcxy::c#15 = cputcxy::c#0 [phi:display_frame::@14->cputcxy#0] -- register_copy 
    // [1834] phi cputcxy::y#15 = cputcxy::y#0 [phi:display_frame::@14->cputcxy#1] -- register_copy 
    // [1834] phi cputcxy::x#15 = cputcxy::x#0 [phi:display_frame::@14->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@15
    // if(w>=2)
    // [1704] if(display_frame::w#0<2) goto display_frame::@36 -- vbum1_lt_vbuc1_then_la1 
    lda w
    cmp #2
    bcs !__b36+
    jmp __b36
  !__b36:
    // display_frame::@2
    // x++;
    // [1705] display_frame::x#1 = ++ display_frame::x#0 -- vbum1=_inc_vbum2 
    lda x
    inc
    sta x_1
    // [1706] phi from display_frame::@2 display_frame::@21 to display_frame::@4 [phi:display_frame::@2/display_frame::@21->display_frame::@4]
    // [1706] phi display_frame::x#10 = display_frame::x#1 [phi:display_frame::@2/display_frame::@21->display_frame::@4#0] -- register_copy 
    // display_frame::@4
  __b4:
    // while(x < x1)
    // [1707] if(display_frame::x#10<display_frame::x1#16) goto display_frame::@5 -- vbum1_lt_vbum2_then_la1 
    lda x_1
    cmp x1
    bcs !__b5+
    jmp __b5
  !__b5:
    // [1708] phi from display_frame::@36 display_frame::@4 to display_frame::@1 [phi:display_frame::@36/display_frame::@4->display_frame::@1]
    // [1708] phi display_frame::x#24 = display_frame::x#30 [phi:display_frame::@36/display_frame::@4->display_frame::@1#0] -- register_copy 
    // display_frame::@1
  __b1:
    // display_frame_maskxy(x, y)
    // [1709] display_frame_maskxy::x#1 = display_frame::x#24
    // [1710] display_frame_maskxy::y#1 = display_frame::y#0
    // [1711] call display_frame_maskxy
    // [2349] phi from display_frame::@1 to display_frame_maskxy [phi:display_frame::@1->display_frame_maskxy]
    // [2349] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#1 [phi:display_frame::@1->display_frame_maskxy#0] -- vbum1=vbum2 
    lda display_frame_maskxy.y
    sta display_frame_maskxy.cpeekcxy1_y
    // [2349] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#1 [phi:display_frame::@1->display_frame_maskxy#1] -- vbum1=vbum2 
    lda display_frame_maskxy.x_1
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1712] display_frame_maskxy::return#14 = display_frame_maskxy::return#12
    // display_frame::@16
    // mask = display_frame_maskxy(x, y)
    // [1713] display_frame::mask#2 = display_frame_maskxy::return#14
    // mask |= 0b0011
    // [1714] display_frame::mask#3 = display_frame::mask#2 | 3 -- vbuz1=vbuz1_bor_vbuc1 
    lda #3
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [1715] display_frame_char::mask#1 = display_frame::mask#3
    // [1716] call display_frame_char
    // [2375] phi from display_frame::@16 to display_frame_char [phi:display_frame::@16->display_frame_char]
    // [2375] phi display_frame_char::mask#10 = display_frame_char::mask#1 [phi:display_frame::@16->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1717] display_frame_char::return#14 = display_frame_char::return#12
    // display_frame::@17
    // c = display_frame_char(mask)
    // [1718] display_frame::c#1 = display_frame_char::return#14
    // cputcxy(x, y, c)
    // [1719] cputcxy::x#1 = display_frame::x#24 -- vbum1=vbum2 
    lda x_1
    sta cputcxy.x
    // [1720] cputcxy::y#1 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [1721] cputcxy::c#1 = display_frame::c#1 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [1722] call cputcxy
    // [1834] phi from display_frame::@17 to cputcxy [phi:display_frame::@17->cputcxy]
    // [1834] phi cputcxy::c#15 = cputcxy::c#1 [phi:display_frame::@17->cputcxy#0] -- register_copy 
    // [1834] phi cputcxy::y#15 = cputcxy::y#1 [phi:display_frame::@17->cputcxy#1] -- register_copy 
    // [1834] phi cputcxy::x#15 = cputcxy::x#1 [phi:display_frame::@17->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@18
    // if(h>=2)
    // [1723] if(display_frame::h#0<2) goto display_frame::@return -- vbum1_lt_vbuc1_then_la1 
    lda h
    cmp #2
    bcc __breturn
    // display_frame::@3
    // y++;
    // [1724] display_frame::y#1 = ++ display_frame::y#0 -- vbum1=_inc_vbum2 
    lda y
    inc
    sta y_1
    // [1725] phi from display_frame::@27 display_frame::@3 to display_frame::@6 [phi:display_frame::@27/display_frame::@3->display_frame::@6]
    // [1725] phi display_frame::y#10 = display_frame::y#2 [phi:display_frame::@27/display_frame::@3->display_frame::@6#0] -- register_copy 
    // display_frame::@6
  __b6:
    // while(y < y1)
    // [1726] if(display_frame::y#10<display_frame::y1#16) goto display_frame::@7 -- vbum1_lt_vbum2_then_la1 
    lda y_1
    cmp y1
    bcs !__b7+
    jmp __b7
  !__b7:
    // display_frame::@8
    // display_frame_maskxy(x, y)
    // [1727] display_frame_maskxy::x#5 = display_frame::x#0
    // [1728] display_frame_maskxy::y#5 = display_frame::y#10
    // [1729] call display_frame_maskxy
    // [2349] phi from display_frame::@8 to display_frame_maskxy [phi:display_frame::@8->display_frame_maskxy]
    // [2349] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#5 [phi:display_frame::@8->display_frame_maskxy#0] -- vbum1=vbum2 
    lda display_frame_maskxy.y_1
    sta display_frame_maskxy.cpeekcxy1_y
    // [2349] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#5 [phi:display_frame::@8->display_frame_maskxy#1] -- vbum1=vbum2 
    lda display_frame_maskxy.x
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1730] display_frame_maskxy::return#18 = display_frame_maskxy::return#12
    // display_frame::@28
    // mask = display_frame_maskxy(x, y)
    // [1731] display_frame::mask#10 = display_frame_maskxy::return#18
    // mask |= 0b1100
    // [1732] display_frame::mask#11 = display_frame::mask#10 | $c -- vbuz1=vbuz1_bor_vbuc1 
    lda #$c
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [1733] display_frame_char::mask#5 = display_frame::mask#11
    // [1734] call display_frame_char
    // [2375] phi from display_frame::@28 to display_frame_char [phi:display_frame::@28->display_frame_char]
    // [2375] phi display_frame_char::mask#10 = display_frame_char::mask#5 [phi:display_frame::@28->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1735] display_frame_char::return#18 = display_frame_char::return#12
    // display_frame::@29
    // c = display_frame_char(mask)
    // [1736] display_frame::c#5 = display_frame_char::return#18
    // cputcxy(x, y, c)
    // [1737] cputcxy::x#5 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1738] cputcxy::y#5 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [1739] cputcxy::c#5 = display_frame::c#5 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [1740] call cputcxy
    // [1834] phi from display_frame::@29 to cputcxy [phi:display_frame::@29->cputcxy]
    // [1834] phi cputcxy::c#15 = cputcxy::c#5 [phi:display_frame::@29->cputcxy#0] -- register_copy 
    // [1834] phi cputcxy::y#15 = cputcxy::y#5 [phi:display_frame::@29->cputcxy#1] -- register_copy 
    // [1834] phi cputcxy::x#15 = cputcxy::x#5 [phi:display_frame::@29->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@30
    // if(w>=2)
    // [1741] if(display_frame::w#0<2) goto display_frame::@10 -- vbum1_lt_vbuc1_then_la1 
    lda w
    cmp #2
    bcc __b10
    // display_frame::@9
    // x++;
    // [1742] display_frame::x#4 = ++ display_frame::x#0 -- vbum1=_inc_vbum1 
    inc x
    // [1743] phi from display_frame::@35 display_frame::@9 to display_frame::@11 [phi:display_frame::@35/display_frame::@9->display_frame::@11]
    // [1743] phi display_frame::x#18 = display_frame::x#5 [phi:display_frame::@35/display_frame::@9->display_frame::@11#0] -- register_copy 
    // display_frame::@11
  __b11:
    // while(x < x1)
    // [1744] if(display_frame::x#18<display_frame::x1#16) goto display_frame::@12 -- vbum1_lt_vbum2_then_la1 
    lda x
    cmp x1
    bcc __b12
    // [1745] phi from display_frame::@11 display_frame::@30 to display_frame::@10 [phi:display_frame::@11/display_frame::@30->display_frame::@10]
    // [1745] phi display_frame::x#15 = display_frame::x#18 [phi:display_frame::@11/display_frame::@30->display_frame::@10#0] -- register_copy 
    // display_frame::@10
  __b10:
    // display_frame_maskxy(x, y)
    // [1746] display_frame_maskxy::x#6 = display_frame::x#15
    // [1747] display_frame_maskxy::y#6 = display_frame::y#10
    // [1748] call display_frame_maskxy
    // [2349] phi from display_frame::@10 to display_frame_maskxy [phi:display_frame::@10->display_frame_maskxy]
    // [2349] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#6 [phi:display_frame::@10->display_frame_maskxy#0] -- vbum1=vbum2 
    lda display_frame_maskxy.y_1
    sta display_frame_maskxy.cpeekcxy1_y
    // [2349] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#6 [phi:display_frame::@10->display_frame_maskxy#1] -- vbum1=vbum2 
    lda display_frame_maskxy.x
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1749] display_frame_maskxy::return#19 = display_frame_maskxy::return#12
    // display_frame::@31
    // mask = display_frame_maskxy(x, y)
    // [1750] display_frame::mask#12 = display_frame_maskxy::return#19
    // mask |= 0b1001
    // [1751] display_frame::mask#13 = display_frame::mask#12 | 9 -- vbuz1=vbuz1_bor_vbuc1 
    lda #9
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [1752] display_frame_char::mask#6 = display_frame::mask#13
    // [1753] call display_frame_char
    // [2375] phi from display_frame::@31 to display_frame_char [phi:display_frame::@31->display_frame_char]
    // [2375] phi display_frame_char::mask#10 = display_frame_char::mask#6 [phi:display_frame::@31->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1754] display_frame_char::return#19 = display_frame_char::return#12
    // display_frame::@32
    // c = display_frame_char(mask)
    // [1755] display_frame::c#6 = display_frame_char::return#19
    // cputcxy(x, y, c)
    // [1756] cputcxy::x#6 = display_frame::x#15 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1757] cputcxy::y#6 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [1758] cputcxy::c#6 = display_frame::c#6 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [1759] call cputcxy
    // [1834] phi from display_frame::@32 to cputcxy [phi:display_frame::@32->cputcxy]
    // [1834] phi cputcxy::c#15 = cputcxy::c#6 [phi:display_frame::@32->cputcxy#0] -- register_copy 
    // [1834] phi cputcxy::y#15 = cputcxy::y#6 [phi:display_frame::@32->cputcxy#1] -- register_copy 
    // [1834] phi cputcxy::x#15 = cputcxy::x#6 [phi:display_frame::@32->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@return
  __breturn:
    // }
    // [1760] return 
    rts
    // display_frame::@12
  __b12:
    // display_frame_maskxy(x, y)
    // [1761] display_frame_maskxy::x#7 = display_frame::x#18
    // [1762] display_frame_maskxy::y#7 = display_frame::y#10
    // [1763] call display_frame_maskxy
    // [2349] phi from display_frame::@12 to display_frame_maskxy [phi:display_frame::@12->display_frame_maskxy]
    // [2349] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#7 [phi:display_frame::@12->display_frame_maskxy#0] -- vbum1=vbum2 
    lda display_frame_maskxy.y_1
    sta display_frame_maskxy.cpeekcxy1_y
    // [2349] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#7 [phi:display_frame::@12->display_frame_maskxy#1] -- vbum1=vbum2 
    lda display_frame_maskxy.x
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1764] display_frame_maskxy::return#20 = display_frame_maskxy::return#12
    // display_frame::@33
    // mask = display_frame_maskxy(x, y)
    // [1765] display_frame::mask#14 = display_frame_maskxy::return#20
    // mask |= 0b0101
    // [1766] display_frame::mask#15 = display_frame::mask#14 | 5 -- vbuz1=vbuz1_bor_vbuc1 
    lda #5
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [1767] display_frame_char::mask#7 = display_frame::mask#15
    // [1768] call display_frame_char
    // [2375] phi from display_frame::@33 to display_frame_char [phi:display_frame::@33->display_frame_char]
    // [2375] phi display_frame_char::mask#10 = display_frame_char::mask#7 [phi:display_frame::@33->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1769] display_frame_char::return#20 = display_frame_char::return#12
    // display_frame::@34
    // c = display_frame_char(mask)
    // [1770] display_frame::c#7 = display_frame_char::return#20
    // cputcxy(x, y, c)
    // [1771] cputcxy::x#7 = display_frame::x#18 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1772] cputcxy::y#7 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [1773] cputcxy::c#7 = display_frame::c#7 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [1774] call cputcxy
    // [1834] phi from display_frame::@34 to cputcxy [phi:display_frame::@34->cputcxy]
    // [1834] phi cputcxy::c#15 = cputcxy::c#7 [phi:display_frame::@34->cputcxy#0] -- register_copy 
    // [1834] phi cputcxy::y#15 = cputcxy::y#7 [phi:display_frame::@34->cputcxy#1] -- register_copy 
    // [1834] phi cputcxy::x#15 = cputcxy::x#7 [phi:display_frame::@34->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@35
    // x++;
    // [1775] display_frame::x#5 = ++ display_frame::x#18 -- vbum1=_inc_vbum1 
    inc x
    jmp __b11
    // display_frame::@7
  __b7:
    // display_frame_maskxy(x0, y)
    // [1776] display_frame_maskxy::x#3 = display_frame::x#0
    // [1777] display_frame_maskxy::y#3 = display_frame::y#10
    // [1778] call display_frame_maskxy
    // [2349] phi from display_frame::@7 to display_frame_maskxy [phi:display_frame::@7->display_frame_maskxy]
    // [2349] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#3 [phi:display_frame::@7->display_frame_maskxy#0] -- vbum1=vbum2 
    lda display_frame_maskxy.y_1
    sta display_frame_maskxy.cpeekcxy1_y
    // [2349] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#3 [phi:display_frame::@7->display_frame_maskxy#1] -- vbum1=vbum2 
    lda display_frame_maskxy.x
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x0, y)
    // [1779] display_frame_maskxy::return#16 = display_frame_maskxy::return#12
    // display_frame::@22
    // mask = display_frame_maskxy(x0, y)
    // [1780] display_frame::mask#6 = display_frame_maskxy::return#16
    // mask |= 0b1010
    // [1781] display_frame::mask#7 = display_frame::mask#6 | $a -- vbuz1=vbuz1_bor_vbuc1 
    lda #$a
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [1782] display_frame_char::mask#3 = display_frame::mask#7
    // [1783] call display_frame_char
    // [2375] phi from display_frame::@22 to display_frame_char [phi:display_frame::@22->display_frame_char]
    // [2375] phi display_frame_char::mask#10 = display_frame_char::mask#3 [phi:display_frame::@22->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1784] display_frame_char::return#16 = display_frame_char::return#12
    // display_frame::@23
    // c = display_frame_char(mask)
    // [1785] display_frame::c#3 = display_frame_char::return#16
    // cputcxy(x0, y, c)
    // [1786] cputcxy::x#3 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1787] cputcxy::y#3 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [1788] cputcxy::c#3 = display_frame::c#3 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [1789] call cputcxy
    // [1834] phi from display_frame::@23 to cputcxy [phi:display_frame::@23->cputcxy]
    // [1834] phi cputcxy::c#15 = cputcxy::c#3 [phi:display_frame::@23->cputcxy#0] -- register_copy 
    // [1834] phi cputcxy::y#15 = cputcxy::y#3 [phi:display_frame::@23->cputcxy#1] -- register_copy 
    // [1834] phi cputcxy::x#15 = cputcxy::x#3 [phi:display_frame::@23->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@24
    // display_frame_maskxy(x1, y)
    // [1790] display_frame_maskxy::x#4 = display_frame::x1#16
    // [1791] display_frame_maskxy::y#4 = display_frame::y#10
    // [1792] call display_frame_maskxy
    // [2349] phi from display_frame::@24 to display_frame_maskxy [phi:display_frame::@24->display_frame_maskxy]
    // [2349] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#4 [phi:display_frame::@24->display_frame_maskxy#0] -- vbum1=vbum2 
    lda display_frame_maskxy.y_1
    sta display_frame_maskxy.cpeekcxy1_y
    // [2349] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#4 [phi:display_frame::@24->display_frame_maskxy#1] -- vbum1=vbum2 
    lda display_frame_maskxy.x_2
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x1, y)
    // [1793] display_frame_maskxy::return#17 = display_frame_maskxy::return#12
    // display_frame::@25
    // mask = display_frame_maskxy(x1, y)
    // [1794] display_frame::mask#8 = display_frame_maskxy::return#17
    // mask |= 0b1010
    // [1795] display_frame::mask#9 = display_frame::mask#8 | $a -- vbuz1=vbuz1_bor_vbuc1 
    lda #$a
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [1796] display_frame_char::mask#4 = display_frame::mask#9
    // [1797] call display_frame_char
    // [2375] phi from display_frame::@25 to display_frame_char [phi:display_frame::@25->display_frame_char]
    // [2375] phi display_frame_char::mask#10 = display_frame_char::mask#4 [phi:display_frame::@25->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1798] display_frame_char::return#17 = display_frame_char::return#12
    // display_frame::@26
    // c = display_frame_char(mask)
    // [1799] display_frame::c#4 = display_frame_char::return#17
    // cputcxy(x1, y, c)
    // [1800] cputcxy::x#4 = display_frame::x1#16 -- vbum1=vbum2 
    lda x1
    sta cputcxy.x
    // [1801] cputcxy::y#4 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [1802] cputcxy::c#4 = display_frame::c#4 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [1803] call cputcxy
    // [1834] phi from display_frame::@26 to cputcxy [phi:display_frame::@26->cputcxy]
    // [1834] phi cputcxy::c#15 = cputcxy::c#4 [phi:display_frame::@26->cputcxy#0] -- register_copy 
    // [1834] phi cputcxy::y#15 = cputcxy::y#4 [phi:display_frame::@26->cputcxy#1] -- register_copy 
    // [1834] phi cputcxy::x#15 = cputcxy::x#4 [phi:display_frame::@26->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@27
    // y++;
    // [1804] display_frame::y#2 = ++ display_frame::y#10 -- vbum1=_inc_vbum1 
    inc y_1
    jmp __b6
    // display_frame::@5
  __b5:
    // display_frame_maskxy(x, y)
    // [1805] display_frame_maskxy::x#2 = display_frame::x#10
    // [1806] display_frame_maskxy::y#2 = display_frame::y#0
    // [1807] call display_frame_maskxy
    // [2349] phi from display_frame::@5 to display_frame_maskxy [phi:display_frame::@5->display_frame_maskxy]
    // [2349] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#2 [phi:display_frame::@5->display_frame_maskxy#0] -- vbum1=vbum2 
    lda display_frame_maskxy.y
    sta display_frame_maskxy.cpeekcxy1_y
    // [2349] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#2 [phi:display_frame::@5->display_frame_maskxy#1] -- vbum1=vbum2 
    lda display_frame_maskxy.x_1
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1808] display_frame_maskxy::return#15 = display_frame_maskxy::return#12
    // display_frame::@19
    // mask = display_frame_maskxy(x, y)
    // [1809] display_frame::mask#4 = display_frame_maskxy::return#15
    // mask |= 0b0101
    // [1810] display_frame::mask#5 = display_frame::mask#4 | 5 -- vbuz1=vbuz1_bor_vbuc1 
    lda #5
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [1811] display_frame_char::mask#2 = display_frame::mask#5
    // [1812] call display_frame_char
    // [2375] phi from display_frame::@19 to display_frame_char [phi:display_frame::@19->display_frame_char]
    // [2375] phi display_frame_char::mask#10 = display_frame_char::mask#2 [phi:display_frame::@19->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1813] display_frame_char::return#15 = display_frame_char::return#12
    // display_frame::@20
    // c = display_frame_char(mask)
    // [1814] display_frame::c#2 = display_frame_char::return#15
    // cputcxy(x, y, c)
    // [1815] cputcxy::x#2 = display_frame::x#10 -- vbum1=vbum2 
    lda x_1
    sta cputcxy.x
    // [1816] cputcxy::y#2 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [1817] cputcxy::c#2 = display_frame::c#2 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [1818] call cputcxy
    // [1834] phi from display_frame::@20 to cputcxy [phi:display_frame::@20->cputcxy]
    // [1834] phi cputcxy::c#15 = cputcxy::c#2 [phi:display_frame::@20->cputcxy#0] -- register_copy 
    // [1834] phi cputcxy::y#15 = cputcxy::y#2 [phi:display_frame::@20->cputcxy#1] -- register_copy 
    // [1834] phi cputcxy::x#15 = cputcxy::x#2 [phi:display_frame::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@21
    // x++;
    // [1819] display_frame::x#2 = ++ display_frame::x#10 -- vbum1=_inc_vbum1 
    inc x_1
    jmp __b4
    // display_frame::@36
  __b36:
    // [1820] display_frame::x#30 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta x_1
    jmp __b1
  .segment Data
    .label w = fopen.fopen__4
    .label h = fopen.fopen__9
    .label x = main.check_status_smc7_main__0
    .label y = main.check_status_roms1_check_status_rom1_main__0
    .label x_1 = main.check_status_roms_all1_check_status_rom1_main__0
    .label y_1 = main.check_status_rom1_main__0
    .label x1 = main.check_status_smc10_main__0
    .label y1 = main.check_status_roms2_check_status_rom1_main__0
}
.segment Code
  // cputs
// Output a NUL-terminated string at the current cursor position
// void cputs(__zp($b7) const char *s)
cputs: {
    .label s = $b7
    // [1822] phi from cputs cputs::@2 to cputs::@1 [phi:cputs/cputs::@2->cputs::@1]
    // [1822] phi cputs::s#2 = cputs::s#1 [phi:cputs/cputs::@2->cputs::@1#0] -- register_copy 
    // cputs::@1
  __b1:
    // while(c=*s++)
    // [1823] cputs::c#1 = *cputs::s#2 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta c
    // [1824] cputs::s#0 = ++ cputs::s#2 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [1825] if(0!=cputs::c#1) goto cputs::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // cputs::@return
    // }
    // [1826] return 
    rts
    // cputs::@2
  __b2:
    // cputc(c)
    // [1827] stackpush(char) = cputs::c#1 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [1828] callexecute cputc  -- call_vprc1 
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
    // [1830] wherex::return#0 = *((char *)&__conio) -- vbum1=_deref_pbuc1 
    lda __conio
    sta return
    // wherex::@return
    // }
    // [1831] return 
    rts
  .segment Data
    return: .byte 0
}
.segment Code
  // wherey
// Return the y position of the cursor
wherey: {
    // return __conio.cursor_y;
    // [1832] wherey::return#0 = *((char *)&__conio+1) -- vbum1=_deref_pbuc1 
    lda __conio+1
    sta return
    // wherey::@return
    // }
    // [1833] return 
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
    // [1835] gotoxy::x#0 = cputcxy::x#15 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1836] gotoxy::y#0 = cputcxy::y#15 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1837] call gotoxy
    // [606] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [606] phi gotoxy::y#30 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [606] phi gotoxy::x#30 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [1838] stackpush(char) = cputcxy::c#15 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [1839] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [1841] return 
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
// void display_smc_led(__zp($c2) char c)
display_smc_led: {
    .label c = $c2
    // display_chip_led(CHIP_SMC_X+1, CHIP_SMC_Y, CHIP_SMC_W, c, BLUE)
    // [1843] display_chip_led::tc#0 = display_smc_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_chip_led.tc
    // [1844] call display_chip_led
    // [2390] phi from display_smc_led to display_chip_led [phi:display_smc_led->display_chip_led]
    // [2390] phi display_chip_led::w#7 = 5 [phi:display_smc_led->display_chip_led#0] -- vbuz1=vbuc1 
    lda #5
    sta.z display_chip_led.w
    // [2390] phi display_chip_led::x#7 = 1+1 [phi:display_smc_led->display_chip_led#1] -- vbuz1=vbuc1 
    lda #1+1
    sta.z display_chip_led.x
    // [2390] phi display_chip_led::tc#3 = display_chip_led::tc#0 [phi:display_smc_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_smc_led::@1
    // display_info_led(INFO_X-2, INFO_Y, c, BLUE)
    // [1845] display_info_led::tc#0 = display_smc_led::c#2
    // [1846] call display_info_led
    // [1605] phi from display_smc_led::@1 to display_info_led [phi:display_smc_led::@1->display_info_led]
    // [1605] phi display_info_led::y#4 = $11 [phi:display_smc_led::@1->display_info_led#0] -- vbuz1=vbuc1 
    lda #$11
    sta.z display_info_led.y
    // [1605] phi display_info_led::x#4 = 4-2 [phi:display_smc_led::@1->display_info_led#1] -- vbuz1=vbuc1 
    lda #4-2
    sta.z display_info_led.x
    // [1605] phi display_info_led::tc#4 = display_info_led::tc#0 [phi:display_smc_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_smc_led::@return
    // }
    // [1847] return 
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
// void display_print_chip(__mem() char x, char y, __mem() char w, __zp($be) char *text)
display_print_chip: {
    .label y = 3+2+1+1+1+1+1+1+1+1
    .label text = $be
    .label text_1 = $56
    .label text_2 = $3a
    .label text_3 = $c0
    .label text_6 = $e1
    // display_chip_line(x, y++, w, *text++)
    // [1849] display_chip_line::x#0 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [1850] display_chip_line::w#0 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_line.w
    // [1851] display_chip_line::c#0 = *display_print_chip::text#11 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_2),y
    sta display_chip_line.c
    // [1852] call display_chip_line
    // [2408] phi from display_print_chip to display_chip_line [phi:display_print_chip->display_chip_line]
    // [2408] phi display_chip_line::c#15 = display_chip_line::c#0 [phi:display_print_chip->display_chip_line#0] -- register_copy 
    // [2408] phi display_chip_line::w#10 = display_chip_line::w#0 [phi:display_print_chip->display_chip_line#1] -- register_copy 
    // [2408] phi display_chip_line::y#16 = 3+2 [phi:display_print_chip->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2
    sta display_chip_line.y
    // [2408] phi display_chip_line::x#16 = display_chip_line::x#0 [phi:display_print_chip->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@1
    // display_chip_line(x, y++, w, *text++);
    // [1853] display_print_chip::text#0 = ++ display_print_chip::text#11 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_2
    adc #1
    sta.z text
    lda.z text_2+1
    adc #0
    sta.z text+1
    // display_chip_line(x, y++, w, *text++)
    // [1854] display_chip_line::x#1 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [1855] display_chip_line::w#1 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_line.w
    // [1856] display_chip_line::c#1 = *display_print_chip::text#0 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text),y
    sta display_chip_line.c
    // [1857] call display_chip_line
    // [2408] phi from display_print_chip::@1 to display_chip_line [phi:display_print_chip::@1->display_chip_line]
    // [2408] phi display_chip_line::c#15 = display_chip_line::c#1 [phi:display_print_chip::@1->display_chip_line#0] -- register_copy 
    // [2408] phi display_chip_line::w#10 = display_chip_line::w#1 [phi:display_print_chip::@1->display_chip_line#1] -- register_copy 
    // [2408] phi display_chip_line::y#16 = ++3+2 [phi:display_print_chip::@1->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1
    sta display_chip_line.y
    // [2408] phi display_chip_line::x#16 = display_chip_line::x#1 [phi:display_print_chip::@1->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@2
    // display_chip_line(x, y++, w, *text++);
    // [1858] display_print_chip::text#1 = ++ display_print_chip::text#0 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text
    adc #1
    sta.z text_1
    lda.z text+1
    adc #0
    sta.z text_1+1
    // display_chip_line(x, y++, w, *text++)
    // [1859] display_chip_line::x#2 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [1860] display_chip_line::w#2 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_line.w
    // [1861] display_chip_line::c#2 = *display_print_chip::text#1 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_1),y
    sta display_chip_line.c
    // [1862] call display_chip_line
    // [2408] phi from display_print_chip::@2 to display_chip_line [phi:display_print_chip::@2->display_chip_line]
    // [2408] phi display_chip_line::c#15 = display_chip_line::c#2 [phi:display_print_chip::@2->display_chip_line#0] -- register_copy 
    // [2408] phi display_chip_line::w#10 = display_chip_line::w#2 [phi:display_print_chip::@2->display_chip_line#1] -- register_copy 
    // [2408] phi display_chip_line::y#16 = ++++3+2 [phi:display_print_chip::@2->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1
    sta display_chip_line.y
    // [2408] phi display_chip_line::x#16 = display_chip_line::x#2 [phi:display_print_chip::@2->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@3
    // display_chip_line(x, y++, w, *text++);
    // [1863] display_print_chip::text#15 = ++ display_print_chip::text#1 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_1
    adc #1
    sta.z text_3
    lda.z text_1+1
    adc #0
    sta.z text_3+1
    // display_chip_line(x, y++, w, *text++)
    // [1864] display_chip_line::x#3 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [1865] display_chip_line::w#3 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_line.w
    // [1866] display_chip_line::c#3 = *display_print_chip::text#15 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_3),y
    sta display_chip_line.c
    // [1867] call display_chip_line
    // [2408] phi from display_print_chip::@3 to display_chip_line [phi:display_print_chip::@3->display_chip_line]
    // [2408] phi display_chip_line::c#15 = display_chip_line::c#3 [phi:display_print_chip::@3->display_chip_line#0] -- register_copy 
    // [2408] phi display_chip_line::w#10 = display_chip_line::w#3 [phi:display_print_chip::@3->display_chip_line#1] -- register_copy 
    // [2408] phi display_chip_line::y#16 = ++++++3+2 [phi:display_print_chip::@3->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1
    sta display_chip_line.y
    // [2408] phi display_chip_line::x#16 = display_chip_line::x#3 [phi:display_print_chip::@3->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@4
    // display_chip_line(x, y++, w, *text++);
    // [1868] display_print_chip::text#16 = ++ display_print_chip::text#15 -- pbum1=_inc_pbuz2 
    clc
    lda.z text_3
    adc #1
    sta text_4
    lda.z text_3+1
    adc #0
    sta text_4+1
    // display_chip_line(x, y++, w, *text++)
    // [1869] display_chip_line::x#4 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [1870] display_chip_line::w#4 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_line.w
    // [1871] display_chip_line::c#4 = *display_print_chip::text#16 -- vbum1=_deref_pbum2 
    ldy text_4
    sty.z $fe
    ldy text_4+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta display_chip_line.c
    // [1872] call display_chip_line
    // [2408] phi from display_print_chip::@4 to display_chip_line [phi:display_print_chip::@4->display_chip_line]
    // [2408] phi display_chip_line::c#15 = display_chip_line::c#4 [phi:display_print_chip::@4->display_chip_line#0] -- register_copy 
    // [2408] phi display_chip_line::w#10 = display_chip_line::w#4 [phi:display_print_chip::@4->display_chip_line#1] -- register_copy 
    // [2408] phi display_chip_line::y#16 = ++++++++3+2 [phi:display_print_chip::@4->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1
    sta display_chip_line.y
    // [2408] phi display_chip_line::x#16 = display_chip_line::x#4 [phi:display_print_chip::@4->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@5
    // display_chip_line(x, y++, w, *text++);
    // [1873] display_print_chip::text#17 = ++ display_print_chip::text#16 -- pbum1=_inc_pbum2 
    clc
    lda text_4
    adc #1
    sta text_5
    lda text_4+1
    adc #0
    sta text_5+1
    // display_chip_line(x, y++, w, *text++)
    // [1874] display_chip_line::x#5 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [1875] display_chip_line::w#5 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_line.w
    // [1876] display_chip_line::c#5 = *display_print_chip::text#17 -- vbum1=_deref_pbum2 
    ldy text_5
    sty.z $fe
    ldy text_5+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta display_chip_line.c
    // [1877] call display_chip_line
    // [2408] phi from display_print_chip::@5 to display_chip_line [phi:display_print_chip::@5->display_chip_line]
    // [2408] phi display_chip_line::c#15 = display_chip_line::c#5 [phi:display_print_chip::@5->display_chip_line#0] -- register_copy 
    // [2408] phi display_chip_line::w#10 = display_chip_line::w#5 [phi:display_print_chip::@5->display_chip_line#1] -- register_copy 
    // [2408] phi display_chip_line::y#16 = ++++++++++3+2 [phi:display_print_chip::@5->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1+1
    sta display_chip_line.y
    // [2408] phi display_chip_line::x#16 = display_chip_line::x#5 [phi:display_print_chip::@5->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@6
    // display_chip_line(x, y++, w, *text++);
    // [1878] display_print_chip::text#18 = ++ display_print_chip::text#17 -- pbuz1=_inc_pbum2 
    clc
    lda text_5
    adc #1
    sta.z text_6
    lda text_5+1
    adc #0
    sta.z text_6+1
    // display_chip_line(x, y++, w, *text++)
    // [1879] display_chip_line::x#6 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [1880] display_chip_line::w#6 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_line.w
    // [1881] display_chip_line::c#6 = *display_print_chip::text#18 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta display_chip_line.c
    // [1882] call display_chip_line
    // [2408] phi from display_print_chip::@6 to display_chip_line [phi:display_print_chip::@6->display_chip_line]
    // [2408] phi display_chip_line::c#15 = display_chip_line::c#6 [phi:display_print_chip::@6->display_chip_line#0] -- register_copy 
    // [2408] phi display_chip_line::w#10 = display_chip_line::w#6 [phi:display_print_chip::@6->display_chip_line#1] -- register_copy 
    // [2408] phi display_chip_line::y#16 = ++++++++++++3+2 [phi:display_print_chip::@6->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1+1+1
    sta display_chip_line.y
    // [2408] phi display_chip_line::x#16 = display_chip_line::x#6 [phi:display_print_chip::@6->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@7
    // display_chip_line(x, y++, w, *text++);
    // [1883] display_print_chip::text#19 = ++ display_print_chip::text#18 -- pbuz1=_inc_pbuz1 
    inc.z text_6
    bne !+
    inc.z text_6+1
  !:
    // display_chip_line(x, y++, w, *text++)
    // [1884] display_chip_line::x#7 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [1885] display_chip_line::w#7 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_line.w
    // [1886] display_chip_line::c#7 = *display_print_chip::text#19 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta display_chip_line.c
    // [1887] call display_chip_line
    // [2408] phi from display_print_chip::@7 to display_chip_line [phi:display_print_chip::@7->display_chip_line]
    // [2408] phi display_chip_line::c#15 = display_chip_line::c#7 [phi:display_print_chip::@7->display_chip_line#0] -- register_copy 
    // [2408] phi display_chip_line::w#10 = display_chip_line::w#7 [phi:display_print_chip::@7->display_chip_line#1] -- register_copy 
    // [2408] phi display_chip_line::y#16 = ++++++++++++++3+2 [phi:display_print_chip::@7->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1+1+1+1
    sta display_chip_line.y
    // [2408] phi display_chip_line::x#16 = display_chip_line::x#7 [phi:display_print_chip::@7->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@8
    // display_chip_end(x, y++, w)
    // [1888] display_chip_end::x#0 = display_print_chip::x#10
    // [1889] display_chip_end::w#0 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_end.w
    // [1890] call display_chip_end
    jsr display_chip_end
    // display_print_chip::@return
    // }
    // [1891] return 
    rts
  .segment Data
    .label x = util_wait_key.return
    .label text_4 = rom_read_byte.rom_bank1_rom_read_byte__2
    .label text_5 = rom_read_byte.rom_ptr1_rom_read_byte__2
    .label w = main.check_status_card_roms1_check_status_rom1_main__0
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
    // [1893] display_chip_led::tc#1 = display_vera_led::c#2 -- vbuz1=vbum2 
    lda c
    sta.z display_chip_led.tc
    // [1894] call display_chip_led
    // [2390] phi from display_vera_led to display_chip_led [phi:display_vera_led->display_chip_led]
    // [2390] phi display_chip_led::w#7 = 8 [phi:display_vera_led->display_chip_led#0] -- vbuz1=vbuc1 
    lda #8
    sta.z display_chip_led.w
    // [2390] phi display_chip_led::x#7 = 9+1 [phi:display_vera_led->display_chip_led#1] -- vbuz1=vbuc1 
    lda #9+1
    sta.z display_chip_led.x
    // [2390] phi display_chip_led::tc#3 = display_chip_led::tc#1 [phi:display_vera_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_vera_led::@1
    // display_info_led(INFO_X-2, INFO_Y+1, c, BLUE)
    // [1895] display_info_led::tc#1 = display_vera_led::c#2 -- vbuz1=vbum2 
    lda c
    sta.z display_info_led.tc
    // [1896] call display_info_led
    // [1605] phi from display_vera_led::@1 to display_info_led [phi:display_vera_led::@1->display_info_led]
    // [1605] phi display_info_led::y#4 = $11+1 [phi:display_vera_led::@1->display_info_led#0] -- vbuz1=vbuc1 
    lda #$11+1
    sta.z display_info_led.y
    // [1605] phi display_info_led::x#4 = 4-2 [phi:display_vera_led::@1->display_info_led#1] -- vbuz1=vbuc1 
    lda #4-2
    sta.z display_info_led.x
    // [1605] phi display_info_led::tc#4 = display_info_led::tc#1 [phi:display_vera_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_vera_led::@return
    // }
    // [1897] return 
    rts
  .segment Data
    .label c = main.main__198
}
.segment Code
  // strcpy
// Copies the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcpy(char *destination, char *source)
strcpy: {
    .label dst = $e3
    .label src = $d8
    // [1899] phi from strcpy to strcpy::@1 [phi:strcpy->strcpy::@1]
    // [1899] phi strcpy::dst#2 = display_chip_rom::rom [phi:strcpy->strcpy::@1#0] -- pbuz1=pbuc1 
    lda #<display_chip_rom.rom
    sta.z dst
    lda #>display_chip_rom.rom
    sta.z dst+1
    // [1899] phi strcpy::src#2 = display_chip_rom::source [phi:strcpy->strcpy::@1#1] -- pbuz1=pbuc1 
    lda #<display_chip_rom.source
    sta.z src
    lda #>display_chip_rom.source
    sta.z src+1
    // strcpy::@1
  __b1:
    // while(*src)
    // [1900] if(0!=*strcpy::src#2) goto strcpy::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcpy::@3
    // *dst = 0
    // [1901] *strcpy::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcpy::@return
    // }
    // [1902] return 
    rts
    // strcpy::@2
  __b2:
    // *dst++ = *src++
    // [1903] *strcpy::dst#2 = *strcpy::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [1904] strcpy::dst#1 = ++ strcpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [1905] strcpy::src#1 = ++ strcpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [1899] phi from strcpy::@2 to strcpy::@1 [phi:strcpy::@2->strcpy::@1]
    // [1899] phi strcpy::dst#2 = strcpy::dst#1 [phi:strcpy::@2->strcpy::@1#0] -- register_copy 
    // [1899] phi strcpy::src#2 = strcpy::src#1 [phi:strcpy::@2->strcpy::@1#1] -- register_copy 
    jmp __b1
}
  // strcat
// Concatenates the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcat(char *destination, __zp($b7) char *source)
strcat: {
    .label strcat__0 = $df
    .label dst = $df
    .label src = $b7
    .label source = $b7
    // strlen(destination)
    // [1907] call strlen
    // [1938] phi from strcat to strlen [phi:strcat->strlen]
    // [1938] phi strlen::str#8 = display_chip_rom::rom [phi:strcat->strlen#0] -- pbuz1=pbuc1 
    lda #<display_chip_rom.rom
    sta.z strlen.str
    lda #>display_chip_rom.rom
    sta.z strlen.str+1
    jsr strlen
    // strlen(destination)
    // [1908] strlen::return#0 = strlen::len#2
    // strcat::@4
    // [1909] strcat::$0 = strlen::return#0 -- vwuz1=vwum2 
    lda strlen.return
    sta.z strcat__0
    lda strlen.return+1
    sta.z strcat__0+1
    // char* dst = destination + strlen(destination)
    // [1910] strcat::dst#0 = display_chip_rom::rom + strcat::$0 -- pbuz1=pbuc1_plus_vwuz1 
    lda.z dst
    clc
    adc #<display_chip_rom.rom
    sta.z dst
    lda.z dst+1
    adc #>display_chip_rom.rom
    sta.z dst+1
    // [1911] phi from strcat::@2 strcat::@4 to strcat::@1 [phi:strcat::@2/strcat::@4->strcat::@1]
    // [1911] phi strcat::dst#2 = strcat::dst#1 [phi:strcat::@2/strcat::@4->strcat::@1#0] -- register_copy 
    // [1911] phi strcat::src#2 = strcat::src#1 [phi:strcat::@2/strcat::@4->strcat::@1#1] -- register_copy 
    // strcat::@1
  __b1:
    // while(*src)
    // [1912] if(0!=*strcat::src#2) goto strcat::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcat::@3
    // *dst = 0
    // [1913] *strcat::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcat::@return
    // }
    // [1914] return 
    rts
    // strcat::@2
  __b2:
    // *dst++ = *src++
    // [1915] *strcat::dst#2 = *strcat::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [1916] strcat::dst#1 = ++ strcat::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [1917] strcat::src#1 = ++ strcat::src#2 -- pbuz1=_inc_pbuz1 
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
// void display_rom_led(__zp($43) char chip, __zp($29) char c)
display_rom_led: {
    .label display_rom_led__0 = $b2
    .label chip = $43
    .label c = $29
    .label display_rom_led__7 = $b2
    .label display_rom_led__8 = $b2
    // chip*6
    // [1919] display_rom_led::$7 = display_rom_led::chip#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z chip
    asl
    sta.z display_rom_led__7
    // [1920] display_rom_led::$8 = display_rom_led::$7 + display_rom_led::chip#2 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z display_rom_led__8
    clc
    adc.z chip
    sta.z display_rom_led__8
    // CHIP_ROM_X+chip*6
    // [1921] display_rom_led::$0 = display_rom_led::$8 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_rom_led__0
    // display_chip_led(CHIP_ROM_X+chip*6+1, CHIP_ROM_Y, CHIP_ROM_W, c, BLUE)
    // [1922] display_chip_led::x#3 = display_rom_led::$0 + $14+1 -- vbuz1=vbuz1_plus_vbuc1 
    lda #$14+1
    clc
    adc.z display_chip_led.x
    sta.z display_chip_led.x
    // [1923] display_chip_led::tc#2 = display_rom_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_chip_led.tc
    // [1924] call display_chip_led
    // [2390] phi from display_rom_led to display_chip_led [phi:display_rom_led->display_chip_led]
    // [2390] phi display_chip_led::w#7 = 3 [phi:display_rom_led->display_chip_led#0] -- vbuz1=vbuc1 
    lda #3
    sta.z display_chip_led.w
    // [2390] phi display_chip_led::x#7 = display_chip_led::x#3 [phi:display_rom_led->display_chip_led#1] -- register_copy 
    // [2390] phi display_chip_led::tc#3 = display_chip_led::tc#2 [phi:display_rom_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_rom_led::@1
    // display_info_led(INFO_X-2, INFO_Y+chip+2, c, BLUE)
    // [1925] display_info_led::y#2 = display_rom_led::chip#2 + $11+2 -- vbuz1=vbuz2_plus_vbuc1 
    lda #$11+2
    clc
    adc.z chip
    sta.z display_info_led.y
    // [1926] display_info_led::tc#2 = display_rom_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_info_led.tc
    // [1927] call display_info_led
    // [1605] phi from display_rom_led::@1 to display_info_led [phi:display_rom_led::@1->display_info_led]
    // [1605] phi display_info_led::y#4 = display_info_led::y#2 [phi:display_rom_led::@1->display_info_led#0] -- register_copy 
    // [1605] phi display_info_led::x#4 = 4-2 [phi:display_rom_led::@1->display_info_led#1] -- vbuz1=vbuc1 
    lda #4-2
    sta.z display_info_led.x
    // [1605] phi display_info_led::tc#4 = display_info_led::tc#2 [phi:display_rom_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_rom_led::@return
    // }
    // [1928] return 
    rts
}
  // display_progress_line
/**
 * @brief Print one line of text in the progress frame at a line position.
 * 
 * @param line The start line, counting from 0.
 * @param text The text to be displayed.
 */
// void display_progress_line(__zp($4c) char line, __zp($48) char *text)
display_progress_line: {
    .label line = $4c
    .label text = $48
    // cputsxy(PROGRESS_X, PROGRESS_Y+line, text)
    // [1929] cputsxy::y#0 = PROGRESS_Y + display_progress_line::line#0 -- vbum1=vbuc1_plus_vbuz2 
    lda #PROGRESS_Y
    clc
    adc.z line
    sta cputsxy.y
    // [1930] cputsxy::s#0 = display_progress_line::text#0
    // [1931] call cputsxy
    // [693] phi from display_progress_line to cputsxy [phi:display_progress_line->cputsxy]
    // [693] phi cputsxy::s#4 = cputsxy::s#0 [phi:display_progress_line->cputsxy#0] -- register_copy 
    // [693] phi cputsxy::y#4 = cputsxy::y#0 [phi:display_progress_line->cputsxy#1] -- register_copy 
    // [693] phi cputsxy::x#4 = PROGRESS_X [phi:display_progress_line->cputsxy#2] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta cputsxy.x
    jsr cputsxy
    // display_progress_line::@return
    // }
    // [1932] return 
    rts
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
    // [1933] cx16_k_i2c_read_byte::result = 0 -- vwum1=vwuc1 
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
    // [1935] cx16_k_i2c_read_byte::return#0 = cx16_k_i2c_read_byte::result -- vwum1=vwum2 
    sta return
    lda result+1
    sta return+1
    // cx16_k_i2c_read_byte::@return
    // }
    // [1936] cx16_k_i2c_read_byte::return#1 = cx16_k_i2c_read_byte::return#0
    // [1937] return 
    rts
  .segment Data
    device: .byte 0
    offset: .byte 0
    result: .word 0
    return: .word 0
}
.segment Code
  // strlen
// Computes the length of the string str up to but not including the terminating null character.
// __mem() unsigned int strlen(__zp($3a) char *str)
strlen: {
    .label str = $3a
    // [1939] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [1939] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta len
    sta len+1
    // [1939] phi strlen::str#6 = strlen::str#8 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [1940] if(0!=*strlen::str#6) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [1941] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [1942] strlen::len#1 = ++ strlen::len#2 -- vwum1=_inc_vwum1 
    inc len
    bne !+
    inc len+1
  !:
    // str++;
    // [1943] strlen::str#1 = ++ strlen::str#6 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [1939] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [1939] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [1939] phi strlen::str#6 = strlen::str#1 [phi:strlen::@2->strlen::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label return = len
    len: .word 0
}
.segment Code
  // printf_padding
// Print a padding char a number of times
// void printf_padding(__zp($48) void (*putc)(char), __mem() char pad, __mem() char length)
printf_padding: {
    .label putc = $48
    // [1945] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [1945] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbum1=vbuc1 
    lda #0
    sta i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [1946] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbum1_lt_vbum2_then_la1 
    lda i
    cmp length
    bcc __b2
    // printf_padding::@return
    // }
    // [1947] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [1948] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbum1 
    lda pad
    pha
    // [1949] callexecute *printf_padding::putc#7  -- call__deref_pprz1 
    jsr icall34
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [1951] printf_padding::i#1 = ++ printf_padding::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [1945] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [1945] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
    jmp __b1
    // Outside Flow
  icall34:
    jmp (putc)
  .segment Data
    i: .byte 0
    length: .byte 0
    pad: .byte 0
}
.segment Code
  // utoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void utoa(__mem() unsigned int value, __zp($48) char *buffer, __mem() char radix)
utoa: {
    .label utoa__4 = $50
    .label utoa__10 = $4f
    .label utoa__11 = $bd
    .label buffer = $48
    .label digit_values = $78
    // if(radix==DECIMAL)
    // [1952] if(utoa::radix#0==DECIMAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // utoa::@2
    // if(radix==HEXADECIMAL)
    // [1953] if(utoa::radix#0==HEXADECIMAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // utoa::@3
    // if(radix==OCTAL)
    // [1954] if(utoa::radix#0==OCTAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // utoa::@4
    // if(radix==BINARY)
    // [1955] if(utoa::radix#0==BINARY) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // utoa::@5
    // *buffer++ = 'e'
    // [1956] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1957] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1958] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1959] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // utoa::@return
    // }
    // [1960] return 
    rts
    // [1961] phi from utoa to utoa::@1 [phi:utoa->utoa::@1]
  __b2:
    // [1961] phi utoa::digit_values#8 = RADIX_DECIMAL_VALUES [phi:utoa->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_DECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES
    sta.z digit_values+1
    // [1961] phi utoa::max_digits#7 = 5 [phi:utoa->utoa::@1#1] -- vbum1=vbuc1 
    lda #5
    sta max_digits
    jmp __b1
    // [1961] phi from utoa::@2 to utoa::@1 [phi:utoa::@2->utoa::@1]
  __b3:
    // [1961] phi utoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES [phi:utoa::@2->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_HEXADECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES
    sta.z digit_values+1
    // [1961] phi utoa::max_digits#7 = 4 [phi:utoa::@2->utoa::@1#1] -- vbum1=vbuc1 
    lda #4
    sta max_digits
    jmp __b1
    // [1961] phi from utoa::@3 to utoa::@1 [phi:utoa::@3->utoa::@1]
  __b4:
    // [1961] phi utoa::digit_values#8 = RADIX_OCTAL_VALUES [phi:utoa::@3->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_OCTAL_VALUES
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES
    sta.z digit_values+1
    // [1961] phi utoa::max_digits#7 = 6 [phi:utoa::@3->utoa::@1#1] -- vbum1=vbuc1 
    lda #6
    sta max_digits
    jmp __b1
    // [1961] phi from utoa::@4 to utoa::@1 [phi:utoa::@4->utoa::@1]
  __b5:
    // [1961] phi utoa::digit_values#8 = RADIX_BINARY_VALUES [phi:utoa::@4->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_BINARY_VALUES
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES
    sta.z digit_values+1
    // [1961] phi utoa::max_digits#7 = $10 [phi:utoa::@4->utoa::@1#1] -- vbum1=vbuc1 
    lda #$10
    sta max_digits
    // utoa::@1
  __b1:
    // [1962] phi from utoa::@1 to utoa::@6 [phi:utoa::@1->utoa::@6]
    // [1962] phi utoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:utoa::@1->utoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1962] phi utoa::started#2 = 0 [phi:utoa::@1->utoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [1962] phi utoa::value#2 = utoa::value#1 [phi:utoa::@1->utoa::@6#2] -- register_copy 
    // [1962] phi utoa::digit#2 = 0 [phi:utoa::@1->utoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // utoa::@6
  __b6:
    // max_digits-1
    // [1963] utoa::$4 = utoa::max_digits#7 - 1 -- vbuz1=vbum2_minus_1 
    ldx max_digits
    dex
    stx.z utoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1964] if(utoa::digit#2<utoa::$4) goto utoa::@7 -- vbum1_lt_vbuz2_then_la1 
    lda digit
    cmp.z utoa__4
    bcc __b7
    // utoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1965] utoa::$11 = (char)utoa::value#2 -- vbuz1=_byte_vwum2 
    lda value
    sta.z utoa__11
    // [1966] *utoa::buffer#11 = DIGITS[utoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1967] utoa::buffer#3 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1968] *utoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // utoa::@7
  __b7:
    // unsigned int digit_value = digit_values[digit]
    // [1969] utoa::$10 = utoa::digit#2 << 1 -- vbuz1=vbum2_rol_1 
    lda digit
    asl
    sta.z utoa__10
    // [1970] utoa::digit_value#0 = utoa::digit_values#8[utoa::$10] -- vwum1=pwuz2_derefidx_vbuz3 
    tay
    lda (digit_values),y
    sta digit_value
    iny
    lda (digit_values),y
    sta digit_value+1
    // if (started || value >= digit_value)
    // [1971] if(0!=utoa::started#2) goto utoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // utoa::@12
    // [1972] if(utoa::value#2>=utoa::digit_value#0) goto utoa::@10 -- vwum1_ge_vwum2_then_la1 
    lda digit_value+1
    cmp value+1
    bne !+
    lda digit_value
    cmp value
    beq __b10
  !:
    bcc __b10
    // [1973] phi from utoa::@12 to utoa::@9 [phi:utoa::@12->utoa::@9]
    // [1973] phi utoa::buffer#14 = utoa::buffer#11 [phi:utoa::@12->utoa::@9#0] -- register_copy 
    // [1973] phi utoa::started#4 = utoa::started#2 [phi:utoa::@12->utoa::@9#1] -- register_copy 
    // [1973] phi utoa::value#6 = utoa::value#2 [phi:utoa::@12->utoa::@9#2] -- register_copy 
    // utoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1974] utoa::digit#1 = ++ utoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [1962] phi from utoa::@9 to utoa::@6 [phi:utoa::@9->utoa::@6]
    // [1962] phi utoa::buffer#11 = utoa::buffer#14 [phi:utoa::@9->utoa::@6#0] -- register_copy 
    // [1962] phi utoa::started#2 = utoa::started#4 [phi:utoa::@9->utoa::@6#1] -- register_copy 
    // [1962] phi utoa::value#2 = utoa::value#6 [phi:utoa::@9->utoa::@6#2] -- register_copy 
    // [1962] phi utoa::digit#2 = utoa::digit#1 [phi:utoa::@9->utoa::@6#3] -- register_copy 
    jmp __b6
    // utoa::@10
  __b10:
    // utoa_append(buffer++, value, digit_value)
    // [1975] utoa_append::buffer#0 = utoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z utoa_append.buffer
    lda.z buffer+1
    sta.z utoa_append.buffer+1
    // [1976] utoa_append::value#0 = utoa::value#2
    // [1977] utoa_append::sub#0 = utoa::digit_value#0
    // [1978] call utoa_append
    // [2469] phi from utoa::@10 to utoa_append [phi:utoa::@10->utoa_append]
    jsr utoa_append
    // utoa_append(buffer++, value, digit_value)
    // [1979] utoa_append::return#0 = utoa_append::value#2
    // utoa::@11
    // value = utoa_append(buffer++, value, digit_value)
    // [1980] utoa::value#0 = utoa_append::return#0
    // value = utoa_append(buffer++, value, digit_value);
    // [1981] utoa::buffer#4 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1973] phi from utoa::@11 to utoa::@9 [phi:utoa::@11->utoa::@9]
    // [1973] phi utoa::buffer#14 = utoa::buffer#4 [phi:utoa::@11->utoa::@9#0] -- register_copy 
    // [1973] phi utoa::started#4 = 1 [phi:utoa::@11->utoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [1973] phi utoa::value#6 = utoa::value#0 [phi:utoa::@11->utoa::@9#2] -- register_copy 
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
  // printf_number_buffer
// Print the contents of the number buffer using a specific format.
// This handles minimum length, zero-filling, and left/right justification from the format
// void printf_number_buffer(__zp($b5) void (*putc)(char), __mem() char buffer_sign, char *buffer_digits, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, char format_radix)
printf_number_buffer: {
    .label printf_number_buffer__19 = $c0
    .label putc = $b5
    // if(format.min_length)
    // [1983] if(0==printf_number_buffer::format_min_length#3) goto printf_number_buffer::@1 -- 0_eq_vbum1_then_la1 
    lda format_min_length
    beq __b5
    // [1984] phi from printf_number_buffer to printf_number_buffer::@5 [phi:printf_number_buffer->printf_number_buffer::@5]
    // printf_number_buffer::@5
    // strlen(buffer.digits)
    // [1985] call strlen
    // [1938] phi from printf_number_buffer::@5 to strlen [phi:printf_number_buffer::@5->strlen]
    // [1938] phi strlen::str#8 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@5->strlen#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str+1
    jsr strlen
    // strlen(buffer.digits)
    // [1986] strlen::return#3 = strlen::len#2
    // printf_number_buffer::@11
    // [1987] printf_number_buffer::$19 = strlen::return#3 -- vwuz1=vwum2 
    lda strlen.return
    sta.z printf_number_buffer__19
    lda strlen.return+1
    sta.z printf_number_buffer__19+1
    // signed char len = (signed char)strlen(buffer.digits)
    // [1988] printf_number_buffer::len#0 = (signed char)printf_number_buffer::$19 -- vbsm1=_sbyte_vwuz2 
    // There is a minimum length - work out the padding
    lda.z printf_number_buffer__19
    sta len
    // if(buffer.sign)
    // [1989] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@10 -- 0_eq_vbum1_then_la1 
    lda buffer_sign
    beq __b10
    // printf_number_buffer::@6
    // len++;
    // [1990] printf_number_buffer::len#1 = ++ printf_number_buffer::len#0 -- vbsm1=_inc_vbsm1 
    inc len
    // [1991] phi from printf_number_buffer::@11 printf_number_buffer::@6 to printf_number_buffer::@10 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10]
    // [1991] phi printf_number_buffer::len#2 = printf_number_buffer::len#0 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10#0] -- register_copy 
    // printf_number_buffer::@10
  __b10:
    // padding = (signed char)format.min_length - len
    // [1992] printf_number_buffer::padding#1 = (signed char)printf_number_buffer::format_min_length#3 - printf_number_buffer::len#2 -- vbsm1=vbsm2_minus_vbsm1 
    lda format_min_length
    sec
    sbc padding
    sta padding
    // if(padding<0)
    // [1993] if(printf_number_buffer::padding#1>=0) goto printf_number_buffer::@15 -- vbsm1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1995] phi from printf_number_buffer printf_number_buffer::@10 to printf_number_buffer::@1 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1]
  __b5:
    // [1995] phi printf_number_buffer::padding#10 = 0 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1#0] -- vbsm1=vbsc1 
    lda #0
    sta padding
    // [1994] phi from printf_number_buffer::@10 to printf_number_buffer::@15 [phi:printf_number_buffer::@10->printf_number_buffer::@15]
    // printf_number_buffer::@15
    // [1995] phi from printf_number_buffer::@15 to printf_number_buffer::@1 [phi:printf_number_buffer::@15->printf_number_buffer::@1]
    // [1995] phi printf_number_buffer::padding#10 = printf_number_buffer::padding#1 [phi:printf_number_buffer::@15->printf_number_buffer::@1#0] -- register_copy 
    // printf_number_buffer::@1
  __b1:
    // printf_number_buffer::@13
    // if(!format.justify_left && !format.zero_padding && padding)
    // [1996] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@2 -- 0_neq_vbum1_then_la1 
    lda format_zero_padding
    bne __b2
    // printf_number_buffer::@12
    // [1997] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@7 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b7
    jmp __b2
    // printf_number_buffer::@7
  __b7:
    // printf_padding(putc, ' ',(char)padding)
    // [1998] printf_padding::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1999] printf_padding::length#0 = (char)printf_number_buffer::padding#10 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [2000] call printf_padding
    // [1944] phi from printf_number_buffer::@7 to printf_padding [phi:printf_number_buffer::@7->printf_padding]
    // [1944] phi printf_padding::putc#7 = printf_padding::putc#0 [phi:printf_number_buffer::@7->printf_padding#0] -- register_copy 
    // [1944] phi printf_padding::pad#7 = ' ' [phi:printf_number_buffer::@7->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [1944] phi printf_padding::length#6 = printf_padding::length#0 [phi:printf_number_buffer::@7->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@2
  __b2:
    // if(buffer.sign)
    // [2001] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@3 -- 0_eq_vbum1_then_la1 
    lda buffer_sign
    beq __b3
    // printf_number_buffer::@8
    // putc(buffer.sign)
    // [2002] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbum1 
    pha
    // [2003] callexecute *printf_number_buffer::putc#10  -- call__deref_pprz1 
    jsr icall35
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@3
  __b3:
    // if(format.zero_padding && padding)
    // [2005] if(0==printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@4 -- 0_eq_vbum1_then_la1 
    lda format_zero_padding
    beq __b4
    // printf_number_buffer::@14
    // [2006] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@9 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b9
    jmp __b4
    // printf_number_buffer::@9
  __b9:
    // printf_padding(putc, '0',(char)padding)
    // [2007] printf_padding::putc#1 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [2008] printf_padding::length#1 = (char)printf_number_buffer::padding#10 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [2009] call printf_padding
    // [1944] phi from printf_number_buffer::@9 to printf_padding [phi:printf_number_buffer::@9->printf_padding]
    // [1944] phi printf_padding::putc#7 = printf_padding::putc#1 [phi:printf_number_buffer::@9->printf_padding#0] -- register_copy 
    // [1944] phi printf_padding::pad#7 = '0' [phi:printf_number_buffer::@9->printf_padding#1] -- vbum1=vbuc1 
    lda #'0'
    sta printf_padding.pad
    // [1944] phi printf_padding::length#6 = printf_padding::length#1 [phi:printf_number_buffer::@9->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@4
  __b4:
    // printf_str(putc, buffer.digits)
    // [2010] printf_str::putc#0 = printf_number_buffer::putc#10
    // [2011] call printf_str
    // [873] phi from printf_number_buffer::@4 to printf_str [phi:printf_number_buffer::@4->printf_str]
    // [873] phi printf_str::putc#73 = printf_str::putc#0 [phi:printf_number_buffer::@4->printf_str#0] -- register_copy 
    // [873] phi printf_str::s#73 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@return
    // }
    // [2012] return 
    rts
    // Outside Flow
  icall35:
    jmp (putc)
  .segment Data
    buffer_sign: .byte 0
    .label format_min_length = printf_uint.format_min_length
    .label format_zero_padding = printf_uint.format_zero_padding
    len: .byte 0
    .label padding = len
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
// void rom_unlock(__zp($5f) unsigned long address, __zp($6d) char unlock_code)
rom_unlock: {
    .label chip_address = $59
    .label address = $5f
    .label unlock_code = $6d
    // unsigned long chip_address = address & ROM_CHIP_MASK
    // [2014] rom_unlock::chip_address#0 = rom_unlock::address#5 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [2015] rom_write_byte::address#0 = rom_unlock::chip_address#0 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [2016] call rom_write_byte
  // This is a very important operation...
    // [2476] phi from rom_unlock to rom_write_byte [phi:rom_unlock->rom_write_byte]
    // [2476] phi rom_write_byte::value#10 = $aa [phi:rom_unlock->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$aa
    sta.z rom_write_byte.value
    // [2476] phi rom_write_byte::address#4 = rom_write_byte::address#0 [phi:rom_unlock->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@1
    // rom_write_byte(chip_address + 0x02AAA, 0x55)
    // [2017] rom_write_byte::address#1 = rom_unlock::chip_address#0 + $2aaa -- vduz1=vduz2_plus_vwuc1 
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
    // [2018] call rom_write_byte
    // [2476] phi from rom_unlock::@1 to rom_write_byte [phi:rom_unlock::@1->rom_write_byte]
    // [2476] phi rom_write_byte::value#10 = $55 [phi:rom_unlock::@1->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$55
    sta.z rom_write_byte.value
    // [2476] phi rom_write_byte::address#4 = rom_write_byte::address#1 [phi:rom_unlock::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@2
    // rom_write_byte(address, unlock_code)
    // [2019] rom_write_byte::address#2 = rom_unlock::address#5 -- vduz1=vduz2 
    lda.z address
    sta.z rom_write_byte.address
    lda.z address+1
    sta.z rom_write_byte.address+1
    lda.z address+2
    sta.z rom_write_byte.address+2
    lda.z address+3
    sta.z rom_write_byte.address+3
    // [2020] rom_write_byte::value#2 = rom_unlock::unlock_code#5 -- vbuz1=vbuz2 
    lda.z unlock_code
    sta.z rom_write_byte.value
    // [2021] call rom_write_byte
    // [2476] phi from rom_unlock::@2 to rom_write_byte [phi:rom_unlock::@2->rom_write_byte]
    // [2476] phi rom_write_byte::value#10 = rom_write_byte::value#2 [phi:rom_unlock::@2->rom_write_byte#0] -- register_copy 
    // [2476] phi rom_write_byte::address#4 = rom_write_byte::address#2 [phi:rom_unlock::@2->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@return
    // }
    // [2022] return 
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
// __zp($b2) char rom_read_byte(__zp($da) unsigned long address)
rom_read_byte: {
    .label rom_bank1_rom_read_byte__0 = $c7
    .label return = $b2
    .label address = $da
    // rom_read_byte::rom_bank1
    // BYTE2(address)
    // [2024] rom_read_byte::rom_bank1_$0 = byte2  rom_read_byte::address#2 -- vbuz1=_byte2_vduz2 
    lda.z address+2
    sta.z rom_bank1_rom_read_byte__0
    // BYTE1(address)
    // [2025] rom_read_byte::rom_bank1_$1 = byte1  rom_read_byte::address#2 -- vbum1=_byte1_vduz2 
    lda.z address+1
    sta rom_bank1_rom_read_byte__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2026] rom_read_byte::rom_bank1_$2 = rom_read_byte::rom_bank1_$0 w= rom_read_byte::rom_bank1_$1 -- vwum1=vbuz2_word_vbum3 
    lda.z rom_bank1_rom_read_byte__0
    sta rom_bank1_rom_read_byte__2+1
    lda rom_bank1_rom_read_byte__1
    sta rom_bank1_rom_read_byte__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2027] rom_read_byte::rom_bank1_bank_unshifted#0 = rom_read_byte::rom_bank1_$2 << 2 -- vwum1=vwum1_rol_2 
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2028] rom_read_byte::rom_bank1_return#0 = byte1  rom_read_byte::rom_bank1_bank_unshifted#0 -- vbum1=_byte1_vwum2 
    lda rom_bank1_bank_unshifted+1
    sta rom_bank1_return
    // rom_read_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2029] rom_read_byte::rom_ptr1_$2 = (unsigned int)rom_read_byte::address#2 -- vwum1=_word_vduz2 
    lda.z address
    sta rom_ptr1_rom_read_byte__2
    lda.z address+1
    sta rom_ptr1_rom_read_byte__2+1
    // [2030] rom_read_byte::rom_ptr1_$0 = rom_read_byte::rom_ptr1_$2 & $3fff -- vwum1=vwum1_band_vwuc1 
    lda rom_ptr1_rom_read_byte__0
    and #<$3fff
    sta rom_ptr1_rom_read_byte__0
    lda rom_ptr1_rom_read_byte__0+1
    and #>$3fff
    sta rom_ptr1_rom_read_byte__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2031] rom_read_byte::rom_ptr1_return#0 = rom_read_byte::rom_ptr1_$0 + $c000 -- vwum1=vwum1_plus_vwuc1 
    lda rom_ptr1_return
    clc
    adc #<$c000
    sta rom_ptr1_return
    lda rom_ptr1_return+1
    adc #>$c000
    sta rom_ptr1_return+1
    // rom_read_byte::bank_set_brom1
    // BROM = bank
    // [2032] BROM = rom_read_byte::rom_bank1_return#0 -- vbuz1=vbum2 
    lda rom_bank1_return
    sta.z BROM
    // rom_read_byte::@1
    // return *ptr_rom;
    // [2033] rom_read_byte::return#0 = *((char *)rom_read_byte::rom_ptr1_return#0) -- vbuz1=_deref_pbum2 
    ldy rom_ptr1_return
    sty.z $fe
    ldy rom_ptr1_return+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta.z return
    // rom_read_byte::@return
    // }
    // [2034] return 
    rts
  .segment Data
    rom_bank1_rom_read_byte__1: .byte 0
    rom_bank1_rom_read_byte__2: .word 0
    .label rom_ptr1_rom_read_byte__0 = rom_ptr1_rom_read_byte__2
    rom_ptr1_rom_read_byte__2: .word 0
    .label rom_bank1_bank_unshifted = rom_bank1_rom_read_byte__2
    rom_bank1_return: .byte 0
    .label rom_ptr1_return = rom_ptr1_rom_read_byte__2
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
// __zp($63) struct $2 * fopen(__zp($b3) const char *path, const char *mode)
fopen: {
    .label fopen__11 = $52
    .label fopen__15 = $ed
    .label fopen__16 = $54
    .label fopen__26 = $38
    .label fopen__28 = $e1
    .label fopen__30 = $63
    .label cbm_k_setnam1_fopen__0 = $b5
    .label stream = $63
    .label pathtoken = $b3
    .label pathtoken_1 = $e8
    .label path = $b3
    .label return = $63
    // unsigned char sp = __stdio_filecount
    // [2036] fopen::sp#0 = __stdio_filecount -- vbum1=vbum2 
    lda __stdio_filecount
    sta sp
    // (unsigned int)sp | 0x8000
    // [2037] fopen::$30 = (unsigned int)fopen::sp#0 -- vwuz1=_word_vbum2 
    sta.z fopen__30
    lda #0
    sta.z fopen__30+1
    // [2038] fopen::stream#0 = fopen::$30 | $8000 -- vwuz1=vwuz1_bor_vwuc1 
    lda.z stream
    ora #<$8000
    sta.z stream
    lda.z stream+1
    ora #>$8000
    sta.z stream+1
    // char pathpos = sp * __STDIO_FILECOUNT
    // [2039] fopen::pathpos#0 = fopen::sp#0 << 1 -- vbum1=vbum2_rol_1 
    lda sp
    asl
    sta pathpos
    // __logical = 0
    // [2040] ((char *)&__stdio_file+$40)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy sp
    sta __stdio_file+$40,y
    // __device = 0
    // [2041] ((char *)&__stdio_file+$42)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [2042] ((char *)&__stdio_file+$44)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$44,y
    // [2043] fopen::pathtoken#22 = fopen::pathtoken#0 -- pbuz1=pbuz2 
    lda.z pathtoken
    sta.z pathtoken_1
    lda.z pathtoken+1
    sta.z pathtoken_1+1
    // [2044] fopen::pathpos#21 = fopen::pathpos#0 -- vbum1=vbum2 
    lda pathpos
    sta pathpos_1
    // [2045] phi from fopen to fopen::@8 [phi:fopen->fopen::@8]
    // [2045] phi fopen::num#10 = 0 [phi:fopen->fopen::@8#0] -- vbum1=vbuc1 
    lda #0
    sta num
    // [2045] phi fopen::pathpos#10 = fopen::pathpos#21 [phi:fopen->fopen::@8#1] -- register_copy 
    // [2045] phi fopen::path#10 = fopen::pathtoken#0 [phi:fopen->fopen::@8#2] -- register_copy 
    // [2045] phi fopen::pathstep#10 = 0 [phi:fopen->fopen::@8#3] -- vbum1=vbuc1 
    sta pathstep
    // [2045] phi fopen::pathtoken#10 = fopen::pathtoken#22 [phi:fopen->fopen::@8#4] -- register_copy 
  // Iterate while path is not \0.
    // [2045] phi from fopen::@22 to fopen::@8 [phi:fopen::@22->fopen::@8]
    // [2045] phi fopen::num#10 = fopen::num#13 [phi:fopen::@22->fopen::@8#0] -- register_copy 
    // [2045] phi fopen::pathpos#10 = fopen::pathpos#7 [phi:fopen::@22->fopen::@8#1] -- register_copy 
    // [2045] phi fopen::path#10 = fopen::path#11 [phi:fopen::@22->fopen::@8#2] -- register_copy 
    // [2045] phi fopen::pathstep#10 = fopen::pathstep#11 [phi:fopen::@22->fopen::@8#3] -- register_copy 
    // [2045] phi fopen::pathtoken#10 = fopen::pathtoken#1 [phi:fopen::@22->fopen::@8#4] -- register_copy 
    // fopen::@8
  __b8:
    // if (*pathtoken == ',' || *pathtoken == '\0')
    // [2046] if(*fopen::pathtoken#10==',') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #','
    ldy #0
    cmp (pathtoken_1),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@33
    // [2047] if(*fopen::pathtoken#10=='@') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #'@'
    cmp (pathtoken_1),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@23
    // if (pathstep == 0)
    // [2048] if(fopen::pathstep#10!=0) goto fopen::@10 -- vbum1_neq_0_then_la1 
    lda pathstep
    bne __b10
    // fopen::@24
    // __stdio_file.filename[pathpos] = *pathtoken
    // [2049] ((char *)&__stdio_file)[fopen::pathpos#10] = *fopen::pathtoken#10 -- pbuc1_derefidx_vbum1=_deref_pbuz2 
    lda (pathtoken_1),y
    ldy pathpos_1
    sta __stdio_file,y
    // pathpos++;
    // [2050] fopen::pathpos#1 = ++ fopen::pathpos#10 -- vbum1=_inc_vbum1 
    inc pathpos_1
    // [2051] phi from fopen::@12 fopen::@23 fopen::@24 to fopen::@10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10]
    // [2051] phi fopen::num#13 = fopen::num#15 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#0] -- register_copy 
    // [2051] phi fopen::pathpos#7 = fopen::pathpos#10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#1] -- register_copy 
    // [2051] phi fopen::path#11 = fopen::path#13 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#2] -- register_copy 
    // [2051] phi fopen::pathstep#11 = fopen::pathstep#1 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#3] -- register_copy 
    // fopen::@10
  __b10:
    // pathtoken++;
    // [2052] fopen::pathtoken#1 = ++ fopen::pathtoken#10 -- pbuz1=_inc_pbuz1 
    inc.z pathtoken_1
    bne !+
    inc.z pathtoken_1+1
  !:
    // fopen::@22
    // pathtoken - 1
    // [2053] fopen::$28 = fopen::pathtoken#1 - 1 -- pbuz1=pbuz2_minus_1 
    lda.z pathtoken_1
    sec
    sbc #1
    sta.z fopen__28
    lda.z pathtoken_1+1
    sbc #0
    sta.z fopen__28+1
    // while (*(pathtoken - 1))
    // [2054] if(0!=*fopen::$28) goto fopen::@8 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (fopen__28),y
    cmp #0
    bne __b8
    // fopen::@26
    // __status = 0
    // [2055] ((char *)&__stdio_file+$46)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    tya
    ldy sp
    sta __stdio_file+$46,y
    // if(!__logical)
    // [2056] if(0!=((char *)&__stdio_file+$40)[fopen::sp#0]) goto fopen::@1 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$40,y
    cmp #0
    bne __b1
    // fopen::@27
    // __stdio_filecount+1
    // [2057] fopen::$4 = __stdio_filecount + 1 -- vbum1=vbum2_plus_1 
    lda __stdio_filecount
    inc
    sta fopen__4
    // __logical = __stdio_filecount+1
    // [2058] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::$4 -- pbuc1_derefidx_vbum1=vbum2 
    sta __stdio_file+$40,y
    // fopen::@1
  __b1:
    // if(!__device)
    // [2059] if(0!=((char *)&__stdio_file+$42)[fopen::sp#0]) goto fopen::@2 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    ldy sp
    lda __stdio_file+$42,y
    cmp #0
    bne __b2
    // fopen::@5
    // __device = 8
    // [2060] ((char *)&__stdio_file+$42)[fopen::sp#0] = 8 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #8
    sta __stdio_file+$42,y
    // fopen::@2
  __b2:
    // if(!__channel)
    // [2061] if(0!=((char *)&__stdio_file+$44)[fopen::sp#0]) goto fopen::@3 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    ldy sp
    lda __stdio_file+$44,y
    cmp #0
    bne __b3
    // fopen::@6
    // __stdio_filecount+2
    // [2062] fopen::$9 = __stdio_filecount + 2 -- vbum1=vbum2_plus_2 
    lda __stdio_filecount
    clc
    adc #2
    sta fopen__9
    // __channel = __stdio_filecount+2
    // [2063] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::$9 -- pbuc1_derefidx_vbum1=vbum2 
    sta __stdio_file+$44,y
    // fopen::@3
  __b3:
    // __filename
    // [2064] fopen::$11 = (char *)&__stdio_file + fopen::pathpos#0 -- pbuz1=pbuc1_plus_vbum2 
    lda pathpos
    clc
    adc #<__stdio_file
    sta.z fopen__11
    lda #>__stdio_file
    adc #0
    sta.z fopen__11+1
    // cbm_k_setnam(__filename)
    // [2065] fopen::cbm_k_setnam1_filename = fopen::$11 -- pbum1=pbuz2 
    lda.z fopen__11
    sta cbm_k_setnam1_filename
    lda.z fopen__11+1
    sta cbm_k_setnam1_filename+1
    // fopen::cbm_k_setnam1
    // strlen(filename)
    // [2066] strlen::str#4 = fopen::cbm_k_setnam1_filename -- pbuz1=pbum2 
    lda cbm_k_setnam1_filename
    sta.z strlen.str
    lda cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [2067] call strlen
    // [1938] phi from fopen::cbm_k_setnam1 to strlen [phi:fopen::cbm_k_setnam1->strlen]
    // [1938] phi strlen::str#8 = strlen::str#4 [phi:fopen::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [2068] strlen::return#11 = strlen::len#2
    // fopen::@31
    // [2069] fopen::cbm_k_setnam1_$0 = strlen::return#11 -- vwuz1=vwum2 
    lda strlen.return
    sta.z cbm_k_setnam1_fopen__0
    lda strlen.return+1
    sta.z cbm_k_setnam1_fopen__0+1
    // char filename_len = (char)strlen(filename)
    // [2070] fopen::cbm_k_setnam1_filename_len = (char)fopen::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
    lda.z cbm_k_setnam1_fopen__0
    sta cbm_k_setnam1_filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx cbm_k_setnam1_filename
    ldy cbm_k_setnam1_filename+1
    jsr CBM_SETNAM
    // fopen::@28
    // cbm_k_setlfs(__logical, __device, __channel)
    // [2072] cbm_k_setlfs::channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$40,y
    sta cbm_k_setlfs.channel
    // [2073] cbm_k_setlfs::device = ((char *)&__stdio_file+$42)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    lda __stdio_file+$42,y
    sta cbm_k_setlfs.device
    // [2074] cbm_k_setlfs::command = ((char *)&__stdio_file+$44)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    lda __stdio_file+$44,y
    sta cbm_k_setlfs.command
    // [2075] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // fopen::cbm_k_open1
    // asm
    // asm { jsrCBM_OPEN  }
    jsr CBM_OPEN
    // fopen::cbm_k_readst1
    // char status
    // [2077] fopen::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2079] fopen::cbm_k_readst1_return#0 = fopen::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // fopen::cbm_k_readst1_@return
    // }
    // [2080] fopen::cbm_k_readst1_return#1 = fopen::cbm_k_readst1_return#0
    // fopen::@29
    // cbm_k_readst()
    // [2081] fopen::$15 = fopen::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z fopen__15
    // __status = cbm_k_readst()
    // [2082] ((char *)&__stdio_file+$46)[fopen::sp#0] = fopen::$15 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // ferror(stream)
    // [2083] ferror::stream#0 = (struct $2 *)fopen::stream#0
    // [2084] call ferror
    jsr ferror
    // [2085] ferror::return#0 = ferror::return#1
    // fopen::@32
    // [2086] fopen::$16 = ferror::return#0 -- vwsz1=vwsm2 
    lda ferror.return
    sta.z fopen__16
    lda ferror.return+1
    sta.z fopen__16+1
    // if (ferror(stream))
    // [2087] if(0==fopen::$16) goto fopen::@4 -- 0_eq_vwsz1_then_la1 
    lda.z fopen__16
    ora.z fopen__16+1
    beq __b4
    // fopen::@7
    // cbm_k_close(__logical)
    // [2088] fopen::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$40,y
    sta cbm_k_close1_channel
    // fopen::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // [2090] phi from fopen::cbm_k_close1 to fopen::@return [phi:fopen::cbm_k_close1->fopen::@return]
    // [2090] phi fopen::return#2 = 0 [phi:fopen::cbm_k_close1->fopen::@return#0] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fopen::@return
    // }
    // [2091] return 
    rts
    // fopen::@4
  __b4:
    // __stdio_filecount++;
    // [2092] __stdio_filecount = ++ __stdio_filecount -- vbum1=_inc_vbum1 
    inc __stdio_filecount
    // [2093] fopen::return#8 = (struct $2 *)fopen::stream#0
    // [2090] phi from fopen::@4 to fopen::@return [phi:fopen::@4->fopen::@return]
    // [2090] phi fopen::return#2 = fopen::return#8 [phi:fopen::@4->fopen::@return#0] -- register_copy 
    rts
    // fopen::@9
  __b9:
    // if (pathstep > 0)
    // [2094] if(fopen::pathstep#10>0) goto fopen::@11 -- vbum1_gt_0_then_la1 
    lda pathstep
    bne __b11
    // fopen::@25
    // __stdio_file.filename[pathpos] = '\0'
    // [2095] ((char *)&__stdio_file)[fopen::pathpos#10] = '@' -- pbuc1_derefidx_vbum1=vbuc2 
    lda #'@'
    ldy pathpos_1
    sta __stdio_file,y
    // path = pathtoken + 1
    // [2096] fopen::path#0 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
    clc
    lda.z pathtoken_1
    adc #1
    sta.z path
    lda.z pathtoken_1+1
    adc #0
    sta.z path+1
    // [2097] phi from fopen::@16 fopen::@17 fopen::@18 fopen::@19 fopen::@25 to fopen::@12 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12]
    // [2097] phi fopen::num#15 = fopen::num#2 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#0] -- register_copy 
    // [2097] phi fopen::path#13 = fopen::path#16 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#1] -- register_copy 
    // fopen::@12
  __b12:
    // pathstep++;
    // [2098] fopen::pathstep#1 = ++ fopen::pathstep#10 -- vbum1=_inc_vbum1 
    inc pathstep
    jmp __b10
    // fopen::@11
  __b11:
    // char pathcmp = *path
    // [2099] fopen::pathcmp#0 = *fopen::path#10 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (path),y
    sta pathcmp
    // case 'D':
    // [2100] if(fopen::pathcmp#0=='D') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'D'
    cmp pathcmp
    beq __b13
    // fopen::@20
    // case 'L':
    // [2101] if(fopen::pathcmp#0=='L') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'L'
    cmp pathcmp
    beq __b13
    // fopen::@21
    // case 'C':
    //                     num = (char)atoi(path + 1);
    //                     path = pathtoken + 1;
    // [2102] if(fopen::pathcmp#0=='C') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'C'
    cmp pathcmp
    beq __b13
    // [2103] phi from fopen::@21 fopen::@30 to fopen::@14 [phi:fopen::@21/fopen::@30->fopen::@14]
    // [2103] phi fopen::path#16 = fopen::path#10 [phi:fopen::@21/fopen::@30->fopen::@14#0] -- register_copy 
    // [2103] phi fopen::num#2 = fopen::num#10 [phi:fopen::@21/fopen::@30->fopen::@14#1] -- register_copy 
    // fopen::@14
  __b14:
    // case 'L':
    //                     __logical = num;
    //                     break;
    // [2104] if(fopen::pathcmp#0=='L') goto fopen::@17 -- vbum1_eq_vbuc1_then_la1 
    lda #'L'
    cmp pathcmp
    beq __b17
    // fopen::@15
    // case 'D':
    //                     __device = num;
    //                     break;
    // [2105] if(fopen::pathcmp#0=='D') goto fopen::@18 -- vbum1_eq_vbuc1_then_la1 
    lda #'D'
    cmp pathcmp
    beq __b18
    // fopen::@16
    // case 'C':
    //                     __channel = num;
    //                     break;
    // [2106] if(fopen::pathcmp#0!='C') goto fopen::@12 -- vbum1_neq_vbuc1_then_la1 
    lda #'C'
    cmp pathcmp
    bne __b12
    // fopen::@19
    // __channel = num
    // [2107] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbum2 
    lda num
    ldy sp
    sta __stdio_file+$44,y
    jmp __b12
    // fopen::@18
  __b18:
    // __device = num
    // [2108] ((char *)&__stdio_file+$42)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbum2 
    lda num
    ldy sp
    sta __stdio_file+$42,y
    jmp __b12
    // fopen::@17
  __b17:
    // __logical = num
    // [2109] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbum2 
    lda num
    ldy sp
    sta __stdio_file+$40,y
    jmp __b12
    // fopen::@13
  __b13:
    // atoi(path + 1)
    // [2110] atoi::str#0 = fopen::path#10 + 1 -- pbuz1=pbuz1_plus_1 
    inc.z atoi.str
    bne !+
    inc.z atoi.str+1
  !:
    // [2111] call atoi
    // [2542] phi from fopen::@13 to atoi [phi:fopen::@13->atoi]
    // [2542] phi atoi::str#2 = atoi::str#0 [phi:fopen::@13->atoi#0] -- register_copy 
    jsr atoi
    // atoi(path + 1)
    // [2112] atoi::return#3 = atoi::return#2
    // fopen::@30
    // [2113] fopen::$26 = atoi::return#3 -- vwsz1=vwsm2 
    lda atoi.return
    sta.z fopen__26
    lda atoi.return+1
    sta.z fopen__26+1
    // num = (char)atoi(path + 1)
    // [2114] fopen::num#1 = (char)fopen::$26 -- vbum1=_byte_vwsz2 
    lda.z fopen__26
    sta num
    // path = pathtoken + 1
    // [2115] fopen::path#1 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
    clc
    lda.z pathtoken_1
    adc #1
    sta.z path
    lda.z pathtoken_1+1
    adc #0
    sta.z path+1
    jmp __b14
  .segment Data
    fopen__4: .byte 0
    fopen__9: .byte 0
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
// __mem() unsigned int fgets(__zp($7a) char *ptr, __mem() unsigned int size, __zp($ca) struct $2 *stream)
fgets: {
    .label fgets__1 = $d0
    .label fgets__8 = $7c
    .label fgets__9 = $7d
    .label fgets__13 = $4c
    .label ptr = $7a
    .label stream = $ca
    // unsigned char sp = (unsigned char)stream
    // [2117] fgets::sp#0 = (char)fgets::stream#2 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_chkin(__logical)
    // [2118] fgets::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fgets::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    tay
    lda __stdio_file+$40,y
    sta cbm_k_chkin1_channel
    // fgets::cbm_k_chkin1
    // char status
    // [2119] fgets::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fgets::cbm_k_readst1
    // char status
    // [2121] fgets::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2123] fgets::cbm_k_readst1_return#0 = fgets::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // fgets::cbm_k_readst1_@return
    // }
    // [2124] fgets::cbm_k_readst1_return#1 = fgets::cbm_k_readst1_return#0
    // fgets::@11
    // cbm_k_readst()
    // [2125] fgets::$1 = fgets::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z fgets__1
    // __status = cbm_k_readst()
    // [2126] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$1 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2127] if(0==((char *)&__stdio_file+$46)[fgets::sp#0]) goto fgets::@1 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b1
    // [2128] phi from fgets::@11 fgets::@12 fgets::@5 to fgets::@return [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return]
  __b8:
    // [2128] phi fgets::return#1 = 0 [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return#0] -- vwum1=vbuc1 
    lda #<0
    sta return
    sta return+1
    // fgets::@return
    // }
    // [2129] return 
    rts
    // fgets::@1
  __b1:
    // [2130] fgets::remaining#22 = fgets::size#10 -- vwum1=vwum2 
    lda size
    sta remaining
    lda size+1
    sta remaining+1
    // [2131] phi from fgets::@1 to fgets::@2 [phi:fgets::@1->fgets::@2]
    // [2131] phi fgets::read#10 = 0 [phi:fgets::@1->fgets::@2#0] -- vwum1=vwuc1 
    lda #<0
    sta read
    sta read+1
    // [2131] phi fgets::remaining#11 = fgets::remaining#22 [phi:fgets::@1->fgets::@2#1] -- register_copy 
    // [2131] phi fgets::ptr#10 = fgets::ptr#12 [phi:fgets::@1->fgets::@2#2] -- register_copy 
    // [2131] phi from fgets::@17 fgets::@18 to fgets::@2 [phi:fgets::@17/fgets::@18->fgets::@2]
    // [2131] phi fgets::read#10 = fgets::read#1 [phi:fgets::@17/fgets::@18->fgets::@2#0] -- register_copy 
    // [2131] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@17/fgets::@18->fgets::@2#1] -- register_copy 
    // [2131] phi fgets::ptr#10 = fgets::ptr#13 [phi:fgets::@17/fgets::@18->fgets::@2#2] -- register_copy 
    // fgets::@2
  __b2:
    // if (!size)
    // [2132] if(0==fgets::size#10) goto fgets::@3 -- 0_eq_vwum1_then_la1 
    lda size
    ora size+1
    bne !__b3+
    jmp __b3
  !__b3:
    // fgets::@8
    // if (remaining >= 512)
    // [2133] if(fgets::remaining#11>=$200) goto fgets::@4 -- vwum1_ge_vwuc1_then_la1 
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
    // [2134] cx16_k_macptr::bytes = fgets::remaining#11 -- vbum1=vwum2 
    lda remaining
    sta cx16_k_macptr.bytes
    // [2135] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2136] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2137] cx16_k_macptr::return#4 = cx16_k_macptr::return#1
    // fgets::@15
  __b15:
    // bytes = cx16_k_macptr(remaining, ptr)
    // [2138] fgets::bytes#3 = cx16_k_macptr::return#4
    // [2139] phi from fgets::@13 fgets::@14 fgets::@15 to fgets::cbm_k_readst2 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2]
    // [2139] phi fgets::bytes#10 = fgets::bytes#1 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2#0] -- register_copy 
    // fgets::cbm_k_readst2
    // char status
    // [2140] fgets::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [2142] fgets::cbm_k_readst2_return#0 = fgets::cbm_k_readst2_status -- vbum1=vbum2 
    sta cbm_k_readst2_return
    // fgets::cbm_k_readst2_@return
    // }
    // [2143] fgets::cbm_k_readst2_return#1 = fgets::cbm_k_readst2_return#0
    // fgets::@12
    // cbm_k_readst()
    // [2144] fgets::$8 = fgets::cbm_k_readst2_return#1 -- vbuz1=vbum2 
    sta.z fgets__8
    // __status = cbm_k_readst()
    // [2145] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$8 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // __status & 0xBF
    // [2146] fgets::$9 = ((char *)&__stdio_file+$46)[fgets::sp#0] & $bf -- vbuz1=pbuc1_derefidx_vbum2_band_vbuc2 
    lda #$bf
    and __stdio_file+$46,y
    sta.z fgets__9
    // if (__status & 0xBF)
    // [2147] if(0==fgets::$9) goto fgets::@5 -- 0_eq_vbuz1_then_la1 
    beq __b5
    jmp __b8
    // fgets::@5
  __b5:
    // if (bytes == 0xFFFF)
    // [2148] if(fgets::bytes#10!=$ffff) goto fgets::@6 -- vwum1_neq_vwuc1_then_la1 
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
    // [2149] fgets::read#1 = fgets::read#10 + fgets::bytes#10 -- vwum1=vwum1_plus_vwum2 
    clc
    lda read
    adc bytes
    sta read
    lda read+1
    adc bytes+1
    sta read+1
    // ptr += bytes
    // [2150] fgets::ptr#0 = fgets::ptr#10 + fgets::bytes#10 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z ptr
    adc bytes
    sta.z ptr
    lda.z ptr+1
    adc bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [2151] fgets::$13 = byte1  fgets::ptr#0 -- vbuz1=_byte1_pbuz2 
    sta.z fgets__13
    // if (BYTE1(ptr) == 0xC0)
    // [2152] if(fgets::$13!=$c0) goto fgets::@7 -- vbuz1_neq_vbuc1_then_la1 
    lda #$c0
    cmp.z fgets__13
    bne __b7
    // fgets::@10
    // ptr -= 0x2000
    // [2153] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [2154] phi from fgets::@10 fgets::@6 to fgets::@7 [phi:fgets::@10/fgets::@6->fgets::@7]
    // [2154] phi fgets::ptr#13 = fgets::ptr#1 [phi:fgets::@10/fgets::@6->fgets::@7#0] -- register_copy 
    // fgets::@7
  __b7:
    // remaining -= bytes
    // [2155] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#10 -- vwum1=vwum1_minus_vwum2 
    lda remaining
    sec
    sbc bytes
    sta remaining
    lda remaining+1
    sbc bytes+1
    sta remaining+1
    // while ((__status == 0) && ((size && remaining) || !size))
    // [2156] if(((char *)&__stdio_file+$46)[fgets::sp#0]==0) goto fgets::@16 -- pbuc1_derefidx_vbum1_eq_0_then_la1 
    ldy sp
    lda __stdio_file+$46,y
    cmp #0
    beq __b16
    // [2128] phi from fgets::@17 fgets::@7 to fgets::@return [phi:fgets::@17/fgets::@7->fgets::@return]
    // [2128] phi fgets::return#1 = fgets::read#1 [phi:fgets::@17/fgets::@7->fgets::@return#0] -- register_copy 
    rts
    // fgets::@16
  __b16:
    // while ((__status == 0) && ((size && remaining) || !size))
    // [2157] if(0==fgets::size#10) goto fgets::@17 -- 0_eq_vwum1_then_la1 
    lda size
    ora size+1
    beq __b17
    // fgets::@18
    // [2158] if(0!=fgets::remaining#1) goto fgets::@2 -- 0_neq_vwum1_then_la1 
    lda remaining
    ora remaining+1
    beq !__b2+
    jmp __b2
  !__b2:
    // fgets::@17
  __b17:
    // [2159] if(0==fgets::size#10) goto fgets::@2 -- 0_eq_vwum1_then_la1 
    lda size
    ora size+1
    bne !__b2+
    jmp __b2
  !__b2:
    rts
    // fgets::@4
  __b4:
    // cx16_k_macptr(512, ptr)
    // [2160] cx16_k_macptr::bytes = $200 -- vbum1=vwuc1 
    lda #<$200
    sta cx16_k_macptr.bytes
    // [2161] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2162] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2163] cx16_k_macptr::return#3 = cx16_k_macptr::return#1
    // fgets::@14
    // bytes = cx16_k_macptr(512, ptr)
    // [2164] fgets::bytes#2 = cx16_k_macptr::return#3
    jmp __b15
    // fgets::@3
  __b3:
    // cx16_k_macptr(0, ptr)
    // [2165] cx16_k_macptr::bytes = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_macptr.bytes
    // [2166] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2167] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2168] cx16_k_macptr::return#2 = cx16_k_macptr::return#1
    // fgets::@13
    // bytes = cx16_k_macptr(0, ptr)
    // [2169] fgets::bytes#1 = cx16_k_macptr::return#2
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
    .label fclose__1 = $d0
    .label fclose__4 = $7c
    .label fclose__6 = $7d
    .label stream = $46
    // unsigned char sp = (unsigned char)stream
    // [2171] fclose::sp#0 = (char)fclose::stream#2 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_chkin(__logical)
    // [2172] fclose::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    tay
    lda __stdio_file+$40,y
    sta cbm_k_chkin1_channel
    // fclose::cbm_k_chkin1
    // char status
    // [2173] fclose::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fclose::cbm_k_readst1
    // char status
    // [2175] fclose::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2177] fclose::cbm_k_readst1_return#0 = fclose::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // fclose::cbm_k_readst1_@return
    // }
    // [2178] fclose::cbm_k_readst1_return#1 = fclose::cbm_k_readst1_return#0
    // fclose::@3
    // cbm_k_readst()
    // [2179] fclose::$1 = fclose::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z fclose__1
    // __status = cbm_k_readst()
    // [2180] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$1 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2181] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@1 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b1
    // fclose::@return
    // }
    // [2182] return 
    rts
    // fclose::@1
  __b1:
    // cbm_k_close(__logical)
    // [2183] fclose::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$40,y
    sta cbm_k_close1_channel
    // fclose::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // fclose::cbm_k_readst2
    // char status
    // [2185] fclose::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [2187] fclose::cbm_k_readst2_return#0 = fclose::cbm_k_readst2_status -- vbum1=vbum2 
    sta cbm_k_readst2_return
    // fclose::cbm_k_readst2_@return
    // }
    // [2188] fclose::cbm_k_readst2_return#1 = fclose::cbm_k_readst2_return#0
    // fclose::@4
    // cbm_k_readst()
    // [2189] fclose::$4 = fclose::cbm_k_readst2_return#1 -- vbuz1=vbum2 
    sta.z fclose__4
    // __status = cbm_k_readst()
    // [2190] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$4 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2191] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@2 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b2
    rts
    // fclose::@2
  __b2:
    // __logical = 0
    // [2192] ((char *)&__stdio_file+$40)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy sp
    sta __stdio_file+$40,y
    // __device = 0
    // [2193] ((char *)&__stdio_file+$42)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [2194] ((char *)&__stdio_file+$44)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$44,y
    // __filename
    // [2195] fclose::$6 = fclose::sp#0 << 1 -- vbuz1=vbum2_rol_1 
    tya
    asl
    sta.z fclose__6
    // *__filename = '\0'
    // [2196] ((char *)&__stdio_file)[fclose::$6] = '@' -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #'@'
    ldy.z fclose__6
    sta __stdio_file,y
    // __stdio_filecount--;
    // [2197] __stdio_filecount = -- __stdio_filecount -- vbum1=_dec_vbum1 
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
    .label uctoa__4 = $4c
    .label buffer = $46
    .label digit_values = $63
    // if(radix==DECIMAL)
    // [2198] if(uctoa::radix#0==DECIMAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // uctoa::@2
    // if(radix==HEXADECIMAL)
    // [2199] if(uctoa::radix#0==HEXADECIMAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // uctoa::@3
    // if(radix==OCTAL)
    // [2200] if(uctoa::radix#0==OCTAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // uctoa::@4
    // if(radix==BINARY)
    // [2201] if(uctoa::radix#0==BINARY) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // uctoa::@5
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
    // uctoa::@return
    // }
    // [2206] return 
    rts
    // [2207] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
  __b2:
    // [2207] phi uctoa::digit_values#8 = RADIX_DECIMAL_VALUES_CHAR [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [2207] phi uctoa::max_digits#7 = 3 [phi:uctoa->uctoa::@1#1] -- vbum1=vbuc1 
    lda #3
    sta max_digits
    jmp __b1
    // [2207] phi from uctoa::@2 to uctoa::@1 [phi:uctoa::@2->uctoa::@1]
  __b3:
    // [2207] phi uctoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_CHAR [phi:uctoa::@2->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [2207] phi uctoa::max_digits#7 = 2 [phi:uctoa::@2->uctoa::@1#1] -- vbum1=vbuc1 
    lda #2
    sta max_digits
    jmp __b1
    // [2207] phi from uctoa::@3 to uctoa::@1 [phi:uctoa::@3->uctoa::@1]
  __b4:
    // [2207] phi uctoa::digit_values#8 = RADIX_OCTAL_VALUES_CHAR [phi:uctoa::@3->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values+1
    // [2207] phi uctoa::max_digits#7 = 3 [phi:uctoa::@3->uctoa::@1#1] -- vbum1=vbuc1 
    lda #3
    sta max_digits
    jmp __b1
    // [2207] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
  __b5:
    // [2207] phi uctoa::digit_values#8 = RADIX_BINARY_VALUES_CHAR [phi:uctoa::@4->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_BINARY_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_CHAR
    sta.z digit_values+1
    // [2207] phi uctoa::max_digits#7 = 8 [phi:uctoa::@4->uctoa::@1#1] -- vbum1=vbuc1 
    lda #8
    sta max_digits
    // uctoa::@1
  __b1:
    // [2208] phi from uctoa::@1 to uctoa::@6 [phi:uctoa::@1->uctoa::@6]
    // [2208] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa::@1->uctoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2208] phi uctoa::started#2 = 0 [phi:uctoa::@1->uctoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [2208] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa::@1->uctoa::@6#2] -- register_copy 
    // [2208] phi uctoa::digit#2 = 0 [phi:uctoa::@1->uctoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // uctoa::@6
  __b6:
    // max_digits-1
    // [2209] uctoa::$4 = uctoa::max_digits#7 - 1 -- vbuz1=vbum2_minus_1 
    ldx max_digits
    dex
    stx.z uctoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2210] if(uctoa::digit#2<uctoa::$4) goto uctoa::@7 -- vbum1_lt_vbuz2_then_la1 
    lda digit
    cmp.z uctoa__4
    bcc __b7
    // uctoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2211] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy value
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2212] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2213] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // uctoa::@7
  __b7:
    // unsigned char digit_value = digit_values[digit]
    // [2214] uctoa::digit_value#0 = uctoa::digit_values#8[uctoa::digit#2] -- vbum1=pbuz2_derefidx_vbum3 
    ldy digit
    lda (digit_values),y
    sta digit_value
    // if (started || value >= digit_value)
    // [2215] if(0!=uctoa::started#2) goto uctoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // uctoa::@12
    // [2216] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@10 -- vbum1_ge_vbum2_then_la1 
    lda value
    cmp digit_value
    bcs __b10
    // [2217] phi from uctoa::@12 to uctoa::@9 [phi:uctoa::@12->uctoa::@9]
    // [2217] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@12->uctoa::@9#0] -- register_copy 
    // [2217] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@12->uctoa::@9#1] -- register_copy 
    // [2217] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@12->uctoa::@9#2] -- register_copy 
    // uctoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2218] uctoa::digit#1 = ++ uctoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [2208] phi from uctoa::@9 to uctoa::@6 [phi:uctoa::@9->uctoa::@6]
    // [2208] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@9->uctoa::@6#0] -- register_copy 
    // [2208] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@9->uctoa::@6#1] -- register_copy 
    // [2208] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@9->uctoa::@6#2] -- register_copy 
    // [2208] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@9->uctoa::@6#3] -- register_copy 
    jmp __b6
    // uctoa::@10
  __b10:
    // uctoa_append(buffer++, value, digit_value)
    // [2219] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [2220] uctoa_append::value#0 = uctoa::value#2
    // [2221] uctoa_append::sub#0 = uctoa::digit_value#0
    // [2222] call uctoa_append
    // [2563] phi from uctoa::@10 to uctoa_append [phi:uctoa::@10->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [2223] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@11
    // value = uctoa_append(buffer++, value, digit_value)
    // [2224] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [2225] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2217] phi from uctoa::@11 to uctoa::@9 [phi:uctoa::@11->uctoa::@9]
    // [2217] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@11->uctoa::@9#0] -- register_copy 
    // [2217] phi uctoa::started#4 = 1 [phi:uctoa::@11->uctoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [2217] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@11->uctoa::@9#2] -- register_copy 
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
    .label rom_address_from_bank__1 = $da
    .label return = $da
    .label return_1 = $65
    // ((unsigned long)(rom_bank)) << 14
    // [2227] rom_address_from_bank::$1 = (unsigned long)rom_address_from_bank::rom_bank#3 -- vduz1=_dword_vbum2 
    lda rom_bank
    sta.z rom_address_from_bank__1
    lda #0
    sta.z rom_address_from_bank__1+1
    sta.z rom_address_from_bank__1+2
    sta.z rom_address_from_bank__1+3
    // [2228] rom_address_from_bank::return#0 = rom_address_from_bank::$1 << $e -- vduz1=vduz1_rol_vbuc1 
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
    // [2229] return 
    rts
  .segment Data
    .label rom_bank = smc_detect.smc_detect__1
    .label return_2 = main.flashed_bytes
}
.segment Code
  // rom_compare
// __zp($63) unsigned int rom_compare(__zp($f1) char bank_ram, __zp($70) char *ptr_ram, __zp($c3) unsigned long rom_compare_address, __zp($af) unsigned int rom_compare_size)
rom_compare: {
    .label rom_compare__5 = $3c
    .label rom_bank1_rom_compare__0 = $4d
    .label rom_bank1_rom_compare__1 = $6d
    .label rom_bank1_rom_compare__2 = $b5
    .label rom_ptr1_rom_compare__0 = $5d
    .label rom_ptr1_rom_compare__2 = $5d
    .label rom_bank1_bank_unshifted = $b5
    .label rom_bank1_return = $4e
    .label rom_ptr1_return = $5d
    .label ptr_rom = $5d
    .label ptr_ram = $70
    .label compared_bytes = $69
    /// Holds the amount of bytes actually verified between the ROM and the RAM.
    .label equal_bytes = $63
    .label bank_ram = $f1
    .label rom_compare_address = $c3
    .label return = $63
    .label bank_ram_1 = $d5
    .label rom_compare_size = $af
    // rom_compare::bank_set_bram1
    // BRAM = bank
    // [2231] BRAM = rom_compare::bank_set_bram1_bank#0 -- vbuz1=vbum2 
    lda bank_set_bram1_bank
    sta.z BRAM
    // rom_compare::rom_bank1
    // BYTE2(address)
    // [2232] rom_compare::rom_bank1_$0 = byte2  rom_compare::rom_compare_address#3 -- vbuz1=_byte2_vduz2 
    lda.z rom_compare_address+2
    sta.z rom_bank1_rom_compare__0
    // BYTE1(address)
    // [2233] rom_compare::rom_bank1_$1 = byte1  rom_compare::rom_compare_address#3 -- vbuz1=_byte1_vduz2 
    lda.z rom_compare_address+1
    sta.z rom_bank1_rom_compare__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2234] rom_compare::rom_bank1_$2 = rom_compare::rom_bank1_$0 w= rom_compare::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_compare__0
    sta.z rom_bank1_rom_compare__2+1
    lda.z rom_bank1_rom_compare__1
    sta.z rom_bank1_rom_compare__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2235] rom_compare::rom_bank1_bank_unshifted#0 = rom_compare::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2236] rom_compare::rom_bank1_return#0 = byte1  rom_compare::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwuz2 
    lda.z rom_bank1_bank_unshifted+1
    sta.z rom_bank1_return
    // rom_compare::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2237] rom_compare::rom_ptr1_$2 = (unsigned int)rom_compare::rom_compare_address#3 -- vwuz1=_word_vduz2 
    lda.z rom_compare_address
    sta.z rom_ptr1_rom_compare__2
    lda.z rom_compare_address+1
    sta.z rom_ptr1_rom_compare__2+1
    // [2238] rom_compare::rom_ptr1_$0 = rom_compare::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_compare__0
    and #<$3fff
    sta.z rom_ptr1_rom_compare__0
    lda.z rom_ptr1_rom_compare__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_compare__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2239] rom_compare::rom_ptr1_return#0 = rom_compare::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_compare::bank_set_brom1
    // BROM = bank
    // [2240] BROM = rom_compare::rom_bank1_return#0 -- vbuz1=vbuz2 
    lda.z rom_bank1_return
    sta.z BROM
    // [2241] rom_compare::ptr_rom#9 = (char *)rom_compare::rom_ptr1_return#0
    // [2242] phi from rom_compare::bank_set_brom1 to rom_compare::@1 [phi:rom_compare::bank_set_brom1->rom_compare::@1]
    // [2242] phi rom_compare::equal_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z equal_bytes
    sta.z equal_bytes+1
    // [2242] phi rom_compare::ptr_ram#4 = rom_compare::ptr_ram#10 [phi:rom_compare::bank_set_brom1->rom_compare::@1#1] -- register_copy 
    // [2242] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#9 [phi:rom_compare::bank_set_brom1->rom_compare::@1#2] -- register_copy 
    // [2242] phi rom_compare::compared_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#3] -- vwuz1=vwuc1 
    sta.z compared_bytes
    sta.z compared_bytes+1
    // rom_compare::@1
  __b1:
    // while (compared_bytes < rom_compare_size)
    // [2243] if(rom_compare::compared_bytes#2<rom_compare::rom_compare_size#11) goto rom_compare::@2 -- vwuz1_lt_vwuz2_then_la1 
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
    // [2244] return 
    rts
    // rom_compare::@2
  __b2:
    // rom_byte_compare(ptr_rom, *ptr_ram)
    // [2245] rom_byte_compare::ptr_rom#0 = rom_compare::ptr_rom#2
    // [2246] rom_byte_compare::value#0 = *rom_compare::ptr_ram#4 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (ptr_ram),y
    sta.z rom_byte_compare.value
    // [2247] call rom_byte_compare
    jsr rom_byte_compare
    // [2248] rom_byte_compare::return#2 = rom_byte_compare::return#0
    // rom_compare::@5
    // [2249] rom_compare::$5 = rom_byte_compare::return#2
    // if (rom_byte_compare(ptr_rom, *ptr_ram))
    // [2250] if(0==rom_compare::$5) goto rom_compare::@3 -- 0_eq_vbuz1_then_la1 
    lda.z rom_compare__5
    beq __b3
    // rom_compare::@4
    // equal_bytes++;
    // [2251] rom_compare::equal_bytes#1 = ++ rom_compare::equal_bytes#2 -- vwuz1=_inc_vwuz1 
    inc.z equal_bytes
    bne !+
    inc.z equal_bytes+1
  !:
    // [2252] phi from rom_compare::@4 rom_compare::@5 to rom_compare::@3 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3]
    // [2252] phi rom_compare::equal_bytes#6 = rom_compare::equal_bytes#1 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3#0] -- register_copy 
    // rom_compare::@3
  __b3:
    // ptr_rom++;
    // [2253] rom_compare::ptr_rom#1 = ++ rom_compare::ptr_rom#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr_rom
    bne !+
    inc.z ptr_rom+1
  !:
    // ptr_ram++;
    // [2254] rom_compare::ptr_ram#0 = ++ rom_compare::ptr_ram#4 -- pbuz1=_inc_pbuz1 
    inc.z ptr_ram
    bne !+
    inc.z ptr_ram+1
  !:
    // compared_bytes++;
    // [2255] rom_compare::compared_bytes#1 = ++ rom_compare::compared_bytes#2 -- vwuz1=_inc_vwuz1 
    inc.z compared_bytes
    bne !+
    inc.z compared_bytes+1
  !:
    // [2242] phi from rom_compare::@3 to rom_compare::@1 [phi:rom_compare::@3->rom_compare::@1]
    // [2242] phi rom_compare::equal_bytes#2 = rom_compare::equal_bytes#6 [phi:rom_compare::@3->rom_compare::@1#0] -- register_copy 
    // [2242] phi rom_compare::ptr_ram#4 = rom_compare::ptr_ram#0 [phi:rom_compare::@3->rom_compare::@1#1] -- register_copy 
    // [2242] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#1 [phi:rom_compare::@3->rom_compare::@1#2] -- register_copy 
    // [2242] phi rom_compare::compared_bytes#2 = rom_compare::compared_bytes#1 [phi:rom_compare::@3->rom_compare::@1#3] -- register_copy 
    jmp __b1
  .segment Data
    bank_set_bram1_bank: .byte 0
}
.segment Code
  // ultoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void ultoa(__mem() unsigned long value, __zp($4a) char *buffer, __mem() char radix)
ultoa: {
    .label ultoa__4 = $4d
    .label ultoa__10 = $4e
    .label ultoa__11 = $6d
    .label buffer = $4a
    .label digit_values = $76
    // if(radix==DECIMAL)
    // [2256] if(ultoa::radix#0==DECIMAL) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // ultoa::@2
    // if(radix==HEXADECIMAL)
    // [2257] if(ultoa::radix#0==HEXADECIMAL) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // ultoa::@3
    // if(radix==OCTAL)
    // [2258] if(ultoa::radix#0==OCTAL) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // ultoa::@4
    // if(radix==BINARY)
    // [2259] if(ultoa::radix#0==BINARY) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // ultoa::@5
    // *buffer++ = 'e'
    // [2260] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2261] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2262] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2263] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // ultoa::@return
    // }
    // [2264] return 
    rts
    // [2265] phi from ultoa to ultoa::@1 [phi:ultoa->ultoa::@1]
  __b2:
    // [2265] phi ultoa::digit_values#8 = RADIX_DECIMAL_VALUES_LONG [phi:ultoa->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2265] phi ultoa::max_digits#7 = $a [phi:ultoa->ultoa::@1#1] -- vbum1=vbuc1 
    lda #$a
    sta max_digits
    jmp __b1
    // [2265] phi from ultoa::@2 to ultoa::@1 [phi:ultoa::@2->ultoa::@1]
  __b3:
    // [2265] phi ultoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_LONG [phi:ultoa::@2->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2265] phi ultoa::max_digits#7 = 8 [phi:ultoa::@2->ultoa::@1#1] -- vbum1=vbuc1 
    lda #8
    sta max_digits
    jmp __b1
    // [2265] phi from ultoa::@3 to ultoa::@1 [phi:ultoa::@3->ultoa::@1]
  __b4:
    // [2265] phi ultoa::digit_values#8 = RADIX_OCTAL_VALUES_LONG [phi:ultoa::@3->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_OCTAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_LONG
    sta.z digit_values+1
    // [2265] phi ultoa::max_digits#7 = $b [phi:ultoa::@3->ultoa::@1#1] -- vbum1=vbuc1 
    lda #$b
    sta max_digits
    jmp __b1
    // [2265] phi from ultoa::@4 to ultoa::@1 [phi:ultoa::@4->ultoa::@1]
  __b5:
    // [2265] phi ultoa::digit_values#8 = RADIX_BINARY_VALUES_LONG [phi:ultoa::@4->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_BINARY_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_LONG
    sta.z digit_values+1
    // [2265] phi ultoa::max_digits#7 = $20 [phi:ultoa::@4->ultoa::@1#1] -- vbum1=vbuc1 
    lda #$20
    sta max_digits
    // ultoa::@1
  __b1:
    // [2266] phi from ultoa::@1 to ultoa::@6 [phi:ultoa::@1->ultoa::@6]
    // [2266] phi ultoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:ultoa::@1->ultoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2266] phi ultoa::started#2 = 0 [phi:ultoa::@1->ultoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [2266] phi ultoa::value#2 = ultoa::value#1 [phi:ultoa::@1->ultoa::@6#2] -- register_copy 
    // [2266] phi ultoa::digit#2 = 0 [phi:ultoa::@1->ultoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // ultoa::@6
  __b6:
    // max_digits-1
    // [2267] ultoa::$4 = ultoa::max_digits#7 - 1 -- vbuz1=vbum2_minus_1 
    ldx max_digits
    dex
    stx.z ultoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2268] if(ultoa::digit#2<ultoa::$4) goto ultoa::@7 -- vbum1_lt_vbuz2_then_la1 
    lda digit
    cmp.z ultoa__4
    bcc __b7
    // ultoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2269] ultoa::$11 = (char)ultoa::value#2 -- vbuz1=_byte_vdum2 
    lda value
    sta.z ultoa__11
    // [2270] *ultoa::buffer#11 = DIGITS[ultoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2271] ultoa::buffer#3 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2272] *ultoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // ultoa::@7
  __b7:
    // unsigned long digit_value = digit_values[digit]
    // [2273] ultoa::$10 = ultoa::digit#2 << 2 -- vbuz1=vbum2_rol_2 
    lda digit
    asl
    asl
    sta.z ultoa__10
    // [2274] ultoa::digit_value#0 = ultoa::digit_values#8[ultoa::$10] -- vdum1=pduz2_derefidx_vbuz3 
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
    // [2275] if(0!=ultoa::started#2) goto ultoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // ultoa::@12
    // [2276] if(ultoa::value#2>=ultoa::digit_value#0) goto ultoa::@10 -- vdum1_ge_vdum2_then_la1 
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
    // [2277] phi from ultoa::@12 to ultoa::@9 [phi:ultoa::@12->ultoa::@9]
    // [2277] phi ultoa::buffer#14 = ultoa::buffer#11 [phi:ultoa::@12->ultoa::@9#0] -- register_copy 
    // [2277] phi ultoa::started#4 = ultoa::started#2 [phi:ultoa::@12->ultoa::@9#1] -- register_copy 
    // [2277] phi ultoa::value#6 = ultoa::value#2 [phi:ultoa::@12->ultoa::@9#2] -- register_copy 
    // ultoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2278] ultoa::digit#1 = ++ ultoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [2266] phi from ultoa::@9 to ultoa::@6 [phi:ultoa::@9->ultoa::@6]
    // [2266] phi ultoa::buffer#11 = ultoa::buffer#14 [phi:ultoa::@9->ultoa::@6#0] -- register_copy 
    // [2266] phi ultoa::started#2 = ultoa::started#4 [phi:ultoa::@9->ultoa::@6#1] -- register_copy 
    // [2266] phi ultoa::value#2 = ultoa::value#6 [phi:ultoa::@9->ultoa::@6#2] -- register_copy 
    // [2266] phi ultoa::digit#2 = ultoa::digit#1 [phi:ultoa::@9->ultoa::@6#3] -- register_copy 
    jmp __b6
    // ultoa::@10
  __b10:
    // ultoa_append(buffer++, value, digit_value)
    // [2279] ultoa_append::buffer#0 = ultoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z ultoa_append.buffer
    lda.z buffer+1
    sta.z ultoa_append.buffer+1
    // [2280] ultoa_append::value#0 = ultoa::value#2
    // [2281] ultoa_append::sub#0 = ultoa::digit_value#0
    // [2282] call ultoa_append
    // [2574] phi from ultoa::@10 to ultoa_append [phi:ultoa::@10->ultoa_append]
    jsr ultoa_append
    // ultoa_append(buffer++, value, digit_value)
    // [2283] ultoa_append::return#0 = ultoa_append::value#2
    // ultoa::@11
    // value = ultoa_append(buffer++, value, digit_value)
    // [2284] ultoa::value#0 = ultoa_append::return#0
    // value = ultoa_append(buffer++, value, digit_value);
    // [2285] ultoa::buffer#4 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2277] phi from ultoa::@11 to ultoa::@9 [phi:ultoa::@11->ultoa::@9]
    // [2277] phi ultoa::buffer#14 = ultoa::buffer#4 [phi:ultoa::@11->ultoa::@9#0] -- register_copy 
    // [2277] phi ultoa::started#4 = 1 [phi:ultoa::@11->ultoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [2277] phi ultoa::value#6 = ultoa::value#0 [phi:ultoa::@11->ultoa::@9#2] -- register_copy 
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
// void rom_sector_erase(__zp($da) unsigned long address)
rom_sector_erase: {
    .label rom_ptr1_rom_sector_erase__0 = $2d
    .label rom_ptr1_rom_sector_erase__2 = $2d
    .label rom_ptr1_return = $2d
    .label rom_chip_address = $5f
    .label address = $da
    // rom_sector_erase::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2287] rom_sector_erase::rom_ptr1_$2 = (unsigned int)rom_sector_erase::address#0 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_sector_erase__2
    lda.z address+1
    sta.z rom_ptr1_rom_sector_erase__2+1
    // [2288] rom_sector_erase::rom_ptr1_$0 = rom_sector_erase::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_sector_erase__0
    and #<$3fff
    sta.z rom_ptr1_rom_sector_erase__0
    lda.z rom_ptr1_rom_sector_erase__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_sector_erase__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2289] rom_sector_erase::rom_ptr1_return#0 = rom_sector_erase::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_sector_erase::@1
    // unsigned long rom_chip_address = address & ROM_CHIP_MASK
    // [2290] rom_sector_erase::rom_chip_address#0 = rom_sector_erase::address#0 & $380000 -- vduz1=vduz2_band_vduc1 
    lda.z address
    and #<$380000
    sta.z rom_chip_address
    lda.z address+1
    and #>$380000
    sta.z rom_chip_address+1
    lda.z address+2
    and #<$380000>>$10
    sta.z rom_chip_address+2
    lda.z address+3
    and #>$380000>>$10
    sta.z rom_chip_address+3
    // rom_unlock(rom_chip_address + 0x05555, 0x80)
    // [2291] rom_unlock::address#0 = rom_sector_erase::rom_chip_address#0 + $5555 -- vduz1=vduz1_plus_vwuc1 
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
    // [2292] call rom_unlock
    // [2013] phi from rom_sector_erase::@1 to rom_unlock [phi:rom_sector_erase::@1->rom_unlock]
    // [2013] phi rom_unlock::unlock_code#5 = $80 [phi:rom_sector_erase::@1->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$80
    sta.z rom_unlock.unlock_code
    // [2013] phi rom_unlock::address#5 = rom_unlock::address#0 [phi:rom_sector_erase::@1->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@2
    // rom_unlock(address, 0x30)
    // [2293] rom_unlock::address#1 = rom_sector_erase::address#0 -- vduz1=vduz2 
    lda.z address
    sta.z rom_unlock.address
    lda.z address+1
    sta.z rom_unlock.address+1
    lda.z address+2
    sta.z rom_unlock.address+2
    lda.z address+3
    sta.z rom_unlock.address+3
    // [2294] call rom_unlock
    // [2013] phi from rom_sector_erase::@2 to rom_unlock [phi:rom_sector_erase::@2->rom_unlock]
    // [2013] phi rom_unlock::unlock_code#5 = $30 [phi:rom_sector_erase::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$30
    sta.z rom_unlock.unlock_code
    // [2013] phi rom_unlock::address#5 = rom_unlock::address#1 [phi:rom_sector_erase::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@3
    // rom_wait(ptr_rom)
    // [2295] rom_wait::ptr_rom#0 = (char *)rom_sector_erase::rom_ptr1_return#0
    // [2296] call rom_wait
    // [2581] phi from rom_sector_erase::@3 to rom_wait [phi:rom_sector_erase::@3->rom_wait]
    // [2581] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#0 [phi:rom_sector_erase::@3->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_sector_erase::@return
    // }
    // [2297] return 
    rts
}
  // rom_write
/* inline */
// unsigned long rom_write(__zp($cd) char flash_ram_bank, __zp($6e) char *flash_ram_address, __zp($72) unsigned long flash_rom_address, unsigned int flash_rom_size)
rom_write: {
    .label rom_chip_address = $a9
    .label flash_rom_address = $72
    .label flash_ram_address = $6e
    .label flashed_bytes = $65
    .label flash_ram_bank = $cd
    // unsigned long rom_chip_address = flash_rom_address & ROM_CHIP_MASK
    // [2298] rom_write::rom_chip_address#0 = rom_write::flash_rom_address#1 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [2299] BRAM = rom_write::flash_ram_bank#0 -- vbuz1=vbuz2 
    lda.z flash_ram_bank
    sta.z BRAM
    // [2300] phi from rom_write::bank_set_bram1 to rom_write::@1 [phi:rom_write::bank_set_bram1->rom_write::@1]
    // [2300] phi rom_write::flash_ram_address#2 = rom_write::flash_ram_address#1 [phi:rom_write::bank_set_bram1->rom_write::@1#0] -- register_copy 
    // [2300] phi rom_write::flash_rom_address#3 = rom_write::flash_rom_address#1 [phi:rom_write::bank_set_bram1->rom_write::@1#1] -- register_copy 
    // [2300] phi rom_write::flashed_bytes#2 = 0 [phi:rom_write::bank_set_bram1->rom_write::@1#2] -- vduz1=vduc1 
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
    // [2301] if(rom_write::flashed_bytes#2<ROM_PROGRESS_CELL) goto rom_write::@2 -- vduz1_lt_vduc1_then_la1 
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
    // [2302] return 
    rts
    // rom_write::@2
  __b2:
    // rom_unlock(rom_chip_address + 0x05555, 0xA0)
    // [2303] rom_unlock::address#4 = rom_write::rom_chip_address#0 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [2304] call rom_unlock
    // [2013] phi from rom_write::@2 to rom_unlock [phi:rom_write::@2->rom_unlock]
    // [2013] phi rom_unlock::unlock_code#5 = $a0 [phi:rom_write::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$a0
    sta.z rom_unlock.unlock_code
    // [2013] phi rom_unlock::address#5 = rom_unlock::address#4 [phi:rom_write::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_write::@3
    // rom_byte_program(flash_rom_address, *flash_ram_address)
    // [2305] rom_byte_program::address#0 = rom_write::flash_rom_address#3 -- vduz1=vduz2 
    lda.z flash_rom_address
    sta.z rom_byte_program.address
    lda.z flash_rom_address+1
    sta.z rom_byte_program.address+1
    lda.z flash_rom_address+2
    sta.z rom_byte_program.address+2
    lda.z flash_rom_address+3
    sta.z rom_byte_program.address+3
    // [2306] rom_byte_program::value#0 = *rom_write::flash_ram_address#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (flash_ram_address),y
    sta.z rom_byte_program.value
    // [2307] call rom_byte_program
    // [2588] phi from rom_write::@3 to rom_byte_program [phi:rom_write::@3->rom_byte_program]
    jsr rom_byte_program
    // rom_write::@4
    // flash_rom_address++;
    // [2308] rom_write::flash_rom_address#0 = ++ rom_write::flash_rom_address#3 -- vduz1=_inc_vduz1 
    inc.z flash_rom_address
    bne !+
    inc.z flash_rom_address+1
    bne !+
    inc.z flash_rom_address+2
    bne !+
    inc.z flash_rom_address+3
  !:
    // flash_ram_address++;
    // [2309] rom_write::flash_ram_address#0 = ++ rom_write::flash_ram_address#2 -- pbuz1=_inc_pbuz1 
    inc.z flash_ram_address
    bne !+
    inc.z flash_ram_address+1
  !:
    // flashed_bytes++;
    // [2310] rom_write::flashed_bytes#1 = ++ rom_write::flashed_bytes#2 -- vduz1=_inc_vduz1 
    inc.z flashed_bytes
    bne !+
    inc.z flashed_bytes+1
    bne !+
    inc.z flashed_bytes+2
    bne !+
    inc.z flashed_bytes+3
  !:
    // [2300] phi from rom_write::@4 to rom_write::@1 [phi:rom_write::@4->rom_write::@1]
    // [2300] phi rom_write::flash_ram_address#2 = rom_write::flash_ram_address#0 [phi:rom_write::@4->rom_write::@1#0] -- register_copy 
    // [2300] phi rom_write::flash_rom_address#3 = rom_write::flash_rom_address#0 [phi:rom_write::@4->rom_write::@1#1] -- register_copy 
    // [2300] phi rom_write::flashed_bytes#2 = rom_write::flashed_bytes#1 [phi:rom_write::@4->rom_write::@1#2] -- register_copy 
    jmp __b1
}
  // cbm_k_getin
/**
 * @brief Scan a character from keyboard without pressing enter.
 * 
 * @return char The character read.
 */
cbm_k_getin: {
    // __mem unsigned char ch
    // [2311] cbm_k_getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // asm
    // asm { jsrCBM_GETIN stach  }
    jsr CBM_GETIN
    sta ch
    // return ch;
    // [2313] cbm_k_getin::return#0 = cbm_k_getin::ch -- vbum1=vbum2 
    sta return
    // cbm_k_getin::@return
    // }
    // [2314] cbm_k_getin::return#1 = cbm_k_getin::return#0
    // [2315] return 
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
    .label insertup__0 = $34
    .label insertup__4 = $2b
    .label insertup__6 = $2c
    .label insertup__7 = $2b
    // __conio.width+1
    // [2316] insertup::$0 = *((char *)&__conio+6) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+6
    inc
    sta.z insertup__0
    // unsigned char width = (__conio.width+1) * 2
    // [2317] insertup::width#0 = insertup::$0 << 1 -- vbum1=vbuz2_rol_1 
    // {asm{.byte $db}}
    asl
    sta width
    // [2318] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [2318] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbum1=vbuc1 
    lda #0
    sta y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [2319] if(insertup::y#2<*((char *)&__conio+1)) goto insertup::@2 -- vbum1_lt__deref_pbuc1_then_la1 
    lda y
    cmp __conio+1
    bcc __b2
    // [2320] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [2321] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [2322] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [2323] insertup::$4 = insertup::y#2 + 1 -- vbuz1=vbum2_plus_1 
    lda y
    inc
    sta.z insertup__4
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [2324] insertup::$6 = insertup::y#2 << 1 -- vbuz1=vbum2_rol_1 
    lda y
    asl
    sta.z insertup__6
    // [2325] insertup::$7 = insertup::$4 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z insertup__7
    // [2326] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+5) -- vbum1=_deref_pbuc1 
    lda __conio+5
    sta memcpy8_vram_vram.dbank_vram
    // [2327] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwum1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__6
    lda __conio+$15,y
    sta memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta memcpy8_vram_vram.doffset_vram+1
    // [2328] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+5) -- vbum1=_deref_pbuc1 
    lda __conio+5
    sta memcpy8_vram_vram.sbank_vram
    // [2329] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwum1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__7
    lda __conio+$15,y
    sta memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,y
    sta memcpy8_vram_vram.soffset_vram+1
    // [2330] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbum1=vbum2 
    lda width
    sta memcpy8_vram_vram.num8_1
    // [2331] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [2332] insertup::y#1 = ++ insertup::y#2 -- vbum1=_inc_vbum1 
    inc y
    // [2318] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [2318] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
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
    // [2333] clearline::$3 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z clearline__3
    // [2334] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwum1=pwuc1_derefidx_vbuz2 
    tay
    lda __conio+$15,y
    sta addr
    lda __conio+$15+1,y
    sta addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2335] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [2336] clearline::$0 = byte0  clearline::addr#0 -- vbuz1=_byte0_vwum2 
    lda addr
    sta.z clearline__0
    // *VERA_ADDRX_L = BYTE0(addr)
    // [2337] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [2338] clearline::$1 = byte1  clearline::addr#0 -- vbuz1=_byte1_vwum2 
    lda addr+1
    sta.z clearline__1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [2339] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [2340] clearline::$2 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clearline__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [2341] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [2342] clearline::c#0 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z c
    // [2343] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [2343] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [2344] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [2345] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [2346] clearline::c#1 = -- clearline::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [2347] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b1
    // clearline::@return
    // }
    // [2348] return 
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
// __zp($4e) char display_frame_maskxy(__mem() char x, __mem() char y)
display_frame_maskxy: {
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__0 = $58
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__1 = $41
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__2 = $3c
    .label c = $43
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
    .label return = $4e
    // display_frame_maskxy::cpeekcxy1
    // gotoxy(x,y)
    // [2350] gotoxy::x#5 = display_frame_maskxy::cpeekcxy1_x#0 -- vbum1=vbum2 
    lda cpeekcxy1_x
    sta gotoxy.x
    // [2351] gotoxy::y#5 = display_frame_maskxy::cpeekcxy1_y#0 -- vbum1=vbum2 
    lda cpeekcxy1_y
    sta gotoxy.y
    // [2352] call gotoxy
    // [606] phi from display_frame_maskxy::cpeekcxy1 to gotoxy [phi:display_frame_maskxy::cpeekcxy1->gotoxy]
    // [606] phi gotoxy::y#30 = gotoxy::y#5 [phi:display_frame_maskxy::cpeekcxy1->gotoxy#0] -- register_copy 
    // [606] phi gotoxy::x#30 = gotoxy::x#5 [phi:display_frame_maskxy::cpeekcxy1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_frame_maskxy::cpeekcxy1_cpeekc1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2353] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(__conio.offset)
    // [2354] display_frame_maskxy::cpeekcxy1_cpeekc1_$0 = byte0  *((unsigned int *)&__conio+$13) -- vbuz1=_byte0__deref_pwuc1 
    lda __conio+$13
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__0
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [2355] *VERA_ADDRX_L = display_frame_maskxy::cpeekcxy1_cpeekc1_$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [2356] display_frame_maskxy::cpeekcxy1_cpeekc1_$1 = byte1  *((unsigned int *)&__conio+$13) -- vbuz1=_byte1__deref_pwuc1 
    lda __conio+$13+1
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__1
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [2357] *VERA_ADDRX_M = display_frame_maskxy::cpeekcxy1_cpeekc1_$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_0
    // [2358] display_frame_maskxy::cpeekcxy1_cpeekc1_$2 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_0
    // [2359] *VERA_ADDRX_H = display_frame_maskxy::cpeekcxy1_cpeekc1_$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // return *VERA_DATA0;
    // [2360] display_frame_maskxy::c#0 = *VERA_DATA0 -- vbuz1=_deref_pbuc1 
    lda VERA_DATA0
    sta.z c
    // display_frame_maskxy::@12
    // case 0x70: // DR corner.
    //             return 0b0110;
    // [2361] if(display_frame_maskxy::c#0==$70) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$70
    cmp.z c
    beq __b2
    // display_frame_maskxy::@1
    // case 0x6E: // DL corner.
    //             return 0b0011;
    // [2362] if(display_frame_maskxy::c#0==$6e) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6e
    cmp.z c
    beq __b1
    // display_frame_maskxy::@2
    // case 0x6D: // UR corner.
    //             return 0b1100;
    // [2363] if(display_frame_maskxy::c#0==$6d) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6d
    cmp.z c
    beq __b3
    // display_frame_maskxy::@3
    // case 0x7D: // UL corner.
    //             return 0b1001;
    // [2364] if(display_frame_maskxy::c#0==$7d) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$7d
    cmp.z c
    beq __b4
    // display_frame_maskxy::@4
    // case 0x40: // HL line.
    //             return 0b0101;
    // [2365] if(display_frame_maskxy::c#0==$40) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$40
    cmp.z c
    beq __b5
    // display_frame_maskxy::@5
    // case 0x5D: // VL line.
    //             return 0b1010;
    // [2366] if(display_frame_maskxy::c#0==$5d) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$5d
    cmp.z c
    beq __b6
    // display_frame_maskxy::@6
    // case 0x6B: // VR junction.
    //             return 0b1110;
    // [2367] if(display_frame_maskxy::c#0==$6b) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6b
    cmp.z c
    beq __b7
    // display_frame_maskxy::@7
    // case 0x73: // VL junction.
    //             return 0b1011;
    // [2368] if(display_frame_maskxy::c#0==$73) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$73
    cmp.z c
    beq __b8
    // display_frame_maskxy::@8
    // case 0x72: // HD junction.
    //             return 0b0111;
    // [2369] if(display_frame_maskxy::c#0==$72) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$72
    cmp.z c
    beq __b9
    // display_frame_maskxy::@9
    // case 0x71: // HU junction.
    //             return 0b1101;
    // [2370] if(display_frame_maskxy::c#0==$71) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$71
    cmp.z c
    beq __b10
    // display_frame_maskxy::@10
    // case 0x5B: // HV junction.
    //             return 0b1111;
    // [2371] if(display_frame_maskxy::c#0==$5b) goto display_frame_maskxy::@11 -- vbuz1_eq_vbuc1_then_la1 
    lda #$5b
    cmp.z c
    beq __b11
    // [2373] phi from display_frame_maskxy::@10 to display_frame_maskxy::@return [phi:display_frame_maskxy::@10->display_frame_maskxy::@return]
    // [2373] phi display_frame_maskxy::return#12 = 0 [phi:display_frame_maskxy::@10->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #0
    sta.z return
    rts
    // [2372] phi from display_frame_maskxy::@10 to display_frame_maskxy::@11 [phi:display_frame_maskxy::@10->display_frame_maskxy::@11]
    // display_frame_maskxy::@11
  __b11:
    // [2373] phi from display_frame_maskxy::@11 to display_frame_maskxy::@return [phi:display_frame_maskxy::@11->display_frame_maskxy::@return]
    // [2373] phi display_frame_maskxy::return#12 = $f [phi:display_frame_maskxy::@11->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$f
    sta.z return
    rts
    // [2373] phi from display_frame_maskxy::@1 to display_frame_maskxy::@return [phi:display_frame_maskxy::@1->display_frame_maskxy::@return]
  __b1:
    // [2373] phi display_frame_maskxy::return#12 = 3 [phi:display_frame_maskxy::@1->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #3
    sta.z return
    rts
    // [2373] phi from display_frame_maskxy::@12 to display_frame_maskxy::@return [phi:display_frame_maskxy::@12->display_frame_maskxy::@return]
  __b2:
    // [2373] phi display_frame_maskxy::return#12 = 6 [phi:display_frame_maskxy::@12->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #6
    sta.z return
    rts
    // [2373] phi from display_frame_maskxy::@2 to display_frame_maskxy::@return [phi:display_frame_maskxy::@2->display_frame_maskxy::@return]
  __b3:
    // [2373] phi display_frame_maskxy::return#12 = $c [phi:display_frame_maskxy::@2->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$c
    sta.z return
    rts
    // [2373] phi from display_frame_maskxy::@3 to display_frame_maskxy::@return [phi:display_frame_maskxy::@3->display_frame_maskxy::@return]
  __b4:
    // [2373] phi display_frame_maskxy::return#12 = 9 [phi:display_frame_maskxy::@3->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #9
    sta.z return
    rts
    // [2373] phi from display_frame_maskxy::@4 to display_frame_maskxy::@return [phi:display_frame_maskxy::@4->display_frame_maskxy::@return]
  __b5:
    // [2373] phi display_frame_maskxy::return#12 = 5 [phi:display_frame_maskxy::@4->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #5
    sta.z return
    rts
    // [2373] phi from display_frame_maskxy::@5 to display_frame_maskxy::@return [phi:display_frame_maskxy::@5->display_frame_maskxy::@return]
  __b6:
    // [2373] phi display_frame_maskxy::return#12 = $a [phi:display_frame_maskxy::@5->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$a
    sta.z return
    rts
    // [2373] phi from display_frame_maskxy::@6 to display_frame_maskxy::@return [phi:display_frame_maskxy::@6->display_frame_maskxy::@return]
  __b7:
    // [2373] phi display_frame_maskxy::return#12 = $e [phi:display_frame_maskxy::@6->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$e
    sta.z return
    rts
    // [2373] phi from display_frame_maskxy::@7 to display_frame_maskxy::@return [phi:display_frame_maskxy::@7->display_frame_maskxy::@return]
  __b8:
    // [2373] phi display_frame_maskxy::return#12 = $b [phi:display_frame_maskxy::@7->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$b
    sta.z return
    rts
    // [2373] phi from display_frame_maskxy::@8 to display_frame_maskxy::@return [phi:display_frame_maskxy::@8->display_frame_maskxy::@return]
  __b9:
    // [2373] phi display_frame_maskxy::return#12 = 7 [phi:display_frame_maskxy::@8->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #7
    sta.z return
    rts
    // [2373] phi from display_frame_maskxy::@9 to display_frame_maskxy::@return [phi:display_frame_maskxy::@9->display_frame_maskxy::@return]
  __b10:
    // [2373] phi display_frame_maskxy::return#12 = $d [phi:display_frame_maskxy::@9->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$d
    sta.z return
    // display_frame_maskxy::@return
    // }
    // [2374] return 
    rts
  .segment Data
    cpeekcxy1_x: .byte 0
    cpeekcxy1_y: .byte 0
    .label x = main.check_status_smc7_main__0
    .label y = main.check_status_roms1_check_status_rom1_main__0
    .label x_1 = main.check_status_roms_all1_check_status_rom1_main__0
    .label y_1 = main.check_status_rom1_main__0
    .label x_2 = main.check_status_smc10_main__0
}
.segment Code
  // display_frame_char
/**
 * @brief 
 * 
 * @param mask 
 * @return unsigned char 
 */
// __zp($2a) char display_frame_char(__zp($4e) char mask)
display_frame_char: {
    .label return = $2a
    .label mask = $4e
    // case 0b0110:
    //             return 0x70;
    // [2376] if(display_frame_char::mask#10==6) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #6
    cmp.z mask
    beq __b1
    // display_frame_char::@1
    // case 0b0011:
    //             return 0x6E;
    // [2377] if(display_frame_char::mask#10==3) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // DR corner.
    lda #3
    cmp.z mask
    beq __b2
    // display_frame_char::@2
    // case 0b1100:
    //             return 0x6D;
    // [2378] if(display_frame_char::mask#10==$c) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // DL corner.
    lda #$c
    cmp.z mask
    beq __b3
    // display_frame_char::@3
    // case 0b1001:
    //             return 0x7D;
    // [2379] if(display_frame_char::mask#10==9) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // UR corner.
    lda #9
    cmp.z mask
    beq __b4
    // display_frame_char::@4
    // case 0b0101:
    //             return 0x40;
    // [2380] if(display_frame_char::mask#10==5) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // UL corner.
    lda #5
    cmp.z mask
    beq __b5
    // display_frame_char::@5
    // case 0b1010:
    //             return 0x5D;
    // [2381] if(display_frame_char::mask#10==$a) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // HL line.
    lda #$a
    cmp.z mask
    beq __b6
    // display_frame_char::@6
    // case 0b1110:
    //             return 0x6B;
    // [2382] if(display_frame_char::mask#10==$e) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VL line.
    lda #$e
    cmp.z mask
    beq __b7
    // display_frame_char::@7
    // case 0b1011:
    //             return 0x73;
    // [2383] if(display_frame_char::mask#10==$b) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VR junction.
    lda #$b
    cmp.z mask
    beq __b8
    // display_frame_char::@8
    // case 0b0111:
    //             return 0x72;
    // [2384] if(display_frame_char::mask#10==7) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VL junction.
    lda #7
    cmp.z mask
    beq __b9
    // display_frame_char::@9
    // case 0b1101:
    //             return 0x71;
    // [2385] if(display_frame_char::mask#10==$d) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // HD junction.
    lda #$d
    cmp.z mask
    beq __b10
    // display_frame_char::@10
    // case 0b1111:
    //             return 0x5B;
    // [2386] if(display_frame_char::mask#10==$f) goto display_frame_char::@11 -- vbuz1_eq_vbuc1_then_la1 
    // HU junction.
    lda #$f
    cmp.z mask
    beq __b11
    // [2388] phi from display_frame_char::@10 to display_frame_char::@return [phi:display_frame_char::@10->display_frame_char::@return]
    // [2388] phi display_frame_char::return#12 = $20 [phi:display_frame_char::@10->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$20
    sta.z return
    rts
    // [2387] phi from display_frame_char::@10 to display_frame_char::@11 [phi:display_frame_char::@10->display_frame_char::@11]
    // display_frame_char::@11
  __b11:
    // [2388] phi from display_frame_char::@11 to display_frame_char::@return [phi:display_frame_char::@11->display_frame_char::@return]
    // [2388] phi display_frame_char::return#12 = $5b [phi:display_frame_char::@11->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z return
    rts
    // [2388] phi from display_frame_char to display_frame_char::@return [phi:display_frame_char->display_frame_char::@return]
  __b1:
    // [2388] phi display_frame_char::return#12 = $70 [phi:display_frame_char->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$70
    sta.z return
    rts
    // [2388] phi from display_frame_char::@1 to display_frame_char::@return [phi:display_frame_char::@1->display_frame_char::@return]
  __b2:
    // [2388] phi display_frame_char::return#12 = $6e [phi:display_frame_char::@1->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6e
    sta.z return
    rts
    // [2388] phi from display_frame_char::@2 to display_frame_char::@return [phi:display_frame_char::@2->display_frame_char::@return]
  __b3:
    // [2388] phi display_frame_char::return#12 = $6d [phi:display_frame_char::@2->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6d
    sta.z return
    rts
    // [2388] phi from display_frame_char::@3 to display_frame_char::@return [phi:display_frame_char::@3->display_frame_char::@return]
  __b4:
    // [2388] phi display_frame_char::return#12 = $7d [phi:display_frame_char::@3->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$7d
    sta.z return
    rts
    // [2388] phi from display_frame_char::@4 to display_frame_char::@return [phi:display_frame_char::@4->display_frame_char::@return]
  __b5:
    // [2388] phi display_frame_char::return#12 = $40 [phi:display_frame_char::@4->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z return
    rts
    // [2388] phi from display_frame_char::@5 to display_frame_char::@return [phi:display_frame_char::@5->display_frame_char::@return]
  __b6:
    // [2388] phi display_frame_char::return#12 = $5d [phi:display_frame_char::@5->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z return
    rts
    // [2388] phi from display_frame_char::@6 to display_frame_char::@return [phi:display_frame_char::@6->display_frame_char::@return]
  __b7:
    // [2388] phi display_frame_char::return#12 = $6b [phi:display_frame_char::@6->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z return
    rts
    // [2388] phi from display_frame_char::@7 to display_frame_char::@return [phi:display_frame_char::@7->display_frame_char::@return]
  __b8:
    // [2388] phi display_frame_char::return#12 = $73 [phi:display_frame_char::@7->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z return
    rts
    // [2388] phi from display_frame_char::@8 to display_frame_char::@return [phi:display_frame_char::@8->display_frame_char::@return]
  __b9:
    // [2388] phi display_frame_char::return#12 = $72 [phi:display_frame_char::@8->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z return
    rts
    // [2388] phi from display_frame_char::@9 to display_frame_char::@return [phi:display_frame_char::@9->display_frame_char::@return]
  __b10:
    // [2388] phi display_frame_char::return#12 = $71 [phi:display_frame_char::@9->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z return
    // display_frame_char::@return
    // }
    // [2389] return 
    rts
}
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
// void display_chip_led(__zp($b2) char x, char y, __zp($b1) char w, __zp($58) char tc, char bc)
display_chip_led: {
    .label x = $b2
    .label w = $b1
    .label tc = $58
    // textcolor(tc)
    // [2391] textcolor::color#11 = display_chip_led::tc#3 -- vbum1=vbuz2 
    lda.z tc
    sta textcolor.color
    // [2392] call textcolor
    // [588] phi from display_chip_led to textcolor [phi:display_chip_led->textcolor]
    // [588] phi textcolor::color#18 = textcolor::color#11 [phi:display_chip_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [2393] phi from display_chip_led to display_chip_led::@3 [phi:display_chip_led->display_chip_led::@3]
    // display_chip_led::@3
    // bgcolor(bc)
    // [2394] call bgcolor
    // [593] phi from display_chip_led::@3 to bgcolor [phi:display_chip_led::@3->bgcolor]
    // [593] phi bgcolor::color#14 = BLUE [phi:display_chip_led::@3->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [2395] phi from display_chip_led::@3 display_chip_led::@5 to display_chip_led::@1 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1]
    // [2395] phi display_chip_led::w#4 = display_chip_led::w#7 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1#0] -- register_copy 
    // [2395] phi display_chip_led::x#4 = display_chip_led::x#7 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1#1] -- register_copy 
    // display_chip_led::@1
  __b1:
    // cputcxy(x, y, 0x6F)
    // [2396] cputcxy::x#9 = display_chip_led::x#4 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [2397] call cputcxy
    // [1834] phi from display_chip_led::@1 to cputcxy [phi:display_chip_led::@1->cputcxy]
    // [1834] phi cputcxy::c#15 = $6f [phi:display_chip_led::@1->cputcxy#0] -- vbum1=vbuc1 
    lda #$6f
    sta cputcxy.c
    // [1834] phi cputcxy::y#15 = 3 [phi:display_chip_led::@1->cputcxy#1] -- vbum1=vbuc1 
    lda #3
    sta cputcxy.y
    // [1834] phi cputcxy::x#15 = cputcxy::x#9 [phi:display_chip_led::@1->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_led::@4
    // cputcxy(x, y+1, 0x77)
    // [2398] cputcxy::x#10 = display_chip_led::x#4 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [2399] call cputcxy
    // [1834] phi from display_chip_led::@4 to cputcxy [phi:display_chip_led::@4->cputcxy]
    // [1834] phi cputcxy::c#15 = $77 [phi:display_chip_led::@4->cputcxy#0] -- vbum1=vbuc1 
    lda #$77
    sta cputcxy.c
    // [1834] phi cputcxy::y#15 = 3+1 [phi:display_chip_led::@4->cputcxy#1] -- vbum1=vbuc1 
    lda #3+1
    sta cputcxy.y
    // [1834] phi cputcxy::x#15 = cputcxy::x#10 [phi:display_chip_led::@4->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_led::@5
    // x++;
    // [2400] display_chip_led::x#0 = ++ display_chip_led::x#4 -- vbuz1=_inc_vbuz1 
    inc.z x
    // while(--w)
    // [2401] display_chip_led::w#0 = -- display_chip_led::w#4 -- vbuz1=_dec_vbuz1 
    dec.z w
    // [2402] if(0!=display_chip_led::w#0) goto display_chip_led::@1 -- 0_neq_vbuz1_then_la1 
    lda.z w
    bne __b1
    // [2403] phi from display_chip_led::@5 to display_chip_led::@2 [phi:display_chip_led::@5->display_chip_led::@2]
    // display_chip_led::@2
    // textcolor(WHITE)
    // [2404] call textcolor
    // [588] phi from display_chip_led::@2 to textcolor [phi:display_chip_led::@2->textcolor]
    // [588] phi textcolor::color#18 = WHITE [phi:display_chip_led::@2->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [2405] phi from display_chip_led::@2 to display_chip_led::@6 [phi:display_chip_led::@2->display_chip_led::@6]
    // display_chip_led::@6
    // bgcolor(BLUE)
    // [2406] call bgcolor
    // [593] phi from display_chip_led::@6 to bgcolor [phi:display_chip_led::@6->bgcolor]
    // [593] phi bgcolor::color#14 = BLUE [phi:display_chip_led::@6->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_led::@return
    // }
    // [2407] return 
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
// void display_chip_line(__mem() char x, __mem() char y, __zp($eb) char w, __mem() char c)
display_chip_line: {
    .label i = $cc
    .label w = $eb
    // gotoxy(x, y)
    // [2409] gotoxy::x#7 = display_chip_line::x#16 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [2410] gotoxy::y#7 = display_chip_line::y#16 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [2411] call gotoxy
    // [606] phi from display_chip_line to gotoxy [phi:display_chip_line->gotoxy]
    // [606] phi gotoxy::y#30 = gotoxy::y#7 [phi:display_chip_line->gotoxy#0] -- register_copy 
    // [606] phi gotoxy::x#30 = gotoxy::x#7 [phi:display_chip_line->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [2412] phi from display_chip_line to display_chip_line::@4 [phi:display_chip_line->display_chip_line::@4]
    // display_chip_line::@4
    // textcolor(GREY)
    // [2413] call textcolor
    // [588] phi from display_chip_line::@4 to textcolor [phi:display_chip_line::@4->textcolor]
    // [588] phi textcolor::color#18 = GREY [phi:display_chip_line::@4->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [2414] phi from display_chip_line::@4 to display_chip_line::@5 [phi:display_chip_line::@4->display_chip_line::@5]
    // display_chip_line::@5
    // bgcolor(BLUE)
    // [2415] call bgcolor
    // [593] phi from display_chip_line::@5 to bgcolor [phi:display_chip_line::@5->bgcolor]
    // [593] phi bgcolor::color#14 = BLUE [phi:display_chip_line::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_line::@6
    // cputc(VERA_CHR_UR)
    // [2416] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [2417] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [2419] call textcolor
    // [588] phi from display_chip_line::@6 to textcolor [phi:display_chip_line::@6->textcolor]
    // [588] phi textcolor::color#18 = WHITE [phi:display_chip_line::@6->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [2420] phi from display_chip_line::@6 to display_chip_line::@7 [phi:display_chip_line::@6->display_chip_line::@7]
    // display_chip_line::@7
    // bgcolor(BLACK)
    // [2421] call bgcolor
    // [593] phi from display_chip_line::@7 to bgcolor [phi:display_chip_line::@7->bgcolor]
    // [593] phi bgcolor::color#14 = BLACK [phi:display_chip_line::@7->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // [2422] phi from display_chip_line::@7 to display_chip_line::@1 [phi:display_chip_line::@7->display_chip_line::@1]
    // [2422] phi display_chip_line::i#2 = 0 [phi:display_chip_line::@7->display_chip_line::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // display_chip_line::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [2423] if(display_chip_line::i#2<display_chip_line::w#10) goto display_chip_line::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [2424] phi from display_chip_line::@1 to display_chip_line::@3 [phi:display_chip_line::@1->display_chip_line::@3]
    // display_chip_line::@3
    // textcolor(GREY)
    // [2425] call textcolor
    // [588] phi from display_chip_line::@3 to textcolor [phi:display_chip_line::@3->textcolor]
    // [588] phi textcolor::color#18 = GREY [phi:display_chip_line::@3->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [2426] phi from display_chip_line::@3 to display_chip_line::@8 [phi:display_chip_line::@3->display_chip_line::@8]
    // display_chip_line::@8
    // bgcolor(BLUE)
    // [2427] call bgcolor
    // [593] phi from display_chip_line::@8 to bgcolor [phi:display_chip_line::@8->bgcolor]
    // [593] phi bgcolor::color#14 = BLUE [phi:display_chip_line::@8->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_line::@9
    // cputc(VERA_CHR_UL)
    // [2428] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [2429] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [2431] call textcolor
    // [588] phi from display_chip_line::@9 to textcolor [phi:display_chip_line::@9->textcolor]
    // [588] phi textcolor::color#18 = WHITE [phi:display_chip_line::@9->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [2432] phi from display_chip_line::@9 to display_chip_line::@10 [phi:display_chip_line::@9->display_chip_line::@10]
    // display_chip_line::@10
    // bgcolor(BLACK)
    // [2433] call bgcolor
    // [593] phi from display_chip_line::@10 to bgcolor [phi:display_chip_line::@10->bgcolor]
    // [593] phi bgcolor::color#14 = BLACK [phi:display_chip_line::@10->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // display_chip_line::@11
    // cputcxy(x+2, y, c)
    // [2434] cputcxy::x#8 = display_chip_line::x#16 + 2 -- vbum1=vbum2_plus_2 
    lda x
    clc
    adc #2
    sta cputcxy.x
    // [2435] cputcxy::y#8 = display_chip_line::y#16 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [2436] cputcxy::c#8 = display_chip_line::c#15 -- vbum1=vbum2 
    lda c
    sta cputcxy.c
    // [2437] call cputcxy
    // [1834] phi from display_chip_line::@11 to cputcxy [phi:display_chip_line::@11->cputcxy]
    // [1834] phi cputcxy::c#15 = cputcxy::c#8 [phi:display_chip_line::@11->cputcxy#0] -- register_copy 
    // [1834] phi cputcxy::y#15 = cputcxy::y#8 [phi:display_chip_line::@11->cputcxy#1] -- register_copy 
    // [1834] phi cputcxy::x#15 = cputcxy::x#8 [phi:display_chip_line::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_line::@return
    // }
    // [2438] return 
    rts
    // display_chip_line::@2
  __b2:
    // cputc(VERA_CHR_SPACE)
    // [2439] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [2440] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [2442] display_chip_line::i#1 = ++ display_chip_line::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [2422] phi from display_chip_line::@2 to display_chip_line::@1 [phi:display_chip_line::@2->display_chip_line::@1]
    // [2422] phi display_chip_line::i#2 = display_chip_line::i#1 [phi:display_chip_line::@2->display_chip_line::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    .label x = rom_detect.rom_detect__24
    .label c = rom_detect.rom_detect__15
    .label y = rom_detect.rom_detect__21
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
// void display_chip_end(__mem() char x, char y, __zp($ed) char w)
display_chip_end: {
    .label i = $ce
    .label w = $ed
    // gotoxy(x, y)
    // [2443] gotoxy::x#8 = display_chip_end::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [2444] call gotoxy
    // [606] phi from display_chip_end to gotoxy [phi:display_chip_end->gotoxy]
    // [606] phi gotoxy::y#30 = display_print_chip::y#21 [phi:display_chip_end->gotoxy#0] -- vbum1=vbuc1 
    lda #display_print_chip.y
    sta gotoxy.y
    // [606] phi gotoxy::x#30 = gotoxy::x#8 [phi:display_chip_end->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [2445] phi from display_chip_end to display_chip_end::@4 [phi:display_chip_end->display_chip_end::@4]
    // display_chip_end::@4
    // textcolor(GREY)
    // [2446] call textcolor
    // [588] phi from display_chip_end::@4 to textcolor [phi:display_chip_end::@4->textcolor]
    // [588] phi textcolor::color#18 = GREY [phi:display_chip_end::@4->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [2447] phi from display_chip_end::@4 to display_chip_end::@5 [phi:display_chip_end::@4->display_chip_end::@5]
    // display_chip_end::@5
    // bgcolor(BLUE)
    // [2448] call bgcolor
    // [593] phi from display_chip_end::@5 to bgcolor [phi:display_chip_end::@5->bgcolor]
    // [593] phi bgcolor::color#14 = BLUE [phi:display_chip_end::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_end::@6
    // cputc(VERA_CHR_UR)
    // [2449] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [2450] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [2452] call textcolor
    // [588] phi from display_chip_end::@6 to textcolor [phi:display_chip_end::@6->textcolor]
    // [588] phi textcolor::color#18 = BLUE [phi:display_chip_end::@6->textcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta textcolor.color
    jsr textcolor
    // [2453] phi from display_chip_end::@6 to display_chip_end::@7 [phi:display_chip_end::@6->display_chip_end::@7]
    // display_chip_end::@7
    // bgcolor(BLACK)
    // [2454] call bgcolor
    // [593] phi from display_chip_end::@7 to bgcolor [phi:display_chip_end::@7->bgcolor]
    // [593] phi bgcolor::color#14 = BLACK [phi:display_chip_end::@7->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // [2455] phi from display_chip_end::@7 to display_chip_end::@1 [phi:display_chip_end::@7->display_chip_end::@1]
    // [2455] phi display_chip_end::i#2 = 0 [phi:display_chip_end::@7->display_chip_end::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // display_chip_end::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [2456] if(display_chip_end::i#2<display_chip_end::w#0) goto display_chip_end::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [2457] phi from display_chip_end::@1 to display_chip_end::@3 [phi:display_chip_end::@1->display_chip_end::@3]
    // display_chip_end::@3
    // textcolor(GREY)
    // [2458] call textcolor
    // [588] phi from display_chip_end::@3 to textcolor [phi:display_chip_end::@3->textcolor]
    // [588] phi textcolor::color#18 = GREY [phi:display_chip_end::@3->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [2459] phi from display_chip_end::@3 to display_chip_end::@8 [phi:display_chip_end::@3->display_chip_end::@8]
    // display_chip_end::@8
    // bgcolor(BLUE)
    // [2460] call bgcolor
    // [593] phi from display_chip_end::@8 to bgcolor [phi:display_chip_end::@8->bgcolor]
    // [593] phi bgcolor::color#14 = BLUE [phi:display_chip_end::@8->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_end::@9
    // cputc(VERA_CHR_UL)
    // [2461] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [2462] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_chip_end::@return
    // }
    // [2464] return 
    rts
    // display_chip_end::@2
  __b2:
    // cputc(VERA_CHR_HL)
    // [2465] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [2466] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [2468] display_chip_end::i#1 = ++ display_chip_end::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [2455] phi from display_chip_end::@2 to display_chip_end::@1 [phi:display_chip_end::@2->display_chip_end::@1]
    // [2455] phi display_chip_end::i#2 = display_chip_end::i#1 [phi:display_chip_end::@2->display_chip_end::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    .label x = util_wait_key.return
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
// __mem() unsigned int utoa_append(__zp($56) char *buffer, __mem() unsigned int value, __mem() unsigned int sub)
utoa_append: {
    .label buffer = $56
    // [2470] phi from utoa_append to utoa_append::@1 [phi:utoa_append->utoa_append::@1]
    // [2470] phi utoa_append::digit#2 = 0 [phi:utoa_append->utoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [2470] phi utoa_append::value#2 = utoa_append::value#0 [phi:utoa_append->utoa_append::@1#1] -- register_copy 
    // utoa_append::@1
  __b1:
    // while (value >= sub)
    // [2471] if(utoa_append::value#2>=utoa_append::sub#0) goto utoa_append::@2 -- vwum1_ge_vwum2_then_la1 
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
    // [2472] *utoa_append::buffer#0 = DIGITS[utoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // utoa_append::@return
    // }
    // [2473] return 
    rts
    // utoa_append::@2
  __b2:
    // digit++;
    // [2474] utoa_append::digit#1 = ++ utoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [2475] utoa_append::value#1 = utoa_append::value#2 - utoa_append::sub#0 -- vwum1=vwum1_minus_vwum2 
    lda value
    sec
    sbc sub
    sta value
    lda value+1
    sbc sub+1
    sta value+1
    // [2470] phi from utoa_append::@2 to utoa_append::@1 [phi:utoa_append::@2->utoa_append::@1]
    // [2470] phi utoa_append::digit#2 = utoa_append::digit#1 [phi:utoa_append::@2->utoa_append::@1#0] -- register_copy 
    // [2470] phi utoa_append::value#2 = utoa_append::value#1 [phi:utoa_append::@2->utoa_append::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label value = printf_uint.uvalue
    .label sub = utoa.digit_value
    .label return = printf_uint.uvalue
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
// void rom_write_byte(__zp($3d) unsigned long address, __zp($42) char value)
rom_write_byte: {
    .label rom_bank1_rom_write_byte__0 = $41
    .label rom_bank1_rom_write_byte__1 = $3c
    .label rom_bank1_rom_write_byte__2 = $38
    .label rom_ptr1_rom_write_byte__0 = $36
    .label rom_ptr1_rom_write_byte__2 = $36
    .label rom_bank1_bank_unshifted = $38
    .label rom_bank1_return = $43
    .label rom_ptr1_return = $36
    .label address = $3d
    .label value = $42
    // rom_write_byte::rom_bank1
    // BYTE2(address)
    // [2477] rom_write_byte::rom_bank1_$0 = byte2  rom_write_byte::address#4 -- vbuz1=_byte2_vduz2 
    lda.z address+2
    sta.z rom_bank1_rom_write_byte__0
    // BYTE1(address)
    // [2478] rom_write_byte::rom_bank1_$1 = byte1  rom_write_byte::address#4 -- vbuz1=_byte1_vduz2 
    lda.z address+1
    sta.z rom_bank1_rom_write_byte__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2479] rom_write_byte::rom_bank1_$2 = rom_write_byte::rom_bank1_$0 w= rom_write_byte::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_write_byte__0
    sta.z rom_bank1_rom_write_byte__2+1
    lda.z rom_bank1_rom_write_byte__1
    sta.z rom_bank1_rom_write_byte__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2480] rom_write_byte::rom_bank1_bank_unshifted#0 = rom_write_byte::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2481] rom_write_byte::rom_bank1_return#0 = byte1  rom_write_byte::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwuz2 
    lda.z rom_bank1_bank_unshifted+1
    sta.z rom_bank1_return
    // rom_write_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2482] rom_write_byte::rom_ptr1_$2 = (unsigned int)rom_write_byte::address#4 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_write_byte__2
    lda.z address+1
    sta.z rom_ptr1_rom_write_byte__2+1
    // [2483] rom_write_byte::rom_ptr1_$0 = rom_write_byte::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_write_byte__0
    and #<$3fff
    sta.z rom_ptr1_rom_write_byte__0
    lda.z rom_ptr1_rom_write_byte__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_write_byte__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2484] rom_write_byte::rom_ptr1_return#0 = rom_write_byte::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_write_byte::bank_set_brom1
    // BROM = bank
    // [2485] BROM = rom_write_byte::rom_bank1_return#0 -- vbuz1=vbuz2 
    lda.z rom_bank1_return
    sta.z BROM
    // rom_write_byte::@1
    // *ptr_rom = value
    // [2486] *((char *)rom_write_byte::rom_ptr1_return#0) = rom_write_byte::value#10 -- _deref_pbuz1=vbuz2 
    lda.z value
    ldy #0
    sta (rom_ptr1_return),y
    // rom_write_byte::@return
    // }
    // [2487] return 
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
    // [2489] return 
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
// __mem() int ferror(__zp($63) struct $2 *stream)
ferror: {
    .label ferror__6 = $2a
    .label ferror__15 = $29
    .label cbm_k_setnam1_ferror__0 = $36
    .label stream = $63
    .label errno_len = $41
    // unsigned char sp = (unsigned char)stream
    // [2490] ferror::sp#0 = (char)ferror::stream#0 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_setlfs(15, 8, 15)
    // [2491] cbm_k_setlfs::channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.channel
    // [2492] cbm_k_setlfs::device = 8 -- vbum1=vbuc1 
    lda #8
    sta cbm_k_setlfs.device
    // [2493] cbm_k_setlfs::command = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.command
    // [2494] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // ferror::@11
    // cbm_k_setnam("")
    // [2495] ferror::cbm_k_setnam1_filename = info_text4 -- pbum1=pbuc1 
    lda #<info_text4
    sta cbm_k_setnam1_filename
    lda #>info_text4
    sta cbm_k_setnam1_filename+1
    // ferror::cbm_k_setnam1
    // strlen(filename)
    // [2496] strlen::str#5 = ferror::cbm_k_setnam1_filename -- pbuz1=pbum2 
    lda cbm_k_setnam1_filename
    sta.z strlen.str
    lda cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [2497] call strlen
    // [1938] phi from ferror::cbm_k_setnam1 to strlen [phi:ferror::cbm_k_setnam1->strlen]
    // [1938] phi strlen::str#8 = strlen::str#5 [phi:ferror::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [2498] strlen::return#12 = strlen::len#2
    // ferror::@12
    // [2499] ferror::cbm_k_setnam1_$0 = strlen::return#12 -- vwuz1=vwum2 
    lda strlen.return
    sta.z cbm_k_setnam1_ferror__0
    lda strlen.return+1
    sta.z cbm_k_setnam1_ferror__0+1
    // char filename_len = (char)strlen(filename)
    // [2500] ferror::cbm_k_setnam1_filename_len = (char)ferror::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
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
    // [2503] ferror::cbm_k_chkin1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_chkin1_channel
    // ferror::cbm_k_chkin1
    // char status
    // [2504] ferror::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // ferror::cbm_k_chrin1
    // char ch
    // [2506] ferror::cbm_k_chrin1_ch = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chrin1_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin1_ch
    // return ch;
    // [2508] ferror::cbm_k_chrin1_return#0 = ferror::cbm_k_chrin1_ch -- vbum1=vbum2 
    sta cbm_k_chrin1_return
    // ferror::cbm_k_chrin1_@return
    // }
    // [2509] ferror::cbm_k_chrin1_return#1 = ferror::cbm_k_chrin1_return#0
    // ferror::@7
    // char ch = cbm_k_chrin()
    // [2510] ferror::ch#0 = ferror::cbm_k_chrin1_return#1
    // [2511] phi from ferror::@7 to ferror::cbm_k_readst1 [phi:ferror::@7->ferror::cbm_k_readst1]
    // [2511] phi __errno#179 = __errno#321 [phi:ferror::@7->ferror::cbm_k_readst1#0] -- register_copy 
    // [2511] phi ferror::errno_len#10 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z errno_len
    // [2511] phi ferror::ch#10 = ferror::ch#0 [phi:ferror::@7->ferror::cbm_k_readst1#2] -- register_copy 
    // [2511] phi ferror::errno_parsed#2 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#3] -- vbum1=vbuc1 
    sta errno_parsed
    // ferror::cbm_k_readst1
  cbm_k_readst1:
    // char status
    // [2512] ferror::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2514] ferror::cbm_k_readst1_return#0 = ferror::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // ferror::cbm_k_readst1_@return
    // }
    // [2515] ferror::cbm_k_readst1_return#1 = ferror::cbm_k_readst1_return#0
    // ferror::@8
    // cbm_k_readst()
    // [2516] ferror::$6 = ferror::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z ferror__6
    // st = cbm_k_readst()
    // [2517] ferror::st#1 = ferror::$6 -- vbum1=vbuz2 
    sta st
    // while (!(st = cbm_k_readst()))
    // [2518] if(0==ferror::st#1) goto ferror::@1 -- 0_eq_vbum1_then_la1 
    beq __b1
    // ferror::@2
    // __status = st
    // [2519] ((char *)&__stdio_file+$46)[ferror::sp#0] = ferror::st#1 -- pbuc1_derefidx_vbum1=vbum2 
    ldy sp
    sta __stdio_file+$46,y
    // cbm_k_close(15)
    // [2520] ferror::cbm_k_close1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_close1_channel
    // ferror::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // ferror::@9
    // return __errno;
    // [2522] ferror::return#1 = __errno#179 -- vwsm1=vwsm2 
    lda __errno
    sta return
    lda __errno+1
    sta return+1
    // ferror::@return
    // }
    // [2523] return 
    rts
    // ferror::@1
  __b1:
    // if (!errno_parsed)
    // [2524] if(0!=ferror::errno_parsed#2) goto ferror::@3 -- 0_neq_vbum1_then_la1 
    lda errno_parsed
    bne __b3
    // ferror::@4
    // if (ch == ',')
    // [2525] if(ferror::ch#10!=',') goto ferror::@3 -- vbum1_neq_vbuc1_then_la1 
    lda #','
    cmp ch
    bne __b3
    // ferror::@5
    // errno_parsed++;
    // [2526] ferror::errno_parsed#1 = ++ ferror::errno_parsed#2 -- vbum1=_inc_vbum1 
    inc errno_parsed
    // strncpy(temp, __errno_error, errno_len+1)
    // [2527] strncpy::n#0 = ferror::errno_len#10 + 1 -- vwum1=vbuz2_plus_1 
    lda.z errno_len
    clc
    adc #1
    sta strncpy.n
    lda #0
    adc #0
    sta strncpy.n+1
    // [2528] call strncpy
    // [1594] phi from ferror::@5 to strncpy [phi:ferror::@5->strncpy]
    // [1594] phi strncpy::dst#8 = ferror::temp [phi:ferror::@5->strncpy#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z strncpy.dst
    lda #>temp
    sta.z strncpy.dst+1
    // [1594] phi strncpy::src#6 = __errno_error [phi:ferror::@5->strncpy#1] -- pbuz1=pbuc1 
    lda #<__errno_error
    sta.z strncpy.src
    lda #>__errno_error
    sta.z strncpy.src+1
    // [1594] phi strncpy::n#3 = strncpy::n#0 [phi:ferror::@5->strncpy#2] -- register_copy 
    jsr strncpy
    // [2529] phi from ferror::@5 to ferror::@13 [phi:ferror::@5->ferror::@13]
    // ferror::@13
    // atoi(temp)
    // [2530] call atoi
    // [2542] phi from ferror::@13 to atoi [phi:ferror::@13->atoi]
    // [2542] phi atoi::str#2 = ferror::temp [phi:ferror::@13->atoi#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z atoi.str
    lda #>temp
    sta.z atoi.str+1
    jsr atoi
    // atoi(temp)
    // [2531] atoi::return#4 = atoi::return#2
    // ferror::@14
    // __errno = atoi(temp)
    // [2532] __errno#2 = atoi::return#4 -- vwsm1=vwsm2 
    lda atoi.return
    sta __errno
    lda atoi.return+1
    sta __errno+1
    // [2533] phi from ferror::@1 ferror::@14 ferror::@4 to ferror::@3 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3]
    // [2533] phi __errno#103 = __errno#179 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#0] -- register_copy 
    // [2533] phi ferror::errno_parsed#11 = ferror::errno_parsed#2 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#1] -- register_copy 
    // ferror::@3
  __b3:
    // __errno_error[errno_len] = ch
    // [2534] __errno_error[ferror::errno_len#10] = ferror::ch#10 -- pbuc1_derefidx_vbuz1=vbum2 
    lda ch
    ldy.z errno_len
    sta __errno_error,y
    // errno_len++;
    // [2535] ferror::errno_len#1 = ++ ferror::errno_len#10 -- vbuz1=_inc_vbuz1 
    inc.z errno_len
    // ferror::cbm_k_chrin2
    // char ch
    // [2536] ferror::cbm_k_chrin2_ch = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chrin2_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin2_ch
    // return ch;
    // [2538] ferror::cbm_k_chrin2_return#0 = ferror::cbm_k_chrin2_ch -- vbum1=vbum2 
    sta cbm_k_chrin2_return
    // ferror::cbm_k_chrin2_@return
    // }
    // [2539] ferror::cbm_k_chrin2_return#1 = ferror::cbm_k_chrin2_return#0
    // ferror::@10
    // cbm_k_chrin()
    // [2540] ferror::$15 = ferror::cbm_k_chrin2_return#1 -- vbuz1=vbum2 
    sta.z ferror__15
    // ch = cbm_k_chrin()
    // [2541] ferror::ch#1 = ferror::$15 -- vbum1=vbuz2 
    sta ch
    // [2511] phi from ferror::@10 to ferror::cbm_k_readst1 [phi:ferror::@10->ferror::cbm_k_readst1]
    // [2511] phi __errno#179 = __errno#103 [phi:ferror::@10->ferror::cbm_k_readst1#0] -- register_copy 
    // [2511] phi ferror::errno_len#10 = ferror::errno_len#1 [phi:ferror::@10->ferror::cbm_k_readst1#1] -- register_copy 
    // [2511] phi ferror::ch#10 = ferror::ch#1 [phi:ferror::@10->ferror::cbm_k_readst1#2] -- register_copy 
    // [2511] phi ferror::errno_parsed#2 = ferror::errno_parsed#11 [phi:ferror::@10->ferror::cbm_k_readst1#3] -- register_copy 
    jmp cbm_k_readst1
  .segment Data
    temp: .fill 4, 0
    cbm_k_setnam1_filename: .word 0
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
// __mem() int atoi(__zp($b3) const char *str)
atoi: {
    .label atoi__6 = $44
    .label atoi__7 = $44
    .label str = $b3
    .label atoi__10 = $44
    .label atoi__11 = $44
    // if (str[i] == '-')
    // [2543] if(*atoi::str#2!='-') goto atoi::@3 -- _deref_pbuz1_neq_vbuc1_then_la1 
    ldy #0
    lda (str),y
    cmp #'-'
    bne __b2
    // [2544] phi from atoi to atoi::@2 [phi:atoi->atoi::@2]
    // atoi::@2
    // [2545] phi from atoi::@2 to atoi::@3 [phi:atoi::@2->atoi::@3]
    // [2545] phi atoi::negative#2 = 1 [phi:atoi::@2->atoi::@3#0] -- vbum1=vbuc1 
    lda #1
    sta negative
    // [2545] phi atoi::res#2 = 0 [phi:atoi::@2->atoi::@3#1] -- vwsm1=vwsc1 
    tya
    sta res
    sta res+1
    // [2545] phi atoi::i#4 = 1 [phi:atoi::@2->atoi::@3#2] -- vbum1=vbuc1 
    lda #1
    sta i
    jmp __b3
  // Iterate through all digits and update the result
    // [2545] phi from atoi to atoi::@3 [phi:atoi->atoi::@3]
  __b2:
    // [2545] phi atoi::negative#2 = 0 [phi:atoi->atoi::@3#0] -- vbum1=vbuc1 
    lda #0
    sta negative
    // [2545] phi atoi::res#2 = 0 [phi:atoi->atoi::@3#1] -- vwsm1=vwsc1 
    sta res
    sta res+1
    // [2545] phi atoi::i#4 = 0 [phi:atoi->atoi::@3#2] -- vbum1=vbuc1 
    sta i
    // atoi::@3
  __b3:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [2546] if(atoi::str#2[atoi::i#4]<'0') goto atoi::@5 -- pbuz1_derefidx_vbum2_lt_vbuc1_then_la1 
    ldy i
    lda (str),y
    cmp #'0'
    bcc __b5
    // atoi::@6
    // [2547] if(atoi::str#2[atoi::i#4]<='9') goto atoi::@4 -- pbuz1_derefidx_vbum2_le_vbuc1_then_la1 
    lda (str),y
    cmp #'9'
    bcc __b4
    beq __b4
    // atoi::@5
  __b5:
    // if(negative)
    // [2548] if(0!=atoi::negative#2) goto atoi::@1 -- 0_neq_vbum1_then_la1 
    // Return result with sign
    lda negative
    bne __b1
    // [2550] phi from atoi::@1 atoi::@5 to atoi::@return [phi:atoi::@1/atoi::@5->atoi::@return]
    // [2550] phi atoi::return#2 = atoi::return#0 [phi:atoi::@1/atoi::@5->atoi::@return#0] -- register_copy 
    rts
    // atoi::@1
  __b1:
    // return -res;
    // [2549] atoi::return#0 = - atoi::res#2 -- vwsm1=_neg_vwsm1 
    lda #0
    sec
    sbc return
    sta return
    lda #0
    sbc return+1
    sta return+1
    // atoi::@return
    // }
    // [2551] return 
    rts
    // atoi::@4
  __b4:
    // res * 10
    // [2552] atoi::$10 = atoi::res#2 << 2 -- vwsz1=vwsm2_rol_2 
    lda res
    asl
    sta.z atoi__10
    lda res+1
    rol
    sta.z atoi__10+1
    asl.z atoi__10
    rol.z atoi__10+1
    // [2553] atoi::$11 = atoi::$10 + atoi::res#2 -- vwsz1=vwsz1_plus_vwsm2 
    clc
    lda.z atoi__11
    adc res
    sta.z atoi__11
    lda.z atoi__11+1
    adc res+1
    sta.z atoi__11+1
    // [2554] atoi::$6 = atoi::$11 << 1 -- vwsz1=vwsz1_rol_1 
    asl.z atoi__6
    rol.z atoi__6+1
    // res * 10 + str[i]
    // [2555] atoi::$7 = atoi::$6 + atoi::str#2[atoi::i#4] -- vwsz1=vwsz1_plus_pbuz2_derefidx_vbum3 
    ldy i
    lda.z atoi__7
    clc
    adc (str),y
    sta.z atoi__7
    bcc !+
    inc.z atoi__7+1
  !:
    // res = res * 10 + str[i] - '0'
    // [2556] atoi::res#1 = atoi::$7 - '0' -- vwsm1=vwsz2_minus_vbuc1 
    lda.z atoi__7
    sec
    sbc #'0'
    sta res
    lda.z atoi__7+1
    sbc #0
    sta res+1
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [2557] atoi::i#2 = ++ atoi::i#4 -- vbum1=_inc_vbum1 
    inc i
    // [2545] phi from atoi::@4 to atoi::@3 [phi:atoi::@4->atoi::@3]
    // [2545] phi atoi::negative#2 = atoi::negative#2 [phi:atoi::@4->atoi::@3#0] -- register_copy 
    // [2545] phi atoi::res#2 = atoi::res#1 [phi:atoi::@4->atoi::@3#1] -- register_copy 
    // [2545] phi atoi::i#4 = atoi::i#2 [phi:atoi::@4->atoi::@3#2] -- register_copy 
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
// __mem() unsigned int cx16_k_macptr(__mem() volatile char bytes, __zp($ad) void * volatile buffer)
cx16_k_macptr: {
    .label buffer = $ad
    // unsigned int bytes_read
    // [2558] cx16_k_macptr::bytes_read = 0 -- vwum1=vwuc1 
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
    // [2560] cx16_k_macptr::return#0 = cx16_k_macptr::bytes_read -- vwum1=vwum2 
    lda bytes_read
    sta return
    lda bytes_read+1
    sta return+1
    // cx16_k_macptr::@return
    // }
    // [2561] cx16_k_macptr::return#1 = cx16_k_macptr::return#0
    // [2562] return 
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
// __mem() char uctoa_append(__zp($52) char *buffer, __mem() char value, __mem() char sub)
uctoa_append: {
    .label buffer = $52
    // [2564] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [2564] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [2564] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [2565] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbum1_ge_vbum2_then_la1 
    lda value
    cmp sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [2566] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // uctoa_append::@return
    // }
    // [2567] return 
    rts
    // uctoa_append::@2
  __b2:
    // digit++;
    // [2568] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [2569] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbum1=vbum1_minus_vbum2 
    lda value
    sec
    sbc sub
    sta value
    // [2564] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [2564] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [2564] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
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
// __zp($3c) char rom_byte_compare(__zp($5d) char *ptr_rom, __zp($58) char value)
rom_byte_compare: {
    .label return = $3c
    .label ptr_rom = $5d
    .label value = $58
    // if (*ptr_rom != value)
    // [2570] if(*rom_byte_compare::ptr_rom#0==rom_byte_compare::value#0) goto rom_byte_compare::@1 -- _deref_pbuz1_eq_vbuz2_then_la1 
    lda.z value
    ldy #0
    cmp (ptr_rom),y
    beq __b2
    // [2571] phi from rom_byte_compare to rom_byte_compare::@2 [phi:rom_byte_compare->rom_byte_compare::@2]
    // rom_byte_compare::@2
    // [2572] phi from rom_byte_compare::@2 to rom_byte_compare::@1 [phi:rom_byte_compare::@2->rom_byte_compare::@1]
    // [2572] phi rom_byte_compare::return#0 = 0 [phi:rom_byte_compare::@2->rom_byte_compare::@1#0] -- vbuz1=vbuc1 
    tya
    sta.z return
    rts
    // [2572] phi from rom_byte_compare to rom_byte_compare::@1 [phi:rom_byte_compare->rom_byte_compare::@1]
  __b2:
    // [2572] phi rom_byte_compare::return#0 = 1 [phi:rom_byte_compare->rom_byte_compare::@1#0] -- vbuz1=vbuc1 
    lda #1
    sta.z return
    // rom_byte_compare::@1
    // rom_byte_compare::@return
    // }
    // [2573] return 
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
// __mem() unsigned long ultoa_append(__zp($54) char *buffer, __mem() unsigned long value, __mem() unsigned long sub)
ultoa_append: {
    .label buffer = $54
    // [2575] phi from ultoa_append to ultoa_append::@1 [phi:ultoa_append->ultoa_append::@1]
    // [2575] phi ultoa_append::digit#2 = 0 [phi:ultoa_append->ultoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [2575] phi ultoa_append::value#2 = ultoa_append::value#0 [phi:ultoa_append->ultoa_append::@1#1] -- register_copy 
    // ultoa_append::@1
  __b1:
    // while (value >= sub)
    // [2576] if(ultoa_append::value#2>=ultoa_append::sub#0) goto ultoa_append::@2 -- vdum1_ge_vdum2_then_la1 
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
    // [2577] *ultoa_append::buffer#0 = DIGITS[ultoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // ultoa_append::@return
    // }
    // [2578] return 
    rts
    // ultoa_append::@2
  __b2:
    // digit++;
    // [2579] ultoa_append::digit#1 = ++ ultoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [2580] ultoa_append::value#1 = ultoa_append::value#2 - ultoa_append::sub#0 -- vdum1=vdum1_minus_vdum2 
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
    // [2575] phi from ultoa_append::@2 to ultoa_append::@1 [phi:ultoa_append::@2->ultoa_append::@1]
    // [2575] phi ultoa_append::digit#2 = ultoa_append::digit#1 [phi:ultoa_append::@2->ultoa_append::@1#0] -- register_copy 
    // [2575] phi ultoa_append::value#2 = ultoa_append::value#1 [phi:ultoa_append::@2->ultoa_append::@1#1] -- register_copy 
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
    .label rom_wait__0 = $2a
    .label rom_wait__1 = $29
    .label test1 = $2a
    .label test2 = $29
    .label ptr_rom = $2d
    // rom_wait::@1
  __b1:
    // test1 = *((brom_ptr_t)ptr_rom)
    // [2582] rom_wait::test1#1 = *rom_wait::ptr_rom#3 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (ptr_rom),y
    sta.z test1
    // test2 = *((brom_ptr_t)ptr_rom)
    // [2583] rom_wait::test2#1 = *rom_wait::ptr_rom#3 -- vbuz1=_deref_pbuz2 
    lda (ptr_rom),y
    sta.z test2
    // test1 & 0x40
    // [2584] rom_wait::$0 = rom_wait::test1#1 & $40 -- vbuz1=vbuz1_band_vbuc1 
    lda #$40
    and.z rom_wait__0
    sta.z rom_wait__0
    // test2 & 0x40
    // [2585] rom_wait::$1 = rom_wait::test2#1 & $40 -- vbuz1=vbuz1_band_vbuc1 
    lda #$40
    and.z rom_wait__1
    sta.z rom_wait__1
    // while ((test1 & 0x40) != (test2 & 0x40))
    // [2586] if(rom_wait::$0!=rom_wait::$1) goto rom_wait::@1 -- vbuz1_neq_vbuz2_then_la1 
    lda.z rom_wait__0
    cmp.z rom_wait__1
    bne __b1
    // rom_wait::@return
    // }
    // [2587] return 
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
// void rom_byte_program(__zp($3d) unsigned long address, __zp($42) char value)
rom_byte_program: {
    .label rom_ptr1_rom_byte_program__0 = $44
    .label rom_ptr1_rom_byte_program__2 = $44
    .label rom_ptr1_return = $44
    .label address = $3d
    .label value = $42
    // rom_byte_program::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2589] rom_byte_program::rom_ptr1_$2 = (unsigned int)rom_byte_program::address#0 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_byte_program__2
    lda.z address+1
    sta.z rom_ptr1_rom_byte_program__2+1
    // [2590] rom_byte_program::rom_ptr1_$0 = rom_byte_program::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_byte_program__0
    and #<$3fff
    sta.z rom_ptr1_rom_byte_program__0
    lda.z rom_ptr1_rom_byte_program__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_byte_program__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2591] rom_byte_program::rom_ptr1_return#0 = rom_byte_program::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_byte_program::@1
    // rom_write_byte(address, value)
    // [2592] rom_write_byte::address#3 = rom_byte_program::address#0
    // [2593] rom_write_byte::value#3 = rom_byte_program::value#0
    // [2594] call rom_write_byte
    // [2476] phi from rom_byte_program::@1 to rom_write_byte [phi:rom_byte_program::@1->rom_write_byte]
    // [2476] phi rom_write_byte::value#10 = rom_write_byte::value#3 [phi:rom_byte_program::@1->rom_write_byte#0] -- register_copy 
    // [2476] phi rom_write_byte::address#4 = rom_write_byte::address#3 [phi:rom_byte_program::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_byte_program::@2
    // rom_wait(ptr_rom)
    // [2595] rom_wait::ptr_rom#1 = (char *)rom_byte_program::rom_ptr1_return#0 -- pbuz1=pbuz2 
    lda.z rom_ptr1_return
    sta.z rom_wait.ptr_rom
    lda.z rom_ptr1_return+1
    sta.z rom_wait.ptr_rom+1
    // [2596] call rom_wait
    // [2581] phi from rom_byte_program::@2 to rom_wait [phi:rom_byte_program::@2->rom_wait]
    // [2581] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#1 [phi:rom_byte_program::@2->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_byte_program::@return
    // }
    // [2597] return 
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
    // [2598] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [2599] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte0_vwum2 
    lda soffset_vram
    sta.z memcpy8_vram_vram__0
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [2600] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [2601] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte1_vwum2 
    lda soffset_vram+1
    sta.z memcpy8_vram_vram__1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [2602] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [2603] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbuz1=vbum2_bor_vbuc1 
    lda #VERA_INC_1
    ora sbank_vram
    sta.z memcpy8_vram_vram__2
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [2604] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [2605] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [2606] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte0_vwum2 
    lda doffset_vram
    sta.z memcpy8_vram_vram__3
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [2607] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [2608] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte1_vwum2 
    lda doffset_vram+1
    sta.z memcpy8_vram_vram__4
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [2609] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [2610] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbuz1=vbum2_bor_vbuc1 
    lda #VERA_INC_1
    ora dbank_vram
    sta.z memcpy8_vram_vram__5
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [2611] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // [2612] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [2612] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [2613] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbum1=_dec_vbum2 
    ldy num8_1
    dey
    sty num8
    // [2614] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbum1_then_la1 
    lda num8_1
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [2615] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [2616] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [2617] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbum1=vbum2 
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
  __stdio_file: .fill SIZEOF_STRUCT___2, 0
  __stdio_filecount: .byte 0
  __errno: .word 0
  // Globals
  status_smc: .byte 0
  status_vera: .byte 0
  // Globals (to save zeropage and code overhead with parameter passing.)
  smc_bootloader: .word 0
  smc_file_size: .word 0
  smc_file_size_1: .word 0
  smc_file_size_2: .word 0
