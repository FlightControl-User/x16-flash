  // File Comments
/**
 * @mainpage cx16-rom-flash.c
 * @author Sven Van de Velde (https://www.commanderx16.com/forum/index.php?/profile/1249-svenvandevelde/)
 * @author Wavicle from CX16 forums (https://www.commanderx16.com/forum/index.php?/profile/1585-wavicle/)
 * @brief COMMANDER X16 ROM FLASH UTILITY
 *
 *
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
.file [name="FLASH-CX16-SMC.prg", type="prg", segments="Program"]
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
  // The different device IDs that can be returned from the manufacturer ID read sequence.
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
  .label __errno = $ec
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
// void snputc(__zp($e6) char c)
snputc: {
    .const OFFSET_STACK_C = 0
    .label c = $e6
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
    .label conio_x16_init__5 = $da
    // screenlayer1()
    // [20] call screenlayer1
    jsr screenlayer1
    // [21] phi from conio_x16_init to conio_x16_init::@1 [phi:conio_x16_init->conio_x16_init::@1]
    // conio_x16_init::@1
    // textcolor(CONIO_TEXTCOLOR_DEFAULT)
    // [22] call textcolor
    // [539] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [539] phi textcolor::color#18 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [23] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [24] call bgcolor
    // [544] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [544] phi bgcolor::color#14 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbuz1=vbuc1 
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
    // [557] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [557] phi gotoxy::y#30 = gotoxy::y#2 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [557] phi gotoxy::x#30 = gotoxy::x#2 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
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
    .label cputc__2 = $ab
    .label cputc__3 = $ac
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
    .const intro_briefing_count = $10
    .const intro_colors_count = $10
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 0
    .const bank_set_brom2_bank = 0
    .const bank_set_brom3_bank = 0
    .const bank_push_set_bram1_bank = 1
    .const bank_set_brom4_bank = 4
    .const bank_set_brom5_bank = 0
    .label main__172 = $d8
    .label main__173 = $e3
    .label main__177 = $65
    .label check_smc1_main__0 = $37
    .label check_smc2_main__0 = $de
    .label check_cx16_rom1_check_rom1_main__0 = $e2
    .label check_smc3_main__0 = $e1
    .label check_rom1_main__0 = $66
    .label check_smc5_main__0 = $e0
    .label check_roms_all1_check_rom1_main__0 = $bc
    .label check_smc6_main__0 = $6e
    .label check_smc7_main__0 = $df
    .label check_vera2_main__0 = $2f
    .label check_roms1_check_rom1_main__0 = $e9
    .label check_smc8_main__0 = $bf
    .label check_smc1_return = $37
    .label check_smc2_return = $de
    .label check_cx16_rom1_check_rom1_return = $e2
    .label check_smc3_return = $e1
    .label check_rom1_return = $66
    .label check_smc5_return = $e0
    .label check_roms_all1_check_rom1_return = $bc
    .label check_smc6_return = $6e
    .label rom_differences = $30
    .label check_smc7_return = $df
    .label check_vera2_return = $2f
    .label check_roms1_check_rom1_return = $e9
    .label check_smc8_return = $bf
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
    // main::@55
    // cx16_k_screen_set_charset(3, (char *)0)
    // [74] main::cx16_k_screen_set_charset1_charset = 3 -- vbum1=vbuc1 
    lda #3
    sta cx16_k_screen_set_charset1_charset
    // [75] main::cx16_k_screen_set_charset1_offset = (char *) 0 -- pbum1=pbuc1 
    lda #<0
    sta cx16_k_screen_set_charset1_offset
    sta cx16_k_screen_set_charset1_offset+1
    // main::cx16_k_screen_set_charset1
    // asm
    // asm { ldacharset ldx<offset ldy>offset jsrCX16_SCREEN_SET_CHARSET  }
    lda cx16_k_screen_set_charset1_charset
    ldx.z <cx16_k_screen_set_charset1_offset
    ldy.z >cx16_k_screen_set_charset1_offset
    jsr CX16_SCREEN_SET_CHARSET
    // [77] phi from main::cx16_k_screen_set_charset1 to main::@56 [phi:main::cx16_k_screen_set_charset1->main::@56]
    // main::@56
    // frame_init()
    // [78] call frame_init
    // [578] phi from main::@56 to frame_init [phi:main::@56->frame_init]
    jsr frame_init
    // [79] phi from main::@56 to main::@78 [phi:main::@56->main::@78]
    // main::@78
    // frame_draw()
    // [80] call frame_draw
    // [598] phi from main::@78 to frame_draw [phi:main::@78->frame_draw]
    jsr frame_draw
    // [81] phi from main::@78 to main::@79 [phi:main::@78->main::@79]
    // main::@79
    // print_title("Commander X16 Flash Utility!")
    // [82] call print_title
    // [639] phi from main::@79 to print_title [phi:main::@79->print_title]
    jsr print_title
    // [83] phi from main::@79 to main::print_info_title1 [phi:main::@79->main::print_info_title1]
    // main::print_info_title1
    // cputsxy(INFO_X-2, INFO_Y-2, "# Chip Status    Type   File  / Total Information")
    // [84] call cputsxy
    // [644] phi from main::print_info_title1 to cputsxy [phi:main::print_info_title1->cputsxy]
    // [644] phi cputsxy::s#4 = main::s [phi:main::print_info_title1->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z cputsxy.s
    lda #>s
    sta.z cputsxy.s+1
    // [644] phi cputsxy::y#4 = $11-2 [phi:main::print_info_title1->cputsxy#1] -- vbuz1=vbuc1 
    lda #$11-2
    sta.z cputsxy.y
    // [644] phi cputsxy::x#4 = 4-2 [phi:main::print_info_title1->cputsxy#2] -- vbuz1=vbuc1 
    lda #4-2
    sta.z cputsxy.x
    jsr cputsxy
    // [85] phi from main::print_info_title1 to main::@80 [phi:main::print_info_title1->main::@80]
    // main::@80
    // cputsxy(INFO_X-2, INFO_Y-1, "- ---- --------- ------ ----- / ----- --------------------")
    // [86] call cputsxy
    // [644] phi from main::@80 to cputsxy [phi:main::@80->cputsxy]
    // [644] phi cputsxy::s#4 = main::s1 [phi:main::@80->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s1
    sta.z cputsxy.s
    lda #>s1
    sta.z cputsxy.s+1
    // [644] phi cputsxy::y#4 = $11-1 [phi:main::@80->cputsxy#1] -- vbuz1=vbuc1 
    lda #$11-1
    sta.z cputsxy.y
    // [644] phi cputsxy::x#4 = 4-2 [phi:main::@80->cputsxy#2] -- vbuz1=vbuc1 
    lda #4-2
    sta.z cputsxy.x
    jsr cputsxy
    // [87] phi from main::@80 to main::@57 [phi:main::@80->main::@57]
    // main::@57
    // progress_clear()
    // [88] call progress_clear
    // [651] phi from main::@57 to progress_clear [phi:main::@57->progress_clear]
    jsr progress_clear
    // [89] phi from main::@57 to main::@81 [phi:main::@57->main::@81]
    // main::@81
    // info_progress("Detecting SMC, VERA and ROM chipsets ...")
    // [90] call info_progress
  // info_print(0, "The SMC chip on the X16 board controls the power on/off, keyboard and mouse pheripherals.");
  // info_print(1, "It is essential that the SMC chip gets updated together with the latest ROM on the X16 board.");
  // info_print(2, "On the X16 board, near the SMC chip are two jumpers");
    // [666] phi from main::@81 to info_progress [phi:main::@81->info_progress]
    // [666] phi info_progress::info_text#14 = main::info_text [phi:main::@81->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_progress.info_text
    lda #>info_text
    sta.z info_progress.info_text+1
    jsr info_progress
    // main::SEI1
    // asm
    // asm { sei  }
    sei
    // [92] phi from main::SEI1 to main::@58 [phi:main::SEI1->main::@58]
    // main::@58
    // smc_detect()
    // [93] call smc_detect
    jsr smc_detect
    // [94] smc_detect::return#2 = smc_detect::return#0
    // main::@82
    // smc_bootloader = smc_detect()
    // [95] smc_bootloader#0 = smc_detect::return#2 -- vwum1=vwuz2 
    lda.z smc_detect.return
    sta smc_bootloader
    lda.z smc_detect.return+1
    sta smc_bootloader+1
    // chip_smc()
    // [96] call chip_smc
    // [691] phi from main::@82 to chip_smc [phi:main::@82->chip_smc]
    jsr chip_smc
    // main::@83
    // if(smc_bootloader == 0x0100)
    // [97] if(smc_bootloader#0==$100) goto main::@1 -- vwum1_eq_vwuc1_then_la1 
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
    // [98] if(smc_bootloader#0==$200) goto main::@11 -- vwum1_eq_vwuc1_then_la1 
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
    // [99] if(smc_bootloader#0>=2+1) goto main::@12 -- vwum1_ge_vbuc1_then_la1 
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
    // [100] phi from main::@4 to main::@5 [phi:main::@4->main::@5]
    // main::@5
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [101] call snprintf_init
    jsr snprintf_init
    // [102] phi from main::@5 to main::@88 [phi:main::@5->main::@88]
    // main::@88
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [103] call printf_str
    // [700] phi from main::@88 to printf_str [phi:main::@88->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:main::@88->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = main::s2 [phi:main::@88->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main::@89
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [104] printf_uint::uvalue#14 = smc_bootloader#0 -- vwuz1=vwum2 
    lda smc_bootloader
    sta.z printf_uint.uvalue
    lda smc_bootloader+1
    sta.z printf_uint.uvalue+1
    // [105] call printf_uint
    // [709] phi from main::@89 to printf_uint [phi:main::@89->printf_uint]
    // [709] phi printf_uint::format_zero_padding#16 = 1 [phi:main::@89->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [709] phi printf_uint::format_min_length#16 = 2 [phi:main::@89->printf_uint#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uint.format_min_length
    // [709] phi printf_uint::putc#16 = &snputc [phi:main::@89->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [709] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:main::@89->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [709] phi printf_uint::uvalue#16 = printf_uint::uvalue#14 [phi:main::@89->printf_uint#4] -- register_copy 
    jsr printf_uint
    // main::@90
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [106] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [107] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_smc(STATUS_DETECTED, info_text)
    // [109] call info_smc
    // [720] phi from main::@90 to info_smc [phi:main::@90->info_smc]
    // [720] phi info_smc::info_text#12 = info_text [phi:main::@90->info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_smc.info_text
    lda #>@info_text
    sta.z info_smc.info_text+1
    // [720] phi smc_file_size#12 = 0 [phi:main::@90->info_smc#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size_2
    sta smc_file_size_2+1
    // [720] phi info_smc::info_status#12 = STATUS_DETECTED [phi:main::@90->info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_DETECTED
    sta.z info_smc.info_status
    jsr info_smc
    // main::CLI1
  CLI1:
    // asm
    // asm { cli  }
    cli
    // [111] phi from main::CLI1 to main::@59 [phi:main::CLI1->main::@59]
    // main::@59
    // chip_vera()
    // [112] call chip_vera
  // Detecting VERA FPGA.
    // [750] phi from main::@59 to chip_vera [phi:main::@59->chip_vera]
    jsr chip_vera
    // [113] phi from main::@59 to main::@91 [phi:main::@59->main::@91]
    // main::@91
    // info_vera(STATUS_DETECTED, "VERA installed, OK")
    // [114] call info_vera
    // [755] phi from main::@91 to info_vera [phi:main::@91->info_vera]
    // [755] phi info_vera::info_text#10 = main::info_text3 [phi:main::@91->info_vera#0] -- pbum1=pbuc1 
    lda #<info_text3
    sta info_vera.info_text
    lda #>info_text3
    sta info_vera.info_text+1
    // [755] phi info_vera::info_status#2 = STATUS_DETECTED [phi:main::@91->info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_DETECTED
    sta.z info_vera.info_status
    jsr info_vera
    // main::SEI2
    // asm
    // asm { sei  }
    sei
    // [116] phi from main::SEI2 to main::@60 [phi:main::SEI2->main::@60]
    // main::@60
    // rom_detect()
    // [117] call rom_detect
  // Detecting ROM chips
    // [781] phi from main::@60 to rom_detect [phi:main::@60->rom_detect]
    jsr rom_detect
    // [118] phi from main::@60 to main::@92 [phi:main::@60->main::@92]
    // main::@92
    // chip_rom()
    // [119] call chip_rom
    // [831] phi from main::@92 to chip_rom [phi:main::@92->chip_rom]
    jsr chip_rom
    // [120] phi from main::@92 to main::@13 [phi:main::@92->main::@13]
    // [120] phi main::rom_chip#2 = 0 [phi:main::@92->main::@13#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // main::@13
  __b13:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [121] if(main::rom_chip#2<8) goto main::@14 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcs !__b14+
    jmp __b14
  !__b14:
    // main::CLI2
    // asm
    // asm { cli  }
    cli
    // [123] phi from main::CLI2 to main::@18 [phi:main::CLI2->main::@18]
    // [123] phi main::intro_line#2 = 0 [phi:main::CLI2->main::@18#0] -- vbum1=vbuc1 
    lda #0
    sta intro_line
    // main::@18
  __b18:
    // for(unsigned char intro_line=0; intro_line<intro_briefing_count; intro_line++)
    // [124] if(main::intro_line#2<main::intro_briefing_count) goto main::@19 -- vbum1_lt_vbuc1_then_la1 
    lda intro_line
    cmp #intro_briefing_count
    bcs !__b19+
    jmp __b19
  !__b19:
    // [125] phi from main::@18 to main::@20 [phi:main::@18->main::@20]
    // main::@20
    // wait_key("Please read carefully the below, and press [SPACE] ...", " ")
    // [126] call wait_key
    // [850] phi from main::@20 to wait_key [phi:main::@20->wait_key]
    // [850] phi wait_key::filter#14 = s1 [phi:main::@20->wait_key#0] -- pbuz1=pbuc1 
    lda #<@s1
    sta.z wait_key.filter
    lda #>@s1
    sta.z wait_key.filter+1
    // [850] phi wait_key::info_text#4 = main::info_text6 [phi:main::@20->wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text6
    sta.z wait_key.info_text
    lda #>info_text6
    sta.z wait_key.info_text+1
    jsr wait_key
    // [127] phi from main::@20 to main::@94 [phi:main::@20->main::@94]
    // main::@94
    // progress_clear()
    // [128] call progress_clear
    // [651] phi from main::@94 to progress_clear [phi:main::@94->progress_clear]
    jsr progress_clear
    // [129] phi from main::@94 to main::@21 [phi:main::@94->main::@21]
    // [129] phi main::intro_line1#2 = 0 [phi:main::@94->main::@21#0] -- vbum1=vbuc1 
    lda #0
    sta intro_line1
    // main::@21
  __b21:
    // for(unsigned char intro_line=0; intro_line<intro_colors_count; intro_line++)
    // [130] if(main::intro_line1#2<main::intro_colors_count) goto main::@22 -- vbum1_lt_vbuc1_then_la1 
    lda intro_line1
    cmp #intro_colors_count
    bcs !__b22+
    jmp __b22
  !__b22:
    // [131] phi from main::@21 to main::@23 [phi:main::@21->main::@23]
    // [131] phi main::intro_status#2 = 0 [phi:main::@21->main::@23#0] -- vbum1=vbuc1 
    lda #0
    sta intro_status
    // main::@23
  __b23:
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [132] if(main::intro_status#2<$b) goto main::@24 -- vbum1_lt_vbuc1_then_la1 
    lda intro_status
    cmp #$b
    bcs !__b24+
    jmp __b24
  !__b24:
    // [133] phi from main::@23 to main::@25 [phi:main::@23->main::@25]
    // main::@25
    // wait_key("If understood, press [SPACE] to start the update ...", " ")
    // [134] call wait_key
    // [850] phi from main::@25 to wait_key [phi:main::@25->wait_key]
    // [850] phi wait_key::filter#14 = s1 [phi:main::@25->wait_key#0] -- pbuz1=pbuc1 
    lda #<@s1
    sta.z wait_key.filter
    lda #>@s1
    sta.z wait_key.filter+1
    // [850] phi wait_key::info_text#4 = main::info_text7 [phi:main::@25->wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z wait_key.info_text
    lda #>info_text7
    sta.z wait_key.info_text+1
    jsr wait_key
    // [135] phi from main::@25 to main::@97 [phi:main::@25->main::@97]
    // main::@97
    // progress_clear()
    // [136] call progress_clear
    // [651] phi from main::@97 to progress_clear [phi:main::@97->progress_clear]
    jsr progress_clear
    // main::SEI3
    // asm
    // asm { sei  }
    sei
    // main::check_smc1
    // status_smc == status
    // [138] main::check_smc1_$0 = status_smc#0 == STATUS_DETECTED -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_DETECTED
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_smc1_main__0
    // return (unsigned char)(status_smc == status);
    // [139] main::check_smc1_return#0 = (char)main::check_smc1_$0
    // main::@61
    // if(check_smc(STATUS_DETECTED))
    // [140] if(0==main::check_smc1_return#0) goto main::CLI3 -- 0_eq_vbuz1_then_la1 
    lda.z check_smc1_return
    bne !__b4+
    jmp __b4
  !__b4:
    // [141] phi from main::@61 to main::@26 [phi:main::@61->main::@26]
    // main::@26
    // smc_read(8, 512)
    // [142] call smc_read
    // [874] phi from main::@26 to smc_read [phi:main::@26->smc_read]
    // [874] phi __errno#35 = 0 [phi:main::@26->smc_read#0] -- vwsz1=vwsc1 
    lda #<0
    sta.z __errno
    sta.z __errno+1
    jsr smc_read
    // smc_read(8, 512)
    // [143] smc_read::return#2 = smc_read::return#0
    // main::@98
    // smc_file_size = smc_read(8, 512)
    // [144] smc_file_size#0 = smc_read::return#2 -- vwum1=vwum2 
    lda smc_read.return
    sta smc_file_size
    lda smc_read.return+1
    sta smc_file_size+1
    // if (!smc_file_size)
    // [145] if(0==smc_file_size#0) goto main::@29 -- 0_eq_vwum1_then_la1 
    // In case no file was found, set the status to error and skip to the next, else, mention the amount of bytes read.
    lda smc_file_size
    ora smc_file_size+1
    bne !__b29+
    jmp __b29
  !__b29:
    // main::@27
    // if(smc_file_size > 0x1E00)
    // [146] if(smc_file_size#0>$1e00) goto main::@30 -- vwum1_gt_vwuc1_then_la1 
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
    // [147] phi from main::@27 to main::@28 [phi:main::@27->main::@28]
    // main::@28
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [148] call snprintf_init
    jsr snprintf_init
    // [149] phi from main::@28 to main::@99 [phi:main::@28->main::@99]
    // main::@99
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [150] call printf_str
    // [700] phi from main::@99 to printf_str [phi:main::@99->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:main::@99->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = main::s2 [phi:main::@99->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main::@100
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [151] printf_uint::uvalue#15 = smc_bootloader#0 -- vwuz1=vwum2 
    lda smc_bootloader
    sta.z printf_uint.uvalue
    lda smc_bootloader+1
    sta.z printf_uint.uvalue+1
    // [152] call printf_uint
    // [709] phi from main::@100 to printf_uint [phi:main::@100->printf_uint]
    // [709] phi printf_uint::format_zero_padding#16 = 1 [phi:main::@100->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [709] phi printf_uint::format_min_length#16 = 2 [phi:main::@100->printf_uint#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uint.format_min_length
    // [709] phi printf_uint::putc#16 = &snputc [phi:main::@100->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [709] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:main::@100->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [709] phi printf_uint::uvalue#16 = printf_uint::uvalue#15 [phi:main::@100->printf_uint#4] -- register_copy 
    jsr printf_uint
    // main::@101
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [153] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [154] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [156] smc_file_size#342 = smc_file_size#0 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // info_smc(STATUS_FLASH, info_text)
    // [157] call info_smc
    // [720] phi from main::@101 to info_smc [phi:main::@101->info_smc]
    // [720] phi info_smc::info_text#12 = info_text [phi:main::@101->info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_smc.info_text
    lda #>@info_text
    sta.z info_smc.info_text+1
    // [720] phi smc_file_size#12 = smc_file_size#342 [phi:main::@101->info_smc#1] -- register_copy 
    // [720] phi info_smc::info_status#12 = STATUS_FLASH [phi:main::@101->info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASH
    sta.z info_smc.info_status
    jsr info_smc
    // [158] phi from main::@101 main::@29 main::@30 to main::CLI3 [phi:main::@101/main::@29/main::@30->main::CLI3]
    // [158] phi smc_file_size#189 = smc_file_size#0 [phi:main::@101/main::@29/main::@30->main::CLI3#0] -- register_copy 
    // [158] phi __errno#243 = __errno#18 [phi:main::@101/main::@29/main::@30->main::CLI3#1] -- register_copy 
    jmp CLI3
    // [158] phi from main::@61 to main::CLI3 [phi:main::@61->main::CLI3]
  __b4:
    // [158] phi smc_file_size#189 = 0 [phi:main::@61->main::CLI3#0] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size
    sta smc_file_size+1
    // [158] phi __errno#243 = 0 [phi:main::@61->main::CLI3#1] -- vwsz1=vwsc1 
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
    // [161] phi from main::SEI4 to main::@31 [phi:main::SEI4->main::@31]
    // [161] phi __errno#111 = __errno#243 [phi:main::SEI4->main::@31#0] -- register_copy 
    // [161] phi main::rom_chip1#10 = 0 [phi:main::SEI4->main::@31#1] -- vbum1=vbuc1 
    lda #0
    sta rom_chip1
  // We loop all the possible ROM chip slots on the board and on the extension card,
  // and we check the file contents.
  // Any error identified gets reported and this chip will not be flashed.
  // In case of ROM0.BIN in error, no flashing will be done!
    // main::@31
  __b31:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [162] if(main::rom_chip1#10<8) goto main::bank_set_brom2 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip1
    cmp #8
    bcs !bank_set_brom2+
    jmp bank_set_brom2
  !bank_set_brom2:
    // main::bank_set_brom3
    // BROM = bank
    // [163] BROM = main::bank_set_brom3_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom3_bank
    sta.z BROM
    // main::CLI4
    // asm
    // asm { cli  }
    cli
    // main::check_smc2
    // status_smc == status
    // [165] main::check_smc2_$0 = status_smc#0 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_smc2_main__0
    // return (unsigned char)(status_smc == status);
    // [166] main::check_smc2_return#0 = (char)main::check_smc2_$0
    // [167] phi from main::check_smc2 to main::check_cx16_rom1 [phi:main::check_smc2->main::check_cx16_rom1]
    // main::check_cx16_rom1
    // main::check_cx16_rom1_check_rom1
    // status_rom[rom_chip] == status
    // [168] main::check_cx16_rom1_check_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_cx16_rom1_check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [169] main::check_cx16_rom1_check_rom1_return#0 = (char)main::check_cx16_rom1_check_rom1_$0
    // main::@63
    // if(!check_smc(STATUS_FLASH) ||!check_cx16_rom(STATUS_FLASH))
    // [170] if(0==main::check_smc2_return#0) goto main::@38 -- 0_eq_vbuz1_then_la1 
    lda.z check_smc2_return
    bne !__b38+
    jmp __b38
  !__b38:
    // main::@162
    // [171] if(0==main::check_cx16_rom1_check_rom1_return#0) goto main::@38 -- 0_eq_vbuz1_then_la1 
    lda.z check_cx16_rom1_check_rom1_return
    bne !__b38+
    jmp __b38
  !__b38:
    // main::check_smc3
  check_smc3:
    // status_smc == status
    // [172] main::check_smc3_$0 = status_smc#0 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_smc3_main__0
    // return (unsigned char)(status_smc == status);
    // [173] main::check_smc3_return#0 = (char)main::check_smc3_$0
    // [174] phi from main::check_smc3 to main::check_cx16_rom2 [phi:main::check_smc3->main::check_cx16_rom2]
    // main::check_cx16_rom2
    // main::check_cx16_rom2_check_rom1
    // status_rom[rom_chip] == status
    // [175] main::check_cx16_rom2_check_rom1_$0 = *status_rom == STATUS_FLASH -- vbom1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_cx16_rom2_check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [176] main::check_cx16_rom2_check_rom1_return#0 = (char)main::check_cx16_rom2_check_rom1_$0
    // [177] phi from main::check_cx16_rom2_check_rom1 to main::check_card_roms1 [phi:main::check_cx16_rom2_check_rom1->main::check_card_roms1]
    // main::check_card_roms1
    // [178] phi from main::check_card_roms1 to main::check_card_roms1_@1 [phi:main::check_card_roms1->main::check_card_roms1_@1]
    // [178] phi main::check_card_roms1_rom_chip#2 = 1 [phi:main::check_card_roms1->main::check_card_roms1_@1#0] -- vbum1=vbuc1 
    lda #1
    sta check_card_roms1_rom_chip
    // main::check_card_roms1_@1
  check_card_roms1___b1:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [179] if(main::check_card_roms1_rom_chip#2<8) goto main::check_card_roms1_check_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda check_card_roms1_rom_chip
    cmp #8
    bcs !check_card_roms1_check_rom1+
    jmp check_card_roms1_check_rom1
  !check_card_roms1_check_rom1:
    // [180] phi from main::check_card_roms1_@1 to main::check_card_roms1_@return [phi:main::check_card_roms1_@1->main::check_card_roms1_@return]
    // [180] phi main::check_card_roms1_return#2 = STATUS_NONE [phi:main::check_card_roms1_@1->main::check_card_roms1_@return#0] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta check_card_roms1_return
    // main::check_card_roms1_@return
    // main::@66
  __b66:
    // if(check_smc(STATUS_FLASH) && check_cx16_rom(STATUS_FLASH) || check_card_roms(STATUS_FLASH))
    // [181] if(0==main::check_smc3_return#0) goto main::@163 -- 0_eq_vbuz1_then_la1 
    lda.z check_smc3_return
    beq __b163
    // main::@164
    // [182] if(0!=main::check_cx16_rom2_check_rom1_return#0) goto main::@6 -- 0_neq_vbum1_then_la1 
    lda check_cx16_rom2_check_rom1_return
    beq !__b6+
    jmp __b6
  !__b6:
    // main::@163
  __b163:
    // [183] if(0!=main::check_card_roms1_return#2) goto main::@6 -- 0_neq_vbum1_then_la1 
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
    // [185] main::check_smc4_$0 = status_smc#0 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_smc4_main__0
    // return (unsigned char)(status_smc == status);
    // [186] main::check_smc4_return#0 = (char)main::check_smc4_$0
    // main::@67
    // if (check_smc(STATUS_FLASH))
    // [187] if(0==main::check_smc4_return#0) goto main::@2 -- 0_eq_vbum1_then_la1 
    lda check_smc4_return
    bne !__b2+
    jmp __b2
  !__b2:
    // [188] phi from main::@67 to main::@8 [phi:main::@67->main::@8]
    // main::@8
    // smc_read(8, 512)
    // [189] call smc_read
    // [874] phi from main::@8 to smc_read [phi:main::@8->smc_read]
    // [874] phi __errno#35 = __errno#111 [phi:main::@8->smc_read#0] -- register_copy 
    jsr smc_read
    // smc_read(8, 512)
    // [190] smc_read::return#3 = smc_read::return#0
    // main::@132
    // smc_file_size = smc_read(8, 512)
    // [191] smc_file_size#1 = smc_read::return#3 -- vwum1=vwum2 
    lda smc_read.return
    sta smc_file_size_1
    lda smc_read.return+1
    sta smc_file_size_1+1
    // if(smc_file_size)
    // [192] if(0==smc_file_size#1) goto main::@2 -- 0_eq_vwum1_then_la1 
    lda smc_file_size_1
    ora smc_file_size_1+1
    beq __b2
    // [193] phi from main::@132 to main::@9 [phi:main::@132->main::@9]
    // main::@9
    // info_line("Press both POWER/RESET buttons on the CX16 board!")
    // [194] call info_line
  // Flash the SMC chip.
    // [931] phi from main::@9 to info_line [phi:main::@9->info_line]
    // [931] phi info_line::info_text#17 = main::info_text18 [phi:main::@9->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text18
    sta.z info_line.info_text
    lda #>info_text18
    sta.z info_line.info_text+1
    jsr info_line
    // main::@133
    // [195] smc_file_size#344 = smc_file_size#1 -- vwum1=vwum2 
    lda smc_file_size_1
    sta smc_file_size_2
    lda smc_file_size_1+1
    sta smc_file_size_2+1
    // info_smc(STATUS_FLASHING, "Press POWER/RESET!")
    // [196] call info_smc
    // [720] phi from main::@133 to info_smc [phi:main::@133->info_smc]
    // [720] phi info_smc::info_text#12 = main::info_text19 [phi:main::@133->info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text19
    sta.z info_smc.info_text
    lda #>info_text19
    sta.z info_smc.info_text+1
    // [720] phi smc_file_size#12 = smc_file_size#344 [phi:main::@133->info_smc#1] -- register_copy 
    // [720] phi info_smc::info_status#12 = STATUS_FLASHING [phi:main::@133->info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHING
    sta.z info_smc.info_status
    jsr info_smc
    // main::@134
    // unsigned long flashed_bytes = flash_smc(PROGRESS_X, PROGRESS_Y, PROGRESS_W, smc_file_size, 8, 512, (ram_ptr_t)RAM_BASE)
    // [197] flash_smc::smc_bytes_total#0 = smc_file_size#1 -- vwuz1=vwum2 
    lda smc_file_size_1
    sta.z flash_smc.smc_bytes_total
    lda smc_file_size_1+1
    sta.z flash_smc.smc_bytes_total+1
    // [198] call flash_smc
    // [945] phi from main::@134 to flash_smc [phi:main::@134->flash_smc]
    jsr flash_smc
    // unsigned long flashed_bytes = flash_smc(PROGRESS_X, PROGRESS_Y, PROGRESS_W, smc_file_size, 8, 512, (ram_ptr_t)RAM_BASE)
    // [199] flash_smc::return#5 = flash_smc::return#1
    // main::@135
    // [200] main::flashed_bytes#0 = flash_smc::return#5 -- vdum1=vwuz2 
    lda.z flash_smc.return
    sta flashed_bytes
    lda.z flash_smc.return+1
    sta flashed_bytes+1
    lda #0
    sta flashed_bytes+2
    sta flashed_bytes+3
    // if(flashed_bytes)
    // [201] if(0!=main::flashed_bytes#0) goto main::@42 -- 0_neq_vdum1_then_la1 
    lda flashed_bytes
    ora flashed_bytes+1
    ora flashed_bytes+2
    ora flashed_bytes+3
    beq !__b42+
    jmp __b42
  !__b42:
    // main::@10
    // [202] smc_file_size#341 = smc_file_size#1 -- vwum1=vwum2 
    lda smc_file_size_1
    sta smc_file_size_2
    lda smc_file_size_1+1
    sta smc_file_size_2+1
    // info_smc(STATUS_ERROR, "SMC not updated!")
    // [203] call info_smc
    // [720] phi from main::@10 to info_smc [phi:main::@10->info_smc]
    // [720] phi info_smc::info_text#12 = main::info_text21 [phi:main::@10->info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text21
    sta.z info_smc.info_text
    lda #>info_text21
    sta.z info_smc.info_text+1
    // [720] phi smc_file_size#12 = smc_file_size#341 [phi:main::@10->info_smc#1] -- register_copy 
    // [720] phi info_smc::info_status#12 = STATUS_ERROR [phi:main::@10->info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z info_smc.info_status
    jsr info_smc
    // [204] phi from main::@10 main::@132 main::@42 main::@67 to main::@2 [phi:main::@10/main::@132/main::@42/main::@67->main::@2]
    // [204] phi __errno#368 = __errno#18 [phi:main::@10/main::@132/main::@42/main::@67->main::@2#0] -- register_copy 
    // main::@2
  __b2:
    // [205] phi from main::@2 to main::@43 [phi:main::@2->main::@43]
    // [205] phi __errno#113 = __errno#368 [phi:main::@2->main::@43#0] -- register_copy 
    // [205] phi main::rom_chip3#10 = 7 [phi:main::@2->main::@43#1] -- vbum1=vbuc1 
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
    // [206] if(main::rom_chip3#10!=$ff) goto main::check_rom1 -- vbum1_neq_vbuc1_then_la1 
    lda #$ff
    cmp rom_chip3
    beq !check_rom1+
    jmp check_rom1
  !check_rom1:
    // main::bank_set_brom4
    // BROM = bank
    // [207] BROM = main::bank_set_brom4_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom4_bank
    sta.z BROM
    // main::CLI5
    // asm
    // asm { cli  }
    cli
    // [209] phi from main::CLI5 to main::@69 [phi:main::CLI5->main::@69]
    // main::@69
    // info_progress("Update finished ...")
    // [210] call info_progress
    // [666] phi from main::@69 to info_progress [phi:main::@69->info_progress]
    // [666] phi info_progress::info_text#14 = main::info_text22 [phi:main::@69->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text22
    sta.z info_progress.info_text
    lda #>info_text22
    sta.z info_progress.info_text+1
    jsr info_progress
    // main::check_smc5
    // status_smc == status
    // [211] main::check_smc5_$0 = status_smc#0 == STATUS_SKIP -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_smc5_main__0
    // return (unsigned char)(status_smc == status);
    // [212] main::check_smc5_return#0 = (char)main::check_smc5_$0
    // main::check_vera1
    // status_vera == status
    // [213] main::check_vera1_$0 = status_vera#0 == STATUS_SKIP -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    sta check_vera1_main__0
    // return (unsigned char)(status_vera == status);
    // [214] main::check_vera1_return#0 = (char)main::check_vera1_$0
    // [215] phi from main::check_vera1 to main::check_roms_all1 [phi:main::check_vera1->main::check_roms_all1]
    // main::check_roms_all1
    // [216] phi from main::check_roms_all1 to main::check_roms_all1_@1 [phi:main::check_roms_all1->main::check_roms_all1_@1]
    // [216] phi main::check_roms_all1_rom_chip#2 = 0 [phi:main::check_roms_all1->main::check_roms_all1_@1#0] -- vbum1=vbuc1 
    lda #0
    sta check_roms_all1_rom_chip
    // main::check_roms_all1_@1
  check_roms_all1___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [217] if(main::check_roms_all1_rom_chip#2<8) goto main::check_roms_all1_check_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda check_roms_all1_rom_chip
    cmp #8
    bcs !check_roms_all1_check_rom1+
    jmp check_roms_all1_check_rom1
  !check_roms_all1_check_rom1:
    // [218] phi from main::check_roms_all1_@1 to main::check_roms_all1_@return [phi:main::check_roms_all1_@1->main::check_roms_all1_@return]
    // [218] phi main::check_roms_all1_return#2 = 1 [phi:main::check_roms_all1_@1->main::check_roms_all1_@return#0] -- vbum1=vbuc1 
    lda #1
    sta check_roms_all1_return
    // main::check_roms_all1_@return
    // main::@70
  __b70:
    // if(check_smc(STATUS_SKIP) && check_vera(STATUS_SKIP) && check_roms_all(STATUS_SKIP))
    // [219] if(0==main::check_smc5_return#0) goto main::check_smc7 -- 0_eq_vbuz1_then_la1 
    lda.z check_smc5_return
    beq check_smc7
    // main::@166
    // [220] if(0==main::check_vera1_return#0) goto main::check_smc7 -- 0_eq_vbum1_then_la1 
    lda check_vera1_return
    beq check_smc7
    // main::@165
    // [221] if(0!=main::check_roms_all1_return#2) goto main::vera_display_set_border_color1 -- 0_neq_vbum1_then_la1 
    lda check_roms_all1_return
    beq !vera_display_set_border_color1+
    jmp vera_display_set_border_color1
  !vera_display_set_border_color1:
    // main::check_smc7
  check_smc7:
    // status_smc == status
    // [222] main::check_smc7_$0 = status_smc#0 == STATUS_ERROR -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_smc7_main__0
    // return (unsigned char)(status_smc == status);
    // [223] main::check_smc7_return#0 = (char)main::check_smc7_$0
    // main::check_vera2
    // status_vera == status
    // [224] main::check_vera2_$0 = status_vera#0 == STATUS_ERROR -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_vera2_main__0
    // return (unsigned char)(status_vera == status);
    // [225] main::check_vera2_return#0 = (char)main::check_vera2_$0
    // [226] phi from main::check_vera2 to main::check_roms1 [phi:main::check_vera2->main::check_roms1]
    // main::check_roms1
    // [227] phi from main::check_roms1 to main::check_roms1_@1 [phi:main::check_roms1->main::check_roms1_@1]
    // [227] phi main::check_roms1_rom_chip#2 = 0 [phi:main::check_roms1->main::check_roms1_@1#0] -- vbum1=vbuc1 
    lda #0
    sta check_roms1_rom_chip
    // main::check_roms1_@1
  check_roms1___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [228] if(main::check_roms1_rom_chip#2<8) goto main::check_roms1_check_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda check_roms1_rom_chip
    cmp #8
    bcs !check_roms1_check_rom1+
    jmp check_roms1_check_rom1
  !check_roms1_check_rom1:
    // [229] phi from main::check_roms1_@1 to main::check_roms1_@return [phi:main::check_roms1_@1->main::check_roms1_@return]
    // [229] phi main::check_roms1_return#2 = STATUS_NONE [phi:main::check_roms1_@1->main::check_roms1_@return#0] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta check_roms1_return
    // main::check_roms1_@return
    // main::@74
  __b74:
    // if(check_smc(STATUS_ERROR) || check_vera(STATUS_ERROR) || check_roms(STATUS_ERROR))
    // [230] if(0!=main::check_smc7_return#0) goto main::vera_display_set_border_color2 -- 0_neq_vbuz1_then_la1 
    lda.z check_smc7_return
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::@170
    // [231] if(0!=main::check_vera2_return#0) goto main::vera_display_set_border_color2 -- 0_neq_vbuz1_then_la1 
    lda.z check_vera2_return
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::@169
    // [232] if(0!=main::check_roms1_return#2) goto main::vera_display_set_border_color2 -- 0_neq_vbum1_then_la1 
    lda check_roms1_return
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::check_smc8
    // status_smc == status
    // [233] main::check_smc8_$0 = status_smc#0 == STATUS_ISSUE -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_smc8_main__0
    // return (unsigned char)(status_smc == status);
    // [234] main::check_smc8_return#0 = (char)main::check_smc8_$0
    // main::check_vera3
    // status_vera == status
    // [235] main::check_vera3_$0 = status_vera#0 == STATUS_ISSUE -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta check_vera3_main__0
    // return (unsigned char)(status_vera == status);
    // [236] main::check_vera3_return#0 = (char)main::check_vera3_$0
    // [237] phi from main::check_vera3 to main::check_roms2 [phi:main::check_vera3->main::check_roms2]
    // main::check_roms2
    // [238] phi from main::check_roms2 to main::check_roms2_@1 [phi:main::check_roms2->main::check_roms2_@1]
    // [238] phi main::check_roms2_rom_chip#2 = 0 [phi:main::check_roms2->main::check_roms2_@1#0] -- vbum1=vbuc1 
    lda #0
    sta check_roms2_rom_chip
    // main::check_roms2_@1
  check_roms2___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [239] if(main::check_roms2_rom_chip#2<8) goto main::check_roms2_check_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda check_roms2_rom_chip
    cmp #8
    bcs !check_roms2_check_rom1+
    jmp check_roms2_check_rom1
  !check_roms2_check_rom1:
    // [240] phi from main::check_roms2_@1 to main::check_roms2_@return [phi:main::check_roms2_@1->main::check_roms2_@return]
    // [240] phi main::check_roms2_return#2 = STATUS_NONE [phi:main::check_roms2_@1->main::check_roms2_@return#0] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta check_roms2_return
    // main::check_roms2_@return
    // main::@76
  __b76:
    // if(check_smc(STATUS_ISSUE) || check_vera(STATUS_ISSUE) || check_roms(STATUS_ISSUE))
    // [241] if(0!=main::check_smc8_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbuz1_then_la1 
    lda.z check_smc8_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::@172
    // [242] if(0!=main::check_vera3_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbum1_then_la1 
    lda check_vera3_return
    bne vera_display_set_border_color3
    // main::@171
    // [243] if(0!=main::check_roms2_return#2) goto main::vera_display_set_border_color3 -- 0_neq_vbum1_then_la1 
    lda check_roms2_return
    bne vera_display_set_border_color3
    // main::vera_display_set_border_color4
    // *VERA_CTRL &= ~VERA_DCSEL
    // [244] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [245] *VERA_DC_BORDER = GREEN -- _deref_pbuc1=vbuc2 
    lda #GREEN
    sta VERA_DC_BORDER
    // [246] phi from main::@73 main::@77 main::vera_display_set_border_color4 to main::@52 [phi:main::@73/main::@77/main::vera_display_set_border_color4->main::@52]
  __b5:
    // [246] phi main::flash_reset#2 = $f0 [phi:main::@73/main::@77/main::vera_display_set_border_color4->main::@52#0] -- vbum1=vbuc1 
    lda #$f0
    sta flash_reset
    // main::@52
  __b52:
    // for(unsigned char flash_reset=240; flash_reset>0; flash_reset--)
    // [247] if(main::flash_reset#2>0) goto main::@53 -- vbum1_gt_0_then_la1 
    lda flash_reset
    bne __b53
    // [248] phi from main::@52 to main::@54 [phi:main::@52->main::@54]
    // main::@54
    // system_reset()
    // [249] call system_reset
    // [1112] phi from main::@54 to system_reset [phi:main::@54->system_reset]
    jsr system_reset
    // main::@return
    // }
    // [250] return 
    rts
    // [251] phi from main::@52 to main::@53 [phi:main::@52->main::@53]
    // main::@53
  __b53:
    // wait_moment()
    // [252] call wait_moment
    // [1117] phi from main::@53 to wait_moment [phi:main::@53->wait_moment]
    jsr wait_moment
    // [253] phi from main::@53 to main::@156 [phi:main::@53->main::@156]
    // main::@156
    // sprintf(info_text, "Resetting your CX16 in %u ...", flash_reset)
    // [254] call snprintf_init
    jsr snprintf_init
    // [255] phi from main::@156 to main::@157 [phi:main::@156->main::@157]
    // main::@157
    // sprintf(info_text, "Resetting your CX16 in %u ...", flash_reset)
    // [256] call printf_str
    // [700] phi from main::@157 to printf_str [phi:main::@157->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:main::@157->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = main::s18 [phi:main::@157->printf_str#1] -- pbuz1=pbuc1 
    lda #<s18
    sta.z printf_str.s
    lda #>s18
    sta.z printf_str.s+1
    jsr printf_str
    // main::@158
    // sprintf(info_text, "Resetting your CX16 in %u ...", flash_reset)
    // [257] printf_uchar::uvalue#9 = main::flash_reset#2 -- vbuz1=vbum2 
    lda flash_reset
    sta.z printf_uchar.uvalue
    // [258] call printf_uchar
    // [1122] phi from main::@158 to printf_uchar [phi:main::@158->printf_uchar]
    // [1122] phi printf_uchar::format_zero_padding#10 = 0 [phi:main::@158->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1122] phi printf_uchar::format_min_length#10 = 0 [phi:main::@158->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1122] phi printf_uchar::putc#10 = &snputc [phi:main::@158->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1122] phi printf_uchar::format_radix#10 = DECIMAL [phi:main::@158->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1122] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#9 [phi:main::@158->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [259] phi from main::@158 to main::@159 [phi:main::@158->main::@159]
    // main::@159
    // sprintf(info_text, "Resetting your CX16 in %u ...", flash_reset)
    // [260] call printf_str
    // [700] phi from main::@159 to printf_str [phi:main::@159->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:main::@159->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = s7 [phi:main::@159->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s7
    sta.z printf_str.s
    lda #>@s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@160
    // sprintf(info_text, "Resetting your CX16 in %u ...", flash_reset)
    // [261] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [262] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [264] call info_line
    // [931] phi from main::@160 to info_line [phi:main::@160->info_line]
    // [931] phi info_line::info_text#17 = info_text [phi:main::@160->info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_line.info_text
    lda #>@info_text
    sta.z info_line.info_text+1
    jsr info_line
    // main::@161
    // for(unsigned char flash_reset=240; flash_reset>0; flash_reset--)
    // [265] main::flash_reset#1 = -- main::flash_reset#2 -- vbum1=_dec_vbum1 
    dec flash_reset
    // [246] phi from main::@161 to main::@52 [phi:main::@161->main::@52]
    // [246] phi main::flash_reset#2 = main::flash_reset#1 [phi:main::@161->main::@52#0] -- register_copy 
    jmp __b52
    // main::vera_display_set_border_color3
  vera_display_set_border_color3:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [266] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [267] *VERA_DC_BORDER = YELLOW -- _deref_pbuc1=vbuc2 
    lda #YELLOW
    sta VERA_DC_BORDER
    // [268] phi from main::vera_display_set_border_color3 to main::@77 [phi:main::vera_display_set_border_color3->main::@77]
    // main::@77
    // info_progress("Update issues, your CX16 is not updated!")
    // [269] call info_progress
    // [666] phi from main::@77 to info_progress [phi:main::@77->info_progress]
    // [666] phi info_progress::info_text#14 = main::info_text31 [phi:main::@77->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text31
    sta.z info_progress.info_text
    lda #>info_text31
    sta.z info_progress.info_text+1
    jsr info_progress
    jmp __b5
    // main::check_roms2_check_rom1
  check_roms2_check_rom1:
    // status_rom[rom_chip] == status
    // [270] main::check_roms2_check_rom1_$0 = status_rom[main::check_roms2_rom_chip#2] == STATUS_ISSUE -- vbom1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_ISSUE
    ldy check_roms2_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta check_roms2_check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [271] main::check_roms2_check_rom1_return#0 = (char)main::check_roms2_check_rom1_$0
    // main::check_roms2_@11
    // if(check_rom(rom_chip, status) == status)
    // [272] if(main::check_roms2_check_rom1_return#0!=STATUS_ISSUE) goto main::check_roms2_@4 -- vbum1_neq_vbuc1_then_la1 
    lda #STATUS_ISSUE
    cmp check_roms2_check_rom1_return
    bne check_roms2___b4
    // [240] phi from main::check_roms2_@11 to main::check_roms2_@return [phi:main::check_roms2_@11->main::check_roms2_@return]
    // [240] phi main::check_roms2_return#2 = STATUS_ISSUE [phi:main::check_roms2_@11->main::check_roms2_@return#0] -- vbum1=vbuc1 
    sta check_roms2_return
    jmp __b76
    // main::check_roms2_@4
  check_roms2___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [273] main::check_roms2_rom_chip#1 = ++ main::check_roms2_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_roms2_rom_chip
    // [238] phi from main::check_roms2_@4 to main::check_roms2_@1 [phi:main::check_roms2_@4->main::check_roms2_@1]
    // [238] phi main::check_roms2_rom_chip#2 = main::check_roms2_rom_chip#1 [phi:main::check_roms2_@4->main::check_roms2_@1#0] -- register_copy 
    jmp check_roms2___b1
    // main::vera_display_set_border_color2
  vera_display_set_border_color2:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [274] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [275] *VERA_DC_BORDER = RED -- _deref_pbuc1=vbuc2 
    lda #RED
    sta VERA_DC_BORDER
    // [276] phi from main::vera_display_set_border_color2 to main::@75 [phi:main::vera_display_set_border_color2->main::@75]
    // main::@75
    // info_progress("Update Failure! Your CX16 may be bricked!")
    // [277] call info_progress
    // [666] phi from main::@75 to info_progress [phi:main::@75->info_progress]
    // [666] phi info_progress::info_text#14 = main::info_text29 [phi:main::@75->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text29
    sta.z info_progress.info_text
    lda #>info_text29
    sta.z info_progress.info_text+1
    jsr info_progress
    // [278] phi from main::@75 to main::@155 [phi:main::@75->main::@155]
    // main::@155
    // info_line("Take a foto of this screen. And shut down power ...")
    // [279] call info_line
    // [931] phi from main::@155 to info_line [phi:main::@155->info_line]
    // [931] phi info_line::info_text#17 = main::info_text30 [phi:main::@155->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text30
    sta.z info_line.info_text
    lda #>info_text30
    sta.z info_line.info_text+1
    jsr info_line
    // [280] phi from main::@155 main::@51 to main::@51 [phi:main::@155/main::@51->main::@51]
    // main::@51
  __b51:
    jmp __b51
    // main::check_roms1_check_rom1
  check_roms1_check_rom1:
    // status_rom[rom_chip] == status
    // [281] main::check_roms1_check_rom1_$0 = status_rom[main::check_roms1_rom_chip#2] == STATUS_ERROR -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_ERROR
    ldy check_roms1_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_roms1_check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [282] main::check_roms1_check_rom1_return#0 = (char)main::check_roms1_check_rom1_$0
    // main::check_roms1_@11
    // if(check_rom(rom_chip, status) == status)
    // [283] if(main::check_roms1_check_rom1_return#0!=STATUS_ERROR) goto main::check_roms1_@4 -- vbuz1_neq_vbuc1_then_la1 
    lda #STATUS_ERROR
    cmp.z check_roms1_check_rom1_return
    bne check_roms1___b4
    // [229] phi from main::check_roms1_@11 to main::check_roms1_@return [phi:main::check_roms1_@11->main::check_roms1_@return]
    // [229] phi main::check_roms1_return#2 = STATUS_ERROR [phi:main::check_roms1_@11->main::check_roms1_@return#0] -- vbum1=vbuc1 
    sta check_roms1_return
    jmp __b74
    // main::check_roms1_@4
  check_roms1___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [284] main::check_roms1_rom_chip#1 = ++ main::check_roms1_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_roms1_rom_chip
    // [227] phi from main::check_roms1_@4 to main::check_roms1_@1 [phi:main::check_roms1_@4->main::check_roms1_@1]
    // [227] phi main::check_roms1_rom_chip#2 = main::check_roms1_rom_chip#1 [phi:main::check_roms1_@4->main::check_roms1_@1#0] -- register_copy 
    jmp check_roms1___b1
    // main::vera_display_set_border_color1
  vera_display_set_border_color1:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [285] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [286] *VERA_DC_BORDER = BLACK -- _deref_pbuc1=vbuc2 
    lda #BLACK
    sta VERA_DC_BORDER
    // [287] phi from main::vera_display_set_border_color1 to main::@73 [phi:main::vera_display_set_border_color1->main::@73]
    // main::@73
    // info_progress("The update has been cancelled!")
    // [288] call info_progress
    // [666] phi from main::@73 to info_progress [phi:main::@73->info_progress]
    // [666] phi info_progress::info_text#14 = main::info_text28 [phi:main::@73->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text28
    sta.z info_progress.info_text
    lda #>info_text28
    sta.z info_progress.info_text+1
    jsr info_progress
    jmp __b5
    // main::check_roms_all1_check_rom1
  check_roms_all1_check_rom1:
    // status_rom[rom_chip] == status
    // [289] main::check_roms_all1_check_rom1_$0 = status_rom[main::check_roms_all1_rom_chip#2] == STATUS_SKIP -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_SKIP
    ldy check_roms_all1_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_roms_all1_check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [290] main::check_roms_all1_check_rom1_return#0 = (char)main::check_roms_all1_check_rom1_$0
    // main::check_roms_all1_@11
    // if(check_rom(rom_chip, status) != status)
    // [291] if(main::check_roms_all1_check_rom1_return#0==STATUS_SKIP) goto main::check_roms_all1_@4 -- vbuz1_eq_vbuc1_then_la1 
    lda #STATUS_SKIP
    cmp.z check_roms_all1_check_rom1_return
    beq check_roms_all1___b4
    // [218] phi from main::check_roms_all1_@11 to main::check_roms_all1_@return [phi:main::check_roms_all1_@11->main::check_roms_all1_@return]
    // [218] phi main::check_roms_all1_return#2 = 0 [phi:main::check_roms_all1_@11->main::check_roms_all1_@return#0] -- vbum1=vbuc1 
    lda #0
    sta check_roms_all1_return
    jmp __b70
    // main::check_roms_all1_@4
  check_roms_all1___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [292] main::check_roms_all1_rom_chip#1 = ++ main::check_roms_all1_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_roms_all1_rom_chip
    // [216] phi from main::check_roms_all1_@4 to main::check_roms_all1_@1 [phi:main::check_roms_all1_@4->main::check_roms_all1_@1]
    // [216] phi main::check_roms_all1_rom_chip#2 = main::check_roms_all1_rom_chip#1 [phi:main::check_roms_all1_@4->main::check_roms_all1_@1#0] -- register_copy 
    jmp check_roms_all1___b1
    // main::check_rom1
  check_rom1:
    // status_rom[rom_chip] == status
    // [293] main::check_rom1_$0 = status_rom[main::rom_chip3#10] == STATUS_FLASH -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_FLASH
    ldy rom_chip3
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [294] main::check_rom1_return#0 = (char)main::check_rom1_$0
    // main::@68
    // if(check_rom(rom_chip, STATUS_FLASH))
    // [295] if(0==main::check_rom1_return#0) goto main::@44 -- 0_eq_vbuz1_then_la1 
    lda.z check_rom1_return
    beq __b44
    // main::check_smc6
    // status_smc == status
    // [296] main::check_smc6_$0 = status_smc#0 == STATUS_FLASHED -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASHED
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_smc6_main__0
    // return (unsigned char)(status_smc == status);
    // [297] main::check_smc6_return#0 = (char)main::check_smc6_$0
    // main::@71
    // if((rom_chip == 0 && check_smc(STATUS_FLASHED)) || (rom_chip != 0))
    // [298] if(main::rom_chip3#10!=0) goto main::@167 -- vbum1_neq_0_then_la1 
    // IMPORTANT! We only flash the CX16 ROM chip if the SMC got flashed succesfully!
    lda rom_chip3
    bne __b167
    // main::@168
    // [299] if(0!=main::check_smc6_return#0) goto main::bank_set_brom5 -- 0_neq_vbuz1_then_la1 
    lda.z check_smc6_return
    bne bank_set_brom5
    // main::@167
  __b167:
    // [300] if(main::rom_chip3#10!=0) goto main::bank_set_brom5 -- vbum1_neq_0_then_la1 
    lda rom_chip3
    bne bank_set_brom5
    // main::@50
    // info_rom(rom_chip, STATUS_ISSUE, "Update SMC failed!")
    // [301] info_rom::rom_chip#10 = main::rom_chip3#10 -- vbum1=vbum2 
    sta info_rom.rom_chip
    // [302] call info_rom
    // [1133] phi from main::@50 to info_rom [phi:main::@50->info_rom]
    // [1133] phi info_rom::info_text#16 = main::info_text23 [phi:main::@50->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text23
    sta.z info_rom.info_text
    lda #>info_text23
    sta.z info_rom.info_text+1
    // [1133] phi info_rom::rom_chip#16 = info_rom::rom_chip#10 [phi:main::@50->info_rom#1] -- register_copy 
    // [1133] phi info_rom::info_status#16 = STATUS_ISSUE [phi:main::@50->info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta info_rom.info_status
    jsr info_rom
    // [303] phi from main::@143 main::@154 main::@45 main::@49 main::@50 main::@68 to main::@44 [phi:main::@143/main::@154/main::@45/main::@49/main::@50/main::@68->main::@44]
    // [303] phi __errno#369 = __errno#18 [phi:main::@143/main::@154/main::@45/main::@49/main::@50/main::@68->main::@44#0] -- register_copy 
    // main::@44
  __b44:
    // for(unsigned char rom_chip = 7; rom_chip != 255; rom_chip--)
    // [304] main::rom_chip3#1 = -- main::rom_chip3#10 -- vbum1=_dec_vbum1 
    dec rom_chip3
    // [205] phi from main::@44 to main::@43 [phi:main::@44->main::@43]
    // [205] phi __errno#113 = __errno#369 [phi:main::@44->main::@43#0] -- register_copy 
    // [205] phi main::rom_chip3#10 = main::rom_chip3#1 [phi:main::@44->main::@43#1] -- register_copy 
    jmp __b43
    // main::bank_set_brom5
  bank_set_brom5:
    // BROM = bank
    // [305] BROM = main::bank_set_brom5_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom5_bank
    sta.z BROM
    // [306] phi from main::bank_set_brom5 to main::@72 [phi:main::bank_set_brom5->main::@72]
    // main::@72
    // progress_clear()
    // [307] call progress_clear
    // [651] phi from main::@72 to progress_clear [phi:main::@72->progress_clear]
    jsr progress_clear
    // main::@136
    // unsigned char rom_bank = rom_chip * 32
    // [308] main::rom_bank1#0 = main::rom_chip3#10 << 5 -- vbum1=vbum2_rol_5 
    lda rom_chip3
    asl
    asl
    asl
    asl
    asl
    sta rom_bank1
    // unsigned char* file = rom_file(rom_chip)
    // [309] rom_file::rom_chip#1 = main::rom_chip3#10 -- vbum1=vbum2 
    lda rom_chip3
    sta rom_file.rom_chip
    // [310] call rom_file
    // [1178] phi from main::@136 to rom_file [phi:main::@136->rom_file]
    // [1178] phi rom_file::rom_chip#2 = rom_file::rom_chip#1 [phi:main::@136->rom_file#0] -- register_copy 
    jsr rom_file
    // unsigned char* file = rom_file(rom_chip)
    // [311] rom_file::return#5 = rom_file::return#2
    // main::@137
    // [312] main::file1#0 = rom_file::return#5
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [313] call snprintf_init
    jsr snprintf_init
    // [314] phi from main::@137 to main::@138 [phi:main::@137->main::@138]
    // main::@138
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [315] call printf_str
    // [700] phi from main::@138 to printf_str [phi:main::@138->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:main::@138->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = s14 [phi:main::@138->printf_str#1] -- pbuz1=pbuc1 
    lda #<s14
    sta.z printf_str.s
    lda #>s14
    sta.z printf_str.s+1
    jsr printf_str
    // main::@139
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [316] printf_string::str#17 = main::file1#0 -- pbuz1=pbum2 
    lda file1
    sta.z printf_string.str
    lda file1+1
    sta.z printf_string.str+1
    // [317] call printf_string
    // [1184] phi from main::@139 to printf_string [phi:main::@139->printf_string]
    // [1184] phi printf_string::putc#18 = &snputc [phi:main::@139->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1184] phi printf_string::str#18 = printf_string::str#17 [phi:main::@139->printf_string#1] -- register_copy 
    // [1184] phi printf_string::format_justify_left#18 = 0 [phi:main::@139->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1184] phi printf_string::format_min_length#18 = 0 [phi:main::@139->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [318] phi from main::@139 to main::@140 [phi:main::@139->main::@140]
    // main::@140
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [319] call printf_str
    // [700] phi from main::@140 to printf_str [phi:main::@140->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:main::@140->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = main::s7 [phi:main::@140->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@141
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [320] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [321] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_progress(info_text)
    // [323] call info_progress
    // [666] phi from main::@141 to info_progress [phi:main::@141->info_progress]
    // [666] phi info_progress::info_text#14 = info_text [phi:main::@141->info_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_progress.info_text
    lda #>@info_text
    sta.z info_progress.info_text+1
    jsr info_progress
    // main::@142
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_READING, rom_bank, rom_sizes[rom_chip])
    // [324] main::$179 = main::rom_chip3#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip3
    asl
    asl
    sta main__179
    // [325] rom_read::file#1 = main::file1#0 -- pbuz1=pbum2 
    lda file1
    sta.z rom_read.file
    lda file1+1
    sta.z rom_read.file+1
    // [326] rom_read::brom_bank_start#2 = main::rom_bank1#0 -- vbuz1=vbum2 
    lda rom_bank1
    sta.z rom_read.brom_bank_start
    // [327] rom_read::rom_size#1 = rom_sizes[main::$179] -- vduz1=pduc1_derefidx_vbum2 
    ldy main__179
    lda rom_sizes,y
    sta.z rom_read.rom_size
    lda rom_sizes+1,y
    sta.z rom_read.rom_size+1
    lda rom_sizes+2,y
    sta.z rom_read.rom_size+2
    lda rom_sizes+3,y
    sta.z rom_read.rom_size+3
    // [328] call rom_read
    // [1209] phi from main::@142 to rom_read [phi:main::@142->rom_read]
    // [1209] phi rom_read::rom_size#12 = rom_read::rom_size#1 [phi:main::@142->rom_read#0] -- register_copy 
    // [1209] phi __errno#105 = __errno#113 [phi:main::@142->rom_read#1] -- register_copy 
    // [1209] phi rom_read::file#11 = rom_read::file#1 [phi:main::@142->rom_read#2] -- register_copy 
    // [1209] phi rom_read::brom_bank_start#21 = rom_read::brom_bank_start#2 [phi:main::@142->rom_read#3] -- register_copy 
    jsr rom_read
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_READING, rom_bank, rom_sizes[rom_chip])
    // [329] rom_read::return#3 = rom_read::return#0
    // main::@143
    // [330] main::rom_bytes_read1#0 = rom_read::return#3
    // if(rom_bytes_read)
    // [331] if(0==main::rom_bytes_read1#0) goto main::@44 -- 0_eq_vdum1_then_la1 
    lda rom_bytes_read1
    ora rom_bytes_read1+1
    ora rom_bytes_read1+2
    ora rom_bytes_read1+3
    bne !__b44+
    jmp __b44
  !__b44:
    // [332] phi from main::@143 to main::@47 [phi:main::@143->main::@47]
    // main::@47
    // info_progress("Comparing ... (.) same, (*) different.")
    // [333] call info_progress
  // Now we compare the RAM with the actual ROM contents.
    // [666] phi from main::@47 to info_progress [phi:main::@47->info_progress]
    // [666] phi info_progress::info_text#14 = main::info_text24 [phi:main::@47->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text24
    sta.z info_progress.info_text
    lda #>info_text24
    sta.z info_progress.info_text+1
    jsr info_progress
    // main::@144
    // info_rom(rom_chip, STATUS_COMPARING, "")
    // [334] info_rom::rom_chip#11 = main::rom_chip3#10 -- vbum1=vbum2 
    lda rom_chip3
    sta info_rom.rom_chip
    // [335] call info_rom
    // [1133] phi from main::@144 to info_rom [phi:main::@144->info_rom]
    // [1133] phi info_rom::info_text#16 = info_text4 [phi:main::@144->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z info_rom.info_text
    lda #>info_text4
    sta.z info_rom.info_text+1
    // [1133] phi info_rom::rom_chip#16 = info_rom::rom_chip#11 [phi:main::@144->info_rom#1] -- register_copy 
    // [1133] phi info_rom::info_status#16 = STATUS_COMPARING [phi:main::@144->info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_COMPARING
    sta info_rom.info_status
    jsr info_rom
    // main::@145
    // unsigned long rom_differences = rom_verify(
    //                         rom_chip, rom_bank, file_sizes[rom_chip])
    // [336] rom_verify::rom_chip#0 = main::rom_chip3#10 -- vbum1=vbum2 
    lda rom_chip3
    sta rom_verify.rom_chip
    // [337] rom_verify::rom_bank_start#0 = main::rom_bank1#0 -- vbuz1=vbum2 
    lda rom_bank1
    sta.z rom_verify.rom_bank_start
    // [338] rom_verify::file_size#0 = file_sizes[main::$179] -- vdum1=pduc1_derefidx_vbum2 
    ldy main__179
    lda file_sizes,y
    sta rom_verify.file_size
    lda file_sizes+1,y
    sta rom_verify.file_size+1
    lda file_sizes+2,y
    sta rom_verify.file_size+2
    lda file_sizes+3,y
    sta rom_verify.file_size+3
    // [339] call rom_verify
    // Verify the ROM...
    jsr rom_verify
    // [340] rom_verify::return#2 = rom_verify::rom_different_bytes#11
    // main::@146
    // [341] main::rom_differences#0 = rom_verify::return#2 -- vduz1=vduz2 
    lda.z rom_verify.return
    sta.z rom_differences
    lda.z rom_verify.return+1
    sta.z rom_differences+1
    lda.z rom_verify.return+2
    sta.z rom_differences+2
    lda.z rom_verify.return+3
    sta.z rom_differences+3
    // if (!rom_differences)
    // [342] if(0==main::rom_differences#0) goto main::@45 -- 0_eq_vduz1_then_la1 
    lda.z rom_differences
    ora.z rom_differences+1
    ora.z rom_differences+2
    ora.z rom_differences+3
    bne !__b45+
    jmp __b45
  !__b45:
    // [343] phi from main::@146 to main::@48 [phi:main::@146->main::@48]
    // main::@48
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [344] call snprintf_init
    jsr snprintf_init
    // main::@147
    // [345] printf_ulong::uvalue#9 = main::rom_differences#0
    // [346] call printf_ulong
    // [1359] phi from main::@147 to printf_ulong [phi:main::@147->printf_ulong]
    // [1359] phi printf_ulong::format_zero_padding#11 = 1 [phi:main::@147->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1359] phi printf_ulong::format_min_length#11 = 5 [phi:main::@147->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1359] phi printf_ulong::putc#11 = &snputc [phi:main::@147->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1359] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:main::@147->printf_ulong#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1359] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#9 [phi:main::@147->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [347] phi from main::@147 to main::@148 [phi:main::@147->main::@148]
    // main::@148
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [348] call printf_str
    // [700] phi from main::@148 to printf_str [phi:main::@148->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:main::@148->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = main::s16 [phi:main::@148->printf_str#1] -- pbuz1=pbuc1 
    lda #<s16
    sta.z printf_str.s
    lda #>s16
    sta.z printf_str.s+1
    jsr printf_str
    // main::@149
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [349] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [350] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom(rom_chip, STATUS_FLASH, info_text)
    // [352] info_rom::rom_chip#13 = main::rom_chip3#10 -- vbum1=vbum2 
    lda rom_chip3
    sta info_rom.rom_chip
    // [353] call info_rom
    // [1133] phi from main::@149 to info_rom [phi:main::@149->info_rom]
    // [1133] phi info_rom::info_text#16 = info_text [phi:main::@149->info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_rom.info_text
    lda #>@info_text
    sta.z info_rom.info_text+1
    // [1133] phi info_rom::rom_chip#16 = info_rom::rom_chip#13 [phi:main::@149->info_rom#1] -- register_copy 
    // [1133] phi info_rom::info_status#16 = STATUS_FLASH [phi:main::@149->info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta info_rom.info_status
    jsr info_rom
    // main::@150
    // unsigned long rom_flash_errors = rom_flash(
    //                             rom_chip, rom_bank, file_sizes[rom_chip])
    // [354] rom_flash::rom_chip#0 = main::rom_chip3#10 -- vbum1=vbum2 
    lda rom_chip3
    sta rom_flash.rom_chip
    // [355] rom_flash::rom_bank_start#0 = main::rom_bank1#0 -- vbuz1=vbum2 
    lda rom_bank1
    sta.z rom_flash.rom_bank_start
    // [356] rom_flash::file_size#0 = file_sizes[main::$179] -- vdum1=pduc1_derefidx_vbum2 
    ldy main__179
    lda file_sizes,y
    sta rom_flash.file_size
    lda file_sizes+1,y
    sta rom_flash.file_size+1
    lda file_sizes+2,y
    sta rom_flash.file_size+2
    lda file_sizes+3,y
    sta rom_flash.file_size+3
    // [357] call rom_flash
    // [1370] phi from main::@150 to rom_flash [phi:main::@150->rom_flash]
    jsr rom_flash
    // unsigned long rom_flash_errors = rom_flash(
    //                             rom_chip, rom_bank, file_sizes[rom_chip])
    // [358] rom_flash::return#2 = rom_flash::flash_errors#10
    // main::@151
    // [359] main::rom_flash_errors#0 = rom_flash::return#2 -- vdum1=vdum2 
    lda rom_flash.return
    sta rom_flash_errors
    lda rom_flash.return+1
    sta rom_flash_errors+1
    lda rom_flash.return+2
    sta rom_flash_errors+2
    lda rom_flash.return+3
    sta rom_flash_errors+3
    // if(rom_flash_errors)
    // [360] if(0!=main::rom_flash_errors#0) goto main::@46 -- 0_neq_vdum1_then_la1 
    lda rom_flash_errors
    ora rom_flash_errors+1
    ora rom_flash_errors+2
    ora rom_flash_errors+3
    bne __b46
    // main::@49
    // info_rom(rom_chip, STATUS_FLASHED, "OK!")
    // [361] info_rom::rom_chip#15 = main::rom_chip3#10 -- vbum1=vbum2 
    lda rom_chip3
    sta info_rom.rom_chip
    // [362] call info_rom
    // [1133] phi from main::@49 to info_rom [phi:main::@49->info_rom]
    // [1133] phi info_rom::info_text#16 = main::info_text27 [phi:main::@49->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text27
    sta.z info_rom.info_text
    lda #>info_text27
    sta.z info_rom.info_text+1
    // [1133] phi info_rom::rom_chip#16 = info_rom::rom_chip#15 [phi:main::@49->info_rom#1] -- register_copy 
    // [1133] phi info_rom::info_status#16 = STATUS_FLASHED [phi:main::@49->info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHED
    sta info_rom.info_status
    jsr info_rom
    jmp __b44
    // [363] phi from main::@151 to main::@46 [phi:main::@151->main::@46]
    // main::@46
  __b46:
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [364] call snprintf_init
    jsr snprintf_init
    // main::@152
    // [365] printf_ulong::uvalue#10 = main::rom_flash_errors#0 -- vduz1=vdum2 
    lda rom_flash_errors
    sta.z printf_ulong.uvalue
    lda rom_flash_errors+1
    sta.z printf_ulong.uvalue+1
    lda rom_flash_errors+2
    sta.z printf_ulong.uvalue+2
    lda rom_flash_errors+3
    sta.z printf_ulong.uvalue+3
    // [366] call printf_ulong
    // [1359] phi from main::@152 to printf_ulong [phi:main::@152->printf_ulong]
    // [1359] phi printf_ulong::format_zero_padding#11 = 0 [phi:main::@152->printf_ulong#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_ulong.format_zero_padding
    // [1359] phi printf_ulong::format_min_length#11 = 0 [phi:main::@152->printf_ulong#1] -- vbuz1=vbuc1 
    sta.z printf_ulong.format_min_length
    // [1359] phi printf_ulong::putc#11 = &snputc [phi:main::@152->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1359] phi printf_ulong::format_radix#11 = DECIMAL [phi:main::@152->printf_ulong#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_ulong.format_radix
    // [1359] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#10 [phi:main::@152->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [367] phi from main::@152 to main::@153 [phi:main::@152->main::@153]
    // main::@153
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [368] call printf_str
    // [700] phi from main::@153 to printf_str [phi:main::@153->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:main::@153->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = main::s17 [phi:main::@153->printf_str#1] -- pbuz1=pbuc1 
    lda #<s17
    sta.z printf_str.s
    lda #>s17
    sta.z printf_str.s+1
    jsr printf_str
    // main::@154
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [369] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [370] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom(rom_chip, STATUS_ERROR, info_text)
    // [372] info_rom::rom_chip#14 = main::rom_chip3#10 -- vbum1=vbum2 
    lda rom_chip3
    sta info_rom.rom_chip
    // [373] call info_rom
    // [1133] phi from main::@154 to info_rom [phi:main::@154->info_rom]
    // [1133] phi info_rom::info_text#16 = info_text [phi:main::@154->info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_rom.info_text
    lda #>@info_text
    sta.z info_rom.info_text+1
    // [1133] phi info_rom::rom_chip#16 = info_rom::rom_chip#14 [phi:main::@154->info_rom#1] -- register_copy 
    // [1133] phi info_rom::info_status#16 = STATUS_ERROR [phi:main::@154->info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta info_rom.info_status
    jsr info_rom
    jmp __b44
    // main::@45
  __b45:
    // info_rom(rom_chip, STATUS_FLASHED, "No update required")
    // [374] info_rom::rom_chip#12 = main::rom_chip3#10 -- vbum1=vbum2 
    lda rom_chip3
    sta info_rom.rom_chip
    // [375] call info_rom
    // [1133] phi from main::@45 to info_rom [phi:main::@45->info_rom]
    // [1133] phi info_rom::info_text#16 = main::info_text26 [phi:main::@45->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text26
    sta.z info_rom.info_text
    lda #>info_text26
    sta.z info_rom.info_text+1
    // [1133] phi info_rom::rom_chip#16 = info_rom::rom_chip#12 [phi:main::@45->info_rom#1] -- register_copy 
    // [1133] phi info_rom::info_status#16 = STATUS_FLASHED [phi:main::@45->info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHED
    sta info_rom.info_status
    jsr info_rom
    jmp __b44
    // main::@42
  __b42:
    // [376] smc_file_size#347 = smc_file_size#1 -- vwum1=vwum2 
    lda smc_file_size_1
    sta smc_file_size_2
    lda smc_file_size_1+1
    sta smc_file_size_2+1
    // info_smc(STATUS_FLASHED, "")
    // [377] call info_smc
    // [720] phi from main::@42 to info_smc [phi:main::@42->info_smc]
    // [720] phi info_smc::info_text#12 = info_text4 [phi:main::@42->info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z info_smc.info_text
    lda #>info_text4
    sta.z info_smc.info_text+1
    // [720] phi smc_file_size#12 = smc_file_size#347 [phi:main::@42->info_smc#1] -- register_copy 
    // [720] phi info_smc::info_status#12 = STATUS_FLASHED [phi:main::@42->info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHED
    sta.z info_smc.info_status
    jsr info_smc
    jmp __b2
    // [378] phi from main::@163 main::@164 to main::@6 [phi:main::@163/main::@164->main::@6]
    // main::@6
  __b6:
    // info_progress("Chipsets have been detected and update files validated!")
    // [379] call info_progress
    // [666] phi from main::@6 to info_progress [phi:main::@6->info_progress]
    // [666] phi info_progress::info_text#14 = main::info_text12 [phi:main::@6->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text12
    sta.z info_progress.info_text
    lda #>info_text12
    sta.z info_progress.info_text+1
    jsr info_progress
    // [380] phi from main::@6 to main::@127 [phi:main::@6->main::@127]
    // main::@127
    // unsigned char ch = wait_key("Continue with update? [Y/N]", "nyNY")
    // [381] call wait_key
    // [850] phi from main::@127 to wait_key [phi:main::@127->wait_key]
    // [850] phi wait_key::filter#14 = main::filter3 [phi:main::@127->wait_key#0] -- pbuz1=pbuc1 
    lda #<filter3
    sta.z wait_key.filter
    lda #>filter3
    sta.z wait_key.filter+1
    // [850] phi wait_key::info_text#4 = main::info_text13 [phi:main::@127->wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text13
    sta.z wait_key.info_text
    lda #>info_text13
    sta.z wait_key.info_text+1
    jsr wait_key
    // unsigned char ch = wait_key("Continue with update? [Y/N]", "nyNY")
    // [382] wait_key::return#5 = wait_key::ch#4 -- vbum1=vwum2 
    lda wait_key.ch
    sta wait_key.return
    // main::@128
    // [383] main::ch#0 = wait_key::return#5
    // strchr("nN", ch)
    // [384] strchr::c#1 = main::ch#0
    // [385] call strchr
    // [1485] phi from main::@128 to strchr [phi:main::@128->strchr]
    // [1485] phi strchr::c#4 = strchr::c#1 [phi:main::@128->strchr#0] -- register_copy 
    // [1485] phi strchr::str#2 = (const void *)main::$196 [phi:main::@128->strchr#1] -- pvom1=pvoc1 
    lda #<main__196
    sta strchr.str
    lda #>main__196
    sta strchr.str+1
    jsr strchr
    // strchr("nN", ch)
    // [386] strchr::return#4 = strchr::return#2
    // main::@129
    // [387] main::$108 = strchr::return#4
    // if(strchr("nN", ch))
    // [388] if((void *)0==main::$108) goto main::SEI5 -- pvoc1_eq_pvom1_then_la1 
    lda main__108
    cmp #<0
    bne !+
    lda main__108+1
    cmp #>0
    bne !SEI5+
    jmp SEI5
  !SEI5:
  !:
    // main::@7
    // [389] smc_file_size#340 = smc_file_size#189 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // info_smc(STATUS_SKIP, "Cancelled")
    // [390] call info_smc
  // We cancel all updates, the updates are skipped.
    // [720] phi from main::@7 to info_smc [phi:main::@7->info_smc]
    // [720] phi info_smc::info_text#12 = main::info_text14 [phi:main::@7->info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text14
    sta.z info_smc.info_text
    lda #>info_text14
    sta.z info_smc.info_text+1
    // [720] phi smc_file_size#12 = smc_file_size#340 [phi:main::@7->info_smc#1] -- register_copy 
    // [720] phi info_smc::info_status#12 = STATUS_SKIP [phi:main::@7->info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z info_smc.info_status
    jsr info_smc
    // [391] phi from main::@7 to main::@130 [phi:main::@7->main::@130]
    // main::@130
    // info_vera(STATUS_SKIP, "Cancelled")
    // [392] call info_vera
    // [755] phi from main::@130 to info_vera [phi:main::@130->info_vera]
    // [755] phi info_vera::info_text#10 = main::info_text14 [phi:main::@130->info_vera#0] -- pbum1=pbuc1 
    lda #<info_text14
    sta info_vera.info_text
    lda #>info_text14
    sta info_vera.info_text+1
    // [755] phi info_vera::info_status#2 = STATUS_SKIP [phi:main::@130->info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z info_vera.info_status
    jsr info_vera
    // [393] phi from main::@130 to main::@39 [phi:main::@130->main::@39]
    // [393] phi main::rom_chip2#2 = 0 [phi:main::@130->main::@39#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip2
    // main::@39
  __b39:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [394] if(main::rom_chip2#2<8) goto main::@40 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip2
    cmp #8
    bcc __b40
    // [395] phi from main::@39 to main::@41 [phi:main::@39->main::@41]
    // main::@41
    // info_line("You have selected not to cancel the update ... ")
    // [396] call info_line
    // [931] phi from main::@41 to info_line [phi:main::@41->info_line]
    // [931] phi info_line::info_text#17 = main::info_text17 [phi:main::@41->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text17
    sta.z info_line.info_text
    lda #>info_text17
    sta.z info_line.info_text+1
    jsr info_line
    jmp SEI5
    // main::@40
  __b40:
    // info_rom(rom_chip, STATUS_SKIP, "Cancelled")
    // [397] info_rom::rom_chip#9 = main::rom_chip2#2 -- vbum1=vbum2 
    lda rom_chip2
    sta info_rom.rom_chip
    // [398] call info_rom
    // [1133] phi from main::@40 to info_rom [phi:main::@40->info_rom]
    // [1133] phi info_rom::info_text#16 = main::info_text14 [phi:main::@40->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text14
    sta.z info_rom.info_text
    lda #>info_text14
    sta.z info_rom.info_text+1
    // [1133] phi info_rom::rom_chip#16 = info_rom::rom_chip#9 [phi:main::@40->info_rom#1] -- register_copy 
    // [1133] phi info_rom::info_status#16 = STATUS_SKIP [phi:main::@40->info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta info_rom.info_status
    jsr info_rom
    // main::@131
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [399] main::rom_chip2#1 = ++ main::rom_chip2#2 -- vbum1=_inc_vbum1 
    inc rom_chip2
    // [393] phi from main::@131 to main::@39 [phi:main::@131->main::@39]
    // [393] phi main::rom_chip2#2 = main::rom_chip2#1 [phi:main::@131->main::@39#0] -- register_copy 
    jmp __b39
    // main::check_card_roms1_check_rom1
  check_card_roms1_check_rom1:
    // status_rom[rom_chip] == status
    // [400] main::check_card_roms1_check_rom1_$0 = status_rom[main::check_card_roms1_rom_chip#2] == STATUS_FLASH -- vbom1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_FLASH
    ldy check_card_roms1_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta check_card_roms1_check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [401] main::check_card_roms1_check_rom1_return#0 = (char)main::check_card_roms1_check_rom1_$0
    // main::check_card_roms1_@11
    // if(check_rom(rom_chip, status))
    // [402] if(0==main::check_card_roms1_check_rom1_return#0) goto main::check_card_roms1_@4 -- 0_eq_vbum1_then_la1 
    lda check_card_roms1_check_rom1_return
    beq check_card_roms1___b4
    // [180] phi from main::check_card_roms1_@11 to main::check_card_roms1_@return [phi:main::check_card_roms1_@11->main::check_card_roms1_@return]
    // [180] phi main::check_card_roms1_return#2 = STATUS_FLASH [phi:main::check_card_roms1_@11->main::check_card_roms1_@return#0] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta check_card_roms1_return
    jmp __b66
    // main::check_card_roms1_@4
  check_card_roms1___b4:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [403] main::check_card_roms1_rom_chip#1 = ++ main::check_card_roms1_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_card_roms1_rom_chip
    // [178] phi from main::check_card_roms1_@4 to main::check_card_roms1_@1 [phi:main::check_card_roms1_@4->main::check_card_roms1_@1]
    // [178] phi main::check_card_roms1_rom_chip#2 = main::check_card_roms1_rom_chip#1 [phi:main::check_card_roms1_@4->main::check_card_roms1_@1#0] -- register_copy 
    jmp check_card_roms1___b1
    // [404] phi from main::@162 main::@63 to main::@38 [phi:main::@162/main::@63->main::@38]
    // main::@38
  __b38:
    // info_progress("There is an issue with either the SMC or the CX16 main ROM!")
    // [405] call info_progress
    // [666] phi from main::@38 to info_progress [phi:main::@38->info_progress]
    // [666] phi info_progress::info_text#14 = main::info_text10 [phi:main::@38->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text10
    sta.z info_progress.info_text
    lda #>info_text10
    sta.z info_progress.info_text+1
    jsr info_progress
    // [406] phi from main::@38 to main::@124 [phi:main::@38->main::@124]
    // main::@124
    // wait_key("Press [SPACE] to continue [ ]", " ")
    // [407] call wait_key
    // [850] phi from main::@124 to wait_key [phi:main::@124->wait_key]
    // [850] phi wait_key::filter#14 = s1 [phi:main::@124->wait_key#0] -- pbuz1=pbuc1 
    lda #<@s1
    sta.z wait_key.filter
    lda #>@s1
    sta.z wait_key.filter+1
    // [850] phi wait_key::info_text#4 = main::info_text11 [phi:main::@124->wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text11
    sta.z wait_key.info_text
    lda #>info_text11
    sta.z wait_key.info_text+1
    jsr wait_key
    // main::@125
    // [408] smc_file_size#343 = smc_file_size#189 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // info_smc(STATUS_ISSUE, NULL)
    // [409] call info_smc
    // [720] phi from main::@125 to info_smc [phi:main::@125->info_smc]
    // [720] phi info_smc::info_text#12 = 0 [phi:main::@125->info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z info_smc.info_text
    sta.z info_smc.info_text+1
    // [720] phi smc_file_size#12 = smc_file_size#343 [phi:main::@125->info_smc#1] -- register_copy 
    // [720] phi info_smc::info_status#12 = STATUS_ISSUE [phi:main::@125->info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z info_smc.info_status
    jsr info_smc
    // [410] phi from main::@125 to main::@126 [phi:main::@125->main::@126]
    // main::@126
    // info_cx16_rom(STATUS_ISSUE, NULL)
    // [411] call info_cx16_rom
    // [1494] phi from main::@126 to info_cx16_rom [phi:main::@126->info_cx16_rom]
    jsr info_cx16_rom
    jmp check_smc3
    // main::bank_set_brom2
  bank_set_brom2:
    // BROM = bank
    // [412] BROM = main::bank_set_brom2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom2_bank
    sta.z BROM
    // main::@62
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [413] if(rom_device_ids[main::rom_chip1#10]==$55) goto main::@32 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    ldy rom_chip1
    lda rom_device_ids,y
    cmp #$55
    bne !__b32+
    jmp __b32
  !__b32:
    // [414] phi from main::@62 to main::@35 [phi:main::@62->main::@35]
    // main::@35
    // progress_clear()
    // [415] call progress_clear
    // [651] phi from main::@35 to progress_clear [phi:main::@35->progress_clear]
    jsr progress_clear
    // main::@102
    // unsigned char rom_bank = rom_chip * 32
    // [416] main::rom_bank#0 = main::rom_chip1#10 << 5 -- vbum1=vbum2_rol_5 
    lda rom_chip1
    asl
    asl
    asl
    asl
    asl
    sta rom_bank
    // unsigned char* file = rom_file(rom_chip)
    // [417] rom_file::rom_chip#0 = main::rom_chip1#10 -- vbum1=vbum2 
    lda rom_chip1
    sta rom_file.rom_chip
    // [418] call rom_file
    // [1178] phi from main::@102 to rom_file [phi:main::@102->rom_file]
    // [1178] phi rom_file::rom_chip#2 = rom_file::rom_chip#0 [phi:main::@102->rom_file#0] -- register_copy 
    jsr rom_file
    // unsigned char* file = rom_file(rom_chip)
    // [419] rom_file::return#4 = rom_file::return#2
    // main::@103
    // [420] main::file#0 = rom_file::return#4 -- pbum1=pbum2 
    lda rom_file.return
    sta file
    lda rom_file.return+1
    sta file+1
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [421] call snprintf_init
    jsr snprintf_init
    // [422] phi from main::@103 to main::@104 [phi:main::@103->main::@104]
    // main::@104
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [423] call printf_str
    // [700] phi from main::@104 to printf_str [phi:main::@104->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:main::@104->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = main::s6 [phi:main::@104->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // main::@105
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [424] printf_string::str#12 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [425] call printf_string
    // [1184] phi from main::@105 to printf_string [phi:main::@105->printf_string]
    // [1184] phi printf_string::putc#18 = &snputc [phi:main::@105->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1184] phi printf_string::str#18 = printf_string::str#12 [phi:main::@105->printf_string#1] -- register_copy 
    // [1184] phi printf_string::format_justify_left#18 = 0 [phi:main::@105->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1184] phi printf_string::format_min_length#18 = 0 [phi:main::@105->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [426] phi from main::@105 to main::@106 [phi:main::@105->main::@106]
    // main::@106
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [427] call printf_str
    // [700] phi from main::@106 to printf_str [phi:main::@106->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:main::@106->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = main::s7 [phi:main::@106->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@107
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [428] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [429] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_progress(info_text)
    // [431] call info_progress
    // [666] phi from main::@107 to info_progress [phi:main::@107->info_progress]
    // [666] phi info_progress::info_text#14 = info_text [phi:main::@107->info_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_progress.info_text
    lda #>@info_text
    sta.z info_progress.info_text+1
    jsr info_progress
    // main::@108
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_CHECKING, rom_bank, rom_sizes[rom_chip])
    // [432] main::$175 = main::rom_chip1#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip1
    asl
    asl
    sta main__175
    // [433] rom_read::file#0 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z rom_read.file
    lda file+1
    sta.z rom_read.file+1
    // [434] rom_read::brom_bank_start#1 = main::rom_bank#0 -- vbuz1=vbum2 
    lda rom_bank
    sta.z rom_read.brom_bank_start
    // [435] rom_read::rom_size#0 = rom_sizes[main::$175] -- vduz1=pduc1_derefidx_vbum2 
    ldy main__175
    lda rom_sizes,y
    sta.z rom_read.rom_size
    lda rom_sizes+1,y
    sta.z rom_read.rom_size+1
    lda rom_sizes+2,y
    sta.z rom_read.rom_size+2
    lda rom_sizes+3,y
    sta.z rom_read.rom_size+3
    // [436] call rom_read
    // [1209] phi from main::@108 to rom_read [phi:main::@108->rom_read]
    // [1209] phi rom_read::rom_size#12 = rom_read::rom_size#0 [phi:main::@108->rom_read#0] -- register_copy 
    // [1209] phi __errno#105 = __errno#111 [phi:main::@108->rom_read#1] -- register_copy 
    // [1209] phi rom_read::file#11 = rom_read::file#0 [phi:main::@108->rom_read#2] -- register_copy 
    // [1209] phi rom_read::brom_bank_start#21 = rom_read::brom_bank_start#1 [phi:main::@108->rom_read#3] -- register_copy 
    jsr rom_read
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_CHECKING, rom_bank, rom_sizes[rom_chip])
    // [437] rom_read::return#2 = rom_read::return#0
    // main::@109
    // [438] main::rom_bytes_read#0 = rom_read::return#2
    // if (!rom_bytes_read)
    // [439] if(0==main::rom_bytes_read#0) goto main::@33 -- 0_eq_vdum1_then_la1 
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
    // [440] main::rom_file_modulo#0 = main::rom_bytes_read#0 & $4000-1 -- vdum1=vdum2_band_vduc1 
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
    // [441] if(0!=main::rom_file_modulo#0) goto main::@34 -- 0_neq_vdum1_then_la1 
    lda rom_file_modulo
    ora rom_file_modulo+1
    ora rom_file_modulo+2
    ora rom_file_modulo+3
    beq !__b34+
    jmp __b34
  !__b34:
    // main::@37
    // file_sizes[rom_chip] = rom_bytes_read
    // [442] file_sizes[main::$175] = main::rom_bytes_read#0 -- pduc1_derefidx_vbum1=vdum2 
    // We know the file size, so we indicate it in the status panel.
    ldy main__175
    lda rom_bytes_read
    sta file_sizes,y
    lda rom_bytes_read+1
    sta file_sizes+1,y
    lda rom_bytes_read+2
    sta file_sizes+2,y
    lda rom_bytes_read+3
    sta file_sizes+3,y
    // strncpy(rom_github[rom_chip], (char*)RAM_BASE, 6)
    // [443] main::$177 = main::rom_chip1#10 << 1 -- vbuz1=vbum2_rol_1 
    lda rom_chip1
    asl
    sta.z main__177
    // [444] strncpy::dst#2 = rom_github[main::$177] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda rom_github,y
    sta.z strncpy.dst
    lda rom_github+1,y
    sta.z strncpy.dst+1
    // [445] call strncpy
  // Fill the version data ...
    // [1497] phi from main::@37 to strncpy [phi:main::@37->strncpy]
    // [1497] phi strncpy::dst#8 = strncpy::dst#2 [phi:main::@37->strncpy#0] -- register_copy 
    // [1497] phi strncpy::src#6 = (char *)$6000 [phi:main::@37->strncpy#1] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z strncpy.src
    lda #>$6000
    sta.z strncpy.src+1
    // [1497] phi strncpy::n#3 = 6 [phi:main::@37->strncpy#2] -- vwuz1=vbuc1 
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
    // [447] BRAM = main::bank_push_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_push_set_bram1_bank
    sta.z BRAM
    // main::@64
    // rom_release[rom_chip] = *((char*)0xBF80)
    // [448] rom_release[main::rom_chip1#10] = *((char *) 49024) -- pbuc1_derefidx_vbum1=_deref_pbuc2 
    lda $bf80
    ldy rom_chip1
    sta rom_release,y
    // main::bank_pull_bram1
    // asm
    // asm { pla sta$00  }
    pla
    sta.z 0
    // [450] phi from main::bank_pull_bram1 to main::@65 [phi:main::bank_pull_bram1->main::@65]
    // main::@65
    // sprintf(info_text, "%s:R%u/%s", file, rom_release[rom_chip], rom_github[rom_chip])
    // [451] call snprintf_init
    jsr snprintf_init
    // main::@118
    // [452] printf_string::str#15 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [453] call printf_string
    // [1184] phi from main::@118 to printf_string [phi:main::@118->printf_string]
    // [1184] phi printf_string::putc#18 = &snputc [phi:main::@118->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1184] phi printf_string::str#18 = printf_string::str#15 [phi:main::@118->printf_string#1] -- register_copy 
    // [1184] phi printf_string::format_justify_left#18 = 0 [phi:main::@118->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1184] phi printf_string::format_min_length#18 = 0 [phi:main::@118->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [454] phi from main::@118 to main::@119 [phi:main::@118->main::@119]
    // main::@119
    // sprintf(info_text, "%s:R%u/%s", file, rom_release[rom_chip], rom_github[rom_chip])
    // [455] call printf_str
    // [700] phi from main::@119 to printf_str [phi:main::@119->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:main::@119->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = main::s12 [phi:main::@119->printf_str#1] -- pbuz1=pbuc1 
    lda #<s12
    sta.z printf_str.s
    lda #>s12
    sta.z printf_str.s+1
    jsr printf_str
    // main::@120
    // sprintf(info_text, "%s:R%u/%s", file, rom_release[rom_chip], rom_github[rom_chip])
    // [456] printf_uchar::uvalue#8 = rom_release[main::rom_chip1#10] -- vbuz1=pbuc1_derefidx_vbum2 
    ldy rom_chip1
    lda rom_release,y
    sta.z printf_uchar.uvalue
    // [457] call printf_uchar
    // [1122] phi from main::@120 to printf_uchar [phi:main::@120->printf_uchar]
    // [1122] phi printf_uchar::format_zero_padding#10 = 0 [phi:main::@120->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1122] phi printf_uchar::format_min_length#10 = 0 [phi:main::@120->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1122] phi printf_uchar::putc#10 = &snputc [phi:main::@120->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1122] phi printf_uchar::format_radix#10 = DECIMAL [phi:main::@120->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1122] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#8 [phi:main::@120->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [458] phi from main::@120 to main::@121 [phi:main::@120->main::@121]
    // main::@121
    // sprintf(info_text, "%s:R%u/%s", file, rom_release[rom_chip], rom_github[rom_chip])
    // [459] call printf_str
    // [700] phi from main::@121 to printf_str [phi:main::@121->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:main::@121->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = s4 [phi:main::@121->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // main::@122
    // sprintf(info_text, "%s:R%u/%s", file, rom_release[rom_chip], rom_github[rom_chip])
    // [460] printf_string::str#16 = rom_github[main::$177] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z main__177
    lda rom_github,y
    sta.z printf_string.str
    lda rom_github+1,y
    sta.z printf_string.str+1
    // [461] call printf_string
    // [1184] phi from main::@122 to printf_string [phi:main::@122->printf_string]
    // [1184] phi printf_string::putc#18 = &snputc [phi:main::@122->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1184] phi printf_string::str#18 = printf_string::str#16 [phi:main::@122->printf_string#1] -- register_copy 
    // [1184] phi printf_string::format_justify_left#18 = 0 [phi:main::@122->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1184] phi printf_string::format_min_length#18 = 0 [phi:main::@122->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // main::@123
    // sprintf(info_text, "%s:R%u/%s", file, rom_release[rom_chip], rom_github[rom_chip])
    // [462] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [463] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom(rom_chip, STATUS_FLASH, info_text)
    // [465] info_rom::rom_chip#8 = main::rom_chip1#10 -- vbum1=vbum2 
    lda rom_chip1
    sta info_rom.rom_chip
    // [466] call info_rom
    // [1133] phi from main::@123 to info_rom [phi:main::@123->info_rom]
    // [1133] phi info_rom::info_text#16 = info_text [phi:main::@123->info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_rom.info_text
    lda #>@info_text
    sta.z info_rom.info_text+1
    // [1133] phi info_rom::rom_chip#16 = info_rom::rom_chip#8 [phi:main::@123->info_rom#1] -- register_copy 
    // [1133] phi info_rom::info_status#16 = STATUS_FLASH [phi:main::@123->info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta info_rom.info_status
    jsr info_rom
    // [467] phi from main::@113 main::@117 main::@123 main::@62 to main::@32 [phi:main::@113/main::@117/main::@123/main::@62->main::@32]
    // [467] phi __errno#242 = __errno#18 [phi:main::@113/main::@117/main::@123/main::@62->main::@32#0] -- register_copy 
    // main::@32
  __b32:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [468] main::rom_chip1#1 = ++ main::rom_chip1#10 -- vbum1=_inc_vbum1 
    inc rom_chip1
    // [161] phi from main::@32 to main::@31 [phi:main::@32->main::@31]
    // [161] phi __errno#111 = __errno#242 [phi:main::@32->main::@31#0] -- register_copy 
    // [161] phi main::rom_chip1#10 = main::rom_chip1#1 [phi:main::@32->main::@31#1] -- register_copy 
    jmp __b31
    // [469] phi from main::@36 to main::@34 [phi:main::@36->main::@34]
    // main::@34
  __b34:
    // sprintf(info_text, "File %s size error!", file)
    // [470] call snprintf_init
    jsr snprintf_init
    // [471] phi from main::@34 to main::@114 [phi:main::@34->main::@114]
    // main::@114
    // sprintf(info_text, "File %s size error!", file)
    // [472] call printf_str
    // [700] phi from main::@114 to printf_str [phi:main::@114->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:main::@114->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = main::s10 [phi:main::@114->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // main::@115
    // sprintf(info_text, "File %s size error!", file)
    // [473] printf_string::str#14 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [474] call printf_string
    // [1184] phi from main::@115 to printf_string [phi:main::@115->printf_string]
    // [1184] phi printf_string::putc#18 = &snputc [phi:main::@115->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1184] phi printf_string::str#18 = printf_string::str#14 [phi:main::@115->printf_string#1] -- register_copy 
    // [1184] phi printf_string::format_justify_left#18 = 0 [phi:main::@115->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1184] phi printf_string::format_min_length#18 = 0 [phi:main::@115->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [475] phi from main::@115 to main::@116 [phi:main::@115->main::@116]
    // main::@116
    // sprintf(info_text, "File %s size error!", file)
    // [476] call printf_str
    // [700] phi from main::@116 to printf_str [phi:main::@116->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:main::@116->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = main::s11 [phi:main::@116->printf_str#1] -- pbuz1=pbuc1 
    lda #<s11
    sta.z printf_str.s
    lda #>s11
    sta.z printf_str.s+1
    jsr printf_str
    // main::@117
    // sprintf(info_text, "File %s size error!", file)
    // [477] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [478] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom(rom_chip, STATUS_ERROR, info_text)
    // [480] info_rom::rom_chip#7 = main::rom_chip1#10 -- vbum1=vbum2 
    lda rom_chip1
    sta info_rom.rom_chip
    // [481] call info_rom
    // [1133] phi from main::@117 to info_rom [phi:main::@117->info_rom]
    // [1133] phi info_rom::info_text#16 = info_text [phi:main::@117->info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_rom.info_text
    lda #>@info_text
    sta.z info_rom.info_text+1
    // [1133] phi info_rom::rom_chip#16 = info_rom::rom_chip#7 [phi:main::@117->info_rom#1] -- register_copy 
    // [1133] phi info_rom::info_status#16 = STATUS_ERROR [phi:main::@117->info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta info_rom.info_status
    jsr info_rom
    jmp __b32
    // [482] phi from main::@109 to main::@33 [phi:main::@109->main::@33]
    // main::@33
  __b33:
    // sprintf(info_text, "No %s, skipped", file)
    // [483] call snprintf_init
    jsr snprintf_init
    // [484] phi from main::@33 to main::@110 [phi:main::@33->main::@110]
    // main::@110
    // sprintf(info_text, "No %s, skipped", file)
    // [485] call printf_str
    // [700] phi from main::@110 to printf_str [phi:main::@110->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:main::@110->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = main::s8 [phi:main::@110->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // main::@111
    // sprintf(info_text, "No %s, skipped", file)
    // [486] printf_string::str#13 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [487] call printf_string
    // [1184] phi from main::@111 to printf_string [phi:main::@111->printf_string]
    // [1184] phi printf_string::putc#18 = &snputc [phi:main::@111->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1184] phi printf_string::str#18 = printf_string::str#13 [phi:main::@111->printf_string#1] -- register_copy 
    // [1184] phi printf_string::format_justify_left#18 = 0 [phi:main::@111->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1184] phi printf_string::format_min_length#18 = 0 [phi:main::@111->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [488] phi from main::@111 to main::@112 [phi:main::@111->main::@112]
    // main::@112
    // sprintf(info_text, "No %s, skipped", file)
    // [489] call printf_str
    // [700] phi from main::@112 to printf_str [phi:main::@112->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:main::@112->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = main::s9 [phi:main::@112->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // main::@113
    // sprintf(info_text, "No %s, skipped", file)
    // [490] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [491] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom(rom_chip, STATUS_NONE, info_text)
    // [493] info_rom::rom_chip#6 = main::rom_chip1#10 -- vbum1=vbum2 
    lda rom_chip1
    sta info_rom.rom_chip
    // [494] call info_rom
    // [1133] phi from main::@113 to info_rom [phi:main::@113->info_rom]
    // [1133] phi info_rom::info_text#16 = info_text [phi:main::@113->info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_rom.info_text
    lda #>@info_text
    sta.z info_rom.info_text+1
    // [1133] phi info_rom::rom_chip#16 = info_rom::rom_chip#6 [phi:main::@113->info_rom#1] -- register_copy 
    // [1133] phi info_rom::info_status#16 = STATUS_NONE [phi:main::@113->info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta info_rom.info_status
    jsr info_rom
    jmp __b32
    // main::@30
  __b30:
    // [495] smc_file_size#346 = smc_file_size#0 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // info_smc(STATUS_ERROR, "SMC.BIN too large!")
    // [496] call info_smc
    // [720] phi from main::@30 to info_smc [phi:main::@30->info_smc]
    // [720] phi info_smc::info_text#12 = main::info_text9 [phi:main::@30->info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text9
    sta.z info_smc.info_text
    lda #>info_text9
    sta.z info_smc.info_text+1
    // [720] phi smc_file_size#12 = smc_file_size#346 [phi:main::@30->info_smc#1] -- register_copy 
    // [720] phi info_smc::info_status#12 = STATUS_ERROR [phi:main::@30->info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z info_smc.info_status
    jsr info_smc
    jmp CLI3
    // main::@29
  __b29:
    // [497] smc_file_size#345 = smc_file_size#0 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // info_smc(STATUS_ERROR, "No SMC.BIN!")
    // [498] call info_smc
    // [720] phi from main::@29 to info_smc [phi:main::@29->info_smc]
    // [720] phi info_smc::info_text#12 = main::info_text8 [phi:main::@29->info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z info_smc.info_text
    lda #>info_text8
    sta.z info_smc.info_text+1
    // [720] phi smc_file_size#12 = smc_file_size#345 [phi:main::@29->info_smc#1] -- register_copy 
    // [720] phi info_smc::info_status#12 = STATUS_ERROR [phi:main::@29->info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z info_smc.info_status
    jsr info_smc
    jmp CLI3
    // main::@24
  __b24:
    // print_info_led(PROGRESS_X + 3, PROGRESS_Y + 4 + intro_status, status_color[intro_status], BLUE)
    // [499] print_info_led::y#3 = PROGRESS_Y+4 + main::intro_status#2 -- vbuz1=vbuc1_plus_vbum2 
    lda #PROGRESS_Y+4
    clc
    adc intro_status
    sta.z print_info_led.y
    // [500] print_info_led::tc#3 = status_color[main::intro_status#2] -- vbuz1=pbuc1_derefidx_vbum2 
    ldy intro_status
    lda status_color,y
    sta.z print_info_led.tc
    // [501] call print_info_led
    // [1508] phi from main::@24 to print_info_led [phi:main::@24->print_info_led]
    // [1508] phi print_info_led::y#4 = print_info_led::y#3 [phi:main::@24->print_info_led#0] -- register_copy 
    // [1508] phi print_info_led::x#4 = PROGRESS_X+3 [phi:main::@24->print_info_led#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X+3
    sta.z print_info_led.x
    // [1508] phi print_info_led::tc#4 = print_info_led::tc#3 [phi:main::@24->print_info_led#2] -- register_copy 
    jsr print_info_led
    // main::@96
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [502] main::intro_status#1 = ++ main::intro_status#2 -- vbum1=_inc_vbum1 
    inc intro_status
    // [131] phi from main::@96 to main::@23 [phi:main::@96->main::@23]
    // [131] phi main::intro_status#2 = main::intro_status#1 [phi:main::@96->main::@23#0] -- register_copy 
    jmp __b23
    // main::@22
  __b22:
    // progress_text(intro_line, into_colors_text[intro_line])
    // [503] main::$173 = main::intro_line1#2 << 1 -- vbuz1=vbum2_rol_1 
    lda intro_line1
    asl
    sta.z main__173
    // [504] progress_text::line#1 = main::intro_line1#2 -- vbuz1=vbum2 
    lda intro_line1
    sta.z progress_text.line
    // [505] progress_text::text#1 = main::into_colors_text[main::$173] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z main__173
    lda into_colors_text,y
    sta.z progress_text.text
    lda into_colors_text+1,y
    sta.z progress_text.text+1
    // [506] call progress_text
    // [1519] phi from main::@22 to progress_text [phi:main::@22->progress_text]
    // [1519] phi progress_text::text#2 = progress_text::text#1 [phi:main::@22->progress_text#0] -- register_copy 
    // [1519] phi progress_text::line#2 = progress_text::line#1 [phi:main::@22->progress_text#1] -- register_copy 
    jsr progress_text
    // main::@95
    // for(unsigned char intro_line=0; intro_line<intro_colors_count; intro_line++)
    // [507] main::intro_line1#1 = ++ main::intro_line1#2 -- vbum1=_inc_vbum1 
    inc intro_line1
    // [129] phi from main::@95 to main::@21 [phi:main::@95->main::@21]
    // [129] phi main::intro_line1#2 = main::intro_line1#1 [phi:main::@95->main::@21#0] -- register_copy 
    jmp __b21
    // main::@19
  __b19:
    // progress_text(intro_line, into_briefing_text[intro_line])
    // [508] main::$172 = main::intro_line#2 << 1 -- vbuz1=vbum2_rol_1 
    lda intro_line
    asl
    sta.z main__172
    // [509] progress_text::line#0 = main::intro_line#2 -- vbuz1=vbum2 
    lda intro_line
    sta.z progress_text.line
    // [510] progress_text::text#0 = main::into_briefing_text[main::$172] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z main__172
    lda into_briefing_text,y
    sta.z progress_text.text
    lda into_briefing_text+1,y
    sta.z progress_text.text+1
    // [511] call progress_text
    // [1519] phi from main::@19 to progress_text [phi:main::@19->progress_text]
    // [1519] phi progress_text::text#2 = progress_text::text#0 [phi:main::@19->progress_text#0] -- register_copy 
    // [1519] phi progress_text::line#2 = progress_text::line#0 [phi:main::@19->progress_text#1] -- register_copy 
    jsr progress_text
    // main::@93
    // for(unsigned char intro_line=0; intro_line<intro_briefing_count; intro_line++)
    // [512] main::intro_line#1 = ++ main::intro_line#2 -- vbum1=_inc_vbum1 
    inc intro_line
    // [123] phi from main::@93 to main::@18 [phi:main::@93->main::@18]
    // [123] phi main::intro_line#2 = main::intro_line#1 [phi:main::@93->main::@18#0] -- register_copy 
    jmp __b18
    // main::@14
  __b14:
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [513] if(rom_device_ids[main::rom_chip#2]!=$55) goto main::@15 -- pbuc1_derefidx_vbum1_neq_vbuc2_then_la1 
    lda #$55
    ldy rom_chip
    cmp rom_device_ids,y
    bne __b15
    // main::@17
    // info_rom(rom_chip, STATUS_NONE, "")
    // [514] info_rom::rom_chip#5 = main::rom_chip#2 -- vbum1=vbum2 
    tya
    sta info_rom.rom_chip
    // [515] call info_rom
    // [1133] phi from main::@17 to info_rom [phi:main::@17->info_rom]
    // [1133] phi info_rom::info_text#16 = info_text4 [phi:main::@17->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z info_rom.info_text
    lda #>info_text4
    sta.z info_rom.info_text+1
    // [1133] phi info_rom::rom_chip#16 = info_rom::rom_chip#5 [phi:main::@17->info_rom#1] -- register_copy 
    // [1133] phi info_rom::info_status#16 = STATUS_NONE [phi:main::@17->info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta info_rom.info_status
    jsr info_rom
    // main::@16
  __b16:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [516] main::rom_chip#1 = ++ main::rom_chip#2 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [120] phi from main::@16 to main::@13 [phi:main::@16->main::@13]
    // [120] phi main::rom_chip#2 = main::rom_chip#1 [phi:main::@16->main::@13#0] -- register_copy 
    jmp __b13
    // main::@15
  __b15:
    // info_rom(rom_chip, STATUS_DETECTED, "")
    // [517] info_rom::rom_chip#4 = main::rom_chip#2 -- vbum1=vbum2 
    lda rom_chip
    sta info_rom.rom_chip
    // [518] call info_rom
    // [1133] phi from main::@15 to info_rom [phi:main::@15->info_rom]
    // [1133] phi info_rom::info_text#16 = info_text4 [phi:main::@15->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z info_rom.info_text
    lda #>info_text4
    sta.z info_rom.info_text+1
    // [1133] phi info_rom::rom_chip#16 = info_rom::rom_chip#4 [phi:main::@15->info_rom#1] -- register_copy 
    // [1133] phi info_rom::info_status#16 = STATUS_DETECTED [phi:main::@15->info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_DETECTED
    sta info_rom.info_status
    jsr info_rom
    jmp __b16
    // [519] phi from main::@4 to main::@12 [phi:main::@4->main::@12]
    // main::@12
  __b12:
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [520] call snprintf_init
    jsr snprintf_init
    // [521] phi from main::@12 to main::@84 [phi:main::@12->main::@84]
    // main::@84
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [522] call printf_str
    // [700] phi from main::@84 to printf_str [phi:main::@84->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:main::@84->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = main::s2 [phi:main::@84->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main::@85
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [523] printf_uint::uvalue#13 = smc_bootloader#0 -- vwuz1=vwum2 
    lda smc_bootloader
    sta.z printf_uint.uvalue
    lda smc_bootloader+1
    sta.z printf_uint.uvalue+1
    // [524] call printf_uint
    // [709] phi from main::@85 to printf_uint [phi:main::@85->printf_uint]
    // [709] phi printf_uint::format_zero_padding#16 = 1 [phi:main::@85->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [709] phi printf_uint::format_min_length#16 = 2 [phi:main::@85->printf_uint#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uint.format_min_length
    // [709] phi printf_uint::putc#16 = &snputc [phi:main::@85->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [709] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:main::@85->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [709] phi printf_uint::uvalue#16 = printf_uint::uvalue#13 [phi:main::@85->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [525] phi from main::@85 to main::@86 [phi:main::@85->main::@86]
    // main::@86
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [526] call printf_str
    // [700] phi from main::@86 to printf_str [phi:main::@86->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:main::@86->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = main::s3 [phi:main::@86->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // main::@87
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [527] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [528] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_smc(STATUS_ERROR, info_text)
    // [530] call info_smc
    // [720] phi from main::@87 to info_smc [phi:main::@87->info_smc]
    // [720] phi info_smc::info_text#12 = info_text [phi:main::@87->info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_smc.info_text
    lda #>@info_text
    sta.z info_smc.info_text+1
    // [720] phi smc_file_size#12 = 0 [phi:main::@87->info_smc#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size_2
    sta smc_file_size_2+1
    // [720] phi info_smc::info_status#12 = STATUS_ERROR [phi:main::@87->info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z info_smc.info_status
    jsr info_smc
    jmp CLI1
    // [531] phi from main::@3 to main::@11 [phi:main::@3->main::@11]
    // main::@11
  __b11:
    // info_smc(STATUS_ERROR, "Unreachable!")
    // [532] call info_smc
  // TODO: explain next steps ...
    // [720] phi from main::@11 to info_smc [phi:main::@11->info_smc]
    // [720] phi info_smc::info_text#12 = main::info_text2 [phi:main::@11->info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z info_smc.info_text
    lda #>info_text2
    sta.z info_smc.info_text+1
    // [720] phi smc_file_size#12 = 0 [phi:main::@11->info_smc#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size_2
    sta smc_file_size_2+1
    // [720] phi info_smc::info_status#12 = STATUS_ERROR [phi:main::@11->info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z info_smc.info_status
    jsr info_smc
    jmp CLI1
    // [533] phi from main::@83 to main::@1 [phi:main::@83->main::@1]
    // main::@1
  __b1:
    // info_smc(STATUS_ERROR, "No Bootloader!")
    // [534] call info_smc
  // TODO: explain next steps ...
    // [720] phi from main::@1 to info_smc [phi:main::@1->info_smc]
    // [720] phi info_smc::info_text#12 = main::info_text1 [phi:main::@1->info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z info_smc.info_text
    lda #>info_text1
    sta.z info_smc.info_text+1
    // [720] phi smc_file_size#12 = 0 [phi:main::@1->info_smc#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size_2
    sta smc_file_size_2+1
    // [720] phi info_smc::info_status#12 = STATUS_ERROR [phi:main::@1->info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z info_smc.info_status
    jsr info_smc
    jmp CLI1
  .segment Data
    into_briefing_text: .word __14, __15, info_text4, __17, __18, __19, __20, __21, __22, __23, __24, info_text4, __26, __27
    .fill 2*2, 0
    into_colors_text: .word __28, __29, info_text4, __31, __32, __33, __34, __35, __36, __37, __38, __39, __40, __41, info_text4, __43
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
    main__196: .text "nN"
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
    s18: .text "Resetting your CX16 in "
    .byte 0
    .label main__108 = strchr.str
    main__175: .byte 0
    main__179: .byte 0
    cx16_k_screen_set_charset1_charset: .byte 0
    cx16_k_screen_set_charset1_offset: .word 0
    check_cx16_rom2_check_rom1_main__0: .byte 0
    check_card_roms1_check_rom1_main__0: .byte 0
    check_smc4_main__0: .byte 0
    check_vera1_main__0: .byte 0
    check_vera3_main__0: .byte 0
    check_roms2_check_rom1_main__0: .byte 0
    rom_chip: .byte 0
    intro_line: .byte 0
    intro_line1: .byte 0
    intro_status: .byte 0
    rom_chip1: .byte 0
    rom_bank: .byte 0
    file: .word 0
    .label rom_bytes_read = rom_read.return
    rom_file_modulo: .dword 0
    .label check_cx16_rom2_check_rom1_return = check_cx16_rom2_check_rom1_main__0
    .label check_card_roms1_check_rom1_return = check_card_roms1_check_rom1_main__0
    check_card_roms1_rom_chip: .byte 0
    check_card_roms1_return: .byte 0
    .label check_smc4_return = check_smc4_main__0
    .label ch = strchr.c
    rom_chip2: .byte 0
    flashed_bytes: .dword 0
    .label check_vera1_return = check_vera1_main__0
    check_roms_all1_rom_chip: .byte 0
    check_roms_all1_return: .byte 0
    rom_chip3: .byte 0
    rom_bank1: .byte 0
    .label file1 = rom_file.return
    .label rom_bytes_read1 = rom_read.return
    rom_flash_errors: .dword 0
    check_roms1_rom_chip: .byte 0
    check_roms1_return: .byte 0
    .label check_vera3_return = check_vera3_main__0
    .label check_roms2_check_rom1_return = check_roms2_check_rom1_main__0
    check_roms2_rom_chip: .byte 0
    check_roms2_return: .byte 0
    flash_reset: .byte 0
}
.segment Code
  // screenlayer1
// Set the layer with which the conio will interact.
screenlayer1: {
    // screenlayer(1, *VERA_L1_MAPBASE, *VERA_L1_CONFIG)
    // [535] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbuz1=_deref_pbuc1 
    lda VERA_L1_MAPBASE
    sta.z screenlayer.mapbase
    // [536] screenlayer::config#0 = *VERA_L1_CONFIG -- vbuz1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta.z screenlayer.config
    // [537] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [538] return 
    rts
}
  // textcolor
// Set the front color for text output. The old front text color setting is returned.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char textcolor(__zp($da) char color)
textcolor: {
    .label textcolor__0 = $dd
    .label textcolor__1 = $da
    .label color = $da
    // __conio.color & 0xF0
    // [540] textcolor::$0 = *((char *)&__conio+$d) & $f0 -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$d
    sta.z textcolor__0
    // __conio.color & 0xF0 | color
    // [541] textcolor::$1 = textcolor::$0 | textcolor::color#18 -- vbuz1=vbuz2_bor_vbuz1 
    lda.z textcolor__1
    ora.z textcolor__0
    sta.z textcolor__1
    // __conio.color = __conio.color & 0xF0 | color
    // [542] *((char *)&__conio+$d) = textcolor::$1 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // textcolor::@return
    // }
    // [543] return 
    rts
}
  // bgcolor
// Set the back color for text output.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char bgcolor(__zp($da) char color)
bgcolor: {
    .label bgcolor__0 = $db
    .label bgcolor__1 = $da
    .label bgcolor__2 = $db
    .label color = $da
    // __conio.color & 0x0F
    // [545] bgcolor::$0 = *((char *)&__conio+$d) & $f -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$d
    sta.z bgcolor__0
    // color << 4
    // [546] bgcolor::$1 = bgcolor::color#14 << 4 -- vbuz1=vbuz1_rol_4 
    lda.z bgcolor__1
    asl
    asl
    asl
    asl
    sta.z bgcolor__1
    // __conio.color & 0x0F | color << 4
    // [547] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbuz1=vbuz1_bor_vbuz2 
    lda.z bgcolor__2
    ora.z bgcolor__1
    sta.z bgcolor__2
    // __conio.color = __conio.color & 0x0F | color << 4
    // [548] *((char *)&__conio+$d) = bgcolor::$2 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // bgcolor::@return
    // }
    // [549] return 
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
    // [550] *((char *)&__conio+$c) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$c
    // cursor::@return
    // }
    // [551] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    // __mem unsigned char x
    // [552] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [553] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [555] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwum1=vbum2_word_vbum3 
    lda x
    sta return+1
    lda y
    sta return
    // cbm_k_plot_get::@return
    // }
    // [556] return 
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
    // [558] if(gotoxy::x#30>=*((char *)&__conio+6)) goto gotoxy::@1 -- vbuz1_ge__deref_pbuc1_then_la1 
    lda.z x
    cmp __conio+6
    bcs __b1
    // [560] phi from gotoxy gotoxy::@1 to gotoxy::@2 [phi:gotoxy/gotoxy::@1->gotoxy::@2]
    // [560] phi gotoxy::$3 = gotoxy::x#30 [phi:gotoxy/gotoxy::@1->gotoxy::@2#0] -- register_copy 
    jmp __b2
    // gotoxy::@1
  __b1:
    // [559] gotoxy::$2 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z gotoxy__2
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [561] *((char *)&__conio) = gotoxy::$3 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__3
    sta __conio
    // (y>=__conio.height)?__conio.height:y
    // [562] if(gotoxy::y#30>=*((char *)&__conio+7)) goto gotoxy::@3 -- vbuz1_ge__deref_pbuc1_then_la1 
    lda.z y
    cmp __conio+7
    bcs __b3
    // gotoxy::@4
    // [563] gotoxy::$14 = gotoxy::y#30 -- vbuz1=vbuz2 
    sta.z gotoxy__14
    // [564] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [564] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [565] *((char *)&__conio+1) = gotoxy::$7 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__7
    sta __conio+1
    // __conio.cursor_x << 1
    // [566] gotoxy::$8 = *((char *)&__conio) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio
    asl
    sta.z gotoxy__8
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [567] gotoxy::$10 = gotoxy::y#30 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z gotoxy__10
    // [568] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwuz1=pwuc1_derefidx_vbuz2_plus_vbuz3 
    ldy.z gotoxy__10
    clc
    adc __conio+$15,y
    sta.z gotoxy__9
    lda __conio+$15+1,y
    adc #0
    sta.z gotoxy__9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [569] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwuz1 
    lda.z gotoxy__9
    sta __conio+$13
    lda.z gotoxy__9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [570] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [571] gotoxy::$6 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
    lda __conio+7
    sta.z gotoxy__6
    jmp __b5
}
  // cputln
// Print a newline
cputln: {
    .label cputln__2 = $6b
    // __conio.cursor_x = 0
    // [572] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y++;
    // [573] *((char *)&__conio+1) = ++ *((char *)&__conio+1) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+1
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [574] cputln::$2 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z cputln__2
    // [575] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [576] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [577] return 
    rts
}
  // frame_init
frame_init: {
    .const vera_display_set_hstart1_start = $b
    .const vera_display_set_hstop1_stop = $93
    .const vera_display_set_vstart1_start = $13
    .const vera_display_set_vstop1_stop = $db
    // textcolor(WHITE)
    // [579] call textcolor
  // Set the charset to lower case.
  // screenlayer1();
    // [539] phi from frame_init to textcolor [phi:frame_init->textcolor]
    // [539] phi textcolor::color#18 = WHITE [phi:frame_init->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [580] phi from frame_init to frame_init::@2 [phi:frame_init->frame_init::@2]
    // frame_init::@2
    // bgcolor(BLUE)
    // [581] call bgcolor
    // [544] phi from frame_init::@2 to bgcolor [phi:frame_init::@2->bgcolor]
    // [544] phi bgcolor::color#14 = BLUE [phi:frame_init::@2->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [582] phi from frame_init::@2 to frame_init::@3 [phi:frame_init::@2->frame_init::@3]
    // frame_init::@3
    // scroll(0)
    // [583] call scroll
    jsr scroll
    // [584] phi from frame_init::@3 to frame_init::@4 [phi:frame_init::@3->frame_init::@4]
    // frame_init::@4
    // clrscr()
    // [585] call clrscr
    jsr clrscr
    // frame_init::vera_display_set_hstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [586] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTART = start
    // [587] *VERA_DC_HSTART = frame_init::vera_display_set_hstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstart1_start
    sta VERA_DC_HSTART
    // frame_init::vera_display_set_hstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [588] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTOP = stop
    // [589] *VERA_DC_HSTOP = frame_init::vera_display_set_hstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstop1_stop
    sta VERA_DC_HSTOP
    // frame_init::vera_display_set_vstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [590] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTART = start
    // [591] *VERA_DC_VSTART = frame_init::vera_display_set_vstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstart1_start
    sta VERA_DC_VSTART
    // frame_init::vera_display_set_vstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [592] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTOP = stop
    // [593] *VERA_DC_VSTOP = frame_init::vera_display_set_vstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstop1_stop
    sta VERA_DC_VSTOP
    // frame_init::@1
    // cx16_k_screen_set_charset(3, (char *)0)
    // [594] frame_init::cx16_k_screen_set_charset1_charset = 3 -- vbum1=vbuc1 
    lda #3
    sta cx16_k_screen_set_charset1_charset
    // [595] frame_init::cx16_k_screen_set_charset1_offset = (char *) 0 -- pbum1=pbuc1 
    lda #<0
    sta cx16_k_screen_set_charset1_offset
    sta cx16_k_screen_set_charset1_offset+1
    // frame_init::cx16_k_screen_set_charset1
    // asm
    // asm { ldacharset ldx<offset ldy>offset jsrCX16_SCREEN_SET_CHARSET  }
    lda cx16_k_screen_set_charset1_charset
    ldx.z <cx16_k_screen_set_charset1_offset
    ldy.z >cx16_k_screen_set_charset1_offset
    jsr CX16_SCREEN_SET_CHARSET
    // frame_init::@return
    // }
    // [597] return 
    rts
  .segment Data
    cx16_k_screen_set_charset1_charset: .byte 0
    cx16_k_screen_set_charset1_offset: .word 0
}
.segment Code
  // frame_draw
frame_draw: {
    // textcolor(LIGHT_BLUE)
    // [599] call textcolor
    // [539] phi from frame_draw to textcolor [phi:frame_draw->textcolor]
    // [539] phi textcolor::color#18 = LIGHT_BLUE [phi:frame_draw->textcolor#0] -- vbuz1=vbuc1 
    lda #LIGHT_BLUE
    sta.z textcolor.color
    jsr textcolor
    // [600] phi from frame_draw to frame_draw::@1 [phi:frame_draw->frame_draw::@1]
    // frame_draw::@1
    // bgcolor(BLUE)
    // [601] call bgcolor
    // [544] phi from frame_draw::@1 to bgcolor [phi:frame_draw::@1->bgcolor]
    // [544] phi bgcolor::color#14 = BLUE [phi:frame_draw::@1->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [602] phi from frame_draw::@1 to frame_draw::@2 [phi:frame_draw::@1->frame_draw::@2]
    // frame_draw::@2
    // clrscr()
    // [603] call clrscr
    jsr clrscr
    // [604] phi from frame_draw::@2 to frame_draw::@3 [phi:frame_draw::@2->frame_draw::@3]
    // frame_draw::@3
    // frame(0, 0, 67, 14)
    // [605] call frame
    // [1595] phi from frame_draw::@3 to frame [phi:frame_draw::@3->frame]
    // [1595] phi frame::y#0 = 0 [phi:frame_draw::@3->frame#0] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.y
    // [1595] phi frame::y1#16 = $e [phi:frame_draw::@3->frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z frame.y1
    // [1595] phi frame::x#0 = 0 [phi:frame_draw::@3->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1595] phi frame::x1#16 = $43 [phi:frame_draw::@3->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [606] phi from frame_draw::@3 to frame_draw::@4 [phi:frame_draw::@3->frame_draw::@4]
    // frame_draw::@4
    // frame(0, 0, 67, 2)
    // [607] call frame
    // [1595] phi from frame_draw::@4 to frame [phi:frame_draw::@4->frame]
    // [1595] phi frame::y#0 = 0 [phi:frame_draw::@4->frame#0] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.y
    // [1595] phi frame::y1#16 = 2 [phi:frame_draw::@4->frame#1] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y1
    // [1595] phi frame::x#0 = 0 [phi:frame_draw::@4->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1595] phi frame::x1#16 = $43 [phi:frame_draw::@4->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [608] phi from frame_draw::@4 to frame_draw::@5 [phi:frame_draw::@4->frame_draw::@5]
    // frame_draw::@5
    // frame(0, 2, 67, 14)
    // [609] call frame
    // [1595] phi from frame_draw::@5 to frame [phi:frame_draw::@5->frame]
    // [1595] phi frame::y#0 = 2 [phi:frame_draw::@5->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1595] phi frame::y1#16 = $e [phi:frame_draw::@5->frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z frame.y1
    // [1595] phi frame::x#0 = 0 [phi:frame_draw::@5->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1595] phi frame::x1#16 = $43 [phi:frame_draw::@5->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [610] phi from frame_draw::@5 to frame_draw::@6 [phi:frame_draw::@5->frame_draw::@6]
    // frame_draw::@6
    // frame(0, 2, 8, 14)
    // [611] call frame
  // Chipset areas
    // [1595] phi from frame_draw::@6 to frame [phi:frame_draw::@6->frame]
    // [1595] phi frame::y#0 = 2 [phi:frame_draw::@6->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1595] phi frame::y1#16 = $e [phi:frame_draw::@6->frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z frame.y1
    // [1595] phi frame::x#0 = 0 [phi:frame_draw::@6->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1595] phi frame::x1#16 = 8 [phi:frame_draw::@6->frame#3] -- vbuz1=vbuc1 
    lda #8
    sta.z frame.x1
    jsr frame
    // [612] phi from frame_draw::@6 to frame_draw::@7 [phi:frame_draw::@6->frame_draw::@7]
    // frame_draw::@7
    // frame(8, 2, 19, 14)
    // [613] call frame
    // [1595] phi from frame_draw::@7 to frame [phi:frame_draw::@7->frame]
    // [1595] phi frame::y#0 = 2 [phi:frame_draw::@7->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1595] phi frame::y1#16 = $e [phi:frame_draw::@7->frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z frame.y1
    // [1595] phi frame::x#0 = 8 [phi:frame_draw::@7->frame#2] -- vbuz1=vbuc1 
    lda #8
    sta.z frame.x
    // [1595] phi frame::x1#16 = $13 [phi:frame_draw::@7->frame#3] -- vbuz1=vbuc1 
    lda #$13
    sta.z frame.x1
    jsr frame
    // [614] phi from frame_draw::@7 to frame_draw::@8 [phi:frame_draw::@7->frame_draw::@8]
    // frame_draw::@8
    // frame(19, 2, 25, 14)
    // [615] call frame
    // [1595] phi from frame_draw::@8 to frame [phi:frame_draw::@8->frame]
    // [1595] phi frame::y#0 = 2 [phi:frame_draw::@8->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1595] phi frame::y1#16 = $e [phi:frame_draw::@8->frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z frame.y1
    // [1595] phi frame::x#0 = $13 [phi:frame_draw::@8->frame#2] -- vbuz1=vbuc1 
    lda #$13
    sta.z frame.x
    // [1595] phi frame::x1#16 = $19 [phi:frame_draw::@8->frame#3] -- vbuz1=vbuc1 
    lda #$19
    sta.z frame.x1
    jsr frame
    // [616] phi from frame_draw::@8 to frame_draw::@9 [phi:frame_draw::@8->frame_draw::@9]
    // frame_draw::@9
    // frame(25, 2, 31, 14)
    // [617] call frame
    // [1595] phi from frame_draw::@9 to frame [phi:frame_draw::@9->frame]
    // [1595] phi frame::y#0 = 2 [phi:frame_draw::@9->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1595] phi frame::y1#16 = $e [phi:frame_draw::@9->frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z frame.y1
    // [1595] phi frame::x#0 = $19 [phi:frame_draw::@9->frame#2] -- vbuz1=vbuc1 
    lda #$19
    sta.z frame.x
    // [1595] phi frame::x1#16 = $1f [phi:frame_draw::@9->frame#3] -- vbuz1=vbuc1 
    lda #$1f
    sta.z frame.x1
    jsr frame
    // [618] phi from frame_draw::@9 to frame_draw::@10 [phi:frame_draw::@9->frame_draw::@10]
    // frame_draw::@10
    // frame(31, 2, 37, 14)
    // [619] call frame
    // [1595] phi from frame_draw::@10 to frame [phi:frame_draw::@10->frame]
    // [1595] phi frame::y#0 = 2 [phi:frame_draw::@10->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1595] phi frame::y1#16 = $e [phi:frame_draw::@10->frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z frame.y1
    // [1595] phi frame::x#0 = $1f [phi:frame_draw::@10->frame#2] -- vbuz1=vbuc1 
    lda #$1f
    sta.z frame.x
    // [1595] phi frame::x1#16 = $25 [phi:frame_draw::@10->frame#3] -- vbuz1=vbuc1 
    lda #$25
    sta.z frame.x1
    jsr frame
    // [620] phi from frame_draw::@10 to frame_draw::@11 [phi:frame_draw::@10->frame_draw::@11]
    // frame_draw::@11
    // frame(37, 2, 43, 14)
    // [621] call frame
    // [1595] phi from frame_draw::@11 to frame [phi:frame_draw::@11->frame]
    // [1595] phi frame::y#0 = 2 [phi:frame_draw::@11->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1595] phi frame::y1#16 = $e [phi:frame_draw::@11->frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z frame.y1
    // [1595] phi frame::x#0 = $25 [phi:frame_draw::@11->frame#2] -- vbuz1=vbuc1 
    lda #$25
    sta.z frame.x
    // [1595] phi frame::x1#16 = $2b [phi:frame_draw::@11->frame#3] -- vbuz1=vbuc1 
    lda #$2b
    sta.z frame.x1
    jsr frame
    // [622] phi from frame_draw::@11 to frame_draw::@12 [phi:frame_draw::@11->frame_draw::@12]
    // frame_draw::@12
    // frame(43, 2, 49, 14)
    // [623] call frame
    // [1595] phi from frame_draw::@12 to frame [phi:frame_draw::@12->frame]
    // [1595] phi frame::y#0 = 2 [phi:frame_draw::@12->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1595] phi frame::y1#16 = $e [phi:frame_draw::@12->frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z frame.y1
    // [1595] phi frame::x#0 = $2b [phi:frame_draw::@12->frame#2] -- vbuz1=vbuc1 
    lda #$2b
    sta.z frame.x
    // [1595] phi frame::x1#16 = $31 [phi:frame_draw::@12->frame#3] -- vbuz1=vbuc1 
    lda #$31
    sta.z frame.x1
    jsr frame
    // [624] phi from frame_draw::@12 to frame_draw::@13 [phi:frame_draw::@12->frame_draw::@13]
    // frame_draw::@13
    // frame(49, 2, 55, 14)
    // [625] call frame
    // [1595] phi from frame_draw::@13 to frame [phi:frame_draw::@13->frame]
    // [1595] phi frame::y#0 = 2 [phi:frame_draw::@13->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1595] phi frame::y1#16 = $e [phi:frame_draw::@13->frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z frame.y1
    // [1595] phi frame::x#0 = $31 [phi:frame_draw::@13->frame#2] -- vbuz1=vbuc1 
    lda #$31
    sta.z frame.x
    // [1595] phi frame::x1#16 = $37 [phi:frame_draw::@13->frame#3] -- vbuz1=vbuc1 
    lda #$37
    sta.z frame.x1
    jsr frame
    // [626] phi from frame_draw::@13 to frame_draw::@14 [phi:frame_draw::@13->frame_draw::@14]
    // frame_draw::@14
    // frame(55, 2, 61, 14)
    // [627] call frame
    // [1595] phi from frame_draw::@14 to frame [phi:frame_draw::@14->frame]
    // [1595] phi frame::y#0 = 2 [phi:frame_draw::@14->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1595] phi frame::y1#16 = $e [phi:frame_draw::@14->frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z frame.y1
    // [1595] phi frame::x#0 = $37 [phi:frame_draw::@14->frame#2] -- vbuz1=vbuc1 
    lda #$37
    sta.z frame.x
    // [1595] phi frame::x1#16 = $3d [phi:frame_draw::@14->frame#3] -- vbuz1=vbuc1 
    lda #$3d
    sta.z frame.x1
    jsr frame
    // [628] phi from frame_draw::@14 to frame_draw::@15 [phi:frame_draw::@14->frame_draw::@15]
    // frame_draw::@15
    // frame(61, 2, 67, 14)
    // [629] call frame
    // [1595] phi from frame_draw::@15 to frame [phi:frame_draw::@15->frame]
    // [1595] phi frame::y#0 = 2 [phi:frame_draw::@15->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1595] phi frame::y1#16 = $e [phi:frame_draw::@15->frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z frame.y1
    // [1595] phi frame::x#0 = $3d [phi:frame_draw::@15->frame#2] -- vbuz1=vbuc1 
    lda #$3d
    sta.z frame.x
    // [1595] phi frame::x1#16 = $43 [phi:frame_draw::@15->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [630] phi from frame_draw::@15 to frame_draw::@16 [phi:frame_draw::@15->frame_draw::@16]
    // frame_draw::@16
    // frame(0, 14, 67, PROGRESS_Y-5)
    // [631] call frame
  // Progress area
    // [1595] phi from frame_draw::@16 to frame [phi:frame_draw::@16->frame]
    // [1595] phi frame::y#0 = $e [phi:frame_draw::@16->frame#0] -- vbuz1=vbuc1 
    lda #$e
    sta.z frame.y
    // [1595] phi frame::y1#16 = PROGRESS_Y-5 [phi:frame_draw::@16->frame#1] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-5
    sta.z frame.y1
    // [1595] phi frame::x#0 = 0 [phi:frame_draw::@16->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1595] phi frame::x1#16 = $43 [phi:frame_draw::@16->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [632] phi from frame_draw::@16 to frame_draw::@17 [phi:frame_draw::@16->frame_draw::@17]
    // frame_draw::@17
    // frame(0, PROGRESS_Y-5, 67, PROGRESS_Y-2)
    // [633] call frame
    // [1595] phi from frame_draw::@17 to frame [phi:frame_draw::@17->frame]
    // [1595] phi frame::y#0 = PROGRESS_Y-5 [phi:frame_draw::@17->frame#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-5
    sta.z frame.y
    // [1595] phi frame::y1#16 = PROGRESS_Y-2 [phi:frame_draw::@17->frame#1] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-2
    sta.z frame.y1
    // [1595] phi frame::x#0 = 0 [phi:frame_draw::@17->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1595] phi frame::x1#16 = $43 [phi:frame_draw::@17->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [634] phi from frame_draw::@17 to frame_draw::@18 [phi:frame_draw::@17->frame_draw::@18]
    // frame_draw::@18
    // frame(0, PROGRESS_Y-2, 67, 49)
    // [635] call frame
    // [1595] phi from frame_draw::@18 to frame [phi:frame_draw::@18->frame]
    // [1595] phi frame::y#0 = PROGRESS_Y-2 [phi:frame_draw::@18->frame#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-2
    sta.z frame.y
    // [1595] phi frame::y1#16 = $31 [phi:frame_draw::@18->frame#1] -- vbuz1=vbuc1 
    lda #$31
    sta.z frame.y1
    // [1595] phi frame::x#0 = 0 [phi:frame_draw::@18->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1595] phi frame::x1#16 = $43 [phi:frame_draw::@18->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [636] phi from frame_draw::@18 to frame_draw::@19 [phi:frame_draw::@18->frame_draw::@19]
    // frame_draw::@19
    // textcolor(WHITE)
    // [637] call textcolor
    // [539] phi from frame_draw::@19 to textcolor [phi:frame_draw::@19->textcolor]
    // [539] phi textcolor::color#18 = WHITE [phi:frame_draw::@19->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // frame_draw::@return
    // }
    // [638] return 
    rts
}
  // print_title
// void print_title(char *title_text)
print_title: {
    // gotoxy(2, 1)
    // [640] call gotoxy
    // [557] phi from print_title to gotoxy [phi:print_title->gotoxy]
    // [557] phi gotoxy::y#30 = 1 [phi:print_title->gotoxy#0] -- vbuz1=vbuc1 
    lda #1
    sta.z gotoxy.y
    // [557] phi gotoxy::x#30 = 2 [phi:print_title->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // [641] phi from print_title to print_title::@1 [phi:print_title->print_title::@1]
    // print_title::@1
    // printf("%-65s", title_text)
    // [642] call printf_string
    // [1184] phi from print_title::@1 to printf_string [phi:print_title::@1->printf_string]
    // [1184] phi printf_string::putc#18 = &cputc [phi:print_title::@1->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1184] phi printf_string::str#18 = main::title_text [phi:print_title::@1->printf_string#1] -- pbuz1=pbuc1 
    lda #<main.title_text
    sta.z printf_string.str
    lda #>main.title_text
    sta.z printf_string.str+1
    // [1184] phi printf_string::format_justify_left#18 = 1 [phi:print_title::@1->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1184] phi printf_string::format_min_length#18 = $41 [phi:print_title::@1->printf_string#3] -- vbuz1=vbuc1 
    lda #$41
    sta.z printf_string.format_min_length
    jsr printf_string
    // print_title::@return
    // }
    // [643] return 
    rts
}
  // cputsxy
// Move cursor and output a NUL-terminated string
// Same as "gotoxy (x, y); puts (s);"
// void cputsxy(__zp($b7) char x, __zp($37) char y, __zp($2d) const char *s)
cputsxy: {
    .label y = $37
    .label s = $2d
    .label x = $b7
    // gotoxy(x, y)
    // [645] gotoxy::x#1 = cputsxy::x#4 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [646] gotoxy::y#1 = cputsxy::y#4 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [647] call gotoxy
    // [557] phi from cputsxy to gotoxy [phi:cputsxy->gotoxy]
    // [557] phi gotoxy::y#30 = gotoxy::y#1 [phi:cputsxy->gotoxy#0] -- register_copy 
    // [557] phi gotoxy::x#30 = gotoxy::x#1 [phi:cputsxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputsxy::@1
    // cputs(s)
    // [648] cputs::s#1 = cputsxy::s#4 -- pbuz1=pbuz2 
    lda.z s
    sta.z cputs.s
    lda.z s+1
    sta.z cputs.s+1
    // [649] call cputs
    // [1729] phi from cputsxy::@1 to cputs [phi:cputsxy::@1->cputs]
    jsr cputs
    // cputsxy::@return
    // }
    // [650] return 
    rts
}
  // progress_clear
/**
 * @brief Clean the progress area for the flashing.
 */
progress_clear: {
    .const h = PROGRESS_Y+PROGRESS_H
    .label x = $de
    .label i = $37
    .label y = $b7
    // textcolor(WHITE)
    // [652] call textcolor
    // [539] phi from progress_clear to textcolor [phi:progress_clear->textcolor]
    // [539] phi textcolor::color#18 = WHITE [phi:progress_clear->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [653] phi from progress_clear to progress_clear::@5 [phi:progress_clear->progress_clear::@5]
    // progress_clear::@5
    // bgcolor(BLUE)
    // [654] call bgcolor
    // [544] phi from progress_clear::@5 to bgcolor [phi:progress_clear::@5->bgcolor]
    // [544] phi bgcolor::color#14 = BLUE [phi:progress_clear::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [655] phi from progress_clear::@5 to progress_clear::@1 [phi:progress_clear::@5->progress_clear::@1]
    // [655] phi progress_clear::y#2 = PROGRESS_Y [phi:progress_clear::@5->progress_clear::@1#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // progress_clear::@1
  __b1:
    // while (y < h)
    // [656] if(progress_clear::y#2<progress_clear::h) goto progress_clear::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y
    cmp #h
    bcc __b4
    // progress_clear::@return
    // }
    // [657] return 
    rts
    // [658] phi from progress_clear::@1 to progress_clear::@2 [phi:progress_clear::@1->progress_clear::@2]
  __b4:
    // [658] phi progress_clear::x#2 = PROGRESS_X [phi:progress_clear::@1->progress_clear::@2#0] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z x
    // [658] phi progress_clear::i#2 = 0 [phi:progress_clear::@1->progress_clear::@2#1] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // progress_clear::@2
  __b2:
    // for(unsigned char i = 0; i < w; i++)
    // [659] if(progress_clear::i#2<PROGRESS_W) goto progress_clear::@3 -- vbuz1_lt_vbuc1_then_la1 
    lda.z i
    cmp #PROGRESS_W
    bcc __b3
    // progress_clear::@4
    // y++;
    // [660] progress_clear::y#1 = ++ progress_clear::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [655] phi from progress_clear::@4 to progress_clear::@1 [phi:progress_clear::@4->progress_clear::@1]
    // [655] phi progress_clear::y#2 = progress_clear::y#1 [phi:progress_clear::@4->progress_clear::@1#0] -- register_copy 
    jmp __b1
    // progress_clear::@3
  __b3:
    // cputcxy(x, y, ' ')
    // [661] cputcxy::x#12 = progress_clear::x#2 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [662] cputcxy::y#12 = progress_clear::y#2 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [663] call cputcxy
    // [1738] phi from progress_clear::@3 to cputcxy [phi:progress_clear::@3->cputcxy]
    // [1738] phi cputcxy::c#15 = ' ' [phi:progress_clear::@3->cputcxy#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z cputcxy.c
    // [1738] phi cputcxy::y#15 = cputcxy::y#12 [phi:progress_clear::@3->cputcxy#1] -- register_copy 
    // [1738] phi cputcxy::x#15 = cputcxy::x#12 [phi:progress_clear::@3->cputcxy#2] -- register_copy 
    jsr cputcxy
    // progress_clear::@6
    // x++;
    // [664] progress_clear::x#1 = ++ progress_clear::x#2 -- vbuz1=_inc_vbuz1 
    inc.z x
    // for(unsigned char i = 0; i < w; i++)
    // [665] progress_clear::i#1 = ++ progress_clear::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [658] phi from progress_clear::@6 to progress_clear::@2 [phi:progress_clear::@6->progress_clear::@2]
    // [658] phi progress_clear::x#2 = progress_clear::x#1 [phi:progress_clear::@6->progress_clear::@2#0] -- register_copy 
    // [658] phi progress_clear::i#2 = progress_clear::i#1 [phi:progress_clear::@6->progress_clear::@2#1] -- register_copy 
    jmp __b2
}
  // info_progress
// void info_progress(__zp($60) char *info_text)
info_progress: {
    .label x = $e4
    .label y = $69
    .label info_text = $60
    // unsigned char x = wherex()
    // [667] call wherex
    jsr wherex
    // [668] wherex::return#2 = wherex::return#0
    // info_progress::@1
    // [669] info_progress::x#0 = wherex::return#2
    // unsigned char y = wherey()
    // [670] call wherey
    jsr wherey
    // [671] wherey::return#2 = wherey::return#0
    // info_progress::@2
    // [672] info_progress::y#0 = wherey::return#2
    // gotoxy(2, PROGRESS_Y-4)
    // [673] call gotoxy
    // [557] phi from info_progress::@2 to gotoxy [phi:info_progress::@2->gotoxy]
    // [557] phi gotoxy::y#30 = PROGRESS_Y-4 [phi:info_progress::@2->gotoxy#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-4
    sta.z gotoxy.y
    // [557] phi gotoxy::x#30 = 2 [phi:info_progress::@2->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // info_progress::@3
    // printf("%-65s", info_text)
    // [674] printf_string::str#1 = info_progress::info_text#14
    // [675] call printf_string
    // [1184] phi from info_progress::@3 to printf_string [phi:info_progress::@3->printf_string]
    // [1184] phi printf_string::putc#18 = &cputc [phi:info_progress::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1184] phi printf_string::str#18 = printf_string::str#1 [phi:info_progress::@3->printf_string#1] -- register_copy 
    // [1184] phi printf_string::format_justify_left#18 = 1 [phi:info_progress::@3->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1184] phi printf_string::format_min_length#18 = $41 [phi:info_progress::@3->printf_string#3] -- vbuz1=vbuc1 
    lda #$41
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_progress::@4
    // gotoxy(x, y)
    // [676] gotoxy::x#10 = info_progress::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [677] gotoxy::y#10 = info_progress::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [678] call gotoxy
    // [557] phi from info_progress::@4 to gotoxy [phi:info_progress::@4->gotoxy]
    // [557] phi gotoxy::y#30 = gotoxy::y#10 [phi:info_progress::@4->gotoxy#0] -- register_copy 
    // [557] phi gotoxy::x#30 = gotoxy::x#10 [phi:info_progress::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // info_progress::@return
    // }
    // [679] return 
    rts
}
  // smc_detect
smc_detect: {
    .label smc_detect__1 = $e4
    // When the bootloader is not present, 0xFF is returned.
    .label smc_bootloader_version = $2d
    .label return = $2d
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [680] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [681] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [682] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [683] cx16_k_i2c_read_byte::return#10 = cx16_k_i2c_read_byte::return#1
    // smc_detect::@3
    // smc_bootloader_version = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [684] smc_detect::smc_bootloader_version#1 = cx16_k_i2c_read_byte::return#10
    // BYTE1(smc_bootloader_version)
    // [685] smc_detect::$1 = byte1  smc_detect::smc_bootloader_version#1 -- vbuz1=_byte1_vwuz2 
    lda.z smc_bootloader_version+1
    sta.z smc_detect__1
    // if(!BYTE1(smc_bootloader_version))
    // [686] if(0==smc_detect::$1) goto smc_detect::@1 -- 0_eq_vbuz1_then_la1 
    beq __b1
    // [689] phi from smc_detect::@3 to smc_detect::@2 [phi:smc_detect::@3->smc_detect::@2]
    // [689] phi smc_detect::return#0 = $200 [phi:smc_detect::@3->smc_detect::@2#0] -- vwuz1=vwuc1 
    lda #<$200
    sta.z return
    lda #>$200
    sta.z return+1
    rts
    // smc_detect::@1
  __b1:
    // if(smc_bootloader_version == 0xFF)
    // [687] if(smc_detect::smc_bootloader_version#1!=$ff) goto smc_detect::@4 -- vwuz1_neq_vbuc1_then_la1 
    lda.z smc_bootloader_version+1
    bne __b2
    lda.z smc_bootloader_version
    cmp #$ff
    bne __b2
    // [689] phi from smc_detect::@1 to smc_detect::@2 [phi:smc_detect::@1->smc_detect::@2]
    // [689] phi smc_detect::return#0 = $100 [phi:smc_detect::@1->smc_detect::@2#0] -- vwuz1=vwuc1 
    lda #<$100
    sta.z return
    lda #>$100
    sta.z return+1
    rts
    // [688] phi from smc_detect::@1 to smc_detect::@4 [phi:smc_detect::@1->smc_detect::@4]
    // smc_detect::@4
    // [689] phi from smc_detect::@4 to smc_detect::@2 [phi:smc_detect::@4->smc_detect::@2]
    // [689] phi smc_detect::return#0 = smc_detect::smc_bootloader_version#1 [phi:smc_detect::@4->smc_detect::@2#0] -- register_copy 
    // smc_detect::@2
  __b2:
    // smc_detect::@return
    // }
    // [690] return 
    rts
}
  // chip_smc
chip_smc: {
    // print_smc_led(GREY)
    // [692] call print_smc_led
    // [1755] phi from chip_smc to print_smc_led [phi:chip_smc->print_smc_led]
    // [1755] phi print_smc_led::c#2 = GREY [phi:chip_smc->print_smc_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z print_smc_led.c
    jsr print_smc_led
    // [693] phi from chip_smc to chip_smc::@1 [phi:chip_smc->chip_smc::@1]
    // chip_smc::@1
    // print_chip(CHIP_SMC_X, CHIP_SMC_Y+2, CHIP_SMC_W, "SMC     ")
    // [694] call print_chip
    // [1761] phi from chip_smc::@1 to print_chip [phi:chip_smc::@1->print_chip]
    // [1761] phi print_chip::text#11 = chip_smc::text [phi:chip_smc::@1->print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z print_chip.text_2
    lda #>text
    sta.z print_chip.text_2+1
    // [1761] phi print_chip::w#10 = 5 [phi:chip_smc::@1->print_chip#1] -- vbuz1=vbuc1 
    lda #5
    sta.z print_chip.w
    // [1761] phi print_chip::x#10 = 1 [phi:chip_smc::@1->print_chip#2] -- vbuz1=vbuc1 
    lda #1
    sta.z print_chip.x
    jsr print_chip
    // chip_smc::@return
    // }
    // [695] return 
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
    // [696] __snprintf_capacity = $ffff -- vwum1=vwuc1 
    lda #<$ffff
    sta __snprintf_capacity
    lda #>$ffff
    sta __snprintf_capacity+1
    // __snprintf_size = 0
    // [697] __snprintf_size = 0 -- vwum1=vbuc1 
    lda #<0
    sta __snprintf_size
    sta __snprintf_size+1
    // __snprintf_buffer = s
    // [698] __snprintf_buffer = info_text -- pbum1=pbuc1 
    lda #<info_text
    sta __snprintf_buffer
    lda #>info_text
    sta __snprintf_buffer+1
    // snprintf_init::@return
    // }
    // [699] return 
    rts
}
  // printf_str
/// Print a NUL-terminated string
// void printf_str(__zp($4d) void (*putc)(char), __zp($60) const char *s)
printf_str: {
    .label c = $b6
    .label s = $60
    .label putc = $4d
    // [701] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [701] phi printf_str::s#67 = printf_str::s#68 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [702] printf_str::c#1 = *printf_str::s#67 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta.z c
    // [703] printf_str::s#0 = ++ printf_str::s#67 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [704] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // printf_str::@return
    // }
    // [705] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [706] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [707] callexecute *printf_str::putc#68  -- call__deref_pprz1 
    jsr icall12
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
    // Outside Flow
  icall12:
    jmp (putc)
}
  // printf_uint
// Print an unsigned int using a specific format
// void printf_uint(__zp($4d) void (*putc)(char), __zp($2d) unsigned int uvalue, __zp($e2) char format_min_length, char format_justify_left, char format_sign_always, __zp($e1) char format_zero_padding, char format_upper_case, __zp($de) char format_radix)
printf_uint: {
    .label uvalue = $2d
    .label format_radix = $de
    .label putc = $4d
    .label format_min_length = $e2
    .label format_zero_padding = $e1
    // printf_uint::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [710] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [711] utoa::value#1 = printf_uint::uvalue#16
    // [712] utoa::radix#0 = printf_uint::format_radix#16
    // [713] call utoa
    // Format number into buffer
    jsr utoa
    // printf_uint::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [714] printf_number_buffer::putc#1 = printf_uint::putc#16
    // [715] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [716] printf_number_buffer::format_min_length#1 = printf_uint::format_min_length#16
    // [717] printf_number_buffer::format_zero_padding#1 = printf_uint::format_zero_padding#16
    // [718] call printf_number_buffer
  // Print using format
    // [1835] phi from printf_uint::@2 to printf_number_buffer [phi:printf_uint::@2->printf_number_buffer]
    // [1835] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#1 [phi:printf_uint::@2->printf_number_buffer#0] -- register_copy 
    // [1835] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_uint::@2->printf_number_buffer#1] -- register_copy 
    // [1835] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#1 [phi:printf_uint::@2->printf_number_buffer#2] -- register_copy 
    // [1835] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#1 [phi:printf_uint::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uint::@return
    // }
    // [719] return 
    rts
}
  // info_smc
/**
 * @brief Print the SMC status.
 * 
 * @param status The STATUS_ 
 * 
 * @remark The smc_booloader is a global variable. 
 */
// void info_smc(__zp($e2) char info_status, __zp($6f) char *info_text)
info_smc: {
    .label info_smc__8 = $e2
    .label x = $dc
    .label y = $63
    .label info_status = $e2
    .label info_text = $6f
    // unsigned char x = wherex()
    // [721] call wherex
    jsr wherex
    // [722] wherex::return#10 = wherex::return#0 -- vbuz1=vbuz2 
    lda.z wherex.return
    sta.z wherex.return_2
    // info_smc::@3
    // [723] info_smc::x#0 = wherex::return#10
    // unsigned char y = wherey()
    // [724] call wherey
    jsr wherey
    // [725] wherey::return#10 = wherey::return#0 -- vbuz1=vbuz2 
    lda.z wherey.return
    sta.z wherey.return_2
    // info_smc::@4
    // [726] info_smc::y#0 = wherey::return#10
    // status_smc = info_status
    // [727] status_smc#0 = info_smc::info_status#12 -- vbum1=vbuz2 
    lda.z info_status
    sta status_smc
    // print_smc_led(status_color[info_status])
    // [728] print_smc_led::c#1 = status_color[info_smc::info_status#12] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z print_smc_led.c
    // [729] call print_smc_led
    // [1755] phi from info_smc::@4 to print_smc_led [phi:info_smc::@4->print_smc_led]
    // [1755] phi print_smc_led::c#2 = print_smc_led::c#1 [phi:info_smc::@4->print_smc_led#0] -- register_copy 
    jsr print_smc_led
    // [730] phi from info_smc::@4 to info_smc::@5 [phi:info_smc::@4->info_smc::@5]
    // info_smc::@5
    // gotoxy(INFO_X, INFO_Y)
    // [731] call gotoxy
    // [557] phi from info_smc::@5 to gotoxy [phi:info_smc::@5->gotoxy]
    // [557] phi gotoxy::y#30 = $11 [phi:info_smc::@5->gotoxy#0] -- vbuz1=vbuc1 
    lda #$11
    sta.z gotoxy.y
    // [557] phi gotoxy::x#30 = 4 [phi:info_smc::@5->gotoxy#1] -- vbuz1=vbuc1 
    lda #4
    sta.z gotoxy.x
    jsr gotoxy
    // [732] phi from info_smc::@5 to info_smc::@6 [phi:info_smc::@5->info_smc::@6]
    // info_smc::@6
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [733] call printf_str
    // [700] phi from info_smc::@6 to printf_str [phi:info_smc::@6->printf_str]
    // [700] phi printf_str::putc#68 = &cputc [phi:info_smc::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = info_smc::s [phi:info_smc::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // info_smc::@7
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [734] info_smc::$8 = info_smc::info_status#12 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z info_smc__8
    // [735] printf_string::str#3 = status_text[info_smc::$8] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z info_smc__8
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [736] call printf_string
    // [1184] phi from info_smc::@7 to printf_string [phi:info_smc::@7->printf_string]
    // [1184] phi printf_string::putc#18 = &cputc [phi:info_smc::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1184] phi printf_string::str#18 = printf_string::str#3 [phi:info_smc::@7->printf_string#1] -- register_copy 
    // [1184] phi printf_string::format_justify_left#18 = 1 [phi:info_smc::@7->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1184] phi printf_string::format_min_length#18 = 9 [phi:info_smc::@7->printf_string#3] -- vbuz1=vbuc1 
    lda #9
    sta.z printf_string.format_min_length
    jsr printf_string
    // [737] phi from info_smc::@7 to info_smc::@8 [phi:info_smc::@7->info_smc::@8]
    // info_smc::@8
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [738] call printf_str
    // [700] phi from info_smc::@8 to printf_str [phi:info_smc::@8->printf_str]
    // [700] phi printf_str::putc#68 = &cputc [phi:info_smc::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = info_smc::s1 [phi:info_smc::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_smc::@9
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [739] printf_uint::uvalue#0 = smc_file_size#12 -- vwuz1=vwum2 
    lda smc_file_size_2
    sta.z printf_uint.uvalue
    lda smc_file_size_2+1
    sta.z printf_uint.uvalue+1
    // [740] call printf_uint
    // [709] phi from info_smc::@9 to printf_uint [phi:info_smc::@9->printf_uint]
    // [709] phi printf_uint::format_zero_padding#16 = 1 [phi:info_smc::@9->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [709] phi printf_uint::format_min_length#16 = 5 [phi:info_smc::@9->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [709] phi printf_uint::putc#16 = &cputc [phi:info_smc::@9->printf_uint#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uint.putc
    lda #>cputc
    sta.z printf_uint.putc+1
    // [709] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:info_smc::@9->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [709] phi printf_uint::uvalue#16 = printf_uint::uvalue#0 [phi:info_smc::@9->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [741] phi from info_smc::@9 to info_smc::@10 [phi:info_smc::@9->info_smc::@10]
    // info_smc::@10
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [742] call printf_str
    // [700] phi from info_smc::@10 to printf_str [phi:info_smc::@10->printf_str]
    // [700] phi printf_str::putc#68 = &cputc [phi:info_smc::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = info_smc::s2 [phi:info_smc::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // info_smc::@11
    // if(info_text)
    // [743] if((char *)0==info_smc::info_text#12) goto info_smc::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // info_smc::@2
    // printf("%-20s", info_text)
    // [744] printf_string::str#4 = info_smc::info_text#12 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [745] call printf_string
    // [1184] phi from info_smc::@2 to printf_string [phi:info_smc::@2->printf_string]
    // [1184] phi printf_string::putc#18 = &cputc [phi:info_smc::@2->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1184] phi printf_string::str#18 = printf_string::str#4 [phi:info_smc::@2->printf_string#1] -- register_copy 
    // [1184] phi printf_string::format_justify_left#18 = 1 [phi:info_smc::@2->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1184] phi printf_string::format_min_length#18 = $14 [phi:info_smc::@2->printf_string#3] -- vbuz1=vbuc1 
    lda #$14
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_smc::@1
  __b1:
    // gotoxy(x, y)
    // [746] gotoxy::x#14 = info_smc::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [747] gotoxy::y#14 = info_smc::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [748] call gotoxy
    // [557] phi from info_smc::@1 to gotoxy [phi:info_smc::@1->gotoxy]
    // [557] phi gotoxy::y#30 = gotoxy::y#14 [phi:info_smc::@1->gotoxy#0] -- register_copy 
    // [557] phi gotoxy::x#30 = gotoxy::x#14 [phi:info_smc::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // info_smc::@return
    // }
    // [749] return 
    rts
  .segment Data
    s: .text "SMC  "
    .byte 0
    s1: .text " ATTiny "
    .byte 0
    s2: .text " / 01E00 "
    .byte 0
}
.segment Code
  // chip_vera
chip_vera: {
    // print_vera_led(GREY)
    // [751] call print_vera_led
    // [1866] phi from chip_vera to print_vera_led [phi:chip_vera->print_vera_led]
    // [1866] phi print_vera_led::c#2 = GREY [phi:chip_vera->print_vera_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z print_vera_led.c
    jsr print_vera_led
    // [752] phi from chip_vera to chip_vera::@1 [phi:chip_vera->chip_vera::@1]
    // chip_vera::@1
    // print_chip(CHIP_VERA_X, CHIP_VERA_Y+2, CHIP_VERA_W, "VERA     ")
    // [753] call print_chip
    // [1761] phi from chip_vera::@1 to print_chip [phi:chip_vera::@1->print_chip]
    // [1761] phi print_chip::text#11 = chip_vera::text [phi:chip_vera::@1->print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z print_chip.text_2
    lda #>text
    sta.z print_chip.text_2+1
    // [1761] phi print_chip::w#10 = 8 [phi:chip_vera::@1->print_chip#1] -- vbuz1=vbuc1 
    lda #8
    sta.z print_chip.w
    // [1761] phi print_chip::x#10 = 9 [phi:chip_vera::@1->print_chip#2] -- vbuz1=vbuc1 
    lda #9
    sta.z print_chip.x
    jsr print_chip
    // chip_vera::@return
    // }
    // [754] return 
    rts
  .segment Data
    text: .text "VERA     "
    .byte 0
}
.segment Code
  // info_vera
/**
 * @brief Print the VERA status.
 * 
 * @param info_status The STATUS_ 
 */
// void info_vera(__zp($e1) char info_status, __mem() char *info_text)
info_vera: {
    .label info_vera__8 = $e1
    .label x = $38
    .label info_status = $e1
    // unsigned char x = wherex()
    // [756] call wherex
    jsr wherex
    // [757] wherex::return#11 = wherex::return#0 -- vbuz1=vbuz2 
    lda.z wherex.return
    sta.z wherex.return_3
    // info_vera::@3
    // [758] info_vera::x#0 = wherex::return#11
    // unsigned char y = wherey()
    // [759] call wherey
    jsr wherey
    // [760] wherey::return#11 = wherey::return#0 -- vbum1=vbuz2 
    lda.z wherey.return
    sta wherey.return_3
    // info_vera::@4
    // [761] info_vera::y#0 = wherey::return#11
    // status_vera = info_status
    // [762] status_vera#0 = info_vera::info_status#2 -- vbum1=vbuz2 
    lda.z info_status
    sta status_vera
    // print_vera_led(status_color[info_status])
    // [763] print_vera_led::c#1 = status_color[info_vera::info_status#2] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z print_vera_led.c
    // [764] call print_vera_led
    // [1866] phi from info_vera::@4 to print_vera_led [phi:info_vera::@4->print_vera_led]
    // [1866] phi print_vera_led::c#2 = print_vera_led::c#1 [phi:info_vera::@4->print_vera_led#0] -- register_copy 
    jsr print_vera_led
    // [765] phi from info_vera::@4 to info_vera::@5 [phi:info_vera::@4->info_vera::@5]
    // info_vera::@5
    // gotoxy(INFO_X, INFO_Y+1)
    // [766] call gotoxy
    // [557] phi from info_vera::@5 to gotoxy [phi:info_vera::@5->gotoxy]
    // [557] phi gotoxy::y#30 = $11+1 [phi:info_vera::@5->gotoxy#0] -- vbuz1=vbuc1 
    lda #$11+1
    sta.z gotoxy.y
    // [557] phi gotoxy::x#30 = 4 [phi:info_vera::@5->gotoxy#1] -- vbuz1=vbuc1 
    lda #4
    sta.z gotoxy.x
    jsr gotoxy
    // [767] phi from info_vera::@5 to info_vera::@6 [phi:info_vera::@5->info_vera::@6]
    // info_vera::@6
    // printf("VERA %-9s FPGA   1a000 / 1a000 ", status_text[info_status])
    // [768] call printf_str
    // [700] phi from info_vera::@6 to printf_str [phi:info_vera::@6->printf_str]
    // [700] phi printf_str::putc#68 = &cputc [phi:info_vera::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = info_vera::s [phi:info_vera::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // info_vera::@7
    // printf("VERA %-9s FPGA   1a000 / 1a000 ", status_text[info_status])
    // [769] info_vera::$8 = info_vera::info_status#2 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z info_vera__8
    // [770] printf_string::str#5 = status_text[info_vera::$8] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z info_vera__8
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [771] call printf_string
    // [1184] phi from info_vera::@7 to printf_string [phi:info_vera::@7->printf_string]
    // [1184] phi printf_string::putc#18 = &cputc [phi:info_vera::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1184] phi printf_string::str#18 = printf_string::str#5 [phi:info_vera::@7->printf_string#1] -- register_copy 
    // [1184] phi printf_string::format_justify_left#18 = 1 [phi:info_vera::@7->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1184] phi printf_string::format_min_length#18 = 9 [phi:info_vera::@7->printf_string#3] -- vbuz1=vbuc1 
    lda #9
    sta.z printf_string.format_min_length
    jsr printf_string
    // [772] phi from info_vera::@7 to info_vera::@8 [phi:info_vera::@7->info_vera::@8]
    // info_vera::@8
    // printf("VERA %-9s FPGA   1a000 / 1a000 ", status_text[info_status])
    // [773] call printf_str
    // [700] phi from info_vera::@8 to printf_str [phi:info_vera::@8->printf_str]
    // [700] phi printf_str::putc#68 = &cputc [phi:info_vera::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = info_vera::s1 [phi:info_vera::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_vera::@9
    // if(info_text)
    // [774] if((char *)0==info_vera::info_text#10) goto info_vera::@1 -- pbuc1_eq_pbum1_then_la1 
    lda info_text
    cmp #<0
    bne !+
    lda info_text+1
    cmp #>0
    beq __b1
  !:
    // info_vera::@2
    // printf("%-20s", info_text)
    // [775] printf_string::str#6 = info_vera::info_text#10 -- pbuz1=pbum2 
    lda info_text
    sta.z printf_string.str
    lda info_text+1
    sta.z printf_string.str+1
    // [776] call printf_string
    // [1184] phi from info_vera::@2 to printf_string [phi:info_vera::@2->printf_string]
    // [1184] phi printf_string::putc#18 = &cputc [phi:info_vera::@2->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1184] phi printf_string::str#18 = printf_string::str#6 [phi:info_vera::@2->printf_string#1] -- register_copy 
    // [1184] phi printf_string::format_justify_left#18 = 1 [phi:info_vera::@2->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1184] phi printf_string::format_min_length#18 = $14 [phi:info_vera::@2->printf_string#3] -- vbuz1=vbuc1 
    lda #$14
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_vera::@1
  __b1:
    // gotoxy(x, y)
    // [777] gotoxy::x#16 = info_vera::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [778] gotoxy::y#16 = info_vera::y#0 -- vbuz1=vbum2 
    lda y
    sta.z gotoxy.y
    // [779] call gotoxy
    // [557] phi from info_vera::@1 to gotoxy [phi:info_vera::@1->gotoxy]
    // [557] phi gotoxy::y#30 = gotoxy::y#16 [phi:info_vera::@1->gotoxy#0] -- register_copy 
    // [557] phi gotoxy::x#30 = gotoxy::x#16 [phi:info_vera::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // info_vera::@return
    // }
    // [780] return 
    rts
  .segment Data
    s: .text "VERA "
    .byte 0
    s1: .text " FPGA   1a000 / 1a000 "
    .byte 0
    .label y = rom_detect.rom_detect__15
    .label info_text = strchr.str
}
.segment Code
  // rom_detect
rom_detect: {
    .const bank_set_brom1_bank = 4
    .label rom_detect__3 = $69
    .label rom_detect__5 = $69
    .label rom_detect__9 = $b6
    .label rom_detect__18 = $38
    .label rom_detect__21 = $63
    .label rom_detect__24 = $dc
    .label rom_detect_address = $30
    // [782] phi from rom_detect to rom_detect::@1 [phi:rom_detect->rom_detect::@1]
    // [782] phi rom_detect::rom_chip#10 = 0 [phi:rom_detect->rom_detect::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // [782] phi rom_detect::rom_detect_address#10 = 0 [phi:rom_detect->rom_detect::@1#1] -- vduz1=vduc1 
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
    // [783] if(rom_detect::rom_detect_address#10<8*$80000) goto rom_detect::@2 -- vduz1_lt_vduc1_then_la1 
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
    // [784] return 
    rts
    // rom_detect::@2
  __b2:
    // rom_manufacturer_ids[rom_chip] = 0
    // [785] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = 0
    // [786] rom_device_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta rom_device_ids,y
    // rom_unlock(rom_detect_address + 0x05555, 0x90)
    // [787] rom_unlock::address#2 = rom_detect::rom_detect_address#10 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [788] call rom_unlock
    // [1872] phi from rom_detect::@2 to rom_unlock [phi:rom_detect::@2->rom_unlock]
    // [1872] phi rom_unlock::unlock_code#5 = $90 [phi:rom_detect::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$90
    sta.z rom_unlock.unlock_code
    // [1872] phi rom_unlock::address#5 = rom_unlock::address#2 [phi:rom_detect::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_detect::@12
    // rom_read_byte(rom_detect_address)
    // [789] rom_read_byte::address#0 = rom_detect::rom_detect_address#10 -- vduz1=vduz2 
    lda.z rom_detect_address
    sta.z rom_read_byte.address
    lda.z rom_detect_address+1
    sta.z rom_read_byte.address+1
    lda.z rom_detect_address+2
    sta.z rom_read_byte.address+2
    lda.z rom_detect_address+3
    sta.z rom_read_byte.address+3
    // [790] call rom_read_byte
    // [1882] phi from rom_detect::@12 to rom_read_byte [phi:rom_detect::@12->rom_read_byte]
    // [1882] phi rom_read_byte::address#2 = rom_read_byte::address#0 [phi:rom_detect::@12->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(rom_detect_address)
    // [791] rom_read_byte::return#2 = rom_read_byte::return#0
    // rom_detect::@13
    // [792] rom_detect::$3 = rom_read_byte::return#2
    // rom_manufacturer_ids[rom_chip] = rom_read_byte(rom_detect_address)
    // [793] rom_manufacturer_ids[rom_detect::rom_chip#10] = rom_detect::$3 -- pbuc1_derefidx_vbum1=vbuz2 
    lda.z rom_detect__3
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_read_byte(rom_detect_address + 1)
    // [794] rom_read_byte::address#1 = rom_detect::rom_detect_address#10 + 1 -- vduz1=vduz2_plus_1 
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
    // [795] call rom_read_byte
    // [1882] phi from rom_detect::@13 to rom_read_byte [phi:rom_detect::@13->rom_read_byte]
    // [1882] phi rom_read_byte::address#2 = rom_read_byte::address#1 [phi:rom_detect::@13->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(rom_detect_address + 1)
    // [796] rom_read_byte::return#3 = rom_read_byte::return#0
    // rom_detect::@14
    // [797] rom_detect::$5 = rom_read_byte::return#3
    // rom_device_ids[rom_chip] = rom_read_byte(rom_detect_address + 1)
    // [798] rom_device_ids[rom_detect::rom_chip#10] = rom_detect::$5 -- pbuc1_derefidx_vbum1=vbuz2 
    lda.z rom_detect__5
    ldy rom_chip
    sta rom_device_ids,y
    // rom_unlock(rom_detect_address + 0x05555, 0xF0)
    // [799] rom_unlock::address#3 = rom_detect::rom_detect_address#10 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [800] call rom_unlock
    // [1872] phi from rom_detect::@14 to rom_unlock [phi:rom_detect::@14->rom_unlock]
    // [1872] phi rom_unlock::unlock_code#5 = $f0 [phi:rom_detect::@14->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$f0
    sta.z rom_unlock.unlock_code
    // [1872] phi rom_unlock::address#5 = rom_unlock::address#3 [phi:rom_detect::@14->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_detect::bank_set_brom1
    // BROM = bank
    // [801] BROM = rom_detect::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // rom_detect::@11
    // rom_chip*3
    // [802] rom_detect::$14 = rom_detect::rom_chip#10 << 1 -- vbum1=vbum2_rol_1 
    lda rom_chip
    asl
    sta rom_detect__14
    // [803] rom_detect::$9 = rom_detect::$14 + rom_detect::rom_chip#10 -- vbuz1=vbum2_plus_vbum3 
    clc
    adc rom_chip
    sta.z rom_detect__9
    // gotoxy(rom_chip*3+40, 1)
    // [804] gotoxy::x#23 = rom_detect::$9 + $28 -- vbuz1=vbuz2_plus_vbuc1 
    lda #$28
    clc
    adc.z rom_detect__9
    sta.z gotoxy.x
    // [805] call gotoxy
    // [557] phi from rom_detect::@11 to gotoxy [phi:rom_detect::@11->gotoxy]
    // [557] phi gotoxy::y#30 = 1 [phi:rom_detect::@11->gotoxy#0] -- vbuz1=vbuc1 
    lda #1
    sta.z gotoxy.y
    // [557] phi gotoxy::x#30 = gotoxy::x#23 [phi:rom_detect::@11->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_detect::@15
    // printf("%02x", rom_device_ids[rom_chip])
    // [806] printf_uchar::uvalue#4 = rom_device_ids[rom_detect::rom_chip#10] -- vbuz1=pbuc1_derefidx_vbum2 
    ldy rom_chip
    lda rom_device_ids,y
    sta.z printf_uchar.uvalue
    // [807] call printf_uchar
    // [1122] phi from rom_detect::@15 to printf_uchar [phi:rom_detect::@15->printf_uchar]
    // [1122] phi printf_uchar::format_zero_padding#10 = 1 [phi:rom_detect::@15->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1122] phi printf_uchar::format_min_length#10 = 2 [phi:rom_detect::@15->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [1122] phi printf_uchar::putc#10 = &cputc [phi:rom_detect::@15->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1122] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:rom_detect::@15->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [1122] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#4 [phi:rom_detect::@15->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // rom_detect::@16
    // case SST39SF010A:
    //             rom_device_names[rom_chip] = "f010a";
    //             rom_size_strings[rom_chip] = "128";
    //             rom_sizes[rom_chip] = 128 * 1024;
    //             break;
    // [808] if(rom_device_ids[rom_detect::rom_chip#10]==$b5) goto rom_detect::@3 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
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
    // [809] if(rom_device_ids[rom_detect::rom_chip#10]==$b6) goto rom_detect::@4 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
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
    // [810] if(rom_device_ids[rom_detect::rom_chip#10]==$b7) goto rom_detect::@5 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b7
    beq __b5
    // rom_detect::@6
    // rom_manufacturer_ids[rom_chip] = 0
    // [811] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    sta rom_manufacturer_ids,y
    // rom_device_names[rom_chip] = "----"
    // [812] rom_device_names[rom_detect::$14] = rom_detect::$31 -- qbuc1_derefidx_vbum1=pbuc2 
    ldy rom_detect__14
    lda #<rom_detect__31
    sta rom_device_names,y
    lda #>rom_detect__31
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "000"
    // [813] rom_size_strings[rom_detect::$14] = rom_detect::$32 -- qbuc1_derefidx_vbum1=pbuc2 
    lda #<rom_detect__32
    sta rom_size_strings,y
    lda #>rom_detect__32
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 0
    // [814] rom_detect::$24 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__24
    // [815] rom_sizes[rom_detect::$24] = 0 -- pduc1_derefidx_vbuz1=vbuc2 
    tay
    lda #0
    sta rom_sizes,y
    sta rom_sizes+1,y
    sta rom_sizes+2,y
    sta rom_sizes+3,y
    // rom_device_ids[rom_chip] = UNKNOWN
    // [816] rom_device_ids[rom_detect::rom_chip#10] = $55 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$55
    ldy rom_chip
    sta rom_device_ids,y
    // rom_detect::@7
  __b7:
    // rom_chip++;
    // [817] rom_detect::rom_chip#1 = ++ rom_detect::rom_chip#10 -- vbum1=_inc_vbum1 
    inc rom_chip
    // rom_detect::@8
    // rom_detect_address += 0x80000
    // [818] rom_detect::rom_detect_address#1 = rom_detect::rom_detect_address#10 + $80000 -- vduz1=vduz1_plus_vduc1 
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
    // [782] phi from rom_detect::@8 to rom_detect::@1 [phi:rom_detect::@8->rom_detect::@1]
    // [782] phi rom_detect::rom_chip#10 = rom_detect::rom_chip#1 [phi:rom_detect::@8->rom_detect::@1#0] -- register_copy 
    // [782] phi rom_detect::rom_detect_address#10 = rom_detect::rom_detect_address#1 [phi:rom_detect::@8->rom_detect::@1#1] -- register_copy 
    jmp __b1
    // rom_detect::@5
  __b5:
    // rom_device_names[rom_chip] = "f040"
    // [819] rom_device_names[rom_detect::$14] = rom_detect::$29 -- qbuc1_derefidx_vbum1=pbuc2 
    ldy rom_detect__14
    lda #<rom_detect__29
    sta rom_device_names,y
    lda #>rom_detect__29
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "512"
    // [820] rom_size_strings[rom_detect::$14] = rom_detect::$30 -- qbuc1_derefidx_vbum1=pbuc2 
    lda #<rom_detect__30
    sta rom_size_strings,y
    lda #>rom_detect__30
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 512 * 1024
    // [821] rom_detect::$21 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__21
    // [822] rom_sizes[rom_detect::$21] = (unsigned long)$200*$400 -- pduc1_derefidx_vbuz1=vduc2 
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
    // [823] rom_device_names[rom_detect::$14] = rom_detect::$27 -- qbuc1_derefidx_vbum1=pbuc2 
    ldy rom_detect__14
    lda #<rom_detect__27
    sta rom_device_names,y
    lda #>rom_detect__27
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "256"
    // [824] rom_size_strings[rom_detect::$14] = rom_detect::$28 -- qbuc1_derefidx_vbum1=pbuc2 
    lda #<rom_detect__28
    sta rom_size_strings,y
    lda #>rom_detect__28
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 256 * 1024
    // [825] rom_detect::$18 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__18
    // [826] rom_sizes[rom_detect::$18] = (unsigned long)$100*$400 -- pduc1_derefidx_vbuz1=vduc2 
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
    // [827] rom_device_names[rom_detect::$14] = rom_detect::$25 -- qbuc1_derefidx_vbum1=pbuc2 
    ldy rom_detect__14
    lda #<rom_detect__25
    sta rom_device_names,y
    lda #>rom_detect__25
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "128"
    // [828] rom_size_strings[rom_detect::$14] = rom_detect::$26 -- qbuc1_derefidx_vbum1=pbuc2 
    lda #<rom_detect__26
    sta rom_size_strings,y
    lda #>rom_detect__26
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 128 * 1024
    // [829] rom_detect::$15 = rom_detect::rom_chip#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta rom_detect__15
    // [830] rom_sizes[rom_detect::$15] = (unsigned long)$80*$400 -- pduc1_derefidx_vbum1=vduc2 
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
    .label rom_detect__14 = chip_rom.chip_rom__4
    rom_detect__15: .byte 0
    .label rom_chip = main.check_cx16_rom2_check_rom1_main__0
}
.segment Code
  // chip_rom
chip_rom: {
    .label chip_rom__6 = $64
    // [832] phi from chip_rom to chip_rom::@1 [phi:chip_rom->chip_rom::@1]
    // [832] phi chip_rom::r#2 = 0 [phi:chip_rom->chip_rom::@1#0] -- vbum1=vbuc1 
    lda #0
    sta r
    // chip_rom::@1
  __b1:
    // for (unsigned char r = 0; r < 8; r++)
    // [833] if(chip_rom::r#2<8) goto chip_rom::@2 -- vbum1_lt_vbuc1_then_la1 
    lda r
    cmp #8
    bcc __b2
    // chip_rom::@return
    // }
    // [834] return 
    rts
    // [835] phi from chip_rom::@1 to chip_rom::@2 [phi:chip_rom::@1->chip_rom::@2]
    // chip_rom::@2
  __b2:
    // strcpy(rom, "ROM ")
    // [836] call strcpy
    // [1894] phi from chip_rom::@2 to strcpy [phi:chip_rom::@2->strcpy]
    jsr strcpy
    // chip_rom::@5
    // strcat(rom, rom_size_strings[r])
    // [837] chip_rom::$11 = chip_rom::r#2 << 1 -- vbum1=vbum2_rol_1 
    lda r
    asl
    sta chip_rom__11
    // [838] strcat::source#0 = rom_size_strings[chip_rom::$11] -- pbuz1=qbuc1_derefidx_vbum2 
    tay
    lda rom_size_strings,y
    sta.z strcat.source
    lda rom_size_strings+1,y
    sta.z strcat.source+1
    // [839] call strcat
    // [1902] phi from chip_rom::@5 to strcat [phi:chip_rom::@5->strcat]
    jsr strcat
    // chip_rom::@6
    // if(r)
    // [840] if(0==chip_rom::r#2) goto chip_rom::@3 -- 0_eq_vbum1_then_la1 
    lda r
    beq __b3
    // chip_rom::@4
    // r+'0'
    // [841] chip_rom::$4 = chip_rom::r#2 + '0' -- vbum1=vbum2_plus_vbuc1 
    lda #'0'
    clc
    adc r
    sta chip_rom__4
    // *(rom+3) = r+'0'
    // [842] *(chip_rom::rom+3) = chip_rom::$4 -- _deref_pbuc1=vbum1 
    sta rom+3
    // chip_rom::@3
  __b3:
    // print_rom_led(r, GREY)
    // [843] print_rom_led::chip#0 = chip_rom::r#2 -- vbuz1=vbum2 
    lda r
    sta.z print_rom_led.chip
    // [844] call print_rom_led
    // [1914] phi from chip_rom::@3 to print_rom_led [phi:chip_rom::@3->print_rom_led]
    // [1914] phi print_rom_led::c#2 = GREY [phi:chip_rom::@3->print_rom_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z print_rom_led.c
    // [1914] phi print_rom_led::chip#2 = print_rom_led::chip#0 [phi:chip_rom::@3->print_rom_led#1] -- register_copy 
    jsr print_rom_led
    // chip_rom::@7
    // r*6
    // [845] chip_rom::$12 = chip_rom::$11 + chip_rom::r#2 -- vbum1=vbum1_plus_vbum2 
    lda chip_rom__12
    clc
    adc r
    sta chip_rom__12
    // [846] chip_rom::$6 = chip_rom::$12 << 1 -- vbuz1=vbum2_rol_1 
    asl
    sta.z chip_rom__6
    // print_chip(CHIP_ROM_X+r*6, CHIP_ROM_Y+2, CHIP_ROM_W, rom)
    // [847] print_chip::x#2 = $14 + chip_rom::$6 -- vbuz1=vbuc1_plus_vbuz1 
    lda #$14
    clc
    adc.z print_chip.x
    sta.z print_chip.x
    // [848] call print_chip
    // [1761] phi from chip_rom::@7 to print_chip [phi:chip_rom::@7->print_chip]
    // [1761] phi print_chip::text#11 = chip_rom::rom [phi:chip_rom::@7->print_chip#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z print_chip.text_2
    lda #>rom
    sta.z print_chip.text_2+1
    // [1761] phi print_chip::w#10 = 3 [phi:chip_rom::@7->print_chip#1] -- vbuz1=vbuc1 
    lda #3
    sta.z print_chip.w
    // [1761] phi print_chip::x#10 = print_chip::x#2 [phi:chip_rom::@7->print_chip#2] -- register_copy 
    jsr print_chip
    // chip_rom::@8
    // for (unsigned char r = 0; r < 8; r++)
    // [849] chip_rom::r#1 = ++ chip_rom::r#2 -- vbum1=_inc_vbum1 
    inc r
    // [832] phi from chip_rom::@8 to chip_rom::@1 [phi:chip_rom::@8->chip_rom::@1]
    // [832] phi chip_rom::r#2 = chip_rom::r#1 [phi:chip_rom::@8->chip_rom::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    rom: .fill $10, 0
    source: .text "ROM "
    .byte 0
    chip_rom__4: .byte 0
    .label r = main.check_smc4_main__0
    .label chip_rom__11 = wait_key.bram
    .label chip_rom__12 = wait_key.bram
}
.segment Code
  // wait_key
// __mem() char wait_key(__zp($4d) char *info_text, __zp($4f) char *filter)
wait_key: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 0
    .label bank_get_brom1_return = $ad
    .label info_text = $4d
    .label filter = $4f
    // info_line(info_text)
    // [851] info_line::info_text#0 = wait_key::info_text#4
    // [852] call info_line
    // [931] phi from wait_key to info_line [phi:wait_key->info_line]
    // [931] phi info_line::info_text#17 = info_line::info_text#0 [phi:wait_key->info_line#0] -- register_copy 
    jsr info_line
    // wait_key::bank_get_bram1
    // return BRAM;
    // [853] wait_key::bram#0 = BRAM -- vbum1=vbuz2 
    lda.z BRAM
    sta bram
    // wait_key::bank_get_brom1
    // return BROM;
    // [854] wait_key::bank_get_brom1_return#0 = BROM -- vbuz1=vbuz2 
    lda.z BROM
    sta.z bank_get_brom1_return
    // wait_key::bank_set_bram1
    // BRAM = bank
    // [855] BRAM = wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // wait_key::bank_set_brom1
    // BROM = bank
    // [856] BROM = wait_key::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [857] phi from wait_key::@2 wait_key::@5 wait_key::bank_set_brom1 to wait_key::kbhit1 [phi:wait_key::@2/wait_key::@5/wait_key::bank_set_brom1->wait_key::kbhit1]
    // wait_key::kbhit1
  kbhit1:
    // wait_key::kbhit1_cbm_k_clrchn1
    // asm
    // asm { jsrCBM_CLRCHN  }
    jsr CBM_CLRCHN
    // [859] phi from wait_key::kbhit1_cbm_k_clrchn1 to wait_key::kbhit1_@2 [phi:wait_key::kbhit1_cbm_k_clrchn1->wait_key::kbhit1_@2]
    // wait_key::kbhit1_@2
    // cbm_k_getin()
    // [860] call cbm_k_getin
    jsr cbm_k_getin
    // [861] cbm_k_getin::return#2 = cbm_k_getin::return#1
    // wait_key::@4
    // [862] wait_key::ch#4 = cbm_k_getin::return#2 -- vwum1=vbuz2 
    lda.z cbm_k_getin.return
    sta ch
    lda #0
    sta ch+1
    // wait_key::@3
    // if (filter)
    // [863] if((char *)0!=wait_key::filter#14) goto wait_key::@1 -- pbuc1_neq_pbuz1_then_la1 
    // if there is a filter, check the filter, otherwise return ch.
    lda.z filter+1
    cmp #>0
    bne __b1
    lda.z filter
    cmp #<0
    bne __b1
    // wait_key::@2
    // if(ch)
    // [864] if(0!=wait_key::ch#4) goto wait_key::bank_set_bram2 -- 0_neq_vwum1_then_la1 
    lda ch
    ora ch+1
    bne bank_set_bram2
    jmp kbhit1
    // wait_key::bank_set_bram2
  bank_set_bram2:
    // BRAM = bank
    // [865] BRAM = wait_key::bram#0 -- vbuz1=vbum2 
    lda bram
    sta.z BRAM
    // wait_key::bank_set_brom2
    // BROM = bank
    // [866] BROM = wait_key::bank_get_brom1_return#0 -- vbuz1=vbuz2 
    lda.z bank_get_brom1_return
    sta.z BROM
    // wait_key::@return
    // }
    // [867] return 
    rts
    // wait_key::@1
  __b1:
    // strchr(filter, ch)
    // [868] strchr::str#0 = (const void *)wait_key::filter#14 -- pvom1=pvoz2 
    lda.z filter
    sta strchr.str
    lda.z filter+1
    sta strchr.str+1
    // [869] strchr::c#0 = wait_key::ch#4 -- vbum1=vwum2 
    lda ch
    sta strchr.c
    // [870] call strchr
    // [1485] phi from wait_key::@1 to strchr [phi:wait_key::@1->strchr]
    // [1485] phi strchr::c#4 = strchr::c#0 [phi:wait_key::@1->strchr#0] -- register_copy 
    // [1485] phi strchr::str#2 = strchr::str#0 [phi:wait_key::@1->strchr#1] -- register_copy 
    jsr strchr
    // strchr(filter, ch)
    // [871] strchr::return#3 = strchr::return#2
    // wait_key::@5
    // [872] wait_key::$9 = strchr::return#3
    // if(strchr(filter, ch) != NULL)
    // [873] if(wait_key::$9!=0) goto wait_key::bank_set_bram2 -- pvom1_neq_0_then_la1 
    lda wait_key__9
    ora wait_key__9+1
    bne bank_set_bram2
    jmp kbhit1
  .segment Data
    .label wait_key__9 = strchr.str
    bram: .byte 0
    .label return = strchr.c
    .label ch = rom_read.fp
}
.segment Code
  // smc_read
// __mem() unsigned int smc_read(char b, unsigned int progress_row_size)
smc_read: {
    .label fp = $ba
    .label smc_file_read = $ae
    .label y = $e0
    // info_progress("Reading SMC.BIN ... (.) data, ( ) empty")
    // [875] call info_progress
  // It is assume that one RAM bank is 0X2000 bytes.
    // [666] phi from smc_read to info_progress [phi:smc_read->info_progress]
    // [666] phi info_progress::info_text#14 = smc_read::info_text [phi:smc_read->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_progress.info_text
    lda #>info_text
    sta.z info_progress.info_text+1
    jsr info_progress
    // [876] phi from smc_read to smc_read::@7 [phi:smc_read->smc_read::@7]
    // smc_read::@7
    // textcolor(WHITE)
    // [877] call textcolor
    // [539] phi from smc_read::@7 to textcolor [phi:smc_read::@7->textcolor]
    // [539] phi textcolor::color#18 = WHITE [phi:smc_read::@7->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [878] phi from smc_read::@7 to smc_read::@8 [phi:smc_read::@7->smc_read::@8]
    // smc_read::@8
    // gotoxy(x, y)
    // [879] call gotoxy
    // [557] phi from smc_read::@8 to gotoxy [phi:smc_read::@8->gotoxy]
    // [557] phi gotoxy::y#30 = PROGRESS_Y [phi:smc_read::@8->gotoxy#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z gotoxy.y
    // [557] phi gotoxy::x#30 = PROGRESS_X [phi:smc_read::@8->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [880] phi from smc_read::@8 to smc_read::@9 [phi:smc_read::@8->smc_read::@9]
    // smc_read::@9
    // FILE *fp = fopen("SMC.BIN", "r")
    // [881] call fopen
    // [1930] phi from smc_read::@9 to fopen [phi:smc_read::@9->fopen]
    // [1930] phi __errno#312 = __errno#35 [phi:smc_read::@9->fopen#0] -- register_copy 
    // [1930] phi fopen::pathtoken#0 = smc_read::path [phi:smc_read::@9->fopen#1] -- pbuz1=pbuc1 
    lda #<path
    sta.z fopen.pathtoken
    lda #>path
    sta.z fopen.pathtoken+1
    jsr fopen
    // FILE *fp = fopen("SMC.BIN", "r")
    // [882] fopen::return#3 = fopen::return#2
    // smc_read::@10
    // [883] smc_read::fp#0 = fopen::return#3 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [884] if((struct $2 *)0==smc_read::fp#0) goto smc_read::@1 -- pssc1_eq_pssz1_then_la1 
    lda.z fp
    cmp #<0
    bne !+
    lda.z fp+1
    cmp #>0
    beq __b4
  !:
    // [885] phi from smc_read::@10 to smc_read::@2 [phi:smc_read::@10->smc_read::@2]
    // [885] phi smc_read::y#10 = PROGRESS_Y [phi:smc_read::@10->smc_read::@2#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // [885] phi smc_read::progress_row_bytes#10 = 0 [phi:smc_read::@10->smc_read::@2#1] -- vwum1=vwuc1 
    lda #<0
    sta progress_row_bytes
    sta progress_row_bytes+1
    // [885] phi smc_read::smc_file_size#11 = 0 [phi:smc_read::@10->smc_read::@2#2] -- vwum1=vwuc1 
    sta smc_file_size
    sta smc_file_size+1
    // [885] phi smc_read::ram_address#10 = (char *)$6000 [phi:smc_read::@10->smc_read::@2#3] -- pbum1=pbuc1 
    lda #<$6000
    sta ram_address
    lda #>$6000
    sta ram_address+1
  // We read b bytes at a time, and each b bytes we plot a dot.
  // Every r bytes we move to the next line.
    // smc_read::@2
  __b2:
    // fgets(ram_address, b, fp)
    // [886] fgets::ptr#2 = smc_read::ram_address#10 -- pbuz1=pbum2 
    lda ram_address
    sta.z fgets.ptr
    lda ram_address+1
    sta.z fgets.ptr+1
    // [887] fgets::stream#0 = smc_read::fp#0 -- pssm1=pssz2 
    lda.z fp
    sta fgets.stream
    lda.z fp+1
    sta fgets.stream+1
    // [888] call fgets
    // [2011] phi from smc_read::@2 to fgets [phi:smc_read::@2->fgets]
    // [2011] phi fgets::ptr#12 = fgets::ptr#2 [phi:smc_read::@2->fgets#0] -- register_copy 
    // [2011] phi fgets::size#10 = 8 [phi:smc_read::@2->fgets#1] -- vwuz1=vbuc1 
    lda #<8
    sta.z fgets.size
    lda #>8
    sta.z fgets.size+1
    // [2011] phi fgets::stream#2 = fgets::stream#0 [phi:smc_read::@2->fgets#2] -- register_copy 
    jsr fgets
    // fgets(ram_address, b, fp)
    // [889] fgets::return#5 = fgets::return#1
    // smc_read::@11
    // smc_file_read = fgets(ram_address, b, fp)
    // [890] smc_read::smc_file_read#1 = fgets::return#5
    // while (smc_file_read = fgets(ram_address, b, fp))
    // [891] if(0!=smc_read::smc_file_read#1) goto smc_read::@3 -- 0_neq_vwuz1_then_la1 
    lda.z smc_file_read
    ora.z smc_file_read+1
    bne __b3
    // smc_read::@4
    // fclose(fp)
    // [892] fclose::stream#0 = smc_read::fp#0
    // [893] call fclose
    // [2065] phi from smc_read::@4 to fclose [phi:smc_read::@4->fclose]
    // [2065] phi fclose::stream#2 = fclose::stream#0 [phi:smc_read::@4->fclose#0] -- register_copy 
    jsr fclose
    // [894] phi from smc_read::@4 to smc_read::@1 [phi:smc_read::@4->smc_read::@1]
    // [894] phi smc_read::return#0 = smc_read::smc_file_size#11 [phi:smc_read::@4->smc_read::@1#0] -- register_copy 
    rts
    // [894] phi from smc_read::@10 to smc_read::@1 [phi:smc_read::@10->smc_read::@1]
  __b4:
    // [894] phi smc_read::return#0 = 0 [phi:smc_read::@10->smc_read::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta return
    sta return+1
    // smc_read::@1
    // smc_read::@return
    // }
    // [895] return 
    rts
    // [896] phi from smc_read::@11 to smc_read::@3 [phi:smc_read::@11->smc_read::@3]
    // smc_read::@3
  __b3:
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [897] call snprintf_init
    jsr snprintf_init
    // [898] phi from smc_read::@3 to smc_read::@12 [phi:smc_read::@3->smc_read::@12]
    // smc_read::@12
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [899] call printf_str
    // [700] phi from smc_read::@12 to printf_str [phi:smc_read::@12->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:smc_read::@12->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = smc_read::s [phi:smc_read::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@13
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [900] printf_uint::uvalue#1 = smc_read::smc_file_read#1 -- vwuz1=vwuz2 
    lda.z smc_file_read
    sta.z printf_uint.uvalue
    lda.z smc_file_read+1
    sta.z printf_uint.uvalue+1
    // [901] call printf_uint
    // [709] phi from smc_read::@13 to printf_uint [phi:smc_read::@13->printf_uint]
    // [709] phi printf_uint::format_zero_padding#16 = 1 [phi:smc_read::@13->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [709] phi printf_uint::format_min_length#16 = 5 [phi:smc_read::@13->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [709] phi printf_uint::putc#16 = &snputc [phi:smc_read::@13->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [709] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:smc_read::@13->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [709] phi printf_uint::uvalue#16 = printf_uint::uvalue#1 [phi:smc_read::@13->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [902] phi from smc_read::@13 to smc_read::@14 [phi:smc_read::@13->smc_read::@14]
    // smc_read::@14
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [903] call printf_str
    // [700] phi from smc_read::@14 to printf_str [phi:smc_read::@14->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:smc_read::@14->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = s4 [phi:smc_read::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@15
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [904] printf_uint::uvalue#2 = smc_read::smc_file_size#11 -- vwuz1=vwum2 
    lda smc_file_size
    sta.z printf_uint.uvalue
    lda smc_file_size+1
    sta.z printf_uint.uvalue+1
    // [905] call printf_uint
    // [709] phi from smc_read::@15 to printf_uint [phi:smc_read::@15->printf_uint]
    // [709] phi printf_uint::format_zero_padding#16 = 1 [phi:smc_read::@15->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [709] phi printf_uint::format_min_length#16 = 5 [phi:smc_read::@15->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [709] phi printf_uint::putc#16 = &snputc [phi:smc_read::@15->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [709] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:smc_read::@15->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [709] phi printf_uint::uvalue#16 = printf_uint::uvalue#2 [phi:smc_read::@15->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [906] phi from smc_read::@15 to smc_read::@16 [phi:smc_read::@15->smc_read::@16]
    // smc_read::@16
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [907] call printf_str
    // [700] phi from smc_read::@16 to printf_str [phi:smc_read::@16->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:smc_read::@16->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = s2 [phi:smc_read::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // [908] phi from smc_read::@16 to smc_read::@17 [phi:smc_read::@16->smc_read::@17]
    // smc_read::@17
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [909] call printf_uint
    // [709] phi from smc_read::@17 to printf_uint [phi:smc_read::@17->printf_uint]
    // [709] phi printf_uint::format_zero_padding#16 = 1 [phi:smc_read::@17->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [709] phi printf_uint::format_min_length#16 = 2 [phi:smc_read::@17->printf_uint#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uint.format_min_length
    // [709] phi printf_uint::putc#16 = &snputc [phi:smc_read::@17->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [709] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:smc_read::@17->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [709] phi printf_uint::uvalue#16 = 0 [phi:smc_read::@17->printf_uint#4] -- vwuz1=vbuc1 
    lda #<0
    sta.z printf_uint.uvalue
    sta.z printf_uint.uvalue+1
    jsr printf_uint
    // [910] phi from smc_read::@17 to smc_read::@18 [phi:smc_read::@17->smc_read::@18]
    // smc_read::@18
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [911] call printf_str
    // [700] phi from smc_read::@18 to printf_str [phi:smc_read::@18->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:smc_read::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = s3 [phi:smc_read::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@19
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [912] printf_uint::uvalue#4 = (unsigned int)smc_read::ram_address#10 -- vwuz1=vwum2 
    lda ram_address
    sta.z printf_uint.uvalue
    lda ram_address+1
    sta.z printf_uint.uvalue+1
    // [913] call printf_uint
    // [709] phi from smc_read::@19 to printf_uint [phi:smc_read::@19->printf_uint]
    // [709] phi printf_uint::format_zero_padding#16 = 1 [phi:smc_read::@19->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [709] phi printf_uint::format_min_length#16 = 4 [phi:smc_read::@19->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [709] phi printf_uint::putc#16 = &snputc [phi:smc_read::@19->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [709] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:smc_read::@19->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [709] phi printf_uint::uvalue#16 = printf_uint::uvalue#4 [phi:smc_read::@19->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [914] phi from smc_read::@19 to smc_read::@20 [phi:smc_read::@19->smc_read::@20]
    // smc_read::@20
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [915] call printf_str
    // [700] phi from smc_read::@20 to printf_str [phi:smc_read::@20->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:smc_read::@20->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = s7 [phi:smc_read::@20->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@21
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [916] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [917] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [919] call info_line
    // [931] phi from smc_read::@21 to info_line [phi:smc_read::@21->info_line]
    // [931] phi info_line::info_text#17 = info_text [phi:smc_read::@21->info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_line.info_text
    lda #>@info_text
    sta.z info_line.info_text+1
    jsr info_line
    // smc_read::@22
    // if (progress_row_bytes == progress_row_size)
    // [920] if(smc_read::progress_row_bytes#10!=$200) goto smc_read::@5 -- vwum1_neq_vwuc1_then_la1 
    lda progress_row_bytes+1
    cmp #>$200
    bne __b5
    lda progress_row_bytes
    cmp #<$200
    bne __b5
    // smc_read::@6
    // gotoxy(x, ++y);
    // [921] smc_read::y#1 = ++ smc_read::y#10 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [922] gotoxy::y#20 = smc_read::y#1 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [923] call gotoxy
    // [557] phi from smc_read::@6 to gotoxy [phi:smc_read::@6->gotoxy]
    // [557] phi gotoxy::y#30 = gotoxy::y#20 [phi:smc_read::@6->gotoxy#0] -- register_copy 
    // [557] phi gotoxy::x#30 = PROGRESS_X [phi:smc_read::@6->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [924] phi from smc_read::@6 to smc_read::@5 [phi:smc_read::@6->smc_read::@5]
    // [924] phi smc_read::y#20 = smc_read::y#1 [phi:smc_read::@6->smc_read::@5#0] -- register_copy 
    // [924] phi smc_read::progress_row_bytes#4 = 0 [phi:smc_read::@6->smc_read::@5#1] -- vwum1=vbuc1 
    lda #<0
    sta progress_row_bytes
    sta progress_row_bytes+1
    // [924] phi from smc_read::@22 to smc_read::@5 [phi:smc_read::@22->smc_read::@5]
    // [924] phi smc_read::y#20 = smc_read::y#10 [phi:smc_read::@22->smc_read::@5#0] -- register_copy 
    // [924] phi smc_read::progress_row_bytes#4 = smc_read::progress_row_bytes#10 [phi:smc_read::@22->smc_read::@5#1] -- register_copy 
    // smc_read::@5
  __b5:
    // cputc('.')
    // [925] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [926] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // ram_address += smc_file_read
    // [928] smc_read::ram_address#1 = smc_read::ram_address#10 + smc_read::smc_file_read#1 -- pbum1=pbum1_plus_vwuz2 
    clc
    lda ram_address
    adc.z smc_file_read
    sta ram_address
    lda ram_address+1
    adc.z smc_file_read+1
    sta ram_address+1
    // smc_file_size += smc_file_read
    // [929] smc_read::smc_file_size#1 = smc_read::smc_file_size#11 + smc_read::smc_file_read#1 -- vwum1=vwum1_plus_vwuz2 
    clc
    lda smc_file_size
    adc.z smc_file_read
    sta smc_file_size
    lda smc_file_size+1
    adc.z smc_file_read+1
    sta smc_file_size+1
    // progress_row_bytes += smc_file_read
    // [930] smc_read::progress_row_bytes#1 = smc_read::progress_row_bytes#4 + smc_read::smc_file_read#1 -- vwum1=vwum1_plus_vwuz2 
    clc
    lda progress_row_bytes
    adc.z smc_file_read
    sta progress_row_bytes
    lda progress_row_bytes+1
    adc.z smc_file_read+1
    sta progress_row_bytes+1
    // [885] phi from smc_read::@5 to smc_read::@2 [phi:smc_read::@5->smc_read::@2]
    // [885] phi smc_read::y#10 = smc_read::y#20 [phi:smc_read::@5->smc_read::@2#0] -- register_copy 
    // [885] phi smc_read::progress_row_bytes#10 = smc_read::progress_row_bytes#1 [phi:smc_read::@5->smc_read::@2#1] -- register_copy 
    // [885] phi smc_read::smc_file_size#11 = smc_read::smc_file_size#1 [phi:smc_read::@5->smc_read::@2#2] -- register_copy 
    // [885] phi smc_read::ram_address#10 = smc_read::ram_address#1 [phi:smc_read::@5->smc_read::@2#3] -- register_copy 
    jmp __b2
  .segment Data
    info_text: .text "Reading SMC.BIN ... (.) data, ( ) empty"
    .byte 0
    path: .text "SMC.BIN"
    .byte 0
    s: .text "Reading SMC.BIN:"
    .byte 0
    .label return = strcpy.src
    .label ram_address = clrscr.ch
    .label smc_file_size = strcpy.src
    /// Holds the amount of bytes actually read in the memory to be flashed.
    .label progress_row_bytes = strcpy.dst
}
.segment Code
  // info_line
// void info_line(__zp($4d) char *info_text)
info_line: {
    .label info_text = $4d
    .label x = $e7
    .label y = $e5
    // unsigned char x = wherex()
    // [932] call wherex
    jsr wherex
    // [933] wherex::return#3 = wherex::return#0 -- vbuz1=vbuz2 
    lda.z wherex.return
    sta.z wherex.return_1
    // info_line::@1
    // [934] info_line::x#0 = wherex::return#3
    // unsigned char y = wherey()
    // [935] call wherey
    jsr wherey
    // [936] wherey::return#3 = wherey::return#0 -- vbuz1=vbuz2 
    lda.z wherey.return
    sta.z wherey.return_1
    // info_line::@2
    // [937] info_line::y#0 = wherey::return#3
    // gotoxy(2, PROGRESS_Y-3)
    // [938] call gotoxy
    // [557] phi from info_line::@2 to gotoxy [phi:info_line::@2->gotoxy]
    // [557] phi gotoxy::y#30 = PROGRESS_Y-3 [phi:info_line::@2->gotoxy#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-3
    sta.z gotoxy.y
    // [557] phi gotoxy::x#30 = 2 [phi:info_line::@2->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // info_line::@3
    // printf("%-65s", info_text)
    // [939] printf_string::str#2 = info_line::info_text#17 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [940] call printf_string
    // [1184] phi from info_line::@3 to printf_string [phi:info_line::@3->printf_string]
    // [1184] phi printf_string::putc#18 = &cputc [phi:info_line::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1184] phi printf_string::str#18 = printf_string::str#2 [phi:info_line::@3->printf_string#1] -- register_copy 
    // [1184] phi printf_string::format_justify_left#18 = 1 [phi:info_line::@3->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1184] phi printf_string::format_min_length#18 = $41 [phi:info_line::@3->printf_string#3] -- vbuz1=vbuc1 
    lda #$41
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_line::@4
    // gotoxy(x, y)
    // [941] gotoxy::x#12 = info_line::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [942] gotoxy::y#12 = info_line::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [943] call gotoxy
    // [557] phi from info_line::@4 to gotoxy [phi:info_line::@4->gotoxy]
    // [557] phi gotoxy::y#30 = gotoxy::y#12 [phi:info_line::@4->gotoxy#0] -- register_copy 
    // [557] phi gotoxy::x#30 = gotoxy::x#12 [phi:info_line::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // info_line::@return
    // }
    // [944] return 
    rts
}
  // flash_smc
// __zp($5e) unsigned int flash_smc(char x, __mem() char y, char w, __zp($3f) unsigned int smc_bytes_total, char b, unsigned int smc_row_total, __zp($cf) char *smc_ram_ptr)
flash_smc: {
    .const smc_row_total = $200
    .label cx16_k_i2c_write_byte1_return = $2f
    .label smc_bootloader_start = $2f
    .label return = $5e
    .label smc_bootloader_not_activated1 = $2d
    // Waiting a bit to ensure the bootloader is activated.
    .label smc_bootloader_activation_countdown_1 = $df
    .label smc_bootloader_not_activated = $2d
    .label smc_byte_upload = $ad
    .label smc_ram_ptr = $cf
    .label smc_package_flashed = $60
    .label smc_commit_result = $2d
    .label smc_attempts_flashed = $bf
    .label smc_bytes_flashed = $5e
    .label smc_attempts_total = $d5
    .label smc_bytes_total = $3f
    // info_progress("To start the SMC update, do the below action ...")
    // [946] call info_progress
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
    // [666] phi from flash_smc to info_progress [phi:flash_smc->info_progress]
    // [666] phi info_progress::info_text#14 = flash_smc::info_text [phi:flash_smc->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_progress.info_text
    lda #>info_text
    sta.z info_progress.info_text+1
    jsr info_progress
    // flash_smc::@26
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [947] flash_smc::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [948] flash_smc::cx16_k_i2c_write_byte1_offset = $8f -- vbum1=vbuc1 
    lda #$8f
    sta cx16_k_i2c_write_byte1_offset
    // [949] flash_smc::cx16_k_i2c_write_byte1_value = $31 -- vbum1=vbuc1 
    lda #$31
    sta cx16_k_i2c_write_byte1_value
    // flash_smc::cx16_k_i2c_write_byte1
    // unsigned char result
    // [950] flash_smc::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
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
    // [952] flash_smc::cx16_k_i2c_write_byte1_return#0 = flash_smc::cx16_k_i2c_write_byte1_result -- vbuz1=vbum2 
    lda cx16_k_i2c_write_byte1_result
    sta.z cx16_k_i2c_write_byte1_return
    // flash_smc::cx16_k_i2c_write_byte1_@return
    // }
    // [953] flash_smc::cx16_k_i2c_write_byte1_return#1 = flash_smc::cx16_k_i2c_write_byte1_return#0
    // flash_smc::@23
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [954] flash_smc::smc_bootloader_start#0 = flash_smc::cx16_k_i2c_write_byte1_return#1
    // if(smc_bootloader_start)
    // [955] if(0==flash_smc::smc_bootloader_start#0) goto flash_smc::@3 -- 0_eq_vbuz1_then_la1 
    lda.z smc_bootloader_start
    beq __b6
    // [956] phi from flash_smc::@23 to flash_smc::@2 [phi:flash_smc::@23->flash_smc::@2]
    // flash_smc::@2
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [957] call snprintf_init
    jsr snprintf_init
    // [958] phi from flash_smc::@2 to flash_smc::@27 [phi:flash_smc::@2->flash_smc::@27]
    // flash_smc::@27
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [959] call printf_str
    // [700] phi from flash_smc::@27 to printf_str [phi:flash_smc::@27->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:flash_smc::@27->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = flash_smc::s [phi:flash_smc::@27->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@28
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [960] printf_uchar::uvalue#1 = flash_smc::smc_bootloader_start#0
    // [961] call printf_uchar
    // [1122] phi from flash_smc::@28 to printf_uchar [phi:flash_smc::@28->printf_uchar]
    // [1122] phi printf_uchar::format_zero_padding#10 = 0 [phi:flash_smc::@28->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1122] phi printf_uchar::format_min_length#10 = 0 [phi:flash_smc::@28->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1122] phi printf_uchar::putc#10 = &snputc [phi:flash_smc::@28->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1122] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:flash_smc::@28->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [1122] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#1 [phi:flash_smc::@28->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // flash_smc::@29
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [962] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [963] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [965] call info_line
    // [931] phi from flash_smc::@29 to info_line [phi:flash_smc::@29->info_line]
    // [931] phi info_line::info_text#17 = info_text [phi:flash_smc::@29->info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_line.info_text
    lda #>@info_text
    sta.z info_line.info_text+1
    jsr info_line
    // flash_smc::@30
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [966] flash_smc::cx16_k_i2c_write_byte2_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte2_device
    // [967] flash_smc::cx16_k_i2c_write_byte2_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte2_offset
    // [968] flash_smc::cx16_k_i2c_write_byte2_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte2_value
    // flash_smc::cx16_k_i2c_write_byte2
    // unsigned char result
    // [969] flash_smc::cx16_k_i2c_write_byte2_result = 0 -- vbum1=vbuc1 
    sta cx16_k_i2c_write_byte2_result
    // asm
    // asm { ldxdevice ldyoffset ldavalue stzresult jsrCX16_I2C_WRITE_BYTE rolresult  }
    ldx cx16_k_i2c_write_byte2_device
    ldy cx16_k_i2c_write_byte2_offset
    lda cx16_k_i2c_write_byte2_value
    stz cx16_k_i2c_write_byte2_result
    jsr CX16_I2C_WRITE_BYTE
    rol cx16_k_i2c_write_byte2_result
    // [971] phi from flash_smc::@48 flash_smc::@60 flash_smc::cx16_k_i2c_write_byte2 to flash_smc::@return [phi:flash_smc::@48/flash_smc::@60/flash_smc::cx16_k_i2c_write_byte2->flash_smc::@return]
  __b2:
    // [971] phi flash_smc::return#1 = 0 [phi:flash_smc::@48/flash_smc::@60/flash_smc::cx16_k_i2c_write_byte2->flash_smc::@return#0] -- vwuz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // flash_smc::@return
    // }
    // [972] return 
    rts
    // [973] phi from flash_smc::@23 to flash_smc::@3 [phi:flash_smc::@23->flash_smc::@3]
  __b6:
    // [973] phi flash_smc::smc_bootloader_activation_countdown#10 = $3c [phi:flash_smc::@23->flash_smc::@3#0] -- vbum1=vbuc1 
    lda #$3c
    sta smc_bootloader_activation_countdown
    // flash_smc::@3
  __b3:
    // while(smc_bootloader_activation_countdown)
    // [974] if(0!=flash_smc::smc_bootloader_activation_countdown#10) goto flash_smc::@4 -- 0_neq_vbum1_then_la1 
    lda smc_bootloader_activation_countdown
    beq !__b4+
    jmp __b4
  !__b4:
    // [975] phi from flash_smc::@3 flash_smc::@31 to flash_smc::@7 [phi:flash_smc::@3/flash_smc::@31->flash_smc::@7]
  __b9:
    // [975] phi flash_smc::smc_bootloader_activation_countdown#12 = $a [phi:flash_smc::@3/flash_smc::@31->flash_smc::@7#0] -- vbuz1=vbuc1 
    lda #$a
    sta.z smc_bootloader_activation_countdown_1
    // flash_smc::@7
  __b7:
    // while(smc_bootloader_activation_countdown)
    // [976] if(0!=flash_smc::smc_bootloader_activation_countdown#12) goto flash_smc::@8 -- 0_neq_vbuz1_then_la1 
    lda.z smc_bootloader_activation_countdown_1
    beq !__b8+
    jmp __b8
  !__b8:
    // flash_smc::@9
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [977] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [978] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [979] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [980] cx16_k_i2c_read_byte::return#3 = cx16_k_i2c_read_byte::return#1
    // flash_smc::@43
    // smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [981] flash_smc::smc_bootloader_not_activated#1 = cx16_k_i2c_read_byte::return#3
    // if(smc_bootloader_not_activated)
    // [982] if(0==flash_smc::smc_bootloader_not_activated#1) goto flash_smc::@1 -- 0_eq_vwuz1_then_la1 
    lda.z smc_bootloader_not_activated
    ora.z smc_bootloader_not_activated+1
    beq __b1
    // [983] phi from flash_smc::@43 to flash_smc::@10 [phi:flash_smc::@43->flash_smc::@10]
    // flash_smc::@10
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [984] call snprintf_init
    jsr snprintf_init
    // [985] phi from flash_smc::@10 to flash_smc::@46 [phi:flash_smc::@10->flash_smc::@46]
    // flash_smc::@46
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [986] call printf_str
    // [700] phi from flash_smc::@46 to printf_str [phi:flash_smc::@46->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:flash_smc::@46->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = flash_smc::s5 [phi:flash_smc::@46->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@47
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [987] printf_uint::uvalue#5 = flash_smc::smc_bootloader_not_activated#1
    // [988] call printf_uint
    // [709] phi from flash_smc::@47 to printf_uint [phi:flash_smc::@47->printf_uint]
    // [709] phi printf_uint::format_zero_padding#16 = 0 [phi:flash_smc::@47->printf_uint#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uint.format_zero_padding
    // [709] phi printf_uint::format_min_length#16 = 0 [phi:flash_smc::@47->printf_uint#1] -- vbuz1=vbuc1 
    sta.z printf_uint.format_min_length
    // [709] phi printf_uint::putc#16 = &snputc [phi:flash_smc::@47->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [709] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:flash_smc::@47->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [709] phi printf_uint::uvalue#16 = printf_uint::uvalue#5 [phi:flash_smc::@47->printf_uint#4] -- register_copy 
    jsr printf_uint
    // flash_smc::@48
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [989] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [990] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [992] call info_line
    // [931] phi from flash_smc::@48 to info_line [phi:flash_smc::@48->info_line]
    // [931] phi info_line::info_text#17 = info_text [phi:flash_smc::@48->info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_line.info_text
    lda #>@info_text
    sta.z info_line.info_text+1
    jsr info_line
    jmp __b2
    // [993] phi from flash_smc::@43 to flash_smc::@1 [phi:flash_smc::@43->flash_smc::@1]
    // flash_smc::@1
  __b1:
    // info_progress("Updating SMC firmware ... (+) Updated")
    // [994] call info_progress
    // [666] phi from flash_smc::@1 to info_progress [phi:flash_smc::@1->info_progress]
    // [666] phi info_progress::info_text#14 = flash_smc::info_text1 [phi:flash_smc::@1->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z info_progress.info_text
    lda #>info_text1
    sta.z info_progress.info_text+1
    jsr info_progress
    // [995] phi from flash_smc::@1 to flash_smc::@44 [phi:flash_smc::@1->flash_smc::@44]
    // flash_smc::@44
    // textcolor(WHITE)
    // [996] call textcolor
    // [539] phi from flash_smc::@44 to textcolor [phi:flash_smc::@44->textcolor]
    // [539] phi textcolor::color#18 = WHITE [phi:flash_smc::@44->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [997] phi from flash_smc::@44 to flash_smc::@45 [phi:flash_smc::@44->flash_smc::@45]
    // flash_smc::@45
    // gotoxy(x, y)
    // [998] call gotoxy
    // [557] phi from flash_smc::@45 to gotoxy [phi:flash_smc::@45->gotoxy]
    // [557] phi gotoxy::y#30 = PROGRESS_Y [phi:flash_smc::@45->gotoxy#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z gotoxy.y
    // [557] phi gotoxy::x#30 = PROGRESS_X [phi:flash_smc::@45->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [999] phi from flash_smc::@45 to flash_smc::@11 [phi:flash_smc::@45->flash_smc::@11]
    // [999] phi flash_smc::y#31 = PROGRESS_Y [phi:flash_smc::@45->flash_smc::@11#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [999] phi flash_smc::smc_attempts_total#21 = 0 [phi:flash_smc::@45->flash_smc::@11#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z smc_attempts_total
    sta.z smc_attempts_total+1
    // [999] phi flash_smc::smc_row_bytes#14 = 0 [phi:flash_smc::@45->flash_smc::@11#2] -- vwum1=vwuc1 
    sta smc_row_bytes
    sta smc_row_bytes+1
    // [999] phi flash_smc::smc_ram_ptr#13 = (char *)$6000 [phi:flash_smc::@45->flash_smc::@11#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z smc_ram_ptr
    lda #>$6000
    sta.z smc_ram_ptr+1
    // [999] phi flash_smc::smc_bytes_flashed#13 = 0 [phi:flash_smc::@45->flash_smc::@11#4] -- vwuz1=vwuc1 
    lda #<0
    sta.z smc_bytes_flashed
    sta.z smc_bytes_flashed+1
    // [999] phi from flash_smc::@14 to flash_smc::@11 [phi:flash_smc::@14->flash_smc::@11]
    // [999] phi flash_smc::y#31 = flash_smc::y#20 [phi:flash_smc::@14->flash_smc::@11#0] -- register_copy 
    // [999] phi flash_smc::smc_attempts_total#21 = flash_smc::smc_attempts_total#17 [phi:flash_smc::@14->flash_smc::@11#1] -- register_copy 
    // [999] phi flash_smc::smc_row_bytes#14 = flash_smc::smc_row_bytes#10 [phi:flash_smc::@14->flash_smc::@11#2] -- register_copy 
    // [999] phi flash_smc::smc_ram_ptr#13 = flash_smc::smc_ram_ptr#10 [phi:flash_smc::@14->flash_smc::@11#3] -- register_copy 
    // [999] phi flash_smc::smc_bytes_flashed#13 = flash_smc::smc_bytes_flashed#12 [phi:flash_smc::@14->flash_smc::@11#4] -- register_copy 
    // flash_smc::@11
  __b11:
    // while(smc_bytes_flashed < smc_bytes_total)
    // [1000] if(flash_smc::smc_bytes_flashed#13<flash_smc::smc_bytes_total#0) goto flash_smc::@13 -- vwuz1_lt_vwuz2_then_la1 
    lda.z smc_bytes_flashed+1
    cmp.z smc_bytes_total+1
    bcc __b10
    bne !+
    lda.z smc_bytes_flashed
    cmp.z smc_bytes_total
    bcc __b10
  !:
    // flash_smc::@12
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [1001] flash_smc::cx16_k_i2c_write_byte3_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte3_device
    // [1002] flash_smc::cx16_k_i2c_write_byte3_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte3_offset
    // [1003] flash_smc::cx16_k_i2c_write_byte3_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte3_value
    // flash_smc::cx16_k_i2c_write_byte3
    // unsigned char result
    // [1004] flash_smc::cx16_k_i2c_write_byte3_result = 0 -- vbum1=vbuc1 
    sta cx16_k_i2c_write_byte3_result
    // asm
    // asm { ldxdevice ldyoffset ldavalue stzresult jsrCX16_I2C_WRITE_BYTE rolresult  }
    ldx cx16_k_i2c_write_byte3_device
    ldy cx16_k_i2c_write_byte3_offset
    lda cx16_k_i2c_write_byte3_value
    stz cx16_k_i2c_write_byte3_result
    jsr CX16_I2C_WRITE_BYTE
    rol cx16_k_i2c_write_byte3_result
    // [971] phi from flash_smc::cx16_k_i2c_write_byte3 to flash_smc::@return [phi:flash_smc::cx16_k_i2c_write_byte3->flash_smc::@return]
    // [971] phi flash_smc::return#1 = flash_smc::smc_bytes_flashed#13 [phi:flash_smc::cx16_k_i2c_write_byte3->flash_smc::@return#0] -- register_copy 
    rts
    // [1006] phi from flash_smc::@11 to flash_smc::@13 [phi:flash_smc::@11->flash_smc::@13]
  __b10:
    // [1006] phi flash_smc::y#20 = flash_smc::y#31 [phi:flash_smc::@11->flash_smc::@13#0] -- register_copy 
    // [1006] phi flash_smc::smc_attempts_total#17 = flash_smc::smc_attempts_total#21 [phi:flash_smc::@11->flash_smc::@13#1] -- register_copy 
    // [1006] phi flash_smc::smc_row_bytes#10 = flash_smc::smc_row_bytes#14 [phi:flash_smc::@11->flash_smc::@13#2] -- register_copy 
    // [1006] phi flash_smc::smc_ram_ptr#10 = flash_smc::smc_ram_ptr#13 [phi:flash_smc::@11->flash_smc::@13#3] -- register_copy 
    // [1006] phi flash_smc::smc_bytes_flashed#12 = flash_smc::smc_bytes_flashed#13 [phi:flash_smc::@11->flash_smc::@13#4] -- register_copy 
    // [1006] phi flash_smc::smc_attempts_flashed#19 = 0 [phi:flash_smc::@11->flash_smc::@13#5] -- vbuz1=vbuc1 
    lda #0
    sta.z smc_attempts_flashed
    // [1006] phi flash_smc::smc_package_committed#2 = 0 [phi:flash_smc::@11->flash_smc::@13#6] -- vbum1=vbuc1 
    sta smc_package_committed
    // flash_smc::@13
  __b13:
    // while(!smc_package_committed && smc_attempts_flashed < 10)
    // [1007] if(0!=flash_smc::smc_package_committed#2) goto flash_smc::@14 -- 0_neq_vbum1_then_la1 
    lda smc_package_committed
    bne __b14
    // flash_smc::@61
    // [1008] if(flash_smc::smc_attempts_flashed#19<$a) goto flash_smc::@15 -- vbuz1_lt_vbuc1_then_la1 
    lda.z smc_attempts_flashed
    cmp #$a
    bcc __b12
    // flash_smc::@14
  __b14:
    // if(smc_attempts_flashed >= 10)
    // [1009] if(flash_smc::smc_attempts_flashed#19<$a) goto flash_smc::@11 -- vbuz1_lt_vbuc1_then_la1 
    lda.z smc_attempts_flashed
    cmp #$a
    bcc __b11
    // [1010] phi from flash_smc::@14 to flash_smc::@22 [phi:flash_smc::@14->flash_smc::@22]
    // flash_smc::@22
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1011] call snprintf_init
    jsr snprintf_init
    // [1012] phi from flash_smc::@22 to flash_smc::@58 [phi:flash_smc::@22->flash_smc::@58]
    // flash_smc::@58
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1013] call printf_str
    // [700] phi from flash_smc::@58 to printf_str [phi:flash_smc::@58->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:flash_smc::@58->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = flash_smc::s10 [phi:flash_smc::@58->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@59
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1014] printf_uint::uvalue#9 = flash_smc::smc_bytes_flashed#12 -- vwuz1=vwuz2 
    lda.z smc_bytes_flashed
    sta.z printf_uint.uvalue
    lda.z smc_bytes_flashed+1
    sta.z printf_uint.uvalue+1
    // [1015] call printf_uint
    // [709] phi from flash_smc::@59 to printf_uint [phi:flash_smc::@59->printf_uint]
    // [709] phi printf_uint::format_zero_padding#16 = 1 [phi:flash_smc::@59->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [709] phi printf_uint::format_min_length#16 = 4 [phi:flash_smc::@59->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [709] phi printf_uint::putc#16 = &snputc [phi:flash_smc::@59->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [709] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:flash_smc::@59->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [709] phi printf_uint::uvalue#16 = printf_uint::uvalue#9 [phi:flash_smc::@59->printf_uint#4] -- register_copy 
    jsr printf_uint
    // flash_smc::@60
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1016] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1017] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [1019] call info_line
    // [931] phi from flash_smc::@60 to info_line [phi:flash_smc::@60->info_line]
    // [931] phi info_line::info_text#17 = info_text [phi:flash_smc::@60->info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_line.info_text
    lda #>@info_text
    sta.z info_line.info_text+1
    jsr info_line
    jmp __b2
    // [1020] phi from flash_smc::@61 to flash_smc::@15 [phi:flash_smc::@61->flash_smc::@15]
  __b12:
    // [1020] phi flash_smc::smc_bytes_checksum#2 = 0 [phi:flash_smc::@61->flash_smc::@15#0] -- vbum1=vbuc1 
    lda #0
    sta smc_bytes_checksum
    // [1020] phi flash_smc::smc_ram_ptr#12 = flash_smc::smc_ram_ptr#10 [phi:flash_smc::@61->flash_smc::@15#1] -- register_copy 
    // [1020] phi flash_smc::smc_package_flashed#2 = 0 [phi:flash_smc::@61->flash_smc::@15#2] -- vwuz1=vwuc1 
    sta.z smc_package_flashed
    sta.z smc_package_flashed+1
    // flash_smc::@15
  __b15:
    // while(smc_package_flashed < 8)
    // [1021] if(flash_smc::smc_package_flashed#2<8) goto flash_smc::@16 -- vwuz1_lt_vbuc1_then_la1 
    lda.z smc_package_flashed+1
    bne !+
    lda.z smc_package_flashed
    cmp #8
    bcs !__b16+
    jmp __b16
  !__b16:
  !:
    // flash_smc::@17
    // smc_bytes_checksum ^ 0xFF
    // [1022] flash_smc::$27 = flash_smc::smc_bytes_checksum#2 ^ $ff -- vbum1=vbum1_bxor_vbuc1 
    lda #$ff
    eor flash_smc__27
    sta flash_smc__27
    // (smc_bytes_checksum ^ 0xFF)+1
    // [1023] flash_smc::$28 = flash_smc::$27 + 1 -- vbum1=vbum1_plus_1 
    inc flash_smc__28
    // unsigned char smc_checksum_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, (smc_bytes_checksum ^ 0xFF)+1)
    // [1024] flash_smc::cx16_k_i2c_write_byte5_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte5_device
    // [1025] flash_smc::cx16_k_i2c_write_byte5_offset = $80 -- vbum1=vbuc1 
    lda #$80
    sta cx16_k_i2c_write_byte5_offset
    // [1026] flash_smc::cx16_k_i2c_write_byte5_value = flash_smc::$28 -- vbum1=vbum2 
    lda flash_smc__28
    sta cx16_k_i2c_write_byte5_value
    // flash_smc::cx16_k_i2c_write_byte5
    // unsigned char result
    // [1027] flash_smc::cx16_k_i2c_write_byte5_result = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte5_result
    // asm
    // asm { ldxdevice ldyoffset ldavalue stzresult jsrCX16_I2C_WRITE_BYTE rolresult  }
    ldx cx16_k_i2c_write_byte5_device
    ldy cx16_k_i2c_write_byte5_offset
    lda cx16_k_i2c_write_byte5_value
    stz cx16_k_i2c_write_byte5_result
    jsr CX16_I2C_WRITE_BYTE
    rol cx16_k_i2c_write_byte5_result
    // flash_smc::@25
    // unsigned int smc_commit_result = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_COMMIT)
    // [1029] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1030] cx16_k_i2c_read_byte::offset = $81 -- vbum1=vbuc1 
    lda #$81
    sta cx16_k_i2c_read_byte.offset
    // [1031] call cx16_k_i2c_read_byte
    // Now send the commit command.
    jsr cx16_k_i2c_read_byte
    // [1032] cx16_k_i2c_read_byte::return#4 = cx16_k_i2c_read_byte::return#1
    // flash_smc::@49
    // [1033] flash_smc::smc_commit_result#0 = cx16_k_i2c_read_byte::return#4
    // if(smc_commit_result == 1)
    // [1034] if(flash_smc::smc_commit_result#0==1) goto flash_smc::@19 -- vwuz1_eq_vbuc1_then_la1 
    lda.z smc_commit_result+1
    bne !+
    lda.z smc_commit_result
    cmp #1
    beq __b19
  !:
    // flash_smc::@18
    // smc_ram_ptr -= 8
    // [1035] flash_smc::smc_ram_ptr#1 = flash_smc::smc_ram_ptr#12 - 8 -- pbuz1=pbuz1_minus_vbuc1 
    sec
    lda.z smc_ram_ptr
    sbc #8
    sta.z smc_ram_ptr
    lda.z smc_ram_ptr+1
    sbc #0
    sta.z smc_ram_ptr+1
    // smc_attempts_flashed++;
    // [1036] flash_smc::smc_attempts_flashed#1 = ++ flash_smc::smc_attempts_flashed#19 -- vbuz1=_inc_vbuz1 
    inc.z smc_attempts_flashed
    // [1006] phi from flash_smc::@18 to flash_smc::@13 [phi:flash_smc::@18->flash_smc::@13]
    // [1006] phi flash_smc::y#20 = flash_smc::y#20 [phi:flash_smc::@18->flash_smc::@13#0] -- register_copy 
    // [1006] phi flash_smc::smc_attempts_total#17 = flash_smc::smc_attempts_total#17 [phi:flash_smc::@18->flash_smc::@13#1] -- register_copy 
    // [1006] phi flash_smc::smc_row_bytes#10 = flash_smc::smc_row_bytes#10 [phi:flash_smc::@18->flash_smc::@13#2] -- register_copy 
    // [1006] phi flash_smc::smc_ram_ptr#10 = flash_smc::smc_ram_ptr#1 [phi:flash_smc::@18->flash_smc::@13#3] -- register_copy 
    // [1006] phi flash_smc::smc_bytes_flashed#12 = flash_smc::smc_bytes_flashed#12 [phi:flash_smc::@18->flash_smc::@13#4] -- register_copy 
    // [1006] phi flash_smc::smc_attempts_flashed#19 = flash_smc::smc_attempts_flashed#1 [phi:flash_smc::@18->flash_smc::@13#5] -- register_copy 
    // [1006] phi flash_smc::smc_package_committed#2 = flash_smc::smc_package_committed#2 [phi:flash_smc::@18->flash_smc::@13#6] -- register_copy 
    jmp __b13
    // flash_smc::@19
  __b19:
    // if (smc_row_bytes == smc_row_total)
    // [1037] if(flash_smc::smc_row_bytes#10!=flash_smc::smc_row_total#0) goto flash_smc::@20 -- vwum1_neq_vwuc1_then_la1 
    lda smc_row_bytes+1
    cmp #>smc_row_total
    bne __b20
    lda smc_row_bytes
    cmp #<smc_row_total
    bne __b20
    // flash_smc::@21
    // gotoxy(x, ++y);
    // [1038] flash_smc::y#0 = ++ flash_smc::y#20 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [1039] gotoxy::y#22 = flash_smc::y#0 -- vbuz1=vbum2 
    lda y
    sta.z gotoxy.y
    // [1040] call gotoxy
    // [557] phi from flash_smc::@21 to gotoxy [phi:flash_smc::@21->gotoxy]
    // [557] phi gotoxy::y#30 = gotoxy::y#22 [phi:flash_smc::@21->gotoxy#0] -- register_copy 
    // [557] phi gotoxy::x#30 = PROGRESS_X [phi:flash_smc::@21->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [1041] phi from flash_smc::@21 to flash_smc::@20 [phi:flash_smc::@21->flash_smc::@20]
    // [1041] phi flash_smc::y#33 = flash_smc::y#0 [phi:flash_smc::@21->flash_smc::@20#0] -- register_copy 
    // [1041] phi flash_smc::smc_row_bytes#4 = 0 [phi:flash_smc::@21->flash_smc::@20#1] -- vwum1=vbuc1 
    lda #<0
    sta smc_row_bytes
    sta smc_row_bytes+1
    // [1041] phi from flash_smc::@19 to flash_smc::@20 [phi:flash_smc::@19->flash_smc::@20]
    // [1041] phi flash_smc::y#33 = flash_smc::y#20 [phi:flash_smc::@19->flash_smc::@20#0] -- register_copy 
    // [1041] phi flash_smc::smc_row_bytes#4 = flash_smc::smc_row_bytes#10 [phi:flash_smc::@19->flash_smc::@20#1] -- register_copy 
    // flash_smc::@20
  __b20:
    // cputc('+')
    // [1042] stackpush(char) = '+' -- _stackpushbyte_=vbuc1 
    lda #'+'
    pha
    // [1043] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_bytes_flashed += 8
    // [1045] flash_smc::smc_bytes_flashed#1 = flash_smc::smc_bytes_flashed#12 + 8 -- vwuz1=vwuz1_plus_vbuc1 
    lda #8
    clc
    adc.z smc_bytes_flashed
    sta.z smc_bytes_flashed
    bcc !+
    inc.z smc_bytes_flashed+1
  !:
    // smc_row_bytes += 8
    // [1046] flash_smc::smc_row_bytes#1 = flash_smc::smc_row_bytes#4 + 8 -- vwum1=vwum1_plus_vbuc1 
    lda #8
    clc
    adc smc_row_bytes
    sta smc_row_bytes
    bcc !+
    inc smc_row_bytes+1
  !:
    // smc_attempts_total += smc_attempts_flashed
    // [1047] flash_smc::smc_attempts_total#1 = flash_smc::smc_attempts_total#17 + flash_smc::smc_attempts_flashed#19 -- vwuz1=vwuz1_plus_vbuz2 
    lda.z smc_attempts_flashed
    clc
    adc.z smc_attempts_total
    sta.z smc_attempts_total
    bcc !+
    inc.z smc_attempts_total+1
  !:
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1048] call snprintf_init
    jsr snprintf_init
    // [1049] phi from flash_smc::@20 to flash_smc::@50 [phi:flash_smc::@20->flash_smc::@50]
    // flash_smc::@50
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1050] call printf_str
    // [700] phi from flash_smc::@50 to printf_str [phi:flash_smc::@50->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:flash_smc::@50->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = flash_smc::s6 [phi:flash_smc::@50->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@51
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1051] printf_uint::uvalue#6 = flash_smc::smc_bytes_flashed#1 -- vwuz1=vwuz2 
    lda.z smc_bytes_flashed
    sta.z printf_uint.uvalue
    lda.z smc_bytes_flashed+1
    sta.z printf_uint.uvalue+1
    // [1052] call printf_uint
    // [709] phi from flash_smc::@51 to printf_uint [phi:flash_smc::@51->printf_uint]
    // [709] phi printf_uint::format_zero_padding#16 = 1 [phi:flash_smc::@51->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [709] phi printf_uint::format_min_length#16 = 5 [phi:flash_smc::@51->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [709] phi printf_uint::putc#16 = &snputc [phi:flash_smc::@51->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [709] phi printf_uint::format_radix#16 = DECIMAL [phi:flash_smc::@51->printf_uint#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [709] phi printf_uint::uvalue#16 = printf_uint::uvalue#6 [phi:flash_smc::@51->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1053] phi from flash_smc::@51 to flash_smc::@52 [phi:flash_smc::@51->flash_smc::@52]
    // flash_smc::@52
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1054] call printf_str
    // [700] phi from flash_smc::@52 to printf_str [phi:flash_smc::@52->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:flash_smc::@52->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = flash_smc::s7 [phi:flash_smc::@52->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@53
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1055] printf_uint::uvalue#7 = flash_smc::smc_bytes_total#0 -- vwuz1=vwuz2 
    lda.z smc_bytes_total
    sta.z printf_uint.uvalue
    lda.z smc_bytes_total+1
    sta.z printf_uint.uvalue+1
    // [1056] call printf_uint
    // [709] phi from flash_smc::@53 to printf_uint [phi:flash_smc::@53->printf_uint]
    // [709] phi printf_uint::format_zero_padding#16 = 1 [phi:flash_smc::@53->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [709] phi printf_uint::format_min_length#16 = 5 [phi:flash_smc::@53->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [709] phi printf_uint::putc#16 = &snputc [phi:flash_smc::@53->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [709] phi printf_uint::format_radix#16 = DECIMAL [phi:flash_smc::@53->printf_uint#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [709] phi printf_uint::uvalue#16 = printf_uint::uvalue#7 [phi:flash_smc::@53->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1057] phi from flash_smc::@53 to flash_smc::@54 [phi:flash_smc::@53->flash_smc::@54]
    // flash_smc::@54
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1058] call printf_str
    // [700] phi from flash_smc::@54 to printf_str [phi:flash_smc::@54->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:flash_smc::@54->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = flash_smc::s8 [phi:flash_smc::@54->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@55
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1059] printf_uint::uvalue#8 = flash_smc::smc_attempts_total#1 -- vwuz1=vwuz2 
    lda.z smc_attempts_total
    sta.z printf_uint.uvalue
    lda.z smc_attempts_total+1
    sta.z printf_uint.uvalue+1
    // [1060] call printf_uint
    // [709] phi from flash_smc::@55 to printf_uint [phi:flash_smc::@55->printf_uint]
    // [709] phi printf_uint::format_zero_padding#16 = 1 [phi:flash_smc::@55->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [709] phi printf_uint::format_min_length#16 = 2 [phi:flash_smc::@55->printf_uint#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uint.format_min_length
    // [709] phi printf_uint::putc#16 = &snputc [phi:flash_smc::@55->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [709] phi printf_uint::format_radix#16 = DECIMAL [phi:flash_smc::@55->printf_uint#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [709] phi printf_uint::uvalue#16 = printf_uint::uvalue#8 [phi:flash_smc::@55->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1061] phi from flash_smc::@55 to flash_smc::@56 [phi:flash_smc::@55->flash_smc::@56]
    // flash_smc::@56
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1062] call printf_str
    // [700] phi from flash_smc::@56 to printf_str [phi:flash_smc::@56->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:flash_smc::@56->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = flash_smc::s9 [phi:flash_smc::@56->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@57
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [1063] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1064] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [1066] call info_line
    // [931] phi from flash_smc::@57 to info_line [phi:flash_smc::@57->info_line]
    // [931] phi info_line::info_text#17 = info_text [phi:flash_smc::@57->info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_line.info_text
    lda #>@info_text
    sta.z info_line.info_text+1
    jsr info_line
    // [1006] phi from flash_smc::@57 to flash_smc::@13 [phi:flash_smc::@57->flash_smc::@13]
    // [1006] phi flash_smc::y#20 = flash_smc::y#33 [phi:flash_smc::@57->flash_smc::@13#0] -- register_copy 
    // [1006] phi flash_smc::smc_attempts_total#17 = flash_smc::smc_attempts_total#1 [phi:flash_smc::@57->flash_smc::@13#1] -- register_copy 
    // [1006] phi flash_smc::smc_row_bytes#10 = flash_smc::smc_row_bytes#1 [phi:flash_smc::@57->flash_smc::@13#2] -- register_copy 
    // [1006] phi flash_smc::smc_ram_ptr#10 = flash_smc::smc_ram_ptr#12 [phi:flash_smc::@57->flash_smc::@13#3] -- register_copy 
    // [1006] phi flash_smc::smc_bytes_flashed#12 = flash_smc::smc_bytes_flashed#1 [phi:flash_smc::@57->flash_smc::@13#4] -- register_copy 
    // [1006] phi flash_smc::smc_attempts_flashed#19 = flash_smc::smc_attempts_flashed#19 [phi:flash_smc::@57->flash_smc::@13#5] -- register_copy 
    // [1006] phi flash_smc::smc_package_committed#2 = 1 [phi:flash_smc::@57->flash_smc::@13#6] -- vbum1=vbuc1 
    lda #1
    sta smc_package_committed
    jmp __b13
    // flash_smc::@16
  __b16:
    // unsigned char smc_byte_upload = *smc_ram_ptr
    // [1067] flash_smc::smc_byte_upload#0 = *flash_smc::smc_ram_ptr#12 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (smc_ram_ptr),y
    sta.z smc_byte_upload
    // smc_ram_ptr++;
    // [1068] flash_smc::smc_ram_ptr#0 = ++ flash_smc::smc_ram_ptr#12 -- pbuz1=_inc_pbuz1 
    inc.z smc_ram_ptr
    bne !+
    inc.z smc_ram_ptr+1
  !:
    // smc_bytes_checksum += smc_byte_upload
    // [1069] flash_smc::smc_bytes_checksum#1 = flash_smc::smc_bytes_checksum#2 + flash_smc::smc_byte_upload#0 -- vbum1=vbum1_plus_vbuz2 
    lda smc_bytes_checksum
    clc
    adc.z smc_byte_upload
    sta smc_bytes_checksum
    // unsigned char smc_upload_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, smc_byte_upload)
    // [1070] flash_smc::cx16_k_i2c_write_byte4_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte4_device
    // [1071] flash_smc::cx16_k_i2c_write_byte4_offset = $80 -- vbum1=vbuc1 
    lda #$80
    sta cx16_k_i2c_write_byte4_offset
    // [1072] flash_smc::cx16_k_i2c_write_byte4_value = flash_smc::smc_byte_upload#0 -- vbum1=vbuz2 
    lda.z smc_byte_upload
    sta cx16_k_i2c_write_byte4_value
    // flash_smc::cx16_k_i2c_write_byte4
    // unsigned char result
    // [1073] flash_smc::cx16_k_i2c_write_byte4_result = 0 -- vbum1=vbuc1 
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
    // smc_package_flashed++;
    // [1075] flash_smc::smc_package_flashed#1 = ++ flash_smc::smc_package_flashed#2 -- vwuz1=_inc_vwuz1 
    inc.z smc_package_flashed
    bne !+
    inc.z smc_package_flashed+1
  !:
    // [1020] phi from flash_smc::@24 to flash_smc::@15 [phi:flash_smc::@24->flash_smc::@15]
    // [1020] phi flash_smc::smc_bytes_checksum#2 = flash_smc::smc_bytes_checksum#1 [phi:flash_smc::@24->flash_smc::@15#0] -- register_copy 
    // [1020] phi flash_smc::smc_ram_ptr#12 = flash_smc::smc_ram_ptr#0 [phi:flash_smc::@24->flash_smc::@15#1] -- register_copy 
    // [1020] phi flash_smc::smc_package_flashed#2 = flash_smc::smc_package_flashed#1 [phi:flash_smc::@24->flash_smc::@15#2] -- register_copy 
    jmp __b15
    // [1076] phi from flash_smc::@7 to flash_smc::@8 [phi:flash_smc::@7->flash_smc::@8]
    // flash_smc::@8
  __b8:
    // wait_moment()
    // [1077] call wait_moment
    // [1117] phi from flash_smc::@8 to wait_moment [phi:flash_smc::@8->wait_moment]
    jsr wait_moment
    // [1078] phi from flash_smc::@8 to flash_smc::@37 [phi:flash_smc::@8->flash_smc::@37]
    // flash_smc::@37
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1079] call snprintf_init
    jsr snprintf_init
    // [1080] phi from flash_smc::@37 to flash_smc::@38 [phi:flash_smc::@37->flash_smc::@38]
    // flash_smc::@38
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1081] call printf_str
    // [700] phi from flash_smc::@38 to printf_str [phi:flash_smc::@38->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:flash_smc::@38->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = flash_smc::s3 [phi:flash_smc::@38->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@39
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1082] printf_uchar::uvalue#3 = flash_smc::smc_bootloader_activation_countdown#12 -- vbuz1=vbuz2 
    lda.z smc_bootloader_activation_countdown_1
    sta.z printf_uchar.uvalue
    // [1083] call printf_uchar
    // [1122] phi from flash_smc::@39 to printf_uchar [phi:flash_smc::@39->printf_uchar]
    // [1122] phi printf_uchar::format_zero_padding#10 = 0 [phi:flash_smc::@39->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1122] phi printf_uchar::format_min_length#10 = 0 [phi:flash_smc::@39->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1122] phi printf_uchar::putc#10 = &snputc [phi:flash_smc::@39->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1122] phi printf_uchar::format_radix#10 = DECIMAL [phi:flash_smc::@39->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1122] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#3 [phi:flash_smc::@39->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1084] phi from flash_smc::@39 to flash_smc::@40 [phi:flash_smc::@39->flash_smc::@40]
    // flash_smc::@40
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1085] call printf_str
    // [700] phi from flash_smc::@40 to printf_str [phi:flash_smc::@40->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:flash_smc::@40->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = s7 [phi:flash_smc::@40->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s7
    sta.z printf_str.s
    lda #>@s7
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@41
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1086] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1087] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [1089] call info_line
    // [931] phi from flash_smc::@41 to info_line [phi:flash_smc::@41->info_line]
    // [931] phi info_line::info_text#17 = info_text [phi:flash_smc::@41->info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_line.info_text
    lda #>@info_text
    sta.z info_line.info_text+1
    jsr info_line
    // flash_smc::@42
    // smc_bootloader_activation_countdown--;
    // [1090] flash_smc::smc_bootloader_activation_countdown#3 = -- flash_smc::smc_bootloader_activation_countdown#12 -- vbuz1=_dec_vbuz1 
    dec.z smc_bootloader_activation_countdown_1
    // [975] phi from flash_smc::@42 to flash_smc::@7 [phi:flash_smc::@42->flash_smc::@7]
    // [975] phi flash_smc::smc_bootloader_activation_countdown#12 = flash_smc::smc_bootloader_activation_countdown#3 [phi:flash_smc::@42->flash_smc::@7#0] -- register_copy 
    jmp __b7
    // flash_smc::@4
  __b4:
    // unsigned int smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1091] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1092] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [1093] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [1094] cx16_k_i2c_read_byte::return#2 = cx16_k_i2c_read_byte::return#1
    // flash_smc::@31
    // [1095] flash_smc::smc_bootloader_not_activated1#0 = cx16_k_i2c_read_byte::return#2
    // if(smc_bootloader_not_activated)
    // [1096] if(0!=flash_smc::smc_bootloader_not_activated1#0) goto flash_smc::@5 -- 0_neq_vwuz1_then_la1 
    lda.z smc_bootloader_not_activated1
    ora.z smc_bootloader_not_activated1+1
    bne __b5
    jmp __b9
    // [1097] phi from flash_smc::@31 to flash_smc::@5 [phi:flash_smc::@31->flash_smc::@5]
    // flash_smc::@5
  __b5:
    // wait_moment()
    // [1098] call wait_moment
    // [1117] phi from flash_smc::@5 to wait_moment [phi:flash_smc::@5->wait_moment]
    jsr wait_moment
    // [1099] phi from flash_smc::@5 to flash_smc::@32 [phi:flash_smc::@5->flash_smc::@32]
    // flash_smc::@32
    // sprintf(info_text, "Press POWER and RESET on the CX16 to start the SMC update (%u)!", smc_bootloader_activation_countdown)
    // [1100] call snprintf_init
    jsr snprintf_init
    // [1101] phi from flash_smc::@32 to flash_smc::@33 [phi:flash_smc::@32->flash_smc::@33]
    // flash_smc::@33
    // sprintf(info_text, "Press POWER and RESET on the CX16 to start the SMC update (%u)!", smc_bootloader_activation_countdown)
    // [1102] call printf_str
    // [700] phi from flash_smc::@33 to printf_str [phi:flash_smc::@33->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:flash_smc::@33->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = flash_smc::s1 [phi:flash_smc::@33->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@34
    // sprintf(info_text, "Press POWER and RESET on the CX16 to start the SMC update (%u)!", smc_bootloader_activation_countdown)
    // [1103] printf_uchar::uvalue#2 = flash_smc::smc_bootloader_activation_countdown#10 -- vbuz1=vbum2 
    lda smc_bootloader_activation_countdown
    sta.z printf_uchar.uvalue
    // [1104] call printf_uchar
    // [1122] phi from flash_smc::@34 to printf_uchar [phi:flash_smc::@34->printf_uchar]
    // [1122] phi printf_uchar::format_zero_padding#10 = 0 [phi:flash_smc::@34->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1122] phi printf_uchar::format_min_length#10 = 0 [phi:flash_smc::@34->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1122] phi printf_uchar::putc#10 = &snputc [phi:flash_smc::@34->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1122] phi printf_uchar::format_radix#10 = DECIMAL [phi:flash_smc::@34->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1122] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#2 [phi:flash_smc::@34->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1105] phi from flash_smc::@34 to flash_smc::@35 [phi:flash_smc::@34->flash_smc::@35]
    // flash_smc::@35
    // sprintf(info_text, "Press POWER and RESET on the CX16 to start the SMC update (%u)!", smc_bootloader_activation_countdown)
    // [1106] call printf_str
    // [700] phi from flash_smc::@35 to printf_str [phi:flash_smc::@35->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:flash_smc::@35->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = flash_smc::s2 [phi:flash_smc::@35->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@36
    // sprintf(info_text, "Press POWER and RESET on the CX16 to start the SMC update (%u)!", smc_bootloader_activation_countdown)
    // [1107] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1108] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [1110] call info_line
    // [931] phi from flash_smc::@36 to info_line [phi:flash_smc::@36->info_line]
    // [931] phi info_line::info_text#17 = info_text [phi:flash_smc::@36->info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_line.info_text
    lda #>@info_text
    sta.z info_line.info_text+1
    jsr info_line
    // flash_smc::@6
    // smc_bootloader_activation_countdown--;
    // [1111] flash_smc::smc_bootloader_activation_countdown#2 = -- flash_smc::smc_bootloader_activation_countdown#10 -- vbum1=_dec_vbum1 
    dec smc_bootloader_activation_countdown
    // [973] phi from flash_smc::@6 to flash_smc::@3 [phi:flash_smc::@6->flash_smc::@3]
    // [973] phi flash_smc::smc_bootloader_activation_countdown#10 = flash_smc::smc_bootloader_activation_countdown#2 [phi:flash_smc::@6->flash_smc::@3#0] -- register_copy 
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
    .label flash_smc__27 = main.check_smc4_main__0
    .label flash_smc__28 = main.check_smc4_main__0
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
    cx16_k_i2c_write_byte5_device: .byte 0
    cx16_k_i2c_write_byte5_offset: .byte 0
    cx16_k_i2c_write_byte5_value: .byte 0
    cx16_k_i2c_write_byte5_result: .byte 0
    // Waiting a bit to ensure the bootloader is activated.
    .label smc_bootloader_activation_countdown = main.check_vera1_main__0
    .label smc_bytes_checksum = main.check_smc4_main__0
    .label smc_row_bytes = fopen.pathtoken_1
    .label y = strchr.c
    .label smc_package_committed = main.check_cx16_rom2_check_rom1_main__0
}
.segment Code
  // system_reset
system_reset: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 0
    // system_reset::bank_set_bram1
    // BRAM = bank
    // [1113] BRAM = system_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // system_reset::bank_set_brom1
    // BROM = bank
    // [1114] BROM = system_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // system_reset::@1
    // asm
    // asm { jmp($FFFC)  }
    jmp ($fffc)
    // system_reset::@return
    // }
    // [1116] return 
}
  // wait_moment
wait_moment: {
    .label i = $6f
    // [1118] phi from wait_moment to wait_moment::@1 [phi:wait_moment->wait_moment::@1]
    // [1118] phi wait_moment::i#2 = $ffff [phi:wait_moment->wait_moment::@1#0] -- vwuz1=vwuc1 
    lda #<$ffff
    sta.z i
    lda #>$ffff
    sta.z i+1
    // wait_moment::@1
  __b1:
    // for(unsigned int i=65535; i>0; i--)
    // [1119] if(wait_moment::i#2>0) goto wait_moment::@2 -- vwuz1_gt_0_then_la1 
    lda.z i+1
    bne __b2
    lda.z i
    bne __b2
  !:
    // wait_moment::@return
    // }
    // [1120] return 
    rts
    // wait_moment::@2
  __b2:
    // for(unsigned int i=65535; i>0; i--)
    // [1121] wait_moment::i#1 = -- wait_moment::i#2 -- vwuz1=_dec_vwuz1 
    lda.z i
    bne !+
    dec.z i+1
  !:
    dec.z i
    // [1118] phi from wait_moment::@2 to wait_moment::@1 [phi:wait_moment::@2->wait_moment::@1]
    // [1118] phi wait_moment::i#2 = wait_moment::i#1 [phi:wait_moment::@2->wait_moment::@1#0] -- register_copy 
    jmp __b1
}
  // printf_uchar
// Print an unsigned char using a specific format
// void printf_uchar(__zp($4d) void (*putc)(char), __zp($2f) char uvalue, __zp($e2) char format_min_length, char format_justify_left, char format_sign_always, __zp($e1) char format_zero_padding, char format_upper_case, __zp($e0) char format_radix)
printf_uchar: {
    .label uvalue = $2f
    .label format_radix = $e0
    .label putc = $4d
    .label format_min_length = $e2
    .label format_zero_padding = $e1
    // printf_uchar::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1123] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // uctoa(uvalue, printf_buffer.digits, format.radix)
    // [1124] uctoa::value#1 = printf_uchar::uvalue#10
    // [1125] uctoa::radix#0 = printf_uchar::format_radix#10
    // [1126] call uctoa
    // Format number into buffer
    jsr uctoa
    // printf_uchar::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1127] printf_number_buffer::putc#2 = printf_uchar::putc#10
    // [1128] printf_number_buffer::buffer_sign#2 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [1129] printf_number_buffer::format_min_length#2 = printf_uchar::format_min_length#10
    // [1130] printf_number_buffer::format_zero_padding#2 = printf_uchar::format_zero_padding#10
    // [1131] call printf_number_buffer
  // Print using format
    // [1835] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [1835] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#2 [phi:printf_uchar::@2->printf_number_buffer#0] -- register_copy 
    // [1835] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#2 [phi:printf_uchar::@2->printf_number_buffer#1] -- register_copy 
    // [1835] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#2 [phi:printf_uchar::@2->printf_number_buffer#2] -- register_copy 
    // [1835] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#2 [phi:printf_uchar::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [1132] return 
    rts
}
  // info_rom
// void info_rom(__mem() char rom_chip, __mem() char info_status, __zp($b8) char *info_text)
info_rom: {
    .label info_rom__11 = $e5
    .label info_rom__13 = $64
    .label x = $eb
    .label y = $d9
    .label info_text = $b8
    // unsigned char x = wherex()
    // [1134] call wherex
    jsr wherex
    // [1135] wherex::return#12 = wherex::return#0 -- vbuz1=vbuz2 
    lda.z wherex.return
    sta.z wherex.return_4
    // info_rom::@3
    // [1136] info_rom::x#0 = wherex::return#12
    // unsigned char y = wherey()
    // [1137] call wherey
    jsr wherey
    // [1138] wherey::return#12 = wherey::return#0 -- vbuz1=vbuz2 
    lda.z wherey.return
    sta.z wherey.return_4
    // info_rom::@4
    // [1139] info_rom::y#0 = wherey::return#12
    // status_rom[rom_chip] = info_status
    // [1140] status_rom[info_rom::rom_chip#16] = info_rom::info_status#16 -- pbuc1_derefidx_vbum1=vbum2 
    lda info_status
    ldy rom_chip
    sta status_rom,y
    // print_rom_led(rom_chip, status_color[info_status])
    // [1141] print_rom_led::chip#1 = info_rom::rom_chip#16 -- vbuz1=vbum2 
    tya
    sta.z print_rom_led.chip
    // [1142] print_rom_led::c#1 = status_color[info_rom::info_status#16] -- vbuz1=pbuc1_derefidx_vbum2 
    ldy info_status
    lda status_color,y
    sta.z print_rom_led.c
    // [1143] call print_rom_led
    // [1914] phi from info_rom::@4 to print_rom_led [phi:info_rom::@4->print_rom_led]
    // [1914] phi print_rom_led::c#2 = print_rom_led::c#1 [phi:info_rom::@4->print_rom_led#0] -- register_copy 
    // [1914] phi print_rom_led::chip#2 = print_rom_led::chip#1 [phi:info_rom::@4->print_rom_led#1] -- register_copy 
    jsr print_rom_led
    // info_rom::@5
    // gotoxy(INFO_X, INFO_Y+rom_chip+2)
    // [1144] gotoxy::y#17 = info_rom::rom_chip#16 + $11+2 -- vbuz1=vbum2_plus_vbuc1 
    lda #$11+2
    clc
    adc rom_chip
    sta.z gotoxy.y
    // [1145] call gotoxy
    // [557] phi from info_rom::@5 to gotoxy [phi:info_rom::@5->gotoxy]
    // [557] phi gotoxy::y#30 = gotoxy::y#17 [phi:info_rom::@5->gotoxy#0] -- register_copy 
    // [557] phi gotoxy::x#30 = 4 [phi:info_rom::@5->gotoxy#1] -- vbuz1=vbuc1 
    lda #4
    sta.z gotoxy.x
    jsr gotoxy
    // [1146] phi from info_rom::@5 to info_rom::@6 [phi:info_rom::@5->info_rom::@6]
    // info_rom::@6
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1147] call printf_str
    // [700] phi from info_rom::@6 to printf_str [phi:info_rom::@6->printf_str]
    // [700] phi printf_str::putc#68 = &cputc [phi:info_rom::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = info_rom::s [phi:info_rom::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@7
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1148] printf_uchar::uvalue#0 = info_rom::rom_chip#16 -- vbuz1=vbum2 
    lda rom_chip
    sta.z printf_uchar.uvalue
    // [1149] call printf_uchar
    // [1122] phi from info_rom::@7 to printf_uchar [phi:info_rom::@7->printf_uchar]
    // [1122] phi printf_uchar::format_zero_padding#10 = 0 [phi:info_rom::@7->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1122] phi printf_uchar::format_min_length#10 = 0 [phi:info_rom::@7->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1122] phi printf_uchar::putc#10 = &cputc [phi:info_rom::@7->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1122] phi printf_uchar::format_radix#10 = DECIMAL [phi:info_rom::@7->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1122] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#0 [phi:info_rom::@7->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1150] phi from info_rom::@7 to info_rom::@8 [phi:info_rom::@7->info_rom::@8]
    // info_rom::@8
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1151] call printf_str
    // [700] phi from info_rom::@8 to printf_str [phi:info_rom::@8->printf_str]
    // [700] phi printf_str::putc#68 = &cputc [phi:info_rom::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = s1 [phi:info_rom::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@9
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1152] info_rom::$10 = info_rom::info_status#16 << 1 -- vbum1=vbum1_rol_1 
    asl info_rom__10
    // [1153] printf_string::str#7 = status_text[info_rom::$10] -- pbuz1=qbuc1_derefidx_vbum2 
    ldy info_rom__10
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [1154] call printf_string
    // [1184] phi from info_rom::@9 to printf_string [phi:info_rom::@9->printf_string]
    // [1184] phi printf_string::putc#18 = &cputc [phi:info_rom::@9->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1184] phi printf_string::str#18 = printf_string::str#7 [phi:info_rom::@9->printf_string#1] -- register_copy 
    // [1184] phi printf_string::format_justify_left#18 = 1 [phi:info_rom::@9->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1184] phi printf_string::format_min_length#18 = 9 [phi:info_rom::@9->printf_string#3] -- vbuz1=vbuc1 
    lda #9
    sta.z printf_string.format_min_length
    jsr printf_string
    // [1155] phi from info_rom::@9 to info_rom::@10 [phi:info_rom::@9->info_rom::@10]
    // info_rom::@10
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1156] call printf_str
    // [700] phi from info_rom::@10 to printf_str [phi:info_rom::@10->printf_str]
    // [700] phi printf_str::putc#68 = &cputc [phi:info_rom::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = s1 [phi:info_rom::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@11
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1157] info_rom::$11 = info_rom::rom_chip#16 << 1 -- vbuz1=vbum2_rol_1 
    lda rom_chip
    asl
    sta.z info_rom__11
    // [1158] printf_string::str#8 = rom_device_names[info_rom::$11] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda rom_device_names,y
    sta.z printf_string.str
    lda rom_device_names+1,y
    sta.z printf_string.str+1
    // [1159] call printf_string
    // [1184] phi from info_rom::@11 to printf_string [phi:info_rom::@11->printf_string]
    // [1184] phi printf_string::putc#18 = &cputc [phi:info_rom::@11->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1184] phi printf_string::str#18 = printf_string::str#8 [phi:info_rom::@11->printf_string#1] -- register_copy 
    // [1184] phi printf_string::format_justify_left#18 = 1 [phi:info_rom::@11->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1184] phi printf_string::format_min_length#18 = 6 [phi:info_rom::@11->printf_string#3] -- vbuz1=vbuc1 
    lda #6
    sta.z printf_string.format_min_length
    jsr printf_string
    // [1160] phi from info_rom::@11 to info_rom::@12 [phi:info_rom::@11->info_rom::@12]
    // info_rom::@12
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1161] call printf_str
    // [700] phi from info_rom::@12 to printf_str [phi:info_rom::@12->printf_str]
    // [700] phi printf_str::putc#68 = &cputc [phi:info_rom::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = s1 [phi:info_rom::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@13
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1162] info_rom::$13 = info_rom::rom_chip#16 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z info_rom__13
    // [1163] printf_ulong::uvalue#0 = file_sizes[info_rom::$13] -- vduz1=pduc1_derefidx_vbuz2 
    tay
    lda file_sizes,y
    sta.z printf_ulong.uvalue
    lda file_sizes+1,y
    sta.z printf_ulong.uvalue+1
    lda file_sizes+2,y
    sta.z printf_ulong.uvalue+2
    lda file_sizes+3,y
    sta.z printf_ulong.uvalue+3
    // [1164] call printf_ulong
    // [1359] phi from info_rom::@13 to printf_ulong [phi:info_rom::@13->printf_ulong]
    // [1359] phi printf_ulong::format_zero_padding#11 = 1 [phi:info_rom::@13->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1359] phi printf_ulong::format_min_length#11 = 5 [phi:info_rom::@13->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1359] phi printf_ulong::putc#11 = &cputc [phi:info_rom::@13->printf_ulong#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_ulong.putc
    lda #>cputc
    sta.z printf_ulong.putc+1
    // [1359] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:info_rom::@13->printf_ulong#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1359] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#0 [phi:info_rom::@13->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1165] phi from info_rom::@13 to info_rom::@14 [phi:info_rom::@13->info_rom::@14]
    // info_rom::@14
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1166] call printf_str
    // [700] phi from info_rom::@14 to printf_str [phi:info_rom::@14->printf_str]
    // [700] phi printf_str::putc#68 = &cputc [phi:info_rom::@14->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = info_rom::s4 [phi:info_rom::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@15
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1167] printf_ulong::uvalue#1 = rom_sizes[info_rom::$13] -- vduz1=pduc1_derefidx_vbuz2 
    ldy.z info_rom__13
    lda rom_sizes,y
    sta.z printf_ulong.uvalue
    lda rom_sizes+1,y
    sta.z printf_ulong.uvalue+1
    lda rom_sizes+2,y
    sta.z printf_ulong.uvalue+2
    lda rom_sizes+3,y
    sta.z printf_ulong.uvalue+3
    // [1168] call printf_ulong
    // [1359] phi from info_rom::@15 to printf_ulong [phi:info_rom::@15->printf_ulong]
    // [1359] phi printf_ulong::format_zero_padding#11 = 1 [phi:info_rom::@15->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1359] phi printf_ulong::format_min_length#11 = 5 [phi:info_rom::@15->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1359] phi printf_ulong::putc#11 = &cputc [phi:info_rom::@15->printf_ulong#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_ulong.putc
    lda #>cputc
    sta.z printf_ulong.putc+1
    // [1359] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:info_rom::@15->printf_ulong#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1359] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#1 [phi:info_rom::@15->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1169] phi from info_rom::@15 to info_rom::@16 [phi:info_rom::@15->info_rom::@16]
    // info_rom::@16
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1170] call printf_str
    // [700] phi from info_rom::@16 to printf_str [phi:info_rom::@16->printf_str]
    // [700] phi printf_str::putc#68 = &cputc [phi:info_rom::@16->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = s1 [phi:info_rom::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@17
    // if(info_text)
    // [1171] if((char *)0==info_rom::info_text#16) goto info_rom::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // info_rom::@2
    // printf("%-20s", info_text)
    // [1172] printf_string::str#9 = info_rom::info_text#16 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1173] call printf_string
    // [1184] phi from info_rom::@2 to printf_string [phi:info_rom::@2->printf_string]
    // [1184] phi printf_string::putc#18 = &cputc [phi:info_rom::@2->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1184] phi printf_string::str#18 = printf_string::str#9 [phi:info_rom::@2->printf_string#1] -- register_copy 
    // [1184] phi printf_string::format_justify_left#18 = 1 [phi:info_rom::@2->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1184] phi printf_string::format_min_length#18 = $14 [phi:info_rom::@2->printf_string#3] -- vbuz1=vbuc1 
    lda #$14
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_rom::@1
  __b1:
    // gotoxy(x,y)
    // [1174] gotoxy::x#18 = info_rom::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1175] gotoxy::y#18 = info_rom::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1176] call gotoxy
    // [557] phi from info_rom::@1 to gotoxy [phi:info_rom::@1->gotoxy]
    // [557] phi gotoxy::y#30 = gotoxy::y#18 [phi:info_rom::@1->gotoxy#0] -- register_copy 
    // [557] phi gotoxy::x#30 = gotoxy::x#18 [phi:info_rom::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // info_rom::@return
    // }
    // [1177] return 
    rts
  .segment Data
    s: .text "ROM"
    .byte 0
    s4: .text " / "
    .byte 0
    .label info_rom__10 = main.check_vera3_main__0
    .label rom_chip = main.check_roms2_check_rom1_main__0
    .label info_status = main.check_vera3_main__0
}
.segment Code
  // rom_file
// __mem() char * rom_file(__mem() char rom_chip)
rom_file: {
    // if(rom_chip)
    // [1179] if(0!=rom_file::rom_chip#2) goto rom_file::@1 -- 0_neq_vbum1_then_la1 
    lda rom_chip
    bne __b1
    // [1182] phi from rom_file to rom_file::@return [phi:rom_file->rom_file::@return]
    // [1182] phi rom_file::return#2 = rom_file::file_rom_cx16 [phi:rom_file->rom_file::@return#0] -- pbum1=pbuc1 
    lda #<file_rom_cx16
    sta return
    lda #>file_rom_cx16
    sta return+1
    rts
    // rom_file::@1
  __b1:
    // '0'+rom_chip
    // [1180] rom_file::$0 = '0' + rom_file::rom_chip#2 -- vbum1=vbuc1_plus_vbum1 
    lda #'0'
    clc
    adc rom_file__0
    sta rom_file__0
    // file_rom_card[3] = '0'+rom_chip
    // [1181] *(rom_file::file_rom_card+3) = rom_file::$0 -- _deref_pbuc1=vbum1 
    sta file_rom_card+3
    // [1182] phi from rom_file::@1 to rom_file::@return [phi:rom_file::@1->rom_file::@return]
    // [1182] phi rom_file::return#2 = rom_file::file_rom_card [phi:rom_file::@1->rom_file::@return#0] -- pbum1=pbuc1 
    lda #<file_rom_card
    sta return
    lda #>file_rom_card
    sta return+1
    // rom_file::@return
    // }
    // [1183] return 
    rts
  .segment Data
    file_rom_cx16: .text "ROM.BIN"
    .byte 0
    file_rom_card: .text "ROMn.BIN"
    .byte 0
    .label rom_file__0 = main.check_vera1_main__0
    return: .word 0
    .label rom_chip = main.check_vera1_main__0
}
.segment Code
  // printf_string
// Print a string value using a specific format
// Handles justification and min length 
// void printf_string(__zp($d3) void (*putc)(char), __zp($60) char *str, __zp($36) char format_min_length, __zp($e9) char format_justify_left)
printf_string: {
    .label printf_string__9 = $55
    .label len = $6c
    .label padding = $36
    .label str = $60
    .label format_min_length = $36
    .label format_justify_left = $e9
    .label putc = $d3
    // if(format.min_length)
    // [1185] if(0==printf_string::format_min_length#18) goto printf_string::@1 -- 0_eq_vbuz1_then_la1 
    lda.z format_min_length
    beq __b3
    // printf_string::@3
    // strlen(str)
    // [1186] strlen::str#3 = printf_string::str#18 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [1187] call strlen
    // [2121] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [2121] phi strlen::str#8 = strlen::str#3 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [1188] strlen::return#10 = strlen::len#2
    // printf_string::@6
    // [1189] printf_string::$9 = strlen::return#10
    // signed char len = (signed char)strlen(str)
    // [1190] printf_string::len#0 = (signed char)printf_string::$9 -- vbsz1=_sbyte_vwuz2 
    lda.z printf_string__9
    sta.z len
    // padding = (signed char)format.min_length  - len
    // [1191] printf_string::padding#1 = (signed char)printf_string::format_min_length#18 - printf_string::len#0 -- vbsz1=vbsz1_minus_vbsz2 
    lda.z padding
    sec
    sbc.z len
    sta.z padding
    // if(padding<0)
    // [1192] if(printf_string::padding#1>=0) goto printf_string::@10 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1194] phi from printf_string printf_string::@6 to printf_string::@1 [phi:printf_string/printf_string::@6->printf_string::@1]
  __b3:
    // [1194] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@6->printf_string::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [1193] phi from printf_string::@6 to printf_string::@10 [phi:printf_string::@6->printf_string::@10]
    // printf_string::@10
    // [1194] phi from printf_string::@10 to printf_string::@1 [phi:printf_string::@10->printf_string::@1]
    // [1194] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@10->printf_string::@1#0] -- register_copy 
    // printf_string::@1
  __b1:
    // if(!format.justify_left && padding)
    // [1195] if(0!=printf_string::format_justify_left#18) goto printf_string::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_justify_left
    bne __b2
    // printf_string::@8
    // [1196] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b4
    jmp __b2
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [1197] printf_padding::putc#3 = printf_string::putc#18 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1198] printf_padding::length#3 = (char)printf_string::padding#3 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1199] call printf_padding
    // [2127] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    // [2127] phi printf_padding::putc#7 = printf_padding::putc#3 [phi:printf_string::@4->printf_padding#0] -- register_copy 
    // [2127] phi printf_padding::pad#7 = ' ' [phi:printf_string::@4->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [2127] phi printf_padding::length#6 = printf_padding::length#3 [phi:printf_string::@4->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [1200] printf_str::putc#1 = printf_string::putc#18 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_str.putc
    lda.z putc+1
    sta.z printf_str.putc+1
    // [1201] printf_str::s#2 = printf_string::str#18
    // [1202] call printf_str
    // [700] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [700] phi printf_str::putc#68 = printf_str::putc#1 [phi:printf_string::@2->printf_str#0] -- register_copy 
    // [700] phi printf_str::s#68 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@7
    // if(format.justify_left && padding)
    // [1203] if(0==printf_string::format_justify_left#18) goto printf_string::@return -- 0_eq_vbuz1_then_la1 
    lda.z format_justify_left
    beq __breturn
    // printf_string::@9
    // [1204] if(0!=printf_string::padding#3) goto printf_string::@5 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b5
    rts
    // printf_string::@5
  __b5:
    // printf_padding(putc, ' ',(char)padding)
    // [1205] printf_padding::putc#4 = printf_string::putc#18 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1206] printf_padding::length#4 = (char)printf_string::padding#3 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1207] call printf_padding
    // [2127] phi from printf_string::@5 to printf_padding [phi:printf_string::@5->printf_padding]
    // [2127] phi printf_padding::putc#7 = printf_padding::putc#4 [phi:printf_string::@5->printf_padding#0] -- register_copy 
    // [2127] phi printf_padding::pad#7 = ' ' [phi:printf_string::@5->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [2127] phi printf_padding::length#6 = printf_padding::length#4 [phi:printf_string::@5->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@return
  __breturn:
    // }
    // [1208] return 
    rts
}
  // rom_read
// __mem() unsigned long rom_read(char rom_chip, __zp($ca) char *file, char info_status, __zp($5d) char brom_bank_start, __zp($77) unsigned long rom_size)
rom_read: {
    .const bank_set_brom1_bank = 0
    .label rom_read__11 = $ee
    .label rom_address = $57
    .label brom_bank_start = $5d
    .label ram_address = $a9
    .label rom_row_current = $75
    .label y = $2c
    .label bram_bank = $ad
    .label file = $ca
    .label rom_size = $77
    // unsigned long rom_address = rom_address_from_bank(brom_bank_start)
    // [1210] rom_address_from_bank::rom_bank#0 = rom_read::brom_bank_start#21 -- vbuz1=vbuz2 
    lda.z brom_bank_start
    sta.z rom_address_from_bank.rom_bank
    // [1211] call rom_address_from_bank
    // [2135] phi from rom_read to rom_address_from_bank [phi:rom_read->rom_address_from_bank]
    // [2135] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#0 [phi:rom_read->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(brom_bank_start)
    // [1212] rom_address_from_bank::return#2 = rom_address_from_bank::return#0
    // rom_read::@15
    // [1213] rom_read::rom_address#0 = rom_address_from_bank::return#2
    // rom_read::bank_set_bram1
    // BRAM = bank
    // [1214] BRAM = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z BRAM
    // rom_read::bank_set_brom1
    // BROM = bank
    // [1215] BROM = rom_read::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [1216] phi from rom_read::bank_set_brom1 to rom_read::@13 [phi:rom_read::bank_set_brom1->rom_read::@13]
    // rom_read::@13
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1217] call snprintf_init
    jsr snprintf_init
    // [1218] phi from rom_read::@13 to rom_read::@16 [phi:rom_read::@13->rom_read::@16]
    // rom_read::@16
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1219] call printf_str
    // [700] phi from rom_read::@16 to printf_str [phi:rom_read::@16->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:rom_read::@16->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = rom_read::s [phi:rom_read::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@17
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1220] printf_string::str#10 = rom_read::file#11 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [1221] call printf_string
    // [1184] phi from rom_read::@17 to printf_string [phi:rom_read::@17->printf_string]
    // [1184] phi printf_string::putc#18 = &snputc [phi:rom_read::@17->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1184] phi printf_string::str#18 = printf_string::str#10 [phi:rom_read::@17->printf_string#1] -- register_copy 
    // [1184] phi printf_string::format_justify_left#18 = 0 [phi:rom_read::@17->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1184] phi printf_string::format_min_length#18 = 0 [phi:rom_read::@17->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [1222] phi from rom_read::@17 to rom_read::@18 [phi:rom_read::@17->rom_read::@18]
    // rom_read::@18
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1223] call printf_str
    // [700] phi from rom_read::@18 to printf_str [phi:rom_read::@18->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:rom_read::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = rom_read::s1 [phi:rom_read::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@19
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1224] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1225] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [1227] call info_line
    // [931] phi from rom_read::@19 to info_line [phi:rom_read::@19->info_line]
    // [931] phi info_line::info_text#17 = info_text [phi:rom_read::@19->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    // rom_read::@20
    // FILE *fp = fopen(file, "r")
    // [1228] fopen::path#3 = rom_read::file#11 -- pbuz1=pbuz2 
    lda.z file
    sta.z fopen.path
    lda.z file+1
    sta.z fopen.path+1
    // [1229] call fopen
    // [1930] phi from rom_read::@20 to fopen [phi:rom_read::@20->fopen]
    // [1930] phi __errno#312 = __errno#105 [phi:rom_read::@20->fopen#0] -- register_copy 
    // [1930] phi fopen::pathtoken#0 = fopen::path#3 [phi:rom_read::@20->fopen#1] -- register_copy 
    jsr fopen
    // FILE *fp = fopen(file, "r")
    // [1230] fopen::return#4 = fopen::return#2
    // rom_read::@21
    // [1231] rom_read::fp#0 = fopen::return#4 -- pssm1=pssz2 
    lda.z fopen.return
    sta fp
    lda.z fopen.return+1
    sta fp+1
    // if (fp)
    // [1232] if((struct $2 *)0==rom_read::fp#0) goto rom_read::@1 -- pssc1_eq_pssm1_then_la1 
    lda fp
    cmp #<0
    bne !+
    lda fp+1
    cmp #>0
    beq __b2
  !:
    // [1233] phi from rom_read::@21 to rom_read::@2 [phi:rom_read::@21->rom_read::@2]
    // rom_read::@2
    // gotoxy(x, y)
    // [1234] call gotoxy
    // [557] phi from rom_read::@2 to gotoxy [phi:rom_read::@2->gotoxy]
    // [557] phi gotoxy::y#30 = PROGRESS_Y [phi:rom_read::@2->gotoxy#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z gotoxy.y
    // [557] phi gotoxy::x#30 = PROGRESS_X [phi:rom_read::@2->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [1235] phi from rom_read::@2 to rom_read::@3 [phi:rom_read::@2->rom_read::@3]
    // [1235] phi rom_read::y#11 = PROGRESS_Y [phi:rom_read::@2->rom_read::@3#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // [1235] phi rom_read::rom_row_current#10 = 0 [phi:rom_read::@2->rom_read::@3#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z rom_row_current
    sta.z rom_row_current+1
    // [1235] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#21 [phi:rom_read::@2->rom_read::@3#2] -- register_copy 
    // [1235] phi rom_read::rom_address#10 = rom_read::rom_address#0 [phi:rom_read::@2->rom_read::@3#3] -- register_copy 
    // [1235] phi rom_read::ram_address#10 = (char *)$6000 [phi:rom_read::@2->rom_read::@3#4] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z ram_address
    lda #>$6000
    sta.z ram_address+1
    // [1235] phi rom_read::bram_bank#10 = 0 [phi:rom_read::@2->rom_read::@3#5] -- vbuz1=vbuc1 
    lda #0
    sta.z bram_bank
    // [1235] phi rom_read::rom_file_size#11 = 0 [phi:rom_read::@2->rom_read::@3#6] -- vdum1=vduc1 
    sta rom_file_size
    sta rom_file_size+1
    lda #<0>>$10
    sta rom_file_size+2
    lda #>0>>$10
    sta rom_file_size+3
    // rom_read::@3
  __b3:
    // while (rom_file_size < rom_size)
    // [1236] if(rom_read::rom_file_size#11<rom_read::rom_size#12) goto rom_read::@4 -- vdum1_lt_vduz2_then_la1 
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
    // [1237] fclose::stream#1 = rom_read::fp#0 -- pssz1=pssm2 
    lda fp
    sta.z fclose.stream
    lda fp+1
    sta.z fclose.stream+1
    // [1238] call fclose
    // [2065] phi from rom_read::@7 to fclose [phi:rom_read::@7->fclose]
    // [2065] phi fclose::stream#2 = fclose::stream#1 [phi:rom_read::@7->fclose#0] -- register_copy 
    jsr fclose
    // [1239] phi from rom_read::@7 to rom_read::@1 [phi:rom_read::@7->rom_read::@1]
    // [1239] phi rom_read::return#0 = rom_read::rom_file_size#11 [phi:rom_read::@7->rom_read::@1#0] -- register_copy 
    rts
    // [1239] phi from rom_read::@21 to rom_read::@1 [phi:rom_read::@21->rom_read::@1]
  __b2:
    // [1239] phi rom_read::return#0 = 0 [phi:rom_read::@21->rom_read::@1#0] -- vdum1=vduc1 
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
    // [1240] return 
    rts
    // [1241] phi from rom_read::@3 to rom_read::@4 [phi:rom_read::@3->rom_read::@4]
    // rom_read::@4
  __b4:
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1242] call snprintf_init
    jsr snprintf_init
    // [1243] phi from rom_read::@4 to rom_read::@22 [phi:rom_read::@4->rom_read::@22]
    // rom_read::@22
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1244] call printf_str
    // [700] phi from rom_read::@22 to printf_str [phi:rom_read::@22->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:rom_read::@22->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = s14 [phi:rom_read::@22->printf_str#1] -- pbuz1=pbuc1 
    lda #<s14
    sta.z printf_str.s
    lda #>s14
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@23
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1245] printf_string::str#11 = rom_read::file#11 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [1246] call printf_string
    // [1184] phi from rom_read::@23 to printf_string [phi:rom_read::@23->printf_string]
    // [1184] phi printf_string::putc#18 = &snputc [phi:rom_read::@23->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1184] phi printf_string::str#18 = printf_string::str#11 [phi:rom_read::@23->printf_string#1] -- register_copy 
    // [1184] phi printf_string::format_justify_left#18 = 0 [phi:rom_read::@23->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1184] phi printf_string::format_min_length#18 = 0 [phi:rom_read::@23->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [1247] phi from rom_read::@23 to rom_read::@24 [phi:rom_read::@23->rom_read::@24]
    // rom_read::@24
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1248] call printf_str
    // [700] phi from rom_read::@24 to printf_str [phi:rom_read::@24->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:rom_read::@24->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = s3 [phi:rom_read::@24->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@25
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1249] printf_ulong::uvalue#2 = rom_read::rom_file_size#11 -- vduz1=vdum2 
    lda rom_file_size
    sta.z printf_ulong.uvalue
    lda rom_file_size+1
    sta.z printf_ulong.uvalue+1
    lda rom_file_size+2
    sta.z printf_ulong.uvalue+2
    lda rom_file_size+3
    sta.z printf_ulong.uvalue+3
    // [1250] call printf_ulong
    // [1359] phi from rom_read::@25 to printf_ulong [phi:rom_read::@25->printf_ulong]
    // [1359] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_read::@25->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1359] phi printf_ulong::format_min_length#11 = 5 [phi:rom_read::@25->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1359] phi printf_ulong::putc#11 = &snputc [phi:rom_read::@25->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1359] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_read::@25->printf_ulong#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1359] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#2 [phi:rom_read::@25->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1251] phi from rom_read::@25 to rom_read::@26 [phi:rom_read::@25->rom_read::@26]
    // rom_read::@26
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1252] call printf_str
    // [700] phi from rom_read::@26 to printf_str [phi:rom_read::@26->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:rom_read::@26->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = s4 [phi:rom_read::@26->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@27
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1253] printf_ulong::uvalue#3 = rom_read::rom_size#12 -- vduz1=vduz2 
    lda.z rom_size
    sta.z printf_ulong.uvalue
    lda.z rom_size+1
    sta.z printf_ulong.uvalue+1
    lda.z rom_size+2
    sta.z printf_ulong.uvalue+2
    lda.z rom_size+3
    sta.z printf_ulong.uvalue+3
    // [1254] call printf_ulong
    // [1359] phi from rom_read::@27 to printf_ulong [phi:rom_read::@27->printf_ulong]
    // [1359] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_read::@27->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1359] phi printf_ulong::format_min_length#11 = 5 [phi:rom_read::@27->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1359] phi printf_ulong::putc#11 = &snputc [phi:rom_read::@27->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1359] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_read::@27->printf_ulong#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1359] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#3 [phi:rom_read::@27->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1255] phi from rom_read::@27 to rom_read::@28 [phi:rom_read::@27->rom_read::@28]
    // rom_read::@28
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1256] call printf_str
    // [700] phi from rom_read::@28 to printf_str [phi:rom_read::@28->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:rom_read::@28->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = s2 [phi:rom_read::@28->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@29
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1257] printf_uchar::uvalue#5 = rom_read::bram_bank#10 -- vbuz1=vbuz2 
    lda.z bram_bank
    sta.z printf_uchar.uvalue
    // [1258] call printf_uchar
    // [1122] phi from rom_read::@29 to printf_uchar [phi:rom_read::@29->printf_uchar]
    // [1122] phi printf_uchar::format_zero_padding#10 = 1 [phi:rom_read::@29->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1122] phi printf_uchar::format_min_length#10 = 2 [phi:rom_read::@29->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [1122] phi printf_uchar::putc#10 = &snputc [phi:rom_read::@29->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1122] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:rom_read::@29->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [1122] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#5 [phi:rom_read::@29->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1259] phi from rom_read::@29 to rom_read::@30 [phi:rom_read::@29->rom_read::@30]
    // rom_read::@30
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1260] call printf_str
    // [700] phi from rom_read::@30 to printf_str [phi:rom_read::@30->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:rom_read::@30->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = s3 [phi:rom_read::@30->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@31
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1261] printf_uint::uvalue#10 = (unsigned int)rom_read::ram_address#10 -- vwuz1=vwuz2 
    lda.z ram_address
    sta.z printf_uint.uvalue
    lda.z ram_address+1
    sta.z printf_uint.uvalue+1
    // [1262] call printf_uint
    // [709] phi from rom_read::@31 to printf_uint [phi:rom_read::@31->printf_uint]
    // [709] phi printf_uint::format_zero_padding#16 = 1 [phi:rom_read::@31->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [709] phi printf_uint::format_min_length#16 = 4 [phi:rom_read::@31->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [709] phi printf_uint::putc#16 = &snputc [phi:rom_read::@31->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [709] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:rom_read::@31->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [709] phi printf_uint::uvalue#16 = printf_uint::uvalue#10 [phi:rom_read::@31->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1263] phi from rom_read::@31 to rom_read::@32 [phi:rom_read::@31->rom_read::@32]
    // rom_read::@32
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1264] call printf_str
    // [700] phi from rom_read::@32 to printf_str [phi:rom_read::@32->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:rom_read::@32->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = s7 [phi:rom_read::@32->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@33
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address)
    // [1265] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1266] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [1268] call info_line
    // [931] phi from rom_read::@33 to info_line [phi:rom_read::@33->info_line]
    // [931] phi info_line::info_text#17 = info_text [phi:rom_read::@33->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    // rom_read::@34
    // rom_address % 0x04000
    // [1269] rom_read::$11 = rom_read::rom_address#10 & $4000-1 -- vduz1=vduz2_band_vduc1 
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
    // [1270] if(0!=rom_read::$11) goto rom_read::@5 -- 0_neq_vduz1_then_la1 
    lda.z rom_read__11
    ora.z rom_read__11+1
    ora.z rom_read__11+2
    ora.z rom_read__11+3
    bne __b5
    // rom_read::@10
    // brom_bank_start++;
    // [1271] rom_read::brom_bank_start#0 = ++ rom_read::brom_bank_start#10 -- vbuz1=_inc_vbuz1 
    inc.z brom_bank_start
    // [1272] phi from rom_read::@10 rom_read::@34 to rom_read::@5 [phi:rom_read::@10/rom_read::@34->rom_read::@5]
    // [1272] phi rom_read::brom_bank_start#20 = rom_read::brom_bank_start#0 [phi:rom_read::@10/rom_read::@34->rom_read::@5#0] -- register_copy 
    // rom_read::@5
  __b5:
    // rom_read::bank_set_bram2
    // BRAM = bank
    // [1273] BRAM = rom_read::bram_bank#10 -- vbuz1=vbuz2 
    lda.z bram_bank
    sta.z BRAM
    // rom_read::@14
    // unsigned int rom_package_read = fgets(ram_address, PROGRESS_CELL, fp)
    // [1274] fgets::ptr#3 = rom_read::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z fgets.ptr
    lda.z ram_address+1
    sta.z fgets.ptr+1
    // [1275] fgets::stream#1 = rom_read::fp#0 -- pssm1=pssm2 
    lda fp
    sta fgets.stream
    lda fp+1
    sta fgets.stream+1
    // [1276] call fgets
    // [2011] phi from rom_read::@14 to fgets [phi:rom_read::@14->fgets]
    // [2011] phi fgets::ptr#12 = fgets::ptr#3 [phi:rom_read::@14->fgets#0] -- register_copy 
    // [2011] phi fgets::size#10 = PROGRESS_CELL [phi:rom_read::@14->fgets#1] -- vwuz1=vwuc1 
    lda #<PROGRESS_CELL
    sta.z fgets.size
    lda #>PROGRESS_CELL
    sta.z fgets.size+1
    // [2011] phi fgets::stream#2 = fgets::stream#1 [phi:rom_read::@14->fgets#2] -- register_copy 
    jsr fgets
    // unsigned int rom_package_read = fgets(ram_address, PROGRESS_CELL, fp)
    // [1277] fgets::return#6 = fgets::return#1
    // rom_read::@35
    // [1278] rom_read::rom_package_read#0 = fgets::return#6 -- vwum1=vwuz2 
    lda.z fgets.return
    sta rom_package_read
    lda.z fgets.return+1
    sta rom_package_read+1
    // if (!rom_package_read)
    // [1279] if(0!=rom_read::rom_package_read#0) goto rom_read::@6 -- 0_neq_vwum1_then_la1 
    lda rom_package_read
    ora rom_package_read+1
    bne __b6
    jmp __b7
    // rom_read::@6
  __b6:
    // if (rom_row_current == PROGRESS_ROW)
    // [1280] if(rom_read::rom_row_current#10!=PROGRESS_ROW) goto rom_read::@8 -- vwuz1_neq_vwuc1_then_la1 
    lda.z rom_row_current+1
    cmp #>PROGRESS_ROW
    bne __b8
    lda.z rom_row_current
    cmp #<PROGRESS_ROW
    bne __b8
    // rom_read::@11
    // gotoxy(x, ++y);
    // [1281] rom_read::y#1 = ++ rom_read::y#11 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [1282] gotoxy::y#25 = rom_read::y#1 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1283] call gotoxy
    // [557] phi from rom_read::@11 to gotoxy [phi:rom_read::@11->gotoxy]
    // [557] phi gotoxy::y#30 = gotoxy::y#25 [phi:rom_read::@11->gotoxy#0] -- register_copy 
    // [557] phi gotoxy::x#30 = PROGRESS_X [phi:rom_read::@11->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [1284] phi from rom_read::@11 to rom_read::@8 [phi:rom_read::@11->rom_read::@8]
    // [1284] phi rom_read::y#36 = rom_read::y#1 [phi:rom_read::@11->rom_read::@8#0] -- register_copy 
    // [1284] phi rom_read::rom_row_current#4 = 0 [phi:rom_read::@11->rom_read::@8#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z rom_row_current
    sta.z rom_row_current+1
    // [1284] phi from rom_read::@6 to rom_read::@8 [phi:rom_read::@6->rom_read::@8]
    // [1284] phi rom_read::y#36 = rom_read::y#11 [phi:rom_read::@6->rom_read::@8#0] -- register_copy 
    // [1284] phi rom_read::rom_row_current#4 = rom_read::rom_row_current#10 [phi:rom_read::@6->rom_read::@8#1] -- register_copy 
    // rom_read::@8
  __b8:
    // cputc('.')
    // [1285] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [1286] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // ram_address += rom_package_read
    // [1288] rom_read::ram_address#1 = rom_read::ram_address#10 + rom_read::rom_package_read#0 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z ram_address
    adc rom_package_read
    sta.z ram_address
    lda.z ram_address+1
    adc rom_package_read+1
    sta.z ram_address+1
    // rom_address += rom_package_read
    // [1289] rom_read::rom_address#1 = rom_read::rom_address#10 + rom_read::rom_package_read#0 -- vduz1=vduz1_plus_vwum2 
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
    // [1290] rom_read::rom_file_size#1 = rom_read::rom_file_size#11 + rom_read::rom_package_read#0 -- vdum1=vdum1_plus_vwum2 
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
    // [1291] rom_read::rom_row_current#1 = rom_read::rom_row_current#4 + rom_read::rom_package_read#0 -- vwuz1=vwuz1_plus_vwum2 
    clc
    lda.z rom_row_current
    adc rom_package_read
    sta.z rom_row_current
    lda.z rom_row_current+1
    adc rom_package_read+1
    sta.z rom_row_current+1
    // if (ram_address == (ram_ptr_t)BRAM_HIGH)
    // [1292] if(rom_read::ram_address#1!=(char *)$c000) goto rom_read::@9 -- pbuz1_neq_pbuc1_then_la1 
    lda.z ram_address+1
    cmp #>$c000
    bne __b9
    lda.z ram_address
    cmp #<$c000
    bne __b9
    // rom_read::@12
    // bram_bank++;
    // [1293] rom_read::bram_bank#1 = ++ rom_read::bram_bank#10 -- vbuz1=_inc_vbuz1 
    inc.z bram_bank
    // [1294] phi from rom_read::@12 to rom_read::@9 [phi:rom_read::@12->rom_read::@9]
    // [1294] phi rom_read::bram_bank#30 = rom_read::bram_bank#1 [phi:rom_read::@12->rom_read::@9#0] -- register_copy 
    // [1294] phi rom_read::ram_address#7 = (char *)$a000 [phi:rom_read::@12->rom_read::@9#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1294] phi from rom_read::@8 to rom_read::@9 [phi:rom_read::@8->rom_read::@9]
    // [1294] phi rom_read::bram_bank#30 = rom_read::bram_bank#10 [phi:rom_read::@8->rom_read::@9#0] -- register_copy 
    // [1294] phi rom_read::ram_address#7 = rom_read::ram_address#1 [phi:rom_read::@8->rom_read::@9#1] -- register_copy 
    // rom_read::@9
  __b9:
    // if (ram_address == (ram_ptr_t)RAM_HIGH)
    // [1295] if(rom_read::ram_address#7!=(char *)$8000) goto rom_read::@36 -- pbuz1_neq_pbuc1_then_la1 
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
    // [1235] phi from rom_read::@9 to rom_read::@3 [phi:rom_read::@9->rom_read::@3]
    // [1235] phi rom_read::y#11 = rom_read::y#36 [phi:rom_read::@9->rom_read::@3#0] -- register_copy 
    // [1235] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#1 [phi:rom_read::@9->rom_read::@3#1] -- register_copy 
    // [1235] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#20 [phi:rom_read::@9->rom_read::@3#2] -- register_copy 
    // [1235] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@9->rom_read::@3#3] -- register_copy 
    // [1235] phi rom_read::ram_address#10 = (char *)$a000 [phi:rom_read::@9->rom_read::@3#4] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1235] phi rom_read::bram_bank#10 = 1 [phi:rom_read::@9->rom_read::@3#5] -- vbuz1=vbuc1 
    lda #1
    sta.z bram_bank
    // [1235] phi rom_read::rom_file_size#11 = rom_read::rom_file_size#1 [phi:rom_read::@9->rom_read::@3#6] -- register_copy 
    jmp __b3
    // [1296] phi from rom_read::@9 to rom_read::@36 [phi:rom_read::@9->rom_read::@36]
    // rom_read::@36
    // [1235] phi from rom_read::@36 to rom_read::@3 [phi:rom_read::@36->rom_read::@3]
    // [1235] phi rom_read::y#11 = rom_read::y#36 [phi:rom_read::@36->rom_read::@3#0] -- register_copy 
    // [1235] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#1 [phi:rom_read::@36->rom_read::@3#1] -- register_copy 
    // [1235] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#20 [phi:rom_read::@36->rom_read::@3#2] -- register_copy 
    // [1235] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@36->rom_read::@3#3] -- register_copy 
    // [1235] phi rom_read::ram_address#10 = rom_read::ram_address#7 [phi:rom_read::@36->rom_read::@3#4] -- register_copy 
    // [1235] phi rom_read::bram_bank#10 = rom_read::bram_bank#30 [phi:rom_read::@36->rom_read::@3#5] -- register_copy 
    // [1235] phi rom_read::rom_file_size#11 = rom_read::rom_file_size#1 [phi:rom_read::@36->rom_read::@3#6] -- register_copy 
  .segment Data
    s: .text "Opening "
    .byte 0
    s1: .text " from SD card ..."
    .byte 0
    fp: .word 0
    return: .dword 0
    .label rom_package_read = rom_read_byte.rom_bank1_rom_read_byte__2
    .label rom_file_size = return
}
.segment Code
  // rom_verify
// __zp($b0) unsigned long rom_verify(__mem() char rom_chip, __zp($fb) char rom_bank_start, __mem() unsigned long file_size)
rom_verify: {
    .label rom_verify__16 = $51
    .label rom_address = $7c
    .label equal_bytes = $51
    .label y = $5b
    .label ram_address = $d1
    .label bram_bank = $54
    .label rom_different_bytes = $b0
    .label rom_bank_start = $fb
    .label return = $b0
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [1297] rom_address_from_bank::rom_bank#1 = rom_verify::rom_bank_start#0
    // [1298] call rom_address_from_bank
    // [2135] phi from rom_verify to rom_address_from_bank [phi:rom_verify->rom_address_from_bank]
    // [2135] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#1 [phi:rom_verify->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [1299] rom_address_from_bank::return#3 = rom_address_from_bank::return#0 -- vduz1=vduz2 
    lda.z rom_address_from_bank.return
    sta.z rom_address_from_bank.return_1
    lda.z rom_address_from_bank.return+1
    sta.z rom_address_from_bank.return_1+1
    lda.z rom_address_from_bank.return+2
    sta.z rom_address_from_bank.return_1+2
    lda.z rom_address_from_bank.return+3
    sta.z rom_address_from_bank.return_1+3
    // rom_verify::@11
    // [1300] rom_verify::rom_address#0 = rom_address_from_bank::return#3
    // unsigned long rom_boundary = rom_address + file_size
    // [1301] rom_verify::rom_boundary#0 = rom_verify::rom_address#0 + rom_verify::file_size#0 -- vdum1=vduz2_plus_vdum1 
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
    // info_rom(rom_chip, STATUS_COMPARING, "Comparing ...")
    // [1302] info_rom::rom_chip#1 = rom_verify::rom_chip#0
    // [1303] call info_rom
    // [1133] phi from rom_verify::@11 to info_rom [phi:rom_verify::@11->info_rom]
    // [1133] phi info_rom::info_text#16 = rom_verify::info_text [phi:rom_verify::@11->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_rom.info_text
    lda #>info_text
    sta.z info_rom.info_text+1
    // [1133] phi info_rom::rom_chip#16 = info_rom::rom_chip#1 [phi:rom_verify::@11->info_rom#1] -- register_copy 
    // [1133] phi info_rom::info_status#16 = STATUS_COMPARING [phi:rom_verify::@11->info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_COMPARING
    sta info_rom.info_status
    jsr info_rom
    // [1304] phi from rom_verify::@11 to rom_verify::@12 [phi:rom_verify::@11->rom_verify::@12]
    // rom_verify::@12
    // gotoxy(x, y)
    // [1305] call gotoxy
    // [557] phi from rom_verify::@12 to gotoxy [phi:rom_verify::@12->gotoxy]
    // [557] phi gotoxy::y#30 = PROGRESS_Y [phi:rom_verify::@12->gotoxy#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z gotoxy.y
    // [557] phi gotoxy::x#30 = PROGRESS_X [phi:rom_verify::@12->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [1306] phi from rom_verify::@12 to rom_verify::@1 [phi:rom_verify::@12->rom_verify::@1]
    // [1306] phi rom_verify::y#3 = PROGRESS_Y [phi:rom_verify::@12->rom_verify::@1#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // [1306] phi rom_verify::progress_row_current#3 = 0 [phi:rom_verify::@12->rom_verify::@1#1] -- vwum1=vwuc1 
    lda #<0
    sta progress_row_current
    sta progress_row_current+1
    // [1306] phi rom_verify::rom_different_bytes#11 = 0 [phi:rom_verify::@12->rom_verify::@1#2] -- vduz1=vduc1 
    sta.z rom_different_bytes
    sta.z rom_different_bytes+1
    lda #<0>>$10
    sta.z rom_different_bytes+2
    lda #>0>>$10
    sta.z rom_different_bytes+3
    // [1306] phi rom_verify::ram_address#10 = (char *)$6000 [phi:rom_verify::@12->rom_verify::@1#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z ram_address
    lda #>$6000
    sta.z ram_address+1
    // [1306] phi rom_verify::bram_bank#11 = 0 [phi:rom_verify::@12->rom_verify::@1#4] -- vbuz1=vbuc1 
    lda #0
    sta.z bram_bank
    // [1306] phi rom_verify::rom_address#12 = rom_verify::rom_address#0 [phi:rom_verify::@12->rom_verify::@1#5] -- register_copy 
    // rom_verify::@1
  __b1:
    // while (rom_address < rom_boundary)
    // [1307] if(rom_verify::rom_address#12<rom_verify::rom_boundary#0) goto rom_verify::@2 -- vduz1_lt_vdum2_then_la1 
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
    // [1308] return 
    rts
    // rom_verify::@2
  __b2:
    // unsigned int equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1309] rom_compare::bank_ram#0 = rom_verify::bram_bank#11 -- vbuz1=vbuz2 
    lda.z bram_bank
    sta.z rom_compare.bank_ram
    // [1310] rom_compare::ptr_ram#1 = rom_verify::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_compare.ptr_ram
    lda.z ram_address+1
    sta.z rom_compare.ptr_ram+1
    // [1311] rom_compare::rom_compare_address#0 = rom_verify::rom_address#12 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_compare.rom_compare_address
    lda.z rom_address+1
    sta.z rom_compare.rom_compare_address+1
    lda.z rom_address+2
    sta.z rom_compare.rom_compare_address+2
    lda.z rom_address+3
    sta.z rom_compare.rom_compare_address+3
    // [1312] call rom_compare
  // {asm{.byte $db}}
    // [2139] phi from rom_verify::@2 to rom_compare [phi:rom_verify::@2->rom_compare]
    // [2139] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#1 [phi:rom_verify::@2->rom_compare#0] -- register_copy 
    // [2139] phi rom_compare::rom_compare_size#11 = PROGRESS_CELL [phi:rom_verify::@2->rom_compare#1] -- vwuz1=vwuc1 
    lda #<PROGRESS_CELL
    sta.z rom_compare.rom_compare_size
    lda #>PROGRESS_CELL
    sta.z rom_compare.rom_compare_size+1
    // [2139] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#0 [phi:rom_verify::@2->rom_compare#2] -- register_copy 
    // [2139] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#0 [phi:rom_verify::@2->rom_compare#3] -- register_copy 
    jsr rom_compare
    // unsigned int equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1313] rom_compare::return#2 = rom_compare::equal_bytes#2
    // rom_verify::@13
    // [1314] rom_verify::equal_bytes#0 = rom_compare::return#2
    // if (progress_row_current == PROGRESS_ROW)
    // [1315] if(rom_verify::progress_row_current#3!=PROGRESS_ROW) goto rom_verify::@3 -- vwum1_neq_vwuc1_then_la1 
    lda progress_row_current+1
    cmp #>PROGRESS_ROW
    bne __b3
    lda progress_row_current
    cmp #<PROGRESS_ROW
    bne __b3
    // rom_verify::@8
    // gotoxy(x, ++y);
    // [1316] rom_verify::y#1 = ++ rom_verify::y#3 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [1317] gotoxy::y#27 = rom_verify::y#1 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1318] call gotoxy
    // [557] phi from rom_verify::@8 to gotoxy [phi:rom_verify::@8->gotoxy]
    // [557] phi gotoxy::y#30 = gotoxy::y#27 [phi:rom_verify::@8->gotoxy#0] -- register_copy 
    // [557] phi gotoxy::x#30 = PROGRESS_X [phi:rom_verify::@8->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [1319] phi from rom_verify::@8 to rom_verify::@3 [phi:rom_verify::@8->rom_verify::@3]
    // [1319] phi rom_verify::y#10 = rom_verify::y#1 [phi:rom_verify::@8->rom_verify::@3#0] -- register_copy 
    // [1319] phi rom_verify::progress_row_current#4 = 0 [phi:rom_verify::@8->rom_verify::@3#1] -- vwum1=vbuc1 
    lda #<0
    sta progress_row_current
    sta progress_row_current+1
    // [1319] phi from rom_verify::@13 to rom_verify::@3 [phi:rom_verify::@13->rom_verify::@3]
    // [1319] phi rom_verify::y#10 = rom_verify::y#3 [phi:rom_verify::@13->rom_verify::@3#0] -- register_copy 
    // [1319] phi rom_verify::progress_row_current#4 = rom_verify::progress_row_current#3 [phi:rom_verify::@13->rom_verify::@3#1] -- register_copy 
    // rom_verify::@3
  __b3:
    // if (equal_bytes != PROGRESS_CELL)
    // [1320] if(rom_verify::equal_bytes#0!=PROGRESS_CELL) goto rom_verify::@4 -- vwuz1_neq_vwuc1_then_la1 
    lda.z equal_bytes+1
    cmp #>PROGRESS_CELL
    beq !__b4+
    jmp __b4
  !__b4:
    lda.z equal_bytes
    cmp #<PROGRESS_CELL
    beq !__b4+
    jmp __b4
  !__b4:
    // rom_verify::@9
    // cputc('=')
    // [1321] stackpush(char) = '=' -- _stackpushbyte_=vbuc1 
    lda #'='
    pha
    // [1322] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // rom_verify::@5
  __b5:
    // ram_address += PROGRESS_CELL
    // [1324] rom_verify::ram_address#1 = rom_verify::ram_address#10 + PROGRESS_CELL -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address
    clc
    adc #<PROGRESS_CELL
    sta.z ram_address
    lda.z ram_address+1
    adc #>PROGRESS_CELL
    sta.z ram_address+1
    // rom_address += PROGRESS_CELL
    // [1325] rom_verify::rom_address#1 = rom_verify::rom_address#12 + PROGRESS_CELL -- vduz1=vduz1_plus_vwuc1 
    clc
    lda.z rom_address
    adc #<PROGRESS_CELL
    sta.z rom_address
    lda.z rom_address+1
    adc #>PROGRESS_CELL
    sta.z rom_address+1
    lda.z rom_address+2
    adc #0
    sta.z rom_address+2
    lda.z rom_address+3
    adc #0
    sta.z rom_address+3
    // progress_row_current += PROGRESS_CELL
    // [1326] rom_verify::progress_row_current#11 = rom_verify::progress_row_current#4 + PROGRESS_CELL -- vwum1=vwum1_plus_vwuc1 
    lda progress_row_current
    clc
    adc #<PROGRESS_CELL
    sta progress_row_current
    lda progress_row_current+1
    adc #>PROGRESS_CELL
    sta progress_row_current+1
    // if (ram_address == BRAM_HIGH)
    // [1327] if(rom_verify::ram_address#1!=$c000) goto rom_verify::@6 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address+1
    cmp #>$c000
    bne __b6
    lda.z ram_address
    cmp #<$c000
    bne __b6
    // rom_verify::@10
    // bram_bank++;
    // [1328] rom_verify::bram_bank#1 = ++ rom_verify::bram_bank#11 -- vbuz1=_inc_vbuz1 
    inc.z bram_bank
    // [1329] phi from rom_verify::@10 to rom_verify::@6 [phi:rom_verify::@10->rom_verify::@6]
    // [1329] phi rom_verify::bram_bank#24 = rom_verify::bram_bank#1 [phi:rom_verify::@10->rom_verify::@6#0] -- register_copy 
    // [1329] phi rom_verify::ram_address#6 = (char *)$a000 [phi:rom_verify::@10->rom_verify::@6#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1329] phi from rom_verify::@5 to rom_verify::@6 [phi:rom_verify::@5->rom_verify::@6]
    // [1329] phi rom_verify::bram_bank#24 = rom_verify::bram_bank#11 [phi:rom_verify::@5->rom_verify::@6#0] -- register_copy 
    // [1329] phi rom_verify::ram_address#6 = rom_verify::ram_address#1 [phi:rom_verify::@5->rom_verify::@6#1] -- register_copy 
    // rom_verify::@6
  __b6:
    // if (ram_address == RAM_HIGH)
    // [1330] if(rom_verify::ram_address#6!=$8000) goto rom_verify::@23 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address+1
    cmp #>$8000
    bne __b7
    lda.z ram_address
    cmp #<$8000
    bne __b7
    // [1332] phi from rom_verify::@6 to rom_verify::@7 [phi:rom_verify::@6->rom_verify::@7]
    // [1332] phi rom_verify::ram_address#11 = (char *)$a000 [phi:rom_verify::@6->rom_verify::@7#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1332] phi rom_verify::bram_bank#10 = 1 [phi:rom_verify::@6->rom_verify::@7#1] -- vbuz1=vbuc1 
    lda #1
    sta.z bram_bank
    // [1331] phi from rom_verify::@6 to rom_verify::@23 [phi:rom_verify::@6->rom_verify::@23]
    // rom_verify::@23
    // [1332] phi from rom_verify::@23 to rom_verify::@7 [phi:rom_verify::@23->rom_verify::@7]
    // [1332] phi rom_verify::ram_address#11 = rom_verify::ram_address#6 [phi:rom_verify::@23->rom_verify::@7#0] -- register_copy 
    // [1332] phi rom_verify::bram_bank#10 = rom_verify::bram_bank#24 [phi:rom_verify::@23->rom_verify::@7#1] -- register_copy 
    // rom_verify::@7
  __b7:
    // PROGRESS_CELL - equal_bytes
    // [1333] rom_verify::$16 = PROGRESS_CELL - rom_verify::equal_bytes#0 -- vwuz1=vwuc1_minus_vwuz1 
    lda #<PROGRESS_CELL
    sec
    sbc.z rom_verify__16
    sta.z rom_verify__16
    lda #>PROGRESS_CELL
    sbc.z rom_verify__16+1
    sta.z rom_verify__16+1
    // rom_different_bytes += (PROGRESS_CELL - equal_bytes)
    // [1334] rom_verify::rom_different_bytes#1 = rom_verify::rom_different_bytes#11 + rom_verify::$16 -- vduz1=vduz1_plus_vwuz2 
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
    // [1335] call snprintf_init
    jsr snprintf_init
    // [1336] phi from rom_verify::@7 to rom_verify::@14 [phi:rom_verify::@7->rom_verify::@14]
    // rom_verify::@14
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1337] call printf_str
    // [700] phi from rom_verify::@14 to printf_str [phi:rom_verify::@14->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:rom_verify::@14->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = rom_verify::s [phi:rom_verify::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@15
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1338] printf_ulong::uvalue#4 = rom_verify::rom_different_bytes#1 -- vduz1=vduz2 
    lda.z rom_different_bytes
    sta.z printf_ulong.uvalue
    lda.z rom_different_bytes+1
    sta.z printf_ulong.uvalue+1
    lda.z rom_different_bytes+2
    sta.z printf_ulong.uvalue+2
    lda.z rom_different_bytes+3
    sta.z printf_ulong.uvalue+3
    // [1339] call printf_ulong
    // [1359] phi from rom_verify::@15 to printf_ulong [phi:rom_verify::@15->printf_ulong]
    // [1359] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_verify::@15->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1359] phi printf_ulong::format_min_length#11 = 5 [phi:rom_verify::@15->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1359] phi printf_ulong::putc#11 = &snputc [phi:rom_verify::@15->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1359] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_verify::@15->printf_ulong#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1359] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#4 [phi:rom_verify::@15->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1340] phi from rom_verify::@15 to rom_verify::@16 [phi:rom_verify::@15->rom_verify::@16]
    // rom_verify::@16
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1341] call printf_str
    // [700] phi from rom_verify::@16 to printf_str [phi:rom_verify::@16->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:rom_verify::@16->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = rom_verify::s1 [phi:rom_verify::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@17
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1342] printf_uchar::uvalue#6 = rom_verify::bram_bank#10 -- vbuz1=vbuz2 
    lda.z bram_bank
    sta.z printf_uchar.uvalue
    // [1343] call printf_uchar
    // [1122] phi from rom_verify::@17 to printf_uchar [phi:rom_verify::@17->printf_uchar]
    // [1122] phi printf_uchar::format_zero_padding#10 = 1 [phi:rom_verify::@17->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1122] phi printf_uchar::format_min_length#10 = 2 [phi:rom_verify::@17->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [1122] phi printf_uchar::putc#10 = &snputc [phi:rom_verify::@17->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1122] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:rom_verify::@17->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [1122] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#6 [phi:rom_verify::@17->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1344] phi from rom_verify::@17 to rom_verify::@18 [phi:rom_verify::@17->rom_verify::@18]
    // rom_verify::@18
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1345] call printf_str
    // [700] phi from rom_verify::@18 to printf_str [phi:rom_verify::@18->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:rom_verify::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = s3 [phi:rom_verify::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s3
    sta.z printf_str.s
    lda #>@s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@19
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1346] printf_uint::uvalue#11 = (unsigned int)rom_verify::ram_address#11 -- vwuz1=vwuz2 
    lda.z ram_address
    sta.z printf_uint.uvalue
    lda.z ram_address+1
    sta.z printf_uint.uvalue+1
    // [1347] call printf_uint
    // [709] phi from rom_verify::@19 to printf_uint [phi:rom_verify::@19->printf_uint]
    // [709] phi printf_uint::format_zero_padding#16 = 1 [phi:rom_verify::@19->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [709] phi printf_uint::format_min_length#16 = 4 [phi:rom_verify::@19->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [709] phi printf_uint::putc#16 = &snputc [phi:rom_verify::@19->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [709] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:rom_verify::@19->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [709] phi printf_uint::uvalue#16 = printf_uint::uvalue#11 [phi:rom_verify::@19->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1348] phi from rom_verify::@19 to rom_verify::@20 [phi:rom_verify::@19->rom_verify::@20]
    // rom_verify::@20
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1349] call printf_str
    // [700] phi from rom_verify::@20 to printf_str [phi:rom_verify::@20->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:rom_verify::@20->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = rom_verify::s3 [phi:rom_verify::@20->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@21
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1350] printf_ulong::uvalue#5 = rom_verify::rom_address#1 -- vduz1=vduz2 
    lda.z rom_address
    sta.z printf_ulong.uvalue
    lda.z rom_address+1
    sta.z printf_ulong.uvalue+1
    lda.z rom_address+2
    sta.z printf_ulong.uvalue+2
    lda.z rom_address+3
    sta.z printf_ulong.uvalue+3
    // [1351] call printf_ulong
    // [1359] phi from rom_verify::@21 to printf_ulong [phi:rom_verify::@21->printf_ulong]
    // [1359] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_verify::@21->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1359] phi printf_ulong::format_min_length#11 = 5 [phi:rom_verify::@21->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1359] phi printf_ulong::putc#11 = &snputc [phi:rom_verify::@21->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1359] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_verify::@21->printf_ulong#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1359] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#5 [phi:rom_verify::@21->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // rom_verify::@22
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1352] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1353] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [1355] call info_line
    // [931] phi from rom_verify::@22 to info_line [phi:rom_verify::@22->info_line]
    // [931] phi info_line::info_text#17 = info_text [phi:rom_verify::@22->info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_line.info_text
    lda #>@info_text
    sta.z info_line.info_text+1
    jsr info_line
    // [1306] phi from rom_verify::@22 to rom_verify::@1 [phi:rom_verify::@22->rom_verify::@1]
    // [1306] phi rom_verify::y#3 = rom_verify::y#10 [phi:rom_verify::@22->rom_verify::@1#0] -- register_copy 
    // [1306] phi rom_verify::progress_row_current#3 = rom_verify::progress_row_current#11 [phi:rom_verify::@22->rom_verify::@1#1] -- register_copy 
    // [1306] phi rom_verify::rom_different_bytes#11 = rom_verify::rom_different_bytes#1 [phi:rom_verify::@22->rom_verify::@1#2] -- register_copy 
    // [1306] phi rom_verify::ram_address#10 = rom_verify::ram_address#11 [phi:rom_verify::@22->rom_verify::@1#3] -- register_copy 
    // [1306] phi rom_verify::bram_bank#11 = rom_verify::bram_bank#10 [phi:rom_verify::@22->rom_verify::@1#4] -- register_copy 
    // [1306] phi rom_verify::rom_address#12 = rom_verify::rom_address#1 [phi:rom_verify::@22->rom_verify::@1#5] -- register_copy 
    jmp __b1
    // rom_verify::@4
  __b4:
    // cputc('*')
    // [1356] stackpush(char) = '*' -- _stackpushbyte_=vbuc1 
    lda #'*'
    pha
    // [1357] callexecute cputc  -- call_vprc1 
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
    .label rom_chip = main.check_roms2_check_rom1_main__0
    .label file_size = rom_flash.rom_flash__29
    .label progress_row_current = fgets.stream
}
.segment Code
  // printf_ulong
// Print an unsigned int using a specific format
// void printf_ulong(__zp($4d) void (*putc)(char), __zp($30) unsigned long uvalue, __zp($e2) char format_min_length, char format_justify_left, char format_sign_always, __zp($e1) char format_zero_padding, char format_upper_case, __zp($df) char format_radix)
printf_ulong: {
    .label uvalue = $30
    .label format_radix = $df
    .label putc = $4d
    .label format_min_length = $e2
    .label format_zero_padding = $e1
    // printf_ulong::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1360] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // ultoa(uvalue, printf_buffer.digits, format.radix)
    // [1361] ultoa::value#1 = printf_ulong::uvalue#11
    // [1362] ultoa::radix#0 = printf_ulong::format_radix#11
    // [1363] call ultoa
    // Format number into buffer
    jsr ultoa
    // printf_ulong::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1364] printf_number_buffer::putc#0 = printf_ulong::putc#11
    // [1365] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [1366] printf_number_buffer::format_min_length#0 = printf_ulong::format_min_length#11
    // [1367] printf_number_buffer::format_zero_padding#0 = printf_ulong::format_zero_padding#11
    // [1368] call printf_number_buffer
  // Print using format
    // [1835] phi from printf_ulong::@2 to printf_number_buffer [phi:printf_ulong::@2->printf_number_buffer]
    // [1835] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#0 [phi:printf_ulong::@2->printf_number_buffer#0] -- register_copy 
    // [1835] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_ulong::@2->printf_number_buffer#1] -- register_copy 
    // [1835] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#0 [phi:printf_ulong::@2->printf_number_buffer#2] -- register_copy 
    // [1835] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#0 [phi:printf_ulong::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_ulong::@return
    // }
    // [1369] return 
    rts
  .segment Data
    uvalue_1: .dword 0
}
.segment Code
  // rom_flash
// __mem() unsigned long rom_flash(__mem() char rom_chip, __zp($fb) char rom_bank_start, __mem() unsigned long file_size)
rom_flash: {
    .label equal_bytes = $51
    .label ram_address_sector = $cd
    .label equal_bytes_1 = $f8
    .label retries = $f2
    .label flash_errors_sector = $bd
    .label ram_address = $c7
    .label rom_address = $ee
    .label x = $e8
    .label bram_bank_sector = $ea
    .label x_sector = $f7
    .label y_sector = $cc
    .label rom_bank_start = $fb
    // info_progress("Flashing ... (-) equal, (+) flashed, (!) error.")
    // [1371] call info_progress
  // Now we compare the RAM with the actual ROM contents.
    // [666] phi from rom_flash to info_progress [phi:rom_flash->info_progress]
    // [666] phi info_progress::info_text#14 = rom_flash::info_text [phi:rom_flash->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_progress.info_text
    lda #>info_text
    sta.z info_progress.info_text+1
    jsr info_progress
    // rom_flash::@19
    // unsigned long rom_address_sector = rom_address_from_bank(rom_bank_start)
    // [1372] rom_address_from_bank::rom_bank#2 = rom_flash::rom_bank_start#0
    // [1373] call rom_address_from_bank
    // [2135] phi from rom_flash::@19 to rom_address_from_bank [phi:rom_flash::@19->rom_address_from_bank]
    // [2135] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#2 [phi:rom_flash::@19->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address_sector = rom_address_from_bank(rom_bank_start)
    // [1374] rom_address_from_bank::return#4 = rom_address_from_bank::return#0 -- vdum1=vduz2 
    lda.z rom_address_from_bank.return
    sta rom_address_from_bank.return_2
    lda.z rom_address_from_bank.return+1
    sta rom_address_from_bank.return_2+1
    lda.z rom_address_from_bank.return+2
    sta rom_address_from_bank.return_2+2
    lda.z rom_address_from_bank.return+3
    sta rom_address_from_bank.return_2+3
    // rom_flash::@20
    // [1375] rom_flash::rom_address_sector#0 = rom_address_from_bank::return#4
    // unsigned long rom_boundary = rom_address_sector + file_size
    // [1376] rom_flash::rom_boundary#0 = rom_flash::rom_address_sector#0 + rom_flash::file_size#0 -- vdum1=vdum2_plus_vdum3 
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
    // info_rom(rom_chip, STATUS_FLASHING, "Flashing ...")
    // [1377] info_rom::rom_chip#2 = rom_flash::rom_chip#0 -- vbum1=vbum2 
    lda rom_chip
    sta info_rom.rom_chip
    // [1378] call info_rom
    // [1133] phi from rom_flash::@20 to info_rom [phi:rom_flash::@20->info_rom]
    // [1133] phi info_rom::info_text#16 = rom_flash::info_text1 [phi:rom_flash::@20->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z info_rom.info_text
    lda #>info_text1
    sta.z info_rom.info_text+1
    // [1133] phi info_rom::rom_chip#16 = info_rom::rom_chip#2 [phi:rom_flash::@20->info_rom#1] -- register_copy 
    // [1133] phi info_rom::info_status#16 = STATUS_FLASHING [phi:rom_flash::@20->info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHING
    sta info_rom.info_status
    jsr info_rom
    // [1379] phi from rom_flash::@20 to rom_flash::@1 [phi:rom_flash::@20->rom_flash::@1]
    // [1379] phi rom_flash::y_sector#13 = PROGRESS_Y [phi:rom_flash::@20->rom_flash::@1#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y_sector
    // [1379] phi rom_flash::x_sector#10 = PROGRESS_X [phi:rom_flash::@20->rom_flash::@1#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z x_sector
    // [1379] phi rom_flash::flash_errors#10 = 0 [phi:rom_flash::@20->rom_flash::@1#2] -- vdum1=vduc1 
    lda #<0
    sta flash_errors
    sta flash_errors+1
    lda #<0>>$10
    sta flash_errors+2
    lda #>0>>$10
    sta flash_errors+3
    // [1379] phi rom_flash::ram_address_sector#11 = (char *)$6000 [phi:rom_flash::@20->rom_flash::@1#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z ram_address_sector
    lda #>$6000
    sta.z ram_address_sector+1
    // [1379] phi rom_flash::bram_bank_sector#14 = 0 [phi:rom_flash::@20->rom_flash::@1#4] -- vbuz1=vbuc1 
    lda #0
    sta.z bram_bank_sector
    // [1379] phi rom_flash::rom_address_sector#12 = rom_flash::rom_address_sector#0 [phi:rom_flash::@20->rom_flash::@1#5] -- register_copy 
    // rom_flash::@1
  __b1:
    // while (rom_address_sector < rom_boundary)
    // [1380] if(rom_flash::rom_address_sector#12<rom_flash::rom_boundary#0) goto rom_flash::@2 -- vdum1_lt_vdum2_then_la1 
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
    // [1381] phi from rom_flash::@1 to rom_flash::@3 [phi:rom_flash::@1->rom_flash::@3]
    // rom_flash::@3
    // info_line("Flashed ...")
    // [1382] call info_line
    // [931] phi from rom_flash::@3 to info_line [phi:rom_flash::@3->info_line]
    // [931] phi info_line::info_text#17 = rom_flash::info_text2 [phi:rom_flash::@3->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z info_line.info_text
    lda #>info_text2
    sta.z info_line.info_text+1
    jsr info_line
    // rom_flash::@return
    // }
    // [1383] return 
    rts
    // rom_flash::@2
  __b2:
    // unsigned int equal_bytes = rom_compare(bram_bank_sector, (ram_ptr_t)ram_address_sector, rom_address_sector, ROM_SECTOR)
    // [1384] rom_compare::bank_ram#1 = rom_flash::bram_bank_sector#14 -- vbuz1=vbuz2 
    lda.z bram_bank_sector
    sta.z rom_compare.bank_ram
    // [1385] rom_compare::ptr_ram#2 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z rom_compare.ptr_ram
    lda.z ram_address_sector+1
    sta.z rom_compare.ptr_ram+1
    // [1386] rom_compare::rom_compare_address#1 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_compare.rom_compare_address
    lda rom_address_sector+1
    sta.z rom_compare.rom_compare_address+1
    lda rom_address_sector+2
    sta.z rom_compare.rom_compare_address+2
    lda rom_address_sector+3
    sta.z rom_compare.rom_compare_address+3
    // [1387] call rom_compare
  // {asm{.byte $db}}
    // [2139] phi from rom_flash::@2 to rom_compare [phi:rom_flash::@2->rom_compare]
    // [2139] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#2 [phi:rom_flash::@2->rom_compare#0] -- register_copy 
    // [2139] phi rom_compare::rom_compare_size#11 = $1000 [phi:rom_flash::@2->rom_compare#1] -- vwuz1=vwuc1 
    lda #<$1000
    sta.z rom_compare.rom_compare_size
    lda #>$1000
    sta.z rom_compare.rom_compare_size+1
    // [2139] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#1 [phi:rom_flash::@2->rom_compare#2] -- register_copy 
    // [2139] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#1 [phi:rom_flash::@2->rom_compare#3] -- register_copy 
    jsr rom_compare
    // unsigned int equal_bytes = rom_compare(bram_bank_sector, (ram_ptr_t)ram_address_sector, rom_address_sector, ROM_SECTOR)
    // [1388] rom_compare::return#3 = rom_compare::equal_bytes#2
    // rom_flash::@21
    // [1389] rom_flash::equal_bytes#0 = rom_compare::return#3
    // if (equal_bytes != ROM_SECTOR)
    // [1390] if(rom_flash::equal_bytes#0!=$1000) goto rom_flash::@5 -- vwuz1_neq_vwuc1_then_la1 
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
    // [1391] cputsxy::x#1 = rom_flash::x_sector#10 -- vbuz1=vbuz2 
    lda.z x_sector
    sta.z cputsxy.x
    // [1392] cputsxy::y#1 = rom_flash::y_sector#13 -- vbuz1=vbuz2 
    lda.z y_sector
    sta.z cputsxy.y
    // [1393] call cputsxy
    // [644] phi from rom_flash::@16 to cputsxy [phi:rom_flash::@16->cputsxy]
    // [644] phi cputsxy::s#4 = rom_flash::s [phi:rom_flash::@16->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z cputsxy.s
    lda #>s
    sta.z cputsxy.s+1
    // [644] phi cputsxy::y#4 = cputsxy::y#1 [phi:rom_flash::@16->cputsxy#1] -- register_copy 
    // [644] phi cputsxy::x#4 = cputsxy::x#1 [phi:rom_flash::@16->cputsxy#2] -- register_copy 
    jsr cputsxy
    // [1394] phi from rom_flash::@12 rom_flash::@16 to rom_flash::@4 [phi:rom_flash::@12/rom_flash::@16->rom_flash::@4]
    // [1394] phi rom_flash::flash_errors#13 = rom_flash::flash_errors#1 [phi:rom_flash::@12/rom_flash::@16->rom_flash::@4#0] -- register_copy 
    // rom_flash::@4
  __b4:
    // ram_address_sector += ROM_SECTOR
    // [1395] rom_flash::ram_address_sector#1 = rom_flash::ram_address_sector#11 + $1000 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address_sector
    clc
    adc #<$1000
    sta.z ram_address_sector
    lda.z ram_address_sector+1
    adc #>$1000
    sta.z ram_address_sector+1
    // rom_address_sector += ROM_SECTOR
    // [1396] rom_flash::rom_address_sector#1 = rom_flash::rom_address_sector#12 + $1000 -- vdum1=vdum1_plus_vwuc1 
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
    // [1397] if(rom_flash::ram_address_sector#1!=$c000) goto rom_flash::@13 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address_sector+1
    cmp #>$c000
    bne __b13
    lda.z ram_address_sector
    cmp #<$c000
    bne __b13
    // rom_flash::@17
    // bram_bank_sector++;
    // [1398] rom_flash::bram_bank_sector#1 = ++ rom_flash::bram_bank_sector#14 -- vbuz1=_inc_vbuz1 
    inc.z bram_bank_sector
    // [1399] phi from rom_flash::@17 to rom_flash::@13 [phi:rom_flash::@17->rom_flash::@13]
    // [1399] phi rom_flash::bram_bank_sector#38 = rom_flash::bram_bank_sector#1 [phi:rom_flash::@17->rom_flash::@13#0] -- register_copy 
    // [1399] phi rom_flash::ram_address_sector#8 = (char *)$a000 [phi:rom_flash::@17->rom_flash::@13#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address_sector
    lda #>$a000
    sta.z ram_address_sector+1
    // [1399] phi from rom_flash::@4 to rom_flash::@13 [phi:rom_flash::@4->rom_flash::@13]
    // [1399] phi rom_flash::bram_bank_sector#38 = rom_flash::bram_bank_sector#14 [phi:rom_flash::@4->rom_flash::@13#0] -- register_copy 
    // [1399] phi rom_flash::ram_address_sector#8 = rom_flash::ram_address_sector#1 [phi:rom_flash::@4->rom_flash::@13#1] -- register_copy 
    // rom_flash::@13
  __b13:
    // if (ram_address_sector == RAM_HIGH)
    // [1400] if(rom_flash::ram_address_sector#8!=$8000) goto rom_flash::@44 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address_sector+1
    cmp #>$8000
    bne __b14
    lda.z ram_address_sector
    cmp #<$8000
    bne __b14
    // [1402] phi from rom_flash::@13 to rom_flash::@14 [phi:rom_flash::@13->rom_flash::@14]
    // [1402] phi rom_flash::ram_address_sector#15 = (char *)$a000 [phi:rom_flash::@13->rom_flash::@14#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address_sector
    lda #>$a000
    sta.z ram_address_sector+1
    // [1402] phi rom_flash::bram_bank_sector#12 = 1 [phi:rom_flash::@13->rom_flash::@14#1] -- vbuz1=vbuc1 
    lda #1
    sta.z bram_bank_sector
    // [1401] phi from rom_flash::@13 to rom_flash::@44 [phi:rom_flash::@13->rom_flash::@44]
    // rom_flash::@44
    // [1402] phi from rom_flash::@44 to rom_flash::@14 [phi:rom_flash::@44->rom_flash::@14]
    // [1402] phi rom_flash::ram_address_sector#15 = rom_flash::ram_address_sector#8 [phi:rom_flash::@44->rom_flash::@14#0] -- register_copy 
    // [1402] phi rom_flash::bram_bank_sector#12 = rom_flash::bram_bank_sector#38 [phi:rom_flash::@44->rom_flash::@14#1] -- register_copy 
    // rom_flash::@14
  __b14:
    // x_sector += 8
    // [1403] rom_flash::x_sector#1 = rom_flash::x_sector#10 + 8 -- vbuz1=vbuz1_plus_vbuc1 
    lda #8
    clc
    adc.z x_sector
    sta.z x_sector
    // rom_address_sector % PROGRESS_ROW
    // [1404] rom_flash::$29 = rom_flash::rom_address_sector#1 & PROGRESS_ROW-1 -- vdum1=vdum2_band_vduc1 
    lda rom_address_sector
    and #<PROGRESS_ROW-1
    sta rom_flash__29
    lda rom_address_sector+1
    and #>PROGRESS_ROW-1
    sta rom_flash__29+1
    lda rom_address_sector+2
    and #<PROGRESS_ROW-1>>$10
    sta rom_flash__29+2
    lda rom_address_sector+3
    and #>PROGRESS_ROW-1>>$10
    sta rom_flash__29+3
    // if (!(rom_address_sector % PROGRESS_ROW))
    // [1405] if(0!=rom_flash::$29) goto rom_flash::@15 -- 0_neq_vdum1_then_la1 
    lda rom_flash__29
    ora rom_flash__29+1
    ora rom_flash__29+2
    ora rom_flash__29+3
    bne __b15
    // rom_flash::@18
    // y_sector++;
    // [1406] rom_flash::y_sector#1 = ++ rom_flash::y_sector#13 -- vbuz1=_inc_vbuz1 
    inc.z y_sector
    // [1407] phi from rom_flash::@18 to rom_flash::@15 [phi:rom_flash::@18->rom_flash::@15]
    // [1407] phi rom_flash::y_sector#18 = rom_flash::y_sector#1 [phi:rom_flash::@18->rom_flash::@15#0] -- register_copy 
    // [1407] phi rom_flash::x_sector#20 = PROGRESS_X [phi:rom_flash::@18->rom_flash::@15#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z x_sector
    // [1407] phi from rom_flash::@14 to rom_flash::@15 [phi:rom_flash::@14->rom_flash::@15]
    // [1407] phi rom_flash::y_sector#18 = rom_flash::y_sector#13 [phi:rom_flash::@14->rom_flash::@15#0] -- register_copy 
    // [1407] phi rom_flash::x_sector#20 = rom_flash::x_sector#1 [phi:rom_flash::@14->rom_flash::@15#1] -- register_copy 
    // rom_flash::@15
  __b15:
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1408] call snprintf_init
    jsr snprintf_init
    // rom_flash::@40
    // [1409] printf_ulong::uvalue#8 = rom_flash::flash_errors#13 -- vduz1=vdum2 
    lda flash_errors
    sta.z printf_ulong.uvalue
    lda flash_errors+1
    sta.z printf_ulong.uvalue+1
    lda flash_errors+2
    sta.z printf_ulong.uvalue+2
    lda flash_errors+3
    sta.z printf_ulong.uvalue+3
    // [1410] call printf_ulong
    // [1359] phi from rom_flash::@40 to printf_ulong [phi:rom_flash::@40->printf_ulong]
    // [1359] phi printf_ulong::format_zero_padding#11 = 0 [phi:rom_flash::@40->printf_ulong#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_ulong.format_zero_padding
    // [1359] phi printf_ulong::format_min_length#11 = 0 [phi:rom_flash::@40->printf_ulong#1] -- vbuz1=vbuc1 
    sta.z printf_ulong.format_min_length
    // [1359] phi printf_ulong::putc#11 = &snputc [phi:rom_flash::@40->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1359] phi printf_ulong::format_radix#11 = DECIMAL [phi:rom_flash::@40->printf_ulong#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_ulong.format_radix
    // [1359] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#8 [phi:rom_flash::@40->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1411] phi from rom_flash::@40 to rom_flash::@41 [phi:rom_flash::@40->rom_flash::@41]
    // rom_flash::@41
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1412] call printf_str
    // [700] phi from rom_flash::@41 to printf_str [phi:rom_flash::@41->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:rom_flash::@41->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = rom_flash::s6 [phi:rom_flash::@41->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@42
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1413] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1414] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom(rom_chip, STATUS_FLASHING, info_text)
    // [1416] info_rom::rom_chip#3 = rom_flash::rom_chip#0 -- vbum1=vbum2 
    lda rom_chip
    sta info_rom.rom_chip
    // [1417] call info_rom
    // [1133] phi from rom_flash::@42 to info_rom [phi:rom_flash::@42->info_rom]
    // [1133] phi info_rom::info_text#16 = info_text [phi:rom_flash::@42->info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_rom.info_text
    lda #>@info_text
    sta.z info_rom.info_text+1
    // [1133] phi info_rom::rom_chip#16 = info_rom::rom_chip#3 [phi:rom_flash::@42->info_rom#1] -- register_copy 
    // [1133] phi info_rom::info_status#16 = STATUS_FLASHING [phi:rom_flash::@42->info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHING
    sta info_rom.info_status
    jsr info_rom
    // [1379] phi from rom_flash::@42 to rom_flash::@1 [phi:rom_flash::@42->rom_flash::@1]
    // [1379] phi rom_flash::y_sector#13 = rom_flash::y_sector#18 [phi:rom_flash::@42->rom_flash::@1#0] -- register_copy 
    // [1379] phi rom_flash::x_sector#10 = rom_flash::x_sector#20 [phi:rom_flash::@42->rom_flash::@1#1] -- register_copy 
    // [1379] phi rom_flash::flash_errors#10 = rom_flash::flash_errors#13 [phi:rom_flash::@42->rom_flash::@1#2] -- register_copy 
    // [1379] phi rom_flash::ram_address_sector#11 = rom_flash::ram_address_sector#15 [phi:rom_flash::@42->rom_flash::@1#3] -- register_copy 
    // [1379] phi rom_flash::bram_bank_sector#14 = rom_flash::bram_bank_sector#12 [phi:rom_flash::@42->rom_flash::@1#4] -- register_copy 
    // [1379] phi rom_flash::rom_address_sector#12 = rom_flash::rom_address_sector#1 [phi:rom_flash::@42->rom_flash::@1#5] -- register_copy 
    jmp __b1
    // [1418] phi from rom_flash::@21 to rom_flash::@5 [phi:rom_flash::@21->rom_flash::@5]
  __b3:
    // [1418] phi rom_flash::retries#12 = 0 [phi:rom_flash::@21->rom_flash::@5#0] -- vbuz1=vbuc1 
    lda #0
    sta.z retries
    // [1418] phi rom_flash::flash_errors_sector#11 = 0 [phi:rom_flash::@21->rom_flash::@5#1] -- vwuz1=vwuc1 
    sta.z flash_errors_sector
    sta.z flash_errors_sector+1
    // [1418] phi from rom_flash::@43 to rom_flash::@5 [phi:rom_flash::@43->rom_flash::@5]
    // [1418] phi rom_flash::retries#12 = rom_flash::retries#1 [phi:rom_flash::@43->rom_flash::@5#0] -- register_copy 
    // [1418] phi rom_flash::flash_errors_sector#11 = rom_flash::flash_errors_sector#10 [phi:rom_flash::@43->rom_flash::@5#1] -- register_copy 
    // rom_flash::@5
  __b5:
    // rom_sector_erase(rom_address_sector)
    // [1419] rom_sector_erase::address#0 = rom_flash::rom_address_sector#12 -- vdum1=vdum2 
    lda rom_address_sector
    sta rom_sector_erase.address
    lda rom_address_sector+1
    sta rom_sector_erase.address+1
    lda rom_address_sector+2
    sta rom_sector_erase.address+2
    lda rom_address_sector+3
    sta rom_sector_erase.address+3
    // [1420] call rom_sector_erase
    // [2195] phi from rom_flash::@5 to rom_sector_erase [phi:rom_flash::@5->rom_sector_erase]
    jsr rom_sector_erase
    // rom_flash::@22
    // unsigned long rom_sector_boundary = rom_address_sector + ROM_SECTOR
    // [1421] rom_flash::rom_sector_boundary#0 = rom_flash::rom_address_sector#12 + $1000 -- vdum1=vdum2_plus_vwuc1 
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
    // [1422] gotoxy::x#28 = rom_flash::x_sector#10 -- vbuz1=vbuz2 
    lda.z x_sector
    sta.z gotoxy.x
    // [1423] gotoxy::y#28 = rom_flash::y_sector#13 -- vbuz1=vbuz2 
    lda.z y_sector
    sta.z gotoxy.y
    // [1424] call gotoxy
    // [557] phi from rom_flash::@22 to gotoxy [phi:rom_flash::@22->gotoxy]
    // [557] phi gotoxy::y#30 = gotoxy::y#28 [phi:rom_flash::@22->gotoxy#0] -- register_copy 
    // [557] phi gotoxy::x#30 = gotoxy::x#28 [phi:rom_flash::@22->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1425] phi from rom_flash::@22 to rom_flash::@23 [phi:rom_flash::@22->rom_flash::@23]
    // rom_flash::@23
    // printf("........")
    // [1426] call printf_str
    // [700] phi from rom_flash::@23 to printf_str [phi:rom_flash::@23->printf_str]
    // [700] phi printf_str::putc#68 = &cputc [phi:rom_flash::@23->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = rom_flash::s1 [phi:rom_flash::@23->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@24
    // [1427] rom_flash::rom_address#26 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_address
    lda rom_address_sector+1
    sta.z rom_address+1
    lda rom_address_sector+2
    sta.z rom_address+2
    lda rom_address_sector+3
    sta.z rom_address+3
    // [1428] rom_flash::ram_address#26 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z ram_address
    lda.z ram_address_sector+1
    sta.z ram_address+1
    // [1429] rom_flash::x#26 = rom_flash::x_sector#10 -- vbuz1=vbuz2 
    lda.z x_sector
    sta.z x
    // [1430] phi from rom_flash::@10 rom_flash::@24 to rom_flash::@6 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6]
    // [1430] phi rom_flash::x#10 = rom_flash::x#1 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#0] -- register_copy 
    // [1430] phi rom_flash::ram_address#10 = rom_flash::ram_address#1 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#1] -- register_copy 
    // [1430] phi rom_flash::flash_errors_sector#10 = rom_flash::flash_errors_sector#8 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#2] -- register_copy 
    // [1430] phi rom_flash::rom_address#11 = rom_flash::rom_address#1 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#3] -- register_copy 
    // rom_flash::@6
  __b6:
    // while (rom_address < rom_sector_boundary)
    // [1431] if(rom_flash::rom_address#11<rom_flash::rom_sector_boundary#0) goto rom_flash::@7 -- vduz1_lt_vdum2_then_la1 
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
    // [1432] rom_flash::retries#1 = ++ rom_flash::retries#12 -- vbuz1=_inc_vbuz1 
    inc.z retries
    // while (flash_errors_sector && retries <= 3)
    // [1433] if(0==rom_flash::flash_errors_sector#10) goto rom_flash::@12 -- 0_eq_vwuz1_then_la1 
    lda.z flash_errors_sector
    ora.z flash_errors_sector+1
    beq __b12
    // rom_flash::@43
    // [1434] if(rom_flash::retries#1<3+1) goto rom_flash::@5 -- vbuz1_lt_vbuc1_then_la1 
    lda.z retries
    cmp #3+1
    bcs !__b5+
    jmp __b5
  !__b5:
    // rom_flash::@12
  __b12:
    // flash_errors += flash_errors_sector
    // [1435] rom_flash::flash_errors#1 = rom_flash::flash_errors#10 + rom_flash::flash_errors_sector#10 -- vdum1=vdum1_plus_vwuz2 
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
    // [1436] printf_ulong::uvalue#7 = rom_flash::flash_errors_sector#10 + rom_flash::flash_errors#10 -- vdum1=vwuz2_plus_vdum3 
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
    // [1437] call snprintf_init
    jsr snprintf_init
    // [1438] phi from rom_flash::@7 to rom_flash::@25 [phi:rom_flash::@7->rom_flash::@25]
    // rom_flash::@25
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1439] call printf_str
    // [700] phi from rom_flash::@25 to printf_str [phi:rom_flash::@25->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:rom_flash::@25->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = rom_flash::s2 [phi:rom_flash::@25->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@26
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1440] printf_uchar::uvalue#7 = rom_flash::bram_bank_sector#14 -- vbuz1=vbuz2 
    lda.z bram_bank_sector
    sta.z printf_uchar.uvalue
    // [1441] call printf_uchar
    // [1122] phi from rom_flash::@26 to printf_uchar [phi:rom_flash::@26->printf_uchar]
    // [1122] phi printf_uchar::format_zero_padding#10 = 1 [phi:rom_flash::@26->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1122] phi printf_uchar::format_min_length#10 = 2 [phi:rom_flash::@26->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [1122] phi printf_uchar::putc#10 = &snputc [phi:rom_flash::@26->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1122] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:rom_flash::@26->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [1122] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#7 [phi:rom_flash::@26->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1442] phi from rom_flash::@26 to rom_flash::@27 [phi:rom_flash::@26->rom_flash::@27]
    // rom_flash::@27
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1443] call printf_str
    // [700] phi from rom_flash::@27 to printf_str [phi:rom_flash::@27->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:rom_flash::@27->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = s3 [phi:rom_flash::@27->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@28
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1444] printf_uint::uvalue#12 = (unsigned int)rom_flash::ram_address_sector#11 -- vwuz1=vwuz2 
    lda.z ram_address_sector
    sta.z printf_uint.uvalue
    lda.z ram_address_sector+1
    sta.z printf_uint.uvalue+1
    // [1445] call printf_uint
    // [709] phi from rom_flash::@28 to printf_uint [phi:rom_flash::@28->printf_uint]
    // [709] phi printf_uint::format_zero_padding#16 = 1 [phi:rom_flash::@28->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [709] phi printf_uint::format_min_length#16 = 4 [phi:rom_flash::@28->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [709] phi printf_uint::putc#16 = &snputc [phi:rom_flash::@28->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [709] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:rom_flash::@28->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [709] phi printf_uint::uvalue#16 = printf_uint::uvalue#12 [phi:rom_flash::@28->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1446] phi from rom_flash::@28 to rom_flash::@29 [phi:rom_flash::@28->rom_flash::@29]
    // rom_flash::@29
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1447] call printf_str
    // [700] phi from rom_flash::@29 to printf_str [phi:rom_flash::@29->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:rom_flash::@29->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = rom_flash::s4 [phi:rom_flash::@29->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@30
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1448] printf_ulong::uvalue#6 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z printf_ulong.uvalue
    lda rom_address_sector+1
    sta.z printf_ulong.uvalue+1
    lda rom_address_sector+2
    sta.z printf_ulong.uvalue+2
    lda rom_address_sector+3
    sta.z printf_ulong.uvalue+3
    // [1449] call printf_ulong
    // [1359] phi from rom_flash::@30 to printf_ulong [phi:rom_flash::@30->printf_ulong]
    // [1359] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_flash::@30->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1359] phi printf_ulong::format_min_length#11 = 5 [phi:rom_flash::@30->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1359] phi printf_ulong::putc#11 = &snputc [phi:rom_flash::@30->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1359] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_flash::@30->printf_ulong#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1359] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#6 [phi:rom_flash::@30->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1450] phi from rom_flash::@30 to rom_flash::@31 [phi:rom_flash::@30->rom_flash::@31]
    // rom_flash::@31
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1451] call printf_str
    // [700] phi from rom_flash::@31 to printf_str [phi:rom_flash::@31->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:rom_flash::@31->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = rom_flash::s5 [phi:rom_flash::@31->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@32
    // [1452] printf_ulong::uvalue#20 = printf_ulong::uvalue#7 -- vduz1=vdum2 
    lda printf_ulong.uvalue_1
    sta.z printf_ulong.uvalue
    lda printf_ulong.uvalue_1+1
    sta.z printf_ulong.uvalue+1
    lda printf_ulong.uvalue_1+2
    sta.z printf_ulong.uvalue+2
    lda printf_ulong.uvalue_1+3
    sta.z printf_ulong.uvalue+3
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1453] call printf_ulong
    // [1359] phi from rom_flash::@32 to printf_ulong [phi:rom_flash::@32->printf_ulong]
    // [1359] phi printf_ulong::format_zero_padding#11 = 0 [phi:rom_flash::@32->printf_ulong#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_ulong.format_zero_padding
    // [1359] phi printf_ulong::format_min_length#11 = 0 [phi:rom_flash::@32->printf_ulong#1] -- vbuz1=vbuc1 
    sta.z printf_ulong.format_min_length
    // [1359] phi printf_ulong::putc#11 = &snputc [phi:rom_flash::@32->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1359] phi printf_ulong::format_radix#11 = DECIMAL [phi:rom_flash::@32->printf_ulong#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_ulong.format_radix
    // [1359] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#20 [phi:rom_flash::@32->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1454] phi from rom_flash::@32 to rom_flash::@33 [phi:rom_flash::@32->rom_flash::@33]
    // rom_flash::@33
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1455] call printf_str
    // [700] phi from rom_flash::@33 to printf_str [phi:rom_flash::@33->printf_str]
    // [700] phi printf_str::putc#68 = &snputc [phi:rom_flash::@33->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [700] phi printf_str::s#68 = rom_flash::s6 [phi:rom_flash::@33->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@34
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1456] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1457] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [1459] call info_line
    // [931] phi from rom_flash::@34 to info_line [phi:rom_flash::@34->info_line]
    // [931] phi info_line::info_text#17 = info_text [phi:rom_flash::@34->info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_line.info_text
    lda #>@info_text
    sta.z info_line.info_text+1
    jsr info_line
    // rom_flash::@35
    // unsigned long written_bytes = rom_write(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1460] rom_write::flash_ram_bank#0 = rom_flash::bram_bank_sector#14 -- vbuz1=vbuz2 
    lda.z bram_bank_sector
    sta.z rom_write.flash_ram_bank
    // [1461] rom_write::flash_ram_address#1 = rom_flash::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_write.flash_ram_address
    lda.z ram_address+1
    sta.z rom_write.flash_ram_address+1
    // [1462] rom_write::flash_rom_address#1 = rom_flash::rom_address#11 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_write.flash_rom_address
    lda.z rom_address+1
    sta.z rom_write.flash_rom_address+1
    lda.z rom_address+2
    sta.z rom_write.flash_rom_address+2
    lda.z rom_address+3
    sta.z rom_write.flash_rom_address+3
    // [1463] call rom_write
    jsr rom_write
    // rom_flash::@36
    // rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1464] rom_compare::bank_ram#2 = rom_flash::bram_bank_sector#14 -- vbuz1=vbuz2 
    lda.z bram_bank_sector
    sta.z rom_compare.bank_ram
    // [1465] rom_compare::ptr_ram#3 = rom_flash::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_compare.ptr_ram
    lda.z ram_address+1
    sta.z rom_compare.ptr_ram+1
    // [1466] rom_compare::rom_compare_address#2 = rom_flash::rom_address#11 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_compare.rom_compare_address
    lda.z rom_address+1
    sta.z rom_compare.rom_compare_address+1
    lda.z rom_address+2
    sta.z rom_compare.rom_compare_address+2
    lda.z rom_address+3
    sta.z rom_compare.rom_compare_address+3
    // [1467] call rom_compare
    // [2139] phi from rom_flash::@36 to rom_compare [phi:rom_flash::@36->rom_compare]
    // [2139] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#3 [phi:rom_flash::@36->rom_compare#0] -- register_copy 
    // [2139] phi rom_compare::rom_compare_size#11 = PROGRESS_CELL [phi:rom_flash::@36->rom_compare#1] -- vwuz1=vwuc1 
    lda #<PROGRESS_CELL
    sta.z rom_compare.rom_compare_size
    lda #>PROGRESS_CELL
    sta.z rom_compare.rom_compare_size+1
    // [2139] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#2 [phi:rom_flash::@36->rom_compare#2] -- register_copy 
    // [2139] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#2 [phi:rom_flash::@36->rom_compare#3] -- register_copy 
    jsr rom_compare
    // rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1468] rom_compare::return#4 = rom_compare::equal_bytes#2
    // rom_flash::@37
    // equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1469] rom_flash::equal_bytes#1 = rom_compare::return#4 -- vwuz1=vwuz2 
    lda.z rom_compare.return
    sta.z equal_bytes_1
    lda.z rom_compare.return+1
    sta.z equal_bytes_1+1
    // gotoxy(x, y)
    // [1470] gotoxy::x#29 = rom_flash::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1471] gotoxy::y#29 = rom_flash::y_sector#13 -- vbuz1=vbuz2 
    lda.z y_sector
    sta.z gotoxy.y
    // [1472] call gotoxy
    // [557] phi from rom_flash::@37 to gotoxy [phi:rom_flash::@37->gotoxy]
    // [557] phi gotoxy::y#30 = gotoxy::y#29 [phi:rom_flash::@37->gotoxy#0] -- register_copy 
    // [557] phi gotoxy::x#30 = gotoxy::x#29 [phi:rom_flash::@37->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_flash::@38
    // if (equal_bytes != PROGRESS_CELL)
    // [1473] if(rom_flash::equal_bytes#1!=PROGRESS_CELL) goto rom_flash::@9 -- vwuz1_neq_vwuc1_then_la1 
    lda.z equal_bytes_1+1
    cmp #>PROGRESS_CELL
    bne __b9
    lda.z equal_bytes_1
    cmp #<PROGRESS_CELL
    bne __b9
    // rom_flash::@11
    // cputcxy(x,y,'+')
    // [1474] cputcxy::x#14 = rom_flash::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1475] cputcxy::y#14 = rom_flash::y_sector#13 -- vbuz1=vbuz2 
    lda.z y_sector
    sta.z cputcxy.y
    // [1476] call cputcxy
    // [1738] phi from rom_flash::@11 to cputcxy [phi:rom_flash::@11->cputcxy]
    // [1738] phi cputcxy::c#15 = '+' [phi:rom_flash::@11->cputcxy#0] -- vbuz1=vbuc1 
    lda #'+'
    sta.z cputcxy.c
    // [1738] phi cputcxy::y#15 = cputcxy::y#14 [phi:rom_flash::@11->cputcxy#1] -- register_copy 
    // [1738] phi cputcxy::x#15 = cputcxy::x#14 [phi:rom_flash::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [1477] phi from rom_flash::@11 rom_flash::@39 to rom_flash::@10 [phi:rom_flash::@11/rom_flash::@39->rom_flash::@10]
    // [1477] phi rom_flash::flash_errors_sector#8 = rom_flash::flash_errors_sector#10 [phi:rom_flash::@11/rom_flash::@39->rom_flash::@10#0] -- register_copy 
    // rom_flash::@10
  __b10:
    // ram_address += PROGRESS_CELL
    // [1478] rom_flash::ram_address#1 = rom_flash::ram_address#10 + PROGRESS_CELL -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address
    clc
    adc #<PROGRESS_CELL
    sta.z ram_address
    lda.z ram_address+1
    adc #>PROGRESS_CELL
    sta.z ram_address+1
    // rom_address += PROGRESS_CELL
    // [1479] rom_flash::rom_address#1 = rom_flash::rom_address#11 + PROGRESS_CELL -- vduz1=vduz1_plus_vwuc1 
    clc
    lda.z rom_address
    adc #<PROGRESS_CELL
    sta.z rom_address
    lda.z rom_address+1
    adc #>PROGRESS_CELL
    sta.z rom_address+1
    lda.z rom_address+2
    adc #0
    sta.z rom_address+2
    lda.z rom_address+3
    adc #0
    sta.z rom_address+3
    // x++;
    // [1480] rom_flash::x#1 = ++ rom_flash::x#10 -- vbuz1=_inc_vbuz1 
    inc.z x
    jmp __b6
    // rom_flash::@9
  __b9:
    // cputcxy(x,y,'!')
    // [1481] cputcxy::x#13 = rom_flash::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1482] cputcxy::y#13 = rom_flash::y_sector#13 -- vbuz1=vbuz2 
    lda.z y_sector
    sta.z cputcxy.y
    // [1483] call cputcxy
    // [1738] phi from rom_flash::@9 to cputcxy [phi:rom_flash::@9->cputcxy]
    // [1738] phi cputcxy::c#15 = '!' [phi:rom_flash::@9->cputcxy#0] -- vbuz1=vbuc1 
    lda #'!'
    sta.z cputcxy.c
    // [1738] phi cputcxy::y#15 = cputcxy::y#13 [phi:rom_flash::@9->cputcxy#1] -- register_copy 
    // [1738] phi cputcxy::x#15 = cputcxy::x#13 [phi:rom_flash::@9->cputcxy#2] -- register_copy 
    jsr cputcxy
    // rom_flash::@39
    // flash_errors_sector++;
    // [1484] rom_flash::flash_errors_sector#1 = ++ rom_flash::flash_errors_sector#10 -- vwuz1=_inc_vwuz1 
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
    .label flash_errors = main.rom_file_modulo
    .label rom_chip = main.check_card_roms1_check_rom1_main__0
    .label file_size = main.rom_flash_errors
    .label return = main.rom_file_modulo
}
.segment Code
  // strchr
// Searches for the first occurrence of the character c (an unsigned char) in the string pointed to, by the argument str.
// - str: The memory to search
// - c: A character to search for
// Return: A pointer to the matching byte or NULL if the character does not occur in the given memory area.
// __mem() void * strchr(__mem() const void *str, __mem() char c)
strchr: {
    // [1486] strchr::ptr#6 = (char *)strchr::str#2
    // [1487] phi from strchr strchr::@3 to strchr::@1 [phi:strchr/strchr::@3->strchr::@1]
    // [1487] phi strchr::ptr#2 = strchr::ptr#6 [phi:strchr/strchr::@3->strchr::@1#0] -- register_copy 
    // strchr::@1
  __b1:
    // while(*ptr)
    // [1488] if(0!=*strchr::ptr#2) goto strchr::@2 -- 0_neq__deref_pbum1_then_la1 
    ldy ptr
    sty.z $fe
    ldy ptr+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    cmp #0
    bne __b2
    // [1489] phi from strchr::@1 to strchr::@return [phi:strchr::@1->strchr::@return]
    // [1489] phi strchr::return#2 = (void *) 0 [phi:strchr::@1->strchr::@return#0] -- pvom1=pvoc1 
    tya
    sta return
    sta return+1
    // strchr::@return
    // }
    // [1490] return 
    rts
    // strchr::@2
  __b2:
    // if(*ptr==c)
    // [1491] if(*strchr::ptr#2!=strchr::c#4) goto strchr::@3 -- _deref_pbum1_neq_vbum2_then_la1 
    ldy ptr
    sty.z $fe
    ldy ptr+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    cmp c
    bne __b3
    // strchr::@4
    // [1492] strchr::return#8 = (void *)strchr::ptr#2
    // [1489] phi from strchr::@4 to strchr::@return [phi:strchr::@4->strchr::@return]
    // [1489] phi strchr::return#2 = strchr::return#8 [phi:strchr::@4->strchr::@return#0] -- register_copy 
    rts
    // strchr::@3
  __b3:
    // ptr++;
    // [1493] strchr::ptr#1 = ++ strchr::ptr#2 -- pbum1=_inc_pbum1 
    inc ptr
    bne !+
    inc ptr+1
  !:
    jmp __b1
  .segment Data
    .label ptr = str
    .label return = str
    str: .word 0
    c: .byte 0
}
.segment Code
  // info_cx16_rom
// void info_cx16_rom(char info_status, char *info_text)
info_cx16_rom: {
    .label info_text = 0
    // info_rom(0, info_status, info_text)
    // [1495] call info_rom
    // [1133] phi from info_cx16_rom to info_rom [phi:info_cx16_rom->info_rom]
    // [1133] phi info_rom::info_text#16 = info_cx16_rom::info_text#0 [phi:info_cx16_rom->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_rom.info_text
    lda #>info_text
    sta.z info_rom.info_text+1
    // [1133] phi info_rom::rom_chip#16 = 0 [phi:info_cx16_rom->info_rom#1] -- vbum1=vbuc1 
    lda #0
    sta info_rom.rom_chip
    // [1133] phi info_rom::info_status#16 = STATUS_ISSUE [phi:info_cx16_rom->info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta info_rom.info_status
    jsr info_rom
    // info_cx16_rom::@return
    // }
    // [1496] return 
    rts
}
  // strncpy
/// Copies up to n characters from the string pointed to, by src to dst.
/// In a case where the length of src is less than that of n, the remainder of dst will be padded with null bytes.
/// @param dst ? This is the pointer to the destination array where the content is to be copied.
/// @param src ? This is the string to be copied.
/// @param n ? The number of characters to be copied from source.
/// @return The destination
// char * strncpy(__zp($d5) char *dst, __zp($cf) const char *src, __zp($4f) unsigned int n)
strncpy: {
    .label c = $d9
    .label dst = $d5
    .label i = $5e
    .label src = $cf
    .label n = $4f
    // [1498] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [1498] phi strncpy::dst#3 = strncpy::dst#8 [phi:strncpy->strncpy::@1#0] -- register_copy 
    // [1498] phi strncpy::src#3 = strncpy::src#6 [phi:strncpy->strncpy::@1#1] -- register_copy 
    // [1498] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwuz1=vwuc1 
    lda #<0
    sta.z i
    sta.z i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [1499] if(strncpy::i#2<strncpy::n#3) goto strncpy::@2 -- vwuz1_lt_vwuz2_then_la1 
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
    // [1500] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [1501] strncpy::c#0 = *strncpy::src#3 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta.z c
    // if(c)
    // [1502] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbuz1_then_la1 
    beq __b3
    // strncpy::@4
    // src++;
    // [1503] strncpy::src#0 = ++ strncpy::src#3 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [1504] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [1504] phi strncpy::src#7 = strncpy::src#3 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [1505] *strncpy::dst#3 = strncpy::c#0 -- _deref_pbuz1=vbuz2 
    lda.z c
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [1506] strncpy::dst#0 = ++ strncpy::dst#3 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [1507] strncpy::i#1 = ++ strncpy::i#2 -- vwuz1=_inc_vwuz1 
    inc.z i
    bne !+
    inc.z i+1
  !:
    // [1498] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [1498] phi strncpy::dst#3 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [1498] phi strncpy::src#3 = strncpy::src#7 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [1498] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
    jmp __b1
}
  // print_info_led
// void print_info_led(__zp($bf) char x, __zp($36) char y, __zp($2f) char tc, char bc)
print_info_led: {
    .label tc = $2f
    .label y = $36
    .label x = $bf
    // textcolor(tc)
    // [1509] textcolor::color#13 = print_info_led::tc#4 -- vbuz1=vbuz2 
    lda.z tc
    sta.z textcolor.color
    // [1510] call textcolor
    // [539] phi from print_info_led to textcolor [phi:print_info_led->textcolor]
    // [539] phi textcolor::color#18 = textcolor::color#13 [phi:print_info_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [1511] phi from print_info_led to print_info_led::@1 [phi:print_info_led->print_info_led::@1]
    // print_info_led::@1
    // bgcolor(bc)
    // [1512] call bgcolor
    // [544] phi from print_info_led::@1 to bgcolor [phi:print_info_led::@1->bgcolor]
    // [544] phi bgcolor::color#14 = BLUE [phi:print_info_led::@1->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_info_led::@2
    // cputcxy(x, y, VERA_CHR_UR)
    // [1513] cputcxy::x#11 = print_info_led::x#4
    // [1514] cputcxy::y#11 = print_info_led::y#4
    // [1515] call cputcxy
    // [1738] phi from print_info_led::@2 to cputcxy [phi:print_info_led::@2->cputcxy]
    // [1738] phi cputcxy::c#15 = $7c [phi:print_info_led::@2->cputcxy#0] -- vbuz1=vbuc1 
    lda #$7c
    sta.z cputcxy.c
    // [1738] phi cputcxy::y#15 = cputcxy::y#11 [phi:print_info_led::@2->cputcxy#1] -- register_copy 
    // [1738] phi cputcxy::x#15 = cputcxy::x#11 [phi:print_info_led::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [1516] phi from print_info_led::@2 to print_info_led::@3 [phi:print_info_led::@2->print_info_led::@3]
    // print_info_led::@3
    // textcolor(WHITE)
    // [1517] call textcolor
    // [539] phi from print_info_led::@3 to textcolor [phi:print_info_led::@3->textcolor]
    // [539] phi textcolor::color#18 = WHITE [phi:print_info_led::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // print_info_led::@return
    // }
    // [1518] return 
    rts
}
  // progress_text
// void progress_text(__zp($37) char line, __zp($2d) char *text)
progress_text: {
    .label line = $37
    .label text = $2d
    // cputsxy(PROGRESS_X, PROGRESS_Y+line, text)
    // [1520] cputsxy::y#0 = PROGRESS_Y + progress_text::line#2 -- vbuz1=vbuc1_plus_vbuz1 
    lda #PROGRESS_Y
    clc
    adc.z cputsxy.y
    sta.z cputsxy.y
    // [1521] cputsxy::s#0 = progress_text::text#2
    // [1522] call cputsxy
    // [644] phi from progress_text to cputsxy [phi:progress_text->cputsxy]
    // [644] phi cputsxy::s#4 = cputsxy::s#0 [phi:progress_text->cputsxy#0] -- register_copy 
    // [644] phi cputsxy::y#4 = cputsxy::y#0 [phi:progress_text->cputsxy#1] -- register_copy 
    // [644] phi cputsxy::x#4 = PROGRESS_X [phi:progress_text->cputsxy#2] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z cputsxy.x
    jsr cputsxy
    // progress_text::@return
    // }
    // [1523] return 
    rts
}
  // screenlayer
// --- layer management in VERA ---
// void screenlayer(char layer, __zp($dd) char mapbase, __zp($db) char config)
screenlayer: {
    .label screenlayer__1 = $dd
    .label screenlayer__5 = $db
    .label screenlayer__6 = $db
    .label mapbase = $dd
    .label config = $db
    .label y = $da
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [1524] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [1525] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [1526] *((char *)&__conio+2) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+2
    // mapbase >> 7
    // [1527] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbum1=vbuz2_ror_7 
    lda.z mapbase
    rol
    rol
    and #1
    sta screenlayer__0
    // __conio.mapbase_bank = mapbase >> 7
    // [1528] *((char *)&__conio+5) = screenlayer::$0 -- _deref_pbuc1=vbum1 
    sta __conio+5
    // (mapbase)<<1
    // [1529] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z screenlayer__1
    // MAKEWORD((mapbase)<<1,0)
    // [1530] screenlayer::$2 = screenlayer::$1 w= 0 -- vwum1=vbuz2_word_vbuc1 
    lda #0
    ldy.z screenlayer__1
    sty screenlayer__2+1
    sta screenlayer__2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [1531] *((unsigned int *)&__conio+3) = screenlayer::$2 -- _deref_pwuc1=vwum1 
    sta __conio+3
    tya
    sta __conio+3+1
    // config & VERA_LAYER_WIDTH_MASK
    // [1532] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbum1=vbuz2_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and.z config
    sta screenlayer__7
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [1533] screenlayer::$8 = screenlayer::$7 >> 4 -- vbum1=vbum1_ror_4 
    lda screenlayer__8
    lsr
    lsr
    lsr
    lsr
    sta screenlayer__8
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [1534] *((char *)&__conio+8) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbum1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+8
    // config & VERA_LAYER_HEIGHT_MASK
    // [1535] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbuz1=vbuz1_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and.z screenlayer__5
    sta.z screenlayer__5
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [1536] screenlayer::$6 = screenlayer::$5 >> 6 -- vbuz1=vbuz1_ror_6 
    lda.z screenlayer__6
    rol
    rol
    rol
    and #3
    sta.z screenlayer__6
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [1537] *((char *)&__conio+9) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+9
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [1538] screenlayer::$16 = screenlayer::$8 << 1 -- vbum1=vbum1_rol_1 
    asl screenlayer__16
    // [1539] *((unsigned int *)&__conio+$a) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbum1 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    ldy screenlayer__16
    lda VERA_LAYER_SKIP,y
    sta __conio+$a
    lda VERA_LAYER_SKIP+1,y
    sta __conio+$a+1
    // vera_dc_hscale_temp == 0x80
    // [1540] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vbom1=vbum2_eq_vbuc1 
    lda vera_dc_hscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta screenlayer__9
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [1541] screenlayer::$18 = (char)screenlayer::$9
    // [1542] screenlayer::$10 = $28 << screenlayer::$18 -- vbum1=vbuc1_rol_vbum1 
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
    // [1543] screenlayer::$11 = screenlayer::$10 - 1 -- vbum1=vbum1_minus_1 
    dec screenlayer__11
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [1544] *((char *)&__conio+6) = screenlayer::$11 -- _deref_pbuc1=vbum1 
    lda screenlayer__11
    sta __conio+6
    // vera_dc_vscale_temp == 0x80
    // [1545] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vbom1=vbum2_eq_vbuc1 
    lda vera_dc_vscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta screenlayer__12
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [1546] screenlayer::$19 = (char)screenlayer::$12
    // [1547] screenlayer::$13 = $1e << screenlayer::$19 -- vbum1=vbuc1_rol_vbum1 
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
    // [1548] screenlayer::$14 = screenlayer::$13 - 1 -- vbum1=vbum1_minus_1 
    dec screenlayer__14
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [1549] *((char *)&__conio+7) = screenlayer::$14 -- _deref_pbuc1=vbum1 
    lda screenlayer__14
    sta __conio+7
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [1550] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta mapbase_offset
    lda __conio+3+1
    sta mapbase_offset+1
    // [1551] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [1551] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [1551] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [1552] if(screenlayer::y#2<=*((char *)&__conio+7)) goto screenlayer::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+7
    cmp.z y
    bcs __b2
    // screenlayer::@return
    // }
    // [1553] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [1554] screenlayer::$17 = screenlayer::y#2 << 1 -- vbum1=vbuz2_rol_1 
    lda.z y
    asl
    sta screenlayer__17
    // [1555] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbum1=vwum2 
    tay
    lda mapbase_offset
    sta __conio+$15,y
    lda mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [1556] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda mapbase_offset
    adc __conio+$a
    sta mapbase_offset
    lda mapbase_offset+1
    adc __conio+$a+1
    sta mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [1557] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [1551] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [1551] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [1551] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
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
    // [1558] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [1559] if(0!=((char *)&__conio+$f)[*((char *)&__conio+2)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [1560] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // [1561] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [1562] call gotoxy
    // [557] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [557] phi gotoxy::y#30 = 0 [phi:cscroll::@3->gotoxy#0] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.y
    // [557] phi gotoxy::x#30 = 0 [phi:cscroll::@3->gotoxy#1] -- vbuz1=vbuc1 
    sta.z gotoxy.x
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [1563] return 
    rts
    // [1564] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [1565] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [1566] gotoxy::y#3 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
    lda __conio+7
    sta.z gotoxy.y
    // [1567] call gotoxy
    // [557] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [557] phi gotoxy::y#30 = gotoxy::y#3 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [557] phi gotoxy::x#30 = 0 [phi:cscroll::@5->gotoxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.x
    jsr gotoxy
    // [1568] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [1569] call clearline
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
    // [1570] ((char *)&__conio+$f)[*((char *)&__conio+2)] = scroll::onoff#0 -- pbuc1_derefidx_(_deref_pbuc2)=vbuc3 
    lda #onoff
    ldy __conio+2
    sta __conio+$f,y
    // scroll::@return
    // }
    // [1571] return 
    rts
}
  // clrscr
// clears the screen and moves the cursor to the upper left-hand corner of the screen.
clrscr: {
    .label clrscr__0 = $64
    .label clrscr__1 = $6c
    // unsigned int line_text = __conio.mapbase_offset
    // [1572] clrscr::line_text#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta line_text
    lda __conio+3+1
    sta line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1573] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [1574] clrscr::$0 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clrscr__0
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1575] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [1576] clrscr::l#0 = *((char *)&__conio+9) -- vbum1=_deref_pbuc1 
    lda __conio+9
    sta l
    // [1577] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [1577] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [1577] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [1578] clrscr::$1 = byte0  clrscr::ch#0 -- vbuz1=_byte0_vwum2 
    lda ch
    sta.z clrscr__1
    // *VERA_ADDRX_L = BYTE0(ch)
    // [1579] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbuz1 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [1580] clrscr::$2 = byte1  clrscr::ch#0 -- vbum1=_byte1_vwum2 
    lda ch+1
    sta clrscr__2
    // *VERA_ADDRX_M = BYTE1(ch)
    // [1581] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth+1
    // [1582] clrscr::c#0 = *((char *)&__conio+8) + 1 -- vbum1=_deref_pbuc1_plus_1 
    lda __conio+8
    inc
    sta c
    // [1583] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [1583] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [1584] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1585] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [1586] clrscr::c#1 = -- clrscr::c#2 -- vbum1=_dec_vbum1 
    dec c
    // while(c)
    // [1587] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [1588] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda line_text
    adc __conio+$a
    sta line_text
    lda line_text+1
    adc __conio+$a+1
    sta line_text+1
    // l--;
    // [1589] clrscr::l#1 = -- clrscr::l#4 -- vbum1=_dec_vbum1 
    dec l
    // while(l)
    // [1590] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbum1_then_la1 
    lda l
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [1591] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y = 0
    // [1592] *((char *)&__conio+1) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+1
    // __conio.offset = __conio.mapbase_offset
    // [1593] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+3) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+3
    sta __conio+$13
    lda __conio+3+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [1594] return 
    rts
  .segment Data
    .label clrscr__2 = frame.w
    .label line_text = ch
    .label l = main.check_vera3_main__0
    ch: .word 0
    .label c = main.check_roms2_check_rom1_main__0
}
.segment Code
  // frame
// Draw a line horizontal from a given xy position and a given length.
// The line should calculate the matching characters to draw and glue them.
// So it first needs to peek the characters at the given position.
// And then calculate the resulting characters to draw.
// void frame(char x0, char y0, __zp($e9) char x1, __zp($bc) char y1)
frame: {
    .label h = $d7
    .label x = $d8
    .label y = $66
    .label mask = $ea
    .label c = $b6
    .label x_1 = $6e
    .label y_1 = $e3
    .label x1 = $e9
    .label y1 = $bc
    // unsigned char w = x1 - x0
    // [1596] frame::w#0 = frame::x1#16 - frame::x#0 -- vbum1=vbuz2_minus_vbuz3 
    lda.z x1
    sec
    sbc.z x
    sta w
    // unsigned char h = y1 - y0
    // [1597] frame::h#0 = frame::y1#16 - frame::y#0 -- vbuz1=vbuz2_minus_vbuz3 
    lda.z y1
    sec
    sbc.z y
    sta.z h
    // unsigned char mask = frame_maskxy(x, y)
    // [1598] frame_maskxy::x#0 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z frame_maskxy.x
    // [1599] frame_maskxy::y#0 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z frame_maskxy.y
    // [1600] call frame_maskxy
    // [2253] phi from frame to frame_maskxy [phi:frame->frame_maskxy]
    // [2253] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#0 [phi:frame->frame_maskxy#0] -- register_copy 
    // [2253] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#0 [phi:frame->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // unsigned char mask = frame_maskxy(x, y)
    // [1601] frame_maskxy::return#13 = frame_maskxy::return#12
    // frame::@13
    // [1602] frame::mask#0 = frame_maskxy::return#13
    // mask |= 0b0110
    // [1603] frame::mask#1 = frame::mask#0 | 6 -- vbuz1=vbuz1_bor_vbuc1 
    lda #6
    ora.z mask
    sta.z mask
    // unsigned char c = frame_char(mask)
    // [1604] frame_char::mask#0 = frame::mask#1
    // [1605] call frame_char
  // Add a corner.
    // [2279] phi from frame::@13 to frame_char [phi:frame::@13->frame_char]
    // [2279] phi frame_char::mask#10 = frame_char::mask#0 [phi:frame::@13->frame_char#0] -- register_copy 
    jsr frame_char
    // unsigned char c = frame_char(mask)
    // [1606] frame_char::return#13 = frame_char::return#12
    // frame::@14
    // [1607] frame::c#0 = frame_char::return#13
    // cputcxy(x, y, c)
    // [1608] cputcxy::x#0 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1609] cputcxy::y#0 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [1610] cputcxy::c#0 = frame::c#0
    // [1611] call cputcxy
    // [1738] phi from frame::@14 to cputcxy [phi:frame::@14->cputcxy]
    // [1738] phi cputcxy::c#15 = cputcxy::c#0 [phi:frame::@14->cputcxy#0] -- register_copy 
    // [1738] phi cputcxy::y#15 = cputcxy::y#0 [phi:frame::@14->cputcxy#1] -- register_copy 
    // [1738] phi cputcxy::x#15 = cputcxy::x#0 [phi:frame::@14->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@15
    // if(w>=2)
    // [1612] if(frame::w#0<2) goto frame::@36 -- vbum1_lt_vbuc1_then_la1 
    lda w
    cmp #2
    bcs !__b36+
    jmp __b36
  !__b36:
    // frame::@2
    // x++;
    // [1613] frame::x#1 = ++ frame::x#0 -- vbuz1=_inc_vbuz2 
    lda.z x
    inc
    sta.z x_1
    // [1614] phi from frame::@2 frame::@21 to frame::@4 [phi:frame::@2/frame::@21->frame::@4]
    // [1614] phi frame::x#10 = frame::x#1 [phi:frame::@2/frame::@21->frame::@4#0] -- register_copy 
    // frame::@4
  __b4:
    // while(x < x1)
    // [1615] if(frame::x#10<frame::x1#16) goto frame::@5 -- vbuz1_lt_vbuz2_then_la1 
    lda.z x_1
    cmp.z x1
    bcs !__b5+
    jmp __b5
  !__b5:
    // [1616] phi from frame::@36 frame::@4 to frame::@1 [phi:frame::@36/frame::@4->frame::@1]
    // [1616] phi frame::x#24 = frame::x#30 [phi:frame::@36/frame::@4->frame::@1#0] -- register_copy 
    // frame::@1
  __b1:
    // frame_maskxy(x, y)
    // [1617] frame_maskxy::x#1 = frame::x#24 -- vbuz1=vbuz2 
    lda.z x_1
    sta.z frame_maskxy.x
    // [1618] frame_maskxy::y#1 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z frame_maskxy.y
    // [1619] call frame_maskxy
    // [2253] phi from frame::@1 to frame_maskxy [phi:frame::@1->frame_maskxy]
    // [2253] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#1 [phi:frame::@1->frame_maskxy#0] -- register_copy 
    // [2253] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#1 [phi:frame::@1->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [1620] frame_maskxy::return#14 = frame_maskxy::return#12
    // frame::@16
    // mask = frame_maskxy(x, y)
    // [1621] frame::mask#2 = frame_maskxy::return#14
    // mask |= 0b0011
    // [1622] frame::mask#3 = frame::mask#2 | 3 -- vbuz1=vbuz1_bor_vbuc1 
    lda #3
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [1623] frame_char::mask#1 = frame::mask#3
    // [1624] call frame_char
    // [2279] phi from frame::@16 to frame_char [phi:frame::@16->frame_char]
    // [2279] phi frame_char::mask#10 = frame_char::mask#1 [phi:frame::@16->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1625] frame_char::return#14 = frame_char::return#12
    // frame::@17
    // c = frame_char(mask)
    // [1626] frame::c#1 = frame_char::return#14
    // cputcxy(x, y, c)
    // [1627] cputcxy::x#1 = frame::x#24 -- vbuz1=vbuz2 
    lda.z x_1
    sta.z cputcxy.x
    // [1628] cputcxy::y#1 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [1629] cputcxy::c#1 = frame::c#1
    // [1630] call cputcxy
    // [1738] phi from frame::@17 to cputcxy [phi:frame::@17->cputcxy]
    // [1738] phi cputcxy::c#15 = cputcxy::c#1 [phi:frame::@17->cputcxy#0] -- register_copy 
    // [1738] phi cputcxy::y#15 = cputcxy::y#1 [phi:frame::@17->cputcxy#1] -- register_copy 
    // [1738] phi cputcxy::x#15 = cputcxy::x#1 [phi:frame::@17->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@18
    // if(h>=2)
    // [1631] if(frame::h#0<2) goto frame::@return -- vbuz1_lt_vbuc1_then_la1 
    lda.z h
    cmp #2
    bcc __breturn
    // frame::@3
    // y++;
    // [1632] frame::y#1 = ++ frame::y#0 -- vbuz1=_inc_vbuz2 
    lda.z y
    inc
    sta.z y_1
    // [1633] phi from frame::@27 frame::@3 to frame::@6 [phi:frame::@27/frame::@3->frame::@6]
    // [1633] phi frame::y#10 = frame::y#2 [phi:frame::@27/frame::@3->frame::@6#0] -- register_copy 
    // frame::@6
  __b6:
    // while(y < y1)
    // [1634] if(frame::y#10<frame::y1#16) goto frame::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z y_1
    cmp.z y1
    bcc __b7
    // frame::@8
    // frame_maskxy(x, y)
    // [1635] frame_maskxy::x#5 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z frame_maskxy.x
    // [1636] frame_maskxy::y#5 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z frame_maskxy.y
    // [1637] call frame_maskxy
    // [2253] phi from frame::@8 to frame_maskxy [phi:frame::@8->frame_maskxy]
    // [2253] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#5 [phi:frame::@8->frame_maskxy#0] -- register_copy 
    // [2253] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#5 [phi:frame::@8->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [1638] frame_maskxy::return#18 = frame_maskxy::return#12
    // frame::@28
    // mask = frame_maskxy(x, y)
    // [1639] frame::mask#10 = frame_maskxy::return#18
    // mask |= 0b1100
    // [1640] frame::mask#11 = frame::mask#10 | $c -- vbuz1=vbuz1_bor_vbuc1 
    lda #$c
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [1641] frame_char::mask#5 = frame::mask#11
    // [1642] call frame_char
    // [2279] phi from frame::@28 to frame_char [phi:frame::@28->frame_char]
    // [2279] phi frame_char::mask#10 = frame_char::mask#5 [phi:frame::@28->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1643] frame_char::return#18 = frame_char::return#12
    // frame::@29
    // c = frame_char(mask)
    // [1644] frame::c#5 = frame_char::return#18
    // cputcxy(x, y, c)
    // [1645] cputcxy::x#5 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1646] cputcxy::y#5 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1647] cputcxy::c#5 = frame::c#5
    // [1648] call cputcxy
    // [1738] phi from frame::@29 to cputcxy [phi:frame::@29->cputcxy]
    // [1738] phi cputcxy::c#15 = cputcxy::c#5 [phi:frame::@29->cputcxy#0] -- register_copy 
    // [1738] phi cputcxy::y#15 = cputcxy::y#5 [phi:frame::@29->cputcxy#1] -- register_copy 
    // [1738] phi cputcxy::x#15 = cputcxy::x#5 [phi:frame::@29->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@30
    // if(w>=2)
    // [1649] if(frame::w#0<2) goto frame::@10 -- vbum1_lt_vbuc1_then_la1 
    lda w
    cmp #2
    bcc __b10
    // frame::@9
    // x++;
    // [1650] frame::x#4 = ++ frame::x#0 -- vbuz1=_inc_vbuz1 
    inc.z x
    // [1651] phi from frame::@35 frame::@9 to frame::@11 [phi:frame::@35/frame::@9->frame::@11]
    // [1651] phi frame::x#18 = frame::x#5 [phi:frame::@35/frame::@9->frame::@11#0] -- register_copy 
    // frame::@11
  __b11:
    // while(x < x1)
    // [1652] if(frame::x#18<frame::x1#16) goto frame::@12 -- vbuz1_lt_vbuz2_then_la1 
    lda.z x
    cmp.z x1
    bcc __b12
    // [1653] phi from frame::@11 frame::@30 to frame::@10 [phi:frame::@11/frame::@30->frame::@10]
    // [1653] phi frame::x#15 = frame::x#18 [phi:frame::@11/frame::@30->frame::@10#0] -- register_copy 
    // frame::@10
  __b10:
    // frame_maskxy(x, y)
    // [1654] frame_maskxy::x#6 = frame::x#15 -- vbuz1=vbuz2 
    lda.z x
    sta.z frame_maskxy.x
    // [1655] frame_maskxy::y#6 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z frame_maskxy.y
    // [1656] call frame_maskxy
    // [2253] phi from frame::@10 to frame_maskxy [phi:frame::@10->frame_maskxy]
    // [2253] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#6 [phi:frame::@10->frame_maskxy#0] -- register_copy 
    // [2253] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#6 [phi:frame::@10->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [1657] frame_maskxy::return#19 = frame_maskxy::return#12
    // frame::@31
    // mask = frame_maskxy(x, y)
    // [1658] frame::mask#12 = frame_maskxy::return#19
    // mask |= 0b1001
    // [1659] frame::mask#13 = frame::mask#12 | 9 -- vbuz1=vbuz1_bor_vbuc1 
    lda #9
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [1660] frame_char::mask#6 = frame::mask#13
    // [1661] call frame_char
    // [2279] phi from frame::@31 to frame_char [phi:frame::@31->frame_char]
    // [2279] phi frame_char::mask#10 = frame_char::mask#6 [phi:frame::@31->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1662] frame_char::return#19 = frame_char::return#12
    // frame::@32
    // c = frame_char(mask)
    // [1663] frame::c#6 = frame_char::return#19
    // cputcxy(x, y, c)
    // [1664] cputcxy::x#6 = frame::x#15 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1665] cputcxy::y#6 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1666] cputcxy::c#6 = frame::c#6
    // [1667] call cputcxy
    // [1738] phi from frame::@32 to cputcxy [phi:frame::@32->cputcxy]
    // [1738] phi cputcxy::c#15 = cputcxy::c#6 [phi:frame::@32->cputcxy#0] -- register_copy 
    // [1738] phi cputcxy::y#15 = cputcxy::y#6 [phi:frame::@32->cputcxy#1] -- register_copy 
    // [1738] phi cputcxy::x#15 = cputcxy::x#6 [phi:frame::@32->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@return
  __breturn:
    // }
    // [1668] return 
    rts
    // frame::@12
  __b12:
    // frame_maskxy(x, y)
    // [1669] frame_maskxy::x#7 = frame::x#18 -- vbuz1=vbuz2 
    lda.z x
    sta.z frame_maskxy.x
    // [1670] frame_maskxy::y#7 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z frame_maskxy.y
    // [1671] call frame_maskxy
    // [2253] phi from frame::@12 to frame_maskxy [phi:frame::@12->frame_maskxy]
    // [2253] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#7 [phi:frame::@12->frame_maskxy#0] -- register_copy 
    // [2253] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#7 [phi:frame::@12->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [1672] frame_maskxy::return#20 = frame_maskxy::return#12
    // frame::@33
    // mask = frame_maskxy(x, y)
    // [1673] frame::mask#14 = frame_maskxy::return#20
    // mask |= 0b0101
    // [1674] frame::mask#15 = frame::mask#14 | 5 -- vbuz1=vbuz1_bor_vbuc1 
    lda #5
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [1675] frame_char::mask#7 = frame::mask#15
    // [1676] call frame_char
    // [2279] phi from frame::@33 to frame_char [phi:frame::@33->frame_char]
    // [2279] phi frame_char::mask#10 = frame_char::mask#7 [phi:frame::@33->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1677] frame_char::return#20 = frame_char::return#12
    // frame::@34
    // c = frame_char(mask)
    // [1678] frame::c#7 = frame_char::return#20
    // cputcxy(x, y, c)
    // [1679] cputcxy::x#7 = frame::x#18 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1680] cputcxy::y#7 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1681] cputcxy::c#7 = frame::c#7
    // [1682] call cputcxy
    // [1738] phi from frame::@34 to cputcxy [phi:frame::@34->cputcxy]
    // [1738] phi cputcxy::c#15 = cputcxy::c#7 [phi:frame::@34->cputcxy#0] -- register_copy 
    // [1738] phi cputcxy::y#15 = cputcxy::y#7 [phi:frame::@34->cputcxy#1] -- register_copy 
    // [1738] phi cputcxy::x#15 = cputcxy::x#7 [phi:frame::@34->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@35
    // x++;
    // [1683] frame::x#5 = ++ frame::x#18 -- vbuz1=_inc_vbuz1 
    inc.z x
    jmp __b11
    // frame::@7
  __b7:
    // frame_maskxy(x0, y)
    // [1684] frame_maskxy::x#3 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z frame_maskxy.x
    // [1685] frame_maskxy::y#3 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z frame_maskxy.y
    // [1686] call frame_maskxy
    // [2253] phi from frame::@7 to frame_maskxy [phi:frame::@7->frame_maskxy]
    // [2253] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#3 [phi:frame::@7->frame_maskxy#0] -- register_copy 
    // [2253] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#3 [phi:frame::@7->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x0, y)
    // [1687] frame_maskxy::return#16 = frame_maskxy::return#12
    // frame::@22
    // mask = frame_maskxy(x0, y)
    // [1688] frame::mask#6 = frame_maskxy::return#16
    // mask |= 0b1010
    // [1689] frame::mask#7 = frame::mask#6 | $a -- vbuz1=vbuz1_bor_vbuc1 
    lda #$a
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [1690] frame_char::mask#3 = frame::mask#7
    // [1691] call frame_char
    // [2279] phi from frame::@22 to frame_char [phi:frame::@22->frame_char]
    // [2279] phi frame_char::mask#10 = frame_char::mask#3 [phi:frame::@22->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1692] frame_char::return#16 = frame_char::return#12
    // frame::@23
    // c = frame_char(mask)
    // [1693] frame::c#3 = frame_char::return#16
    // cputcxy(x0, y, c)
    // [1694] cputcxy::x#3 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1695] cputcxy::y#3 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1696] cputcxy::c#3 = frame::c#3
    // [1697] call cputcxy
    // [1738] phi from frame::@23 to cputcxy [phi:frame::@23->cputcxy]
    // [1738] phi cputcxy::c#15 = cputcxy::c#3 [phi:frame::@23->cputcxy#0] -- register_copy 
    // [1738] phi cputcxy::y#15 = cputcxy::y#3 [phi:frame::@23->cputcxy#1] -- register_copy 
    // [1738] phi cputcxy::x#15 = cputcxy::x#3 [phi:frame::@23->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@24
    // frame_maskxy(x1, y)
    // [1698] frame_maskxy::x#4 = frame::x1#16 -- vbuz1=vbuz2 
    lda.z x1
    sta.z frame_maskxy.x
    // [1699] frame_maskxy::y#4 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z frame_maskxy.y
    // [1700] call frame_maskxy
    // [2253] phi from frame::@24 to frame_maskxy [phi:frame::@24->frame_maskxy]
    // [2253] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#4 [phi:frame::@24->frame_maskxy#0] -- register_copy 
    // [2253] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#4 [phi:frame::@24->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x1, y)
    // [1701] frame_maskxy::return#17 = frame_maskxy::return#12
    // frame::@25
    // mask = frame_maskxy(x1, y)
    // [1702] frame::mask#8 = frame_maskxy::return#17
    // mask |= 0b1010
    // [1703] frame::mask#9 = frame::mask#8 | $a -- vbuz1=vbuz1_bor_vbuc1 
    lda #$a
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [1704] frame_char::mask#4 = frame::mask#9
    // [1705] call frame_char
    // [2279] phi from frame::@25 to frame_char [phi:frame::@25->frame_char]
    // [2279] phi frame_char::mask#10 = frame_char::mask#4 [phi:frame::@25->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1706] frame_char::return#17 = frame_char::return#12
    // frame::@26
    // c = frame_char(mask)
    // [1707] frame::c#4 = frame_char::return#17
    // cputcxy(x1, y, c)
    // [1708] cputcxy::x#4 = frame::x1#16 -- vbuz1=vbuz2 
    lda.z x1
    sta.z cputcxy.x
    // [1709] cputcxy::y#4 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1710] cputcxy::c#4 = frame::c#4
    // [1711] call cputcxy
    // [1738] phi from frame::@26 to cputcxy [phi:frame::@26->cputcxy]
    // [1738] phi cputcxy::c#15 = cputcxy::c#4 [phi:frame::@26->cputcxy#0] -- register_copy 
    // [1738] phi cputcxy::y#15 = cputcxy::y#4 [phi:frame::@26->cputcxy#1] -- register_copy 
    // [1738] phi cputcxy::x#15 = cputcxy::x#4 [phi:frame::@26->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@27
    // y++;
    // [1712] frame::y#2 = ++ frame::y#10 -- vbuz1=_inc_vbuz1 
    inc.z y_1
    jmp __b6
    // frame::@5
  __b5:
    // frame_maskxy(x, y)
    // [1713] frame_maskxy::x#2 = frame::x#10 -- vbuz1=vbuz2 
    lda.z x_1
    sta.z frame_maskxy.x
    // [1714] frame_maskxy::y#2 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z frame_maskxy.y
    // [1715] call frame_maskxy
    // [2253] phi from frame::@5 to frame_maskxy [phi:frame::@5->frame_maskxy]
    // [2253] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#2 [phi:frame::@5->frame_maskxy#0] -- register_copy 
    // [2253] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#2 [phi:frame::@5->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [1716] frame_maskxy::return#15 = frame_maskxy::return#12
    // frame::@19
    // mask = frame_maskxy(x, y)
    // [1717] frame::mask#4 = frame_maskxy::return#15
    // mask |= 0b0101
    // [1718] frame::mask#5 = frame::mask#4 | 5 -- vbuz1=vbuz1_bor_vbuc1 
    lda #5
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [1719] frame_char::mask#2 = frame::mask#5
    // [1720] call frame_char
    // [2279] phi from frame::@19 to frame_char [phi:frame::@19->frame_char]
    // [2279] phi frame_char::mask#10 = frame_char::mask#2 [phi:frame::@19->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1721] frame_char::return#15 = frame_char::return#12
    // frame::@20
    // c = frame_char(mask)
    // [1722] frame::c#2 = frame_char::return#15
    // cputcxy(x, y, c)
    // [1723] cputcxy::x#2 = frame::x#10 -- vbuz1=vbuz2 
    lda.z x_1
    sta.z cputcxy.x
    // [1724] cputcxy::y#2 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [1725] cputcxy::c#2 = frame::c#2
    // [1726] call cputcxy
    // [1738] phi from frame::@20 to cputcxy [phi:frame::@20->cputcxy]
    // [1738] phi cputcxy::c#15 = cputcxy::c#2 [phi:frame::@20->cputcxy#0] -- register_copy 
    // [1738] phi cputcxy::y#15 = cputcxy::y#2 [phi:frame::@20->cputcxy#1] -- register_copy 
    // [1738] phi cputcxy::x#15 = cputcxy::x#2 [phi:frame::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@21
    // x++;
    // [1727] frame::x#2 = ++ frame::x#10 -- vbuz1=_inc_vbuz1 
    inc.z x_1
    jmp __b4
    // frame::@36
  __b36:
    // [1728] frame::x#30 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z x_1
    jmp __b1
  .segment Data
    w: .byte 0
}
.segment Code
  // cputs
// Output a NUL-terminated string at the current cursor position
// void cputs(__zp($d3) const char *s)
cputs: {
    .label c = $d7
    .label s = $d3
    // [1730] phi from cputs cputs::@2 to cputs::@1 [phi:cputs/cputs::@2->cputs::@1]
    // [1730] phi cputs::s#2 = cputs::s#1 [phi:cputs/cputs::@2->cputs::@1#0] -- register_copy 
    // cputs::@1
  __b1:
    // while(c=*s++)
    // [1731] cputs::c#1 = *cputs::s#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta.z c
    // [1732] cputs::s#0 = ++ cputs::s#2 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [1733] if(0!=cputs::c#1) goto cputs::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // cputs::@return
    // }
    // [1734] return 
    rts
    // cputs::@2
  __b2:
    // cputc(c)
    // [1735] stackpush(char) = cputs::c#1 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [1736] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
}
  // cputcxy
// Move cursor and output one character
// Same as "gotoxy (x, y); cputc (c);"
// void cputcxy(__zp($bf) char x, __zp($36) char y, __zp($b6) char c)
cputcxy: {
    .label x = $bf
    .label y = $36
    .label c = $b6
    // gotoxy(x, y)
    // [1739] gotoxy::x#0 = cputcxy::x#15 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1740] gotoxy::y#0 = cputcxy::y#15 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1741] call gotoxy
    // [557] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [557] phi gotoxy::y#30 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [557] phi gotoxy::x#30 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [1742] stackpush(char) = cputcxy::c#15 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [1743] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [1745] return 
    rts
}
  // wherex
// Return the x position of the cursor
wherex: {
    .label return = $e4
    .label return_1 = $e7
    .label return_2 = $dc
    .label return_3 = $38
    .label return_4 = $eb
    // return __conio.cursor_x;
    // [1746] wherex::return#0 = *((char *)&__conio) -- vbuz1=_deref_pbuc1 
    lda __conio
    sta.z return
    // wherex::@return
    // }
    // [1747] return 
    rts
}
  // wherey
// Return the y position of the cursor
wherey: {
    .label return = $69
    .label return_1 = $e5
    .label return_2 = $63
    .label return_4 = $d9
    // return __conio.cursor_y;
    // [1748] wherey::return#0 = *((char *)&__conio+1) -- vbuz1=_deref_pbuc1 
    lda __conio+1
    sta.z return
    // wherey::@return
    // }
    // [1749] return 
    rts
  .segment Data
    .label return_3 = rom_detect.rom_detect__15
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
// __zp($2d) unsigned int cx16_k_i2c_read_byte(__mem() volatile char device, __mem() volatile char offset)
cx16_k_i2c_read_byte: {
    .label return = $2d
    // unsigned int result
    // [1750] cx16_k_i2c_read_byte::result = 0 -- vwum1=vwuc1 
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
    // [1752] cx16_k_i2c_read_byte::return#0 = cx16_k_i2c_read_byte::result -- vwuz1=vwum2 
    sta.z return
    lda result+1
    sta.z return+1
    // cx16_k_i2c_read_byte::@return
    // }
    // [1753] cx16_k_i2c_read_byte::return#1 = cx16_k_i2c_read_byte::return#0
    // [1754] return 
    rts
  .segment Data
    device: .byte 0
    offset: .byte 0
    result: .word 0
}
.segment Code
  // print_smc_led
// void print_smc_led(__zp($2f) char c)
print_smc_led: {
    .label c = $2f
    // print_chip_led(CHIP_SMC_X+1, CHIP_SMC_Y, CHIP_SMC_W, c, BLUE)
    // [1756] print_chip_led::tc#0 = print_smc_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z print_chip_led.tc
    // [1757] call print_chip_led
    // [2294] phi from print_smc_led to print_chip_led [phi:print_smc_led->print_chip_led]
    // [2294] phi print_chip_led::w#7 = 5 [phi:print_smc_led->print_chip_led#0] -- vbuz1=vbuc1 
    lda #5
    sta.z print_chip_led.w
    // [2294] phi print_chip_led::x#7 = 1+1 [phi:print_smc_led->print_chip_led#1] -- vbuz1=vbuc1 
    lda #1+1
    sta.z print_chip_led.x
    // [2294] phi print_chip_led::tc#3 = print_chip_led::tc#0 [phi:print_smc_led->print_chip_led#2] -- register_copy 
    jsr print_chip_led
    // print_smc_led::@1
    // print_info_led(INFO_X-2, INFO_Y, c, BLUE)
    // [1758] print_info_led::tc#0 = print_smc_led::c#2
    // [1759] call print_info_led
    // [1508] phi from print_smc_led::@1 to print_info_led [phi:print_smc_led::@1->print_info_led]
    // [1508] phi print_info_led::y#4 = $11 [phi:print_smc_led::@1->print_info_led#0] -- vbuz1=vbuc1 
    lda #$11
    sta.z print_info_led.y
    // [1508] phi print_info_led::x#4 = 4-2 [phi:print_smc_led::@1->print_info_led#1] -- vbuz1=vbuc1 
    lda #4-2
    sta.z print_info_led.x
    // [1508] phi print_info_led::tc#4 = print_info_led::tc#0 [phi:print_smc_led::@1->print_info_led#2] -- register_copy 
    jsr print_info_led
    // print_smc_led::@return
    // }
    // [1760] return 
    rts
}
  // print_chip
// void print_chip(__zp($64) char x, char y, __zp($6c) char w, __zp($3d) char *text)
print_chip: {
    .label y = 3+2+1+1+1+1+1+1+1+1
    .label text = $3d
    .label text_1 = $73
    .label x = $64
    .label text_2 = $55
    .label text_6 = $71
    .label w = $6c
    // print_chip_line(x, y++, w, *text++)
    // [1762] print_chip_line::x#0 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1763] print_chip_line::w#0 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1764] print_chip_line::c#0 = *print_chip::text#11 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_2),y
    sta.z print_chip_line.c
    // [1765] call print_chip_line
    // [2312] phi from print_chip to print_chip_line [phi:print_chip->print_chip_line]
    // [2312] phi print_chip_line::c#15 = print_chip_line::c#0 [phi:print_chip->print_chip_line#0] -- register_copy 
    // [2312] phi print_chip_line::w#10 = print_chip_line::w#0 [phi:print_chip->print_chip_line#1] -- register_copy 
    // [2312] phi print_chip_line::y#16 = 3+2 [phi:print_chip->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2
    sta.z print_chip_line.y
    // [2312] phi print_chip_line::x#16 = print_chip_line::x#0 [phi:print_chip->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@1
    // print_chip_line(x, y++, w, *text++);
    // [1766] print_chip::text#0 = ++ print_chip::text#11 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_2
    adc #1
    sta.z text
    lda.z text_2+1
    adc #0
    sta.z text+1
    // print_chip_line(x, y++, w, *text++)
    // [1767] print_chip_line::x#1 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1768] print_chip_line::w#1 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1769] print_chip_line::c#1 = *print_chip::text#0 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text),y
    sta.z print_chip_line.c
    // [1770] call print_chip_line
    // [2312] phi from print_chip::@1 to print_chip_line [phi:print_chip::@1->print_chip_line]
    // [2312] phi print_chip_line::c#15 = print_chip_line::c#1 [phi:print_chip::@1->print_chip_line#0] -- register_copy 
    // [2312] phi print_chip_line::w#10 = print_chip_line::w#1 [phi:print_chip::@1->print_chip_line#1] -- register_copy 
    // [2312] phi print_chip_line::y#16 = ++3+2 [phi:print_chip::@1->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1
    sta.z print_chip_line.y
    // [2312] phi print_chip_line::x#16 = print_chip_line::x#1 [phi:print_chip::@1->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@2
    // print_chip_line(x, y++, w, *text++);
    // [1771] print_chip::text#1 = ++ print_chip::text#0 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text
    adc #1
    sta.z text_1
    lda.z text+1
    adc #0
    sta.z text_1+1
    // print_chip_line(x, y++, w, *text++)
    // [1772] print_chip_line::x#2 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1773] print_chip_line::w#2 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1774] print_chip_line::c#2 = *print_chip::text#1 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_1),y
    sta.z print_chip_line.c
    // [1775] call print_chip_line
    // [2312] phi from print_chip::@2 to print_chip_line [phi:print_chip::@2->print_chip_line]
    // [2312] phi print_chip_line::c#15 = print_chip_line::c#2 [phi:print_chip::@2->print_chip_line#0] -- register_copy 
    // [2312] phi print_chip_line::w#10 = print_chip_line::w#2 [phi:print_chip::@2->print_chip_line#1] -- register_copy 
    // [2312] phi print_chip_line::y#16 = ++++3+2 [phi:print_chip::@2->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1
    sta.z print_chip_line.y
    // [2312] phi print_chip_line::x#16 = print_chip_line::x#2 [phi:print_chip::@2->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@3
    // print_chip_line(x, y++, w, *text++);
    // [1776] print_chip::text#15 = ++ print_chip::text#1 -- pbum1=_inc_pbuz2 
    clc
    lda.z text_1
    adc #1
    sta text_3
    lda.z text_1+1
    adc #0
    sta text_3+1
    // print_chip_line(x, y++, w, *text++)
    // [1777] print_chip_line::x#3 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1778] print_chip_line::w#3 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1779] print_chip_line::c#3 = *print_chip::text#15 -- vbuz1=_deref_pbum2 
    ldy text_3
    sty.z $fe
    ldy text_3+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta.z print_chip_line.c
    // [1780] call print_chip_line
    // [2312] phi from print_chip::@3 to print_chip_line [phi:print_chip::@3->print_chip_line]
    // [2312] phi print_chip_line::c#15 = print_chip_line::c#3 [phi:print_chip::@3->print_chip_line#0] -- register_copy 
    // [2312] phi print_chip_line::w#10 = print_chip_line::w#3 [phi:print_chip::@3->print_chip_line#1] -- register_copy 
    // [2312] phi print_chip_line::y#16 = ++++++3+2 [phi:print_chip::@3->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1
    sta.z print_chip_line.y
    // [2312] phi print_chip_line::x#16 = print_chip_line::x#3 [phi:print_chip::@3->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@4
    // print_chip_line(x, y++, w, *text++);
    // [1781] print_chip::text#16 = ++ print_chip::text#15 -- pbum1=_inc_pbum2 
    clc
    lda text_3
    adc #1
    sta text_4
    lda text_3+1
    adc #0
    sta text_4+1
    // print_chip_line(x, y++, w, *text++)
    // [1782] print_chip_line::x#4 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1783] print_chip_line::w#4 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1784] print_chip_line::c#4 = *print_chip::text#16 -- vbuz1=_deref_pbum2 
    ldy text_4
    sty.z $fe
    ldy text_4+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta.z print_chip_line.c
    // [1785] call print_chip_line
    // [2312] phi from print_chip::@4 to print_chip_line [phi:print_chip::@4->print_chip_line]
    // [2312] phi print_chip_line::c#15 = print_chip_line::c#4 [phi:print_chip::@4->print_chip_line#0] -- register_copy 
    // [2312] phi print_chip_line::w#10 = print_chip_line::w#4 [phi:print_chip::@4->print_chip_line#1] -- register_copy 
    // [2312] phi print_chip_line::y#16 = ++++++++3+2 [phi:print_chip::@4->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1
    sta.z print_chip_line.y
    // [2312] phi print_chip_line::x#16 = print_chip_line::x#4 [phi:print_chip::@4->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@5
    // print_chip_line(x, y++, w, *text++);
    // [1786] print_chip::text#17 = ++ print_chip::text#16 -- pbum1=_inc_pbum2 
    clc
    lda text_4
    adc #1
    sta text_5
    lda text_4+1
    adc #0
    sta text_5+1
    // print_chip_line(x, y++, w, *text++)
    // [1787] print_chip_line::x#5 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1788] print_chip_line::w#5 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1789] print_chip_line::c#5 = *print_chip::text#17 -- vbuz1=_deref_pbum2 
    ldy text_5
    sty.z $fe
    ldy text_5+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta.z print_chip_line.c
    // [1790] call print_chip_line
    // [2312] phi from print_chip::@5 to print_chip_line [phi:print_chip::@5->print_chip_line]
    // [2312] phi print_chip_line::c#15 = print_chip_line::c#5 [phi:print_chip::@5->print_chip_line#0] -- register_copy 
    // [2312] phi print_chip_line::w#10 = print_chip_line::w#5 [phi:print_chip::@5->print_chip_line#1] -- register_copy 
    // [2312] phi print_chip_line::y#16 = ++++++++++3+2 [phi:print_chip::@5->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1+1
    sta.z print_chip_line.y
    // [2312] phi print_chip_line::x#16 = print_chip_line::x#5 [phi:print_chip::@5->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@6
    // print_chip_line(x, y++, w, *text++);
    // [1791] print_chip::text#18 = ++ print_chip::text#17 -- pbuz1=_inc_pbum2 
    clc
    lda text_5
    adc #1
    sta.z text_6
    lda text_5+1
    adc #0
    sta.z text_6+1
    // print_chip_line(x, y++, w, *text++)
    // [1792] print_chip_line::x#6 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1793] print_chip_line::w#6 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1794] print_chip_line::c#6 = *print_chip::text#18 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta.z print_chip_line.c
    // [1795] call print_chip_line
    // [2312] phi from print_chip::@6 to print_chip_line [phi:print_chip::@6->print_chip_line]
    // [2312] phi print_chip_line::c#15 = print_chip_line::c#6 [phi:print_chip::@6->print_chip_line#0] -- register_copy 
    // [2312] phi print_chip_line::w#10 = print_chip_line::w#6 [phi:print_chip::@6->print_chip_line#1] -- register_copy 
    // [2312] phi print_chip_line::y#16 = ++++++++++++3+2 [phi:print_chip::@6->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1+1+1
    sta.z print_chip_line.y
    // [2312] phi print_chip_line::x#16 = print_chip_line::x#6 [phi:print_chip::@6->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@7
    // print_chip_line(x, y++, w, *text++);
    // [1796] print_chip::text#19 = ++ print_chip::text#18 -- pbuz1=_inc_pbuz1 
    inc.z text_6
    bne !+
    inc.z text_6+1
  !:
    // print_chip_line(x, y++, w, *text++)
    // [1797] print_chip_line::x#7 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1798] print_chip_line::w#7 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1799] print_chip_line::c#7 = *print_chip::text#19 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta.z print_chip_line.c
    // [1800] call print_chip_line
    // [2312] phi from print_chip::@7 to print_chip_line [phi:print_chip::@7->print_chip_line]
    // [2312] phi print_chip_line::c#15 = print_chip_line::c#7 [phi:print_chip::@7->print_chip_line#0] -- register_copy 
    // [2312] phi print_chip_line::w#10 = print_chip_line::w#7 [phi:print_chip::@7->print_chip_line#1] -- register_copy 
    // [2312] phi print_chip_line::y#16 = ++++++++++++++3+2 [phi:print_chip::@7->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1+1+1+1
    sta.z print_chip_line.y
    // [2312] phi print_chip_line::x#16 = print_chip_line::x#7 [phi:print_chip::@7->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@8
    // print_chip_end(x, y++, w)
    // [1801] print_chip_end::x#0 = print_chip::x#10
    // [1802] print_chip_end::w#0 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_end.w
    // [1803] call print_chip_end
    jsr print_chip_end
    // print_chip::@return
    // }
    // [1804] return 
    rts
  .segment Data
    .label text_3 = fopen.fopen__28
    .label text_4 = fopen.fopen__11
    .label text_5 = ferror.return
}
.segment Code
  // utoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void utoa(__zp($2d) unsigned int value, __zp($55) char *buffer, __zp($de) char radix)
utoa: {
    .label utoa__4 = $6a
    .label utoa__10 = $62
    .label utoa__11 = $68
    .label digit_value = $3d
    .label buffer = $55
    .label digit = $66
    .label value = $2d
    .label radix = $de
    .label started = $6e
    .label max_digits = $bc
    .label digit_values = $b8
    // if(radix==DECIMAL)
    // [1805] if(utoa::radix#0==DECIMAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp.z radix
    beq __b2
    // utoa::@2
    // if(radix==HEXADECIMAL)
    // [1806] if(utoa::radix#0==HEXADECIMAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp.z radix
    beq __b3
    // utoa::@3
    // if(radix==OCTAL)
    // [1807] if(utoa::radix#0==OCTAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp.z radix
    beq __b4
    // utoa::@4
    // if(radix==BINARY)
    // [1808] if(utoa::radix#0==BINARY) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp.z radix
    beq __b5
    // utoa::@5
    // *buffer++ = 'e'
    // [1809] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1810] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1811] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1812] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // utoa::@return
    // }
    // [1813] return 
    rts
    // [1814] phi from utoa to utoa::@1 [phi:utoa->utoa::@1]
  __b2:
    // [1814] phi utoa::digit_values#8 = RADIX_DECIMAL_VALUES [phi:utoa->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_DECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES
    sta.z digit_values+1
    // [1814] phi utoa::max_digits#7 = 5 [phi:utoa->utoa::@1#1] -- vbuz1=vbuc1 
    lda #5
    sta.z max_digits
    jmp __b1
    // [1814] phi from utoa::@2 to utoa::@1 [phi:utoa::@2->utoa::@1]
  __b3:
    // [1814] phi utoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES [phi:utoa::@2->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_HEXADECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES
    sta.z digit_values+1
    // [1814] phi utoa::max_digits#7 = 4 [phi:utoa::@2->utoa::@1#1] -- vbuz1=vbuc1 
    lda #4
    sta.z max_digits
    jmp __b1
    // [1814] phi from utoa::@3 to utoa::@1 [phi:utoa::@3->utoa::@1]
  __b4:
    // [1814] phi utoa::digit_values#8 = RADIX_OCTAL_VALUES [phi:utoa::@3->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_OCTAL_VALUES
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES
    sta.z digit_values+1
    // [1814] phi utoa::max_digits#7 = 6 [phi:utoa::@3->utoa::@1#1] -- vbuz1=vbuc1 
    lda #6
    sta.z max_digits
    jmp __b1
    // [1814] phi from utoa::@4 to utoa::@1 [phi:utoa::@4->utoa::@1]
  __b5:
    // [1814] phi utoa::digit_values#8 = RADIX_BINARY_VALUES [phi:utoa::@4->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_BINARY_VALUES
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES
    sta.z digit_values+1
    // [1814] phi utoa::max_digits#7 = $10 [phi:utoa::@4->utoa::@1#1] -- vbuz1=vbuc1 
    lda #$10
    sta.z max_digits
    // utoa::@1
  __b1:
    // [1815] phi from utoa::@1 to utoa::@6 [phi:utoa::@1->utoa::@6]
    // [1815] phi utoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:utoa::@1->utoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1815] phi utoa::started#2 = 0 [phi:utoa::@1->utoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [1815] phi utoa::value#2 = utoa::value#1 [phi:utoa::@1->utoa::@6#2] -- register_copy 
    // [1815] phi utoa::digit#2 = 0 [phi:utoa::@1->utoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // utoa::@6
  __b6:
    // max_digits-1
    // [1816] utoa::$4 = utoa::max_digits#7 - 1 -- vbuz1=vbuz2_minus_1 
    ldx.z max_digits
    dex
    stx.z utoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1817] if(utoa::digit#2<utoa::$4) goto utoa::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z digit
    cmp.z utoa__4
    bcc __b7
    // utoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1818] utoa::$11 = (char)utoa::value#2 -- vbuz1=_byte_vwuz2 
    lda.z value
    sta.z utoa__11
    // [1819] *utoa::buffer#11 = DIGITS[utoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1820] utoa::buffer#3 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1821] *utoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // utoa::@7
  __b7:
    // unsigned int digit_value = digit_values[digit]
    // [1822] utoa::$10 = utoa::digit#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z digit
    asl
    sta.z utoa__10
    // [1823] utoa::digit_value#0 = utoa::digit_values#8[utoa::$10] -- vwuz1=pwuz2_derefidx_vbuz3 
    tay
    lda (digit_values),y
    sta.z digit_value
    iny
    lda (digit_values),y
    sta.z digit_value+1
    // if (started || value >= digit_value)
    // [1824] if(0!=utoa::started#2) goto utoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // utoa::@12
    // [1825] if(utoa::value#2>=utoa::digit_value#0) goto utoa::@10 -- vwuz1_ge_vwuz2_then_la1 
    lda.z digit_value+1
    cmp.z value+1
    bne !+
    lda.z digit_value
    cmp.z value
    beq __b10
  !:
    bcc __b10
    // [1826] phi from utoa::@12 to utoa::@9 [phi:utoa::@12->utoa::@9]
    // [1826] phi utoa::buffer#14 = utoa::buffer#11 [phi:utoa::@12->utoa::@9#0] -- register_copy 
    // [1826] phi utoa::started#4 = utoa::started#2 [phi:utoa::@12->utoa::@9#1] -- register_copy 
    // [1826] phi utoa::value#6 = utoa::value#2 [phi:utoa::@12->utoa::@9#2] -- register_copy 
    // utoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1827] utoa::digit#1 = ++ utoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1815] phi from utoa::@9 to utoa::@6 [phi:utoa::@9->utoa::@6]
    // [1815] phi utoa::buffer#11 = utoa::buffer#14 [phi:utoa::@9->utoa::@6#0] -- register_copy 
    // [1815] phi utoa::started#2 = utoa::started#4 [phi:utoa::@9->utoa::@6#1] -- register_copy 
    // [1815] phi utoa::value#2 = utoa::value#6 [phi:utoa::@9->utoa::@6#2] -- register_copy 
    // [1815] phi utoa::digit#2 = utoa::digit#1 [phi:utoa::@9->utoa::@6#3] -- register_copy 
    jmp __b6
    // utoa::@10
  __b10:
    // utoa_append(buffer++, value, digit_value)
    // [1828] utoa_append::buffer#0 = utoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z utoa_append.buffer
    lda.z buffer+1
    sta.z utoa_append.buffer+1
    // [1829] utoa_append::value#0 = utoa::value#2
    // [1830] utoa_append::sub#0 = utoa::digit_value#0
    // [1831] call utoa_append
    // [2373] phi from utoa::@10 to utoa_append [phi:utoa::@10->utoa_append]
    jsr utoa_append
    // utoa_append(buffer++, value, digit_value)
    // [1832] utoa_append::return#0 = utoa_append::value#2
    // utoa::@11
    // value = utoa_append(buffer++, value, digit_value)
    // [1833] utoa::value#0 = utoa_append::return#0
    // value = utoa_append(buffer++, value, digit_value);
    // [1834] utoa::buffer#4 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1826] phi from utoa::@11 to utoa::@9 [phi:utoa::@11->utoa::@9]
    // [1826] phi utoa::buffer#14 = utoa::buffer#4 [phi:utoa::@11->utoa::@9#0] -- register_copy 
    // [1826] phi utoa::started#4 = 1 [phi:utoa::@11->utoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [1826] phi utoa::value#6 = utoa::value#0 [phi:utoa::@11->utoa::@9#2] -- register_copy 
    jmp __b9
}
  // printf_number_buffer
// Print the contents of the number buffer using a specific format.
// This handles minimum length, zero-filling, and left/right justification from the format
// void printf_number_buffer(__zp($4d) void (*putc)(char), __zp($e3) char buffer_sign, char *buffer_digits, __zp($e2) char format_min_length, char format_justify_left, char format_sign_always, __zp($e1) char format_zero_padding, char format_upper_case, char format_radix)
printf_number_buffer: {
    .label printf_number_buffer__19 = $55
    .label putc = $4d
    .label buffer_sign = $e3
    .label format_min_length = $e2
    .label format_zero_padding = $e1
    .label len = $d8
    .label padding = $d8
    // if(format.min_length)
    // [1836] if(0==printf_number_buffer::format_min_length#3) goto printf_number_buffer::@1 -- 0_eq_vbuz1_then_la1 
    lda.z format_min_length
    beq __b5
    // [1837] phi from printf_number_buffer to printf_number_buffer::@5 [phi:printf_number_buffer->printf_number_buffer::@5]
    // printf_number_buffer::@5
    // strlen(buffer.digits)
    // [1838] call strlen
    // [2121] phi from printf_number_buffer::@5 to strlen [phi:printf_number_buffer::@5->strlen]
    // [2121] phi strlen::str#8 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@5->strlen#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str+1
    jsr strlen
    // strlen(buffer.digits)
    // [1839] strlen::return#3 = strlen::len#2
    // printf_number_buffer::@11
    // [1840] printf_number_buffer::$19 = strlen::return#3
    // signed char len = (signed char)strlen(buffer.digits)
    // [1841] printf_number_buffer::len#0 = (signed char)printf_number_buffer::$19 -- vbsz1=_sbyte_vwuz2 
    // There is a minimum length - work out the padding
    lda.z printf_number_buffer__19
    sta.z len
    // if(buffer.sign)
    // [1842] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@10 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b10
    // printf_number_buffer::@6
    // len++;
    // [1843] printf_number_buffer::len#1 = ++ printf_number_buffer::len#0 -- vbsz1=_inc_vbsz1 
    inc.z len
    // [1844] phi from printf_number_buffer::@11 printf_number_buffer::@6 to printf_number_buffer::@10 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10]
    // [1844] phi printf_number_buffer::len#2 = printf_number_buffer::len#0 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10#0] -- register_copy 
    // printf_number_buffer::@10
  __b10:
    // padding = (signed char)format.min_length - len
    // [1845] printf_number_buffer::padding#1 = (signed char)printf_number_buffer::format_min_length#3 - printf_number_buffer::len#2 -- vbsz1=vbsz2_minus_vbsz1 
    lda.z format_min_length
    sec
    sbc.z padding
    sta.z padding
    // if(padding<0)
    // [1846] if(printf_number_buffer::padding#1>=0) goto printf_number_buffer::@15 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1848] phi from printf_number_buffer printf_number_buffer::@10 to printf_number_buffer::@1 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1]
  __b5:
    // [1848] phi printf_number_buffer::padding#10 = 0 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [1847] phi from printf_number_buffer::@10 to printf_number_buffer::@15 [phi:printf_number_buffer::@10->printf_number_buffer::@15]
    // printf_number_buffer::@15
    // [1848] phi from printf_number_buffer::@15 to printf_number_buffer::@1 [phi:printf_number_buffer::@15->printf_number_buffer::@1]
    // [1848] phi printf_number_buffer::padding#10 = printf_number_buffer::padding#1 [phi:printf_number_buffer::@15->printf_number_buffer::@1#0] -- register_copy 
    // printf_number_buffer::@1
  __b1:
    // printf_number_buffer::@13
    // if(!format.justify_left && !format.zero_padding && padding)
    // [1849] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_zero_padding
    bne __b2
    // printf_number_buffer::@12
    // [1850] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@7 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b7
    jmp __b2
    // printf_number_buffer::@7
  __b7:
    // printf_padding(putc, ' ',(char)padding)
    // [1851] printf_padding::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1852] printf_padding::length#0 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1853] call printf_padding
    // [2127] phi from printf_number_buffer::@7 to printf_padding [phi:printf_number_buffer::@7->printf_padding]
    // [2127] phi printf_padding::putc#7 = printf_padding::putc#0 [phi:printf_number_buffer::@7->printf_padding#0] -- register_copy 
    // [2127] phi printf_padding::pad#7 = ' ' [phi:printf_number_buffer::@7->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [2127] phi printf_padding::length#6 = printf_padding::length#0 [phi:printf_number_buffer::@7->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@2
  __b2:
    // if(buffer.sign)
    // [1854] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@3 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b3
    // printf_number_buffer::@8
    // putc(buffer.sign)
    // [1855] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbuz1 
    pha
    // [1856] callexecute *printf_number_buffer::putc#10  -- call__deref_pprz1 
    jsr icall32
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@3
  __b3:
    // if(format.zero_padding && padding)
    // [1858] if(0==printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@4 -- 0_eq_vbuz1_then_la1 
    lda.z format_zero_padding
    beq __b4
    // printf_number_buffer::@14
    // [1859] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@9 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b9
    jmp __b4
    // printf_number_buffer::@9
  __b9:
    // printf_padding(putc, '0',(char)padding)
    // [1860] printf_padding::putc#1 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1861] printf_padding::length#1 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1862] call printf_padding
    // [2127] phi from printf_number_buffer::@9 to printf_padding [phi:printf_number_buffer::@9->printf_padding]
    // [2127] phi printf_padding::putc#7 = printf_padding::putc#1 [phi:printf_number_buffer::@9->printf_padding#0] -- register_copy 
    // [2127] phi printf_padding::pad#7 = '0' [phi:printf_number_buffer::@9->printf_padding#1] -- vbuz1=vbuc1 
    lda #'0'
    sta.z printf_padding.pad
    // [2127] phi printf_padding::length#6 = printf_padding::length#1 [phi:printf_number_buffer::@9->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@4
  __b4:
    // printf_str(putc, buffer.digits)
    // [1863] printf_str::putc#0 = printf_number_buffer::putc#10
    // [1864] call printf_str
    // [700] phi from printf_number_buffer::@4 to printf_str [phi:printf_number_buffer::@4->printf_str]
    // [700] phi printf_str::putc#68 = printf_str::putc#0 [phi:printf_number_buffer::@4->printf_str#0] -- register_copy 
    // [700] phi printf_str::s#68 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@return
    // }
    // [1865] return 
    rts
    // Outside Flow
  icall32:
    jmp (putc)
}
  // print_vera_led
// void print_vera_led(__zp($68) char c)
print_vera_led: {
    .label c = $68
    // print_chip_led(CHIP_VERA_X+1, CHIP_VERA_Y, CHIP_VERA_W, c, BLUE)
    // [1867] print_chip_led::tc#1 = print_vera_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z print_chip_led.tc
    // [1868] call print_chip_led
    // [2294] phi from print_vera_led to print_chip_led [phi:print_vera_led->print_chip_led]
    // [2294] phi print_chip_led::w#7 = 8 [phi:print_vera_led->print_chip_led#0] -- vbuz1=vbuc1 
    lda #8
    sta.z print_chip_led.w
    // [2294] phi print_chip_led::x#7 = 9+1 [phi:print_vera_led->print_chip_led#1] -- vbuz1=vbuc1 
    lda #9+1
    sta.z print_chip_led.x
    // [2294] phi print_chip_led::tc#3 = print_chip_led::tc#1 [phi:print_vera_led->print_chip_led#2] -- register_copy 
    jsr print_chip_led
    // print_vera_led::@1
    // print_info_led(INFO_X-2, INFO_Y+1, c, BLUE)
    // [1869] print_info_led::tc#1 = print_vera_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z print_info_led.tc
    // [1870] call print_info_led
    // [1508] phi from print_vera_led::@1 to print_info_led [phi:print_vera_led::@1->print_info_led]
    // [1508] phi print_info_led::y#4 = $11+1 [phi:print_vera_led::@1->print_info_led#0] -- vbuz1=vbuc1 
    lda #$11+1
    sta.z print_info_led.y
    // [1508] phi print_info_led::x#4 = 4-2 [phi:print_vera_led::@1->print_info_led#1] -- vbuz1=vbuc1 
    lda #4-2
    sta.z print_info_led.x
    // [1508] phi print_info_led::tc#4 = print_info_led::tc#1 [phi:print_vera_led::@1->print_info_led#2] -- register_copy 
    jsr print_info_led
    // print_vera_led::@return
    // }
    // [1871] return 
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
// void rom_unlock(__zp($77) unsigned long address, __zp($ad) char unlock_code)
rom_unlock: {
    .label chip_address = $41
    .label address = $77
    .label unlock_code = $ad
    // unsigned long chip_address = address & ROM_CHIP_MASK
    // [1873] rom_unlock::chip_address#0 = rom_unlock::address#5 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [1874] rom_write_byte::address#0 = rom_unlock::chip_address#0 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [1875] call rom_write_byte
  // This is a very important operation...
    // [2380] phi from rom_unlock to rom_write_byte [phi:rom_unlock->rom_write_byte]
    // [2380] phi rom_write_byte::value#10 = $aa [phi:rom_unlock->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$aa
    sta.z rom_write_byte.value
    // [2380] phi rom_write_byte::address#4 = rom_write_byte::address#0 [phi:rom_unlock->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@1
    // rom_write_byte(chip_address + 0x02AAA, 0x55)
    // [1876] rom_write_byte::address#1 = rom_unlock::chip_address#0 + $2aaa -- vduz1=vduz2_plus_vwuc1 
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
    // [1877] call rom_write_byte
    // [2380] phi from rom_unlock::@1 to rom_write_byte [phi:rom_unlock::@1->rom_write_byte]
    // [2380] phi rom_write_byte::value#10 = $55 [phi:rom_unlock::@1->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$55
    sta.z rom_write_byte.value
    // [2380] phi rom_write_byte::address#4 = rom_write_byte::address#1 [phi:rom_unlock::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@2
    // rom_write_byte(address, unlock_code)
    // [1878] rom_write_byte::address#2 = rom_unlock::address#5 -- vduz1=vduz2 
    lda.z address
    sta.z rom_write_byte.address
    lda.z address+1
    sta.z rom_write_byte.address+1
    lda.z address+2
    sta.z rom_write_byte.address+2
    lda.z address+3
    sta.z rom_write_byte.address+3
    // [1879] rom_write_byte::value#2 = rom_unlock::unlock_code#5 -- vbuz1=vbuz2 
    lda.z unlock_code
    sta.z rom_write_byte.value
    // [1880] call rom_write_byte
    // [2380] phi from rom_unlock::@2 to rom_write_byte [phi:rom_unlock::@2->rom_write_byte]
    // [2380] phi rom_write_byte::value#10 = rom_write_byte::value#2 [phi:rom_unlock::@2->rom_write_byte#0] -- register_copy 
    // [2380] phi rom_write_byte::address#4 = rom_write_byte::address#2 [phi:rom_unlock::@2->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@return
    // }
    // [1881] return 
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
// __zp($69) char rom_read_byte(__zp($57) unsigned long address)
rom_read_byte: {
    .label rom_bank1_rom_read_byte__0 = $68
    .label rom_bank1_rom_read_byte__1 = $62
    .label rom_ptr1_rom_read_byte__0 = $f8
    .label rom_ptr1_rom_read_byte__2 = $f8
    .label rom_bank1_return = $53
    .label rom_ptr1_return = $f8
    .label return = $69
    .label address = $57
    // rom_read_byte::rom_bank1
    // BYTE2(address)
    // [1883] rom_read_byte::rom_bank1_$0 = byte2  rom_read_byte::address#2 -- vbuz1=_byte2_vduz2 
    lda.z address+2
    sta.z rom_bank1_rom_read_byte__0
    // BYTE1(address)
    // [1884] rom_read_byte::rom_bank1_$1 = byte1  rom_read_byte::address#2 -- vbuz1=_byte1_vduz2 
    lda.z address+1
    sta.z rom_bank1_rom_read_byte__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [1885] rom_read_byte::rom_bank1_$2 = rom_read_byte::rom_bank1_$0 w= rom_read_byte::rom_bank1_$1 -- vwum1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_read_byte__0
    sta rom_bank1_rom_read_byte__2+1
    lda.z rom_bank1_rom_read_byte__1
    sta rom_bank1_rom_read_byte__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [1886] rom_read_byte::rom_bank1_bank_unshifted#0 = rom_read_byte::rom_bank1_$2 << 2 -- vwum1=vwum1_rol_2 
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [1887] rom_read_byte::rom_bank1_return#0 = byte1  rom_read_byte::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwum2 
    lda rom_bank1_bank_unshifted+1
    sta.z rom_bank1_return
    // rom_read_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [1888] rom_read_byte::rom_ptr1_$2 = (unsigned int)rom_read_byte::address#2 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_read_byte__2
    lda.z address+1
    sta.z rom_ptr1_rom_read_byte__2+1
    // [1889] rom_read_byte::rom_ptr1_$0 = rom_read_byte::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_read_byte__0
    and #<$3fff
    sta.z rom_ptr1_rom_read_byte__0
    lda.z rom_ptr1_rom_read_byte__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_read_byte__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [1890] rom_read_byte::rom_ptr1_return#0 = rom_read_byte::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_read_byte::bank_set_brom1
    // BROM = bank
    // [1891] BROM = rom_read_byte::rom_bank1_return#0 -- vbuz1=vbuz2 
    lda.z rom_bank1_return
    sta.z BROM
    // rom_read_byte::@1
    // return *ptr_rom;
    // [1892] rom_read_byte::return#0 = *((char *)rom_read_byte::rom_ptr1_return#0) -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (rom_ptr1_return),y
    sta.z return
    // rom_read_byte::@return
    // }
    // [1893] return 
    rts
  .segment Data
    rom_bank1_rom_read_byte__2: .word 0
    .label rom_bank1_bank_unshifted = rom_bank1_rom_read_byte__2
}
.segment Code
  // strcpy
// Copies the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcpy(char *destination, char *source)
strcpy: {
    // [1895] phi from strcpy to strcpy::@1 [phi:strcpy->strcpy::@1]
    // [1895] phi strcpy::dst#2 = chip_rom::rom [phi:strcpy->strcpy::@1#0] -- pbum1=pbuc1 
    lda #<chip_rom.rom
    sta dst
    lda #>chip_rom.rom
    sta dst+1
    // [1895] phi strcpy::src#2 = chip_rom::source [phi:strcpy->strcpy::@1#1] -- pbum1=pbuc1 
    lda #<chip_rom.source
    sta src
    lda #>chip_rom.source
    sta src+1
    // strcpy::@1
  __b1:
    // while(*src)
    // [1896] if(0!=*strcpy::src#2) goto strcpy::@2 -- 0_neq__deref_pbum1_then_la1 
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
    // [1897] *strcpy::dst#2 = 0 -- _deref_pbum1=vbuc1 
    tya
    ldy dst
    sty.z $fe
    ldy dst+1
    sty.z $ff
    tay
    sta ($fe),y
    // strcpy::@return
    // }
    // [1898] return 
    rts
    // strcpy::@2
  __b2:
    // *dst++ = *src++
    // [1899] *strcpy::dst#2 = *strcpy::src#2 -- _deref_pbum1=_deref_pbum2 
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
    // [1900] strcpy::dst#1 = ++ strcpy::dst#2 -- pbum1=_inc_pbum1 
    inc dst
    bne !+
    inc dst+1
  !:
    // [1901] strcpy::src#1 = ++ strcpy::src#2 -- pbum1=_inc_pbum1 
    inc src
    bne !+
    inc src+1
  !:
    // [1895] phi from strcpy::@2 to strcpy::@1 [phi:strcpy::@2->strcpy::@1]
    // [1895] phi strcpy::dst#2 = strcpy::dst#1 [phi:strcpy::@2->strcpy::@1#0] -- register_copy 
    // [1895] phi strcpy::src#2 = strcpy::src#1 [phi:strcpy::@2->strcpy::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    dst: .word 0
    src: .word 0
}
.segment Code
  // strcat
// Concatenates the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcat(char *destination, __zp($2d) char *source)
strcat: {
    .label strcat__0 = $55
    .label dst = $55
    .label src = $2d
    .label source = $2d
    // strlen(destination)
    // [1903] call strlen
    // [2121] phi from strcat to strlen [phi:strcat->strlen]
    // [2121] phi strlen::str#8 = chip_rom::rom [phi:strcat->strlen#0] -- pbuz1=pbuc1 
    lda #<chip_rom.rom
    sta.z strlen.str
    lda #>chip_rom.rom
    sta.z strlen.str+1
    jsr strlen
    // strlen(destination)
    // [1904] strlen::return#0 = strlen::len#2
    // strcat::@4
    // [1905] strcat::$0 = strlen::return#0
    // char* dst = destination + strlen(destination)
    // [1906] strcat::dst#0 = chip_rom::rom + strcat::$0 -- pbuz1=pbuc1_plus_vwuz1 
    lda.z dst
    clc
    adc #<chip_rom.rom
    sta.z dst
    lda.z dst+1
    adc #>chip_rom.rom
    sta.z dst+1
    // [1907] phi from strcat::@2 strcat::@4 to strcat::@1 [phi:strcat::@2/strcat::@4->strcat::@1]
    // [1907] phi strcat::dst#2 = strcat::dst#1 [phi:strcat::@2/strcat::@4->strcat::@1#0] -- register_copy 
    // [1907] phi strcat::src#2 = strcat::src#1 [phi:strcat::@2/strcat::@4->strcat::@1#1] -- register_copy 
    // strcat::@1
  __b1:
    // while(*src)
    // [1908] if(0!=*strcat::src#2) goto strcat::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcat::@3
    // *dst = 0
    // [1909] *strcat::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcat::@return
    // }
    // [1910] return 
    rts
    // strcat::@2
  __b2:
    // *dst++ = *src++
    // [1911] *strcat::dst#2 = *strcat::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [1912] strcat::dst#1 = ++ strcat::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [1913] strcat::src#1 = ++ strcat::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    jmp __b1
}
  // print_rom_led
// void print_rom_led(__zp($62) char chip, __zp($53) char c)
print_rom_led: {
    .label print_rom_led__0 = $65
    .label chip = $62
    .label c = $53
    .label print_rom_led__7 = $65
    .label print_rom_led__8 = $65
    // chip*6
    // [1915] print_rom_led::$7 = print_rom_led::chip#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z chip
    asl
    sta.z print_rom_led__7
    // [1916] print_rom_led::$8 = print_rom_led::$7 + print_rom_led::chip#2 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z print_rom_led__8
    clc
    adc.z chip
    sta.z print_rom_led__8
    // CHIP_ROM_X+chip*6
    // [1917] print_rom_led::$0 = print_rom_led::$8 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z print_rom_led__0
    // print_chip_led(CHIP_ROM_X+chip*6+1, CHIP_ROM_Y, CHIP_ROM_W, c, BLUE)
    // [1918] print_chip_led::x#3 = print_rom_led::$0 + $14+1 -- vbuz1=vbuz1_plus_vbuc1 
    lda #$14+1
    clc
    adc.z print_chip_led.x
    sta.z print_chip_led.x
    // [1919] print_chip_led::tc#2 = print_rom_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z print_chip_led.tc
    // [1920] call print_chip_led
    // [2294] phi from print_rom_led to print_chip_led [phi:print_rom_led->print_chip_led]
    // [2294] phi print_chip_led::w#7 = 3 [phi:print_rom_led->print_chip_led#0] -- vbuz1=vbuc1 
    lda #3
    sta.z print_chip_led.w
    // [2294] phi print_chip_led::x#7 = print_chip_led::x#3 [phi:print_rom_led->print_chip_led#1] -- register_copy 
    // [2294] phi print_chip_led::tc#3 = print_chip_led::tc#2 [phi:print_rom_led->print_chip_led#2] -- register_copy 
    jsr print_chip_led
    // print_rom_led::@1
    // print_info_led(INFO_X-2, INFO_Y+chip+2, c, BLUE)
    // [1921] print_info_led::y#2 = print_rom_led::chip#2 + $11+2 -- vbuz1=vbuz2_plus_vbuc1 
    lda #$11+2
    clc
    adc.z chip
    sta.z print_info_led.y
    // [1922] print_info_led::tc#2 = print_rom_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z print_info_led.tc
    // [1923] call print_info_led
    // [1508] phi from print_rom_led::@1 to print_info_led [phi:print_rom_led::@1->print_info_led]
    // [1508] phi print_info_led::y#4 = print_info_led::y#2 [phi:print_rom_led::@1->print_info_led#0] -- register_copy 
    // [1508] phi print_info_led::x#4 = 4-2 [phi:print_rom_led::@1->print_info_led#1] -- vbuz1=vbuc1 
    lda #4-2
    sta.z print_info_led.x
    // [1508] phi print_info_led::tc#4 = print_info_led::tc#2 [phi:print_rom_led::@1->print_info_led#2] -- register_copy 
    jsr print_info_led
    // print_rom_led::@return
    // }
    // [1924] return 
    rts
}
  // cbm_k_getin
/**
 * @brief Scan a character from keyboard without pressing enter.
 * 
 * @return char The character read.
 */
cbm_k_getin: {
    .label return = $e7
    // __mem unsigned char ch
    // [1925] cbm_k_getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // asm
    // asm { jsrCBM_GETIN stach  }
    jsr CBM_GETIN
    sta ch
    // return ch;
    // [1927] cbm_k_getin::return#0 = cbm_k_getin::ch -- vbuz1=vbum2 
    sta.z return
    // cbm_k_getin::@return
    // }
    // [1928] cbm_k_getin::return#1 = cbm_k_getin::return#0
    // [1929] return 
    rts
  .segment Data
    ch: .byte 0
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
// __zp($3d) struct $2 * fopen(__zp($d1) const char *path, const char *mode)
fopen: {
    .label fopen__4 = $ea
    .label fopen__9 = $6d
    .label fopen__15 = $35
    .label fopen__26 = $51
    .label fopen__30 = $3d
    .label cbm_k_setnam1_fopen__0 = $55
    .label sp = $53
    .label stream = $3d
    .label pathtoken = $d1
    .label pathpos = $cc
    .label pathpos_1 = $54
    .label pathcmp = $5c
    .label path = $d1
    // Parse path
    .label pathstep = $5b
    .label num = $f7
    .label cbm_k_readst1_return = $35
    .label return = $3d
    // unsigned char sp = __stdio_filecount
    // [1931] fopen::sp#0 = __stdio_filecount -- vbuz1=vbum2 
    lda __stdio_filecount
    sta.z sp
    // (unsigned int)sp | 0x8000
    // [1932] fopen::$30 = (unsigned int)fopen::sp#0 -- vwuz1=_word_vbuz2 
    sta.z fopen__30
    lda #0
    sta.z fopen__30+1
    // [1933] fopen::stream#0 = fopen::$30 | $8000 -- vwuz1=vwuz1_bor_vwuc1 
    lda.z stream
    ora #<$8000
    sta.z stream
    lda.z stream+1
    ora #>$8000
    sta.z stream+1
    // char pathpos = sp * __STDIO_FILECOUNT
    // [1934] fopen::pathpos#0 = fopen::sp#0 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z sp
    asl
    sta.z pathpos
    // __logical = 0
    // [1935] ((char *)&__stdio_file+$40)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    ldy.z sp
    sta __stdio_file+$40,y
    // __device = 0
    // [1936] ((char *)&__stdio_file+$42)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [1937] ((char *)&__stdio_file+$44)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$44,y
    // [1938] fopen::pathtoken#22 = fopen::pathtoken#0 -- pbum1=pbuz2 
    lda.z pathtoken
    sta pathtoken_1
    lda.z pathtoken+1
    sta pathtoken_1+1
    // [1939] fopen::pathpos#21 = fopen::pathpos#0 -- vbuz1=vbuz2 
    lda.z pathpos
    sta.z pathpos_1
    // [1940] phi from fopen to fopen::@8 [phi:fopen->fopen::@8]
    // [1940] phi fopen::num#10 = 0 [phi:fopen->fopen::@8#0] -- vbuz1=vbuc1 
    lda #0
    sta.z num
    // [1940] phi fopen::pathpos#10 = fopen::pathpos#21 [phi:fopen->fopen::@8#1] -- register_copy 
    // [1940] phi fopen::path#10 = fopen::pathtoken#0 [phi:fopen->fopen::@8#2] -- register_copy 
    // [1940] phi fopen::pathstep#10 = 0 [phi:fopen->fopen::@8#3] -- vbuz1=vbuc1 
    sta.z pathstep
    // [1940] phi fopen::pathtoken#10 = fopen::pathtoken#22 [phi:fopen->fopen::@8#4] -- register_copy 
  // Iterate while path is not \0.
    // [1940] phi from fopen::@22 to fopen::@8 [phi:fopen::@22->fopen::@8]
    // [1940] phi fopen::num#10 = fopen::num#13 [phi:fopen::@22->fopen::@8#0] -- register_copy 
    // [1940] phi fopen::pathpos#10 = fopen::pathpos#7 [phi:fopen::@22->fopen::@8#1] -- register_copy 
    // [1940] phi fopen::path#10 = fopen::path#11 [phi:fopen::@22->fopen::@8#2] -- register_copy 
    // [1940] phi fopen::pathstep#10 = fopen::pathstep#11 [phi:fopen::@22->fopen::@8#3] -- register_copy 
    // [1940] phi fopen::pathtoken#10 = fopen::pathtoken#1 [phi:fopen::@22->fopen::@8#4] -- register_copy 
    // fopen::@8
  __b8:
    // if (*pathtoken == ',' || *pathtoken == '\0')
    // [1941] if(*fopen::pathtoken#10==',') goto fopen::@9 -- _deref_pbum1_eq_vbuc1_then_la1 
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
    // [1942] if(*fopen::pathtoken#10=='@') goto fopen::@9 -- _deref_pbum1_eq_vbuc1_then_la1 
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
    // [1943] if(fopen::pathstep#10!=0) goto fopen::@10 -- vbuz1_neq_0_then_la1 
    lda.z pathstep
    bne __b10
    // fopen::@24
    // __stdio_file.filename[pathpos] = *pathtoken
    // [1944] ((char *)&__stdio_file)[fopen::pathpos#10] = *fopen::pathtoken#10 -- pbuc1_derefidx_vbuz1=_deref_pbum2 
    ldy pathtoken_1
    sty.z $fe
    ldy pathtoken_1+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    ldy.z pathpos_1
    sta __stdio_file,y
    // pathpos++;
    // [1945] fopen::pathpos#1 = ++ fopen::pathpos#10 -- vbuz1=_inc_vbuz1 
    inc.z pathpos_1
    // [1946] phi from fopen::@12 fopen::@23 fopen::@24 to fopen::@10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10]
    // [1946] phi fopen::num#13 = fopen::num#15 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#0] -- register_copy 
    // [1946] phi fopen::pathpos#7 = fopen::pathpos#10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#1] -- register_copy 
    // [1946] phi fopen::path#11 = fopen::path#13 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#2] -- register_copy 
    // [1946] phi fopen::pathstep#11 = fopen::pathstep#1 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#3] -- register_copy 
    // fopen::@10
  __b10:
    // pathtoken++;
    // [1947] fopen::pathtoken#1 = ++ fopen::pathtoken#10 -- pbum1=_inc_pbum1 
    inc pathtoken_1
    bne !+
    inc pathtoken_1+1
  !:
    // fopen::@22
    // pathtoken - 1
    // [1948] fopen::$28 = fopen::pathtoken#1 - 1 -- pbum1=pbum2_minus_1 
    lda pathtoken_1
    sec
    sbc #1
    sta fopen__28
    lda pathtoken_1+1
    sbc #0
    sta fopen__28+1
    // while (*(pathtoken - 1))
    // [1949] if(0!=*fopen::$28) goto fopen::@8 -- 0_neq__deref_pbum1_then_la1 
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
    // [1950] ((char *)&__stdio_file+$46)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    tya
    ldy.z sp
    sta __stdio_file+$46,y
    // if(!__logical)
    // [1951] if(0!=((char *)&__stdio_file+$40)[fopen::sp#0]) goto fopen::@1 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$40,y
    cmp #0
    bne __b1
    // fopen::@27
    // __stdio_filecount+1
    // [1952] fopen::$4 = __stdio_filecount + 1 -- vbuz1=vbum2_plus_1 
    lda __stdio_filecount
    inc
    sta.z fopen__4
    // __logical = __stdio_filecount+1
    // [1953] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::$4 -- pbuc1_derefidx_vbuz1=vbuz2 
    sta __stdio_file+$40,y
    // fopen::@1
  __b1:
    // if(!__device)
    // [1954] if(0!=((char *)&__stdio_file+$42)[fopen::sp#0]) goto fopen::@2 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    ldy.z sp
    lda __stdio_file+$42,y
    cmp #0
    bne __b2
    // fopen::@5
    // __device = 8
    // [1955] ((char *)&__stdio_file+$42)[fopen::sp#0] = 8 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #8
    sta __stdio_file+$42,y
    // fopen::@2
  __b2:
    // if(!__channel)
    // [1956] if(0!=((char *)&__stdio_file+$44)[fopen::sp#0]) goto fopen::@3 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    ldy.z sp
    lda __stdio_file+$44,y
    cmp #0
    bne __b3
    // fopen::@6
    // __stdio_filecount+2
    // [1957] fopen::$9 = __stdio_filecount + 2 -- vbuz1=vbum2_plus_2 
    lda __stdio_filecount
    clc
    adc #2
    sta.z fopen__9
    // __channel = __stdio_filecount+2
    // [1958] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::$9 -- pbuc1_derefidx_vbuz1=vbuz2 
    sta __stdio_file+$44,y
    // fopen::@3
  __b3:
    // __filename
    // [1959] fopen::$11 = (char *)&__stdio_file + fopen::pathpos#0 -- pbum1=pbuc1_plus_vbuz2 
    lda.z pathpos
    clc
    adc #<__stdio_file
    sta fopen__11
    lda #>__stdio_file
    adc #0
    sta fopen__11+1
    // cbm_k_setnam(__filename)
    // [1960] fopen::cbm_k_setnam1_filename = fopen::$11 -- pbum1=pbum2 
    lda fopen__11
    sta cbm_k_setnam1_filename
    lda fopen__11+1
    sta cbm_k_setnam1_filename+1
    // fopen::cbm_k_setnam1
    // strlen(filename)
    // [1961] strlen::str#4 = fopen::cbm_k_setnam1_filename -- pbuz1=pbum2 
    lda cbm_k_setnam1_filename
    sta.z strlen.str
    lda cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [1962] call strlen
    // [2121] phi from fopen::cbm_k_setnam1 to strlen [phi:fopen::cbm_k_setnam1->strlen]
    // [2121] phi strlen::str#8 = strlen::str#4 [phi:fopen::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [1963] strlen::return#11 = strlen::len#2
    // fopen::@31
    // [1964] fopen::cbm_k_setnam1_$0 = strlen::return#11
    // char filename_len = (char)strlen(filename)
    // [1965] fopen::cbm_k_setnam1_filename_len = (char)fopen::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
    lda.z cbm_k_setnam1_fopen__0
    sta cbm_k_setnam1_filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx cbm_k_setnam1_filename
    ldy cbm_k_setnam1_filename+1
    jsr CBM_SETNAM
    // fopen::@28
    // cbm_k_setlfs(__logical, __device, __channel)
    // [1967] cbm_k_setlfs::channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$40,y
    sta cbm_k_setlfs.channel
    // [1968] cbm_k_setlfs::device = ((char *)&__stdio_file+$42)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    lda __stdio_file+$42,y
    sta cbm_k_setlfs.device
    // [1969] cbm_k_setlfs::command = ((char *)&__stdio_file+$44)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    lda __stdio_file+$44,y
    sta cbm_k_setlfs.command
    // [1970] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // fopen::cbm_k_open1
    // asm
    // asm { jsrCBM_OPEN  }
    jsr CBM_OPEN
    // fopen::cbm_k_readst1
    // char status
    // [1972] fopen::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [1974] fopen::cbm_k_readst1_return#0 = fopen::cbm_k_readst1_status -- vbuz1=vbum2 
    sta.z cbm_k_readst1_return
    // fopen::cbm_k_readst1_@return
    // }
    // [1975] fopen::cbm_k_readst1_return#1 = fopen::cbm_k_readst1_return#0
    // fopen::@29
    // cbm_k_readst()
    // [1976] fopen::$15 = fopen::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [1977] ((char *)&__stdio_file+$46)[fopen::sp#0] = fopen::$15 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fopen__15
    ldy.z sp
    sta __stdio_file+$46,y
    // ferror(stream)
    // [1978] ferror::stream#0 = (struct $2 *)fopen::stream#0
    // [1979] call ferror
    jsr ferror
    // [1980] ferror::return#0 = ferror::return#1
    // fopen::@32
    // [1981] fopen::$16 = ferror::return#0
    // if (ferror(stream))
    // [1982] if(0==fopen::$16) goto fopen::@4 -- 0_eq_vwsm1_then_la1 
    lda fopen__16
    ora fopen__16+1
    beq __b4
    // fopen::@7
    // cbm_k_close(__logical)
    // [1983] fopen::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$40,y
    sta cbm_k_close1_channel
    // fopen::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // [1985] phi from fopen::cbm_k_close1 to fopen::@return [phi:fopen::cbm_k_close1->fopen::@return]
    // [1985] phi fopen::return#2 = 0 [phi:fopen::cbm_k_close1->fopen::@return#0] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fopen::@return
    // }
    // [1986] return 
    rts
    // fopen::@4
  __b4:
    // __stdio_filecount++;
    // [1987] __stdio_filecount = ++ __stdio_filecount -- vbum1=_inc_vbum1 
    inc __stdio_filecount
    // [1988] fopen::return#8 = (struct $2 *)fopen::stream#0
    // [1985] phi from fopen::@4 to fopen::@return [phi:fopen::@4->fopen::@return]
    // [1985] phi fopen::return#2 = fopen::return#8 [phi:fopen::@4->fopen::@return#0] -- register_copy 
    rts
    // fopen::@9
  __b9:
    // if (pathstep > 0)
    // [1989] if(fopen::pathstep#10>0) goto fopen::@11 -- vbuz1_gt_0_then_la1 
    lda.z pathstep
    bne __b11
    // fopen::@25
    // __stdio_file.filename[pathpos] = '\0'
    // [1990] ((char *)&__stdio_file)[fopen::pathpos#10] = '@' -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #'@'
    ldy.z pathpos_1
    sta __stdio_file,y
    // path = pathtoken + 1
    // [1991] fopen::path#0 = fopen::pathtoken#10 + 1 -- pbuz1=pbum2_plus_1 
    clc
    lda pathtoken_1
    adc #1
    sta.z path
    lda pathtoken_1+1
    adc #0
    sta.z path+1
    // [1992] phi from fopen::@16 fopen::@17 fopen::@18 fopen::@19 fopen::@25 to fopen::@12 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12]
    // [1992] phi fopen::num#15 = fopen::num#2 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#0] -- register_copy 
    // [1992] phi fopen::path#13 = fopen::path#16 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#1] -- register_copy 
    // fopen::@12
  __b12:
    // pathstep++;
    // [1993] fopen::pathstep#1 = ++ fopen::pathstep#10 -- vbuz1=_inc_vbuz1 
    inc.z pathstep
    jmp __b10
    // fopen::@11
  __b11:
    // char pathcmp = *path
    // [1994] fopen::pathcmp#0 = *fopen::path#10 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (path),y
    sta.z pathcmp
    // case 'D':
    // [1995] if(fopen::pathcmp#0=='D') goto fopen::@13 -- vbuz1_eq_vbuc1_then_la1 
    lda #'D'
    cmp.z pathcmp
    beq __b13
    // fopen::@20
    // case 'L':
    // [1996] if(fopen::pathcmp#0=='L') goto fopen::@13 -- vbuz1_eq_vbuc1_then_la1 
    lda #'L'
    cmp.z pathcmp
    beq __b13
    // fopen::@21
    // case 'C':
    //                     num = (char)atoi(path + 1);
    //                     path = pathtoken + 1;
    // [1997] if(fopen::pathcmp#0=='C') goto fopen::@13 -- vbuz1_eq_vbuc1_then_la1 
    lda #'C'
    cmp.z pathcmp
    beq __b13
    // [1998] phi from fopen::@21 fopen::@30 to fopen::@14 [phi:fopen::@21/fopen::@30->fopen::@14]
    // [1998] phi fopen::path#16 = fopen::path#10 [phi:fopen::@21/fopen::@30->fopen::@14#0] -- register_copy 
    // [1998] phi fopen::num#2 = fopen::num#10 [phi:fopen::@21/fopen::@30->fopen::@14#1] -- register_copy 
    // fopen::@14
  __b14:
    // case 'L':
    //                     __logical = num;
    //                     break;
    // [1999] if(fopen::pathcmp#0=='L') goto fopen::@17 -- vbuz1_eq_vbuc1_then_la1 
    lda #'L'
    cmp.z pathcmp
    beq __b17
    // fopen::@15
    // case 'D':
    //                     __device = num;
    //                     break;
    // [2000] if(fopen::pathcmp#0=='D') goto fopen::@18 -- vbuz1_eq_vbuc1_then_la1 
    lda #'D'
    cmp.z pathcmp
    beq __b18
    // fopen::@16
    // case 'C':
    //                     __channel = num;
    //                     break;
    // [2001] if(fopen::pathcmp#0!='C') goto fopen::@12 -- vbuz1_neq_vbuc1_then_la1 
    lda #'C'
    cmp.z pathcmp
    bne __b12
    // fopen::@19
    // __channel = num
    // [2002] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z num
    ldy.z sp
    sta __stdio_file+$44,y
    jmp __b12
    // fopen::@18
  __b18:
    // __device = num
    // [2003] ((char *)&__stdio_file+$42)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z num
    ldy.z sp
    sta __stdio_file+$42,y
    jmp __b12
    // fopen::@17
  __b17:
    // __logical = num
    // [2004] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z num
    ldy.z sp
    sta __stdio_file+$40,y
    jmp __b12
    // fopen::@13
  __b13:
    // atoi(path + 1)
    // [2005] atoi::str#0 = fopen::path#10 + 1 -- pbuz1=pbuz1_plus_1 
    inc.z atoi.str
    bne !+
    inc.z atoi.str+1
  !:
    // [2006] call atoi
    // [2446] phi from fopen::@13 to atoi [phi:fopen::@13->atoi]
    // [2446] phi atoi::str#2 = atoi::str#0 [phi:fopen::@13->atoi#0] -- register_copy 
    jsr atoi
    // atoi(path + 1)
    // [2007] atoi::return#3 = atoi::return#2
    // fopen::@30
    // [2008] fopen::$26 = atoi::return#3
    // num = (char)atoi(path + 1)
    // [2009] fopen::num#1 = (char)fopen::$26 -- vbuz1=_byte_vwsz2 
    lda.z fopen__26
    sta.z num
    // path = pathtoken + 1
    // [2010] fopen::path#1 = fopen::pathtoken#10 + 1 -- pbuz1=pbum2_plus_1 
    clc
    lda pathtoken_1
    adc #1
    sta.z path
    lda pathtoken_1+1
    adc #0
    sta.z path+1
    jmp __b14
  .segment Data
    fopen__11: .word 0
    .label fopen__16 = ferror.return
    fopen__28: .word 0
    cbm_k_setnam1_filename: .word 0
    cbm_k_setnam1_filename_len: .byte 0
    cbm_k_readst1_status: .byte 0
    cbm_k_close1_channel: .byte 0
    pathtoken_1: .word 0
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
// __zp($ae) unsigned int fgets(__zp($bd) char *ptr, __zp($cd) unsigned int size, __mem() struct $2 *stream)
fgets: {
    .label fgets__1 = $ea
    .label fgets__8 = $6d
    .label fgets__9 = $35
    .label fgets__13 = $5c
    .label cbm_k_chkin1_channel = $fa
    .label cbm_k_chkin1_status = $f3
    .label cbm_k_readst1_status = $f4
    .label cbm_k_readst2_status = $c0
    .label sp = $cc
    .label cbm_k_readst1_return = $ea
    .label return = $ae
    .label bytes = $2d
    .label cbm_k_readst2_return = $6d
    .label read = $ae
    .label ptr = $bd
    .label remaining = $c7
    .label size = $cd
    // unsigned char sp = (unsigned char)stream
    // [2012] fgets::sp#0 = (char)fgets::stream#2 -- vbuz1=_byte_pssm2 
    lda stream
    sta.z sp
    // cbm_k_chkin(__logical)
    // [2013] fgets::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fgets::sp#0] -- vbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda __stdio_file+$40,y
    sta.z cbm_k_chkin1_channel
    // fgets::cbm_k_chkin1
    // char status
    // [2014] fgets::cbm_k_chkin1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fgets::cbm_k_readst1
    // char status
    // [2016] fgets::cbm_k_readst1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2018] fgets::cbm_k_readst1_return#0 = fgets::cbm_k_readst1_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst1_return
    // fgets::cbm_k_readst1_@return
    // }
    // [2019] fgets::cbm_k_readst1_return#1 = fgets::cbm_k_readst1_return#0
    // fgets::@11
    // cbm_k_readst()
    // [2020] fgets::$1 = fgets::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [2021] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$1 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fgets__1
    ldy.z sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2022] if(0==((char *)&__stdio_file+$46)[fgets::sp#0]) goto fgets::@1 -- 0_eq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b1
    // [2023] phi from fgets::@11 fgets::@12 fgets::@5 to fgets::@return [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return]
  __b8:
    // [2023] phi fgets::return#1 = 0 [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return#0] -- vwuz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fgets::@return
    // }
    // [2024] return 
    rts
    // fgets::@1
  __b1:
    // [2025] fgets::remaining#22 = fgets::size#10 -- vwuz1=vwuz2 
    lda.z size
    sta.z remaining
    lda.z size+1
    sta.z remaining+1
    // [2026] phi from fgets::@1 to fgets::@2 [phi:fgets::@1->fgets::@2]
    // [2026] phi fgets::read#10 = 0 [phi:fgets::@1->fgets::@2#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z read
    sta.z read+1
    // [2026] phi fgets::remaining#11 = fgets::remaining#22 [phi:fgets::@1->fgets::@2#1] -- register_copy 
    // [2026] phi fgets::ptr#10 = fgets::ptr#12 [phi:fgets::@1->fgets::@2#2] -- register_copy 
    // [2026] phi from fgets::@17 fgets::@18 to fgets::@2 [phi:fgets::@17/fgets::@18->fgets::@2]
    // [2026] phi fgets::read#10 = fgets::read#1 [phi:fgets::@17/fgets::@18->fgets::@2#0] -- register_copy 
    // [2026] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@17/fgets::@18->fgets::@2#1] -- register_copy 
    // [2026] phi fgets::ptr#10 = fgets::ptr#13 [phi:fgets::@17/fgets::@18->fgets::@2#2] -- register_copy 
    // fgets::@2
  __b2:
    // if (!size)
    // [2027] if(0==fgets::size#10) goto fgets::@3 -- 0_eq_vwuz1_then_la1 
    lda.z size
    ora.z size+1
    bne !__b3+
    jmp __b3
  !__b3:
    // fgets::@8
    // if (remaining >= 512)
    // [2028] if(fgets::remaining#11>=$200) goto fgets::@4 -- vwuz1_ge_vwuc1_then_la1 
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
    // [2029] cx16_k_macptr::bytes = fgets::remaining#11 -- vbuz1=vwuz2 
    lda.z remaining
    sta.z cx16_k_macptr.bytes
    // [2030] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2031] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2032] cx16_k_macptr::return#4 = cx16_k_macptr::return#1
    // fgets::@15
  __b15:
    // bytes = cx16_k_macptr(remaining, ptr)
    // [2033] fgets::bytes#3 = cx16_k_macptr::return#4
    // [2034] phi from fgets::@13 fgets::@14 fgets::@15 to fgets::cbm_k_readst2 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2]
    // [2034] phi fgets::bytes#10 = fgets::bytes#1 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2#0] -- register_copy 
    // fgets::cbm_k_readst2
    // char status
    // [2035] fgets::cbm_k_readst2_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [2037] fgets::cbm_k_readst2_return#0 = fgets::cbm_k_readst2_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst2_return
    // fgets::cbm_k_readst2_@return
    // }
    // [2038] fgets::cbm_k_readst2_return#1 = fgets::cbm_k_readst2_return#0
    // fgets::@12
    // cbm_k_readst()
    // [2039] fgets::$8 = fgets::cbm_k_readst2_return#1
    // __status = cbm_k_readst()
    // [2040] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$8 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fgets__8
    ldy.z sp
    sta __stdio_file+$46,y
    // __status & 0xBF
    // [2041] fgets::$9 = ((char *)&__stdio_file+$46)[fgets::sp#0] & $bf -- vbuz1=pbuc1_derefidx_vbuz2_band_vbuc2 
    lda #$bf
    and __stdio_file+$46,y
    sta.z fgets__9
    // if (__status & 0xBF)
    // [2042] if(0==fgets::$9) goto fgets::@5 -- 0_eq_vbuz1_then_la1 
    beq __b5
    jmp __b8
    // fgets::@5
  __b5:
    // if (bytes == 0xFFFF)
    // [2043] if(fgets::bytes#10!=$ffff) goto fgets::@6 -- vwuz1_neq_vwuc1_then_la1 
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
    // [2044] fgets::read#1 = fgets::read#10 + fgets::bytes#10 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z read
    adc.z bytes
    sta.z read
    lda.z read+1
    adc.z bytes+1
    sta.z read+1
    // ptr += bytes
    // [2045] fgets::ptr#0 = fgets::ptr#10 + fgets::bytes#10 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z ptr
    adc.z bytes
    sta.z ptr
    lda.z ptr+1
    adc.z bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [2046] fgets::$13 = byte1  fgets::ptr#0 -- vbuz1=_byte1_pbuz2 
    sta.z fgets__13
    // if (BYTE1(ptr) == 0xC0)
    // [2047] if(fgets::$13!=$c0) goto fgets::@7 -- vbuz1_neq_vbuc1_then_la1 
    lda #$c0
    cmp.z fgets__13
    bne __b7
    // fgets::@10
    // ptr -= 0x2000
    // [2048] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [2049] phi from fgets::@10 fgets::@6 to fgets::@7 [phi:fgets::@10/fgets::@6->fgets::@7]
    // [2049] phi fgets::ptr#13 = fgets::ptr#1 [phi:fgets::@10/fgets::@6->fgets::@7#0] -- register_copy 
    // fgets::@7
  __b7:
    // remaining -= bytes
    // [2050] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#10 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z remaining
    sec
    sbc.z bytes
    sta.z remaining
    lda.z remaining+1
    sbc.z bytes+1
    sta.z remaining+1
    // while ((__status == 0) && ((size && remaining) || !size))
    // [2051] if(((char *)&__stdio_file+$46)[fgets::sp#0]==0) goto fgets::@16 -- pbuc1_derefidx_vbuz1_eq_0_then_la1 
    ldy.z sp
    lda __stdio_file+$46,y
    cmp #0
    beq __b16
    // [2023] phi from fgets::@17 fgets::@7 to fgets::@return [phi:fgets::@17/fgets::@7->fgets::@return]
    // [2023] phi fgets::return#1 = fgets::read#1 [phi:fgets::@17/fgets::@7->fgets::@return#0] -- register_copy 
    rts
    // fgets::@16
  __b16:
    // while ((__status == 0) && ((size && remaining) || !size))
    // [2052] if(0==fgets::size#10) goto fgets::@17 -- 0_eq_vwuz1_then_la1 
    lda.z size
    ora.z size+1
    beq __b17
    // fgets::@18
    // [2053] if(0!=fgets::remaining#1) goto fgets::@2 -- 0_neq_vwuz1_then_la1 
    lda.z remaining
    ora.z remaining+1
    beq !__b2+
    jmp __b2
  !__b2:
    // fgets::@17
  __b17:
    // [2054] if(0==fgets::size#10) goto fgets::@2 -- 0_eq_vwuz1_then_la1 
    lda.z size
    ora.z size+1
    bne !__b2+
    jmp __b2
  !__b2:
    rts
    // fgets::@4
  __b4:
    // cx16_k_macptr(512, ptr)
    // [2055] cx16_k_macptr::bytes = $200 -- vbuz1=vwuc1 
    lda #<$200
    sta.z cx16_k_macptr.bytes
    // [2056] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2057] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2058] cx16_k_macptr::return#3 = cx16_k_macptr::return#1
    // fgets::@14
    // bytes = cx16_k_macptr(512, ptr)
    // [2059] fgets::bytes#2 = cx16_k_macptr::return#3
    jmp __b15
    // fgets::@3
  __b3:
    // cx16_k_macptr(0, ptr)
    // [2060] cx16_k_macptr::bytes = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cx16_k_macptr.bytes
    // [2061] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2062] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2063] cx16_k_macptr::return#2 = cx16_k_macptr::return#1
    // fgets::@13
    // bytes = cx16_k_macptr(0, ptr)
    // [2064] fgets::bytes#1 = cx16_k_macptr::return#2
    jmp __b15
  .segment Data
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
// int fclose(__zp($ba) struct $2 *stream)
fclose: {
    .label fclose__1 = $45
    .label fclose__4 = $e4
    .label fclose__6 = $67
    .label sp = $67
    .label cbm_k_readst1_return = $45
    .label cbm_k_readst2_return = $e4
    .label stream = $ba
    // unsigned char sp = (unsigned char)stream
    // [2066] fclose::sp#0 = (char)fclose::stream#2 -- vbuz1=_byte_pssz2 
    lda.z stream
    sta.z sp
    // cbm_k_chkin(__logical)
    // [2067] fclose::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    tay
    lda __stdio_file+$40,y
    sta cbm_k_chkin1_channel
    // fclose::cbm_k_chkin1
    // char status
    // [2068] fclose::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fclose::cbm_k_readst1
    // char status
    // [2070] fclose::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2072] fclose::cbm_k_readst1_return#0 = fclose::cbm_k_readst1_status -- vbuz1=vbum2 
    sta.z cbm_k_readst1_return
    // fclose::cbm_k_readst1_@return
    // }
    // [2073] fclose::cbm_k_readst1_return#1 = fclose::cbm_k_readst1_return#0
    // fclose::@3
    // cbm_k_readst()
    // [2074] fclose::$1 = fclose::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [2075] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$1 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fclose__1
    ldy.z sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2076] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@1 -- 0_eq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b1
    // fclose::@return
    // }
    // [2077] return 
    rts
    // fclose::@1
  __b1:
    // cbm_k_close(__logical)
    // [2078] fclose::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$40,y
    sta cbm_k_close1_channel
    // fclose::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // fclose::cbm_k_readst2
    // char status
    // [2080] fclose::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [2082] fclose::cbm_k_readst2_return#0 = fclose::cbm_k_readst2_status -- vbuz1=vbum2 
    sta.z cbm_k_readst2_return
    // fclose::cbm_k_readst2_@return
    // }
    // [2083] fclose::cbm_k_readst2_return#1 = fclose::cbm_k_readst2_return#0
    // fclose::@4
    // cbm_k_readst()
    // [2084] fclose::$4 = fclose::cbm_k_readst2_return#1
    // __status = cbm_k_readst()
    // [2085] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$4 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fclose__4
    ldy.z sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2086] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@2 -- 0_eq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b2
    rts
    // fclose::@2
  __b2:
    // __logical = 0
    // [2087] ((char *)&__stdio_file+$40)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    ldy.z sp
    sta __stdio_file+$40,y
    // __device = 0
    // [2088] ((char *)&__stdio_file+$42)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [2089] ((char *)&__stdio_file+$44)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$44,y
    // __filename
    // [2090] fclose::$6 = fclose::sp#0 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z fclose__6
    // *__filename = '\0'
    // [2091] ((char *)&__stdio_file)[fclose::$6] = '@' -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #'@'
    ldy.z fclose__6
    sta __stdio_file,y
    // __stdio_filecount--;
    // [2092] __stdio_filecount = -- __stdio_filecount -- vbum1=_dec_vbum1 
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
  // uctoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void uctoa(__zp($2f) char value, __zp($3d) char *buffer, __zp($e0) char radix)
uctoa: {
    .label uctoa__4 = $67
    .label digit_value = $45
    .label buffer = $3d
    .label digit = $64
    .label value = $2f
    .label radix = $e0
    .label started = $6c
    .label max_digits = $b6
    .label digit_values = $55
    // if(radix==DECIMAL)
    // [2093] if(uctoa::radix#0==DECIMAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp.z radix
    beq __b2
    // uctoa::@2
    // if(radix==HEXADECIMAL)
    // [2094] if(uctoa::radix#0==HEXADECIMAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp.z radix
    beq __b3
    // uctoa::@3
    // if(radix==OCTAL)
    // [2095] if(uctoa::radix#0==OCTAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp.z radix
    beq __b4
    // uctoa::@4
    // if(radix==BINARY)
    // [2096] if(uctoa::radix#0==BINARY) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp.z radix
    beq __b5
    // uctoa::@5
    // *buffer++ = 'e'
    // [2097] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2098] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2099] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2100] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // uctoa::@return
    // }
    // [2101] return 
    rts
    // [2102] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
  __b2:
    // [2102] phi uctoa::digit_values#8 = RADIX_DECIMAL_VALUES_CHAR [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [2102] phi uctoa::max_digits#7 = 3 [phi:uctoa->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [2102] phi from uctoa::@2 to uctoa::@1 [phi:uctoa::@2->uctoa::@1]
  __b3:
    // [2102] phi uctoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_CHAR [phi:uctoa::@2->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [2102] phi uctoa::max_digits#7 = 2 [phi:uctoa::@2->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #2
    sta.z max_digits
    jmp __b1
    // [2102] phi from uctoa::@3 to uctoa::@1 [phi:uctoa::@3->uctoa::@1]
  __b4:
    // [2102] phi uctoa::digit_values#8 = RADIX_OCTAL_VALUES_CHAR [phi:uctoa::@3->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values+1
    // [2102] phi uctoa::max_digits#7 = 3 [phi:uctoa::@3->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [2102] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
  __b5:
    // [2102] phi uctoa::digit_values#8 = RADIX_BINARY_VALUES_CHAR [phi:uctoa::@4->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_BINARY_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_CHAR
    sta.z digit_values+1
    // [2102] phi uctoa::max_digits#7 = 8 [phi:uctoa::@4->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #8
    sta.z max_digits
    // uctoa::@1
  __b1:
    // [2103] phi from uctoa::@1 to uctoa::@6 [phi:uctoa::@1->uctoa::@6]
    // [2103] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa::@1->uctoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2103] phi uctoa::started#2 = 0 [phi:uctoa::@1->uctoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [2103] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa::@1->uctoa::@6#2] -- register_copy 
    // [2103] phi uctoa::digit#2 = 0 [phi:uctoa::@1->uctoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // uctoa::@6
  __b6:
    // max_digits-1
    // [2104] uctoa::$4 = uctoa::max_digits#7 - 1 -- vbuz1=vbuz2_minus_1 
    ldx.z max_digits
    dex
    stx.z uctoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2105] if(uctoa::digit#2<uctoa::$4) goto uctoa::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z digit
    cmp.z uctoa__4
    bcc __b7
    // uctoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2106] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z value
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2107] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2108] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // uctoa::@7
  __b7:
    // unsigned char digit_value = digit_values[digit]
    // [2109] uctoa::digit_value#0 = uctoa::digit_values#8[uctoa::digit#2] -- vbuz1=pbuz2_derefidx_vbuz3 
    ldy.z digit
    lda (digit_values),y
    sta.z digit_value
    // if (started || value >= digit_value)
    // [2110] if(0!=uctoa::started#2) goto uctoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // uctoa::@12
    // [2111] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@10 -- vbuz1_ge_vbuz2_then_la1 
    lda.z value
    cmp.z digit_value
    bcs __b10
    // [2112] phi from uctoa::@12 to uctoa::@9 [phi:uctoa::@12->uctoa::@9]
    // [2112] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@12->uctoa::@9#0] -- register_copy 
    // [2112] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@12->uctoa::@9#1] -- register_copy 
    // [2112] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@12->uctoa::@9#2] -- register_copy 
    // uctoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2113] uctoa::digit#1 = ++ uctoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [2103] phi from uctoa::@9 to uctoa::@6 [phi:uctoa::@9->uctoa::@6]
    // [2103] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@9->uctoa::@6#0] -- register_copy 
    // [2103] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@9->uctoa::@6#1] -- register_copy 
    // [2103] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@9->uctoa::@6#2] -- register_copy 
    // [2103] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@9->uctoa::@6#3] -- register_copy 
    jmp __b6
    // uctoa::@10
  __b10:
    // uctoa_append(buffer++, value, digit_value)
    // [2114] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [2115] uctoa_append::value#0 = uctoa::value#2
    // [2116] uctoa_append::sub#0 = uctoa::digit_value#0
    // [2117] call uctoa_append
    // [2467] phi from uctoa::@10 to uctoa_append [phi:uctoa::@10->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [2118] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@11
    // value = uctoa_append(buffer++, value, digit_value)
    // [2119] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [2120] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2112] phi from uctoa::@11 to uctoa::@9 [phi:uctoa::@11->uctoa::@9]
    // [2112] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@11->uctoa::@9#0] -- register_copy 
    // [2112] phi uctoa::started#4 = 1 [phi:uctoa::@11->uctoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [2112] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@11->uctoa::@9#2] -- register_copy 
    jmp __b9
}
  // strlen
// Computes the length of the string str up to but not including the terminating null character.
// __zp($55) unsigned int strlen(__zp($51) char *str)
strlen: {
    .label return = $55
    .label len = $55
    .label str = $51
    // [2122] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [2122] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z len
    sta.z len+1
    // [2122] phi strlen::str#6 = strlen::str#8 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [2123] if(0!=*strlen::str#6) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [2124] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [2125] strlen::len#1 = ++ strlen::len#2 -- vwuz1=_inc_vwuz1 
    inc.z len
    bne !+
    inc.z len+1
  !:
    // str++;
    // [2126] strlen::str#1 = ++ strlen::str#6 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [2122] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [2122] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [2122] phi strlen::str#6 = strlen::str#1 [phi:strlen::@2->strlen::@1#1] -- register_copy 
    jmp __b1
}
  // printf_padding
// Print a padding char a number of times
// void printf_padding(__zp($51) void (*putc)(char), __zp($62) char pad, __zp($68) char length)
printf_padding: {
    .label i = $53
    .label putc = $51
    .label length = $68
    .label pad = $62
    // [2128] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [2128] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [2129] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z length
    bcc __b2
    // printf_padding::@return
    // }
    // [2130] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [2131] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbuz1 
    lda.z pad
    pha
    // [2132] callexecute *printf_padding::putc#7  -- call__deref_pprz1 
    jsr icall33
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [2134] printf_padding::i#1 = ++ printf_padding::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [2128] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [2128] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
    jmp __b1
    // Outside Flow
  icall33:
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
// __mem() unsigned long rom_address_from_bank(__zp($fb) char rom_bank)
rom_address_from_bank: {
    .label rom_address_from_bank__1 = $57
    .label return = $57
    .label rom_bank = $fb
    .label return_1 = $7c
    // ((unsigned long)(rom_bank)) << 14
    // [2136] rom_address_from_bank::$1 = (unsigned long)rom_address_from_bank::rom_bank#3 -- vduz1=_dword_vbuz2 
    lda.z rom_bank
    sta.z rom_address_from_bank__1
    lda #0
    sta.z rom_address_from_bank__1+1
    sta.z rom_address_from_bank__1+2
    sta.z rom_address_from_bank__1+3
    // [2137] rom_address_from_bank::return#0 = rom_address_from_bank::$1 << $e -- vduz1=vduz1_rol_vbuc1 
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
    // [2138] return 
    rts
  .segment Data
    .label return_2 = main.flashed_bytes
}
.segment Code
  // rom_compare
// __zp($51) unsigned int rom_compare(__zp($5d) char bank_ram, __zp($ae) char *ptr_ram, __zp($57) unsigned long rom_compare_address, __zp($ca) unsigned int rom_compare_size)
rom_compare: {
    .label rom_compare__5 = $7b
    .label rom_bank1_rom_compare__0 = $e4
    .label rom_bank1_rom_compare__1 = $69
    .label rom_bank1_rom_compare__2 = $6f
    .label rom_ptr1_rom_compare__0 = $75
    .label rom_ptr1_rom_compare__2 = $75
    .label bank_set_bram1_bank = $5d
    .label rom_bank1_bank_unshifted = $6f
    .label rom_bank1_return = $dc
    .label rom_ptr1_return = $75
    .label ptr_rom = $75
    .label ptr_ram = $ae
    .label compared_bytes = $a9
    /// Holds the amount of bytes actually verified between the ROM and the RAM.
    .label equal_bytes = $51
    .label bank_ram = $5d
    .label rom_compare_address = $57
    .label return = $51
    .label rom_compare_size = $ca
    // rom_compare::bank_set_bram1
    // BRAM = bank
    // [2140] BRAM = rom_compare::bank_set_bram1_bank#0 -- vbuz1=vbuz2 
    lda.z bank_set_bram1_bank
    sta.z BRAM
    // rom_compare::rom_bank1
    // BYTE2(address)
    // [2141] rom_compare::rom_bank1_$0 = byte2  rom_compare::rom_compare_address#3 -- vbuz1=_byte2_vduz2 
    lda.z rom_compare_address+2
    sta.z rom_bank1_rom_compare__0
    // BYTE1(address)
    // [2142] rom_compare::rom_bank1_$1 = byte1  rom_compare::rom_compare_address#3 -- vbuz1=_byte1_vduz2 
    lda.z rom_compare_address+1
    sta.z rom_bank1_rom_compare__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2143] rom_compare::rom_bank1_$2 = rom_compare::rom_bank1_$0 w= rom_compare::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_compare__0
    sta.z rom_bank1_rom_compare__2+1
    lda.z rom_bank1_rom_compare__1
    sta.z rom_bank1_rom_compare__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2144] rom_compare::rom_bank1_bank_unshifted#0 = rom_compare::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2145] rom_compare::rom_bank1_return#0 = byte1  rom_compare::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwuz2 
    lda.z rom_bank1_bank_unshifted+1
    sta.z rom_bank1_return
    // rom_compare::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2146] rom_compare::rom_ptr1_$2 = (unsigned int)rom_compare::rom_compare_address#3 -- vwuz1=_word_vduz2 
    lda.z rom_compare_address
    sta.z rom_ptr1_rom_compare__2
    lda.z rom_compare_address+1
    sta.z rom_ptr1_rom_compare__2+1
    // [2147] rom_compare::rom_ptr1_$0 = rom_compare::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_compare__0
    and #<$3fff
    sta.z rom_ptr1_rom_compare__0
    lda.z rom_ptr1_rom_compare__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_compare__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2148] rom_compare::rom_ptr1_return#0 = rom_compare::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_compare::bank_set_brom1
    // BROM = bank
    // [2149] BROM = rom_compare::rom_bank1_return#0 -- vbuz1=vbuz2 
    lda.z rom_bank1_return
    sta.z BROM
    // [2150] rom_compare::ptr_rom#9 = (char *)rom_compare::rom_ptr1_return#0
    // [2151] phi from rom_compare::bank_set_brom1 to rom_compare::@1 [phi:rom_compare::bank_set_brom1->rom_compare::@1]
    // [2151] phi rom_compare::equal_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z equal_bytes
    sta.z equal_bytes+1
    // [2151] phi rom_compare::ptr_ram#4 = rom_compare::ptr_ram#10 [phi:rom_compare::bank_set_brom1->rom_compare::@1#1] -- register_copy 
    // [2151] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#9 [phi:rom_compare::bank_set_brom1->rom_compare::@1#2] -- register_copy 
    // [2151] phi rom_compare::compared_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#3] -- vwuz1=vwuc1 
    sta.z compared_bytes
    sta.z compared_bytes+1
    // rom_compare::@1
  __b1:
    // while (compared_bytes < rom_compare_size)
    // [2152] if(rom_compare::compared_bytes#2<rom_compare::rom_compare_size#11) goto rom_compare::@2 -- vwuz1_lt_vwuz2_then_la1 
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
    // [2153] return 
    rts
    // rom_compare::@2
  __b2:
    // rom_byte_compare(ptr_rom, *ptr_ram)
    // [2154] rom_byte_compare::ptr_rom#0 = rom_compare::ptr_rom#2
    // [2155] rom_byte_compare::value#0 = *rom_compare::ptr_ram#4 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (ptr_ram),y
    sta.z rom_byte_compare.value
    // [2156] call rom_byte_compare
    jsr rom_byte_compare
    // [2157] rom_byte_compare::return#2 = rom_byte_compare::return#0
    // rom_compare::@5
    // [2158] rom_compare::$5 = rom_byte_compare::return#2
    // if (rom_byte_compare(ptr_rom, *ptr_ram))
    // [2159] if(0==rom_compare::$5) goto rom_compare::@3 -- 0_eq_vbuz1_then_la1 
    lda.z rom_compare__5
    beq __b3
    // rom_compare::@4
    // equal_bytes++;
    // [2160] rom_compare::equal_bytes#1 = ++ rom_compare::equal_bytes#2 -- vwuz1=_inc_vwuz1 
    inc.z equal_bytes
    bne !+
    inc.z equal_bytes+1
  !:
    // [2161] phi from rom_compare::@4 rom_compare::@5 to rom_compare::@3 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3]
    // [2161] phi rom_compare::equal_bytes#6 = rom_compare::equal_bytes#1 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3#0] -- register_copy 
    // rom_compare::@3
  __b3:
    // ptr_rom++;
    // [2162] rom_compare::ptr_rom#1 = ++ rom_compare::ptr_rom#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr_rom
    bne !+
    inc.z ptr_rom+1
  !:
    // ptr_ram++;
    // [2163] rom_compare::ptr_ram#0 = ++ rom_compare::ptr_ram#4 -- pbuz1=_inc_pbuz1 
    inc.z ptr_ram
    bne !+
    inc.z ptr_ram+1
  !:
    // compared_bytes++;
    // [2164] rom_compare::compared_bytes#1 = ++ rom_compare::compared_bytes#2 -- vwuz1=_inc_vwuz1 
    inc.z compared_bytes
    bne !+
    inc.z compared_bytes+1
  !:
    // [2151] phi from rom_compare::@3 to rom_compare::@1 [phi:rom_compare::@3->rom_compare::@1]
    // [2151] phi rom_compare::equal_bytes#2 = rom_compare::equal_bytes#6 [phi:rom_compare::@3->rom_compare::@1#0] -- register_copy 
    // [2151] phi rom_compare::ptr_ram#4 = rom_compare::ptr_ram#0 [phi:rom_compare::@3->rom_compare::@1#1] -- register_copy 
    // [2151] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#1 [phi:rom_compare::@3->rom_compare::@1#2] -- register_copy 
    // [2151] phi rom_compare::compared_bytes#2 = rom_compare::compared_bytes#1 [phi:rom_compare::@3->rom_compare::@1#3] -- register_copy 
    jmp __b1
}
  // ultoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void ultoa(__zp($30) unsigned long value, __zp($60) char *buffer, __zp($df) char radix)
ultoa: {
    .label ultoa__4 = $69
    .label ultoa__10 = $63
    .label ultoa__11 = $dc
    .label digit_value = $41
    .label buffer = $60
    .label digit = $65
    .label value = $30
    .label radix = $df
    .label started = $6d
    .label max_digits = $b7
    .label digit_values = $ba
    // if(radix==DECIMAL)
    // [2165] if(ultoa::radix#0==DECIMAL) goto ultoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp.z radix
    beq __b2
    // ultoa::@2
    // if(radix==HEXADECIMAL)
    // [2166] if(ultoa::radix#0==HEXADECIMAL) goto ultoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp.z radix
    beq __b3
    // ultoa::@3
    // if(radix==OCTAL)
    // [2167] if(ultoa::radix#0==OCTAL) goto ultoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp.z radix
    beq __b4
    // ultoa::@4
    // if(radix==BINARY)
    // [2168] if(ultoa::radix#0==BINARY) goto ultoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp.z radix
    beq __b5
    // ultoa::@5
    // *buffer++ = 'e'
    // [2169] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2170] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2171] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2172] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // ultoa::@return
    // }
    // [2173] return 
    rts
    // [2174] phi from ultoa to ultoa::@1 [phi:ultoa->ultoa::@1]
  __b2:
    // [2174] phi ultoa::digit_values#8 = RADIX_DECIMAL_VALUES_LONG [phi:ultoa->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2174] phi ultoa::max_digits#7 = $a [phi:ultoa->ultoa::@1#1] -- vbuz1=vbuc1 
    lda #$a
    sta.z max_digits
    jmp __b1
    // [2174] phi from ultoa::@2 to ultoa::@1 [phi:ultoa::@2->ultoa::@1]
  __b3:
    // [2174] phi ultoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_LONG [phi:ultoa::@2->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2174] phi ultoa::max_digits#7 = 8 [phi:ultoa::@2->ultoa::@1#1] -- vbuz1=vbuc1 
    lda #8
    sta.z max_digits
    jmp __b1
    // [2174] phi from ultoa::@3 to ultoa::@1 [phi:ultoa::@3->ultoa::@1]
  __b4:
    // [2174] phi ultoa::digit_values#8 = RADIX_OCTAL_VALUES_LONG [phi:ultoa::@3->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_OCTAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_LONG
    sta.z digit_values+1
    // [2174] phi ultoa::max_digits#7 = $b [phi:ultoa::@3->ultoa::@1#1] -- vbuz1=vbuc1 
    lda #$b
    sta.z max_digits
    jmp __b1
    // [2174] phi from ultoa::@4 to ultoa::@1 [phi:ultoa::@4->ultoa::@1]
  __b5:
    // [2174] phi ultoa::digit_values#8 = RADIX_BINARY_VALUES_LONG [phi:ultoa::@4->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_BINARY_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_LONG
    sta.z digit_values+1
    // [2174] phi ultoa::max_digits#7 = $20 [phi:ultoa::@4->ultoa::@1#1] -- vbuz1=vbuc1 
    lda #$20
    sta.z max_digits
    // ultoa::@1
  __b1:
    // [2175] phi from ultoa::@1 to ultoa::@6 [phi:ultoa::@1->ultoa::@6]
    // [2175] phi ultoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:ultoa::@1->ultoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2175] phi ultoa::started#2 = 0 [phi:ultoa::@1->ultoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [2175] phi ultoa::value#2 = ultoa::value#1 [phi:ultoa::@1->ultoa::@6#2] -- register_copy 
    // [2175] phi ultoa::digit#2 = 0 [phi:ultoa::@1->ultoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // ultoa::@6
  __b6:
    // max_digits-1
    // [2176] ultoa::$4 = ultoa::max_digits#7 - 1 -- vbuz1=vbuz2_minus_1 
    ldx.z max_digits
    dex
    stx.z ultoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2177] if(ultoa::digit#2<ultoa::$4) goto ultoa::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z digit
    cmp.z ultoa__4
    bcc __b7
    // ultoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2178] ultoa::$11 = (char)ultoa::value#2 -- vbuz1=_byte_vduz2 
    lda.z value
    sta.z ultoa__11
    // [2179] *ultoa::buffer#11 = DIGITS[ultoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2180] ultoa::buffer#3 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2181] *ultoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // ultoa::@7
  __b7:
    // unsigned long digit_value = digit_values[digit]
    // [2182] ultoa::$10 = ultoa::digit#2 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z digit
    asl
    asl
    sta.z ultoa__10
    // [2183] ultoa::digit_value#0 = ultoa::digit_values#8[ultoa::$10] -- vduz1=pduz2_derefidx_vbuz3 
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
    // [2184] if(0!=ultoa::started#2) goto ultoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // ultoa::@12
    // [2185] if(ultoa::value#2>=ultoa::digit_value#0) goto ultoa::@10 -- vduz1_ge_vduz2_then_la1 
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
    // [2186] phi from ultoa::@12 to ultoa::@9 [phi:ultoa::@12->ultoa::@9]
    // [2186] phi ultoa::buffer#14 = ultoa::buffer#11 [phi:ultoa::@12->ultoa::@9#0] -- register_copy 
    // [2186] phi ultoa::started#4 = ultoa::started#2 [phi:ultoa::@12->ultoa::@9#1] -- register_copy 
    // [2186] phi ultoa::value#6 = ultoa::value#2 [phi:ultoa::@12->ultoa::@9#2] -- register_copy 
    // ultoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2187] ultoa::digit#1 = ++ ultoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [2175] phi from ultoa::@9 to ultoa::@6 [phi:ultoa::@9->ultoa::@6]
    // [2175] phi ultoa::buffer#11 = ultoa::buffer#14 [phi:ultoa::@9->ultoa::@6#0] -- register_copy 
    // [2175] phi ultoa::started#2 = ultoa::started#4 [phi:ultoa::@9->ultoa::@6#1] -- register_copy 
    // [2175] phi ultoa::value#2 = ultoa::value#6 [phi:ultoa::@9->ultoa::@6#2] -- register_copy 
    // [2175] phi ultoa::digit#2 = ultoa::digit#1 [phi:ultoa::@9->ultoa::@6#3] -- register_copy 
    jmp __b6
    // ultoa::@10
  __b10:
    // ultoa_append(buffer++, value, digit_value)
    // [2188] ultoa_append::buffer#0 = ultoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z ultoa_append.buffer
    lda.z buffer+1
    sta.z ultoa_append.buffer+1
    // [2189] ultoa_append::value#0 = ultoa::value#2
    // [2190] ultoa_append::sub#0 = ultoa::digit_value#0
    // [2191] call ultoa_append
    // [2478] phi from ultoa::@10 to ultoa_append [phi:ultoa::@10->ultoa_append]
    jsr ultoa_append
    // ultoa_append(buffer++, value, digit_value)
    // [2192] ultoa_append::return#0 = ultoa_append::value#2
    // ultoa::@11
    // value = ultoa_append(buffer++, value, digit_value)
    // [2193] ultoa::value#0 = ultoa_append::return#0
    // value = ultoa_append(buffer++, value, digit_value);
    // [2194] ultoa::buffer#4 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2186] phi from ultoa::@11 to ultoa::@9 [phi:ultoa::@11->ultoa::@9]
    // [2186] phi ultoa::buffer#14 = ultoa::buffer#4 [phi:ultoa::@11->ultoa::@9#0] -- register_copy 
    // [2186] phi ultoa::started#4 = 1 [phi:ultoa::@11->ultoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [2186] phi ultoa::value#6 = ultoa::value#0 [phi:ultoa::@11->ultoa::@9#2] -- register_copy 
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
    .label rom_ptr1_rom_sector_erase__0 = $3f
    .label rom_ptr1_rom_sector_erase__2 = $3f
    .label rom_ptr1_return = $3f
    .label rom_chip_address = $77
    // rom_sector_erase::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2196] rom_sector_erase::rom_ptr1_$2 = (unsigned int)rom_sector_erase::address#0 -- vwuz1=_word_vdum2 
    lda address
    sta.z rom_ptr1_rom_sector_erase__2
    lda address+1
    sta.z rom_ptr1_rom_sector_erase__2+1
    // [2197] rom_sector_erase::rom_ptr1_$0 = rom_sector_erase::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_sector_erase__0
    and #<$3fff
    sta.z rom_ptr1_rom_sector_erase__0
    lda.z rom_ptr1_rom_sector_erase__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_sector_erase__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2198] rom_sector_erase::rom_ptr1_return#0 = rom_sector_erase::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_sector_erase::@1
    // unsigned long rom_chip_address = address & ROM_CHIP_MASK
    // [2199] rom_sector_erase::rom_chip_address#0 = rom_sector_erase::address#0 & $380000 -- vduz1=vdum2_band_vduc1 
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
    // [2200] rom_unlock::address#0 = rom_sector_erase::rom_chip_address#0 + $5555 -- vduz1=vduz1_plus_vwuc1 
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
    // [2201] call rom_unlock
    // [1872] phi from rom_sector_erase::@1 to rom_unlock [phi:rom_sector_erase::@1->rom_unlock]
    // [1872] phi rom_unlock::unlock_code#5 = $80 [phi:rom_sector_erase::@1->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$80
    sta.z rom_unlock.unlock_code
    // [1872] phi rom_unlock::address#5 = rom_unlock::address#0 [phi:rom_sector_erase::@1->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@2
    // rom_unlock(address, 0x30)
    // [2202] rom_unlock::address#1 = rom_sector_erase::address#0 -- vduz1=vdum2 
    lda address
    sta.z rom_unlock.address
    lda address+1
    sta.z rom_unlock.address+1
    lda address+2
    sta.z rom_unlock.address+2
    lda address+3
    sta.z rom_unlock.address+3
    // [2203] call rom_unlock
    // [1872] phi from rom_sector_erase::@2 to rom_unlock [phi:rom_sector_erase::@2->rom_unlock]
    // [1872] phi rom_unlock::unlock_code#5 = $30 [phi:rom_sector_erase::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$30
    sta.z rom_unlock.unlock_code
    // [1872] phi rom_unlock::address#5 = rom_unlock::address#1 [phi:rom_sector_erase::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@3
    // rom_wait(ptr_rom)
    // [2204] rom_wait::ptr_rom#0 = (char *)rom_sector_erase::rom_ptr1_return#0
    // [2205] call rom_wait
    // [2485] phi from rom_sector_erase::@3 to rom_wait [phi:rom_sector_erase::@3->rom_wait]
    // [2485] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#0 [phi:rom_sector_erase::@3->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_sector_erase::@return
    // }
    // [2206] return 
    rts
  .segment Data
    .label address = printf_ulong.uvalue_1
}
.segment Code
  // rom_write
/* inline */
// unsigned long rom_write(__zp($eb) char flash_ram_bank, __zp($60) char *flash_ram_address, __zp($b0) unsigned long flash_rom_address, unsigned int flash_rom_size)
rom_write: {
    .label rom_chip_address = $c1
    .label flash_rom_address = $b0
    .label flash_ram_address = $60
    .label flashed_bytes = $7c
    .label flash_ram_bank = $eb
    // unsigned long rom_chip_address = flash_rom_address & ROM_CHIP_MASK
    // [2207] rom_write::rom_chip_address#0 = rom_write::flash_rom_address#1 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [2208] BRAM = rom_write::flash_ram_bank#0 -- vbuz1=vbuz2 
    lda.z flash_ram_bank
    sta.z BRAM
    // [2209] phi from rom_write::bank_set_bram1 to rom_write::@1 [phi:rom_write::bank_set_bram1->rom_write::@1]
    // [2209] phi rom_write::flash_ram_address#2 = rom_write::flash_ram_address#1 [phi:rom_write::bank_set_bram1->rom_write::@1#0] -- register_copy 
    // [2209] phi rom_write::flash_rom_address#3 = rom_write::flash_rom_address#1 [phi:rom_write::bank_set_bram1->rom_write::@1#1] -- register_copy 
    // [2209] phi rom_write::flashed_bytes#2 = 0 [phi:rom_write::bank_set_bram1->rom_write::@1#2] -- vduz1=vduc1 
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
    // [2210] if(rom_write::flashed_bytes#2<PROGRESS_CELL) goto rom_write::@2 -- vduz1_lt_vduc1_then_la1 
    lda.z flashed_bytes+3
    cmp #>PROGRESS_CELL>>$10
    bcc __b2
    bne !+
    lda.z flashed_bytes+2
    cmp #<PROGRESS_CELL>>$10
    bcc __b2
    bne !+
    lda.z flashed_bytes+1
    cmp #>PROGRESS_CELL
    bcc __b2
    bne !+
    lda.z flashed_bytes
    cmp #<PROGRESS_CELL
    bcc __b2
  !:
    // rom_write::@return
    // }
    // [2211] return 
    rts
    // rom_write::@2
  __b2:
    // rom_unlock(rom_chip_address + 0x05555, 0xA0)
    // [2212] rom_unlock::address#4 = rom_write::rom_chip_address#0 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [2213] call rom_unlock
    // [1872] phi from rom_write::@2 to rom_unlock [phi:rom_write::@2->rom_unlock]
    // [1872] phi rom_unlock::unlock_code#5 = $a0 [phi:rom_write::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$a0
    sta.z rom_unlock.unlock_code
    // [1872] phi rom_unlock::address#5 = rom_unlock::address#4 [phi:rom_write::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_write::@3
    // rom_byte_program(flash_rom_address, *flash_ram_address)
    // [2214] rom_byte_program::address#0 = rom_write::flash_rom_address#3 -- vduz1=vduz2 
    lda.z flash_rom_address
    sta.z rom_byte_program.address
    lda.z flash_rom_address+1
    sta.z rom_byte_program.address+1
    lda.z flash_rom_address+2
    sta.z rom_byte_program.address+2
    lda.z flash_rom_address+3
    sta.z rom_byte_program.address+3
    // [2215] rom_byte_program::value#0 = *rom_write::flash_ram_address#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (flash_ram_address),y
    sta.z rom_byte_program.value
    // [2216] call rom_byte_program
    // [2492] phi from rom_write::@3 to rom_byte_program [phi:rom_write::@3->rom_byte_program]
    jsr rom_byte_program
    // rom_write::@4
    // flash_rom_address++;
    // [2217] rom_write::flash_rom_address#0 = ++ rom_write::flash_rom_address#3 -- vduz1=_inc_vduz1 
    inc.z flash_rom_address
    bne !+
    inc.z flash_rom_address+1
    bne !+
    inc.z flash_rom_address+2
    bne !+
    inc.z flash_rom_address+3
  !:
    // flash_ram_address++;
    // [2218] rom_write::flash_ram_address#0 = ++ rom_write::flash_ram_address#2 -- pbuz1=_inc_pbuz1 
    inc.z flash_ram_address
    bne !+
    inc.z flash_ram_address+1
  !:
    // flashed_bytes++;
    // [2219] rom_write::flashed_bytes#1 = ++ rom_write::flashed_bytes#2 -- vduz1=_inc_vduz1 
    inc.z flashed_bytes
    bne !+
    inc.z flashed_bytes+1
    bne !+
    inc.z flashed_bytes+2
    bne !+
    inc.z flashed_bytes+3
  !:
    // [2209] phi from rom_write::@4 to rom_write::@1 [phi:rom_write::@4->rom_write::@1]
    // [2209] phi rom_write::flash_ram_address#2 = rom_write::flash_ram_address#0 [phi:rom_write::@4->rom_write::@1#0] -- register_copy 
    // [2209] phi rom_write::flash_rom_address#3 = rom_write::flash_rom_address#0 [phi:rom_write::@4->rom_write::@1#1] -- register_copy 
    // [2209] phi rom_write::flashed_bytes#2 = rom_write::flashed_bytes#1 [phi:rom_write::@4->rom_write::@1#2] -- register_copy 
    jmp __b1
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
    // [2220] insertup::$0 = *((char *)&__conio+6) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+6
    inc
    sta.z insertup__0
    // unsigned char width = (__conio.width+1) * 2
    // [2221] insertup::width#0 = insertup::$0 << 1 -- vbuz1=vbuz1_rol_1 
    // {asm{.byte $db}}
    asl.z width
    // [2222] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [2222] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [2223] if(insertup::y#2<*((char *)&__conio+1)) goto insertup::@2 -- vbuz1_lt__deref_pbuc1_then_la1 
    lda.z y
    cmp __conio+1
    bcc __b2
    // [2224] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [2225] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [2226] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [2227] insertup::$4 = insertup::y#2 + 1 -- vbuz1=vbuz2_plus_1 
    lda.z y
    inc
    sta.z insertup__4
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [2228] insertup::$6 = insertup::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z insertup__6
    // [2229] insertup::$7 = insertup::$4 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z insertup__7
    // [2230] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z memcpy8_vram_vram.dbank_vram
    // [2231] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__6
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.doffset_vram+1
    // [2232] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z memcpy8_vram_vram.sbank_vram
    // [2233] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__7
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.soffset_vram+1
    // [2234] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbuz1=vbuz2 
    lda.z width
    sta.z memcpy8_vram_vram.num8_1
    // [2235] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [2236] insertup::y#1 = ++ insertup::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [2222] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [2222] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
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
    // [2237] clearline::$3 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z clearline__3
    // [2238] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwuz1=pwuc1_derefidx_vbuz2 
    tay
    lda __conio+$15,y
    sta.z addr
    lda __conio+$15+1,y
    sta.z addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2239] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [2240] clearline::$0 = byte0  clearline::addr#0 -- vbuz1=_byte0_vwuz2 
    lda.z addr
    sta.z clearline__0
    // *VERA_ADDRX_L = BYTE0(addr)
    // [2241] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [2242] clearline::$1 = byte1  clearline::addr#0 -- vbuz1=_byte1_vwuz2 
    lda.z addr+1
    sta.z clearline__1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [2243] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [2244] clearline::$2 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clearline__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [2245] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [2246] clearline::c#0 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z c
    // [2247] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [2247] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [2248] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [2249] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [2250] clearline::c#1 = -- clearline::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [2251] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b1
    // clearline::@return
    // }
    // [2252] return 
    rts
}
  // frame_maskxy
// __zp($ea) char frame_maskxy(__zp($2c) char x, __zp($cc) char y)
frame_maskxy: {
    .label cpeekcxy1_cpeekc1_frame_maskxy__0 = $5b
    .label cpeekcxy1_cpeekc1_frame_maskxy__1 = $54
    .label cpeekcxy1_cpeekc1_frame_maskxy__2 = $5d
    .label cpeekcxy1_x = $2c
    .label cpeekcxy1_y = $cc
    .label c = $7b
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
    .label return = $ea
    .label x = $2c
    .label y = $cc
    // frame_maskxy::cpeekcxy1
    // gotoxy(x,y)
    // [2254] gotoxy::x#5 = frame_maskxy::cpeekcxy1_x#0 -- vbuz1=vbuz2 
    lda.z cpeekcxy1_x
    sta.z gotoxy.x
    // [2255] gotoxy::y#5 = frame_maskxy::cpeekcxy1_y#0 -- vbuz1=vbuz2 
    lda.z cpeekcxy1_y
    sta.z gotoxy.y
    // [2256] call gotoxy
    // [557] phi from frame_maskxy::cpeekcxy1 to gotoxy [phi:frame_maskxy::cpeekcxy1->gotoxy]
    // [557] phi gotoxy::y#30 = gotoxy::y#5 [phi:frame_maskxy::cpeekcxy1->gotoxy#0] -- register_copy 
    // [557] phi gotoxy::x#30 = gotoxy::x#5 [phi:frame_maskxy::cpeekcxy1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // frame_maskxy::cpeekcxy1_cpeekc1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2257] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(__conio.offset)
    // [2258] frame_maskxy::cpeekcxy1_cpeekc1_$0 = byte0  *((unsigned int *)&__conio+$13) -- vbuz1=_byte0__deref_pwuc1 
    lda __conio+$13
    sta.z cpeekcxy1_cpeekc1_frame_maskxy__0
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [2259] *VERA_ADDRX_L = frame_maskxy::cpeekcxy1_cpeekc1_$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [2260] frame_maskxy::cpeekcxy1_cpeekc1_$1 = byte1  *((unsigned int *)&__conio+$13) -- vbuz1=_byte1__deref_pwuc1 
    lda __conio+$13+1
    sta.z cpeekcxy1_cpeekc1_frame_maskxy__1
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [2261] *VERA_ADDRX_M = frame_maskxy::cpeekcxy1_cpeekc1_$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_0
    // [2262] frame_maskxy::cpeekcxy1_cpeekc1_$2 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z cpeekcxy1_cpeekc1_frame_maskxy__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_0
    // [2263] *VERA_ADDRX_H = frame_maskxy::cpeekcxy1_cpeekc1_$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // return *VERA_DATA0;
    // [2264] frame_maskxy::c#0 = *VERA_DATA0 -- vbuz1=_deref_pbuc1 
    lda VERA_DATA0
    sta.z c
    // frame_maskxy::@12
    // case 0x70: // DR corner.
    //             return 0b0110;
    // [2265] if(frame_maskxy::c#0==$70) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$70
    cmp.z c
    beq __b2
    // frame_maskxy::@1
    // case 0x6E: // DL corner.
    //             return 0b0011;
    // [2266] if(frame_maskxy::c#0==$6e) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6e
    cmp.z c
    beq __b1
    // frame_maskxy::@2
    // case 0x6D: // UR corner.
    //             return 0b1100;
    // [2267] if(frame_maskxy::c#0==$6d) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6d
    cmp.z c
    beq __b3
    // frame_maskxy::@3
    // case 0x7D: // UL corner.
    //             return 0b1001;
    // [2268] if(frame_maskxy::c#0==$7d) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$7d
    cmp.z c
    beq __b4
    // frame_maskxy::@4
    // case 0x40: // HL line.
    //             return 0b0101;
    // [2269] if(frame_maskxy::c#0==$40) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$40
    cmp.z c
    beq __b5
    // frame_maskxy::@5
    // case 0x5D: // VL line.
    //             return 0b1010;
    // [2270] if(frame_maskxy::c#0==$5d) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$5d
    cmp.z c
    beq __b6
    // frame_maskxy::@6
    // case 0x6B: // VR junction.
    //             return 0b1110;
    // [2271] if(frame_maskxy::c#0==$6b) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6b
    cmp.z c
    beq __b7
    // frame_maskxy::@7
    // case 0x73: // VL junction.
    //             return 0b1011;
    // [2272] if(frame_maskxy::c#0==$73) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$73
    cmp.z c
    beq __b8
    // frame_maskxy::@8
    // case 0x72: // HD junction.
    //             return 0b0111;
    // [2273] if(frame_maskxy::c#0==$72) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$72
    cmp.z c
    beq __b9
    // frame_maskxy::@9
    // case 0x71: // HU junction.
    //             return 0b1101;
    // [2274] if(frame_maskxy::c#0==$71) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$71
    cmp.z c
    beq __b10
    // frame_maskxy::@10
    // case 0x5B: // HV junction.
    //             return 0b1111;
    // [2275] if(frame_maskxy::c#0==$5b) goto frame_maskxy::@11 -- vbuz1_eq_vbuc1_then_la1 
    lda #$5b
    cmp.z c
    beq __b11
    // [2277] phi from frame_maskxy::@10 to frame_maskxy::@return [phi:frame_maskxy::@10->frame_maskxy::@return]
    // [2277] phi frame_maskxy::return#12 = 0 [phi:frame_maskxy::@10->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #0
    sta.z return
    rts
    // [2276] phi from frame_maskxy::@10 to frame_maskxy::@11 [phi:frame_maskxy::@10->frame_maskxy::@11]
    // frame_maskxy::@11
  __b11:
    // [2277] phi from frame_maskxy::@11 to frame_maskxy::@return [phi:frame_maskxy::@11->frame_maskxy::@return]
    // [2277] phi frame_maskxy::return#12 = $f [phi:frame_maskxy::@11->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$f
    sta.z return
    rts
    // [2277] phi from frame_maskxy::@1 to frame_maskxy::@return [phi:frame_maskxy::@1->frame_maskxy::@return]
  __b1:
    // [2277] phi frame_maskxy::return#12 = 3 [phi:frame_maskxy::@1->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #3
    sta.z return
    rts
    // [2277] phi from frame_maskxy::@12 to frame_maskxy::@return [phi:frame_maskxy::@12->frame_maskxy::@return]
  __b2:
    // [2277] phi frame_maskxy::return#12 = 6 [phi:frame_maskxy::@12->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #6
    sta.z return
    rts
    // [2277] phi from frame_maskxy::@2 to frame_maskxy::@return [phi:frame_maskxy::@2->frame_maskxy::@return]
  __b3:
    // [2277] phi frame_maskxy::return#12 = $c [phi:frame_maskxy::@2->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$c
    sta.z return
    rts
    // [2277] phi from frame_maskxy::@3 to frame_maskxy::@return [phi:frame_maskxy::@3->frame_maskxy::@return]
  __b4:
    // [2277] phi frame_maskxy::return#12 = 9 [phi:frame_maskxy::@3->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #9
    sta.z return
    rts
    // [2277] phi from frame_maskxy::@4 to frame_maskxy::@return [phi:frame_maskxy::@4->frame_maskxy::@return]
  __b5:
    // [2277] phi frame_maskxy::return#12 = 5 [phi:frame_maskxy::@4->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #5
    sta.z return
    rts
    // [2277] phi from frame_maskxy::@5 to frame_maskxy::@return [phi:frame_maskxy::@5->frame_maskxy::@return]
  __b6:
    // [2277] phi frame_maskxy::return#12 = $a [phi:frame_maskxy::@5->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$a
    sta.z return
    rts
    // [2277] phi from frame_maskxy::@6 to frame_maskxy::@return [phi:frame_maskxy::@6->frame_maskxy::@return]
  __b7:
    // [2277] phi frame_maskxy::return#12 = $e [phi:frame_maskxy::@6->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$e
    sta.z return
    rts
    // [2277] phi from frame_maskxy::@7 to frame_maskxy::@return [phi:frame_maskxy::@7->frame_maskxy::@return]
  __b8:
    // [2277] phi frame_maskxy::return#12 = $b [phi:frame_maskxy::@7->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$b
    sta.z return
    rts
    // [2277] phi from frame_maskxy::@8 to frame_maskxy::@return [phi:frame_maskxy::@8->frame_maskxy::@return]
  __b9:
    // [2277] phi frame_maskxy::return#12 = 7 [phi:frame_maskxy::@8->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #7
    sta.z return
    rts
    // [2277] phi from frame_maskxy::@9 to frame_maskxy::@return [phi:frame_maskxy::@9->frame_maskxy::@return]
  __b10:
    // [2277] phi frame_maskxy::return#12 = $d [phi:frame_maskxy::@9->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$d
    sta.z return
    // frame_maskxy::@return
    // }
    // [2278] return 
    rts
}
  // frame_char
// __zp($b6) char frame_char(__zp($ea) char mask)
frame_char: {
    .label return = $b6
    .label mask = $ea
    // case 0b0110:
    //             return 0x70;
    // [2280] if(frame_char::mask#10==6) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #6
    cmp.z mask
    beq __b1
    // frame_char::@1
    // case 0b0011:
    //             return 0x6E;
    // [2281] if(frame_char::mask#10==3) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // DR corner.
    lda #3
    cmp.z mask
    beq __b2
    // frame_char::@2
    // case 0b1100:
    //             return 0x6D;
    // [2282] if(frame_char::mask#10==$c) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // DL corner.
    lda #$c
    cmp.z mask
    beq __b3
    // frame_char::@3
    // case 0b1001:
    //             return 0x7D;
    // [2283] if(frame_char::mask#10==9) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // UR corner.
    lda #9
    cmp.z mask
    beq __b4
    // frame_char::@4
    // case 0b0101:
    //             return 0x40;
    // [2284] if(frame_char::mask#10==5) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // UL corner.
    lda #5
    cmp.z mask
    beq __b5
    // frame_char::@5
    // case 0b1010:
    //             return 0x5D;
    // [2285] if(frame_char::mask#10==$a) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // HL line.
    lda #$a
    cmp.z mask
    beq __b6
    // frame_char::@6
    // case 0b1110:
    //             return 0x6B;
    // [2286] if(frame_char::mask#10==$e) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VL line.
    lda #$e
    cmp.z mask
    beq __b7
    // frame_char::@7
    // case 0b1011:
    //             return 0x73;
    // [2287] if(frame_char::mask#10==$b) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VR junction.
    lda #$b
    cmp.z mask
    beq __b8
    // frame_char::@8
    // case 0b0111:
    //             return 0x72;
    // [2288] if(frame_char::mask#10==7) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VL junction.
    lda #7
    cmp.z mask
    beq __b9
    // frame_char::@9
    // case 0b1101:
    //             return 0x71;
    // [2289] if(frame_char::mask#10==$d) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // HD junction.
    lda #$d
    cmp.z mask
    beq __b10
    // frame_char::@10
    // case 0b1111:
    //             return 0x5B;
    // [2290] if(frame_char::mask#10==$f) goto frame_char::@11 -- vbuz1_eq_vbuc1_then_la1 
    // HU junction.
    lda #$f
    cmp.z mask
    beq __b11
    // [2292] phi from frame_char::@10 to frame_char::@return [phi:frame_char::@10->frame_char::@return]
    // [2292] phi frame_char::return#12 = $20 [phi:frame_char::@10->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$20
    sta.z return
    rts
    // [2291] phi from frame_char::@10 to frame_char::@11 [phi:frame_char::@10->frame_char::@11]
    // frame_char::@11
  __b11:
    // [2292] phi from frame_char::@11 to frame_char::@return [phi:frame_char::@11->frame_char::@return]
    // [2292] phi frame_char::return#12 = $5b [phi:frame_char::@11->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z return
    rts
    // [2292] phi from frame_char to frame_char::@return [phi:frame_char->frame_char::@return]
  __b1:
    // [2292] phi frame_char::return#12 = $70 [phi:frame_char->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$70
    sta.z return
    rts
    // [2292] phi from frame_char::@1 to frame_char::@return [phi:frame_char::@1->frame_char::@return]
  __b2:
    // [2292] phi frame_char::return#12 = $6e [phi:frame_char::@1->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6e
    sta.z return
    rts
    // [2292] phi from frame_char::@2 to frame_char::@return [phi:frame_char::@2->frame_char::@return]
  __b3:
    // [2292] phi frame_char::return#12 = $6d [phi:frame_char::@2->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6d
    sta.z return
    rts
    // [2292] phi from frame_char::@3 to frame_char::@return [phi:frame_char::@3->frame_char::@return]
  __b4:
    // [2292] phi frame_char::return#12 = $7d [phi:frame_char::@3->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$7d
    sta.z return
    rts
    // [2292] phi from frame_char::@4 to frame_char::@return [phi:frame_char::@4->frame_char::@return]
  __b5:
    // [2292] phi frame_char::return#12 = $40 [phi:frame_char::@4->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z return
    rts
    // [2292] phi from frame_char::@5 to frame_char::@return [phi:frame_char::@5->frame_char::@return]
  __b6:
    // [2292] phi frame_char::return#12 = $5d [phi:frame_char::@5->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z return
    rts
    // [2292] phi from frame_char::@6 to frame_char::@return [phi:frame_char::@6->frame_char::@return]
  __b7:
    // [2292] phi frame_char::return#12 = $6b [phi:frame_char::@6->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z return
    rts
    // [2292] phi from frame_char::@7 to frame_char::@return [phi:frame_char::@7->frame_char::@return]
  __b8:
    // [2292] phi frame_char::return#12 = $73 [phi:frame_char::@7->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z return
    rts
    // [2292] phi from frame_char::@8 to frame_char::@return [phi:frame_char::@8->frame_char::@return]
  __b9:
    // [2292] phi frame_char::return#12 = $72 [phi:frame_char::@8->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z return
    rts
    // [2292] phi from frame_char::@9 to frame_char::@return [phi:frame_char::@9->frame_char::@return]
  __b10:
    // [2292] phi frame_char::return#12 = $71 [phi:frame_char::@9->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z return
    // frame_char::@return
    // }
    // [2293] return 
    rts
}
  // print_chip_led
// void print_chip_led(__zp($65) char x, char y, __zp($6d) char w, __zp($b7) char tc, char bc)
print_chip_led: {
    .label x = $65
    .label w = $6d
    .label tc = $b7
    // textcolor(tc)
    // [2295] textcolor::color#11 = print_chip_led::tc#3 -- vbuz1=vbuz2 
    lda.z tc
    sta.z textcolor.color
    // [2296] call textcolor
    // [539] phi from print_chip_led to textcolor [phi:print_chip_led->textcolor]
    // [539] phi textcolor::color#18 = textcolor::color#11 [phi:print_chip_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [2297] phi from print_chip_led to print_chip_led::@3 [phi:print_chip_led->print_chip_led::@3]
    // print_chip_led::@3
    // bgcolor(bc)
    // [2298] call bgcolor
    // [544] phi from print_chip_led::@3 to bgcolor [phi:print_chip_led::@3->bgcolor]
    // [544] phi bgcolor::color#14 = BLUE [phi:print_chip_led::@3->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [2299] phi from print_chip_led::@3 print_chip_led::@5 to print_chip_led::@1 [phi:print_chip_led::@3/print_chip_led::@5->print_chip_led::@1]
    // [2299] phi print_chip_led::w#4 = print_chip_led::w#7 [phi:print_chip_led::@3/print_chip_led::@5->print_chip_led::@1#0] -- register_copy 
    // [2299] phi print_chip_led::x#4 = print_chip_led::x#7 [phi:print_chip_led::@3/print_chip_led::@5->print_chip_led::@1#1] -- register_copy 
    // print_chip_led::@1
  __b1:
    // cputcxy(x, y, 0x6F)
    // [2300] cputcxy::x#9 = print_chip_led::x#4 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [2301] call cputcxy
    // [1738] phi from print_chip_led::@1 to cputcxy [phi:print_chip_led::@1->cputcxy]
    // [1738] phi cputcxy::c#15 = $6f [phi:print_chip_led::@1->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6f
    sta.z cputcxy.c
    // [1738] phi cputcxy::y#15 = 3 [phi:print_chip_led::@1->cputcxy#1] -- vbuz1=vbuc1 
    lda #3
    sta.z cputcxy.y
    // [1738] phi cputcxy::x#15 = cputcxy::x#9 [phi:print_chip_led::@1->cputcxy#2] -- register_copy 
    jsr cputcxy
    // print_chip_led::@4
    // cputcxy(x, y+1, 0x77)
    // [2302] cputcxy::x#10 = print_chip_led::x#4 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [2303] call cputcxy
    // [1738] phi from print_chip_led::@4 to cputcxy [phi:print_chip_led::@4->cputcxy]
    // [1738] phi cputcxy::c#15 = $77 [phi:print_chip_led::@4->cputcxy#0] -- vbuz1=vbuc1 
    lda #$77
    sta.z cputcxy.c
    // [1738] phi cputcxy::y#15 = 3+1 [phi:print_chip_led::@4->cputcxy#1] -- vbuz1=vbuc1 
    lda #3+1
    sta.z cputcxy.y
    // [1738] phi cputcxy::x#15 = cputcxy::x#10 [phi:print_chip_led::@4->cputcxy#2] -- register_copy 
    jsr cputcxy
    // print_chip_led::@5
    // x++;
    // [2304] print_chip_led::x#0 = ++ print_chip_led::x#4 -- vbuz1=_inc_vbuz1 
    inc.z x
    // while(--w)
    // [2305] print_chip_led::w#0 = -- print_chip_led::w#4 -- vbuz1=_dec_vbuz1 
    dec.z w
    // [2306] if(0!=print_chip_led::w#0) goto print_chip_led::@1 -- 0_neq_vbuz1_then_la1 
    lda.z w
    bne __b1
    // [2307] phi from print_chip_led::@5 to print_chip_led::@2 [phi:print_chip_led::@5->print_chip_led::@2]
    // print_chip_led::@2
    // textcolor(WHITE)
    // [2308] call textcolor
    // [539] phi from print_chip_led::@2 to textcolor [phi:print_chip_led::@2->textcolor]
    // [539] phi textcolor::color#18 = WHITE [phi:print_chip_led::@2->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [2309] phi from print_chip_led::@2 to print_chip_led::@6 [phi:print_chip_led::@2->print_chip_led::@6]
    // print_chip_led::@6
    // bgcolor(BLUE)
    // [2310] call bgcolor
    // [544] phi from print_chip_led::@6 to bgcolor [phi:print_chip_led::@6->bgcolor]
    // [544] phi bgcolor::color#14 = BLUE [phi:print_chip_led::@6->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_led::@return
    // }
    // [2311] return 
    rts
}
  // print_chip_line
// void print_chip_line(__zp($35) char x, __zp($5c) char y, __zp($67) char w, __zp($45) char c)
print_chip_line: {
    .label i = $36
    .label x = $35
    .label w = $67
    .label c = $45
    .label y = $5c
    // gotoxy(x, y)
    // [2313] gotoxy::x#7 = print_chip_line::x#16 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [2314] gotoxy::y#7 = print_chip_line::y#16 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [2315] call gotoxy
    // [557] phi from print_chip_line to gotoxy [phi:print_chip_line->gotoxy]
    // [557] phi gotoxy::y#30 = gotoxy::y#7 [phi:print_chip_line->gotoxy#0] -- register_copy 
    // [557] phi gotoxy::x#30 = gotoxy::x#7 [phi:print_chip_line->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [2316] phi from print_chip_line to print_chip_line::@4 [phi:print_chip_line->print_chip_line::@4]
    // print_chip_line::@4
    // textcolor(GREY)
    // [2317] call textcolor
    // [539] phi from print_chip_line::@4 to textcolor [phi:print_chip_line::@4->textcolor]
    // [539] phi textcolor::color#18 = GREY [phi:print_chip_line::@4->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [2318] phi from print_chip_line::@4 to print_chip_line::@5 [phi:print_chip_line::@4->print_chip_line::@5]
    // print_chip_line::@5
    // bgcolor(BLUE)
    // [2319] call bgcolor
    // [544] phi from print_chip_line::@5 to bgcolor [phi:print_chip_line::@5->bgcolor]
    // [544] phi bgcolor::color#14 = BLUE [phi:print_chip_line::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@6
    // cputc(VERA_CHR_UR)
    // [2320] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [2321] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [2323] call textcolor
    // [539] phi from print_chip_line::@6 to textcolor [phi:print_chip_line::@6->textcolor]
    // [539] phi textcolor::color#18 = WHITE [phi:print_chip_line::@6->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [2324] phi from print_chip_line::@6 to print_chip_line::@7 [phi:print_chip_line::@6->print_chip_line::@7]
    // print_chip_line::@7
    // bgcolor(BLACK)
    // [2325] call bgcolor
    // [544] phi from print_chip_line::@7 to bgcolor [phi:print_chip_line::@7->bgcolor]
    // [544] phi bgcolor::color#14 = BLACK [phi:print_chip_line::@7->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // [2326] phi from print_chip_line::@7 to print_chip_line::@1 [phi:print_chip_line::@7->print_chip_line::@1]
    // [2326] phi print_chip_line::i#2 = 0 [phi:print_chip_line::@7->print_chip_line::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // print_chip_line::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [2327] if(print_chip_line::i#2<print_chip_line::w#10) goto print_chip_line::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [2328] phi from print_chip_line::@1 to print_chip_line::@3 [phi:print_chip_line::@1->print_chip_line::@3]
    // print_chip_line::@3
    // textcolor(GREY)
    // [2329] call textcolor
    // [539] phi from print_chip_line::@3 to textcolor [phi:print_chip_line::@3->textcolor]
    // [539] phi textcolor::color#18 = GREY [phi:print_chip_line::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [2330] phi from print_chip_line::@3 to print_chip_line::@8 [phi:print_chip_line::@3->print_chip_line::@8]
    // print_chip_line::@8
    // bgcolor(BLUE)
    // [2331] call bgcolor
    // [544] phi from print_chip_line::@8 to bgcolor [phi:print_chip_line::@8->bgcolor]
    // [544] phi bgcolor::color#14 = BLUE [phi:print_chip_line::@8->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@9
    // cputc(VERA_CHR_UL)
    // [2332] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [2333] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [2335] call textcolor
    // [539] phi from print_chip_line::@9 to textcolor [phi:print_chip_line::@9->textcolor]
    // [539] phi textcolor::color#18 = WHITE [phi:print_chip_line::@9->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [2336] phi from print_chip_line::@9 to print_chip_line::@10 [phi:print_chip_line::@9->print_chip_line::@10]
    // print_chip_line::@10
    // bgcolor(BLACK)
    // [2337] call bgcolor
    // [544] phi from print_chip_line::@10 to bgcolor [phi:print_chip_line::@10->bgcolor]
    // [544] phi bgcolor::color#14 = BLACK [phi:print_chip_line::@10->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@11
    // cputcxy(x+2, y, c)
    // [2338] cputcxy::x#8 = print_chip_line::x#16 + 2 -- vbuz1=vbuz2_plus_2 
    lda.z x
    clc
    adc #2
    sta.z cputcxy.x
    // [2339] cputcxy::y#8 = print_chip_line::y#16 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [2340] cputcxy::c#8 = print_chip_line::c#15 -- vbuz1=vbuz2 
    lda.z c
    sta.z cputcxy.c
    // [2341] call cputcxy
    // [1738] phi from print_chip_line::@11 to cputcxy [phi:print_chip_line::@11->cputcxy]
    // [1738] phi cputcxy::c#15 = cputcxy::c#8 [phi:print_chip_line::@11->cputcxy#0] -- register_copy 
    // [1738] phi cputcxy::y#15 = cputcxy::y#8 [phi:print_chip_line::@11->cputcxy#1] -- register_copy 
    // [1738] phi cputcxy::x#15 = cputcxy::x#8 [phi:print_chip_line::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // print_chip_line::@return
    // }
    // [2342] return 
    rts
    // print_chip_line::@2
  __b2:
    // cputc(VERA_CHR_SPACE)
    // [2343] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [2344] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [2346] print_chip_line::i#1 = ++ print_chip_line::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [2326] phi from print_chip_line::@2 to print_chip_line::@1 [phi:print_chip_line::@2->print_chip_line::@1]
    // [2326] phi print_chip_line::i#2 = print_chip_line::i#1 [phi:print_chip_line::@2->print_chip_line::@1#0] -- register_copy 
    jmp __b1
}
  // print_chip_end
// void print_chip_end(__zp($64) char x, char y, __zp($6a) char w)
print_chip_end: {
    .label i = $7b
    .label x = $64
    .label w = $6a
    // gotoxy(x, y)
    // [2347] gotoxy::x#8 = print_chip_end::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [2348] call gotoxy
    // [557] phi from print_chip_end to gotoxy [phi:print_chip_end->gotoxy]
    // [557] phi gotoxy::y#30 = print_chip::y#21 [phi:print_chip_end->gotoxy#0] -- vbuz1=vbuc1 
    lda #print_chip.y
    sta.z gotoxy.y
    // [557] phi gotoxy::x#30 = gotoxy::x#8 [phi:print_chip_end->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [2349] phi from print_chip_end to print_chip_end::@4 [phi:print_chip_end->print_chip_end::@4]
    // print_chip_end::@4
    // textcolor(GREY)
    // [2350] call textcolor
    // [539] phi from print_chip_end::@4 to textcolor [phi:print_chip_end::@4->textcolor]
    // [539] phi textcolor::color#18 = GREY [phi:print_chip_end::@4->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [2351] phi from print_chip_end::@4 to print_chip_end::@5 [phi:print_chip_end::@4->print_chip_end::@5]
    // print_chip_end::@5
    // bgcolor(BLUE)
    // [2352] call bgcolor
    // [544] phi from print_chip_end::@5 to bgcolor [phi:print_chip_end::@5->bgcolor]
    // [544] phi bgcolor::color#14 = BLUE [phi:print_chip_end::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_end::@6
    // cputc(VERA_CHR_UR)
    // [2353] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [2354] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [2356] call textcolor
    // [539] phi from print_chip_end::@6 to textcolor [phi:print_chip_end::@6->textcolor]
    // [539] phi textcolor::color#18 = BLUE [phi:print_chip_end::@6->textcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z textcolor.color
    jsr textcolor
    // [2357] phi from print_chip_end::@6 to print_chip_end::@7 [phi:print_chip_end::@6->print_chip_end::@7]
    // print_chip_end::@7
    // bgcolor(BLACK)
    // [2358] call bgcolor
    // [544] phi from print_chip_end::@7 to bgcolor [phi:print_chip_end::@7->bgcolor]
    // [544] phi bgcolor::color#14 = BLACK [phi:print_chip_end::@7->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // [2359] phi from print_chip_end::@7 to print_chip_end::@1 [phi:print_chip_end::@7->print_chip_end::@1]
    // [2359] phi print_chip_end::i#2 = 0 [phi:print_chip_end::@7->print_chip_end::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // print_chip_end::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [2360] if(print_chip_end::i#2<print_chip_end::w#0) goto print_chip_end::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [2361] phi from print_chip_end::@1 to print_chip_end::@3 [phi:print_chip_end::@1->print_chip_end::@3]
    // print_chip_end::@3
    // textcolor(GREY)
    // [2362] call textcolor
    // [539] phi from print_chip_end::@3 to textcolor [phi:print_chip_end::@3->textcolor]
    // [539] phi textcolor::color#18 = GREY [phi:print_chip_end::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [2363] phi from print_chip_end::@3 to print_chip_end::@8 [phi:print_chip_end::@3->print_chip_end::@8]
    // print_chip_end::@8
    // bgcolor(BLUE)
    // [2364] call bgcolor
    // [544] phi from print_chip_end::@8 to bgcolor [phi:print_chip_end::@8->bgcolor]
    // [544] phi bgcolor::color#14 = BLUE [phi:print_chip_end::@8->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_end::@9
    // cputc(VERA_CHR_UL)
    // [2365] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [2366] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_end::@return
    // }
    // [2368] return 
    rts
    // print_chip_end::@2
  __b2:
    // cputc(VERA_CHR_HL)
    // [2369] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [2370] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [2372] print_chip_end::i#1 = ++ print_chip_end::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [2359] phi from print_chip_end::@2 to print_chip_end::@1 [phi:print_chip_end::@2->print_chip_end::@1]
    // [2359] phi print_chip_end::i#2 = print_chip_end::i#1 [phi:print_chip_end::@2->print_chip_end::@1#0] -- register_copy 
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
// __zp($2d) unsigned int utoa_append(__zp($73) char *buffer, __zp($2d) unsigned int value, __zp($3d) unsigned int sub)
utoa_append: {
    .label buffer = $73
    .label value = $2d
    .label sub = $3d
    .label return = $2d
    .label digit = $35
    // [2374] phi from utoa_append to utoa_append::@1 [phi:utoa_append->utoa_append::@1]
    // [2374] phi utoa_append::digit#2 = 0 [phi:utoa_append->utoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [2374] phi utoa_append::value#2 = utoa_append::value#0 [phi:utoa_append->utoa_append::@1#1] -- register_copy 
    // utoa_append::@1
  __b1:
    // while (value >= sub)
    // [2375] if(utoa_append::value#2>=utoa_append::sub#0) goto utoa_append::@2 -- vwuz1_ge_vwuz2_then_la1 
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
    // [2376] *utoa_append::buffer#0 = DIGITS[utoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // utoa_append::@return
    // }
    // [2377] return 
    rts
    // utoa_append::@2
  __b2:
    // digit++;
    // [2378] utoa_append::digit#1 = ++ utoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [2379] utoa_append::value#1 = utoa_append::value#2 - utoa_append::sub#0 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z value
    sec
    sbc.z sub
    sta.z value
    lda.z value+1
    sbc.z sub+1
    sta.z value+1
    // [2374] phi from utoa_append::@2 to utoa_append::@1 [phi:utoa_append::@2->utoa_append::@1]
    // [2374] phi utoa_append::digit#2 = utoa_append::digit#1 [phi:utoa_append::@2->utoa_append::@1#0] -- register_copy 
    // [2374] phi utoa_append::value#2 = utoa_append::value#1 [phi:utoa_append::@2->utoa_append::@1#1] -- register_copy 
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
    // [2381] rom_write_byte::rom_bank1_$0 = byte2  rom_write_byte::address#4 -- vbuz1=_byte2_vduz2 
    lda.z address+2
    sta.z rom_bank1_rom_write_byte__0
    // BYTE1(address)
    // [2382] rom_write_byte::rom_bank1_$1 = byte1  rom_write_byte::address#4 -- vbuz1=_byte1_vduz2 
    lda.z address+1
    sta.z rom_bank1_rom_write_byte__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2383] rom_write_byte::rom_bank1_$2 = rom_write_byte::rom_bank1_$0 w= rom_write_byte::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_write_byte__0
    sta.z rom_bank1_rom_write_byte__2+1
    lda.z rom_bank1_rom_write_byte__1
    sta.z rom_bank1_rom_write_byte__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2384] rom_write_byte::rom_bank1_bank_unshifted#0 = rom_write_byte::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2385] rom_write_byte::rom_bank1_return#0 = byte1  rom_write_byte::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwuz2 
    lda.z rom_bank1_bank_unshifted+1
    sta.z rom_bank1_return
    // rom_write_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2386] rom_write_byte::rom_ptr1_$2 = (unsigned int)rom_write_byte::address#4 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_write_byte__2
    lda.z address+1
    sta.z rom_ptr1_rom_write_byte__2+1
    // [2387] rom_write_byte::rom_ptr1_$0 = rom_write_byte::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_write_byte__0
    and #<$3fff
    sta.z rom_ptr1_rom_write_byte__0
    lda.z rom_ptr1_rom_write_byte__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_write_byte__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2388] rom_write_byte::rom_ptr1_return#0 = rom_write_byte::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_write_byte::bank_set_brom1
    // BROM = bank
    // [2389] BROM = rom_write_byte::rom_bank1_return#0 -- vbuz1=vbuz2 
    lda.z rom_bank1_return
    sta.z BROM
    // rom_write_byte::@1
    // *ptr_rom = value
    // [2390] *((char *)rom_write_byte::rom_ptr1_return#0) = rom_write_byte::value#10 -- _deref_pbuz1=vbuz2 
    lda.z value
    ldy #0
    sta (rom_ptr1_return),y
    // rom_write_byte::@return
    // }
    // [2391] return 
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
    // [2393] return 
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
// __mem() int ferror(__zp($3d) struct $2 *stream)
ferror: {
    .label ferror__6 = $38
    .label ferror__15 = $e8
    .label cbm_k_setnam1_ferror__0 = $55
    .label cbm_k_readst1_status = $f5
    .label cbm_k_chrin2_ch = $f6
    .label stream = $3d
    .label sp = $7b
    .label cbm_k_chrin1_return = $e8
    .label ch = $e8
    .label cbm_k_readst1_return = $38
    .label st = $38
    .label errno_len = $fb
    .label cbm_k_chrin2_return = $e8
    .label errno_parsed = $f2
    // unsigned char sp = (unsigned char)stream
    // [2394] ferror::sp#0 = (char)ferror::stream#0 -- vbuz1=_byte_pssz2 
    lda.z stream
    sta.z sp
    // cbm_k_setlfs(15, 8, 15)
    // [2395] cbm_k_setlfs::channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.channel
    // [2396] cbm_k_setlfs::device = 8 -- vbum1=vbuc1 
    lda #8
    sta cbm_k_setlfs.device
    // [2397] cbm_k_setlfs::command = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.command
    // [2398] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // ferror::@11
    // cbm_k_setnam("")
    // [2399] ferror::cbm_k_setnam1_filename = info_text4 -- pbum1=pbuc1 
    lda #<info_text4
    sta cbm_k_setnam1_filename
    lda #>info_text4
    sta cbm_k_setnam1_filename+1
    // ferror::cbm_k_setnam1
    // strlen(filename)
    // [2400] strlen::str#5 = ferror::cbm_k_setnam1_filename -- pbuz1=pbum2 
    lda cbm_k_setnam1_filename
    sta.z strlen.str
    lda cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [2401] call strlen
    // [2121] phi from ferror::cbm_k_setnam1 to strlen [phi:ferror::cbm_k_setnam1->strlen]
    // [2121] phi strlen::str#8 = strlen::str#5 [phi:ferror::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [2402] strlen::return#12 = strlen::len#2
    // ferror::@12
    // [2403] ferror::cbm_k_setnam1_$0 = strlen::return#12
    // char filename_len = (char)strlen(filename)
    // [2404] ferror::cbm_k_setnam1_filename_len = (char)ferror::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
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
    // [2407] ferror::cbm_k_chkin1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_chkin1_channel
    // ferror::cbm_k_chkin1
    // char status
    // [2408] ferror::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // ferror::cbm_k_chrin1
    // char ch
    // [2410] ferror::cbm_k_chrin1_ch = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chrin1_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin1_ch
    // return ch;
    // [2412] ferror::cbm_k_chrin1_return#0 = ferror::cbm_k_chrin1_ch -- vbuz1=vbum2 
    sta.z cbm_k_chrin1_return
    // ferror::cbm_k_chrin1_@return
    // }
    // [2413] ferror::cbm_k_chrin1_return#1 = ferror::cbm_k_chrin1_return#0
    // ferror::@7
    // char ch = cbm_k_chrin()
    // [2414] ferror::ch#0 = ferror::cbm_k_chrin1_return#1
    // [2415] phi from ferror::@7 to ferror::cbm_k_readst1 [phi:ferror::@7->ferror::cbm_k_readst1]
    // [2415] phi __errno#18 = __errno#312 [phi:ferror::@7->ferror::cbm_k_readst1#0] -- register_copy 
    // [2415] phi ferror::errno_len#10 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z errno_len
    // [2415] phi ferror::ch#10 = ferror::ch#0 [phi:ferror::@7->ferror::cbm_k_readst1#2] -- register_copy 
    // [2415] phi ferror::errno_parsed#2 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#3] -- vbuz1=vbuc1 
    sta.z errno_parsed
    // ferror::cbm_k_readst1
  cbm_k_readst1:
    // char status
    // [2416] ferror::cbm_k_readst1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2418] ferror::cbm_k_readst1_return#0 = ferror::cbm_k_readst1_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst1_return
    // ferror::cbm_k_readst1_@return
    // }
    // [2419] ferror::cbm_k_readst1_return#1 = ferror::cbm_k_readst1_return#0
    // ferror::@8
    // cbm_k_readst()
    // [2420] ferror::$6 = ferror::cbm_k_readst1_return#1
    // st = cbm_k_readst()
    // [2421] ferror::st#1 = ferror::$6
    // while (!(st = cbm_k_readst()))
    // [2422] if(0==ferror::st#1) goto ferror::@1 -- 0_eq_vbuz1_then_la1 
    lda.z st
    beq __b1
    // ferror::@2
    // __status = st
    // [2423] ((char *)&__stdio_file+$46)[ferror::sp#0] = ferror::st#1 -- pbuc1_derefidx_vbuz1=vbuz2 
    ldy.z sp
    sta __stdio_file+$46,y
    // cbm_k_close(15)
    // [2424] ferror::cbm_k_close1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_close1_channel
    // ferror::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // ferror::@9
    // return __errno;
    // [2426] ferror::return#1 = __errno#18 -- vwsm1=vwsz2 
    lda.z __errno
    sta return
    lda.z __errno+1
    sta return+1
    // ferror::@return
    // }
    // [2427] return 
    rts
    // ferror::@1
  __b1:
    // if (!errno_parsed)
    // [2428] if(0!=ferror::errno_parsed#2) goto ferror::@3 -- 0_neq_vbuz1_then_la1 
    lda.z errno_parsed
    bne __b3
    // ferror::@4
    // if (ch == ',')
    // [2429] if(ferror::ch#10!=',') goto ferror::@3 -- vbuz1_neq_vbuc1_then_la1 
    lda #','
    cmp.z ch
    bne __b3
    // ferror::@5
    // errno_parsed++;
    // [2430] ferror::errno_parsed#1 = ++ ferror::errno_parsed#2 -- vbuz1=_inc_vbuz1 
    inc.z errno_parsed
    // strncpy(temp, __errno_error, errno_len+1)
    // [2431] strncpy::n#0 = ferror::errno_len#10 + 1 -- vwuz1=vbuz2_plus_1 
    lda.z errno_len
    clc
    adc #1
    sta.z strncpy.n
    lda #0
    adc #0
    sta.z strncpy.n+1
    // [2432] call strncpy
    // [1497] phi from ferror::@5 to strncpy [phi:ferror::@5->strncpy]
    // [1497] phi strncpy::dst#8 = ferror::temp [phi:ferror::@5->strncpy#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z strncpy.dst
    lda #>temp
    sta.z strncpy.dst+1
    // [1497] phi strncpy::src#6 = __errno_error [phi:ferror::@5->strncpy#1] -- pbuz1=pbuc1 
    lda #<__errno_error
    sta.z strncpy.src
    lda #>__errno_error
    sta.z strncpy.src+1
    // [1497] phi strncpy::n#3 = strncpy::n#0 [phi:ferror::@5->strncpy#2] -- register_copy 
    jsr strncpy
    // [2433] phi from ferror::@5 to ferror::@13 [phi:ferror::@5->ferror::@13]
    // ferror::@13
    // atoi(temp)
    // [2434] call atoi
    // [2446] phi from ferror::@13 to atoi [phi:ferror::@13->atoi]
    // [2446] phi atoi::str#2 = ferror::temp [phi:ferror::@13->atoi#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z atoi.str
    lda #>temp
    sta.z atoi.str+1
    jsr atoi
    // atoi(temp)
    // [2435] atoi::return#4 = atoi::return#2
    // ferror::@14
    // __errno = atoi(temp)
    // [2436] __errno#2 = atoi::return#4 -- vwsz1=vwsz2 
    lda.z atoi.return
    sta.z __errno
    lda.z atoi.return+1
    sta.z __errno+1
    // [2437] phi from ferror::@1 ferror::@14 ferror::@4 to ferror::@3 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3]
    // [2437] phi __errno#102 = __errno#18 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#0] -- register_copy 
    // [2437] phi ferror::errno_parsed#11 = ferror::errno_parsed#2 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#1] -- register_copy 
    // ferror::@3
  __b3:
    // __errno_error[errno_len] = ch
    // [2438] __errno_error[ferror::errno_len#10] = ferror::ch#10 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z ch
    ldy.z errno_len
    sta __errno_error,y
    // errno_len++;
    // [2439] ferror::errno_len#1 = ++ ferror::errno_len#10 -- vbuz1=_inc_vbuz1 
    inc.z errno_len
    // ferror::cbm_k_chrin2
    // char ch
    // [2440] ferror::cbm_k_chrin2_ch = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chrin2_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin2_ch
    // return ch;
    // [2442] ferror::cbm_k_chrin2_return#0 = ferror::cbm_k_chrin2_ch -- vbuz1=vbuz2 
    sta.z cbm_k_chrin2_return
    // ferror::cbm_k_chrin2_@return
    // }
    // [2443] ferror::cbm_k_chrin2_return#1 = ferror::cbm_k_chrin2_return#0
    // ferror::@10
    // cbm_k_chrin()
    // [2444] ferror::$15 = ferror::cbm_k_chrin2_return#1
    // ch = cbm_k_chrin()
    // [2445] ferror::ch#1 = ferror::$15
    // [2415] phi from ferror::@10 to ferror::cbm_k_readst1 [phi:ferror::@10->ferror::cbm_k_readst1]
    // [2415] phi __errno#18 = __errno#102 [phi:ferror::@10->ferror::cbm_k_readst1#0] -- register_copy 
    // [2415] phi ferror::errno_len#10 = ferror::errno_len#1 [phi:ferror::@10->ferror::cbm_k_readst1#1] -- register_copy 
    // [2415] phi ferror::ch#10 = ferror::ch#1 [phi:ferror::@10->ferror::cbm_k_readst1#2] -- register_copy 
    // [2415] phi ferror::errno_parsed#2 = ferror::errno_parsed#11 [phi:ferror::@10->ferror::cbm_k_readst1#3] -- register_copy 
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
}
.segment Code
  // atoi
// Converts the string argument str to an integer.
// __zp($51) int atoi(__zp($d1) const char *str)
atoi: {
    .label atoi__6 = $51
    .label atoi__7 = $51
    .label res = $51
    // Initialize sign as positive
    .label i = $67
    .label return = $51
    .label str = $d1
    // Initialize result
    .label negative = $45
    .label atoi__10 = $4f
    .label atoi__11 = $51
    // if (str[i] == '-')
    // [2447] if(*atoi::str#2!='-') goto atoi::@3 -- _deref_pbuz1_neq_vbuc1_then_la1 
    ldy #0
    lda (str),y
    cmp #'-'
    bne __b2
    // [2448] phi from atoi to atoi::@2 [phi:atoi->atoi::@2]
    // atoi::@2
    // [2449] phi from atoi::@2 to atoi::@3 [phi:atoi::@2->atoi::@3]
    // [2449] phi atoi::negative#2 = 1 [phi:atoi::@2->atoi::@3#0] -- vbuz1=vbuc1 
    lda #1
    sta.z negative
    // [2449] phi atoi::res#2 = 0 [phi:atoi::@2->atoi::@3#1] -- vwsz1=vwsc1 
    tya
    sta.z res
    sta.z res+1
    // [2449] phi atoi::i#4 = 1 [phi:atoi::@2->atoi::@3#2] -- vbuz1=vbuc1 
    lda #1
    sta.z i
    jmp __b3
  // Iterate through all digits and update the result
    // [2449] phi from atoi to atoi::@3 [phi:atoi->atoi::@3]
  __b2:
    // [2449] phi atoi::negative#2 = 0 [phi:atoi->atoi::@3#0] -- vbuz1=vbuc1 
    lda #0
    sta.z negative
    // [2449] phi atoi::res#2 = 0 [phi:atoi->atoi::@3#1] -- vwsz1=vwsc1 
    sta.z res
    sta.z res+1
    // [2449] phi atoi::i#4 = 0 [phi:atoi->atoi::@3#2] -- vbuz1=vbuc1 
    sta.z i
    // atoi::@3
  __b3:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [2450] if(atoi::str#2[atoi::i#4]<'0') goto atoi::@5 -- pbuz1_derefidx_vbuz2_lt_vbuc1_then_la1 
    ldy.z i
    lda (str),y
    cmp #'0'
    bcc __b5
    // atoi::@6
    // [2451] if(atoi::str#2[atoi::i#4]<='9') goto atoi::@4 -- pbuz1_derefidx_vbuz2_le_vbuc1_then_la1 
    lda (str),y
    cmp #'9'
    bcc __b4
    beq __b4
    // atoi::@5
  __b5:
    // if(negative)
    // [2452] if(0!=atoi::negative#2) goto atoi::@1 -- 0_neq_vbuz1_then_la1 
    // Return result with sign
    lda.z negative
    bne __b1
    // [2454] phi from atoi::@1 atoi::@5 to atoi::@return [phi:atoi::@1/atoi::@5->atoi::@return]
    // [2454] phi atoi::return#2 = atoi::return#0 [phi:atoi::@1/atoi::@5->atoi::@return#0] -- register_copy 
    rts
    // atoi::@1
  __b1:
    // return -res;
    // [2453] atoi::return#0 = - atoi::res#2 -- vwsz1=_neg_vwsz1 
    lda #0
    sec
    sbc.z return
    sta.z return
    lda #0
    sbc.z return+1
    sta.z return+1
    // atoi::@return
    // }
    // [2455] return 
    rts
    // atoi::@4
  __b4:
    // res * 10
    // [2456] atoi::$10 = atoi::res#2 << 2 -- vwsz1=vwsz2_rol_2 
    lda.z res
    asl
    sta.z atoi__10
    lda.z res+1
    rol
    sta.z atoi__10+1
    asl.z atoi__10
    rol.z atoi__10+1
    // [2457] atoi::$11 = atoi::$10 + atoi::res#2 -- vwsz1=vwsz2_plus_vwsz1 
    clc
    lda.z atoi__11
    adc.z atoi__10
    sta.z atoi__11
    lda.z atoi__11+1
    adc.z atoi__10+1
    sta.z atoi__11+1
    // [2458] atoi::$6 = atoi::$11 << 1 -- vwsz1=vwsz1_rol_1 
    asl.z atoi__6
    rol.z atoi__6+1
    // res * 10 + str[i]
    // [2459] atoi::$7 = atoi::$6 + atoi::str#2[atoi::i#4] -- vwsz1=vwsz1_plus_pbuz2_derefidx_vbuz3 
    ldy.z i
    lda.z atoi__7
    clc
    adc (str),y
    sta.z atoi__7
    bcc !+
    inc.z atoi__7+1
  !:
    // res = res * 10 + str[i] - '0'
    // [2460] atoi::res#1 = atoi::$7 - '0' -- vwsz1=vwsz1_minus_vbuc1 
    lda.z res
    sec
    sbc #'0'
    sta.z res
    bcs !+
    dec.z res+1
  !:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [2461] atoi::i#2 = ++ atoi::i#4 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [2449] phi from atoi::@4 to atoi::@3 [phi:atoi::@4->atoi::@3]
    // [2449] phi atoi::negative#2 = atoi::negative#2 [phi:atoi::@4->atoi::@3#0] -- register_copy 
    // [2449] phi atoi::res#2 = atoi::res#1 [phi:atoi::@4->atoi::@3#1] -- register_copy 
    // [2449] phi atoi::i#4 = atoi::i#2 [phi:atoi::@4->atoi::@3#2] -- register_copy 
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
// __zp($2d) unsigned int cx16_k_macptr(__zp($c9) volatile char bytes, __zp($c5) void * volatile buffer)
cx16_k_macptr: {
    .label bytes = $c9
    .label buffer = $c5
    .label bytes_read = $b4
    .label return = $2d
    // unsigned int bytes_read
    // [2462] cx16_k_macptr::bytes_read = 0 -- vwuz1=vwuc1 
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
    // [2464] cx16_k_macptr::return#0 = cx16_k_macptr::bytes_read -- vwuz1=vwuz2 
    lda.z bytes_read
    sta.z return
    lda.z bytes_read+1
    sta.z return+1
    // cx16_k_macptr::@return
    // }
    // [2465] cx16_k_macptr::return#1 = cx16_k_macptr::return#0
    // [2466] return 
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
// __zp($2f) char uctoa_append(__zp($71) char *buffer, __zp($2f) char value, __zp($45) char sub)
uctoa_append: {
    .label buffer = $71
    .label value = $2f
    .label sub = $45
    .label return = $2f
    .label digit = $36
    // [2468] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [2468] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [2468] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [2469] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbuz1_ge_vbuz2_then_la1 
    lda.z value
    cmp.z sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [2470] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // uctoa_append::@return
    // }
    // [2471] return 
    rts
    // uctoa_append::@2
  __b2:
    // digit++;
    // [2472] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [2473] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbuz1=vbuz1_minus_vbuz2 
    lda.z value
    sec
    sbc.z sub
    sta.z value
    // [2468] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [2468] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [2468] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
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
// __zp($7b) char rom_byte_compare(__zp($75) char *ptr_rom, __zp($63) char value)
rom_byte_compare: {
    .label return = $7b
    .label ptr_rom = $75
    .label value = $63
    // if (*ptr_rom != value)
    // [2474] if(*rom_byte_compare::ptr_rom#0==rom_byte_compare::value#0) goto rom_byte_compare::@1 -- _deref_pbuz1_eq_vbuz2_then_la1 
    lda.z value
    ldy #0
    cmp (ptr_rom),y
    beq __b2
    // [2475] phi from rom_byte_compare to rom_byte_compare::@2 [phi:rom_byte_compare->rom_byte_compare::@2]
    // rom_byte_compare::@2
    // [2476] phi from rom_byte_compare::@2 to rom_byte_compare::@1 [phi:rom_byte_compare::@2->rom_byte_compare::@1]
    // [2476] phi rom_byte_compare::return#0 = 0 [phi:rom_byte_compare::@2->rom_byte_compare::@1#0] -- vbuz1=vbuc1 
    tya
    sta.z return
    rts
    // [2476] phi from rom_byte_compare to rom_byte_compare::@1 [phi:rom_byte_compare->rom_byte_compare::@1]
  __b2:
    // [2476] phi rom_byte_compare::return#0 = 1 [phi:rom_byte_compare->rom_byte_compare::@1#0] -- vbuz1=vbuc1 
    lda #1
    sta.z return
    // rom_byte_compare::@1
    // rom_byte_compare::@return
    // }
    // [2477] return 
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
// __zp($30) unsigned long ultoa_append(__zp($6f) char *buffer, __zp($30) unsigned long value, __zp($41) unsigned long sub)
ultoa_append: {
    .label buffer = $6f
    .label value = $30
    .label sub = $41
    .label return = $30
    .label digit = $37
    // [2479] phi from ultoa_append to ultoa_append::@1 [phi:ultoa_append->ultoa_append::@1]
    // [2479] phi ultoa_append::digit#2 = 0 [phi:ultoa_append->ultoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [2479] phi ultoa_append::value#2 = ultoa_append::value#0 [phi:ultoa_append->ultoa_append::@1#1] -- register_copy 
    // ultoa_append::@1
  __b1:
    // while (value >= sub)
    // [2480] if(ultoa_append::value#2>=ultoa_append::sub#0) goto ultoa_append::@2 -- vduz1_ge_vduz2_then_la1 
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
    // [2481] *ultoa_append::buffer#0 = DIGITS[ultoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // ultoa_append::@return
    // }
    // [2482] return 
    rts
    // ultoa_append::@2
  __b2:
    // digit++;
    // [2483] ultoa_append::digit#1 = ++ ultoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [2484] ultoa_append::value#1 = ultoa_append::value#2 - ultoa_append::sub#0 -- vduz1=vduz1_minus_vduz2 
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
    // [2479] phi from ultoa_append::@2 to ultoa_append::@1 [phi:ultoa_append::@2->ultoa_append::@1]
    // [2479] phi ultoa_append::digit#2 = ultoa_append::digit#1 [phi:ultoa_append::@2->ultoa_append::@1#0] -- register_copy 
    // [2479] phi ultoa_append::value#2 = ultoa_append::value#1 [phi:ultoa_append::@2->ultoa_append::@1#1] -- register_copy 
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
// void rom_wait(__zp($3f) char *ptr_rom)
rom_wait: {
    .label rom_wait__0 = $38
    .label rom_wait__1 = $2c
    .label test1 = $38
    .label test2 = $2c
    .label ptr_rom = $3f
    // rom_wait::@1
  __b1:
    // test1 = *((brom_ptr_t)ptr_rom)
    // [2486] rom_wait::test1#1 = *rom_wait::ptr_rom#3 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (ptr_rom),y
    sta.z test1
    // test2 = *((brom_ptr_t)ptr_rom)
    // [2487] rom_wait::test2#1 = *rom_wait::ptr_rom#3 -- vbuz1=_deref_pbuz2 
    lda (ptr_rom),y
    sta.z test2
    // test1 & 0x40
    // [2488] rom_wait::$0 = rom_wait::test1#1 & $40 -- vbuz1=vbuz1_band_vbuc1 
    lda #$40
    and.z rom_wait__0
    sta.z rom_wait__0
    // test2 & 0x40
    // [2489] rom_wait::$1 = rom_wait::test2#1 & $40 -- vbuz1=vbuz1_band_vbuc1 
    lda #$40
    and.z rom_wait__1
    sta.z rom_wait__1
    // while ((test1 & 0x40) != (test2 & 0x40))
    // [2490] if(rom_wait::$0!=rom_wait::$1) goto rom_wait::@1 -- vbuz1_neq_vbuz2_then_la1 
    lda.z rom_wait__0
    cmp.z rom_wait__1
    bne __b1
    // rom_wait::@return
    // }
    // [2491] return 
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
    // [2493] rom_byte_program::rom_ptr1_$2 = (unsigned int)rom_byte_program::address#0 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_byte_program__2
    lda.z address+1
    sta.z rom_ptr1_rom_byte_program__2+1
    // [2494] rom_byte_program::rom_ptr1_$0 = rom_byte_program::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_byte_program__0
    and #<$3fff
    sta.z rom_ptr1_rom_byte_program__0
    lda.z rom_ptr1_rom_byte_program__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_byte_program__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2495] rom_byte_program::rom_ptr1_return#0 = rom_byte_program::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_byte_program::@1
    // rom_write_byte(address, value)
    // [2496] rom_write_byte::address#3 = rom_byte_program::address#0
    // [2497] rom_write_byte::value#3 = rom_byte_program::value#0
    // [2498] call rom_write_byte
    // [2380] phi from rom_byte_program::@1 to rom_write_byte [phi:rom_byte_program::@1->rom_write_byte]
    // [2380] phi rom_write_byte::value#10 = rom_write_byte::value#3 [phi:rom_byte_program::@1->rom_write_byte#0] -- register_copy 
    // [2380] phi rom_write_byte::address#4 = rom_write_byte::address#3 [phi:rom_byte_program::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_byte_program::@2
    // rom_wait(ptr_rom)
    // [2499] rom_wait::ptr_rom#1 = (char *)rom_byte_program::rom_ptr1_return#0 -- pbuz1=pbuz2 
    lda.z rom_ptr1_return
    sta.z rom_wait.ptr_rom
    lda.z rom_ptr1_return+1
    sta.z rom_wait.ptr_rom+1
    // [2500] call rom_wait
    // [2485] phi from rom_byte_program::@2 to rom_wait [phi:rom_byte_program::@2->rom_wait]
    // [2485] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#1 [phi:rom_byte_program::@2->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_byte_program::@return
    // }
    // [2501] return 
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
    // [2502] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [2503] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte0_vwuz2 
    lda.z soffset_vram
    sta.z memcpy8_vram_vram__0
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [2504] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [2505] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte1_vwuz2 
    lda.z soffset_vram+1
    sta.z memcpy8_vram_vram__1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [2506] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [2507] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbuz1=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z memcpy8_vram_vram__2
    sta.z memcpy8_vram_vram__2
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [2508] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [2509] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [2510] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte0_vwuz2 
    lda.z doffset_vram
    sta.z memcpy8_vram_vram__3
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [2511] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [2512] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte1_vwuz2 
    lda.z doffset_vram+1
    sta.z memcpy8_vram_vram__4
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [2513] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [2514] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbuz1=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z memcpy8_vram_vram__5
    sta.z memcpy8_vram_vram__5
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [2515] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // [2516] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [2516] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [2517] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbuz1=_dec_vbuz2 
    ldy.z num8_1
    dey
    sty.z num8
    // [2518] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbuz1_then_la1 
    lda.z num8_1
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [2519] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [2520] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [2521] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbuz1=vbuz2 
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
  //     unsigned char l = 0;
  //     while (l < INFO_H) {
  //         info_clear(l);
  //         l++;
  //     }
  // }
  status_smc: .byte 0
  status_vera: .byte 0
  smc_bootloader: .word 0
  smc_file_size: .word 0
  smc_file_size_1: .word 0
  smc_file_size_2: .word 0
