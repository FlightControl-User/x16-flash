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
  .const STATUS_FLASH = 6
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
  .label __snprintf_buffer = $c0
  .label __errno = $6b
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
    .label conio_x16_init__4 = $d7
    .label conio_x16_init__6 = $d7
    // screenlayer1()
    // [20] call screenlayer1
    jsr screenlayer1
    // [21] phi from conio_x16_init to conio_x16_init::@1 [phi:conio_x16_init->conio_x16_init::@1]
    // conio_x16_init::@1
    // textcolor(CONIO_TEXTCOLOR_DEFAULT)
    // [22] call textcolor
    // [572] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [572] phi textcolor::color#17 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [23] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [24] call bgcolor
    // [577] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [577] phi bgcolor::color#14 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbuxx=vbuc1 
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
    // [31] conio_x16_init::$5 = byte1  conio_x16_init::$4 -- vbuaa=_byte1_vwuz1 
    lda.z conio_x16_init__4+1
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
    // [36] conio_x16_init::$7 = byte0  conio_x16_init::$6 -- vbuaa=_byte0_vwuz1 
    lda.z conio_x16_init__6
    // __conio.cursor_y = BYTE0(cbm_k_plot_get())
    // [37] *((char *)&__conio+1) = conio_x16_init::$7 -- _deref_pbuc1=vbuaa 
    sta __conio+1
    // gotoxy(__conio.cursor_x, __conio.cursor_y)
    // [38] gotoxy::x#2 = *((char *)&__conio) -- vbuxx=_deref_pbuc1 
    ldx __conio
    // [39] gotoxy::y#2 = *((char *)&__conio+1) -- vbuyy=_deref_pbuc1 
    tay
    // [40] call gotoxy
    // [590] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [590] phi gotoxy::y#24 = gotoxy::y#2 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [590] phi gotoxy::x#24 = gotoxy::x#2 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
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
}
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
    .label main__102 = $69
    .label main__159 = $67
    .label rom_chip = $f5
    .label intro_status = $f3
    .label release = $ab
    .label major = $ae
    .label minor = $5d
    .label rom_chip1 = $f6
    .label file_smc_release = $7a
    .label file_smc_major = $bf
    .label file = $f7
    .label rom_bytes_read = $b5
    .label rom_file_modulo = $b9
    .label check_status_smc4_return = $7c
    .label check_status_vera1_return = $aa
    .label check_status_roms_all1_return = $f5
    .label check_status_smc5_return = $c9
    .label check_status_smc6_return = $e7
    .label check_status_smc7_return = $6a
    .label rom_chip3 = $f4
    .label check_status_smc9_return = $b2
    .label check_status_smc10_return = $c2
    .label w = $fb
    .label w1 = $fa
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
    // [75] phi from main::bank_set_brom1 to main::@41 [phi:main::bank_set_brom1->main::@41]
    // main::@41
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
    // [611] phi from main::@41 to display_frame_init_64 [phi:main::@41->display_frame_init_64]
    jsr display_frame_init_64
    // [77] phi from main::@41 to main::@62 [phi:main::@41->main::@62]
    // main::@62
    // display_frame_draw()
    // [78] call display_frame_draw
    // [631] phi from main::@62 to display_frame_draw [phi:main::@62->display_frame_draw]
    jsr display_frame_draw
    // [79] phi from main::@62 to main::@63 [phi:main::@62->main::@63]
    // main::@63
    // display_frame_title("Commander X16 Flash Utility!")
    // [80] call display_frame_title
    // [672] phi from main::@63 to display_frame_title [phi:main::@63->display_frame_title]
    jsr display_frame_title
    // [81] phi from main::@63 to main::display_info_title1 [phi:main::@63->main::display_info_title1]
    // main::display_info_title1
    // cputsxy(INFO_X-2, INFO_Y-2, "# Chip Status    Type   Curr. Release Update Info")
    // [82] call cputsxy
    // [677] phi from main::display_info_title1 to cputsxy [phi:main::display_info_title1->cputsxy]
    // [677] phi cputsxy::s#3 = main::s [phi:main::display_info_title1->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z cputsxy.s
    lda #>s
    sta.z cputsxy.s+1
    // [677] phi cputsxy::y#3 = $11-2 [phi:main::display_info_title1->cputsxy#1] -- vbuyy=vbuc1 
    ldy #$11-2
    // [677] phi cputsxy::x#3 = 4-2 [phi:main::display_info_title1->cputsxy#2] -- vbuxx=vbuc1 
    ldx #4-2
    jsr cputsxy
    // [83] phi from main::display_info_title1 to main::@64 [phi:main::display_info_title1->main::@64]
    // main::@64
    // cputsxy(INFO_X-2, INFO_Y-1, "- ---- --------- ------ ------------- --------------------")
    // [84] call cputsxy
    // [677] phi from main::@64 to cputsxy [phi:main::@64->cputsxy]
    // [677] phi cputsxy::s#3 = main::s1 [phi:main::@64->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s1
    sta.z cputsxy.s
    lda #>s1
    sta.z cputsxy.s+1
    // [677] phi cputsxy::y#3 = $11-1 [phi:main::@64->cputsxy#1] -- vbuyy=vbuc1 
    ldy #$11-1
    // [677] phi cputsxy::x#3 = 4-2 [phi:main::@64->cputsxy#2] -- vbuxx=vbuc1 
    ldx #4-2
    jsr cputsxy
    // [85] phi from main::@64 to main::@42 [phi:main::@64->main::@42]
    // main::@42
    // display_action_progress("Introduction ...")
    // [86] call display_action_progress
    // [684] phi from main::@42 to display_action_progress [phi:main::@42->display_action_progress]
    // [684] phi display_action_progress::info_text#10 = main::info_text [phi:main::@42->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [87] phi from main::@42 to main::@65 [phi:main::@42->main::@65]
    // main::@65
    // display_progress_clear()
    // [88] call display_progress_clear
    // [698] phi from main::@65 to display_progress_clear [phi:main::@65->display_progress_clear]
    jsr display_progress_clear
    // [89] phi from main::@65 to main::@66 [phi:main::@65->main::@66]
    // main::@66
    // display_chip_smc()
    // [90] call display_chip_smc
    // [713] phi from main::@66 to display_chip_smc [phi:main::@66->display_chip_smc]
    jsr display_chip_smc
    // [91] phi from main::@66 to main::@67 [phi:main::@66->main::@67]
    // main::@67
    // display_chip_vera()
    // [92] call display_chip_vera
    // [718] phi from main::@67 to display_chip_vera [phi:main::@67->display_chip_vera]
    jsr display_chip_vera
    // [93] phi from main::@67 to main::@68 [phi:main::@67->main::@68]
    // main::@68
    // display_chip_rom()
    // [94] call display_chip_rom
    // [723] phi from main::@68 to display_chip_rom [phi:main::@68->display_chip_rom]
    jsr display_chip_rom
    // [95] phi from main::@68 to main::@69 [phi:main::@68->main::@69]
    // main::@69
    // display_info_smc(STATUS_COLOR_NONE, NULL)
    // [96] call display_info_smc
    // [742] phi from main::@69 to display_info_smc [phi:main::@69->display_info_smc]
    // [742] phi display_info_smc::info_text#11 = 0 [phi:main::@69->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [742] phi display_info_smc::info_status#11 = BLACK [phi:main::@69->display_info_smc#1] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [97] phi from main::@69 to main::@70 [phi:main::@69->main::@70]
    // main::@70
    // display_info_vera(STATUS_NONE, NULL)
    // [98] call display_info_vera
    // [772] phi from main::@70 to display_info_vera [phi:main::@70->display_info_vera]
    // [772] phi display_info_vera::info_text#10 = 0 [phi:main::@70->display_info_vera#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_vera.info_text
    sta.z display_info_vera.info_text+1
    // [772] phi display_info_vera::info_status#3 = STATUS_NONE [phi:main::@70->display_info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_NONE
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // [99] phi from main::@70 to main::@6 [phi:main::@70->main::@6]
    // [99] phi main::rom_chip#2 = 0 [phi:main::@70->main::@6#0] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_chip
    // main::@6
  __b6:
    // for(unsigned char rom_chip=0; rom_chip<8; rom_chip++)
    // [100] if(main::rom_chip#2<8) goto main::@7 -- vbuz1_lt_vbuc1_then_la1 
    lda.z rom_chip
    cmp #8
    bcs !__b7+
    jmp __b7
  !__b7:
    // main::bank_set_brom2
    // BROM = bank
    // [101] BROM = main::bank_set_brom2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom2_bank
    sta.z BROM
    // main::CLI1
    // asm
    // asm { cli  }
    cli
    // [103] phi from main::CLI1 to main::@43 [phi:main::CLI1->main::@43]
    // main::@43
    // display_progress_text(display_into_briefing_text, display_intro_briefing_count)
    // [104] call display_progress_text
    // [798] phi from main::@43 to display_progress_text [phi:main::@43->display_progress_text]
    // [798] phi display_progress_text::text#10 = display_into_briefing_text [phi:main::@43->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_into_briefing_text
    sta.z display_progress_text.text
    lda #>display_into_briefing_text
    sta.z display_progress_text.text+1
    // [798] phi display_progress_text::lines#11 = display_intro_briefing_count [phi:main::@43->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_intro_briefing_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [105] phi from main::@43 to main::@73 [phi:main::@43->main::@73]
    // main::@73
    // util_wait_space()
    // [106] call util_wait_space
    // [808] phi from main::@73 to util_wait_space [phi:main::@73->util_wait_space]
    jsr util_wait_space
    // [107] phi from main::@73 to main::@74 [phi:main::@73->main::@74]
    // main::@74
    // display_progress_text(display_into_colors_text, display_intro_colors_count)
    // [108] call display_progress_text
    // [798] phi from main::@74 to display_progress_text [phi:main::@74->display_progress_text]
    // [798] phi display_progress_text::text#10 = display_into_colors_text [phi:main::@74->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_into_colors_text
    sta.z display_progress_text.text
    lda #>display_into_colors_text
    sta.z display_progress_text.text+1
    // [798] phi display_progress_text::lines#11 = display_intro_colors_count [phi:main::@74->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_intro_colors_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [109] phi from main::@74 to main::@8 [phi:main::@74->main::@8]
    // [109] phi main::intro_status#2 = 0 [phi:main::@74->main::@8#0] -- vbuz1=vbuc1 
    lda #0
    sta.z intro_status
    // main::@8
  __b8:
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [110] if(main::intro_status#2<$b) goto main::@9 -- vbuz1_lt_vbuc1_then_la1 
    lda.z intro_status
    cmp #$b
    bcs !__b9+
    jmp __b9
  !__b9:
    // [111] phi from main::@8 to main::@10 [phi:main::@8->main::@10]
    // main::@10
    // util_wait_space()
    // [112] call util_wait_space
    // [808] phi from main::@10 to util_wait_space [phi:main::@10->util_wait_space]
    jsr util_wait_space
    // [113] phi from main::@10 to main::@76 [phi:main::@10->main::@76]
    // main::@76
    // display_progress_clear()
    // [114] call display_progress_clear
    // [698] phi from main::@76 to display_progress_clear [phi:main::@76->display_progress_clear]
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
    // [117] phi from main::bank_set_brom3 to main::@44 [phi:main::bank_set_brom3->main::@44]
    // main::@44
    // smc_detect()
    // [118] call smc_detect
    // [811] phi from main::@44 to smc_detect [phi:main::@44->smc_detect]
    jsr smc_detect
    // [119] phi from main::@44 to main::@77 [phi:main::@44->main::@77]
    // main::@77
    // strcpy(smc_version_string, "0.0.0")
    // [120] call strcpy
    // [813] phi from main::@77 to strcpy [phi:main::@77->strcpy]
    // [813] phi strcpy::dst#0 = smc_version_string [phi:main::@77->strcpy#0] -- pbuz1=pbuc1 
    lda #<smc_version_string
    sta.z strcpy.dst
    lda #>smc_version_string
    sta.z strcpy.dst+1
    // [813] phi strcpy::src#0 = main::source1 [phi:main::@77->strcpy#1] -- pbuz1=pbuc1 
    lda #<source1
    sta.z strcpy.src
    lda #>source1
    sta.z strcpy.src+1
    jsr strcpy
    // [121] phi from main::@77 to main::@78 [phi:main::@77->main::@78]
    // main::@78
    // display_chip_smc()
    // [122] call display_chip_smc
    // [713] phi from main::@78 to display_chip_smc [phi:main::@78->display_chip_smc]
    jsr display_chip_smc
    // main::@11
    // unsigned int release = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_VERSION)
    // [123] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [124] cx16_k_i2c_read_byte::offset = $30 -- vbum1=vbuc1 
    lda #$30
    sta cx16_k_i2c_read_byte.offset
    // [125] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [126] cx16_k_i2c_read_byte::return#2 = cx16_k_i2c_read_byte::return#1 -- vwuz1=vwuz2 
    lda.z cx16_k_i2c_read_byte.return
    sta.z cx16_k_i2c_read_byte.return_1
    lda.z cx16_k_i2c_read_byte.return+1
    sta.z cx16_k_i2c_read_byte.return_1+1
    // main::@79
    // [127] main::release#0 = cx16_k_i2c_read_byte::return#2
    // unsigned int major = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_MAJOR)
    // [128] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [129] cx16_k_i2c_read_byte::offset = $31 -- vbum1=vbuc1 
    lda #$31
    sta cx16_k_i2c_read_byte.offset
    // [130] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [131] cx16_k_i2c_read_byte::return#3 = cx16_k_i2c_read_byte::return#1 -- vwuz1=vwuz2 
    lda.z cx16_k_i2c_read_byte.return
    sta.z cx16_k_i2c_read_byte.return_2
    lda.z cx16_k_i2c_read_byte.return+1
    sta.z cx16_k_i2c_read_byte.return_2+1
    // main::@80
    // [132] main::major#0 = cx16_k_i2c_read_byte::return#3
    // unsigned int minor = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_MINOR)
    // [133] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [134] cx16_k_i2c_read_byte::offset = $32 -- vbum1=vbuc1 
    lda #$32
    sta cx16_k_i2c_read_byte.offset
    // [135] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [136] cx16_k_i2c_read_byte::return#4 = cx16_k_i2c_read_byte::return#1
    // main::@81
    // [137] main::minor#0 = cx16_k_i2c_read_byte::return#4
    // smc_get_version_text(smc_version_string, release, major, minor)
    // [138] smc_get_version_text::release#0 = main::release#0 -- vbuxx=vwuz1 
    ldx.z release
    // [139] smc_get_version_text::major#0 = main::major#0 -- vbuz1=vwuz2 
    lda.z major
    sta.z smc_get_version_text.major
    // [140] smc_get_version_text::minor#0 = main::minor#0 -- vbuz1=vwuz2 
    lda.z minor
    sta.z smc_get_version_text.minor
    // [141] call smc_get_version_text
    // [826] phi from main::@81 to smc_get_version_text [phi:main::@81->smc_get_version_text]
    // [826] phi smc_get_version_text::minor#2 = smc_get_version_text::minor#0 [phi:main::@81->smc_get_version_text#0] -- register_copy 
    // [826] phi smc_get_version_text::major#2 = smc_get_version_text::major#0 [phi:main::@81->smc_get_version_text#1] -- register_copy 
    // [826] phi smc_get_version_text::release#2 = smc_get_version_text::release#0 [phi:main::@81->smc_get_version_text#2] -- register_copy 
    // [826] phi smc_get_version_text::version_string#2 = smc_version_string [phi:main::@81->smc_get_version_text#3] -- pbuz1=pbuc1 
    lda #<smc_version_string
    sta.z smc_get_version_text.version_string
    lda #>smc_version_string
    sta.z smc_get_version_text.version_string+1
    jsr smc_get_version_text
    // [142] phi from main::@81 to main::@82 [phi:main::@81->main::@82]
    // main::@82
    // sprintf(info_text, "BL:v%u", smc_bootloader)
    // [143] call snprintf_init
    // [845] phi from main::@82 to snprintf_init [phi:main::@82->snprintf_init]
    // [845] phi snprintf_init::s#15 = info_text [phi:main::@82->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [144] phi from main::@82 to main::@83 [phi:main::@82->main::@83]
    // main::@83
    // sprintf(info_text, "BL:v%u", smc_bootloader)
    // [145] call printf_str
    // [850] phi from main::@83 to printf_str [phi:main::@83->printf_str]
    // [850] phi printf_str::putc#48 = &snputc [phi:main::@83->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = main::s4 [phi:main::@83->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // [146] phi from main::@83 to main::@84 [phi:main::@83->main::@84]
    // main::@84
    // sprintf(info_text, "BL:v%u", smc_bootloader)
    // [147] call printf_uint
    // [859] phi from main::@84 to printf_uint [phi:main::@84->printf_uint]
    // [859] phi printf_uint::format_zero_padding#10 = 0 [phi:main::@84->printf_uint#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uint.format_zero_padding
    // [859] phi printf_uint::format_min_length#10 = 0 [phi:main::@84->printf_uint#1] -- vbuz1=vbuc1 
    sta.z printf_uint.format_min_length
    // [859] phi printf_uint::format_radix#10 = DECIMAL [phi:main::@84->printf_uint#2] -- vbuxx=vbuc1 
    ldx #DECIMAL
    // [859] phi printf_uint::uvalue#10 = smc_detect::return#0 [phi:main::@84->printf_uint#3] -- vwuz1=vwuc1 
    lda #<smc_detect.return
    sta.z printf_uint.uvalue
    lda #>smc_detect.return
    sta.z printf_uint.uvalue+1
    jsr printf_uint
    // main::@85
    // sprintf(info_text, "BL:v%u", smc_bootloader)
    // [148] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [149] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_smc(STATUS_DETECTED, info_text)
    // [151] call display_info_smc
  // All ok, display bootloader version.
    // [742] phi from main::@85 to display_info_smc [phi:main::@85->display_info_smc]
    // [742] phi display_info_smc::info_text#11 = info_text [phi:main::@85->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_smc.info_text
    lda #>@info_text
    sta.z display_info_smc.info_text+1
    // [742] phi display_info_smc::info_status#11 = STATUS_DETECTED [phi:main::@85->display_info_smc#1] -- vbuz1=vbuc1 
    lda #STATUS_DETECTED
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [152] phi from main::@85 to main::@1 [phi:main::@85->main::@1]
    // main::@1
    // display_chip_vera()
    // [153] call display_chip_vera
  // Detecting VERA FPGA.
    // [718] phi from main::@1 to display_chip_vera [phi:main::@1->display_chip_vera]
    jsr display_chip_vera
    // [154] phi from main::@1 to main::@86 [phi:main::@1->main::@86]
    // main::@86
    // display_info_vera(STATUS_DETECTED, "VERA installed, OK")
    // [155] call display_info_vera
    // [772] phi from main::@86 to display_info_vera [phi:main::@86->display_info_vera]
    // [772] phi display_info_vera::info_text#10 = main::info_text3 [phi:main::@86->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text3
    sta.z display_info_vera.info_text
    lda #>info_text3
    sta.z display_info_vera.info_text+1
    // [772] phi display_info_vera::info_status#3 = STATUS_DETECTED [phi:main::@86->display_info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_DETECTED
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // [156] phi from main::@86 to main::@87 [phi:main::@86->main::@87]
    // main::@87
    // rom_detect()
    // [157] call rom_detect
  // Detecting ROM chips
    // [869] phi from main::@87 to rom_detect [phi:main::@87->rom_detect]
    jsr rom_detect
    // [158] phi from main::@87 to main::@88 [phi:main::@87->main::@88]
    // main::@88
    // display_chip_rom()
    // [159] call display_chip_rom
    // [723] phi from main::@88 to display_chip_rom [phi:main::@88->display_chip_rom]
    jsr display_chip_rom
    // [160] phi from main::@88 to main::@12 [phi:main::@88->main::@12]
    // [160] phi main::rom_chip1#10 = 0 [phi:main::@88->main::@12#0] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_chip1
    // main::@12
  __b12:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [161] if(main::rom_chip1#10<8) goto main::@13 -- vbuz1_lt_vbuc1_then_la1 
    lda.z rom_chip1
    cmp #8
    bcs !__b13+
    jmp __b13
  !__b13:
    // main::SEI3
    // asm
    // asm { sei  }
    sei
    // main::check_status_smc1
    // status_smc == status
    // [163] main::check_status_smc1_$0 = status_smc#0 == STATUS_DETECTED -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_DETECTED
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [164] main::check_status_smc1_return#0 = (char)main::check_status_smc1_$0
    // main::@45
    // if(check_status_smc(STATUS_DETECTED))
    // [165] if(0==main::check_status_smc1_return#0) goto main::CLI2 -- 0_eq_vbuaa_then_la1 
    cmp #0
    bne !__b4+
    jmp __b4
  !__b4:
    // [166] phi from main::@45 to main::@16 [phi:main::@45->main::@16]
    // main::@16
    // smc_read(0)
    // [167] call smc_read
    // [923] phi from main::@16 to smc_read [phi:main::@16->smc_read]
    jsr smc_read
    // smc_read(0)
    // [168] smc_read::return#2 = smc_read::return#0
    // main::@93
    // smc_file_size = smc_read(0)
    // [169] smc_file_size#0 = smc_read::return#2 -- vwum1=vwuz2 
    lda.z smc_read.return
    sta smc_file_size
    lda.z smc_read.return+1
    sta smc_file_size+1
    // if (!smc_file_size)
    // [170] if(0==smc_file_size#0) goto main::@19 -- 0_eq_vwum1_then_la1 
    // In case no file was found, set the status to error and skip to the next, else, mention the amount of bytes read.
    lda smc_file_size
    ora smc_file_size+1
    bne !__b19+
    jmp __b19
  !__b19:
    // main::@17
    // if(smc_file_size > 0x1E00)
    // [171] if(smc_file_size#0>$1e00) goto main::@20 -- vwum1_gt_vwuc1_then_la1 
    // If the smc.bin file size is larger than 0x1E00 then there is an issue!
    lda #>$1e00
    cmp smc_file_size+1
    bcs !__b20+
    jmp __b20
  !__b20:
    bne !+
    lda #<$1e00
    cmp smc_file_size
    bcs !__b20+
    jmp __b20
  !__b20:
  !:
    // main::@18
    // unsigned char file_smc_release = rom_get_release(*((char*)0xA030))
    // [172] rom_get_release::release#2 = *((char *) 41008) -- vbuxx=_deref_pbuc1 
    ldx $a030
    // [173] call rom_get_release
  // All ok, display the SMC.BIN file version and SMC on-board bootloader.
  // Fill the version data ...
    // [977] phi from main::@18 to rom_get_release [phi:main::@18->rom_get_release]
    // [977] phi rom_get_release::release#4 = rom_get_release::release#2 [phi:main::@18->rom_get_release#0] -- register_copy 
    jsr rom_get_release
    // unsigned char file_smc_release = rom_get_release(*((char*)0xA030))
    // [174] rom_get_release::return#3 = rom_get_release::return#0
    // main::@94
    // [175] main::file_smc_release#0 = rom_get_release::return#3 -- vbuz1=vbuxx 
    stx.z file_smc_release
    // unsigned char file_smc_major = rom_get_prefix(*((char*)0xA031))
    // [176] rom_get_prefix::release#1 = *((char *) 41009) -- vbuaa=_deref_pbuc1 
    lda $a031
    // [177] call rom_get_prefix
    // [984] phi from main::@94 to rom_get_prefix [phi:main::@94->rom_get_prefix]
    // [984] phi rom_get_prefix::release#4 = rom_get_prefix::release#1 [phi:main::@94->rom_get_prefix#0] -- register_copy 
    jsr rom_get_prefix
    // unsigned char file_smc_major = rom_get_prefix(*((char*)0xA031))
    // [178] rom_get_prefix::return#3 = rom_get_prefix::return#0
    // main::@95
    // [179] main::file_smc_major#0 = rom_get_prefix::return#3 -- vbuz1=vbuxx 
    stx.z file_smc_major
    // unsigned char file_smc_minor = rom_get_prefix(*((char*)0xA032))
    // [180] rom_get_prefix::release#2 = *((char *) 41010) -- vbuaa=_deref_pbuc1 
    lda $a032
    // [181] call rom_get_prefix
    // [984] phi from main::@95 to rom_get_prefix [phi:main::@95->rom_get_prefix]
    // [984] phi rom_get_prefix::release#4 = rom_get_prefix::release#2 [phi:main::@95->rom_get_prefix#0] -- register_copy 
    jsr rom_get_prefix
    // unsigned char file_smc_minor = rom_get_prefix(*((char*)0xA032))
    // [182] rom_get_prefix::return#4 = rom_get_prefix::return#0
    // main::@96
    // [183] main::file_smc_minor#0 = rom_get_prefix::return#4 -- vbuyy=vbuxx 
    txa
    tay
    // smc_get_version_text(file_smc_version_text, file_smc_release, file_smc_major, file_smc_minor)
    // [184] smc_get_version_text::release#1 = main::file_smc_release#0 -- vbuxx=vbuz1 
    ldx.z file_smc_release
    // [185] smc_get_version_text::major#1 = main::file_smc_major#0
    // [186] smc_get_version_text::minor#1 = main::file_smc_minor#0 -- vbuz1=vbuyy 
    sty.z smc_get_version_text.minor
    // [187] call smc_get_version_text
    // [826] phi from main::@96 to smc_get_version_text [phi:main::@96->smc_get_version_text]
    // [826] phi smc_get_version_text::minor#2 = smc_get_version_text::minor#1 [phi:main::@96->smc_get_version_text#0] -- register_copy 
    // [826] phi smc_get_version_text::major#2 = smc_get_version_text::major#1 [phi:main::@96->smc_get_version_text#1] -- register_copy 
    // [826] phi smc_get_version_text::release#2 = smc_get_version_text::release#1 [phi:main::@96->smc_get_version_text#2] -- register_copy 
    // [826] phi smc_get_version_text::version_string#2 = main::file_smc_version_text [phi:main::@96->smc_get_version_text#3] -- pbuz1=pbuc1 
    lda #<file_smc_version_text
    sta.z smc_get_version_text.version_string
    lda #>file_smc_version_text
    sta.z smc_get_version_text.version_string+1
    jsr smc_get_version_text
    // [188] phi from main::@96 to main::@97 [phi:main::@96->main::@97]
    // main::@97
    // sprintf(info_text, "BL:v%u, SMC:%s", smc_bootloader, file_smc_version_text)
    // [189] call snprintf_init
    // [845] phi from main::@97 to snprintf_init [phi:main::@97->snprintf_init]
    // [845] phi snprintf_init::s#15 = info_text [phi:main::@97->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [190] phi from main::@97 to main::@98 [phi:main::@97->main::@98]
    // main::@98
    // sprintf(info_text, "BL:v%u, SMC:%s", smc_bootloader, file_smc_version_text)
    // [191] call printf_str
    // [850] phi from main::@98 to printf_str [phi:main::@98->printf_str]
    // [850] phi printf_str::putc#48 = &snputc [phi:main::@98->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = main::s4 [phi:main::@98->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // [192] phi from main::@98 to main::@99 [phi:main::@98->main::@99]
    // main::@99
    // sprintf(info_text, "BL:v%u, SMC:%s", smc_bootloader, file_smc_version_text)
    // [193] call printf_uint
    // [859] phi from main::@99 to printf_uint [phi:main::@99->printf_uint]
    // [859] phi printf_uint::format_zero_padding#10 = 0 [phi:main::@99->printf_uint#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uint.format_zero_padding
    // [859] phi printf_uint::format_min_length#10 = 0 [phi:main::@99->printf_uint#1] -- vbuz1=vbuc1 
    sta.z printf_uint.format_min_length
    // [859] phi printf_uint::format_radix#10 = DECIMAL [phi:main::@99->printf_uint#2] -- vbuxx=vbuc1 
    ldx #DECIMAL
    // [859] phi printf_uint::uvalue#10 = smc_detect::return#0 [phi:main::@99->printf_uint#3] -- vwuz1=vwuc1 
    lda #<smc_detect.return
    sta.z printf_uint.uvalue
    lda #>smc_detect.return
    sta.z printf_uint.uvalue+1
    jsr printf_uint
    // [194] phi from main::@99 to main::@100 [phi:main::@99->main::@100]
    // main::@100
    // sprintf(info_text, "BL:v%u, SMC:%s", smc_bootloader, file_smc_version_text)
    // [195] call printf_str
    // [850] phi from main::@100 to printf_str [phi:main::@100->printf_str]
    // [850] phi printf_str::putc#48 = &snputc [phi:main::@100->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = main::s6 [phi:main::@100->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // [196] phi from main::@100 to main::@101 [phi:main::@100->main::@101]
    // main::@101
    // sprintf(info_text, "BL:v%u, SMC:%s", smc_bootloader, file_smc_version_text)
    // [197] call printf_string
    // [993] phi from main::@101 to printf_string [phi:main::@101->printf_string]
    // [993] phi printf_string::putc#21 = &snputc [phi:main::@101->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [993] phi printf_string::str#21 = main::file_smc_version_text [phi:main::@101->printf_string#1] -- pbuz1=pbuc1 
    lda #<file_smc_version_text
    sta.z printf_string.str
    lda #>file_smc_version_text
    sta.z printf_string.str+1
    // [993] phi printf_string::format_justify_left#21 = 0 [phi:main::@101->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [993] phi printf_string::format_min_length#21 = 0 [phi:main::@101->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@102
    // sprintf(info_text, "BL:v%u, SMC:%s", smc_bootloader, file_smc_version_text)
    // [198] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [199] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_smc(STATUS_FLASH, NULL)
    // [201] call display_info_smc
  // All ok, display bootloader version.
    // [742] phi from main::@102 to display_info_smc [phi:main::@102->display_info_smc]
    // [742] phi display_info_smc::info_text#11 = 0 [phi:main::@102->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [742] phi display_info_smc::info_status#11 = STATUS_FLASH [phi:main::@102->display_info_smc#1] -- vbuz1=vbuc1 
    lda #STATUS_FLASH
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [202] phi from main::@102 main::@19 main::@20 to main::CLI2 [phi:main::@102/main::@19/main::@20->main::CLI2]
    // [202] phi __errno#219 = __errno#16 [phi:main::@102/main::@19/main::@20->main::CLI2#0] -- register_copy 
    jmp CLI2
    // [202] phi from main::@45 to main::CLI2 [phi:main::@45->main::CLI2]
  __b4:
    // [202] phi __errno#219 = 0 [phi:main::@45->main::CLI2#0] -- vwsz1=vwsc1 
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
    // [205] phi from main::SEI4 to main::@21 [phi:main::SEI4->main::@21]
    // [205] phi __errno#115 = __errno#219 [phi:main::SEI4->main::@21#0] -- register_copy 
    // [205] phi main::rom_chip2#10 = 0 [phi:main::SEI4->main::@21#1] -- vbum1=vbuc1 
    lda #0
    sta rom_chip2
  // We loop all the possible ROM chip slots on the board and on the extension card,
  // and we check the file contents.
  // Any error identified gets reported and this chip will not be flashed.
  // In case of ROM0.BIN in error, no flashing will be done!
    // main::@21
  __b21:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [206] if(main::rom_chip2#10<8) goto main::bank_set_brom4 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip2
    cmp #8
    bcs !bank_set_brom4+
    jmp bank_set_brom4
  !bank_set_brom4:
    // main::bank_set_brom5
    // BROM = bank
    // [207] BROM = main::bank_set_brom5_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom5_bank
    sta.z BROM
    // main::CLI3
    // asm
    // asm { cli  }
    cli
    // main::check_status_smc2
    // status_smc == status
    // [209] main::check_status_smc2_$0 = status_smc#0 == STATUS_FLASH -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [210] main::check_status_smc2_return#0 = (char)main::check_status_smc2_$0 -- vbuyy=vbuaa 
    tay
    // [211] phi from main::check_status_smc2 to main::check_status_cx16_rom1 [phi:main::check_status_smc2->main::check_status_cx16_rom1]
    // main::check_status_cx16_rom1
    // main::check_status_cx16_rom1_check_status_rom1
    // status_rom[rom_chip] == status
    // [212] main::check_status_cx16_rom1_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboaa=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [213] main::check_status_cx16_rom1_check_status_rom1_return#0 = (char)main::check_status_cx16_rom1_check_status_rom1_$0 -- vbuxx=vbuaa 
    tax
    // main::@47
    // if(!check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH))
    // [214] if(0!=main::check_status_smc2_return#0) goto main::check_status_smc3 -- 0_neq_vbuyy_then_la1 
    cpy #0
    bne check_status_smc3
    // main::@154
    // [215] if(0!=main::check_status_cx16_rom1_check_status_rom1_return#0) goto main::@28 -- 0_neq_vbuxx_then_la1 
    cpx #0
    beq !__b28+
    jmp __b28
  !__b28:
    // main::check_status_smc3
  check_status_smc3:
    // status_smc == status
    // [216] main::check_status_smc3_$0 = status_smc#0 == STATUS_FLASH -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [217] main::check_status_smc3_return#0 = (char)main::check_status_smc3_$0 -- vbuyy=vbuaa 
    tay
    // [218] phi from main::check_status_smc3 to main::check_status_cx16_rom2 [phi:main::check_status_smc3->main::check_status_cx16_rom2]
    // main::check_status_cx16_rom2
    // main::check_status_cx16_rom2_check_status_rom1
    // status_rom[rom_chip] == status
    // [219] main::check_status_cx16_rom2_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboaa=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [220] main::check_status_cx16_rom2_check_status_rom1_return#0 = (char)main::check_status_cx16_rom2_check_status_rom1_$0 -- vbuxx=vbuaa 
    tax
    // main::@50
    // if(check_status_smc(STATUS_FLASH) && !check_status_cx16_rom(STATUS_FLASH))
    // [221] if(0==main::check_status_smc3_return#0) goto main::check_status_smc4 -- 0_eq_vbuyy_then_la1 
    cpy #0
    beq check_status_smc4
    // main::@155
    // [222] if(0==main::check_status_cx16_rom2_check_status_rom1_return#0) goto main::@2 -- 0_eq_vbuxx_then_la1 
    cpx #0
    bne !__b2+
    jmp __b2
  !__b2:
    // main::check_status_smc4
  check_status_smc4:
    // status_smc == status
    // [223] main::check_status_smc4_$0 = status_smc#0 == STATUS_ISSUE -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [224] main::check_status_smc4_return#0 = (char)main::check_status_smc4_$0 -- vbuz1=vbuaa 
    sta.z check_status_smc4_return
    // main::check_status_vera1
    // status_vera == status
    // [225] main::check_status_vera1_$0 = status_vera#0 == STATUS_ISSUE -- vboaa=vbum1_eq_vbuc1 
    lda status_vera
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_vera == status);
    // [226] main::check_status_vera1_return#0 = (char)main::check_status_vera1_$0 -- vbuz1=vbuaa 
    sta.z check_status_vera1_return
    // [227] phi from main::check_status_vera1 to main::check_status_roms_all1 [phi:main::check_status_vera1->main::check_status_roms_all1]
    // main::check_status_roms_all1
    // [228] phi from main::check_status_roms_all1 to main::check_status_roms_all1_@1 [phi:main::check_status_roms_all1->main::check_status_roms_all1_@1]
    // [228] phi main::check_status_roms_all1_rom_chip#2 = 0 [phi:main::check_status_roms_all1->main::check_status_roms_all1_@1#0] -- vbuxx=vbuc1 
    ldx #0
    // main::check_status_roms_all1_@1
  check_status_roms_all1___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [229] if(main::check_status_roms_all1_rom_chip#2<8) goto main::check_status_roms_all1_check_status_rom1 -- vbuxx_lt_vbuc1_then_la1 
    cpx #8
    bcs !check_status_roms_all1_check_status_rom1+
    jmp check_status_roms_all1_check_status_rom1
  !check_status_roms_all1_check_status_rom1:
    // [230] phi from main::check_status_roms_all1_@1 to main::check_status_roms_all1_@return [phi:main::check_status_roms_all1_@1->main::check_status_roms_all1_@return]
    // [230] phi main::check_status_roms_all1_return#2 = 1 [phi:main::check_status_roms_all1_@1->main::check_status_roms_all1_@return#0] -- vbuz1=vbuc1 
    lda #1
    sta.z check_status_roms_all1_return
    // main::check_status_roms_all1_@return
    // main::check_status_smc5
  check_status_smc5:
    // status_smc == status
    // [231] main::check_status_smc5_$0 = status_smc#0 == STATUS_ERROR -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [232] main::check_status_smc5_return#0 = (char)main::check_status_smc5_$0 -- vbuz1=vbuaa 
    sta.z check_status_smc5_return
    // main::check_status_vera2
    // status_vera == status
    // [233] main::check_status_vera2_$0 = status_vera#0 == STATUS_ERROR -- vboaa=vbum1_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_vera == status);
    // [234] main::check_status_vera2_return#0 = (char)main::check_status_vera2_$0 -- vbuyy=vbuaa 
    tay
    // [235] phi from main::check_status_vera2 to main::check_status_roms_all2 [phi:main::check_status_vera2->main::check_status_roms_all2]
    // main::check_status_roms_all2
    // [236] phi from main::check_status_roms_all2 to main::check_status_roms_all2_@1 [phi:main::check_status_roms_all2->main::check_status_roms_all2_@1]
    // [236] phi main::check_status_roms_all2_rom_chip#2 = 0 [phi:main::check_status_roms_all2->main::check_status_roms_all2_@1#0] -- vbuxx=vbuc1 
    ldx #0
    // main::check_status_roms_all2_@1
  check_status_roms_all2___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [237] if(main::check_status_roms_all2_rom_chip#2<8) goto main::check_status_roms_all2_check_status_rom1 -- vbuxx_lt_vbuc1_then_la1 
    cpx #8
    bcs !check_status_roms_all2_check_status_rom1+
    jmp check_status_roms_all2_check_status_rom1
  !check_status_roms_all2_check_status_rom1:
    // [238] phi from main::check_status_roms_all2_@1 to main::check_status_roms_all2_@return [phi:main::check_status_roms_all2_@1->main::check_status_roms_all2_@return]
    // [238] phi main::check_status_roms_all2_return#2 = 1 [phi:main::check_status_roms_all2_@1->main::check_status_roms_all2_@return#0] -- vbuxx=vbuc1 
    ldx #1
    // main::check_status_roms_all2_@return
    // main::@51
  __b51:
    // if(!check_status_smc(STATUS_ISSUE) && !check_status_vera(STATUS_ISSUE) && !check_status_roms_all(STATUS_ISSUE) &&
    //        !check_status_smc(STATUS_ERROR) && !check_status_vera(STATUS_ERROR) && !check_status_roms_all(STATUS_ERROR))
    // [239] if(0!=main::check_status_smc4_return#0) goto main::check_status_smc6 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc4_return
    bne check_status_smc6
    // main::@160
    // [240] if(0==main::check_status_vera1_return#0) goto main::@159 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_vera1_return
    bne !__b159+
    jmp __b159
  !__b159:
    // main::check_status_smc6
  check_status_smc6:
    // status_smc == status
    // [241] main::check_status_smc6_$0 = status_smc#0 == STATUS_SKIP -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [242] main::check_status_smc6_return#0 = (char)main::check_status_smc6_$0 -- vbuz1=vbuaa 
    sta.z check_status_smc6_return
    // main::check_status_vera3
    // status_vera == status
    // [243] main::check_status_vera3_$0 = status_vera#0 == STATUS_SKIP -- vboaa=vbum1_eq_vbuc1 
    lda status_vera
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_vera == status);
    // [244] main::check_status_vera3_return#0 = (char)main::check_status_vera3_$0 -- vbuyy=vbuaa 
    tay
    // [245] phi from main::check_status_vera3 to main::check_status_roms_all3 [phi:main::check_status_vera3->main::check_status_roms_all3]
    // main::check_status_roms_all3
    // [246] phi from main::check_status_roms_all3 to main::check_status_roms_all3_@1 [phi:main::check_status_roms_all3->main::check_status_roms_all3_@1]
    // [246] phi main::check_status_roms_all3_rom_chip#2 = 0 [phi:main::check_status_roms_all3->main::check_status_roms_all3_@1#0] -- vbuxx=vbuc1 
    ldx #0
    // main::check_status_roms_all3_@1
  check_status_roms_all3___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [247] if(main::check_status_roms_all3_rom_chip#2<8) goto main::check_status_roms_all3_check_status_rom1 -- vbuxx_lt_vbuc1_then_la1 
    cpx #8
    bcs !check_status_roms_all3_check_status_rom1+
    jmp check_status_roms_all3_check_status_rom1
  !check_status_roms_all3_check_status_rom1:
    // [248] phi from main::check_status_roms_all3_@1 to main::check_status_roms_all3_@return [phi:main::check_status_roms_all3_@1->main::check_status_roms_all3_@return]
    // [248] phi main::check_status_roms_all3_return#2 = 1 [phi:main::check_status_roms_all3_@1->main::check_status_roms_all3_@return#0] -- vbuxx=vbuc1 
    ldx #1
    // main::check_status_roms_all3_@return
    // main::@52
  __b52:
    // if(check_status_smc(STATUS_SKIP) && check_status_vera(STATUS_SKIP) && check_status_roms_all(STATUS_SKIP))
    // [249] if(0==main::check_status_smc6_return#0) goto main::check_status_smc9 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_smc6_return
    beq check_status_smc9
    // main::@162
    // [250] if(0==main::check_status_vera3_return#0) goto main::check_status_smc9 -- 0_eq_vbuyy_then_la1 
    cpy #0
    beq check_status_smc9
    // main::@161
    // [251] if(0!=main::check_status_roms_all3_return#2) goto main::vera_display_set_border_color1 -- 0_neq_vbuxx_then_la1 
    cpx #0
    beq !vera_display_set_border_color1+
    jmp vera_display_set_border_color1
  !vera_display_set_border_color1:
    // main::check_status_smc9
  check_status_smc9:
    // status_smc == status
    // [252] main::check_status_smc9_$0 = status_smc#0 == STATUS_ERROR -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [253] main::check_status_smc9_return#0 = (char)main::check_status_smc9_$0 -- vbuz1=vbuaa 
    sta.z check_status_smc9_return
    // main::check_status_vera4
    // status_vera == status
    // [254] main::check_status_vera4_$0 = status_vera#0 == STATUS_ERROR -- vboaa=vbum1_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_vera == status);
    // [255] main::check_status_vera4_return#0 = (char)main::check_status_vera4_$0 -- vbuyy=vbuaa 
    tay
    // [256] phi from main::check_status_vera4 to main::check_status_roms1 [phi:main::check_status_vera4->main::check_status_roms1]
    // main::check_status_roms1
    // [257] phi from main::check_status_roms1 to main::check_status_roms1_@1 [phi:main::check_status_roms1->main::check_status_roms1_@1]
    // [257] phi main::check_status_roms1_rom_chip#2 = 0 [phi:main::check_status_roms1->main::check_status_roms1_@1#0] -- vbuxx=vbuc1 
    ldx #0
    // main::check_status_roms1_@1
  check_status_roms1___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [258] if(main::check_status_roms1_rom_chip#2<8) goto main::check_status_roms1_check_status_rom1 -- vbuxx_lt_vbuc1_then_la1 
    cpx #8
    bcs !check_status_roms1_check_status_rom1+
    jmp check_status_roms1_check_status_rom1
  !check_status_roms1_check_status_rom1:
    // [259] phi from main::check_status_roms1_@1 to main::check_status_roms1_@return [phi:main::check_status_roms1_@1->main::check_status_roms1_@return]
    // [259] phi main::check_status_roms1_return#2 = STATUS_NONE [phi:main::check_status_roms1_@1->main::check_status_roms1_@return#0] -- vbuxx=vbuc1 
    ldx #STATUS_NONE
    // main::check_status_roms1_@return
    // main::@56
  __b56:
    // if(check_status_smc(STATUS_ERROR) || check_status_vera(STATUS_ERROR) || check_status_roms(STATUS_ERROR))
    // [260] if(0!=main::check_status_smc9_return#0) goto main::vera_display_set_border_color2 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc9_return
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::@167
    // [261] if(0!=main::check_status_vera4_return#0) goto main::vera_display_set_border_color2 -- 0_neq_vbuyy_then_la1 
    cpy #0
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::@166
    // [262] if(0!=main::check_status_roms1_return#2) goto main::vera_display_set_border_color2 -- 0_neq_vbuxx_then_la1 
    cpx #0
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::check_status_smc10
    // status_smc == status
    // [263] main::check_status_smc10_$0 = status_smc#0 == STATUS_ISSUE -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [264] main::check_status_smc10_return#0 = (char)main::check_status_smc10_$0 -- vbuz1=vbuaa 
    sta.z check_status_smc10_return
    // main::check_status_vera5
    // status_vera == status
    // [265] main::check_status_vera5_$0 = status_vera#0 == STATUS_ISSUE -- vboaa=vbum1_eq_vbuc1 
    lda status_vera
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_vera == status);
    // [266] main::check_status_vera5_return#0 = (char)main::check_status_vera5_$0 -- vbuyy=vbuaa 
    tay
    // [267] phi from main::check_status_vera5 to main::check_status_roms2 [phi:main::check_status_vera5->main::check_status_roms2]
    // main::check_status_roms2
    // [268] phi from main::check_status_roms2 to main::check_status_roms2_@1 [phi:main::check_status_roms2->main::check_status_roms2_@1]
    // [268] phi main::check_status_roms2_rom_chip#2 = 0 [phi:main::check_status_roms2->main::check_status_roms2_@1#0] -- vbuxx=vbuc1 
    ldx #0
    // main::check_status_roms2_@1
  check_status_roms2___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [269] if(main::check_status_roms2_rom_chip#2<8) goto main::check_status_roms2_check_status_rom1 -- vbuxx_lt_vbuc1_then_la1 
    cpx #8
    bcs !check_status_roms2_check_status_rom1+
    jmp check_status_roms2_check_status_rom1
  !check_status_roms2_check_status_rom1:
    // [270] phi from main::check_status_roms2_@1 to main::check_status_roms2_@return [phi:main::check_status_roms2_@1->main::check_status_roms2_@return]
    // [270] phi main::check_status_roms2_return#2 = STATUS_NONE [phi:main::check_status_roms2_@1->main::check_status_roms2_@return#0] -- vbuxx=vbuc1 
    ldx #STATUS_NONE
    // main::check_status_roms2_@return
    // main::@58
  __b58:
    // if(check_status_smc(STATUS_ISSUE) || check_status_vera(STATUS_ISSUE) || check_status_roms(STATUS_ISSUE))
    // [271] if(0!=main::check_status_smc10_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc10_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::@169
    // [272] if(0!=main::check_status_vera5_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbuyy_then_la1 
    cpy #0
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::@168
    // [273] if(0!=main::check_status_roms2_return#2) goto main::vera_display_set_border_color3 -- 0_neq_vbuxx_then_la1 
    cpx #0
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::vera_display_set_border_color4
    // *VERA_CTRL &= ~VERA_DCSEL
    // [274] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [275] *VERA_DC_BORDER = GREEN -- _deref_pbuc1=vbuc2 
    lda #GREEN
    sta VERA_DC_BORDER
    // [276] phi from main::vera_display_set_border_color4 to main::@60 [phi:main::vera_display_set_border_color4->main::@60]
    // main::@60
    // display_action_progress("Your CX16 update is a success!")
    // [277] call display_action_progress
    // [684] phi from main::@60 to display_action_progress [phi:main::@60->display_action_progress]
    // [684] phi display_action_progress::info_text#10 = main::info_text21 [phi:main::@60->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text21
    sta.z display_action_progress.info_text
    lda #>info_text21
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::check_status_smc11
    // status_smc == status
    // [278] main::check_status_smc11_$0 = status_smc#0 == STATUS_FLASHED -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASHED
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [279] main::check_status_smc11_return#0 = (char)main::check_status_smc11_$0
    // main::@61
    // if(check_status_smc(STATUS_FLASHED))
    // [280] if(0!=main::check_status_smc11_return#0) goto main::@33 -- 0_neq_vbuaa_then_la1 
    cmp #0
    bne __b33
    // [281] phi from main::@61 to main::@5 [phi:main::@61->main::@5]
    // main::@5
    // display_progress_text(display_debriefing_text_rom, display_debriefing_count_rom)
    // [282] call display_progress_text
    // [798] phi from main::@5 to display_progress_text [phi:main::@5->display_progress_text]
    // [798] phi display_progress_text::text#10 = display_debriefing_text_rom [phi:main::@5->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_debriefing_text_rom
    sta.z display_progress_text.text
    lda #>display_debriefing_text_rom
    sta.z display_progress_text.text+1
    // [798] phi display_progress_text::lines#11 = display_debriefing_count_rom [phi:main::@5->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_debriefing_count_rom
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [283] phi from main::@147 main::@5 main::@55 main::@59 to main::@38 [phi:main::@147/main::@5/main::@55/main::@59->main::@38]
  __b5:
    // [283] phi main::w1#2 = $c8 [phi:main::@147/main::@5/main::@55/main::@59->main::@38#0] -- vbuz1=vbuc1 
    lda #$c8
    sta.z w1
    // main::@38
  __b38:
    // for (unsigned char w=200; w>0; w--)
    // [284] if(main::w1#2>0) goto main::@39 -- vbuz1_gt_0_then_la1 
    lda.z w1
    bne __b39
    // [285] phi from main::@38 to main::@40 [phi:main::@38->main::@40]
    // main::@40
    // system_reset()
    // [286] call system_reset
    // [1018] phi from main::@40 to system_reset [phi:main::@40->system_reset]
    jsr system_reset
    // main::@return
    // }
    // [287] return 
    rts
    // [288] phi from main::@38 to main::@39 [phi:main::@38->main::@39]
    // main::@39
  __b39:
    // wait_moment()
    // [289] call wait_moment
    // [1023] phi from main::@39 to wait_moment [phi:main::@39->wait_moment]
    jsr wait_moment
    // [290] phi from main::@39 to main::@148 [phi:main::@39->main::@148]
    // main::@148
    // sprintf(info_text, "(%u) Your CX16 will reset ...", w)
    // [291] call snprintf_init
    // [845] phi from main::@148 to snprintf_init [phi:main::@148->snprintf_init]
    // [845] phi snprintf_init::s#15 = info_text [phi:main::@148->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [292] phi from main::@148 to main::@149 [phi:main::@148->main::@149]
    // main::@149
    // sprintf(info_text, "(%u) Your CX16 will reset ...", w)
    // [293] call printf_str
    // [850] phi from main::@149 to printf_str [phi:main::@149->printf_str]
    // [850] phi printf_str::putc#48 = &snputc [phi:main::@149->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = main::s13 [phi:main::@149->printf_str#1] -- pbuz1=pbuc1 
    lda #<s13
    sta.z printf_str.s
    lda #>s13
    sta.z printf_str.s+1
    jsr printf_str
    // main::@150
    // sprintf(info_text, "(%u) Your CX16 will reset ...", w)
    // [294] printf_uchar::uvalue#8 = main::w1#2 -- vbuxx=vbuz1 
    ldx.z w1
    // [295] call printf_uchar
    // [1028] phi from main::@150 to printf_uchar [phi:main::@150->printf_uchar]
    // [1028] phi printf_uchar::format_zero_padding#10 = 0 [phi:main::@150->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1028] phi printf_uchar::format_min_length#10 = 0 [phi:main::@150->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1028] phi printf_uchar::putc#10 = &snputc [phi:main::@150->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1028] phi printf_uchar::format_radix#10 = DECIMAL [phi:main::@150->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [1028] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#8 [phi:main::@150->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [296] phi from main::@150 to main::@151 [phi:main::@150->main::@151]
    // main::@151
    // sprintf(info_text, "(%u) Your CX16 will reset ...", w)
    // [297] call printf_str
    // [850] phi from main::@151 to printf_str [phi:main::@151->printf_str]
    // [850] phi printf_str::putc#48 = &snputc [phi:main::@151->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = main::s17 [phi:main::@151->printf_str#1] -- pbuz1=pbuc1 
    lda #<s17
    sta.z printf_str.s
    lda #>s17
    sta.z printf_str.s+1
    jsr printf_str
    // main::@152
    // sprintf(info_text, "(%u) Your CX16 will reset ...", w)
    // [298] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [299] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [301] call display_action_text
    // [1039] phi from main::@152 to display_action_text [phi:main::@152->display_action_text]
    // [1039] phi display_action_text::info_text#10 = info_text [phi:main::@152->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@153
    // for (unsigned char w=200; w>0; w--)
    // [302] main::w1#1 = -- main::w1#2 -- vbuz1=_dec_vbuz1 
    dec.z w1
    // [283] phi from main::@153 to main::@38 [phi:main::@153->main::@38]
    // [283] phi main::w1#2 = main::w1#1 [phi:main::@153->main::@38#0] -- register_copy 
    jmp __b38
    // [303] phi from main::@61 to main::@33 [phi:main::@61->main::@33]
    // main::@33
  __b33:
    // display_progress_text(display_debriefing_text_smc, display_debriefing_count_smc)
    // [304] call display_progress_text
    // [798] phi from main::@33 to display_progress_text [phi:main::@33->display_progress_text]
    // [798] phi display_progress_text::text#10 = display_debriefing_text_smc [phi:main::@33->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_debriefing_text_smc
    sta.z display_progress_text.text
    lda #>display_debriefing_text_smc
    sta.z display_progress_text.text+1
    // [798] phi display_progress_text::lines#11 = display_debriefing_count_smc [phi:main::@33->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_debriefing_count_smc
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [305] phi from main::@33 to main::@34 [phi:main::@33->main::@34]
    // [305] phi main::w#2 = $f0 [phi:main::@33->main::@34#0] -- vbuz1=vbuc1 
    lda #$f0
    sta.z w
    // main::@34
  __b34:
    // for (unsigned char w=240; w>0; w--)
    // [306] if(main::w#2>0) goto main::@35 -- vbuz1_gt_0_then_la1 
    lda.z w
    bne __b35
    // [307] phi from main::@34 to main::@36 [phi:main::@34->main::@36]
    // main::@36
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [308] call snprintf_init
    // [845] phi from main::@36 to snprintf_init [phi:main::@36->snprintf_init]
    // [845] phi snprintf_init::s#15 = info_text [phi:main::@36->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [309] phi from main::@36 to main::@145 [phi:main::@36->main::@145]
    // main::@145
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [310] call printf_str
    // [850] phi from main::@145 to printf_str [phi:main::@145->printf_str]
    // [850] phi printf_str::putc#48 = &snputc [phi:main::@145->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = main::s15 [phi:main::@145->printf_str#1] -- pbuz1=pbuc1 
    lda #<s15
    sta.z printf_str.s
    lda #>s15
    sta.z printf_str.s+1
    jsr printf_str
    // main::@146
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [311] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [312] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [314] call display_action_text
    // [1039] phi from main::@146 to display_action_text [phi:main::@146->display_action_text]
    // [1039] phi display_action_text::info_text#10 = info_text [phi:main::@146->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [315] phi from main::@146 to main::@147 [phi:main::@146->main::@147]
    // main::@147
    // smc_reset()
    // [316] call smc_reset
    // [1053] phi from main::@147 to smc_reset [phi:main::@147->smc_reset]
    jsr smc_reset
    jmp __b5
    // [317] phi from main::@34 to main::@35 [phi:main::@34->main::@35]
    // main::@35
  __b35:
    // wait_moment()
    // [318] call wait_moment
    // [1023] phi from main::@35 to wait_moment [phi:main::@35->wait_moment]
    jsr wait_moment
    // [319] phi from main::@35 to main::@139 [phi:main::@35->main::@139]
    // main::@139
    // sprintf(info_text, "(%u) Please read carefully the below ...", w)
    // [320] call snprintf_init
    // [845] phi from main::@139 to snprintf_init [phi:main::@139->snprintf_init]
    // [845] phi snprintf_init::s#15 = info_text [phi:main::@139->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [321] phi from main::@139 to main::@140 [phi:main::@139->main::@140]
    // main::@140
    // sprintf(info_text, "(%u) Please read carefully the below ...", w)
    // [322] call printf_str
    // [850] phi from main::@140 to printf_str [phi:main::@140->printf_str]
    // [850] phi printf_str::putc#48 = &snputc [phi:main::@140->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = main::s13 [phi:main::@140->printf_str#1] -- pbuz1=pbuc1 
    lda #<s13
    sta.z printf_str.s
    lda #>s13
    sta.z printf_str.s+1
    jsr printf_str
    // main::@141
    // sprintf(info_text, "(%u) Please read carefully the below ...", w)
    // [323] printf_uchar::uvalue#7 = main::w#2 -- vbuxx=vbuz1 
    ldx.z w
    // [324] call printf_uchar
    // [1028] phi from main::@141 to printf_uchar [phi:main::@141->printf_uchar]
    // [1028] phi printf_uchar::format_zero_padding#10 = 0 [phi:main::@141->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1028] phi printf_uchar::format_min_length#10 = 0 [phi:main::@141->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1028] phi printf_uchar::putc#10 = &snputc [phi:main::@141->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1028] phi printf_uchar::format_radix#10 = DECIMAL [phi:main::@141->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [1028] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#7 [phi:main::@141->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [325] phi from main::@141 to main::@142 [phi:main::@141->main::@142]
    // main::@142
    // sprintf(info_text, "(%u) Please read carefully the below ...", w)
    // [326] call printf_str
    // [850] phi from main::@142 to printf_str [phi:main::@142->printf_str]
    // [850] phi printf_str::putc#48 = &snputc [phi:main::@142->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = main::s14 [phi:main::@142->printf_str#1] -- pbuz1=pbuc1 
    lda #<s14
    sta.z printf_str.s
    lda #>s14
    sta.z printf_str.s+1
    jsr printf_str
    // main::@143
    // sprintf(info_text, "(%u) Please read carefully the below ...", w)
    // [327] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [328] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [330] call display_action_text
    // [1039] phi from main::@143 to display_action_text [phi:main::@143->display_action_text]
    // [1039] phi display_action_text::info_text#10 = info_text [phi:main::@143->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@144
    // for (unsigned char w=240; w>0; w--)
    // [331] main::w#1 = -- main::w#2 -- vbuz1=_dec_vbuz1 
    dec.z w
    // [305] phi from main::@144 to main::@34 [phi:main::@144->main::@34]
    // [305] phi main::w#2 = main::w#1 [phi:main::@144->main::@34#0] -- register_copy 
    jmp __b34
    // main::vera_display_set_border_color3
  vera_display_set_border_color3:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [332] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [333] *VERA_DC_BORDER = YELLOW -- _deref_pbuc1=vbuc2 
    lda #YELLOW
    sta VERA_DC_BORDER
    // [334] phi from main::vera_display_set_border_color3 to main::@59 [phi:main::vera_display_set_border_color3->main::@59]
    // main::@59
    // display_action_progress("Update issues, your CX16 is not updated!")
    // [335] call display_action_progress
    // [684] phi from main::@59 to display_action_progress [phi:main::@59->display_action_progress]
    // [684] phi display_action_progress::info_text#10 = main::info_text20 [phi:main::@59->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text20
    sta.z display_action_progress.info_text
    lda #>info_text20
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    jmp __b5
    // main::check_status_roms2_check_status_rom1
  check_status_roms2_check_status_rom1:
    // status_rom[rom_chip] == status
    // [336] main::check_status_roms2_check_status_rom1_$0 = status_rom[main::check_status_roms2_rom_chip#2] == STATUS_ISSUE -- vboaa=pbuc1_derefidx_vbuxx_eq_vbuc2 
    lda #STATUS_ISSUE
    eor status_rom,x
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [337] main::check_status_roms2_check_status_rom1_return#0 = (char)main::check_status_roms2_check_status_rom1_$0
    // main::check_status_roms2_@11
    // if(check_status_rom(rom_chip, status))
    // [338] if(0==main::check_status_roms2_check_status_rom1_return#0) goto main::check_status_roms2_@4 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq check_status_roms2___b4
    // [270] phi from main::check_status_roms2_@11 to main::check_status_roms2_@return [phi:main::check_status_roms2_@11->main::check_status_roms2_@return]
    // [270] phi main::check_status_roms2_return#2 = STATUS_ISSUE [phi:main::check_status_roms2_@11->main::check_status_roms2_@return#0] -- vbuxx=vbuc1 
    ldx #STATUS_ISSUE
    jmp __b58
    // main::check_status_roms2_@4
  check_status_roms2___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [339] main::check_status_roms2_rom_chip#1 = ++ main::check_status_roms2_rom_chip#2 -- vbuxx=_inc_vbuxx 
    inx
    // [268] phi from main::check_status_roms2_@4 to main::check_status_roms2_@1 [phi:main::check_status_roms2_@4->main::check_status_roms2_@1]
    // [268] phi main::check_status_roms2_rom_chip#2 = main::check_status_roms2_rom_chip#1 [phi:main::check_status_roms2_@4->main::check_status_roms2_@1#0] -- register_copy 
    jmp check_status_roms2___b1
    // main::vera_display_set_border_color2
  vera_display_set_border_color2:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [340] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [341] *VERA_DC_BORDER = RED -- _deref_pbuc1=vbuc2 
    lda #RED
    sta VERA_DC_BORDER
    // [342] phi from main::vera_display_set_border_color2 to main::@57 [phi:main::vera_display_set_border_color2->main::@57]
    // main::@57
    // display_action_progress("Update Failure! Your CX16 may be bricked!")
    // [343] call display_action_progress
    // [684] phi from main::@57 to display_action_progress [phi:main::@57->display_action_progress]
    // [684] phi display_action_progress::info_text#10 = main::info_text18 [phi:main::@57->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text18
    sta.z display_action_progress.info_text
    lda #>info_text18
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [344] phi from main::@57 to main::@138 [phi:main::@57->main::@138]
    // main::@138
    // display_action_text("Take a foto of this screen. And shut down power ...")
    // [345] call display_action_text
    // [1039] phi from main::@138 to display_action_text [phi:main::@138->display_action_text]
    // [1039] phi display_action_text::info_text#10 = main::info_text19 [phi:main::@138->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text19
    sta.z display_action_text.info_text
    lda #>info_text19
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [346] phi from main::@138 main::@37 to main::@37 [phi:main::@138/main::@37->main::@37]
    // main::@37
  __b37:
    jmp __b37
    // main::check_status_roms1_check_status_rom1
  check_status_roms1_check_status_rom1:
    // status_rom[rom_chip] == status
    // [347] main::check_status_roms1_check_status_rom1_$0 = status_rom[main::check_status_roms1_rom_chip#2] == STATUS_ERROR -- vboaa=pbuc1_derefidx_vbuxx_eq_vbuc2 
    lda #STATUS_ERROR
    eor status_rom,x
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [348] main::check_status_roms1_check_status_rom1_return#0 = (char)main::check_status_roms1_check_status_rom1_$0
    // main::check_status_roms1_@11
    // if(check_status_rom(rom_chip, status))
    // [349] if(0==main::check_status_roms1_check_status_rom1_return#0) goto main::check_status_roms1_@4 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq check_status_roms1___b4
    // [259] phi from main::check_status_roms1_@11 to main::check_status_roms1_@return [phi:main::check_status_roms1_@11->main::check_status_roms1_@return]
    // [259] phi main::check_status_roms1_return#2 = STATUS_ERROR [phi:main::check_status_roms1_@11->main::check_status_roms1_@return#0] -- vbuxx=vbuc1 
    ldx #STATUS_ERROR
    jmp __b56
    // main::check_status_roms1_@4
  check_status_roms1___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [350] main::check_status_roms1_rom_chip#1 = ++ main::check_status_roms1_rom_chip#2 -- vbuxx=_inc_vbuxx 
    inx
    // [257] phi from main::check_status_roms1_@4 to main::check_status_roms1_@1 [phi:main::check_status_roms1_@4->main::check_status_roms1_@1]
    // [257] phi main::check_status_roms1_rom_chip#2 = main::check_status_roms1_rom_chip#1 [phi:main::check_status_roms1_@4->main::check_status_roms1_@1#0] -- register_copy 
    jmp check_status_roms1___b1
    // main::vera_display_set_border_color1
  vera_display_set_border_color1:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [351] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [352] *VERA_DC_BORDER = BLACK -- _deref_pbuc1=vbuc2 
    lda #BLACK
    sta VERA_DC_BORDER
    // [353] phi from main::vera_display_set_border_color1 to main::@55 [phi:main::vera_display_set_border_color1->main::@55]
    // main::@55
    // display_action_progress("The update has been cancelled!")
    // [354] call display_action_progress
    // [684] phi from main::@55 to display_action_progress [phi:main::@55->display_action_progress]
    // [684] phi display_action_progress::info_text#10 = main::info_text17 [phi:main::@55->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text17
    sta.z display_action_progress.info_text
    lda #>info_text17
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    jmp __b5
    // main::check_status_roms_all3_check_status_rom1
  check_status_roms_all3_check_status_rom1:
    // status_rom[rom_chip] == status
    // [355] main::check_status_roms_all3_check_status_rom1_$0 = status_rom[main::check_status_roms_all3_rom_chip#2] == STATUS_SKIP -- vboaa=pbuc1_derefidx_vbuxx_eq_vbuc2 
    lda #STATUS_SKIP
    eor status_rom,x
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [356] main::check_status_roms_all3_check_status_rom1_return#0 = (char)main::check_status_roms_all3_check_status_rom1_$0
    // main::check_status_roms_all3_@11
    // if(check_status_rom(rom_chip, status) != status)
    // [357] if(main::check_status_roms_all3_check_status_rom1_return#0==STATUS_SKIP) goto main::check_status_roms_all3_@4 -- vbuaa_eq_vbuc1_then_la1 
    cmp #STATUS_SKIP
    beq check_status_roms_all3___b4
    // [248] phi from main::check_status_roms_all3_@11 to main::check_status_roms_all3_@return [phi:main::check_status_roms_all3_@11->main::check_status_roms_all3_@return]
    // [248] phi main::check_status_roms_all3_return#2 = 0 [phi:main::check_status_roms_all3_@11->main::check_status_roms_all3_@return#0] -- vbuxx=vbuc1 
    ldx #0
    jmp __b52
    // main::check_status_roms_all3_@4
  check_status_roms_all3___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [358] main::check_status_roms_all3_rom_chip#1 = ++ main::check_status_roms_all3_rom_chip#2 -- vbuxx=_inc_vbuxx 
    inx
    // [246] phi from main::check_status_roms_all3_@4 to main::check_status_roms_all3_@1 [phi:main::check_status_roms_all3_@4->main::check_status_roms_all3_@1]
    // [246] phi main::check_status_roms_all3_rom_chip#2 = main::check_status_roms_all3_rom_chip#1 [phi:main::check_status_roms_all3_@4->main::check_status_roms_all3_@1#0] -- register_copy 
    jmp check_status_roms_all3___b1
    // main::@159
  __b159:
    // if(!check_status_smc(STATUS_ISSUE) && !check_status_vera(STATUS_ISSUE) && !check_status_roms_all(STATUS_ISSUE) &&
    //        !check_status_smc(STATUS_ERROR) && !check_status_vera(STATUS_ERROR) && !check_status_roms_all(STATUS_ERROR))
    // [359] if(0!=main::check_status_roms_all1_return#2) goto main::check_status_smc6 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_roms_all1_return
    beq !check_status_smc6+
    jmp check_status_smc6
  !check_status_smc6:
    // main::@158
    // [360] if(0==main::check_status_smc5_return#0) goto main::@157 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_smc5_return
    beq __b157
    jmp check_status_smc6
    // main::@157
  __b157:
    // [361] if(0!=main::check_status_vera2_return#0) goto main::check_status_smc6 -- 0_neq_vbuyy_then_la1 
    cpy #0
    beq !check_status_smc6+
    jmp check_status_smc6
  !check_status_smc6:
    // main::@156
    // [362] if(0==main::check_status_roms_all2_return#2) goto main::check_status_smc7 -- 0_eq_vbuxx_then_la1 
    cpx #0
    beq check_status_smc7
    jmp check_status_smc6
    // main::check_status_smc7
  check_status_smc7:
    // status_smc == status
    // [363] main::check_status_smc7_$0 = status_smc#0 == STATUS_FLASH -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [364] main::check_status_smc7_return#0 = (char)main::check_status_smc7_$0 -- vbuz1=vbuaa 
    sta.z check_status_smc7_return
    // [365] phi from main::check_status_smc7 to main::check_status_cx16_rom3 [phi:main::check_status_smc7->main::check_status_cx16_rom3]
    // main::check_status_cx16_rom3
    // main::check_status_cx16_rom3_check_status_rom1
    // status_rom[rom_chip] == status
    // [366] main::check_status_cx16_rom3_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboaa=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [367] main::check_status_cx16_rom3_check_status_rom1_return#0 = (char)main::check_status_cx16_rom3_check_status_rom1_$0 -- vbuyy=vbuaa 
    tay
    // [368] phi from main::check_status_cx16_rom3_check_status_rom1 to main::check_status_card_roms1 [phi:main::check_status_cx16_rom3_check_status_rom1->main::check_status_card_roms1]
    // main::check_status_card_roms1
    // [369] phi from main::check_status_card_roms1 to main::check_status_card_roms1_@1 [phi:main::check_status_card_roms1->main::check_status_card_roms1_@1]
    // [369] phi main::check_status_card_roms1_rom_chip#2 = 1 [phi:main::check_status_card_roms1->main::check_status_card_roms1_@1#0] -- vbuxx=vbuc1 
    ldx #1
    // main::check_status_card_roms1_@1
  check_status_card_roms1___b1:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [370] if(main::check_status_card_roms1_rom_chip#2<8) goto main::check_status_card_roms1_check_status_rom1 -- vbuxx_lt_vbuc1_then_la1 
    cpx #8
    bcs !check_status_card_roms1_check_status_rom1+
    jmp check_status_card_roms1_check_status_rom1
  !check_status_card_roms1_check_status_rom1:
    // [371] phi from main::check_status_card_roms1_@1 to main::check_status_card_roms1_@return [phi:main::check_status_card_roms1_@1->main::check_status_card_roms1_@return]
    // [371] phi main::check_status_card_roms1_return#2 = STATUS_NONE [phi:main::check_status_card_roms1_@1->main::check_status_card_roms1_@return#0] -- vbuxx=vbuc1 
    ldx #STATUS_NONE
    // main::check_status_card_roms1_@return
    // main::@53
  __b53:
    // if(check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH) || check_status_card_roms(STATUS_FLASH))
    // [372] if(0==main::check_status_smc7_return#0) goto main::@163 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_smc7_return
    beq __b163
    // main::@164
    // [373] if(0!=main::check_status_cx16_rom3_check_status_rom1_return#0) goto main::@3 -- 0_neq_vbuyy_then_la1 
    cpy #0
    bne __b3
    // main::@163
  __b163:
    // [374] if(0!=main::check_status_card_roms1_return#2) goto main::@3 -- 0_neq_vbuxx_then_la1 
    cpx #0
    bne __b3
    // main::bank_set_bram2
  bank_set_bram2:
    // BRAM = bank
    // [375] BRAM = main::bank_set_bram2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram2_bank
    sta.z BRAM
    // main::SEI5
    // asm
    // asm { sei  }
    sei
    // main::check_status_smc8
    // status_smc == status
    // [377] main::check_status_smc8_$0 = status_smc#0 == STATUS_FLASH -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [378] main::check_status_smc8_return#0 = (char)main::check_status_smc8_$0 -- vbuyy=vbuaa 
    tay
    // [379] phi from main::check_status_smc8 to main::check_status_cx16_rom4 [phi:main::check_status_smc8->main::check_status_cx16_rom4]
    // main::check_status_cx16_rom4
    // main::check_status_cx16_rom4_check_status_rom1
    // status_rom[rom_chip] == status
    // [380] main::check_status_cx16_rom4_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboaa=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [381] main::check_status_cx16_rom4_check_status_rom1_return#0 = (char)main::check_status_cx16_rom4_check_status_rom1_$0 -- vbuxx=vbuaa 
    tax
    // main::@54
    // if (check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH))
    // [382] if(0==main::check_status_smc8_return#0) goto main::check_status_smc6 -- 0_eq_vbuyy_then_la1 
    cpy #0
    bne !check_status_smc6+
    jmp check_status_smc6
  !check_status_smc6:
    // main::@165
    // [383] if(0!=main::check_status_cx16_rom4_check_status_rom1_return#0) goto main::@32 -- 0_neq_vbuxx_then_la1 
    cpx #0
    bne __b32
    jmp check_status_smc6
    // [384] phi from main::@165 to main::@32 [phi:main::@165->main::@32]
    // main::@32
  __b32:
    // display_progress_clear()
    // [385] call display_progress_clear
    // [698] phi from main::@32 to display_progress_clear [phi:main::@32->display_progress_clear]
    jsr display_progress_clear
    jmp check_status_smc6
    // [386] phi from main::@163 main::@164 to main::@3 [phi:main::@163/main::@164->main::@3]
    // main::@3
  __b3:
    // display_action_progress("Chipsets have been detected and update files validated!")
    // [387] call display_action_progress
    // [684] phi from main::@3 to display_action_progress [phi:main::@3->display_action_progress]
    // [684] phi display_action_progress::info_text#10 = main::info_text11 [phi:main::@3->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text11
    sta.z display_action_progress.info_text
    lda #>info_text11
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [388] phi from main::@3 to main::@133 [phi:main::@3->main::@133]
    // main::@133
    // unsigned char ch = util_wait_key("Continue with update of highlighted chipsets? [Y/N]", "nyNY")
    // [389] call util_wait_key
    // [1062] phi from main::@133 to util_wait_key [phi:main::@133->util_wait_key]
    // [1062] phi util_wait_key::filter#12 = main::filter [phi:main::@133->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter
    sta.z util_wait_key.filter
    lda #>filter
    sta.z util_wait_key.filter+1
    // [1062] phi util_wait_key::info_text#2 = main::info_text12 [phi:main::@133->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text12
    sta.z util_wait_key.info_text
    lda #>info_text12
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("Continue with update of highlighted chipsets? [Y/N]", "nyNY")
    // [390] util_wait_key::return#3 = util_wait_key::ch#4 -- vbuaa=vwuz1 
    lda.z util_wait_key.ch
    // main::@134
    // [391] main::ch#0 = util_wait_key::return#3
    // strchr("nN", ch)
    // [392] strchr::c#1 = main::ch#0 -- vbuz1=vbuaa 
    sta.z strchr.c
    // [393] call strchr
    // [1086] phi from main::@134 to strchr [phi:main::@134->strchr]
    // [1086] phi strchr::c#4 = strchr::c#1 [phi:main::@134->strchr#0] -- register_copy 
    // [1086] phi strchr::str#2 = (const void *)main::$224 [phi:main::@134->strchr#1] -- pvoz1=pvoc1 
    lda #<main__224
    sta.z strchr.str
    lda #>main__224
    sta.z strchr.str+1
    jsr strchr
    // strchr("nN", ch)
    // [394] strchr::return#4 = strchr::return#2
    // main::@135
    // [395] main::$159 = strchr::return#4
    // if(strchr("nN", ch))
    // [396] if((void *)0==main::$159) goto main::bank_set_bram2 -- pvoc1_eq_pvoz1_then_la1 
    lda.z main__159
    cmp #<0
    bne !+
    lda.z main__159+1
    cmp #>0
    beq bank_set_bram2
  !:
    // [397] phi from main::@135 to main::@4 [phi:main::@135->main::@4]
    // main::@4
    // display_info_smc(STATUS_SKIP, "Cancelled")
    // [398] call display_info_smc
  // We cancel all updates, the updates are skipped.
    // [742] phi from main::@4 to display_info_smc [phi:main::@4->display_info_smc]
    // [742] phi display_info_smc::info_text#11 = main::info_text13 [phi:main::@4->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text13
    sta.z display_info_smc.info_text
    lda #>info_text13
    sta.z display_info_smc.info_text+1
    // [742] phi display_info_smc::info_status#11 = STATUS_SKIP [phi:main::@4->display_info_smc#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [399] phi from main::@4 to main::@136 [phi:main::@4->main::@136]
    // main::@136
    // display_info_vera(STATUS_SKIP, "Cancelled")
    // [400] call display_info_vera
    // [772] phi from main::@136 to display_info_vera [phi:main::@136->display_info_vera]
    // [772] phi display_info_vera::info_text#10 = main::info_text13 [phi:main::@136->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text13
    sta.z display_info_vera.info_text
    lda #>info_text13
    sta.z display_info_vera.info_text+1
    // [772] phi display_info_vera::info_status#3 = STATUS_SKIP [phi:main::@136->display_info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_vera.info_status
    jsr display_info_vera
    // [401] phi from main::@136 to main::@29 [phi:main::@136->main::@29]
    // [401] phi main::rom_chip3#2 = 0 [phi:main::@136->main::@29#0] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_chip3
    // main::@29
  __b29:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [402] if(main::rom_chip3#2<8) goto main::@30 -- vbuz1_lt_vbuc1_then_la1 
    lda.z rom_chip3
    cmp #8
    bcc __b30
    // [403] phi from main::@29 to main::@31 [phi:main::@29->main::@31]
    // main::@31
    // display_action_text("You have selected not to cancel the update ... ")
    // [404] call display_action_text
    // [1039] phi from main::@31 to display_action_text [phi:main::@31->display_action_text]
    // [1039] phi display_action_text::info_text#10 = main::info_text16 [phi:main::@31->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text16
    sta.z display_action_text.info_text
    lda #>info_text16
    sta.z display_action_text.info_text+1
    jsr display_action_text
    jmp bank_set_bram2
    // main::@30
  __b30:
    // display_info_rom(rom_chip, STATUS_SKIP, "Cancelled")
    // [405] display_info_rom::rom_chip#6 = main::rom_chip3#2 -- vbuz1=vbuz2 
    lda.z rom_chip3
    sta.z display_info_rom.rom_chip
    // [406] call display_info_rom
    // [1095] phi from main::@30 to display_info_rom [phi:main::@30->display_info_rom]
    // [1095] phi display_info_rom::info_text#10 = main::info_text13 [phi:main::@30->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text13
    sta.z display_info_rom.info_text
    lda #>info_text13
    sta.z display_info_rom.info_text+1
    // [1095] phi display_info_rom::rom_chip#10 = display_info_rom::rom_chip#6 [phi:main::@30->display_info_rom#1] -- register_copy 
    // [1095] phi display_info_rom::info_status#10 = STATUS_SKIP [phi:main::@30->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // main::@137
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [407] main::rom_chip3#1 = ++ main::rom_chip3#2 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip3
    // [401] phi from main::@137 to main::@29 [phi:main::@137->main::@29]
    // [401] phi main::rom_chip3#2 = main::rom_chip3#1 [phi:main::@137->main::@29#0] -- register_copy 
    jmp __b29
    // main::check_status_card_roms1_check_status_rom1
  check_status_card_roms1_check_status_rom1:
    // status_rom[rom_chip] == status
    // [408] main::check_status_card_roms1_check_status_rom1_$0 = status_rom[main::check_status_card_roms1_rom_chip#2] == STATUS_FLASH -- vboaa=pbuc1_derefidx_vbuxx_eq_vbuc2 
    lda #STATUS_FLASH
    eor status_rom,x
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [409] main::check_status_card_roms1_check_status_rom1_return#0 = (char)main::check_status_card_roms1_check_status_rom1_$0
    // main::check_status_card_roms1_@11
    // if(check_status_rom(rom_chip, status))
    // [410] if(0==main::check_status_card_roms1_check_status_rom1_return#0) goto main::check_status_card_roms1_@4 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq check_status_card_roms1___b4
    // [371] phi from main::check_status_card_roms1_@11 to main::check_status_card_roms1_@return [phi:main::check_status_card_roms1_@11->main::check_status_card_roms1_@return]
    // [371] phi main::check_status_card_roms1_return#2 = STATUS_FLASH [phi:main::check_status_card_roms1_@11->main::check_status_card_roms1_@return#0] -- vbuxx=vbuc1 
    ldx #STATUS_FLASH
    jmp __b53
    // main::check_status_card_roms1_@4
  check_status_card_roms1___b4:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [411] main::check_status_card_roms1_rom_chip#1 = ++ main::check_status_card_roms1_rom_chip#2 -- vbuxx=_inc_vbuxx 
    inx
    // [369] phi from main::check_status_card_roms1_@4 to main::check_status_card_roms1_@1 [phi:main::check_status_card_roms1_@4->main::check_status_card_roms1_@1]
    // [369] phi main::check_status_card_roms1_rom_chip#2 = main::check_status_card_roms1_rom_chip#1 [phi:main::check_status_card_roms1_@4->main::check_status_card_roms1_@1#0] -- register_copy 
    jmp check_status_card_roms1___b1
    // main::check_status_roms_all2_check_status_rom1
  check_status_roms_all2_check_status_rom1:
    // status_rom[rom_chip] == status
    // [412] main::check_status_roms_all2_check_status_rom1_$0 = status_rom[main::check_status_roms_all2_rom_chip#2] == STATUS_ERROR -- vboaa=pbuc1_derefidx_vbuxx_eq_vbuc2 
    lda #STATUS_ERROR
    eor status_rom,x
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [413] main::check_status_roms_all2_check_status_rom1_return#0 = (char)main::check_status_roms_all2_check_status_rom1_$0
    // main::check_status_roms_all2_@11
    // if(check_status_rom(rom_chip, status) != status)
    // [414] if(main::check_status_roms_all2_check_status_rom1_return#0==STATUS_ERROR) goto main::check_status_roms_all2_@4 -- vbuaa_eq_vbuc1_then_la1 
    cmp #STATUS_ERROR
    beq check_status_roms_all2___b4
    // [238] phi from main::check_status_roms_all2_@11 to main::check_status_roms_all2_@return [phi:main::check_status_roms_all2_@11->main::check_status_roms_all2_@return]
    // [238] phi main::check_status_roms_all2_return#2 = 0 [phi:main::check_status_roms_all2_@11->main::check_status_roms_all2_@return#0] -- vbuxx=vbuc1 
    ldx #0
    jmp __b51
    // main::check_status_roms_all2_@4
  check_status_roms_all2___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [415] main::check_status_roms_all2_rom_chip#1 = ++ main::check_status_roms_all2_rom_chip#2 -- vbuxx=_inc_vbuxx 
    inx
    // [236] phi from main::check_status_roms_all2_@4 to main::check_status_roms_all2_@1 [phi:main::check_status_roms_all2_@4->main::check_status_roms_all2_@1]
    // [236] phi main::check_status_roms_all2_rom_chip#2 = main::check_status_roms_all2_rom_chip#1 [phi:main::check_status_roms_all2_@4->main::check_status_roms_all2_@1#0] -- register_copy 
    jmp check_status_roms_all2___b1
    // main::check_status_roms_all1_check_status_rom1
  check_status_roms_all1_check_status_rom1:
    // status_rom[rom_chip] == status
    // [416] main::check_status_roms_all1_check_status_rom1_$0 = status_rom[main::check_status_roms_all1_rom_chip#2] == STATUS_ISSUE -- vboaa=pbuc1_derefidx_vbuxx_eq_vbuc2 
    lda #STATUS_ISSUE
    eor status_rom,x
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [417] main::check_status_roms_all1_check_status_rom1_return#0 = (char)main::check_status_roms_all1_check_status_rom1_$0
    // main::check_status_roms_all1_@11
    // if(check_status_rom(rom_chip, status) != status)
    // [418] if(main::check_status_roms_all1_check_status_rom1_return#0==STATUS_ISSUE) goto main::check_status_roms_all1_@4 -- vbuaa_eq_vbuc1_then_la1 
    cmp #STATUS_ISSUE
    beq check_status_roms_all1___b4
    // [230] phi from main::check_status_roms_all1_@11 to main::check_status_roms_all1_@return [phi:main::check_status_roms_all1_@11->main::check_status_roms_all1_@return]
    // [230] phi main::check_status_roms_all1_return#2 = 0 [phi:main::check_status_roms_all1_@11->main::check_status_roms_all1_@return#0] -- vbuz1=vbuc1 
    lda #0
    sta.z check_status_roms_all1_return
    jmp check_status_smc5
    // main::check_status_roms_all1_@4
  check_status_roms_all1___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [419] main::check_status_roms_all1_rom_chip#1 = ++ main::check_status_roms_all1_rom_chip#2 -- vbuxx=_inc_vbuxx 
    inx
    // [228] phi from main::check_status_roms_all1_@4 to main::check_status_roms_all1_@1 [phi:main::check_status_roms_all1_@4->main::check_status_roms_all1_@1]
    // [228] phi main::check_status_roms_all1_rom_chip#2 = main::check_status_roms_all1_rom_chip#1 [phi:main::check_status_roms_all1_@4->main::check_status_roms_all1_@1#0] -- register_copy 
    jmp check_status_roms_all1___b1
    // [420] phi from main::@155 to main::@2 [phi:main::@155->main::@2]
    // main::@2
  __b2:
    // display_action_progress("Please check the main CX16 ROM update issue!")
    // [421] call display_action_progress
    // [684] phi from main::@2 to display_action_progress [phi:main::@2->display_action_progress]
    // [684] phi display_action_progress::info_text#10 = main::info_text9 [phi:main::@2->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text9
    sta.z display_action_progress.info_text
    lda #>info_text9
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [422] phi from main::@2 to main::@129 [phi:main::@2->main::@129]
    // main::@129
    // display_progress_text(display_smc_rom_issue__text, display_smc_rom_issue_count)
    // [423] call display_progress_text
    // [798] phi from main::@129 to display_progress_text [phi:main::@129->display_progress_text]
    // [798] phi display_progress_text::text#10 = display_smc_rom_issue__text [phi:main::@129->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_rom_issue__text
    sta.z display_progress_text.text
    lda #>display_smc_rom_issue__text
    sta.z display_progress_text.text+1
    // [798] phi display_progress_text::lines#11 = display_smc_rom_issue_count [phi:main::@129->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_smc_rom_issue_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [424] phi from main::@129 to main::@130 [phi:main::@129->main::@130]
    // main::@130
    // display_info_smc(STATUS_SKIP, "Issue with main CX16 ROM!")
    // [425] call display_info_smc
    // [742] phi from main::@130 to display_info_smc [phi:main::@130->display_info_smc]
    // [742] phi display_info_smc::info_text#11 = main::info_text10 [phi:main::@130->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text10
    sta.z display_info_smc.info_text
    lda #>info_text10
    sta.z display_info_smc.info_text+1
    // [742] phi display_info_smc::info_status#11 = STATUS_SKIP [phi:main::@130->display_info_smc#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [426] phi from main::@130 to main::@131 [phi:main::@130->main::@131]
    // main::@131
    // display_info_cx16_rom(STATUS_ISSUE, NULL)
    // [427] call display_info_cx16_rom
    // [1138] phi from main::@131 to display_info_cx16_rom [phi:main::@131->display_info_cx16_rom]
    // [1138] phi display_info_cx16_rom::info_text#2 = 0 [phi:main::@131->display_info_cx16_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_cx16_rom.info_text
    sta.z display_info_cx16_rom.info_text+1
    // [1138] phi display_info_cx16_rom::info_status#2 = STATUS_ISSUE [phi:main::@131->display_info_cx16_rom#1] -- vbuxx=vbuc1 
    ldx #STATUS_ISSUE
    jsr display_info_cx16_rom
    // [428] phi from main::@131 to main::@132 [phi:main::@131->main::@132]
    // main::@132
    // util_wait_space()
    // [429] call util_wait_space
    // [808] phi from main::@132 to util_wait_space [phi:main::@132->util_wait_space]
    jsr util_wait_space
    jmp check_status_smc4
    // [430] phi from main::@154 to main::@28 [phi:main::@154->main::@28]
    // main::@28
  __b28:
    // display_action_progress("Please check the SMC update issue!")
    // [431] call display_action_progress
    // [684] phi from main::@28 to display_action_progress [phi:main::@28->display_action_progress]
    // [684] phi display_action_progress::info_text#10 = main::info_text7 [phi:main::@28->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z display_action_progress.info_text
    lda #>info_text7
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [432] phi from main::@28 to main::@125 [phi:main::@28->main::@125]
    // main::@125
    // display_progress_text(display_smc_rom_issue__text, display_smc_rom_issue_count)
    // [433] call display_progress_text
    // [798] phi from main::@125 to display_progress_text [phi:main::@125->display_progress_text]
    // [798] phi display_progress_text::text#10 = display_smc_rom_issue__text [phi:main::@125->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_rom_issue__text
    sta.z display_progress_text.text
    lda #>display_smc_rom_issue__text
    sta.z display_progress_text.text+1
    // [798] phi display_progress_text::lines#11 = display_smc_rom_issue_count [phi:main::@125->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_smc_rom_issue_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [434] phi from main::@125 to main::@126 [phi:main::@125->main::@126]
    // main::@126
    // display_info_cx16_rom(STATUS_SKIP, "Issue with SMC!")
    // [435] call display_info_cx16_rom
    // [1138] phi from main::@126 to display_info_cx16_rom [phi:main::@126->display_info_cx16_rom]
    // [1138] phi display_info_cx16_rom::info_text#2 = main::info_text8 [phi:main::@126->display_info_cx16_rom#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z display_info_cx16_rom.info_text
    lda #>info_text8
    sta.z display_info_cx16_rom.info_text+1
    // [1138] phi display_info_cx16_rom::info_status#2 = STATUS_SKIP [phi:main::@126->display_info_cx16_rom#1] -- vbuxx=vbuc1 
    ldx #STATUS_SKIP
    jsr display_info_cx16_rom
    // [436] phi from main::@126 to main::@127 [phi:main::@126->main::@127]
    // main::@127
    // display_info_smc(STATUS_ISSUE, NULL)
    // [437] call display_info_smc
    // [742] phi from main::@127 to display_info_smc [phi:main::@127->display_info_smc]
    // [742] phi display_info_smc::info_text#11 = 0 [phi:main::@127->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [742] phi display_info_smc::info_status#11 = STATUS_ISSUE [phi:main::@127->display_info_smc#1] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [438] phi from main::@127 to main::@128 [phi:main::@127->main::@128]
    // main::@128
    // util_wait_space()
    // [439] call util_wait_space
    // [808] phi from main::@128 to util_wait_space [phi:main::@128->util_wait_space]
    jsr util_wait_space
    jmp check_status_smc3
    // main::bank_set_brom4
  bank_set_brom4:
    // BROM = bank
    // [440] BROM = main::bank_set_brom4_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom4_bank
    sta.z BROM
    // main::@46
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [441] if(rom_device_ids[main::rom_chip2#10]==$55) goto main::@22 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    ldy rom_chip2
    lda rom_device_ids,y
    cmp #$55
    bne !__b22+
    jmp __b22
  !__b22:
    // [442] phi from main::@46 to main::@25 [phi:main::@46->main::@25]
    // main::@25
    // display_progress_clear()
    // [443] call display_progress_clear
    // [698] phi from main::@25 to display_progress_clear [phi:main::@25->display_progress_clear]
    jsr display_progress_clear
    // main::@103
    // unsigned char rom_bank = rom_chip * 32
    // [444] main::rom_bank#0 = main::rom_chip2#10 << 5 -- vbum1=vbum2_rol_5 
    lda rom_chip2
    asl
    asl
    asl
    asl
    asl
    sta rom_bank
    // unsigned char* file = rom_file(rom_chip)
    // [445] rom_file::rom_chip#0 = main::rom_chip2#10 -- vbuaa=vbum1 
    lda rom_chip2
    // [446] call rom_file
    jsr rom_file
    // [447] rom_file::return#4 = rom_file::return#2
    // main::@104
    // [448] main::file#0 = rom_file::return#4
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [449] call snprintf_init
    // [845] phi from main::@104 to snprintf_init [phi:main::@104->snprintf_init]
    // [845] phi snprintf_init::s#15 = info_text [phi:main::@104->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [450] phi from main::@104 to main::@105 [phi:main::@104->main::@105]
    // main::@105
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [451] call printf_str
    // [850] phi from main::@105 to printf_str [phi:main::@105->printf_str]
    // [850] phi printf_str::putc#48 = &snputc [phi:main::@105->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = main::s7 [phi:main::@105->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@106
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [452] printf_string::str#16 = main::file#0 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [453] call printf_string
    // [993] phi from main::@106 to printf_string [phi:main::@106->printf_string]
    // [993] phi printf_string::putc#21 = &snputc [phi:main::@106->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [993] phi printf_string::str#21 = printf_string::str#16 [phi:main::@106->printf_string#1] -- register_copy 
    // [993] phi printf_string::format_justify_left#21 = 0 [phi:main::@106->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [993] phi printf_string::format_min_length#21 = 0 [phi:main::@106->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [454] phi from main::@106 to main::@107 [phi:main::@106->main::@107]
    // main::@107
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [455] call printf_str
    // [850] phi from main::@107 to printf_str [phi:main::@107->printf_str]
    // [850] phi printf_str::putc#48 = &snputc [phi:main::@107->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = main::s8 [phi:main::@107->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // main::@108
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [456] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [457] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_progress(info_text)
    // [459] call display_action_progress
    // [684] phi from main::@108 to display_action_progress [phi:main::@108->display_action_progress]
    // [684] phi display_action_progress::info_text#10 = info_text [phi:main::@108->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_progress.info_text
    lda #>@info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@109
    // unsigned long rom_bytes_read = rom_read(0, rom_chip, file, STATUS_CHECKING, rom_bank, rom_sizes[rom_chip])
    // [460] main::$208 = main::rom_chip2#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip2
    asl
    asl
    sta main__208
    // [461] rom_read::file#0 = main::file#0 -- pbuz1=pbuz2 
    lda.z file
    sta.z rom_read.file
    lda.z file+1
    sta.z rom_read.file+1
    // [462] rom_read::brom_bank_start#1 = main::rom_bank#0 -- vbuz1=vbum2 
    lda rom_bank
    sta.z rom_read.brom_bank_start
    // [463] rom_read::rom_size#0 = rom_sizes[main::$208] -- vduz1=pduc1_derefidx_vbum2 
    ldy main__208
    lda rom_sizes,y
    sta.z rom_read.rom_size
    lda rom_sizes+1,y
    sta.z rom_read.rom_size+1
    lda rom_sizes+2,y
    sta.z rom_read.rom_size+2
    lda rom_sizes+3,y
    sta.z rom_read.rom_size+3
    // [464] call rom_read
    // Read the ROM(n).BIN file.
    jsr rom_read
    // [465] rom_read::return#2 = rom_read::return#0
    // main::@110
    // [466] main::rom_bytes_read#0 = rom_read::return#2
    // if (!rom_bytes_read)
    // [467] if(0==main::rom_bytes_read#0) goto main::@23 -- 0_eq_vduz1_then_la1 
    // In case no file was found, set the status to none and skip to the next, else, mention the amount of bytes read.
    lda.z rom_bytes_read
    ora.z rom_bytes_read+1
    ora.z rom_bytes_read+2
    ora.z rom_bytes_read+3
    bne !__b23+
    jmp __b23
  !__b23:
    // main::@26
    // unsigned long rom_file_modulo = rom_bytes_read % 0x4000
    // [468] main::rom_file_modulo#0 = main::rom_bytes_read#0 & $4000-1 -- vduz1=vduz2_band_vduc1 
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
    // [469] if(0!=main::rom_file_modulo#0) goto main::@24 -- 0_neq_vduz1_then_la1 
    lda.z rom_file_modulo
    ora.z rom_file_modulo+1
    ora.z rom_file_modulo+2
    ora.z rom_file_modulo+3
    beq !__b24+
    jmp __b24
  !__b24:
    // main::@27
    // file_sizes[rom_chip] = rom_bytes_read
    // [470] file_sizes[main::$208] = main::rom_bytes_read#0 -- pduc1_derefidx_vbum1=vduz2 
    // We know the file size, so we indicate it in the status panel.
    ldy main__208
    lda.z rom_bytes_read
    sta file_sizes,y
    lda.z rom_bytes_read+1
    sta file_sizes+1,y
    lda.z rom_bytes_read+2
    sta file_sizes+2,y
    lda.z rom_bytes_read+3
    sta file_sizes+3,y
    // rom_get_github_commit_id(file_rom_github, (char*)RAM_BASE)
    // [471] call rom_get_github_commit_id
    // [1232] phi from main::@27 to rom_get_github_commit_id [phi:main::@27->rom_get_github_commit_id]
    // [1232] phi rom_get_github_commit_id::commit_id#6 = main::file_rom_github [phi:main::@27->rom_get_github_commit_id#0] -- pbuz1=pbuc1 
    lda #<file_rom_github
    sta.z rom_get_github_commit_id.commit_id
    lda #>file_rom_github
    sta.z rom_get_github_commit_id.commit_id+1
    // [1232] phi rom_get_github_commit_id::from#6 = (char *)$7800 [phi:main::@27->rom_get_github_commit_id#1] -- pbuz1=pbuc1 
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
    // [473] BRAM = main::bank_push_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_push_set_bram1_bank
    sta.z BRAM
    // main::@48
    // unsigned char file_rom_release = rom_get_release(*((char*)0xBF80))
    // [474] rom_get_release::release#3 = *((char *) 49024) -- vbuxx=_deref_pbuc1 
    ldx $bf80
    // [475] call rom_get_release
    // [977] phi from main::@48 to rom_get_release [phi:main::@48->rom_get_release]
    // [977] phi rom_get_release::release#4 = rom_get_release::release#3 [phi:main::@48->rom_get_release#0] -- register_copy 
    jsr rom_get_release
    // unsigned char file_rom_release = rom_get_release(*((char*)0xBF80))
    // [476] rom_get_release::return#4 = rom_get_release::return#0
    // main::@118
    // [477] main::file_rom_release#0 = rom_get_release::return#4 -- vbuyy=vbuxx 
    txa
    tay
    // unsigned char file_rom_prefix = rom_get_prefix(*((char*)0xBF80))
    // [478] rom_get_prefix::release#3 = *((char *) 49024) -- vbuaa=_deref_pbuc1 
    lda $bf80
    // [479] call rom_get_prefix
    // [984] phi from main::@118 to rom_get_prefix [phi:main::@118->rom_get_prefix]
    // [984] phi rom_get_prefix::release#4 = rom_get_prefix::release#3 [phi:main::@118->rom_get_prefix#0] -- register_copy 
    jsr rom_get_prefix
    // unsigned char file_rom_prefix = rom_get_prefix(*((char*)0xBF80))
    // [480] rom_get_prefix::return#10 = rom_get_prefix::return#0 -- vbuaa=vbuxx 
    txa
    // main::@119
    // [481] main::file_rom_prefix#0 = rom_get_prefix::return#10 -- vbuxx=vbuaa 
    tax
    // main::bank_pull_bram1
    // asm
    // asm { pla sta$00  }
    pla
    sta.z 0
    // main::@49
    // rom_get_version_text(file_rom_release_text, file_rom_prefix, file_rom_release, file_rom_github)
    // [483] rom_get_version_text::prefix#1 = main::file_rom_prefix#0 -- vbuz1=vbuxx 
    stx.z rom_get_version_text.prefix
    // [484] rom_get_version_text::release#1 = main::file_rom_release#0 -- vbuz1=vbuyy 
    sty.z rom_get_version_text.release
    // [485] call rom_get_version_text
    // [1249] phi from main::@49 to rom_get_version_text [phi:main::@49->rom_get_version_text]
    // [1249] phi rom_get_version_text::github#2 = main::file_rom_github [phi:main::@49->rom_get_version_text#0] -- pbuz1=pbuc1 
    lda #<file_rom_github
    sta.z rom_get_version_text.github
    lda #>file_rom_github
    sta.z rom_get_version_text.github+1
    // [1249] phi rom_get_version_text::prefix#2 = rom_get_version_text::prefix#1 [phi:main::@49->rom_get_version_text#1] -- register_copy 
    // [1249] phi rom_get_version_text::release#2 = rom_get_version_text::release#1 [phi:main::@49->rom_get_version_text#2] -- register_copy 
    // [1249] phi rom_get_version_text::release_info#2 = main::file_rom_release_text [phi:main::@49->rom_get_version_text#3] -- pbuz1=pbuc1 
    lda #<file_rom_release_text
    sta.z rom_get_version_text.release_info
    lda #>file_rom_release_text
    sta.z rom_get_version_text.release_info+1
    jsr rom_get_version_text
    // [486] phi from main::@49 to main::@120 [phi:main::@49->main::@120]
    // main::@120
    // sprintf(info_text, "%s %s", file, file_rom_release_text)
    // [487] call snprintf_init
    // [845] phi from main::@120 to snprintf_init [phi:main::@120->snprintf_init]
    // [845] phi snprintf_init::s#15 = info_text [phi:main::@120->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main::@121
    // sprintf(info_text, "%s %s", file, file_rom_release_text)
    // [488] printf_string::str#19 = main::file#0 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [489] call printf_string
    // [993] phi from main::@121 to printf_string [phi:main::@121->printf_string]
    // [993] phi printf_string::putc#21 = &snputc [phi:main::@121->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [993] phi printf_string::str#21 = printf_string::str#19 [phi:main::@121->printf_string#1] -- register_copy 
    // [993] phi printf_string::format_justify_left#21 = 0 [phi:main::@121->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [993] phi printf_string::format_min_length#21 = 0 [phi:main::@121->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [490] phi from main::@121 to main::@122 [phi:main::@121->main::@122]
    // main::@122
    // sprintf(info_text, "%s %s", file, file_rom_release_text)
    // [491] call printf_str
    // [850] phi from main::@122 to printf_str [phi:main::@122->printf_str]
    // [850] phi printf_str::putc#48 = &snputc [phi:main::@122->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = s2 [phi:main::@122->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // [492] phi from main::@122 to main::@123 [phi:main::@122->main::@123]
    // main::@123
    // sprintf(info_text, "%s %s", file, file_rom_release_text)
    // [493] call printf_string
    // [993] phi from main::@123 to printf_string [phi:main::@123->printf_string]
    // [993] phi printf_string::putc#21 = &snputc [phi:main::@123->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [993] phi printf_string::str#21 = main::file_rom_release_text [phi:main::@123->printf_string#1] -- pbuz1=pbuc1 
    lda #<file_rom_release_text
    sta.z printf_string.str
    lda #>file_rom_release_text
    sta.z printf_string.str+1
    // [993] phi printf_string::format_justify_left#21 = 0 [phi:main::@123->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [993] phi printf_string::format_min_length#21 = 0 [phi:main::@123->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@124
    // sprintf(info_text, "%s %s", file, file_rom_release_text)
    // [494] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [495] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_FLASH, info_text)
    // [497] display_info_rom::rom_chip#5 = main::rom_chip2#10 -- vbuz1=vbum2 
    lda rom_chip2
    sta.z display_info_rom.rom_chip
    // [498] call display_info_rom
    // [1095] phi from main::@124 to display_info_rom [phi:main::@124->display_info_rom]
    // [1095] phi display_info_rom::info_text#10 = info_text [phi:main::@124->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1095] phi display_info_rom::rom_chip#10 = display_info_rom::rom_chip#5 [phi:main::@124->display_info_rom#1] -- register_copy 
    // [1095] phi display_info_rom::info_status#10 = STATUS_FLASH [phi:main::@124->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASH
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // [499] phi from main::@113 main::@117 main::@124 main::@46 to main::@22 [phi:main::@113/main::@117/main::@124/main::@46->main::@22]
    // [499] phi __errno#218 = __errno#16 [phi:main::@113/main::@117/main::@124/main::@46->main::@22#0] -- register_copy 
    // main::@22
  __b22:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [500] main::rom_chip2#1 = ++ main::rom_chip2#10 -- vbum1=_inc_vbum1 
    inc rom_chip2
    // [205] phi from main::@22 to main::@21 [phi:main::@22->main::@21]
    // [205] phi __errno#115 = __errno#218 [phi:main::@22->main::@21#0] -- register_copy 
    // [205] phi main::rom_chip2#10 = main::rom_chip2#1 [phi:main::@22->main::@21#1] -- register_copy 
    jmp __b21
    // [501] phi from main::@26 to main::@24 [phi:main::@26->main::@24]
    // main::@24
  __b24:
    // sprintf(info_text, "File %s size error!", file)
    // [502] call snprintf_init
    // [845] phi from main::@24 to snprintf_init [phi:main::@24->snprintf_init]
    // [845] phi snprintf_init::s#15 = info_text [phi:main::@24->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [503] phi from main::@24 to main::@114 [phi:main::@24->main::@114]
    // main::@114
    // sprintf(info_text, "File %s size error!", file)
    // [504] call printf_str
    // [850] phi from main::@114 to printf_str [phi:main::@114->printf_str]
    // [850] phi printf_str::putc#48 = &snputc [phi:main::@114->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = main::s10 [phi:main::@114->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // main::@115
    // sprintf(info_text, "File %s size error!", file)
    // [505] printf_string::str#18 = main::file#0 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [506] call printf_string
    // [993] phi from main::@115 to printf_string [phi:main::@115->printf_string]
    // [993] phi printf_string::putc#21 = &snputc [phi:main::@115->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [993] phi printf_string::str#21 = printf_string::str#18 [phi:main::@115->printf_string#1] -- register_copy 
    // [993] phi printf_string::format_justify_left#21 = 0 [phi:main::@115->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [993] phi printf_string::format_min_length#21 = 0 [phi:main::@115->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [507] phi from main::@115 to main::@116 [phi:main::@115->main::@116]
    // main::@116
    // sprintf(info_text, "File %s size error!", file)
    // [508] call printf_str
    // [850] phi from main::@116 to printf_str [phi:main::@116->printf_str]
    // [850] phi printf_str::putc#48 = &snputc [phi:main::@116->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = main::s11 [phi:main::@116->printf_str#1] -- pbuz1=pbuc1 
    lda #<s11
    sta.z printf_str.s
    lda #>s11
    sta.z printf_str.s+1
    jsr printf_str
    // main::@117
    // sprintf(info_text, "File %s size error!", file)
    // [509] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [510] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_ISSUE, info_text)
    // [512] display_info_rom::rom_chip#4 = main::rom_chip2#10 -- vbuz1=vbum2 
    lda rom_chip2
    sta.z display_info_rom.rom_chip
    // [513] call display_info_rom
    // [1095] phi from main::@117 to display_info_rom [phi:main::@117->display_info_rom]
    // [1095] phi display_info_rom::info_text#10 = info_text [phi:main::@117->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1095] phi display_info_rom::rom_chip#10 = display_info_rom::rom_chip#4 [phi:main::@117->display_info_rom#1] -- register_copy 
    // [1095] phi display_info_rom::info_status#10 = STATUS_ISSUE [phi:main::@117->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_rom.info_status
    jsr display_info_rom
    jmp __b22
    // [514] phi from main::@110 to main::@23 [phi:main::@110->main::@23]
    // main::@23
  __b23:
    // sprintf(info_text, "No %s", file)
    // [515] call snprintf_init
    // [845] phi from main::@23 to snprintf_init [phi:main::@23->snprintf_init]
    // [845] phi snprintf_init::s#15 = info_text [phi:main::@23->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [516] phi from main::@23 to main::@111 [phi:main::@23->main::@111]
    // main::@111
    // sprintf(info_text, "No %s", file)
    // [517] call printf_str
    // [850] phi from main::@111 to printf_str [phi:main::@111->printf_str]
    // [850] phi printf_str::putc#48 = &snputc [phi:main::@111->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = main::s9 [phi:main::@111->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // main::@112
    // sprintf(info_text, "No %s", file)
    // [518] printf_string::str#17 = main::file#0 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [519] call printf_string
    // [993] phi from main::@112 to printf_string [phi:main::@112->printf_string]
    // [993] phi printf_string::putc#21 = &snputc [phi:main::@112->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [993] phi printf_string::str#21 = printf_string::str#17 [phi:main::@112->printf_string#1] -- register_copy 
    // [993] phi printf_string::format_justify_left#21 = 0 [phi:main::@112->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [993] phi printf_string::format_min_length#21 = 0 [phi:main::@112->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@113
    // sprintf(info_text, "No %s", file)
    // [520] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [521] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_SKIP, info_text)
    // [523] display_info_rom::rom_chip#3 = main::rom_chip2#10 -- vbuz1=vbum2 
    lda rom_chip2
    sta.z display_info_rom.rom_chip
    // [524] call display_info_rom
    // [1095] phi from main::@113 to display_info_rom [phi:main::@113->display_info_rom]
    // [1095] phi display_info_rom::info_text#10 = info_text [phi:main::@113->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1095] phi display_info_rom::rom_chip#10 = display_info_rom::rom_chip#3 [phi:main::@113->display_info_rom#1] -- register_copy 
    // [1095] phi display_info_rom::info_status#10 = STATUS_SKIP [phi:main::@113->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_rom.info_status
    jsr display_info_rom
    jmp __b22
    // [525] phi from main::@17 to main::@20 [phi:main::@17->main::@20]
    // main::@20
  __b20:
    // display_info_smc(STATUS_ISSUE, "SMC.BIN too large!")
    // [526] call display_info_smc
    // [742] phi from main::@20 to display_info_smc [phi:main::@20->display_info_smc]
    // [742] phi display_info_smc::info_text#11 = main::info_text6 [phi:main::@20->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text6
    sta.z display_info_smc.info_text
    lda #>info_text6
    sta.z display_info_smc.info_text+1
    // [742] phi display_info_smc::info_status#11 = STATUS_ISSUE [phi:main::@20->display_info_smc#1] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp CLI2
    // [527] phi from main::@93 to main::@19 [phi:main::@93->main::@19]
    // main::@19
  __b19:
    // display_info_smc(STATUS_SKIP, "No SMC.BIN!")
    // [528] call display_info_smc
    // [742] phi from main::@19 to display_info_smc [phi:main::@19->display_info_smc]
    // [742] phi display_info_smc::info_text#11 = main::info_text5 [phi:main::@19->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z display_info_smc.info_text
    lda #>info_text5
    sta.z display_info_smc.info_text+1
    // [742] phi display_info_smc::info_status#11 = STATUS_SKIP [phi:main::@19->display_info_smc#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp CLI2
    // main::@13
  __b13:
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [529] if(rom_device_ids[main::rom_chip1#10]!=$55) goto main::@14 -- pbuc1_derefidx_vbuz1_neq_vbuc2_then_la1 
    lda #$55
    ldy.z rom_chip1
    cmp rom_device_ids,y
    bne __b14
    // main::@15
  __b15:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [530] main::rom_chip1#1 = ++ main::rom_chip1#10 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip1
    // [160] phi from main::@15 to main::@12 [phi:main::@15->main::@12]
    // [160] phi main::rom_chip1#10 = main::rom_chip1#1 [phi:main::@15->main::@12#0] -- register_copy 
    jmp __b12
    // main::@14
  __b14:
    // rom_chip*8
    // [531] main::$102 = main::rom_chip1#10 << 3 -- vbuz1=vbuz2_rol_3 
    lda.z rom_chip1
    asl
    asl
    asl
    sta.z main__102
    // rom_get_github_commit_id(&rom_github[rom_chip*8], (char*)0xC000)
    // [532] rom_get_github_commit_id::commit_id#0 = rom_github + main::$102 -- pbuz1=pbuc1_plus_vbuz2 
    clc
    adc #<rom_github
    sta.z rom_get_github_commit_id.commit_id
    lda #>rom_github
    adc #0
    sta.z rom_get_github_commit_id.commit_id+1
    // [533] call rom_get_github_commit_id
  // Fill the version data ...
    // [1232] phi from main::@14 to rom_get_github_commit_id [phi:main::@14->rom_get_github_commit_id]
    // [1232] phi rom_get_github_commit_id::commit_id#6 = rom_get_github_commit_id::commit_id#0 [phi:main::@14->rom_get_github_commit_id#0] -- register_copy 
    // [1232] phi rom_get_github_commit_id::from#6 = (char *) 49152 [phi:main::@14->rom_get_github_commit_id#1] -- pbuz1=pbuc1 
    lda #<$c000
    sta.z rom_get_github_commit_id.from
    lda #>$c000
    sta.z rom_get_github_commit_id.from+1
    jsr rom_get_github_commit_id
    // main::@89
    // rom_get_release(*((char*)0xFF80))
    // [534] rom_get_release::release#1 = *((char *) 65408) -- vbuxx=_deref_pbuc1 
    ldx $ff80
    // [535] call rom_get_release
    // [977] phi from main::@89 to rom_get_release [phi:main::@89->rom_get_release]
    // [977] phi rom_get_release::release#4 = rom_get_release::release#1 [phi:main::@89->rom_get_release#0] -- register_copy 
    jsr rom_get_release
    // rom_get_release(*((char*)0xFF80))
    // [536] rom_get_release::return#2 = rom_get_release::return#0
    // main::@90
    // [537] main::$98 = rom_get_release::return#2 -- vbuaa=vbuxx 
    txa
    // rom_release[rom_chip] = rom_get_release(*((char*)0xFF80))
    // [538] rom_release[main::rom_chip1#10] = main::$98 -- pbuc1_derefidx_vbuz1=vbuaa 
    ldy.z rom_chip1
    sta rom_release,y
    // rom_get_prefix(*((char*)0xFF80))
    // [539] rom_get_prefix::release#0 = *((char *) 65408) -- vbuaa=_deref_pbuc1 
    lda $ff80
    // [540] call rom_get_prefix
    // [984] phi from main::@90 to rom_get_prefix [phi:main::@90->rom_get_prefix]
    // [984] phi rom_get_prefix::release#4 = rom_get_prefix::release#0 [phi:main::@90->rom_get_prefix#0] -- register_copy 
    jsr rom_get_prefix
    // rom_get_prefix(*((char*)0xFF80))
    // [541] rom_get_prefix::return#2 = rom_get_prefix::return#0
    // main::@91
    // [542] main::$99 = rom_get_prefix::return#2 -- vbuaa=vbuxx 
    txa
    // rom_prefix[rom_chip] = rom_get_prefix(*((char*)0xFF80))
    // [543] rom_prefix[main::rom_chip1#10] = main::$99 -- pbuc1_derefidx_vbuz1=vbuaa 
    ldy.z rom_chip1
    sta rom_prefix,y
    // rom_chip*13
    // [544] main::$245 = main::rom_chip1#10 << 1 -- vbuaa=vbuz1_rol_1 
    tya
    asl
    // [545] main::$246 = main::$245 + main::rom_chip1#10 -- vbuaa=vbuaa_plus_vbuz1 
    clc
    adc.z rom_chip1
    // [546] main::$247 = main::$246 << 2 -- vbuaa=vbuaa_rol_2 
    asl
    asl
    // [547] main::$100 = main::$247 + main::rom_chip1#10 -- vbuaa=vbuaa_plus_vbuz1 
    clc
    adc.z rom_chip1
    // rom_get_version_text(&rom_release_text[rom_chip*13], rom_prefix[rom_chip], rom_release[rom_chip], &rom_github[rom_chip*8])
    // [548] rom_get_version_text::release_info#0 = rom_release_text + main::$100 -- pbuz1=pbuc1_plus_vbuaa 
    clc
    adc #<rom_release_text
    sta.z rom_get_version_text.release_info
    lda #>rom_release_text
    adc #0
    sta.z rom_get_version_text.release_info+1
    // [549] rom_get_version_text::github#0 = rom_github + main::$102 -- pbuz1=pbuc1_plus_vbuz2 
    lda.z main__102
    clc
    adc #<rom_github
    sta.z rom_get_version_text.github
    lda #>rom_github
    adc #0
    sta.z rom_get_version_text.github+1
    // [550] rom_get_version_text::prefix#0 = rom_prefix[main::rom_chip1#10] -- vbuz1=pbuc1_derefidx_vbuz2 
    lda rom_prefix,y
    sta.z rom_get_version_text.prefix
    // [551] rom_get_version_text::release#0 = rom_release[main::rom_chip1#10] -- vbuz1=pbuc1_derefidx_vbuz2 
    lda rom_release,y
    sta.z rom_get_version_text.release
    // [552] call rom_get_version_text
    // [1249] phi from main::@91 to rom_get_version_text [phi:main::@91->rom_get_version_text]
    // [1249] phi rom_get_version_text::github#2 = rom_get_version_text::github#0 [phi:main::@91->rom_get_version_text#0] -- register_copy 
    // [1249] phi rom_get_version_text::prefix#2 = rom_get_version_text::prefix#0 [phi:main::@91->rom_get_version_text#1] -- register_copy 
    // [1249] phi rom_get_version_text::release#2 = rom_get_version_text::release#0 [phi:main::@91->rom_get_version_text#2] -- register_copy 
    // [1249] phi rom_get_version_text::release_info#2 = rom_get_version_text::release_info#0 [phi:main::@91->rom_get_version_text#3] -- register_copy 
    jsr rom_get_version_text
    // main::@92
    // display_info_rom(rom_chip, STATUS_DETECTED, "")
    // [553] display_info_rom::rom_chip#2 = main::rom_chip1#10 -- vbuz1=vbuz2 
    lda.z rom_chip1
    sta.z display_info_rom.rom_chip
    // [554] call display_info_rom
    // [1095] phi from main::@92 to display_info_rom [phi:main::@92->display_info_rom]
    // [1095] phi display_info_rom::info_text#10 = info_text4 [phi:main::@92->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z display_info_rom.info_text
    lda #>info_text4
    sta.z display_info_rom.info_text+1
    // [1095] phi display_info_rom::rom_chip#10 = display_info_rom::rom_chip#2 [phi:main::@92->display_info_rom#1] -- register_copy 
    // [1095] phi display_info_rom::info_status#10 = STATUS_DETECTED [phi:main::@92->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_DETECTED
    sta.z display_info_rom.info_status
    jsr display_info_rom
    jmp __b15
    // main::@9
  __b9:
    // display_info_led(PROGRESS_X + 3, PROGRESS_Y + 3 + intro_status, status_color[intro_status], BLUE)
    // [555] display_info_led::y#3 = PROGRESS_Y+3 + main::intro_status#2 -- vbuz1=vbuc1_plus_vbuz2 
    lda #PROGRESS_Y+3
    clc
    adc.z intro_status
    sta.z display_info_led.y
    // [556] display_info_led::tc#3 = status_color[main::intro_status#2] -- vbuxx=pbuc1_derefidx_vbuz1 
    ldy.z intro_status
    ldx status_color,y
    // [557] call display_info_led
    // [1266] phi from main::@9 to display_info_led [phi:main::@9->display_info_led]
    // [1266] phi display_info_led::y#4 = display_info_led::y#3 [phi:main::@9->display_info_led#0] -- register_copy 
    // [1266] phi display_info_led::x#4 = PROGRESS_X+3 [phi:main::@9->display_info_led#1] -- vbuyy=vbuc1 
    ldy #PROGRESS_X+3
    // [1266] phi display_info_led::tc#4 = display_info_led::tc#3 [phi:main::@9->display_info_led#2] -- register_copy 
    jsr display_info_led
    // main::@75
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [558] main::intro_status#1 = ++ main::intro_status#2 -- vbuz1=_inc_vbuz1 
    inc.z intro_status
    // [109] phi from main::@75 to main::@8 [phi:main::@75->main::@8]
    // [109] phi main::intro_status#2 = main::intro_status#1 [phi:main::@75->main::@8#0] -- register_copy 
    jmp __b8
    // main::@7
  __b7:
    // rom_chip*13
    // [559] main::$241 = main::rom_chip#2 << 1 -- vbuaa=vbuz1_rol_1 
    lda.z rom_chip
    asl
    // [560] main::$242 = main::$241 + main::rom_chip#2 -- vbuaa=vbuaa_plus_vbuz1 
    clc
    adc.z rom_chip
    // [561] main::$243 = main::$242 << 2 -- vbuaa=vbuaa_rol_2 
    asl
    asl
    // [562] main::$72 = main::$243 + main::rom_chip#2 -- vbuaa=vbuaa_plus_vbuz1 
    clc
    adc.z rom_chip
    // strcpy(&rom_release_text[rom_chip*13], "          " )
    // [563] strcpy::destination#1 = rom_release_text + main::$72 -- pbuz1=pbuc1_plus_vbuaa 
    clc
    adc #<rom_release_text
    sta.z strcpy.destination
    lda #>rom_release_text
    adc #0
    sta.z strcpy.destination+1
    // [564] call strcpy
    // [813] phi from main::@7 to strcpy [phi:main::@7->strcpy]
    // [813] phi strcpy::dst#0 = strcpy::destination#1 [phi:main::@7->strcpy#0] -- register_copy 
    // [813] phi strcpy::src#0 = main::source [phi:main::@7->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // main::@71
    // display_info_rom(rom_chip, STATUS_NONE, NULL)
    // [565] display_info_rom::rom_chip#1 = main::rom_chip#2 -- vbuz1=vbuz2 
    lda.z rom_chip
    sta.z display_info_rom.rom_chip
    // [566] call display_info_rom
    // [1095] phi from main::@71 to display_info_rom [phi:main::@71->display_info_rom]
    // [1095] phi display_info_rom::info_text#10 = 0 [phi:main::@71->display_info_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_rom.info_text
    sta.z display_info_rom.info_text+1
    // [1095] phi display_info_rom::rom_chip#10 = display_info_rom::rom_chip#1 [phi:main::@71->display_info_rom#1] -- register_copy 
    // [1095] phi display_info_rom::info_status#10 = STATUS_NONE [phi:main::@71->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_NONE
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // main::@72
    // for(unsigned char rom_chip=0; rom_chip<8; rom_chip++)
    // [567] main::rom_chip#1 = ++ main::rom_chip#2 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip
    // [99] phi from main::@72 to main::@6 [phi:main::@72->main::@6]
    // [99] phi main::rom_chip#2 = main::rom_chip#1 [phi:main::@72->main::@6#0] -- register_copy 
    jmp __b6
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
    main__224: .text "nN"
    .byte 0
    info_text13: .text "Cancelled"
    .byte 0
    info_text16: .text "You have selected not to cancel the update ... "
    .byte 0
    info_text17: .text "The update has been cancelled!"
    .byte 0
    info_text18: .text "Update Failure! Your CX16 may be bricked!"
    .byte 0
    info_text19: .text "Take a foto of this screen. And shut down power ..."
    .byte 0
    info_text20: .text "Update issues, your CX16 is not updated!"
    .byte 0
    info_text21: .text "Your CX16 update is a success!"
    .byte 0
    s13: .text "("
    .byte 0
    s14: .text ") Please read carefully the below ..."
    .byte 0
    s15: .text "Please disconnect your CX16 from power source ..."
    .byte 0
    s17: .text ") Your CX16 will reset ..."
    .byte 0
    main__208: .byte 0
    rom_chip2: .byte 0
    rom_bank: .byte 0
}
.segment Code
  // screenlayer1
// Set the layer with which the conio will interact.
screenlayer1: {
    // screenlayer(1, *VERA_L1_MAPBASE, *VERA_L1_CONFIG)
    // [568] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbuxx=_deref_pbuc1 
    ldx VERA_L1_MAPBASE
    // [569] screenlayer::config#0 = *VERA_L1_CONFIG -- vbuz1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta.z screenlayer.config
    // [570] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [571] return 
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
    // [573] textcolor::$0 = *((char *)&__conio+$d) & $f0 -- vbuaa=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$d
    // __conio.color & 0xF0 | color
    // [574] textcolor::$1 = textcolor::$0 | textcolor::color#17 -- vbuaa=vbuaa_bor_vbuxx 
    stx.z $ff
    ora.z $ff
    // __conio.color = __conio.color & 0xF0 | color
    // [575] *((char *)&__conio+$d) = textcolor::$1 -- _deref_pbuc1=vbuaa 
    sta __conio+$d
    // textcolor::@return
    // }
    // [576] return 
    rts
}
  // bgcolor
// Set the back color for text output.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char bgcolor(__register(X) char color)
bgcolor: {
    .label bgcolor__0 = $ad
    // __conio.color & 0x0F
    // [578] bgcolor::$0 = *((char *)&__conio+$d) & $f -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$d
    sta.z bgcolor__0
    // color << 4
    // [579] bgcolor::$1 = bgcolor::color#14 << 4 -- vbuaa=vbuxx_rol_4 
    txa
    asl
    asl
    asl
    asl
    // __conio.color & 0x0F | color << 4
    // [580] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbuaa=vbuz1_bor_vbuaa 
    ora.z bgcolor__0
    // __conio.color = __conio.color & 0x0F | color << 4
    // [581] *((char *)&__conio+$d) = bgcolor::$2 -- _deref_pbuc1=vbuaa 
    sta __conio+$d
    // bgcolor::@return
    // }
    // [582] return 
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
    // [583] *((char *)&__conio+$c) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$c
    // cursor::@return
    // }
    // [584] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    .label return = $d7
    // __mem unsigned char x
    // [585] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [586] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [588] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwuz1=vbum2_word_vbum3 
    lda x
    sta.z return+1
    lda y
    sta.z return
    // cbm_k_plot_get::@return
    // }
    // [589] return 
    rts
  .segment Data
    x: .byte 0
    y: .byte 0
}
.segment Code
  // gotoxy
// Set the cursor to the specified position
// void gotoxy(__register(X) char x, __register(Y) char y)
gotoxy: {
    .label gotoxy__9 = $46
    // (x>=__conio.width)?__conio.width:x
    // [591] if(gotoxy::x#24>=*((char *)&__conio+6)) goto gotoxy::@1 -- vbuxx_ge__deref_pbuc1_then_la1 
    cpx __conio+6
    bcs __b1
    // [593] phi from gotoxy gotoxy::@1 to gotoxy::@2 [phi:gotoxy/gotoxy::@1->gotoxy::@2]
    // [593] phi gotoxy::$3 = gotoxy::x#24 [phi:gotoxy/gotoxy::@1->gotoxy::@2#0] -- register_copy 
    jmp __b2
    // gotoxy::@1
  __b1:
    // [592] gotoxy::$2 = *((char *)&__conio+6) -- vbuxx=_deref_pbuc1 
    ldx __conio+6
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [594] *((char *)&__conio) = gotoxy::$3 -- _deref_pbuc1=vbuxx 
    stx __conio
    // (y>=__conio.height)?__conio.height:y
    // [595] if(gotoxy::y#24>=*((char *)&__conio+7)) goto gotoxy::@3 -- vbuyy_ge__deref_pbuc1_then_la1 
    cpy __conio+7
    bcs __b3
    // gotoxy::@4
    // [596] gotoxy::$14 = gotoxy::y#24 -- vbuaa=vbuyy 
    tya
    // [597] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [597] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [598] *((char *)&__conio+1) = gotoxy::$7 -- _deref_pbuc1=vbuaa 
    sta __conio+1
    // __conio.cursor_x << 1
    // [599] gotoxy::$8 = *((char *)&__conio) << 1 -- vbuxx=_deref_pbuc1_rol_1 
    lda __conio
    asl
    tax
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [600] gotoxy::$10 = gotoxy::y#24 << 1 -- vbuaa=vbuyy_rol_1 
    tya
    asl
    // [601] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwuz1=pwuc1_derefidx_vbuaa_plus_vbuxx 
    tay
    txa
    clc
    adc __conio+$15,y
    sta.z gotoxy__9
    lda __conio+$15+1,y
    adc #0
    sta.z gotoxy__9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [602] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwuz1 
    lda.z gotoxy__9
    sta __conio+$13
    lda.z gotoxy__9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [603] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [604] gotoxy::$6 = *((char *)&__conio+7) -- vbuaa=_deref_pbuc1 
    lda __conio+7
    jmp __b5
}
  // cputln
// Print a newline
cputln: {
    // __conio.cursor_x = 0
    // [605] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y++;
    // [606] *((char *)&__conio+1) = ++ *((char *)&__conio+1) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+1
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [607] cputln::$2 = *((char *)&__conio+1) << 1 -- vbuaa=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    // [608] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbuaa 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [609] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [610] return 
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
    // [612] call textcolor
  // Set the charset to lower case.
  // screenlayer1();
    // [572] phi from display_frame_init_64 to textcolor [phi:display_frame_init_64->textcolor]
    // [572] phi textcolor::color#17 = WHITE [phi:display_frame_init_64->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [613] phi from display_frame_init_64 to display_frame_init_64::@2 [phi:display_frame_init_64->display_frame_init_64::@2]
    // display_frame_init_64::@2
    // bgcolor(BLUE)
    // [614] call bgcolor
    // [577] phi from display_frame_init_64::@2 to bgcolor [phi:display_frame_init_64::@2->bgcolor]
    // [577] phi bgcolor::color#14 = BLUE [phi:display_frame_init_64::@2->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // [615] phi from display_frame_init_64::@2 to display_frame_init_64::@3 [phi:display_frame_init_64::@2->display_frame_init_64::@3]
    // display_frame_init_64::@3
    // scroll(0)
    // [616] call scroll
    jsr scroll
    // [617] phi from display_frame_init_64::@3 to display_frame_init_64::@4 [phi:display_frame_init_64::@3->display_frame_init_64::@4]
    // display_frame_init_64::@4
    // clrscr()
    // [618] call clrscr
    jsr clrscr
    // display_frame_init_64::vera_display_set_hstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [619] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTART = start
    // [620] *VERA_DC_HSTART = display_frame_init_64::vera_display_set_hstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstart1_start
    sta VERA_DC_HSTART
    // display_frame_init_64::vera_display_set_hstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [621] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTOP = stop
    // [622] *VERA_DC_HSTOP = display_frame_init_64::vera_display_set_hstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstop1_stop
    sta VERA_DC_HSTOP
    // display_frame_init_64::vera_display_set_vstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [623] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTART = start
    // [624] *VERA_DC_VSTART = display_frame_init_64::vera_display_set_vstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstart1_start
    sta VERA_DC_VSTART
    // display_frame_init_64::vera_display_set_vstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [625] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTOP = stop
    // [626] *VERA_DC_VSTOP = display_frame_init_64::vera_display_set_vstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstop1_stop
    sta VERA_DC_VSTOP
    // display_frame_init_64::@1
    // cx16_k_screen_set_charset(3, (char *)0)
    // [627] display_frame_init_64::cx16_k_screen_set_charset1_charset = 3 -- vbum1=vbuc1 
    lda #3
    sta cx16_k_screen_set_charset1_charset
    // [628] display_frame_init_64::cx16_k_screen_set_charset1_offset = (char *) 0 -- pbum1=pbuc1 
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
    // [630] return 
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
    // [632] call textcolor
    // [572] phi from display_frame_draw to textcolor [phi:display_frame_draw->textcolor]
    // [572] phi textcolor::color#17 = LIGHT_BLUE [phi:display_frame_draw->textcolor#0] -- vbuxx=vbuc1 
    ldx #LIGHT_BLUE
    jsr textcolor
    // [633] phi from display_frame_draw to display_frame_draw::@1 [phi:display_frame_draw->display_frame_draw::@1]
    // display_frame_draw::@1
    // bgcolor(BLUE)
    // [634] call bgcolor
    // [577] phi from display_frame_draw::@1 to bgcolor [phi:display_frame_draw::@1->bgcolor]
    // [577] phi bgcolor::color#14 = BLUE [phi:display_frame_draw::@1->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // [635] phi from display_frame_draw::@1 to display_frame_draw::@2 [phi:display_frame_draw::@1->display_frame_draw::@2]
    // display_frame_draw::@2
    // clrscr()
    // [636] call clrscr
    jsr clrscr
    // [637] phi from display_frame_draw::@2 to display_frame_draw::@3 [phi:display_frame_draw::@2->display_frame_draw::@3]
    // display_frame_draw::@3
    // display_frame(0, 0, 67, 14)
    // [638] call display_frame
    // [1348] phi from display_frame_draw::@3 to display_frame [phi:display_frame_draw::@3->display_frame]
    // [1348] phi display_frame::y#0 = 0 [phi:display_frame_draw::@3->display_frame#0] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.y
    // [1348] phi display_frame::y1#16 = $e [phi:display_frame_draw::@3->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1348] phi display_frame::x#0 = 0 [phi:display_frame_draw::@3->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1348] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@3->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [639] phi from display_frame_draw::@3 to display_frame_draw::@4 [phi:display_frame_draw::@3->display_frame_draw::@4]
    // display_frame_draw::@4
    // display_frame(0, 0, 67, 2)
    // [640] call display_frame
    // [1348] phi from display_frame_draw::@4 to display_frame [phi:display_frame_draw::@4->display_frame]
    // [1348] phi display_frame::y#0 = 0 [phi:display_frame_draw::@4->display_frame#0] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.y
    // [1348] phi display_frame::y1#16 = 2 [phi:display_frame_draw::@4->display_frame#1] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y1
    // [1348] phi display_frame::x#0 = 0 [phi:display_frame_draw::@4->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1348] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@4->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [641] phi from display_frame_draw::@4 to display_frame_draw::@5 [phi:display_frame_draw::@4->display_frame_draw::@5]
    // display_frame_draw::@5
    // display_frame(0, 2, 67, 14)
    // [642] call display_frame
    // [1348] phi from display_frame_draw::@5 to display_frame [phi:display_frame_draw::@5->display_frame]
    // [1348] phi display_frame::y#0 = 2 [phi:display_frame_draw::@5->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1348] phi display_frame::y1#16 = $e [phi:display_frame_draw::@5->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1348] phi display_frame::x#0 = 0 [phi:display_frame_draw::@5->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1348] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@5->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [643] phi from display_frame_draw::@5 to display_frame_draw::@6 [phi:display_frame_draw::@5->display_frame_draw::@6]
    // display_frame_draw::@6
    // display_frame(0, 2, 8, 14)
    // [644] call display_frame
  // Chipset areas
    // [1348] phi from display_frame_draw::@6 to display_frame [phi:display_frame_draw::@6->display_frame]
    // [1348] phi display_frame::y#0 = 2 [phi:display_frame_draw::@6->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1348] phi display_frame::y1#16 = $e [phi:display_frame_draw::@6->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1348] phi display_frame::x#0 = 0 [phi:display_frame_draw::@6->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1348] phi display_frame::x1#16 = 8 [phi:display_frame_draw::@6->display_frame#3] -- vbuz1=vbuc1 
    lda #8
    sta.z display_frame.x1
    jsr display_frame
    // [645] phi from display_frame_draw::@6 to display_frame_draw::@7 [phi:display_frame_draw::@6->display_frame_draw::@7]
    // display_frame_draw::@7
    // display_frame(8, 2, 19, 14)
    // [646] call display_frame
    // [1348] phi from display_frame_draw::@7 to display_frame [phi:display_frame_draw::@7->display_frame]
    // [1348] phi display_frame::y#0 = 2 [phi:display_frame_draw::@7->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1348] phi display_frame::y1#16 = $e [phi:display_frame_draw::@7->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1348] phi display_frame::x#0 = 8 [phi:display_frame_draw::@7->display_frame#2] -- vbuz1=vbuc1 
    lda #8
    sta.z display_frame.x
    // [1348] phi display_frame::x1#16 = $13 [phi:display_frame_draw::@7->display_frame#3] -- vbuz1=vbuc1 
    lda #$13
    sta.z display_frame.x1
    jsr display_frame
    // [647] phi from display_frame_draw::@7 to display_frame_draw::@8 [phi:display_frame_draw::@7->display_frame_draw::@8]
    // display_frame_draw::@8
    // display_frame(19, 2, 25, 14)
    // [648] call display_frame
    // [1348] phi from display_frame_draw::@8 to display_frame [phi:display_frame_draw::@8->display_frame]
    // [1348] phi display_frame::y#0 = 2 [phi:display_frame_draw::@8->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1348] phi display_frame::y1#16 = $e [phi:display_frame_draw::@8->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1348] phi display_frame::x#0 = $13 [phi:display_frame_draw::@8->display_frame#2] -- vbuz1=vbuc1 
    lda #$13
    sta.z display_frame.x
    // [1348] phi display_frame::x1#16 = $19 [phi:display_frame_draw::@8->display_frame#3] -- vbuz1=vbuc1 
    lda #$19
    sta.z display_frame.x1
    jsr display_frame
    // [649] phi from display_frame_draw::@8 to display_frame_draw::@9 [phi:display_frame_draw::@8->display_frame_draw::@9]
    // display_frame_draw::@9
    // display_frame(25, 2, 31, 14)
    // [650] call display_frame
    // [1348] phi from display_frame_draw::@9 to display_frame [phi:display_frame_draw::@9->display_frame]
    // [1348] phi display_frame::y#0 = 2 [phi:display_frame_draw::@9->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1348] phi display_frame::y1#16 = $e [phi:display_frame_draw::@9->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1348] phi display_frame::x#0 = $19 [phi:display_frame_draw::@9->display_frame#2] -- vbuz1=vbuc1 
    lda #$19
    sta.z display_frame.x
    // [1348] phi display_frame::x1#16 = $1f [phi:display_frame_draw::@9->display_frame#3] -- vbuz1=vbuc1 
    lda #$1f
    sta.z display_frame.x1
    jsr display_frame
    // [651] phi from display_frame_draw::@9 to display_frame_draw::@10 [phi:display_frame_draw::@9->display_frame_draw::@10]
    // display_frame_draw::@10
    // display_frame(31, 2, 37, 14)
    // [652] call display_frame
    // [1348] phi from display_frame_draw::@10 to display_frame [phi:display_frame_draw::@10->display_frame]
    // [1348] phi display_frame::y#0 = 2 [phi:display_frame_draw::@10->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1348] phi display_frame::y1#16 = $e [phi:display_frame_draw::@10->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1348] phi display_frame::x#0 = $1f [phi:display_frame_draw::@10->display_frame#2] -- vbuz1=vbuc1 
    lda #$1f
    sta.z display_frame.x
    // [1348] phi display_frame::x1#16 = $25 [phi:display_frame_draw::@10->display_frame#3] -- vbuz1=vbuc1 
    lda #$25
    sta.z display_frame.x1
    jsr display_frame
    // [653] phi from display_frame_draw::@10 to display_frame_draw::@11 [phi:display_frame_draw::@10->display_frame_draw::@11]
    // display_frame_draw::@11
    // display_frame(37, 2, 43, 14)
    // [654] call display_frame
    // [1348] phi from display_frame_draw::@11 to display_frame [phi:display_frame_draw::@11->display_frame]
    // [1348] phi display_frame::y#0 = 2 [phi:display_frame_draw::@11->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1348] phi display_frame::y1#16 = $e [phi:display_frame_draw::@11->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1348] phi display_frame::x#0 = $25 [phi:display_frame_draw::@11->display_frame#2] -- vbuz1=vbuc1 
    lda #$25
    sta.z display_frame.x
    // [1348] phi display_frame::x1#16 = $2b [phi:display_frame_draw::@11->display_frame#3] -- vbuz1=vbuc1 
    lda #$2b
    sta.z display_frame.x1
    jsr display_frame
    // [655] phi from display_frame_draw::@11 to display_frame_draw::@12 [phi:display_frame_draw::@11->display_frame_draw::@12]
    // display_frame_draw::@12
    // display_frame(43, 2, 49, 14)
    // [656] call display_frame
    // [1348] phi from display_frame_draw::@12 to display_frame [phi:display_frame_draw::@12->display_frame]
    // [1348] phi display_frame::y#0 = 2 [phi:display_frame_draw::@12->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1348] phi display_frame::y1#16 = $e [phi:display_frame_draw::@12->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1348] phi display_frame::x#0 = $2b [phi:display_frame_draw::@12->display_frame#2] -- vbuz1=vbuc1 
    lda #$2b
    sta.z display_frame.x
    // [1348] phi display_frame::x1#16 = $31 [phi:display_frame_draw::@12->display_frame#3] -- vbuz1=vbuc1 
    lda #$31
    sta.z display_frame.x1
    jsr display_frame
    // [657] phi from display_frame_draw::@12 to display_frame_draw::@13 [phi:display_frame_draw::@12->display_frame_draw::@13]
    // display_frame_draw::@13
    // display_frame(49, 2, 55, 14)
    // [658] call display_frame
    // [1348] phi from display_frame_draw::@13 to display_frame [phi:display_frame_draw::@13->display_frame]
    // [1348] phi display_frame::y#0 = 2 [phi:display_frame_draw::@13->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1348] phi display_frame::y1#16 = $e [phi:display_frame_draw::@13->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1348] phi display_frame::x#0 = $31 [phi:display_frame_draw::@13->display_frame#2] -- vbuz1=vbuc1 
    lda #$31
    sta.z display_frame.x
    // [1348] phi display_frame::x1#16 = $37 [phi:display_frame_draw::@13->display_frame#3] -- vbuz1=vbuc1 
    lda #$37
    sta.z display_frame.x1
    jsr display_frame
    // [659] phi from display_frame_draw::@13 to display_frame_draw::@14 [phi:display_frame_draw::@13->display_frame_draw::@14]
    // display_frame_draw::@14
    // display_frame(55, 2, 61, 14)
    // [660] call display_frame
    // [1348] phi from display_frame_draw::@14 to display_frame [phi:display_frame_draw::@14->display_frame]
    // [1348] phi display_frame::y#0 = 2 [phi:display_frame_draw::@14->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1348] phi display_frame::y1#16 = $e [phi:display_frame_draw::@14->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1348] phi display_frame::x#0 = $37 [phi:display_frame_draw::@14->display_frame#2] -- vbuz1=vbuc1 
    lda #$37
    sta.z display_frame.x
    // [1348] phi display_frame::x1#16 = $3d [phi:display_frame_draw::@14->display_frame#3] -- vbuz1=vbuc1 
    lda #$3d
    sta.z display_frame.x1
    jsr display_frame
    // [661] phi from display_frame_draw::@14 to display_frame_draw::@15 [phi:display_frame_draw::@14->display_frame_draw::@15]
    // display_frame_draw::@15
    // display_frame(61, 2, 67, 14)
    // [662] call display_frame
    // [1348] phi from display_frame_draw::@15 to display_frame [phi:display_frame_draw::@15->display_frame]
    // [1348] phi display_frame::y#0 = 2 [phi:display_frame_draw::@15->display_frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z display_frame.y
    // [1348] phi display_frame::y1#16 = $e [phi:display_frame_draw::@15->display_frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y1
    // [1348] phi display_frame::x#0 = $3d [phi:display_frame_draw::@15->display_frame#2] -- vbuz1=vbuc1 
    lda #$3d
    sta.z display_frame.x
    // [1348] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@15->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [663] phi from display_frame_draw::@15 to display_frame_draw::@16 [phi:display_frame_draw::@15->display_frame_draw::@16]
    // display_frame_draw::@16
    // display_frame(0, 14, 67, PROGRESS_Y-5)
    // [664] call display_frame
  // Progress area
    // [1348] phi from display_frame_draw::@16 to display_frame [phi:display_frame_draw::@16->display_frame]
    // [1348] phi display_frame::y#0 = $e [phi:display_frame_draw::@16->display_frame#0] -- vbuz1=vbuc1 
    lda #$e
    sta.z display_frame.y
    // [1348] phi display_frame::y1#16 = PROGRESS_Y-5 [phi:display_frame_draw::@16->display_frame#1] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-5
    sta.z display_frame.y1
    // [1348] phi display_frame::x#0 = 0 [phi:display_frame_draw::@16->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1348] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@16->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [665] phi from display_frame_draw::@16 to display_frame_draw::@17 [phi:display_frame_draw::@16->display_frame_draw::@17]
    // display_frame_draw::@17
    // display_frame(0, PROGRESS_Y-5, 67, PROGRESS_Y-2)
    // [666] call display_frame
    // [1348] phi from display_frame_draw::@17 to display_frame [phi:display_frame_draw::@17->display_frame]
    // [1348] phi display_frame::y#0 = PROGRESS_Y-5 [phi:display_frame_draw::@17->display_frame#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-5
    sta.z display_frame.y
    // [1348] phi display_frame::y1#16 = PROGRESS_Y-2 [phi:display_frame_draw::@17->display_frame#1] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-2
    sta.z display_frame.y1
    // [1348] phi display_frame::x#0 = 0 [phi:display_frame_draw::@17->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1348] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@17->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [667] phi from display_frame_draw::@17 to display_frame_draw::@18 [phi:display_frame_draw::@17->display_frame_draw::@18]
    // display_frame_draw::@18
    // display_frame(0, PROGRESS_Y-2, 67, 49)
    // [668] call display_frame
    // [1348] phi from display_frame_draw::@18 to display_frame [phi:display_frame_draw::@18->display_frame]
    // [1348] phi display_frame::y#0 = PROGRESS_Y-2 [phi:display_frame_draw::@18->display_frame#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-2
    sta.z display_frame.y
    // [1348] phi display_frame::y1#16 = $31 [phi:display_frame_draw::@18->display_frame#1] -- vbuz1=vbuc1 
    lda #$31
    sta.z display_frame.y1
    // [1348] phi display_frame::x#0 = 0 [phi:display_frame_draw::@18->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [1348] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@18->display_frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z display_frame.x1
    jsr display_frame
    // [669] phi from display_frame_draw::@18 to display_frame_draw::@19 [phi:display_frame_draw::@18->display_frame_draw::@19]
    // display_frame_draw::@19
    // textcolor(WHITE)
    // [670] call textcolor
    // [572] phi from display_frame_draw::@19 to textcolor [phi:display_frame_draw::@19->textcolor]
    // [572] phi textcolor::color#17 = WHITE [phi:display_frame_draw::@19->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // display_frame_draw::@return
    // }
    // [671] return 
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
    // [673] call gotoxy
    // [590] phi from display_frame_title to gotoxy [phi:display_frame_title->gotoxy]
    // [590] phi gotoxy::y#24 = 1 [phi:display_frame_title->gotoxy#0] -- vbuyy=vbuc1 
    ldy #1
    // [590] phi gotoxy::x#24 = 2 [phi:display_frame_title->gotoxy#1] -- vbuxx=vbuc1 
    ldx #2
    jsr gotoxy
    // [674] phi from display_frame_title to display_frame_title::@1 [phi:display_frame_title->display_frame_title::@1]
    // display_frame_title::@1
    // printf("%-65s", title_text)
    // [675] call printf_string
    // [993] phi from display_frame_title::@1 to printf_string [phi:display_frame_title::@1->printf_string]
    // [993] phi printf_string::putc#21 = &cputc [phi:display_frame_title::@1->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [993] phi printf_string::str#21 = main::title_text [phi:display_frame_title::@1->printf_string#1] -- pbuz1=pbuc1 
    lda #<main.title_text
    sta.z printf_string.str
    lda #>main.title_text
    sta.z printf_string.str+1
    // [993] phi printf_string::format_justify_left#21 = 1 [phi:display_frame_title::@1->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [993] phi printf_string::format_min_length#21 = $41 [phi:display_frame_title::@1->printf_string#3] -- vbuz1=vbuc1 
    lda #$41
    sta.z printf_string.format_min_length
    jsr printf_string
    // display_frame_title::@return
    // }
    // [676] return 
    rts
}
  // cputsxy
// Move cursor and output a NUL-terminated string
// Same as "gotoxy (x, y); puts (s);"
// void cputsxy(__register(X) char x, __register(Y) char y, __zp($3a) const char *s)
cputsxy: {
    .label s = $3a
    // gotoxy(x, y)
    // [678] gotoxy::x#1 = cputsxy::x#3
    // [679] gotoxy::y#1 = cputsxy::y#3
    // [680] call gotoxy
    // [590] phi from cputsxy to gotoxy [phi:cputsxy->gotoxy]
    // [590] phi gotoxy::y#24 = gotoxy::y#1 [phi:cputsxy->gotoxy#0] -- register_copy 
    // [590] phi gotoxy::x#24 = gotoxy::x#1 [phi:cputsxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputsxy::@1
    // cputs(s)
    // [681] cputs::s#1 = cputsxy::s#3 -- pbuz1=pbuz2 
    lda.z s
    sta.z cputs.s
    lda.z s+1
    sta.z cputs.s+1
    // [682] call cputs
    // [1482] phi from cputsxy::@1 to cputs [phi:cputsxy::@1->cputs]
    jsr cputs
    // cputsxy::@return
    // }
    // [683] return 
    rts
}
  // display_action_progress
/**
 * @brief Print the progress at the action frame, which is the first line.
 * 
 * @param info_text The progress text to be displayed.
 */
// void display_action_progress(__zp($3e) char *info_text)
display_action_progress: {
    .label x = $ec
    .label y = $f0
    .label info_text = $3e
    // unsigned char x = wherex()
    // [685] call wherex
    jsr wherex
    // [686] wherex::return#2 = wherex::return#0
    // display_action_progress::@1
    // [687] display_action_progress::x#0 = wherex::return#2 -- vbuz1=vbuaa 
    sta.z x
    // unsigned char y = wherey()
    // [688] call wherey
    jsr wherey
    // [689] wherey::return#2 = wherey::return#0
    // display_action_progress::@2
    // [690] display_action_progress::y#0 = wherey::return#2 -- vbuz1=vbuaa 
    sta.z y
    // gotoxy(2, PROGRESS_Y-4)
    // [691] call gotoxy
    // [590] phi from display_action_progress::@2 to gotoxy [phi:display_action_progress::@2->gotoxy]
    // [590] phi gotoxy::y#24 = PROGRESS_Y-4 [phi:display_action_progress::@2->gotoxy#0] -- vbuyy=vbuc1 
    ldy #PROGRESS_Y-4
    // [590] phi gotoxy::x#24 = 2 [phi:display_action_progress::@2->gotoxy#1] -- vbuxx=vbuc1 
    ldx #2
    jsr gotoxy
    // display_action_progress::@3
    // printf("%-65s", info_text)
    // [692] printf_string::str#1 = display_action_progress::info_text#10
    // [693] call printf_string
    // [993] phi from display_action_progress::@3 to printf_string [phi:display_action_progress::@3->printf_string]
    // [993] phi printf_string::putc#21 = &cputc [phi:display_action_progress::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [993] phi printf_string::str#21 = printf_string::str#1 [phi:display_action_progress::@3->printf_string#1] -- register_copy 
    // [993] phi printf_string::format_justify_left#21 = 1 [phi:display_action_progress::@3->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [993] phi printf_string::format_min_length#21 = $41 [phi:display_action_progress::@3->printf_string#3] -- vbuz1=vbuc1 
    lda #$41
    sta.z printf_string.format_min_length
    jsr printf_string
    // display_action_progress::@4
    // gotoxy(x, y)
    // [694] gotoxy::x#10 = display_action_progress::x#0 -- vbuxx=vbuz1 
    ldx.z x
    // [695] gotoxy::y#10 = display_action_progress::y#0 -- vbuyy=vbuz1 
    ldy.z y
    // [696] call gotoxy
    // [590] phi from display_action_progress::@4 to gotoxy [phi:display_action_progress::@4->gotoxy]
    // [590] phi gotoxy::y#24 = gotoxy::y#10 [phi:display_action_progress::@4->gotoxy#0] -- register_copy 
    // [590] phi gotoxy::x#24 = gotoxy::x#10 [phi:display_action_progress::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_action_progress::@return
    // }
    // [697] return 
    rts
}
  // display_progress_clear
/**
 * @brief Clean the progress area for the flashing.
 */
display_progress_clear: {
    .const h = PROGRESS_Y+PROGRESS_H
    .label x = $78
    .label i = $7b
    .label y = $bf
    // textcolor(WHITE)
    // [699] call textcolor
    // [572] phi from display_progress_clear to textcolor [phi:display_progress_clear->textcolor]
    // [572] phi textcolor::color#17 = WHITE [phi:display_progress_clear->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [700] phi from display_progress_clear to display_progress_clear::@5 [phi:display_progress_clear->display_progress_clear::@5]
    // display_progress_clear::@5
    // bgcolor(BLUE)
    // [701] call bgcolor
    // [577] phi from display_progress_clear::@5 to bgcolor [phi:display_progress_clear::@5->bgcolor]
    // [577] phi bgcolor::color#14 = BLUE [phi:display_progress_clear::@5->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // [702] phi from display_progress_clear::@5 to display_progress_clear::@1 [phi:display_progress_clear::@5->display_progress_clear::@1]
    // [702] phi display_progress_clear::y#2 = PROGRESS_Y [phi:display_progress_clear::@5->display_progress_clear::@1#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // display_progress_clear::@1
  __b1:
    // while (y < h)
    // [703] if(display_progress_clear::y#2<display_progress_clear::h) goto display_progress_clear::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y
    cmp #h
    bcc __b4
    // display_progress_clear::@return
    // }
    // [704] return 
    rts
    // [705] phi from display_progress_clear::@1 to display_progress_clear::@2 [phi:display_progress_clear::@1->display_progress_clear::@2]
  __b4:
    // [705] phi display_progress_clear::x#2 = PROGRESS_X [phi:display_progress_clear::@1->display_progress_clear::@2#0] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z x
    // [705] phi display_progress_clear::i#2 = 0 [phi:display_progress_clear::@1->display_progress_clear::@2#1] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // display_progress_clear::@2
  __b2:
    // for(unsigned char i = 0; i < w; i++)
    // [706] if(display_progress_clear::i#2<PROGRESS_W) goto display_progress_clear::@3 -- vbuz1_lt_vbuc1_then_la1 
    lda.z i
    cmp #PROGRESS_W
    bcc __b3
    // display_progress_clear::@4
    // y++;
    // [707] display_progress_clear::y#1 = ++ display_progress_clear::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [702] phi from display_progress_clear::@4 to display_progress_clear::@1 [phi:display_progress_clear::@4->display_progress_clear::@1]
    // [702] phi display_progress_clear::y#2 = display_progress_clear::y#1 [phi:display_progress_clear::@4->display_progress_clear::@1#0] -- register_copy 
    jmp __b1
    // display_progress_clear::@3
  __b3:
    // cputcxy(x, y, ' ')
    // [708] cputcxy::x#12 = display_progress_clear::x#2 -- vbuxx=vbuz1 
    ldx.z x
    // [709] cputcxy::y#12 = display_progress_clear::y#2 -- vbuyy=vbuz1 
    ldy.z y
    // [710] call cputcxy
    // [1495] phi from display_progress_clear::@3 to cputcxy [phi:display_progress_clear::@3->cputcxy]
    // [1495] phi cputcxy::c#13 = ' ' [phi:display_progress_clear::@3->cputcxy#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z cputcxy.c
    // [1495] phi cputcxy::y#13 = cputcxy::y#12 [phi:display_progress_clear::@3->cputcxy#1] -- register_copy 
    // [1495] phi cputcxy::x#13 = cputcxy::x#12 [phi:display_progress_clear::@3->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_progress_clear::@6
    // x++;
    // [711] display_progress_clear::x#1 = ++ display_progress_clear::x#2 -- vbuz1=_inc_vbuz1 
    inc.z x
    // for(unsigned char i = 0; i < w; i++)
    // [712] display_progress_clear::i#1 = ++ display_progress_clear::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [705] phi from display_progress_clear::@6 to display_progress_clear::@2 [phi:display_progress_clear::@6->display_progress_clear::@2]
    // [705] phi display_progress_clear::x#2 = display_progress_clear::x#1 [phi:display_progress_clear::@6->display_progress_clear::@2#0] -- register_copy 
    // [705] phi display_progress_clear::i#2 = display_progress_clear::i#1 [phi:display_progress_clear::@6->display_progress_clear::@2#1] -- register_copy 
    jmp __b2
}
  // display_chip_smc
display_chip_smc: {
    // display_smc_led(GREY)
    // [714] call display_smc_led
    // [1503] phi from display_chip_smc to display_smc_led [phi:display_chip_smc->display_smc_led]
    // [1503] phi display_smc_led::c#2 = GREY [phi:display_chip_smc->display_smc_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z display_smc_led.c
    jsr display_smc_led
    // [715] phi from display_chip_smc to display_chip_smc::@1 [phi:display_chip_smc->display_chip_smc::@1]
    // display_chip_smc::@1
    // display_print_chip(CHIP_SMC_X, CHIP_SMC_Y+2, CHIP_SMC_W, "SMC     ")
    // [716] call display_print_chip
    // [1509] phi from display_chip_smc::@1 to display_print_chip [phi:display_chip_smc::@1->display_print_chip]
    // [1509] phi display_print_chip::text#11 = display_chip_smc::text [phi:display_chip_smc::@1->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_print_chip.text_2
    lda #>text
    sta.z display_print_chip.text_2+1
    // [1509] phi display_print_chip::w#10 = 5 [phi:display_chip_smc::@1->display_print_chip#1] -- vbuz1=vbuc1 
    lda #5
    sta.z display_print_chip.w
    // [1509] phi display_print_chip::x#10 = 1 [phi:display_chip_smc::@1->display_print_chip#2] -- vbuz1=vbuc1 
    lda #1
    sta.z display_print_chip.x
    jsr display_print_chip
    // display_chip_smc::@return
    // }
    // [717] return 
    rts
  .segment Data
    text: .text "SMC     "
    .byte 0
}
.segment Code
  // display_chip_vera
display_chip_vera: {
    // display_vera_led(GREY)
    // [719] call display_vera_led
    // [1553] phi from display_chip_vera to display_vera_led [phi:display_chip_vera->display_vera_led]
    // [1553] phi display_vera_led::c#2 = GREY [phi:display_chip_vera->display_vera_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z display_vera_led.c
    jsr display_vera_led
    // [720] phi from display_chip_vera to display_chip_vera::@1 [phi:display_chip_vera->display_chip_vera::@1]
    // display_chip_vera::@1
    // display_print_chip(CHIP_VERA_X, CHIP_VERA_Y+2, CHIP_VERA_W, "VERA     ")
    // [721] call display_print_chip
    // [1509] phi from display_chip_vera::@1 to display_print_chip [phi:display_chip_vera::@1->display_print_chip]
    // [1509] phi display_print_chip::text#11 = display_chip_vera::text [phi:display_chip_vera::@1->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_print_chip.text_2
    lda #>text
    sta.z display_print_chip.text_2+1
    // [1509] phi display_print_chip::w#10 = 8 [phi:display_chip_vera::@1->display_print_chip#1] -- vbuz1=vbuc1 
    lda #8
    sta.z display_print_chip.w
    // [1509] phi display_print_chip::x#10 = 9 [phi:display_chip_vera::@1->display_print_chip#2] -- vbuz1=vbuc1 
    lda #9
    sta.z display_print_chip.x
    jsr display_print_chip
    // display_chip_vera::@return
    // }
    // [722] return 
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
    .label r = $a9
    .label display_chip_rom__11 = $f2
    // [724] phi from display_chip_rom to display_chip_rom::@1 [phi:display_chip_rom->display_chip_rom::@1]
    // [724] phi display_chip_rom::r#2 = 0 [phi:display_chip_rom->display_chip_rom::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z r
    // display_chip_rom::@1
  __b1:
    // for (unsigned char r = 0; r < 8; r++)
    // [725] if(display_chip_rom::r#2<8) goto display_chip_rom::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z r
    cmp #8
    bcc __b2
    // display_chip_rom::@return
    // }
    // [726] return 
    rts
    // [727] phi from display_chip_rom::@1 to display_chip_rom::@2 [phi:display_chip_rom::@1->display_chip_rom::@2]
    // display_chip_rom::@2
  __b2:
    // strcpy(rom, "ROM  ")
    // [728] call strcpy
    // [813] phi from display_chip_rom::@2 to strcpy [phi:display_chip_rom::@2->strcpy]
    // [813] phi strcpy::dst#0 = display_chip_rom::rom [phi:display_chip_rom::@2->strcpy#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z strcpy.dst
    lda #>rom
    sta.z strcpy.dst+1
    // [813] phi strcpy::src#0 = display_chip_rom::source [phi:display_chip_rom::@2->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // display_chip_rom::@5
    // strcat(rom, rom_size_strings[r])
    // [729] display_chip_rom::$11 = display_chip_rom::r#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z r
    asl
    sta.z display_chip_rom__11
    // [730] strcat::source#0 = rom_size_strings[display_chip_rom::$11] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda rom_size_strings,y
    sta.z strcat.source
    lda rom_size_strings+1,y
    sta.z strcat.source+1
    // [731] call strcat
    // [1559] phi from display_chip_rom::@5 to strcat [phi:display_chip_rom::@5->strcat]
    jsr strcat
    // display_chip_rom::@6
    // if(r)
    // [732] if(0==display_chip_rom::r#2) goto display_chip_rom::@3 -- 0_eq_vbuz1_then_la1 
    lda.z r
    beq __b3
    // display_chip_rom::@4
    // r+'0'
    // [733] display_chip_rom::$4 = display_chip_rom::r#2 + '0' -- vbuaa=vbuz1_plus_vbuc1 
    lda #'0'
    clc
    adc.z r
    // *(rom+3) = r+'0'
    // [734] *(display_chip_rom::rom+3) = display_chip_rom::$4 -- _deref_pbuc1=vbuaa 
    sta rom+3
    // display_chip_rom::@3
  __b3:
    // display_rom_led(r, GREY)
    // [735] display_rom_led::chip#0 = display_chip_rom::r#2 -- vbuz1=vbuz2 
    lda.z r
    sta.z display_rom_led.chip
    // [736] call display_rom_led
    // [1571] phi from display_chip_rom::@3 to display_rom_led [phi:display_chip_rom::@3->display_rom_led]
    // [1571] phi display_rom_led::c#2 = GREY [phi:display_chip_rom::@3->display_rom_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z display_rom_led.c
    // [1571] phi display_rom_led::chip#2 = display_rom_led::chip#0 [phi:display_chip_rom::@3->display_rom_led#1] -- register_copy 
    jsr display_rom_led
    // display_chip_rom::@7
    // r*6
    // [737] display_chip_rom::$12 = display_chip_rom::$11 + display_chip_rom::r#2 -- vbuaa=vbuz1_plus_vbuz2 
    lda.z display_chip_rom__11
    clc
    adc.z r
    // [738] display_chip_rom::$6 = display_chip_rom::$12 << 1 -- vbuaa=vbuaa_rol_1 
    asl
    // display_print_chip(CHIP_ROM_X+r*6, CHIP_ROM_Y+2, CHIP_ROM_W, rom)
    // [739] display_print_chip::x#2 = $14 + display_chip_rom::$6 -- vbuz1=vbuc1_plus_vbuaa 
    clc
    adc #$14
    sta.z display_print_chip.x
    // [740] call display_print_chip
    // [1509] phi from display_chip_rom::@7 to display_print_chip [phi:display_chip_rom::@7->display_print_chip]
    // [1509] phi display_print_chip::text#11 = display_chip_rom::rom [phi:display_chip_rom::@7->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z display_print_chip.text_2
    lda #>rom
    sta.z display_print_chip.text_2+1
    // [1509] phi display_print_chip::w#10 = 3 [phi:display_chip_rom::@7->display_print_chip#1] -- vbuz1=vbuc1 
    lda #3
    sta.z display_print_chip.w
    // [1509] phi display_print_chip::x#10 = display_print_chip::x#2 [phi:display_chip_rom::@7->display_print_chip#2] -- register_copy 
    jsr display_print_chip
    // display_chip_rom::@8
    // for (unsigned char r = 0; r < 8; r++)
    // [741] display_chip_rom::r#1 = ++ display_chip_rom::r#2 -- vbuz1=_inc_vbuz1 
    inc.z r
    // [724] phi from display_chip_rom::@8 to display_chip_rom::@1 [phi:display_chip_rom::@8->display_chip_rom::@1]
    // [724] phi display_chip_rom::r#2 = display_chip_rom::r#1 [phi:display_chip_rom::@8->display_chip_rom::@1#0] -- register_copy 
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
// void display_info_smc(__zp($65) char info_status, __zp($5b) char *info_text)
display_info_smc: {
    .label x = $ef
    .label y = $b3
    .label info_status = $65
    .label info_text = $5b
    // unsigned char x = wherex()
    // [743] call wherex
    jsr wherex
    // [744] wherex::return#10 = wherex::return#0
    // display_info_smc::@3
    // [745] display_info_smc::x#0 = wherex::return#10 -- vbuz1=vbuaa 
    sta.z x
    // unsigned char y = wherey()
    // [746] call wherey
    jsr wherey
    // [747] wherey::return#10 = wherey::return#0
    // display_info_smc::@4
    // [748] display_info_smc::y#0 = wherey::return#10 -- vbuz1=vbuaa 
    sta.z y
    // status_smc = info_status
    // [749] status_smc#0 = display_info_smc::info_status#11 -- vbum1=vbuz2 
    lda.z info_status
    sta status_smc
    // display_smc_led(status_color[info_status])
    // [750] display_smc_led::c#1 = status_color[display_info_smc::info_status#11] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z display_smc_led.c
    // [751] call display_smc_led
    // [1503] phi from display_info_smc::@4 to display_smc_led [phi:display_info_smc::@4->display_smc_led]
    // [1503] phi display_smc_led::c#2 = display_smc_led::c#1 [phi:display_info_smc::@4->display_smc_led#0] -- register_copy 
    jsr display_smc_led
    // [752] phi from display_info_smc::@4 to display_info_smc::@5 [phi:display_info_smc::@4->display_info_smc::@5]
    // display_info_smc::@5
    // gotoxy(INFO_X, INFO_Y)
    // [753] call gotoxy
    // [590] phi from display_info_smc::@5 to gotoxy [phi:display_info_smc::@5->gotoxy]
    // [590] phi gotoxy::y#24 = $11 [phi:display_info_smc::@5->gotoxy#0] -- vbuyy=vbuc1 
    ldy #$11
    // [590] phi gotoxy::x#24 = 4 [phi:display_info_smc::@5->gotoxy#1] -- vbuxx=vbuc1 
    ldx #4
    jsr gotoxy
    // [754] phi from display_info_smc::@5 to display_info_smc::@6 [phi:display_info_smc::@5->display_info_smc::@6]
    // display_info_smc::@6
    // printf("SMC  %-9s ATTiny v%s ", status_text[info_status], smc_version_string)
    // [755] call printf_str
    // [850] phi from display_info_smc::@6 to printf_str [phi:display_info_smc::@6->printf_str]
    // [850] phi printf_str::putc#48 = &cputc [phi:display_info_smc::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = display_info_smc::s [phi:display_info_smc::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@7
    // printf("SMC  %-9s ATTiny v%s ", status_text[info_status], smc_version_string)
    // [756] display_info_smc::$8 = display_info_smc::info_status#11 << 1 -- vbuaa=vbuz1_rol_1 
    lda.z info_status
    asl
    // [757] printf_string::str#3 = status_text[display_info_smc::$8] -- pbuz1=qbuc1_derefidx_vbuaa 
    tay
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [758] call printf_string
    // [993] phi from display_info_smc::@7 to printf_string [phi:display_info_smc::@7->printf_string]
    // [993] phi printf_string::putc#21 = &cputc [phi:display_info_smc::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [993] phi printf_string::str#21 = printf_string::str#3 [phi:display_info_smc::@7->printf_string#1] -- register_copy 
    // [993] phi printf_string::format_justify_left#21 = 1 [phi:display_info_smc::@7->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [993] phi printf_string::format_min_length#21 = 9 [phi:display_info_smc::@7->printf_string#3] -- vbuz1=vbuc1 
    lda #9
    sta.z printf_string.format_min_length
    jsr printf_string
    // [759] phi from display_info_smc::@7 to display_info_smc::@8 [phi:display_info_smc::@7->display_info_smc::@8]
    // display_info_smc::@8
    // printf("SMC  %-9s ATTiny v%s ", status_text[info_status], smc_version_string)
    // [760] call printf_str
    // [850] phi from display_info_smc::@8 to printf_str [phi:display_info_smc::@8->printf_str]
    // [850] phi printf_str::putc#48 = &cputc [phi:display_info_smc::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = display_info_smc::s1 [phi:display_info_smc::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // [761] phi from display_info_smc::@8 to display_info_smc::@9 [phi:display_info_smc::@8->display_info_smc::@9]
    // display_info_smc::@9
    // printf("SMC  %-9s ATTiny v%s ", status_text[info_status], smc_version_string)
    // [762] call printf_string
    // [993] phi from display_info_smc::@9 to printf_string [phi:display_info_smc::@9->printf_string]
    // [993] phi printf_string::putc#21 = &cputc [phi:display_info_smc::@9->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [993] phi printf_string::str#21 = smc_version_string [phi:display_info_smc::@9->printf_string#1] -- pbuz1=pbuc1 
    lda #<smc_version_string
    sta.z printf_string.str
    lda #>smc_version_string
    sta.z printf_string.str+1
    // [993] phi printf_string::format_justify_left#21 = 0 [phi:display_info_smc::@9->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [993] phi printf_string::format_min_length#21 = 0 [phi:display_info_smc::@9->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [763] phi from display_info_smc::@9 to display_info_smc::@10 [phi:display_info_smc::@9->display_info_smc::@10]
    // display_info_smc::@10
    // printf("SMC  %-9s ATTiny v%s ", status_text[info_status], smc_version_string)
    // [764] call printf_str
    // [850] phi from display_info_smc::@10 to printf_str [phi:display_info_smc::@10->printf_str]
    // [850] phi printf_str::putc#48 = &cputc [phi:display_info_smc::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = s2 [phi:display_info_smc::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@11
    // if(info_text)
    // [765] if((char *)0==display_info_smc::info_text#11) goto display_info_smc::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // display_info_smc::@2
    // printf("%-25s", info_text)
    // [766] printf_string::str#5 = display_info_smc::info_text#11 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [767] call printf_string
    // [993] phi from display_info_smc::@2 to printf_string [phi:display_info_smc::@2->printf_string]
    // [993] phi printf_string::putc#21 = &cputc [phi:display_info_smc::@2->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [993] phi printf_string::str#21 = printf_string::str#5 [phi:display_info_smc::@2->printf_string#1] -- register_copy 
    // [993] phi printf_string::format_justify_left#21 = 1 [phi:display_info_smc::@2->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [993] phi printf_string::format_min_length#21 = $19 [phi:display_info_smc::@2->printf_string#3] -- vbuz1=vbuc1 
    lda #$19
    sta.z printf_string.format_min_length
    jsr printf_string
    // display_info_smc::@1
  __b1:
    // gotoxy(x, y)
    // [768] gotoxy::x#14 = display_info_smc::x#0 -- vbuxx=vbuz1 
    ldx.z x
    // [769] gotoxy::y#14 = display_info_smc::y#0 -- vbuyy=vbuz1 
    ldy.z y
    // [770] call gotoxy
    // [590] phi from display_info_smc::@1 to gotoxy [phi:display_info_smc::@1->gotoxy]
    // [590] phi gotoxy::y#24 = gotoxy::y#14 [phi:display_info_smc::@1->gotoxy#0] -- register_copy 
    // [590] phi gotoxy::x#24 = gotoxy::x#14 [phi:display_info_smc::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_smc::@return
    // }
    // [771] return 
    rts
  .segment Data
    s: .text "SMC  "
    .byte 0
    s1: .text " ATTiny v"
    .byte 0
}
.segment Code
  // display_info_vera
/**
 * @brief Display the VERA status at the info frame.
 * 
 * @param info_status The STATUS_ 
 */
// void display_info_vera(__zp($7f) char info_status, __zp($23) char *info_text)
display_info_vera: {
    .label x = $59
    .label y = $e9
    .label info_status = $7f
    .label info_text = $23
    // unsigned char x = wherex()
    // [773] call wherex
    jsr wherex
    // [774] wherex::return#11 = wherex::return#0
    // display_info_vera::@3
    // [775] display_info_vera::x#0 = wherex::return#11 -- vbuz1=vbuaa 
    sta.z x
    // unsigned char y = wherey()
    // [776] call wherey
    jsr wherey
    // [777] wherey::return#11 = wherey::return#0
    // display_info_vera::@4
    // [778] display_info_vera::y#0 = wherey::return#11 -- vbuz1=vbuaa 
    sta.z y
    // status_vera = info_status
    // [779] status_vera#0 = display_info_vera::info_status#3 -- vbum1=vbuz2 
    lda.z info_status
    sta status_vera
    // display_vera_led(status_color[info_status])
    // [780] display_vera_led::c#1 = status_color[display_info_vera::info_status#3] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z display_vera_led.c
    // [781] call display_vera_led
    // [1553] phi from display_info_vera::@4 to display_vera_led [phi:display_info_vera::@4->display_vera_led]
    // [1553] phi display_vera_led::c#2 = display_vera_led::c#1 [phi:display_info_vera::@4->display_vera_led#0] -- register_copy 
    jsr display_vera_led
    // [782] phi from display_info_vera::@4 to display_info_vera::@5 [phi:display_info_vera::@4->display_info_vera::@5]
    // display_info_vera::@5
    // gotoxy(INFO_X, INFO_Y+1)
    // [783] call gotoxy
    // [590] phi from display_info_vera::@5 to gotoxy [phi:display_info_vera::@5->gotoxy]
    // [590] phi gotoxy::y#24 = $11+1 [phi:display_info_vera::@5->gotoxy#0] -- vbuyy=vbuc1 
    ldy #$11+1
    // [590] phi gotoxy::x#24 = 4 [phi:display_info_vera::@5->gotoxy#1] -- vbuxx=vbuc1 
    ldx #4
    jsr gotoxy
    // [784] phi from display_info_vera::@5 to display_info_vera::@6 [phi:display_info_vera::@5->display_info_vera::@6]
    // display_info_vera::@6
    // printf("VERA %-9s FPGA                 ", status_text[info_status])
    // [785] call printf_str
    // [850] phi from display_info_vera::@6 to printf_str [phi:display_info_vera::@6->printf_str]
    // [850] phi printf_str::putc#48 = &cputc [phi:display_info_vera::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = display_info_vera::s [phi:display_info_vera::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@7
    // printf("VERA %-9s FPGA                 ", status_text[info_status])
    // [786] display_info_vera::$8 = display_info_vera::info_status#3 << 1 -- vbuaa=vbuz1_rol_1 
    lda.z info_status
    asl
    // [787] printf_string::str#6 = status_text[display_info_vera::$8] -- pbuz1=qbuc1_derefidx_vbuaa 
    tay
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [788] call printf_string
    // [993] phi from display_info_vera::@7 to printf_string [phi:display_info_vera::@7->printf_string]
    // [993] phi printf_string::putc#21 = &cputc [phi:display_info_vera::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [993] phi printf_string::str#21 = printf_string::str#6 [phi:display_info_vera::@7->printf_string#1] -- register_copy 
    // [993] phi printf_string::format_justify_left#21 = 1 [phi:display_info_vera::@7->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [993] phi printf_string::format_min_length#21 = 9 [phi:display_info_vera::@7->printf_string#3] -- vbuz1=vbuc1 
    lda #9
    sta.z printf_string.format_min_length
    jsr printf_string
    // [789] phi from display_info_vera::@7 to display_info_vera::@8 [phi:display_info_vera::@7->display_info_vera::@8]
    // display_info_vera::@8
    // printf("VERA %-9s FPGA                 ", status_text[info_status])
    // [790] call printf_str
    // [850] phi from display_info_vera::@8 to printf_str [phi:display_info_vera::@8->printf_str]
    // [850] phi printf_str::putc#48 = &cputc [phi:display_info_vera::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = display_info_vera::s1 [phi:display_info_vera::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@9
    // if(info_text)
    // [791] if((char *)0==display_info_vera::info_text#10) goto display_info_vera::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // display_info_vera::@2
    // printf("%-25s", info_text)
    // [792] printf_string::str#7 = display_info_vera::info_text#10 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [793] call printf_string
    // [993] phi from display_info_vera::@2 to printf_string [phi:display_info_vera::@2->printf_string]
    // [993] phi printf_string::putc#21 = &cputc [phi:display_info_vera::@2->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [993] phi printf_string::str#21 = printf_string::str#7 [phi:display_info_vera::@2->printf_string#1] -- register_copy 
    // [993] phi printf_string::format_justify_left#21 = 1 [phi:display_info_vera::@2->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [993] phi printf_string::format_min_length#21 = $19 [phi:display_info_vera::@2->printf_string#3] -- vbuz1=vbuc1 
    lda #$19
    sta.z printf_string.format_min_length
    jsr printf_string
    // display_info_vera::@1
  __b1:
    // gotoxy(x, y)
    // [794] gotoxy::x#16 = display_info_vera::x#0 -- vbuxx=vbuz1 
    ldx.z x
    // [795] gotoxy::y#16 = display_info_vera::y#0 -- vbuyy=vbuz1 
    ldy.z y
    // [796] call gotoxy
    // [590] phi from display_info_vera::@1 to gotoxy [phi:display_info_vera::@1->gotoxy]
    // [590] phi gotoxy::y#24 = gotoxy::y#16 [phi:display_info_vera::@1->gotoxy#0] -- register_copy 
    // [590] phi gotoxy::x#24 = gotoxy::x#16 [phi:display_info_vera::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_vera::@return
    // }
    // [797] return 
    rts
  .segment Data
    s: .text "VERA "
    .byte 0
    s1: .text " FPGA                 "
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
// void display_progress_text(__zp($4f) char **text, __zp($63) char lines)
display_progress_text: {
    .label l = $70
    .label lines = $63
    .label text = $4f
    // display_progress_clear()
    // [799] call display_progress_clear
    // [698] phi from display_progress_text to display_progress_clear [phi:display_progress_text->display_progress_clear]
    jsr display_progress_clear
    // [800] phi from display_progress_text to display_progress_text::@1 [phi:display_progress_text->display_progress_text::@1]
    // [800] phi display_progress_text::l#2 = 0 [phi:display_progress_text->display_progress_text::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z l
    // display_progress_text::@1
  __b1:
    // for(unsigned char l=0; l<lines; l++)
    // [801] if(display_progress_text::l#2<display_progress_text::lines#11) goto display_progress_text::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z l
    cmp.z lines
    bcc __b2
    // display_progress_text::@return
    // }
    // [802] return 
    rts
    // display_progress_text::@2
  __b2:
    // display_progress_line(l, text[l])
    // [803] display_progress_text::$3 = display_progress_text::l#2 << 1 -- vbuaa=vbuz1_rol_1 
    lda.z l
    asl
    // [804] display_progress_line::line#0 = display_progress_text::l#2 -- vbuxx=vbuz1 
    ldx.z l
    // [805] display_progress_line::text#0 = display_progress_text::text#10[display_progress_text::$3] -- pbuz1=qbuz2_derefidx_vbuaa 
    tay
    lda (text),y
    sta.z display_progress_line.text
    iny
    lda (text),y
    sta.z display_progress_line.text+1
    // [806] call display_progress_line
    jsr display_progress_line
    // display_progress_text::@3
    // for(unsigned char l=0; l<lines; l++)
    // [807] display_progress_text::l#1 = ++ display_progress_text::l#2 -- vbuz1=_inc_vbuz1 
    inc.z l
    // [800] phi from display_progress_text::@3 to display_progress_text::@1 [phi:display_progress_text::@3->display_progress_text::@1]
    // [800] phi display_progress_text::l#2 = display_progress_text::l#1 [phi:display_progress_text::@3->display_progress_text::@1#0] -- register_copy 
    jmp __b1
}
  // util_wait_space
util_wait_space: {
    // util_wait_key("Press [SPACE] to continue ...", " ")
    // [809] call util_wait_key
    // [1062] phi from util_wait_space to util_wait_key [phi:util_wait_space->util_wait_key]
    // [1062] phi util_wait_key::filter#12 = s2 [phi:util_wait_space->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<s2
    sta.z util_wait_key.filter
    lda #>s2
    sta.z util_wait_key.filter+1
    // [1062] phi util_wait_key::info_text#2 = util_wait_space::info_text [phi:util_wait_space->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z util_wait_key.info_text
    lda #>info_text
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // util_wait_space::@return
    // }
    // [810] return 
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
    // [812] return 
    rts
}
  // strcpy
// Copies the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcpy(__zp($3e) char *destination, char *source)
strcpy: {
    .label src = $3a
    .label dst = $3e
    .label destination = $3e
    // [814] phi from strcpy strcpy::@2 to strcpy::@1 [phi:strcpy/strcpy::@2->strcpy::@1]
    // [814] phi strcpy::dst#2 = strcpy::dst#0 [phi:strcpy/strcpy::@2->strcpy::@1#0] -- register_copy 
    // [814] phi strcpy::src#2 = strcpy::src#0 [phi:strcpy/strcpy::@2->strcpy::@1#1] -- register_copy 
    // strcpy::@1
  __b1:
    // while(*src)
    // [815] if(0!=*strcpy::src#2) goto strcpy::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcpy::@3
    // *dst = 0
    // [816] *strcpy::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcpy::@return
    // }
    // [817] return 
    rts
    // strcpy::@2
  __b2:
    // *dst++ = *src++
    // [818] *strcpy::dst#2 = *strcpy::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [819] strcpy::dst#1 = ++ strcpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [820] strcpy::src#1 = ++ strcpy::src#2 -- pbuz1=_inc_pbuz1 
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
// __zp($5d) unsigned int cx16_k_i2c_read_byte(__mem() volatile char device, __mem() volatile char offset)
cx16_k_i2c_read_byte: {
    .label return = $5d
    .label return_1 = $ab
    .label return_2 = $ae
    // unsigned int result
    // [821] cx16_k_i2c_read_byte::result = 0 -- vwum1=vwuc1 
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
    // [823] cx16_k_i2c_read_byte::return#0 = cx16_k_i2c_read_byte::result -- vwuz1=vwum2 
    sta.z return
    lda result+1
    sta.z return+1
    // cx16_k_i2c_read_byte::@return
    // }
    // [824] cx16_k_i2c_read_byte::return#1 = cx16_k_i2c_read_byte::return#0
    // [825] return 
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
// unsigned long smc_get_version_text(__zp($5b) char *version_string, __register(X) char release, __zp($bf) char major, __zp($7b) char minor)
smc_get_version_text: {
    .label major = $bf
    .label minor = $7b
    .label version_string = $5b
    // sprintf(version_string, "%u.%u.%u ", release, major, minor)
    // [827] snprintf_init::s#0 = smc_get_version_text::version_string#2
    // [828] call snprintf_init
    // [845] phi from smc_get_version_text to snprintf_init [phi:smc_get_version_text->snprintf_init]
    // [845] phi snprintf_init::s#15 = snprintf_init::s#0 [phi:smc_get_version_text->snprintf_init#0] -- register_copy 
    jsr snprintf_init
    // smc_get_version_text::@1
    // sprintf(version_string, "%u.%u.%u ", release, major, minor)
    // [829] printf_uchar::uvalue#1 = smc_get_version_text::release#2
    // [830] call printf_uchar
    // [1028] phi from smc_get_version_text::@1 to printf_uchar [phi:smc_get_version_text::@1->printf_uchar]
    // [1028] phi printf_uchar::format_zero_padding#10 = 0 [phi:smc_get_version_text::@1->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1028] phi printf_uchar::format_min_length#10 = 0 [phi:smc_get_version_text::@1->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1028] phi printf_uchar::putc#10 = &snputc [phi:smc_get_version_text::@1->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1028] phi printf_uchar::format_radix#10 = DECIMAL [phi:smc_get_version_text::@1->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [1028] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#1 [phi:smc_get_version_text::@1->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [831] phi from smc_get_version_text::@1 to smc_get_version_text::@2 [phi:smc_get_version_text::@1->smc_get_version_text::@2]
    // smc_get_version_text::@2
    // sprintf(version_string, "%u.%u.%u ", release, major, minor)
    // [832] call printf_str
    // [850] phi from smc_get_version_text::@2 to printf_str [phi:smc_get_version_text::@2->printf_str]
    // [850] phi printf_str::putc#48 = &snputc [phi:smc_get_version_text::@2->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = smc_get_version_text::s [phi:smc_get_version_text::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_get_version_text::@3
    // sprintf(version_string, "%u.%u.%u ", release, major, minor)
    // [833] printf_uchar::uvalue#2 = smc_get_version_text::major#2 -- vbuxx=vbuz1 
    ldx.z major
    // [834] call printf_uchar
    // [1028] phi from smc_get_version_text::@3 to printf_uchar [phi:smc_get_version_text::@3->printf_uchar]
    // [1028] phi printf_uchar::format_zero_padding#10 = 0 [phi:smc_get_version_text::@3->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1028] phi printf_uchar::format_min_length#10 = 0 [phi:smc_get_version_text::@3->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1028] phi printf_uchar::putc#10 = &snputc [phi:smc_get_version_text::@3->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1028] phi printf_uchar::format_radix#10 = DECIMAL [phi:smc_get_version_text::@3->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [1028] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#2 [phi:smc_get_version_text::@3->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [835] phi from smc_get_version_text::@3 to smc_get_version_text::@4 [phi:smc_get_version_text::@3->smc_get_version_text::@4]
    // smc_get_version_text::@4
    // sprintf(version_string, "%u.%u.%u ", release, major, minor)
    // [836] call printf_str
    // [850] phi from smc_get_version_text::@4 to printf_str [phi:smc_get_version_text::@4->printf_str]
    // [850] phi printf_str::putc#48 = &snputc [phi:smc_get_version_text::@4->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = smc_get_version_text::s [phi:smc_get_version_text::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_get_version_text::@5
    // sprintf(version_string, "%u.%u.%u ", release, major, minor)
    // [837] printf_uchar::uvalue#3 = smc_get_version_text::minor#2 -- vbuxx=vbuz1 
    ldx.z minor
    // [838] call printf_uchar
    // [1028] phi from smc_get_version_text::@5 to printf_uchar [phi:smc_get_version_text::@5->printf_uchar]
    // [1028] phi printf_uchar::format_zero_padding#10 = 0 [phi:smc_get_version_text::@5->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1028] phi printf_uchar::format_min_length#10 = 0 [phi:smc_get_version_text::@5->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1028] phi printf_uchar::putc#10 = &snputc [phi:smc_get_version_text::@5->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1028] phi printf_uchar::format_radix#10 = DECIMAL [phi:smc_get_version_text::@5->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [1028] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#3 [phi:smc_get_version_text::@5->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [839] phi from smc_get_version_text::@5 to smc_get_version_text::@6 [phi:smc_get_version_text::@5->smc_get_version_text::@6]
    // smc_get_version_text::@6
    // sprintf(version_string, "%u.%u.%u ", release, major, minor)
    // [840] call printf_str
    // [850] phi from smc_get_version_text::@6 to printf_str [phi:smc_get_version_text::@6->printf_str]
    // [850] phi printf_str::putc#48 = &snputc [phi:smc_get_version_text::@6->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = s2 [phi:smc_get_version_text::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // smc_get_version_text::@7
    // sprintf(version_string, "%u.%u.%u ", release, major, minor)
    // [841] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [842] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_get_version_text::@return
    // }
    // [844] return 
    rts
  .segment Data
    s: .text "."
    .byte 0
}
.segment Code
  // snprintf_init
/// Initialize the snprintf() state
// void snprintf_init(__zp($5b) char *s, unsigned int n)
snprintf_init: {
    .label s = $5b
    // __snprintf_capacity = n
    // [846] __snprintf_capacity = $ffff -- vwum1=vwuc1 
    lda #<$ffff
    sta __snprintf_capacity
    lda #>$ffff
    sta __snprintf_capacity+1
    // __snprintf_size = 0
    // [847] __snprintf_size = 0 -- vwum1=vbuc1 
    lda #<0
    sta __snprintf_size
    sta __snprintf_size+1
    // __snprintf_buffer = s
    // [848] __snprintf_buffer = snprintf_init::s#15 -- pbuz1=pbuz2 
    lda.z s
    sta.z __snprintf_buffer
    lda.z s+1
    sta.z __snprintf_buffer+1
    // snprintf_init::@return
    // }
    // [849] return 
    rts
}
  // printf_str
/// Print a NUL-terminated string
// void printf_str(__zp($4f) void (*putc)(char), __zp($3e) const char *s)
printf_str: {
    .label s = $3e
    .label putc = $4f
    // [851] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [851] phi printf_str::s#47 = printf_str::s#48 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [852] printf_str::c#1 = *printf_str::s#47 -- vbuaa=_deref_pbuz1 
    ldy #0
    lda (s),y
    // [853] printf_str::s#0 = ++ printf_str::s#47 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [854] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbuaa_then_la1 
    cmp #0
    bne __b2
    // printf_str::@return
    // }
    // [855] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [856] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbuaa 
    pha
    // [857] callexecute *printf_str::putc#48  -- call__deref_pprz1 
    jsr icall11
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
    // Outside Flow
  icall11:
    jmp (putc)
}
  // printf_uint
// Print an unsigned int using a specific format
// void printf_uint(void (*putc)(char), __zp($23) unsigned int uvalue, __zp($78) char format_min_length, char format_justify_left, char format_sign_always, __zp($65) char format_zero_padding, char format_upper_case, __register(X) char format_radix)
printf_uint: {
    .label uvalue = $23
    .label format_min_length = $78
    .label format_zero_padding = $65
    // printf_uint::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [860] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [861] utoa::value#1 = printf_uint::uvalue#10
    // [862] utoa::radix#0 = printf_uint::format_radix#10
    // [863] call utoa
    // Format number into buffer
    jsr utoa
    // printf_uint::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [864] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [865] printf_number_buffer::format_min_length#1 = printf_uint::format_min_length#10 -- vbuxx=vbuz1 
    ldx.z format_min_length
    // [866] printf_number_buffer::format_zero_padding#1 = printf_uint::format_zero_padding#10
    // [867] call printf_number_buffer
  // Print using format
    // [1616] phi from printf_uint::@2 to printf_number_buffer [phi:printf_uint::@2->printf_number_buffer]
    // [1616] phi printf_number_buffer::putc#10 = &snputc [phi:printf_uint::@2->printf_number_buffer#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_number_buffer.putc
    lda #>snputc
    sta.z printf_number_buffer.putc+1
    // [1616] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_uint::@2->printf_number_buffer#1] -- register_copy 
    // [1616] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#1 [phi:printf_uint::@2->printf_number_buffer#2] -- register_copy 
    // [1616] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#1 [phi:printf_uint::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uint::@return
    // }
    // [868] return 
    rts
}
  // rom_detect
rom_detect: {
    .const bank_set_brom1_bank = 4
    .label rom_detect__19 = $ee
    .label rom_detect__29 = $ec
    .label rom_chip = $cf
    .label rom_detect_address = $25
    // [870] phi from rom_detect to rom_detect::@1 [phi:rom_detect->rom_detect::@1]
    // [870] phi rom_detect::rom_chip#10 = 0 [phi:rom_detect->rom_detect::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_chip
    // [870] phi rom_detect::rom_detect_address#10 = 0 [phi:rom_detect->rom_detect::@1#1] -- vduz1=vduc1 
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
    // [871] if(rom_detect::rom_detect_address#10<8*$80000) goto rom_detect::@2 -- vduz1_lt_vduc1_then_la1 
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
    // [872] return 
    rts
    // rom_detect::@2
  __b2:
    // rom_manufacturer_ids[rom_chip] = 0
    // [873] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    ldy.z rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = 0
    // [874] rom_device_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta rom_device_ids,y
    // if (rom_detect_address == 0x0)
    // [875] if(rom_detect::rom_detect_address#10!=0) goto rom_detect::@3 -- vduz1_neq_0_then_la1 
    lda.z rom_detect_address
    ora.z rom_detect_address+1
    ora.z rom_detect_address+2
    ora.z rom_detect_address+3
    bne __b3
    // rom_detect::@14
    // rom_manufacturer_ids[rom_chip] = 0x9f
    // [876] rom_manufacturer_ids[rom_detect::rom_chip#10] = $9f -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$9f
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF040
    // [877] rom_device_ids[rom_detect::rom_chip#10] = $b7 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$b7
    sta rom_device_ids,y
    // rom_detect::@3
  __b3:
    // if (rom_detect_address == 0x80000)
    // [878] if(rom_detect::rom_detect_address#10!=$80000) goto rom_detect::@4 -- vduz1_neq_vduc1_then_la1 
    lda.z rom_detect_address+3
    cmp #>$80000>>$10
    bne __b4
    lda.z rom_detect_address+2
    cmp #<$80000>>$10
    bne __b4
    lda.z rom_detect_address+1
    cmp #>$80000
    bne __b4
    lda.z rom_detect_address
    cmp #<$80000
    bne __b4
    // rom_detect::@15
    // rom_manufacturer_ids[rom_chip] = 0x9f
    // [879] rom_manufacturer_ids[rom_detect::rom_chip#10] = $9f -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$9f
    ldy.z rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF040
    // [880] rom_device_ids[rom_detect::rom_chip#10] = $b7 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$b7
    sta rom_device_ids,y
    // rom_detect::@4
  __b4:
    // if (rom_detect_address == 0x100000)
    // [881] if(rom_detect::rom_detect_address#10!=$100000) goto rom_detect::@5 -- vduz1_neq_vduc1_then_la1 
    lda.z rom_detect_address+3
    cmp #>$100000>>$10
    bne __b5
    lda.z rom_detect_address+2
    cmp #<$100000>>$10
    bne __b5
    lda.z rom_detect_address+1
    cmp #>$100000
    bne __b5
    lda.z rom_detect_address
    cmp #<$100000
    bne __b5
    // rom_detect::@16
    // rom_manufacturer_ids[rom_chip] = 0x9f
    // [882] rom_manufacturer_ids[rom_detect::rom_chip#10] = $9f -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$9f
    ldy.z rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF020A
    // [883] rom_device_ids[rom_detect::rom_chip#10] = $b6 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$b6
    sta rom_device_ids,y
    // rom_detect::@5
  __b5:
    // if (rom_detect_address == 0x180000)
    // [884] if(rom_detect::rom_detect_address#10!=$180000) goto rom_detect::@6 -- vduz1_neq_vduc1_then_la1 
    lda.z rom_detect_address+3
    cmp #>$180000>>$10
    bne __b6
    lda.z rom_detect_address+2
    cmp #<$180000>>$10
    bne __b6
    lda.z rom_detect_address+1
    cmp #>$180000
    bne __b6
    lda.z rom_detect_address
    cmp #<$180000
    bne __b6
    // rom_detect::@17
    // rom_manufacturer_ids[rom_chip] = 0x9f
    // [885] rom_manufacturer_ids[rom_detect::rom_chip#10] = $9f -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$9f
    ldy.z rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF010A
    // [886] rom_device_ids[rom_detect::rom_chip#10] = $b5 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$b5
    sta rom_device_ids,y
    // rom_detect::@6
  __b6:
    // if (rom_detect_address == 0x200000)
    // [887] if(rom_detect::rom_detect_address#10!=$200000) goto rom_detect::@7 -- vduz1_neq_vduc1_then_la1 
    lda.z rom_detect_address+3
    cmp #>$200000>>$10
    bne __b7
    lda.z rom_detect_address+2
    cmp #<$200000>>$10
    bne __b7
    lda.z rom_detect_address+1
    cmp #>$200000
    bne __b7
    lda.z rom_detect_address
    cmp #<$200000
    bne __b7
    // rom_detect::@18
    // rom_manufacturer_ids[rom_chip] = 0x9f
    // [888] rom_manufacturer_ids[rom_detect::rom_chip#10] = $9f -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$9f
    ldy.z rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF040
    // [889] rom_device_ids[rom_detect::rom_chip#10] = $b7 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$b7
    sta rom_device_ids,y
    // rom_detect::@7
  __b7:
    // if (rom_detect_address == 0x280000)
    // [890] if(rom_detect::rom_detect_address#10!=$280000) goto rom_detect::bank_set_brom1 -- vduz1_neq_vduc1_then_la1 
    lda.z rom_detect_address+3
    cmp #>$280000>>$10
    bne bank_set_brom1
    lda.z rom_detect_address+2
    cmp #<$280000>>$10
    bne bank_set_brom1
    lda.z rom_detect_address+1
    cmp #>$280000
    bne bank_set_brom1
    lda.z rom_detect_address
    cmp #<$280000
    bne bank_set_brom1
    // rom_detect::@19
    // rom_manufacturer_ids[rom_chip] = 0x9f
    // [891] rom_manufacturer_ids[rom_detect::rom_chip#10] = $9f -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$9f
    ldy.z rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF040
    // [892] rom_device_ids[rom_detect::rom_chip#10] = $b7 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$b7
    sta rom_device_ids,y
    // rom_detect::bank_set_brom1
  bank_set_brom1:
    // BROM = bank
    // [893] BROM = rom_detect::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // rom_detect::@22
    // rom_chip*3
    // [894] rom_detect::$19 = rom_detect::rom_chip#10 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta.z rom_detect__19
    // [895] rom_detect::$14 = rom_detect::$19 + rom_detect::rom_chip#10 -- vbuaa=vbuz1_plus_vbuz2 
    clc
    adc.z rom_chip
    // gotoxy(rom_chip*3+40, 1)
    // [896] gotoxy::x#21 = rom_detect::$14 + $28 -- vbuxx=vbuaa_plus_vbuc1 
    clc
    adc #$28
    tax
    // [897] call gotoxy
    // [590] phi from rom_detect::@22 to gotoxy [phi:rom_detect::@22->gotoxy]
    // [590] phi gotoxy::y#24 = 1 [phi:rom_detect::@22->gotoxy#0] -- vbuyy=vbuc1 
    ldy #1
    // [590] phi gotoxy::x#24 = gotoxy::x#21 [phi:rom_detect::@22->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_detect::@23
    // printf("%02x", rom_device_ids[rom_chip])
    // [898] printf_uchar::uvalue#5 = rom_device_ids[rom_detect::rom_chip#10] -- vbuxx=pbuc1_derefidx_vbuz1 
    ldy.z rom_chip
    ldx rom_device_ids,y
    // [899] call printf_uchar
    // [1028] phi from rom_detect::@23 to printf_uchar [phi:rom_detect::@23->printf_uchar]
    // [1028] phi printf_uchar::format_zero_padding#10 = 1 [phi:rom_detect::@23->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1028] phi printf_uchar::format_min_length#10 = 2 [phi:rom_detect::@23->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [1028] phi printf_uchar::putc#10 = &cputc [phi:rom_detect::@23->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1028] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:rom_detect::@23->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #HEXADECIMAL
    // [1028] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#5 [phi:rom_detect::@23->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // rom_detect::@24
    // case SST39SF010A:
    //             rom_device_names[rom_chip] = "f010a";
    //             rom_size_strings[rom_chip] = "128";
    //             rom_sizes[rom_chip] = 128 * 1024;
    //             break;
    // [900] if(rom_device_ids[rom_detect::rom_chip#10]==$b5) goto rom_detect::@8 -- pbuc1_derefidx_vbuz1_eq_vbuc2_then_la1 
    ldy.z rom_chip
    lda rom_device_ids,y
    cmp #$b5
    bne !__b8+
    jmp __b8
  !__b8:
    // rom_detect::@20
    // case SST39SF020A:
    //             rom_device_names[rom_chip] = "f020a";
    //             rom_size_strings[rom_chip] = "256";
    //             rom_sizes[rom_chip] = 256 * 1024;
    //             break;
    // [901] if(rom_device_ids[rom_detect::rom_chip#10]==$b6) goto rom_detect::@9 -- pbuc1_derefidx_vbuz1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b6
    bne !__b9+
    jmp __b9
  !__b9:
    // rom_detect::@21
    // case SST39SF040:
    //             rom_device_names[rom_chip] = "f040";
    //             rom_size_strings[rom_chip] = "512";
    //             rom_sizes[rom_chip] = 512 * 1024;
    //             break;
    // [902] if(rom_device_ids[rom_detect::rom_chip#10]==$b7) goto rom_detect::@10 -- pbuc1_derefidx_vbuz1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b7
    beq __b10
    // rom_detect::@11
    // rom_manufacturer_ids[rom_chip] = 0
    // [903] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    sta rom_manufacturer_ids,y
    // rom_device_names[rom_chip] = "----"
    // [904] rom_device_names[rom_detect::$19] = rom_detect::$36 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__19
    lda #<rom_detect__36
    sta rom_device_names,y
    lda #>rom_detect__36
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "000"
    // [905] rom_size_strings[rom_detect::$19] = rom_detect::$37 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__37
    sta rom_size_strings,y
    lda #>rom_detect__37
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 0
    // [906] rom_detect::$29 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta.z rom_detect__29
    // [907] rom_sizes[rom_detect::$29] = 0 -- pduc1_derefidx_vbuz1=vbuc2 
    tay
    lda #0
    sta rom_sizes,y
    sta rom_sizes+1,y
    sta rom_sizes+2,y
    sta rom_sizes+3,y
    // rom_device_ids[rom_chip] = UNKNOWN
    // [908] rom_device_ids[rom_detect::rom_chip#10] = $55 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$55
    ldy.z rom_chip
    sta rom_device_ids,y
    // rom_detect::@12
  __b12:
    // rom_chip++;
    // [909] rom_detect::rom_chip#1 = ++ rom_detect::rom_chip#10 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip
    // rom_detect::@13
    // rom_detect_address += 0x80000
    // [910] rom_detect::rom_detect_address#1 = rom_detect::rom_detect_address#10 + $80000 -- vduz1=vduz1_plus_vduc1 
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
    // [870] phi from rom_detect::@13 to rom_detect::@1 [phi:rom_detect::@13->rom_detect::@1]
    // [870] phi rom_detect::rom_chip#10 = rom_detect::rom_chip#1 [phi:rom_detect::@13->rom_detect::@1#0] -- register_copy 
    // [870] phi rom_detect::rom_detect_address#10 = rom_detect::rom_detect_address#1 [phi:rom_detect::@13->rom_detect::@1#1] -- register_copy 
    jmp __b1
    // rom_detect::@10
  __b10:
    // rom_device_names[rom_chip] = "f040"
    // [911] rom_device_names[rom_detect::$19] = rom_detect::$34 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__19
    lda #<rom_detect__34
    sta rom_device_names,y
    lda #>rom_detect__34
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "512"
    // [912] rom_size_strings[rom_detect::$19] = rom_detect::$35 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__35
    sta rom_size_strings,y
    lda #>rom_detect__35
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 512 * 1024
    // [913] rom_detect::$26 = rom_detect::rom_chip#10 << 2 -- vbuaa=vbuz1_rol_2 
    lda.z rom_chip
    asl
    asl
    // [914] rom_sizes[rom_detect::$26] = (unsigned long)$200*$400 -- pduc1_derefidx_vbuaa=vduc2 
    tay
    lda #<$200*$400
    sta rom_sizes,y
    lda #>$200*$400
    sta rom_sizes+1,y
    lda #<$200*$400>>$10
    sta rom_sizes+2,y
    lda #>$200*$400>>$10
    sta rom_sizes+3,y
    jmp __b12
    // rom_detect::@9
  __b9:
    // rom_device_names[rom_chip] = "f020a"
    // [915] rom_device_names[rom_detect::$19] = rom_detect::$32 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__19
    lda #<rom_detect__32
    sta rom_device_names,y
    lda #>rom_detect__32
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "256"
    // [916] rom_size_strings[rom_detect::$19] = rom_detect::$33 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__33
    sta rom_size_strings,y
    lda #>rom_detect__33
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 256 * 1024
    // [917] rom_detect::$23 = rom_detect::rom_chip#10 << 2 -- vbuaa=vbuz1_rol_2 
    lda.z rom_chip
    asl
    asl
    // [918] rom_sizes[rom_detect::$23] = (unsigned long)$100*$400 -- pduc1_derefidx_vbuaa=vduc2 
    tay
    lda #<$100*$400
    sta rom_sizes,y
    lda #>$100*$400
    sta rom_sizes+1,y
    lda #<$100*$400>>$10
    sta rom_sizes+2,y
    lda #>$100*$400>>$10
    sta rom_sizes+3,y
    jmp __b12
    // rom_detect::@8
  __b8:
    // rom_device_names[rom_chip] = "f010a"
    // [919] rom_device_names[rom_detect::$19] = rom_detect::$30 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__19
    lda #<rom_detect__30
    sta rom_device_names,y
    lda #>rom_detect__30
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "128"
    // [920] rom_size_strings[rom_detect::$19] = rom_detect::$31 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__31
    sta rom_size_strings,y
    lda #>rom_detect__31
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 128 * 1024
    // [921] rom_detect::$20 = rom_detect::rom_chip#10 << 2 -- vbuaa=vbuz1_rol_2 
    lda.z rom_chip
    asl
    asl
    // [922] rom_sizes[rom_detect::$20] = (unsigned long)$80*$400 -- pduc1_derefidx_vbuaa=vduc2 
    tay
    lda #<$80*$400
    sta rom_sizes,y
    lda #>$80*$400
    sta rom_sizes+1,y
    lda #<$80*$400>>$10
    sta rom_sizes+2,y
    lda #>$80*$400>>$10
    sta rom_sizes+3,y
    jmp __b12
  .segment Data
    rom_detect__30: .text "f010a"
    .byte 0
    rom_detect__31: .text "128"
    .byte 0
    rom_detect__32: .text "f020a"
    .byte 0
    rom_detect__33: .text "256"
    .byte 0
    rom_detect__34: .text "f040"
    .byte 0
    rom_detect__35: .text "512"
    .byte 0
    rom_detect__36: .text "----"
    .byte 0
    rom_detect__37: .text "000"
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
// __zp($67) unsigned int smc_read(char display_progress)
smc_read: {
    .label fp = $40
    .label return = $67
    .label smc_file_read = $55
    .label y = $58
    .label ram_ptr = $bd
    .label smc_file_size = $67
    /// Holds the amount of bytes actually read in the memory to be flashed.
    .label progress_row_bytes = $de
    // display_action_progress("Reading SMC.BIN ... (.) data, ( ) empty")
    // [924] call display_action_progress
  // It is assume that one RAM bank is 0X2000 bytes.
    // [684] phi from smc_read to display_action_progress [phi:smc_read->display_action_progress]
    // [684] phi display_action_progress::info_text#10 = smc_read::info_text [phi:smc_read->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [925] phi from smc_read to smc_read::@8 [phi:smc_read->smc_read::@8]
    // smc_read::@8
    // textcolor(WHITE)
    // [926] call textcolor
    // [572] phi from smc_read::@8 to textcolor [phi:smc_read::@8->textcolor]
    // [572] phi textcolor::color#17 = WHITE [phi:smc_read::@8->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [927] phi from smc_read::@8 to smc_read::@9 [phi:smc_read::@8->smc_read::@9]
    // smc_read::@9
    // gotoxy(x, y)
    // [928] call gotoxy
    // [590] phi from smc_read::@9 to gotoxy [phi:smc_read::@9->gotoxy]
    // [590] phi gotoxy::y#24 = PROGRESS_Y [phi:smc_read::@9->gotoxy#0] -- vbuyy=vbuc1 
    ldy #PROGRESS_Y
    // [590] phi gotoxy::x#24 = PROGRESS_X [phi:smc_read::@9->gotoxy#1] -- vbuxx=vbuc1 
    ldx #PROGRESS_X
    jsr gotoxy
    // [929] phi from smc_read::@9 to smc_read::@10 [phi:smc_read::@9->smc_read::@10]
    // smc_read::@10
    // FILE *fp = fopen("SMC.BIN", "r")
    // [930] call fopen
    // [1647] phi from smc_read::@10 to fopen [phi:smc_read::@10->fopen]
    // [1647] phi __errno#295 = 0 [phi:smc_read::@10->fopen#0] -- vwsz1=vwsc1 
    lda #<0
    sta.z __errno
    sta.z __errno+1
    // [1647] phi fopen::pathtoken#0 = smc_read::path [phi:smc_read::@10->fopen#1] -- pbuz1=pbuc1 
    lda #<path
    sta.z fopen.pathtoken
    lda #>path
    sta.z fopen.pathtoken+1
    jsr fopen
    // FILE *fp = fopen("SMC.BIN", "r")
    // [931] fopen::return#3 = fopen::return#2
    // smc_read::@11
    // [932] smc_read::fp#0 = fopen::return#3 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [933] if((struct $2 *)0==smc_read::fp#0) goto smc_read::@1 -- pssc1_eq_pssz1_then_la1 
    lda.z fp
    cmp #<0
    bne !+
    lda.z fp+1
    cmp #>0
    beq __b4
  !:
    // [934] phi from smc_read::@11 to smc_read::@2 [phi:smc_read::@11->smc_read::@2]
    // [934] phi smc_read::y#10 = PROGRESS_Y [phi:smc_read::@11->smc_read::@2#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // [934] phi smc_read::progress_row_bytes#10 = 0 [phi:smc_read::@11->smc_read::@2#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z progress_row_bytes
    sta.z progress_row_bytes+1
    // [934] phi smc_read::smc_file_size#11 = 0 [phi:smc_read::@11->smc_read::@2#2] -- vwuz1=vwuc1 
    sta.z smc_file_size
    sta.z smc_file_size+1
    // [934] phi smc_read::ram_ptr#10 = (char *)$7800 [phi:smc_read::@11->smc_read::@2#3] -- pbuz1=pbuc1 
    lda #<$7800
    sta.z ram_ptr
    lda #>$7800
    sta.z ram_ptr+1
  // We read block_size bytes at a time, and each block_size bytes we plot a dot.
  // Every r bytes we move to the next line.
    // smc_read::@2
  __b2:
    // fgets(ram_ptr, SMC_PROGRESS_CELL, fp)
    // [935] fgets::ptr#2 = smc_read::ram_ptr#10 -- pbuz1=pbuz2 
    lda.z ram_ptr
    sta.z fgets.ptr
    lda.z ram_ptr+1
    sta.z fgets.ptr+1
    // [936] fgets::stream#0 = smc_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.stream
    lda.z fp+1
    sta.z fgets.stream+1
    // [937] call fgets
    // [1728] phi from smc_read::@2 to fgets [phi:smc_read::@2->fgets]
    // [1728] phi fgets::ptr#12 = fgets::ptr#2 [phi:smc_read::@2->fgets#0] -- register_copy 
    // [1728] phi fgets::size#10 = SMC_PROGRESS_CELL [phi:smc_read::@2->fgets#1] -- vwuz1=vbuc1 
    lda #<SMC_PROGRESS_CELL
    sta.z fgets.size
    lda #>SMC_PROGRESS_CELL
    sta.z fgets.size+1
    // [1728] phi fgets::stream#2 = fgets::stream#0 [phi:smc_read::@2->fgets#2] -- register_copy 
    jsr fgets
    // fgets(ram_ptr, SMC_PROGRESS_CELL, fp)
    // [938] fgets::return#5 = fgets::return#1
    // smc_read::@12
    // smc_file_read = fgets(ram_ptr, SMC_PROGRESS_CELL, fp)
    // [939] smc_read::smc_file_read#1 = fgets::return#5
    // while (smc_file_read = fgets(ram_ptr, SMC_PROGRESS_CELL, fp))
    // [940] if(0!=smc_read::smc_file_read#1) goto smc_read::@3 -- 0_neq_vwuz1_then_la1 
    lda.z smc_file_read
    ora.z smc_file_read+1
    bne __b3
    // smc_read::@4
    // fclose(fp)
    // [941] fclose::stream#0 = smc_read::fp#0
    // [942] call fclose
    // [1782] phi from smc_read::@4 to fclose [phi:smc_read::@4->fclose]
    // [1782] phi fclose::stream#2 = fclose::stream#0 [phi:smc_read::@4->fclose#0] -- register_copy 
    jsr fclose
    // [943] phi from smc_read::@4 to smc_read::@1 [phi:smc_read::@4->smc_read::@1]
    // [943] phi smc_read::return#0 = smc_read::smc_file_size#11 [phi:smc_read::@4->smc_read::@1#0] -- register_copy 
    rts
    // [943] phi from smc_read::@11 to smc_read::@1 [phi:smc_read::@11->smc_read::@1]
  __b4:
    // [943] phi smc_read::return#0 = 0 [phi:smc_read::@11->smc_read::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // smc_read::@1
    // smc_read::@return
    // }
    // [944] return 
    rts
    // [945] phi from smc_read::@12 to smc_read::@3 [phi:smc_read::@12->smc_read::@3]
    // smc_read::@3
  __b3:
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [946] call snprintf_init
    // [845] phi from smc_read::@3 to snprintf_init [phi:smc_read::@3->snprintf_init]
    // [845] phi snprintf_init::s#15 = info_text [phi:smc_read::@3->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [947] phi from smc_read::@3 to smc_read::@13 [phi:smc_read::@3->smc_read::@13]
    // smc_read::@13
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [948] call printf_str
    // [850] phi from smc_read::@13 to printf_str [phi:smc_read::@13->printf_str]
    // [850] phi printf_str::putc#48 = &snputc [phi:smc_read::@13->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = smc_read::s [phi:smc_read::@13->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@14
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [949] printf_uint::uvalue#0 = smc_read::smc_file_read#1 -- vwuz1=vwuz2 
    lda.z smc_file_read
    sta.z printf_uint.uvalue
    lda.z smc_file_read+1
    sta.z printf_uint.uvalue+1
    // [950] call printf_uint
    // [859] phi from smc_read::@14 to printf_uint [phi:smc_read::@14->printf_uint]
    // [859] phi printf_uint::format_zero_padding#10 = 1 [phi:smc_read::@14->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [859] phi printf_uint::format_min_length#10 = 5 [phi:smc_read::@14->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [859] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:smc_read::@14->printf_uint#2] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [859] phi printf_uint::uvalue#10 = printf_uint::uvalue#0 [phi:smc_read::@14->printf_uint#3] -- register_copy 
    jsr printf_uint
    // [951] phi from smc_read::@14 to smc_read::@15 [phi:smc_read::@14->smc_read::@15]
    // smc_read::@15
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [952] call printf_str
    // [850] phi from smc_read::@15 to printf_str [phi:smc_read::@15->printf_str]
    // [850] phi printf_str::putc#48 = &snputc [phi:smc_read::@15->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = s1 [phi:smc_read::@15->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@16
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [953] printf_uint::uvalue#1 = smc_read::smc_file_size#11 -- vwuz1=vwuz2 
    lda.z smc_file_size
    sta.z printf_uint.uvalue
    lda.z smc_file_size+1
    sta.z printf_uint.uvalue+1
    // [954] call printf_uint
    // [859] phi from smc_read::@16 to printf_uint [phi:smc_read::@16->printf_uint]
    // [859] phi printf_uint::format_zero_padding#10 = 1 [phi:smc_read::@16->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [859] phi printf_uint::format_min_length#10 = 5 [phi:smc_read::@16->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [859] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:smc_read::@16->printf_uint#2] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [859] phi printf_uint::uvalue#10 = printf_uint::uvalue#1 [phi:smc_read::@16->printf_uint#3] -- register_copy 
    jsr printf_uint
    // [955] phi from smc_read::@16 to smc_read::@17 [phi:smc_read::@16->smc_read::@17]
    // smc_read::@17
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [956] call printf_str
    // [850] phi from smc_read::@17 to printf_str [phi:smc_read::@17->printf_str]
    // [850] phi printf_str::putc#48 = &snputc [phi:smc_read::@17->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = s5 [phi:smc_read::@17->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // [957] phi from smc_read::@17 to smc_read::@18 [phi:smc_read::@17->smc_read::@18]
    // smc_read::@18
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [958] call printf_uint
    // [859] phi from smc_read::@18 to printf_uint [phi:smc_read::@18->printf_uint]
    // [859] phi printf_uint::format_zero_padding#10 = 1 [phi:smc_read::@18->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [859] phi printf_uint::format_min_length#10 = 2 [phi:smc_read::@18->printf_uint#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uint.format_min_length
    // [859] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:smc_read::@18->printf_uint#2] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [859] phi printf_uint::uvalue#10 = 0 [phi:smc_read::@18->printf_uint#3] -- vwuz1=vbuc1 
    lda #<0
    sta.z printf_uint.uvalue
    sta.z printf_uint.uvalue+1
    jsr printf_uint
    // [959] phi from smc_read::@18 to smc_read::@19 [phi:smc_read::@18->smc_read::@19]
    // smc_read::@19
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [960] call printf_str
    // [850] phi from smc_read::@19 to printf_str [phi:smc_read::@19->printf_str]
    // [850] phi printf_str::putc#48 = &snputc [phi:smc_read::@19->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = s3 [phi:smc_read::@19->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@20
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [961] printf_uint::uvalue#3 = (unsigned int)smc_read::ram_ptr#10 -- vwuz1=vwuz2 
    lda.z ram_ptr
    sta.z printf_uint.uvalue
    lda.z ram_ptr+1
    sta.z printf_uint.uvalue+1
    // [962] call printf_uint
    // [859] phi from smc_read::@20 to printf_uint [phi:smc_read::@20->printf_uint]
    // [859] phi printf_uint::format_zero_padding#10 = 1 [phi:smc_read::@20->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [859] phi printf_uint::format_min_length#10 = 4 [phi:smc_read::@20->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [859] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:smc_read::@20->printf_uint#2] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [859] phi printf_uint::uvalue#10 = printf_uint::uvalue#3 [phi:smc_read::@20->printf_uint#3] -- register_copy 
    jsr printf_uint
    // [963] phi from smc_read::@20 to smc_read::@21 [phi:smc_read::@20->smc_read::@21]
    // smc_read::@21
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [964] call printf_str
    // [850] phi from smc_read::@21 to printf_str [phi:smc_read::@21->printf_str]
    // [850] phi printf_str::putc#48 = &snputc [phi:smc_read::@21->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = s4 [phi:smc_read::@21->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@22
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr)
    // [965] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [966] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [968] call display_action_text
    // [1039] phi from smc_read::@22 to display_action_text [phi:smc_read::@22->display_action_text]
    // [1039] phi display_action_text::info_text#10 = info_text [phi:smc_read::@22->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_read::@23
    // if (progress_row_bytes == SMC_PROGRESS_ROW)
    // [969] if(smc_read::progress_row_bytes#10!=SMC_PROGRESS_ROW) goto smc_read::@5 -- vwuz1_neq_vwuc1_then_la1 
    lda.z progress_row_bytes+1
    cmp #>SMC_PROGRESS_ROW
    bne __b6
    lda.z progress_row_bytes
    cmp #<SMC_PROGRESS_ROW
    bne __b6
    // smc_read::@7
    // gotoxy(x, ++y);
    // [970] smc_read::y#1 = ++ smc_read::y#10 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [971] gotoxy::y#20 = smc_read::y#1 -- vbuyy=vbuz1 
    ldy.z y
    // [972] call gotoxy
    // [590] phi from smc_read::@7 to gotoxy [phi:smc_read::@7->gotoxy]
    // [590] phi gotoxy::y#24 = gotoxy::y#20 [phi:smc_read::@7->gotoxy#0] -- register_copy 
    // [590] phi gotoxy::x#24 = PROGRESS_X [phi:smc_read::@7->gotoxy#1] -- vbuxx=vbuc1 
    ldx #PROGRESS_X
    jsr gotoxy
    // [973] phi from smc_read::@7 to smc_read::@5 [phi:smc_read::@7->smc_read::@5]
    // [973] phi smc_read::y#20 = smc_read::y#1 [phi:smc_read::@7->smc_read::@5#0] -- register_copy 
    // [973] phi smc_read::progress_row_bytes#4 = 0 [phi:smc_read::@7->smc_read::@5#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z progress_row_bytes
    sta.z progress_row_bytes+1
    // [973] phi from smc_read::@23 to smc_read::@5 [phi:smc_read::@23->smc_read::@5]
    // [973] phi smc_read::y#20 = smc_read::y#10 [phi:smc_read::@23->smc_read::@5#0] -- register_copy 
    // [973] phi smc_read::progress_row_bytes#4 = smc_read::progress_row_bytes#10 [phi:smc_read::@23->smc_read::@5#1] -- register_copy 
    // smc_read::@5
    // smc_read::@6
  __b6:
    // ram_ptr += smc_file_read
    // [974] smc_read::ram_ptr#1 = smc_read::ram_ptr#10 + smc_read::smc_file_read#1 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z ram_ptr
    adc.z smc_file_read
    sta.z ram_ptr
    lda.z ram_ptr+1
    adc.z smc_file_read+1
    sta.z ram_ptr+1
    // smc_file_size += smc_file_read
    // [975] smc_read::smc_file_size#1 = smc_read::smc_file_size#11 + smc_read::smc_file_read#1 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z smc_file_size
    adc.z smc_file_read
    sta.z smc_file_size
    lda.z smc_file_size+1
    adc.z smc_file_read+1
    sta.z smc_file_size+1
    // progress_row_bytes += smc_file_read
    // [976] smc_read::progress_row_bytes#2 = smc_read::progress_row_bytes#4 + smc_read::smc_file_read#1 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z progress_row_bytes
    adc.z smc_file_read
    sta.z progress_row_bytes
    lda.z progress_row_bytes+1
    adc.z smc_file_read+1
    sta.z progress_row_bytes+1
    // [934] phi from smc_read::@6 to smc_read::@2 [phi:smc_read::@6->smc_read::@2]
    // [934] phi smc_read::y#10 = smc_read::y#20 [phi:smc_read::@6->smc_read::@2#0] -- register_copy 
    // [934] phi smc_read::progress_row_bytes#10 = smc_read::progress_row_bytes#2 [phi:smc_read::@6->smc_read::@2#1] -- register_copy 
    // [934] phi smc_read::smc_file_size#11 = smc_read::smc_file_size#1 [phi:smc_read::@6->smc_read::@2#2] -- register_copy 
    // [934] phi smc_read::ram_ptr#10 = smc_read::ram_ptr#1 [phi:smc_read::@6->smc_read::@2#3] -- register_copy 
    jmp __b2
  .segment Data
    info_text: .text "Reading SMC.BIN ... (.) data, ( ) empty"
    .byte 0
    path: .text "SMC.BIN"
    .byte 0
    s: .text "Reading SMC.BIN:"
    .byte 0
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
    // [978] rom_get_release::$0 = rom_get_release::release#4 & $80 -- vbuaa=vbuxx_band_vbuc1 
    txa
    and #$80
    // if(release & 0x80)
    // [979] if(0==rom_get_release::$0) goto rom_get_release::@1 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b1
    // rom_get_release::@2
    // ~release
    // [980] rom_get_release::$2 = ~ rom_get_release::release#4 -- vbuaa=_bnot_vbuxx 
    txa
    eor #$ff
    // release = ~release + 1
    // [981] rom_get_release::release#0 = rom_get_release::$2 + 1 -- vbuxx=vbuaa_plus_1 
    tax
    inx
    // [982] phi from rom_get_release rom_get_release::@2 to rom_get_release::@1 [phi:rom_get_release/rom_get_release::@2->rom_get_release::@1]
    // [982] phi rom_get_release::return#0 = rom_get_release::release#4 [phi:rom_get_release/rom_get_release::@2->rom_get_release::@1#0] -- register_copy 
    // rom_get_release::@1
  __b1:
    // rom_get_release::@return
    // }
    // [983] return 
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
    // [985] if(rom_get_prefix::release#4!=$ff) goto rom_get_prefix::@1 -- vbuaa_neq_vbuc1_then_la1 
    cmp #$ff
    bne __b3
    // [986] phi from rom_get_prefix to rom_get_prefix::@3 [phi:rom_get_prefix->rom_get_prefix::@3]
    // rom_get_prefix::@3
    // [987] phi from rom_get_prefix::@3 to rom_get_prefix::@1 [phi:rom_get_prefix::@3->rom_get_prefix::@1]
    // [987] phi rom_get_prefix::prefix#4 = 'p' [phi:rom_get_prefix::@3->rom_get_prefix::@1#0] -- vbuxx=vbuc1 
    ldx #'p'
    jmp __b1
    // [987] phi from rom_get_prefix to rom_get_prefix::@1 [phi:rom_get_prefix->rom_get_prefix::@1]
  __b3:
    // [987] phi rom_get_prefix::prefix#4 = ' ' [phi:rom_get_prefix->rom_get_prefix::@1#0] -- vbuxx=vbuc1 
    ldx #' '
    // rom_get_prefix::@1
  __b1:
    // release & 0x80
    // [988] rom_get_prefix::$2 = rom_get_prefix::release#4 & $80 -- vbuaa=vbuaa_band_vbuc1 
    and #$80
    // if(release & 0x80)
    // [989] if(0==rom_get_prefix::$2) goto rom_get_prefix::@4 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b2
    // [991] phi from rom_get_prefix::@1 to rom_get_prefix::@2 [phi:rom_get_prefix::@1->rom_get_prefix::@2]
    // [991] phi rom_get_prefix::return#0 = 'p' [phi:rom_get_prefix::@1->rom_get_prefix::@2#0] -- vbuxx=vbuc1 
    ldx #'p'
    rts
    // [990] phi from rom_get_prefix::@1 to rom_get_prefix::@4 [phi:rom_get_prefix::@1->rom_get_prefix::@4]
    // rom_get_prefix::@4
    // [991] phi from rom_get_prefix::@4 to rom_get_prefix::@2 [phi:rom_get_prefix::@4->rom_get_prefix::@2]
    // [991] phi rom_get_prefix::return#0 = rom_get_prefix::prefix#4 [phi:rom_get_prefix::@4->rom_get_prefix::@2#0] -- register_copy 
    // rom_get_prefix::@2
  __b2:
    // rom_get_prefix::@return
    // }
    // [992] return 
    rts
}
  // printf_string
// Print a string value using a specific format
// Handles justification and min length 
// void printf_string(__zp($5d) void (*putc)(char), __zp($3e) char *str, __zp($63) char format_min_length, __zp($70) char format_justify_left)
printf_string: {
    .label printf_string__9 = $3a
    .label padding = $63
    .label str = $3e
    .label str_1 = $b0
    .label format_min_length = $63
    .label format_justify_left = $70
    .label putc = $5d
    // if(format.min_length)
    // [994] if(0==printf_string::format_min_length#21) goto printf_string::@1 -- 0_eq_vbuz1_then_la1 
    lda.z format_min_length
    beq __b3
    // printf_string::@3
    // strlen(str)
    // [995] strlen::str#3 = printf_string::str#21 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [996] call strlen
    // [1810] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [1810] phi strlen::str#8 = strlen::str#3 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [997] strlen::return#10 = strlen::len#2
    // printf_string::@6
    // [998] printf_string::$9 = strlen::return#10
    // signed char len = (signed char)strlen(str)
    // [999] printf_string::len#0 = (signed char)printf_string::$9 -- vbsaa=_sbyte_vwuz1 
    lda.z printf_string__9
    // padding = (signed char)format.min_length  - len
    // [1000] printf_string::padding#1 = (signed char)printf_string::format_min_length#21 - printf_string::len#0 -- vbsz1=vbsz1_minus_vbsaa 
    eor #$ff
    sec
    adc.z padding
    sta.z padding
    // if(padding<0)
    // [1001] if(printf_string::padding#1>=0) goto printf_string::@10 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1003] phi from printf_string printf_string::@6 to printf_string::@1 [phi:printf_string/printf_string::@6->printf_string::@1]
  __b3:
    // [1003] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@6->printf_string::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [1002] phi from printf_string::@6 to printf_string::@10 [phi:printf_string::@6->printf_string::@10]
    // printf_string::@10
    // [1003] phi from printf_string::@10 to printf_string::@1 [phi:printf_string::@10->printf_string::@1]
    // [1003] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@10->printf_string::@1#0] -- register_copy 
    // printf_string::@1
  __b1:
    // if(!format.justify_left && padding)
    // [1004] if(0!=printf_string::format_justify_left#21) goto printf_string::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_justify_left
    bne __b2
    // printf_string::@8
    // [1005] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b4
    jmp __b2
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [1006] printf_padding::putc#3 = printf_string::putc#21 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1007] printf_padding::length#3 = (char)printf_string::padding#3 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1008] call printf_padding
    // [1816] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    // [1816] phi printf_padding::putc#7 = printf_padding::putc#3 [phi:printf_string::@4->printf_padding#0] -- register_copy 
    // [1816] phi printf_padding::pad#7 = ' ' [phi:printf_string::@4->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1816] phi printf_padding::length#6 = printf_padding::length#3 [phi:printf_string::@4->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [1009] printf_str::putc#1 = printf_string::putc#21 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_str.putc
    lda.z putc+1
    sta.z printf_str.putc+1
    // [1010] printf_str::s#2 = printf_string::str#21
    // [1011] call printf_str
    // [850] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [850] phi printf_str::putc#48 = printf_str::putc#1 [phi:printf_string::@2->printf_str#0] -- register_copy 
    // [850] phi printf_str::s#48 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@7
    // if(format.justify_left && padding)
    // [1012] if(0==printf_string::format_justify_left#21) goto printf_string::@return -- 0_eq_vbuz1_then_la1 
    lda.z format_justify_left
    beq __breturn
    // printf_string::@9
    // [1013] if(0!=printf_string::padding#3) goto printf_string::@5 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b5
    rts
    // printf_string::@5
  __b5:
    // printf_padding(putc, ' ',(char)padding)
    // [1014] printf_padding::putc#4 = printf_string::putc#21 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1015] printf_padding::length#4 = (char)printf_string::padding#3 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1016] call printf_padding
    // [1816] phi from printf_string::@5 to printf_padding [phi:printf_string::@5->printf_padding]
    // [1816] phi printf_padding::putc#7 = printf_padding::putc#4 [phi:printf_string::@5->printf_padding#0] -- register_copy 
    // [1816] phi printf_padding::pad#7 = ' ' [phi:printf_string::@5->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1816] phi printf_padding::length#6 = printf_padding::length#4 [phi:printf_string::@5->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@return
  __breturn:
    // }
    // [1017] return 
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
    // [1019] BRAM = system_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // system_reset::bank_set_brom1
    // BROM = bank
    // [1020] BROM = system_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // system_reset::@2
    // asm
    // asm { jmp($FFFC)  }
    jmp ($fffc)
    // [1022] phi from system_reset::@1 system_reset::@2 to system_reset::@1 [phi:system_reset::@1/system_reset::@2->system_reset::@1]
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
    .label i = $bd
    // [1024] phi from wait_moment to wait_moment::@1 [phi:wait_moment->wait_moment::@1]
    // [1024] phi wait_moment::i#2 = $ffff [phi:wait_moment->wait_moment::@1#0] -- vwuz1=vwuc1 
    lda #<$ffff
    sta.z i
    lda #>$ffff
    sta.z i+1
    // wait_moment::@1
  __b1:
    // for(unsigned int i=65535; i>0; i--)
    // [1025] if(wait_moment::i#2>0) goto wait_moment::@2 -- vwuz1_gt_0_then_la1 
    lda.z i+1
    bne __b2
    lda.z i
    bne __b2
  !:
    // wait_moment::@return
    // }
    // [1026] return 
    rts
    // wait_moment::@2
  __b2:
    // for(unsigned int i=65535; i>0; i--)
    // [1027] wait_moment::i#1 = -- wait_moment::i#2 -- vwuz1=_dec_vwuz1 
    lda.z i
    bne !+
    dec.z i+1
  !:
    dec.z i
    // [1024] phi from wait_moment::@2 to wait_moment::@1 [phi:wait_moment::@2->wait_moment::@1]
    // [1024] phi wait_moment::i#2 = wait_moment::i#1 [phi:wait_moment::@2->wait_moment::@1#0] -- register_copy 
    jmp __b1
}
  // printf_uchar
// Print an unsigned char using a specific format
// void printf_uchar(__zp($4f) void (*putc)(char), __register(X) char uvalue, __zp($a9) char format_min_length, char format_justify_left, char format_sign_always, __zp($65) char format_zero_padding, char format_upper_case, __register(Y) char format_radix)
printf_uchar: {
    .label putc = $4f
    .label format_min_length = $a9
    .label format_zero_padding = $65
    // printf_uchar::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1029] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // uctoa(uvalue, printf_buffer.digits, format.radix)
    // [1030] uctoa::value#1 = printf_uchar::uvalue#10
    // [1031] uctoa::radix#0 = printf_uchar::format_radix#10
    // [1032] call uctoa
    // Format number into buffer
    jsr uctoa
    // printf_uchar::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1033] printf_number_buffer::putc#2 = printf_uchar::putc#10
    // [1034] printf_number_buffer::buffer_sign#2 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [1035] printf_number_buffer::format_min_length#2 = printf_uchar::format_min_length#10 -- vbuxx=vbuz1 
    ldx.z format_min_length
    // [1036] printf_number_buffer::format_zero_padding#2 = printf_uchar::format_zero_padding#10
    // [1037] call printf_number_buffer
  // Print using format
    // [1616] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [1616] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#2 [phi:printf_uchar::@2->printf_number_buffer#0] -- register_copy 
    // [1616] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#2 [phi:printf_uchar::@2->printf_number_buffer#1] -- register_copy 
    // [1616] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#2 [phi:printf_uchar::@2->printf_number_buffer#2] -- register_copy 
    // [1616] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#2 [phi:printf_uchar::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [1038] return 
    rts
}
  // display_action_text
/**
 * @brief Print an info line at the action frame, which is the second line.
 * 
 * @param info_text The info text to be displayed.
 */
// void display_action_text(__zp($5d) char *info_text)
display_action_text: {
    .label info_text = $5d
    .label x = $2f
    .label y = $76
    // unsigned char x = wherex()
    // [1040] call wherex
    jsr wherex
    // [1041] wherex::return#3 = wherex::return#0
    // display_action_text::@1
    // [1042] display_action_text::x#0 = wherex::return#3 -- vbuz1=vbuaa 
    sta.z x
    // unsigned char y = wherey()
    // [1043] call wherey
    jsr wherey
    // [1044] wherey::return#3 = wherey::return#0
    // display_action_text::@2
    // [1045] display_action_text::y#0 = wherey::return#3 -- vbuz1=vbuaa 
    sta.z y
    // gotoxy(2, PROGRESS_Y-3)
    // [1046] call gotoxy
    // [590] phi from display_action_text::@2 to gotoxy [phi:display_action_text::@2->gotoxy]
    // [590] phi gotoxy::y#24 = PROGRESS_Y-3 [phi:display_action_text::@2->gotoxy#0] -- vbuyy=vbuc1 
    ldy #PROGRESS_Y-3
    // [590] phi gotoxy::x#24 = 2 [phi:display_action_text::@2->gotoxy#1] -- vbuxx=vbuc1 
    ldx #2
    jsr gotoxy
    // display_action_text::@3
    // printf("%-65s", info_text)
    // [1047] printf_string::str#2 = display_action_text::info_text#10 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1048] call printf_string
    // [993] phi from display_action_text::@3 to printf_string [phi:display_action_text::@3->printf_string]
    // [993] phi printf_string::putc#21 = &cputc [phi:display_action_text::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [993] phi printf_string::str#21 = printf_string::str#2 [phi:display_action_text::@3->printf_string#1] -- register_copy 
    // [993] phi printf_string::format_justify_left#21 = 1 [phi:display_action_text::@3->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [993] phi printf_string::format_min_length#21 = $41 [phi:display_action_text::@3->printf_string#3] -- vbuz1=vbuc1 
    lda #$41
    sta.z printf_string.format_min_length
    jsr printf_string
    // display_action_text::@4
    // gotoxy(x, y)
    // [1049] gotoxy::x#12 = display_action_text::x#0 -- vbuxx=vbuz1 
    ldx.z x
    // [1050] gotoxy::y#12 = display_action_text::y#0 -- vbuyy=vbuz1 
    ldy.z y
    // [1051] call gotoxy
    // [590] phi from display_action_text::@4 to gotoxy [phi:display_action_text::@4->gotoxy]
    // [590] phi gotoxy::y#24 = gotoxy::y#12 [phi:display_action_text::@4->gotoxy#0] -- register_copy 
    // [590] phi gotoxy::x#24 = gotoxy::x#12 [phi:display_action_text::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_action_text::@return
    // }
    // [1052] return 
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
    // [1054] BRAM = smc_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // smc_reset::bank_set_brom1
    // BROM = bank
    // [1055] BROM = smc_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // smc_reset::@2
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [1056] smc_reset::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [1057] smc_reset::cx16_k_i2c_write_byte1_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte1_offset
    // [1058] smc_reset::cx16_k_i2c_write_byte1_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte1_value
    // smc_reset::cx16_k_i2c_write_byte1
    // unsigned char result
    // [1059] smc_reset::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
    sta cx16_k_i2c_write_byte1_result
    // asm
    // asm { ldxdevice ldyoffset ldavalue stzresult jsrCX16_I2C_WRITE_BYTE rolresult  }
    ldx cx16_k_i2c_write_byte1_device
    ldy cx16_k_i2c_write_byte1_offset
    lda cx16_k_i2c_write_byte1_value
    stz cx16_k_i2c_write_byte1_result
    jsr CX16_I2C_WRITE_BYTE
    rol cx16_k_i2c_write_byte1_result
    // [1061] phi from smc_reset::@1 smc_reset::cx16_k_i2c_write_byte1 to smc_reset::@1 [phi:smc_reset::@1/smc_reset::cx16_k_i2c_write_byte1->smc_reset::@1]
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
  // util_wait_key
/**
 * @brief 
 * 
 * @param info_text 
 * @param filter 
 * @return unsigned char 
 */
// __register(A) char util_wait_key(__zp($5d) char *info_text, __zp($49) char *filter)
util_wait_key: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 4
    .label util_wait_key__9 = $67
    .label bram = $f0
    .label bank_get_brom1_return = $f2
    .label info_text = $5d
    .label ch = $dc
    .label filter = $49
    // display_action_text(info_text)
    // [1063] display_action_text::info_text#0 = util_wait_key::info_text#2
    // [1064] call display_action_text
    // [1039] phi from util_wait_key to display_action_text [phi:util_wait_key->display_action_text]
    // [1039] phi display_action_text::info_text#10 = display_action_text::info_text#0 [phi:util_wait_key->display_action_text#0] -- register_copy 
    jsr display_action_text
    // util_wait_key::bank_get_bram1
    // return BRAM;
    // [1065] util_wait_key::bram#0 = BRAM -- vbuz1=vbuz2 
    lda.z BRAM
    sta.z bram
    // util_wait_key::bank_get_brom1
    // return BROM;
    // [1066] util_wait_key::bank_get_brom1_return#0 = BROM -- vbuz1=vbuz2 
    lda.z BROM
    sta.z bank_get_brom1_return
    // util_wait_key::bank_set_bram1
    // BRAM = bank
    // [1067] BRAM = util_wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // util_wait_key::bank_set_brom1
    // BROM = bank
    // [1068] BROM = util_wait_key::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [1069] phi from util_wait_key::@2 util_wait_key::@5 util_wait_key::bank_set_brom1 to util_wait_key::kbhit1 [phi:util_wait_key::@2/util_wait_key::@5/util_wait_key::bank_set_brom1->util_wait_key::kbhit1]
    // util_wait_key::kbhit1
  kbhit1:
    // util_wait_key::kbhit1_cbm_k_clrchn1
    // asm
    // asm { jsrCBM_CLRCHN  }
    jsr CBM_CLRCHN
    // [1071] phi from util_wait_key::kbhit1_cbm_k_clrchn1 to util_wait_key::kbhit1_@2 [phi:util_wait_key::kbhit1_cbm_k_clrchn1->util_wait_key::kbhit1_@2]
    // util_wait_key::kbhit1_@2
    // cbm_k_getin()
    // [1072] call cbm_k_getin
    jsr cbm_k_getin
    // [1073] cbm_k_getin::return#2 = cbm_k_getin::return#1
    // util_wait_key::@4
    // [1074] util_wait_key::ch#4 = cbm_k_getin::return#2 -- vwuz1=vbuaa 
    sta.z ch
    lda #0
    sta.z ch+1
    // util_wait_key::@3
    // if (filter)
    // [1075] if((char *)0!=util_wait_key::filter#12) goto util_wait_key::@1 -- pbuc1_neq_pbuz1_then_la1 
    // if there is a filter, check the filter, otherwise return ch.
    lda.z filter+1
    cmp #>0
    bne __b1
    lda.z filter
    cmp #<0
    bne __b1
    // util_wait_key::@2
    // if(ch)
    // [1076] if(0!=util_wait_key::ch#4) goto util_wait_key::bank_set_bram2 -- 0_neq_vwuz1_then_la1 
    lda.z ch
    ora.z ch+1
    bne bank_set_bram2
    jmp kbhit1
    // util_wait_key::bank_set_bram2
  bank_set_bram2:
    // BRAM = bank
    // [1077] BRAM = util_wait_key::bram#0 -- vbuz1=vbuz2 
    lda.z bram
    sta.z BRAM
    // util_wait_key::bank_set_brom2
    // BROM = bank
    // [1078] BROM = util_wait_key::bank_get_brom1_return#0 -- vbuz1=vbuz2 
    lda.z bank_get_brom1_return
    sta.z BROM
    // util_wait_key::@return
    // }
    // [1079] return 
    rts
    // util_wait_key::@1
  __b1:
    // strchr(filter, ch)
    // [1080] strchr::str#0 = (const void *)util_wait_key::filter#12 -- pvoz1=pvoz2 
    lda.z filter
    sta.z strchr.str
    lda.z filter+1
    sta.z strchr.str+1
    // [1081] strchr::c#0 = util_wait_key::ch#4 -- vbuz1=vwuz2 
    lda.z ch
    sta.z strchr.c
    // [1082] call strchr
    // [1086] phi from util_wait_key::@1 to strchr [phi:util_wait_key::@1->strchr]
    // [1086] phi strchr::c#4 = strchr::c#0 [phi:util_wait_key::@1->strchr#0] -- register_copy 
    // [1086] phi strchr::str#2 = strchr::str#0 [phi:util_wait_key::@1->strchr#1] -- register_copy 
    jsr strchr
    // strchr(filter, ch)
    // [1083] strchr::return#3 = strchr::return#2
    // util_wait_key::@5
    // [1084] util_wait_key::$9 = strchr::return#3
    // if(strchr(filter, ch) != NULL)
    // [1085] if(util_wait_key::$9!=0) goto util_wait_key::bank_set_bram2 -- pvoz1_neq_0_then_la1 
    lda.z util_wait_key__9
    ora.z util_wait_key__9+1
    bne bank_set_bram2
    jmp kbhit1
}
  // strchr
// Searches for the first occurrence of the character c (an unsigned char) in the string pointed to, by the argument str.
// - str: The memory to search
// - c: A character to search for
// Return: A pointer to the matching byte or NULL if the character does not occur in the given memory area.
// __zp($67) void * strchr(__zp($67) const void *str, __zp($7f) char c)
strchr: {
    .label ptr = $67
    .label return = $67
    .label str = $67
    .label c = $7f
    // [1087] strchr::ptr#6 = (char *)strchr::str#2
    // [1088] phi from strchr strchr::@3 to strchr::@1 [phi:strchr/strchr::@3->strchr::@1]
    // [1088] phi strchr::ptr#2 = strchr::ptr#6 [phi:strchr/strchr::@3->strchr::@1#0] -- register_copy 
    // strchr::@1
  __b1:
    // while(*ptr)
    // [1089] if(0!=*strchr::ptr#2) goto strchr::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (ptr),y
    cmp #0
    bne __b2
    // [1090] phi from strchr::@1 to strchr::@return [phi:strchr::@1->strchr::@return]
    // [1090] phi strchr::return#2 = (void *) 0 [phi:strchr::@1->strchr::@return#0] -- pvoz1=pvoc1 
    tya
    sta.z return
    sta.z return+1
    // strchr::@return
    // }
    // [1091] return 
    rts
    // strchr::@2
  __b2:
    // if(*ptr==c)
    // [1092] if(*strchr::ptr#2!=strchr::c#4) goto strchr::@3 -- _deref_pbuz1_neq_vbuz2_then_la1 
    ldy #0
    lda (ptr),y
    cmp.z c
    bne __b3
    // strchr::@4
    // [1093] strchr::return#8 = (void *)strchr::ptr#2
    // [1090] phi from strchr::@4 to strchr::@return [phi:strchr::@4->strchr::@return]
    // [1090] phi strchr::return#2 = strchr::return#8 [phi:strchr::@4->strchr::@return#0] -- register_copy 
    rts
    // strchr::@3
  __b3:
    // ptr++;
    // [1094] strchr::ptr#1 = ++ strchr::ptr#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr
    bne !+
    inc.z ptr+1
  !:
    jmp __b1
}
  // display_info_rom
/**
 * @brief Display the ROM status of a specific rom chip. 
 * 
 * @param rom_chip The ROM chip, 0 is the main CX16 ROM chip, maximum 7 ROMs.
 * @param info_status The status.
 * @param info_text The status text.
 */
// void display_info_rom(__zp($44) char rom_chip, __zp($5a) char info_status, __zp($5f) char *info_text)
display_info_rom: {
    .label display_info_rom__13 = $f9
    .label info_status = $5a
    .label info_text = $5f
    .label rom_chip = $44
    // unsigned char x = wherex()
    // [1096] call wherex
    jsr wherex
    // [1097] wherex::return#12 = wherex::return#0
    // display_info_rom::@3
    // [1098] display_info_rom::x#0 = wherex::return#12 -- vbum1=vbuaa 
    sta x
    // unsigned char y = wherey()
    // [1099] call wherey
    jsr wherey
    // [1100] wherey::return#12 = wherey::return#0
    // display_info_rom::@4
    // [1101] display_info_rom::y#0 = wherey::return#12 -- vbum1=vbuaa 
    sta y
    // status_rom[rom_chip] = info_status
    // [1102] status_rom[display_info_rom::rom_chip#10] = display_info_rom::info_status#10 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z info_status
    ldy.z rom_chip
    sta status_rom,y
    // display_rom_led(rom_chip, status_color[info_status])
    // [1103] display_rom_led::chip#1 = display_info_rom::rom_chip#10 -- vbuz1=vbuz2 
    tya
    sta.z display_rom_led.chip
    // [1104] display_rom_led::c#1 = status_color[display_info_rom::info_status#10] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z display_rom_led.c
    // [1105] call display_rom_led
    // [1571] phi from display_info_rom::@4 to display_rom_led [phi:display_info_rom::@4->display_rom_led]
    // [1571] phi display_rom_led::c#2 = display_rom_led::c#1 [phi:display_info_rom::@4->display_rom_led#0] -- register_copy 
    // [1571] phi display_rom_led::chip#2 = display_rom_led::chip#1 [phi:display_info_rom::@4->display_rom_led#1] -- register_copy 
    jsr display_rom_led
    // display_info_rom::@5
    // gotoxy(INFO_X, INFO_Y+rom_chip+2)
    // [1106] gotoxy::y#17 = display_info_rom::rom_chip#10 + $11+2 -- vbuyy=vbuz1_plus_vbuc1 
    lda #$11+2
    clc
    adc.z rom_chip
    tay
    // [1107] call gotoxy
    // [590] phi from display_info_rom::@5 to gotoxy [phi:display_info_rom::@5->gotoxy]
    // [590] phi gotoxy::y#24 = gotoxy::y#17 [phi:display_info_rom::@5->gotoxy#0] -- register_copy 
    // [590] phi gotoxy::x#24 = 4 [phi:display_info_rom::@5->gotoxy#1] -- vbuxx=vbuc1 
    ldx #4
    jsr gotoxy
    // display_info_rom::@6
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1108] display_info_rom::$13 = display_info_rom::rom_chip#10 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta.z display_info_rom__13
    // rom_chip*13
    // [1109] display_info_rom::$16 = display_info_rom::$13 + display_info_rom::rom_chip#10 -- vbuaa=vbuz1_plus_vbuz2 
    clc
    adc.z rom_chip
    // [1110] display_info_rom::$17 = display_info_rom::$16 << 2 -- vbuaa=vbuaa_rol_2 
    asl
    asl
    // [1111] display_info_rom::$6 = display_info_rom::$17 + display_info_rom::rom_chip#10 -- vbuaa=vbuaa_plus_vbuz1 
    clc
    adc.z rom_chip
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1112] printf_string::str#10 = rom_release_text + display_info_rom::$6 -- pbuz1=pbuc1_plus_vbuaa 
    clc
    adc #<rom_release_text
    sta.z printf_string.str_1
    lda #>rom_release_text
    adc #0
    sta.z printf_string.str_1+1
    // [1113] call printf_str
    // [850] phi from display_info_rom::@6 to printf_str [phi:display_info_rom::@6->printf_str]
    // [850] phi printf_str::putc#48 = &cputc [phi:display_info_rom::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = display_info_rom::s [phi:display_info_rom::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@7
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1114] printf_uchar::uvalue#0 = display_info_rom::rom_chip#10 -- vbuxx=vbuz1 
    ldx.z rom_chip
    // [1115] call printf_uchar
    // [1028] phi from display_info_rom::@7 to printf_uchar [phi:display_info_rom::@7->printf_uchar]
    // [1028] phi printf_uchar::format_zero_padding#10 = 0 [phi:display_info_rom::@7->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1028] phi printf_uchar::format_min_length#10 = 0 [phi:display_info_rom::@7->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1028] phi printf_uchar::putc#10 = &cputc [phi:display_info_rom::@7->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1028] phi printf_uchar::format_radix#10 = DECIMAL [phi:display_info_rom::@7->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [1028] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#0 [phi:display_info_rom::@7->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1116] phi from display_info_rom::@7 to display_info_rom::@8 [phi:display_info_rom::@7->display_info_rom::@8]
    // display_info_rom::@8
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1117] call printf_str
    // [850] phi from display_info_rom::@8 to printf_str [phi:display_info_rom::@8->printf_str]
    // [850] phi printf_str::putc#48 = &cputc [phi:display_info_rom::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = s2 [phi:display_info_rom::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@9
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1118] display_info_rom::$12 = display_info_rom::info_status#10 << 1 -- vbuaa=vbuz1_rol_1 
    lda.z info_status
    asl
    // [1119] printf_string::str#8 = status_text[display_info_rom::$12] -- pbuz1=qbuc1_derefidx_vbuaa 
    tay
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [1120] call printf_string
    // [993] phi from display_info_rom::@9 to printf_string [phi:display_info_rom::@9->printf_string]
    // [993] phi printf_string::putc#21 = &cputc [phi:display_info_rom::@9->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [993] phi printf_string::str#21 = printf_string::str#8 [phi:display_info_rom::@9->printf_string#1] -- register_copy 
    // [993] phi printf_string::format_justify_left#21 = 1 [phi:display_info_rom::@9->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [993] phi printf_string::format_min_length#21 = 9 [phi:display_info_rom::@9->printf_string#3] -- vbuz1=vbuc1 
    lda #9
    sta.z printf_string.format_min_length
    jsr printf_string
    // [1121] phi from display_info_rom::@9 to display_info_rom::@10 [phi:display_info_rom::@9->display_info_rom::@10]
    // display_info_rom::@10
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1122] call printf_str
    // [850] phi from display_info_rom::@10 to printf_str [phi:display_info_rom::@10->printf_str]
    // [850] phi printf_str::putc#48 = &cputc [phi:display_info_rom::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = s2 [phi:display_info_rom::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@11
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1123] printf_string::str#9 = rom_device_names[display_info_rom::$13] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z display_info_rom__13
    lda rom_device_names,y
    sta.z printf_string.str
    lda rom_device_names+1,y
    sta.z printf_string.str+1
    // [1124] call printf_string
    // [993] phi from display_info_rom::@11 to printf_string [phi:display_info_rom::@11->printf_string]
    // [993] phi printf_string::putc#21 = &cputc [phi:display_info_rom::@11->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [993] phi printf_string::str#21 = printf_string::str#9 [phi:display_info_rom::@11->printf_string#1] -- register_copy 
    // [993] phi printf_string::format_justify_left#21 = 1 [phi:display_info_rom::@11->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [993] phi printf_string::format_min_length#21 = 6 [phi:display_info_rom::@11->printf_string#3] -- vbuz1=vbuc1 
    lda #6
    sta.z printf_string.format_min_length
    jsr printf_string
    // [1125] phi from display_info_rom::@11 to display_info_rom::@12 [phi:display_info_rom::@11->display_info_rom::@12]
    // display_info_rom::@12
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1126] call printf_str
    // [850] phi from display_info_rom::@12 to printf_str [phi:display_info_rom::@12->printf_str]
    // [850] phi printf_str::putc#48 = &cputc [phi:display_info_rom::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = s2 [phi:display_info_rom::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@13
    // [1127] printf_string::str#32 = printf_string::str#10 -- pbuz1=pbuz2 
    lda.z printf_string.str_1
    sta.z printf_string.str
    lda.z printf_string.str_1+1
    sta.z printf_string.str+1
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1128] call printf_string
    // [993] phi from display_info_rom::@13 to printf_string [phi:display_info_rom::@13->printf_string]
    // [993] phi printf_string::putc#21 = &cputc [phi:display_info_rom::@13->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [993] phi printf_string::str#21 = printf_string::str#32 [phi:display_info_rom::@13->printf_string#1] -- register_copy 
    // [993] phi printf_string::format_justify_left#21 = 1 [phi:display_info_rom::@13->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [993] phi printf_string::format_min_length#21 = $d [phi:display_info_rom::@13->printf_string#3] -- vbuz1=vbuc1 
    lda #$d
    sta.z printf_string.format_min_length
    jsr printf_string
    // [1129] phi from display_info_rom::@13 to display_info_rom::@14 [phi:display_info_rom::@13->display_info_rom::@14]
    // display_info_rom::@14
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1130] call printf_str
    // [850] phi from display_info_rom::@14 to printf_str [phi:display_info_rom::@14->printf_str]
    // [850] phi printf_str::putc#48 = &cputc [phi:display_info_rom::@14->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = s2 [phi:display_info_rom::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@15
    // if(info_text)
    // [1131] if((char *)0==display_info_rom::info_text#10) goto display_info_rom::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // display_info_rom::@2
    // printf("%-25s", info_text)
    // [1132] printf_string::str#11 = display_info_rom::info_text#10 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1133] call printf_string
    // [993] phi from display_info_rom::@2 to printf_string [phi:display_info_rom::@2->printf_string]
    // [993] phi printf_string::putc#21 = &cputc [phi:display_info_rom::@2->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [993] phi printf_string::str#21 = printf_string::str#11 [phi:display_info_rom::@2->printf_string#1] -- register_copy 
    // [993] phi printf_string::format_justify_left#21 = 1 [phi:display_info_rom::@2->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [993] phi printf_string::format_min_length#21 = $19 [phi:display_info_rom::@2->printf_string#3] -- vbuz1=vbuc1 
    lda #$19
    sta.z printf_string.format_min_length
    jsr printf_string
    // display_info_rom::@1
  __b1:
    // gotoxy(x,y)
    // [1134] gotoxy::x#18 = display_info_rom::x#0 -- vbuxx=vbum1 
    ldx x
    // [1135] gotoxy::y#18 = display_info_rom::y#0 -- vbuyy=vbum1 
    ldy y
    // [1136] call gotoxy
    // [590] phi from display_info_rom::@1 to gotoxy [phi:display_info_rom::@1->gotoxy]
    // [590] phi gotoxy::y#24 = gotoxy::y#18 [phi:display_info_rom::@1->gotoxy#0] -- register_copy 
    // [590] phi gotoxy::x#24 = gotoxy::x#18 [phi:display_info_rom::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_rom::@return
    // }
    // [1137] return 
    rts
  .segment Data
    s: .text "ROM"
    .byte 0
    x: .byte 0
    y: .byte 0
}
.segment Code
  // display_info_cx16_rom
/**
 * @brief Display the ROM status of the main CX16 ROM chip.
 * 
 * @param info_status The status.
 * @param info_text The status text.
 */
// void display_info_cx16_rom(__register(X) char info_status, __zp($5f) char *info_text)
display_info_cx16_rom: {
    .label info_text = $5f
    // display_info_rom(0, info_status, info_text)
    // [1139] display_info_rom::info_status#0 = display_info_cx16_rom::info_status#2 -- vbuz1=vbuxx 
    stx.z display_info_rom.info_status
    // [1140] display_info_rom::info_text#0 = display_info_cx16_rom::info_text#2
    // [1141] call display_info_rom
    // [1095] phi from display_info_cx16_rom to display_info_rom [phi:display_info_cx16_rom->display_info_rom]
    // [1095] phi display_info_rom::info_text#10 = display_info_rom::info_text#0 [phi:display_info_cx16_rom->display_info_rom#0] -- register_copy 
    // [1095] phi display_info_rom::rom_chip#10 = 0 [phi:display_info_cx16_rom->display_info_rom#1] -- vbuz1=vbuc1 
    lda #0
    sta.z display_info_rom.rom_chip
    // [1095] phi display_info_rom::info_status#10 = display_info_rom::info_status#0 [phi:display_info_cx16_rom->display_info_rom#2] -- register_copy 
    jsr display_info_rom
    // display_info_cx16_rom::@return
    // }
    // [1142] return 
    rts
}
  // rom_file
// __zp($f7) char * rom_file(__register(A) char rom_chip)
rom_file: {
    .label return = $f7
    // if(rom_chip)
    // [1143] if(0!=rom_file::rom_chip#0) goto rom_file::@1 -- 0_neq_vbuaa_then_la1 
    cmp #0
    bne __b1
    // [1146] phi from rom_file to rom_file::@return [phi:rom_file->rom_file::@return]
    // [1146] phi rom_file::return#2 = rom_file::file_rom_cx16 [phi:rom_file->rom_file::@return#0] -- pbuz1=pbuc1 
    lda #<file_rom_cx16
    sta.z return
    lda #>file_rom_cx16
    sta.z return+1
    rts
    // rom_file::@1
  __b1:
    // '0'+rom_chip
    // [1144] rom_file::$0 = '0' + rom_file::rom_chip#0 -- vbuaa=vbuc1_plus_vbuaa 
    clc
    adc #'0'
    // file_rom_card[3] = '0'+rom_chip
    // [1145] *(rom_file::file_rom_card+3) = rom_file::$0 -- _deref_pbuc1=vbuaa 
    sta file_rom_card+3
    // [1146] phi from rom_file::@1 to rom_file::@return [phi:rom_file::@1->rom_file::@return]
    // [1146] phi rom_file::return#2 = rom_file::file_rom_card [phi:rom_file::@1->rom_file::@return#0] -- pbuz1=pbuc1 
    lda #<file_rom_card
    sta.z return
    lda #>file_rom_card
    sta.z return+1
    // rom_file::@return
    // }
    // [1147] return 
    rts
  .segment Data
    file_rom_cx16: .text "ROM.BIN"
    .byte 0
    file_rom_card: .text "ROMn.BIN"
    .byte 0
}
.segment Code
  // rom_read
// __zp($b5) unsigned long rom_read(char display_progress, char rom_chip, __zp($dc) char *file, char info_status, __zp($7c) char brom_bank_start, __zp($d3) unsigned long rom_size)
rom_read: {
    .const bank_set_brom1_bank = 0
    .label rom_read__11 = $25
    .label rom_address = $b9
    .label fp = $da
    .label return = $b5
    .label rom_package_read = $b0
    .label brom_bank_start = $7c
    .label y = $aa
    .label ram_address = $ab
    .label rom_file_size = $b5
    .label rom_row_current = $ae
    .label bram_bank = $7a
    .label file = $dc
    .label rom_size = $d3
    // unsigned long rom_address = rom_address_from_bank(brom_bank_start)
    // [1148] rom_address_from_bank::rom_bank#0 = rom_read::brom_bank_start#1 -- vbuaa=vbuz1 
    lda.z brom_bank_start
    // [1149] call rom_address_from_bank
    jsr rom_address_from_bank
    // [1150] rom_address_from_bank::return#2 = rom_address_from_bank::return#0
    // rom_read::@16
    // [1151] rom_read::rom_address#0 = rom_address_from_bank::return#2
    // rom_read::bank_set_bram1
    // BRAM = bank
    // [1152] BRAM = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z BRAM
    // rom_read::bank_set_brom1
    // BROM = bank
    // [1153] BROM = rom_read::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [1154] phi from rom_read::bank_set_brom1 to rom_read::@14 [phi:rom_read::bank_set_brom1->rom_read::@14]
    // rom_read::@14
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1155] call snprintf_init
    // [845] phi from rom_read::@14 to snprintf_init [phi:rom_read::@14->snprintf_init]
    // [845] phi snprintf_init::s#15 = info_text [phi:rom_read::@14->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1156] phi from rom_read::@14 to rom_read::@17 [phi:rom_read::@14->rom_read::@17]
    // rom_read::@17
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1157] call printf_str
    // [850] phi from rom_read::@17 to printf_str [phi:rom_read::@17->printf_str]
    // [850] phi printf_str::putc#48 = &snputc [phi:rom_read::@17->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = rom_read::s [phi:rom_read::@17->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@18
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1158] printf_string::str#13 = rom_read::file#0 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [1159] call printf_string
    // [993] phi from rom_read::@18 to printf_string [phi:rom_read::@18->printf_string]
    // [993] phi printf_string::putc#21 = &snputc [phi:rom_read::@18->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [993] phi printf_string::str#21 = printf_string::str#13 [phi:rom_read::@18->printf_string#1] -- register_copy 
    // [993] phi printf_string::format_justify_left#21 = 0 [phi:rom_read::@18->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [993] phi printf_string::format_min_length#21 = 0 [phi:rom_read::@18->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [1160] phi from rom_read::@18 to rom_read::@19 [phi:rom_read::@18->rom_read::@19]
    // rom_read::@19
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1161] call printf_str
    // [850] phi from rom_read::@19 to printf_str [phi:rom_read::@19->printf_str]
    // [850] phi printf_str::putc#48 = &snputc [phi:rom_read::@19->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = rom_read::s1 [phi:rom_read::@19->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@20
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1162] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1163] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1165] call display_action_text
    // [1039] phi from rom_read::@20 to display_action_text [phi:rom_read::@20->display_action_text]
    // [1039] phi display_action_text::info_text#10 = info_text [phi:rom_read::@20->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // rom_read::@21
    // FILE *fp = fopen(file, "r")
    // [1166] fopen::path#3 = rom_read::file#0 -- pbuz1=pbuz2 
    lda.z file
    sta.z fopen.path
    lda.z file+1
    sta.z fopen.path+1
    // [1167] call fopen
    // [1647] phi from rom_read::@21 to fopen [phi:rom_read::@21->fopen]
    // [1647] phi __errno#295 = __errno#115 [phi:rom_read::@21->fopen#0] -- register_copy 
    // [1647] phi fopen::pathtoken#0 = fopen::path#3 [phi:rom_read::@21->fopen#1] -- register_copy 
    jsr fopen
    // FILE *fp = fopen(file, "r")
    // [1168] fopen::return#4 = fopen::return#2
    // rom_read::@22
    // [1169] rom_read::fp#0 = fopen::return#4 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [1170] if((struct $2 *)0==rom_read::fp#0) goto rom_read::@1 -- pssc1_eq_pssz1_then_la1 
    lda.z fp
    cmp #<0
    bne !+
    lda.z fp+1
    cmp #>0
    beq __b2
  !:
    // [1171] phi from rom_read::@22 to rom_read::@2 [phi:rom_read::@22->rom_read::@2]
    // rom_read::@2
    // gotoxy(x, y)
    // [1172] call gotoxy
    // [590] phi from rom_read::@2 to gotoxy [phi:rom_read::@2->gotoxy]
    // [590] phi gotoxy::y#24 = PROGRESS_Y [phi:rom_read::@2->gotoxy#0] -- vbuyy=vbuc1 
    ldy #PROGRESS_Y
    // [590] phi gotoxy::x#24 = PROGRESS_X [phi:rom_read::@2->gotoxy#1] -- vbuxx=vbuc1 
    ldx #PROGRESS_X
    jsr gotoxy
    // [1173] phi from rom_read::@2 to rom_read::@3 [phi:rom_read::@2->rom_read::@3]
    // [1173] phi rom_read::y#11 = PROGRESS_Y [phi:rom_read::@2->rom_read::@3#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // [1173] phi rom_read::rom_row_current#10 = 0 [phi:rom_read::@2->rom_read::@3#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z rom_row_current
    sta.z rom_row_current+1
    // [1173] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#1 [phi:rom_read::@2->rom_read::@3#2] -- register_copy 
    // [1173] phi rom_read::rom_address#10 = rom_read::rom_address#0 [phi:rom_read::@2->rom_read::@3#3] -- register_copy 
    // [1173] phi rom_read::ram_address#10 = (char *)$7800 [phi:rom_read::@2->rom_read::@3#4] -- pbuz1=pbuc1 
    lda #<$7800
    sta.z ram_address
    lda #>$7800
    sta.z ram_address+1
    // [1173] phi rom_read::bram_bank#10 = 0 [phi:rom_read::@2->rom_read::@3#5] -- vbuz1=vbuc1 
    lda #0
    sta.z bram_bank
    // [1173] phi rom_read::rom_file_size#11 = 0 [phi:rom_read::@2->rom_read::@3#6] -- vduz1=vduc1 
    sta.z rom_file_size
    sta.z rom_file_size+1
    lda #<0>>$10
    sta.z rom_file_size+2
    lda #>0>>$10
    sta.z rom_file_size+3
    // rom_read::@3
  __b3:
    // while (rom_file_size < rom_size)
    // [1174] if(rom_read::rom_file_size#11<rom_read::rom_size#0) goto rom_read::@4 -- vduz1_lt_vduz2_then_la1 
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
    // [1175] fclose::stream#1 = rom_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fclose.stream
    lda.z fp+1
    sta.z fclose.stream+1
    // [1176] call fclose
    // [1782] phi from rom_read::@7 to fclose [phi:rom_read::@7->fclose]
    // [1782] phi fclose::stream#2 = fclose::stream#1 [phi:rom_read::@7->fclose#0] -- register_copy 
    jsr fclose
    // [1177] phi from rom_read::@7 to rom_read::@1 [phi:rom_read::@7->rom_read::@1]
    // [1177] phi rom_read::return#0 = rom_read::rom_file_size#11 [phi:rom_read::@7->rom_read::@1#0] -- register_copy 
    rts
    // [1177] phi from rom_read::@22 to rom_read::@1 [phi:rom_read::@22->rom_read::@1]
  __b2:
    // [1177] phi rom_read::return#0 = 0 [phi:rom_read::@22->rom_read::@1#0] -- vduz1=vduc1 
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
    // [1178] return 
    rts
    // [1179] phi from rom_read::@3 to rom_read::@4 [phi:rom_read::@3->rom_read::@4]
    // rom_read::@4
  __b4:
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1180] call snprintf_init
    // [845] phi from rom_read::@4 to snprintf_init [phi:rom_read::@4->snprintf_init]
    // [845] phi snprintf_init::s#15 = info_text [phi:rom_read::@4->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1181] phi from rom_read::@4 to rom_read::@23 [phi:rom_read::@4->rom_read::@23]
    // rom_read::@23
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1182] call printf_str
    // [850] phi from rom_read::@23 to printf_str [phi:rom_read::@23->printf_str]
    // [850] phi printf_str::putc#48 = &snputc [phi:rom_read::@23->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = rom_read::s2 [phi:rom_read::@23->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@24
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1183] printf_string::str#14 = rom_read::file#0 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [1184] call printf_string
    // [993] phi from rom_read::@24 to printf_string [phi:rom_read::@24->printf_string]
    // [993] phi printf_string::putc#21 = &snputc [phi:rom_read::@24->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [993] phi printf_string::str#21 = printf_string::str#14 [phi:rom_read::@24->printf_string#1] -- register_copy 
    // [993] phi printf_string::format_justify_left#21 = 0 [phi:rom_read::@24->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [993] phi printf_string::format_min_length#21 = 0 [phi:rom_read::@24->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [1185] phi from rom_read::@24 to rom_read::@25 [phi:rom_read::@24->rom_read::@25]
    // rom_read::@25
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1186] call printf_str
    // [850] phi from rom_read::@25 to printf_str [phi:rom_read::@25->printf_str]
    // [850] phi printf_str::putc#48 = &snputc [phi:rom_read::@25->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = s3 [phi:rom_read::@25->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@26
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1187] printf_ulong::uvalue#0 = rom_read::rom_file_size#11 -- vduz1=vduz2 
    lda.z rom_file_size
    sta.z printf_ulong.uvalue
    lda.z rom_file_size+1
    sta.z printf_ulong.uvalue+1
    lda.z rom_file_size+2
    sta.z printf_ulong.uvalue+2
    lda.z rom_file_size+3
    sta.z printf_ulong.uvalue+3
    // [1188] call printf_ulong
    // [1860] phi from rom_read::@26 to printf_ulong [phi:rom_read::@26->printf_ulong]
    // [1860] phi printf_ulong::uvalue#2 = printf_ulong::uvalue#0 [phi:rom_read::@26->printf_ulong#0] -- register_copy 
    jsr printf_ulong
    // [1189] phi from rom_read::@26 to rom_read::@27 [phi:rom_read::@26->rom_read::@27]
    // rom_read::@27
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1190] call printf_str
    // [850] phi from rom_read::@27 to printf_str [phi:rom_read::@27->printf_str]
    // [850] phi printf_str::putc#48 = &snputc [phi:rom_read::@27->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = s1 [phi:rom_read::@27->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s1
    sta.z printf_str.s
    lda #>@s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@28
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1191] printf_ulong::uvalue#1 = rom_read::rom_size#0 -- vduz1=vduz2 
    lda.z rom_size
    sta.z printf_ulong.uvalue
    lda.z rom_size+1
    sta.z printf_ulong.uvalue+1
    lda.z rom_size+2
    sta.z printf_ulong.uvalue+2
    lda.z rom_size+3
    sta.z printf_ulong.uvalue+3
    // [1192] call printf_ulong
    // [1860] phi from rom_read::@28 to printf_ulong [phi:rom_read::@28->printf_ulong]
    // [1860] phi printf_ulong::uvalue#2 = printf_ulong::uvalue#1 [phi:rom_read::@28->printf_ulong#0] -- register_copy 
    jsr printf_ulong
    // [1193] phi from rom_read::@28 to rom_read::@29 [phi:rom_read::@28->rom_read::@29]
    // rom_read::@29
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1194] call printf_str
    // [850] phi from rom_read::@29 to printf_str [phi:rom_read::@29->printf_str]
    // [850] phi printf_str::putc#48 = &snputc [phi:rom_read::@29->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = s5 [phi:rom_read::@29->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@30
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1195] printf_uchar::uvalue#6 = rom_read::bram_bank#10 -- vbuxx=vbuz1 
    ldx.z bram_bank
    // [1196] call printf_uchar
    // [1028] phi from rom_read::@30 to printf_uchar [phi:rom_read::@30->printf_uchar]
    // [1028] phi printf_uchar::format_zero_padding#10 = 1 [phi:rom_read::@30->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1028] phi printf_uchar::format_min_length#10 = 2 [phi:rom_read::@30->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [1028] phi printf_uchar::putc#10 = &snputc [phi:rom_read::@30->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1028] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:rom_read::@30->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #HEXADECIMAL
    // [1028] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#6 [phi:rom_read::@30->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1197] phi from rom_read::@30 to rom_read::@31 [phi:rom_read::@30->rom_read::@31]
    // rom_read::@31
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1198] call printf_str
    // [850] phi from rom_read::@31 to printf_str [phi:rom_read::@31->printf_str]
    // [850] phi printf_str::putc#48 = &snputc [phi:rom_read::@31->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = s3 [phi:rom_read::@31->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@32
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1199] printf_uint::uvalue#4 = (unsigned int)rom_read::ram_address#10 -- vwuz1=vwuz2 
    lda.z ram_address
    sta.z printf_uint.uvalue
    lda.z ram_address+1
    sta.z printf_uint.uvalue+1
    // [1200] call printf_uint
    // [859] phi from rom_read::@32 to printf_uint [phi:rom_read::@32->printf_uint]
    // [859] phi printf_uint::format_zero_padding#10 = 1 [phi:rom_read::@32->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [859] phi printf_uint::format_min_length#10 = 4 [phi:rom_read::@32->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [859] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:rom_read::@32->printf_uint#2] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [859] phi printf_uint::uvalue#10 = printf_uint::uvalue#4 [phi:rom_read::@32->printf_uint#3] -- register_copy 
    jsr printf_uint
    // [1201] phi from rom_read::@32 to rom_read::@33 [phi:rom_read::@32->rom_read::@33]
    // rom_read::@33
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1202] call printf_str
    // [850] phi from rom_read::@33 to printf_str [phi:rom_read::@33->printf_str]
    // [850] phi printf_str::putc#48 = &snputc [phi:rom_read::@33->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = s4 [phi:rom_read::@33->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@34
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1203] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1204] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1206] call display_action_text
    // [1039] phi from rom_read::@34 to display_action_text [phi:rom_read::@34->display_action_text]
    // [1039] phi display_action_text::info_text#10 = info_text [phi:rom_read::@34->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // rom_read::@35
    // rom_address % 0x04000
    // [1207] rom_read::$11 = rom_read::rom_address#10 & $4000-1 -- vduz1=vduz2_band_vduc1 
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
    // [1208] if(0!=rom_read::$11) goto rom_read::@5 -- 0_neq_vduz1_then_la1 
    lda.z rom_read__11
    ora.z rom_read__11+1
    ora.z rom_read__11+2
    ora.z rom_read__11+3
    bne __b5
    // rom_read::@11
    // brom_bank_start++;
    // [1209] rom_read::brom_bank_start#0 = ++ rom_read::brom_bank_start#10 -- vbuz1=_inc_vbuz1 
    inc.z brom_bank_start
    // [1210] phi from rom_read::@11 rom_read::@35 to rom_read::@5 [phi:rom_read::@11/rom_read::@35->rom_read::@5]
    // [1210] phi rom_read::brom_bank_start#19 = rom_read::brom_bank_start#0 [phi:rom_read::@11/rom_read::@35->rom_read::@5#0] -- register_copy 
    // rom_read::@5
  __b5:
    // rom_read::bank_set_bram2
    // BRAM = bank
    // [1211] BRAM = rom_read::bram_bank#10 -- vbuz1=vbuz2 
    lda.z bram_bank
    sta.z BRAM
    // rom_read::@15
    // unsigned int rom_package_read = fgets(ram_address, ROM_PROGRESS_CELL, fp)
    // [1212] fgets::ptr#3 = rom_read::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z fgets.ptr
    lda.z ram_address+1
    sta.z fgets.ptr+1
    // [1213] fgets::stream#1 = rom_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.stream
    lda.z fp+1
    sta.z fgets.stream+1
    // [1214] call fgets
    // [1728] phi from rom_read::@15 to fgets [phi:rom_read::@15->fgets]
    // [1728] phi fgets::ptr#12 = fgets::ptr#3 [phi:rom_read::@15->fgets#0] -- register_copy 
    // [1728] phi fgets::size#10 = ROM_PROGRESS_CELL [phi:rom_read::@15->fgets#1] -- vwuz1=vwuc1 
    lda #<ROM_PROGRESS_CELL
    sta.z fgets.size
    lda #>ROM_PROGRESS_CELL
    sta.z fgets.size+1
    // [1728] phi fgets::stream#2 = fgets::stream#1 [phi:rom_read::@15->fgets#2] -- register_copy 
    jsr fgets
    // unsigned int rom_package_read = fgets(ram_address, ROM_PROGRESS_CELL, fp)
    // [1215] fgets::return#6 = fgets::return#1
    // rom_read::@36
    // [1216] rom_read::rom_package_read#0 = fgets::return#6 -- vwuz1=vwuz2 
    lda.z fgets.return
    sta.z rom_package_read
    lda.z fgets.return+1
    sta.z rom_package_read+1
    // if (!rom_package_read)
    // [1217] if(0!=rom_read::rom_package_read#0) goto rom_read::@6 -- 0_neq_vwuz1_then_la1 
    lda.z rom_package_read
    ora.z rom_package_read+1
    bne __b6
    jmp __b7
    // rom_read::@6
  __b6:
    // if (rom_row_current == ROM_PROGRESS_ROW)
    // [1218] if(rom_read::rom_row_current#10!=ROM_PROGRESS_ROW) goto rom_read::@8 -- vwuz1_neq_vwuc1_then_la1 
    lda.z rom_row_current+1
    cmp #>ROM_PROGRESS_ROW
    bne __b9
    lda.z rom_row_current
    cmp #<ROM_PROGRESS_ROW
    bne __b9
    // rom_read::@12
    // gotoxy(x, ++y);
    // [1219] rom_read::y#1 = ++ rom_read::y#11 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [1220] gotoxy::y#23 = rom_read::y#1 -- vbuyy=vbuz1 
    ldy.z y
    // [1221] call gotoxy
    // [590] phi from rom_read::@12 to gotoxy [phi:rom_read::@12->gotoxy]
    // [590] phi gotoxy::y#24 = gotoxy::y#23 [phi:rom_read::@12->gotoxy#0] -- register_copy 
    // [590] phi gotoxy::x#24 = PROGRESS_X [phi:rom_read::@12->gotoxy#1] -- vbuxx=vbuc1 
    ldx #PROGRESS_X
    jsr gotoxy
    // [1222] phi from rom_read::@12 to rom_read::@8 [phi:rom_read::@12->rom_read::@8]
    // [1222] phi rom_read::y#36 = rom_read::y#1 [phi:rom_read::@12->rom_read::@8#0] -- register_copy 
    // [1222] phi rom_read::rom_row_current#4 = 0 [phi:rom_read::@12->rom_read::@8#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z rom_row_current
    sta.z rom_row_current+1
    // [1222] phi from rom_read::@6 to rom_read::@8 [phi:rom_read::@6->rom_read::@8]
    // [1222] phi rom_read::y#36 = rom_read::y#11 [phi:rom_read::@6->rom_read::@8#0] -- register_copy 
    // [1222] phi rom_read::rom_row_current#4 = rom_read::rom_row_current#10 [phi:rom_read::@6->rom_read::@8#1] -- register_copy 
    // rom_read::@8
    // rom_read::@9
  __b9:
    // ram_address += rom_package_read
    // [1223] rom_read::ram_address#1 = rom_read::ram_address#10 + rom_read::rom_package_read#0 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z ram_address
    adc.z rom_package_read
    sta.z ram_address
    lda.z ram_address+1
    adc.z rom_package_read+1
    sta.z ram_address+1
    // rom_address += rom_package_read
    // [1224] rom_read::rom_address#1 = rom_read::rom_address#10 + rom_read::rom_package_read#0 -- vduz1=vduz1_plus_vwuz2 
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
    // [1225] rom_read::rom_file_size#1 = rom_read::rom_file_size#11 + rom_read::rom_package_read#0 -- vduz1=vduz1_plus_vwuz2 
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
    // [1226] rom_read::rom_row_current#2 = rom_read::rom_row_current#4 + rom_read::rom_package_read#0 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z rom_row_current
    adc.z rom_package_read
    sta.z rom_row_current
    lda.z rom_row_current+1
    adc.z rom_package_read+1
    sta.z rom_row_current+1
    // if (ram_address == (ram_ptr_t)BRAM_HIGH)
    // [1227] if(rom_read::ram_address#1!=(char *)$c000) goto rom_read::@10 -- pbuz1_neq_pbuc1_then_la1 
    lda.z ram_address+1
    cmp #>$c000
    bne __b10
    lda.z ram_address
    cmp #<$c000
    bne __b10
    // rom_read::@13
    // bram_bank++;
    // [1228] rom_read::bram_bank#1 = ++ rom_read::bram_bank#10 -- vbuz1=_inc_vbuz1 
    inc.z bram_bank
    // [1229] phi from rom_read::@13 to rom_read::@10 [phi:rom_read::@13->rom_read::@10]
    // [1229] phi rom_read::bram_bank#31 = rom_read::bram_bank#1 [phi:rom_read::@13->rom_read::@10#0] -- register_copy 
    // [1229] phi rom_read::ram_address#7 = (char *)$a000 [phi:rom_read::@13->rom_read::@10#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1229] phi from rom_read::@9 to rom_read::@10 [phi:rom_read::@9->rom_read::@10]
    // [1229] phi rom_read::bram_bank#31 = rom_read::bram_bank#10 [phi:rom_read::@9->rom_read::@10#0] -- register_copy 
    // [1229] phi rom_read::ram_address#7 = rom_read::ram_address#1 [phi:rom_read::@9->rom_read::@10#1] -- register_copy 
    // rom_read::@10
  __b10:
    // if (ram_address == (ram_ptr_t)RAM_HIGH)
    // [1230] if(rom_read::ram_address#7!=(char *)$9800) goto rom_read::@37 -- pbuz1_neq_pbuc1_then_la1 
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
    // [1173] phi from rom_read::@10 to rom_read::@3 [phi:rom_read::@10->rom_read::@3]
    // [1173] phi rom_read::y#11 = rom_read::y#36 [phi:rom_read::@10->rom_read::@3#0] -- register_copy 
    // [1173] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#2 [phi:rom_read::@10->rom_read::@3#1] -- register_copy 
    // [1173] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#19 [phi:rom_read::@10->rom_read::@3#2] -- register_copy 
    // [1173] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@10->rom_read::@3#3] -- register_copy 
    // [1173] phi rom_read::ram_address#10 = (char *)$a000 [phi:rom_read::@10->rom_read::@3#4] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1173] phi rom_read::bram_bank#10 = 1 [phi:rom_read::@10->rom_read::@3#5] -- vbuz1=vbuc1 
    lda #1
    sta.z bram_bank
    // [1173] phi rom_read::rom_file_size#11 = rom_read::rom_file_size#1 [phi:rom_read::@10->rom_read::@3#6] -- register_copy 
    jmp __b3
    // [1231] phi from rom_read::@10 to rom_read::@37 [phi:rom_read::@10->rom_read::@37]
    // rom_read::@37
    // [1173] phi from rom_read::@37 to rom_read::@3 [phi:rom_read::@37->rom_read::@3]
    // [1173] phi rom_read::y#11 = rom_read::y#36 [phi:rom_read::@37->rom_read::@3#0] -- register_copy 
    // [1173] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#2 [phi:rom_read::@37->rom_read::@3#1] -- register_copy 
    // [1173] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#19 [phi:rom_read::@37->rom_read::@3#2] -- register_copy 
    // [1173] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@37->rom_read::@3#3] -- register_copy 
    // [1173] phi rom_read::ram_address#10 = rom_read::ram_address#7 [phi:rom_read::@37->rom_read::@3#4] -- register_copy 
    // [1173] phi rom_read::bram_bank#10 = rom_read::bram_bank#31 [phi:rom_read::@37->rom_read::@3#5] -- register_copy 
    // [1173] phi rom_read::rom_file_size#11 = rom_read::rom_file_size#1 [phi:rom_read::@37->rom_read::@3#6] -- register_copy 
  .segment Data
    s: .text "Opening "
    .byte 0
    s1: .text " from SD card ..."
    .byte 0
    s2: .text "Reading "
    .byte 0
}
.segment Code
  // rom_get_github_commit_id
/**
 * @brief Copy the github commit_id only if the commit_id contains hexadecimal characters. 
 * 
 * @param commit_id The target commit_id.
 * @param from The source ptr in ROM or RAM.
 */
// void rom_get_github_commit_id(__zp($5f) char *commit_id, __zp($49) char *from)
rom_get_github_commit_id: {
    .label commit_id = $5f
    .label from = $49
    // [1233] phi from rom_get_github_commit_id to rom_get_github_commit_id::@2 [phi:rom_get_github_commit_id->rom_get_github_commit_id::@2]
    // [1233] phi rom_get_github_commit_id::commit_id_ok#2 = true [phi:rom_get_github_commit_id->rom_get_github_commit_id::@2#0] -- vboxx=vboc1 
    lda #1
    tax
    // [1233] phi rom_get_github_commit_id::c#2 = 0 [phi:rom_get_github_commit_id->rom_get_github_commit_id::@2#1] -- vbuyy=vbuc1 
    ldy #0
    // rom_get_github_commit_id::@2
  __b2:
    // for(unsigned char c=0; c<7; c++)
    // [1234] if(rom_get_github_commit_id::c#2<7) goto rom_get_github_commit_id::@3 -- vbuyy_lt_vbuc1_then_la1 
    cpy #7
    bcc __b3
    // rom_get_github_commit_id::@4
    // if(commit_id_ok)
    // [1235] if(rom_get_github_commit_id::commit_id_ok#2) goto rom_get_github_commit_id::@1 -- vboxx_then_la1 
    cpx #0
    bne __b1
    // rom_get_github_commit_id::@6
    // *commit_id = '\0'
    // [1236] *rom_get_github_commit_id::commit_id#6 = '@' -- _deref_pbuz1=vbuc1 
    lda #'@'
    ldy #0
    sta (commit_id),y
    // rom_get_github_commit_id::@return
    // }
    // [1237] return 
    rts
    // rom_get_github_commit_id::@1
  __b1:
    // strncpy(commit_id, from, 7)
    // [1238] strncpy::dst#2 = rom_get_github_commit_id::commit_id#6
    // [1239] strncpy::src#2 = rom_get_github_commit_id::from#6
    // [1240] call strncpy
    // [1867] phi from rom_get_github_commit_id::@1 to strncpy [phi:rom_get_github_commit_id::@1->strncpy]
    // [1867] phi strncpy::dst#8 = strncpy::dst#2 [phi:rom_get_github_commit_id::@1->strncpy#0] -- register_copy 
    // [1867] phi strncpy::src#6 = strncpy::src#2 [phi:rom_get_github_commit_id::@1->strncpy#1] -- register_copy 
    // [1867] phi strncpy::n#3 = 7 [phi:rom_get_github_commit_id::@1->strncpy#2] -- vwuz1=vbuc1 
    lda #<7
    sta.z strncpy.n
    lda #>7
    sta.z strncpy.n+1
    jsr strncpy
    rts
    // rom_get_github_commit_id::@3
  __b3:
    // unsigned char ch = from[c]
    // [1241] rom_get_github_commit_id::ch#0 = rom_get_github_commit_id::from#6[rom_get_github_commit_id::c#2] -- vbuaa=pbuz1_derefidx_vbuyy 
    lda (from),y
    // if(!(ch >= 48 && ch <= 48+9 || ch >= 65 && ch <= 65+26))
    // [1242] if(rom_get_github_commit_id::ch#0<$30) goto rom_get_github_commit_id::@7 -- vbuaa_lt_vbuc1_then_la1 
    cmp #$30
    bcc __b7
    // rom_get_github_commit_id::@8
    // [1243] if(rom_get_github_commit_id::ch#0<$30+9+1) goto rom_get_github_commit_id::@5 -- vbuaa_lt_vbuc1_then_la1 
    cmp #$30+9+1
    bcc __b5
    // rom_get_github_commit_id::@7
  __b7:
    // [1244] if(rom_get_github_commit_id::ch#0<$41) goto rom_get_github_commit_id::@5 -- vbuaa_lt_vbuc1_then_la1 
    cmp #$41
    bcc __b4
    // rom_get_github_commit_id::@9
    // [1245] if(rom_get_github_commit_id::ch#0<$41+$1a+1) goto rom_get_github_commit_id::@10 -- vbuaa_lt_vbuc1_then_la1 
    cmp #$41+$1a+1
    bcc __b5
    // [1247] phi from rom_get_github_commit_id::@7 rom_get_github_commit_id::@9 to rom_get_github_commit_id::@5 [phi:rom_get_github_commit_id::@7/rom_get_github_commit_id::@9->rom_get_github_commit_id::@5]
  __b4:
    // [1247] phi rom_get_github_commit_id::commit_id_ok#4 = false [phi:rom_get_github_commit_id::@7/rom_get_github_commit_id::@9->rom_get_github_commit_id::@5#0] -- vboxx=vboc1 
    lda #0
    tax
    // [1246] phi from rom_get_github_commit_id::@9 to rom_get_github_commit_id::@10 [phi:rom_get_github_commit_id::@9->rom_get_github_commit_id::@10]
    // rom_get_github_commit_id::@10
    // [1247] phi from rom_get_github_commit_id::@10 rom_get_github_commit_id::@8 to rom_get_github_commit_id::@5 [phi:rom_get_github_commit_id::@10/rom_get_github_commit_id::@8->rom_get_github_commit_id::@5]
    // [1247] phi rom_get_github_commit_id::commit_id_ok#4 = rom_get_github_commit_id::commit_id_ok#2 [phi:rom_get_github_commit_id::@10/rom_get_github_commit_id::@8->rom_get_github_commit_id::@5#0] -- register_copy 
    // rom_get_github_commit_id::@5
  __b5:
    // for(unsigned char c=0; c<7; c++)
    // [1248] rom_get_github_commit_id::c#1 = ++ rom_get_github_commit_id::c#2 -- vbuyy=_inc_vbuyy 
    iny
    // [1233] phi from rom_get_github_commit_id::@5 to rom_get_github_commit_id::@2 [phi:rom_get_github_commit_id::@5->rom_get_github_commit_id::@2]
    // [1233] phi rom_get_github_commit_id::commit_id_ok#2 = rom_get_github_commit_id::commit_id_ok#4 [phi:rom_get_github_commit_id::@5->rom_get_github_commit_id::@2#0] -- register_copy 
    // [1233] phi rom_get_github_commit_id::c#2 = rom_get_github_commit_id::c#1 [phi:rom_get_github_commit_id::@5->rom_get_github_commit_id::@2#1] -- register_copy 
    jmp __b2
}
  // rom_get_version_text
// void rom_get_version_text(__zp($5b) char *release_info, __zp($f1) char prefix, __zp($ed) char release, __zp($61) char *github)
rom_get_version_text: {
    .label release_info = $5b
    .label prefix = $f1
    .label release = $ed
    .label github = $61
    // sprintf(release_info, "v%u%c-%s", release, prefix, github)
    // [1250] snprintf_init::s#2 = rom_get_version_text::release_info#2
    // [1251] call snprintf_init
    // [845] phi from rom_get_version_text to snprintf_init [phi:rom_get_version_text->snprintf_init]
    // [845] phi snprintf_init::s#15 = snprintf_init::s#2 [phi:rom_get_version_text->snprintf_init#0] -- register_copy 
    jsr snprintf_init
    // [1252] phi from rom_get_version_text to rom_get_version_text::@1 [phi:rom_get_version_text->rom_get_version_text::@1]
    // rom_get_version_text::@1
    // sprintf(release_info, "v%u%c-%s", release, prefix, github)
    // [1253] call printf_str
    // [850] phi from rom_get_version_text::@1 to printf_str [phi:rom_get_version_text::@1->printf_str]
    // [850] phi printf_str::putc#48 = &snputc [phi:rom_get_version_text::@1->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = rom_get_version_text::s [phi:rom_get_version_text::@1->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_get_version_text::@2
    // sprintf(release_info, "v%u%c-%s", release, prefix, github)
    // [1254] printf_uchar::uvalue#4 = rom_get_version_text::release#2 -- vbuxx=vbuz1 
    ldx.z release
    // [1255] call printf_uchar
    // [1028] phi from rom_get_version_text::@2 to printf_uchar [phi:rom_get_version_text::@2->printf_uchar]
    // [1028] phi printf_uchar::format_zero_padding#10 = 0 [phi:rom_get_version_text::@2->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1028] phi printf_uchar::format_min_length#10 = 0 [phi:rom_get_version_text::@2->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1028] phi printf_uchar::putc#10 = &snputc [phi:rom_get_version_text::@2->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1028] phi printf_uchar::format_radix#10 = DECIMAL [phi:rom_get_version_text::@2->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [1028] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#4 [phi:rom_get_version_text::@2->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // rom_get_version_text::@3
    // sprintf(release_info, "v%u%c-%s", release, prefix, github)
    // [1256] stackpush(char) = rom_get_version_text::prefix#2 -- _stackpushbyte_=vbuz1 
    lda.z prefix
    pha
    // [1257] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [1259] call printf_str
    // [850] phi from rom_get_version_text::@3 to printf_str [phi:rom_get_version_text::@3->printf_str]
    // [850] phi printf_str::putc#48 = &snputc [phi:rom_get_version_text::@3->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [850] phi printf_str::s#48 = rom_get_version_text::s1 [phi:rom_get_version_text::@3->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_get_version_text::@4
    // sprintf(release_info, "v%u%c-%s", release, prefix, github)
    // [1260] printf_string::str#12 = rom_get_version_text::github#2 -- pbuz1=pbuz2 
    lda.z github
    sta.z printf_string.str
    lda.z github+1
    sta.z printf_string.str+1
    // [1261] call printf_string
    // [993] phi from rom_get_version_text::@4 to printf_string [phi:rom_get_version_text::@4->printf_string]
    // [993] phi printf_string::putc#21 = &snputc [phi:rom_get_version_text::@4->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [993] phi printf_string::str#21 = printf_string::str#12 [phi:rom_get_version_text::@4->printf_string#1] -- register_copy 
    // [993] phi printf_string::format_justify_left#21 = 0 [phi:rom_get_version_text::@4->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [993] phi printf_string::format_min_length#21 = 0 [phi:rom_get_version_text::@4->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // rom_get_version_text::@5
    // sprintf(release_info, "v%u%c-%s", release, prefix, github)
    // [1262] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1263] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // rom_get_version_text::@return
    // }
    // [1265] return 
    rts
  .segment Data
    s: .text "v"
    .byte 0
    s1: .text "-"
    .byte 0
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
// void display_info_led(__register(Y) char x, __zp($cf) char y, __register(X) char tc, char bc)
display_info_led: {
    .label y = $cf
    // textcolor(tc)
    // [1267] textcolor::color#13 = display_info_led::tc#4
    // [1268] call textcolor
    // [572] phi from display_info_led to textcolor [phi:display_info_led->textcolor]
    // [572] phi textcolor::color#17 = textcolor::color#13 [phi:display_info_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [1269] phi from display_info_led to display_info_led::@1 [phi:display_info_led->display_info_led::@1]
    // display_info_led::@1
    // bgcolor(bc)
    // [1270] call bgcolor
    // [577] phi from display_info_led::@1 to bgcolor [phi:display_info_led::@1->bgcolor]
    // [577] phi bgcolor::color#14 = BLUE [phi:display_info_led::@1->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // display_info_led::@2
    // cputcxy(x, y, VERA_CHR_UR)
    // [1271] cputcxy::x#11 = display_info_led::x#4 -- vbuxx=vbuyy 
    tya
    tax
    // [1272] cputcxy::y#11 = display_info_led::y#4 -- vbuyy=vbuz1 
    ldy.z y
    // [1273] call cputcxy
    // [1495] phi from display_info_led::@2 to cputcxy [phi:display_info_led::@2->cputcxy]
    // [1495] phi cputcxy::c#13 = $7c [phi:display_info_led::@2->cputcxy#0] -- vbuz1=vbuc1 
    lda #$7c
    sta.z cputcxy.c
    // [1495] phi cputcxy::y#13 = cputcxy::y#11 [phi:display_info_led::@2->cputcxy#1] -- register_copy 
    // [1495] phi cputcxy::x#13 = cputcxy::x#11 [phi:display_info_led::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [1274] phi from display_info_led::@2 to display_info_led::@3 [phi:display_info_led::@2->display_info_led::@3]
    // display_info_led::@3
    // textcolor(WHITE)
    // [1275] call textcolor
    // [572] phi from display_info_led::@3 to textcolor [phi:display_info_led::@3->textcolor]
    // [572] phi textcolor::color#17 = WHITE [phi:display_info_led::@3->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // display_info_led::@return
    // }
    // [1276] return 
    rts
}
  // screenlayer
// --- layer management in VERA ---
// void screenlayer(char layer, __register(X) char mapbase, __zp($ad) char config)
screenlayer: {
    .label screenlayer__2 = $d7
    .label config = $ad
    .label mapbase_offset = $d7
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [1277] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [1278] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [1279] *((char *)&__conio+2) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+2
    // mapbase >> 7
    // [1280] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbuaa=vbuxx_ror_7 
    txa
    rol
    rol
    and #1
    // __conio.mapbase_bank = mapbase >> 7
    // [1281] *((char *)&__conio+5) = screenlayer::$0 -- _deref_pbuc1=vbuaa 
    sta __conio+5
    // (mapbase)<<1
    // [1282] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbuaa=vbuxx_rol_1 
    txa
    asl
    // MAKEWORD((mapbase)<<1,0)
    // [1283] screenlayer::$2 = screenlayer::$1 w= 0 -- vwuz1=vbuaa_word_vbuc1 
    ldy #0
    sta.z screenlayer__2+1
    sty.z screenlayer__2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [1284] *((unsigned int *)&__conio+3) = screenlayer::$2 -- _deref_pwuc1=vwuz1 
    tya
    sta __conio+3
    lda.z screenlayer__2+1
    sta __conio+3+1
    // config & VERA_LAYER_WIDTH_MASK
    // [1285] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbuaa=vbuz1_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and.z config
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [1286] screenlayer::$8 = screenlayer::$7 >> 4 -- vbuxx=vbuaa_ror_4 
    lsr
    lsr
    lsr
    lsr
    tax
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [1287] *((char *)&__conio+8) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbuxx 
    lda VERA_LAYER_DIM,x
    sta __conio+8
    // config & VERA_LAYER_HEIGHT_MASK
    // [1288] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbuaa=vbuz1_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and.z config
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [1289] screenlayer::$6 = screenlayer::$5 >> 6 -- vbuaa=vbuaa_ror_6 
    rol
    rol
    rol
    and #3
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [1290] *((char *)&__conio+9) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbuaa 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+9
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [1291] screenlayer::$16 = screenlayer::$8 << 1 -- vbuaa=vbuxx_rol_1 
    txa
    asl
    // [1292] *((unsigned int *)&__conio+$a) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbuaa 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    tay
    lda VERA_LAYER_SKIP,y
    sta __conio+$a
    lda VERA_LAYER_SKIP+1,y
    sta __conio+$a+1
    // vera_dc_hscale_temp == 0x80
    // [1293] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vboaa=vbum1_eq_vbuc1 
    lda vera_dc_hscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [1294] screenlayer::$18 = (char)screenlayer::$9 -- vbuxx=vbuaa 
    tax
    // [1295] screenlayer::$10 = $28 << screenlayer::$18 -- vbuaa=vbuc1_rol_vbuxx 
    lda #$28
    cpx #0
    beq !e+
  !:
    asl
    dex
    bne !-
  !e:
    // (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [1296] screenlayer::$11 = screenlayer::$10 - 1 -- vbuaa=vbuaa_minus_1 
    sec
    sbc #1
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [1297] *((char *)&__conio+6) = screenlayer::$11 -- _deref_pbuc1=vbuaa 
    sta __conio+6
    // vera_dc_vscale_temp == 0x80
    // [1298] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vboaa=vbum1_eq_vbuc1 
    lda vera_dc_vscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [1299] screenlayer::$19 = (char)screenlayer::$12 -- vbuxx=vbuaa 
    tax
    // [1300] screenlayer::$13 = $1e << screenlayer::$19 -- vbuaa=vbuc1_rol_vbuxx 
    lda #$1e
    cpx #0
    beq !e+
  !:
    asl
    dex
    bne !-
  !e:
    // (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [1301] screenlayer::$14 = screenlayer::$13 - 1 -- vbuaa=vbuaa_minus_1 
    sec
    sbc #1
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [1302] *((char *)&__conio+7) = screenlayer::$14 -- _deref_pbuc1=vbuaa 
    sta __conio+7
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [1303] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+3) -- vwuz1=_deref_pwuc1 
    lda __conio+3
    sta.z mapbase_offset
    lda __conio+3+1
    sta.z mapbase_offset+1
    // [1304] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [1304] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [1304] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuxx=vbuc1 
    ldx #0
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [1305] if(screenlayer::y#2<=*((char *)&__conio+7)) goto screenlayer::@2 -- vbuxx_le__deref_pbuc1_then_la1 
    lda __conio+7
    stx.z $ff
    cmp.z $ff
    bcs __b2
    // screenlayer::@return
    // }
    // [1306] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [1307] screenlayer::$17 = screenlayer::y#2 << 1 -- vbuaa=vbuxx_rol_1 
    txa
    asl
    // [1308] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbuaa=vwuz1 
    tay
    lda.z mapbase_offset
    sta __conio+$15,y
    lda.z mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [1309] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+$a) -- vwuz1=vwuz1_plus__deref_pwuc1 
    clc
    lda.z mapbase_offset
    adc __conio+$a
    sta.z mapbase_offset
    lda.z mapbase_offset+1
    adc __conio+$a+1
    sta.z mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [1310] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuxx=_inc_vbuxx 
    inx
    // [1304] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [1304] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [1304] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
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
    // [1311] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [1312] if(0!=((char *)&__conio+$f)[*((char *)&__conio+2)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [1313] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // [1314] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [1315] call gotoxy
    // [590] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [590] phi gotoxy::y#24 = 0 [phi:cscroll::@3->gotoxy#0] -- vbuyy=vbuc1 
    ldy #0
    // [590] phi gotoxy::x#24 = 0 [phi:cscroll::@3->gotoxy#1] -- vbuxx=vbuc1 
    ldx #0
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [1316] return 
    rts
    // [1317] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [1318] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [1319] gotoxy::y#3 = *((char *)&__conio+7) -- vbuyy=_deref_pbuc1 
    ldy __conio+7
    // [1320] call gotoxy
    // [590] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [590] phi gotoxy::y#24 = gotoxy::y#3 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [590] phi gotoxy::x#24 = 0 [phi:cscroll::@5->gotoxy#1] -- vbuxx=vbuc1 
    ldx #0
    jsr gotoxy
    // [1321] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [1322] call clearline
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
    // [1323] ((char *)&__conio+$f)[*((char *)&__conio+2)] = scroll::onoff#0 -- pbuc1_derefidx_(_deref_pbuc2)=vbuc3 
    lda #onoff
    ldy __conio+2
    sta __conio+$f,y
    // scroll::@return
    // }
    // [1324] return 
    rts
}
  // clrscr
// clears the screen and moves the cursor to the upper left-hand corner of the screen.
clrscr: {
    .label line_text = $de
    .label ch = $de
    // unsigned int line_text = __conio.mapbase_offset
    // [1325] clrscr::line_text#0 = *((unsigned int *)&__conio+3) -- vwuz1=_deref_pwuc1 
    lda __conio+3
    sta.z line_text
    lda __conio+3+1
    sta.z line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1326] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [1327] clrscr::$0 = *((char *)&__conio+5) | VERA_INC_1 -- vbuaa=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1328] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [1329] clrscr::l#0 = *((char *)&__conio+9) -- vbuxx=_deref_pbuc1 
    ldx __conio+9
    // [1330] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [1330] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [1330] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [1331] clrscr::$1 = byte0  clrscr::ch#0 -- vbuaa=_byte0_vwuz1 
    lda.z ch
    // *VERA_ADDRX_L = BYTE0(ch)
    // [1332] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbuaa 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [1333] clrscr::$2 = byte1  clrscr::ch#0 -- vbuaa=_byte1_vwuz1 
    lda.z ch+1
    // *VERA_ADDRX_M = BYTE1(ch)
    // [1334] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth+1
    // [1335] clrscr::c#0 = *((char *)&__conio+8) + 1 -- vbuyy=_deref_pbuc1_plus_1 
    ldy __conio+8
    iny
    // [1336] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [1336] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [1337] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1338] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [1339] clrscr::c#1 = -- clrscr::c#2 -- vbuyy=_dec_vbuyy 
    dey
    // while(c)
    // [1340] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbuyy_then_la1 
    cpy #0
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [1341] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+$a) -- vwuz1=vwuz1_plus__deref_pwuc1 
    clc
    lda.z line_text
    adc __conio+$a
    sta.z line_text
    lda.z line_text+1
    adc __conio+$a+1
    sta.z line_text+1
    // l--;
    // [1342] clrscr::l#1 = -- clrscr::l#4 -- vbuxx=_dec_vbuxx 
    dex
    // while(l)
    // [1343] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbuxx_then_la1 
    cpx #0
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [1344] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y = 0
    // [1345] *((char *)&__conio+1) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+1
    // __conio.offset = __conio.mapbase_offset
    // [1346] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+3) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+3
    sta __conio+$13
    lda __conio+3+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [1347] return 
    rts
}
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
// void display_frame(char x0, char y0, __zp($ed) char x1, __zp($f1) char y1)
display_frame: {
    .label w = $f9
    .label h = $cc
    .label x = $77
    .label y = $66
    .label x_1 = $64
    .label y_1 = $79
    .label x1 = $ed
    .label y1 = $f1
    // unsigned char w = x1 - x0
    // [1349] display_frame::w#0 = display_frame::x1#16 - display_frame::x#0 -- vbuz1=vbuz2_minus_vbuz3 
    lda.z x1
    sec
    sbc.z x
    sta.z w
    // unsigned char h = y1 - y0
    // [1350] display_frame::h#0 = display_frame::y1#16 - display_frame::y#0 -- vbuz1=vbuz2_minus_vbuz3 
    lda.z y1
    sec
    sbc.z y
    sta.z h
    // unsigned char mask = display_frame_maskxy(x, y)
    // [1351] display_frame_maskxy::x#0 = display_frame::x#0 -- vbuxx=vbuz1 
    ldx.z x
    // [1352] display_frame_maskxy::y#0 = display_frame::y#0 -- vbuyy=vbuz1 
    ldy.z y
    // [1353] call display_frame_maskxy
    // [1911] phi from display_frame to display_frame_maskxy [phi:display_frame->display_frame_maskxy]
    // [1911] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#0 [phi:display_frame->display_frame_maskxy#0] -- register_copy 
    // [1911] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#0 [phi:display_frame->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // unsigned char mask = display_frame_maskxy(x, y)
    // [1354] display_frame_maskxy::return#13 = display_frame_maskxy::return#12
    // display_frame::@13
    // [1355] display_frame::mask#0 = display_frame_maskxy::return#13
    // mask |= 0b0110
    // [1356] display_frame::mask#1 = display_frame::mask#0 | 6 -- vbuaa=vbuaa_bor_vbuc1 
    ora #6
    // unsigned char c = display_frame_char(mask)
    // [1357] display_frame_char::mask#0 = display_frame::mask#1
    // [1358] call display_frame_char
  // Add a corner.
    // [1937] phi from display_frame::@13 to display_frame_char [phi:display_frame::@13->display_frame_char]
    // [1937] phi display_frame_char::mask#10 = display_frame_char::mask#0 [phi:display_frame::@13->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // unsigned char c = display_frame_char(mask)
    // [1359] display_frame_char::return#13 = display_frame_char::return#12
    // display_frame::@14
    // [1360] display_frame::c#0 = display_frame_char::return#13
    // cputcxy(x, y, c)
    // [1361] cputcxy::x#0 = display_frame::x#0 -- vbuxx=vbuz1 
    ldx.z x
    // [1362] cputcxy::y#0 = display_frame::y#0 -- vbuyy=vbuz1 
    ldy.z y
    // [1363] cputcxy::c#0 = display_frame::c#0 -- vbuz1=vbuaa 
    sta.z cputcxy.c
    // [1364] call cputcxy
    // [1495] phi from display_frame::@14 to cputcxy [phi:display_frame::@14->cputcxy]
    // [1495] phi cputcxy::c#13 = cputcxy::c#0 [phi:display_frame::@14->cputcxy#0] -- register_copy 
    // [1495] phi cputcxy::y#13 = cputcxy::y#0 [phi:display_frame::@14->cputcxy#1] -- register_copy 
    // [1495] phi cputcxy::x#13 = cputcxy::x#0 [phi:display_frame::@14->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@15
    // if(w>=2)
    // [1365] if(display_frame::w#0<2) goto display_frame::@36 -- vbuz1_lt_vbuc1_then_la1 
    lda.z w
    cmp #2
    bcs !__b36+
    jmp __b36
  !__b36:
    // display_frame::@2
    // x++;
    // [1366] display_frame::x#1 = ++ display_frame::x#0 -- vbuz1=_inc_vbuz2 
    lda.z x
    inc
    sta.z x_1
    // [1367] phi from display_frame::@2 display_frame::@21 to display_frame::@4 [phi:display_frame::@2/display_frame::@21->display_frame::@4]
    // [1367] phi display_frame::x#10 = display_frame::x#1 [phi:display_frame::@2/display_frame::@21->display_frame::@4#0] -- register_copy 
    // display_frame::@4
  __b4:
    // while(x < x1)
    // [1368] if(display_frame::x#10<display_frame::x1#16) goto display_frame::@5 -- vbuz1_lt_vbuz2_then_la1 
    lda.z x_1
    cmp.z x1
    bcs !__b5+
    jmp __b5
  !__b5:
    // [1369] phi from display_frame::@36 display_frame::@4 to display_frame::@1 [phi:display_frame::@36/display_frame::@4->display_frame::@1]
    // [1369] phi display_frame::x#24 = display_frame::x#30 [phi:display_frame::@36/display_frame::@4->display_frame::@1#0] -- register_copy 
    // display_frame::@1
  __b1:
    // display_frame_maskxy(x, y)
    // [1370] display_frame_maskxy::x#1 = display_frame::x#24 -- vbuxx=vbuz1 
    ldx.z x_1
    // [1371] display_frame_maskxy::y#1 = display_frame::y#0 -- vbuyy=vbuz1 
    ldy.z y
    // [1372] call display_frame_maskxy
    // [1911] phi from display_frame::@1 to display_frame_maskxy [phi:display_frame::@1->display_frame_maskxy]
    // [1911] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#1 [phi:display_frame::@1->display_frame_maskxy#0] -- register_copy 
    // [1911] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#1 [phi:display_frame::@1->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1373] display_frame_maskxy::return#14 = display_frame_maskxy::return#12
    // display_frame::@16
    // mask = display_frame_maskxy(x, y)
    // [1374] display_frame::mask#2 = display_frame_maskxy::return#14
    // mask |= 0b0011
    // [1375] display_frame::mask#3 = display_frame::mask#2 | 3 -- vbuaa=vbuaa_bor_vbuc1 
    ora #3
    // display_frame_char(mask)
    // [1376] display_frame_char::mask#1 = display_frame::mask#3
    // [1377] call display_frame_char
    // [1937] phi from display_frame::@16 to display_frame_char [phi:display_frame::@16->display_frame_char]
    // [1937] phi display_frame_char::mask#10 = display_frame_char::mask#1 [phi:display_frame::@16->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1378] display_frame_char::return#14 = display_frame_char::return#12
    // display_frame::@17
    // c = display_frame_char(mask)
    // [1379] display_frame::c#1 = display_frame_char::return#14
    // cputcxy(x, y, c)
    // [1380] cputcxy::x#1 = display_frame::x#24 -- vbuxx=vbuz1 
    ldx.z x_1
    // [1381] cputcxy::y#1 = display_frame::y#0 -- vbuyy=vbuz1 
    ldy.z y
    // [1382] cputcxy::c#1 = display_frame::c#1 -- vbuz1=vbuaa 
    sta.z cputcxy.c
    // [1383] call cputcxy
    // [1495] phi from display_frame::@17 to cputcxy [phi:display_frame::@17->cputcxy]
    // [1495] phi cputcxy::c#13 = cputcxy::c#1 [phi:display_frame::@17->cputcxy#0] -- register_copy 
    // [1495] phi cputcxy::y#13 = cputcxy::y#1 [phi:display_frame::@17->cputcxy#1] -- register_copy 
    // [1495] phi cputcxy::x#13 = cputcxy::x#1 [phi:display_frame::@17->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@18
    // if(h>=2)
    // [1384] if(display_frame::h#0<2) goto display_frame::@return -- vbuz1_lt_vbuc1_then_la1 
    lda.z h
    cmp #2
    bcc __breturn
    // display_frame::@3
    // y++;
    // [1385] display_frame::y#1 = ++ display_frame::y#0 -- vbuz1=_inc_vbuz2 
    lda.z y
    inc
    sta.z y_1
    // [1386] phi from display_frame::@27 display_frame::@3 to display_frame::@6 [phi:display_frame::@27/display_frame::@3->display_frame::@6]
    // [1386] phi display_frame::y#10 = display_frame::y#2 [phi:display_frame::@27/display_frame::@3->display_frame::@6#0] -- register_copy 
    // display_frame::@6
  __b6:
    // while(y < y1)
    // [1387] if(display_frame::y#10<display_frame::y1#16) goto display_frame::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z y_1
    cmp.z y1
    bcc __b7
    // display_frame::@8
    // display_frame_maskxy(x, y)
    // [1388] display_frame_maskxy::x#5 = display_frame::x#0 -- vbuxx=vbuz1 
    ldx.z x
    // [1389] display_frame_maskxy::y#5 = display_frame::y#10 -- vbuyy=vbuz1 
    tay
    // [1390] call display_frame_maskxy
    // [1911] phi from display_frame::@8 to display_frame_maskxy [phi:display_frame::@8->display_frame_maskxy]
    // [1911] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#5 [phi:display_frame::@8->display_frame_maskxy#0] -- register_copy 
    // [1911] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#5 [phi:display_frame::@8->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1391] display_frame_maskxy::return#18 = display_frame_maskxy::return#12
    // display_frame::@28
    // mask = display_frame_maskxy(x, y)
    // [1392] display_frame::mask#10 = display_frame_maskxy::return#18
    // mask |= 0b1100
    // [1393] display_frame::mask#11 = display_frame::mask#10 | $c -- vbuaa=vbuaa_bor_vbuc1 
    ora #$c
    // display_frame_char(mask)
    // [1394] display_frame_char::mask#5 = display_frame::mask#11
    // [1395] call display_frame_char
    // [1937] phi from display_frame::@28 to display_frame_char [phi:display_frame::@28->display_frame_char]
    // [1937] phi display_frame_char::mask#10 = display_frame_char::mask#5 [phi:display_frame::@28->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1396] display_frame_char::return#18 = display_frame_char::return#12
    // display_frame::@29
    // c = display_frame_char(mask)
    // [1397] display_frame::c#5 = display_frame_char::return#18
    // cputcxy(x, y, c)
    // [1398] cputcxy::x#5 = display_frame::x#0 -- vbuxx=vbuz1 
    ldx.z x
    // [1399] cputcxy::y#5 = display_frame::y#10 -- vbuyy=vbuz1 
    ldy.z y_1
    // [1400] cputcxy::c#5 = display_frame::c#5 -- vbuz1=vbuaa 
    sta.z cputcxy.c
    // [1401] call cputcxy
    // [1495] phi from display_frame::@29 to cputcxy [phi:display_frame::@29->cputcxy]
    // [1495] phi cputcxy::c#13 = cputcxy::c#5 [phi:display_frame::@29->cputcxy#0] -- register_copy 
    // [1495] phi cputcxy::y#13 = cputcxy::y#5 [phi:display_frame::@29->cputcxy#1] -- register_copy 
    // [1495] phi cputcxy::x#13 = cputcxy::x#5 [phi:display_frame::@29->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@30
    // if(w>=2)
    // [1402] if(display_frame::w#0<2) goto display_frame::@10 -- vbuz1_lt_vbuc1_then_la1 
    lda.z w
    cmp #2
    bcc __b10
    // display_frame::@9
    // x++;
    // [1403] display_frame::x#4 = ++ display_frame::x#0 -- vbuz1=_inc_vbuz1 
    inc.z x
    // [1404] phi from display_frame::@35 display_frame::@9 to display_frame::@11 [phi:display_frame::@35/display_frame::@9->display_frame::@11]
    // [1404] phi display_frame::x#18 = display_frame::x#5 [phi:display_frame::@35/display_frame::@9->display_frame::@11#0] -- register_copy 
    // display_frame::@11
  __b11:
    // while(x < x1)
    // [1405] if(display_frame::x#18<display_frame::x1#16) goto display_frame::@12 -- vbuz1_lt_vbuz2_then_la1 
    lda.z x
    cmp.z x1
    bcc __b12
    // [1406] phi from display_frame::@11 display_frame::@30 to display_frame::@10 [phi:display_frame::@11/display_frame::@30->display_frame::@10]
    // [1406] phi display_frame::x#15 = display_frame::x#18 [phi:display_frame::@11/display_frame::@30->display_frame::@10#0] -- register_copy 
    // display_frame::@10
  __b10:
    // display_frame_maskxy(x, y)
    // [1407] display_frame_maskxy::x#6 = display_frame::x#15 -- vbuxx=vbuz1 
    ldx.z x
    // [1408] display_frame_maskxy::y#6 = display_frame::y#10 -- vbuyy=vbuz1 
    ldy.z y_1
    // [1409] call display_frame_maskxy
    // [1911] phi from display_frame::@10 to display_frame_maskxy [phi:display_frame::@10->display_frame_maskxy]
    // [1911] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#6 [phi:display_frame::@10->display_frame_maskxy#0] -- register_copy 
    // [1911] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#6 [phi:display_frame::@10->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1410] display_frame_maskxy::return#19 = display_frame_maskxy::return#12
    // display_frame::@31
    // mask = display_frame_maskxy(x, y)
    // [1411] display_frame::mask#12 = display_frame_maskxy::return#19
    // mask |= 0b1001
    // [1412] display_frame::mask#13 = display_frame::mask#12 | 9 -- vbuaa=vbuaa_bor_vbuc1 
    ora #9
    // display_frame_char(mask)
    // [1413] display_frame_char::mask#6 = display_frame::mask#13
    // [1414] call display_frame_char
    // [1937] phi from display_frame::@31 to display_frame_char [phi:display_frame::@31->display_frame_char]
    // [1937] phi display_frame_char::mask#10 = display_frame_char::mask#6 [phi:display_frame::@31->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1415] display_frame_char::return#19 = display_frame_char::return#12
    // display_frame::@32
    // c = display_frame_char(mask)
    // [1416] display_frame::c#6 = display_frame_char::return#19
    // cputcxy(x, y, c)
    // [1417] cputcxy::x#6 = display_frame::x#15 -- vbuxx=vbuz1 
    ldx.z x
    // [1418] cputcxy::y#6 = display_frame::y#10 -- vbuyy=vbuz1 
    ldy.z y_1
    // [1419] cputcxy::c#6 = display_frame::c#6 -- vbuz1=vbuaa 
    sta.z cputcxy.c
    // [1420] call cputcxy
    // [1495] phi from display_frame::@32 to cputcxy [phi:display_frame::@32->cputcxy]
    // [1495] phi cputcxy::c#13 = cputcxy::c#6 [phi:display_frame::@32->cputcxy#0] -- register_copy 
    // [1495] phi cputcxy::y#13 = cputcxy::y#6 [phi:display_frame::@32->cputcxy#1] -- register_copy 
    // [1495] phi cputcxy::x#13 = cputcxy::x#6 [phi:display_frame::@32->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@return
  __breturn:
    // }
    // [1421] return 
    rts
    // display_frame::@12
  __b12:
    // display_frame_maskxy(x, y)
    // [1422] display_frame_maskxy::x#7 = display_frame::x#18 -- vbuxx=vbuz1 
    ldx.z x
    // [1423] display_frame_maskxy::y#7 = display_frame::y#10 -- vbuyy=vbuz1 
    ldy.z y_1
    // [1424] call display_frame_maskxy
    // [1911] phi from display_frame::@12 to display_frame_maskxy [phi:display_frame::@12->display_frame_maskxy]
    // [1911] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#7 [phi:display_frame::@12->display_frame_maskxy#0] -- register_copy 
    // [1911] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#7 [phi:display_frame::@12->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1425] display_frame_maskxy::return#20 = display_frame_maskxy::return#12
    // display_frame::@33
    // mask = display_frame_maskxy(x, y)
    // [1426] display_frame::mask#14 = display_frame_maskxy::return#20
    // mask |= 0b0101
    // [1427] display_frame::mask#15 = display_frame::mask#14 | 5 -- vbuaa=vbuaa_bor_vbuc1 
    ora #5
    // display_frame_char(mask)
    // [1428] display_frame_char::mask#7 = display_frame::mask#15
    // [1429] call display_frame_char
    // [1937] phi from display_frame::@33 to display_frame_char [phi:display_frame::@33->display_frame_char]
    // [1937] phi display_frame_char::mask#10 = display_frame_char::mask#7 [phi:display_frame::@33->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1430] display_frame_char::return#20 = display_frame_char::return#12
    // display_frame::@34
    // c = display_frame_char(mask)
    // [1431] display_frame::c#7 = display_frame_char::return#20
    // cputcxy(x, y, c)
    // [1432] cputcxy::x#7 = display_frame::x#18 -- vbuxx=vbuz1 
    ldx.z x
    // [1433] cputcxy::y#7 = display_frame::y#10 -- vbuyy=vbuz1 
    ldy.z y_1
    // [1434] cputcxy::c#7 = display_frame::c#7 -- vbuz1=vbuaa 
    sta.z cputcxy.c
    // [1435] call cputcxy
    // [1495] phi from display_frame::@34 to cputcxy [phi:display_frame::@34->cputcxy]
    // [1495] phi cputcxy::c#13 = cputcxy::c#7 [phi:display_frame::@34->cputcxy#0] -- register_copy 
    // [1495] phi cputcxy::y#13 = cputcxy::y#7 [phi:display_frame::@34->cputcxy#1] -- register_copy 
    // [1495] phi cputcxy::x#13 = cputcxy::x#7 [phi:display_frame::@34->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@35
    // x++;
    // [1436] display_frame::x#5 = ++ display_frame::x#18 -- vbuz1=_inc_vbuz1 
    inc.z x
    jmp __b11
    // display_frame::@7
  __b7:
    // display_frame_maskxy(x0, y)
    // [1437] display_frame_maskxy::x#3 = display_frame::x#0 -- vbuxx=vbuz1 
    ldx.z x
    // [1438] display_frame_maskxy::y#3 = display_frame::y#10 -- vbuyy=vbuz1 
    ldy.z y_1
    // [1439] call display_frame_maskxy
    // [1911] phi from display_frame::@7 to display_frame_maskxy [phi:display_frame::@7->display_frame_maskxy]
    // [1911] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#3 [phi:display_frame::@7->display_frame_maskxy#0] -- register_copy 
    // [1911] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#3 [phi:display_frame::@7->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x0, y)
    // [1440] display_frame_maskxy::return#16 = display_frame_maskxy::return#12
    // display_frame::@22
    // mask = display_frame_maskxy(x0, y)
    // [1441] display_frame::mask#6 = display_frame_maskxy::return#16
    // mask |= 0b1010
    // [1442] display_frame::mask#7 = display_frame::mask#6 | $a -- vbuaa=vbuaa_bor_vbuc1 
    ora #$a
    // display_frame_char(mask)
    // [1443] display_frame_char::mask#3 = display_frame::mask#7
    // [1444] call display_frame_char
    // [1937] phi from display_frame::@22 to display_frame_char [phi:display_frame::@22->display_frame_char]
    // [1937] phi display_frame_char::mask#10 = display_frame_char::mask#3 [phi:display_frame::@22->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1445] display_frame_char::return#16 = display_frame_char::return#12
    // display_frame::@23
    // c = display_frame_char(mask)
    // [1446] display_frame::c#3 = display_frame_char::return#16
    // cputcxy(x0, y, c)
    // [1447] cputcxy::x#3 = display_frame::x#0 -- vbuxx=vbuz1 
    ldx.z x
    // [1448] cputcxy::y#3 = display_frame::y#10 -- vbuyy=vbuz1 
    ldy.z y_1
    // [1449] cputcxy::c#3 = display_frame::c#3 -- vbuz1=vbuaa 
    sta.z cputcxy.c
    // [1450] call cputcxy
    // [1495] phi from display_frame::@23 to cputcxy [phi:display_frame::@23->cputcxy]
    // [1495] phi cputcxy::c#13 = cputcxy::c#3 [phi:display_frame::@23->cputcxy#0] -- register_copy 
    // [1495] phi cputcxy::y#13 = cputcxy::y#3 [phi:display_frame::@23->cputcxy#1] -- register_copy 
    // [1495] phi cputcxy::x#13 = cputcxy::x#3 [phi:display_frame::@23->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@24
    // display_frame_maskxy(x1, y)
    // [1451] display_frame_maskxy::x#4 = display_frame::x1#16 -- vbuxx=vbuz1 
    ldx.z x1
    // [1452] display_frame_maskxy::y#4 = display_frame::y#10 -- vbuyy=vbuz1 
    ldy.z y_1
    // [1453] call display_frame_maskxy
    // [1911] phi from display_frame::@24 to display_frame_maskxy [phi:display_frame::@24->display_frame_maskxy]
    // [1911] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#4 [phi:display_frame::@24->display_frame_maskxy#0] -- register_copy 
    // [1911] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#4 [phi:display_frame::@24->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x1, y)
    // [1454] display_frame_maskxy::return#17 = display_frame_maskxy::return#12
    // display_frame::@25
    // mask = display_frame_maskxy(x1, y)
    // [1455] display_frame::mask#8 = display_frame_maskxy::return#17
    // mask |= 0b1010
    // [1456] display_frame::mask#9 = display_frame::mask#8 | $a -- vbuaa=vbuaa_bor_vbuc1 
    ora #$a
    // display_frame_char(mask)
    // [1457] display_frame_char::mask#4 = display_frame::mask#9
    // [1458] call display_frame_char
    // [1937] phi from display_frame::@25 to display_frame_char [phi:display_frame::@25->display_frame_char]
    // [1937] phi display_frame_char::mask#10 = display_frame_char::mask#4 [phi:display_frame::@25->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1459] display_frame_char::return#17 = display_frame_char::return#12
    // display_frame::@26
    // c = display_frame_char(mask)
    // [1460] display_frame::c#4 = display_frame_char::return#17
    // cputcxy(x1, y, c)
    // [1461] cputcxy::x#4 = display_frame::x1#16 -- vbuxx=vbuz1 
    ldx.z x1
    // [1462] cputcxy::y#4 = display_frame::y#10 -- vbuyy=vbuz1 
    ldy.z y_1
    // [1463] cputcxy::c#4 = display_frame::c#4 -- vbuz1=vbuaa 
    sta.z cputcxy.c
    // [1464] call cputcxy
    // [1495] phi from display_frame::@26 to cputcxy [phi:display_frame::@26->cputcxy]
    // [1495] phi cputcxy::c#13 = cputcxy::c#4 [phi:display_frame::@26->cputcxy#0] -- register_copy 
    // [1495] phi cputcxy::y#13 = cputcxy::y#4 [phi:display_frame::@26->cputcxy#1] -- register_copy 
    // [1495] phi cputcxy::x#13 = cputcxy::x#4 [phi:display_frame::@26->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@27
    // y++;
    // [1465] display_frame::y#2 = ++ display_frame::y#10 -- vbuz1=_inc_vbuz1 
    inc.z y_1
    jmp __b6
    // display_frame::@5
  __b5:
    // display_frame_maskxy(x, y)
    // [1466] display_frame_maskxy::x#2 = display_frame::x#10 -- vbuxx=vbuz1 
    ldx.z x_1
    // [1467] display_frame_maskxy::y#2 = display_frame::y#0 -- vbuyy=vbuz1 
    ldy.z y
    // [1468] call display_frame_maskxy
    // [1911] phi from display_frame::@5 to display_frame_maskxy [phi:display_frame::@5->display_frame_maskxy]
    // [1911] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#2 [phi:display_frame::@5->display_frame_maskxy#0] -- register_copy 
    // [1911] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#2 [phi:display_frame::@5->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [1469] display_frame_maskxy::return#15 = display_frame_maskxy::return#12
    // display_frame::@19
    // mask = display_frame_maskxy(x, y)
    // [1470] display_frame::mask#4 = display_frame_maskxy::return#15
    // mask |= 0b0101
    // [1471] display_frame::mask#5 = display_frame::mask#4 | 5 -- vbuaa=vbuaa_bor_vbuc1 
    ora #5
    // display_frame_char(mask)
    // [1472] display_frame_char::mask#2 = display_frame::mask#5
    // [1473] call display_frame_char
    // [1937] phi from display_frame::@19 to display_frame_char [phi:display_frame::@19->display_frame_char]
    // [1937] phi display_frame_char::mask#10 = display_frame_char::mask#2 [phi:display_frame::@19->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [1474] display_frame_char::return#15 = display_frame_char::return#12
    // display_frame::@20
    // c = display_frame_char(mask)
    // [1475] display_frame::c#2 = display_frame_char::return#15
    // cputcxy(x, y, c)
    // [1476] cputcxy::x#2 = display_frame::x#10 -- vbuxx=vbuz1 
    ldx.z x_1
    // [1477] cputcxy::y#2 = display_frame::y#0 -- vbuyy=vbuz1 
    ldy.z y
    // [1478] cputcxy::c#2 = display_frame::c#2 -- vbuz1=vbuaa 
    sta.z cputcxy.c
    // [1479] call cputcxy
    // [1495] phi from display_frame::@20 to cputcxy [phi:display_frame::@20->cputcxy]
    // [1495] phi cputcxy::c#13 = cputcxy::c#2 [phi:display_frame::@20->cputcxy#0] -- register_copy 
    // [1495] phi cputcxy::y#13 = cputcxy::y#2 [phi:display_frame::@20->cputcxy#1] -- register_copy 
    // [1495] phi cputcxy::x#13 = cputcxy::x#2 [phi:display_frame::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@21
    // x++;
    // [1480] display_frame::x#2 = ++ display_frame::x#10 -- vbuz1=_inc_vbuz1 
    inc.z x_1
    jmp __b4
    // display_frame::@36
  __b36:
    // [1481] display_frame::x#30 = display_frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z x_1
    jmp __b1
}
  // cputs
// Output a NUL-terminated string at the current cursor position
// void cputs(__zp($61) const char *s)
cputs: {
    .label s = $61
    // [1483] phi from cputs cputs::@2 to cputs::@1 [phi:cputs/cputs::@2->cputs::@1]
    // [1483] phi cputs::s#2 = cputs::s#1 [phi:cputs/cputs::@2->cputs::@1#0] -- register_copy 
    // cputs::@1
  __b1:
    // while(c=*s++)
    // [1484] cputs::c#1 = *cputs::s#2 -- vbuaa=_deref_pbuz1 
    ldy #0
    lda (s),y
    // [1485] cputs::s#0 = ++ cputs::s#2 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [1486] if(0!=cputs::c#1) goto cputs::@2 -- 0_neq_vbuaa_then_la1 
    cmp #0
    bne __b2
    // cputs::@return
    // }
    // [1487] return 
    rts
    // cputs::@2
  __b2:
    // cputc(c)
    // [1488] stackpush(char) = cputs::c#1 -- _stackpushbyte_=vbuaa 
    pha
    // [1489] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
}
  // wherex
// Return the x position of the cursor
wherex: {
    // return __conio.cursor_x;
    // [1491] wherex::return#0 = *((char *)&__conio) -- vbuaa=_deref_pbuc1 
    lda __conio
    // wherex::@return
    // }
    // [1492] return 
    rts
}
  // wherey
// Return the y position of the cursor
wherey: {
    // return __conio.cursor_y;
    // [1493] wherey::return#0 = *((char *)&__conio+1) -- vbuaa=_deref_pbuc1 
    lda __conio+1
    // wherey::@return
    // }
    // [1494] return 
    rts
}
  // cputcxy
// Move cursor and output one character
// Same as "gotoxy (x, y); cputc (c);"
// void cputcxy(__register(X) char x, __register(Y) char y, __zp($45) char c)
cputcxy: {
    .label c = $45
    // gotoxy(x, y)
    // [1496] gotoxy::x#0 = cputcxy::x#13
    // [1497] gotoxy::y#0 = cputcxy::y#13
    // [1498] call gotoxy
    // [590] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [590] phi gotoxy::y#24 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [590] phi gotoxy::x#24 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [1499] stackpush(char) = cputcxy::c#13 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [1500] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [1502] return 
    rts
}
  // display_smc_led
/**
 * @brief Print SMC led above the SMC chip.
 * 
 * @param c Led color
 */
// void display_smc_led(__zp($48) char c)
display_smc_led: {
    .label c = $48
    // display_chip_led(CHIP_SMC_X+1, CHIP_SMC_Y, CHIP_SMC_W, c, BLUE)
    // [1504] display_chip_led::tc#0 = display_smc_led::c#2 -- vbuxx=vbuz1 
    ldx.z c
    // [1505] call display_chip_led
    // [1952] phi from display_smc_led to display_chip_led [phi:display_smc_led->display_chip_led]
    // [1952] phi display_chip_led::w#7 = 5 [phi:display_smc_led->display_chip_led#0] -- vbuz1=vbuc1 
    lda #5
    sta.z display_chip_led.w
    // [1952] phi display_chip_led::x#7 = 1+1 [phi:display_smc_led->display_chip_led#1] -- vbuz1=vbuc1 
    lda #1+1
    sta.z display_chip_led.x
    // [1952] phi display_chip_led::tc#3 = display_chip_led::tc#0 [phi:display_smc_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_smc_led::@1
    // display_info_led(INFO_X-2, INFO_Y, c, BLUE)
    // [1506] display_info_led::tc#0 = display_smc_led::c#2 -- vbuxx=vbuz1 
    ldx.z c
    // [1507] call display_info_led
    // [1266] phi from display_smc_led::@1 to display_info_led [phi:display_smc_led::@1->display_info_led]
    // [1266] phi display_info_led::y#4 = $11 [phi:display_smc_led::@1->display_info_led#0] -- vbuz1=vbuc1 
    lda #$11
    sta.z display_info_led.y
    // [1266] phi display_info_led::x#4 = 4-2 [phi:display_smc_led::@1->display_info_led#1] -- vbuyy=vbuc1 
    ldy #4-2
    // [1266] phi display_info_led::tc#4 = display_info_led::tc#0 [phi:display_smc_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_smc_led::@return
    // }
    // [1508] return 
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
// void display_print_chip(__zp($39) char x, char y, __zp($43) char w, __zp($29) char *text)
display_print_chip: {
    .label y = 3+2+1+1+1+1+1+1+1+1
    .label text = $29
    .label text_1 = $37
    .label x = $39
    .label text_2 = $53
    .label text_3 = $7d
    .label text_4 = $d1
    .label text_5 = $c7
    .label text_6 = $4c
    .label w = $43
    // display_chip_line(x, y++, w, *text++)
    // [1510] display_chip_line::x#0 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1511] display_chip_line::w#0 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1512] display_chip_line::c#0 = *display_print_chip::text#11 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_2),y
    sta.z display_chip_line.c
    // [1513] call display_chip_line
    // [1970] phi from display_print_chip to display_chip_line [phi:display_print_chip->display_chip_line]
    // [1970] phi display_chip_line::c#15 = display_chip_line::c#0 [phi:display_print_chip->display_chip_line#0] -- register_copy 
    // [1970] phi display_chip_line::w#10 = display_chip_line::w#0 [phi:display_print_chip->display_chip_line#1] -- register_copy 
    // [1970] phi display_chip_line::y#16 = 3+2 [phi:display_print_chip->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2
    sta.z display_chip_line.y
    // [1970] phi display_chip_line::x#16 = display_chip_line::x#0 [phi:display_print_chip->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@1
    // display_chip_line(x, y++, w, *text++);
    // [1514] display_print_chip::text#0 = ++ display_print_chip::text#11 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_2
    adc #1
    sta.z text
    lda.z text_2+1
    adc #0
    sta.z text+1
    // display_chip_line(x, y++, w, *text++)
    // [1515] display_chip_line::x#1 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1516] display_chip_line::w#1 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1517] display_chip_line::c#1 = *display_print_chip::text#0 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text),y
    sta.z display_chip_line.c
    // [1518] call display_chip_line
    // [1970] phi from display_print_chip::@1 to display_chip_line [phi:display_print_chip::@1->display_chip_line]
    // [1970] phi display_chip_line::c#15 = display_chip_line::c#1 [phi:display_print_chip::@1->display_chip_line#0] -- register_copy 
    // [1970] phi display_chip_line::w#10 = display_chip_line::w#1 [phi:display_print_chip::@1->display_chip_line#1] -- register_copy 
    // [1970] phi display_chip_line::y#16 = ++3+2 [phi:display_print_chip::@1->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1
    sta.z display_chip_line.y
    // [1970] phi display_chip_line::x#16 = display_chip_line::x#1 [phi:display_print_chip::@1->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@2
    // display_chip_line(x, y++, w, *text++);
    // [1519] display_print_chip::text#1 = ++ display_print_chip::text#0 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text
    adc #1
    sta.z text_1
    lda.z text+1
    adc #0
    sta.z text_1+1
    // display_chip_line(x, y++, w, *text++)
    // [1520] display_chip_line::x#2 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1521] display_chip_line::w#2 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1522] display_chip_line::c#2 = *display_print_chip::text#1 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_1),y
    sta.z display_chip_line.c
    // [1523] call display_chip_line
    // [1970] phi from display_print_chip::@2 to display_chip_line [phi:display_print_chip::@2->display_chip_line]
    // [1970] phi display_chip_line::c#15 = display_chip_line::c#2 [phi:display_print_chip::@2->display_chip_line#0] -- register_copy 
    // [1970] phi display_chip_line::w#10 = display_chip_line::w#2 [phi:display_print_chip::@2->display_chip_line#1] -- register_copy 
    // [1970] phi display_chip_line::y#16 = ++++3+2 [phi:display_print_chip::@2->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1
    sta.z display_chip_line.y
    // [1970] phi display_chip_line::x#16 = display_chip_line::x#2 [phi:display_print_chip::@2->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@3
    // display_chip_line(x, y++, w, *text++);
    // [1524] display_print_chip::text#15 = ++ display_print_chip::text#1 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_1
    adc #1
    sta.z text_3
    lda.z text_1+1
    adc #0
    sta.z text_3+1
    // display_chip_line(x, y++, w, *text++)
    // [1525] display_chip_line::x#3 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1526] display_chip_line::w#3 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1527] display_chip_line::c#3 = *display_print_chip::text#15 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_3),y
    sta.z display_chip_line.c
    // [1528] call display_chip_line
    // [1970] phi from display_print_chip::@3 to display_chip_line [phi:display_print_chip::@3->display_chip_line]
    // [1970] phi display_chip_line::c#15 = display_chip_line::c#3 [phi:display_print_chip::@3->display_chip_line#0] -- register_copy 
    // [1970] phi display_chip_line::w#10 = display_chip_line::w#3 [phi:display_print_chip::@3->display_chip_line#1] -- register_copy 
    // [1970] phi display_chip_line::y#16 = ++++++3+2 [phi:display_print_chip::@3->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1
    sta.z display_chip_line.y
    // [1970] phi display_chip_line::x#16 = display_chip_line::x#3 [phi:display_print_chip::@3->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@4
    // display_chip_line(x, y++, w, *text++);
    // [1529] display_print_chip::text#16 = ++ display_print_chip::text#15 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_3
    adc #1
    sta.z text_4
    lda.z text_3+1
    adc #0
    sta.z text_4+1
    // display_chip_line(x, y++, w, *text++)
    // [1530] display_chip_line::x#4 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1531] display_chip_line::w#4 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1532] display_chip_line::c#4 = *display_print_chip::text#16 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_4),y
    sta.z display_chip_line.c
    // [1533] call display_chip_line
    // [1970] phi from display_print_chip::@4 to display_chip_line [phi:display_print_chip::@4->display_chip_line]
    // [1970] phi display_chip_line::c#15 = display_chip_line::c#4 [phi:display_print_chip::@4->display_chip_line#0] -- register_copy 
    // [1970] phi display_chip_line::w#10 = display_chip_line::w#4 [phi:display_print_chip::@4->display_chip_line#1] -- register_copy 
    // [1970] phi display_chip_line::y#16 = ++++++++3+2 [phi:display_print_chip::@4->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1
    sta.z display_chip_line.y
    // [1970] phi display_chip_line::x#16 = display_chip_line::x#4 [phi:display_print_chip::@4->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@5
    // display_chip_line(x, y++, w, *text++);
    // [1534] display_print_chip::text#17 = ++ display_print_chip::text#16 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_4
    adc #1
    sta.z text_5
    lda.z text_4+1
    adc #0
    sta.z text_5+1
    // display_chip_line(x, y++, w, *text++)
    // [1535] display_chip_line::x#5 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1536] display_chip_line::w#5 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1537] display_chip_line::c#5 = *display_print_chip::text#17 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_5),y
    sta.z display_chip_line.c
    // [1538] call display_chip_line
    // [1970] phi from display_print_chip::@5 to display_chip_line [phi:display_print_chip::@5->display_chip_line]
    // [1970] phi display_chip_line::c#15 = display_chip_line::c#5 [phi:display_print_chip::@5->display_chip_line#0] -- register_copy 
    // [1970] phi display_chip_line::w#10 = display_chip_line::w#5 [phi:display_print_chip::@5->display_chip_line#1] -- register_copy 
    // [1970] phi display_chip_line::y#16 = ++++++++++3+2 [phi:display_print_chip::@5->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1+1
    sta.z display_chip_line.y
    // [1970] phi display_chip_line::x#16 = display_chip_line::x#5 [phi:display_print_chip::@5->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@6
    // display_chip_line(x, y++, w, *text++);
    // [1539] display_print_chip::text#18 = ++ display_print_chip::text#17 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_5
    adc #1
    sta.z text_6
    lda.z text_5+1
    adc #0
    sta.z text_6+1
    // display_chip_line(x, y++, w, *text++)
    // [1540] display_chip_line::x#6 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1541] display_chip_line::w#6 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1542] display_chip_line::c#6 = *display_print_chip::text#18 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta.z display_chip_line.c
    // [1543] call display_chip_line
    // [1970] phi from display_print_chip::@6 to display_chip_line [phi:display_print_chip::@6->display_chip_line]
    // [1970] phi display_chip_line::c#15 = display_chip_line::c#6 [phi:display_print_chip::@6->display_chip_line#0] -- register_copy 
    // [1970] phi display_chip_line::w#10 = display_chip_line::w#6 [phi:display_print_chip::@6->display_chip_line#1] -- register_copy 
    // [1970] phi display_chip_line::y#16 = ++++++++++++3+2 [phi:display_print_chip::@6->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1+1+1
    sta.z display_chip_line.y
    // [1970] phi display_chip_line::x#16 = display_chip_line::x#6 [phi:display_print_chip::@6->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@7
    // display_chip_line(x, y++, w, *text++);
    // [1544] display_print_chip::text#19 = ++ display_print_chip::text#18 -- pbuz1=_inc_pbuz1 
    inc.z text_6
    bne !+
    inc.z text_6+1
  !:
    // display_chip_line(x, y++, w, *text++)
    // [1545] display_chip_line::x#7 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1546] display_chip_line::w#7 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_line.w
    // [1547] display_chip_line::c#7 = *display_print_chip::text#19 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta.z display_chip_line.c
    // [1548] call display_chip_line
    // [1970] phi from display_print_chip::@7 to display_chip_line [phi:display_print_chip::@7->display_chip_line]
    // [1970] phi display_chip_line::c#15 = display_chip_line::c#7 [phi:display_print_chip::@7->display_chip_line#0] -- register_copy 
    // [1970] phi display_chip_line::w#10 = display_chip_line::w#7 [phi:display_print_chip::@7->display_chip_line#1] -- register_copy 
    // [1970] phi display_chip_line::y#16 = ++++++++++++++3+2 [phi:display_print_chip::@7->display_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1+1+1+1
    sta.z display_chip_line.y
    // [1970] phi display_chip_line::x#16 = display_chip_line::x#7 [phi:display_print_chip::@7->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@8
    // display_chip_end(x, y++, w)
    // [1549] display_chip_end::x#0 = display_print_chip::x#10 -- vbuxx=vbuz1 
    ldx.z x
    // [1550] display_chip_end::w#0 = display_print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z display_chip_end.w
    // [1551] call display_chip_end
    jsr display_chip_end
    // display_print_chip::@return
    // }
    // [1552] return 
    rts
}
  // display_vera_led
/**
 * @brief Print VERA led above the VERA chip.
 * 
 * @param c Led color
 */
// void display_vera_led(__zp($4b) char c)
display_vera_led: {
    .label c = $4b
    // display_chip_led(CHIP_VERA_X+1, CHIP_VERA_Y, CHIP_VERA_W, c, BLUE)
    // [1554] display_chip_led::tc#1 = display_vera_led::c#2 -- vbuxx=vbuz1 
    ldx.z c
    // [1555] call display_chip_led
    // [1952] phi from display_vera_led to display_chip_led [phi:display_vera_led->display_chip_led]
    // [1952] phi display_chip_led::w#7 = 8 [phi:display_vera_led->display_chip_led#0] -- vbuz1=vbuc1 
    lda #8
    sta.z display_chip_led.w
    // [1952] phi display_chip_led::x#7 = 9+1 [phi:display_vera_led->display_chip_led#1] -- vbuz1=vbuc1 
    lda #9+1
    sta.z display_chip_led.x
    // [1952] phi display_chip_led::tc#3 = display_chip_led::tc#1 [phi:display_vera_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_vera_led::@1
    // display_info_led(INFO_X-2, INFO_Y+1, c, BLUE)
    // [1556] display_info_led::tc#1 = display_vera_led::c#2 -- vbuxx=vbuz1 
    ldx.z c
    // [1557] call display_info_led
    // [1266] phi from display_vera_led::@1 to display_info_led [phi:display_vera_led::@1->display_info_led]
    // [1266] phi display_info_led::y#4 = $11+1 [phi:display_vera_led::@1->display_info_led#0] -- vbuz1=vbuc1 
    lda #$11+1
    sta.z display_info_led.y
    // [1266] phi display_info_led::x#4 = 4-2 [phi:display_vera_led::@1->display_info_led#1] -- vbuyy=vbuc1 
    ldy #4-2
    // [1266] phi display_info_led::tc#4 = display_info_led::tc#1 [phi:display_vera_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_vera_led::@return
    // }
    // [1558] return 
    rts
}
  // strcat
// Concatenates the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcat(char *destination, __zp($53) char *source)
strcat: {
    .label strcat__0 = $3a
    .label dst = $3a
    .label src = $53
    .label source = $53
    // strlen(destination)
    // [1560] call strlen
    // [1810] phi from strcat to strlen [phi:strcat->strlen]
    // [1810] phi strlen::str#8 = display_chip_rom::rom [phi:strcat->strlen#0] -- pbuz1=pbuc1 
    lda #<display_chip_rom.rom
    sta.z strlen.str
    lda #>display_chip_rom.rom
    sta.z strlen.str+1
    jsr strlen
    // strlen(destination)
    // [1561] strlen::return#0 = strlen::len#2
    // strcat::@4
    // [1562] strcat::$0 = strlen::return#0
    // char* dst = destination + strlen(destination)
    // [1563] strcat::dst#0 = display_chip_rom::rom + strcat::$0 -- pbuz1=pbuc1_plus_vwuz1 
    lda.z dst
    clc
    adc #<display_chip_rom.rom
    sta.z dst
    lda.z dst+1
    adc #>display_chip_rom.rom
    sta.z dst+1
    // [1564] phi from strcat::@2 strcat::@4 to strcat::@1 [phi:strcat::@2/strcat::@4->strcat::@1]
    // [1564] phi strcat::dst#2 = strcat::dst#1 [phi:strcat::@2/strcat::@4->strcat::@1#0] -- register_copy 
    // [1564] phi strcat::src#2 = strcat::src#1 [phi:strcat::@2/strcat::@4->strcat::@1#1] -- register_copy 
    // strcat::@1
  __b1:
    // while(*src)
    // [1565] if(0!=*strcat::src#2) goto strcat::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcat::@3
    // *dst = 0
    // [1566] *strcat::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcat::@return
    // }
    // [1567] return 
    rts
    // strcat::@2
  __b2:
    // *dst++ = *src++
    // [1568] *strcat::dst#2 = *strcat::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [1569] strcat::dst#1 = ++ strcat::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [1570] strcat::src#1 = ++ strcat::src#2 -- pbuz1=_inc_pbuz1 
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
// void display_rom_led(__zp($6f) char chip, __zp($6d) char c)
display_rom_led: {
    .label chip = $6f
    .label c = $6d
    // chip*6
    // [1572] display_rom_led::$7 = display_rom_led::chip#2 << 1 -- vbuaa=vbuz1_rol_1 
    lda.z chip
    asl
    // [1573] display_rom_led::$8 = display_rom_led::$7 + display_rom_led::chip#2 -- vbuaa=vbuaa_plus_vbuz1 
    clc
    adc.z chip
    // CHIP_ROM_X+chip*6
    // [1574] display_rom_led::$0 = display_rom_led::$8 << 1 -- vbuaa=vbuaa_rol_1 
    asl
    // display_chip_led(CHIP_ROM_X+chip*6+1, CHIP_ROM_Y, CHIP_ROM_W, c, BLUE)
    // [1575] display_chip_led::x#3 = display_rom_led::$0 + $14+1 -- vbuz1=vbuaa_plus_vbuc1 
    clc
    adc #$14+1
    sta.z display_chip_led.x
    // [1576] display_chip_led::tc#2 = display_rom_led::c#2 -- vbuxx=vbuz1 
    ldx.z c
    // [1577] call display_chip_led
    // [1952] phi from display_rom_led to display_chip_led [phi:display_rom_led->display_chip_led]
    // [1952] phi display_chip_led::w#7 = 3 [phi:display_rom_led->display_chip_led#0] -- vbuz1=vbuc1 
    lda #3
    sta.z display_chip_led.w
    // [1952] phi display_chip_led::x#7 = display_chip_led::x#3 [phi:display_rom_led->display_chip_led#1] -- register_copy 
    // [1952] phi display_chip_led::tc#3 = display_chip_led::tc#2 [phi:display_rom_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_rom_led::@1
    // display_info_led(INFO_X-2, INFO_Y+chip+2, c, BLUE)
    // [1578] display_info_led::y#2 = display_rom_led::chip#2 + $11+2 -- vbuz1=vbuz2_plus_vbuc1 
    lda #$11+2
    clc
    adc.z chip
    sta.z display_info_led.y
    // [1579] display_info_led::tc#2 = display_rom_led::c#2 -- vbuxx=vbuz1 
    ldx.z c
    // [1580] call display_info_led
    // [1266] phi from display_rom_led::@1 to display_info_led [phi:display_rom_led::@1->display_info_led]
    // [1266] phi display_info_led::y#4 = display_info_led::y#2 [phi:display_rom_led::@1->display_info_led#0] -- register_copy 
    // [1266] phi display_info_led::x#4 = 4-2 [phi:display_rom_led::@1->display_info_led#1] -- vbuyy=vbuc1 
    ldy #4-2
    // [1266] phi display_info_led::tc#4 = display_info_led::tc#2 [phi:display_rom_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_rom_led::@return
    // }
    // [1581] return 
    rts
}
  // display_progress_line
/**
 * @brief Print one line of text in the progress frame at a line position.
 * 
 * @param line The start line, counting from 0.
 * @param text The text to be displayed.
 */
// void display_progress_line(__register(X) char line, __zp($3a) char *text)
display_progress_line: {
    .label text = $3a
    // cputsxy(PROGRESS_X, PROGRESS_Y+line, text)
    // [1582] cputsxy::y#0 = PROGRESS_Y + display_progress_line::line#0 -- vbuyy=vbuc1_plus_vbuxx 
    txa
    clc
    adc #PROGRESS_Y
    tay
    // [1583] cputsxy::s#0 = display_progress_line::text#0
    // [1584] call cputsxy
    // [677] phi from display_progress_line to cputsxy [phi:display_progress_line->cputsxy]
    // [677] phi cputsxy::s#3 = cputsxy::s#0 [phi:display_progress_line->cputsxy#0] -- register_copy 
    // [677] phi cputsxy::y#3 = cputsxy::y#0 [phi:display_progress_line->cputsxy#1] -- register_copy 
    // [677] phi cputsxy::x#3 = PROGRESS_X [phi:display_progress_line->cputsxy#2] -- vbuxx=vbuc1 
    ldx #PROGRESS_X
    jsr cputsxy
    // display_progress_line::@return
    // }
    // [1585] return 
    rts
}
  // utoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void utoa(__zp($23) unsigned int value, __zp($3e) char *buffer, __register(X) char radix)
utoa: {
    .label digit_value = $29
    .label buffer = $3e
    .label digit = $44
    .label value = $23
    .label max_digits = $5a
    .label digit_values = $3a
    // if(radix==DECIMAL)
    // [1586] if(utoa::radix#0==DECIMAL) goto utoa::@1 -- vbuxx_eq_vbuc1_then_la1 
    cpx #DECIMAL
    beq __b2
    // utoa::@2
    // if(radix==HEXADECIMAL)
    // [1587] if(utoa::radix#0==HEXADECIMAL) goto utoa::@1 -- vbuxx_eq_vbuc1_then_la1 
    cpx #HEXADECIMAL
    beq __b3
    // utoa::@3
    // if(radix==OCTAL)
    // [1588] if(utoa::radix#0==OCTAL) goto utoa::@1 -- vbuxx_eq_vbuc1_then_la1 
    cpx #OCTAL
    beq __b4
    // utoa::@4
    // if(radix==BINARY)
    // [1589] if(utoa::radix#0==BINARY) goto utoa::@1 -- vbuxx_eq_vbuc1_then_la1 
    cpx #BINARY
    beq __b5
    // utoa::@5
    // *buffer++ = 'e'
    // [1590] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1591] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1592] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1593] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // utoa::@return
    // }
    // [1594] return 
    rts
    // [1595] phi from utoa to utoa::@1 [phi:utoa->utoa::@1]
  __b2:
    // [1595] phi utoa::digit_values#8 = RADIX_DECIMAL_VALUES [phi:utoa->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_DECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES
    sta.z digit_values+1
    // [1595] phi utoa::max_digits#7 = 5 [phi:utoa->utoa::@1#1] -- vbuz1=vbuc1 
    lda #5
    sta.z max_digits
    jmp __b1
    // [1595] phi from utoa::@2 to utoa::@1 [phi:utoa::@2->utoa::@1]
  __b3:
    // [1595] phi utoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES [phi:utoa::@2->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_HEXADECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES
    sta.z digit_values+1
    // [1595] phi utoa::max_digits#7 = 4 [phi:utoa::@2->utoa::@1#1] -- vbuz1=vbuc1 
    lda #4
    sta.z max_digits
    jmp __b1
    // [1595] phi from utoa::@3 to utoa::@1 [phi:utoa::@3->utoa::@1]
  __b4:
    // [1595] phi utoa::digit_values#8 = RADIX_OCTAL_VALUES [phi:utoa::@3->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_OCTAL_VALUES
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES
    sta.z digit_values+1
    // [1595] phi utoa::max_digits#7 = 6 [phi:utoa::@3->utoa::@1#1] -- vbuz1=vbuc1 
    lda #6
    sta.z max_digits
    jmp __b1
    // [1595] phi from utoa::@4 to utoa::@1 [phi:utoa::@4->utoa::@1]
  __b5:
    // [1595] phi utoa::digit_values#8 = RADIX_BINARY_VALUES [phi:utoa::@4->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_BINARY_VALUES
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES
    sta.z digit_values+1
    // [1595] phi utoa::max_digits#7 = $10 [phi:utoa::@4->utoa::@1#1] -- vbuz1=vbuc1 
    lda #$10
    sta.z max_digits
    // utoa::@1
  __b1:
    // [1596] phi from utoa::@1 to utoa::@6 [phi:utoa::@1->utoa::@6]
    // [1596] phi utoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:utoa::@1->utoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1596] phi utoa::started#2 = 0 [phi:utoa::@1->utoa::@6#1] -- vbuxx=vbuc1 
    ldx #0
    // [1596] phi utoa::value#2 = utoa::value#1 [phi:utoa::@1->utoa::@6#2] -- register_copy 
    // [1596] phi utoa::digit#2 = 0 [phi:utoa::@1->utoa::@6#3] -- vbuz1=vbuc1 
    txa
    sta.z digit
    // utoa::@6
  __b6:
    // max_digits-1
    // [1597] utoa::$4 = utoa::max_digits#7 - 1 -- vbuaa=vbuz1_minus_1 
    lda.z max_digits
    sec
    sbc #1
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1598] if(utoa::digit#2<utoa::$4) goto utoa::@7 -- vbuz1_lt_vbuaa_then_la1 
    cmp.z digit
    beq !+
    bcs __b7
  !:
    // utoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1599] utoa::$11 = (char)utoa::value#2 -- vbuxx=_byte_vwuz1 
    ldx.z value
    // [1600] *utoa::buffer#11 = DIGITS[utoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuxx 
    lda DIGITS,x
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1601] utoa::buffer#3 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1602] *utoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // utoa::@7
  __b7:
    // unsigned int digit_value = digit_values[digit]
    // [1603] utoa::$10 = utoa::digit#2 << 1 -- vbuaa=vbuz1_rol_1 
    lda.z digit
    asl
    // [1604] utoa::digit_value#0 = utoa::digit_values#8[utoa::$10] -- vwuz1=pwuz2_derefidx_vbuaa 
    tay
    lda (digit_values),y
    sta.z digit_value
    iny
    lda (digit_values),y
    sta.z digit_value+1
    // if (started || value >= digit_value)
    // [1605] if(0!=utoa::started#2) goto utoa::@10 -- 0_neq_vbuxx_then_la1 
    cpx #0
    bne __b10
    // utoa::@12
    // [1606] if(utoa::value#2>=utoa::digit_value#0) goto utoa::@10 -- vwuz1_ge_vwuz2_then_la1 
    cmp.z value+1
    bne !+
    lda.z digit_value
    cmp.z value
    beq __b10
  !:
    bcc __b10
    // [1607] phi from utoa::@12 to utoa::@9 [phi:utoa::@12->utoa::@9]
    // [1607] phi utoa::buffer#14 = utoa::buffer#11 [phi:utoa::@12->utoa::@9#0] -- register_copy 
    // [1607] phi utoa::started#4 = utoa::started#2 [phi:utoa::@12->utoa::@9#1] -- register_copy 
    // [1607] phi utoa::value#6 = utoa::value#2 [phi:utoa::@12->utoa::@9#2] -- register_copy 
    // utoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1608] utoa::digit#1 = ++ utoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1596] phi from utoa::@9 to utoa::@6 [phi:utoa::@9->utoa::@6]
    // [1596] phi utoa::buffer#11 = utoa::buffer#14 [phi:utoa::@9->utoa::@6#0] -- register_copy 
    // [1596] phi utoa::started#2 = utoa::started#4 [phi:utoa::@9->utoa::@6#1] -- register_copy 
    // [1596] phi utoa::value#2 = utoa::value#6 [phi:utoa::@9->utoa::@6#2] -- register_copy 
    // [1596] phi utoa::digit#2 = utoa::digit#1 [phi:utoa::@9->utoa::@6#3] -- register_copy 
    jmp __b6
    // utoa::@10
  __b10:
    // utoa_append(buffer++, value, digit_value)
    // [1609] utoa_append::buffer#0 = utoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z utoa_append.buffer
    lda.z buffer+1
    sta.z utoa_append.buffer+1
    // [1610] utoa_append::value#0 = utoa::value#2
    // [1611] utoa_append::sub#0 = utoa::digit_value#0
    // [1612] call utoa_append
    // [2031] phi from utoa::@10 to utoa_append [phi:utoa::@10->utoa_append]
    jsr utoa_append
    // utoa_append(buffer++, value, digit_value)
    // [1613] utoa_append::return#0 = utoa_append::value#2
    // utoa::@11
    // value = utoa_append(buffer++, value, digit_value)
    // [1614] utoa::value#0 = utoa_append::return#0
    // value = utoa_append(buffer++, value, digit_value);
    // [1615] utoa::buffer#4 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1607] phi from utoa::@11 to utoa::@9 [phi:utoa::@11->utoa::@9]
    // [1607] phi utoa::buffer#14 = utoa::buffer#4 [phi:utoa::@11->utoa::@9#0] -- register_copy 
    // [1607] phi utoa::started#4 = 1 [phi:utoa::@11->utoa::@9#1] -- vbuxx=vbuc1 
    ldx #1
    // [1607] phi utoa::value#6 = utoa::value#0 [phi:utoa::@11->utoa::@9#2] -- register_copy 
    jmp __b9
}
  // printf_number_buffer
// Print the contents of the number buffer using a specific format.
// This handles minimum length, zero-filling, and left/right justification from the format
// void printf_number_buffer(__zp($4f) void (*putc)(char), __zp($66) char buffer_sign, char *buffer_digits, __register(X) char format_min_length, char format_justify_left, char format_sign_always, __zp($65) char format_zero_padding, char format_upper_case, char format_radix)
printf_number_buffer: {
    .label printf_number_buffer__19 = $3a
    .label buffer_sign = $66
    .label format_zero_padding = $65
    .label putc = $4f
    .label padding = $64
    // if(format.min_length)
    // [1617] if(0==printf_number_buffer::format_min_length#3) goto printf_number_buffer::@1 -- 0_eq_vbuxx_then_la1 
    cpx #0
    beq __b5
    // [1618] phi from printf_number_buffer to printf_number_buffer::@5 [phi:printf_number_buffer->printf_number_buffer::@5]
    // printf_number_buffer::@5
    // strlen(buffer.digits)
    // [1619] call strlen
    // [1810] phi from printf_number_buffer::@5 to strlen [phi:printf_number_buffer::@5->strlen]
    // [1810] phi strlen::str#8 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@5->strlen#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str+1
    jsr strlen
    // strlen(buffer.digits)
    // [1620] strlen::return#3 = strlen::len#2
    // printf_number_buffer::@11
    // [1621] printf_number_buffer::$19 = strlen::return#3
    // signed char len = (signed char)strlen(buffer.digits)
    // [1622] printf_number_buffer::len#0 = (signed char)printf_number_buffer::$19 -- vbsyy=_sbyte_vwuz1 
    // There is a minimum length - work out the padding
    ldy.z printf_number_buffer__19
    // if(buffer.sign)
    // [1623] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@10 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b10
    // printf_number_buffer::@6
    // len++;
    // [1624] printf_number_buffer::len#1 = ++ printf_number_buffer::len#0 -- vbsyy=_inc_vbsyy 
    iny
    // [1625] phi from printf_number_buffer::@11 printf_number_buffer::@6 to printf_number_buffer::@10 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10]
    // [1625] phi printf_number_buffer::len#2 = printf_number_buffer::len#0 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10#0] -- register_copy 
    // printf_number_buffer::@10
  __b10:
    // padding = (signed char)format.min_length - len
    // [1626] printf_number_buffer::padding#1 = (signed char)printf_number_buffer::format_min_length#3 - printf_number_buffer::len#2 -- vbsz1=vbsxx_minus_vbsyy 
    txa
    sty.z $ff
    sec
    sbc.z $ff
    sta.z padding
    // if(padding<0)
    // [1627] if(printf_number_buffer::padding#1>=0) goto printf_number_buffer::@15 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1629] phi from printf_number_buffer printf_number_buffer::@10 to printf_number_buffer::@1 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1]
  __b5:
    // [1629] phi printf_number_buffer::padding#10 = 0 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [1628] phi from printf_number_buffer::@10 to printf_number_buffer::@15 [phi:printf_number_buffer::@10->printf_number_buffer::@15]
    // printf_number_buffer::@15
    // [1629] phi from printf_number_buffer::@15 to printf_number_buffer::@1 [phi:printf_number_buffer::@15->printf_number_buffer::@1]
    // [1629] phi printf_number_buffer::padding#10 = printf_number_buffer::padding#1 [phi:printf_number_buffer::@15->printf_number_buffer::@1#0] -- register_copy 
    // printf_number_buffer::@1
  __b1:
    // printf_number_buffer::@13
    // if(!format.justify_left && !format.zero_padding && padding)
    // [1630] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_zero_padding
    bne __b2
    // printf_number_buffer::@12
    // [1631] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@7 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b7
    jmp __b2
    // printf_number_buffer::@7
  __b7:
    // printf_padding(putc, ' ',(char)padding)
    // [1632] printf_padding::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1633] printf_padding::length#0 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1634] call printf_padding
    // [1816] phi from printf_number_buffer::@7 to printf_padding [phi:printf_number_buffer::@7->printf_padding]
    // [1816] phi printf_padding::putc#7 = printf_padding::putc#0 [phi:printf_number_buffer::@7->printf_padding#0] -- register_copy 
    // [1816] phi printf_padding::pad#7 = ' ' [phi:printf_number_buffer::@7->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1816] phi printf_padding::length#6 = printf_padding::length#0 [phi:printf_number_buffer::@7->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@2
  __b2:
    // if(buffer.sign)
    // [1635] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@3 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b3
    // printf_number_buffer::@8
    // putc(buffer.sign)
    // [1636] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbuz1 
    pha
    // [1637] callexecute *printf_number_buffer::putc#10  -- call__deref_pprz1 
    jsr icall19
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@3
  __b3:
    // if(format.zero_padding && padding)
    // [1639] if(0==printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@4 -- 0_eq_vbuz1_then_la1 
    lda.z format_zero_padding
    beq __b4
    // printf_number_buffer::@14
    // [1640] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@9 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b9
    jmp __b4
    // printf_number_buffer::@9
  __b9:
    // printf_padding(putc, '0',(char)padding)
    // [1641] printf_padding::putc#1 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1642] printf_padding::length#1 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1643] call printf_padding
    // [1816] phi from printf_number_buffer::@9 to printf_padding [phi:printf_number_buffer::@9->printf_padding]
    // [1816] phi printf_padding::putc#7 = printf_padding::putc#1 [phi:printf_number_buffer::@9->printf_padding#0] -- register_copy 
    // [1816] phi printf_padding::pad#7 = '0' [phi:printf_number_buffer::@9->printf_padding#1] -- vbuz1=vbuc1 
    lda #'0'
    sta.z printf_padding.pad
    // [1816] phi printf_padding::length#6 = printf_padding::length#1 [phi:printf_number_buffer::@9->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@4
  __b4:
    // printf_str(putc, buffer.digits)
    // [1644] printf_str::putc#0 = printf_number_buffer::putc#10
    // [1645] call printf_str
    // [850] phi from printf_number_buffer::@4 to printf_str [phi:printf_number_buffer::@4->printf_str]
    // [850] phi printf_str::putc#48 = printf_str::putc#0 [phi:printf_number_buffer::@4->printf_str#0] -- register_copy 
    // [850] phi printf_str::s#48 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@return
    // }
    // [1646] return 
    rts
    // Outside Flow
  icall19:
    jmp (putc)
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
// __zp($29) struct $2 * fopen(__zp($5b) const char *path, const char *mode)
fopen: {
    .label fopen__11 = $d1
    .label fopen__16 = $c7
    .label fopen__26 = $4f
    .label fopen__28 = $7d
    .label fopen__30 = $29
    .label cbm_k_setnam1_filename = $ea
    .label cbm_k_setnam1_filename_len = $e0
    .label cbm_k_setnam1_fopen__0 = $3a
    .label cbm_k_readst1_status = $e1
    .label cbm_k_close1_channel = $e2
    .label sp = $cc
    .label stream = $29
    .label pathtoken = $5b
    .label pathpos = $ef
    .label pathpos_1 = $77
    .label pathtoken_1 = $3e
    .label pathcmp = $b3
    .label path = $5b
    // Parse path
    .label pathstep = $79
    .label return = $29
    // unsigned char sp = __stdio_filecount
    // [1648] fopen::sp#0 = __stdio_filecount -- vbuz1=vbum2 
    lda __stdio_filecount
    sta.z sp
    // (unsigned int)sp | 0x8000
    // [1649] fopen::$30 = (unsigned int)fopen::sp#0 -- vwuz1=_word_vbuz2 
    sta.z fopen__30
    lda #0
    sta.z fopen__30+1
    // [1650] fopen::stream#0 = fopen::$30 | $8000 -- vwuz1=vwuz1_bor_vwuc1 
    lda.z stream
    ora #<$8000
    sta.z stream
    lda.z stream+1
    ora #>$8000
    sta.z stream+1
    // char pathpos = sp * __STDIO_FILECOUNT
    // [1651] fopen::pathpos#0 = fopen::sp#0 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z sp
    asl
    sta.z pathpos
    // __logical = 0
    // [1652] ((char *)&__stdio_file+$40)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    ldy.z sp
    sta __stdio_file+$40,y
    // __device = 0
    // [1653] ((char *)&__stdio_file+$42)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [1654] ((char *)&__stdio_file+$44)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$44,y
    // [1655] fopen::pathtoken#22 = fopen::pathtoken#0 -- pbuz1=pbuz2 
    lda.z pathtoken
    sta.z pathtoken_1
    lda.z pathtoken+1
    sta.z pathtoken_1+1
    // [1656] fopen::pathpos#21 = fopen::pathpos#0 -- vbuz1=vbuz2 
    lda.z pathpos
    sta.z pathpos_1
    // [1657] phi from fopen to fopen::@8 [phi:fopen->fopen::@8]
    // [1657] phi fopen::num#10 = 0 [phi:fopen->fopen::@8#0] -- vbuxx=vbuc1 
    ldx #0
    // [1657] phi fopen::pathpos#10 = fopen::pathpos#21 [phi:fopen->fopen::@8#1] -- register_copy 
    // [1657] phi fopen::path#10 = fopen::pathtoken#0 [phi:fopen->fopen::@8#2] -- register_copy 
    // [1657] phi fopen::pathstep#10 = 0 [phi:fopen->fopen::@8#3] -- vbuz1=vbuc1 
    txa
    sta.z pathstep
    // [1657] phi fopen::pathtoken#10 = fopen::pathtoken#22 [phi:fopen->fopen::@8#4] -- register_copy 
  // Iterate while path is not \0.
    // [1657] phi from fopen::@22 to fopen::@8 [phi:fopen::@22->fopen::@8]
    // [1657] phi fopen::num#10 = fopen::num#13 [phi:fopen::@22->fopen::@8#0] -- register_copy 
    // [1657] phi fopen::pathpos#10 = fopen::pathpos#7 [phi:fopen::@22->fopen::@8#1] -- register_copy 
    // [1657] phi fopen::path#10 = fopen::path#11 [phi:fopen::@22->fopen::@8#2] -- register_copy 
    // [1657] phi fopen::pathstep#10 = fopen::pathstep#11 [phi:fopen::@22->fopen::@8#3] -- register_copy 
    // [1657] phi fopen::pathtoken#10 = fopen::pathtoken#1 [phi:fopen::@22->fopen::@8#4] -- register_copy 
    // fopen::@8
  __b8:
    // if (*pathtoken == ',' || *pathtoken == '\0')
    // [1658] if(*fopen::pathtoken#10==',') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #','
    ldy #0
    cmp (pathtoken_1),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@33
    // [1659] if(*fopen::pathtoken#10=='@') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #'@'
    cmp (pathtoken_1),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@23
    // if (pathstep == 0)
    // [1660] if(fopen::pathstep#10!=0) goto fopen::@10 -- vbuz1_neq_0_then_la1 
    lda.z pathstep
    bne __b10
    // fopen::@24
    // __stdio_file.filename[pathpos] = *pathtoken
    // [1661] ((char *)&__stdio_file)[fopen::pathpos#10] = *fopen::pathtoken#10 -- pbuc1_derefidx_vbuz1=_deref_pbuz2 
    lda (pathtoken_1),y
    ldy.z pathpos_1
    sta __stdio_file,y
    // pathpos++;
    // [1662] fopen::pathpos#1 = ++ fopen::pathpos#10 -- vbuz1=_inc_vbuz1 
    inc.z pathpos_1
    // [1663] phi from fopen::@12 fopen::@23 fopen::@24 to fopen::@10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10]
    // [1663] phi fopen::num#13 = fopen::num#15 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#0] -- register_copy 
    // [1663] phi fopen::pathpos#7 = fopen::pathpos#10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#1] -- register_copy 
    // [1663] phi fopen::path#11 = fopen::path#13 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#2] -- register_copy 
    // [1663] phi fopen::pathstep#11 = fopen::pathstep#1 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#3] -- register_copy 
    // fopen::@10
  __b10:
    // pathtoken++;
    // [1664] fopen::pathtoken#1 = ++ fopen::pathtoken#10 -- pbuz1=_inc_pbuz1 
    inc.z pathtoken_1
    bne !+
    inc.z pathtoken_1+1
  !:
    // fopen::@22
    // pathtoken - 1
    // [1665] fopen::$28 = fopen::pathtoken#1 - 1 -- pbuz1=pbuz2_minus_1 
    lda.z pathtoken_1
    sec
    sbc #1
    sta.z fopen__28
    lda.z pathtoken_1+1
    sbc #0
    sta.z fopen__28+1
    // while (*(pathtoken - 1))
    // [1666] if(0!=*fopen::$28) goto fopen::@8 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (fopen__28),y
    cmp #0
    bne __b8
    // fopen::@26
    // __status = 0
    // [1667] ((char *)&__stdio_file+$46)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    tya
    ldy.z sp
    sta __stdio_file+$46,y
    // if(!__logical)
    // [1668] if(0!=((char *)&__stdio_file+$40)[fopen::sp#0]) goto fopen::@1 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$40,y
    cmp #0
    bne __b1
    // fopen::@27
    // __stdio_filecount+1
    // [1669] fopen::$4 = __stdio_filecount + 1 -- vbuaa=vbum1_plus_1 
    lda __stdio_filecount
    inc
    // __logical = __stdio_filecount+1
    // [1670] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::$4 -- pbuc1_derefidx_vbuz1=vbuaa 
    sta __stdio_file+$40,y
    // fopen::@1
  __b1:
    // if(!__device)
    // [1671] if(0!=((char *)&__stdio_file+$42)[fopen::sp#0]) goto fopen::@2 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    ldy.z sp
    lda __stdio_file+$42,y
    cmp #0
    bne __b2
    // fopen::@5
    // __device = 8
    // [1672] ((char *)&__stdio_file+$42)[fopen::sp#0] = 8 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #8
    sta __stdio_file+$42,y
    // fopen::@2
  __b2:
    // if(!__channel)
    // [1673] if(0!=((char *)&__stdio_file+$44)[fopen::sp#0]) goto fopen::@3 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    ldy.z sp
    lda __stdio_file+$44,y
    cmp #0
    bne __b3
    // fopen::@6
    // __stdio_filecount+2
    // [1674] fopen::$9 = __stdio_filecount + 2 -- vbuaa=vbum1_plus_2 
    lda __stdio_filecount
    clc
    adc #2
    // __channel = __stdio_filecount+2
    // [1675] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::$9 -- pbuc1_derefidx_vbuz1=vbuaa 
    sta __stdio_file+$44,y
    // fopen::@3
  __b3:
    // __filename
    // [1676] fopen::$11 = (char *)&__stdio_file + fopen::pathpos#0 -- pbuz1=pbuc1_plus_vbuz2 
    lda.z pathpos
    clc
    adc #<__stdio_file
    sta.z fopen__11
    lda #>__stdio_file
    adc #0
    sta.z fopen__11+1
    // cbm_k_setnam(__filename)
    // [1677] fopen::cbm_k_setnam1_filename = fopen::$11 -- pbuz1=pbuz2 
    lda.z fopen__11
    sta.z cbm_k_setnam1_filename
    lda.z fopen__11+1
    sta.z cbm_k_setnam1_filename+1
    // fopen::cbm_k_setnam1
    // strlen(filename)
    // [1678] strlen::str#4 = fopen::cbm_k_setnam1_filename -- pbuz1=pbuz2 
    lda.z cbm_k_setnam1_filename
    sta.z strlen.str
    lda.z cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [1679] call strlen
    // [1810] phi from fopen::cbm_k_setnam1 to strlen [phi:fopen::cbm_k_setnam1->strlen]
    // [1810] phi strlen::str#8 = strlen::str#4 [phi:fopen::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [1680] strlen::return#11 = strlen::len#2
    // fopen::@31
    // [1681] fopen::cbm_k_setnam1_$0 = strlen::return#11
    // char filename_len = (char)strlen(filename)
    // [1682] fopen::cbm_k_setnam1_filename_len = (char)fopen::cbm_k_setnam1_$0 -- vbuz1=_byte_vwuz2 
    lda.z cbm_k_setnam1_fopen__0
    sta.z cbm_k_setnam1_filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx cbm_k_setnam1_filename
    ldy cbm_k_setnam1_filename+1
    jsr CBM_SETNAM
    // fopen::@28
    // cbm_k_setlfs(__logical, __device, __channel)
    // [1684] cbm_k_setlfs::channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$40,y
    sta.z cbm_k_setlfs.channel
    // [1685] cbm_k_setlfs::device = ((char *)&__stdio_file+$42)[fopen::sp#0] -- vbuz1=pbuc1_derefidx_vbuz2 
    lda __stdio_file+$42,y
    sta.z cbm_k_setlfs.device
    // [1686] cbm_k_setlfs::command = ((char *)&__stdio_file+$44)[fopen::sp#0] -- vbuz1=pbuc1_derefidx_vbuz2 
    lda __stdio_file+$44,y
    sta.z cbm_k_setlfs.command
    // [1687] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // fopen::cbm_k_open1
    // asm
    // asm { jsrCBM_OPEN  }
    jsr CBM_OPEN
    // fopen::cbm_k_readst1
    // char status
    // [1689] fopen::cbm_k_readst1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [1691] fopen::cbm_k_readst1_return#0 = fopen::cbm_k_readst1_status -- vbuaa=vbuz1 
    // fopen::cbm_k_readst1_@return
    // }
    // [1692] fopen::cbm_k_readst1_return#1 = fopen::cbm_k_readst1_return#0
    // fopen::@29
    // cbm_k_readst()
    // [1693] fopen::$15 = fopen::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [1694] ((char *)&__stdio_file+$46)[fopen::sp#0] = fopen::$15 -- pbuc1_derefidx_vbuz1=vbuaa 
    ldy.z sp
    sta __stdio_file+$46,y
    // ferror(stream)
    // [1695] ferror::stream#0 = (struct $2 *)fopen::stream#0
    // [1696] call ferror
    jsr ferror
    // [1697] ferror::return#0 = ferror::return#1
    // fopen::@32
    // [1698] fopen::$16 = ferror::return#0
    // if (ferror(stream))
    // [1699] if(0==fopen::$16) goto fopen::@4 -- 0_eq_vwsz1_then_la1 
    lda.z fopen__16
    ora.z fopen__16+1
    beq __b4
    // fopen::@7
    // cbm_k_close(__logical)
    // [1700] fopen::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$40,y
    sta.z cbm_k_close1_channel
    // fopen::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // [1702] phi from fopen::cbm_k_close1 to fopen::@return [phi:fopen::cbm_k_close1->fopen::@return]
    // [1702] phi fopen::return#2 = 0 [phi:fopen::cbm_k_close1->fopen::@return#0] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fopen::@return
    // }
    // [1703] return 
    rts
    // fopen::@4
  __b4:
    // __stdio_filecount++;
    // [1704] __stdio_filecount = ++ __stdio_filecount -- vbum1=_inc_vbum1 
    inc __stdio_filecount
    // [1705] fopen::return#8 = (struct $2 *)fopen::stream#0
    // [1702] phi from fopen::@4 to fopen::@return [phi:fopen::@4->fopen::@return]
    // [1702] phi fopen::return#2 = fopen::return#8 [phi:fopen::@4->fopen::@return#0] -- register_copy 
    rts
    // fopen::@9
  __b9:
    // if (pathstep > 0)
    // [1706] if(fopen::pathstep#10>0) goto fopen::@11 -- vbuz1_gt_0_then_la1 
    lda.z pathstep
    bne __b11
    // fopen::@25
    // __stdio_file.filename[pathpos] = '\0'
    // [1707] ((char *)&__stdio_file)[fopen::pathpos#10] = '@' -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #'@'
    ldy.z pathpos_1
    sta __stdio_file,y
    // path = pathtoken + 1
    // [1708] fopen::path#0 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
    clc
    lda.z pathtoken_1
    adc #1
    sta.z path
    lda.z pathtoken_1+1
    adc #0
    sta.z path+1
    // [1709] phi from fopen::@16 fopen::@17 fopen::@18 fopen::@19 fopen::@25 to fopen::@12 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12]
    // [1709] phi fopen::num#15 = fopen::num#2 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#0] -- register_copy 
    // [1709] phi fopen::path#13 = fopen::path#16 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#1] -- register_copy 
    // fopen::@12
  __b12:
    // pathstep++;
    // [1710] fopen::pathstep#1 = ++ fopen::pathstep#10 -- vbuz1=_inc_vbuz1 
    inc.z pathstep
    jmp __b10
    // fopen::@11
  __b11:
    // char pathcmp = *path
    // [1711] fopen::pathcmp#0 = *fopen::path#10 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (path),y
    sta.z pathcmp
    // case 'D':
    // [1712] if(fopen::pathcmp#0=='D') goto fopen::@13 -- vbuz1_eq_vbuc1_then_la1 
    lda #'D'
    cmp.z pathcmp
    beq __b13
    // fopen::@20
    // case 'L':
    // [1713] if(fopen::pathcmp#0=='L') goto fopen::@13 -- vbuz1_eq_vbuc1_then_la1 
    lda #'L'
    cmp.z pathcmp
    beq __b13
    // fopen::@21
    // case 'C':
    //                     num = (char)atoi(path + 1);
    //                     path = pathtoken + 1;
    // [1714] if(fopen::pathcmp#0=='C') goto fopen::@13 -- vbuz1_eq_vbuc1_then_la1 
    lda #'C'
    cmp.z pathcmp
    beq __b13
    // [1715] phi from fopen::@21 fopen::@30 to fopen::@14 [phi:fopen::@21/fopen::@30->fopen::@14]
    // [1715] phi fopen::path#16 = fopen::path#10 [phi:fopen::@21/fopen::@30->fopen::@14#0] -- register_copy 
    // [1715] phi fopen::num#2 = fopen::num#10 [phi:fopen::@21/fopen::@30->fopen::@14#1] -- register_copy 
    // fopen::@14
  __b14:
    // case 'L':
    //                     __logical = num;
    //                     break;
    // [1716] if(fopen::pathcmp#0=='L') goto fopen::@17 -- vbuz1_eq_vbuc1_then_la1 
    lda #'L'
    cmp.z pathcmp
    beq __b17
    // fopen::@15
    // case 'D':
    //                     __device = num;
    //                     break;
    // [1717] if(fopen::pathcmp#0=='D') goto fopen::@18 -- vbuz1_eq_vbuc1_then_la1 
    lda #'D'
    cmp.z pathcmp
    beq __b18
    // fopen::@16
    // case 'C':
    //                     __channel = num;
    //                     break;
    // [1718] if(fopen::pathcmp#0!='C') goto fopen::@12 -- vbuz1_neq_vbuc1_then_la1 
    lda #'C'
    cmp.z pathcmp
    bne __b12
    // fopen::@19
    // __channel = num
    // [1719] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbuxx 
    ldy.z sp
    txa
    sta __stdio_file+$44,y
    jmp __b12
    // fopen::@18
  __b18:
    // __device = num
    // [1720] ((char *)&__stdio_file+$42)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbuxx 
    ldy.z sp
    txa
    sta __stdio_file+$42,y
    jmp __b12
    // fopen::@17
  __b17:
    // __logical = num
    // [1721] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbuxx 
    ldy.z sp
    txa
    sta __stdio_file+$40,y
    jmp __b12
    // fopen::@13
  __b13:
    // atoi(path + 1)
    // [1722] atoi::str#0 = fopen::path#10 + 1 -- pbuz1=pbuz1_plus_1 
    inc.z atoi.str
    bne !+
    inc.z atoi.str+1
  !:
    // [1723] call atoi
    // [2092] phi from fopen::@13 to atoi [phi:fopen::@13->atoi]
    // [2092] phi atoi::str#2 = atoi::str#0 [phi:fopen::@13->atoi#0] -- register_copy 
    jsr atoi
    // atoi(path + 1)
    // [1724] atoi::return#3 = atoi::return#2
    // fopen::@30
    // [1725] fopen::$26 = atoi::return#3
    // num = (char)atoi(path + 1)
    // [1726] fopen::num#1 = (char)fopen::$26 -- vbuxx=_byte_vwsz1 
    lda.z fopen__26
    tax
    // path = pathtoken + 1
    // [1727] fopen::path#1 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
    clc
    lda.z pathtoken_1
    adc #1
    sta.z path
    lda.z pathtoken_1+1
    adc #0
    sta.z path+1
    jmp __b14
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
// __zp($55) unsigned int fgets(__zp($37) char *ptr, __zp($29) unsigned int size, __zp($5b) struct $2 *stream)
fgets: {
    .label cbm_k_chkin1_channel = $75
    .label cbm_k_chkin1_status = $71
    .label cbm_k_readst1_status = $72
    .label cbm_k_readst2_status = $4e
    .label sp = $59
    .label return = $55
    .label bytes = $23
    .label read = $55
    .label ptr = $37
    .label remaining = $53
    .label stream = $5b
    .label size = $29
    // unsigned char sp = (unsigned char)stream
    // [1729] fgets::sp#0 = (char)fgets::stream#2 -- vbuz1=_byte_pssz2 
    lda.z stream
    sta.z sp
    // cbm_k_chkin(__logical)
    // [1730] fgets::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fgets::sp#0] -- vbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda __stdio_file+$40,y
    sta.z cbm_k_chkin1_channel
    // fgets::cbm_k_chkin1
    // char status
    // [1731] fgets::cbm_k_chkin1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fgets::cbm_k_readst1
    // char status
    // [1733] fgets::cbm_k_readst1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [1735] fgets::cbm_k_readst1_return#0 = fgets::cbm_k_readst1_status -- vbuaa=vbuz1 
    // fgets::cbm_k_readst1_@return
    // }
    // [1736] fgets::cbm_k_readst1_return#1 = fgets::cbm_k_readst1_return#0
    // fgets::@11
    // cbm_k_readst()
    // [1737] fgets::$1 = fgets::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [1738] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$1 -- pbuc1_derefidx_vbuz1=vbuaa 
    ldy.z sp
    sta __stdio_file+$46,y
    // if (__status)
    // [1739] if(0==((char *)&__stdio_file+$46)[fgets::sp#0]) goto fgets::@1 -- 0_eq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b1
    // [1740] phi from fgets::@11 fgets::@12 fgets::@5 to fgets::@return [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return]
  __b8:
    // [1740] phi fgets::return#1 = 0 [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return#0] -- vwuz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fgets::@return
    // }
    // [1741] return 
    rts
    // fgets::@1
  __b1:
    // [1742] fgets::remaining#22 = fgets::size#10 -- vwuz1=vwuz2 
    lda.z size
    sta.z remaining
    lda.z size+1
    sta.z remaining+1
    // [1743] phi from fgets::@1 to fgets::@2 [phi:fgets::@1->fgets::@2]
    // [1743] phi fgets::read#10 = 0 [phi:fgets::@1->fgets::@2#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z read
    sta.z read+1
    // [1743] phi fgets::remaining#11 = fgets::remaining#22 [phi:fgets::@1->fgets::@2#1] -- register_copy 
    // [1743] phi fgets::ptr#10 = fgets::ptr#12 [phi:fgets::@1->fgets::@2#2] -- register_copy 
    // [1743] phi from fgets::@17 fgets::@18 to fgets::@2 [phi:fgets::@17/fgets::@18->fgets::@2]
    // [1743] phi fgets::read#10 = fgets::read#1 [phi:fgets::@17/fgets::@18->fgets::@2#0] -- register_copy 
    // [1743] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@17/fgets::@18->fgets::@2#1] -- register_copy 
    // [1743] phi fgets::ptr#10 = fgets::ptr#13 [phi:fgets::@17/fgets::@18->fgets::@2#2] -- register_copy 
    // fgets::@2
  __b2:
    // if (!size)
    // [1744] if(0==fgets::size#10) goto fgets::@3 -- 0_eq_vwuz1_then_la1 
    lda.z size
    ora.z size+1
    bne !__b3+
    jmp __b3
  !__b3:
    // fgets::@8
    // if (remaining >= 512)
    // [1745] if(fgets::remaining#11>=$200) goto fgets::@4 -- vwuz1_ge_vwuc1_then_la1 
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
    // [1746] cx16_k_macptr::bytes = fgets::remaining#11 -- vbuz1=vwuz2 
    lda.z remaining
    sta.z cx16_k_macptr.bytes
    // [1747] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [1748] call cx16_k_macptr
    jsr cx16_k_macptr
    // [1749] cx16_k_macptr::return#4 = cx16_k_macptr::return#1
    // fgets::@15
  __b15:
    // bytes = cx16_k_macptr(remaining, ptr)
    // [1750] fgets::bytes#3 = cx16_k_macptr::return#4
    // [1751] phi from fgets::@13 fgets::@14 fgets::@15 to fgets::cbm_k_readst2 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2]
    // [1751] phi fgets::bytes#10 = fgets::bytes#1 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2#0] -- register_copy 
    // fgets::cbm_k_readst2
    // char status
    // [1752] fgets::cbm_k_readst2_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [1754] fgets::cbm_k_readst2_return#0 = fgets::cbm_k_readst2_status -- vbuaa=vbuz1 
    // fgets::cbm_k_readst2_@return
    // }
    // [1755] fgets::cbm_k_readst2_return#1 = fgets::cbm_k_readst2_return#0
    // fgets::@12
    // cbm_k_readst()
    // [1756] fgets::$8 = fgets::cbm_k_readst2_return#1
    // __status = cbm_k_readst()
    // [1757] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$8 -- pbuc1_derefidx_vbuz1=vbuaa 
    ldy.z sp
    sta __stdio_file+$46,y
    // __status & 0xBF
    // [1758] fgets::$9 = ((char *)&__stdio_file+$46)[fgets::sp#0] & $bf -- vbuaa=pbuc1_derefidx_vbuz1_band_vbuc2 
    lda #$bf
    and __stdio_file+$46,y
    // if (__status & 0xBF)
    // [1759] if(0==fgets::$9) goto fgets::@5 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b5
    jmp __b8
    // fgets::@5
  __b5:
    // if (bytes == 0xFFFF)
    // [1760] if(fgets::bytes#10!=$ffff) goto fgets::@6 -- vwuz1_neq_vwuc1_then_la1 
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
    // [1761] fgets::read#1 = fgets::read#10 + fgets::bytes#10 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z read
    adc.z bytes
    sta.z read
    lda.z read+1
    adc.z bytes+1
    sta.z read+1
    // ptr += bytes
    // [1762] fgets::ptr#0 = fgets::ptr#10 + fgets::bytes#10 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z ptr
    adc.z bytes
    sta.z ptr
    lda.z ptr+1
    adc.z bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [1763] fgets::$13 = byte1  fgets::ptr#0 -- vbuaa=_byte1_pbuz1 
    // if (BYTE1(ptr) == 0xC0)
    // [1764] if(fgets::$13!=$c0) goto fgets::@7 -- vbuaa_neq_vbuc1_then_la1 
    cmp #$c0
    bne __b7
    // fgets::@10
    // ptr -= 0x2000
    // [1765] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [1766] phi from fgets::@10 fgets::@6 to fgets::@7 [phi:fgets::@10/fgets::@6->fgets::@7]
    // [1766] phi fgets::ptr#13 = fgets::ptr#1 [phi:fgets::@10/fgets::@6->fgets::@7#0] -- register_copy 
    // fgets::@7
  __b7:
    // remaining -= bytes
    // [1767] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#10 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z remaining
    sec
    sbc.z bytes
    sta.z remaining
    lda.z remaining+1
    sbc.z bytes+1
    sta.z remaining+1
    // while ((__status == 0) && ((size && remaining) || !size))
    // [1768] if(((char *)&__stdio_file+$46)[fgets::sp#0]==0) goto fgets::@16 -- pbuc1_derefidx_vbuz1_eq_0_then_la1 
    ldy.z sp
    lda __stdio_file+$46,y
    cmp #0
    beq __b16
    // [1740] phi from fgets::@17 fgets::@7 to fgets::@return [phi:fgets::@17/fgets::@7->fgets::@return]
    // [1740] phi fgets::return#1 = fgets::read#1 [phi:fgets::@17/fgets::@7->fgets::@return#0] -- register_copy 
    rts
    // fgets::@16
  __b16:
    // while ((__status == 0) && ((size && remaining) || !size))
    // [1769] if(0==fgets::size#10) goto fgets::@17 -- 0_eq_vwuz1_then_la1 
    lda.z size
    ora.z size+1
    beq __b17
    // fgets::@18
    // [1770] if(0!=fgets::remaining#1) goto fgets::@2 -- 0_neq_vwuz1_then_la1 
    lda.z remaining
    ora.z remaining+1
    beq !__b2+
    jmp __b2
  !__b2:
    // fgets::@17
  __b17:
    // [1771] if(0==fgets::size#10) goto fgets::@2 -- 0_eq_vwuz1_then_la1 
    lda.z size
    ora.z size+1
    bne !__b2+
    jmp __b2
  !__b2:
    rts
    // fgets::@4
  __b4:
    // cx16_k_macptr(512, ptr)
    // [1772] cx16_k_macptr::bytes = $200 -- vbuz1=vwuc1 
    lda #<$200
    sta.z cx16_k_macptr.bytes
    // [1773] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [1774] call cx16_k_macptr
    jsr cx16_k_macptr
    // [1775] cx16_k_macptr::return#3 = cx16_k_macptr::return#1
    // fgets::@14
    // bytes = cx16_k_macptr(512, ptr)
    // [1776] fgets::bytes#2 = cx16_k_macptr::return#3
    jmp __b15
    // fgets::@3
  __b3:
    // cx16_k_macptr(0, ptr)
    // [1777] cx16_k_macptr::bytes = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cx16_k_macptr.bytes
    // [1778] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [1779] call cx16_k_macptr
    jsr cx16_k_macptr
    // [1780] cx16_k_macptr::return#2 = cx16_k_macptr::return#1
    // fgets::@13
    // bytes = cx16_k_macptr(0, ptr)
    // [1781] fgets::bytes#1 = cx16_k_macptr::return#2
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
// int fclose(__zp($40) struct $2 *stream)
fclose: {
    .label cbm_k_chkin1_channel = $e8
    .label cbm_k_chkin1_status = $e3
    .label cbm_k_readst1_status = $e4
    .label cbm_k_close1_channel = $e5
    .label cbm_k_readst2_status = $e6
    .label sp = $e9
    .label stream = $40
    // unsigned char sp = (unsigned char)stream
    // [1783] fclose::sp#0 = (char)fclose::stream#2 -- vbuz1=_byte_pssz2 
    lda.z stream
    sta.z sp
    // cbm_k_chkin(__logical)
    // [1784] fclose::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda __stdio_file+$40,y
    sta.z cbm_k_chkin1_channel
    // fclose::cbm_k_chkin1
    // char status
    // [1785] fclose::cbm_k_chkin1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fclose::cbm_k_readst1
    // char status
    // [1787] fclose::cbm_k_readst1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [1789] fclose::cbm_k_readst1_return#0 = fclose::cbm_k_readst1_status -- vbuaa=vbuz1 
    // fclose::cbm_k_readst1_@return
    // }
    // [1790] fclose::cbm_k_readst1_return#1 = fclose::cbm_k_readst1_return#0
    // fclose::@3
    // cbm_k_readst()
    // [1791] fclose::$1 = fclose::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [1792] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$1 -- pbuc1_derefidx_vbuz1=vbuaa 
    ldy.z sp
    sta __stdio_file+$46,y
    // if (__status)
    // [1793] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@1 -- 0_eq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b1
    // fclose::@return
    // }
    // [1794] return 
    rts
    // fclose::@1
  __b1:
    // cbm_k_close(__logical)
    // [1795] fclose::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$40,y
    sta.z cbm_k_close1_channel
    // fclose::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // fclose::cbm_k_readst2
    // char status
    // [1797] fclose::cbm_k_readst2_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [1799] fclose::cbm_k_readst2_return#0 = fclose::cbm_k_readst2_status -- vbuaa=vbuz1 
    // fclose::cbm_k_readst2_@return
    // }
    // [1800] fclose::cbm_k_readst2_return#1 = fclose::cbm_k_readst2_return#0
    // fclose::@4
    // cbm_k_readst()
    // [1801] fclose::$4 = fclose::cbm_k_readst2_return#1
    // __status = cbm_k_readst()
    // [1802] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$4 -- pbuc1_derefidx_vbuz1=vbuaa 
    ldy.z sp
    sta __stdio_file+$46,y
    // if (__status)
    // [1803] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@2 -- 0_eq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b2
    rts
    // fclose::@2
  __b2:
    // __logical = 0
    // [1804] ((char *)&__stdio_file+$40)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    ldy.z sp
    sta __stdio_file+$40,y
    // __device = 0
    // [1805] ((char *)&__stdio_file+$42)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [1806] ((char *)&__stdio_file+$44)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$44,y
    // __filename
    // [1807] fclose::$6 = fclose::sp#0 << 1 -- vbuaa=vbuz1_rol_1 
    tya
    asl
    // *__filename = '\0'
    // [1808] ((char *)&__stdio_file)[fclose::$6] = '@' -- pbuc1_derefidx_vbuaa=vbuc2 
    tay
    lda #'@'
    sta __stdio_file,y
    // __stdio_filecount--;
    // [1809] __stdio_filecount = -- __stdio_filecount -- vbum1=_dec_vbum1 
    dec __stdio_filecount
    rts
}
  // strlen
// Computes the length of the string str up to but not including the terminating null character.
// __zp($3a) unsigned int strlen(__zp($37) char *str)
strlen: {
    .label return = $3a
    .label len = $3a
    .label str = $37
    // [1811] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [1811] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z len
    sta.z len+1
    // [1811] phi strlen::str#6 = strlen::str#8 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [1812] if(0!=*strlen::str#6) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [1813] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [1814] strlen::len#1 = ++ strlen::len#2 -- vwuz1=_inc_vwuz1 
    inc.z len
    bne !+
    inc.z len+1
  !:
    // str++;
    // [1815] strlen::str#1 = ++ strlen::str#6 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [1811] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [1811] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [1811] phi strlen::str#6 = strlen::str#1 [phi:strlen::@2->strlen::@1#1] -- register_copy 
    jmp __b1
}
  // printf_padding
// Print a padding char a number of times
// void printf_padding(__zp($53) void (*putc)(char), __zp($48) char pad, __zp($45) char length)
printf_padding: {
    .label i = $39
    .label putc = $53
    .label length = $45
    .label pad = $48
    // [1817] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [1817] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [1818] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z length
    bcc __b2
    // printf_padding::@return
    // }
    // [1819] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [1820] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbuz1 
    lda.z pad
    pha
    // [1821] callexecute *printf_padding::putc#7  -- call__deref_pprz1 
    jsr icall20
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [1823] printf_padding::i#1 = ++ printf_padding::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1817] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [1817] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
    jmp __b1
    // Outside Flow
  icall20:
    jmp (putc)
}
  // uctoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void uctoa(__register(X) char value, __zp($23) char *buffer, __register(Y) char radix)
uctoa: {
    .label buffer = $23
    .label digit = $43
    .label started = $4b
    .label max_digits = $58
    .label digit_values = $55
    // if(radix==DECIMAL)
    // [1824] if(uctoa::radix#0==DECIMAL) goto uctoa::@1 -- vbuyy_eq_vbuc1_then_la1 
    cpy #DECIMAL
    beq __b2
    // uctoa::@2
    // if(radix==HEXADECIMAL)
    // [1825] if(uctoa::radix#0==HEXADECIMAL) goto uctoa::@1 -- vbuyy_eq_vbuc1_then_la1 
    cpy #HEXADECIMAL
    beq __b3
    // uctoa::@3
    // if(radix==OCTAL)
    // [1826] if(uctoa::radix#0==OCTAL) goto uctoa::@1 -- vbuyy_eq_vbuc1_then_la1 
    cpy #OCTAL
    beq __b4
    // uctoa::@4
    // if(radix==BINARY)
    // [1827] if(uctoa::radix#0==BINARY) goto uctoa::@1 -- vbuyy_eq_vbuc1_then_la1 
    cpy #BINARY
    beq __b5
    // uctoa::@5
    // *buffer++ = 'e'
    // [1828] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1829] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1830] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1831] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // uctoa::@return
    // }
    // [1832] return 
    rts
    // [1833] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
  __b2:
    // [1833] phi uctoa::digit_values#8 = RADIX_DECIMAL_VALUES_CHAR [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1833] phi uctoa::max_digits#7 = 3 [phi:uctoa->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [1833] phi from uctoa::@2 to uctoa::@1 [phi:uctoa::@2->uctoa::@1]
  __b3:
    // [1833] phi uctoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_CHAR [phi:uctoa::@2->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1833] phi uctoa::max_digits#7 = 2 [phi:uctoa::@2->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #2
    sta.z max_digits
    jmp __b1
    // [1833] phi from uctoa::@3 to uctoa::@1 [phi:uctoa::@3->uctoa::@1]
  __b4:
    // [1833] phi uctoa::digit_values#8 = RADIX_OCTAL_VALUES_CHAR [phi:uctoa::@3->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values+1
    // [1833] phi uctoa::max_digits#7 = 3 [phi:uctoa::@3->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [1833] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
  __b5:
    // [1833] phi uctoa::digit_values#8 = RADIX_BINARY_VALUES_CHAR [phi:uctoa::@4->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_BINARY_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_CHAR
    sta.z digit_values+1
    // [1833] phi uctoa::max_digits#7 = 8 [phi:uctoa::@4->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #8
    sta.z max_digits
    // uctoa::@1
  __b1:
    // [1834] phi from uctoa::@1 to uctoa::@6 [phi:uctoa::@1->uctoa::@6]
    // [1834] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa::@1->uctoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1834] phi uctoa::started#2 = 0 [phi:uctoa::@1->uctoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [1834] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa::@1->uctoa::@6#2] -- register_copy 
    // [1834] phi uctoa::digit#2 = 0 [phi:uctoa::@1->uctoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // uctoa::@6
  __b6:
    // max_digits-1
    // [1835] uctoa::$4 = uctoa::max_digits#7 - 1 -- vbuaa=vbuz1_minus_1 
    lda.z max_digits
    sec
    sbc #1
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1836] if(uctoa::digit#2<uctoa::$4) goto uctoa::@7 -- vbuz1_lt_vbuaa_then_la1 
    cmp.z digit
    beq !+
    bcs __b7
  !:
    // uctoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1837] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbuxx 
    lda DIGITS,x
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1838] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1839] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // uctoa::@7
  __b7:
    // unsigned char digit_value = digit_values[digit]
    // [1840] uctoa::digit_value#0 = uctoa::digit_values#8[uctoa::digit#2] -- vbuyy=pbuz1_derefidx_vbuz2 
    ldy.z digit
    lda (digit_values),y
    tay
    // if (started || value >= digit_value)
    // [1841] if(0!=uctoa::started#2) goto uctoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // uctoa::@12
    // [1842] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@10 -- vbuxx_ge_vbuyy_then_la1 
    sty.z $ff
    cpx.z $ff
    bcs __b10
    // [1843] phi from uctoa::@12 to uctoa::@9 [phi:uctoa::@12->uctoa::@9]
    // [1843] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@12->uctoa::@9#0] -- register_copy 
    // [1843] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@12->uctoa::@9#1] -- register_copy 
    // [1843] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@12->uctoa::@9#2] -- register_copy 
    // uctoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1844] uctoa::digit#1 = ++ uctoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1834] phi from uctoa::@9 to uctoa::@6 [phi:uctoa::@9->uctoa::@6]
    // [1834] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@9->uctoa::@6#0] -- register_copy 
    // [1834] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@9->uctoa::@6#1] -- register_copy 
    // [1834] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@9->uctoa::@6#2] -- register_copy 
    // [1834] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@9->uctoa::@6#3] -- register_copy 
    jmp __b6
    // uctoa::@10
  __b10:
    // uctoa_append(buffer++, value, digit_value)
    // [1845] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [1846] uctoa_append::value#0 = uctoa::value#2
    // [1847] uctoa_append::sub#0 = uctoa::digit_value#0 -- vbuz1=vbuyy 
    sty.z uctoa_append.sub
    // [1848] call uctoa_append
    // [2113] phi from uctoa::@10 to uctoa_append [phi:uctoa::@10->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [1849] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@11
    // value = uctoa_append(buffer++, value, digit_value)
    // [1850] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [1851] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1843] phi from uctoa::@11 to uctoa::@9 [phi:uctoa::@11->uctoa::@9]
    // [1843] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@11->uctoa::@9#0] -- register_copy 
    // [1843] phi uctoa::started#4 = 1 [phi:uctoa::@11->uctoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [1843] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@11->uctoa::@9#2] -- register_copy 
    jmp __b9
}
  // cbm_k_getin
/**
 * @brief Scan a character from keyboard without pressing enter.
 * 
 * @return char The character read.
 */
cbm_k_getin: {
    // __mem unsigned char ch
    // [1852] cbm_k_getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // asm
    // asm { jsrCBM_GETIN stach  }
    jsr CBM_GETIN
    sta ch
    // return ch;
    // [1854] cbm_k_getin::return#0 = cbm_k_getin::ch -- vbuaa=vbum1 
    // cbm_k_getin::@return
    // }
    // [1855] cbm_k_getin::return#1 = cbm_k_getin::return#0
    // [1856] return 
    rts
  .segment Data
    ch: .byte 0
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
// __zp($b9) unsigned long rom_address_from_bank(__register(A) char rom_bank)
rom_address_from_bank: {
    .label rom_address_from_bank__1 = $b9
    .label return = $b9
    // ((unsigned long)(rom_bank)) << 14
    // [1857] rom_address_from_bank::$1 = (unsigned long)rom_address_from_bank::rom_bank#0 -- vduz1=_dword_vbuaa 
    sta.z rom_address_from_bank__1
    lda #0
    sta.z rom_address_from_bank__1+1
    sta.z rom_address_from_bank__1+2
    sta.z rom_address_from_bank__1+3
    // [1858] rom_address_from_bank::return#0 = rom_address_from_bank::$1 << $e -- vduz1=vduz1_rol_vbuc1 
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
    // [1859] return 
    rts
}
  // printf_ulong
// Print an unsigned int using a specific format
// void printf_ulong(void (*putc)(char), __zp($25) unsigned long uvalue, char format_min_length, char format_justify_left, char format_sign_always, char format_zero_padding, char format_upper_case, char format_radix)
printf_ulong: {
    .label uvalue = $25
    // printf_ulong::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1861] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // ultoa(uvalue, printf_buffer.digits, format.radix)
    // [1862] ultoa::value#1 = printf_ulong::uvalue#2
    // [1863] call ultoa
  // Format number into buffer
    // [2120] phi from printf_ulong::@1 to ultoa [phi:printf_ulong::@1->ultoa]
    jsr ultoa
    // printf_ulong::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1864] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [1865] call printf_number_buffer
  // Print using format
    // [1616] phi from printf_ulong::@2 to printf_number_buffer [phi:printf_ulong::@2->printf_number_buffer]
    // [1616] phi printf_number_buffer::putc#10 = &snputc [phi:printf_ulong::@2->printf_number_buffer#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_number_buffer.putc
    lda #>snputc
    sta.z printf_number_buffer.putc+1
    // [1616] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_ulong::@2->printf_number_buffer#1] -- register_copy 
    // [1616] phi printf_number_buffer::format_zero_padding#10 = 1 [phi:printf_ulong::@2->printf_number_buffer#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_number_buffer.format_zero_padding
    // [1616] phi printf_number_buffer::format_min_length#3 = 5 [phi:printf_ulong::@2->printf_number_buffer#3] -- vbuxx=vbuc1 
    ldx #5
    jsr printf_number_buffer
    // printf_ulong::@return
    // }
    // [1866] return 
    rts
}
  // strncpy
/// Copies up to n characters from the string pointed to, by src to dst.
/// In a case where the length of src is less than that of n, the remainder of dst will be padded with null bytes.
/// @param dst ? This is the pointer to the destination array where the content is to be copied.
/// @param src ? This is the string to be copied.
/// @param n ? The number of characters to be copied from source.
/// @return The destination
// char * strncpy(__zp($5f) char *dst, __zp($49) const char *src, __zp($4f) unsigned int n)
strncpy: {
    .label dst = $5f
    .label i = $5d
    .label src = $49
    .label n = $4f
    // [1868] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [1868] phi strncpy::dst#3 = strncpy::dst#8 [phi:strncpy->strncpy::@1#0] -- register_copy 
    // [1868] phi strncpy::src#3 = strncpy::src#6 [phi:strncpy->strncpy::@1#1] -- register_copy 
    // [1868] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwuz1=vwuc1 
    lda #<0
    sta.z i
    sta.z i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [1869] if(strncpy::i#2<strncpy::n#3) goto strncpy::@2 -- vwuz1_lt_vwuz2_then_la1 
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
    // [1870] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [1871] strncpy::c#0 = *strncpy::src#3 -- vbuaa=_deref_pbuz1 
    ldy #0
    lda (src),y
    // if(c)
    // [1872] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b3
    // strncpy::@4
    // src++;
    // [1873] strncpy::src#0 = ++ strncpy::src#3 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [1874] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [1874] phi strncpy::src#7 = strncpy::src#3 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [1875] *strncpy::dst#3 = strncpy::c#0 -- _deref_pbuz1=vbuaa 
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [1876] strncpy::dst#0 = ++ strncpy::dst#3 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [1877] strncpy::i#1 = ++ strncpy::i#2 -- vwuz1=_inc_vwuz1 
    inc.z i
    bne !+
    inc.z i+1
  !:
    // [1868] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [1868] phi strncpy::dst#3 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [1868] phi strncpy::src#3 = strncpy::src#7 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [1868] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
    jmp __b1
}
  // insertup
// Insert a new line, and scroll the upper part of the screen up.
// void insertup(char rows)
insertup: {
    .label width = $36
    .label y = $32
    // __conio.width+1
    // [1878] insertup::$0 = *((char *)&__conio+6) + 1 -- vbuaa=_deref_pbuc1_plus_1 
    lda __conio+6
    inc
    // unsigned char width = (__conio.width+1) * 2
    // [1879] insertup::width#0 = insertup::$0 << 1 -- vbuz1=vbuaa_rol_1 
    // {asm{.byte $db}}
    asl
    sta.z width
    // [1880] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [1880] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [1881] if(insertup::y#2<*((char *)&__conio+1)) goto insertup::@2 -- vbuz1_lt__deref_pbuc1_then_la1 
    lda.z y
    cmp __conio+1
    bcc __b2
    // [1882] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [1883] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [1884] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [1885] insertup::$4 = insertup::y#2 + 1 -- vbuxx=vbuz1_plus_1 
    ldx.z y
    inx
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [1886] insertup::$6 = insertup::y#2 << 1 -- vbuyy=vbuz1_rol_1 
    lda.z y
    asl
    tay
    // [1887] insertup::$7 = insertup::$4 << 1 -- vbuxx=vbuxx_rol_1 
    txa
    asl
    tax
    // [1888] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z memcpy8_vram_vram.dbank_vram
    // [1889] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwuz1=pwuc1_derefidx_vbuyy 
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.doffset_vram+1
    // [1890] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+5) -- vbuyy=_deref_pbuc1 
    ldy __conio+5
    // [1891] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwuz1=pwuc1_derefidx_vbuxx 
    lda __conio+$15,x
    sta.z memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,x
    sta.z memcpy8_vram_vram.soffset_vram+1
    // [1892] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbuz1=vbuz2 
    lda.z width
    sta.z memcpy8_vram_vram.num8
    // [1893] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [1894] insertup::y#1 = ++ insertup::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [1880] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [1880] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
    jmp __b1
}
  // clearline
clearline: {
    .label addr = $33
    // unsigned int addr = __conio.offsets[__conio.cursor_y]
    // [1895] clearline::$3 = *((char *)&__conio+1) << 1 -- vbuaa=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    // [1896] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwuz1=pwuc1_derefidx_vbuaa 
    tay
    lda __conio+$15,y
    sta.z addr
    lda __conio+$15+1,y
    sta.z addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1897] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [1898] clearline::$0 = byte0  clearline::addr#0 -- vbuaa=_byte0_vwuz1 
    lda.z addr
    // *VERA_ADDRX_L = BYTE0(addr)
    // [1899] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [1900] clearline::$1 = byte1  clearline::addr#0 -- vbuaa=_byte1_vwuz1 
    lda.z addr+1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [1901] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [1902] clearline::$2 = *((char *)&__conio+5) | VERA_INC_1 -- vbuaa=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1903] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [1904] clearline::c#0 = *((char *)&__conio+6) -- vbuxx=_deref_pbuc1 
    ldx __conio+6
    // [1905] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [1905] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [1906] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1907] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [1908] clearline::c#1 = -- clearline::c#2 -- vbuxx=_dec_vbuxx 
    dex
    // while(c)
    // [1909] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuxx_then_la1 
    cpx #0
    bne __b1
    // clearline::@return
    // }
    // [1910] return 
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
    // [1912] gotoxy::x#5 = display_frame_maskxy::cpeekcxy1_x#0
    // [1913] gotoxy::y#5 = display_frame_maskxy::cpeekcxy1_y#0
    // [1914] call gotoxy
    // [590] phi from display_frame_maskxy::cpeekcxy1 to gotoxy [phi:display_frame_maskxy::cpeekcxy1->gotoxy]
    // [590] phi gotoxy::y#24 = gotoxy::y#5 [phi:display_frame_maskxy::cpeekcxy1->gotoxy#0] -- register_copy 
    // [590] phi gotoxy::x#24 = gotoxy::x#5 [phi:display_frame_maskxy::cpeekcxy1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_frame_maskxy::cpeekcxy1_cpeekc1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1915] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(__conio.offset)
    // [1916] display_frame_maskxy::cpeekcxy1_cpeekc1_$0 = byte0  *((unsigned int *)&__conio+$13) -- vbuaa=_byte0__deref_pwuc1 
    lda __conio+$13
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [1917] *VERA_ADDRX_L = display_frame_maskxy::cpeekcxy1_cpeekc1_$0 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [1918] display_frame_maskxy::cpeekcxy1_cpeekc1_$1 = byte1  *((unsigned int *)&__conio+$13) -- vbuaa=_byte1__deref_pwuc1 
    lda __conio+$13+1
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [1919] *VERA_ADDRX_M = display_frame_maskxy::cpeekcxy1_cpeekc1_$1 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_0
    // [1920] display_frame_maskxy::cpeekcxy1_cpeekc1_$2 = *((char *)&__conio+5) -- vbuaa=_deref_pbuc1 
    lda __conio+5
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_0
    // [1921] *VERA_ADDRX_H = display_frame_maskxy::cpeekcxy1_cpeekc1_$2 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_H
    // return *VERA_DATA0;
    // [1922] display_frame_maskxy::c#0 = *VERA_DATA0 -- vbuaa=_deref_pbuc1 
    lda VERA_DATA0
    // display_frame_maskxy::@12
    // case 0x70: // DR corner.
    //             return 0b0110;
    // [1923] if(display_frame_maskxy::c#0==$70) goto display_frame_maskxy::@return -- vbuaa_eq_vbuc1_then_la1 
    cmp #$70
    beq __b2
    // display_frame_maskxy::@1
    // case 0x6E: // DL corner.
    //             return 0b0011;
    // [1924] if(display_frame_maskxy::c#0==$6e) goto display_frame_maskxy::@return -- vbuaa_eq_vbuc1_then_la1 
    cmp #$6e
    beq __b1
    // display_frame_maskxy::@2
    // case 0x6D: // UR corner.
    //             return 0b1100;
    // [1925] if(display_frame_maskxy::c#0==$6d) goto display_frame_maskxy::@return -- vbuaa_eq_vbuc1_then_la1 
    cmp #$6d
    beq __b3
    // display_frame_maskxy::@3
    // case 0x7D: // UL corner.
    //             return 0b1001;
    // [1926] if(display_frame_maskxy::c#0==$7d) goto display_frame_maskxy::@return -- vbuaa_eq_vbuc1_then_la1 
    cmp #$7d
    beq __b4
    // display_frame_maskxy::@4
    // case 0x40: // HL line.
    //             return 0b0101;
    // [1927] if(display_frame_maskxy::c#0==$40) goto display_frame_maskxy::@return -- vbuaa_eq_vbuc1_then_la1 
    cmp #$40
    beq __b5
    // display_frame_maskxy::@5
    // case 0x5D: // VL line.
    //             return 0b1010;
    // [1928] if(display_frame_maskxy::c#0==$5d) goto display_frame_maskxy::@return -- vbuaa_eq_vbuc1_then_la1 
    cmp #$5d
    beq __b6
    // display_frame_maskxy::@6
    // case 0x6B: // VR junction.
    //             return 0b1110;
    // [1929] if(display_frame_maskxy::c#0==$6b) goto display_frame_maskxy::@return -- vbuaa_eq_vbuc1_then_la1 
    cmp #$6b
    beq __b7
    // display_frame_maskxy::@7
    // case 0x73: // VL junction.
    //             return 0b1011;
    // [1930] if(display_frame_maskxy::c#0==$73) goto display_frame_maskxy::@return -- vbuaa_eq_vbuc1_then_la1 
    cmp #$73
    beq __b8
    // display_frame_maskxy::@8
    // case 0x72: // HD junction.
    //             return 0b0111;
    // [1931] if(display_frame_maskxy::c#0==$72) goto display_frame_maskxy::@return -- vbuaa_eq_vbuc1_then_la1 
    cmp #$72
    beq __b9
    // display_frame_maskxy::@9
    // case 0x71: // HU junction.
    //             return 0b1101;
    // [1932] if(display_frame_maskxy::c#0==$71) goto display_frame_maskxy::@return -- vbuaa_eq_vbuc1_then_la1 
    cmp #$71
    beq __b10
    // display_frame_maskxy::@10
    // case 0x5B: // HV junction.
    //             return 0b1111;
    // [1933] if(display_frame_maskxy::c#0==$5b) goto display_frame_maskxy::@11 -- vbuaa_eq_vbuc1_then_la1 
    cmp #$5b
    beq __b11
    // [1935] phi from display_frame_maskxy::@10 to display_frame_maskxy::@return [phi:display_frame_maskxy::@10->display_frame_maskxy::@return]
    // [1935] phi display_frame_maskxy::return#12 = 0 [phi:display_frame_maskxy::@10->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #0
    rts
    // [1934] phi from display_frame_maskxy::@10 to display_frame_maskxy::@11 [phi:display_frame_maskxy::@10->display_frame_maskxy::@11]
    // display_frame_maskxy::@11
  __b11:
    // [1935] phi from display_frame_maskxy::@11 to display_frame_maskxy::@return [phi:display_frame_maskxy::@11->display_frame_maskxy::@return]
    // [1935] phi display_frame_maskxy::return#12 = $f [phi:display_frame_maskxy::@11->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #$f
    rts
    // [1935] phi from display_frame_maskxy::@1 to display_frame_maskxy::@return [phi:display_frame_maskxy::@1->display_frame_maskxy::@return]
  __b1:
    // [1935] phi display_frame_maskxy::return#12 = 3 [phi:display_frame_maskxy::@1->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #3
    rts
    // [1935] phi from display_frame_maskxy::@12 to display_frame_maskxy::@return [phi:display_frame_maskxy::@12->display_frame_maskxy::@return]
  __b2:
    // [1935] phi display_frame_maskxy::return#12 = 6 [phi:display_frame_maskxy::@12->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #6
    rts
    // [1935] phi from display_frame_maskxy::@2 to display_frame_maskxy::@return [phi:display_frame_maskxy::@2->display_frame_maskxy::@return]
  __b3:
    // [1935] phi display_frame_maskxy::return#12 = $c [phi:display_frame_maskxy::@2->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #$c
    rts
    // [1935] phi from display_frame_maskxy::@3 to display_frame_maskxy::@return [phi:display_frame_maskxy::@3->display_frame_maskxy::@return]
  __b4:
    // [1935] phi display_frame_maskxy::return#12 = 9 [phi:display_frame_maskxy::@3->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #9
    rts
    // [1935] phi from display_frame_maskxy::@4 to display_frame_maskxy::@return [phi:display_frame_maskxy::@4->display_frame_maskxy::@return]
  __b5:
    // [1935] phi display_frame_maskxy::return#12 = 5 [phi:display_frame_maskxy::@4->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #5
    rts
    // [1935] phi from display_frame_maskxy::@5 to display_frame_maskxy::@return [phi:display_frame_maskxy::@5->display_frame_maskxy::@return]
  __b6:
    // [1935] phi display_frame_maskxy::return#12 = $a [phi:display_frame_maskxy::@5->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #$a
    rts
    // [1935] phi from display_frame_maskxy::@6 to display_frame_maskxy::@return [phi:display_frame_maskxy::@6->display_frame_maskxy::@return]
  __b7:
    // [1935] phi display_frame_maskxy::return#12 = $e [phi:display_frame_maskxy::@6->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #$e
    rts
    // [1935] phi from display_frame_maskxy::@7 to display_frame_maskxy::@return [phi:display_frame_maskxy::@7->display_frame_maskxy::@return]
  __b8:
    // [1935] phi display_frame_maskxy::return#12 = $b [phi:display_frame_maskxy::@7->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #$b
    rts
    // [1935] phi from display_frame_maskxy::@8 to display_frame_maskxy::@return [phi:display_frame_maskxy::@8->display_frame_maskxy::@return]
  __b9:
    // [1935] phi display_frame_maskxy::return#12 = 7 [phi:display_frame_maskxy::@8->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #7
    rts
    // [1935] phi from display_frame_maskxy::@9 to display_frame_maskxy::@return [phi:display_frame_maskxy::@9->display_frame_maskxy::@return]
  __b10:
    // [1935] phi display_frame_maskxy::return#12 = $d [phi:display_frame_maskxy::@9->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #$d
    // display_frame_maskxy::@return
    // }
    // [1936] return 
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
    // [1938] if(display_frame_char::mask#10==6) goto display_frame_char::@return -- vbuaa_eq_vbuc1_then_la1 
    cmp #6
    beq __b1
    // display_frame_char::@1
    // case 0b0011:
    //             return 0x6E;
    // [1939] if(display_frame_char::mask#10==3) goto display_frame_char::@return -- vbuaa_eq_vbuc1_then_la1 
    // DR corner.
    cmp #3
    beq __b2
    // display_frame_char::@2
    // case 0b1100:
    //             return 0x6D;
    // [1940] if(display_frame_char::mask#10==$c) goto display_frame_char::@return -- vbuaa_eq_vbuc1_then_la1 
    // DL corner.
    cmp #$c
    beq __b3
    // display_frame_char::@3
    // case 0b1001:
    //             return 0x7D;
    // [1941] if(display_frame_char::mask#10==9) goto display_frame_char::@return -- vbuaa_eq_vbuc1_then_la1 
    // UR corner.
    cmp #9
    beq __b4
    // display_frame_char::@4
    // case 0b0101:
    //             return 0x40;
    // [1942] if(display_frame_char::mask#10==5) goto display_frame_char::@return -- vbuaa_eq_vbuc1_then_la1 
    // UL corner.
    cmp #5
    beq __b5
    // display_frame_char::@5
    // case 0b1010:
    //             return 0x5D;
    // [1943] if(display_frame_char::mask#10==$a) goto display_frame_char::@return -- vbuaa_eq_vbuc1_then_la1 
    // HL line.
    cmp #$a
    beq __b6
    // display_frame_char::@6
    // case 0b1110:
    //             return 0x6B;
    // [1944] if(display_frame_char::mask#10==$e) goto display_frame_char::@return -- vbuaa_eq_vbuc1_then_la1 
    // VL line.
    cmp #$e
    beq __b7
    // display_frame_char::@7
    // case 0b1011:
    //             return 0x73;
    // [1945] if(display_frame_char::mask#10==$b) goto display_frame_char::@return -- vbuaa_eq_vbuc1_then_la1 
    // VR junction.
    cmp #$b
    beq __b8
    // display_frame_char::@8
    // case 0b0111:
    //             return 0x72;
    // [1946] if(display_frame_char::mask#10==7) goto display_frame_char::@return -- vbuaa_eq_vbuc1_then_la1 
    // VL junction.
    cmp #7
    beq __b9
    // display_frame_char::@9
    // case 0b1101:
    //             return 0x71;
    // [1947] if(display_frame_char::mask#10==$d) goto display_frame_char::@return -- vbuaa_eq_vbuc1_then_la1 
    // HD junction.
    cmp #$d
    beq __b10
    // display_frame_char::@10
    // case 0b1111:
    //             return 0x5B;
    // [1948] if(display_frame_char::mask#10==$f) goto display_frame_char::@11 -- vbuaa_eq_vbuc1_then_la1 
    // HU junction.
    cmp #$f
    beq __b11
    // [1950] phi from display_frame_char::@10 to display_frame_char::@return [phi:display_frame_char::@10->display_frame_char::@return]
    // [1950] phi display_frame_char::return#12 = $20 [phi:display_frame_char::@10->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$20
    rts
    // [1949] phi from display_frame_char::@10 to display_frame_char::@11 [phi:display_frame_char::@10->display_frame_char::@11]
    // display_frame_char::@11
  __b11:
    // [1950] phi from display_frame_char::@11 to display_frame_char::@return [phi:display_frame_char::@11->display_frame_char::@return]
    // [1950] phi display_frame_char::return#12 = $5b [phi:display_frame_char::@11->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$5b
    rts
    // [1950] phi from display_frame_char to display_frame_char::@return [phi:display_frame_char->display_frame_char::@return]
  __b1:
    // [1950] phi display_frame_char::return#12 = $70 [phi:display_frame_char->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$70
    rts
    // [1950] phi from display_frame_char::@1 to display_frame_char::@return [phi:display_frame_char::@1->display_frame_char::@return]
  __b2:
    // [1950] phi display_frame_char::return#12 = $6e [phi:display_frame_char::@1->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$6e
    rts
    // [1950] phi from display_frame_char::@2 to display_frame_char::@return [phi:display_frame_char::@2->display_frame_char::@return]
  __b3:
    // [1950] phi display_frame_char::return#12 = $6d [phi:display_frame_char::@2->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$6d
    rts
    // [1950] phi from display_frame_char::@3 to display_frame_char::@return [phi:display_frame_char::@3->display_frame_char::@return]
  __b4:
    // [1950] phi display_frame_char::return#12 = $7d [phi:display_frame_char::@3->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$7d
    rts
    // [1950] phi from display_frame_char::@4 to display_frame_char::@return [phi:display_frame_char::@4->display_frame_char::@return]
  __b5:
    // [1950] phi display_frame_char::return#12 = $40 [phi:display_frame_char::@4->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$40
    rts
    // [1950] phi from display_frame_char::@5 to display_frame_char::@return [phi:display_frame_char::@5->display_frame_char::@return]
  __b6:
    // [1950] phi display_frame_char::return#12 = $5d [phi:display_frame_char::@5->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$5d
    rts
    // [1950] phi from display_frame_char::@6 to display_frame_char::@return [phi:display_frame_char::@6->display_frame_char::@return]
  __b7:
    // [1950] phi display_frame_char::return#12 = $6b [phi:display_frame_char::@6->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$6b
    rts
    // [1950] phi from display_frame_char::@7 to display_frame_char::@return [phi:display_frame_char::@7->display_frame_char::@return]
  __b8:
    // [1950] phi display_frame_char::return#12 = $73 [phi:display_frame_char::@7->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$73
    rts
    // [1950] phi from display_frame_char::@8 to display_frame_char::@return [phi:display_frame_char::@8->display_frame_char::@return]
  __b9:
    // [1950] phi display_frame_char::return#12 = $72 [phi:display_frame_char::@8->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$72
    rts
    // [1950] phi from display_frame_char::@9 to display_frame_char::@return [phi:display_frame_char::@9->display_frame_char::@return]
  __b10:
    // [1950] phi display_frame_char::return#12 = $71 [phi:display_frame_char::@9->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$71
    // display_frame_char::@return
    // }
    // [1951] return 
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
// void display_chip_led(__zp($6e) char x, char y, __zp($42) char w, __register(X) char tc, char bc)
display_chip_led: {
    .label x = $6e
    .label w = $42
    // textcolor(tc)
    // [1953] textcolor::color#11 = display_chip_led::tc#3
    // [1954] call textcolor
    // [572] phi from display_chip_led to textcolor [phi:display_chip_led->textcolor]
    // [572] phi textcolor::color#17 = textcolor::color#11 [phi:display_chip_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [1955] phi from display_chip_led to display_chip_led::@3 [phi:display_chip_led->display_chip_led::@3]
    // display_chip_led::@3
    // bgcolor(bc)
    // [1956] call bgcolor
    // [577] phi from display_chip_led::@3 to bgcolor [phi:display_chip_led::@3->bgcolor]
    // [577] phi bgcolor::color#14 = BLUE [phi:display_chip_led::@3->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // [1957] phi from display_chip_led::@3 display_chip_led::@5 to display_chip_led::@1 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1]
    // [1957] phi display_chip_led::w#4 = display_chip_led::w#7 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1#0] -- register_copy 
    // [1957] phi display_chip_led::x#4 = display_chip_led::x#7 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1#1] -- register_copy 
    // display_chip_led::@1
  __b1:
    // cputcxy(x, y, 0x6F)
    // [1958] cputcxy::x#9 = display_chip_led::x#4 -- vbuxx=vbuz1 
    ldx.z x
    // [1959] call cputcxy
    // [1495] phi from display_chip_led::@1 to cputcxy [phi:display_chip_led::@1->cputcxy]
    // [1495] phi cputcxy::c#13 = $6f [phi:display_chip_led::@1->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6f
    sta.z cputcxy.c
    // [1495] phi cputcxy::y#13 = 3 [phi:display_chip_led::@1->cputcxy#1] -- vbuyy=vbuc1 
    ldy #3
    // [1495] phi cputcxy::x#13 = cputcxy::x#9 [phi:display_chip_led::@1->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_led::@4
    // cputcxy(x, y+1, 0x77)
    // [1960] cputcxy::x#10 = display_chip_led::x#4 -- vbuxx=vbuz1 
    ldx.z x
    // [1961] call cputcxy
    // [1495] phi from display_chip_led::@4 to cputcxy [phi:display_chip_led::@4->cputcxy]
    // [1495] phi cputcxy::c#13 = $77 [phi:display_chip_led::@4->cputcxy#0] -- vbuz1=vbuc1 
    lda #$77
    sta.z cputcxy.c
    // [1495] phi cputcxy::y#13 = 3+1 [phi:display_chip_led::@4->cputcxy#1] -- vbuyy=vbuc1 
    ldy #3+1
    // [1495] phi cputcxy::x#13 = cputcxy::x#10 [phi:display_chip_led::@4->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_led::@5
    // x++;
    // [1962] display_chip_led::x#0 = ++ display_chip_led::x#4 -- vbuz1=_inc_vbuz1 
    inc.z x
    // while(--w)
    // [1963] display_chip_led::w#0 = -- display_chip_led::w#4 -- vbuz1=_dec_vbuz1 
    dec.z w
    // [1964] if(0!=display_chip_led::w#0) goto display_chip_led::@1 -- 0_neq_vbuz1_then_la1 
    lda.z w
    bne __b1
    // [1965] phi from display_chip_led::@5 to display_chip_led::@2 [phi:display_chip_led::@5->display_chip_led::@2]
    // display_chip_led::@2
    // textcolor(WHITE)
    // [1966] call textcolor
    // [572] phi from display_chip_led::@2 to textcolor [phi:display_chip_led::@2->textcolor]
    // [572] phi textcolor::color#17 = WHITE [phi:display_chip_led::@2->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [1967] phi from display_chip_led::@2 to display_chip_led::@6 [phi:display_chip_led::@2->display_chip_led::@6]
    // display_chip_led::@6
    // bgcolor(BLUE)
    // [1968] call bgcolor
    // [577] phi from display_chip_led::@6 to bgcolor [phi:display_chip_led::@6->bgcolor]
    // [577] phi bgcolor::color#14 = BLUE [phi:display_chip_led::@6->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // display_chip_led::@return
    // }
    // [1969] return 
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
// void display_chip_line(__zp($c9) char x, __zp($e7) char y, __zp($b2) char w, __zp($c2) char c)
display_chip_line: {
    .label i = $6a
    .label x = $c9
    .label w = $b2
    .label c = $c2
    .label y = $e7
    // gotoxy(x, y)
    // [1971] gotoxy::x#7 = display_chip_line::x#16 -- vbuxx=vbuz1 
    ldx.z x
    // [1972] gotoxy::y#7 = display_chip_line::y#16 -- vbuyy=vbuz1 
    ldy.z y
    // [1973] call gotoxy
    // [590] phi from display_chip_line to gotoxy [phi:display_chip_line->gotoxy]
    // [590] phi gotoxy::y#24 = gotoxy::y#7 [phi:display_chip_line->gotoxy#0] -- register_copy 
    // [590] phi gotoxy::x#24 = gotoxy::x#7 [phi:display_chip_line->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1974] phi from display_chip_line to display_chip_line::@4 [phi:display_chip_line->display_chip_line::@4]
    // display_chip_line::@4
    // textcolor(GREY)
    // [1975] call textcolor
    // [572] phi from display_chip_line::@4 to textcolor [phi:display_chip_line::@4->textcolor]
    // [572] phi textcolor::color#17 = GREY [phi:display_chip_line::@4->textcolor#0] -- vbuxx=vbuc1 
    ldx #GREY
    jsr textcolor
    // [1976] phi from display_chip_line::@4 to display_chip_line::@5 [phi:display_chip_line::@4->display_chip_line::@5]
    // display_chip_line::@5
    // bgcolor(BLUE)
    // [1977] call bgcolor
    // [577] phi from display_chip_line::@5 to bgcolor [phi:display_chip_line::@5->bgcolor]
    // [577] phi bgcolor::color#14 = BLUE [phi:display_chip_line::@5->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // display_chip_line::@6
    // cputc(VERA_CHR_UR)
    // [1978] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [1979] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [1981] call textcolor
    // [572] phi from display_chip_line::@6 to textcolor [phi:display_chip_line::@6->textcolor]
    // [572] phi textcolor::color#17 = WHITE [phi:display_chip_line::@6->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [1982] phi from display_chip_line::@6 to display_chip_line::@7 [phi:display_chip_line::@6->display_chip_line::@7]
    // display_chip_line::@7
    // bgcolor(BLACK)
    // [1983] call bgcolor
    // [577] phi from display_chip_line::@7 to bgcolor [phi:display_chip_line::@7->bgcolor]
    // [577] phi bgcolor::color#14 = BLACK [phi:display_chip_line::@7->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLACK
    jsr bgcolor
    // [1984] phi from display_chip_line::@7 to display_chip_line::@1 [phi:display_chip_line::@7->display_chip_line::@1]
    // [1984] phi display_chip_line::i#2 = 0 [phi:display_chip_line::@7->display_chip_line::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // display_chip_line::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [1985] if(display_chip_line::i#2<display_chip_line::w#10) goto display_chip_line::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [1986] phi from display_chip_line::@1 to display_chip_line::@3 [phi:display_chip_line::@1->display_chip_line::@3]
    // display_chip_line::@3
    // textcolor(GREY)
    // [1987] call textcolor
    // [572] phi from display_chip_line::@3 to textcolor [phi:display_chip_line::@3->textcolor]
    // [572] phi textcolor::color#17 = GREY [phi:display_chip_line::@3->textcolor#0] -- vbuxx=vbuc1 
    ldx #GREY
    jsr textcolor
    // [1988] phi from display_chip_line::@3 to display_chip_line::@8 [phi:display_chip_line::@3->display_chip_line::@8]
    // display_chip_line::@8
    // bgcolor(BLUE)
    // [1989] call bgcolor
    // [577] phi from display_chip_line::@8 to bgcolor [phi:display_chip_line::@8->bgcolor]
    // [577] phi bgcolor::color#14 = BLUE [phi:display_chip_line::@8->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // display_chip_line::@9
    // cputc(VERA_CHR_UL)
    // [1990] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [1991] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [1993] call textcolor
    // [572] phi from display_chip_line::@9 to textcolor [phi:display_chip_line::@9->textcolor]
    // [572] phi textcolor::color#17 = WHITE [phi:display_chip_line::@9->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [1994] phi from display_chip_line::@9 to display_chip_line::@10 [phi:display_chip_line::@9->display_chip_line::@10]
    // display_chip_line::@10
    // bgcolor(BLACK)
    // [1995] call bgcolor
    // [577] phi from display_chip_line::@10 to bgcolor [phi:display_chip_line::@10->bgcolor]
    // [577] phi bgcolor::color#14 = BLACK [phi:display_chip_line::@10->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLACK
    jsr bgcolor
    // display_chip_line::@11
    // cputcxy(x+2, y, c)
    // [1996] cputcxy::x#8 = display_chip_line::x#16 + 2 -- vbuxx=vbuz1_plus_2 
    ldx.z x
    inx
    inx
    // [1997] cputcxy::y#8 = display_chip_line::y#16 -- vbuyy=vbuz1 
    ldy.z y
    // [1998] cputcxy::c#8 = display_chip_line::c#15 -- vbuz1=vbuz2 
    lda.z c
    sta.z cputcxy.c
    // [1999] call cputcxy
    // [1495] phi from display_chip_line::@11 to cputcxy [phi:display_chip_line::@11->cputcxy]
    // [1495] phi cputcxy::c#13 = cputcxy::c#8 [phi:display_chip_line::@11->cputcxy#0] -- register_copy 
    // [1495] phi cputcxy::y#13 = cputcxy::y#8 [phi:display_chip_line::@11->cputcxy#1] -- register_copy 
    // [1495] phi cputcxy::x#13 = cputcxy::x#8 [phi:display_chip_line::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_line::@return
    // }
    // [2000] return 
    rts
    // display_chip_line::@2
  __b2:
    // cputc(VERA_CHR_SPACE)
    // [2001] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [2002] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [2004] display_chip_line::i#1 = ++ display_chip_line::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1984] phi from display_chip_line::@2 to display_chip_line::@1 [phi:display_chip_line::@2->display_chip_line::@1]
    // [1984] phi display_chip_line::i#2 = display_chip_line::i#1 [phi:display_chip_line::@2->display_chip_line::@1#0] -- register_copy 
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
// void display_chip_end(__register(X) char x, char y, __zp($b4) char w)
display_chip_end: {
    .label i = $69
    .label w = $b4
    // gotoxy(x, y)
    // [2005] gotoxy::x#8 = display_chip_end::x#0
    // [2006] call gotoxy
    // [590] phi from display_chip_end to gotoxy [phi:display_chip_end->gotoxy]
    // [590] phi gotoxy::y#24 = display_print_chip::y#21 [phi:display_chip_end->gotoxy#0] -- vbuyy=vbuc1 
    ldy #display_print_chip.y
    // [590] phi gotoxy::x#24 = gotoxy::x#8 [phi:display_chip_end->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [2007] phi from display_chip_end to display_chip_end::@4 [phi:display_chip_end->display_chip_end::@4]
    // display_chip_end::@4
    // textcolor(GREY)
    // [2008] call textcolor
    // [572] phi from display_chip_end::@4 to textcolor [phi:display_chip_end::@4->textcolor]
    // [572] phi textcolor::color#17 = GREY [phi:display_chip_end::@4->textcolor#0] -- vbuxx=vbuc1 
    ldx #GREY
    jsr textcolor
    // [2009] phi from display_chip_end::@4 to display_chip_end::@5 [phi:display_chip_end::@4->display_chip_end::@5]
    // display_chip_end::@5
    // bgcolor(BLUE)
    // [2010] call bgcolor
    // [577] phi from display_chip_end::@5 to bgcolor [phi:display_chip_end::@5->bgcolor]
    // [577] phi bgcolor::color#14 = BLUE [phi:display_chip_end::@5->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // display_chip_end::@6
    // cputc(VERA_CHR_UR)
    // [2011] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [2012] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [2014] call textcolor
    // [572] phi from display_chip_end::@6 to textcolor [phi:display_chip_end::@6->textcolor]
    // [572] phi textcolor::color#17 = BLUE [phi:display_chip_end::@6->textcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr textcolor
    // [2015] phi from display_chip_end::@6 to display_chip_end::@7 [phi:display_chip_end::@6->display_chip_end::@7]
    // display_chip_end::@7
    // bgcolor(BLACK)
    // [2016] call bgcolor
    // [577] phi from display_chip_end::@7 to bgcolor [phi:display_chip_end::@7->bgcolor]
    // [577] phi bgcolor::color#14 = BLACK [phi:display_chip_end::@7->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLACK
    jsr bgcolor
    // [2017] phi from display_chip_end::@7 to display_chip_end::@1 [phi:display_chip_end::@7->display_chip_end::@1]
    // [2017] phi display_chip_end::i#2 = 0 [phi:display_chip_end::@7->display_chip_end::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // display_chip_end::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [2018] if(display_chip_end::i#2<display_chip_end::w#0) goto display_chip_end::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [2019] phi from display_chip_end::@1 to display_chip_end::@3 [phi:display_chip_end::@1->display_chip_end::@3]
    // display_chip_end::@3
    // textcolor(GREY)
    // [2020] call textcolor
    // [572] phi from display_chip_end::@3 to textcolor [phi:display_chip_end::@3->textcolor]
    // [572] phi textcolor::color#17 = GREY [phi:display_chip_end::@3->textcolor#0] -- vbuxx=vbuc1 
    ldx #GREY
    jsr textcolor
    // [2021] phi from display_chip_end::@3 to display_chip_end::@8 [phi:display_chip_end::@3->display_chip_end::@8]
    // display_chip_end::@8
    // bgcolor(BLUE)
    // [2022] call bgcolor
    // [577] phi from display_chip_end::@8 to bgcolor [phi:display_chip_end::@8->bgcolor]
    // [577] phi bgcolor::color#14 = BLUE [phi:display_chip_end::@8->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // display_chip_end::@9
    // cputc(VERA_CHR_UL)
    // [2023] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [2024] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_chip_end::@return
    // }
    // [2026] return 
    rts
    // display_chip_end::@2
  __b2:
    // cputc(VERA_CHR_HL)
    // [2027] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [2028] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [2030] display_chip_end::i#1 = ++ display_chip_end::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [2017] phi from display_chip_end::@2 to display_chip_end::@1 [phi:display_chip_end::@2->display_chip_end::@1]
    // [2017] phi display_chip_end::i#2 = display_chip_end::i#1 [phi:display_chip_end::@2->display_chip_end::@1#0] -- register_copy 
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
// __zp($23) unsigned int utoa_append(__zp($37) char *buffer, __zp($23) unsigned int value, __zp($29) unsigned int sub)
utoa_append: {
    .label buffer = $37
    .label value = $23
    .label sub = $29
    .label return = $23
    // [2032] phi from utoa_append to utoa_append::@1 [phi:utoa_append->utoa_append::@1]
    // [2032] phi utoa_append::digit#2 = 0 [phi:utoa_append->utoa_append::@1#0] -- vbuxx=vbuc1 
    ldx #0
    // [2032] phi utoa_append::value#2 = utoa_append::value#0 [phi:utoa_append->utoa_append::@1#1] -- register_copy 
    // utoa_append::@1
  __b1:
    // while (value >= sub)
    // [2033] if(utoa_append::value#2>=utoa_append::sub#0) goto utoa_append::@2 -- vwuz1_ge_vwuz2_then_la1 
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
    // [2034] *utoa_append::buffer#0 = DIGITS[utoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuxx 
    lda DIGITS,x
    ldy #0
    sta (buffer),y
    // utoa_append::@return
    // }
    // [2035] return 
    rts
    // utoa_append::@2
  __b2:
    // digit++;
    // [2036] utoa_append::digit#1 = ++ utoa_append::digit#2 -- vbuxx=_inc_vbuxx 
    inx
    // value -= sub
    // [2037] utoa_append::value#1 = utoa_append::value#2 - utoa_append::sub#0 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z value
    sec
    sbc.z sub
    sta.z value
    lda.z value+1
    sbc.z sub+1
    sta.z value+1
    // [2032] phi from utoa_append::@2 to utoa_append::@1 [phi:utoa_append::@2->utoa_append::@1]
    // [2032] phi utoa_append::digit#2 = utoa_append::digit#1 [phi:utoa_append::@2->utoa_append::@1#0] -- register_copy 
    // [2032] phi utoa_append::value#2 = utoa_append::value#1 [phi:utoa_append::@2->utoa_append::@1#1] -- register_copy 
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
// void cbm_k_setlfs(__zp($d9) volatile char channel, __zp($d0) volatile char device, __zp($ca) volatile char command)
cbm_k_setlfs: {
    .label channel = $d9
    .label device = $d0
    .label command = $ca
    // asm
    // asm { ldxdevice ldachannel ldycommand jsrCBM_SETLFS  }
    ldx device
    lda channel
    ldy command
    jsr CBM_SETLFS
    // cbm_k_setlfs::@return
    // }
    // [2039] return 
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
// __zp($c7) int ferror(__zp($29) struct $2 *stream)
ferror: {
    .label cbm_k_setnam1_filename = $cd
    .label cbm_k_setnam1_filename_len = $c3
    .label cbm_k_setnam1_ferror__0 = $3a
    .label cbm_k_chkin1_channel = $cb
    .label cbm_k_chkin1_status = $c4
    .label cbm_k_chrin1_ch = $c5
    .label cbm_k_readst1_status = $73
    .label cbm_k_close1_channel = $c6
    .label cbm_k_chrin2_ch = $74
    .label stream = $29
    .label return = $c7
    .label sp = $b4
    .label ch = $6d
    .label errno_len = $6e
    .label errno_parsed = $6f
    // unsigned char sp = (unsigned char)stream
    // [2040] ferror::sp#0 = (char)ferror::stream#0 -- vbuz1=_byte_pssz2 
    lda.z stream
    sta.z sp
    // cbm_k_setlfs(15, 8, 15)
    // [2041] cbm_k_setlfs::channel = $f -- vbuz1=vbuc1 
    lda #$f
    sta.z cbm_k_setlfs.channel
    // [2042] cbm_k_setlfs::device = 8 -- vbuz1=vbuc1 
    lda #8
    sta.z cbm_k_setlfs.device
    // [2043] cbm_k_setlfs::command = $f -- vbuz1=vbuc1 
    lda #$f
    sta.z cbm_k_setlfs.command
    // [2044] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // ferror::@11
    // cbm_k_setnam("")
    // [2045] ferror::cbm_k_setnam1_filename = info_text4 -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z cbm_k_setnam1_filename
    lda #>info_text4
    sta.z cbm_k_setnam1_filename+1
    // ferror::cbm_k_setnam1
    // strlen(filename)
    // [2046] strlen::str#5 = ferror::cbm_k_setnam1_filename -- pbuz1=pbuz2 
    lda.z cbm_k_setnam1_filename
    sta.z strlen.str
    lda.z cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [2047] call strlen
    // [1810] phi from ferror::cbm_k_setnam1 to strlen [phi:ferror::cbm_k_setnam1->strlen]
    // [1810] phi strlen::str#8 = strlen::str#5 [phi:ferror::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [2048] strlen::return#12 = strlen::len#2
    // ferror::@12
    // [2049] ferror::cbm_k_setnam1_$0 = strlen::return#12
    // char filename_len = (char)strlen(filename)
    // [2050] ferror::cbm_k_setnam1_filename_len = (char)ferror::cbm_k_setnam1_$0 -- vbuz1=_byte_vwuz2 
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
    // [2053] ferror::cbm_k_chkin1_channel = $f -- vbuz1=vbuc1 
    lda #$f
    sta.z cbm_k_chkin1_channel
    // ferror::cbm_k_chkin1
    // char status
    // [2054] ferror::cbm_k_chkin1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // ferror::cbm_k_chrin1
    // char ch
    // [2056] ferror::cbm_k_chrin1_ch = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chrin1_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin1_ch
    // return ch;
    // [2058] ferror::cbm_k_chrin1_return#0 = ferror::cbm_k_chrin1_ch -- vbuaa=vbuz1 
    // ferror::cbm_k_chrin1_@return
    // }
    // [2059] ferror::cbm_k_chrin1_return#1 = ferror::cbm_k_chrin1_return#0
    // ferror::@7
    // char ch = cbm_k_chrin()
    // [2060] ferror::ch#0 = ferror::cbm_k_chrin1_return#1 -- vbuz1=vbuaa 
    sta.z ch
    // [2061] phi from ferror::@7 to ferror::cbm_k_readst1 [phi:ferror::@7->ferror::cbm_k_readst1]
    // [2061] phi __errno#16 = __errno#295 [phi:ferror::@7->ferror::cbm_k_readst1#0] -- register_copy 
    // [2061] phi ferror::errno_len#10 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z errno_len
    // [2061] phi ferror::ch#10 = ferror::ch#0 [phi:ferror::@7->ferror::cbm_k_readst1#2] -- register_copy 
    // [2061] phi ferror::errno_parsed#2 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#3] -- vbuz1=vbuc1 
    sta.z errno_parsed
    // ferror::cbm_k_readst1
  cbm_k_readst1:
    // char status
    // [2062] ferror::cbm_k_readst1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2064] ferror::cbm_k_readst1_return#0 = ferror::cbm_k_readst1_status -- vbuaa=vbuz1 
    // ferror::cbm_k_readst1_@return
    // }
    // [2065] ferror::cbm_k_readst1_return#1 = ferror::cbm_k_readst1_return#0
    // ferror::@8
    // cbm_k_readst()
    // [2066] ferror::$6 = ferror::cbm_k_readst1_return#1
    // st = cbm_k_readst()
    // [2067] ferror::st#1 = ferror::$6
    // while (!(st = cbm_k_readst()))
    // [2068] if(0==ferror::st#1) goto ferror::@1 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b1
    // ferror::@2
    // __status = st
    // [2069] ((char *)&__stdio_file+$46)[ferror::sp#0] = ferror::st#1 -- pbuc1_derefidx_vbuz1=vbuaa 
    ldy.z sp
    sta __stdio_file+$46,y
    // cbm_k_close(15)
    // [2070] ferror::cbm_k_close1_channel = $f -- vbuz1=vbuc1 
    lda #$f
    sta.z cbm_k_close1_channel
    // ferror::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // ferror::@9
    // return __errno;
    // [2072] ferror::return#1 = __errno#16 -- vwsz1=vwsz2 
    lda.z __errno
    sta.z return
    lda.z __errno+1
    sta.z return+1
    // ferror::@return
    // }
    // [2073] return 
    rts
    // ferror::@1
  __b1:
    // if (!errno_parsed)
    // [2074] if(0!=ferror::errno_parsed#2) goto ferror::@3 -- 0_neq_vbuz1_then_la1 
    lda.z errno_parsed
    bne __b3
    // ferror::@4
    // if (ch == ',')
    // [2075] if(ferror::ch#10!=',') goto ferror::@3 -- vbuz1_neq_vbuc1_then_la1 
    lda #','
    cmp.z ch
    bne __b3
    // ferror::@5
    // errno_parsed++;
    // [2076] ferror::errno_parsed#1 = ++ ferror::errno_parsed#2 -- vbuz1=_inc_vbuz1 
    inc.z errno_parsed
    // strncpy(temp, __errno_error, errno_len+1)
    // [2077] strncpy::n#0 = ferror::errno_len#10 + 1 -- vwuz1=vbuz2_plus_1 
    lda.z errno_len
    clc
    adc #1
    sta.z strncpy.n
    lda #0
    adc #0
    sta.z strncpy.n+1
    // [2078] call strncpy
    // [1867] phi from ferror::@5 to strncpy [phi:ferror::@5->strncpy]
    // [1867] phi strncpy::dst#8 = ferror::temp [phi:ferror::@5->strncpy#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z strncpy.dst
    lda #>temp
    sta.z strncpy.dst+1
    // [1867] phi strncpy::src#6 = __errno_error [phi:ferror::@5->strncpy#1] -- pbuz1=pbuc1 
    lda #<__errno_error
    sta.z strncpy.src
    lda #>__errno_error
    sta.z strncpy.src+1
    // [1867] phi strncpy::n#3 = strncpy::n#0 [phi:ferror::@5->strncpy#2] -- register_copy 
    jsr strncpy
    // [2079] phi from ferror::@5 to ferror::@13 [phi:ferror::@5->ferror::@13]
    // ferror::@13
    // atoi(temp)
    // [2080] call atoi
    // [2092] phi from ferror::@13 to atoi [phi:ferror::@13->atoi]
    // [2092] phi atoi::str#2 = ferror::temp [phi:ferror::@13->atoi#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z atoi.str
    lda #>temp
    sta.z atoi.str+1
    jsr atoi
    // atoi(temp)
    // [2081] atoi::return#4 = atoi::return#2
    // ferror::@14
    // __errno = atoi(temp)
    // [2082] __errno#2 = atoi::return#4 -- vwsz1=vwsz2 
    lda.z atoi.return
    sta.z __errno
    lda.z atoi.return+1
    sta.z __errno+1
    // [2083] phi from ferror::@1 ferror::@14 ferror::@4 to ferror::@3 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3]
    // [2083] phi __errno#107 = __errno#16 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#0] -- register_copy 
    // [2083] phi ferror::errno_parsed#11 = ferror::errno_parsed#2 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#1] -- register_copy 
    // ferror::@3
  __b3:
    // __errno_error[errno_len] = ch
    // [2084] __errno_error[ferror::errno_len#10] = ferror::ch#10 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z ch
    ldy.z errno_len
    sta __errno_error,y
    // errno_len++;
    // [2085] ferror::errno_len#1 = ++ ferror::errno_len#10 -- vbuz1=_inc_vbuz1 
    inc.z errno_len
    // ferror::cbm_k_chrin2
    // char ch
    // [2086] ferror::cbm_k_chrin2_ch = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chrin2_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin2_ch
    // return ch;
    // [2088] ferror::cbm_k_chrin2_return#0 = ferror::cbm_k_chrin2_ch -- vbuaa=vbuz1 
    // ferror::cbm_k_chrin2_@return
    // }
    // [2089] ferror::cbm_k_chrin2_return#1 = ferror::cbm_k_chrin2_return#0
    // ferror::@10
    // cbm_k_chrin()
    // [2090] ferror::$15 = ferror::cbm_k_chrin2_return#1
    // ch = cbm_k_chrin()
    // [2091] ferror::ch#1 = ferror::$15 -- vbuz1=vbuaa 
    sta.z ch
    // [2061] phi from ferror::@10 to ferror::cbm_k_readst1 [phi:ferror::@10->ferror::cbm_k_readst1]
    // [2061] phi __errno#16 = __errno#107 [phi:ferror::@10->ferror::cbm_k_readst1#0] -- register_copy 
    // [2061] phi ferror::errno_len#10 = ferror::errno_len#1 [phi:ferror::@10->ferror::cbm_k_readst1#1] -- register_copy 
    // [2061] phi ferror::ch#10 = ferror::ch#1 [phi:ferror::@10->ferror::cbm_k_readst1#2] -- register_copy 
    // [2061] phi ferror::errno_parsed#2 = ferror::errno_parsed#11 [phi:ferror::@10->ferror::cbm_k_readst1#3] -- register_copy 
    jmp cbm_k_readst1
  .segment Data
    temp: .fill 4, 0
}
.segment Code
  // atoi
// Converts the string argument str to an integer.
// __zp($4f) int atoi(__zp($5b) const char *str)
atoi: {
    .label atoi__6 = $4f
    .label atoi__7 = $4f
    .label res = $4f
    .label return = $4f
    .label str = $5b
    .label atoi__10 = $49
    .label atoi__11 = $4f
    // if (str[i] == '-')
    // [2093] if(*atoi::str#2!='-') goto atoi::@3 -- _deref_pbuz1_neq_vbuc1_then_la1 
    ldy #0
    lda (str),y
    cmp #'-'
    bne __b2
    // [2094] phi from atoi to atoi::@2 [phi:atoi->atoi::@2]
    // atoi::@2
    // [2095] phi from atoi::@2 to atoi::@3 [phi:atoi::@2->atoi::@3]
    // [2095] phi atoi::negative#2 = 1 [phi:atoi::@2->atoi::@3#0] -- vbuxx=vbuc1 
    ldx #1
    // [2095] phi atoi::res#2 = 0 [phi:atoi::@2->atoi::@3#1] -- vwsz1=vwsc1 
    tya
    sta.z res
    sta.z res+1
    // [2095] phi atoi::i#4 = 1 [phi:atoi::@2->atoi::@3#2] -- vbuyy=vbuc1 
    ldy #1
    jmp __b3
  // Iterate through all digits and update the result
    // [2095] phi from atoi to atoi::@3 [phi:atoi->atoi::@3]
  __b2:
    // [2095] phi atoi::negative#2 = 0 [phi:atoi->atoi::@3#0] -- vbuxx=vbuc1 
    ldx #0
    // [2095] phi atoi::res#2 = 0 [phi:atoi->atoi::@3#1] -- vwsz1=vwsc1 
    txa
    sta.z res
    sta.z res+1
    // [2095] phi atoi::i#4 = 0 [phi:atoi->atoi::@3#2] -- vbuyy=vbuc1 
    tay
    // atoi::@3
  __b3:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [2096] if(atoi::str#2[atoi::i#4]<'0') goto atoi::@5 -- pbuz1_derefidx_vbuyy_lt_vbuc1_then_la1 
    lda (str),y
    cmp #'0'
    bcc __b5
    // atoi::@6
    // [2097] if(atoi::str#2[atoi::i#4]<='9') goto atoi::@4 -- pbuz1_derefidx_vbuyy_le_vbuc1_then_la1 
    lda (str),y
    cmp #'9'
    bcc __b4
    beq __b4
    // atoi::@5
  __b5:
    // if(negative)
    // [2098] if(0!=atoi::negative#2) goto atoi::@1 -- 0_neq_vbuxx_then_la1 
    // Return result with sign
    cpx #0
    bne __b1
    // [2100] phi from atoi::@1 atoi::@5 to atoi::@return [phi:atoi::@1/atoi::@5->atoi::@return]
    // [2100] phi atoi::return#2 = atoi::return#0 [phi:atoi::@1/atoi::@5->atoi::@return#0] -- register_copy 
    rts
    // atoi::@1
  __b1:
    // return -res;
    // [2099] atoi::return#0 = - atoi::res#2 -- vwsz1=_neg_vwsz1 
    lda #0
    sec
    sbc.z return
    sta.z return
    lda #0
    sbc.z return+1
    sta.z return+1
    // atoi::@return
    // }
    // [2101] return 
    rts
    // atoi::@4
  __b4:
    // res * 10
    // [2102] atoi::$10 = atoi::res#2 << 2 -- vwsz1=vwsz2_rol_2 
    lda.z res
    asl
    sta.z atoi__10
    lda.z res+1
    rol
    sta.z atoi__10+1
    asl.z atoi__10
    rol.z atoi__10+1
    // [2103] atoi::$11 = atoi::$10 + atoi::res#2 -- vwsz1=vwsz2_plus_vwsz1 
    clc
    lda.z atoi__11
    adc.z atoi__10
    sta.z atoi__11
    lda.z atoi__11+1
    adc.z atoi__10+1
    sta.z atoi__11+1
    // [2104] atoi::$6 = atoi::$11 << 1 -- vwsz1=vwsz1_rol_1 
    asl.z atoi__6
    rol.z atoi__6+1
    // res * 10 + str[i]
    // [2105] atoi::$7 = atoi::$6 + atoi::str#2[atoi::i#4] -- vwsz1=vwsz1_plus_pbuz2_derefidx_vbuyy 
    lda.z atoi__7
    clc
    adc (str),y
    sta.z atoi__7
    bcc !+
    inc.z atoi__7+1
  !:
    // res = res * 10 + str[i] - '0'
    // [2106] atoi::res#1 = atoi::$7 - '0' -- vwsz1=vwsz1_minus_vbuc1 
    lda.z res
    sec
    sbc #'0'
    sta.z res
    bcs !+
    dec.z res+1
  !:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [2107] atoi::i#2 = ++ atoi::i#4 -- vbuyy=_inc_vbuyy 
    iny
    // [2095] phi from atoi::@4 to atoi::@3 [phi:atoi::@4->atoi::@3]
    // [2095] phi atoi::negative#2 = atoi::negative#2 [phi:atoi::@4->atoi::@3#0] -- register_copy 
    // [2095] phi atoi::res#2 = atoi::res#1 [phi:atoi::@4->atoi::@3#1] -- register_copy 
    // [2095] phi atoi::i#4 = atoi::i#2 [phi:atoi::@4->atoi::@3#2] -- register_copy 
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
// __zp($23) unsigned int cx16_k_macptr(__zp($57) volatile char bytes, __zp($51) void * volatile buffer)
cx16_k_macptr: {
    .label bytes = $57
    .label buffer = $51
    .label bytes_read = $3c
    .label return = $23
    // unsigned int bytes_read
    // [2108] cx16_k_macptr::bytes_read = 0 -- vwuz1=vwuc1 
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
    // [2110] cx16_k_macptr::return#0 = cx16_k_macptr::bytes_read -- vwuz1=vwuz2 
    lda.z bytes_read
    sta.z return
    lda.z bytes_read+1
    sta.z return+1
    // cx16_k_macptr::@return
    // }
    // [2111] cx16_k_macptr::return#1 = cx16_k_macptr::return#0
    // [2112] return 
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
// __register(X) char uctoa_append(__zp($4c) char *buffer, __register(X) char value, __zp($2f) char sub)
uctoa_append: {
    .label buffer = $4c
    .label sub = $2f
    // [2114] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [2114] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbuyy=vbuc1 
    ldy #0
    // [2114] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [2115] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbuxx_ge_vbuz1_then_la1 
    cpx.z sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [2116] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuyy 
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // uctoa_append::@return
    // }
    // [2117] return 
    rts
    // uctoa_append::@2
  __b2:
    // digit++;
    // [2118] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbuyy=_inc_vbuyy 
    iny
    // value -= sub
    // [2119] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbuxx=vbuxx_minus_vbuz1 
    txa
    sec
    sbc.z sub
    tax
    // [2114] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [2114] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [2114] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
    jmp __b1
}
  // ultoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void ultoa(__zp($25) unsigned long value, __zp($40) char *buffer, char radix)
ultoa: {
    .label digit_value = $2b
    .label buffer = $40
    .label digit = $42
    .label value = $25
    // [2121] phi from ultoa to ultoa::@1 [phi:ultoa->ultoa::@1]
    // [2121] phi ultoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:ultoa->ultoa::@1#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2121] phi ultoa::started#2 = 0 [phi:ultoa->ultoa::@1#1] -- vbuxx=vbuc1 
    ldx #0
    // [2121] phi ultoa::value#2 = ultoa::value#1 [phi:ultoa->ultoa::@1#2] -- register_copy 
    // [2121] phi ultoa::digit#2 = 0 [phi:ultoa->ultoa::@1#3] -- vbuz1=vbuc1 
    txa
    sta.z digit
    // ultoa::@1
  __b1:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2122] if(ultoa::digit#2<8-1) goto ultoa::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z digit
    cmp #8-1
    bcc __b2
    // ultoa::@3
    // *buffer++ = DIGITS[(char)value]
    // [2123] ultoa::$11 = (char)ultoa::value#2 -- vbuaa=_byte_vduz1 
    lda.z value
    // [2124] *ultoa::buffer#11 = DIGITS[ultoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuaa 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2125] ultoa::buffer#3 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2126] *ultoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    // ultoa::@return
    // }
    // [2127] return 
    rts
    // ultoa::@2
  __b2:
    // unsigned long digit_value = digit_values[digit]
    // [2128] ultoa::$10 = ultoa::digit#2 << 2 -- vbuaa=vbuz1_rol_2 
    lda.z digit
    asl
    asl
    // [2129] ultoa::digit_value#0 = RADIX_HEXADECIMAL_VALUES_LONG[ultoa::$10] -- vduz1=pduc1_derefidx_vbuaa 
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
    // [2130] if(0!=ultoa::started#2) goto ultoa::@5 -- 0_neq_vbuxx_then_la1 
    cpx #0
    bne __b5
    // ultoa::@7
    // [2131] if(ultoa::value#2>=ultoa::digit_value#0) goto ultoa::@5 -- vduz1_ge_vduz2_then_la1 
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
    // [2132] phi from ultoa::@7 to ultoa::@4 [phi:ultoa::@7->ultoa::@4]
    // [2132] phi ultoa::buffer#14 = ultoa::buffer#11 [phi:ultoa::@7->ultoa::@4#0] -- register_copy 
    // [2132] phi ultoa::started#4 = ultoa::started#2 [phi:ultoa::@7->ultoa::@4#1] -- register_copy 
    // [2132] phi ultoa::value#6 = ultoa::value#2 [phi:ultoa::@7->ultoa::@4#2] -- register_copy 
    // ultoa::@4
  __b4:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2133] ultoa::digit#1 = ++ ultoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [2121] phi from ultoa::@4 to ultoa::@1 [phi:ultoa::@4->ultoa::@1]
    // [2121] phi ultoa::buffer#11 = ultoa::buffer#14 [phi:ultoa::@4->ultoa::@1#0] -- register_copy 
    // [2121] phi ultoa::started#2 = ultoa::started#4 [phi:ultoa::@4->ultoa::@1#1] -- register_copy 
    // [2121] phi ultoa::value#2 = ultoa::value#6 [phi:ultoa::@4->ultoa::@1#2] -- register_copy 
    // [2121] phi ultoa::digit#2 = ultoa::digit#1 [phi:ultoa::@4->ultoa::@1#3] -- register_copy 
    jmp __b1
    // ultoa::@5
  __b5:
    // ultoa_append(buffer++, value, digit_value)
    // [2134] ultoa_append::buffer#0 = ultoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z ultoa_append.buffer
    lda.z buffer+1
    sta.z ultoa_append.buffer+1
    // [2135] ultoa_append::value#0 = ultoa::value#2
    // [2136] ultoa_append::sub#0 = ultoa::digit_value#0
    // [2137] call ultoa_append
    // [2161] phi from ultoa::@5 to ultoa_append [phi:ultoa::@5->ultoa_append]
    jsr ultoa_append
    // ultoa_append(buffer++, value, digit_value)
    // [2138] ultoa_append::return#0 = ultoa_append::value#2
    // ultoa::@6
    // value = ultoa_append(buffer++, value, digit_value)
    // [2139] ultoa::value#0 = ultoa_append::return#0
    // value = ultoa_append(buffer++, value, digit_value);
    // [2140] ultoa::buffer#4 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2132] phi from ultoa::@6 to ultoa::@4 [phi:ultoa::@6->ultoa::@4]
    // [2132] phi ultoa::buffer#14 = ultoa::buffer#4 [phi:ultoa::@6->ultoa::@4#0] -- register_copy 
    // [2132] phi ultoa::started#4 = 1 [phi:ultoa::@6->ultoa::@4#1] -- vbuxx=vbuc1 
    ldx #1
    // [2132] phi ultoa::value#6 = ultoa::value#0 [phi:ultoa::@6->ultoa::@4#2] -- register_copy 
    jmp __b4
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
// void memcpy8_vram_vram(__zp($35) char dbank_vram, __zp($33) unsigned int doffset_vram, __register(Y) char sbank_vram, __zp($30) unsigned int soffset_vram, __register(X) char num8)
memcpy8_vram_vram: {
    .label dbank_vram = $35
    .label doffset_vram = $33
    .label soffset_vram = $30
    .label num8 = $22
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2141] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [2142] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbuaa=_byte0_vwuz1 
    lda.z soffset_vram
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [2143] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [2144] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbuaa=_byte1_vwuz1 
    lda.z soffset_vram+1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [2145] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [2146] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbuaa=vbuyy_bor_vbuc1 
    tya
    ora #VERA_INC_1
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [2147] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [2148] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [2149] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbuaa=_byte0_vwuz1 
    lda.z doffset_vram
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [2150] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [2151] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbuaa=_byte1_vwuz1 
    lda.z doffset_vram+1
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [2152] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [2153] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbuaa=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z dbank_vram
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [2154] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_H
    // [2155] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [2155] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [2156] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbuxx=_dec_vbuz1 
    ldx.z num8
    dex
    // [2157] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbuz1_then_la1 
    lda.z num8
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [2158] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [2159] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [2160] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbuz1=vbuxx 
    stx.z num8
    jmp __b1
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
// __zp($25) unsigned long ultoa_append(__zp($49) char *buffer, __zp($25) unsigned long value, __zp($2b) unsigned long sub)
ultoa_append: {
    .label buffer = $49
    .label value = $25
    .label sub = $2b
    .label return = $25
    // [2162] phi from ultoa_append to ultoa_append::@1 [phi:ultoa_append->ultoa_append::@1]
    // [2162] phi ultoa_append::digit#2 = 0 [phi:ultoa_append->ultoa_append::@1#0] -- vbuxx=vbuc1 
    ldx #0
    // [2162] phi ultoa_append::value#2 = ultoa_append::value#0 [phi:ultoa_append->ultoa_append::@1#1] -- register_copy 
    // ultoa_append::@1
  __b1:
    // while (value >= sub)
    // [2163] if(ultoa_append::value#2>=ultoa_append::sub#0) goto ultoa_append::@2 -- vduz1_ge_vduz2_then_la1 
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
    // [2164] *ultoa_append::buffer#0 = DIGITS[ultoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuxx 
    lda DIGITS,x
    ldy #0
    sta (buffer),y
    // ultoa_append::@return
    // }
    // [2165] return 
    rts
    // ultoa_append::@2
  __b2:
    // digit++;
    // [2166] ultoa_append::digit#1 = ++ ultoa_append::digit#2 -- vbuxx=_inc_vbuxx 
    inx
    // value -= sub
    // [2167] ultoa_append::value#1 = ultoa_append::value#2 - ultoa_append::sub#0 -- vduz1=vduz1_minus_vduz2 
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
    // [2162] phi from ultoa_append::@2 to ultoa_append::@1 [phi:ultoa_append::@2->ultoa_append::@1]
    // [2162] phi ultoa_append::digit#2 = ultoa_append::digit#1 [phi:ultoa_append::@2->ultoa_append::@1#0] -- register_copy 
    // [2162] phi ultoa_append::value#2 = ultoa_append::value#1 [phi:ultoa_append::@2->ultoa_append::@1#1] -- register_copy 
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
  // Values of hexadecimal digits
  RADIX_HEXADECIMAL_VALUES_LONG: .dword $10000000, $1000000, $100000, $10000, $1000, $100, $10
  info_text: .fill $50, 0
  status_text: .word __3, __4, __5, __6, __7, __8, __9, __10, __11, __12, __13
  status_color: .byte BLACK, GREY, WHITE, CYAN, PURPLE, CYAN, PURPLE, PURPLE, GREEN, YELLOW, RED
  status_rom: .byte 0
  .fill 7, 0
  display_into_briefing_text: .word __14, __15, info_text4, __17, __18, __19, __20, __21, __22, __23, __24, info_text4, __26, __27
  display_into_colors_text: .word __28, __29, info_text4, __31, __32, __33, __34, __35, __36, __37, __38, __39, __40, __41, info_text4, __43
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
  s2: .text " "
  .byte 0
  s1: .text "/"
  .byte 0
  s5: .text " -> RAM:"
  .byte 0
  s3: .text ":"
  .byte 0
  s4: .text " ..."
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
  smc_file_size: .word 0
