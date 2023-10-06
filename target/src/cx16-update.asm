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
  // #define __ROM_CHIP_DETECT
  // #define __SMC_CHIP_DETECT
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
  .label __snprintf_buffer = $e8
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
    // [555] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [555] phi textcolor::color#18 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [22] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [23] call bgcolor
    // [560] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [560] phi bgcolor::color#14 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbum1=vbuc1 
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
    // [573] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [573] phi gotoxy::y#30 = gotoxy::y#2 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [573] phi gotoxy::x#30 = gotoxy::x#2 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
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
    .label main__115 = $c9
    .label check_status_smc1_main__0 = $db
    .label check_status_smc2_main__0 = $e1
    .label check_status_cx16_rom1_check_status_rom1_main__0 = $ea
    .label check_status_cx16_rom2_check_status_rom1_main__0 = $f3
    .label check_status_cx16_rom3_check_status_rom1_main__0 = $ef
    .label check_status_smc5_main__0 = $d5
    .label check_status_cx16_rom4_check_status_rom1_main__0 = $ed
    .label check_status_smc6_main__0 = $cf
    .label check_status_vera3_main__0 = $c1
    .label check_status_smc1_return = $db
    .label check_status_smc2_return = $e1
    .label check_status_cx16_rom1_check_status_rom1_return = $ea
    .label rom_bytes_read = $f4
    .label rom_file_modulo = $f8
    .label check_status_cx16_rom2_check_status_rom1_return = $f3
    .label check_status_cx16_rom3_check_status_rom1_return = $ef
    .label check_status_smc5_return = $d5
    .label check_status_cx16_rom4_check_status_rom1_return = $ed
    .label check_status_smc6_return = $cf
    .label rom_bytes_read1 = $f4
    .label rom_differences = $c4
    .label check_status_vera3_return = $c1
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
    // [73] phi from main::bank_set_brom1 to main::@51 [phi:main::bank_set_brom1->main::@51]
    // main::@51
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
    // [594] phi from main::@51 to display_frame_init_64 [phi:main::@51->display_frame_init_64]
    jsr display_frame_init_64
    // [75] phi from main::@51 to main::@74 [phi:main::@51->main::@74]
    // main::@74
    // display_frame_draw()
    // [76] call display_frame_draw
    // [614] phi from main::@74 to display_frame_draw [phi:main::@74->display_frame_draw]
    jsr display_frame_draw
    // [77] phi from main::@74 to main::@75 [phi:main::@74->main::@75]
    // main::@75
    // display_frame_title("Commander X16 Flash Utility!")
    // [78] call display_frame_title
    // [655] phi from main::@75 to display_frame_title [phi:main::@75->display_frame_title]
    jsr display_frame_title
    // [79] phi from main::@75 to main::display_info_title1 [phi:main::@75->main::display_info_title1]
    // main::display_info_title1
    // cputsxy(INFO_X-2, INFO_Y-2, "# Chip Status    Type   File  / Total Information")
    // [80] call cputsxy
    // [660] phi from main::display_info_title1 to cputsxy [phi:main::display_info_title1->cputsxy]
    // [660] phi cputsxy::s#4 = main::s [phi:main::display_info_title1->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z cputsxy.s
    lda #>s
    sta.z cputsxy.s+1
    // [660] phi cputsxy::y#4 = $11-2 [phi:main::display_info_title1->cputsxy#1] -- vbum1=vbuc1 
    lda #$11-2
    sta cputsxy.y
    // [660] phi cputsxy::x#4 = 4-2 [phi:main::display_info_title1->cputsxy#2] -- vbum1=vbuc1 
    lda #4-2
    sta cputsxy.x
    jsr cputsxy
    // [81] phi from main::display_info_title1 to main::@76 [phi:main::display_info_title1->main::@76]
    // main::@76
    // cputsxy(INFO_X-2, INFO_Y-1, "- ---- --------- ------ ----- / ----- --------------------")
    // [82] call cputsxy
    // [660] phi from main::@76 to cputsxy [phi:main::@76->cputsxy]
    // [660] phi cputsxy::s#4 = main::s1 [phi:main::@76->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s1
    sta.z cputsxy.s
    lda #>s1
    sta.z cputsxy.s+1
    // [660] phi cputsxy::y#4 = $11-1 [phi:main::@76->cputsxy#1] -- vbum1=vbuc1 
    lda #$11-1
    sta cputsxy.y
    // [660] phi cputsxy::x#4 = 4-2 [phi:main::@76->cputsxy#2] -- vbum1=vbuc1 
    lda #4-2
    sta cputsxy.x
    jsr cputsxy
    // [83] phi from main::@76 to main::@52 [phi:main::@76->main::@52]
    // main::@52
    // display_action_progress("Introduction ...")
    // [84] call display_action_progress
    // [667] phi from main::@52 to display_action_progress [phi:main::@52->display_action_progress]
    // [667] phi display_action_progress::info_text#14 = main::info_text [phi:main::@52->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [85] phi from main::@52 to main::@77 [phi:main::@52->main::@77]
    // main::@77
    // display_progress_clear()
    // [86] call display_progress_clear
    // [681] phi from main::@77 to display_progress_clear [phi:main::@77->display_progress_clear]
    jsr display_progress_clear
    // [87] phi from main::@77 to main::@78 [phi:main::@77->main::@78]
    // main::@78
    // display_chip_smc()
    // [88] call display_chip_smc
    // [696] phi from main::@78 to display_chip_smc [phi:main::@78->display_chip_smc]
    jsr display_chip_smc
    // [89] phi from main::@78 to main::@79 [phi:main::@78->main::@79]
    // main::@79
    // display_chip_vera()
    // [90] call display_chip_vera
    // [701] phi from main::@79 to display_chip_vera [phi:main::@79->display_chip_vera]
    jsr display_chip_vera
    // [91] phi from main::@79 to main::@80 [phi:main::@79->main::@80]
    // main::@80
    // display_chip_rom()
    // [92] call display_chip_rom
    // [706] phi from main::@80 to display_chip_rom [phi:main::@80->display_chip_rom]
    jsr display_chip_rom
    // [93] phi from main::@80 to main::@81 [phi:main::@80->main::@81]
    // main::@81
    // display_progress_text(display_into_briefing_text, display_intro_briefing_count)
    // [94] call display_progress_text
    // [725] phi from main::@81 to display_progress_text [phi:main::@81->display_progress_text]
    // [725] phi display_progress_text::text#10 = display_into_briefing_text [phi:main::@81->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_into_briefing_text
    sta.z display_progress_text.text
    lda #>display_into_briefing_text
    sta.z display_progress_text.text+1
    // [725] phi display_progress_text::lines#7 = display_intro_briefing_count [phi:main::@81->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_intro_briefing_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [95] phi from main::@81 to main::@82 [phi:main::@81->main::@82]
    // main::@82
    // util_wait_space()
    // [96] call util_wait_space
    // [735] phi from main::@82 to util_wait_space [phi:main::@82->util_wait_space]
    jsr util_wait_space
    // [97] phi from main::@82 to main::@83 [phi:main::@82->main::@83]
    // main::@83
    // display_progress_text(display_into_colors_text, display_intro_colors_count)
    // [98] call display_progress_text
    // [725] phi from main::@83 to display_progress_text [phi:main::@83->display_progress_text]
    // [725] phi display_progress_text::text#10 = display_into_colors_text [phi:main::@83->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_into_colors_text
    sta.z display_progress_text.text
    lda #>display_into_colors_text
    sta.z display_progress_text.text+1
    // [725] phi display_progress_text::lines#7 = display_intro_colors_count [phi:main::@83->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_intro_colors_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [99] phi from main::@83 to main::@8 [phi:main::@83->main::@8]
    // [99] phi main::intro_status#2 = 0 [phi:main::@83->main::@8#0] -- vbum1=vbuc1 
    lda #0
    sta intro_status
    // main::@8
  __b8:
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [100] if(main::intro_status#2<$b) goto main::@9 -- vbum1_lt_vbuc1_then_la1 
    lda intro_status
    cmp #$b
    bcs !__b9+
    jmp __b9
  !__b9:
    // [101] phi from main::@8 to main::@10 [phi:main::@8->main::@10]
    // main::@10
    // util_wait_space()
    // [102] call util_wait_space
    // [735] phi from main::@10 to util_wait_space [phi:main::@10->util_wait_space]
    jsr util_wait_space
    // [103] phi from main::@10 to main::@85 [phi:main::@10->main::@85]
    // main::@85
    // display_progress_clear()
    // [104] call display_progress_clear
    // [681] phi from main::@85 to display_progress_clear [phi:main::@85->display_progress_clear]
    jsr display_progress_clear
    // main::SEI1
    // asm
    // asm { sei  }
    sei
    // [106] phi from main::SEI1 to main::@53 [phi:main::SEI1->main::@53]
    // main::@53
    // smc_detect()
    // [107] call smc_detect
    // [738] phi from main::@53 to smc_detect [phi:main::@53->smc_detect]
    jsr smc_detect
    // [108] phi from main::@53 to main::@86 [phi:main::@53->main::@86]
    // main::@86
    // display_chip_smc()
    // [109] call display_chip_smc
    // [696] phi from main::@86 to display_chip_smc [phi:main::@86->display_chip_smc]
    jsr display_chip_smc
    // [110] phi from main::@86 to main::@11 [phi:main::@86->main::@11]
    // main::@11
    // smc_version(smc_version_string)
    // [111] call smc_version
    jsr smc_version
    // [112] phi from main::@11 to main::@87 [phi:main::@11->main::@87]
    // main::@87
    // sprintf(info_text, "SMC %s, BL v%02x", smc_version_string, smc_bootloader)
    // [113] call snprintf_init
    // [770] phi from main::@87 to snprintf_init [phi:main::@87->snprintf_init]
    // [770] phi snprintf_init::s#25 = info_text [phi:main::@87->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [114] phi from main::@87 to main::@88 [phi:main::@87->main::@88]
    // main::@88
    // sprintf(info_text, "SMC %s, BL v%02x", smc_version_string, smc_bootloader)
    // [115] call printf_str
    // [775] phi from main::@88 to printf_str [phi:main::@88->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:main::@88->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = main::s4 [phi:main::@88->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // [116] phi from main::@88 to main::@89 [phi:main::@88->main::@89]
    // main::@89
    // sprintf(info_text, "SMC %s, BL v%02x", smc_version_string, smc_bootloader)
    // [117] call printf_string
    // [784] phi from main::@89 to printf_string [phi:main::@89->printf_string]
    // [784] phi printf_string::putc#19 = &snputc [phi:main::@89->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [784] phi printf_string::str#19 = smc_version_string [phi:main::@89->printf_string#1] -- pbuz1=pbuc1 
    lda #<smc_version_string
    sta.z printf_string.str
    lda #>smc_version_string
    sta.z printf_string.str+1
    // [784] phi printf_string::format_justify_left#19 = 0 [phi:main::@89->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [784] phi printf_string::format_min_length#19 = 0 [phi:main::@89->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [118] phi from main::@89 to main::@90 [phi:main::@89->main::@90]
    // main::@90
    // sprintf(info_text, "SMC %s, BL v%02x", smc_version_string, smc_bootloader)
    // [119] call printf_str
    // [775] phi from main::@90 to printf_str [phi:main::@90->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:main::@90->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = main::s5 [phi:main::@90->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // [120] phi from main::@90 to main::@91 [phi:main::@90->main::@91]
    // main::@91
    // sprintf(info_text, "SMC %s, BL v%02x", smc_version_string, smc_bootloader)
    // [121] call printf_uint
    // [809] phi from main::@91 to printf_uint [phi:main::@91->printf_uint]
    // [809] phi printf_uint::format_zero_padding#18 = 1 [phi:main::@91->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [809] phi printf_uint::format_min_length#18 = 2 [phi:main::@91->printf_uint#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uint.format_min_length
    // [809] phi printf_uint::putc#18 = &snputc [phi:main::@91->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [809] phi printf_uint::format_radix#18 = HEXADECIMAL [phi:main::@91->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [809] phi printf_uint::uvalue#18 = smc_detect::return#0 [phi:main::@91->printf_uint#4] -- vwum1=vwuc1 
    lda #<smc_detect.return
    sta printf_uint.uvalue
    lda #>smc_detect.return
    sta printf_uint.uvalue+1
    jsr printf_uint
    // main::@92
    // sprintf(info_text, "SMC %s, BL v%02x", smc_version_string, smc_bootloader)
    // [122] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [123] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_smc(STATUS_DETECTED, info_text)
    // [125] call display_info_smc
  // All ok, display bootloader version.
    // [820] phi from main::@92 to display_info_smc [phi:main::@92->display_info_smc]
    // [820] phi display_info_smc::info_text#12 = info_text [phi:main::@92->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_smc.info_text
    lda #>@info_text
    sta.z display_info_smc.info_text+1
    // [820] phi smc_file_size#12 = 0 [phi:main::@92->display_info_smc#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size_2
    sta smc_file_size_2+1
    // [820] phi display_info_smc::info_status#12 = STATUS_DETECTED [phi:main::@92->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_DETECTED
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // main::CLI1
    // asm
    // asm { cli  }
    cli
    // [127] phi from main::CLI1 to main::@54 [phi:main::CLI1->main::@54]
    // main::@54
    // display_chip_vera()
    // [128] call display_chip_vera
  // Detecting VERA FPGA.
    // [701] phi from main::@54 to display_chip_vera [phi:main::@54->display_chip_vera]
    jsr display_chip_vera
    // [129] phi from main::@54 to main::@93 [phi:main::@54->main::@93]
    // main::@93
    // display_info_vera(STATUS_DETECTED, "VERA installed, OK")
    // [130] call display_info_vera
    // [850] phi from main::@93 to display_info_vera [phi:main::@93->display_info_vera]
    // [850] phi display_info_vera::info_text#10 = main::info_text3 [phi:main::@93->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text3
    sta.z display_info_vera.info_text
    lda #>info_text3
    sta.z display_info_vera.info_text+1
    // [850] phi display_info_vera::info_status#2 = STATUS_DETECTED [phi:main::@93->display_info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_DETECTED
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // main::SEI2
    // asm
    // asm { sei  }
    sei
    // [132] phi from main::SEI2 to main::@55 [phi:main::SEI2->main::@55]
    // main::@55
    // rom_detect()
    // [133] call rom_detect
  // Detecting ROM chips
    // [876] phi from main::@55 to rom_detect [phi:main::@55->rom_detect]
    jsr rom_detect
    // [134] phi from main::@55 to main::@94 [phi:main::@55->main::@94]
    // main::@94
    // display_chip_rom()
    // [135] call display_chip_rom
    // [706] phi from main::@94 to display_chip_rom [phi:main::@94->display_chip_rom]
    jsr display_chip_rom
    // [136] phi from main::@94 to main::@12 [phi:main::@94->main::@12]
    // [136] phi main::rom_chip#2 = 0 [phi:main::@94->main::@12#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // main::@12
  __b12:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [137] if(main::rom_chip#2<8) goto main::@13 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcs !__b13+
    jmp __b13
  !__b13:
    // main::CLI2
    // asm
    // asm { cli  }
    cli
    // main::SEI3
    // asm { sei  }
    sei
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
    // [141] main::check_status_smc1_return#0 = (char)main::check_status_smc1_$0
    // main::@56
    // if(check_status_smc(STATUS_DETECTED))
    // [142] if(0==main::check_status_smc1_return#0) goto main::CLI3 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_smc1_return
    beq __b6
    // [143] phi from main::@56 to main::@17 [phi:main::@56->main::@17]
    // main::@17
    // smc_read()
    // [144] call smc_read
    // [915] phi from main::@17 to smc_read [phi:main::@17->smc_read]
    // [915] phi __errno#35 = 0 [phi:main::@17->smc_read#0] -- vwsm1=vwsc1 
    lda #<0
    sta __errno
    sta __errno+1
    jsr smc_read
    // smc_read()
    // [145] smc_read::return#2 = smc_read::return#0
    // main::@95
    // smc_file_size = smc_read()
    // [146] smc_file_size#0 = smc_read::return#2 -- vwum1=vwuz2 
    lda.z smc_read.return
    sta smc_file_size
    lda.z smc_read.return+1
    sta smc_file_size+1
    // if (!smc_file_size)
    // [147] if(0==smc_file_size#0) goto main::@20 -- 0_eq_vwum1_then_la1 
    // In case no file was found, set the status to error and skip to the next, else, mention the amount of bytes read.
    lda smc_file_size
    ora smc_file_size+1
    bne !__b20+
    jmp __b20
  !__b20:
    // main::@18
    // if(smc_file_size > 0x1E00)
    // [148] if(smc_file_size#0>$1e00) goto main::@21 -- vwum1_gt_vwuc1_then_la1 
    // If the smc.bin file size is larger than 0x1E00 then there is an error!
    lda #>$1e00
    cmp smc_file_size+1
    bcs !__b21+
    jmp __b21
  !__b21:
    bne !+
    lda #<$1e00
    cmp smc_file_size
    bcs !__b21+
    jmp __b21
  !__b21:
  !:
    // main::@19
    // [149] smc_file_size#377 = smc_file_size#0 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_FLASH, NULL)
    // [150] call display_info_smc
  // All ok, display the SMC version and bootloader.
    // [820] phi from main::@19 to display_info_smc [phi:main::@19->display_info_smc]
    // [820] phi display_info_smc::info_text#12 = 0 [phi:main::@19->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [820] phi smc_file_size#12 = smc_file_size#377 [phi:main::@19->display_info_smc#1] -- register_copy 
    // [820] phi display_info_smc::info_status#12 = STATUS_FLASH [phi:main::@19->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASH
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [151] phi from main::@19 main::@20 main::@21 to main::CLI3 [phi:main::@19/main::@20/main::@21->main::CLI3]
    // [151] phi smc_file_size#208 = smc_file_size#0 [phi:main::@19/main::@20/main::@21->main::CLI3#0] -- register_copy 
    // [151] phi __errno#240 = __errno#179 [phi:main::@19/main::@20/main::@21->main::CLI3#1] -- register_copy 
    jmp CLI3
    // [151] phi from main::@56 to main::CLI3 [phi:main::@56->main::CLI3]
  __b6:
    // [151] phi smc_file_size#208 = 0 [phi:main::@56->main::CLI3#0] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size
    sta smc_file_size+1
    // [151] phi __errno#240 = 0 [phi:main::@56->main::CLI3#1] -- vwsm1=vwsc1 
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
    // [154] phi from main::SEI4 to main::@22 [phi:main::SEI4->main::@22]
    // [154] phi __errno#112 = __errno#240 [phi:main::SEI4->main::@22#0] -- register_copy 
    // [154] phi main::rom_chip1#10 = 0 [phi:main::SEI4->main::@22#1] -- vbum1=vbuc1 
    lda #0
    sta rom_chip1
  // We loop all the possible ROM chip slots on the board and on the extension card,
  // and we check the file contents.
  // Any error identified gets reported and this chip will not be flashed.
  // In case of ROM0.BIN in error, no flashing will be done!
    // main::@22
  __b22:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [155] if(main::rom_chip1#10<8) goto main::bank_set_brom2 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip1
    cmp #8
    bcs !bank_set_brom2+
    jmp bank_set_brom2
  !bank_set_brom2:
    // main::bank_set_brom3
    // BROM = bank
    // [156] BROM = main::bank_set_brom3_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom3_bank
    sta.z BROM
    // main::CLI4
    // asm
    // asm { cli  }
    cli
    // main::check_status_smc2
    // status_smc == status
    // [158] main::check_status_smc2_$0 = status_smc#0 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc2_main__0
    // return (unsigned char)(status_smc == status);
    // [159] main::check_status_smc2_return#0 = (char)main::check_status_smc2_$0
    // [160] phi from main::check_status_smc2 to main::check_status_cx16_rom1 [phi:main::check_status_smc2->main::check_status_cx16_rom1]
    // main::check_status_cx16_rom1
    // main::check_status_cx16_rom1_check_status_rom1
    // status_rom[rom_chip] == status
    // [161] main::check_status_cx16_rom1_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_cx16_rom1_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [162] main::check_status_cx16_rom1_check_status_rom1_return#0 = (char)main::check_status_cx16_rom1_check_status_rom1_$0
    // main::@58
    // if(!check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH))
    // [163] if(0!=main::check_status_smc2_return#0) goto main::check_status_smc3 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc2_return
    bne check_status_smc3
    // main::@167
    // [164] if(0!=main::check_status_cx16_rom1_check_status_rom1_return#0) goto main::@29 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_cx16_rom1_check_status_rom1_return
    beq !__b29+
    jmp __b29
  !__b29:
    // main::check_status_smc3
  check_status_smc3:
    // status_smc == status
    // [165] main::check_status_smc3_$0 = status_smc#0 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc3_main__0
    // return (unsigned char)(status_smc == status);
    // [166] main::check_status_smc3_return#0 = (char)main::check_status_smc3_$0
    // [167] phi from main::check_status_smc3 to main::check_status_cx16_rom2 [phi:main::check_status_smc3->main::check_status_cx16_rom2]
    // main::check_status_cx16_rom2
    // main::check_status_cx16_rom2_check_status_rom1
    // status_rom[rom_chip] == status
    // [168] main::check_status_cx16_rom2_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_cx16_rom2_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [169] main::check_status_cx16_rom2_check_status_rom1_return#0 = (char)main::check_status_cx16_rom2_check_status_rom1_$0
    // main::@61
    // if(check_status_smc(STATUS_FLASH) && !check_status_cx16_rom(STATUS_FLASH))
    // [170] if(0==main::check_status_smc3_return#0) goto main::check_status_smc4 -- 0_eq_vbum1_then_la1 
    lda check_status_smc3_return
    beq check_status_smc4
    // main::@168
    // [171] if(0==main::check_status_cx16_rom2_check_status_rom1_return#0) goto main::@2 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_cx16_rom2_check_status_rom1_return
    bne !__b2+
    jmp __b2
  !__b2:
    // main::check_status_smc4
  check_status_smc4:
    // status_smc == status
    // [172] main::check_status_smc4_$0 = status_smc#0 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc4_main__0
    // return (unsigned char)(status_smc == status);
    // [173] main::check_status_smc4_return#0 = (char)main::check_status_smc4_$0
    // [174] phi from main::check_status_smc4 to main::check_status_cx16_rom3 [phi:main::check_status_smc4->main::check_status_cx16_rom3]
    // main::check_status_cx16_rom3
    // main::check_status_cx16_rom3_check_status_rom1
    // status_rom[rom_chip] == status
    // [175] main::check_status_cx16_rom3_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_cx16_rom3_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [176] main::check_status_cx16_rom3_check_status_rom1_return#0 = (char)main::check_status_cx16_rom3_check_status_rom1_$0
    // [177] phi from main::check_status_cx16_rom3_check_status_rom1 to main::check_status_card_roms1 [phi:main::check_status_cx16_rom3_check_status_rom1->main::check_status_card_roms1]
    // main::check_status_card_roms1
    // [178] phi from main::check_status_card_roms1 to main::check_status_card_roms1_@1 [phi:main::check_status_card_roms1->main::check_status_card_roms1_@1]
    // [178] phi main::check_status_card_roms1_rom_chip#2 = 1 [phi:main::check_status_card_roms1->main::check_status_card_roms1_@1#0] -- vbum1=vbuc1 
    lda #1
    sta check_status_card_roms1_rom_chip
    // main::check_status_card_roms1_@1
  check_status_card_roms1___b1:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [179] if(main::check_status_card_roms1_rom_chip#2<8) goto main::check_status_card_roms1_check_status_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda check_status_card_roms1_rom_chip
    cmp #8
    bcs !check_status_card_roms1_check_status_rom1+
    jmp check_status_card_roms1_check_status_rom1
  !check_status_card_roms1_check_status_rom1:
    // [180] phi from main::check_status_card_roms1_@1 to main::check_status_card_roms1_@return [phi:main::check_status_card_roms1_@1->main::check_status_card_roms1_@return]
    // [180] phi main::check_status_card_roms1_return#2 = STATUS_NONE [phi:main::check_status_card_roms1_@1->main::check_status_card_roms1_@return#0] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta check_status_card_roms1_return
    // main::check_status_card_roms1_@return
    // main::@62
  __b62:
    // if(check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH) || check_status_card_roms(STATUS_FLASH))
    // [181] if(0==main::check_status_smc4_return#0) goto main::@169 -- 0_eq_vbum1_then_la1 
    lda check_status_smc4_return
    beq __b169
    // main::@170
    // [182] if(0!=main::check_status_cx16_rom3_check_status_rom1_return#0) goto main::@3 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_cx16_rom3_check_status_rom1_return
    beq !__b3+
    jmp __b3
  !__b3:
    // main::@169
  __b169:
    // [183] if(0!=main::check_status_card_roms1_return#2) goto main::@3 -- 0_neq_vbum1_then_la1 
    lda check_status_card_roms1_return
    beq !__b3+
    jmp __b3
  !__b3:
    // main::SEI5
  SEI5:
    // asm
    // asm { sei  }
    sei
    // main::check_status_smc5
    // status_smc == status
    // [185] main::check_status_smc5_$0 = status_smc#0 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc5_main__0
    // return (unsigned char)(status_smc == status);
    // [186] main::check_status_smc5_return#0 = (char)main::check_status_smc5_$0
    // [187] phi from main::check_status_smc5 to main::check_status_cx16_rom4 [phi:main::check_status_smc5->main::check_status_cx16_rom4]
    // main::check_status_cx16_rom4
    // main::check_status_cx16_rom4_check_status_rom1
    // status_rom[rom_chip] == status
    // [188] main::check_status_cx16_rom4_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_cx16_rom4_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [189] main::check_status_cx16_rom4_check_status_rom1_return#0 = (char)main::check_status_cx16_rom4_check_status_rom1_$0
    // main::@63
    // if (check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH))
    // [190] if(0==main::check_status_smc5_return#0) goto main::@1 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_smc5_return
    beq __b1
    // main::@171
    // [191] if(0!=main::check_status_cx16_rom4_check_status_rom1_return#0) goto main::@5 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_cx16_rom4_check_status_rom1_return
    beq !__b5+
    jmp __b5
  !__b5:
    // [192] phi from main::@171 to main::@1 [phi:main::@171->main::@1]
    // [192] phi from main::@128 main::@33 main::@63 main::@7 to main::@1 [phi:main::@128/main::@33/main::@63/main::@7->main::@1]
    // [192] phi __errno#395 = __errno#179 [phi:main::@128/main::@33/main::@63/main::@7->main::@1#0] -- register_copy 
    // main::@1
  __b1:
    // [193] phi from main::@1 to main::@34 [phi:main::@1->main::@34]
    // [193] phi __errno#114 = __errno#395 [phi:main::@1->main::@34#0] -- register_copy 
    // [193] phi main::rom_chip3#10 = 7 [phi:main::@1->main::@34#1] -- vbum1=vbuc1 
    lda #7
    sta rom_chip3
  // Flash the ROM chips. 
  // We loop first all the ROM chips and read the file contents.
  // Then we verify the file contents and flash the ROM only for the differences.
  // If the file contents are the same as the ROM contents, then no flashing is required.
  // IMPORTANT! We start to flash the ROMs on the extension card.
  // The last ROM flashed is the CX16 ROM on the CX16 board!
    // main::@34
  __b34:
    // for(unsigned char rom_chip = 7; rom_chip != 255; rom_chip--)
    // [194] if(main::rom_chip3#10!=$ff) goto main::check_status_rom1 -- vbum1_neq_vbuc1_then_la1 
    lda #$ff
    cmp rom_chip3
    beq !check_status_rom1+
    jmp check_status_rom1
  !check_status_rom1:
    // main::bank_set_brom4
    // BROM = bank
    // [195] BROM = main::bank_set_brom4_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom4_bank
    sta.z BROM
    // main::CLI5
    // asm
    // asm { cli  }
    cli
    // main::check_status_smc6
    // status_smc == status
    // [197] main::check_status_smc6_$0 = status_smc#0 == STATUS_SKIP -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc6_main__0
    // return (unsigned char)(status_smc == status);
    // [198] main::check_status_smc6_return#0 = (char)main::check_status_smc6_$0
    // main::check_status_vera1
    // status_vera == status
    // [199] main::check_status_vera1_$0 = status_vera#0 == STATUS_SKIP -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_vera1_main__0
    // return (unsigned char)(status_vera == status);
    // [200] main::check_status_vera1_return#0 = (char)main::check_status_vera1_$0
    // [201] phi from main::check_status_vera1 to main::check_status_roms_all1 [phi:main::check_status_vera1->main::check_status_roms_all1]
    // main::check_status_roms_all1
    // [202] phi from main::check_status_roms_all1 to main::check_status_roms_all1_@1 [phi:main::check_status_roms_all1->main::check_status_roms_all1_@1]
    // [202] phi main::check_status_roms_all1_rom_chip#2 = 0 [phi:main::check_status_roms_all1->main::check_status_roms_all1_@1#0] -- vbum1=vbuc1 
    lda #0
    sta check_status_roms_all1_rom_chip
    // main::check_status_roms_all1_@1
  check_status_roms_all1___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [203] if(main::check_status_roms_all1_rom_chip#2<8) goto main::check_status_roms_all1_check_status_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda check_status_roms_all1_rom_chip
    cmp #8
    bcs !check_status_roms_all1_check_status_rom1+
    jmp check_status_roms_all1_check_status_rom1
  !check_status_roms_all1_check_status_rom1:
    // [204] phi from main::check_status_roms_all1_@1 to main::check_status_roms_all1_@return [phi:main::check_status_roms_all1_@1->main::check_status_roms_all1_@return]
    // [204] phi main::check_status_roms_all1_return#2 = 1 [phi:main::check_status_roms_all1_@1->main::check_status_roms_all1_@return#0] -- vbum1=vbuc1 
    lda #1
    sta check_status_roms_all1_return
    // main::check_status_roms_all1_@return
    // main::@65
  __b65:
    // if(check_status_smc(STATUS_SKIP) && check_status_vera(STATUS_SKIP) && check_status_roms_all(STATUS_SKIP))
    // [205] if(0==main::check_status_smc6_return#0) goto main::check_status_smc8 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_smc6_return
    beq check_status_smc8
    // main::@173
    // [206] if(0==main::check_status_vera1_return#0) goto main::check_status_smc8 -- 0_eq_vbum1_then_la1 
    lda check_status_vera1_return
    beq check_status_smc8
    // main::@172
    // [207] if(0!=main::check_status_roms_all1_return#2) goto main::vera_display_set_border_color1 -- 0_neq_vbum1_then_la1 
    lda check_status_roms_all1_return
    beq !vera_display_set_border_color1+
    jmp vera_display_set_border_color1
  !vera_display_set_border_color1:
    // main::check_status_smc8
  check_status_smc8:
    // status_smc == status
    // [208] main::check_status_smc8_$0 = status_smc#0 == STATUS_ERROR -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc8_main__0
    // return (unsigned char)(status_smc == status);
    // [209] main::check_status_smc8_return#0 = (char)main::check_status_smc8_$0
    // main::check_status_vera2
    // status_vera == status
    // [210] main::check_status_vera2_$0 = status_vera#0 == STATUS_ERROR -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_vera2_main__0
    // return (unsigned char)(status_vera == status);
    // [211] main::check_status_vera2_return#0 = (char)main::check_status_vera2_$0
    // [212] phi from main::check_status_vera2 to main::check_status_roms1 [phi:main::check_status_vera2->main::check_status_roms1]
    // main::check_status_roms1
    // [213] phi from main::check_status_roms1 to main::check_status_roms1_@1 [phi:main::check_status_roms1->main::check_status_roms1_@1]
    // [213] phi main::check_status_roms1_rom_chip#2 = 0 [phi:main::check_status_roms1->main::check_status_roms1_@1#0] -- vbum1=vbuc1 
    lda #0
    sta check_status_roms1_rom_chip
    // main::check_status_roms1_@1
  check_status_roms1___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [214] if(main::check_status_roms1_rom_chip#2<8) goto main::check_status_roms1_check_status_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda check_status_roms1_rom_chip
    cmp #8
    bcs !check_status_roms1_check_status_rom1+
    jmp check_status_roms1_check_status_rom1
  !check_status_roms1_check_status_rom1:
    // [215] phi from main::check_status_roms1_@1 to main::check_status_roms1_@return [phi:main::check_status_roms1_@1->main::check_status_roms1_@return]
    // [215] phi main::check_status_roms1_return#2 = STATUS_NONE [phi:main::check_status_roms1_@1->main::check_status_roms1_@return#0] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta check_status_roms1_return
    // main::check_status_roms1_@return
    // main::@69
  __b69:
    // if(check_status_smc(STATUS_ERROR) || check_status_vera(STATUS_ERROR) || check_status_roms(STATUS_ERROR))
    // [216] if(0!=main::check_status_smc8_return#0) goto main::vera_display_set_border_color2 -- 0_neq_vbum1_then_la1 
    lda check_status_smc8_return
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::@177
    // [217] if(0!=main::check_status_vera2_return#0) goto main::vera_display_set_border_color2 -- 0_neq_vbum1_then_la1 
    lda check_status_vera2_return
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::@176
    // [218] if(0!=main::check_status_roms1_return#2) goto main::vera_display_set_border_color2 -- 0_neq_vbum1_then_la1 
    lda check_status_roms1_return
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::check_status_smc9
    // status_smc == status
    // [219] main::check_status_smc9_$0 = status_smc#0 == STATUS_ISSUE -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc9_main__0
    // return (unsigned char)(status_smc == status);
    // [220] main::check_status_smc9_return#0 = (char)main::check_status_smc9_$0
    // main::check_status_vera3
    // status_vera == status
    // [221] main::check_status_vera3_$0 = status_vera#0 == STATUS_ISSUE -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_vera3_main__0
    // return (unsigned char)(status_vera == status);
    // [222] main::check_status_vera3_return#0 = (char)main::check_status_vera3_$0
    // [223] phi from main::check_status_vera3 to main::check_status_roms2 [phi:main::check_status_vera3->main::check_status_roms2]
    // main::check_status_roms2
    // [224] phi from main::check_status_roms2 to main::check_status_roms2_@1 [phi:main::check_status_roms2->main::check_status_roms2_@1]
    // [224] phi main::check_status_roms2_rom_chip#2 = 0 [phi:main::check_status_roms2->main::check_status_roms2_@1#0] -- vbum1=vbuc1 
    lda #0
    sta check_status_roms2_rom_chip
    // main::check_status_roms2_@1
  check_status_roms2___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [225] if(main::check_status_roms2_rom_chip#2<8) goto main::check_status_roms2_check_status_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda check_status_roms2_rom_chip
    cmp #8
    bcs !check_status_roms2_check_status_rom1+
    jmp check_status_roms2_check_status_rom1
  !check_status_roms2_check_status_rom1:
    // [226] phi from main::check_status_roms2_@1 to main::check_status_roms2_@return [phi:main::check_status_roms2_@1->main::check_status_roms2_@return]
    // [226] phi main::check_status_roms2_return#2 = STATUS_NONE [phi:main::check_status_roms2_@1->main::check_status_roms2_@return#0] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta check_status_roms2_return
    // main::check_status_roms2_@return
    // main::@71
  __b71:
    // if(check_status_smc(STATUS_ISSUE) || check_status_vera(STATUS_ISSUE) || check_status_roms(STATUS_ISSUE))
    // [227] if(0!=main::check_status_smc9_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbum1_then_la1 
    lda check_status_smc9_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::@179
    // [228] if(0!=main::check_status_vera3_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_vera3_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::@178
    // [229] if(0!=main::check_status_roms2_return#2) goto main::vera_display_set_border_color3 -- 0_neq_vbum1_then_la1 
    lda check_status_roms2_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::vera_display_set_border_color4
    // *VERA_CTRL &= ~VERA_DCSEL
    // [230] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [231] *VERA_DC_BORDER = GREEN -- _deref_pbuc1=vbuc2 
    lda #GREEN
    sta VERA_DC_BORDER
    // main::check_status_smc10
    // status_smc == status
    // [232] main::check_status_smc10_$0 = status_smc#0 == STATUS_FLASHED -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASHED
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc10_main__0
    // return (unsigned char)(status_smc == status);
    // [233] main::check_status_smc10_return#0 = (char)main::check_status_smc10_$0
    // main::@73
    // if(check_status_smc(STATUS_FLASHED))
    // [234] if(0!=main::check_status_smc10_return#0) goto main::@43 -- 0_neq_vbum1_then_la1 
    lda check_status_smc10_return
    beq !__b43+
    jmp __b43
  !__b43:
    // [235] phi from main::@73 to main::@42 [phi:main::@73->main::@42]
    // main::@42
    // display_progress_text(display_debriefing_text_rom, display_debriefing_count_rom)
    // [236] call display_progress_text
    // [725] phi from main::@42 to display_progress_text [phi:main::@42->display_progress_text]
    // [725] phi display_progress_text::text#10 = display_debriefing_text_rom [phi:main::@42->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_debriefing_text_rom
    sta.z display_progress_text.text
    lda #>display_debriefing_text_rom
    sta.z display_progress_text.text+1
    // [725] phi display_progress_text::lines#7 = display_debriefing_count_rom [phi:main::@42->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_debriefing_count_rom
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [237] phi from main::@160 main::@42 main::@68 main::@72 to main::@48 [phi:main::@160/main::@42/main::@68/main::@72->main::@48]
  __b7:
    // [237] phi main::w1#2 = $c8 [phi:main::@160/main::@42/main::@68/main::@72->main::@48#0] -- vbum1=vbuc1 
    lda #$c8
    sta w1
    // main::@48
  __b48:
    // for (unsigned char w=200; w>0; w--)
    // [238] if(main::w1#2>0) goto main::@49 -- vbum1_gt_0_then_la1 
    lda w1
    bne __b49
    // [239] phi from main::@48 to main::@50 [phi:main::@48->main::@50]
    // main::@50
    // system_reset()
    // [240] call system_reset
    // [972] phi from main::@50 to system_reset [phi:main::@50->system_reset]
    jsr system_reset
    // main::@return
    // }
    // [241] return 
    rts
    // [242] phi from main::@48 to main::@49 [phi:main::@48->main::@49]
    // main::@49
  __b49:
    // wait_moment()
    // [243] call wait_moment
    // [977] phi from main::@49 to wait_moment [phi:main::@49->wait_moment]
    jsr wait_moment
    // [244] phi from main::@49 to main::@161 [phi:main::@49->main::@161]
    // main::@161
    // sprintf(info_text, " (%03u) Your CX16 will reset ...", w)
    // [245] call snprintf_init
    // [770] phi from main::@161 to snprintf_init [phi:main::@161->snprintf_init]
    // [770] phi snprintf_init::s#25 = info_text [phi:main::@161->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [246] phi from main::@161 to main::@162 [phi:main::@161->main::@162]
    // main::@162
    // sprintf(info_text, " (%03u) Your CX16 will reset ...", w)
    // [247] call printf_str
    // [775] phi from main::@162 to printf_str [phi:main::@162->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:main::@162->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = main::s21 [phi:main::@162->printf_str#1] -- pbuz1=pbuc1 
    lda #<s21
    sta.z printf_str.s
    lda #>s21
    sta.z printf_str.s+1
    jsr printf_str
    // main::@163
    // sprintf(info_text, " (%03u) Your CX16 will reset ...", w)
    // [248] printf_uchar::uvalue#10 = main::w1#2 -- vbum1=vbum2 
    lda w1
    sta printf_uchar.uvalue
    // [249] call printf_uchar
    // [982] phi from main::@163 to printf_uchar [phi:main::@163->printf_uchar]
    // [982] phi printf_uchar::format_zero_padding#11 = 1 [phi:main::@163->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [982] phi printf_uchar::format_min_length#11 = 3 [phi:main::@163->printf_uchar#1] -- vbum1=vbuc1 
    lda #3
    sta printf_uchar.format_min_length
    // [982] phi printf_uchar::putc#11 = &snputc [phi:main::@163->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [982] phi printf_uchar::format_radix#11 = DECIMAL [phi:main::@163->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [982] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#10 [phi:main::@163->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [250] phi from main::@163 to main::@164 [phi:main::@163->main::@164]
    // main::@164
    // sprintf(info_text, " (%03u) Your CX16 will reset ...", w)
    // [251] call printf_str
    // [775] phi from main::@164 to printf_str [phi:main::@164->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:main::@164->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = main::s22 [phi:main::@164->printf_str#1] -- pbuz1=pbuc1 
    lda #<s22
    sta.z printf_str.s
    lda #>s22
    sta.z printf_str.s+1
    jsr printf_str
    // main::@165
    // sprintf(info_text, " (%03u) Your CX16 will reset ...", w)
    // [252] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [253] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [255] call display_action_text
    // [993] phi from main::@165 to display_action_text [phi:main::@165->display_action_text]
    // [993] phi display_action_text::info_text#19 = info_text [phi:main::@165->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@166
    // for (unsigned char w=200; w>0; w--)
    // [256] main::w1#1 = -- main::w1#2 -- vbum1=_dec_vbum1 
    dec w1
    // [237] phi from main::@166 to main::@48 [phi:main::@166->main::@48]
    // [237] phi main::w1#2 = main::w1#1 [phi:main::@166->main::@48#0] -- register_copy 
    jmp __b48
    // [257] phi from main::@73 to main::@43 [phi:main::@73->main::@43]
    // main::@43
  __b43:
    // display_progress_text(display_debriefing_text_smc, display_debriefing_count_smc)
    // [258] call display_progress_text
    // [725] phi from main::@43 to display_progress_text [phi:main::@43->display_progress_text]
    // [725] phi display_progress_text::text#10 = display_debriefing_text_smc [phi:main::@43->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_debriefing_text_smc
    sta.z display_progress_text.text
    lda #>display_debriefing_text_smc
    sta.z display_progress_text.text+1
    // [725] phi display_progress_text::lines#7 = display_debriefing_count_smc [phi:main::@43->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_debriefing_count_smc
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [259] phi from main::@43 to main::@44 [phi:main::@43->main::@44]
    // [259] phi main::w#2 = $80 [phi:main::@43->main::@44#0] -- vbum1=vbuc1 
    lda #$80
    sta w
    // main::@44
  __b44:
    // for (unsigned char w=128; w>0; w--)
    // [260] if(main::w#2>0) goto main::@45 -- vbum1_gt_0_then_la1 
    lda w
    bne __b45
    // [261] phi from main::@44 to main::@46 [phi:main::@44->main::@46]
    // main::@46
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [262] call snprintf_init
    // [770] phi from main::@46 to snprintf_init [phi:main::@46->snprintf_init]
    // [770] phi snprintf_init::s#25 = info_text [phi:main::@46->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [263] phi from main::@46 to main::@158 [phi:main::@46->main::@158]
    // main::@158
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [264] call printf_str
    // [775] phi from main::@158 to printf_str [phi:main::@158->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:main::@158->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = main::s20 [phi:main::@158->printf_str#1] -- pbuz1=pbuc1 
    lda #<s20
    sta.z printf_str.s
    lda #>s20
    sta.z printf_str.s+1
    jsr printf_str
    // main::@159
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [265] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [266] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [268] call display_action_text
    // [993] phi from main::@159 to display_action_text [phi:main::@159->display_action_text]
    // [993] phi display_action_text::info_text#19 = info_text [phi:main::@159->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [269] phi from main::@159 to main::@160 [phi:main::@159->main::@160]
    // main::@160
    // smc_reset()
    // [270] call smc_reset
    // [1007] phi from main::@160 to smc_reset [phi:main::@160->smc_reset]
    jsr smc_reset
    jmp __b7
    // [271] phi from main::@44 to main::@45 [phi:main::@44->main::@45]
    // main::@45
  __b45:
    // wait_moment()
    // [272] call wait_moment
    // [977] phi from main::@45 to wait_moment [phi:main::@45->wait_moment]
    jsr wait_moment
    // [273] phi from main::@45 to main::@152 [phi:main::@45->main::@152]
    // main::@152
    // sprintf(info_text, "Please read carefully the below (%u) ...", w)
    // [274] call snprintf_init
    // [770] phi from main::@152 to snprintf_init [phi:main::@152->snprintf_init]
    // [770] phi snprintf_init::s#25 = info_text [phi:main::@152->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [275] phi from main::@152 to main::@153 [phi:main::@152->main::@153]
    // main::@153
    // sprintf(info_text, "Please read carefully the below (%u) ...", w)
    // [276] call printf_str
    // [775] phi from main::@153 to printf_str [phi:main::@153->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:main::@153->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = main::s18 [phi:main::@153->printf_str#1] -- pbuz1=pbuc1 
    lda #<s18
    sta.z printf_str.s
    lda #>s18
    sta.z printf_str.s+1
    jsr printf_str
    // main::@154
    // sprintf(info_text, "Please read carefully the below (%u) ...", w)
    // [277] printf_uchar::uvalue#9 = main::w#2 -- vbum1=vbum2 
    lda w
    sta printf_uchar.uvalue
    // [278] call printf_uchar
    // [982] phi from main::@154 to printf_uchar [phi:main::@154->printf_uchar]
    // [982] phi printf_uchar::format_zero_padding#11 = 0 [phi:main::@154->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [982] phi printf_uchar::format_min_length#11 = 0 [phi:main::@154->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [982] phi printf_uchar::putc#11 = &snputc [phi:main::@154->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [982] phi printf_uchar::format_radix#11 = DECIMAL [phi:main::@154->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [982] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#9 [phi:main::@154->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [279] phi from main::@154 to main::@155 [phi:main::@154->main::@155]
    // main::@155
    // sprintf(info_text, "Please read carefully the below (%u) ...", w)
    // [280] call printf_str
    // [775] phi from main::@155 to printf_str [phi:main::@155->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:main::@155->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = main::s19 [phi:main::@155->printf_str#1] -- pbuz1=pbuc1 
    lda #<s19
    sta.z printf_str.s
    lda #>s19
    sta.z printf_str.s+1
    jsr printf_str
    // main::@156
    // sprintf(info_text, "Please read carefully the below (%u) ...", w)
    // [281] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [282] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [284] call display_action_text
    // [993] phi from main::@156 to display_action_text [phi:main::@156->display_action_text]
    // [993] phi display_action_text::info_text#19 = info_text [phi:main::@156->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@157
    // for (unsigned char w=128; w>0; w--)
    // [285] main::w#1 = -- main::w#2 -- vbum1=_dec_vbum1 
    dec w
    // [259] phi from main::@157 to main::@44 [phi:main::@157->main::@44]
    // [259] phi main::w#2 = main::w#1 [phi:main::@157->main::@44#0] -- register_copy 
    jmp __b44
    // main::vera_display_set_border_color3
  vera_display_set_border_color3:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [286] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [287] *VERA_DC_BORDER = YELLOW -- _deref_pbuc1=vbuc2 
    lda #YELLOW
    sta VERA_DC_BORDER
    // [288] phi from main::vera_display_set_border_color3 to main::@72 [phi:main::vera_display_set_border_color3->main::@72]
    // main::@72
    // display_action_progress("Update issues, your CX16 is not updated!")
    // [289] call display_action_progress
    // [667] phi from main::@72 to display_action_progress [phi:main::@72->display_action_progress]
    // [667] phi display_action_progress::info_text#14 = main::info_text28 [phi:main::@72->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text28
    sta.z display_action_progress.info_text
    lda #>info_text28
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    jmp __b7
    // main::check_status_roms2_check_status_rom1
  check_status_roms2_check_status_rom1:
    // status_rom[rom_chip] == status
    // [290] main::check_status_roms2_check_status_rom1_$0 = status_rom[main::check_status_roms2_rom_chip#2] == STATUS_ISSUE -- vbom1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_ISSUE
    ldy check_status_roms2_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_roms2_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [291] main::check_status_roms2_check_status_rom1_return#0 = (char)main::check_status_roms2_check_status_rom1_$0
    // main::check_status_roms2_@11
    // if(check_status_rom(rom_chip, status))
    // [292] if(0==main::check_status_roms2_check_status_rom1_return#0) goto main::check_status_roms2_@4 -- 0_eq_vbum1_then_la1 
    lda check_status_roms2_check_status_rom1_return
    beq check_status_roms2___b4
    // [226] phi from main::check_status_roms2_@11 to main::check_status_roms2_@return [phi:main::check_status_roms2_@11->main::check_status_roms2_@return]
    // [226] phi main::check_status_roms2_return#2 = STATUS_ISSUE [phi:main::check_status_roms2_@11->main::check_status_roms2_@return#0] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta check_status_roms2_return
    jmp __b71
    // main::check_status_roms2_@4
  check_status_roms2___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [293] main::check_status_roms2_rom_chip#1 = ++ main::check_status_roms2_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_status_roms2_rom_chip
    // [224] phi from main::check_status_roms2_@4 to main::check_status_roms2_@1 [phi:main::check_status_roms2_@4->main::check_status_roms2_@1]
    // [224] phi main::check_status_roms2_rom_chip#2 = main::check_status_roms2_rom_chip#1 [phi:main::check_status_roms2_@4->main::check_status_roms2_@1#0] -- register_copy 
    jmp check_status_roms2___b1
    // main::vera_display_set_border_color2
  vera_display_set_border_color2:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [294] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [295] *VERA_DC_BORDER = RED -- _deref_pbuc1=vbuc2 
    lda #RED
    sta VERA_DC_BORDER
    // [296] phi from main::vera_display_set_border_color2 to main::@70 [phi:main::vera_display_set_border_color2->main::@70]
    // main::@70
    // display_action_progress("Update Failure! Your CX16 may be bricked!")
    // [297] call display_action_progress
    // [667] phi from main::@70 to display_action_progress [phi:main::@70->display_action_progress]
    // [667] phi display_action_progress::info_text#14 = main::info_text26 [phi:main::@70->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text26
    sta.z display_action_progress.info_text
    lda #>info_text26
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [298] phi from main::@70 to main::@151 [phi:main::@70->main::@151]
    // main::@151
    // display_action_text("Take a foto of this screen. And shut down power ...")
    // [299] call display_action_text
    // [993] phi from main::@151 to display_action_text [phi:main::@151->display_action_text]
    // [993] phi display_action_text::info_text#19 = main::info_text27 [phi:main::@151->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text27
    sta.z display_action_text.info_text
    lda #>info_text27
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [300] phi from main::@151 main::@47 to main::@47 [phi:main::@151/main::@47->main::@47]
    // main::@47
  __b47:
    jmp __b47
    // main::check_status_roms1_check_status_rom1
  check_status_roms1_check_status_rom1:
    // status_rom[rom_chip] == status
    // [301] main::check_status_roms1_check_status_rom1_$0 = status_rom[main::check_status_roms1_rom_chip#2] == STATUS_ERROR -- vbom1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_ERROR
    ldy check_status_roms1_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_roms1_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [302] main::check_status_roms1_check_status_rom1_return#0 = (char)main::check_status_roms1_check_status_rom1_$0
    // main::check_status_roms1_@11
    // if(check_status_rom(rom_chip, status))
    // [303] if(0==main::check_status_roms1_check_status_rom1_return#0) goto main::check_status_roms1_@4 -- 0_eq_vbum1_then_la1 
    lda check_status_roms1_check_status_rom1_return
    beq check_status_roms1___b4
    // [215] phi from main::check_status_roms1_@11 to main::check_status_roms1_@return [phi:main::check_status_roms1_@11->main::check_status_roms1_@return]
    // [215] phi main::check_status_roms1_return#2 = STATUS_ERROR [phi:main::check_status_roms1_@11->main::check_status_roms1_@return#0] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta check_status_roms1_return
    jmp __b69
    // main::check_status_roms1_@4
  check_status_roms1___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [304] main::check_status_roms1_rom_chip#1 = ++ main::check_status_roms1_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_status_roms1_rom_chip
    // [213] phi from main::check_status_roms1_@4 to main::check_status_roms1_@1 [phi:main::check_status_roms1_@4->main::check_status_roms1_@1]
    // [213] phi main::check_status_roms1_rom_chip#2 = main::check_status_roms1_rom_chip#1 [phi:main::check_status_roms1_@4->main::check_status_roms1_@1#0] -- register_copy 
    jmp check_status_roms1___b1
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
    // [307] phi from main::vera_display_set_border_color1 to main::@68 [phi:main::vera_display_set_border_color1->main::@68]
    // main::@68
    // display_action_progress("The update has been cancelled!")
    // [308] call display_action_progress
    // [667] phi from main::@68 to display_action_progress [phi:main::@68->display_action_progress]
    // [667] phi display_action_progress::info_text#14 = main::info_text25 [phi:main::@68->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text25
    sta.z display_action_progress.info_text
    lda #>info_text25
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    jmp __b7
    // main::check_status_roms_all1_check_status_rom1
  check_status_roms_all1_check_status_rom1:
    // status_rom[rom_chip] == status
    // [309] main::check_status_roms_all1_check_status_rom1_$0 = status_rom[main::check_status_roms_all1_rom_chip#2] == STATUS_SKIP -- vbom1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_SKIP
    ldy check_status_roms_all1_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_roms_all1_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [310] main::check_status_roms_all1_check_status_rom1_return#0 = (char)main::check_status_roms_all1_check_status_rom1_$0
    // main::check_status_roms_all1_@11
    // if(check_status_rom(rom_chip, status) != status)
    // [311] if(main::check_status_roms_all1_check_status_rom1_return#0==STATUS_SKIP) goto main::check_status_roms_all1_@4 -- vbum1_eq_vbuc1_then_la1 
    lda #STATUS_SKIP
    cmp check_status_roms_all1_check_status_rom1_return
    beq check_status_roms_all1___b4
    // [204] phi from main::check_status_roms_all1_@11 to main::check_status_roms_all1_@return [phi:main::check_status_roms_all1_@11->main::check_status_roms_all1_@return]
    // [204] phi main::check_status_roms_all1_return#2 = 0 [phi:main::check_status_roms_all1_@11->main::check_status_roms_all1_@return#0] -- vbum1=vbuc1 
    lda #0
    sta check_status_roms_all1_return
    jmp __b65
    // main::check_status_roms_all1_@4
  check_status_roms_all1___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [312] main::check_status_roms_all1_rom_chip#1 = ++ main::check_status_roms_all1_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_status_roms_all1_rom_chip
    // [202] phi from main::check_status_roms_all1_@4 to main::check_status_roms_all1_@1 [phi:main::check_status_roms_all1_@4->main::check_status_roms_all1_@1]
    // [202] phi main::check_status_roms_all1_rom_chip#2 = main::check_status_roms_all1_rom_chip#1 [phi:main::check_status_roms_all1_@4->main::check_status_roms_all1_@1#0] -- register_copy 
    jmp check_status_roms_all1___b1
    // main::check_status_rom1
  check_status_rom1:
    // status_rom[rom_chip] == status
    // [313] main::check_status_rom1_$0 = status_rom[main::rom_chip3#10] == STATUS_FLASH -- vbom1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_FLASH
    ldy rom_chip3
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [314] main::check_status_rom1_return#0 = (char)main::check_status_rom1_$0
    // main::@64
    // if(check_status_rom(rom_chip, STATUS_FLASH))
    // [315] if(0==main::check_status_rom1_return#0) goto main::@35 -- 0_eq_vbum1_then_la1 
    lda check_status_rom1_return
    beq __b35
    // main::check_status_smc7
    // status_smc == status
    // [316] main::check_status_smc7_$0 = status_smc#0 == STATUS_FLASHED -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASHED
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc7_main__0
    // return (unsigned char)(status_smc == status);
    // [317] main::check_status_smc7_return#0 = (char)main::check_status_smc7_$0
    // main::@66
    // if((rom_chip == 0 && check_status_smc(STATUS_FLASHED)) || (rom_chip != 0))
    // [318] if(main::rom_chip3#10!=0) goto main::@174 -- vbum1_neq_0_then_la1 
    // IMPORTANT! We only flash the CX16 ROM chip if the SMC got flashed succesfully!
    lda rom_chip3
    bne __b174
    // main::@175
    // [319] if(0!=main::check_status_smc7_return#0) goto main::bank_set_brom5 -- 0_neq_vbum1_then_la1 
    lda check_status_smc7_return
    bne bank_set_brom5
    // main::@174
  __b174:
    // [320] if(main::rom_chip3#10!=0) goto main::bank_set_brom5 -- vbum1_neq_0_then_la1 
    lda rom_chip3
    bne bank_set_brom5
    // main::@41
    // display_info_rom(rom_chip, STATUS_ISSUE, "Update SMC failed!")
    // [321] display_info_rom::rom_chip#10 = main::rom_chip3#10 -- vbuz1=vbum2 
    sta.z display_info_rom.rom_chip
    // [322] call display_info_rom
    // [1016] phi from main::@41 to display_info_rom [phi:main::@41->display_info_rom]
    // [1016] phi display_info_rom::info_text#16 = main::info_text20 [phi:main::@41->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text20
    sta.z display_info_rom.info_text
    lda #>info_text20
    sta.z display_info_rom.info_text+1
    // [1016] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#10 [phi:main::@41->display_info_rom#1] -- register_copy 
    // [1016] phi display_info_rom::info_status#16 = STATUS_ISSUE [phi:main::@41->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // [323] phi from main::@139 main::@150 main::@36 main::@40 main::@41 main::@64 to main::@35 [phi:main::@139/main::@150/main::@36/main::@40/main::@41/main::@64->main::@35]
    // [323] phi __errno#396 = __errno#179 [phi:main::@139/main::@150/main::@36/main::@40/main::@41/main::@64->main::@35#0] -- register_copy 
    // main::@35
  __b35:
    // for(unsigned char rom_chip = 7; rom_chip != 255; rom_chip--)
    // [324] main::rom_chip3#1 = -- main::rom_chip3#10 -- vbum1=_dec_vbum1 
    dec rom_chip3
    // [193] phi from main::@35 to main::@34 [phi:main::@35->main::@34]
    // [193] phi __errno#114 = __errno#396 [phi:main::@35->main::@34#0] -- register_copy 
    // [193] phi main::rom_chip3#10 = main::rom_chip3#1 [phi:main::@35->main::@34#1] -- register_copy 
    jmp __b34
    // main::bank_set_brom5
  bank_set_brom5:
    // BROM = bank
    // [325] BROM = main::bank_set_brom5_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom5_bank
    sta.z BROM
    // [326] phi from main::bank_set_brom5 to main::@67 [phi:main::bank_set_brom5->main::@67]
    // main::@67
    // display_progress_clear()
    // [327] call display_progress_clear
    // [681] phi from main::@67 to display_progress_clear [phi:main::@67->display_progress_clear]
    jsr display_progress_clear
    // main::@132
    // unsigned char rom_bank = rom_chip * 32
    // [328] main::rom_bank1#0 = main::rom_chip3#10 << 5 -- vbum1=vbum2_rol_5 
    lda rom_chip3
    asl
    asl
    asl
    asl
    asl
    sta rom_bank1
    // unsigned char* file = rom_file(rom_chip)
    // [329] rom_file::rom_chip#1 = main::rom_chip3#10 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z rom_file.rom_chip
    // [330] call rom_file
    // [1061] phi from main::@132 to rom_file [phi:main::@132->rom_file]
    // [1061] phi rom_file::rom_chip#2 = rom_file::rom_chip#1 [phi:main::@132->rom_file#0] -- register_copy 
    jsr rom_file
    // unsigned char* file = rom_file(rom_chip)
    // [331] rom_file::return#5 = rom_file::return#2
    // main::@133
    // [332] main::file1#0 = rom_file::return#5
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [333] call snprintf_init
    // [770] phi from main::@133 to snprintf_init [phi:main::@133->snprintf_init]
    // [770] phi snprintf_init::s#25 = info_text [phi:main::@133->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [334] phi from main::@133 to main::@134 [phi:main::@133->main::@134]
    // main::@134
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [335] call printf_str
    // [775] phi from main::@134 to printf_str [phi:main::@134->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:main::@134->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = s14 [phi:main::@134->printf_str#1] -- pbuz1=pbuc1 
    lda #<s14
    sta.z printf_str.s
    lda #>s14
    sta.z printf_str.s+1
    jsr printf_str
    // main::@135
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [336] printf_string::str#18 = main::file1#0 -- pbuz1=pbum2 
    lda file1
    sta.z printf_string.str
    lda file1+1
    sta.z printf_string.str+1
    // [337] call printf_string
    // [784] phi from main::@135 to printf_string [phi:main::@135->printf_string]
    // [784] phi printf_string::putc#19 = &snputc [phi:main::@135->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [784] phi printf_string::str#19 = printf_string::str#18 [phi:main::@135->printf_string#1] -- register_copy 
    // [784] phi printf_string::format_justify_left#19 = 0 [phi:main::@135->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [784] phi printf_string::format_min_length#19 = 0 [phi:main::@135->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [338] phi from main::@135 to main::@136 [phi:main::@135->main::@136]
    // main::@136
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [339] call printf_str
    // [775] phi from main::@136 to printf_str [phi:main::@136->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:main::@136->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = main::s7 [phi:main::@136->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@137
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [340] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [341] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_progress(info_text)
    // [343] call display_action_progress
    // [667] phi from main::@137 to display_action_progress [phi:main::@137->display_action_progress]
    // [667] phi display_action_progress::info_text#14 = info_text [phi:main::@137->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_progress.info_text
    lda #>@info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@138
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_READING, rom_bank, rom_sizes[rom_chip])
    // [344] main::$196 = main::rom_chip3#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip3
    asl
    asl
    sta main__196
    // [345] rom_read::file#1 = main::file1#0 -- pbuz1=pbum2 
    lda file1
    sta.z rom_read.file
    lda file1+1
    sta.z rom_read.file+1
    // [346] rom_read::brom_bank_start#2 = main::rom_bank1#0 -- vbuz1=vbum2 
    lda rom_bank1
    sta.z rom_read.brom_bank_start
    // [347] rom_read::rom_size#1 = rom_sizes[main::$196] -- vduz1=pduc1_derefidx_vbum2 
    ldy main__196
    lda rom_sizes,y
    sta.z rom_read.rom_size
    lda rom_sizes+1,y
    sta.z rom_read.rom_size+1
    lda rom_sizes+2,y
    sta.z rom_read.rom_size+2
    lda rom_sizes+3,y
    sta.z rom_read.rom_size+3
    // [348] call rom_read
    // [1067] phi from main::@138 to rom_read [phi:main::@138->rom_read]
    // [1067] phi rom_read::rom_size#12 = rom_read::rom_size#1 [phi:main::@138->rom_read#0] -- register_copy 
    // [1067] phi __errno#106 = __errno#114 [phi:main::@138->rom_read#1] -- register_copy 
    // [1067] phi rom_read::file#11 = rom_read::file#1 [phi:main::@138->rom_read#2] -- register_copy 
    // [1067] phi rom_read::brom_bank_start#21 = rom_read::brom_bank_start#2 [phi:main::@138->rom_read#3] -- register_copy 
    jsr rom_read
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_READING, rom_bank, rom_sizes[rom_chip])
    // [349] rom_read::return#3 = rom_read::return#0
    // main::@139
    // [350] main::rom_bytes_read1#0 = rom_read::return#3
    // if(rom_bytes_read)
    // [351] if(0==main::rom_bytes_read1#0) goto main::@35 -- 0_eq_vduz1_then_la1 
    lda.z rom_bytes_read1
    ora.z rom_bytes_read1+1
    ora.z rom_bytes_read1+2
    ora.z rom_bytes_read1+3
    bne !__b35+
    jmp __b35
  !__b35:
    // [352] phi from main::@139 to main::@38 [phi:main::@139->main::@38]
    // main::@38
    // display_action_progress("Comparing ... (.) same, (*) different.")
    // [353] call display_action_progress
  // Now we compare the RAM with the actual ROM contents.
    // [667] phi from main::@38 to display_action_progress [phi:main::@38->display_action_progress]
    // [667] phi display_action_progress::info_text#14 = main::info_text21 [phi:main::@38->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text21
    sta.z display_action_progress.info_text
    lda #>info_text21
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@140
    // display_info_rom(rom_chip, STATUS_COMPARING, "")
    // [354] display_info_rom::rom_chip#11 = main::rom_chip3#10 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z display_info_rom.rom_chip
    // [355] call display_info_rom
    // [1016] phi from main::@140 to display_info_rom [phi:main::@140->display_info_rom]
    // [1016] phi display_info_rom::info_text#16 = info_text4 [phi:main::@140->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z display_info_rom.info_text
    lda #>info_text4
    sta.z display_info_rom.info_text+1
    // [1016] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#11 [phi:main::@140->display_info_rom#1] -- register_copy 
    // [1016] phi display_info_rom::info_status#16 = STATUS_COMPARING [phi:main::@140->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_COMPARING
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // main::@141
    // unsigned long rom_differences = rom_verify(
    //                         rom_chip, rom_bank, file_sizes[rom_chip])
    // [356] rom_verify::rom_chip#0 = main::rom_chip3#10 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z rom_verify.rom_chip
    // [357] rom_verify::rom_bank_start#0 = main::rom_bank1#0 -- vbum1=vbum2 
    lda rom_bank1
    sta rom_verify.rom_bank_start
    // [358] rom_verify::file_size#0 = file_sizes[main::$196] -- vdum1=pduc1_derefidx_vbum2 
    ldy main__196
    lda file_sizes,y
    sta rom_verify.file_size
    lda file_sizes+1,y
    sta rom_verify.file_size+1
    lda file_sizes+2,y
    sta rom_verify.file_size+2
    lda file_sizes+3,y
    sta rom_verify.file_size+3
    // [359] call rom_verify
    // Verify the ROM...
    jsr rom_verify
    // [360] rom_verify::return#2 = rom_verify::rom_different_bytes#11
    // main::@142
    // [361] main::rom_differences#0 = rom_verify::return#2 -- vduz1=vduz2 
    lda.z rom_verify.return
    sta.z rom_differences
    lda.z rom_verify.return+1
    sta.z rom_differences+1
    lda.z rom_verify.return+2
    sta.z rom_differences+2
    lda.z rom_verify.return+3
    sta.z rom_differences+3
    // if (!rom_differences)
    // [362] if(0==main::rom_differences#0) goto main::@36 -- 0_eq_vduz1_then_la1 
    lda.z rom_differences
    ora.z rom_differences+1
    ora.z rom_differences+2
    ora.z rom_differences+3
    bne !__b36+
    jmp __b36
  !__b36:
    // [363] phi from main::@142 to main::@39 [phi:main::@142->main::@39]
    // main::@39
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [364] call snprintf_init
    // [770] phi from main::@39 to snprintf_init [phi:main::@39->snprintf_init]
    // [770] phi snprintf_init::s#25 = info_text [phi:main::@39->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main::@143
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [365] printf_ulong::uvalue#9 = main::rom_differences#0 -- vdum1=vduz2 
    lda.z rom_differences
    sta printf_ulong.uvalue
    lda.z rom_differences+1
    sta printf_ulong.uvalue+1
    lda.z rom_differences+2
    sta printf_ulong.uvalue+2
    lda.z rom_differences+3
    sta printf_ulong.uvalue+3
    // [366] call printf_ulong
    // [1217] phi from main::@143 to printf_ulong [phi:main::@143->printf_ulong]
    // [1217] phi printf_ulong::format_zero_padding#11 = 1 [phi:main::@143->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1217] phi printf_ulong::format_min_length#11 = 5 [phi:main::@143->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1217] phi printf_ulong::putc#11 = &snputc [phi:main::@143->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1217] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:main::@143->printf_ulong#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1217] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#9 [phi:main::@143->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [367] phi from main::@143 to main::@144 [phi:main::@143->main::@144]
    // main::@144
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [368] call printf_str
    // [775] phi from main::@144 to printf_str [phi:main::@144->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:main::@144->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = main::s16 [phi:main::@144->printf_str#1] -- pbuz1=pbuc1 
    lda #<s16
    sta.z printf_str.s
    lda #>s16
    sta.z printf_str.s+1
    jsr printf_str
    // main::@145
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [369] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [370] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_FLASH, info_text)
    // [372] display_info_rom::rom_chip#13 = main::rom_chip3#10 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z display_info_rom.rom_chip
    // [373] call display_info_rom
    // [1016] phi from main::@145 to display_info_rom [phi:main::@145->display_info_rom]
    // [1016] phi display_info_rom::info_text#16 = info_text [phi:main::@145->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1016] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#13 [phi:main::@145->display_info_rom#1] -- register_copy 
    // [1016] phi display_info_rom::info_status#16 = STATUS_FLASH [phi:main::@145->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASH
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // main::@146
    // unsigned long rom_flash_errors = rom_flash(
    //                             rom_chip, rom_bank, file_sizes[rom_chip])
    // [374] rom_flash::rom_chip#0 = main::rom_chip3#10 -- vbum1=vbum2 
    lda rom_chip3
    sta rom_flash.rom_chip
    // [375] rom_flash::rom_bank_start#0 = main::rom_bank1#0 -- vbum1=vbum2 
    lda rom_bank1
    sta rom_flash.rom_bank_start
    // [376] rom_flash::file_size#0 = file_sizes[main::$196] -- vdum1=pduc1_derefidx_vbum2 
    ldy main__196
    lda file_sizes,y
    sta rom_flash.file_size
    lda file_sizes+1,y
    sta rom_flash.file_size+1
    lda file_sizes+2,y
    sta rom_flash.file_size+2
    lda file_sizes+3,y
    sta rom_flash.file_size+3
    // [377] call rom_flash
    // [1228] phi from main::@146 to rom_flash [phi:main::@146->rom_flash]
    jsr rom_flash
    // unsigned long rom_flash_errors = rom_flash(
    //                             rom_chip, rom_bank, file_sizes[rom_chip])
    // [378] rom_flash::return#2 = rom_flash::flash_errors#10
    // main::@147
    // [379] main::rom_flash_errors#0 = rom_flash::return#2 -- vdum1=vduz2 
    lda.z rom_flash.return
    sta rom_flash_errors
    lda.z rom_flash.return+1
    sta rom_flash_errors+1
    lda.z rom_flash.return+2
    sta rom_flash_errors+2
    lda.z rom_flash.return+3
    sta rom_flash_errors+3
    // if(rom_flash_errors)
    // [380] if(0!=main::rom_flash_errors#0) goto main::@37 -- 0_neq_vdum1_then_la1 
    lda rom_flash_errors
    ora rom_flash_errors+1
    ora rom_flash_errors+2
    ora rom_flash_errors+3
    bne __b37
    // main::@40
    // display_info_rom(rom_chip, STATUS_FLASHED, "OK!")
    // [381] display_info_rom::rom_chip#15 = main::rom_chip3#10 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z display_info_rom.rom_chip
    // [382] call display_info_rom
    // [1016] phi from main::@40 to display_info_rom [phi:main::@40->display_info_rom]
    // [1016] phi display_info_rom::info_text#16 = main::info_text24 [phi:main::@40->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text24
    sta.z display_info_rom.info_text
    lda #>info_text24
    sta.z display_info_rom.info_text+1
    // [1016] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#15 [phi:main::@40->display_info_rom#1] -- register_copy 
    // [1016] phi display_info_rom::info_status#16 = STATUS_FLASHED [phi:main::@40->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHED
    sta.z display_info_rom.info_status
    jsr display_info_rom
    jmp __b35
    // [383] phi from main::@147 to main::@37 [phi:main::@147->main::@37]
    // main::@37
  __b37:
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [384] call snprintf_init
    // [770] phi from main::@37 to snprintf_init [phi:main::@37->snprintf_init]
    // [770] phi snprintf_init::s#25 = info_text [phi:main::@37->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main::@148
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [385] printf_ulong::uvalue#10 = main::rom_flash_errors#0 -- vdum1=vdum2 
    lda rom_flash_errors
    sta printf_ulong.uvalue
    lda rom_flash_errors+1
    sta printf_ulong.uvalue+1
    lda rom_flash_errors+2
    sta printf_ulong.uvalue+2
    lda rom_flash_errors+3
    sta printf_ulong.uvalue+3
    // [386] call printf_ulong
    // [1217] phi from main::@148 to printf_ulong [phi:main::@148->printf_ulong]
    // [1217] phi printf_ulong::format_zero_padding#11 = 0 [phi:main::@148->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1217] phi printf_ulong::format_min_length#11 = 0 [phi:main::@148->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1217] phi printf_ulong::putc#11 = &snputc [phi:main::@148->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1217] phi printf_ulong::format_radix#11 = DECIMAL [phi:main::@148->printf_ulong#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1217] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#10 [phi:main::@148->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [387] phi from main::@148 to main::@149 [phi:main::@148->main::@149]
    // main::@149
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [388] call printf_str
    // [775] phi from main::@149 to printf_str [phi:main::@149->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:main::@149->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = main::s17 [phi:main::@149->printf_str#1] -- pbuz1=pbuc1 
    lda #<s17
    sta.z printf_str.s
    lda #>s17
    sta.z printf_str.s+1
    jsr printf_str
    // main::@150
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [389] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [390] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_ERROR, info_text)
    // [392] display_info_rom::rom_chip#14 = main::rom_chip3#10 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z display_info_rom.rom_chip
    // [393] call display_info_rom
    // [1016] phi from main::@150 to display_info_rom [phi:main::@150->display_info_rom]
    // [1016] phi display_info_rom::info_text#16 = info_text [phi:main::@150->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1016] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#14 [phi:main::@150->display_info_rom#1] -- register_copy 
    // [1016] phi display_info_rom::info_status#16 = STATUS_ERROR [phi:main::@150->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_rom.info_status
    jsr display_info_rom
    jmp __b35
    // main::@36
  __b36:
    // display_info_rom(rom_chip, STATUS_FLASHED, "No update required")
    // [394] display_info_rom::rom_chip#12 = main::rom_chip3#10 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z display_info_rom.rom_chip
    // [395] call display_info_rom
    // [1016] phi from main::@36 to display_info_rom [phi:main::@36->display_info_rom]
    // [1016] phi display_info_rom::info_text#16 = main::info_text23 [phi:main::@36->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text23
    sta.z display_info_rom.info_text
    lda #>info_text23
    sta.z display_info_rom.info_text+1
    // [1016] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#12 [phi:main::@36->display_info_rom#1] -- register_copy 
    // [1016] phi display_info_rom::info_status#16 = STATUS_FLASHED [phi:main::@36->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHED
    sta.z display_info_rom.info_status
    jsr display_info_rom
    jmp __b35
    // [396] phi from main::@171 to main::@5 [phi:main::@171->main::@5]
    // main::@5
  __b5:
    // display_progress_clear()
    // [397] call display_progress_clear
    // [681] phi from main::@5 to display_progress_clear [phi:main::@5->display_progress_clear]
    jsr display_progress_clear
    // [398] phi from main::@5 to main::@127 [phi:main::@5->main::@127]
    // main::@127
    // smc_read()
    // [399] call smc_read
    // [915] phi from main::@127 to smc_read [phi:main::@127->smc_read]
    // [915] phi __errno#35 = __errno#112 [phi:main::@127->smc_read#0] -- register_copy 
    jsr smc_read
    // smc_read()
    // [400] smc_read::return#3 = smc_read::return#0
    // main::@128
    // smc_file_size = smc_read()
    // [401] smc_file_size#1 = smc_read::return#3 -- vwum1=vwuz2 
    lda.z smc_read.return
    sta smc_file_size_1
    lda.z smc_read.return+1
    sta smc_file_size_1+1
    // if(smc_file_size)
    // [402] if(0==smc_file_size#1) goto main::@1 -- 0_eq_vwum1_then_la1 
    lda smc_file_size_1
    ora smc_file_size_1+1
    bne !__b1+
    jmp __b1
  !__b1:
    // [403] phi from main::@128 to main::@6 [phi:main::@128->main::@6]
    // main::@6
    // display_action_text("Press both POWER/RESET buttons on the CX16 board!")
    // [404] call display_action_text
  // Flash the SMC chip.
    // [993] phi from main::@6 to display_action_text [phi:main::@6->display_action_text]
    // [993] phi display_action_text::info_text#19 = main::info_text16 [phi:main::@6->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text16
    sta.z display_action_text.info_text
    lda #>info_text16
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@129
    // [405] smc_file_size#376 = smc_file_size#1 -- vwum1=vwum2 
    lda smc_file_size_1
    sta smc_file_size_2
    lda smc_file_size_1+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_FLASHING, "Press POWER/RESET!")
    // [406] call display_info_smc
    // [820] phi from main::@129 to display_info_smc [phi:main::@129->display_info_smc]
    // [820] phi display_info_smc::info_text#12 = main::info_text17 [phi:main::@129->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text17
    sta.z display_info_smc.info_text
    lda #>info_text17
    sta.z display_info_smc.info_text+1
    // [820] phi smc_file_size#12 = smc_file_size#376 [phi:main::@129->display_info_smc#1] -- register_copy 
    // [820] phi display_info_smc::info_status#12 = STATUS_FLASHING [phi:main::@129->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHING
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // main::@130
    // unsigned long flashed_bytes = smc_flash(smc_file_size)
    // [407] smc_flash::smc_bytes_total#0 = smc_file_size#1 -- vwuz1=vwum2 
    lda smc_file_size_1
    sta.z smc_flash.smc_bytes_total
    lda smc_file_size_1+1
    sta.z smc_flash.smc_bytes_total+1
    // [408] call smc_flash
    // [1343] phi from main::@130 to smc_flash [phi:main::@130->smc_flash]
    jsr smc_flash
    // unsigned long flashed_bytes = smc_flash(smc_file_size)
    // [409] smc_flash::return#5 = smc_flash::return#1
    // main::@131
    // [410] main::flashed_bytes#0 = smc_flash::return#5 -- vdum1=vwuz2 
    lda.z smc_flash.return
    sta flashed_bytes
    lda.z smc_flash.return+1
    sta flashed_bytes+1
    lda #0
    sta flashed_bytes+2
    sta flashed_bytes+3
    // if(flashed_bytes)
    // [411] if(0!=main::flashed_bytes#0) goto main::@33 -- 0_neq_vdum1_then_la1 
    lda flashed_bytes
    ora flashed_bytes+1
    ora flashed_bytes+2
    ora flashed_bytes+3
    bne __b33
    // main::@7
    // [412] smc_file_size#374 = smc_file_size#1 -- vwum1=vwum2 
    lda smc_file_size_1
    sta smc_file_size_2
    lda smc_file_size_1+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_ERROR, "SMC not updated!")
    // [413] call display_info_smc
    // [820] phi from main::@7 to display_info_smc [phi:main::@7->display_info_smc]
    // [820] phi display_info_smc::info_text#12 = main::info_text19 [phi:main::@7->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text19
    sta.z display_info_smc.info_text
    lda #>info_text19
    sta.z display_info_smc.info_text+1
    // [820] phi smc_file_size#12 = smc_file_size#374 [phi:main::@7->display_info_smc#1] -- register_copy 
    // [820] phi display_info_smc::info_status#12 = STATUS_ERROR [phi:main::@7->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp __b1
    // main::@33
  __b33:
    // [414] smc_file_size#380 = smc_file_size#1 -- vwum1=vwum2 
    lda smc_file_size_1
    sta smc_file_size_2
    lda smc_file_size_1+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_FLASHED, "")
    // [415] call display_info_smc
    // [820] phi from main::@33 to display_info_smc [phi:main::@33->display_info_smc]
    // [820] phi display_info_smc::info_text#12 = info_text4 [phi:main::@33->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z display_info_smc.info_text
    lda #>info_text4
    sta.z display_info_smc.info_text+1
    // [820] phi smc_file_size#12 = smc_file_size#380 [phi:main::@33->display_info_smc#1] -- register_copy 
    // [820] phi display_info_smc::info_status#12 = STATUS_FLASHED [phi:main::@33->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHED
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp __b1
    // [416] phi from main::@169 main::@170 to main::@3 [phi:main::@169/main::@170->main::@3]
    // main::@3
  __b3:
    // display_action_progress("Chipsets have been detected and update files validated!")
    // [417] call display_action_progress
    // [667] phi from main::@3 to display_action_progress [phi:main::@3->display_action_progress]
    // [667] phi display_action_progress::info_text#14 = main::info_text10 [phi:main::@3->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text10
    sta.z display_action_progress.info_text
    lda #>info_text10
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [418] phi from main::@3 to main::@122 [phi:main::@3->main::@122]
    // main::@122
    // unsigned char ch = util_wait_key("Continue with update of highlighted chipsets? [Y/N]", "nyNY")
    // [419] call util_wait_key
    // [1505] phi from main::@122 to util_wait_key [phi:main::@122->util_wait_key]
    // [1505] phi util_wait_key::filter#12 = main::filter [phi:main::@122->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter
    sta.z util_wait_key.filter
    lda #>filter
    sta.z util_wait_key.filter+1
    // [1505] phi util_wait_key::info_text#2 = main::info_text11 [phi:main::@122->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text11
    sta.z util_wait_key.info_text
    lda #>info_text11
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("Continue with update of highlighted chipsets? [Y/N]", "nyNY")
    // [420] util_wait_key::return#3 = util_wait_key::ch#4 -- vbum1=vwuz2 
    lda.z util_wait_key.ch
    sta util_wait_key.return
    // main::@123
    // [421] main::ch#0 = util_wait_key::return#3
    // strchr("nN", ch)
    // [422] strchr::c#1 = main::ch#0 -- vbum1=vbum2 
    lda ch
    sta strchr.c
    // [423] call strchr
    // [1529] phi from main::@123 to strchr [phi:main::@123->strchr]
    // [1529] phi strchr::c#4 = strchr::c#1 [phi:main::@123->strchr#0] -- register_copy 
    // [1529] phi strchr::str#2 = (const void *)main::$213 [phi:main::@123->strchr#1] -- pvoz1=pvoc1 
    lda #<main__213
    sta.z strchr.str
    lda #>main__213
    sta.z strchr.str+1
    jsr strchr
    // strchr("nN", ch)
    // [424] strchr::return#4 = strchr::return#2
    // main::@124
    // [425] main::$115 = strchr::return#4
    // if(strchr("nN", ch))
    // [426] if((void *)0==main::$115) goto main::SEI5 -- pvoc1_eq_pvoz1_then_la1 
    lda.z main__115
    cmp #<0
    bne !+
    lda.z main__115+1
    cmp #>0
    bne !SEI5+
    jmp SEI5
  !SEI5:
  !:
    // main::@4
    // [427] smc_file_size#381 = smc_file_size#208 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_SKIP, "Cancelled")
    // [428] call display_info_smc
  // We cancel all updates, the updates are skipped.
    // [820] phi from main::@4 to display_info_smc [phi:main::@4->display_info_smc]
    // [820] phi display_info_smc::info_text#12 = main::info_text12 [phi:main::@4->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text12
    sta.z display_info_smc.info_text
    lda #>info_text12
    sta.z display_info_smc.info_text+1
    // [820] phi smc_file_size#12 = smc_file_size#381 [phi:main::@4->display_info_smc#1] -- register_copy 
    // [820] phi display_info_smc::info_status#12 = STATUS_SKIP [phi:main::@4->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [429] phi from main::@4 to main::@125 [phi:main::@4->main::@125]
    // main::@125
    // display_info_vera(STATUS_SKIP, "Cancelled")
    // [430] call display_info_vera
    // [850] phi from main::@125 to display_info_vera [phi:main::@125->display_info_vera]
    // [850] phi display_info_vera::info_text#10 = main::info_text12 [phi:main::@125->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text12
    sta.z display_info_vera.info_text
    lda #>info_text12
    sta.z display_info_vera.info_text+1
    // [850] phi display_info_vera::info_status#2 = STATUS_SKIP [phi:main::@125->display_info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // [431] phi from main::@125 to main::@30 [phi:main::@125->main::@30]
    // [431] phi main::rom_chip2#2 = 0 [phi:main::@125->main::@30#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip2
    // main::@30
  __b30:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [432] if(main::rom_chip2#2<8) goto main::@31 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip2
    cmp #8
    bcc __b31
    // [433] phi from main::@30 to main::@32 [phi:main::@30->main::@32]
    // main::@32
    // display_action_text("You have selected not to cancel the update ... ")
    // [434] call display_action_text
    // [993] phi from main::@32 to display_action_text [phi:main::@32->display_action_text]
    // [993] phi display_action_text::info_text#19 = main::info_text15 [phi:main::@32->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text15
    sta.z display_action_text.info_text
    lda #>info_text15
    sta.z display_action_text.info_text+1
    jsr display_action_text
    jmp SEI5
    // main::@31
  __b31:
    // display_info_rom(rom_chip, STATUS_SKIP, "Cancelled")
    // [435] display_info_rom::rom_chip#9 = main::rom_chip2#2 -- vbuz1=vbum2 
    lda rom_chip2
    sta.z display_info_rom.rom_chip
    // [436] call display_info_rom
    // [1016] phi from main::@31 to display_info_rom [phi:main::@31->display_info_rom]
    // [1016] phi display_info_rom::info_text#16 = main::info_text12 [phi:main::@31->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text12
    sta.z display_info_rom.info_text
    lda #>info_text12
    sta.z display_info_rom.info_text+1
    // [1016] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#9 [phi:main::@31->display_info_rom#1] -- register_copy 
    // [1016] phi display_info_rom::info_status#16 = STATUS_SKIP [phi:main::@31->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // main::@126
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [437] main::rom_chip2#1 = ++ main::rom_chip2#2 -- vbum1=_inc_vbum1 
    inc rom_chip2
    // [431] phi from main::@126 to main::@30 [phi:main::@126->main::@30]
    // [431] phi main::rom_chip2#2 = main::rom_chip2#1 [phi:main::@126->main::@30#0] -- register_copy 
    jmp __b30
    // main::check_status_card_roms1_check_status_rom1
  check_status_card_roms1_check_status_rom1:
    // status_rom[rom_chip] == status
    // [438] main::check_status_card_roms1_check_status_rom1_$0 = status_rom[main::check_status_card_roms1_rom_chip#2] == STATUS_FLASH -- vbom1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_FLASH
    ldy check_status_card_roms1_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_card_roms1_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [439] main::check_status_card_roms1_check_status_rom1_return#0 = (char)main::check_status_card_roms1_check_status_rom1_$0
    // main::check_status_card_roms1_@11
    // if(check_status_rom(rom_chip, status))
    // [440] if(0==main::check_status_card_roms1_check_status_rom1_return#0) goto main::check_status_card_roms1_@4 -- 0_eq_vbum1_then_la1 
    lda check_status_card_roms1_check_status_rom1_return
    beq check_status_card_roms1___b4
    // [180] phi from main::check_status_card_roms1_@11 to main::check_status_card_roms1_@return [phi:main::check_status_card_roms1_@11->main::check_status_card_roms1_@return]
    // [180] phi main::check_status_card_roms1_return#2 = STATUS_FLASH [phi:main::check_status_card_roms1_@11->main::check_status_card_roms1_@return#0] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta check_status_card_roms1_return
    jmp __b62
    // main::check_status_card_roms1_@4
  check_status_card_roms1___b4:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [441] main::check_status_card_roms1_rom_chip#1 = ++ main::check_status_card_roms1_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_status_card_roms1_rom_chip
    // [178] phi from main::check_status_card_roms1_@4 to main::check_status_card_roms1_@1 [phi:main::check_status_card_roms1_@4->main::check_status_card_roms1_@1]
    // [178] phi main::check_status_card_roms1_rom_chip#2 = main::check_status_card_roms1_rom_chip#1 [phi:main::check_status_card_roms1_@4->main::check_status_card_roms1_@1#0] -- register_copy 
    jmp check_status_card_roms1___b1
    // [442] phi from main::@168 to main::@2 [phi:main::@168->main::@2]
    // main::@2
  __b2:
    // display_action_progress("The ROM must also be flashable, check the ROM issue.")
    // [443] call display_action_progress
    // [667] phi from main::@2 to display_action_progress [phi:main::@2->display_action_progress]
    // [667] phi display_action_progress::info_text#14 = main::info_text9 [phi:main::@2->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text9
    sta.z display_action_progress.info_text
    lda #>info_text9
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [444] phi from main::@2 to main::@120 [phi:main::@2->main::@120]
    // main::@120
    // display_info_cx16_rom(STATUS_ISSUE, NULL)
    // [445] call display_info_cx16_rom
    // [1538] phi from main::@120 to display_info_cx16_rom [phi:main::@120->display_info_cx16_rom]
    jsr display_info_cx16_rom
    // [446] phi from main::@120 to main::@121 [phi:main::@120->main::@121]
    // main::@121
    // util_wait_space()
    // [447] call util_wait_space
    // [735] phi from main::@121 to util_wait_space [phi:main::@121->util_wait_space]
    jsr util_wait_space
    jmp check_status_smc4
    // [448] phi from main::@167 to main::@29 [phi:main::@167->main::@29]
    // main::@29
  __b29:
    // display_action_progress("The SMC must also be flashable, check the SMC issue!")
    // [449] call display_action_progress
    // [667] phi from main::@29 to display_action_progress [phi:main::@29->display_action_progress]
    // [667] phi display_action_progress::info_text#14 = main::info_text8 [phi:main::@29->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z display_action_progress.info_text
    lda #>info_text8
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@118
    // [450] smc_file_size#375 = smc_file_size#208 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_ISSUE, NULL)
    // [451] call display_info_smc
    // [820] phi from main::@118 to display_info_smc [phi:main::@118->display_info_smc]
    // [820] phi display_info_smc::info_text#12 = 0 [phi:main::@118->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [820] phi smc_file_size#12 = smc_file_size#375 [phi:main::@118->display_info_smc#1] -- register_copy 
    // [820] phi display_info_smc::info_status#12 = STATUS_ISSUE [phi:main::@118->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [452] phi from main::@118 to main::@119 [phi:main::@118->main::@119]
    // main::@119
    // util_wait_space()
    // [453] call util_wait_space
    // [735] phi from main::@119 to util_wait_space [phi:main::@119->util_wait_space]
    jsr util_wait_space
    jmp check_status_smc3
    // main::bank_set_brom2
  bank_set_brom2:
    // BROM = bank
    // [454] BROM = main::bank_set_brom2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom2_bank
    sta.z BROM
    // main::@57
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [455] if(rom_device_ids[main::rom_chip1#10]==$55) goto main::@23 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    ldy rom_chip1
    lda rom_device_ids,y
    cmp #$55
    bne !__b23+
    jmp __b23
  !__b23:
    // [456] phi from main::@57 to main::@26 [phi:main::@57->main::@26]
    // main::@26
    // display_progress_clear()
    // [457] call display_progress_clear
    // [681] phi from main::@26 to display_progress_clear [phi:main::@26->display_progress_clear]
    jsr display_progress_clear
    // main::@96
    // unsigned char rom_bank = rom_chip * 32
    // [458] main::rom_bank#0 = main::rom_chip1#10 << 5 -- vbum1=vbum2_rol_5 
    lda rom_chip1
    asl
    asl
    asl
    asl
    asl
    sta rom_bank
    // unsigned char* file = rom_file(rom_chip)
    // [459] rom_file::rom_chip#0 = main::rom_chip1#10 -- vbuz1=vbum2 
    lda rom_chip1
    sta.z rom_file.rom_chip
    // [460] call rom_file
    // [1061] phi from main::@96 to rom_file [phi:main::@96->rom_file]
    // [1061] phi rom_file::rom_chip#2 = rom_file::rom_chip#0 [phi:main::@96->rom_file#0] -- register_copy 
    jsr rom_file
    // unsigned char* file = rom_file(rom_chip)
    // [461] rom_file::return#4 = rom_file::return#2
    // main::@97
    // [462] main::file#0 = rom_file::return#4 -- pbum1=pbum2 
    lda rom_file.return
    sta file
    lda rom_file.return+1
    sta file+1
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [463] call snprintf_init
    // [770] phi from main::@97 to snprintf_init [phi:main::@97->snprintf_init]
    // [770] phi snprintf_init::s#25 = info_text [phi:main::@97->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [464] phi from main::@97 to main::@98 [phi:main::@97->main::@98]
    // main::@98
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [465] call printf_str
    // [775] phi from main::@98 to printf_str [phi:main::@98->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:main::@98->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = main::s6 [phi:main::@98->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // main::@99
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [466] printf_string::str#13 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [467] call printf_string
    // [784] phi from main::@99 to printf_string [phi:main::@99->printf_string]
    // [784] phi printf_string::putc#19 = &snputc [phi:main::@99->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [784] phi printf_string::str#19 = printf_string::str#13 [phi:main::@99->printf_string#1] -- register_copy 
    // [784] phi printf_string::format_justify_left#19 = 0 [phi:main::@99->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [784] phi printf_string::format_min_length#19 = 0 [phi:main::@99->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [468] phi from main::@99 to main::@100 [phi:main::@99->main::@100]
    // main::@100
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [469] call printf_str
    // [775] phi from main::@100 to printf_str [phi:main::@100->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:main::@100->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = main::s7 [phi:main::@100->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@101
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [470] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [471] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_progress(info_text)
    // [473] call display_action_progress
    // [667] phi from main::@101 to display_action_progress [phi:main::@101->display_action_progress]
    // [667] phi display_action_progress::info_text#14 = info_text [phi:main::@101->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_progress.info_text
    lda #>@info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@102
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_CHECKING, rom_bank, rom_sizes[rom_chip])
    // [474] main::$192 = main::rom_chip1#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip1
    asl
    asl
    sta main__192
    // [475] rom_read::file#0 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z rom_read.file
    lda file+1
    sta.z rom_read.file+1
    // [476] rom_read::brom_bank_start#1 = main::rom_bank#0 -- vbuz1=vbum2 
    lda rom_bank
    sta.z rom_read.brom_bank_start
    // [477] rom_read::rom_size#0 = rom_sizes[main::$192] -- vduz1=pduc1_derefidx_vbum2 
    ldy main__192
    lda rom_sizes,y
    sta.z rom_read.rom_size
    lda rom_sizes+1,y
    sta.z rom_read.rom_size+1
    lda rom_sizes+2,y
    sta.z rom_read.rom_size+2
    lda rom_sizes+3,y
    sta.z rom_read.rom_size+3
    // [478] call rom_read
  // Read the ROM(n).BIN file.
    // [1067] phi from main::@102 to rom_read [phi:main::@102->rom_read]
    // [1067] phi rom_read::rom_size#12 = rom_read::rom_size#0 [phi:main::@102->rom_read#0] -- register_copy 
    // [1067] phi __errno#106 = __errno#112 [phi:main::@102->rom_read#1] -- register_copy 
    // [1067] phi rom_read::file#11 = rom_read::file#0 [phi:main::@102->rom_read#2] -- register_copy 
    // [1067] phi rom_read::brom_bank_start#21 = rom_read::brom_bank_start#1 [phi:main::@102->rom_read#3] -- register_copy 
    jsr rom_read
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_CHECKING, rom_bank, rom_sizes[rom_chip])
    // [479] rom_read::return#2 = rom_read::return#0
    // main::@103
    // [480] main::rom_bytes_read#0 = rom_read::return#2
    // if (!rom_bytes_read)
    // [481] if(0==main::rom_bytes_read#0) goto main::@24 -- 0_eq_vduz1_then_la1 
    // In case no file was found, set the status to none and skip to the next, else, mention the amount of bytes read.
    lda.z rom_bytes_read
    ora.z rom_bytes_read+1
    ora.z rom_bytes_read+2
    ora.z rom_bytes_read+3
    bne !__b24+
    jmp __b24
  !__b24:
    // main::@27
    // unsigned long rom_file_modulo = rom_bytes_read % 0x4000
    // [482] main::rom_file_modulo#0 = main::rom_bytes_read#0 & $4000-1 -- vduz1=vduz2_band_vduc1 
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
    // [483] if(0!=main::rom_file_modulo#0) goto main::@25 -- 0_neq_vduz1_then_la1 
    lda.z rom_file_modulo
    ora.z rom_file_modulo+1
    ora.z rom_file_modulo+2
    ora.z rom_file_modulo+3
    beq !__b25+
    jmp __b25
  !__b25:
    // main::@28
    // file_sizes[rom_chip] = rom_bytes_read
    // [484] file_sizes[main::$192] = main::rom_bytes_read#0 -- pduc1_derefidx_vbum1=vduz2 
    // We know the file size, so we indicate it in the status panel.
    ldy main__192
    lda.z rom_bytes_read
    sta file_sizes,y
    lda.z rom_bytes_read+1
    sta file_sizes+1,y
    lda.z rom_bytes_read+2
    sta file_sizes+2,y
    lda.z rom_bytes_read+3
    sta file_sizes+3,y
    // strncpy(rom_github[rom_chip], (char*)RAM_BASE, 6)
    // [485] main::$194 = main::rom_chip1#10 << 1 -- vbum1=vbum2_rol_1 
    lda rom_chip1
    asl
    sta main__194
    // [486] strncpy::dst#2 = rom_github[main::$194] -- pbuz1=qbuc1_derefidx_vbum2 
    tay
    lda rom_github,y
    sta.z strncpy.dst
    lda rom_github+1,y
    sta.z strncpy.dst+1
    // [487] call strncpy
  // Fill the version data ...
  // TODO: I need to make a function for this, and calculate it properly! 
  // TODO: It seems currently not to work like I would expect.
    // [1541] phi from main::@28 to strncpy [phi:main::@28->strncpy]
    // [1541] phi strncpy::dst#8 = strncpy::dst#2 [phi:main::@28->strncpy#0] -- register_copy 
    // [1541] phi strncpy::src#6 = (char *)$6000 [phi:main::@28->strncpy#1] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z strncpy.src
    lda #>$6000
    sta.z strncpy.src+1
    // [1541] phi strncpy::n#3 = 6 [phi:main::@28->strncpy#2] -- vwum1=vbuc1 
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
    // [489] BRAM = main::bank_push_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_push_set_bram1_bank
    sta.z BRAM
    // main::@59
    // rom_release[rom_chip] = *((char*)0xBF80)
    // [490] rom_release[main::rom_chip1#10] = *((char *) 49024) -- pbuc1_derefidx_vbum1=_deref_pbuc2 
    lda $bf80
    ldy rom_chip1
    sta rom_release,y
    // main::bank_pull_bram1
    // asm
    // asm { pla sta$00  }
    pla
    sta.z 0
    // [492] phi from main::bank_pull_bram1 to main::@60 [phi:main::bank_pull_bram1->main::@60]
    // main::@60
    // sprintf(info_text, "%s:R%u/%s", file, rom_release[rom_chip], rom_github[rom_chip])
    // [493] call snprintf_init
    // [770] phi from main::@60 to snprintf_init [phi:main::@60->snprintf_init]
    // [770] phi snprintf_init::s#25 = info_text [phi:main::@60->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main::@112
    // sprintf(info_text, "%s:R%u/%s", file, rom_release[rom_chip], rom_github[rom_chip])
    // [494] printf_string::str#16 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [495] call printf_string
    // [784] phi from main::@112 to printf_string [phi:main::@112->printf_string]
    // [784] phi printf_string::putc#19 = &snputc [phi:main::@112->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [784] phi printf_string::str#19 = printf_string::str#16 [phi:main::@112->printf_string#1] -- register_copy 
    // [784] phi printf_string::format_justify_left#19 = 0 [phi:main::@112->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [784] phi printf_string::format_min_length#19 = 0 [phi:main::@112->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [496] phi from main::@112 to main::@113 [phi:main::@112->main::@113]
    // main::@113
    // sprintf(info_text, "%s:R%u/%s", file, rom_release[rom_chip], rom_github[rom_chip])
    // [497] call printf_str
    // [775] phi from main::@113 to printf_str [phi:main::@113->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:main::@113->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = main::s12 [phi:main::@113->printf_str#1] -- pbuz1=pbuc1 
    lda #<s12
    sta.z printf_str.s
    lda #>s12
    sta.z printf_str.s+1
    jsr printf_str
    // main::@114
    // sprintf(info_text, "%s:R%u/%s", file, rom_release[rom_chip], rom_github[rom_chip])
    // [498] printf_uchar::uvalue#8 = rom_release[main::rom_chip1#10] -- vbum1=pbuc1_derefidx_vbum2 
    ldy rom_chip1
    lda rom_release,y
    sta printf_uchar.uvalue
    // [499] call printf_uchar
    // [982] phi from main::@114 to printf_uchar [phi:main::@114->printf_uchar]
    // [982] phi printf_uchar::format_zero_padding#11 = 0 [phi:main::@114->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [982] phi printf_uchar::format_min_length#11 = 0 [phi:main::@114->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [982] phi printf_uchar::putc#11 = &snputc [phi:main::@114->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [982] phi printf_uchar::format_radix#11 = DECIMAL [phi:main::@114->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [982] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#8 [phi:main::@114->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [500] phi from main::@114 to main::@115 [phi:main::@114->main::@115]
    // main::@115
    // sprintf(info_text, "%s:R%u/%s", file, rom_release[rom_chip], rom_github[rom_chip])
    // [501] call printf_str
    // [775] phi from main::@115 to printf_str [phi:main::@115->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:main::@115->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = s4 [phi:main::@115->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s4
    sta.z printf_str.s
    lda #>@s4
    sta.z printf_str.s+1
    jsr printf_str
    // main::@116
    // sprintf(info_text, "%s:R%u/%s", file, rom_release[rom_chip], rom_github[rom_chip])
    // [502] printf_string::str#17 = rom_github[main::$194] -- pbuz1=qbuc1_derefidx_vbum2 
    ldy main__194
    lda rom_github,y
    sta.z printf_string.str
    lda rom_github+1,y
    sta.z printf_string.str+1
    // [503] call printf_string
    // [784] phi from main::@116 to printf_string [phi:main::@116->printf_string]
    // [784] phi printf_string::putc#19 = &snputc [phi:main::@116->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [784] phi printf_string::str#19 = printf_string::str#17 [phi:main::@116->printf_string#1] -- register_copy 
    // [784] phi printf_string::format_justify_left#19 = 0 [phi:main::@116->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [784] phi printf_string::format_min_length#19 = 0 [phi:main::@116->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // main::@117
    // sprintf(info_text, "%s:R%u/%s", file, rom_release[rom_chip], rom_github[rom_chip])
    // [504] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [505] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_FLASH, info_text)
    // [507] display_info_rom::rom_chip#8 = main::rom_chip1#10 -- vbuz1=vbum2 
    lda rom_chip1
    sta.z display_info_rom.rom_chip
    // [508] call display_info_rom
    // [1016] phi from main::@117 to display_info_rom [phi:main::@117->display_info_rom]
    // [1016] phi display_info_rom::info_text#16 = info_text [phi:main::@117->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1016] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#8 [phi:main::@117->display_info_rom#1] -- register_copy 
    // [1016] phi display_info_rom::info_status#16 = STATUS_FLASH [phi:main::@117->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASH
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // [509] phi from main::@107 main::@111 main::@117 main::@57 to main::@23 [phi:main::@107/main::@111/main::@117/main::@57->main::@23]
    // [509] phi __errno#239 = __errno#179 [phi:main::@107/main::@111/main::@117/main::@57->main::@23#0] -- register_copy 
    // main::@23
  __b23:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [510] main::rom_chip1#1 = ++ main::rom_chip1#10 -- vbum1=_inc_vbum1 
    inc rom_chip1
    // [154] phi from main::@23 to main::@22 [phi:main::@23->main::@22]
    // [154] phi __errno#112 = __errno#239 [phi:main::@23->main::@22#0] -- register_copy 
    // [154] phi main::rom_chip1#10 = main::rom_chip1#1 [phi:main::@23->main::@22#1] -- register_copy 
    jmp __b22
    // [511] phi from main::@27 to main::@25 [phi:main::@27->main::@25]
    // main::@25
  __b25:
    // sprintf(info_text, "File %s size error!", file)
    // [512] call snprintf_init
    // [770] phi from main::@25 to snprintf_init [phi:main::@25->snprintf_init]
    // [770] phi snprintf_init::s#25 = info_text [phi:main::@25->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [513] phi from main::@25 to main::@108 [phi:main::@25->main::@108]
    // main::@108
    // sprintf(info_text, "File %s size error!", file)
    // [514] call printf_str
    // [775] phi from main::@108 to printf_str [phi:main::@108->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:main::@108->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = main::s10 [phi:main::@108->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // main::@109
    // sprintf(info_text, "File %s size error!", file)
    // [515] printf_string::str#15 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [516] call printf_string
    // [784] phi from main::@109 to printf_string [phi:main::@109->printf_string]
    // [784] phi printf_string::putc#19 = &snputc [phi:main::@109->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [784] phi printf_string::str#19 = printf_string::str#15 [phi:main::@109->printf_string#1] -- register_copy 
    // [784] phi printf_string::format_justify_left#19 = 0 [phi:main::@109->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [784] phi printf_string::format_min_length#19 = 0 [phi:main::@109->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [517] phi from main::@109 to main::@110 [phi:main::@109->main::@110]
    // main::@110
    // sprintf(info_text, "File %s size error!", file)
    // [518] call printf_str
    // [775] phi from main::@110 to printf_str [phi:main::@110->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:main::@110->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = main::s11 [phi:main::@110->printf_str#1] -- pbuz1=pbuc1 
    lda #<s11
    sta.z printf_str.s
    lda #>s11
    sta.z printf_str.s+1
    jsr printf_str
    // main::@111
    // sprintf(info_text, "File %s size error!", file)
    // [519] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [520] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_ERROR, info_text)
    // [522] display_info_rom::rom_chip#7 = main::rom_chip1#10 -- vbuz1=vbum2 
    lda rom_chip1
    sta.z display_info_rom.rom_chip
    // [523] call display_info_rom
    // [1016] phi from main::@111 to display_info_rom [phi:main::@111->display_info_rom]
    // [1016] phi display_info_rom::info_text#16 = info_text [phi:main::@111->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1016] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#7 [phi:main::@111->display_info_rom#1] -- register_copy 
    // [1016] phi display_info_rom::info_status#16 = STATUS_ERROR [phi:main::@111->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_rom.info_status
    jsr display_info_rom
    jmp __b23
    // [524] phi from main::@103 to main::@24 [phi:main::@103->main::@24]
    // main::@24
  __b24:
    // sprintf(info_text, "No %s, skipped", file)
    // [525] call snprintf_init
    // [770] phi from main::@24 to snprintf_init [phi:main::@24->snprintf_init]
    // [770] phi snprintf_init::s#25 = info_text [phi:main::@24->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [526] phi from main::@24 to main::@104 [phi:main::@24->main::@104]
    // main::@104
    // sprintf(info_text, "No %s, skipped", file)
    // [527] call printf_str
    // [775] phi from main::@104 to printf_str [phi:main::@104->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:main::@104->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = main::s8 [phi:main::@104->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // main::@105
    // sprintf(info_text, "No %s, skipped", file)
    // [528] printf_string::str#14 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [529] call printf_string
    // [784] phi from main::@105 to printf_string [phi:main::@105->printf_string]
    // [784] phi printf_string::putc#19 = &snputc [phi:main::@105->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [784] phi printf_string::str#19 = printf_string::str#14 [phi:main::@105->printf_string#1] -- register_copy 
    // [784] phi printf_string::format_justify_left#19 = 0 [phi:main::@105->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [784] phi printf_string::format_min_length#19 = 0 [phi:main::@105->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [530] phi from main::@105 to main::@106 [phi:main::@105->main::@106]
    // main::@106
    // sprintf(info_text, "No %s, skipped", file)
    // [531] call printf_str
    // [775] phi from main::@106 to printf_str [phi:main::@106->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:main::@106->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = main::s9 [phi:main::@106->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // main::@107
    // sprintf(info_text, "No %s, skipped", file)
    // [532] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [533] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_NONE, info_text)
    // [535] display_info_rom::rom_chip#6 = main::rom_chip1#10 -- vbuz1=vbum2 
    lda rom_chip1
    sta.z display_info_rom.rom_chip
    // [536] call display_info_rom
    // [1016] phi from main::@107 to display_info_rom [phi:main::@107->display_info_rom]
    // [1016] phi display_info_rom::info_text#16 = info_text [phi:main::@107->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1016] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#6 [phi:main::@107->display_info_rom#1] -- register_copy 
    // [1016] phi display_info_rom::info_status#16 = STATUS_NONE [phi:main::@107->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_NONE
    sta.z display_info_rom.info_status
    jsr display_info_rom
    jmp __b23
    // main::@21
  __b21:
    // [537] smc_file_size#379 = smc_file_size#0 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_ISSUE, "SMC.BIN too large!")
    // [538] call display_info_smc
    // [820] phi from main::@21 to display_info_smc [phi:main::@21->display_info_smc]
    // [820] phi display_info_smc::info_text#12 = main::info_text7 [phi:main::@21->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z display_info_smc.info_text
    lda #>info_text7
    sta.z display_info_smc.info_text+1
    // [820] phi smc_file_size#12 = smc_file_size#379 [phi:main::@21->display_info_smc#1] -- register_copy 
    // [820] phi display_info_smc::info_status#12 = STATUS_ISSUE [phi:main::@21->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp CLI3
    // main::@20
  __b20:
    // [539] smc_file_size#378 = smc_file_size#0 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // display_info_smc(STATUS_ISSUE, "No SMC.BIN!")
    // [540] call display_info_smc
    // [820] phi from main::@20 to display_info_smc [phi:main::@20->display_info_smc]
    // [820] phi display_info_smc::info_text#12 = main::info_text6 [phi:main::@20->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text6
    sta.z display_info_smc.info_text
    lda #>info_text6
    sta.z display_info_smc.info_text+1
    // [820] phi smc_file_size#12 = smc_file_size#378 [phi:main::@20->display_info_smc#1] -- register_copy 
    // [820] phi display_info_smc::info_status#12 = STATUS_ISSUE [phi:main::@20->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp CLI3
    // main::@13
  __b13:
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [541] if(rom_device_ids[main::rom_chip#2]!=$55) goto main::@14 -- pbuc1_derefidx_vbum1_neq_vbuc2_then_la1 
    lda #$55
    ldy rom_chip
    cmp rom_device_ids,y
    bne __b14
    // main::@16
    // display_info_rom(rom_chip, STATUS_NONE, "")
    // [542] display_info_rom::rom_chip#5 = main::rom_chip#2 -- vbuz1=vbum2 
    tya
    sta.z display_info_rom.rom_chip
    // [543] call display_info_rom
    // [1016] phi from main::@16 to display_info_rom [phi:main::@16->display_info_rom]
    // [1016] phi display_info_rom::info_text#16 = info_text4 [phi:main::@16->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z display_info_rom.info_text
    lda #>info_text4
    sta.z display_info_rom.info_text+1
    // [1016] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#5 [phi:main::@16->display_info_rom#1] -- register_copy 
    // [1016] phi display_info_rom::info_status#16 = STATUS_NONE [phi:main::@16->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_NONE
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // main::@15
  __b15:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [544] main::rom_chip#1 = ++ main::rom_chip#2 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [136] phi from main::@15 to main::@12 [phi:main::@15->main::@12]
    // [136] phi main::rom_chip#2 = main::rom_chip#1 [phi:main::@15->main::@12#0] -- register_copy 
    jmp __b12
    // main::@14
  __b14:
    // display_info_rom(rom_chip, STATUS_DETECTED, "")
    // [545] display_info_rom::rom_chip#4 = main::rom_chip#2 -- vbuz1=vbum2 
    lda rom_chip
    sta.z display_info_rom.rom_chip
    // [546] call display_info_rom
    // [1016] phi from main::@14 to display_info_rom [phi:main::@14->display_info_rom]
    // [1016] phi display_info_rom::info_text#16 = info_text4 [phi:main::@14->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z display_info_rom.info_text
    lda #>info_text4
    sta.z display_info_rom.info_text+1
    // [1016] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#4 [phi:main::@14->display_info_rom#1] -- register_copy 
    // [1016] phi display_info_rom::info_status#16 = STATUS_DETECTED [phi:main::@14->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_DETECTED
    sta.z display_info_rom.info_status
    jsr display_info_rom
    jmp __b15
    // main::@9
  __b9:
    // display_info_led(PROGRESS_X + 3, PROGRESS_Y + 3 + intro_status, status_color[intro_status], BLUE)
    // [547] display_info_led::y#3 = PROGRESS_Y+3 + main::intro_status#2 -- vbuz1=vbuc1_plus_vbum2 
    lda #PROGRESS_Y+3
    clc
    adc intro_status
    sta.z display_info_led.y
    // [548] display_info_led::tc#3 = status_color[main::intro_status#2] -- vbuz1=pbuc1_derefidx_vbum2 
    ldy intro_status
    lda status_color,y
    sta.z display_info_led.tc
    // [549] call display_info_led
    // [1552] phi from main::@9 to display_info_led [phi:main::@9->display_info_led]
    // [1552] phi display_info_led::y#4 = display_info_led::y#3 [phi:main::@9->display_info_led#0] -- register_copy 
    // [1552] phi display_info_led::x#4 = PROGRESS_X+3 [phi:main::@9->display_info_led#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X+3
    sta.z display_info_led.x
    // [1552] phi display_info_led::tc#4 = display_info_led::tc#3 [phi:main::@9->display_info_led#2] -- register_copy 
    jsr display_info_led
    // main::@84
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [550] main::intro_status#1 = ++ main::intro_status#2 -- vbum1=_inc_vbum1 
    inc intro_status
    // [99] phi from main::@84 to main::@8 [phi:main::@84->main::@8]
    // [99] phi main::intro_status#2 = main::intro_status#1 [phi:main::@84->main::@8#0] -- register_copy 
    jmp __b8
  .segment Data
    title_text: .text "Commander X16 Flash Utility!"
    .byte 0
    s: .text "# Chip Status    Type   File  / Total Information"
    .byte 0
    s1: .text "- ---- --------- ------ ----- / ----- --------------------"
    .byte 0
    info_text: .text "Introduction ..."
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
    main__213: .text "nN"
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
    s21: .text " ("
    .byte 0
    s22: .text ") Your CX16 will reset ..."
    .byte 0
    main__192: .byte 0
    main__194: .byte 0
    main__196: .byte 0
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
    intro_status: .byte 0
    rom_chip: .byte 0
    rom_chip1: .byte 0
    rom_bank: .byte 0
    file: .word 0
    .label check_status_smc3_return = check_status_smc3_main__0
    .label check_status_smc4_return = check_status_smc4_main__0
    .label check_status_card_roms1_check_status_rom1_return = check_status_card_roms1_check_status_rom1_main__0
    check_status_card_roms1_rom_chip: .byte 0
    check_status_card_roms1_return: .byte 0
    .label ch = util_wait_key.return
    rom_chip2: .byte 0
    flashed_bytes: .dword 0
    .label check_status_rom1_return = check_status_rom1_main__0
    .label check_status_vera1_return = check_status_vera1_main__0
    .label check_status_roms_all1_check_status_rom1_return = check_status_roms_all1_check_status_rom1_main__0
    check_status_roms_all1_rom_chip: .byte 0
    check_status_roms_all1_return: .byte 0
    rom_chip3: .byte 0
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
    // [551] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbum1=_deref_pbuc1 
    lda VERA_L1_MAPBASE
    sta screenlayer.mapbase
    // [552] screenlayer::config#0 = *VERA_L1_CONFIG -- vbum1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta screenlayer.config
    // [553] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [554] return 
    rts
}
  // textcolor
// Set the front color for text output. The old front text color setting is returned.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char textcolor(__mem() char color)
textcolor: {
    .label textcolor__0 = $b9
    .label textcolor__1 = $b9
    // __conio.color & 0xF0
    // [556] textcolor::$0 = *((char *)&__conio+$d) & $f0 -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$d
    sta.z textcolor__0
    // __conio.color & 0xF0 | color
    // [557] textcolor::$1 = textcolor::$0 | textcolor::color#18 -- vbuz1=vbuz1_bor_vbum2 
    lda color
    ora.z textcolor__1
    sta.z textcolor__1
    // __conio.color = __conio.color & 0xF0 | color
    // [558] *((char *)&__conio+$d) = textcolor::$1 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // textcolor::@return
    // }
    // [559] return 
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
    .label bgcolor__0 = $b9
    .label bgcolor__1 = $bb
    .label bgcolor__2 = $b9
    // __conio.color & 0x0F
    // [561] bgcolor::$0 = *((char *)&__conio+$d) & $f -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$d
    sta.z bgcolor__0
    // color << 4
    // [562] bgcolor::$1 = bgcolor::color#14 << 4 -- vbuz1=vbum2_rol_4 
    lda color
    asl
    asl
    asl
    asl
    sta.z bgcolor__1
    // __conio.color & 0x0F | color << 4
    // [563] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbuz1=vbuz1_bor_vbuz2 
    lda.z bgcolor__2
    ora.z bgcolor__1
    sta.z bgcolor__2
    // __conio.color = __conio.color & 0x0F | color << 4
    // [564] *((char *)&__conio+$d) = bgcolor::$2 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // bgcolor::@return
    // }
    // [565] return 
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
    // [566] *((char *)&__conio+$c) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$c
    // cursor::@return
    // }
    // [567] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    // __mem unsigned char x
    // [568] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [569] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [571] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwum1=vbum2_word_vbum3 
    lda x
    sta return+1
    lda y
    sta return
    // cbm_k_plot_get::@return
    // }
    // [572] return 
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
    // [574] if(gotoxy::x#30>=*((char *)&__conio+6)) goto gotoxy::@1 -- vbum1_ge__deref_pbuc1_then_la1 
    lda x
    cmp __conio+6
    bcs __b1
    // [576] phi from gotoxy to gotoxy::@2 [phi:gotoxy->gotoxy::@2]
    // [576] phi gotoxy::$3 = gotoxy::x#30 [phi:gotoxy->gotoxy::@2#0] -- vbuz1=vbum2 
    sta.z gotoxy__3
    jmp __b2
    // gotoxy::@1
  __b1:
    // [575] gotoxy::$2 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z gotoxy__2
    // [576] phi from gotoxy::@1 to gotoxy::@2 [phi:gotoxy::@1->gotoxy::@2]
    // [576] phi gotoxy::$3 = gotoxy::$2 [phi:gotoxy::@1->gotoxy::@2#0] -- register_copy 
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [577] *((char *)&__conio) = gotoxy::$3 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__3
    sta __conio
    // (y>=__conio.height)?__conio.height:y
    // [578] if(gotoxy::y#30>=*((char *)&__conio+7)) goto gotoxy::@3 -- vbum1_ge__deref_pbuc1_then_la1 
    lda y
    cmp __conio+7
    bcs __b3
    // gotoxy::@4
    // [579] gotoxy::$14 = gotoxy::y#30 -- vbuz1=vbum2 
    sta.z gotoxy__14
    // [580] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [580] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [581] *((char *)&__conio+1) = gotoxy::$7 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__7
    sta __conio+1
    // __conio.cursor_x << 1
    // [582] gotoxy::$8 = *((char *)&__conio) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio
    asl
    sta.z gotoxy__8
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [583] gotoxy::$10 = gotoxy::y#30 << 1 -- vbuz1=vbum2_rol_1 
    lda y
    asl
    sta.z gotoxy__10
    // [584] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwuz1=pwuc1_derefidx_vbuz2_plus_vbuz3 
    lda.z gotoxy__8
    ldy.z gotoxy__10
    clc
    adc __conio+$15,y
    sta.z gotoxy__9
    lda __conio+$15+1,y
    adc #0
    sta.z gotoxy__9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [585] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwuz1 
    lda.z gotoxy__9
    sta __conio+$13
    lda.z gotoxy__9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [586] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [587] gotoxy::$6 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
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
    // [588] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y++;
    // [589] *((char *)&__conio+1) = ++ *((char *)&__conio+1) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+1
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [590] cputln::$2 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z cputln__2
    // [591] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [592] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [593] return 
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
    // [595] call textcolor
  // Set the charset to lower case.
  // screenlayer1();
    // [555] phi from display_frame_init_64 to textcolor [phi:display_frame_init_64->textcolor]
    // [555] phi textcolor::color#18 = WHITE [phi:display_frame_init_64->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [596] phi from display_frame_init_64 to display_frame_init_64::@2 [phi:display_frame_init_64->display_frame_init_64::@2]
    // display_frame_init_64::@2
    // bgcolor(BLUE)
    // [597] call bgcolor
    // [560] phi from display_frame_init_64::@2 to bgcolor [phi:display_frame_init_64::@2->bgcolor]
    // [560] phi bgcolor::color#14 = BLUE [phi:display_frame_init_64::@2->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [598] phi from display_frame_init_64::@2 to display_frame_init_64::@3 [phi:display_frame_init_64::@2->display_frame_init_64::@3]
    // display_frame_init_64::@3
    // scroll(0)
    // [599] call scroll
    jsr scroll
    // [600] phi from display_frame_init_64::@3 to display_frame_init_64::@4 [phi:display_frame_init_64::@3->display_frame_init_64::@4]
    // display_frame_init_64::@4
    // clrscr()
    // [601] call clrscr
    jsr clrscr
    // display_frame_init_64::vera_display_set_hstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [602] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTART = start
    // [603] *VERA_DC_HSTART = display_frame_init_64::vera_display_set_hstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstart1_start
    sta VERA_DC_HSTART
    // display_frame_init_64::vera_display_set_hstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [604] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTOP = stop
    // [605] *VERA_DC_HSTOP = display_frame_init_64::vera_display_set_hstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstop1_stop
    sta VERA_DC_HSTOP
    // display_frame_init_64::vera_display_set_vstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [606] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTART = start
    // [607] *VERA_DC_VSTART = display_frame_init_64::vera_display_set_vstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstart1_start
    sta VERA_DC_VSTART
    // display_frame_init_64::vera_display_set_vstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [608] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTOP = stop
    // [609] *VERA_DC_VSTOP = display_frame_init_64::vera_display_set_vstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstop1_stop
    sta VERA_DC_VSTOP
    // display_frame_init_64::@1
    // cx16_k_screen_set_charset(3, (char *)0)
    // [610] display_frame_init_64::cx16_k_screen_set_charset1_charset = 3 -- vbum1=vbuc1 
    lda #3
    sta cx16_k_screen_set_charset1_charset
    // [611] display_frame_init_64::cx16_k_screen_set_charset1_offset = (char *) 0 -- pbum1=pbuc1 
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
    // [613] return 
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
    // [615] call textcolor
    // [555] phi from display_frame_draw to textcolor [phi:display_frame_draw->textcolor]
    // [555] phi textcolor::color#18 = LIGHT_BLUE [phi:display_frame_draw->textcolor#0] -- vbum1=vbuc1 
    lda #LIGHT_BLUE
    sta textcolor.color
    jsr textcolor
    // [616] phi from display_frame_draw to display_frame_draw::@1 [phi:display_frame_draw->display_frame_draw::@1]
    // display_frame_draw::@1
    // bgcolor(BLUE)
    // [617] call bgcolor
    // [560] phi from display_frame_draw::@1 to bgcolor [phi:display_frame_draw::@1->bgcolor]
    // [560] phi bgcolor::color#14 = BLUE [phi:display_frame_draw::@1->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [618] phi from display_frame_draw::@1 to display_frame_draw::@2 [phi:display_frame_draw::@1->display_frame_draw::@2]
    // display_frame_draw::@2
    // clrscr()
    // [619] call clrscr
    jsr clrscr
    // [620] phi from display_frame_draw::@2 to display_frame_draw::@3 [phi:display_frame_draw::@2->display_frame_draw::@3]
    // display_frame_draw::@3
    // display_frame(0, 0, 67, 14)
    // [621] call display_frame
    // [1634] phi from display_frame_draw::@3 to display_frame [phi:display_frame_draw::@3->display_frame]
    // [1634] phi display_frame::y#0 = 0 [phi:display_frame_draw::@3->display_frame#0] -- vbum1=vbuc1 
    lda #0
    sta display_frame.y
    // [1634] phi display_frame::y1#16 = $e [phi:display_frame_draw::@3->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1634] phi display_frame::x#0 = 0 [phi:display_frame_draw::@3->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1634] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@3->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [622] phi from display_frame_draw::@3 to display_frame_draw::@4 [phi:display_frame_draw::@3->display_frame_draw::@4]
    // display_frame_draw::@4
    // display_frame(0, 0, 67, 2)
    // [623] call display_frame
    // [1634] phi from display_frame_draw::@4 to display_frame [phi:display_frame_draw::@4->display_frame]
    // [1634] phi display_frame::y#0 = 0 [phi:display_frame_draw::@4->display_frame#0] -- vbum1=vbuc1 
    lda #0
    sta display_frame.y
    // [1634] phi display_frame::y1#16 = 2 [phi:display_frame_draw::@4->display_frame#1] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y1
    // [1634] phi display_frame::x#0 = 0 [phi:display_frame_draw::@4->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1634] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@4->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [624] phi from display_frame_draw::@4 to display_frame_draw::@5 [phi:display_frame_draw::@4->display_frame_draw::@5]
    // display_frame_draw::@5
    // display_frame(0, 2, 67, 14)
    // [625] call display_frame
    // [1634] phi from display_frame_draw::@5 to display_frame [phi:display_frame_draw::@5->display_frame]
    // [1634] phi display_frame::y#0 = 2 [phi:display_frame_draw::@5->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1634] phi display_frame::y1#16 = $e [phi:display_frame_draw::@5->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1634] phi display_frame::x#0 = 0 [phi:display_frame_draw::@5->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1634] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@5->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [626] phi from display_frame_draw::@5 to display_frame_draw::@6 [phi:display_frame_draw::@5->display_frame_draw::@6]
    // display_frame_draw::@6
    // display_frame(0, 2, 8, 14)
    // [627] call display_frame
  // Chipset areas
    // [1634] phi from display_frame_draw::@6 to display_frame [phi:display_frame_draw::@6->display_frame]
    // [1634] phi display_frame::y#0 = 2 [phi:display_frame_draw::@6->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1634] phi display_frame::y1#16 = $e [phi:display_frame_draw::@6->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1634] phi display_frame::x#0 = 0 [phi:display_frame_draw::@6->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1634] phi display_frame::x1#16 = 8 [phi:display_frame_draw::@6->display_frame#3] -- vbum1=vbuc1 
    lda #8
    sta display_frame.x1
    jsr display_frame
    // [628] phi from display_frame_draw::@6 to display_frame_draw::@7 [phi:display_frame_draw::@6->display_frame_draw::@7]
    // display_frame_draw::@7
    // display_frame(8, 2, 19, 14)
    // [629] call display_frame
    // [1634] phi from display_frame_draw::@7 to display_frame [phi:display_frame_draw::@7->display_frame]
    // [1634] phi display_frame::y#0 = 2 [phi:display_frame_draw::@7->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1634] phi display_frame::y1#16 = $e [phi:display_frame_draw::@7->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1634] phi display_frame::x#0 = 8 [phi:display_frame_draw::@7->display_frame#2] -- vbum1=vbuc1 
    lda #8
    sta display_frame.x
    // [1634] phi display_frame::x1#16 = $13 [phi:display_frame_draw::@7->display_frame#3] -- vbum1=vbuc1 
    lda #$13
    sta display_frame.x1
    jsr display_frame
    // [630] phi from display_frame_draw::@7 to display_frame_draw::@8 [phi:display_frame_draw::@7->display_frame_draw::@8]
    // display_frame_draw::@8
    // display_frame(19, 2, 25, 14)
    // [631] call display_frame
    // [1634] phi from display_frame_draw::@8 to display_frame [phi:display_frame_draw::@8->display_frame]
    // [1634] phi display_frame::y#0 = 2 [phi:display_frame_draw::@8->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1634] phi display_frame::y1#16 = $e [phi:display_frame_draw::@8->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1634] phi display_frame::x#0 = $13 [phi:display_frame_draw::@8->display_frame#2] -- vbum1=vbuc1 
    lda #$13
    sta display_frame.x
    // [1634] phi display_frame::x1#16 = $19 [phi:display_frame_draw::@8->display_frame#3] -- vbum1=vbuc1 
    lda #$19
    sta display_frame.x1
    jsr display_frame
    // [632] phi from display_frame_draw::@8 to display_frame_draw::@9 [phi:display_frame_draw::@8->display_frame_draw::@9]
    // display_frame_draw::@9
    // display_frame(25, 2, 31, 14)
    // [633] call display_frame
    // [1634] phi from display_frame_draw::@9 to display_frame [phi:display_frame_draw::@9->display_frame]
    // [1634] phi display_frame::y#0 = 2 [phi:display_frame_draw::@9->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1634] phi display_frame::y1#16 = $e [phi:display_frame_draw::@9->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1634] phi display_frame::x#0 = $19 [phi:display_frame_draw::@9->display_frame#2] -- vbum1=vbuc1 
    lda #$19
    sta display_frame.x
    // [1634] phi display_frame::x1#16 = $1f [phi:display_frame_draw::@9->display_frame#3] -- vbum1=vbuc1 
    lda #$1f
    sta display_frame.x1
    jsr display_frame
    // [634] phi from display_frame_draw::@9 to display_frame_draw::@10 [phi:display_frame_draw::@9->display_frame_draw::@10]
    // display_frame_draw::@10
    // display_frame(31, 2, 37, 14)
    // [635] call display_frame
    // [1634] phi from display_frame_draw::@10 to display_frame [phi:display_frame_draw::@10->display_frame]
    // [1634] phi display_frame::y#0 = 2 [phi:display_frame_draw::@10->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1634] phi display_frame::y1#16 = $e [phi:display_frame_draw::@10->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1634] phi display_frame::x#0 = $1f [phi:display_frame_draw::@10->display_frame#2] -- vbum1=vbuc1 
    lda #$1f
    sta display_frame.x
    // [1634] phi display_frame::x1#16 = $25 [phi:display_frame_draw::@10->display_frame#3] -- vbum1=vbuc1 
    lda #$25
    sta display_frame.x1
    jsr display_frame
    // [636] phi from display_frame_draw::@10 to display_frame_draw::@11 [phi:display_frame_draw::@10->display_frame_draw::@11]
    // display_frame_draw::@11
    // display_frame(37, 2, 43, 14)
    // [637] call display_frame
    // [1634] phi from display_frame_draw::@11 to display_frame [phi:display_frame_draw::@11->display_frame]
    // [1634] phi display_frame::y#0 = 2 [phi:display_frame_draw::@11->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1634] phi display_frame::y1#16 = $e [phi:display_frame_draw::@11->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1634] phi display_frame::x#0 = $25 [phi:display_frame_draw::@11->display_frame#2] -- vbum1=vbuc1 
    lda #$25
    sta display_frame.x
    // [1634] phi display_frame::x1#16 = $2b [phi:display_frame_draw::@11->display_frame#3] -- vbum1=vbuc1 
    lda #$2b
    sta display_frame.x1
    jsr display_frame
    // [638] phi from display_frame_draw::@11 to display_frame_draw::@12 [phi:display_frame_draw::@11->display_frame_draw::@12]
    // display_frame_draw::@12
    // display_frame(43, 2, 49, 14)
    // [639] call display_frame
    // [1634] phi from display_frame_draw::@12 to display_frame [phi:display_frame_draw::@12->display_frame]
    // [1634] phi display_frame::y#0 = 2 [phi:display_frame_draw::@12->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1634] phi display_frame::y1#16 = $e [phi:display_frame_draw::@12->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1634] phi display_frame::x#0 = $2b [phi:display_frame_draw::@12->display_frame#2] -- vbum1=vbuc1 
    lda #$2b
    sta display_frame.x
    // [1634] phi display_frame::x1#16 = $31 [phi:display_frame_draw::@12->display_frame#3] -- vbum1=vbuc1 
    lda #$31
    sta display_frame.x1
    jsr display_frame
    // [640] phi from display_frame_draw::@12 to display_frame_draw::@13 [phi:display_frame_draw::@12->display_frame_draw::@13]
    // display_frame_draw::@13
    // display_frame(49, 2, 55, 14)
    // [641] call display_frame
    // [1634] phi from display_frame_draw::@13 to display_frame [phi:display_frame_draw::@13->display_frame]
    // [1634] phi display_frame::y#0 = 2 [phi:display_frame_draw::@13->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1634] phi display_frame::y1#16 = $e [phi:display_frame_draw::@13->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1634] phi display_frame::x#0 = $31 [phi:display_frame_draw::@13->display_frame#2] -- vbum1=vbuc1 
    lda #$31
    sta display_frame.x
    // [1634] phi display_frame::x1#16 = $37 [phi:display_frame_draw::@13->display_frame#3] -- vbum1=vbuc1 
    lda #$37
    sta display_frame.x1
    jsr display_frame
    // [642] phi from display_frame_draw::@13 to display_frame_draw::@14 [phi:display_frame_draw::@13->display_frame_draw::@14]
    // display_frame_draw::@14
    // display_frame(55, 2, 61, 14)
    // [643] call display_frame
    // [1634] phi from display_frame_draw::@14 to display_frame [phi:display_frame_draw::@14->display_frame]
    // [1634] phi display_frame::y#0 = 2 [phi:display_frame_draw::@14->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1634] phi display_frame::y1#16 = $e [phi:display_frame_draw::@14->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1634] phi display_frame::x#0 = $37 [phi:display_frame_draw::@14->display_frame#2] -- vbum1=vbuc1 
    lda #$37
    sta display_frame.x
    // [1634] phi display_frame::x1#16 = $3d [phi:display_frame_draw::@14->display_frame#3] -- vbum1=vbuc1 
    lda #$3d
    sta display_frame.x1
    jsr display_frame
    // [644] phi from display_frame_draw::@14 to display_frame_draw::@15 [phi:display_frame_draw::@14->display_frame_draw::@15]
    // display_frame_draw::@15
    // display_frame(61, 2, 67, 14)
    // [645] call display_frame
    // [1634] phi from display_frame_draw::@15 to display_frame [phi:display_frame_draw::@15->display_frame]
    // [1634] phi display_frame::y#0 = 2 [phi:display_frame_draw::@15->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [1634] phi display_frame::y1#16 = $e [phi:display_frame_draw::@15->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [1634] phi display_frame::x#0 = $3d [phi:display_frame_draw::@15->display_frame#2] -- vbum1=vbuc1 
    lda #$3d
    sta display_frame.x
    // [1634] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@15->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [646] phi from display_frame_draw::@15 to display_frame_draw::@16 [phi:display_frame_draw::@15->display_frame_draw::@16]
    // display_frame_draw::@16
    // display_frame(0, 14, 67, PROGRESS_Y-5)
    // [647] call display_frame
  // Progress area
    // [1634] phi from display_frame_draw::@16 to display_frame [phi:display_frame_draw::@16->display_frame]
    // [1634] phi display_frame::y#0 = $e [phi:display_frame_draw::@16->display_frame#0] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y
    // [1634] phi display_frame::y1#16 = PROGRESS_Y-5 [phi:display_frame_draw::@16->display_frame#1] -- vbum1=vbuc1 
    lda #PROGRESS_Y-5
    sta display_frame.y1
    // [1634] phi display_frame::x#0 = 0 [phi:display_frame_draw::@16->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1634] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@16->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [648] phi from display_frame_draw::@16 to display_frame_draw::@17 [phi:display_frame_draw::@16->display_frame_draw::@17]
    // display_frame_draw::@17
    // display_frame(0, PROGRESS_Y-5, 67, PROGRESS_Y-2)
    // [649] call display_frame
    // [1634] phi from display_frame_draw::@17 to display_frame [phi:display_frame_draw::@17->display_frame]
    // [1634] phi display_frame::y#0 = PROGRESS_Y-5 [phi:display_frame_draw::@17->display_frame#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-5
    sta display_frame.y
    // [1634] phi display_frame::y1#16 = PROGRESS_Y-2 [phi:display_frame_draw::@17->display_frame#1] -- vbum1=vbuc1 
    lda #PROGRESS_Y-2
    sta display_frame.y1
    // [1634] phi display_frame::x#0 = 0 [phi:display_frame_draw::@17->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1634] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@17->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [650] phi from display_frame_draw::@17 to display_frame_draw::@18 [phi:display_frame_draw::@17->display_frame_draw::@18]
    // display_frame_draw::@18
    // display_frame(0, PROGRESS_Y-2, 67, 49)
    // [651] call display_frame
    // [1634] phi from display_frame_draw::@18 to display_frame [phi:display_frame_draw::@18->display_frame]
    // [1634] phi display_frame::y#0 = PROGRESS_Y-2 [phi:display_frame_draw::@18->display_frame#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-2
    sta display_frame.y
    // [1634] phi display_frame::y1#16 = $31 [phi:display_frame_draw::@18->display_frame#1] -- vbum1=vbuc1 
    lda #$31
    sta display_frame.y1
    // [1634] phi display_frame::x#0 = 0 [phi:display_frame_draw::@18->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [1634] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@18->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [652] phi from display_frame_draw::@18 to display_frame_draw::@19 [phi:display_frame_draw::@18->display_frame_draw::@19]
    // display_frame_draw::@19
    // textcolor(WHITE)
    // [653] call textcolor
    // [555] phi from display_frame_draw::@19 to textcolor [phi:display_frame_draw::@19->textcolor]
    // [555] phi textcolor::color#18 = WHITE [phi:display_frame_draw::@19->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // display_frame_draw::@return
    // }
    // [654] return 
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
    // [656] call gotoxy
    // [573] phi from display_frame_title to gotoxy [phi:display_frame_title->gotoxy]
    // [573] phi gotoxy::y#30 = 1 [phi:display_frame_title->gotoxy#0] -- vbum1=vbuc1 
    lda #1
    sta gotoxy.y
    // [573] phi gotoxy::x#30 = 2 [phi:display_frame_title->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // [657] phi from display_frame_title to display_frame_title::@1 [phi:display_frame_title->display_frame_title::@1]
    // display_frame_title::@1
    // printf("%-65s", title_text)
    // [658] call printf_string
    // [784] phi from display_frame_title::@1 to printf_string [phi:display_frame_title::@1->printf_string]
    // [784] phi printf_string::putc#19 = &cputc [phi:display_frame_title::@1->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [784] phi printf_string::str#19 = main::title_text [phi:display_frame_title::@1->printf_string#1] -- pbuz1=pbuc1 
    lda #<main.title_text
    sta.z printf_string.str
    lda #>main.title_text
    sta.z printf_string.str+1
    // [784] phi printf_string::format_justify_left#19 = 1 [phi:display_frame_title::@1->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [784] phi printf_string::format_min_length#19 = $41 [phi:display_frame_title::@1->printf_string#3] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_frame_title::@return
    // }
    // [659] return 
    rts
}
  // cputsxy
// Move cursor and output a NUL-terminated string
// Same as "gotoxy (x, y); puts (s);"
// void cputsxy(__mem() char x, __mem() char y, __zp($48) const char *s)
cputsxy: {
    .label s = $48
    // gotoxy(x, y)
    // [661] gotoxy::x#1 = cputsxy::x#4 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [662] gotoxy::y#1 = cputsxy::y#4 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [663] call gotoxy
    // [573] phi from cputsxy to gotoxy [phi:cputsxy->gotoxy]
    // [573] phi gotoxy::y#30 = gotoxy::y#1 [phi:cputsxy->gotoxy#0] -- register_copy 
    // [573] phi gotoxy::x#30 = gotoxy::x#1 [phi:cputsxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputsxy::@1
    // cputs(s)
    // [664] cputs::s#1 = cputsxy::s#4 -- pbuz1=pbuz2 
    lda.z s
    sta.z cputs.s
    lda.z s+1
    sta.z cputs.s+1
    // [665] call cputs
    // [1768] phi from cputsxy::@1 to cputs [phi:cputsxy::@1->cputs]
    jsr cputs
    // cputsxy::@return
    // }
    // [666] return 
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
    .label info_text = $52
    // unsigned char x = wherex()
    // [668] call wherex
    jsr wherex
    // [669] wherex::return#2 = wherex::return#0
    // display_action_progress::@1
    // [670] display_action_progress::x#0 = wherex::return#2 -- vbum1=vbum2 
    lda wherex.return
    sta x
    // unsigned char y = wherey()
    // [671] call wherey
    jsr wherey
    // [672] wherey::return#2 = wherey::return#0
    // display_action_progress::@2
    // [673] display_action_progress::y#0 = wherey::return#2 -- vbum1=vbum2 
    lda wherey.return
    sta y
    // gotoxy(2, PROGRESS_Y-4)
    // [674] call gotoxy
    // [573] phi from display_action_progress::@2 to gotoxy [phi:display_action_progress::@2->gotoxy]
    // [573] phi gotoxy::y#30 = PROGRESS_Y-4 [phi:display_action_progress::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-4
    sta gotoxy.y
    // [573] phi gotoxy::x#30 = 2 [phi:display_action_progress::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // display_action_progress::@3
    // printf("%-65s", info_text)
    // [675] printf_string::str#1 = display_action_progress::info_text#14
    // [676] call printf_string
    // [784] phi from display_action_progress::@3 to printf_string [phi:display_action_progress::@3->printf_string]
    // [784] phi printf_string::putc#19 = &cputc [phi:display_action_progress::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [784] phi printf_string::str#19 = printf_string::str#1 [phi:display_action_progress::@3->printf_string#1] -- register_copy 
    // [784] phi printf_string::format_justify_left#19 = 1 [phi:display_action_progress::@3->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [784] phi printf_string::format_min_length#19 = $41 [phi:display_action_progress::@3->printf_string#3] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_action_progress::@4
    // gotoxy(x, y)
    // [677] gotoxy::x#10 = display_action_progress::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [678] gotoxy::y#10 = display_action_progress::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [679] call gotoxy
    // [573] phi from display_action_progress::@4 to gotoxy [phi:display_action_progress::@4->gotoxy]
    // [573] phi gotoxy::y#30 = gotoxy::y#10 [phi:display_action_progress::@4->gotoxy#0] -- register_copy 
    // [573] phi gotoxy::x#30 = gotoxy::x#10 [phi:display_action_progress::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_action_progress::@return
    // }
    // [680] return 
    rts
  .segment Data
    .label x = util_wait_key.bram
    .label y = clrscr.clrscr__0
}
.segment Code
  // display_progress_clear
/**
 * @brief Clean the progress area for the flashing.
 */
display_progress_clear: {
    .const h = PROGRESS_Y+PROGRESS_H
    .label x = $4d
    .label i = $c2
    .label y = $4e
    // textcolor(WHITE)
    // [682] call textcolor
    // [555] phi from display_progress_clear to textcolor [phi:display_progress_clear->textcolor]
    // [555] phi textcolor::color#18 = WHITE [phi:display_progress_clear->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [683] phi from display_progress_clear to display_progress_clear::@5 [phi:display_progress_clear->display_progress_clear::@5]
    // display_progress_clear::@5
    // bgcolor(BLUE)
    // [684] call bgcolor
    // [560] phi from display_progress_clear::@5 to bgcolor [phi:display_progress_clear::@5->bgcolor]
    // [560] phi bgcolor::color#14 = BLUE [phi:display_progress_clear::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [685] phi from display_progress_clear::@5 to display_progress_clear::@1 [phi:display_progress_clear::@5->display_progress_clear::@1]
    // [685] phi display_progress_clear::y#2 = PROGRESS_Y [phi:display_progress_clear::@5->display_progress_clear::@1#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // display_progress_clear::@1
  __b1:
    // while (y < h)
    // [686] if(display_progress_clear::y#2<display_progress_clear::h) goto display_progress_clear::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y
    cmp #h
    bcc __b4
    // display_progress_clear::@return
    // }
    // [687] return 
    rts
    // [688] phi from display_progress_clear::@1 to display_progress_clear::@2 [phi:display_progress_clear::@1->display_progress_clear::@2]
  __b4:
    // [688] phi display_progress_clear::x#2 = PROGRESS_X [phi:display_progress_clear::@1->display_progress_clear::@2#0] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z x
    // [688] phi display_progress_clear::i#2 = 0 [phi:display_progress_clear::@1->display_progress_clear::@2#1] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // display_progress_clear::@2
  __b2:
    // for(unsigned char i = 0; i < w; i++)
    // [689] if(display_progress_clear::i#2<PROGRESS_W) goto display_progress_clear::@3 -- vbuz1_lt_vbuc1_then_la1 
    lda.z i
    cmp #PROGRESS_W
    bcc __b3
    // display_progress_clear::@4
    // y++;
    // [690] display_progress_clear::y#1 = ++ display_progress_clear::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [685] phi from display_progress_clear::@4 to display_progress_clear::@1 [phi:display_progress_clear::@4->display_progress_clear::@1]
    // [685] phi display_progress_clear::y#2 = display_progress_clear::y#1 [phi:display_progress_clear::@4->display_progress_clear::@1#0] -- register_copy 
    jmp __b1
    // display_progress_clear::@3
  __b3:
    // cputcxy(x, y, ' ')
    // [691] cputcxy::x#12 = display_progress_clear::x#2 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [692] cputcxy::y#12 = display_progress_clear::y#2 -- vbum1=vbuz2 
    lda.z y
    sta cputcxy.y
    // [693] call cputcxy
    // [1781] phi from display_progress_clear::@3 to cputcxy [phi:display_progress_clear::@3->cputcxy]
    // [1781] phi cputcxy::c#15 = ' ' [phi:display_progress_clear::@3->cputcxy#0] -- vbum1=vbuc1 
    lda #' '
    sta cputcxy.c
    // [1781] phi cputcxy::y#15 = cputcxy::y#12 [phi:display_progress_clear::@3->cputcxy#1] -- register_copy 
    // [1781] phi cputcxy::x#15 = cputcxy::x#12 [phi:display_progress_clear::@3->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_progress_clear::@6
    // x++;
    // [694] display_progress_clear::x#1 = ++ display_progress_clear::x#2 -- vbuz1=_inc_vbuz1 
    inc.z x
    // for(unsigned char i = 0; i < w; i++)
    // [695] display_progress_clear::i#1 = ++ display_progress_clear::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [688] phi from display_progress_clear::@6 to display_progress_clear::@2 [phi:display_progress_clear::@6->display_progress_clear::@2]
    // [688] phi display_progress_clear::x#2 = display_progress_clear::x#1 [phi:display_progress_clear::@6->display_progress_clear::@2#0] -- register_copy 
    // [688] phi display_progress_clear::i#2 = display_progress_clear::i#1 [phi:display_progress_clear::@6->display_progress_clear::@2#1] -- register_copy 
    jmp __b2
}
  // display_chip_smc
display_chip_smc: {
    // display_smc_led(GREY)
    // [697] call display_smc_led
    // [1789] phi from display_chip_smc to display_smc_led [phi:display_chip_smc->display_smc_led]
    // [1789] phi display_smc_led::c#2 = GREY [phi:display_chip_smc->display_smc_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z display_smc_led.c
    jsr display_smc_led
    // [698] phi from display_chip_smc to display_chip_smc::@1 [phi:display_chip_smc->display_chip_smc::@1]
    // display_chip_smc::@1
    // display_print_chip(CHIP_SMC_X, CHIP_SMC_Y+2, CHIP_SMC_W, "SMC     ")
    // [699] call display_print_chip
    // [1795] phi from display_chip_smc::@1 to display_print_chip [phi:display_chip_smc::@1->display_print_chip]
    // [1795] phi display_print_chip::text#11 = display_chip_smc::text [phi:display_chip_smc::@1->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_print_chip.text_2
    lda #>text
    sta.z display_print_chip.text_2+1
    // [1795] phi display_print_chip::w#10 = 5 [phi:display_chip_smc::@1->display_print_chip#1] -- vbum1=vbuc1 
    lda #5
    sta display_print_chip.w
    // [1795] phi display_print_chip::x#10 = 1 [phi:display_chip_smc::@1->display_print_chip#2] -- vbum1=vbuc1 
    lda #1
    sta display_print_chip.x
    jsr display_print_chip
    // display_chip_smc::@return
    // }
    // [700] return 
    rts
  .segment Data
    text: .text "SMC     "
    .byte 0
}
.segment Code
  // display_chip_vera
display_chip_vera: {
    // display_vera_led(GREY)
    // [702] call display_vera_led
    // [1839] phi from display_chip_vera to display_vera_led [phi:display_chip_vera->display_vera_led]
    // [1839] phi display_vera_led::c#2 = GREY [phi:display_chip_vera->display_vera_led#0] -- vbum1=vbuc1 
    lda #GREY
    sta display_vera_led.c
    jsr display_vera_led
    // [703] phi from display_chip_vera to display_chip_vera::@1 [phi:display_chip_vera->display_chip_vera::@1]
    // display_chip_vera::@1
    // display_print_chip(CHIP_VERA_X, CHIP_VERA_Y+2, CHIP_VERA_W, "VERA     ")
    // [704] call display_print_chip
    // [1795] phi from display_chip_vera::@1 to display_print_chip [phi:display_chip_vera::@1->display_print_chip]
    // [1795] phi display_print_chip::text#11 = display_chip_vera::text [phi:display_chip_vera::@1->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_print_chip.text_2
    lda #>text
    sta.z display_print_chip.text_2+1
    // [1795] phi display_print_chip::w#10 = 8 [phi:display_chip_vera::@1->display_print_chip#1] -- vbum1=vbuc1 
    lda #8
    sta display_print_chip.w
    // [1795] phi display_print_chip::x#10 = 9 [phi:display_chip_vera::@1->display_print_chip#2] -- vbum1=vbuc1 
    lda #9
    sta display_print_chip.x
    jsr display_print_chip
    // display_chip_vera::@return
    // }
    // [705] return 
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
    .label r = $41
    // [707] phi from display_chip_rom to display_chip_rom::@1 [phi:display_chip_rom->display_chip_rom::@1]
    // [707] phi display_chip_rom::r#2 = 0 [phi:display_chip_rom->display_chip_rom::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z r
    // display_chip_rom::@1
  __b1:
    // for (unsigned char r = 0; r < 8; r++)
    // [708] if(display_chip_rom::r#2<8) goto display_chip_rom::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z r
    cmp #8
    bcc __b2
    // display_chip_rom::@return
    // }
    // [709] return 
    rts
    // [710] phi from display_chip_rom::@1 to display_chip_rom::@2 [phi:display_chip_rom::@1->display_chip_rom::@2]
    // display_chip_rom::@2
  __b2:
    // strcpy(rom, "ROM  ")
    // [711] call strcpy
    // [1845] phi from display_chip_rom::@2 to strcpy [phi:display_chip_rom::@2->strcpy]
    jsr strcpy
    // display_chip_rom::@5
    // strcat(rom, rom_size_strings[r])
    // [712] display_chip_rom::$11 = display_chip_rom::r#2 << 1 -- vbum1=vbuz2_rol_1 
    lda.z r
    asl
    sta display_chip_rom__11
    // [713] strcat::source#0 = rom_size_strings[display_chip_rom::$11] -- pbuz1=qbuc1_derefidx_vbum2 
    tay
    lda rom_size_strings,y
    sta.z strcat.source
    lda rom_size_strings+1,y
    sta.z strcat.source+1
    // [714] call strcat
    // [1853] phi from display_chip_rom::@5 to strcat [phi:display_chip_rom::@5->strcat]
    jsr strcat
    // display_chip_rom::@6
    // if(r)
    // [715] if(0==display_chip_rom::r#2) goto display_chip_rom::@3 -- 0_eq_vbuz1_then_la1 
    lda.z r
    beq __b3
    // display_chip_rom::@4
    // r+'0'
    // [716] display_chip_rom::$4 = display_chip_rom::r#2 + '0' -- vbuz1=vbuz2_plus_vbuc1 
    lda #'0'
    clc
    adc.z r
    sta.z display_chip_rom__4
    // *(rom+3) = r+'0'
    // [717] *(display_chip_rom::rom+3) = display_chip_rom::$4 -- _deref_pbuc1=vbuz1 
    sta rom+3
    // display_chip_rom::@3
  __b3:
    // display_rom_led(r, GREY)
    // [718] display_rom_led::chip#0 = display_chip_rom::r#2 -- vbuz1=vbuz2 
    lda.z r
    sta.z display_rom_led.chip
    // [719] call display_rom_led
    // [1865] phi from display_chip_rom::@3 to display_rom_led [phi:display_chip_rom::@3->display_rom_led]
    // [1865] phi display_rom_led::c#2 = GREY [phi:display_chip_rom::@3->display_rom_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z display_rom_led.c
    // [1865] phi display_rom_led::chip#2 = display_rom_led::chip#0 [phi:display_chip_rom::@3->display_rom_led#1] -- register_copy 
    jsr display_rom_led
    // display_chip_rom::@7
    // r*6
    // [720] display_chip_rom::$12 = display_chip_rom::$11 + display_chip_rom::r#2 -- vbum1=vbum1_plus_vbuz2 
    lda display_chip_rom__12
    clc
    adc.z r
    sta display_chip_rom__12
    // [721] display_chip_rom::$6 = display_chip_rom::$12 << 1 -- vbum1=vbum2_rol_1 
    asl
    sta display_chip_rom__6
    // display_print_chip(CHIP_ROM_X+r*6, CHIP_ROM_Y+2, CHIP_ROM_W, rom)
    // [722] display_print_chip::x#2 = $14 + display_chip_rom::$6 -- vbum1=vbuc1_plus_vbum1 
    lda #$14
    clc
    adc display_print_chip.x
    sta display_print_chip.x
    // [723] call display_print_chip
    // [1795] phi from display_chip_rom::@7 to display_print_chip [phi:display_chip_rom::@7->display_print_chip]
    // [1795] phi display_print_chip::text#11 = display_chip_rom::rom [phi:display_chip_rom::@7->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z display_print_chip.text_2
    lda #>rom
    sta.z display_print_chip.text_2+1
    // [1795] phi display_print_chip::w#10 = 3 [phi:display_chip_rom::@7->display_print_chip#1] -- vbum1=vbuc1 
    lda #3
    sta display_print_chip.w
    // [1795] phi display_print_chip::x#10 = display_print_chip::x#2 [phi:display_chip_rom::@7->display_print_chip#2] -- register_copy 
    jsr display_print_chip
    // display_chip_rom::@8
    // for (unsigned char r = 0; r < 8; r++)
    // [724] display_chip_rom::r#1 = ++ display_chip_rom::r#2 -- vbuz1=_inc_vbuz1 
    inc.z r
    // [707] phi from display_chip_rom::@8 to display_chip_rom::@1 [phi:display_chip_rom::@8->display_chip_rom::@1]
    // [707] phi display_chip_rom::r#2 = display_chip_rom::r#1 [phi:display_chip_rom::@8->display_chip_rom::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    rom: .fill $10, 0
    source: .text "ROM  "
    .byte 0
    .label display_chip_rom__6 = util_wait_key.return
    .label display_chip_rom__11 = clrscr.clrscr__1
    .label display_chip_rom__12 = clrscr.clrscr__1
}
.segment Code
  // display_progress_text
/**
 * @brief Print a block of text within the progress frame with a count of lines.
 * 
 * @param text A pointer to an array of strings to be displayed (char**).
 * @param lines The amount of lines to be displayed, starting from the top of the progress frame.
 */
// void display_progress_text(__zp($b5) char **text, __zp($3c) char lines)
display_progress_text: {
    .label display_progress_text__3 = $d8
    .label l = $ba
    .label lines = $3c
    .label text = $b5
    // display_progress_clear()
    // [726] call display_progress_clear
    // [681] phi from display_progress_text to display_progress_clear [phi:display_progress_text->display_progress_clear]
    jsr display_progress_clear
    // [727] phi from display_progress_text to display_progress_text::@1 [phi:display_progress_text->display_progress_text::@1]
    // [727] phi display_progress_text::l#2 = 0 [phi:display_progress_text->display_progress_text::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z l
    // display_progress_text::@1
  __b1:
    // for(unsigned char l=0; l<lines; l++)
    // [728] if(display_progress_text::l#2<display_progress_text::lines#7) goto display_progress_text::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z l
    cmp.z lines
    bcc __b2
    // display_progress_text::@return
    // }
    // [729] return 
    rts
    // display_progress_text::@2
  __b2:
    // display_progress_line(l, text[l])
    // [730] display_progress_text::$3 = display_progress_text::l#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z l
    asl
    sta.z display_progress_text__3
    // [731] display_progress_line::line#0 = display_progress_text::l#2
    // [732] display_progress_line::text#0 = display_progress_text::text#10[display_progress_text::$3] -- pbuz1=qbuz2_derefidx_vbuz3 
    tay
    lda (text),y
    sta.z display_progress_line.text
    iny
    lda (text),y
    sta.z display_progress_line.text+1
    // [733] call display_progress_line
    jsr display_progress_line
    // display_progress_text::@3
    // for(unsigned char l=0; l<lines; l++)
    // [734] display_progress_text::l#1 = ++ display_progress_text::l#2 -- vbuz1=_inc_vbuz1 
    inc.z l
    // [727] phi from display_progress_text::@3 to display_progress_text::@1 [phi:display_progress_text::@3->display_progress_text::@1]
    // [727] phi display_progress_text::l#2 = display_progress_text::l#1 [phi:display_progress_text::@3->display_progress_text::@1#0] -- register_copy 
    jmp __b1
}
  // util_wait_space
util_wait_space: {
    // util_wait_key("Press [SPACE] to continue ...", " ")
    // [736] call util_wait_key
    // [1505] phi from util_wait_space to util_wait_key [phi:util_wait_space->util_wait_key]
    // [1505] phi util_wait_key::filter#12 = s1 [phi:util_wait_space->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<s1
    sta.z util_wait_key.filter
    lda #>s1
    sta.z util_wait_key.filter+1
    // [1505] phi util_wait_key::info_text#2 = util_wait_space::info_text [phi:util_wait_space->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z util_wait_key.info_text
    lda #>info_text
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // util_wait_space::@return
    // }
    // [737] return 
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
    // This conditional compilation ensures that only the detection interpretation happens if it is switched on.
    .label return = 1
    // smc_detect::@return
    // [739] return 
    rts
}
  // smc_version
/**
 * @brief Detect and write the SMC version number into the info_text.
 * 
 * @param version_string The string containing the SMC version filled upon return.
 */
// unsigned long smc_version(char *version_string)
smc_version: {
    .label version = $63
    .label major = $bd
    .label minor = $f1
    // unsigned int version = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_VERSION)
    // [740] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [741] cx16_k_i2c_read_byte::offset = $30 -- vbum1=vbuc1 
    lda #$30
    sta cx16_k_i2c_read_byte.offset
    // [742] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [743] cx16_k_i2c_read_byte::return#2 = cx16_k_i2c_read_byte::return#1
    // smc_version::@1
    // [744] smc_version::version#0 = cx16_k_i2c_read_byte::return#2 -- vwuz1=vwum2 
    lda cx16_k_i2c_read_byte.return
    sta.z version
    lda cx16_k_i2c_read_byte.return+1
    sta.z version+1
    // unsigned int major = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_MAJOR)
    // [745] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [746] cx16_k_i2c_read_byte::offset = $31 -- vbum1=vbuc1 
    lda #$31
    sta cx16_k_i2c_read_byte.offset
    // [747] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [748] cx16_k_i2c_read_byte::return#10 = cx16_k_i2c_read_byte::return#1
    // smc_version::@2
    // [749] smc_version::major#0 = cx16_k_i2c_read_byte::return#10 -- vwuz1=vwum2 
    lda cx16_k_i2c_read_byte.return
    sta.z major
    lda cx16_k_i2c_read_byte.return+1
    sta.z major+1
    // unsigned int minor = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_MINOR)
    // [750] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [751] cx16_k_i2c_read_byte::offset = $32 -- vbum1=vbuc1 
    lda #$32
    sta cx16_k_i2c_read_byte.offset
    // [752] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [753] cx16_k_i2c_read_byte::return#11 = cx16_k_i2c_read_byte::return#1
    // smc_version::@3
    // [754] smc_version::minor#0 = cx16_k_i2c_read_byte::return#11 -- vwuz1=vwum2 
    lda cx16_k_i2c_read_byte.return
    sta.z minor
    lda cx16_k_i2c_read_byte.return+1
    sta.z minor+1
    // sprintf(version_string, "%u.%u.%u", version, major, minor)
    // [755] call snprintf_init
    // [770] phi from smc_version::@3 to snprintf_init [phi:smc_version::@3->snprintf_init]
    // [770] phi snprintf_init::s#25 = smc_version_string [phi:smc_version::@3->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<smc_version_string
    sta.z snprintf_init.s
    lda #>smc_version_string
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // smc_version::@4
    // sprintf(version_string, "%u.%u.%u", version, major, minor)
    // [756] printf_uint::uvalue#1 = smc_version::version#0 -- vwum1=vwuz2 
    lda.z version
    sta printf_uint.uvalue
    lda.z version+1
    sta printf_uint.uvalue+1
    // [757] call printf_uint
    // [809] phi from smc_version::@4 to printf_uint [phi:smc_version::@4->printf_uint]
    // [809] phi printf_uint::format_zero_padding#18 = 0 [phi:smc_version::@4->printf_uint#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uint.format_zero_padding
    // [809] phi printf_uint::format_min_length#18 = 0 [phi:smc_version::@4->printf_uint#1] -- vbum1=vbuc1 
    sta printf_uint.format_min_length
    // [809] phi printf_uint::putc#18 = &snputc [phi:smc_version::@4->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [809] phi printf_uint::format_radix#18 = DECIMAL [phi:smc_version::@4->printf_uint#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uint.format_radix
    // [809] phi printf_uint::uvalue#18 = printf_uint::uvalue#1 [phi:smc_version::@4->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [758] phi from smc_version::@4 to smc_version::@5 [phi:smc_version::@4->smc_version::@5]
    // smc_version::@5
    // sprintf(version_string, "%u.%u.%u", version, major, minor)
    // [759] call printf_str
    // [775] phi from smc_version::@5 to printf_str [phi:smc_version::@5->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:smc_version::@5->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = smc_version::s [phi:smc_version::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_version::@6
    // sprintf(version_string, "%u.%u.%u", version, major, minor)
    // [760] printf_uint::uvalue#2 = smc_version::major#0 -- vwum1=vwuz2 
    lda.z major
    sta printf_uint.uvalue
    lda.z major+1
    sta printf_uint.uvalue+1
    // [761] call printf_uint
    // [809] phi from smc_version::@6 to printf_uint [phi:smc_version::@6->printf_uint]
    // [809] phi printf_uint::format_zero_padding#18 = 0 [phi:smc_version::@6->printf_uint#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uint.format_zero_padding
    // [809] phi printf_uint::format_min_length#18 = 0 [phi:smc_version::@6->printf_uint#1] -- vbum1=vbuc1 
    sta printf_uint.format_min_length
    // [809] phi printf_uint::putc#18 = &snputc [phi:smc_version::@6->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [809] phi printf_uint::format_radix#18 = DECIMAL [phi:smc_version::@6->printf_uint#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uint.format_radix
    // [809] phi printf_uint::uvalue#18 = printf_uint::uvalue#2 [phi:smc_version::@6->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [762] phi from smc_version::@6 to smc_version::@7 [phi:smc_version::@6->smc_version::@7]
    // smc_version::@7
    // sprintf(version_string, "%u.%u.%u", version, major, minor)
    // [763] call printf_str
    // [775] phi from smc_version::@7 to printf_str [phi:smc_version::@7->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:smc_version::@7->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = smc_version::s [phi:smc_version::@7->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_version::@8
    // sprintf(version_string, "%u.%u.%u", version, major, minor)
    // [764] printf_uint::uvalue#3 = smc_version::minor#0 -- vwum1=vwuz2 
    lda.z minor
    sta printf_uint.uvalue
    lda.z minor+1
    sta printf_uint.uvalue+1
    // [765] call printf_uint
    // [809] phi from smc_version::@8 to printf_uint [phi:smc_version::@8->printf_uint]
    // [809] phi printf_uint::format_zero_padding#18 = 0 [phi:smc_version::@8->printf_uint#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uint.format_zero_padding
    // [809] phi printf_uint::format_min_length#18 = 0 [phi:smc_version::@8->printf_uint#1] -- vbum1=vbuc1 
    sta printf_uint.format_min_length
    // [809] phi printf_uint::putc#18 = &snputc [phi:smc_version::@8->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [809] phi printf_uint::format_radix#18 = DECIMAL [phi:smc_version::@8->printf_uint#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uint.format_radix
    // [809] phi printf_uint::uvalue#18 = printf_uint::uvalue#3 [phi:smc_version::@8->printf_uint#4] -- register_copy 
    jsr printf_uint
    // smc_version::@9
    // sprintf(version_string, "%u.%u.%u", version, major, minor)
    // [766] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [767] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_version::@return
    // }
    // [769] return 
    rts
  .segment Data
    s: .text "."
    .byte 0
}
.segment Code
  // snprintf_init
/// Initialize the snprintf() state
// void snprintf_init(__zp($48) char *s, unsigned int n)
snprintf_init: {
    .label s = $48
    // __snprintf_capacity = n
    // [771] __snprintf_capacity = $ffff -- vwum1=vwuc1 
    lda #<$ffff
    sta __snprintf_capacity
    lda #>$ffff
    sta __snprintf_capacity+1
    // __snprintf_size = 0
    // [772] __snprintf_size = 0 -- vwum1=vbuc1 
    lda #<0
    sta __snprintf_size
    sta __snprintf_size+1
    // __snprintf_buffer = s
    // [773] __snprintf_buffer = snprintf_init::s#25 -- pbuz1=pbuz2 
    lda.z s
    sta.z __snprintf_buffer
    lda.z s+1
    sta.z __snprintf_buffer+1
    // snprintf_init::@return
    // }
    // [774] return 
    rts
}
  // printf_str
/// Print a NUL-terminated string
// void printf_str(__zp($b5) void (*putc)(char), __zp($52) const char *s)
printf_str: {
    .label s = $52
    .label putc = $b5
    // [776] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [776] phi printf_str::s#72 = printf_str::s#73 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [777] printf_str::c#1 = *printf_str::s#72 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta c
    // [778] printf_str::s#0 = ++ printf_str::s#72 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [779] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // printf_str::@return
    // }
    // [780] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [781] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [782] callexecute *printf_str::putc#73  -- call__deref_pprz1 
    jsr icall13
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
    // Outside Flow
  icall13:
    jmp (putc)
  .segment Data
    c: .byte 0
}
.segment Code
  // printf_string
// Print a string value using a specific format
// Handles justification and min length 
// void printf_string(__zp($54) void (*putc)(char), __zp($52) char *str, __mem() char format_min_length, __mem() char format_justify_left)
printf_string: {
    .label printf_string__9 = $bd
    .label str = $52
    .label putc = $54
    // if(format.min_length)
    // [785] if(0==printf_string::format_min_length#19) goto printf_string::@1 -- 0_eq_vbum1_then_la1 
    lda format_min_length
    beq __b3
    // printf_string::@3
    // strlen(str)
    // [786] strlen::str#3 = printf_string::str#19 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [787] call strlen
    // [1885] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [1885] phi strlen::str#8 = strlen::str#3 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [788] strlen::return#10 = strlen::len#2
    // printf_string::@6
    // [789] printf_string::$9 = strlen::return#10 -- vwuz1=vwum2 
    lda strlen.return
    sta.z printf_string__9
    lda strlen.return+1
    sta.z printf_string__9+1
    // signed char len = (signed char)strlen(str)
    // [790] printf_string::len#0 = (signed char)printf_string::$9 -- vbsm1=_sbyte_vwuz2 
    lda.z printf_string__9
    sta len
    // padding = (signed char)format.min_length  - len
    // [791] printf_string::padding#1 = (signed char)printf_string::format_min_length#19 - printf_string::len#0 -- vbsm1=vbsm1_minus_vbsm2 
    lda padding
    sec
    sbc len
    sta padding
    // if(padding<0)
    // [792] if(printf_string::padding#1>=0) goto printf_string::@10 -- vbsm1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [794] phi from printf_string printf_string::@6 to printf_string::@1 [phi:printf_string/printf_string::@6->printf_string::@1]
  __b3:
    // [794] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@6->printf_string::@1#0] -- vbsm1=vbsc1 
    lda #0
    sta padding
    // [793] phi from printf_string::@6 to printf_string::@10 [phi:printf_string::@6->printf_string::@10]
    // printf_string::@10
    // [794] phi from printf_string::@10 to printf_string::@1 [phi:printf_string::@10->printf_string::@1]
    // [794] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@10->printf_string::@1#0] -- register_copy 
    // printf_string::@1
  __b1:
    // if(!format.justify_left && padding)
    // [795] if(0!=printf_string::format_justify_left#19) goto printf_string::@2 -- 0_neq_vbum1_then_la1 
    lda format_justify_left
    bne __b2
    // printf_string::@8
    // [796] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b4
    jmp __b2
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [797] printf_padding::putc#3 = printf_string::putc#19 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [798] printf_padding::length#3 = (char)printf_string::padding#3 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [799] call printf_padding
    // [1891] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    // [1891] phi printf_padding::putc#7 = printf_padding::putc#3 [phi:printf_string::@4->printf_padding#0] -- register_copy 
    // [1891] phi printf_padding::pad#7 = ' ' [phi:printf_string::@4->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [1891] phi printf_padding::length#6 = printf_padding::length#3 [phi:printf_string::@4->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [800] printf_str::putc#1 = printf_string::putc#19 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_str.putc
    lda.z putc+1
    sta.z printf_str.putc+1
    // [801] printf_str::s#2 = printf_string::str#19
    // [802] call printf_str
    // [775] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [775] phi printf_str::putc#73 = printf_str::putc#1 [phi:printf_string::@2->printf_str#0] -- register_copy 
    // [775] phi printf_str::s#73 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@7
    // if(format.justify_left && padding)
    // [803] if(0==printf_string::format_justify_left#19) goto printf_string::@return -- 0_eq_vbum1_then_la1 
    lda format_justify_left
    beq __breturn
    // printf_string::@9
    // [804] if(0!=printf_string::padding#3) goto printf_string::@5 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b5
    rts
    // printf_string::@5
  __b5:
    // printf_padding(putc, ' ',(char)padding)
    // [805] printf_padding::putc#4 = printf_string::putc#19 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [806] printf_padding::length#4 = (char)printf_string::padding#3 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [807] call printf_padding
    // [1891] phi from printf_string::@5 to printf_padding [phi:printf_string::@5->printf_padding]
    // [1891] phi printf_padding::putc#7 = printf_padding::putc#4 [phi:printf_string::@5->printf_padding#0] -- register_copy 
    // [1891] phi printf_padding::pad#7 = ' ' [phi:printf_string::@5->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [1891] phi printf_padding::length#6 = printf_padding::length#4 [phi:printf_string::@5->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@return
  __breturn:
    // }
    // [808] return 
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
    // [810] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [811] utoa::value#1 = printf_uint::uvalue#18
    // [812] utoa::radix#0 = printf_uint::format_radix#18
    // [813] call utoa
    // Format number into buffer
    jsr utoa
    // printf_uint::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [814] printf_number_buffer::putc#1 = printf_uint::putc#18
    // [815] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [816] printf_number_buffer::format_min_length#1 = printf_uint::format_min_length#18
    // [817] printf_number_buffer::format_zero_padding#1 = printf_uint::format_zero_padding#18
    // [818] call printf_number_buffer
  // Print using format
    // [1929] phi from printf_uint::@2 to printf_number_buffer [phi:printf_uint::@2->printf_number_buffer]
    // [1929] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#1 [phi:printf_uint::@2->printf_number_buffer#0] -- register_copy 
    // [1929] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_uint::@2->printf_number_buffer#1] -- register_copy 
    // [1929] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#1 [phi:printf_uint::@2->printf_number_buffer#2] -- register_copy 
    // [1929] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#1 [phi:printf_uint::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uint::@return
    // }
    // [819] return 
    rts
  .segment Data
    uvalue: .word 0
    format_radix: .byte 0
    format_min_length: .byte 0
    format_zero_padding: .byte 0
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
// void display_info_smc(__zp($29) char info_status, __zp($44) char *info_text)
display_info_smc: {
    .label display_info_smc__8 = $29
    .label info_status = $29
    .label info_text = $44
    // unsigned char x = wherex()
    // [821] call wherex
    jsr wherex
    // [822] wherex::return#10 = wherex::return#0
    // display_info_smc::@3
    // [823] display_info_smc::x#0 = wherex::return#10 -- vbum1=vbum2 
    lda wherex.return
    sta x
    // unsigned char y = wherey()
    // [824] call wherey
    jsr wherey
    // [825] wherey::return#10 = wherey::return#0
    // display_info_smc::@4
    // [826] display_info_smc::y#0 = wherey::return#10 -- vbum1=vbum2 
    lda wherey.return
    sta y
    // status_smc = info_status
    // [827] status_smc#0 = display_info_smc::info_status#12 -- vbum1=vbuz2 
    lda.z info_status
    sta status_smc
    // display_smc_led(status_color[info_status])
    // [828] display_smc_led::c#1 = status_color[display_info_smc::info_status#12] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z display_smc_led.c
    // [829] call display_smc_led
    // [1789] phi from display_info_smc::@4 to display_smc_led [phi:display_info_smc::@4->display_smc_led]
    // [1789] phi display_smc_led::c#2 = display_smc_led::c#1 [phi:display_info_smc::@4->display_smc_led#0] -- register_copy 
    jsr display_smc_led
    // [830] phi from display_info_smc::@4 to display_info_smc::@5 [phi:display_info_smc::@4->display_info_smc::@5]
    // display_info_smc::@5
    // gotoxy(INFO_X, INFO_Y)
    // [831] call gotoxy
    // [573] phi from display_info_smc::@5 to gotoxy [phi:display_info_smc::@5->gotoxy]
    // [573] phi gotoxy::y#30 = $11 [phi:display_info_smc::@5->gotoxy#0] -- vbum1=vbuc1 
    lda #$11
    sta gotoxy.y
    // [573] phi gotoxy::x#30 = 4 [phi:display_info_smc::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.x
    jsr gotoxy
    // [832] phi from display_info_smc::@5 to display_info_smc::@6 [phi:display_info_smc::@5->display_info_smc::@6]
    // display_info_smc::@6
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [833] call printf_str
    // [775] phi from display_info_smc::@6 to printf_str [phi:display_info_smc::@6->printf_str]
    // [775] phi printf_str::putc#73 = &cputc [phi:display_info_smc::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = display_info_smc::s [phi:display_info_smc::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@7
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [834] display_info_smc::$8 = display_info_smc::info_status#12 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_info_smc__8
    // [835] printf_string::str#3 = status_text[display_info_smc::$8] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z display_info_smc__8
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [836] call printf_string
    // [784] phi from display_info_smc::@7 to printf_string [phi:display_info_smc::@7->printf_string]
    // [784] phi printf_string::putc#19 = &cputc [phi:display_info_smc::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [784] phi printf_string::str#19 = printf_string::str#3 [phi:display_info_smc::@7->printf_string#1] -- register_copy 
    // [784] phi printf_string::format_justify_left#19 = 1 [phi:display_info_smc::@7->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [784] phi printf_string::format_min_length#19 = 9 [phi:display_info_smc::@7->printf_string#3] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [837] phi from display_info_smc::@7 to display_info_smc::@8 [phi:display_info_smc::@7->display_info_smc::@8]
    // display_info_smc::@8
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [838] call printf_str
    // [775] phi from display_info_smc::@8 to printf_str [phi:display_info_smc::@8->printf_str]
    // [775] phi printf_str::putc#73 = &cputc [phi:display_info_smc::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = display_info_smc::s1 [phi:display_info_smc::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@9
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [839] printf_uint::uvalue#0 = smc_file_size#12 -- vwum1=vwum2 
    lda smc_file_size_2
    sta printf_uint.uvalue
    lda smc_file_size_2+1
    sta printf_uint.uvalue+1
    // [840] call printf_uint
    // [809] phi from display_info_smc::@9 to printf_uint [phi:display_info_smc::@9->printf_uint]
    // [809] phi printf_uint::format_zero_padding#18 = 1 [phi:display_info_smc::@9->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [809] phi printf_uint::format_min_length#18 = 5 [phi:display_info_smc::@9->printf_uint#1] -- vbum1=vbuc1 
    lda #5
    sta printf_uint.format_min_length
    // [809] phi printf_uint::putc#18 = &cputc [phi:display_info_smc::@9->printf_uint#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uint.putc
    lda #>cputc
    sta.z printf_uint.putc+1
    // [809] phi printf_uint::format_radix#18 = HEXADECIMAL [phi:display_info_smc::@9->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [809] phi printf_uint::uvalue#18 = printf_uint::uvalue#0 [phi:display_info_smc::@9->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [841] phi from display_info_smc::@9 to display_info_smc::@10 [phi:display_info_smc::@9->display_info_smc::@10]
    // display_info_smc::@10
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [842] call printf_str
    // [775] phi from display_info_smc::@10 to printf_str [phi:display_info_smc::@10->printf_str]
    // [775] phi printf_str::putc#73 = &cputc [phi:display_info_smc::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = display_info_smc::s2 [phi:display_info_smc::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@11
    // if(info_text)
    // [843] if((char *)0==display_info_smc::info_text#12) goto display_info_smc::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // display_info_smc::@2
    // printf("%-25s", info_text)
    // [844] printf_string::str#4 = display_info_smc::info_text#12 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [845] call printf_string
    // [784] phi from display_info_smc::@2 to printf_string [phi:display_info_smc::@2->printf_string]
    // [784] phi printf_string::putc#19 = &cputc [phi:display_info_smc::@2->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [784] phi printf_string::str#19 = printf_string::str#4 [phi:display_info_smc::@2->printf_string#1] -- register_copy 
    // [784] phi printf_string::format_justify_left#19 = 1 [phi:display_info_smc::@2->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [784] phi printf_string::format_min_length#19 = $19 [phi:display_info_smc::@2->printf_string#3] -- vbum1=vbuc1 
    lda #$19
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_smc::@1
  __b1:
    // gotoxy(x, y)
    // [846] gotoxy::x#14 = display_info_smc::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [847] gotoxy::y#14 = display_info_smc::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [848] call gotoxy
    // [573] phi from display_info_smc::@1 to gotoxy [phi:display_info_smc::@1->gotoxy]
    // [573] phi gotoxy::y#30 = gotoxy::y#14 [phi:display_info_smc::@1->gotoxy#0] -- register_copy 
    // [573] phi gotoxy::x#30 = gotoxy::x#14 [phi:display_info_smc::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_smc::@return
    // }
    // [849] return 
    rts
  .segment Data
    s: .text "SMC  "
    .byte 0
    s1: .text " ATTiny "
    .byte 0
    s2: .text " / 01E00 "
    .byte 0
    .label x = clrscr.clrscr__2
    .label y = fopen.fopen__4
}
.segment Code
  // display_info_vera
/**
 * @brief Display the VERA status at the info frame.
 * 
 * @param info_status The STATUS_ 
 */
// void display_info_vera(__zp($62) char info_status, __zp($c9) char *info_text)
display_info_vera: {
    .label display_info_vera__8 = $62
    .label x = $50
    .label y = $bc
    .label info_status = $62
    .label info_text = $c9
    // unsigned char x = wherex()
    // [851] call wherex
    jsr wherex
    // [852] wherex::return#11 = wherex::return#0
    // display_info_vera::@3
    // [853] display_info_vera::x#0 = wherex::return#11 -- vbuz1=vbum2 
    lda wherex.return
    sta.z x
    // unsigned char y = wherey()
    // [854] call wherey
    jsr wherey
    // [855] wherey::return#11 = wherey::return#0
    // display_info_vera::@4
    // [856] display_info_vera::y#0 = wherey::return#11 -- vbuz1=vbum2 
    lda wherey.return
    sta.z y
    // status_vera = info_status
    // [857] status_vera#0 = display_info_vera::info_status#2 -- vbum1=vbuz2 
    lda.z info_status
    sta status_vera
    // display_vera_led(status_color[info_status])
    // [858] display_vera_led::c#1 = status_color[display_info_vera::info_status#2] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta display_vera_led.c
    // [859] call display_vera_led
    // [1839] phi from display_info_vera::@4 to display_vera_led [phi:display_info_vera::@4->display_vera_led]
    // [1839] phi display_vera_led::c#2 = display_vera_led::c#1 [phi:display_info_vera::@4->display_vera_led#0] -- register_copy 
    jsr display_vera_led
    // [860] phi from display_info_vera::@4 to display_info_vera::@5 [phi:display_info_vera::@4->display_info_vera::@5]
    // display_info_vera::@5
    // gotoxy(INFO_X, INFO_Y+1)
    // [861] call gotoxy
    // [573] phi from display_info_vera::@5 to gotoxy [phi:display_info_vera::@5->gotoxy]
    // [573] phi gotoxy::y#30 = $11+1 [phi:display_info_vera::@5->gotoxy#0] -- vbum1=vbuc1 
    lda #$11+1
    sta gotoxy.y
    // [573] phi gotoxy::x#30 = 4 [phi:display_info_vera::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.x
    jsr gotoxy
    // [862] phi from display_info_vera::@5 to display_info_vera::@6 [phi:display_info_vera::@5->display_info_vera::@6]
    // display_info_vera::@6
    // printf("VERA %-9s FPGA   1a000 / 1a000 ", status_text[info_status])
    // [863] call printf_str
    // [775] phi from display_info_vera::@6 to printf_str [phi:display_info_vera::@6->printf_str]
    // [775] phi printf_str::putc#73 = &cputc [phi:display_info_vera::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = display_info_vera::s [phi:display_info_vera::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@7
    // printf("VERA %-9s FPGA   1a000 / 1a000 ", status_text[info_status])
    // [864] display_info_vera::$8 = display_info_vera::info_status#2 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_info_vera__8
    // [865] printf_string::str#5 = status_text[display_info_vera::$8] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z display_info_vera__8
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [866] call printf_string
    // [784] phi from display_info_vera::@7 to printf_string [phi:display_info_vera::@7->printf_string]
    // [784] phi printf_string::putc#19 = &cputc [phi:display_info_vera::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [784] phi printf_string::str#19 = printf_string::str#5 [phi:display_info_vera::@7->printf_string#1] -- register_copy 
    // [784] phi printf_string::format_justify_left#19 = 1 [phi:display_info_vera::@7->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [784] phi printf_string::format_min_length#19 = 9 [phi:display_info_vera::@7->printf_string#3] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [867] phi from display_info_vera::@7 to display_info_vera::@8 [phi:display_info_vera::@7->display_info_vera::@8]
    // display_info_vera::@8
    // printf("VERA %-9s FPGA   1a000 / 1a000 ", status_text[info_status])
    // [868] call printf_str
    // [775] phi from display_info_vera::@8 to printf_str [phi:display_info_vera::@8->printf_str]
    // [775] phi printf_str::putc#73 = &cputc [phi:display_info_vera::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = display_info_vera::s1 [phi:display_info_vera::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@9
    // if(info_text)
    // [869] if((char *)0==display_info_vera::info_text#10) goto display_info_vera::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // display_info_vera::@2
    // printf("%-25s", info_text)
    // [870] printf_string::str#6 = display_info_vera::info_text#10 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [871] call printf_string
    // [784] phi from display_info_vera::@2 to printf_string [phi:display_info_vera::@2->printf_string]
    // [784] phi printf_string::putc#19 = &cputc [phi:display_info_vera::@2->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [784] phi printf_string::str#19 = printf_string::str#6 [phi:display_info_vera::@2->printf_string#1] -- register_copy 
    // [784] phi printf_string::format_justify_left#19 = 1 [phi:display_info_vera::@2->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [784] phi printf_string::format_min_length#19 = $19 [phi:display_info_vera::@2->printf_string#3] -- vbum1=vbuc1 
    lda #$19
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_vera::@1
  __b1:
    // gotoxy(x, y)
    // [872] gotoxy::x#16 = display_info_vera::x#0 -- vbum1=vbuz2 
    lda.z x
    sta gotoxy.x
    // [873] gotoxy::y#16 = display_info_vera::y#0 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [874] call gotoxy
    // [573] phi from display_info_vera::@1 to gotoxy [phi:display_info_vera::@1->gotoxy]
    // [573] phi gotoxy::y#30 = gotoxy::y#16 [phi:display_info_vera::@1->gotoxy#0] -- register_copy 
    // [573] phi gotoxy::x#30 = gotoxy::x#16 [phi:display_info_vera::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_vera::@return
    // }
    // [875] return 
    rts
  .segment Data
    s: .text "VERA "
    .byte 0
    s1: .text " FPGA   1a000 / 1a000 "
    .byte 0
}
.segment Code
  // rom_detect
rom_detect: {
    .const bank_set_brom1_bank = 4
    .label rom_detect__9 = $4f
    .label rom_detect__16 = $b1
    .label rom_detect__19 = $b2
    .label rom_chip = $4c
    .label rom_detect_address = $c4
    // [877] phi from rom_detect to rom_detect::@1 [phi:rom_detect->rom_detect::@1]
    // [877] phi rom_detect::rom_chip#10 = 0 [phi:rom_detect->rom_detect::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_chip
    // [877] phi rom_detect::rom_detect_address#10 = 0 [phi:rom_detect->rom_detect::@1#1] -- vduz1=vduc1 
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
    // [878] if(rom_detect::rom_detect_address#10<8*$80000) goto rom_detect::@2 -- vduz1_lt_vduc1_then_la1 
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
    // [879] return 
    rts
    // rom_detect::@2
  __b2:
    // rom_manufacturer_ids[rom_chip] = 0
    // [880] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    ldy.z rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = 0
    // [881] rom_device_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta rom_device_ids,y
    // if (rom_detect_address == 0x0)
    // [882] if(rom_detect::rom_detect_address#10!=0) goto rom_detect::bank_set_brom1 -- vduz1_neq_0_then_la1 
    lda.z rom_detect_address
    ora.z rom_detect_address+1
    ora.z rom_detect_address+2
    ora.z rom_detect_address+3
    bne bank_set_brom1
    // rom_detect::@9
    // rom_manufacturer_ids[rom_chip] = 0x9f
    // [883] rom_manufacturer_ids[rom_detect::rom_chip#10] = $9f -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$9f
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF040
    // [884] rom_device_ids[rom_detect::rom_chip#10] = $b7 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$b7
    sta rom_device_ids,y
    // rom_detect::bank_set_brom1
  bank_set_brom1:
    // BROM = bank
    // [885] BROM = rom_detect::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // rom_detect::@12
    // rom_chip*3
    // [886] rom_detect::$9 = rom_detect::rom_chip#10 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta.z rom_detect__9
    // [887] rom_detect::$4 = rom_detect::$9 + rom_detect::rom_chip#10 -- vbum1=vbuz2_plus_vbuz3 
    clc
    adc.z rom_chip
    sta rom_detect__4
    // gotoxy(rom_chip*3+40, 1)
    // [888] gotoxy::x#23 = rom_detect::$4 + $28 -- vbum1=vbum2_plus_vbuc1 
    lda #$28
    clc
    adc rom_detect__4
    sta gotoxy.x
    // [889] call gotoxy
    // [573] phi from rom_detect::@12 to gotoxy [phi:rom_detect::@12->gotoxy]
    // [573] phi gotoxy::y#30 = 1 [phi:rom_detect::@12->gotoxy#0] -- vbum1=vbuc1 
    lda #1
    sta gotoxy.y
    // [573] phi gotoxy::x#30 = gotoxy::x#23 [phi:rom_detect::@12->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_detect::@13
    // printf("%02x", rom_device_ids[rom_chip])
    // [890] printf_uchar::uvalue#4 = rom_device_ids[rom_detect::rom_chip#10] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z rom_chip
    lda rom_device_ids,y
    sta printf_uchar.uvalue
    // [891] call printf_uchar
    // [982] phi from rom_detect::@13 to printf_uchar [phi:rom_detect::@13->printf_uchar]
    // [982] phi printf_uchar::format_zero_padding#11 = 1 [phi:rom_detect::@13->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [982] phi printf_uchar::format_min_length#11 = 2 [phi:rom_detect::@13->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [982] phi printf_uchar::putc#11 = &cputc [phi:rom_detect::@13->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [982] phi printf_uchar::format_radix#11 = HEXADECIMAL [phi:rom_detect::@13->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [982] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#4 [phi:rom_detect::@13->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // rom_detect::@14
    // case SST39SF010A:
    //             rom_device_names[rom_chip] = "f010a";
    //             rom_size_strings[rom_chip] = "128";
    //             rom_sizes[rom_chip] = 128 * 1024;
    //             break;
    // [892] if(rom_device_ids[rom_detect::rom_chip#10]==$b5) goto rom_detect::@3 -- pbuc1_derefidx_vbuz1_eq_vbuc2_then_la1 
    ldy.z rom_chip
    lda rom_device_ids,y
    cmp #$b5
    bne !__b3+
    jmp __b3
  !__b3:
    // rom_detect::@10
    // case SST39SF020A:
    //             rom_device_names[rom_chip] = "f020a";
    //             rom_size_strings[rom_chip] = "256";
    //             rom_sizes[rom_chip] = 256 * 1024;
    //             break;
    // [893] if(rom_device_ids[rom_detect::rom_chip#10]==$b6) goto rom_detect::@4 -- pbuc1_derefidx_vbuz1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b6
    bne !__b4+
    jmp __b4
  !__b4:
    // rom_detect::@11
    // case SST39SF040:
    //             rom_device_names[rom_chip] = "f040";
    //             rom_size_strings[rom_chip] = "512";
    //             rom_sizes[rom_chip] = 512 * 1024;
    //             break;
    // [894] if(rom_device_ids[rom_detect::rom_chip#10]==$b7) goto rom_detect::@5 -- pbuc1_derefidx_vbuz1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b7
    beq __b5
    // rom_detect::@6
    // rom_manufacturer_ids[rom_chip] = 0
    // [895] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    sta rom_manufacturer_ids,y
    // rom_device_names[rom_chip] = "----"
    // [896] rom_device_names[rom_detect::$9] = rom_detect::$26 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__9
    lda #<rom_detect__26
    sta rom_device_names,y
    lda #>rom_detect__26
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "000"
    // [897] rom_size_strings[rom_detect::$9] = rom_detect::$27 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__27
    sta rom_size_strings,y
    lda #>rom_detect__27
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 0
    // [898] rom_detect::$19 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta.z rom_detect__19
    // [899] rom_sizes[rom_detect::$19] = 0 -- pduc1_derefidx_vbuz1=vbuc2 
    tay
    lda #0
    sta rom_sizes,y
    sta rom_sizes+1,y
    sta rom_sizes+2,y
    sta rom_sizes+3,y
    // rom_device_ids[rom_chip] = UNKNOWN
    // [900] rom_device_ids[rom_detect::rom_chip#10] = $55 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$55
    ldy.z rom_chip
    sta rom_device_ids,y
    // rom_detect::@7
  __b7:
    // rom_chip++;
    // [901] rom_detect::rom_chip#1 = ++ rom_detect::rom_chip#10 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip
    // rom_detect::@8
    // rom_detect_address += 0x80000
    // [902] rom_detect::rom_detect_address#1 = rom_detect::rom_detect_address#10 + $80000 -- vduz1=vduz1_plus_vduc1 
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
    // [877] phi from rom_detect::@8 to rom_detect::@1 [phi:rom_detect::@8->rom_detect::@1]
    // [877] phi rom_detect::rom_chip#10 = rom_detect::rom_chip#1 [phi:rom_detect::@8->rom_detect::@1#0] -- register_copy 
    // [877] phi rom_detect::rom_detect_address#10 = rom_detect::rom_detect_address#1 [phi:rom_detect::@8->rom_detect::@1#1] -- register_copy 
    jmp __b1
    // rom_detect::@5
  __b5:
    // rom_device_names[rom_chip] = "f040"
    // [903] rom_device_names[rom_detect::$9] = rom_detect::$24 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__9
    lda #<rom_detect__24
    sta rom_device_names,y
    lda #>rom_detect__24
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "512"
    // [904] rom_size_strings[rom_detect::$9] = rom_detect::$25 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__25
    sta rom_size_strings,y
    lda #>rom_detect__25
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 512 * 1024
    // [905] rom_detect::$16 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta.z rom_detect__16
    // [906] rom_sizes[rom_detect::$16] = (unsigned long)$200*$400 -- pduc1_derefidx_vbuz1=vduc2 
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
    // [907] rom_device_names[rom_detect::$9] = rom_detect::$22 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__9
    lda #<rom_detect__22
    sta rom_device_names,y
    lda #>rom_detect__22
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "256"
    // [908] rom_size_strings[rom_detect::$9] = rom_detect::$23 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__23
    sta rom_size_strings,y
    lda #>rom_detect__23
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 256 * 1024
    // [909] rom_detect::$13 = rom_detect::rom_chip#10 << 2 -- vbum1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta rom_detect__13
    // [910] rom_sizes[rom_detect::$13] = (unsigned long)$100*$400 -- pduc1_derefidx_vbum1=vduc2 
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
    // [911] rom_device_names[rom_detect::$9] = rom_detect::$20 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__9
    lda #<rom_detect__20
    sta rom_device_names,y
    lda #>rom_detect__20
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "128"
    // [912] rom_size_strings[rom_detect::$9] = rom_detect::$21 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__21
    sta rom_size_strings,y
    lda #>rom_detect__21
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 128 * 1024
    // [913] rom_detect::$10 = rom_detect::rom_chip#10 << 2 -- vbum1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta rom_detect__10
    // [914] rom_sizes[rom_detect::$10] = (unsigned long)$80*$400 -- pduc1_derefidx_vbum1=vduc2 
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
    rom_detect__20: .text "f010a"
    .byte 0
    rom_detect__21: .text "128"
    .byte 0
    rom_detect__22: .text "f020a"
    .byte 0
    rom_detect__23: .text "256"
    .byte 0
    rom_detect__24: .text "f040"
    .byte 0
    rom_detect__25: .text "512"
    .byte 0
    rom_detect__26: .text "----"
    .byte 0
    rom_detect__27: .text "000"
    .byte 0
    rom_detect__4: .byte 0
    rom_detect__10: .byte 0
    rom_detect__13: .byte 0
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
    .label return = $e6
    .label ram_ptr = $d9
    .label smc_file_size = $e6
    /// Holds the amount of bytes actually read in the memory to be flashed.
    .label progress_row_bytes = $e2
    .label y = $2a
    // display_action_progress("Reading SMC.BIN ... (.) data, ( ) empty")
    // [916] call display_action_progress
  // It is assume that one RAM bank is 0X2000 bytes.
    // [667] phi from smc_read to display_action_progress [phi:smc_read->display_action_progress]
    // [667] phi display_action_progress::info_text#14 = smc_read::info_text [phi:smc_read->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [917] phi from smc_read to smc_read::@7 [phi:smc_read->smc_read::@7]
    // smc_read::@7
    // textcolor(WHITE)
    // [918] call textcolor
    // [555] phi from smc_read::@7 to textcolor [phi:smc_read::@7->textcolor]
    // [555] phi textcolor::color#18 = WHITE [phi:smc_read::@7->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [919] phi from smc_read::@7 to smc_read::@8 [phi:smc_read::@7->smc_read::@8]
    // smc_read::@8
    // gotoxy(x, y)
    // [920] call gotoxy
    // [573] phi from smc_read::@8 to gotoxy [phi:smc_read::@8->gotoxy]
    // [573] phi gotoxy::y#30 = PROGRESS_Y [phi:smc_read::@8->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [573] phi gotoxy::x#30 = PROGRESS_X [phi:smc_read::@8->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [921] phi from smc_read::@8 to smc_read::@9 [phi:smc_read::@8->smc_read::@9]
    // smc_read::@9
    // FILE *fp = fopen("SMC.BIN", "r")
    // [922] call fopen
    // [1960] phi from smc_read::@9 to fopen [phi:smc_read::@9->fopen]
    // [1960] phi __errno#321 = __errno#35 [phi:smc_read::@9->fopen#0] -- register_copy 
    // [1960] phi fopen::pathtoken#0 = smc_read::path [phi:smc_read::@9->fopen#1] -- pbuz1=pbuc1 
    lda #<path
    sta.z fopen.pathtoken
    lda #>path
    sta.z fopen.pathtoken+1
    jsr fopen
    // FILE *fp = fopen("SMC.BIN", "r")
    // [923] fopen::return#3 = fopen::return#2
    // smc_read::@10
    // [924] smc_read::fp#0 = fopen::return#3 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [925] if((struct $2 *)0==smc_read::fp#0) goto smc_read::@1 -- pssc1_eq_pssz1_then_la1 
    lda.z fp
    cmp #<0
    bne !+
    lda.z fp+1
    cmp #>0
    beq __b4
  !:
    // [926] phi from smc_read::@10 to smc_read::@2 [phi:smc_read::@10->smc_read::@2]
    // [926] phi smc_read::y#10 = PROGRESS_Y [phi:smc_read::@10->smc_read::@2#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // [926] phi smc_read::progress_row_bytes#10 = 0 [phi:smc_read::@10->smc_read::@2#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z progress_row_bytes
    sta.z progress_row_bytes+1
    // [926] phi smc_read::smc_file_size#11 = 0 [phi:smc_read::@10->smc_read::@2#2] -- vwuz1=vwuc1 
    sta.z smc_file_size
    sta.z smc_file_size+1
    // [926] phi smc_read::ram_ptr#10 = (char *)$6000 [phi:smc_read::@10->smc_read::@2#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z ram_ptr
    lda #>$6000
    sta.z ram_ptr+1
  // We read block_size bytes at a time, and each block_size bytes we plot a dot.
  // Every r bytes we move to the next line.
    // smc_read::@2
  __b2:
    // fgets(ram_ptr, SMC_PROGRESS_CELL, fp)
    // [927] fgets::ptr#2 = smc_read::ram_ptr#10 -- pbuz1=pbuz2 
    lda.z ram_ptr
    sta.z fgets.ptr
    lda.z ram_ptr+1
    sta.z fgets.ptr+1
    // [928] fgets::stream#0 = smc_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.stream
    lda.z fp+1
    sta.z fgets.stream+1
    // [929] call fgets
    // [2041] phi from smc_read::@2 to fgets [phi:smc_read::@2->fgets]
    // [2041] phi fgets::ptr#12 = fgets::ptr#2 [phi:smc_read::@2->fgets#0] -- register_copy 
    // [2041] phi fgets::size#10 = SMC_PROGRESS_CELL [phi:smc_read::@2->fgets#1] -- vwum1=vbuc1 
    lda #<SMC_PROGRESS_CELL
    sta fgets.size
    lda #>SMC_PROGRESS_CELL
    sta fgets.size+1
    // [2041] phi fgets::stream#2 = fgets::stream#0 [phi:smc_read::@2->fgets#2] -- register_copy 
    jsr fgets
    // fgets(ram_ptr, SMC_PROGRESS_CELL, fp)
    // [930] fgets::return#5 = fgets::return#1
    // smc_read::@11
    // smc_file_read = fgets(ram_ptr, SMC_PROGRESS_CELL, fp)
    // [931] smc_read::smc_file_read#1 = fgets::return#5 -- vwum1=vwum2 
    lda fgets.return
    sta smc_file_read
    lda fgets.return+1
    sta smc_file_read+1
    // while (smc_file_read = fgets(ram_ptr, SMC_PROGRESS_CELL, fp))
    // [932] if(0!=smc_read::smc_file_read#1) goto smc_read::@3 -- 0_neq_vwum1_then_la1 
    lda smc_file_read
    ora smc_file_read+1
    bne __b3
    // smc_read::@4
    // fclose(fp)
    // [933] fclose::stream#0 = smc_read::fp#0
    // [934] call fclose
    // [2095] phi from smc_read::@4 to fclose [phi:smc_read::@4->fclose]
    // [2095] phi fclose::stream#2 = fclose::stream#0 [phi:smc_read::@4->fclose#0] -- register_copy 
    jsr fclose
    // [935] phi from smc_read::@4 to smc_read::@1 [phi:smc_read::@4->smc_read::@1]
    // [935] phi smc_read::return#0 = smc_read::smc_file_size#11 [phi:smc_read::@4->smc_read::@1#0] -- register_copy 
    rts
    // [935] phi from smc_read::@10 to smc_read::@1 [phi:smc_read::@10->smc_read::@1]
  __b4:
    // [935] phi smc_read::return#0 = 0 [phi:smc_read::@10->smc_read::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // smc_read::@1
    // smc_read::@return
    // }
    // [936] return 
    rts
    // [937] phi from smc_read::@11 to smc_read::@3 [phi:smc_read::@11->smc_read::@3]
    // smc_read::@3
  __b3:
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [938] call snprintf_init
    // [770] phi from smc_read::@3 to snprintf_init [phi:smc_read::@3->snprintf_init]
    // [770] phi snprintf_init::s#25 = info_text [phi:smc_read::@3->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [939] phi from smc_read::@3 to smc_read::@12 [phi:smc_read::@3->smc_read::@12]
    // smc_read::@12
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [940] call printf_str
    // [775] phi from smc_read::@12 to printf_str [phi:smc_read::@12->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:smc_read::@12->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = smc_read::s [phi:smc_read::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@13
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [941] printf_uint::uvalue#4 = smc_read::smc_file_read#1 -- vwum1=vwum2 
    lda smc_file_read
    sta printf_uint.uvalue
    lda smc_file_read+1
    sta printf_uint.uvalue+1
    // [942] call printf_uint
    // [809] phi from smc_read::@13 to printf_uint [phi:smc_read::@13->printf_uint]
    // [809] phi printf_uint::format_zero_padding#18 = 1 [phi:smc_read::@13->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [809] phi printf_uint::format_min_length#18 = 5 [phi:smc_read::@13->printf_uint#1] -- vbum1=vbuc1 
    lda #5
    sta printf_uint.format_min_length
    // [809] phi printf_uint::putc#18 = &snputc [phi:smc_read::@13->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [809] phi printf_uint::format_radix#18 = HEXADECIMAL [phi:smc_read::@13->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [809] phi printf_uint::uvalue#18 = printf_uint::uvalue#4 [phi:smc_read::@13->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [943] phi from smc_read::@13 to smc_read::@14 [phi:smc_read::@13->smc_read::@14]
    // smc_read::@14
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [944] call printf_str
    // [775] phi from smc_read::@14 to printf_str [phi:smc_read::@14->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:smc_read::@14->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = s4 [phi:smc_read::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@15
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [945] printf_uint::uvalue#5 = smc_read::smc_file_size#11 -- vwum1=vwuz2 
    lda.z smc_file_size
    sta printf_uint.uvalue
    lda.z smc_file_size+1
    sta printf_uint.uvalue+1
    // [946] call printf_uint
    // [809] phi from smc_read::@15 to printf_uint [phi:smc_read::@15->printf_uint]
    // [809] phi printf_uint::format_zero_padding#18 = 1 [phi:smc_read::@15->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [809] phi printf_uint::format_min_length#18 = 5 [phi:smc_read::@15->printf_uint#1] -- vbum1=vbuc1 
    lda #5
    sta printf_uint.format_min_length
    // [809] phi printf_uint::putc#18 = &snputc [phi:smc_read::@15->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [809] phi printf_uint::format_radix#18 = HEXADECIMAL [phi:smc_read::@15->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [809] phi printf_uint::uvalue#18 = printf_uint::uvalue#5 [phi:smc_read::@15->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [947] phi from smc_read::@15 to smc_read::@16 [phi:smc_read::@15->smc_read::@16]
    // smc_read::@16
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [948] call printf_str
    // [775] phi from smc_read::@16 to printf_str [phi:smc_read::@16->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:smc_read::@16->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = s2 [phi:smc_read::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // [949] phi from smc_read::@16 to smc_read::@17 [phi:smc_read::@16->smc_read::@17]
    // smc_read::@17
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [950] call printf_uint
    // [809] phi from smc_read::@17 to printf_uint [phi:smc_read::@17->printf_uint]
    // [809] phi printf_uint::format_zero_padding#18 = 1 [phi:smc_read::@17->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [809] phi printf_uint::format_min_length#18 = 2 [phi:smc_read::@17->printf_uint#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uint.format_min_length
    // [809] phi printf_uint::putc#18 = &snputc [phi:smc_read::@17->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [809] phi printf_uint::format_radix#18 = HEXADECIMAL [phi:smc_read::@17->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [809] phi printf_uint::uvalue#18 = 0 [phi:smc_read::@17->printf_uint#4] -- vwum1=vbuc1 
    lda #<0
    sta printf_uint.uvalue
    sta printf_uint.uvalue+1
    jsr printf_uint
    // [951] phi from smc_read::@17 to smc_read::@18 [phi:smc_read::@17->smc_read::@18]
    // smc_read::@18
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [952] call printf_str
    // [775] phi from smc_read::@18 to printf_str [phi:smc_read::@18->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:smc_read::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = s3 [phi:smc_read::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@19
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [953] printf_uint::uvalue#7 = (unsigned int)smc_read::ram_ptr#10 -- vwum1=vwuz2 
    lda.z ram_ptr
    sta printf_uint.uvalue
    lda.z ram_ptr+1
    sta printf_uint.uvalue+1
    // [954] call printf_uint
    // [809] phi from smc_read::@19 to printf_uint [phi:smc_read::@19->printf_uint]
    // [809] phi printf_uint::format_zero_padding#18 = 1 [phi:smc_read::@19->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [809] phi printf_uint::format_min_length#18 = 4 [phi:smc_read::@19->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [809] phi printf_uint::putc#18 = &snputc [phi:smc_read::@19->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [809] phi printf_uint::format_radix#18 = HEXADECIMAL [phi:smc_read::@19->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [809] phi printf_uint::uvalue#18 = printf_uint::uvalue#7 [phi:smc_read::@19->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [955] phi from smc_read::@19 to smc_read::@20 [phi:smc_read::@19->smc_read::@20]
    // smc_read::@20
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [956] call printf_str
    // [775] phi from smc_read::@20 to printf_str [phi:smc_read::@20->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:smc_read::@20->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = s7 [phi:smc_read::@20->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@21
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [957] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [958] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [960] call display_action_text
    // [993] phi from smc_read::@21 to display_action_text [phi:smc_read::@21->display_action_text]
    // [993] phi display_action_text::info_text#19 = info_text [phi:smc_read::@21->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_read::@22
    // if (progress_row_bytes == SMC_PROGRESS_ROW)
    // [961] if(smc_read::progress_row_bytes#10!=SMC_PROGRESS_ROW) goto smc_read::@5 -- vwuz1_neq_vwuc1_then_la1 
    lda.z progress_row_bytes+1
    cmp #>SMC_PROGRESS_ROW
    bne __b5
    lda.z progress_row_bytes
    cmp #<SMC_PROGRESS_ROW
    bne __b5
    // smc_read::@6
    // gotoxy(x, ++y);
    // [962] smc_read::y#1 = ++ smc_read::y#10 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [963] gotoxy::y#20 = smc_read::y#1 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [964] call gotoxy
    // [573] phi from smc_read::@6 to gotoxy [phi:smc_read::@6->gotoxy]
    // [573] phi gotoxy::y#30 = gotoxy::y#20 [phi:smc_read::@6->gotoxy#0] -- register_copy 
    // [573] phi gotoxy::x#30 = PROGRESS_X [phi:smc_read::@6->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [965] phi from smc_read::@6 to smc_read::@5 [phi:smc_read::@6->smc_read::@5]
    // [965] phi smc_read::y#20 = smc_read::y#1 [phi:smc_read::@6->smc_read::@5#0] -- register_copy 
    // [965] phi smc_read::progress_row_bytes#4 = 0 [phi:smc_read::@6->smc_read::@5#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z progress_row_bytes
    sta.z progress_row_bytes+1
    // [965] phi from smc_read::@22 to smc_read::@5 [phi:smc_read::@22->smc_read::@5]
    // [965] phi smc_read::y#20 = smc_read::y#10 [phi:smc_read::@22->smc_read::@5#0] -- register_copy 
    // [965] phi smc_read::progress_row_bytes#4 = smc_read::progress_row_bytes#10 [phi:smc_read::@22->smc_read::@5#1] -- register_copy 
    // smc_read::@5
  __b5:
    // cputc('.')
    // [966] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [967] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // ram_ptr += smc_file_read
    // [969] smc_read::ram_ptr#1 = smc_read::ram_ptr#10 + smc_read::smc_file_read#1 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z ram_ptr
    adc smc_file_read
    sta.z ram_ptr
    lda.z ram_ptr+1
    adc smc_file_read+1
    sta.z ram_ptr+1
    // smc_file_size += smc_file_read
    // [970] smc_read::smc_file_size#1 = smc_read::smc_file_size#11 + smc_read::smc_file_read#1 -- vwuz1=vwuz1_plus_vwum2 
    clc
    lda.z smc_file_size
    adc smc_file_read
    sta.z smc_file_size
    lda.z smc_file_size+1
    adc smc_file_read+1
    sta.z smc_file_size+1
    // progress_row_bytes += smc_file_read
    // [971] smc_read::progress_row_bytes#1 = smc_read::progress_row_bytes#4 + smc_read::smc_file_read#1 -- vwuz1=vwuz1_plus_vwum2 
    clc
    lda.z progress_row_bytes
    adc smc_file_read
    sta.z progress_row_bytes
    lda.z progress_row_bytes+1
    adc smc_file_read+1
    sta.z progress_row_bytes+1
    // [926] phi from smc_read::@5 to smc_read::@2 [phi:smc_read::@5->smc_read::@2]
    // [926] phi smc_read::y#10 = smc_read::y#20 [phi:smc_read::@5->smc_read::@2#0] -- register_copy 
    // [926] phi smc_read::progress_row_bytes#10 = smc_read::progress_row_bytes#1 [phi:smc_read::@5->smc_read::@2#1] -- register_copy 
    // [926] phi smc_read::smc_file_size#11 = smc_read::smc_file_size#1 [phi:smc_read::@5->smc_read::@2#2] -- register_copy 
    // [926] phi smc_read::ram_ptr#10 = smc_read::ram_ptr#1 [phi:smc_read::@5->smc_read::@2#3] -- register_copy 
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
    // [973] BRAM = system_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // system_reset::bank_set_brom1
    // BROM = bank
    // [974] BROM = system_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // system_reset::@2
    // asm
    // asm { jmp($FFFC)  }
    jmp ($fffc)
    // [976] phi from system_reset::@1 system_reset::@2 to system_reset::@1 [phi:system_reset::@1/system_reset::@2->system_reset::@1]
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
    .label i = $52
    // [978] phi from wait_moment to wait_moment::@1 [phi:wait_moment->wait_moment::@1]
    // [978] phi wait_moment::i#2 = $ffff [phi:wait_moment->wait_moment::@1#0] -- vwuz1=vwuc1 
    lda #<$ffff
    sta.z i
    lda #>$ffff
    sta.z i+1
    // wait_moment::@1
  __b1:
    // for(unsigned int i=65535; i>0; i--)
    // [979] if(wait_moment::i#2>0) goto wait_moment::@2 -- vwuz1_gt_0_then_la1 
    lda.z i+1
    bne __b2
    lda.z i
    bne __b2
  !:
    // wait_moment::@return
    // }
    // [980] return 
    rts
    // wait_moment::@2
  __b2:
    // for(unsigned int i=65535; i>0; i--)
    // [981] wait_moment::i#1 = -- wait_moment::i#2 -- vwuz1=_dec_vwuz1 
    lda.z i
    bne !+
    dec.z i+1
  !:
    dec.z i
    // [978] phi from wait_moment::@2 to wait_moment::@1 [phi:wait_moment::@2->wait_moment::@1]
    // [978] phi wait_moment::i#2 = wait_moment::i#1 [phi:wait_moment::@2->wait_moment::@1#0] -- register_copy 
    jmp __b1
}
  // printf_uchar
// Print an unsigned char using a specific format
// void printf_uchar(__zp($b5) void (*putc)(char), __mem() char uvalue, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, __mem() char format_radix)
printf_uchar: {
    .label putc = $b5
    // printf_uchar::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [983] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // uctoa(uvalue, printf_buffer.digits, format.radix)
    // [984] uctoa::value#1 = printf_uchar::uvalue#11
    // [985] uctoa::radix#0 = printf_uchar::format_radix#11
    // [986] call uctoa
    // Format number into buffer
    jsr uctoa
    // printf_uchar::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [987] printf_number_buffer::putc#2 = printf_uchar::putc#11
    // [988] printf_number_buffer::buffer_sign#2 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [989] printf_number_buffer::format_min_length#2 = printf_uchar::format_min_length#11
    // [990] printf_number_buffer::format_zero_padding#2 = printf_uchar::format_zero_padding#11
    // [991] call printf_number_buffer
  // Print using format
    // [1929] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [1929] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#2 [phi:printf_uchar::@2->printf_number_buffer#0] -- register_copy 
    // [1929] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#2 [phi:printf_uchar::@2->printf_number_buffer#1] -- register_copy 
    // [1929] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#2 [phi:printf_uchar::@2->printf_number_buffer#2] -- register_copy 
    // [1929] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#2 [phi:printf_uchar::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [992] return 
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
// void display_action_text(__zp($54) char *info_text)
display_action_text: {
    .label x = $cd
    .label y = $c8
    .label info_text = $54
    // unsigned char x = wherex()
    // [994] call wherex
    jsr wherex
    // [995] wherex::return#3 = wherex::return#0
    // display_action_text::@1
    // [996] display_action_text::x#0 = wherex::return#3 -- vbuz1=vbum2 
    lda wherex.return
    sta.z x
    // unsigned char y = wherey()
    // [997] call wherey
    jsr wherey
    // [998] wherey::return#3 = wherey::return#0
    // display_action_text::@2
    // [999] display_action_text::y#0 = wherey::return#3 -- vbuz1=vbum2 
    lda wherey.return
    sta.z y
    // gotoxy(2, PROGRESS_Y-3)
    // [1000] call gotoxy
    // [573] phi from display_action_text::@2 to gotoxy [phi:display_action_text::@2->gotoxy]
    // [573] phi gotoxy::y#30 = PROGRESS_Y-3 [phi:display_action_text::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-3
    sta gotoxy.y
    // [573] phi gotoxy::x#30 = 2 [phi:display_action_text::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // display_action_text::@3
    // printf("%-65s", info_text)
    // [1001] printf_string::str#2 = display_action_text::info_text#19 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1002] call printf_string
    // [784] phi from display_action_text::@3 to printf_string [phi:display_action_text::@3->printf_string]
    // [784] phi printf_string::putc#19 = &cputc [phi:display_action_text::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [784] phi printf_string::str#19 = printf_string::str#2 [phi:display_action_text::@3->printf_string#1] -- register_copy 
    // [784] phi printf_string::format_justify_left#19 = 1 [phi:display_action_text::@3->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [784] phi printf_string::format_min_length#19 = $41 [phi:display_action_text::@3->printf_string#3] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_action_text::@4
    // gotoxy(x, y)
    // [1003] gotoxy::x#12 = display_action_text::x#0 -- vbum1=vbuz2 
    lda.z x
    sta gotoxy.x
    // [1004] gotoxy::y#12 = display_action_text::y#0 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [1005] call gotoxy
    // [573] phi from display_action_text::@4 to gotoxy [phi:display_action_text::@4->gotoxy]
    // [573] phi gotoxy::y#30 = gotoxy::y#12 [phi:display_action_text::@4->gotoxy#0] -- register_copy 
    // [573] phi gotoxy::x#30 = gotoxy::x#12 [phi:display_action_text::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_action_text::@return
    // }
    // [1006] return 
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
    // [1008] BRAM = smc_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // smc_reset::bank_set_brom1
    // BROM = bank
    // [1009] BROM = smc_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // smc_reset::@2
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [1010] smc_reset::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [1011] smc_reset::cx16_k_i2c_write_byte1_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte1_offset
    // [1012] smc_reset::cx16_k_i2c_write_byte1_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte1_value
    // smc_reset::cx16_k_i2c_write_byte1
    // unsigned char result
    // [1013] smc_reset::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
    sta cx16_k_i2c_write_byte1_result
    // asm
    // asm { ldxdevice ldyoffset ldavalue stzresult jsrCX16_I2C_WRITE_BYTE rolresult  }
    ldx cx16_k_i2c_write_byte1_device
    ldy cx16_k_i2c_write_byte1_offset
    lda cx16_k_i2c_write_byte1_value
    stz cx16_k_i2c_write_byte1_result
    jsr CX16_I2C_WRITE_BYTE
    rol cx16_k_i2c_write_byte1_result
    // [1015] phi from smc_reset::@1 smc_reset::cx16_k_i2c_write_byte1 to smc_reset::@1 [phi:smc_reset::@1/smc_reset::cx16_k_i2c_write_byte1->smc_reset::@1]
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
// void display_info_rom(__zp($42) char rom_chip, __zp($6d) char info_status, __zp($38) char *info_text)
display_info_rom: {
    .label display_info_rom__10 = $6d
    .label display_info_rom__11 = $e0
    .label display_info_rom__13 = $ee
    .label x = $d0
    .label y = $7c
    .label rom_chip = $42
    .label info_status = $6d
    .label info_text = $38
    // unsigned char x = wherex()
    // [1017] call wherex
    jsr wherex
    // [1018] wherex::return#12 = wherex::return#0
    // display_info_rom::@3
    // [1019] display_info_rom::x#0 = wherex::return#12 -- vbuz1=vbum2 
    lda wherex.return
    sta.z x
    // unsigned char y = wherey()
    // [1020] call wherey
    jsr wherey
    // [1021] wherey::return#12 = wherey::return#0
    // display_info_rom::@4
    // [1022] display_info_rom::y#0 = wherey::return#12 -- vbuz1=vbum2 
    lda wherey.return
    sta.z y
    // status_rom[rom_chip] = info_status
    // [1023] status_rom[display_info_rom::rom_chip#16] = display_info_rom::info_status#16 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z info_status
    ldy.z rom_chip
    sta status_rom,y
    // display_rom_led(rom_chip, status_color[info_status])
    // [1024] display_rom_led::chip#1 = display_info_rom::rom_chip#16 -- vbuz1=vbuz2 
    tya
    sta.z display_rom_led.chip
    // [1025] display_rom_led::c#1 = status_color[display_info_rom::info_status#16] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z display_rom_led.c
    // [1026] call display_rom_led
    // [1865] phi from display_info_rom::@4 to display_rom_led [phi:display_info_rom::@4->display_rom_led]
    // [1865] phi display_rom_led::c#2 = display_rom_led::c#1 [phi:display_info_rom::@4->display_rom_led#0] -- register_copy 
    // [1865] phi display_rom_led::chip#2 = display_rom_led::chip#1 [phi:display_info_rom::@4->display_rom_led#1] -- register_copy 
    jsr display_rom_led
    // display_info_rom::@5
    // gotoxy(INFO_X, INFO_Y+rom_chip+2)
    // [1027] gotoxy::y#17 = display_info_rom::rom_chip#16 + $11+2 -- vbum1=vbuz2_plus_vbuc1 
    lda #$11+2
    clc
    adc.z rom_chip
    sta gotoxy.y
    // [1028] call gotoxy
    // [573] phi from display_info_rom::@5 to gotoxy [phi:display_info_rom::@5->gotoxy]
    // [573] phi gotoxy::y#30 = gotoxy::y#17 [phi:display_info_rom::@5->gotoxy#0] -- register_copy 
    // [573] phi gotoxy::x#30 = 4 [phi:display_info_rom::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.x
    jsr gotoxy
    // [1029] phi from display_info_rom::@5 to display_info_rom::@6 [phi:display_info_rom::@5->display_info_rom::@6]
    // display_info_rom::@6
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1030] call printf_str
    // [775] phi from display_info_rom::@6 to printf_str [phi:display_info_rom::@6->printf_str]
    // [775] phi printf_str::putc#73 = &cputc [phi:display_info_rom::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = display_info_rom::s [phi:display_info_rom::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@7
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1031] printf_uchar::uvalue#0 = display_info_rom::rom_chip#16 -- vbum1=vbuz2 
    lda.z rom_chip
    sta printf_uchar.uvalue
    // [1032] call printf_uchar
    // [982] phi from display_info_rom::@7 to printf_uchar [phi:display_info_rom::@7->printf_uchar]
    // [982] phi printf_uchar::format_zero_padding#11 = 0 [phi:display_info_rom::@7->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [982] phi printf_uchar::format_min_length#11 = 0 [phi:display_info_rom::@7->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [982] phi printf_uchar::putc#11 = &cputc [phi:display_info_rom::@7->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [982] phi printf_uchar::format_radix#11 = DECIMAL [phi:display_info_rom::@7->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [982] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#0 [phi:display_info_rom::@7->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1033] phi from display_info_rom::@7 to display_info_rom::@8 [phi:display_info_rom::@7->display_info_rom::@8]
    // display_info_rom::@8
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1034] call printf_str
    // [775] phi from display_info_rom::@8 to printf_str [phi:display_info_rom::@8->printf_str]
    // [775] phi printf_str::putc#73 = &cputc [phi:display_info_rom::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = s1 [phi:display_info_rom::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@9
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1035] display_info_rom::$10 = display_info_rom::info_status#16 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_info_rom__10
    // [1036] printf_string::str#7 = status_text[display_info_rom::$10] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z display_info_rom__10
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [1037] call printf_string
    // [784] phi from display_info_rom::@9 to printf_string [phi:display_info_rom::@9->printf_string]
    // [784] phi printf_string::putc#19 = &cputc [phi:display_info_rom::@9->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [784] phi printf_string::str#19 = printf_string::str#7 [phi:display_info_rom::@9->printf_string#1] -- register_copy 
    // [784] phi printf_string::format_justify_left#19 = 1 [phi:display_info_rom::@9->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [784] phi printf_string::format_min_length#19 = 9 [phi:display_info_rom::@9->printf_string#3] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [1038] phi from display_info_rom::@9 to display_info_rom::@10 [phi:display_info_rom::@9->display_info_rom::@10]
    // display_info_rom::@10
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1039] call printf_str
    // [775] phi from display_info_rom::@10 to printf_str [phi:display_info_rom::@10->printf_str]
    // [775] phi printf_str::putc#73 = &cputc [phi:display_info_rom::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = s1 [phi:display_info_rom::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@11
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1040] display_info_rom::$11 = display_info_rom::rom_chip#16 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta.z display_info_rom__11
    // [1041] printf_string::str#8 = rom_device_names[display_info_rom::$11] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda rom_device_names,y
    sta.z printf_string.str
    lda rom_device_names+1,y
    sta.z printf_string.str+1
    // [1042] call printf_string
    // [784] phi from display_info_rom::@11 to printf_string [phi:display_info_rom::@11->printf_string]
    // [784] phi printf_string::putc#19 = &cputc [phi:display_info_rom::@11->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [784] phi printf_string::str#19 = printf_string::str#8 [phi:display_info_rom::@11->printf_string#1] -- register_copy 
    // [784] phi printf_string::format_justify_left#19 = 1 [phi:display_info_rom::@11->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [784] phi printf_string::format_min_length#19 = 6 [phi:display_info_rom::@11->printf_string#3] -- vbum1=vbuc1 
    lda #6
    sta printf_string.format_min_length
    jsr printf_string
    // [1043] phi from display_info_rom::@11 to display_info_rom::@12 [phi:display_info_rom::@11->display_info_rom::@12]
    // display_info_rom::@12
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1044] call printf_str
    // [775] phi from display_info_rom::@12 to printf_str [phi:display_info_rom::@12->printf_str]
    // [775] phi printf_str::putc#73 = &cputc [phi:display_info_rom::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = s1 [phi:display_info_rom::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@13
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1045] display_info_rom::$13 = display_info_rom::rom_chip#16 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta.z display_info_rom__13
    // [1046] printf_ulong::uvalue#0 = file_sizes[display_info_rom::$13] -- vdum1=pduc1_derefidx_vbuz2 
    tay
    lda file_sizes,y
    sta printf_ulong.uvalue
    lda file_sizes+1,y
    sta printf_ulong.uvalue+1
    lda file_sizes+2,y
    sta printf_ulong.uvalue+2
    lda file_sizes+3,y
    sta printf_ulong.uvalue+3
    // [1047] call printf_ulong
    // [1217] phi from display_info_rom::@13 to printf_ulong [phi:display_info_rom::@13->printf_ulong]
    // [1217] phi printf_ulong::format_zero_padding#11 = 1 [phi:display_info_rom::@13->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1217] phi printf_ulong::format_min_length#11 = 5 [phi:display_info_rom::@13->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1217] phi printf_ulong::putc#11 = &cputc [phi:display_info_rom::@13->printf_ulong#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_ulong.putc
    lda #>cputc
    sta.z printf_ulong.putc+1
    // [1217] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:display_info_rom::@13->printf_ulong#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1217] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#0 [phi:display_info_rom::@13->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1048] phi from display_info_rom::@13 to display_info_rom::@14 [phi:display_info_rom::@13->display_info_rom::@14]
    // display_info_rom::@14
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1049] call printf_str
    // [775] phi from display_info_rom::@14 to printf_str [phi:display_info_rom::@14->printf_str]
    // [775] phi printf_str::putc#73 = &cputc [phi:display_info_rom::@14->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = display_info_rom::s4 [phi:display_info_rom::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@15
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1050] printf_ulong::uvalue#1 = rom_sizes[display_info_rom::$13] -- vdum1=pduc1_derefidx_vbuz2 
    ldy.z display_info_rom__13
    lda rom_sizes,y
    sta printf_ulong.uvalue
    lda rom_sizes+1,y
    sta printf_ulong.uvalue+1
    lda rom_sizes+2,y
    sta printf_ulong.uvalue+2
    lda rom_sizes+3,y
    sta printf_ulong.uvalue+3
    // [1051] call printf_ulong
    // [1217] phi from display_info_rom::@15 to printf_ulong [phi:display_info_rom::@15->printf_ulong]
    // [1217] phi printf_ulong::format_zero_padding#11 = 1 [phi:display_info_rom::@15->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1217] phi printf_ulong::format_min_length#11 = 5 [phi:display_info_rom::@15->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1217] phi printf_ulong::putc#11 = &cputc [phi:display_info_rom::@15->printf_ulong#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_ulong.putc
    lda #>cputc
    sta.z printf_ulong.putc+1
    // [1217] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:display_info_rom::@15->printf_ulong#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1217] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#1 [phi:display_info_rom::@15->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1052] phi from display_info_rom::@15 to display_info_rom::@16 [phi:display_info_rom::@15->display_info_rom::@16]
    // display_info_rom::@16
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1053] call printf_str
    // [775] phi from display_info_rom::@16 to printf_str [phi:display_info_rom::@16->printf_str]
    // [775] phi printf_str::putc#73 = &cputc [phi:display_info_rom::@16->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = s1 [phi:display_info_rom::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@17
    // if(info_text)
    // [1054] if((char *)0==display_info_rom::info_text#16) goto display_info_rom::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // display_info_rom::@2
    // printf("%-25s", info_text)
    // [1055] printf_string::str#9 = display_info_rom::info_text#16 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1056] call printf_string
    // [784] phi from display_info_rom::@2 to printf_string [phi:display_info_rom::@2->printf_string]
    // [784] phi printf_string::putc#19 = &cputc [phi:display_info_rom::@2->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [784] phi printf_string::str#19 = printf_string::str#9 [phi:display_info_rom::@2->printf_string#1] -- register_copy 
    // [784] phi printf_string::format_justify_left#19 = 1 [phi:display_info_rom::@2->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [784] phi printf_string::format_min_length#19 = $19 [phi:display_info_rom::@2->printf_string#3] -- vbum1=vbuc1 
    lda #$19
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_rom::@1
  __b1:
    // gotoxy(x,y)
    // [1057] gotoxy::x#18 = display_info_rom::x#0 -- vbum1=vbuz2 
    lda.z x
    sta gotoxy.x
    // [1058] gotoxy::y#18 = display_info_rom::y#0 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [1059] call gotoxy
    // [573] phi from display_info_rom::@1 to gotoxy [phi:display_info_rom::@1->gotoxy]
    // [573] phi gotoxy::y#30 = gotoxy::y#18 [phi:display_info_rom::@1->gotoxy#0] -- register_copy 
    // [573] phi gotoxy::x#30 = gotoxy::x#18 [phi:display_info_rom::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_rom::@return
    // }
    // [1060] return 
    rts
  .segment Data
    s: .text "ROM"
    .byte 0
    s4: .text " / "
    .byte 0
}
.segment Code
  // rom_file
// __mem() char * rom_file(__zp($4e) char rom_chip)
rom_file: {
    .label rom_file__0 = $4e
    .label rom_chip = $4e
    // if(rom_chip)
    // [1062] if(0!=rom_file::rom_chip#2) goto rom_file::@1 -- 0_neq_vbuz1_then_la1 
    lda.z rom_chip
    bne __b1
    // [1065] phi from rom_file to rom_file::@return [phi:rom_file->rom_file::@return]
    // [1065] phi rom_file::return#2 = rom_file::file_rom_cx16 [phi:rom_file->rom_file::@return#0] -- pbum1=pbuc1 
    lda #<file_rom_cx16
    sta return
    lda #>file_rom_cx16
    sta return+1
    rts
    // rom_file::@1
  __b1:
    // '0'+rom_chip
    // [1063] rom_file::$0 = '0' + rom_file::rom_chip#2 -- vbuz1=vbuc1_plus_vbuz1 
    lda #'0'
    clc
    adc.z rom_file__0
    sta.z rom_file__0
    // file_rom_card[3] = '0'+rom_chip
    // [1064] *(rom_file::file_rom_card+3) = rom_file::$0 -- _deref_pbuc1=vbuz1 
    sta file_rom_card+3
    // [1065] phi from rom_file::@1 to rom_file::@return [phi:rom_file::@1->rom_file::@return]
    // [1065] phi rom_file::return#2 = rom_file::file_rom_card [phi:rom_file::@1->rom_file::@return#0] -- pbum1=pbuc1 
    lda #<file_rom_card
    sta return
    lda #>file_rom_card
    sta return+1
    // rom_file::@return
    // }
    // [1066] return 
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
// __zp($f4) unsigned long rom_read(char rom_chip, __zp($af) char *file, char info_status, __zp($e1) char brom_bank_start, __zp($65) unsigned long rom_size)
rom_read: {
    .const bank_set_brom1_bank = 0
    .label rom_read__11 = $d1
    .label rom_address = $72
    .label return = $f4
    .label rom_package_read = $f1
    .label brom_bank_start = $e1
    .label ram_address = $69
    .label rom_file_size = $f4
    .label rom_row_current = $5c
    .label y = $ea
    .label bram_bank = $db
    .label file = $af
    .label rom_size = $65
    // unsigned long rom_address = rom_address_from_bank(brom_bank_start)
    // [1068] rom_address_from_bank::rom_bank#0 = rom_read::brom_bank_start#21 -- vbum1=vbuz2 
    lda.z brom_bank_start
    sta rom_address_from_bank.rom_bank
    // [1069] call rom_address_from_bank
    // [2151] phi from rom_read to rom_address_from_bank [phi:rom_read->rom_address_from_bank]
    // [2151] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#0 [phi:rom_read->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(brom_bank_start)
    // [1070] rom_address_from_bank::return#2 = rom_address_from_bank::return#0
    // rom_read::@15
    // [1071] rom_read::rom_address#0 = rom_address_from_bank::return#2
    // rom_read::bank_set_bram1
    // BRAM = bank
    // [1072] BRAM = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z BRAM
    // rom_read::bank_set_brom1
    // BROM = bank
    // [1073] BROM = rom_read::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [1074] phi from rom_read::bank_set_brom1 to rom_read::@13 [phi:rom_read::bank_set_brom1->rom_read::@13]
    // rom_read::@13
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1075] call snprintf_init
    // [770] phi from rom_read::@13 to snprintf_init [phi:rom_read::@13->snprintf_init]
    // [770] phi snprintf_init::s#25 = info_text [phi:rom_read::@13->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1076] phi from rom_read::@13 to rom_read::@16 [phi:rom_read::@13->rom_read::@16]
    // rom_read::@16
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1077] call printf_str
    // [775] phi from rom_read::@16 to printf_str [phi:rom_read::@16->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:rom_read::@16->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = rom_read::s [phi:rom_read::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@17
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1078] printf_string::str#10 = rom_read::file#11 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [1079] call printf_string
    // [784] phi from rom_read::@17 to printf_string [phi:rom_read::@17->printf_string]
    // [784] phi printf_string::putc#19 = &snputc [phi:rom_read::@17->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [784] phi printf_string::str#19 = printf_string::str#10 [phi:rom_read::@17->printf_string#1] -- register_copy 
    // [784] phi printf_string::format_justify_left#19 = 0 [phi:rom_read::@17->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [784] phi printf_string::format_min_length#19 = 0 [phi:rom_read::@17->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [1080] phi from rom_read::@17 to rom_read::@18 [phi:rom_read::@17->rom_read::@18]
    // rom_read::@18
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1081] call printf_str
    // [775] phi from rom_read::@18 to printf_str [phi:rom_read::@18->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:rom_read::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = rom_read::s1 [phi:rom_read::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@19
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1082] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1083] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1085] call display_action_text
    // [993] phi from rom_read::@19 to display_action_text [phi:rom_read::@19->display_action_text]
    // [993] phi display_action_text::info_text#19 = info_text [phi:rom_read::@19->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // rom_read::@20
    // FILE *fp = fopen(file, "r")
    // [1086] fopen::path#3 = rom_read::file#11 -- pbuz1=pbuz2 
    lda.z file
    sta.z fopen.path
    lda.z file+1
    sta.z fopen.path+1
    // [1087] call fopen
    // [1960] phi from rom_read::@20 to fopen [phi:rom_read::@20->fopen]
    // [1960] phi __errno#321 = __errno#106 [phi:rom_read::@20->fopen#0] -- register_copy 
    // [1960] phi fopen::pathtoken#0 = fopen::path#3 [phi:rom_read::@20->fopen#1] -- register_copy 
    jsr fopen
    // FILE *fp = fopen(file, "r")
    // [1088] fopen::return#4 = fopen::return#2
    // rom_read::@21
    // [1089] rom_read::fp#0 = fopen::return#4 -- pssm1=pssz2 
    lda.z fopen.return
    sta fp
    lda.z fopen.return+1
    sta fp+1
    // if (fp)
    // [1090] if((struct $2 *)0==rom_read::fp#0) goto rom_read::@1 -- pssc1_eq_pssm1_then_la1 
    lda fp
    cmp #<0
    bne !+
    lda fp+1
    cmp #>0
    beq __b2
  !:
    // [1091] phi from rom_read::@21 to rom_read::@2 [phi:rom_read::@21->rom_read::@2]
    // rom_read::@2
    // gotoxy(x, y)
    // [1092] call gotoxy
    // [573] phi from rom_read::@2 to gotoxy [phi:rom_read::@2->gotoxy]
    // [573] phi gotoxy::y#30 = PROGRESS_Y [phi:rom_read::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [573] phi gotoxy::x#30 = PROGRESS_X [phi:rom_read::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1093] phi from rom_read::@2 to rom_read::@3 [phi:rom_read::@2->rom_read::@3]
    // [1093] phi rom_read::y#11 = PROGRESS_Y [phi:rom_read::@2->rom_read::@3#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // [1093] phi rom_read::rom_row_current#10 = 0 [phi:rom_read::@2->rom_read::@3#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z rom_row_current
    sta.z rom_row_current+1
    // [1093] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#21 [phi:rom_read::@2->rom_read::@3#2] -- register_copy 
    // [1093] phi rom_read::rom_address#10 = rom_read::rom_address#0 [phi:rom_read::@2->rom_read::@3#3] -- register_copy 
    // [1093] phi rom_read::ram_address#10 = (char *)$6000 [phi:rom_read::@2->rom_read::@3#4] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z ram_address
    lda #>$6000
    sta.z ram_address+1
    // [1093] phi rom_read::bram_bank#10 = 0 [phi:rom_read::@2->rom_read::@3#5] -- vbuz1=vbuc1 
    lda #0
    sta.z bram_bank
    // [1093] phi rom_read::rom_file_size#11 = 0 [phi:rom_read::@2->rom_read::@3#6] -- vduz1=vduc1 
    sta.z rom_file_size
    sta.z rom_file_size+1
    lda #<0>>$10
    sta.z rom_file_size+2
    lda #>0>>$10
    sta.z rom_file_size+3
    // rom_read::@3
  __b3:
    // while (rom_file_size < rom_size)
    // [1094] if(rom_read::rom_file_size#11<rom_read::rom_size#12) goto rom_read::@4 -- vduz1_lt_vduz2_then_la1 
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
    // [1095] fclose::stream#1 = rom_read::fp#0 -- pssz1=pssm2 
    lda fp
    sta.z fclose.stream
    lda fp+1
    sta.z fclose.stream+1
    // [1096] call fclose
    // [2095] phi from rom_read::@7 to fclose [phi:rom_read::@7->fclose]
    // [2095] phi fclose::stream#2 = fclose::stream#1 [phi:rom_read::@7->fclose#0] -- register_copy 
    jsr fclose
    // [1097] phi from rom_read::@7 to rom_read::@1 [phi:rom_read::@7->rom_read::@1]
    // [1097] phi rom_read::return#0 = rom_read::rom_file_size#11 [phi:rom_read::@7->rom_read::@1#0] -- register_copy 
    rts
    // [1097] phi from rom_read::@21 to rom_read::@1 [phi:rom_read::@21->rom_read::@1]
  __b2:
    // [1097] phi rom_read::return#0 = 0 [phi:rom_read::@21->rom_read::@1#0] -- vduz1=vduc1 
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
    // [1098] return 
    rts
    // [1099] phi from rom_read::@3 to rom_read::@4 [phi:rom_read::@3->rom_read::@4]
    // rom_read::@4
  __b4:
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1100] call snprintf_init
    // [770] phi from rom_read::@4 to snprintf_init [phi:rom_read::@4->snprintf_init]
    // [770] phi snprintf_init::s#25 = info_text [phi:rom_read::@4->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1101] phi from rom_read::@4 to rom_read::@22 [phi:rom_read::@4->rom_read::@22]
    // rom_read::@22
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1102] call printf_str
    // [775] phi from rom_read::@22 to printf_str [phi:rom_read::@22->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:rom_read::@22->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = s14 [phi:rom_read::@22->printf_str#1] -- pbuz1=pbuc1 
    lda #<s14
    sta.z printf_str.s
    lda #>s14
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@23
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1103] printf_string::str#11 = rom_read::file#11 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [1104] call printf_string
    // [784] phi from rom_read::@23 to printf_string [phi:rom_read::@23->printf_string]
    // [784] phi printf_string::putc#19 = &snputc [phi:rom_read::@23->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [784] phi printf_string::str#19 = printf_string::str#11 [phi:rom_read::@23->printf_string#1] -- register_copy 
    // [784] phi printf_string::format_justify_left#19 = 0 [phi:rom_read::@23->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [784] phi printf_string::format_min_length#19 = 0 [phi:rom_read::@23->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [1105] phi from rom_read::@23 to rom_read::@24 [phi:rom_read::@23->rom_read::@24]
    // rom_read::@24
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1106] call printf_str
    // [775] phi from rom_read::@24 to printf_str [phi:rom_read::@24->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:rom_read::@24->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = s3 [phi:rom_read::@24->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@25
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1107] printf_ulong::uvalue#2 = rom_read::rom_file_size#11 -- vdum1=vduz2 
    lda.z rom_file_size
    sta printf_ulong.uvalue
    lda.z rom_file_size+1
    sta printf_ulong.uvalue+1
    lda.z rom_file_size+2
    sta printf_ulong.uvalue+2
    lda.z rom_file_size+3
    sta printf_ulong.uvalue+3
    // [1108] call printf_ulong
    // [1217] phi from rom_read::@25 to printf_ulong [phi:rom_read::@25->printf_ulong]
    // [1217] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_read::@25->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1217] phi printf_ulong::format_min_length#11 = 5 [phi:rom_read::@25->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1217] phi printf_ulong::putc#11 = &snputc [phi:rom_read::@25->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1217] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_read::@25->printf_ulong#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1217] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#2 [phi:rom_read::@25->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1109] phi from rom_read::@25 to rom_read::@26 [phi:rom_read::@25->rom_read::@26]
    // rom_read::@26
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1110] call printf_str
    // [775] phi from rom_read::@26 to printf_str [phi:rom_read::@26->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:rom_read::@26->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = s4 [phi:rom_read::@26->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@27
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1111] printf_ulong::uvalue#3 = rom_read::rom_size#12 -- vdum1=vduz2 
    lda.z rom_size
    sta printf_ulong.uvalue
    lda.z rom_size+1
    sta printf_ulong.uvalue+1
    lda.z rom_size+2
    sta printf_ulong.uvalue+2
    lda.z rom_size+3
    sta printf_ulong.uvalue+3
    // [1112] call printf_ulong
    // [1217] phi from rom_read::@27 to printf_ulong [phi:rom_read::@27->printf_ulong]
    // [1217] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_read::@27->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1217] phi printf_ulong::format_min_length#11 = 5 [phi:rom_read::@27->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1217] phi printf_ulong::putc#11 = &snputc [phi:rom_read::@27->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1217] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_read::@27->printf_ulong#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1217] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#3 [phi:rom_read::@27->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1113] phi from rom_read::@27 to rom_read::@28 [phi:rom_read::@27->rom_read::@28]
    // rom_read::@28
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1114] call printf_str
    // [775] phi from rom_read::@28 to printf_str [phi:rom_read::@28->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:rom_read::@28->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = s2 [phi:rom_read::@28->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@29
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1115] printf_uchar::uvalue#5 = rom_read::bram_bank#10 -- vbum1=vbuz2 
    lda.z bram_bank
    sta printf_uchar.uvalue
    // [1116] call printf_uchar
    // [982] phi from rom_read::@29 to printf_uchar [phi:rom_read::@29->printf_uchar]
    // [982] phi printf_uchar::format_zero_padding#11 = 1 [phi:rom_read::@29->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [982] phi printf_uchar::format_min_length#11 = 2 [phi:rom_read::@29->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [982] phi printf_uchar::putc#11 = &snputc [phi:rom_read::@29->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [982] phi printf_uchar::format_radix#11 = HEXADECIMAL [phi:rom_read::@29->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [982] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#5 [phi:rom_read::@29->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1117] phi from rom_read::@29 to rom_read::@30 [phi:rom_read::@29->rom_read::@30]
    // rom_read::@30
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1118] call printf_str
    // [775] phi from rom_read::@30 to printf_str [phi:rom_read::@30->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:rom_read::@30->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = s3 [phi:rom_read::@30->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@31
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1119] printf_uint::uvalue#13 = (unsigned int)rom_read::ram_address#10 -- vwum1=vwuz2 
    lda.z ram_address
    sta printf_uint.uvalue
    lda.z ram_address+1
    sta printf_uint.uvalue+1
    // [1120] call printf_uint
    // [809] phi from rom_read::@31 to printf_uint [phi:rom_read::@31->printf_uint]
    // [809] phi printf_uint::format_zero_padding#18 = 1 [phi:rom_read::@31->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [809] phi printf_uint::format_min_length#18 = 4 [phi:rom_read::@31->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [809] phi printf_uint::putc#18 = &snputc [phi:rom_read::@31->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [809] phi printf_uint::format_radix#18 = HEXADECIMAL [phi:rom_read::@31->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [809] phi printf_uint::uvalue#18 = printf_uint::uvalue#13 [phi:rom_read::@31->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1121] phi from rom_read::@31 to rom_read::@32 [phi:rom_read::@31->rom_read::@32]
    // rom_read::@32
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1122] call printf_str
    // [775] phi from rom_read::@32 to printf_str [phi:rom_read::@32->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:rom_read::@32->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = s7 [phi:rom_read::@32->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@33
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1123] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1124] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1126] call display_action_text
    // [993] phi from rom_read::@33 to display_action_text [phi:rom_read::@33->display_action_text]
    // [993] phi display_action_text::info_text#19 = info_text [phi:rom_read::@33->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // rom_read::@34
    // rom_address % 0x04000
    // [1127] rom_read::$11 = rom_read::rom_address#10 & $4000-1 -- vduz1=vduz2_band_vduc1 
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
    // [1128] if(0!=rom_read::$11) goto rom_read::@5 -- 0_neq_vduz1_then_la1 
    lda.z rom_read__11
    ora.z rom_read__11+1
    ora.z rom_read__11+2
    ora.z rom_read__11+3
    bne __b5
    // rom_read::@10
    // brom_bank_start++;
    // [1129] rom_read::brom_bank_start#0 = ++ rom_read::brom_bank_start#10 -- vbuz1=_inc_vbuz1 
    inc.z brom_bank_start
    // [1130] phi from rom_read::@10 rom_read::@34 to rom_read::@5 [phi:rom_read::@10/rom_read::@34->rom_read::@5]
    // [1130] phi rom_read::brom_bank_start#20 = rom_read::brom_bank_start#0 [phi:rom_read::@10/rom_read::@34->rom_read::@5#0] -- register_copy 
    // rom_read::@5
  __b5:
    // rom_read::bank_set_bram2
    // BRAM = bank
    // [1131] BRAM = rom_read::bram_bank#10 -- vbuz1=vbuz2 
    lda.z bram_bank
    sta.z BRAM
    // rom_read::@14
    // unsigned int rom_package_read = fgets(ram_address, ROM_PROGRESS_CELL, fp)
    // [1132] fgets::ptr#3 = rom_read::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z fgets.ptr
    lda.z ram_address+1
    sta.z fgets.ptr+1
    // [1133] fgets::stream#1 = rom_read::fp#0 -- pssz1=pssm2 
    lda fp
    sta.z fgets.stream
    lda fp+1
    sta.z fgets.stream+1
    // [1134] call fgets
    // [2041] phi from rom_read::@14 to fgets [phi:rom_read::@14->fgets]
    // [2041] phi fgets::ptr#12 = fgets::ptr#3 [phi:rom_read::@14->fgets#0] -- register_copy 
    // [2041] phi fgets::size#10 = ROM_PROGRESS_CELL [phi:rom_read::@14->fgets#1] -- vwum1=vwuc1 
    lda #<ROM_PROGRESS_CELL
    sta fgets.size
    lda #>ROM_PROGRESS_CELL
    sta fgets.size+1
    // [2041] phi fgets::stream#2 = fgets::stream#1 [phi:rom_read::@14->fgets#2] -- register_copy 
    jsr fgets
    // unsigned int rom_package_read = fgets(ram_address, ROM_PROGRESS_CELL, fp)
    // [1135] fgets::return#6 = fgets::return#1
    // rom_read::@35
    // [1136] rom_read::rom_package_read#0 = fgets::return#6 -- vwuz1=vwum2 
    lda fgets.return
    sta.z rom_package_read
    lda fgets.return+1
    sta.z rom_package_read+1
    // if (!rom_package_read)
    // [1137] if(0!=rom_read::rom_package_read#0) goto rom_read::@6 -- 0_neq_vwuz1_then_la1 
    lda.z rom_package_read
    ora.z rom_package_read+1
    bne __b6
    jmp __b7
    // rom_read::@6
  __b6:
    // if (rom_row_current == ROM_PROGRESS_ROW)
    // [1138] if(rom_read::rom_row_current#10!=ROM_PROGRESS_ROW) goto rom_read::@8 -- vwuz1_neq_vwuc1_then_la1 
    lda.z rom_row_current+1
    cmp #>ROM_PROGRESS_ROW
    bne __b8
    lda.z rom_row_current
    cmp #<ROM_PROGRESS_ROW
    bne __b8
    // rom_read::@11
    // gotoxy(x, ++y);
    // [1139] rom_read::y#1 = ++ rom_read::y#11 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [1140] gotoxy::y#25 = rom_read::y#1 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [1141] call gotoxy
    // [573] phi from rom_read::@11 to gotoxy [phi:rom_read::@11->gotoxy]
    // [573] phi gotoxy::y#30 = gotoxy::y#25 [phi:rom_read::@11->gotoxy#0] -- register_copy 
    // [573] phi gotoxy::x#30 = PROGRESS_X [phi:rom_read::@11->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1142] phi from rom_read::@11 to rom_read::@8 [phi:rom_read::@11->rom_read::@8]
    // [1142] phi rom_read::y#36 = rom_read::y#1 [phi:rom_read::@11->rom_read::@8#0] -- register_copy 
    // [1142] phi rom_read::rom_row_current#4 = 0 [phi:rom_read::@11->rom_read::@8#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z rom_row_current
    sta.z rom_row_current+1
    // [1142] phi from rom_read::@6 to rom_read::@8 [phi:rom_read::@6->rom_read::@8]
    // [1142] phi rom_read::y#36 = rom_read::y#11 [phi:rom_read::@6->rom_read::@8#0] -- register_copy 
    // [1142] phi rom_read::rom_row_current#4 = rom_read::rom_row_current#10 [phi:rom_read::@6->rom_read::@8#1] -- register_copy 
    // rom_read::@8
  __b8:
    // cputc('.')
    // [1143] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [1144] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // ram_address += rom_package_read
    // [1146] rom_read::ram_address#1 = rom_read::ram_address#10 + rom_read::rom_package_read#0 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z ram_address
    adc.z rom_package_read
    sta.z ram_address
    lda.z ram_address+1
    adc.z rom_package_read+1
    sta.z ram_address+1
    // rom_address += rom_package_read
    // [1147] rom_read::rom_address#1 = rom_read::rom_address#10 + rom_read::rom_package_read#0 -- vduz1=vduz1_plus_vwuz2 
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
    // [1148] rom_read::rom_file_size#1 = rom_read::rom_file_size#11 + rom_read::rom_package_read#0 -- vduz1=vduz1_plus_vwuz2 
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
    // [1149] rom_read::rom_row_current#1 = rom_read::rom_row_current#4 + rom_read::rom_package_read#0 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z rom_row_current
    adc.z rom_package_read
    sta.z rom_row_current
    lda.z rom_row_current+1
    adc.z rom_package_read+1
    sta.z rom_row_current+1
    // if (ram_address == (ram_ptr_t)BRAM_HIGH)
    // [1150] if(rom_read::ram_address#1!=(char *)$c000) goto rom_read::@9 -- pbuz1_neq_pbuc1_then_la1 
    lda.z ram_address+1
    cmp #>$c000
    bne __b9
    lda.z ram_address
    cmp #<$c000
    bne __b9
    // rom_read::@12
    // bram_bank++;
    // [1151] rom_read::bram_bank#1 = ++ rom_read::bram_bank#10 -- vbuz1=_inc_vbuz1 
    inc.z bram_bank
    // [1152] phi from rom_read::@12 to rom_read::@9 [phi:rom_read::@12->rom_read::@9]
    // [1152] phi rom_read::bram_bank#30 = rom_read::bram_bank#1 [phi:rom_read::@12->rom_read::@9#0] -- register_copy 
    // [1152] phi rom_read::ram_address#7 = (char *)$a000 [phi:rom_read::@12->rom_read::@9#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1152] phi from rom_read::@8 to rom_read::@9 [phi:rom_read::@8->rom_read::@9]
    // [1152] phi rom_read::bram_bank#30 = rom_read::bram_bank#10 [phi:rom_read::@8->rom_read::@9#0] -- register_copy 
    // [1152] phi rom_read::ram_address#7 = rom_read::ram_address#1 [phi:rom_read::@8->rom_read::@9#1] -- register_copy 
    // rom_read::@9
  __b9:
    // if (ram_address == (ram_ptr_t)RAM_HIGH)
    // [1153] if(rom_read::ram_address#7!=(char *)$8000) goto rom_read::@36 -- pbuz1_neq_pbuc1_then_la1 
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
    // [1093] phi from rom_read::@9 to rom_read::@3 [phi:rom_read::@9->rom_read::@3]
    // [1093] phi rom_read::y#11 = rom_read::y#36 [phi:rom_read::@9->rom_read::@3#0] -- register_copy 
    // [1093] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#1 [phi:rom_read::@9->rom_read::@3#1] -- register_copy 
    // [1093] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#20 [phi:rom_read::@9->rom_read::@3#2] -- register_copy 
    // [1093] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@9->rom_read::@3#3] -- register_copy 
    // [1093] phi rom_read::ram_address#10 = (char *)$a000 [phi:rom_read::@9->rom_read::@3#4] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1093] phi rom_read::bram_bank#10 = 1 [phi:rom_read::@9->rom_read::@3#5] -- vbuz1=vbuc1 
    lda #1
    sta.z bram_bank
    // [1093] phi rom_read::rom_file_size#11 = rom_read::rom_file_size#1 [phi:rom_read::@9->rom_read::@3#6] -- register_copy 
    jmp __b3
    // [1154] phi from rom_read::@9 to rom_read::@36 [phi:rom_read::@9->rom_read::@36]
    // rom_read::@36
    // [1093] phi from rom_read::@36 to rom_read::@3 [phi:rom_read::@36->rom_read::@3]
    // [1093] phi rom_read::y#11 = rom_read::y#36 [phi:rom_read::@36->rom_read::@3#0] -- register_copy 
    // [1093] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#1 [phi:rom_read::@36->rom_read::@3#1] -- register_copy 
    // [1093] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#20 [phi:rom_read::@36->rom_read::@3#2] -- register_copy 
    // [1093] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@36->rom_read::@3#3] -- register_copy 
    // [1093] phi rom_read::ram_address#10 = rom_read::ram_address#7 [phi:rom_read::@36->rom_read::@3#4] -- register_copy 
    // [1093] phi rom_read::bram_bank#10 = rom_read::bram_bank#30 [phi:rom_read::@36->rom_read::@3#5] -- register_copy 
    // [1093] phi rom_read::rom_file_size#11 = rom_read::rom_file_size#1 [phi:rom_read::@36->rom_read::@3#6] -- register_copy 
  .segment Data
    s: .text "Opening "
    .byte 0
    s1: .text " from SD card ..."
    .byte 0
    .label fp = smc_flash.smc_bootloader_not_activated1
}
.segment Code
  // rom_verify
// __zp($3d) unsigned long rom_verify(__zp($42) char rom_chip, __mem() char rom_bank_start, __mem() unsigned long file_size)
rom_verify: {
    .label rom_verify__16 = $63
    .label rom_address = $5e
    .label equal_bytes = $63
    .label ram_address = $36
    .label bram_bank = $f3
    .label rom_different_bytes = $3d
    .label rom_chip = $42
    .label return = $3d
    .label progress_row_current = $eb
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [1155] rom_address_from_bank::rom_bank#1 = rom_verify::rom_bank_start#0
    // [1156] call rom_address_from_bank
    // [2151] phi from rom_verify to rom_address_from_bank [phi:rom_verify->rom_address_from_bank]
    // [2151] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#1 [phi:rom_verify->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [1157] rom_address_from_bank::return#3 = rom_address_from_bank::return#0 -- vduz1=vduz2 
    lda.z rom_address_from_bank.return
    sta.z rom_address_from_bank.return_1
    lda.z rom_address_from_bank.return+1
    sta.z rom_address_from_bank.return_1+1
    lda.z rom_address_from_bank.return+2
    sta.z rom_address_from_bank.return_1+2
    lda.z rom_address_from_bank.return+3
    sta.z rom_address_from_bank.return_1+3
    // rom_verify::@11
    // [1158] rom_verify::rom_address#0 = rom_address_from_bank::return#3
    // unsigned long rom_boundary = rom_address + file_size
    // [1159] rom_verify::rom_boundary#0 = rom_verify::rom_address#0 + rom_verify::file_size#0 -- vdum1=vduz2_plus_vdum1 
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
    // [1160] display_info_rom::rom_chip#1 = rom_verify::rom_chip#0
    // [1161] call display_info_rom
    // [1016] phi from rom_verify::@11 to display_info_rom [phi:rom_verify::@11->display_info_rom]
    // [1016] phi display_info_rom::info_text#16 = rom_verify::info_text [phi:rom_verify::@11->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_rom.info_text
    lda #>info_text
    sta.z display_info_rom.info_text+1
    // [1016] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#1 [phi:rom_verify::@11->display_info_rom#1] -- register_copy 
    // [1016] phi display_info_rom::info_status#16 = STATUS_COMPARING [phi:rom_verify::@11->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_COMPARING
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // [1162] phi from rom_verify::@11 to rom_verify::@12 [phi:rom_verify::@11->rom_verify::@12]
    // rom_verify::@12
    // gotoxy(x, y)
    // [1163] call gotoxy
    // [573] phi from rom_verify::@12 to gotoxy [phi:rom_verify::@12->gotoxy]
    // [573] phi gotoxy::y#30 = PROGRESS_Y [phi:rom_verify::@12->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [573] phi gotoxy::x#30 = PROGRESS_X [phi:rom_verify::@12->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1164] phi from rom_verify::@12 to rom_verify::@1 [phi:rom_verify::@12->rom_verify::@1]
    // [1164] phi rom_verify::y#3 = PROGRESS_Y [phi:rom_verify::@12->rom_verify::@1#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1164] phi rom_verify::progress_row_current#3 = 0 [phi:rom_verify::@12->rom_verify::@1#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z progress_row_current
    sta.z progress_row_current+1
    // [1164] phi rom_verify::rom_different_bytes#11 = 0 [phi:rom_verify::@12->rom_verify::@1#2] -- vduz1=vduc1 
    sta.z rom_different_bytes
    sta.z rom_different_bytes+1
    lda #<0>>$10
    sta.z rom_different_bytes+2
    lda #>0>>$10
    sta.z rom_different_bytes+3
    // [1164] phi rom_verify::ram_address#10 = (char *)$6000 [phi:rom_verify::@12->rom_verify::@1#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z ram_address
    lda #>$6000
    sta.z ram_address+1
    // [1164] phi rom_verify::bram_bank#11 = 0 [phi:rom_verify::@12->rom_verify::@1#4] -- vbuz1=vbuc1 
    lda #0
    sta.z bram_bank
    // [1164] phi rom_verify::rom_address#12 = rom_verify::rom_address#0 [phi:rom_verify::@12->rom_verify::@1#5] -- register_copy 
    // rom_verify::@1
  __b1:
    // while (rom_address < rom_boundary)
    // [1165] if(rom_verify::rom_address#12<rom_verify::rom_boundary#0) goto rom_verify::@2 -- vduz1_lt_vdum2_then_la1 
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
    // [1166] return 
    rts
    // rom_verify::@2
  __b2:
    // unsigned int equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1167] rom_compare::bank_ram#0 = rom_verify::bram_bank#11
    // [1168] rom_compare::ptr_ram#1 = rom_verify::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_compare.ptr_ram
    lda.z ram_address+1
    sta.z rom_compare.ptr_ram+1
    // [1169] rom_compare::rom_compare_address#0 = rom_verify::rom_address#12 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_compare.rom_compare_address
    lda.z rom_address+1
    sta.z rom_compare.rom_compare_address+1
    lda.z rom_address+2
    sta.z rom_compare.rom_compare_address+2
    lda.z rom_address+3
    sta.z rom_compare.rom_compare_address+3
    // [1170] call rom_compare
  // {asm{.byte $db}}
    // [2155] phi from rom_verify::@2 to rom_compare [phi:rom_verify::@2->rom_compare]
    // [2155] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#1 [phi:rom_verify::@2->rom_compare#0] -- register_copy 
    // [2155] phi rom_compare::rom_compare_size#11 = ROM_PROGRESS_CELL [phi:rom_verify::@2->rom_compare#1] -- vwuz1=vwuc1 
    lda #<ROM_PROGRESS_CELL
    sta.z rom_compare.rom_compare_size
    lda #>ROM_PROGRESS_CELL
    sta.z rom_compare.rom_compare_size+1
    // [2155] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#0 [phi:rom_verify::@2->rom_compare#2] -- register_copy 
    // [2155] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#0 [phi:rom_verify::@2->rom_compare#3] -- vbum1=vbuz2 
    lda.z rom_compare.bank_ram
    sta rom_compare.bank_set_bram1_bank
    jsr rom_compare
    // unsigned int equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1171] rom_compare::return#2 = rom_compare::equal_bytes#2
    // rom_verify::@13
    // [1172] rom_verify::equal_bytes#0 = rom_compare::return#2
    // if (progress_row_current == ROM_PROGRESS_ROW)
    // [1173] if(rom_verify::progress_row_current#3!=ROM_PROGRESS_ROW) goto rom_verify::@3 -- vwuz1_neq_vwuc1_then_la1 
    lda.z progress_row_current+1
    cmp #>ROM_PROGRESS_ROW
    bne __b3
    lda.z progress_row_current
    cmp #<ROM_PROGRESS_ROW
    bne __b3
    // rom_verify::@8
    // gotoxy(x, ++y);
    // [1174] rom_verify::y#1 = ++ rom_verify::y#3 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [1175] gotoxy::y#27 = rom_verify::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1176] call gotoxy
    // [573] phi from rom_verify::@8 to gotoxy [phi:rom_verify::@8->gotoxy]
    // [573] phi gotoxy::y#30 = gotoxy::y#27 [phi:rom_verify::@8->gotoxy#0] -- register_copy 
    // [573] phi gotoxy::x#30 = PROGRESS_X [phi:rom_verify::@8->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1177] phi from rom_verify::@8 to rom_verify::@3 [phi:rom_verify::@8->rom_verify::@3]
    // [1177] phi rom_verify::y#10 = rom_verify::y#1 [phi:rom_verify::@8->rom_verify::@3#0] -- register_copy 
    // [1177] phi rom_verify::progress_row_current#4 = 0 [phi:rom_verify::@8->rom_verify::@3#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z progress_row_current
    sta.z progress_row_current+1
    // [1177] phi from rom_verify::@13 to rom_verify::@3 [phi:rom_verify::@13->rom_verify::@3]
    // [1177] phi rom_verify::y#10 = rom_verify::y#3 [phi:rom_verify::@13->rom_verify::@3#0] -- register_copy 
    // [1177] phi rom_verify::progress_row_current#4 = rom_verify::progress_row_current#3 [phi:rom_verify::@13->rom_verify::@3#1] -- register_copy 
    // rom_verify::@3
  __b3:
    // if (equal_bytes != ROM_PROGRESS_CELL)
    // [1178] if(rom_verify::equal_bytes#0!=ROM_PROGRESS_CELL) goto rom_verify::@4 -- vwuz1_neq_vwuc1_then_la1 
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
    // [1179] stackpush(char) = '=' -- _stackpushbyte_=vbuc1 
    lda #'='
    pha
    // [1180] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // rom_verify::@5
  __b5:
    // ram_address += ROM_PROGRESS_CELL
    // [1182] rom_verify::ram_address#1 = rom_verify::ram_address#10 + ROM_PROGRESS_CELL -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address
    clc
    adc #<ROM_PROGRESS_CELL
    sta.z ram_address
    lda.z ram_address+1
    adc #>ROM_PROGRESS_CELL
    sta.z ram_address+1
    // rom_address += ROM_PROGRESS_CELL
    // [1183] rom_verify::rom_address#1 = rom_verify::rom_address#12 + ROM_PROGRESS_CELL -- vduz1=vduz1_plus_vwuc1 
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
    // [1184] rom_verify::progress_row_current#11 = rom_verify::progress_row_current#4 + ROM_PROGRESS_CELL -- vwuz1=vwuz1_plus_vwuc1 
    lda.z progress_row_current
    clc
    adc #<ROM_PROGRESS_CELL
    sta.z progress_row_current
    lda.z progress_row_current+1
    adc #>ROM_PROGRESS_CELL
    sta.z progress_row_current+1
    // if (ram_address == BRAM_HIGH)
    // [1185] if(rom_verify::ram_address#1!=$c000) goto rom_verify::@6 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address+1
    cmp #>$c000
    bne __b6
    lda.z ram_address
    cmp #<$c000
    bne __b6
    // rom_verify::@10
    // bram_bank++;
    // [1186] rom_verify::bram_bank#1 = ++ rom_verify::bram_bank#11 -- vbuz1=_inc_vbuz1 
    inc.z bram_bank
    // [1187] phi from rom_verify::@10 to rom_verify::@6 [phi:rom_verify::@10->rom_verify::@6]
    // [1187] phi rom_verify::bram_bank#24 = rom_verify::bram_bank#1 [phi:rom_verify::@10->rom_verify::@6#0] -- register_copy 
    // [1187] phi rom_verify::ram_address#6 = (char *)$a000 [phi:rom_verify::@10->rom_verify::@6#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1187] phi from rom_verify::@5 to rom_verify::@6 [phi:rom_verify::@5->rom_verify::@6]
    // [1187] phi rom_verify::bram_bank#24 = rom_verify::bram_bank#11 [phi:rom_verify::@5->rom_verify::@6#0] -- register_copy 
    // [1187] phi rom_verify::ram_address#6 = rom_verify::ram_address#1 [phi:rom_verify::@5->rom_verify::@6#1] -- register_copy 
    // rom_verify::@6
  __b6:
    // if (ram_address == RAM_HIGH)
    // [1188] if(rom_verify::ram_address#6!=$8000) goto rom_verify::@23 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address+1
    cmp #>$8000
    bne __b7
    lda.z ram_address
    cmp #<$8000
    bne __b7
    // [1190] phi from rom_verify::@6 to rom_verify::@7 [phi:rom_verify::@6->rom_verify::@7]
    // [1190] phi rom_verify::ram_address#11 = (char *)$a000 [phi:rom_verify::@6->rom_verify::@7#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1190] phi rom_verify::bram_bank#10 = 1 [phi:rom_verify::@6->rom_verify::@7#1] -- vbuz1=vbuc1 
    lda #1
    sta.z bram_bank
    // [1189] phi from rom_verify::@6 to rom_verify::@23 [phi:rom_verify::@6->rom_verify::@23]
    // rom_verify::@23
    // [1190] phi from rom_verify::@23 to rom_verify::@7 [phi:rom_verify::@23->rom_verify::@7]
    // [1190] phi rom_verify::ram_address#11 = rom_verify::ram_address#6 [phi:rom_verify::@23->rom_verify::@7#0] -- register_copy 
    // [1190] phi rom_verify::bram_bank#10 = rom_verify::bram_bank#24 [phi:rom_verify::@23->rom_verify::@7#1] -- register_copy 
    // rom_verify::@7
  __b7:
    // ROM_PROGRESS_CELL - equal_bytes
    // [1191] rom_verify::$16 = ROM_PROGRESS_CELL - rom_verify::equal_bytes#0 -- vwuz1=vwuc1_minus_vwuz1 
    lda #<ROM_PROGRESS_CELL
    sec
    sbc.z rom_verify__16
    sta.z rom_verify__16
    lda #>ROM_PROGRESS_CELL
    sbc.z rom_verify__16+1
    sta.z rom_verify__16+1
    // rom_different_bytes += (ROM_PROGRESS_CELL - equal_bytes)
    // [1192] rom_verify::rom_different_bytes#1 = rom_verify::rom_different_bytes#11 + rom_verify::$16 -- vduz1=vduz1_plus_vwuz2 
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
    // [1193] call snprintf_init
    // [770] phi from rom_verify::@7 to snprintf_init [phi:rom_verify::@7->snprintf_init]
    // [770] phi snprintf_init::s#25 = info_text [phi:rom_verify::@7->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1194] phi from rom_verify::@7 to rom_verify::@14 [phi:rom_verify::@7->rom_verify::@14]
    // rom_verify::@14
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1195] call printf_str
    // [775] phi from rom_verify::@14 to printf_str [phi:rom_verify::@14->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:rom_verify::@14->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = rom_verify::s [phi:rom_verify::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@15
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1196] printf_ulong::uvalue#4 = rom_verify::rom_different_bytes#1 -- vdum1=vduz2 
    lda.z rom_different_bytes
    sta printf_ulong.uvalue
    lda.z rom_different_bytes+1
    sta printf_ulong.uvalue+1
    lda.z rom_different_bytes+2
    sta printf_ulong.uvalue+2
    lda.z rom_different_bytes+3
    sta printf_ulong.uvalue+3
    // [1197] call printf_ulong
    // [1217] phi from rom_verify::@15 to printf_ulong [phi:rom_verify::@15->printf_ulong]
    // [1217] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_verify::@15->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1217] phi printf_ulong::format_min_length#11 = 5 [phi:rom_verify::@15->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1217] phi printf_ulong::putc#11 = &snputc [phi:rom_verify::@15->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1217] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_verify::@15->printf_ulong#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1217] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#4 [phi:rom_verify::@15->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1198] phi from rom_verify::@15 to rom_verify::@16 [phi:rom_verify::@15->rom_verify::@16]
    // rom_verify::@16
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1199] call printf_str
    // [775] phi from rom_verify::@16 to printf_str [phi:rom_verify::@16->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:rom_verify::@16->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = rom_verify::s1 [phi:rom_verify::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@17
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1200] printf_uchar::uvalue#6 = rom_verify::bram_bank#10 -- vbum1=vbuz2 
    lda.z bram_bank
    sta printf_uchar.uvalue
    // [1201] call printf_uchar
    // [982] phi from rom_verify::@17 to printf_uchar [phi:rom_verify::@17->printf_uchar]
    // [982] phi printf_uchar::format_zero_padding#11 = 1 [phi:rom_verify::@17->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [982] phi printf_uchar::format_min_length#11 = 2 [phi:rom_verify::@17->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [982] phi printf_uchar::putc#11 = &snputc [phi:rom_verify::@17->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [982] phi printf_uchar::format_radix#11 = HEXADECIMAL [phi:rom_verify::@17->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [982] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#6 [phi:rom_verify::@17->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1202] phi from rom_verify::@17 to rom_verify::@18 [phi:rom_verify::@17->rom_verify::@18]
    // rom_verify::@18
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1203] call printf_str
    // [775] phi from rom_verify::@18 to printf_str [phi:rom_verify::@18->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:rom_verify::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = s3 [phi:rom_verify::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s3
    sta.z printf_str.s
    lda #>@s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@19
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1204] printf_uint::uvalue#14 = (unsigned int)rom_verify::ram_address#11 -- vwum1=vwuz2 
    lda.z ram_address
    sta printf_uint.uvalue
    lda.z ram_address+1
    sta printf_uint.uvalue+1
    // [1205] call printf_uint
    // [809] phi from rom_verify::@19 to printf_uint [phi:rom_verify::@19->printf_uint]
    // [809] phi printf_uint::format_zero_padding#18 = 1 [phi:rom_verify::@19->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [809] phi printf_uint::format_min_length#18 = 4 [phi:rom_verify::@19->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [809] phi printf_uint::putc#18 = &snputc [phi:rom_verify::@19->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [809] phi printf_uint::format_radix#18 = HEXADECIMAL [phi:rom_verify::@19->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [809] phi printf_uint::uvalue#18 = printf_uint::uvalue#14 [phi:rom_verify::@19->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1206] phi from rom_verify::@19 to rom_verify::@20 [phi:rom_verify::@19->rom_verify::@20]
    // rom_verify::@20
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1207] call printf_str
    // [775] phi from rom_verify::@20 to printf_str [phi:rom_verify::@20->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:rom_verify::@20->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = rom_verify::s3 [phi:rom_verify::@20->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@21
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1208] printf_ulong::uvalue#5 = rom_verify::rom_address#1 -- vdum1=vduz2 
    lda.z rom_address
    sta printf_ulong.uvalue
    lda.z rom_address+1
    sta printf_ulong.uvalue+1
    lda.z rom_address+2
    sta printf_ulong.uvalue+2
    lda.z rom_address+3
    sta printf_ulong.uvalue+3
    // [1209] call printf_ulong
    // [1217] phi from rom_verify::@21 to printf_ulong [phi:rom_verify::@21->printf_ulong]
    // [1217] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_verify::@21->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1217] phi printf_ulong::format_min_length#11 = 5 [phi:rom_verify::@21->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1217] phi printf_ulong::putc#11 = &snputc [phi:rom_verify::@21->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1217] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_verify::@21->printf_ulong#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1217] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#5 [phi:rom_verify::@21->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // rom_verify::@22
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1210] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1211] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1213] call display_action_text
    // [993] phi from rom_verify::@22 to display_action_text [phi:rom_verify::@22->display_action_text]
    // [993] phi display_action_text::info_text#19 = info_text [phi:rom_verify::@22->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1164] phi from rom_verify::@22 to rom_verify::@1 [phi:rom_verify::@22->rom_verify::@1]
    // [1164] phi rom_verify::y#3 = rom_verify::y#10 [phi:rom_verify::@22->rom_verify::@1#0] -- register_copy 
    // [1164] phi rom_verify::progress_row_current#3 = rom_verify::progress_row_current#11 [phi:rom_verify::@22->rom_verify::@1#1] -- register_copy 
    // [1164] phi rom_verify::rom_different_bytes#11 = rom_verify::rom_different_bytes#1 [phi:rom_verify::@22->rom_verify::@1#2] -- register_copy 
    // [1164] phi rom_verify::ram_address#10 = rom_verify::ram_address#11 [phi:rom_verify::@22->rom_verify::@1#3] -- register_copy 
    // [1164] phi rom_verify::bram_bank#11 = rom_verify::bram_bank#10 [phi:rom_verify::@22->rom_verify::@1#4] -- register_copy 
    // [1164] phi rom_verify::rom_address#12 = rom_verify::rom_address#1 [phi:rom_verify::@22->rom_verify::@1#5] -- register_copy 
    jmp __b1
    // rom_verify::@4
  __b4:
    // cputc('*')
    // [1214] stackpush(char) = '*' -- _stackpushbyte_=vbuc1 
    lda #'*'
    pha
    // [1215] callexecute cputc  -- call_vprc1 
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
    .label y = main.check_status_smc3_main__0
    .label rom_bank_start = rom_detect.rom_detect__4
    .label file_size = rom_flash.rom_flash__29
}
.segment Code
  // printf_ulong
// Print an unsigned int using a specific format
// void printf_ulong(__zp($b5) void (*putc)(char), __mem() unsigned long uvalue, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, __mem() char format_radix)
printf_ulong: {
    .label putc = $b5
    // printf_ulong::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1218] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // ultoa(uvalue, printf_buffer.digits, format.radix)
    // [1219] ultoa::value#1 = printf_ulong::uvalue#11
    // [1220] ultoa::radix#0 = printf_ulong::format_radix#11
    // [1221] call ultoa
    // Format number into buffer
    jsr ultoa
    // printf_ulong::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1222] printf_number_buffer::putc#0 = printf_ulong::putc#11
    // [1223] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [1224] printf_number_buffer::format_min_length#0 = printf_ulong::format_min_length#11
    // [1225] printf_number_buffer::format_zero_padding#0 = printf_ulong::format_zero_padding#11
    // [1226] call printf_number_buffer
  // Print using format
    // [1929] phi from printf_ulong::@2 to printf_number_buffer [phi:printf_ulong::@2->printf_number_buffer]
    // [1929] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#0 [phi:printf_ulong::@2->printf_number_buffer#0] -- register_copy 
    // [1929] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_ulong::@2->printf_number_buffer#1] -- register_copy 
    // [1929] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#0 [phi:printf_ulong::@2->printf_number_buffer#2] -- register_copy 
    // [1929] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#0 [phi:printf_ulong::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_ulong::@return
    // }
    // [1227] return 
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
// __zp($f8) unsigned long rom_flash(__mem() char rom_chip, __mem() char rom_bank_start, __mem() unsigned long file_size)
rom_flash: {
    .label equal_bytes = $63
    .label ram_address_sector = $b3
    .label equal_bytes_1 = $d6
    .label retries = $ed
    .label flash_errors_sector = $cb
    .label ram_address = $7a
    .label rom_address = $d1
    .label x = $cf
    .label flash_errors = $f8
    .label bram_bank_sector = $d5
    .label y_sector = $ef
    .label return = $f8
    // display_action_progress("Flashing ... (-) equal, (+) flashed, (!) error.")
    // [1229] call display_action_progress
  // Now we compare the RAM with the actual ROM contents.
    // [667] phi from rom_flash to display_action_progress [phi:rom_flash->display_action_progress]
    // [667] phi display_action_progress::info_text#14 = rom_flash::info_text [phi:rom_flash->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // rom_flash::@19
    // unsigned long rom_address_sector = rom_address_from_bank(rom_bank_start)
    // [1230] rom_address_from_bank::rom_bank#2 = rom_flash::rom_bank_start#0
    // [1231] call rom_address_from_bank
    // [2151] phi from rom_flash::@19 to rom_address_from_bank [phi:rom_flash::@19->rom_address_from_bank]
    // [2151] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#2 [phi:rom_flash::@19->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address_sector = rom_address_from_bank(rom_bank_start)
    // [1232] rom_address_from_bank::return#4 = rom_address_from_bank::return#0 -- vdum1=vduz2 
    lda.z rom_address_from_bank.return
    sta rom_address_from_bank.return_2
    lda.z rom_address_from_bank.return+1
    sta rom_address_from_bank.return_2+1
    lda.z rom_address_from_bank.return+2
    sta rom_address_from_bank.return_2+2
    lda.z rom_address_from_bank.return+3
    sta rom_address_from_bank.return_2+3
    // rom_flash::@20
    // [1233] rom_flash::rom_address_sector#0 = rom_address_from_bank::return#4
    // unsigned long rom_boundary = rom_address_sector + file_size
    // [1234] rom_flash::rom_boundary#0 = rom_flash::rom_address_sector#0 + rom_flash::file_size#0 -- vdum1=vdum2_plus_vdum3 
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
    // [1235] display_info_rom::rom_chip#2 = rom_flash::rom_chip#0 -- vbuz1=vbum2 
    lda rom_chip
    sta.z display_info_rom.rom_chip
    // [1236] call display_info_rom
    // [1016] phi from rom_flash::@20 to display_info_rom [phi:rom_flash::@20->display_info_rom]
    // [1016] phi display_info_rom::info_text#16 = rom_flash::info_text1 [phi:rom_flash::@20->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_rom.info_text
    lda #>info_text1
    sta.z display_info_rom.info_text+1
    // [1016] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#2 [phi:rom_flash::@20->display_info_rom#1] -- register_copy 
    // [1016] phi display_info_rom::info_status#16 = STATUS_FLASHING [phi:rom_flash::@20->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHING
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // [1237] phi from rom_flash::@20 to rom_flash::@1 [phi:rom_flash::@20->rom_flash::@1]
    // [1237] phi rom_flash::y_sector#13 = PROGRESS_Y [phi:rom_flash::@20->rom_flash::@1#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y_sector
    // [1237] phi rom_flash::x_sector#10 = PROGRESS_X [phi:rom_flash::@20->rom_flash::@1#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [1237] phi rom_flash::flash_errors#10 = 0 [phi:rom_flash::@20->rom_flash::@1#2] -- vduz1=vduc1 
    lda #<0
    sta.z flash_errors
    sta.z flash_errors+1
    lda #<0>>$10
    sta.z flash_errors+2
    lda #>0>>$10
    sta.z flash_errors+3
    // [1237] phi rom_flash::ram_address_sector#11 = (char *)$6000 [phi:rom_flash::@20->rom_flash::@1#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z ram_address_sector
    lda #>$6000
    sta.z ram_address_sector+1
    // [1237] phi rom_flash::bram_bank_sector#14 = 0 [phi:rom_flash::@20->rom_flash::@1#4] -- vbuz1=vbuc1 
    lda #0
    sta.z bram_bank_sector
    // [1237] phi rom_flash::rom_address_sector#12 = rom_flash::rom_address_sector#0 [phi:rom_flash::@20->rom_flash::@1#5] -- register_copy 
    // rom_flash::@1
  __b1:
    // while (rom_address_sector < rom_boundary)
    // [1238] if(rom_flash::rom_address_sector#12<rom_flash::rom_boundary#0) goto rom_flash::@2 -- vdum1_lt_vdum2_then_la1 
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
    // [1239] phi from rom_flash::@1 to rom_flash::@3 [phi:rom_flash::@1->rom_flash::@3]
    // rom_flash::@3
    // display_action_text("Flashed ...")
    // [1240] call display_action_text
    // [993] phi from rom_flash::@3 to display_action_text [phi:rom_flash::@3->display_action_text]
    // [993] phi display_action_text::info_text#19 = rom_flash::info_text2 [phi:rom_flash::@3->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z display_action_text.info_text
    lda #>info_text2
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // rom_flash::@return
    // }
    // [1241] return 
    rts
    // rom_flash::@2
  __b2:
    // unsigned int equal_bytes = rom_compare(bram_bank_sector, (ram_ptr_t)ram_address_sector, rom_address_sector, ROM_SECTOR)
    // [1242] rom_compare::bank_ram#1 = rom_flash::bram_bank_sector#14
    // [1243] rom_compare::ptr_ram#2 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z rom_compare.ptr_ram
    lda.z ram_address_sector+1
    sta.z rom_compare.ptr_ram+1
    // [1244] rom_compare::rom_compare_address#1 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_compare.rom_compare_address
    lda rom_address_sector+1
    sta.z rom_compare.rom_compare_address+1
    lda rom_address_sector+2
    sta.z rom_compare.rom_compare_address+2
    lda rom_address_sector+3
    sta.z rom_compare.rom_compare_address+3
    // [1245] call rom_compare
  // {asm{.byte $db}}
    // [2155] phi from rom_flash::@2 to rom_compare [phi:rom_flash::@2->rom_compare]
    // [2155] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#2 [phi:rom_flash::@2->rom_compare#0] -- register_copy 
    // [2155] phi rom_compare::rom_compare_size#11 = $1000 [phi:rom_flash::@2->rom_compare#1] -- vwuz1=vwuc1 
    lda #<$1000
    sta.z rom_compare.rom_compare_size
    lda #>$1000
    sta.z rom_compare.rom_compare_size+1
    // [2155] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#1 [phi:rom_flash::@2->rom_compare#2] -- register_copy 
    // [2155] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#1 [phi:rom_flash::@2->rom_compare#3] -- vbum1=vbuz2 
    lda.z rom_compare.bank_ram_1
    sta rom_compare.bank_set_bram1_bank
    jsr rom_compare
    // unsigned int equal_bytes = rom_compare(bram_bank_sector, (ram_ptr_t)ram_address_sector, rom_address_sector, ROM_SECTOR)
    // [1246] rom_compare::return#3 = rom_compare::equal_bytes#2
    // rom_flash::@21
    // [1247] rom_flash::equal_bytes#0 = rom_compare::return#3
    // if (equal_bytes != ROM_SECTOR)
    // [1248] if(rom_flash::equal_bytes#0!=$1000) goto rom_flash::@5 -- vwuz1_neq_vwuc1_then_la1 
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
    // [1249] cputsxy::x#1 = rom_flash::x_sector#10 -- vbum1=vbum2 
    lda x_sector
    sta cputsxy.x
    // [1250] cputsxy::y#1 = rom_flash::y_sector#13 -- vbum1=vbuz2 
    lda.z y_sector
    sta cputsxy.y
    // [1251] call cputsxy
    // [660] phi from rom_flash::@16 to cputsxy [phi:rom_flash::@16->cputsxy]
    // [660] phi cputsxy::s#4 = rom_flash::s [phi:rom_flash::@16->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z cputsxy.s
    lda #>s
    sta.z cputsxy.s+1
    // [660] phi cputsxy::y#4 = cputsxy::y#1 [phi:rom_flash::@16->cputsxy#1] -- register_copy 
    // [660] phi cputsxy::x#4 = cputsxy::x#1 [phi:rom_flash::@16->cputsxy#2] -- register_copy 
    jsr cputsxy
    // [1252] phi from rom_flash::@12 rom_flash::@16 to rom_flash::@4 [phi:rom_flash::@12/rom_flash::@16->rom_flash::@4]
    // [1252] phi rom_flash::flash_errors#13 = rom_flash::flash_errors#1 [phi:rom_flash::@12/rom_flash::@16->rom_flash::@4#0] -- register_copy 
    // rom_flash::@4
  __b4:
    // ram_address_sector += ROM_SECTOR
    // [1253] rom_flash::ram_address_sector#1 = rom_flash::ram_address_sector#11 + $1000 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address_sector
    clc
    adc #<$1000
    sta.z ram_address_sector
    lda.z ram_address_sector+1
    adc #>$1000
    sta.z ram_address_sector+1
    // rom_address_sector += ROM_SECTOR
    // [1254] rom_flash::rom_address_sector#1 = rom_flash::rom_address_sector#12 + $1000 -- vdum1=vdum1_plus_vwuc1 
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
    // [1255] if(rom_flash::ram_address_sector#1!=$c000) goto rom_flash::@13 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address_sector+1
    cmp #>$c000
    bne __b13
    lda.z ram_address_sector
    cmp #<$c000
    bne __b13
    // rom_flash::@17
    // bram_bank_sector++;
    // [1256] rom_flash::bram_bank_sector#1 = ++ rom_flash::bram_bank_sector#14 -- vbuz1=_inc_vbuz1 
    inc.z bram_bank_sector
    // [1257] phi from rom_flash::@17 to rom_flash::@13 [phi:rom_flash::@17->rom_flash::@13]
    // [1257] phi rom_flash::bram_bank_sector#38 = rom_flash::bram_bank_sector#1 [phi:rom_flash::@17->rom_flash::@13#0] -- register_copy 
    // [1257] phi rom_flash::ram_address_sector#8 = (char *)$a000 [phi:rom_flash::@17->rom_flash::@13#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address_sector
    lda #>$a000
    sta.z ram_address_sector+1
    // [1257] phi from rom_flash::@4 to rom_flash::@13 [phi:rom_flash::@4->rom_flash::@13]
    // [1257] phi rom_flash::bram_bank_sector#38 = rom_flash::bram_bank_sector#14 [phi:rom_flash::@4->rom_flash::@13#0] -- register_copy 
    // [1257] phi rom_flash::ram_address_sector#8 = rom_flash::ram_address_sector#1 [phi:rom_flash::@4->rom_flash::@13#1] -- register_copy 
    // rom_flash::@13
  __b13:
    // if (ram_address_sector == RAM_HIGH)
    // [1258] if(rom_flash::ram_address_sector#8!=$8000) goto rom_flash::@44 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address_sector+1
    cmp #>$8000
    bne __b14
    lda.z ram_address_sector
    cmp #<$8000
    bne __b14
    // [1260] phi from rom_flash::@13 to rom_flash::@14 [phi:rom_flash::@13->rom_flash::@14]
    // [1260] phi rom_flash::ram_address_sector#15 = (char *)$a000 [phi:rom_flash::@13->rom_flash::@14#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address_sector
    lda #>$a000
    sta.z ram_address_sector+1
    // [1260] phi rom_flash::bram_bank_sector#12 = 1 [phi:rom_flash::@13->rom_flash::@14#1] -- vbuz1=vbuc1 
    lda #1
    sta.z bram_bank_sector
    // [1259] phi from rom_flash::@13 to rom_flash::@44 [phi:rom_flash::@13->rom_flash::@44]
    // rom_flash::@44
    // [1260] phi from rom_flash::@44 to rom_flash::@14 [phi:rom_flash::@44->rom_flash::@14]
    // [1260] phi rom_flash::ram_address_sector#15 = rom_flash::ram_address_sector#8 [phi:rom_flash::@44->rom_flash::@14#0] -- register_copy 
    // [1260] phi rom_flash::bram_bank_sector#12 = rom_flash::bram_bank_sector#38 [phi:rom_flash::@44->rom_flash::@14#1] -- register_copy 
    // rom_flash::@14
  __b14:
    // x_sector += 8
    // [1261] rom_flash::x_sector#1 = rom_flash::x_sector#10 + 8 -- vbum1=vbum1_plus_vbuc1 
    lda #8
    clc
    adc x_sector
    sta x_sector
    // rom_address_sector % ROM_PROGRESS_ROW
    // [1262] rom_flash::$29 = rom_flash::rom_address_sector#1 & ROM_PROGRESS_ROW-1 -- vdum1=vdum2_band_vduc1 
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
    // [1263] if(0!=rom_flash::$29) goto rom_flash::@15 -- 0_neq_vdum1_then_la1 
    lda rom_flash__29
    ora rom_flash__29+1
    ora rom_flash__29+2
    ora rom_flash__29+3
    bne __b15
    // rom_flash::@18
    // y_sector++;
    // [1264] rom_flash::y_sector#1 = ++ rom_flash::y_sector#13 -- vbuz1=_inc_vbuz1 
    inc.z y_sector
    // [1265] phi from rom_flash::@18 to rom_flash::@15 [phi:rom_flash::@18->rom_flash::@15]
    // [1265] phi rom_flash::y_sector#18 = rom_flash::y_sector#1 [phi:rom_flash::@18->rom_flash::@15#0] -- register_copy 
    // [1265] phi rom_flash::x_sector#20 = PROGRESS_X [phi:rom_flash::@18->rom_flash::@15#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [1265] phi from rom_flash::@14 to rom_flash::@15 [phi:rom_flash::@14->rom_flash::@15]
    // [1265] phi rom_flash::y_sector#18 = rom_flash::y_sector#13 [phi:rom_flash::@14->rom_flash::@15#0] -- register_copy 
    // [1265] phi rom_flash::x_sector#20 = rom_flash::x_sector#1 [phi:rom_flash::@14->rom_flash::@15#1] -- register_copy 
    // rom_flash::@15
  __b15:
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1266] call snprintf_init
    // [770] phi from rom_flash::@15 to snprintf_init [phi:rom_flash::@15->snprintf_init]
    // [770] phi snprintf_init::s#25 = info_text [phi:rom_flash::@15->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // rom_flash::@40
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1267] printf_ulong::uvalue#8 = rom_flash::flash_errors#13 -- vdum1=vduz2 
    lda.z flash_errors
    sta printf_ulong.uvalue
    lda.z flash_errors+1
    sta printf_ulong.uvalue+1
    lda.z flash_errors+2
    sta printf_ulong.uvalue+2
    lda.z flash_errors+3
    sta printf_ulong.uvalue+3
    // [1268] call printf_ulong
    // [1217] phi from rom_flash::@40 to printf_ulong [phi:rom_flash::@40->printf_ulong]
    // [1217] phi printf_ulong::format_zero_padding#11 = 0 [phi:rom_flash::@40->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1217] phi printf_ulong::format_min_length#11 = 0 [phi:rom_flash::@40->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1217] phi printf_ulong::putc#11 = &snputc [phi:rom_flash::@40->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1217] phi printf_ulong::format_radix#11 = DECIMAL [phi:rom_flash::@40->printf_ulong#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1217] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#8 [phi:rom_flash::@40->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1269] phi from rom_flash::@40 to rom_flash::@41 [phi:rom_flash::@40->rom_flash::@41]
    // rom_flash::@41
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1270] call printf_str
    // [775] phi from rom_flash::@41 to printf_str [phi:rom_flash::@41->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:rom_flash::@41->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = rom_flash::s6 [phi:rom_flash::@41->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@42
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1271] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1272] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_FLASHING, info_text)
    // [1274] display_info_rom::rom_chip#3 = rom_flash::rom_chip#0 -- vbuz1=vbum2 
    lda rom_chip
    sta.z display_info_rom.rom_chip
    // [1275] call display_info_rom
    // [1016] phi from rom_flash::@42 to display_info_rom [phi:rom_flash::@42->display_info_rom]
    // [1016] phi display_info_rom::info_text#16 = info_text [phi:rom_flash::@42->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1016] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#3 [phi:rom_flash::@42->display_info_rom#1] -- register_copy 
    // [1016] phi display_info_rom::info_status#16 = STATUS_FLASHING [phi:rom_flash::@42->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHING
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // [1237] phi from rom_flash::@42 to rom_flash::@1 [phi:rom_flash::@42->rom_flash::@1]
    // [1237] phi rom_flash::y_sector#13 = rom_flash::y_sector#18 [phi:rom_flash::@42->rom_flash::@1#0] -- register_copy 
    // [1237] phi rom_flash::x_sector#10 = rom_flash::x_sector#20 [phi:rom_flash::@42->rom_flash::@1#1] -- register_copy 
    // [1237] phi rom_flash::flash_errors#10 = rom_flash::flash_errors#13 [phi:rom_flash::@42->rom_flash::@1#2] -- register_copy 
    // [1237] phi rom_flash::ram_address_sector#11 = rom_flash::ram_address_sector#15 [phi:rom_flash::@42->rom_flash::@1#3] -- register_copy 
    // [1237] phi rom_flash::bram_bank_sector#14 = rom_flash::bram_bank_sector#12 [phi:rom_flash::@42->rom_flash::@1#4] -- register_copy 
    // [1237] phi rom_flash::rom_address_sector#12 = rom_flash::rom_address_sector#1 [phi:rom_flash::@42->rom_flash::@1#5] -- register_copy 
    jmp __b1
    // [1276] phi from rom_flash::@21 to rom_flash::@5 [phi:rom_flash::@21->rom_flash::@5]
  __b3:
    // [1276] phi rom_flash::retries#12 = 0 [phi:rom_flash::@21->rom_flash::@5#0] -- vbuz1=vbuc1 
    lda #0
    sta.z retries
    // [1276] phi rom_flash::flash_errors_sector#11 = 0 [phi:rom_flash::@21->rom_flash::@5#1] -- vwuz1=vwuc1 
    sta.z flash_errors_sector
    sta.z flash_errors_sector+1
    // [1276] phi from rom_flash::@43 to rom_flash::@5 [phi:rom_flash::@43->rom_flash::@5]
    // [1276] phi rom_flash::retries#12 = rom_flash::retries#1 [phi:rom_flash::@43->rom_flash::@5#0] -- register_copy 
    // [1276] phi rom_flash::flash_errors_sector#11 = rom_flash::flash_errors_sector#10 [phi:rom_flash::@43->rom_flash::@5#1] -- register_copy 
    // rom_flash::@5
  __b5:
    // rom_sector_erase(rom_address_sector)
    // [1277] rom_sector_erase::address#0 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_sector_erase.address
    lda rom_address_sector+1
    sta.z rom_sector_erase.address+1
    lda rom_address_sector+2
    sta.z rom_sector_erase.address+2
    lda rom_address_sector+3
    sta.z rom_sector_erase.address+3
    // [1278] call rom_sector_erase
    // [2211] phi from rom_flash::@5 to rom_sector_erase [phi:rom_flash::@5->rom_sector_erase]
    jsr rom_sector_erase
    // rom_flash::@22
    // unsigned long rom_sector_boundary = rom_address_sector + ROM_SECTOR
    // [1279] rom_flash::rom_sector_boundary#0 = rom_flash::rom_address_sector#12 + $1000 -- vdum1=vdum2_plus_vwuc1 
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
    // [1280] gotoxy::x#28 = rom_flash::x_sector#10 -- vbum1=vbum2 
    lda x_sector
    sta gotoxy.x
    // [1281] gotoxy::y#28 = rom_flash::y_sector#13 -- vbum1=vbuz2 
    lda.z y_sector
    sta gotoxy.y
    // [1282] call gotoxy
    // [573] phi from rom_flash::@22 to gotoxy [phi:rom_flash::@22->gotoxy]
    // [573] phi gotoxy::y#30 = gotoxy::y#28 [phi:rom_flash::@22->gotoxy#0] -- register_copy 
    // [573] phi gotoxy::x#30 = gotoxy::x#28 [phi:rom_flash::@22->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1283] phi from rom_flash::@22 to rom_flash::@23 [phi:rom_flash::@22->rom_flash::@23]
    // rom_flash::@23
    // printf("........")
    // [1284] call printf_str
    // [775] phi from rom_flash::@23 to printf_str [phi:rom_flash::@23->printf_str]
    // [775] phi printf_str::putc#73 = &cputc [phi:rom_flash::@23->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = rom_flash::s1 [phi:rom_flash::@23->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@24
    // [1285] rom_flash::rom_address#26 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_address
    lda rom_address_sector+1
    sta.z rom_address+1
    lda rom_address_sector+2
    sta.z rom_address+2
    lda rom_address_sector+3
    sta.z rom_address+3
    // [1286] rom_flash::ram_address#26 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z ram_address
    lda.z ram_address_sector+1
    sta.z ram_address+1
    // [1287] rom_flash::x#26 = rom_flash::x_sector#10 -- vbuz1=vbum2 
    lda x_sector
    sta.z x
    // [1288] phi from rom_flash::@10 rom_flash::@24 to rom_flash::@6 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6]
    // [1288] phi rom_flash::x#10 = rom_flash::x#1 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#0] -- register_copy 
    // [1288] phi rom_flash::ram_address#10 = rom_flash::ram_address#1 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#1] -- register_copy 
    // [1288] phi rom_flash::flash_errors_sector#10 = rom_flash::flash_errors_sector#8 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#2] -- register_copy 
    // [1288] phi rom_flash::rom_address#11 = rom_flash::rom_address#1 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#3] -- register_copy 
    // rom_flash::@6
  __b6:
    // while (rom_address < rom_sector_boundary)
    // [1289] if(rom_flash::rom_address#11<rom_flash::rom_sector_boundary#0) goto rom_flash::@7 -- vduz1_lt_vdum2_then_la1 
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
    // [1290] rom_flash::retries#1 = ++ rom_flash::retries#12 -- vbuz1=_inc_vbuz1 
    inc.z retries
    // while (flash_errors_sector && retries <= 3)
    // [1291] if(0==rom_flash::flash_errors_sector#10) goto rom_flash::@12 -- 0_eq_vwuz1_then_la1 
    lda.z flash_errors_sector
    ora.z flash_errors_sector+1
    beq __b12
    // rom_flash::@43
    // [1292] if(rom_flash::retries#1<3+1) goto rom_flash::@5 -- vbuz1_lt_vbuc1_then_la1 
    lda.z retries
    cmp #3+1
    bcs !__b5+
    jmp __b5
  !__b5:
    // rom_flash::@12
  __b12:
    // flash_errors += flash_errors_sector
    // [1293] rom_flash::flash_errors#1 = rom_flash::flash_errors#10 + rom_flash::flash_errors_sector#10 -- vduz1=vduz1_plus_vwuz2 
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
    // [1294] printf_ulong::uvalue#7 = rom_flash::flash_errors_sector#10 + rom_flash::flash_errors#10 -- vdum1=vwuz2_plus_vduz3 
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
    // [1295] call snprintf_init
    // [770] phi from rom_flash::@7 to snprintf_init [phi:rom_flash::@7->snprintf_init]
    // [770] phi snprintf_init::s#25 = info_text [phi:rom_flash::@7->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1296] phi from rom_flash::@7 to rom_flash::@25 [phi:rom_flash::@7->rom_flash::@25]
    // rom_flash::@25
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1297] call printf_str
    // [775] phi from rom_flash::@25 to printf_str [phi:rom_flash::@25->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:rom_flash::@25->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = rom_flash::s2 [phi:rom_flash::@25->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@26
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1298] printf_uchar::uvalue#7 = rom_flash::bram_bank_sector#14 -- vbum1=vbuz2 
    lda.z bram_bank_sector
    sta printf_uchar.uvalue
    // [1299] call printf_uchar
    // [982] phi from rom_flash::@26 to printf_uchar [phi:rom_flash::@26->printf_uchar]
    // [982] phi printf_uchar::format_zero_padding#11 = 1 [phi:rom_flash::@26->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [982] phi printf_uchar::format_min_length#11 = 2 [phi:rom_flash::@26->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [982] phi printf_uchar::putc#11 = &snputc [phi:rom_flash::@26->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [982] phi printf_uchar::format_radix#11 = HEXADECIMAL [phi:rom_flash::@26->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [982] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#7 [phi:rom_flash::@26->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1300] phi from rom_flash::@26 to rom_flash::@27 [phi:rom_flash::@26->rom_flash::@27]
    // rom_flash::@27
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1301] call printf_str
    // [775] phi from rom_flash::@27 to printf_str [phi:rom_flash::@27->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:rom_flash::@27->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = s3 [phi:rom_flash::@27->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@28
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1302] printf_uint::uvalue#15 = (unsigned int)rom_flash::ram_address_sector#11 -- vwum1=vwuz2 
    lda.z ram_address_sector
    sta printf_uint.uvalue
    lda.z ram_address_sector+1
    sta printf_uint.uvalue+1
    // [1303] call printf_uint
    // [809] phi from rom_flash::@28 to printf_uint [phi:rom_flash::@28->printf_uint]
    // [809] phi printf_uint::format_zero_padding#18 = 1 [phi:rom_flash::@28->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [809] phi printf_uint::format_min_length#18 = 4 [phi:rom_flash::@28->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [809] phi printf_uint::putc#18 = &snputc [phi:rom_flash::@28->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [809] phi printf_uint::format_radix#18 = HEXADECIMAL [phi:rom_flash::@28->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [809] phi printf_uint::uvalue#18 = printf_uint::uvalue#15 [phi:rom_flash::@28->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1304] phi from rom_flash::@28 to rom_flash::@29 [phi:rom_flash::@28->rom_flash::@29]
    // rom_flash::@29
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1305] call printf_str
    // [775] phi from rom_flash::@29 to printf_str [phi:rom_flash::@29->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:rom_flash::@29->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = rom_flash::s4 [phi:rom_flash::@29->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@30
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1306] printf_ulong::uvalue#6 = rom_flash::rom_address_sector#12 -- vdum1=vdum2 
    lda rom_address_sector
    sta printf_ulong.uvalue
    lda rom_address_sector+1
    sta printf_ulong.uvalue+1
    lda rom_address_sector+2
    sta printf_ulong.uvalue+2
    lda rom_address_sector+3
    sta printf_ulong.uvalue+3
    // [1307] call printf_ulong
    // [1217] phi from rom_flash::@30 to printf_ulong [phi:rom_flash::@30->printf_ulong]
    // [1217] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_flash::@30->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1217] phi printf_ulong::format_min_length#11 = 5 [phi:rom_flash::@30->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1217] phi printf_ulong::putc#11 = &snputc [phi:rom_flash::@30->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1217] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_flash::@30->printf_ulong#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1217] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#6 [phi:rom_flash::@30->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1308] phi from rom_flash::@30 to rom_flash::@31 [phi:rom_flash::@30->rom_flash::@31]
    // rom_flash::@31
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1309] call printf_str
    // [775] phi from rom_flash::@31 to printf_str [phi:rom_flash::@31->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:rom_flash::@31->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = rom_flash::s5 [phi:rom_flash::@31->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@32
    // [1310] printf_ulong::uvalue#20 = printf_ulong::uvalue#7 -- vdum1=vdum2 
    lda printf_ulong.uvalue_1
    sta printf_ulong.uvalue
    lda printf_ulong.uvalue_1+1
    sta printf_ulong.uvalue+1
    lda printf_ulong.uvalue_1+2
    sta printf_ulong.uvalue+2
    lda printf_ulong.uvalue_1+3
    sta printf_ulong.uvalue+3
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1311] call printf_ulong
    // [1217] phi from rom_flash::@32 to printf_ulong [phi:rom_flash::@32->printf_ulong]
    // [1217] phi printf_ulong::format_zero_padding#11 = 0 [phi:rom_flash::@32->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1217] phi printf_ulong::format_min_length#11 = 0 [phi:rom_flash::@32->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1217] phi printf_ulong::putc#11 = &snputc [phi:rom_flash::@32->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1217] phi printf_ulong::format_radix#11 = DECIMAL [phi:rom_flash::@32->printf_ulong#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1217] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#20 [phi:rom_flash::@32->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1312] phi from rom_flash::@32 to rom_flash::@33 [phi:rom_flash::@32->rom_flash::@33]
    // rom_flash::@33
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1313] call printf_str
    // [775] phi from rom_flash::@33 to printf_str [phi:rom_flash::@33->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:rom_flash::@33->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = rom_flash::s6 [phi:rom_flash::@33->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@34
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1314] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1315] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1317] call display_action_text
    // [993] phi from rom_flash::@34 to display_action_text [phi:rom_flash::@34->display_action_text]
    // [993] phi display_action_text::info_text#19 = info_text [phi:rom_flash::@34->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // rom_flash::@35
    // unsigned long written_bytes = rom_write(bram_bank, (ram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1318] rom_write::flash_ram_bank#0 = rom_flash::bram_bank_sector#14 -- vbuz1=vbuz2 
    lda.z bram_bank_sector
    sta.z rom_write.flash_ram_bank
    // [1319] rom_write::flash_ram_address#1 = rom_flash::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_write.flash_ram_address
    lda.z ram_address+1
    sta.z rom_write.flash_ram_address+1
    // [1320] rom_write::flash_rom_address#1 = rom_flash::rom_address#11 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_write.flash_rom_address
    lda.z rom_address+1
    sta.z rom_write.flash_rom_address+1
    lda.z rom_address+2
    sta.z rom_write.flash_rom_address+2
    lda.z rom_address+3
    sta.z rom_write.flash_rom_address+3
    // [1321] call rom_write
    jsr rom_write
    // rom_flash::@36
    // rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1322] rom_compare::bank_ram#2 = rom_flash::bram_bank_sector#14
    // [1323] rom_compare::ptr_ram#3 = rom_flash::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_compare.ptr_ram
    lda.z ram_address+1
    sta.z rom_compare.ptr_ram+1
    // [1324] rom_compare::rom_compare_address#2 = rom_flash::rom_address#11 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_compare.rom_compare_address
    lda.z rom_address+1
    sta.z rom_compare.rom_compare_address+1
    lda.z rom_address+2
    sta.z rom_compare.rom_compare_address+2
    lda.z rom_address+3
    sta.z rom_compare.rom_compare_address+3
    // [1325] call rom_compare
    // [2155] phi from rom_flash::@36 to rom_compare [phi:rom_flash::@36->rom_compare]
    // [2155] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#3 [phi:rom_flash::@36->rom_compare#0] -- register_copy 
    // [2155] phi rom_compare::rom_compare_size#11 = ROM_PROGRESS_CELL [phi:rom_flash::@36->rom_compare#1] -- vwuz1=vwuc1 
    lda #<ROM_PROGRESS_CELL
    sta.z rom_compare.rom_compare_size
    lda #>ROM_PROGRESS_CELL
    sta.z rom_compare.rom_compare_size+1
    // [2155] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#2 [phi:rom_flash::@36->rom_compare#2] -- register_copy 
    // [2155] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#2 [phi:rom_flash::@36->rom_compare#3] -- vbum1=vbuz2 
    lda.z rom_compare.bank_ram_1
    sta rom_compare.bank_set_bram1_bank
    jsr rom_compare
    // rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1326] rom_compare::return#4 = rom_compare::equal_bytes#2
    // rom_flash::@37
    // equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1327] rom_flash::equal_bytes#1 = rom_compare::return#4 -- vwuz1=vwuz2 
    lda.z rom_compare.return
    sta.z equal_bytes_1
    lda.z rom_compare.return+1
    sta.z equal_bytes_1+1
    // gotoxy(x, y)
    // [1328] gotoxy::x#29 = rom_flash::x#10 -- vbum1=vbuz2 
    lda.z x
    sta gotoxy.x
    // [1329] gotoxy::y#29 = rom_flash::y_sector#13 -- vbum1=vbuz2 
    lda.z y_sector
    sta gotoxy.y
    // [1330] call gotoxy
    // [573] phi from rom_flash::@37 to gotoxy [phi:rom_flash::@37->gotoxy]
    // [573] phi gotoxy::y#30 = gotoxy::y#29 [phi:rom_flash::@37->gotoxy#0] -- register_copy 
    // [573] phi gotoxy::x#30 = gotoxy::x#29 [phi:rom_flash::@37->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_flash::@38
    // if (equal_bytes != ROM_PROGRESS_CELL)
    // [1331] if(rom_flash::equal_bytes#1!=ROM_PROGRESS_CELL) goto rom_flash::@9 -- vwuz1_neq_vwuc1_then_la1 
    lda.z equal_bytes_1+1
    cmp #>ROM_PROGRESS_CELL
    bne __b9
    lda.z equal_bytes_1
    cmp #<ROM_PROGRESS_CELL
    bne __b9
    // rom_flash::@11
    // cputcxy(x,y,'+')
    // [1332] cputcxy::x#14 = rom_flash::x#10 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [1333] cputcxy::y#14 = rom_flash::y_sector#13 -- vbum1=vbuz2 
    lda.z y_sector
    sta cputcxy.y
    // [1334] call cputcxy
    // [1781] phi from rom_flash::@11 to cputcxy [phi:rom_flash::@11->cputcxy]
    // [1781] phi cputcxy::c#15 = '+' [phi:rom_flash::@11->cputcxy#0] -- vbum1=vbuc1 
    lda #'+'
    sta cputcxy.c
    // [1781] phi cputcxy::y#15 = cputcxy::y#14 [phi:rom_flash::@11->cputcxy#1] -- register_copy 
    // [1781] phi cputcxy::x#15 = cputcxy::x#14 [phi:rom_flash::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [1335] phi from rom_flash::@11 rom_flash::@39 to rom_flash::@10 [phi:rom_flash::@11/rom_flash::@39->rom_flash::@10]
    // [1335] phi rom_flash::flash_errors_sector#8 = rom_flash::flash_errors_sector#10 [phi:rom_flash::@11/rom_flash::@39->rom_flash::@10#0] -- register_copy 
    // rom_flash::@10
  __b10:
    // ram_address += ROM_PROGRESS_CELL
    // [1336] rom_flash::ram_address#1 = rom_flash::ram_address#10 + ROM_PROGRESS_CELL -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address
    clc
    adc #<ROM_PROGRESS_CELL
    sta.z ram_address
    lda.z ram_address+1
    adc #>ROM_PROGRESS_CELL
    sta.z ram_address+1
    // rom_address += ROM_PROGRESS_CELL
    // [1337] rom_flash::rom_address#1 = rom_flash::rom_address#11 + ROM_PROGRESS_CELL -- vduz1=vduz1_plus_vwuc1 
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
    // [1338] rom_flash::x#1 = ++ rom_flash::x#10 -- vbuz1=_inc_vbuz1 
    inc.z x
    jmp __b6
    // rom_flash::@9
  __b9:
    // cputcxy(x,y,'!')
    // [1339] cputcxy::x#13 = rom_flash::x#10 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [1340] cputcxy::y#13 = rom_flash::y_sector#13 -- vbum1=vbuz2 
    lda.z y_sector
    sta cputcxy.y
    // [1341] call cputcxy
    // [1781] phi from rom_flash::@9 to cputcxy [phi:rom_flash::@9->cputcxy]
    // [1781] phi cputcxy::c#15 = '!' [phi:rom_flash::@9->cputcxy#0] -- vbum1=vbuc1 
    lda #'!'
    sta cputcxy.c
    // [1781] phi cputcxy::y#15 = cputcxy::y#13 [phi:rom_flash::@9->cputcxy#1] -- register_copy 
    // [1781] phi cputcxy::x#15 = cputcxy::x#13 [phi:rom_flash::@9->cputcxy#2] -- register_copy 
    jsr cputcxy
    // rom_flash::@39
    // flash_errors_sector++;
    // [1342] rom_flash::flash_errors_sector#1 = ++ rom_flash::flash_errors_sector#10 -- vwuz1=_inc_vwuz1 
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
    .label x_sector = main.check_status_smc4_main__0
    .label rom_chip = smc_flash.smc_byte_upload
    .label rom_bank_start = rom_detect.rom_detect__4
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
// __zp($70) unsigned int smc_flash(__zp($2d) unsigned int smc_bytes_total)
smc_flash: {
    .label smc_flash__26 = $4d
    .label smc_flash__27 = $4d
    .label smc_bootloader_start = $ce
    .label return = $70
    .label smc_bootloader_not_activated = $d6
    .label smc_ram_ptr = $76
    .label smc_bytes_checksum = $4d
    .label smc_package_flashed = $44
    .label smc_bytes_flashed = $70
    .label smc_row_bytes = $6e
    .label smc_attempts_total = $4a
    .label smc_bytes_total = $2d
    .label smc_package_committed = $c2
    // display_action_progress("To start the SMC update, do the below action ...")
    // [1344] call display_action_progress
    // [667] phi from smc_flash to display_action_progress [phi:smc_flash->display_action_progress]
    // [667] phi display_action_progress::info_text#14 = smc_flash::info_text [phi:smc_flash->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // smc_flash::@25
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [1345] smc_flash::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [1346] smc_flash::cx16_k_i2c_write_byte1_offset = $8f -- vbum1=vbuc1 
    lda #$8f
    sta cx16_k_i2c_write_byte1_offset
    // [1347] smc_flash::cx16_k_i2c_write_byte1_value = $31 -- vbum1=vbuc1 
    lda #$31
    sta cx16_k_i2c_write_byte1_value
    // smc_flash::cx16_k_i2c_write_byte1
    // unsigned char result
    // [1348] smc_flash::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
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
    // [1350] smc_flash::cx16_k_i2c_write_byte1_return#0 = smc_flash::cx16_k_i2c_write_byte1_result -- vbum1=vbum2 
    lda cx16_k_i2c_write_byte1_result
    sta cx16_k_i2c_write_byte1_return
    // smc_flash::cx16_k_i2c_write_byte1_@return
    // }
    // [1351] smc_flash::cx16_k_i2c_write_byte1_return#1 = smc_flash::cx16_k_i2c_write_byte1_return#0
    // smc_flash::@22
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [1352] smc_flash::smc_bootloader_start#0 = smc_flash::cx16_k_i2c_write_byte1_return#1 -- vbuz1=vbum2 
    sta.z smc_bootloader_start
    // if(smc_bootloader_start)
    // [1353] if(0==smc_flash::smc_bootloader_start#0) goto smc_flash::@3 -- 0_eq_vbuz1_then_la1 
    beq __b6
    // [1354] phi from smc_flash::@22 to smc_flash::@2 [phi:smc_flash::@22->smc_flash::@2]
    // smc_flash::@2
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1355] call snprintf_init
    // [770] phi from smc_flash::@2 to snprintf_init [phi:smc_flash::@2->snprintf_init]
    // [770] phi snprintf_init::s#25 = info_text [phi:smc_flash::@2->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1356] phi from smc_flash::@2 to smc_flash::@26 [phi:smc_flash::@2->smc_flash::@26]
    // smc_flash::@26
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1357] call printf_str
    // [775] phi from smc_flash::@26 to printf_str [phi:smc_flash::@26->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:smc_flash::@26->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = smc_flash::s [phi:smc_flash::@26->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@27
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1358] printf_uchar::uvalue#1 = smc_flash::smc_bootloader_start#0 -- vbum1=vbuz2 
    lda.z smc_bootloader_start
    sta printf_uchar.uvalue
    // [1359] call printf_uchar
    // [982] phi from smc_flash::@27 to printf_uchar [phi:smc_flash::@27->printf_uchar]
    // [982] phi printf_uchar::format_zero_padding#11 = 0 [phi:smc_flash::@27->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [982] phi printf_uchar::format_min_length#11 = 0 [phi:smc_flash::@27->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [982] phi printf_uchar::putc#11 = &snputc [phi:smc_flash::@27->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [982] phi printf_uchar::format_radix#11 = HEXADECIMAL [phi:smc_flash::@27->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [982] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#1 [phi:smc_flash::@27->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // smc_flash::@28
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1360] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1361] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1363] call display_action_text
    // [993] phi from smc_flash::@28 to display_action_text [phi:smc_flash::@28->display_action_text]
    // [993] phi display_action_text::info_text#19 = info_text [phi:smc_flash::@28->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_flash::@29
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [1364] smc_flash::cx16_k_i2c_write_byte2_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte2_device
    // [1365] smc_flash::cx16_k_i2c_write_byte2_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte2_offset
    // [1366] smc_flash::cx16_k_i2c_write_byte2_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte2_value
    // smc_flash::cx16_k_i2c_write_byte2
    // unsigned char result
    // [1367] smc_flash::cx16_k_i2c_write_byte2_result = 0 -- vbum1=vbuc1 
    sta cx16_k_i2c_write_byte2_result
    // asm
    // asm { ldxdevice ldyoffset ldavalue stzresult jsrCX16_I2C_WRITE_BYTE rolresult  }
    ldx cx16_k_i2c_write_byte2_device
    ldy cx16_k_i2c_write_byte2_offset
    lda cx16_k_i2c_write_byte2_value
    stz cx16_k_i2c_write_byte2_result
    jsr CX16_I2C_WRITE_BYTE
    rol cx16_k_i2c_write_byte2_result
    // [1369] phi from smc_flash::@47 smc_flash::@59 smc_flash::cx16_k_i2c_write_byte2 to smc_flash::@return [phi:smc_flash::@47/smc_flash::@59/smc_flash::cx16_k_i2c_write_byte2->smc_flash::@return]
  __b2:
    // [1369] phi smc_flash::return#1 = 0 [phi:smc_flash::@47/smc_flash::@59/smc_flash::cx16_k_i2c_write_byte2->smc_flash::@return#0] -- vwuz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // smc_flash::@return
    // }
    // [1370] return 
    rts
    // [1371] phi from smc_flash::@22 to smc_flash::@3 [phi:smc_flash::@22->smc_flash::@3]
  __b6:
    // [1371] phi smc_flash::smc_bootloader_activation_countdown#10 = $80 [phi:smc_flash::@22->smc_flash::@3#0] -- vbum1=vbuc1 
    lda #$80
    sta smc_bootloader_activation_countdown
    // smc_flash::@3
  __b3:
    // while(smc_bootloader_activation_countdown)
    // [1372] if(0!=smc_flash::smc_bootloader_activation_countdown#10) goto smc_flash::@4 -- 0_neq_vbum1_then_la1 
    lda smc_bootloader_activation_countdown
    beq !__b4+
    jmp __b4
  !__b4:
    // [1373] phi from smc_flash::@3 smc_flash::@30 to smc_flash::@7 [phi:smc_flash::@3/smc_flash::@30->smc_flash::@7]
  __b9:
    // [1373] phi smc_flash::smc_bootloader_activation_countdown#12 = $a [phi:smc_flash::@3/smc_flash::@30->smc_flash::@7#0] -- vbum1=vbuc1 
    lda #$a
    sta smc_bootloader_activation_countdown_1
    // smc_flash::@7
  __b7:
    // while(smc_bootloader_activation_countdown)
    // [1374] if(0!=smc_flash::smc_bootloader_activation_countdown#12) goto smc_flash::@8 -- 0_neq_vbum1_then_la1 
    lda smc_bootloader_activation_countdown_1
    beq !__b8+
    jmp __b8
  !__b8:
    // smc_flash::@9
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1375] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1376] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [1377] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [1378] cx16_k_i2c_read_byte::return#13 = cx16_k_i2c_read_byte::return#1
    // smc_flash::@42
    // smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1379] smc_flash::smc_bootloader_not_activated#1 = cx16_k_i2c_read_byte::return#13 -- vwuz1=vwum2 
    lda cx16_k_i2c_read_byte.return
    sta.z smc_bootloader_not_activated
    lda cx16_k_i2c_read_byte.return+1
    sta.z smc_bootloader_not_activated+1
    // if(smc_bootloader_not_activated)
    // [1380] if(0==smc_flash::smc_bootloader_not_activated#1) goto smc_flash::@1 -- 0_eq_vwuz1_then_la1 
    lda.z smc_bootloader_not_activated
    ora.z smc_bootloader_not_activated+1
    beq __b1
    // [1381] phi from smc_flash::@42 to smc_flash::@10 [phi:smc_flash::@42->smc_flash::@10]
    // smc_flash::@10
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1382] call snprintf_init
    // [770] phi from smc_flash::@10 to snprintf_init [phi:smc_flash::@10->snprintf_init]
    // [770] phi snprintf_init::s#25 = info_text [phi:smc_flash::@10->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1383] phi from smc_flash::@10 to smc_flash::@45 [phi:smc_flash::@10->smc_flash::@45]
    // smc_flash::@45
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1384] call printf_str
    // [775] phi from smc_flash::@45 to printf_str [phi:smc_flash::@45->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:smc_flash::@45->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = smc_flash::s5 [phi:smc_flash::@45->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@46
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1385] printf_uint::uvalue#8 = smc_flash::smc_bootloader_not_activated#1 -- vwum1=vwuz2 
    lda.z smc_bootloader_not_activated
    sta printf_uint.uvalue
    lda.z smc_bootloader_not_activated+1
    sta printf_uint.uvalue+1
    // [1386] call printf_uint
    // [809] phi from smc_flash::@46 to printf_uint [phi:smc_flash::@46->printf_uint]
    // [809] phi printf_uint::format_zero_padding#18 = 0 [phi:smc_flash::@46->printf_uint#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uint.format_zero_padding
    // [809] phi printf_uint::format_min_length#18 = 0 [phi:smc_flash::@46->printf_uint#1] -- vbum1=vbuc1 
    sta printf_uint.format_min_length
    // [809] phi printf_uint::putc#18 = &snputc [phi:smc_flash::@46->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [809] phi printf_uint::format_radix#18 = HEXADECIMAL [phi:smc_flash::@46->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [809] phi printf_uint::uvalue#18 = printf_uint::uvalue#8 [phi:smc_flash::@46->printf_uint#4] -- register_copy 
    jsr printf_uint
    // smc_flash::@47
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1387] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1388] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1390] call display_action_text
    // [993] phi from smc_flash::@47 to display_action_text [phi:smc_flash::@47->display_action_text]
    // [993] phi display_action_text::info_text#19 = info_text [phi:smc_flash::@47->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    jmp __b2
    // [1391] phi from smc_flash::@42 to smc_flash::@1 [phi:smc_flash::@42->smc_flash::@1]
    // smc_flash::@1
  __b1:
    // display_action_progress("Updating SMC firmware ... (+) Updated")
    // [1392] call display_action_progress
    // [667] phi from smc_flash::@1 to display_action_progress [phi:smc_flash::@1->display_action_progress]
    // [667] phi display_action_progress::info_text#14 = smc_flash::info_text1 [phi:smc_flash::@1->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_action_progress.info_text
    lda #>info_text1
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1393] phi from smc_flash::@1 to smc_flash::@43 [phi:smc_flash::@1->smc_flash::@43]
    // smc_flash::@43
    // textcolor(WHITE)
    // [1394] call textcolor
    // [555] phi from smc_flash::@43 to textcolor [phi:smc_flash::@43->textcolor]
    // [555] phi textcolor::color#18 = WHITE [phi:smc_flash::@43->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [1395] phi from smc_flash::@43 to smc_flash::@44 [phi:smc_flash::@43->smc_flash::@44]
    // smc_flash::@44
    // gotoxy(x, y)
    // [1396] call gotoxy
    // [573] phi from smc_flash::@44 to gotoxy [phi:smc_flash::@44->gotoxy]
    // [573] phi gotoxy::y#30 = PROGRESS_Y [phi:smc_flash::@44->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [573] phi gotoxy::x#30 = PROGRESS_X [phi:smc_flash::@44->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1397] phi from smc_flash::@44 to smc_flash::@11 [phi:smc_flash::@44->smc_flash::@11]
    // [1397] phi smc_flash::y#31 = PROGRESS_Y [phi:smc_flash::@44->smc_flash::@11#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1397] phi smc_flash::smc_attempts_total#21 = 0 [phi:smc_flash::@44->smc_flash::@11#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z smc_attempts_total
    sta.z smc_attempts_total+1
    // [1397] phi smc_flash::smc_row_bytes#14 = 0 [phi:smc_flash::@44->smc_flash::@11#2] -- vwuz1=vwuc1 
    sta.z smc_row_bytes
    sta.z smc_row_bytes+1
    // [1397] phi smc_flash::smc_ram_ptr#13 = (char *)$6000 [phi:smc_flash::@44->smc_flash::@11#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z smc_ram_ptr
    lda #>$6000
    sta.z smc_ram_ptr+1
    // [1397] phi smc_flash::smc_bytes_flashed#16 = 0 [phi:smc_flash::@44->smc_flash::@11#4] -- vwuz1=vwuc1 
    lda #<0
    sta.z smc_bytes_flashed
    sta.z smc_bytes_flashed+1
    // [1397] phi from smc_flash::@13 to smc_flash::@11 [phi:smc_flash::@13->smc_flash::@11]
    // [1397] phi smc_flash::y#31 = smc_flash::y#20 [phi:smc_flash::@13->smc_flash::@11#0] -- register_copy 
    // [1397] phi smc_flash::smc_attempts_total#21 = smc_flash::smc_attempts_total#17 [phi:smc_flash::@13->smc_flash::@11#1] -- register_copy 
    // [1397] phi smc_flash::smc_row_bytes#14 = smc_flash::smc_row_bytes#10 [phi:smc_flash::@13->smc_flash::@11#2] -- register_copy 
    // [1397] phi smc_flash::smc_ram_ptr#13 = smc_flash::smc_ram_ptr#10 [phi:smc_flash::@13->smc_flash::@11#3] -- register_copy 
    // [1397] phi smc_flash::smc_bytes_flashed#16 = smc_flash::smc_bytes_flashed#11 [phi:smc_flash::@13->smc_flash::@11#4] -- register_copy 
    // smc_flash::@11
  __b11:
    // while(smc_bytes_flashed < smc_bytes_total)
    // [1398] if(smc_flash::smc_bytes_flashed#16<smc_flash::smc_bytes_total#0) goto smc_flash::@12 -- vwuz1_lt_vwuz2_then_la1 
    lda.z smc_bytes_flashed+1
    cmp.z smc_bytes_total+1
    bcc __b10
    bne !+
    lda.z smc_bytes_flashed
    cmp.z smc_bytes_total
    bcc __b10
  !:
    // [1369] phi from smc_flash::@11 to smc_flash::@return [phi:smc_flash::@11->smc_flash::@return]
    // [1369] phi smc_flash::return#1 = smc_flash::smc_bytes_flashed#16 [phi:smc_flash::@11->smc_flash::@return#0] -- register_copy 
    rts
    // [1399] phi from smc_flash::@11 to smc_flash::@12 [phi:smc_flash::@11->smc_flash::@12]
  __b10:
    // [1399] phi smc_flash::y#20 = smc_flash::y#31 [phi:smc_flash::@11->smc_flash::@12#0] -- register_copy 
    // [1399] phi smc_flash::smc_attempts_total#17 = smc_flash::smc_attempts_total#21 [phi:smc_flash::@11->smc_flash::@12#1] -- register_copy 
    // [1399] phi smc_flash::smc_row_bytes#10 = smc_flash::smc_row_bytes#14 [phi:smc_flash::@11->smc_flash::@12#2] -- register_copy 
    // [1399] phi smc_flash::smc_ram_ptr#10 = smc_flash::smc_ram_ptr#13 [phi:smc_flash::@11->smc_flash::@12#3] -- register_copy 
    // [1399] phi smc_flash::smc_bytes_flashed#11 = smc_flash::smc_bytes_flashed#16 [phi:smc_flash::@11->smc_flash::@12#4] -- register_copy 
    // [1399] phi smc_flash::smc_attempts_flashed#19 = 0 [phi:smc_flash::@11->smc_flash::@12#5] -- vbum1=vbuc1 
    lda #0
    sta smc_attempts_flashed
    // [1399] phi smc_flash::smc_package_committed#2 = 0 [phi:smc_flash::@11->smc_flash::@12#6] -- vbuz1=vbuc1 
    sta.z smc_package_committed
    // smc_flash::@12
  __b12:
    // while(!smc_package_committed && smc_attempts_flashed < 10)
    // [1400] if(0!=smc_flash::smc_package_committed#2) goto smc_flash::@13 -- 0_neq_vbuz1_then_la1 
    lda.z smc_package_committed
    bne __b13
    // smc_flash::@60
    // [1401] if(smc_flash::smc_attempts_flashed#19<$a) goto smc_flash::@14 -- vbum1_lt_vbuc1_then_la1 
    lda smc_attempts_flashed
    cmp #$a
    bcc __b16
    // smc_flash::@13
  __b13:
    // if(smc_attempts_flashed >= 10)
    // [1402] if(smc_flash::smc_attempts_flashed#19<$a) goto smc_flash::@11 -- vbum1_lt_vbuc1_then_la1 
    lda smc_attempts_flashed
    cmp #$a
    bcc __b11
    // [1403] phi from smc_flash::@13 to smc_flash::@21 [phi:smc_flash::@13->smc_flash::@21]
    // smc_flash::@21
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1404] call snprintf_init
    // [770] phi from smc_flash::@21 to snprintf_init [phi:smc_flash::@21->snprintf_init]
    // [770] phi snprintf_init::s#25 = info_text [phi:smc_flash::@21->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1405] phi from smc_flash::@21 to smc_flash::@57 [phi:smc_flash::@21->smc_flash::@57]
    // smc_flash::@57
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1406] call printf_str
    // [775] phi from smc_flash::@57 to printf_str [phi:smc_flash::@57->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:smc_flash::@57->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = smc_flash::s10 [phi:smc_flash::@57->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@58
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1407] printf_uint::uvalue#12 = smc_flash::smc_bytes_flashed#11 -- vwum1=vwuz2 
    lda.z smc_bytes_flashed
    sta printf_uint.uvalue
    lda.z smc_bytes_flashed+1
    sta printf_uint.uvalue+1
    // [1408] call printf_uint
    // [809] phi from smc_flash::@58 to printf_uint [phi:smc_flash::@58->printf_uint]
    // [809] phi printf_uint::format_zero_padding#18 = 1 [phi:smc_flash::@58->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [809] phi printf_uint::format_min_length#18 = 4 [phi:smc_flash::@58->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [809] phi printf_uint::putc#18 = &snputc [phi:smc_flash::@58->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [809] phi printf_uint::format_radix#18 = HEXADECIMAL [phi:smc_flash::@58->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [809] phi printf_uint::uvalue#18 = printf_uint::uvalue#12 [phi:smc_flash::@58->printf_uint#4] -- register_copy 
    jsr printf_uint
    // smc_flash::@59
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1409] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1410] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1412] call display_action_text
    // [993] phi from smc_flash::@59 to display_action_text [phi:smc_flash::@59->display_action_text]
    // [993] phi display_action_text::info_text#19 = info_text [phi:smc_flash::@59->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    jmp __b2
    // [1413] phi from smc_flash::@60 to smc_flash::@14 [phi:smc_flash::@60->smc_flash::@14]
  __b16:
    // [1413] phi smc_flash::smc_bytes_checksum#2 = 0 [phi:smc_flash::@60->smc_flash::@14#0] -- vbuz1=vbuc1 
    lda #0
    sta.z smc_bytes_checksum
    // [1413] phi smc_flash::smc_ram_ptr#12 = smc_flash::smc_ram_ptr#10 [phi:smc_flash::@60->smc_flash::@14#1] -- register_copy 
    // [1413] phi smc_flash::smc_package_flashed#2 = 0 [phi:smc_flash::@60->smc_flash::@14#2] -- vwuz1=vwuc1 
    sta.z smc_package_flashed
    sta.z smc_package_flashed+1
    // smc_flash::@14
  __b14:
    // while(smc_package_flashed < SMC_PROGRESS_CELL)
    // [1414] if(smc_flash::smc_package_flashed#2<SMC_PROGRESS_CELL) goto smc_flash::@15 -- vwuz1_lt_vbuc1_then_la1 
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
    // [1415] smc_flash::$26 = smc_flash::smc_bytes_checksum#2 ^ $ff -- vbuz1=vbuz1_bxor_vbuc1 
    lda #$ff
    eor.z smc_flash__26
    sta.z smc_flash__26
    // (smc_bytes_checksum ^ 0xFF)+1
    // [1416] smc_flash::$27 = smc_flash::$26 + 1 -- vbuz1=vbuz1_plus_1 
    inc.z smc_flash__27
    // unsigned char smc_checksum_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, (smc_bytes_checksum ^ 0xFF)+1)
    // [1417] smc_flash::cx16_k_i2c_write_byte4_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte4_device
    // [1418] smc_flash::cx16_k_i2c_write_byte4_offset = $80 -- vbum1=vbuc1 
    lda #$80
    sta cx16_k_i2c_write_byte4_offset
    // [1419] smc_flash::cx16_k_i2c_write_byte4_value = smc_flash::$27 -- vbum1=vbuz2 
    lda.z smc_flash__27
    sta cx16_k_i2c_write_byte4_value
    // smc_flash::cx16_k_i2c_write_byte4
    // unsigned char result
    // [1420] smc_flash::cx16_k_i2c_write_byte4_result = 0 -- vbum1=vbuc1 
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
    // [1422] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1423] cx16_k_i2c_read_byte::offset = $81 -- vbum1=vbuc1 
    lda #$81
    sta cx16_k_i2c_read_byte.offset
    // [1424] call cx16_k_i2c_read_byte
    // Now send the commit command.
    jsr cx16_k_i2c_read_byte
    // [1425] cx16_k_i2c_read_byte::return#14 = cx16_k_i2c_read_byte::return#1
    // smc_flash::@48
    // [1426] smc_flash::smc_commit_result#0 = cx16_k_i2c_read_byte::return#14 -- vwum1=vwum2 
    lda cx16_k_i2c_read_byte.return
    sta smc_commit_result
    lda cx16_k_i2c_read_byte.return+1
    sta smc_commit_result+1
    // if(smc_commit_result == 1)
    // [1427] if(smc_flash::smc_commit_result#0==1) goto smc_flash::@18 -- vwum1_eq_vbuc1_then_la1 
    bne !+
    lda smc_commit_result
    cmp #1
    beq __b18
  !:
    // smc_flash::@17
    // smc_ram_ptr -= SMC_PROGRESS_CELL
    // [1428] smc_flash::smc_ram_ptr#2 = smc_flash::smc_ram_ptr#12 - SMC_PROGRESS_CELL -- pbuz1=pbuz1_minus_vbuc1 
    sec
    lda.z smc_ram_ptr
    sbc #SMC_PROGRESS_CELL
    sta.z smc_ram_ptr
    lda.z smc_ram_ptr+1
    sbc #0
    sta.z smc_ram_ptr+1
    // smc_attempts_flashed++;
    // [1429] smc_flash::smc_attempts_flashed#1 = ++ smc_flash::smc_attempts_flashed#19 -- vbum1=_inc_vbum1 
    inc smc_attempts_flashed
    // [1399] phi from smc_flash::@17 to smc_flash::@12 [phi:smc_flash::@17->smc_flash::@12]
    // [1399] phi smc_flash::y#20 = smc_flash::y#20 [phi:smc_flash::@17->smc_flash::@12#0] -- register_copy 
    // [1399] phi smc_flash::smc_attempts_total#17 = smc_flash::smc_attempts_total#17 [phi:smc_flash::@17->smc_flash::@12#1] -- register_copy 
    // [1399] phi smc_flash::smc_row_bytes#10 = smc_flash::smc_row_bytes#10 [phi:smc_flash::@17->smc_flash::@12#2] -- register_copy 
    // [1399] phi smc_flash::smc_ram_ptr#10 = smc_flash::smc_ram_ptr#2 [phi:smc_flash::@17->smc_flash::@12#3] -- register_copy 
    // [1399] phi smc_flash::smc_bytes_flashed#11 = smc_flash::smc_bytes_flashed#11 [phi:smc_flash::@17->smc_flash::@12#4] -- register_copy 
    // [1399] phi smc_flash::smc_attempts_flashed#19 = smc_flash::smc_attempts_flashed#1 [phi:smc_flash::@17->smc_flash::@12#5] -- register_copy 
    // [1399] phi smc_flash::smc_package_committed#2 = smc_flash::smc_package_committed#2 [phi:smc_flash::@17->smc_flash::@12#6] -- register_copy 
    jmp __b12
    // smc_flash::@18
  __b18:
    // if (smc_row_bytes == SMC_PROGRESS_ROW)
    // [1430] if(smc_flash::smc_row_bytes#10!=SMC_PROGRESS_ROW) goto smc_flash::@19 -- vwuz1_neq_vwuc1_then_la1 
    lda.z smc_row_bytes+1
    cmp #>SMC_PROGRESS_ROW
    bne __b19
    lda.z smc_row_bytes
    cmp #<SMC_PROGRESS_ROW
    bne __b19
    // smc_flash::@20
    // gotoxy(x, ++y);
    // [1431] smc_flash::y#1 = ++ smc_flash::y#20 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [1432] gotoxy::y#22 = smc_flash::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1433] call gotoxy
    // [573] phi from smc_flash::@20 to gotoxy [phi:smc_flash::@20->gotoxy]
    // [573] phi gotoxy::y#30 = gotoxy::y#22 [phi:smc_flash::@20->gotoxy#0] -- register_copy 
    // [573] phi gotoxy::x#30 = PROGRESS_X [phi:smc_flash::@20->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1434] phi from smc_flash::@20 to smc_flash::@19 [phi:smc_flash::@20->smc_flash::@19]
    // [1434] phi smc_flash::y#33 = smc_flash::y#1 [phi:smc_flash::@20->smc_flash::@19#0] -- register_copy 
    // [1434] phi smc_flash::smc_row_bytes#4 = 0 [phi:smc_flash::@20->smc_flash::@19#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z smc_row_bytes
    sta.z smc_row_bytes+1
    // [1434] phi from smc_flash::@18 to smc_flash::@19 [phi:smc_flash::@18->smc_flash::@19]
    // [1434] phi smc_flash::y#33 = smc_flash::y#20 [phi:smc_flash::@18->smc_flash::@19#0] -- register_copy 
    // [1434] phi smc_flash::smc_row_bytes#4 = smc_flash::smc_row_bytes#10 [phi:smc_flash::@18->smc_flash::@19#1] -- register_copy 
    // smc_flash::@19
  __b19:
    // cputc('+')
    // [1435] stackpush(char) = '+' -- _stackpushbyte_=vbuc1 
    lda #'+'
    pha
    // [1436] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_bytes_flashed += SMC_PROGRESS_CELL
    // [1438] smc_flash::smc_bytes_flashed#1 = smc_flash::smc_bytes_flashed#11 + SMC_PROGRESS_CELL -- vwuz1=vwuz1_plus_vbuc1 
    lda #SMC_PROGRESS_CELL
    clc
    adc.z smc_bytes_flashed
    sta.z smc_bytes_flashed
    bcc !+
    inc.z smc_bytes_flashed+1
  !:
    // smc_row_bytes += SMC_PROGRESS_CELL
    // [1439] smc_flash::smc_row_bytes#1 = smc_flash::smc_row_bytes#4 + SMC_PROGRESS_CELL -- vwuz1=vwuz1_plus_vbuc1 
    lda #SMC_PROGRESS_CELL
    clc
    adc.z smc_row_bytes
    sta.z smc_row_bytes
    bcc !+
    inc.z smc_row_bytes+1
  !:
    // smc_attempts_total += smc_attempts_flashed
    // [1440] smc_flash::smc_attempts_total#1 = smc_flash::smc_attempts_total#17 + smc_flash::smc_attempts_flashed#19 -- vwuz1=vwuz1_plus_vbum2 
    lda smc_attempts_flashed
    clc
    adc.z smc_attempts_total
    sta.z smc_attempts_total
    bcc !+
    inc.z smc_attempts_total+1
  !:
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1441] call snprintf_init
    // [770] phi from smc_flash::@19 to snprintf_init [phi:smc_flash::@19->snprintf_init]
    // [770] phi snprintf_init::s#25 = info_text [phi:smc_flash::@19->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1442] phi from smc_flash::@19 to smc_flash::@49 [phi:smc_flash::@19->smc_flash::@49]
    // smc_flash::@49
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1443] call printf_str
    // [775] phi from smc_flash::@49 to printf_str [phi:smc_flash::@49->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:smc_flash::@49->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = smc_flash::s6 [phi:smc_flash::@49->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@50
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1444] printf_uint::uvalue#9 = smc_flash::smc_bytes_flashed#1 -- vwum1=vwuz2 
    lda.z smc_bytes_flashed
    sta printf_uint.uvalue
    lda.z smc_bytes_flashed+1
    sta printf_uint.uvalue+1
    // [1445] call printf_uint
    // [809] phi from smc_flash::@50 to printf_uint [phi:smc_flash::@50->printf_uint]
    // [809] phi printf_uint::format_zero_padding#18 = 1 [phi:smc_flash::@50->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [809] phi printf_uint::format_min_length#18 = 5 [phi:smc_flash::@50->printf_uint#1] -- vbum1=vbuc1 
    lda #5
    sta printf_uint.format_min_length
    // [809] phi printf_uint::putc#18 = &snputc [phi:smc_flash::@50->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [809] phi printf_uint::format_radix#18 = DECIMAL [phi:smc_flash::@50->printf_uint#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uint.format_radix
    // [809] phi printf_uint::uvalue#18 = printf_uint::uvalue#9 [phi:smc_flash::@50->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1446] phi from smc_flash::@50 to smc_flash::@51 [phi:smc_flash::@50->smc_flash::@51]
    // smc_flash::@51
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1447] call printf_str
    // [775] phi from smc_flash::@51 to printf_str [phi:smc_flash::@51->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:smc_flash::@51->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = smc_flash::s7 [phi:smc_flash::@51->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@52
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1448] printf_uint::uvalue#10 = smc_flash::smc_bytes_total#0 -- vwum1=vwuz2 
    lda.z smc_bytes_total
    sta printf_uint.uvalue
    lda.z smc_bytes_total+1
    sta printf_uint.uvalue+1
    // [1449] call printf_uint
    // [809] phi from smc_flash::@52 to printf_uint [phi:smc_flash::@52->printf_uint]
    // [809] phi printf_uint::format_zero_padding#18 = 1 [phi:smc_flash::@52->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [809] phi printf_uint::format_min_length#18 = 5 [phi:smc_flash::@52->printf_uint#1] -- vbum1=vbuc1 
    lda #5
    sta printf_uint.format_min_length
    // [809] phi printf_uint::putc#18 = &snputc [phi:smc_flash::@52->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [809] phi printf_uint::format_radix#18 = DECIMAL [phi:smc_flash::@52->printf_uint#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uint.format_radix
    // [809] phi printf_uint::uvalue#18 = printf_uint::uvalue#10 [phi:smc_flash::@52->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1450] phi from smc_flash::@52 to smc_flash::@53 [phi:smc_flash::@52->smc_flash::@53]
    // smc_flash::@53
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1451] call printf_str
    // [775] phi from smc_flash::@53 to printf_str [phi:smc_flash::@53->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:smc_flash::@53->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = smc_flash::s8 [phi:smc_flash::@53->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@54
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1452] printf_uint::uvalue#11 = smc_flash::smc_attempts_total#1 -- vwum1=vwuz2 
    lda.z smc_attempts_total
    sta printf_uint.uvalue
    lda.z smc_attempts_total+1
    sta printf_uint.uvalue+1
    // [1453] call printf_uint
    // [809] phi from smc_flash::@54 to printf_uint [phi:smc_flash::@54->printf_uint]
    // [809] phi printf_uint::format_zero_padding#18 = 1 [phi:smc_flash::@54->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [809] phi printf_uint::format_min_length#18 = 2 [phi:smc_flash::@54->printf_uint#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uint.format_min_length
    // [809] phi printf_uint::putc#18 = &snputc [phi:smc_flash::@54->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [809] phi printf_uint::format_radix#18 = DECIMAL [phi:smc_flash::@54->printf_uint#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uint.format_radix
    // [809] phi printf_uint::uvalue#18 = printf_uint::uvalue#11 [phi:smc_flash::@54->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1454] phi from smc_flash::@54 to smc_flash::@55 [phi:smc_flash::@54->smc_flash::@55]
    // smc_flash::@55
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1455] call printf_str
    // [775] phi from smc_flash::@55 to printf_str [phi:smc_flash::@55->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:smc_flash::@55->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = smc_flash::s9 [phi:smc_flash::@55->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@56
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1456] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1457] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1459] call display_action_text
    // [993] phi from smc_flash::@56 to display_action_text [phi:smc_flash::@56->display_action_text]
    // [993] phi display_action_text::info_text#19 = info_text [phi:smc_flash::@56->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1399] phi from smc_flash::@56 to smc_flash::@12 [phi:smc_flash::@56->smc_flash::@12]
    // [1399] phi smc_flash::y#20 = smc_flash::y#33 [phi:smc_flash::@56->smc_flash::@12#0] -- register_copy 
    // [1399] phi smc_flash::smc_attempts_total#17 = smc_flash::smc_attempts_total#1 [phi:smc_flash::@56->smc_flash::@12#1] -- register_copy 
    // [1399] phi smc_flash::smc_row_bytes#10 = smc_flash::smc_row_bytes#1 [phi:smc_flash::@56->smc_flash::@12#2] -- register_copy 
    // [1399] phi smc_flash::smc_ram_ptr#10 = smc_flash::smc_ram_ptr#12 [phi:smc_flash::@56->smc_flash::@12#3] -- register_copy 
    // [1399] phi smc_flash::smc_bytes_flashed#11 = smc_flash::smc_bytes_flashed#1 [phi:smc_flash::@56->smc_flash::@12#4] -- register_copy 
    // [1399] phi smc_flash::smc_attempts_flashed#19 = smc_flash::smc_attempts_flashed#19 [phi:smc_flash::@56->smc_flash::@12#5] -- register_copy 
    // [1399] phi smc_flash::smc_package_committed#2 = 1 [phi:smc_flash::@56->smc_flash::@12#6] -- vbuz1=vbuc1 
    lda #1
    sta.z smc_package_committed
    jmp __b12
    // smc_flash::@15
  __b15:
    // unsigned char smc_byte_upload = *smc_ram_ptr
    // [1460] smc_flash::smc_byte_upload#0 = *smc_flash::smc_ram_ptr#12 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (smc_ram_ptr),y
    sta smc_byte_upload
    // smc_ram_ptr++;
    // [1461] smc_flash::smc_ram_ptr#1 = ++ smc_flash::smc_ram_ptr#12 -- pbuz1=_inc_pbuz1 
    inc.z smc_ram_ptr
    bne !+
    inc.z smc_ram_ptr+1
  !:
    // smc_bytes_checksum += smc_byte_upload
    // [1462] smc_flash::smc_bytes_checksum#1 = smc_flash::smc_bytes_checksum#2 + smc_flash::smc_byte_upload#0 -- vbuz1=vbuz1_plus_vbum2 
    lda smc_byte_upload
    clc
    adc.z smc_bytes_checksum
    sta.z smc_bytes_checksum
    // unsigned char smc_upload_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, smc_byte_upload)
    // [1463] smc_flash::cx16_k_i2c_write_byte3_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte3_device
    // [1464] smc_flash::cx16_k_i2c_write_byte3_offset = $80 -- vbum1=vbuc1 
    lda #$80
    sta cx16_k_i2c_write_byte3_offset
    // [1465] smc_flash::cx16_k_i2c_write_byte3_value = smc_flash::smc_byte_upload#0 -- vbum1=vbum2 
    lda smc_byte_upload
    sta cx16_k_i2c_write_byte3_value
    // smc_flash::cx16_k_i2c_write_byte3
    // unsigned char result
    // [1466] smc_flash::cx16_k_i2c_write_byte3_result = 0 -- vbum1=vbuc1 
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
    // [1468] smc_flash::smc_package_flashed#1 = ++ smc_flash::smc_package_flashed#2 -- vwuz1=_inc_vwuz1 
    inc.z smc_package_flashed
    bne !+
    inc.z smc_package_flashed+1
  !:
    // [1413] phi from smc_flash::@23 to smc_flash::@14 [phi:smc_flash::@23->smc_flash::@14]
    // [1413] phi smc_flash::smc_bytes_checksum#2 = smc_flash::smc_bytes_checksum#1 [phi:smc_flash::@23->smc_flash::@14#0] -- register_copy 
    // [1413] phi smc_flash::smc_ram_ptr#12 = smc_flash::smc_ram_ptr#1 [phi:smc_flash::@23->smc_flash::@14#1] -- register_copy 
    // [1413] phi smc_flash::smc_package_flashed#2 = smc_flash::smc_package_flashed#1 [phi:smc_flash::@23->smc_flash::@14#2] -- register_copy 
    jmp __b14
    // [1469] phi from smc_flash::@7 to smc_flash::@8 [phi:smc_flash::@7->smc_flash::@8]
    // smc_flash::@8
  __b8:
    // wait_moment()
    // [1470] call wait_moment
    // [977] phi from smc_flash::@8 to wait_moment [phi:smc_flash::@8->wait_moment]
    jsr wait_moment
    // [1471] phi from smc_flash::@8 to smc_flash::@36 [phi:smc_flash::@8->smc_flash::@36]
    // smc_flash::@36
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1472] call snprintf_init
    // [770] phi from smc_flash::@36 to snprintf_init [phi:smc_flash::@36->snprintf_init]
    // [770] phi snprintf_init::s#25 = info_text [phi:smc_flash::@36->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1473] phi from smc_flash::@36 to smc_flash::@37 [phi:smc_flash::@36->smc_flash::@37]
    // smc_flash::@37
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1474] call printf_str
    // [775] phi from smc_flash::@37 to printf_str [phi:smc_flash::@37->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:smc_flash::@37->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = smc_flash::s3 [phi:smc_flash::@37->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@38
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1475] printf_uchar::uvalue#3 = smc_flash::smc_bootloader_activation_countdown#12 -- vbum1=vbum2 
    lda smc_bootloader_activation_countdown_1
    sta printf_uchar.uvalue
    // [1476] call printf_uchar
    // [982] phi from smc_flash::@38 to printf_uchar [phi:smc_flash::@38->printf_uchar]
    // [982] phi printf_uchar::format_zero_padding#11 = 0 [phi:smc_flash::@38->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [982] phi printf_uchar::format_min_length#11 = 0 [phi:smc_flash::@38->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [982] phi printf_uchar::putc#11 = &snputc [phi:smc_flash::@38->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [982] phi printf_uchar::format_radix#11 = DECIMAL [phi:smc_flash::@38->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [982] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#3 [phi:smc_flash::@38->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1477] phi from smc_flash::@38 to smc_flash::@39 [phi:smc_flash::@38->smc_flash::@39]
    // smc_flash::@39
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1478] call printf_str
    // [775] phi from smc_flash::@39 to printf_str [phi:smc_flash::@39->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:smc_flash::@39->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = s7 [phi:smc_flash::@39->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s7
    sta.z printf_str.s
    lda #>@s7
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@40
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1479] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1480] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1482] call display_action_text
    // [993] phi from smc_flash::@40 to display_action_text [phi:smc_flash::@40->display_action_text]
    // [993] phi display_action_text::info_text#19 = info_text [phi:smc_flash::@40->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_flash::@41
    // smc_bootloader_activation_countdown--;
    // [1483] smc_flash::smc_bootloader_activation_countdown#3 = -- smc_flash::smc_bootloader_activation_countdown#12 -- vbum1=_dec_vbum1 
    dec smc_bootloader_activation_countdown_1
    // [1373] phi from smc_flash::@41 to smc_flash::@7 [phi:smc_flash::@41->smc_flash::@7]
    // [1373] phi smc_flash::smc_bootloader_activation_countdown#12 = smc_flash::smc_bootloader_activation_countdown#3 [phi:smc_flash::@41->smc_flash::@7#0] -- register_copy 
    jmp __b7
    // smc_flash::@4
  __b4:
    // unsigned int smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1484] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1485] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [1486] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [1487] cx16_k_i2c_read_byte::return#12 = cx16_k_i2c_read_byte::return#1
    // smc_flash::@30
    // [1488] smc_flash::smc_bootloader_not_activated1#0 = cx16_k_i2c_read_byte::return#12 -- vwum1=vwum2 
    lda cx16_k_i2c_read_byte.return
    sta smc_bootloader_not_activated1
    lda cx16_k_i2c_read_byte.return+1
    sta smc_bootloader_not_activated1+1
    // if(smc_bootloader_not_activated)
    // [1489] if(0!=smc_flash::smc_bootloader_not_activated1#0) goto smc_flash::@5 -- 0_neq_vwum1_then_la1 
    lda smc_bootloader_not_activated1
    ora smc_bootloader_not_activated1+1
    bne __b5
    jmp __b9
    // [1490] phi from smc_flash::@30 to smc_flash::@5 [phi:smc_flash::@30->smc_flash::@5]
    // smc_flash::@5
  __b5:
    // wait_moment()
    // [1491] call wait_moment
    // [977] phi from smc_flash::@5 to wait_moment [phi:smc_flash::@5->wait_moment]
    jsr wait_moment
    // [1492] phi from smc_flash::@5 to smc_flash::@31 [phi:smc_flash::@5->smc_flash::@31]
    // smc_flash::@31
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1493] call snprintf_init
    // [770] phi from smc_flash::@31 to snprintf_init [phi:smc_flash::@31->snprintf_init]
    // [770] phi snprintf_init::s#25 = info_text [phi:smc_flash::@31->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1494] phi from smc_flash::@31 to smc_flash::@32 [phi:smc_flash::@31->smc_flash::@32]
    // smc_flash::@32
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1495] call printf_str
    // [775] phi from smc_flash::@32 to printf_str [phi:smc_flash::@32->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:smc_flash::@32->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = smc_flash::s1 [phi:smc_flash::@32->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@33
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1496] printf_uchar::uvalue#2 = smc_flash::smc_bootloader_activation_countdown#10 -- vbum1=vbum2 
    lda smc_bootloader_activation_countdown
    sta printf_uchar.uvalue
    // [1497] call printf_uchar
    // [982] phi from smc_flash::@33 to printf_uchar [phi:smc_flash::@33->printf_uchar]
    // [982] phi printf_uchar::format_zero_padding#11 = 1 [phi:smc_flash::@33->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [982] phi printf_uchar::format_min_length#11 = 3 [phi:smc_flash::@33->printf_uchar#1] -- vbum1=vbuc1 
    lda #3
    sta printf_uchar.format_min_length
    // [982] phi printf_uchar::putc#11 = &snputc [phi:smc_flash::@33->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [982] phi printf_uchar::format_radix#11 = DECIMAL [phi:smc_flash::@33->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [982] phi printf_uchar::uvalue#11 = printf_uchar::uvalue#2 [phi:smc_flash::@33->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1498] phi from smc_flash::@33 to smc_flash::@34 [phi:smc_flash::@33->smc_flash::@34]
    // smc_flash::@34
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1499] call printf_str
    // [775] phi from smc_flash::@34 to printf_str [phi:smc_flash::@34->printf_str]
    // [775] phi printf_str::putc#73 = &snputc [phi:smc_flash::@34->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [775] phi printf_str::s#73 = smc_flash::s2 [phi:smc_flash::@34->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@35
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1500] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1501] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1503] call display_action_text
    // [993] phi from smc_flash::@35 to display_action_text [phi:smc_flash::@35->display_action_text]
    // [993] phi display_action_text::info_text#19 = info_text [phi:smc_flash::@35->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_flash::@6
    // smc_bootloader_activation_countdown--;
    // [1504] smc_flash::smc_bootloader_activation_countdown#2 = -- smc_flash::smc_bootloader_activation_countdown#10 -- vbum1=_dec_vbum1 
    dec smc_bootloader_activation_countdown
    // [1371] phi from smc_flash::@6 to smc_flash::@3 [phi:smc_flash::@6->smc_flash::@3]
    // [1371] phi smc_flash::smc_bootloader_activation_countdown#10 = smc_flash::smc_bootloader_activation_countdown#2 [phi:smc_flash::@6->smc_flash::@3#0] -- register_copy 
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
// __mem() char util_wait_key(__zp($54) char *info_text, __zp($78) char *filter)
util_wait_key: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 0
    .label util_wait_key__9 = $c9
    .label info_text = $54
    .label ch = $bd
    .label filter = $78
    // display_action_text(info_text)
    // [1506] display_action_text::info_text#7 = util_wait_key::info_text#2
    // [1507] call display_action_text
    // [993] phi from util_wait_key to display_action_text [phi:util_wait_key->display_action_text]
    // [993] phi display_action_text::info_text#19 = display_action_text::info_text#7 [phi:util_wait_key->display_action_text#0] -- register_copy 
    jsr display_action_text
    // util_wait_key::bank_get_bram1
    // return BRAM;
    // [1508] util_wait_key::bram#0 = BRAM -- vbum1=vbuz2 
    lda.z BRAM
    sta bram
    // util_wait_key::bank_get_brom1
    // return BROM;
    // [1509] util_wait_key::bank_get_brom1_return#0 = BROM -- vbum1=vbuz2 
    lda.z BROM
    sta bank_get_brom1_return
    // util_wait_key::bank_set_bram1
    // BRAM = bank
    // [1510] BRAM = util_wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // util_wait_key::bank_set_brom1
    // BROM = bank
    // [1511] BROM = util_wait_key::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [1512] phi from util_wait_key::@2 util_wait_key::@5 util_wait_key::bank_set_brom1 to util_wait_key::kbhit1 [phi:util_wait_key::@2/util_wait_key::@5/util_wait_key::bank_set_brom1->util_wait_key::kbhit1]
    // util_wait_key::kbhit1
  kbhit1:
    // util_wait_key::kbhit1_cbm_k_clrchn1
    // asm
    // asm { jsrCBM_CLRCHN  }
    jsr CBM_CLRCHN
    // [1514] phi from util_wait_key::kbhit1_cbm_k_clrchn1 to util_wait_key::kbhit1_@2 [phi:util_wait_key::kbhit1_cbm_k_clrchn1->util_wait_key::kbhit1_@2]
    // util_wait_key::kbhit1_@2
    // cbm_k_getin()
    // [1515] call cbm_k_getin
    jsr cbm_k_getin
    // [1516] cbm_k_getin::return#2 = cbm_k_getin::return#1
    // util_wait_key::@4
    // [1517] util_wait_key::ch#4 = cbm_k_getin::return#2 -- vwuz1=vbum2 
    lda cbm_k_getin.return
    sta.z ch
    lda #0
    sta.z ch+1
    // util_wait_key::@3
    // if (filter)
    // [1518] if((char *)0!=util_wait_key::filter#12) goto util_wait_key::@1 -- pbuc1_neq_pbuz1_then_la1 
    // if there is a filter, check the filter, otherwise return ch.
    lda.z filter+1
    cmp #>0
    bne __b1
    lda.z filter
    cmp #<0
    bne __b1
    // util_wait_key::@2
    // if(ch)
    // [1519] if(0!=util_wait_key::ch#4) goto util_wait_key::bank_set_bram2 -- 0_neq_vwuz1_then_la1 
    lda.z ch
    ora.z ch+1
    bne bank_set_bram2
    jmp kbhit1
    // util_wait_key::bank_set_bram2
  bank_set_bram2:
    // BRAM = bank
    // [1520] BRAM = util_wait_key::bram#0 -- vbuz1=vbum2 
    lda bram
    sta.z BRAM
    // util_wait_key::bank_set_brom2
    // BROM = bank
    // [1521] BROM = util_wait_key::bank_get_brom1_return#0 -- vbuz1=vbum2 
    lda bank_get_brom1_return
    sta.z BROM
    // util_wait_key::@return
    // }
    // [1522] return 
    rts
    // util_wait_key::@1
  __b1:
    // strchr(filter, ch)
    // [1523] strchr::str#0 = (const void *)util_wait_key::filter#12 -- pvoz1=pvoz2 
    lda.z filter
    sta.z strchr.str
    lda.z filter+1
    sta.z strchr.str+1
    // [1524] strchr::c#0 = util_wait_key::ch#4 -- vbum1=vwuz2 
    lda.z ch
    sta strchr.c
    // [1525] call strchr
    // [1529] phi from util_wait_key::@1 to strchr [phi:util_wait_key::@1->strchr]
    // [1529] phi strchr::c#4 = strchr::c#0 [phi:util_wait_key::@1->strchr#0] -- register_copy 
    // [1529] phi strchr::str#2 = strchr::str#0 [phi:util_wait_key::@1->strchr#1] -- register_copy 
    jsr strchr
    // strchr(filter, ch)
    // [1526] strchr::return#3 = strchr::return#2
    // util_wait_key::@5
    // [1527] util_wait_key::$9 = strchr::return#3
    // if(strchr(filter, ch) != NULL)
    // [1528] if(util_wait_key::$9!=0) goto util_wait_key::bank_set_bram2 -- pvoz1_neq_0_then_la1 
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
// __zp($c9) void * strchr(__zp($c9) const void *str, __mem() char c)
strchr: {
    .label ptr = $c9
    .label return = $c9
    .label str = $c9
    // [1530] strchr::ptr#6 = (char *)strchr::str#2
    // [1531] phi from strchr strchr::@3 to strchr::@1 [phi:strchr/strchr::@3->strchr::@1]
    // [1531] phi strchr::ptr#2 = strchr::ptr#6 [phi:strchr/strchr::@3->strchr::@1#0] -- register_copy 
    // strchr::@1
  __b1:
    // while(*ptr)
    // [1532] if(0!=*strchr::ptr#2) goto strchr::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (ptr),y
    cmp #0
    bne __b2
    // [1533] phi from strchr::@1 to strchr::@return [phi:strchr::@1->strchr::@return]
    // [1533] phi strchr::return#2 = (void *) 0 [phi:strchr::@1->strchr::@return#0] -- pvoz1=pvoc1 
    tya
    sta.z return
    sta.z return+1
    // strchr::@return
    // }
    // [1534] return 
    rts
    // strchr::@2
  __b2:
    // if(*ptr==c)
    // [1535] if(*strchr::ptr#2!=strchr::c#4) goto strchr::@3 -- _deref_pbuz1_neq_vbum2_then_la1 
    ldy #0
    lda (ptr),y
    cmp c
    bne __b3
    // strchr::@4
    // [1536] strchr::return#8 = (void *)strchr::ptr#2
    // [1533] phi from strchr::@4 to strchr::@return [phi:strchr::@4->strchr::@return]
    // [1533] phi strchr::return#2 = strchr::return#8 [phi:strchr::@4->strchr::@return#0] -- register_copy 
    rts
    // strchr::@3
  __b3:
    // ptr++;
    // [1537] strchr::ptr#1 = ++ strchr::ptr#2 -- pbuz1=_inc_pbuz1 
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
    // [1539] call display_info_rom
    // [1016] phi from display_info_cx16_rom to display_info_rom [phi:display_info_cx16_rom->display_info_rom]
    // [1016] phi display_info_rom::info_text#16 = display_info_cx16_rom::info_text#0 [phi:display_info_cx16_rom->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_rom.info_text
    lda #>info_text
    sta.z display_info_rom.info_text+1
    // [1016] phi display_info_rom::rom_chip#16 = 0 [phi:display_info_cx16_rom->display_info_rom#1] -- vbuz1=vbuc1 
    lda #0
    sta.z display_info_rom.rom_chip
    // [1016] phi display_info_rom::info_status#16 = STATUS_ISSUE [phi:display_info_cx16_rom->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // display_info_cx16_rom::@return
    // }
    // [1540] return 
    rts
}
  // strncpy
/// Copies up to n characters from the string pointed to, by src to dst.
/// In a case where the length of src is less than that of n, the remainder of dst will be padded with null bytes.
/// @param dst ? This is the pointer to the destination array where the content is to be copied.
/// @param src ? This is the string to be copied.
/// @param n ? The number of characters to be copied from source.
/// @return The destination
// char * strncpy(__zp($36) char *dst, __zp($38) const char *src, __mem() unsigned int n)
strncpy: {
    .label dst = $36
    .label src = $38
    // [1542] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [1542] phi strncpy::dst#3 = strncpy::dst#8 [phi:strncpy->strncpy::@1#0] -- register_copy 
    // [1542] phi strncpy::src#3 = strncpy::src#6 [phi:strncpy->strncpy::@1#1] -- register_copy 
    // [1542] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwum1=vwuc1 
    lda #<0
    sta i
    sta i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [1543] if(strncpy::i#2<strncpy::n#3) goto strncpy::@2 -- vwum1_lt_vwum2_then_la1 
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
    // [1544] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [1545] strncpy::c#0 = *strncpy::src#3 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta c
    // if(c)
    // [1546] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbum1_then_la1 
    beq __b3
    // strncpy::@4
    // src++;
    // [1547] strncpy::src#0 = ++ strncpy::src#3 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [1548] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [1548] phi strncpy::src#7 = strncpy::src#3 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [1549] *strncpy::dst#3 = strncpy::c#0 -- _deref_pbuz1=vbum2 
    lda c
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [1550] strncpy::dst#0 = ++ strncpy::dst#3 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [1551] strncpy::i#1 = ++ strncpy::i#2 -- vwum1=_inc_vwum1 
    inc i
    bne !+
    inc i+1
  !:
    // [1542] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [1542] phi strncpy::dst#3 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [1542] phi strncpy::src#3 = strncpy::src#7 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [1542] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
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
// void display_info_led(__zp($ba) char x, __zp($4c) char y, __zp($c1) char tc, char bc)
display_info_led: {
    .label tc = $c1
    .label y = $4c
    .label x = $ba
    // textcolor(tc)
    // [1553] textcolor::color#13 = display_info_led::tc#4 -- vbum1=vbuz2 
    lda.z tc
    sta textcolor.color
    // [1554] call textcolor
    // [555] phi from display_info_led to textcolor [phi:display_info_led->textcolor]
    // [555] phi textcolor::color#18 = textcolor::color#13 [phi:display_info_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [1555] phi from display_info_led to display_info_led::@1 [phi:display_info_led->display_info_led::@1]
    // display_info_led::@1
    // bgcolor(bc)
    // [1556] call bgcolor
    // [560] phi from display_info_led::@1 to bgcolor [phi:display_info_led::@1->bgcolor]
    // [560] phi bgcolor::color#14 = BLUE [phi:display_info_led::@1->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_info_led::@2
    // cputcxy(x, y, VERA_CHR_UR)
    // [1557] cputcxy::x#11 = display_info_led::x#4 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [1558] cputcxy::y#11 = display_info_led::y#4 -- vbum1=vbuz2 
    lda.z y
    sta cputcxy.y
    // [1559] call cputcxy
    // [1781] phi from display_info_led::@2 to cputcxy [phi:display_info_led::@2->cputcxy]
    // [1781] phi cputcxy::c#15 = $7c [phi:display_info_led::@2->cputcxy#0] -- vbum1=vbuc1 
    lda #$7c
    sta cputcxy.c
    // [1781] phi cputcxy::y#15 = cputcxy::y#11 [phi:display_info_led::@2->cputcxy#1] -- register_copy 
    // [1781] phi cputcxy::x#15 = cputcxy::x#11 [phi:display_info_led::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [1560] phi from display_info_led::@2 to display_info_led::@3 [phi:display_info_led::@2->display_info_led::@3]
    // display_info_led::@3
    // textcolor(WHITE)
    // [1561] call textcolor
    // [555] phi from display_info_led::@3 to textcolor [phi:display_info_led::@3->textcolor]
    // [555] phi textcolor::color#18 = WHITE [phi:display_info_led::@3->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // display_info_led::@return
    // }
    // [1562] return 
    rts
}
  // screenlayer
// --- layer management in VERA ---
// void screenlayer(char layer, __mem() char mapbase, __mem() char config)
screenlayer: {
    .label screenlayer__0 = $bb
    .label screenlayer__1 = $b9
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [1563] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [1564] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [1565] *((char *)&__conio+2) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+2
    // mapbase >> 7
    // [1566] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbuz1=vbum2_ror_7 
    lda mapbase
    rol
    rol
    and #1
    sta.z screenlayer__0
    // __conio.mapbase_bank = mapbase >> 7
    // [1567] *((char *)&__conio+5) = screenlayer::$0 -- _deref_pbuc1=vbuz1 
    sta __conio+5
    // (mapbase)<<1
    // [1568] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbuz1=vbum2_rol_1 
    lda mapbase
    asl
    sta.z screenlayer__1
    // MAKEWORD((mapbase)<<1,0)
    // [1569] screenlayer::$2 = screenlayer::$1 w= 0 -- vwum1=vbuz2_word_vbuc1 
    lda #0
    ldy.z screenlayer__1
    sty screenlayer__2+1
    sta screenlayer__2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [1570] *((unsigned int *)&__conio+3) = screenlayer::$2 -- _deref_pwuc1=vwum1 
    sta __conio+3
    tya
    sta __conio+3+1
    // config & VERA_LAYER_WIDTH_MASK
    // [1571] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbum1=vbum2_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and config
    sta screenlayer__7
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [1572] screenlayer::$8 = screenlayer::$7 >> 4 -- vbum1=vbum1_ror_4 
    lda screenlayer__8
    lsr
    lsr
    lsr
    lsr
    sta screenlayer__8
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [1573] *((char *)&__conio+8) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbum1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+8
    // config & VERA_LAYER_HEIGHT_MASK
    // [1574] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbum1=vbum2_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and config
    sta screenlayer__5
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [1575] screenlayer::$6 = screenlayer::$5 >> 6 -- vbum1=vbum1_ror_6 
    lda screenlayer__6
    rol
    rol
    rol
    and #3
    sta screenlayer__6
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [1576] *((char *)&__conio+9) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbum1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+9
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [1577] screenlayer::$16 = screenlayer::$8 << 1 -- vbum1=vbum1_rol_1 
    asl screenlayer__16
    // [1578] *((unsigned int *)&__conio+$a) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbum1 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    ldy screenlayer__16
    lda VERA_LAYER_SKIP,y
    sta __conio+$a
    lda VERA_LAYER_SKIP+1,y
    sta __conio+$a+1
    // vera_dc_hscale_temp == 0x80
    // [1579] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vbom1=vbum2_eq_vbuc1 
    lda vera_dc_hscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta screenlayer__9
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [1580] screenlayer::$18 = (char)screenlayer::$9
    // [1581] screenlayer::$10 = $28 << screenlayer::$18 -- vbum1=vbuc1_rol_vbum1 
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
    // [1582] screenlayer::$11 = screenlayer::$10 - 1 -- vbum1=vbum1_minus_1 
    dec screenlayer__11
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [1583] *((char *)&__conio+6) = screenlayer::$11 -- _deref_pbuc1=vbum1 
    lda screenlayer__11
    sta __conio+6
    // vera_dc_vscale_temp == 0x80
    // [1584] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vbom1=vbum2_eq_vbuc1 
    lda vera_dc_vscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta screenlayer__12
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [1585] screenlayer::$19 = (char)screenlayer::$12
    // [1586] screenlayer::$13 = $1e << screenlayer::$19 -- vbum1=vbuc1_rol_vbum1 
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
    // [1587] screenlayer::$14 = screenlayer::$13 - 1 -- vbum1=vbum1_minus_1 
    dec screenlayer__14
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [1588] *((char *)&__conio+7) = screenlayer::$14 -- _deref_pbuc1=vbum1 
    lda screenlayer__14
    sta __conio+7
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [1589] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta mapbase_offset
    lda __conio+3+1
    sta mapbase_offset+1
    // [1590] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [1590] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [1590] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbum1=vbuc1 
    lda #0
    sta y
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [1591] if(screenlayer::y#2<=*((char *)&__conio+7)) goto screenlayer::@2 -- vbum1_le__deref_pbuc1_then_la1 
    lda __conio+7
    cmp y
    bcs __b2
    // screenlayer::@return
    // }
    // [1592] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [1593] screenlayer::$17 = screenlayer::y#2 << 1 -- vbum1=vbum2_rol_1 
    lda y
    asl
    sta screenlayer__17
    // [1594] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbum1=vwum2 
    tay
    lda mapbase_offset
    sta __conio+$15,y
    lda mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [1595] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda mapbase_offset
    adc __conio+$a
    sta mapbase_offset
    lda mapbase_offset+1
    adc __conio+$a+1
    sta mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [1596] screenlayer::y#1 = ++ screenlayer::y#2 -- vbum1=_inc_vbum1 
    inc y
    // [1590] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [1590] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [1590] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
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
    // [1597] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [1598] if(0!=((char *)&__conio+$f)[*((char *)&__conio+2)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [1599] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // [1600] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [1601] call gotoxy
    // [573] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [573] phi gotoxy::y#30 = 0 [phi:cscroll::@3->gotoxy#0] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.y
    // [573] phi gotoxy::x#30 = 0 [phi:cscroll::@3->gotoxy#1] -- vbum1=vbuc1 
    sta gotoxy.x
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [1602] return 
    rts
    // [1603] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [1604] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [1605] gotoxy::y#3 = *((char *)&__conio+7) -- vbum1=_deref_pbuc1 
    lda __conio+7
    sta gotoxy.y
    // [1606] call gotoxy
    // [573] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [573] phi gotoxy::y#30 = gotoxy::y#3 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [573] phi gotoxy::x#30 = 0 [phi:cscroll::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.x
    jsr gotoxy
    // [1607] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [1608] call clearline
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
    // [1609] ((char *)&__conio+$f)[*((char *)&__conio+2)] = scroll::onoff#0 -- pbuc1_derefidx_(_deref_pbuc2)=vbuc3 
    lda #onoff
    ldy __conio+2
    sta __conio+$f,y
    // scroll::@return
    // }
    // [1610] return 
    rts
}
  // clrscr
// clears the screen and moves the cursor to the upper left-hand corner of the screen.
clrscr: {
    // unsigned int line_text = __conio.mapbase_offset
    // [1611] clrscr::line_text#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta line_text
    lda __conio+3+1
    sta line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1612] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [1613] clrscr::$0 = *((char *)&__conio+5) | VERA_INC_1 -- vbum1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta clrscr__0
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1614] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [1615] clrscr::l#0 = *((char *)&__conio+9) -- vbum1=_deref_pbuc1 
    lda __conio+9
    sta l
    // [1616] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [1616] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [1616] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [1617] clrscr::$1 = byte0  clrscr::ch#0 -- vbum1=_byte0_vwum2 
    lda ch
    sta clrscr__1
    // *VERA_ADDRX_L = BYTE0(ch)
    // [1618] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbum1 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [1619] clrscr::$2 = byte1  clrscr::ch#0 -- vbum1=_byte1_vwum2 
    lda ch+1
    sta clrscr__2
    // *VERA_ADDRX_M = BYTE1(ch)
    // [1620] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth+1
    // [1621] clrscr::c#0 = *((char *)&__conio+8) + 1 -- vbum1=_deref_pbuc1_plus_1 
    lda __conio+8
    inc
    sta c
    // [1622] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [1622] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [1623] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1624] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [1625] clrscr::c#1 = -- clrscr::c#2 -- vbum1=_dec_vbum1 
    dec c
    // while(c)
    // [1626] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [1627] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda line_text
    adc __conio+$a
    sta line_text
    lda line_text+1
    adc __conio+$a+1
    sta line_text+1
    // l--;
    // [1628] clrscr::l#1 = -- clrscr::l#4 -- vbum1=_dec_vbum1 
    dec l
    // while(l)
    // [1629] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbum1_then_la1 
    lda l
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [1630] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y = 0
    // [1631] *((char *)&__conio+1) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+1
    // __conio.offset = __conio.mapbase_offset
    // [1632] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+3) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+3
    sta __conio+$13
    lda __conio+3+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [1633] return 
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
    .label w = $7e
    .label h = $7d
    .label mask = $41
    .label c = $3c
    // unsigned char w = x1 - x0
    // [1635] display_frame::w#0 = display_frame::x1#16 - display_frame::x#0 -- vbuz1=vbum2_minus_vbum3 
    lda x1
    sec
    sbc x
    sta.z w
    // unsigned char h = y1 - y0
    // [1636] display_frame::h#0 = display_frame::y1#16 - display_frame::y#0 -- vbuz1=vbum2_minus_vbum3 
    lda y1
    sec
    sbc y
    sta.z h
    // unsigned char mask = display_frame_maskxy(x, y)
    // [1637] display_frame_maskxy::x#0 = display_frame::x#0
    // [1638] display_frame_maskxy::y#0 = display_frame::y#0
    // [1639] call display_frame_maskxy
    // [2274] phi from display_frame to display_frame_maskxy [phi:display_frame->display_frame_maskxy]
    // [2274] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#0 [phi:display_frame->display_frame_maskxy#0] -- vbum1=vbum2 
    lda display_frame_maskxy.y
    sta display_frame_maskxy.cpeekcxy1_y
    // [2274] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#0 [phi:display_frame->display_frame_maskxy#1] -- vbum1=vbum2 
    lda display_frame_maskxy.x
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // unsigned char mask = display_frame_maskxy(x, y)
    // [1640] display_frame_maskxy::return#13 = display_frame_maskxy::return#12
    // display_frame::@13
    // [1641] display_frame::mask#0 = display_frame_maskxy::return#13
    // mask |= 0b0110
    // [1642] display_frame::mask#1 = display_frame::mask#0 | 6 -- vbuz1=vbuz1_bor_vbuc1 
    lda #6
    ora.z mask
    sta.z mask
    // unsigned char c = display_frame_char(mask)
    // [1643] display_frame_char::mask#0 = display_frame::mask#1
    // [1644] call display_frame_char
  // Add a corner.
    // [2300] phi from display_frame::@13 to display_frame_char [phi:display_frame::@13->display_frame_char]
    // [2300] phi display_frame_char::mask#10 = display_frame_char::mask#0 [phi:display_frame::@13->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // unsigned char c = display_frame_char(mask)
    // [1645] display_frame_char::return#13 = display_frame_char::return#12
    // display_frame::@14
    // [1646] display_frame::c#0 = display_frame_char::return#13
    // cputcxy(x, y, c)
    // [1647] cputcxy::x#0 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1648] cputcxy::y#0 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [1649] cputcxy::c#0 = display_frame::c#0 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [1650] call cputcxy
    // [1781] phi from display_frame::@14 to cputcxy [phi:display_frame::@14->cputcxy]
    // [1781] phi cputcxy::c#15 = cputcxy::c#0 [phi:display_frame::@14->cputcxy#0] -- register_copy 
    // [1781] phi cputcxy::y#15 = cputcxy::y#0 [phi:display_frame::@14->cputcxy#1] -- register_copy 
    // [1781] phi cputcxy::x#15 = cputcxy::x#0 [phi:display_frame::@14->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@15
    // if(w>=2)
    // [1651] if(display_frame::w#0<2) goto display_frame::@36 -- vbuz1_lt_vbuc1_then_la1 
    lda.z w
    cmp #2
    bcs !__b36+
    jmp __b36
  !__b36:
    // display_frame::@2
    // x++;
    // [1652] display_frame::x#1 = ++ display_frame::x#0 -- vbum1=_inc_vbum2 
    lda x
    inc
    sta x_1
    // [1653] phi from display_frame::@2 display_frame::@21 to display_frame::@4 [phi:display_frame::@2/display_frame::@21->display_frame::@4]
    // [1653] phi display_frame::x#10 = display_frame::x#1 [phi:display_frame::@2/display_frame::@21->display_frame::@4#0] -- register_copy 
    // display_frame::@4
  __b4:
    // while(x < x1)
    // [1654] if(display_frame::x#10<display_frame::x1#16) goto display_frame::@5 -- vbum1_lt_vbum2_then_la1 
    lda x_1
    cmp x1
    bcs !__b5+
    jmp __b5
  !__b5:
    // [1655] phi from display_frame::@36 display_frame::@4 to display_frame::@1 [phi:display_frame::@36/display_frame::@4->display_frame::@1]
    // [1655] phi display_frame::x#24 = display_frame::x#30 [phi:display_frame::@36/display_frame::@4->display_frame::@1#0] -- register_copy 
    // display_frame::@1
  __b1:
    // display_frame_maskxy(x, y)
    // [1656] display_frame_maskxy::x#1 = display_frame::x#24
    // [1657] display_frame_maskxy::y#1 = display_frame::y#0
    // [1658] call display_frame_maskxy
    // [2274] phi from display_frame::@1 to display_frame_maskxy [phi:display_frame::@1->display_frame_maskxy]
    // [2274] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#1 [phi:display_frame::@1->display_frame_maskxy#0] -- vbum1=vbum2 
    lda display_frame_maskxy.y
    sta display_frame_maskxy.cpeekcxy1_y
    // [2274] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#1 [phi:display_frame::@1->display_frame_maskxy#1] -- vbum1=vbum2 
    lda display_frame_maskxy.x_1
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1659] display_frame_maskxy::return#14 = display_frame_maskxy::return#12
    // display_frame::@16
    // mask = display_frame_maskxy(x, y)
    // [1660] display_frame::mask#2 = display_frame_maskxy::return#14
    // mask |= 0b0011
    // [1661] display_frame::mask#3 = display_frame::mask#2 | 3 -- vbuz1=vbuz1_bor_vbuc1 
    lda #3
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [1662] display_frame_char::mask#1 = display_frame::mask#3
    // [1663] call display_frame_char
    // [2300] phi from display_frame::@16 to display_frame_char [phi:display_frame::@16->display_frame_char]
    // [2300] phi display_frame_char::mask#10 = display_frame_char::mask#1 [phi:display_frame::@16->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1664] display_frame_char::return#14 = display_frame_char::return#12
    // display_frame::@17
    // c = display_frame_char(mask)
    // [1665] display_frame::c#1 = display_frame_char::return#14
    // cputcxy(x, y, c)
    // [1666] cputcxy::x#1 = display_frame::x#24 -- vbum1=vbum2 
    lda x_1
    sta cputcxy.x
    // [1667] cputcxy::y#1 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [1668] cputcxy::c#1 = display_frame::c#1 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [1669] call cputcxy
    // [1781] phi from display_frame::@17 to cputcxy [phi:display_frame::@17->cputcxy]
    // [1781] phi cputcxy::c#15 = cputcxy::c#1 [phi:display_frame::@17->cputcxy#0] -- register_copy 
    // [1781] phi cputcxy::y#15 = cputcxy::y#1 [phi:display_frame::@17->cputcxy#1] -- register_copy 
    // [1781] phi cputcxy::x#15 = cputcxy::x#1 [phi:display_frame::@17->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@18
    // if(h>=2)
    // [1670] if(display_frame::h#0<2) goto display_frame::@return -- vbuz1_lt_vbuc1_then_la1 
    lda.z h
    cmp #2
    bcc __breturn
    // display_frame::@3
    // y++;
    // [1671] display_frame::y#1 = ++ display_frame::y#0 -- vbum1=_inc_vbum2 
    lda y
    inc
    sta y_1
    // [1672] phi from display_frame::@27 display_frame::@3 to display_frame::@6 [phi:display_frame::@27/display_frame::@3->display_frame::@6]
    // [1672] phi display_frame::y#10 = display_frame::y#2 [phi:display_frame::@27/display_frame::@3->display_frame::@6#0] -- register_copy 
    // display_frame::@6
  __b6:
    // while(y < y1)
    // [1673] if(display_frame::y#10<display_frame::y1#16) goto display_frame::@7 -- vbum1_lt_vbum2_then_la1 
    lda y_1
    cmp y1
    bcs !__b7+
    jmp __b7
  !__b7:
    // display_frame::@8
    // display_frame_maskxy(x, y)
    // [1674] display_frame_maskxy::x#5 = display_frame::x#0
    // [1675] display_frame_maskxy::y#5 = display_frame::y#10
    // [1676] call display_frame_maskxy
    // [2274] phi from display_frame::@8 to display_frame_maskxy [phi:display_frame::@8->display_frame_maskxy]
    // [2274] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#5 [phi:display_frame::@8->display_frame_maskxy#0] -- vbum1=vbum2 
    lda display_frame_maskxy.y_1
    sta display_frame_maskxy.cpeekcxy1_y
    // [2274] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#5 [phi:display_frame::@8->display_frame_maskxy#1] -- vbum1=vbum2 
    lda display_frame_maskxy.x
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1677] display_frame_maskxy::return#18 = display_frame_maskxy::return#12
    // display_frame::@28
    // mask = display_frame_maskxy(x, y)
    // [1678] display_frame::mask#10 = display_frame_maskxy::return#18
    // mask |= 0b1100
    // [1679] display_frame::mask#11 = display_frame::mask#10 | $c -- vbuz1=vbuz1_bor_vbuc1 
    lda #$c
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [1680] display_frame_char::mask#5 = display_frame::mask#11
    // [1681] call display_frame_char
    // [2300] phi from display_frame::@28 to display_frame_char [phi:display_frame::@28->display_frame_char]
    // [2300] phi display_frame_char::mask#10 = display_frame_char::mask#5 [phi:display_frame::@28->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1682] display_frame_char::return#18 = display_frame_char::return#12
    // display_frame::@29
    // c = display_frame_char(mask)
    // [1683] display_frame::c#5 = display_frame_char::return#18
    // cputcxy(x, y, c)
    // [1684] cputcxy::x#5 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1685] cputcxy::y#5 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [1686] cputcxy::c#5 = display_frame::c#5 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [1687] call cputcxy
    // [1781] phi from display_frame::@29 to cputcxy [phi:display_frame::@29->cputcxy]
    // [1781] phi cputcxy::c#15 = cputcxy::c#5 [phi:display_frame::@29->cputcxy#0] -- register_copy 
    // [1781] phi cputcxy::y#15 = cputcxy::y#5 [phi:display_frame::@29->cputcxy#1] -- register_copy 
    // [1781] phi cputcxy::x#15 = cputcxy::x#5 [phi:display_frame::@29->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@30
    // if(w>=2)
    // [1688] if(display_frame::w#0<2) goto display_frame::@10 -- vbuz1_lt_vbuc1_then_la1 
    lda.z w
    cmp #2
    bcc __b10
    // display_frame::@9
    // x++;
    // [1689] display_frame::x#4 = ++ display_frame::x#0 -- vbum1=_inc_vbum1 
    inc x
    // [1690] phi from display_frame::@35 display_frame::@9 to display_frame::@11 [phi:display_frame::@35/display_frame::@9->display_frame::@11]
    // [1690] phi display_frame::x#18 = display_frame::x#5 [phi:display_frame::@35/display_frame::@9->display_frame::@11#0] -- register_copy 
    // display_frame::@11
  __b11:
    // while(x < x1)
    // [1691] if(display_frame::x#18<display_frame::x1#16) goto display_frame::@12 -- vbum1_lt_vbum2_then_la1 
    lda x
    cmp x1
    bcc __b12
    // [1692] phi from display_frame::@11 display_frame::@30 to display_frame::@10 [phi:display_frame::@11/display_frame::@30->display_frame::@10]
    // [1692] phi display_frame::x#15 = display_frame::x#18 [phi:display_frame::@11/display_frame::@30->display_frame::@10#0] -- register_copy 
    // display_frame::@10
  __b10:
    // display_frame_maskxy(x, y)
    // [1693] display_frame_maskxy::x#6 = display_frame::x#15
    // [1694] display_frame_maskxy::y#6 = display_frame::y#10
    // [1695] call display_frame_maskxy
    // [2274] phi from display_frame::@10 to display_frame_maskxy [phi:display_frame::@10->display_frame_maskxy]
    // [2274] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#6 [phi:display_frame::@10->display_frame_maskxy#0] -- vbum1=vbum2 
    lda display_frame_maskxy.y_1
    sta display_frame_maskxy.cpeekcxy1_y
    // [2274] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#6 [phi:display_frame::@10->display_frame_maskxy#1] -- vbum1=vbum2 
    lda display_frame_maskxy.x
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1696] display_frame_maskxy::return#19 = display_frame_maskxy::return#12
    // display_frame::@31
    // mask = display_frame_maskxy(x, y)
    // [1697] display_frame::mask#12 = display_frame_maskxy::return#19
    // mask |= 0b1001
    // [1698] display_frame::mask#13 = display_frame::mask#12 | 9 -- vbuz1=vbuz1_bor_vbuc1 
    lda #9
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [1699] display_frame_char::mask#6 = display_frame::mask#13
    // [1700] call display_frame_char
    // [2300] phi from display_frame::@31 to display_frame_char [phi:display_frame::@31->display_frame_char]
    // [2300] phi display_frame_char::mask#10 = display_frame_char::mask#6 [phi:display_frame::@31->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1701] display_frame_char::return#19 = display_frame_char::return#12
    // display_frame::@32
    // c = display_frame_char(mask)
    // [1702] display_frame::c#6 = display_frame_char::return#19
    // cputcxy(x, y, c)
    // [1703] cputcxy::x#6 = display_frame::x#15 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1704] cputcxy::y#6 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [1705] cputcxy::c#6 = display_frame::c#6 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [1706] call cputcxy
    // [1781] phi from display_frame::@32 to cputcxy [phi:display_frame::@32->cputcxy]
    // [1781] phi cputcxy::c#15 = cputcxy::c#6 [phi:display_frame::@32->cputcxy#0] -- register_copy 
    // [1781] phi cputcxy::y#15 = cputcxy::y#6 [phi:display_frame::@32->cputcxy#1] -- register_copy 
    // [1781] phi cputcxy::x#15 = cputcxy::x#6 [phi:display_frame::@32->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@return
  __breturn:
    // }
    // [1707] return 
    rts
    // display_frame::@12
  __b12:
    // display_frame_maskxy(x, y)
    // [1708] display_frame_maskxy::x#7 = display_frame::x#18
    // [1709] display_frame_maskxy::y#7 = display_frame::y#10
    // [1710] call display_frame_maskxy
    // [2274] phi from display_frame::@12 to display_frame_maskxy [phi:display_frame::@12->display_frame_maskxy]
    // [2274] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#7 [phi:display_frame::@12->display_frame_maskxy#0] -- vbum1=vbum2 
    lda display_frame_maskxy.y_1
    sta display_frame_maskxy.cpeekcxy1_y
    // [2274] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#7 [phi:display_frame::@12->display_frame_maskxy#1] -- vbum1=vbum2 
    lda display_frame_maskxy.x
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1711] display_frame_maskxy::return#20 = display_frame_maskxy::return#12
    // display_frame::@33
    // mask = display_frame_maskxy(x, y)
    // [1712] display_frame::mask#14 = display_frame_maskxy::return#20
    // mask |= 0b0101
    // [1713] display_frame::mask#15 = display_frame::mask#14 | 5 -- vbuz1=vbuz1_bor_vbuc1 
    lda #5
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [1714] display_frame_char::mask#7 = display_frame::mask#15
    // [1715] call display_frame_char
    // [2300] phi from display_frame::@33 to display_frame_char [phi:display_frame::@33->display_frame_char]
    // [2300] phi display_frame_char::mask#10 = display_frame_char::mask#7 [phi:display_frame::@33->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1716] display_frame_char::return#20 = display_frame_char::return#12
    // display_frame::@34
    // c = display_frame_char(mask)
    // [1717] display_frame::c#7 = display_frame_char::return#20
    // cputcxy(x, y, c)
    // [1718] cputcxy::x#7 = display_frame::x#18 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1719] cputcxy::y#7 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [1720] cputcxy::c#7 = display_frame::c#7 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [1721] call cputcxy
    // [1781] phi from display_frame::@34 to cputcxy [phi:display_frame::@34->cputcxy]
    // [1781] phi cputcxy::c#15 = cputcxy::c#7 [phi:display_frame::@34->cputcxy#0] -- register_copy 
    // [1781] phi cputcxy::y#15 = cputcxy::y#7 [phi:display_frame::@34->cputcxy#1] -- register_copy 
    // [1781] phi cputcxy::x#15 = cputcxy::x#7 [phi:display_frame::@34->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@35
    // x++;
    // [1722] display_frame::x#5 = ++ display_frame::x#18 -- vbum1=_inc_vbum1 
    inc x
    jmp __b11
    // display_frame::@7
  __b7:
    // display_frame_maskxy(x0, y)
    // [1723] display_frame_maskxy::x#3 = display_frame::x#0
    // [1724] display_frame_maskxy::y#3 = display_frame::y#10
    // [1725] call display_frame_maskxy
    // [2274] phi from display_frame::@7 to display_frame_maskxy [phi:display_frame::@7->display_frame_maskxy]
    // [2274] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#3 [phi:display_frame::@7->display_frame_maskxy#0] -- vbum1=vbum2 
    lda display_frame_maskxy.y_1
    sta display_frame_maskxy.cpeekcxy1_y
    // [2274] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#3 [phi:display_frame::@7->display_frame_maskxy#1] -- vbum1=vbum2 
    lda display_frame_maskxy.x
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x0, y)
    // [1726] display_frame_maskxy::return#16 = display_frame_maskxy::return#12
    // display_frame::@22
    // mask = display_frame_maskxy(x0, y)
    // [1727] display_frame::mask#6 = display_frame_maskxy::return#16
    // mask |= 0b1010
    // [1728] display_frame::mask#7 = display_frame::mask#6 | $a -- vbuz1=vbuz1_bor_vbuc1 
    lda #$a
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [1729] display_frame_char::mask#3 = display_frame::mask#7
    // [1730] call display_frame_char
    // [2300] phi from display_frame::@22 to display_frame_char [phi:display_frame::@22->display_frame_char]
    // [2300] phi display_frame_char::mask#10 = display_frame_char::mask#3 [phi:display_frame::@22->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1731] display_frame_char::return#16 = display_frame_char::return#12
    // display_frame::@23
    // c = display_frame_char(mask)
    // [1732] display_frame::c#3 = display_frame_char::return#16
    // cputcxy(x0, y, c)
    // [1733] cputcxy::x#3 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [1734] cputcxy::y#3 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [1735] cputcxy::c#3 = display_frame::c#3 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [1736] call cputcxy
    // [1781] phi from display_frame::@23 to cputcxy [phi:display_frame::@23->cputcxy]
    // [1781] phi cputcxy::c#15 = cputcxy::c#3 [phi:display_frame::@23->cputcxy#0] -- register_copy 
    // [1781] phi cputcxy::y#15 = cputcxy::y#3 [phi:display_frame::@23->cputcxy#1] -- register_copy 
    // [1781] phi cputcxy::x#15 = cputcxy::x#3 [phi:display_frame::@23->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@24
    // display_frame_maskxy(x1, y)
    // [1737] display_frame_maskxy::x#4 = display_frame::x1#16
    // [1738] display_frame_maskxy::y#4 = display_frame::y#10
    // [1739] call display_frame_maskxy
    // [2274] phi from display_frame::@24 to display_frame_maskxy [phi:display_frame::@24->display_frame_maskxy]
    // [2274] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#4 [phi:display_frame::@24->display_frame_maskxy#0] -- vbum1=vbum2 
    lda display_frame_maskxy.y_1
    sta display_frame_maskxy.cpeekcxy1_y
    // [2274] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#4 [phi:display_frame::@24->display_frame_maskxy#1] -- vbum1=vbum2 
    lda display_frame_maskxy.x_2
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x1, y)
    // [1740] display_frame_maskxy::return#17 = display_frame_maskxy::return#12
    // display_frame::@25
    // mask = display_frame_maskxy(x1, y)
    // [1741] display_frame::mask#8 = display_frame_maskxy::return#17
    // mask |= 0b1010
    // [1742] display_frame::mask#9 = display_frame::mask#8 | $a -- vbuz1=vbuz1_bor_vbuc1 
    lda #$a
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [1743] display_frame_char::mask#4 = display_frame::mask#9
    // [1744] call display_frame_char
    // [2300] phi from display_frame::@25 to display_frame_char [phi:display_frame::@25->display_frame_char]
    // [2300] phi display_frame_char::mask#10 = display_frame_char::mask#4 [phi:display_frame::@25->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1745] display_frame_char::return#17 = display_frame_char::return#12
    // display_frame::@26
    // c = display_frame_char(mask)
    // [1746] display_frame::c#4 = display_frame_char::return#17
    // cputcxy(x1, y, c)
    // [1747] cputcxy::x#4 = display_frame::x1#16 -- vbum1=vbum2 
    lda x1
    sta cputcxy.x
    // [1748] cputcxy::y#4 = display_frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [1749] cputcxy::c#4 = display_frame::c#4 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [1750] call cputcxy
    // [1781] phi from display_frame::@26 to cputcxy [phi:display_frame::@26->cputcxy]
    // [1781] phi cputcxy::c#15 = cputcxy::c#4 [phi:display_frame::@26->cputcxy#0] -- register_copy 
    // [1781] phi cputcxy::y#15 = cputcxy::y#4 [phi:display_frame::@26->cputcxy#1] -- register_copy 
    // [1781] phi cputcxy::x#15 = cputcxy::x#4 [phi:display_frame::@26->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@27
    // y++;
    // [1751] display_frame::y#2 = ++ display_frame::y#10 -- vbum1=_inc_vbum1 
    inc y_1
    jmp __b6
    // display_frame::@5
  __b5:
    // display_frame_maskxy(x, y)
    // [1752] display_frame_maskxy::x#2 = display_frame::x#10
    // [1753] display_frame_maskxy::y#2 = display_frame::y#0
    // [1754] call display_frame_maskxy
    // [2274] phi from display_frame::@5 to display_frame_maskxy [phi:display_frame::@5->display_frame_maskxy]
    // [2274] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#2 [phi:display_frame::@5->display_frame_maskxy#0] -- vbum1=vbum2 
    lda display_frame_maskxy.y
    sta display_frame_maskxy.cpeekcxy1_y
    // [2274] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#2 [phi:display_frame::@5->display_frame_maskxy#1] -- vbum1=vbum2 
    lda display_frame_maskxy.x_1
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1755] display_frame_maskxy::return#15 = display_frame_maskxy::return#12
    // display_frame::@19
    // mask = display_frame_maskxy(x, y)
    // [1756] display_frame::mask#4 = display_frame_maskxy::return#15
    // mask |= 0b0101
    // [1757] display_frame::mask#5 = display_frame::mask#4 | 5 -- vbuz1=vbuz1_bor_vbuc1 
    lda #5
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [1758] display_frame_char::mask#2 = display_frame::mask#5
    // [1759] call display_frame_char
    // [2300] phi from display_frame::@19 to display_frame_char [phi:display_frame::@19->display_frame_char]
    // [2300] phi display_frame_char::mask#10 = display_frame_char::mask#2 [phi:display_frame::@19->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1760] display_frame_char::return#15 = display_frame_char::return#12
    // display_frame::@20
    // c = display_frame_char(mask)
    // [1761] display_frame::c#2 = display_frame_char::return#15
    // cputcxy(x, y, c)
    // [1762] cputcxy::x#2 = display_frame::x#10 -- vbum1=vbum2 
    lda x_1
    sta cputcxy.x
    // [1763] cputcxy::y#2 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [1764] cputcxy::c#2 = display_frame::c#2 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [1765] call cputcxy
    // [1781] phi from display_frame::@20 to cputcxy [phi:display_frame::@20->cputcxy]
    // [1781] phi cputcxy::c#15 = cputcxy::c#2 [phi:display_frame::@20->cputcxy#0] -- register_copy 
    // [1781] phi cputcxy::y#15 = cputcxy::y#2 [phi:display_frame::@20->cputcxy#1] -- register_copy 
    // [1781] phi cputcxy::x#15 = cputcxy::x#2 [phi:display_frame::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@21
    // x++;
    // [1766] display_frame::x#2 = ++ display_frame::x#10 -- vbum1=_inc_vbum1 
    inc x_1
    jmp __b4
    // display_frame::@36
  __b36:
    // [1767] display_frame::x#30 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta x_1
    jmp __b1
  .segment Data
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
    // [1769] phi from cputs cputs::@2 to cputs::@1 [phi:cputs/cputs::@2->cputs::@1]
    // [1769] phi cputs::s#2 = cputs::s#1 [phi:cputs/cputs::@2->cputs::@1#0] -- register_copy 
    // cputs::@1
  __b1:
    // while(c=*s++)
    // [1770] cputs::c#1 = *cputs::s#2 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta c
    // [1771] cputs::s#0 = ++ cputs::s#2 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [1772] if(0!=cputs::c#1) goto cputs::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // cputs::@return
    // }
    // [1773] return 
    rts
    // cputs::@2
  __b2:
    // cputc(c)
    // [1774] stackpush(char) = cputs::c#1 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [1775] callexecute cputc  -- call_vprc1 
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
    // [1777] wherex::return#0 = *((char *)&__conio) -- vbum1=_deref_pbuc1 
    lda __conio
    sta return
    // wherex::@return
    // }
    // [1778] return 
    rts
  .segment Data
    return: .byte 0
}
.segment Code
  // wherey
// Return the y position of the cursor
wherey: {
    // return __conio.cursor_y;
    // [1779] wherey::return#0 = *((char *)&__conio+1) -- vbum1=_deref_pbuc1 
    lda __conio+1
    sta return
    // wherey::@return
    // }
    // [1780] return 
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
    // [1782] gotoxy::x#0 = cputcxy::x#15 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1783] gotoxy::y#0 = cputcxy::y#15 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1784] call gotoxy
    // [573] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [573] phi gotoxy::y#30 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [573] phi gotoxy::x#30 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [1785] stackpush(char) = cputcxy::c#15 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [1786] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [1788] return 
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
// void display_smc_led(__zp($c1) char c)
display_smc_led: {
    .label c = $c1
    // display_chip_led(CHIP_SMC_X+1, CHIP_SMC_Y, CHIP_SMC_W, c, BLUE)
    // [1790] display_chip_led::tc#0 = display_smc_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_chip_led.tc
    // [1791] call display_chip_led
    // [2315] phi from display_smc_led to display_chip_led [phi:display_smc_led->display_chip_led]
    // [2315] phi display_chip_led::w#7 = 5 [phi:display_smc_led->display_chip_led#0] -- vbuz1=vbuc1 
    lda #5
    sta.z display_chip_led.w
    // [2315] phi display_chip_led::x#7 = 1+1 [phi:display_smc_led->display_chip_led#1] -- vbuz1=vbuc1 
    lda #1+1
    sta.z display_chip_led.x
    // [2315] phi display_chip_led::tc#3 = display_chip_led::tc#0 [phi:display_smc_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_smc_led::@1
    // display_info_led(INFO_X-2, INFO_Y, c, BLUE)
    // [1792] display_info_led::tc#0 = display_smc_led::c#2
    // [1793] call display_info_led
    // [1552] phi from display_smc_led::@1 to display_info_led [phi:display_smc_led::@1->display_info_led]
    // [1552] phi display_info_led::y#4 = $11 [phi:display_smc_led::@1->display_info_led#0] -- vbuz1=vbuc1 
    lda #$11
    sta.z display_info_led.y
    // [1552] phi display_info_led::x#4 = 4-2 [phi:display_smc_led::@1->display_info_led#1] -- vbuz1=vbuc1 
    lda #4-2
    sta.z display_info_led.x
    // [1552] phi display_info_led::tc#4 = display_info_led::tc#0 [phi:display_smc_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_smc_led::@return
    // }
    // [1794] return 
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
// void display_print_chip(__mem() char x, char y, __mem() char w, __zp($bd) char *text)
display_print_chip: {
    .label y = 3+2+1+1+1+1+1+1+1+1
    .label text = $bd
    .label text_1 = $56
    .label text_2 = $3a
    .label text_3 = $bf
    .label text_4 = $e4
    // display_chip_line(x, y++, w, *text++)
    // [1796] display_chip_line::x#0 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [1797] display_chip_line::w#0 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_line.w
    // [1798] display_chip_line::c#0 = *display_print_chip::text#11 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_2),y
    sta.z display_chip_line.c
    // [1799] call display_chip_line
    // [2333] phi from display_print_chip to display_chip_line [phi:display_print_chip->display_chip_line]
    // [2333] phi display_chip_line::c#15 = display_chip_line::c#0 [phi:display_print_chip->display_chip_line#0] -- register_copy 
    // [2333] phi display_chip_line::w#10 = display_chip_line::w#0 [phi:display_print_chip->display_chip_line#1] -- register_copy 
    // [2333] phi display_chip_line::y#16 = 3+2 [phi:display_print_chip->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2
    sta display_chip_line.y
    // [2333] phi display_chip_line::x#16 = display_chip_line::x#0 [phi:display_print_chip->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@1
    // display_chip_line(x, y++, w, *text++);
    // [1800] display_print_chip::text#0 = ++ display_print_chip::text#11 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_2
    adc #1
    sta.z text
    lda.z text_2+1
    adc #0
    sta.z text+1
    // display_chip_line(x, y++, w, *text++)
    // [1801] display_chip_line::x#1 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [1802] display_chip_line::w#1 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_line.w
    // [1803] display_chip_line::c#1 = *display_print_chip::text#0 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text),y
    sta.z display_chip_line.c
    // [1804] call display_chip_line
    // [2333] phi from display_print_chip::@1 to display_chip_line [phi:display_print_chip::@1->display_chip_line]
    // [2333] phi display_chip_line::c#15 = display_chip_line::c#1 [phi:display_print_chip::@1->display_chip_line#0] -- register_copy 
    // [2333] phi display_chip_line::w#10 = display_chip_line::w#1 [phi:display_print_chip::@1->display_chip_line#1] -- register_copy 
    // [2333] phi display_chip_line::y#16 = ++3+2 [phi:display_print_chip::@1->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1
    sta display_chip_line.y
    // [2333] phi display_chip_line::x#16 = display_chip_line::x#1 [phi:display_print_chip::@1->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@2
    // display_chip_line(x, y++, w, *text++);
    // [1805] display_print_chip::text#1 = ++ display_print_chip::text#0 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text
    adc #1
    sta.z text_1
    lda.z text+1
    adc #0
    sta.z text_1+1
    // display_chip_line(x, y++, w, *text++)
    // [1806] display_chip_line::x#2 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [1807] display_chip_line::w#2 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_line.w
    // [1808] display_chip_line::c#2 = *display_print_chip::text#1 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_1),y
    sta.z display_chip_line.c
    // [1809] call display_chip_line
    // [2333] phi from display_print_chip::@2 to display_chip_line [phi:display_print_chip::@2->display_chip_line]
    // [2333] phi display_chip_line::c#15 = display_chip_line::c#2 [phi:display_print_chip::@2->display_chip_line#0] -- register_copy 
    // [2333] phi display_chip_line::w#10 = display_chip_line::w#2 [phi:display_print_chip::@2->display_chip_line#1] -- register_copy 
    // [2333] phi display_chip_line::y#16 = ++++3+2 [phi:display_print_chip::@2->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1
    sta display_chip_line.y
    // [2333] phi display_chip_line::x#16 = display_chip_line::x#2 [phi:display_print_chip::@2->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@3
    // display_chip_line(x, y++, w, *text++);
    // [1810] display_print_chip::text#15 = ++ display_print_chip::text#1 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_1
    adc #1
    sta.z text_3
    lda.z text_1+1
    adc #0
    sta.z text_3+1
    // display_chip_line(x, y++, w, *text++)
    // [1811] display_chip_line::x#3 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [1812] display_chip_line::w#3 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_line.w
    // [1813] display_chip_line::c#3 = *display_print_chip::text#15 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_3),y
    sta.z display_chip_line.c
    // [1814] call display_chip_line
    // [2333] phi from display_print_chip::@3 to display_chip_line [phi:display_print_chip::@3->display_chip_line]
    // [2333] phi display_chip_line::c#15 = display_chip_line::c#3 [phi:display_print_chip::@3->display_chip_line#0] -- register_copy 
    // [2333] phi display_chip_line::w#10 = display_chip_line::w#3 [phi:display_print_chip::@3->display_chip_line#1] -- register_copy 
    // [2333] phi display_chip_line::y#16 = ++++++3+2 [phi:display_print_chip::@3->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1
    sta display_chip_line.y
    // [2333] phi display_chip_line::x#16 = display_chip_line::x#3 [phi:display_print_chip::@3->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@4
    // display_chip_line(x, y++, w, *text++);
    // [1815] display_print_chip::text#16 = ++ display_print_chip::text#15 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_3
    adc #1
    sta.z text_4
    lda.z text_3+1
    adc #0
    sta.z text_4+1
    // display_chip_line(x, y++, w, *text++)
    // [1816] display_chip_line::x#4 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [1817] display_chip_line::w#4 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_line.w
    // [1818] display_chip_line::c#4 = *display_print_chip::text#16 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_4),y
    sta.z display_chip_line.c
    // [1819] call display_chip_line
    // [2333] phi from display_print_chip::@4 to display_chip_line [phi:display_print_chip::@4->display_chip_line]
    // [2333] phi display_chip_line::c#15 = display_chip_line::c#4 [phi:display_print_chip::@4->display_chip_line#0] -- register_copy 
    // [2333] phi display_chip_line::w#10 = display_chip_line::w#4 [phi:display_print_chip::@4->display_chip_line#1] -- register_copy 
    // [2333] phi display_chip_line::y#16 = ++++++++3+2 [phi:display_print_chip::@4->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1
    sta display_chip_line.y
    // [2333] phi display_chip_line::x#16 = display_chip_line::x#4 [phi:display_print_chip::@4->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@5
    // display_chip_line(x, y++, w, *text++);
    // [1820] display_print_chip::text#17 = ++ display_print_chip::text#16 -- pbum1=_inc_pbuz2 
    clc
    lda.z text_4
    adc #1
    sta text_5
    lda.z text_4+1
    adc #0
    sta text_5+1
    // display_chip_line(x, y++, w, *text++)
    // [1821] display_chip_line::x#5 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [1822] display_chip_line::w#5 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_line.w
    // [1823] display_chip_line::c#5 = *display_print_chip::text#17 -- vbuz1=_deref_pbum2 
    ldy text_5
    sty.z $fe
    ldy text_5+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta.z display_chip_line.c
    // [1824] call display_chip_line
    // [2333] phi from display_print_chip::@5 to display_chip_line [phi:display_print_chip::@5->display_chip_line]
    // [2333] phi display_chip_line::c#15 = display_chip_line::c#5 [phi:display_print_chip::@5->display_chip_line#0] -- register_copy 
    // [2333] phi display_chip_line::w#10 = display_chip_line::w#5 [phi:display_print_chip::@5->display_chip_line#1] -- register_copy 
    // [2333] phi display_chip_line::y#16 = ++++++++++3+2 [phi:display_print_chip::@5->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1+1
    sta display_chip_line.y
    // [2333] phi display_chip_line::x#16 = display_chip_line::x#5 [phi:display_print_chip::@5->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@6
    // display_chip_line(x, y++, w, *text++);
    // [1825] display_print_chip::text#18 = ++ display_print_chip::text#17 -- pbum1=_inc_pbum2 
    clc
    lda text_5
    adc #1
    sta text_6
    lda text_5+1
    adc #0
    sta text_6+1
    // display_chip_line(x, y++, w, *text++)
    // [1826] display_chip_line::x#6 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [1827] display_chip_line::w#6 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_line.w
    // [1828] display_chip_line::c#6 = *display_print_chip::text#18 -- vbuz1=_deref_pbum2 
    ldy text_6
    sty.z $fe
    ldy text_6+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta.z display_chip_line.c
    // [1829] call display_chip_line
    // [2333] phi from display_print_chip::@6 to display_chip_line [phi:display_print_chip::@6->display_chip_line]
    // [2333] phi display_chip_line::c#15 = display_chip_line::c#6 [phi:display_print_chip::@6->display_chip_line#0] -- register_copy 
    // [2333] phi display_chip_line::w#10 = display_chip_line::w#6 [phi:display_print_chip::@6->display_chip_line#1] -- register_copy 
    // [2333] phi display_chip_line::y#16 = ++++++++++++3+2 [phi:display_print_chip::@6->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1+1+1
    sta display_chip_line.y
    // [2333] phi display_chip_line::x#16 = display_chip_line::x#6 [phi:display_print_chip::@6->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@7
    // display_chip_line(x, y++, w, *text++);
    // [1830] display_print_chip::text#19 = ++ display_print_chip::text#18 -- pbum1=_inc_pbum1 
    inc text_6
    bne !+
    inc text_6+1
  !:
    // display_chip_line(x, y++, w, *text++)
    // [1831] display_chip_line::x#7 = display_print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta display_chip_line.x
    // [1832] display_chip_line::w#7 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_line.w
    // [1833] display_chip_line::c#7 = *display_print_chip::text#19 -- vbuz1=_deref_pbum2 
    ldy text_6
    sty.z $fe
    ldy text_6+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta.z display_chip_line.c
    // [1834] call display_chip_line
    // [2333] phi from display_print_chip::@7 to display_chip_line [phi:display_print_chip::@7->display_chip_line]
    // [2333] phi display_chip_line::c#15 = display_chip_line::c#7 [phi:display_print_chip::@7->display_chip_line#0] -- register_copy 
    // [2333] phi display_chip_line::w#10 = display_chip_line::w#7 [phi:display_print_chip::@7->display_chip_line#1] -- register_copy 
    // [2333] phi display_chip_line::y#16 = ++++++++++++++3+2 [phi:display_print_chip::@7->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1+1+1+1
    sta display_chip_line.y
    // [2333] phi display_chip_line::x#16 = display_chip_line::x#7 [phi:display_print_chip::@7->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@8
    // display_chip_end(x, y++, w)
    // [1835] display_chip_end::x#0 = display_print_chip::x#10
    // [1836] display_chip_end::w#0 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_end.w
    // [1837] call display_chip_end
    jsr display_chip_end
    // display_print_chip::@return
    // }
    // [1838] return 
    rts
  .segment Data
    .label x = util_wait_key.return
    .label text_5 = fopen.fopen__11
    .label text_6 = fopen.cbm_k_setnam1_fopen__0
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
    // [1840] display_chip_led::tc#1 = display_vera_led::c#2 -- vbuz1=vbum2 
    lda c
    sta.z display_chip_led.tc
    // [1841] call display_chip_led
    // [2315] phi from display_vera_led to display_chip_led [phi:display_vera_led->display_chip_led]
    // [2315] phi display_chip_led::w#7 = 8 [phi:display_vera_led->display_chip_led#0] -- vbuz1=vbuc1 
    lda #8
    sta.z display_chip_led.w
    // [2315] phi display_chip_led::x#7 = 9+1 [phi:display_vera_led->display_chip_led#1] -- vbuz1=vbuc1 
    lda #9+1
    sta.z display_chip_led.x
    // [2315] phi display_chip_led::tc#3 = display_chip_led::tc#1 [phi:display_vera_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_vera_led::@1
    // display_info_led(INFO_X-2, INFO_Y+1, c, BLUE)
    // [1842] display_info_led::tc#1 = display_vera_led::c#2 -- vbuz1=vbum2 
    lda c
    sta.z display_info_led.tc
    // [1843] call display_info_led
    // [1552] phi from display_vera_led::@1 to display_info_led [phi:display_vera_led::@1->display_info_led]
    // [1552] phi display_info_led::y#4 = $11+1 [phi:display_vera_led::@1->display_info_led#0] -- vbuz1=vbuc1 
    lda #$11+1
    sta.z display_info_led.y
    // [1552] phi display_info_led::x#4 = 4-2 [phi:display_vera_led::@1->display_info_led#1] -- vbuz1=vbuc1 
    lda #4-2
    sta.z display_info_led.x
    // [1552] phi display_info_led::tc#4 = display_info_led::tc#1 [phi:display_vera_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_vera_led::@return
    // }
    // [1844] return 
    rts
  .segment Data
    .label c = main.main__194
}
.segment Code
  // strcpy
// Copies the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcpy(char *destination, char *source)
strcpy: {
    .label dst = $e6
    .label src = $d9
    // [1846] phi from strcpy to strcpy::@1 [phi:strcpy->strcpy::@1]
    // [1846] phi strcpy::dst#2 = display_chip_rom::rom [phi:strcpy->strcpy::@1#0] -- pbuz1=pbuc1 
    lda #<display_chip_rom.rom
    sta.z dst
    lda #>display_chip_rom.rom
    sta.z dst+1
    // [1846] phi strcpy::src#2 = display_chip_rom::source [phi:strcpy->strcpy::@1#1] -- pbuz1=pbuc1 
    lda #<display_chip_rom.source
    sta.z src
    lda #>display_chip_rom.source
    sta.z src+1
    // strcpy::@1
  __b1:
    // while(*src)
    // [1847] if(0!=*strcpy::src#2) goto strcpy::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcpy::@3
    // *dst = 0
    // [1848] *strcpy::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcpy::@return
    // }
    // [1849] return 
    rts
    // strcpy::@2
  __b2:
    // *dst++ = *src++
    // [1850] *strcpy::dst#2 = *strcpy::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [1851] strcpy::dst#1 = ++ strcpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [1852] strcpy::src#1 = ++ strcpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [1846] phi from strcpy::@2 to strcpy::@1 [phi:strcpy::@2->strcpy::@1]
    // [1846] phi strcpy::dst#2 = strcpy::dst#1 [phi:strcpy::@2->strcpy::@1#0] -- register_copy 
    // [1846] phi strcpy::src#2 = strcpy::src#1 [phi:strcpy::@2->strcpy::@1#1] -- register_copy 
    jmp __b1
}
  // strcat
// Concatenates the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcat(char *destination, __zp($b7) char *source)
strcat: {
    .label strcat__0 = $e2
    .label dst = $e2
    .label src = $b7
    .label source = $b7
    // strlen(destination)
    // [1854] call strlen
    // [1885] phi from strcat to strlen [phi:strcat->strlen]
    // [1885] phi strlen::str#8 = display_chip_rom::rom [phi:strcat->strlen#0] -- pbuz1=pbuc1 
    lda #<display_chip_rom.rom
    sta.z strlen.str
    lda #>display_chip_rom.rom
    sta.z strlen.str+1
    jsr strlen
    // strlen(destination)
    // [1855] strlen::return#0 = strlen::len#2
    // strcat::@4
    // [1856] strcat::$0 = strlen::return#0 -- vwuz1=vwum2 
    lda strlen.return
    sta.z strcat__0
    lda strlen.return+1
    sta.z strcat__0+1
    // char* dst = destination + strlen(destination)
    // [1857] strcat::dst#0 = display_chip_rom::rom + strcat::$0 -- pbuz1=pbuc1_plus_vwuz1 
    lda.z dst
    clc
    adc #<display_chip_rom.rom
    sta.z dst
    lda.z dst+1
    adc #>display_chip_rom.rom
    sta.z dst+1
    // [1858] phi from strcat::@2 strcat::@4 to strcat::@1 [phi:strcat::@2/strcat::@4->strcat::@1]
    // [1858] phi strcat::dst#2 = strcat::dst#1 [phi:strcat::@2/strcat::@4->strcat::@1#0] -- register_copy 
    // [1858] phi strcat::src#2 = strcat::src#1 [phi:strcat::@2/strcat::@4->strcat::@1#1] -- register_copy 
    // strcat::@1
  __b1:
    // while(*src)
    // [1859] if(0!=*strcat::src#2) goto strcat::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcat::@3
    // *dst = 0
    // [1860] *strcat::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcat::@return
    // }
    // [1861] return 
    rts
    // strcat::@2
  __b2:
    // *dst++ = *src++
    // [1862] *strcat::dst#2 = *strcat::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [1863] strcat::dst#1 = ++ strcat::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [1864] strcat::src#1 = ++ strcat::src#2 -- pbuz1=_inc_pbuz1 
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
// void display_rom_led(__zp($43) char chip, __zp($d8) char c)
display_rom_led: {
    .label display_rom_led__0 = $b2
    .label chip = $43
    .label c = $d8
    .label display_rom_led__7 = $b2
    .label display_rom_led__8 = $b2
    // chip*6
    // [1866] display_rom_led::$7 = display_rom_led::chip#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z chip
    asl
    sta.z display_rom_led__7
    // [1867] display_rom_led::$8 = display_rom_led::$7 + display_rom_led::chip#2 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z display_rom_led__8
    clc
    adc.z chip
    sta.z display_rom_led__8
    // CHIP_ROM_X+chip*6
    // [1868] display_rom_led::$0 = display_rom_led::$8 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_rom_led__0
    // display_chip_led(CHIP_ROM_X+chip*6+1, CHIP_ROM_Y, CHIP_ROM_W, c, BLUE)
    // [1869] display_chip_led::x#3 = display_rom_led::$0 + $14+1 -- vbuz1=vbuz1_plus_vbuc1 
    lda #$14+1
    clc
    adc.z display_chip_led.x
    sta.z display_chip_led.x
    // [1870] display_chip_led::tc#2 = display_rom_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_chip_led.tc
    // [1871] call display_chip_led
    // [2315] phi from display_rom_led to display_chip_led [phi:display_rom_led->display_chip_led]
    // [2315] phi display_chip_led::w#7 = 3 [phi:display_rom_led->display_chip_led#0] -- vbuz1=vbuc1 
    lda #3
    sta.z display_chip_led.w
    // [2315] phi display_chip_led::x#7 = display_chip_led::x#3 [phi:display_rom_led->display_chip_led#1] -- register_copy 
    // [2315] phi display_chip_led::tc#3 = display_chip_led::tc#2 [phi:display_rom_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_rom_led::@1
    // display_info_led(INFO_X-2, INFO_Y+chip+2, c, BLUE)
    // [1872] display_info_led::y#2 = display_rom_led::chip#2 + $11+2 -- vbuz1=vbuz2_plus_vbuc1 
    lda #$11+2
    clc
    adc.z chip
    sta.z display_info_led.y
    // [1873] display_info_led::tc#2 = display_rom_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_info_led.tc
    // [1874] call display_info_led
    // [1552] phi from display_rom_led::@1 to display_info_led [phi:display_rom_led::@1->display_info_led]
    // [1552] phi display_info_led::y#4 = display_info_led::y#2 [phi:display_rom_led::@1->display_info_led#0] -- register_copy 
    // [1552] phi display_info_led::x#4 = 4-2 [phi:display_rom_led::@1->display_info_led#1] -- vbuz1=vbuc1 
    lda #4-2
    sta.z display_info_led.x
    // [1552] phi display_info_led::tc#4 = display_info_led::tc#2 [phi:display_rom_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_rom_led::@return
    // }
    // [1875] return 
    rts
}
  // display_progress_line
/**
 * @brief Print one line of text in the progress frame at a line position.
 * 
 * @param line The start line, counting from 0.
 * @param text The text to be displayed.
 */
// void display_progress_line(__zp($ba) char line, __zp($48) char *text)
display_progress_line: {
    .label line = $ba
    .label text = $48
    // cputsxy(PROGRESS_X, PROGRESS_Y+line, text)
    // [1876] cputsxy::y#0 = PROGRESS_Y + display_progress_line::line#0 -- vbum1=vbuc1_plus_vbuz2 
    lda #PROGRESS_Y
    clc
    adc.z line
    sta cputsxy.y
    // [1877] cputsxy::s#0 = display_progress_line::text#0
    // [1878] call cputsxy
    // [660] phi from display_progress_line to cputsxy [phi:display_progress_line->cputsxy]
    // [660] phi cputsxy::s#4 = cputsxy::s#0 [phi:display_progress_line->cputsxy#0] -- register_copy 
    // [660] phi cputsxy::y#4 = cputsxy::y#0 [phi:display_progress_line->cputsxy#1] -- register_copy 
    // [660] phi cputsxy::x#4 = PROGRESS_X [phi:display_progress_line->cputsxy#2] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta cputsxy.x
    jsr cputsxy
    // display_progress_line::@return
    // }
    // [1879] return 
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
    // [1880] cx16_k_i2c_read_byte::result = 0 -- vwum1=vwuc1 
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
    // [1882] cx16_k_i2c_read_byte::return#0 = cx16_k_i2c_read_byte::result -- vwum1=vwum2 
    sta return
    lda result+1
    sta return+1
    // cx16_k_i2c_read_byte::@return
    // }
    // [1883] cx16_k_i2c_read_byte::return#1 = cx16_k_i2c_read_byte::return#0
    // [1884] return 
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
    // [1886] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [1886] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta len
    sta len+1
    // [1886] phi strlen::str#6 = strlen::str#8 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [1887] if(0!=*strlen::str#6) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [1888] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [1889] strlen::len#1 = ++ strlen::len#2 -- vwum1=_inc_vwum1 
    inc len
    bne !+
    inc len+1
  !:
    // str++;
    // [1890] strlen::str#1 = ++ strlen::str#6 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [1886] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [1886] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [1886] phi strlen::str#6 = strlen::str#1 [phi:strlen::@2->strlen::@1#1] -- register_copy 
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
    // [1892] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [1892] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbum1=vbuc1 
    lda #0
    sta i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [1893] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbum1_lt_vbum2_then_la1 
    lda i
    cmp length
    bcc __b2
    // printf_padding::@return
    // }
    // [1894] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [1895] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbum1 
    lda pad
    pha
    // [1896] callexecute *printf_padding::putc#7  -- call__deref_pprz1 
    jsr icall33
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [1898] printf_padding::i#1 = ++ printf_padding::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [1892] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [1892] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
    jmp __b1
    // Outside Flow
  icall33:
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
    .label utoa__11 = $bc
    .label buffer = $48
    .label digit_values = $78
    // if(radix==DECIMAL)
    // [1899] if(utoa::radix#0==DECIMAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // utoa::@2
    // if(radix==HEXADECIMAL)
    // [1900] if(utoa::radix#0==HEXADECIMAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // utoa::@3
    // if(radix==OCTAL)
    // [1901] if(utoa::radix#0==OCTAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // utoa::@4
    // if(radix==BINARY)
    // [1902] if(utoa::radix#0==BINARY) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // utoa::@5
    // *buffer++ = 'e'
    // [1903] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1904] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1905] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1906] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // utoa::@return
    // }
    // [1907] return 
    rts
    // [1908] phi from utoa to utoa::@1 [phi:utoa->utoa::@1]
  __b2:
    // [1908] phi utoa::digit_values#8 = RADIX_DECIMAL_VALUES [phi:utoa->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_DECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES
    sta.z digit_values+1
    // [1908] phi utoa::max_digits#7 = 5 [phi:utoa->utoa::@1#1] -- vbum1=vbuc1 
    lda #5
    sta max_digits
    jmp __b1
    // [1908] phi from utoa::@2 to utoa::@1 [phi:utoa::@2->utoa::@1]
  __b3:
    // [1908] phi utoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES [phi:utoa::@2->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_HEXADECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES
    sta.z digit_values+1
    // [1908] phi utoa::max_digits#7 = 4 [phi:utoa::@2->utoa::@1#1] -- vbum1=vbuc1 
    lda #4
    sta max_digits
    jmp __b1
    // [1908] phi from utoa::@3 to utoa::@1 [phi:utoa::@3->utoa::@1]
  __b4:
    // [1908] phi utoa::digit_values#8 = RADIX_OCTAL_VALUES [phi:utoa::@3->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_OCTAL_VALUES
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES
    sta.z digit_values+1
    // [1908] phi utoa::max_digits#7 = 6 [phi:utoa::@3->utoa::@1#1] -- vbum1=vbuc1 
    lda #6
    sta max_digits
    jmp __b1
    // [1908] phi from utoa::@4 to utoa::@1 [phi:utoa::@4->utoa::@1]
  __b5:
    // [1908] phi utoa::digit_values#8 = RADIX_BINARY_VALUES [phi:utoa::@4->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_BINARY_VALUES
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES
    sta.z digit_values+1
    // [1908] phi utoa::max_digits#7 = $10 [phi:utoa::@4->utoa::@1#1] -- vbum1=vbuc1 
    lda #$10
    sta max_digits
    // utoa::@1
  __b1:
    // [1909] phi from utoa::@1 to utoa::@6 [phi:utoa::@1->utoa::@6]
    // [1909] phi utoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:utoa::@1->utoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1909] phi utoa::started#2 = 0 [phi:utoa::@1->utoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [1909] phi utoa::value#2 = utoa::value#1 [phi:utoa::@1->utoa::@6#2] -- register_copy 
    // [1909] phi utoa::digit#2 = 0 [phi:utoa::@1->utoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // utoa::@6
  __b6:
    // max_digits-1
    // [1910] utoa::$4 = utoa::max_digits#7 - 1 -- vbuz1=vbum2_minus_1 
    ldx max_digits
    dex
    stx.z utoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1911] if(utoa::digit#2<utoa::$4) goto utoa::@7 -- vbum1_lt_vbuz2_then_la1 
    lda digit
    cmp.z utoa__4
    bcc __b7
    // utoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1912] utoa::$11 = (char)utoa::value#2 -- vbuz1=_byte_vwum2 
    lda value
    sta.z utoa__11
    // [1913] *utoa::buffer#11 = DIGITS[utoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1914] utoa::buffer#3 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1915] *utoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // utoa::@7
  __b7:
    // unsigned int digit_value = digit_values[digit]
    // [1916] utoa::$10 = utoa::digit#2 << 1 -- vbuz1=vbum2_rol_1 
    lda digit
    asl
    sta.z utoa__10
    // [1917] utoa::digit_value#0 = utoa::digit_values#8[utoa::$10] -- vwum1=pwuz2_derefidx_vbuz3 
    tay
    lda (digit_values),y
    sta digit_value
    iny
    lda (digit_values),y
    sta digit_value+1
    // if (started || value >= digit_value)
    // [1918] if(0!=utoa::started#2) goto utoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // utoa::@12
    // [1919] if(utoa::value#2>=utoa::digit_value#0) goto utoa::@10 -- vwum1_ge_vwum2_then_la1 
    lda digit_value+1
    cmp value+1
    bne !+
    lda digit_value
    cmp value
    beq __b10
  !:
    bcc __b10
    // [1920] phi from utoa::@12 to utoa::@9 [phi:utoa::@12->utoa::@9]
    // [1920] phi utoa::buffer#14 = utoa::buffer#11 [phi:utoa::@12->utoa::@9#0] -- register_copy 
    // [1920] phi utoa::started#4 = utoa::started#2 [phi:utoa::@12->utoa::@9#1] -- register_copy 
    // [1920] phi utoa::value#6 = utoa::value#2 [phi:utoa::@12->utoa::@9#2] -- register_copy 
    // utoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1921] utoa::digit#1 = ++ utoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [1909] phi from utoa::@9 to utoa::@6 [phi:utoa::@9->utoa::@6]
    // [1909] phi utoa::buffer#11 = utoa::buffer#14 [phi:utoa::@9->utoa::@6#0] -- register_copy 
    // [1909] phi utoa::started#2 = utoa::started#4 [phi:utoa::@9->utoa::@6#1] -- register_copy 
    // [1909] phi utoa::value#2 = utoa::value#6 [phi:utoa::@9->utoa::@6#2] -- register_copy 
    // [1909] phi utoa::digit#2 = utoa::digit#1 [phi:utoa::@9->utoa::@6#3] -- register_copy 
    jmp __b6
    // utoa::@10
  __b10:
    // utoa_append(buffer++, value, digit_value)
    // [1922] utoa_append::buffer#0 = utoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z utoa_append.buffer
    lda.z buffer+1
    sta.z utoa_append.buffer+1
    // [1923] utoa_append::value#0 = utoa::value#2
    // [1924] utoa_append::sub#0 = utoa::digit_value#0
    // [1925] call utoa_append
    // [2394] phi from utoa::@10 to utoa_append [phi:utoa::@10->utoa_append]
    jsr utoa_append
    // utoa_append(buffer++, value, digit_value)
    // [1926] utoa_append::return#0 = utoa_append::value#2
    // utoa::@11
    // value = utoa_append(buffer++, value, digit_value)
    // [1927] utoa::value#0 = utoa_append::return#0
    // value = utoa_append(buffer++, value, digit_value);
    // [1928] utoa::buffer#4 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1920] phi from utoa::@11 to utoa::@9 [phi:utoa::@11->utoa::@9]
    // [1920] phi utoa::buffer#14 = utoa::buffer#4 [phi:utoa::@11->utoa::@9#0] -- register_copy 
    // [1920] phi utoa::started#4 = 1 [phi:utoa::@11->utoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [1920] phi utoa::value#6 = utoa::value#0 [phi:utoa::@11->utoa::@9#2] -- register_copy 
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
    .label printf_number_buffer__19 = $bf
    .label putc = $b5
    // if(format.min_length)
    // [1930] if(0==printf_number_buffer::format_min_length#3) goto printf_number_buffer::@1 -- 0_eq_vbum1_then_la1 
    lda format_min_length
    beq __b5
    // [1931] phi from printf_number_buffer to printf_number_buffer::@5 [phi:printf_number_buffer->printf_number_buffer::@5]
    // printf_number_buffer::@5
    // strlen(buffer.digits)
    // [1932] call strlen
    // [1885] phi from printf_number_buffer::@5 to strlen [phi:printf_number_buffer::@5->strlen]
    // [1885] phi strlen::str#8 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@5->strlen#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str+1
    jsr strlen
    // strlen(buffer.digits)
    // [1933] strlen::return#3 = strlen::len#2
    // printf_number_buffer::@11
    // [1934] printf_number_buffer::$19 = strlen::return#3 -- vwuz1=vwum2 
    lda strlen.return
    sta.z printf_number_buffer__19
    lda strlen.return+1
    sta.z printf_number_buffer__19+1
    // signed char len = (signed char)strlen(buffer.digits)
    // [1935] printf_number_buffer::len#0 = (signed char)printf_number_buffer::$19 -- vbsm1=_sbyte_vwuz2 
    // There is a minimum length - work out the padding
    lda.z printf_number_buffer__19
    sta len
    // if(buffer.sign)
    // [1936] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@10 -- 0_eq_vbum1_then_la1 
    lda buffer_sign
    beq __b10
    // printf_number_buffer::@6
    // len++;
    // [1937] printf_number_buffer::len#1 = ++ printf_number_buffer::len#0 -- vbsm1=_inc_vbsm1 
    inc len
    // [1938] phi from printf_number_buffer::@11 printf_number_buffer::@6 to printf_number_buffer::@10 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10]
    // [1938] phi printf_number_buffer::len#2 = printf_number_buffer::len#0 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10#0] -- register_copy 
    // printf_number_buffer::@10
  __b10:
    // padding = (signed char)format.min_length - len
    // [1939] printf_number_buffer::padding#1 = (signed char)printf_number_buffer::format_min_length#3 - printf_number_buffer::len#2 -- vbsm1=vbsm2_minus_vbsm1 
    lda format_min_length
    sec
    sbc padding
    sta padding
    // if(padding<0)
    // [1940] if(printf_number_buffer::padding#1>=0) goto printf_number_buffer::@15 -- vbsm1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1942] phi from printf_number_buffer printf_number_buffer::@10 to printf_number_buffer::@1 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1]
  __b5:
    // [1942] phi printf_number_buffer::padding#10 = 0 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1#0] -- vbsm1=vbsc1 
    lda #0
    sta padding
    // [1941] phi from printf_number_buffer::@10 to printf_number_buffer::@15 [phi:printf_number_buffer::@10->printf_number_buffer::@15]
    // printf_number_buffer::@15
    // [1942] phi from printf_number_buffer::@15 to printf_number_buffer::@1 [phi:printf_number_buffer::@15->printf_number_buffer::@1]
    // [1942] phi printf_number_buffer::padding#10 = printf_number_buffer::padding#1 [phi:printf_number_buffer::@15->printf_number_buffer::@1#0] -- register_copy 
    // printf_number_buffer::@1
  __b1:
    // printf_number_buffer::@13
    // if(!format.justify_left && !format.zero_padding && padding)
    // [1943] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@2 -- 0_neq_vbum1_then_la1 
    lda format_zero_padding
    bne __b2
    // printf_number_buffer::@12
    // [1944] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@7 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b7
    jmp __b2
    // printf_number_buffer::@7
  __b7:
    // printf_padding(putc, ' ',(char)padding)
    // [1945] printf_padding::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1946] printf_padding::length#0 = (char)printf_number_buffer::padding#10 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1947] call printf_padding
    // [1891] phi from printf_number_buffer::@7 to printf_padding [phi:printf_number_buffer::@7->printf_padding]
    // [1891] phi printf_padding::putc#7 = printf_padding::putc#0 [phi:printf_number_buffer::@7->printf_padding#0] -- register_copy 
    // [1891] phi printf_padding::pad#7 = ' ' [phi:printf_number_buffer::@7->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [1891] phi printf_padding::length#6 = printf_padding::length#0 [phi:printf_number_buffer::@7->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@2
  __b2:
    // if(buffer.sign)
    // [1948] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@3 -- 0_eq_vbum1_then_la1 
    lda buffer_sign
    beq __b3
    // printf_number_buffer::@8
    // putc(buffer.sign)
    // [1949] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbum1 
    pha
    // [1950] callexecute *printf_number_buffer::putc#10  -- call__deref_pprz1 
    jsr icall34
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@3
  __b3:
    // if(format.zero_padding && padding)
    // [1952] if(0==printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@4 -- 0_eq_vbum1_then_la1 
    lda format_zero_padding
    beq __b4
    // printf_number_buffer::@14
    // [1953] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@9 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b9
    jmp __b4
    // printf_number_buffer::@9
  __b9:
    // printf_padding(putc, '0',(char)padding)
    // [1954] printf_padding::putc#1 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1955] printf_padding::length#1 = (char)printf_number_buffer::padding#10 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1956] call printf_padding
    // [1891] phi from printf_number_buffer::@9 to printf_padding [phi:printf_number_buffer::@9->printf_padding]
    // [1891] phi printf_padding::putc#7 = printf_padding::putc#1 [phi:printf_number_buffer::@9->printf_padding#0] -- register_copy 
    // [1891] phi printf_padding::pad#7 = '0' [phi:printf_number_buffer::@9->printf_padding#1] -- vbum1=vbuc1 
    lda #'0'
    sta printf_padding.pad
    // [1891] phi printf_padding::length#6 = printf_padding::length#1 [phi:printf_number_buffer::@9->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@4
  __b4:
    // printf_str(putc, buffer.digits)
    // [1957] printf_str::putc#0 = printf_number_buffer::putc#10
    // [1958] call printf_str
    // [775] phi from printf_number_buffer::@4 to printf_str [phi:printf_number_buffer::@4->printf_str]
    // [775] phi printf_str::putc#73 = printf_str::putc#0 [phi:printf_number_buffer::@4->printf_str#0] -- register_copy 
    // [775] phi printf_str::s#73 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@return
    // }
    // [1959] return 
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
    .label fopen__9 = $cd
    .label fopen__15 = $c8
    .label fopen__16 = $52
    .label fopen__26 = $b5
    .label fopen__28 = $e4
    .label fopen__30 = $63
    .label stream = $63
    .label pathtoken = $b3
    .label pathtoken_1 = $eb
    .label path = $b3
    .label return = $63
    // unsigned char sp = __stdio_filecount
    // [1961] fopen::sp#0 = __stdio_filecount -- vbum1=vbum2 
    lda __stdio_filecount
    sta sp
    // (unsigned int)sp | 0x8000
    // [1962] fopen::$30 = (unsigned int)fopen::sp#0 -- vwuz1=_word_vbum2 
    sta.z fopen__30
    lda #0
    sta.z fopen__30+1
    // [1963] fopen::stream#0 = fopen::$30 | $8000 -- vwuz1=vwuz1_bor_vwuc1 
    lda.z stream
    ora #<$8000
    sta.z stream
    lda.z stream+1
    ora #>$8000
    sta.z stream+1
    // char pathpos = sp * __STDIO_FILECOUNT
    // [1964] fopen::pathpos#0 = fopen::sp#0 << 1 -- vbum1=vbum2_rol_1 
    lda sp
    asl
    sta pathpos
    // __logical = 0
    // [1965] ((char *)&__stdio_file+$40)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy sp
    sta __stdio_file+$40,y
    // __device = 0
    // [1966] ((char *)&__stdio_file+$42)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [1967] ((char *)&__stdio_file+$44)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$44,y
    // [1968] fopen::pathtoken#22 = fopen::pathtoken#0 -- pbuz1=pbuz2 
    lda.z pathtoken
    sta.z pathtoken_1
    lda.z pathtoken+1
    sta.z pathtoken_1+1
    // [1969] fopen::pathpos#21 = fopen::pathpos#0 -- vbum1=vbum2 
    lda pathpos
    sta pathpos_1
    // [1970] phi from fopen to fopen::@8 [phi:fopen->fopen::@8]
    // [1970] phi fopen::num#10 = 0 [phi:fopen->fopen::@8#0] -- vbum1=vbuc1 
    lda #0
    sta num
    // [1970] phi fopen::pathpos#10 = fopen::pathpos#21 [phi:fopen->fopen::@8#1] -- register_copy 
    // [1970] phi fopen::path#10 = fopen::pathtoken#0 [phi:fopen->fopen::@8#2] -- register_copy 
    // [1970] phi fopen::pathstep#10 = 0 [phi:fopen->fopen::@8#3] -- vbum1=vbuc1 
    sta pathstep
    // [1970] phi fopen::pathtoken#10 = fopen::pathtoken#22 [phi:fopen->fopen::@8#4] -- register_copy 
  // Iterate while path is not \0.
    // [1970] phi from fopen::@22 to fopen::@8 [phi:fopen::@22->fopen::@8]
    // [1970] phi fopen::num#10 = fopen::num#13 [phi:fopen::@22->fopen::@8#0] -- register_copy 
    // [1970] phi fopen::pathpos#10 = fopen::pathpos#7 [phi:fopen::@22->fopen::@8#1] -- register_copy 
    // [1970] phi fopen::path#10 = fopen::path#11 [phi:fopen::@22->fopen::@8#2] -- register_copy 
    // [1970] phi fopen::pathstep#10 = fopen::pathstep#11 [phi:fopen::@22->fopen::@8#3] -- register_copy 
    // [1970] phi fopen::pathtoken#10 = fopen::pathtoken#1 [phi:fopen::@22->fopen::@8#4] -- register_copy 
    // fopen::@8
  __b8:
    // if (*pathtoken == ',' || *pathtoken == '\0')
    // [1971] if(*fopen::pathtoken#10==',') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #','
    ldy #0
    cmp (pathtoken_1),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@33
    // [1972] if(*fopen::pathtoken#10=='@') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #'@'
    cmp (pathtoken_1),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@23
    // if (pathstep == 0)
    // [1973] if(fopen::pathstep#10!=0) goto fopen::@10 -- vbum1_neq_0_then_la1 
    lda pathstep
    bne __b10
    // fopen::@24
    // __stdio_file.filename[pathpos] = *pathtoken
    // [1974] ((char *)&__stdio_file)[fopen::pathpos#10] = *fopen::pathtoken#10 -- pbuc1_derefidx_vbum1=_deref_pbuz2 
    lda (pathtoken_1),y
    ldy pathpos_1
    sta __stdio_file,y
    // pathpos++;
    // [1975] fopen::pathpos#1 = ++ fopen::pathpos#10 -- vbum1=_inc_vbum1 
    inc pathpos_1
    // [1976] phi from fopen::@12 fopen::@23 fopen::@24 to fopen::@10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10]
    // [1976] phi fopen::num#13 = fopen::num#15 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#0] -- register_copy 
    // [1976] phi fopen::pathpos#7 = fopen::pathpos#10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#1] -- register_copy 
    // [1976] phi fopen::path#11 = fopen::path#13 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#2] -- register_copy 
    // [1976] phi fopen::pathstep#11 = fopen::pathstep#1 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#3] -- register_copy 
    // fopen::@10
  __b10:
    // pathtoken++;
    // [1977] fopen::pathtoken#1 = ++ fopen::pathtoken#10 -- pbuz1=_inc_pbuz1 
    inc.z pathtoken_1
    bne !+
    inc.z pathtoken_1+1
  !:
    // fopen::@22
    // pathtoken - 1
    // [1978] fopen::$28 = fopen::pathtoken#1 - 1 -- pbuz1=pbuz2_minus_1 
    lda.z pathtoken_1
    sec
    sbc #1
    sta.z fopen__28
    lda.z pathtoken_1+1
    sbc #0
    sta.z fopen__28+1
    // while (*(pathtoken - 1))
    // [1979] if(0!=*fopen::$28) goto fopen::@8 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (fopen__28),y
    cmp #0
    bne __b8
    // fopen::@26
    // __status = 0
    // [1980] ((char *)&__stdio_file+$46)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    tya
    ldy sp
    sta __stdio_file+$46,y
    // if(!__logical)
    // [1981] if(0!=((char *)&__stdio_file+$40)[fopen::sp#0]) goto fopen::@1 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$40,y
    cmp #0
    bne __b1
    // fopen::@27
    // __stdio_filecount+1
    // [1982] fopen::$4 = __stdio_filecount + 1 -- vbum1=vbum2_plus_1 
    lda __stdio_filecount
    inc
    sta fopen__4
    // __logical = __stdio_filecount+1
    // [1983] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::$4 -- pbuc1_derefidx_vbum1=vbum2 
    sta __stdio_file+$40,y
    // fopen::@1
  __b1:
    // if(!__device)
    // [1984] if(0!=((char *)&__stdio_file+$42)[fopen::sp#0]) goto fopen::@2 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    ldy sp
    lda __stdio_file+$42,y
    cmp #0
    bne __b2
    // fopen::@5
    // __device = 8
    // [1985] ((char *)&__stdio_file+$42)[fopen::sp#0] = 8 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #8
    sta __stdio_file+$42,y
    // fopen::@2
  __b2:
    // if(!__channel)
    // [1986] if(0!=((char *)&__stdio_file+$44)[fopen::sp#0]) goto fopen::@3 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    ldy sp
    lda __stdio_file+$44,y
    cmp #0
    bne __b3
    // fopen::@6
    // __stdio_filecount+2
    // [1987] fopen::$9 = __stdio_filecount + 2 -- vbuz1=vbum2_plus_2 
    lda __stdio_filecount
    clc
    adc #2
    sta.z fopen__9
    // __channel = __stdio_filecount+2
    // [1988] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::$9 -- pbuc1_derefidx_vbum1=vbuz2 
    sta __stdio_file+$44,y
    // fopen::@3
  __b3:
    // __filename
    // [1989] fopen::$11 = (char *)&__stdio_file + fopen::pathpos#0 -- pbum1=pbuc1_plus_vbum2 
    lda pathpos
    clc
    adc #<__stdio_file
    sta fopen__11
    lda #>__stdio_file
    adc #0
    sta fopen__11+1
    // cbm_k_setnam(__filename)
    // [1990] fopen::cbm_k_setnam1_filename = fopen::$11 -- pbum1=pbum2 
    lda fopen__11
    sta cbm_k_setnam1_filename
    lda fopen__11+1
    sta cbm_k_setnam1_filename+1
    // fopen::cbm_k_setnam1
    // strlen(filename)
    // [1991] strlen::str#4 = fopen::cbm_k_setnam1_filename -- pbuz1=pbum2 
    lda cbm_k_setnam1_filename
    sta.z strlen.str
    lda cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [1992] call strlen
    // [1885] phi from fopen::cbm_k_setnam1 to strlen [phi:fopen::cbm_k_setnam1->strlen]
    // [1885] phi strlen::str#8 = strlen::str#4 [phi:fopen::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [1993] strlen::return#11 = strlen::len#2
    // fopen::@31
    // [1994] fopen::cbm_k_setnam1_$0 = strlen::return#11 -- vwum1=vwum2 
    lda strlen.return
    sta cbm_k_setnam1_fopen__0
    lda strlen.return+1
    sta cbm_k_setnam1_fopen__0+1
    // char filename_len = (char)strlen(filename)
    // [1995] fopen::cbm_k_setnam1_filename_len = (char)fopen::cbm_k_setnam1_$0 -- vbum1=_byte_vwum2 
    lda cbm_k_setnam1_fopen__0
    sta cbm_k_setnam1_filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx cbm_k_setnam1_filename
    ldy cbm_k_setnam1_filename+1
    jsr CBM_SETNAM
    // fopen::@28
    // cbm_k_setlfs(__logical, __device, __channel)
    // [1997] cbm_k_setlfs::channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$40,y
    sta cbm_k_setlfs.channel
    // [1998] cbm_k_setlfs::device = ((char *)&__stdio_file+$42)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    lda __stdio_file+$42,y
    sta cbm_k_setlfs.device
    // [1999] cbm_k_setlfs::command = ((char *)&__stdio_file+$44)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    lda __stdio_file+$44,y
    sta cbm_k_setlfs.command
    // [2000] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // fopen::cbm_k_open1
    // asm
    // asm { jsrCBM_OPEN  }
    jsr CBM_OPEN
    // fopen::cbm_k_readst1
    // char status
    // [2002] fopen::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2004] fopen::cbm_k_readst1_return#0 = fopen::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // fopen::cbm_k_readst1_@return
    // }
    // [2005] fopen::cbm_k_readst1_return#1 = fopen::cbm_k_readst1_return#0
    // fopen::@29
    // cbm_k_readst()
    // [2006] fopen::$15 = fopen::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z fopen__15
    // __status = cbm_k_readst()
    // [2007] ((char *)&__stdio_file+$46)[fopen::sp#0] = fopen::$15 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // ferror(stream)
    // [2008] ferror::stream#0 = (struct $2 *)fopen::stream#0
    // [2009] call ferror
    jsr ferror
    // [2010] ferror::return#0 = ferror::return#1
    // fopen::@32
    // [2011] fopen::$16 = ferror::return#0 -- vwsz1=vwsm2 
    lda ferror.return
    sta.z fopen__16
    lda ferror.return+1
    sta.z fopen__16+1
    // if (ferror(stream))
    // [2012] if(0==fopen::$16) goto fopen::@4 -- 0_eq_vwsz1_then_la1 
    lda.z fopen__16
    ora.z fopen__16+1
    beq __b4
    // fopen::@7
    // cbm_k_close(__logical)
    // [2013] fopen::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$40,y
    sta cbm_k_close1_channel
    // fopen::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // [2015] phi from fopen::cbm_k_close1 to fopen::@return [phi:fopen::cbm_k_close1->fopen::@return]
    // [2015] phi fopen::return#2 = 0 [phi:fopen::cbm_k_close1->fopen::@return#0] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fopen::@return
    // }
    // [2016] return 
    rts
    // fopen::@4
  __b4:
    // __stdio_filecount++;
    // [2017] __stdio_filecount = ++ __stdio_filecount -- vbum1=_inc_vbum1 
    inc __stdio_filecount
    // [2018] fopen::return#8 = (struct $2 *)fopen::stream#0
    // [2015] phi from fopen::@4 to fopen::@return [phi:fopen::@4->fopen::@return]
    // [2015] phi fopen::return#2 = fopen::return#8 [phi:fopen::@4->fopen::@return#0] -- register_copy 
    rts
    // fopen::@9
  __b9:
    // if (pathstep > 0)
    // [2019] if(fopen::pathstep#10>0) goto fopen::@11 -- vbum1_gt_0_then_la1 
    lda pathstep
    bne __b11
    // fopen::@25
    // __stdio_file.filename[pathpos] = '\0'
    // [2020] ((char *)&__stdio_file)[fopen::pathpos#10] = '@' -- pbuc1_derefidx_vbum1=vbuc2 
    lda #'@'
    ldy pathpos_1
    sta __stdio_file,y
    // path = pathtoken + 1
    // [2021] fopen::path#0 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
    clc
    lda.z pathtoken_1
    adc #1
    sta.z path
    lda.z pathtoken_1+1
    adc #0
    sta.z path+1
    // [2022] phi from fopen::@16 fopen::@17 fopen::@18 fopen::@19 fopen::@25 to fopen::@12 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12]
    // [2022] phi fopen::num#15 = fopen::num#2 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#0] -- register_copy 
    // [2022] phi fopen::path#13 = fopen::path#16 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#1] -- register_copy 
    // fopen::@12
  __b12:
    // pathstep++;
    // [2023] fopen::pathstep#1 = ++ fopen::pathstep#10 -- vbum1=_inc_vbum1 
    inc pathstep
    jmp __b10
    // fopen::@11
  __b11:
    // char pathcmp = *path
    // [2024] fopen::pathcmp#0 = *fopen::path#10 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (path),y
    sta pathcmp
    // case 'D':
    // [2025] if(fopen::pathcmp#0=='D') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'D'
    cmp pathcmp
    beq __b13
    // fopen::@20
    // case 'L':
    // [2026] if(fopen::pathcmp#0=='L') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'L'
    cmp pathcmp
    beq __b13
    // fopen::@21
    // case 'C':
    //                     num = (char)atoi(path + 1);
    //                     path = pathtoken + 1;
    // [2027] if(fopen::pathcmp#0=='C') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'C'
    cmp pathcmp
    beq __b13
    // [2028] phi from fopen::@21 fopen::@30 to fopen::@14 [phi:fopen::@21/fopen::@30->fopen::@14]
    // [2028] phi fopen::path#16 = fopen::path#10 [phi:fopen::@21/fopen::@30->fopen::@14#0] -- register_copy 
    // [2028] phi fopen::num#2 = fopen::num#10 [phi:fopen::@21/fopen::@30->fopen::@14#1] -- register_copy 
    // fopen::@14
  __b14:
    // case 'L':
    //                     __logical = num;
    //                     break;
    // [2029] if(fopen::pathcmp#0=='L') goto fopen::@17 -- vbum1_eq_vbuc1_then_la1 
    lda #'L'
    cmp pathcmp
    beq __b17
    // fopen::@15
    // case 'D':
    //                     __device = num;
    //                     break;
    // [2030] if(fopen::pathcmp#0=='D') goto fopen::@18 -- vbum1_eq_vbuc1_then_la1 
    lda #'D'
    cmp pathcmp
    beq __b18
    // fopen::@16
    // case 'C':
    //                     __channel = num;
    //                     break;
    // [2031] if(fopen::pathcmp#0!='C') goto fopen::@12 -- vbum1_neq_vbuc1_then_la1 
    lda #'C'
    cmp pathcmp
    bne __b12
    // fopen::@19
    // __channel = num
    // [2032] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbum2 
    lda num
    ldy sp
    sta __stdio_file+$44,y
    jmp __b12
    // fopen::@18
  __b18:
    // __device = num
    // [2033] ((char *)&__stdio_file+$42)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbum2 
    lda num
    ldy sp
    sta __stdio_file+$42,y
    jmp __b12
    // fopen::@17
  __b17:
    // __logical = num
    // [2034] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbum2 
    lda num
    ldy sp
    sta __stdio_file+$40,y
    jmp __b12
    // fopen::@13
  __b13:
    // atoi(path + 1)
    // [2035] atoi::str#0 = fopen::path#10 + 1 -- pbuz1=pbuz1_plus_1 
    inc.z atoi.str
    bne !+
    inc.z atoi.str+1
  !:
    // [2036] call atoi
    // [2455] phi from fopen::@13 to atoi [phi:fopen::@13->atoi]
    // [2455] phi atoi::str#2 = atoi::str#0 [phi:fopen::@13->atoi#0] -- register_copy 
    jsr atoi
    // atoi(path + 1)
    // [2037] atoi::return#3 = atoi::return#2
    // fopen::@30
    // [2038] fopen::$26 = atoi::return#3 -- vwsz1=vwsm2 
    lda atoi.return
    sta.z fopen__26
    lda atoi.return+1
    sta.z fopen__26+1
    // num = (char)atoi(path + 1)
    // [2039] fopen::num#1 = (char)fopen::$26 -- vbum1=_byte_vwsz2 
    lda.z fopen__26
    sta num
    // path = pathtoken + 1
    // [2040] fopen::path#1 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
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
    fopen__11: .word 0
    cbm_k_setnam1_filename: .word 0
    cbm_k_setnam1_filename_len: .byte 0
    cbm_k_setnam1_fopen__0: .word 0
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
// __mem() unsigned int fgets(__zp($7a) char *ptr, __mem() unsigned int size, __zp($cb) struct $2 *stream)
fgets: {
    .label fgets__1 = $d0
    .label fgets__8 = $7c
    .label fgets__9 = $7e
    .label fgets__13 = $7d
    .label ptr = $7a
    .label stream = $cb
    // unsigned char sp = (unsigned char)stream
    // [2042] fgets::sp#0 = (char)fgets::stream#2 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_chkin(__logical)
    // [2043] fgets::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fgets::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    tay
    lda __stdio_file+$40,y
    sta cbm_k_chkin1_channel
    // fgets::cbm_k_chkin1
    // char status
    // [2044] fgets::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fgets::cbm_k_readst1
    // char status
    // [2046] fgets::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2048] fgets::cbm_k_readst1_return#0 = fgets::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // fgets::cbm_k_readst1_@return
    // }
    // [2049] fgets::cbm_k_readst1_return#1 = fgets::cbm_k_readst1_return#0
    // fgets::@11
    // cbm_k_readst()
    // [2050] fgets::$1 = fgets::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z fgets__1
    // __status = cbm_k_readst()
    // [2051] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$1 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2052] if(0==((char *)&__stdio_file+$46)[fgets::sp#0]) goto fgets::@1 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b1
    // [2053] phi from fgets::@11 fgets::@12 fgets::@5 to fgets::@return [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return]
  __b8:
    // [2053] phi fgets::return#1 = 0 [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return#0] -- vwum1=vbuc1 
    lda #<0
    sta return
    sta return+1
    // fgets::@return
    // }
    // [2054] return 
    rts
    // fgets::@1
  __b1:
    // [2055] fgets::remaining#22 = fgets::size#10 -- vwum1=vwum2 
    lda size
    sta remaining
    lda size+1
    sta remaining+1
    // [2056] phi from fgets::@1 to fgets::@2 [phi:fgets::@1->fgets::@2]
    // [2056] phi fgets::read#10 = 0 [phi:fgets::@1->fgets::@2#0] -- vwum1=vwuc1 
    lda #<0
    sta read
    sta read+1
    // [2056] phi fgets::remaining#11 = fgets::remaining#22 [phi:fgets::@1->fgets::@2#1] -- register_copy 
    // [2056] phi fgets::ptr#10 = fgets::ptr#12 [phi:fgets::@1->fgets::@2#2] -- register_copy 
    // [2056] phi from fgets::@17 fgets::@18 to fgets::@2 [phi:fgets::@17/fgets::@18->fgets::@2]
    // [2056] phi fgets::read#10 = fgets::read#1 [phi:fgets::@17/fgets::@18->fgets::@2#0] -- register_copy 
    // [2056] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@17/fgets::@18->fgets::@2#1] -- register_copy 
    // [2056] phi fgets::ptr#10 = fgets::ptr#13 [phi:fgets::@17/fgets::@18->fgets::@2#2] -- register_copy 
    // fgets::@2
  __b2:
    // if (!size)
    // [2057] if(0==fgets::size#10) goto fgets::@3 -- 0_eq_vwum1_then_la1 
    lda size
    ora size+1
    bne !__b3+
    jmp __b3
  !__b3:
    // fgets::@8
    // if (remaining >= 512)
    // [2058] if(fgets::remaining#11>=$200) goto fgets::@4 -- vwum1_ge_vwuc1_then_la1 
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
    // [2059] cx16_k_macptr::bytes = fgets::remaining#11 -- vbum1=vwum2 
    lda remaining
    sta cx16_k_macptr.bytes
    // [2060] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2061] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2062] cx16_k_macptr::return#4 = cx16_k_macptr::return#1
    // fgets::@15
  __b15:
    // bytes = cx16_k_macptr(remaining, ptr)
    // [2063] fgets::bytes#3 = cx16_k_macptr::return#4
    // [2064] phi from fgets::@13 fgets::@14 fgets::@15 to fgets::cbm_k_readst2 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2]
    // [2064] phi fgets::bytes#10 = fgets::bytes#1 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2#0] -- register_copy 
    // fgets::cbm_k_readst2
    // char status
    // [2065] fgets::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [2067] fgets::cbm_k_readst2_return#0 = fgets::cbm_k_readst2_status -- vbum1=vbum2 
    sta cbm_k_readst2_return
    // fgets::cbm_k_readst2_@return
    // }
    // [2068] fgets::cbm_k_readst2_return#1 = fgets::cbm_k_readst2_return#0
    // fgets::@12
    // cbm_k_readst()
    // [2069] fgets::$8 = fgets::cbm_k_readst2_return#1 -- vbuz1=vbum2 
    sta.z fgets__8
    // __status = cbm_k_readst()
    // [2070] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$8 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // __status & 0xBF
    // [2071] fgets::$9 = ((char *)&__stdio_file+$46)[fgets::sp#0] & $bf -- vbuz1=pbuc1_derefidx_vbum2_band_vbuc2 
    lda #$bf
    and __stdio_file+$46,y
    sta.z fgets__9
    // if (__status & 0xBF)
    // [2072] if(0==fgets::$9) goto fgets::@5 -- 0_eq_vbuz1_then_la1 
    beq __b5
    jmp __b8
    // fgets::@5
  __b5:
    // if (bytes == 0xFFFF)
    // [2073] if(fgets::bytes#10!=$ffff) goto fgets::@6 -- vwum1_neq_vwuc1_then_la1 
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
    // [2074] fgets::read#1 = fgets::read#10 + fgets::bytes#10 -- vwum1=vwum1_plus_vwum2 
    clc
    lda read
    adc bytes
    sta read
    lda read+1
    adc bytes+1
    sta read+1
    // ptr += bytes
    // [2075] fgets::ptr#0 = fgets::ptr#10 + fgets::bytes#10 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z ptr
    adc bytes
    sta.z ptr
    lda.z ptr+1
    adc bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [2076] fgets::$13 = byte1  fgets::ptr#0 -- vbuz1=_byte1_pbuz2 
    sta.z fgets__13
    // if (BYTE1(ptr) == 0xC0)
    // [2077] if(fgets::$13!=$c0) goto fgets::@7 -- vbuz1_neq_vbuc1_then_la1 
    lda #$c0
    cmp.z fgets__13
    bne __b7
    // fgets::@10
    // ptr -= 0x2000
    // [2078] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [2079] phi from fgets::@10 fgets::@6 to fgets::@7 [phi:fgets::@10/fgets::@6->fgets::@7]
    // [2079] phi fgets::ptr#13 = fgets::ptr#1 [phi:fgets::@10/fgets::@6->fgets::@7#0] -- register_copy 
    // fgets::@7
  __b7:
    // remaining -= bytes
    // [2080] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#10 -- vwum1=vwum1_minus_vwum2 
    lda remaining
    sec
    sbc bytes
    sta remaining
    lda remaining+1
    sbc bytes+1
    sta remaining+1
    // while ((__status == 0) && ((size && remaining) || !size))
    // [2081] if(((char *)&__stdio_file+$46)[fgets::sp#0]==0) goto fgets::@16 -- pbuc1_derefidx_vbum1_eq_0_then_la1 
    ldy sp
    lda __stdio_file+$46,y
    cmp #0
    beq __b16
    // [2053] phi from fgets::@17 fgets::@7 to fgets::@return [phi:fgets::@17/fgets::@7->fgets::@return]
    // [2053] phi fgets::return#1 = fgets::read#1 [phi:fgets::@17/fgets::@7->fgets::@return#0] -- register_copy 
    rts
    // fgets::@16
  __b16:
    // while ((__status == 0) && ((size && remaining) || !size))
    // [2082] if(0==fgets::size#10) goto fgets::@17 -- 0_eq_vwum1_then_la1 
    lda size
    ora size+1
    beq __b17
    // fgets::@18
    // [2083] if(0!=fgets::remaining#1) goto fgets::@2 -- 0_neq_vwum1_then_la1 
    lda remaining
    ora remaining+1
    beq !__b2+
    jmp __b2
  !__b2:
    // fgets::@17
  __b17:
    // [2084] if(0==fgets::size#10) goto fgets::@2 -- 0_eq_vwum1_then_la1 
    lda size
    ora size+1
    bne !__b2+
    jmp __b2
  !__b2:
    rts
    // fgets::@4
  __b4:
    // cx16_k_macptr(512, ptr)
    // [2085] cx16_k_macptr::bytes = $200 -- vbum1=vwuc1 
    lda #<$200
    sta cx16_k_macptr.bytes
    // [2086] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2087] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2088] cx16_k_macptr::return#3 = cx16_k_macptr::return#1
    // fgets::@14
    // bytes = cx16_k_macptr(512, ptr)
    // [2089] fgets::bytes#2 = cx16_k_macptr::return#3
    jmp __b15
    // fgets::@3
  __b3:
    // cx16_k_macptr(0, ptr)
    // [2090] cx16_k_macptr::bytes = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_macptr.bytes
    // [2091] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2092] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2093] cx16_k_macptr::return#2 = cx16_k_macptr::return#1
    // fgets::@13
    // bytes = cx16_k_macptr(0, ptr)
    // [2094] fgets::bytes#1 = cx16_k_macptr::return#2
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
    .label fclose__1 = $f0
    .label fclose__4 = $4e
    .label fclose__6 = $c2
    .label stream = $46
    // unsigned char sp = (unsigned char)stream
    // [2096] fclose::sp#0 = (char)fclose::stream#2 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_chkin(__logical)
    // [2097] fclose::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    tay
    lda __stdio_file+$40,y
    sta cbm_k_chkin1_channel
    // fclose::cbm_k_chkin1
    // char status
    // [2098] fclose::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fclose::cbm_k_readst1
    // char status
    // [2100] fclose::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2102] fclose::cbm_k_readst1_return#0 = fclose::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // fclose::cbm_k_readst1_@return
    // }
    // [2103] fclose::cbm_k_readst1_return#1 = fclose::cbm_k_readst1_return#0
    // fclose::@3
    // cbm_k_readst()
    // [2104] fclose::$1 = fclose::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z fclose__1
    // __status = cbm_k_readst()
    // [2105] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$1 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2106] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@1 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b1
    // fclose::@return
    // }
    // [2107] return 
    rts
    // fclose::@1
  __b1:
    // cbm_k_close(__logical)
    // [2108] fclose::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$40,y
    sta cbm_k_close1_channel
    // fclose::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // fclose::cbm_k_readst2
    // char status
    // [2110] fclose::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [2112] fclose::cbm_k_readst2_return#0 = fclose::cbm_k_readst2_status -- vbum1=vbum2 
    sta cbm_k_readst2_return
    // fclose::cbm_k_readst2_@return
    // }
    // [2113] fclose::cbm_k_readst2_return#1 = fclose::cbm_k_readst2_return#0
    // fclose::@4
    // cbm_k_readst()
    // [2114] fclose::$4 = fclose::cbm_k_readst2_return#1 -- vbuz1=vbum2 
    sta.z fclose__4
    // __status = cbm_k_readst()
    // [2115] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$4 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2116] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@2 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b2
    rts
    // fclose::@2
  __b2:
    // __logical = 0
    // [2117] ((char *)&__stdio_file+$40)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy sp
    sta __stdio_file+$40,y
    // __device = 0
    // [2118] ((char *)&__stdio_file+$42)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [2119] ((char *)&__stdio_file+$44)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$44,y
    // __filename
    // [2120] fclose::$6 = fclose::sp#0 << 1 -- vbuz1=vbum2_rol_1 
    tya
    asl
    sta.z fclose__6
    // *__filename = '\0'
    // [2121] ((char *)&__stdio_file)[fclose::$6] = '@' -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #'@'
    ldy.z fclose__6
    sta __stdio_file,y
    // __stdio_filecount--;
    // [2122] __stdio_filecount = -- __stdio_filecount -- vbum1=_dec_vbum1 
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
    .label uctoa__4 = $4e
    .label buffer = $46
    .label digit_values = $63
    // if(radix==DECIMAL)
    // [2123] if(uctoa::radix#0==DECIMAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // uctoa::@2
    // if(radix==HEXADECIMAL)
    // [2124] if(uctoa::radix#0==HEXADECIMAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // uctoa::@3
    // if(radix==OCTAL)
    // [2125] if(uctoa::radix#0==OCTAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // uctoa::@4
    // if(radix==BINARY)
    // [2126] if(uctoa::radix#0==BINARY) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // uctoa::@5
    // *buffer++ = 'e'
    // [2127] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2128] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2129] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2130] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // uctoa::@return
    // }
    // [2131] return 
    rts
    // [2132] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
  __b2:
    // [2132] phi uctoa::digit_values#8 = RADIX_DECIMAL_VALUES_CHAR [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [2132] phi uctoa::max_digits#7 = 3 [phi:uctoa->uctoa::@1#1] -- vbum1=vbuc1 
    lda #3
    sta max_digits
    jmp __b1
    // [2132] phi from uctoa::@2 to uctoa::@1 [phi:uctoa::@2->uctoa::@1]
  __b3:
    // [2132] phi uctoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_CHAR [phi:uctoa::@2->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [2132] phi uctoa::max_digits#7 = 2 [phi:uctoa::@2->uctoa::@1#1] -- vbum1=vbuc1 
    lda #2
    sta max_digits
    jmp __b1
    // [2132] phi from uctoa::@3 to uctoa::@1 [phi:uctoa::@3->uctoa::@1]
  __b4:
    // [2132] phi uctoa::digit_values#8 = RADIX_OCTAL_VALUES_CHAR [phi:uctoa::@3->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values+1
    // [2132] phi uctoa::max_digits#7 = 3 [phi:uctoa::@3->uctoa::@1#1] -- vbum1=vbuc1 
    lda #3
    sta max_digits
    jmp __b1
    // [2132] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
  __b5:
    // [2132] phi uctoa::digit_values#8 = RADIX_BINARY_VALUES_CHAR [phi:uctoa::@4->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_BINARY_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_CHAR
    sta.z digit_values+1
    // [2132] phi uctoa::max_digits#7 = 8 [phi:uctoa::@4->uctoa::@1#1] -- vbum1=vbuc1 
    lda #8
    sta max_digits
    // uctoa::@1
  __b1:
    // [2133] phi from uctoa::@1 to uctoa::@6 [phi:uctoa::@1->uctoa::@6]
    // [2133] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa::@1->uctoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2133] phi uctoa::started#2 = 0 [phi:uctoa::@1->uctoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [2133] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa::@1->uctoa::@6#2] -- register_copy 
    // [2133] phi uctoa::digit#2 = 0 [phi:uctoa::@1->uctoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // uctoa::@6
  __b6:
    // max_digits-1
    // [2134] uctoa::$4 = uctoa::max_digits#7 - 1 -- vbuz1=vbum2_minus_1 
    ldx max_digits
    dex
    stx.z uctoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2135] if(uctoa::digit#2<uctoa::$4) goto uctoa::@7 -- vbum1_lt_vbuz2_then_la1 
    lda digit
    cmp.z uctoa__4
    bcc __b7
    // uctoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2136] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy value
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2137] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2138] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // uctoa::@7
  __b7:
    // unsigned char digit_value = digit_values[digit]
    // [2139] uctoa::digit_value#0 = uctoa::digit_values#8[uctoa::digit#2] -- vbum1=pbuz2_derefidx_vbum3 
    ldy digit
    lda (digit_values),y
    sta digit_value
    // if (started || value >= digit_value)
    // [2140] if(0!=uctoa::started#2) goto uctoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // uctoa::@12
    // [2141] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@10 -- vbum1_ge_vbum2_then_la1 
    lda value
    cmp digit_value
    bcs __b10
    // [2142] phi from uctoa::@12 to uctoa::@9 [phi:uctoa::@12->uctoa::@9]
    // [2142] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@12->uctoa::@9#0] -- register_copy 
    // [2142] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@12->uctoa::@9#1] -- register_copy 
    // [2142] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@12->uctoa::@9#2] -- register_copy 
    // uctoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2143] uctoa::digit#1 = ++ uctoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [2133] phi from uctoa::@9 to uctoa::@6 [phi:uctoa::@9->uctoa::@6]
    // [2133] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@9->uctoa::@6#0] -- register_copy 
    // [2133] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@9->uctoa::@6#1] -- register_copy 
    // [2133] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@9->uctoa::@6#2] -- register_copy 
    // [2133] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@9->uctoa::@6#3] -- register_copy 
    jmp __b6
    // uctoa::@10
  __b10:
    // uctoa_append(buffer++, value, digit_value)
    // [2144] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [2145] uctoa_append::value#0 = uctoa::value#2
    // [2146] uctoa_append::sub#0 = uctoa::digit_value#0
    // [2147] call uctoa_append
    // [2476] phi from uctoa::@10 to uctoa_append [phi:uctoa::@10->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [2148] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@11
    // value = uctoa_append(buffer++, value, digit_value)
    // [2149] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [2150] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2142] phi from uctoa::@11 to uctoa::@9 [phi:uctoa::@11->uctoa::@9]
    // [2142] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@11->uctoa::@9#0] -- register_copy 
    // [2142] phi uctoa::started#4 = 1 [phi:uctoa::@11->uctoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [2142] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@11->uctoa::@9#2] -- register_copy 
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
    .label rom_address_from_bank__1 = $72
    .label return = $72
    .label return_1 = $5e
    // ((unsigned long)(rom_bank)) << 14
    // [2152] rom_address_from_bank::$1 = (unsigned long)rom_address_from_bank::rom_bank#3 -- vduz1=_dword_vbum2 
    lda rom_bank
    sta.z rom_address_from_bank__1
    lda #0
    sta.z rom_address_from_bank__1+1
    sta.z rom_address_from_bank__1+2
    sta.z rom_address_from_bank__1+3
    // [2153] rom_address_from_bank::return#0 = rom_address_from_bank::$1 << $e -- vduz1=vduz1_rol_vbuc1 
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
    // [2154] return 
    rts
  .segment Data
    .label rom_bank = rom_detect.rom_detect__4
    .label return_2 = main.flashed_bytes
}
.segment Code
  // rom_compare
// __zp($63) unsigned int rom_compare(__zp($f3) char bank_ram, __zp($70) char *ptr_ram, __zp($c4) unsigned long rom_compare_address, __zp($af) unsigned int rom_compare_size)
rom_compare: {
    .label rom_compare__5 = $62
    .label rom_bank1_rom_compare__0 = $c2
    .label rom_bank1_rom_compare__1 = $4d
    .label rom_bank1_rom_compare__2 = $b5
    .label rom_ptr1_rom_compare__0 = $5c
    .label rom_ptr1_rom_compare__2 = $5c
    .label rom_bank1_bank_unshifted = $b5
    .label rom_bank1_return = $ba
    .label rom_ptr1_return = $5c
    .label ptr_rom = $5c
    .label ptr_ram = $70
    .label compared_bytes = $69
    /// Holds the amount of bytes actually verified between the ROM and the RAM.
    .label equal_bytes = $63
    .label bank_ram = $f3
    .label rom_compare_address = $c4
    .label return = $63
    .label bank_ram_1 = $d5
    .label rom_compare_size = $af
    // rom_compare::bank_set_bram1
    // BRAM = bank
    // [2156] BRAM = rom_compare::bank_set_bram1_bank#0 -- vbuz1=vbum2 
    lda bank_set_bram1_bank
    sta.z BRAM
    // rom_compare::rom_bank1
    // BYTE2(address)
    // [2157] rom_compare::rom_bank1_$0 = byte2  rom_compare::rom_compare_address#3 -- vbuz1=_byte2_vduz2 
    lda.z rom_compare_address+2
    sta.z rom_bank1_rom_compare__0
    // BYTE1(address)
    // [2158] rom_compare::rom_bank1_$1 = byte1  rom_compare::rom_compare_address#3 -- vbuz1=_byte1_vduz2 
    lda.z rom_compare_address+1
    sta.z rom_bank1_rom_compare__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2159] rom_compare::rom_bank1_$2 = rom_compare::rom_bank1_$0 w= rom_compare::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_compare__0
    sta.z rom_bank1_rom_compare__2+1
    lda.z rom_bank1_rom_compare__1
    sta.z rom_bank1_rom_compare__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2160] rom_compare::rom_bank1_bank_unshifted#0 = rom_compare::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2161] rom_compare::rom_bank1_return#0 = byte1  rom_compare::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwuz2 
    lda.z rom_bank1_bank_unshifted+1
    sta.z rom_bank1_return
    // rom_compare::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2162] rom_compare::rom_ptr1_$2 = (unsigned int)rom_compare::rom_compare_address#3 -- vwuz1=_word_vduz2 
    lda.z rom_compare_address
    sta.z rom_ptr1_rom_compare__2
    lda.z rom_compare_address+1
    sta.z rom_ptr1_rom_compare__2+1
    // [2163] rom_compare::rom_ptr1_$0 = rom_compare::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_compare__0
    and #<$3fff
    sta.z rom_ptr1_rom_compare__0
    lda.z rom_ptr1_rom_compare__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_compare__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2164] rom_compare::rom_ptr1_return#0 = rom_compare::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_compare::bank_set_brom1
    // BROM = bank
    // [2165] BROM = rom_compare::rom_bank1_return#0 -- vbuz1=vbuz2 
    lda.z rom_bank1_return
    sta.z BROM
    // [2166] rom_compare::ptr_rom#9 = (char *)rom_compare::rom_ptr1_return#0
    // [2167] phi from rom_compare::bank_set_brom1 to rom_compare::@1 [phi:rom_compare::bank_set_brom1->rom_compare::@1]
    // [2167] phi rom_compare::equal_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z equal_bytes
    sta.z equal_bytes+1
    // [2167] phi rom_compare::ptr_ram#4 = rom_compare::ptr_ram#10 [phi:rom_compare::bank_set_brom1->rom_compare::@1#1] -- register_copy 
    // [2167] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#9 [phi:rom_compare::bank_set_brom1->rom_compare::@1#2] -- register_copy 
    // [2167] phi rom_compare::compared_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#3] -- vwuz1=vwuc1 
    sta.z compared_bytes
    sta.z compared_bytes+1
    // rom_compare::@1
  __b1:
    // while (compared_bytes < rom_compare_size)
    // [2168] if(rom_compare::compared_bytes#2<rom_compare::rom_compare_size#11) goto rom_compare::@2 -- vwuz1_lt_vwuz2_then_la1 
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
    // [2169] return 
    rts
    // rom_compare::@2
  __b2:
    // rom_byte_compare(ptr_rom, *ptr_ram)
    // [2170] rom_byte_compare::ptr_rom#0 = rom_compare::ptr_rom#2
    // [2171] rom_byte_compare::value#0 = *rom_compare::ptr_ram#4 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (ptr_ram),y
    sta.z rom_byte_compare.value
    // [2172] call rom_byte_compare
    jsr rom_byte_compare
    // [2173] rom_byte_compare::return#2 = rom_byte_compare::return#0
    // rom_compare::@5
    // [2174] rom_compare::$5 = rom_byte_compare::return#2
    // if (rom_byte_compare(ptr_rom, *ptr_ram))
    // [2175] if(0==rom_compare::$5) goto rom_compare::@3 -- 0_eq_vbuz1_then_la1 
    lda.z rom_compare__5
    beq __b3
    // rom_compare::@4
    // equal_bytes++;
    // [2176] rom_compare::equal_bytes#1 = ++ rom_compare::equal_bytes#2 -- vwuz1=_inc_vwuz1 
    inc.z equal_bytes
    bne !+
    inc.z equal_bytes+1
  !:
    // [2177] phi from rom_compare::@4 rom_compare::@5 to rom_compare::@3 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3]
    // [2177] phi rom_compare::equal_bytes#6 = rom_compare::equal_bytes#1 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3#0] -- register_copy 
    // rom_compare::@3
  __b3:
    // ptr_rom++;
    // [2178] rom_compare::ptr_rom#1 = ++ rom_compare::ptr_rom#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr_rom
    bne !+
    inc.z ptr_rom+1
  !:
    // ptr_ram++;
    // [2179] rom_compare::ptr_ram#0 = ++ rom_compare::ptr_ram#4 -- pbuz1=_inc_pbuz1 
    inc.z ptr_ram
    bne !+
    inc.z ptr_ram+1
  !:
    // compared_bytes++;
    // [2180] rom_compare::compared_bytes#1 = ++ rom_compare::compared_bytes#2 -- vwuz1=_inc_vwuz1 
    inc.z compared_bytes
    bne !+
    inc.z compared_bytes+1
  !:
    // [2167] phi from rom_compare::@3 to rom_compare::@1 [phi:rom_compare::@3->rom_compare::@1]
    // [2167] phi rom_compare::equal_bytes#2 = rom_compare::equal_bytes#6 [phi:rom_compare::@3->rom_compare::@1#0] -- register_copy 
    // [2167] phi rom_compare::ptr_ram#4 = rom_compare::ptr_ram#0 [phi:rom_compare::@3->rom_compare::@1#1] -- register_copy 
    // [2167] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#1 [phi:rom_compare::@3->rom_compare::@1#2] -- register_copy 
    // [2167] phi rom_compare::compared_bytes#2 = rom_compare::compared_bytes#1 [phi:rom_compare::@3->rom_compare::@1#3] -- register_copy 
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
    .label ultoa__10 = $4c
    .label ultoa__11 = $ba
    .label buffer = $4a
    .label digit_values = $76
    // if(radix==DECIMAL)
    // [2181] if(ultoa::radix#0==DECIMAL) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // ultoa::@2
    // if(radix==HEXADECIMAL)
    // [2182] if(ultoa::radix#0==HEXADECIMAL) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // ultoa::@3
    // if(radix==OCTAL)
    // [2183] if(ultoa::radix#0==OCTAL) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // ultoa::@4
    // if(radix==BINARY)
    // [2184] if(ultoa::radix#0==BINARY) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // ultoa::@5
    // *buffer++ = 'e'
    // [2185] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2186] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2187] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2188] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // ultoa::@return
    // }
    // [2189] return 
    rts
    // [2190] phi from ultoa to ultoa::@1 [phi:ultoa->ultoa::@1]
  __b2:
    // [2190] phi ultoa::digit_values#8 = RADIX_DECIMAL_VALUES_LONG [phi:ultoa->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2190] phi ultoa::max_digits#7 = $a [phi:ultoa->ultoa::@1#1] -- vbum1=vbuc1 
    lda #$a
    sta max_digits
    jmp __b1
    // [2190] phi from ultoa::@2 to ultoa::@1 [phi:ultoa::@2->ultoa::@1]
  __b3:
    // [2190] phi ultoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_LONG [phi:ultoa::@2->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2190] phi ultoa::max_digits#7 = 8 [phi:ultoa::@2->ultoa::@1#1] -- vbum1=vbuc1 
    lda #8
    sta max_digits
    jmp __b1
    // [2190] phi from ultoa::@3 to ultoa::@1 [phi:ultoa::@3->ultoa::@1]
  __b4:
    // [2190] phi ultoa::digit_values#8 = RADIX_OCTAL_VALUES_LONG [phi:ultoa::@3->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_OCTAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_LONG
    sta.z digit_values+1
    // [2190] phi ultoa::max_digits#7 = $b [phi:ultoa::@3->ultoa::@1#1] -- vbum1=vbuc1 
    lda #$b
    sta max_digits
    jmp __b1
    // [2190] phi from ultoa::@4 to ultoa::@1 [phi:ultoa::@4->ultoa::@1]
  __b5:
    // [2190] phi ultoa::digit_values#8 = RADIX_BINARY_VALUES_LONG [phi:ultoa::@4->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_BINARY_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_LONG
    sta.z digit_values+1
    // [2190] phi ultoa::max_digits#7 = $20 [phi:ultoa::@4->ultoa::@1#1] -- vbum1=vbuc1 
    lda #$20
    sta max_digits
    // ultoa::@1
  __b1:
    // [2191] phi from ultoa::@1 to ultoa::@6 [phi:ultoa::@1->ultoa::@6]
    // [2191] phi ultoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:ultoa::@1->ultoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2191] phi ultoa::started#2 = 0 [phi:ultoa::@1->ultoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [2191] phi ultoa::value#2 = ultoa::value#1 [phi:ultoa::@1->ultoa::@6#2] -- register_copy 
    // [2191] phi ultoa::digit#2 = 0 [phi:ultoa::@1->ultoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // ultoa::@6
  __b6:
    // max_digits-1
    // [2192] ultoa::$4 = ultoa::max_digits#7 - 1 -- vbuz1=vbum2_minus_1 
    ldx max_digits
    dex
    stx.z ultoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2193] if(ultoa::digit#2<ultoa::$4) goto ultoa::@7 -- vbum1_lt_vbuz2_then_la1 
    lda digit
    cmp.z ultoa__4
    bcc __b7
    // ultoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2194] ultoa::$11 = (char)ultoa::value#2 -- vbuz1=_byte_vdum2 
    lda value
    sta.z ultoa__11
    // [2195] *ultoa::buffer#11 = DIGITS[ultoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2196] ultoa::buffer#3 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2197] *ultoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // ultoa::@7
  __b7:
    // unsigned long digit_value = digit_values[digit]
    // [2198] ultoa::$10 = ultoa::digit#2 << 2 -- vbuz1=vbum2_rol_2 
    lda digit
    asl
    asl
    sta.z ultoa__10
    // [2199] ultoa::digit_value#0 = ultoa::digit_values#8[ultoa::$10] -- vdum1=pduz2_derefidx_vbuz3 
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
    // [2200] if(0!=ultoa::started#2) goto ultoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // ultoa::@12
    // [2201] if(ultoa::value#2>=ultoa::digit_value#0) goto ultoa::@10 -- vdum1_ge_vdum2_then_la1 
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
    // [2202] phi from ultoa::@12 to ultoa::@9 [phi:ultoa::@12->ultoa::@9]
    // [2202] phi ultoa::buffer#14 = ultoa::buffer#11 [phi:ultoa::@12->ultoa::@9#0] -- register_copy 
    // [2202] phi ultoa::started#4 = ultoa::started#2 [phi:ultoa::@12->ultoa::@9#1] -- register_copy 
    // [2202] phi ultoa::value#6 = ultoa::value#2 [phi:ultoa::@12->ultoa::@9#2] -- register_copy 
    // ultoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2203] ultoa::digit#1 = ++ ultoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [2191] phi from ultoa::@9 to ultoa::@6 [phi:ultoa::@9->ultoa::@6]
    // [2191] phi ultoa::buffer#11 = ultoa::buffer#14 [phi:ultoa::@9->ultoa::@6#0] -- register_copy 
    // [2191] phi ultoa::started#2 = ultoa::started#4 [phi:ultoa::@9->ultoa::@6#1] -- register_copy 
    // [2191] phi ultoa::value#2 = ultoa::value#6 [phi:ultoa::@9->ultoa::@6#2] -- register_copy 
    // [2191] phi ultoa::digit#2 = ultoa::digit#1 [phi:ultoa::@9->ultoa::@6#3] -- register_copy 
    jmp __b6
    // ultoa::@10
  __b10:
    // ultoa_append(buffer++, value, digit_value)
    // [2204] ultoa_append::buffer#0 = ultoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z ultoa_append.buffer
    lda.z buffer+1
    sta.z ultoa_append.buffer+1
    // [2205] ultoa_append::value#0 = ultoa::value#2
    // [2206] ultoa_append::sub#0 = ultoa::digit_value#0
    // [2207] call ultoa_append
    // [2487] phi from ultoa::@10 to ultoa_append [phi:ultoa::@10->ultoa_append]
    jsr ultoa_append
    // ultoa_append(buffer++, value, digit_value)
    // [2208] ultoa_append::return#0 = ultoa_append::value#2
    // ultoa::@11
    // value = ultoa_append(buffer++, value, digit_value)
    // [2209] ultoa::value#0 = ultoa_append::return#0
    // value = ultoa_append(buffer++, value, digit_value);
    // [2210] ultoa::buffer#4 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2202] phi from ultoa::@11 to ultoa::@9 [phi:ultoa::@11->ultoa::@9]
    // [2202] phi ultoa::buffer#14 = ultoa::buffer#4 [phi:ultoa::@11->ultoa::@9#0] -- register_copy 
    // [2202] phi ultoa::started#4 = 1 [phi:ultoa::@11->ultoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [2202] phi ultoa::value#6 = ultoa::value#0 [phi:ultoa::@11->ultoa::@9#2] -- register_copy 
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
// void rom_sector_erase(__zp($dc) unsigned long address)
rom_sector_erase: {
    .label rom_ptr1_rom_sector_erase__0 = $2d
    .label rom_ptr1_rom_sector_erase__2 = $2d
    .label rom_ptr1_return = $2d
    .label rom_chip_address = $5e
    .label address = $dc
    // rom_sector_erase::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2212] rom_sector_erase::rom_ptr1_$2 = (unsigned int)rom_sector_erase::address#0 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_sector_erase__2
    lda.z address+1
    sta.z rom_ptr1_rom_sector_erase__2+1
    // [2213] rom_sector_erase::rom_ptr1_$0 = rom_sector_erase::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_sector_erase__0
    and #<$3fff
    sta.z rom_ptr1_rom_sector_erase__0
    lda.z rom_ptr1_rom_sector_erase__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_sector_erase__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2214] rom_sector_erase::rom_ptr1_return#0 = rom_sector_erase::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_sector_erase::@1
    // unsigned long rom_chip_address = address & ROM_CHIP_MASK
    // [2215] rom_sector_erase::rom_chip_address#0 = rom_sector_erase::address#0 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [2216] rom_unlock::address#0 = rom_sector_erase::rom_chip_address#0 + $5555 -- vduz1=vduz1_plus_vwuc1 
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
    // [2217] call rom_unlock
    // [2494] phi from rom_sector_erase::@1 to rom_unlock [phi:rom_sector_erase::@1->rom_unlock]
    // [2494] phi rom_unlock::unlock_code#3 = $80 [phi:rom_sector_erase::@1->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$80
    sta.z rom_unlock.unlock_code
    // [2494] phi rom_unlock::address#3 = rom_unlock::address#0 [phi:rom_sector_erase::@1->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@2
    // rom_unlock(address, 0x30)
    // [2218] rom_unlock::address#1 = rom_sector_erase::address#0 -- vduz1=vduz2 
    lda.z address
    sta.z rom_unlock.address
    lda.z address+1
    sta.z rom_unlock.address+1
    lda.z address+2
    sta.z rom_unlock.address+2
    lda.z address+3
    sta.z rom_unlock.address+3
    // [2219] call rom_unlock
    // [2494] phi from rom_sector_erase::@2 to rom_unlock [phi:rom_sector_erase::@2->rom_unlock]
    // [2494] phi rom_unlock::unlock_code#3 = $30 [phi:rom_sector_erase::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$30
    sta.z rom_unlock.unlock_code
    // [2494] phi rom_unlock::address#3 = rom_unlock::address#1 [phi:rom_sector_erase::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@3
    // rom_wait(ptr_rom)
    // [2220] rom_wait::ptr_rom#0 = (char *)rom_sector_erase::rom_ptr1_return#0
    // [2221] call rom_wait
    // [2504] phi from rom_sector_erase::@3 to rom_wait [phi:rom_sector_erase::@3->rom_wait]
    // [2504] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#0 [phi:rom_sector_erase::@3->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_sector_erase::@return
    // }
    // [2222] return 
    rts
}
  // rom_write
/* inline */
// unsigned long rom_write(__zp($c3) char flash_ram_bank, __zp($6e) char *flash_ram_address, __zp($72) unsigned long flash_rom_address, unsigned int flash_rom_size)
rom_write: {
    .label rom_chip_address = $a9
    .label flash_rom_address = $72
    .label flash_ram_address = $6e
    .label flashed_bytes = $65
    .label flash_ram_bank = $c3
    // unsigned long rom_chip_address = flash_rom_address & ROM_CHIP_MASK
    // [2223] rom_write::rom_chip_address#0 = rom_write::flash_rom_address#1 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [2224] BRAM = rom_write::flash_ram_bank#0 -- vbuz1=vbuz2 
    lda.z flash_ram_bank
    sta.z BRAM
    // [2225] phi from rom_write::bank_set_bram1 to rom_write::@1 [phi:rom_write::bank_set_bram1->rom_write::@1]
    // [2225] phi rom_write::flash_ram_address#2 = rom_write::flash_ram_address#1 [phi:rom_write::bank_set_bram1->rom_write::@1#0] -- register_copy 
    // [2225] phi rom_write::flash_rom_address#3 = rom_write::flash_rom_address#1 [phi:rom_write::bank_set_bram1->rom_write::@1#1] -- register_copy 
    // [2225] phi rom_write::flashed_bytes#2 = 0 [phi:rom_write::bank_set_bram1->rom_write::@1#2] -- vduz1=vduc1 
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
    // [2226] if(rom_write::flashed_bytes#2<ROM_PROGRESS_CELL) goto rom_write::@2 -- vduz1_lt_vduc1_then_la1 
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
    // [2227] return 
    rts
    // rom_write::@2
  __b2:
    // rom_unlock(rom_chip_address + 0x05555, 0xA0)
    // [2228] rom_unlock::address#2 = rom_write::rom_chip_address#0 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [2229] call rom_unlock
    // [2494] phi from rom_write::@2 to rom_unlock [phi:rom_write::@2->rom_unlock]
    // [2494] phi rom_unlock::unlock_code#3 = $a0 [phi:rom_write::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$a0
    sta.z rom_unlock.unlock_code
    // [2494] phi rom_unlock::address#3 = rom_unlock::address#2 [phi:rom_write::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_write::@3
    // rom_byte_program(flash_rom_address, *flash_ram_address)
    // [2230] rom_byte_program::address#0 = rom_write::flash_rom_address#3 -- vduz1=vduz2 
    lda.z flash_rom_address
    sta.z rom_byte_program.address
    lda.z flash_rom_address+1
    sta.z rom_byte_program.address+1
    lda.z flash_rom_address+2
    sta.z rom_byte_program.address+2
    lda.z flash_rom_address+3
    sta.z rom_byte_program.address+3
    // [2231] rom_byte_program::value#0 = *rom_write::flash_ram_address#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (flash_ram_address),y
    sta.z rom_byte_program.value
    // [2232] call rom_byte_program
    // [2511] phi from rom_write::@3 to rom_byte_program [phi:rom_write::@3->rom_byte_program]
    jsr rom_byte_program
    // rom_write::@4
    // flash_rom_address++;
    // [2233] rom_write::flash_rom_address#0 = ++ rom_write::flash_rom_address#3 -- vduz1=_inc_vduz1 
    inc.z flash_rom_address
    bne !+
    inc.z flash_rom_address+1
    bne !+
    inc.z flash_rom_address+2
    bne !+
    inc.z flash_rom_address+3
  !:
    // flash_ram_address++;
    // [2234] rom_write::flash_ram_address#0 = ++ rom_write::flash_ram_address#2 -- pbuz1=_inc_pbuz1 
    inc.z flash_ram_address
    bne !+
    inc.z flash_ram_address+1
  !:
    // flashed_bytes++;
    // [2235] rom_write::flashed_bytes#1 = ++ rom_write::flashed_bytes#2 -- vduz1=_inc_vduz1 
    inc.z flashed_bytes
    bne !+
    inc.z flashed_bytes+1
    bne !+
    inc.z flashed_bytes+2
    bne !+
    inc.z flashed_bytes+3
  !:
    // [2225] phi from rom_write::@4 to rom_write::@1 [phi:rom_write::@4->rom_write::@1]
    // [2225] phi rom_write::flash_ram_address#2 = rom_write::flash_ram_address#0 [phi:rom_write::@4->rom_write::@1#0] -- register_copy 
    // [2225] phi rom_write::flash_rom_address#3 = rom_write::flash_rom_address#0 [phi:rom_write::@4->rom_write::@1#1] -- register_copy 
    // [2225] phi rom_write::flashed_bytes#2 = rom_write::flashed_bytes#1 [phi:rom_write::@4->rom_write::@1#2] -- register_copy 
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
    // [2236] cbm_k_getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // asm
    // asm { jsrCBM_GETIN stach  }
    jsr CBM_GETIN
    sta ch
    // return ch;
    // [2238] cbm_k_getin::return#0 = cbm_k_getin::ch -- vbum1=vbum2 
    sta return
    // cbm_k_getin::@return
    // }
    // [2239] cbm_k_getin::return#1 = cbm_k_getin::return#0
    // [2240] return 
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
    // [2241] insertup::$0 = *((char *)&__conio+6) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+6
    inc
    sta.z insertup__0
    // unsigned char width = (__conio.width+1) * 2
    // [2242] insertup::width#0 = insertup::$0 << 1 -- vbum1=vbuz2_rol_1 
    // {asm{.byte $db}}
    asl
    sta width
    // [2243] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [2243] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbum1=vbuc1 
    lda #0
    sta y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [2244] if(insertup::y#2<*((char *)&__conio+1)) goto insertup::@2 -- vbum1_lt__deref_pbuc1_then_la1 
    lda y
    cmp __conio+1
    bcc __b2
    // [2245] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [2246] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [2247] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [2248] insertup::$4 = insertup::y#2 + 1 -- vbuz1=vbum2_plus_1 
    lda y
    inc
    sta.z insertup__4
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [2249] insertup::$6 = insertup::y#2 << 1 -- vbuz1=vbum2_rol_1 
    lda y
    asl
    sta.z insertup__6
    // [2250] insertup::$7 = insertup::$4 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z insertup__7
    // [2251] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+5) -- vbum1=_deref_pbuc1 
    lda __conio+5
    sta memcpy8_vram_vram.dbank_vram
    // [2252] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwum1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__6
    lda __conio+$15,y
    sta memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta memcpy8_vram_vram.doffset_vram+1
    // [2253] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+5) -- vbum1=_deref_pbuc1 
    lda __conio+5
    sta memcpy8_vram_vram.sbank_vram
    // [2254] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwum1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__7
    lda __conio+$15,y
    sta memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,y
    sta memcpy8_vram_vram.soffset_vram+1
    // [2255] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbum1=vbum2 
    lda width
    sta memcpy8_vram_vram.num8_1
    // [2256] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [2257] insertup::y#1 = ++ insertup::y#2 -- vbum1=_inc_vbum1 
    inc y
    // [2243] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [2243] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
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
    // [2258] clearline::$3 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z clearline__3
    // [2259] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwum1=pwuc1_derefidx_vbuz2 
    tay
    lda __conio+$15,y
    sta addr
    lda __conio+$15+1,y
    sta addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2260] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [2261] clearline::$0 = byte0  clearline::addr#0 -- vbuz1=_byte0_vwum2 
    lda addr
    sta.z clearline__0
    // *VERA_ADDRX_L = BYTE0(addr)
    // [2262] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [2263] clearline::$1 = byte1  clearline::addr#0 -- vbuz1=_byte1_vwum2 
    lda addr+1
    sta.z clearline__1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [2264] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [2265] clearline::$2 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clearline__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [2266] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [2267] clearline::c#0 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z c
    // [2268] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [2268] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [2269] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [2270] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [2271] clearline::c#1 = -- clearline::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [2272] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b1
    // clearline::@return
    // }
    // [2273] return 
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
// __zp($41) char display_frame_maskxy(__mem() char x, __mem() char y)
display_frame_maskxy: {
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__0 = $62
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__1 = $6d
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__2 = $2a
    .label c = $29
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
    .label return = $41
    // display_frame_maskxy::cpeekcxy1
    // gotoxy(x,y)
    // [2275] gotoxy::x#5 = display_frame_maskxy::cpeekcxy1_x#0 -- vbum1=vbum2 
    lda cpeekcxy1_x
    sta gotoxy.x
    // [2276] gotoxy::y#5 = display_frame_maskxy::cpeekcxy1_y#0 -- vbum1=vbum2 
    lda cpeekcxy1_y
    sta gotoxy.y
    // [2277] call gotoxy
    // [573] phi from display_frame_maskxy::cpeekcxy1 to gotoxy [phi:display_frame_maskxy::cpeekcxy1->gotoxy]
    // [573] phi gotoxy::y#30 = gotoxy::y#5 [phi:display_frame_maskxy::cpeekcxy1->gotoxy#0] -- register_copy 
    // [573] phi gotoxy::x#30 = gotoxy::x#5 [phi:display_frame_maskxy::cpeekcxy1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_frame_maskxy::cpeekcxy1_cpeekc1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2278] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(__conio.offset)
    // [2279] display_frame_maskxy::cpeekcxy1_cpeekc1_$0 = byte0  *((unsigned int *)&__conio+$13) -- vbuz1=_byte0__deref_pwuc1 
    lda __conio+$13
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__0
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [2280] *VERA_ADDRX_L = display_frame_maskxy::cpeekcxy1_cpeekc1_$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [2281] display_frame_maskxy::cpeekcxy1_cpeekc1_$1 = byte1  *((unsigned int *)&__conio+$13) -- vbuz1=_byte1__deref_pwuc1 
    lda __conio+$13+1
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__1
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [2282] *VERA_ADDRX_M = display_frame_maskxy::cpeekcxy1_cpeekc1_$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_0
    // [2283] display_frame_maskxy::cpeekcxy1_cpeekc1_$2 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_0
    // [2284] *VERA_ADDRX_H = display_frame_maskxy::cpeekcxy1_cpeekc1_$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // return *VERA_DATA0;
    // [2285] display_frame_maskxy::c#0 = *VERA_DATA0 -- vbuz1=_deref_pbuc1 
    lda VERA_DATA0
    sta.z c
    // display_frame_maskxy::@12
    // case 0x70: // DR corner.
    //             return 0b0110;
    // [2286] if(display_frame_maskxy::c#0==$70) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$70
    cmp.z c
    beq __b2
    // display_frame_maskxy::@1
    // case 0x6E: // DL corner.
    //             return 0b0011;
    // [2287] if(display_frame_maskxy::c#0==$6e) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6e
    cmp.z c
    beq __b1
    // display_frame_maskxy::@2
    // case 0x6D: // UR corner.
    //             return 0b1100;
    // [2288] if(display_frame_maskxy::c#0==$6d) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6d
    cmp.z c
    beq __b3
    // display_frame_maskxy::@3
    // case 0x7D: // UL corner.
    //             return 0b1001;
    // [2289] if(display_frame_maskxy::c#0==$7d) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$7d
    cmp.z c
    beq __b4
    // display_frame_maskxy::@4
    // case 0x40: // HL line.
    //             return 0b0101;
    // [2290] if(display_frame_maskxy::c#0==$40) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$40
    cmp.z c
    beq __b5
    // display_frame_maskxy::@5
    // case 0x5D: // VL line.
    //             return 0b1010;
    // [2291] if(display_frame_maskxy::c#0==$5d) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$5d
    cmp.z c
    beq __b6
    // display_frame_maskxy::@6
    // case 0x6B: // VR junction.
    //             return 0b1110;
    // [2292] if(display_frame_maskxy::c#0==$6b) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6b
    cmp.z c
    beq __b7
    // display_frame_maskxy::@7
    // case 0x73: // VL junction.
    //             return 0b1011;
    // [2293] if(display_frame_maskxy::c#0==$73) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$73
    cmp.z c
    beq __b8
    // display_frame_maskxy::@8
    // case 0x72: // HD junction.
    //             return 0b0111;
    // [2294] if(display_frame_maskxy::c#0==$72) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$72
    cmp.z c
    beq __b9
    // display_frame_maskxy::@9
    // case 0x71: // HU junction.
    //             return 0b1101;
    // [2295] if(display_frame_maskxy::c#0==$71) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$71
    cmp.z c
    beq __b10
    // display_frame_maskxy::@10
    // case 0x5B: // HV junction.
    //             return 0b1111;
    // [2296] if(display_frame_maskxy::c#0==$5b) goto display_frame_maskxy::@11 -- vbuz1_eq_vbuc1_then_la1 
    lda #$5b
    cmp.z c
    beq __b11
    // [2298] phi from display_frame_maskxy::@10 to display_frame_maskxy::@return [phi:display_frame_maskxy::@10->display_frame_maskxy::@return]
    // [2298] phi display_frame_maskxy::return#12 = 0 [phi:display_frame_maskxy::@10->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #0
    sta.z return
    rts
    // [2297] phi from display_frame_maskxy::@10 to display_frame_maskxy::@11 [phi:display_frame_maskxy::@10->display_frame_maskxy::@11]
    // display_frame_maskxy::@11
  __b11:
    // [2298] phi from display_frame_maskxy::@11 to display_frame_maskxy::@return [phi:display_frame_maskxy::@11->display_frame_maskxy::@return]
    // [2298] phi display_frame_maskxy::return#12 = $f [phi:display_frame_maskxy::@11->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$f
    sta.z return
    rts
    // [2298] phi from display_frame_maskxy::@1 to display_frame_maskxy::@return [phi:display_frame_maskxy::@1->display_frame_maskxy::@return]
  __b1:
    // [2298] phi display_frame_maskxy::return#12 = 3 [phi:display_frame_maskxy::@1->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #3
    sta.z return
    rts
    // [2298] phi from display_frame_maskxy::@12 to display_frame_maskxy::@return [phi:display_frame_maskxy::@12->display_frame_maskxy::@return]
  __b2:
    // [2298] phi display_frame_maskxy::return#12 = 6 [phi:display_frame_maskxy::@12->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #6
    sta.z return
    rts
    // [2298] phi from display_frame_maskxy::@2 to display_frame_maskxy::@return [phi:display_frame_maskxy::@2->display_frame_maskxy::@return]
  __b3:
    // [2298] phi display_frame_maskxy::return#12 = $c [phi:display_frame_maskxy::@2->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$c
    sta.z return
    rts
    // [2298] phi from display_frame_maskxy::@3 to display_frame_maskxy::@return [phi:display_frame_maskxy::@3->display_frame_maskxy::@return]
  __b4:
    // [2298] phi display_frame_maskxy::return#12 = 9 [phi:display_frame_maskxy::@3->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #9
    sta.z return
    rts
    // [2298] phi from display_frame_maskxy::@4 to display_frame_maskxy::@return [phi:display_frame_maskxy::@4->display_frame_maskxy::@return]
  __b5:
    // [2298] phi display_frame_maskxy::return#12 = 5 [phi:display_frame_maskxy::@4->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #5
    sta.z return
    rts
    // [2298] phi from display_frame_maskxy::@5 to display_frame_maskxy::@return [phi:display_frame_maskxy::@5->display_frame_maskxy::@return]
  __b6:
    // [2298] phi display_frame_maskxy::return#12 = $a [phi:display_frame_maskxy::@5->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$a
    sta.z return
    rts
    // [2298] phi from display_frame_maskxy::@6 to display_frame_maskxy::@return [phi:display_frame_maskxy::@6->display_frame_maskxy::@return]
  __b7:
    // [2298] phi display_frame_maskxy::return#12 = $e [phi:display_frame_maskxy::@6->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$e
    sta.z return
    rts
    // [2298] phi from display_frame_maskxy::@7 to display_frame_maskxy::@return [phi:display_frame_maskxy::@7->display_frame_maskxy::@return]
  __b8:
    // [2298] phi display_frame_maskxy::return#12 = $b [phi:display_frame_maskxy::@7->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$b
    sta.z return
    rts
    // [2298] phi from display_frame_maskxy::@8 to display_frame_maskxy::@return [phi:display_frame_maskxy::@8->display_frame_maskxy::@return]
  __b9:
    // [2298] phi display_frame_maskxy::return#12 = 7 [phi:display_frame_maskxy::@8->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #7
    sta.z return
    rts
    // [2298] phi from display_frame_maskxy::@9 to display_frame_maskxy::@return [phi:display_frame_maskxy::@9->display_frame_maskxy::@return]
  __b10:
    // [2298] phi display_frame_maskxy::return#12 = $d [phi:display_frame_maskxy::@9->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$d
    sta.z return
    // display_frame_maskxy::@return
    // }
    // [2299] return 
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
// __zp($3c) char display_frame_char(__zp($41) char mask)
display_frame_char: {
    .label return = $3c
    .label mask = $41
    // case 0b0110:
    //             return 0x70;
    // [2301] if(display_frame_char::mask#10==6) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #6
    cmp.z mask
    beq __b1
    // display_frame_char::@1
    // case 0b0011:
    //             return 0x6E;
    // [2302] if(display_frame_char::mask#10==3) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // DR corner.
    lda #3
    cmp.z mask
    beq __b2
    // display_frame_char::@2
    // case 0b1100:
    //             return 0x6D;
    // [2303] if(display_frame_char::mask#10==$c) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // DL corner.
    lda #$c
    cmp.z mask
    beq __b3
    // display_frame_char::@3
    // case 0b1001:
    //             return 0x7D;
    // [2304] if(display_frame_char::mask#10==9) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // UR corner.
    lda #9
    cmp.z mask
    beq __b4
    // display_frame_char::@4
    // case 0b0101:
    //             return 0x40;
    // [2305] if(display_frame_char::mask#10==5) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // UL corner.
    lda #5
    cmp.z mask
    beq __b5
    // display_frame_char::@5
    // case 0b1010:
    //             return 0x5D;
    // [2306] if(display_frame_char::mask#10==$a) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // HL line.
    lda #$a
    cmp.z mask
    beq __b6
    // display_frame_char::@6
    // case 0b1110:
    //             return 0x6B;
    // [2307] if(display_frame_char::mask#10==$e) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VL line.
    lda #$e
    cmp.z mask
    beq __b7
    // display_frame_char::@7
    // case 0b1011:
    //             return 0x73;
    // [2308] if(display_frame_char::mask#10==$b) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VR junction.
    lda #$b
    cmp.z mask
    beq __b8
    // display_frame_char::@8
    // case 0b0111:
    //             return 0x72;
    // [2309] if(display_frame_char::mask#10==7) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VL junction.
    lda #7
    cmp.z mask
    beq __b9
    // display_frame_char::@9
    // case 0b1101:
    //             return 0x71;
    // [2310] if(display_frame_char::mask#10==$d) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // HD junction.
    lda #$d
    cmp.z mask
    beq __b10
    // display_frame_char::@10
    // case 0b1111:
    //             return 0x5B;
    // [2311] if(display_frame_char::mask#10==$f) goto display_frame_char::@11 -- vbuz1_eq_vbuc1_then_la1 
    // HU junction.
    lda #$f
    cmp.z mask
    beq __b11
    // [2313] phi from display_frame_char::@10 to display_frame_char::@return [phi:display_frame_char::@10->display_frame_char::@return]
    // [2313] phi display_frame_char::return#12 = $20 [phi:display_frame_char::@10->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$20
    sta.z return
    rts
    // [2312] phi from display_frame_char::@10 to display_frame_char::@11 [phi:display_frame_char::@10->display_frame_char::@11]
    // display_frame_char::@11
  __b11:
    // [2313] phi from display_frame_char::@11 to display_frame_char::@return [phi:display_frame_char::@11->display_frame_char::@return]
    // [2313] phi display_frame_char::return#12 = $5b [phi:display_frame_char::@11->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z return
    rts
    // [2313] phi from display_frame_char to display_frame_char::@return [phi:display_frame_char->display_frame_char::@return]
  __b1:
    // [2313] phi display_frame_char::return#12 = $70 [phi:display_frame_char->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$70
    sta.z return
    rts
    // [2313] phi from display_frame_char::@1 to display_frame_char::@return [phi:display_frame_char::@1->display_frame_char::@return]
  __b2:
    // [2313] phi display_frame_char::return#12 = $6e [phi:display_frame_char::@1->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6e
    sta.z return
    rts
    // [2313] phi from display_frame_char::@2 to display_frame_char::@return [phi:display_frame_char::@2->display_frame_char::@return]
  __b3:
    // [2313] phi display_frame_char::return#12 = $6d [phi:display_frame_char::@2->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6d
    sta.z return
    rts
    // [2313] phi from display_frame_char::@3 to display_frame_char::@return [phi:display_frame_char::@3->display_frame_char::@return]
  __b4:
    // [2313] phi display_frame_char::return#12 = $7d [phi:display_frame_char::@3->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$7d
    sta.z return
    rts
    // [2313] phi from display_frame_char::@4 to display_frame_char::@return [phi:display_frame_char::@4->display_frame_char::@return]
  __b5:
    // [2313] phi display_frame_char::return#12 = $40 [phi:display_frame_char::@4->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z return
    rts
    // [2313] phi from display_frame_char::@5 to display_frame_char::@return [phi:display_frame_char::@5->display_frame_char::@return]
  __b6:
    // [2313] phi display_frame_char::return#12 = $5d [phi:display_frame_char::@5->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z return
    rts
    // [2313] phi from display_frame_char::@6 to display_frame_char::@return [phi:display_frame_char::@6->display_frame_char::@return]
  __b7:
    // [2313] phi display_frame_char::return#12 = $6b [phi:display_frame_char::@6->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z return
    rts
    // [2313] phi from display_frame_char::@7 to display_frame_char::@return [phi:display_frame_char::@7->display_frame_char::@return]
  __b8:
    // [2313] phi display_frame_char::return#12 = $73 [phi:display_frame_char::@7->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z return
    rts
    // [2313] phi from display_frame_char::@8 to display_frame_char::@return [phi:display_frame_char::@8->display_frame_char::@return]
  __b9:
    // [2313] phi display_frame_char::return#12 = $72 [phi:display_frame_char::@8->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z return
    rts
    // [2313] phi from display_frame_char::@9 to display_frame_char::@return [phi:display_frame_char::@9->display_frame_char::@return]
  __b10:
    // [2313] phi display_frame_char::return#12 = $71 [phi:display_frame_char::@9->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z return
    // display_frame_char::@return
    // }
    // [2314] return 
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
// void display_chip_led(__zp($b2) char x, char y, __zp($b1) char w, __zp($2a) char tc, char bc)
display_chip_led: {
    .label x = $b2
    .label w = $b1
    .label tc = $2a
    // textcolor(tc)
    // [2316] textcolor::color#11 = display_chip_led::tc#3 -- vbum1=vbuz2 
    lda.z tc
    sta textcolor.color
    // [2317] call textcolor
    // [555] phi from display_chip_led to textcolor [phi:display_chip_led->textcolor]
    // [555] phi textcolor::color#18 = textcolor::color#11 [phi:display_chip_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [2318] phi from display_chip_led to display_chip_led::@3 [phi:display_chip_led->display_chip_led::@3]
    // display_chip_led::@3
    // bgcolor(bc)
    // [2319] call bgcolor
    // [560] phi from display_chip_led::@3 to bgcolor [phi:display_chip_led::@3->bgcolor]
    // [560] phi bgcolor::color#14 = BLUE [phi:display_chip_led::@3->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [2320] phi from display_chip_led::@3 display_chip_led::@5 to display_chip_led::@1 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1]
    // [2320] phi display_chip_led::w#4 = display_chip_led::w#7 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1#0] -- register_copy 
    // [2320] phi display_chip_led::x#4 = display_chip_led::x#7 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1#1] -- register_copy 
    // display_chip_led::@1
  __b1:
    // cputcxy(x, y, 0x6F)
    // [2321] cputcxy::x#9 = display_chip_led::x#4 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [2322] call cputcxy
    // [1781] phi from display_chip_led::@1 to cputcxy [phi:display_chip_led::@1->cputcxy]
    // [1781] phi cputcxy::c#15 = $6f [phi:display_chip_led::@1->cputcxy#0] -- vbum1=vbuc1 
    lda #$6f
    sta cputcxy.c
    // [1781] phi cputcxy::y#15 = 3 [phi:display_chip_led::@1->cputcxy#1] -- vbum1=vbuc1 
    lda #3
    sta cputcxy.y
    // [1781] phi cputcxy::x#15 = cputcxy::x#9 [phi:display_chip_led::@1->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_led::@4
    // cputcxy(x, y+1, 0x77)
    // [2323] cputcxy::x#10 = display_chip_led::x#4 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [2324] call cputcxy
    // [1781] phi from display_chip_led::@4 to cputcxy [phi:display_chip_led::@4->cputcxy]
    // [1781] phi cputcxy::c#15 = $77 [phi:display_chip_led::@4->cputcxy#0] -- vbum1=vbuc1 
    lda #$77
    sta cputcxy.c
    // [1781] phi cputcxy::y#15 = 3+1 [phi:display_chip_led::@4->cputcxy#1] -- vbum1=vbuc1 
    lda #3+1
    sta cputcxy.y
    // [1781] phi cputcxy::x#15 = cputcxy::x#10 [phi:display_chip_led::@4->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_led::@5
    // x++;
    // [2325] display_chip_led::x#0 = ++ display_chip_led::x#4 -- vbuz1=_inc_vbuz1 
    inc.z x
    // while(--w)
    // [2326] display_chip_led::w#0 = -- display_chip_led::w#4 -- vbuz1=_dec_vbuz1 
    dec.z w
    // [2327] if(0!=display_chip_led::w#0) goto display_chip_led::@1 -- 0_neq_vbuz1_then_la1 
    lda.z w
    bne __b1
    // [2328] phi from display_chip_led::@5 to display_chip_led::@2 [phi:display_chip_led::@5->display_chip_led::@2]
    // display_chip_led::@2
    // textcolor(WHITE)
    // [2329] call textcolor
    // [555] phi from display_chip_led::@2 to textcolor [phi:display_chip_led::@2->textcolor]
    // [555] phi textcolor::color#18 = WHITE [phi:display_chip_led::@2->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [2330] phi from display_chip_led::@2 to display_chip_led::@6 [phi:display_chip_led::@2->display_chip_led::@6]
    // display_chip_led::@6
    // bgcolor(BLUE)
    // [2331] call bgcolor
    // [560] phi from display_chip_led::@6 to bgcolor [phi:display_chip_led::@6->bgcolor]
    // [560] phi bgcolor::color#14 = BLUE [phi:display_chip_led::@6->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_led::@return
    // }
    // [2332] return 
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
// void display_chip_line(__mem() char x, __mem() char y, __zp($e0) char w, __zp($ee) char c)
display_chip_line: {
    .label i = $c3
    .label w = $e0
    .label c = $ee
    // gotoxy(x, y)
    // [2334] gotoxy::x#7 = display_chip_line::x#16 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [2335] gotoxy::y#7 = display_chip_line::y#16 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [2336] call gotoxy
    // [573] phi from display_chip_line to gotoxy [phi:display_chip_line->gotoxy]
    // [573] phi gotoxy::y#30 = gotoxy::y#7 [phi:display_chip_line->gotoxy#0] -- register_copy 
    // [573] phi gotoxy::x#30 = gotoxy::x#7 [phi:display_chip_line->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [2337] phi from display_chip_line to display_chip_line::@4 [phi:display_chip_line->display_chip_line::@4]
    // display_chip_line::@4
    // textcolor(GREY)
    // [2338] call textcolor
    // [555] phi from display_chip_line::@4 to textcolor [phi:display_chip_line::@4->textcolor]
    // [555] phi textcolor::color#18 = GREY [phi:display_chip_line::@4->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [2339] phi from display_chip_line::@4 to display_chip_line::@5 [phi:display_chip_line::@4->display_chip_line::@5]
    // display_chip_line::@5
    // bgcolor(BLUE)
    // [2340] call bgcolor
    // [560] phi from display_chip_line::@5 to bgcolor [phi:display_chip_line::@5->bgcolor]
    // [560] phi bgcolor::color#14 = BLUE [phi:display_chip_line::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_line::@6
    // cputc(VERA_CHR_UR)
    // [2341] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [2342] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [2344] call textcolor
    // [555] phi from display_chip_line::@6 to textcolor [phi:display_chip_line::@6->textcolor]
    // [555] phi textcolor::color#18 = WHITE [phi:display_chip_line::@6->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [2345] phi from display_chip_line::@6 to display_chip_line::@7 [phi:display_chip_line::@6->display_chip_line::@7]
    // display_chip_line::@7
    // bgcolor(BLACK)
    // [2346] call bgcolor
    // [560] phi from display_chip_line::@7 to bgcolor [phi:display_chip_line::@7->bgcolor]
    // [560] phi bgcolor::color#14 = BLACK [phi:display_chip_line::@7->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // [2347] phi from display_chip_line::@7 to display_chip_line::@1 [phi:display_chip_line::@7->display_chip_line::@1]
    // [2347] phi display_chip_line::i#2 = 0 [phi:display_chip_line::@7->display_chip_line::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // display_chip_line::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [2348] if(display_chip_line::i#2<display_chip_line::w#10) goto display_chip_line::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [2349] phi from display_chip_line::@1 to display_chip_line::@3 [phi:display_chip_line::@1->display_chip_line::@3]
    // display_chip_line::@3
    // textcolor(GREY)
    // [2350] call textcolor
    // [555] phi from display_chip_line::@3 to textcolor [phi:display_chip_line::@3->textcolor]
    // [555] phi textcolor::color#18 = GREY [phi:display_chip_line::@3->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [2351] phi from display_chip_line::@3 to display_chip_line::@8 [phi:display_chip_line::@3->display_chip_line::@8]
    // display_chip_line::@8
    // bgcolor(BLUE)
    // [2352] call bgcolor
    // [560] phi from display_chip_line::@8 to bgcolor [phi:display_chip_line::@8->bgcolor]
    // [560] phi bgcolor::color#14 = BLUE [phi:display_chip_line::@8->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_line::@9
    // cputc(VERA_CHR_UL)
    // [2353] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [2354] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [2356] call textcolor
    // [555] phi from display_chip_line::@9 to textcolor [phi:display_chip_line::@9->textcolor]
    // [555] phi textcolor::color#18 = WHITE [phi:display_chip_line::@9->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [2357] phi from display_chip_line::@9 to display_chip_line::@10 [phi:display_chip_line::@9->display_chip_line::@10]
    // display_chip_line::@10
    // bgcolor(BLACK)
    // [2358] call bgcolor
    // [560] phi from display_chip_line::@10 to bgcolor [phi:display_chip_line::@10->bgcolor]
    // [560] phi bgcolor::color#14 = BLACK [phi:display_chip_line::@10->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // display_chip_line::@11
    // cputcxy(x+2, y, c)
    // [2359] cputcxy::x#8 = display_chip_line::x#16 + 2 -- vbum1=vbum2_plus_2 
    lda x
    clc
    adc #2
    sta cputcxy.x
    // [2360] cputcxy::y#8 = display_chip_line::y#16 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [2361] cputcxy::c#8 = display_chip_line::c#15 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [2362] call cputcxy
    // [1781] phi from display_chip_line::@11 to cputcxy [phi:display_chip_line::@11->cputcxy]
    // [1781] phi cputcxy::c#15 = cputcxy::c#8 [phi:display_chip_line::@11->cputcxy#0] -- register_copy 
    // [1781] phi cputcxy::y#15 = cputcxy::y#8 [phi:display_chip_line::@11->cputcxy#1] -- register_copy 
    // [1781] phi cputcxy::x#15 = cputcxy::x#8 [phi:display_chip_line::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_line::@return
    // }
    // [2363] return 
    rts
    // display_chip_line::@2
  __b2:
    // cputc(VERA_CHR_SPACE)
    // [2364] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [2365] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [2367] display_chip_line::i#1 = ++ display_chip_line::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [2347] phi from display_chip_line::@2 to display_chip_line::@1 [phi:display_chip_line::@2->display_chip_line::@1]
    // [2347] phi display_chip_line::i#2 = display_chip_line::i#1 [phi:display_chip_line::@2->display_chip_line::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    .label x = rom_detect.rom_detect__13
    .label y = rom_detect.rom_detect__10
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
// void display_chip_end(__mem() char x, char y, __zp($f0) char w)
display_chip_end: {
    .label i = $ce
    .label w = $f0
    // gotoxy(x, y)
    // [2368] gotoxy::x#8 = display_chip_end::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [2369] call gotoxy
    // [573] phi from display_chip_end to gotoxy [phi:display_chip_end->gotoxy]
    // [573] phi gotoxy::y#30 = display_print_chip::y#21 [phi:display_chip_end->gotoxy#0] -- vbum1=vbuc1 
    lda #display_print_chip.y
    sta gotoxy.y
    // [573] phi gotoxy::x#30 = gotoxy::x#8 [phi:display_chip_end->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [2370] phi from display_chip_end to display_chip_end::@4 [phi:display_chip_end->display_chip_end::@4]
    // display_chip_end::@4
    // textcolor(GREY)
    // [2371] call textcolor
    // [555] phi from display_chip_end::@4 to textcolor [phi:display_chip_end::@4->textcolor]
    // [555] phi textcolor::color#18 = GREY [phi:display_chip_end::@4->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [2372] phi from display_chip_end::@4 to display_chip_end::@5 [phi:display_chip_end::@4->display_chip_end::@5]
    // display_chip_end::@5
    // bgcolor(BLUE)
    // [2373] call bgcolor
    // [560] phi from display_chip_end::@5 to bgcolor [phi:display_chip_end::@5->bgcolor]
    // [560] phi bgcolor::color#14 = BLUE [phi:display_chip_end::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_end::@6
    // cputc(VERA_CHR_UR)
    // [2374] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [2375] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [2377] call textcolor
    // [555] phi from display_chip_end::@6 to textcolor [phi:display_chip_end::@6->textcolor]
    // [555] phi textcolor::color#18 = BLUE [phi:display_chip_end::@6->textcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta textcolor.color
    jsr textcolor
    // [2378] phi from display_chip_end::@6 to display_chip_end::@7 [phi:display_chip_end::@6->display_chip_end::@7]
    // display_chip_end::@7
    // bgcolor(BLACK)
    // [2379] call bgcolor
    // [560] phi from display_chip_end::@7 to bgcolor [phi:display_chip_end::@7->bgcolor]
    // [560] phi bgcolor::color#14 = BLACK [phi:display_chip_end::@7->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // [2380] phi from display_chip_end::@7 to display_chip_end::@1 [phi:display_chip_end::@7->display_chip_end::@1]
    // [2380] phi display_chip_end::i#2 = 0 [phi:display_chip_end::@7->display_chip_end::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // display_chip_end::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [2381] if(display_chip_end::i#2<display_chip_end::w#0) goto display_chip_end::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [2382] phi from display_chip_end::@1 to display_chip_end::@3 [phi:display_chip_end::@1->display_chip_end::@3]
    // display_chip_end::@3
    // textcolor(GREY)
    // [2383] call textcolor
    // [555] phi from display_chip_end::@3 to textcolor [phi:display_chip_end::@3->textcolor]
    // [555] phi textcolor::color#18 = GREY [phi:display_chip_end::@3->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [2384] phi from display_chip_end::@3 to display_chip_end::@8 [phi:display_chip_end::@3->display_chip_end::@8]
    // display_chip_end::@8
    // bgcolor(BLUE)
    // [2385] call bgcolor
    // [560] phi from display_chip_end::@8 to bgcolor [phi:display_chip_end::@8->bgcolor]
    // [560] phi bgcolor::color#14 = BLUE [phi:display_chip_end::@8->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_end::@9
    // cputc(VERA_CHR_UL)
    // [2386] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [2387] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_chip_end::@return
    // }
    // [2389] return 
    rts
    // display_chip_end::@2
  __b2:
    // cputc(VERA_CHR_HL)
    // [2390] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [2391] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [2393] display_chip_end::i#1 = ++ display_chip_end::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [2380] phi from display_chip_end::@2 to display_chip_end::@1 [phi:display_chip_end::@2->display_chip_end::@1]
    // [2380] phi display_chip_end::i#2 = display_chip_end::i#1 [phi:display_chip_end::@2->display_chip_end::@1#0] -- register_copy 
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
    // [2395] phi from utoa_append to utoa_append::@1 [phi:utoa_append->utoa_append::@1]
    // [2395] phi utoa_append::digit#2 = 0 [phi:utoa_append->utoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [2395] phi utoa_append::value#2 = utoa_append::value#0 [phi:utoa_append->utoa_append::@1#1] -- register_copy 
    // utoa_append::@1
  __b1:
    // while (value >= sub)
    // [2396] if(utoa_append::value#2>=utoa_append::sub#0) goto utoa_append::@2 -- vwum1_ge_vwum2_then_la1 
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
    // [2397] *utoa_append::buffer#0 = DIGITS[utoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // utoa_append::@return
    // }
    // [2398] return 
    rts
    // utoa_append::@2
  __b2:
    // digit++;
    // [2399] utoa_append::digit#1 = ++ utoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [2400] utoa_append::value#1 = utoa_append::value#2 - utoa_append::sub#0 -- vwum1=vwum1_minus_vwum2 
    lda value
    sec
    sbc sub
    sta value
    lda value+1
    sbc sub+1
    sta value+1
    // [2395] phi from utoa_append::@2 to utoa_append::@1 [phi:utoa_append::@2->utoa_append::@1]
    // [2395] phi utoa_append::digit#2 = utoa_append::digit#1 [phi:utoa_append::@2->utoa_append::@1#0] -- register_copy 
    // [2395] phi utoa_append::value#2 = utoa_append::value#1 [phi:utoa_append::@2->utoa_append::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label value = printf_uint.uvalue
    .label sub = utoa.digit_value
    .label return = printf_uint.uvalue
    digit: .byte 0
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
    // [2402] return 
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
    .label ferror__6 = $62
    .label ferror__15 = $6d
    .label cbm_k_setnam1_ferror__0 = $54
    .label stream = $63
    .label errno_len = $29
    // unsigned char sp = (unsigned char)stream
    // [2403] ferror::sp#0 = (char)ferror::stream#0 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_setlfs(15, 8, 15)
    // [2404] cbm_k_setlfs::channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.channel
    // [2405] cbm_k_setlfs::device = 8 -- vbum1=vbuc1 
    lda #8
    sta cbm_k_setlfs.device
    // [2406] cbm_k_setlfs::command = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.command
    // [2407] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // ferror::@11
    // cbm_k_setnam("")
    // [2408] ferror::cbm_k_setnam1_filename = info_text4 -- pbum1=pbuc1 
    lda #<info_text4
    sta cbm_k_setnam1_filename
    lda #>info_text4
    sta cbm_k_setnam1_filename+1
    // ferror::cbm_k_setnam1
    // strlen(filename)
    // [2409] strlen::str#5 = ferror::cbm_k_setnam1_filename -- pbuz1=pbum2 
    lda cbm_k_setnam1_filename
    sta.z strlen.str
    lda cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [2410] call strlen
    // [1885] phi from ferror::cbm_k_setnam1 to strlen [phi:ferror::cbm_k_setnam1->strlen]
    // [1885] phi strlen::str#8 = strlen::str#5 [phi:ferror::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [2411] strlen::return#12 = strlen::len#2
    // ferror::@12
    // [2412] ferror::cbm_k_setnam1_$0 = strlen::return#12 -- vwuz1=vwum2 
    lda strlen.return
    sta.z cbm_k_setnam1_ferror__0
    lda strlen.return+1
    sta.z cbm_k_setnam1_ferror__0+1
    // char filename_len = (char)strlen(filename)
    // [2413] ferror::cbm_k_setnam1_filename_len = (char)ferror::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
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
    // [2416] ferror::cbm_k_chkin1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_chkin1_channel
    // ferror::cbm_k_chkin1
    // char status
    // [2417] ferror::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // ferror::cbm_k_chrin1
    // char ch
    // [2419] ferror::cbm_k_chrin1_ch = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chrin1_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin1_ch
    // return ch;
    // [2421] ferror::cbm_k_chrin1_return#0 = ferror::cbm_k_chrin1_ch -- vbum1=vbum2 
    sta cbm_k_chrin1_return
    // ferror::cbm_k_chrin1_@return
    // }
    // [2422] ferror::cbm_k_chrin1_return#1 = ferror::cbm_k_chrin1_return#0
    // ferror::@7
    // char ch = cbm_k_chrin()
    // [2423] ferror::ch#0 = ferror::cbm_k_chrin1_return#1
    // [2424] phi from ferror::@7 to ferror::cbm_k_readst1 [phi:ferror::@7->ferror::cbm_k_readst1]
    // [2424] phi __errno#179 = __errno#321 [phi:ferror::@7->ferror::cbm_k_readst1#0] -- register_copy 
    // [2424] phi ferror::errno_len#10 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z errno_len
    // [2424] phi ferror::ch#10 = ferror::ch#0 [phi:ferror::@7->ferror::cbm_k_readst1#2] -- register_copy 
    // [2424] phi ferror::errno_parsed#2 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#3] -- vbum1=vbuc1 
    sta errno_parsed
    // ferror::cbm_k_readst1
  cbm_k_readst1:
    // char status
    // [2425] ferror::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2427] ferror::cbm_k_readst1_return#0 = ferror::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // ferror::cbm_k_readst1_@return
    // }
    // [2428] ferror::cbm_k_readst1_return#1 = ferror::cbm_k_readst1_return#0
    // ferror::@8
    // cbm_k_readst()
    // [2429] ferror::$6 = ferror::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z ferror__6
    // st = cbm_k_readst()
    // [2430] ferror::st#1 = ferror::$6 -- vbum1=vbuz2 
    sta st
    // while (!(st = cbm_k_readst()))
    // [2431] if(0==ferror::st#1) goto ferror::@1 -- 0_eq_vbum1_then_la1 
    beq __b1
    // ferror::@2
    // __status = st
    // [2432] ((char *)&__stdio_file+$46)[ferror::sp#0] = ferror::st#1 -- pbuc1_derefidx_vbum1=vbum2 
    ldy sp
    sta __stdio_file+$46,y
    // cbm_k_close(15)
    // [2433] ferror::cbm_k_close1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_close1_channel
    // ferror::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // ferror::@9
    // return __errno;
    // [2435] ferror::return#1 = __errno#179 -- vwsm1=vwsm2 
    lda __errno
    sta return
    lda __errno+1
    sta return+1
    // ferror::@return
    // }
    // [2436] return 
    rts
    // ferror::@1
  __b1:
    // if (!errno_parsed)
    // [2437] if(0!=ferror::errno_parsed#2) goto ferror::@3 -- 0_neq_vbum1_then_la1 
    lda errno_parsed
    bne __b3
    // ferror::@4
    // if (ch == ',')
    // [2438] if(ferror::ch#10!=',') goto ferror::@3 -- vbum1_neq_vbuc1_then_la1 
    lda #','
    cmp ch
    bne __b3
    // ferror::@5
    // errno_parsed++;
    // [2439] ferror::errno_parsed#1 = ++ ferror::errno_parsed#2 -- vbum1=_inc_vbum1 
    inc errno_parsed
    // strncpy(temp, __errno_error, errno_len+1)
    // [2440] strncpy::n#0 = ferror::errno_len#10 + 1 -- vwum1=vbuz2_plus_1 
    lda.z errno_len
    clc
    adc #1
    sta strncpy.n
    lda #0
    adc #0
    sta strncpy.n+1
    // [2441] call strncpy
    // [1541] phi from ferror::@5 to strncpy [phi:ferror::@5->strncpy]
    // [1541] phi strncpy::dst#8 = ferror::temp [phi:ferror::@5->strncpy#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z strncpy.dst
    lda #>temp
    sta.z strncpy.dst+1
    // [1541] phi strncpy::src#6 = __errno_error [phi:ferror::@5->strncpy#1] -- pbuz1=pbuc1 
    lda #<__errno_error
    sta.z strncpy.src
    lda #>__errno_error
    sta.z strncpy.src+1
    // [1541] phi strncpy::n#3 = strncpy::n#0 [phi:ferror::@5->strncpy#2] -- register_copy 
    jsr strncpy
    // [2442] phi from ferror::@5 to ferror::@13 [phi:ferror::@5->ferror::@13]
    // ferror::@13
    // atoi(temp)
    // [2443] call atoi
    // [2455] phi from ferror::@13 to atoi [phi:ferror::@13->atoi]
    // [2455] phi atoi::str#2 = ferror::temp [phi:ferror::@13->atoi#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z atoi.str
    lda #>temp
    sta.z atoi.str+1
    jsr atoi
    // atoi(temp)
    // [2444] atoi::return#4 = atoi::return#2
    // ferror::@14
    // __errno = atoi(temp)
    // [2445] __errno#2 = atoi::return#4 -- vwsm1=vwsm2 
    lda atoi.return
    sta __errno
    lda atoi.return+1
    sta __errno+1
    // [2446] phi from ferror::@1 ferror::@14 ferror::@4 to ferror::@3 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3]
    // [2446] phi __errno#103 = __errno#179 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#0] -- register_copy 
    // [2446] phi ferror::errno_parsed#11 = ferror::errno_parsed#2 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#1] -- register_copy 
    // ferror::@3
  __b3:
    // __errno_error[errno_len] = ch
    // [2447] __errno_error[ferror::errno_len#10] = ferror::ch#10 -- pbuc1_derefidx_vbuz1=vbum2 
    lda ch
    ldy.z errno_len
    sta __errno_error,y
    // errno_len++;
    // [2448] ferror::errno_len#1 = ++ ferror::errno_len#10 -- vbuz1=_inc_vbuz1 
    inc.z errno_len
    // ferror::cbm_k_chrin2
    // char ch
    // [2449] ferror::cbm_k_chrin2_ch = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chrin2_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin2_ch
    // return ch;
    // [2451] ferror::cbm_k_chrin2_return#0 = ferror::cbm_k_chrin2_ch -- vbum1=vbum2 
    sta cbm_k_chrin2_return
    // ferror::cbm_k_chrin2_@return
    // }
    // [2452] ferror::cbm_k_chrin2_return#1 = ferror::cbm_k_chrin2_return#0
    // ferror::@10
    // cbm_k_chrin()
    // [2453] ferror::$15 = ferror::cbm_k_chrin2_return#1 -- vbuz1=vbum2 
    sta.z ferror__15
    // ch = cbm_k_chrin()
    // [2454] ferror::ch#1 = ferror::$15 -- vbum1=vbuz2 
    sta ch
    // [2424] phi from ferror::@10 to ferror::cbm_k_readst1 [phi:ferror::@10->ferror::cbm_k_readst1]
    // [2424] phi __errno#179 = __errno#103 [phi:ferror::@10->ferror::cbm_k_readst1#0] -- register_copy 
    // [2424] phi ferror::errno_len#10 = ferror::errno_len#1 [phi:ferror::@10->ferror::cbm_k_readst1#1] -- register_copy 
    // [2424] phi ferror::ch#10 = ferror::ch#1 [phi:ferror::@10->ferror::cbm_k_readst1#2] -- register_copy 
    // [2424] phi ferror::errno_parsed#2 = ferror::errno_parsed#11 [phi:ferror::@10->ferror::cbm_k_readst1#3] -- register_copy 
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
    // [2456] if(*atoi::str#2!='-') goto atoi::@3 -- _deref_pbuz1_neq_vbuc1_then_la1 
    ldy #0
    lda (str),y
    cmp #'-'
    bne __b2
    // [2457] phi from atoi to atoi::@2 [phi:atoi->atoi::@2]
    // atoi::@2
    // [2458] phi from atoi::@2 to atoi::@3 [phi:atoi::@2->atoi::@3]
    // [2458] phi atoi::negative#2 = 1 [phi:atoi::@2->atoi::@3#0] -- vbum1=vbuc1 
    lda #1
    sta negative
    // [2458] phi atoi::res#2 = 0 [phi:atoi::@2->atoi::@3#1] -- vwsm1=vwsc1 
    tya
    sta res
    sta res+1
    // [2458] phi atoi::i#4 = 1 [phi:atoi::@2->atoi::@3#2] -- vbum1=vbuc1 
    lda #1
    sta i
    jmp __b3
  // Iterate through all digits and update the result
    // [2458] phi from atoi to atoi::@3 [phi:atoi->atoi::@3]
  __b2:
    // [2458] phi atoi::negative#2 = 0 [phi:atoi->atoi::@3#0] -- vbum1=vbuc1 
    lda #0
    sta negative
    // [2458] phi atoi::res#2 = 0 [phi:atoi->atoi::@3#1] -- vwsm1=vwsc1 
    sta res
    sta res+1
    // [2458] phi atoi::i#4 = 0 [phi:atoi->atoi::@3#2] -- vbum1=vbuc1 
    sta i
    // atoi::@3
  __b3:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [2459] if(atoi::str#2[atoi::i#4]<'0') goto atoi::@5 -- pbuz1_derefidx_vbum2_lt_vbuc1_then_la1 
    ldy i
    lda (str),y
    cmp #'0'
    bcc __b5
    // atoi::@6
    // [2460] if(atoi::str#2[atoi::i#4]<='9') goto atoi::@4 -- pbuz1_derefidx_vbum2_le_vbuc1_then_la1 
    lda (str),y
    cmp #'9'
    bcc __b4
    beq __b4
    // atoi::@5
  __b5:
    // if(negative)
    // [2461] if(0!=atoi::negative#2) goto atoi::@1 -- 0_neq_vbum1_then_la1 
    // Return result with sign
    lda negative
    bne __b1
    // [2463] phi from atoi::@1 atoi::@5 to atoi::@return [phi:atoi::@1/atoi::@5->atoi::@return]
    // [2463] phi atoi::return#2 = atoi::return#0 [phi:atoi::@1/atoi::@5->atoi::@return#0] -- register_copy 
    rts
    // atoi::@1
  __b1:
    // return -res;
    // [2462] atoi::return#0 = - atoi::res#2 -- vwsm1=_neg_vwsm1 
    lda #0
    sec
    sbc return
    sta return
    lda #0
    sbc return+1
    sta return+1
    // atoi::@return
    // }
    // [2464] return 
    rts
    // atoi::@4
  __b4:
    // res * 10
    // [2465] atoi::$10 = atoi::res#2 << 2 -- vwsz1=vwsm2_rol_2 
    lda res
    asl
    sta.z atoi__10
    lda res+1
    rol
    sta.z atoi__10+1
    asl.z atoi__10
    rol.z atoi__10+1
    // [2466] atoi::$11 = atoi::$10 + atoi::res#2 -- vwsz1=vwsz1_plus_vwsm2 
    clc
    lda.z atoi__11
    adc res
    sta.z atoi__11
    lda.z atoi__11+1
    adc res+1
    sta.z atoi__11+1
    // [2467] atoi::$6 = atoi::$11 << 1 -- vwsz1=vwsz1_rol_1 
    asl.z atoi__6
    rol.z atoi__6+1
    // res * 10 + str[i]
    // [2468] atoi::$7 = atoi::$6 + atoi::str#2[atoi::i#4] -- vwsz1=vwsz1_plus_pbuz2_derefidx_vbum3 
    ldy i
    lda.z atoi__7
    clc
    adc (str),y
    sta.z atoi__7
    bcc !+
    inc.z atoi__7+1
  !:
    // res = res * 10 + str[i] - '0'
    // [2469] atoi::res#1 = atoi::$7 - '0' -- vwsm1=vwsz2_minus_vbuc1 
    lda.z atoi__7
    sec
    sbc #'0'
    sta res
    lda.z atoi__7+1
    sbc #0
    sta res+1
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [2470] atoi::i#2 = ++ atoi::i#4 -- vbum1=_inc_vbum1 
    inc i
    // [2458] phi from atoi::@4 to atoi::@3 [phi:atoi::@4->atoi::@3]
    // [2458] phi atoi::negative#2 = atoi::negative#2 [phi:atoi::@4->atoi::@3#0] -- register_copy 
    // [2458] phi atoi::res#2 = atoi::res#1 [phi:atoi::@4->atoi::@3#1] -- register_copy 
    // [2458] phi atoi::i#4 = atoi::i#2 [phi:atoi::@4->atoi::@3#2] -- register_copy 
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
    // [2471] cx16_k_macptr::bytes_read = 0 -- vwum1=vwuc1 
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
    // [2473] cx16_k_macptr::return#0 = cx16_k_macptr::bytes_read -- vwum1=vwum2 
    lda bytes_read
    sta return
    lda bytes_read+1
    sta return+1
    // cx16_k_macptr::@return
    // }
    // [2474] cx16_k_macptr::return#1 = cx16_k_macptr::return#0
    // [2475] return 
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
    // [2477] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [2477] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [2477] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [2478] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbum1_ge_vbum2_then_la1 
    lda value
    cmp sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [2479] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // uctoa_append::@return
    // }
    // [2480] return 
    rts
    // uctoa_append::@2
  __b2:
    // digit++;
    // [2481] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [2482] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbum1=vbum1_minus_vbum2 
    lda value
    sec
    sbc sub
    sta value
    // [2477] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [2477] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [2477] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
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
// __zp($62) char rom_byte_compare(__zp($5c) char *ptr_rom, __zp($4c) char value)
rom_byte_compare: {
    .label return = $62
    .label ptr_rom = $5c
    .label value = $4c
    // if (*ptr_rom != value)
    // [2483] if(*rom_byte_compare::ptr_rom#0==rom_byte_compare::value#0) goto rom_byte_compare::@1 -- _deref_pbuz1_eq_vbuz2_then_la1 
    lda.z value
    ldy #0
    cmp (ptr_rom),y
    beq __b2
    // [2484] phi from rom_byte_compare to rom_byte_compare::@2 [phi:rom_byte_compare->rom_byte_compare::@2]
    // rom_byte_compare::@2
    // [2485] phi from rom_byte_compare::@2 to rom_byte_compare::@1 [phi:rom_byte_compare::@2->rom_byte_compare::@1]
    // [2485] phi rom_byte_compare::return#0 = 0 [phi:rom_byte_compare::@2->rom_byte_compare::@1#0] -- vbuz1=vbuc1 
    tya
    sta.z return
    rts
    // [2485] phi from rom_byte_compare to rom_byte_compare::@1 [phi:rom_byte_compare->rom_byte_compare::@1]
  __b2:
    // [2485] phi rom_byte_compare::return#0 = 1 [phi:rom_byte_compare->rom_byte_compare::@1#0] -- vbuz1=vbuc1 
    lda #1
    sta.z return
    // rom_byte_compare::@1
    // rom_byte_compare::@return
    // }
    // [2486] return 
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
    // [2488] phi from ultoa_append to ultoa_append::@1 [phi:ultoa_append->ultoa_append::@1]
    // [2488] phi ultoa_append::digit#2 = 0 [phi:ultoa_append->ultoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [2488] phi ultoa_append::value#2 = ultoa_append::value#0 [phi:ultoa_append->ultoa_append::@1#1] -- register_copy 
    // ultoa_append::@1
  __b1:
    // while (value >= sub)
    // [2489] if(ultoa_append::value#2>=ultoa_append::sub#0) goto ultoa_append::@2 -- vdum1_ge_vdum2_then_la1 
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
    // [2490] *ultoa_append::buffer#0 = DIGITS[ultoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // ultoa_append::@return
    // }
    // [2491] return 
    rts
    // ultoa_append::@2
  __b2:
    // digit++;
    // [2492] ultoa_append::digit#1 = ++ ultoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [2493] ultoa_append::value#1 = ultoa_append::value#2 - ultoa_append::sub#0 -- vdum1=vdum1_minus_vdum2 
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
    // [2488] phi from ultoa_append::@2 to ultoa_append::@1 [phi:ultoa_append::@2->ultoa_append::@1]
    // [2488] phi ultoa_append::digit#2 = ultoa_append::digit#1 [phi:ultoa_append::@2->ultoa_append::@1#0] -- register_copy 
    // [2488] phi ultoa_append::value#2 = ultoa_append::value#1 [phi:ultoa_append::@2->ultoa_append::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label value = printf_ulong.uvalue
    .label sub = ultoa.digit_value
    .label return = printf_ulong.uvalue
    digit: .byte 0
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
// void rom_unlock(__zp($5e) unsigned long address, __zp($6d) char unlock_code)
rom_unlock: {
    .label chip_address = $58
    .label address = $5e
    .label unlock_code = $6d
    // unsigned long chip_address = address & ROM_CHIP_MASK
    // [2495] rom_unlock::chip_address#0 = rom_unlock::address#3 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [2496] rom_write_byte::address#0 = rom_unlock::chip_address#0 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [2497] call rom_write_byte
  // This is a very important operation...
    // [2541] phi from rom_unlock to rom_write_byte [phi:rom_unlock->rom_write_byte]
    // [2541] phi rom_write_byte::value#10 = $aa [phi:rom_unlock->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$aa
    sta.z rom_write_byte.value
    // [2541] phi rom_write_byte::address#4 = rom_write_byte::address#0 [phi:rom_unlock->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@1
    // rom_write_byte(chip_address + 0x02AAA, 0x55)
    // [2498] rom_write_byte::address#1 = rom_unlock::chip_address#0 + $2aaa -- vduz1=vduz2_plus_vwuc1 
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
    // [2499] call rom_write_byte
    // [2541] phi from rom_unlock::@1 to rom_write_byte [phi:rom_unlock::@1->rom_write_byte]
    // [2541] phi rom_write_byte::value#10 = $55 [phi:rom_unlock::@1->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$55
    sta.z rom_write_byte.value
    // [2541] phi rom_write_byte::address#4 = rom_write_byte::address#1 [phi:rom_unlock::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@2
    // rom_write_byte(address, unlock_code)
    // [2500] rom_write_byte::address#2 = rom_unlock::address#3 -- vduz1=vduz2 
    lda.z address
    sta.z rom_write_byte.address
    lda.z address+1
    sta.z rom_write_byte.address+1
    lda.z address+2
    sta.z rom_write_byte.address+2
    lda.z address+3
    sta.z rom_write_byte.address+3
    // [2501] rom_write_byte::value#2 = rom_unlock::unlock_code#3 -- vbuz1=vbuz2 
    lda.z unlock_code
    sta.z rom_write_byte.value
    // [2502] call rom_write_byte
    // [2541] phi from rom_unlock::@2 to rom_write_byte [phi:rom_unlock::@2->rom_write_byte]
    // [2541] phi rom_write_byte::value#10 = rom_write_byte::value#2 [phi:rom_unlock::@2->rom_write_byte#0] -- register_copy 
    // [2541] phi rom_write_byte::address#4 = rom_write_byte::address#2 [phi:rom_unlock::@2->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@return
    // }
    // [2503] return 
    rts
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
    // [2505] rom_wait::test1#1 = *rom_wait::ptr_rom#3 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (ptr_rom),y
    sta.z test1
    // test2 = *((brom_ptr_t)ptr_rom)
    // [2506] rom_wait::test2#1 = *rom_wait::ptr_rom#3 -- vbuz1=_deref_pbuz2 
    lda (ptr_rom),y
    sta.z test2
    // test1 & 0x40
    // [2507] rom_wait::$0 = rom_wait::test1#1 & $40 -- vbuz1=vbuz1_band_vbuc1 
    lda #$40
    and.z rom_wait__0
    sta.z rom_wait__0
    // test2 & 0x40
    // [2508] rom_wait::$1 = rom_wait::test2#1 & $40 -- vbuz1=vbuz1_band_vbuc1 
    lda #$40
    and.z rom_wait__1
    sta.z rom_wait__1
    // while ((test1 & 0x40) != (test2 & 0x40))
    // [2509] if(rom_wait::$0!=rom_wait::$1) goto rom_wait::@1 -- vbuz1_neq_vbuz2_then_la1 
    lda.z rom_wait__0
    cmp.z rom_wait__1
    bne __b1
    // rom_wait::@return
    // }
    // [2510] return 
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
    // [2512] rom_byte_program::rom_ptr1_$2 = (unsigned int)rom_byte_program::address#0 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_byte_program__2
    lda.z address+1
    sta.z rom_ptr1_rom_byte_program__2+1
    // [2513] rom_byte_program::rom_ptr1_$0 = rom_byte_program::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_byte_program__0
    and #<$3fff
    sta.z rom_ptr1_rom_byte_program__0
    lda.z rom_ptr1_rom_byte_program__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_byte_program__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2514] rom_byte_program::rom_ptr1_return#0 = rom_byte_program::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_byte_program::@1
    // rom_write_byte(address, value)
    // [2515] rom_write_byte::address#3 = rom_byte_program::address#0
    // [2516] rom_write_byte::value#3 = rom_byte_program::value#0
    // [2517] call rom_write_byte
    // [2541] phi from rom_byte_program::@1 to rom_write_byte [phi:rom_byte_program::@1->rom_write_byte]
    // [2541] phi rom_write_byte::value#10 = rom_write_byte::value#3 [phi:rom_byte_program::@1->rom_write_byte#0] -- register_copy 
    // [2541] phi rom_write_byte::address#4 = rom_write_byte::address#3 [phi:rom_byte_program::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_byte_program::@2
    // rom_wait(ptr_rom)
    // [2518] rom_wait::ptr_rom#1 = (char *)rom_byte_program::rom_ptr1_return#0 -- pbuz1=pbuz2 
    lda.z rom_ptr1_return
    sta.z rom_wait.ptr_rom
    lda.z rom_ptr1_return+1
    sta.z rom_wait.ptr_rom+1
    // [2519] call rom_wait
    // [2504] phi from rom_byte_program::@2 to rom_wait [phi:rom_byte_program::@2->rom_wait]
    // [2504] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#1 [phi:rom_byte_program::@2->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_byte_program::@return
    // }
    // [2520] return 
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
    // [2521] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [2522] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte0_vwum2 
    lda soffset_vram
    sta.z memcpy8_vram_vram__0
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [2523] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [2524] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte1_vwum2 
    lda soffset_vram+1
    sta.z memcpy8_vram_vram__1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [2525] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [2526] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbuz1=vbum2_bor_vbuc1 
    lda #VERA_INC_1
    ora sbank_vram
    sta.z memcpy8_vram_vram__2
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [2527] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [2528] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [2529] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte0_vwum2 
    lda doffset_vram
    sta.z memcpy8_vram_vram__3
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [2530] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [2531] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte1_vwum2 
    lda doffset_vram+1
    sta.z memcpy8_vram_vram__4
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [2532] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [2533] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbuz1=vbum2_bor_vbuc1 
    lda #VERA_INC_1
    ora dbank_vram
    sta.z memcpy8_vram_vram__5
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [2534] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // [2535] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [2535] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [2536] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbum1=_dec_vbum2 
    ldy num8_1
    dey
    sty num8
    // [2537] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbum1_then_la1 
    lda num8_1
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [2538] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [2539] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [2540] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbum1=vbum2 
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
    // [2542] rom_write_byte::rom_bank1_$0 = byte2  rom_write_byte::address#4 -- vbuz1=_byte2_vduz2 
    lda.z address+2
    sta.z rom_bank1_rom_write_byte__0
    // BYTE1(address)
    // [2543] rom_write_byte::rom_bank1_$1 = byte1  rom_write_byte::address#4 -- vbuz1=_byte1_vduz2 
    lda.z address+1
    sta.z rom_bank1_rom_write_byte__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2544] rom_write_byte::rom_bank1_$2 = rom_write_byte::rom_bank1_$0 w= rom_write_byte::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_write_byte__0
    sta.z rom_bank1_rom_write_byte__2+1
    lda.z rom_bank1_rom_write_byte__1
    sta.z rom_bank1_rom_write_byte__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2545] rom_write_byte::rom_bank1_bank_unshifted#0 = rom_write_byte::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2546] rom_write_byte::rom_bank1_return#0 = byte1  rom_write_byte::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwuz2 
    lda.z rom_bank1_bank_unshifted+1
    sta.z rom_bank1_return
    // rom_write_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2547] rom_write_byte::rom_ptr1_$2 = (unsigned int)rom_write_byte::address#4 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_write_byte__2
    lda.z address+1
    sta.z rom_ptr1_rom_write_byte__2+1
    // [2548] rom_write_byte::rom_ptr1_$0 = rom_write_byte::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_write_byte__0
    and #<$3fff
    sta.z rom_ptr1_rom_write_byte__0
    lda.z rom_ptr1_rom_write_byte__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_write_byte__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2549] rom_write_byte::rom_ptr1_return#0 = rom_write_byte::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_write_byte::bank_set_brom1
    // BROM = bank
    // [2550] BROM = rom_write_byte::rom_bank1_return#0 -- vbuz1=vbuz2 
    lda.z rom_bank1_return
    sta.z BROM
    // rom_write_byte::@1
    // *ptr_rom = value
    // [2551] *((char *)rom_write_byte::rom_ptr1_return#0) = rom_write_byte::value#10 -- _deref_pbuz1=vbuz2 
    lda.z value
    ldy #0
    sta (rom_ptr1_return),y
    // rom_write_byte::@return
    // }
    // [2552] return 
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
  smc_file_size: .word 0
  smc_file_size_1: .word 0
  smc_file_size_2: .word 0
