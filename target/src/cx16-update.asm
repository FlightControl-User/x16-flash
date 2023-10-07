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
  .const display_smc_rom_issue_count = 7
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
  .label __snprintf_buffer = $ed
  .label __errno = $c9
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
// void snputc(__register(X) char c)
snputc: {
    .const OFFSET_STACK_C = 0
    // [10] snputc::c#0 = stackidx(char,snputc::OFFSET_STACK_C) -- vbuxx=_stackidxbyte_vbuc1 
    tsx
    lda STACK_BASE+OFFSET_STACK_C,x
    tax
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
    // [16] phi snputc::c#2 = 0 [phi:snputc::@1->snputc::@2#0] -- vbuxx=vbuc1 
    ldx #0
    // [15] phi from snputc::@1 to snputc::@3 [phi:snputc::@1->snputc::@3]
    // snputc::@3
    // [16] phi from snputc::@3 to snputc::@2 [phi:snputc::@3->snputc::@2]
    // [16] phi snputc::c#2 = snputc::c#0 [phi:snputc::@3->snputc::@2#0] -- register_copy 
    // snputc::@2
  __b2:
    // *(__snprintf_buffer++) = c
    // [17] *__snprintf_buffer = snputc::c#2 -- _deref_pbuz1=vbuxx 
    // Append char
    txa
    ldy #0
    sta (__snprintf_buffer),y
    // *(__snprintf_buffer++) = c;
    // [18] __snprintf_buffer = ++ __snprintf_buffer -- pbuz1=_inc_pbuz1 
    inc.z __snprintf_buffer
    bne !+
    inc.z __snprintf_buffer+1
  !:
    rts
}
  // conio_x16_init
/// Set initial screen values.
conio_x16_init: {
    // screenlayer1()
    // [20] call screenlayer1
    jsr screenlayer1
    // [21] phi from conio_x16_init to conio_x16_init::@1 [phi:conio_x16_init->conio_x16_init::@1]
    // conio_x16_init::@1
    // textcolor(CONIO_TEXTCOLOR_DEFAULT)
    // [22] call textcolor
    // [700] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [700] phi textcolor::color#18 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [23] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [24] call bgcolor
    // [705] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [705] phi bgcolor::color#14 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
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
    // [31] conio_x16_init::$5 = byte1  conio_x16_init::$4 -- vbuaa=_byte1_vwum1 
    lda conio_x16_init__4+1
    // __conio.cursor_x = BYTE1(cbm_k_plot_get())
    // [32] *((char *)&__conio) = conio_x16_init::$5 -- _deref_pbuc1=vbuaa 
    sta __conio
    // cbm_k_plot_get()
    // [33] call cbm_k_plot_get
    jsr cbm_k_plot_get
    // [34] cbm_k_plot_get::return#3 = cbm_k_plot_get::return#0
    // conio_x16_init::@6
    // [35] conio_x16_init::$6 = cbm_k_plot_get::return#3
    // BYTE0(cbm_k_plot_get())
    // [36] conio_x16_init::$7 = byte0  conio_x16_init::$6 -- vbuaa=_byte0_vwum1 
    lda conio_x16_init__6
    // __conio.cursor_y = BYTE0(cbm_k_plot_get())
    // [37] *((char *)&__conio+1) = conio_x16_init::$7 -- _deref_pbuc1=vbuaa 
    sta __conio+1
    // gotoxy(__conio.cursor_x, __conio.cursor_y)
    // [38] gotoxy::x#2 = *((char *)&__conio) -- vbuxx=_deref_pbuc1 
    ldx __conio
    // [39] gotoxy::y#2 = *((char *)&__conio+1) -- vbuyy=_deref_pbuc1 
    tay
    // [40] call gotoxy
    // [718] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [718] phi gotoxy::y#30 = gotoxy::y#2 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [718] phi gotoxy::x#30 = gotoxy::x#2 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
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
}
.segment Code
  // cputc
// Output one character at the current cursor position
// Moves the cursor forward. Scrolls the entire screen if needed
// void cputc(__register(X) char c)
cputc: {
    .const OFFSET_STACK_C = 0
    // [44] cputc::c#0 = stackidx(char,cputc::OFFSET_STACK_C) -- vbuxx=_stackidxbyte_vbuc1 
    tsx
    lda STACK_BASE+OFFSET_STACK_C,x
    tax
    // if(c=='\n')
    // [45] if(cputc::c#0==' ') goto cputc::@1 -- vbuxx_eq_vbuc1_then_la1 
    cpx #'\n'
    beq __b1
    // cputc::@2
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [46] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(__conio.offset)
    // [47] cputc::$1 = byte0  *((unsigned int *)&__conio+$13) -- vbuaa=_byte0__deref_pwuc1 
    lda __conio+$13
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [48] *VERA_ADDRX_L = cputc::$1 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [49] cputc::$2 = byte1  *((unsigned int *)&__conio+$13) -- vbuaa=_byte1__deref_pwuc1 
    lda __conio+$13+1
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [50] *VERA_ADDRX_M = cputc::$2 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [51] cputc::$3 = *((char *)&__conio+5) | VERA_INC_1 -- vbuaa=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [52] *VERA_ADDRX_H = cputc::$3 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_H
    // *VERA_DATA0 = c
    // [53] *VERA_DATA0 = cputc::c#0 -- _deref_pbuc1=vbuxx 
    stx VERA_DATA0
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
    .const bank_set_brom5_bank = 4
    .const bank_push_set_bram1_bank = 1
    .const bank_set_bram2_bank = 0
    .const bank_set_brom6_bank = 0
    .label main__102 = $da
    .label main__159 = $c2
    .label release = $b7
    .label major = $e2
    .label minor = $29
    .label file_smc_release = $e7
    .label file_smc_major = $f7
    .label rom_bytes_read = $7c
    .label rom_file_modulo = $f8
    .label check_status_smc4_return = $e9
    .label check_status_vera1_return = $f1
    .label check_status_smc5_return = $f2
    .label check_status_smc6_return = $cb
    .label rom_bytes_read1 = $7c
    .label rom_differences = $25
    .label rom_flash_errors = $32
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
    // [75] phi from main::bank_set_brom1 to main::@58 [phi:main::bank_set_brom1->main::@58]
    // main::@58
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
    // [739] phi from main::@58 to display_frame_init_64 [phi:main::@58->display_frame_init_64]
    jsr display_frame_init_64
    // [77] phi from main::@58 to main::@82 [phi:main::@58->main::@82]
    // main::@82
    // display_frame_draw()
    // [78] call display_frame_draw
    // [759] phi from main::@82 to display_frame_draw [phi:main::@82->display_frame_draw]
    jsr display_frame_draw
    // [79] phi from main::@82 to main::@83 [phi:main::@82->main::@83]
    // main::@83
    // display_frame_title("Commander X16 Flash Utility!")
    // [80] call display_frame_title
    // [800] phi from main::@83 to display_frame_title [phi:main::@83->display_frame_title]
    jsr display_frame_title
    // [81] phi from main::@83 to main::display_info_title1 [phi:main::@83->main::display_info_title1]
    // main::display_info_title1
    // cputsxy(INFO_X-2, INFO_Y-2, "# Chip Status    Type   Curr. Release Update Info")
    // [82] call cputsxy
    // [805] phi from main::display_info_title1 to cputsxy [phi:main::display_info_title1->cputsxy]
    // [805] phi cputsxy::s#4 = main::s [phi:main::display_info_title1->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z cputsxy.s
    lda #>s
    sta.z cputsxy.s+1
    // [805] phi cputsxy::y#4 = $11-2 [phi:main::display_info_title1->cputsxy#1] -- vbuyy=vbuc1 
    ldy #$11-2
    // [805] phi cputsxy::x#4 = 4-2 [phi:main::display_info_title1->cputsxy#2] -- vbuxx=vbuc1 
    ldx #4-2
    jsr cputsxy
    // [83] phi from main::display_info_title1 to main::@84 [phi:main::display_info_title1->main::@84]
    // main::@84
    // cputsxy(INFO_X-2, INFO_Y-1, "- ---- --------- ------ ------------- --------------------")
    // [84] call cputsxy
    // [805] phi from main::@84 to cputsxy [phi:main::@84->cputsxy]
    // [805] phi cputsxy::s#4 = main::s1 [phi:main::@84->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s1
    sta.z cputsxy.s
    lda #>s1
    sta.z cputsxy.s+1
    // [805] phi cputsxy::y#4 = $11-1 [phi:main::@84->cputsxy#1] -- vbuyy=vbuc1 
    ldy #$11-1
    // [805] phi cputsxy::x#4 = 4-2 [phi:main::@84->cputsxy#2] -- vbuxx=vbuc1 
    ldx #4-2
    jsr cputsxy
    // [85] phi from main::@84 to main::@59 [phi:main::@84->main::@59]
    // main::@59
    // display_action_progress("Introduction ...")
    // [86] call display_action_progress
    // [812] phi from main::@59 to display_action_progress [phi:main::@59->display_action_progress]
    // [812] phi display_action_progress::info_text#15 = main::info_text [phi:main::@59->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [87] phi from main::@59 to main::@85 [phi:main::@59->main::@85]
    // main::@85
    // display_progress_clear()
    // [88] call display_progress_clear
    // [826] phi from main::@85 to display_progress_clear [phi:main::@85->display_progress_clear]
    jsr display_progress_clear
    // [89] phi from main::@85 to main::@86 [phi:main::@85->main::@86]
    // main::@86
    // display_chip_smc()
    // [90] call display_chip_smc
    // [841] phi from main::@86 to display_chip_smc [phi:main::@86->display_chip_smc]
    jsr display_chip_smc
    // [91] phi from main::@86 to main::@87 [phi:main::@86->main::@87]
    // main::@87
    // display_chip_vera()
    // [92] call display_chip_vera
    // [846] phi from main::@87 to display_chip_vera [phi:main::@87->display_chip_vera]
    jsr display_chip_vera
    // [93] phi from main::@87 to main::@88 [phi:main::@87->main::@88]
    // main::@88
    // display_chip_rom()
    // [94] call display_chip_rom
    // [851] phi from main::@88 to display_chip_rom [phi:main::@88->display_chip_rom]
    jsr display_chip_rom
    // [95] phi from main::@88 to main::@89 [phi:main::@88->main::@89]
    // main::@89
    // display_info_smc(STATUS_COLOR_NONE, NULL)
    // [96] call display_info_smc
    // [870] phi from main::@89 to display_info_smc [phi:main::@89->display_info_smc]
    // [870] phi display_info_smc::info_text#14 = 0 [phi:main::@89->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [870] phi display_info_smc::info_status#14 = BLACK [phi:main::@89->display_info_smc#1] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [97] phi from main::@89 to main::@90 [phi:main::@89->main::@90]
    // main::@90
    // display_info_vera(STATUS_NONE, NULL)
    // [98] call display_info_vera
    // [900] phi from main::@90 to display_info_vera [phi:main::@90->display_info_vera]
    // [900] phi display_info_vera::info_text#10 = 0 [phi:main::@90->display_info_vera#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_vera.info_text
    sta.z display_info_vera.info_text+1
    // [900] phi display_info_vera::info_status#3 = STATUS_NONE [phi:main::@90->display_info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_NONE
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // [99] phi from main::@90 to main::@7 [phi:main::@90->main::@7]
    // [99] phi main::rom_chip#2 = 0 [phi:main::@90->main::@7#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // main::@7
  __b7:
    // for(unsigned char rom_chip=0; rom_chip<8; rom_chip++)
    // [100] if(main::rom_chip#2<8) goto main::@8 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcs !__b8+
    jmp __b8
  !__b8:
    // main::bank_set_brom2
    // BROM = bank
    // [101] BROM = main::bank_set_brom2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom2_bank
    sta.z BROM
    // main::CLI1
    // asm
    // asm { cli  }
    cli
    // [103] phi from main::CLI1 to main::@60 [phi:main::CLI1->main::@60]
    // main::@60
    // display_progress_text(display_into_briefing_text, display_intro_briefing_count)
    // [104] call display_progress_text
    // [926] phi from main::@60 to display_progress_text [phi:main::@60->display_progress_text]
    // [926] phi display_progress_text::text#10 = display_into_briefing_text [phi:main::@60->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_into_briefing_text
    sta.z display_progress_text.text
    lda #>display_into_briefing_text
    sta.z display_progress_text.text+1
    // [926] phi display_progress_text::lines#11 = display_intro_briefing_count [phi:main::@60->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_intro_briefing_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [105] phi from main::@60 to main::@93 [phi:main::@60->main::@93]
    // main::@93
    // util_wait_space()
    // [106] call util_wait_space
    // [936] phi from main::@93 to util_wait_space [phi:main::@93->util_wait_space]
    jsr util_wait_space
    // [107] phi from main::@93 to main::@94 [phi:main::@93->main::@94]
    // main::@94
    // display_progress_text(display_into_colors_text, display_intro_colors_count)
    // [108] call display_progress_text
    // [926] phi from main::@94 to display_progress_text [phi:main::@94->display_progress_text]
    // [926] phi display_progress_text::text#10 = display_into_colors_text [phi:main::@94->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_into_colors_text
    sta.z display_progress_text.text
    lda #>display_into_colors_text
    sta.z display_progress_text.text+1
    // [926] phi display_progress_text::lines#11 = display_intro_colors_count [phi:main::@94->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_intro_colors_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [109] phi from main::@94 to main::@9 [phi:main::@94->main::@9]
    // [109] phi main::intro_status#2 = 0 [phi:main::@94->main::@9#0] -- vbum1=vbuc1 
    lda #0
    sta intro_status
    // main::@9
  __b9:
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [110] if(main::intro_status#2<$b) goto main::@10 -- vbum1_lt_vbuc1_then_la1 
    lda intro_status
    cmp #$b
    bcs !__b10+
    jmp __b10
  !__b10:
    // [111] phi from main::@9 to main::@11 [phi:main::@9->main::@11]
    // main::@11
    // util_wait_space()
    // [112] call util_wait_space
    // [936] phi from main::@11 to util_wait_space [phi:main::@11->util_wait_space]
    jsr util_wait_space
    // [113] phi from main::@11 to main::@96 [phi:main::@11->main::@96]
    // main::@96
    // display_progress_clear()
    // [114] call display_progress_clear
    // [826] phi from main::@96 to display_progress_clear [phi:main::@96->display_progress_clear]
    jsr display_progress_clear
    // main::SEI2
    // asm
    // asm { sei  }
    sei
    // main::bank_set_brom3
    // BROM = bank
    // [116] BROM = main::bank_set_brom3_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom3_bank
    sta.z BROM
    // [117] phi from main::bank_set_brom3 to main::@61 [phi:main::bank_set_brom3->main::@61]
    // main::@61
    // smc_detect()
    // [118] call smc_detect
    jsr smc_detect
    // [119] smc_detect::return#2 = smc_detect::return#0
    // main::@97
    // smc_bootloader = smc_detect()
    // [120] smc_bootloader#0 = smc_detect::return#2 -- vwum1=vwuz2 
    lda.z smc_detect.return
    sta smc_bootloader
    lda.z smc_detect.return+1
    sta smc_bootloader+1
    // strcpy(smc_version_string, "0.0.0")
    // [121] call strcpy
    // [950] phi from main::@97 to strcpy [phi:main::@97->strcpy]
    // [950] phi strcpy::dst#0 = smc_version_string [phi:main::@97->strcpy#0] -- pbuz1=pbuc1 
    lda #<smc_version_string
    sta.z strcpy.dst
    lda #>smc_version_string
    sta.z strcpy.dst+1
    // [950] phi strcpy::src#0 = main::source1 [phi:main::@97->strcpy#1] -- pbuz1=pbuc1 
    lda #<source1
    sta.z strcpy.src
    lda #>source1
    sta.z strcpy.src+1
    jsr strcpy
    // [122] phi from main::@97 to main::@98 [phi:main::@97->main::@98]
    // main::@98
    // display_chip_smc()
    // [123] call display_chip_smc
    // [841] phi from main::@98 to display_chip_smc [phi:main::@98->display_chip_smc]
    jsr display_chip_smc
    // main::@99
    // if(smc_bootloader == 0x0100)
    // [124] if(smc_bootloader#0==$100) goto main::@1 -- vwum1_eq_vwuc1_then_la1 
    lda smc_bootloader
    cmp #<$100
    bne !+
    lda smc_bootloader+1
    cmp #>$100
    bne !__b1+
    jmp __b1
  !__b1:
  !:
    // main::@12
    // if(smc_bootloader == 0x0200)
    // [125] if(smc_bootloader#0==$200) goto main::@15 -- vwum1_eq_vwuc1_then_la1 
    lda smc_bootloader
    cmp #<$200
    bne !+
    lda smc_bootloader+1
    cmp #>$200
    bne !__b15+
    jmp __b15
  !__b15:
  !:
    // main::@13
    // if(smc_bootloader > 0x2)
    // [126] if(smc_bootloader#0>=2+1) goto main::@16 -- vwum1_ge_vbuc1_then_la1 
    lda smc_bootloader+1
    beq !__b16+
    jmp __b16
  !__b16:
    lda smc_bootloader
    cmp #2+1
    bcc !__b16+
    jmp __b16
  !__b16:
  !:
    // main::@14
    // unsigned int release = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_VERSION)
    // [127] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [128] cx16_k_i2c_read_byte::offset = $30 -- vbum1=vbuc1 
    lda #$30
    sta cx16_k_i2c_read_byte.offset
    // [129] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [130] cx16_k_i2c_read_byte::return#14 = cx16_k_i2c_read_byte::return#1 -- vwuz1=vwuz2 
    lda.z cx16_k_i2c_read_byte.return
    sta.z cx16_k_i2c_read_byte.return_1
    lda.z cx16_k_i2c_read_byte.return+1
    sta.z cx16_k_i2c_read_byte.return_1+1
    // main::@106
    // [131] main::release#0 = cx16_k_i2c_read_byte::return#14
    // unsigned int major = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_MAJOR)
    // [132] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [133] cx16_k_i2c_read_byte::offset = $31 -- vbum1=vbuc1 
    lda #$31
    sta cx16_k_i2c_read_byte.offset
    // [134] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [135] cx16_k_i2c_read_byte::return#15 = cx16_k_i2c_read_byte::return#1 -- vwuz1=vwuz2 
    lda.z cx16_k_i2c_read_byte.return
    sta.z cx16_k_i2c_read_byte.return_2
    lda.z cx16_k_i2c_read_byte.return+1
    sta.z cx16_k_i2c_read_byte.return_2+1
    // main::@107
    // [136] main::major#0 = cx16_k_i2c_read_byte::return#15
    // unsigned int minor = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_MINOR)
    // [137] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [138] cx16_k_i2c_read_byte::offset = $32 -- vbum1=vbuc1 
    lda #$32
    sta cx16_k_i2c_read_byte.offset
    // [139] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [140] cx16_k_i2c_read_byte::return#16 = cx16_k_i2c_read_byte::return#1
    // main::@108
    // [141] main::minor#0 = cx16_k_i2c_read_byte::return#16
    // smc_get_version_text(smc_version_string, release, major, minor)
    // [142] smc_get_version_text::release#0 = main::release#0 -- vbuyy=vwuz1 
    ldy.z release
    // [143] smc_get_version_text::major#0 = main::major#0 -- vbuz1=vwuz2 
    lda.z major
    sta.z smc_get_version_text.major
    // [144] smc_get_version_text::minor#0 = main::minor#0 -- vbuz1=vwuz2 
    lda.z minor
    sta.z smc_get_version_text.minor
    // [145] call smc_get_version_text
    // [963] phi from main::@108 to smc_get_version_text [phi:main::@108->smc_get_version_text]
    // [963] phi smc_get_version_text::minor#2 = smc_get_version_text::minor#0 [phi:main::@108->smc_get_version_text#0] -- register_copy 
    // [963] phi smc_get_version_text::major#2 = smc_get_version_text::major#0 [phi:main::@108->smc_get_version_text#1] -- register_copy 
    // [963] phi smc_get_version_text::release#2 = smc_get_version_text::release#0 [phi:main::@108->smc_get_version_text#2] -- register_copy 
    // [963] phi smc_get_version_text::version_string#2 = smc_version_string [phi:main::@108->smc_get_version_text#3] -- pbuz1=pbuc1 
    lda #<smc_version_string
    sta.z smc_get_version_text.version_string
    lda #>smc_version_string
    sta.z smc_get_version_text.version_string+1
    jsr smc_get_version_text
    // [146] phi from main::@108 to main::@109 [phi:main::@108->main::@109]
    // main::@109
    // sprintf(info_text, "BL:v%u", smc_bootloader)
    // [147] call snprintf_init
    // [982] phi from main::@109 to snprintf_init [phi:main::@109->snprintf_init]
    // [982] phi snprintf_init::s#27 = info_text [phi:main::@109->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [148] phi from main::@109 to main::@110 [phi:main::@109->main::@110]
    // main::@110
    // sprintf(info_text, "BL:v%u", smc_bootloader)
    // [149] call printf_str
    // [987] phi from main::@110 to printf_str [phi:main::@110->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:main::@110->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = main::s4 [phi:main::@110->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // main::@111
    // sprintf(info_text, "BL:v%u", smc_bootloader)
    // [150] printf_uint::uvalue#13 = smc_bootloader#0 -- vwuz1=vwum2 
    lda smc_bootloader
    sta.z printf_uint.uvalue
    lda smc_bootloader+1
    sta.z printf_uint.uvalue+1
    // [151] call printf_uint
    // [996] phi from main::@111 to printf_uint [phi:main::@111->printf_uint]
    // [996] phi printf_uint::format_zero_padding#15 = 0 [phi:main::@111->printf_uint#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uint.format_zero_padding
    // [996] phi printf_uint::format_min_length#15 = 0 [phi:main::@111->printf_uint#1] -- vbuz1=vbuc1 
    sta.z printf_uint.format_min_length
    // [996] phi printf_uint::format_radix#15 = DECIMAL [phi:main::@111->printf_uint#2] -- vbuxx=vbuc1 
    ldx #DECIMAL
    // [996] phi printf_uint::uvalue#15 = printf_uint::uvalue#13 [phi:main::@111->printf_uint#3] -- register_copy 
    jsr printf_uint
    // main::@112
    // sprintf(info_text, "BL:v%u", smc_bootloader)
    // [152] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [153] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_smc(STATUS_DETECTED, info_text)
    // [155] call display_info_smc
  // All ok, display bootloader version.
    // [870] phi from main::@112 to display_info_smc [phi:main::@112->display_info_smc]
    // [870] phi display_info_smc::info_text#14 = info_text [phi:main::@112->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_smc.info_text
    lda #>@info_text
    sta.z display_info_smc.info_text+1
    // [870] phi display_info_smc::info_status#14 = STATUS_DETECTED [phi:main::@112->display_info_smc#1] -- vbuz1=vbuc1 
    lda #STATUS_DETECTED
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [156] phi from main::@100 main::@105 main::@112 main::@15 to main::@2 [phi:main::@100/main::@105/main::@112/main::@15->main::@2]
    // main::@2
  __b2:
    // display_chip_vera()
    // [157] call display_chip_vera
  // Detecting VERA FPGA.
    // [846] phi from main::@2 to display_chip_vera [phi:main::@2->display_chip_vera]
    jsr display_chip_vera
    // [158] phi from main::@2 to main::@113 [phi:main::@2->main::@113]
    // main::@113
    // display_info_vera(STATUS_DETECTED, "VERA installed, OK")
    // [159] call display_info_vera
    // [900] phi from main::@113 to display_info_vera [phi:main::@113->display_info_vera]
    // [900] phi display_info_vera::info_text#10 = main::info_text3 [phi:main::@113->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text3
    sta.z display_info_vera.info_text
    lda #>info_text3
    sta.z display_info_vera.info_text+1
    // [900] phi display_info_vera::info_status#3 = STATUS_DETECTED [phi:main::@113->display_info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_DETECTED
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // [160] phi from main::@113 to main::@114 [phi:main::@113->main::@114]
    // main::@114
    // rom_detect()
    // [161] call rom_detect
  // Detecting ROM chips
    // [1006] phi from main::@114 to rom_detect [phi:main::@114->rom_detect]
    jsr rom_detect
    // [162] phi from main::@114 to main::@115 [phi:main::@114->main::@115]
    // main::@115
    // display_chip_rom()
    // [163] call display_chip_rom
    // [851] phi from main::@115 to display_chip_rom [phi:main::@115->display_chip_rom]
    jsr display_chip_rom
    // [164] phi from main::@115 to main::@17 [phi:main::@115->main::@17]
    // [164] phi main::rom_chip1#10 = 0 [phi:main::@115->main::@17#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip1
    // main::@17
  __b17:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [165] if(main::rom_chip1#10<8) goto main::@18 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip1
    cmp #8
    bcs !__b18+
    jmp __b18
  !__b18:
    // main::SEI3
    // asm
    // asm { sei  }
    sei
    // main::check_status_smc1
    // status_smc == status
    // [167] main::check_status_smc1_$0 = status_smc#0 == STATUS_DETECTED -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_DETECTED
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [168] main::check_status_smc1_return#0 = (char)main::check_status_smc1_$0
    // main::@62
    // if(check_status_smc(STATUS_DETECTED))
    // [169] if(0==main::check_status_smc1_return#0) goto main::CLI2 -- 0_eq_vbuaa_then_la1 
    cmp #0
    bne !__b6+
    jmp __b6
  !__b6:
    // [170] phi from main::@62 to main::@21 [phi:main::@62->main::@21]
    // main::@21
    // smc_read(0)
    // [171] call smc_read
    // [1056] phi from main::@21 to smc_read [phi:main::@21->smc_read]
    // [1056] phi smc_read::display_progress#19 = 0 [phi:main::@21->smc_read#0] -- vbum1=vbuc1 
    lda #0
    sta smc_read.display_progress
    // [1056] phi __errno#35 = 0 [phi:main::@21->smc_read#1] -- vwsz1=vwsc1 
    sta.z __errno
    sta.z __errno+1
    jsr smc_read
    // smc_read(0)
    // [172] smc_read::return#2 = smc_read::return#0
    // main::@120
    // smc_file_size = smc_read(0)
    // [173] smc_file_size#0 = smc_read::return#2 -- vwum1=vwuz2 
    lda.z smc_read.return
    sta smc_file_size
    lda.z smc_read.return+1
    sta smc_file_size+1
    // if (!smc_file_size)
    // [174] if(0==smc_file_size#0) goto main::@24 -- 0_eq_vwum1_then_la1 
    // In case no file was found, set the status to error and skip to the next, else, mention the amount of bytes read.
    lda smc_file_size
    ora smc_file_size+1
    bne !__b24+
    jmp __b24
  !__b24:
    // main::@22
    // if(smc_file_size > 0x1E00)
    // [175] if(smc_file_size#0>$1e00) goto main::@25 -- vwum1_gt_vwuc1_then_la1 
    // If the smc.bin file size is larger than 0x1E00 then there is an issue!
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
    // main::@23
    // unsigned char file_smc_release = rom_get_release(*((char*)0xA030))
    // [176] rom_get_release::release#2 = *((char *) 41008) -- vbuxx=_deref_pbuc1 
    ldx $a030
    // [177] call rom_get_release
  // All ok, display the SMC.BIN file version and SMC on-board bootloader.
  // Fill the version data ...
    // [1114] phi from main::@23 to rom_get_release [phi:main::@23->rom_get_release]
    // [1114] phi rom_get_release::release#4 = rom_get_release::release#2 [phi:main::@23->rom_get_release#0] -- register_copy 
    jsr rom_get_release
    // unsigned char file_smc_release = rom_get_release(*((char*)0xA030))
    // [178] rom_get_release::return#3 = rom_get_release::return#0
    // main::@121
    // [179] main::file_smc_release#0 = rom_get_release::return#3 -- vbuz1=vbuxx 
    stx.z file_smc_release
    // unsigned char file_smc_major = rom_get_prefix(*((char*)0xA031))
    // [180] rom_get_prefix::release#1 = *((char *) 41009) -- vbuaa=_deref_pbuc1 
    lda $a031
    // [181] call rom_get_prefix
    // [1121] phi from main::@121 to rom_get_prefix [phi:main::@121->rom_get_prefix]
    // [1121] phi rom_get_prefix::release#4 = rom_get_prefix::release#1 [phi:main::@121->rom_get_prefix#0] -- register_copy 
    jsr rom_get_prefix
    // unsigned char file_smc_major = rom_get_prefix(*((char*)0xA031))
    // [182] rom_get_prefix::return#3 = rom_get_prefix::return#0
    // main::@122
    // [183] main::file_smc_major#0 = rom_get_prefix::return#3 -- vbuz1=vbuxx 
    stx.z file_smc_major
    // unsigned char file_smc_minor = rom_get_prefix(*((char*)0xA032))
    // [184] rom_get_prefix::release#2 = *((char *) 41010) -- vbuaa=_deref_pbuc1 
    lda $a032
    // [185] call rom_get_prefix
    // [1121] phi from main::@122 to rom_get_prefix [phi:main::@122->rom_get_prefix]
    // [1121] phi rom_get_prefix::release#4 = rom_get_prefix::release#2 [phi:main::@122->rom_get_prefix#0] -- register_copy 
    jsr rom_get_prefix
    // unsigned char file_smc_minor = rom_get_prefix(*((char*)0xA032))
    // [186] rom_get_prefix::return#4 = rom_get_prefix::return#0
    // main::@123
    // [187] main::file_smc_minor#0 = rom_get_prefix::return#4
    // smc_get_version_text(file_smc_version_text, file_smc_release, file_smc_major, file_smc_minor)
    // [188] smc_get_version_text::release#1 = main::file_smc_release#0 -- vbuyy=vbuz1 
    ldy.z file_smc_release
    // [189] smc_get_version_text::major#1 = main::file_smc_major#0
    // [190] smc_get_version_text::minor#1 = main::file_smc_minor#0 -- vbuz1=vbuxx 
    stx.z smc_get_version_text.minor
    // [191] call smc_get_version_text
    // [963] phi from main::@123 to smc_get_version_text [phi:main::@123->smc_get_version_text]
    // [963] phi smc_get_version_text::minor#2 = smc_get_version_text::minor#1 [phi:main::@123->smc_get_version_text#0] -- register_copy 
    // [963] phi smc_get_version_text::major#2 = smc_get_version_text::major#1 [phi:main::@123->smc_get_version_text#1] -- register_copy 
    // [963] phi smc_get_version_text::release#2 = smc_get_version_text::release#1 [phi:main::@123->smc_get_version_text#2] -- register_copy 
    // [963] phi smc_get_version_text::version_string#2 = main::file_smc_version_text [phi:main::@123->smc_get_version_text#3] -- pbuz1=pbuc1 
    lda #<file_smc_version_text
    sta.z smc_get_version_text.version_string
    lda #>file_smc_version_text
    sta.z smc_get_version_text.version_string+1
    jsr smc_get_version_text
    // [192] phi from main::@123 to main::@124 [phi:main::@123->main::@124]
    // main::@124
    // sprintf(info_text, "BL:v%u, SMC:%s", smc_bootloader, file_smc_version_text)
    // [193] call snprintf_init
    // [982] phi from main::@124 to snprintf_init [phi:main::@124->snprintf_init]
    // [982] phi snprintf_init::s#27 = info_text [phi:main::@124->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [194] phi from main::@124 to main::@125 [phi:main::@124->main::@125]
    // main::@125
    // sprintf(info_text, "BL:v%u, SMC:%s", smc_bootloader, file_smc_version_text)
    // [195] call printf_str
    // [987] phi from main::@125 to printf_str [phi:main::@125->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:main::@125->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = main::s4 [phi:main::@125->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // main::@126
    // sprintf(info_text, "BL:v%u, SMC:%s", smc_bootloader, file_smc_version_text)
    // [196] printf_uint::uvalue#14 = smc_bootloader#0 -- vwuz1=vwum2 
    lda smc_bootloader
    sta.z printf_uint.uvalue
    lda smc_bootloader+1
    sta.z printf_uint.uvalue+1
    // [197] call printf_uint
    // [996] phi from main::@126 to printf_uint [phi:main::@126->printf_uint]
    // [996] phi printf_uint::format_zero_padding#15 = 0 [phi:main::@126->printf_uint#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uint.format_zero_padding
    // [996] phi printf_uint::format_min_length#15 = 0 [phi:main::@126->printf_uint#1] -- vbuz1=vbuc1 
    sta.z printf_uint.format_min_length
    // [996] phi printf_uint::format_radix#15 = DECIMAL [phi:main::@126->printf_uint#2] -- vbuxx=vbuc1 
    ldx #DECIMAL
    // [996] phi printf_uint::uvalue#15 = printf_uint::uvalue#14 [phi:main::@126->printf_uint#3] -- register_copy 
    jsr printf_uint
    // [198] phi from main::@126 to main::@127 [phi:main::@126->main::@127]
    // main::@127
    // sprintf(info_text, "BL:v%u, SMC:%s", smc_bootloader, file_smc_version_text)
    // [199] call printf_str
    // [987] phi from main::@127 to printf_str [phi:main::@127->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:main::@127->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = main::s6 [phi:main::@127->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // [200] phi from main::@127 to main::@128 [phi:main::@127->main::@128]
    // main::@128
    // sprintf(info_text, "BL:v%u, SMC:%s", smc_bootloader, file_smc_version_text)
    // [201] call printf_string
    // [1130] phi from main::@128 to printf_string [phi:main::@128->printf_string]
    // [1130] phi printf_string::putc#22 = &snputc [phi:main::@128->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1130] phi printf_string::str#22 = main::file_smc_version_text [phi:main::@128->printf_string#1] -- pbuz1=pbuc1 
    lda #<file_smc_version_text
    sta.z printf_string.str
    lda #>file_smc_version_text
    sta.z printf_string.str+1
    // [1130] phi printf_string::format_justify_left#22 = 0 [phi:main::@128->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1130] phi printf_string::format_min_length#22 = 0 [phi:main::@128->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@129
    // sprintf(info_text, "BL:v%u, SMC:%s", smc_bootloader, file_smc_version_text)
    // [202] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [203] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_smc(STATUS_FLASH, NULL)
    // [205] call display_info_smc
  // All ok, display bootloader version.
    // [870] phi from main::@129 to display_info_smc [phi:main::@129->display_info_smc]
    // [870] phi display_info_smc::info_text#14 = 0 [phi:main::@129->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [870] phi display_info_smc::info_status#14 = STATUS_FLASH [phi:main::@129->display_info_smc#1] -- vbuz1=vbuc1 
    lda #STATUS_FLASH
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [206] phi from main::@129 main::@24 main::@25 to main::CLI2 [phi:main::@129/main::@24/main::@25->main::CLI2]
    // [206] phi __errno#247 = __errno#18 [phi:main::@129/main::@24/main::@25->main::CLI2#0] -- register_copy 
    jmp CLI2
    // [206] phi from main::@62 to main::CLI2 [phi:main::@62->main::CLI2]
  __b6:
    // [206] phi __errno#247 = 0 [phi:main::@62->main::CLI2#0] -- vwsz1=vwsc1 
    lda #<0
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
    // [209] phi from main::SEI4 to main::@26 [phi:main::SEI4->main::@26]
    // [209] phi __errno#112 = __errno#247 [phi:main::SEI4->main::@26#0] -- register_copy 
    // [209] phi main::rom_chip2#10 = 0 [phi:main::SEI4->main::@26#1] -- vbum1=vbuc1 
    lda #0
    sta rom_chip2
  // We loop all the possible ROM chip slots on the board and on the extension card,
  // and we check the file contents.
  // Any error identified gets reported and this chip will not be flashed.
  // In case of ROM0.BIN in error, no flashing will be done!
    // main::@26
  __b26:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [210] if(main::rom_chip2#10<8) goto main::bank_set_brom4 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip2
    cmp #8
    bcs !bank_set_brom4+
    jmp bank_set_brom4
  !bank_set_brom4:
    // main::bank_set_brom5
    // BROM = bank
    // [211] BROM = main::bank_set_brom5_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom5_bank
    sta.z BROM
    // main::CLI3
    // asm
    // asm { cli  }
    cli
    // main::check_status_smc2
    // status_smc == status
    // [213] main::check_status_smc2_$0 = status_smc#0 == STATUS_FLASH -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [214] main::check_status_smc2_return#0 = (char)main::check_status_smc2_$0 -- vbuyy=vbuaa 
    tay
    // [215] phi from main::check_status_smc2 to main::check_status_cx16_rom1 [phi:main::check_status_smc2->main::check_status_cx16_rom1]
    // main::check_status_cx16_rom1
    // main::check_status_cx16_rom1_check_status_rom1
    // status_rom[rom_chip] == status
    // [216] main::check_status_cx16_rom1_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboaa=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [217] main::check_status_cx16_rom1_check_status_rom1_return#0 = (char)main::check_status_cx16_rom1_check_status_rom1_$0 -- vbuxx=vbuaa 
    tax
    // main::@64
    // if(!check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH))
    // [218] if(0!=main::check_status_smc2_return#0) goto main::check_status_smc3 -- 0_neq_vbuyy_then_la1 
    cpy #0
    bne check_status_smc3
    // main::@205
    // [219] if(0!=main::check_status_cx16_rom1_check_status_rom1_return#0) goto main::@33 -- 0_neq_vbuxx_then_la1 
    cpx #0
    beq !__b33+
    jmp __b33
  !__b33:
    // main::check_status_smc3
  check_status_smc3:
    // status_smc == status
    // [220] main::check_status_smc3_$0 = status_smc#0 == STATUS_FLASH -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [221] main::check_status_smc3_return#0 = (char)main::check_status_smc3_$0 -- vbuyy=vbuaa 
    tay
    // [222] phi from main::check_status_smc3 to main::check_status_cx16_rom2 [phi:main::check_status_smc3->main::check_status_cx16_rom2]
    // main::check_status_cx16_rom2
    // main::check_status_cx16_rom2_check_status_rom1
    // status_rom[rom_chip] == status
    // [223] main::check_status_cx16_rom2_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboaa=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [224] main::check_status_cx16_rom2_check_status_rom1_return#0 = (char)main::check_status_cx16_rom2_check_status_rom1_$0 -- vbuxx=vbuaa 
    tax
    // main::@67
    // if(check_status_smc(STATUS_FLASH) && !check_status_cx16_rom(STATUS_FLASH))
    // [225] if(0==main::check_status_smc3_return#0) goto main::check_status_smc4 -- 0_eq_vbuyy_then_la1 
    cpy #0
    beq check_status_smc4
    // main::@206
    // [226] if(0==main::check_status_cx16_rom2_check_status_rom1_return#0) goto main::@3 -- 0_eq_vbuxx_then_la1 
    cpx #0
    bne !__b3+
    jmp __b3
  !__b3:
    // main::check_status_smc4
  check_status_smc4:
    // status_smc == status
    // [227] main::check_status_smc4_$0 = status_smc#0 == STATUS_ISSUE -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [228] main::check_status_smc4_return#0 = (char)main::check_status_smc4_$0 -- vbuz1=vbuaa 
    sta.z check_status_smc4_return
    // main::check_status_vera1
    // status_vera == status
    // [229] main::check_status_vera1_$0 = status_vera#0 == STATUS_ISSUE -- vboaa=vbum1_eq_vbuc1 
    lda status_vera
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_vera == status);
    // [230] main::check_status_vera1_return#0 = (char)main::check_status_vera1_$0 -- vbuz1=vbuaa 
    sta.z check_status_vera1_return
    // [231] phi from main::check_status_vera1 to main::check_status_roms_all1 [phi:main::check_status_vera1->main::check_status_roms_all1]
    // main::check_status_roms_all1
    // [232] phi from main::check_status_roms_all1 to main::check_status_roms_all1_@1 [phi:main::check_status_roms_all1->main::check_status_roms_all1_@1]
    // [232] phi main::check_status_roms_all1_rom_chip#2 = 0 [phi:main::check_status_roms_all1->main::check_status_roms_all1_@1#0] -- vbuxx=vbuc1 
    ldx #0
    // main::check_status_roms_all1_@1
  check_status_roms_all1___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [233] if(main::check_status_roms_all1_rom_chip#2<8) goto main::check_status_roms_all1_check_status_rom1 -- vbuxx_lt_vbuc1_then_la1 
    cpx #8
    bcs !check_status_roms_all1_check_status_rom1+
    jmp check_status_roms_all1_check_status_rom1
  !check_status_roms_all1_check_status_rom1:
    // [234] phi from main::check_status_roms_all1_@1 to main::check_status_roms_all1_@return [phi:main::check_status_roms_all1_@1->main::check_status_roms_all1_@return]
    // [234] phi main::check_status_roms_all1_return#2 = 1 [phi:main::check_status_roms_all1_@1->main::check_status_roms_all1_@return#0] -- vbum1=vbuc1 
    lda #1
    sta check_status_roms_all1_return
    // main::check_status_roms_all1_@return
    // main::check_status_smc5
  check_status_smc5:
    // status_smc == status
    // [235] main::check_status_smc5_$0 = status_smc#0 == STATUS_ERROR -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [236] main::check_status_smc5_return#0 = (char)main::check_status_smc5_$0 -- vbuz1=vbuaa 
    sta.z check_status_smc5_return
    // main::check_status_vera2
    // status_vera == status
    // [237] main::check_status_vera2_$0 = status_vera#0 == STATUS_ERROR -- vboaa=vbum1_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_vera == status);
    // [238] main::check_status_vera2_return#0 = (char)main::check_status_vera2_$0 -- vbuyy=vbuaa 
    tay
    // [239] phi from main::check_status_vera2 to main::check_status_roms_all2 [phi:main::check_status_vera2->main::check_status_roms_all2]
    // main::check_status_roms_all2
    // [240] phi from main::check_status_roms_all2 to main::check_status_roms_all2_@1 [phi:main::check_status_roms_all2->main::check_status_roms_all2_@1]
    // [240] phi main::check_status_roms_all2_rom_chip#2 = 0 [phi:main::check_status_roms_all2->main::check_status_roms_all2_@1#0] -- vbuxx=vbuc1 
    ldx #0
    // main::check_status_roms_all2_@1
  check_status_roms_all2___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [241] if(main::check_status_roms_all2_rom_chip#2<8) goto main::check_status_roms_all2_check_status_rom1 -- vbuxx_lt_vbuc1_then_la1 
    cpx #8
    bcs !check_status_roms_all2_check_status_rom1+
    jmp check_status_roms_all2_check_status_rom1
  !check_status_roms_all2_check_status_rom1:
    // [242] phi from main::check_status_roms_all2_@1 to main::check_status_roms_all2_@return [phi:main::check_status_roms_all2_@1->main::check_status_roms_all2_@return]
    // [242] phi main::check_status_roms_all2_return#2 = 1 [phi:main::check_status_roms_all2_@1->main::check_status_roms_all2_@return#0] -- vbuxx=vbuc1 
    ldx #1
    // main::check_status_roms_all2_@return
    // main::@68
  __b68:
    // if(!check_status_smc(STATUS_ISSUE) && !check_status_vera(STATUS_ISSUE) && !check_status_roms_all(STATUS_ISSUE) &&
    //        !check_status_smc(STATUS_ERROR) && !check_status_vera(STATUS_ERROR) && !check_status_roms_all(STATUS_ERROR))
    // [243] if(0!=main::check_status_smc4_return#0) goto main::check_status_smc6 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc4_return
    bne check_status_smc6
    // main::@211
    // [244] if(0==main::check_status_vera1_return#0) goto main::@210 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_vera1_return
    bne !__b210+
    jmp __b210
  !__b210:
    // main::check_status_smc6
  check_status_smc6:
    // status_smc == status
    // [245] main::check_status_smc6_$0 = status_smc#0 == STATUS_SKIP -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [246] main::check_status_smc6_return#0 = (char)main::check_status_smc6_$0 -- vbuz1=vbuaa 
    sta.z check_status_smc6_return
    // main::check_status_vera3
    // status_vera == status
    // [247] main::check_status_vera3_$0 = status_vera#0 == STATUS_SKIP -- vboaa=vbum1_eq_vbuc1 
    lda status_vera
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_vera == status);
    // [248] main::check_status_vera3_return#0 = (char)main::check_status_vera3_$0 -- vbuyy=vbuaa 
    tay
    // [249] phi from main::check_status_vera3 to main::check_status_roms_all3 [phi:main::check_status_vera3->main::check_status_roms_all3]
    // main::check_status_roms_all3
    // [250] phi from main::check_status_roms_all3 to main::check_status_roms_all3_@1 [phi:main::check_status_roms_all3->main::check_status_roms_all3_@1]
    // [250] phi main::check_status_roms_all3_rom_chip#2 = 0 [phi:main::check_status_roms_all3->main::check_status_roms_all3_@1#0] -- vbuxx=vbuc1 
    ldx #0
    // main::check_status_roms_all3_@1
  check_status_roms_all3___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [251] if(main::check_status_roms_all3_rom_chip#2<8) goto main::check_status_roms_all3_check_status_rom1 -- vbuxx_lt_vbuc1_then_la1 
    cpx #8
    bcs !check_status_roms_all3_check_status_rom1+
    jmp check_status_roms_all3_check_status_rom1
  !check_status_roms_all3_check_status_rom1:
    // [252] phi from main::check_status_roms_all3_@1 to main::check_status_roms_all3_@return [phi:main::check_status_roms_all3_@1->main::check_status_roms_all3_@return]
    // [252] phi main::check_status_roms_all3_return#2 = 1 [phi:main::check_status_roms_all3_@1->main::check_status_roms_all3_@return#0] -- vbuxx=vbuc1 
    ldx #1
    // main::check_status_roms_all3_@return
    // main::@69
  __b69:
    // if(check_status_smc(STATUS_SKIP) && check_status_vera(STATUS_SKIP) && check_status_roms_all(STATUS_SKIP))
    // [253] if(0==main::check_status_smc6_return#0) goto main::check_status_smc10 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_smc6_return
    beq check_status_smc10
    // main::@213
    // [254] if(0==main::check_status_vera3_return#0) goto main::check_status_smc10 -- 0_eq_vbuyy_then_la1 
    cpy #0
    beq check_status_smc10
    // main::@212
    // [255] if(0!=main::check_status_roms_all3_return#2) goto main::vera_display_set_border_color1 -- 0_neq_vbuxx_then_la1 
    cpx #0
    beq !vera_display_set_border_color1+
    jmp vera_display_set_border_color1
  !vera_display_set_border_color1:
    // main::check_status_smc10
  check_status_smc10:
    // status_smc == status
    // [256] main::check_status_smc10_$0 = status_smc#0 == STATUS_ERROR -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [257] main::check_status_smc10_return#0 = (char)main::check_status_smc10_$0 -- vbum1=vbuaa 
    sta check_status_smc10_return
    // main::check_status_vera4
    // status_vera == status
    // [258] main::check_status_vera4_$0 = status_vera#0 == STATUS_ERROR -- vboaa=vbum1_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_vera == status);
    // [259] main::check_status_vera4_return#0 = (char)main::check_status_vera4_$0 -- vbuyy=vbuaa 
    tay
    // [260] phi from main::check_status_vera4 to main::check_status_roms1 [phi:main::check_status_vera4->main::check_status_roms1]
    // main::check_status_roms1
    // [261] phi from main::check_status_roms1 to main::check_status_roms1_@1 [phi:main::check_status_roms1->main::check_status_roms1_@1]
    // [261] phi main::check_status_roms1_rom_chip#2 = 0 [phi:main::check_status_roms1->main::check_status_roms1_@1#0] -- vbuxx=vbuc1 
    ldx #0
    // main::check_status_roms1_@1
  check_status_roms1___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [262] if(main::check_status_roms1_rom_chip#2<8) goto main::check_status_roms1_check_status_rom1 -- vbuxx_lt_vbuc1_then_la1 
    cpx #8
    bcs !check_status_roms1_check_status_rom1+
    jmp check_status_roms1_check_status_rom1
  !check_status_roms1_check_status_rom1:
    // [263] phi from main::check_status_roms1_@1 to main::check_status_roms1_@return [phi:main::check_status_roms1_@1->main::check_status_roms1_@return]
    // [263] phi main::check_status_roms1_return#2 = STATUS_NONE [phi:main::check_status_roms1_@1->main::check_status_roms1_@return#0] -- vbuxx=vbuc1 
    ldx #STATUS_NONE
    // main::check_status_roms1_@return
    // main::@76
  __b76:
    // if(check_status_smc(STATUS_ERROR) || check_status_vera(STATUS_ERROR) || check_status_roms(STATUS_ERROR))
    // [264] if(0!=main::check_status_smc10_return#0) goto main::vera_display_set_border_color2 -- 0_neq_vbum1_then_la1 
    lda check_status_smc10_return
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::@220
    // [265] if(0!=main::check_status_vera4_return#0) goto main::vera_display_set_border_color2 -- 0_neq_vbuyy_then_la1 
    cpy #0
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::@219
    // [266] if(0!=main::check_status_roms1_return#2) goto main::vera_display_set_border_color2 -- 0_neq_vbuxx_then_la1 
    cpx #0
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::check_status_smc11
    // status_smc == status
    // [267] main::check_status_smc11_$0 = status_smc#0 == STATUS_ISSUE -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [268] main::check_status_smc11_return#0 = (char)main::check_status_smc11_$0 -- vbum1=vbuaa 
    sta check_status_smc11_return
    // main::check_status_vera5
    // status_vera == status
    // [269] main::check_status_vera5_$0 = status_vera#0 == STATUS_ISSUE -- vboaa=vbum1_eq_vbuc1 
    lda status_vera
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_vera == status);
    // [270] main::check_status_vera5_return#0 = (char)main::check_status_vera5_$0 -- vbuyy=vbuaa 
    tay
    // [271] phi from main::check_status_vera5 to main::check_status_roms2 [phi:main::check_status_vera5->main::check_status_roms2]
    // main::check_status_roms2
    // [272] phi from main::check_status_roms2 to main::check_status_roms2_@1 [phi:main::check_status_roms2->main::check_status_roms2_@1]
    // [272] phi main::check_status_roms2_rom_chip#2 = 0 [phi:main::check_status_roms2->main::check_status_roms2_@1#0] -- vbuxx=vbuc1 
    ldx #0
    // main::check_status_roms2_@1
  check_status_roms2___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [273] if(main::check_status_roms2_rom_chip#2<8) goto main::check_status_roms2_check_status_rom1 -- vbuxx_lt_vbuc1_then_la1 
    cpx #8
    bcs !check_status_roms2_check_status_rom1+
    jmp check_status_roms2_check_status_rom1
  !check_status_roms2_check_status_rom1:
    // [274] phi from main::check_status_roms2_@1 to main::check_status_roms2_@return [phi:main::check_status_roms2_@1->main::check_status_roms2_@return]
    // [274] phi main::check_status_roms2_return#2 = STATUS_NONE [phi:main::check_status_roms2_@1->main::check_status_roms2_@return#0] -- vbuxx=vbuc1 
    ldx #STATUS_NONE
    // main::check_status_roms2_@return
    // main::@78
  __b78:
    // if(check_status_smc(STATUS_ISSUE) || check_status_vera(STATUS_ISSUE) || check_status_roms(STATUS_ISSUE))
    // [275] if(0!=main::check_status_smc11_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbum1_then_la1 
    lda check_status_smc11_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::@222
    // [276] if(0!=main::check_status_vera5_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbuyy_then_la1 
    cpy #0
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::@221
    // [277] if(0!=main::check_status_roms2_return#2) goto main::vera_display_set_border_color3 -- 0_neq_vbuxx_then_la1 
    cpx #0
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::vera_display_set_border_color4
    // *VERA_CTRL &= ~VERA_DCSEL
    // [278] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [279] *VERA_DC_BORDER = GREEN -- _deref_pbuc1=vbuc2 
    lda #GREEN
    sta VERA_DC_BORDER
    // [280] phi from main::vera_display_set_border_color4 to main::@80 [phi:main::vera_display_set_border_color4->main::@80]
    // main::@80
    // display_action_progress("Your CX16 update is a success!")
    // [281] call display_action_progress
    // [812] phi from main::@80 to display_action_progress [phi:main::@80->display_action_progress]
    // [812] phi display_action_progress::info_text#15 = main::info_text30 [phi:main::@80->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text30
    sta.z display_action_progress.info_text
    lda #>info_text30
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::check_status_smc12
    // status_smc == status
    // [282] main::check_status_smc12_$0 = status_smc#0 == STATUS_FLASHED -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASHED
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [283] main::check_status_smc12_return#0 = (char)main::check_status_smc12_$0
    // main::@81
    // if(check_status_smc(STATUS_FLASHED))
    // [284] if(0!=main::check_status_smc12_return#0) goto main::@50 -- 0_neq_vbuaa_then_la1 
    cmp #0
    bne __b50
    // [285] phi from main::@81 to main::@6 [phi:main::@81->main::@6]
    // main::@6
    // display_progress_text(display_debriefing_text_rom, display_debriefing_count_rom)
    // [286] call display_progress_text
    // [926] phi from main::@6 to display_progress_text [phi:main::@6->display_progress_text]
    // [926] phi display_progress_text::text#10 = display_debriefing_text_rom [phi:main::@6->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_debriefing_text_rom
    sta.z display_progress_text.text
    lda #>display_debriefing_text_rom
    sta.z display_progress_text.text+1
    // [926] phi display_progress_text::lines#11 = display_debriefing_count_rom [phi:main::@6->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_debriefing_count_rom
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [287] phi from main::@198 main::@6 main::@75 main::@79 to main::@55 [phi:main::@198/main::@6/main::@75/main::@79->main::@55]
  __b11:
    // [287] phi main::w1#2 = $c8 [phi:main::@198/main::@6/main::@75/main::@79->main::@55#0] -- vbum1=vbuc1 
    lda #$c8
    sta w1
    // main::@55
  __b55:
    // for (unsigned char w=200; w>0; w--)
    // [288] if(main::w1#2>0) goto main::@56 -- vbum1_gt_0_then_la1 
    lda w1
    bne __b56
    // [289] phi from main::@55 to main::@57 [phi:main::@55->main::@57]
    // main::@57
    // system_reset()
    // [290] call system_reset
    // [1155] phi from main::@57 to system_reset [phi:main::@57->system_reset]
    jsr system_reset
    // main::@return
    // }
    // [291] return 
    rts
    // [292] phi from main::@55 to main::@56 [phi:main::@55->main::@56]
    // main::@56
  __b56:
    // wait_moment()
    // [293] call wait_moment
    // [1160] phi from main::@56 to wait_moment [phi:main::@56->wait_moment]
    jsr wait_moment
    // [294] phi from main::@56 to main::@199 [phi:main::@56->main::@199]
    // main::@199
    // sprintf(info_text, "(%u) Your CX16 will reset ...", w)
    // [295] call snprintf_init
    // [982] phi from main::@199 to snprintf_init [phi:main::@199->snprintf_init]
    // [982] phi snprintf_init::s#27 = info_text [phi:main::@199->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [296] phi from main::@199 to main::@200 [phi:main::@199->main::@200]
    // main::@200
    // sprintf(info_text, "(%u) Your CX16 will reset ...", w)
    // [297] call printf_str
    // [987] phi from main::@200 to printf_str [phi:main::@200->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:main::@200->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = main::s17 [phi:main::@200->printf_str#1] -- pbuz1=pbuc1 
    lda #<s17
    sta.z printf_str.s
    lda #>s17
    sta.z printf_str.s+1
    jsr printf_str
    // main::@201
    // sprintf(info_text, "(%u) Your CX16 will reset ...", w)
    // [298] printf_uchar::uvalue#13 = main::w1#2 -- vbuxx=vbum1 
    ldx w1
    // [299] call printf_uchar
    // [1165] phi from main::@201 to printf_uchar [phi:main::@201->printf_uchar]
    // [1165] phi printf_uchar::format_zero_padding#14 = 0 [phi:main::@201->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1165] phi printf_uchar::format_min_length#14 = 0 [phi:main::@201->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1165] phi printf_uchar::putc#14 = &snputc [phi:main::@201->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1165] phi printf_uchar::format_radix#14 = DECIMAL [phi:main::@201->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [1165] phi printf_uchar::uvalue#14 = printf_uchar::uvalue#13 [phi:main::@201->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [300] phi from main::@201 to main::@202 [phi:main::@201->main::@202]
    // main::@202
    // sprintf(info_text, "(%u) Your CX16 will reset ...", w)
    // [301] call printf_str
    // [987] phi from main::@202 to printf_str [phi:main::@202->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:main::@202->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = main::s21 [phi:main::@202->printf_str#1] -- pbuz1=pbuc1 
    lda #<s21
    sta.z printf_str.s
    lda #>s21
    sta.z printf_str.s+1
    jsr printf_str
    // main::@203
    // sprintf(info_text, "(%u) Your CX16 will reset ...", w)
    // [302] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [303] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [305] call display_action_text
    // [1176] phi from main::@203 to display_action_text [phi:main::@203->display_action_text]
    // [1176] phi display_action_text::info_text#19 = info_text [phi:main::@203->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@204
    // for (unsigned char w=200; w>0; w--)
    // [306] main::w1#1 = -- main::w1#2 -- vbum1=_dec_vbum1 
    dec w1
    // [287] phi from main::@204 to main::@55 [phi:main::@204->main::@55]
    // [287] phi main::w1#2 = main::w1#1 [phi:main::@204->main::@55#0] -- register_copy 
    jmp __b55
    // [307] phi from main::@81 to main::@50 [phi:main::@81->main::@50]
    // main::@50
  __b50:
    // display_progress_text(display_debriefing_text_smc, display_debriefing_count_smc)
    // [308] call display_progress_text
    // [926] phi from main::@50 to display_progress_text [phi:main::@50->display_progress_text]
    // [926] phi display_progress_text::text#10 = display_debriefing_text_smc [phi:main::@50->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_debriefing_text_smc
    sta.z display_progress_text.text
    lda #>display_debriefing_text_smc
    sta.z display_progress_text.text+1
    // [926] phi display_progress_text::lines#11 = display_debriefing_count_smc [phi:main::@50->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_debriefing_count_smc
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [309] phi from main::@50 to main::@51 [phi:main::@50->main::@51]
    // [309] phi main::w#2 = $f0 [phi:main::@50->main::@51#0] -- vbum1=vbuc1 
    lda #$f0
    sta w
    // main::@51
  __b51:
    // for (unsigned char w=240; w>0; w--)
    // [310] if(main::w#2>0) goto main::@52 -- vbum1_gt_0_then_la1 
    lda w
    bne __b52
    // [311] phi from main::@51 to main::@53 [phi:main::@51->main::@53]
    // main::@53
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [312] call snprintf_init
    // [982] phi from main::@53 to snprintf_init [phi:main::@53->snprintf_init]
    // [982] phi snprintf_init::s#27 = info_text [phi:main::@53->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [313] phi from main::@53 to main::@196 [phi:main::@53->main::@196]
    // main::@196
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [314] call printf_str
    // [987] phi from main::@196 to printf_str [phi:main::@196->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:main::@196->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = main::s19 [phi:main::@196->printf_str#1] -- pbuz1=pbuc1 
    lda #<s19
    sta.z printf_str.s
    lda #>s19
    sta.z printf_str.s+1
    jsr printf_str
    // main::@197
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [315] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [316] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [318] call display_action_text
    // [1176] phi from main::@197 to display_action_text [phi:main::@197->display_action_text]
    // [1176] phi display_action_text::info_text#19 = info_text [phi:main::@197->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [319] phi from main::@197 to main::@198 [phi:main::@197->main::@198]
    // main::@198
    // smc_reset()
    // [320] call smc_reset
    // [1190] phi from main::@198 to smc_reset [phi:main::@198->smc_reset]
    jsr smc_reset
    jmp __b11
    // [321] phi from main::@51 to main::@52 [phi:main::@51->main::@52]
    // main::@52
  __b52:
    // wait_moment()
    // [322] call wait_moment
    // [1160] phi from main::@52 to wait_moment [phi:main::@52->wait_moment]
    jsr wait_moment
    // [323] phi from main::@52 to main::@190 [phi:main::@52->main::@190]
    // main::@190
    // sprintf(info_text, "(%u) Please read carefully the below ...", w)
    // [324] call snprintf_init
    // [982] phi from main::@190 to snprintf_init [phi:main::@190->snprintf_init]
    // [982] phi snprintf_init::s#27 = info_text [phi:main::@190->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [325] phi from main::@190 to main::@191 [phi:main::@190->main::@191]
    // main::@191
    // sprintf(info_text, "(%u) Please read carefully the below ...", w)
    // [326] call printf_str
    // [987] phi from main::@191 to printf_str [phi:main::@191->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:main::@191->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = main::s17 [phi:main::@191->printf_str#1] -- pbuz1=pbuc1 
    lda #<s17
    sta.z printf_str.s
    lda #>s17
    sta.z printf_str.s+1
    jsr printf_str
    // main::@192
    // sprintf(info_text, "(%u) Please read carefully the below ...", w)
    // [327] printf_uchar::uvalue#12 = main::w#2 -- vbuxx=vbum1 
    ldx w
    // [328] call printf_uchar
    // [1165] phi from main::@192 to printf_uchar [phi:main::@192->printf_uchar]
    // [1165] phi printf_uchar::format_zero_padding#14 = 0 [phi:main::@192->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1165] phi printf_uchar::format_min_length#14 = 0 [phi:main::@192->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1165] phi printf_uchar::putc#14 = &snputc [phi:main::@192->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1165] phi printf_uchar::format_radix#14 = DECIMAL [phi:main::@192->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [1165] phi printf_uchar::uvalue#14 = printf_uchar::uvalue#12 [phi:main::@192->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [329] phi from main::@192 to main::@193 [phi:main::@192->main::@193]
    // main::@193
    // sprintf(info_text, "(%u) Please read carefully the below ...", w)
    // [330] call printf_str
    // [987] phi from main::@193 to printf_str [phi:main::@193->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:main::@193->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = main::s18 [phi:main::@193->printf_str#1] -- pbuz1=pbuc1 
    lda #<s18
    sta.z printf_str.s
    lda #>s18
    sta.z printf_str.s+1
    jsr printf_str
    // main::@194
    // sprintf(info_text, "(%u) Please read carefully the below ...", w)
    // [331] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [332] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [334] call display_action_text
    // [1176] phi from main::@194 to display_action_text [phi:main::@194->display_action_text]
    // [1176] phi display_action_text::info_text#19 = info_text [phi:main::@194->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@195
    // for (unsigned char w=240; w>0; w--)
    // [335] main::w#1 = -- main::w#2 -- vbum1=_dec_vbum1 
    dec w
    // [309] phi from main::@195 to main::@51 [phi:main::@195->main::@51]
    // [309] phi main::w#2 = main::w#1 [phi:main::@195->main::@51#0] -- register_copy 
    jmp __b51
    // main::vera_display_set_border_color3
  vera_display_set_border_color3:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [336] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [337] *VERA_DC_BORDER = YELLOW -- _deref_pbuc1=vbuc2 
    lda #YELLOW
    sta VERA_DC_BORDER
    // [338] phi from main::vera_display_set_border_color3 to main::@79 [phi:main::vera_display_set_border_color3->main::@79]
    // main::@79
    // display_action_progress("Update issues, your CX16 is not updated!")
    // [339] call display_action_progress
    // [812] phi from main::@79 to display_action_progress [phi:main::@79->display_action_progress]
    // [812] phi display_action_progress::info_text#15 = main::info_text29 [phi:main::@79->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text29
    sta.z display_action_progress.info_text
    lda #>info_text29
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    jmp __b11
    // main::check_status_roms2_check_status_rom1
  check_status_roms2_check_status_rom1:
    // status_rom[rom_chip] == status
    // [340] main::check_status_roms2_check_status_rom1_$0 = status_rom[main::check_status_roms2_rom_chip#2] == STATUS_ISSUE -- vboaa=pbuc1_derefidx_vbuxx_eq_vbuc2 
    lda #STATUS_ISSUE
    eor status_rom,x
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [341] main::check_status_roms2_check_status_rom1_return#0 = (char)main::check_status_roms2_check_status_rom1_$0
    // main::check_status_roms2_@11
    // if(check_status_rom(rom_chip, status))
    // [342] if(0==main::check_status_roms2_check_status_rom1_return#0) goto main::check_status_roms2_@4 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq check_status_roms2___b4
    // [274] phi from main::check_status_roms2_@11 to main::check_status_roms2_@return [phi:main::check_status_roms2_@11->main::check_status_roms2_@return]
    // [274] phi main::check_status_roms2_return#2 = STATUS_ISSUE [phi:main::check_status_roms2_@11->main::check_status_roms2_@return#0] -- vbuxx=vbuc1 
    ldx #STATUS_ISSUE
    jmp __b78
    // main::check_status_roms2_@4
  check_status_roms2___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [343] main::check_status_roms2_rom_chip#1 = ++ main::check_status_roms2_rom_chip#2 -- vbuxx=_inc_vbuxx 
    inx
    // [272] phi from main::check_status_roms2_@4 to main::check_status_roms2_@1 [phi:main::check_status_roms2_@4->main::check_status_roms2_@1]
    // [272] phi main::check_status_roms2_rom_chip#2 = main::check_status_roms2_rom_chip#1 [phi:main::check_status_roms2_@4->main::check_status_roms2_@1#0] -- register_copy 
    jmp check_status_roms2___b1
    // main::vera_display_set_border_color2
  vera_display_set_border_color2:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [344] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [345] *VERA_DC_BORDER = RED -- _deref_pbuc1=vbuc2 
    lda #RED
    sta VERA_DC_BORDER
    // [346] phi from main::vera_display_set_border_color2 to main::@77 [phi:main::vera_display_set_border_color2->main::@77]
    // main::@77
    // display_action_progress("Update Failure! Your CX16 may be bricked!")
    // [347] call display_action_progress
    // [812] phi from main::@77 to display_action_progress [phi:main::@77->display_action_progress]
    // [812] phi display_action_progress::info_text#15 = main::info_text27 [phi:main::@77->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text27
    sta.z display_action_progress.info_text
    lda #>info_text27
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [348] phi from main::@77 to main::@189 [phi:main::@77->main::@189]
    // main::@189
    // display_action_text("Take a foto of this screen. And shut down power ...")
    // [349] call display_action_text
    // [1176] phi from main::@189 to display_action_text [phi:main::@189->display_action_text]
    // [1176] phi display_action_text::info_text#19 = main::info_text28 [phi:main::@189->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text28
    sta.z display_action_text.info_text
    lda #>info_text28
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [350] phi from main::@189 main::@54 to main::@54 [phi:main::@189/main::@54->main::@54]
    // main::@54
  __b54:
    jmp __b54
    // main::check_status_roms1_check_status_rom1
  check_status_roms1_check_status_rom1:
    // status_rom[rom_chip] == status
    // [351] main::check_status_roms1_check_status_rom1_$0 = status_rom[main::check_status_roms1_rom_chip#2] == STATUS_ERROR -- vboaa=pbuc1_derefidx_vbuxx_eq_vbuc2 
    lda #STATUS_ERROR
    eor status_rom,x
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [352] main::check_status_roms1_check_status_rom1_return#0 = (char)main::check_status_roms1_check_status_rom1_$0
    // main::check_status_roms1_@11
    // if(check_status_rom(rom_chip, status))
    // [353] if(0==main::check_status_roms1_check_status_rom1_return#0) goto main::check_status_roms1_@4 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq check_status_roms1___b4
    // [263] phi from main::check_status_roms1_@11 to main::check_status_roms1_@return [phi:main::check_status_roms1_@11->main::check_status_roms1_@return]
    // [263] phi main::check_status_roms1_return#2 = STATUS_ERROR [phi:main::check_status_roms1_@11->main::check_status_roms1_@return#0] -- vbuxx=vbuc1 
    ldx #STATUS_ERROR
    jmp __b76
    // main::check_status_roms1_@4
  check_status_roms1___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [354] main::check_status_roms1_rom_chip#1 = ++ main::check_status_roms1_rom_chip#2 -- vbuxx=_inc_vbuxx 
    inx
    // [261] phi from main::check_status_roms1_@4 to main::check_status_roms1_@1 [phi:main::check_status_roms1_@4->main::check_status_roms1_@1]
    // [261] phi main::check_status_roms1_rom_chip#2 = main::check_status_roms1_rom_chip#1 [phi:main::check_status_roms1_@4->main::check_status_roms1_@1#0] -- register_copy 
    jmp check_status_roms1___b1
    // main::vera_display_set_border_color1
  vera_display_set_border_color1:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [355] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [356] *VERA_DC_BORDER = BLACK -- _deref_pbuc1=vbuc2 
    lda #BLACK
    sta VERA_DC_BORDER
    // [357] phi from main::vera_display_set_border_color1 to main::@75 [phi:main::vera_display_set_border_color1->main::@75]
    // main::@75
    // display_action_progress("The update has been cancelled!")
    // [358] call display_action_progress
    // [812] phi from main::@75 to display_action_progress [phi:main::@75->display_action_progress]
    // [812] phi display_action_progress::info_text#15 = main::info_text26 [phi:main::@75->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text26
    sta.z display_action_progress.info_text
    lda #>info_text26
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    jmp __b11
    // main::check_status_roms_all3_check_status_rom1
  check_status_roms_all3_check_status_rom1:
    // status_rom[rom_chip] == status
    // [359] main::check_status_roms_all3_check_status_rom1_$0 = status_rom[main::check_status_roms_all3_rom_chip#2] == STATUS_SKIP -- vboaa=pbuc1_derefidx_vbuxx_eq_vbuc2 
    lda #STATUS_SKIP
    eor status_rom,x
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [360] main::check_status_roms_all3_check_status_rom1_return#0 = (char)main::check_status_roms_all3_check_status_rom1_$0
    // main::check_status_roms_all3_@11
    // if(check_status_rom(rom_chip, status) != status)
    // [361] if(main::check_status_roms_all3_check_status_rom1_return#0==STATUS_SKIP) goto main::check_status_roms_all3_@4 -- vbuaa_eq_vbuc1_then_la1 
    cmp #STATUS_SKIP
    beq check_status_roms_all3___b4
    // [252] phi from main::check_status_roms_all3_@11 to main::check_status_roms_all3_@return [phi:main::check_status_roms_all3_@11->main::check_status_roms_all3_@return]
    // [252] phi main::check_status_roms_all3_return#2 = 0 [phi:main::check_status_roms_all3_@11->main::check_status_roms_all3_@return#0] -- vbuxx=vbuc1 
    ldx #0
    jmp __b69
    // main::check_status_roms_all3_@4
  check_status_roms_all3___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [362] main::check_status_roms_all3_rom_chip#1 = ++ main::check_status_roms_all3_rom_chip#2 -- vbuxx=_inc_vbuxx 
    inx
    // [250] phi from main::check_status_roms_all3_@4 to main::check_status_roms_all3_@1 [phi:main::check_status_roms_all3_@4->main::check_status_roms_all3_@1]
    // [250] phi main::check_status_roms_all3_rom_chip#2 = main::check_status_roms_all3_rom_chip#1 [phi:main::check_status_roms_all3_@4->main::check_status_roms_all3_@1#0] -- register_copy 
    jmp check_status_roms_all3___b1
    // main::@210
  __b210:
    // if(!check_status_smc(STATUS_ISSUE) && !check_status_vera(STATUS_ISSUE) && !check_status_roms_all(STATUS_ISSUE) &&
    //        !check_status_smc(STATUS_ERROR) && !check_status_vera(STATUS_ERROR) && !check_status_roms_all(STATUS_ERROR))
    // [363] if(0!=main::check_status_roms_all1_return#2) goto main::check_status_smc6 -- 0_neq_vbum1_then_la1 
    lda check_status_roms_all1_return
    beq !check_status_smc6+
    jmp check_status_smc6
  !check_status_smc6:
    // main::@209
    // [364] if(0==main::check_status_smc5_return#0) goto main::@208 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_smc5_return
    beq __b208
    jmp check_status_smc6
    // main::@208
  __b208:
    // [365] if(0!=main::check_status_vera2_return#0) goto main::check_status_smc6 -- 0_neq_vbuyy_then_la1 
    cpy #0
    beq !check_status_smc6+
    jmp check_status_smc6
  !check_status_smc6:
    // main::@207
    // [366] if(0==main::check_status_roms_all2_return#2) goto main::check_status_smc7 -- 0_eq_vbuxx_then_la1 
    cpx #0
    beq check_status_smc7
    jmp check_status_smc6
    // main::check_status_smc7
  check_status_smc7:
    // status_smc == status
    // [367] main::check_status_smc7_$0 = status_smc#0 == STATUS_FLASH -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [368] main::check_status_smc7_return#0 = (char)main::check_status_smc7_$0 -- vbum1=vbuaa 
    sta check_status_smc7_return
    // [369] phi from main::check_status_smc7 to main::check_status_cx16_rom3 [phi:main::check_status_smc7->main::check_status_cx16_rom3]
    // main::check_status_cx16_rom3
    // main::check_status_cx16_rom3_check_status_rom1
    // status_rom[rom_chip] == status
    // [370] main::check_status_cx16_rom3_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboaa=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [371] main::check_status_cx16_rom3_check_status_rom1_return#0 = (char)main::check_status_cx16_rom3_check_status_rom1_$0 -- vbuyy=vbuaa 
    tay
    // [372] phi from main::check_status_cx16_rom3_check_status_rom1 to main::check_status_card_roms1 [phi:main::check_status_cx16_rom3_check_status_rom1->main::check_status_card_roms1]
    // main::check_status_card_roms1
    // [373] phi from main::check_status_card_roms1 to main::check_status_card_roms1_@1 [phi:main::check_status_card_roms1->main::check_status_card_roms1_@1]
    // [373] phi main::check_status_card_roms1_rom_chip#2 = 1 [phi:main::check_status_card_roms1->main::check_status_card_roms1_@1#0] -- vbuxx=vbuc1 
    ldx #1
    // main::check_status_card_roms1_@1
  check_status_card_roms1___b1:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [374] if(main::check_status_card_roms1_rom_chip#2<8) goto main::check_status_card_roms1_check_status_rom1 -- vbuxx_lt_vbuc1_then_la1 
    cpx #8
    bcs !check_status_card_roms1_check_status_rom1+
    jmp check_status_card_roms1_check_status_rom1
  !check_status_card_roms1_check_status_rom1:
    // [375] phi from main::check_status_card_roms1_@1 to main::check_status_card_roms1_@return [phi:main::check_status_card_roms1_@1->main::check_status_card_roms1_@return]
    // [375] phi main::check_status_card_roms1_return#2 = STATUS_NONE [phi:main::check_status_card_roms1_@1->main::check_status_card_roms1_@return#0] -- vbuxx=vbuc1 
    ldx #STATUS_NONE
    // main::check_status_card_roms1_@return
    // main::@70
  __b70:
    // if(check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH) || check_status_card_roms(STATUS_FLASH))
    // [376] if(0==main::check_status_smc7_return#0) goto main::@214 -- 0_eq_vbum1_then_la1 
    lda check_status_smc7_return
    beq __b214
    // main::@215
    // [377] if(0!=main::check_status_cx16_rom3_check_status_rom1_return#0) goto main::@4 -- 0_neq_vbuyy_then_la1 
    cpy #0
    beq !__b4+
    jmp __b4
  !__b4:
    // main::@214
  __b214:
    // [378] if(0!=main::check_status_card_roms1_return#2) goto main::@4 -- 0_neq_vbuxx_then_la1 
    cpx #0
    beq !__b4+
    jmp __b4
  !__b4:
    // main::bank_set_bram2
  bank_set_bram2:
    // BRAM = bank
    // [379] BRAM = main::bank_set_bram2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram2_bank
    sta.z BRAM
    // main::SEI5
    // asm
    // asm { sei  }
    sei
    // main::check_status_smc8
    // status_smc == status
    // [381] main::check_status_smc8_$0 = status_smc#0 == STATUS_FLASH -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [382] main::check_status_smc8_return#0 = (char)main::check_status_smc8_$0 -- vbuyy=vbuaa 
    tay
    // [383] phi from main::check_status_smc8 to main::check_status_cx16_rom4 [phi:main::check_status_smc8->main::check_status_cx16_rom4]
    // main::check_status_cx16_rom4
    // main::check_status_cx16_rom4_check_status_rom1
    // status_rom[rom_chip] == status
    // [384] main::check_status_cx16_rom4_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboaa=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [385] main::check_status_cx16_rom4_check_status_rom1_return#0 = (char)main::check_status_cx16_rom4_check_status_rom1_$0 -- vbuxx=vbuaa 
    tax
    // main::@71
    // if (check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH))
    // [386] if(0==main::check_status_smc8_return#0) goto main::@37 -- 0_eq_vbuyy_then_la1 
    cpy #0
    beq __b37
    // main::@216
    // [387] if(0!=main::check_status_cx16_rom4_check_status_rom1_return#0) goto main::@47 -- 0_neq_vbuxx_then_la1 
    cpx #0
    beq !__b47+
    jmp __b47
  !__b47:
    // [388] phi from main::@216 to main::@37 [phi:main::@216->main::@37]
    // [388] phi from main::@166 main::@38 main::@49 main::@71 to main::@37 [phi:main::@166/main::@38/main::@49/main::@71->main::@37]
    // [388] phi __errno#410 = __errno#18 [phi:main::@166/main::@38/main::@49/main::@71->main::@37#0] -- register_copy 
    // main::@37
  __b37:
    // [389] phi from main::@37 to main::@39 [phi:main::@37->main::@39]
    // [389] phi __errno#114 = __errno#410 [phi:main::@37->main::@39#0] -- register_copy 
    // [389] phi main::rom_chip4#10 = 7 [phi:main::@37->main::@39#1] -- vbum1=vbuc1 
    lda #7
    sta rom_chip4
  // Flash the ROM chips. 
  // We loop first all the ROM chips and read the file contents.
  // Then we verify the file contents and flash the ROM only for the differences.
  // If the file contents are the same as the ROM contents, then no flashing is required.
  // IMPORTANT! We start to flash the ROMs on the extension card.
  // The last ROM flashed is the CX16 ROM on the CX16 board!
    // main::@39
  __b39:
    // for(unsigned char rom_chip = 7; rom_chip != 255; rom_chip--)
    // [390] if(main::rom_chip4#10!=$ff) goto main::check_status_rom1 -- vbum1_neq_vbuc1_then_la1 
    lda #$ff
    cmp rom_chip4
    bne check_status_rom1
    jmp check_status_smc6
    // main::check_status_rom1
  check_status_rom1:
    // status_rom[rom_chip] == status
    // [391] main::check_status_rom1_$0 = status_rom[main::rom_chip4#10] == STATUS_FLASH -- vboaa=pbuc1_derefidx_vbum1_eq_vbuc2 
    lda #STATUS_FLASH
    ldy rom_chip4
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [392] main::check_status_rom1_return#0 = (char)main::check_status_rom1_$0
    // main::@72
    // if(check_status_rom(rom_chip, STATUS_FLASH))
    // [393] if(0==main::check_status_rom1_return#0) goto main::@40 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b40
    // main::check_status_smc9
    // status_smc == status
    // [394] main::check_status_smc9_$0 = status_smc#0 == STATUS_FLASHED -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASHED
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [395] main::check_status_smc9_return#0 = (char)main::check_status_smc9_$0 -- vbuxx=vbuaa 
    tax
    // main::@73
    // if((rom_chip == 0 && check_status_smc(STATUS_FLASHED)) || (rom_chip != 0))
    // [396] if(main::rom_chip4#10!=0) goto main::@217 -- vbum1_neq_0_then_la1 
    // IMPORTANT! We only flash the CX16 ROM chip if the SMC got flashed succesfully!
    lda rom_chip4
    bne __b217
    // main::@218
    // [397] if(0!=main::check_status_smc9_return#0) goto main::bank_set_brom6 -- 0_neq_vbuxx_then_la1 
    cpx #0
    bne bank_set_brom6
    // main::@217
  __b217:
    // [398] if(main::rom_chip4#10!=0) goto main::bank_set_brom6 -- vbum1_neq_0_then_la1 
    lda rom_chip4
    bne bank_set_brom6
    // main::@46
    // display_info_rom(rom_chip, STATUS_ISSUE, "Update SMC failed!")
    // [399] display_info_rom::rom_chip#10 = main::rom_chip4#10 -- vbuz1=vbum2 
    sta.z display_info_rom.rom_chip
    // [400] call display_info_rom
    // [1199] phi from main::@46 to display_info_rom [phi:main::@46->display_info_rom]
    // [1199] phi display_info_rom::info_text#16 = main::info_text21 [phi:main::@46->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text21
    sta.z display_info_rom.info_text
    lda #>info_text21
    sta.z display_info_rom.info_text+1
    // [1199] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#10 [phi:main::@46->display_info_rom#1] -- register_copy 
    // [1199] phi display_info_rom::info_status#16 = STATUS_ISSUE [phi:main::@46->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_rom.info_status
    jsr display_info_rom
    // [401] phi from main::@177 main::@188 main::@41 main::@45 main::@46 main::@72 to main::@40 [phi:main::@177/main::@188/main::@41/main::@45/main::@46/main::@72->main::@40]
    // [401] phi __errno#411 = __errno#18 [phi:main::@177/main::@188/main::@41/main::@45/main::@46/main::@72->main::@40#0] -- register_copy 
    // main::@40
  __b40:
    // for(unsigned char rom_chip = 7; rom_chip != 255; rom_chip--)
    // [402] main::rom_chip4#1 = -- main::rom_chip4#10 -- vbum1=_dec_vbum1 
    dec rom_chip4
    // [389] phi from main::@40 to main::@39 [phi:main::@40->main::@39]
    // [389] phi __errno#114 = __errno#411 [phi:main::@40->main::@39#0] -- register_copy 
    // [389] phi main::rom_chip4#10 = main::rom_chip4#1 [phi:main::@40->main::@39#1] -- register_copy 
    jmp __b39
    // main::bank_set_brom6
  bank_set_brom6:
    // BROM = bank
    // [403] BROM = main::bank_set_brom6_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom6_bank
    sta.z BROM
    // [404] phi from main::bank_set_brom6 to main::@74 [phi:main::bank_set_brom6->main::@74]
    // main::@74
    // display_progress_clear()
    // [405] call display_progress_clear
    // [826] phi from main::@74 to display_progress_clear [phi:main::@74->display_progress_clear]
    jsr display_progress_clear
    // main::@170
    // unsigned char rom_bank = rom_chip * 32
    // [406] main::rom_bank1#0 = main::rom_chip4#10 << 5 -- vbum1=vbum2_rol_5 
    lda rom_chip4
    asl
    asl
    asl
    asl
    asl
    sta rom_bank1
    // unsigned char* file = rom_file(rom_chip)
    // [407] rom_file::rom_chip#1 = main::rom_chip4#10 -- vbuaa=vbum1 
    lda rom_chip4
    // [408] call rom_file
    // [1242] phi from main::@170 to rom_file [phi:main::@170->rom_file]
    // [1242] phi rom_file::rom_chip#2 = rom_file::rom_chip#1 [phi:main::@170->rom_file#0] -- register_copy 
    jsr rom_file
    // unsigned char* file = rom_file(rom_chip)
    // [409] rom_file::return#5 = rom_file::return#2
    // main::@171
    // [410] main::file1#0 = rom_file::return#5
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [411] call snprintf_init
    // [982] phi from main::@171 to snprintf_init [phi:main::@171->snprintf_init]
    // [982] phi snprintf_init::s#27 = info_text [phi:main::@171->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [412] phi from main::@171 to main::@172 [phi:main::@171->main::@172]
    // main::@172
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [413] call printf_str
    // [987] phi from main::@172 to printf_str [phi:main::@172->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:main::@172->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = s13 [phi:main::@172->printf_str#1] -- pbuz1=pbuc1 
    lda #<s13
    sta.z printf_str.s
    lda #>s13
    sta.z printf_str.s+1
    jsr printf_str
    // main::@173
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [414] printf_string::str#21 = main::file1#0 -- pbuz1=pbum2 
    lda file1
    sta.z printf_string.str
    lda file1+1
    sta.z printf_string.str+1
    // [415] call printf_string
    // [1130] phi from main::@173 to printf_string [phi:main::@173->printf_string]
    // [1130] phi printf_string::putc#22 = &snputc [phi:main::@173->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1130] phi printf_string::str#22 = printf_string::str#21 [phi:main::@173->printf_string#1] -- register_copy 
    // [1130] phi printf_string::format_justify_left#22 = 0 [phi:main::@173->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1130] phi printf_string::format_min_length#22 = 0 [phi:main::@173->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [416] phi from main::@173 to main::@174 [phi:main::@173->main::@174]
    // main::@174
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [417] call printf_str
    // [987] phi from main::@174 to printf_str [phi:main::@174->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:main::@174->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = main::s8 [phi:main::@174->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // main::@175
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [418] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [419] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_progress(info_text)
    // [421] call display_action_progress
    // [812] phi from main::@175 to display_action_progress [phi:main::@175->display_action_progress]
    // [812] phi display_action_progress::info_text#15 = info_text [phi:main::@175->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_progress.info_text
    lda #>@info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@176
    // unsigned long rom_bytes_read = rom_read(1, rom_chip, file, STATUS_READING, rom_bank, rom_sizes[rom_chip])
    // [422] main::$245 = main::rom_chip4#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip4
    asl
    asl
    sta main__245
    // [423] rom_read::file#1 = main::file1#0 -- pbum1=pbum2 
    lda file1
    sta rom_read.file
    lda file1+1
    sta rom_read.file+1
    // [424] rom_read::brom_bank_start#2 = main::rom_bank1#0 -- vbuz1=vbum2 
    lda rom_bank1
    sta.z rom_read.brom_bank_start
    // [425] rom_read::rom_size#1 = rom_sizes[main::$245] -- vduz1=pduc1_derefidx_vbum2 
    ldy main__245
    lda rom_sizes,y
    sta.z rom_read.rom_size
    lda rom_sizes+1,y
    sta.z rom_read.rom_size+1
    lda rom_sizes+2,y
    sta.z rom_read.rom_size+2
    lda rom_sizes+3,y
    sta.z rom_read.rom_size+3
    // [426] call rom_read
    // [1248] phi from main::@176 to rom_read [phi:main::@176->rom_read]
    // [1248] phi rom_read::display_progress#28 = 1 [phi:main::@176->rom_read#0] -- vbuz1=vbuc1 
    lda #1
    sta.z rom_read.display_progress
    // [1248] phi rom_read::rom_size#12 = rom_read::rom_size#1 [phi:main::@176->rom_read#1] -- register_copy 
    // [1248] phi __errno#106 = __errno#114 [phi:main::@176->rom_read#2] -- register_copy 
    // [1248] phi rom_read::file#11 = rom_read::file#1 [phi:main::@176->rom_read#3] -- register_copy 
    // [1248] phi rom_read::brom_bank_start#22 = rom_read::brom_bank_start#2 [phi:main::@176->rom_read#4] -- register_copy 
    jsr rom_read
    // unsigned long rom_bytes_read = rom_read(1, rom_chip, file, STATUS_READING, rom_bank, rom_sizes[rom_chip])
    // [427] rom_read::return#3 = rom_read::return#0
    // main::@177
    // [428] main::rom_bytes_read1#0 = rom_read::return#3
    // if(rom_bytes_read)
    // [429] if(0==main::rom_bytes_read1#0) goto main::@40 -- 0_eq_vduz1_then_la1 
    lda.z rom_bytes_read1
    ora.z rom_bytes_read1+1
    ora.z rom_bytes_read1+2
    ora.z rom_bytes_read1+3
    bne !__b40+
    jmp __b40
  !__b40:
    // [430] phi from main::@177 to main::@43 [phi:main::@177->main::@43]
    // main::@43
    // display_action_progress("Comparing ... (.) same, (*) different.")
    // [431] call display_action_progress
  // Now we compare the RAM with the actual ROM contents.
    // [812] phi from main::@43 to display_action_progress [phi:main::@43->display_action_progress]
    // [812] phi display_action_progress::info_text#15 = main::info_text22 [phi:main::@43->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text22
    sta.z display_action_progress.info_text
    lda #>info_text22
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@178
    // display_info_rom(rom_chip, STATUS_COMPARING, "")
    // [432] display_info_rom::rom_chip#11 = main::rom_chip4#10 -- vbuz1=vbum2 
    lda rom_chip4
    sta.z display_info_rom.rom_chip
    // [433] call display_info_rom
    // [1199] phi from main::@178 to display_info_rom [phi:main::@178->display_info_rom]
    // [1199] phi display_info_rom::info_text#16 = info_text4 [phi:main::@178->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z display_info_rom.info_text
    lda #>info_text4
    sta.z display_info_rom.info_text+1
    // [1199] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#11 [phi:main::@178->display_info_rom#1] -- register_copy 
    // [1199] phi display_info_rom::info_status#16 = STATUS_COMPARING [phi:main::@178->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_COMPARING
    sta display_info_rom.info_status
    jsr display_info_rom
    // main::@179
    // unsigned long rom_differences = rom_verify(
    //                             rom_chip, rom_bank, file_sizes[rom_chip])
    // [434] rom_verify::rom_chip#0 = main::rom_chip4#10 -- vbuz1=vbum2 
    lda rom_chip4
    sta.z rom_verify.rom_chip
    // [435] rom_verify::rom_bank_start#0 = main::rom_bank1#0 -- vbuxx=vbum1 
    ldx rom_bank1
    // [436] rom_verify::file_size#0 = file_sizes[main::$245] -- vdum1=pduc1_derefidx_vbum2 
    ldy main__245
    lda file_sizes,y
    sta rom_verify.file_size
    lda file_sizes+1,y
    sta rom_verify.file_size+1
    lda file_sizes+2,y
    sta rom_verify.file_size+2
    lda file_sizes+3,y
    sta rom_verify.file_size+3
    // [437] call rom_verify
    // Verify the ROM...
    jsr rom_verify
    // [438] rom_verify::return#2 = rom_verify::rom_different_bytes#11
    // main::@180
    // [439] main::rom_differences#0 = rom_verify::return#2 -- vduz1=vduz2 
    lda.z rom_verify.return
    sta.z rom_differences
    lda.z rom_verify.return+1
    sta.z rom_differences+1
    lda.z rom_verify.return+2
    sta.z rom_differences+2
    lda.z rom_verify.return+3
    sta.z rom_differences+3
    // if (!rom_differences)
    // [440] if(0==main::rom_differences#0) goto main::@41 -- 0_eq_vduz1_then_la1 
    lda.z rom_differences
    ora.z rom_differences+1
    ora.z rom_differences+2
    ora.z rom_differences+3
    bne !__b41+
    jmp __b41
  !__b41:
    // [441] phi from main::@180 to main::@44 [phi:main::@180->main::@44]
    // main::@44
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [442] call snprintf_init
    // [982] phi from main::@44 to snprintf_init [phi:main::@44->snprintf_init]
    // [982] phi snprintf_init::s#27 = info_text [phi:main::@44->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main::@181
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [443] printf_ulong::uvalue#7 = main::rom_differences#0
    // [444] call printf_ulong
    // [1399] phi from main::@181 to printf_ulong [phi:main::@181->printf_ulong]
    // [1399] phi printf_ulong::format_zero_padding#10 = 1 [phi:main::@181->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1399] phi printf_ulong::format_min_length#10 = 5 [phi:main::@181->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1399] phi printf_ulong::format_radix#10 = HEXADECIMAL [phi:main::@181->printf_ulong#2] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [1399] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#7 [phi:main::@181->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [445] phi from main::@181 to main::@182 [phi:main::@181->main::@182]
    // main::@182
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [446] call printf_str
    // [987] phi from main::@182 to printf_str [phi:main::@182->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:main::@182->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = main::s15 [phi:main::@182->printf_str#1] -- pbuz1=pbuc1 
    lda #<s15
    sta.z printf_str.s
    lda #>s15
    sta.z printf_str.s+1
    jsr printf_str
    // main::@183
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [447] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [448] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_FLASH, info_text)
    // [450] display_info_rom::rom_chip#13 = main::rom_chip4#10 -- vbuz1=vbum2 
    lda rom_chip4
    sta.z display_info_rom.rom_chip
    // [451] call display_info_rom
    // [1199] phi from main::@183 to display_info_rom [phi:main::@183->display_info_rom]
    // [1199] phi display_info_rom::info_text#16 = info_text [phi:main::@183->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1199] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#13 [phi:main::@183->display_info_rom#1] -- register_copy 
    // [1199] phi display_info_rom::info_status#16 = STATUS_FLASH [phi:main::@183->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta display_info_rom.info_status
    jsr display_info_rom
    // main::@184
    // unsigned long rom_flash_errors = rom_flash(
    //                                 rom_chip, rom_bank, file_sizes[rom_chip])
    // [452] rom_flash::rom_chip#0 = main::rom_chip4#10 -- vbum1=vbum2 
    lda rom_chip4
    sta rom_flash.rom_chip
    // [453] rom_flash::rom_bank_start#0 = main::rom_bank1#0 -- vbum1=vbum2 
    lda rom_bank1
    sta rom_flash.rom_bank_start
    // [454] rom_flash::file_size#0 = file_sizes[main::$245] -- vduz1=pduc1_derefidx_vbum2 
    ldy main__245
    lda file_sizes,y
    sta.z rom_flash.file_size
    lda file_sizes+1,y
    sta.z rom_flash.file_size+1
    lda file_sizes+2,y
    sta.z rom_flash.file_size+2
    lda file_sizes+3,y
    sta.z rom_flash.file_size+3
    // [455] call rom_flash
    // [1409] phi from main::@184 to rom_flash [phi:main::@184->rom_flash]
    jsr rom_flash
    // unsigned long rom_flash_errors = rom_flash(
    //                                 rom_chip, rom_bank, file_sizes[rom_chip])
    // [456] rom_flash::return#2 = rom_flash::flash_errors#10
    // main::@185
    // [457] main::rom_flash_errors#0 = rom_flash::return#2 -- vduz1=vduz2 
    lda.z rom_flash.return
    sta.z rom_flash_errors
    lda.z rom_flash.return+1
    sta.z rom_flash_errors+1
    lda.z rom_flash.return+2
    sta.z rom_flash_errors+2
    lda.z rom_flash.return+3
    sta.z rom_flash_errors+3
    // if(rom_flash_errors)
    // [458] if(0!=main::rom_flash_errors#0) goto main::@42 -- 0_neq_vduz1_then_la1 
    lda.z rom_flash_errors
    ora.z rom_flash_errors+1
    ora.z rom_flash_errors+2
    ora.z rom_flash_errors+3
    bne __b42
    // main::@45
    // display_info_rom(rom_chip, STATUS_FLASHED, "OK!")
    // [459] display_info_rom::rom_chip#15 = main::rom_chip4#10 -- vbuz1=vbum2 
    lda rom_chip4
    sta.z display_info_rom.rom_chip
    // [460] call display_info_rom
    // [1199] phi from main::@45 to display_info_rom [phi:main::@45->display_info_rom]
    // [1199] phi display_info_rom::info_text#16 = main::info_text25 [phi:main::@45->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text25
    sta.z display_info_rom.info_text
    lda #>info_text25
    sta.z display_info_rom.info_text+1
    // [1199] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#15 [phi:main::@45->display_info_rom#1] -- register_copy 
    // [1199] phi display_info_rom::info_status#16 = STATUS_FLASHED [phi:main::@45->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHED
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b40
    // [461] phi from main::@185 to main::@42 [phi:main::@185->main::@42]
    // main::@42
  __b42:
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [462] call snprintf_init
    // [982] phi from main::@42 to snprintf_init [phi:main::@42->snprintf_init]
    // [982] phi snprintf_init::s#27 = info_text [phi:main::@42->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main::@186
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [463] printf_ulong::uvalue#8 = main::rom_flash_errors#0 -- vduz1=vduz2 
    lda.z rom_flash_errors
    sta.z printf_ulong.uvalue
    lda.z rom_flash_errors+1
    sta.z printf_ulong.uvalue+1
    lda.z rom_flash_errors+2
    sta.z printf_ulong.uvalue+2
    lda.z rom_flash_errors+3
    sta.z printf_ulong.uvalue+3
    // [464] call printf_ulong
    // [1399] phi from main::@186 to printf_ulong [phi:main::@186->printf_ulong]
    // [1399] phi printf_ulong::format_zero_padding#10 = 0 [phi:main::@186->printf_ulong#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_ulong.format_zero_padding
    // [1399] phi printf_ulong::format_min_length#10 = 0 [phi:main::@186->printf_ulong#1] -- vbuz1=vbuc1 
    sta.z printf_ulong.format_min_length
    // [1399] phi printf_ulong::format_radix#10 = DECIMAL [phi:main::@186->printf_ulong#2] -- vbuxx=vbuc1 
    ldx #DECIMAL
    // [1399] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#8 [phi:main::@186->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [465] phi from main::@186 to main::@187 [phi:main::@186->main::@187]
    // main::@187
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [466] call printf_str
    // [987] phi from main::@187 to printf_str [phi:main::@187->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:main::@187->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = main::s16 [phi:main::@187->printf_str#1] -- pbuz1=pbuc1 
    lda #<s16
    sta.z printf_str.s
    lda #>s16
    sta.z printf_str.s+1
    jsr printf_str
    // main::@188
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [467] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [468] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_ERROR, info_text)
    // [470] display_info_rom::rom_chip#14 = main::rom_chip4#10 -- vbuz1=vbum2 
    lda rom_chip4
    sta.z display_info_rom.rom_chip
    // [471] call display_info_rom
    // [1199] phi from main::@188 to display_info_rom [phi:main::@188->display_info_rom]
    // [1199] phi display_info_rom::info_text#16 = info_text [phi:main::@188->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1199] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#14 [phi:main::@188->display_info_rom#1] -- register_copy 
    // [1199] phi display_info_rom::info_status#16 = STATUS_ERROR [phi:main::@188->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b40
    // main::@41
  __b41:
    // display_info_rom(rom_chip, STATUS_FLASHED, "No update required")
    // [472] display_info_rom::rom_chip#12 = main::rom_chip4#10 -- vbuz1=vbum2 
    lda rom_chip4
    sta.z display_info_rom.rom_chip
    // [473] call display_info_rom
    // [1199] phi from main::@41 to display_info_rom [phi:main::@41->display_info_rom]
    // [1199] phi display_info_rom::info_text#16 = main::info_text24 [phi:main::@41->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text24
    sta.z display_info_rom.info_text
    lda #>info_text24
    sta.z display_info_rom.info_text+1
    // [1199] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#12 [phi:main::@41->display_info_rom#1] -- register_copy 
    // [1199] phi display_info_rom::info_status#16 = STATUS_FLASHED [phi:main::@41->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHED
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b40
    // [474] phi from main::@216 to main::@47 [phi:main::@216->main::@47]
    // main::@47
  __b47:
    // display_progress_clear()
    // [475] call display_progress_clear
    // [826] phi from main::@47 to display_progress_clear [phi:main::@47->display_progress_clear]
    jsr display_progress_clear
    // [476] phi from main::@47 to main::@165 [phi:main::@47->main::@165]
    // main::@165
    // smc_read(1)
    // [477] call smc_read
    // [1056] phi from main::@165 to smc_read [phi:main::@165->smc_read]
    // [1056] phi smc_read::display_progress#19 = 1 [phi:main::@165->smc_read#0] -- vbum1=vbuc1 
    lda #1
    sta smc_read.display_progress
    // [1056] phi __errno#35 = __errno#112 [phi:main::@165->smc_read#1] -- register_copy 
    jsr smc_read
    // smc_read(1)
    // [478] smc_read::return#3 = smc_read::return#0
    // main::@166
    // smc_file_size = smc_read(1)
    // [479] smc_file_size#1 = smc_read::return#3 -- vwum1=vwuz2 
    lda.z smc_read.return
    sta smc_file_size
    lda.z smc_read.return+1
    sta smc_file_size+1
    // if(smc_file_size)
    // [480] if(0==smc_file_size#1) goto main::@37 -- 0_eq_vwum1_then_la1 
    lda smc_file_size
    ora smc_file_size+1
    bne !__b37+
    jmp __b37
  !__b37:
    // [481] phi from main::@166 to main::@48 [phi:main::@166->main::@48]
    // main::@48
    // display_action_text("Press both POWER/RESET buttons on the CX16 board!")
    // [482] call display_action_text
  // Flash the SMC chip.
    // [1176] phi from main::@48 to display_action_text [phi:main::@48->display_action_text]
    // [1176] phi display_action_text::info_text#19 = main::info_text17 [phi:main::@48->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text17
    sta.z display_action_text.info_text
    lda #>info_text17
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [483] phi from main::@48 to main::@167 [phi:main::@48->main::@167]
    // main::@167
    // display_info_smc(STATUS_FLASHING, "Press POWER/RESET!")
    // [484] call display_info_smc
    // [870] phi from main::@167 to display_info_smc [phi:main::@167->display_info_smc]
    // [870] phi display_info_smc::info_text#14 = main::info_text18 [phi:main::@167->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text18
    sta.z display_info_smc.info_text
    lda #>info_text18
    sta.z display_info_smc.info_text+1
    // [870] phi display_info_smc::info_status#14 = STATUS_FLASHING [phi:main::@167->display_info_smc#1] -- vbuz1=vbuc1 
    lda #STATUS_FLASHING
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // main::@168
    // unsigned long flashed_bytes = smc_flash(smc_file_size)
    // [485] smc_flash::smc_bytes_total#0 = smc_file_size#1 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_flash.smc_bytes_total
    lda smc_file_size+1
    sta smc_flash.smc_bytes_total+1
    // [486] call smc_flash
    // [1524] phi from main::@168 to smc_flash [phi:main::@168->smc_flash]
    jsr smc_flash
    // unsigned long flashed_bytes = smc_flash(smc_file_size)
    // [487] smc_flash::return#5 = smc_flash::return#1
    // main::@169
    // [488] main::flashed_bytes#0 = smc_flash::return#5 -- vdum1=vwuz2 
    lda.z smc_flash.return
    sta flashed_bytes
    lda.z smc_flash.return+1
    sta flashed_bytes+1
    lda #0
    sta flashed_bytes+2
    sta flashed_bytes+3
    // if(flashed_bytes)
    // [489] if(0!=main::flashed_bytes#0) goto main::@38 -- 0_neq_vdum1_then_la1 
    lda flashed_bytes
    ora flashed_bytes+1
    ora flashed_bytes+2
    ora flashed_bytes+3
    bne __b38
    // [490] phi from main::@169 to main::@49 [phi:main::@169->main::@49]
    // main::@49
    // display_info_smc(STATUS_ERROR, "SMC not updated!")
    // [491] call display_info_smc
    // [870] phi from main::@49 to display_info_smc [phi:main::@49->display_info_smc]
    // [870] phi display_info_smc::info_text#14 = main::info_text20 [phi:main::@49->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text20
    sta.z display_info_smc.info_text
    lda #>info_text20
    sta.z display_info_smc.info_text+1
    // [870] phi display_info_smc::info_status#14 = STATUS_ERROR [phi:main::@49->display_info_smc#1] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp __b37
    // [492] phi from main::@169 to main::@38 [phi:main::@169->main::@38]
    // main::@38
  __b38:
    // display_info_smc(STATUS_FLASHED, "")
    // [493] call display_info_smc
    // [870] phi from main::@38 to display_info_smc [phi:main::@38->display_info_smc]
    // [870] phi display_info_smc::info_text#14 = info_text4 [phi:main::@38->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z display_info_smc.info_text
    lda #>info_text4
    sta.z display_info_smc.info_text+1
    // [870] phi display_info_smc::info_status#14 = STATUS_FLASHED [phi:main::@38->display_info_smc#1] -- vbuz1=vbuc1 
    lda #STATUS_FLASHED
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp __b37
    // [494] phi from main::@214 main::@215 to main::@4 [phi:main::@214/main::@215->main::@4]
    // main::@4
  __b4:
    // display_action_progress("Chipsets have been detected and update files validated!")
    // [495] call display_action_progress
    // [812] phi from main::@4 to display_action_progress [phi:main::@4->display_action_progress]
    // [812] phi display_action_progress::info_text#15 = main::info_text11 [phi:main::@4->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text11
    sta.z display_action_progress.info_text
    lda #>info_text11
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [496] phi from main::@4 to main::@160 [phi:main::@4->main::@160]
    // main::@160
    // unsigned char ch = util_wait_key("Continue with update of highlighted chipsets? [Y/N]", "nyNY")
    // [497] call util_wait_key
    // [1686] phi from main::@160 to util_wait_key [phi:main::@160->util_wait_key]
    // [1686] phi util_wait_key::filter#12 = main::filter [phi:main::@160->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter
    sta.z util_wait_key.filter
    lda #>filter
    sta.z util_wait_key.filter+1
    // [1686] phi util_wait_key::info_text#2 = main::info_text12 [phi:main::@160->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text12
    sta.z util_wait_key.info_text
    lda #>info_text12
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("Continue with update of highlighted chipsets? [Y/N]", "nyNY")
    // [498] util_wait_key::return#3 = util_wait_key::ch#4 -- vbuaa=vwum1 
    lda util_wait_key.ch
    // main::@161
    // [499] main::ch#0 = util_wait_key::return#3
    // strchr("nN", ch)
    // [500] strchr::c#1 = main::ch#0 -- vbuz1=vbuaa 
    sta.z strchr.c
    // [501] call strchr
    // [1710] phi from main::@161 to strchr [phi:main::@161->strchr]
    // [1710] phi strchr::c#4 = strchr::c#1 [phi:main::@161->strchr#0] -- register_copy 
    // [1710] phi strchr::str#2 = (const void *)main::$268 [phi:main::@161->strchr#1] -- pvoz1=pvoc1 
    lda #<main__268
    sta.z strchr.str
    lda #>main__268
    sta.z strchr.str+1
    jsr strchr
    // strchr("nN", ch)
    // [502] strchr::return#4 = strchr::return#2
    // main::@162
    // [503] main::$159 = strchr::return#4
    // if(strchr("nN", ch))
    // [504] if((void *)0==main::$159) goto main::bank_set_bram2 -- pvoc1_eq_pvoz1_then_la1 
    lda.z main__159
    cmp #<0
    bne !+
    lda.z main__159+1
    cmp #>0
    bne !bank_set_bram2+
    jmp bank_set_bram2
  !bank_set_bram2:
  !:
    // [505] phi from main::@162 to main::@5 [phi:main::@162->main::@5]
    // main::@5
    // display_info_smc(STATUS_SKIP, "Cancelled")
    // [506] call display_info_smc
  // We cancel all updates, the updates are skipped.
    // [870] phi from main::@5 to display_info_smc [phi:main::@5->display_info_smc]
    // [870] phi display_info_smc::info_text#14 = main::info_text13 [phi:main::@5->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text13
    sta.z display_info_smc.info_text
    lda #>info_text13
    sta.z display_info_smc.info_text+1
    // [870] phi display_info_smc::info_status#14 = STATUS_SKIP [phi:main::@5->display_info_smc#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [507] phi from main::@5 to main::@163 [phi:main::@5->main::@163]
    // main::@163
    // display_info_vera(STATUS_SKIP, "Cancelled")
    // [508] call display_info_vera
    // [900] phi from main::@163 to display_info_vera [phi:main::@163->display_info_vera]
    // [900] phi display_info_vera::info_text#10 = main::info_text13 [phi:main::@163->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text13
    sta.z display_info_vera.info_text
    lda #>info_text13
    sta.z display_info_vera.info_text+1
    // [900] phi display_info_vera::info_status#3 = STATUS_SKIP [phi:main::@163->display_info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // [509] phi from main::@163 to main::@34 [phi:main::@163->main::@34]
    // [509] phi main::rom_chip3#2 = 0 [phi:main::@163->main::@34#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip3
    // main::@34
  __b34:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [510] if(main::rom_chip3#2<8) goto main::@35 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip3
    cmp #8
    bcc __b35
    // [511] phi from main::@34 to main::@36 [phi:main::@34->main::@36]
    // main::@36
    // display_action_text("You have selected not to cancel the update ... ")
    // [512] call display_action_text
    // [1176] phi from main::@36 to display_action_text [phi:main::@36->display_action_text]
    // [1176] phi display_action_text::info_text#19 = main::info_text16 [phi:main::@36->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text16
    sta.z display_action_text.info_text
    lda #>info_text16
    sta.z display_action_text.info_text+1
    jsr display_action_text
    jmp bank_set_bram2
    // main::@35
  __b35:
    // display_info_rom(rom_chip, STATUS_SKIP, "Cancelled")
    // [513] display_info_rom::rom_chip#9 = main::rom_chip3#2 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z display_info_rom.rom_chip
    // [514] call display_info_rom
    // [1199] phi from main::@35 to display_info_rom [phi:main::@35->display_info_rom]
    // [1199] phi display_info_rom::info_text#16 = main::info_text13 [phi:main::@35->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text13
    sta.z display_info_rom.info_text
    lda #>info_text13
    sta.z display_info_rom.info_text+1
    // [1199] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#9 [phi:main::@35->display_info_rom#1] -- register_copy 
    // [1199] phi display_info_rom::info_status#16 = STATUS_SKIP [phi:main::@35->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_rom.info_status
    jsr display_info_rom
    // main::@164
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [515] main::rom_chip3#1 = ++ main::rom_chip3#2 -- vbum1=_inc_vbum1 
    inc rom_chip3
    // [509] phi from main::@164 to main::@34 [phi:main::@164->main::@34]
    // [509] phi main::rom_chip3#2 = main::rom_chip3#1 [phi:main::@164->main::@34#0] -- register_copy 
    jmp __b34
    // main::check_status_card_roms1_check_status_rom1
  check_status_card_roms1_check_status_rom1:
    // status_rom[rom_chip] == status
    // [516] main::check_status_card_roms1_check_status_rom1_$0 = status_rom[main::check_status_card_roms1_rom_chip#2] == STATUS_FLASH -- vboaa=pbuc1_derefidx_vbuxx_eq_vbuc2 
    lda #STATUS_FLASH
    eor status_rom,x
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [517] main::check_status_card_roms1_check_status_rom1_return#0 = (char)main::check_status_card_roms1_check_status_rom1_$0
    // main::check_status_card_roms1_@11
    // if(check_status_rom(rom_chip, status))
    // [518] if(0==main::check_status_card_roms1_check_status_rom1_return#0) goto main::check_status_card_roms1_@4 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq check_status_card_roms1___b4
    // [375] phi from main::check_status_card_roms1_@11 to main::check_status_card_roms1_@return [phi:main::check_status_card_roms1_@11->main::check_status_card_roms1_@return]
    // [375] phi main::check_status_card_roms1_return#2 = STATUS_FLASH [phi:main::check_status_card_roms1_@11->main::check_status_card_roms1_@return#0] -- vbuxx=vbuc1 
    ldx #STATUS_FLASH
    jmp __b70
    // main::check_status_card_roms1_@4
  check_status_card_roms1___b4:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [519] main::check_status_card_roms1_rom_chip#1 = ++ main::check_status_card_roms1_rom_chip#2 -- vbuxx=_inc_vbuxx 
    inx
    // [373] phi from main::check_status_card_roms1_@4 to main::check_status_card_roms1_@1 [phi:main::check_status_card_roms1_@4->main::check_status_card_roms1_@1]
    // [373] phi main::check_status_card_roms1_rom_chip#2 = main::check_status_card_roms1_rom_chip#1 [phi:main::check_status_card_roms1_@4->main::check_status_card_roms1_@1#0] -- register_copy 
    jmp check_status_card_roms1___b1
    // main::check_status_roms_all2_check_status_rom1
  check_status_roms_all2_check_status_rom1:
    // status_rom[rom_chip] == status
    // [520] main::check_status_roms_all2_check_status_rom1_$0 = status_rom[main::check_status_roms_all2_rom_chip#2] == STATUS_ERROR -- vboaa=pbuc1_derefidx_vbuxx_eq_vbuc2 
    lda #STATUS_ERROR
    eor status_rom,x
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [521] main::check_status_roms_all2_check_status_rom1_return#0 = (char)main::check_status_roms_all2_check_status_rom1_$0
    // main::check_status_roms_all2_@11
    // if(check_status_rom(rom_chip, status) != status)
    // [522] if(main::check_status_roms_all2_check_status_rom1_return#0==STATUS_ERROR) goto main::check_status_roms_all2_@4 -- vbuaa_eq_vbuc1_then_la1 
    cmp #STATUS_ERROR
    beq check_status_roms_all2___b4
    // [242] phi from main::check_status_roms_all2_@11 to main::check_status_roms_all2_@return [phi:main::check_status_roms_all2_@11->main::check_status_roms_all2_@return]
    // [242] phi main::check_status_roms_all2_return#2 = 0 [phi:main::check_status_roms_all2_@11->main::check_status_roms_all2_@return#0] -- vbuxx=vbuc1 
    ldx #0
    jmp __b68
    // main::check_status_roms_all2_@4
  check_status_roms_all2___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [523] main::check_status_roms_all2_rom_chip#1 = ++ main::check_status_roms_all2_rom_chip#2 -- vbuxx=_inc_vbuxx 
    inx
    // [240] phi from main::check_status_roms_all2_@4 to main::check_status_roms_all2_@1 [phi:main::check_status_roms_all2_@4->main::check_status_roms_all2_@1]
    // [240] phi main::check_status_roms_all2_rom_chip#2 = main::check_status_roms_all2_rom_chip#1 [phi:main::check_status_roms_all2_@4->main::check_status_roms_all2_@1#0] -- register_copy 
    jmp check_status_roms_all2___b1
    // main::check_status_roms_all1_check_status_rom1
  check_status_roms_all1_check_status_rom1:
    // status_rom[rom_chip] == status
    // [524] main::check_status_roms_all1_check_status_rom1_$0 = status_rom[main::check_status_roms_all1_rom_chip#2] == STATUS_ISSUE -- vboaa=pbuc1_derefidx_vbuxx_eq_vbuc2 
    lda #STATUS_ISSUE
    eor status_rom,x
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [525] main::check_status_roms_all1_check_status_rom1_return#0 = (char)main::check_status_roms_all1_check_status_rom1_$0
    // main::check_status_roms_all1_@11
    // if(check_status_rom(rom_chip, status) != status)
    // [526] if(main::check_status_roms_all1_check_status_rom1_return#0==STATUS_ISSUE) goto main::check_status_roms_all1_@4 -- vbuaa_eq_vbuc1_then_la1 
    cmp #STATUS_ISSUE
    beq check_status_roms_all1___b4
    // [234] phi from main::check_status_roms_all1_@11 to main::check_status_roms_all1_@return [phi:main::check_status_roms_all1_@11->main::check_status_roms_all1_@return]
    // [234] phi main::check_status_roms_all1_return#2 = 0 [phi:main::check_status_roms_all1_@11->main::check_status_roms_all1_@return#0] -- vbum1=vbuc1 
    lda #0
    sta check_status_roms_all1_return
    jmp check_status_smc5
    // main::check_status_roms_all1_@4
  check_status_roms_all1___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [527] main::check_status_roms_all1_rom_chip#1 = ++ main::check_status_roms_all1_rom_chip#2 -- vbuxx=_inc_vbuxx 
    inx
    // [232] phi from main::check_status_roms_all1_@4 to main::check_status_roms_all1_@1 [phi:main::check_status_roms_all1_@4->main::check_status_roms_all1_@1]
    // [232] phi main::check_status_roms_all1_rom_chip#2 = main::check_status_roms_all1_rom_chip#1 [phi:main::check_status_roms_all1_@4->main::check_status_roms_all1_@1#0] -- register_copy 
    jmp check_status_roms_all1___b1
    // [528] phi from main::@206 to main::@3 [phi:main::@206->main::@3]
    // main::@3
  __b3:
    // display_action_progress("Please check the main CX16 ROM update issue!")
    // [529] call display_action_progress
    // [812] phi from main::@3 to display_action_progress [phi:main::@3->display_action_progress]
    // [812] phi display_action_progress::info_text#15 = main::info_text9 [phi:main::@3->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text9
    sta.z display_action_progress.info_text
    lda #>info_text9
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [530] phi from main::@3 to main::@156 [phi:main::@3->main::@156]
    // main::@156
    // display_progress_text(display_smc_rom_issue__text, display_smc_rom_issue_count)
    // [531] call display_progress_text
    // [926] phi from main::@156 to display_progress_text [phi:main::@156->display_progress_text]
    // [926] phi display_progress_text::text#10 = display_smc_rom_issue__text [phi:main::@156->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_rom_issue__text
    sta.z display_progress_text.text
    lda #>display_smc_rom_issue__text
    sta.z display_progress_text.text+1
    // [926] phi display_progress_text::lines#11 = display_smc_rom_issue_count [phi:main::@156->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_smc_rom_issue_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [532] phi from main::@156 to main::@157 [phi:main::@156->main::@157]
    // main::@157
    // display_info_smc(STATUS_SKIP, "Issue with main CX16 ROM!")
    // [533] call display_info_smc
    // [870] phi from main::@157 to display_info_smc [phi:main::@157->display_info_smc]
    // [870] phi display_info_smc::info_text#14 = main::info_text10 [phi:main::@157->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text10
    sta.z display_info_smc.info_text
    lda #>info_text10
    sta.z display_info_smc.info_text+1
    // [870] phi display_info_smc::info_status#14 = STATUS_SKIP [phi:main::@157->display_info_smc#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [534] phi from main::@157 to main::@158 [phi:main::@157->main::@158]
    // main::@158
    // display_info_cx16_rom(STATUS_ISSUE, NULL)
    // [535] call display_info_cx16_rom
    // [1719] phi from main::@158 to display_info_cx16_rom [phi:main::@158->display_info_cx16_rom]
    // [1719] phi display_info_cx16_rom::info_text#2 = 0 [phi:main::@158->display_info_cx16_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_cx16_rom.info_text
    sta.z display_info_cx16_rom.info_text+1
    // [1719] phi display_info_cx16_rom::info_status#2 = STATUS_ISSUE [phi:main::@158->display_info_cx16_rom#1] -- vbuxx=vbuc1 
    ldx #STATUS_ISSUE
    jsr display_info_cx16_rom
    // [536] phi from main::@158 to main::@159 [phi:main::@158->main::@159]
    // main::@159
    // util_wait_space()
    // [537] call util_wait_space
    // [936] phi from main::@159 to util_wait_space [phi:main::@159->util_wait_space]
    jsr util_wait_space
    jmp check_status_smc4
    // [538] phi from main::@205 to main::@33 [phi:main::@205->main::@33]
    // main::@33
  __b33:
    // display_action_progress("Please check the SMC update issue!")
    // [539] call display_action_progress
    // [812] phi from main::@33 to display_action_progress [phi:main::@33->display_action_progress]
    // [812] phi display_action_progress::info_text#15 = main::info_text7 [phi:main::@33->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z display_action_progress.info_text
    lda #>info_text7
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [540] phi from main::@33 to main::@152 [phi:main::@33->main::@152]
    // main::@152
    // display_progress_text(display_smc_rom_issue__text, display_smc_rom_issue_count)
    // [541] call display_progress_text
    // [926] phi from main::@152 to display_progress_text [phi:main::@152->display_progress_text]
    // [926] phi display_progress_text::text#10 = display_smc_rom_issue__text [phi:main::@152->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_rom_issue__text
    sta.z display_progress_text.text
    lda #>display_smc_rom_issue__text
    sta.z display_progress_text.text+1
    // [926] phi display_progress_text::lines#11 = display_smc_rom_issue_count [phi:main::@152->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_smc_rom_issue_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [542] phi from main::@152 to main::@153 [phi:main::@152->main::@153]
    // main::@153
    // display_info_cx16_rom(STATUS_SKIP, "Issue with SMC!")
    // [543] call display_info_cx16_rom
    // [1719] phi from main::@153 to display_info_cx16_rom [phi:main::@153->display_info_cx16_rom]
    // [1719] phi display_info_cx16_rom::info_text#2 = main::info_text8 [phi:main::@153->display_info_cx16_rom#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z display_info_cx16_rom.info_text
    lda #>info_text8
    sta.z display_info_cx16_rom.info_text+1
    // [1719] phi display_info_cx16_rom::info_status#2 = STATUS_SKIP [phi:main::@153->display_info_cx16_rom#1] -- vbuxx=vbuc1 
    ldx #STATUS_SKIP
    jsr display_info_cx16_rom
    // [544] phi from main::@153 to main::@154 [phi:main::@153->main::@154]
    // main::@154
    // display_info_smc(STATUS_ISSUE, NULL)
    // [545] call display_info_smc
    // [870] phi from main::@154 to display_info_smc [phi:main::@154->display_info_smc]
    // [870] phi display_info_smc::info_text#14 = 0 [phi:main::@154->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [870] phi display_info_smc::info_status#14 = STATUS_ISSUE [phi:main::@154->display_info_smc#1] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [546] phi from main::@154 to main::@155 [phi:main::@154->main::@155]
    // main::@155
    // util_wait_space()
    // [547] call util_wait_space
    // [936] phi from main::@155 to util_wait_space [phi:main::@155->util_wait_space]
    jsr util_wait_space
    jmp check_status_smc3
    // main::bank_set_brom4
  bank_set_brom4:
    // BROM = bank
    // [548] BROM = main::bank_set_brom4_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom4_bank
    sta.z BROM
    // main::@63
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [549] if(rom_device_ids[main::rom_chip2#10]==$55) goto main::@27 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    ldy rom_chip2
    lda rom_device_ids,y
    cmp #$55
    bne !__b27+
    jmp __b27
  !__b27:
    // [550] phi from main::@63 to main::@30 [phi:main::@63->main::@30]
    // main::@30
    // display_progress_clear()
    // [551] call display_progress_clear
    // [826] phi from main::@30 to display_progress_clear [phi:main::@30->display_progress_clear]
    jsr display_progress_clear
    // main::@130
    // unsigned char rom_bank = rom_chip * 32
    // [552] main::rom_bank#0 = main::rom_chip2#10 << 5 -- vbum1=vbum2_rol_5 
    lda rom_chip2
    asl
    asl
    asl
    asl
    asl
    sta rom_bank
    // unsigned char* file = rom_file(rom_chip)
    // [553] rom_file::rom_chip#0 = main::rom_chip2#10 -- vbuaa=vbum1 
    lda rom_chip2
    // [554] call rom_file
    // [1242] phi from main::@130 to rom_file [phi:main::@130->rom_file]
    // [1242] phi rom_file::rom_chip#2 = rom_file::rom_chip#0 [phi:main::@130->rom_file#0] -- register_copy 
    jsr rom_file
    // unsigned char* file = rom_file(rom_chip)
    // [555] rom_file::return#4 = rom_file::return#2
    // main::@131
    // [556] main::file#0 = rom_file::return#4 -- pbum1=pbum2 
    lda rom_file.return
    sta file
    lda rom_file.return+1
    sta file+1
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [557] call snprintf_init
    // [982] phi from main::@131 to snprintf_init [phi:main::@131->snprintf_init]
    // [982] phi snprintf_init::s#27 = info_text [phi:main::@131->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [558] phi from main::@131 to main::@132 [phi:main::@131->main::@132]
    // main::@132
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [559] call printf_str
    // [987] phi from main::@132 to printf_str [phi:main::@132->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:main::@132->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = main::s7 [phi:main::@132->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@133
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [560] printf_string::str#16 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [561] call printf_string
    // [1130] phi from main::@133 to printf_string [phi:main::@133->printf_string]
    // [1130] phi printf_string::putc#22 = &snputc [phi:main::@133->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1130] phi printf_string::str#22 = printf_string::str#16 [phi:main::@133->printf_string#1] -- register_copy 
    // [1130] phi printf_string::format_justify_left#22 = 0 [phi:main::@133->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1130] phi printf_string::format_min_length#22 = 0 [phi:main::@133->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [562] phi from main::@133 to main::@134 [phi:main::@133->main::@134]
    // main::@134
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [563] call printf_str
    // [987] phi from main::@134 to printf_str [phi:main::@134->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:main::@134->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = main::s8 [phi:main::@134->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // main::@135
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [564] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [565] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_progress(info_text)
    // [567] call display_action_progress
    // [812] phi from main::@135 to display_action_progress [phi:main::@135->display_action_progress]
    // [812] phi display_action_progress::info_text#15 = info_text [phi:main::@135->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_progress.info_text
    lda #>@info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@136
    // unsigned long rom_bytes_read = rom_read(0, rom_chip, file, STATUS_CHECKING, rom_bank, rom_sizes[rom_chip])
    // [568] main::$243 = main::rom_chip2#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip2
    asl
    asl
    sta main__243
    // [569] rom_read::file#0 = main::file#0 -- pbum1=pbum2 
    lda file
    sta rom_read.file
    lda file+1
    sta rom_read.file+1
    // [570] rom_read::brom_bank_start#1 = main::rom_bank#0 -- vbuz1=vbum2 
    lda rom_bank
    sta.z rom_read.brom_bank_start
    // [571] rom_read::rom_size#0 = rom_sizes[main::$243] -- vduz1=pduc1_derefidx_vbum2 
    ldy main__243
    lda rom_sizes,y
    sta.z rom_read.rom_size
    lda rom_sizes+1,y
    sta.z rom_read.rom_size+1
    lda rom_sizes+2,y
    sta.z rom_read.rom_size+2
    lda rom_sizes+3,y
    sta.z rom_read.rom_size+3
    // [572] call rom_read
  // Read the ROM(n).BIN file.
    // [1248] phi from main::@136 to rom_read [phi:main::@136->rom_read]
    // [1248] phi rom_read::display_progress#28 = 0 [phi:main::@136->rom_read#0] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_read.display_progress
    // [1248] phi rom_read::rom_size#12 = rom_read::rom_size#0 [phi:main::@136->rom_read#1] -- register_copy 
    // [1248] phi __errno#106 = __errno#112 [phi:main::@136->rom_read#2] -- register_copy 
    // [1248] phi rom_read::file#11 = rom_read::file#0 [phi:main::@136->rom_read#3] -- register_copy 
    // [1248] phi rom_read::brom_bank_start#22 = rom_read::brom_bank_start#1 [phi:main::@136->rom_read#4] -- register_copy 
    jsr rom_read
    // unsigned long rom_bytes_read = rom_read(0, rom_chip, file, STATUS_CHECKING, rom_bank, rom_sizes[rom_chip])
    // [573] rom_read::return#2 = rom_read::return#0
    // main::@137
    // [574] main::rom_bytes_read#0 = rom_read::return#2
    // if (!rom_bytes_read)
    // [575] if(0==main::rom_bytes_read#0) goto main::@28 -- 0_eq_vduz1_then_la1 
    // In case no file was found, set the status to none and skip to the next, else, mention the amount of bytes read.
    lda.z rom_bytes_read
    ora.z rom_bytes_read+1
    ora.z rom_bytes_read+2
    ora.z rom_bytes_read+3
    bne !__b28+
    jmp __b28
  !__b28:
    // main::@31
    // unsigned long rom_file_modulo = rom_bytes_read % 0x4000
    // [576] main::rom_file_modulo#0 = main::rom_bytes_read#0 & $4000-1 -- vduz1=vduz2_band_vduc1 
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
    // [577] if(0!=main::rom_file_modulo#0) goto main::@29 -- 0_neq_vduz1_then_la1 
    lda.z rom_file_modulo
    ora.z rom_file_modulo+1
    ora.z rom_file_modulo+2
    ora.z rom_file_modulo+3
    beq !__b29+
    jmp __b29
  !__b29:
    // main::@32
    // file_sizes[rom_chip] = rom_bytes_read
    // [578] file_sizes[main::$243] = main::rom_bytes_read#0 -- pduc1_derefidx_vbum1=vduz2 
    // We know the file size, so we indicate it in the status panel.
    ldy main__243
    lda.z rom_bytes_read
    sta file_sizes,y
    lda.z rom_bytes_read+1
    sta file_sizes+1,y
    lda.z rom_bytes_read+2
    sta file_sizes+2,y
    lda.z rom_bytes_read+3
    sta file_sizes+3,y
    // rom_get_github_commit_id(file_rom_github, (char*)RAM_BASE)
    // [579] call rom_get_github_commit_id
    // [1724] phi from main::@32 to rom_get_github_commit_id [phi:main::@32->rom_get_github_commit_id]
    // [1724] phi rom_get_github_commit_id::commit_id#6 = main::file_rom_github [phi:main::@32->rom_get_github_commit_id#0] -- pbuz1=pbuc1 
    lda #<file_rom_github
    sta.z rom_get_github_commit_id.commit_id
    lda #>file_rom_github
    sta.z rom_get_github_commit_id.commit_id+1
    // [1724] phi rom_get_github_commit_id::from#6 = (char *)$7800 [phi:main::@32->rom_get_github_commit_id#1] -- pbuz1=pbuc1 
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
    // [581] BRAM = main::bank_push_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_push_set_bram1_bank
    sta.z BRAM
    // main::@65
    // unsigned char file_rom_release = rom_get_release(*((char*)0xBF80))
    // [582] rom_get_release::release#3 = *((char *) 49024) -- vbuxx=_deref_pbuc1 
    ldx $bf80
    // [583] call rom_get_release
    // [1114] phi from main::@65 to rom_get_release [phi:main::@65->rom_get_release]
    // [1114] phi rom_get_release::release#4 = rom_get_release::release#3 [phi:main::@65->rom_get_release#0] -- register_copy 
    jsr rom_get_release
    // unsigned char file_rom_release = rom_get_release(*((char*)0xBF80))
    // [584] rom_get_release::return#4 = rom_get_release::return#0
    // main::@145
    // [585] main::file_rom_release#0 = rom_get_release::return#4 -- vbuyy=vbuxx 
    txa
    tay
    // unsigned char file_rom_prefix = rom_get_prefix(*((char*)0xBF80))
    // [586] rom_get_prefix::release#3 = *((char *) 49024) -- vbuaa=_deref_pbuc1 
    lda $bf80
    // [587] call rom_get_prefix
    // [1121] phi from main::@145 to rom_get_prefix [phi:main::@145->rom_get_prefix]
    // [1121] phi rom_get_prefix::release#4 = rom_get_prefix::release#3 [phi:main::@145->rom_get_prefix#0] -- register_copy 
    jsr rom_get_prefix
    // unsigned char file_rom_prefix = rom_get_prefix(*((char*)0xBF80))
    // [588] rom_get_prefix::return#10 = rom_get_prefix::return#0 -- vbuaa=vbuxx 
    txa
    // main::@146
    // [589] main::file_rom_prefix#0 = rom_get_prefix::return#10 -- vbuxx=vbuaa 
    tax
    // main::bank_pull_bram1
    // asm
    // asm { pla sta$00  }
    pla
    sta.z 0
    // main::@66
    // rom_get_version_text(file_rom_release_text, file_rom_prefix, file_rom_release, file_rom_github)
    // [591] rom_get_version_text::prefix#1 = main::file_rom_prefix#0
    // [592] rom_get_version_text::release#1 = main::file_rom_release#0 -- vbum1=vbuyy 
    sty rom_get_version_text.release
    // [593] call rom_get_version_text
    // [1741] phi from main::@66 to rom_get_version_text [phi:main::@66->rom_get_version_text]
    // [1741] phi rom_get_version_text::github#2 = main::file_rom_github [phi:main::@66->rom_get_version_text#0] -- pbuz1=pbuc1 
    lda #<file_rom_github
    sta.z rom_get_version_text.github
    lda #>file_rom_github
    sta.z rom_get_version_text.github+1
    // [1741] phi rom_get_version_text::release#2 = rom_get_version_text::release#1 [phi:main::@66->rom_get_version_text#1] -- register_copy 
    // [1741] phi rom_get_version_text::prefix#2 = rom_get_version_text::prefix#1 [phi:main::@66->rom_get_version_text#2] -- register_copy 
    // [1741] phi rom_get_version_text::release_info#2 = main::file_rom_release_text [phi:main::@66->rom_get_version_text#3] -- pbuz1=pbuc1 
    lda #<file_rom_release_text
    sta.z rom_get_version_text.release_info
    lda #>file_rom_release_text
    sta.z rom_get_version_text.release_info+1
    jsr rom_get_version_text
    // [594] phi from main::@66 to main::@147 [phi:main::@66->main::@147]
    // main::@147
    // sprintf(info_text, "%s %s", file, file_rom_release_text)
    // [595] call snprintf_init
    // [982] phi from main::@147 to snprintf_init [phi:main::@147->snprintf_init]
    // [982] phi snprintf_init::s#27 = info_text [phi:main::@147->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main::@148
    // sprintf(info_text, "%s %s", file, file_rom_release_text)
    // [596] printf_string::str#19 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [597] call printf_string
    // [1130] phi from main::@148 to printf_string [phi:main::@148->printf_string]
    // [1130] phi printf_string::putc#22 = &snputc [phi:main::@148->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1130] phi printf_string::str#22 = printf_string::str#19 [phi:main::@148->printf_string#1] -- register_copy 
    // [1130] phi printf_string::format_justify_left#22 = 0 [phi:main::@148->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1130] phi printf_string::format_min_length#22 = 0 [phi:main::@148->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [598] phi from main::@148 to main::@149 [phi:main::@148->main::@149]
    // main::@149
    // sprintf(info_text, "%s %s", file, file_rom_release_text)
    // [599] call printf_str
    // [987] phi from main::@149 to printf_str [phi:main::@149->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:main::@149->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = s [phi:main::@149->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s
    sta.z printf_str.s
    lda #>@s
    sta.z printf_str.s+1
    jsr printf_str
    // [600] phi from main::@149 to main::@150 [phi:main::@149->main::@150]
    // main::@150
    // sprintf(info_text, "%s %s", file, file_rom_release_text)
    // [601] call printf_string
    // [1130] phi from main::@150 to printf_string [phi:main::@150->printf_string]
    // [1130] phi printf_string::putc#22 = &snputc [phi:main::@150->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1130] phi printf_string::str#22 = main::file_rom_release_text [phi:main::@150->printf_string#1] -- pbuz1=pbuc1 
    lda #<file_rom_release_text
    sta.z printf_string.str
    lda #>file_rom_release_text
    sta.z printf_string.str+1
    // [1130] phi printf_string::format_justify_left#22 = 0 [phi:main::@150->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1130] phi printf_string::format_min_length#22 = 0 [phi:main::@150->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@151
    // sprintf(info_text, "%s %s", file, file_rom_release_text)
    // [602] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [603] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_FLASH, info_text)
    // [605] display_info_rom::rom_chip#8 = main::rom_chip2#10 -- vbuz1=vbum2 
    lda rom_chip2
    sta.z display_info_rom.rom_chip
    // [606] call display_info_rom
    // [1199] phi from main::@151 to display_info_rom [phi:main::@151->display_info_rom]
    // [1199] phi display_info_rom::info_text#16 = info_text [phi:main::@151->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1199] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#8 [phi:main::@151->display_info_rom#1] -- register_copy 
    // [1199] phi display_info_rom::info_status#16 = STATUS_FLASH [phi:main::@151->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta display_info_rom.info_status
    jsr display_info_rom
    // [607] phi from main::@140 main::@144 main::@151 main::@63 to main::@27 [phi:main::@140/main::@144/main::@151/main::@63->main::@27]
    // [607] phi __errno#246 = __errno#18 [phi:main::@140/main::@144/main::@151/main::@63->main::@27#0] -- register_copy 
    // main::@27
  __b27:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [608] main::rom_chip2#1 = ++ main::rom_chip2#10 -- vbum1=_inc_vbum1 
    inc rom_chip2
    // [209] phi from main::@27 to main::@26 [phi:main::@27->main::@26]
    // [209] phi __errno#112 = __errno#246 [phi:main::@27->main::@26#0] -- register_copy 
    // [209] phi main::rom_chip2#10 = main::rom_chip2#1 [phi:main::@27->main::@26#1] -- register_copy 
    jmp __b26
    // [609] phi from main::@31 to main::@29 [phi:main::@31->main::@29]
    // main::@29
  __b29:
    // sprintf(info_text, "File %s size error!", file)
    // [610] call snprintf_init
    // [982] phi from main::@29 to snprintf_init [phi:main::@29->snprintf_init]
    // [982] phi snprintf_init::s#27 = info_text [phi:main::@29->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [611] phi from main::@29 to main::@141 [phi:main::@29->main::@141]
    // main::@141
    // sprintf(info_text, "File %s size error!", file)
    // [612] call printf_str
    // [987] phi from main::@141 to printf_str [phi:main::@141->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:main::@141->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = main::s10 [phi:main::@141->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // main::@142
    // sprintf(info_text, "File %s size error!", file)
    // [613] printf_string::str#18 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [614] call printf_string
    // [1130] phi from main::@142 to printf_string [phi:main::@142->printf_string]
    // [1130] phi printf_string::putc#22 = &snputc [phi:main::@142->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1130] phi printf_string::str#22 = printf_string::str#18 [phi:main::@142->printf_string#1] -- register_copy 
    // [1130] phi printf_string::format_justify_left#22 = 0 [phi:main::@142->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1130] phi printf_string::format_min_length#22 = 0 [phi:main::@142->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [615] phi from main::@142 to main::@143 [phi:main::@142->main::@143]
    // main::@143
    // sprintf(info_text, "File %s size error!", file)
    // [616] call printf_str
    // [987] phi from main::@143 to printf_str [phi:main::@143->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:main::@143->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = main::s11 [phi:main::@143->printf_str#1] -- pbuz1=pbuc1 
    lda #<s11
    sta.z printf_str.s
    lda #>s11
    sta.z printf_str.s+1
    jsr printf_str
    // main::@144
    // sprintf(info_text, "File %s size error!", file)
    // [617] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [618] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_ISSUE, info_text)
    // [620] display_info_rom::rom_chip#7 = main::rom_chip2#10 -- vbuz1=vbum2 
    lda rom_chip2
    sta.z display_info_rom.rom_chip
    // [621] call display_info_rom
    // [1199] phi from main::@144 to display_info_rom [phi:main::@144->display_info_rom]
    // [1199] phi display_info_rom::info_text#16 = info_text [phi:main::@144->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1199] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#7 [phi:main::@144->display_info_rom#1] -- register_copy 
    // [1199] phi display_info_rom::info_status#16 = STATUS_ISSUE [phi:main::@144->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b27
    // [622] phi from main::@137 to main::@28 [phi:main::@137->main::@28]
    // main::@28
  __b28:
    // sprintf(info_text, "No %s", file)
    // [623] call snprintf_init
    // [982] phi from main::@28 to snprintf_init [phi:main::@28->snprintf_init]
    // [982] phi snprintf_init::s#27 = info_text [phi:main::@28->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [624] phi from main::@28 to main::@138 [phi:main::@28->main::@138]
    // main::@138
    // sprintf(info_text, "No %s", file)
    // [625] call printf_str
    // [987] phi from main::@138 to printf_str [phi:main::@138->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:main::@138->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = main::s9 [phi:main::@138->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // main::@139
    // sprintf(info_text, "No %s", file)
    // [626] printf_string::str#17 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [627] call printf_string
    // [1130] phi from main::@139 to printf_string [phi:main::@139->printf_string]
    // [1130] phi printf_string::putc#22 = &snputc [phi:main::@139->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1130] phi printf_string::str#22 = printf_string::str#17 [phi:main::@139->printf_string#1] -- register_copy 
    // [1130] phi printf_string::format_justify_left#22 = 0 [phi:main::@139->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1130] phi printf_string::format_min_length#22 = 0 [phi:main::@139->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@140
    // sprintf(info_text, "No %s", file)
    // [628] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [629] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_SKIP, info_text)
    // [631] display_info_rom::rom_chip#6 = main::rom_chip2#10 -- vbuz1=vbum2 
    lda rom_chip2
    sta.z display_info_rom.rom_chip
    // [632] call display_info_rom
    // [1199] phi from main::@140 to display_info_rom [phi:main::@140->display_info_rom]
    // [1199] phi display_info_rom::info_text#16 = info_text [phi:main::@140->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1199] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#6 [phi:main::@140->display_info_rom#1] -- register_copy 
    // [1199] phi display_info_rom::info_status#16 = STATUS_SKIP [phi:main::@140->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b27
    // [633] phi from main::@22 to main::@25 [phi:main::@22->main::@25]
    // main::@25
  __b25:
    // display_info_smc(STATUS_ISSUE, "SMC.BIN too large!")
    // [634] call display_info_smc
    // [870] phi from main::@25 to display_info_smc [phi:main::@25->display_info_smc]
    // [870] phi display_info_smc::info_text#14 = main::info_text6 [phi:main::@25->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text6
    sta.z display_info_smc.info_text
    lda #>info_text6
    sta.z display_info_smc.info_text+1
    // [870] phi display_info_smc::info_status#14 = STATUS_ISSUE [phi:main::@25->display_info_smc#1] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp CLI2
    // [635] phi from main::@120 to main::@24 [phi:main::@120->main::@24]
    // main::@24
  __b24:
    // display_info_smc(STATUS_SKIP, "No SMC.BIN!")
    // [636] call display_info_smc
    // [870] phi from main::@24 to display_info_smc [phi:main::@24->display_info_smc]
    // [870] phi display_info_smc::info_text#14 = main::info_text5 [phi:main::@24->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z display_info_smc.info_text
    lda #>info_text5
    sta.z display_info_smc.info_text+1
    // [870] phi display_info_smc::info_status#14 = STATUS_SKIP [phi:main::@24->display_info_smc#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp CLI2
    // main::@18
  __b18:
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [637] if(rom_device_ids[main::rom_chip1#10]!=$55) goto main::@19 -- pbuc1_derefidx_vbum1_neq_vbuc2_then_la1 
    lda #$55
    ldy rom_chip1
    cmp rom_device_ids,y
    bne __b19
    // main::@20
  __b20:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [638] main::rom_chip1#1 = ++ main::rom_chip1#10 -- vbum1=_inc_vbum1 
    inc rom_chip1
    // [164] phi from main::@20 to main::@17 [phi:main::@20->main::@17]
    // [164] phi main::rom_chip1#10 = main::rom_chip1#1 [phi:main::@20->main::@17#0] -- register_copy 
    jmp __b17
    // main::@19
  __b19:
    // rom_chip*8
    // [639] main::$102 = main::rom_chip1#10 << 3 -- vbuz1=vbum2_rol_3 
    lda rom_chip1
    asl
    asl
    asl
    sta.z main__102
    // rom_get_github_commit_id(&rom_github[rom_chip*8], (char*)0xC000)
    // [640] rom_get_github_commit_id::commit_id#0 = rom_github + main::$102 -- pbuz1=pbuc1_plus_vbuz2 
    clc
    adc #<rom_github
    sta.z rom_get_github_commit_id.commit_id
    lda #>rom_github
    adc #0
    sta.z rom_get_github_commit_id.commit_id+1
    // [641] call rom_get_github_commit_id
  // Fill the version data ...
    // [1724] phi from main::@19 to rom_get_github_commit_id [phi:main::@19->rom_get_github_commit_id]
    // [1724] phi rom_get_github_commit_id::commit_id#6 = rom_get_github_commit_id::commit_id#0 [phi:main::@19->rom_get_github_commit_id#0] -- register_copy 
    // [1724] phi rom_get_github_commit_id::from#6 = (char *) 49152 [phi:main::@19->rom_get_github_commit_id#1] -- pbuz1=pbuc1 
    lda #<$c000
    sta.z rom_get_github_commit_id.from
    lda #>$c000
    sta.z rom_get_github_commit_id.from+1
    jsr rom_get_github_commit_id
    // main::@116
    // rom_get_release(*((char*)0xFF80))
    // [642] rom_get_release::release#1 = *((char *) 65408) -- vbuxx=_deref_pbuc1 
    ldx $ff80
    // [643] call rom_get_release
    // [1114] phi from main::@116 to rom_get_release [phi:main::@116->rom_get_release]
    // [1114] phi rom_get_release::release#4 = rom_get_release::release#1 [phi:main::@116->rom_get_release#0] -- register_copy 
    jsr rom_get_release
    // rom_get_release(*((char*)0xFF80))
    // [644] rom_get_release::return#2 = rom_get_release::return#0
    // main::@117
    // [645] main::$98 = rom_get_release::return#2 -- vbuaa=vbuxx 
    txa
    // rom_release[rom_chip] = rom_get_release(*((char*)0xFF80))
    // [646] rom_release[main::rom_chip1#10] = main::$98 -- pbuc1_derefidx_vbum1=vbuaa 
    ldy rom_chip1
    sta rom_release,y
    // rom_get_prefix(*((char*)0xFF80))
    // [647] rom_get_prefix::release#0 = *((char *) 65408) -- vbuaa=_deref_pbuc1 
    lda $ff80
    // [648] call rom_get_prefix
    // [1121] phi from main::@117 to rom_get_prefix [phi:main::@117->rom_get_prefix]
    // [1121] phi rom_get_prefix::release#4 = rom_get_prefix::release#0 [phi:main::@117->rom_get_prefix#0] -- register_copy 
    jsr rom_get_prefix
    // rom_get_prefix(*((char*)0xFF80))
    // [649] rom_get_prefix::return#2 = rom_get_prefix::return#0
    // main::@118
    // [650] main::$99 = rom_get_prefix::return#2 -- vbuaa=vbuxx 
    txa
    // rom_prefix[rom_chip] = rom_get_prefix(*((char*)0xFF80))
    // [651] rom_prefix[main::rom_chip1#10] = main::$99 -- pbuc1_derefidx_vbum1=vbuaa 
    ldy rom_chip1
    sta rom_prefix,y
    // rom_chip*13
    // [652] main::$290 = main::rom_chip1#10 << 1 -- vbuaa=vbum1_rol_1 
    tya
    asl
    // [653] main::$291 = main::$290 + main::rom_chip1#10 -- vbuaa=vbuaa_plus_vbum1 
    clc
    adc rom_chip1
    // [654] main::$292 = main::$291 << 2 -- vbuaa=vbuaa_rol_2 
    asl
    asl
    // [655] main::$100 = main::$292 + main::rom_chip1#10 -- vbuaa=vbuaa_plus_vbum1 
    clc
    adc rom_chip1
    // rom_get_version_text(&rom_release_text[rom_chip*13], rom_prefix[rom_chip], rom_release[rom_chip], &rom_github[rom_chip*8])
    // [656] rom_get_version_text::release_info#0 = rom_release_text + main::$100 -- pbuz1=pbuc1_plus_vbuaa 
    clc
    adc #<rom_release_text
    sta.z rom_get_version_text.release_info
    lda #>rom_release_text
    adc #0
    sta.z rom_get_version_text.release_info+1
    // [657] rom_get_version_text::github#0 = rom_github + main::$102 -- pbuz1=pbuc1_plus_vbuz2 
    lda.z main__102
    clc
    adc #<rom_github
    sta.z rom_get_version_text.github
    lda #>rom_github
    adc #0
    sta.z rom_get_version_text.github+1
    // [658] rom_get_version_text::prefix#0 = rom_prefix[main::rom_chip1#10] -- vbuxx=pbuc1_derefidx_vbum1 
    ldx rom_prefix,y
    // [659] rom_get_version_text::release#0 = rom_release[main::rom_chip1#10] -- vbum1=pbuc1_derefidx_vbum2 
    lda rom_release,y
    sta rom_get_version_text.release
    // [660] call rom_get_version_text
    // [1741] phi from main::@118 to rom_get_version_text [phi:main::@118->rom_get_version_text]
    // [1741] phi rom_get_version_text::github#2 = rom_get_version_text::github#0 [phi:main::@118->rom_get_version_text#0] -- register_copy 
    // [1741] phi rom_get_version_text::release#2 = rom_get_version_text::release#0 [phi:main::@118->rom_get_version_text#1] -- register_copy 
    // [1741] phi rom_get_version_text::prefix#2 = rom_get_version_text::prefix#0 [phi:main::@118->rom_get_version_text#2] -- register_copy 
    // [1741] phi rom_get_version_text::release_info#2 = rom_get_version_text::release_info#0 [phi:main::@118->rom_get_version_text#3] -- register_copy 
    jsr rom_get_version_text
    // main::@119
    // display_info_rom(rom_chip, STATUS_DETECTED, "")
    // [661] display_info_rom::rom_chip#5 = main::rom_chip1#10 -- vbuz1=vbum2 
    lda rom_chip1
    sta.z display_info_rom.rom_chip
    // [662] call display_info_rom
    // [1199] phi from main::@119 to display_info_rom [phi:main::@119->display_info_rom]
    // [1199] phi display_info_rom::info_text#16 = info_text4 [phi:main::@119->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z display_info_rom.info_text
    lda #>info_text4
    sta.z display_info_rom.info_text+1
    // [1199] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#5 [phi:main::@119->display_info_rom#1] -- register_copy 
    // [1199] phi display_info_rom::info_status#16 = STATUS_DETECTED [phi:main::@119->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_DETECTED
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b20
    // [663] phi from main::@13 to main::@16 [phi:main::@13->main::@16]
    // main::@16
  __b16:
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [664] call snprintf_init
    // [982] phi from main::@16 to snprintf_init [phi:main::@16->snprintf_init]
    // [982] phi snprintf_init::s#27 = info_text [phi:main::@16->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [665] phi from main::@16 to main::@101 [phi:main::@16->main::@101]
    // main::@101
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [666] call printf_str
    // [987] phi from main::@101 to printf_str [phi:main::@101->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:main::@101->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = main::s2 [phi:main::@101->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main::@102
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [667] printf_uint::uvalue#12 = smc_bootloader#0 -- vwuz1=vwum2 
    lda smc_bootloader
    sta.z printf_uint.uvalue
    lda smc_bootloader+1
    sta.z printf_uint.uvalue+1
    // [668] call printf_uint
    // [996] phi from main::@102 to printf_uint [phi:main::@102->printf_uint]
    // [996] phi printf_uint::format_zero_padding#15 = 1 [phi:main::@102->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [996] phi printf_uint::format_min_length#15 = 2 [phi:main::@102->printf_uint#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uint.format_min_length
    // [996] phi printf_uint::format_radix#15 = HEXADECIMAL [phi:main::@102->printf_uint#2] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [996] phi printf_uint::uvalue#15 = printf_uint::uvalue#12 [phi:main::@102->printf_uint#3] -- register_copy 
    jsr printf_uint
    // [669] phi from main::@102 to main::@103 [phi:main::@102->main::@103]
    // main::@103
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [670] call printf_str
    // [987] phi from main::@103 to printf_str [phi:main::@103->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:main::@103->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = main::s3 [phi:main::@103->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // main::@104
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [671] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [672] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_smc(STATUS_ISSUE, info_text)
    // [674] call display_info_smc
    // [870] phi from main::@104 to display_info_smc [phi:main::@104->display_info_smc]
    // [870] phi display_info_smc::info_text#14 = info_text [phi:main::@104->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_smc.info_text
    lda #>@info_text
    sta.z display_info_smc.info_text+1
    // [870] phi display_info_smc::info_status#14 = STATUS_ISSUE [phi:main::@104->display_info_smc#1] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [675] phi from main::@104 to main::@105 [phi:main::@104->main::@105]
    // main::@105
    // display_progress_text(display_no_valid_smc_bootloader_text, display_no_valid_smc_bootloader_count)
    // [676] call display_progress_text
  // Bootloader is not supported by this utility, but is not error.
    // [926] phi from main::@105 to display_progress_text [phi:main::@105->display_progress_text]
    // [926] phi display_progress_text::text#10 = display_no_valid_smc_bootloader_text [phi:main::@105->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_no_valid_smc_bootloader_text
    sta.z display_progress_text.text
    lda #>display_no_valid_smc_bootloader_text
    sta.z display_progress_text.text+1
    // [926] phi display_progress_text::lines#11 = display_no_valid_smc_bootloader_count [phi:main::@105->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_no_valid_smc_bootloader_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    jmp __b2
    // [677] phi from main::@12 to main::@15 [phi:main::@12->main::@15]
    // main::@15
  __b15:
    // display_info_smc(STATUS_ERROR, "SMC Unreachable!")
    // [678] call display_info_smc
    // [870] phi from main::@15 to display_info_smc [phi:main::@15->display_info_smc]
    // [870] phi display_info_smc::info_text#14 = main::info_text2 [phi:main::@15->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z display_info_smc.info_text
    lda #>info_text2
    sta.z display_info_smc.info_text+1
    // [870] phi display_info_smc::info_status#14 = STATUS_ERROR [phi:main::@15->display_info_smc#1] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp __b2
    // [679] phi from main::@99 to main::@1 [phi:main::@99->main::@1]
    // main::@1
  __b1:
    // display_info_smc(STATUS_ISSUE, "No Bootloader!")
    // [680] call display_info_smc
    // [870] phi from main::@1 to display_info_smc [phi:main::@1->display_info_smc]
    // [870] phi display_info_smc::info_text#14 = main::info_text1 [phi:main::@1->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_smc.info_text
    lda #>info_text1
    sta.z display_info_smc.info_text+1
    // [870] phi display_info_smc::info_status#14 = STATUS_ISSUE [phi:main::@1->display_info_smc#1] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [681] phi from main::@1 to main::@100 [phi:main::@1->main::@100]
    // main::@100
    // display_progress_text(display_no_valid_smc_bootloader_text, display_no_valid_smc_bootloader_count)
    // [682] call display_progress_text
  // If the CX16 board does not have a bootloader, display info how to flash bootloader.
    // [926] phi from main::@100 to display_progress_text [phi:main::@100->display_progress_text]
    // [926] phi display_progress_text::text#10 = display_no_valid_smc_bootloader_text [phi:main::@100->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_no_valid_smc_bootloader_text
    sta.z display_progress_text.text
    lda #>display_no_valid_smc_bootloader_text
    sta.z display_progress_text.text+1
    // [926] phi display_progress_text::lines#11 = display_no_valid_smc_bootloader_count [phi:main::@100->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_no_valid_smc_bootloader_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    jmp __b2
    // main::@10
  __b10:
    // display_info_led(PROGRESS_X + 3, PROGRESS_Y + 3 + intro_status, status_color[intro_status], BLUE)
    // [683] display_info_led::y#3 = PROGRESS_Y+3 + main::intro_status#2 -- vbuz1=vbuc1_plus_vbum2 
    lda #PROGRESS_Y+3
    clc
    adc intro_status
    sta.z display_info_led.y
    // [684] display_info_led::tc#3 = status_color[main::intro_status#2] -- vbuxx=pbuc1_derefidx_vbum1 
    ldy intro_status
    ldx status_color,y
    // [685] call display_info_led
    // [1757] phi from main::@10 to display_info_led [phi:main::@10->display_info_led]
    // [1757] phi display_info_led::y#4 = display_info_led::y#3 [phi:main::@10->display_info_led#0] -- register_copy 
    // [1757] phi display_info_led::x#4 = PROGRESS_X+3 [phi:main::@10->display_info_led#1] -- vbuyy=vbuc1 
    ldy #PROGRESS_X+3
    // [1757] phi display_info_led::tc#4 = display_info_led::tc#3 [phi:main::@10->display_info_led#2] -- register_copy 
    jsr display_info_led
    // main::@95
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [686] main::intro_status#1 = ++ main::intro_status#2 -- vbum1=_inc_vbum1 
    inc intro_status
    // [109] phi from main::@95 to main::@9 [phi:main::@95->main::@9]
    // [109] phi main::intro_status#2 = main::intro_status#1 [phi:main::@95->main::@9#0] -- register_copy 
    jmp __b9
    // main::@8
  __b8:
    // rom_chip*13
    // [687] main::$286 = main::rom_chip#2 << 1 -- vbuaa=vbum1_rol_1 
    lda rom_chip
    asl
    // [688] main::$287 = main::$286 + main::rom_chip#2 -- vbuaa=vbuaa_plus_vbum1 
    clc
    adc rom_chip
    // [689] main::$288 = main::$287 << 2 -- vbuaa=vbuaa_rol_2 
    asl
    asl
    // [690] main::$72 = main::$288 + main::rom_chip#2 -- vbuaa=vbuaa_plus_vbum1 
    clc
    adc rom_chip
    // strcpy(&rom_release_text[rom_chip*13], "          " )
    // [691] strcpy::destination#1 = rom_release_text + main::$72 -- pbuz1=pbuc1_plus_vbuaa 
    clc
    adc #<rom_release_text
    sta.z strcpy.destination
    lda #>rom_release_text
    adc #0
    sta.z strcpy.destination+1
    // [692] call strcpy
    // [950] phi from main::@8 to strcpy [phi:main::@8->strcpy]
    // [950] phi strcpy::dst#0 = strcpy::destination#1 [phi:main::@8->strcpy#0] -- register_copy 
    // [950] phi strcpy::src#0 = main::source [phi:main::@8->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // main::@91
    // display_info_rom(rom_chip, STATUS_NONE, NULL)
    // [693] display_info_rom::rom_chip#4 = main::rom_chip#2 -- vbuz1=vbum2 
    lda rom_chip
    sta.z display_info_rom.rom_chip
    // [694] call display_info_rom
    // [1199] phi from main::@91 to display_info_rom [phi:main::@91->display_info_rom]
    // [1199] phi display_info_rom::info_text#16 = 0 [phi:main::@91->display_info_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_rom.info_text
    sta.z display_info_rom.info_text+1
    // [1199] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#4 [phi:main::@91->display_info_rom#1] -- register_copy 
    // [1199] phi display_info_rom::info_status#16 = STATUS_NONE [phi:main::@91->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta display_info_rom.info_status
    jsr display_info_rom
    // main::@92
    // for(unsigned char rom_chip=0; rom_chip<8; rom_chip++)
    // [695] main::rom_chip#1 = ++ main::rom_chip#2 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [99] phi from main::@92 to main::@7 [phi:main::@92->main::@7]
    // [99] phi main::rom_chip#2 = main::rom_chip#1 [phi:main::@92->main::@7#0] -- register_copy 
    jmp __b7
  .segment Data
    file_smc_version_text: .fill $d, 0
    // Fill the version data ...
    file_rom_github: .fill 8, 0
    file_rom_release_text: .fill $d, 0
    title_text: .text "Commander X16 Flash Utility!"
    .byte 0
    s: .text "# Chip Status    Type   Curr. Release Update Info"
    .byte 0
    s1: .text "- ---- --------- ------ ------------- --------------------"
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
    s4: .text "BL:v"
    .byte 0
    info_text3: .text "VERA installed, OK"
    .byte 0
    info_text5: .text "No SMC.BIN!"
    .byte 0
    info_text6: .text "SMC.BIN too large!"
    .byte 0
    s6: .text ", SMC:"
    .byte 0
    s7: .text "Checking "
    .byte 0
    s8: .text " ... (.) data ( ) empty"
    .byte 0
    s9: .text "No "
    .byte 0
    s10: .text "File "
    .byte 0
    s11: .text " size error!"
    .byte 0
    info_text7: .text "Please check the SMC update issue!"
    .byte 0
    info_text8: .text "Issue with SMC!"
    .byte 0
    info_text9: .text "Please check the main CX16 ROM update issue!"
    .byte 0
    info_text10: .text "Issue with main CX16 ROM!"
    .byte 0
    info_text11: .text "Chipsets have been detected and update files validated!"
    .byte 0
    info_text12: .text "Continue with update of highlighted chipsets? [Y/N]"
    .byte 0
    filter: .text "nyNY"
    .byte 0
    main__268: .text "nN"
    .byte 0
    info_text13: .text "Cancelled"
    .byte 0
    info_text16: .text "You have selected not to cancel the update ... "
    .byte 0
    info_text17: .text "Press both POWER/RESET buttons on the CX16 board!"
    .byte 0
    info_text18: .text "Press POWER/RESET!"
    .byte 0
    info_text20: .text "SMC not updated!"
    .byte 0
    info_text21: .text "Update SMC failed!"
    .byte 0
    info_text22: .text "Comparing ... (.) same, (*) different."
    .byte 0
    info_text24: .text "No update required"
    .byte 0
    s15: .text " differences!"
    .byte 0
    s16: .text " flash errors!"
    .byte 0
    info_text25: .text "OK!"
    .byte 0
    info_text26: .text "The update has been cancelled!"
    .byte 0
    info_text27: .text "Update Failure! Your CX16 may be bricked!"
    .byte 0
    info_text28: .text "Take a foto of this screen. And shut down power ..."
    .byte 0
    info_text29: .text "Update issues, your CX16 is not updated!"
    .byte 0
    info_text30: .text "Your CX16 update is a success!"
    .byte 0
    s17: .text "("
    .byte 0
    s18: .text ") Please read carefully the below ..."
    .byte 0
    s19: .text "Please disconnect your CX16 from power source ..."
    .byte 0
    s21: .text ") Your CX16 will reset ..."
    .byte 0
    main__243: .byte 0
    main__245: .byte 0
    rom_chip: .byte 0
    intro_status: .byte 0
    rom_chip1: .byte 0
    rom_chip2: .byte 0
    rom_bank: .byte 0
    file: .word 0
    .label check_status_roms_all1_return = rom_chip
    check_status_smc7_return: .byte 0
    rom_chip3: .byte 0
    flashed_bytes: .dword 0
    rom_chip4: .byte 0
    rom_bank1: .byte 0
    .label file1 = rom_file.return
    check_status_smc10_return: .byte 0
    check_status_smc11_return: .byte 0
    w: .byte 0
    w1: .byte 0
}
.segment Code
  // screenlayer1
// Set the layer with which the conio will interact.
screenlayer1: {
    // screenlayer(1, *VERA_L1_MAPBASE, *VERA_L1_CONFIG)
    // [696] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbuxx=_deref_pbuc1 
    ldx VERA_L1_MAPBASE
    // [697] screenlayer::config#0 = *VERA_L1_CONFIG -- vbuz1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta.z screenlayer.config
    // [698] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [699] return 
    rts
}
  // textcolor
// Set the front color for text output. The old front text color setting is returned.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char textcolor(__register(X) char color)
textcolor: {
    // __conio.color & 0xF0
    // [701] textcolor::$0 = *((char *)&__conio+$d) & $f0 -- vbuaa=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$d
    // __conio.color & 0xF0 | color
    // [702] textcolor::$1 = textcolor::$0 | textcolor::color#18 -- vbuaa=vbuaa_bor_vbuxx 
    stx.z $ff
    ora.z $ff
    // __conio.color = __conio.color & 0xF0 | color
    // [703] *((char *)&__conio+$d) = textcolor::$1 -- _deref_pbuc1=vbuaa 
    sta __conio+$d
    // textcolor::@return
    // }
    // [704] return 
    rts
}
  // bgcolor
// Set the back color for text output.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char bgcolor(__register(X) char color)
bgcolor: {
    .label bgcolor__0 = $bd
    // __conio.color & 0x0F
    // [706] bgcolor::$0 = *((char *)&__conio+$d) & $f -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$d
    sta.z bgcolor__0
    // color << 4
    // [707] bgcolor::$1 = bgcolor::color#14 << 4 -- vbuaa=vbuxx_rol_4 
    txa
    asl
    asl
    asl
    asl
    // __conio.color & 0x0F | color << 4
    // [708] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbuaa=vbuz1_bor_vbuaa 
    ora.z bgcolor__0
    // __conio.color = __conio.color & 0x0F | color << 4
    // [709] *((char *)&__conio+$d) = bgcolor::$2 -- _deref_pbuc1=vbuaa 
    sta __conio+$d
    // bgcolor::@return
    // }
    // [710] return 
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
    // [711] *((char *)&__conio+$c) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$c
    // cursor::@return
    // }
    // [712] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    // __mem unsigned char x
    // [713] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [714] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [716] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwum1=vbum2_word_vbum3 
    lda x
    sta return+1
    lda y
    sta return
    // cbm_k_plot_get::@return
    // }
    // [717] return 
    rts
  .segment Data
    x: .byte 0
    y: .byte 0
    return: .word 0
}
.segment Code
  // gotoxy
// Set the cursor to the specified position
// void gotoxy(__register(X) char x, __register(Y) char y)
gotoxy: {
    .label gotoxy__9 = $3a
    // (x>=__conio.width)?__conio.width:x
    // [719] if(gotoxy::x#30>=*((char *)&__conio+6)) goto gotoxy::@1 -- vbuxx_ge__deref_pbuc1_then_la1 
    cpx __conio+6
    bcs __b1
    // [721] phi from gotoxy gotoxy::@1 to gotoxy::@2 [phi:gotoxy/gotoxy::@1->gotoxy::@2]
    // [721] phi gotoxy::$3 = gotoxy::x#30 [phi:gotoxy/gotoxy::@1->gotoxy::@2#0] -- register_copy 
    jmp __b2
    // gotoxy::@1
  __b1:
    // [720] gotoxy::$2 = *((char *)&__conio+6) -- vbuxx=_deref_pbuc1 
    ldx __conio+6
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [722] *((char *)&__conio) = gotoxy::$3 -- _deref_pbuc1=vbuxx 
    stx __conio
    // (y>=__conio.height)?__conio.height:y
    // [723] if(gotoxy::y#30>=*((char *)&__conio+7)) goto gotoxy::@3 -- vbuyy_ge__deref_pbuc1_then_la1 
    cpy __conio+7
    bcs __b3
    // gotoxy::@4
    // [724] gotoxy::$14 = gotoxy::y#30 -- vbuaa=vbuyy 
    tya
    // [725] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [725] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [726] *((char *)&__conio+1) = gotoxy::$7 -- _deref_pbuc1=vbuaa 
    sta __conio+1
    // __conio.cursor_x << 1
    // [727] gotoxy::$8 = *((char *)&__conio) << 1 -- vbuxx=_deref_pbuc1_rol_1 
    lda __conio
    asl
    tax
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [728] gotoxy::$10 = gotoxy::y#30 << 1 -- vbuaa=vbuyy_rol_1 
    tya
    asl
    // [729] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwuz1=pwuc1_derefidx_vbuaa_plus_vbuxx 
    tay
    txa
    clc
    adc __conio+$15,y
    sta.z gotoxy__9
    lda __conio+$15+1,y
    adc #0
    sta.z gotoxy__9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [730] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwuz1 
    lda.z gotoxy__9
    sta __conio+$13
    lda.z gotoxy__9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [731] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [732] gotoxy::$6 = *((char *)&__conio+7) -- vbuaa=_deref_pbuc1 
    lda __conio+7
    jmp __b5
}
  // cputln
// Print a newline
cputln: {
    // __conio.cursor_x = 0
    // [733] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y++;
    // [734] *((char *)&__conio+1) = ++ *((char *)&__conio+1) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+1
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [735] cputln::$2 = *((char *)&__conio+1) << 1 -- vbuaa=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    // [736] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbuaa 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [737] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [738] return 
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
    // [740] call textcolor
  // Set the charset to lower case.
  // screenlayer1();
    // [700] phi from display_frame_init_64 to textcolor [phi:display_frame_init_64->textcolor]
    // [700] phi textcolor::color#18 = WHITE [phi:display_frame_init_64->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [741] phi from display_frame_init_64 to display_frame_init_64::@2 [phi:display_frame_init_64->display_frame_init_64::@2]
    // display_frame_init_64::@2
    // bgcolor(BLUE)
    // [742] call bgcolor
    // [705] phi from display_frame_init_64::@2 to bgcolor [phi:display_frame_init_64::@2->bgcolor]
    // [705] phi bgcolor::color#14 = BLUE [phi:display_frame_init_64::@2->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // [743] phi from display_frame_init_64::@2 to display_frame_init_64::@3 [phi:display_frame_init_64::@2->display_frame_init_64::@3]
    // display_frame_init_64::@3
    // scroll(0)
    // [744] call scroll
    jsr scroll
    // [745] phi from display_frame_init_64::@3 to display_frame_init_64::@4 [phi:display_frame_init_64::@3->display_frame_init_64::@4]
    // display_frame_init_64::@4
    // clrscr()
    // [746] call clrscr
    jsr clrscr
    // display_frame_init_64::vera_display_set_hstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [747] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTART = start
    // [748] *VERA_DC_HSTART = display_frame_init_64::vera_display_set_hstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstart1_start
    sta VERA_DC_HSTART
    // display_frame_init_64::vera_display_set_hstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [749] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTOP = stop
    // [750] *VERA_DC_HSTOP = display_frame_init_64::vera_display_set_hstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstop1_stop
    sta VERA_DC_HSTOP
    // display_frame_init_64::vera_display_set_vstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [751] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTART = start
    // [752] *VERA_DC_VSTART = display_frame_init_64::vera_display_set_vstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstart1_start
    sta VERA_DC_VSTART
    // display_frame_init_64::vera_display_set_vstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [753] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTOP = stop
    // [754] *VERA_DC_VSTOP = display_frame_init_64::vera_display_set_vstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstop1_stop
    sta VERA_DC_VSTOP
    // display_frame_init_64::@1
    // cx16_k_screen_set_charset(3, (char *)0)
    // [755] display_frame_init_64::cx16_k_screen_set_charset1_charset = 3 -- vbum1=vbuc1 
    lda #3
    sta cx16_k_screen_set_charset1_charset
    // [756] display_frame_init_64::cx16_k_screen_set_charset1_offset = (char *) 0 -- pbum1=pbuc1 
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
    // [758] return 
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
    // [760] call textcolor
    // [700] phi from display_frame_draw to textcolor [phi:display_frame_draw->textcolor]
    // [700] phi textcolor::color#18 = LIGHT_BLUE [phi:display_frame_draw->textcolor#0] -- vbuxx=vbuc1 
    ldx #LIGHT_BLUE
    jsr textcolor
    // [761] phi from display_frame_draw to display_frame_draw::@1 [phi:display_frame_draw->display_frame_draw::@1]
    // display_frame_draw::@1
    // bgcolor(BLUE)
    // [762] call bgcolor
    // [705] phi from display_frame_draw::@1 to bgcolor [phi:display_frame_draw::@1->bgcolor]
    // [705] phi bgcolor::color#14 = BLUE [phi:display_frame_draw::@1->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // [763] phi from display_frame_draw::@1 to display_frame_draw::@2 [phi:display_frame_draw::@1->display_frame_draw::@2]
    // display_frame_draw::@2
    // clrscr()
    // [764] call clrscr
    jsr clrscr
    // [765] phi from display_frame_draw::@2 to display_frame_draw::@3 [phi:display_frame_draw::@2->display_frame_draw::@3]
    // display_frame_draw::@3
    // display_frame(0, 0, 67, 14)
    // [766] call display_frame
    // [1839] phi from display_frame_draw::@3 to display_frame [phi:display_frame_draw::@3->display_frame]
    // [1839] phi display_frame::y#0 = 0 [phi:display_frame_draw::@3->display_frame#0] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.y
    // [1839] phi display_frame::y1#16 = $e [phi:display_frame_draw::@3->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1839] phi display_frame::x#0 = 0 [phi:display_frame_draw::@3->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1839] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@3->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [767] phi from display_frame_draw::@3 to display_frame_draw::@4 [phi:display_frame_draw::@3->display_frame_draw::@4]
    // display_frame_draw::@4
    // display_frame(0, 0, 67, 2)
    // [768] call display_frame
    // [1839] phi from display_frame_draw::@4 to display_frame [phi:display_frame_draw::@4->display_frame]
    // [1839] phi display_frame::y#0 = 0 [phi:display_frame_draw::@4->display_frame#0] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.y
    // [1839] phi display_frame::y1#16 = 2 [phi:display_frame_draw::@4->display_frame#1] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y1
    // [1839] phi display_frame::x#0 = 0 [phi:display_frame_draw::@4->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1839] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@4->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [769] phi from display_frame_draw::@4 to display_frame_draw::@5 [phi:display_frame_draw::@4->display_frame_draw::@5]
    // display_frame_draw::@5
    // display_frame(0, 2, 67, 14)
    // [770] call display_frame
    // [1839] phi from display_frame_draw::@5 to display_frame [phi:display_frame_draw::@5->display_frame]
    // [1839] phi display_frame::y#0 = 2 [phi:display_frame_draw::@5->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1839] phi display_frame::y1#16 = $e [phi:display_frame_draw::@5->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1839] phi display_frame::x#0 = 0 [phi:display_frame_draw::@5->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1839] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@5->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [771] phi from display_frame_draw::@5 to display_frame_draw::@6 [phi:display_frame_draw::@5->display_frame_draw::@6]
    // display_frame_draw::@6
    // display_frame(0, 2, 8, 14)
    // [772] call display_frame
  // Chipset areas
    // [1839] phi from display_frame_draw::@6 to display_frame [phi:display_frame_draw::@6->display_frame]
    // [1839] phi display_frame::y#0 = 2 [phi:display_frame_draw::@6->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1839] phi display_frame::y1#16 = $e [phi:display_frame_draw::@6->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1839] phi display_frame::x#0 = 0 [phi:display_frame_draw::@6->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1839] phi display_frame::x1#16 = 8 [phi:display_frame_draw::@6->display_frame#3] -- vbuz1=vbuc1 
    lda #8
    sta.z display_frame.x1
    jsr display_frame
    // [773] phi from display_frame_draw::@6 to display_frame_draw::@7 [phi:display_frame_draw::@6->display_frame_draw::@7]
    // display_frame_draw::@7
    // display_frame(8, 2, 19, 14)
    // [774] call display_frame
    // [1839] phi from display_frame_draw::@7 to display_frame [phi:display_frame_draw::@7->display_frame]
    // [1839] phi display_frame::y#0 = 2 [phi:display_frame_draw::@7->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1839] phi display_frame::y1#16 = $e [phi:display_frame_draw::@7->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1839] phi display_frame::x#0 = 8 [phi:display_frame_draw::@7->display_frame#2] -- vbuz1=vbuc1 
    lda #8
    sta.z display_frame.x
    // [1839] phi display_frame::x1#16 = $13 [phi:display_frame_draw::@7->display_frame#3] -- vbuz1=vbuc1 
    lda #$13
    sta.z display_frame.x1
    jsr display_frame
    // [775] phi from display_frame_draw::@7 to display_frame_draw::@8 [phi:display_frame_draw::@7->display_frame_draw::@8]
    // display_frame_draw::@8
    // display_frame(19, 2, 25, 14)
    // [776] call display_frame
    // [1839] phi from display_frame_draw::@8 to display_frame [phi:display_frame_draw::@8->display_frame]
    // [1839] phi display_frame::y#0 = 2 [phi:display_frame_draw::@8->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1839] phi display_frame::y1#16 = $e [phi:display_frame_draw::@8->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1839] phi display_frame::x#0 = $13 [phi:display_frame_draw::@8->display_frame#2] -- vbuz1=vbuc1 
    lda #$13
    sta.z display_frame.x
    // [1839] phi display_frame::x1#16 = $19 [phi:display_frame_draw::@8->display_frame#3] -- vbuz1=vbuc1 
    lda #$19
    sta.z display_frame.x1
    jsr display_frame
    // [777] phi from display_frame_draw::@8 to display_frame_draw::@9 [phi:display_frame_draw::@8->display_frame_draw::@9]
    // display_frame_draw::@9
    // display_frame(25, 2, 31, 14)
    // [778] call display_frame
    // [1839] phi from display_frame_draw::@9 to display_frame [phi:display_frame_draw::@9->display_frame]
    // [1839] phi display_frame::y#0 = 2 [phi:display_frame_draw::@9->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1839] phi display_frame::y1#16 = $e [phi:display_frame_draw::@9->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1839] phi display_frame::x#0 = $19 [phi:display_frame_draw::@9->display_frame#2] -- vbuz1=vbuc1 
    lda #$19
    sta.z display_frame.x
    // [1839] phi display_frame::x1#16 = $1f [phi:display_frame_draw::@9->display_frame#3] -- vbuz1=vbuc1 
    lda #$1f
    sta.z display_frame.x1
    jsr display_frame
    // [779] phi from display_frame_draw::@9 to display_frame_draw::@10 [phi:display_frame_draw::@9->display_frame_draw::@10]
    // display_frame_draw::@10
    // display_frame(31, 2, 37, 14)
    // [780] call display_frame
    // [1839] phi from display_frame_draw::@10 to display_frame [phi:display_frame_draw::@10->display_frame]
    // [1839] phi display_frame::y#0 = 2 [phi:display_frame_draw::@10->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1839] phi display_frame::y1#16 = $e [phi:display_frame_draw::@10->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1839] phi display_frame::x#0 = $1f [phi:display_frame_draw::@10->display_frame#2] -- vbuz1=vbuc1 
    lda #$1f
    sta.z display_frame.x
    // [1839] phi display_frame::x1#16 = $25 [phi:display_frame_draw::@10->display_frame#3] -- vbuz1=vbuc1 
    lda #$25
    sta.z display_frame.x1
    jsr display_frame
    // [781] phi from display_frame_draw::@10 to display_frame_draw::@11 [phi:display_frame_draw::@10->display_frame_draw::@11]
    // display_frame_draw::@11
    // display_frame(37, 2, 43, 14)
    // [782] call display_frame
    // [1839] phi from display_frame_draw::@11 to display_frame [phi:display_frame_draw::@11->display_frame]
    // [1839] phi display_frame::y#0 = 2 [phi:display_frame_draw::@11->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1839] phi display_frame::y1#16 = $e [phi:display_frame_draw::@11->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1839] phi display_frame::x#0 = $25 [phi:display_frame_draw::@11->display_frame#2] -- vbuz1=vbuc1 
    lda #$25
    sta.z display_frame.x
    // [1839] phi display_frame::x1#16 = $2b [phi:display_frame_draw::@11->display_frame#3] -- vbuz1=vbuc1 
    lda #$2b
    sta.z display_frame.x1
    jsr display_frame
    // [783] phi from display_frame_draw::@11 to display_frame_draw::@12 [phi:display_frame_draw::@11->display_frame_draw::@12]
    // display_frame_draw::@12
    // display_frame(43, 2, 49, 14)
    // [784] call display_frame
    // [1839] phi from display_frame_draw::@12 to display_frame [phi:display_frame_draw::@12->display_frame]
    // [1839] phi display_frame::y#0 = 2 [phi:display_frame_draw::@12->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1839] phi display_frame::y1#16 = $e [phi:display_frame_draw::@12->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1839] phi display_frame::x#0 = $2b [phi:display_frame_draw::@12->display_frame#2] -- vbuz1=vbuc1 
    lda #$2b
    sta.z display_frame.x
    // [1839] phi display_frame::x1#16 = $31 [phi:display_frame_draw::@12->display_frame#3] -- vbuz1=vbuc1 
    lda #$31
    sta.z display_frame.x1
    jsr display_frame
    // [785] phi from display_frame_draw::@12 to display_frame_draw::@13 [phi:display_frame_draw::@12->display_frame_draw::@13]
    // display_frame_draw::@13
    // display_frame(49, 2, 55, 14)
    // [786] call display_frame
    // [1839] phi from display_frame_draw::@13 to display_frame [phi:display_frame_draw::@13->display_frame]
    // [1839] phi display_frame::y#0 = 2 [phi:display_frame_draw::@13->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1839] phi display_frame::y1#16 = $e [phi:display_frame_draw::@13->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1839] phi display_frame::x#0 = $31 [phi:display_frame_draw::@13->display_frame#2] -- vbuz1=vbuc1 
    lda #$31
    sta.z display_frame.x
    // [1839] phi display_frame::x1#16 = $37 [phi:display_frame_draw::@13->display_frame#3] -- vbuz1=vbuc1 
    lda #$37
    sta.z display_frame.x1
    jsr display_frame
    // [787] phi from display_frame_draw::@13 to display_frame_draw::@14 [phi:display_frame_draw::@13->display_frame_draw::@14]
    // display_frame_draw::@14
    // display_frame(55, 2, 61, 14)
    // [788] call display_frame
    // [1839] phi from display_frame_draw::@14 to display_frame [phi:display_frame_draw::@14->display_frame]
    // [1839] phi display_frame::y#0 = 2 [phi:display_frame_draw::@14->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1839] phi display_frame::y1#16 = $e [phi:display_frame_draw::@14->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1839] phi display_frame::x#0 = $37 [phi:display_frame_draw::@14->display_frame#2] -- vbuz1=vbuc1 
    lda #$37
    sta.z display_frame.x
    // [1839] phi display_frame::x1#16 = $3d [phi:display_frame_draw::@14->display_frame#3] -- vbuz1=vbuc1 
    lda #$3d
    sta.z display_frame.x1
    jsr display_frame
    // [789] phi from display_frame_draw::@14 to display_frame_draw::@15 [phi:display_frame_draw::@14->display_frame_draw::@15]
    // display_frame_draw::@15
    // display_frame(61, 2, 67, 14)
    // [790] call display_frame
    // [1839] phi from display_frame_draw::@15 to display_frame [phi:display_frame_draw::@15->display_frame]
    // [1839] phi display_frame::y#0 = 2 [phi:display_frame_draw::@15->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1839] phi display_frame::y1#16 = $e [phi:display_frame_draw::@15->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1839] phi display_frame::x#0 = $3d [phi:display_frame_draw::@15->display_frame#2] -- vbuz1=vbuc1 
    lda #$3d
    sta.z display_frame.x
    // [1839] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@15->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [791] phi from display_frame_draw::@15 to display_frame_draw::@16 [phi:display_frame_draw::@15->display_frame_draw::@16]
    // display_frame_draw::@16
    // display_frame(0, 14, 67, PROGRESS_Y-5)
    // [792] call display_frame
  // Progress area
    // [1839] phi from display_frame_draw::@16 to display_frame [phi:display_frame_draw::@16->display_frame]
    // [1839] phi display_frame::y#0 = $e [phi:display_frame_draw::@16->display_frame#0] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y
    // [1839] phi display_frame::y1#16 = PROGRESS_Y-5 [phi:display_frame_draw::@16->display_frame#1] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-5
    sta.z display_frame.y1
    // [1839] phi display_frame::x#0 = 0 [phi:display_frame_draw::@16->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1839] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@16->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [793] phi from display_frame_draw::@16 to display_frame_draw::@17 [phi:display_frame_draw::@16->display_frame_draw::@17]
    // display_frame_draw::@17
    // display_frame(0, PROGRESS_Y-5, 67, PROGRESS_Y-2)
    // [794] call display_frame
    // [1839] phi from display_frame_draw::@17 to display_frame [phi:display_frame_draw::@17->display_frame]
    // [1839] phi display_frame::y#0 = PROGRESS_Y-5 [phi:display_frame_draw::@17->display_frame#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-5
    sta.z display_frame.y
    // [1839] phi display_frame::y1#16 = PROGRESS_Y-2 [phi:display_frame_draw::@17->display_frame#1] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-2
    sta.z display_frame.y1
    // [1839] phi display_frame::x#0 = 0 [phi:display_frame_draw::@17->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1839] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@17->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [795] phi from display_frame_draw::@17 to display_frame_draw::@18 [phi:display_frame_draw::@17->display_frame_draw::@18]
    // display_frame_draw::@18
    // display_frame(0, PROGRESS_Y-2, 67, 49)
    // [796] call display_frame
    // [1839] phi from display_frame_draw::@18 to display_frame [phi:display_frame_draw::@18->display_frame]
    // [1839] phi display_frame::y#0 = PROGRESS_Y-2 [phi:display_frame_draw::@18->display_frame#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-2
    sta.z display_frame.y
    // [1839] phi display_frame::y1#16 = $31 [phi:display_frame_draw::@18->display_frame#1] -- vbuz1=vbuc1 
    lda #$31
    sta.z display_frame.y1
    // [1839] phi display_frame::x#0 = 0 [phi:display_frame_draw::@18->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1839] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@18->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [797] phi from display_frame_draw::@18 to display_frame_draw::@19 [phi:display_frame_draw::@18->display_frame_draw::@19]
    // display_frame_draw::@19
    // textcolor(WHITE)
    // [798] call textcolor
    // [700] phi from display_frame_draw::@19 to textcolor [phi:display_frame_draw::@19->textcolor]
    // [700] phi textcolor::color#18 = WHITE [phi:display_frame_draw::@19->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // display_frame_draw::@return
    // }
    // [799] return 
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
    // [801] call gotoxy
    // [718] phi from display_frame_title to gotoxy [phi:display_frame_title->gotoxy]
    // [718] phi gotoxy::y#30 = 1 [phi:display_frame_title->gotoxy#0] -- vbuyy=vbuc1 
    ldy #1
    // [718] phi gotoxy::x#30 = 2 [phi:display_frame_title->gotoxy#1] -- vbuxx=vbuc1 
    ldx #2
    jsr gotoxy
    // [802] phi from display_frame_title to display_frame_title::@1 [phi:display_frame_title->display_frame_title::@1]
    // display_frame_title::@1
    // printf("%-65s", title_text)
    // [803] call printf_string
    // [1130] phi from display_frame_title::@1 to printf_string [phi:display_frame_title::@1->printf_string]
    // [1130] phi printf_string::putc#22 = &cputc [phi:display_frame_title::@1->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1130] phi printf_string::str#22 = main::title_text [phi:display_frame_title::@1->printf_string#1] -- pbuz1=pbuc1 
    lda #<main.title_text
    sta.z printf_string.str
    lda #>main.title_text
    sta.z printf_string.str+1
    // [1130] phi printf_string::format_justify_left#22 = 1 [phi:display_frame_title::@1->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1130] phi printf_string::format_min_length#22 = $41 [phi:display_frame_title::@1->printf_string#3] -- vbuz1=vbuc1 
    lda #$41
    sta.z printf_string.format_min_length
    jsr printf_string
    // display_frame_title::@return
    // }
    // [804] return 
    rts
}
  // cputsxy
// Move cursor and output a NUL-terminated string
// Same as "gotoxy (x, y); puts (s);"
// void cputsxy(__register(X) char x, __register(Y) char y, __zp($29) const char *s)
cputsxy: {
    .label s = $29
    // gotoxy(x, y)
    // [806] gotoxy::x#1 = cputsxy::x#4
    // [807] gotoxy::y#1 = cputsxy::y#4
    // [808] call gotoxy
    // [718] phi from cputsxy to gotoxy [phi:cputsxy->gotoxy]
    // [718] phi gotoxy::y#30 = gotoxy::y#1 [phi:cputsxy->gotoxy#0] -- register_copy 
    // [718] phi gotoxy::x#30 = gotoxy::x#1 [phi:cputsxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputsxy::@1
    // cputs(s)
    // [809] cputs::s#1 = cputsxy::s#4 -- pbuz1=pbuz2 
    lda.z s
    sta.z cputs.s
    lda.z s+1
    sta.z cputs.s+1
    // [810] call cputs
    // [1973] phi from cputsxy::@1 to cputs [phi:cputsxy::@1->cputs]
    jsr cputs
    // cputsxy::@return
    // }
    // [811] return 
    rts
}
  // display_action_progress
/**
 * @brief Print the progress at the action frame, which is the first line.
 * 
 * @param info_text The progress text to be displayed.
 */
// void display_action_progress(__zp($69) char *info_text)
display_action_progress: {
    .label x = $38
    .label y = $2e
    .label info_text = $69
    // unsigned char x = wherex()
    // [813] call wherex
    jsr wherex
    // [814] wherex::return#2 = wherex::return#0
    // display_action_progress::@1
    // [815] display_action_progress::x#0 = wherex::return#2 -- vbuz1=vbuaa 
    sta.z x
    // unsigned char y = wherey()
    // [816] call wherey
    jsr wherey
    // [817] wherey::return#2 = wherey::return#0
    // display_action_progress::@2
    // [818] display_action_progress::y#0 = wherey::return#2 -- vbuz1=vbuaa 
    sta.z y
    // gotoxy(2, PROGRESS_Y-4)
    // [819] call gotoxy
    // [718] phi from display_action_progress::@2 to gotoxy [phi:display_action_progress::@2->gotoxy]
    // [718] phi gotoxy::y#30 = PROGRESS_Y-4 [phi:display_action_progress::@2->gotoxy#0] -- vbuyy=vbuc1 
    ldy #PROGRESS_Y-4
    // [718] phi gotoxy::x#30 = 2 [phi:display_action_progress::@2->gotoxy#1] -- vbuxx=vbuc1 
    ldx #2
    jsr gotoxy
    // display_action_progress::@3
    // printf("%-65s", info_text)
    // [820] printf_string::str#1 = display_action_progress::info_text#15
    // [821] call printf_string
    // [1130] phi from display_action_progress::@3 to printf_string [phi:display_action_progress::@3->printf_string]
    // [1130] phi printf_string::putc#22 = &cputc [phi:display_action_progress::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1130] phi printf_string::str#22 = printf_string::str#1 [phi:display_action_progress::@3->printf_string#1] -- register_copy 
    // [1130] phi printf_string::format_justify_left#22 = 1 [phi:display_action_progress::@3->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1130] phi printf_string::format_min_length#22 = $41 [phi:display_action_progress::@3->printf_string#3] -- vbuz1=vbuc1 
    lda #$41
    sta.z printf_string.format_min_length
    jsr printf_string
    // display_action_progress::@4
    // gotoxy(x, y)
    // [822] gotoxy::x#10 = display_action_progress::x#0 -- vbuxx=vbuz1 
    ldx.z x
    // [823] gotoxy::y#10 = display_action_progress::y#0 -- vbuyy=vbuz1 
    ldy.z y
    // [824] call gotoxy
    // [718] phi from display_action_progress::@4 to gotoxy [phi:display_action_progress::@4->gotoxy]
    // [718] phi gotoxy::y#30 = gotoxy::y#10 [phi:display_action_progress::@4->gotoxy#0] -- register_copy 
    // [718] phi gotoxy::x#30 = gotoxy::x#10 [phi:display_action_progress::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_action_progress::@return
    // }
    // [825] return 
    rts
}
  // display_progress_clear
/**
 * @brief Clean the progress area for the flashing.
 */
display_progress_clear: {
    .const h = PROGRESS_Y+PROGRESS_H
    .label x = $cd
    .label i = $e8
    .label y = $f7
    // textcolor(WHITE)
    // [827] call textcolor
    // [700] phi from display_progress_clear to textcolor [phi:display_progress_clear->textcolor]
    // [700] phi textcolor::color#18 = WHITE [phi:display_progress_clear->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [828] phi from display_progress_clear to display_progress_clear::@5 [phi:display_progress_clear->display_progress_clear::@5]
    // display_progress_clear::@5
    // bgcolor(BLUE)
    // [829] call bgcolor
    // [705] phi from display_progress_clear::@5 to bgcolor [phi:display_progress_clear::@5->bgcolor]
    // [705] phi bgcolor::color#14 = BLUE [phi:display_progress_clear::@5->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // [830] phi from display_progress_clear::@5 to display_progress_clear::@1 [phi:display_progress_clear::@5->display_progress_clear::@1]
    // [830] phi display_progress_clear::y#2 = PROGRESS_Y [phi:display_progress_clear::@5->display_progress_clear::@1#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // display_progress_clear::@1
  __b1:
    // while (y < h)
    // [831] if(display_progress_clear::y#2<display_progress_clear::h) goto display_progress_clear::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y
    cmp #h
    bcc __b4
    // display_progress_clear::@return
    // }
    // [832] return 
    rts
    // [833] phi from display_progress_clear::@1 to display_progress_clear::@2 [phi:display_progress_clear::@1->display_progress_clear::@2]
  __b4:
    // [833] phi display_progress_clear::x#2 = PROGRESS_X [phi:display_progress_clear::@1->display_progress_clear::@2#0] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z x
    // [833] phi display_progress_clear::i#2 = 0 [phi:display_progress_clear::@1->display_progress_clear::@2#1] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // display_progress_clear::@2
  __b2:
    // for(unsigned char i = 0; i < w; i++)
    // [834] if(display_progress_clear::i#2<PROGRESS_W) goto display_progress_clear::@3 -- vbuz1_lt_vbuc1_then_la1 
    lda.z i
    cmp #PROGRESS_W
    bcc __b3
    // display_progress_clear::@4
    // y++;
    // [835] display_progress_clear::y#1 = ++ display_progress_clear::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [830] phi from display_progress_clear::@4 to display_progress_clear::@1 [phi:display_progress_clear::@4->display_progress_clear::@1]
    // [830] phi display_progress_clear::y#2 = display_progress_clear::y#1 [phi:display_progress_clear::@4->display_progress_clear::@1#0] -- register_copy 
    jmp __b1
    // display_progress_clear::@3
  __b3:
    // cputcxy(x, y, ' ')
    // [836] cputcxy::x#12 = display_progress_clear::x#2 -- vbuxx=vbuz1 
    ldx.z x
    // [837] cputcxy::y#12 = display_progress_clear::y#2 -- vbuyy=vbuz1 
    ldy.z y
    // [838] call cputcxy
    // [1986] phi from display_progress_clear::@3 to cputcxy [phi:display_progress_clear::@3->cputcxy]
    // [1986] phi cputcxy::c#15 = ' ' [phi:display_progress_clear::@3->cputcxy#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z cputcxy.c
    // [1986] phi cputcxy::y#15 = cputcxy::y#12 [phi:display_progress_clear::@3->cputcxy#1] -- register_copy 
    // [1986] phi cputcxy::x#15 = cputcxy::x#12 [phi:display_progress_clear::@3->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_progress_clear::@6
    // x++;
    // [839] display_progress_clear::x#1 = ++ display_progress_clear::x#2 -- vbuz1=_inc_vbuz1 
    inc.z x
    // for(unsigned char i = 0; i < w; i++)
    // [840] display_progress_clear::i#1 = ++ display_progress_clear::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [833] phi from display_progress_clear::@6 to display_progress_clear::@2 [phi:display_progress_clear::@6->display_progress_clear::@2]
    // [833] phi display_progress_clear::x#2 = display_progress_clear::x#1 [phi:display_progress_clear::@6->display_progress_clear::@2#0] -- register_copy 
    // [833] phi display_progress_clear::i#2 = display_progress_clear::i#1 [phi:display_progress_clear::@6->display_progress_clear::@2#1] -- register_copy 
    jmp __b2
}
  // display_chip_smc
display_chip_smc: {
    // display_smc_led(GREY)
    // [842] call display_smc_led
    // [1994] phi from display_chip_smc to display_smc_led [phi:display_chip_smc->display_smc_led]
    // [1994] phi display_smc_led::c#2 = GREY [phi:display_chip_smc->display_smc_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z display_smc_led.c
    jsr display_smc_led
    // [843] phi from display_chip_smc to display_chip_smc::@1 [phi:display_chip_smc->display_chip_smc::@1]
    // display_chip_smc::@1
    // display_print_chip(CHIP_SMC_X, CHIP_SMC_Y+2, CHIP_SMC_W, "SMC     ")
    // [844] call display_print_chip
    // [2000] phi from display_chip_smc::@1 to display_print_chip [phi:display_chip_smc::@1->display_print_chip]
    // [2000] phi display_print_chip::text#11 = display_chip_smc::text [phi:display_chip_smc::@1->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_print_chip.text_2
    lda #>text
    sta.z display_print_chip.text_2+1
    // [2000] phi display_print_chip::w#10 = 5 [phi:display_chip_smc::@1->display_print_chip#1] -- vbuz1=vbuc1 
    lda #5
    sta.z display_print_chip.w
    // [2000] phi display_print_chip::x#10 = 1 [phi:display_chip_smc::@1->display_print_chip#2] -- vbuz1=vbuc1 
    lda #1
    sta.z display_print_chip.x
    jsr display_print_chip
    // display_chip_smc::@return
    // }
    // [845] return 
    rts
  .segment Data
    text: .text "SMC     "
    .byte 0
}
.segment Code
  // display_chip_vera
display_chip_vera: {
    // display_vera_led(GREY)
    // [847] call display_vera_led
    // [2044] phi from display_chip_vera to display_vera_led [phi:display_chip_vera->display_vera_led]
    // [2044] phi display_vera_led::c#2 = GREY [phi:display_chip_vera->display_vera_led#0] -- vbum1=vbuc1 
    lda #GREY
    sta display_vera_led.c
    jsr display_vera_led
    // [848] phi from display_chip_vera to display_chip_vera::@1 [phi:display_chip_vera->display_chip_vera::@1]
    // display_chip_vera::@1
    // display_print_chip(CHIP_VERA_X, CHIP_VERA_Y+2, CHIP_VERA_W, "VERA     ")
    // [849] call display_print_chip
    // [2000] phi from display_chip_vera::@1 to display_print_chip [phi:display_chip_vera::@1->display_print_chip]
    // [2000] phi display_print_chip::text#11 = display_chip_vera::text [phi:display_chip_vera::@1->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_print_chip.text_2
    lda #>text
    sta.z display_print_chip.text_2+1
    // [2000] phi display_print_chip::w#10 = 8 [phi:display_chip_vera::@1->display_print_chip#1] -- vbuz1=vbuc1 
    lda #8
    sta.z display_print_chip.w
    // [2000] phi display_print_chip::x#10 = 9 [phi:display_chip_vera::@1->display_print_chip#2] -- vbuz1=vbuc1 
    lda #9
    sta.z display_print_chip.x
    jsr display_print_chip
    // display_chip_vera::@return
    // }
    // [850] return 
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
    .label r = $cf
    // [852] phi from display_chip_rom to display_chip_rom::@1 [phi:display_chip_rom->display_chip_rom::@1]
    // [852] phi display_chip_rom::r#2 = 0 [phi:display_chip_rom->display_chip_rom::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z r
    // display_chip_rom::@1
  __b1:
    // for (unsigned char r = 0; r < 8; r++)
    // [853] if(display_chip_rom::r#2<8) goto display_chip_rom::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z r
    cmp #8
    bcc __b2
    // display_chip_rom::@return
    // }
    // [854] return 
    rts
    // [855] phi from display_chip_rom::@1 to display_chip_rom::@2 [phi:display_chip_rom::@1->display_chip_rom::@2]
    // display_chip_rom::@2
  __b2:
    // strcpy(rom, "ROM  ")
    // [856] call strcpy
    // [950] phi from display_chip_rom::@2 to strcpy [phi:display_chip_rom::@2->strcpy]
    // [950] phi strcpy::dst#0 = display_chip_rom::rom [phi:display_chip_rom::@2->strcpy#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z strcpy.dst
    lda #>rom
    sta.z strcpy.dst+1
    // [950] phi strcpy::src#0 = display_chip_rom::source [phi:display_chip_rom::@2->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // display_chip_rom::@5
    // strcat(rom, rom_size_strings[r])
    // [857] display_chip_rom::$11 = display_chip_rom::r#2 << 1 -- vbum1=vbuz2_rol_1 
    lda.z r
    asl
    sta display_chip_rom__11
    // [858] strcat::source#0 = rom_size_strings[display_chip_rom::$11] -- pbuz1=qbuc1_derefidx_vbum2 
    tay
    lda rom_size_strings,y
    sta.z strcat.source
    lda rom_size_strings+1,y
    sta.z strcat.source+1
    // [859] call strcat
    // [2050] phi from display_chip_rom::@5 to strcat [phi:display_chip_rom::@5->strcat]
    jsr strcat
    // display_chip_rom::@6
    // if(r)
    // [860] if(0==display_chip_rom::r#2) goto display_chip_rom::@3 -- 0_eq_vbuz1_then_la1 
    lda.z r
    beq __b3
    // display_chip_rom::@4
    // r+'0'
    // [861] display_chip_rom::$4 = display_chip_rom::r#2 + '0' -- vbuaa=vbuz1_plus_vbuc1 
    lda #'0'
    clc
    adc.z r
    // *(rom+3) = r+'0'
    // [862] *(display_chip_rom::rom+3) = display_chip_rom::$4 -- _deref_pbuc1=vbuaa 
    sta rom+3
    // display_chip_rom::@3
  __b3:
    // display_rom_led(r, GREY)
    // [863] display_rom_led::chip#0 = display_chip_rom::r#2 -- vbuz1=vbuz2 
    lda.z r
    sta.z display_rom_led.chip
    // [864] call display_rom_led
    // [2062] phi from display_chip_rom::@3 to display_rom_led [phi:display_chip_rom::@3->display_rom_led]
    // [2062] phi display_rom_led::c#2 = GREY [phi:display_chip_rom::@3->display_rom_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z display_rom_led.c
    // [2062] phi display_rom_led::chip#2 = display_rom_led::chip#0 [phi:display_chip_rom::@3->display_rom_led#1] -- register_copy 
    jsr display_rom_led
    // display_chip_rom::@7
    // r*6
    // [865] display_chip_rom::$12 = display_chip_rom::$11 + display_chip_rom::r#2 -- vbuaa=vbum1_plus_vbuz2 
    lda display_chip_rom__11
    clc
    adc.z r
    // [866] display_chip_rom::$6 = display_chip_rom::$12 << 1 -- vbuaa=vbuaa_rol_1 
    asl
    // display_print_chip(CHIP_ROM_X+r*6, CHIP_ROM_Y+2, CHIP_ROM_W, rom)
    // [867] display_print_chip::x#2 = $14 + display_chip_rom::$6 -- vbuz1=vbuc1_plus_vbuaa 
    clc
    adc #$14
    sta.z display_print_chip.x
    // [868] call display_print_chip
    // [2000] phi from display_chip_rom::@7 to display_print_chip [phi:display_chip_rom::@7->display_print_chip]
    // [2000] phi display_print_chip::text#11 = display_chip_rom::rom [phi:display_chip_rom::@7->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z display_print_chip.text_2
    lda #>rom
    sta.z display_print_chip.text_2+1
    // [2000] phi display_print_chip::w#10 = 3 [phi:display_chip_rom::@7->display_print_chip#1] -- vbuz1=vbuc1 
    lda #3
    sta.z display_print_chip.w
    // [2000] phi display_print_chip::x#10 = display_print_chip::x#2 [phi:display_chip_rom::@7->display_print_chip#2] -- register_copy 
    jsr display_print_chip
    // display_chip_rom::@8
    // for (unsigned char r = 0; r < 8; r++)
    // [869] display_chip_rom::r#1 = ++ display_chip_rom::r#2 -- vbuz1=_inc_vbuz1 
    inc.z r
    // [852] phi from display_chip_rom::@8 to display_chip_rom::@1 [phi:display_chip_rom::@8->display_chip_rom::@1]
    // [852] phi display_chip_rom::r#2 = display_chip_rom::r#1 [phi:display_chip_rom::@8->display_chip_rom::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    rom: .fill $10, 0
    source: .text "ROM  "
    .byte 0
    display_chip_rom__11: .byte 0
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
// void display_info_smc(__zp($be) char info_status, __zp($4d) char *info_text)
display_info_smc: {
    .label info_status = $be
    .label info_text = $4d
    // unsigned char x = wherex()
    // [871] call wherex
    jsr wherex
    // [872] wherex::return#10 = wherex::return#0
    // display_info_smc::@3
    // [873] display_info_smc::x#0 = wherex::return#10 -- vbum1=vbuaa 
    sta x
    // unsigned char y = wherey()
    // [874] call wherey
    jsr wherey
    // [875] wherey::return#10 = wherey::return#0
    // display_info_smc::@4
    // [876] display_info_smc::y#0 = wherey::return#10 -- vbum1=vbuaa 
    sta y
    // status_smc = info_status
    // [877] status_smc#0 = display_info_smc::info_status#14 -- vbum1=vbuz2 
    lda.z info_status
    sta status_smc
    // display_smc_led(status_color[info_status])
    // [878] display_smc_led::c#1 = status_color[display_info_smc::info_status#14] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z display_smc_led.c
    // [879] call display_smc_led
    // [1994] phi from display_info_smc::@4 to display_smc_led [phi:display_info_smc::@4->display_smc_led]
    // [1994] phi display_smc_led::c#2 = display_smc_led::c#1 [phi:display_info_smc::@4->display_smc_led#0] -- register_copy 
    jsr display_smc_led
    // [880] phi from display_info_smc::@4 to display_info_smc::@5 [phi:display_info_smc::@4->display_info_smc::@5]
    // display_info_smc::@5
    // gotoxy(INFO_X, INFO_Y)
    // [881] call gotoxy
    // [718] phi from display_info_smc::@5 to gotoxy [phi:display_info_smc::@5->gotoxy]
    // [718] phi gotoxy::y#30 = $11 [phi:display_info_smc::@5->gotoxy#0] -- vbuyy=vbuc1 
    ldy #$11
    // [718] phi gotoxy::x#30 = 4 [phi:display_info_smc::@5->gotoxy#1] -- vbuxx=vbuc1 
    ldx #4
    jsr gotoxy
    // [882] phi from display_info_smc::@5 to display_info_smc::@6 [phi:display_info_smc::@5->display_info_smc::@6]
    // display_info_smc::@6
    // printf("SMC  %-9s ATTiny v%s ", status_text[info_status], smc_version_string)
    // [883] call printf_str
    // [987] phi from display_info_smc::@6 to printf_str [phi:display_info_smc::@6->printf_str]
    // [987] phi printf_str::putc#73 = &cputc [phi:display_info_smc::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = display_info_smc::s [phi:display_info_smc::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@7
    // printf("SMC  %-9s ATTiny v%s ", status_text[info_status], smc_version_string)
    // [884] display_info_smc::$8 = display_info_smc::info_status#14 << 1 -- vbuaa=vbuz1_rol_1 
    lda.z info_status
    asl
    // [885] printf_string::str#3 = status_text[display_info_smc::$8] -- pbuz1=qbuc1_derefidx_vbuaa 
    tay
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [886] call printf_string
    // [1130] phi from display_info_smc::@7 to printf_string [phi:display_info_smc::@7->printf_string]
    // [1130] phi printf_string::putc#22 = &cputc [phi:display_info_smc::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1130] phi printf_string::str#22 = printf_string::str#3 [phi:display_info_smc::@7->printf_string#1] -- register_copy 
    // [1130] phi printf_string::format_justify_left#22 = 1 [phi:display_info_smc::@7->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1130] phi printf_string::format_min_length#22 = 9 [phi:display_info_smc::@7->printf_string#3] -- vbuz1=vbuc1 
    lda #9
    sta.z printf_string.format_min_length
    jsr printf_string
    // [887] phi from display_info_smc::@7 to display_info_smc::@8 [phi:display_info_smc::@7->display_info_smc::@8]
    // display_info_smc::@8
    // printf("SMC  %-9s ATTiny v%s ", status_text[info_status], smc_version_string)
    // [888] call printf_str
    // [987] phi from display_info_smc::@8 to printf_str [phi:display_info_smc::@8->printf_str]
    // [987] phi printf_str::putc#73 = &cputc [phi:display_info_smc::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = display_info_smc::s1 [phi:display_info_smc::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // [889] phi from display_info_smc::@8 to display_info_smc::@9 [phi:display_info_smc::@8->display_info_smc::@9]
    // display_info_smc::@9
    // printf("SMC  %-9s ATTiny v%s ", status_text[info_status], smc_version_string)
    // [890] call printf_string
    // [1130] phi from display_info_smc::@9 to printf_string [phi:display_info_smc::@9->printf_string]
    // [1130] phi printf_string::putc#22 = &cputc [phi:display_info_smc::@9->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1130] phi printf_string::str#22 = smc_version_string [phi:display_info_smc::@9->printf_string#1] -- pbuz1=pbuc1 
    lda #<smc_version_string
    sta.z printf_string.str
    lda #>smc_version_string
    sta.z printf_string.str+1
    // [1130] phi printf_string::format_justify_left#22 = 0 [phi:display_info_smc::@9->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1130] phi printf_string::format_min_length#22 = 0 [phi:display_info_smc::@9->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [891] phi from display_info_smc::@9 to display_info_smc::@10 [phi:display_info_smc::@9->display_info_smc::@10]
    // display_info_smc::@10
    // printf("SMC  %-9s ATTiny v%s ", status_text[info_status], smc_version_string)
    // [892] call printf_str
    // [987] phi from display_info_smc::@10 to printf_str [phi:display_info_smc::@10->printf_str]
    // [987] phi printf_str::putc#73 = &cputc [phi:display_info_smc::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = s [phi:display_info_smc::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s
    sta.z printf_str.s
    lda #>@s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@11
    // if(info_text)
    // [893] if((char *)0==display_info_smc::info_text#14) goto display_info_smc::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // display_info_smc::@2
    // printf("%-25s", info_text)
    // [894] printf_string::str#5 = display_info_smc::info_text#14 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [895] call printf_string
    // [1130] phi from display_info_smc::@2 to printf_string [phi:display_info_smc::@2->printf_string]
    // [1130] phi printf_string::putc#22 = &cputc [phi:display_info_smc::@2->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1130] phi printf_string::str#22 = printf_string::str#5 [phi:display_info_smc::@2->printf_string#1] -- register_copy 
    // [1130] phi printf_string::format_justify_left#22 = 1 [phi:display_info_smc::@2->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1130] phi printf_string::format_min_length#22 = $19 [phi:display_info_smc::@2->printf_string#3] -- vbuz1=vbuc1 
    lda #$19
    sta.z printf_string.format_min_length
    jsr printf_string
    // display_info_smc::@1
  __b1:
    // gotoxy(x, y)
    // [896] gotoxy::x#14 = display_info_smc::x#0 -- vbuxx=vbum1 
    ldx x
    // [897] gotoxy::y#14 = display_info_smc::y#0 -- vbuyy=vbum1 
    ldy y
    // [898] call gotoxy
    // [718] phi from display_info_smc::@1 to gotoxy [phi:display_info_smc::@1->gotoxy]
    // [718] phi gotoxy::y#30 = gotoxy::y#14 [phi:display_info_smc::@1->gotoxy#0] -- register_copy 
    // [718] phi gotoxy::x#30 = gotoxy::x#14 [phi:display_info_smc::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_smc::@return
    // }
    // [899] return 
    rts
  .segment Data
    s: .text "SMC  "
    .byte 0
    s1: .text " ATTiny v"
    .byte 0
    x: .byte 0
    y: .byte 0
}
.segment Code
  // display_info_vera
/**
 * @brief Display the VERA status at the info frame.
 * 
 * @param info_status The STATUS_ 
 */
// void display_info_vera(__zp($ce) char info_status, __zp($30) char *info_text)
display_info_vera: {
    .label info_status = $ce
    .label info_text = $30
    // unsigned char x = wherex()
    // [901] call wherex
    jsr wherex
    // [902] wherex::return#11 = wherex::return#0
    // display_info_vera::@3
    // [903] display_info_vera::x#0 = wherex::return#11 -- vbum1=vbuaa 
    sta x
    // unsigned char y = wherey()
    // [904] call wherey
    jsr wherey
    // [905] wherey::return#11 = wherey::return#0
    // display_info_vera::@4
    // [906] display_info_vera::y#0 = wherey::return#11 -- vbum1=vbuaa 
    sta y
    // status_vera = info_status
    // [907] status_vera#0 = display_info_vera::info_status#3 -- vbum1=vbuz2 
    lda.z info_status
    sta status_vera
    // display_vera_led(status_color[info_status])
    // [908] display_vera_led::c#1 = status_color[display_info_vera::info_status#3] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta display_vera_led.c
    // [909] call display_vera_led
    // [2044] phi from display_info_vera::@4 to display_vera_led [phi:display_info_vera::@4->display_vera_led]
    // [2044] phi display_vera_led::c#2 = display_vera_led::c#1 [phi:display_info_vera::@4->display_vera_led#0] -- register_copy 
    jsr display_vera_led
    // [910] phi from display_info_vera::@4 to display_info_vera::@5 [phi:display_info_vera::@4->display_info_vera::@5]
    // display_info_vera::@5
    // gotoxy(INFO_X, INFO_Y+1)
    // [911] call gotoxy
    // [718] phi from display_info_vera::@5 to gotoxy [phi:display_info_vera::@5->gotoxy]
    // [718] phi gotoxy::y#30 = $11+1 [phi:display_info_vera::@5->gotoxy#0] -- vbuyy=vbuc1 
    ldy #$11+1
    // [718] phi gotoxy::x#30 = 4 [phi:display_info_vera::@5->gotoxy#1] -- vbuxx=vbuc1 
    ldx #4
    jsr gotoxy
    // [912] phi from display_info_vera::@5 to display_info_vera::@6 [phi:display_info_vera::@5->display_info_vera::@6]
    // display_info_vera::@6
    // printf("VERA %-9s FPGA                 ", status_text[info_status])
    // [913] call printf_str
    // [987] phi from display_info_vera::@6 to printf_str [phi:display_info_vera::@6->printf_str]
    // [987] phi printf_str::putc#73 = &cputc [phi:display_info_vera::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = display_info_vera::s [phi:display_info_vera::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@7
    // printf("VERA %-9s FPGA                 ", status_text[info_status])
    // [914] display_info_vera::$8 = display_info_vera::info_status#3 << 1 -- vbuaa=vbuz1_rol_1 
    lda.z info_status
    asl
    // [915] printf_string::str#6 = status_text[display_info_vera::$8] -- pbuz1=qbuc1_derefidx_vbuaa 
    tay
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [916] call printf_string
    // [1130] phi from display_info_vera::@7 to printf_string [phi:display_info_vera::@7->printf_string]
    // [1130] phi printf_string::putc#22 = &cputc [phi:display_info_vera::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1130] phi printf_string::str#22 = printf_string::str#6 [phi:display_info_vera::@7->printf_string#1] -- register_copy 
    // [1130] phi printf_string::format_justify_left#22 = 1 [phi:display_info_vera::@7->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1130] phi printf_string::format_min_length#22 = 9 [phi:display_info_vera::@7->printf_string#3] -- vbuz1=vbuc1 
    lda #9
    sta.z printf_string.format_min_length
    jsr printf_string
    // [917] phi from display_info_vera::@7 to display_info_vera::@8 [phi:display_info_vera::@7->display_info_vera::@8]
    // display_info_vera::@8
    // printf("VERA %-9s FPGA                 ", status_text[info_status])
    // [918] call printf_str
    // [987] phi from display_info_vera::@8 to printf_str [phi:display_info_vera::@8->printf_str]
    // [987] phi printf_str::putc#73 = &cputc [phi:display_info_vera::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = display_info_vera::s1 [phi:display_info_vera::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@9
    // if(info_text)
    // [919] if((char *)0==display_info_vera::info_text#10) goto display_info_vera::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // display_info_vera::@2
    // printf("%-25s", info_text)
    // [920] printf_string::str#7 = display_info_vera::info_text#10 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [921] call printf_string
    // [1130] phi from display_info_vera::@2 to printf_string [phi:display_info_vera::@2->printf_string]
    // [1130] phi printf_string::putc#22 = &cputc [phi:display_info_vera::@2->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1130] phi printf_string::str#22 = printf_string::str#7 [phi:display_info_vera::@2->printf_string#1] -- register_copy 
    // [1130] phi printf_string::format_justify_left#22 = 1 [phi:display_info_vera::@2->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1130] phi printf_string::format_min_length#22 = $19 [phi:display_info_vera::@2->printf_string#3] -- vbuz1=vbuc1 
    lda #$19
    sta.z printf_string.format_min_length
    jsr printf_string
    // display_info_vera::@1
  __b1:
    // gotoxy(x, y)
    // [922] gotoxy::x#16 = display_info_vera::x#0 -- vbuxx=vbum1 
    ldx x
    // [923] gotoxy::y#16 = display_info_vera::y#0 -- vbuyy=vbum1 
    ldy y
    // [924] call gotoxy
    // [718] phi from display_info_vera::@1 to gotoxy [phi:display_info_vera::@1->gotoxy]
    // [718] phi gotoxy::y#30 = gotoxy::y#16 [phi:display_info_vera::@1->gotoxy#0] -- register_copy 
    // [718] phi gotoxy::x#30 = gotoxy::x#16 [phi:display_info_vera::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_vera::@return
    // }
    // [925] return 
    rts
  .segment Data
    s: .text "VERA "
    .byte 0
    s1: .text " FPGA                 "
    .byte 0
    x: .byte 0
    y: .byte 0
}
.segment Code
  // display_progress_text
/**
 * @brief Print a block of text within the progress frame with a count of lines.
 * 
 * @param text A pointer to an array of strings to be displayed (char**).
 * @param lines The amount of lines to be displayed, starting from the top of the progress frame.
 */
// void display_progress_text(__zp($b7) char **text, __zp($bb) char lines)
display_progress_text: {
    .label l = $c0
    .label lines = $bb
    .label text = $b7
    // display_progress_clear()
    // [927] call display_progress_clear
    // [826] phi from display_progress_text to display_progress_clear [phi:display_progress_text->display_progress_clear]
    jsr display_progress_clear
    // [928] phi from display_progress_text to display_progress_text::@1 [phi:display_progress_text->display_progress_text::@1]
    // [928] phi display_progress_text::l#2 = 0 [phi:display_progress_text->display_progress_text::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z l
    // display_progress_text::@1
  __b1:
    // for(unsigned char l=0; l<lines; l++)
    // [929] if(display_progress_text::l#2<display_progress_text::lines#11) goto display_progress_text::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z l
    cmp.z lines
    bcc __b2
    // display_progress_text::@return
    // }
    // [930] return 
    rts
    // display_progress_text::@2
  __b2:
    // display_progress_line(l, text[l])
    // [931] display_progress_text::$3 = display_progress_text::l#2 << 1 -- vbuaa=vbuz1_rol_1 
    lda.z l
    asl
    // [932] display_progress_line::line#0 = display_progress_text::l#2 -- vbuxx=vbuz1 
    ldx.z l
    // [933] display_progress_line::text#0 = display_progress_text::text#10[display_progress_text::$3] -- pbuz1=qbuz2_derefidx_vbuaa 
    tay
    lda (text),y
    sta.z display_progress_line.text
    iny
    lda (text),y
    sta.z display_progress_line.text+1
    // [934] call display_progress_line
    jsr display_progress_line
    // display_progress_text::@3
    // for(unsigned char l=0; l<lines; l++)
    // [935] display_progress_text::l#1 = ++ display_progress_text::l#2 -- vbuz1=_inc_vbuz1 
    inc.z l
    // [928] phi from display_progress_text::@3 to display_progress_text::@1 [phi:display_progress_text::@3->display_progress_text::@1]
    // [928] phi display_progress_text::l#2 = display_progress_text::l#1 [phi:display_progress_text::@3->display_progress_text::@1#0] -- register_copy 
    jmp __b1
}
  // util_wait_space
util_wait_space: {
    // util_wait_key("Press [SPACE] to continue ...", " ")
    // [937] call util_wait_key
    // [1686] phi from util_wait_space to util_wait_key [phi:util_wait_space->util_wait_key]
    // [1686] phi util_wait_key::filter#12 = s [phi:util_wait_space->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z util_wait_key.filter
    lda #>s
    sta.z util_wait_key.filter+1
    // [1686] phi util_wait_key::info_text#2 = util_wait_space::info_text [phi:util_wait_space->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z util_wait_key.info_text
    lda #>info_text
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // util_wait_space::@return
    // }
    // [938] return 
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
    .label smc_bootloader_version = $29
    .label return = $29
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [939] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [940] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [941] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [942] cx16_k_i2c_read_byte::return#10 = cx16_k_i2c_read_byte::return#1
    // smc_detect::@3
    // smc_bootloader_version = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [943] smc_detect::smc_bootloader_version#1 = cx16_k_i2c_read_byte::return#10
    // BYTE1(smc_bootloader_version)
    // [944] smc_detect::$1 = byte1  smc_detect::smc_bootloader_version#1 -- vbuaa=_byte1_vwuz1 
    lda.z smc_bootloader_version+1
    // if(!BYTE1(smc_bootloader_version))
    // [945] if(0==smc_detect::$1) goto smc_detect::@1 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b1
    // [948] phi from smc_detect::@3 to smc_detect::@2 [phi:smc_detect::@3->smc_detect::@2]
    // [948] phi smc_detect::return#0 = $200 [phi:smc_detect::@3->smc_detect::@2#0] -- vwuz1=vwuc1 
    lda #<$200
    sta.z return
    lda #>$200
    sta.z return+1
    rts
    // smc_detect::@1
  __b1:
    // if(smc_bootloader_version == 0xFF)
    // [946] if(smc_detect::smc_bootloader_version#1!=$ff) goto smc_detect::@4 -- vwuz1_neq_vbuc1_then_la1 
    lda.z smc_bootloader_version+1
    bne __b2
    lda.z smc_bootloader_version
    cmp #$ff
    bne __b2
    // [948] phi from smc_detect::@1 to smc_detect::@2 [phi:smc_detect::@1->smc_detect::@2]
    // [948] phi smc_detect::return#0 = $100 [phi:smc_detect::@1->smc_detect::@2#0] -- vwuz1=vwuc1 
    lda #<$100
    sta.z return
    lda #>$100
    sta.z return+1
    rts
    // [947] phi from smc_detect::@1 to smc_detect::@4 [phi:smc_detect::@1->smc_detect::@4]
    // smc_detect::@4
    // [948] phi from smc_detect::@4 to smc_detect::@2 [phi:smc_detect::@4->smc_detect::@2]
    // [948] phi smc_detect::return#0 = smc_detect::smc_bootloader_version#1 [phi:smc_detect::@4->smc_detect::@2#0] -- register_copy 
    // smc_detect::@2
  __b2:
    // smc_detect::@return
    // }
    // [949] return 
    rts
}
  // strcpy
// Copies the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcpy(__zp($4d) char *destination, char *source)
strcpy: {
    .label src = $69
    .label dst = $4d
    .label destination = $4d
    // [951] phi from strcpy strcpy::@2 to strcpy::@1 [phi:strcpy/strcpy::@2->strcpy::@1]
    // [951] phi strcpy::dst#2 = strcpy::dst#0 [phi:strcpy/strcpy::@2->strcpy::@1#0] -- register_copy 
    // [951] phi strcpy::src#2 = strcpy::src#0 [phi:strcpy/strcpy::@2->strcpy::@1#1] -- register_copy 
    // strcpy::@1
  __b1:
    // while(*src)
    // [952] if(0!=*strcpy::src#2) goto strcpy::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcpy::@3
    // *dst = 0
    // [953] *strcpy::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcpy::@return
    // }
    // [954] return 
    rts
    // strcpy::@2
  __b2:
    // *dst++ = *src++
    // [955] *strcpy::dst#2 = *strcpy::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [956] strcpy::dst#1 = ++ strcpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [957] strcpy::src#1 = ++ strcpy::src#2 -- pbuz1=_inc_pbuz1 
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
// __zp($29) unsigned int cx16_k_i2c_read_byte(__mem() volatile char device, __mem() volatile char offset)
cx16_k_i2c_read_byte: {
    .label return = $29
    .label return_1 = $b7
    .label return_2 = $e2
    // unsigned int result
    // [958] cx16_k_i2c_read_byte::result = 0 -- vwum1=vwuc1 
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
    // [960] cx16_k_i2c_read_byte::return#0 = cx16_k_i2c_read_byte::result -- vwuz1=vwum2 
    sta.z return
    lda result+1
    sta.z return+1
    // cx16_k_i2c_read_byte::@return
    // }
    // [961] cx16_k_i2c_read_byte::return#1 = cx16_k_i2c_read_byte::return#0
    // [962] return 
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
// unsigned long smc_get_version_text(__zp($30) char *version_string, __register(Y) char release, __zp($f7) char major, __zp($e8) char minor)
smc_get_version_text: {
    .label major = $f7
    .label minor = $e8
    .label version_string = $30
    // sprintf(version_string, "%u.%u.%u ", release, major, minor)
    // [964] snprintf_init::s#0 = smc_get_version_text::version_string#2
    // [965] call snprintf_init
    // [982] phi from smc_get_version_text to snprintf_init [phi:smc_get_version_text->snprintf_init]
    // [982] phi snprintf_init::s#27 = snprintf_init::s#0 [phi:smc_get_version_text->snprintf_init#0] -- register_copy 
    jsr snprintf_init
    // smc_get_version_text::@1
    // sprintf(version_string, "%u.%u.%u ", release, major, minor)
    // [966] printf_uchar::uvalue#1 = smc_get_version_text::release#2 -- vbuxx=vbuyy 
    tya
    tax
    // [967] call printf_uchar
    // [1165] phi from smc_get_version_text::@1 to printf_uchar [phi:smc_get_version_text::@1->printf_uchar]
    // [1165] phi printf_uchar::format_zero_padding#14 = 0 [phi:smc_get_version_text::@1->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1165] phi printf_uchar::format_min_length#14 = 0 [phi:smc_get_version_text::@1->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1165] phi printf_uchar::putc#14 = &snputc [phi:smc_get_version_text::@1->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1165] phi printf_uchar::format_radix#14 = DECIMAL [phi:smc_get_version_text::@1->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [1165] phi printf_uchar::uvalue#14 = printf_uchar::uvalue#1 [phi:smc_get_version_text::@1->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [968] phi from smc_get_version_text::@1 to smc_get_version_text::@2 [phi:smc_get_version_text::@1->smc_get_version_text::@2]
    // smc_get_version_text::@2
    // sprintf(version_string, "%u.%u.%u ", release, major, minor)
    // [969] call printf_str
    // [987] phi from smc_get_version_text::@2 to printf_str [phi:smc_get_version_text::@2->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:smc_get_version_text::@2->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = smc_get_version_text::s [phi:smc_get_version_text::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_get_version_text::@3
    // sprintf(version_string, "%u.%u.%u ", release, major, minor)
    // [970] printf_uchar::uvalue#2 = smc_get_version_text::major#2 -- vbuxx=vbuz1 
    ldx.z major
    // [971] call printf_uchar
    // [1165] phi from smc_get_version_text::@3 to printf_uchar [phi:smc_get_version_text::@3->printf_uchar]
    // [1165] phi printf_uchar::format_zero_padding#14 = 0 [phi:smc_get_version_text::@3->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1165] phi printf_uchar::format_min_length#14 = 0 [phi:smc_get_version_text::@3->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1165] phi printf_uchar::putc#14 = &snputc [phi:smc_get_version_text::@3->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1165] phi printf_uchar::format_radix#14 = DECIMAL [phi:smc_get_version_text::@3->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [1165] phi printf_uchar::uvalue#14 = printf_uchar::uvalue#2 [phi:smc_get_version_text::@3->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [972] phi from smc_get_version_text::@3 to smc_get_version_text::@4 [phi:smc_get_version_text::@3->smc_get_version_text::@4]
    // smc_get_version_text::@4
    // sprintf(version_string, "%u.%u.%u ", release, major, minor)
    // [973] call printf_str
    // [987] phi from smc_get_version_text::@4 to printf_str [phi:smc_get_version_text::@4->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:smc_get_version_text::@4->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = smc_get_version_text::s [phi:smc_get_version_text::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_get_version_text::@5
    // sprintf(version_string, "%u.%u.%u ", release, major, minor)
    // [974] printf_uchar::uvalue#3 = smc_get_version_text::minor#2 -- vbuxx=vbuz1 
    ldx.z minor
    // [975] call printf_uchar
    // [1165] phi from smc_get_version_text::@5 to printf_uchar [phi:smc_get_version_text::@5->printf_uchar]
    // [1165] phi printf_uchar::format_zero_padding#14 = 0 [phi:smc_get_version_text::@5->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1165] phi printf_uchar::format_min_length#14 = 0 [phi:smc_get_version_text::@5->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1165] phi printf_uchar::putc#14 = &snputc [phi:smc_get_version_text::@5->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1165] phi printf_uchar::format_radix#14 = DECIMAL [phi:smc_get_version_text::@5->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [1165] phi printf_uchar::uvalue#14 = printf_uchar::uvalue#3 [phi:smc_get_version_text::@5->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [976] phi from smc_get_version_text::@5 to smc_get_version_text::@6 [phi:smc_get_version_text::@5->smc_get_version_text::@6]
    // smc_get_version_text::@6
    // sprintf(version_string, "%u.%u.%u ", release, major, minor)
    // [977] call printf_str
    // [987] phi from smc_get_version_text::@6 to printf_str [phi:smc_get_version_text::@6->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:smc_get_version_text::@6->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = s [phi:smc_get_version_text::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s
    sta.z printf_str.s
    lda #>@s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_get_version_text::@7
    // sprintf(version_string, "%u.%u.%u ", release, major, minor)
    // [978] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [979] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_get_version_text::@return
    // }
    // [981] return 
    rts
  .segment Data
    s: .text "."
    .byte 0
}
.segment Code
  // snprintf_init
/// Initialize the snprintf() state
// void snprintf_init(__zp($30) char *s, unsigned int n)
snprintf_init: {
    .label s = $30
    // __snprintf_capacity = n
    // [983] __snprintf_capacity = $ffff -- vwum1=vwuc1 
    lda #<$ffff
    sta __snprintf_capacity
    lda #>$ffff
    sta __snprintf_capacity+1
    // __snprintf_size = 0
    // [984] __snprintf_size = 0 -- vwum1=vbuc1 
    lda #<0
    sta __snprintf_size
    sta __snprintf_size+1
    // __snprintf_buffer = s
    // [985] __snprintf_buffer = snprintf_init::s#27 -- pbuz1=pbuz2 
    lda.z s
    sta.z __snprintf_buffer
    lda.z s+1
    sta.z __snprintf_buffer+1
    // snprintf_init::@return
    // }
    // [986] return 
    rts
}
  // printf_str
/// Print a NUL-terminated string
// void printf_str(__zp($b7) void (*putc)(char), __zp($69) const char *s)
printf_str: {
    .label s = $69
    .label putc = $b7
    // [988] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [988] phi printf_str::s#72 = printf_str::s#73 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [989] printf_str::c#1 = *printf_str::s#72 -- vbuaa=_deref_pbuz1 
    ldy #0
    lda (s),y
    // [990] printf_str::s#0 = ++ printf_str::s#72 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [991] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbuaa_then_la1 
    cmp #0
    bne __b2
    // printf_str::@return
    // }
    // [992] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [993] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbuaa 
    pha
    // [994] callexecute *printf_str::putc#73  -- call__deref_pprz1 
    jsr icall15
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
    // Outside Flow
  icall15:
    jmp (putc)
}
  // printf_uint
// Print an unsigned int using a specific format
// void printf_uint(void (*putc)(char), __zp($29) unsigned int uvalue, __zp($cd) char format_min_length, char format_justify_left, char format_sign_always, __zp($be) char format_zero_padding, char format_upper_case, __register(X) char format_radix)
printf_uint: {
    .label uvalue = $29
    .label format_min_length = $cd
    .label format_zero_padding = $be
    // printf_uint::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [997] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [998] utoa::value#1 = printf_uint::uvalue#15
    // [999] utoa::radix#0 = printf_uint::format_radix#15
    // [1000] call utoa
    // Format number into buffer
    jsr utoa
    // printf_uint::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1001] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [1002] printf_number_buffer::format_min_length#1 = printf_uint::format_min_length#15 -- vbuxx=vbuz1 
    ldx.z format_min_length
    // [1003] printf_number_buffer::format_zero_padding#1 = printf_uint::format_zero_padding#15
    // [1004] call printf_number_buffer
  // Print using format
    // [2107] phi from printf_uint::@2 to printf_number_buffer [phi:printf_uint::@2->printf_number_buffer]
    // [2107] phi printf_number_buffer::putc#10 = &snputc [phi:printf_uint::@2->printf_number_buffer#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_number_buffer.putc
    lda #>snputc
    sta.z printf_number_buffer.putc+1
    // [2107] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_uint::@2->printf_number_buffer#1] -- register_copy 
    // [2107] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#1 [phi:printf_uint::@2->printf_number_buffer#2] -- register_copy 
    // [2107] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#1 [phi:printf_uint::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uint::@return
    // }
    // [1005] return 
    rts
}
  // rom_detect
rom_detect: {
    .const bank_set_brom1_bank = 4
    .label rom_detect__24 = $dc
    .label rom_detect_address = $25
    // [1007] phi from rom_detect to rom_detect::@1 [phi:rom_detect->rom_detect::@1]
    // [1007] phi rom_detect::rom_chip#10 = 0 [phi:rom_detect->rom_detect::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // [1007] phi rom_detect::rom_detect_address#10 = 0 [phi:rom_detect->rom_detect::@1#1] -- vduz1=vduc1 
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
    // [1008] if(rom_detect::rom_detect_address#10<8*$80000) goto rom_detect::@2 -- vduz1_lt_vduc1_then_la1 
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
    // [1009] return 
    rts
    // rom_detect::@2
  __b2:
    // rom_manufacturer_ids[rom_chip] = 0
    // [1010] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = 0
    // [1011] rom_device_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta rom_device_ids,y
    // rom_unlock(rom_detect_address + 0x05555, 0x90)
    // [1012] rom_unlock::address#2 = rom_detect::rom_detect_address#10 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [1013] call rom_unlock
    // [2138] phi from rom_detect::@2 to rom_unlock [phi:rom_detect::@2->rom_unlock]
    // [2138] phi rom_unlock::unlock_code#5 = $90 [phi:rom_detect::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$90
    sta.z rom_unlock.unlock_code
    // [2138] phi rom_unlock::address#5 = rom_unlock::address#2 [phi:rom_detect::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_detect::@12
    // rom_read_byte(rom_detect_address)
    // [1014] rom_read_byte::address#0 = rom_detect::rom_detect_address#10 -- vduz1=vduz2 
    lda.z rom_detect_address
    sta.z rom_read_byte.address
    lda.z rom_detect_address+1
    sta.z rom_read_byte.address+1
    lda.z rom_detect_address+2
    sta.z rom_read_byte.address+2
    lda.z rom_detect_address+3
    sta.z rom_read_byte.address+3
    // [1015] call rom_read_byte
    // [2148] phi from rom_detect::@12 to rom_read_byte [phi:rom_detect::@12->rom_read_byte]
    // [2148] phi rom_read_byte::address#2 = rom_read_byte::address#0 [phi:rom_detect::@12->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(rom_detect_address)
    // [1016] rom_read_byte::return#2 = rom_read_byte::return#0
    // rom_detect::@13
    // [1017] rom_detect::$3 = rom_read_byte::return#2
    // rom_manufacturer_ids[rom_chip] = rom_read_byte(rom_detect_address)
    // [1018] rom_manufacturer_ids[rom_detect::rom_chip#10] = rom_detect::$3 -- pbuc1_derefidx_vbum1=vbuaa 
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_read_byte(rom_detect_address + 1)
    // [1019] rom_read_byte::address#1 = rom_detect::rom_detect_address#10 + 1 -- vduz1=vduz2_plus_1 
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
    // [1020] call rom_read_byte
    // [2148] phi from rom_detect::@13 to rom_read_byte [phi:rom_detect::@13->rom_read_byte]
    // [2148] phi rom_read_byte::address#2 = rom_read_byte::address#1 [phi:rom_detect::@13->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(rom_detect_address + 1)
    // [1021] rom_read_byte::return#3 = rom_read_byte::return#0
    // rom_detect::@14
    // [1022] rom_detect::$5 = rom_read_byte::return#3
    // rom_device_ids[rom_chip] = rom_read_byte(rom_detect_address + 1)
    // [1023] rom_device_ids[rom_detect::rom_chip#10] = rom_detect::$5 -- pbuc1_derefidx_vbum1=vbuaa 
    ldy rom_chip
    sta rom_device_ids,y
    // rom_unlock(rom_detect_address + 0x05555, 0xF0)
    // [1024] rom_unlock::address#3 = rom_detect::rom_detect_address#10 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [1025] call rom_unlock
    // [2138] phi from rom_detect::@14 to rom_unlock [phi:rom_detect::@14->rom_unlock]
    // [2138] phi rom_unlock::unlock_code#5 = $f0 [phi:rom_detect::@14->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$f0
    sta.z rom_unlock.unlock_code
    // [2138] phi rom_unlock::address#5 = rom_unlock::address#3 [phi:rom_detect::@14->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_detect::bank_set_brom1
    // BROM = bank
    // [1026] BROM = rom_detect::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // rom_detect::@11
    // rom_chip*3
    // [1027] rom_detect::$14 = rom_detect::rom_chip#10 << 1 -- vbum1=vbum2_rol_1 
    lda rom_chip
    asl
    sta rom_detect__14
    // [1028] rom_detect::$9 = rom_detect::$14 + rom_detect::rom_chip#10 -- vbuaa=vbum1_plus_vbum2 
    clc
    adc rom_chip
    // gotoxy(rom_chip*3+40, 1)
    // [1029] gotoxy::x#23 = rom_detect::$9 + $28 -- vbuxx=vbuaa_plus_vbuc1 
    clc
    adc #$28
    tax
    // [1030] call gotoxy
    // [718] phi from rom_detect::@11 to gotoxy [phi:rom_detect::@11->gotoxy]
    // [718] phi gotoxy::y#30 = 1 [phi:rom_detect::@11->gotoxy#0] -- vbuyy=vbuc1 
    ldy #1
    // [718] phi gotoxy::x#30 = gotoxy::x#23 [phi:rom_detect::@11->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_detect::@15
    // printf("%02x", rom_device_ids[rom_chip])
    // [1031] printf_uchar::uvalue#8 = rom_device_ids[rom_detect::rom_chip#10] -- vbuxx=pbuc1_derefidx_vbum1 
    ldy rom_chip
    ldx rom_device_ids,y
    // [1032] call printf_uchar
    // [1165] phi from rom_detect::@15 to printf_uchar [phi:rom_detect::@15->printf_uchar]
    // [1165] phi printf_uchar::format_zero_padding#14 = 1 [phi:rom_detect::@15->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1165] phi printf_uchar::format_min_length#14 = 2 [phi:rom_detect::@15->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [1165] phi printf_uchar::putc#14 = &cputc [phi:rom_detect::@15->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1165] phi printf_uchar::format_radix#14 = HEXADECIMAL [phi:rom_detect::@15->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #HEXADECIMAL
    // [1165] phi printf_uchar::uvalue#14 = printf_uchar::uvalue#8 [phi:rom_detect::@15->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // rom_detect::@16
    // case SST39SF010A:
    //             rom_device_names[rom_chip] = "f010a";
    //             rom_size_strings[rom_chip] = "128";
    //             rom_sizes[rom_chip] = 128 * 1024;
    //             break;
    // [1033] if(rom_device_ids[rom_detect::rom_chip#10]==$b5) goto rom_detect::@3 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
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
    // [1034] if(rom_device_ids[rom_detect::rom_chip#10]==$b6) goto rom_detect::@4 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
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
    // [1035] if(rom_device_ids[rom_detect::rom_chip#10]==$b7) goto rom_detect::@5 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b7
    beq __b5
    // rom_detect::@6
    // rom_manufacturer_ids[rom_chip] = 0
    // [1036] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    sta rom_manufacturer_ids,y
    // rom_device_names[rom_chip] = "----"
    // [1037] rom_device_names[rom_detect::$14] = rom_detect::$31 -- qbuc1_derefidx_vbum1=pbuc2 
    ldy rom_detect__14
    lda #<rom_detect__31
    sta rom_device_names,y
    lda #>rom_detect__31
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "000"
    // [1038] rom_size_strings[rom_detect::$14] = rom_detect::$32 -- qbuc1_derefidx_vbum1=pbuc2 
    lda #<rom_detect__32
    sta rom_size_strings,y
    lda #>rom_detect__32
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 0
    // [1039] rom_detect::$24 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__24
    // [1040] rom_sizes[rom_detect::$24] = 0 -- pduc1_derefidx_vbuz1=vbuc2 
    tay
    lda #0
    sta rom_sizes,y
    sta rom_sizes+1,y
    sta rom_sizes+2,y
    sta rom_sizes+3,y
    // rom_device_ids[rom_chip] = UNKNOWN
    // [1041] rom_device_ids[rom_detect::rom_chip#10] = $55 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$55
    ldy rom_chip
    sta rom_device_ids,y
    // rom_detect::@7
  __b7:
    // rom_chip++;
    // [1042] rom_detect::rom_chip#1 = ++ rom_detect::rom_chip#10 -- vbum1=_inc_vbum1 
    inc rom_chip
    // rom_detect::@8
    // rom_detect_address += 0x80000
    // [1043] rom_detect::rom_detect_address#1 = rom_detect::rom_detect_address#10 + $80000 -- vduz1=vduz1_plus_vduc1 
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
    // [1007] phi from rom_detect::@8 to rom_detect::@1 [phi:rom_detect::@8->rom_detect::@1]
    // [1007] phi rom_detect::rom_chip#10 = rom_detect::rom_chip#1 [phi:rom_detect::@8->rom_detect::@1#0] -- register_copy 
    // [1007] phi rom_detect::rom_detect_address#10 = rom_detect::rom_detect_address#1 [phi:rom_detect::@8->rom_detect::@1#1] -- register_copy 
    jmp __b1
    // rom_detect::@5
  __b5:
    // rom_device_names[rom_chip] = "f040"
    // [1044] rom_device_names[rom_detect::$14] = rom_detect::$29 -- qbuc1_derefidx_vbum1=pbuc2 
    ldy rom_detect__14
    lda #<rom_detect__29
    sta rom_device_names,y
    lda #>rom_detect__29
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "512"
    // [1045] rom_size_strings[rom_detect::$14] = rom_detect::$30 -- qbuc1_derefidx_vbum1=pbuc2 
    lda #<rom_detect__30
    sta rom_size_strings,y
    lda #>rom_detect__30
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 512 * 1024
    // [1046] rom_detect::$21 = rom_detect::rom_chip#10 << 2 -- vbuaa=vbum1_rol_2 
    lda rom_chip
    asl
    asl
    // [1047] rom_sizes[rom_detect::$21] = (unsigned long)$200*$400 -- pduc1_derefidx_vbuaa=vduc2 
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
    // [1048] rom_device_names[rom_detect::$14] = rom_detect::$27 -- qbuc1_derefidx_vbum1=pbuc2 
    ldy rom_detect__14
    lda #<rom_detect__27
    sta rom_device_names,y
    lda #>rom_detect__27
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "256"
    // [1049] rom_size_strings[rom_detect::$14] = rom_detect::$28 -- qbuc1_derefidx_vbum1=pbuc2 
    lda #<rom_detect__28
    sta rom_size_strings,y
    lda #>rom_detect__28
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 256 * 1024
    // [1050] rom_detect::$18 = rom_detect::rom_chip#10 << 2 -- vbuaa=vbum1_rol_2 
    lda rom_chip
    asl
    asl
    // [1051] rom_sizes[rom_detect::$18] = (unsigned long)$100*$400 -- pduc1_derefidx_vbuaa=vduc2 
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
    // [1052] rom_device_names[rom_detect::$14] = rom_detect::$25 -- qbuc1_derefidx_vbum1=pbuc2 
    ldy rom_detect__14
    lda #<rom_detect__25
    sta rom_device_names,y
    lda #>rom_detect__25
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "128"
    // [1053] rom_size_strings[rom_detect::$14] = rom_detect::$26 -- qbuc1_derefidx_vbum1=pbuc2 
    lda #<rom_detect__26
    sta rom_size_strings,y
    lda #>rom_detect__26
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 128 * 1024
    // [1054] rom_detect::$15 = rom_detect::rom_chip#10 << 2 -- vbuaa=vbum1_rol_2 
    lda rom_chip
    asl
    asl
    // [1055] rom_sizes[rom_detect::$15] = (unsigned long)$80*$400 -- pduc1_derefidx_vbuaa=vduc2 
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
    rom_detect__14: .byte 0
    .label rom_chip = smc_flash.smc_package_committed
}
.segment Code
  // smc_read
/**
 * @brief Read the SMC.BIN file into RAM_BASE.
 * The maximum size of SMC.BIN data that should be in the file is 0x1E00.
 * 
 * @return unsigned int The amount of bytes read from SMC.BIN to be flashed.
 */
// __zp($3c) unsigned int smc_read(__mem() char display_progress)
smc_read: {
    .label fp = $4b
    .label return = $3c
    .label smc_file_read = $72
    .label y = $ec
    .label ram_ptr = $e2
    .label smc_file_size = $3c
    /// Holds the amount of bytes actually read in the memory to be flashed.
    .label progress_row_bytes = $c2
    // display_action_progress("Reading SMC.BIN ... (.) data, ( ) empty")
    // [1057] call display_action_progress
  // It is assume that one RAM bank is 0X2000 bytes.
    // [812] phi from smc_read to display_action_progress [phi:smc_read->display_action_progress]
    // [812] phi display_action_progress::info_text#15 = smc_read::info_text [phi:smc_read->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1058] phi from smc_read to smc_read::@9 [phi:smc_read->smc_read::@9]
    // smc_read::@9
    // textcolor(WHITE)
    // [1059] call textcolor
    // [700] phi from smc_read::@9 to textcolor [phi:smc_read::@9->textcolor]
    // [700] phi textcolor::color#18 = WHITE [phi:smc_read::@9->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [1060] phi from smc_read::@9 to smc_read::@10 [phi:smc_read::@9->smc_read::@10]
    // smc_read::@10
    // gotoxy(x, y)
    // [1061] call gotoxy
    // [718] phi from smc_read::@10 to gotoxy [phi:smc_read::@10->gotoxy]
    // [718] phi gotoxy::y#30 = PROGRESS_Y [phi:smc_read::@10->gotoxy#0] -- vbuyy=vbuc1 
    ldy #PROGRESS_Y
    // [718] phi gotoxy::x#30 = PROGRESS_X [phi:smc_read::@10->gotoxy#1] -- vbuxx=vbuc1 
    ldx #PROGRESS_X
    jsr gotoxy
    // [1062] phi from smc_read::@10 to smc_read::@11 [phi:smc_read::@10->smc_read::@11]
    // smc_read::@11
    // FILE *fp = fopen("SMC.BIN", "r")
    // [1063] call fopen
    // [2160] phi from smc_read::@11 to fopen [phi:smc_read::@11->fopen]
    // [2160] phi __errno#333 = __errno#35 [phi:smc_read::@11->fopen#0] -- register_copy 
    // [2160] phi fopen::pathtoken#0 = smc_read::path [phi:smc_read::@11->fopen#1] -- pbuz1=pbuc1 
    lda #<path
    sta.z fopen.pathtoken
    lda #>path
    sta.z fopen.pathtoken+1
    jsr fopen
    // FILE *fp = fopen("SMC.BIN", "r")
    // [1064] fopen::return#3 = fopen::return#2
    // smc_read::@12
    // [1065] smc_read::fp#0 = fopen::return#3 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [1066] if((struct $2 *)0==smc_read::fp#0) goto smc_read::@1 -- pssc1_eq_pssz1_then_la1 
    lda.z fp
    cmp #<0
    bne !+
    lda.z fp+1
    cmp #>0
    beq __b4
  !:
    // [1067] phi from smc_read::@12 to smc_read::@2 [phi:smc_read::@12->smc_read::@2]
    // [1067] phi smc_read::y#10 = PROGRESS_Y [phi:smc_read::@12->smc_read::@2#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // [1067] phi smc_read::progress_row_bytes#10 = 0 [phi:smc_read::@12->smc_read::@2#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z progress_row_bytes
    sta.z progress_row_bytes+1
    // [1067] phi smc_read::smc_file_size#11 = 0 [phi:smc_read::@12->smc_read::@2#2] -- vwuz1=vwuc1 
    sta.z smc_file_size
    sta.z smc_file_size+1
    // [1067] phi smc_read::ram_ptr#10 = (char *)$7800 [phi:smc_read::@12->smc_read::@2#3] -- pbuz1=pbuc1 
    lda #<$7800
    sta.z ram_ptr
    lda #>$7800
    sta.z ram_ptr+1
  // We read block_size bytes at a time, and each block_size bytes we plot a dot.
  // Every r bytes we move to the next line.
    // smc_read::@2
  __b2:
    // fgets(ram_ptr, SMC_PROGRESS_CELL, fp)
    // [1068] fgets::ptr#2 = smc_read::ram_ptr#10 -- pbuz1=pbuz2 
    lda.z ram_ptr
    sta.z fgets.ptr
    lda.z ram_ptr+1
    sta.z fgets.ptr+1
    // [1069] fgets::stream#0 = smc_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.stream
    lda.z fp+1
    sta.z fgets.stream+1
    // [1070] call fgets
    // [2241] phi from smc_read::@2 to fgets [phi:smc_read::@2->fgets]
    // [2241] phi fgets::ptr#12 = fgets::ptr#2 [phi:smc_read::@2->fgets#0] -- register_copy 
    // [2241] phi fgets::size#10 = SMC_PROGRESS_CELL [phi:smc_read::@2->fgets#1] -- vwuz1=vbuc1 
    lda #<SMC_PROGRESS_CELL
    sta.z fgets.size
    lda #>SMC_PROGRESS_CELL
    sta.z fgets.size+1
    // [2241] phi fgets::stream#2 = fgets::stream#0 [phi:smc_read::@2->fgets#2] -- register_copy 
    jsr fgets
    // fgets(ram_ptr, SMC_PROGRESS_CELL, fp)
    // [1071] fgets::return#5 = fgets::return#1
    // smc_read::@13
    // smc_file_read = fgets(ram_ptr, SMC_PROGRESS_CELL, fp)
    // [1072] smc_read::smc_file_read#1 = fgets::return#5
    // while (smc_file_read = fgets(ram_ptr, SMC_PROGRESS_CELL, fp))
    // [1073] if(0!=smc_read::smc_file_read#1) goto smc_read::@3 -- 0_neq_vwuz1_then_la1 
    lda.z smc_file_read
    ora.z smc_file_read+1
    bne __b3
    // smc_read::@4
    // fclose(fp)
    // [1074] fclose::stream#0 = smc_read::fp#0
    // [1075] call fclose
    // [2295] phi from smc_read::@4 to fclose [phi:smc_read::@4->fclose]
    // [2295] phi fclose::stream#2 = fclose::stream#0 [phi:smc_read::@4->fclose#0] -- register_copy 
    jsr fclose
    // [1076] phi from smc_read::@4 to smc_read::@1 [phi:smc_read::@4->smc_read::@1]
    // [1076] phi smc_read::return#0 = smc_read::smc_file_size#11 [phi:smc_read::@4->smc_read::@1#0] -- register_copy 
    rts
    // [1076] phi from smc_read::@12 to smc_read::@1 [phi:smc_read::@12->smc_read::@1]
  __b4:
    // [1076] phi smc_read::return#0 = 0 [phi:smc_read::@12->smc_read::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // smc_read::@1
    // smc_read::@return
    // }
    // [1077] return 
    rts
    // [1078] phi from smc_read::@13 to smc_read::@3 [phi:smc_read::@13->smc_read::@3]
    // smc_read::@3
  __b3:
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1079] call snprintf_init
    // [982] phi from smc_read::@3 to snprintf_init [phi:smc_read::@3->snprintf_init]
    // [982] phi snprintf_init::s#27 = info_text [phi:smc_read::@3->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1080] phi from smc_read::@3 to smc_read::@14 [phi:smc_read::@3->smc_read::@14]
    // smc_read::@14
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1081] call printf_str
    // [987] phi from smc_read::@14 to printf_str [phi:smc_read::@14->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:smc_read::@14->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = smc_read::s [phi:smc_read::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@15
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1082] printf_uint::uvalue#0 = smc_read::smc_file_read#1 -- vwuz1=vwuz2 
    lda.z smc_file_read
    sta.z printf_uint.uvalue
    lda.z smc_file_read+1
    sta.z printf_uint.uvalue+1
    // [1083] call printf_uint
    // [996] phi from smc_read::@15 to printf_uint [phi:smc_read::@15->printf_uint]
    // [996] phi printf_uint::format_zero_padding#15 = 1 [phi:smc_read::@15->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [996] phi printf_uint::format_min_length#15 = 5 [phi:smc_read::@15->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [996] phi printf_uint::format_radix#15 = HEXADECIMAL [phi:smc_read::@15->printf_uint#2] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [996] phi printf_uint::uvalue#15 = printf_uint::uvalue#0 [phi:smc_read::@15->printf_uint#3] -- register_copy 
    jsr printf_uint
    // [1084] phi from smc_read::@15 to smc_read::@16 [phi:smc_read::@15->smc_read::@16]
    // smc_read::@16
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1085] call printf_str
    // [987] phi from smc_read::@16 to printf_str [phi:smc_read::@16->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:smc_read::@16->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = s1 [phi:smc_read::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@17
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1086] printf_uint::uvalue#1 = smc_read::smc_file_size#11 -- vwuz1=vwuz2 
    lda.z smc_file_size
    sta.z printf_uint.uvalue
    lda.z smc_file_size+1
    sta.z printf_uint.uvalue+1
    // [1087] call printf_uint
    // [996] phi from smc_read::@17 to printf_uint [phi:smc_read::@17->printf_uint]
    // [996] phi printf_uint::format_zero_padding#15 = 1 [phi:smc_read::@17->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [996] phi printf_uint::format_min_length#15 = 5 [phi:smc_read::@17->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [996] phi printf_uint::format_radix#15 = HEXADECIMAL [phi:smc_read::@17->printf_uint#2] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [996] phi printf_uint::uvalue#15 = printf_uint::uvalue#1 [phi:smc_read::@17->printf_uint#3] -- register_copy 
    jsr printf_uint
    // [1088] phi from smc_read::@17 to smc_read::@18 [phi:smc_read::@17->smc_read::@18]
    // smc_read::@18
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1089] call printf_str
    // [987] phi from smc_read::@18 to printf_str [phi:smc_read::@18->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:smc_read::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = s2 [phi:smc_read::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // [1090] phi from smc_read::@18 to smc_read::@19 [phi:smc_read::@18->smc_read::@19]
    // smc_read::@19
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1091] call printf_uint
    // [996] phi from smc_read::@19 to printf_uint [phi:smc_read::@19->printf_uint]
    // [996] phi printf_uint::format_zero_padding#15 = 1 [phi:smc_read::@19->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [996] phi printf_uint::format_min_length#15 = 2 [phi:smc_read::@19->printf_uint#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uint.format_min_length
    // [996] phi printf_uint::format_radix#15 = HEXADECIMAL [phi:smc_read::@19->printf_uint#2] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [996] phi printf_uint::uvalue#15 = 0 [phi:smc_read::@19->printf_uint#3] -- vwuz1=vbuc1 
    lda #<0
    sta.z printf_uint.uvalue
    sta.z printf_uint.uvalue+1
    jsr printf_uint
    // [1092] phi from smc_read::@19 to smc_read::@20 [phi:smc_read::@19->smc_read::@20]
    // smc_read::@20
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1093] call printf_str
    // [987] phi from smc_read::@20 to printf_str [phi:smc_read::@20->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:smc_read::@20->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = s3 [phi:smc_read::@20->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@21
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1094] printf_uint::uvalue#3 = (unsigned int)smc_read::ram_ptr#10 -- vwuz1=vwuz2 
    lda.z ram_ptr
    sta.z printf_uint.uvalue
    lda.z ram_ptr+1
    sta.z printf_uint.uvalue+1
    // [1095] call printf_uint
    // [996] phi from smc_read::@21 to printf_uint [phi:smc_read::@21->printf_uint]
    // [996] phi printf_uint::format_zero_padding#15 = 1 [phi:smc_read::@21->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [996] phi printf_uint::format_min_length#15 = 4 [phi:smc_read::@21->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [996] phi printf_uint::format_radix#15 = HEXADECIMAL [phi:smc_read::@21->printf_uint#2] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [996] phi printf_uint::uvalue#15 = printf_uint::uvalue#3 [phi:smc_read::@21->printf_uint#3] -- register_copy 
    jsr printf_uint
    // [1096] phi from smc_read::@21 to smc_read::@22 [phi:smc_read::@21->smc_read::@22]
    // smc_read::@22
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1097] call printf_str
    // [987] phi from smc_read::@22 to printf_str [phi:smc_read::@22->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:smc_read::@22->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = s4 [phi:smc_read::@22->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@23
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [1098] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1099] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1101] call display_action_text
    // [1176] phi from smc_read::@23 to display_action_text [phi:smc_read::@23->display_action_text]
    // [1176] phi display_action_text::info_text#19 = info_text [phi:smc_read::@23->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_read::@24
    // if (progress_row_bytes == SMC_PROGRESS_ROW)
    // [1102] if(smc_read::progress_row_bytes#10!=SMC_PROGRESS_ROW) goto smc_read::@5 -- vwuz1_neq_vwuc1_then_la1 
    lda.z progress_row_bytes+1
    cmp #>SMC_PROGRESS_ROW
    bne __b5
    lda.z progress_row_bytes
    cmp #<SMC_PROGRESS_ROW
    bne __b5
    // smc_read::@7
    // gotoxy(x, ++y);
    // [1103] smc_read::y#1 = ++ smc_read::y#10 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [1104] gotoxy::y#20 = smc_read::y#1 -- vbuyy=vbuz1 
    ldy.z y
    // [1105] call gotoxy
    // [718] phi from smc_read::@7 to gotoxy [phi:smc_read::@7->gotoxy]
    // [718] phi gotoxy::y#30 = gotoxy::y#20 [phi:smc_read::@7->gotoxy#0] -- register_copy 
    // [718] phi gotoxy::x#30 = PROGRESS_X [phi:smc_read::@7->gotoxy#1] -- vbuxx=vbuc1 
    ldx #PROGRESS_X
    jsr gotoxy
    // [1106] phi from smc_read::@7 to smc_read::@5 [phi:smc_read::@7->smc_read::@5]
    // [1106] phi smc_read::y#20 = smc_read::y#1 [phi:smc_read::@7->smc_read::@5#0] -- register_copy 
    // [1106] phi smc_read::progress_row_bytes#4 = 0 [phi:smc_read::@7->smc_read::@5#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z progress_row_bytes
    sta.z progress_row_bytes+1
    // [1106] phi from smc_read::@24 to smc_read::@5 [phi:smc_read::@24->smc_read::@5]
    // [1106] phi smc_read::y#20 = smc_read::y#10 [phi:smc_read::@24->smc_read::@5#0] -- register_copy 
    // [1106] phi smc_read::progress_row_bytes#4 = smc_read::progress_row_bytes#10 [phi:smc_read::@24->smc_read::@5#1] -- register_copy 
    // smc_read::@5
  __b5:
    // if(display_progress)
    // [1107] if(0==smc_read::display_progress#19) goto smc_read::@6 -- 0_eq_vbum1_then_la1 
    lda display_progress
    beq __b6
    // smc_read::@8
    // cputc('.')
    // [1108] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [1109] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_read::@6
  __b6:
    // ram_ptr += smc_file_read
    // [1111] smc_read::ram_ptr#1 = smc_read::ram_ptr#10 + smc_read::smc_file_read#1 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z ram_ptr
    adc.z smc_file_read
    sta.z ram_ptr
    lda.z ram_ptr+1
    adc.z smc_file_read+1
    sta.z ram_ptr+1
    // smc_file_size += smc_file_read
    // [1112] smc_read::smc_file_size#1 = smc_read::smc_file_size#11 + smc_read::smc_file_read#1 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z smc_file_size
    adc.z smc_file_read
    sta.z smc_file_size
    lda.z smc_file_size+1
    adc.z smc_file_read+1
    sta.z smc_file_size+1
    // progress_row_bytes += smc_file_read
    // [1113] smc_read::progress_row_bytes#2 = smc_read::progress_row_bytes#4 + smc_read::smc_file_read#1 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z progress_row_bytes
    adc.z smc_file_read
    sta.z progress_row_bytes
    lda.z progress_row_bytes+1
    adc.z smc_file_read+1
    sta.z progress_row_bytes+1
    // [1067] phi from smc_read::@6 to smc_read::@2 [phi:smc_read::@6->smc_read::@2]
    // [1067] phi smc_read::y#10 = smc_read::y#20 [phi:smc_read::@6->smc_read::@2#0] -- register_copy 
    // [1067] phi smc_read::progress_row_bytes#10 = smc_read::progress_row_bytes#2 [phi:smc_read::@6->smc_read::@2#1] -- register_copy 
    // [1067] phi smc_read::smc_file_size#11 = smc_read::smc_file_size#1 [phi:smc_read::@6->smc_read::@2#2] -- register_copy 
    // [1067] phi smc_read::ram_ptr#10 = smc_read::ram_ptr#1 [phi:smc_read::@6->smc_read::@2#3] -- register_copy 
    jmp __b2
  .segment Data
    info_text: .text "Reading SMC.BIN ... (.) data, ( ) empty"
    .byte 0
    path: .text "SMC.BIN"
    .byte 0
    s: .text "Reading SMC.BIN:"
    .byte 0
    .label display_progress = smc_flash.smc_bytes_checksum
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
// __register(X) char rom_get_release(__register(X) char release)
rom_get_release: {
    // release & 0x80
    // [1115] rom_get_release::$0 = rom_get_release::release#4 & $80 -- vbuaa=vbuxx_band_vbuc1 
    txa
    and #$80
    // if(release & 0x80)
    // [1116] if(0==rom_get_release::$0) goto rom_get_release::@1 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b1
    // rom_get_release::@2
    // ~release
    // [1117] rom_get_release::$2 = ~ rom_get_release::release#4 -- vbuaa=_bnot_vbuxx 
    txa
    eor #$ff
    // release = ~release + 1
    // [1118] rom_get_release::release#0 = rom_get_release::$2 + 1 -- vbuxx=vbuaa_plus_1 
    tax
    inx
    // [1119] phi from rom_get_release rom_get_release::@2 to rom_get_release::@1 [phi:rom_get_release/rom_get_release::@2->rom_get_release::@1]
    // [1119] phi rom_get_release::return#0 = rom_get_release::release#4 [phi:rom_get_release/rom_get_release::@2->rom_get_release::@1#0] -- register_copy 
    // rom_get_release::@1
  __b1:
    // rom_get_release::@return
    // }
    // [1120] return 
    rts
}
  // rom_get_prefix
/**
 * @brief Determine the prefix of the ROM release number.
 * If the version is 0xFF or bit 7 of the version is set, then the release is a preview.
 * 
 * @param rom_chip The ROM chip to calculate the release.
 * @param release The release potentially taken 2's complement.
 * @return unsigned char 'r' if the release is official, 'p' if the release is inofficial of 0xFF.
 */
// __register(A) char rom_get_prefix(__register(A) char release)
rom_get_prefix: {
    // if(release == 0xFF)
    // [1122] if(rom_get_prefix::release#4!=$ff) goto rom_get_prefix::@1 -- vbuaa_neq_vbuc1_then_la1 
    cmp #$ff
    bne __b3
    // [1123] phi from rom_get_prefix to rom_get_prefix::@3 [phi:rom_get_prefix->rom_get_prefix::@3]
    // rom_get_prefix::@3
    // [1124] phi from rom_get_prefix::@3 to rom_get_prefix::@1 [phi:rom_get_prefix::@3->rom_get_prefix::@1]
    // [1124] phi rom_get_prefix::prefix#4 = 'p' [phi:rom_get_prefix::@3->rom_get_prefix::@1#0] -- vbuxx=vbuc1 
    ldx #'p'
    jmp __b1
    // [1124] phi from rom_get_prefix to rom_get_prefix::@1 [phi:rom_get_prefix->rom_get_prefix::@1]
  __b3:
    // [1124] phi rom_get_prefix::prefix#4 = 'r' [phi:rom_get_prefix->rom_get_prefix::@1#0] -- vbuxx=vbuc1 
    ldx #'r'
    // rom_get_prefix::@1
  __b1:
    // release & 0x80
    // [1125] rom_get_prefix::$2 = rom_get_prefix::release#4 & $80 -- vbuaa=vbuaa_band_vbuc1 
    and #$80
    // if(release & 0x80)
    // [1126] if(0==rom_get_prefix::$2) goto rom_get_prefix::@4 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b2
    // [1128] phi from rom_get_prefix::@1 to rom_get_prefix::@2 [phi:rom_get_prefix::@1->rom_get_prefix::@2]
    // [1128] phi rom_get_prefix::return#0 = 'p' [phi:rom_get_prefix::@1->rom_get_prefix::@2#0] -- vbuxx=vbuc1 
    ldx #'p'
    rts
    // [1127] phi from rom_get_prefix::@1 to rom_get_prefix::@4 [phi:rom_get_prefix::@1->rom_get_prefix::@4]
    // rom_get_prefix::@4
    // [1128] phi from rom_get_prefix::@4 to rom_get_prefix::@2 [phi:rom_get_prefix::@4->rom_get_prefix::@2]
    // [1128] phi rom_get_prefix::return#0 = rom_get_prefix::prefix#4 [phi:rom_get_prefix::@4->rom_get_prefix::@2#0] -- register_copy 
    // rom_get_prefix::@2
  __b2:
    // rom_get_prefix::@return
    // }
    // [1129] return 
    rts
}
  // printf_string
// Print a string value using a specific format
// Handles justification and min length 
// void printf_string(__zp($55) void (*putc)(char), __zp($69) char *str, __zp($bb) char format_min_length, __zp($c0) char format_justify_left)
printf_string: {
    .label printf_string__9 = $43
    .label padding = $bb
    .label str = $69
    .label str_1 = $f4
    .label format_min_length = $bb
    .label format_justify_left = $c0
    .label putc = $55
    // if(format.min_length)
    // [1131] if(0==printf_string::format_min_length#22) goto printf_string::@1 -- 0_eq_vbuz1_then_la1 
    lda.z format_min_length
    beq __b3
    // printf_string::@3
    // strlen(str)
    // [1132] strlen::str#3 = printf_string::str#22 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [1133] call strlen
    // [2323] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [2323] phi strlen::str#8 = strlen::str#3 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [1134] strlen::return#10 = strlen::len#2
    // printf_string::@6
    // [1135] printf_string::$9 = strlen::return#10
    // signed char len = (signed char)strlen(str)
    // [1136] printf_string::len#0 = (signed char)printf_string::$9 -- vbsaa=_sbyte_vwuz1 
    lda.z printf_string__9
    // padding = (signed char)format.min_length  - len
    // [1137] printf_string::padding#1 = (signed char)printf_string::format_min_length#22 - printf_string::len#0 -- vbsz1=vbsz1_minus_vbsaa 
    eor #$ff
    sec
    adc.z padding
    sta.z padding
    // if(padding<0)
    // [1138] if(printf_string::padding#1>=0) goto printf_string::@10 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1140] phi from printf_string printf_string::@6 to printf_string::@1 [phi:printf_string/printf_string::@6->printf_string::@1]
  __b3:
    // [1140] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@6->printf_string::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [1139] phi from printf_string::@6 to printf_string::@10 [phi:printf_string::@6->printf_string::@10]
    // printf_string::@10
    // [1140] phi from printf_string::@10 to printf_string::@1 [phi:printf_string::@10->printf_string::@1]
    // [1140] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@10->printf_string::@1#0] -- register_copy 
    // printf_string::@1
  __b1:
    // if(!format.justify_left && padding)
    // [1141] if(0!=printf_string::format_justify_left#22) goto printf_string::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_justify_left
    bne __b2
    // printf_string::@8
    // [1142] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b4
    jmp __b2
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [1143] printf_padding::putc#3 = printf_string::putc#22 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1144] printf_padding::length#3 = (char)printf_string::padding#3 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1145] call printf_padding
    // [2329] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    // [2329] phi printf_padding::putc#7 = printf_padding::putc#3 [phi:printf_string::@4->printf_padding#0] -- register_copy 
    // [2329] phi printf_padding::pad#7 = ' ' [phi:printf_string::@4->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [2329] phi printf_padding::length#6 = printf_padding::length#3 [phi:printf_string::@4->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [1146] printf_str::putc#1 = printf_string::putc#22 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_str.putc
    lda.z putc+1
    sta.z printf_str.putc+1
    // [1147] printf_str::s#2 = printf_string::str#22
    // [1148] call printf_str
    // [987] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [987] phi printf_str::putc#73 = printf_str::putc#1 [phi:printf_string::@2->printf_str#0] -- register_copy 
    // [987] phi printf_str::s#73 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@7
    // if(format.justify_left && padding)
    // [1149] if(0==printf_string::format_justify_left#22) goto printf_string::@return -- 0_eq_vbuz1_then_la1 
    lda.z format_justify_left
    beq __breturn
    // printf_string::@9
    // [1150] if(0!=printf_string::padding#3) goto printf_string::@5 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b5
    rts
    // printf_string::@5
  __b5:
    // printf_padding(putc, ' ',(char)padding)
    // [1151] printf_padding::putc#4 = printf_string::putc#22 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1152] printf_padding::length#4 = (char)printf_string::padding#3 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1153] call printf_padding
    // [2329] phi from printf_string::@5 to printf_padding [phi:printf_string::@5->printf_padding]
    // [2329] phi printf_padding::putc#7 = printf_padding::putc#4 [phi:printf_string::@5->printf_padding#0] -- register_copy 
    // [2329] phi printf_padding::pad#7 = ' ' [phi:printf_string::@5->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [2329] phi printf_padding::length#6 = printf_padding::length#4 [phi:printf_string::@5->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@return
  __breturn:
    // }
    // [1154] return 
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
    // [1156] BRAM = system_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // system_reset::bank_set_brom1
    // BROM = bank
    // [1157] BROM = system_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // system_reset::@2
    // asm
    // asm { jmp($FFFC)  }
    jmp ($fffc)
    // [1159] phi from system_reset::@1 system_reset::@2 to system_reset::@1 [phi:system_reset::@1/system_reset::@2->system_reset::@1]
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
    .label i = $e2
    // [1161] phi from wait_moment to wait_moment::@1 [phi:wait_moment->wait_moment::@1]
    // [1161] phi wait_moment::i#2 = $ffff [phi:wait_moment->wait_moment::@1#0] -- vwuz1=vwuc1 
    lda #<$ffff
    sta.z i
    lda #>$ffff
    sta.z i+1
    // wait_moment::@1
  __b1:
    // for(unsigned int i=65535; i>0; i--)
    // [1162] if(wait_moment::i#2>0) goto wait_moment::@2 -- vwuz1_gt_0_then_la1 
    lda.z i+1
    bne __b2
    lda.z i
    bne __b2
  !:
    // wait_moment::@return
    // }
    // [1163] return 
    rts
    // wait_moment::@2
  __b2:
    // for(unsigned int i=65535; i>0; i--)
    // [1164] wait_moment::i#1 = -- wait_moment::i#2 -- vwuz1=_dec_vwuz1 
    lda.z i
    bne !+
    dec.z i+1
  !:
    dec.z i
    // [1161] phi from wait_moment::@2 to wait_moment::@1 [phi:wait_moment::@2->wait_moment::@1]
    // [1161] phi wait_moment::i#2 = wait_moment::i#1 [phi:wait_moment::@2->wait_moment::@1#0] -- register_copy 
    jmp __b1
}
  // printf_uchar
// Print an unsigned char using a specific format
// void printf_uchar(__zp($b7) void (*putc)(char), __register(X) char uvalue, __zp($cf) char format_min_length, char format_justify_left, char format_sign_always, __zp($be) char format_zero_padding, char format_upper_case, __register(Y) char format_radix)
printf_uchar: {
    .label putc = $b7
    .label format_min_length = $cf
    .label format_zero_padding = $be
    // printf_uchar::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1166] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // uctoa(uvalue, printf_buffer.digits, format.radix)
    // [1167] uctoa::value#1 = printf_uchar::uvalue#14
    // [1168] uctoa::radix#0 = printf_uchar::format_radix#14
    // [1169] call uctoa
    // Format number into buffer
    jsr uctoa
    // printf_uchar::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1170] printf_number_buffer::putc#2 = printf_uchar::putc#14
    // [1171] printf_number_buffer::buffer_sign#2 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [1172] printf_number_buffer::format_min_length#2 = printf_uchar::format_min_length#14 -- vbuxx=vbuz1 
    ldx.z format_min_length
    // [1173] printf_number_buffer::format_zero_padding#2 = printf_uchar::format_zero_padding#14
    // [1174] call printf_number_buffer
  // Print using format
    // [2107] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [2107] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#2 [phi:printf_uchar::@2->printf_number_buffer#0] -- register_copy 
    // [2107] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#2 [phi:printf_uchar::@2->printf_number_buffer#1] -- register_copy 
    // [2107] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#2 [phi:printf_uchar::@2->printf_number_buffer#2] -- register_copy 
    // [2107] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#2 [phi:printf_uchar::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [1175] return 
    rts
}
  // display_action_text
/**
 * @brief Print an info line at the action frame, which is the second line.
 * 
 * @param info_text The info text to be displayed.
 */
// void display_action_text(__zp($55) char *info_text)
display_action_text: {
    .label info_text = $55
    .label x = $c6
    .label y = $c1
    // unsigned char x = wherex()
    // [1177] call wherex
    jsr wherex
    // [1178] wherex::return#3 = wherex::return#0
    // display_action_text::@1
    // [1179] display_action_text::x#0 = wherex::return#3 -- vbuz1=vbuaa 
    sta.z x
    // unsigned char y = wherey()
    // [1180] call wherey
    jsr wherey
    // [1181] wherey::return#3 = wherey::return#0
    // display_action_text::@2
    // [1182] display_action_text::y#0 = wherey::return#3 -- vbuz1=vbuaa 
    sta.z y
    // gotoxy(2, PROGRESS_Y-3)
    // [1183] call gotoxy
    // [718] phi from display_action_text::@2 to gotoxy [phi:display_action_text::@2->gotoxy]
    // [718] phi gotoxy::y#30 = PROGRESS_Y-3 [phi:display_action_text::@2->gotoxy#0] -- vbuyy=vbuc1 
    ldy #PROGRESS_Y-3
    // [718] phi gotoxy::x#30 = 2 [phi:display_action_text::@2->gotoxy#1] -- vbuxx=vbuc1 
    ldx #2
    jsr gotoxy
    // display_action_text::@3
    // printf("%-65s", info_text)
    // [1184] printf_string::str#2 = display_action_text::info_text#19 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1185] call printf_string
    // [1130] phi from display_action_text::@3 to printf_string [phi:display_action_text::@3->printf_string]
    // [1130] phi printf_string::putc#22 = &cputc [phi:display_action_text::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1130] phi printf_string::str#22 = printf_string::str#2 [phi:display_action_text::@3->printf_string#1] -- register_copy 
    // [1130] phi printf_string::format_justify_left#22 = 1 [phi:display_action_text::@3->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1130] phi printf_string::format_min_length#22 = $41 [phi:display_action_text::@3->printf_string#3] -- vbuz1=vbuc1 
    lda #$41
    sta.z printf_string.format_min_length
    jsr printf_string
    // display_action_text::@4
    // gotoxy(x, y)
    // [1186] gotoxy::x#12 = display_action_text::x#0 -- vbuxx=vbuz1 
    ldx.z x
    // [1187] gotoxy::y#12 = display_action_text::y#0 -- vbuyy=vbuz1 
    ldy.z y
    // [1188] call gotoxy
    // [718] phi from display_action_text::@4 to gotoxy [phi:display_action_text::@4->gotoxy]
    // [718] phi gotoxy::y#30 = gotoxy::y#12 [phi:display_action_text::@4->gotoxy#0] -- register_copy 
    // [718] phi gotoxy::x#30 = gotoxy::x#12 [phi:display_action_text::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_action_text::@return
    // }
    // [1189] return 
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
    // [1191] BRAM = smc_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // smc_reset::bank_set_brom1
    // BROM = bank
    // [1192] BROM = smc_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // smc_reset::@2
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [1193] smc_reset::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [1194] smc_reset::cx16_k_i2c_write_byte1_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte1_offset
    // [1195] smc_reset::cx16_k_i2c_write_byte1_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte1_value
    // smc_reset::cx16_k_i2c_write_byte1
    // unsigned char result
    // [1196] smc_reset::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
    sta cx16_k_i2c_write_byte1_result
    // asm
    // asm { ldxdevice ldyoffset ldavalue stzresult jsrCX16_I2C_WRITE_BYTE rolresult  }
    ldx cx16_k_i2c_write_byte1_device
    ldy cx16_k_i2c_write_byte1_offset
    lda cx16_k_i2c_write_byte1_value
    stz cx16_k_i2c_write_byte1_result
    jsr CX16_I2C_WRITE_BYTE
    rol cx16_k_i2c_write_byte1_result
    // [1198] phi from smc_reset::@1 smc_reset::cx16_k_i2c_write_byte1 to smc_reset::@1 [phi:smc_reset::@1/smc_reset::cx16_k_i2c_write_byte1->smc_reset::@1]
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
// void display_info_rom(__zp($6b) char rom_chip, __mem() char info_status, __zp($3e) char *info_text)
display_info_rom: {
    .label display_info_rom__13 = $b1
    .label info_text = $3e
    .label rom_chip = $6b
    // unsigned char x = wherex()
    // [1200] call wherex
    jsr wherex
    // [1201] wherex::return#12 = wherex::return#0
    // display_info_rom::@3
    // [1202] display_info_rom::x#0 = wherex::return#12 -- vbum1=vbuaa 
    sta x
    // unsigned char y = wherey()
    // [1203] call wherey
    jsr wherey
    // [1204] wherey::return#12 = wherey::return#0
    // display_info_rom::@4
    // [1205] display_info_rom::y#0 = wherey::return#12 -- vbum1=vbuaa 
    sta y
    // status_rom[rom_chip] = info_status
    // [1206] status_rom[display_info_rom::rom_chip#16] = display_info_rom::info_status#16 -- pbuc1_derefidx_vbuz1=vbum2 
    lda info_status
    ldy.z rom_chip
    sta status_rom,y
    // display_rom_led(rom_chip, status_color[info_status])
    // [1207] display_rom_led::chip#1 = display_info_rom::rom_chip#16 -- vbuz1=vbuz2 
    tya
    sta.z display_rom_led.chip
    // [1208] display_rom_led::c#1 = status_color[display_info_rom::info_status#16] -- vbuz1=pbuc1_derefidx_vbum2 
    ldy info_status
    lda status_color,y
    sta.z display_rom_led.c
    // [1209] call display_rom_led
    // [2062] phi from display_info_rom::@4 to display_rom_led [phi:display_info_rom::@4->display_rom_led]
    // [2062] phi display_rom_led::c#2 = display_rom_led::c#1 [phi:display_info_rom::@4->display_rom_led#0] -- register_copy 
    // [2062] phi display_rom_led::chip#2 = display_rom_led::chip#1 [phi:display_info_rom::@4->display_rom_led#1] -- register_copy 
    jsr display_rom_led
    // display_info_rom::@5
    // gotoxy(INFO_X, INFO_Y+rom_chip+2)
    // [1210] gotoxy::y#17 = display_info_rom::rom_chip#16 + $11+2 -- vbuyy=vbuz1_plus_vbuc1 
    lda #$11+2
    clc
    adc.z rom_chip
    tay
    // [1211] call gotoxy
    // [718] phi from display_info_rom::@5 to gotoxy [phi:display_info_rom::@5->gotoxy]
    // [718] phi gotoxy::y#30 = gotoxy::y#17 [phi:display_info_rom::@5->gotoxy#0] -- register_copy 
    // [718] phi gotoxy::x#30 = 4 [phi:display_info_rom::@5->gotoxy#1] -- vbuxx=vbuc1 
    ldx #4
    jsr gotoxy
    // display_info_rom::@6
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1212] display_info_rom::$13 = display_info_rom::rom_chip#16 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta.z display_info_rom__13
    // rom_chip*13
    // [1213] display_info_rom::$16 = display_info_rom::$13 + display_info_rom::rom_chip#16 -- vbuaa=vbuz1_plus_vbuz2 
    clc
    adc.z rom_chip
    // [1214] display_info_rom::$17 = display_info_rom::$16 << 2 -- vbuaa=vbuaa_rol_2 
    asl
    asl
    // [1215] display_info_rom::$6 = display_info_rom::$17 + display_info_rom::rom_chip#16 -- vbuaa=vbuaa_plus_vbuz1 
    clc
    adc.z rom_chip
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1216] printf_string::str#10 = rom_release_text + display_info_rom::$6 -- pbuz1=pbuc1_plus_vbuaa 
    clc
    adc #<rom_release_text
    sta.z printf_string.str_1
    lda #>rom_release_text
    adc #0
    sta.z printf_string.str_1+1
    // [1217] call printf_str
    // [987] phi from display_info_rom::@6 to printf_str [phi:display_info_rom::@6->printf_str]
    // [987] phi printf_str::putc#73 = &cputc [phi:display_info_rom::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = display_info_rom::s [phi:display_info_rom::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@7
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1218] printf_uchar::uvalue#0 = display_info_rom::rom_chip#16 -- vbuxx=vbuz1 
    ldx.z rom_chip
    // [1219] call printf_uchar
    // [1165] phi from display_info_rom::@7 to printf_uchar [phi:display_info_rom::@7->printf_uchar]
    // [1165] phi printf_uchar::format_zero_padding#14 = 0 [phi:display_info_rom::@7->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1165] phi printf_uchar::format_min_length#14 = 0 [phi:display_info_rom::@7->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1165] phi printf_uchar::putc#14 = &cputc [phi:display_info_rom::@7->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1165] phi printf_uchar::format_radix#14 = DECIMAL [phi:display_info_rom::@7->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [1165] phi printf_uchar::uvalue#14 = printf_uchar::uvalue#0 [phi:display_info_rom::@7->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1220] phi from display_info_rom::@7 to display_info_rom::@8 [phi:display_info_rom::@7->display_info_rom::@8]
    // display_info_rom::@8
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1221] call printf_str
    // [987] phi from display_info_rom::@8 to printf_str [phi:display_info_rom::@8->printf_str]
    // [987] phi printf_str::putc#73 = &cputc [phi:display_info_rom::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = s [phi:display_info_rom::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s
    sta.z printf_str.s
    lda #>@s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@9
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1222] display_info_rom::$12 = display_info_rom::info_status#16 << 1 -- vbuaa=vbum1_rol_1 
    lda info_status
    asl
    // [1223] printf_string::str#8 = status_text[display_info_rom::$12] -- pbuz1=qbuc1_derefidx_vbuaa 
    tay
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [1224] call printf_string
    // [1130] phi from display_info_rom::@9 to printf_string [phi:display_info_rom::@9->printf_string]
    // [1130] phi printf_string::putc#22 = &cputc [phi:display_info_rom::@9->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1130] phi printf_string::str#22 = printf_string::str#8 [phi:display_info_rom::@9->printf_string#1] -- register_copy 
    // [1130] phi printf_string::format_justify_left#22 = 1 [phi:display_info_rom::@9->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1130] phi printf_string::format_min_length#22 = 9 [phi:display_info_rom::@9->printf_string#3] -- vbuz1=vbuc1 
    lda #9
    sta.z printf_string.format_min_length
    jsr printf_string
    // [1225] phi from display_info_rom::@9 to display_info_rom::@10 [phi:display_info_rom::@9->display_info_rom::@10]
    // display_info_rom::@10
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1226] call printf_str
    // [987] phi from display_info_rom::@10 to printf_str [phi:display_info_rom::@10->printf_str]
    // [987] phi printf_str::putc#73 = &cputc [phi:display_info_rom::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = s [phi:display_info_rom::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s
    sta.z printf_str.s
    lda #>@s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@11
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1227] printf_string::str#9 = rom_device_names[display_info_rom::$13] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z display_info_rom__13
    lda rom_device_names,y
    sta.z printf_string.str
    lda rom_device_names+1,y
    sta.z printf_string.str+1
    // [1228] call printf_string
    // [1130] phi from display_info_rom::@11 to printf_string [phi:display_info_rom::@11->printf_string]
    // [1130] phi printf_string::putc#22 = &cputc [phi:display_info_rom::@11->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1130] phi printf_string::str#22 = printf_string::str#9 [phi:display_info_rom::@11->printf_string#1] -- register_copy 
    // [1130] phi printf_string::format_justify_left#22 = 1 [phi:display_info_rom::@11->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1130] phi printf_string::format_min_length#22 = 6 [phi:display_info_rom::@11->printf_string#3] -- vbuz1=vbuc1 
    lda #6
    sta.z printf_string.format_min_length
    jsr printf_string
    // [1229] phi from display_info_rom::@11 to display_info_rom::@12 [phi:display_info_rom::@11->display_info_rom::@12]
    // display_info_rom::@12
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1230] call printf_str
    // [987] phi from display_info_rom::@12 to printf_str [phi:display_info_rom::@12->printf_str]
    // [987] phi printf_str::putc#73 = &cputc [phi:display_info_rom::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = s [phi:display_info_rom::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s
    sta.z printf_str.s
    lda #>@s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@13
    // [1231] printf_string::str#33 = printf_string::str#10 -- pbuz1=pbuz2 
    lda.z printf_string.str_1
    sta.z printf_string.str
    lda.z printf_string.str_1+1
    sta.z printf_string.str+1
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1232] call printf_string
    // [1130] phi from display_info_rom::@13 to printf_string [phi:display_info_rom::@13->printf_string]
    // [1130] phi printf_string::putc#22 = &cputc [phi:display_info_rom::@13->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1130] phi printf_string::str#22 = printf_string::str#33 [phi:display_info_rom::@13->printf_string#1] -- register_copy 
    // [1130] phi printf_string::format_justify_left#22 = 1 [phi:display_info_rom::@13->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1130] phi printf_string::format_min_length#22 = $d [phi:display_info_rom::@13->printf_string#3] -- vbuz1=vbuc1 
    lda #$d
    sta.z printf_string.format_min_length
    jsr printf_string
    // [1233] phi from display_info_rom::@13 to display_info_rom::@14 [phi:display_info_rom::@13->display_info_rom::@14]
    // display_info_rom::@14
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1234] call printf_str
    // [987] phi from display_info_rom::@14 to printf_str [phi:display_info_rom::@14->printf_str]
    // [987] phi printf_str::putc#73 = &cputc [phi:display_info_rom::@14->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = s [phi:display_info_rom::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s
    sta.z printf_str.s
    lda #>@s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@15
    // if(info_text)
    // [1235] if((char *)0==display_info_rom::info_text#16) goto display_info_rom::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // display_info_rom::@2
    // printf("%-25s", info_text)
    // [1236] printf_string::str#11 = display_info_rom::info_text#16 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1237] call printf_string
    // [1130] phi from display_info_rom::@2 to printf_string [phi:display_info_rom::@2->printf_string]
    // [1130] phi printf_string::putc#22 = &cputc [phi:display_info_rom::@2->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1130] phi printf_string::str#22 = printf_string::str#11 [phi:display_info_rom::@2->printf_string#1] -- register_copy 
    // [1130] phi printf_string::format_justify_left#22 = 1 [phi:display_info_rom::@2->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1130] phi printf_string::format_min_length#22 = $19 [phi:display_info_rom::@2->printf_string#3] -- vbuz1=vbuc1 
    lda #$19
    sta.z printf_string.format_min_length
    jsr printf_string
    // display_info_rom::@1
  __b1:
    // gotoxy(x,y)
    // [1238] gotoxy::x#18 = display_info_rom::x#0 -- vbuxx=vbum1 
    ldx x
    // [1239] gotoxy::y#18 = display_info_rom::y#0 -- vbuyy=vbum1 
    ldy y
    // [1240] call gotoxy
    // [718] phi from display_info_rom::@1 to gotoxy [phi:display_info_rom::@1->gotoxy]
    // [718] phi gotoxy::y#30 = gotoxy::y#18 [phi:display_info_rom::@1->gotoxy#0] -- register_copy 
    // [718] phi gotoxy::x#30 = gotoxy::x#18 [phi:display_info_rom::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_rom::@return
    // }
    // [1241] return 
    rts
  .segment Data
    s: .text "ROM"
    .byte 0
    x: .byte 0
    y: .byte 0
    .label info_status = rom_get_version_text.release
}
.segment Code
  // rom_file
// __mem() char * rom_file(__register(A) char rom_chip)
rom_file: {
    // if(rom_chip)
    // [1243] if(0!=rom_file::rom_chip#2) goto rom_file::@1 -- 0_neq_vbuaa_then_la1 
    cmp #0
    bne __b1
    // [1246] phi from rom_file to rom_file::@return [phi:rom_file->rom_file::@return]
    // [1246] phi rom_file::return#2 = rom_file::file_rom_cx16 [phi:rom_file->rom_file::@return#0] -- pbum1=pbuc1 
    lda #<file_rom_cx16
    sta return
    lda #>file_rom_cx16
    sta return+1
    rts
    // rom_file::@1
  __b1:
    // '0'+rom_chip
    // [1244] rom_file::$0 = '0' + rom_file::rom_chip#2 -- vbuaa=vbuc1_plus_vbuaa 
    clc
    adc #'0'
    // file_rom_card[3] = '0'+rom_chip
    // [1245] *(rom_file::file_rom_card+3) = rom_file::$0 -- _deref_pbuc1=vbuaa 
    sta file_rom_card+3
    // [1246] phi from rom_file::@1 to rom_file::@return [phi:rom_file::@1->rom_file::@return]
    // [1246] phi rom_file::return#2 = rom_file::file_rom_card [phi:rom_file::@1->rom_file::@return#0] -- pbum1=pbuc1 
    lda #<file_rom_card
    sta return
    lda #>file_rom_card
    sta return+1
    // rom_file::@return
    // }
    // [1247] return 
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
// __zp($7c) unsigned long rom_read(__zp($c7) char display_progress, char rom_chip, __mem() char *file, char info_status, __zp($e9) char brom_bank_start, __zp($5b) unsigned long rom_size)
rom_read: {
    .const bank_set_brom1_bank = 0
    .label rom_read__11 = $d0
    .label rom_address = $45
    .label return = $7c
    .label rom_package_read = $f4
    .label brom_bank_start = $e9
    .label y = $f1
    .label ram_address = $ae
    .label rom_file_size = $7c
    .label rom_row_current = $67
    .label bram_bank = $e7
    .label rom_size = $5b
    .label display_progress = $c7
    // unsigned long rom_address = rom_address_from_bank(brom_bank_start)
    // [1249] rom_address_from_bank::rom_bank#0 = rom_read::brom_bank_start#22 -- vbuaa=vbuz1 
    lda.z brom_bank_start
    // [1250] call rom_address_from_bank
    // [2365] phi from rom_read to rom_address_from_bank [phi:rom_read->rom_address_from_bank]
    // [2365] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#0 [phi:rom_read->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(brom_bank_start)
    // [1251] rom_address_from_bank::return#2 = rom_address_from_bank::return#0
    // rom_read::@17
    // [1252] rom_read::rom_address#0 = rom_address_from_bank::return#2
    // rom_read::bank_set_bram1
    // BRAM = bank
    // [1253] BRAM = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z BRAM
    // rom_read::bank_set_brom1
    // BROM = bank
    // [1254] BROM = rom_read::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [1255] phi from rom_read::bank_set_brom1 to rom_read::@15 [phi:rom_read::bank_set_brom1->rom_read::@15]
    // rom_read::@15
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1256] call snprintf_init
    // [982] phi from rom_read::@15 to snprintf_init [phi:rom_read::@15->snprintf_init]
    // [982] phi snprintf_init::s#27 = info_text [phi:rom_read::@15->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1257] phi from rom_read::@15 to rom_read::@18 [phi:rom_read::@15->rom_read::@18]
    // rom_read::@18
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1258] call printf_str
    // [987] phi from rom_read::@18 to printf_str [phi:rom_read::@18->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:rom_read::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = rom_read::s [phi:rom_read::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@19
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1259] printf_string::str#13 = rom_read::file#11 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [1260] call printf_string
    // [1130] phi from rom_read::@19 to printf_string [phi:rom_read::@19->printf_string]
    // [1130] phi printf_string::putc#22 = &snputc [phi:rom_read::@19->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1130] phi printf_string::str#22 = printf_string::str#13 [phi:rom_read::@19->printf_string#1] -- register_copy 
    // [1130] phi printf_string::format_justify_left#22 = 0 [phi:rom_read::@19->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1130] phi printf_string::format_min_length#22 = 0 [phi:rom_read::@19->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [1261] phi from rom_read::@19 to rom_read::@20 [phi:rom_read::@19->rom_read::@20]
    // rom_read::@20
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1262] call printf_str
    // [987] phi from rom_read::@20 to printf_str [phi:rom_read::@20->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:rom_read::@20->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = rom_read::s1 [phi:rom_read::@20->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@21
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1263] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1264] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1266] call display_action_text
    // [1176] phi from rom_read::@21 to display_action_text [phi:rom_read::@21->display_action_text]
    // [1176] phi display_action_text::info_text#19 = info_text [phi:rom_read::@21->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // rom_read::@22
    // FILE *fp = fopen(file, "r")
    // [1267] fopen::path#3 = rom_read::file#11 -- pbuz1=pbum2 
    lda file
    sta.z fopen.path
    lda file+1
    sta.z fopen.path+1
    // [1268] call fopen
    // [2160] phi from rom_read::@22 to fopen [phi:rom_read::@22->fopen]
    // [2160] phi __errno#333 = __errno#106 [phi:rom_read::@22->fopen#0] -- register_copy 
    // [2160] phi fopen::pathtoken#0 = fopen::path#3 [phi:rom_read::@22->fopen#1] -- register_copy 
    jsr fopen
    // FILE *fp = fopen(file, "r")
    // [1269] fopen::return#4 = fopen::return#2
    // rom_read::@23
    // [1270] rom_read::fp#0 = fopen::return#4 -- pssm1=pssz2 
    lda.z fopen.return
    sta fp
    lda.z fopen.return+1
    sta fp+1
    // if (fp)
    // [1271] if((struct $2 *)0==rom_read::fp#0) goto rom_read::@1 -- pssc1_eq_pssm1_then_la1 
    lda fp
    cmp #<0
    bne !+
    lda fp+1
    cmp #>0
    beq __b2
  !:
    // [1272] phi from rom_read::@23 to rom_read::@2 [phi:rom_read::@23->rom_read::@2]
    // rom_read::@2
    // gotoxy(x, y)
    // [1273] call gotoxy
    // [718] phi from rom_read::@2 to gotoxy [phi:rom_read::@2->gotoxy]
    // [718] phi gotoxy::y#30 = PROGRESS_Y [phi:rom_read::@2->gotoxy#0] -- vbuyy=vbuc1 
    ldy #PROGRESS_Y
    // [718] phi gotoxy::x#30 = PROGRESS_X [phi:rom_read::@2->gotoxy#1] -- vbuxx=vbuc1 
    ldx #PROGRESS_X
    jsr gotoxy
    // [1274] phi from rom_read::@2 to rom_read::@3 [phi:rom_read::@2->rom_read::@3]
    // [1274] phi rom_read::y#11 = PROGRESS_Y [phi:rom_read::@2->rom_read::@3#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // [1274] phi rom_read::rom_row_current#10 = 0 [phi:rom_read::@2->rom_read::@3#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z rom_row_current
    sta.z rom_row_current+1
    // [1274] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#22 [phi:rom_read::@2->rom_read::@3#2] -- register_copy 
    // [1274] phi rom_read::rom_address#10 = rom_read::rom_address#0 [phi:rom_read::@2->rom_read::@3#3] -- register_copy 
    // [1274] phi rom_read::ram_address#10 = (char *)$7800 [phi:rom_read::@2->rom_read::@3#4] -- pbuz1=pbuc1 
    lda #<$7800
    sta.z ram_address
    lda #>$7800
    sta.z ram_address+1
    // [1274] phi rom_read::bram_bank#10 = 0 [phi:rom_read::@2->rom_read::@3#5] -- vbuz1=vbuc1 
    lda #0
    sta.z bram_bank
    // [1274] phi rom_read::rom_file_size#11 = 0 [phi:rom_read::@2->rom_read::@3#6] -- vduz1=vduc1 
    sta.z rom_file_size
    sta.z rom_file_size+1
    lda #<0>>$10
    sta.z rom_file_size+2
    lda #>0>>$10
    sta.z rom_file_size+3
    // rom_read::@3
  __b3:
    // while (rom_file_size < rom_size)
    // [1275] if(rom_read::rom_file_size#11<rom_read::rom_size#12) goto rom_read::@4 -- vduz1_lt_vduz2_then_la1 
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
    // [1276] fclose::stream#1 = rom_read::fp#0 -- pssz1=pssm2 
    lda fp
    sta.z fclose.stream
    lda fp+1
    sta.z fclose.stream+1
    // [1277] call fclose
    // [2295] phi from rom_read::@7 to fclose [phi:rom_read::@7->fclose]
    // [2295] phi fclose::stream#2 = fclose::stream#1 [phi:rom_read::@7->fclose#0] -- register_copy 
    jsr fclose
    // [1278] phi from rom_read::@7 to rom_read::@1 [phi:rom_read::@7->rom_read::@1]
    // [1278] phi rom_read::return#0 = rom_read::rom_file_size#11 [phi:rom_read::@7->rom_read::@1#0] -- register_copy 
    rts
    // [1278] phi from rom_read::@23 to rom_read::@1 [phi:rom_read::@23->rom_read::@1]
  __b2:
    // [1278] phi rom_read::return#0 = 0 [phi:rom_read::@23->rom_read::@1#0] -- vduz1=vduc1 
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
    // [1279] return 
    rts
    // [1280] phi from rom_read::@3 to rom_read::@4 [phi:rom_read::@3->rom_read::@4]
    // rom_read::@4
  __b4:
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1281] call snprintf_init
    // [982] phi from rom_read::@4 to snprintf_init [phi:rom_read::@4->snprintf_init]
    // [982] phi snprintf_init::s#27 = info_text [phi:rom_read::@4->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1282] phi from rom_read::@4 to rom_read::@24 [phi:rom_read::@4->rom_read::@24]
    // rom_read::@24
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1283] call printf_str
    // [987] phi from rom_read::@24 to printf_str [phi:rom_read::@24->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:rom_read::@24->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = s13 [phi:rom_read::@24->printf_str#1] -- pbuz1=pbuc1 
    lda #<s13
    sta.z printf_str.s
    lda #>s13
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@25
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1284] printf_string::str#14 = rom_read::file#11 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [1285] call printf_string
    // [1130] phi from rom_read::@25 to printf_string [phi:rom_read::@25->printf_string]
    // [1130] phi printf_string::putc#22 = &snputc [phi:rom_read::@25->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1130] phi printf_string::str#22 = printf_string::str#14 [phi:rom_read::@25->printf_string#1] -- register_copy 
    // [1130] phi printf_string::format_justify_left#22 = 0 [phi:rom_read::@25->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1130] phi printf_string::format_min_length#22 = 0 [phi:rom_read::@25->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [1286] phi from rom_read::@25 to rom_read::@26 [phi:rom_read::@25->rom_read::@26]
    // rom_read::@26
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1287] call printf_str
    // [987] phi from rom_read::@26 to printf_str [phi:rom_read::@26->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:rom_read::@26->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = s3 [phi:rom_read::@26->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@27
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1288] printf_ulong::uvalue#0 = rom_read::rom_file_size#11 -- vduz1=vduz2 
    lda.z rom_file_size
    sta.z printf_ulong.uvalue
    lda.z rom_file_size+1
    sta.z printf_ulong.uvalue+1
    lda.z rom_file_size+2
    sta.z printf_ulong.uvalue+2
    lda.z rom_file_size+3
    sta.z printf_ulong.uvalue+3
    // [1289] call printf_ulong
    // [1399] phi from rom_read::@27 to printf_ulong [phi:rom_read::@27->printf_ulong]
    // [1399] phi printf_ulong::format_zero_padding#10 = 1 [phi:rom_read::@27->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1399] phi printf_ulong::format_min_length#10 = 5 [phi:rom_read::@27->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1399] phi printf_ulong::format_radix#10 = HEXADECIMAL [phi:rom_read::@27->printf_ulong#2] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [1399] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#0 [phi:rom_read::@27->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1290] phi from rom_read::@27 to rom_read::@28 [phi:rom_read::@27->rom_read::@28]
    // rom_read::@28
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1291] call printf_str
    // [987] phi from rom_read::@28 to printf_str [phi:rom_read::@28->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:rom_read::@28->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = s1 [phi:rom_read::@28->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s1
    sta.z printf_str.s
    lda #>@s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@29
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1292] printf_ulong::uvalue#1 = rom_read::rom_size#12 -- vduz1=vduz2 
    lda.z rom_size
    sta.z printf_ulong.uvalue
    lda.z rom_size+1
    sta.z printf_ulong.uvalue+1
    lda.z rom_size+2
    sta.z printf_ulong.uvalue+2
    lda.z rom_size+3
    sta.z printf_ulong.uvalue+3
    // [1293] call printf_ulong
    // [1399] phi from rom_read::@29 to printf_ulong [phi:rom_read::@29->printf_ulong]
    // [1399] phi printf_ulong::format_zero_padding#10 = 1 [phi:rom_read::@29->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1399] phi printf_ulong::format_min_length#10 = 5 [phi:rom_read::@29->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1399] phi printf_ulong::format_radix#10 = HEXADECIMAL [phi:rom_read::@29->printf_ulong#2] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [1399] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#1 [phi:rom_read::@29->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1294] phi from rom_read::@29 to rom_read::@30 [phi:rom_read::@29->rom_read::@30]
    // rom_read::@30
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1295] call printf_str
    // [987] phi from rom_read::@30 to printf_str [phi:rom_read::@30->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:rom_read::@30->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = s2 [phi:rom_read::@30->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@31
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1296] printf_uchar::uvalue#9 = rom_read::bram_bank#10 -- vbuxx=vbuz1 
    ldx.z bram_bank
    // [1297] call printf_uchar
    // [1165] phi from rom_read::@31 to printf_uchar [phi:rom_read::@31->printf_uchar]
    // [1165] phi printf_uchar::format_zero_padding#14 = 1 [phi:rom_read::@31->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1165] phi printf_uchar::format_min_length#14 = 2 [phi:rom_read::@31->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [1165] phi printf_uchar::putc#14 = &snputc [phi:rom_read::@31->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1165] phi printf_uchar::format_radix#14 = HEXADECIMAL [phi:rom_read::@31->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #HEXADECIMAL
    // [1165] phi printf_uchar::uvalue#14 = printf_uchar::uvalue#9 [phi:rom_read::@31->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1298] phi from rom_read::@31 to rom_read::@32 [phi:rom_read::@31->rom_read::@32]
    // rom_read::@32
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1299] call printf_str
    // [987] phi from rom_read::@32 to printf_str [phi:rom_read::@32->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:rom_read::@32->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = s3 [phi:rom_read::@32->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@33
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1300] printf_uint::uvalue#9 = (unsigned int)rom_read::ram_address#10 -- vwuz1=vwuz2 
    lda.z ram_address
    sta.z printf_uint.uvalue
    lda.z ram_address+1
    sta.z printf_uint.uvalue+1
    // [1301] call printf_uint
    // [996] phi from rom_read::@33 to printf_uint [phi:rom_read::@33->printf_uint]
    // [996] phi printf_uint::format_zero_padding#15 = 1 [phi:rom_read::@33->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [996] phi printf_uint::format_min_length#15 = 4 [phi:rom_read::@33->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [996] phi printf_uint::format_radix#15 = HEXADECIMAL [phi:rom_read::@33->printf_uint#2] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [996] phi printf_uint::uvalue#15 = printf_uint::uvalue#9 [phi:rom_read::@33->printf_uint#3] -- register_copy 
    jsr printf_uint
    // [1302] phi from rom_read::@33 to rom_read::@34 [phi:rom_read::@33->rom_read::@34]
    // rom_read::@34
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1303] call printf_str
    // [987] phi from rom_read::@34 to printf_str [phi:rom_read::@34->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:rom_read::@34->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = s4 [phi:rom_read::@34->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@35
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1304] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1305] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1307] call display_action_text
    // [1176] phi from rom_read::@35 to display_action_text [phi:rom_read::@35->display_action_text]
    // [1176] phi display_action_text::info_text#19 = info_text [phi:rom_read::@35->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // rom_read::@36
    // rom_address % 0x04000
    // [1308] rom_read::$11 = rom_read::rom_address#10 & $4000-1 -- vduz1=vduz2_band_vduc1 
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
    // [1309] if(0!=rom_read::$11) goto rom_read::@5 -- 0_neq_vduz1_then_la1 
    lda.z rom_read__11
    ora.z rom_read__11+1
    ora.z rom_read__11+2
    ora.z rom_read__11+3
    bne __b5
    // rom_read::@11
    // brom_bank_start++;
    // [1310] rom_read::brom_bank_start#0 = ++ rom_read::brom_bank_start#10 -- vbuz1=_inc_vbuz1 
    inc.z brom_bank_start
    // [1311] phi from rom_read::@11 rom_read::@36 to rom_read::@5 [phi:rom_read::@11/rom_read::@36->rom_read::@5]
    // [1311] phi rom_read::brom_bank_start#20 = rom_read::brom_bank_start#0 [phi:rom_read::@11/rom_read::@36->rom_read::@5#0] -- register_copy 
    // rom_read::@5
  __b5:
    // rom_read::bank_set_bram2
    // BRAM = bank
    // [1312] BRAM = rom_read::bram_bank#10 -- vbuz1=vbuz2 
    lda.z bram_bank
    sta.z BRAM
    // rom_read::@16
    // unsigned int rom_package_read = fgets(ram_address, ROM_PROGRESS_CELL, fp)
    // [1313] fgets::ptr#3 = rom_read::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z fgets.ptr
    lda.z ram_address+1
    sta.z fgets.ptr+1
    // [1314] fgets::stream#1 = rom_read::fp#0 -- pssz1=pssm2 
    lda fp
    sta.z fgets.stream
    lda fp+1
    sta.z fgets.stream+1
    // [1315] call fgets
    // [2241] phi from rom_read::@16 to fgets [phi:rom_read::@16->fgets]
    // [2241] phi fgets::ptr#12 = fgets::ptr#3 [phi:rom_read::@16->fgets#0] -- register_copy 
    // [2241] phi fgets::size#10 = ROM_PROGRESS_CELL [phi:rom_read::@16->fgets#1] -- vwuz1=vwuc1 
    lda #<ROM_PROGRESS_CELL
    sta.z fgets.size
    lda #>ROM_PROGRESS_CELL
    sta.z fgets.size+1
    // [2241] phi fgets::stream#2 = fgets::stream#1 [phi:rom_read::@16->fgets#2] -- register_copy 
    jsr fgets
    // unsigned int rom_package_read = fgets(ram_address, ROM_PROGRESS_CELL, fp)
    // [1316] fgets::return#6 = fgets::return#1
    // rom_read::@37
    // [1317] rom_read::rom_package_read#0 = fgets::return#6 -- vwuz1=vwuz2 
    lda.z fgets.return
    sta.z rom_package_read
    lda.z fgets.return+1
    sta.z rom_package_read+1
    // if (!rom_package_read)
    // [1318] if(0!=rom_read::rom_package_read#0) goto rom_read::@6 -- 0_neq_vwuz1_then_la1 
    lda.z rom_package_read
    ora.z rom_package_read+1
    bne __b6
    jmp __b7
    // rom_read::@6
  __b6:
    // if (rom_row_current == ROM_PROGRESS_ROW)
    // [1319] if(rom_read::rom_row_current#10!=ROM_PROGRESS_ROW) goto rom_read::@8 -- vwuz1_neq_vwuc1_then_la1 
    lda.z rom_row_current+1
    cmp #>ROM_PROGRESS_ROW
    bne __b8
    lda.z rom_row_current
    cmp #<ROM_PROGRESS_ROW
    bne __b8
    // rom_read::@12
    // gotoxy(x, ++y);
    // [1320] rom_read::y#1 = ++ rom_read::y#11 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [1321] gotoxy::y#25 = rom_read::y#1 -- vbuyy=vbuz1 
    ldy.z y
    // [1322] call gotoxy
    // [718] phi from rom_read::@12 to gotoxy [phi:rom_read::@12->gotoxy]
    // [718] phi gotoxy::y#30 = gotoxy::y#25 [phi:rom_read::@12->gotoxy#0] -- register_copy 
    // [718] phi gotoxy::x#30 = PROGRESS_X [phi:rom_read::@12->gotoxy#1] -- vbuxx=vbuc1 
    ldx #PROGRESS_X
    jsr gotoxy
    // [1323] phi from rom_read::@12 to rom_read::@8 [phi:rom_read::@12->rom_read::@8]
    // [1323] phi rom_read::y#36 = rom_read::y#1 [phi:rom_read::@12->rom_read::@8#0] -- register_copy 
    // [1323] phi rom_read::rom_row_current#4 = 0 [phi:rom_read::@12->rom_read::@8#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z rom_row_current
    sta.z rom_row_current+1
    // [1323] phi from rom_read::@6 to rom_read::@8 [phi:rom_read::@6->rom_read::@8]
    // [1323] phi rom_read::y#36 = rom_read::y#11 [phi:rom_read::@6->rom_read::@8#0] -- register_copy 
    // [1323] phi rom_read::rom_row_current#4 = rom_read::rom_row_current#10 [phi:rom_read::@6->rom_read::@8#1] -- register_copy 
    // rom_read::@8
  __b8:
    // if(display_progress)
    // [1324] if(0==rom_read::display_progress#28) goto rom_read::@9 -- 0_eq_vbuz1_then_la1 
    lda.z display_progress
    beq __b9
    // rom_read::@13
    // cputc('.')
    // [1325] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [1326] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // rom_read::@9
  __b9:
    // ram_address += rom_package_read
    // [1328] rom_read::ram_address#1 = rom_read::ram_address#10 + rom_read::rom_package_read#0 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z ram_address
    adc.z rom_package_read
    sta.z ram_address
    lda.z ram_address+1
    adc.z rom_package_read+1
    sta.z ram_address+1
    // rom_address += rom_package_read
    // [1329] rom_read::rom_address#1 = rom_read::rom_address#10 + rom_read::rom_package_read#0 -- vduz1=vduz1_plus_vwuz2 
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
    // [1330] rom_read::rom_file_size#1 = rom_read::rom_file_size#11 + rom_read::rom_package_read#0 -- vduz1=vduz1_plus_vwuz2 
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
    // [1331] rom_read::rom_row_current#2 = rom_read::rom_row_current#4 + rom_read::rom_package_read#0 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z rom_row_current
    adc.z rom_package_read
    sta.z rom_row_current
    lda.z rom_row_current+1
    adc.z rom_package_read+1
    sta.z rom_row_current+1
    // if (ram_address == (ram_ptr_t)BRAM_HIGH)
    // [1332] if(rom_read::ram_address#1!=(char *)$c000) goto rom_read::@10 -- pbuz1_neq_pbuc1_then_la1 
    lda.z ram_address+1
    cmp #>$c000
    bne __b10
    lda.z ram_address
    cmp #<$c000
    bne __b10
    // rom_read::@14
    // bram_bank++;
    // [1333] rom_read::bram_bank#1 = ++ rom_read::bram_bank#10 -- vbuz1=_inc_vbuz1 
    inc.z bram_bank
    // [1334] phi from rom_read::@14 to rom_read::@10 [phi:rom_read::@14->rom_read::@10]
    // [1334] phi rom_read::bram_bank#31 = rom_read::bram_bank#1 [phi:rom_read::@14->rom_read::@10#0] -- register_copy 
    // [1334] phi rom_read::ram_address#7 = (char *)$a000 [phi:rom_read::@14->rom_read::@10#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1334] phi from rom_read::@9 to rom_read::@10 [phi:rom_read::@9->rom_read::@10]
    // [1334] phi rom_read::bram_bank#31 = rom_read::bram_bank#10 [phi:rom_read::@9->rom_read::@10#0] -- register_copy 
    // [1334] phi rom_read::ram_address#7 = rom_read::ram_address#1 [phi:rom_read::@9->rom_read::@10#1] -- register_copy 
    // rom_read::@10
  __b10:
    // if (ram_address == (ram_ptr_t)RAM_HIGH)
    // [1335] if(rom_read::ram_address#7!=(char *)$9800) goto rom_read::@38 -- pbuz1_neq_pbuc1_then_la1 
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
    // [1274] phi from rom_read::@10 to rom_read::@3 [phi:rom_read::@10->rom_read::@3]
    // [1274] phi rom_read::y#11 = rom_read::y#36 [phi:rom_read::@10->rom_read::@3#0] -- register_copy 
    // [1274] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#2 [phi:rom_read::@10->rom_read::@3#1] -- register_copy 
    // [1274] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#20 [phi:rom_read::@10->rom_read::@3#2] -- register_copy 
    // [1274] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@10->rom_read::@3#3] -- register_copy 
    // [1274] phi rom_read::ram_address#10 = (char *)$a000 [phi:rom_read::@10->rom_read::@3#4] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1274] phi rom_read::bram_bank#10 = 1 [phi:rom_read::@10->rom_read::@3#5] -- vbuz1=vbuc1 
    lda #1
    sta.z bram_bank
    // [1274] phi rom_read::rom_file_size#11 = rom_read::rom_file_size#1 [phi:rom_read::@10->rom_read::@3#6] -- register_copy 
    jmp __b3
    // [1336] phi from rom_read::@10 to rom_read::@38 [phi:rom_read::@10->rom_read::@38]
    // rom_read::@38
    // [1274] phi from rom_read::@38 to rom_read::@3 [phi:rom_read::@38->rom_read::@3]
    // [1274] phi rom_read::y#11 = rom_read::y#36 [phi:rom_read::@38->rom_read::@3#0] -- register_copy 
    // [1274] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#2 [phi:rom_read::@38->rom_read::@3#1] -- register_copy 
    // [1274] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#20 [phi:rom_read::@38->rom_read::@3#2] -- register_copy 
    // [1274] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@38->rom_read::@3#3] -- register_copy 
    // [1274] phi rom_read::ram_address#10 = rom_read::ram_address#7 [phi:rom_read::@38->rom_read::@3#4] -- register_copy 
    // [1274] phi rom_read::bram_bank#10 = rom_read::bram_bank#31 [phi:rom_read::@38->rom_read::@3#5] -- register_copy 
    // [1274] phi rom_read::rom_file_size#11 = rom_read::rom_file_size#1 [phi:rom_read::@38->rom_read::@3#6] -- register_copy 
  .segment Data
    s: .text "Opening "
    .byte 0
    s1: .text " from SD card ..."
    .byte 0
    .label fp = rom_read_byte.rom_bank1_rom_read_byte__2
    .label file = clrscr.ch
}
.segment Code
  // rom_verify
// __zp($6c) unsigned long rom_verify(__zp($6b) char rom_chip, __register(X) char rom_bank_start, __mem() unsigned long file_size)
rom_verify: {
    .label rom_verify__16 = $61
    .label rom_address = $63
    .label equal_bytes = $61
    .label y = $e4
    .label ram_address = $49
    .label bram_bank = $e1
    .label rom_different_bytes = $6c
    .label rom_chip = $6b
    .label return = $6c
    .label progress_row_current = $ef
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [1337] rom_address_from_bank::rom_bank#1 = rom_verify::rom_bank_start#0 -- vbuaa=vbuxx 
    txa
    // [1338] call rom_address_from_bank
    // [2365] phi from rom_verify to rom_address_from_bank [phi:rom_verify->rom_address_from_bank]
    // [2365] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#1 [phi:rom_verify->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [1339] rom_address_from_bank::return#3 = rom_address_from_bank::return#0 -- vduz1=vduz2 
    lda.z rom_address_from_bank.return
    sta.z rom_address_from_bank.return_1
    lda.z rom_address_from_bank.return+1
    sta.z rom_address_from_bank.return_1+1
    lda.z rom_address_from_bank.return+2
    sta.z rom_address_from_bank.return_1+2
    lda.z rom_address_from_bank.return+3
    sta.z rom_address_from_bank.return_1+3
    // rom_verify::@11
    // [1340] rom_verify::rom_address#0 = rom_address_from_bank::return#3
    // unsigned long rom_boundary = rom_address + file_size
    // [1341] rom_verify::rom_boundary#0 = rom_verify::rom_address#0 + rom_verify::file_size#0 -- vdum1=vduz2_plus_vdum1 
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
    // [1342] display_info_rom::rom_chip#1 = rom_verify::rom_chip#0
    // [1343] call display_info_rom
    // [1199] phi from rom_verify::@11 to display_info_rom [phi:rom_verify::@11->display_info_rom]
    // [1199] phi display_info_rom::info_text#16 = rom_verify::info_text [phi:rom_verify::@11->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_rom.info_text
    lda #>info_text
    sta.z display_info_rom.info_text+1
    // [1199] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#1 [phi:rom_verify::@11->display_info_rom#1] -- register_copy 
    // [1199] phi display_info_rom::info_status#16 = STATUS_COMPARING [phi:rom_verify::@11->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_COMPARING
    sta display_info_rom.info_status
    jsr display_info_rom
    // [1344] phi from rom_verify::@11 to rom_verify::@12 [phi:rom_verify::@11->rom_verify::@12]
    // rom_verify::@12
    // gotoxy(x, y)
    // [1345] call gotoxy
    // [718] phi from rom_verify::@12 to gotoxy [phi:rom_verify::@12->gotoxy]
    // [718] phi gotoxy::y#30 = PROGRESS_Y [phi:rom_verify::@12->gotoxy#0] -- vbuyy=vbuc1 
    ldy #PROGRESS_Y
    // [718] phi gotoxy::x#30 = PROGRESS_X [phi:rom_verify::@12->gotoxy#1] -- vbuxx=vbuc1 
    ldx #PROGRESS_X
    jsr gotoxy
    // [1346] phi from rom_verify::@12 to rom_verify::@1 [phi:rom_verify::@12->rom_verify::@1]
    // [1346] phi rom_verify::y#3 = PROGRESS_Y [phi:rom_verify::@12->rom_verify::@1#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // [1346] phi rom_verify::progress_row_current#3 = 0 [phi:rom_verify::@12->rom_verify::@1#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z progress_row_current
    sta.z progress_row_current+1
    // [1346] phi rom_verify::rom_different_bytes#11 = 0 [phi:rom_verify::@12->rom_verify::@1#2] -- vduz1=vduc1 
    sta.z rom_different_bytes
    sta.z rom_different_bytes+1
    lda #<0>>$10
    sta.z rom_different_bytes+2
    lda #>0>>$10
    sta.z rom_different_bytes+3
    // [1346] phi rom_verify::ram_address#10 = (char *)$7800 [phi:rom_verify::@12->rom_verify::@1#3] -- pbuz1=pbuc1 
    lda #<$7800
    sta.z ram_address
    lda #>$7800
    sta.z ram_address+1
    // [1346] phi rom_verify::bram_bank#11 = 0 [phi:rom_verify::@12->rom_verify::@1#4] -- vbuz1=vbuc1 
    lda #0
    sta.z bram_bank
    // [1346] phi rom_verify::rom_address#12 = rom_verify::rom_address#0 [phi:rom_verify::@12->rom_verify::@1#5] -- register_copy 
    // rom_verify::@1
  __b1:
    // while (rom_address < rom_boundary)
    // [1347] if(rom_verify::rom_address#12<rom_verify::rom_boundary#0) goto rom_verify::@2 -- vduz1_lt_vdum2_then_la1 
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
    // [1348] return 
    rts
    // rom_verify::@2
  __b2:
    // unsigned int equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1349] rom_compare::bank_ram#0 = rom_verify::bram_bank#11 -- vbuxx=vbuz1 
    ldx.z bram_bank
    // [1350] rom_compare::ptr_ram#1 = rom_verify::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_compare.ptr_ram
    lda.z ram_address+1
    sta.z rom_compare.ptr_ram+1
    // [1351] rom_compare::rom_compare_address#0 = rom_verify::rom_address#12 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_compare.rom_compare_address
    lda.z rom_address+1
    sta.z rom_compare.rom_compare_address+1
    lda.z rom_address+2
    sta.z rom_compare.rom_compare_address+2
    lda.z rom_address+3
    sta.z rom_compare.rom_compare_address+3
    // [1352] call rom_compare
  // {asm{.byte $db}}
    // [2369] phi from rom_verify::@2 to rom_compare [phi:rom_verify::@2->rom_compare]
    // [2369] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#1 [phi:rom_verify::@2->rom_compare#0] -- register_copy 
    // [2369] phi rom_compare::rom_compare_size#11 = ROM_PROGRESS_CELL [phi:rom_verify::@2->rom_compare#1] -- vwuz1=vwuc1 
    lda #<ROM_PROGRESS_CELL
    sta.z rom_compare.rom_compare_size
    lda #>ROM_PROGRESS_CELL
    sta.z rom_compare.rom_compare_size+1
    // [2369] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#0 [phi:rom_verify::@2->rom_compare#2] -- register_copy 
    // [2369] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#0 [phi:rom_verify::@2->rom_compare#3] -- register_copy 
    jsr rom_compare
    // unsigned int equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1353] rom_compare::return#2 = rom_compare::equal_bytes#2
    // rom_verify::@13
    // [1354] rom_verify::equal_bytes#0 = rom_compare::return#2
    // if (progress_row_current == ROM_PROGRESS_ROW)
    // [1355] if(rom_verify::progress_row_current#3!=ROM_PROGRESS_ROW) goto rom_verify::@3 -- vwuz1_neq_vwuc1_then_la1 
    lda.z progress_row_current+1
    cmp #>ROM_PROGRESS_ROW
    bne __b3
    lda.z progress_row_current
    cmp #<ROM_PROGRESS_ROW
    bne __b3
    // rom_verify::@8
    // gotoxy(x, ++y);
    // [1356] rom_verify::y#1 = ++ rom_verify::y#3 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [1357] gotoxy::y#27 = rom_verify::y#1 -- vbuyy=vbuz1 
    ldy.z y
    // [1358] call gotoxy
    // [718] phi from rom_verify::@8 to gotoxy [phi:rom_verify::@8->gotoxy]
    // [718] phi gotoxy::y#30 = gotoxy::y#27 [phi:rom_verify::@8->gotoxy#0] -- register_copy 
    // [718] phi gotoxy::x#30 = PROGRESS_X [phi:rom_verify::@8->gotoxy#1] -- vbuxx=vbuc1 
    ldx #PROGRESS_X
    jsr gotoxy
    // [1359] phi from rom_verify::@8 to rom_verify::@3 [phi:rom_verify::@8->rom_verify::@3]
    // [1359] phi rom_verify::y#10 = rom_verify::y#1 [phi:rom_verify::@8->rom_verify::@3#0] -- register_copy 
    // [1359] phi rom_verify::progress_row_current#4 = 0 [phi:rom_verify::@8->rom_verify::@3#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z progress_row_current
    sta.z progress_row_current+1
    // [1359] phi from rom_verify::@13 to rom_verify::@3 [phi:rom_verify::@13->rom_verify::@3]
    // [1359] phi rom_verify::y#10 = rom_verify::y#3 [phi:rom_verify::@13->rom_verify::@3#0] -- register_copy 
    // [1359] phi rom_verify::progress_row_current#4 = rom_verify::progress_row_current#3 [phi:rom_verify::@13->rom_verify::@3#1] -- register_copy 
    // rom_verify::@3
  __b3:
    // if (equal_bytes != ROM_PROGRESS_CELL)
    // [1360] if(rom_verify::equal_bytes#0!=ROM_PROGRESS_CELL) goto rom_verify::@4 -- vwuz1_neq_vwuc1_then_la1 
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
    // [1361] stackpush(char) = '=' -- _stackpushbyte_=vbuc1 
    lda #'='
    pha
    // [1362] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // rom_verify::@5
  __b5:
    // ram_address += ROM_PROGRESS_CELL
    // [1364] rom_verify::ram_address#1 = rom_verify::ram_address#10 + ROM_PROGRESS_CELL -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address
    clc
    adc #<ROM_PROGRESS_CELL
    sta.z ram_address
    lda.z ram_address+1
    adc #>ROM_PROGRESS_CELL
    sta.z ram_address+1
    // rom_address += ROM_PROGRESS_CELL
    // [1365] rom_verify::rom_address#1 = rom_verify::rom_address#12 + ROM_PROGRESS_CELL -- vduz1=vduz1_plus_vwuc1 
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
    // [1366] rom_verify::progress_row_current#11 = rom_verify::progress_row_current#4 + ROM_PROGRESS_CELL -- vwuz1=vwuz1_plus_vwuc1 
    lda.z progress_row_current
    clc
    adc #<ROM_PROGRESS_CELL
    sta.z progress_row_current
    lda.z progress_row_current+1
    adc #>ROM_PROGRESS_CELL
    sta.z progress_row_current+1
    // if (ram_address == BRAM_HIGH)
    // [1367] if(rom_verify::ram_address#1!=$c000) goto rom_verify::@6 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address+1
    cmp #>$c000
    bne __b6
    lda.z ram_address
    cmp #<$c000
    bne __b6
    // rom_verify::@10
    // bram_bank++;
    // [1368] rom_verify::bram_bank#1 = ++ rom_verify::bram_bank#11 -- vbuz1=_inc_vbuz1 
    inc.z bram_bank
    // [1369] phi from rom_verify::@10 to rom_verify::@6 [phi:rom_verify::@10->rom_verify::@6]
    // [1369] phi rom_verify::bram_bank#24 = rom_verify::bram_bank#1 [phi:rom_verify::@10->rom_verify::@6#0] -- register_copy 
    // [1369] phi rom_verify::ram_address#6 = (char *)$a000 [phi:rom_verify::@10->rom_verify::@6#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1369] phi from rom_verify::@5 to rom_verify::@6 [phi:rom_verify::@5->rom_verify::@6]
    // [1369] phi rom_verify::bram_bank#24 = rom_verify::bram_bank#11 [phi:rom_verify::@5->rom_verify::@6#0] -- register_copy 
    // [1369] phi rom_verify::ram_address#6 = rom_verify::ram_address#1 [phi:rom_verify::@5->rom_verify::@6#1] -- register_copy 
    // rom_verify::@6
  __b6:
    // if (ram_address == RAM_HIGH)
    // [1370] if(rom_verify::ram_address#6!=$9800) goto rom_verify::@23 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address+1
    cmp #>$9800
    bne __b7
    lda.z ram_address
    cmp #<$9800
    bne __b7
    // [1372] phi from rom_verify::@6 to rom_verify::@7 [phi:rom_verify::@6->rom_verify::@7]
    // [1372] phi rom_verify::ram_address#11 = (char *)$a000 [phi:rom_verify::@6->rom_verify::@7#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1372] phi rom_verify::bram_bank#10 = 1 [phi:rom_verify::@6->rom_verify::@7#1] -- vbuz1=vbuc1 
    lda #1
    sta.z bram_bank
    // [1371] phi from rom_verify::@6 to rom_verify::@23 [phi:rom_verify::@6->rom_verify::@23]
    // rom_verify::@23
    // [1372] phi from rom_verify::@23 to rom_verify::@7 [phi:rom_verify::@23->rom_verify::@7]
    // [1372] phi rom_verify::ram_address#11 = rom_verify::ram_address#6 [phi:rom_verify::@23->rom_verify::@7#0] -- register_copy 
    // [1372] phi rom_verify::bram_bank#10 = rom_verify::bram_bank#24 [phi:rom_verify::@23->rom_verify::@7#1] -- register_copy 
    // rom_verify::@7
  __b7:
    // ROM_PROGRESS_CELL - equal_bytes
    // [1373] rom_verify::$16 = ROM_PROGRESS_CELL - rom_verify::equal_bytes#0 -- vwuz1=vwuc1_minus_vwuz1 
    lda #<ROM_PROGRESS_CELL
    sec
    sbc.z rom_verify__16
    sta.z rom_verify__16
    lda #>ROM_PROGRESS_CELL
    sbc.z rom_verify__16+1
    sta.z rom_verify__16+1
    // rom_different_bytes += (ROM_PROGRESS_CELL - equal_bytes)
    // [1374] rom_verify::rom_different_bytes#1 = rom_verify::rom_different_bytes#11 + rom_verify::$16 -- vduz1=vduz1_plus_vwuz2 
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
    // [1375] call snprintf_init
    // [982] phi from rom_verify::@7 to snprintf_init [phi:rom_verify::@7->snprintf_init]
    // [982] phi snprintf_init::s#27 = info_text [phi:rom_verify::@7->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1376] phi from rom_verify::@7 to rom_verify::@14 [phi:rom_verify::@7->rom_verify::@14]
    // rom_verify::@14
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1377] call printf_str
    // [987] phi from rom_verify::@14 to printf_str [phi:rom_verify::@14->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:rom_verify::@14->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = rom_verify::s [phi:rom_verify::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@15
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1378] printf_ulong::uvalue#2 = rom_verify::rom_different_bytes#1 -- vduz1=vduz2 
    lda.z rom_different_bytes
    sta.z printf_ulong.uvalue
    lda.z rom_different_bytes+1
    sta.z printf_ulong.uvalue+1
    lda.z rom_different_bytes+2
    sta.z printf_ulong.uvalue+2
    lda.z rom_different_bytes+3
    sta.z printf_ulong.uvalue+3
    // [1379] call printf_ulong
    // [1399] phi from rom_verify::@15 to printf_ulong [phi:rom_verify::@15->printf_ulong]
    // [1399] phi printf_ulong::format_zero_padding#10 = 1 [phi:rom_verify::@15->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1399] phi printf_ulong::format_min_length#10 = 5 [phi:rom_verify::@15->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1399] phi printf_ulong::format_radix#10 = HEXADECIMAL [phi:rom_verify::@15->printf_ulong#2] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [1399] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#2 [phi:rom_verify::@15->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1380] phi from rom_verify::@15 to rom_verify::@16 [phi:rom_verify::@15->rom_verify::@16]
    // rom_verify::@16
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1381] call printf_str
    // [987] phi from rom_verify::@16 to printf_str [phi:rom_verify::@16->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:rom_verify::@16->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = rom_verify::s1 [phi:rom_verify::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@17
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1382] printf_uchar::uvalue#10 = rom_verify::bram_bank#10 -- vbuxx=vbuz1 
    ldx.z bram_bank
    // [1383] call printf_uchar
    // [1165] phi from rom_verify::@17 to printf_uchar [phi:rom_verify::@17->printf_uchar]
    // [1165] phi printf_uchar::format_zero_padding#14 = 1 [phi:rom_verify::@17->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1165] phi printf_uchar::format_min_length#14 = 2 [phi:rom_verify::@17->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [1165] phi printf_uchar::putc#14 = &snputc [phi:rom_verify::@17->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1165] phi printf_uchar::format_radix#14 = HEXADECIMAL [phi:rom_verify::@17->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #HEXADECIMAL
    // [1165] phi printf_uchar::uvalue#14 = printf_uchar::uvalue#10 [phi:rom_verify::@17->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1384] phi from rom_verify::@17 to rom_verify::@18 [phi:rom_verify::@17->rom_verify::@18]
    // rom_verify::@18
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1385] call printf_str
    // [987] phi from rom_verify::@18 to printf_str [phi:rom_verify::@18->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:rom_verify::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = s3 [phi:rom_verify::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s3
    sta.z printf_str.s
    lda #>@s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@19
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1386] printf_uint::uvalue#10 = (unsigned int)rom_verify::ram_address#11 -- vwuz1=vwuz2 
    lda.z ram_address
    sta.z printf_uint.uvalue
    lda.z ram_address+1
    sta.z printf_uint.uvalue+1
    // [1387] call printf_uint
    // [996] phi from rom_verify::@19 to printf_uint [phi:rom_verify::@19->printf_uint]
    // [996] phi printf_uint::format_zero_padding#15 = 1 [phi:rom_verify::@19->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [996] phi printf_uint::format_min_length#15 = 4 [phi:rom_verify::@19->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [996] phi printf_uint::format_radix#15 = HEXADECIMAL [phi:rom_verify::@19->printf_uint#2] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [996] phi printf_uint::uvalue#15 = printf_uint::uvalue#10 [phi:rom_verify::@19->printf_uint#3] -- register_copy 
    jsr printf_uint
    // [1388] phi from rom_verify::@19 to rom_verify::@20 [phi:rom_verify::@19->rom_verify::@20]
    // rom_verify::@20
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1389] call printf_str
    // [987] phi from rom_verify::@20 to printf_str [phi:rom_verify::@20->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:rom_verify::@20->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = rom_verify::s3 [phi:rom_verify::@20->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@21
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1390] printf_ulong::uvalue#3 = rom_verify::rom_address#1 -- vduz1=vduz2 
    lda.z rom_address
    sta.z printf_ulong.uvalue
    lda.z rom_address+1
    sta.z printf_ulong.uvalue+1
    lda.z rom_address+2
    sta.z printf_ulong.uvalue+2
    lda.z rom_address+3
    sta.z printf_ulong.uvalue+3
    // [1391] call printf_ulong
    // [1399] phi from rom_verify::@21 to printf_ulong [phi:rom_verify::@21->printf_ulong]
    // [1399] phi printf_ulong::format_zero_padding#10 = 1 [phi:rom_verify::@21->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1399] phi printf_ulong::format_min_length#10 = 5 [phi:rom_verify::@21->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1399] phi printf_ulong::format_radix#10 = HEXADECIMAL [phi:rom_verify::@21->printf_ulong#2] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [1399] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#3 [phi:rom_verify::@21->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // rom_verify::@22
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1392] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1393] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1395] call display_action_text
    // [1176] phi from rom_verify::@22 to display_action_text [phi:rom_verify::@22->display_action_text]
    // [1176] phi display_action_text::info_text#19 = info_text [phi:rom_verify::@22->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1346] phi from rom_verify::@22 to rom_verify::@1 [phi:rom_verify::@22->rom_verify::@1]
    // [1346] phi rom_verify::y#3 = rom_verify::y#10 [phi:rom_verify::@22->rom_verify::@1#0] -- register_copy 
    // [1346] phi rom_verify::progress_row_current#3 = rom_verify::progress_row_current#11 [phi:rom_verify::@22->rom_verify::@1#1] -- register_copy 
    // [1346] phi rom_verify::rom_different_bytes#11 = rom_verify::rom_different_bytes#1 [phi:rom_verify::@22->rom_verify::@1#2] -- register_copy 
    // [1346] phi rom_verify::ram_address#10 = rom_verify::ram_address#11 [phi:rom_verify::@22->rom_verify::@1#3] -- register_copy 
    // [1346] phi rom_verify::bram_bank#11 = rom_verify::bram_bank#10 [phi:rom_verify::@22->rom_verify::@1#4] -- register_copy 
    // [1346] phi rom_verify::rom_address#12 = rom_verify::rom_address#1 [phi:rom_verify::@22->rom_verify::@1#5] -- register_copy 
    jmp __b1
    // rom_verify::@4
  __b4:
    // cputc('*')
    // [1396] stackpush(char) = '*' -- _stackpushbyte_=vbuc1 
    lda #'*'
    pha
    // [1397] callexecute cputc  -- call_vprc1 
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
    .label file_size = rom_flash.rom_flash__29
}
.segment Code
  // printf_ulong
// Print an unsigned int using a specific format
// void printf_ulong(void (*putc)(char), __zp($25) unsigned long uvalue, __zp($ce) char format_min_length, char format_justify_left, char format_sign_always, __zp($be) char format_zero_padding, char format_upper_case, __register(X) char format_radix)
printf_ulong: {
    .label uvalue = $25
    .label uvalue_1 = $dd
    .label format_min_length = $ce
    .label format_zero_padding = $be
    // printf_ulong::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1400] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // ultoa(uvalue, printf_buffer.digits, format.radix)
    // [1401] ultoa::value#1 = printf_ulong::uvalue#10
    // [1402] ultoa::radix#0 = printf_ulong::format_radix#10
    // [1403] call ultoa
    // Format number into buffer
    jsr ultoa
    // printf_ulong::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1404] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [1405] printf_number_buffer::format_min_length#0 = printf_ulong::format_min_length#10 -- vbuxx=vbuz1 
    ldx.z format_min_length
    // [1406] printf_number_buffer::format_zero_padding#0 = printf_ulong::format_zero_padding#10
    // [1407] call printf_number_buffer
  // Print using format
    // [2107] phi from printf_ulong::@2 to printf_number_buffer [phi:printf_ulong::@2->printf_number_buffer]
    // [2107] phi printf_number_buffer::putc#10 = &snputc [phi:printf_ulong::@2->printf_number_buffer#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_number_buffer.putc
    lda #>snputc
    sta.z printf_number_buffer.putc+1
    // [2107] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_ulong::@2->printf_number_buffer#1] -- register_copy 
    // [2107] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#0 [phi:printf_ulong::@2->printf_number_buffer#2] -- register_copy 
    // [2107] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#0 [phi:printf_ulong::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_ulong::@return
    // }
    // [1408] return 
    rts
}
  // rom_flash
// __zp($f8) unsigned long rom_flash(__mem() char rom_chip, __mem() char rom_bank_start, __zp($32) unsigned long file_size)
rom_flash: {
    .label equal_bytes = $61
    .label ram_address_sector = $b5
    .label equal_bytes_1 = $43
    .label retries = $f2
    .label flash_errors_sector = $c4
    .label ram_address = $b3
    .label rom_address = $d0
    .label x = $cb
    .label flash_errors = $f8
    .label bram_bank_sector = $d9
    .label x_sector = $d4
    .label y_sector = $cc
    .label file_size = $32
    .label return = $f8
    // display_action_progress("Flashing ... (-) equal, (+) flashed, (!) error.")
    // [1410] call display_action_progress
  // Now we compare the RAM with the actual ROM contents.
    // [812] phi from rom_flash to display_action_progress [phi:rom_flash->display_action_progress]
    // [812] phi display_action_progress::info_text#15 = rom_flash::info_text [phi:rom_flash->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // rom_flash::@19
    // unsigned long rom_address_sector = rom_address_from_bank(rom_bank_start)
    // [1411] rom_address_from_bank::rom_bank#2 = rom_flash::rom_bank_start#0 -- vbuaa=vbum1 
    lda rom_bank_start
    // [1412] call rom_address_from_bank
    // [2365] phi from rom_flash::@19 to rom_address_from_bank [phi:rom_flash::@19->rom_address_from_bank]
    // [2365] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#2 [phi:rom_flash::@19->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address_sector = rom_address_from_bank(rom_bank_start)
    // [1413] rom_address_from_bank::return#4 = rom_address_from_bank::return#0 -- vdum1=vduz2 
    lda.z rom_address_from_bank.return
    sta rom_address_from_bank.return_2
    lda.z rom_address_from_bank.return+1
    sta rom_address_from_bank.return_2+1
    lda.z rom_address_from_bank.return+2
    sta rom_address_from_bank.return_2+2
    lda.z rom_address_from_bank.return+3
    sta rom_address_from_bank.return_2+3
    // rom_flash::@20
    // [1414] rom_flash::rom_address_sector#0 = rom_address_from_bank::return#4
    // unsigned long rom_boundary = rom_address_sector + file_size
    // [1415] rom_flash::rom_boundary#0 = rom_flash::rom_address_sector#0 + rom_flash::file_size#0 -- vdum1=vdum2_plus_vduz3 
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
    // [1416] display_info_rom::rom_chip#2 = rom_flash::rom_chip#0 -- vbuz1=vbum2 
    lda rom_chip
    sta.z display_info_rom.rom_chip
    // [1417] call display_info_rom
    // [1199] phi from rom_flash::@20 to display_info_rom [phi:rom_flash::@20->display_info_rom]
    // [1199] phi display_info_rom::info_text#16 = rom_flash::info_text1 [phi:rom_flash::@20->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_rom.info_text
    lda #>info_text1
    sta.z display_info_rom.info_text+1
    // [1199] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#2 [phi:rom_flash::@20->display_info_rom#1] -- register_copy 
    // [1199] phi display_info_rom::info_status#16 = STATUS_FLASHING [phi:rom_flash::@20->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHING
    sta display_info_rom.info_status
    jsr display_info_rom
    // [1418] phi from rom_flash::@20 to rom_flash::@1 [phi:rom_flash::@20->rom_flash::@1]
    // [1418] phi rom_flash::y_sector#13 = PROGRESS_Y [phi:rom_flash::@20->rom_flash::@1#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y_sector
    // [1418] phi rom_flash::x_sector#10 = PROGRESS_X [phi:rom_flash::@20->rom_flash::@1#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z x_sector
    // [1418] phi rom_flash::flash_errors#10 = 0 [phi:rom_flash::@20->rom_flash::@1#2] -- vduz1=vduc1 
    lda #<0
    sta.z flash_errors
    sta.z flash_errors+1
    lda #<0>>$10
    sta.z flash_errors+2
    lda #>0>>$10
    sta.z flash_errors+3
    // [1418] phi rom_flash::ram_address_sector#11 = (char *)$7800 [phi:rom_flash::@20->rom_flash::@1#3] -- pbuz1=pbuc1 
    lda #<$7800
    sta.z ram_address_sector
    lda #>$7800
    sta.z ram_address_sector+1
    // [1418] phi rom_flash::bram_bank_sector#14 = 0 [phi:rom_flash::@20->rom_flash::@1#4] -- vbuz1=vbuc1 
    lda #0
    sta.z bram_bank_sector
    // [1418] phi rom_flash::rom_address_sector#12 = rom_flash::rom_address_sector#0 [phi:rom_flash::@20->rom_flash::@1#5] -- register_copy 
    // rom_flash::@1
  __b1:
    // while (rom_address_sector < rom_boundary)
    // [1419] if(rom_flash::rom_address_sector#12<rom_flash::rom_boundary#0) goto rom_flash::@2 -- vdum1_lt_vdum2_then_la1 
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
    // [1420] phi from rom_flash::@1 to rom_flash::@3 [phi:rom_flash::@1->rom_flash::@3]
    // rom_flash::@3
    // display_action_text("Flashed ...")
    // [1421] call display_action_text
    // [1176] phi from rom_flash::@3 to display_action_text [phi:rom_flash::@3->display_action_text]
    // [1176] phi display_action_text::info_text#19 = rom_flash::info_text2 [phi:rom_flash::@3->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z display_action_text.info_text
    lda #>info_text2
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // rom_flash::@return
    // }
    // [1422] return 
    rts
    // rom_flash::@2
  __b2:
    // unsigned int equal_bytes = rom_compare(bram_bank_sector, (ram_ptr_t)ram_address_sector, rom_address_sector, ROM_SECTOR)
    // [1423] rom_compare::bank_ram#1 = rom_flash::bram_bank_sector#14 -- vbuxx=vbuz1 
    ldx.z bram_bank_sector
    // [1424] rom_compare::ptr_ram#2 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z rom_compare.ptr_ram
    lda.z ram_address_sector+1
    sta.z rom_compare.ptr_ram+1
    // [1425] rom_compare::rom_compare_address#1 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_compare.rom_compare_address
    lda rom_address_sector+1
    sta.z rom_compare.rom_compare_address+1
    lda rom_address_sector+2
    sta.z rom_compare.rom_compare_address+2
    lda rom_address_sector+3
    sta.z rom_compare.rom_compare_address+3
    // [1426] call rom_compare
  // {asm{.byte $db}}
    // [2369] phi from rom_flash::@2 to rom_compare [phi:rom_flash::@2->rom_compare]
    // [2369] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#2 [phi:rom_flash::@2->rom_compare#0] -- register_copy 
    // [2369] phi rom_compare::rom_compare_size#11 = $1000 [phi:rom_flash::@2->rom_compare#1] -- vwuz1=vwuc1 
    lda #<$1000
    sta.z rom_compare.rom_compare_size
    lda #>$1000
    sta.z rom_compare.rom_compare_size+1
    // [2369] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#1 [phi:rom_flash::@2->rom_compare#2] -- register_copy 
    // [2369] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#1 [phi:rom_flash::@2->rom_compare#3] -- register_copy 
    jsr rom_compare
    // unsigned int equal_bytes = rom_compare(bram_bank_sector, (ram_ptr_t)ram_address_sector, rom_address_sector, ROM_SECTOR)
    // [1427] rom_compare::return#3 = rom_compare::equal_bytes#2
    // rom_flash::@21
    // [1428] rom_flash::equal_bytes#0 = rom_compare::return#3
    // if (equal_bytes != ROM_SECTOR)
    // [1429] if(rom_flash::equal_bytes#0!=$1000) goto rom_flash::@5 -- vwuz1_neq_vwuc1_then_la1 
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
    // [1430] cputsxy::x#1 = rom_flash::x_sector#10 -- vbuxx=vbuz1 
    ldx.z x_sector
    // [1431] cputsxy::y#1 = rom_flash::y_sector#13 -- vbuyy=vbuz1 
    ldy.z y_sector
    // [1432] call cputsxy
    // [805] phi from rom_flash::@16 to cputsxy [phi:rom_flash::@16->cputsxy]
    // [805] phi cputsxy::s#4 = rom_flash::s [phi:rom_flash::@16->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z cputsxy.s
    lda #>s
    sta.z cputsxy.s+1
    // [805] phi cputsxy::y#4 = cputsxy::y#1 [phi:rom_flash::@16->cputsxy#1] -- register_copy 
    // [805] phi cputsxy::x#4 = cputsxy::x#1 [phi:rom_flash::@16->cputsxy#2] -- register_copy 
    jsr cputsxy
    // [1433] phi from rom_flash::@12 rom_flash::@16 to rom_flash::@4 [phi:rom_flash::@12/rom_flash::@16->rom_flash::@4]
    // [1433] phi rom_flash::flash_errors#13 = rom_flash::flash_errors#1 [phi:rom_flash::@12/rom_flash::@16->rom_flash::@4#0] -- register_copy 
    // rom_flash::@4
  __b4:
    // ram_address_sector += ROM_SECTOR
    // [1434] rom_flash::ram_address_sector#1 = rom_flash::ram_address_sector#11 + $1000 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address_sector
    clc
    adc #<$1000
    sta.z ram_address_sector
    lda.z ram_address_sector+1
    adc #>$1000
    sta.z ram_address_sector+1
    // rom_address_sector += ROM_SECTOR
    // [1435] rom_flash::rom_address_sector#1 = rom_flash::rom_address_sector#12 + $1000 -- vdum1=vdum1_plus_vwuc1 
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
    // [1436] if(rom_flash::ram_address_sector#1!=$c000) goto rom_flash::@13 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address_sector+1
    cmp #>$c000
    bne __b13
    lda.z ram_address_sector
    cmp #<$c000
    bne __b13
    // rom_flash::@17
    // bram_bank_sector++;
    // [1437] rom_flash::bram_bank_sector#1 = ++ rom_flash::bram_bank_sector#14 -- vbuz1=_inc_vbuz1 
    inc.z bram_bank_sector
    // [1438] phi from rom_flash::@17 to rom_flash::@13 [phi:rom_flash::@17->rom_flash::@13]
    // [1438] phi rom_flash::bram_bank_sector#38 = rom_flash::bram_bank_sector#1 [phi:rom_flash::@17->rom_flash::@13#0] -- register_copy 
    // [1438] phi rom_flash::ram_address_sector#8 = (char *)$a000 [phi:rom_flash::@17->rom_flash::@13#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address_sector
    lda #>$a000
    sta.z ram_address_sector+1
    // [1438] phi from rom_flash::@4 to rom_flash::@13 [phi:rom_flash::@4->rom_flash::@13]
    // [1438] phi rom_flash::bram_bank_sector#38 = rom_flash::bram_bank_sector#14 [phi:rom_flash::@4->rom_flash::@13#0] -- register_copy 
    // [1438] phi rom_flash::ram_address_sector#8 = rom_flash::ram_address_sector#1 [phi:rom_flash::@4->rom_flash::@13#1] -- register_copy 
    // rom_flash::@13
  __b13:
    // if (ram_address_sector == RAM_HIGH)
    // [1439] if(rom_flash::ram_address_sector#8!=$9800) goto rom_flash::@44 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address_sector+1
    cmp #>$9800
    bne __b14
    lda.z ram_address_sector
    cmp #<$9800
    bne __b14
    // [1441] phi from rom_flash::@13 to rom_flash::@14 [phi:rom_flash::@13->rom_flash::@14]
    // [1441] phi rom_flash::ram_address_sector#15 = (char *)$a000 [phi:rom_flash::@13->rom_flash::@14#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address_sector
    lda #>$a000
    sta.z ram_address_sector+1
    // [1441] phi rom_flash::bram_bank_sector#12 = 1 [phi:rom_flash::@13->rom_flash::@14#1] -- vbuz1=vbuc1 
    lda #1
    sta.z bram_bank_sector
    // [1440] phi from rom_flash::@13 to rom_flash::@44 [phi:rom_flash::@13->rom_flash::@44]
    // rom_flash::@44
    // [1441] phi from rom_flash::@44 to rom_flash::@14 [phi:rom_flash::@44->rom_flash::@14]
    // [1441] phi rom_flash::ram_address_sector#15 = rom_flash::ram_address_sector#8 [phi:rom_flash::@44->rom_flash::@14#0] -- register_copy 
    // [1441] phi rom_flash::bram_bank_sector#12 = rom_flash::bram_bank_sector#38 [phi:rom_flash::@44->rom_flash::@14#1] -- register_copy 
    // rom_flash::@14
  __b14:
    // x_sector += 8
    // [1442] rom_flash::x_sector#1 = rom_flash::x_sector#10 + 8 -- vbuz1=vbuz1_plus_vbuc1 
    lda #8
    clc
    adc.z x_sector
    sta.z x_sector
    // rom_address_sector % ROM_PROGRESS_ROW
    // [1443] rom_flash::$29 = rom_flash::rom_address_sector#1 & ROM_PROGRESS_ROW-1 -- vdum1=vdum2_band_vduc1 
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
    // [1444] if(0!=rom_flash::$29) goto rom_flash::@15 -- 0_neq_vdum1_then_la1 
    lda rom_flash__29
    ora rom_flash__29+1
    ora rom_flash__29+2
    ora rom_flash__29+3
    bne __b15
    // rom_flash::@18
    // y_sector++;
    // [1445] rom_flash::y_sector#1 = ++ rom_flash::y_sector#13 -- vbuz1=_inc_vbuz1 
    inc.z y_sector
    // [1446] phi from rom_flash::@18 to rom_flash::@15 [phi:rom_flash::@18->rom_flash::@15]
    // [1446] phi rom_flash::y_sector#18 = rom_flash::y_sector#1 [phi:rom_flash::@18->rom_flash::@15#0] -- register_copy 
    // [1446] phi rom_flash::x_sector#20 = PROGRESS_X [phi:rom_flash::@18->rom_flash::@15#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z x_sector
    // [1446] phi from rom_flash::@14 to rom_flash::@15 [phi:rom_flash::@14->rom_flash::@15]
    // [1446] phi rom_flash::y_sector#18 = rom_flash::y_sector#13 [phi:rom_flash::@14->rom_flash::@15#0] -- register_copy 
    // [1446] phi rom_flash::x_sector#20 = rom_flash::x_sector#1 [phi:rom_flash::@14->rom_flash::@15#1] -- register_copy 
    // rom_flash::@15
  __b15:
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1447] call snprintf_init
    // [982] phi from rom_flash::@15 to snprintf_init [phi:rom_flash::@15->snprintf_init]
    // [982] phi snprintf_init::s#27 = info_text [phi:rom_flash::@15->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // rom_flash::@40
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1448] printf_ulong::uvalue#6 = rom_flash::flash_errors#13 -- vduz1=vduz2 
    lda.z flash_errors
    sta.z printf_ulong.uvalue
    lda.z flash_errors+1
    sta.z printf_ulong.uvalue+1
    lda.z flash_errors+2
    sta.z printf_ulong.uvalue+2
    lda.z flash_errors+3
    sta.z printf_ulong.uvalue+3
    // [1449] call printf_ulong
    // [1399] phi from rom_flash::@40 to printf_ulong [phi:rom_flash::@40->printf_ulong]
    // [1399] phi printf_ulong::format_zero_padding#10 = 0 [phi:rom_flash::@40->printf_ulong#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_ulong.format_zero_padding
    // [1399] phi printf_ulong::format_min_length#10 = 0 [phi:rom_flash::@40->printf_ulong#1] -- vbuz1=vbuc1 
    sta.z printf_ulong.format_min_length
    // [1399] phi printf_ulong::format_radix#10 = DECIMAL [phi:rom_flash::@40->printf_ulong#2] -- vbuxx=vbuc1 
    ldx #DECIMAL
    // [1399] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#6 [phi:rom_flash::@40->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1450] phi from rom_flash::@40 to rom_flash::@41 [phi:rom_flash::@40->rom_flash::@41]
    // rom_flash::@41
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1451] call printf_str
    // [987] phi from rom_flash::@41 to printf_str [phi:rom_flash::@41->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:rom_flash::@41->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = rom_flash::s6 [phi:rom_flash::@41->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@42
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1452] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1453] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_FLASHING, info_text)
    // [1455] display_info_rom::rom_chip#3 = rom_flash::rom_chip#0 -- vbuz1=vbum2 
    lda rom_chip
    sta.z display_info_rom.rom_chip
    // [1456] call display_info_rom
    // [1199] phi from rom_flash::@42 to display_info_rom [phi:rom_flash::@42->display_info_rom]
    // [1199] phi display_info_rom::info_text#16 = info_text [phi:rom_flash::@42->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1199] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#3 [phi:rom_flash::@42->display_info_rom#1] -- register_copy 
    // [1199] phi display_info_rom::info_status#16 = STATUS_FLASHING [phi:rom_flash::@42->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHING
    sta display_info_rom.info_status
    jsr display_info_rom
    // [1418] phi from rom_flash::@42 to rom_flash::@1 [phi:rom_flash::@42->rom_flash::@1]
    // [1418] phi rom_flash::y_sector#13 = rom_flash::y_sector#18 [phi:rom_flash::@42->rom_flash::@1#0] -- register_copy 
    // [1418] phi rom_flash::x_sector#10 = rom_flash::x_sector#20 [phi:rom_flash::@42->rom_flash::@1#1] -- register_copy 
    // [1418] phi rom_flash::flash_errors#10 = rom_flash::flash_errors#13 [phi:rom_flash::@42->rom_flash::@1#2] -- register_copy 
    // [1418] phi rom_flash::ram_address_sector#11 = rom_flash::ram_address_sector#15 [phi:rom_flash::@42->rom_flash::@1#3] -- register_copy 
    // [1418] phi rom_flash::bram_bank_sector#14 = rom_flash::bram_bank_sector#12 [phi:rom_flash::@42->rom_flash::@1#4] -- register_copy 
    // [1418] phi rom_flash::rom_address_sector#12 = rom_flash::rom_address_sector#1 [phi:rom_flash::@42->rom_flash::@1#5] -- register_copy 
    jmp __b1
    // [1457] phi from rom_flash::@21 to rom_flash::@5 [phi:rom_flash::@21->rom_flash::@5]
  __b3:
    // [1457] phi rom_flash::retries#12 = 0 [phi:rom_flash::@21->rom_flash::@5#0] -- vbuz1=vbuc1 
    lda #0
    sta.z retries
    // [1457] phi rom_flash::flash_errors_sector#11 = 0 [phi:rom_flash::@21->rom_flash::@5#1] -- vwuz1=vwuc1 
    sta.z flash_errors_sector
    sta.z flash_errors_sector+1
    // [1457] phi from rom_flash::@43 to rom_flash::@5 [phi:rom_flash::@43->rom_flash::@5]
    // [1457] phi rom_flash::retries#12 = rom_flash::retries#1 [phi:rom_flash::@43->rom_flash::@5#0] -- register_copy 
    // [1457] phi rom_flash::flash_errors_sector#11 = rom_flash::flash_errors_sector#10 [phi:rom_flash::@43->rom_flash::@5#1] -- register_copy 
    // rom_flash::@5
  __b5:
    // rom_sector_erase(rom_address_sector)
    // [1458] rom_sector_erase::address#0 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_sector_erase.address
    lda rom_address_sector+1
    sta.z rom_sector_erase.address+1
    lda rom_address_sector+2
    sta.z rom_sector_erase.address+2
    lda rom_address_sector+3
    sta.z rom_sector_erase.address+3
    // [1459] call rom_sector_erase
    // [2425] phi from rom_flash::@5 to rom_sector_erase [phi:rom_flash::@5->rom_sector_erase]
    jsr rom_sector_erase
    // rom_flash::@22
    // unsigned long rom_sector_boundary = rom_address_sector + ROM_SECTOR
    // [1460] rom_flash::rom_sector_boundary#0 = rom_flash::rom_address_sector#12 + $1000 -- vdum1=vdum2_plus_vwuc1 
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
    // [1461] gotoxy::x#28 = rom_flash::x_sector#10 -- vbuxx=vbuz1 
    ldx.z x_sector
    // [1462] gotoxy::y#28 = rom_flash::y_sector#13 -- vbuyy=vbuz1 
    ldy.z y_sector
    // [1463] call gotoxy
    // [718] phi from rom_flash::@22 to gotoxy [phi:rom_flash::@22->gotoxy]
    // [718] phi gotoxy::y#30 = gotoxy::y#28 [phi:rom_flash::@22->gotoxy#0] -- register_copy 
    // [718] phi gotoxy::x#30 = gotoxy::x#28 [phi:rom_flash::@22->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1464] phi from rom_flash::@22 to rom_flash::@23 [phi:rom_flash::@22->rom_flash::@23]
    // rom_flash::@23
    // printf("........")
    // [1465] call printf_str
    // [987] phi from rom_flash::@23 to printf_str [phi:rom_flash::@23->printf_str]
    // [987] phi printf_str::putc#73 = &cputc [phi:rom_flash::@23->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = rom_flash::s1 [phi:rom_flash::@23->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@24
    // [1466] rom_flash::rom_address#26 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_address
    lda rom_address_sector+1
    sta.z rom_address+1
    lda rom_address_sector+2
    sta.z rom_address+2
    lda rom_address_sector+3
    sta.z rom_address+3
    // [1467] rom_flash::ram_address#26 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z ram_address
    lda.z ram_address_sector+1
    sta.z ram_address+1
    // [1468] rom_flash::x#26 = rom_flash::x_sector#10 -- vbuz1=vbuz2 
    lda.z x_sector
    sta.z x
    // [1469] phi from rom_flash::@10 rom_flash::@24 to rom_flash::@6 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6]
    // [1469] phi rom_flash::x#10 = rom_flash::x#1 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#0] -- register_copy 
    // [1469] phi rom_flash::ram_address#10 = rom_flash::ram_address#1 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#1] -- register_copy 
    // [1469] phi rom_flash::flash_errors_sector#10 = rom_flash::flash_errors_sector#8 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#2] -- register_copy 
    // [1469] phi rom_flash::rom_address#11 = rom_flash::rom_address#1 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#3] -- register_copy 
    // rom_flash::@6
  __b6:
    // while (rom_address < rom_sector_boundary)
    // [1470] if(rom_flash::rom_address#11<rom_flash::rom_sector_boundary#0) goto rom_flash::@7 -- vduz1_lt_vdum2_then_la1 
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
    // [1471] rom_flash::retries#1 = ++ rom_flash::retries#12 -- vbuz1=_inc_vbuz1 
    inc.z retries
    // while (flash_errors_sector && retries <= 3)
    // [1472] if(0==rom_flash::flash_errors_sector#10) goto rom_flash::@12 -- 0_eq_vwuz1_then_la1 
    lda.z flash_errors_sector
    ora.z flash_errors_sector+1
    beq __b12
    // rom_flash::@43
    // [1473] if(rom_flash::retries#1<3+1) goto rom_flash::@5 -- vbuz1_lt_vbuc1_then_la1 
    lda.z retries
    cmp #3+1
    bcs !__b5+
    jmp __b5
  !__b5:
    // rom_flash::@12
  __b12:
    // flash_errors += flash_errors_sector
    // [1474] rom_flash::flash_errors#1 = rom_flash::flash_errors#10 + rom_flash::flash_errors_sector#10 -- vduz1=vduz1_plus_vwuz2 
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
    // [1475] printf_ulong::uvalue#5 = rom_flash::flash_errors_sector#10 + rom_flash::flash_errors#10 -- vduz1=vwuz2_plus_vduz3 
    lda.z flash_errors
    clc
    adc.z flash_errors_sector
    sta.z printf_ulong.uvalue_1
    lda.z flash_errors+1
    adc.z flash_errors_sector+1
    sta.z printf_ulong.uvalue_1+1
    lda.z flash_errors+2
    adc #0
    sta.z printf_ulong.uvalue_1+2
    lda.z flash_errors+3
    adc #0
    sta.z printf_ulong.uvalue_1+3
    // [1476] call snprintf_init
    // [982] phi from rom_flash::@7 to snprintf_init [phi:rom_flash::@7->snprintf_init]
    // [982] phi snprintf_init::s#27 = info_text [phi:rom_flash::@7->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1477] phi from rom_flash::@7 to rom_flash::@25 [phi:rom_flash::@7->rom_flash::@25]
    // rom_flash::@25
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1478] call printf_str
    // [987] phi from rom_flash::@25 to printf_str [phi:rom_flash::@25->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:rom_flash::@25->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = rom_flash::s2 [phi:rom_flash::@25->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@26
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1479] printf_uchar::uvalue#11 = rom_flash::bram_bank_sector#14 -- vbuxx=vbuz1 
    ldx.z bram_bank_sector
    // [1480] call printf_uchar
    // [1165] phi from rom_flash::@26 to printf_uchar [phi:rom_flash::@26->printf_uchar]
    // [1165] phi printf_uchar::format_zero_padding#14 = 1 [phi:rom_flash::@26->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1165] phi printf_uchar::format_min_length#14 = 2 [phi:rom_flash::@26->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [1165] phi printf_uchar::putc#14 = &snputc [phi:rom_flash::@26->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1165] phi printf_uchar::format_radix#14 = HEXADECIMAL [phi:rom_flash::@26->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #HEXADECIMAL
    // [1165] phi printf_uchar::uvalue#14 = printf_uchar::uvalue#11 [phi:rom_flash::@26->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1481] phi from rom_flash::@26 to rom_flash::@27 [phi:rom_flash::@26->rom_flash::@27]
    // rom_flash::@27
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1482] call printf_str
    // [987] phi from rom_flash::@27 to printf_str [phi:rom_flash::@27->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:rom_flash::@27->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = s3 [phi:rom_flash::@27->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@28
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1483] printf_uint::uvalue#11 = (unsigned int)rom_flash::ram_address_sector#11 -- vwuz1=vwuz2 
    lda.z ram_address_sector
    sta.z printf_uint.uvalue
    lda.z ram_address_sector+1
    sta.z printf_uint.uvalue+1
    // [1484] call printf_uint
    // [996] phi from rom_flash::@28 to printf_uint [phi:rom_flash::@28->printf_uint]
    // [996] phi printf_uint::format_zero_padding#15 = 1 [phi:rom_flash::@28->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [996] phi printf_uint::format_min_length#15 = 4 [phi:rom_flash::@28->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [996] phi printf_uint::format_radix#15 = HEXADECIMAL [phi:rom_flash::@28->printf_uint#2] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [996] phi printf_uint::uvalue#15 = printf_uint::uvalue#11 [phi:rom_flash::@28->printf_uint#3] -- register_copy 
    jsr printf_uint
    // [1485] phi from rom_flash::@28 to rom_flash::@29 [phi:rom_flash::@28->rom_flash::@29]
    // rom_flash::@29
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1486] call printf_str
    // [987] phi from rom_flash::@29 to printf_str [phi:rom_flash::@29->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:rom_flash::@29->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = rom_flash::s4 [phi:rom_flash::@29->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@30
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1487] printf_ulong::uvalue#4 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z printf_ulong.uvalue
    lda rom_address_sector+1
    sta.z printf_ulong.uvalue+1
    lda rom_address_sector+2
    sta.z printf_ulong.uvalue+2
    lda rom_address_sector+3
    sta.z printf_ulong.uvalue+3
    // [1488] call printf_ulong
    // [1399] phi from rom_flash::@30 to printf_ulong [phi:rom_flash::@30->printf_ulong]
    // [1399] phi printf_ulong::format_zero_padding#10 = 1 [phi:rom_flash::@30->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1399] phi printf_ulong::format_min_length#10 = 5 [phi:rom_flash::@30->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1399] phi printf_ulong::format_radix#10 = HEXADECIMAL [phi:rom_flash::@30->printf_ulong#2] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [1399] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#4 [phi:rom_flash::@30->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1489] phi from rom_flash::@30 to rom_flash::@31 [phi:rom_flash::@30->rom_flash::@31]
    // rom_flash::@31
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1490] call printf_str
    // [987] phi from rom_flash::@31 to printf_str [phi:rom_flash::@31->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:rom_flash::@31->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = rom_flash::s5 [phi:rom_flash::@31->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@32
    // [1491] printf_ulong::uvalue#16 = printf_ulong::uvalue#5 -- vduz1=vduz2 
    lda.z printf_ulong.uvalue_1
    sta.z printf_ulong.uvalue
    lda.z printf_ulong.uvalue_1+1
    sta.z printf_ulong.uvalue+1
    lda.z printf_ulong.uvalue_1+2
    sta.z printf_ulong.uvalue+2
    lda.z printf_ulong.uvalue_1+3
    sta.z printf_ulong.uvalue+3
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1492] call printf_ulong
    // [1399] phi from rom_flash::@32 to printf_ulong [phi:rom_flash::@32->printf_ulong]
    // [1399] phi printf_ulong::format_zero_padding#10 = 0 [phi:rom_flash::@32->printf_ulong#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_ulong.format_zero_padding
    // [1399] phi printf_ulong::format_min_length#10 = 0 [phi:rom_flash::@32->printf_ulong#1] -- vbuz1=vbuc1 
    sta.z printf_ulong.format_min_length
    // [1399] phi printf_ulong::format_radix#10 = DECIMAL [phi:rom_flash::@32->printf_ulong#2] -- vbuxx=vbuc1 
    ldx #DECIMAL
    // [1399] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#16 [phi:rom_flash::@32->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1493] phi from rom_flash::@32 to rom_flash::@33 [phi:rom_flash::@32->rom_flash::@33]
    // rom_flash::@33
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1494] call printf_str
    // [987] phi from rom_flash::@33 to printf_str [phi:rom_flash::@33->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:rom_flash::@33->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = rom_flash::s6 [phi:rom_flash::@33->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@34
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1495] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1496] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1498] call display_action_text
    // [1176] phi from rom_flash::@34 to display_action_text [phi:rom_flash::@34->display_action_text]
    // [1176] phi display_action_text::info_text#19 = info_text [phi:rom_flash::@34->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // rom_flash::@35
    // unsigned long written_bytes = rom_write(bram_bank, (ram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1499] rom_write::flash_ram_bank#0 = rom_flash::bram_bank_sector#14 -- vbuxx=vbuz1 
    ldx.z bram_bank_sector
    // [1500] rom_write::flash_ram_address#1 = rom_flash::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_write.flash_ram_address
    lda.z ram_address+1
    sta.z rom_write.flash_ram_address+1
    // [1501] rom_write::flash_rom_address#1 = rom_flash::rom_address#11 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_write.flash_rom_address
    lda.z rom_address+1
    sta.z rom_write.flash_rom_address+1
    lda.z rom_address+2
    sta.z rom_write.flash_rom_address+2
    lda.z rom_address+3
    sta.z rom_write.flash_rom_address+3
    // [1502] call rom_write
    jsr rom_write
    // rom_flash::@36
    // rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1503] rom_compare::bank_ram#2 = rom_flash::bram_bank_sector#14 -- vbuxx=vbuz1 
    ldx.z bram_bank_sector
    // [1504] rom_compare::ptr_ram#3 = rom_flash::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_compare.ptr_ram
    lda.z ram_address+1
    sta.z rom_compare.ptr_ram+1
    // [1505] rom_compare::rom_compare_address#2 = rom_flash::rom_address#11 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_compare.rom_compare_address
    lda.z rom_address+1
    sta.z rom_compare.rom_compare_address+1
    lda.z rom_address+2
    sta.z rom_compare.rom_compare_address+2
    lda.z rom_address+3
    sta.z rom_compare.rom_compare_address+3
    // [1506] call rom_compare
    // [2369] phi from rom_flash::@36 to rom_compare [phi:rom_flash::@36->rom_compare]
    // [2369] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#3 [phi:rom_flash::@36->rom_compare#0] -- register_copy 
    // [2369] phi rom_compare::rom_compare_size#11 = ROM_PROGRESS_CELL [phi:rom_flash::@36->rom_compare#1] -- vwuz1=vwuc1 
    lda #<ROM_PROGRESS_CELL
    sta.z rom_compare.rom_compare_size
    lda #>ROM_PROGRESS_CELL
    sta.z rom_compare.rom_compare_size+1
    // [2369] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#2 [phi:rom_flash::@36->rom_compare#2] -- register_copy 
    // [2369] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#2 [phi:rom_flash::@36->rom_compare#3] -- register_copy 
    jsr rom_compare
    // rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1507] rom_compare::return#4 = rom_compare::equal_bytes#2
    // rom_flash::@37
    // equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1508] rom_flash::equal_bytes#1 = rom_compare::return#4 -- vwuz1=vwuz2 
    lda.z rom_compare.return
    sta.z equal_bytes_1
    lda.z rom_compare.return+1
    sta.z equal_bytes_1+1
    // gotoxy(x, y)
    // [1509] gotoxy::x#29 = rom_flash::x#10 -- vbuxx=vbuz1 
    ldx.z x
    // [1510] gotoxy::y#29 = rom_flash::y_sector#13 -- vbuyy=vbuz1 
    ldy.z y_sector
    // [1511] call gotoxy
    // [718] phi from rom_flash::@37 to gotoxy [phi:rom_flash::@37->gotoxy]
    // [718] phi gotoxy::y#30 = gotoxy::y#29 [phi:rom_flash::@37->gotoxy#0] -- register_copy 
    // [718] phi gotoxy::x#30 = gotoxy::x#29 [phi:rom_flash::@37->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_flash::@38
    // if (equal_bytes != ROM_PROGRESS_CELL)
    // [1512] if(rom_flash::equal_bytes#1!=ROM_PROGRESS_CELL) goto rom_flash::@9 -- vwuz1_neq_vwuc1_then_la1 
    lda.z equal_bytes_1+1
    cmp #>ROM_PROGRESS_CELL
    bne __b9
    lda.z equal_bytes_1
    cmp #<ROM_PROGRESS_CELL
    bne __b9
    // rom_flash::@11
    // cputcxy(x,y,'+')
    // [1513] cputcxy::x#14 = rom_flash::x#10 -- vbuxx=vbuz1 
    ldx.z x
    // [1514] cputcxy::y#14 = rom_flash::y_sector#13 -- vbuyy=vbuz1 
    ldy.z y_sector
    // [1515] call cputcxy
    // [1986] phi from rom_flash::@11 to cputcxy [phi:rom_flash::@11->cputcxy]
    // [1986] phi cputcxy::c#15 = '+' [phi:rom_flash::@11->cputcxy#0] -- vbuz1=vbuc1 
    lda #'+'
    sta.z cputcxy.c
    // [1986] phi cputcxy::y#15 = cputcxy::y#14 [phi:rom_flash::@11->cputcxy#1] -- register_copy 
    // [1986] phi cputcxy::x#15 = cputcxy::x#14 [phi:rom_flash::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [1516] phi from rom_flash::@11 rom_flash::@39 to rom_flash::@10 [phi:rom_flash::@11/rom_flash::@39->rom_flash::@10]
    // [1516] phi rom_flash::flash_errors_sector#8 = rom_flash::flash_errors_sector#10 [phi:rom_flash::@11/rom_flash::@39->rom_flash::@10#0] -- register_copy 
    // rom_flash::@10
  __b10:
    // ram_address += ROM_PROGRESS_CELL
    // [1517] rom_flash::ram_address#1 = rom_flash::ram_address#10 + ROM_PROGRESS_CELL -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address
    clc
    adc #<ROM_PROGRESS_CELL
    sta.z ram_address
    lda.z ram_address+1
    adc #>ROM_PROGRESS_CELL
    sta.z ram_address+1
    // rom_address += ROM_PROGRESS_CELL
    // [1518] rom_flash::rom_address#1 = rom_flash::rom_address#11 + ROM_PROGRESS_CELL -- vduz1=vduz1_plus_vwuc1 
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
    // [1519] rom_flash::x#1 = ++ rom_flash::x#10 -- vbuz1=_inc_vbuz1 
    inc.z x
    jmp __b6
    // rom_flash::@9
  __b9:
    // cputcxy(x,y,'!')
    // [1520] cputcxy::x#13 = rom_flash::x#10 -- vbuxx=vbuz1 
    ldx.z x
    // [1521] cputcxy::y#13 = rom_flash::y_sector#13 -- vbuyy=vbuz1 
    ldy.z y_sector
    // [1522] call cputcxy
    // [1986] phi from rom_flash::@9 to cputcxy [phi:rom_flash::@9->cputcxy]
    // [1986] phi cputcxy::c#15 = '!' [phi:rom_flash::@9->cputcxy#0] -- vbuz1=vbuc1 
    lda #'!'
    sta.z cputcxy.c
    // [1986] phi cputcxy::y#15 = cputcxy::y#13 [phi:rom_flash::@9->cputcxy#1] -- register_copy 
    // [1986] phi cputcxy::x#15 = cputcxy::x#13 [phi:rom_flash::@9->cputcxy#2] -- register_copy 
    jsr cputcxy
    // rom_flash::@39
    // flash_errors_sector++;
    // [1523] rom_flash::flash_errors_sector#1 = ++ rom_flash::flash_errors_sector#10 -- vwuz1=_inc_vwuz1 
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
    .label rom_chip = fclose.sp
    rom_bank_start: .byte 0
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
// __zp($79) unsigned int smc_flash(__mem() unsigned int smc_bytes_total)
smc_flash: {
    .label smc_bootloader_start = $b0
    .label return = $79
    .label smc_bootloader_not_activated1 = $29
    // Waiting a bit to ensure the bootloader is activated.
    .label smc_bootloader_activation_countdown = $75
    // Waiting a bit to ensure the bootloader is activated.
    .label smc_bootloader_activation_countdown_1 = $50
    .label smc_bootloader_not_activated = $29
    .label smc_ram_ptr = $ab
    .label smc_package_flashed = $3c
    .label smc_commit_result = $29
    .label smc_bytes_flashed = $79
    .label smc_row_bytes = $59
    .label smc_attempts_total = $5f
    // display_action_progress("To start the SMC update, do the below action ...")
    // [1525] call display_action_progress
    // [812] phi from smc_flash to display_action_progress [phi:smc_flash->display_action_progress]
    // [812] phi display_action_progress::info_text#15 = smc_flash::info_text [phi:smc_flash->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // smc_flash::@25
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [1526] smc_flash::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [1527] smc_flash::cx16_k_i2c_write_byte1_offset = $8f -- vbum1=vbuc1 
    lda #$8f
    sta cx16_k_i2c_write_byte1_offset
    // [1528] smc_flash::cx16_k_i2c_write_byte1_value = $31 -- vbum1=vbuc1 
    lda #$31
    sta cx16_k_i2c_write_byte1_value
    // smc_flash::cx16_k_i2c_write_byte1
    // unsigned char result
    // [1529] smc_flash::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
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
    // [1531] smc_flash::cx16_k_i2c_write_byte1_return#0 = smc_flash::cx16_k_i2c_write_byte1_result -- vbuaa=vbum1 
    lda cx16_k_i2c_write_byte1_result
    // smc_flash::cx16_k_i2c_write_byte1_@return
    // }
    // [1532] smc_flash::cx16_k_i2c_write_byte1_return#1 = smc_flash::cx16_k_i2c_write_byte1_return#0
    // smc_flash::@22
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [1533] smc_flash::smc_bootloader_start#0 = smc_flash::cx16_k_i2c_write_byte1_return#1 -- vbuz1=vbuaa 
    sta.z smc_bootloader_start
    // if(smc_bootloader_start)
    // [1534] if(0==smc_flash::smc_bootloader_start#0) goto smc_flash::@3 -- 0_eq_vbuz1_then_la1 
    beq __b6
    // [1535] phi from smc_flash::@22 to smc_flash::@2 [phi:smc_flash::@22->smc_flash::@2]
    // smc_flash::@2
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1536] call snprintf_init
    // [982] phi from smc_flash::@2 to snprintf_init [phi:smc_flash::@2->snprintf_init]
    // [982] phi snprintf_init::s#27 = info_text [phi:smc_flash::@2->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1537] phi from smc_flash::@2 to smc_flash::@26 [phi:smc_flash::@2->smc_flash::@26]
    // smc_flash::@26
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1538] call printf_str
    // [987] phi from smc_flash::@26 to printf_str [phi:smc_flash::@26->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:smc_flash::@26->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = smc_flash::s [phi:smc_flash::@26->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@27
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1539] printf_uchar::uvalue#4 = smc_flash::smc_bootloader_start#0 -- vbuxx=vbuz1 
    ldx.z smc_bootloader_start
    // [1540] call printf_uchar
    // [1165] phi from smc_flash::@27 to printf_uchar [phi:smc_flash::@27->printf_uchar]
    // [1165] phi printf_uchar::format_zero_padding#14 = 0 [phi:smc_flash::@27->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1165] phi printf_uchar::format_min_length#14 = 0 [phi:smc_flash::@27->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1165] phi printf_uchar::putc#14 = &snputc [phi:smc_flash::@27->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1165] phi printf_uchar::format_radix#14 = HEXADECIMAL [phi:smc_flash::@27->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #HEXADECIMAL
    // [1165] phi printf_uchar::uvalue#14 = printf_uchar::uvalue#4 [phi:smc_flash::@27->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // smc_flash::@28
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1541] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1542] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1544] call display_action_text
    // [1176] phi from smc_flash::@28 to display_action_text [phi:smc_flash::@28->display_action_text]
    // [1176] phi display_action_text::info_text#19 = info_text [phi:smc_flash::@28->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_flash::@29
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [1545] smc_flash::cx16_k_i2c_write_byte2_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte2_device
    // [1546] smc_flash::cx16_k_i2c_write_byte2_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte2_offset
    // [1547] smc_flash::cx16_k_i2c_write_byte2_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte2_value
    // smc_flash::cx16_k_i2c_write_byte2
    // unsigned char result
    // [1548] smc_flash::cx16_k_i2c_write_byte2_result = 0 -- vbum1=vbuc1 
    sta cx16_k_i2c_write_byte2_result
    // asm
    // asm { ldxdevice ldyoffset ldavalue stzresult jsrCX16_I2C_WRITE_BYTE rolresult  }
    ldx cx16_k_i2c_write_byte2_device
    ldy cx16_k_i2c_write_byte2_offset
    lda cx16_k_i2c_write_byte2_value
    stz cx16_k_i2c_write_byte2_result
    jsr CX16_I2C_WRITE_BYTE
    rol cx16_k_i2c_write_byte2_result
    // [1550] phi from smc_flash::@47 smc_flash::@59 smc_flash::cx16_k_i2c_write_byte2 to smc_flash::@return [phi:smc_flash::@47/smc_flash::@59/smc_flash::cx16_k_i2c_write_byte2->smc_flash::@return]
  __b2:
    // [1550] phi smc_flash::return#1 = 0 [phi:smc_flash::@47/smc_flash::@59/smc_flash::cx16_k_i2c_write_byte2->smc_flash::@return#0] -- vwuz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // smc_flash::@return
    // }
    // [1551] return 
    rts
    // [1552] phi from smc_flash::@22 to smc_flash::@3 [phi:smc_flash::@22->smc_flash::@3]
  __b6:
    // [1552] phi smc_flash::smc_bootloader_activation_countdown#10 = $80 [phi:smc_flash::@22->smc_flash::@3#0] -- vbuz1=vbuc1 
    lda #$80
    sta.z smc_bootloader_activation_countdown
    // smc_flash::@3
  __b3:
    // while(smc_bootloader_activation_countdown)
    // [1553] if(0!=smc_flash::smc_bootloader_activation_countdown#10) goto smc_flash::@4 -- 0_neq_vbuz1_then_la1 
    lda.z smc_bootloader_activation_countdown
    beq !__b4+
    jmp __b4
  !__b4:
    // [1554] phi from smc_flash::@3 smc_flash::@30 to smc_flash::@7 [phi:smc_flash::@3/smc_flash::@30->smc_flash::@7]
  __b9:
    // [1554] phi smc_flash::smc_bootloader_activation_countdown#12 = $a [phi:smc_flash::@3/smc_flash::@30->smc_flash::@7#0] -- vbuz1=vbuc1 
    lda #$a
    sta.z smc_bootloader_activation_countdown_1
    // smc_flash::@7
  __b7:
    // while(smc_bootloader_activation_countdown)
    // [1555] if(0!=smc_flash::smc_bootloader_activation_countdown#12) goto smc_flash::@8 -- 0_neq_vbuz1_then_la1 
    lda.z smc_bootloader_activation_countdown_1
    beq !__b8+
    jmp __b8
  !__b8:
    // smc_flash::@9
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1556] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1557] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [1558] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [1559] cx16_k_i2c_read_byte::return#12 = cx16_k_i2c_read_byte::return#1
    // smc_flash::@42
    // smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1560] smc_flash::smc_bootloader_not_activated#1 = cx16_k_i2c_read_byte::return#12
    // if(smc_bootloader_not_activated)
    // [1561] if(0==smc_flash::smc_bootloader_not_activated#1) goto smc_flash::@1 -- 0_eq_vwuz1_then_la1 
    lda.z smc_bootloader_not_activated
    ora.z smc_bootloader_not_activated+1
    beq __b1
    // [1562] phi from smc_flash::@42 to smc_flash::@10 [phi:smc_flash::@42->smc_flash::@10]
    // smc_flash::@10
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1563] call snprintf_init
    // [982] phi from smc_flash::@10 to snprintf_init [phi:smc_flash::@10->snprintf_init]
    // [982] phi snprintf_init::s#27 = info_text [phi:smc_flash::@10->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1564] phi from smc_flash::@10 to smc_flash::@45 [phi:smc_flash::@10->smc_flash::@45]
    // smc_flash::@45
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1565] call printf_str
    // [987] phi from smc_flash::@45 to printf_str [phi:smc_flash::@45->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:smc_flash::@45->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = smc_flash::s5 [phi:smc_flash::@45->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@46
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1566] printf_uint::uvalue#4 = smc_flash::smc_bootloader_not_activated#1
    // [1567] call printf_uint
    // [996] phi from smc_flash::@46 to printf_uint [phi:smc_flash::@46->printf_uint]
    // [996] phi printf_uint::format_zero_padding#15 = 0 [phi:smc_flash::@46->printf_uint#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uint.format_zero_padding
    // [996] phi printf_uint::format_min_length#15 = 0 [phi:smc_flash::@46->printf_uint#1] -- vbuz1=vbuc1 
    sta.z printf_uint.format_min_length
    // [996] phi printf_uint::format_radix#15 = HEXADECIMAL [phi:smc_flash::@46->printf_uint#2] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [996] phi printf_uint::uvalue#15 = printf_uint::uvalue#4 [phi:smc_flash::@46->printf_uint#3] -- register_copy 
    jsr printf_uint
    // smc_flash::@47
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1568] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1569] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1571] call display_action_text
    // [1176] phi from smc_flash::@47 to display_action_text [phi:smc_flash::@47->display_action_text]
    // [1176] phi display_action_text::info_text#19 = info_text [phi:smc_flash::@47->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    jmp __b2
    // [1572] phi from smc_flash::@42 to smc_flash::@1 [phi:smc_flash::@42->smc_flash::@1]
    // smc_flash::@1
  __b1:
    // display_action_progress("Updating SMC firmware ... (+) Updated")
    // [1573] call display_action_progress
    // [812] phi from smc_flash::@1 to display_action_progress [phi:smc_flash::@1->display_action_progress]
    // [812] phi display_action_progress::info_text#15 = smc_flash::info_text1 [phi:smc_flash::@1->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_action_progress.info_text
    lda #>info_text1
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1574] phi from smc_flash::@1 to smc_flash::@43 [phi:smc_flash::@1->smc_flash::@43]
    // smc_flash::@43
    // textcolor(WHITE)
    // [1575] call textcolor
    // [700] phi from smc_flash::@43 to textcolor [phi:smc_flash::@43->textcolor]
    // [700] phi textcolor::color#18 = WHITE [phi:smc_flash::@43->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [1576] phi from smc_flash::@43 to smc_flash::@44 [phi:smc_flash::@43->smc_flash::@44]
    // smc_flash::@44
    // gotoxy(x, y)
    // [1577] call gotoxy
    // [718] phi from smc_flash::@44 to gotoxy [phi:smc_flash::@44->gotoxy]
    // [718] phi gotoxy::y#30 = PROGRESS_Y [phi:smc_flash::@44->gotoxy#0] -- vbuyy=vbuc1 
    ldy #PROGRESS_Y
    // [718] phi gotoxy::x#30 = PROGRESS_X [phi:smc_flash::@44->gotoxy#1] -- vbuxx=vbuc1 
    ldx #PROGRESS_X
    jsr gotoxy
    // [1578] phi from smc_flash::@44 to smc_flash::@11 [phi:smc_flash::@44->smc_flash::@11]
    // [1578] phi smc_flash::y#31 = PROGRESS_Y [phi:smc_flash::@44->smc_flash::@11#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1578] phi smc_flash::smc_attempts_total#21 = 0 [phi:smc_flash::@44->smc_flash::@11#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z smc_attempts_total
    sta.z smc_attempts_total+1
    // [1578] phi smc_flash::smc_row_bytes#14 = 0 [phi:smc_flash::@44->smc_flash::@11#2] -- vwuz1=vwuc1 
    sta.z smc_row_bytes
    sta.z smc_row_bytes+1
    // [1578] phi smc_flash::smc_ram_ptr#13 = (char *)$7800 [phi:smc_flash::@44->smc_flash::@11#3] -- pbuz1=pbuc1 
    lda #<$7800
    sta.z smc_ram_ptr
    lda #>$7800
    sta.z smc_ram_ptr+1
    // [1578] phi smc_flash::smc_bytes_flashed#16 = 0 [phi:smc_flash::@44->smc_flash::@11#4] -- vwuz1=vwuc1 
    lda #<0
    sta.z smc_bytes_flashed
    sta.z smc_bytes_flashed+1
    // [1578] phi from smc_flash::@13 to smc_flash::@11 [phi:smc_flash::@13->smc_flash::@11]
    // [1578] phi smc_flash::y#31 = smc_flash::y#20 [phi:smc_flash::@13->smc_flash::@11#0] -- register_copy 
    // [1578] phi smc_flash::smc_attempts_total#21 = smc_flash::smc_attempts_total#17 [phi:smc_flash::@13->smc_flash::@11#1] -- register_copy 
    // [1578] phi smc_flash::smc_row_bytes#14 = smc_flash::smc_row_bytes#10 [phi:smc_flash::@13->smc_flash::@11#2] -- register_copy 
    // [1578] phi smc_flash::smc_ram_ptr#13 = smc_flash::smc_ram_ptr#10 [phi:smc_flash::@13->smc_flash::@11#3] -- register_copy 
    // [1578] phi smc_flash::smc_bytes_flashed#16 = smc_flash::smc_bytes_flashed#11 [phi:smc_flash::@13->smc_flash::@11#4] -- register_copy 
    // smc_flash::@11
  __b11:
    // while(smc_bytes_flashed < smc_bytes_total)
    // [1579] if(smc_flash::smc_bytes_flashed#16<smc_flash::smc_bytes_total#0) goto smc_flash::@12 -- vwuz1_lt_vwum2_then_la1 
    lda.z smc_bytes_flashed+1
    cmp smc_bytes_total+1
    bcc __b10
    bne !+
    lda.z smc_bytes_flashed
    cmp smc_bytes_total
    bcc __b10
  !:
    // [1550] phi from smc_flash::@11 to smc_flash::@return [phi:smc_flash::@11->smc_flash::@return]
    // [1550] phi smc_flash::return#1 = smc_flash::smc_bytes_flashed#16 [phi:smc_flash::@11->smc_flash::@return#0] -- register_copy 
    rts
    // [1580] phi from smc_flash::@11 to smc_flash::@12 [phi:smc_flash::@11->smc_flash::@12]
  __b10:
    // [1580] phi smc_flash::y#20 = smc_flash::y#31 [phi:smc_flash::@11->smc_flash::@12#0] -- register_copy 
    // [1580] phi smc_flash::smc_attempts_total#17 = smc_flash::smc_attempts_total#21 [phi:smc_flash::@11->smc_flash::@12#1] -- register_copy 
    // [1580] phi smc_flash::smc_row_bytes#10 = smc_flash::smc_row_bytes#14 [phi:smc_flash::@11->smc_flash::@12#2] -- register_copy 
    // [1580] phi smc_flash::smc_ram_ptr#10 = smc_flash::smc_ram_ptr#13 [phi:smc_flash::@11->smc_flash::@12#3] -- register_copy 
    // [1580] phi smc_flash::smc_bytes_flashed#11 = smc_flash::smc_bytes_flashed#16 [phi:smc_flash::@11->smc_flash::@12#4] -- register_copy 
    // [1580] phi smc_flash::smc_attempts_flashed#19 = 0 [phi:smc_flash::@11->smc_flash::@12#5] -- vbum1=vbuc1 
    lda #0
    sta smc_attempts_flashed
    // [1580] phi smc_flash::smc_package_committed#2 = 0 [phi:smc_flash::@11->smc_flash::@12#6] -- vbum1=vbuc1 
    sta smc_package_committed
    // smc_flash::@12
  __b12:
    // while(!smc_package_committed && smc_attempts_flashed < 10)
    // [1581] if(0!=smc_flash::smc_package_committed#2) goto smc_flash::@13 -- 0_neq_vbum1_then_la1 
    lda smc_package_committed
    bne __b13
    // smc_flash::@60
    // [1582] if(smc_flash::smc_attempts_flashed#19<$a) goto smc_flash::@14 -- vbum1_lt_vbuc1_then_la1 
    lda smc_attempts_flashed
    cmp #$a
    bcc __b16
    // smc_flash::@13
  __b13:
    // if(smc_attempts_flashed >= 10)
    // [1583] if(smc_flash::smc_attempts_flashed#19<$a) goto smc_flash::@11 -- vbum1_lt_vbuc1_then_la1 
    lda smc_attempts_flashed
    cmp #$a
    bcc __b11
    // [1584] phi from smc_flash::@13 to smc_flash::@21 [phi:smc_flash::@13->smc_flash::@21]
    // smc_flash::@21
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1585] call snprintf_init
    // [982] phi from smc_flash::@21 to snprintf_init [phi:smc_flash::@21->snprintf_init]
    // [982] phi snprintf_init::s#27 = info_text [phi:smc_flash::@21->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1586] phi from smc_flash::@21 to smc_flash::@57 [phi:smc_flash::@21->smc_flash::@57]
    // smc_flash::@57
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1587] call printf_str
    // [987] phi from smc_flash::@57 to printf_str [phi:smc_flash::@57->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:smc_flash::@57->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = smc_flash::s10 [phi:smc_flash::@57->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@58
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1588] printf_uint::uvalue#8 = smc_flash::smc_bytes_flashed#11 -- vwuz1=vwuz2 
    lda.z smc_bytes_flashed
    sta.z printf_uint.uvalue
    lda.z smc_bytes_flashed+1
    sta.z printf_uint.uvalue+1
    // [1589] call printf_uint
    // [996] phi from smc_flash::@58 to printf_uint [phi:smc_flash::@58->printf_uint]
    // [996] phi printf_uint::format_zero_padding#15 = 1 [phi:smc_flash::@58->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [996] phi printf_uint::format_min_length#15 = 4 [phi:smc_flash::@58->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [996] phi printf_uint::format_radix#15 = HEXADECIMAL [phi:smc_flash::@58->printf_uint#2] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [996] phi printf_uint::uvalue#15 = printf_uint::uvalue#8 [phi:smc_flash::@58->printf_uint#3] -- register_copy 
    jsr printf_uint
    // smc_flash::@59
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1590] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1591] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1593] call display_action_text
    // [1176] phi from smc_flash::@59 to display_action_text [phi:smc_flash::@59->display_action_text]
    // [1176] phi display_action_text::info_text#19 = info_text [phi:smc_flash::@59->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    jmp __b2
    // [1594] phi from smc_flash::@60 to smc_flash::@14 [phi:smc_flash::@60->smc_flash::@14]
  __b16:
    // [1594] phi smc_flash::smc_bytes_checksum#2 = 0 [phi:smc_flash::@60->smc_flash::@14#0] -- vbum1=vbuc1 
    lda #0
    sta smc_bytes_checksum
    // [1594] phi smc_flash::smc_ram_ptr#12 = smc_flash::smc_ram_ptr#10 [phi:smc_flash::@60->smc_flash::@14#1] -- register_copy 
    // [1594] phi smc_flash::smc_package_flashed#2 = 0 [phi:smc_flash::@60->smc_flash::@14#2] -- vwuz1=vwuc1 
    sta.z smc_package_flashed
    sta.z smc_package_flashed+1
    // smc_flash::@14
  __b14:
    // while(smc_package_flashed < SMC_PROGRESS_CELL)
    // [1595] if(smc_flash::smc_package_flashed#2<SMC_PROGRESS_CELL) goto smc_flash::@15 -- vwuz1_lt_vbuc1_then_la1 
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
    // [1596] smc_flash::$26 = smc_flash::smc_bytes_checksum#2 ^ $ff -- vbuaa=vbum1_bxor_vbuc1 
    lda #$ff
    eor smc_bytes_checksum
    // (smc_bytes_checksum ^ 0xFF)+1
    // [1597] smc_flash::$27 = smc_flash::$26 + 1 -- vbuxx=vbuaa_plus_1 
    tax
    inx
    // unsigned char smc_checksum_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, (smc_bytes_checksum ^ 0xFF)+1)
    // [1598] smc_flash::cx16_k_i2c_write_byte4_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte4_device
    // [1599] smc_flash::cx16_k_i2c_write_byte4_offset = $80 -- vbum1=vbuc1 
    lda #$80
    sta cx16_k_i2c_write_byte4_offset
    // [1600] smc_flash::cx16_k_i2c_write_byte4_value = smc_flash::$27 -- vbum1=vbuxx 
    stx cx16_k_i2c_write_byte4_value
    // smc_flash::cx16_k_i2c_write_byte4
    // unsigned char result
    // [1601] smc_flash::cx16_k_i2c_write_byte4_result = 0 -- vbum1=vbuc1 
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
    // [1603] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1604] cx16_k_i2c_read_byte::offset = $81 -- vbum1=vbuc1 
    lda #$81
    sta cx16_k_i2c_read_byte.offset
    // [1605] call cx16_k_i2c_read_byte
    // Now send the commit command.
    jsr cx16_k_i2c_read_byte
    // [1606] cx16_k_i2c_read_byte::return#13 = cx16_k_i2c_read_byte::return#1
    // smc_flash::@48
    // [1607] smc_flash::smc_commit_result#0 = cx16_k_i2c_read_byte::return#13
    // if(smc_commit_result == 1)
    // [1608] if(smc_flash::smc_commit_result#0==1) goto smc_flash::@18 -- vwuz1_eq_vbuc1_then_la1 
    lda.z smc_commit_result+1
    bne !+
    lda.z smc_commit_result
    cmp #1
    beq __b18
  !:
    // smc_flash::@17
    // smc_ram_ptr -= SMC_PROGRESS_CELL
    // [1609] smc_flash::smc_ram_ptr#2 = smc_flash::smc_ram_ptr#12 - SMC_PROGRESS_CELL -- pbuz1=pbuz1_minus_vbuc1 
    sec
    lda.z smc_ram_ptr
    sbc #SMC_PROGRESS_CELL
    sta.z smc_ram_ptr
    lda.z smc_ram_ptr+1
    sbc #0
    sta.z smc_ram_ptr+1
    // smc_attempts_flashed++;
    // [1610] smc_flash::smc_attempts_flashed#1 = ++ smc_flash::smc_attempts_flashed#19 -- vbum1=_inc_vbum1 
    inc smc_attempts_flashed
    // [1580] phi from smc_flash::@17 to smc_flash::@12 [phi:smc_flash::@17->smc_flash::@12]
    // [1580] phi smc_flash::y#20 = smc_flash::y#20 [phi:smc_flash::@17->smc_flash::@12#0] -- register_copy 
    // [1580] phi smc_flash::smc_attempts_total#17 = smc_flash::smc_attempts_total#17 [phi:smc_flash::@17->smc_flash::@12#1] -- register_copy 
    // [1580] phi smc_flash::smc_row_bytes#10 = smc_flash::smc_row_bytes#10 [phi:smc_flash::@17->smc_flash::@12#2] -- register_copy 
    // [1580] phi smc_flash::smc_ram_ptr#10 = smc_flash::smc_ram_ptr#2 [phi:smc_flash::@17->smc_flash::@12#3] -- register_copy 
    // [1580] phi smc_flash::smc_bytes_flashed#11 = smc_flash::smc_bytes_flashed#11 [phi:smc_flash::@17->smc_flash::@12#4] -- register_copy 
    // [1580] phi smc_flash::smc_attempts_flashed#19 = smc_flash::smc_attempts_flashed#1 [phi:smc_flash::@17->smc_flash::@12#5] -- register_copy 
    // [1580] phi smc_flash::smc_package_committed#2 = smc_flash::smc_package_committed#2 [phi:smc_flash::@17->smc_flash::@12#6] -- register_copy 
    jmp __b12
    // smc_flash::@18
  __b18:
    // if (smc_row_bytes == SMC_PROGRESS_ROW)
    // [1611] if(smc_flash::smc_row_bytes#10!=SMC_PROGRESS_ROW) goto smc_flash::@19 -- vwuz1_neq_vwuc1_then_la1 
    lda.z smc_row_bytes+1
    cmp #>SMC_PROGRESS_ROW
    bne __b19
    lda.z smc_row_bytes
    cmp #<SMC_PROGRESS_ROW
    bne __b19
    // smc_flash::@20
    // gotoxy(x, ++y);
    // [1612] smc_flash::y#1 = ++ smc_flash::y#20 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [1613] gotoxy::y#22 = smc_flash::y#1 -- vbuyy=vbum1 
    ldy y
    // [1614] call gotoxy
    // [718] phi from smc_flash::@20 to gotoxy [phi:smc_flash::@20->gotoxy]
    // [718] phi gotoxy::y#30 = gotoxy::y#22 [phi:smc_flash::@20->gotoxy#0] -- register_copy 
    // [718] phi gotoxy::x#30 = PROGRESS_X [phi:smc_flash::@20->gotoxy#1] -- vbuxx=vbuc1 
    ldx #PROGRESS_X
    jsr gotoxy
    // [1615] phi from smc_flash::@20 to smc_flash::@19 [phi:smc_flash::@20->smc_flash::@19]
    // [1615] phi smc_flash::y#33 = smc_flash::y#1 [phi:smc_flash::@20->smc_flash::@19#0] -- register_copy 
    // [1615] phi smc_flash::smc_row_bytes#4 = 0 [phi:smc_flash::@20->smc_flash::@19#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z smc_row_bytes
    sta.z smc_row_bytes+1
    // [1615] phi from smc_flash::@18 to smc_flash::@19 [phi:smc_flash::@18->smc_flash::@19]
    // [1615] phi smc_flash::y#33 = smc_flash::y#20 [phi:smc_flash::@18->smc_flash::@19#0] -- register_copy 
    // [1615] phi smc_flash::smc_row_bytes#4 = smc_flash::smc_row_bytes#10 [phi:smc_flash::@18->smc_flash::@19#1] -- register_copy 
    // smc_flash::@19
  __b19:
    // cputc('+')
    // [1616] stackpush(char) = '+' -- _stackpushbyte_=vbuc1 
    lda #'+'
    pha
    // [1617] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_bytes_flashed += SMC_PROGRESS_CELL
    // [1619] smc_flash::smc_bytes_flashed#1 = smc_flash::smc_bytes_flashed#11 + SMC_PROGRESS_CELL -- vwuz1=vwuz1_plus_vbuc1 
    lda #SMC_PROGRESS_CELL
    clc
    adc.z smc_bytes_flashed
    sta.z smc_bytes_flashed
    bcc !+
    inc.z smc_bytes_flashed+1
  !:
    // smc_row_bytes += SMC_PROGRESS_CELL
    // [1620] smc_flash::smc_row_bytes#1 = smc_flash::smc_row_bytes#4 + SMC_PROGRESS_CELL -- vwuz1=vwuz1_plus_vbuc1 
    lda #SMC_PROGRESS_CELL
    clc
    adc.z smc_row_bytes
    sta.z smc_row_bytes
    bcc !+
    inc.z smc_row_bytes+1
  !:
    // smc_attempts_total += smc_attempts_flashed
    // [1621] smc_flash::smc_attempts_total#1 = smc_flash::smc_attempts_total#17 + smc_flash::smc_attempts_flashed#19 -- vwuz1=vwuz1_plus_vbum2 
    lda smc_attempts_flashed
    clc
    adc.z smc_attempts_total
    sta.z smc_attempts_total
    bcc !+
    inc.z smc_attempts_total+1
  !:
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1622] call snprintf_init
    // [982] phi from smc_flash::@19 to snprintf_init [phi:smc_flash::@19->snprintf_init]
    // [982] phi snprintf_init::s#27 = info_text [phi:smc_flash::@19->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1623] phi from smc_flash::@19 to smc_flash::@49 [phi:smc_flash::@19->smc_flash::@49]
    // smc_flash::@49
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1624] call printf_str
    // [987] phi from smc_flash::@49 to printf_str [phi:smc_flash::@49->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:smc_flash::@49->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = smc_flash::s6 [phi:smc_flash::@49->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@50
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1625] printf_uint::uvalue#5 = smc_flash::smc_bytes_flashed#1 -- vwuz1=vwuz2 
    lda.z smc_bytes_flashed
    sta.z printf_uint.uvalue
    lda.z smc_bytes_flashed+1
    sta.z printf_uint.uvalue+1
    // [1626] call printf_uint
    // [996] phi from smc_flash::@50 to printf_uint [phi:smc_flash::@50->printf_uint]
    // [996] phi printf_uint::format_zero_padding#15 = 1 [phi:smc_flash::@50->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [996] phi printf_uint::format_min_length#15 = 5 [phi:smc_flash::@50->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [996] phi printf_uint::format_radix#15 = DECIMAL [phi:smc_flash::@50->printf_uint#2] -- vbuxx=vbuc1 
    ldx #DECIMAL
    // [996] phi printf_uint::uvalue#15 = printf_uint::uvalue#5 [phi:smc_flash::@50->printf_uint#3] -- register_copy 
    jsr printf_uint
    // [1627] phi from smc_flash::@50 to smc_flash::@51 [phi:smc_flash::@50->smc_flash::@51]
    // smc_flash::@51
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1628] call printf_str
    // [987] phi from smc_flash::@51 to printf_str [phi:smc_flash::@51->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:smc_flash::@51->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = smc_flash::s7 [phi:smc_flash::@51->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@52
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1629] printf_uint::uvalue#6 = smc_flash::smc_bytes_total#0 -- vwuz1=vwum2 
    lda smc_bytes_total
    sta.z printf_uint.uvalue
    lda smc_bytes_total+1
    sta.z printf_uint.uvalue+1
    // [1630] call printf_uint
    // [996] phi from smc_flash::@52 to printf_uint [phi:smc_flash::@52->printf_uint]
    // [996] phi printf_uint::format_zero_padding#15 = 1 [phi:smc_flash::@52->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [996] phi printf_uint::format_min_length#15 = 5 [phi:smc_flash::@52->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [996] phi printf_uint::format_radix#15 = DECIMAL [phi:smc_flash::@52->printf_uint#2] -- vbuxx=vbuc1 
    ldx #DECIMAL
    // [996] phi printf_uint::uvalue#15 = printf_uint::uvalue#6 [phi:smc_flash::@52->printf_uint#3] -- register_copy 
    jsr printf_uint
    // [1631] phi from smc_flash::@52 to smc_flash::@53 [phi:smc_flash::@52->smc_flash::@53]
    // smc_flash::@53
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1632] call printf_str
    // [987] phi from smc_flash::@53 to printf_str [phi:smc_flash::@53->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:smc_flash::@53->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = smc_flash::s8 [phi:smc_flash::@53->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@54
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1633] printf_uint::uvalue#7 = smc_flash::smc_attempts_total#1 -- vwuz1=vwuz2 
    lda.z smc_attempts_total
    sta.z printf_uint.uvalue
    lda.z smc_attempts_total+1
    sta.z printf_uint.uvalue+1
    // [1634] call printf_uint
    // [996] phi from smc_flash::@54 to printf_uint [phi:smc_flash::@54->printf_uint]
    // [996] phi printf_uint::format_zero_padding#15 = 1 [phi:smc_flash::@54->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [996] phi printf_uint::format_min_length#15 = 2 [phi:smc_flash::@54->printf_uint#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uint.format_min_length
    // [996] phi printf_uint::format_radix#15 = DECIMAL [phi:smc_flash::@54->printf_uint#2] -- vbuxx=vbuc1 
    ldx #DECIMAL
    // [996] phi printf_uint::uvalue#15 = printf_uint::uvalue#7 [phi:smc_flash::@54->printf_uint#3] -- register_copy 
    jsr printf_uint
    // [1635] phi from smc_flash::@54 to smc_flash::@55 [phi:smc_flash::@54->smc_flash::@55]
    // smc_flash::@55
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1636] call printf_str
    // [987] phi from smc_flash::@55 to printf_str [phi:smc_flash::@55->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:smc_flash::@55->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = smc_flash::s9 [phi:smc_flash::@55->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@56
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1637] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1638] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1640] call display_action_text
    // [1176] phi from smc_flash::@56 to display_action_text [phi:smc_flash::@56->display_action_text]
    // [1176] phi display_action_text::info_text#19 = info_text [phi:smc_flash::@56->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1580] phi from smc_flash::@56 to smc_flash::@12 [phi:smc_flash::@56->smc_flash::@12]
    // [1580] phi smc_flash::y#20 = smc_flash::y#33 [phi:smc_flash::@56->smc_flash::@12#0] -- register_copy 
    // [1580] phi smc_flash::smc_attempts_total#17 = smc_flash::smc_attempts_total#1 [phi:smc_flash::@56->smc_flash::@12#1] -- register_copy 
    // [1580] phi smc_flash::smc_row_bytes#10 = smc_flash::smc_row_bytes#1 [phi:smc_flash::@56->smc_flash::@12#2] -- register_copy 
    // [1580] phi smc_flash::smc_ram_ptr#10 = smc_flash::smc_ram_ptr#12 [phi:smc_flash::@56->smc_flash::@12#3] -- register_copy 
    // [1580] phi smc_flash::smc_bytes_flashed#11 = smc_flash::smc_bytes_flashed#1 [phi:smc_flash::@56->smc_flash::@12#4] -- register_copy 
    // [1580] phi smc_flash::smc_attempts_flashed#19 = smc_flash::smc_attempts_flashed#19 [phi:smc_flash::@56->smc_flash::@12#5] -- register_copy 
    // [1580] phi smc_flash::smc_package_committed#2 = 1 [phi:smc_flash::@56->smc_flash::@12#6] -- vbum1=vbuc1 
    lda #1
    sta smc_package_committed
    jmp __b12
    // smc_flash::@15
  __b15:
    // unsigned char smc_byte_upload = *smc_ram_ptr
    // [1641] smc_flash::smc_byte_upload#0 = *smc_flash::smc_ram_ptr#12 -- vbuxx=_deref_pbuz1 
    ldy #0
    lda (smc_ram_ptr),y
    tax
    // smc_ram_ptr++;
    // [1642] smc_flash::smc_ram_ptr#1 = ++ smc_flash::smc_ram_ptr#12 -- pbuz1=_inc_pbuz1 
    inc.z smc_ram_ptr
    bne !+
    inc.z smc_ram_ptr+1
  !:
    // smc_bytes_checksum += smc_byte_upload
    // [1643] smc_flash::smc_bytes_checksum#1 = smc_flash::smc_bytes_checksum#2 + smc_flash::smc_byte_upload#0 -- vbum1=vbum1_plus_vbuxx 
    txa
    clc
    adc smc_bytes_checksum
    sta smc_bytes_checksum
    // unsigned char smc_upload_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, smc_byte_upload)
    // [1644] smc_flash::cx16_k_i2c_write_byte3_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte3_device
    // [1645] smc_flash::cx16_k_i2c_write_byte3_offset = $80 -- vbum1=vbuc1 
    lda #$80
    sta cx16_k_i2c_write_byte3_offset
    // [1646] smc_flash::cx16_k_i2c_write_byte3_value = smc_flash::smc_byte_upload#0 -- vbum1=vbuxx 
    stx cx16_k_i2c_write_byte3_value
    // smc_flash::cx16_k_i2c_write_byte3
    // unsigned char result
    // [1647] smc_flash::cx16_k_i2c_write_byte3_result = 0 -- vbum1=vbuc1 
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
    // [1649] smc_flash::smc_package_flashed#1 = ++ smc_flash::smc_package_flashed#2 -- vwuz1=_inc_vwuz1 
    inc.z smc_package_flashed
    bne !+
    inc.z smc_package_flashed+1
  !:
    // [1594] phi from smc_flash::@23 to smc_flash::@14 [phi:smc_flash::@23->smc_flash::@14]
    // [1594] phi smc_flash::smc_bytes_checksum#2 = smc_flash::smc_bytes_checksum#1 [phi:smc_flash::@23->smc_flash::@14#0] -- register_copy 
    // [1594] phi smc_flash::smc_ram_ptr#12 = smc_flash::smc_ram_ptr#1 [phi:smc_flash::@23->smc_flash::@14#1] -- register_copy 
    // [1594] phi smc_flash::smc_package_flashed#2 = smc_flash::smc_package_flashed#1 [phi:smc_flash::@23->smc_flash::@14#2] -- register_copy 
    jmp __b14
    // [1650] phi from smc_flash::@7 to smc_flash::@8 [phi:smc_flash::@7->smc_flash::@8]
    // smc_flash::@8
  __b8:
    // wait_moment()
    // [1651] call wait_moment
    // [1160] phi from smc_flash::@8 to wait_moment [phi:smc_flash::@8->wait_moment]
    jsr wait_moment
    // [1652] phi from smc_flash::@8 to smc_flash::@36 [phi:smc_flash::@8->smc_flash::@36]
    // smc_flash::@36
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1653] call snprintf_init
    // [982] phi from smc_flash::@36 to snprintf_init [phi:smc_flash::@36->snprintf_init]
    // [982] phi snprintf_init::s#27 = info_text [phi:smc_flash::@36->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1654] phi from smc_flash::@36 to smc_flash::@37 [phi:smc_flash::@36->smc_flash::@37]
    // smc_flash::@37
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1655] call printf_str
    // [987] phi from smc_flash::@37 to printf_str [phi:smc_flash::@37->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:smc_flash::@37->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = smc_flash::s3 [phi:smc_flash::@37->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@38
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1656] printf_uchar::uvalue#6 = smc_flash::smc_bootloader_activation_countdown#12 -- vbuxx=vbuz1 
    ldx.z smc_bootloader_activation_countdown_1
    // [1657] call printf_uchar
    // [1165] phi from smc_flash::@38 to printf_uchar [phi:smc_flash::@38->printf_uchar]
    // [1165] phi printf_uchar::format_zero_padding#14 = 0 [phi:smc_flash::@38->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1165] phi printf_uchar::format_min_length#14 = 0 [phi:smc_flash::@38->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1165] phi printf_uchar::putc#14 = &snputc [phi:smc_flash::@38->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1165] phi printf_uchar::format_radix#14 = DECIMAL [phi:smc_flash::@38->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [1165] phi printf_uchar::uvalue#14 = printf_uchar::uvalue#6 [phi:smc_flash::@38->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1658] phi from smc_flash::@38 to smc_flash::@39 [phi:smc_flash::@38->smc_flash::@39]
    // smc_flash::@39
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1659] call printf_str
    // [987] phi from smc_flash::@39 to printf_str [phi:smc_flash::@39->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:smc_flash::@39->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = s4 [phi:smc_flash::@39->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@40
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1660] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1661] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1663] call display_action_text
    // [1176] phi from smc_flash::@40 to display_action_text [phi:smc_flash::@40->display_action_text]
    // [1176] phi display_action_text::info_text#19 = info_text [phi:smc_flash::@40->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_flash::@41
    // smc_bootloader_activation_countdown--;
    // [1664] smc_flash::smc_bootloader_activation_countdown#3 = -- smc_flash::smc_bootloader_activation_countdown#12 -- vbuz1=_dec_vbuz1 
    dec.z smc_bootloader_activation_countdown_1
    // [1554] phi from smc_flash::@41 to smc_flash::@7 [phi:smc_flash::@41->smc_flash::@7]
    // [1554] phi smc_flash::smc_bootloader_activation_countdown#12 = smc_flash::smc_bootloader_activation_countdown#3 [phi:smc_flash::@41->smc_flash::@7#0] -- register_copy 
    jmp __b7
    // smc_flash::@4
  __b4:
    // unsigned int smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1665] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1666] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [1667] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [1668] cx16_k_i2c_read_byte::return#11 = cx16_k_i2c_read_byte::return#1
    // smc_flash::@30
    // [1669] smc_flash::smc_bootloader_not_activated1#0 = cx16_k_i2c_read_byte::return#11
    // if(smc_bootloader_not_activated)
    // [1670] if(0!=smc_flash::smc_bootloader_not_activated1#0) goto smc_flash::@5 -- 0_neq_vwuz1_then_la1 
    lda.z smc_bootloader_not_activated1
    ora.z smc_bootloader_not_activated1+1
    bne __b5
    jmp __b9
    // [1671] phi from smc_flash::@30 to smc_flash::@5 [phi:smc_flash::@30->smc_flash::@5]
    // smc_flash::@5
  __b5:
    // wait_moment()
    // [1672] call wait_moment
    // [1160] phi from smc_flash::@5 to wait_moment [phi:smc_flash::@5->wait_moment]
    jsr wait_moment
    // [1673] phi from smc_flash::@5 to smc_flash::@31 [phi:smc_flash::@5->smc_flash::@31]
    // smc_flash::@31
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1674] call snprintf_init
    // [982] phi from smc_flash::@31 to snprintf_init [phi:smc_flash::@31->snprintf_init]
    // [982] phi snprintf_init::s#27 = info_text [phi:smc_flash::@31->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1675] phi from smc_flash::@31 to smc_flash::@32 [phi:smc_flash::@31->smc_flash::@32]
    // smc_flash::@32
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1676] call printf_str
    // [987] phi from smc_flash::@32 to printf_str [phi:smc_flash::@32->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:smc_flash::@32->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = smc_flash::s1 [phi:smc_flash::@32->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@33
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1677] printf_uchar::uvalue#5 = smc_flash::smc_bootloader_activation_countdown#10 -- vbuxx=vbuz1 
    ldx.z smc_bootloader_activation_countdown
    // [1678] call printf_uchar
    // [1165] phi from smc_flash::@33 to printf_uchar [phi:smc_flash::@33->printf_uchar]
    // [1165] phi printf_uchar::format_zero_padding#14 = 1 [phi:smc_flash::@33->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1165] phi printf_uchar::format_min_length#14 = 3 [phi:smc_flash::@33->printf_uchar#1] -- vbuz1=vbuc1 
    lda #3
    sta.z printf_uchar.format_min_length
    // [1165] phi printf_uchar::putc#14 = &snputc [phi:smc_flash::@33->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1165] phi printf_uchar::format_radix#14 = DECIMAL [phi:smc_flash::@33->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [1165] phi printf_uchar::uvalue#14 = printf_uchar::uvalue#5 [phi:smc_flash::@33->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1679] phi from smc_flash::@33 to smc_flash::@34 [phi:smc_flash::@33->smc_flash::@34]
    // smc_flash::@34
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1680] call printf_str
    // [987] phi from smc_flash::@34 to printf_str [phi:smc_flash::@34->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:smc_flash::@34->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = smc_flash::s2 [phi:smc_flash::@34->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@35
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1681] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1682] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1684] call display_action_text
    // [1176] phi from smc_flash::@35 to display_action_text [phi:smc_flash::@35->display_action_text]
    // [1176] phi display_action_text::info_text#19 = info_text [phi:smc_flash::@35->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_flash::@6
    // smc_bootloader_activation_countdown--;
    // [1685] smc_flash::smc_bootloader_activation_countdown#2 = -- smc_flash::smc_bootloader_activation_countdown#10 -- vbuz1=_dec_vbuz1 
    dec.z smc_bootloader_activation_countdown
    // [1552] phi from smc_flash::@6 to smc_flash::@3 [phi:smc_flash::@6->smc_flash::@3]
    // [1552] phi smc_flash::smc_bootloader_activation_countdown#10 = smc_flash::smc_bootloader_activation_countdown#2 [phi:smc_flash::@6->smc_flash::@3#0] -- register_copy 
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
    smc_bytes_checksum: .byte 0
    .label smc_attempts_flashed = main.check_status_smc11_return
    .label y = main.check_status_smc10_return
    .label smc_bytes_total = util_wait_key.ch
    smc_package_committed: .byte 0
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
// __register(A) char util_wait_key(__zp($55) char *info_text, __zp($76) char *filter)
util_wait_key: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 4
    .label util_wait_key__9 = $c2
    .label info_text = $55
    .label filter = $76
    // display_action_text(info_text)
    // [1687] display_action_text::info_text#0 = util_wait_key::info_text#2
    // [1688] call display_action_text
    // [1176] phi from util_wait_key to display_action_text [phi:util_wait_key->display_action_text]
    // [1176] phi display_action_text::info_text#19 = display_action_text::info_text#0 [phi:util_wait_key->display_action_text#0] -- register_copy 
    jsr display_action_text
    // util_wait_key::bank_get_bram1
    // return BRAM;
    // [1689] util_wait_key::bram#0 = BRAM -- vbum1=vbuz2 
    lda.z BRAM
    sta bram
    // util_wait_key::bank_get_brom1
    // return BROM;
    // [1690] util_wait_key::bank_get_brom1_return#0 = BROM -- vbum1=vbuz2 
    lda.z BROM
    sta bank_get_brom1_return
    // util_wait_key::bank_set_bram1
    // BRAM = bank
    // [1691] BRAM = util_wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // util_wait_key::bank_set_brom1
    // BROM = bank
    // [1692] BROM = util_wait_key::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [1693] phi from util_wait_key::@2 util_wait_key::@5 util_wait_key::bank_set_brom1 to util_wait_key::kbhit1 [phi:util_wait_key::@2/util_wait_key::@5/util_wait_key::bank_set_brom1->util_wait_key::kbhit1]
    // util_wait_key::kbhit1
  kbhit1:
    // util_wait_key::kbhit1_cbm_k_clrchn1
    // asm
    // asm { jsrCBM_CLRCHN  }
    jsr CBM_CLRCHN
    // [1695] phi from util_wait_key::kbhit1_cbm_k_clrchn1 to util_wait_key::kbhit1_@2 [phi:util_wait_key::kbhit1_cbm_k_clrchn1->util_wait_key::kbhit1_@2]
    // util_wait_key::kbhit1_@2
    // cbm_k_getin()
    // [1696] call cbm_k_getin
    jsr cbm_k_getin
    // [1697] cbm_k_getin::return#2 = cbm_k_getin::return#1
    // util_wait_key::@4
    // [1698] util_wait_key::ch#4 = cbm_k_getin::return#2 -- vwum1=vbuaa 
    sta ch
    lda #0
    sta ch+1
    // util_wait_key::@3
    // if (filter)
    // [1699] if((char *)0!=util_wait_key::filter#12) goto util_wait_key::@1 -- pbuc1_neq_pbuz1_then_la1 
    // if there is a filter, check the filter, otherwise return ch.
    lda.z filter+1
    cmp #>0
    bne __b1
    lda.z filter
    cmp #<0
    bne __b1
    // util_wait_key::@2
    // if(ch)
    // [1700] if(0!=util_wait_key::ch#4) goto util_wait_key::bank_set_bram2 -- 0_neq_vwum1_then_la1 
    lda ch
    ora ch+1
    bne bank_set_bram2
    jmp kbhit1
    // util_wait_key::bank_set_bram2
  bank_set_bram2:
    // BRAM = bank
    // [1701] BRAM = util_wait_key::bram#0 -- vbuz1=vbum2 
    lda bram
    sta.z BRAM
    // util_wait_key::bank_set_brom2
    // BROM = bank
    // [1702] BROM = util_wait_key::bank_get_brom1_return#0 -- vbuz1=vbum2 
    lda bank_get_brom1_return
    sta.z BROM
    // util_wait_key::@return
    // }
    // [1703] return 
    rts
    // util_wait_key::@1
  __b1:
    // strchr(filter, ch)
    // [1704] strchr::str#0 = (const void *)util_wait_key::filter#12 -- pvoz1=pvoz2 
    lda.z filter
    sta.z strchr.str
    lda.z filter+1
    sta.z strchr.str+1
    // [1705] strchr::c#0 = util_wait_key::ch#4 -- vbuz1=vwum2 
    lda ch
    sta.z strchr.c
    // [1706] call strchr
    // [1710] phi from util_wait_key::@1 to strchr [phi:util_wait_key::@1->strchr]
    // [1710] phi strchr::c#4 = strchr::c#0 [phi:util_wait_key::@1->strchr#0] -- register_copy 
    // [1710] phi strchr::str#2 = strchr::str#0 [phi:util_wait_key::@1->strchr#1] -- register_copy 
    jsr strchr
    // strchr(filter, ch)
    // [1707] strchr::return#3 = strchr::return#2
    // util_wait_key::@5
    // [1708] util_wait_key::$9 = strchr::return#3
    // if(strchr(filter, ch) != NULL)
    // [1709] if(util_wait_key::$9!=0) goto util_wait_key::bank_set_bram2 -- pvoz1_neq_0_then_la1 
    lda.z util_wait_key__9
    ora.z util_wait_key__9+1
    bne bank_set_bram2
    jmp kbhit1
  .segment Data
    bram: .byte 0
    bank_get_brom1_return: .byte 0
    ch: .word 0
}
.segment Code
  // strchr
// Searches for the first occurrence of the character c (an unsigned char) in the string pointed to, by the argument str.
// - str: The memory to search
// - c: A character to search for
// Return: A pointer to the matching byte or NULL if the character does not occur in the given memory area.
// __zp($c2) void * strchr(__zp($c2) const void *str, __zp($ec) char c)
strchr: {
    .label ptr = $c2
    .label return = $c2
    .label str = $c2
    .label c = $ec
    // [1711] strchr::ptr#6 = (char *)strchr::str#2
    // [1712] phi from strchr strchr::@3 to strchr::@1 [phi:strchr/strchr::@3->strchr::@1]
    // [1712] phi strchr::ptr#2 = strchr::ptr#6 [phi:strchr/strchr::@3->strchr::@1#0] -- register_copy 
    // strchr::@1
  __b1:
    // while(*ptr)
    // [1713] if(0!=*strchr::ptr#2) goto strchr::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (ptr),y
    cmp #0
    bne __b2
    // [1714] phi from strchr::@1 to strchr::@return [phi:strchr::@1->strchr::@return]
    // [1714] phi strchr::return#2 = (void *) 0 [phi:strchr::@1->strchr::@return#0] -- pvoz1=pvoc1 
    tya
    sta.z return
    sta.z return+1
    // strchr::@return
    // }
    // [1715] return 
    rts
    // strchr::@2
  __b2:
    // if(*ptr==c)
    // [1716] if(*strchr::ptr#2!=strchr::c#4) goto strchr::@3 -- _deref_pbuz1_neq_vbuz2_then_la1 
    ldy #0
    lda (ptr),y
    cmp.z c
    bne __b3
    // strchr::@4
    // [1717] strchr::return#8 = (void *)strchr::ptr#2
    // [1714] phi from strchr::@4 to strchr::@return [phi:strchr::@4->strchr::@return]
    // [1714] phi strchr::return#2 = strchr::return#8 [phi:strchr::@4->strchr::@return#0] -- register_copy 
    rts
    // strchr::@3
  __b3:
    // ptr++;
    // [1718] strchr::ptr#1 = ++ strchr::ptr#2 -- pbuz1=_inc_pbuz1 
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
// void display_info_cx16_rom(__register(X) char info_status, __zp($3e) char *info_text)
display_info_cx16_rom: {
    .label info_text = $3e
    // display_info_rom(0, info_status, info_text)
    // [1720] display_info_rom::info_status#0 = display_info_cx16_rom::info_status#2 -- vbum1=vbuxx 
    stx display_info_rom.info_status
    // [1721] display_info_rom::info_text#0 = display_info_cx16_rom::info_text#2
    // [1722] call display_info_rom
    // [1199] phi from display_info_cx16_rom to display_info_rom [phi:display_info_cx16_rom->display_info_rom]
    // [1199] phi display_info_rom::info_text#16 = display_info_rom::info_text#0 [phi:display_info_cx16_rom->display_info_rom#0] -- register_copy 
    // [1199] phi display_info_rom::rom_chip#16 = 0 [phi:display_info_cx16_rom->display_info_rom#1] -- vbuz1=vbuc1 
    lda #0
    sta.z display_info_rom.rom_chip
    // [1199] phi display_info_rom::info_status#16 = display_info_rom::info_status#0 [phi:display_info_cx16_rom->display_info_rom#2] -- register_copy 
    jsr display_info_rom
    // display_info_cx16_rom::@return
    // }
    // [1723] return 
    rts
}
  // rom_get_github_commit_id
/**
 * @brief Copy the github commit_id only if the commit_id contains hexadecimal characters. 
 * 
 * @param commit_id The target commit_id.
 * @param from The source ptr in ROM or RAM.
 */
// void rom_get_github_commit_id(__zp($49) char *commit_id, __zp($3e) char *from)
rom_get_github_commit_id: {
    .label commit_id = $49
    .label from = $3e
    // [1725] phi from rom_get_github_commit_id to rom_get_github_commit_id::@2 [phi:rom_get_github_commit_id->rom_get_github_commit_id::@2]
    // [1725] phi rom_get_github_commit_id::commit_id_ok#2 = true [phi:rom_get_github_commit_id->rom_get_github_commit_id::@2#0] -- vboxx=vboc1 
    lda #1
    tax
    // [1725] phi rom_get_github_commit_id::c#2 = 0 [phi:rom_get_github_commit_id->rom_get_github_commit_id::@2#1] -- vbuyy=vbuc1 
    ldy #0
    // rom_get_github_commit_id::@2
  __b2:
    // for(unsigned char c=0; c<7; c++)
    // [1726] if(rom_get_github_commit_id::c#2<7) goto rom_get_github_commit_id::@3 -- vbuyy_lt_vbuc1_then_la1 
    cpy #7
    bcc __b3
    // rom_get_github_commit_id::@4
    // if(commit_id_ok)
    // [1727] if(rom_get_github_commit_id::commit_id_ok#2) goto rom_get_github_commit_id::@1 -- vboxx_then_la1 
    cpx #0
    bne __b1
    // rom_get_github_commit_id::@6
    // *commit_id = '\0'
    // [1728] *rom_get_github_commit_id::commit_id#6 = '@' -- _deref_pbuz1=vbuc1 
    lda #'@'
    ldy #0
    sta (commit_id),y
    // rom_get_github_commit_id::@return
    // }
    // [1729] return 
    rts
    // rom_get_github_commit_id::@1
  __b1:
    // strncpy(commit_id, from, 7)
    // [1730] strncpy::dst#2 = rom_get_github_commit_id::commit_id#6
    // [1731] strncpy::src#2 = rom_get_github_commit_id::from#6
    // [1732] call strncpy
    // [2455] phi from rom_get_github_commit_id::@1 to strncpy [phi:rom_get_github_commit_id::@1->strncpy]
    // [2455] phi strncpy::dst#8 = strncpy::dst#2 [phi:rom_get_github_commit_id::@1->strncpy#0] -- register_copy 
    // [2455] phi strncpy::src#6 = strncpy::src#2 [phi:rom_get_github_commit_id::@1->strncpy#1] -- register_copy 
    // [2455] phi strncpy::n#3 = 7 [phi:rom_get_github_commit_id::@1->strncpy#2] -- vwuz1=vbuc1 
    lda #<7
    sta.z strncpy.n
    lda #>7
    sta.z strncpy.n+1
    jsr strncpy
    rts
    // rom_get_github_commit_id::@3
  __b3:
    // unsigned char ch = from[c]
    // [1733] rom_get_github_commit_id::ch#0 = rom_get_github_commit_id::from#6[rom_get_github_commit_id::c#2] -- vbuaa=pbuz1_derefidx_vbuyy 
    lda (from),y
    // if(!(ch >= 48 && ch <= 48+9 || ch >= 65 && ch <= 65+26))
    // [1734] if(rom_get_github_commit_id::ch#0<$30) goto rom_get_github_commit_id::@7 -- vbuaa_lt_vbuc1_then_la1 
    cmp #$30
    bcc __b7
    // rom_get_github_commit_id::@8
    // [1735] if(rom_get_github_commit_id::ch#0<$30+9+1) goto rom_get_github_commit_id::@5 -- vbuaa_lt_vbuc1_then_la1 
    cmp #$30+9+1
    bcc __b5
    // rom_get_github_commit_id::@7
  __b7:
    // [1736] if(rom_get_github_commit_id::ch#0<$41) goto rom_get_github_commit_id::@5 -- vbuaa_lt_vbuc1_then_la1 
    cmp #$41
    bcc __b4
    // rom_get_github_commit_id::@9
    // [1737] if(rom_get_github_commit_id::ch#0<$41+$1a+1) goto rom_get_github_commit_id::@10 -- vbuaa_lt_vbuc1_then_la1 
    cmp #$41+$1a+1
    bcc __b5
    // [1739] phi from rom_get_github_commit_id::@7 rom_get_github_commit_id::@9 to rom_get_github_commit_id::@5 [phi:rom_get_github_commit_id::@7/rom_get_github_commit_id::@9->rom_get_github_commit_id::@5]
  __b4:
    // [1739] phi rom_get_github_commit_id::commit_id_ok#4 = false [phi:rom_get_github_commit_id::@7/rom_get_github_commit_id::@9->rom_get_github_commit_id::@5#0] -- vboxx=vboc1 
    lda #0
    tax
    // [1738] phi from rom_get_github_commit_id::@9 to rom_get_github_commit_id::@10 [phi:rom_get_github_commit_id::@9->rom_get_github_commit_id::@10]
    // rom_get_github_commit_id::@10
    // [1739] phi from rom_get_github_commit_id::@10 rom_get_github_commit_id::@8 to rom_get_github_commit_id::@5 [phi:rom_get_github_commit_id::@10/rom_get_github_commit_id::@8->rom_get_github_commit_id::@5]
    // [1739] phi rom_get_github_commit_id::commit_id_ok#4 = rom_get_github_commit_id::commit_id_ok#2 [phi:rom_get_github_commit_id::@10/rom_get_github_commit_id::@8->rom_get_github_commit_id::@5#0] -- register_copy 
    // rom_get_github_commit_id::@5
  __b5:
    // for(unsigned char c=0; c<7; c++)
    // [1740] rom_get_github_commit_id::c#1 = ++ rom_get_github_commit_id::c#2 -- vbuyy=_inc_vbuyy 
    iny
    // [1725] phi from rom_get_github_commit_id::@5 to rom_get_github_commit_id::@2 [phi:rom_get_github_commit_id::@5->rom_get_github_commit_id::@2]
    // [1725] phi rom_get_github_commit_id::commit_id_ok#2 = rom_get_github_commit_id::commit_id_ok#4 [phi:rom_get_github_commit_id::@5->rom_get_github_commit_id::@2#0] -- register_copy 
    // [1725] phi rom_get_github_commit_id::c#2 = rom_get_github_commit_id::c#1 [phi:rom_get_github_commit_id::@5->rom_get_github_commit_id::@2#1] -- register_copy 
    jmp __b2
}
  // rom_get_version_text
// void rom_get_version_text(__zp($30) char *release_info, __register(X) char prefix, __mem() char release, __zp($b9) char *github)
rom_get_version_text: {
    .label release_info = $30
    .label github = $b9
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [1742] snprintf_init::s#8 = rom_get_version_text::release_info#2
    // [1743] call snprintf_init
    // [982] phi from rom_get_version_text to snprintf_init [phi:rom_get_version_text->snprintf_init]
    // [982] phi snprintf_init::s#27 = snprintf_init::s#8 [phi:rom_get_version_text->snprintf_init#0] -- register_copy 
    jsr snprintf_init
    // rom_get_version_text::@1
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [1744] stackpush(char) = rom_get_version_text::prefix#2 -- _stackpushbyte_=vbuxx 
    txa
    pha
    // [1745] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [1747] printf_uchar::uvalue#7 = rom_get_version_text::release#2 -- vbuxx=vbum1 
    ldx release
    // [1748] call printf_uchar
    // [1165] phi from rom_get_version_text::@1 to printf_uchar [phi:rom_get_version_text::@1->printf_uchar]
    // [1165] phi printf_uchar::format_zero_padding#14 = 0 [phi:rom_get_version_text::@1->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1165] phi printf_uchar::format_min_length#14 = 0 [phi:rom_get_version_text::@1->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1165] phi printf_uchar::putc#14 = &snputc [phi:rom_get_version_text::@1->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1165] phi printf_uchar::format_radix#14 = DECIMAL [phi:rom_get_version_text::@1->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [1165] phi printf_uchar::uvalue#14 = printf_uchar::uvalue#7 [phi:rom_get_version_text::@1->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1749] phi from rom_get_version_text::@1 to rom_get_version_text::@2 [phi:rom_get_version_text::@1->rom_get_version_text::@2]
    // rom_get_version_text::@2
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [1750] call printf_str
    // [987] phi from rom_get_version_text::@2 to printf_str [phi:rom_get_version_text::@2->printf_str]
    // [987] phi printf_str::putc#73 = &snputc [phi:rom_get_version_text::@2->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [987] phi printf_str::s#73 = s [phi:rom_get_version_text::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_get_version_text::@3
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [1751] printf_string::str#12 = rom_get_version_text::github#2 -- pbuz1=pbuz2 
    lda.z github
    sta.z printf_string.str
    lda.z github+1
    sta.z printf_string.str+1
    // [1752] call printf_string
    // [1130] phi from rom_get_version_text::@3 to printf_string [phi:rom_get_version_text::@3->printf_string]
    // [1130] phi printf_string::putc#22 = &snputc [phi:rom_get_version_text::@3->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1130] phi printf_string::str#22 = printf_string::str#12 [phi:rom_get_version_text::@3->printf_string#1] -- register_copy 
    // [1130] phi printf_string::format_justify_left#22 = 0 [phi:rom_get_version_text::@3->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1130] phi printf_string::format_min_length#22 = 0 [phi:rom_get_version_text::@3->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // rom_get_version_text::@4
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [1753] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1754] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // rom_get_version_text::@return
    // }
    // [1756] return 
    rts
  .segment Data
    release: .byte 0
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
// void display_info_led(__register(Y) char x, __zp($c7) char y, __register(X) char tc, char bc)
display_info_led: {
    .label y = $c7
    // textcolor(tc)
    // [1758] textcolor::color#13 = display_info_led::tc#4
    // [1759] call textcolor
    // [700] phi from display_info_led to textcolor [phi:display_info_led->textcolor]
    // [700] phi textcolor::color#18 = textcolor::color#13 [phi:display_info_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [1760] phi from display_info_led to display_info_led::@1 [phi:display_info_led->display_info_led::@1]
    // display_info_led::@1
    // bgcolor(bc)
    // [1761] call bgcolor
    // [705] phi from display_info_led::@1 to bgcolor [phi:display_info_led::@1->bgcolor]
    // [705] phi bgcolor::color#14 = BLUE [phi:display_info_led::@1->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // display_info_led::@2
    // cputcxy(x, y, VERA_CHR_UR)
    // [1762] cputcxy::x#11 = display_info_led::x#4 -- vbuxx=vbuyy 
    tya
    tax
    // [1763] cputcxy::y#11 = display_info_led::y#4 -- vbuyy=vbuz1 
    ldy.z y
    // [1764] call cputcxy
    // [1986] phi from display_info_led::@2 to cputcxy [phi:display_info_led::@2->cputcxy]
    // [1986] phi cputcxy::c#15 = $7c [phi:display_info_led::@2->cputcxy#0] -- vbuz1=vbuc1 
    lda #$7c
    sta.z cputcxy.c
    // [1986] phi cputcxy::y#15 = cputcxy::y#11 [phi:display_info_led::@2->cputcxy#1] -- register_copy 
    // [1986] phi cputcxy::x#15 = cputcxy::x#11 [phi:display_info_led::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [1765] phi from display_info_led::@2 to display_info_led::@3 [phi:display_info_led::@2->display_info_led::@3]
    // display_info_led::@3
    // textcolor(WHITE)
    // [1766] call textcolor
    // [700] phi from display_info_led::@3 to textcolor [phi:display_info_led::@3->textcolor]
    // [700] phi textcolor::color#18 = WHITE [phi:display_info_led::@3->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // display_info_led::@return
    // }
    // [1767] return 
    rts
}
  // screenlayer
// --- layer management in VERA ---
// void screenlayer(char layer, __register(X) char mapbase, __zp($bd) char config)
screenlayer: {
    .label config = $bd
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [1768] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [1769] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [1770] *((char *)&__conio+2) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+2
    // mapbase >> 7
    // [1771] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbuaa=vbuxx_ror_7 
    txa
    rol
    rol
    and #1
    // __conio.mapbase_bank = mapbase >> 7
    // [1772] *((char *)&__conio+5) = screenlayer::$0 -- _deref_pbuc1=vbuaa 
    sta __conio+5
    // (mapbase)<<1
    // [1773] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbuaa=vbuxx_rol_1 
    txa
    asl
    // MAKEWORD((mapbase)<<1,0)
    // [1774] screenlayer::$2 = screenlayer::$1 w= 0 -- vwum1=vbuaa_word_vbuc1 
    ldy #0
    sta screenlayer__2+1
    sty screenlayer__2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [1775] *((unsigned int *)&__conio+3) = screenlayer::$2 -- _deref_pwuc1=vwum1 
    tya
    sta __conio+3
    lda screenlayer__2+1
    sta __conio+3+1
    // config & VERA_LAYER_WIDTH_MASK
    // [1776] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbuaa=vbuz1_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and.z config
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [1777] screenlayer::$8 = screenlayer::$7 >> 4 -- vbuxx=vbuaa_ror_4 
    lsr
    lsr
    lsr
    lsr
    tax
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [1778] *((char *)&__conio+8) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbuxx 
    lda VERA_LAYER_DIM,x
    sta __conio+8
    // config & VERA_LAYER_HEIGHT_MASK
    // [1779] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbuaa=vbuz1_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and.z config
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [1780] screenlayer::$6 = screenlayer::$5 >> 6 -- vbuaa=vbuaa_ror_6 
    rol
    rol
    rol
    and #3
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [1781] *((char *)&__conio+9) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbuaa 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+9
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [1782] screenlayer::$16 = screenlayer::$8 << 1 -- vbuaa=vbuxx_rol_1 
    txa
    asl
    // [1783] *((unsigned int *)&__conio+$a) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbuaa 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    tay
    lda VERA_LAYER_SKIP,y
    sta __conio+$a
    lda VERA_LAYER_SKIP+1,y
    sta __conio+$a+1
    // vera_dc_hscale_temp == 0x80
    // [1784] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vboaa=vbum1_eq_vbuc1 
    lda vera_dc_hscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [1785] screenlayer::$18 = (char)screenlayer::$9 -- vbuxx=vbuaa 
    tax
    // [1786] screenlayer::$10 = $28 << screenlayer::$18 -- vbuaa=vbuc1_rol_vbuxx 
    lda #$28
    cpx #0
    beq !e+
  !:
    asl
    dex
    bne !-
  !e:
    // (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [1787] screenlayer::$11 = screenlayer::$10 - 1 -- vbuaa=vbuaa_minus_1 
    sec
    sbc #1
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [1788] *((char *)&__conio+6) = screenlayer::$11 -- _deref_pbuc1=vbuaa 
    sta __conio+6
    // vera_dc_vscale_temp == 0x80
    // [1789] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vboaa=vbum1_eq_vbuc1 
    lda vera_dc_vscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [1790] screenlayer::$19 = (char)screenlayer::$12 -- vbuxx=vbuaa 
    tax
    // [1791] screenlayer::$13 = $1e << screenlayer::$19 -- vbuaa=vbuc1_rol_vbuxx 
    lda #$1e
    cpx #0
    beq !e+
  !:
    asl
    dex
    bne !-
  !e:
    // (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [1792] screenlayer::$14 = screenlayer::$13 - 1 -- vbuaa=vbuaa_minus_1 
    sec
    sbc #1
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [1793] *((char *)&__conio+7) = screenlayer::$14 -- _deref_pbuc1=vbuaa 
    sta __conio+7
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [1794] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta mapbase_offset
    lda __conio+3+1
    sta mapbase_offset+1
    // [1795] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [1795] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [1795] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuxx=vbuc1 
    ldx #0
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [1796] if(screenlayer::y#2<=*((char *)&__conio+7)) goto screenlayer::@2 -- vbuxx_le__deref_pbuc1_then_la1 
    lda __conio+7
    stx.z $ff
    cmp.z $ff
    bcs __b2
    // screenlayer::@return
    // }
    // [1797] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [1798] screenlayer::$17 = screenlayer::y#2 << 1 -- vbuaa=vbuxx_rol_1 
    txa
    asl
    // [1799] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbuaa=vwum1 
    tay
    lda mapbase_offset
    sta __conio+$15,y
    lda mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [1800] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda mapbase_offset
    adc __conio+$a
    sta mapbase_offset
    lda mapbase_offset+1
    adc __conio+$a+1
    sta mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [1801] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuxx=_inc_vbuxx 
    inx
    // [1795] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [1795] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [1795] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    VERA_LAYER_DIM: .byte $1f, $3f, $7f, $ff
    VERA_LAYER_SKIP: .word $40, $80, $100, $200
    .label screenlayer__2 = cbm_k_plot_get.return
    vera_dc_hscale_temp: .byte 0
    vera_dc_vscale_temp: .byte 0
    .label mapbase_offset = cbm_k_plot_get.return
}
.segment Code
  // cscroll
// Scroll the entire screen if the cursor is beyond the last line
cscroll: {
    // if(__conio.cursor_y>__conio.height)
    // [1802] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [1803] if(0!=((char *)&__conio+$f)[*((char *)&__conio+2)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [1804] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // [1805] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [1806] call gotoxy
    // [718] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [718] phi gotoxy::y#30 = 0 [phi:cscroll::@3->gotoxy#0] -- vbuyy=vbuc1 
    ldy #0
    // [718] phi gotoxy::x#30 = 0 [phi:cscroll::@3->gotoxy#1] -- vbuxx=vbuc1 
    ldx #0
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [1807] return 
    rts
    // [1808] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [1809] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [1810] gotoxy::y#3 = *((char *)&__conio+7) -- vbuyy=_deref_pbuc1 
    ldy __conio+7
    // [1811] call gotoxy
    // [718] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [718] phi gotoxy::y#30 = gotoxy::y#3 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [718] phi gotoxy::x#30 = 0 [phi:cscroll::@5->gotoxy#1] -- vbuxx=vbuc1 
    ldx #0
    jsr gotoxy
    // [1812] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [1813] call clearline
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
    // [1814] ((char *)&__conio+$f)[*((char *)&__conio+2)] = scroll::onoff#0 -- pbuc1_derefidx_(_deref_pbuc2)=vbuc3 
    lda #onoff
    ldy __conio+2
    sta __conio+$f,y
    // scroll::@return
    // }
    // [1815] return 
    rts
}
  // clrscr
// clears the screen and moves the cursor to the upper left-hand corner of the screen.
clrscr: {
    // unsigned int line_text = __conio.mapbase_offset
    // [1816] clrscr::line_text#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta line_text
    lda __conio+3+1
    sta line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1817] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [1818] clrscr::$0 = *((char *)&__conio+5) | VERA_INC_1 -- vbuaa=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1819] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [1820] clrscr::l#0 = *((char *)&__conio+9) -- vbuxx=_deref_pbuc1 
    ldx __conio+9
    // [1821] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [1821] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [1821] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [1822] clrscr::$1 = byte0  clrscr::ch#0 -- vbuaa=_byte0_vwum1 
    lda ch
    // *VERA_ADDRX_L = BYTE0(ch)
    // [1823] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbuaa 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [1824] clrscr::$2 = byte1  clrscr::ch#0 -- vbuaa=_byte1_vwum1 
    lda ch+1
    // *VERA_ADDRX_M = BYTE1(ch)
    // [1825] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth+1
    // [1826] clrscr::c#0 = *((char *)&__conio+8) + 1 -- vbuyy=_deref_pbuc1_plus_1 
    ldy __conio+8
    iny
    // [1827] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [1827] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [1828] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1829] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [1830] clrscr::c#1 = -- clrscr::c#2 -- vbuyy=_dec_vbuyy 
    dey
    // while(c)
    // [1831] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbuyy_then_la1 
    cpy #0
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [1832] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda line_text
    adc __conio+$a
    sta line_text
    lda line_text+1
    adc __conio+$a+1
    sta line_text+1
    // l--;
    // [1833] clrscr::l#1 = -- clrscr::l#4 -- vbuxx=_dec_vbuxx 
    dex
    // while(l)
    // [1834] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbuxx_then_la1 
    cpx #0
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [1835] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y = 0
    // [1836] *((char *)&__conio+1) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+1
    // __conio.offset = __conio.mapbase_offset
    // [1837] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+3) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+3
    sta __conio+$13
    lda __conio+3+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [1838] return 
    rts
  .segment Data
    .label line_text = ch
    ch: .word 0
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
// void display_frame(char x0, char y0, __zp($78) char x1, __zp($51) char y1)
display_frame: {
    .label x = $53
    .label y = $bf
    .label x_1 = $bc
    .label y_1 = $52
    .label x1 = $78
    .label y1 = $51
    // unsigned char w = x1 - x0
    // [1840] display_frame::w#0 = display_frame::x1#16 - display_frame::x#0 -- vbum1=vbuz2_minus_vbuz3 
    lda.z x1
    sec
    sbc.z x
    sta w
    // unsigned char h = y1 - y0
    // [1841] display_frame::h#0 = display_frame::y1#16 - display_frame::y#0 -- vbum1=vbuz2_minus_vbuz3 
    lda.z y1
    sec
    sbc.z y
    sta h
    // unsigned char mask = display_frame_maskxy(x, y)
    // [1842] display_frame_maskxy::x#0 = display_frame::x#0 -- vbuxx=vbuz1 
    ldx.z x
    // [1843] display_frame_maskxy::y#0 = display_frame::y#0 -- vbuyy=vbuz1 
    ldy.z y
    // [1844] call display_frame_maskxy
    // [2499] phi from display_frame to display_frame_maskxy [phi:display_frame->display_frame_maskxy]
    // [2499] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#0 [phi:display_frame->display_frame_maskxy#0] -- register_copy 
    // [2499] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#0 [phi:display_frame->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // unsigned char mask = display_frame_maskxy(x, y)
    // [1845] display_frame_maskxy::return#13 = display_frame_maskxy::return#12
    // display_frame::@13
    // [1846] display_frame::mask#0 = display_frame_maskxy::return#13
    // mask |= 0b0110
    // [1847] display_frame::mask#1 = display_frame::mask#0 | 6 -- vbuaa=vbuaa_bor_vbuc1 
    ora #6
    // unsigned char c = display_frame_char(mask)
    // [1848] display_frame_char::mask#0 = display_frame::mask#1
    // [1849] call display_frame_char
  // Add a corner.
    // [2525] phi from display_frame::@13 to display_frame_char [phi:display_frame::@13->display_frame_char]
    // [2525] phi display_frame_char::mask#10 = display_frame_char::mask#0 [phi:display_frame::@13->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // unsigned char c = display_frame_char(mask)
    // [1850] display_frame_char::return#13 = display_frame_char::return#12
    // display_frame::@14
    // [1851] display_frame::c#0 = display_frame_char::return#13
    // cputcxy(x, y, c)
    // [1852] cputcxy::x#0 = display_frame::x#0 -- vbuxx=vbuz1 
    ldx.z x
    // [1853] cputcxy::y#0 = display_frame::y#0 -- vbuyy=vbuz1 
    ldy.z y
    // [1854] cputcxy::c#0 = display_frame::c#0 -- vbuz1=vbuaa 
    sta.z cputcxy.c
    // [1855] call cputcxy
    // [1986] phi from display_frame::@14 to cputcxy [phi:display_frame::@14->cputcxy]
    // [1986] phi cputcxy::c#15 = cputcxy::c#0 [phi:display_frame::@14->cputcxy#0] -- register_copy 
    // [1986] phi cputcxy::y#15 = cputcxy::y#0 [phi:display_frame::@14->cputcxy#1] -- register_copy 
    // [1986] phi cputcxy::x#15 = cputcxy::x#0 [phi:display_frame::@14->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@15
    // if(w>=2)
    // [1856] if(display_frame::w#0<2) goto display_frame::@36 -- vbum1_lt_vbuc1_then_la1 
    lda w
    cmp #2
    bcs !__b36+
    jmp __b36
  !__b36:
    // display_frame::@2
    // x++;
    // [1857] display_frame::x#1 = ++ display_frame::x#0 -- vbuz1=_inc_vbuz2 
    lda.z x
    inc
    sta.z x_1
    // [1858] phi from display_frame::@2 display_frame::@21 to display_frame::@4 [phi:display_frame::@2/display_frame::@21->display_frame::@4]
    // [1858] phi display_frame::x#10 = display_frame::x#1 [phi:display_frame::@2/display_frame::@21->display_frame::@4#0] -- register_copy 
    // display_frame::@4
  __b4:
    // while(x < x1)
    // [1859] if(display_frame::x#10<display_frame::x1#16) goto display_frame::@5 -- vbuz1_lt_vbuz2_then_la1 
    lda.z x_1
    cmp.z x1
    bcs !__b5+
    jmp __b5
  !__b5:
    // [1860] phi from display_frame::@36 display_frame::@4 to display_frame::@1 [phi:display_frame::@36/display_frame::@4->display_frame::@1]
    // [1860] phi display_frame::x#24 = display_frame::x#30 [phi:display_frame::@36/display_frame::@4->display_frame::@1#0] -- register_copy 
    // display_frame::@1
  __b1:
    // display_frame_maskxy(x, y)
    // [1861] display_frame_maskxy::x#1 = display_frame::x#24 -- vbuxx=vbuz1 
    ldx.z x_1
    // [1862] display_frame_maskxy::y#1 = display_frame::y#0 -- vbuyy=vbuz1 
    ldy.z y
    // [1863] call display_frame_maskxy
    // [2499] phi from display_frame::@1 to display_frame_maskxy [phi:display_frame::@1->display_frame_maskxy]
    // [2499] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#1 [phi:display_frame::@1->display_frame_maskxy#0] -- register_copy 
    // [2499] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#1 [phi:display_frame::@1->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1864] display_frame_maskxy::return#14 = display_frame_maskxy::return#12
    // display_frame::@16
    // mask = display_frame_maskxy(x, y)
    // [1865] display_frame::mask#2 = display_frame_maskxy::return#14
    // mask |= 0b0011
    // [1866] display_frame::mask#3 = display_frame::mask#2 | 3 -- vbuaa=vbuaa_bor_vbuc1 
    ora #3
    // display_frame_char(mask)
    // [1867] display_frame_char::mask#1 = display_frame::mask#3
    // [1868] call display_frame_char
    // [2525] phi from display_frame::@16 to display_frame_char [phi:display_frame::@16->display_frame_char]
    // [2525] phi display_frame_char::mask#10 = display_frame_char::mask#1 [phi:display_frame::@16->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1869] display_frame_char::return#14 = display_frame_char::return#12
    // display_frame::@17
    // c = display_frame_char(mask)
    // [1870] display_frame::c#1 = display_frame_char::return#14
    // cputcxy(x, y, c)
    // [1871] cputcxy::x#1 = display_frame::x#24 -- vbuxx=vbuz1 
    ldx.z x_1
    // [1872] cputcxy::y#1 = display_frame::y#0 -- vbuyy=vbuz1 
    ldy.z y
    // [1873] cputcxy::c#1 = display_frame::c#1 -- vbuz1=vbuaa 
    sta.z cputcxy.c
    // [1874] call cputcxy
    // [1986] phi from display_frame::@17 to cputcxy [phi:display_frame::@17->cputcxy]
    // [1986] phi cputcxy::c#15 = cputcxy::c#1 [phi:display_frame::@17->cputcxy#0] -- register_copy 
    // [1986] phi cputcxy::y#15 = cputcxy::y#1 [phi:display_frame::@17->cputcxy#1] -- register_copy 
    // [1986] phi cputcxy::x#15 = cputcxy::x#1 [phi:display_frame::@17->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@18
    // if(h>=2)
    // [1875] if(display_frame::h#0<2) goto display_frame::@return -- vbum1_lt_vbuc1_then_la1 
    lda h
    cmp #2
    bcc __breturn
    // display_frame::@3
    // y++;
    // [1876] display_frame::y#1 = ++ display_frame::y#0 -- vbuz1=_inc_vbuz2 
    lda.z y
    inc
    sta.z y_1
    // [1877] phi from display_frame::@27 display_frame::@3 to display_frame::@6 [phi:display_frame::@27/display_frame::@3->display_frame::@6]
    // [1877] phi display_frame::y#10 = display_frame::y#2 [phi:display_frame::@27/display_frame::@3->display_frame::@6#0] -- register_copy 
    // display_frame::@6
  __b6:
    // while(y < y1)
    // [1878] if(display_frame::y#10<display_frame::y1#16) goto display_frame::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z y_1
    cmp.z y1
    bcc __b7
    // display_frame::@8
    // display_frame_maskxy(x, y)
    // [1879] display_frame_maskxy::x#5 = display_frame::x#0 -- vbuxx=vbuz1 
    ldx.z x
    // [1880] display_frame_maskxy::y#5 = display_frame::y#10 -- vbuyy=vbuz1 
    tay
    // [1881] call display_frame_maskxy
    // [2499] phi from display_frame::@8 to display_frame_maskxy [phi:display_frame::@8->display_frame_maskxy]
    // [2499] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#5 [phi:display_frame::@8->display_frame_maskxy#0] -- register_copy 
    // [2499] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#5 [phi:display_frame::@8->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1882] display_frame_maskxy::return#18 = display_frame_maskxy::return#12
    // display_frame::@28
    // mask = display_frame_maskxy(x, y)
    // [1883] display_frame::mask#10 = display_frame_maskxy::return#18
    // mask |= 0b1100
    // [1884] display_frame::mask#11 = display_frame::mask#10 | $c -- vbuaa=vbuaa_bor_vbuc1 
    ora #$c
    // display_frame_char(mask)
    // [1885] display_frame_char::mask#5 = display_frame::mask#11
    // [1886] call display_frame_char
    // [2525] phi from display_frame::@28 to display_frame_char [phi:display_frame::@28->display_frame_char]
    // [2525] phi display_frame_char::mask#10 = display_frame_char::mask#5 [phi:display_frame::@28->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1887] display_frame_char::return#18 = display_frame_char::return#12
    // display_frame::@29
    // c = display_frame_char(mask)
    // [1888] display_frame::c#5 = display_frame_char::return#18
    // cputcxy(x, y, c)
    // [1889] cputcxy::x#5 = display_frame::x#0 -- vbuxx=vbuz1 
    ldx.z x
    // [1890] cputcxy::y#5 = display_frame::y#10 -- vbuyy=vbuz1 
    ldy.z y_1
    // [1891] cputcxy::c#5 = display_frame::c#5 -- vbuz1=vbuaa 
    sta.z cputcxy.c
    // [1892] call cputcxy
    // [1986] phi from display_frame::@29 to cputcxy [phi:display_frame::@29->cputcxy]
    // [1986] phi cputcxy::c#15 = cputcxy::c#5 [phi:display_frame::@29->cputcxy#0] -- register_copy 
    // [1986] phi cputcxy::y#15 = cputcxy::y#5 [phi:display_frame::@29->cputcxy#1] -- register_copy 
    // [1986] phi cputcxy::x#15 = cputcxy::x#5 [phi:display_frame::@29->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@30
    // if(w>=2)
    // [1893] if(display_frame::w#0<2) goto display_frame::@10 -- vbum1_lt_vbuc1_then_la1 
    lda w
    cmp #2
    bcc __b10
    // display_frame::@9
    // x++;
    // [1894] display_frame::x#4 = ++ display_frame::x#0 -- vbuz1=_inc_vbuz1 
    inc.z x
    // [1895] phi from display_frame::@35 display_frame::@9 to display_frame::@11 [phi:display_frame::@35/display_frame::@9->display_frame::@11]
    // [1895] phi display_frame::x#18 = display_frame::x#5 [phi:display_frame::@35/display_frame::@9->display_frame::@11#0] -- register_copy 
    // display_frame::@11
  __b11:
    // while(x < x1)
    // [1896] if(display_frame::x#18<display_frame::x1#16) goto display_frame::@12 -- vbuz1_lt_vbuz2_then_la1 
    lda.z x
    cmp.z x1
    bcc __b12
    // [1897] phi from display_frame::@11 display_frame::@30 to display_frame::@10 [phi:display_frame::@11/display_frame::@30->display_frame::@10]
    // [1897] phi display_frame::x#15 = display_frame::x#18 [phi:display_frame::@11/display_frame::@30->display_frame::@10#0] -- register_copy 
    // display_frame::@10
  __b10:
    // display_frame_maskxy(x, y)
    // [1898] display_frame_maskxy::x#6 = display_frame::x#15 -- vbuxx=vbuz1 
    ldx.z x
    // [1899] display_frame_maskxy::y#6 = display_frame::y#10 -- vbuyy=vbuz1 
    ldy.z y_1
    // [1900] call display_frame_maskxy
    // [2499] phi from display_frame::@10 to display_frame_maskxy [phi:display_frame::@10->display_frame_maskxy]
    // [2499] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#6 [phi:display_frame::@10->display_frame_maskxy#0] -- register_copy 
    // [2499] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#6 [phi:display_frame::@10->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1901] display_frame_maskxy::return#19 = display_frame_maskxy::return#12
    // display_frame::@31
    // mask = display_frame_maskxy(x, y)
    // [1902] display_frame::mask#12 = display_frame_maskxy::return#19
    // mask |= 0b1001
    // [1903] display_frame::mask#13 = display_frame::mask#12 | 9 -- vbuaa=vbuaa_bor_vbuc1 
    ora #9
    // display_frame_char(mask)
    // [1904] display_frame_char::mask#6 = display_frame::mask#13
    // [1905] call display_frame_char
    // [2525] phi from display_frame::@31 to display_frame_char [phi:display_frame::@31->display_frame_char]
    // [2525] phi display_frame_char::mask#10 = display_frame_char::mask#6 [phi:display_frame::@31->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1906] display_frame_char::return#19 = display_frame_char::return#12
    // display_frame::@32
    // c = display_frame_char(mask)
    // [1907] display_frame::c#6 = display_frame_char::return#19
    // cputcxy(x, y, c)
    // [1908] cputcxy::x#6 = display_frame::x#15 -- vbuxx=vbuz1 
    ldx.z x
    // [1909] cputcxy::y#6 = display_frame::y#10 -- vbuyy=vbuz1 
    ldy.z y_1
    // [1910] cputcxy::c#6 = display_frame::c#6 -- vbuz1=vbuaa 
    sta.z cputcxy.c
    // [1911] call cputcxy
    // [1986] phi from display_frame::@32 to cputcxy [phi:display_frame::@32->cputcxy]
    // [1986] phi cputcxy::c#15 = cputcxy::c#6 [phi:display_frame::@32->cputcxy#0] -- register_copy 
    // [1986] phi cputcxy::y#15 = cputcxy::y#6 [phi:display_frame::@32->cputcxy#1] -- register_copy 
    // [1986] phi cputcxy::x#15 = cputcxy::x#6 [phi:display_frame::@32->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@return
  __breturn:
    // }
    // [1912] return 
    rts
    // display_frame::@12
  __b12:
    // display_frame_maskxy(x, y)
    // [1913] display_frame_maskxy::x#7 = display_frame::x#18 -- vbuxx=vbuz1 
    ldx.z x
    // [1914] display_frame_maskxy::y#7 = display_frame::y#10 -- vbuyy=vbuz1 
    ldy.z y_1
    // [1915] call display_frame_maskxy
    // [2499] phi from display_frame::@12 to display_frame_maskxy [phi:display_frame::@12->display_frame_maskxy]
    // [2499] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#7 [phi:display_frame::@12->display_frame_maskxy#0] -- register_copy 
    // [2499] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#7 [phi:display_frame::@12->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1916] display_frame_maskxy::return#20 = display_frame_maskxy::return#12
    // display_frame::@33
    // mask = display_frame_maskxy(x, y)
    // [1917] display_frame::mask#14 = display_frame_maskxy::return#20
    // mask |= 0b0101
    // [1918] display_frame::mask#15 = display_frame::mask#14 | 5 -- vbuaa=vbuaa_bor_vbuc1 
    ora #5
    // display_frame_char(mask)
    // [1919] display_frame_char::mask#7 = display_frame::mask#15
    // [1920] call display_frame_char
    // [2525] phi from display_frame::@33 to display_frame_char [phi:display_frame::@33->display_frame_char]
    // [2525] phi display_frame_char::mask#10 = display_frame_char::mask#7 [phi:display_frame::@33->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1921] display_frame_char::return#20 = display_frame_char::return#12
    // display_frame::@34
    // c = display_frame_char(mask)
    // [1922] display_frame::c#7 = display_frame_char::return#20
    // cputcxy(x, y, c)
    // [1923] cputcxy::x#7 = display_frame::x#18 -- vbuxx=vbuz1 
    ldx.z x
    // [1924] cputcxy::y#7 = display_frame::y#10 -- vbuyy=vbuz1 
    ldy.z y_1
    // [1925] cputcxy::c#7 = display_frame::c#7 -- vbuz1=vbuaa 
    sta.z cputcxy.c
    // [1926] call cputcxy
    // [1986] phi from display_frame::@34 to cputcxy [phi:display_frame::@34->cputcxy]
    // [1986] phi cputcxy::c#15 = cputcxy::c#7 [phi:display_frame::@34->cputcxy#0] -- register_copy 
    // [1986] phi cputcxy::y#15 = cputcxy::y#7 [phi:display_frame::@34->cputcxy#1] -- register_copy 
    // [1986] phi cputcxy::x#15 = cputcxy::x#7 [phi:display_frame::@34->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@35
    // x++;
    // [1927] display_frame::x#5 = ++ display_frame::x#18 -- vbuz1=_inc_vbuz1 
    inc.z x
    jmp __b11
    // display_frame::@7
  __b7:
    // display_frame_maskxy(x0, y)
    // [1928] display_frame_maskxy::x#3 = display_frame::x#0 -- vbuxx=vbuz1 
    ldx.z x
    // [1929] display_frame_maskxy::y#3 = display_frame::y#10 -- vbuyy=vbuz1 
    ldy.z y_1
    // [1930] call display_frame_maskxy
    // [2499] phi from display_frame::@7 to display_frame_maskxy [phi:display_frame::@7->display_frame_maskxy]
    // [2499] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#3 [phi:display_frame::@7->display_frame_maskxy#0] -- register_copy 
    // [2499] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#3 [phi:display_frame::@7->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x0, y)
    // [1931] display_frame_maskxy::return#16 = display_frame_maskxy::return#12
    // display_frame::@22
    // mask = display_frame_maskxy(x0, y)
    // [1932] display_frame::mask#6 = display_frame_maskxy::return#16
    // mask |= 0b1010
    // [1933] display_frame::mask#7 = display_frame::mask#6 | $a -- vbuaa=vbuaa_bor_vbuc1 
    ora #$a
    // display_frame_char(mask)
    // [1934] display_frame_char::mask#3 = display_frame::mask#7
    // [1935] call display_frame_char
    // [2525] phi from display_frame::@22 to display_frame_char [phi:display_frame::@22->display_frame_char]
    // [2525] phi display_frame_char::mask#10 = display_frame_char::mask#3 [phi:display_frame::@22->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1936] display_frame_char::return#16 = display_frame_char::return#12
    // display_frame::@23
    // c = display_frame_char(mask)
    // [1937] display_frame::c#3 = display_frame_char::return#16
    // cputcxy(x0, y, c)
    // [1938] cputcxy::x#3 = display_frame::x#0 -- vbuxx=vbuz1 
    ldx.z x
    // [1939] cputcxy::y#3 = display_frame::y#10 -- vbuyy=vbuz1 
    ldy.z y_1
    // [1940] cputcxy::c#3 = display_frame::c#3 -- vbuz1=vbuaa 
    sta.z cputcxy.c
    // [1941] call cputcxy
    // [1986] phi from display_frame::@23 to cputcxy [phi:display_frame::@23->cputcxy]
    // [1986] phi cputcxy::c#15 = cputcxy::c#3 [phi:display_frame::@23->cputcxy#0] -- register_copy 
    // [1986] phi cputcxy::y#15 = cputcxy::y#3 [phi:display_frame::@23->cputcxy#1] -- register_copy 
    // [1986] phi cputcxy::x#15 = cputcxy::x#3 [phi:display_frame::@23->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@24
    // display_frame_maskxy(x1, y)
    // [1942] display_frame_maskxy::x#4 = display_frame::x1#16 -- vbuxx=vbuz1 
    ldx.z x1
    // [1943] display_frame_maskxy::y#4 = display_frame::y#10 -- vbuyy=vbuz1 
    ldy.z y_1
    // [1944] call display_frame_maskxy
    // [2499] phi from display_frame::@24 to display_frame_maskxy [phi:display_frame::@24->display_frame_maskxy]
    // [2499] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#4 [phi:display_frame::@24->display_frame_maskxy#0] -- register_copy 
    // [2499] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#4 [phi:display_frame::@24->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x1, y)
    // [1945] display_frame_maskxy::return#17 = display_frame_maskxy::return#12
    // display_frame::@25
    // mask = display_frame_maskxy(x1, y)
    // [1946] display_frame::mask#8 = display_frame_maskxy::return#17
    // mask |= 0b1010
    // [1947] display_frame::mask#9 = display_frame::mask#8 | $a -- vbuaa=vbuaa_bor_vbuc1 
    ora #$a
    // display_frame_char(mask)
    // [1948] display_frame_char::mask#4 = display_frame::mask#9
    // [1949] call display_frame_char
    // [2525] phi from display_frame::@25 to display_frame_char [phi:display_frame::@25->display_frame_char]
    // [2525] phi display_frame_char::mask#10 = display_frame_char::mask#4 [phi:display_frame::@25->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1950] display_frame_char::return#17 = display_frame_char::return#12
    // display_frame::@26
    // c = display_frame_char(mask)
    // [1951] display_frame::c#4 = display_frame_char::return#17
    // cputcxy(x1, y, c)
    // [1952] cputcxy::x#4 = display_frame::x1#16 -- vbuxx=vbuz1 
    ldx.z x1
    // [1953] cputcxy::y#4 = display_frame::y#10 -- vbuyy=vbuz1 
    ldy.z y_1
    // [1954] cputcxy::c#4 = display_frame::c#4 -- vbuz1=vbuaa 
    sta.z cputcxy.c
    // [1955] call cputcxy
    // [1986] phi from display_frame::@26 to cputcxy [phi:display_frame::@26->cputcxy]
    // [1986] phi cputcxy::c#15 = cputcxy::c#4 [phi:display_frame::@26->cputcxy#0] -- register_copy 
    // [1986] phi cputcxy::y#15 = cputcxy::y#4 [phi:display_frame::@26->cputcxy#1] -- register_copy 
    // [1986] phi cputcxy::x#15 = cputcxy::x#4 [phi:display_frame::@26->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@27
    // y++;
    // [1956] display_frame::y#2 = ++ display_frame::y#10 -- vbuz1=_inc_vbuz1 
    inc.z y_1
    jmp __b6
    // display_frame::@5
  __b5:
    // display_frame_maskxy(x, y)
    // [1957] display_frame_maskxy::x#2 = display_frame::x#10 -- vbuxx=vbuz1 
    ldx.z x_1
    // [1958] display_frame_maskxy::y#2 = display_frame::y#0 -- vbuyy=vbuz1 
    ldy.z y
    // [1959] call display_frame_maskxy
    // [2499] phi from display_frame::@5 to display_frame_maskxy [phi:display_frame::@5->display_frame_maskxy]
    // [2499] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#2 [phi:display_frame::@5->display_frame_maskxy#0] -- register_copy 
    // [2499] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#2 [phi:display_frame::@5->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1960] display_frame_maskxy::return#15 = display_frame_maskxy::return#12
    // display_frame::@19
    // mask = display_frame_maskxy(x, y)
    // [1961] display_frame::mask#4 = display_frame_maskxy::return#15
    // mask |= 0b0101
    // [1962] display_frame::mask#5 = display_frame::mask#4 | 5 -- vbuaa=vbuaa_bor_vbuc1 
    ora #5
    // display_frame_char(mask)
    // [1963] display_frame_char::mask#2 = display_frame::mask#5
    // [1964] call display_frame_char
    // [2525] phi from display_frame::@19 to display_frame_char [phi:display_frame::@19->display_frame_char]
    // [2525] phi display_frame_char::mask#10 = display_frame_char::mask#2 [phi:display_frame::@19->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1965] display_frame_char::return#15 = display_frame_char::return#12
    // display_frame::@20
    // c = display_frame_char(mask)
    // [1966] display_frame::c#2 = display_frame_char::return#15
    // cputcxy(x, y, c)
    // [1967] cputcxy::x#2 = display_frame::x#10 -- vbuxx=vbuz1 
    ldx.z x_1
    // [1968] cputcxy::y#2 = display_frame::y#0 -- vbuyy=vbuz1 
    ldy.z y
    // [1969] cputcxy::c#2 = display_frame::c#2 -- vbuz1=vbuaa 
    sta.z cputcxy.c
    // [1970] call cputcxy
    // [1986] phi from display_frame::@20 to cputcxy [phi:display_frame::@20->cputcxy]
    // [1986] phi cputcxy::c#15 = cputcxy::c#2 [phi:display_frame::@20->cputcxy#0] -- register_copy 
    // [1986] phi cputcxy::y#15 = cputcxy::y#2 [phi:display_frame::@20->cputcxy#1] -- register_copy 
    // [1986] phi cputcxy::x#15 = cputcxy::x#2 [phi:display_frame::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@21
    // x++;
    // [1971] display_frame::x#2 = ++ display_frame::x#10 -- vbuz1=_inc_vbuz1 
    inc.z x_1
    jmp __b4
    // display_frame::@36
  __b36:
    // [1972] display_frame::x#30 = display_frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z x_1
    jmp __b1
  .segment Data
    .label w = ferror.sp
    h: .byte 0
}
.segment Code
  // cputs
// Output a NUL-terminated string at the current cursor position
// void cputs(__zp($b9) const char *s)
cputs: {
    .label s = $b9
    // [1974] phi from cputs cputs::@2 to cputs::@1 [phi:cputs/cputs::@2->cputs::@1]
    // [1974] phi cputs::s#2 = cputs::s#1 [phi:cputs/cputs::@2->cputs::@1#0] -- register_copy 
    // cputs::@1
  __b1:
    // while(c=*s++)
    // [1975] cputs::c#1 = *cputs::s#2 -- vbuaa=_deref_pbuz1 
    ldy #0
    lda (s),y
    // [1976] cputs::s#0 = ++ cputs::s#2 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [1977] if(0!=cputs::c#1) goto cputs::@2 -- 0_neq_vbuaa_then_la1 
    cmp #0
    bne __b2
    // cputs::@return
    // }
    // [1978] return 
    rts
    // cputs::@2
  __b2:
    // cputc(c)
    // [1979] stackpush(char) = cputs::c#1 -- _stackpushbyte_=vbuaa 
    pha
    // [1980] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
}
  // wherex
// Return the x position of the cursor
wherex: {
    // return __conio.cursor_x;
    // [1982] wherex::return#0 = *((char *)&__conio) -- vbuaa=_deref_pbuc1 
    lda __conio
    // wherex::@return
    // }
    // [1983] return 
    rts
}
  // wherey
// Return the y position of the cursor
wherey: {
    // return __conio.cursor_y;
    // [1984] wherey::return#0 = *((char *)&__conio+1) -- vbuaa=_deref_pbuc1 
    lda __conio+1
    // wherey::@return
    // }
    // [1985] return 
    rts
}
  // cputcxy
// Move cursor and output one character
// Same as "gotoxy (x, y); cputc (c);"
// void cputcxy(__register(X) char x, __register(Y) char y, __zp($42) char c)
cputcxy: {
    .label c = $42
    // gotoxy(x, y)
    // [1987] gotoxy::x#0 = cputcxy::x#15
    // [1988] gotoxy::y#0 = cputcxy::y#15
    // [1989] call gotoxy
    // [718] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [718] phi gotoxy::y#30 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [718] phi gotoxy::x#30 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [1990] stackpush(char) = cputcxy::c#15 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [1991] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [1993] return 
    rts
}
  // display_smc_led
/**
 * @brief Print SMC led above the SMC chip.
 * 
 * @param c Led color
 */
// void display_smc_led(__zp($74) char c)
display_smc_led: {
    .label c = $74
    // display_chip_led(CHIP_SMC_X+1, CHIP_SMC_Y, CHIP_SMC_W, c, BLUE)
    // [1995] display_chip_led::tc#0 = display_smc_led::c#2 -- vbuxx=vbuz1 
    ldx.z c
    // [1996] call display_chip_led
    // [2540] phi from display_smc_led to display_chip_led [phi:display_smc_led->display_chip_led]
    // [2540] phi display_chip_led::w#7 = 5 [phi:display_smc_led->display_chip_led#0] -- vbuz1=vbuc1 
    lda #5
    sta.z display_chip_led.w
    // [2540] phi display_chip_led::x#7 = 1+1 [phi:display_smc_led->display_chip_led#1] -- vbuz1=vbuc1 
    lda #1+1
    sta.z display_chip_led.x
    // [2540] phi display_chip_led::tc#3 = display_chip_led::tc#0 [phi:display_smc_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_smc_led::@1
    // display_info_led(INFO_X-2, INFO_Y, c, BLUE)
    // [1997] display_info_led::tc#0 = display_smc_led::c#2 -- vbuxx=vbuz1 
    ldx.z c
    // [1998] call display_info_led
    // [1757] phi from display_smc_led::@1 to display_info_led [phi:display_smc_led::@1->display_info_led]
    // [1757] phi display_info_led::y#4 = $11 [phi:display_smc_led::@1->display_info_led#0] -- vbuz1=vbuc1 
    lda #$11
    sta.z display_info_led.y
    // [1757] phi display_info_led::x#4 = 4-2 [phi:display_smc_led::@1->display_info_led#1] -- vbuyy=vbuc1 
    ldy #4-2
    // [1757] phi display_info_led::tc#4 = display_info_led::tc#0 [phi:display_smc_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_smc_led::@return
    // }
    // [1999] return 
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
// void display_print_chip(__zp($4f) char x, char y, __zp($54) char w, __zp($36) char *text)
display_print_chip: {
    .label y = 3+2+1+1+1+1+1+1+1+1
    .label text = $36
    .label text_1 = $40
    .label x = $4f
    .label text_2 = $e5
    .label text_3 = $ea
    .label text_6 = $57
    .label w = $54
    // display_chip_line(x, y++, w, *text++)
    // [2001] display_chip_line::x#0 = display_print_chip::x#10 -- vbum1=vbuz2 
    lda.z x
    sta display_chip_line.x
    // [2002] display_chip_line::w#0 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [2003] display_chip_line::c#0 = *display_print_chip::text#11 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_2),y
    sta display_chip_line.c
    // [2004] call display_chip_line
    // [2558] phi from display_print_chip to display_chip_line [phi:display_print_chip->display_chip_line]
    // [2558] phi display_chip_line::c#15 = display_chip_line::c#0 [phi:display_print_chip->display_chip_line#0] -- register_copy 
    // [2558] phi display_chip_line::w#10 = display_chip_line::w#0 [phi:display_print_chip->display_chip_line#1] -- register_copy 
    // [2558] phi display_chip_line::y#16 = 3+2 [phi:display_print_chip->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2
    sta display_chip_line.y
    // [2558] phi display_chip_line::x#16 = display_chip_line::x#0 [phi:display_print_chip->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@1
    // display_chip_line(x, y++, w, *text++);
    // [2005] display_print_chip::text#0 = ++ display_print_chip::text#11 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_2
    adc #1
    sta.z text
    lda.z text_2+1
    adc #0
    sta.z text+1
    // display_chip_line(x, y++, w, *text++)
    // [2006] display_chip_line::x#1 = display_print_chip::x#10 -- vbum1=vbuz2 
    lda.z x
    sta display_chip_line.x
    // [2007] display_chip_line::w#1 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [2008] display_chip_line::c#1 = *display_print_chip::text#0 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text),y
    sta display_chip_line.c
    // [2009] call display_chip_line
    // [2558] phi from display_print_chip::@1 to display_chip_line [phi:display_print_chip::@1->display_chip_line]
    // [2558] phi display_chip_line::c#15 = display_chip_line::c#1 [phi:display_print_chip::@1->display_chip_line#0] -- register_copy 
    // [2558] phi display_chip_line::w#10 = display_chip_line::w#1 [phi:display_print_chip::@1->display_chip_line#1] -- register_copy 
    // [2558] phi display_chip_line::y#16 = ++3+2 [phi:display_print_chip::@1->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1
    sta display_chip_line.y
    // [2558] phi display_chip_line::x#16 = display_chip_line::x#1 [phi:display_print_chip::@1->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@2
    // display_chip_line(x, y++, w, *text++);
    // [2010] display_print_chip::text#1 = ++ display_print_chip::text#0 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text
    adc #1
    sta.z text_1
    lda.z text+1
    adc #0
    sta.z text_1+1
    // display_chip_line(x, y++, w, *text++)
    // [2011] display_chip_line::x#2 = display_print_chip::x#10 -- vbum1=vbuz2 
    lda.z x
    sta display_chip_line.x
    // [2012] display_chip_line::w#2 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [2013] display_chip_line::c#2 = *display_print_chip::text#1 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_1),y
    sta display_chip_line.c
    // [2014] call display_chip_line
    // [2558] phi from display_print_chip::@2 to display_chip_line [phi:display_print_chip::@2->display_chip_line]
    // [2558] phi display_chip_line::c#15 = display_chip_line::c#2 [phi:display_print_chip::@2->display_chip_line#0] -- register_copy 
    // [2558] phi display_chip_line::w#10 = display_chip_line::w#2 [phi:display_print_chip::@2->display_chip_line#1] -- register_copy 
    // [2558] phi display_chip_line::y#16 = ++++3+2 [phi:display_print_chip::@2->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1
    sta display_chip_line.y
    // [2558] phi display_chip_line::x#16 = display_chip_line::x#2 [phi:display_print_chip::@2->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@3
    // display_chip_line(x, y++, w, *text++);
    // [2015] display_print_chip::text#15 = ++ display_print_chip::text#1 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_1
    adc #1
    sta.z text_3
    lda.z text_1+1
    adc #0
    sta.z text_3+1
    // display_chip_line(x, y++, w, *text++)
    // [2016] display_chip_line::x#3 = display_print_chip::x#10 -- vbum1=vbuz2 
    lda.z x
    sta display_chip_line.x
    // [2017] display_chip_line::w#3 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [2018] display_chip_line::c#3 = *display_print_chip::text#15 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_3),y
    sta display_chip_line.c
    // [2019] call display_chip_line
    // [2558] phi from display_print_chip::@3 to display_chip_line [phi:display_print_chip::@3->display_chip_line]
    // [2558] phi display_chip_line::c#15 = display_chip_line::c#3 [phi:display_print_chip::@3->display_chip_line#0] -- register_copy 
    // [2558] phi display_chip_line::w#10 = display_chip_line::w#3 [phi:display_print_chip::@3->display_chip_line#1] -- register_copy 
    // [2558] phi display_chip_line::y#16 = ++++++3+2 [phi:display_print_chip::@3->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1
    sta display_chip_line.y
    // [2558] phi display_chip_line::x#16 = display_chip_line::x#3 [phi:display_print_chip::@3->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@4
    // display_chip_line(x, y++, w, *text++);
    // [2020] display_print_chip::text#16 = ++ display_print_chip::text#15 -- pbum1=_inc_pbuz2 
    clc
    lda.z text_3
    adc #1
    sta text_4
    lda.z text_3+1
    adc #0
    sta text_4+1
    // display_chip_line(x, y++, w, *text++)
    // [2021] display_chip_line::x#4 = display_print_chip::x#10 -- vbum1=vbuz2 
    lda.z x
    sta display_chip_line.x
    // [2022] display_chip_line::w#4 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [2023] display_chip_line::c#4 = *display_print_chip::text#16 -- vbum1=_deref_pbum2 
    ldy text_4
    sty.z $fe
    ldy text_4+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta display_chip_line.c
    // [2024] call display_chip_line
    // [2558] phi from display_print_chip::@4 to display_chip_line [phi:display_print_chip::@4->display_chip_line]
    // [2558] phi display_chip_line::c#15 = display_chip_line::c#4 [phi:display_print_chip::@4->display_chip_line#0] -- register_copy 
    // [2558] phi display_chip_line::w#10 = display_chip_line::w#4 [phi:display_print_chip::@4->display_chip_line#1] -- register_copy 
    // [2558] phi display_chip_line::y#16 = ++++++++3+2 [phi:display_print_chip::@4->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1
    sta display_chip_line.y
    // [2558] phi display_chip_line::x#16 = display_chip_line::x#4 [phi:display_print_chip::@4->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@5
    // display_chip_line(x, y++, w, *text++);
    // [2025] display_print_chip::text#17 = ++ display_print_chip::text#16 -- pbum1=_inc_pbum2 
    clc
    lda text_4
    adc #1
    sta text_5
    lda text_4+1
    adc #0
    sta text_5+1
    // display_chip_line(x, y++, w, *text++)
    // [2026] display_chip_line::x#5 = display_print_chip::x#10 -- vbum1=vbuz2 
    lda.z x
    sta display_chip_line.x
    // [2027] display_chip_line::w#5 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [2028] display_chip_line::c#5 = *display_print_chip::text#17 -- vbum1=_deref_pbum2 
    ldy text_5
    sty.z $fe
    ldy text_5+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta display_chip_line.c
    // [2029] call display_chip_line
    // [2558] phi from display_print_chip::@5 to display_chip_line [phi:display_print_chip::@5->display_chip_line]
    // [2558] phi display_chip_line::c#15 = display_chip_line::c#5 [phi:display_print_chip::@5->display_chip_line#0] -- register_copy 
    // [2558] phi display_chip_line::w#10 = display_chip_line::w#5 [phi:display_print_chip::@5->display_chip_line#1] -- register_copy 
    // [2558] phi display_chip_line::y#16 = ++++++++++3+2 [phi:display_print_chip::@5->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1+1
    sta display_chip_line.y
    // [2558] phi display_chip_line::x#16 = display_chip_line::x#5 [phi:display_print_chip::@5->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@6
    // display_chip_line(x, y++, w, *text++);
    // [2030] display_print_chip::text#18 = ++ display_print_chip::text#17 -- pbuz1=_inc_pbum2 
    clc
    lda text_5
    adc #1
    sta.z text_6
    lda text_5+1
    adc #0
    sta.z text_6+1
    // display_chip_line(x, y++, w, *text++)
    // [2031] display_chip_line::x#6 = display_print_chip::x#10 -- vbum1=vbuz2 
    lda.z x
    sta display_chip_line.x
    // [2032] display_chip_line::w#6 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [2033] display_chip_line::c#6 = *display_print_chip::text#18 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta display_chip_line.c
    // [2034] call display_chip_line
    // [2558] phi from display_print_chip::@6 to display_chip_line [phi:display_print_chip::@6->display_chip_line]
    // [2558] phi display_chip_line::c#15 = display_chip_line::c#6 [phi:display_print_chip::@6->display_chip_line#0] -- register_copy 
    // [2558] phi display_chip_line::w#10 = display_chip_line::w#6 [phi:display_print_chip::@6->display_chip_line#1] -- register_copy 
    // [2558] phi display_chip_line::y#16 = ++++++++++++3+2 [phi:display_print_chip::@6->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1+1+1
    sta display_chip_line.y
    // [2558] phi display_chip_line::x#16 = display_chip_line::x#6 [phi:display_print_chip::@6->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@7
    // display_chip_line(x, y++, w, *text++);
    // [2035] display_print_chip::text#19 = ++ display_print_chip::text#18 -- pbuz1=_inc_pbuz1 
    inc.z text_6
    bne !+
    inc.z text_6+1
  !:
    // display_chip_line(x, y++, w, *text++)
    // [2036] display_chip_line::x#7 = display_print_chip::x#10 -- vbum1=vbuz2 
    lda.z x
    sta display_chip_line.x
    // [2037] display_chip_line::w#7 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [2038] display_chip_line::c#7 = *display_print_chip::text#19 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta display_chip_line.c
    // [2039] call display_chip_line
    // [2558] phi from display_print_chip::@7 to display_chip_line [phi:display_print_chip::@7->display_chip_line]
    // [2558] phi display_chip_line::c#15 = display_chip_line::c#7 [phi:display_print_chip::@7->display_chip_line#0] -- register_copy 
    // [2558] phi display_chip_line::w#10 = display_chip_line::w#7 [phi:display_print_chip::@7->display_chip_line#1] -- register_copy 
    // [2558] phi display_chip_line::y#16 = ++++++++++++++3+2 [phi:display_print_chip::@7->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1+1+1+1
    sta display_chip_line.y
    // [2558] phi display_chip_line::x#16 = display_chip_line::x#7 [phi:display_print_chip::@7->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@8
    // display_chip_end(x, y++, w)
    // [2040] display_chip_end::x#0 = display_print_chip::x#10 -- vbuxx=vbuz1 
    ldx.z x
    // [2041] display_chip_end::w#0 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_end.w
    // [2042] call display_chip_end
    jsr display_chip_end
    // display_print_chip::@return
    // }
    // [2043] return 
    rts
  .segment Data
    .label text_4 = fopen.fopen__11
    .label text_5 = ferror.return
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
    // [2045] display_chip_led::tc#1 = display_vera_led::c#2 -- vbuxx=vbum1 
    ldx c
    // [2046] call display_chip_led
    // [2540] phi from display_vera_led to display_chip_led [phi:display_vera_led->display_chip_led]
    // [2540] phi display_chip_led::w#7 = 8 [phi:display_vera_led->display_chip_led#0] -- vbuz1=vbuc1 
    lda #8
    sta.z display_chip_led.w
    // [2540] phi display_chip_led::x#7 = 9+1 [phi:display_vera_led->display_chip_led#1] -- vbuz1=vbuc1 
    lda #9+1
    sta.z display_chip_led.x
    // [2540] phi display_chip_led::tc#3 = display_chip_led::tc#1 [phi:display_vera_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_vera_led::@1
    // display_info_led(INFO_X-2, INFO_Y+1, c, BLUE)
    // [2047] display_info_led::tc#1 = display_vera_led::c#2 -- vbuxx=vbum1 
    ldx c
    // [2048] call display_info_led
    // [1757] phi from display_vera_led::@1 to display_info_led [phi:display_vera_led::@1->display_info_led]
    // [1757] phi display_info_led::y#4 = $11+1 [phi:display_vera_led::@1->display_info_led#0] -- vbuz1=vbuc1 
    lda #$11+1
    sta.z display_info_led.y
    // [1757] phi display_info_led::x#4 = 4-2 [phi:display_vera_led::@1->display_info_led#1] -- vbuyy=vbuc1 
    ldy #4-2
    // [1757] phi display_info_led::tc#4 = display_info_led::tc#1 [phi:display_vera_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_vera_led::@return
    // }
    // [2049] return 
    rts
  .segment Data
    .label c = main.check_status_smc7_return
}
.segment Code
  // strcat
// Concatenates the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcat(char *destination, __zp($e5) char *source)
strcat: {
    .label strcat__0 = $43
    .label dst = $43
    .label src = $e5
    .label source = $e5
    // strlen(destination)
    // [2051] call strlen
    // [2323] phi from strcat to strlen [phi:strcat->strlen]
    // [2323] phi strlen::str#8 = display_chip_rom::rom [phi:strcat->strlen#0] -- pbuz1=pbuc1 
    lda #<display_chip_rom.rom
    sta.z strlen.str
    lda #>display_chip_rom.rom
    sta.z strlen.str+1
    jsr strlen
    // strlen(destination)
    // [2052] strlen::return#0 = strlen::len#2
    // strcat::@4
    // [2053] strcat::$0 = strlen::return#0
    // char* dst = destination + strlen(destination)
    // [2054] strcat::dst#0 = display_chip_rom::rom + strcat::$0 -- pbuz1=pbuc1_plus_vwuz1 
    lda.z dst
    clc
    adc #<display_chip_rom.rom
    sta.z dst
    lda.z dst+1
    adc #>display_chip_rom.rom
    sta.z dst+1
    // [2055] phi from strcat::@2 strcat::@4 to strcat::@1 [phi:strcat::@2/strcat::@4->strcat::@1]
    // [2055] phi strcat::dst#2 = strcat::dst#1 [phi:strcat::@2/strcat::@4->strcat::@1#0] -- register_copy 
    // [2055] phi strcat::src#2 = strcat::src#1 [phi:strcat::@2/strcat::@4->strcat::@1#1] -- register_copy 
    // strcat::@1
  __b1:
    // while(*src)
    // [2056] if(0!=*strcat::src#2) goto strcat::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcat::@3
    // *dst = 0
    // [2057] *strcat::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcat::@return
    // }
    // [2058] return 
    rts
    // strcat::@2
  __b2:
    // *dst++ = *src++
    // [2059] *strcat::dst#2 = *strcat::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [2060] strcat::dst#1 = ++ strcat::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [2061] strcat::src#1 = ++ strcat::src#2 -- pbuz1=_inc_pbuz1 
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
// void display_rom_led(__zp($da) char chip, __zp($dc) char c)
display_rom_led: {
    .label chip = $da
    .label c = $dc
    // chip*6
    // [2063] display_rom_led::$7 = display_rom_led::chip#2 << 1 -- vbuaa=vbuz1_rol_1 
    lda.z chip
    asl
    // [2064] display_rom_led::$8 = display_rom_led::$7 + display_rom_led::chip#2 -- vbuaa=vbuaa_plus_vbuz1 
    clc
    adc.z chip
    // CHIP_ROM_X+chip*6
    // [2065] display_rom_led::$0 = display_rom_led::$8 << 1 -- vbuaa=vbuaa_rol_1 
    asl
    // display_chip_led(CHIP_ROM_X+chip*6+1, CHIP_ROM_Y, CHIP_ROM_W, c, BLUE)
    // [2066] display_chip_led::x#3 = display_rom_led::$0 + $14+1 -- vbuz1=vbuaa_plus_vbuc1 
    clc
    adc #$14+1
    sta.z display_chip_led.x
    // [2067] display_chip_led::tc#2 = display_rom_led::c#2 -- vbuxx=vbuz1 
    ldx.z c
    // [2068] call display_chip_led
    // [2540] phi from display_rom_led to display_chip_led [phi:display_rom_led->display_chip_led]
    // [2540] phi display_chip_led::w#7 = 3 [phi:display_rom_led->display_chip_led#0] -- vbuz1=vbuc1 
    lda #3
    sta.z display_chip_led.w
    // [2540] phi display_chip_led::x#7 = display_chip_led::x#3 [phi:display_rom_led->display_chip_led#1] -- register_copy 
    // [2540] phi display_chip_led::tc#3 = display_chip_led::tc#2 [phi:display_rom_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_rom_led::@1
    // display_info_led(INFO_X-2, INFO_Y+chip+2, c, BLUE)
    // [2069] display_info_led::y#2 = display_rom_led::chip#2 + $11+2 -- vbuz1=vbuz2_plus_vbuc1 
    lda #$11+2
    clc
    adc.z chip
    sta.z display_info_led.y
    // [2070] display_info_led::tc#2 = display_rom_led::c#2 -- vbuxx=vbuz1 
    ldx.z c
    // [2071] call display_info_led
    // [1757] phi from display_rom_led::@1 to display_info_led [phi:display_rom_led::@1->display_info_led]
    // [1757] phi display_info_led::y#4 = display_info_led::y#2 [phi:display_rom_led::@1->display_info_led#0] -- register_copy 
    // [1757] phi display_info_led::x#4 = 4-2 [phi:display_rom_led::@1->display_info_led#1] -- vbuyy=vbuc1 
    ldy #4-2
    // [1757] phi display_info_led::tc#4 = display_info_led::tc#2 [phi:display_rom_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_rom_led::@return
    // }
    // [2072] return 
    rts
}
  // display_progress_line
/**
 * @brief Print one line of text in the progress frame at a line position.
 * 
 * @param line The start line, counting from 0.
 * @param text The text to be displayed.
 */
// void display_progress_line(__register(X) char line, __zp($29) char *text)
display_progress_line: {
    .label text = $29
    // cputsxy(PROGRESS_X, PROGRESS_Y+line, text)
    // [2073] cputsxy::y#0 = PROGRESS_Y + display_progress_line::line#0 -- vbuyy=vbuc1_plus_vbuxx 
    txa
    clc
    adc #PROGRESS_Y
    tay
    // [2074] cputsxy::s#0 = display_progress_line::text#0
    // [2075] call cputsxy
    // [805] phi from display_progress_line to cputsxy [phi:display_progress_line->cputsxy]
    // [805] phi cputsxy::s#4 = cputsxy::s#0 [phi:display_progress_line->cputsxy#0] -- register_copy 
    // [805] phi cputsxy::y#4 = cputsxy::y#0 [phi:display_progress_line->cputsxy#1] -- register_copy 
    // [805] phi cputsxy::x#4 = PROGRESS_X [phi:display_progress_line->cputsxy#2] -- vbuxx=vbuc1 
    ldx #PROGRESS_X
    jsr cputsxy
    // display_progress_line::@return
    // }
    // [2076] return 
    rts
}
  // utoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void utoa(__zp($29) unsigned int value, __zp($43) char *buffer, __register(X) char radix)
utoa: {
    .label digit_value = $36
    .label buffer = $43
    .label digit = $51
    .label value = $29
    .label max_digits = $78
    .label digit_values = $76
    // if(radix==DECIMAL)
    // [2077] if(utoa::radix#0==DECIMAL) goto utoa::@1 -- vbuxx_eq_vbuc1_then_la1 
    cpx #DECIMAL
    beq __b2
    // utoa::@2
    // if(radix==HEXADECIMAL)
    // [2078] if(utoa::radix#0==HEXADECIMAL) goto utoa::@1 -- vbuxx_eq_vbuc1_then_la1 
    cpx #HEXADECIMAL
    beq __b3
    // utoa::@3
    // if(radix==OCTAL)
    // [2079] if(utoa::radix#0==OCTAL) goto utoa::@1 -- vbuxx_eq_vbuc1_then_la1 
    cpx #OCTAL
    beq __b4
    // utoa::@4
    // if(radix==BINARY)
    // [2080] if(utoa::radix#0==BINARY) goto utoa::@1 -- vbuxx_eq_vbuc1_then_la1 
    cpx #BINARY
    beq __b5
    // utoa::@5
    // *buffer++ = 'e'
    // [2081] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2082] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2083] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2084] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // utoa::@return
    // }
    // [2085] return 
    rts
    // [2086] phi from utoa to utoa::@1 [phi:utoa->utoa::@1]
  __b2:
    // [2086] phi utoa::digit_values#8 = RADIX_DECIMAL_VALUES [phi:utoa->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_DECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES
    sta.z digit_values+1
    // [2086] phi utoa::max_digits#7 = 5 [phi:utoa->utoa::@1#1] -- vbuz1=vbuc1 
    lda #5
    sta.z max_digits
    jmp __b1
    // [2086] phi from utoa::@2 to utoa::@1 [phi:utoa::@2->utoa::@1]
  __b3:
    // [2086] phi utoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES [phi:utoa::@2->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_HEXADECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES
    sta.z digit_values+1
    // [2086] phi utoa::max_digits#7 = 4 [phi:utoa::@2->utoa::@1#1] -- vbuz1=vbuc1 
    lda #4
    sta.z max_digits
    jmp __b1
    // [2086] phi from utoa::@3 to utoa::@1 [phi:utoa::@3->utoa::@1]
  __b4:
    // [2086] phi utoa::digit_values#8 = RADIX_OCTAL_VALUES [phi:utoa::@3->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_OCTAL_VALUES
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES
    sta.z digit_values+1
    // [2086] phi utoa::max_digits#7 = 6 [phi:utoa::@3->utoa::@1#1] -- vbuz1=vbuc1 
    lda #6
    sta.z max_digits
    jmp __b1
    // [2086] phi from utoa::@4 to utoa::@1 [phi:utoa::@4->utoa::@1]
  __b5:
    // [2086] phi utoa::digit_values#8 = RADIX_BINARY_VALUES [phi:utoa::@4->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_BINARY_VALUES
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES
    sta.z digit_values+1
    // [2086] phi utoa::max_digits#7 = $10 [phi:utoa::@4->utoa::@1#1] -- vbuz1=vbuc1 
    lda #$10
    sta.z max_digits
    // utoa::@1
  __b1:
    // [2087] phi from utoa::@1 to utoa::@6 [phi:utoa::@1->utoa::@6]
    // [2087] phi utoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:utoa::@1->utoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2087] phi utoa::started#2 = 0 [phi:utoa::@1->utoa::@6#1] -- vbuxx=vbuc1 
    ldx #0
    // [2087] phi utoa::value#2 = utoa::value#1 [phi:utoa::@1->utoa::@6#2] -- register_copy 
    // [2087] phi utoa::digit#2 = 0 [phi:utoa::@1->utoa::@6#3] -- vbuz1=vbuc1 
    txa
    sta.z digit
    // utoa::@6
  __b6:
    // max_digits-1
    // [2088] utoa::$4 = utoa::max_digits#7 - 1 -- vbuaa=vbuz1_minus_1 
    lda.z max_digits
    sec
    sbc #1
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2089] if(utoa::digit#2<utoa::$4) goto utoa::@7 -- vbuz1_lt_vbuaa_then_la1 
    cmp.z digit
    beq !+
    bcs __b7
  !:
    // utoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2090] utoa::$11 = (char)utoa::value#2 -- vbuxx=_byte_vwuz1 
    ldx.z value
    // [2091] *utoa::buffer#11 = DIGITS[utoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuxx 
    lda DIGITS,x
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2092] utoa::buffer#3 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2093] *utoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // utoa::@7
  __b7:
    // unsigned int digit_value = digit_values[digit]
    // [2094] utoa::$10 = utoa::digit#2 << 1 -- vbuaa=vbuz1_rol_1 
    lda.z digit
    asl
    // [2095] utoa::digit_value#0 = utoa::digit_values#8[utoa::$10] -- vwuz1=pwuz2_derefidx_vbuaa 
    tay
    lda (digit_values),y
    sta.z digit_value
    iny
    lda (digit_values),y
    sta.z digit_value+1
    // if (started || value >= digit_value)
    // [2096] if(0!=utoa::started#2) goto utoa::@10 -- 0_neq_vbuxx_then_la1 
    cpx #0
    bne __b10
    // utoa::@12
    // [2097] if(utoa::value#2>=utoa::digit_value#0) goto utoa::@10 -- vwuz1_ge_vwuz2_then_la1 
    cmp.z value+1
    bne !+
    lda.z digit_value
    cmp.z value
    beq __b10
  !:
    bcc __b10
    // [2098] phi from utoa::@12 to utoa::@9 [phi:utoa::@12->utoa::@9]
    // [2098] phi utoa::buffer#14 = utoa::buffer#11 [phi:utoa::@12->utoa::@9#0] -- register_copy 
    // [2098] phi utoa::started#4 = utoa::started#2 [phi:utoa::@12->utoa::@9#1] -- register_copy 
    // [2098] phi utoa::value#6 = utoa::value#2 [phi:utoa::@12->utoa::@9#2] -- register_copy 
    // utoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2099] utoa::digit#1 = ++ utoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [2087] phi from utoa::@9 to utoa::@6 [phi:utoa::@9->utoa::@6]
    // [2087] phi utoa::buffer#11 = utoa::buffer#14 [phi:utoa::@9->utoa::@6#0] -- register_copy 
    // [2087] phi utoa::started#2 = utoa::started#4 [phi:utoa::@9->utoa::@6#1] -- register_copy 
    // [2087] phi utoa::value#2 = utoa::value#6 [phi:utoa::@9->utoa::@6#2] -- register_copy 
    // [2087] phi utoa::digit#2 = utoa::digit#1 [phi:utoa::@9->utoa::@6#3] -- register_copy 
    jmp __b6
    // utoa::@10
  __b10:
    // utoa_append(buffer++, value, digit_value)
    // [2100] utoa_append::buffer#0 = utoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z utoa_append.buffer
    lda.z buffer+1
    sta.z utoa_append.buffer+1
    // [2101] utoa_append::value#0 = utoa::value#2
    // [2102] utoa_append::sub#0 = utoa::digit_value#0
    // [2103] call utoa_append
    // [2619] phi from utoa::@10 to utoa_append [phi:utoa::@10->utoa_append]
    jsr utoa_append
    // utoa_append(buffer++, value, digit_value)
    // [2104] utoa_append::return#0 = utoa_append::value#2
    // utoa::@11
    // value = utoa_append(buffer++, value, digit_value)
    // [2105] utoa::value#0 = utoa_append::return#0
    // value = utoa_append(buffer++, value, digit_value);
    // [2106] utoa::buffer#4 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2098] phi from utoa::@11 to utoa::@9 [phi:utoa::@11->utoa::@9]
    // [2098] phi utoa::buffer#14 = utoa::buffer#4 [phi:utoa::@11->utoa::@9#0] -- register_copy 
    // [2098] phi utoa::started#4 = 1 [phi:utoa::@11->utoa::@9#1] -- vbuxx=vbuc1 
    ldx #1
    // [2098] phi utoa::value#6 = utoa::value#0 [phi:utoa::@11->utoa::@9#2] -- register_copy 
    jmp __b9
}
  // printf_number_buffer
// Print the contents of the number buffer using a specific format.
// This handles minimum length, zero-filling, and left/right justification from the format
// void printf_number_buffer(__zp($b7) void (*putc)(char), __zp($bf) char buffer_sign, char *buffer_digits, __register(X) char format_min_length, char format_justify_left, char format_sign_always, __zp($be) char format_zero_padding, char format_upper_case, char format_radix)
printf_number_buffer: {
    .label printf_number_buffer__19 = $43
    .label buffer_sign = $bf
    .label format_zero_padding = $be
    .label putc = $b7
    .label padding = $bc
    // if(format.min_length)
    // [2108] if(0==printf_number_buffer::format_min_length#3) goto printf_number_buffer::@1 -- 0_eq_vbuxx_then_la1 
    cpx #0
    beq __b5
    // [2109] phi from printf_number_buffer to printf_number_buffer::@5 [phi:printf_number_buffer->printf_number_buffer::@5]
    // printf_number_buffer::@5
    // strlen(buffer.digits)
    // [2110] call strlen
    // [2323] phi from printf_number_buffer::@5 to strlen [phi:printf_number_buffer::@5->strlen]
    // [2323] phi strlen::str#8 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@5->strlen#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str+1
    jsr strlen
    // strlen(buffer.digits)
    // [2111] strlen::return#3 = strlen::len#2
    // printf_number_buffer::@11
    // [2112] printf_number_buffer::$19 = strlen::return#3
    // signed char len = (signed char)strlen(buffer.digits)
    // [2113] printf_number_buffer::len#0 = (signed char)printf_number_buffer::$19 -- vbsyy=_sbyte_vwuz1 
    // There is a minimum length - work out the padding
    ldy.z printf_number_buffer__19
    // if(buffer.sign)
    // [2114] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@10 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b10
    // printf_number_buffer::@6
    // len++;
    // [2115] printf_number_buffer::len#1 = ++ printf_number_buffer::len#0 -- vbsyy=_inc_vbsyy 
    iny
    // [2116] phi from printf_number_buffer::@11 printf_number_buffer::@6 to printf_number_buffer::@10 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10]
    // [2116] phi printf_number_buffer::len#2 = printf_number_buffer::len#0 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10#0] -- register_copy 
    // printf_number_buffer::@10
  __b10:
    // padding = (signed char)format.min_length - len
    // [2117] printf_number_buffer::padding#1 = (signed char)printf_number_buffer::format_min_length#3 - printf_number_buffer::len#2 -- vbsz1=vbsxx_minus_vbsyy 
    txa
    sty.z $ff
    sec
    sbc.z $ff
    sta.z padding
    // if(padding<0)
    // [2118] if(printf_number_buffer::padding#1>=0) goto printf_number_buffer::@15 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [2120] phi from printf_number_buffer printf_number_buffer::@10 to printf_number_buffer::@1 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1]
  __b5:
    // [2120] phi printf_number_buffer::padding#10 = 0 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [2119] phi from printf_number_buffer::@10 to printf_number_buffer::@15 [phi:printf_number_buffer::@10->printf_number_buffer::@15]
    // printf_number_buffer::@15
    // [2120] phi from printf_number_buffer::@15 to printf_number_buffer::@1 [phi:printf_number_buffer::@15->printf_number_buffer::@1]
    // [2120] phi printf_number_buffer::padding#10 = printf_number_buffer::padding#1 [phi:printf_number_buffer::@15->printf_number_buffer::@1#0] -- register_copy 
    // printf_number_buffer::@1
  __b1:
    // printf_number_buffer::@13
    // if(!format.justify_left && !format.zero_padding && padding)
    // [2121] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_zero_padding
    bne __b2
    // printf_number_buffer::@12
    // [2122] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@7 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b7
    jmp __b2
    // printf_number_buffer::@7
  __b7:
    // printf_padding(putc, ' ',(char)padding)
    // [2123] printf_padding::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [2124] printf_padding::length#0 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [2125] call printf_padding
    // [2329] phi from printf_number_buffer::@7 to printf_padding [phi:printf_number_buffer::@7->printf_padding]
    // [2329] phi printf_padding::putc#7 = printf_padding::putc#0 [phi:printf_number_buffer::@7->printf_padding#0] -- register_copy 
    // [2329] phi printf_padding::pad#7 = ' ' [phi:printf_number_buffer::@7->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [2329] phi printf_padding::length#6 = printf_padding::length#0 [phi:printf_number_buffer::@7->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@2
  __b2:
    // if(buffer.sign)
    // [2126] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@3 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b3
    // printf_number_buffer::@8
    // putc(buffer.sign)
    // [2127] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbuz1 
    pha
    // [2128] callexecute *printf_number_buffer::putc#10  -- call__deref_pprz1 
    jsr icall37
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@3
  __b3:
    // if(format.zero_padding && padding)
    // [2130] if(0==printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@4 -- 0_eq_vbuz1_then_la1 
    lda.z format_zero_padding
    beq __b4
    // printf_number_buffer::@14
    // [2131] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@9 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b9
    jmp __b4
    // printf_number_buffer::@9
  __b9:
    // printf_padding(putc, '0',(char)padding)
    // [2132] printf_padding::putc#1 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [2133] printf_padding::length#1 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [2134] call printf_padding
    // [2329] phi from printf_number_buffer::@9 to printf_padding [phi:printf_number_buffer::@9->printf_padding]
    // [2329] phi printf_padding::putc#7 = printf_padding::putc#1 [phi:printf_number_buffer::@9->printf_padding#0] -- register_copy 
    // [2329] phi printf_padding::pad#7 = '0' [phi:printf_number_buffer::@9->printf_padding#1] -- vbuz1=vbuc1 
    lda #'0'
    sta.z printf_padding.pad
    // [2329] phi printf_padding::length#6 = printf_padding::length#1 [phi:printf_number_buffer::@9->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@4
  __b4:
    // printf_str(putc, buffer.digits)
    // [2135] printf_str::putc#0 = printf_number_buffer::putc#10
    // [2136] call printf_str
    // [987] phi from printf_number_buffer::@4 to printf_str [phi:printf_number_buffer::@4->printf_str]
    // [987] phi printf_str::putc#73 = printf_str::putc#0 [phi:printf_number_buffer::@4->printf_str#0] -- register_copy 
    // [987] phi printf_str::s#73 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@return
    // }
    // [2137] return 
    rts
    // Outside Flow
  icall37:
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
// void rom_unlock(__zp($5b) unsigned long address, __zp($6b) char unlock_code)
rom_unlock: {
    .label chip_address = $32
    .label address = $5b
    .label unlock_code = $6b
    // unsigned long chip_address = address & ROM_CHIP_MASK
    // [2139] rom_unlock::chip_address#0 = rom_unlock::address#5 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [2140] rom_write_byte::address#0 = rom_unlock::chip_address#0 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [2141] call rom_write_byte
  // This is a very important operation...
    // [2626] phi from rom_unlock to rom_write_byte [phi:rom_unlock->rom_write_byte]
    // [2626] phi rom_write_byte::value#10 = $aa [phi:rom_unlock->rom_write_byte#0] -- vbuyy=vbuc1 
    ldy #$aa
    // [2626] phi rom_write_byte::address#4 = rom_write_byte::address#0 [phi:rom_unlock->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@1
    // rom_write_byte(chip_address + 0x02AAA, 0x55)
    // [2142] rom_write_byte::address#1 = rom_unlock::chip_address#0 + $2aaa -- vduz1=vduz2_plus_vwuc1 
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
    // [2143] call rom_write_byte
    // [2626] phi from rom_unlock::@1 to rom_write_byte [phi:rom_unlock::@1->rom_write_byte]
    // [2626] phi rom_write_byte::value#10 = $55 [phi:rom_unlock::@1->rom_write_byte#0] -- vbuyy=vbuc1 
    ldy #$55
    // [2626] phi rom_write_byte::address#4 = rom_write_byte::address#1 [phi:rom_unlock::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@2
    // rom_write_byte(address, unlock_code)
    // [2144] rom_write_byte::address#2 = rom_unlock::address#5 -- vduz1=vduz2 
    lda.z address
    sta.z rom_write_byte.address
    lda.z address+1
    sta.z rom_write_byte.address+1
    lda.z address+2
    sta.z rom_write_byte.address+2
    lda.z address+3
    sta.z rom_write_byte.address+3
    // [2145] rom_write_byte::value#2 = rom_unlock::unlock_code#5 -- vbuyy=vbuz1 
    ldy.z unlock_code
    // [2146] call rom_write_byte
    // [2626] phi from rom_unlock::@2 to rom_write_byte [phi:rom_unlock::@2->rom_write_byte]
    // [2626] phi rom_write_byte::value#10 = rom_write_byte::value#2 [phi:rom_unlock::@2->rom_write_byte#0] -- register_copy 
    // [2626] phi rom_write_byte::address#4 = rom_write_byte::address#2 [phi:rom_unlock::@2->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@return
    // }
    // [2147] return 
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
// __register(A) char rom_read_byte(__zp($45) unsigned long address)
rom_read_byte: {
    .label rom_ptr1_rom_read_byte__0 = $43
    .label rom_ptr1_rom_read_byte__2 = $43
    .label rom_ptr1_return = $43
    .label address = $45
    // rom_read_byte::rom_bank1
    // BYTE2(address)
    // [2149] rom_read_byte::rom_bank1_$0 = byte2  rom_read_byte::address#2 -- vbuaa=_byte2_vduz1 
    lda.z address+2
    // BYTE1(address)
    // [2150] rom_read_byte::rom_bank1_$1 = byte1  rom_read_byte::address#2 -- vbuxx=_byte1_vduz1 
    ldx.z address+1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2151] rom_read_byte::rom_bank1_$2 = rom_read_byte::rom_bank1_$0 w= rom_read_byte::rom_bank1_$1 -- vwum1=vbuaa_word_vbuxx 
    sta rom_bank1_rom_read_byte__2+1
    stx rom_bank1_rom_read_byte__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2152] rom_read_byte::rom_bank1_bank_unshifted#0 = rom_read_byte::rom_bank1_$2 << 2 -- vwum1=vwum1_rol_2 
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2153] rom_read_byte::rom_bank1_return#0 = byte1  rom_read_byte::rom_bank1_bank_unshifted#0 -- vbuxx=_byte1_vwum1 
    ldx rom_bank1_bank_unshifted+1
    // rom_read_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2154] rom_read_byte::rom_ptr1_$2 = (unsigned int)rom_read_byte::address#2 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_read_byte__2
    lda.z address+1
    sta.z rom_ptr1_rom_read_byte__2+1
    // [2155] rom_read_byte::rom_ptr1_$0 = rom_read_byte::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_read_byte__0
    and #<$3fff
    sta.z rom_ptr1_rom_read_byte__0
    lda.z rom_ptr1_rom_read_byte__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_read_byte__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2156] rom_read_byte::rom_ptr1_return#0 = rom_read_byte::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_read_byte::bank_set_brom1
    // BROM = bank
    // [2157] BROM = rom_read_byte::rom_bank1_return#0 -- vbuz1=vbuxx 
    stx.z BROM
    // rom_read_byte::@1
    // return *ptr_rom;
    // [2158] rom_read_byte::return#0 = *((char *)rom_read_byte::rom_ptr1_return#0) -- vbuaa=_deref_pbuz1 
    ldy #0
    lda (rom_ptr1_return),y
    // rom_read_byte::@return
    // }
    // [2159] return 
    rts
  .segment Data
    rom_bank1_rom_read_byte__2: .word 0
    .label rom_bank1_bank_unshifted = rom_bank1_rom_read_byte__2
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
// __zp($36) struct $2 * fopen(__zp($b5) const char *path, const char *mode)
fopen: {
    .label fopen__26 = $30
    .label fopen__28 = $ea
    .label fopen__30 = $36
    .label cbm_k_setnam1_fopen__0 = $43
    .label sp = $f3
    .label stream = $36
    .label pathtoken = $b5
    .label pathpos_1 = $e1
    .label pathtoken_1 = $ef
    .label pathcmp = $c8
    .label path = $b5
    // Parse path
    .label pathstep = $e4
    .label return = $36
    // unsigned char sp = __stdio_filecount
    // [2161] fopen::sp#0 = __stdio_filecount -- vbuz1=vbum2 
    lda __stdio_filecount
    sta.z sp
    // (unsigned int)sp | 0x8000
    // [2162] fopen::$30 = (unsigned int)fopen::sp#0 -- vwuz1=_word_vbuz2 
    sta.z fopen__30
    lda #0
    sta.z fopen__30+1
    // [2163] fopen::stream#0 = fopen::$30 | $8000 -- vwuz1=vwuz1_bor_vwuc1 
    lda.z stream
    ora #<$8000
    sta.z stream
    lda.z stream+1
    ora #>$8000
    sta.z stream+1
    // char pathpos = sp * __STDIO_FILECOUNT
    // [2164] fopen::pathpos#0 = fopen::sp#0 << 1 -- vbum1=vbuz2_rol_1 
    lda.z sp
    asl
    sta pathpos
    // __logical = 0
    // [2165] ((char *)&__stdio_file+$40)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    ldy.z sp
    sta __stdio_file+$40,y
    // __device = 0
    // [2166] ((char *)&__stdio_file+$42)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [2167] ((char *)&__stdio_file+$44)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$44,y
    // [2168] fopen::pathtoken#22 = fopen::pathtoken#0 -- pbuz1=pbuz2 
    lda.z pathtoken
    sta.z pathtoken_1
    lda.z pathtoken+1
    sta.z pathtoken_1+1
    // [2169] fopen::pathpos#21 = fopen::pathpos#0 -- vbuz1=vbum2 
    lda pathpos
    sta.z pathpos_1
    // [2170] phi from fopen to fopen::@8 [phi:fopen->fopen::@8]
    // [2170] phi fopen::num#10 = 0 [phi:fopen->fopen::@8#0] -- vbuxx=vbuc1 
    ldx #0
    // [2170] phi fopen::pathpos#10 = fopen::pathpos#21 [phi:fopen->fopen::@8#1] -- register_copy 
    // [2170] phi fopen::path#10 = fopen::pathtoken#0 [phi:fopen->fopen::@8#2] -- register_copy 
    // [2170] phi fopen::pathstep#10 = 0 [phi:fopen->fopen::@8#3] -- vbuz1=vbuc1 
    txa
    sta.z pathstep
    // [2170] phi fopen::pathtoken#10 = fopen::pathtoken#22 [phi:fopen->fopen::@8#4] -- register_copy 
  // Iterate while path is not \0.
    // [2170] phi from fopen::@22 to fopen::@8 [phi:fopen::@22->fopen::@8]
    // [2170] phi fopen::num#10 = fopen::num#13 [phi:fopen::@22->fopen::@8#0] -- register_copy 
    // [2170] phi fopen::pathpos#10 = fopen::pathpos#7 [phi:fopen::@22->fopen::@8#1] -- register_copy 
    // [2170] phi fopen::path#10 = fopen::path#11 [phi:fopen::@22->fopen::@8#2] -- register_copy 
    // [2170] phi fopen::pathstep#10 = fopen::pathstep#11 [phi:fopen::@22->fopen::@8#3] -- register_copy 
    // [2170] phi fopen::pathtoken#10 = fopen::pathtoken#1 [phi:fopen::@22->fopen::@8#4] -- register_copy 
    // fopen::@8
  __b8:
    // if (*pathtoken == ',' || *pathtoken == '\0')
    // [2171] if(*fopen::pathtoken#10==',') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #','
    ldy #0
    cmp (pathtoken_1),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@33
    // [2172] if(*fopen::pathtoken#10=='@') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #'@'
    cmp (pathtoken_1),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@23
    // if (pathstep == 0)
    // [2173] if(fopen::pathstep#10!=0) goto fopen::@10 -- vbuz1_neq_0_then_la1 
    lda.z pathstep
    bne __b10
    // fopen::@24
    // __stdio_file.filename[pathpos] = *pathtoken
    // [2174] ((char *)&__stdio_file)[fopen::pathpos#10] = *fopen::pathtoken#10 -- pbuc1_derefidx_vbuz1=_deref_pbuz2 
    lda (pathtoken_1),y
    ldy.z pathpos_1
    sta __stdio_file,y
    // pathpos++;
    // [2175] fopen::pathpos#1 = ++ fopen::pathpos#10 -- vbuz1=_inc_vbuz1 
    inc.z pathpos_1
    // [2176] phi from fopen::@12 fopen::@23 fopen::@24 to fopen::@10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10]
    // [2176] phi fopen::num#13 = fopen::num#15 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#0] -- register_copy 
    // [2176] phi fopen::pathpos#7 = fopen::pathpos#10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#1] -- register_copy 
    // [2176] phi fopen::path#11 = fopen::path#13 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#2] -- register_copy 
    // [2176] phi fopen::pathstep#11 = fopen::pathstep#1 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#3] -- register_copy 
    // fopen::@10
  __b10:
    // pathtoken++;
    // [2177] fopen::pathtoken#1 = ++ fopen::pathtoken#10 -- pbuz1=_inc_pbuz1 
    inc.z pathtoken_1
    bne !+
    inc.z pathtoken_1+1
  !:
    // fopen::@22
    // pathtoken - 1
    // [2178] fopen::$28 = fopen::pathtoken#1 - 1 -- pbuz1=pbuz2_minus_1 
    lda.z pathtoken_1
    sec
    sbc #1
    sta.z fopen__28
    lda.z pathtoken_1+1
    sbc #0
    sta.z fopen__28+1
    // while (*(pathtoken - 1))
    // [2179] if(0!=*fopen::$28) goto fopen::@8 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (fopen__28),y
    cmp #0
    bne __b8
    // fopen::@26
    // __status = 0
    // [2180] ((char *)&__stdio_file+$46)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    tya
    ldy.z sp
    sta __stdio_file+$46,y
    // if(!__logical)
    // [2181] if(0!=((char *)&__stdio_file+$40)[fopen::sp#0]) goto fopen::@1 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$40,y
    cmp #0
    bne __b1
    // fopen::@27
    // __stdio_filecount+1
    // [2182] fopen::$4 = __stdio_filecount + 1 -- vbuaa=vbum1_plus_1 
    lda __stdio_filecount
    inc
    // __logical = __stdio_filecount+1
    // [2183] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::$4 -- pbuc1_derefidx_vbuz1=vbuaa 
    sta __stdio_file+$40,y
    // fopen::@1
  __b1:
    // if(!__device)
    // [2184] if(0!=((char *)&__stdio_file+$42)[fopen::sp#0]) goto fopen::@2 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    ldy.z sp
    lda __stdio_file+$42,y
    cmp #0
    bne __b2
    // fopen::@5
    // __device = 8
    // [2185] ((char *)&__stdio_file+$42)[fopen::sp#0] = 8 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #8
    sta __stdio_file+$42,y
    // fopen::@2
  __b2:
    // if(!__channel)
    // [2186] if(0!=((char *)&__stdio_file+$44)[fopen::sp#0]) goto fopen::@3 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    ldy.z sp
    lda __stdio_file+$44,y
    cmp #0
    bne __b3
    // fopen::@6
    // __stdio_filecount+2
    // [2187] fopen::$9 = __stdio_filecount + 2 -- vbuaa=vbum1_plus_2 
    lda __stdio_filecount
    clc
    adc #2
    // __channel = __stdio_filecount+2
    // [2188] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::$9 -- pbuc1_derefidx_vbuz1=vbuaa 
    sta __stdio_file+$44,y
    // fopen::@3
  __b3:
    // __filename
    // [2189] fopen::$11 = (char *)&__stdio_file + fopen::pathpos#0 -- pbum1=pbuc1_plus_vbum2 
    lda pathpos
    clc
    adc #<__stdio_file
    sta fopen__11
    lda #>__stdio_file
    adc #0
    sta fopen__11+1
    // cbm_k_setnam(__filename)
    // [2190] fopen::cbm_k_setnam1_filename = fopen::$11 -- pbum1=pbum2 
    lda fopen__11
    sta cbm_k_setnam1_filename
    lda fopen__11+1
    sta cbm_k_setnam1_filename+1
    // fopen::cbm_k_setnam1
    // strlen(filename)
    // [2191] strlen::str#4 = fopen::cbm_k_setnam1_filename -- pbuz1=pbum2 
    lda cbm_k_setnam1_filename
    sta.z strlen.str
    lda cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [2192] call strlen
    // [2323] phi from fopen::cbm_k_setnam1 to strlen [phi:fopen::cbm_k_setnam1->strlen]
    // [2323] phi strlen::str#8 = strlen::str#4 [phi:fopen::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [2193] strlen::return#11 = strlen::len#2
    // fopen::@31
    // [2194] fopen::cbm_k_setnam1_$0 = strlen::return#11
    // char filename_len = (char)strlen(filename)
    // [2195] fopen::cbm_k_setnam1_filename_len = (char)fopen::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
    lda.z cbm_k_setnam1_fopen__0
    sta cbm_k_setnam1_filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx cbm_k_setnam1_filename
    ldy cbm_k_setnam1_filename+1
    jsr CBM_SETNAM
    // fopen::@28
    // cbm_k_setlfs(__logical, __device, __channel)
    // [2197] cbm_k_setlfs::channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$40,y
    sta cbm_k_setlfs.channel
    // [2198] cbm_k_setlfs::device = ((char *)&__stdio_file+$42)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    lda __stdio_file+$42,y
    sta cbm_k_setlfs.device
    // [2199] cbm_k_setlfs::command = ((char *)&__stdio_file+$44)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    lda __stdio_file+$44,y
    sta cbm_k_setlfs.command
    // [2200] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // fopen::cbm_k_open1
    // asm
    // asm { jsrCBM_OPEN  }
    jsr CBM_OPEN
    // fopen::cbm_k_readst1
    // char status
    // [2202] fopen::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2204] fopen::cbm_k_readst1_return#0 = fopen::cbm_k_readst1_status -- vbuaa=vbum1 
    // fopen::cbm_k_readst1_@return
    // }
    // [2205] fopen::cbm_k_readst1_return#1 = fopen::cbm_k_readst1_return#0
    // fopen::@29
    // cbm_k_readst()
    // [2206] fopen::$15 = fopen::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [2207] ((char *)&__stdio_file+$46)[fopen::sp#0] = fopen::$15 -- pbuc1_derefidx_vbuz1=vbuaa 
    ldy.z sp
    sta __stdio_file+$46,y
    // ferror(stream)
    // [2208] ferror::stream#0 = (struct $2 *)fopen::stream#0
    // [2209] call ferror
    jsr ferror
    // [2210] ferror::return#0 = ferror::return#1
    // fopen::@32
    // [2211] fopen::$16 = ferror::return#0
    // if (ferror(stream))
    // [2212] if(0==fopen::$16) goto fopen::@4 -- 0_eq_vwsm1_then_la1 
    lda fopen__16
    ora fopen__16+1
    beq __b4
    // fopen::@7
    // cbm_k_close(__logical)
    // [2213] fopen::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$40,y
    sta cbm_k_close1_channel
    // fopen::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // [2215] phi from fopen::cbm_k_close1 to fopen::@return [phi:fopen::cbm_k_close1->fopen::@return]
    // [2215] phi fopen::return#2 = 0 [phi:fopen::cbm_k_close1->fopen::@return#0] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fopen::@return
    // }
    // [2216] return 
    rts
    // fopen::@4
  __b4:
    // __stdio_filecount++;
    // [2217] __stdio_filecount = ++ __stdio_filecount -- vbum1=_inc_vbum1 
    inc __stdio_filecount
    // [2218] fopen::return#8 = (struct $2 *)fopen::stream#0
    // [2215] phi from fopen::@4 to fopen::@return [phi:fopen::@4->fopen::@return]
    // [2215] phi fopen::return#2 = fopen::return#8 [phi:fopen::@4->fopen::@return#0] -- register_copy 
    rts
    // fopen::@9
  __b9:
    // if (pathstep > 0)
    // [2219] if(fopen::pathstep#10>0) goto fopen::@11 -- vbuz1_gt_0_then_la1 
    lda.z pathstep
    bne __b11
    // fopen::@25
    // __stdio_file.filename[pathpos] = '\0'
    // [2220] ((char *)&__stdio_file)[fopen::pathpos#10] = '@' -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #'@'
    ldy.z pathpos_1
    sta __stdio_file,y
    // path = pathtoken + 1
    // [2221] fopen::path#0 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
    clc
    lda.z pathtoken_1
    adc #1
    sta.z path
    lda.z pathtoken_1+1
    adc #0
    sta.z path+1
    // [2222] phi from fopen::@16 fopen::@17 fopen::@18 fopen::@19 fopen::@25 to fopen::@12 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12]
    // [2222] phi fopen::num#15 = fopen::num#2 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#0] -- register_copy 
    // [2222] phi fopen::path#13 = fopen::path#16 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#1] -- register_copy 
    // fopen::@12
  __b12:
    // pathstep++;
    // [2223] fopen::pathstep#1 = ++ fopen::pathstep#10 -- vbuz1=_inc_vbuz1 
    inc.z pathstep
    jmp __b10
    // fopen::@11
  __b11:
    // char pathcmp = *path
    // [2224] fopen::pathcmp#0 = *fopen::path#10 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (path),y
    sta.z pathcmp
    // case 'D':
    // [2225] if(fopen::pathcmp#0=='D') goto fopen::@13 -- vbuz1_eq_vbuc1_then_la1 
    lda #'D'
    cmp.z pathcmp
    beq __b13
    // fopen::@20
    // case 'L':
    // [2226] if(fopen::pathcmp#0=='L') goto fopen::@13 -- vbuz1_eq_vbuc1_then_la1 
    lda #'L'
    cmp.z pathcmp
    beq __b13
    // fopen::@21
    // case 'C':
    //                     num = (char)atoi(path + 1);
    //                     path = pathtoken + 1;
    // [2227] if(fopen::pathcmp#0=='C') goto fopen::@13 -- vbuz1_eq_vbuc1_then_la1 
    lda #'C'
    cmp.z pathcmp
    beq __b13
    // [2228] phi from fopen::@21 fopen::@30 to fopen::@14 [phi:fopen::@21/fopen::@30->fopen::@14]
    // [2228] phi fopen::path#16 = fopen::path#10 [phi:fopen::@21/fopen::@30->fopen::@14#0] -- register_copy 
    // [2228] phi fopen::num#2 = fopen::num#10 [phi:fopen::@21/fopen::@30->fopen::@14#1] -- register_copy 
    // fopen::@14
  __b14:
    // case 'L':
    //                     __logical = num;
    //                     break;
    // [2229] if(fopen::pathcmp#0=='L') goto fopen::@17 -- vbuz1_eq_vbuc1_then_la1 
    lda #'L'
    cmp.z pathcmp
    beq __b17
    // fopen::@15
    // case 'D':
    //                     __device = num;
    //                     break;
    // [2230] if(fopen::pathcmp#0=='D') goto fopen::@18 -- vbuz1_eq_vbuc1_then_la1 
    lda #'D'
    cmp.z pathcmp
    beq __b18
    // fopen::@16
    // case 'C':
    //                     __channel = num;
    //                     break;
    // [2231] if(fopen::pathcmp#0!='C') goto fopen::@12 -- vbuz1_neq_vbuc1_then_la1 
    lda #'C'
    cmp.z pathcmp
    bne __b12
    // fopen::@19
    // __channel = num
    // [2232] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbuxx 
    ldy.z sp
    txa
    sta __stdio_file+$44,y
    jmp __b12
    // fopen::@18
  __b18:
    // __device = num
    // [2233] ((char *)&__stdio_file+$42)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbuxx 
    ldy.z sp
    txa
    sta __stdio_file+$42,y
    jmp __b12
    // fopen::@17
  __b17:
    // __logical = num
    // [2234] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbuxx 
    ldy.z sp
    txa
    sta __stdio_file+$40,y
    jmp __b12
    // fopen::@13
  __b13:
    // atoi(path + 1)
    // [2235] atoi::str#0 = fopen::path#10 + 1 -- pbuz1=pbuz1_plus_1 
    inc.z atoi.str
    bne !+
    inc.z atoi.str+1
  !:
    // [2236] call atoi
    // [2692] phi from fopen::@13 to atoi [phi:fopen::@13->atoi]
    // [2692] phi atoi::str#2 = atoi::str#0 [phi:fopen::@13->atoi#0] -- register_copy 
    jsr atoi
    // atoi(path + 1)
    // [2237] atoi::return#3 = atoi::return#2
    // fopen::@30
    // [2238] fopen::$26 = atoi::return#3
    // num = (char)atoi(path + 1)
    // [2239] fopen::num#1 = (char)fopen::$26 -- vbuxx=_byte_vwsz1 
    lda.z fopen__26
    tax
    // path = pathtoken + 1
    // [2240] fopen::path#1 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
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
    .label fopen__16 = ferror.return
    cbm_k_setnam1_filename: .word 0
    cbm_k_setnam1_filename_len: .byte 0
    cbm_k_readst1_status: .byte 0
    cbm_k_close1_channel: .byte 0
    pathpos: .byte 0
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
// __zp($72) unsigned int fgets(__zp($79) char *ptr, __zp($b3) unsigned int size, __zp($c4) struct $2 *stream)
fgets: {
    .label cbm_k_chkin1_channel = $db
    .label cbm_k_chkin1_status = $d5
    .label cbm_k_readst1_status = $d6
    .label cbm_k_readst2_status = $7b
    .label sp = $b2
    .label return = $72
    .label bytes = $5f
    .label read = $72
    .label ptr = $79
    .label remaining = $ab
    .label stream = $c4
    .label size = $b3
    // unsigned char sp = (unsigned char)stream
    // [2242] fgets::sp#0 = (char)fgets::stream#2 -- vbuz1=_byte_pssz2 
    lda.z stream
    sta.z sp
    // cbm_k_chkin(__logical)
    // [2243] fgets::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fgets::sp#0] -- vbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda __stdio_file+$40,y
    sta.z cbm_k_chkin1_channel
    // fgets::cbm_k_chkin1
    // char status
    // [2244] fgets::cbm_k_chkin1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fgets::cbm_k_readst1
    // char status
    // [2246] fgets::cbm_k_readst1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2248] fgets::cbm_k_readst1_return#0 = fgets::cbm_k_readst1_status -- vbuaa=vbuz1 
    // fgets::cbm_k_readst1_@return
    // }
    // [2249] fgets::cbm_k_readst1_return#1 = fgets::cbm_k_readst1_return#0
    // fgets::@11
    // cbm_k_readst()
    // [2250] fgets::$1 = fgets::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [2251] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$1 -- pbuc1_derefidx_vbuz1=vbuaa 
    ldy.z sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2252] if(0==((char *)&__stdio_file+$46)[fgets::sp#0]) goto fgets::@1 -- 0_eq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b1
    // [2253] phi from fgets::@11 fgets::@12 fgets::@5 to fgets::@return [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return]
  __b8:
    // [2253] phi fgets::return#1 = 0 [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return#0] -- vwuz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fgets::@return
    // }
    // [2254] return 
    rts
    // fgets::@1
  __b1:
    // [2255] fgets::remaining#22 = fgets::size#10 -- vwuz1=vwuz2 
    lda.z size
    sta.z remaining
    lda.z size+1
    sta.z remaining+1
    // [2256] phi from fgets::@1 to fgets::@2 [phi:fgets::@1->fgets::@2]
    // [2256] phi fgets::read#10 = 0 [phi:fgets::@1->fgets::@2#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z read
    sta.z read+1
    // [2256] phi fgets::remaining#11 = fgets::remaining#22 [phi:fgets::@1->fgets::@2#1] -- register_copy 
    // [2256] phi fgets::ptr#10 = fgets::ptr#12 [phi:fgets::@1->fgets::@2#2] -- register_copy 
    // [2256] phi from fgets::@17 fgets::@18 to fgets::@2 [phi:fgets::@17/fgets::@18->fgets::@2]
    // [2256] phi fgets::read#10 = fgets::read#1 [phi:fgets::@17/fgets::@18->fgets::@2#0] -- register_copy 
    // [2256] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@17/fgets::@18->fgets::@2#1] -- register_copy 
    // [2256] phi fgets::ptr#10 = fgets::ptr#13 [phi:fgets::@17/fgets::@18->fgets::@2#2] -- register_copy 
    // fgets::@2
  __b2:
    // if (!size)
    // [2257] if(0==fgets::size#10) goto fgets::@3 -- 0_eq_vwuz1_then_la1 
    lda.z size
    ora.z size+1
    bne !__b3+
    jmp __b3
  !__b3:
    // fgets::@8
    // if (remaining >= 512)
    // [2258] if(fgets::remaining#11>=$200) goto fgets::@4 -- vwuz1_ge_vwuc1_then_la1 
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
    // [2259] cx16_k_macptr::bytes = fgets::remaining#11 -- vbuz1=vwuz2 
    lda.z remaining
    sta.z cx16_k_macptr.bytes
    // [2260] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2261] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2262] cx16_k_macptr::return#4 = cx16_k_macptr::return#1
    // fgets::@15
  __b15:
    // bytes = cx16_k_macptr(remaining, ptr)
    // [2263] fgets::bytes#3 = cx16_k_macptr::return#4
    // [2264] phi from fgets::@13 fgets::@14 fgets::@15 to fgets::cbm_k_readst2 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2]
    // [2264] phi fgets::bytes#10 = fgets::bytes#1 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2#0] -- register_copy 
    // fgets::cbm_k_readst2
    // char status
    // [2265] fgets::cbm_k_readst2_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [2267] fgets::cbm_k_readst2_return#0 = fgets::cbm_k_readst2_status -- vbuaa=vbuz1 
    // fgets::cbm_k_readst2_@return
    // }
    // [2268] fgets::cbm_k_readst2_return#1 = fgets::cbm_k_readst2_return#0
    // fgets::@12
    // cbm_k_readst()
    // [2269] fgets::$8 = fgets::cbm_k_readst2_return#1
    // __status = cbm_k_readst()
    // [2270] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$8 -- pbuc1_derefidx_vbuz1=vbuaa 
    ldy.z sp
    sta __stdio_file+$46,y
    // __status & 0xBF
    // [2271] fgets::$9 = ((char *)&__stdio_file+$46)[fgets::sp#0] & $bf -- vbuaa=pbuc1_derefidx_vbuz1_band_vbuc2 
    lda #$bf
    and __stdio_file+$46,y
    // if (__status & 0xBF)
    // [2272] if(0==fgets::$9) goto fgets::@5 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b5
    jmp __b8
    // fgets::@5
  __b5:
    // if (bytes == 0xFFFF)
    // [2273] if(fgets::bytes#10!=$ffff) goto fgets::@6 -- vwuz1_neq_vwuc1_then_la1 
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
    // [2274] fgets::read#1 = fgets::read#10 + fgets::bytes#10 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z read
    adc.z bytes
    sta.z read
    lda.z read+1
    adc.z bytes+1
    sta.z read+1
    // ptr += bytes
    // [2275] fgets::ptr#0 = fgets::ptr#10 + fgets::bytes#10 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z ptr
    adc.z bytes
    sta.z ptr
    lda.z ptr+1
    adc.z bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [2276] fgets::$13 = byte1  fgets::ptr#0 -- vbuaa=_byte1_pbuz1 
    // if (BYTE1(ptr) == 0xC0)
    // [2277] if(fgets::$13!=$c0) goto fgets::@7 -- vbuaa_neq_vbuc1_then_la1 
    cmp #$c0
    bne __b7
    // fgets::@10
    // ptr -= 0x2000
    // [2278] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [2279] phi from fgets::@10 fgets::@6 to fgets::@7 [phi:fgets::@10/fgets::@6->fgets::@7]
    // [2279] phi fgets::ptr#13 = fgets::ptr#1 [phi:fgets::@10/fgets::@6->fgets::@7#0] -- register_copy 
    // fgets::@7
  __b7:
    // remaining -= bytes
    // [2280] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#10 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z remaining
    sec
    sbc.z bytes
    sta.z remaining
    lda.z remaining+1
    sbc.z bytes+1
    sta.z remaining+1
    // while ((__status == 0) && ((size && remaining) || !size))
    // [2281] if(((char *)&__stdio_file+$46)[fgets::sp#0]==0) goto fgets::@16 -- pbuc1_derefidx_vbuz1_eq_0_then_la1 
    ldy.z sp
    lda __stdio_file+$46,y
    cmp #0
    beq __b16
    // [2253] phi from fgets::@17 fgets::@7 to fgets::@return [phi:fgets::@17/fgets::@7->fgets::@return]
    // [2253] phi fgets::return#1 = fgets::read#1 [phi:fgets::@17/fgets::@7->fgets::@return#0] -- register_copy 
    rts
    // fgets::@16
  __b16:
    // while ((__status == 0) && ((size && remaining) || !size))
    // [2282] if(0==fgets::size#10) goto fgets::@17 -- 0_eq_vwuz1_then_la1 
    lda.z size
    ora.z size+1
    beq __b17
    // fgets::@18
    // [2283] if(0!=fgets::remaining#1) goto fgets::@2 -- 0_neq_vwuz1_then_la1 
    lda.z remaining
    ora.z remaining+1
    beq !__b2+
    jmp __b2
  !__b2:
    // fgets::@17
  __b17:
    // [2284] if(0==fgets::size#10) goto fgets::@2 -- 0_eq_vwuz1_then_la1 
    lda.z size
    ora.z size+1
    bne !__b2+
    jmp __b2
  !__b2:
    rts
    // fgets::@4
  __b4:
    // cx16_k_macptr(512, ptr)
    // [2285] cx16_k_macptr::bytes = $200 -- vbuz1=vwuc1 
    lda #<$200
    sta.z cx16_k_macptr.bytes
    // [2286] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2287] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2288] cx16_k_macptr::return#3 = cx16_k_macptr::return#1
    // fgets::@14
    // bytes = cx16_k_macptr(512, ptr)
    // [2289] fgets::bytes#2 = cx16_k_macptr::return#3
    jmp __b15
    // fgets::@3
  __b3:
    // cx16_k_macptr(0, ptr)
    // [2290] cx16_k_macptr::bytes = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cx16_k_macptr.bytes
    // [2291] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2292] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2293] cx16_k_macptr::return#2 = cx16_k_macptr::return#1
    // fgets::@13
    // bytes = cx16_k_macptr(0, ptr)
    // [2294] fgets::bytes#1 = cx16_k_macptr::return#2
    jmp __b15
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
// int fclose(__zp($4b) struct $2 *stream)
fclose: {
    .label stream = $4b
    // unsigned char sp = (unsigned char)stream
    // [2296] fclose::sp#0 = (char)fclose::stream#2 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_chkin(__logical)
    // [2297] fclose::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    tay
    lda __stdio_file+$40,y
    sta cbm_k_chkin1_channel
    // fclose::cbm_k_chkin1
    // char status
    // [2298] fclose::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fclose::cbm_k_readst1
    // char status
    // [2300] fclose::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2302] fclose::cbm_k_readst1_return#0 = fclose::cbm_k_readst1_status -- vbuaa=vbum1 
    // fclose::cbm_k_readst1_@return
    // }
    // [2303] fclose::cbm_k_readst1_return#1 = fclose::cbm_k_readst1_return#0
    // fclose::@3
    // cbm_k_readst()
    // [2304] fclose::$1 = fclose::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [2305] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$1 -- pbuc1_derefidx_vbum1=vbuaa 
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2306] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@1 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b1
    // fclose::@return
    // }
    // [2307] return 
    rts
    // fclose::@1
  __b1:
    // cbm_k_close(__logical)
    // [2308] fclose::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$40,y
    sta cbm_k_close1_channel
    // fclose::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // fclose::cbm_k_readst2
    // char status
    // [2310] fclose::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [2312] fclose::cbm_k_readst2_return#0 = fclose::cbm_k_readst2_status -- vbuaa=vbum1 
    // fclose::cbm_k_readst2_@return
    // }
    // [2313] fclose::cbm_k_readst2_return#1 = fclose::cbm_k_readst2_return#0
    // fclose::@4
    // cbm_k_readst()
    // [2314] fclose::$4 = fclose::cbm_k_readst2_return#1
    // __status = cbm_k_readst()
    // [2315] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$4 -- pbuc1_derefidx_vbum1=vbuaa 
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2316] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@2 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b2
    rts
    // fclose::@2
  __b2:
    // __logical = 0
    // [2317] ((char *)&__stdio_file+$40)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy sp
    sta __stdio_file+$40,y
    // __device = 0
    // [2318] ((char *)&__stdio_file+$42)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [2319] ((char *)&__stdio_file+$44)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$44,y
    // __filename
    // [2320] fclose::$6 = fclose::sp#0 << 1 -- vbuaa=vbum1_rol_1 
    tya
    asl
    // *__filename = '\0'
    // [2321] ((char *)&__stdio_file)[fclose::$6] = '@' -- pbuc1_derefidx_vbuaa=vbuc2 
    tay
    lda #'@'
    sta __stdio_file,y
    // __stdio_filecount--;
    // [2322] __stdio_filecount = -- __stdio_filecount -- vbum1=_dec_vbum1 
    dec __stdio_filecount
    rts
  .segment Data
    cbm_k_chkin1_channel: .byte 0
    cbm_k_chkin1_status: .byte 0
    cbm_k_readst1_status: .byte 0
    cbm_k_close1_channel: .byte 0
    cbm_k_readst2_status: .byte 0
    sp: .byte 0
}
.segment Code
  // strlen
// Computes the length of the string str up to but not including the terminating null character.
// __zp($43) unsigned int strlen(__zp($40) char *str)
strlen: {
    .label return = $43
    .label len = $43
    .label str = $40
    // [2324] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [2324] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z len
    sta.z len+1
    // [2324] phi strlen::str#6 = strlen::str#8 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [2325] if(0!=*strlen::str#6) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [2326] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [2327] strlen::len#1 = ++ strlen::len#2 -- vwuz1=_inc_vwuz1 
    inc.z len
    bne !+
    inc.z len+1
  !:
    // str++;
    // [2328] strlen::str#1 = ++ strlen::str#6 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [2324] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [2324] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [2324] phi strlen::str#6 = strlen::str#1 [phi:strlen::@2->strlen::@1#1] -- register_copy 
    jmp __b1
}
  // printf_padding
// Print a padding char a number of times
// void printf_padding(__zp($36) void (*putc)(char), __zp($53) char pad, __zp($52) char length)
printf_padding: {
    .label i = $42
    .label putc = $36
    .label length = $52
    .label pad = $53
    // [2330] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [2330] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [2331] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z length
    bcc __b2
    // printf_padding::@return
    // }
    // [2332] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [2333] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbuz1 
    lda.z pad
    pha
    // [2334] callexecute *printf_padding::putc#7  -- call__deref_pprz1 
    jsr icall38
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [2336] printf_padding::i#1 = ++ printf_padding::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [2330] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [2330] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
    jmp __b1
    // Outside Flow
  icall38:
    jmp (putc)
}
  // uctoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void uctoa(__register(X) char value, __zp($4b) char *buffer, __register(Y) char radix)
uctoa: {
    .label buffer = $4b
    .label digit = $4f
    .label started = $54
    .label max_digits = $74
    .label digit_values = $72
    // if(radix==DECIMAL)
    // [2337] if(uctoa::radix#0==DECIMAL) goto uctoa::@1 -- vbuyy_eq_vbuc1_then_la1 
    cpy #DECIMAL
    beq __b2
    // uctoa::@2
    // if(radix==HEXADECIMAL)
    // [2338] if(uctoa::radix#0==HEXADECIMAL) goto uctoa::@1 -- vbuyy_eq_vbuc1_then_la1 
    cpy #HEXADECIMAL
    beq __b3
    // uctoa::@3
    // if(radix==OCTAL)
    // [2339] if(uctoa::radix#0==OCTAL) goto uctoa::@1 -- vbuyy_eq_vbuc1_then_la1 
    cpy #OCTAL
    beq __b4
    // uctoa::@4
    // if(radix==BINARY)
    // [2340] if(uctoa::radix#0==BINARY) goto uctoa::@1 -- vbuyy_eq_vbuc1_then_la1 
    cpy #BINARY
    beq __b5
    // uctoa::@5
    // *buffer++ = 'e'
    // [2341] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2342] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2343] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2344] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // uctoa::@return
    // }
    // [2345] return 
    rts
    // [2346] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
  __b2:
    // [2346] phi uctoa::digit_values#8 = RADIX_DECIMAL_VALUES_CHAR [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [2346] phi uctoa::max_digits#7 = 3 [phi:uctoa->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [2346] phi from uctoa::@2 to uctoa::@1 [phi:uctoa::@2->uctoa::@1]
  __b3:
    // [2346] phi uctoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_CHAR [phi:uctoa::@2->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [2346] phi uctoa::max_digits#7 = 2 [phi:uctoa::@2->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #2
    sta.z max_digits
    jmp __b1
    // [2346] phi from uctoa::@3 to uctoa::@1 [phi:uctoa::@3->uctoa::@1]
  __b4:
    // [2346] phi uctoa::digit_values#8 = RADIX_OCTAL_VALUES_CHAR [phi:uctoa::@3->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values+1
    // [2346] phi uctoa::max_digits#7 = 3 [phi:uctoa::@3->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [2346] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
  __b5:
    // [2346] phi uctoa::digit_values#8 = RADIX_BINARY_VALUES_CHAR [phi:uctoa::@4->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_BINARY_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_CHAR
    sta.z digit_values+1
    // [2346] phi uctoa::max_digits#7 = 8 [phi:uctoa::@4->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #8
    sta.z max_digits
    // uctoa::@1
  __b1:
    // [2347] phi from uctoa::@1 to uctoa::@6 [phi:uctoa::@1->uctoa::@6]
    // [2347] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa::@1->uctoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2347] phi uctoa::started#2 = 0 [phi:uctoa::@1->uctoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [2347] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa::@1->uctoa::@6#2] -- register_copy 
    // [2347] phi uctoa::digit#2 = 0 [phi:uctoa::@1->uctoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // uctoa::@6
  __b6:
    // max_digits-1
    // [2348] uctoa::$4 = uctoa::max_digits#7 - 1 -- vbuaa=vbuz1_minus_1 
    lda.z max_digits
    sec
    sbc #1
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2349] if(uctoa::digit#2<uctoa::$4) goto uctoa::@7 -- vbuz1_lt_vbuaa_then_la1 
    cmp.z digit
    beq !+
    bcs __b7
  !:
    // uctoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2350] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbuxx 
    lda DIGITS,x
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2351] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2352] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // uctoa::@7
  __b7:
    // unsigned char digit_value = digit_values[digit]
    // [2353] uctoa::digit_value#0 = uctoa::digit_values#8[uctoa::digit#2] -- vbuyy=pbuz1_derefidx_vbuz2 
    ldy.z digit
    lda (digit_values),y
    tay
    // if (started || value >= digit_value)
    // [2354] if(0!=uctoa::started#2) goto uctoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // uctoa::@12
    // [2355] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@10 -- vbuxx_ge_vbuyy_then_la1 
    sty.z $ff
    cpx.z $ff
    bcs __b10
    // [2356] phi from uctoa::@12 to uctoa::@9 [phi:uctoa::@12->uctoa::@9]
    // [2356] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@12->uctoa::@9#0] -- register_copy 
    // [2356] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@12->uctoa::@9#1] -- register_copy 
    // [2356] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@12->uctoa::@9#2] -- register_copy 
    // uctoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2357] uctoa::digit#1 = ++ uctoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [2347] phi from uctoa::@9 to uctoa::@6 [phi:uctoa::@9->uctoa::@6]
    // [2347] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@9->uctoa::@6#0] -- register_copy 
    // [2347] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@9->uctoa::@6#1] -- register_copy 
    // [2347] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@9->uctoa::@6#2] -- register_copy 
    // [2347] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@9->uctoa::@6#3] -- register_copy 
    jmp __b6
    // uctoa::@10
  __b10:
    // uctoa_append(buffer++, value, digit_value)
    // [2358] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [2359] uctoa_append::value#0 = uctoa::value#2
    // [2360] uctoa_append::sub#0 = uctoa::digit_value#0 -- vbuz1=vbuyy 
    sty.z uctoa_append.sub
    // [2361] call uctoa_append
    // [2713] phi from uctoa::@10 to uctoa_append [phi:uctoa::@10->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [2362] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@11
    // value = uctoa_append(buffer++, value, digit_value)
    // [2363] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [2364] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2356] phi from uctoa::@11 to uctoa::@9 [phi:uctoa::@11->uctoa::@9]
    // [2356] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@11->uctoa::@9#0] -- register_copy 
    // [2356] phi uctoa::started#4 = 1 [phi:uctoa::@11->uctoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [2356] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@11->uctoa::@9#2] -- register_copy 
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
// __mem() unsigned long rom_address_from_bank(__register(A) char rom_bank)
rom_address_from_bank: {
    .label rom_address_from_bank__1 = $45
    .label return = $45
    .label return_1 = $63
    // ((unsigned long)(rom_bank)) << 14
    // [2366] rom_address_from_bank::$1 = (unsigned long)rom_address_from_bank::rom_bank#3 -- vduz1=_dword_vbuaa 
    sta.z rom_address_from_bank__1
    lda #0
    sta.z rom_address_from_bank__1+1
    sta.z rom_address_from_bank__1+2
    sta.z rom_address_from_bank__1+3
    // [2367] rom_address_from_bank::return#0 = rom_address_from_bank::$1 << $e -- vduz1=vduz1_rol_vbuc1 
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
    // [2368] return 
    rts
  .segment Data
    .label return_2 = main.flashed_bytes
}
.segment Code
  // rom_compare
// __zp($61) unsigned int rom_compare(__register(X) char bank_ram, __zp($40) char *ptr_ram, __zp($45) unsigned long rom_compare_address, __zp($ae) unsigned int rom_compare_size)
rom_compare: {
    .label rom_bank1_rom_compare__2 = $55
    .label rom_ptr1_rom_compare__0 = $59
    .label rom_ptr1_rom_compare__2 = $59
    .label rom_bank1_bank_unshifted = $55
    .label rom_ptr1_return = $59
    .label ptr_rom = $59
    .label ptr_ram = $40
    .label compared_bytes = $67
    /// Holds the amount of bytes actually verified between the ROM and the RAM.
    .label equal_bytes = $61
    .label rom_compare_address = $45
    .label return = $61
    .label rom_compare_size = $ae
    // rom_compare::bank_set_bram1
    // BRAM = bank
    // [2370] BRAM = rom_compare::bank_set_bram1_bank#0 -- vbuz1=vbuxx 
    stx.z BRAM
    // rom_compare::rom_bank1
    // BYTE2(address)
    // [2371] rom_compare::rom_bank1_$0 = byte2  rom_compare::rom_compare_address#3 -- vbuaa=_byte2_vduz1 
    lda.z rom_compare_address+2
    // BYTE1(address)
    // [2372] rom_compare::rom_bank1_$1 = byte1  rom_compare::rom_compare_address#3 -- vbuxx=_byte1_vduz1 
    ldx.z rom_compare_address+1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2373] rom_compare::rom_bank1_$2 = rom_compare::rom_bank1_$0 w= rom_compare::rom_bank1_$1 -- vwuz1=vbuaa_word_vbuxx 
    sta.z rom_bank1_rom_compare__2+1
    stx.z rom_bank1_rom_compare__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2374] rom_compare::rom_bank1_bank_unshifted#0 = rom_compare::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2375] rom_compare::rom_bank1_return#0 = byte1  rom_compare::rom_bank1_bank_unshifted#0 -- vbuxx=_byte1_vwuz1 
    ldx.z rom_bank1_bank_unshifted+1
    // rom_compare::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2376] rom_compare::rom_ptr1_$2 = (unsigned int)rom_compare::rom_compare_address#3 -- vwuz1=_word_vduz2 
    lda.z rom_compare_address
    sta.z rom_ptr1_rom_compare__2
    lda.z rom_compare_address+1
    sta.z rom_ptr1_rom_compare__2+1
    // [2377] rom_compare::rom_ptr1_$0 = rom_compare::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_compare__0
    and #<$3fff
    sta.z rom_ptr1_rom_compare__0
    lda.z rom_ptr1_rom_compare__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_compare__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2378] rom_compare::rom_ptr1_return#0 = rom_compare::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_compare::bank_set_brom1
    // BROM = bank
    // [2379] BROM = rom_compare::rom_bank1_return#0 -- vbuz1=vbuxx 
    stx.z BROM
    // [2380] rom_compare::ptr_rom#9 = (char *)rom_compare::rom_ptr1_return#0
    // [2381] phi from rom_compare::bank_set_brom1 to rom_compare::@1 [phi:rom_compare::bank_set_brom1->rom_compare::@1]
    // [2381] phi rom_compare::equal_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z equal_bytes
    sta.z equal_bytes+1
    // [2381] phi rom_compare::ptr_ram#4 = rom_compare::ptr_ram#10 [phi:rom_compare::bank_set_brom1->rom_compare::@1#1] -- register_copy 
    // [2381] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#9 [phi:rom_compare::bank_set_brom1->rom_compare::@1#2] -- register_copy 
    // [2381] phi rom_compare::compared_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#3] -- vwuz1=vwuc1 
    sta.z compared_bytes
    sta.z compared_bytes+1
    // rom_compare::@1
  __b1:
    // while (compared_bytes < rom_compare_size)
    // [2382] if(rom_compare::compared_bytes#2<rom_compare::rom_compare_size#11) goto rom_compare::@2 -- vwuz1_lt_vwuz2_then_la1 
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
    // [2383] return 
    rts
    // rom_compare::@2
  __b2:
    // rom_byte_compare(ptr_rom, *ptr_ram)
    // [2384] rom_byte_compare::ptr_rom#0 = rom_compare::ptr_rom#2
    // [2385] rom_byte_compare::value#0 = *rom_compare::ptr_ram#4 -- vbuaa=_deref_pbuz1 
    ldy #0
    lda (ptr_ram),y
    // [2386] call rom_byte_compare
    jsr rom_byte_compare
    // [2387] rom_byte_compare::return#2 = rom_byte_compare::return#0
    // rom_compare::@5
    // [2388] rom_compare::$5 = rom_byte_compare::return#2
    // if (rom_byte_compare(ptr_rom, *ptr_ram))
    // [2389] if(0==rom_compare::$5) goto rom_compare::@3 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b3
    // rom_compare::@4
    // equal_bytes++;
    // [2390] rom_compare::equal_bytes#1 = ++ rom_compare::equal_bytes#2 -- vwuz1=_inc_vwuz1 
    inc.z equal_bytes
    bne !+
    inc.z equal_bytes+1
  !:
    // [2391] phi from rom_compare::@4 rom_compare::@5 to rom_compare::@3 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3]
    // [2391] phi rom_compare::equal_bytes#6 = rom_compare::equal_bytes#1 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3#0] -- register_copy 
    // rom_compare::@3
  __b3:
    // ptr_rom++;
    // [2392] rom_compare::ptr_rom#1 = ++ rom_compare::ptr_rom#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr_rom
    bne !+
    inc.z ptr_rom+1
  !:
    // ptr_ram++;
    // [2393] rom_compare::ptr_ram#0 = ++ rom_compare::ptr_ram#4 -- pbuz1=_inc_pbuz1 
    inc.z ptr_ram
    bne !+
    inc.z ptr_ram+1
  !:
    // compared_bytes++;
    // [2394] rom_compare::compared_bytes#1 = ++ rom_compare::compared_bytes#2 -- vwuz1=_inc_vwuz1 
    inc.z compared_bytes
    bne !+
    inc.z compared_bytes+1
  !:
    // [2381] phi from rom_compare::@3 to rom_compare::@1 [phi:rom_compare::@3->rom_compare::@1]
    // [2381] phi rom_compare::equal_bytes#2 = rom_compare::equal_bytes#6 [phi:rom_compare::@3->rom_compare::@1#0] -- register_copy 
    // [2381] phi rom_compare::ptr_ram#4 = rom_compare::ptr_ram#0 [phi:rom_compare::@3->rom_compare::@1#1] -- register_copy 
    // [2381] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#1 [phi:rom_compare::@3->rom_compare::@1#2] -- register_copy 
    // [2381] phi rom_compare::compared_bytes#2 = rom_compare::compared_bytes#1 [phi:rom_compare::@3->rom_compare::@1#3] -- register_copy 
    jmp __b1
}
  // ultoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void ultoa(__zp($25) unsigned long value, __zp($4d) char *buffer, __register(X) char radix)
ultoa: {
    .label digit_value = $32
    .label buffer = $4d
    .label digit = $50
    .label value = $25
    .label max_digits = $75
    .label digit_values = $69
    // if(radix==DECIMAL)
    // [2395] if(ultoa::radix#0==DECIMAL) goto ultoa::@1 -- vbuxx_eq_vbuc1_then_la1 
    cpx #DECIMAL
    beq __b2
    // ultoa::@2
    // if(radix==HEXADECIMAL)
    // [2396] if(ultoa::radix#0==HEXADECIMAL) goto ultoa::@1 -- vbuxx_eq_vbuc1_then_la1 
    cpx #HEXADECIMAL
    beq __b3
    // ultoa::@3
    // if(radix==OCTAL)
    // [2397] if(ultoa::radix#0==OCTAL) goto ultoa::@1 -- vbuxx_eq_vbuc1_then_la1 
    cpx #OCTAL
    beq __b4
    // ultoa::@4
    // if(radix==BINARY)
    // [2398] if(ultoa::radix#0==BINARY) goto ultoa::@1 -- vbuxx_eq_vbuc1_then_la1 
    cpx #BINARY
    beq __b5
    // ultoa::@5
    // *buffer++ = 'e'
    // [2399] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2400] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2401] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2402] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // ultoa::@return
    // }
    // [2403] return 
    rts
    // [2404] phi from ultoa to ultoa::@1 [phi:ultoa->ultoa::@1]
  __b2:
    // [2404] phi ultoa::digit_values#8 = RADIX_DECIMAL_VALUES_LONG [phi:ultoa->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2404] phi ultoa::max_digits#7 = $a [phi:ultoa->ultoa::@1#1] -- vbuz1=vbuc1 
    lda #$a
    sta.z max_digits
    jmp __b1
    // [2404] phi from ultoa::@2 to ultoa::@1 [phi:ultoa::@2->ultoa::@1]
  __b3:
    // [2404] phi ultoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_LONG [phi:ultoa::@2->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2404] phi ultoa::max_digits#7 = 8 [phi:ultoa::@2->ultoa::@1#1] -- vbuz1=vbuc1 
    lda #8
    sta.z max_digits
    jmp __b1
    // [2404] phi from ultoa::@3 to ultoa::@1 [phi:ultoa::@3->ultoa::@1]
  __b4:
    // [2404] phi ultoa::digit_values#8 = RADIX_OCTAL_VALUES_LONG [phi:ultoa::@3->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_OCTAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_LONG
    sta.z digit_values+1
    // [2404] phi ultoa::max_digits#7 = $b [phi:ultoa::@3->ultoa::@1#1] -- vbuz1=vbuc1 
    lda #$b
    sta.z max_digits
    jmp __b1
    // [2404] phi from ultoa::@4 to ultoa::@1 [phi:ultoa::@4->ultoa::@1]
  __b5:
    // [2404] phi ultoa::digit_values#8 = RADIX_BINARY_VALUES_LONG [phi:ultoa::@4->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_BINARY_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_LONG
    sta.z digit_values+1
    // [2404] phi ultoa::max_digits#7 = $20 [phi:ultoa::@4->ultoa::@1#1] -- vbuz1=vbuc1 
    lda #$20
    sta.z max_digits
    // ultoa::@1
  __b1:
    // [2405] phi from ultoa::@1 to ultoa::@6 [phi:ultoa::@1->ultoa::@6]
    // [2405] phi ultoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:ultoa::@1->ultoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2405] phi ultoa::started#2 = 0 [phi:ultoa::@1->ultoa::@6#1] -- vbuxx=vbuc1 
    ldx #0
    // [2405] phi ultoa::value#2 = ultoa::value#1 [phi:ultoa::@1->ultoa::@6#2] -- register_copy 
    // [2405] phi ultoa::digit#2 = 0 [phi:ultoa::@1->ultoa::@6#3] -- vbuz1=vbuc1 
    txa
    sta.z digit
    // ultoa::@6
  __b6:
    // max_digits-1
    // [2406] ultoa::$4 = ultoa::max_digits#7 - 1 -- vbuaa=vbuz1_minus_1 
    lda.z max_digits
    sec
    sbc #1
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2407] if(ultoa::digit#2<ultoa::$4) goto ultoa::@7 -- vbuz1_lt_vbuaa_then_la1 
    cmp.z digit
    beq !+
    bcs __b7
  !:
    // ultoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2408] ultoa::$11 = (char)ultoa::value#2 -- vbuaa=_byte_vduz1 
    lda.z value
    // [2409] *ultoa::buffer#11 = DIGITS[ultoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuaa 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2410] ultoa::buffer#3 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2411] *ultoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // ultoa::@7
  __b7:
    // unsigned long digit_value = digit_values[digit]
    // [2412] ultoa::$10 = ultoa::digit#2 << 2 -- vbuaa=vbuz1_rol_2 
    lda.z digit
    asl
    asl
    // [2413] ultoa::digit_value#0 = ultoa::digit_values#8[ultoa::$10] -- vduz1=pduz2_derefidx_vbuaa 
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
    // [2414] if(0!=ultoa::started#2) goto ultoa::@10 -- 0_neq_vbuxx_then_la1 
    cpx #0
    bne __b10
    // ultoa::@12
    // [2415] if(ultoa::value#2>=ultoa::digit_value#0) goto ultoa::@10 -- vduz1_ge_vduz2_then_la1 
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
    // [2416] phi from ultoa::@12 to ultoa::@9 [phi:ultoa::@12->ultoa::@9]
    // [2416] phi ultoa::buffer#14 = ultoa::buffer#11 [phi:ultoa::@12->ultoa::@9#0] -- register_copy 
    // [2416] phi ultoa::started#4 = ultoa::started#2 [phi:ultoa::@12->ultoa::@9#1] -- register_copy 
    // [2416] phi ultoa::value#6 = ultoa::value#2 [phi:ultoa::@12->ultoa::@9#2] -- register_copy 
    // ultoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2417] ultoa::digit#1 = ++ ultoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [2405] phi from ultoa::@9 to ultoa::@6 [phi:ultoa::@9->ultoa::@6]
    // [2405] phi ultoa::buffer#11 = ultoa::buffer#14 [phi:ultoa::@9->ultoa::@6#0] -- register_copy 
    // [2405] phi ultoa::started#2 = ultoa::started#4 [phi:ultoa::@9->ultoa::@6#1] -- register_copy 
    // [2405] phi ultoa::value#2 = ultoa::value#6 [phi:ultoa::@9->ultoa::@6#2] -- register_copy 
    // [2405] phi ultoa::digit#2 = ultoa::digit#1 [phi:ultoa::@9->ultoa::@6#3] -- register_copy 
    jmp __b6
    // ultoa::@10
  __b10:
    // ultoa_append(buffer++, value, digit_value)
    // [2418] ultoa_append::buffer#0 = ultoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z ultoa_append.buffer
    lda.z buffer+1
    sta.z ultoa_append.buffer+1
    // [2419] ultoa_append::value#0 = ultoa::value#2
    // [2420] ultoa_append::sub#0 = ultoa::digit_value#0
    // [2421] call ultoa_append
    // [2724] phi from ultoa::@10 to ultoa_append [phi:ultoa::@10->ultoa_append]
    jsr ultoa_append
    // ultoa_append(buffer++, value, digit_value)
    // [2422] ultoa_append::return#0 = ultoa_append::value#2
    // ultoa::@11
    // value = ultoa_append(buffer++, value, digit_value)
    // [2423] ultoa::value#0 = ultoa_append::return#0
    // value = ultoa_append(buffer++, value, digit_value);
    // [2424] ultoa::buffer#4 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2416] phi from ultoa::@11 to ultoa::@9 [phi:ultoa::@11->ultoa::@9]
    // [2416] phi ultoa::buffer#14 = ultoa::buffer#4 [phi:ultoa::@11->ultoa::@9#0] -- register_copy 
    // [2416] phi ultoa::started#4 = 1 [phi:ultoa::@11->ultoa::@9#1] -- vbuxx=vbuc1 
    ldx #1
    // [2416] phi ultoa::value#6 = ultoa::value#0 [phi:ultoa::@11->ultoa::@9#2] -- register_copy 
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
// void rom_sector_erase(__zp($dd) unsigned long address)
rom_sector_erase: {
    .label rom_ptr1_rom_sector_erase__0 = $30
    .label rom_ptr1_rom_sector_erase__2 = $30
    .label rom_ptr1_return = $30
    .label rom_chip_address = $5b
    .label address = $dd
    // rom_sector_erase::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2426] rom_sector_erase::rom_ptr1_$2 = (unsigned int)rom_sector_erase::address#0 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_sector_erase__2
    lda.z address+1
    sta.z rom_ptr1_rom_sector_erase__2+1
    // [2427] rom_sector_erase::rom_ptr1_$0 = rom_sector_erase::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_sector_erase__0
    and #<$3fff
    sta.z rom_ptr1_rom_sector_erase__0
    lda.z rom_ptr1_rom_sector_erase__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_sector_erase__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2428] rom_sector_erase::rom_ptr1_return#0 = rom_sector_erase::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_sector_erase::@1
    // unsigned long rom_chip_address = address & ROM_CHIP_MASK
    // [2429] rom_sector_erase::rom_chip_address#0 = rom_sector_erase::address#0 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [2430] rom_unlock::address#0 = rom_sector_erase::rom_chip_address#0 + $5555 -- vduz1=vduz1_plus_vwuc1 
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
    // [2431] call rom_unlock
    // [2138] phi from rom_sector_erase::@1 to rom_unlock [phi:rom_sector_erase::@1->rom_unlock]
    // [2138] phi rom_unlock::unlock_code#5 = $80 [phi:rom_sector_erase::@1->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$80
    sta.z rom_unlock.unlock_code
    // [2138] phi rom_unlock::address#5 = rom_unlock::address#0 [phi:rom_sector_erase::@1->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@2
    // rom_unlock(address, 0x30)
    // [2432] rom_unlock::address#1 = rom_sector_erase::address#0 -- vduz1=vduz2 
    lda.z address
    sta.z rom_unlock.address
    lda.z address+1
    sta.z rom_unlock.address+1
    lda.z address+2
    sta.z rom_unlock.address+2
    lda.z address+3
    sta.z rom_unlock.address+3
    // [2433] call rom_unlock
    // [2138] phi from rom_sector_erase::@2 to rom_unlock [phi:rom_sector_erase::@2->rom_unlock]
    // [2138] phi rom_unlock::unlock_code#5 = $30 [phi:rom_sector_erase::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$30
    sta.z rom_unlock.unlock_code
    // [2138] phi rom_unlock::address#5 = rom_unlock::address#1 [phi:rom_sector_erase::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@3
    // rom_wait(ptr_rom)
    // [2434] rom_wait::ptr_rom#0 = (char *)rom_sector_erase::rom_ptr1_return#0
    // [2435] call rom_wait
    // [2731] phi from rom_sector_erase::@3 to rom_wait [phi:rom_sector_erase::@3->rom_wait]
    // [2731] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#0 [phi:rom_sector_erase::@3->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_sector_erase::@return
    // }
    // [2436] return 
    rts
}
  // rom_write
/* inline */
// unsigned long rom_write(__register(X) char flash_ram_bank, __zp($69) char *flash_ram_address, __zp($6c) unsigned long flash_rom_address, unsigned int flash_rom_size)
rom_write: {
    .label rom_chip_address = $7c
    .label flash_rom_address = $6c
    .label flash_ram_address = $69
    .label flashed_bytes = $63
    // unsigned long rom_chip_address = flash_rom_address & ROM_CHIP_MASK
    // [2437] rom_write::rom_chip_address#0 = rom_write::flash_rom_address#1 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [2438] BRAM = rom_write::flash_ram_bank#0 -- vbuz1=vbuxx 
    stx.z BRAM
    // [2439] phi from rom_write::bank_set_bram1 to rom_write::@1 [phi:rom_write::bank_set_bram1->rom_write::@1]
    // [2439] phi rom_write::flash_ram_address#2 = rom_write::flash_ram_address#1 [phi:rom_write::bank_set_bram1->rom_write::@1#0] -- register_copy 
    // [2439] phi rom_write::flash_rom_address#3 = rom_write::flash_rom_address#1 [phi:rom_write::bank_set_bram1->rom_write::@1#1] -- register_copy 
    // [2439] phi rom_write::flashed_bytes#2 = 0 [phi:rom_write::bank_set_bram1->rom_write::@1#2] -- vduz1=vduc1 
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
    // [2440] if(rom_write::flashed_bytes#2<ROM_PROGRESS_CELL) goto rom_write::@2 -- vduz1_lt_vduc1_then_la1 
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
    // [2441] return 
    rts
    // rom_write::@2
  __b2:
    // rom_unlock(rom_chip_address + 0x05555, 0xA0)
    // [2442] rom_unlock::address#4 = rom_write::rom_chip_address#0 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [2443] call rom_unlock
    // [2138] phi from rom_write::@2 to rom_unlock [phi:rom_write::@2->rom_unlock]
    // [2138] phi rom_unlock::unlock_code#5 = $a0 [phi:rom_write::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$a0
    sta.z rom_unlock.unlock_code
    // [2138] phi rom_unlock::address#5 = rom_unlock::address#4 [phi:rom_write::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_write::@3
    // rom_byte_program(flash_rom_address, *flash_ram_address)
    // [2444] rom_byte_program::address#0 = rom_write::flash_rom_address#3 -- vduz1=vduz2 
    lda.z flash_rom_address
    sta.z rom_byte_program.address
    lda.z flash_rom_address+1
    sta.z rom_byte_program.address+1
    lda.z flash_rom_address+2
    sta.z rom_byte_program.address+2
    lda.z flash_rom_address+3
    sta.z rom_byte_program.address+3
    // [2445] rom_byte_program::value#0 = *rom_write::flash_ram_address#2 -- vbuyy=_deref_pbuz1 
    ldy #0
    lda (flash_ram_address),y
    tay
    // [2446] call rom_byte_program
    // [2738] phi from rom_write::@3 to rom_byte_program [phi:rom_write::@3->rom_byte_program]
    jsr rom_byte_program
    // rom_write::@4
    // flash_rom_address++;
    // [2447] rom_write::flash_rom_address#0 = ++ rom_write::flash_rom_address#3 -- vduz1=_inc_vduz1 
    inc.z flash_rom_address
    bne !+
    inc.z flash_rom_address+1
    bne !+
    inc.z flash_rom_address+2
    bne !+
    inc.z flash_rom_address+3
  !:
    // flash_ram_address++;
    // [2448] rom_write::flash_ram_address#0 = ++ rom_write::flash_ram_address#2 -- pbuz1=_inc_pbuz1 
    inc.z flash_ram_address
    bne !+
    inc.z flash_ram_address+1
  !:
    // flashed_bytes++;
    // [2449] rom_write::flashed_bytes#1 = ++ rom_write::flashed_bytes#2 -- vduz1=_inc_vduz1 
    inc.z flashed_bytes
    bne !+
    inc.z flashed_bytes+1
    bne !+
    inc.z flashed_bytes+2
    bne !+
    inc.z flashed_bytes+3
  !:
    // [2439] phi from rom_write::@4 to rom_write::@1 [phi:rom_write::@4->rom_write::@1]
    // [2439] phi rom_write::flash_ram_address#2 = rom_write::flash_ram_address#0 [phi:rom_write::@4->rom_write::@1#0] -- register_copy 
    // [2439] phi rom_write::flash_rom_address#3 = rom_write::flash_rom_address#0 [phi:rom_write::@4->rom_write::@1#1] -- register_copy 
    // [2439] phi rom_write::flashed_bytes#2 = rom_write::flashed_bytes#1 [phi:rom_write::@4->rom_write::@1#2] -- register_copy 
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
    // [2450] cbm_k_getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // asm
    // asm { jsrCBM_GETIN stach  }
    jsr CBM_GETIN
    sta ch
    // return ch;
    // [2452] cbm_k_getin::return#0 = cbm_k_getin::ch -- vbuaa=vbum1 
    // cbm_k_getin::@return
    // }
    // [2453] cbm_k_getin::return#1 = cbm_k_getin::return#0
    // [2454] return 
    rts
  .segment Data
    ch: .byte 0
}
.segment Code
  // strncpy
/// Copies up to n characters from the string pointed to, by src to dst.
/// In a case where the length of src is less than that of n, the remainder of dst will be padded with null bytes.
/// @param dst ? This is the pointer to the destination array where the content is to be copied.
/// @param src ? This is the string to be copied.
/// @param n ? The number of characters to be copied from source.
/// @return The destination
// char * strncpy(__zp($49) char *dst, __zp($3e) const char *src, __zp($61) unsigned int n)
strncpy: {
    .label dst = $49
    .label i = $4d
    .label src = $3e
    .label n = $61
    // [2456] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [2456] phi strncpy::dst#3 = strncpy::dst#8 [phi:strncpy->strncpy::@1#0] -- register_copy 
    // [2456] phi strncpy::src#3 = strncpy::src#6 [phi:strncpy->strncpy::@1#1] -- register_copy 
    // [2456] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwuz1=vwuc1 
    lda #<0
    sta.z i
    sta.z i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [2457] if(strncpy::i#2<strncpy::n#3) goto strncpy::@2 -- vwuz1_lt_vwuz2_then_la1 
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
    // [2458] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [2459] strncpy::c#0 = *strncpy::src#3 -- vbuaa=_deref_pbuz1 
    ldy #0
    lda (src),y
    // if(c)
    // [2460] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b3
    // strncpy::@4
    // src++;
    // [2461] strncpy::src#0 = ++ strncpy::src#3 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [2462] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [2462] phi strncpy::src#7 = strncpy::src#3 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [2463] *strncpy::dst#3 = strncpy::c#0 -- _deref_pbuz1=vbuaa 
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [2464] strncpy::dst#0 = ++ strncpy::dst#3 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [2465] strncpy::i#1 = ++ strncpy::i#2 -- vwuz1=_inc_vwuz1 
    inc.z i
    bne !+
    inc.z i+1
  !:
    // [2456] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [2456] phi strncpy::dst#3 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [2456] phi strncpy::src#3 = strncpy::src#7 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [2456] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
    jmp __b1
}
  // insertup
// Insert a new line, and scroll the upper part of the screen up.
// void insertup(char rows)
insertup: {
    .label width = $39
    .label y = $2b
    // __conio.width+1
    // [2466] insertup::$0 = *((char *)&__conio+6) + 1 -- vbuaa=_deref_pbuc1_plus_1 
    lda __conio+6
    inc
    // unsigned char width = (__conio.width+1) * 2
    // [2467] insertup::width#0 = insertup::$0 << 1 -- vbuz1=vbuaa_rol_1 
    // {asm{.byte $db}}
    asl
    sta.z width
    // [2468] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [2468] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [2469] if(insertup::y#2<*((char *)&__conio+1)) goto insertup::@2 -- vbuz1_lt__deref_pbuc1_then_la1 
    lda.z y
    cmp __conio+1
    bcc __b2
    // [2470] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [2471] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [2472] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [2473] insertup::$4 = insertup::y#2 + 1 -- vbuxx=vbuz1_plus_1 
    ldx.z y
    inx
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [2474] insertup::$6 = insertup::y#2 << 1 -- vbuyy=vbuz1_rol_1 
    lda.z y
    asl
    tay
    // [2475] insertup::$7 = insertup::$4 << 1 -- vbuxx=vbuxx_rol_1 
    txa
    asl
    tax
    // [2476] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z memcpy8_vram_vram.dbank_vram
    // [2477] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwuz1=pwuc1_derefidx_vbuyy 
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.doffset_vram+1
    // [2478] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+5) -- vbuyy=_deref_pbuc1 
    ldy __conio+5
    // [2479] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwuz1=pwuc1_derefidx_vbuxx 
    lda __conio+$15,x
    sta.z memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,x
    sta.z memcpy8_vram_vram.soffset_vram+1
    // [2480] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbuz1=vbuz2 
    lda.z width
    sta.z memcpy8_vram_vram.num8
    // [2481] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [2482] insertup::y#1 = ++ insertup::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [2468] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [2468] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
    jmp __b1
}
  // clearline
clearline: {
    .label addr = $2c
    // unsigned int addr = __conio.offsets[__conio.cursor_y]
    // [2483] clearline::$3 = *((char *)&__conio+1) << 1 -- vbuaa=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    // [2484] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwuz1=pwuc1_derefidx_vbuaa 
    tay
    lda __conio+$15,y
    sta.z addr
    lda __conio+$15+1,y
    sta.z addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2485] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [2486] clearline::$0 = byte0  clearline::addr#0 -- vbuaa=_byte0_vwuz1 
    lda.z addr
    // *VERA_ADDRX_L = BYTE0(addr)
    // [2487] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [2488] clearline::$1 = byte1  clearline::addr#0 -- vbuaa=_byte1_vwuz1 
    lda.z addr+1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [2489] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [2490] clearline::$2 = *((char *)&__conio+5) | VERA_INC_1 -- vbuaa=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [2491] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [2492] clearline::c#0 = *((char *)&__conio+6) -- vbuxx=_deref_pbuc1 
    ldx __conio+6
    // [2493] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [2493] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [2494] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [2495] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [2496] clearline::c#1 = -- clearline::c#2 -- vbuxx=_dec_vbuxx 
    dex
    // while(c)
    // [2497] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuxx_then_la1 
    cpx #0
    bne __b1
    // clearline::@return
    // }
    // [2498] return 
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
// __register(A) char display_frame_maskxy(__register(X) char x, __register(Y) char y)
display_frame_maskxy: {
    // display_frame_maskxy::cpeekcxy1
    // gotoxy(x,y)
    // [2500] gotoxy::x#5 = display_frame_maskxy::cpeekcxy1_x#0
    // [2501] gotoxy::y#5 = display_frame_maskxy::cpeekcxy1_y#0
    // [2502] call gotoxy
    // [718] phi from display_frame_maskxy::cpeekcxy1 to gotoxy [phi:display_frame_maskxy::cpeekcxy1->gotoxy]
    // [718] phi gotoxy::y#30 = gotoxy::y#5 [phi:display_frame_maskxy::cpeekcxy1->gotoxy#0] -- register_copy 
    // [718] phi gotoxy::x#30 = gotoxy::x#5 [phi:display_frame_maskxy::cpeekcxy1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_frame_maskxy::cpeekcxy1_cpeekc1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2503] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(__conio.offset)
    // [2504] display_frame_maskxy::cpeekcxy1_cpeekc1_$0 = byte0  *((unsigned int *)&__conio+$13) -- vbuaa=_byte0__deref_pwuc1 
    lda __conio+$13
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [2505] *VERA_ADDRX_L = display_frame_maskxy::cpeekcxy1_cpeekc1_$0 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [2506] display_frame_maskxy::cpeekcxy1_cpeekc1_$1 = byte1  *((unsigned int *)&__conio+$13) -- vbuaa=_byte1__deref_pwuc1 
    lda __conio+$13+1
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [2507] *VERA_ADDRX_M = display_frame_maskxy::cpeekcxy1_cpeekc1_$1 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_0
    // [2508] display_frame_maskxy::cpeekcxy1_cpeekc1_$2 = *((char *)&__conio+5) -- vbuaa=_deref_pbuc1 
    lda __conio+5
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_0
    // [2509] *VERA_ADDRX_H = display_frame_maskxy::cpeekcxy1_cpeekc1_$2 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_H
    // return *VERA_DATA0;
    // [2510] display_frame_maskxy::c#0 = *VERA_DATA0 -- vbuaa=_deref_pbuc1 
    lda VERA_DATA0
    // display_frame_maskxy::@12
    // case 0x70: // DR corner.
    //             return 0b0110;
    // [2511] if(display_frame_maskxy::c#0==$70) goto display_frame_maskxy::@return -- vbuaa_eq_vbuc1_then_la1 
    cmp #$70
    beq __b2
    // display_frame_maskxy::@1
    // case 0x6E: // DL corner.
    //             return 0b0011;
    // [2512] if(display_frame_maskxy::c#0==$6e) goto display_frame_maskxy::@return -- vbuaa_eq_vbuc1_then_la1 
    cmp #$6e
    beq __b1
    // display_frame_maskxy::@2
    // case 0x6D: // UR corner.
    //             return 0b1100;
    // [2513] if(display_frame_maskxy::c#0==$6d) goto display_frame_maskxy::@return -- vbuaa_eq_vbuc1_then_la1 
    cmp #$6d
    beq __b3
    // display_frame_maskxy::@3
    // case 0x7D: // UL corner.
    //             return 0b1001;
    // [2514] if(display_frame_maskxy::c#0==$7d) goto display_frame_maskxy::@return -- vbuaa_eq_vbuc1_then_la1 
    cmp #$7d
    beq __b4
    // display_frame_maskxy::@4
    // case 0x40: // HL line.
    //             return 0b0101;
    // [2515] if(display_frame_maskxy::c#0==$40) goto display_frame_maskxy::@return -- vbuaa_eq_vbuc1_then_la1 
    cmp #$40
    beq __b5
    // display_frame_maskxy::@5
    // case 0x5D: // VL line.
    //             return 0b1010;
    // [2516] if(display_frame_maskxy::c#0==$5d) goto display_frame_maskxy::@return -- vbuaa_eq_vbuc1_then_la1 
    cmp #$5d
    beq __b6
    // display_frame_maskxy::@6
    // case 0x6B: // VR junction.
    //             return 0b1110;
    // [2517] if(display_frame_maskxy::c#0==$6b) goto display_frame_maskxy::@return -- vbuaa_eq_vbuc1_then_la1 
    cmp #$6b
    beq __b7
    // display_frame_maskxy::@7
    // case 0x73: // VL junction.
    //             return 0b1011;
    // [2518] if(display_frame_maskxy::c#0==$73) goto display_frame_maskxy::@return -- vbuaa_eq_vbuc1_then_la1 
    cmp #$73
    beq __b8
    // display_frame_maskxy::@8
    // case 0x72: // HD junction.
    //             return 0b0111;
    // [2519] if(display_frame_maskxy::c#0==$72) goto display_frame_maskxy::@return -- vbuaa_eq_vbuc1_then_la1 
    cmp #$72
    beq __b9
    // display_frame_maskxy::@9
    // case 0x71: // HU junction.
    //             return 0b1101;
    // [2520] if(display_frame_maskxy::c#0==$71) goto display_frame_maskxy::@return -- vbuaa_eq_vbuc1_then_la1 
    cmp #$71
    beq __b10
    // display_frame_maskxy::@10
    // case 0x5B: // HV junction.
    //             return 0b1111;
    // [2521] if(display_frame_maskxy::c#0==$5b) goto display_frame_maskxy::@11 -- vbuaa_eq_vbuc1_then_la1 
    cmp #$5b
    beq __b11
    // [2523] phi from display_frame_maskxy::@10 to display_frame_maskxy::@return [phi:display_frame_maskxy::@10->display_frame_maskxy::@return]
    // [2523] phi display_frame_maskxy::return#12 = 0 [phi:display_frame_maskxy::@10->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #0
    rts
    // [2522] phi from display_frame_maskxy::@10 to display_frame_maskxy::@11 [phi:display_frame_maskxy::@10->display_frame_maskxy::@11]
    // display_frame_maskxy::@11
  __b11:
    // [2523] phi from display_frame_maskxy::@11 to display_frame_maskxy::@return [phi:display_frame_maskxy::@11->display_frame_maskxy::@return]
    // [2523] phi display_frame_maskxy::return#12 = $f [phi:display_frame_maskxy::@11->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #$f
    rts
    // [2523] phi from display_frame_maskxy::@1 to display_frame_maskxy::@return [phi:display_frame_maskxy::@1->display_frame_maskxy::@return]
  __b1:
    // [2523] phi display_frame_maskxy::return#12 = 3 [phi:display_frame_maskxy::@1->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #3
    rts
    // [2523] phi from display_frame_maskxy::@12 to display_frame_maskxy::@return [phi:display_frame_maskxy::@12->display_frame_maskxy::@return]
  __b2:
    // [2523] phi display_frame_maskxy::return#12 = 6 [phi:display_frame_maskxy::@12->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #6
    rts
    // [2523] phi from display_frame_maskxy::@2 to display_frame_maskxy::@return [phi:display_frame_maskxy::@2->display_frame_maskxy::@return]
  __b3:
    // [2523] phi display_frame_maskxy::return#12 = $c [phi:display_frame_maskxy::@2->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #$c
    rts
    // [2523] phi from display_frame_maskxy::@3 to display_frame_maskxy::@return [phi:display_frame_maskxy::@3->display_frame_maskxy::@return]
  __b4:
    // [2523] phi display_frame_maskxy::return#12 = 9 [phi:display_frame_maskxy::@3->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #9
    rts
    // [2523] phi from display_frame_maskxy::@4 to display_frame_maskxy::@return [phi:display_frame_maskxy::@4->display_frame_maskxy::@return]
  __b5:
    // [2523] phi display_frame_maskxy::return#12 = 5 [phi:display_frame_maskxy::@4->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #5
    rts
    // [2523] phi from display_frame_maskxy::@5 to display_frame_maskxy::@return [phi:display_frame_maskxy::@5->display_frame_maskxy::@return]
  __b6:
    // [2523] phi display_frame_maskxy::return#12 = $a [phi:display_frame_maskxy::@5->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #$a
    rts
    // [2523] phi from display_frame_maskxy::@6 to display_frame_maskxy::@return [phi:display_frame_maskxy::@6->display_frame_maskxy::@return]
  __b7:
    // [2523] phi display_frame_maskxy::return#12 = $e [phi:display_frame_maskxy::@6->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #$e
    rts
    // [2523] phi from display_frame_maskxy::@7 to display_frame_maskxy::@return [phi:display_frame_maskxy::@7->display_frame_maskxy::@return]
  __b8:
    // [2523] phi display_frame_maskxy::return#12 = $b [phi:display_frame_maskxy::@7->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #$b
    rts
    // [2523] phi from display_frame_maskxy::@8 to display_frame_maskxy::@return [phi:display_frame_maskxy::@8->display_frame_maskxy::@return]
  __b9:
    // [2523] phi display_frame_maskxy::return#12 = 7 [phi:display_frame_maskxy::@8->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #7
    rts
    // [2523] phi from display_frame_maskxy::@9 to display_frame_maskxy::@return [phi:display_frame_maskxy::@9->display_frame_maskxy::@return]
  __b10:
    // [2523] phi display_frame_maskxy::return#12 = $d [phi:display_frame_maskxy::@9->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #$d
    // display_frame_maskxy::@return
    // }
    // [2524] return 
    rts
}
  // display_frame_char
/**
 * @brief 
 * 
 * @param mask 
 * @return unsigned char 
 */
// __register(A) char display_frame_char(__register(A) char mask)
display_frame_char: {
    // case 0b0110:
    //             return 0x70;
    // [2526] if(display_frame_char::mask#10==6) goto display_frame_char::@return -- vbuaa_eq_vbuc1_then_la1 
    cmp #6
    beq __b1
    // display_frame_char::@1
    // case 0b0011:
    //             return 0x6E;
    // [2527] if(display_frame_char::mask#10==3) goto display_frame_char::@return -- vbuaa_eq_vbuc1_then_la1 
    // DR corner.
    cmp #3
    beq __b2
    // display_frame_char::@2
    // case 0b1100:
    //             return 0x6D;
    // [2528] if(display_frame_char::mask#10==$c) goto display_frame_char::@return -- vbuaa_eq_vbuc1_then_la1 
    // DL corner.
    cmp #$c
    beq __b3
    // display_frame_char::@3
    // case 0b1001:
    //             return 0x7D;
    // [2529] if(display_frame_char::mask#10==9) goto display_frame_char::@return -- vbuaa_eq_vbuc1_then_la1 
    // UR corner.
    cmp #9
    beq __b4
    // display_frame_char::@4
    // case 0b0101:
    //             return 0x40;
    // [2530] if(display_frame_char::mask#10==5) goto display_frame_char::@return -- vbuaa_eq_vbuc1_then_la1 
    // UL corner.
    cmp #5
    beq __b5
    // display_frame_char::@5
    // case 0b1010:
    //             return 0x5D;
    // [2531] if(display_frame_char::mask#10==$a) goto display_frame_char::@return -- vbuaa_eq_vbuc1_then_la1 
    // HL line.
    cmp #$a
    beq __b6
    // display_frame_char::@6
    // case 0b1110:
    //             return 0x6B;
    // [2532] if(display_frame_char::mask#10==$e) goto display_frame_char::@return -- vbuaa_eq_vbuc1_then_la1 
    // VL line.
    cmp #$e
    beq __b7
    // display_frame_char::@7
    // case 0b1011:
    //             return 0x73;
    // [2533] if(display_frame_char::mask#10==$b) goto display_frame_char::@return -- vbuaa_eq_vbuc1_then_la1 
    // VR junction.
    cmp #$b
    beq __b8
    // display_frame_char::@8
    // case 0b0111:
    //             return 0x72;
    // [2534] if(display_frame_char::mask#10==7) goto display_frame_char::@return -- vbuaa_eq_vbuc1_then_la1 
    // VL junction.
    cmp #7
    beq __b9
    // display_frame_char::@9
    // case 0b1101:
    //             return 0x71;
    // [2535] if(display_frame_char::mask#10==$d) goto display_frame_char::@return -- vbuaa_eq_vbuc1_then_la1 
    // HD junction.
    cmp #$d
    beq __b10
    // display_frame_char::@10
    // case 0b1111:
    //             return 0x5B;
    // [2536] if(display_frame_char::mask#10==$f) goto display_frame_char::@11 -- vbuaa_eq_vbuc1_then_la1 
    // HU junction.
    cmp #$f
    beq __b11
    // [2538] phi from display_frame_char::@10 to display_frame_char::@return [phi:display_frame_char::@10->display_frame_char::@return]
    // [2538] phi display_frame_char::return#12 = $20 [phi:display_frame_char::@10->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$20
    rts
    // [2537] phi from display_frame_char::@10 to display_frame_char::@11 [phi:display_frame_char::@10->display_frame_char::@11]
    // display_frame_char::@11
  __b11:
    // [2538] phi from display_frame_char::@11 to display_frame_char::@return [phi:display_frame_char::@11->display_frame_char::@return]
    // [2538] phi display_frame_char::return#12 = $5b [phi:display_frame_char::@11->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$5b
    rts
    // [2538] phi from display_frame_char to display_frame_char::@return [phi:display_frame_char->display_frame_char::@return]
  __b1:
    // [2538] phi display_frame_char::return#12 = $70 [phi:display_frame_char->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$70
    rts
    // [2538] phi from display_frame_char::@1 to display_frame_char::@return [phi:display_frame_char::@1->display_frame_char::@return]
  __b2:
    // [2538] phi display_frame_char::return#12 = $6e [phi:display_frame_char::@1->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$6e
    rts
    // [2538] phi from display_frame_char::@2 to display_frame_char::@return [phi:display_frame_char::@2->display_frame_char::@return]
  __b3:
    // [2538] phi display_frame_char::return#12 = $6d [phi:display_frame_char::@2->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$6d
    rts
    // [2538] phi from display_frame_char::@3 to display_frame_char::@return [phi:display_frame_char::@3->display_frame_char::@return]
  __b4:
    // [2538] phi display_frame_char::return#12 = $7d [phi:display_frame_char::@3->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$7d
    rts
    // [2538] phi from display_frame_char::@4 to display_frame_char::@return [phi:display_frame_char::@4->display_frame_char::@return]
  __b5:
    // [2538] phi display_frame_char::return#12 = $40 [phi:display_frame_char::@4->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$40
    rts
    // [2538] phi from display_frame_char::@5 to display_frame_char::@return [phi:display_frame_char::@5->display_frame_char::@return]
  __b6:
    // [2538] phi display_frame_char::return#12 = $5d [phi:display_frame_char::@5->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$5d
    rts
    // [2538] phi from display_frame_char::@6 to display_frame_char::@return [phi:display_frame_char::@6->display_frame_char::@return]
  __b7:
    // [2538] phi display_frame_char::return#12 = $6b [phi:display_frame_char::@6->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$6b
    rts
    // [2538] phi from display_frame_char::@7 to display_frame_char::@return [phi:display_frame_char::@7->display_frame_char::@return]
  __b8:
    // [2538] phi display_frame_char::return#12 = $73 [phi:display_frame_char::@7->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$73
    rts
    // [2538] phi from display_frame_char::@8 to display_frame_char::@return [phi:display_frame_char::@8->display_frame_char::@return]
  __b9:
    // [2538] phi display_frame_char::return#12 = $72 [phi:display_frame_char::@8->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$72
    rts
    // [2538] phi from display_frame_char::@9 to display_frame_char::@return [phi:display_frame_char::@9->display_frame_char::@return]
  __b10:
    // [2538] phi display_frame_char::return#12 = $71 [phi:display_frame_char::@9->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$71
    // display_frame_char::@return
    // }
    // [2539] return 
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
// void display_chip_led(__zp($b1) char x, char y, __zp($b0) char w, __register(X) char tc, char bc)
display_chip_led: {
    .label x = $b1
    .label w = $b0
    // textcolor(tc)
    // [2541] textcolor::color#11 = display_chip_led::tc#3
    // [2542] call textcolor
    // [700] phi from display_chip_led to textcolor [phi:display_chip_led->textcolor]
    // [700] phi textcolor::color#18 = textcolor::color#11 [phi:display_chip_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [2543] phi from display_chip_led to display_chip_led::@3 [phi:display_chip_led->display_chip_led::@3]
    // display_chip_led::@3
    // bgcolor(bc)
    // [2544] call bgcolor
    // [705] phi from display_chip_led::@3 to bgcolor [phi:display_chip_led::@3->bgcolor]
    // [705] phi bgcolor::color#14 = BLUE [phi:display_chip_led::@3->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // [2545] phi from display_chip_led::@3 display_chip_led::@5 to display_chip_led::@1 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1]
    // [2545] phi display_chip_led::w#4 = display_chip_led::w#7 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1#0] -- register_copy 
    // [2545] phi display_chip_led::x#4 = display_chip_led::x#7 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1#1] -- register_copy 
    // display_chip_led::@1
  __b1:
    // cputcxy(x, y, 0x6F)
    // [2546] cputcxy::x#9 = display_chip_led::x#4 -- vbuxx=vbuz1 
    ldx.z x
    // [2547] call cputcxy
    // [1986] phi from display_chip_led::@1 to cputcxy [phi:display_chip_led::@1->cputcxy]
    // [1986] phi cputcxy::c#15 = $6f [phi:display_chip_led::@1->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6f
    sta.z cputcxy.c
    // [1986] phi cputcxy::y#15 = 3 [phi:display_chip_led::@1->cputcxy#1] -- vbuyy=vbuc1 
    ldy #3
    // [1986] phi cputcxy::x#15 = cputcxy::x#9 [phi:display_chip_led::@1->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_led::@4
    // cputcxy(x, y+1, 0x77)
    // [2548] cputcxy::x#10 = display_chip_led::x#4 -- vbuxx=vbuz1 
    ldx.z x
    // [2549] call cputcxy
    // [1986] phi from display_chip_led::@4 to cputcxy [phi:display_chip_led::@4->cputcxy]
    // [1986] phi cputcxy::c#15 = $77 [phi:display_chip_led::@4->cputcxy#0] -- vbuz1=vbuc1 
    lda #$77
    sta.z cputcxy.c
    // [1986] phi cputcxy::y#15 = 3+1 [phi:display_chip_led::@4->cputcxy#1] -- vbuyy=vbuc1 
    ldy #3+1
    // [1986] phi cputcxy::x#15 = cputcxy::x#10 [phi:display_chip_led::@4->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_led::@5
    // x++;
    // [2550] display_chip_led::x#0 = ++ display_chip_led::x#4 -- vbuz1=_inc_vbuz1 
    inc.z x
    // while(--w)
    // [2551] display_chip_led::w#0 = -- display_chip_led::w#4 -- vbuz1=_dec_vbuz1 
    dec.z w
    // [2552] if(0!=display_chip_led::w#0) goto display_chip_led::@1 -- 0_neq_vbuz1_then_la1 
    lda.z w
    bne __b1
    // [2553] phi from display_chip_led::@5 to display_chip_led::@2 [phi:display_chip_led::@5->display_chip_led::@2]
    // display_chip_led::@2
    // textcolor(WHITE)
    // [2554] call textcolor
    // [700] phi from display_chip_led::@2 to textcolor [phi:display_chip_led::@2->textcolor]
    // [700] phi textcolor::color#18 = WHITE [phi:display_chip_led::@2->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [2555] phi from display_chip_led::@2 to display_chip_led::@6 [phi:display_chip_led::@2->display_chip_led::@6]
    // display_chip_led::@6
    // bgcolor(BLUE)
    // [2556] call bgcolor
    // [705] phi from display_chip_led::@6 to bgcolor [phi:display_chip_led::@6->bgcolor]
    // [705] phi bgcolor::color#14 = BLUE [phi:display_chip_led::@6->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // display_chip_led::@return
    // }
    // [2557] return 
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
// void display_chip_line(__mem() char x, __mem() char y, __zp($f3) char w, __mem() char c)
display_chip_line: {
    .label i = $c8
    .label w = $f3
    // gotoxy(x, y)
    // [2559] gotoxy::x#7 = display_chip_line::x#16 -- vbuxx=vbum1 
    ldx x
    // [2560] gotoxy::y#7 = display_chip_line::y#16 -- vbuyy=vbum1 
    ldy y
    // [2561] call gotoxy
    // [718] phi from display_chip_line to gotoxy [phi:display_chip_line->gotoxy]
    // [718] phi gotoxy::y#30 = gotoxy::y#7 [phi:display_chip_line->gotoxy#0] -- register_copy 
    // [718] phi gotoxy::x#30 = gotoxy::x#7 [phi:display_chip_line->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [2562] phi from display_chip_line to display_chip_line::@4 [phi:display_chip_line->display_chip_line::@4]
    // display_chip_line::@4
    // textcolor(GREY)
    // [2563] call textcolor
    // [700] phi from display_chip_line::@4 to textcolor [phi:display_chip_line::@4->textcolor]
    // [700] phi textcolor::color#18 = GREY [phi:display_chip_line::@4->textcolor#0] -- vbuxx=vbuc1 
    ldx #GREY
    jsr textcolor
    // [2564] phi from display_chip_line::@4 to display_chip_line::@5 [phi:display_chip_line::@4->display_chip_line::@5]
    // display_chip_line::@5
    // bgcolor(BLUE)
    // [2565] call bgcolor
    // [705] phi from display_chip_line::@5 to bgcolor [phi:display_chip_line::@5->bgcolor]
    // [705] phi bgcolor::color#14 = BLUE [phi:display_chip_line::@5->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // display_chip_line::@6
    // cputc(VERA_CHR_UR)
    // [2566] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [2567] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [2569] call textcolor
    // [700] phi from display_chip_line::@6 to textcolor [phi:display_chip_line::@6->textcolor]
    // [700] phi textcolor::color#18 = WHITE [phi:display_chip_line::@6->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [2570] phi from display_chip_line::@6 to display_chip_line::@7 [phi:display_chip_line::@6->display_chip_line::@7]
    // display_chip_line::@7
    // bgcolor(BLACK)
    // [2571] call bgcolor
    // [705] phi from display_chip_line::@7 to bgcolor [phi:display_chip_line::@7->bgcolor]
    // [705] phi bgcolor::color#14 = BLACK [phi:display_chip_line::@7->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLACK
    jsr bgcolor
    // [2572] phi from display_chip_line::@7 to display_chip_line::@1 [phi:display_chip_line::@7->display_chip_line::@1]
    // [2572] phi display_chip_line::i#2 = 0 [phi:display_chip_line::@7->display_chip_line::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // display_chip_line::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [2573] if(display_chip_line::i#2<display_chip_line::w#10) goto display_chip_line::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [2574] phi from display_chip_line::@1 to display_chip_line::@3 [phi:display_chip_line::@1->display_chip_line::@3]
    // display_chip_line::@3
    // textcolor(GREY)
    // [2575] call textcolor
    // [700] phi from display_chip_line::@3 to textcolor [phi:display_chip_line::@3->textcolor]
    // [700] phi textcolor::color#18 = GREY [phi:display_chip_line::@3->textcolor#0] -- vbuxx=vbuc1 
    ldx #GREY
    jsr textcolor
    // [2576] phi from display_chip_line::@3 to display_chip_line::@8 [phi:display_chip_line::@3->display_chip_line::@8]
    // display_chip_line::@8
    // bgcolor(BLUE)
    // [2577] call bgcolor
    // [705] phi from display_chip_line::@8 to bgcolor [phi:display_chip_line::@8->bgcolor]
    // [705] phi bgcolor::color#14 = BLUE [phi:display_chip_line::@8->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // display_chip_line::@9
    // cputc(VERA_CHR_UL)
    // [2578] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [2579] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [2581] call textcolor
    // [700] phi from display_chip_line::@9 to textcolor [phi:display_chip_line::@9->textcolor]
    // [700] phi textcolor::color#18 = WHITE [phi:display_chip_line::@9->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [2582] phi from display_chip_line::@9 to display_chip_line::@10 [phi:display_chip_line::@9->display_chip_line::@10]
    // display_chip_line::@10
    // bgcolor(BLACK)
    // [2583] call bgcolor
    // [705] phi from display_chip_line::@10 to bgcolor [phi:display_chip_line::@10->bgcolor]
    // [705] phi bgcolor::color#14 = BLACK [phi:display_chip_line::@10->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLACK
    jsr bgcolor
    // display_chip_line::@11
    // cputcxy(x+2, y, c)
    // [2584] cputcxy::x#8 = display_chip_line::x#16 + 2 -- vbuxx=vbum1_plus_2 
    ldx x
    inx
    inx
    // [2585] cputcxy::y#8 = display_chip_line::y#16 -- vbuyy=vbum1 
    ldy y
    // [2586] cputcxy::c#8 = display_chip_line::c#15 -- vbuz1=vbum2 
    lda c
    sta.z cputcxy.c
    // [2587] call cputcxy
    // [1986] phi from display_chip_line::@11 to cputcxy [phi:display_chip_line::@11->cputcxy]
    // [1986] phi cputcxy::c#15 = cputcxy::c#8 [phi:display_chip_line::@11->cputcxy#0] -- register_copy 
    // [1986] phi cputcxy::y#15 = cputcxy::y#8 [phi:display_chip_line::@11->cputcxy#1] -- register_copy 
    // [1986] phi cputcxy::x#15 = cputcxy::x#8 [phi:display_chip_line::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_line::@return
    // }
    // [2588] return 
    rts
    // display_chip_line::@2
  __b2:
    // cputc(VERA_CHR_SPACE)
    // [2589] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [2590] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [2592] display_chip_line::i#1 = ++ display_chip_line::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [2572] phi from display_chip_line::@2 to display_chip_line::@1 [phi:display_chip_line::@2->display_chip_line::@1]
    // [2572] phi display_chip_line::i#2 = display_chip_line::i#1 [phi:display_chip_line::@2->display_chip_line::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    .label x = util_wait_key.bram
    .label c = fopen.pathpos
    .label y = util_wait_key.bank_get_brom1_return
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
// void display_chip_end(__register(X) char x, char y, __zp($f6) char w)
display_chip_end: {
    .label i = $b2
    .label w = $f6
    // gotoxy(x, y)
    // [2593] gotoxy::x#8 = display_chip_end::x#0
    // [2594] call gotoxy
    // [718] phi from display_chip_end to gotoxy [phi:display_chip_end->gotoxy]
    // [718] phi gotoxy::y#30 = display_print_chip::y#21 [phi:display_chip_end->gotoxy#0] -- vbuyy=vbuc1 
    ldy #display_print_chip.y
    // [718] phi gotoxy::x#30 = gotoxy::x#8 [phi:display_chip_end->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [2595] phi from display_chip_end to display_chip_end::@4 [phi:display_chip_end->display_chip_end::@4]
    // display_chip_end::@4
    // textcolor(GREY)
    // [2596] call textcolor
    // [700] phi from display_chip_end::@4 to textcolor [phi:display_chip_end::@4->textcolor]
    // [700] phi textcolor::color#18 = GREY [phi:display_chip_end::@4->textcolor#0] -- vbuxx=vbuc1 
    ldx #GREY
    jsr textcolor
    // [2597] phi from display_chip_end::@4 to display_chip_end::@5 [phi:display_chip_end::@4->display_chip_end::@5]
    // display_chip_end::@5
    // bgcolor(BLUE)
    // [2598] call bgcolor
    // [705] phi from display_chip_end::@5 to bgcolor [phi:display_chip_end::@5->bgcolor]
    // [705] phi bgcolor::color#14 = BLUE [phi:display_chip_end::@5->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // display_chip_end::@6
    // cputc(VERA_CHR_UR)
    // [2599] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [2600] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [2602] call textcolor
    // [700] phi from display_chip_end::@6 to textcolor [phi:display_chip_end::@6->textcolor]
    // [700] phi textcolor::color#18 = BLUE [phi:display_chip_end::@6->textcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr textcolor
    // [2603] phi from display_chip_end::@6 to display_chip_end::@7 [phi:display_chip_end::@6->display_chip_end::@7]
    // display_chip_end::@7
    // bgcolor(BLACK)
    // [2604] call bgcolor
    // [705] phi from display_chip_end::@7 to bgcolor [phi:display_chip_end::@7->bgcolor]
    // [705] phi bgcolor::color#14 = BLACK [phi:display_chip_end::@7->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLACK
    jsr bgcolor
    // [2605] phi from display_chip_end::@7 to display_chip_end::@1 [phi:display_chip_end::@7->display_chip_end::@1]
    // [2605] phi display_chip_end::i#2 = 0 [phi:display_chip_end::@7->display_chip_end::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // display_chip_end::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [2606] if(display_chip_end::i#2<display_chip_end::w#0) goto display_chip_end::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [2607] phi from display_chip_end::@1 to display_chip_end::@3 [phi:display_chip_end::@1->display_chip_end::@3]
    // display_chip_end::@3
    // textcolor(GREY)
    // [2608] call textcolor
    // [700] phi from display_chip_end::@3 to textcolor [phi:display_chip_end::@3->textcolor]
    // [700] phi textcolor::color#18 = GREY [phi:display_chip_end::@3->textcolor#0] -- vbuxx=vbuc1 
    ldx #GREY
    jsr textcolor
    // [2609] phi from display_chip_end::@3 to display_chip_end::@8 [phi:display_chip_end::@3->display_chip_end::@8]
    // display_chip_end::@8
    // bgcolor(BLUE)
    // [2610] call bgcolor
    // [705] phi from display_chip_end::@8 to bgcolor [phi:display_chip_end::@8->bgcolor]
    // [705] phi bgcolor::color#14 = BLUE [phi:display_chip_end::@8->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // display_chip_end::@9
    // cputc(VERA_CHR_UL)
    // [2611] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [2612] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_chip_end::@return
    // }
    // [2614] return 
    rts
    // display_chip_end::@2
  __b2:
    // cputc(VERA_CHR_HL)
    // [2615] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [2616] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [2618] display_chip_end::i#1 = ++ display_chip_end::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [2605] phi from display_chip_end::@2 to display_chip_end::@1 [phi:display_chip_end::@2->display_chip_end::@1]
    // [2605] phi display_chip_end::i#2 = display_chip_end::i#1 [phi:display_chip_end::@2->display_chip_end::@1#0] -- register_copy 
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
// __zp($29) unsigned int utoa_append(__zp($40) char *buffer, __zp($29) unsigned int value, __zp($36) unsigned int sub)
utoa_append: {
    .label buffer = $40
    .label value = $29
    .label sub = $36
    .label return = $29
    // [2620] phi from utoa_append to utoa_append::@1 [phi:utoa_append->utoa_append::@1]
    // [2620] phi utoa_append::digit#2 = 0 [phi:utoa_append->utoa_append::@1#0] -- vbuxx=vbuc1 
    ldx #0
    // [2620] phi utoa_append::value#2 = utoa_append::value#0 [phi:utoa_append->utoa_append::@1#1] -- register_copy 
    // utoa_append::@1
  __b1:
    // while (value >= sub)
    // [2621] if(utoa_append::value#2>=utoa_append::sub#0) goto utoa_append::@2 -- vwuz1_ge_vwuz2_then_la1 
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
    // [2622] *utoa_append::buffer#0 = DIGITS[utoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuxx 
    lda DIGITS,x
    ldy #0
    sta (buffer),y
    // utoa_append::@return
    // }
    // [2623] return 
    rts
    // utoa_append::@2
  __b2:
    // digit++;
    // [2624] utoa_append::digit#1 = ++ utoa_append::digit#2 -- vbuxx=_inc_vbuxx 
    inx
    // value -= sub
    // [2625] utoa_append::value#1 = utoa_append::value#2 - utoa_append::sub#0 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z value
    sec
    sbc.z sub
    sta.z value
    lda.z value+1
    sbc.z sub+1
    sta.z value+1
    // [2620] phi from utoa_append::@2 to utoa_append::@1 [phi:utoa_append::@2->utoa_append::@1]
    // [2620] phi utoa_append::digit#2 = utoa_append::digit#1 [phi:utoa_append::@2->utoa_append::@1#0] -- register_copy 
    // [2620] phi utoa_append::value#2 = utoa_append::value#1 [phi:utoa_append::@2->utoa_append::@1#1] -- register_copy 
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
// void rom_write_byte(__zp($45) unsigned long address, __register(Y) char value)
rom_write_byte: {
    .label rom_bank1_rom_write_byte__2 = $3e
    .label rom_ptr1_rom_write_byte__0 = $3c
    .label rom_ptr1_rom_write_byte__2 = $3c
    .label rom_bank1_bank_unshifted = $3e
    .label rom_ptr1_return = $3c
    .label address = $45
    // rom_write_byte::rom_bank1
    // BYTE2(address)
    // [2627] rom_write_byte::rom_bank1_$0 = byte2  rom_write_byte::address#4 -- vbuaa=_byte2_vduz1 
    lda.z address+2
    // BYTE1(address)
    // [2628] rom_write_byte::rom_bank1_$1 = byte1  rom_write_byte::address#4 -- vbuxx=_byte1_vduz1 
    ldx.z address+1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2629] rom_write_byte::rom_bank1_$2 = rom_write_byte::rom_bank1_$0 w= rom_write_byte::rom_bank1_$1 -- vwuz1=vbuaa_word_vbuxx 
    sta.z rom_bank1_rom_write_byte__2+1
    stx.z rom_bank1_rom_write_byte__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2630] rom_write_byte::rom_bank1_bank_unshifted#0 = rom_write_byte::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2631] rom_write_byte::rom_bank1_return#0 = byte1  rom_write_byte::rom_bank1_bank_unshifted#0 -- vbuxx=_byte1_vwuz1 
    ldx.z rom_bank1_bank_unshifted+1
    // rom_write_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2632] rom_write_byte::rom_ptr1_$2 = (unsigned int)rom_write_byte::address#4 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_write_byte__2
    lda.z address+1
    sta.z rom_ptr1_rom_write_byte__2+1
    // [2633] rom_write_byte::rom_ptr1_$0 = rom_write_byte::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_write_byte__0
    and #<$3fff
    sta.z rom_ptr1_rom_write_byte__0
    lda.z rom_ptr1_rom_write_byte__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_write_byte__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2634] rom_write_byte::rom_ptr1_return#0 = rom_write_byte::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_write_byte::bank_set_brom1
    // BROM = bank
    // [2635] BROM = rom_write_byte::rom_bank1_return#0 -- vbuz1=vbuxx 
    stx.z BROM
    // rom_write_byte::@1
    // *ptr_rom = value
    // [2636] *((char *)rom_write_byte::rom_ptr1_return#0) = rom_write_byte::value#10 -- _deref_pbuz1=vbuyy 
    tya
    ldy #0
    sta (rom_ptr1_return),y
    // rom_write_byte::@return
    // }
    // [2637] return 
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
    // [2639] return 
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
// __mem() int ferror(__zp($36) struct $2 *stream)
ferror: {
    .label cbm_k_setnam1_ferror__0 = $43
    .label cbm_k_readst1_status = $d7
    .label cbm_k_chrin2_ch = $d8
    .label stream = $36
    .label ch = $cc
    .label errno_len = $d9
    .label errno_parsed = $d4
    // unsigned char sp = (unsigned char)stream
    // [2640] ferror::sp#0 = (char)ferror::stream#0 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_setlfs(15, 8, 15)
    // [2641] cbm_k_setlfs::channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.channel
    // [2642] cbm_k_setlfs::device = 8 -- vbum1=vbuc1 
    lda #8
    sta cbm_k_setlfs.device
    // [2643] cbm_k_setlfs::command = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.command
    // [2644] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // ferror::@11
    // cbm_k_setnam("")
    // [2645] ferror::cbm_k_setnam1_filename = info_text4 -- pbum1=pbuc1 
    lda #<info_text4
    sta cbm_k_setnam1_filename
    lda #>info_text4
    sta cbm_k_setnam1_filename+1
    // ferror::cbm_k_setnam1
    // strlen(filename)
    // [2646] strlen::str#5 = ferror::cbm_k_setnam1_filename -- pbuz1=pbum2 
    lda cbm_k_setnam1_filename
    sta.z strlen.str
    lda cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [2647] call strlen
    // [2323] phi from ferror::cbm_k_setnam1 to strlen [phi:ferror::cbm_k_setnam1->strlen]
    // [2323] phi strlen::str#8 = strlen::str#5 [phi:ferror::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [2648] strlen::return#12 = strlen::len#2
    // ferror::@12
    // [2649] ferror::cbm_k_setnam1_$0 = strlen::return#12
    // char filename_len = (char)strlen(filename)
    // [2650] ferror::cbm_k_setnam1_filename_len = (char)ferror::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
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
    // [2653] ferror::cbm_k_chkin1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_chkin1_channel
    // ferror::cbm_k_chkin1
    // char status
    // [2654] ferror::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // ferror::cbm_k_chrin1
    // char ch
    // [2656] ferror::cbm_k_chrin1_ch = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chrin1_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin1_ch
    // return ch;
    // [2658] ferror::cbm_k_chrin1_return#0 = ferror::cbm_k_chrin1_ch -- vbuaa=vbum1 
    // ferror::cbm_k_chrin1_@return
    // }
    // [2659] ferror::cbm_k_chrin1_return#1 = ferror::cbm_k_chrin1_return#0
    // ferror::@7
    // char ch = cbm_k_chrin()
    // [2660] ferror::ch#0 = ferror::cbm_k_chrin1_return#1 -- vbuz1=vbuaa 
    sta.z ch
    // [2661] phi from ferror::@7 to ferror::cbm_k_readst1 [phi:ferror::@7->ferror::cbm_k_readst1]
    // [2661] phi __errno#18 = __errno#333 [phi:ferror::@7->ferror::cbm_k_readst1#0] -- register_copy 
    // [2661] phi ferror::errno_len#10 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z errno_len
    // [2661] phi ferror::ch#10 = ferror::ch#0 [phi:ferror::@7->ferror::cbm_k_readst1#2] -- register_copy 
    // [2661] phi ferror::errno_parsed#2 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#3] -- vbuz1=vbuc1 
    sta.z errno_parsed
    // ferror::cbm_k_readst1
  cbm_k_readst1:
    // char status
    // [2662] ferror::cbm_k_readst1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2664] ferror::cbm_k_readst1_return#0 = ferror::cbm_k_readst1_status -- vbuaa=vbuz1 
    // ferror::cbm_k_readst1_@return
    // }
    // [2665] ferror::cbm_k_readst1_return#1 = ferror::cbm_k_readst1_return#0
    // ferror::@8
    // cbm_k_readst()
    // [2666] ferror::$6 = ferror::cbm_k_readst1_return#1
    // st = cbm_k_readst()
    // [2667] ferror::st#1 = ferror::$6
    // while (!(st = cbm_k_readst()))
    // [2668] if(0==ferror::st#1) goto ferror::@1 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b1
    // ferror::@2
    // __status = st
    // [2669] ((char *)&__stdio_file+$46)[ferror::sp#0] = ferror::st#1 -- pbuc1_derefidx_vbum1=vbuaa 
    ldy sp
    sta __stdio_file+$46,y
    // cbm_k_close(15)
    // [2670] ferror::cbm_k_close1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_close1_channel
    // ferror::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // ferror::@9
    // return __errno;
    // [2672] ferror::return#1 = __errno#18 -- vwsm1=vwsz2 
    lda.z __errno
    sta return
    lda.z __errno+1
    sta return+1
    // ferror::@return
    // }
    // [2673] return 
    rts
    // ferror::@1
  __b1:
    // if (!errno_parsed)
    // [2674] if(0!=ferror::errno_parsed#2) goto ferror::@3 -- 0_neq_vbuz1_then_la1 
    lda.z errno_parsed
    bne __b3
    // ferror::@4
    // if (ch == ',')
    // [2675] if(ferror::ch#10!=',') goto ferror::@3 -- vbuz1_neq_vbuc1_then_la1 
    lda #','
    cmp.z ch
    bne __b3
    // ferror::@5
    // errno_parsed++;
    // [2676] ferror::errno_parsed#1 = ++ ferror::errno_parsed#2 -- vbuz1=_inc_vbuz1 
    inc.z errno_parsed
    // strncpy(temp, __errno_error, errno_len+1)
    // [2677] strncpy::n#0 = ferror::errno_len#10 + 1 -- vwuz1=vbuz2_plus_1 
    lda.z errno_len
    clc
    adc #1
    sta.z strncpy.n
    lda #0
    adc #0
    sta.z strncpy.n+1
    // [2678] call strncpy
    // [2455] phi from ferror::@5 to strncpy [phi:ferror::@5->strncpy]
    // [2455] phi strncpy::dst#8 = ferror::temp [phi:ferror::@5->strncpy#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z strncpy.dst
    lda #>temp
    sta.z strncpy.dst+1
    // [2455] phi strncpy::src#6 = __errno_error [phi:ferror::@5->strncpy#1] -- pbuz1=pbuc1 
    lda #<__errno_error
    sta.z strncpy.src
    lda #>__errno_error
    sta.z strncpy.src+1
    // [2455] phi strncpy::n#3 = strncpy::n#0 [phi:ferror::@5->strncpy#2] -- register_copy 
    jsr strncpy
    // [2679] phi from ferror::@5 to ferror::@13 [phi:ferror::@5->ferror::@13]
    // ferror::@13
    // atoi(temp)
    // [2680] call atoi
    // [2692] phi from ferror::@13 to atoi [phi:ferror::@13->atoi]
    // [2692] phi atoi::str#2 = ferror::temp [phi:ferror::@13->atoi#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z atoi.str
    lda #>temp
    sta.z atoi.str+1
    jsr atoi
    // atoi(temp)
    // [2681] atoi::return#4 = atoi::return#2
    // ferror::@14
    // __errno = atoi(temp)
    // [2682] __errno#2 = atoi::return#4 -- vwsz1=vwsz2 
    lda.z atoi.return
    sta.z __errno
    lda.z atoi.return+1
    sta.z __errno+1
    // [2683] phi from ferror::@1 ferror::@14 ferror::@4 to ferror::@3 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3]
    // [2683] phi __errno#103 = __errno#18 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#0] -- register_copy 
    // [2683] phi ferror::errno_parsed#11 = ferror::errno_parsed#2 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#1] -- register_copy 
    // ferror::@3
  __b3:
    // __errno_error[errno_len] = ch
    // [2684] __errno_error[ferror::errno_len#10] = ferror::ch#10 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z ch
    ldy.z errno_len
    sta __errno_error,y
    // errno_len++;
    // [2685] ferror::errno_len#1 = ++ ferror::errno_len#10 -- vbuz1=_inc_vbuz1 
    inc.z errno_len
    // ferror::cbm_k_chrin2
    // char ch
    // [2686] ferror::cbm_k_chrin2_ch = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chrin2_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin2_ch
    // return ch;
    // [2688] ferror::cbm_k_chrin2_return#0 = ferror::cbm_k_chrin2_ch -- vbuaa=vbuz1 
    // ferror::cbm_k_chrin2_@return
    // }
    // [2689] ferror::cbm_k_chrin2_return#1 = ferror::cbm_k_chrin2_return#0
    // ferror::@10
    // cbm_k_chrin()
    // [2690] ferror::$15 = ferror::cbm_k_chrin2_return#1
    // ch = cbm_k_chrin()
    // [2691] ferror::ch#1 = ferror::$15 -- vbuz1=vbuaa 
    sta.z ch
    // [2661] phi from ferror::@10 to ferror::cbm_k_readst1 [phi:ferror::@10->ferror::cbm_k_readst1]
    // [2661] phi __errno#18 = __errno#103 [phi:ferror::@10->ferror::cbm_k_readst1#0] -- register_copy 
    // [2661] phi ferror::errno_len#10 = ferror::errno_len#1 [phi:ferror::@10->ferror::cbm_k_readst1#1] -- register_copy 
    // [2661] phi ferror::ch#10 = ferror::ch#1 [phi:ferror::@10->ferror::cbm_k_readst1#2] -- register_copy 
    // [2661] phi ferror::errno_parsed#2 = ferror::errno_parsed#11 [phi:ferror::@10->ferror::cbm_k_readst1#3] -- register_copy 
    jmp cbm_k_readst1
  .segment Data
    temp: .fill 4, 0
    cbm_k_setnam1_filename: .word 0
    cbm_k_setnam1_filename_len: .byte 0
    cbm_k_chkin1_channel: .byte 0
    cbm_k_chkin1_status: .byte 0
    cbm_k_chrin1_ch: .byte 0
    cbm_k_close1_channel: .byte 0
    return: .word 0
    sp: .byte 0
}
.segment Code
  // atoi
// Converts the string argument str to an integer.
// __zp($30) int atoi(__zp($b5) const char *str)
atoi: {
    .label atoi__6 = $30
    .label atoi__7 = $30
    .label res = $30
    .label return = $30
    .label str = $b5
    .label atoi__10 = $3e
    .label atoi__11 = $30
    // if (str[i] == '-')
    // [2693] if(*atoi::str#2!='-') goto atoi::@3 -- _deref_pbuz1_neq_vbuc1_then_la1 
    ldy #0
    lda (str),y
    cmp #'-'
    bne __b2
    // [2694] phi from atoi to atoi::@2 [phi:atoi->atoi::@2]
    // atoi::@2
    // [2695] phi from atoi::@2 to atoi::@3 [phi:atoi::@2->atoi::@3]
    // [2695] phi atoi::negative#2 = 1 [phi:atoi::@2->atoi::@3#0] -- vbuxx=vbuc1 
    ldx #1
    // [2695] phi atoi::res#2 = 0 [phi:atoi::@2->atoi::@3#1] -- vwsz1=vwsc1 
    tya
    sta.z res
    sta.z res+1
    // [2695] phi atoi::i#4 = 1 [phi:atoi::@2->atoi::@3#2] -- vbuyy=vbuc1 
    ldy #1
    jmp __b3
  // Iterate through all digits and update the result
    // [2695] phi from atoi to atoi::@3 [phi:atoi->atoi::@3]
  __b2:
    // [2695] phi atoi::negative#2 = 0 [phi:atoi->atoi::@3#0] -- vbuxx=vbuc1 
    ldx #0
    // [2695] phi atoi::res#2 = 0 [phi:atoi->atoi::@3#1] -- vwsz1=vwsc1 
    txa
    sta.z res
    sta.z res+1
    // [2695] phi atoi::i#4 = 0 [phi:atoi->atoi::@3#2] -- vbuyy=vbuc1 
    tay
    // atoi::@3
  __b3:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [2696] if(atoi::str#2[atoi::i#4]<'0') goto atoi::@5 -- pbuz1_derefidx_vbuyy_lt_vbuc1_then_la1 
    lda (str),y
    cmp #'0'
    bcc __b5
    // atoi::@6
    // [2697] if(atoi::str#2[atoi::i#4]<='9') goto atoi::@4 -- pbuz1_derefidx_vbuyy_le_vbuc1_then_la1 
    lda (str),y
    cmp #'9'
    bcc __b4
    beq __b4
    // atoi::@5
  __b5:
    // if(negative)
    // [2698] if(0!=atoi::negative#2) goto atoi::@1 -- 0_neq_vbuxx_then_la1 
    // Return result with sign
    cpx #0
    bne __b1
    // [2700] phi from atoi::@1 atoi::@5 to atoi::@return [phi:atoi::@1/atoi::@5->atoi::@return]
    // [2700] phi atoi::return#2 = atoi::return#0 [phi:atoi::@1/atoi::@5->atoi::@return#0] -- register_copy 
    rts
    // atoi::@1
  __b1:
    // return -res;
    // [2699] atoi::return#0 = - atoi::res#2 -- vwsz1=_neg_vwsz1 
    lda #0
    sec
    sbc.z return
    sta.z return
    lda #0
    sbc.z return+1
    sta.z return+1
    // atoi::@return
    // }
    // [2701] return 
    rts
    // atoi::@4
  __b4:
    // res * 10
    // [2702] atoi::$10 = atoi::res#2 << 2 -- vwsz1=vwsz2_rol_2 
    lda.z res
    asl
    sta.z atoi__10
    lda.z res+1
    rol
    sta.z atoi__10+1
    asl.z atoi__10
    rol.z atoi__10+1
    // [2703] atoi::$11 = atoi::$10 + atoi::res#2 -- vwsz1=vwsz2_plus_vwsz1 
    clc
    lda.z atoi__11
    adc.z atoi__10
    sta.z atoi__11
    lda.z atoi__11+1
    adc.z atoi__10+1
    sta.z atoi__11+1
    // [2704] atoi::$6 = atoi::$11 << 1 -- vwsz1=vwsz1_rol_1 
    asl.z atoi__6
    rol.z atoi__6+1
    // res * 10 + str[i]
    // [2705] atoi::$7 = atoi::$6 + atoi::str#2[atoi::i#4] -- vwsz1=vwsz1_plus_pbuz2_derefidx_vbuyy 
    lda.z atoi__7
    clc
    adc (str),y
    sta.z atoi__7
    bcc !+
    inc.z atoi__7+1
  !:
    // res = res * 10 + str[i] - '0'
    // [2706] atoi::res#1 = atoi::$7 - '0' -- vwsz1=vwsz1_minus_vbuc1 
    lda.z res
    sec
    sbc #'0'
    sta.z res
    bcs !+
    dec.z res+1
  !:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [2707] atoi::i#2 = ++ atoi::i#4 -- vbuyy=_inc_vbuyy 
    iny
    // [2695] phi from atoi::@4 to atoi::@3 [phi:atoi::@4->atoi::@3]
    // [2695] phi atoi::negative#2 = atoi::negative#2 [phi:atoi::@4->atoi::@3#0] -- register_copy 
    // [2695] phi atoi::res#2 = atoi::res#1 [phi:atoi::@4->atoi::@3#1] -- register_copy 
    // [2695] phi atoi::i#4 = atoi::i#2 [phi:atoi::@4->atoi::@3#2] -- register_copy 
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
// __zp($5f) unsigned int cx16_k_macptr(__zp($ad) volatile char bytes, __zp($a9) void * volatile buffer)
cx16_k_macptr: {
    .label bytes = $ad
    .label buffer = $a9
    .label bytes_read = $70
    .label return = $5f
    // unsigned int bytes_read
    // [2708] cx16_k_macptr::bytes_read = 0 -- vwuz1=vwuc1 
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
    // [2710] cx16_k_macptr::return#0 = cx16_k_macptr::bytes_read -- vwuz1=vwuz2 
    lda.z bytes_read
    sta.z return
    lda.z bytes_read+1
    sta.z return+1
    // cx16_k_macptr::@return
    // }
    // [2711] cx16_k_macptr::return#1 = cx16_k_macptr::return#0
    // [2712] return 
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
// __register(X) char uctoa_append(__zp($57) char *buffer, __register(X) char value, __zp($38) char sub)
uctoa_append: {
    .label buffer = $57
    .label sub = $38
    // [2714] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [2714] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbuyy=vbuc1 
    ldy #0
    // [2714] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [2715] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbuxx_ge_vbuz1_then_la1 
    cpx.z sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [2716] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuyy 
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // uctoa_append::@return
    // }
    // [2717] return 
    rts
    // uctoa_append::@2
  __b2:
    // digit++;
    // [2718] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbuyy=_inc_vbuyy 
    iny
    // value -= sub
    // [2719] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbuxx=vbuxx_minus_vbuz1 
    txa
    sec
    sbc.z sub
    tax
    // [2714] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [2714] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [2714] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
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
// __register(A) char rom_byte_compare(__zp($59) char *ptr_rom, __register(A) char value)
rom_byte_compare: {
    .label ptr_rom = $59
    // if (*ptr_rom != value)
    // [2720] if(*rom_byte_compare::ptr_rom#0==rom_byte_compare::value#0) goto rom_byte_compare::@1 -- _deref_pbuz1_eq_vbuaa_then_la1 
    ldy #0
    cmp (ptr_rom),y
    beq __b2
    // [2721] phi from rom_byte_compare to rom_byte_compare::@2 [phi:rom_byte_compare->rom_byte_compare::@2]
    // rom_byte_compare::@2
    // [2722] phi from rom_byte_compare::@2 to rom_byte_compare::@1 [phi:rom_byte_compare::@2->rom_byte_compare::@1]
    // [2722] phi rom_byte_compare::return#0 = 0 [phi:rom_byte_compare::@2->rom_byte_compare::@1#0] -- vbuaa=vbuc1 
    tya
    rts
    // [2722] phi from rom_byte_compare to rom_byte_compare::@1 [phi:rom_byte_compare->rom_byte_compare::@1]
  __b2:
    // [2722] phi rom_byte_compare::return#0 = 1 [phi:rom_byte_compare->rom_byte_compare::@1#0] -- vbuaa=vbuc1 
    lda #1
    // rom_byte_compare::@1
    // rom_byte_compare::@return
    // }
    // [2723] return 
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
// __zp($25) unsigned long ultoa_append(__zp($55) char *buffer, __zp($25) unsigned long value, __zp($32) unsigned long sub)
ultoa_append: {
    .label buffer = $55
    .label value = $25
    .label sub = $32
    .label return = $25
    // [2725] phi from ultoa_append to ultoa_append::@1 [phi:ultoa_append->ultoa_append::@1]
    // [2725] phi ultoa_append::digit#2 = 0 [phi:ultoa_append->ultoa_append::@1#0] -- vbuxx=vbuc1 
    ldx #0
    // [2725] phi ultoa_append::value#2 = ultoa_append::value#0 [phi:ultoa_append->ultoa_append::@1#1] -- register_copy 
    // ultoa_append::@1
  __b1:
    // while (value >= sub)
    // [2726] if(ultoa_append::value#2>=ultoa_append::sub#0) goto ultoa_append::@2 -- vduz1_ge_vduz2_then_la1 
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
    // [2727] *ultoa_append::buffer#0 = DIGITS[ultoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuxx 
    lda DIGITS,x
    ldy #0
    sta (buffer),y
    // ultoa_append::@return
    // }
    // [2728] return 
    rts
    // ultoa_append::@2
  __b2:
    // digit++;
    // [2729] ultoa_append::digit#1 = ++ ultoa_append::digit#2 -- vbuxx=_inc_vbuxx 
    inx
    // value -= sub
    // [2730] ultoa_append::value#1 = ultoa_append::value#2 - ultoa_append::sub#0 -- vduz1=vduz1_minus_vduz2 
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
    // [2725] phi from ultoa_append::@2 to ultoa_append::@1 [phi:ultoa_append::@2->ultoa_append::@1]
    // [2725] phi ultoa_append::digit#2 = ultoa_append::digit#1 [phi:ultoa_append::@2->ultoa_append::@1#0] -- register_copy 
    // [2725] phi ultoa_append::value#2 = ultoa_append::value#1 [phi:ultoa_append::@2->ultoa_append::@1#1] -- register_copy 
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
// void rom_wait(__zp($30) char *ptr_rom)
rom_wait: {
    .label rom_wait__0 = $2e
    .label ptr_rom = $30
    // rom_wait::@1
  __b1:
    // test1 = *((brom_ptr_t)ptr_rom)
    // [2732] rom_wait::test1#1 = *rom_wait::ptr_rom#3 -- vbuxx=_deref_pbuz1 
    ldy #0
    lda (ptr_rom),y
    tax
    // test2 = *((brom_ptr_t)ptr_rom)
    // [2733] rom_wait::test2#1 = *rom_wait::ptr_rom#3 -- vbuyy=_deref_pbuz1 
    lda (ptr_rom),y
    tay
    // test1 & 0x40
    // [2734] rom_wait::$0 = rom_wait::test1#1 & $40 -- vbuz1=vbuxx_band_vbuc1 
    txa
    and #$40
    sta.z rom_wait__0
    // test2 & 0x40
    // [2735] rom_wait::$1 = rom_wait::test2#1 & $40 -- vbuaa=vbuyy_band_vbuc1 
    tya
    and #$40
    // while ((test1 & 0x40) != (test2 & 0x40))
    // [2736] if(rom_wait::$0!=rom_wait::$1) goto rom_wait::@1 -- vbuz1_neq_vbuaa_then_la1 
    cmp.z rom_wait__0
    bne __b1
    // rom_wait::@return
    // }
    // [2737] return 
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
// void rom_byte_program(__zp($45) unsigned long address, __register(Y) char value)
rom_byte_program: {
    .label rom_ptr1_rom_byte_program__0 = $49
    .label rom_ptr1_rom_byte_program__2 = $49
    .label rom_ptr1_return = $49
    .label address = $45
    // rom_byte_program::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2739] rom_byte_program::rom_ptr1_$2 = (unsigned int)rom_byte_program::address#0 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_byte_program__2
    lda.z address+1
    sta.z rom_ptr1_rom_byte_program__2+1
    // [2740] rom_byte_program::rom_ptr1_$0 = rom_byte_program::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_byte_program__0
    and #<$3fff
    sta.z rom_ptr1_rom_byte_program__0
    lda.z rom_ptr1_rom_byte_program__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_byte_program__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2741] rom_byte_program::rom_ptr1_return#0 = rom_byte_program::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_byte_program::@1
    // rom_write_byte(address, value)
    // [2742] rom_write_byte::address#3 = rom_byte_program::address#0
    // [2743] rom_write_byte::value#3 = rom_byte_program::value#0
    // [2744] call rom_write_byte
    // [2626] phi from rom_byte_program::@1 to rom_write_byte [phi:rom_byte_program::@1->rom_write_byte]
    // [2626] phi rom_write_byte::value#10 = rom_write_byte::value#3 [phi:rom_byte_program::@1->rom_write_byte#0] -- register_copy 
    // [2626] phi rom_write_byte::address#4 = rom_write_byte::address#3 [phi:rom_byte_program::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_byte_program::@2
    // rom_wait(ptr_rom)
    // [2745] rom_wait::ptr_rom#1 = (char *)rom_byte_program::rom_ptr1_return#0 -- pbuz1=pbuz2 
    lda.z rom_ptr1_return
    sta.z rom_wait.ptr_rom
    lda.z rom_ptr1_return+1
    sta.z rom_wait.ptr_rom+1
    // [2746] call rom_wait
    // [2731] phi from rom_byte_program::@2 to rom_wait [phi:rom_byte_program::@2->rom_wait]
    // [2731] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#1 [phi:rom_byte_program::@2->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_byte_program::@return
    // }
    // [2747] return 
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
// void memcpy8_vram_vram(__zp($2f) char dbank_vram, __zp($2c) unsigned int doffset_vram, __register(Y) char sbank_vram, __zp($23) unsigned int soffset_vram, __register(X) char num8)
memcpy8_vram_vram: {
    .label dbank_vram = $2f
    .label doffset_vram = $2c
    .label soffset_vram = $23
    .label num8 = $22
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2748] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [2749] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbuaa=_byte0_vwuz1 
    lda.z soffset_vram
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [2750] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [2751] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbuaa=_byte1_vwuz1 
    lda.z soffset_vram+1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [2752] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [2753] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbuaa=vbuyy_bor_vbuc1 
    tya
    ora #VERA_INC_1
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [2754] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [2755] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [2756] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbuaa=_byte0_vwuz1 
    lda.z doffset_vram
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [2757] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [2758] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbuaa=_byte1_vwuz1 
    lda.z doffset_vram+1
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [2759] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [2760] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbuaa=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z dbank_vram
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [2761] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_H
    // [2762] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [2762] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [2763] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbuxx=_dec_vbuz1 
    ldx.z num8
    dex
    // [2764] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbuz1_then_la1 
    lda.z num8
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [2765] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [2766] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [2767] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbuz1=vbuxx 
    stx.z num8
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
  display_smc_rom_issue__text: .word __53, info_text4, __55, __56, info_text4, __58, __59
  display_debriefing_text_smc: .word __72, info_text4, __62, __63, __64, info_text4, __66, info_text4, __68, __69, __70, __71
  display_debriefing_text_rom: .word __72, info_text4, __74, __75
  smc_version_string: .fill $10, 0
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
  __55: .text "Both the SMC and the main ROM must be updated together,"
  .byte 0
  __56: .text "to avoid possible conflicts of firmware, bricking your CX16."
  .byte 0
  __58: .text "Therefore, ensure you have the correct SMC.BIN and ROM.BIN"
  .byte 0
  __59: .text "files placed on your SDcard."
  .byte 0
  __62: .text "Because your SMC chipset has been updated,"
  .byte 0
  __63: .text "the restart process differs, depending on the"
  .byte 0
  __64: .text "SMC boootloader version installed on your CX16 board:"
  .byte 0
  __66: .text "- SMC bootloader v2.0: your CX16 will automatically shut down."
  .byte 0
  __68: .text "- SMC bootloader v1.0: you need to "
  .byte 0
  __69: .text "  COMPLETELY DISCONNECT your CX16 from the power source!"
  .byte 0
  __70: .text "  The power-off button won't work!"
  .byte 0
  __71: .text "  Then, reconnect and start the CX16 normally."
  .byte 0
  __72: .text "Your CX16 system has been successfully updated!"
  .byte 0
  __74: .text "Since your CX16 system SMC and main ROM chipset"
  .byte 0
  __75: .text "have not been updated, your CX16 will just reset."
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
  s13: .text "Reading "
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
  // Globals
  status_smc: .byte 0
  status_vera: .byte 0
  // Globals (to save zeropage and code overhead with parameter passing.)
  smc_bootloader: .word 0
  smc_file_size: .word 0
